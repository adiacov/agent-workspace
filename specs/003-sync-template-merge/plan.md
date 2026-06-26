# Implementation Plan: Sync merges template changes into projects

**Branch**: `003-sync-template-merge` | **Date**: 2026-06-26 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/003-sync-template-merge/spec.md`

## Summary

Turn `agent-ws sync` from a no-op-on-active-files command into a safe reconciler that pulls
published template changes into a bootstrapped project's framework files. The mechanism is a
per-project **baseline** (a local, gitignored snapshot of the template content the project
last synced from) feeding a **three-way merge** (`baseline` = BASE, current template = THEIRS,
project file = OURS) via `git merge-file`. Clean template-only additions apply silently;
overlapping edits are refused deterministically (live file untouched, a `*.merge` side-file
written, non-zero exit); resolving that side-file is a separate agent/user step, not the tool's
job. Each write is backed up and atomic.
Files are scoped by the `kind` already recorded in `workspace.json`: only `default`/`profile`/
`adapter` (framework) files sync; `context` files (STATE.md/PROJECT.md) are never touched.
`init` seeds baselines going forward; first `sync` on a baseline-less project seeds and applies
only safe additions. `diff` is repurposed/colorized to show the incoming `baseline→template`
delta rather than an unscoped comparison.

## Technical Context

**Language/Version**: Bash (POSIX-ish, same style as existing `lib/agent-ws/*.sh`), Python 3
helpers for JSON (already used in `metadata.sh`/`diff.sh`).

**Primary Dependencies**: `git` (for `git merge-file`, always present), `python3` (JSON),
coreutils (`cp`, `mv`, `cmp`, `mktemp`, `diff`). No new third-party dependencies.

**Storage**: Per-project files only — `.agent-workspace/workspace.json` (existing, metadata),
new `.agent-workspace/baseline/<active-path>` (gitignored baseline snapshots), transient
`*.bak` backups and `*.merge` side-files.

**Testing**: Existing `tests/smoke/` (fast functional) and `tests/integration/` (end-to-end in
temp dirs). Add a `tests/unit/` for the merge/classify/baseline helpers, plus integration flows.

**Target Platform**: Linux shell (first-class), macOS-compatible shells.

**Project Type**: Single-project CLI tool.

**Performance Goals**: Interactive (sub-second per project for a handful of files). Not a hot path.

**Constraints**: Fully offline — no network, no template git history required (FR-015). No
silent data loss (FR-002, FR-005). Atomic per-file writes (FR-007). Backwards compatible:
projects without a baseline must still work (FR-009).

**Scale/Scope**: A project has ~4–8 generated files; a handful of projects. Small inputs.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is an unfilled template (placeholder principles only), so
there are no ratified governance gates to evaluate. Applying the project's own de-facto
principles instead (from existing code style and `STATE.md`/`README.md`):

- **Conservative-by-default / no data loss** — honored: backups, atomic writes, refuse-on-
  conflict, dry-run first.
- **Offline, dependency-light** — honored: only git + python3 + coreutils, already in use.
- **Match existing code idiom** — honored: bash modules under `lib/agent-ws/`, python heredocs
  for JSON, `agent_ws_*` naming.
- **Tested** — honored: unit + integration coverage added before/with implementation.

No violations; Complexity Tracking left empty.

## Project Structure

### Documentation (this feature)

```text
specs/003-sync-template-merge/
├── plan.md              # This file
├── spec.md              # Feature spec (+ Clarifications)
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── sync-cli.md      # CLI behavior contract for sync/diff
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/agent-ws/
├── sync.sh         # REWRITE: agent_ws_sync_project becomes the reconciler
├── merge.sh        # NEW: 3-way merge engine + classification + outcome reporting
├── baseline.sh     # NEW: read/write/seed per-project baseline snapshots
├── diff.sh         # REPURPOSE: incoming baseline→template delta + colorized output
├── templates.sh    # EDIT: init writes baselines; classification helper source of truth
├── metadata.sh     # (read) generatedFiles {path,kind,template}; baseline location
└── commands.sh     # EDIT: sync/diff usage + flag wiring (e.g. --apply seeds+merges)

templates/default/.gitignore   # EDIT: add .agent-workspace/baseline/, *.bak, *.merge

tests/
├── unit/                       # NEW: merge engine, classify-by-kind, baseline seed/update
├── integration/                # NEW flows: sync-additive, sync-conflict-refuse,
│                               #   sync-agentless-sidefile, seed-existing, context-skip
└── smoke/                      # extend: sync help/flags
```

**Structure Decision**: Single-project CLI. New behavior is split into two new modules
(`merge.sh`, `baseline.sh`) to keep `sync.sh` orchestration thin and unit-testable, mirroring
how the codebase already separates `metadata.sh`/`templates.sh`/`diff.sh`.

## Complexity Tracking

> No constitution violations; section intentionally empty.
