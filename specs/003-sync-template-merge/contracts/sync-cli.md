# CLI Contract: `sync` and `diff`

Behavioral contract (not code). Drives integration tests.

## `agent-ws sync [path] --dry-run`

- Resolves the project (CWD or `path`).
- Reports, per framework file, the outcome it WOULD produce (`unchanged | updated | seeded |
  conflicted | missing-* `), and skips `context` files.
- **Modifies nothing** (no live file, no baseline, no backup, no `.merge`).
- Exit `0` even if conflicts would occur (dry-run is informational). Conflicts are clearly
  labeled in output.

## `agent-ws sync [path] --apply`

- Performs the reconciliation in `data-model.md` (state transitions).
- For each framework file: clean merge → write (with `.bak`) + refresh baseline; agentless
  conflict → write `<file>.merge`, leave live file untouched; agent-resolved → write + refresh.
- Baseline-less project: seed baselines, report `seeded`, apply nothing destructive this run.
- Backups removed on whole-run success; on failure, originals restored from `.bak`.
- **Exit non-zero if any file is `conflicted`**; otherwise `0`.
- Never leaves a live file containing conflict markers.

### Flags / invariants
- `--dry-run` and `--apply` are mutually exclusive (existing behavior in `commands.sh`).
- Accepts at most one project path (existing behavior).
- Agent presence signaled by the orchestrator (e.g. `AGENT_WS_AGENT_PRESENT=1`); unset ⇒
  agentless path. Tests/CI run agentless by default.

## `agent-ws diff [path]`

- Reports the **incoming delta** per framework file: `baseline (template-then)` → `template-now`.
- If a project has no baseline, says so (nothing to compare yet) and suggests `sync`.
- Skips `context` files.
- Colorizes add/remove lines on a TTY; emits plain text when `NO_COLOR` is set or output is not
  a TTY.
- Read-only; exit `0`.

## Cross-cutting

- Offline only; no network, no template git history required.
- Output style matches existing `agent_ws_say` line format.
- `context` files (STATE.md, PROJECT.md) are never modified or flagged for update by either
  command.
