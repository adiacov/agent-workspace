# Implementation Plan: Release, Install, and Update Hardening

**Branch**: `002-release-install-update` | **Date**: 2026-06-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-release-install-update/spec.md`

## Summary

Harden the public lifecycle for `agent-ws` so a new user can install directly from GitHub, verify the installed version, pin a specific release, and safely update later without manually cloning the repository. The implementation will extend the existing Bash CLI and installer with a root version source, `agent-ws version`, deterministic GitHub tag/release resolution, staged install/update replacement, failure-safety tests, and README guidance.

## Technical Context

**Language/Version**: Bash using the existing `#!/usr/bin/env bash` command and module layout; keep POSIX-friendly patterns where practical but continue using Bash because the current CLI already does.

**Primary Dependencies**: Standard Unix userland tools already used by the project: `bash`, `git`, `curl`, `mktemp`, `find`, `diff`, `mkdir`, `cp`, `mv`, `rm`, `chmod`, `date`, and common text utilities. No package registry dependency for this phase.

**Storage**: Filesystem-based installed payload under a user-selected prefix. A root `VERSION` file is the single version source copied into the installed payload. Temporary staging directories are used for install/update candidates.

**Testing**: Existing shell syntax checks plus integration/smoke tests under `tests/integration/` and `tests/smoke/`. Add tests for version reporting, remote-style archive install, pinned install, latest stable selection, staged update success, and failed install/update safety.

**Target Platform**: Linux-based shell environments first. Compatible macOS shells may work when required tools are present. Native Windows outside WSL is out of scope.

**Project Type**: Shell-based CLI tool plus install/update scripts and documentation.

**Performance Goals**: A user can complete install and version verification in under 5 minutes on a clean supported environment. Local smoke tests for install/update should complete quickly enough to remain part of normal validation.

**Constraints**: Failed install/update must preserve any currently working installation; updates are explicit; default public install/update resolves to latest stable GitHub release/tag; pinned release install/update must be reproducible; local checkout install remains supported; no Homebrew/apt/npm/pipx/Docker distribution in this phase.

**Scale/Scope**: Single-user developer CLI distribution for early public GitHub usage. Supports one active installation prefix at a time per command invocation; no hosted service, package-manager channel, native Windows installer, or unrelated feature work.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The constitution file is still a placeholder and contains no ratified project-specific gates. This plan applies the effective project rules from `WORKFLOWS.md`, `ENGINEERING.md`, `PROJECT.md`, and the feature spec:

- Prefer conservative, inspectable changes over automatic overwrites.
- Keep the implementation simple, shell-native, and aligned with the current Bash CLI.
- Preserve active project-owned files and installed commands when lifecycle operations fail.
- Documentation and smoke/integration tests are part of the deliverable.
- No unrelated feature work or package-manager distribution in this phase.

**Gate Status**: PASS — no ratified constitution violations.

## Project Structure

### Documentation (this feature)

```text
specs/002-release-install-update/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── cli.md
│   └── installer.md
└── tasks.md              # Created later by /speckit.tasks
```

### Source Code (repository root)

```text
VERSION                  # single source of version truth
install.sh               # local and remote/curl installer with staging validation
bin/
└── agent-ws             # global CLI command entrypoint

lib/
└── agent-ws/
    ├── commands.sh      # dispatch, help, version command routing
    ├── update.sh        # staged update and GitHub release/tag helpers
    └── templates.sh     # installed payload/template location compatibility

templates/               # installed reusable templates copied as part of payload

tests/
├── integration/
│   ├── test_version.sh
│   ├── test_install_remote.sh
│   ├── test_install_pinned.sh
│   ├── test_update_staged.sh
│   └── test_update_failure_safety.sh
└── smoke/
    └── run-smoke.sh

README.md                # public install/update/version/uninstall documentation
```

**Structure Decision**: Keep the current shell module layout. Add a root `VERSION` file and install/update behavior around the existing `install.sh`, `bin/agent-ws`, and `lib/agent-ws/update.sh`. Do not introduce a package manager, compiled binary, or separate release asset format unless a tag archive cannot satisfy validation during implementation.

## Complexity Tracking

No constitution violations or complexity exceptions are required for this plan.

## Phase 0: Research Summary

Research is captured in [research.md](./research.md). Key decisions:

- Use `vMAJOR.MINOR.PATCH` tags externally and store the same value in `VERSION` for phase simplicity.
- Install from GitHub tag archives by default; local checkout install remains a separate path.
- Resolve latest stable from GitHub releases when available, falling back to tags with stable-name filtering.
- Keep default prefix as `$HOME/.local` for compatibility with the current installer.
- Stage all install/update payloads in temporary directories and validate `agent-ws version` before activation.

## Phase 1: Design Summary

Design artifacts generated:

- [data-model.md](./data-model.md): release/version/install/staging entities and state transitions.
- [contracts/cli.md](./contracts/cli.md): user-visible `version` and `update` command contracts.
- [contracts/installer.md](./contracts/installer.md): installer environment variables, options, outcomes, and failure guarantees.
- [quickstart.md](./quickstart.md): end-to-end validation scenarios for install, pinning, update, and failure safety.

## Post-Design Constitution Check

The design keeps lifecycle operations staged, validates before activation, documents public behavior, and preserves the current shell architecture. No ratified constitution violations were introduced.

**Gate Status**: PASS.
