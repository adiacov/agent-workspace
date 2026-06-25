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
"$TMPBIN/bin/agent-ws" audit "$FIXTURES/managed" "$FIXTURES/partial" "$FIXTURES/legacy" >"$TMPBIN/audit.out"
assert_contains "Audit: $FIXTURES/managed" "$TMPBIN/audit.out"
assert_contains 'metadata: present' "$TMPBIN/audit.out"
assert_contains "Audit: $FIXTURES/partial" "$TMPBIN/audit.out"
assert_contains 'missing: STATE.md' "$TMPBIN/audit.out"
assert_contains 'metadata: missing' "$TMPBIN/audit.out"
assert_contains "Audit: $FIXTURES/legacy" "$TMPBIN/audit.out"
assert_contains 'metadata: legacy' "$TMPBIN/audit.out"
assert_contains 'legacy: .agent/' "$TMPBIN/audit.out"
assert_contains 'legacy: bin/agent-workspace' "$TMPBIN/audit.out"
