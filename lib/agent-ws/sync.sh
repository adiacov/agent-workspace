#!/usr/bin/env bash
# Merge-based sync: reconcile published template changes into a project's
# framework files using a per-project baseline three-way merge.
#
# Per file outcomes: unchanged | updated | seeded | conflicted |
#                    missing-active | missing-template | skipped-content
# A run exits non-zero if any file is conflicted.

agent_ws_sync_project() {
  local project_root="$1" mode="$2"
  project_root="$(agent_ws_existing_project_root "$project_root")"

  local metadata_file metadata_status template_dir
  metadata_file="$(agent_ws_metadata_path "$project_root")"
  metadata_status="$(agent_ws_metadata_status "$project_root")"

  agent_ws_say "sync: $mode"
  agent_ws_say "project: $project_root"
  agent_ws_say "metadata: $metadata_status"

  if [ "$mode" != "dry-run" ] && [ "$mode" != "apply" ]; then
    agent_ws_die "unknown sync mode: $mode" "run 'agent-ws sync --dry-run' or 'agent-ws sync --apply'."
  fi

  if [ ! -f "$metadata_file" ]; then
    agent_ws_say "no metadata mappings available"
    return 0
  fi

  template_dir="$(agent_ws_template_source_dir 2>/dev/null || true)"
  if [ -z "$template_dir" ]; then
    agent_ws_say "template source: missing"
    return 0
  fi
  agent_ws_say "template source: $template_dir"

  local apply=0
  [ "$mode" = "apply" ] && apply=1

  local conflicts=0 seeded_any=0
  local backups=()   # files we backed up this run (for cleanup/restore)

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
      agent_ws_say "$path: skipped-content"
      continue
    fi
    if [ ! -f "$template_file" ]; then
      agent_ws_say "$path: missing-template"
      continue
    fi
    if [ ! -f "$active" ]; then
      agent_ws_say "$path: missing-active"
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
        agent_ws_say "$path: seeded"
      else
        agent_ws_say "$path: would-seed"
      fi
      continue
    fi

    # Baseline present: if the template has no incoming change, nothing to do.
    if cmp -s "$baseline" "$template_file"; then
      agent_ws_say "$path: unchanged"
      continue
    fi

    # Three-way merge into a temp file in the active file's directory.
    local merged status=0
    merged="$(mktemp "$(dirname "$active")/.agent-ws-merge.XXXXXX")"
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
        agent_ws_say "$path: conflicted (wrote $path.merge)"
      else
        rm -f "$merged"
        agent_ws_say "$path: would-conflict"
      fi
      continue
    fi

    # Clean merge. If it changes nothing, just advance the baseline.
    if cmp -s "$merged" "$active"; then
      rm -f "$merged"
      if [ "$apply" -eq 1 ]; then
        agent_ws_baseline_write "$project_root" "$path" "$template_file"
      fi
      agent_ws_say "$path: unchanged"
      continue
    fi

    if [ "$apply" -eq 1 ]; then
      agent_ws_atomic_write "$merged" "$active"
      backups+=("$active")
      agent_ws_baseline_write "$project_root" "$path" "$template_file"
      agent_ws_say "$path: updated"
    else
      rm -f "$merged"
      agent_ws_say "$path: would-update"
    fi
  done <<< "$(agent_ws_metadata_generated_records "$metadata_file" 2>/dev/null || true)"

  # Whole-run success: drop the per-file backups.
  if [ "$apply" -eq 1 ]; then
    local b
    for b in "${backups[@]:-}"; do
      [ -n "$b" ] && agent_ws_backup_remove "$b"
    done
  fi

  if [ "$conflicts" -gt 0 ]; then
    if [ "$apply" -eq 1 ]; then
      agent_ws_say "$conflicts file(s) conflicted; live files unchanged, see *.merge"
    else
      agent_ws_say "$conflicts file(s) would conflict"
      return 0
    fi
    return 1
  fi

  agent_ws_say "sync complete"
  return 0
}
