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
(cd "$SCAN/managed" && "$TMPBIN/agent-ws" init --profile general --agents pi --no-prompt >/dev/null)
touch "$SCAN/legacy/bin/agent-workspace" "$SCAN/legacy/AGENTS.md"
touch "$SCAN/weak/AGENTS.md"
"$TMPBIN/agent-ws" discover "$SCAN" >discover.out
assert_contains "$SCAN/managed strong" discover.out
assert_contains '.agent-workspace/workspace.json' discover.out
assert_contains "$SCAN/legacy strong" discover.out
assert_contains '.agent/' discover.out
assert_contains 'bin/agent-workspace' discover.out
assert_contains "$SCAN/weak uncertain" discover.out
if grep -F "$SCAN/plain" discover.out >/dev/null; then
  fail 'plain directory should not be reported'
fi
