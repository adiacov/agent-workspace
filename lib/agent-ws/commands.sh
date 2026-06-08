#!/usr/bin/env bash
# Command dispatch, output helpers, argument parsing, and project safety helpers.

agent_ws_say() { printf '%s\n' "$*"; }
agent_ws_warn() { printf 'warning: %s\n' "$*" >&2; }
agent_ws_error() { printf 'error: %s\n' "$*" >&2; }
agent_ws_next() { printf 'next: %s\n' "$*" >&2; }
agent_ws_die() {
  local message="$1" next="${2:-run 'agent-ws help' to see available commands.}"
  agent_ws_error "$message"
  agent_ws_next "$next"
  exit 1
}

agent_ws_usage() {
  cat <<'USAGE'
Usage: agent-ws <command> [options] [path]

Primary flow:
  agent-ws init --profile code --agents pi --no-prompt

Commands:
  init        Initialize a project workspace
  add-agent   Add an agent entrypoint
  status      Show current project status
  audit       Audit one or more projects
  discover    Discover Agent Workspace projects
  diff        Compare active files with templates
  sync        Conservative maintenance
  update      Update the global command
  migrate     Preview/apply legacy migration
  help        Show this help text

Run `agent-ws help <command>` for command-specific usage.
USAGE
}

agent_ws_command_usage() {
  local command="${1:-help}"
  case "$command" in
    help) agent_ws_usage ;;
    init) cat <<'USAGE'
Usage: agent-ws init [project-name|path] [--profile general|code] [--agents list] [--custom-path path] [--no-prompt]

Initializes the current directory or creates and initializes a named project directory.
Creates default files, selected agent files, and .agent-workspace/workspace.json.
Existing active files are skipped, not overwritten.
USAGE
      ;;
    add-agent) printf '%s\n' 'Usage: agent-ws add-agent [agent] [--agents list] [--custom-path path] [--no-prompt]' ;;
    status) printf '%s\n' 'Usage: agent-ws status [path]' ;;
    audit) printf '%s\n' 'Usage: agent-ws audit [path...]' ;;
    discover) printf '%s\n' 'Usage: agent-ws discover <root...>' ;;
    diff) printf '%s\n' 'Usage: agent-ws diff [path]' ;;
    sync) printf '%s\n' 'Usage: agent-ws sync [path] [--dry-run|--apply]' ;;
    update) printf '%s\n' 'Usage: agent-ws update [--version version]' ;;
    migrate) printf '%s\n' 'Usage: agent-ws migrate [path] [--dry-run|--apply]' ;;
    *) agent_ws_die "unknown help topic: $command" "run 'agent-ws help' to see available commands." ;;
  esac
}

agent_ws_reset_args() {
  AGENT_WS_COMMAND=""
  AGENT_WS_PROFILE=""
  AGENT_WS_AGENTS=""
  AGENT_WS_CUSTOM_PATH=""
  AGENT_WS_NO_PROMPT=0
  AGENT_WS_DRY_RUN=0
  AGENT_WS_APPLY=0
  AGENT_WS_VERSION=""
  AGENT_WS_PATHS=()
}

agent_ws_parse_args() {
  agent_ws_reset_args
  AGENT_WS_COMMAND="${1:-help}"
  if [ "$#" -gt 0 ]; then shift; fi

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        [ "$#" -ge 2 ] || agent_ws_die "--profile requires a value" "choose --profile general or --profile code."
        AGENT_WS_PROFILE="$2"; shift 2 ;;
      --agents)
        [ "$#" -ge 2 ] || agent_ws_die "--agents requires a value" "provide a comma-separated or space-separated agent list."
        AGENT_WS_AGENTS="$2"; shift 2 ;;
      --custom-path)
        [ "$#" -ge 2 ] || agent_ws_die "--custom-path requires a value" "provide a project-root-relative destination path."
        AGENT_WS_CUSTOM_PATH="$2"; shift 2 ;;
      --no-prompt)
        AGENT_WS_NO_PROMPT=1; shift ;;
      --dry-run)
        AGENT_WS_DRY_RUN=1; shift ;;
      --apply)
        AGENT_WS_APPLY=1; shift ;;
      --version)
        [ "$#" -ge 2 ] || agent_ws_die "--version requires a value" "provide an available Git/GitHub release or tag."
        AGENT_WS_VERSION="$2"; shift 2 ;;
      -h|--help)
        AGENT_WS_PATHS+=("--help"); shift ;;
      --)
        shift; while [ "$#" -gt 0 ]; do AGENT_WS_PATHS+=("$1"); shift; done ;;
      --*)
        agent_ws_die "unknown option: $1" "run 'agent-ws help ${AGENT_WS_COMMAND}' for valid options." ;;
      *)
        AGENT_WS_PATHS+=("$1"); shift ;;
    esac
  done
}

agent_ws_dispatch_unimplemented() {
  local command="$1"
  agent_ws_die "command '$command' is not implemented yet" "continue with the implementation phase for '$command', or run 'agent-ws help $command' for planned usage."
}

agent_ws_main() {
  agent_ws_parse_args "$@"

  case "$AGENT_WS_COMMAND" in
    help|-h|--help)
      if [ "${#AGENT_WS_PATHS[@]}" -gt 0 ] && [ "${AGENT_WS_PATHS[0]}" != "--help" ]; then
        agent_ws_command_usage "${AGENT_WS_PATHS[0]}"
      else
        agent_ws_usage
      fi
      ;;
    init)
      if [ "${#AGENT_WS_PATHS[@]}" -gt 0 ] && [ "${AGENT_WS_PATHS[0]}" = "--help" ]; then
        agent_ws_command_usage init
      else
        agent_ws_cmd_init
      fi
      ;;
    add-agent|status|audit|discover|diff|sync|update|migrate)
      if [ "${#AGENT_WS_PATHS[@]}" -gt 0 ] && [ "${AGENT_WS_PATHS[0]}" = "--help" ]; then
        agent_ws_command_usage "$AGENT_WS_COMMAND"
      else
        agent_ws_dispatch_unimplemented "$AGENT_WS_COMMAND"
      fi
      ;;
    *)
      agent_ws_usage >&2
      agent_ws_die "unknown command: $AGENT_WS_COMMAND" "run 'agent-ws help' to see available commands."
      ;;
  esac
}

agent_ws_abs_path() {
  local path="$1"
  if [ -d "$path" ]; then
    cd "$path" && pwd -P
  else
    mkdir -p "$(dirname "$path")"
    local dir base
    dir="$(cd "$(dirname "$path")" && pwd -P)"
    base="$(basename "$path")"
    printf '%s/%s\n' "$dir" "$base"
  fi
}

agent_ws_git_root() {
  git -C "${1:-.}" rev-parse --show-toplevel 2>/dev/null || return 1
}

agent_ws_project_root_for_init() {
  local target="${1:-.}" abs git_root
  abs="$(agent_ws_abs_path "$target")"
  if git_root="$(agent_ws_git_root "$abs")"; then
    if [ "$abs" != "$git_root" ]; then
      agent_ws_die "refusing to initialize inside a parent git repository" "run from the repository root '$git_root' or initialize a directory outside that repository."
    fi
  fi
  printf '%s\n' "$abs"
}

agent_ws_existing_project_root() {
  local target="${1:-.}"
  [ -d "$target" ] || agent_ws_die "project path does not exist: $target" "choose an existing project path."
  agent_ws_abs_path "$target"
}

agent_ws_cmd_init() {
  local profile agents target project_root template_dir records_file generated_json
  profile="${AGENT_WS_PROFILE:-general}"
  agents="${AGENT_WS_AGENTS:-}"

  [ "$profile" = "general" ] || [ "$profile" = "code" ] || agent_ws_die "unsupported profile: $profile" "choose --profile general or --profile code."
  if [ -z "$agents" ]; then
    if [ "$AGENT_WS_NO_PROMPT" -eq 1 ]; then
      agent_ws_die "--agents is required with --no-prompt" "provide --agents pi, codex, claude, cursor, or custom."
    fi
    agent_ws_warn "no --agents provided; defaulting to pi"
    agents="pi"
  fi

  if [ "${#AGENT_WS_PATHS[@]}" -gt 1 ]; then
    agent_ws_die "init accepts at most one project path" "run 'agent-ws help init' for usage."
  fi

  target="${AGENT_WS_PATHS[0]:-.}"
  if [ "$target" = "." ]; then
    project_root="$(agent_ws_project_root_for_init ".")"
  else
    mkdir -p "$target"
    project_root="$(agent_ws_abs_path "$target")"
  fi

  template_dir="$(agent_ws_template_source_dir)"
  AGENT_WS_TEMPLATE_REVISION="$(agent_ws_template_revision "$template_dir")"

  agent_ws_say "initializing $project_root"
  records_file="$(mktemp)"
  AGENT_WS_GENERATED_RECORDS_FILE="$records_file"
  agent_ws_generate_default_files "$project_root"
  agent_ws_generate_profile_files "$project_root" "$profile"
  agent_ws_generate_agent_files "$project_root" "$agents" "$AGENT_WS_CUSTOM_PATH"
  unset AGENT_WS_GENERATED_RECORDS_FILE
  generated_json="$(agent_ws_metadata_generated_json_from_records "$records_file")"
  rm -f "$records_file"
  agent_ws_metadata_write "$project_root" "$profile" "$agents" "$generated_json"
  agent_ws_say "initialized $project_root"
}
