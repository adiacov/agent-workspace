#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

assert_failure_has_next_action() {
  local name="$1"
  shift
  local output status
  set +e
  output="$($@ 2>&1)"
  status=$?
  set -e
  if [ "$status" -eq 0 ]; then
    printf 'not ok: %s succeeded but expected failure\n' "$name" >&2
    exit 1
  fi
  printf '%s\n' "$output" | grep -F 'error:' >/dev/null || {
    printf 'not ok: %s missing error explanation\n%s\n' "$name" "$output" >&2
    exit 1
  }
  printf '%s\n' "$output" | grep -F 'next:' >/dev/null || {
    printf 'not ok: %s missing next action\n%s\n' "$name" "$output" >&2
    exit 1
  }
}

assert_failure_has_next_action 'unknown command' "$ROOT/bin/agent-ws" does-not-exist
assert_failure_has_next_action 'unknown option' "$ROOT/bin/agent-ws" init --bad-option
assert_failure_has_next_action 'missing option value' "$ROOT/bin/agent-ws" init --profile

printf 'failure messages: ok\n'
