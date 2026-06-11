# Workflows

This file is the primary workflow authority. Agent-specific adapter files should only bootstrap the agent into this file, not duplicate its rules.

## Start of session

1. Read the agent adapter/instruction file for the current tool if present.
2. Read durable memory if present, such as `MEMORY.md`.
3. Read `STATE.md` if present. Treat it as the single canonical current-context entrypoint.
4. Follow only the relevant pointers from `STATE.md`, plus files clearly required by the user's request.
5. Read `PROJECT.md` only when project purpose, users, boundaries, non-goals, or principles are needed.
6. Reconcile memory with reality before continuing work:

   * check `sessions/pending/` for raw checkpoint files;
   * inspect `git status` and recent commits;
   * inspect project files mentioned by `STATE.md`, such as active specs, plans, and READMEs;
   * inspect relevant local/external task state when current work mentions tasks;
   * compare these facts with project context/memory.
7. Treat memory as a hint, not a source of truth. Repository state, task systems, and current project files take precedence.
8. Do not blindly read unrelated historical specs, decisions, or implementation notes by default.
9. If durable memory is stale or contradicted by repo/task reality, update memory or project docs before continuing normal work.
10. If the task is unclear after reconciliation, ask what we are working on.
11. For coding or implementation work, read and follow `ENGINEERING.md` if present.

## Collaboration style

* Work as a collaborative partner, not an autonomous task executor.
* Prefer dialogue over assumptions when requirements, tradeoffs, priorities, or constraints are unclear.
* For non-trivial work, discuss the approach before implementation.
* Present one major decision at a time rather than large batches of options.
* Do not rush into implementation when understanding is incomplete.
* Challenge assumptions when evidence suggests a better approach.
* Keep communication concise and focused.
* When multiple reasonable approaches exist, explain the tradeoffs and recommend one.

## Pending checkpoint handling

If pending checkpoints exist:

1. review them before continuing normal work;
2. extract only durable goals, decisions, current state, next actions, blockers, and important realizations;
3. update project context/memory/docs as appropriate;
4. move processed checkpoint files to `sessions/archive/`.

Do not blindly copy raw conversation into durable memory.

Checkpoint files are raw recovery evidence, not curated memory. Manual durable-memory updates remain preferred when practical.

## Implementation workflow

When coding or editing files:

1. understand the request and affected area;
2. inspect existing files before proposing changes;
3. for non-trivial work, present a short plan;
4. explain intended changes briefly when useful;
5. make minimal, precise edits;
6. preserve existing content unless explicitly asked to reorganize it;
7. run relevant checks when possible;
8. summarize changed files, verification performed, and next steps.
