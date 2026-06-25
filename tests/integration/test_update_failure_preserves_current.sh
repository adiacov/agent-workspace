#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"
trap 'rm -rf "$TMPBIN"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
before="$(sha256sum "$TMPBIN/bin/agent-ws" | awk '{print $1}')"
if "$TMPBIN/bin/agent-ws" update --version missing-version >"$TMPBIN/update.out" 2>&1; then
  fail 'missing update version should fail'
fi
after="$(sha256sum "$TMPBIN/bin/agent-ws" | awk '{print $1}')"
test "$before" = "$after" || fail 'failed update changed current command'
assert_contains 'preserved current command' "$TMPBIN/update.out"
"$TMPBIN/bin/agent-ws" help >/dev/null
