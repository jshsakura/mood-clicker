#!/usr/bin/env bash
# Starts a team in one tmux session: a leader pane and one pane per worker.
#
#   tool/team/start.sh [-s SESSION] [-b BASE] [-n COUNT] AGENT [NAME[=AGENT]...]
#
# AGENT is the command to run in a pane, for example claude or codex. The first AGENT runs in the
# leader pane and is the default of every worker; NAME=AGENT gives one worker another product
# (quote it when it has spaces: ui="codex --yolo"). The leader works in this checkout. Each
# worker NAME works in its own git worktree, ../<repo>-<NAME> on branch work/<NAME>, cut from BASE
# (default: the current commit). -n COUNT names the workers w1..wCOUNT instead.
# Panes are named (see tool/team/itl), so panes talk with: itl send leader '...'
# Safe to run again: an existing worktree, pane or session is reused, never created twice, and
# new names are added to the running session.
# Works with bash 3.2.
set -euo pipefail

usage() {
  echo "usage: tool/team/start.sh [-s SESSION] [-b BASE] [-n COUNT] AGENT [NAME[=AGENT]...]" >&2
  exit 2
}

SESSION="" BASE="HEAD" COUNT=0
while getopts "s:b:n:h" opt; do
  case "$opt" in
    s) SESSION="$OPTARG" ;;
    b) BASE="$OPTARG" ;;
    n) COUNT="$OPTARG" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ $# -ge 1 ] || usage
AGENT="$1"
shift
# Each worker argument is NAME or NAME=AGENT; NAMES and AGENTS stay in step (bash 3.2 has no maps).
NAMES=() AGENTS=()
for arg in "$@"; do
  case "$arg" in
    *=*) NAMES+=("${arg%%=*}") AGENTS+=("${arg#*=}") ;;
    *) NAMES+=("$arg") AGENTS+=("$AGENT") ;;
  esac
done
case "$COUNT" in '' | *[!0-9]*) echo "start.sh: -n needs a number" >&2; exit 2 ;; esac
if [ "${#NAMES[@]}" -eq 0 ] && [ "$COUNT" -gt 0 ]; then
  for ((i = 1; i <= COUNT; i++)); do NAMES+=("w$i") AGENTS+=("$AGENT"); done
fi
if [ "${#NAMES[@]}" -eq 0 ]; then
  echo "start.sh: give worker names or -n COUNT" >&2
  usage
fi

command -v tmux > /dev/null || { echo "start.sh: tmux is not installed" >&2; exit 1; }
for i in "${!NAMES[@]}"; do
  name="${NAMES[$i]}"
  case "$name" in
    '' | -* | *[!A-Za-z0-9._-]*) echo "start.sh: bad worker name '$name' (letters, digits, dot, dash, underscore)" >&2; exit 2 ;;
  esac
  [ -n "${AGENTS[$i]}" ] || { echo "start.sh: worker '$name' has an empty agent command" >&2; exit 2; }
  [ "$name" = "leader" ] && { echo "start.sh: 'leader' is taken by the leader pane" >&2; exit 2; }
done

REPO="$(git rev-parse --show-toplevel)"
REPO_NAME="$(basename "$REPO")"
SESSION="${SESSION:-$REPO_NAME}"
PARENT="$(dirname "$REPO")"
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

# Make every worktree first, so a mistake stops the script before any pane exists.
for name in "${NAMES[@]}"; do
  dir="$PARENT/$REPO_NAME-$name"
  if [ -e "$dir" ]; then
    if [ -f "$dir/.git" ] && git -C "$REPO" worktree list --porcelain | grep -qx "worktree $dir"; then
      echo "worktree $dir already exists"
    else
      echo "start.sh: $dir exists and is not a worktree of this repository" >&2
      exit 1
    fi
  elif git -C "$REPO" show-ref --verify --quiet "refs/heads/work/$name"; then
    git -C "$REPO" worktree add -q "$dir" "work/$name"
  else
    git -C "$REPO" worktree add -q "$dir" -b "work/$name" "$BASE"
  fi
done

has_pane() { tmux list-panes -s -t "$SESSION" -F '#{@itl_name}' 2> /dev/null | grep -qx "$1"; }

# new_pane NAME DIR AGENT: a pane named NAME running AGENT in DIR; the first one creates the session.
new_pane() {
  local name="$1" dir="$2" agent="$3" id
  if has_pane "$name"; then
    echo "pane $name already exists"
    return
  fi
  if tmux has-session -t "=$SESSION" 2> /dev/null; then
    id="$(tmux split-window -d -P -F '#{pane_id}' -t "=$SESSION:" -c "$dir")"
    tmux select-layout -t "=$SESSION:" tiled > /dev/null
  else
    id="$(tmux new-session -d -P -F '#{pane_id}' -s "$SESSION" -c "$dir" -x 200 -y 50)"
  fi
  tmux set-option -p -t "$id" @itl_name "$name"
  tmux send-keys -t "$id" -l "$agent"
  tmux send-keys -t "$id" Enter
  echo "pane $name started in $dir"
}

new_pane leader "$REPO" "$AGENT"
for i in "${!NAMES[@]}"; do
  new_pane "${NAMES[$i]}" "$PARENT/$REPO_NAME-${NAMES[$i]}" "${AGENTS[$i]}"
done
echo "team is up. Attach with: tmux attach -t $SESSION"
