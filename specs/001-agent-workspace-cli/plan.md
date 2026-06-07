# Implementation Plan: Agent Workspace CLI

**Branch**: `001-agent-workspace-cli` | **Date**: 2026-06-07 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-agent-workspace-cli/spec.md`

## Summary

Create a globally installed `agent-ws` CLI that initializes and manages Agent Workspace projects from canonical templates bundled with the global installation or selected release source. New projects store committed metadata under `.agent-workspace/`, do not receive project-local template caches, do not receive `bin/agent-workspace`, and keep active instruction/memory files project-owned. The implementation will evolve the existing Bash CLI/bootstrap behavior into a global-command model, add discovery/audit/diff/sync/update/migration capabilities, and rewrite README documentation around one clear quickstart.

## Technical Context

**Language/Version**: Bash using POSIX-friendly shell patterns where practical; repository already uses Bash and `#!/usr/bin/env bash`.

**Primary Dependencies**: Standard Unix userland commands already implied by the project: `bash`, `git`, `curl`, `find`, `diff`, `mkdir`, `cp`, `chmod`, `date`, and common text utilities. No package registry dependency for MVP.

**Storage**: Filesystem-based project state. Project metadata is stored under committed `.agent-workspace/` files. Global templates are stored with the installed CLI/release payload, not copied into each target project.

**Testing**: Shell syntax checks plus integration-style fixture tests using temporary directories and command execution. Tests verify generated files, metadata, no-overwrite behavior, discovery classifications, audit findings, diff output, migration preview, and README quickstart commands.

**Target Platform**: Unix-like developer machines with Bash available; Linux/macOS are primary. Windows support is limited to environments capable of running Bash unless a later release adds native PowerShell support.

**Project Type**: Global CLI tool plus reusable templates and documentation.

**Performance Goals**: Initialize or add an agent in under 2 minutes; add-agent in under 1 minute; audit/discovery accurate for representative fixture trees; discovery skips heavy folders to avoid expensive scans.

**Constraints**: No silent overwrites; active files and memory remain project-owned; no project-local template cache by default; no project-local CLI copy; metadata must avoid private or machine-specific content and be committed by default; update/install source is Git/GitHub stable releases or tags; updates preserve the current working command until the new version is validated; old project-local template caches are outside the supported product model.

**Scale/Scope**: Single-user local developer CLI for tens to low hundreds of local projects. No hosted service, GUI, personal registry, semantic active-file merge, or package registry publishing in MVP.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The constitution file is still a placeholder and contains no ratified project-specific gates. This plan applies the effective project rules from `WORKFLOWS.md`, `ENGINEERING.md`, `SPEC.md`, and the feature spec:

- Templates are source of truth for generated content.
- Global CLI owns reusable mechanisms and templates.
- Target projects own active instruction files and memory.
- No silent overwrites.
- Documentation and migration guidance are part of the deliverable.
- Implementation should remain simple, portable, and aligned with the existing Bash project unless a future decision justifies a rewrite.

**Gate Status**: PASS — no ratified constitution violations.

## Project Structure

### Documentation (this feature)

```text
specs/001-agent-workspace-cli/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── cli.md
│   └── metadata.md
└── tasks.md              # Created later by /speckit.tasks
```

### Source Code (repository root)

```text
bin/
└── agent-ws              # global CLI command source/installed executable name

install.sh                # installs or updates agent-ws from the repository/release payload
bootstrap.sh              # legacy bootstrap entrypoint updated to point users to install.sh / agent-ws

lib/
└── agent-ws/
    ├── commands.sh       # command dispatch and shared command helpers
    ├── templates.sh      # global template source resolution and copying helpers
    ├── metadata.sh       # .agent-workspace metadata read/write helpers
    ├── discovery.sh      # discovery scoring and directory traversal
    ├── audit.sh          # project health checks
    ├── diff.sh           # active-file/template comparison helpers
    ├── sync.sh           # conservative sync/refresh helpers
    ├── update.sh         # Git/GitHub stable release/tag update helpers with staged replacement
    └── migrate.sh        # legacy project migration preview/apply helpers that ignore old template caches

templates/
├── default/
├── adapters/
└── profiles/

tests/
├── fixtures/
├── integration/
└── smoke/

README.md
```

**Structure Decision**: Keep Bash as the implementation language and split the current monolithic script into small shell modules under `lib/agent-ws/`, with `bin/agent-ws` as the global executable entrypoint. Keep repository templates under `templates/` and use them as the global installed template source. Add `install.sh` for Git/GitHub release installation/update. Update `bootstrap.sh` as a legacy transition entrypoint that directs users to `install.sh` and `agent-ws`, not as the primary user flow.

## Complexity Tracking

No constitution violations or complexity exceptions are required for this plan.
