#!/usr/bin/env bash
set -euo pipefail

# Copy Arch Linux wallpapers to ~/.local/share/wallpapers
# Source: /usr/share/backgrounds/archlinux/
SOURCE_DIR="/usr/share/backgrounds/archlinux"
TARGET_DIR="$HOME/.local/share/wallpapers"

if ! mkdir -p "$TARGET_DIR"; then
  echo "Error: Failed to create target directory '$TARGET_DIR'" >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Warning: Source directory '$SOURCE_DIR' not found. Skipping." >&2
  exit 0
fi

echo "Copying Arch Linux wallpapers from $SOURCE_DIR..."
count=0
skipped=0
for ext in png jpg jpeg; do
  file=""
  while IFS= read -r -d '' file || [[ -n "$file" ]]; do
    filename=$(basename "$file")
    target_path="$TARGET_DIR/$filename"

    # Skip if file already exists
    if [[ -f "$target_path" ]]; then
      echo "  ⊝ Skipping (already exists): $filename"
      skipped=$((skipped + 1))
      continue
    fi

    if cp -n "$file" "$target_path"; then
      count=$((count + 1))
      echo "  ✓ Copied: $filename"
    else
      echo "  ✗ Failed to copy: $filename" >&2
    fi
  done < <(command find "$SOURCE_DIR" -maxdepth 1 -type f -iname "*.$ext" -print0)
done

echo "✓ Complete: $count wallpaper(s) copied, $skipped skipped"
