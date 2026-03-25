#!/usr/bin/env bash
set -euo pipefail

WINDOW_NAME="${TMUX_MUSIC_WINDOW_NAME:-music}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Error: %s is not installed or not in PATH\n' "$1" >&2
    exit 1
  fi
}

if [ -z "${TMUX:-}" ]; then
  echo "Error: tmux-music.sh must be run inside tmux" >&2
  exit 1
fi

require_command tmux
require_command musicfox
require_command cava

current_path="$(tmux display-message -p '#{pane_current_path}')"
session_name="$(tmux display-message -p '#S')"
window_target="${session_name}:${WINDOW_NAME}"

if tmux list-windows -t "$session_name" -F '#W' | grep -Fxq "$WINDOW_NAME"; then
  tmux select-window -t "$window_target"
  exit 0
fi

tmux new-window -n "$WINDOW_NAME" -c "$current_path" -d 'exec musicfox'
tmux split-window -v -t "$window_target" -c "$current_path" 'exec cava'

# Resize the lower cava pane to the configured target height when possible.
cava_pane_height="$(tmux display-message -p -t "${window_target}.2" '#{pane_height}')"
target_cava_height="${TMUX_MUSIC_CAVA_HEIGHT:-12}"
desired_shrink=$((cava_pane_height - target_cava_height))

if ((desired_shrink > 0)); then
  tmux resize-pane -D -t "${window_target}.2" "$desired_shrink"
fi

tmux select-pane -t "${window_target}.1"
tmux select-window -t "$window_target"
