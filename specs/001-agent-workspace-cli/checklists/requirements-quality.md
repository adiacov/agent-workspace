# Requirements Quality Checklist: Agent Workspace CLI

**Purpose**: Unit tests for the English requirements: validate clarity, completeness, consistency, and implementation readiness for the global `agent-ws` CLI feature
**Created**: 2026-06-07
**Feature**: [spec.md](../spec.md)

**Note**: This checklist validates whether the requirements are well-written and complete. It does not validate implementation behavior.

## Requirement Completeness

- [x] CHK001 Are all public `agent-ws` command requirements documented with scope, inputs, and expected outcomes? [Completeness, Spec §FR-022, Contract §Commands]
- [x] CHK002 Are initialization requirements complete for both current-directory and named-directory project creation? [Completeness, Spec §User Story 1, Spec §FR-002]
- [x] CHK003 Are requirements defined for global template source discovery, availability, and failure handling? [Completeness, Spec §FR-002a, Spec §FR-005, Data Model §Global Template Source]
- [x] CHK004 Are metadata creation requirements complete enough to cover required fields, commit behavior, privacy constraints, and future schema compatibility? [Completeness, Spec §FR-011, Contract §Metadata]
- [x] CHK005 Are migration requirements complete for legacy `.agent/` and `bin/agent-workspace` cases while excluding old project-local template caches from product logic? [Completeness, Spec §User Story 6, Spec §FR-024]
- [x] CHK006 Are README requirements complete enough to define the primary quickstart, advanced-option placement, and migration guidance expectations? [Completeness, Spec §User Story 7, Spec §FR-026]

## Requirement Clarity

- [x] CHK007 Is the term "global template source" defined clearly enough to distinguish installed templates, release templates, and local development templates? [Clarity, Spec §FR-002a, Data Model §Global Template Source]
- [x] CHK008 Is "conservative sync" defined with clear boundaries for what may change and what must never change? [Clarity, Spec §FR-017, Spec §SC-006]
- [x] CHK009 Is "latest stable release" defined clearly enough for update requirements to be unambiguous? [Ambiguity, Spec §FR-020]
- [x] CHK010 Are "strong" and "uncertain" discovery classifications defined with enough scoring criteria to guide implementation consistently? [Clarity, Spec §FR-014, Data Model §Discovery Result]
- [x] CHK011 Is "no silent overwrites" specified with enough detail for active files, memory files, metadata, and migration actions? [Clarity, Spec §FR-008, Spec §FR-018, Spec §FR-025]
- [x] CHK012 Are custom agent path rules specified clearly enough to distinguish valid relative paths from unsafe escaping paths? [Clarity, Spec §FR-006, Edge Cases]

## Requirement Consistency

- [x] CHK013 Are global CLI naming requirements consistent across spec, plan, CLI contract, metadata contract, and quickstart? [Consistency, Spec §Clarifications, Plan §Summary, Contract §CLI]
- [x] CHK014 Are `.agent-workspace/` metadata requirements consistent across spec, data model, metadata contract, and quickstart? [Consistency, Spec §FR-011, Data Model §Workspace Metadata, Contract §Metadata]
- [x] CHK015 Are legacy `.agent/` requirements consistently described as migration/discovery signals rather than new initialization outputs? [Consistency, Spec §FR-011b, Contract §Compatibility Rules]
- [x] CHK016 Are project ownership boundaries consistent across active files, memory files, templates, metadata, sync, and migration requirements? [Consistency, Spec §FR-021, Plan §Constitution Check]
- [x] CHK017 Are install/update requirements consistent with the decision to use Git/GitHub releases or tags rather than package registries? [Consistency, Spec §FR-020, Research §Install/update]

## Acceptance Criteria Quality

- [x] CHK018 Are success criteria measurable for initialization, add-agent, audit, discovery, sync, update, migration, and README usability? [Acceptance Criteria, Spec §Success Criteria]
- [x] CHK019 Are audit accuracy targets tied to representative fixture definitions or explicit fixture coverage expectations? [Measurability, Spec §SC-004]
- [x] CHK020 Are discovery accuracy targets tied to representative directory-tree definitions and legacy signal examples? [Measurability, Spec §SC-005]
- [x] CHK021 Is README usability success defined objectively enough to avoid subjective interpretation of "clear" or "counterintuitive"? [Measurability, Spec §SC-011]
- [x] CHK022 Are failure-message quality requirements measurable beyond the 90% target, including what counts as a clear next action? [Clarity, Spec §SC-009]

## Scenario Coverage

- [x] CHK023 Are primary user flows covered for install, initialize, add-agent, status, audit, discover, diff, sync, update, migrate, and help? [Coverage, Spec §User Stories, Contract §Commands]
- [x] CHK024 Are alternate flows covered for non-interactive use, custom agents, named project creation, and multiple selected agents? [Coverage, Spec §FR-004, Spec §FR-006, Edge Cases]
- [x] CHK025 Are exception flows covered for unavailable templates, unavailable releases, invalid metadata, unsafe paths, and legacy project ambiguity? [Coverage, Edge Cases, Contract §Metadata]
- [x] CHK026 Are recovery flows documented for failed initialization, failed update, failed migration apply, or partial metadata creation? [Gap, Recovery Flow]
- [x] CHK027 Are non-functional scenarios covered for discovery scale, scan exclusions, privacy-safe metadata, and no-overwrite safety? [Coverage, Spec §FR-011a, Spec §FR-015, Plan §Constraints]

## Edge Case Coverage

- [x] CHK028 Are requirements defined for initializing into an existing named directory that already contains partial Agent Workspace files? [Edge Case, Spec §Edge Cases]
- [x] CHK029 Are requirements defined for metadata conflicts, stale metadata, or metadata that references templates no longer available globally? [Gap, Data Model §Workspace Metadata]
- [x] CHK030 Are requirements defined for adapter destination conflicts when multiple agents share the same active file path? [Edge Case, Spec §Edge Cases, Data Model §Agent Adapter]
- [x] CHK031 Are requirements explicit that old project-local template cache contents are outside the supported product model and are not inspected or migrated? [Gap, Spec §User Story 6]
- [x] CHK032 Are requirements defined for update rollback or preserving the previous installed `agent-ws` when an update fails? [Gap, Recovery Flow, Spec §FR-020]

## Non-Functional Requirements

- [x] CHK033 Are portability requirements specific enough for Bash/Linux/macOS support and Windows limitations? [Clarity, Plan §Technical Context]
- [x] CHK034 Are privacy requirements for metadata complete enough to exclude secrets, private memory, personal registry meaning, and machine-specific paths? [Completeness, Spec §FR-011a, Contract §Privacy Rules]
- [x] CHK035 Are performance requirements for discovery bounded with scan-skip rules and expected scale assumptions? [Coverage, Spec §FR-015, Plan §Scale/Scope]
- [x] CHK036 Are reliability requirements defined for no-overwrite behavior, explicit apply intent, and conflict stopping across all mutating commands? [Coverage, Spec §FR-008, Spec §FR-018, Spec §FR-019]

## Dependencies & Assumptions

- [x] CHK037 Are external dependency assumptions documented for Bash, Git, Curl, GitHub availability, and common Unix tools? [Assumption, Plan §Technical Context]
- [x] CHK038 Are release-source assumptions documented for latest stable lookup, explicit version selection, and unavailable versions? [Assumption, Spec §FR-020, Spec §Edge Cases]
- [x] CHK039 Are assumptions about existing legacy projects being few/local separated from requirements that must hold for all users? [Assumption, Spec §Assumptions]
- [x] CHK040 Are documentation deliverables traceable from requirements to quickstart validation and README expectations? [Traceability, Spec §FR-024, Spec §FR-026, Quickstart §10]

## Ambiguities & Conflicts

- [x] CHK041 Is any remaining use of the older `agent-workspace` name intentionally limited to legacy migration context? [Ambiguity, Spec §FR-023]
- [x] CHK042 Are command names `diff` and `sync` clearly differentiated so requirements do not imply overlapping behavior? [Ambiguity, Contract §Commands]
- [x] CHK043 Is the relationship between `status` and `audit` requirements clear enough to avoid duplicate or contradictory command scopes? [Ambiguity, Contract §Commands]
- [x] CHK044 Are migration automation requirements explicit about whether automation is mandatory for MVP or optional if time allows? [Ambiguity, Spec §FR-025]
- [x] CHK045 Are active-file sync requirements clear that automatic semantic merge is out of scope for this phase? [Clarity, Spec §Assumptions, Plan §Scale/Scope]

## Notes

- This checklist is intended for requirements review before task generation and implementation.
- Items marked incomplete indicate requirements writing gaps, not implementation defects.
