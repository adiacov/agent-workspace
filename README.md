# agent-workspace

Agent Workspace standardizes project setup for AI-assisted development. It provides a global `agent-ws` command, reusable templates, project memory files, and agent-specific instruction entrypoints.

The tool itself is installed once for a user or machine. Individual projects receive only their active project files and committed, privacy-safe metadata.

## Primary quickstart

From this repository checkout, install the development command into a temporary or user-level bin directory:

```bash
TMPBIN="$(mktemp -d)"
./install.sh --prefix "$TMPBIN"
export PATH="$TMPBIN:$PATH"
agent-ws help
```

Initialize the current project with the code profile and Pi instructions:

```bash
agent-ws init --profile code --agents pi --no-prompt
```

Add another agent later without reinitializing the project:

```bash
agent-ws add-agent --agents claude --no-prompt
```

After initialization, project metadata is stored at:

```text
.agent-workspace/workspace.json
```

## Commands

```bash
agent-ws init [project-name|path] --profile general --agents pi --no-prompt
```

Initializes the current directory or creates and initializes a named project directory.

```bash
agent-ws add-agent --agents claude --no-prompt
```

Adds one or more agent instruction entrypoints using global templates and preserves existing files.

```bash
agent-ws status [path]
```

Shows a quick health summary for one project.

```bash
agent-ws audit [path...]
```

Performs deeper checks for missing files, metadata validity, stale metadata, legacy structure, template availability, and recovery guidance.

```bash
agent-ws discover <root...>
```

Scans explicit roots for likely Agent Workspace projects and reports strong or uncertain matches with signals.

```bash
agent-ws diff [path]
```

Shows read-only differences between active generated files and available global templates.

```bash
agent-ws sync [path] --dry-run
agent-ws sync [path] --apply
```

Runs conservative maintenance. It does not overwrite active instruction files or memory.

```bash
agent-ws update [--version VERSION]
```

Updates the global command from a stable Git/GitHub release or tag when release support is available. Without `--version`, the latest stable release is the newest tag or release that is not pre-release and does not include alpha, beta, or release-candidate suffixes.

```bash
agent-ws migrate --dry-run /path/to/legacy-project
agent-ws migrate --apply /path/to/legacy-project
```

Previews or applies safe migration from the older project-local model.

Use command-specific help for concise usage:

```bash
agent-ws help init
agent-ws help add-agent
agent-ws help migrate
```

## What gets created in a project

Depending on profile and selected agents, `agent-ws init` creates active project-owned files such as:

- `WORKFLOWS.md`
- `STATE.md`
- `BRAINSTORM.md`
- `.gitignore`
- `ENGINEERING.md` for the `code` profile
- `AGENTS.md` for Pi/Codex-style agents
- `CLAUDE.md` for Claude Code
- `.cursor/rules/agent-workspace.mdc` for Cursor
- a custom instruction file at a project-relative path you choose
- `.agent-workspace/workspace.json`

Existing active files are skipped, never silently overwritten.

New initialization does not create `.agent/`, `.agent/templates/`, or `bin/agent-workspace`.

## Metadata and ownership

Agent Workspace stores committed metadata under `.agent-workspace/`:

```text
.agent-workspace/workspace.json
```

Metadata contains non-private setup facts only, such as:

- metadata schema version
- tool name/version when available
- selected profile
- selected agents
- generated file mappings
- template or release revision when available
- created/updated timestamps

Metadata must not contain secrets, private memory contents, personal project registry meaning, or machine-specific absolute paths.

Ownership boundary:

- Agent Workspace owns reusable mechanisms and global templates.
- The target project owns final active instruction files and memory.
- Active files may contain local project-specific edits and are preserved by default.

## Install and update model

The intended product model is a global/user-level `agent-ws` command that can be run from anywhere. Projects do not receive a project-local command copy.

For development from this checkout:

```bash
./install.sh --prefix "$HOME/.local/bin"
```

Ensure the chosen directory is on `PATH` before running `agent-ws`.

Release-aware updates use Git/GitHub stable releases or tags:

```bash
agent-ws update
agent-ws update --version v1.2.3
```

Failed updates preserve the currently working `agent-ws` command.

## Migration from the older project-local model

Older projects may contain:

- `.agent/`
- `.agent/templates/`
- `bin/agent-workspace`
- active instruction files such as `AGENTS.md`, `CLAUDE.md`, or Cursor rules
- memory files such as `STATE.md` and `BRAINSTORM.md`

The migration rule is conservative:

- active instruction files are project-owned and must be preserved;
- memory files are project-owned and must be preserved;
- `.agent-workspace/workspace.json` may be created as committed non-private metadata;
- `bin/agent-workspace` is a legacy local command copy and may be removed only with explicit apply intent;
- old project-local template caches under `.agent/templates/` are outside the supported global model and are not inspected, migrated, or used for decisions. You may delete them manually after reviewing your project.

Preview migration first:

```bash
agent-ws migrate --dry-run /path/to/legacy-project
```

Apply only after reviewing the preview:

```bash
agent-ws migrate --apply /path/to/legacy-project
```

The migration helper preserves active instruction files and memory by default.

## Advanced options

Supported profiles:

- `general`: default memory and workflow files
- `code`: includes engineering guidance in `ENGINEERING.md`

Supported agents:

- `pi`
- `codex`
- `claude`
- `cursor`
- `custom`

Multiple agents can be selected with commas or spaces:

```bash
agent-ws init --profile code --agents "pi claude" --no-prompt
agent-ws add-agent --agents pi,claude --no-prompt
```

For a custom agent, provide a project-root-relative output path:

```bash
agent-ws add-agent --agents custom --custom-path docs/CUSTOM_AGENT.md --no-prompt
```

Absolute paths and paths that escape the project root are rejected.

## Templates

Repository templates live in:

```text
templates/default/
templates/adapters/
templates/profiles/
```

The installed `agent-ws` command uses global templates from the installed payload or selected release source. Projects customize behavior by editing their active instruction files after initialization.
