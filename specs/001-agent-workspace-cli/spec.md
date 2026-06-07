# Feature Specification: Agent Workspace CLI

**Feature Branch**: `001-agent-workspace-cli`

**Created**: 2026-06-07

**Status**: Draft

**Input**: User description: "from the existing features and from BRIEF.md and SPEC.md, create a CLI application for agent-workspace"

## Clarifications

### Session 2026-06-07

- Q: Should Agent Workspace remain primarily a project-local CLI or become a globally installed command? → A: Globally installed CLI primary.
- Q: Where should initialization run? → A: Current directory or named new directory.
- Q: Should new projects generate or support project-local `bin/agent-workspace` copies? → A: No project-local CLI copies.
- Q: How should the globally installed CLI be distributed and updated? → A: Git/GitHub releases or tags.
- Q: Should workspace metadata be committed to projects? → A: Commit metadata by default.
- Q: Should projects keep a local template cache? → A: Templates live globally, not per project.
- Q: What names should the global command and project metadata directory use? → A: Use `agent-ws` and `.agent-workspace/`.
- Q: Should the new CLI include migration guidance from the current project-local model? → A: Yes, include migration documentation and a safe migration helper.
- Q: Should README documentation be rewritten around a simpler user flow? → A: Yes, README must prioritize a clear first-time flow.
- Q: What counts as the latest stable release for updates? → A: Newest Git/GitHub tag or release not marked pre-release and without alpha, beta, or rc suffixes.
- Q: What happens if update fails? → A: Preserve the currently working `agent-ws` until the new version is fully installed and validated.
- Q: Is migration automation required for MVP? → A: Yes; provide a safe migration helper that defaults to dry-run and requires explicit apply for destructive changes.
- Q: Should migration logic handle old project-local template caches? → A: No; old project-local template caches are outside the product model and may be deleted manually.
- Q: How should invalid or stale metadata be handled? → A: Report it in status/audit as invalid or stale; active files remain valid project-owned files.
- Q: How are `status` and `audit` different? → A: `status` is a quick current-project summary; `audit` performs deeper checks for one or many paths.
- Q: How are `diff` and `sync` different? → A: `diff` is read-only comparison; `sync` is conservative maintenance and never changes active files without explicit apply.
- Q: What recovery behavior is required for partial failures? → A: Use staged writes where possible, preserve active files/memory, and report recovery steps during audit.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Initialize a Project Workspace (Priority: P1)

A developer starts in a project directory and uses the globally installed `agent-ws` command to create the standard collaboration structure for AI-assisted work, including project memory files, selected agent instruction files copied from global templates, privacy-aware defaults, and workspace metadata in `.agent-workspace/`.

**Why this priority**: Initialization is the core value already provided by Agent Workspace and is required before later lifecycle commands are useful.

**Independent Test**: Can be fully tested in a clean project directory by initializing with a selected profile and agent, then confirming the expected active files and metadata exist, no local template cache is created by default, and no existing files were overwritten.

**Acceptance Scenarios**:

1. **Given** a clean project directory with no Agent Workspace files, **When** the developer initializes with the default profile and one supported agent, **Then** the project receives default memory files, privacy defaults, the selected agent instruction file copied from global templates, and workspace metadata.
2. **Given** an existing project file that has the same destination as a generated file, **When** initialization runs, **Then** the existing file is preserved and the result clearly reports that it was skipped.
3. **Given** a developer chooses the code profile, **When** initialization runs, **Then** the project receives engineering guidance in addition to the default workspace files.
4. **Given** a developer wants to start a new project by name, **When** initialization is run with a new project directory name, **Then** the directory is created and initialized with the same Agent Workspace structure.
5. **Given** a developer initializes a project, **When** the command completes, **Then** the project metadata is stored under `.agent-workspace/` and no generic `.agent/` directory is created by default.

---

### User Story 2 - Add Agent Support Later (Priority: P1)

A developer who already initialized a project adds another supported AI agent entrypoint later without reinitializing the whole project or overwriting project-specific instructions.

**Why this priority**: Agent Workspace is meant to make context portable across multiple agents, and later adapter generation depends on canonical templates provided by the global installation.

**Independent Test**: Can be tested by initializing a project with no agent or one agent, then adding a second agent and verifying only the new agent file is created.

**Acceptance Scenarios**:

1. **Given** an initialized project and a global Agent Workspace installation with templates, **When** the developer adds a supported agent, **Then** the matching agent instruction file is copied into the project at the location expected by that agent.
2. **Given** the destination instruction file already exists, **When** the developer adds that agent, **Then** the existing file is preserved and reported as skipped.
3. **Given** the developer chooses a custom agent, **When** a project-root-relative output path is provided, **Then** a generic instruction file is created at that path if it does not already exist.

---

### User Story 3 - Check One Project for Workspace Health (Priority: P2)

A developer checks whether the current project follows the expected Agent Workspace structure and can identify missing, legacy, or incomplete pieces.

**Why this priority**: As projects accumulate local edits, the developer needs a safe way to understand current state before making changes.

**Independent Test**: Can be tested against initialized, partially initialized, and legacy-shaped projects and comparing the reported findings to the files present.

**Acceptance Scenarios**:

1. **Given** a fully initialized project, **When** the developer checks status or audits the project, **Then** the result reports core files, known agent files, metadata, profile-related files, and the global template source status as present or expected.
2. **Given** a legacy project with Agent Workspace signals but no explicit metadata, **When** the developer audits it, **Then** the project is identified as likely Agent Workspace-managed and the missing metadata is reported.
3. **Given** a project created by the global CLI, **When** the developer audits it, **Then** the absence of a project-local template cache is treated as expected behavior.

---

### User Story 4 - Discover Agent Workspace Projects (Priority: P2)

A developer scans one or more directories to find projects that appear to use Agent Workspace, including newer projects with metadata and older projects with legacy signals.

**Why this priority**: The brief identifies multi-repository usage as the key reason for evolving from a project-by-project bootstrap script into a broader CLI.

**Independent Test**: Can be tested by creating a directory tree with projects containing strong, weak, and no Agent Workspace signals and verifying classification output.

**Acceptance Scenarios**:

1. **Given** a directory tree containing multiple projects, **When** the developer runs discovery on one or more roots, **Then** each likely Agent Workspace project is listed with the signals that caused detection.
2. **Given** a project with explicit Agent Workspace metadata, **When** discovery scans its parent directory, **Then** it is classified as an Agent Workspace project.
3. **Given** a directory with only weak generic files, **When** discovery scans it, **Then** the result distinguishes uncertain matches from strong matches.

---

### User Story 5 - Safely Refresh Templates and CLI Versions (Priority: P3)

A developer updates reusable Agent Workspace assets in existing projects while preserving project-owned active files and memory by default.

**Why this priority**: Safe propagation of template and command improvements is important, but the MVP should avoid automatic active-file merging until reliable ownership and drift detection exist.

**Independent Test**: Can be tested by refreshing a project that has local active-file modifications and verifying that local active files and memory are unchanged unless the developer explicitly chooses a safe apply operation.

**Acceptance Scenarios**:

1. **Given** an initialized project with project-specific edits in active instruction files, **When** the developer runs a default sync, **Then** global templates or release metadata can be refreshed but active instruction files and memory are not overwritten.
2. **Given** a globally installed `agent-ws` command, **When** the developer requests an update to a released version, **Then** the global command can be updated from that release and the result identifies what changed.
3. **Given** an audit finds drift between active files and templates, **When** the developer asks for differences, **Then** the CLI shows what differs without applying changes by default.

### User Story 6 - Migrate From Current Local Model (Priority: P3)

A developer with projects created by the older project-local model can understand what changed, remove obsolete local command copies, preserve active files, and adopt the new global command and metadata location.

**Why this priority**: The project already has existing local usage, and the global CLI model changes folder and command ownership in ways that must be explained before adoption.

**Independent Test**: Can be tested with a project containing the older local command and `.agent/` structure by following documented migration steps and verifying active files remain intact.

**Acceptance Scenarios**:

1. **Given** a project initialized with the older local command model, **When** the developer reads migration documentation, **Then** they can identify which files to keep, remove, or regenerate.
2. **Given** a migration helper is provided, **When** the developer runs it in a legacy project, **Then** it defaults to dry-run and reports intended changes before deleting or moving anything.
3. **Given** legacy active instruction files have local edits, **When** migration occurs, **Then** those active files are preserved.
4. **Given** a legacy project contains old project-local template caches, **When** migration guidance is followed, **Then** those caches are treated as outside the supported product model and may be deleted manually by the user.

---

### User Story 7 - Understand and Use the CLI From README (Priority: P3)

A new user can read the README and quickly understand what Agent Workspace is, how to install `agent-ws`, how to initialize a project, and how to add another agent without being overwhelmed by competing setup paths.

**Why this priority**: Clear documentation is part of the product experience and reduces confusion from the current README's many equivalent options.

**Independent Test**: Can be tested by asking a new reader to install the CLI and initialize a project using only the README.

**Acceptance Scenarios**:

1. **Given** a new user reads the README, **When** they follow the primary quickstart, **Then** they can install `agent-ws` and initialize a project without choosing between multiple redundant flows.
2. **Given** advanced options exist, **When** the README presents them, **Then** they appear after the primary quickstart and are clearly labeled as optional.

### Edge Cases

- A command is run inside a parent repository but not at that repository root; initialization of the current directory stops rather than nesting unintended project state.
- Initialization is requested for a named directory that already exists and contains files; the command preserves existing files and reports skipped destinations.
- Required global templates are missing or inaccessible when adding an agent; the command stops with a clear recovery-oriented message instead of creating partial output.
- A custom agent path is absolute or attempts to escape the project root; the command rejects the path.
- Multiple selected agents map to the same active file destination; the command must avoid silent overwrites and clearly report the result.
- Discovery encounters large dependency, virtual environment, hidden VCS, or generated folders; scanning avoids these common heavy directories.
- Existing projects do not have metadata because they were created before metadata existed; audit and discovery use legacy signals and clearly label confidence.
- Metadata is invalid or references an unavailable template revision; status and audit report it as invalid or stale while treating active files as valid project-owned files.
- A requested release or version for command update is unavailable; the project remains unchanged and the failure is reported clearly.
- An update fails after download or staging; the currently working `agent-ws` remains usable.
- Initialization, update, or migration encounters partial state; audit reports recovery steps and active files and memory are preserved.
- The developer runs commands repeatedly; repeated runs are safe and preserve existing active files unless an explicit safe update operation is chosen.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The CLI MUST be available as a globally installed command named `agent-ws` that can operate from inside any project directory.
- **FR-002**: The CLI MUST provide project initialization that creates the Agent Workspace structure from templates in the current project or in a newly created named project directory.
- **FR-002a**: Initialization MUST NOT create a project-local template cache by default; later commands MUST use canonical templates from the global installation or selected release source.
- **FR-003**: Initialization MUST support a default general profile and a code profile that adds engineering guidance.
- **FR-004**: Initialization MUST support non-interactive selection of supported agents and profile so automated or agent-driven setup can run without prompts.
- **FR-005**: The CLI MUST support adding supported agent instruction entrypoints after initialization using canonical templates from the global installation or selected release source.
- **FR-006**: The CLI MUST support a custom agent instruction entrypoint using a developer-provided project-root-relative destination.
- **FR-007**: The CLI MUST place generated active agent files at locations expected by each supported agent.
- **FR-008**: The CLI MUST never silently overwrite existing active files or memory files.
- **FR-009**: The CLI MUST clearly report created, skipped, missing, and failed actions for user-facing commands.
- **FR-010**: The CLI MUST provide a quick current-project status view for known core files, known agent files, profile-specific files, workspace metadata, and global template source availability.
- **FR-011**: The CLI MUST create explicit workspace metadata under `.agent-workspace/` for newly initialized projects, including selected profile, selected agents, generated file mapping, and template or release revision when available.
- **FR-011a**: Workspace metadata MUST contain only non-private project setup facts and MUST be placed or ignored so it is committed by default.
- **FR-011b**: New initialization MUST NOT create the generic `.agent/` directory by default.
- **FR-012**: The CLI MUST audit current or specified projects with deeper checks than status, including expected structure, missing files, legacy layout, metadata validity, stale metadata, global template source availability, and likely drift between active files and available templates.
- **FR-013**: The CLI MUST discover likely Agent Workspace projects under developer-provided root paths using explicit metadata and legacy signal scoring.
- **FR-014**: Discovery MUST distinguish strong matches, uncertain matches, and non-matches and report the signals used for classification.
- **FR-015**: Discovery MUST skip common heavy or irrelevant directories such as dependency folders, virtual environments, generated output folders, and version-control internals.
- **FR-016**: The CLI MUST support read-only comparison of active generated files against available templates and report differences without changing files.
- **FR-017**: The CLI MUST support a conservative sync mode that refreshes global template/release references, metadata, or comparison baselines without modifying active instruction files or memory unless explicit apply intent is provided for a safe non-conflicting change.
- **FR-018**: The CLI MUST require explicit developer intent before applying any change to active instruction files after initialization.
- **FR-019**: The CLI MUST stop and report conflicts when a requested active-file update cannot be determined safe.
- **FR-020**: The CLI MUST support updating the globally installed `agent-ws` command from Git/GitHub releases or tags to a specified released version and to the latest stable release when no version is specified.
- **FR-020a**: Latest stable MUST mean the newest Git/GitHub tag or release that is not marked pre-release and does not use alpha, beta, or release-candidate suffixes.
- **FR-020b**: Update MUST preserve the currently working installed `agent-ws` until the new version is fully installed and validated; failed updates MUST leave the current command usable.
- **FR-023**: New project initialization MUST NOT generate or maintain a project-local `bin/agent-workspace` command copy.
- **FR-021**: The CLI MUST preserve the boundary that Agent Workspace owns reusable mechanisms and templates while the target project owns final active instruction files and memory.
- **FR-022**: The CLI MUST provide help or usage guidance for every user-facing command, including initialization, adding agents, status, audit, discovery, template comparison, sync, and command update.
- **FR-024**: The project documentation MUST include a migration section explaining how to move from the older `.agent/` and `bin/agent-workspace` approach to the new `agent-ws` and `.agent-workspace/` model.
- **FR-025**: Migration documentation and a migration helper are required for MVP; the helper MUST default to dry-run, preview intended changes, require explicit apply for destructive actions, and preserve active instruction files and memory by default.
- **FR-025a**: Migration logic and documentation MUST NOT rely on or manage old project-local template caches; those caches are outside the supported target model and may be deleted manually by the user.
- **FR-026**: The README MUST prioritize one clear primary install-and-initialize flow before presenting optional advanced usage.

### Key Entities

- **Workspace Project**: A target project that may contain Agent Workspace metadata, generated active files, and project-owned memory.
- **Global Template Source**: The canonical reusable templates installed or retrieved with the global Agent Workspace command and used for later agent additions, audits, comparisons, and conservative sync.
- **Active Generated File**: A file consumed directly by a user or AI agent, such as agent instructions, workflow guidance, engineering guidance, privacy defaults, or project memory.
- **Agent Adapter**: A supported mapping from an agent choice to a template and destination path.
- **Workspace Profile**: A named setup variant that determines which default and profile-specific files are expected.
- **Workspace Metadata**: A project-local record stored under `.agent-workspace/` containing Agent Workspace ownership information, selected options, generated file mappings, and known revision information.
- **Discovery Result**: A classification of a scanned directory as a strong match, uncertain match, or non-match with the evidence that produced the classification.
- **Release Version**: A published Git/GitHub release or tag that can be used to update the globally installed command and related reusable assets.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A developer can install or confirm `agent-ws`, then initialize a clean project with one profile and one agent in under 2 minutes, including verification that expected files were created.
- **SC-002**: Re-running initialization or agent addition on an already initialized project preserves 100% of existing active files and reports each skipped destination.
- **SC-003**: A developer can add a second supported agent to an initialized project in under 1 minute using global templates without manually copying template files.
- **SC-004**: Project audit correctly identifies missing core files, missing metadata, and missing global template source availability in at least 95% of representative initialized, partial, and legacy project fixtures.
- **SC-005**: Discovery classifies projects with explicit metadata or strong legacy signals with at least 95% accuracy across representative directory trees.
- **SC-006**: Conservative sync or global template refresh completes without changing active instruction files or memory in 100% of tested projects that contain local modifications.
- **SC-007**: Developers can view template-vs-active-file differences before applying changes in 100% of projects where comparable templates are available.
- **SC-008**: The globally installed `agent-ws` command can be updated to a selected stable released version in under 2 minutes when that release is available, and failed updates leave the previous working command usable.
- **SC-009**: At least 90% of command failures in validation scenarios include a clear explanation and a next action the developer can take.
- **SC-010**: A developer can migrate a representative legacy local project using the documented migration guidance and safe migration helper without losing active instruction files or memory.
- **SC-011**: A new user can complete the README primary quickstart without needing to choose between multiple redundant initialization methods.

## Assumptions

- The first expanded CLI version prioritizes global command usage, global template ownership, metadata, discovery, audit, conservative sync, difference reporting, and release-aware global command updates before attempting automatic active-file merges.
- Existing project-local `bin/agent-workspace` copies may be manually deleted from local projects after migration guidance confirms no active project-owned files will be lost; old project-local template caches are outside the target model and may be deleted manually without product migration logic.
- Scan roots for discovery are provided explicitly by the developer; the CLI does not maintain a personal project registry or infer private project meaning.
- New projects commit workspace metadata under `.agent-workspace/` by default as part of normal project files; metadata must not contain machine-specific paths, private memory, or personal project meaning.
- Existing legacy projects may lack metadata, so discovery and audit need a confidence-based fallback using known Agent Workspace signals.
- Active instruction files and memory may contain project-specific edits after initialization and therefore are project-owned.
- Template refresh applies to the global installation or release-derived comparison source by default; active-file changes require explicit review or apply intent.
- The existing supported agents are pi, codex, claude, cursor, and custom.
- Release-aware updates use published Agent Workspace Git/GitHub releases or tags that are externally available to the developer's environment.
