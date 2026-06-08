#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

TMPBIN="$(mktemp -d)"
SCAN="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$SCAN"' EXIT

"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
mkdir -p "$SCAN/node_modules/fake/.agent-workspace" "$SCAN/.git/fake/.agent-workspace" "$SCAN/.venv/fake/.agent-workspace" "$SCAN/dist/fake/.agent-workspace" "$SCAN/build/fake/.agent-workspace" "$SCAN/real/.agent-workspace"
printf '{}\n' > "$SCAN/node_modules/fake/.agent-workspace/workspace.json"
printf '{}\n' > "$SCAN/.git/fake/.agent-workspace/workspace.json"
printf '{}\n' > "$SCAN/.venv/fake/.agent-workspace/workspace.json"
printf '{}\n' > "$SCAN/dist/fake/.agent-workspace/workspace.json"
printf '{}\n' > "$SCAN/build/fake/.agent-workspace/workspace.json"
printf '{}\n' > "$SCAN/real/.agent-workspace/workspace.json"
"$TMPBIN/bin/agent-ws" discover "$SCAN" >discover.out
assert_contains "$SCAN/real strong" discover.out
for skipped in node_modules .git .venv dist build; do
  if grep -F "$SCAN/$skipped/fake" discover.out >/dev/null; then
    fail "discovery should skip $skipped"
  fi
done
