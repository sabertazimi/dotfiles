#!/bin/bash

PIDFILE="/tmp/macro.pid"

# Toggle: if running, stop it
if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE")
  if kill -0 "$PID" 2>/dev/null; then
    kill "$PID"
    rm "$PIDFILE"
    exit 0
  fi
  rm "$PIDFILE"
fi

# Start macro loop
(
  while true; do
    for code in $(cat ~/.config/macro.ini 2>/dev/null || echo "2 3 4 5 6"); do
      ydotool key "${code}:1"
      ydotool key "${code}:0"
      sleep 0.05
    done
  done
) &

echo $! >"$PIDFILE"
