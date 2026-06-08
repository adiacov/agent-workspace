#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"; LEGACY="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$LEGACY"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
mkdir -p "$LEGACY/.agent" "$LEGACY/bin"
touch "$LEGACY/bin/agent-workspace" "$LEGACY/AGENTS.md" "$LEGACY/STATE.md" "$LEGACY/BRAINSTORM.md"
"$TMPBIN/bin/agent-ws" migrate --dry-run "$LEGACY" >migrate.out
assert_contains 'migration: dry-run' migrate.out
assert_contains 'legacy: .agent/' migrate.out
assert_contains 'legacy: bin/agent-workspace' migrate.out
assert_contains 'preserve: AGENTS.md' migrate.out
assert_contains 'preserve: STATE.md' migrate.out
assert_contains 'would create: .agent-workspace/workspace.json' migrate.out
assert_file_exists "$LEGACY/bin/agent-workspace"
assert_not_exists "$LEGACY/.agent-workspace/workspace.json"
