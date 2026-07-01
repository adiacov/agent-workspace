#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

TMPBIN="$(mktemp -d)"
WORK="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$WORK"' EXIT

"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
(
  cd "$WORK"
  "$TMPBIN/bin/agent-ws" init cockpit-project --profile cockpit --agents pi --no-prompt >/dev/null

  # Full cockpit file set: general core + coordination layer + adapter.
  assert_file_exists cockpit-project/.gitignore
  assert_file_exists cockpit-project/PROJECT.md
  assert_file_exists cockpit-project/STATE.md
  assert_file_exists cockpit-project/WORKFLOWS.md
  assert_file_exists cockpit-project/WORKFLOWS-COCKPIT.md
  assert_file_exists cockpit-project/PROJECTS.md
  assert_file_exists cockpit-project/PROFILE.md
  assert_file_exists cockpit-project/AGENTS.md
  assert_file_exists cockpit-project/.agent-workspace/workspace.json
  # cockpit does not imply the code profile.
  assert_not_exists cockpit-project/ENGINEERING.md

  # STATE.md is the cross-cutting cockpit variant, and reaches coordination guidance.
  assert_contains 'cockpit' cockpit-project/STATE.md
  assert_contains 'WORKFLOWS-COCKPIT.md' cockpit-project/STATE.md

  # Base WORKFLOWS.md is byte-identical to the shipped template (not mutated for cockpit).
  cmp -s cockpit-project/WORKFLOWS.md "$ROOT/templates/default/WORKFLOWS.md" \
    || fail "cockpit WORKFLOWS.md must equal the base template"

  # Control-room workflows are present as distinct sections.
  assert_contains 'Cross-project rule' cockpit-project/WORKFLOWS-COCKPIT.md
  assert_contains 'Explore' cockpit-project/WORKFLOWS-COCKPIT.md
  assert_contains 'Handoff ingest' cockpit-project/WORKFLOWS-COCKPIT.md

  # Metadata records profile: cockpit and the correct kinds.
  meta=cockpit-project/.agent-workspace/workspace.json
  python3 - "$meta" <<'PY'
import json, sys
d = json.load(open(sys.argv[1], encoding='utf-8'))
assert d.get('profile') == 'cockpit', d.get('profile')
gf = d['generatedFiles']
assert gf['STATE.md']['kind'] == 'context', gf['STATE.md']
assert gf['STATE.md']['template'] == 'profiles/cockpit/STATE.md', gf['STATE.md']
assert gf['PROJECTS.md']['kind'] == 'context', gf['PROJECTS.md']
assert gf['PROFILE.md']['kind'] == 'context', gf['PROFILE.md']
assert gf['WORKFLOWS-COCKPIT.md']['kind'] == 'profile', gf['WORKFLOWS-COCKPIT.md']
print('metadata ok')
PY

  # Audit passes: every expected file present, no partial state.
  "$TMPBIN/bin/agent-ws" audit cockpit-project >audit.out
  assert_contains 'present: PROJECTS.md' audit.out
  assert_contains 'present: PROFILE.md' audit.out
  assert_contains 'present: WORKFLOWS-COCKPIT.md' audit.out
  assert_contains 'partial state: no' audit.out
  if grep -q '^missing:' audit.out; then fail "cockpit audit reported missing files"; fi
)

printf 'ok: init cockpit profile\n'
