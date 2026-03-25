#!/usr/bin/env bash

if tmux list-clients -F '#{client_pid}' 2>/dev/null | grep -q .; then
  tmux new-session \; set-option destroy-unattached on
else
  tmux attach-session || tmux new-session
fi
