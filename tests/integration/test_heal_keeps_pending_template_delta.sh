#!/usr/bin/env bash
set -euo pipefail

# Regression: healing an incomplete project must not stomp the baselines of
# files it skips. Recreating missing files used to rewrite every framework
# baseline to the current template, erasing the pending delta so the following
# sync reported "unchanged" and left stale active files behind.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=helpers.sh
. "$ROOT/tests/integration/helpers.sh"

TMPBIN="$(mktemp -d)"
WORK="$(mktemp -d)"
export AGENT_WS_REGISTRY_FILE="$WORK/registry"
trap 'rm -rf "$TMPBIN" "$WORK"' EXIT

"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
AGENT_WS="$TMPBIN/bin/agent-ws"

mkdir -p "$WORK/project"
(
  cd "$WORK/project"
  "$AGENT_WS" init --profile general --agents claude --no-prompt >/dev/null
  "$AGENT_WS" sync --apply >/dev/null

  # Publish a newer template set, then make the project incomplete.
  cp -R "$TMPBIN/share/agent-ws/templates" "$WORK/templates-next"
  printf '\nNEW TEMPLATE LINE\n' >> "$WORK/templates-next/adapters/claude/CLAUDE.md"
  rm AGENTS.md

  AGENT_WS_TEMPLATE_SOURCE_DIR="$WORK/templates-next" "$AGENT_WS" heal --apply >heal.out
  assert_file_exists AGENTS.md
  assert_contains 'CLAUDE.md: updated' heal.out
  assert_contains 'NEW TEMPLATE LINE' CLAUDE.md
)
