#!/usr/bin/env bash
set -euo pipefail

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--prefix PREFIX]

Installs agent-ws for the current user by default.

Default prefix:
  $HOME/.local

Installed layout:
  PREFIX/bin/agent-ws
  PREFIX/lib/agent-ws/
  PREFIX/share/agent-ws/templates/

Examples:
  ./install.sh
  ./install.sh --prefix "$HOME/.local"

After install, ensure PREFIX/bin is on PATH.
USAGE
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P
}

copy_dir() {
  local src="$1" dst="$2"
  rm -rf "$dst"
  mkdir -p "$(dirname "$dst")"
  cp -R "$src" "$dst"
}

PREFIX="${HOME:-}/.local"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --prefix)
      [ "$#" -ge 2 ] || die "--prefix requires a value"
      PREFIX="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

[ -n "$PREFIX" ] || die "unable to determine install prefix; pass --prefix PREFIX"

ROOT="$(repo_root)"
[ -f "$ROOT/bin/agent-ws" ] || die "missing bin/agent-ws in repository checkout"
[ -d "$ROOT/lib/agent-ws" ] || die "missing lib/agent-ws in repository checkout"
[ -d "$ROOT/templates" ] || die "missing templates in repository checkout"

mkdir -p "$PREFIX/bin" "$PREFIX/lib" "$PREFIX/share/agent-ws"
cp "$ROOT/bin/agent-ws" "$PREFIX/bin/agent-ws"
chmod +x "$PREFIX/bin/agent-ws"
copy_dir "$ROOT/lib/agent-ws" "$PREFIX/lib/agent-ws"
copy_dir "$ROOT/templates" "$PREFIX/share/agent-ws/templates"

say "installed agent-ws to $PREFIX/bin/agent-ws"
say "installed libraries to $PREFIX/lib/agent-ws"
say "installed templates to $PREFIX/share/agent-ws/templates"
say "ensure $PREFIX/bin is on PATH"
