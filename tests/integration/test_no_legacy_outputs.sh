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
  "$TMPBIN/bin/agent-ws" init --profile general --agents pi --no-prompt >/dev/null
  assert_not_exists .agent
  assert_not_exists .agent/templates
  assert_not_exists bin/agent-workspace
  assert_not_exists BRAINSTORM.md
  assert_file_exists PROJECT.md
  assert_file_exists STATE.md
  assert_file_exists .agent-workspace/workspace.json
)
