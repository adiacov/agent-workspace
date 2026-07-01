# Quickstart: the `cockpit` profile

Steer several separate project repos from one workspace.

```sh
mkdir my-cockpit && cd my-cockpit
agent-ws init --profile cockpit --agents pi --no-prompt
```

You get:

```
my-cockpit/            ← you steer from here
├── PROJECTS.md        index of the projects this cockpit coordinates
├── PROFILE.md         your goals + context (the "who/what am I steering")
├── STATE.md           current focus, cross-project (points at each repo's own STATE.md)
├── WORKFLOWS.md        how we work (base)
├── WORKFLOWS-COCKPIT.md  + control-room workflows (cross-project rule, explore→build→reflect, handoff ingest)
└── AGENTS.md          agent adapter
```

Then:

1. Fill `PROFILE.md` with your background, goals, and constraints.
2. List the projects you steer in `PROJECTS.md`, each pointing at its own repo + `STATE.md`.
3. Keep `STATE.md` as your current cross-project focus; let each project keep its own detail.

The cockpit points *at* your projects; your projects never depend on the cockpit.

## Verify

```sh
agent-ws audit          # every expected cockpit file present, partial state: no
```

## When to use which profile

- Building **one** thing → `agent-ws init --profile code`.
- Steering **many** things toward a goal → `agent-ws init --profile cockpit`.
