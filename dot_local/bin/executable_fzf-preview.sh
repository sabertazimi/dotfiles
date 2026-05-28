#!/usr/bin/env bash

if [[ -d "$1" ]]; then
  eza -1 --color=always --icons --group-directories-first "$1"
else
  /usr/share/fzf/fzf-preview.sh "$@"
fi
