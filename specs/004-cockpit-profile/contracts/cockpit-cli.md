# CLI Contract: `--profile cockpit`

Delta only; all other `agent-ws` behavior is unchanged.

## `agent-ws init --profile cockpit`

**Accepts**: `cockpit` wherever `general`/`code` are accepted — the `--profile` flag, the
interactive profile prompt, and `--no-prompt` validation.

**Generates** (in the target project root), in addition to nothing being removed:

```
.gitignore
PROJECT.md
STATE.md              # cockpit cross-cutting index variant
WORKFLOWS.md          # base template, unchanged
WORKFLOWS-COCKPIT.md  # control-room workflows (framework, synced)
PROJECTS.md           # project index (content, seeded once)
PROFILE.md            # strategy/context (content, seeded once)
<agent adapter file>  # per --agents
```

**Metadata**: `.agent-workspace/workspace.json` records `"profile": "cockpit"` and every
generated file in `generatedFiles` with its kind.

**Exit**: `0` on success. Existing destinations are skipped (not overwritten), consistent with
current init behavior.

## Errors

- Invalid `--profile <x>`: exit non-zero; message `unsupported profile: <x>`; remediation hint
  lists `general`, `code`, and `cockpit`.
- `--no-prompt` without `--profile`: unchanged error, hint mentions all three profiles.

## `agent-ws audit` (cockpit project)

Expected-files check includes `PROJECTS.md`, `PROFILE.md`, `STATE.md`, `WORKFLOWS.md`,
`WORKFLOWS-COCKPIT.md`, plus the recorded agent adapter(s). A fresh cockpit project reports every
expected file `present` and `partial state: no`.

## `agent-ws sync` (cockpit project)

Reconciles framework files only. `WORKFLOWS-COCKPIT.md` (kind `profile`) participates in the
baseline three-way merge like `ENGINEERING.md`. `PROJECTS.md`, `PROFILE.md`, `STATE.md`
(kind `context`) are never touched.

## Unchanged contracts

`agent-ws init --profile general|code` produces byte-identical output to the prior release.
