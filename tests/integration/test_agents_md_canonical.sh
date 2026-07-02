#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

TMPBIN="$(mktemp -d)"
WORK="$(mktemp -d)"
export AGENT_WS_REGISTRY_FILE="$WORK/registry"
trap 'rm -rf "$TMPBIN" "$WORK"' EXIT

"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
AGENT_WS="$TMPBIN/bin/agent-ws"

# claude implies the canonical AGENTS.md plus a CLAUDE.md import shim.
mkdir -p "$WORK/claude-only"
(
  cd "$WORK/claude-only"
  "$AGENT_WS" init --profile general --agents claude --no-prompt >/dev/null
  assert_file_exists AGENTS.md
  assert_file_exists CLAUDE.md
  assert_contains '@AGENTS.md' CLAUDE.md
  python3 - .agent-workspace/workspace.json <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding='utf-8'))
gen = data['generatedFiles']
assert 'agent' not in gen['AGENTS.md'], gen['AGENTS.md']
assert gen['AGENTS.md']['template'] == 'adapters/AGENTS.md', gen['AGENTS.md']
assert gen['CLAUDE.md']['agent'] == 'claude', gen['CLAUDE.md']
PY
)

# Pre-v0.4.0 adapter records are upgraded: dry-run previews and leaves the
# metadata untouched; apply persists the rewrite and drops the retired cursor
# record (the file itself is preserved).
mkdir -p "$WORK/legacy-records"
(
  cd "$WORK/legacy-records"
  "$AGENT_WS" init --profile general --agents pi --no-prompt >/dev/null
  "$AGENT_WS" sync --apply >/dev/null
  mkdir -p .cursor/rules
  touch .cursor/rules/agent-workspace.mdc
  python3 - .agent-workspace/workspace.json <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding='utf-8'))
data['generatedFiles']['AGENTS.md'] = {"kind": "adapter", "agent": "pi", "template": "adapters/pi/AGENTS.md"}
data['generatedFiles']['.cursor/rules/agent-workspace.mdc'] = {"kind": "adapter", "agent": "cursor", "template": "adapters/cursor/.cursor/rules/agent-workspace.mdc"}
open(path, 'w', encoding='utf-8').write(json.dumps(data, indent=2, sort_keys=True) + '\n')
PY
  before="$(sha256sum .agent-workspace/workspace.json | awk '{print $1}')"
  "$AGENT_WS" sync --dry-run >dry.out
  assert_contains 'will be upgraded to the canonical AGENTS.md model' dry.out
  after="$(sha256sum .agent-workspace/workspace.json | awk '{print $1}')"
  test "$before" = "$after" || fail 'dry-run must not modify metadata'

  "$AGENT_WS" sync --apply >apply.out
  assert_contains 'upgraded 2 record(s) to the canonical AGENTS.md model' apply.out
  assert_contains 'no longer managed' apply.out
  assert_file_exists .cursor/rules/agent-workspace.mdc
  python3 - .agent-workspace/workspace.json <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding='utf-8'))
gen = data['generatedFiles']
assert gen['AGENTS.md']['template'] == 'adapters/AGENTS.md', gen['AGENTS.md']
assert 'agent' not in gen['AGENTS.md'], gen['AGENTS.md']
assert '.cursor/rules/agent-workspace.mdc' not in gen, sorted(gen)
PY
)

# heal restores a missing canonical AGENTS.md for a claude project and lands in-sync.
mkdir -p "$WORK/heal-claude"
(
  cd "$WORK/heal-claude"
  "$AGENT_WS" init --profile general --agents claude --no-prompt >/dev/null
  rm AGENTS.md
  "$AGENT_WS" heal --apply >heal.out
  assert_file_exists AGENTS.md
  assert_contains 'healed — the project is set up and in sync' heal.out
)
