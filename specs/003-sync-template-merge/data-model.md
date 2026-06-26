# Phase 1 Data Model: Sync merges template changes into projects

No database. "Entities" here are files and the structured records the tool reads/writes.

## Entities

### Active file
- **Location**: `<project>/<active-path>` (e.g. `WORKFLOWS.md`).
- **Role**: project-owned generated file; may carry local edits.
- **Role in merge**: OURS.

### Template file (current)
- **Location**: `<template-source>/<template-rel>` (e.g. `default/WORKFLOWS.md`), resolved by
  `agent_ws_template_source_dir`.
- **Role in merge**: THEIRS.

### Baseline snapshot
- **Location**: `<project>/.agent-workspace/baseline/<active-path>` (gitignored).
- **Content**: byte copy of the template content this project last synced from.
- **Lifecycle**: created on `init` (framework files) and on first sync seeding; overwritten with
  THEIRS after each successful sync of that file.
- **Role in merge**: BASE. Absent ⇒ "no baseline" path (seed).

### Backup
- **Location**: `<project>/<active-path>.bak` (gitignored), transient.
- **Lifecycle**: created before a write, removed after whole-run success, used to restore on
  failure.

### Conflict side-file
- **Location**: `<project>/<active-path>.merge` (gitignored), produced only on agentless
  conflict.
- **Content**: `git merge-file` output with `<<<<<<< ======= >>>>>>>` markers.
- **Lifecycle**: written when a conflict is refused; the live file is NOT modified. Left for the
  user/agent to inspect; not auto-deleted.

### Generated-file record (existing, in `workspace.json`)
- **Shape**: `generatedFiles[active-path] = { kind, template, agent? }`.
- **kind** ∈ `default | profile | adapter | context`.
- **Derived classification**: `framework = kind ∈ {default, profile, adapter}`,
  `content = kind == context`.

## Per-file outcome (reported by sync)

| Outcome | Meaning | Live file changed? | Exit contribution |
|---|---|---|---|
| `unchanged` | template == baseline, or merge produced identical content | no | ok |
| `updated` | clean 3-way merge applied (or agent-resolved) | yes | ok |
| `seeded` | baseline established for a framework file (first run) | no | ok |
| `conflicted` | overlapping change, refused; `.merge` written | no | non-zero |
| `missing-active` | mapped active file absent | no | ok (reported) |
| `missing-template` | template for a mapped file absent | no | ok (reported) |
| `skipped-content` | `kind == context`; never synced | no | ok |

Run exit code is non-zero if any file is `conflicted`.

## State transitions (per framework file, on `--apply`)

```
            baseline exists?
                 │
        no ──────┴────── yes
        │                 │
     seed BASE        3-way merge(OURS, BASE, THEIRS)
   (outcome=seeded)        │
                    ┌──────┴───────┐
                 clean            conflict
                    │                │
             write+backup      agent present?
            (outcome=updated)   ┌────┴────┐
              refresh BASE     yes        no
                                │          │
                          agent resolve   write .merge,
                          → write+backup   leave live file
                          → refresh BASE   (outcome=conflicted)
                          (outcome=updated)
```

## Validation rules

- Never write a live file that still contains conflict markers (FR-005).
- A backup must exist for the duration of every live-file write (FR-006).
- `content` files are excluded before any merge work (FR-008).
- All operations resolve from local templates + local baseline only (FR-015).
