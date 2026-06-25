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
AGENT_WS_VERSION="$version" \
AGENT_WS_TEST_RELEASES="v9.9.9 $version" \
AGENT_WS_INSTALL_BASE_URL="file://$archive_dir" \
  "$ROOT/install.sh" >"$TEST_TMPDIR/install.out"

assert_version_file_value "$version" "$prefix/share/agent-ws/VERSION"
"$prefix/bin/agent-ws" version >"$TEST_TMPDIR/version.out"
assert_contains "agent-ws $version" "$TEST_TMPDIR/version.out"
assert_contains "selected version: $version" "$TEST_TMPDIR/install.out"
