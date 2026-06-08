#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

TMPBIN="$(mktemp -d)"
PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$PROJECT"' EXIT

"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
(
  cd "$PROJECT"
  "$TMPBIN/bin/agent-ws" init --profile general --agents claude --no-prompt >/dev/null
  printf 'local pi/codex instructions\n' > AGENTS.md
  before="$(sha256sum AGENTS.md | awk '{print $1}')"
  "$TMPBIN/bin/agent-ws" add-agent --agents pi --no-prompt >add.out
  after="$(sha256sum AGENTS.md | awk '{print $1}')"
  test "$before" = "$after" || fail 'AGENTS.md was overwritten'
  assert_contains 'skip existing AGENTS.md' add.out
)
