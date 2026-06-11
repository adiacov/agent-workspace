#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

make_test_workspace >/dev/null
trap cleanup_test_workspace EXIT

prefix="$(make_install_prefix "$TEST_TMPDIR")"
"$ROOT/install.sh" --prefix "$prefix" >install.out

assert_executable "$prefix/bin/agent-ws"
assert_dir_exists "$prefix/lib/agent-ws"
assert_dir_exists "$prefix/share/agent-ws/templates"
assert_version_file_value "$(current_repo_version)" "$prefix/share/agent-ws/VERSION"
assert_contains 'installed agent-ws to' install.out
assert_contains 'installed version to' install.out
"$prefix/bin/agent-ws" help >/dev/null
