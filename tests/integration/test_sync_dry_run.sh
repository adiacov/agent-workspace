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
  printf '\n# Local project note\n' >> AGENTS.md
  before="$(sha256sum AGENTS.md | awk '{print $1}')"
  "$TMPBIN/bin/agent-ws" sync --dry-run . >sync.out
  after="$(sha256sum AGENTS.md | awk '{print $1}')"
  test "$before" = "$after" || fail 'sync --dry-run changed active file'
  assert_contains 'Sync preview:' sync.out
  # No incoming template change since init: framework files report unchanged,
  # and the local edit is preserved (sync never touches it).
  assert_contains 'AGENTS.md: unchanged' sync.out
)
