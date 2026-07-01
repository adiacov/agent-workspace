# Cockpit workflows

Control-room workflows for a **cockpit**: a single workspace that indexes, connects, and steers
several separate project repos over time. This file augments the base `WORKFLOWS.md` — the base
rules still apply; the sections below add the coordination layer. A cockpit's `STATE.md` points
here as authoritative for how to steer.

Core idea: one operator with every instrument in reach — watch the projects, decide the course,
keep the memory.

## Cross-project rule (dependency points one way)

- The cockpit may index and reason about sibling projects, but each sibling repo MUST stay
  understandable on its own.
- Dependency points one way only: **cockpit → projects, never projects → cockpit.** A project must
  never require the cockpit to build, run, or be understood.
- The cockpit holds coordination and continuity; each project holds its own implementation detail
  and its own `STATE.md`. Do not copy per-project detail into the cockpit — point at it.

## Explore → build → reflect loop

Use the cockpit to think; use a project repo to build.

1. **Explore (in the cockpit)** — frame the problem, weigh options, decide scope and whether it is
   worth doing. Idea-shaping and cross-project prioritization happen here.
2. **Build (in a separate project repo)** — once scope is decided, do the actual work in that
   project's own repo, with its own workflow and state. The cockpit does not accumulate build
   artifacts.
3. **Reflect (back in the cockpit)** — when a slice is done or stalls, return to record the
   outcome, update the project's coarse status in `PROJECTS.md` / `STATE.md`, and decide
   **continue / pivot / stop**.

The loop keeps exploration and execution in their proper homes and preserves continuity across
sessions and across agents.

## Handoff ingest (optional, manual ritual)

A project repo may carry a transient `HANDOFF.md`: a not-yet-integrated delta from its last
session (what changed, decisions, next steps), not project history. When you bring such a project
into cockpit focus, you may ingest it:

1. **Read** the project's `HANDOFF.md`.
2. **Verify** its claims against that repo's git reality (log, diff, current files). Repo reality
   wins over the handoff's prose — if they disagree, trust the repo.
3. **Integrate** only durable, still-relevant content into the cockpit (`PROJECTS.md` /
   cockpit `STATE.md`). Do not copy raw prose wholesale.
4. **Drain** it — mark the handoff processed in the project repo so it is not re-ingested.

This ritual is optional and manual. The cockpit's continuity comes from its own durable curated
files (`PROJECTS.md`, `PROFILE.md`, `STATE.md`); handoff ingest is a convenience for pulling a
project's latest delta up to the cockpit, not a required mechanism.
