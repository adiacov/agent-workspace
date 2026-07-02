# agent-workspace

**Give your AI coding agents a memory and a consistent way of working — one that survives across sessions, across tools, and across projects.**

AI agents start every session amnesiac: they don't know what your project is, what you decided last time, or how you like to work — and each tool (Claude, Cursor, Codex, Pi…) looks for its own instruction file. So you re-explain the same context over and over, and it drifts.

`agent-ws init` fixes that with one command. It scaffolds a few plain-Markdown files — what the project *is* (`PROJECT.md`), what's *true right now* (`STATE.md`), and *how you work* (`WORKFLOWS.md`) — and wires up the entrypoint each agent you use already reads. Every session, any agent picks up the same durable context, so the project stays coherent no matter which tool or how much time has passed. The files are yours; the tool copies scaffolding and never reads or edits your content.

See [CHANGELOG.md](CHANGELOG.md) for release history.

## Contents

- [What you can build](#what-you-can-build)
- [Primary quickstart](#primary-quickstart)
- [Commands](#commands)
- [What gets created in a project](#what-gets-created-in-a-project)
- [Context model](#context-model)
- [Metadata and ownership](#metadata-and-ownership)
- [Synchronization for existing global projects](#synchronization-for-existing-global-projects)
- [Install and update model](#install-and-update-model)
- [Migration from the older project-local model](#migration-from-the-older-project-local-model)
- [Advanced options](#advanced-options)
- [Templates](#templates)

## What you can build

Pick the *shape* you need when you run `init` — the profile.

**One project** — a single repo with its own durable memory and workflow:

- `general` — for any generic project: notes, research, planning, writing, a business or idea you're shaping.
- `code` — for software projects.

```
my-project/
├── STATE.md          what's true now
├── WORKFLOWS.md      how we work
├── PROJECT.md        what this is
└── ENGINEERING.md    how we build   (code profile only)
```

**Many projects at once** — use `cockpit`: one place that remembers and coordinates several separate project repos, pointing at each without swallowing it.

```
                 my-cockpit/            ← you steer from here
                 ├── PROJECTS.md        index of everything below
                 ├── PROFILE.md         your goals + context
                 ├── STATE.md           current focus (cross-project)
                 └── WORKFLOWS.md        + control-room workflows
                        │
      ┌─────────────────┼─────────────────┐
      ▼                 ▼                 ▼
 ../project-a       ../project-b       ../project-c   ← separate repos,
 (own STATE.md)     (own STATE.md)     (own STATE.md)   each stands alone
```

See [Advanced options](#advanced-options) for the full profile walkthrough.

## Primary quickstart

Install the command for your user. From a repository checkout, run:

```bash
./install.sh
export PATH="$HOME/.local/bin:$PATH"
agent-ws help
```

For public GitHub install, see [Install and update model](#install-and-update-model).

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
| Inspect project health or incoming template changes | `status`, `audit`, `diff` | one or more projects |
| See every project registered with agent-ws, with its state | `projects` | the global project registry |
| Bring a project to a healthy state with one command | `heal` | one project (preview first) |
| Merge published template changes into a project | `sync` | one project's framework files |
| Convert an old `.agent/` project to the global model | `migrate` | one legacy project |
| Update the installed `agent-ws` command and global templates | `update` | user-level installation, not project files |

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
agent-ws projects
```

Lists every project registered with agent-ws, one line per project with a one-word state (`in-sync`, `outdated`, `incomplete`, `legacy`, …). Projects register themselves whenever the tool touches them and finds valid metadata (`init`, `migrate`, `status`, `audit`, `sync`, `heal`); the registry lives at `~/.local/share/agent-ws/projects` (one absolute path per line), and entries whose directory no longer exists are pruned on listing.

```bash
agent-ws heal [path]
agent-ws heal [path] --apply
```

Brings a project to a healthy state with one command, composing the existing steps in order: adopt if legacy or unmanaged (`migrate`), recreate missing files from templates (existing files are never overwritten), then `sync` (seed baselines / merge template changes). Defaults to a dry-run that shows the plan. It never guesses on your behalf: uninitialized directories (init needs your profile choice), unreadable metadata, and sync conflicts are reported with instructions instead of auto-resolved.

```bash
agent-ws discover <root...>
```

Scans explicit roots for likely Agent Workspace projects and reports project roots — once a directory matches, its subtree is not descended into, so a project's internals (template caches, baselines, build output) are never reported as separate matches. Useful for finding projects that predate the registry; it never writes the registry itself.

```bash
agent-ws diff [path]
```

Shows the incoming template delta for framework files — what the current templates would bring in relative to each project's baseline (the template version it last synced from). Read-only; colorized on a TTY, plain under `NO_COLOR` or when piped. Content files (`STATE.md`, `PROJECT.md`) are not shown.

```bash
agent-ws sync [path] --dry-run
agent-ws sync [path] --apply
```

Merges published template changes into a project's framework files (`WORKFLOWS.md`, `ENGINEERING.md`, agent adapter files) using a per-project baseline three-way merge. Template-only additions apply cleanly while local edits are preserved. Overlapping edits are refused — the live file is left untouched, a `*.merge` side-file with conflict markers is written, and the run exits non-zero (resolve that file separately). Content files (`STATE.md`, `PROJECT.md`) are never synced. A project with no baseline is seeded on first sync. It does not update the installed `agent-ws` command and does not migrate legacy `.agent/` projects.

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
- `PROJECTS.md`, `PROFILE.md`, and `WORKFLOWS-COCKPIT.md` for the `cockpit` profile (with a cross-cutting `STATE.md` variant)
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
- `HANDOFF.md`: optional transient outbox for progress not yet delivered downstream. It is not project history (git log and `STATE.md` hold history). The agent creates and appends to it only when the user explicitly asks for a handoff/digest; it is not generated by `init`. It is gitignored as transient transport.

Agents should classify the request before loading broad project context and use the smallest useful context set. They should not blindly read unrelated historical task artifacts, decisions, or old context files by default.

A downstream workspace may later ingest and drain `HANDOFF.md`; the producer contract in `WORKFLOWS.md` stays generic and never names a specific consumer.

## Complementary tools

An Agent Workspace project is, by design, a collaboration between a human and AI agents. A common failure mode of that collaboration is *losing work* when a session ends, is compacted, or the user switches agents.

**checkpoint** — a safety net for agent sessions. Working with a coding agent is amnesiac: when a session ends or is compacted, the context of what you were doing is gone. [`checkpoint`](https://github.com/adiacov/checkpoint) captures your git state and recent conversation at the end of a session so your next session — in any supported agent — can pick up where you left off. It is optional and independent of `agent-workspace`; nothing here installs, configures, or depends on it. Install it separately if you want that protection, and see its README for setup and usage.

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
- Active files may contain local project-specific edits and are preserved.

`sync` relaxes this just enough to be useful: it merges template changes into framework files
while preserving local edits (clean additions apply; overlapping edits are refused, never
overwritten). To support this each project keeps a **baseline** — a snapshot of the template
version it last synced from — under `.agent-workspace/baseline/`. The baseline is a local,
gitignored working artifact (a fresh clone re-seeds it on first sync). Content files
(`STATE.md`, `PROJECT.md`) remain seed-once and are never synced.

## Synchronization for existing global projects

After updating the global templates (`agent-ws update`), use `sync` from within a project to
pull those template changes into the project's framework files. Typical flow:

1. inspect the incoming delta: `agent-ws diff /path/to/project`;
2. preview per-file outcomes: `agent-ws sync /path/to/project --dry-run`;
3. apply: `agent-ws sync /path/to/project --apply`.

Do not use `sync` to update the installed tool; use `agent-ws update` for that. Do not use
`sync` for older `.agent/` projects; use `migrate` for those.

Preview first:

```bash
agent-ws sync /path/to/project --dry-run
```

Apply after reviewing the preview:

```bash
agent-ws sync /path/to/project --apply
```

Per-file outcomes are reported as: `unchanged`, `updated`, `seeded` (baseline established),
`conflicted` (refused — a `*.merge` side-file is written and the run exits non-zero),
`skipped-content` (`STATE.md`/`PROJECT.md`), or `missing-active` / `missing-template`. On a
clean run a backup is taken before each write and removed on success; if a write fails the
original is restored. The first sync on a project created before this model establishes the
baseline and applies nothing destructive that run.

## Install and update model

The intended product model is a global/user-level `agent-ws` command that can be run from anywhere. Projects do not receive a project-local command copy.

Updating the installed tool and maintaining project files are separate steps:

1. use `agent-ws update` to update the installed command and global templates;
2. use `agent-ws sync --dry-run /path/to/project` when you want to inspect maintenance for an existing project.

### Public install

Public GitHub install installs the latest stable GitHub release/tag by default. The installer stages the payload, validates it, and activates it only after validation succeeds:

```bash
curl -fsSL https://raw.githubusercontent.com/adiacov/agent-workspace/main/install.sh | bash
```

The public installer URL is `https://raw.githubusercontent.com/adiacov/agent-workspace/main/install.sh`. It points at `install.sh` in the default branch; the installer resolves and installs the latest stable GitHub release/tag.

For local development or testing from a checkout, run:

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

- `general`: core memory and workflow files for a single project. Choose this for any non-code project — notes, research, planning, writing, a business or idea you're shaping.
- `code`: `general` plus engineering guidance in `ENGINEERING.md`. Choose this for software projects.
- `cockpit`: `general` plus a control-room layer for steering *many* separate project repos over time. Choose this when you are coordinating several projects toward a goal — business, career, study, side-projects — rather than working inside a single one.

The `cockpit` profile adds:

- `PROJECTS.md` — an index of the projects the cockpit coordinates (name, one-line purpose, coarse status, path to each project's own repo). The cockpit points at each project's own `STATE.md`; it does not hold per-project implementation detail.
- `PROFILE.md` — the strategy/context layer: background, goals, constraints, and preferences for what you are steering. Ships with neutral placeholder content.
- `WORKFLOWS-COCKPIT.md` — control-room workflows that augment the base `WORKFLOWS.md`: the cross-project one-way-dependency rule (cockpit → projects, never the reverse), the explore→build→reflect loop (explore in the cockpit, build in a separate project repo, return to reflect), and an optional handoff-ingest ritual.
- a cross-cutting `STATE.md` variant: current focus and coarse per-project status pointing at each repo's own `STATE.md`, rather than a single project's active state.

A cockpit indexes and reasons about sibling projects, but each sibling repo stays understandable on its own and never depends on the cockpit. Create a cockpit with:

```bash
agent-ws init --profile cockpit --agents pi --no-prompt
```

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
