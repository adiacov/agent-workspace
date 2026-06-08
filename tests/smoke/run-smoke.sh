#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

printf 'smoke: agent-ws help\n'
"$ROOT/bin/agent-ws" help >/dev/null

printf 'smoke: install.sh help\n'
"$ROOT/install.sh" --help >/dev/null

printf 'smoke: bootstrap transition message\n'
"$ROOT/bootstrap.sh" >/dev/null

printf 'smoke: ok\n'
