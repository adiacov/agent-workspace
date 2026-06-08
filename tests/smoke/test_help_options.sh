#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

check_help() {
  local command="$1" needle="$2"
  "$ROOT/bin/agent-ws" help "$command" | grep -F -- "$needle" >/dev/null || {
    printf 'not ok: help %s missing %s\n' "$command" "$needle" >&2
    exit 1
  }
}

check_help init '--profile general|code'
check_help init '--agents list'
check_help init '--no-prompt'
check_help add-agent '--custom-path path'
check_help sync 'Use migrate, not sync'
check_help migrate 'older project-local model'
check_help update '--version version'
printf 'help options: ok\n'
