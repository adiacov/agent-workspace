#!/usr/bin/env bash
# Heal: take a project from any recoverable state to healthy with one
# preview-first command. Composes the existing primitives in order:
#   legacy/unmanaged -> migrate --apply (adopt, create metadata)
#   incomplete       -> recreate missing files from templates (never overwrites)
#   outdated         -> sync --apply (seed baselines / merge template changes)
# States heal cannot decide for the user: not-initialized (init needs a
# profile choice), invalid metadata (needs inspection).

# Recreate any missing generated files using the profile/agents recorded in
# metadata (custom adapters are skipped: their destination is not recoverable).
agent_ws_heal_complete_files() {
  local project_root="$1" profile agents agent records_file generated_json
  profile="$(agent_ws_audit_metadata_profile "$project_root")"
  agents="$(agent_ws_audit_metadata_agents "$project_root")"
  [ -n "$agents" ] || agents="pi"
  agents="$(agent_ws_split_agents "$agents" | { grep -vx custom || true; } | tr '\n' ' ')"

  AGENT_WS_TEMPLATE_REVISION="$(agent_ws_template_revision "$(agent_ws_template_source_dir)")"
  records_file="$(mktemp)"
  AGENT_WS_GENERATED_RECORDS_FILE="$records_file"
  AGENT_WS_RECORD_CREATED_ONLY=1
  agent_ws_generate_default_files "$project_root" "$profile"
  agent_ws_generate_profile_files "$project_root" "$profile"
  if [ -n "${agents// /}" ]; then
    agent_ws_generate_agent_files "$project_root" "$agents" ""
  else
    # custom-only project: the custom destination is not recoverable, but the
    # shared canonical AGENTS.md still is.
    agent_ws_copy_template_spec "$project_root" 'adapters/AGENTS.md' 'AGENTS.md' 'adapter' ''
  fi
  unset AGENT_WS_GENERATED_RECORDS_FILE
  unset AGENT_WS_RECORD_CREATED_ONLY
  generated_json="$(agent_ws_metadata_generated_json_from_records "$records_file")"
  rm -f "$records_file"
  if [ "$generated_json" != "{}" ]; then
    agent_ws_metadata_update_generated "$project_root" "$agents" "$generated_json"
  fi
}

agent_ws_heal_project() {
  local project_root="$1" mode="$2" state step=0
  project_root="$(agent_ws_existing_project_root "$project_root")"

  if [ "$mode" = "apply" ]; then
    agent_ws_say "Heal: $project_root"
  else
    agent_ws_say "Heal preview: $project_root (dry-run; nothing will be modified)"
  fi

  state="$(agent_ws_project_state "$project_root")"
  agent_ws_say "state: $state"

  case "$state" in
    in-sync)
      agent_ws_advice_flush "this project is already healthy; nothing to do."
      return 0
      ;;
    not-initialized)
      agent_ws_say "this directory has nothing to heal: it is not an agent-ws project"
      agent_ws_advise "set it up (this needs your profile choice): agent-ws init"
      agent_ws_advice_flush
      return 0
      ;;
    invalid)
      agent_ws_say "the workspace metadata cannot be read; healing will not guess what it contained"
      agent_ws_advise "inspect .agent-workspace/workspace.json, fix or delete it, then re-run: agent-ws heal"
      agent_ws_advice_flush
      return 1
      ;;
    stale)
      agent_ws_say "the template source is unavailable; healing needs the global templates"
      agent_ws_advise "reinstall agent-ws or set AGENT_WS_TEMPLATE_SOURCE_DIR, then re-run: agent-ws heal"
      agent_ws_advice_flush
      return 1
      ;;
  esac

  agent_ws_section "Plan"
  case "$state" in
    legacy|unmanaged)
      step=$((step + 1)); agent_ws_say "  $step. adopt the project (create metadata, migrate legacy layout)"
      step=$((step + 1)); agent_ws_say "  $step. recreate any missing files from templates (existing files are never overwritten)"
      step=$((step + 1)); agent_ws_say "  $step. seed baselines / merge template changes (sync)"
      ;;
    incomplete)
      step=$((step + 1)); agent_ws_say "  $step. recreate any missing files from templates (existing files are never overwritten)"
      step=$((step + 1)); agent_ws_say "  $step. seed baselines / merge template changes (sync)"
      ;;
    outdated)
      step=$((step + 1)); agent_ws_say "  $step. seed baselines / merge template changes (sync)"
      ;;
  esac

  if [ "$mode" != "apply" ]; then
    agent_ws_advise "run the plan with: agent-ws heal --apply"
    agent_ws_advice_flush
    return 0
  fi

  agent_ws_section "Run"
  AGENT_WS_ADVICE_QUIET=1
  case "$state" in
    legacy|unmanaged)
      agent_ws_migrate_project "$project_root" "apply"
      agent_ws_heal_complete_files "$project_root"
      ;;
    incomplete)
      agent_ws_heal_complete_files "$project_root"
      ;;
  esac
  if ! agent_ws_sync_project "$project_root" "apply"; then
    AGENT_WS_ADVICE_QUIET=0
    agent_ws_say "heal stopped: sync reported conflicts (see above)"
    agent_ws_advise "resolve each *.merge file (edit, replace the live file, delete the *.merge), then re-run: agent-ws heal --apply"
    agent_ws_advice_flush
    return 1
  fi
  AGENT_WS_ADVICE_QUIET=0

  agent_ws_section "Result"
  state="$(agent_ws_project_state "$project_root")"
  if [ "$state" = "in-sync" ]; then
    agent_ws_registry_add "$project_root"
    agent_ws_say "  healed — the project is set up and in sync"
    return 0
  fi
  agent_ws_say "  state after healing: $state"
  agent_ws_advise "inspect the remaining issue with: agent-ws audit"
  agent_ws_advice_flush
  return 1
}
