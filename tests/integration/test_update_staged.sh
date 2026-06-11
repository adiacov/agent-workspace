#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

make_test_workspace >/dev/null
trap cleanup_test_workspace EXIT

prefix="$(make_install_prefix "$TEST_TMPDIR")"
archive_dir="$TEST_TMPDIR/releases"
new_version="v0.2.0"
make_release_archive "$new_version" "$archive_dir" >/dev/null
"$ROOT/install.sh" --prefix "$prefix" >/dev/null
before="$($prefix/bin/agent-ws version)"

AGENT_WS_TEST_RELEASES="$new_version" AGENT_WS_UPDATE_BASE_URL="file://$archive_dir" \
  "$prefix/bin/agent-ws" update >update.out

after="$($prefix/bin/agent-ws version)"
[ "$after" = "agent-ws $new_version" ] || fail "expected updated version $new_version, got $after"
assert_contains "updated agent-ws" update.out
assert_contains "$before" update.out
assert_contains "$new_version" update.out
assert_executable "$prefix/bin/agent-ws"
