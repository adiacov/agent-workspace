#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

make_test_workspace >/dev/null
trap cleanup_test_workspace EXIT

version="$(current_repo_version)"
archive_dir="$TEST_TMPDIR/releases"
make_release_archive "$version" "$archive_dir" >/dev/null
prefix="$(make_install_prefix "$TEST_TMPDIR")"

AGENT_WS_FORCE_REMOTE=1 \
AGENT_WS_PREFIX="$prefix" \
AGENT_WS_TEST_RELEASES="v0.0.9-alpha $version v9.9.9-rc1" \
AGENT_WS_INSTALL_BASE_URL="file://$archive_dir" \
  "$ROOT/install.sh" >install.out

assert_executable "$prefix/bin/agent-ws"
assert_dir_exists "$prefix/lib/agent-ws"
assert_dir_exists "$prefix/share/agent-ws/templates"
assert_version_file_value "$version" "$prefix/share/agent-ws/VERSION"
assert_contains "latest stable: $version" install.out
"$prefix/bin/agent-ws" help >/dev/null
