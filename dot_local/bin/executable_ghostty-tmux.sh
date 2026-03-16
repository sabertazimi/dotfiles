#!/usr/bin/env bash

if pgrep -x "ghostty" >/dev/null; then
  ghostty -e sh -c "tmux new-session \; set-option destroy-unattached on" &
else
  ghostty -e sh -c "tmux attach || tmux" &
fi
