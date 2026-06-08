# Quickstart Validation Guide: Agent Workspace CLI

This guide validates the planned `agent-ws` behavior end-to-end. It is not the final README; it is a runnable acceptance guide for implementation.

## Prerequisites

- Unix-like shell with Bash available.
- Git available.
- Curl available for install/update scenarios.
- Repository checkout available as the source under test.

## 1. Install or expose `agent-ws`

From the repository checkout, make the planned global command available in a temporary bin directory:

```bash
TMPBIN="$(mktemp -d)"
# Implementation should provide either install.sh or an equivalent development install command.
./install.sh --prefix "$TMPBIN"
export PATH="$TMPBIN/bin:$PATH"
agent-ws help
```

Expected outcome:

- `agent-ws help` succeeds.
- Help shows one primary install/init flow and references advanced options separately.

## 2. Initialize the current directory

```bash
TMPPROJECT="$(mktemp -d)"
cd "$TMPPROJECT"
agent-ws init --profile code --agents pi --no-prompt
```

Expected outcome:

- `WORKFLOWS.md`, `STATE.md`, `BRAINSTORM.md`, `.gitignore`, `ENGINEERING.md`, and `AGENTS.md` are created if missing.
- `.agent-workspace/workspace.json` is created.
- `.agent/` is not created.
- `bin/agent-workspace` is not created.
- Existing files are skipped on repeat run.

Repeat check:

```bash
agent-ws init --profile code --agents pi --no-prompt
```

Expected outcome:

- Existing active files are preserved.
- Output reports skipped destinations.

## 3. Initialize a named new project

```bash
ROOT="$(mktemp -d)"
cd "$ROOT"
agent-ws init sample-project --profile general --agents claude --no-prompt
```

Expected outcome:

- `sample-project/` is created.
- `sample-project/CLAUDE.md` and default files are created.
- `sample-project/.agent-workspace/workspace.json` is created.

## 4. Add another agent

```bash
cd "$TMPPROJECT"
agent-ws add-agent --agents claude --no-prompt
```

Expected outcome:

- `CLAUDE.md` is created from global templates.
- Existing `AGENTS.md` is unchanged.
- Metadata records the newly generated file.

## 5. Validate status and audit

```bash
agent-ws status
agent-ws audit .
```

Expected outcome:

- Metadata is present and valid.
- Global template source is available.
- Absence of a project-local template cache is not reported as a problem.
- Legacy signals are reported only if present.
- Invalid or stale metadata is reported without invalidating active files.

## 6. Validate discovery

```bash
ROOT="$(mktemp -d)"
mkdir -p "$ROOT/managed" "$ROOT/legacy" "$ROOT/plain"
(cd "$ROOT/managed" && agent-ws init --profile general --agents pi --no-prompt)
mkdir -p "$ROOT/legacy/.agent" "$ROOT/legacy/bin"
touch "$ROOT/legacy/bin/agent-workspace" "$ROOT/legacy/AGENTS.md"
agent-ws discover "$ROOT"
```

Expected outcome:

- `managed` is a strong match due to `.agent-workspace/` metadata.
- `legacy` is a legacy or uncertain match with listed signals.
- `plain` is not reported as a managed project.

## 7. Validate diff behavior

```bash
cd "$TMPPROJECT"
printf '\n# Local project note\n' >> AGENTS.md
agent-ws diff .
```

Expected outcome:

- Differences are shown.
- Stale metadata or unavailable template mappings are reported clearly when present.
- No files are modified.

## 8. Validate conservative sync

```bash
before="$(sha256sum AGENTS.md | awk '{print $1}')"
agent-ws sync --dry-run .
after="$(sha256sum AGENTS.md | awk '{print $1}')"
test "$before" = "$after"
```

Expected outcome:

- Active files and memory are unchanged.
- Any refresh/check action is reported without applying active-file changes.

## 9. Validate migration preview

```bash
LEGACY="$(mktemp -d)"
mkdir -p "$LEGACY/.agent" "$LEGACY/bin"
touch "$LEGACY/bin/agent-workspace" "$LEGACY/AGENTS.md" "$LEGACY/STATE.md" "$LEGACY/BRAINSTORM.md"
agent-ws migrate --dry-run "$LEGACY"
```

Expected outcome:

- Migration actions are previewed.
- Active instruction files and memory are listed as preserved.
- No deletion happens in dry-run mode.
- Old project-local template cache contents are not inspected, migrated, or used for decisions.

## 10. Validate README primary flow

After implementation, a new user should be able to follow only the README quickstart to:

1. install `agent-ws`;
2. initialize a current directory;
3. add another agent;
4. understand where metadata lives;
5. understand how legacy projects migrate;
6. understand that old project-local template caches are outside the supported model and can be deleted manually.

Expected outcome:

- The README does not present multiple redundant ways to perform the same first-time action before the primary quickstart is complete.
