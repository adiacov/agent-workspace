#!/usr/bin/env bash
# Three-way merge engine and safe-write helpers for sync.
#
# OURS  = the project's active file (local edits)
# BASE  = the per-project baseline (template content last synced from)
# THEIRS= the current template
# A clean merge applies template-only additions while preserving local edits;
# overlapping edits become a conflict that the caller refuses (never auto-resolved).

# Run a three-way merge, writing the merged result to <out>.
# Returns 0 on a clean merge, 1 on conflict. Does not modify any input file.
agent_ws_merge_three_way() {
  local ours="$1" base="$2" theirs="$3" out="$4" status=0
  # git merge-file -p writes the merged content to stdout and exits non-zero
  # (number of conflicts) when conflicts remain.
  git merge-file -p -L active -L baseline -L template "$ours" "$base" "$theirs" > "$out" 2>/dev/null || status=$?
  if [ "$status" -ne 0 ]; then
    return 1
  fi
  return 0
}

# True if the file contains git conflict markers.
agent_ws_has_conflict_markers() {
  local file="$1"
  grep -Eq '^(<<<<<<<|=======|>>>>>>>)' "$file"
}

# Backup helpers. Backups are transient (removed on whole-run success, used to
# restore on failure).
agent_ws_backup_create() {
  local file="$1"
  [ -f "$file" ] || return 0
  cp "$file" "$file.bak"
}

agent_ws_backup_remove() {
  local file="$1"
  rm -f "$file.bak"
}

agent_ws_backup_restore() {
  local file="$1"
  [ -f "$file.bak" ] || return 0
  mv "$file.bak" "$file"
}

# Atomically replace <dest> with the content of <src_tmp>, keeping a .bak of the
# original until the caller confirms whole-run success. <src_tmp> must already
# live on the same filesystem as <dest> (callers create it in dest's directory).
agent_ws_atomic_write() {
  local src_tmp="$1" dest="$2"
  agent_ws_backup_create "$dest"
  mv "$src_tmp" "$dest"
}
