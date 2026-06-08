#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"
trap 'rm -rf "$TMPBIN"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
AGENT_WS_TEST_RELEASES='v1.0.0 v1.1.0-alpha v1.1.0-beta v1.1.0-rc1 v1.0.1 v2.0.0' "$TMPBIN/agent-ws" update --dry-run >update.out
assert_contains 'latest stable: v2.0.0' update.out
if grep -E 'latest stable: .*alpha|latest stable: .*beta|latest stable: .*rc' update.out >/dev/null; then
  fail 'pre-release selected as latest stable'
fi
