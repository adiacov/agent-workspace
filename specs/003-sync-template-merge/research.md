# Phase 0 Research: Sync merges template changes into projects

Source of options analysis: `reports/2026-06-26-sync-merge-redesign-options.md` (internal).
All NEEDS CLARIFICATION are resolved here or in spec Clarifications.

## R1. Merge engine

**Decision**: Use `git merge-file -p <OURS> <BASE> <THEIRS>` per file.

**Rationale**: Standard 3-way merge with conflict markers, ships with git (already a hard
dependency for `update`/`templateRevision`), works on arbitrary files outside any repo, exits
non-zero when conflicts remain (clean signal). Output to stdout (`-p`) lets us inspect before
touching the live file.

**Alternatives considered**:
- `diff3 -m` — equivalent, but `git merge-file` has nicer labels (`-L`) and is already implied.
- Hand-written section merge — fragile, reinvents a solved problem.
- `patch`/`git apply --3way` — needs blob context / a repo; rejected.

## R2. The merge BASE (the crux)

**Decision**: Store a per-project baseline snapshot at `.agent-workspace/baseline/<active-path>`
written at `init` and refreshed after each successful sync; it is BASE.

**Rationale**: A real install's `templateRevision` is `unknown` (templates copied as plain
files, not a git checkout), so git history cannot reconstruct the old template. A stored
snapshot is reliable, offline, and install-agnostic — the Copier/Cruft model.

**Clarified**: baseline is **gitignored** (local-only working artifact), not committed. A
fresh clone has no baseline → first sync seeds it (R6).

**Alternatives considered**: reconstruct BASE from agent-ws git history (Option D) — rejected,
prerequisites not met. Central/install-path baseline — rejected: cannot represent multiple
projects each at a different sync point.

## R3. File classification (what syncs)

**Decision**: Drive scope from `generatedFiles[path].kind` already in `workspace.json`.
Framework = `default | profile | adapter` → sync. Content = `context` → never sync.

**Rationale**: The classifier already exists; no new metadata. `context` files (STATE.md,
PROJECT.md) are per-project content (this repo's own STATE.md was fully rewritten), so syncing
template boilerplate into them is wrong. Resolves the "diff is noise" complaint at the source.

**Alternatives**: hardcode a filename allowlist — brittle vs. custom adapter paths. Sync
everything — rejected (FR-008).

## R4. Conflict handling

**Decision**: Deterministic, two outcomes. (a) clean merge (git exit 0) → stage and apply the
merged content. (b) conflict (git exit 1) → do NOT write the live file; write a `*.merge`
side-file with markers; report; the run exits non-zero. The tool never resolves conflicts
itself.

**Rationale**: A bash command cannot invoke an LLM to reconcile text mid-run, so an "agent
resolves inline" branch is fiction. Keeping the tool deterministic makes it testable in a bare
shell/CI and matches the user's hard requirement: never hand them a marker-filled live file,
never lose data. The `*.merge` side-file preserves the merge result for later resolution by an
agent or the user as a **separate step**, without risking the active file.

**Alternatives**: inline agent resolution via an `AGENT_WS_AGENT_PRESENT` flag — rejected (F1):
bash can't do it, and it adds state for no real behavior. Always write markers to the live file
— rejected (unsafe).

## R5. Safety: backups + atomicity

**Decision**: For each file to change: write merged content to a temp file, create `<file>.bak`
of the original, `mv` temp into place, then remove `.bak` on whole-run success. On any failure,
restore from `.bak`. Per-file all-or-nothing; never a partially written file.

**Rationale**: Cheap, transparent, recoverable (FR-006, FR-007). `mv` within the same
filesystem is atomic.

## R6. Seeding existing (baseline-less) projects

**Decision**: First sync with no baseline runs **additive-safe** mode: apply only template
content that does not overlap project content is not attempted as a true 3-way (no BASE);
instead seed BASE = current template snapshot, report "baseline established", and apply nothing
destructive on that run. Next sync does full 3-way against the new baseline.

**Rationale**: Without BASE a 3-way is impossible; the safe, predictable bootstrap is to record
the current template as BASE so future deltas reconcile. Avoids guessing/clobbering on run one
(FR-009).

**Note**: this understates already-diverged content for exactly one cycle — acceptable and
documented.

## R7. Repurpose + colorize `diff`

**Decision**: `diff` reports the incoming delta = `baseline (template-then)` vs
`template-now`, scoped to framework files, with colorized add/remove lines; honor `NO_COLOR`
and non-TTY (plain output).

**Rationale**: The old `template-now vs active-now` comparison is unscoped noise (user
complaint). The incoming delta is the meaningful preview/input to sync. Colorization fixes the
"single color, unreadable" bug.

**Alternatives**: remove `diff` — rejected; it is the natural preview. Keep old behavior behind
a flag — possible later, not now.

## R8. `init` writes baselines + gitignore

**Decision**: `agent_ws_copy_template_spec` (or a wrapper) also snapshots the copied template
into `.agent-workspace/baseline/<dst>` for framework files; template `.gitignore` gains
`.agent-workspace/baseline/`, `*.bak`, `*.merge`.

**Rationale**: New projects are sync-ready from day one; transient/working artifacts stay out
of version control (FR-016).

## R9. Command surface

**Decision**: Keep `sync` (no new `merge` command). `sync --dry-run` previews; `sync --apply`
performs merge + seeding. Update usage text in `commands.sh`.

**Rationale**: `sync` is already the "maintain a project" verb; users settled on not adding a
command. (spec Assumptions, report Q6.)
