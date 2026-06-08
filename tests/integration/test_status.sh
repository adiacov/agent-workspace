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
  "$TMPBIN/agent-ws" init --profile code --agents pi --no-prompt >/dev/null
  "$TMPBIN/agent-ws" status >status.out
  assert_contains 'Status:' status.out
  assert_contains 'metadata: present' status.out
  assert_contains 'template source: present' status.out
  assert_contains 'WORKFLOWS.md: present' status.out
  assert_contains 'ENGINEERING.md: present' status.out
  assert_contains 'AGENTS.md: present' status.out
)
