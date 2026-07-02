#!/usr/bin/env bash
# Legacy project migration helpers for agent-ws.

agent_ws_migrate_has_file() {
  local project_root="$1" rel="$2"
  [ -e "$project_root/$rel" ]
}

agent_ws_migrate_preserved_files() {
  local project_root="$1" rel
  for rel in AGENTS.md CLAUDE.md .cursor/rules/agent-workspace.mdc PROJECT.md STATE.md MEMORY.md BRAINSTORM.md WORKFLOWS.md ENGINEERING.md PROJECTS.md PROFILE.md WORKFLOWS-COCKPIT.md; do
    if agent_ws_migrate_has_file "$project_root" "$rel"; then
      printf '%s\n' "$rel"
    fi
  done
}

agent_ws_migrate_generated_records() {
  local project_root="$1" records_file="$2" rel kind agent template
  while IFS= read -r rel; do
    kind="default"; agent=""; template=""
    case "$rel" in
      AGENTS.md) kind="adapter"; agent="pi"; template="adapters/pi/AGENTS.md" ;;
      CLAUDE.md) kind="adapter"; agent="claude"; template="adapters/claude/CLAUDE.md" ;;
      .cursor/rules/agent-workspace.mdc) kind="adapter"; agent="cursor"; template="adapters/cursor/.cursor/rules/agent-workspace.mdc" ;;
      PROJECT.md) kind="context"; template="default/PROJECT.md" ;;
      STATE.md) kind="context"; template="default/STATE.md" ;;
      WORKFLOWS.md) kind="default"; template="default/WORKFLOWS.md" ;;
      ENGINEERING.md) kind="profile"; template="profiles/software/ENGINEERING.md" ;;
      PROJECTS.md) kind="context"; template="profiles/cockpit/PROJECTS.md" ;;
      PROFILE.md) kind="context"; template="profiles/cockpit/PROFILE.md" ;;
      WORKFLOWS-COCKPIT.md) kind="profile"; template="profiles/cockpit/WORKFLOWS-COCKPIT.md" ;;
    esac
    [ -n "$template" ] && printf '%s|%s|%s|%s\n' "$rel" "$kind" "$template" "$agent" >> "$records_file"
  done < <(agent_ws_migrate_preserved_files "$project_root")
  return 0
}

# Infer the profile from the preserved files instead of assuming general:
# cockpit files win over ENGINEERING.md since a cockpit may also have one.
agent_ws_migrate_detect_profile() {
  local project_root="$1"
  if [ -e "$project_root/WORKFLOWS-COCKPIT.md" ] || [ -e "$project_root/PROJECTS.md" ]; then
    printf '%s\n' cockpit
  elif [ -e "$project_root/ENGINEERING.md" ]; then
    printf '%s\n' code
  else
    printf '%s\n' general
  fi
}

agent_ws_migrate_detect_agents() {
  local project_root="$1" agents=""
  [ -e "$project_root/AGENTS.md" ] && agents="${agents} pi"
  [ -e "$project_root/CLAUDE.md" ] && agents="${agents} claude"
  [ -e "$project_root/.cursor/rules/agent-workspace.mdc" ] && agents="${agents} cursor"
  printf '%s\n' "$agents" | awk '{$1=$1; print}'
}

agent_ws_migrate_project() {
  local project_root="$1" mode="$2" rel records_file generated_json agents profile
  project_root="$(agent_ws_existing_project_root "$project_root")"

  agent_ws_say "migration: $mode"
  agent_ws_say "project: $project_root"

  if [ -d "$project_root/.agent" ]; then
    agent_ws_say "legacy: .agent/"
  fi
  if [ -e "$project_root/bin/agent-workspace" ]; then
    agent_ws_say "legacy: bin/agent-workspace"
  fi
  agent_ws_say "old project-local template caches are ignored"

  while IFS= read -r rel; do
    [ -n "$rel" ] && agent_ws_say "preserve: $rel"
  done < <(agent_ws_migrate_preserved_files "$project_root")

  if [ ! -f "$(agent_ws_metadata_path "$project_root")" ]; then
    profile="$(agent_ws_migrate_detect_profile "$project_root")"
    if [ "$mode" = "dry-run" ]; then
      agent_ws_say "would create: .agent-workspace/workspace.json (profile: $profile)"
      agent_ws_advise "if this preview looks right, perform the migration with: agent-ws migrate --apply"
    else
      records_file="$(mktemp)"
      agent_ws_migrate_generated_records "$project_root" "$records_file"
      generated_json="$(agent_ws_metadata_generated_json_from_records "$records_file")"
      rm -f "$records_file"
      agents="$(agent_ws_migrate_detect_agents "$project_root")"
      agent_ws_metadata_write "$project_root" "$profile" "$agents" "$generated_json"
    fi
  else
    agent_ws_say "metadata: present"
  fi

  if [ -e "$project_root/bin/agent-workspace" ]; then
    if [ "$mode" = "dry-run" ]; then
      agent_ws_say "would remove: bin/agent-workspace"
      agent_ws_advise "if this preview looks right, perform the migration with: agent-ws migrate --apply"
    else
      rm -f "$project_root/bin/agent-workspace"
      agent_ws_say "removed: bin/agent-workspace"
    fi
  fi

  if [ "$mode" = "apply" ]; then
    agent_ws_say "preserved active files and context"
    agent_ws_advise "make the project sync-ready (seed baseline snapshots) with: agent-ws sync --apply"
    agent_ws_advise "review the result with: agent-ws status"
  fi
  agent_ws_advice_flush "nothing to migrate; the project is already on the current model."
}
