# Data Model: `cockpit` profile

This feature adds no runtime data structures; the "model" is the static profile → file-set → kind
mapping the generator, auditor, and metadata writer share.

## Profiles

| Profile   | Core files (default)                         | Added files                                                   |
|-----------|----------------------------------------------|---------------------------------------------------------------|
| `general` | `.gitignore`, `PROJECT.md`, `STATE.md`, `WORKFLOWS.md` | —                                                     |
| `code`    | same as `general`                            | `ENGINEERING.md`                                              |
| `cockpit` | same as `general`, but `STATE.md` source overridden to the cockpit variant | `PROJECTS.md`, `PROFILE.md`, `WORKFLOWS-COCKPIT.md` |

## Cockpit file set → kind → sync behavior

| Destination           | Source template                          | Kind      | Synced? |
|-----------------------|------------------------------------------|-----------|---------|
| `PROJECTS.md`         | `profiles/cockpit/PROJECTS.md`           | `context` | no      |
| `PROFILE.md`          | `profiles/cockpit/PROFILE.md`            | `context` | no      |
| `STATE.md`            | `profiles/cockpit/STATE.md` (override)   | `context` | no      |
| `WORKFLOWS-COCKPIT.md`| `profiles/cockpit/WORKFLOWS-COCKPIT.md`  | `profile` | yes     |

`default`/`profile`/`adapter` = framework (reconciled by `sync`); `context` = seeded once, never
synced. Cockpit keeps user-owned strategy/index content as `context` and the shareable
control-room workflow as a syncable `profile` file.

## Metadata (`.agent-workspace/workspace.json`)

`profile` is recorded verbatim (`"cockpit"`). `generatedFiles` lists each destination with its
kind, source template, and owning agent (empty for non-adapter files) — same schema as today,
no new fields.

## Invariants

- Base `WORKFLOWS.md` template is identical across all profiles.
- `general`/`code` file sets and metadata are unchanged.
- The cockpit `STATE.md` remains the single canonical current-context entrypoint (destination
  `STATE.md`), only its content/role differs.
