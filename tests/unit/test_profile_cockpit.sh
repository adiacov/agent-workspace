#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
. "$ROOT/lib/agent-ws/templates.sh"

fail() { printf 'not ok: %s\n' "$*" >&2; exit 1; }

# cockpit profile lists exactly its three added files with correct kinds.
cockpit_profile="$(agent_ws_profile_template_files cockpit)"
for expected in \
  'profiles/cockpit/PROJECTS.md:PROJECTS.md:context' \
  'profiles/cockpit/PROFILE.md:PROFILE.md:context' \
  'profiles/cockpit/WORKFLOWS-COCKPIT.md:WORKFLOWS-COCKPIT.md:profile'; do
  printf '%s\n' "$cockpit_profile" | grep -Fxq "$expected" \
    || fail "cockpit profile missing: $expected"
done
[ "$(printf '%s\n' "$cockpit_profile" | grep -c .)" -eq 3 ] \
  || fail "cockpit profile should list exactly 3 files"

# cockpit overrides only the STATE.md source in the default file set.
cockpit_default="$(agent_ws_default_template_files cockpit)"
printf '%s\n' "$cockpit_default" | grep -Fxq 'profiles/cockpit/STATE.md:STATE.md:context' \
  || fail "cockpit default should swap STATE.md source"

# general/code default sets are unchanged (still the base STATE.md).
for prof in "" general code; do
  base_default="$(agent_ws_default_template_files "$prof")"
  printf '%s\n' "$base_default" | grep -Fxq 'default/STATE.md:STATE.md:context' \
    || fail "profile '$prof' default STATE.md must be default/STATE.md"
done

# general adds nothing; code adds only ENGINEERING.md (regression guard).
[ -z "$(agent_ws_profile_template_files general)" ] || fail "general must add no profile files"
code_profile="$(agent_ws_profile_template_files code)"
[ "$code_profile" = 'profiles/software/ENGINEERING.md:ENGINEERING.md:profile' ] \
  || fail "code profile file set changed"

# WORKFLOWS-COCKPIT.md is a framework file (syncable); the content files are not.
agent_ws_file_is_framework profile || fail "profile kind should be framework"
agent_ws_file_is_framework context && fail "context kind should not be framework"

printf 'ok: unit cockpit profile file set + STATE override\n'
