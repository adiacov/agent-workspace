#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

make_test_workspace >/dev/null
trap cleanup_test_workspace EXIT

prefix="$(make_install_prefix "$TEST_TMPDIR")"
"$ROOT/install.sh" --prefix "$prefix" >/dev/null
rm -f "$prefix/share/agent-ws/VERSION"

set +e
"$prefix/bin/agent-ws" version >"$TEST_TMPDIR/version.out" 2>&1
status=$?
set -e

[ "$status" -ne 0 ] || fail 'version should fail when installed VERSION is missing'
assert_contains 'unable to determine installed version' "$TEST_TMPDIR/version.out"
assert_contains 'next:' "$TEST_TMPDIR/version.out"
