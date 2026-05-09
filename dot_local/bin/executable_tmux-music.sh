#!/usr/bin/env bash
set -euo pipefail

WINDOW_NAME="${TMUX_MUSIC_WINDOW_NAME:-music}"

# Globals set by init_session_vars
current_path=""
session_name=""
current_window_name=""
window_target=""
musicfox_pane=""
cava_pane=""
lock_channel=""

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Error: %s is not installed or not in PATH\n' "$1" >&2
    exit 1
  fi
}

check_environment() {
  if [ -z "${TMUX:-}" ]; then
    echo "Error: tmux-music.sh must be run inside tmux" >&2
    exit 1
  fi
  require_command tmux
  require_command musicfox
  require_command cava
}

init_session_vars() {
  current_path="$(tmux display-message -p '#{pane_current_path}')"
  session_name="$(tmux display-message -p '#S')"
  current_window_name="$(tmux display-message -p '#{window_name}')"
  window_target="${session_name}:${WINDOW_NAME}"
  musicfox_pane="${window_target}.1"
  cava_pane="${window_target}.2"
  lock_channel="tmux-music:${session_name}:${WINDOW_NAME}"
}

toggle_or_exit() {
  if ! tmux list-windows -t "$session_name" -F '#W' | grep -Fxq "$WINDOW_NAME"; then
    return 0
  fi

  if [ "$current_window_name" = "$WINDOW_NAME" ]; then
    if ! tmux last-window 2>/dev/null; then
      tmux new-window
    fi
  else
    tmux select-window -t "$window_target"
  fi
  exit 0
}

setup_cava_pane() {
  tmux split-window -v -t "$window_target" -c "$current_path" 'exec cava'

  local pane_height target_height shrink
  pane_height="$(tmux display-message -p -t "$cava_pane" '#{pane_height}')"
  target_height="${TMUX_MUSIC_CAVA_HEIGHT:-12}"
  shrink=$((pane_height - target_height))

  if ((shrink > 0)); then
    tmux resize-pane -D -t "$cava_pane" "$shrink"
  fi
}

open_playlist() {
  tmux select-pane -t "$musicfox_pane"
  sleep "${TMUX_MUSICFOX_JUMP_DELAY:-2}"
  tmux send-keys -t "$musicfox_pane" b
  tmux send-keys -t "$musicfox_pane" c
}

main() {
  check_environment
  init_session_vars

  tmux wait-for -L "$lock_channel"
  cleanup() {
    tmux wait-for -U "$lock_channel"
  }
  trap cleanup EXIT

  toggle_or_exit

  tmux new-window -n "$WINDOW_NAME" -c "$current_path" -d 'exec musicfox'
  # setup_cava_pane
  open_playlist
}

main
