# Tasks: Agent Workspace CLI

**Input**: Design documents from `/specs/001-agent-workspace-cli/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included because the implementation plan explicitly requires shell syntax checks and integration-style fixture tests for generated files, metadata, no-overwrite behavior, discovery, audit, diff, migration preview, and README quickstart validation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, etc.)
- Every task includes an exact file path

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the global CLI source layout, test harness skeleton, and installation entrypoints.

- [X] T001 Create global CLI source directories `lib/agent-ws/`, `tests/integration/`, `tests/fixtures/`, and `tests/smoke/`
- [X] T002 Create executable global CLI entrypoint skeleton in `bin/agent-ws`
- [X] T003 Create development installer skeleton in `install.sh`
- [X] T004 Implement `install.sh --prefix` to install `bin/agent-ws`, `lib/agent-ws/`, and `templates/` into a global or temporary prefix in `install.sh`
- [X] T005 Update legacy bootstrap transition behavior to point users toward `install.sh` and `agent-ws` in `bootstrap.sh`
- [X] T006 [P] Create command dispatch module placeholder in `lib/agent-ws/commands.sh`
- [X] T007 [P] Create template source module placeholder in `lib/agent-ws/templates.sh`
- [X] T008 [P] Create metadata module placeholder in `lib/agent-ws/metadata.sh`
- [X] T009 [P] Create discovery module placeholder in `lib/agent-ws/discovery.sh`
- [X] T010 [P] Create audit module placeholder in `lib/agent-ws/audit.sh`
- [X] T011 [P] Create diff module placeholder in `lib/agent-ws/diff.sh`
- [X] T012 [P] Create sync module placeholder in `lib/agent-ws/sync.sh`
- [X] T013 [P] Create update module placeholder in `lib/agent-ws/update.sh`
- [X] T014 [P] Create migration module placeholder in `lib/agent-ws/migrate.sh`
- [X] T015 [P] Create shared integration test helpers in `tests/integration/helpers.sh`
- [X] T016 [P] Create smoke test runner skeleton in `tests/smoke/run-smoke.sh`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement shared helpers required by every command before user story work begins.

**⚠️ CRITICAL**: No user story implementation should begin until this phase is complete.

- [X] T017 Implement CLI module loading and command dispatch in `bin/agent-ws` and `lib/agent-ws/commands.sh`
- [X] T018 Implement shared output, warning, error, and exit helpers in `lib/agent-ws/commands.sh`
- [X] T019 Implement argument parsing primitives for command, options, path, `--no-prompt`, `--profile`, `--agents`, `--custom-path`, `--dry-run`, `--apply`, and `--version` in `lib/agent-ws/commands.sh`
- [X] T020 Implement global template source resolution for repository checkout, installed payload, and selected release source in `lib/agent-ws/templates.sh`
- [X] T021 Implement safe copy-skip helper that creates parent directories and never overwrites active files in `lib/agent-ws/templates.sh`
- [X] T022 Implement project root and git-root safety helpers in `lib/agent-ws/commands.sh`
- [X] T023 Implement metadata JSON write helper with staged file replacement in `lib/agent-ws/metadata.sh`
- [X] T024 Implement metadata JSON read, invalid detection, stale revision detection, and privacy-safe field validation in `lib/agent-ws/metadata.sh`
- [X] T025 Implement supported profiles and agent adapter mappings in `lib/agent-ws/templates.sh`
- [X] T026 Implement custom path validation that rejects absolute paths and parent-directory escapes in `lib/agent-ws/templates.sh`
- [X] T027 [P] Add shell syntax smoke checks for all shell entrypoints in `tests/smoke/run-smoke.sh`
- [X] T028 [P] Add fixture builder helpers and an explicit fixture matrix for clean, partial, legacy, managed, invalid-metadata, and stale-metadata projects in `tests/integration/helpers.sh`
- [X] T029 [P] Add representative failure-message quality tests for clear explanation and next action in `tests/smoke/test_failure_messages.sh`

**Checkpoint**: Foundation ready — user story implementation can now begin.

---

## Phase 3: User Story 1 - Initialize a Project Workspace (Priority: P1) 🎯 MVP

**Goal**: A developer can run globally installed `agent-ws` to initialize the current directory or a named new directory with active files and `.agent-workspace/` metadata, without `.agent/`, project-local templates, or `bin/agent-workspace`.

**Independent Test**: Initialize a clean temporary project with `--profile code --agents pi --no-prompt`, verify expected active files and metadata exist, verify `.agent/` and `bin/agent-workspace` do not exist, then rerun and verify existing files are skipped.

### Tests for User Story 1

- [X] T030 [P] [US1] Add integration test for current-directory initialization in `tests/integration/test_init_current.sh`
- [X] T031 [P] [US1] Add integration test for named-directory initialization in `tests/integration/test_init_named_project.sh`
- [X] T032 [P] [US1] Add integration test for initialization no-overwrite behavior in `tests/integration/test_init_no_overwrite.sh`
- [X] T033 [P] [US1] Add integration test for metadata privacy and required fields in `tests/integration/test_metadata_contract.sh`
- [X] T034 [P] [US1] Add integration test proving `.agent/`, project-local template cache, and `bin/agent-workspace` are not created in `tests/integration/test_no_legacy_outputs.sh`

### Implementation for User Story 1

- [X] T035 [US1] Implement `agent-ws init` command routing in `lib/agent-ws/commands.sh`
- [X] T036 [US1] Implement current-directory initialization flow with git-root safety in `lib/agent-ws/commands.sh`
- [X] T037 [US1] Implement named project directory creation and initialization flow in `lib/agent-ws/commands.sh`
- [X] T038 [US1] Implement default file generation from global templates in `lib/agent-ws/templates.sh`
- [X] T039 [US1] Implement profile-specific generation for `general` and `code` profiles in `lib/agent-ws/templates.sh`
- [X] T040 [US1] Implement selected agent file generation during initialization in `lib/agent-ws/templates.sh`
- [X] T041 [US1] Implement `.agent-workspace/workspace.json` metadata creation during initialization in `lib/agent-ws/metadata.sh`
- [X] T042 [US1] Implement metadata generated-file mapping updates for initialization outputs in `lib/agent-ws/metadata.sh`
- [X] T043 [US1] Implement non-interactive `--no-prompt`, `--profile`, and `--agents` initialization behavior in `lib/agent-ws/commands.sh`
- [X] T044 [US1] Add init usage text to `agent-ws help` in `lib/agent-ws/commands.sh`

**Checkpoint**: User Story 1 is independently functional and provides the MVP.

---

## Phase 4: User Story 2 - Add Agent Support Later (Priority: P1)

**Goal**: A developer can add another supported agent entrypoint to an initialized project using global templates without overwriting existing project-owned files.

**Independent Test**: Initialize a project with one agent or none, run `agent-ws add-agent --agents claude --no-prompt`, verify only the new agent file is created and metadata is updated.

### Tests for User Story 2

- [X] T045 [P] [US2] Add integration test for adding a supported agent after initialization in `tests/integration/test_add_agent.sh`
- [X] T046 [P] [US2] Add integration test for add-agent no-overwrite behavior in `tests/integration/test_add_agent_no_overwrite.sh`
- [X] T047 [P] [US2] Add integration test for custom agent path validation in `tests/integration/test_custom_agent_path.sh`
- [X] T048 [P] [US2] Add integration test for multiple agents targeting the same destination without silent overwrite in `tests/integration/test_agent_destination_conflict.sh`

### Implementation for User Story 2

- [X] T049 [US2] Implement `agent-ws add-agent` command routing in `lib/agent-ws/commands.sh`
- [X] T050 [US2] Implement add-agent template copy flow using global template source in `lib/agent-ws/templates.sh`
- [X] T051 [US2] Implement add-agent metadata update for newly generated files in `lib/agent-ws/metadata.sh`
- [X] T052 [US2] Implement custom agent output flow using project-root-relative destination paths in `lib/agent-ws/templates.sh`
- [X] T053 [US2] Implement duplicate destination detection and clear skip/conflict reporting in `lib/agent-ws/templates.sh`
- [X] T054 [US2] Add add-agent usage text to `agent-ws help` in `lib/agent-ws/commands.sh`

**Checkpoint**: User Story 2 is independently functional after the foundational phase and can be validated on any initialized project.

---

## Phase 5: User Story 3 - Check One Project for Workspace Health (Priority: P2)

**Goal**: A developer can quickly check one project with `status` and deeply inspect one or more projects with `audit`, including metadata validity, stale metadata, legacy signals, template availability, and recovery guidance.

**Independent Test**: Run status and audit against fully initialized, partial, stale-metadata, invalid-metadata, and legacy-shaped fixtures and compare findings to fixture state.

### Tests for User Story 3

- [X] T055 [P] [US3] Add integration test for quick current-project status in `tests/integration/test_status.sh`
- [X] T056 [P] [US3] Add integration test for audit on managed, partial, and legacy fixtures in `tests/integration/test_audit.sh`
- [X] T057 [P] [US3] Add integration test for invalid and stale metadata reporting in `tests/integration/test_metadata_status_audit.sh`
- [X] T058 [P] [US3] Add integration test for partial-state recovery guidance in `tests/integration/test_audit_recovery_guidance.sh`

### Implementation for User Story 3

- [X] T059 [US3] Implement `agent-ws status` command routing in `lib/agent-ws/commands.sh`
- [X] T060 [US3] Implement quick project health summary in `lib/agent-ws/audit.sh`
- [X] T061 [US3] Implement `agent-ws audit` command routing for current or specified paths in `lib/agent-ws/commands.sh`
- [X] T062 [US3] Implement deep audit checks for expected files, metadata presence, metadata validity, stale metadata, and template availability in `lib/agent-ws/audit.sh`
- [X] T063 [US3] Implement legacy signal reporting for `.agent/` and `bin/agent-workspace` in `lib/agent-ws/audit.sh`
- [X] T064 [US3] Implement partial-state recovery guidance output in `lib/agent-ws/audit.sh`
- [X] T065 [US3] Add status and audit usage text to `agent-ws help` in `lib/agent-ws/commands.sh`

**Checkpoint**: User Story 3 is independently functional for one project and multi-path audit inputs.

---

## Phase 6: User Story 4 - Discover Agent Workspace Projects (Priority: P2)

**Goal**: A developer can scan one or more roots to identify strong and uncertain Agent Workspace projects while skipping heavy directories and version-control internals.

**Independent Test**: Create a directory tree with managed, legacy-shaped, weak-signal, and plain folders; run `agent-ws discover ROOT`; verify classifications and listed signals.

### Tests for User Story 4

- [X] T066 [P] [US4] Add integration test for discovery classification in `tests/integration/test_discover.sh`
- [X] T067 [P] [US4] Add integration test for discovery skip directories in `tests/integration/test_discover_skip_dirs.sh`
- [X] T068 [P] [US4] Add integration test proving discovery does not maintain a registry in `tests/integration/test_discover_no_registry.sh`

### Implementation for User Story 4

- [X] T069 [US4] Implement `agent-ws discover` command routing in `lib/agent-ws/commands.sh`
- [X] T070 [US4] Implement discovery traversal with skip rules for `.git`, `node_modules`, `.venv`, generated output, and heavy folders in `lib/agent-ws/discovery.sh`
- [X] T071 [US4] Implement discovery signal scoring for `.agent-workspace/`, legacy `.agent/`, `bin/agent-workspace`, and known active files in `lib/agent-ws/discovery.sh`
- [X] T072 [US4] Implement strong and uncertain discovery output with signal lists in `lib/agent-ws/discovery.sh`
- [X] T073 [US4] Add discover usage text to `agent-ws help` in `lib/agent-ws/commands.sh`

**Checkpoint**: User Story 4 is independently functional for explicit scan roots.

---

## Phase 7: User Story 5 - Safely Refresh Templates and CLI Versions (Priority: P3)

**Goal**: A developer can inspect template drift with read-only `diff`, run conservative `sync`, and update the global `agent-ws` from stable Git/GitHub releases or tags while preserving active files and the current working command on failure.

**Independent Test**: Modify an active file, run `agent-ws diff` and `agent-ws sync --dry-run`, verify no active files change; simulate an unavailable update and verify the previous `agent-ws` remains usable.

### Tests for User Story 5

- [X] T074 [P] [US5] Add integration test for read-only diff behavior in `tests/integration/test_diff.sh`
- [X] T075 [P] [US5] Add integration test for conservative sync dry-run preserving active files in `tests/integration/test_sync_dry_run.sh`
- [X] T076 [P] [US5] Add integration test for safe non-conflicting sync apply behavior in `tests/integration/test_sync_apply_safe.sh`
- [X] T077 [P] [US5] Add integration test for update latest stable selection rules in `tests/integration/test_update_latest_stable.sh`
- [X] T078 [P] [US5] Add integration test for update failure preserving previous command in `tests/integration/test_update_failure_preserves_current.sh`

### Implementation for User Story 5

- [X] T079 [US5] Implement `agent-ws diff` command routing in `lib/agent-ws/commands.sh`
- [X] T080 [US5] Implement active-file to global-template comparison in `lib/agent-ws/diff.sh`
- [X] T081 [US5] Implement stale metadata and unavailable template reporting for diff in `lib/agent-ws/diff.sh`
- [X] T082 [US5] Implement `agent-ws sync` command routing with `--dry-run` and `--apply` in `lib/agent-ws/commands.sh`
- [X] T083 [US5] Implement conservative sync behavior for metadata and comparison baselines in `lib/agent-ws/sync.sh`
- [X] T084 [US5] Implement active-file preservation and conflict stopping in `lib/agent-ws/sync.sh`
- [X] T085 [US5] Implement `agent-ws update` command routing with optional `--version` in `lib/agent-ws/commands.sh`
- [X] T086 [US5] Implement Git/GitHub stable release or tag lookup excluding pre-release, alpha, beta, and release-candidate versions in `lib/agent-ws/update.sh`
- [X] T087 [US5] Implement staged update download, validation, and replacement in `lib/agent-ws/update.sh`
- [X] T088 [US5] Implement update failure handling that preserves the current working command in `lib/agent-ws/update.sh`
- [X] T089 [US5] Add diff, sync, and update usage text to `agent-ws help` in `lib/agent-ws/commands.sh`

**Checkpoint**: User Story 5 is independently functional without changing active project-owned files by default.

---

## Phase 8: User Story 6 - Migrate From Current Local Model (Priority: P3)

**Goal**: A developer with older local Agent Workspace projects can follow migration documentation and run a dry-run migration helper that preserves active files and memory.

**Independent Test**: Use a legacy fixture containing `bin/agent-workspace`, `.agent/`, active instructions, and memory; follow docs or run `agent-ws migrate --dry-run`; verify active files are preserved and old project-local template caches are not inspected or used.

### Tests for User Story 6

- [X] T090 [P] [US6] Add integration test for migration dry-run preview in `tests/integration/test_migrate_dry_run.sh`
- [X] T091 [P] [US6] Add integration test for migration apply preserving active files and memory in `tests/integration/test_migrate_apply_preserves_active_files.sh`
- [X] T092 [P] [US6] Add integration test proving migration does not inspect old project-local template cache contents in `tests/integration/test_migrate_ignores_old_template_cache.sh`

### Implementation for User Story 6

- [X] T093 [US6] Write migration documentation section in `README.md`
- [X] T094 [US6] Implement `agent-ws migrate` command routing in `lib/agent-ws/commands.sh`
- [X] T095 [US6] Implement migration dry-run report for legacy `.agent/` and `bin/agent-workspace` signals in `lib/agent-ws/migrate.sh`
- [X] T096 [US6] Implement migration apply path that requires `--apply` and preserves active files and memory in `lib/agent-ws/migrate.sh`
- [X] T097 [US6] Implement legacy metadata creation during migration when safe in `lib/agent-ws/migrate.sh`
- [X] T098 [US6] Add migrate usage text to `agent-ws help` in `lib/agent-ws/commands.sh`

**Checkpoint**: User Story 6 is independently functional as documentation plus safe migration helper automation.

---

## Phase 9: User Story 7 - Understand and Use the CLI From README (Priority: P3)

**Goal**: A new user can install `agent-ws`, initialize a project, add an agent, understand metadata, and understand legacy migration from one clear README quickstart before seeing advanced options.

**Independent Test**: Follow only the README primary quickstart in a clean temporary environment and complete installation, initialization, and add-agent without needing competing flows.

### Tests for User Story 7

- [X] T099 [P] [US7] Add README quickstart smoke validation in `tests/smoke/test_readme_quickstart.sh`
- [X] T100 [P] [US7] Add documentation grep check that README introduces one primary quickstart before advanced options in `tests/smoke/test_readme_structure.sh`

### Implementation for User Story 7

- [X] T101 [US7] Rewrite README overview and primary quickstart around `agent-ws` in `README.md`
- [X] T102 [US7] Document install and update flow from Git/GitHub stable releases or tags in `README.md`
- [X] T103 [US7] Document `agent-ws init`, `add-agent`, `status`, `audit`, `discover`, `diff`, `sync`, `update`, and `migrate` command summaries in `README.md`
- [X] T104 [US7] Document `.agent-workspace/` metadata ownership and privacy rules in `README.md`
- [X] T105 [US7] Document that templates are global and active instruction files are project-owned in `README.md`
- [X] T106 [US7] Move advanced non-interactive and custom options after the primary quickstart in `README.md`

**Checkpoint**: User Story 7 is independently functional as user-facing documentation.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, cleanup, and consistency checks across all stories.

- [X] T107 [P] Run shell syntax checks for `bin/agent-ws`, `install.sh`, and `lib/agent-ws/*.sh`
- [X] T108 [P] Run all integration tests in `tests/integration/`
- [X] T109 [P] Add lightweight timing validation for init, add-agent, and update scenarios in `tests/smoke/test_timing_targets.sh`
- [X] T110 [P] Run all smoke tests in `tests/smoke/`
- [X] T111 Review code comments and docstrings for public entrypoints and non-obvious shell logic in `bin/agent-ws` and `lib/agent-ws/*.sh`
- [X] T112 Remove obsolete debug output and temporary scaffolding from `bin/agent-ws`, `install.sh`, and `lib/agent-ws/*.sh`
- [X] T113 Validate quickstart scenarios from `specs/001-agent-workspace-cli/quickstart.md`
- [X] T114 Verify generated docs and implementation do not describe new project-local template caches in `README.md` and `specs/001-agent-workspace-cli/*.md`
- [X] T115 Review task completion against `specs/001-agent-workspace-cli/contracts/cli.md` and `specs/001-agent-workspace-cli/contracts/metadata.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies; can start immediately.
- **Phase 2 Foundational**: Depends on Phase 1; blocks every user story.
- **Phase 3 US1 Initialization**: Depends on Phase 2; MVP scope.
- **Phase 4 US2 Add Agent**: Depends on Phase 2 and is easiest after US1 metadata/init exists.
- **Phase 5 US3 Status/Audit**: Depends on Phase 2; benefits from US1 fixtures but can be built with the explicit fixture matrix independently.
- **Phase 6 US4 Discovery**: Depends on Phase 2; can proceed after fixture helpers and the explicit fixture matrix exist.
- **Phase 7 US5 Diff/Sync/Update**: Depends on Phase 2 and metadata/template helpers.
- **Phase 8 US6 Migration**: Depends on Phase 2 and audit/metadata helpers.
- **Phase 9 US7 README**: Depends on command contract and can proceed alongside later implementation, but final README validation depends on implemented commands.
- **Phase 10 Polish**: Depends on all desired stories being complete.

### User Story Dependencies

- **US1 (P1)**: First MVP story; no other story dependency after foundation.
- **US2 (P1)**: Depends on foundation; practically uses US1 metadata/init behavior for end-to-end validation.
- **US3 (P2)**: Depends on foundation; can test against the explicit fixture matrix before all commands exist.
- **US4 (P2)**: Depends on foundation and fixture helpers with the explicit fixture matrix.
- **US5 (P3)**: Depends on metadata/template helpers and benefits from US1 outputs.
- **US6 (P3)**: Depends on metadata helpers; migration documentation and safe helper automation are required.
- **US7 (P3)**: Documentation story can start early, but final validation depends on implemented command behavior.

### Within Each User Story

- Write integration/smoke tests first and confirm they fail before implementation.
- Implement command routing before command-specific modules.
- Implement metadata/template helpers before commands that depend on them.
- Validate each story independently before moving to lower-priority stories.

---

## Parallel Opportunities

- Setup module placeholder tasks T006–T016 can run in parallel after T001.
- Foundational smoke and fixture tasks T027–T028 can run in parallel with helper implementation tasks T017–T026 where files do not overlap.
- Test tasks within each user story are parallelizable because they target separate test files.
- After Phase 2, US3 status/audit, US4 discovery, US6 migration docs, and US7 README can proceed in parallel with minimal file overlap.
- US5 update tests and diff/sync tests can be split across separate files and implemented independently after template and metadata helpers exist.

## Parallel Examples

### User Story 1

```bash
Task: "T030 [P] [US1] Add integration test for current-directory initialization in tests/integration/test_init_current.sh"
Task: "T031 [P] [US1] Add integration test for named-directory initialization in tests/integration/test_init_named_project.sh"
Task: "T033 [P] [US1] Add integration test for metadata privacy and required fields in tests/integration/test_metadata_contract.sh"
```

### User Story 3

```bash
Task: "T055 [P] [US3] Add integration test for quick current-project status in tests/integration/test_status.sh"
Task: "T056 [P] [US3] Add integration test for audit on managed, partial, and legacy fixtures in tests/integration/test_audit.sh"
Task: "T057 [P] [US3] Add integration test for invalid and stale metadata reporting in tests/integration/test_metadata_status_audit.sh"
```

### User Story 7

```bash
Task: "T099 [P] [US7] Add README quickstart smoke validation in tests/smoke/test_readme_quickstart.sh"
Task: "T100 [P] [US7] Add documentation grep check that README introduces one primary quickstart before advanced options in tests/smoke/test_readme_structure.sh"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational helpers.
3. Complete Phase 3: US1 initialization.
4. Stop and validate US1 using `tests/integration/test_init_current.sh`, `tests/integration/test_init_named_project.sh`, `tests/integration/test_init_no_overwrite.sh`, `tests/integration/test_metadata_contract.sh`, and `tests/integration/test_no_legacy_outputs.sh`.
5. Demo `agent-ws init --profile code --agents pi --no-prompt` in a clean temporary project.

### Incremental Delivery

1. Setup + Foundational → shared CLI skeleton ready.
2. US1 → global initialization MVP.
3. US2 → add-agent lifecycle.
4. US3 + US4 → status/audit/discovery lifecycle visibility.
5. US5 → diff/sync/update safe maintenance.
6. US6 → migration documentation and safe helper.
7. US7 → final user-facing README flow.

### Parallel Team Strategy

With multiple implementers:

1. One person completes command dispatch and shared helper foundation.
2. Separate people can implement status/audit, discovery, README, and migration docs in parallel after foundation.
3. Diff/sync/update should be implemented by one person or tightly coordinated because they share template/release metadata behavior.

---

## Notes

- `[P]` tasks target different files or independent test files.
- `[US#]` labels map directly to user stories in `spec.md`.
- Tests are integration/smoke shell tests because this is a Bash CLI.
- Migration documentation and the safe migration helper are required for MVP.
- Old project-local template caches are outside supported product logic and must not influence migration behavior.
- Active instruction files and memory are project-owned and must not be overwritten silently.
