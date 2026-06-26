#!/usr/bin/env bash
set -euo pipefail

# US4: diff shows the incoming baseline->template delta for framework files only,
# is read-only, plain under NO_COLOR, and never flags content files.

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

  # A local edit must NOT appear in the diff (diff shows incoming template delta).
  printf '\n# LOCAL ONLY EDIT\n' >> WORKFLOWS.md
  # Published template change:
  awk 'NR==1{print; print ""; print "## IncomingProbeSection"; next} {print}' \
    "$TPL/default/WORKFLOWS.md" > "$TPL/default/WORKFLOWS.md.new"
  mv "$TPL/default/WORKFLOWS.md.new" "$TPL/default/WORKFLOWS.md"

  before="$(sha256sum WORKFLOWS.md | awk '{print $1}')"
  NO_COLOR=1 "$TMPBIN/bin/agent-ws" diff . > diff.out
  test "$before" = "$(sha256sum WORKFLOWS.md | awk '{print $1}')" || fail 'diff modified active file'

  assert_contains 'incoming: WORKFLOWS.md' diff.out
  assert_contains 'IncomingProbeSection' diff.out
  grep -F 'LOCAL ONLY EDIT' diff.out && fail 'diff leaked local edit (should show template delta only)' || true
  grep -E '^incoming: (STATE|PROJECT)\.md' diff.out && fail 'diff flagged a content file' || true
  # NO_COLOR output must be plain (no ANSI escapes)
  if grep -q $'\033' diff.out; then fail 'NO_COLOR diff contained ANSI escapes'; fi
)

printf 'ok: diff shows incoming template delta, scoped and plain\n'
