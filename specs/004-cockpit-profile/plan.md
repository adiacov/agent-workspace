# Implementation Plan: `cockpit` profile

**Branch**: `004-cockpit-profile` | **Date**: 2026-07-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/004-cockpit-profile/spec.md`

## Summary

Add a third profile, `cockpit`, that scaffolds a control-room over many project repos. Where
`code` = `general` + `ENGINEERING.md`, `cockpit` = `general` core + a coordination layer:
`PROJECTS.md` (project index), `PROFILE.md` (strategy/context), a cockpit-variant `STATE.md`
(cross-cutting index), and `WORKFLOWS-COCKPIT.md` (control-room workflows). The tool stays
meaning-free: it copies empty/neutral scaffolding the project owns, exactly like `code` ships
`ENGINEERING.md`.

Two mechanism gaps are closed: (1) **augmenting** a base file — solved by shipping a companion
`WORKFLOWS-COCKPIT.md` (option (a)) rather than mutating the shared `WORKFLOWS.md`; discovery is
via a pointer in the cockpit `STATE.md`; (2) **overriding** a base file — solved by making the
default-file generator profile-aware so `cockpit` swaps the `STATE.md` source to the cockpit
variant while keeping the destination path and `context` kind unchanged. `general`/`code` output
is byte-identical.

Documentation work: top-of-README use-case visuals (two shapes + choosing rule), a `cockpit`
entry everywhere profiles are enumerated, a short optional `checkpoint` complementary-tools note,
and removal of stale statements.

## Technical Context

**Language/Version**: Bash (POSIX-ish, matching `lib/agent-ws/*.sh`), Python 3 for JSON
(as in `metadata.sh`).

**Primary Dependencies**: `git`, `python3`, coreutils. No new third-party dependencies.

**Storage**: Per-project files only — new templates under `templates/profiles/cockpit/`,
generated files in the target project, metadata in `.agent-workspace/workspace.json`.

**Testing**: `tests/smoke/` (fast functional), `tests/integration/` (end-to-end in temp dirs),
`tests/unit/` (helper-level). Add cockpit coverage across all three where each fits.

**Target Platform**: Linux shell (first-class), macOS-compatible shells.

**Project Type**: Single-project CLI tool.

**Constraints**: No runtime boundary change — the CLI never learns project meaning; cockpit ships
empty/neutral templates. No external capture/recovery wiring in the profile. No personal registry
in tool state. `general`/`code` behavior unchanged.

**Scale/Scope**: ~7 generated files for a cockpit project; small inputs; interactive latency.

## Constitution Check

The repository constitution is an unpopulated template (`.specify/memory/constitution.md`), so
there are no ratified principles to gate against. The de-facto invariants from `SPEC.md`/`README.md`
are honored: tool copies scaffolding but never reads/maintains project meaning; global-CLI model;
ownership model (`context` vs framework `default`/`profile`/`adapter`). No violations; no
Complexity Tracking entries required.

## Design decisions (resolved open questions)

1. **Strategy file → `PROFILE.md`** (generic; neutral placeholder content).
2. **WORKFLOWS augmentation → companion file `WORKFLOWS-COCKPIT.md`** (option (a)); base
   `WORKFLOWS.md` untouched; cockpit `STATE.md` points to it.
3. **Standalone profile** (no `cockpit`+`code` stacking) for iteration one.
4. **STATE.md override → profile-aware default generation** (swap source, keep destination +
   `context` kind) rather than a second STATE.md file. Keeps `general`/`code` untouched and keeps
   the ownership model intact.

## Where it plugs in (verified against the repo)

- `templates/profiles/cockpit/{PROJECTS.md,PROFILE.md,STATE.md,WORKFLOWS-COCKPIT.md}` — new
  template files (modeled on `templates/profiles/software/ENGINEERING.md`).
- `lib/agent-ws/templates.sh`:
  - `agent_ws_default_template_files` gains an optional `profile` arg; for `cockpit` the
    `STATE.md` source becomes `profiles/cockpit/STATE.md` (destination + `context` kind unchanged).
  - `agent_ws_generate_default_files` passes the profile through.
  - `agent_ws_profile_template_files` gains a `cockpit)` branch listing `PROJECTS.md`,
    `PROFILE.md`, `WORKFLOWS-COCKPIT.md`; the `*)` error hint lists all three profiles.
- `lib/agent-ws/commands.sh`: `init` passes the profile to default generation; accept-list in the
  `--no-prompt` validation, `agent_ws_prompt_profile`, help/usage, and the example line all add
  `cockpit`.
- `lib/agent-ws/audit.sh`: `agent_ws_audit_expected_files` iterates default+profile+agents, so the
  cockpit set is audited once `profile_template_files(cockpit)` and the profile-aware default are
  in place. Its default-files call stays profile-agnostic (destination unchanged) — no edit needed.
- `lib/agent-ws/metadata.sh`: `profile` is written verbatim; `cockpit` flows through with no change.
- `lib/agent-ws/migrate.sh`: add `PROJECTS.md`, `PROFILE.md`, `WORKFLOWS-COCKPIT.md` to the
  preserved-files list and the record→template mapping.
- `templates/default/WORKFLOWS.md`: **unchanged** (invariant per FR-004).

## Docs plan

- `README.md`: top-of-file "What you can build" block (two shapes + one-line rule); `cockpit` in
  "Supported profiles" and any profile table; "Complementary tools" note for `checkpoint`; remove
  stale statements (`bin/agent-workspace`, two-profile assumptions).
- `SPEC.md`: update profile enumeration and any two-profile/stale global-CLI statements.
- Help text in `commands.sh`: profile list + example.

## Test plan

- **unit** (`tests/unit/`): `agent_ws_profile_template_files cockpit` lists the three files;
  `agent_ws_default_template_files cockpit` swaps only the `STATE.md` source; `general`/`code`
  return unchanged sets.
- **integration** (`tests/integration/`): `init --profile cockpit --no-prompt` creates the full
  set; metadata records `profile: cockpit`; `audit` passes; `general`/`code` regression unchanged;
  invalid-profile error lists three profiles.
- **smoke**: cockpit init happy path in a temp dir, asserting file presence and metadata.

## Phase outputs

- `research.md` — mechanism-gap analysis and rejected alternatives.
- `data-model.md` — profile → file-set → kind mapping (the "entities").
- `contracts/cockpit-cli.md` — the CLI contract delta for `--profile cockpit`.
- `quickstart.md` — the one-command cockpit walkthrough.
- `tasks.md` — ordered, dependency-annotated tasks.

## Complexity Tracking

No constitution violations; table intentionally omitted.
