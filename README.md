# agent-workspace

Agent Workspace standardizes project setup for AI-assisted development. It provides a global `agent-ws` command, reusable templates, context files, and agent-specific instruction entrypoints.

See [CHANGELOG.md](CHANGELOG.md) for release history.

## Contents

- [Primary quickstart](#primary-quickstart)
- [Commands](#commands)
- [What gets created in a project](#what-gets-created-in-a-project)
- [Context model](#context-model)
- [Synchronization for existing global projects](#synchronization-for-existing-global-projects)
- [Install and update model](#install-and-update-model)
- [Migration from the older project-local model](#migration-from-the-older-project-local-model)
- [Advanced options](#advanced-options)
- [Templates](#templates)

## Primary quickstart

From this repository checkout, install the command for your user:

```bash
./install.sh
export PATH="$HOME/.local/bin:$PATH"
agent-ws help
```

Initialize the current project:

```bash
agent-ws init
```

`init` asks for project profile and agent choices.

Add another agent later without reinitializing the project:

```bash
agent-ws add-agent --agents claude --no-prompt
```

After initialization, project metadata is stored at:

```text
.agent-workspace/workspace.json
```

## Commands

Choose commands by what they operate on:

| Need | Command | Operates on |
| --- | --- | --- |
| Create Agent Workspace files in a project | `init` | one project |
| Add another agent entrypoint to a project | `add-agent` | one project |
| Inspect project health or template differences | `status`, `audit`, `diff` | one or more projects |
| Maintain an already-modern Agent Workspace project | `sync` | one project metadata/baselines |
| Convert an old `.agent/` project to the global model | `migrate` | one legacy project |
| Update the installed `agent-ws` command and global templates | `update` | user-level installation |

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

Maintains one project that already uses the global Agent Workspace model. It validates project metadata/template references and comparison baselines. It does not update the installed `agent-ws` command, does not migrate legacy `.agent/` projects, and does not overwrite active instruction files or memory.

```bash
agent-ws update [--version VERSION]
```

Updates the user-level installed `agent-ws` command and global templates from a stable Git/GitHub release or tag. It does not modify project files. Without `--version`, the latest stable release is the newest tag or release that is not pre-release and does not include alpha, beta, or release-candidate suffixes.

```bash
agent-ws migrate --dry-run /path/to/legacy-project
agent-ws migrate --apply /path/to/legacy-project
```

Previews or applies migration of one legacy project from the older project-local model with `.agent/` and `bin/agent-workspace` to the global `agent-ws` model. It is not for already-modern projects.

Use command-specific help for concise usage:

```bash
agent-ws help init
agent-ws help add-agent
agent-ws help migrate
```

## What gets created in a project

Depending on profile and selected agents, `agent-ws init` creates active project-owned files such as:

- `WORKFLOWS.md`
- `PROJECT.md`
- `STATE.md`
- `.gitignore`
- `ENGINEERING.md` for the `code` profile
- `AGENTS.md` for Pi/Codex-style agents
- `CLAUDE.md` for Claude Code
- `.cursor/rules/agent-workspace.mdc` for Cursor
- a custom instruction file at a project-relative path you choose
- `.agent-workspace/workspace.json`

Existing active files are skipped, never silently overwritten.

New initialization does not create `.agent/`, `.agent/templates/`, or `bin/agent-workspace`.

## Context model

Agent Workspace uses one canonical current-context entrypoint per repository:

- `STATE.md`: current status, active work, next action, blockers, and explicit pointers to relevant deeper docs. Agents should read this first and follow only relevant pointers.
- `PROJECT.md`: stable project identity, purpose, users, boundaries, non-goals, and principles. Read it when that stable scope is needed, not by default for every task.
- Task artifacts from planning tools: task-specific context. Read these only when `STATE.md` points to them or the user request is clearly about that task.
- `DECISIONS.md` or `MEMORY.md`: optional durable history or memory. These are not required for every task.
- `sessions/pending/`: raw recovery checkpoints. Agents should check for these at startup, extract only durable state, then archive processed files.

Agents should classify the request before loading broad project context and use the smallest useful context set. They should not blindly read unrelated historical task artifacts, decisions, or old context files by default.

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

## Synchronization for existing global projects

Use `sync` only for projects already initialized with the global Agent Workspace model and `.agent-workspace/workspace.json`. It maintains project metadata/baselines for that project. It does not update the installed `agent-ws` command and is not for older `.agent/` project-local migrations.

Preview synchronization first:

```bash
agent-ws sync /path/to/project --dry-run
```

Apply only after reviewing the preview:

```bash
agent-ws sync /path/to/project --apply
```

`sync --apply` is conservative and must not overwrite active instruction files or memory, but it is still an applying maintenance command. Prefer `--dry-run` first whenever you are unsure what the project state is or what will be validated.

## Install and update model

The intended product model is a global/user-level `agent-ws` command that can be run from anywhere. Projects do not receive a project-local command copy.

### Public install

Public GitHub install support installs the latest stable GitHub release/tag by default, stages the payload, validates it, and activates it only after validation succeeds:

```bash
curl -fsSL https://raw.githubusercontent.com/adiacov/agent-workspace/main/install.sh | bash
```

The public installer URL is `https://raw.githubusercontent.com/adiacov/agent-workspace/main/install.sh`. It points at `install.sh` in the default branch; the installer resolves and installs the latest stable GitHub release/tag. The first public release must have a stable tag matching `VERSION` before true remote GitHub validation.

Until the final install URL is published, install from a checkout:

```bash
./install.sh
```

This installs:

```text
$HOME/.local/bin/agent-ws
$HOME/.local/lib/agent-ws/
$HOME/.local/share/agent-ws/templates/
```

If you choose another install root, pass `--prefix`:

```bash
./install.sh --prefix "$HOME/.local"
```

Ensure `PREFIX/bin` is on `PATH` before running `agent-ws`.

### Pinned install

Pinned install uses the same public installer with an explicit version:

```bash
AGENT_WS_VERSION=v0.1.0 curl -fsSL https://raw.githubusercontent.com/adiacov/agent-workspace/main/install.sh | bash
```

The installer resolves exactly the requested version, validates that the staged command reports that version, and preserves any existing install if the requested release is unavailable or invalid. Versions use the `vMAJOR.MINOR.PATCH` format and must match public GitHub tags/releases for remote install and update.

### Version

Show the installed command version with:

```bash
agent-ws version
```

Example output:

```text
agent-ws v0.1.0
```

The version comes from the installed payload, not from the current working directory.

### Update

Release-aware updates use Git/GitHub stable releases or tags:

```bash
agent-ws update
agent-ws update --version v1.2.3
```

`agent-ws update` resolves the latest stable release/tag. `agent-ws update --version` selects an exact release. Updates are staged and validated with `agent-ws version` before activation. Failed updates preserve the currently working `agent-ws` command and report the failed stage. This updates only the installed tool and global templates; use `sync` separately for project-level maintenance.

### Uninstall / cleanup

Manual cleanup removes only the installed command and support files. It does not remove project files created by `agent-ws init`:

```bash
rm -f "$HOME/.local/bin/agent-ws"
rm -rf "$HOME/.local/lib/agent-ws"
rm -rf "$HOME/.local/share/agent-ws"
```

### Supported platforms

Linux-based shell environments are the first supported target. Compatible macOS shells may work when the required standard tools are available. WSL may work but is not a first-class tested target yet. Native Windows outside WSL is not supported in this phase.

## Migration from the older project-local model

Older projects may contain:

- `.agent/`
- `.agent/templates/`
- `bin/agent-workspace`
- active instruction files such as `AGENTS.md`, `CLAUDE.md`, or Cursor rules
- context or memory files such as `PROJECT.md`, `STATE.md`, and legacy `BRAINSTORM.md`

The migration rule is conservative:

- active instruction files are project-owned and must be preserved;
- context and memory files are project-owned and must be preserved;
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

The migration helper preserves active instruction files and memory by default. After a project has been migrated to the global model, use `sync` for future project-level maintenance instead of running `migrate` again.

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

Non-interactive setup for scripts:

```bash
agent-ws init --profile code --agents pi --no-prompt
```

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
