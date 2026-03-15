#!/usr/bin/env bash

if pgrep -x "ghostty" >/dev/null; then
  ghostty &
else
  ghostty -e sh -c "tmux attach || tmux" &
fi
