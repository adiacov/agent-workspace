# Tasks: Release, Install, and Update Hardening

**Input**: Design documents from `/specs/002-release-install-update/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included because the specification and plan explicitly require smoke/integration coverage for version reporting, install/update success, pinned installs, and failed install/update safety.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, etc.)
- Every task includes an exact file path

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish version source, release configuration seams, and shared test fixtures used by all release lifecycle stories.

- [ ] T001 Create root version source with initial `v0.1.0` value in `VERSION`
- [ ] T002 Add shared release/install test fixture helpers in `tests/integration/helpers.sh`
- [ ] T003 [P] Add shell syntax coverage for `VERSION`, `install.sh`, `bin/agent-ws`, and `lib/agent-ws/*.sh` in `tests/smoke/run-smoke.sh`
- [ ] T004 [P] Add README placeholder sections for install, pinned install, version, update, uninstall, platforms, and release expectations in `README.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement shared version, staging, validation, and release-resolution primitives required before any install/update user story can be completed.

**⚠️ CRITICAL**: No user story work should begin until this phase is complete.

- [ ] T005 Implement version source discovery helper for checkout and installed payload layouts in `lib/agent-ws/commands.sh`
- [ ] T006 Implement shared version file validation helper in `lib/agent-ws/commands.sh`
- [ ] T007 Implement staged install directory creation and cleanup helpers in `install.sh`
- [ ] T008 Implement staged payload validation helper that runs candidate `agent-ws version` in `install.sh`
- [ ] T009 Implement safe activation helper that replaces active install only after validation in `install.sh`
- [ ] T010 Implement GitHub release/tag configuration constants and environment overrides in `install.sh`
- [ ] T011 Implement stable version filtering helper that excludes alpha, beta, rc, and prerelease suffixes in `install.sh`
- [ ] T012 Implement default remote install latest-stable release/tag resolution in `install.sh`
- [ ] T013 Implement shared update staging and validation helpers in `lib/agent-ws/update.sh`
- [ ] T014 Implement shared latest stable release/tag resolution helper in `lib/agent-ws/update.sh`
- [ ] T015 Implement reusable failure-stage error messages for release resolution, download, staging, validation, and activation in `install.sh`
- [ ] T016 Mirror reusable failure-stage error messages for update paths in `lib/agent-ws/update.sh`

**Checkpoint**: Foundation ready - version, staging, validation, and release resolution primitives exist for story work.

---

## Phase 3: User Story 1 - Install Without Cloning (Priority: P1) 🎯 MVP

**Goal**: A new user can install `agent-ws` from a documented one-line remote command without manually cloning the repository, and failed installs preserve any previous working command.

**Independent Test**: Run remote-style install into a temporary prefix, confirm `agent-ws` is executable, then simulate install failure over an existing install and confirm the previous command still works.

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T017 [P] [US1] Add remote-style latest-stable archive install integration test in `tests/integration/test_install_remote.sh`
- [ ] T018 [P] [US1] Add failed remote install preservation integration test in `tests/integration/test_install_remote_failure_safety.sh`
- [ ] T019 [P] [US1] Add local checkout install validation test with staged activation expectations in `tests/integration/test_install_local_staged.sh`

### Implementation for User Story 1

- [ ] T020 [US1] Extend `install.sh` argument and environment parsing for `--prefix` and `AGENT_WS_PREFIX` in `install.sh`
- [ ] T021 [US1] Implement local checkout install through staged payload activation in `install.sh`
- [ ] T022 [US1] Implement remote/curl mode detection when `install.sh` is not running from a checkout in `install.sh`
- [ ] T023 [US1] Implement release archive download and extraction into staging in `install.sh`
- [ ] T024 [US1] Install `bin/agent-ws`, `lib/agent-ws/`, `templates/`, and `VERSION` from staged payload in `install.sh`
- [ ] T025 [US1] Add PATH visibility guidance after successful install in `install.sh`
- [ ] T026 [US1] Preserve existing active install on download, staging, or validation failure in `install.sh`
- [ ] T027 [US1] Update default one-line install documentation in `README.md`

**Checkpoint**: User Story 1 is independently testable with remote-style and local checkout install flows.

---

## Phase 4: User Story 2 - Verify Installed Version (Priority: P1)

**Goal**: A user can run `agent-ws version` and see the installed payload version clearly.

**Independent Test**: Install into a temporary prefix and run `agent-ws version`, confirming output matches `VERSION` and works from the installed layout.

### Tests for User Story 2 ⚠️

- [ ] T028 [P] [US2] Add installed version command integration test in `tests/integration/test_version.sh`
- [ ] T029 [P] [US2] Add missing or invalid installed version source failure test in `tests/integration/test_version_invalid_payload.sh`
- [ ] T030 [P] [US2] Add `agent-ws help version` contract test in `tests/integration/test_help_version.sh`

### Implementation for User Story 2

- [ ] T031 [US2] Add `version` command dispatch in `lib/agent-ws/commands.sh`
- [ ] T032 [US2] Implement `agent_ws_command_version` using the shared version source helper in `lib/agent-ws/commands.sh`
- [ ] T033 [US2] Ensure `agent-ws version` reads the installed payload `VERSION` location in `lib/agent-ws/commands.sh`
- [ ] T034 [US2] Add `agent-ws help version` content in `lib/agent-ws/commands.sh`
- [ ] T035 [US2] Update version command documentation in `README.md`

**Checkpoint**: User Story 2 is independently testable after any successful local or remote-style install.

---

## Phase 5: User Story 3 - Install a Specific Release (Priority: P2)

**Goal**: A user can request a specific release during install and gets exactly that version, or a safe failure if the release is unavailable.

**Independent Test**: Run pinned install into a temporary prefix and confirm reported version matches the requested release; run invalid pinned install over an existing install and confirm the previous command remains usable.

### Tests for User Story 3 ⚠️

- [ ] T036 [P] [US3] Add pinned remote-style install integration test in `tests/integration/test_install_pinned.sh`
- [ ] T037 [P] [US3] Add invalid pinned install preservation test in `tests/integration/test_install_pinned_failure_safety.sh`
- [ ] T038 [P] [US3] Add pinned version environment parsing test in `tests/integration/test_install_version_env.sh`

### Implementation for User Story 3

- [ ] T039 [US3] Add `AGENT_WS_VERSION` support for pinned install selection in `install.sh`
- [ ] T040 [US3] Implement exact release identifier validation for pinned install in `install.sh`
- [ ] T041 [US3] Ensure pinned install validates staged reported version matches requested version in `install.sh`
- [ ] T042 [US3] Add invalid pinned release failure messaging in `install.sh`
- [ ] T043 [US3] Update pinned install documentation in `README.md`

**Checkpoint**: User Story 3 supports reproducible pinned installs without weakening install failure safety.

---

## Phase 6: User Story 4 - Update Safely (Priority: P2)

**Goal**: A user can explicitly update an installed command to latest stable or selected version, with staged validation and previous-install preservation on failure.

**Independent Test**: Install an older fixture release, run update, confirm version changes and output reports before/after; simulate update failure and confirm previous version still runs.

### Tests for User Story 4 ⚠️

- [ ] T044 [P] [US4] Add staged update success integration test in `tests/integration/test_update_staged.sh`
- [ ] T045 [P] [US4] Add update failure preservation integration test in `tests/integration/test_update_failure_safety.sh`
- [ ] T046 [P] [US4] Add pinned update integration test in `tests/integration/test_update_pinned.sh`
- [ ] T047 [P] [US4] Add latest stable filtering integration test for update resolution in `tests/integration/test_update_latest_stable.sh`
- [ ] T048 [P] [US4] Add `agent-ws help update` contract test in `tests/integration/test_help_update.sh`

### Implementation for User Story 4

- [ ] T049 [US4] Replace placeholder update behavior with staged update orchestration in `lib/agent-ws/update.sh`
- [ ] T050 [US4] Implement installed prefix discovery for active command updates in `lib/agent-ws/update.sh`
- [ ] T051 [US4] Implement latest stable update resolution using releases or stable tags in `lib/agent-ws/update.sh`
- [ ] T052 [US4] Implement `--version VERSION` pinned update selection in `lib/agent-ws/update.sh`
- [ ] T053 [US4] Implement update archive download and extraction into staging in `lib/agent-ws/update.sh`
- [ ] T054 [US4] Validate staged update by running staged `agent-ws version` in `lib/agent-ws/update.sh`
- [ ] T055 [US4] Activate staged update only after validation and preserve previous install on failure in `lib/agent-ws/update.sh`
- [ ] T056 [US4] Report previous version, new version, command path, and failed stage details in `lib/agent-ws/update.sh`
- [ ] T057 [US4] Add or update `agent-ws help update` content in `lib/agent-ws/commands.sh`
- [ ] T058 [US4] Update safe update documentation in `README.md`

**Checkpoint**: User Story 4 supports safe latest and pinned updates without corrupting active installs on failure.

---

## Phase 7: User Story 5 - Follow Public Documentation (Priority: P3)

**Goal**: README readers can understand install, pin, version, update, cleanup, supported platforms, and release/versioning expectations without private context.

**Independent Test**: Review README and execute documented happy-path quickstart commands in a temporary prefix.

### Tests for User Story 5 ⚠️

- [ ] T059 [P] [US5] Add README lifecycle command coverage check in `tests/smoke/run-smoke.sh`
- [ ] T060 [P] [US5] Add quickstart lifecycle validation script in `tests/smoke/test_release_lifecycle_quickstart.sh`
- [ ] T061 [P] [US5] Add installed CLI init-after-install validation in `tests/smoke/test_release_lifecycle_quickstart.sh`

### Implementation for User Story 5

- [ ] T062 [US5] Document supported platforms and native Windows non-goal in `README.md`
- [ ] T063 [US5] Document release/versioning expectations and `vMAJOR.MINOR.PATCH` convention in `README.md`
- [ ] T064 [US5] Document uninstall/manual cleanup steps for installed command and support files in `README.md`
- [ ] T065 [US5] Update `specs/002-release-install-update/quickstart.md` with final install URL and validated commands

**Checkpoint**: User Story 5 is complete when README and quickstart cover the full public lifecycle.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, consistency, and cleanup across all stories.

- [ ] T066 [P] Run shell syntax checks for `bin/agent-ws`, `install.sh`, and `lib/agent-ws/*.sh`
- [ ] T067 [P] Run all release lifecycle integration tests in `tests/integration/`
- [ ] T068 [P] Run smoke tests in `tests/smoke/run-smoke.sh`
- [ ] T069 Validate quickstart scenarios in `specs/002-release-install-update/quickstart.md`
- [ ] T070 Review release lifecycle requirements checklist findings in `specs/002-release-install-update/checklists/release-lifecycle.md`
- [ ] T071 Update `STATE.md` to summarize completed phase 002 status and next action
- [ ] T072 Review changed shell comments and remove temporary debug output in `install.sh`, `lib/agent-ws/commands.sh`, and `lib/agent-ws/update.sh`
- [ ] T073 Verify README commands and implementation behavior match `specs/002-release-install-update/contracts/cli.md` and `specs/002-release-install-update/contracts/installer.md`
- [ ] T074 Verify or document the required initial public tag/release matching `VERSION` before remote GitHub validation in `README.md`
- [ ] T075 Confirm working tree is clean after committing phase 002 changes using `git status`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies; can start immediately.
- **Phase 2 Foundational**: Depends on Phase 1 and blocks all user stories.
- **Phase 3 US1 Install Without Cloning**: Depends on Phase 2; MVP public install path.
- **Phase 4 US2 Verify Installed Version**: Depends on Phase 2 and is easiest after US1 install layout exists; still independently testable from local install.
- **Phase 5 US3 Install a Specific Release**: Depends on US1 remote install mechanics and US2 version reporting.
- **Phase 6 US4 Update Safely**: Depends on US2 version reporting and foundational staging/update helpers.
- **Phase 7 US5 Documentation**: Can start after contracts exist, but final validation depends on implemented stories.
- **Phase 8 Polish**: Depends on all desired stories being complete.

### User Story Dependencies

- **US1 (P1)**: First MVP slice after foundation.
- **US2 (P1)**: Can be implemented alongside US1 after foundation, but full installed-layout validation benefits from US1.
- **US3 (P2)**: Builds on US1 remote install and US2 version validation.
- **US4 (P2)**: Builds on US2 version validation and shared staged lifecycle helpers.
- **US5 (P3)**: Documentation can proceed incrementally and is finalized after behavior settles.

### Within Each User Story

- Write integration/smoke tests first and confirm they fail before implementation.
- Implement helpers before command-specific orchestration.
- Preserve active install failure-safety before adding success-path polish.
- Complete and validate a story before moving to lower-priority stories.

---

## Parallel Opportunities

- Setup tasks T003 and T004 can run in parallel after T001/T002 are understood.
- Foundational helper tasks touching `install.sh` and `lib/agent-ws/update.sh` can be split by file, but tasks touching the same file must be sequenced.
- Test tasks within each user story marked [P] can be written in parallel because they target separate files.
- US1 and US2 implementation can partially overlap after Phase 2, but `VERSION` payload handling should be coordinated.
- US5 documentation sections can be drafted in parallel with US3/US4 implementation and finalized during polish.
- Polish validation tasks T066, T067, and T068 can run in parallel.

## Parallel Example: User Story 1

```bash
Task: "T016 [P] [US1] Add remote-style archive install integration test in tests/integration/test_install_remote.sh"
Task: "T017 [P] [US1] Add failed remote install preservation integration test in tests/integration/test_install_remote_failure_safety.sh"
Task: "T018 [P] [US1] Add local checkout install validation test with staged activation expectations in tests/integration/test_install_local_staged.sh"
```

## Parallel Example: User Story 4

```bash
Task: "T043 [P] [US4] Add staged update success integration test in tests/integration/test_update_staged.sh"
Task: "T044 [P] [US4] Add update failure preservation integration test in tests/integration/test_update_failure_safety.sh"
Task: "T045 [P] [US4] Add pinned update integration test in tests/integration/test_update_pinned.sh"
Task: "T047 [P] [US4] Add latest stable filtering integration test for update resolution in tests/integration/test_update_latest_stable.sh"
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Complete Phase 1 setup.
2. Complete Phase 2 foundational staging/version/release helpers.
3. Complete Phase 3 US1 install without cloning.
4. Complete Phase 4 US2 version visibility.
5. Stop and validate that a new user can install and run `agent-ws version` from a temporary prefix.

### Incremental Delivery

1. Add US3 pinned install for reproducibility.
2. Add US4 safe staged update.
3. Finalize US5 public documentation.
4. Run Phase 8 validation and clean up.

### Validation Gates

- Every lifecycle operation that can replace files must have a failure-safety test.
- `agent-ws version` must work from installed payloads before remote install/update is considered complete.
- README commands must match the implemented command contract before phase completion.
