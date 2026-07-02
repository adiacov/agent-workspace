# Agent Workspace Spec

## Status

Current. Describes the shipped global-CLI model. Supersedes the earlier project-local
(`.agent/templates/`, `bin/agent-workspace`, `bootstrap.sh`) draft.

## Goal

Agent Workspace bootstraps agent-specific instruction files and project context files into a
target project from maintainable templates, using a single globally-installed `agent-ws` command.

The generated files live where each supported agent actually expects to find them. There is no
hidden shared active instruction layer that agents must discover indirectly.

## Core principles

- Templates are the source of truth for generated content.
- Shell modules orchestrate copying, prompting, and reconciliation; they do not embed Markdown
  file bodies.
- Generated agent instruction files are placed at the correct agent-native auto-load locations.
- No silent overwrites: existing generated files are skipped.
- The tool is meaning-free: it copies scaffolding but never reads or maintains a project's own
  content (its `STATE.md`, `PROJECT.md`, etc.).
- One global command, installed once per user; projects do not carry a local CLI copy or a local
  template cache.

## Install and command model

`agent-ws` is installed once per user (default under `~/.local`) via `install.sh` or the public
`install.sh | bash` one-liner. Templates ship with the installed payload, not inside each project.
Projects are initialized in place; they do not receive `.agent/`, `.agent/templates/`, or a
`bin/agent-workspace` copy. The older project-local model is supported only through `agent-ws
migrate`, which converts a legacy project to the global model while preserving project-owned files.

## Profiles

A profile selects the *shape* of scaffolding `init` creates:

- `general`: the single-project core — `PROJECT.md`, `STATE.md`, `WORKFLOWS.md`, `.gitignore`.
- `code`: `general` plus `ENGINEERING.md` (engineering guidance). For building one project.
- `cockpit`: `general` plus a control-room layer for steering many separate project repos —
  `PROJECTS.md` (project index), `PROFILE.md` (strategy/context), `WORKFLOWS-COCKPIT.md`
  (control-room workflows), and a cross-cutting `STATE.md` variant. For coordinating projects
  toward a goal rather than building a single one. Standalone (no profile stacking).

The profile is recorded in `.agent-workspace/workspace.json`.

## Generated (active) files

Active files are consumed by humans or agents, placed at visible or agent-native locations:

- `AGENTS.md` — the canonical instruction entrypoint shared by every supported agent
  (pi, codex, and Cursor read it natively)
- `CLAUDE.md` for Claude Code — a thin shim that imports `AGENTS.md` (`@AGENTS.md`)
- a custom pointer file at a user-chosen project-relative path (custom agent), deferring
  to `AGENTS.md`
- `PROJECT.md` (stable project identity), `STATE.md` (canonical current-context entrypoint)
- `WORKFLOWS.md` (primary workflow authority), and `ENGINEERING.md` / cockpit files per profile
- `.gitignore` with privacy-aware defaults

Existing active files are skipped, never silently overwritten.

## Ownership model

Each generated file is recorded with a `kind` that governs synchronization:

- `default` / `profile` / `adapter` are **framework** files: `agent-ws sync` reconciles published
  template changes into them via a per-project gitignored baseline three-way merge, preserving
  local edits.
- `context` files (`PROJECT.md`, `STATE.md`, and the cockpit `PROJECTS.md` / `PROFILE.md`) are
  **content**: seeded once and never synced or read by the tool.

The base `WORKFLOWS.md` template is identical across all profiles; cockpit control-room workflows
live in the companion `WORKFLOWS-COCKPIT.md` (a framework file), keeping the base untouched.

## Supported agents

Every agent shares the canonical `AGENTS.md`; agents that cannot read it natively get a
thin shim that defers to it.

| Agent  | Generated path(s)                                            |
| ------ | ------------------------------------------------------------ |
| pi     | `AGENTS.md`                                                  |
| codex  | `AGENTS.md`                                                  |
| claude | `AGENTS.md` + `CLAUDE.md` (shim importing `@AGENTS.md`)      |
| cursor | `AGENTS.md` (read natively; no `.cursor` rules file)         |
| custom | `AGENTS.md` + pointer file at a user-provided relative path  |

Pre-v0.4.0 projects may still record the retired per-agent templates
(`adapters/pi/AGENTS.md`, `adapters/codex/AGENTS.md`, the cursor `.mdc`); readers upgrade
those records on the fly and `sync --apply` persists the rewrite. A pre-existing
`.cursor/rules/agent-workspace.mdc` is preserved but no longer template-managed.

## Commands

- `init [path] --profile <general|code|cockpit> --agents <list> [--custom-path p] [--no-prompt]`
  — create core files, profile files, selected agent files, and `workspace.json`. Prompts when
  options are omitted and prompting is available.
- `add-agent --agents <list> [--custom-path p]` — add an agent entrypoint to an existing project.
- `status` / `audit` — report project health and expected-file presence per recorded profile.
- `projects` — list globally registered projects with a one-word state each.
- `heal [path] --dry-run|--apply` — bring a project to a healthy state by composing migrate,
  missing-file regeneration, and sync; dry-run by default, never guesses (profile choice,
  invalid metadata, and merge conflicts are reported, not auto-resolved).
- `discover <root...>` — scan roots for project roots (subtrees of a match are pruned); used to
  find projects that predate the registry, never writes it.
- `diff` / `sync` — preview / apply incoming template changes to framework files.
- `migrate --dry-run|--apply` — convert a legacy project-local project to the global model.
- `version` / `update` — report / update the installed command and global templates.

## Project registry

The tool keeps a plain-text registry of managed projects at
`${XDG_DATA_HOME:-~/.local/share}/agent-ws/projects` — one absolute path per line, nothing else.
Projects self-register whenever a command touches them and confirms valid metadata (`init`,
`migrate --apply`, `status`, `audit`, `sync`, `heal`). Listing prunes entries whose directory no
longer exists. The registry records only *where* projects are, never what they mean —
`PROJECTS.md` remains the user-owned place for project meaning.

## Template layout

```text
templates/
  default/       .gitignore, PROJECT.md, STATE.md, WORKFLOWS.md
  profiles/
    software/    ENGINEERING.md            # code profile
    cockpit/     PROJECTS.md, PROFILE.md, STATE.md, WORKFLOWS-COCKPIT.md
  adapters/
    AGENTS.md    # canonical shared entrypoint
    claude/ custom/    # shims deferring to AGENTS.md
```

Initialized projects do not receive a root-level `templates/` directory or a local template cache.

## Non-goals

- No project-local CLI copy or per-project template cache.
- No tool-held record of project *meaning*; the registry stores paths only, and `PROJECTS.md`
  stays a user-owned file.
- No overwrite command; delete a generated file and rerun `init`/`add-agent` to regenerate.
- No external session capture/recovery wiring inside any profile (see the optional, independent
  `checkpoint` companion tool documented in the README).
