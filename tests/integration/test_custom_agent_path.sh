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
  "$TMPBIN/agent-ws" init --profile general --agents pi --no-prompt >/dev/null
  "$TMPBIN/agent-ws" add-agent --agents custom --custom-path docs/CUSTOM_AGENT.md --no-prompt >/dev/null
  assert_file_exists docs/CUSTOM_AGENT.md

  if "$TMPBIN/agent-ws" add-agent --agents custom --custom-path /tmp/bad.md --no-prompt >/tmp/custom-abs.out 2>&1; then
    fail 'absolute custom path should fail'
  fi
  assert_contains 'path must be relative' /tmp/custom-abs.out

  if "$TMPBIN/agent-ws" add-agent --agents custom --custom-path ../bad.md --no-prompt >/tmp/custom-parent.out 2>&1; then
    fail 'escaping custom path should fail'
  fi
  assert_contains 'must not escape' /tmp/custom-parent.out
)
