# Feature Specification: Sync merges template changes into projects

**Feature Branch**: `003-sync-template-merge`

**Created**: 2026-06-26

**Status**: Draft

**Input**: User description: "Sync merges published template changes into a bootstrapped project's active files using a per-project baseline three-way merge, with agent-assisted conflict handling, backups, and baseline seeding for existing projects"

## Clarifications

### Session 2026-06-26

- Q: Where is the per-project baseline stored relative to git? → A: Gitignored — a local-only
  working artifact, not committed. A fresh clone has no baseline and re-seeds on first sync.
- Q: On a real conflict with no assisting agent, what does sync produce besides refusing to
  touch the live file? → A: Write a `*.merge` side-file containing the reconciliation result
  with conflict markers, name it, and exit non-zero; the live file stays untouched.
- Q: Should sync ever touch project-owned content files (current-state, project-identity)? →
  A: No — sync only reconciles framework files (workflow/profile/adapter); content files are
  seeded once and never synced.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pull a new template section into a project (Priority: P1)

A developer maintains the agent-workspace templates. They add a new section to a template
file (for example a new `## Handoff` section in `WORKFLOWS.md`) and publish it. In a
separate project that was bootstrapped with agent-ws — and whose copy of that file already
carries local edits — they run the sync command. The new section appears in the project's
file, and every local edit the project had made is still intact.

**Why this priority**: This is the core unmet need. Today sync reports "active files
unchanged" and never propagates template improvements, so projects silently fall behind.
Solving just this delivers the primary value.

**Independent Test**: Bootstrap a project, locally edit its `WORKFLOWS.md`, add a new
section to the source template, run sync, and confirm the new section is present and the
local edits are unchanged.

**Acceptance Scenarios**:

1. **Given** a project whose `WORKFLOWS.md` has local edits and a template that gained a
   new section since the project last synced, **When** the developer applies sync, **Then**
   the new section is inserted into the project file and all prior local edits remain.
2. **Given** a project whose file is already identical to the latest template, **When** the
   developer runs sync, **Then** no change is made and the result reports nothing to update.
3. **Given** a project that is behind on several framework files, **When** the developer
   previews sync, **Then** the preview lists exactly which files would change and what would
   be added, without modifying any file.

---

### User Story 2 - Conflicting changes never corrupt a file (Priority: P1)

A template changes the wording of a line that the project also edited locally. The two
changes overlap. When the developer syncs, the tool must never leave the project file in a
broken or half-merged state. On an overlapping change the tool stops and reports the conflict,
leaving the original file untouched and writing a `*.merge` side-file; an agent (or the user)
can resolve that side-file afterward as a separate step.

**Why this priority**: The explicit risk the user named is "this may break the instruction
files in a separate project." Safety on conflict is as important as the merge itself; an
unsafe merge is worse than no merge.

**Independent Test**: Create an overlapping change in both template and project, run sync, and
confirm the project file is byte-identical to before, a `*.merge` side-file is written, and the
command reports the conflict and exits with a non-zero status.

**Acceptance Scenarios**:

1. **Given** an overlapping change, **When** the developer applies sync, **Then** the project
   file is left unchanged, a `*.merge` side-file with markers is written, the conflicted file is
   named in the output, and the command exits non-zero.
2. **Given** a `*.merge` side-file from a refused conflict, **When** an agent or the user
   resolves it and writes the result back to the live file, **Then** the live file contains no
   conflict markers (resolution is a separate step from sync).
3. **Given** any applied sync, **When** it finishes, **Then** no project file contains
   unresolved conflict markers.
4. **Given** a sync that writes a file, **When** the write begins, **Then** a backup of the
   original exists until the write succeeds, and the backup is removed only after success;
   if the write fails, the original is restored.

---

### User Story 3 - Existing project with no baseline can start syncing (Priority: P2)

A project was bootstrapped before this feature existed, so it has no record of which
template version it came from. The developer runs sync there for the first time. Sync does
not fail and does not guess destructively: it brings in safe additions and establishes the
baseline so that future syncs can do full reconciliation.

**Why this priority**: Without this, the feature only works for projects created after it
ships. Most real projects (including the user's sibling project) predate it.

**Independent Test**: Take a project with metadata but no baseline, run sync, confirm safe
additions are applied, a baseline is recorded, and a second sync now behaves like User
Story 1.

**Acceptance Scenarios**:

1. **Given** a project with workspace metadata but no recorded baseline, **When** the
   developer applies sync, **Then** sync establishes a baseline and reports that it did so.
2. **Given** that same project after its baseline is established, **When** a template later
   changes and the developer syncs again, **Then** reconciliation behaves as in User Story 1.

---

### User Story 4 - Preview the incoming change, ignore project-owned content (Priority: P3)

Before applying anything, the developer wants to see only what would actually come in from
the templates — not noise. The preview shows the incoming template delta, not an arbitrary
comparison between unrelated current files. Project-owned content files (current-state and
project-identity files) are never targeted by sync.

**Why this priority**: The user found the old comparison output unusable ("obviously changes
will be present"). A focused preview is what makes sync trustworthy, but it is a refinement
on top of the core merge.

**Independent Test**: Run the preview against a project and confirm it reports the incoming
template additions for framework files only, and never lists the current-state or
project-identity files.

**Acceptance Scenarios**:

1. **Given** a project, **When** the developer previews sync, **Then** the output describes
   the incoming template changes that would be applied, scoped to framework files.
2. **Given** a project whose current-state or project-identity file differs from its template
   seed, **When** the developer runs sync, **Then** those files are never modified or flagged
   for update.

---

### Edge Cases

- A project file the user fully rewrote and a template that changed elsewhere: non-overlapping
  template additions still come in; overlapping regions are treated as conflicts (US2).
- A project file was deleted by the user: sync reports it as missing and does not recreate it
  silently.
- The template no longer contains a file the project was generated from: sync reports it and
  makes no change.
- A non-Markdown framework file (an agent adapter file): handled by the same reconcile-or-
  refuse rule, never by blind overwrite.
- Sync interrupted partway through multiple files: each file is all-or-nothing; already-written
  files keep their backups until the whole run is known to have succeeded.
- Preview and apply run from inside the project directory or with an explicit project path:
  both resolve to the same project.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Running sync from within (or against) a bootstrapped project MUST bring
  published template changes into that project's framework files.
- **FR-002**: Sync MUST preserve the project's local edits; it MUST NOT blindly overwrite a
  project file with template content.
- **FR-003**: Sync MUST reconcile changes against the template version the project last
  synced from (its baseline), so that template-only additions apply cleanly and only genuinely
  overlapping changes are treated as conflicts.
- **FR-004**: On a conflict, sync MUST leave the affected live file unchanged, write a `*.merge`
  side-file holding the reconciliation result with conflict markers, name the conflicted file in
  the output, and exit with a non-zero status. Sync itself does NOT resolve conflicts; resolving
  a `*.merge` file (by an agent or the user) is a separate, later step.
- **FR-005**: A completed apply MUST NOT leave any project file containing unresolved conflict
  markers.
- **FR-006**: Before modifying any project file, sync MUST create a backup, and MUST remove
  that backup only after the modification succeeds; on failure it MUST restore the original.
- **FR-007**: Each file's update MUST be all-or-nothing (no partially written file is left in
  place).
- **FR-008**: Sync MUST only target framework files (workflow, profile, and agent-adapter
  files); it MUST NOT modify project-owned content files (current-state and project-identity
  files).
- **FR-009**: For a project that has no recorded baseline, sync MUST establish one, applying
  only safe additions on that first run, and MUST report that it did so.
- **FR-010**: After a successful apply, sync MUST update the project's baseline to the template
  version just applied, so the next sync reconciles from the new point.
- **FR-017**: When sync establishes a baseline in an existing project (FR-009), it MUST ensure
  that project's `.gitignore` excludes the baseline directory and the transient `*.bak`/`*.merge`
  artifacts, so seeding never causes them to be committed.
- **FR-011**: Sync MUST provide a preview mode that reports what would change without modifying
  any file, and an apply mode that performs the changes.
- **FR-012**: The preview MUST describe the incoming template delta for the targeted files,
  not an unscoped comparison of unrelated current files.
- **FR-013**: Sync MUST report a clear per-file outcome: unchanged, updated, seeded-baseline,
  conflicted (refused), or missing.
- **FR-014**: The existing comparison command MUST be repurposed or retained only insofar as it
  serves the incoming-delta preview; its output MUST be readable when a project has many
  differences (legible add/remove distinction).
- **FR-015**: Running sync MUST NOT require network access or a template git history; it MUST
  work from the locally available templates and the project's stored baseline.
- **FR-016**: The per-project baseline and transient backups/side-files MUST be excluded from
  the project's version control (gitignored), and bootstrapping a project MUST ensure that
  exclusion exists.

### Key Entities *(include if feature involves data)*

- **Active file**: a project-owned file generated from a template; may carry local edits.
- **Template file (current)**: the latest published template content available locally.
- **Baseline**: the per-project stored copy of the template content the project last synced
  from; the reconciliation reference point.
- **Framework file vs content file**: framework files (workflow/profile/adapter) are sync
  targets; content files (current-state/project-identity) are seeded once and never synced.
- **Per-file outcome**: the classification reported for each file after a sync run.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After a template gains a new section, a single apply brings that section into a
  locally edited project file with 100% of the project's prior local edits preserved.
- **SC-002**: Across all sync runs, the number of project files left containing conflict
  markers is zero.
- **SC-003**: Every applied file modification has a backup that exists during the write and is
  absent after a successful run; after any failed run the original content is fully recovered.
- **SC-004**: An existing project with no baseline becomes sync-capable in one run, and its
  next sync reconciles a new template change without manual setup.
- **SC-005**: Project-owned content files are modified in zero sync runs.
- **SC-006**: Preview output for a project with many divergences is readable enough that a
  user can identify the incoming additions without reading raw unscoped diffs.
- **SC-007**: All sync behavior is reproducible offline (no network, no template git history).

## Assumptions

- The reconciliation reference (baseline) is stored per project but gitignored (local-only
  working artifact), because each project tracks a different sync point and a single
  shared/global copy cannot represent all projects' states. A fresh clone has no baseline and
  re-seeds on its first sync (User Story 3).
- The merge behavior is added to the existing sync command (preview/apply); a separate new
  command is not introduced unless it proves necessary.
- "Conflict" means overlapping edits in the same region of base, template, and project; pure
  template-only additions are not conflicts.
- Framework vs content classification is derived from the file role already recorded in the
  project's workspace metadata.
- Conflict resolution is out of the tool's scope: sync is deterministic and always takes the
  refuse-and-report path on conflict; an agent or user resolves the resulting `*.merge` file as a
  separate step.
- Backups and baselines are local working artifacts; backups are transient (removed on success)
  while baselines persist.
