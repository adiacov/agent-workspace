#!/usr/bin/env bash
set -euo pipefail

# US1: a new template section merges into a locally-edited framework file,
# preserving local edits. Dry-run mutates nothing; apply leaves no .bak/.merge.

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

  # Local edit at end of the project file.
  printf '\n# LOCAL PROJECT NOTE\n' >> WORKFLOWS.md
  # Published template change: insert a new section near the top (non-overlapping).
  awk 'NR==1{print; print ""; print "## AddedByTemplate"; print "template body"; next} {print}' \
    "$TPL/default/WORKFLOWS.md" > "$TPL/default/WORKFLOWS.md.new"
  mv "$TPL/default/WORKFLOWS.md.new" "$TPL/default/WORKFLOWS.md"

  before="$(sha256sum WORKFLOWS.md | awk '{print $1}')"
  "$TMPBIN/bin/agent-ws" sync . --dry-run > dry.out
  assert_contains 'WORKFLOWS.md: would-update' dry.out
  test "$before" = "$(sha256sum WORKFLOWS.md | awk '{print $1}')" || fail 'dry-run modified active file'

  "$TMPBIN/bin/agent-ws" sync . --apply > apply.out
  assert_contains 'WORKFLOWS.md: updated' apply.out
  assert_contains '# LOCAL PROJECT NOTE' WORKFLOWS.md
  assert_contains '## AddedByTemplate' WORKFLOWS.md
  assert_not_exists WORKFLOWS.md.bak
  assert_not_exists WORKFLOWS.md.merge
)

printf 'ok: sync additive merge preserves local edits\n'
