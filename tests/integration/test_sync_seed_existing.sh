#!/usr/bin/env bash
set -euo pipefail

# US3: a project with no baseline is seeded on first sync (nothing destructive,
# gitignore exclusions ensured), and a later template change then merges cleanly.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"; PROJECT="$(mktemp -d)"; TPL="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$PROJECT" "$TPL"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
cp -R "$ROOT"/templates/* "$TPL"/
export AGENT_WS_TEMPLATE_SOURCE_DIR="$TPL"

(
  cd "$PROJECT"
  "$TMPBIN/bin/agent-ws" init --profile general --agents pi --no-prompt >/dev/null

  # Simulate a pre-feature project: no baseline, and a .gitignore lacking exclusions.
  rm -rf .agent-workspace/baseline
  rm -f .gitignore

  before="$(sha256sum WORKFLOWS.md | awk '{print $1}')"
  "$TMPBIN/bin/agent-ws" sync . --apply > seed.out
  assert_contains 'WORKFLOWS.md: seeded' seed.out
  assert_dir_exists .agent-workspace/baseline
  assert_file_exists .agent-workspace/baseline/WORKFLOWS.md
  test "$before" = "$(sha256sum WORKFLOWS.md | awk '{print $1}')" || fail 'seeding modified active file'
  grep -qxF '.agent-workspace/baseline/' .gitignore || fail 'seeding did not ensure gitignore exclusion'

  # Now a published template change reconciles normally.
  awk 'NR==1{print; print ""; print "## SeededThenAdded"; next} {print}' \
    "$TPL/default/WORKFLOWS.md" > "$TPL/default/WORKFLOWS.md.new"
  mv "$TPL/default/WORKFLOWS.md.new" "$TPL/default/WORKFLOWS.md"
  "$TMPBIN/bin/agent-ws" sync . --apply > apply.out
  assert_contains 'WORKFLOWS.md: updated' apply.out
  assert_contains '## SeededThenAdded' WORKFLOWS.md
)

printf 'ok: sync seeds baseline for existing projects\n'
