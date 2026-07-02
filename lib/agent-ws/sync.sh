#!/usr/bin/env bash
# Merge-based sync: reconcile published template changes into a project's
# framework files using a per-project baseline three-way merge.
#
# Per file outcomes: unchanged | updated | seeded | conflicted |
#                    missing-active | missing-template | skipped-content
# A run exits non-zero if any file is conflicted.

# Read-only check of how the project's framework files stand relative to the
# installed templates. Prints one of:
#   no-framework       no metadata/template source/framework mappings to check
#   seed-needed        at least one framework file has no baseline yet
#   updates-available  baselines are behind the installed templates
#   up-to-date         baselines match the installed templates
agent_ws_sync_readiness() {
  local project_root="$1" metadata_file template_dir line path rest kind template baseline
  metadata_file="$(agent_ws_metadata_path "$project_root")"
  if [ ! -f "$metadata_file" ]; then
    printf 'no-framework\n'
    return 0
  fi
  template_dir="$(agent_ws_template_source_dir 2>/dev/null || true)"
  if [ -z "$template_dir" ]; then
    printf 'no-framework\n'
    return 0
  fi
  local any=0 seed=0 updates=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    path="${line%%|*}"
    rest="${line#*|}"
    kind="${rest%%|*}"
    template="${rest#*|}"
    agent_ws_file_is_framework "$kind" || continue
    [ -f "$template_dir/$template" ] || continue
    any=1
    baseline="$(agent_ws_baseline_path "$project_root" "$path")"
    if [ ! -f "$baseline" ]; then
      seed=1
    elif ! cmp -s "$baseline" "$template_dir/$template"; then
      updates=1
    fi
  done <<< "$(agent_ws_metadata_generated_records "$metadata_file" 2>/dev/null || true)"
  if [ "$any" -eq 0 ]; then
    printf 'no-framework\n'
  elif [ "$seed" -eq 1 ]; then
    printf 'seed-needed\n'
  elif [ "$updates" -eq 1 ]; then
    printf 'updates-available\n'
  else
    printf 'up-to-date\n'
  fi
}

# EXIT-trap handler: if an apply run aborts partway, restore every file we
# replaced from its .bak and drop the in-flight merge temp file.
agent_ws_sync_abort_cleanup() {
  local b
  [ -n "${AGENT_WS_SYNC_MERGED_TMP:-}" ] && rm -f "$AGENT_WS_SYNC_MERGED_TMP"
  for b in "${AGENT_WS_SYNC_BACKUPS[@]:-}"; do
    [ -n "$b" ] && agent_ws_backup_restore "$b"
  done
  return 0
}

agent_ws_sync_project() {
  local project_root="$1" mode="$2"
  project_root="$(agent_ws_existing_project_root "$project_root")"

  local metadata_file metadata_status template_dir
  metadata_file="$(agent_ws_metadata_path "$project_root")"
  metadata_status="$(agent_ws_metadata_status "$project_root")"

  if [ "$mode" != "dry-run" ] && [ "$mode" != "apply" ]; then
    agent_ws_die "unknown sync mode: $mode" "run 'agent-ws sync --dry-run' or 'agent-ws sync --apply'."
  fi

  if [ "$mode" = "apply" ]; then
    agent_ws_say "Sync: $project_root"
  else
    agent_ws_say "Sync preview: $project_root (dry-run; nothing will be modified)"
  fi
  agent_ws_say "metadata: $(agent_ws_metadata_status_gloss "$metadata_status")"

  if [ ! -f "$metadata_file" ]; then
    agent_ws_say "nothing to sync: this project has no workspace metadata"
    agent_ws_advise "adopt an existing project with: agent-ws migrate --dry-run, or set one up with: agent-ws init"
    agent_ws_advice_flush
    return 0
  fi

  template_dir="$(agent_ws_template_source_dir 2>/dev/null || true)"
  if [ -z "$template_dir" ]; then
    agent_ws_say "template source: missing — the global templates cannot be found"
    agent_ws_advise "reinstall agent-ws or set AGENT_WS_TEMPLATE_SOURCE_DIR"
    agent_ws_advice_flush
    return 0
  fi
  agent_ws_say "template source: $template_dir"
  [ "$metadata_status" = "present" ] && agent_ws_registry_add "$project_root"

  # Pre-v0.4.0 adapter records are upgraded to the canonical AGENTS.md model.
  # Dry-run previews with the upgraded view (agent_ws_metadata_generated_records
  # remaps on read); apply persists the rewrite.
  local upgraded
  if [ "$mode" = "apply" ]; then
    upgraded="$(agent_ws_metadata_upgrade_adapter_records "$metadata_file" 1)"
    [ "$upgraded" -gt 0 ] && agent_ws_say "adapter records: upgraded $upgraded record(s) to the canonical AGENTS.md model"
  else
    upgraded="$(agent_ws_metadata_upgrade_adapter_records "$metadata_file" 0)"
    [ "$upgraded" -gt 0 ] && agent_ws_say "adapter records: $upgraded record(s) will be upgraded to the canonical AGENTS.md model on apply"
  fi
  if [ -e "$project_root/.cursor/rules/agent-workspace.mdc" ]; then
    agent_ws_advise "Cursor reads AGENTS.md natively now; .cursor/rules/agent-workspace.mdc is no longer managed — delete it when convenient"
  fi

  agent_ws_section "Files"

  local apply=0
  [ "$mode" = "apply" ] && apply=1

  local conflicts=0 seeded_any=0 pending=0 missing_active=0
  AGENT_WS_SYNC_BACKUPS=()   # files we backed up this run (for cleanup/restore)
  AGENT_WS_SYNC_MERGED_TMP=""
  if [ "$apply" -eq 1 ]; then
    trap 'agent_ws_sync_abort_cleanup' EXIT
  fi

  local line path kind template active template_file baseline
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    path="${line%%|*}"
    local rest="${line#*|}"
    kind="${rest%%|*}"
    template="${rest#*|}"
    active="$project_root/$path"
    template_file="$template_dir/$template"

    if ! agent_ws_file_is_framework "$kind"; then
      agent_ws_say "  $path: skipped-content — your content file; sync never touches it"
      continue
    fi
    if [ ! -f "$template_file" ]; then
      agent_ws_say "  $path: missing-template — the installed templates no longer provide this file"
      continue
    fi
    if [ ! -f "$active" ]; then
      agent_ws_say "  $path: missing-active — tracked in metadata but missing from the project"
      missing_active=$((missing_active + 1))
      continue
    fi

    baseline="$(agent_ws_baseline_path "$project_root" "$path")"

    # No baseline yet: seed it, apply nothing destructive this run (R6/FR-009).
    if [ ! -f "$baseline" ]; then
      if [ "$apply" -eq 1 ]; then
        agent_ws_baseline_write "$project_root" "$path" "$template_file"
        if [ "$seeded_any" -eq 0 ]; then
          agent_ws_ensure_gitignore "$project_root"
          seeded_any=1
        fi
        agent_ws_say "  $path: seeded — baseline snapshot saved; this file is now sync-ready"
      else
        agent_ws_say "  $path: would-seed — first sync; a baseline snapshot would be saved"
        pending=$((pending + 1))
      fi
      continue
    fi

    # Baseline present: if the template has no incoming change, nothing to do.
    if cmp -s "$baseline" "$template_file"; then
      agent_ws_say "  $path: unchanged — already up to date"
      continue
    fi

    # Three-way merge into a temp file in the active file's directory.
    local merged status=0
    merged="$(mktemp "$(dirname "$active")/.agent-ws-merge.XXXXXX")"
    AGENT_WS_SYNC_MERGED_TMP="$merged"
    if agent_ws_merge_three_way "$active" "$baseline" "$template_file" "$merged"; then
      status=0
    else
      status=1
    fi

    # Conflict (or, defensively, markers in a "clean" merge): refuse.
    if [ "$status" -ne 0 ] || agent_ws_has_conflict_markers "$merged"; then
      conflicts=$((conflicts + 1))
      if [ "$apply" -eq 1 ]; then
        mv "$merged" "$active.merge"
        agent_ws_say "  $path: conflicted — your edits and the template changed the same lines (wrote $path.merge)"
      else
        rm -f "$merged"
        agent_ws_say "  $path: would-conflict — your edits and the template changed the same lines"
      fi
      AGENT_WS_SYNC_MERGED_TMP=""
      continue
    fi

    # Clean merge. If it changes nothing, just advance the baseline.
    if cmp -s "$merged" "$active"; then
      rm -f "$merged"
      AGENT_WS_SYNC_MERGED_TMP=""
      if [ "$apply" -eq 1 ]; then
        agent_ws_baseline_write "$project_root" "$path" "$template_file"
      fi
      agent_ws_say "  $path: unchanged — already up to date"
      continue
    fi

    if [ "$apply" -eq 1 ]; then
      agent_ws_atomic_write "$merged" "$active"
      AGENT_WS_SYNC_BACKUPS+=("$active")
      agent_ws_baseline_write "$project_root" "$path" "$template_file"
      agent_ws_say "  $path: updated — template changes merged; your local edits were kept"
    else
      rm -f "$merged"
      agent_ws_say "  $path: would-update — template changes would merge cleanly with your edits"
      pending=$((pending + 1))
    fi
    AGENT_WS_SYNC_MERGED_TMP=""
  done <<< "$(agent_ws_metadata_generated_records "$metadata_file" 2>/dev/null || true)"

  # The run completed; disarm the abort-restore handler.
  if [ "$apply" -eq 1 ]; then
    trap - EXIT
  fi

  # Whole-run success: drop the per-file backups. On a conflicted apply run the
  # .bak files of updated files are kept as a restore point (they are gitignored).
  if [ "$apply" -eq 1 ] && [ "$conflicts" -eq 0 ]; then
    local b
    for b in "${AGENT_WS_SYNC_BACKUPS[@]:-}"; do
      [ -n "$b" ] && agent_ws_backup_remove "$b"
    done
  fi

  if [ "$missing_active" -gt 0 ]; then
    agent_ws_advise "$missing_active tracked file(s) are missing from the project; restore them with: agent-ws init (existing files are never overwritten)"
  fi

  agent_ws_section "Summary"
  if [ "$conflicts" -gt 0 ]; then
    if [ "$apply" -eq 1 ]; then
      agent_ws_say "  $conflicts file(s) conflicted; your live files were left unchanged, see the *.merge side-files"
      agent_ws_advise "for each *.merge file: edit it to resolve the conflict markers, replace the live file with the result, delete the *.merge file, then re-run: agent-ws sync --apply"
      agent_ws_advice_flush
    else
      agent_ws_say "  $conflicts file(s) would conflict"
      agent_ws_advise "some of your edits overlap the template changes; running 'agent-ws sync --apply' will keep your files untouched and write *.merge files to resolve by hand"
      agent_ws_advice_flush
      return 0
    fi
    return 1
  fi

  if [ "$apply" -eq 1 ]; then
    agent_ws_say "  sync complete — the project matches the installed templates"
  elif [ "$pending" -gt 0 ]; then
    agent_ws_say "  preview only — $pending file(s) would change; nothing was modified"
    agent_ws_advise "apply the changes above with: agent-ws sync --apply"
  else
    agent_ws_say "  preview only — nothing to change; the project matches the installed templates"
  fi
  agent_ws_advice_flush
  return 0
}
