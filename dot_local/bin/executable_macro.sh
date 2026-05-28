#!/usr/bin/env bash

PIDFILE="/tmp/macro.pid"
CONFIG=$(cat ~/.config/macro.ini 2>/dev/null || echo "2 3 4 5 6")

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

# Collect all key codes for release on exit
ALL_CODES=""
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  last="${line##* }"
  [[ "$last" =~ ^[0-9]+s$ ]] && line="${line% *}"
  ALL_CODES="$ALL_CODES $line"
done <<<"$CONFIG"

release_keys() {
  for code in $ALL_CODES; do
    ydotool key "${code}:0"
  done
}

# Start macro loops
(
  trap 'kill $(jobs -p) 2>/dev/null; release_keys' EXIT

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    last="${line##* }"
    if [[ "$last" =~ ^([0-9]+)s$ ]]; then
      codes="${line% *}"
      [[ -z "$codes" || "$codes" == "$line" ]] && continue
      interval="${BASH_REMATCH[1]}"
      (
        while true; do
          for code in $codes; do
            ydotool key "${code}:1"
            ydotool key "${code}:0"
            sleep 0.05
          done
          sleep "$interval"
        done
      ) &
    else
      (
        while true; do
          for code in $line; do
            ydotool key "${code}:1"
            ydotool key "${code}:0"
            sleep 0.05
          done
        done
      ) &
    fi
  done <<<"$CONFIG"

  wait
) &

echo $! >"$PIDFILE"
dms ipc call toast infoWith "Macro Started" "" "" "macro"
