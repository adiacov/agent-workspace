#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"; PROJECT="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$PROJECT"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
(
  cd "$PROJECT"
  "$TMPBIN/bin/agent-ws" init --profile general --agents pi --no-prompt >/dev/null
  python3 - .agent-workspace/workspace.json <<'PY'
import json, sys
p=sys.argv[1]
d=json.load(open(p))
d['templateRevision']='missing-test-revision'
open(p,'w').write(json.dumps(d))
PY
  "$TMPBIN/bin/agent-ws" diff . >diff.out
  assert_contains 'metadata: stale' diff.out
)
