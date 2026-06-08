#!/usr/bin/env bash
# Workspace metadata read/write and validation helpers.

agent_ws_metadata_path() {
  local project_root="$1"
  printf '%s/.agent-workspace/workspace.json\n' "$project_root"
}

agent_ws_metadata_now() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

agent_ws_metadata_write() {
  local project_root="$1" profile="$2" agents="$3" generated_files_json="${4:-{}}"
  local metadata_dir metadata_file tmp now tool_version template_revision
  metadata_dir="$project_root/.agent-workspace"
  metadata_file="$metadata_dir/workspace.json"
  tmp="$metadata_file.tmp.$$"
  now="$(agent_ws_metadata_now)"
  tool_version="${AGENT_WS_VERSION:-unknown}"
  template_revision="${AGENT_WS_TEMPLATE_REVISION:-unknown}"
  mkdir -p "$metadata_dir"

  python3 - "$profile" "$agents" "$generated_files_json" "$now" "$tool_version" "$template_revision" > "$tmp" <<'PY'
import json, sys
profile, agents_raw, generated_raw, now, tool_version, template_revision = sys.argv[1:]
agents = [a for a in agents_raw.replace(',', ' ').split() if a]
try:
    generated = json.loads(generated_raw)
except json.JSONDecodeError:
    generated = {}
print(json.dumps({
    "schemaVersion": 1,
    "toolName": "agent-ws",
    "toolVersion": tool_version or "unknown",
    "templateRevision": template_revision or "unknown",
    "profile": profile or "general",
    "agents": agents,
    "generatedFiles": generated,
    "createdAt": now,
    "updatedAt": now,
}, indent=2, sort_keys=True))
PY
  mv "$tmp" "$metadata_file"
  agent_ws_say "created $metadata_file"
}

agent_ws_metadata_read() {
  local project_root="$1" metadata_file
  metadata_file="$(agent_ws_metadata_path "$project_root")"
  [ -f "$metadata_file" ] || return 1
  cat "$metadata_file"
}

agent_ws_metadata_validate_json() {
  local metadata_file="$1"
  [ -f "$metadata_file" ] || return 2
  python3 - "$metadata_file" <<'PY'
import json, sys
try:
    json.load(open(sys.argv[1], encoding='utf-8'))
except Exception:
    sys.exit(1)
PY
}

agent_ws_metadata_has_required_fields() {
  local metadata_file="$1"
  python3 - "$metadata_file" <<'PY'
import json, sys
required = {"schemaVersion", "toolName", "profile", "agents", "generatedFiles", "createdAt", "updatedAt"}
try:
    data = json.load(open(sys.argv[1], encoding='utf-8'))
except Exception:
    sys.exit(1)
missing = required - set(data)
if missing or data.get("toolName") != "agent-ws":
    sys.exit(1)
sys.exit(0)
PY
}

agent_ws_metadata_privacy_check() {
  local metadata_file="$1"
  python3 - "$metadata_file" <<'PY'
import json, re, sys
try:
    data = json.load(open(sys.argv[1], encoding='utf-8'))
except Exception:
    sys.exit(1)
text = json.dumps(data, sort_keys=True)
# Reject obvious machine-specific absolute paths and common secret-like keys.
if re.search(r'"(?:/[^"]+|[A-Za-z]:\\[^"]+)"', text):
    sys.exit(1)
if re.search(r'(?i)(secret|token|password|credential|private[_-]?key)', text):
    sys.exit(1)
if 'STATE.md:' in text or 'BRAINSTORM.md:' in text:
    sys.exit(1)
sys.exit(0)
PY
}

agent_ws_metadata_status() {
  local project_root="$1" metadata_file template_dir
  metadata_file="$(agent_ws_metadata_path "$project_root")"
  if [ ! -e "$metadata_file" ]; then
    if [ -d "$project_root/.agent" ] || [ -e "$project_root/bin/agent-workspace" ]; then
      printf '%s\n' legacy
    else
      printf '%s\n' missing
    fi
    return 0
  fi
  if ! agent_ws_metadata_validate_json "$metadata_file" || ! agent_ws_metadata_has_required_fields "$metadata_file" || ! agent_ws_metadata_privacy_check "$metadata_file"; then
    printf '%s\n' invalid
    return 0
  fi
  template_dir="$(agent_ws_template_source_dir 2>/dev/null || true)"
  if [ -z "$template_dir" ]; then
    printf '%s\n' stale
    return 0
  fi
  printf '%s\n' present
}
