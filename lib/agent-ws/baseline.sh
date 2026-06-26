#!/usr/bin/env bash
# Per-project baseline snapshots: the template content a project last synced from.
# The baseline is the BASE input to the three-way merge in merge.sh. It is a local,
# gitignored working artifact (one file per synced framework file).

agent_ws_baseline_dir() {
  local project_root="$1"
  printf '%s/.agent-workspace/baseline\n' "$project_root"
}

agent_ws_baseline_path() {
  local project_root="$1" active_rel="$2"
  printf '%s/.agent-workspace/baseline/%s\n' "$project_root" "$active_rel"
}

agent_ws_baseline_exists() {
  local project_root="$1" active_rel="$2"
  [ -f "$(agent_ws_baseline_path "$project_root" "$active_rel")" ]
}

# Snapshot a template file as the baseline for an active path.
agent_ws_baseline_write() {
  local project_root="$1" active_rel="$2" template_file="$3" dst
  [ -f "$template_file" ] || return 1
  dst="$(agent_ws_baseline_path "$project_root" "$active_rel")"
  mkdir -p "$(dirname "$dst")"
  cp "$template_file" "$dst"
}

# Ensure the project's .gitignore excludes baselines and transient sync artifacts.
# Idempotent; used when seeding a baseline into a pre-existing project (FR-017).
agent_ws_ensure_gitignore() {
  local project_root="$1" gitignore="$project_root/.gitignore" entry
  local entries=('.agent-workspace/baseline/' '*.bak' '*.merge')
  for entry in "${entries[@]}"; do
    if [ -f "$gitignore" ] && grep -qxF "$entry" "$gitignore"; then
      continue
    fi
    if [ ! -f "$gitignore" ]; then
      printf '# Agent Workspace sync working files\n' > "$gitignore"
    fi
    printf '%s\n' "$entry" >> "$gitignore"
  done
}
