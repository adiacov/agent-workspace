# Changelog

## v0.3.0 - 2026-07-02

Fleet-awareness release: the tool now remembers your projects and can fix them with one command.

### Added

- **Project registry**: projects register themselves globally (one absolute path per line in `${XDG_DATA_HOME:-~/.local/share}/agent-ws/projects`) whenever a command touches them and finds valid metadata (`init`, `migrate --apply`, `status`, `audit`, `sync`, `heal`). The registry stores paths only, never project meaning; `discover` never writes it.
- **`agent-ws projects`**: lists every registered project with a one-word state (`in-sync`, `outdated`, `incomplete`, `legacy`, `unmanaged`, …) and the recommended fix. Entries whose directory no longer exists are pruned on listing.
- **`agent-ws heal [path]`**: brings a project to a healthy state with one preview-first command, composing the existing steps in order — adopt if legacy/unmanaged (migrate), recreate missing files from templates (existing files are never overwritten), then sync (seed baselines / merge template changes). Defaults to `--dry-run` showing the plan. It never guesses: uninitialized directories, unreadable metadata, and merge conflicts are reported with instructions instead of auto-resolved.

### Fixed

- `agent-ws discover` reports project roots instead of every matching directory: once a directory matches, its subtree is pruned, and the tool's own artifact dirs (`.agent-workspace/`, `.agent/`) are skipped — so template caches, baselines, and build output no longer appear as separate matches.

## v0.2.0 - 2026-07-02

Output usability release: every command now explains itself and tells you what to run next.

### Added

- Commands that inspect or change project state (`status`, `audit`, `diff`, `sync`, `migrate`, `update`, `discover`, `init`, `add-agent`) end with a **Next steps** block recommending the concrete command for the detected situation — adopt hand-made projects with `migrate --dry-run`, seed or merge with `sync --apply`, review incoming changes with `diff`, install with `update` — or an **All good** line when the project is healthy.
- `status` and `audit` gain a read-only sync-readiness check: they detect when baselines are unseeded or behind the installed templates and recommend the fix.
- `update --dry-run` reports "already up to date" when the installed version is the latest, instead of offering to reinstall it.
- `status` shows the project's profile and agents; `discover` prints an explicit "no projects found" message instead of empty output.

### Changed

- Output is grouped into titled sections (Workspace / Files / Legacy / Actions / Summary / Next steps) with indented detail lines, and every state token is followed by a plain-language explanation (e.g. `metadata: missing — agent-ws does not manage this directory yet`, `WORKFLOWS.md: updated — template changes merged; your local edits were kept`).
- `sync` and `migrate` say up front when a run is a preview: `Sync preview: <path> (dry-run; nothing will be modified)`.
- State tokens (`metadata: present`, `WORKFLOWS.md: seeded`, `preserve: X`, …) are kept verbatim inside the richer lines, so scripts that grep for them keep working. Scripts matching the old header lines (`sync: dry-run`, `migration: apply`) must switch to the new headers (`Sync preview:`, `Migration:`).

## v0.1.7 - 2026-07-02

Bugfix release.

### Fixed

- `agent-ws migrate` now infers the project profile from the files it preserves instead of always recording `general`: `PROJECTS.md`/`WORKFLOWS-COCKPIT.md` → `cockpit`, `ENGINEERING.md` → `code`, otherwise `general` (cockpit signals win when both are present). `migrate --dry-run` reports the detected profile in its preview line.

### Added

- Integration test (`tests/integration/test_migrate_detects_profile.sh`) covering all three detection cases and the dry-run preview.

## v0.1.6 - 2026-07-02

Bugfix release.

### Fixed

- `agent-ws init <path>` now honors the parent-git-repo guard exactly like `agent-ws init` in the current directory; previously a named path silently initialized a nested project inside an existing repository.
- `agent-ws init` validates the agent list (and the custom adapter path) before writing any files, so an unsupported `--agents` value can no longer leave a half-initialized project (core files without `workspace.json`).
- `agent-ws sync` no longer misreads a Markdown setext heading underline (`=======`) in cleanly merged content as a conflict; conflict detection now requires labeled `<<<<<<< `/`>>>>>>> ` markers.
- `agent-ws sync --apply` restores the `.bak` backups and removes the in-flight merge temp file if a run aborts partway, instead of leaving files partially updated. When a run ends with conflicts, the `.bak` files of successfully updated files are kept as a restore point (they are gitignored), matching the documented "removed on success" behavior.
- `agent-ws update` without `--version` now resolves the latest stable release from the repository's real tags (via `git ls-remote`) and picks the semver maximum; previously it only consulted a test-only variable and always failed.
- `agent-ws update` validates the staged candidate's version as a whole word, so expected `v0.1.1` no longer accepts a candidate reporting `v0.1.10`.
- `--custom-path` rejects `:`, `|`, and whitespace, which would have corrupted internal template-spec and metadata records.
- Internal: `agent_ws_abs_path` no longer creates directories as a side effect; `agent_ws_can_prompt` detects a detached stdin (no TTY, closed stdin) instead of always reporting that prompting is possible.

### Added

- Integration regression test (`tests/integration/test_bugfix_regressions.sh`) covering the init guard, no-partial-init, setext-underline merge, and semver-max release selection.

## v0.1.5 - 2026-07-01

Documentation release.

### Changed

- `README.md`: lead with the problem and value (amnesiac agents, per-tool instruction files, drifting context) instead of a mechanism-first opening, and move "What you can build" below the Contents list.
- `README.md`: clarify profile positioning — `general` for any generic (non-code) project (notes, research, planning, writing, a business or idea), `code` for software projects, `cockpit` for coordinating many projects; drop the backwards "general is code without the engineering guidance" framing.
- `README.md`: keep the optional `checkpoint` tool mentioned only in "Complementary tools"; remove the `sessions/pending/` recovery-checkpoint bullet from the Context model.

## v0.1.4 - 2026-07-01

Cockpit profile release.

### Added

- New `cockpit` profile for `agent-ws init`, alongside `general` and `code`. Where `code` builds one project, `cockpit` scaffolds a control-room over many separate project repos: `PROJECTS.md` (project index), `PROFILE.md` (strategy/context), `WORKFLOWS-COCKPIT.md` (control-room workflows — cross-project one-way-dependency rule, explore→build→reflect loop, optional handoff-ingest ritual), and a cross-cutting `STATE.md` variant. All files ship as neutral, user-owned placeholder scaffolding; the tool never reads or maintains their content.
- `cockpit` file kinds: `PROJECTS.md`/`PROFILE.md`/`STATE.md` are `context` (seeded once, never synced); `WORKFLOWS-COCKPIT.md` is a framework file reconciled by `sync` like `ENGINEERING.md`.

### Changed

- Profile selection (flag, interactive prompt, `--no-prompt` validation, help/usage, examples, and error hints) now accepts and documents `cockpit`; invalid-profile errors list all three profiles.
- `agent-ws migrate` recognizes `PROJECTS.md`, `PROFILE.md`, and `WORKFLOWS-COCKPIT.md` as preserved, template-mapped files.
- `README.md`: added a top-of-file "What you can build" visual (one-project vs. cockpit shapes) with a one-line choosing rule, a full `cockpit` profile walkthrough under "Advanced options", and an optional, independent `checkpoint` "Complementary tools" note.
- `SPEC.md`: rewritten to describe the current global-CLI model and three profiles, removing the obsolete project-local (`.agent/templates/`, `bin/agent-workspace`, `bootstrap.sh`) draft.

### Unchanged

- `general` and `code` init output and metadata are identical to the prior release; the base `WORKFLOWS.md` template is untouched.

## v0.1.3 - 2026-06-26

Merge-based sync release.

### Added

- `agent-ws sync` now merges published template changes into a project's framework files using a per-project baseline three-way merge: template-only additions apply cleanly while local edits are preserved. Overlapping edits are refused — the live file is left untouched, a `*.merge` side-file with conflict markers is written, and the run exits non-zero. Content files (`STATE.md`, `PROJECT.md`) are never synced.
- Per-project baseline snapshots under `.agent-workspace/baseline/` (the template version a project last synced from), written by `init` and refreshed after each successful sync. Baselines are gitignored local working artifacts; a project with no baseline is seeded on first sync (which also ensures the project `.gitignore` excludes the baseline and transient `*.bak`/`*.merge` files).
- Backups are taken before each write and removed on success; a failed write restores the original.

### Changed

- `agent-ws diff` now shows the incoming template delta (baseline → current template) for framework files only, colorized on a TTY and plain under `NO_COLOR`, instead of an unscoped active-vs-template comparison.
- Updated `README.md` ownership/synchronization sections and command help to describe the merge model.

## v0.1.2 - 2026-06-25

Handoff producer contract release.

### Added

- Added a `## Handoff` producer contract to the default `WORKFLOWS.md`: an agent writes/updates a transient `HANDOFF.md` outbox only when the user explicitly asks for a handoff/digest, appending one delta entry per session without overwriting un-drained entries.
- Gitignored `HANDOFF.md` in the default template as transient transport, mirroring how `MEMORY.md` is handled (agent-created on demand, not generated by `init`).

## v0.1.1 - 2026-06-16

Template context-efficiency release.

### Changed

- Updated default workflow guidance to classify requests before loading broad project context.
- Kept pending checkpoint recovery automatic while making it bounded to durable state extraction.
- Reduced default memory, repository, and historical task-artifact loading to only when relevant.
- Updated adapter templates to load only context required by `WORKFLOWS.md`.
- Clarified `STATE.md` as active-work context with cleanup guidance for completed-work pointers.
- Added a tag-based GitHub Actions release workflow that validates `VERSION`, changelog notes, smoke tests, and integration tests before creating a GitHub release.

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
