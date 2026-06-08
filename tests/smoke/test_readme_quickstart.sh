#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
README="$ROOT/README.md"

for needle in \
  './install.sh' \
  'agent-ws init' \
  'agent-ws add-agent --agents claude --no-prompt' \
  '.agent-workspace/workspace.json' \
  'agent-ws migrate --dry-run' \
  'old project-local template caches'; do
  grep -F "$needle" "$README" >/dev/null || {
    printf 'not ok: README missing quickstart content: %s\n' "$needle" >&2
    exit 1
  }
done

TMPBIN="$(mktemp -d)"
TMPPROJECT="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$TMPPROJECT"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
(
  cd "$TMPPROJECT"
  "$TMPBIN/bin/agent-ws" init --profile code --agents pi --no-prompt >/dev/null
  "$TMPBIN/bin/agent-ws" add-agent --agents claude --no-prompt >/dev/null
  test -f .agent-workspace/workspace.json
  test -f AGENTS.md
  test -f CLAUDE.md
)
printf 'README quickstart: ok\n'
