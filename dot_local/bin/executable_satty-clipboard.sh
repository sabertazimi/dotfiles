#!/usr/bin/env bash
set -uo pipefail

# Edit the image currently in the Wayland clipboard with satty.
# Notifies via dms toast if the clipboard does not hold a PNG image.

tmp="$(mktemp --suffix=.png)"
trap 'rm -f "$tmp"' EXIT

if wl-paste --type image/png >"$tmp" 2>/dev/null && [ -s "$tmp" ]; then
  satty --filename "$tmp"
else
  dms ipc call toast info "剪贴板不是图像"
fi
