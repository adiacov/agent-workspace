#!/usr/bin/env bash
set -euo pipefail

# US4: content files (STATE.md, PROJECT.md) are never synced, even when fully
# rewritten and even when their template seed differs.

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

  printf '# fully rewritten state\n' > STATE.md
  printf '# fully rewritten project\n' > PROJECT.md
  # change the content templates too, to prove they are still skipped
  printf '# template state changed\n' > "$TPL/default/STATE.md"
  printf '# template project changed\n' > "$TPL/default/PROJECT.md"

  s_before="$(sha256sum STATE.md | awk '{print $1}')"
  p_before="$(sha256sum PROJECT.md | awk '{print $1}')"

  "$TMPBIN/bin/agent-ws" sync . --dry-run > dry.out
  "$TMPBIN/bin/agent-ws" sync . --apply > apply.out
  assert_contains 'STATE.md: skipped-content' apply.out
  assert_contains 'PROJECT.md: skipped-content' apply.out
  test "$s_before" = "$(sha256sum STATE.md | awk '{print $1}')" || fail 'STATE.md was modified'
  test "$p_before" = "$(sha256sum PROJECT.md | awk '{print $1}')" || fail 'PROJECT.md was modified'
)

printf 'ok: sync skips content files\n'
