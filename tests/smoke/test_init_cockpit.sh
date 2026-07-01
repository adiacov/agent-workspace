#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

"$ROOT/bin/agent-ws" init "$WORK/cockpit" --profile cockpit --agents pi --no-prompt >/dev/null

for f in PROJECTS.md PROFILE.md STATE.md WORKFLOWS.md WORKFLOWS-COCKPIT.md AGENTS.md \
         .agent-workspace/workspace.json; do
  [ -f "$WORK/cockpit/$f" ] || { printf 'not ok: cockpit init missing %s\n' "$f" >&2; exit 1; }
done
[ -e "$WORK/cockpit/ENGINEERING.md" ] && { printf 'not ok: cockpit must not create ENGINEERING.md\n' >&2; exit 1; }

grep -F '"cockpit"' "$WORK/cockpit/.agent-workspace/workspace.json" >/dev/null \
  || { printf 'not ok: metadata missing profile cockpit\n' >&2; exit 1; }

printf 'init cockpit: ok\n'
