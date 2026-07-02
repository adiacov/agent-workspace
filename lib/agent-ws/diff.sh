#!/usr/bin/env bash
# Incoming-delta preview for sync: shows what the current templates would bring
# into a project's framework files, i.e. baseline (template-then) -> template-now.
# This is the meaningful input to `sync`, not an unscoped active-vs-template diff.

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

# Emit a colorized unified diff unless NO_COLOR is set or output is not a TTY.
agent_ws_diff_render() {
  local from="$1" to="$2"
  if [ -n "${NO_COLOR:-}" ] || [ ! -t 1 ]; then
    diff -u "$from" "$to" || true
    return 0
  fi
  diff -u "$from" "$to" | while IFS= read -r dline; do
    case "$dline" in
      '+++ '*|'--- '*) printf '\033[1m%s\033[0m\n' "$dline" ;;
      '@@'*)           printf '\033[36m%s\033[0m\n' "$dline" ;;
      '+'*)            printf '\033[32m%s\033[0m\n' "$dline" ;;
      '-'*)            printf '\033[31m%s\033[0m\n' "$dline" ;;
      *)               printf '%s\n' "$dline" ;;
    esac
  done
  return 0
}

agent_ws_diff_project() {
  local project_root="$1" metadata_file metadata_status template_dir line path kind template template_file baseline
  local incoming=0 unseeded=0
  project_root="$(agent_ws_existing_project_root "$project_root")"
  metadata_file="$(agent_ws_metadata_path "$project_root")"
  metadata_status="$(agent_ws_metadata_status "$project_root")"
  agent_ws_say "Incoming template changes: $project_root"
  agent_ws_say "(what the installed templates would bring in, relative to the last sync)"
  agent_ws_say "metadata: $(agent_ws_metadata_status_gloss "$metadata_status")"
  if [ ! -f "$metadata_file" ]; then
    agent_ws_say "nothing to compare: this project has no workspace metadata"
    agent_ws_advise "adopt an existing project with: agent-ws migrate --dry-run, or set one up with: agent-ws init"
    agent_ws_advice_flush
    return 0
  fi
  template_dir="$(agent_ws_template_source_dir 2>/dev/null || true)"
  if [ -z "$template_dir" ]; then
    agent_ws_say "template source: missing — the global templates cannot be found"
    agent_ws_advise "reinstall agent-ws or set AGENT_WS_TEMPLATE_SOURCE_DIR"
    agent_ws_advice_flush
    return 0
  fi
  agent_ws_section "Files"

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    path="${line%%|*}"
    local rest="${line#*|}"
    kind="${rest%%|*}"
    template="${rest#*|}"
    template_file="$template_dir/$template"
    baseline="$(agent_ws_baseline_path "$project_root" "$path")"

    if ! agent_ws_file_is_framework "$kind"; then
      continue
    fi
    if [ ! -f "$template_file" ]; then
      agent_ws_say "  missing template: $template"
      continue
    fi
    if [ ! -f "$baseline" ]; then
      agent_ws_say "  no baseline: $path (run 'agent-ws sync --apply' to seed)"
      unseeded=$((unseeded + 1))
      continue
    fi
    if cmp -s "$baseline" "$template_file"; then
      agent_ws_say "  same: $path — up to date"
    else
      agent_ws_say "  incoming: $path — the template changed since the last sync:"
      agent_ws_diff_render "$baseline" "$template_file"
      incoming=$((incoming + 1))
    fi
  done <<< "$(agent_ws_metadata_generated_records "$metadata_file" 2>/dev/null || true)"

  if [ "$incoming" -gt 0 ]; then
    agent_ws_advise "merge the incoming template changes shown above with: agent-ws sync --apply (your local edits are preserved)"
  fi
  if [ "$unseeded" -gt 0 ]; then
    agent_ws_advise "some files have no baseline yet, so their delta cannot be shown; seed them with: agent-ws sync --apply"
  fi
  agent_ws_advice_flush "the project already matches the installed templates."
}
