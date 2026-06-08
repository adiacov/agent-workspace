#!/usr/bin/env bash
# Git/GitHub release update helpers for agent-ws.

agent_ws_update_is_stable_version() {
  local version="$1" lower
  lower="$(printf '%s' "$version" | tr '[:upper:]' '[:lower:]')"
  case "$lower" in
    *alpha*|*beta*|*rc*|*pre*) return 1 ;;
    *) return 0 ;;
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

  agent_ws_error "requested release is unavailable: $version"
  agent_ws_next "choose an available stable release or run 'agent-ws update --dry-run'."
  agent_ws_say "preserved current command"
  return 1
}
