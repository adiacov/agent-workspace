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
  "$TMPBIN/agent-ws" init --profile code --agents pi --no-prompt >init.out
  assert_file_exists WORKFLOWS.md
  assert_file_exists STATE.md
  assert_file_exists BRAINSTORM.md
  assert_file_exists .gitignore
  assert_file_exists ENGINEERING.md
  assert_file_exists AGENTS.md
  assert_file_exists .agent-workspace/workspace.json
  assert_contains 'created' init.out
)
