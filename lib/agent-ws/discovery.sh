#!/usr/bin/env bash
# Discovery scoring and traversal helpers for agent-ws.

agent_ws_discovery_is_skip_dir() {
  case "$(basename "$1")" in
    .git|node_modules|.venv|venv|dist|build|target|coverage|.idea|.vscode|__pycache__)
      return 0 ;;
    # The tool's own artifacts are never projects: metadata/baselines and the
    # legacy project-local dir (its template cache is full of project-like files).
    .agent-workspace|.agent)
      return 0 ;;
    *) return 1 ;;
  esac
}

agent_ws_discovery_score_dir() {
  local dir="$1" signals="" strong_count=0 weak_count=0 classification="none"

  if [ -f "$dir/.agent-workspace/workspace.json" ] || [ -d "$dir/.agent-workspace" ]; then
    signals="${signals}.agent-workspace/workspace.json,"
    classification="strong"
  fi

  if [ -d "$dir/.agent" ]; then
    signals="${signals}.agent/,"
    strong_count=$((strong_count + 1))
  fi
  if [ -e "$dir/bin/agent-workspace" ]; then
    signals="${signals}bin/agent-workspace,"
    strong_count=$((strong_count + 1))
  fi

  for weak in AGENTS.md CLAUDE.md WORKFLOWS.md PROJECT.md STATE.md MEMORY.md BRAINSTORM.md .cursor/rules/agent-workspace.mdc; do
    if [ -e "$dir/$weak" ]; then
      signals="${signals}${weak},"
      weak_count=$((weak_count + 1))
    fi
  done

  if [ "$classification" != "strong" ]; then
    if [ "$strong_count" -ge 1 ] && [ $((strong_count + weak_count)) -ge 2 ]; then
      classification="strong"
    elif [ "$strong_count" -ge 2 ]; then
      classification="strong"
    elif [ "$weak_count" -ge 1 ] || [ "$strong_count" -ge 1 ]; then
      classification="uncertain"
    fi
  fi

  if [ "$classification" != "none" ]; then
    signals="${signals%,}"
    printf '%s %s signals=%s\n' "$dir" "$classification" "$signals"
  fi
}

# Depth-first walk that reports project roots, not directories: once a
# directory matches, it is reported and its subtree is pruned, so a project's
# internals (template caches, baselines, build output) never show up as
# separate matches.
agent_ws_discover_walk() {
  local dir="$1" line child base
  agent_ws_discovery_is_skip_dir "$dir" && return 0
  line="$(agent_ws_discovery_score_dir "$dir")"
  if [ -n "$line" ]; then
    printf '%s\n' "$line"
    return 0
  fi
  for child in "$dir"/* "$dir"/.*; do
    [ -d "$child" ] || continue
    base="$(basename "$child")"
    [ "$base" = "." ] || [ "$base" = ".." ] && continue
    agent_ws_discover_walk "$child"
  done
  return 0
}

agent_ws_discover_root() {
  local root="$1"
  root="$(agent_ws_existing_project_root "$root")"
  agent_ws_discover_walk "$root"
}

agent_ws_discover() {
  local root results
  [ "$#" -gt 0 ] || agent_ws_die "discover requires at least one root path" "run 'agent-ws discover <root...>'."
  results=""
  local out
  for root in "$@"; do
    out="$(agent_ws_discover_root "$root")"
    [ -n "$out" ] && results="${results}${out}"$'\n'
  done
  if [ -n "$results" ]; then
    printf '%s' "$results"
    agent_ws_advise "check any match in depth with: agent-ws audit <path> (read-only; includes recovery guidance)"
  else
    agent_ws_say "no Agent Workspace projects found under the given roots"
  fi
  agent_ws_advice_flush
}
