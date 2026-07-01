# Research: `cockpit` profile

## R1 — Augmenting an existing base file (`WORKFLOWS.md`)

**Question**: Cockpit needs control-room workflow content *in* `WORKFLOWS.md`, but the current
profile mechanism only *adds* new files; it does not mutate a base file.

**Options considered**:
- (a) Ship a separate `WORKFLOWS-COCKPIT.md` companion that the base `WORKFLOWS.md` references.
- (b) Have `cockpit` provide a fuller `WORKFLOWS.md` that supersedes the default for this profile.
- (c) Template-compose base + profile fragments at generate time.

**Decision**: (a). Least invasive; the shared base template stays byte-for-byte identical, so
`general`/`code` are provably unchanged (FR-004, FR-010). No new compose step in the generator.

**Refinement**: The source brief's phrasing of (a) has the *base* `WORKFLOWS.md` reference the
companion — but that would mutate the shared template. Instead, discovery is via the cockpit
`STATE.md` (which a cockpit reads first at session start) pointing to `WORKFLOWS-COCKPIT.md` as
authoritative for coordination. Same outcome, zero base mutation.

**Rejected**: (b) duplicates the entire base into the profile, creating a second file to keep in
sync on every base change — high drift risk. (c) adds generate-time composition machinery the tool
does not otherwise need; premature. Revisit (c) only if companion files proliferate.

## R2 — Overriding a base file (`STATE.md`)

**Question**: The cockpit `STATE.md` plays a different role (cross-cutting index) than the default
single-project `STATE.md`. `init` generates default files before profile files, and the safe-copy
helper skips an existing destination — so a profile file cannot override a default one by
destination.

**Decision**: Make `agent_ws_default_template_files` profile-aware. For `cockpit`, the `STATE.md`
row's *source* becomes `profiles/cockpit/STATE.md`; the *destination* (`STATE.md`) and *kind*
(`context`) are unchanged. Generation copies the cockpit variant; audit (which calls the generator
without a profile) still sees destination `STATE.md`, so no audit change is needed.

**Why not a separate cross-cutting file** (e.g. `COCKPIT.md`): a cockpit's canonical
current-context entrypoint should still be `STATE.md` so the shared "read STATE.md first"
workflow applies unchanged. Overriding the source keeps one entrypoint and keeps `context`
ownership semantics (seeded once, never synced).

## R3 — Standalone vs. stacked profile

**Question**: Should `cockpit` imply/allow a base profile underneath (`cockpit`+`code`)?

**Decision**: Standalone for iteration one. A cockpit coordinates *separate* project repos; the
technical among those repos are their own `code` projects. Stacking would require a profile
grammar (`--profile cockpit,code`) and file-set union logic that nothing yet needs. YAGNI.

## R4 — File kinds and sync behavior

`PROJECTS.md`, `PROFILE.md`, and cockpit `STATE.md` are **`context`**: user-owned content the tool
seeds once and never syncs or reads (matches `PROJECT.md`/`STATE.md` today). `WORKFLOWS-COCKPIT.md`
is a **`profile`** framework file: `sync` reconciles it via the baseline three-way merge exactly
like `ENGINEERING.md`, so template improvements to the control-room workflows flow into adopted
cockpits while local edits are preserved. This reuses the 003 machinery with no new sync code.

## R5 — Migration

Legacy projects predate cockpit and will not contain these files, but `migrate` maps known files
to template kinds defensively. Add `PROJECTS.md`/`PROFILE.md` (`context`) and
`WORKFLOWS-COCKPIT.md` (`profile`) to the preserved-files list and record mapping so a
hand-assembled cockpit is not dropped. `migrate` still records `profile: general` (it cannot infer
`cockpit`); that is acceptable and unchanged in scope.

## R6 — Complementary tool `checkpoint`

Documentation only. A short "Complementary tools" note near the human+agent collaboration model,
linking `https://github.com/adiacov/checkpoint`, explicitly optional and independent. No behavior
is wired into `agent-ws` or any profile (Non-goals).
