#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

printf 'smoke: shell syntax\n'
bash -n \
  "$ROOT/bin/agent-ws" \
  "$ROOT/install.sh" \
  "$ROOT/bootstrap.sh" \
  "$ROOT"/lib/agent-ws/*.sh \
  "$ROOT"/tests/integration/*.sh \
  "$ROOT"/tests/smoke/*.sh

printf 'smoke: agent-ws help\n'
"$ROOT/bin/agent-ws" help >/dev/null

printf 'smoke: install.sh help\n'
"$ROOT/install.sh" --help >/dev/null

printf 'smoke: bootstrap transition message\n'
"$ROOT/bootstrap.sh" >/dev/null

if [ -x "$ROOT/tests/smoke/test_failure_messages.sh" ]; then
  printf 'smoke: failure message quality\n'
  "$ROOT/tests/smoke/test_failure_messages.sh"
fi

printf 'smoke: ok\n'
