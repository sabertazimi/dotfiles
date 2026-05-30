#!/usr/bin/env bash
set -euo pipefail

WINDOW_NAME="${TMUX_MUSIC_WINDOW_NAME:-music}"
TARGET_SESSION="${TMUX_MUSIC_SESSION:-0}"

# Globals set by init_mode
session_name=""
current_path=""
current_window_name=""
window_target=""
musicfox_pane=""
cava_pane=""
lock_channel=""
needs_ghostty=false
fresh_session=false

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Error: %s is not installed or not in PATH\n' "$1" >&2
    exit 1
  fi
}

check_environment() {
  require_command tmux
  require_command musicfox
  require_command cava
}

init_mode() {
  if [ -n "${TMUX:-}" ]; then
    session_name="$(tmux display-message -p '#S')"
    current_path="$(tmux display-message -p '#{pane_current_path}')"
    current_window_name="$(tmux display-message -p '#{window_name}')"
  else
    local attached_session
    attached_session="$(tmux list-clients -F '#{session_name}' 2>/dev/null | head -1 || true)"
    if [ -n "$attached_session" ]; then
      exec tmux run-shell -b -t "$attached_session" "exec ~/.local/bin/tmux-music.sh"
    fi

    session_name="$TARGET_SESSION"
    current_path="$HOME"
    current_window_name=""
    needs_ghostty=true
    require_command ghostty
  fi
  window_target="${session_name}:${WINDOW_NAME}"
  musicfox_pane="${window_target}.1"
  cava_pane="${window_target}.2"
  lock_channel="tmux-music:${session_name}:${WINDOW_NAME}"
}

toggle_or_exit() {
  if [ "$fresh_session" = true ]; then
    return 0
  fi

  if ! tmux list-windows -t "$session_name" -F '#W' | grep -Fxq "$WINDOW_NAME"; then
    return 0
  fi

  if [ "$needs_ghostty" = true ]; then
    # Launch ghostty
    tmux select-window -t "$window_target"
    tmux wait-for -U "$lock_channel"
    trap - EXIT
    exec ghostty -e tmux attach-session -t "$session_name"
  fi

  # Toggle music window
  if [ "$current_window_name" = "$WINDOW_NAME" ]; then
    if ! tmux last-window -t "$session_name" 2>/dev/null; then
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
  init_mode

  # Create session
  if [ "$needs_ghostty" = true ] && ! tmux has-session -t "$session_name" 2>/dev/null; then
    fresh_session=true
    tmux new-session -d -s "$session_name" -n "$WINDOW_NAME" -c "$current_path" 'exec musicfox'
  fi

  tmux wait-for -L "$lock_channel"
  cleanup() {
    tmux wait-for -U "$lock_channel"
  }
  trap cleanup EXIT

  toggle_or_exit

  if [ "$fresh_session" = false ]; then
    if [ -n "${TMUX:-}" ]; then
      tmux new-window -a -n "$WINDOW_NAME" -c "$current_path" -d 'exec musicfox'
    else
      tmux new-window -a -t "${session_name}:" -n "$WINDOW_NAME" -c "$current_path" -d 'exec musicfox'
    fi
  fi

  setup_cava_pane

  if [ "$needs_ghostty" = true ]; then
    tmux wait-for -U "$lock_channel"
    trap - EXIT
    tmux select-window -t "$window_target"
    ghostty -e tmux attach-session -t "$session_name" & disown
    open_playlist
  else
    open_playlist
  fi
}

main
