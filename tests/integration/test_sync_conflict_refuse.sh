#!/usr/bin/env bash
set -euo pipefail

# US2: overlapping edits are refused. Live file untouched, *.merge written with
# markers, non-zero exit, no markers in the live file.

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

  # Overlapping change: same first line edited differently in project and template.
  sed -i '1s/.*/PROJECT TITLE EDIT/' WORKFLOWS.md
  sed -i '1s/.*/TEMPLATE TITLE EDIT/' "$TPL/default/WORKFLOWS.md"

  before="$(sha256sum WORKFLOWS.md | awk '{print $1}')"
  rc=0
  "$TMPBIN/bin/agent-ws" sync . --apply > apply.out 2>&1 || rc=$?
  test "$rc" -ne 0 || fail 'sync --apply should exit non-zero on conflict'
  assert_contains 'WORKFLOWS.md: conflicted' apply.out
  test "$before" = "$(sha256sum WORKFLOWS.md | awk '{print $1}')" || fail 'conflict modified live file'
  assert_file_exists WORKFLOWS.md.merge
  assert_contains '<<<<<<<' WORKFLOWS.md.merge
  if grep -Eq '^(<<<<<<<|=======|>>>>>>>)' WORKFLOWS.md; then
    fail 'live file contains conflict markers'
  fi

  # dry-run reports the would-conflict and still exits zero.
  rc=0
  "$TMPBIN/bin/agent-ws" sync . --dry-run > dry.out 2>&1 || rc=$?
  test "$rc" -eq 0 || fail 'dry-run should exit zero'
  assert_contains 'WORKFLOWS.md: would-conflict' dry.out
)

printf 'ok: sync refuses conflicts safely\n'
