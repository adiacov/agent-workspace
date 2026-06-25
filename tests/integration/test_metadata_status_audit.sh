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
"$TMPBIN/bin/agent-ws" audit "$FIXTURES/invalid-metadata" "$FIXTURES/stale-metadata" >"$TMPBIN/audit.out"
assert_contains "Audit: $FIXTURES/invalid-metadata" "$TMPBIN/audit.out"
assert_contains 'metadata: invalid' "$TMPBIN/audit.out"
assert_contains 'recovery: inspect or recreate .agent-workspace/workspace.json' "$TMPBIN/audit.out"
assert_contains "Audit: $FIXTURES/stale-metadata" "$TMPBIN/audit.out"
assert_contains 'metadata: stale' "$TMPBIN/audit.out"
assert_contains 'active files remain project-owned' "$TMPBIN/audit.out"
