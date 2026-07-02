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
  "$TMPBIN/bin/agent-ws" init --profile general --agents pi --no-prompt >/dev/null
  assert_not_exists CLAUDE.md
  "$TMPBIN/bin/agent-ws" add-agent --agents claude --no-prompt >add.out
  assert_file_exists CLAUDE.md
  assert_contains 'created CLAUDE.md' add.out
  assert_contains '@AGENTS.md' CLAUDE.md
  python3 - .agent-workspace/workspace.json <<'PY'
import json, sys
data=json.load(open(sys.argv[1], encoding='utf-8'))
assert 'claude' in data['agents'], data['agents']
assert 'CLAUDE.md' in data['generatedFiles'], data['generatedFiles']
assert data['generatedFiles']['CLAUDE.md']['agent'] == 'claude'
PY
)
