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
  # Agents that share the canonical AGENTS.md are deduplicated, not a conflict.
  "$TMPBIN/bin/agent-ws" init --profile general --agents pi,codex,cursor --no-prompt >init.out
  assert_file_exists AGENTS.md
  assert_not_exists .cursor
  test "$(grep -c 'created AGENTS.md' init.out)" -eq 1 || fail 'AGENTS.md should be created exactly once'

  # The same destination from different templates is refused before writing.
  if "$TMPBIN/bin/agent-ws" add-agent --agents claude,custom --custom-path CLAUDE.md --no-prompt >conflict.out 2>&1; then
    fail 'custom path colliding with CLAUDE.md should fail'
  fi
  assert_contains 'destination conflict' conflict.out
  assert_not_exists CLAUDE.md

  if "$TMPBIN/bin/agent-ws" add-agent --agents custom --custom-path AGENTS.md --no-prompt >conflict2.out 2>&1; then
    fail 'custom path colliding with AGENTS.md should fail'
  fi
  assert_contains 'destination conflict' conflict2.out
)
