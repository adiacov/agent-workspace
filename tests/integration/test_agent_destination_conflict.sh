#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

TMPBIN="$(mktemp -d)"
PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$PROJECT"' EXIT

"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
(
  cd "$PROJECT"
  "$TMPBIN/agent-ws" init --profile general --agents claude --no-prompt >/dev/null
  if "$TMPBIN/agent-ws" add-agent --agents pi,codex --no-prompt >conflict.out 2>&1; then
    fail 'duplicate destination should fail before writing'
  fi
  assert_contains 'destination conflict' conflict.out
  assert_not_exists AGENTS.md
)
