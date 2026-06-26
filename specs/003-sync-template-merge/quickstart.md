# Quickstart / Validation: merge-based sync

End-to-end scenarios that prove the feature. Run from a checkout with the dev install on PATH
(`./install.sh`), or point `AGENT_WS_TEMPLATE_SOURCE_DIR` at a templates dir. All scenarios run
**agentless** (no `AGENT_WS_AGENT_PRESENT`) so behavior is deterministic.

## Scenario 1 — Additive section flows in, local edits preserved (US1)

1. `agent-ws init demo --profile general --agents claude --no-prompt`
2. Edit `demo/WORKFLOWS.md` (add a local line the templates don't have).
3. Add a new `## NewSection` to the source template `default/WORKFLOWS.md`.
4. `agent-ws sync demo --dry-run` → reports `WORKFLOWS.md: updated` (incoming `## NewSection`).
5. `agent-ws sync demo --apply` → exit 0.
6. **Expect**: `demo/WORKFLOWS.md` now contains `## NewSection` AND the local line; baseline
   refreshed; no `.bak`/`.merge` left.

## Scenario 2 — Overlapping change is refused safely (US2)

1. From Scenario 1 state, change the SAME line in both `demo/WORKFLOWS.md` and the template,
   differently.
2. `agent-ws sync demo --apply` → **exit non-zero**, reports `WORKFLOWS.md: conflicted`.
3. **Expect**: `demo/WORKFLOWS.md` byte-identical to before; a `demo/WORKFLOWS.md.merge` exists
   with conflict markers; live file has NO markers.

## Scenario 3 — Existing project with no baseline gets seeded (US3)

1. `agent-ws init legacy ... --no-prompt`, then delete `legacy/.agent-workspace/baseline/`.
2. `agent-ws sync legacy --apply` → reports `seeded`; baseline dir recreated; no destructive
   change.
3. Change a template section, `agent-ws sync legacy --apply` → now behaves like Scenario 1.

## Scenario 4 — Content files never touched (US4)

1. Fully rewrite `demo/STATE.md` and `demo/PROJECT.md`.
2. `agent-ws sync demo --dry-run` and `--apply`.
3. **Expect**: both files reported `skipped-content` (or omitted) and unchanged on disk.

## Scenario 5 — diff shows the incoming delta, readably

1. With a template section added since last sync, `agent-ws diff demo`.
2. **Expect**: shows the `baseline→template` incoming delta for framework files only, colorized
   on a TTY; `NO_COLOR=1 agent-ws diff demo` prints plain text. `context` files absent.

## Scenario 6 — Atomicity / recovery

1. Force a write failure mid-run (e.g. read-only target) for one file.
2. **Expect**: that file restored from `.bak`; run reports failure; no partial file remains.

## Automated coverage

- `tests/unit/`: 3-way merge wrapper (clean/conflict), classify-by-kind, baseline seed/refresh,
  backup create/remove/restore.
- `tests/integration/`: Scenarios 1–6 above, each in an isolated temp dir (no repo pollution).
- `tests/smoke/`: `sync`/`diff` help + flag validation.
