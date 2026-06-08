#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"; PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$PROJECT"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
(
  cd "$PROJECT"
  "$TMPBIN/agent-ws" init --profile general --agents pi --no-prompt >/dev/null
  before="$(sha256sum AGENTS.md | awk '{print $1}')"
  "$TMPBIN/agent-ws" sync --apply . >sync.out
  after="$(sha256sum AGENTS.md | awk '{print $1}')"
  test "$before" = "$after" || fail 'sync --apply changed active file'
  assert_contains 'sync: apply' sync.out
  assert_contains 'no safe active-file changes applied' sync.out
)
