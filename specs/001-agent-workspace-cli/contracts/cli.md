# CLI Contract: `agent-ws`

This contract describes user-visible commands, arguments, and expected outcomes. Commands write human-readable status to standard output, errors to standard error, and exit non-zero on failure.

## Global command

```text
agent-ws <command> [options] [path]
```

## Commands

### `agent-ws init [project-name|path]`

Initializes the current directory or creates and initializes a named project directory.

**Options**:

- `--profile <general|code>`: select workspace profile.
- `--agents <list>`: select comma- or space-separated agents.
- `--custom-path <path>`: destination for custom agent instructions.
- `--no-prompt`: fail instead of prompting for missing required choices.

**Expected outcomes**:

- Creates active default files and selected agent files if missing.
- Creates committed metadata under `.agent-workspace/`.
- Does not create `.agent/` or `bin/agent-workspace` by default.
- Skips existing active files and reports each skip.

### `agent-ws add-agent [agent]`

Adds an agent instruction entrypoint to an initialized project using global templates.

**Options**:

- `--agents <list>`: one or more agents.
- `--custom-path <path>`: destination for custom instructions.
- `--no-prompt`: fail instead of prompting.

**Expected outcomes**:

- Copies the selected template to the agent's project-relative destination.
- Preserves existing files.
- Updates metadata when a new file is created.

### `agent-ws status [path]`

Shows a quick health summary for the current project or one specified project.

**Expected outcomes**:

- Reports core active files, known agent files, profile files, metadata, global template availability, and obvious legacy signals.
- Reports invalid or stale metadata without treating active files as invalid.
- Does not modify files.

### `agent-ws audit [path...]`

Performs deeper checks for one or more projects. If no path is provided, audits the current directory.

**Expected outcomes**:

- Reports missing files, invalid/missing/stale metadata, legacy structure, global template availability, likely drift, and recovery guidance for partial states.
- Does not inspect or depend on old project-local template cache contents.
- Does not modify files.

### `agent-ws discover <root...>`

Scans roots for likely Agent Workspace projects.

**Expected outcomes**:

- Lists strong and uncertain matches with detected signals.
- Skips heavy directories and version-control internals.
- Does not maintain a personal registry.

### `agent-ws diff [path]`

Performs read-only comparison of active generated files with the global template source when mappings are known.

**Expected outcomes**:

- Shows differences without applying changes.
- Reports unavailable templates, stale metadata, or unknown mappings clearly.

### `agent-ws sync [path]`

Runs conservative maintenance behavior distinct from read-only diff.

**Options**:

- `--dry-run`: report intended checks/refreshes only.
- `--apply`: apply only explicitly safe non-active-file updates.

**Expected outcomes**:

- Refreshes or validates global template/release references, metadata, or comparison baselines.
- Does not overwrite active instruction files or memory without explicit apply intent for a safe non-conflicting change.
- Stops on conflicts.

### `agent-ws update [--version <version>]`

Updates the globally installed `agent-ws` command from Git/GitHub releases or tags.

**Expected outcomes**:

- Uses the newest Git/GitHub tag or release that is not marked pre-release and does not use alpha, beta, or release-candidate suffixes when no version is specified.
- Stages and validates the new version before replacing the current working command.
- Leaves the current installation usable if the requested release is unavailable or update validation fails.
- Reports installed version or failure reason.

### `agent-ws migrate [path]`

Helps migrate a legacy project from local command copies to the global model. Migration documentation is required for MVP; this helper is optional if implemented.

**Options**:

- `--dry-run`: preview migration actions; default behavior.
- `--apply`: perform explicitly safe migration actions.

**Expected outcomes**:

- Preserves active instruction files and memory.
- Previews deletion/move actions before applying.
- Can create `.agent-workspace/` metadata for legacy projects.
- Does not inspect, migrate, or rely on old project-local template cache contents.

### `agent-ws help [command]`

Shows usage guidance.

**Expected outcomes**:

- Every public command has concise help.
- Primary quickstart path is clear and not buried under advanced options.
