#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/lib/agent-ws/merge.sh"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail() { printf 'not ok: %s\n' "$*" >&2; exit 1; }

# base / ours (top addition) / theirs (bottom addition): non-overlapping → clean.
printf 'line1\nline2\nline3\n' > "$TMP/base"
printf 'OURS-TOP\nline1\nline2\nline3\n' > "$TMP/ours"
printf 'line1\nline2\nline3\nTHEIRS-BOTTOM\n' > "$TMP/theirs"
if agent_ws_merge_three_way "$TMP/ours" "$TMP/base" "$TMP/theirs" "$TMP/out"; then :; else
  fail "expected clean merge to return 0"
fi
grep -q 'OURS-TOP' "$TMP/out" || fail "clean merge dropped ours"
grep -q 'THEIRS-BOTTOM' "$TMP/out" || fail "clean merge dropped theirs"
agent_ws_has_conflict_markers "$TMP/out" && fail "clean merge should have no markers"

# overlapping change to the same line → conflict.
printf 'OURS-EDIT\nline2\nline3\n' > "$TMP/ours2"
printf 'THEIRS-EDIT\nline2\nline3\n' > "$TMP/theirs2"
if agent_ws_merge_three_way "$TMP/ours2" "$TMP/base" "$TMP/theirs2" "$TMP/out2"; then
  fail "expected conflicting merge to return non-zero"
fi
agent_ws_has_conflict_markers "$TMP/out2" || fail "conflict output missing markers"

printf 'ok: unit merge three-way (clean + conflict)\n'
