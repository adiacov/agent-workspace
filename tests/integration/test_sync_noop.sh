#!/usr/bin/env bash
set -euo pipefail

# US1: when the template has no incoming change, sync reports unchanged and
# writes nothing.

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
  before="$(sha256sum WORKFLOWS.md | awk '{print $1}')"
  "$TMPBIN/bin/agent-ws" sync . --apply > apply.out
  assert_contains 'WORKFLOWS.md: unchanged' apply.out
  test "$before" = "$(sha256sum WORKFLOWS.md | awk '{print $1}')" || fail 'no-op sync modified active file'
  assert_not_exists WORKFLOWS.md.bak
  assert_not_exists WORKFLOWS.md.merge
)

printf 'ok: sync no-op when template unchanged\n'
