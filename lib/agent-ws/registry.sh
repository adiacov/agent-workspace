#!/usr/bin/env bash
# Global project registry: one absolute project path per line, so "which
# projects use agent-ws?" is a lookup instead of a filesystem hunt.
#
# Projects are registered when the tool touches them and confirms they are
# managed (init, migrate --apply, and any status/audit/sync/heal run that
# finds valid metadata). discover never writes the registry. Entries whose
# directory disappeared are pruned when the registry is listed.

agent_ws_registry_file() {
  if [ -n "${AGENT_WS_REGISTRY_FILE:-}" ]; then
    printf '%s\n' "$AGENT_WS_REGISTRY_FILE"
    return 0
  fi
  printf '%s/agent-ws/projects\n' "${XDG_DATA_HOME:-$HOME/.local/share}"
}

agent_ws_registry_add() {
  local project_root="$1" file
  file="$(agent_ws_registry_file)" || return 0
  if [ -f "$file" ] && grep -qxF "$project_root" "$file"; then
    return 0
  fi
  mkdir -p "$(dirname "$file")" 2>/dev/null || return 0
  printf '%s\n' "$project_root" >> "$file" 2>/dev/null || true
}

# Print registered project paths, sorted. Entries whose directory no longer
# exists are dropped from the file and not printed.
agent_ws_registry_list() {
  local file tmp path
  file="$(agent_ws_registry_file)"
  [ -f "$file" ] || return 0
  tmp="$file.tmp.$$"
  : > "$tmp"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    [ -d "$path" ] || continue
    printf '%s\n' "$path" >> "$tmp"
  done < <(sort -u "$file")
  mv "$tmp" "$file"
  cat "$file"
}
