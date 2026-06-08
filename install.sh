#!/usr/bin/env bash
set -euo pipefail

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Usage: ./install.sh --prefix PREFIX

Installs the development checkout payload into PREFIX:
  PREFIX/agent-ws
  PREFIX/lib/agent-ws/
  PREFIX/templates/

Example:
  TMPBIN="$(mktemp -d)"
  ./install.sh --prefix "$TMPBIN"
  PATH="$TMPBIN:$PATH" agent-ws help
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

PREFIX=""
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

[ -n "$PREFIX" ] || die "--prefix is required"

ROOT="$(repo_root)"
[ -f "$ROOT/bin/agent-ws" ] || die "missing bin/agent-ws in repository checkout"
[ -d "$ROOT/lib/agent-ws" ] || die "missing lib/agent-ws in repository checkout"
[ -d "$ROOT/templates" ] || die "missing templates in repository checkout"

mkdir -p "$PREFIX"
cp "$ROOT/bin/agent-ws" "$PREFIX/agent-ws"
chmod +x "$PREFIX/agent-ws"
copy_dir "$ROOT/lib/agent-ws" "$PREFIX/lib/agent-ws"
copy_dir "$ROOT/templates" "$PREFIX/templates"

say "installed agent-ws to $PREFIX/agent-ws"
say "installed libraries to $PREFIX/lib/agent-ws"
say "installed templates to $PREFIX/templates"
