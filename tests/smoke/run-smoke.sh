#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

printf 'smoke: version file\n'
[ -s "$ROOT/VERSION" ] || { printf 'error: VERSION is missing or empty\n' >&2; exit 1; }
grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$' "$ROOT/VERSION" || {
  printf 'error: VERSION must use vMAJOR.MINOR.PATCH format\n' >&2
  exit 1
}

printf 'smoke: shell syntax\n'
bash -n \
  "$ROOT/bin/agent-ws" \
  "$ROOT/install.sh" \
  "$ROOT"/lib/agent-ws/*.sh \
  "$ROOT"/tests/integration/*.sh \
  "$ROOT"/tests/smoke/*.sh

printf 'smoke: agent-ws help\n'
"$ROOT/bin/agent-ws" help >/dev/null

printf 'smoke: install.sh help\n'
"$ROOT/install.sh" --help >/dev/null

printf 'smoke: README lifecycle coverage\n'
for needle in \
  'curl -fsSL <install-url> | bash' \
  'AGENT_WS_VERSION=v0.1.0' \
  'agent-ws version' \
  'agent-ws update' \
  'Uninstall / cleanup' \
  'Supported platforms' \
  'vMAJOR.MINOR.PATCH'; do
  grep -F -- "$needle" "$ROOT/README.md" >/dev/null || {
    printf 'error: README missing lifecycle documentation: %s\n' "$needle" >&2
    exit 1
  }
done

for smoke_test in "$ROOT"/tests/smoke/test_*.sh; do
  [ -x "$smoke_test" ] || continue
  printf 'smoke: %s\n' "$(basename "$smoke_test")"
  "$smoke_test"
done

printf 'smoke: ok\n'
