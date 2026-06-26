#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/lib/agent-ws/templates.sh"

fail() { printf 'not ok: %s\n' "$*" >&2; exit 1; }

for kind in default profile adapter; do
  agent_ws_file_is_framework "$kind" || fail "$kind should be framework"
done
for kind in context "" other; do
  if agent_ws_file_is_framework "$kind"; then
    fail "$kind should NOT be framework"
  fi
done

printf 'ok: unit classify framework vs content\n'
