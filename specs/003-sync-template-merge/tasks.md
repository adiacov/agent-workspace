---
description: "Task list for merge-based sync"
---

# Tasks: Sync merges template changes into projects

**Input**: Design documents from `specs/003-sync-template-merge/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/sync-cli.md, quickstart.md

**Tests**: Included — the spec defines Independent Tests per story and quickstart lists unit +
integration coverage. Tests are written to FAIL first, then implementation makes them pass.

**Organization**: Grouped by user story (US1–US4) for independent implementation/testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on incomplete tasks)
- **[Story]**: US1–US4 maps to spec user stories
- All paths are repo-root-relative

## Path Conventions

Single-project CLI: shell modules in `lib/agent-ws/`, tests in `tests/{unit,integration,smoke}/`,
templates in `templates/default/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: scaffolding for new modules and tests

- [x] T001 Create empty modules `lib/agent-ws/merge.sh` and `lib/agent-ws/baseline.sh` with the
  `#!/usr/bin/env bash` header and a top comment, and source them wherever `sync.sh`/`diff.sh`
  are loaded (find the loader, e.g. `bin/agent-ws` or `lib/agent-ws/commands.sh` includes).
- [x] T002 Create `tests/unit/` with a minimal runner consistent with `tests/smoke/`'s style
  (locate how smoke/integration tests are invoked, e.g. a `run.sh`, and mirror it).
- [x] T003 [P] Add `.agent-workspace/baseline/`, `*.bak`, and `*.merge` to
  `templates/default/.gitignore`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: shared helpers every story depends on. ⚠️ No story work begins until these exist.

- [x] T004 [P] In `lib/agent-ws/templates.sh` (or `metadata.sh`), add a classification helper
  `agent_ws_file_is_framework <kind>` returning true for `default|profile|adapter`, false for
  `context` (per data-model.md). Single source of truth used by sync and diff.
- [x] T005 [P] In `lib/agent-ws/baseline.sh`, implement baseline path + IO helpers:
  `agent_ws_baseline_path <project> <active-path>` →
  `<project>/.agent-workspace/baseline/<active-path>`; `agent_ws_baseline_exists`;
  `agent_ws_baseline_write <project> <active-path> <template-file>` (mkdir -p + copy).
- [x] T006 In `lib/agent-ws/merge.sh`, implement `agent_ws_merge_three_way <ours> <base>
  <theirs> <out>` wrapping `git merge-file -p` (labels via `-L`), returning 0 = clean,
  1 = conflict, writing merged content (with markers on conflict) to `<out>`.
- [x] T007 In `lib/agent-ws/merge.sh`, implement safe-write helpers: `agent_ws_backup_create`,
  `agent_ws_backup_remove`, `agent_ws_backup_restore`, and `agent_ws_atomic_write <tmp>
  <dest>` (temp file → `.bak` of original → `mv` into place). Whole-run success removes backups;
  failure restores (per R5/FR-006/FR-007).
- [x] T008 [P] In `lib/agent-ws/baseline.sh`, add `agent_ws_ensure_gitignore <project>` that
  appends `.agent-workspace/baseline/`, `*.bak`, `*.merge` to the project's `.gitignore` if
  absent (idempotent) — used when seeding existing projects (FR-017).

**Checkpoint**: helpers exist and are unit-testable.

---

## Phase 3: User Story 1 — Additive template change flows in (Priority: P1) 🎯 MVP

**Goal**: `sync --apply` brings a new template section into a locally-edited framework file,
preserving local edits; `--dry-run` previews; identical files report unchanged.

**Independent Test**: init project, edit `WORKFLOWS.md`, add a template section, sync → section
present + local edits intact.

### Tests for User Story 1 ⚠️ (write first, must FAIL)

- [x] T009 [P] [US1] Unit test in `tests/unit/test_merge_three_way.sh`: clean additive merge
  returns 0 and output contains both the template addition and the local edit.
- [x] T010 [P] [US1] Integration test `tests/integration/test_sync_additive` (quickstart
  Scenario 1): apply brings `## NewSection` into edited `WORKFLOWS.md`, local line preserved,
  exit 0, no `.bak`/`.merge` left, baseline refreshed. Output stays in a temp dir (no repo
  pollution).
- [x] T011 [P] [US1] Integration test `tests/integration/test_sync_noop`: when active == template,
  sync reports `unchanged` and writes nothing.

### Implementation for User Story 1

- [x] T012 [US1] Rewrite `agent_ws_sync_project` in `lib/agent-ws/sync.sh` to iterate
  `generatedFiles` (via `agent_ws_metadata_generated_paths`), skip non-framework files (T004),
  and for each framework file resolve OURS/BASE/THEIRS and call the merge (T006).
- [x] T013 [US1] In `sync.sh`, implement the clean-merge apply path: atomic write (T007) +
  baseline refresh (T005), outcome `updated`; and the `unchanged` short-circuit (`cmp` BASE vs
  THEIRS, or merged == OURS).
- [x] T014 [US1] In `sync.sh`, implement `--dry-run`: compute and report per-file would-be
  outcomes without modifying anything (contract: dry-run mutates nothing, exit 0).
- [x] T015 [US1] In `init` path (`lib/agent-ws/templates.sh`
  `agent_ws_copy_template_spec`/`agent_ws_generate_*`), write a baseline (T005) for each
  framework file created, so new projects are sync-ready.

**Checkpoint**: US1 fully functional and independently testable (MVP).

---

## Phase 4: User Story 2 — Conflicts never corrupt a file (Priority: P1)

**Goal**: overlapping edits are reconciled by an agent or refused safely (live file untouched,
`*.merge` written, non-zero exit); no completed apply leaves markers in a live file; backups
protect every write.

**Independent Test**: overlapping change, agentless apply → live file unchanged, `.merge`
present with markers, non-zero exit.

### Tests for User Story 2 ⚠️ (write first, must FAIL)

- [x] T016 [P] [US2] Unit test `tests/unit/test_merge_conflict.sh`: overlapping inputs return 1
  and produce marker output.
- [x] T017 [P] [US2] Unit test `tests/unit/test_backup.sh`: backup created before write, removed
  on success, restores original on simulated failure.
- [x] T018 [P] [US2] Integration test `tests/integration/test_sync_conflict_refuse` (quickstart
  Scenario 2): agentless conflict → live file byte-identical, `WORKFLOWS.md.merge` exists with
  markers, exit non-zero.
- [x] T019 [P] [US2] Integration test `tests/integration/test_sync_atomicity` (quickstart
  Scenario 6): forced write failure restores from `.bak`, no partial file remains.

### Implementation for User Story 2

- [x] T020 [US2] In `sync.sh`, implement the deterministic conflict branch: on merge exit 1,
  write `<file>.merge` (do NOT touch the live file), mark file `conflicted`, and record a
  run-level non-zero exit. No inline agent resolution (F1).
- [x] T021 [US2] In `sync.sh`, on a clean merge, guard FR-005: if the merged output unexpectedly
  contains conflict markers, treat it as a conflict (refuse + `.merge`) rather than writing the
  live file.
- [x] T022 [US2] In `sync.sh`, add the final invariant check: assert no live file written this
  run contains conflict markers before reporting success; wire run exit code (non-zero iff any
  `conflicted`).

**Checkpoint**: US1 + US2 both pass; safety guarantees enforced.

---

## Phase 5: User Story 3 — Seed baseline for existing projects (Priority: P2)

**Goal**: first sync on a baseline-less project seeds baselines and applies nothing destructive;
the next sync reconciles normally.

**Independent Test**: remove baseline dir, sync → `seeded` reported, baseline recreated; second
sync after a template change behaves like US1.

### Tests for User Story 3 ⚠️ (write first, must FAIL)

- [x] T023 [P] [US3] Integration test `tests/integration/test_sync_seed_existing` (quickstart
  Scenario 3): no-baseline apply reports `seeded`, recreates baseline, no destructive change,
  AND the project `.gitignore` gains the baseline/`*.bak`/`*.merge` exclusions (FR-017);
  follow-up template change then merges cleanly.

### Implementation for User Story 3

- [x] T024 [US3] In `sync.sh`, add the no-baseline branch: when BASE is absent for a framework
  file, seed BASE = THEIRS (T005), outcome `seeded`, apply nothing destructive on this run (R6);
  on first seed in the project, call `agent_ws_ensure_gitignore` (T008) so the exclusions exist
  (FR-017).

**Checkpoint**: pre-existing projects (e.g. sibling `checkpoint/`) become sync-capable.

---

## Phase 6: User Story 4 — Preview incoming delta, skip content files (Priority: P3)

**Goal**: `diff` shows the incoming `baseline→template` delta for framework files only, colorized
and `NO_COLOR`/non-TTY aware; content files (`context`) are never modified or flagged.

**Independent Test**: diff shows incoming additions for framework files only (colorized on TTY,
plain otherwise); STATE.md/PROJECT.md never appear or change.

### Tests for User Story 4 ⚠️ (write first, must FAIL)

- [x] T025 [P] [US4] Integration test `tests/integration/test_diff_incoming_delta` (quickstart
  Scenario 5): diff reports `baseline→template` delta for framework files; `NO_COLOR=1` yields
  plain output; `context` files absent.
- [x] T026 [P] [US4] Integration test `tests/integration/test_sync_skips_content` (quickstart
  Scenario 4): rewritten STATE.md/PROJECT.md reported `skipped-content` and unchanged after
  dry-run and apply.

### Implementation for User Story 4

- [x] T027 [US4] Repurpose `agent_ws_diff_project` in `lib/agent-ws/diff.sh` to compare
  baseline (BASE) vs current template (THEIRS) for framework files only (skip `context` via
  T004); handle the no-baseline case with a "run sync to seed" note.
- [x] T028 [US4] Add colorized add/remove output to diff, honoring `NO_COLOR` and non-TTY
  (plain) per R7/FR-014.

**Checkpoint**: all four stories independently functional.

---

## Phase 7: Polish & Cross-Cutting

- [x] T029 [P] Update `lib/agent-ws/commands.sh` usage/help for `sync` (merge + seeding under
  `--apply`) and `diff` (incoming-delta preview); keep top-level `help` summaries in sync.
- [x] T030 [P] Add smoke coverage in `tests/smoke/` for `sync`/`diff` help text and
  flag validation (mutually-exclusive `--dry-run`/`--apply`, single path).
- [x] T031 Update `README.md` sections "Metadata and ownership" and "Synchronization for
  existing global projects" to describe the merge model, baseline (gitignored), seeding, and the
  relaxed ownership boundary.
- [x] T032 Bump `VERSION` and add a `CHANGELOG.md` entry describing merge-based sync.
- [x] T033 Run the full `quickstart.md` (Scenarios 1–6) end-to-end and the whole test suite from
  the repo root; confirm zero repo pollution and all green.

---

## Dependencies & Execution Order

- **Setup (P1: T001–T003)**: first.
- **Foundational (P2: T004–T008)**: blocks all stories. T004/T005 are [P]; T006→T007→T008 build
  in `merge.sh`.
- **US1 (P3)**: needs Foundational. MVP. T009–T011 (tests) before T012–T015.
- **US2 (P4)**: needs Foundational + US1's `sync.sh` skeleton (T012). Tests T016–T019 before
  T020–T022.
- **US3 (P5)**: needs US1 skeleton (T012). T023 before T024.
- **US4 (P6)**: needs Foundational (T004/T005). Independent of US2/US3. T025–T026 before
  T027–T028.
- **Polish (P7)**: after the stories it documents/tests.

### Parallel opportunities
- T004 ∥ T005; all per-story test tasks marked [P] (different files); US4 can proceed in
  parallel with US2/US3 once Foundational is done.

## Implementation Strategy

1. Setup + Foundational.
2. **US1 = MVP** → validate Scenario 1, stop/demo.
3. US2 (safety) → US3 (seeding) → US4 (preview/diff).
4. Polish: docs, version, full quickstart + suite.

## Notes
- Tests written to FAIL before implementation (TDD per spec request).
- Keep integration outputs in temp dirs (repo recently fixed `*.out` pollution — do not regress).
- Commit after each story/logical group on branch `003-sync-template-merge`.
