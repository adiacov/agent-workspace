#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

make_test_workspace >/dev/null
trap cleanup_test_workspace EXIT

prefix="$(make_install_prefix "$TEST_TMPDIR")"
"$ROOT/install.sh" --prefix "$prefix" >/dev/null
before="$($prefix/bin/agent-ws version)"

set +e
AGENT_WS_TEST_RELEASES="v0.2.0" AGENT_WS_UPDATE_BASE_URL="file://$TEST_TMPDIR/missing" \
  "$prefix/bin/agent-ws" update >"$TEST_TMPDIR/update.out" 2>&1
status=$?
set -e

[ "$status" -ne 0 ] || fail 'update should fail when archive is missing'
after="$($prefix/bin/agent-ws version)"
[ "$before" = "$after" ] || fail 'failed update changed active version'
assert_contains 'update failed during download' "$TEST_TMPDIR/update.out"
assert_contains 'preserved current command' "$TEST_TMPDIR/update.out"
