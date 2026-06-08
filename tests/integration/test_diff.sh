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
  printf '\n# Local project note\n' >> AGENTS.md
  "$TMPBIN/bin/agent-ws" diff . >diff.out
  after="$(sha256sum AGENTS.md | awk '{print $1}')"
  test "$before" != "$after" || fail 'test setup did not modify AGENTS.md'
  assert_contains 'diff: AGENTS.md' diff.out
  assert_contains '# Local project note' diff.out
  test "$after" = "$(sha256sum AGENTS.md | awk '{print $1}')" || fail 'diff modified active file'
)
