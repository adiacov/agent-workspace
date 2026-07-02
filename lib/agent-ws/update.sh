#!/usr/bin/env bash
# Git/GitHub release update helpers for agent-ws.

agent_ws_update_error() {
  local stage="$1" message="$2" next="${3:-retry after fixing the reported problem.}"
  agent_ws_error "update failed during $stage: $message"
  agent_ws_next "$next"
}

agent_ws_update_is_stable_version() {
  local version="$1" lower
  lower="$(printf '%s' "$version" | tr '[:upper:]' '[:lower:]')"
  case "$lower" in
    *alpha*|*beta*|*rc*|*pre*) return 1 ;;
    v[0-9]*.[0-9]*.[0-9]*) return 0 ;;
    *) return 1 ;;
  esac
}

agent_ws_update_release_list_contains() {
  local requested="$1" candidate
  [ -n "${AGENT_WS_TEST_RELEASES:-}" ] || return 0
  for candidate in ${AGENT_WS_TEST_RELEASES}; do
    [ "$candidate" = "$requested" ] && return 0
  done
  return 1
}

# List candidate release tags, one per line. AGENT_WS_TEST_RELEASES overrides
# the remote lookup for tests; otherwise query the repository's tags.
agent_ws_update_release_tags() {
  if [ -n "${AGENT_WS_TEST_RELEASES:-}" ]; then
    local version
    for version in ${AGENT_WS_TEST_RELEASES}; do
      printf '%s\n' "$version"
    done
    return 0
  fi
  git ls-remote --tags --refs "https://github.com/${AGENT_WS_REPO:-adiacov/agent-workspace}.git" 2>/dev/null \
    | awk -F 'refs/tags/' 'NF > 1 { print $2 }'
}

agent_ws_update_latest_stable() {
  local stable
  stable="$(
    agent_ws_update_release_tags | while IFS= read -r version; do
      if [ -n "$version" ] && agent_ws_update_is_stable_version "$version"; then
        printf '%s\n' "$version"
      fi
    done | sort -V | tail -n 1
  )"
  [ -n "$stable" ] || agent_ws_die "no stable release is available" "check network access to the release repository or provide --version for an available stable Git/GitHub tag."
  printf '%s\n' "$stable"
}

agent_ws_update_select_version() {
  local requested="${1:-}"
  if [ -n "$requested" ]; then
    agent_ws_update_is_stable_version "$requested" || {
      agent_ws_update_error "release resolution" "requested version is not a stable vMAJOR.MINOR.PATCH release: $requested" "choose a stable release such as v0.1.0."
      return 1
    }
    agent_ws_update_release_list_contains "$requested" || {
      agent_ws_update_error "release resolution" "requested release is unavailable: $requested" "choose an available stable release or run 'agent-ws update --dry-run'."
      return 1
    }
    printf '%s\n' "$requested"
    return 0
  fi
  agent_ws_update_latest_stable
}

agent_ws_update_stage_create() {
  mktemp -d "${TMPDIR:-/tmp}/agent-ws-update.XXXXXX"
}

agent_ws_update_stage_cleanup() {
  local stage="${1:-}"
  [ -n "$stage" ] && [ -d "$stage" ] && rm -rf "$stage"
}

agent_ws_update_active_prefix() {
  local bin_dir prefix
  bin_dir="$(cd "$AGENT_WS_BIN_DIR" && pwd -P)"
  case "$bin_dir" in
    */bin)
      prefix="$(cd "$bin_dir/.." && pwd -P)"
      printf '%s\n' "$prefix"
      ;;
    *)
      return 1
      ;;
  esac
}

agent_ws_update_archive_url() {
  local version="$1"
  if [ -n "${AGENT_WS_UPDATE_BASE_URL:-}" ]; then
    printf '%s/%s.tar.gz\n' "${AGENT_WS_UPDATE_BASE_URL%/}" "$version"
  else
    printf 'https://github.com/%s/archive/refs/tags/%s.tar.gz\n' "${AGENT_WS_REPO:-adiacov/agent-workspace}" "$version"
  fi
}

agent_ws_update_download_archive() {
  local version="$1" dst="$2" url
  url="$(agent_ws_update_archive_url "$version")"
  curl -fsSL "$url" -o "$dst" || {
    agent_ws_update_error "download" "unable to download $url" "check network access or choose an available --version."
    return 1
  }
}

agent_ws_update_is_payload_root() {
  local root="$1"
  [ -f "$root/bin/agent-ws" ] && [ -d "$root/lib/agent-ws" ] && [ -d "$root/templates" ] && [ -f "$root/VERSION" ]
}

agent_ws_update_payload_root_from_extract() {
  local extract_dir="$1" candidate
  if agent_ws_update_is_payload_root "$extract_dir"; then
    printf '%s\n' "$extract_dir"
    return 0
  fi
  for candidate in "$extract_dir"/*; do
    [ -d "$candidate" ] || continue
    if agent_ws_update_is_payload_root "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  agent_ws_update_error "staging" "downloaded archive does not contain an agent-ws payload" "check the selected release archive."
  return 1
}

agent_ws_update_copy_payload_to_stage() {
  local payload_root="$1" staged_prefix="$2"
  mkdir -p "$staged_prefix/bin" "$staged_prefix/lib" "$staged_prefix/share/agent-ws"
  cp "$payload_root/bin/agent-ws" "$staged_prefix/bin/agent-ws" || return 1
  chmod +x "$staged_prefix/bin/agent-ws" || return 1
  rm -rf "$staged_prefix/lib/agent-ws" "$staged_prefix/share/agent-ws/templates"
  cp -R "$payload_root/lib/agent-ws" "$staged_prefix/lib/agent-ws" || return 1
  cp -R "$payload_root/templates" "$staged_prefix/share/agent-ws/templates" || return 1
  cp "$payload_root/VERSION" "$staged_prefix/share/agent-ws/VERSION" || return 1
}

agent_ws_update_stage_from_archive() {
  local version="$1" stage="$2" staged_prefix="$3" archive extract_dir payload_root
  archive="$stage/release.tar.gz"
  extract_dir="$stage/extract"
  mkdir -p "$extract_dir"
  agent_ws_update_download_archive "$version" "$archive" || return 1
  tar -xzf "$archive" -C "$extract_dir" || {
    agent_ws_update_error "staging" "unable to extract release archive" "check that the selected release is a tar.gz archive."
    return 1
  }
  payload_root="$(agent_ws_update_payload_root_from_extract "$extract_dir")" || return 1
  agent_ws_update_copy_payload_to_stage "$payload_root" "$staged_prefix" || {
    agent_ws_update_error "staging" "unable to stage release payload" "check the selected release payload."
    return 1
  }
}

agent_ws_update_validate_candidate() {
  local candidate_prefix="$1" expected_version="${2:-}" command reported_version
  command="$candidate_prefix/bin/agent-ws"
  [ -x "$command" ] || {
    agent_ws_update_error "validation" "candidate command is not executable: $command" "check the release payload layout."
    return 1
  }
  reported_version="$($command version 2>/dev/null)" || {
    agent_ws_update_error "validation" "candidate command cannot report version" "check the staged payload before activation."
    return 1
  }
  if [ -n "$expected_version" ]; then
    # Whole-word match so expected v0.1.1 does not accept a candidate
    # reporting v0.1.10.
    case " $reported_version " in
      *" $expected_version "*) ;;
      *)
        agent_ws_update_error "validation" "candidate reported '$reported_version', expected $expected_version" "check the selected release payload."
        return 1
        ;;
    esac
  fi
}

agent_ws_update_replace_file() {
  local src="$1" dst="$2" tmp
  mkdir -p "$(dirname "$dst")"
  tmp="$dst.tmp.$$"
  cp "$src" "$tmp" || return 1
  mv "$tmp" "$dst" || return 1
}

agent_ws_update_replace_dir() {
  local src="$1" dst="$2" new="$2.new.$$" old="$2.old.$$"
  mkdir -p "$(dirname "$dst")"
  rm -rf "$new" "$old"
  cp -R "$src" "$new" || return 1
  if [ -e "$dst" ]; then
    mv "$dst" "$old" || return 1
  fi
  if ! mv "$new" "$dst"; then
    [ -e "$old" ] && mv "$old" "$dst" 2>/dev/null || true
    return 1
  fi
  rm -rf "$old"
}

agent_ws_update_activate_staged() {
  local staged_prefix="$1" prefix="$2"
  mkdir -p "$prefix/bin" "$prefix/lib" "$prefix/share/agent-ws" || return 1
  agent_ws_update_replace_file "$staged_prefix/bin/agent-ws" "$prefix/bin/agent-ws" || return 1
  chmod +x "$prefix/bin/agent-ws" || return 1
  agent_ws_update_replace_dir "$staged_prefix/lib/agent-ws" "$prefix/lib/agent-ws" || return 1
  agent_ws_update_replace_dir "$staged_prefix/share/agent-ws/templates" "$prefix/share/agent-ws/templates" || return 1
  agent_ws_update_replace_file "$staged_prefix/share/agent-ws/VERSION" "$prefix/share/agent-ws/VERSION" || return 1
}

agent_ws_update_command() {
  local requested="${1:-}" dry_run="${2:-0}" version stage staged_prefix prefix previous_version
  version="$(agent_ws_update_select_version "$requested")" || { agent_ws_say "preserved current command"; return 1; }
  if [ -n "$requested" ]; then
    agent_ws_say "selected version: $version"
  else
    agent_ws_say "latest stable: $version"
  fi

  if [ "$dry_run" -eq 1 ]; then
    agent_ws_say "update: dry-run"
    previous_version="$(agent_ws_installed_version 2>/dev/null || printf '%s' unknown)"
    if [ "$previous_version" = "$version" ]; then
      agent_ws_say "already up to date ($version); nothing to install"
    else
      agent_ws_say "would install: $version (currently $previous_version)"
      agent_ws_advise "install it with: agent-ws update"
    fi
    agent_ws_advice_flush
    return 0
  fi

  prefix="$(agent_ws_update_active_prefix)" || {
    agent_ws_update_error "activation" "unable to determine active install prefix" "run update from an installed agent-ws command."
    agent_ws_say "preserved current command"
    return 1
  }
  previous_version="$(agent_ws_installed_version 2>/dev/null || printf '%s' unknown)"
  stage="$(agent_ws_update_stage_create)"
  staged_prefix="$stage/prefix"

  if ! agent_ws_update_stage_from_archive "$version" "$stage" "$staged_prefix"; then
    agent_ws_update_stage_cleanup "$stage"
    agent_ws_say "preserved current command"
    return 1
  fi
  if ! agent_ws_update_validate_candidate "$staged_prefix" "$version"; then
    agent_ws_update_stage_cleanup "$stage"
    agent_ws_say "preserved current command"
    return 1
  fi
  if ! agent_ws_update_activate_staged "$staged_prefix" "$prefix"; then
    agent_ws_update_stage_cleanup "$stage"
    agent_ws_update_error "activation" "unable to activate staged update" "check write permissions for $prefix."
    agent_ws_say "preserved current command"
    return 1
  fi
  agent_ws_update_stage_cleanup "$stage"

  agent_ws_say "updated agent-ws $previous_version -> $version"
  agent_ws_say "installed at $prefix/bin/agent-ws"
}
