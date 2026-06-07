# Agent Workspace CLI Evolution Brief

## Project name

`agent-workspace`

## Current implementation repo

```text
../agent-workspace
```

## Current purpose

Agent Workspace bootstraps project files for AI-assisted work.

It currently provides:

- reusable templates for agent instruction files;
- reusable templates for project memory files;
- workspace profiles, including a `code` profile that adds `ENGINEERING.md`;
- a curl/bootstrap flow for new projects;
- a project-local CLI installed at `bin/agent-workspace` inside each initialized project.

## Origin of this next phase

The user has started using multiple repositories with the Agent Workspace structure.

The current workflow is still mostly project-by-project:

1. create a new project;
2. run the bootstrap command;
3. get templates copied into the project;
4. use local instructions and memory in that repo.

This works for initialization, but new needs have appeared:

- discovering which projects on the machine use Agent Workspace;
- checking whether a specific project is using the structure correctly;
- comparing project instruction files against current templates;
- syncing/upgrading instruction files safely;
- doing this from Agent Workspace itself, not from `life-os`.

Important architectural boundary:

`life-os` may know about projects and reason about strategy, but Agent Workspace should own reusable initialization, discovery, audit, and sync behavior.

## Current implementation research

The actual implementation logic currently lives in two bash files:

```text
../agent-workspace/bootstrap.sh
../agent-workspace/bin/agent-workspace
```

They are currently effectively the same script body.

Important current behavior from the bash implementation:

- Default command is `init`.
- Supported commands are currently:
  - `init`
  - `add-agent`
  - `status`
  - `help`
- Templates are copied into initialized projects under:

```text
.agent/templates/
```

- Generated active files are placed at project root or agent-native locations:
  - `AGENTS.md` for Pi/Codex-style agents;
  - `CLAUDE.md` for Claude Code;
  - `.cursor/rules/agent-workspace.mdc` for Cursor;
  - custom path for custom agent instructions;
  - `STATE.md`;
  - `BRAINSTORM.md`;
  - `.gitignore`;
  - `ENGINEERING.md` when profile is `code`.
- Existing files are skipped, not overwritten.
- `init` runs `git init` if needed, but aborts if run inside a parent git repository instead of the target repo root.
- `add-agent` requires `.agent/templates/` to exist and generates additional adapter files from the local template cache.
- `status` only reports presence/missing for known files in the current project.
- Template source can be local or downloaded from GitHub raw content.
- Environment variables exist for non-interactive use:
  - `AGENT_WORKSPACE_RAW_BASE`
  - `AGENT_WORKSPACE_TEMPLATE_SOURCE_DIR`
  - `AGENT_WORKSPACE_AGENTS`
  - `AGENT_WORKSPACE_CUSTOM_PATH`
  - `AGENT_WORKSPACE_PROFILE`

Current source templates live under:

```text
../agent-workspace/templates/default/
../agent-workspace/templates/adapters/
../agent-workspace/templates/profiles/software/ENGINEERING.md
```

Current local target marker is implicit, not explicit. A project appears to be Agent Workspace-initialized if it has some combination of:

- `.agent/templates/`
- `bin/agent-workspace`
- `STATE.md`
- `BRAINSTORM.md`
- `WORKFLOWS.md`
- known adapter files such as `AGENTS.md`, `CLAUDE.md`, or Cursor rules.

## Current design documents in `agent-workspace`

Relevant files:

- `README.md` documents the current bootstrap/local CLI behavior.
- `SPEC.md` documents the previous rewrite model and current principles.
- `PROMPT_REVIEW_SESSION.md` records recent instruction architecture decisions.
- `WORKFLOWS.md` defines project workflow.

Important existing principles from `SPEC.md` and recent prompt review:

- Templates are the source of truth for generated content.
- Shell scripts should orchestrate copying and prompting, not embed Markdown content.
- Generated agent files should live where each agent expects them.
- No silent overwrites.
- Local templates are kept after initialization so `add-agent` can work later.
- Agent adapters should be thin bootstraps.
- `WORKFLOWS.md` should own collaboration/workflow behavior.
- `ENGINEERING.md` should own engineering behavior.

## Responsibility model

Agent Workspace as a CLI should own reusable mechanisms, not project-specific meaning.

| Feature / area | Responsibility owner | Meaning |
| --- | --- | --- |
| Template source files | `agent-workspace` | Owns canonical reusable templates. |
| Bootstrap command | `agent-workspace` | Initializes a target project from templates. |
| `init` | `agent-workspace` | Creates initial structure safely in the current project. |
| `add-agent` | `agent-workspace` | Adds selected agent adapter from templates. |
| `status` | `agent-workspace` | Reports current project's Agent Workspace file presence. |
| `.agent/templates/` cache | `agent-workspace` manages; target project stores | CLI may install or refresh it; project may contain local customized copies. |
| Active generated files such as `AGENTS.md`, `WORKFLOWS.md`, `ENGINEERING.md` | target project | CLI may create them initially, but final content belongs to the target project. |
| Project memory such as `STATE.md` and `BRAINSTORM.md` | target project | Never globally overwritten or synced by default. |
| Project-specific instruction additions | target project | Must be preserved during any update. |
| `discover PATH...` | `agent-workspace` | Finds projects that appear to use Agent Workspace. |
| `audit [PATH...]` | `agent-workspace` | Reports missing files, legacy structure, metadata, and drift. |
| `.agent/workspace.json` metadata | `agent-workspace` defines and updates; target project stores | Enables reliable discovery, audit, and future sync. |
| `sync --templates-only` | `agent-workspace` | Safe default: refresh local template cache without touching active files. |
| Active-file sync | shared: `agent-workspace` proposes; user/project agent approves | CLI should compare and preview, not blindly overwrite. |
| Conflict detection | `agent-workspace` | Tool should identify safe updates vs manual merge cases. |
| Final merge of project-specific instructions | user/project agent | Human/project-context judgment is required. |
| Global personal project registry | not `agent-workspace` | Agent Workspace can discover projects, but should not maintain personal meaning/status. |
| Project purpose/status/strategy | not `agent-workspace` | Belongs to project-local memory or external planning systems. |
| Installed local CLI copy lifecycle | `agent-workspace` should help | A future command may update `bin/agent-workspace` safely. |

Core rule:

```text
agent-workspace owns mechanisms and templates.
A target project owns its final active files and memory.
```

Therefore Agent Workspace may initialize, discover, audit, compare, and propose updates. It should not blindly rewrite active instruction files after a project has started accumulating local instructions or memory.

## Problem statement

Agent Workspace currently initializes individual projects well, but it does not yet manage the lifecycle of already-initialized projects.

As the number of projects grows, the user needs a way to answer:

- Which projects on this machine use Agent Workspace?
- Which projects are missing expected files?
- Which projects have old or drifted instruction files?
- Which projects can be safely upgraded from current templates?
- What would change before syncing instructions?
- How can template improvements be propagated without blindly overwriting project-specific additions?

This should be handled by Agent Workspace, not by ad hoc cross-repo work from `life-os`.

## Candidate users

Primary user:

- a developer using multiple AI-assisted local projects and wanting consistent agent instructions/memory behavior.

Secondary users:

- developers who bootstrap new projects with Agent Workspace;
- developers who later want to add new agent adapters;
- developers who want to audit or update already-initialized projects.

## Proposed next CLI responsibilities

### 1. Project-local commands

These operate inside one project.

Existing:

```bash
agent-workspace init
agent-workspace add-agent
agent-workspace status
```

Candidate additions:

```bash
agent-workspace audit
agent-workspace diff-templates
agent-workspace sync
```

Potential meanings:

- `audit`: report whether current project has the expected Agent Workspace structure.
- `diff-templates`: compare generated files against the current source templates or local `.agent/templates` cache.
- `sync`: safely update instruction/template files, preferably with preview/dry-run first.

### 2. Multi-project commands

These operate across directories.

Candidate commands:

```bash
agent-workspace discover PATH...
agent-workspace audit PATH...
agent-workspace sync PATH...
```

Potential meanings:

- `discover`: find projects that appear to use Agent Workspace under one or more root paths.
- `audit PATH...`: check discovered or specified projects for structure/version/drift.
- `sync PATH...`: apply safe updates to specified projects, with explicit confirmation and no blind overwrites.

## Discovery ideas

Discovery should probably be based on a scoring/marker model, because older projects may not have a single canonical marker.

Possible signals:

Strong signals:

- `.agent/templates/`
- `bin/agent-workspace`
- `WORKFLOWS.md` matching Agent Workspace structure
- known adapter files generated from templates

Weak signals:

- `STATE.md`
- `BRAINSTORM.md`
- `AGENTS.md`
- `CLAUDE.md`
- `.cursor/rules/agent-workspace.mdc`

Possible output:

```text
/path/to/project-a  yes  .agent/templates, bin/agent-workspace, WORKFLOWS.md
/path/to/project-b  maybe  AGENTS.md, STATE.md, BRAINSTORM.md
/path/to/project-c  no
```

Open question: should Agent Workspace add a future explicit marker file, such as `.agent/workspace.json`, to make future discovery reliable?

## Sync/upgrade problem

This is the hardest part.

Blind copying is unsafe because projects often add project-specific instructions below or around generated content.

The desired behavior is similar to the manual process already used successfully:

1. compare current project files against old template/base version;
2. compare old template/base version against new template version;
3. detect local project-specific additions;
4. apply generic template improvements;
5. preserve local additions;
6. show a diff before finalizing.

Potential sync modes:

### Conservative mode

Default.

- Never overwrite active instruction files automatically.
- Update `.agent/templates/` cache only.
- Show which active files differ and need manual merge.

### Preview mode

- Generate proposed updated files into a temp/staging directory.
- Show diffs.
- User/agent reviews before applying.

### Apply mode

- Apply only safe, non-conflicting updates.
- Stop on conflicts or unclear local modifications.
- Require explicit flag such as `--apply`.

Possible flags:

```bash
agent-workspace sync --dry-run
agent-workspace sync --apply
agent-workspace sync --templates-only
agent-workspace sync --agent pi
agent-workspace sync --profile code
```

## Versioning / metadata issue

Current initialized projects do not appear to store which Agent Workspace template commit/version created them.

This makes future sync harder.

Possible future metadata file:

```text
.agent/workspace.json
```

Potential contents:

```json
{
  "version": 1,
  "source": "https://github.com/adiacov/agent-workspace",
  "templateRevision": "<git-sha-or-version>",
  "profile": "code",
  "agents": ["pi"],
  "generatedFiles": {
    "WORKFLOWS.md": "templates/default/WORKFLOWS.md",
    "AGENTS.md": "templates/adapters/pi/AGENTS.md",
    "ENGINEERING.md": "templates/profiles/software/ENGINEERING.md"
  }
}
```

Benefits:

- reliable discovery;
- easier audits;
- safer sync;
- reproducibility;
- clearer generated-file ownership.

Risks:

- adds complexity;
- existing projects need migration;
- metadata can become stale if users edit manually.

## Important boundaries

Agent Workspace should not become a personal project registry.

It should not know about `life-os`.

It should not know the meaning of the user's individual projects.

It should provide generic capabilities:

- initialize a project;
- add agent adapters;
- detect likely Agent Workspace projects;
- audit structure;
- compare/sync templates safely.

Project meaning, strategy, and cross-project planning remain outside Agent Workspace.

## MVP proposal for next phase

A reasonable next implementation phase should avoid solving full three-way merge immediately.

Suggested MVP:

1. Add explicit metadata for new projects:
   - `.agent/workspace.json`
   - records profile, selected agents, generated file mapping, and template revision when available.
2. Add `agent-workspace discover PATH...`:
   - recursively scans directories;
   - skips `.git`, `node_modules`, `.venv`, and common heavy/ignored folders;
   - reports projects with metadata or strong legacy signals.
3. Add `agent-workspace audit [PATH...]`:
   - for current or specified project(s);
   - reports missing core files, adapter files, template cache, and metadata;
   - identifies legacy projects without metadata.
4. Add `agent-workspace sync --templates-only [PATH...]`:
   - refreshes `.agent/templates/` from current source templates;
   - does not modify active instruction files.
5. Document manual safe merge workflow for active instruction files.

Only after this MVP is proven useful should Agent Workspace attempt active-file merge/sync.

## Non-goals for the next phase

- No automatic rewriting of active instruction files by default.
- No personal project registry.
- No dependency on `life-os`.
- No hidden knowledge of the user's private repo layout.
- No complex semantic merge in the first iteration.
- No hosted service.
- No GUI.

## Open questions

1. Should Agent Workspace become globally installable, or remain a project-local `bin/agent-workspace` script plus curl bootstrap?
2. Should there be a separate global command for discovery across the machine?
3. What default roots should discovery scan, if any, or should paths always be explicit?
4. Should `.agent/workspace.json` be gitignored or committed?
5. Should active generated files contain markers/comments to support future sync?
6. Should sync compare against remote `main`, a tagged version, or a user-specified local source path?
7. Should `bootstrap.sh` and `bin/agent-workspace` remain duplicated bash scripts, or should there be one source of truth with a release/copy step?
8. Should the CLI remain bash for portability, or move to another language if multi-project discovery/sync grows complex?

## Recommended next discussion

Decide the first real CLI expansion target:

```text
metadata + discover + audit
```

versus:

```text
sync existing projects
```

Recommendation: start with metadata/discover/audit first, because safe sync needs reliable project detection and generated-file ownership information.
