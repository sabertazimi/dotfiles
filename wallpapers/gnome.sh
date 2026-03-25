#!/usr/bin/env bash
set -euo pipefail

# Copy GNOME wallpapers (.jxl) and convert to .png
# Source: /usr/share/backgrounds/gnome/
SOURCE_DIR="/usr/share/backgrounds/gnome"
TARGET_DIR="$HOME/.local/share/wallpapers"
TEMP_DIR=$(mktemp -d)

# Cleanup function
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Create target directory if it doesn't exist
if ! mkdir -p "$TARGET_DIR"; then
  echo "Error: Failed to create target directory '$TARGET_DIR'" >&2
  exit 1
fi

# Check if source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Warning: Source directory '$SOURCE_DIR' not found. Skipping." >&2
  exit 0
fi

# Check if ImageMagick is available
if ! command -v magick &>/dev/null; then
  echo "Warning: ImageMagick 'magick' command not found. Please install imagemagick." >&2
  echo "  Skipping .jxl to .png conversion." >&2
  exit 0
fi

# Copy .jxl files to temp directory
echo "Copying GNOME .jxl wallpapers from $SOURCE_DIR..."
count=0
skipped=0
file=""
while IFS= read -r -d '' file || [[ -n "$file" ]]; do
  filename=$(basename "$file")
  png_filename="${filename%.jxl}.png"
  target_path="$TARGET_DIR/$png_filename"

  # Skip if PNG file already exists
  if [[ -f "$target_path" ]]; then
    echo "  ⊝ Skipping (already exists): $png_filename"
    skipped=$((skipped + 1))
    continue
  fi

  if cp -n "$file" "$TEMP_DIR/$filename"; then
    count=$((count + 1))
    echo "  ✓ Copied: $filename"
  else
    echo "  ✗ Failed to copy: $filename" >&2
  fi
done < <(command find "$SOURCE_DIR" -maxdepth 1 -type f -iname "*-d.jxl" -print0)

if [[ $count -eq 0 ]]; then
  if [[ $skipped -gt 0 ]]; then
    echo "✓ Complete: 0 wallpaper(s) converted, $skipped skipped"
  else
    echo "✓ Complete: 0 wallpaper(s) converted, 0 skipped"
  fi
  exit 0
fi

echo "Converting $count .jxl file(s) to .png (using $(nproc) parallel jobs)..."
# Convert all .jxl files to .png in parallel
cd "$TEMP_DIR"
converted=0
for jxl_file in *.jxl; do
  [[ -f "$jxl_file" ]] || continue
  basename="${jxl_file%.jxl}"
  echo "  Converting: $jxl_file"
  # Use background jobs for parallel conversion
  (
    if magick "$jxl_file" "${basename}.png" 2>/dev/null; then
      echo "  ✓ Converted: $jxl_file -> ${basename}.png"
      rm -f "$jxl_file"
    else
      echo "  ✗ Failed: $jxl_file" >&2
    fi
  ) &
  # Limit parallel jobs to CPU count
  if (($(jobs -r | wc -l) >= $(nproc))); then
    wait -n
  fi
done
wait
# Count converted files
converted=$(find . -maxdepth 1 -type f -name '*.png' 2>/dev/null | wc -l)

# Move .png files to target directory
echo "Moving $converted .png file(s) to $TARGET_DIR..."
moved=0
move_skipped=0
for png_file in *.png; do
  [[ -f "$png_file" ]] || continue
  target_path="$TARGET_DIR/$png_file"
  if [[ -f "$target_path" ]]; then
    echo "  ⊝ Skipping (already exists): $png_file"
    move_skipped=$((move_skipped + 1))
    continue
  fi
  if cp -n "$png_file" "$target_path"; then
    moved=$((moved + 1))
    echo "  ✓ Moved: $png_file"
  else
    echo "  ✗ Failed to move: $png_file" >&2
  fi
done

echo "✓ Complete: $moved wallpaper(s) converted, $((skipped + move_skipped)) skipped"
