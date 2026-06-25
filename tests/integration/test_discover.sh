#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

TMPBIN="$(mktemp -d)"
SCAN="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$SCAN"' EXIT

"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
mkdir -p "$SCAN/managed" "$SCAN/legacy/.agent" "$SCAN/legacy/bin" "$SCAN/weak" "$SCAN/plain"
(cd "$SCAN/managed" && "$TMPBIN/bin/agent-ws" init --profile general --agents pi --no-prompt >/dev/null)
touch "$SCAN/legacy/bin/agent-workspace" "$SCAN/legacy/AGENTS.md"
touch "$SCAN/weak/AGENTS.md"
"$TMPBIN/bin/agent-ws" discover "$SCAN" >"$TMPBIN/discover.out"
assert_contains "$SCAN/managed strong" "$TMPBIN/discover.out"
assert_contains '.agent-workspace/workspace.json' "$TMPBIN/discover.out"
assert_contains "$SCAN/legacy strong" "$TMPBIN/discover.out"
assert_contains '.agent/' "$TMPBIN/discover.out"
assert_contains 'bin/agent-workspace' "$TMPBIN/discover.out"
assert_contains "$SCAN/weak uncertain" "$TMPBIN/discover.out"
if grep -F "$SCAN/plain" "$TMPBIN/discover.out" >/dev/null; then
  fail 'plain directory should not be reported'
fi
