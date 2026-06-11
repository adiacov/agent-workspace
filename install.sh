#!/usr/bin/env bash
set -euo pipefail

say() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

install_error() {
  local stage="$1" message="$2" next="${3:-retry after fixing the reported problem.}"
  printf 'error: install failed during %s: %s\n' "$stage" "$message" >&2
  printf 'next: %s\n' "$next" >&2
  exit 1
}

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
  PREFIX/share/agent-ws/VERSION

Environment:
  AGENT_WS_PREFIX          Install prefix for curl/remote usage.
  AGENT_WS_VERSION         Specific release/tag to install.
  AGENT_WS_REPO            GitHub repository, owner/name.
  AGENT_WS_INSTALL_BASE_URL  Override archive base URL for tests/mirrors.
  AGENT_WS_TEST_RELEASES   Space-separated release list for tests.

Examples:
  ./install.sh
  ./install.sh --prefix "$HOME/.local"
  AGENT_WS_VERSION=v0.1.0 curl -fsSL <install-url> | bash

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

install_is_stable_version() {
  local version="$1" lower
  lower="$(printf '%s' "$version" | tr '[:upper:]' '[:lower:]')"
  case "$lower" in
    *alpha*|*beta*|*rc*|*pre*) return 1 ;;
    v[0-9]*.[0-9]*.[0-9]*) return 0 ;;
    *) return 1 ;;
  esac
}

install_release_list_contains() {
  local requested="$1" candidate
  [ -n "${AGENT_WS_TEST_RELEASES:-}" ] || return 0
  for candidate in ${AGENT_WS_TEST_RELEASES}; do
    [ "$candidate" = "$requested" ] && return 0
  done
  return 1
}

install_select_version() {
  local version stable=""
  if [ -n "${AGENT_WS_VERSION:-}" ]; then
    install_is_stable_version "$AGENT_WS_VERSION" || install_error "release resolution" "requested version is not a stable vMAJOR.MINOR.PATCH release: $AGENT_WS_VERSION" "choose a stable release such as v0.1.0."
    install_release_list_contains "$AGENT_WS_VERSION" || install_error "release resolution" "requested release is unavailable: $AGENT_WS_VERSION" "choose an available stable release."
    printf '%s\n' "$AGENT_WS_VERSION"
    return 0
  fi
  for version in ${AGENT_WS_TEST_RELEASES:-}; do
    if install_is_stable_version "$version"; then
      stable="$version"
    fi
  done
  if [ -n "$stable" ]; then
    printf '%s\n' "$stable"
    return 0
  fi
  install_error "release resolution" "no stable release is available" "set AGENT_WS_VERSION to an available vMAJOR.MINOR.PATCH tag."
}

install_stage_create() {
  mktemp -d "${TMPDIR:-/tmp}/agent-ws-install.XXXXXX"
}

install_stage_cleanup() {
  local stage="${1:-}"
  [ -n "$stage" ] && [ -d "$stage" ] && rm -rf "$stage"
}

install_validate_candidate() {
  local candidate_prefix="$1" expected_version="${2:-}" command reported_version
  command="$candidate_prefix/bin/agent-ws"
  [ -x "$command" ] || install_error "validation" "candidate command is not executable: $command" "check the release payload layout."
  if ! reported_version="$($command version 2>/dev/null)"; then
    # Phase 2 introduced the validation hook before the version command was wired
    # into the active CLI. Fall back to help for existing local installs so the
    # helper remains compatible with older development payloads.
    "$command" help >/dev/null 2>&1 || install_error "validation" "candidate command cannot run" "check the staged payload before activation."
    return 0
  fi
  if [ -n "$expected_version" ]; then
    case "$reported_version" in
      *"$expected_version"*) ;;
      *) install_error "validation" "candidate reported '$reported_version', expected $expected_version" "check the selected release payload." ;;
    esac
  fi
}

install_replace_file() {
  local src="$1" dst="$2" tmp
  mkdir -p "$(dirname "$dst")"
  tmp="$dst.tmp.$$"
  cp "$src" "$tmp" || install_error "activation" "unable to stage file $(basename "$dst")" "check write permissions for $(dirname "$dst")."
  mv "$tmp" "$dst" || install_error "activation" "unable to activate file $(basename "$dst")" "check write permissions for $(dirname "$dst")."
}

install_replace_dir() {
  local src="$1" dst="$2" new="$2.new.$$" old="$2.old.$$"
  mkdir -p "$(dirname "$dst")"
  rm -rf "$new" "$old"
  cp -R "$src" "$new" || install_error "activation" "unable to stage directory $(basename "$dst")" "check write permissions for $(dirname "$dst")."
  if [ -e "$dst" ]; then
    mv "$dst" "$old" || install_error "activation" "unable to preserve existing directory $(basename "$dst")" "check write permissions for $(dirname "$dst")."
  fi
  if ! mv "$new" "$dst"; then
    [ -e "$old" ] && mv "$old" "$dst" 2>/dev/null || true
    install_error "activation" "unable to activate directory $(basename "$dst")" "existing installation was restored if possible."
  fi
  rm -rf "$old"
}

install_activate_staged() {
  local staged_prefix="$1" prefix="$2"
  mkdir -p "$prefix/bin" "$prefix/lib" "$prefix/share/agent-ws"
  install_replace_file "$staged_prefix/bin/agent-ws" "$prefix/bin/agent-ws"
  chmod +x "$prefix/bin/agent-ws" || install_error "activation" "unable to make command executable" "check permissions for $prefix/bin/agent-ws."
  install_replace_dir "$staged_prefix/lib/agent-ws" "$prefix/lib/agent-ws"
  install_replace_dir "$staged_prefix/share/agent-ws/templates" "$prefix/share/agent-ws/templates"
  if [ -f "$staged_prefix/share/agent-ws/VERSION" ]; then
    install_replace_file "$staged_prefix/share/agent-ws/VERSION" "$prefix/share/agent-ws/VERSION"
  fi
}

install_stage_from_checkout() {
  local root="$1" staged_prefix="$2"
  [ -f "$root/bin/agent-ws" ] || install_error "staging" "missing bin/agent-ws in repository checkout" "run install.sh from a complete checkout."
  [ -d "$root/lib/agent-ws" ] || install_error "staging" "missing lib/agent-ws in repository checkout" "run install.sh from a complete checkout."
  [ -d "$root/templates" ] || install_error "staging" "missing templates in repository checkout" "run install.sh from a complete checkout."
  [ -f "$root/VERSION" ] || install_error "staging" "missing VERSION in repository checkout" "restore the root VERSION file."

  mkdir -p "$staged_prefix/bin" "$staged_prefix/lib" "$staged_prefix/share/agent-ws"
  cp "$root/bin/agent-ws" "$staged_prefix/bin/agent-ws"
  chmod +x "$staged_prefix/bin/agent-ws"
  copy_dir "$root/lib/agent-ws" "$staged_prefix/lib/agent-ws"
  copy_dir "$root/templates" "$staged_prefix/share/agent-ws/templates"
  cp "$root/VERSION" "$staged_prefix/share/agent-ws/VERSION"
}

install_archive_url() {
  local version="$1"
  if [ -n "${AGENT_WS_INSTALL_BASE_URL:-}" ]; then
    printf '%s/%s.tar.gz\n' "${AGENT_WS_INSTALL_BASE_URL%/}" "$version"
  else
    printf 'https://github.com/%s/archive/refs/tags/%s.tar.gz\n' "${AGENT_WS_REPO:-adiacov/agent-workspace}" "$version"
  fi
}

install_download_archive() {
  local version="$1" dst="$2" url
  url="$(install_archive_url "$version")"
  curl -fsSL "$url" -o "$dst" || install_error "download" "unable to download $url" "check network access or choose an available AGENT_WS_VERSION."
}

install_is_checkout() {
  local root="$1"
  [ -f "$root/bin/agent-ws" ] && [ -d "$root/lib/agent-ws" ] && [ -d "$root/templates" ] && [ -f "$root/VERSION" ]
}

install_payload_root_from_extract() {
  local extract_dir="$1" candidate
  if install_is_checkout "$extract_dir"; then
    printf '%s\n' "$extract_dir"
    return 0
  fi
  for candidate in "$extract_dir"/*; do
    [ -d "$candidate" ] || continue
    if install_is_checkout "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  install_error "staging" "downloaded archive does not contain an agent-ws payload" "check the selected release archive."
}

install_stage_from_archive() {
  local version="$1" stage="$2" staged_prefix="$3" archive extract_dir payload_root
  archive="$stage/release.tar.gz"
  extract_dir="$stage/extract"
  mkdir -p "$extract_dir"
  install_download_archive "$version" "$archive"
  tar -xzf "$archive" -C "$extract_dir" || install_error "staging" "unable to extract release archive" "check that the selected release is a tar.gz archive."
  payload_root="$(install_payload_root_from_extract "$extract_dir")"
  install_stage_from_checkout "$payload_root" "$staged_prefix"
}

install_path_contains() {
  local dir="$1" entry old_ifs="$IFS"
  IFS=:
  for entry in ${PATH:-}; do
    [ "$entry" = "$dir" ] && { IFS="$old_ifs"; return 0; }
  done
  IFS="$old_ifs"
  return 1
}

PREFIX="${AGENT_WS_PREFIX:-${HOME:-}/.local}"
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
STAGE="$(install_stage_create)"
trap 'install_stage_cleanup "$STAGE"' EXIT
STAGED_PREFIX="$STAGE/prefix"

if [ "${AGENT_WS_FORCE_REMOTE:-0}" = "1" ] || ! install_is_checkout "$ROOT"; then
  VERSION_TO_INSTALL="$(install_select_version)"
  if [ -n "${AGENT_WS_VERSION:-}" ]; then
    say "selected version: $VERSION_TO_INSTALL"
  else
    say "latest stable: $VERSION_TO_INSTALL"
  fi
  install_stage_from_archive "$VERSION_TO_INSTALL" "$STAGE" "$STAGED_PREFIX"
else
  install_stage_from_checkout "$ROOT" "$STAGED_PREFIX"
fi
install_validate_candidate "$STAGED_PREFIX" "${VERSION_TO_INSTALL:-}"
install_activate_staged "$STAGED_PREFIX" "$PREFIX"

say "installed agent-ws to $PREFIX/bin/agent-ws"
say "installed libraries to $PREFIX/lib/agent-ws"
say "installed templates to $PREFIX/share/agent-ws/templates"
say "installed version to $PREFIX/share/agent-ws/VERSION"
if install_path_contains "$PREFIX/bin"; then
  say "$PREFIX/bin is on PATH"
else
  say "ensure $PREFIX/bin is on PATH"
fi
