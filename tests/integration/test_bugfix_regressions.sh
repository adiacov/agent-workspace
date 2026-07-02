#!/usr/bin/env bash
set -euo pipefail

# Regressions: named-path init honors the parent-git-repo guard, an invalid
# agent cannot leave a half-initialized project, a Markdown setext '======='
# underline in a clean merge is not misread as a conflict, and update picks
# the semver-max stable release rather than the last-listed one.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"; WORK="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$WORK"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null

# init <path> inside a parent git repository is refused, like init in ".".
mkdir -p "$WORK/repo" && git -C "$WORK/repo" init -q
rc=0
(cd "$WORK/repo" && "$TMPBIN/bin/agent-ws" init sub --profile code --agents pi --no-prompt) >/dev/null 2>&1 || rc=$?
test "$rc" -ne 0 || fail 'init <path> inside a git repo should be refused'
assert_not_exists "$WORK/repo/sub/PROJECT.md"

# an unsupported agent fails before any file is written.
mkdir -p "$WORK/badagent"
rc=0
(cd "$WORK/badagent" && "$TMPBIN/bin/agent-ws" init --profile code --agents bogus --no-prompt) >/dev/null 2>&1 || rc=$?
test "$rc" -ne 0 || fail 'init with an unsupported agent should fail'
test -z "$(ls -A "$WORK/badagent")" || fail 'failed init left files behind'

# a clean merge whose result contains a setext underline is not a conflict.
mkdir -p "$WORK/setext" "$WORK/tpl-copy"
cp -R "$ROOT"/templates/. "$WORK/tpl-copy"
printf 'Title\n=======\nshared line\n' > "$WORK/tpl-copy/default/WORKFLOWS.md"
(
  cd "$WORK/setext"
  export AGENT_WS_TEMPLATE_SOURCE_DIR="$WORK/tpl-copy"
  "$TMPBIN/bin/agent-ws" init --profile general --agents pi --no-prompt >/dev/null
  printf 'local tail\n' >> WORKFLOWS.md
  sed -i '1i template head' "$WORK/tpl-copy/default/WORKFLOWS.md"
  "$TMPBIN/bin/agent-ws" sync . --apply > sync.out 2>&1
  assert_contains 'WORKFLOWS.md: updated' sync.out
  assert_contains 'local tail' WORKFLOWS.md
  assert_contains 'template head' WORKFLOWS.md
  assert_not_exists WORKFLOWS.md.merge
)

# latest stable is the semver max, not the last-listed release.
AGENT_WS_TEST_RELEASES='v2.0.0 v1.0.0 v1.9.0' "$TMPBIN/bin/agent-ws" update --dry-run > "$WORK/update.out"
assert_contains 'latest stable: v2.0.0' "$WORK/update.out"

printf 'ok: bugfix regressions\n'
