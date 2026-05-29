#!/usr/bin/env bash
set -euo pipefail

VERSION="0.1.0"

say() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }

write_file() {
  local path="$1"
  local content="$2"
  if [[ -e "$path" ]]; then
    say "skip: $path already exists"
    return 0
  fi
  mkdir -p "$(dirname "$path")"
  printf '%s' "$content" > "$path"
  say "create: $path"
}

core_collaboration() { cat <<'EOF'
# Collaboration Style

Work with me as a dialogue, not as a lecture.

Prefer:

- one important thing at a time
- concise responses unless detail is needed
- clarifying questions when direction is ambiguous
- concrete next actions after abstract discussion
- honest pushback when assumptions seem weak

Avoid:

- long monologues
- generic motivation
- dumping many options at once
- pretending certainty
- rushing to implementation before framing the problem

Act as a thinking partner, mentor, technical guide, implementation assistant, and accountability mirror.
EOF
}

core_memory() { cat <<'EOF'
# Memory Workflow

Use project files as durable memory instead of relying on chat history.

At the start of meaningful work, read these files if present:

1. `.agent/COLLABORATION.md`
2. `.agent/MEMORY.md`
3. `.agent/WORKFLOWS.md`
4. `STATE.md`
5. `BRAINSTORM.md`

File responsibilities:

- `STATE.md` — current situation, active work, next actions, blockers
- `BRAINSTORM.md` — durable reasoning, decisions, hypotheses, research findings
- `.agent/` — shared agent instructions and workflows

When a meaningful discussion or work session finishes:

- update `STATE.md` if the current situation changed
- update `BRAINSTORM.md` if durable insights were discovered
- avoid duplicating information across files
EOF
}

core_workflows() { cat <<'EOF'
# Workflows

## Start of session

1. Read the agent adapter file for the current tool.
2. Read shared instructions in `.agent/`.
3. Read `STATE.md` and `BRAINSTORM.md` if present.
4. Ask what we are working on if the task is unclear.

## Discussion workflow

1. Restate the problem simply.
2. Identify the current decision.
3. Ask one useful question if needed.
4. Suggest a small next step.

## Implementation workflow

1. Inspect existing files before changing them.
2. Explain intended changes briefly.
3. Make minimal, precise edits.
4. Run relevant checks when possible.
5. Summarize changed files and next steps.
EOF
}

state_template() { cat <<'EOF'
# STATE.md

## Purpose

Current project situation. Expected to change.

## Current focus

Not defined yet.

## Active work

Not defined yet.

## Next actions

- Define the project purpose.
EOF
}

brainstorm_template() { cat <<'EOF'
# BRAINSTORM.md

## Purpose

Durable project reasoning and long-term memory.

Preserve:

- observations
- decisions and rationale
- hypotheses
- research findings
- changes in direction

Avoid storing temporary state here.
EOF
}

gitignore_template() { cat <<'EOF'
.DS_Store
.env
.env.*
*.log

# Local/private identity or secrets
USER_PROFILE.md
LOCAL.md
PRIVATE.md
secrets/
*.pem
*.key

# Raw agent/session evidence may contain sensitive conversation
sessions/pending/*.md
sessions/archive/*.md

# Uncomment if project memory should stay private
# STATE.md
# BRAINSTORM.md
EOF
}

agents_adapter() { cat <<'EOF'
# AGENTS.md

Read and follow the shared workspace instructions:

1. `.agent/COLLABORATION.md`
2. `.agent/MEMORY.md`
3. `.agent/WORKFLOWS.md`

Then read project memory if present:

1. `STATE.md`
2. `BRAINSTORM.md`

Project-specific instructions may be added below.
EOF
}

claude_adapter() { cat <<'EOF'
# CLAUDE.md

Read and follow the shared workspace instructions:

1. `.agent/COLLABORATION.md`
2. `.agent/MEMORY.md`
3. `.agent/WORKFLOWS.md`

Then read project memory if present:

1. `STATE.md`
2. `BRAINSTORM.md`

Project-specific Claude Code instructions may be added below.
EOF
}

cursor_adapter() { cat <<'EOF'
---
description: Agent Workspace shared instructions
alwaysApply: true
---

Read and follow the shared workspace instructions:

- `.agent/COLLABORATION.md`
- `.agent/MEMORY.md`
- `.agent/WORKFLOWS.md`

Then read project memory if present:

- `STATE.md`
- `BRAINSTORM.md`
EOF
}

custom_adapter() {
  local name="$1"
  cat <<EOF
# ${name} Instructions

Read and follow the shared workspace instructions:

1. \`.agent/COLLABORATION.md\`
2. \`.agent/MEMORY.md\`
3. \`.agent/WORKFLOWS.md\`

Then read project memory if present:

1. \`STATE.md\`
2. \`BRAINSTORM.md\`

Project-specific instructions may be added below.
EOF
}

ensure_git_repo() {
  if ! command -v git >/dev/null 2>&1; then
    warn "git not found; skipping git init"
    return 0
  fi

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    say "skip: git repository already exists"
  else
    git init >/dev/null
    say "create: git repository"
  fi
}

create_core() {
  ensure_git_repo
  write_file ".gitignore" "$(gitignore_template)"
  write_file ".agent/COLLABORATION.md" "$(core_collaboration)"
  write_file ".agent/MEMORY.md" "$(core_memory)"
  write_file ".agent/WORKFLOWS.md" "$(core_workflows)"
  write_file "STATE.md" "$(state_template)"
  write_file "BRAINSTORM.md" "$(brainstorm_template)"
}

add_agent_named() {
  local agent="$1"
  case "$agent" in
    pi|codex|agents)
      write_file "AGENTS.md" "$(agents_adapter)"
      ;;
    claude)
      write_file "CLAUDE.md" "$(claude_adapter)"
      ;;
    cursor)
      write_file ".cursor/rules/agent-workspace.mdc" "$(cursor_adapter)"
      ;;
    custom)
      add_custom_agent
      ;;
    none|skip|'')
      ;;
    *)
      warn "unknown agent: $agent"
      warn "supported: pi, codex, claude, cursor, custom"
      return 1
      ;;
  esac
}

add_custom_agent() {
  local name path
  printf 'Custom agent name: '
  read -r name
  printf 'Instruction file path (example: GEMINI.md): '
  read -r path
  if [[ -z "${path}" ]]; then
    warn "path is required"
    return 1
  fi
  write_file "$path" "$(custom_adapter "${name:-Custom Agent}")"
}

select_agents() {
  say "Which agent adapter(s) should be added?"
  say "Options: pi, codex, claude, cursor, custom, none"
  printf 'Enter one or more, comma-separated [pi]: '
  read -r selected
  selected="${selected:-pi}"
  IFS=',' read -ra agents <<< "$selected"
  for agent in "${agents[@]}"; do
    agent="$(printf '%s' "$agent" | xargs)"
    add_agent_named "$agent"
  done
}

cmd_init() {
  create_core
  select_agents
  say "done"
}

cmd_add_agent() {
  select_agents
  say "done"
}

cmd_status() {
  say "Agent Workspace status"
  for path in ".agent/COLLABORATION.md" ".agent/MEMORY.md" ".agent/WORKFLOWS.md" "STATE.md" "BRAINSTORM.md" "AGENTS.md" "CLAUDE.md" ".cursor/rules/agent-workspace.mdc"; do
    if [[ -e "$path" ]]; then
      say "present: $path"
    else
      say "missing: $path"
    fi
  done
}

usage() { cat <<EOF
agent-workspace $VERSION

Usage:
  agent-workspace init
  agent-workspace add-agent
  agent-workspace status
  agent-workspace --help
EOF
}

main() {
  local cmd="${1:-init}"
  case "$cmd" in
    init) cmd_init ;;
    add-agent|agent-add) cmd_add_agent ;;
    status|doctor) cmd_status ;;
    -h|--help|help) usage ;;
    --version|version) say "$VERSION" ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
