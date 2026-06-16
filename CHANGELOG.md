# Changelog

## v0.1.1 - 2026-06-16

Template context-efficiency release.

### Changed

- Updated default workflow guidance to classify requests before loading broad project context.
- Kept pending checkpoint recovery automatic while making it bounded to durable state extraction.
- Reduced default memory, repository, and historical task-artifact loading to only when relevant.
- Updated adapter templates to load only context required by `WORKFLOWS.md`.
- Clarified `STATE.md` as active-work context with cleanup guidance for completed-work pointers.

## v0.1.0 - 2026-06-11

Initial public release of `agent-ws` as an installable, versioned CLI.

### Added

- Added root `VERSION` source and `agent-ws version`.
- Added remote/curl install path from GitHub.
- Added pinned install support with `AGENT_WS_VERSION`.
- Added staged, validated `agent-ws update`.
- Added failure safety so failed install/update attempts preserve the active install.
- Added release lifecycle smoke and integration coverage.
- Documented install, pinned install, version, update, cleanup, supported platforms, and release expectations.

### Supported environments

- Linux-based shell environments first.
- macOS may work when standard shell tools are available.
- WSL may work but is not a first-class tested target yet.
- Native Windows outside WSL is not supported.
