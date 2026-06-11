# Feature Specification: Release, Install, and Update Hardening

**Feature Branch**: `002-release-install-update`

**Created**: 2026-06-11

**Status**: Draft

**Input**: User description: "Make `agent-ws` installable, versioned, and safely updateable from GitHub for Linux-based shell environments, without requiring users to manually clone the repository."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Install Without Cloning (Priority: P1)

A developer discovers Agent Workspace on the public project page and installs the `agent-ws` command directly from a documented one-line shell command, without first cloning the repository or understanding the project internals.

**Why this priority**: Installation is the first experience for any new user. If users cannot install the tool easily and deterministically, later version and update capabilities have no value.

**Independent Test**: Can be fully tested in a clean shell environment by following the documented install command, confirming the command becomes available at the expected user-level location, and running a basic help or version command.

**Acceptance Scenarios**:

1. **Given** a supported Linux-based shell environment with the required standard tools, **When** the developer runs the documented one-line install command, **Then** `agent-ws` is installed without requiring a manual repository clone.
2. **Given** installation completes successfully, **When** the developer opens a shell with the documented command location on `PATH`, **Then** `agent-ws` can be executed as a normal user command.
3. **Given** the install cannot download, stage, or validate the command, **When** installation fails, **Then** any previously working installation remains usable and the user receives clear recovery guidance.

---

### User Story 2 - Verify Installed Version (Priority: P1)

A developer verifies exactly which `agent-ws` version is installed before initializing a project, reporting a bug, or deciding whether to update.

**Why this priority**: Visible version information makes installations reproducible, supportable, and safe to update.

**Independent Test**: Can be fully tested by installing the tool and running the documented version command, then confirming the output includes a clear installed version that matches the release source used for installation.

**Acceptance Scenarios**:

1. **Given** `agent-ws` is installed, **When** the developer requests version information, **Then** the command prints a clear installed version.
2. **Given** the command was installed from a pinned release, **When** the developer requests version information, **Then** the reported version matches the pinned release selected by the user.

---

### User Story 3 - Install a Specific Release (Priority: P2)

A developer installs a specific known release of `agent-ws` so they can reproduce behavior, avoid an unplanned upgrade, or follow documentation written for that release.

**Why this priority**: Pinned installs are necessary for reproducibility and for users who need predictable tool behavior.

**Independent Test**: Can be fully tested by selecting a documented version value during installation, then confirming the installed command reports that exact version and works normally.

**Acceptance Scenarios**:

1. **Given** a documented release identifier exists, **When** the developer runs the documented pinned install command with that identifier, **Then** the installed command reports the selected version.
2. **Given** the requested release identifier does not exist or cannot be validated, **When** the developer runs pinned install, **Then** installation fails clearly and does not replace any working installation.

---

### User Story 4 - Update Safely (Priority: P2)

A developer with an existing `agent-ws` installation explicitly updates to a newer stable release and keeps the current working command if anything goes wrong.

**Why this priority**: Updates are a high-risk lifecycle operation; users need a safe, explicit path that does not corrupt the active command.

**Independent Test**: Can be fully tested by installing an older release, running the update command, confirming the version changes after success, and simulating failures to confirm the old command remains usable.

**Acceptance Scenarios**:

1. **Given** an older installed version and a newer stable release exists, **When** the developer runs the update command, **Then** the tool stages the new release, validates it, activates it only after validation, and reports the version change.
2. **Given** download, staging, or validation fails during update, **When** the update command exits, **Then** the previously active command still works and the user sees a clear failure message.
3. **Given** the developer requests a specific update version, **When** that version is valid, **Then** the active command is updated to that selected version after validation.

---

### User Story 5 - Follow Public Documentation (Priority: P3)

A developer reads the README and understands how to install, pin, verify, update, uninstall, and identify supported environments without needing private project knowledge.

**Why this priority**: Documentation completes the public onboarding path and reduces support burden.

**Independent Test**: Can be fully tested by reviewing the README and executing the documented happy-path commands in a clean environment.

**Acceptance Scenarios**:

1. **Given** a new user reads the README, **When** they look for installation instructions, **Then** they find a one-line install command, a pinned install example, version verification, update instructions, uninstall guidance, supported platforms, and release/versioning expectations.
2. **Given** a user is on an unsupported environment, **When** they read the supported environment section, **Then** they can determine that native Windows outside WSL is not currently a supported target.

### Edge Cases

- Install is run where a previous `agent-ws` installation already exists.
- The selected command directory is not on `PATH`.
- Network access is unavailable, interrupted, or returns a missing release.
- The latest available public release is not considered stable.
- A user requests an invalid or non-existent pinned version.
- Update is interrupted after staging but before activation.
- Validation of a newly staged command fails.
- Local development installation is run from a checked-out repository and should still work.
- The user lacks permission to write to the default install location.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The product MUST provide one clear source of version truth for the installed command.
- **FR-002**: Users MUST be able to print the installed command version with a documented `agent-ws` command.
- **FR-003**: Users MUST be able to install `agent-ws` from a documented one-line shell command without manually cloning the repository.
- **FR-004**: The default public installation path MUST resolve to the latest stable public release rather than an arbitrary development state.
- **FR-005**: Users MUST be able to select a specific release identifier during installation.
- **FR-006**: Local development installation from an existing repository checkout MUST remain supported.
- **FR-007**: Successful installation MUST place the active command and its required supporting files in documented user-accessible locations.
- **FR-008**: Failed installation attempts MUST NOT leave an existing working installation broken or partially replaced.
- **FR-009**: Users MUST be able to explicitly update an installed command to the latest stable release.
- **FR-010**: Users MUST be able to explicitly update an installed command to a selected valid release.
- **FR-011**: Update MUST stage the selected release before replacing the active installation.
- **FR-012**: Update MUST validate the staged command before activation, at minimum by confirming it can report version information.
- **FR-013**: Failed update attempts MUST preserve the previously active working installation.
- **FR-014**: Successful update MUST clearly report the previous version, the new version, and the active command location when that information is available.
- **FR-015**: Install and update failures MUST provide clear, actionable messages that identify whether the failure happened during release resolution, download, staging, validation, or activation.
- **FR-016**: Public documentation MUST include default install, pinned install, version verification, update, uninstall or manual cleanup guidance, supported platforms, and release/versioning expectations.
- **FR-017**: The supported environment MUST include Linux-based shell environments and may work on compatible macOS shells, while native Windows outside WSL is explicitly out of scope.
- **FR-018**: The release process expectations MUST make installed versions visible and reproducible for users.

### Key Entities *(include if feature involves data)*

- **Release Version**: A stable public release identifier selected by default or by the user; key attributes include version string, stability status, and availability.
- **Installed Command**: The active `agent-ws` command available to the user; key attributes include installed version, command path, supporting files, and validation status.
- **Staged Installation**: A temporary candidate installation prepared before activation; key attributes include selected version, staging location, validation result, and activation readiness.
- **Install Location**: The documented user-level destination for the command and supporting files; key attributes include command directory, support-file directory, write permission, and PATH visibility.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new user can complete documented installation and version verification in under 5 minutes on a supported clean environment.
- **SC-002**: 100% of documented pinned install smoke tests install the requested available release and report the matching version.
- **SC-003**: 100% of simulated failed install and update smoke tests leave the previously active command usable.
- **SC-004**: A successful update reports the before-and-after version information in every tested update path.
- **SC-005**: README review confirms all required public lifecycle actions are documented: install, pinned install, version, update, uninstall or cleanup, supported platforms, and release/versioning expectations.
- **SC-006**: A first-time user following the README can initialize a project after installation without needing to clone the repository manually.

## Assumptions

- The public project release location is GitHub, and stable tags or releases are the distribution source for this phase.
- Stable versions use a consistent visible release identifier; the planning phase will choose the exact string format and document it.
- The default installation target is a user-writable location suitable for Linux-based shell environments.
- Users have standard shell tooling and network access when performing remote installation or update.
- Package-manager distribution, native Windows installation outside WSL, hosted services, GUI workflows, and unrelated command features are out of scope for this phase.
- Validation of a staged installation means the command can execute and report version information before activation.
