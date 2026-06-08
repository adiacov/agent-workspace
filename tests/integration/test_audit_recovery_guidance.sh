#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

TMPBIN="$(mktemp -d)"
FIXTURES="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$FIXTURES"' EXIT

"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
build_fixture_matrix "$FIXTURES"
"$TMPBIN/agent-ws" audit "$FIXTURES/partial" >audit.out
assert_contains 'partial state: yes' audit.out
assert_contains 'recovery: run agent-ws init' audit.out
assert_contains 'active files and memory are preserved' audit.out
