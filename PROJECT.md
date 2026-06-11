# agent-workspace Project

## What this project is

`agent-workspace` is a shell-based CLI and template set for initializing and maintaining project-local collaboration files for AI-assisted work.

## Why it exists

It gives local projects a consistent, portable structure for agent instructions, current context, stable project identity, and optional engineering guidance without tying project meaning to a personal registry or a specific agent.

## Target users

- A developer using multiple local projects with AI coding agents.
- Developers who want reusable agent instruction templates and conservative maintenance commands.

## Boundaries

- Own reusable mechanisms, templates, metadata, discovery, audit, diff, sync preview/apply safety, migration helpers, and install/update behavior.
- Generate initial active files, but treat those files as project-owned after creation.
- Store only non-private setup metadata in `.agent-workspace/workspace.json`.

## Non-goals

- No personal project registry.
- No hosted service or GUI.
- No blind rewriting of project-owned active files or memory.
- No dependency on `life-os` or private machine layouts.
- No semantic merge system unless a later design justifies it.

## Core principles

- One canonical current-context entrypoint per repo: `STATE.md`.
- Agents should follow explicit context pointers instead of reading unrelated historical docs by default.
- Prefer conservative, inspectable changes over automatic overwrites.
- Keep agent adapters thin; shared workflow belongs in `WORKFLOWS.md`.
- Templates are reusable defaults, not permanent ownership claims over initialized files.
