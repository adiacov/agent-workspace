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

assert_contains() {
  local needle="$1" file="$2"
  grep -F "$needle" "$file" >/dev/null || fail "expected $file to contain: $needle"
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

fixture_matrix() {
  cat <<'MATRIX'
clean              no Agent Workspace files
partial            some active files, no metadata
legacy             .agent/ and/or bin/agent-workspace legacy signals
managed            valid .agent-workspace/workspace.json plus active files
invalid-metadata   malformed or schema-invalid workspace metadata
stale-metadata     valid metadata referencing unavailable template source/revision
MATRIX
}

fixture_clean_project() {
  local root="$1"
  mkdir -p "$root/clean"
  printf '%s\n' "$root/clean"
}

fixture_partial_project() {
  local root="$1"
  mkdir -p "$root/partial"
  touch "$root/partial/WORKFLOWS.md" "$root/partial/AGENTS.md"
  printf '%s\n' "$root/partial"
}

fixture_legacy_project() {
  local root="$1"
  mkdir -p "$root/legacy/.agent" "$root/legacy/bin"
  touch "$root/legacy/bin/agent-workspace" "$root/legacy/AGENTS.md" "$root/legacy/STATE.md" "$root/legacy/BRAINSTORM.md"
  printf '%s\n' "$root/legacy"
}

fixture_managed_project() {
  local root="$1"
  mkdir -p "$root/managed/.agent-workspace"
  touch "$root/managed/WORKFLOWS.md" "$root/managed/PROJECT.md" "$root/managed/STATE.md" "$root/managed/AGENTS.md"
  cat > "$root/managed/.agent-workspace/workspace.json" <<'JSON'
{
  "schemaVersion": 1,
  "toolName": "agent-ws",
  "toolVersion": "test",
  "templateRevision": "test",
  "profile": "general",
  "agents": ["pi"],
  "generatedFiles": {},
  "createdAt": "2026-06-08T00:00:00Z",
  "updatedAt": "2026-06-08T00:00:00Z"
}
JSON
  printf '%s\n' "$root/managed"
}

fixture_invalid_metadata_project() {
  local root="$1"
  mkdir -p "$root/invalid-metadata/.agent-workspace"
  printf '{invalid json\n' > "$root/invalid-metadata/.agent-workspace/workspace.json"
  printf '%s\n' "$root/invalid-metadata"
}

fixture_stale_metadata_project() {
  local root="$1"
  mkdir -p "$root/stale-metadata/.agent-workspace"
  cat > "$root/stale-metadata/.agent-workspace/workspace.json" <<'JSON'
{
  "schemaVersion": 1,
  "toolName": "agent-ws",
  "toolVersion": "test",
  "templateRevision": "missing-test-revision",
  "profile": "general",
  "agents": ["pi"],
  "generatedFiles": {"AGENTS.md": {"kind": "adapter", "agent": "pi", "template": "adapters/pi/AGENTS.md"}},
  "createdAt": "2026-06-08T00:00:00Z",
  "updatedAt": "2026-06-08T00:00:00Z"
}
JSON
  printf '%s\n' "$root/stale-metadata"
}

build_fixture_matrix() {
  local root="$1"
  fixture_clean_project "$root" >/dev/null
  fixture_partial_project "$root" >/dev/null
  fixture_legacy_project "$root" >/dev/null
  fixture_managed_project "$root" >/dev/null
  fixture_invalid_metadata_project "$root" >/dev/null
  fixture_stale_metadata_project "$root" >/dev/null
}
