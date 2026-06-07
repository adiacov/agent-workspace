# Data Model: Agent Workspace CLI

## Workspace Project

Represents a target project managed or detected by Agent Workspace.

**Fields**:

- `path`: project root path being initialized, audited, discovered, or migrated.
- `metadataStatus`: `present`, `missing`, `legacy`, `invalid`, or `stale`.
- `profile`: workspace profile expected for the project, such as `general` or `code`.
- `agents`: selected/supported agent adapters known for the project.
- `activeFiles`: generated files that now belong to the project.
- `legacySignals`: old-structure signals such as `.agent/` or `bin/agent-workspace`.

**Validation rules**:

- Project root must not be accidentally nested inside a parent git repository during current-directory initialization.
- Existing active files must not be overwritten silently.
- Legacy command copies may be reported, not deleted, unless the user explicitly runs a migration apply step.
- Legacy template caches are outside the supported product model and are not interpreted by migration logic.

## Workspace Metadata

Committed project-local metadata stored under `.agent-workspace/`.

**Fields**:

- `schemaVersion`: metadata schema version.
- `toolName`: `agent-ws`.
- `toolVersion`: installed or release version used for initialization when available.
- `templateRevision`: release/tag/commit used as the template source when available.
- `profile`: selected workspace profile.
- `agents`: selected agent adapters.
- `generatedFiles`: mapping of active project files to their template source identity.
- `createdAt`: creation timestamp.
- `updatedAt`: last metadata update timestamp.

**Validation rules**:

- Must contain only non-private project setup facts.
- Must not contain machine-specific absolute paths, personal project meaning, private memory, or secrets.
- Must be placed and documented so it is committed by default.

## Global Template Source

Canonical template set owned by the installed CLI or selected Git/GitHub release/tag.

**Fields**:

- `sourceKind`: installed payload, release, tag, or local development checkout.
- `revision`: version, tag, or commit identifier when available.
- `templateFiles`: known templates for defaults, adapters, and profiles.
- `availability`: available, missing, invalid, or inaccessible.

**Validation rules**:

- Add-agent and initialization must fail clearly if required templates are unavailable.
- Template source must not be copied into each project as a project-local template cache by default.

## Active Generated File

A file copied from a template into a target project and then owned by that project.

**Fields**:

- `path`: project-relative destination path.
- `kind`: default, adapter, profile, memory, or privacy default.
- `sourceTemplate`: canonical template identity.
- `status`: created, present, skipped, missing, drifted, conflict, stale, or invalid.

**Validation rules**:

- Existing active files are skipped unless an explicit safe apply workflow is requested.
- Project-specific edits are preserved.
- Diffs compare active content against the global template source without applying changes.
- Active files remain valid project-owned files even when metadata is stale or invalid.

## Agent Adapter

Mapping from an agent selection to an active instruction file destination.

**Fields**:

- `name`: pi, codex, claude, cursor, or custom.
- `templatePath`: template path in the global template source.
- `destinationPath`: project-relative active file path.
- `requiresCustomPath`: true for custom adapter when default path is not accepted.

**Validation rules**:

- Destination path must be project-root-relative.
- Custom path must not be absolute and must not escape the project root.
- Multiple adapters targeting the same destination must not overwrite each other silently.

## Workspace Profile

Named setup variant that controls optional generated files.

**Fields**:

- `name`: general or code.
- `defaultFiles`: files generated for the profile.
- `profileFiles`: profile-specific files such as engineering guidance for code projects.

**Validation rules**:

- Unsupported profiles fail clearly.
- Deprecated profile names may be reported during migration if relevant, but new docs should use canonical names.

## Discovery Result

Output record for scanning roots for Agent Workspace projects.

**Fields**:

- `path`: candidate project root.
- `classification`: strong, uncertain, or none.
- `signals`: detected metadata and/or legacy signals.
- `notes`: missing or legacy items relevant to audit.

**Validation rules**:

- Metadata under `.agent-workspace/` is a strong signal.
- Legacy `.agent/`, `bin/agent-workspace`, and known active files contribute to confidence scoring.
- Heavy folders and version-control internals are skipped during traversal.

## Migration Plan Record

Preview of migration actions for a legacy project.

**Fields**:

- `projectPath`: target project root.
- `legacyItems`: detected old command or metadata-era files/directories, excluding old template cache interpretation.
- `preservedFiles`: active files and memory that will not be changed.
- `proposedActions`: create metadata, remove old command copy, or no-op.
- `mode`: preview or apply.

**Validation rules**:

- Dry-run preview is the default before destructive actions.
- Active instruction files and memory are preserved by default.
- Destructive actions require explicit apply intent.
- Old project-local template cache contents are not inspected, migrated, or used for product logic.
