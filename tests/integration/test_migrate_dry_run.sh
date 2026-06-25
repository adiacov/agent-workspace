#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"; LEGACY="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$LEGACY"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
mkdir -p "$LEGACY/.agent" "$LEGACY/bin"
touch "$LEGACY/bin/agent-workspace" "$LEGACY/AGENTS.md" "$LEGACY/STATE.md" "$LEGACY/BRAINSTORM.md"
"$TMPBIN/bin/agent-ws" migrate --dry-run "$LEGACY" >"$TMPBIN/migrate.out"
assert_contains 'migration: dry-run' "$TMPBIN/migrate.out"
assert_contains 'legacy: .agent/' "$TMPBIN/migrate.out"
assert_contains 'legacy: bin/agent-workspace' "$TMPBIN/migrate.out"
assert_contains 'preserve: AGENTS.md' "$TMPBIN/migrate.out"
assert_contains 'preserve: STATE.md' "$TMPBIN/migrate.out"
assert_contains 'would create: .agent-workspace/workspace.json' "$TMPBIN/migrate.out"
assert_file_exists "$LEGACY/bin/agent-workspace"
assert_not_exists "$LEGACY/.agent-workspace/workspace.json"
