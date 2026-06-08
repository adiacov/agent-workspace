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

for smoke_test in "$ROOT"/tests/smoke/test_*.sh; do
  [ -x "$smoke_test" ] || continue
  printf 'smoke: %s\n' "$(basename "$smoke_test")"
  "$smoke_test"
done

printf 'smoke: ok\n'
