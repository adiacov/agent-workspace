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
  assert_file_exists .agent-workspace/workspace.json
  python3 - .agent-workspace/workspace.json <<'PY'
import json, re, sys
p=sys.argv[1]
data=json.load(open(p, encoding='utf-8'))
required={'schemaVersion','toolName','profile','agents','generatedFiles','createdAt','updatedAt'}
missing=required-set(data)
assert not missing, missing
assert data['toolName']=='agent-ws'
assert data['profile']=='code'
assert data['agents']==['pi']
for key in ['WORKFLOWS.md','STATE.md','BRAINSTORM.md','.gitignore','ENGINEERING.md','AGENTS.md']:
    assert key in data['generatedFiles'], key
text=json.dumps(data)
assert not re.search(r'"/[^"]+"', text), text
for forbidden in ['secret','token','password','credential']:
    assert forbidden not in text.lower(), forbidden
PY
)
