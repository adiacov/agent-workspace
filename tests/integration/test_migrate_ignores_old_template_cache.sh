#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"; LEGACY="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$LEGACY"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
mkdir -p "$LEGACY/.agent/templates/default" "$LEGACY/bin"
printf 'do not inspect me\n' > "$LEGACY/.agent/templates/default/SECRET_SENTINEL.md"
touch "$LEGACY/bin/agent-workspace" "$LEGACY/AGENTS.md" "$LEGACY/STATE.md" "$LEGACY/BRAINSTORM.md"
"$TMPBIN/bin/agent-ws" migrate --dry-run "$LEGACY" >migrate.out
assert_contains 'old project-local template caches are ignored' migrate.out
if grep -F 'SECRET_SENTINEL' migrate.out >/dev/null; then
  fail 'migration inspected old project-local template cache contents'
fi
assert_file_exists "$LEGACY/.agent/templates/default/SECRET_SENTINEL.md"
