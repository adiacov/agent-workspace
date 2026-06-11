# STATE.md

Single canonical current-context entrypoint for this repository.

## Current status

Starting phase 002: release, install, and update hardening for the public `agent-ws` CLI lifecycle.

## Active phase/spec/task

- Active specification: `specs/002-release-install-update/spec.md`.
- Quality checklist: `specs/002-release-install-update/checklists/requirements.md`.
- Prior CLI implementation context remains available in `specs/001-agent-workspace-cli/plan.md` when implementation details are needed.

## Next action

- Run `/speckit.plan` (or equivalent planning workflow) for `specs/002-release-install-update/spec.md`.
- During implementation, inspect current install/update/version behavior before editing and preserve failed install/update safety.

## Blockers

- None known.

## Relevant deeper docs

Read only when needed for the current task:

- `PROJECT.md` for stable project identity and boundaries.
- `ENGINEERING.md` for implementation work.
- `specs/001-agent-workspace-cli/plan.md` for CLI architecture and validation context.
- `README.md` for user-facing behavior that must match templates.
