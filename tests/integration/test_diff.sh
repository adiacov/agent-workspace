#!/usr/bin/env bash
set -euo pipefail

# diff is read-only and reports the incoming template delta (baseline -> template),
# NOT local project edits. With no template change, framework files report "same"
# and a local edit does not appear.

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
  # Template unchanged since init => no incoming delta for framework files.
  assert_contains 'same: AGENTS.md' diff.out
  # The local edit is project-owned and must not show up as an incoming change.
  grep -F '# Local project note' diff.out && fail 'diff leaked local edit' || true
  # diff is read-only.
  after="$(sha256sum AGENTS.md | awk '{print $1}')"
  test "$before" != "$after" || fail 'test setup did not modify AGENTS.md'
)

printf 'ok: diff is read-only and shows incoming template delta only\n'
