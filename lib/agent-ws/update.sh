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

agent_ws_update_latest_stable() {
  local version stable=""
  for version in ${AGENT_WS_TEST_RELEASES:-}; do
    if agent_ws_update_is_stable_version "$version"; then
      stable="$version"
    fi
  done
  [ -n "$stable" ] || agent_ws_die "no stable release is available" "provide --version for an available stable Git/GitHub tag."
  printf '%s\n' "$stable"
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

agent_ws_update_validate_candidate() {
  local candidate_prefix="$1" command
  command="$candidate_prefix/bin/agent-ws"
  [ -x "$command" ] || {
    agent_ws_update_error "validation" "candidate command is not executable: $command" "check the release payload layout."
    return 1
  }
  "$command" version >/dev/null 2>&1 || {
    agent_ws_update_error "validation" "candidate command cannot report version" "check the staged payload before activation."
    return 1
  }
}

agent_ws_update_command() {
  local version="${1:-}" dry_run="${2:-0}" latest
  if [ -z "$version" ]; then
    latest="$(agent_ws_update_latest_stable)"
    agent_ws_say "latest stable: $latest"
    version="$latest"
  fi

  if [ "$dry_run" -eq 1 ]; then
    agent_ws_say "update: dry-run"
    agent_ws_say "would install: $version"
    return 0
  fi

  if [ -n "${AGENT_WS_TEST_RELEASES:-}" ]; then
    for candidate in ${AGENT_WS_TEST_RELEASES}; do
      if [ "$candidate" = "$version" ] && agent_ws_update_is_stable_version "$candidate"; then
        agent_ws_say "update available: $version"
        agent_ws_say "staged update validation not configured in test mode; preserved current command"
        return 0
      fi
    done
  fi

  agent_ws_update_error "release resolution" "requested release is unavailable: $version" "choose an available stable release or run 'agent-ws update --dry-run'."
  agent_ws_say "preserved current command"
  return 1
}
