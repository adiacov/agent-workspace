#!/usr/bin/env bash
set -euo pipefail

# migrate infers the profile from preserved files instead of assuming general:
# ENGINEERING.md -> code, cockpit files -> cockpit, otherwise general.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"; WORK="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$WORK"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null

migrated_profile() {
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["profile"])' "$1/.agent-workspace/workspace.json"
}

mkdir -p "$WORK/code-proj"
touch "$WORK/code-proj/AGENTS.md" "$WORK/code-proj/WORKFLOWS.md" "$WORK/code-proj/ENGINEERING.md"
"$TMPBIN/bin/agent-ws" migrate "$WORK/code-proj" --apply >/dev/null
test "$(migrated_profile "$WORK/code-proj")" = "code" || fail 'ENGINEERING.md project should migrate as code'

mkdir -p "$WORK/cockpit-proj"
touch "$WORK/cockpit-proj/PROJECTS.md" "$WORK/cockpit-proj/WORKFLOWS-COCKPIT.md" "$WORK/cockpit-proj/ENGINEERING.md"
"$TMPBIN/bin/agent-ws" migrate "$WORK/cockpit-proj" --apply >/dev/null
test "$(migrated_profile "$WORK/cockpit-proj")" = "cockpit" || fail 'cockpit files should win over ENGINEERING.md'

mkdir -p "$WORK/general-proj"
touch "$WORK/general-proj/WORKFLOWS.md" "$WORK/general-proj/STATE.md"
"$TMPBIN/bin/agent-ws" migrate "$WORK/general-proj" --apply >/dev/null
test "$(migrated_profile "$WORK/general-proj")" = "general" || fail 'plain project should migrate as general'

# dry-run reports the detected profile without writing anything.
mkdir -p "$WORK/dry-proj"
touch "$WORK/dry-proj/ENGINEERING.md"
"$TMPBIN/bin/agent-ws" migrate "$WORK/dry-proj" --dry-run > "$WORK/dry.out"
assert_contains 'would create: .agent-workspace/workspace.json (profile: code)' "$WORK/dry.out"
assert_not_exists "$WORK/dry-proj/.agent-workspace/workspace.json"

printf 'ok: migrate detects profile from preserved files\n'
