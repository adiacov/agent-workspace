#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

TMPBIN="$(mktemp -d)"
SCAN="$(mktemp -d)"
HOME_FAKE="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$SCAN" "$HOME_FAKE"' EXIT

"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
mkdir -p "$SCAN/managed/.agent-workspace"
printf '{}\n' > "$SCAN/managed/.agent-workspace/workspace.json"
HOME="$HOME_FAKE" "$TMPBIN/bin/agent-ws" discover "$SCAN" >discover.out
assert_contains "$SCAN/managed strong" discover.out
if find "$HOME_FAKE" -type f | grep . >/dev/null; then
  fail 'discover should not create a personal registry or state file'
fi
