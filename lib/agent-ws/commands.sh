#!/usr/bin/env bash
# Command dispatch and shared command helpers for agent-ws.

agent_ws_say() { printf '%s\n' "$*"; }
agent_ws_warn() { printf 'warning: %s\n' "$*" >&2; }
agent_ws_die() { printf 'error: %s\n' "$*" >&2; exit 1; }

agent_ws_usage() {
  cat <<'USAGE'
Usage: agent-ws <command> [options] [path]

Commands:
  init        Initialize a project workspace (implemented in a later phase)
  add-agent   Add an agent entrypoint (implemented in a later phase)
  status      Show current project status (implemented in a later phase)
  audit       Audit one or more projects (implemented in a later phase)
  discover    Discover Agent Workspace projects (implemented in a later phase)
  diff        Compare active files with templates (implemented in a later phase)
  sync        Conservative maintenance (implemented in a later phase)
  update      Update the global command (implemented in a later phase)
  migrate     Preview/apply legacy migration (implemented in a later phase)
  help        Show this help text
USAGE
}

agent_ws_main() {
  local command="${1:-help}"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  case "$command" in
    help|-h|--help)
      agent_ws_usage
      ;;
    init|add-agent|status|audit|discover|diff|sync|update|migrate)
      agent_ws_die "command '$command' is not implemented yet. Next: complete the corresponding implementation phase."
      ;;
    *)
      agent_ws_usage >&2
      agent_ws_die "unknown command: $command. Next: run 'agent-ws help' to see available commands."
      ;;
  esac
}
