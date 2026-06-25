#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

make_test_workspace >/dev/null
trap cleanup_test_workspace EXIT

prefix="$(make_install_prefix "$TEST_TMPDIR")"
"$ROOT/install.sh" --prefix "$prefix" >/dev/null
before="$($prefix/bin/agent-ws help)"

set +e
AGENT_WS_FORCE_REMOTE=1 \
AGENT_WS_PREFIX="$prefix" \
AGENT_WS_VERSION="v9.9.9" \
AGENT_WS_INSTALL_BASE_URL="file://$TEST_TMPDIR/missing-releases" \
  "$ROOT/install.sh" >"$TEST_TMPDIR/install.out" 2>&1
status=$?
set -e

[ "$status" -ne 0 ] || fail 'remote install should fail for missing archive'
after="$($prefix/bin/agent-ws help)"
[ "$before" = "$after" ] || fail 'failed remote install changed active command behavior'
assert_contains 'install failed during download' "$TEST_TMPDIR/install.out"
assert_executable "$prefix/bin/agent-ws"
