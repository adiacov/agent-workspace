#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=../integration/helpers.sh
. "$ROOT/tests/integration/helpers.sh"

make_test_workspace >/dev/null
trap cleanup_test_workspace EXIT

prefix="$(make_install_prefix "$TEST_TMPDIR")"
"$ROOT/install.sh" --prefix "$prefix" >/dev/null

"$prefix/bin/agent-ws" version >version.out
assert_contains "agent-ws $(current_repo_version)" version.out

project="$TEST_TMPDIR/quickstart-project"
mkdir -p "$project"
(
  cd "$project"
  "$prefix/bin/agent-ws" init --profile general --agents pi --no-prompt >/dev/null
)

assert_file_exists "$project/WORKFLOWS.md"
assert_file_exists "$project/PROJECT.md"
assert_file_exists "$project/STATE.md"
assert_file_exists "$project/AGENTS.md"
assert_file_exists "$project/.agent-workspace/workspace.json"

printf 'release lifecycle quickstart: ok\n'
