# agent-workspace

Agent Workspace bootstraps portable, agent-independent collaboration files into any project.

It is designed for people who work with multiple coding agents or AI assistants and want the same collaboration style, memory workflow, and project context everywhere.

## Purpose

Most agents have different entrypoint files:

- Pi / Codex-style agents often read `AGENTS.md`
- Claude Code reads `CLAUDE.md`
- Cursor uses rule files
- future tools may use something else

Agent Workspace keeps the source of truth in a neutral folder:

```text
.agent/
```

Agent-specific files are thin adapters that point back to `.agent/`.

## Generated structure

A typical initialized project may contain:

```text
.agent/
  COLLABORATION.md
  MEMORY.md
  WORKFLOWS.md

AGENTS.md        # optional adapter for Pi/Codex-style agents
CLAUDE.md        # optional adapter for Claude Code
STATE.md         # project-local current state
BRAINSTORM.md    # project-local durable reasoning
```

Only the adapters you choose are created.

## Quick start

From inside a project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/agent-workspace/main/bootstrap.sh | bash
```

Or, from a local clone of this repository:

```bash
./bin/agent-workspace init
```

## Commands

### Initialize a project

```bash
agent-workspace init
```

Initializes git if needed, creates a privacy-aware `.gitignore`, creates the core `.agent/` files, and asks which agent adapter(s) to add.

### Add another agent later

```bash
agent-workspace add-agent
```

Adds another adapter if it does not already exist.

### Check status

```bash
agent-workspace status
```

Shows which core files and adapters exist in the current project.

## Supported adapters

Initial adapters:

- `pi` → `AGENTS.md`
- `codex` → `AGENTS.md`
- `claude` → `CLAUDE.md`
- `cursor` → `.cursor/rules/agent-workspace.mdc`
- `custom` → user-provided path

Note: `pi` and `codex` currently share `AGENTS.md`. This is intentional.

## Design principles

- Agent-independent core
- Plain Markdown files
- Safe and idempotent by default
- No silent overwrites
- Git initialized by default when needed
- Privacy-aware `.gitignore`
- Project-local memory
- Minimal adapters for specific tools

## Repository layout

```text
bin/agent-workspace          # CLI script
bootstrap.sh                 # curl-friendly entrypoint
templates/default/           # human-readable default templates
templates/adapters/          # human-readable adapter templates
```

## License

MIT © Alexandru Diacov
