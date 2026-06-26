# STATE.md

Single canonical current-context entrypoint for this repository.

## Current status

`v0.1.2` is the last released tag (Handoff producer contract). Merge-based sync is implemented
on branch `003-sync-template-merge` (VERSION bumped to `v0.1.3`, not yet tagged/merged). Full
suite green: smoke + 3 unit + 46 integration tests pass, zero repo pollution. Uncommitted —
pending review/commit/merge.

## Active work

Merge-based `sync` redesign — IMPLEMENTED on branch `003-sync-template-merge`, awaiting
commit + merge to `main` + release tag `v0.1.3`. Spec-kit artifacts live under
`specs/003-sync-template-merge/`; design rationale in `reports/2026-06-26-sync-merge-redesign-options.md`.

What shipped: `sync` now merges published template changes into a project's framework files via
a per-project gitignored baseline (`.agent-workspace/baseline/`) three-way merge (`git
merge-file`). Clean additions apply preserving local edits; overlapping edits are refused (live
file untouched, `*.merge` side-file, non-zero exit) — the tool never resolves conflicts itself.
Content files (`STATE.md`/`PROJECT.md`) are never synced (classified by `kind`). Baseline-less
projects are seeded on first sync (and their `.gitignore` is ensured). `diff` repurposed to show
the incoming baseline→template delta, colorized (NO_COLOR/non-TTY aware). New modules:
`lib/agent-ws/baseline.sh`, `lib/agent-ws/merge.sh`.

Next: commit branch, merge to `main`, tag `v0.1.3` (CI auto-releases). Then optionally adopt in
sibling projects via `agent-ws sync`.

### What the user wants changed (their words, captured)

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

- Treat this as a redesign of the tool's update/merge model, not a one-line `sync` patch.
- Decide the merge strategy: section-aware append/insert of template-only blocks vs. 3-way merge
  vs. patch-with-conflict-markers. Define what counts as a "template-only addition" vs a "conflict".
- Decide the fate of `diff` (keep as merge input / repurpose / remove) and whether `sync` stays
  conservative with a NEW command added, or `sync` itself gains an `--apply`-that-merges behavior.
- Only after the design is agreed: implement, add tests, version bump + changelog.

## Relevant deeper docs

Read only when needed for the current task:

- `lib/agent-ws/sync.sh`, `lib/agent-ws/diff.sh`, `lib/agent-ws/templates.sh` — the code to rethink.
- `lib/agent-ws/metadata.sh` — `generatedFiles` mappings the merge would iterate over.
- `README.md` sections "Synchronization for existing global projects" and "Metadata and ownership"
  — the ownership invariant that this redesign challenges.
- `PROJECT.md` for stable project identity and boundaries.

## Blockers

- None. Work is intentionally paused; resume in the next session.
