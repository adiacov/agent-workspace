#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

TMPBIN="$(mktemp -d)"
WORK="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$WORK"' EXIT

"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
(
  cd "$WORK"
  "$TMPBIN/bin/agent-ws" init sample-project --profile general --agents claude --no-prompt >/dev/null
  assert_dir_exists sample-project
  assert_file_exists sample-project/WORKFLOWS.md
  assert_file_exists sample-project/STATE.md
  assert_file_exists sample-project/BRAINSTORM.md
  assert_file_exists sample-project/.gitignore
  assert_file_exists sample-project/CLAUDE.md
  assert_file_exists sample-project/.agent-workspace/workspace.json
  assert_not_exists sample-project/ENGINEERING.md
)
