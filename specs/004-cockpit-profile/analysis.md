# Cross-Artifact Analysis: `cockpit` profile

**Date**: 2026-07-01 · **Scope**: spec.md, plan.md, research.md, data-model.md,
contracts/cockpit-cli.md, tasks.md, checklists/. Analysis is read-only; findings below are
resolved in-place before implementation.

## Coverage: requirements → tasks

| Requirement | Tasks | Status |
|-------------|-------|--------|
| FR-001 accept `cockpit` | T006, T007 | covered |
| FR-002 generate added files | T001–T004, T005, T006, T010 | covered |
| FR-003 cockpit STATE.md variant | T003, T005 | covered |
| FR-004 base WORKFLOWS.md unchanged | (invariant) T004; checklist CHK004 | covered |
| FR-005 WORKFLOWS-COCKPIT content | T004 | covered |
| FR-006 neutral placeholder content | T001, T002 | covered |
| FR-007 metadata profile+files | T010 | covered |
| FR-008 audit cockpit set | T010 | covered |
| FR-009 kinds/sync behavior | T006 | covered |
| FR-010 general/code unchanged | T009, T011 | covered |
| FR-011 prompt/validation/help/example | T007 | covered |
| FR-012 invalid-profile hint | T006, T007, T011 | covered |
| FR-013 migrate recognizes files | T008 | covered |
| FR-014 top-of-README visuals | T013 | covered |
| FR-015 checkpoint note | T015 | covered |
| FR-016 profile enumerations | T014 | covered |
| FR-017 remove stale docs | T016 | covered |

All 17 functional requirements map to ≥1 task. All 5 success criteria are exercised (SC-001 T010,
SC-002 T014, SC-003 T011, SC-004 T013, SC-005 T003/T012).

## Consistency findings

- **C1 (resolved) — "base WORKFLOWS.md references companion" vs "base unchanged".** The source
  brief's option (a) implies the base references the companion, which would mutate the shared
  template and violate FR-004/FR-010. Resolved in research R1 + spec Clarification: discovery is
  via the cockpit `STATE.md` pointer instead; base template stays identical. No residual conflict.
- **C2 (resolved) — STATE.md override vs "profile only adds files".** The generator only adds by
  destination and skips existing ones, so a profile file cannot override the default `STATE.md`.
  Resolved by making default-file generation profile-aware (swap source, keep destination/kind) —
  plan §Design decisions, research R2, tasks T005.
- **C3 (resolved) — audit path.** `agent_ws_audit_expected_files` calls the default generator
  without a profile. Since the cockpit override changes only the *source* (destination `STATE.md`
  unchanged) and the extra files come from `profile_template_files(cockpit)`, audit needs no edit.
  Verified against `lib/agent-ws/audit.sh`; recorded in plan.

## Ambiguity / terminology

- File-kind terms (`context`/`profile`) are user-facing (README ownership model), so their
  appearance in the spec is intentional, not a leak — noted in the requirements checklist.
- "Coarse status" in `PROJECTS.md` is deliberately unconstrained (user-owned content); no enum is
  imposed, consistent with the tool-stays-meaning-free non-goal.

## Constitution alignment

Constitution is an unpopulated template; de-facto invariants (meaning-free tool, global-CLI,
ownership model) are honored. No violations.

## Verdict

Artifacts are internally consistent and fully cover the spec. No blocking issues. Proceed to
`/speckit.implement`.
