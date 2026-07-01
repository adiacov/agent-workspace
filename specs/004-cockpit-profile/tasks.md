---
description: "Task list for the cockpit profile"
---

# Tasks: `cockpit` profile

**Input**: Design documents from `specs/004-cockpit-profile/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/cockpit-cli.md, quickstart.md

**Tests**: Included — spec defines Independent Tests per story; plan lists unit + integration +
smoke coverage. New assertions are added to fail against the pre-change code, then implementation
makes them pass.

**Organization**: Grouped by user story (US1–US3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on incomplete tasks)
- All paths are repo-root-relative

## Path Conventions

Single-project CLI: shell modules in `lib/agent-ws/`, templates in
`templates/{default,profiles}/`, tests in `tests/{unit,integration,smoke}/`, docs at repo root.

---

## Phase 1: Templates (Shared Infrastructure)

**Purpose**: the neutral, project-owned scaffolding the profile ships (FR-002, FR-003, FR-005, FR-006)

- [x] T001 [P] [US1] Create `templates/profiles/cockpit/PROJECTS.md` — project index with
  obviously-placeholder rows (name · purpose · coarse status · path→own STATE.md); neutral,
  not software-only.
- [x] T002 [P] [US1] Create `templates/profiles/cockpit/PROFILE.md` — strategy/context skeleton
  (background, goals, constraints, preferences) with placeholder content.
- [x] T003 [P] [US1] Create `templates/profiles/cockpit/STATE.md` — cockpit cross-cutting index
  variant (current focus, current question, coarse per-project status pointing at each repo's own
  STATE.md); names itself a cockpit and points to `WORKFLOWS-COCKPIT.md` and `PROJECTS.md`.
- [x] T004 [P] [US2] Create `templates/profiles/cockpit/WORKFLOWS-COCKPIT.md` — control-room
  workflows: cross-project one-way-dependency rule, explore→build→reflect loop, handoff-ingest
  ritual (FR-005).

## Phase 2: Generator + validation wiring

**Purpose**: make `--profile cockpit` produce the file set and flow through metadata/audit

- [x] T005 [US1] `lib/agent-ws/templates.sh`: make `agent_ws_default_template_files` accept an
  optional `profile`; for `cockpit` swap the `STATE.md` source to `profiles/cockpit/STATE.md`
  (destination + `context` kind unchanged). Update `agent_ws_generate_default_files` to pass the
  profile through.
- [x] T006 [US1] `lib/agent-ws/templates.sh`: add a `cockpit)` branch to
  `agent_ws_profile_template_files` listing `PROJECTS.md`, `PROFILE.md`, `WORKFLOWS-COCKPIT.md`
  with correct kinds; update the `*)` error hint to list `general`, `code`, `cockpit`.
- [x] T007 [US1] `lib/agent-ws/commands.sh`: `init` passes `profile` to
  `agent_ws_generate_default_files`; extend the `--no-prompt` accept-list, `agent_ws_prompt_profile`
  accept-list/prompt, the `--profile` flag error hints, help/usage text, and the example line to
  include `cockpit` (FR-001, FR-011, FR-012).
- [x] T008 [P] [US3] `lib/agent-ws/migrate.sh`: add `PROJECTS.md`, `PROFILE.md`,
  `WORKFLOWS-COCKPIT.md` to `agent_ws_migrate_preserved_files` and the record→template mapping in
  `agent_ws_migrate_generated_records` (FR-013).

## Phase 3: Tests

- [x] T009 [P] [US1] `tests/unit/`: assert `agent_ws_profile_template_files cockpit` lists the
  three cockpit files; `agent_ws_default_template_files cockpit` swaps only the `STATE.md` source;
  `general`/`code` return unchanged sets (FR-010).
- [x] T010 [US1] `tests/integration/`: `init --profile cockpit --agents pi --no-prompt` creates the
  full set; metadata records `profile: cockpit`; `audit` passes with no missing files (FR-002,
  FR-007, FR-008; SC-001).
- [x] T011 [P] [US3] `tests/integration/`: regression — `init --profile general` and `--profile
  code` output + metadata unchanged; invalid `--profile` error lists three profiles (FR-010, SC-003).
- [x] T012 [P] [US1] `tests/smoke/`: cockpit init happy path asserting file presence + metadata.

## Phase 4: Documentation

- [x] T013 [US3] `README.md`: add top-of-file "What you can build" block (two shapes + one-line
  choosing rule) after the intro, before concept-heavy sections; keep any longer walkthrough lower
  (FR-014, SC-004).
- [x] T014 [P] [US3] `README.md`: add `cockpit` to "Supported profiles"/any profile table with a
  same-altitude description of what it is and when to choose it (FR-016).
- [x] T015 [P] [US3] `README.md`: add a short, optional "Complementary tools" note for `checkpoint`
  linking `https://github.com/adiacov/checkpoint`, near the human+agent collaboration model (FR-015).
- [x] T016 [P] [US3] Remove/correct stale docs across `README.md` and `SPEC.md` (project-local
  `bin/agent-workspace` references, two-profile assumptions) (FR-017).

## Phase 5: Verification

- [x] T017 Run the full suite (`tests/smoke` + `tests/unit` + `tests/integration`); confirm green
  and zero repo pollution.
- [x] T018 Manual: `init --profile cockpit` in a temp dir + `audit`; eyeball generated files;
  update `CHANGELOG.md`, `VERSION`, and `STATE.md`.

## Dependencies

- Phase 1 templates block T005–T006 (generator references them) and T010/T012 (integration copies
  them).
- T005 before T007 (init passes the profile the generator now accepts).
- T006 before T009/T010 (profile file set must exist).
- Docs (Phase 4) are independent of code and can proceed in parallel once decisions are fixed.
