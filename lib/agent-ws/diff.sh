#!/usr/bin/env bash
# Active-file/template comparison helpers for agent-ws.

agent_ws_metadata_generated_paths() {
  local metadata_file="$1"
  python3 - "$metadata_file" <<'PY'
import json, sys
try:
    data=json.load(open(sys.argv[1], encoding='utf-8'))
except Exception:
    sys.exit(1)
for path, item in sorted((data.get('generatedFiles') or {}).items()):
    template=item.get('template')
    if template:
        print(f'{path}|{template}')
PY
}

agent_ws_diff_project() {
  local project_root="$1" metadata_file metadata_status template_dir line path template active template_file
  project_root="$(agent_ws_existing_project_root "$project_root")"
  metadata_file="$(agent_ws_metadata_path "$project_root")"
  metadata_status="$(agent_ws_metadata_status "$project_root")"
  agent_ws_say "Diff: $project_root"
  agent_ws_say "metadata: $metadata_status"
  if [ "$metadata_status" = "stale" ]; then
    agent_ws_say "note: active files remain project-owned"
  fi
  [ -f "$metadata_file" ] || { agent_ws_say "no metadata mappings available"; return 0; }
  template_dir="$(agent_ws_template_source_dir 2>/dev/null || true)"
  [ -n "$template_dir" ] || { agent_ws_say "template source: missing"; return 0; }

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    path="${line%%|*}"
    template="${line#*|}"
    active="$project_root/$path"
    template_file="$template_dir/$template"
    if [ ! -f "$active" ]; then
      agent_ws_say "missing active: $path"
    elif [ ! -f "$template_file" ]; then
      agent_ws_say "missing template: $template"
    elif cmp -s "$template_file" "$active"; then
      agent_ws_say "same: $path"
    else
      agent_ws_say "diff: $path"
      diff -u "$template_file" "$active" || true
    fi
  done <<< "$(agent_ws_metadata_generated_paths "$metadata_file" 2>/dev/null || true)"
}
