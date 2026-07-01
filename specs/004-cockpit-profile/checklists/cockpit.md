# Checklist: cockpit profile parity, safety & docs

**Purpose**: Gate implementation quality before merge — profile parity, ownership-model safety,
and documentation consistency.
**Created**: 2026-07-01
**Feature**: [spec.md](../spec.md)

## Profile parity

- [ ] CHK001 `--profile cockpit` accepted by the flag, the interactive prompt, and `--no-prompt`
  validation [FR-001, FR-011]
- [ ] CHK002 Invalid `--profile` error hint lists exactly `general`, `code`, `cockpit` [FR-012]
- [ ] CHK003 `general` and `code` generated file set + metadata are byte-identical to prior release
  [FR-010, SC-003]
- [ ] CHK004 Base `templates/default/WORKFLOWS.md` is unchanged by this feature [FR-004]

## File set & ownership model

- [ ] CHK005 Cockpit init creates `PROJECTS.md`, `PROFILE.md`, cockpit `STATE.md`, `WORKFLOWS.md`,
  `WORKFLOWS-COCKPIT.md` + adapter [FR-002, FR-003]
- [ ] CHK006 `PROJECTS.md`, `PROFILE.md`, `STATE.md` recorded as `context` (never synced);
  `WORKFLOWS-COCKPIT.md` recorded as `profile` (synced) [FR-009]
- [ ] CHK007 `sync` never touches cockpit `context` files; reconciles `WORKFLOWS-COCKPIT.md` like
  `ENGINEERING.md` [FR-009]
- [ ] CHK008 Metadata records `profile: cockpit` and lists every generated file [FR-007]
- [ ] CHK009 `audit` passes on a fresh cockpit project (no missing expected files) [FR-008, SC-001]

## Content quality (neutral & discoverable)

- [ ] CHK010 `PROJECTS.md`/`PROFILE.md` content is obviously placeholder, encodes no individual's
  habits, and does not assume a software-only user [FR-006]
- [ ] CHK011 `WORKFLOWS-COCKPIT.md` documents the cross-project rule, explore→build→reflect loop,
  and handoff-ingest ritual as distinct sections [FR-005]
- [ ] CHK012 Cockpit `STATE.md` names itself a cross-cutting index and reaches all coordination
  guidance in ≤1 pointer hop [FR-003, SC-005]

## Documentation

- [ ] CHK013 README shows the two use-case shapes + choosing rule near the top, before
  concept-heavy sections; longer walkthrough stays lower with no duplication [FR-014, SC-004]
- [ ] CHK014 Every profile enumeration (README, help text) includes `cockpit` [FR-016, SC-002]
- [ ] CHK015 README has an optional, independent `checkpoint` "Complementary tools" note linking
  the canonical repo; no checkpoint behavior wired into the tool [FR-015]
- [ ] CHK016 Stale docs removed/corrected (`bin/agent-workspace`, two-profile assumptions)
  across README and SPEC [FR-017]

## Non-goals held

- [ ] CHK017 Tool never reads/maintains cockpit content; no personal registry in tool state;
  no external capture/recovery wiring in the profile
