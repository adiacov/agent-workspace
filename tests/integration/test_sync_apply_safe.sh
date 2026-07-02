#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"; PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$PROJECT"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
(
  cd "$PROJECT"
  "$TMPBIN/bin/agent-ws" init --profile general --agents pi --no-prompt >/dev/null
  before="$(sha256sum AGENTS.md | awk '{print $1}')"
  "$TMPBIN/bin/agent-ws" sync --apply . >sync.out
  after="$(sha256sum AGENTS.md | awk '{print $1}')"
  test "$before" = "$after" || fail 'sync --apply changed active file'
  assert_contains 'Sync:' sync.out
  # No incoming template change since init: nothing to merge, active file (with
  # its local edit) is left untouched.
  assert_contains 'AGENTS.md: unchanged' sync.out
  assert_contains 'sync complete' sync.out
)
