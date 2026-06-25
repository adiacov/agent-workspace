#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

make_test_workspace >/dev/null
trap cleanup_test_workspace EXIT

prefix="$(make_install_prefix "$TEST_TMPDIR")"
"$ROOT/install.sh" --prefix "$prefix" >/dev/null
"$prefix/bin/agent-ws" help update >"$TEST_TMPDIR/help.out"

assert_contains 'Usage: agent-ws update' "$TEST_TMPDIR/help.out"
assert_contains '--version version' "$TEST_TMPDIR/help.out"
assert_contains 'preserves the current command' "$TEST_TMPDIR/help.out"
