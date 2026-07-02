#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"; LEGACY="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$LEGACY"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
mkdir -p "$LEGACY/.agent" "$LEGACY/bin"
printf 'local agent instructions\n' > "$LEGACY/AGENTS.md"
printf 'state memory\n' > "$LEGACY/STATE.md"
printf 'brainstorm memory\n' > "$LEGACY/BRAINSTORM.md"
touch "$LEGACY/bin/agent-workspace"
before_agents="$(sha256sum "$LEGACY/AGENTS.md" | awk '{print $1}')"
before_state="$(sha256sum "$LEGACY/STATE.md" | awk '{print $1}')"
"$TMPBIN/bin/agent-ws" migrate --apply "$LEGACY" >"$TMPBIN/migrate.out"
after_agents="$(sha256sum "$LEGACY/AGENTS.md" | awk '{print $1}')"
after_state="$(sha256sum "$LEGACY/STATE.md" | awk '{print $1}')"
test "$before_agents" = "$after_agents" || fail 'AGENTS.md changed during migration'
test "$before_state" = "$after_state" || fail 'STATE.md changed during migration'
assert_contains 'Migration:' "$TMPBIN/migrate.out"
assert_contains 'preserved active files and context' "$TMPBIN/migrate.out"
assert_file_exists "$LEGACY/.agent-workspace/workspace.json"
python3 - "$LEGACY/.agent-workspace/workspace.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1], encoding='utf-8'))
assert data['toolName']=='agent-ws'
assert data['profile']=='general'
PY
