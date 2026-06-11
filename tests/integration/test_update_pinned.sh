#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

make_test_workspace >/dev/null
trap cleanup_test_workspace EXIT

prefix="$(make_install_prefix "$TEST_TMPDIR")"
archive_dir="$TEST_TMPDIR/releases"
pinned="v0.3.0"
make_release_archive "$pinned" "$archive_dir" >/dev/null
"$ROOT/install.sh" --prefix "$prefix" >/dev/null

AGENT_WS_TEST_RELEASES="v0.2.0 $pinned" AGENT_WS_UPDATE_BASE_URL="file://$archive_dir" \
  "$prefix/bin/agent-ws" update --version "$pinned" >update.out

assert_contains "selected version: $pinned" update.out
"$prefix/bin/agent-ws" version >version.out
assert_contains "agent-ws $pinned" version.out
