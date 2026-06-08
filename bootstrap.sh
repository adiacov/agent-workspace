#!/usr/bin/env bash
set -euo pipefail

cat <<'MESSAGE'
Agent Workspace now uses the global `agent-ws` command.

Recommended development install from this checkout:

  ./install.sh --prefix "$HOME/.local/bin"
  agent-ws help
  agent-ws init --profile code --agents pi --no-prompt

The older project-local `bin/agent-workspace` bootstrap flow is legacy.
This transition entrypoint does not initialize or modify project files.
MESSAGE
