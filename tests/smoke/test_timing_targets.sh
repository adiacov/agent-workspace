#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TMPBIN="$(mktemp -d)"
PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$PROJECT"' EXIT

elapsed_seconds() {
  local start="$1" end
  end="$(date +%s)"
  printf '%s\n' "$((end - start))"
}

assert_under() {
  local label="$1" elapsed="$2" limit="$3"
  if [ "$elapsed" -gt "$limit" ]; then
    printf 'not ok: %s took %ss, expected <= %ss\n' "$label" "$elapsed" "$limit" >&2
    exit 1
  fi
}

"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null

start="$(date +%s)"
(cd "$PROJECT" && "$TMPBIN/agent-ws" init --profile code --agents pi --no-prompt >/dev/null)
assert_under 'init' "$(elapsed_seconds "$start")" 120

start="$(date +%s)"
(cd "$PROJECT" && "$TMPBIN/agent-ws" add-agent --agents claude --no-prompt >/dev/null)
assert_under 'add-agent' "$(elapsed_seconds "$start")" 60

start="$(date +%s)"
AGENT_WS_TEST_RELEASES='v1.0.0 v1.0.1 v2.0.0-rc1' "$TMPBIN/agent-ws" update --dry-run >/dev/null
assert_under 'update dry-run' "$(elapsed_seconds "$start")" 120

printf 'timing targets: ok\n'
