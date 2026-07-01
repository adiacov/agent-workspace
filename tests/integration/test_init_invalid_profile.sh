#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

TMPBIN="$(mktemp -d)"
WORK="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$WORK"' EXIT

"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
(
  cd "$WORK"
  if "$TMPBIN/bin/agent-ws" init bad --profile nonsense --agents pi --no-prompt >out.txt 2>&1; then
    fail "invalid profile should exit non-zero"
  fi
  assert_contains 'unsupported profile: nonsense' out.txt
  # Remediation hint enumerates all three supported profiles.
  assert_contains 'cockpit' out.txt
  assert_contains 'general' out.txt
  assert_contains 'code' out.txt
)

printf 'ok: init invalid profile lists all profiles\n'
