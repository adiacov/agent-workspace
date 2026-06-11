# Installer Contract: `install.sh`

The installer supports both local checkout installation and remote/curl installation. It writes human-readable status to standard output, errors to standard error, and exits non-zero on failure.

## Local checkout install

```bash
./install.sh [--prefix PREFIX]
```

**Expected outcomes**:

- Installs the command, libraries, templates, and version source from the current checkout.
- Preserves the documented installed layout.
- Validates the installed command before reporting success.
- Reports PATH guidance if needed.

## Remote install

```bash
curl -fsSL <install-url> | bash
```

**Expected outcomes**:

- Resolves the latest stable public release.
- Downloads a coherent release payload.
- Stages the candidate installation before activation.
- Validates the staged command by running version reporting.
- Activates only after validation succeeds.
- Does not require the user to manually clone the repository.

## Pinned remote install

```bash
AGENT_WS_VERSION=v0.1.0 curl -fsSL <install-url> | bash
```

**Environment variables**:

- `AGENT_WS_VERSION`: optional release identifier to install exactly.
- `AGENT_WS_PREFIX`: optional install prefix equivalent to `--prefix` for remote usage.

**Expected outcomes**:

- Installs exactly the requested available release.
- Reports a clear error if the requested release cannot be resolved or validated.
- Does not replace a previously working installation on failure.

## Failure guarantees

For any install mode:

- Failure during release resolution must not modify the active installation.
- Failure during download must not modify the active installation.
- Failure during staging must not modify the active installation.
- Failure during validation must not modify the active installation.
- Activation failure must report the active install state and recovery guidance.

## Installed layout

```text
PREFIX/bin/agent-ws
PREFIX/lib/agent-ws/
PREFIX/share/agent-ws/templates/
PREFIX/share/agent-ws/VERSION or equivalent copied version source
```

The implementation may choose the exact colocated path for the copied version source, but it must remain part of the installed payload and must be discoverable by `agent-ws version`.
