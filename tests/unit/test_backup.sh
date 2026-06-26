#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/lib/agent-ws/merge.sh"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail() { printf 'not ok: %s\n' "$*" >&2; exit 1; }

f="$TMP/file"
printf 'original\n' > "$f"

agent_ws_backup_create "$f"
[ -f "$f.bak" ] || fail "backup not created"
cmp -s "$f" "$f.bak" || fail "backup differs from original"

# simulate a write, then restore from backup
printf 'corrupted\n' > "$f"
agent_ws_backup_restore "$f"
grep -q 'original' "$f" || fail "restore did not recover original"
[ ! -f "$f.bak" ] || fail "restore should consume the backup"

# create then remove on success
agent_ws_backup_create "$f"
agent_ws_backup_remove "$f"
[ ! -f "$f.bak" ] || fail "backup not removed on success"

# atomic write replaces dest and leaves a backup until removed
printf 'new content\n' > "$TMP/incoming"
agent_ws_atomic_write "$TMP/incoming" "$f"
grep -q 'new content' "$f" || fail "atomic write did not replace dest"
[ -f "$f.bak" ] || fail "atomic write should leave a backup"
agent_ws_backup_remove "$f"

printf 'ok: unit backup + atomic write\n'
