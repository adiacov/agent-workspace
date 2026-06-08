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
  printf 'local instructions\n' > AGENTS.md
  before="$(sha256sum AGENTS.md | awk '{print $1}')"
  "$TMPBIN/agent-ws" init --profile code --agents pi --no-prompt >init.out
  after="$(sha256sum AGENTS.md | awk '{print $1}')"
  test "$before" = "$after" || fail 'AGENTS.md was overwritten'
  assert_contains 'skip existing AGENTS.md' init.out
  "$TMPBIN/agent-ws" init --profile code --agents pi --no-prompt >rerun.out
  assert_contains 'skip existing WORKFLOWS.md' rerun.out
  assert_contains 'skip existing AGENTS.md' rerun.out
)
