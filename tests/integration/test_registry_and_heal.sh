#!/usr/bin/env bash
set -euo pipefail

# Registry: projects self-register when the tool confirms they are managed;
# 'projects' lists them with a one-word state and prunes dead entries.
# Heal: one preview-first command takes a legacy project to in-sync.
# Discover: reports project roots only, pruning matches inside a project.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/tests/integration/helpers.sh"
TMPBIN="$(mktemp -d)"; WORK="$(mktemp -d)"
trap 'rm -rf "$TMPBIN" "$WORK"' EXIT
"$ROOT/install.sh" --prefix "$TMPBIN" >/dev/null
AW="$TMPBIN/bin/agent-ws"
export AGENT_WS_REGISTRY_FILE="$WORK/registry"

# init registers the project.
mkdir -p "$WORK/one"
(cd "$WORK/one" && "$AW" init --profile general --agents pi --no-prompt >/dev/null)
assert_contains "$WORK/one" "$AGENT_WS_REGISTRY_FILE"

# status on a managed-but-unregistered project backfills the registry.
mkdir -p "$WORK/two"
(cd "$WORK/two" && "$AW" init --profile general --agents pi --no-prompt >/dev/null)
: > "$AGENT_WS_REGISTRY_FILE"
"$AW" status "$WORK/two" >/dev/null
assert_contains "$WORK/two" "$AGENT_WS_REGISTRY_FILE"

# discover does not register.
: > "$AGENT_WS_REGISTRY_FILE"
"$AW" discover "$WORK" >/dev/null
if grep -q . "$AGENT_WS_REGISTRY_FILE"; then
  fail 'discover must not write the registry'
fi

# discover reports the project root once, without its internals.
"$AW" discover "$WORK" > "$WORK/discover.out"
count=$(grep -c "^$WORK/one " "$WORK/discover.out" || true)
test "$count" -eq 1 || fail "expected exactly one line for the project root, got $count"
if grep -q 'baseline' "$WORK/discover.out"; then
  fail 'discover leaked project internals (baseline dir)'
fi

# projects lists registered paths with a state, prunes dead entries.
"$AW" status "$WORK/one" >/dev/null; "$AW" status "$WORK/two" >/dev/null
printf '%s\n' "$WORK/gone" >> "$AGENT_WS_REGISTRY_FILE"
"$AW" projects > "$WORK/projects.out"
assert_contains "$WORK/one" "$WORK/projects.out"
if grep -q "$WORK/gone" "$WORK/projects.out"; then
  fail 'projects should prune entries whose directory is gone'
fi
if grep -q "$WORK/gone" "$AGENT_WS_REGISTRY_FILE"; then
  fail 'registry file should be pruned on listing'
fi

# heal: legacy project -> plan on dry-run, in-sync after apply, registered.
mkdir -p "$WORK/old/bin" "$WORK/old/.agent/templates"
touch "$WORK/old/AGENTS.md" "$WORK/old/STATE.md" "$WORK/old/ENGINEERING.md" "$WORK/old/bin/agent-workspace"
"$AW" heal "$WORK/old" > "$WORK/heal-dry.out"
assert_contains 'state: legacy' "$WORK/heal-dry.out"
assert_contains 'agent-ws heal --apply' "$WORK/heal-dry.out"
assert_not_exists "$WORK/old/.agent-workspace/workspace.json"
"$AW" heal "$WORK/old" --apply > "$WORK/heal-apply.out"
assert_contains 'healed' "$WORK/heal-apply.out"
assert_file_exists "$WORK/old/.agent-workspace/workspace.json"
assert_file_exists "$WORK/old/PROJECT.md"
"$AW" status "$WORK/old" | grep -q 'All good' || fail 'healed project should report All good'
assert_contains "$WORK/old" "$AGENT_WS_REGISTRY_FILE"

# heal on a healthy project is a no-op; on an empty dir it defers to init.
"$AW" heal "$WORK/old" | grep -q 'already healthy' || fail 'healthy project should be a heal no-op'
mkdir -p "$WORK/empty"
"$AW" heal "$WORK/empty" | grep -q 'agent-ws init' || fail 'empty dir heal should defer to init'

printf 'ok: registry, projects listing, root-only discover, heal\n'
