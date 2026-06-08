#!/usr/bin/env bash
# Project health audit helpers for agent-ws.

agent_ws_audit_metadata_profile() {
  local project_root="$1" metadata_file
  metadata_file="$(agent_ws_metadata_path "$project_root")"
  if [ -f "$metadata_file" ] && agent_ws_metadata_validate_json "$metadata_file" >/dev/null 2>&1; then
    python3 - "$metadata_file" <<'PY'
import json, sys
try:
    print(json.load(open(sys.argv[1], encoding='utf-8')).get('profile') or 'general')
except Exception:
    print('general')
PY
  else
    printf '%s\n' general
  fi
}

agent_ws_audit_metadata_agents() {
  local project_root="$1" metadata_file
  metadata_file="$(agent_ws_metadata_path "$project_root")"
  if [ -f "$metadata_file" ] && agent_ws_metadata_validate_json "$metadata_file" >/dev/null 2>&1; then
    python3 - "$metadata_file" <<'PY'
import json, sys
try:
    print(' '.join(json.load(open(sys.argv[1], encoding='utf-8')).get('agents') or []))
except Exception:
    print('')
PY
  fi
}

agent_ws_audit_expected_files() {
  local project_root="$1" profile agents spec rel dst kind agent adapter dst2 req
  profile="$(agent_ws_audit_metadata_profile "$project_root")"
  agents="$(agent_ws_audit_metadata_agents "$project_root")"
  [ -n "$agents" ] || agents="pi"

  while IFS= read -r spec; do
    [ -n "$spec" ] || continue
    IFS=: read -r rel dst kind <<EOF
$spec
EOF
    printf '%s\n' "$dst"
  done <<< "$(agent_ws_default_template_files)"

  while IFS= read -r spec; do
    [ -n "$spec" ] || continue
    IFS=: read -r rel dst kind <<EOF
$spec
EOF
    printf '%s\n' "$dst"
  done <<< "$(agent_ws_profile_template_files "$profile")"

  while IFS= read -r agent; do
    [ -n "$agent" ] || continue
    [ "$agent" = "custom" ] && continue
    adapter="$(agent_ws_adapter_template "$agent")"
    IFS=: read -r rel dst2 kind req <<EOF
$adapter
EOF
    printf '%s\n' "$dst2"
  done <<< "$(agent_ws_split_agents "$agents")"
}

agent_ws_template_source_status() {
  if agent_ws_template_source_dir >/dev/null 2>&1; then
    printf '%s\n' present
  else
    printf '%s\n' missing
  fi
}

agent_ws_status_project() {
  local project_root="$1" metadata_status template_status file
  project_root="$(agent_ws_existing_project_root "$project_root")"
  metadata_status="$(agent_ws_metadata_status "$project_root")"
  template_status="$(agent_ws_template_source_status)"

  agent_ws_say "Status: $project_root"
  agent_ws_say "metadata: $metadata_status"
  agent_ws_say "template source: $template_status"
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    if [ -e "$project_root/$file" ]; then
      agent_ws_say "$file: present"
    else
      agent_ws_say "$file: missing"
    fi
  done <<< "$(agent_ws_audit_expected_files "$project_root")"
  if [ -d "$project_root/.agent" ]; then
    agent_ws_say "legacy: .agent/"
  fi
  if [ -e "$project_root/bin/agent-workspace" ]; then
    agent_ws_say "legacy: bin/agent-workspace"
  fi
}

agent_ws_audit_project() {
  local project_root="$1" metadata_status template_status file missing_count=0 legacy_count=0
  project_root="$(agent_ws_existing_project_root "$project_root")"
  metadata_status="$(agent_ws_metadata_status "$project_root")"
  template_status="$(agent_ws_template_source_status)"

  agent_ws_say "Audit: $project_root"
  agent_ws_say "metadata: $metadata_status"
  agent_ws_say "template source: $template_status"

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    if [ -e "$project_root/$file" ]; then
      agent_ws_say "present: $file"
    else
      agent_ws_say "missing: $file"
      missing_count=$((missing_count + 1))
    fi
  done <<< "$(agent_ws_audit_expected_files "$project_root")"

  if [ -d "$project_root/.agent" ]; then
    agent_ws_say "legacy: .agent/"
    legacy_count=$((legacy_count + 1))
  fi
  if [ -e "$project_root/bin/agent-workspace" ]; then
    agent_ws_say "legacy: bin/agent-workspace"
    legacy_count=$((legacy_count + 1))
  fi

  if [ "$missing_count" -gt 0 ] || [ "$metadata_status" = "missing" ]; then
    agent_ws_say "partial state: yes"
    agent_ws_say "recovery: run agent-ws init with the intended profile and agents; active files and memory are preserved"
  else
    agent_ws_say "partial state: no"
  fi

  case "$metadata_status" in
    invalid)
      agent_ws_say "recovery: inspect or recreate .agent-workspace/workspace.json; active files remain project-owned"
      ;;
    stale)
      agent_ws_say "recovery: refresh templates or update metadata references; active files remain project-owned"
      ;;
    legacy)
      agent_ws_say "recovery: run agent-ws migrate --dry-run before removing legacy files"
      ;;
  esac

  if [ "$template_status" = "missing" ]; then
    agent_ws_say "recovery: reinstall agent-ws or set AGENT_WS_TEMPLATE_SOURCE_DIR"
  fi

  if [ "$legacy_count" -eq 0 ]; then
    agent_ws_say "legacy: none"
  fi
}
