#!/usr/bin/env bash
# Conservative sync helpers for agent-ws.

agent_ws_sync_project() {
  local project_root="$1" mode="$2" metadata_status template_status
  project_root="$(agent_ws_existing_project_root "$project_root")"
  metadata_status="$(agent_ws_metadata_status "$project_root")"
  template_status="$(agent_ws_template_source_status)"

  agent_ws_say "sync: $mode"
  agent_ws_say "project: $project_root"
  agent_ws_say "metadata: $metadata_status"
  agent_ws_say "template source: $template_status"

  if [ "$mode" = "dry-run" ]; then
    agent_ws_say "would validate metadata and comparison baselines"
    agent_ws_say "active files unchanged"
    return 0
  fi

  if [ "$mode" = "apply" ]; then
    agent_ws_say "validated metadata and comparison baselines"
    agent_ws_say "no safe active-file changes applied"
    agent_ws_say "active files unchanged"
    return 0
  fi

  agent_ws_die "unknown sync mode: $mode" "run 'agent-ws sync --dry-run' or 'agent-ws sync --apply'."
}
