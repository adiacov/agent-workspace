# Quickstart Validation: Release, Install, and Update Hardening

Use temporary prefixes so validation does not modify a developer's normal installation.

## Prerequisites

- Linux-based shell environment with Bash.
- Standard tools: `git`, `curl`, `mktemp`, `cp`, `mv`, `chmod`, `tar`, and common text utilities.
- Network access for true remote GitHub scenarios.
- A stable public tag matching `VERSION`, such as `v0.1.0`, before true remote GitHub validation.
- Published installer URL: `<install-url>` is the raw `install.sh` URL documented in `README.md` once releases are published.

## 1. Local checkout install reports version

```bash
prefix="$(mktemp -d)"
./install.sh --prefix "$prefix"
"$prefix/bin/agent-ws" version
```

Expected outcome:

- Install succeeds.
- Version output is clear and matches `VERSION`.
- Installed command can run `help`.

## 2. Installed CLI can initialize a project

```bash
project="$(mktemp -d)"
(
  cd "$project"
  "$prefix/bin/agent-ws" init --profile general --agents pi --no-prompt
)
```

Expected outcome:

- Project initialization succeeds from the installed command.
- The project contains `WORKFLOWS.md`, `PROJECT.md`, `STATE.md`, `AGENTS.md`, and `.agent-workspace/workspace.json`.

## 3. Remote latest stable install

```bash
prefix="$(mktemp -d)"
AGENT_WS_PREFIX="$prefix" curl -fsSL <install-url> | bash
"$prefix/bin/agent-ws" version
```

Expected outcome:

- Install succeeds without manually cloning the repository.
- Installed version is the latest stable public release.
- Output includes PATH guidance if needed.

## 4. Pinned install

```bash
prefix="$(mktemp -d)"
AGENT_WS_PREFIX="$prefix" AGENT_WS_VERSION=v0.1.0 curl -fsSL <install-url> | bash
"$prefix/bin/agent-ws" version
```

Expected outcome:

- Install succeeds for an available pinned release.
- Version output reports `v0.1.0`.

## 5. Invalid pinned install preserves previous command

```bash
prefix="$(mktemp -d)"
./install.sh --prefix "$prefix"
before="$($prefix/bin/agent-ws version)"
AGENT_WS_PREFIX="$prefix" AGENT_WS_VERSION=v9.9.9-does-not-exist curl -fsSL <install-url> | bash || true
after="$($prefix/bin/agent-ws version)"
test "$before" = "$after"
```

Expected outcome:

- Invalid install exits non-zero.
- Existing command still runs.
- Version output before and after is unchanged.

## 6. Update to latest stable

```bash
prefix="$(mktemp -d)"
AGENT_WS_PREFIX="$prefix" AGENT_WS_VERSION=v0.1.0 curl -fsSL <install-url> | bash
before="$($prefix/bin/agent-ws version)"
"$prefix/bin/agent-ws" update
after="$($prefix/bin/agent-ws version)"
printf 'before=%s\nafter=%s\n' "$before" "$after"
```

Expected outcome:

- Update stages and validates a candidate before activation.
- Successful update reports previous and new versions.
- Active command remains runnable after update.

## 7. Failed update preserves active command

Use a controlled test fixture or environment override that forces download or validation failure.

Expected outcome:

- Update exits non-zero.
- The previous `agent-ws version` still succeeds.
- Failure message identifies the failed stage and recovery guidance.

## 8. Documentation review

Review `README.md` and confirm it includes:

- default one-line install command;
- pinned install command;
- `agent-ws version`;
- `agent-ws update`;
- uninstall or cleanup guidance;
- supported platforms;
- release/versioning expectations.
