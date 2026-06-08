#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
HOME_FAKE="$(mktemp -d)"
trap 'rm -rf "$HOME_FAKE"' EXIT

HOME="$HOME_FAKE" "$ROOT/install.sh" >/dev/null

test -x "$HOME_FAKE/.local/bin/agent-ws"
test -d "$HOME_FAKE/.local/lib/agent-ws"
test -d "$HOME_FAKE/.local/share/agent-ws/templates"
"$HOME_FAKE/.local/bin/agent-ws" help >/dev/null
printf 'install default layout: ok\n'
