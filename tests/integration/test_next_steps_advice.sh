#!/usr/bin/env bash
set -euo pipefail

# Commands end with a "Next steps" block recommending concrete commands for
# the detected state, or an "All good" line when there is nothing to do.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"; WORK="$(mktemp -d)"; TPL="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$WORK" "$TPL"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
AW="$TMPBIN/bin/agent-ws"

# status: uninitialized dir -> init; hand-made files -> migrate.
mkdir -p "$WORK/bare" "$WORK/handmade"
touch "$WORK/handmade/WORKFLOWS.md"
"$AW" status "$WORK/bare" > "$WORK/bare.out"
assert_contains 'Next steps:' "$WORK/bare.out"
assert_contains 'agent-ws init' "$WORK/bare.out"
"$AW" status "$WORK/handmade" > "$WORK/handmade.out"
assert_contains 'agent-ws migrate --dry-run' "$WORK/handmade.out"

# migrate: dry-run suggests --apply; apply suggests sync + status.
"$AW" migrate "$WORK/handmade" --dry-run > "$WORK/migrate-dry.out"
assert_contains 'agent-ws migrate --apply' "$WORK/migrate-dry.out"
"$AW" migrate "$WORK/handmade" --apply > "$WORK/migrate-apply.out"
assert_contains 'agent-ws sync --apply' "$WORK/migrate-apply.out"
assert_contains 'agent-ws status' "$WORK/migrate-apply.out"

# healthy project: status and diff report all-clear, no advice block.
cp -R "$ROOT"/templates/. "$TPL"
export AGENT_WS_TEMPLATE_SOURCE_DIR="$TPL"
mkdir -p "$WORK/healthy"
(cd "$WORK/healthy" && "$AW" init --profile general --agents pi --no-prompt >/dev/null && "$AW" sync . --apply >/dev/null)
"$AW" status "$WORK/healthy" > "$WORK/healthy.out"
assert_contains 'All good:' "$WORK/healthy.out"
if grep -F 'Next steps:' "$WORK/healthy.out" >/dev/null; then
  fail 'healthy project should not get next-steps advice'
fi

# template changed: status recommends diff+sync; diff recommends sync; sync
# dry-run recommends --apply.
printf '\nnew template line\n' >> "$TPL/default/WORKFLOWS.md"
"$AW" status "$WORK/healthy" > "$WORK/outdated.out"
assert_contains 'agent-ws diff' "$WORK/outdated.out"
assert_contains 'agent-ws sync --apply' "$WORK/outdated.out"
"$AW" diff "$WORK/healthy" > "$WORK/diff.out"
assert_contains 'agent-ws sync --apply' "$WORK/diff.out"
"$AW" sync "$WORK/healthy" --dry-run > "$WORK/sync-dry.out"
assert_contains 'apply the changes above with: agent-ws sync --apply' "$WORK/sync-dry.out"

# update dry-run on the current version reports already up to date.
AGENT_WS_TEST_RELEASES="$(tr -d '[:space:]' < "$ROOT/VERSION")" "$AW" update --dry-run > "$WORK/update.out"
assert_contains 'already up to date' "$WORK/update.out"

printf 'ok: next-steps advice per command\n'
