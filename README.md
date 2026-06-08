# agent-workspace

Agent Workspace standardizes the project setup needed to work with AI coding agents.

It generates agent-specific instruction entrypoints, project memory files, and privacy-aware defaults so each project starts with a consistent collaboration structure. This reduces repeated manual setup and helps keep context portable when switching between agents or adding a new agent later.

Note: Current tool is an older way of installing agent-workspace on a project. Next step is to create a CLI tool, which is installed globally on a machine (linux OS). A migration command is supposed to be created for migration from old to new structure.

## Install / initialize

Run from the root of the project you want to initialize:

```bash
curl -fsSL https://raw.githubusercontent.com/adiacov/agent-workspace/main/bootstrap.sh | bash
```

By default, bootstrap uses the `general` workspace profile and asks which agent adapter to generate. To initialize non-interactively, pass the adapter explicitly:

```bash
curl -fsSL https://raw.githubusercontent.com/adiacov/agent-workspace/main/bootstrap.sh \
  | bash -s -- --agents claude
```

Choose a workspace profile with `--profile` or `AGENT_WORKSPACE_PROFILE`:

```bash
agent-workspace init --profile code --agents pi
agent-workspace init --profile general
AGENT_WORKSPACE_PROFILE=code agent-workspace init
```

Supported agents are: `pi`, `codex`, `claude`, `cursor`, and `custom`.

Multiple agents can be selected with commas or spaces:

```bash
curl -fsSL https://raw.githubusercontent.com/adiacov/agent-workspace/main/bootstrap.sh \
  | bash -s -- --agents "pi claude"
```

For `custom`, provide an output path if you do not want the default `INSTRUCTIONS.md`:

```bash
curl -fsSL https://raw.githubusercontent.com/adiacov/agent-workspace/main/bootstrap.sh \
  | bash -s -- --agents custom --custom-path .my-agent/instructions.md
```

The bootstrap command:

1. runs `git init` if needed, or stops if the current directory is inside another git repository but is not that repository root
2. copies templates into `.agent/templates/`
3. creates `STATE.md`, `BRAINSTORM.md`, and `.gitignore` if missing
4. installs `bin/agent-workspace`
5. asks which agent instruction files to generate, unless `--agents` or `AGENT_WORKSPACE_AGENTS` is provided

Existing files are skipped, never overwritten.

Workspace profiles:

- `general` is the default profile. It generates the standard memory files only and does not generate or cache `ENGINEERING.md`.
- `code` adds coding-project engineering guidance by caching `.agent/templates/profiles/software/ENGINEERING.md` and generating root `ENGINEERING.md` if missing. The old `software` profile name is still accepted as a deprecated alias.

## Generated files

Depending on selected agents, Agent Workspace can generate:

- `AGENTS.md` for Pi / Codex-style agents
- `CLAUDE.md` for Claude Code
- `.cursor/rules/agent-workspace.mdc` for Cursor
- a custom instruction file at a path you choose

It also generates private memory files:

- `STATE.md` — current situation, active work, next actions
- `BRAINSTORM.md` — durable reasoning, decisions, observations

The default generated `.gitignore` ignores `.agent/`, `STATE.md`, and `BRAINSTORM.md`.

## Local CLI

After bootstrap, use the local CLI:

```bash
./bin/agent-workspace status
./bin/agent-workspace add-agent
./bin/agent-workspace add-agent --agents cursor
./bin/agent-workspace init --agents claude
./bin/agent-workspace init --profile code --agents pi
./bin/agent-workspace init --profile general
AGENT_WORKSPACE_PROFILE=code ./bin/agent-workspace init
```

`init` repeats the bootstrap behavior using the local CLI. You do not need to run it immediately after the curl bootstrap.

`add-agent` uses `.agent/templates/` to generate additional agent instruction files later.

## Customizing for your own workflow

Agent Workspace is intentionally plain and open source. If the defaults do not match how you work, clone or fork the repository and adapt the templates, supported adapters, or bootstrap behavior for your own needs.

The main customization points are:

- `templates/default/` for memory files and `.gitignore` defaults
- `templates/adapters/` for agent-specific instruction files
- `bootstrap.sh` for initialization behavior

## Templates

Repository templates live in:

```text
templates/default/
templates/adapters/
templates/profiles/
```

Initialized projects receive a local template cache at:

```text
.agent/templates/
```

You can edit `.agent/templates/`, delete generated files, and rerun `init` or `add-agent` to regenerate customized outputs.

## Migration from the older project-local model

Agent Workspace is moving from the older project-local command model to the global
`agent-ws` command.

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
