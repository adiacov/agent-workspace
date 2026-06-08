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
"$TMPBIN/agent-ws" audit "$FIXTURES/managed" "$FIXTURES/partial" "$FIXTURES/legacy" >audit.out
assert_contains "Audit: $FIXTURES/managed" audit.out
assert_contains 'metadata: present' audit.out
assert_contains "Audit: $FIXTURES/partial" audit.out
assert_contains 'missing: STATE.md' audit.out
assert_contains 'metadata: missing' audit.out
assert_contains "Audit: $FIXTURES/legacy" audit.out
assert_contains 'metadata: legacy' audit.out
assert_contains 'legacy: .agent/' audit.out
assert_contains 'legacy: bin/agent-workspace' audit.out
