#!/usr/bin/env bash
# Command dispatch, output helpers, argument parsing, and project safety helpers.

agent_ws_say() { printf '%s\n' "$*"; }

# Section header: a blank line plus a title, so command output reads as
# grouped areas instead of one flat stream.
agent_ws_section() {
  agent_ws_say ""
  agent_ws_say "$1"
}

# One-line plain-language explanation for each metadata state, appended after
# the state token (tests and scripts match on the token, people read the rest).
agent_ws_metadata_status_gloss() {
  case "$1" in
    present) printf '%s\n' "present — this project is managed by agent-ws" ;;
    missing) printf '%s\n' "missing — agent-ws does not manage this directory yet" ;;
    legacy)  printf '%s\n' "legacy — this project uses the old project-local layout" ;;
    invalid) printf '%s\n' "invalid — .agent-workspace/workspace.json cannot be read" ;;
    stale)   printf '%s\n' "stale — the recorded template source is unavailable" ;;
    *)       printf '%s\n' "$1" ;;
  esac
}

# Next-step advice: commands collect plain-language recommendations while they
# run and flush them as one "Next steps" block at the end of the output.
AGENT_WS_ADVICE=()

agent_ws_advise() {
  local existing
  for existing in "${AGENT_WS_ADVICE[@]:-}"; do
    [ "$existing" = "$1" ] && return 0
  done
  AGENT_WS_ADVICE+=("$1")
}

# Print the collected advice (if any) and reset. When there is no advice and
# an all-clear message is given, print that instead so healthy projects get a
# positive confirmation rather than silence.
agent_ws_advice_flush() {
  local all_clear="${1:-}" line
  if [ "${#AGENT_WS_ADVICE[@]}" -eq 0 ]; then
    if [ -n "$all_clear" ]; then
      agent_ws_say ""
      agent_ws_say "All good: $all_clear"
    fi
    return 0
  fi
  agent_ws_say ""
  agent_ws_say "Next steps:"
  for line in "${AGENT_WS_ADVICE[@]}"; do
    agent_ws_say "  - $line"
  done
  AGENT_WS_ADVICE=()
}
agent_ws_warn() { printf 'warning: %s\n' "$*" >&2; }
agent_ws_error() { printf 'error: %s\n' "$*" >&2; }
agent_ws_next() { printf 'next: %s\n' "$*" >&2; }
agent_ws_die() {
  local message="$1" next="${2:-run 'agent-ws help' to see available commands.}"
  agent_ws_error "$message"
  agent_ws_next "$next"
  exit 1
}

agent_ws_validate_version_value() {
  local version="$1"
  [ -n "$version" ] || return 1
  case "$version" in
    v[0-9]*.[0-9]*.[0-9]*) ;;
    *) return 1 ;;
  esac
  case "$version" in
    *[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._+-]*) return 1 ;;
  esac
  return 0
}

agent_ws_read_version_file() {
  local file="$1" version
  [ -f "$file" ] || return 1
  version="$(tr -d '[:space:]' < "$file")"
  agent_ws_validate_version_value "$version" || return 1
  printf '%s\n' "$version"
}

agent_ws_version_file() {
  local candidate

  if [ -n "${AGENT_WS_VERSION_FILE:-}" ]; then
    [ -f "$AGENT_WS_VERSION_FILE" ] || return 1
    printf '%s\n' "$AGENT_WS_VERSION_FILE"
    return 0
  fi

  for candidate in \
    "$AGENT_WS_LIB_DIR/../../VERSION" \
    "$AGENT_WS_LIB_DIR/../VERSION" \
    "$AGENT_WS_LIB_DIR/VERSION" \
    "$AGENT_WS_LIB_DIR/../../share/agent-ws/VERSION" \
    "$AGENT_WS_LIB_DIR/../../share/agent-ws/version"; do
    if [ -f "$candidate" ]; then
      cd "$(dirname "$candidate")" && printf '%s/%s\n' "$(pwd -P)" "$(basename "$candidate")"
      return 0
    fi
  done

  return 1
}

agent_ws_installed_version() {
  local file
  file="$(agent_ws_version_file)" || return 1
  agent_ws_read_version_file "$file"
}

agent_ws_usage() {
  cat <<'USAGE'
Usage: agent-ws <command> [options] [path]

Primary flow:
  agent-ws init

Non-interactive flow:
  agent-ws init --profile code --agents pi --no-prompt
  agent-ws init --profile cockpit --agents pi --no-prompt

Commands:
  init        Initialize a project workspace
  add-agent   Add an agent entrypoint
  status      Show current project status
  audit       Audit one or more projects
  discover    Discover Agent Workspace projects
  diff        Show incoming template changes (baseline to template)
  sync        Merge template changes into a project
  version     Show installed command version
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
Usage: agent-ws init [project-name|path] [--profile general|code|cockpit] [--agents list] [--custom-path path] [--no-prompt]

Initializes the current directory or creates and initializes a named project directory.
Creates default files, selected agent files, and .agent-workspace/workspace.json.
Existing active files are skipped, not overwritten.

Options:
  --profile general|code|cockpit
                          Project type. general creates core workflow/context files; code also
                          creates ENGINEERING.md; cockpit adds a control-room layer over many
                          projects (PROJECTS.md, PROFILE.md, WORKFLOWS-COCKPIT.md, cockpit STATE.md).
  --agents list           Agent adapters to create. Supports pi, codex, claude, cursor, custom. Commas or spaces are accepted.
  --custom-path path      Project-relative output path for the custom agent adapter.
  --no-prompt             Non-interactive mode. Requires --profile and --agents.

Interactive behavior:
  If --profile or --agents are omitted, init prompts for them unless --no-prompt is used.
USAGE
      ;;
    add-agent) cat <<'USAGE'
Usage: agent-ws add-agent [agent] [--agents list] [--custom-path path] [--no-prompt]

Adds one or more agent instruction entrypoints to an initialized project.
Uses global templates, preserves existing files, and updates metadata for newly created files.

Options:
  --agents list           Agent adapters to add. Supports pi, codex, claude, cursor, custom. Commas or spaces are accepted.
  --custom-path path      Project-relative output path for the custom agent adapter.
  --no-prompt             Non-interactive mode. Requires an agent through --agents or positional argument.

If no agent is provided and prompting is possible, add-agent asks which agent to add.
USAGE
      ;;
    status) cat <<'USAGE'
Usage: agent-ws status [path]

Shows a quick current-project health summary without modifying files.
Reports core files, known agent files, profile files, metadata, global template availability, and legacy signals.

Arguments:
  path                    Optional project path. Defaults to current directory.
USAGE
      ;;
    audit) cat <<'USAGE'
Usage: agent-ws audit [path...]

Performs deeper checks for one or more projects without modifying files.
Reports missing files, metadata validity, stale metadata, legacy structure, template availability, and recovery guidance.

Arguments:
  path...                 Optional project paths. Defaults to current directory.
USAGE
      ;;
    discover) cat <<'USAGE'
Usage: agent-ws discover <root...>

Scans explicit roots for likely Agent Workspace projects without maintaining a registry.
Reports strong and uncertain matches with the signals that caused detection.
Skips heavy directories such as .git, node_modules, .venv, dist, and build.

Arguments:
  root...                 Required scan roots.
USAGE
      ;;
    diff) cat <<'USAGE'
Usage: agent-ws diff [path]

Shows the incoming template delta for framework files: what the current templates
would bring in relative to the project's baseline (the template version last synced).
Read-only. Colorized on a TTY; plain under NO_COLOR or when piped. Content files
(STATE.md, PROJECT.md) are not shown.

Arguments:
  path                    Optional project path. Defaults to current directory.
USAGE
      ;;
    sync) cat <<'USAGE'
Usage: agent-ws sync [path] [--dry-run|--apply]

Merges published template changes into a project's framework files using a per-project
baseline three-way merge. Template-only additions apply cleanly while local edits are
preserved. Overlapping edits are refused: the live file is left untouched, a *.merge
side-file with conflict markers is written, and the run exits non-zero (resolve it
separately). Content files (STATE.md, PROJECT.md) are never synced. A project with no
baseline is seeded on first sync. Backups are taken before writes and removed on success.

Options:
  --dry-run               Preview per-file outcomes without modifying anything. Default.
  --apply                 Perform the merge (and seed baselines as needed).

Use migrate, not sync, for older projects with .agent/ or bin/agent-workspace.
USAGE
      ;;
    version) cat <<'USAGE'
Usage: agent-ws version

Shows the installed agent-ws version from the installed payload VERSION file.
Does not inspect the current project or require a git checkout.
USAGE
      ;;
    update) cat <<'USAGE'
Usage: agent-ws update [--version version] [--dry-run]

Selects a stable Git/GitHub release or tag and preserves the current command on failures.
Without --version, uses the latest stable release, excluding alpha, beta, rc, and pre-release versions.

Options:
  --version version       Install a specific stable release/tag.
  --dry-run               Show selected release without replacing the command.
USAGE
      ;;
    migrate) cat <<'USAGE'
Usage: agent-ws migrate [path] [--dry-run|--apply]

Helps migrate from the older project-local model with .agent/ and bin/agent-workspace to the global agent-ws model.
Defaults to --dry-run, preserves active instruction files and memory, and ignores old .agent/templates/ cache contents.
USAGE
      ;;
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
        [ "$#" -ge 2 ] || agent_ws_die "--profile requires a value" "choose --profile general, code, or cockpit."
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

agent_ws_can_prompt() {
  # A usable TTY or piped/redirected stdin can answer prompts; a fully
  # detached process (no controlling terminal, closed stdin) cannot.
  { [ -r /dev/tty ] && true < /dev/tty; } 2>/dev/null && return 0
  [ -e /dev/stdin ] 2>/dev/null
}

agent_ws_prompt_read() {
  local prompt="$1" value=""
  printf '%s' "$prompt" >&2
  if [ -r /dev/tty ] 2>/dev/null && IFS= read -r value < /dev/tty 2>/dev/null; then
    printf '%s\n' "$value"
    return 0
  fi
  if IFS= read -r value; then
    printf '%s\n' "$value"
    return 0
  fi
  agent_ws_die "prompt input is unavailable" "rerun with explicit options such as --profile, --agents, and --no-prompt."
}

agent_ws_prompt_profile() {
  local value
  value="$(agent_ws_prompt_read 'Project profile [general/code/cockpit] (general): ')"
  case "${value:-general}" in
    general|code|cockpit) printf '%s\n' "${value:-general}" ;;
    *) agent_ws_die "unsupported profile: $value" "choose general, code, or cockpit." ;;
  esac
}

agent_ws_prompt_agents() {
  local value
  value="$(agent_ws_prompt_read 'Agents [pi,codex,claude,cursor,custom] (pi): ')"
  printf '%s\n' "${value:-pi}"
}

agent_ws_agents_include_custom() {
  local agent
  while IFS= read -r agent; do
    [ "$agent" = "custom" ] && return 0
  done <<< "$(agent_ws_split_agents "$1")"
  return 1
}

agent_ws_prompt_custom_path_if_needed() {
  local agents="$1" value
  if agent_ws_agents_include_custom "$agents" && [ -z "$AGENT_WS_CUSTOM_PATH" ]; then
    if [ "$AGENT_WS_NO_PROMPT" -eq 1 ]; then
      agent_ws_die "--custom-path is required for custom agent with --no-prompt" "provide a project-root-relative custom instruction path."
    fi
    agent_ws_can_prompt || agent_ws_die "--custom-path is required when prompting is unavailable" "provide a project-root-relative custom instruction path."
    value="$(agent_ws_prompt_read 'Custom agent path (INSTRUCTIONS.md): ')"
    AGENT_WS_CUSTOM_PATH="${value:-INSTRUCTIONS.md}"
  fi
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
    add-agent)
      if [ "${#AGENT_WS_PATHS[@]}" -gt 0 ] && [ "${AGENT_WS_PATHS[0]}" = "--help" ]; then
        agent_ws_command_usage add-agent
      else
        agent_ws_cmd_add_agent
      fi
      ;;
    status)
      if [ "${#AGENT_WS_PATHS[@]}" -gt 0 ] && [ "${AGENT_WS_PATHS[0]}" = "--help" ]; then
        agent_ws_command_usage status
      else
        agent_ws_cmd_status
      fi
      ;;
    audit)
      if [ "${#AGENT_WS_PATHS[@]}" -gt 0 ] && [ "${AGENT_WS_PATHS[0]}" = "--help" ]; then
        agent_ws_command_usage audit
      else
        agent_ws_cmd_audit
      fi
      ;;
    discover)
      if [ "${#AGENT_WS_PATHS[@]}" -gt 0 ] && [ "${AGENT_WS_PATHS[0]}" = "--help" ]; then
        agent_ws_command_usage discover
      else
        agent_ws_cmd_discover
      fi
      ;;
    diff)
      if [ "${#AGENT_WS_PATHS[@]}" -gt 0 ] && [ "${AGENT_WS_PATHS[0]}" = "--help" ]; then
        agent_ws_command_usage diff
      else
        agent_ws_cmd_diff
      fi
      ;;
    sync)
      if [ "${#AGENT_WS_PATHS[@]}" -gt 0 ] && [ "${AGENT_WS_PATHS[0]}" = "--help" ]; then
        agent_ws_command_usage sync
      else
        agent_ws_cmd_sync
      fi
      ;;
    version)
      if [ "${#AGENT_WS_PATHS[@]}" -gt 0 ]; then
        agent_ws_die "version does not accept positional arguments" "run 'agent-ws version'."
      fi
      agent_ws_cmd_version
      ;;
    update)
      if [ "${#AGENT_WS_PATHS[@]}" -gt 0 ] && [ "${AGENT_WS_PATHS[0]}" = "--help" ]; then
        agent_ws_command_usage update
      else
        agent_ws_cmd_update
      fi
      ;;
    migrate)
      if [ "${#AGENT_WS_PATHS[@]}" -gt 0 ] && [ "${AGENT_WS_PATHS[0]}" = "--help" ]; then
        agent_ws_command_usage migrate
      else
        agent_ws_cmd_migrate
      fi
      ;;
    *)
      agent_ws_usage >&2
      agent_ws_die "unknown command: $AGENT_WS_COMMAND" "run 'agent-ws help' to see available commands."
      ;;
  esac
}

agent_ws_abs_path() {
  local path="$1" dir base
  if [ -d "$path" ]; then
    cd "$path" && pwd -P
  else
    dir="$(cd "$(dirname "$path")" && pwd -P)" || return 1
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
  profile="${AGENT_WS_PROFILE:-}"
  agents="${AGENT_WS_AGENTS:-}"

  if [ -z "$profile" ]; then
    if [ "$AGENT_WS_NO_PROMPT" -eq 1 ]; then
      agent_ws_die "--profile is required with --no-prompt" "provide --profile general, code, or cockpit."
    fi
    agent_ws_can_prompt || agent_ws_die "--profile is required when prompting is unavailable" "provide --profile general, code, or cockpit."
    profile="$(agent_ws_prompt_profile)"
  fi
  [ "$profile" = "general" ] || [ "$profile" = "code" ] || [ "$profile" = "cockpit" ] || agent_ws_die "unsupported profile: $profile" "choose --profile general, code, or cockpit."
  if [ -z "$agents" ]; then
    if [ "$AGENT_WS_NO_PROMPT" -eq 1 ]; then
      agent_ws_die "--agents is required with --no-prompt" "provide --agents pi, codex, claude, cursor, or custom."
    fi
    agent_ws_can_prompt || agent_ws_die "--agents is required when prompting is unavailable" "provide --agents pi, codex, claude, cursor, or custom."
    agents="$(agent_ws_prompt_agents)"
  fi

  agent_ws_prompt_custom_path_if_needed "$agents"

  # Validate the agent list before any files are written so a bad agent name
  # cannot leave a half-initialized project behind.
  agent_ws_validate_agents "$agents" "$AGENT_WS_CUSTOM_PATH"
  agent_ws_agent_destination_conflict_check "$agents" "$AGENT_WS_CUSTOM_PATH"

  if [ "${#AGENT_WS_PATHS[@]}" -gt 1 ]; then
    agent_ws_die "init accepts at most one project path" "run 'agent-ws help init' for usage."
  fi

  target="${AGENT_WS_PATHS[0]:-.}"
  if [ "$target" != "." ]; then
    mkdir -p "$target"
  fi
  project_root="$(agent_ws_project_root_for_init "$target")"

  template_dir="$(agent_ws_template_source_dir)"
  AGENT_WS_TEMPLATE_REVISION="$(agent_ws_template_revision "$template_dir")"

  agent_ws_say "Initializing: $project_root (profile: $profile, agents: $agents)"
  records_file="$(mktemp)"
  AGENT_WS_GENERATED_RECORDS_FILE="$records_file"
  agent_ws_generate_default_files "$project_root" "$profile"
  agent_ws_generate_profile_files "$project_root" "$profile"
  agent_ws_generate_agent_files "$project_root" "$agents" "$AGENT_WS_CUSTOM_PATH"
  unset AGENT_WS_GENERATED_RECORDS_FILE
  generated_json="$(agent_ws_metadata_generated_json_from_records "$records_file")"
  rm -f "$records_file"
  agent_ws_metadata_write "$project_root" "$profile" "$agents" "$generated_json"
  agent_ws_say "Initialized: $project_root"
  agent_ws_advise "describe your project in PROJECT.md and its current state in STATE.md (these files are yours; agent-ws never edits them)"
  agent_ws_advise "review the workspace anytime with: agent-ws status"
  agent_ws_advice_flush
}

agent_ws_cmd_add_agent() {
  local agents project_root template_dir records_file generated_json
  agents="${AGENT_WS_AGENTS:-}"

  if [ -z "$agents" ] && [ "${#AGENT_WS_PATHS[@]}" -gt 0 ]; then
    agents="${AGENT_WS_PATHS[0]}"
    if [ "${#AGENT_WS_PATHS[@]}" -gt 1 ]; then
      agent_ws_die "add-agent accepts one positional agent or --agents" "run 'agent-ws help add-agent' for usage."
    fi
  fi

  if [ -z "$agents" ]; then
    if [ "$AGENT_WS_NO_PROMPT" -eq 1 ]; then
      agent_ws_die "--agents or positional agent is required with --no-prompt" "provide --agents pi, codex, claude, cursor, or custom."
    fi
    agent_ws_can_prompt || agent_ws_die "agent selection is required when prompting is unavailable" "provide --agents pi, codex, claude, cursor, or custom."
    agents="$(agent_ws_prompt_agents)"
  fi

  agent_ws_prompt_custom_path_if_needed "$agents"

  agent_ws_validate_agents "$agents" "$AGENT_WS_CUSTOM_PATH"
  agent_ws_agent_destination_conflict_check "$agents" "$AGENT_WS_CUSTOM_PATH"

  project_root="$(agent_ws_existing_project_root ".")"
  [ -f "$(agent_ws_metadata_path "$project_root")" ] || agent_ws_die "workspace metadata is missing" "run 'agent-ws init' before adding agents."

  template_dir="$(agent_ws_template_source_dir)"
  AGENT_WS_TEMPLATE_REVISION="$(agent_ws_template_revision "$template_dir")"

  agent_ws_say "Adding agent support: $project_root ($agents)"
  records_file="$(mktemp)"
  AGENT_WS_GENERATED_RECORDS_FILE="$records_file"
  AGENT_WS_RECORD_CREATED_ONLY=1
  agent_ws_generate_agent_files "$project_root" "$agents" "$AGENT_WS_CUSTOM_PATH"
  unset AGENT_WS_GENERATED_RECORDS_FILE
  unset AGENT_WS_RECORD_CREATED_ONLY
  generated_json="$(agent_ws_metadata_generated_json_from_records "$records_file")"
  rm -f "$records_file"
  if [ "$generated_json" != "{}" ]; then
    agent_ws_metadata_update_generated "$project_root" "$agents" "$generated_json"
  else
    agent_ws_say "metadata unchanged; no new agent files created"
  fi
  agent_ws_say "Done: added agent support to $project_root"
  agent_ws_advise "review the workspace anytime with: agent-ws status"
  agent_ws_advice_flush
}

agent_ws_cmd_status() {
  local target="${AGENT_WS_PATHS[0]:-.}"
  if [ "${#AGENT_WS_PATHS[@]}" -gt 1 ]; then
    agent_ws_die "status accepts at most one project path" "run 'agent-ws help status' for usage."
  fi
  agent_ws_status_project "$target"
}

agent_ws_cmd_audit() {
  local path
  if [ "${#AGENT_WS_PATHS[@]}" -eq 0 ]; then
    agent_ws_audit_project "."
    return 0
  fi
  local first=1
  for path in "${AGENT_WS_PATHS[@]}"; do
    [ "$first" -eq 1 ] || agent_ws_say ""
    first=0
    agent_ws_audit_project "$path"
  done
}

agent_ws_cmd_discover() {
  if [ "${#AGENT_WS_PATHS[@]}" -eq 0 ]; then
    agent_ws_die "discover requires at least one root path" "run 'agent-ws discover <root...>'."
  fi
  agent_ws_discover "${AGENT_WS_PATHS[@]}"
}

agent_ws_cmd_diff() {
  local target="${AGENT_WS_PATHS[0]:-.}"
  if [ "${#AGENT_WS_PATHS[@]}" -gt 1 ]; then
    agent_ws_die "diff accepts at most one project path" "run 'agent-ws help diff' for usage."
  fi
  agent_ws_diff_project "$target"
}

agent_ws_cmd_sync() {
  local mode target
  if [ "$AGENT_WS_APPLY" -eq 1 ] && [ "$AGENT_WS_DRY_RUN" -eq 1 ]; then
    agent_ws_die "sync accepts only one of --dry-run or --apply" "choose either --dry-run or --apply."
  fi
  if [ "$AGENT_WS_APPLY" -eq 1 ]; then
    mode="apply"
  else
    mode="dry-run"
  fi
  target="${AGENT_WS_PATHS[0]:-.}"
  if [ "${#AGENT_WS_PATHS[@]}" -gt 1 ]; then
    agent_ws_die "sync accepts at most one project path" "run 'agent-ws help sync' for usage."
  fi
  agent_ws_sync_project "$target" "$mode"
}

agent_ws_cmd_version() {
  local version
  version="$(agent_ws_installed_version)" || agent_ws_die "unable to determine installed version" "reinstall agent-ws or restore the installed VERSION file."
  agent_ws_say "agent-ws $version"
}

agent_ws_cmd_update() {
  if [ "${#AGENT_WS_PATHS[@]}" -gt 0 ]; then
    agent_ws_die "update does not accept positional paths" "use --version to select a release."
  fi
  agent_ws_update_command "$AGENT_WS_VERSION" "$AGENT_WS_DRY_RUN"
}

agent_ws_cmd_migrate() {
  local mode target
  if [ "$AGENT_WS_APPLY" -eq 1 ] && [ "$AGENT_WS_DRY_RUN" -eq 1 ]; then
    agent_ws_die "migrate accepts only one of --dry-run or --apply" "review with --dry-run, then rerun with --apply if safe."
  fi
  if [ "$AGENT_WS_APPLY" -eq 1 ]; then
    mode="apply"
  else
    mode="dry-run"
  fi
  target="${AGENT_WS_PATHS[0]:-.}"
  if [ "${#AGENT_WS_PATHS[@]}" -gt 1 ]; then
    agent_ws_die "migrate accepts at most one project path" "run 'agent-ws help migrate' for usage."
  fi
  agent_ws_migrate_project "$target" "$mode"
}
