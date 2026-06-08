#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"; PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$PROJECT"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
(
  cd "$PROJECT"
  printf 'code\nclaude\n' | "$TMPBIN/bin/agent-ws" init . >init.out 2>prompt.out
  assert_contains 'Project profile' prompt.out
  assert_contains 'Agents' prompt.out
  assert_file_exists ENGINEERING.md
  assert_file_exists CLAUDE.md
  python3 - .agent-workspace/workspace.json <<'PY'
import json
m=json.load(open('.agent-workspace/workspace.json'))
assert m['profile']=='code', m
assert m['agents']==['claude'], m
PY
)
