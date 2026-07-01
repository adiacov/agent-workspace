# STATE.md

Single canonical current-context entrypoint for this repository.

## Current status

`v0.1.3` is the last released tag (merge-based sync). Feature `004-cockpit-profile` is
IMPLEMENTED on branch `004-cockpit-profile` (VERSION bumped to `v0.1.4`, not yet committed/
merged/tagged). Full suite green: smoke + 4 unit + 48 integration pass, zero repo pollution.
Uncommitted — pending commit + merge to `main` + tag `v0.1.4`.

## Active work

`cockpit` profile — a third `agent-ws init` profile alongside `general`/`code`, scaffolding a
control-room over many project repos. IMPLEMENTED on branch `004-cockpit-profile`; spec-kit
artifacts under `specs/004-cockpit-profile/`.

What shipped: new `cockpit` profile generates `PROJECTS.md`, `PROFILE.md`, `WORKFLOWS-COCKPIT.md`
(control-room workflows) plus a cross-cutting `STATE.md` variant, on top of the `general` core.
Mechanism gaps closed in `lib/agent-ws/templates.sh`: `agent_ws_default_template_files` is now
profile-aware (cockpit swaps the `STATE.md` *source*, destination/kind unchanged — the override);
`agent_ws_profile_template_files` gained a `cockpit)` branch (the augmentation). `WORKFLOWS.md`
base template is untouched (companion-file approach). `context` kinds for PROJECTS/PROFILE/STATE
(never synced); `WORKFLOWS-COCKPIT.md` is a `profile`/framework file (synced like ENGINEERING.md).
Wired through commands.sh (prompt/validation/help/example), migrate.sh, and audit (no edit needed).
Templates live in `templates/profiles/cockpit/`. Docs: README top-of-file use-case visuals +
cockpit walkthrough + optional `checkpoint` note; `SPEC.md` rewritten to the current global-CLI
model. Open questions resolved: strategy file = `PROFILE.md`; augmentation = companion file;
cockpit = standalone (no stacking).

Next: commit branch, merge to `main`, tag `v0.1.4` (CI auto-releases).

## History — merge-based sync (shipped in v0.1.3)

Spec-kit artifacts under `specs/003-sync-template-merge/`; design rationale in
`reports/2026-06-26-sync-merge-redesign-options.md`.

What shipped: `sync` now merges published template changes into a project's framework files via
a per-project gitignored baseline (`.agent-workspace/baseline/`) three-way merge (`git
merge-file`). Clean additions apply preserving local edits; overlapping edits are refused (live
file untouched, `*.merge` side-file, non-zero exit) — the tool never resolves conflicts itself.
Content files (`STATE.md`/`PROJECT.md`) are never synced (classified by `kind`). Baseline-less
projects are seeded on first sync (and their `.gitignore` is ensured). `diff` repurposed to show
the incoming baseline→template delta, colorized (NO_COLOR/non-TTY aware). New modules:
`lib/agent-ws/baseline.sh`, `lib/agent-ws/merge.sh`.

Adoption: the sibling `checkpoint` project already adopted v0.1.3 via `agent-ws sync --apply`
(pulled the Handoff section into its `WORKFLOWS.md`, added sync/HANDOFF exclusions to
`.gitignore`, committed + pushed). Other sibling projects can adopt the same way.

### Original problem the redesign solved (their words, captured)

1. **`sync` should propagate template changes into a project.** When a template file changes in
   the agent-workspace repo (e.g. a new section added to `WORKFLOWS.md`) and is published,
   running `agent-ws sync` from *within a bootstrapped project* should **merge those new template
   changes into that project's active files** (e.g. update the project's `WORKFLOWS.md`).
   Today `sync` does none of this — it only reads metadata/template-source status and reports
   "active files unchanged"; it never touches active files. See `lib/agent-ws/sync.sh`.

2. **`diff` as it stands is not useful to the user.** Showing raw differences between global
   templates and a project's files is "obvious" noise, because a project evolves independently
   from the templates. (`lib/agent-ws/diff.sh` runs `diff -u template active` per mapped file.)

3. **But `diff` may be worth keeping as an input to the new `sync`** (complementary): the
   template-vs-active comparison could feed the merge engine. Decide during design whether to keep,
   repurpose, or fold `diff` into `sync`.

### Core design problem to solve (do not lose this)

Active files contain **local project edits**. Any "pull template changes" mechanism must **merge**
(append/insert template-only additions, detect conflicts) and must NOT blindly overwrite, or it
destroys the user's local content. This is the hard part. The current ownership invariant
("agent-ws owns templates; the project owns active files; sync never overwrites active files") is
exactly what the user now wants to relax — so the rethink touches the tool's core model, not just
one function.

## Next action (for the next session)

- Commit branch `004-cockpit-profile`, merge to `main`, tag `v0.1.4` (CI auto-releases).
- The section below is `v0.1.3` history, retained for context only.
- Optional: adopt `v0.1.3` merge-based sync in remaining sibling projects via `agent-ws sync --apply`.

## Relevant deeper docs

Read only when needed for the current task:

- `lib/agent-ws/sync.sh`, `lib/agent-ws/diff.sh`, `lib/agent-ws/templates.sh` — the code to rethink.
- `lib/agent-ws/metadata.sh` — `generatedFiles` mappings the merge would iterate over.
- `README.md` sections "Synchronization for existing global projects" and "Metadata and ownership"
  — the ownership invariant that this redesign challenges.
- `PROJECT.md` for stable project identity and boundaries.

## Blockers

- None.
