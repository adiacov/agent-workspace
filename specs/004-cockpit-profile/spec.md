# Feature Specification: `cockpit` profile

**Feature Branch**: `004-cockpit-profile`

**Created**: 2026-07-01

**Status**: Draft

**Input**: User description: "Add a third profile, `cockpit`, alongside `general` and `code`. `cockpit` scaffolds a control-room over many projects: one workspace that indexes, connects, and steers several separate project repos over time, and preserves continuity across time and across agents. Ship mechanisms with neutral example content; augment `WORKFLOWS.md` and override `STATE.md` for this profile; keep `general`/`code` unchanged; clean up and extend the docs; mention the complementary `checkpoint` tool; add top-of-README use-case visuals."

## Clarifications

### Session 2026-07-01

- Q: What is the strategy/personal file named? → A: `PROFILE.md` — generic enough for a
  business owner, job-seeker, or student; ships with obviously-placeholder neutral content.
- Q: How is `WORKFLOWS.md` augmented with control-room workflows without mutating the shared
  base template? → A: Option (a). Ship a separate companion file `WORKFLOWS-COCKPIT.md` that
  the cockpit `STATE.md` points to as authoritative for coordination. The base
  `WORKFLOWS.md` template is byte-for-byte unchanged, so `general`/`code` are untouched.
- Q: Does `cockpit` stack on top of a base profile (e.g. `cockpit`+`code`)? → A: No. For the
  first iteration `cockpit` is a standalone profile (= `general` core + a coordination layer).
  A technical user still creates `code` projects *underneath* the cockpit as separate repos.
- Q: Does the tool learn or maintain any per-project meaning/registry? → A: No. `cockpit`
  ships empty, user-owned scaffolding exactly like `code` ships `ENGINEERING.md`. `PROJECTS.md`
  and `PROFILE.md` are project-owned content files the tool seeds once and never reads.
- Q: What role does cockpit `STATE.md` play? → A: A cross-cutting index (current focus,
  current question, coarse per-project status pointing at each repo's own `STATE.md`), not a
  single project's active state. `cockpit` overrides the default `STATE.md` template source;
  it stays a `context` (seeded-once, never-synced) file.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Scaffold a control-room over many projects (Priority: P1)

A person steering several separate efforts — a business owner with a few product repos, a
job-seeker running applications-plus-portfolio, a student juggling courses and a side project —
wants one workspace to coordinate all of them without copying per-project detail into it. They
run `agent-ws init --profile cockpit`. The result is a coordination workspace: an index of the
projects it steers, a strategy/context file, a cross-cutting current-focus state, and
control-room workflows — all as neutral, obviously-placeholder scaffolding they then fill in.

**Why this priority**: This is the core new capability. Without it there is no third profile
and no control-room shape. Delivering just this — a fresh cockpit project with the full,
correct file set — is a viable MVP.

**Independent Test**: Run `agent-ws init --profile cockpit --agents <x> --no-prompt` in an
empty directory and confirm it creates `PROJECTS.md`, `PROFILE.md`, a cockpit `STATE.md`,
`WORKFLOWS.md`, `WORKFLOWS-COCKPIT.md`, and the selected agent adapter, with metadata recording
`profile: cockpit`.

**Acceptance Scenarios**:

1. **Given** an empty target directory, **When** the user runs `agent-ws init --profile cockpit
   --agents pi --no-prompt`, **Then** the project contains `PROJECTS.md`, `PROFILE.md`,
   `STATE.md` (cockpit variant), `WORKFLOWS.md`, `WORKFLOWS-COCKPIT.md`, and `AGENTS.md`.
2. **Given** a fresh cockpit project, **When** the user runs `agent-ws audit`, **Then** the
   audit reports every expected cockpit file present and no partial state.
3. **Given** a fresh cockpit project, **When** the user inspects `.agent-workspace/workspace.json`,
   **Then** `profile` is `cockpit` and every generated file is recorded.

---

### User Story 2 - Coordinate without coupling (Priority: P2)

The cockpit indexes sibling project repos and reasons about them, but each sibling repo must
still stand on its own and must never depend on the cockpit. The user reads `WORKFLOWS-COCKPIT.md`
and understands the one-way dependency rule (cockpit → projects, never the reverse), the
explore→build→reflect loop (explore in the cockpit, build in a separate project repo, return to
reflect), and the optional handoff-ingest ritual.

**Why this priority**: The coordination rules are what make a cockpit different from a folder of
links. They prevent the failure mode where sibling repos silently grow a dependency on the
operator's private workspace.

**Independent Test**: Open a fresh cockpit's `WORKFLOWS-COCKPIT.md` and confirm it documents the
cross-project one-way-dependency rule, the explore→build→reflect loop, and the handoff-ingest
ritual, and that cockpit `STATE.md` points to it as authoritative for coordination.

**Acceptance Scenarios**:

1. **Given** a fresh cockpit project, **When** the user opens `WORKFLOWS-COCKPIT.md`, **Then**
   it contains the cross-project rule, the explore→build→reflect loop, and the handoff-ingest
   ritual as distinct sections.
2. **Given** a fresh cockpit project, **When** the user opens `STATE.md`, **Then** it names
   itself a cross-cutting cockpit index and points to `WORKFLOWS-COCKPIT.md` and `PROJECTS.md`.

---

### User Story 3 - Existing profiles and newcomers unaffected/served (Priority: P2)

Existing `general` and `code` users see no behavioral change. A newcomer opening the README sees,
on the first screen, two simple visual shapes — "one project" vs. "a cockpit coordinating several
projects" — and a one-line rule for choosing between `code` and `cockpit`, so they can decide
"is this for me?" before the concept-heavy sections. Every place that lists profiles now includes
`cockpit`, and the README points to the optional, independent `checkpoint` companion tool.

**Why this priority**: A more capable third profile makes the bare command README harder to grok;
the docs must onboard newcomers and stay internally consistent, or adoption suffers.

**Independent Test**: Run `agent-ws init --profile general` and `--profile code` and confirm
byte-identical output to before; grep the README/help for profile enumerations and confirm all
list `cockpit`; confirm the README shows the two use-case shapes near the top and a `checkpoint`
mention.

**Acceptance Scenarios**:

1. **Given** the released docs, **When** a reader scans the top of the README, **Then** they see
   the two use-case shapes and the "building one thing → `code`; steering many → `cockpit`" rule
   before the concept-heavy sections.
2. **Given** any profile enumeration (help text, README "Supported profiles", prompts), **When**
   inspected, **Then** it includes `general`, `code`, and `cockpit`.
3. **Given** `agent-ws init --profile general|code`, **When** run, **Then** the generated file
   set and metadata are unchanged from the prior release.

---

### Edge Cases

- Running `agent-ws init` with an invalid `--profile` value must fail with a message that lists
  all three valid profiles (`general`, `code`, `cockpit`).
- A cockpit project's `STATE.md` must not be overwritten by `sync` (it is project-owned content).
- `WORKFLOWS-COCKPIT.md` is a framework file: `sync` should reconcile it like `ENGINEERING.md`,
  preserving local edits.
- Auditing a cockpit project created before some cockpit files existed reports the missing files
  and recommends re-running init (existing partial-state behavior), without touching content.
- The interactive profile prompt must accept `cockpit` and reject unknown values.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST accept `cockpit` as a valid value for `--profile` on `agent-ws init`.
- **FR-002**: `agent-ws init --profile cockpit` MUST generate, in addition to the `general` core
  files (`PROJECT.md`, `STATE.md`, `WORKFLOWS.md`, `.gitignore`): `PROJECTS.md`, `PROFILE.md`,
  and `WORKFLOWS-COCKPIT.md`.
- **FR-003**: For the `cockpit` profile the generated `STATE.md` MUST be the cross-cutting cockpit
  variant (current focus, current question, coarse per-project status pointing at each repo's own
  `STATE.md`), not the default single-project `STATE.md`.
- **FR-004**: The base `WORKFLOWS.md` template MUST remain byte-for-byte identical for all
  profiles; cockpit control-room workflows MUST live in the companion `WORKFLOWS-COCKPIT.md`.
- **FR-005**: `WORKFLOWS-COCKPIT.md` MUST document (a) the cross-project one-way-dependency rule,
  (b) the explore→build→reflect loop, and (c) the optional handoff-ingest ritual.
- **FR-006**: `PROJECTS.md` and `PROFILE.md` MUST ship with obviously-placeholder, neutral example
  content that does not assume a software-only user and encodes no individual's habits.
- **FR-007**: The generated metadata (`workspace.json`) MUST record `profile: cockpit` and list
  all generated cockpit files with their kinds.
- **FR-008**: `agent-ws audit` MUST include the full cockpit file set in its expected-files check
  for a project whose metadata records `profile: cockpit`, and pass on a freshly-initialized
  cockpit project.
- **FR-009**: File kinds MUST be assigned so that `PROJECTS.md`, `PROFILE.md`, and the cockpit
  `STATE.md` are `context` (seeded once, never synced) and `WORKFLOWS-COCKPIT.md` is a framework
  (`profile`) file that `sync` reconciles.
- **FR-010**: `general` and `code` init output (files and metadata) MUST be unchanged.
- **FR-011**: The interactive profile prompt, `--no-prompt` validation, help/usage text, and the
  usage example MUST all present `cockpit` as an accepted profile.
- **FR-012**: An invalid `--profile` value MUST produce an error whose remediation hint lists
  `general`, `code`, and `cockpit`.
- **FR-013**: `agent-ws migrate` MUST recognize cockpit files (`PROJECTS.md`, `PROFILE.md`,
  `WORKFLOWS-COCKPIT.md`) as preserved, mapped-to-template files when present in a legacy project.
- **FR-014**: The README MUST show, near the top (after the one-line intro, before the
  concept-heavy sections), the two compact use-case shapes and the one-line choose-your-profile
  rule; any longer walkthrough MUST stay lower near the command/advanced docs, with no duplication.
- **FR-015**: The README MUST include a short, clearly-optional "Complementary tools" note for
  `checkpoint` that links to `https://github.com/adiacov/checkpoint`, states independence from
  agent-workspace, and does not wire any checkpoint behavior into the tool or any profile.
- **FR-016**: Every documentation enumeration of profiles (README "Supported profiles", help text,
  any profile table) MUST include `cockpit` with a same-altitude description of what it is and
  when to choose it.
- **FR-017**: Documentation made stale by the current global-CLI model or by the third profile
  (e.g. lingering references to a project-local `bin/agent-workspace`, two-profile assumptions)
  MUST be removed or corrected.

### Key Entities

- **Profile**: A named shape of scaffolding. `general` (core), `code` (core + `ENGINEERING.md`),
  `cockpit` (core + coordination layer). Recorded in `workspace.json`.
- **Cockpit file set**: `PROJECTS.md` (project index, `context`), `PROFILE.md` (strategy/context,
  `context`), `STATE.md` (cross-cutting index, `context`, overrides default source),
  `WORKFLOWS-COCKPIT.md` (control-room workflows, `profile`/framework).
- **File kind**: `default`/`profile`/`adapter` are framework (synced); `context` is seeded-once
  (never synced). Cockpit assignments per FR-009.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `agent-ws init --profile cockpit --agents <x> --no-prompt` produces a project that
  passes `agent-ws audit` with zero missing expected files, in a single command with no manual
  follow-up.
- **SC-002**: 100% of profile enumerations across code help text and docs list all three profiles.
- **SC-003**: `agent-ws init --profile general` and `--profile code` produce output identical to
  the prior release (verified by the existing test suite continuing to pass unchanged).
- **SC-004**: A newcomer can determine, from the first screen of the README alone, whether they
  want `code` (one project) or `cockpit` (many projects) — the two shapes and the choosing rule
  are visible without scrolling past the quickstart.
- **SC-005**: A fresh cockpit project contains all coordination guidance (cross-project rule,
  explore→build→reflect, handoff ingest) reachable from `STATE.md` in at most one pointer hop.

## Assumptions

- `cockpit` is standalone in this iteration (no `cockpit`+`code` stacking); revisited only if a
  concrete need appears.
- The companion-file approach (a) is preferred over superseding `WORKFLOWS.md`; discovery is via
  the cockpit `STATE.md` pointer, keeping the shared base template untouched.
- `checkpoint` remains external and optional; this feature adds documentation only, never wiring.
- Neutral example content is sufficient; the tool never reads or maintains the content files.
