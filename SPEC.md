# Agent Workspace Spec

## Status

Draft for rewrite.

## Goal

Agent Workspace bootstraps agent-specific instruction files and project memory files into a target project using maintainable templates.

The generated files should live where each supported agent actually expects to find them. There should be no hidden shared active instruction layer that agents are expected to discover indirectly.

## Core principles

- Templates are the source of truth for generated content.
- Shell scripts should orchestrate copying and prompting, not embed Markdown file contents.
- Generated agent instruction files must be placed at the correct agent-specific auto-load locations.
- No silent overwrites: existing generated files are skipped unless a future explicit overwrite command is added.
- Keep setup portable and simple for users running a curl bootstrap command.
- Keep local templates after initialization so `add-agent` can work later and users can edit templates locally.

## Target project structure after initialization

Example target project after running bootstrap/init:

```text
.agent/
  templates/
    default/
    adapters/

bin/
  agent-workspace

AGENTS.md        # if pi/codex selected
CLAUDE.md        # if claude selected
.cursor/rules/   # if cursor selected
STATE.md
BRAINSTORM.md
.gitignore
```

Important: initialized target projects should not receive a root-level `templates/` directory. Repository templates are copied to `.agent/templates/` during initialization for local reuse by the CLI. Generated active instruction files themselves are not placed under `.agent/` unless a specific agent requires that location.

## Active generated files

Generated files are active files consumed by humans or agents. They should be placed at visible or agent-native locations:

- `AGENTS.md` for Pi and Codex-style agents
- `CLAUDE.md` for Claude Code
- `.cursor/rules/agent-workspace.mdc` for Cursor
- `STATE.md` for current project state/memory
- `BRAINSTORM.md` for durable reasoning/memory
- `.gitignore` for privacy-aware defaults; it should ignore `.agent/`, `STATE.md`, and `BRAINSTORM.md` by default

There should not be generated active shared instruction files like `.agent/COLLABORATION.md`, `.agent/MEMORY.md`, or `.agent/WORKFLOWS.md` unless a future supported agent explicitly requires them.

## Template storage model

Repository templates live in:

```text
templates/default/
templates/adapters/
```

During bootstrap/init, templates are copied into the target project at:

```text
.agent/templates/
```

This keeps the target project self-contained for later commands such as:

```bash
./bin/agent-workspace add-agent
```

Users may edit `.agent/templates/`, remove generated files, and rerun commands to regenerate customized outputs.

## Supported agents table

This table must be researched and verified before expanding support.

| Agent | Generated path | Notes | Verification status |
| --- | --- | --- | --- |
| pi | `AGENTS.md` | Needs official verification. | TODO |
| codex | `AGENTS.md` | Needs official verification. | TODO |
| claude | `CLAUDE.md` | Needs official verification. | TODO |
| cursor | `.cursor/rules/agent-workspace.mdc` | Needs official verification. | TODO |
| custom | user-provided path | project root path. | N/A |

## Command behavior

### Bootstrap command

The public bootstrap command is:

```bash
curl -fsSL https://raw.githubusercontent.com/adiacov/agent-workspace/main/bootstrap.sh | bash
```

NOTE: research similar commands for windows and macos (the two other popular OS)

Expected behavior:

1. Run init behavior in the current working directory.
2. Ensure git exists for the target project using `git init` only if the current directory is not already inside a git work tree.
3. Install/copy templates into `.agent/templates/`.
4. Generate default files from `.agent/templates/default/`.
5. Install local CLI at `bin/agent-workspace`.
6. Ask which agent adapter(s) to generate.
7. Generate selected agent files at the correct locations from `.agent/templates/adapters/`.

### `./bin/agent-workspace init`

Same behavior as bootstrap init, but using the local CLI. Documentation must state clearly when this command should be run - especially no need to run it after initial bootstrap with curl.

### `./bin/agent-workspace add-agent`

Expected behavior:

1. Ensure `.agent/templates/` exists; if missing, stop and warn the user. Propose the user a recovery strategy see below `Expected behavior for custom agents`.
2. Ask which agent adapter(s) to generate.
3. Generate selected files from `.agent/templates/adapters/`.
4. Skip existing files without overwriting.

Expected behavior for custom agents:

1. Ensure `.agent/templates/` exists; if missing, stop and warn the user.
2. Ask for a project-root-relative output path, such as `INSTRUCTIONS.md` or `.my-agent/instructions.md`.
3. Generate that file from `.agent/templates/adapters/custom/INSTRUCTIONS.md`.
4. Skip the file if it already exists, without overwriting.

Custom support is intentionally simple in the first version: it is a "copy this generic custom template to a user-chosen path" flow, not a reusable named adapter system.

### `./bin/agent-workspace status`

Show presence/missing status for:

- `.agent/templates/`
- `bin/agent-workspace`
- `.gitignore`
- `STATE.md`
- `BRAINSTORM.md`
- `AGENTS.md`
- `CLAUDE.md`
- `.cursor/rules/agent-workspace.mdc`

## Template layout proposal

```text
templates/
  default/
    .gitignore
    STATE.md
    BRAINSTORM.md
  adapters/
    pi/
      AGENTS.md
    codex/
      AGENTS.md
    claude/
      CLAUDE.md
    cursor/
      .cursor/rules/agent-workspace.mdc
    custom/
      INSTRUCTIONS.md
```

## Rewrite plan

1. Create and agree on this spec.
2. Remove old script implementations.
3. Clear README so it can be rewritten from the new model.
4. Verify/reorganize templates to match the spec.
5. Rewrite `bootstrap.sh` from scratch.
6. Copy/sync `bootstrap.sh` into `bin/agent-workspace` or generate local CLI from the same script body.
7. Test bootstrap in a clean temporary project.
8. Test `add-agent` in the initialized temporary project.
9. Test idempotency/no-overwrite behavior.
10. Rewrite README from the final behavior.

## Open questions

- Should default memory files `STATE.md` and `BRAINSTORM.md` be generated by default or only by prompt?
Generate by default.

- Should `.gitignore` ignore `.agent/`, `STATE.md`, and `BRAINSTORM.md` by default?
Yes.

- Should `templates/` in the source repository include only files copied to `.agent/templates/`, or should the target project also get a visible root `templates/` copy?
Only `.agent/templates/` is copied to target projects. Initialized target projects should not have root-level `templates/`.

- Should there be an explicit `regenerate` or `overwrite` command in the future?
Not for the first version. No-overwrite behavior keeps the tool safe. Users can delete generated files and rerun `init` or `add-agent` if they want regeneration; add overwrite support later only if real friction appears.
