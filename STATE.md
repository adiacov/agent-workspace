# STATE.md

Single canonical current-context entrypoint for this repository.

## Current status

`v0.4.1` is the latest released tag, released 2026-07-02 on `main` (both v0.4.x releases were
published by CI on tag push — the first clean CI releases; earlier failures were manual
`gh release create` collisions). `v0.4.0` shipped the canonical-AGENTS.md model; `v0.4.1`
fixed heal stomping baselines of skipped files (erasing pending template deltas). Suite green:
smoke + 4 unit + 54 integration. The repo is self-managed by its own tool
(`.agent-workspace/workspace.json`, profile `code`) and registered in the global registry.

## Current model (what the tool is now)

- **Canonical AGENTS.md** (since v0.4.0): one shared instruction entrypoint
  (`templates/adapters/AGENTS.md`) for every agent. pi/codex/cursor map straight to it;
  claude adds a `CLAUDE.md` shim importing it (`@AGENTS.md`); custom adds a pointer file.
  Same-destination specs from the same template dedupe; different templates for one
  destination still conflict. Pre-v0.4.0 adapter records (`adapters/pi|codex/AGENTS.md`,
  cursor `.mdc`) are upgraded on read (`metadata.sh` `AGENT_WS_LEGACY_ADAPTER_PY`) and
  persisted by `sync --apply`; a pre-existing `.mdc` is preserved but unmanaged.
- **Registry**: managed projects self-register (path-only, one per line) at
  `${XDG_DATA_HOME:-~/.local/share}/agent-ws/projects` when any command confirms valid metadata
  (`init`, `migrate --apply`, `status`, `audit`, `sync`, `heal`). `agent-ws projects` lists them
  with a one-word state and prunes dead entries. `discover` never writes it (finds pre-registry
  projects; reports project roots only — subtrees of a match are pruned).
- **Heal**: `agent-ws heal [path]` (dry-run default) composes migrate → recreate missing files →
  sync to take any recoverable state to in-sync. Refuses to guess: uninitialized dirs, invalid
  metadata, and merge conflicts get instructions, not auto-fixes.
- **Output contract** (since v0.2.0): sectioned human output; every command ends with a
  "Next steps" advice block or an "All good" line; state tokens kept verbatim inside glossed
  lines so scripts/tests can grep them.
- **Sync** (since v0.1.3): baseline three-way merge of framework files; content files
  (`STATE.md`, `PROJECT.md`, cockpit `PROJECTS.md`/`PROFILE.md`) never synced.
- **Profiles**: `general`, `code` (+`ENGINEERING.md`), `cockpit` (control-room over many repos).
  `migrate` auto-detects the profile from preserved files (since v0.1.7).

## Fleet

All 12 sibling projects under `~/Documents/private/projects/personal-code/` were remediated on
2026-07-02 (seeded, completed, or migrated; one commit each, pushed), then updated to the
canonical-AGENTS.md model the same day (healed with v0.4.1, conflicts resolved by hand:
stock-plus-tail files got new-template+tail, custom-rewritten AGENTS.md bodies were kept with
the baseline advanced; one commit each, pushed). All in-sync and registered. Excluded on purpose per the user — never adopt/init them: `adiacov.github.io`
(deliberately unmanaged), `docpilot` (not using agent-ws).
Quirks: `spec-kit-issues` has no git remote (commit locally only); `posts` works on feature
branches (e.g. `interview/agent-workspace-20260701`).

## Release flow

1. Content commit(s) first (conventional commits), full suite green: loop
   `bash tests/unit/*.sh tests/integration/*.sh` (skip `helpers.sh`) + `bash tests/smoke/run-smoke.sh`.
2. Bump `VERSION` (`vX.Y.Z` + trailing newline); prepend `## vX.Y.Z - YYYY-MM-DD` to `CHANGELOG.md`.
3. Commit `chore(release): vX.Y.Z (theme)`; annotated tag; `git push origin main vX.Y.Z`.
4. **Never `gh release create`** — CI publishes the release on tag push; verify with
   `gh run watch` / `gh release view`.
5. Update the installed copy with bare `agent-ws update` (`~/.local/bin/agent-ws`,
   templates at `~/.local/share/agent-ws/templates`).

## Codebase gotchas (easy to re-break)

- Records are `:`-delimited (template specs) and `|`-delimited (generated files); user paths
  must reject `:`, `|`, and whitespace.
- Markdown setext `=======` is legit content — conflict detection needs labeled
  `<<<<<<< `/`>>>>>>> ` markers, never a lone `=======`.
- `templateRevision: "missing-*"` in `metadata.sh` looks dead but is the tested "stale"
  contract (fixture in `tests/integration/helpers.sh`).
- Test seams: `AGENT_WS_TEST_RELEASES`, `AGENT_WS_REGISTRY_FILE`, `AGENT_WS_TEMPLATE_SOURCE_DIR`.
  Tests without `AGENT_WS_REGISTRY_FILE` write /tmp paths into the real registry — accepted,
  `projects` prunes dead entries.
- Advice engine in `commands.sh`: commands collect via `agent_ws_advise`, flush one
  "Next steps"/"All good" block; `AGENT_WS_ADVICE_QUIET=1` silences inner flushes (heal uses it).
- State tokens (`metadata: present`, `preserve: X`, …) stay verbatim inside glossed lines —
  tests grep those substrings. Prompts must accept piped (non-tty) stdin.

## Working conventions

- Short, plain-language reports; concrete before/after when proposing changes.
- Implement and test autonomously, but commit/push/release only when the owner asks.
- `reports/` and `HANDOFF.md` are gitignored working files — never commit or force-add them.
- Durable knowledge lives in this repo's files (`STATE.md`, per `WORKFLOWS.md`), not in any
  assistant-private memory store.

## Open follow-ups (not blocking)

Backlog captured in `reports/2026-07-02-fleet-status.md` (local, gitignored):
- Planned discussion: a fleet-level feature (bulk status/heal across the registry —
  `projects` + `heal` are its foundation).
- `init` gitignore-seeding gap: when a project keeps its own `.gitignore`, the baseline entries
  (`.agent-workspace/baseline/`, `*.bak`, `*.merge`) are never added.
- `migrate` is silent about non-cache user files inside legacy `.agent/` (real docs were found
  there in wikistream-observatory).
- `agent-ws update` on the current version prints "updated vX -> vX" instead of "already up to
  date" (dry-run path already handles it).
- Bump `actions/checkout@v4` deprecation annotation in CI (from the v0.1.4 session).
- Sync conflict-resolution loop: after resolving a `*.merge` by hand, re-running sync conflicts
  again unless the baseline is manually advanced to the current template (overlapping hunks
  merge cleanly only when byte-identical). The documented advice omits the baseline step;
  consider a `sync --resolve <file>` helper or advice fix.

## History

- v0.1.3 merge-based sync design rationale: `specs/003-sync-template-merge/`,
  `reports/2026-06-26-sync-merge-redesign-options.md`.
- v0.1.4 cockpit profile: `specs/004-cockpit-profile/`.
- v0.1.5 documentation; v0.1.6–v0.3.0: see `CHANGELOG.md` and `HANDOFF.md` (2026-07-02 entry).
