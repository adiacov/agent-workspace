# STATE.md

Single canonical current-context entrypoint for this repository.

## Current status

`v0.3.0` is the latest released tag (fleet awareness: project registry, `projects`, `heal`),
released 2026-07-02 on `main`. Five releases shipped that day: `v0.1.6` (bug-hunt hardening),
`v0.1.7` (migrate profile detection), `v0.2.0` (readable output + next-step advice), `v0.3.0`.
Suite green: smoke + 4 unit + 52 integration. The repo is self-managed by its own tool
(`.agent-workspace/workspace.json`, profile `code`) and registered in the global registry.

Known cosmetic issue: the CI Release workflow failed for v0.1.6→v0.3.0 because the GitHub
releases were created manually with `gh` before CI ran ("tag_name already exists"). The releases
themselves are correct. From now on: push the tag only and let CI publish.

## Current model (what the tool is now)

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
2026-07-02 (seeded, completed, or migrated; one commit each, pushed) and are in-sync and
registered. Excluded on purpose per the user: `adiacov.github.io` (deliberately unmanaged),
`docpilot` (not using agent-ws).

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

## History

- v0.1.3 merge-based sync design rationale: `specs/003-sync-template-merge/`,
  `reports/2026-06-26-sync-merge-redesign-options.md`.
- v0.1.4 cockpit profile: `specs/004-cockpit-profile/`.
- v0.1.5 documentation; v0.1.6–v0.3.0: see `CHANGELOG.md` and `HANDOFF.md` (2026-07-02 entry).
