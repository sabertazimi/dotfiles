#!/bin/bash

PIDFILE="/tmp/macro.pid"
CODES=$(cat ~/.config/macro.ini 2>/dev/null || echo "2 3 4 5 6")

# Toggle: if running, stop it
if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE")
  if kill -0 "$PID" 2>/dev/null; then
    kill "$PID"
    rm "$PIDFILE"
    dms ipc call toast infoWith "Macro Stopped" "" "" "macro"
    exit 0
  fi
  rm "$PIDFILE"
fi

release_keys() {
  for code in $CODES; do
    ydotool key "${code}:0"
  done
}

# Start macro loop
(
  trap release_keys EXIT
  while true; do
    for code in $CODES; do
      ydotool key "${code}:1"
      ydotool key "${code}:0"
      sleep 0.05
    done
  done
) &

echo $! >"$PIDFILE"
dms ipc call toast infoWith "Macro Started" "" "" "macro"
