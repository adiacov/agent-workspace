#!/usr/bin/env bash
# Template source resolution, supported mappings, path validation, and safe copy helpers.

agent_ws_template_source_dir() {
  local candidate=""

  if [ -n "${AGENT_WS_TEMPLATE_SOURCE_DIR:-}" ]; then
    candidate="$AGENT_WS_TEMPLATE_SOURCE_DIR"
    [ -d "$candidate" ] || agent_ws_die "template source is unavailable: $candidate" "set AGENT_WS_TEMPLATE_SOURCE_DIR to a directory containing templates."
    cd "$candidate" && pwd -P
    return 0
  fi

  if [ -n "${AGENT_WS_RELEASE_TEMPLATE_DIR:-}" ]; then
    candidate="$AGENT_WS_RELEASE_TEMPLATE_DIR"
    [ -d "$candidate" ] || agent_ws_die "release template source is unavailable: $candidate" "select an available release template source."
    cd "$candidate" && pwd -P
    return 0
  fi

  # Repository checkout and current development install layout both resolve from
  # lib/agent-ws to ../../templates.
  candidate="$AGENT_WS_LIB_DIR/../../templates"
  if [ -d "$candidate" ]; then
    cd "$candidate" && pwd -P
    return 0
  fi

  # Future Linux-style install layout: <prefix>/lib/agent-ws with templates in
  # <prefix>/share/agent-ws/templates.
  candidate="$AGENT_WS_LIB_DIR/../../share/agent-ws/templates"
  if [ -d "$candidate" ]; then
    cd "$candidate" && pwd -P
    return 0
  fi

  agent_ws_die "unable to locate global template source" "reinstall agent-ws or set AGENT_WS_TEMPLATE_SOURCE_DIR."
}

agent_ws_template_revision() {
  local template_dir="$1"
  if git -C "$template_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$template_dir" rev-parse --short HEAD 2>/dev/null || printf '%s\n' unknown
  else
    printf '%s\n' "${AGENT_WS_TEMPLATE_REVISION:-unknown}"
  fi
}

agent_ws_require_template() {
  local rel="$1" source_dir
  source_dir="$(agent_ws_template_source_dir)"
  [ -f "$source_dir/$rel" ] || agent_ws_die "required template is missing: $rel" "restore templates or select a valid template source."
  printf '%s/%s\n' "$source_dir" "$rel"
}

agent_ws_safe_copy_skip() {
  local src="$1" dst="$2"
  [ -f "$src" ] || agent_ws_die "source file does not exist: $src" "restore templates before retrying."
  if [ -e "$dst" ]; then
    agent_ws_say "skip existing $dst"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  agent_ws_say "created $dst"
}

agent_ws_default_template_files() {
  printf '%s\n' \
    'default/.gitignore:.gitignore:default' \
    'default/PROJECT.md:PROJECT.md:context' \
    'default/STATE.md:STATE.md:context' \
    'default/WORKFLOWS.md:WORKFLOWS.md:default'
}

agent_ws_profile_template_files() {
  local profile="$1"
  case "$profile" in
    ''|general) return 0 ;;
    code) printf '%s\n' 'profiles/software/ENGINEERING.md:ENGINEERING.md:profile' ;;
    *) agent_ws_die "unsupported profile: $profile" "choose 'general' or 'code'." ;;
  esac
}

agent_ws_adapter_template() {
  local agent="$1" custom_path="${2:-}"
  case "$agent" in
    pi) printf '%s\n' 'adapters/pi/AGENTS.md:AGENTS.md:adapter:false' ;;
    codex) printf '%s\n' 'adapters/codex/AGENTS.md:AGENTS.md:adapter:false' ;;
    claude) printf '%s\n' 'adapters/claude/CLAUDE.md:CLAUDE.md:adapter:false' ;;
    cursor) printf '%s\n' 'adapters/cursor/.cursor/rules/agent-workspace.mdc:.cursor/rules/agent-workspace.mdc:adapter:false' ;;
    custom)
      [ -n "$custom_path" ] || agent_ws_die "custom agent requires --custom-path" "provide a project-root-relative custom instruction path."
      agent_ws_validate_project_relative_path "$custom_path" >/dev/null
      printf '%s:%s:%s:%s\n' 'adapters/custom/INSTRUCTIONS.md' "$custom_path" 'adapter' 'true'
      ;;
    *) agent_ws_die "unsupported agent: $agent" "choose pi, codex, claude, cursor, or custom." ;;
  esac
}

agent_ws_split_agents() {
  local raw="$1"
  printf '%s\n' "$raw" | tr ',' ' ' | tr ' ' '\n' | awk 'NF {print}'
}

agent_ws_validate_project_relative_path() {
  local path="$1"
  [ -n "$path" ] || agent_ws_die "path must not be empty" "provide a project-root-relative path."
  case "$path" in
    /*) agent_ws_die "path must be relative to the project root: $path" "remove the leading slash." ;;
    *'/../'*|'../'*|*'/..'|'..') agent_ws_die "path must not escape the project root: $path" "remove parent-directory traversal from the path." ;;
  esac
  printf '%s\n' "$path"
}

agent_ws_copy_template_spec() {
  local project_root="$1" rel="$2" dst_rel="$3" kind="$4" agent="${5:-}"
  local src dst
  agent_ws_validate_project_relative_path "$dst_rel" >/dev/null
  src="$(agent_ws_require_template "$rel")"
  dst="$project_root/$dst_rel"
  local created=0
  if [ -e "$dst" ]; then
    agent_ws_say "skip existing $dst_rel"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    agent_ws_say "created $dst_rel"
    created=1
  fi
  if [ -n "${AGENT_WS_GENERATED_RECORDS_FILE:-}" ]; then
    if [ "${AGENT_WS_RECORD_CREATED_ONLY:-0}" -eq 0 ] || [ "$created" -eq 1 ]; then
      printf '%s|%s|%s|%s\n' "$dst_rel" "$kind" "$rel" "$agent" >> "$AGENT_WS_GENERATED_RECORDS_FILE"
    fi
  fi
}

agent_ws_generate_default_files() {
  local project_root="$1" spec rel dst kind
  while IFS= read -r spec; do
    [ -n "$spec" ] || continue
    IFS=: read -r rel dst kind <<EOF
$spec
EOF
    agent_ws_copy_template_spec "$project_root" "$rel" "$dst" "$kind" ""
  done <<< "$(agent_ws_default_template_files)"
}

agent_ws_generate_profile_files() {
  local project_root="$1" profile="$2" spec rel dst kind
  while IFS= read -r spec; do
    [ -n "$spec" ] || continue
    IFS=: read -r rel dst kind <<EOF
$spec
EOF
    agent_ws_copy_template_spec "$project_root" "$rel" "$dst" "$kind" ""
  done <<< "$(agent_ws_profile_template_files "$profile")"
}

agent_ws_agent_destination_conflict_check() {
  local agents="$1" custom_path="${2:-}" agent spec rel dst kind requires_custom seen_file
  seen_file="$(mktemp)"
  while IFS= read -r agent; do
    [ -n "$agent" ] || continue
    spec="$(agent_ws_adapter_template "$agent" "$custom_path")"
    IFS=: read -r rel dst kind requires_custom <<EOF
$spec
EOF
    if awk -F '|' -v dst="$dst" '$1 == dst { found=1 } END { exit found ? 0 : 1 }' "$seen_file"; then
      rm -f "$seen_file"
      agent_ws_die "destination conflict for $dst" "select agents one at a time or choose a custom path that does not collide."
    fi
    printf '%s|%s|%s\n' "$dst" "$agent" "$rel" >> "$seen_file"
  done <<< "$(agent_ws_split_agents "$agents")"
  rm -f "$seen_file"
}

agent_ws_generate_agent_files() {
  local project_root="$1" agents="$2" custom_path="${3:-}" agent spec rel dst kind requires_custom
  agent_ws_agent_destination_conflict_check "$agents" "$custom_path"
  while IFS= read -r agent; do
    [ -n "$agent" ] || continue
    spec="$(agent_ws_adapter_template "$agent" "$custom_path")"
    IFS=: read -r rel dst kind requires_custom <<EOF
$spec
EOF
    agent_ws_copy_template_spec "$project_root" "$rel" "$dst" "$kind" "$agent"
  done <<< "$(agent_ws_split_agents "$agents")"
}
