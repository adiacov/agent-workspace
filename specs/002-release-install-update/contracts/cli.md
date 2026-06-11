# CLI Contract: Release, Version, and Update

Commands write human-readable status to standard output, errors to standard error, and exit non-zero on failure.

## `agent-ws version`

Prints installed version information.

**Expected outcomes**:

- Exits successfully when the installed command can locate its version source.
- Prints a clear version identifier matching the installed payload.
- Does not modify files.
- Exits non-zero with recovery guidance if the version source is missing or invalid.

**Minimum validation use**:

- Install and update validation may call this command on a staged candidate before activation.

## `agent-ws update [--version VERSION]`

Updates the active installed command.

**Options**:

- `--version VERSION`: update to a specific release identifier instead of latest stable.

**Expected outcomes**:

- Without `--version`, resolves the latest stable public release.
- With `--version`, resolves exactly the requested release identifier.
- Stages the selected release before changing the active installation.
- Validates the staged command by running version reporting before activation.
- Activates the staged installation only after validation succeeds.
- Reports previous version, new version, and active command path when available.
- Leaves the previous active command usable if resolution, download, staging, validation, or activation fails before safe replacement.

## `agent-ws help version`

Shows concise usage for version reporting.

**Expected outcomes**:

- Documents the purpose of `agent-ws version`.
- Mentions that the version corresponds to the installed payload.

## `agent-ws help update`

Shows concise usage for update.

**Expected outcomes**:

- Documents default latest stable update.
- Documents pinned update syntax.
- States that update is staged and preserves the active install on failure.
