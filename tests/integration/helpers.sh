#!/usr/bin/env bash
set -euo pipefail

TEST_TMPDIR="${TEST_TMPDIR:-}"

fail() {
  printf 'not ok: %s\n' "$*" >&2
  exit 1
}

assert_file_exists() {
  local path="$1"
  [ -f "$path" ] || fail "expected file to exist: $path"
}

assert_dir_exists() {
  local path="$1"
  [ -d "$path" ] || fail "expected directory to exist: $path"
}

assert_not_exists() {
  local path="$1"
  [ ! -e "$path" ] || fail "expected path to be absent: $path"
}

make_test_workspace() {
  TEST_TMPDIR="$(mktemp -d)"
  printf '%s\n' "$TEST_TMPDIR"
}

cleanup_test_workspace() {
  if [ -n "${TEST_TMPDIR:-}" ] && [ -d "$TEST_TMPDIR" ]; then
    rm -rf "$TEST_TMPDIR"
  fi
}
