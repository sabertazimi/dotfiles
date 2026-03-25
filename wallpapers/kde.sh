#!/usr/bin/env bash
set -euo pipefail

# Copy system wallpapers by resolution priority
# Source: /usr/share/wallpapers/*/contents/images/
SOURCE_BASE="/usr/share/wallpapers"
TARGET_DIR="$HOME/.local/share/wallpapers"

# Resolution priority: highest first, each resolution tries png -> jpg -> jpeg
RESOLUTIONS=(
  "5120x2880.png" "5120x2880.jpg" "5120x2880.jpeg"
  "3840x2160.png" "3840x2160.jpg" "3840x2160.jpeg"
  "2560x1600.png" "2560x1600.jpg" "2560x1600.jpeg"
  "2560x1440.png" "2560x1440.jpg" "2560x1440.jpeg"
  "1920x1080.png" "1920x1080.jpg" "1920x1080.jpeg"
)

# Create target directory if it doesn't exist
if ! mkdir -p "$TARGET_DIR"; then
  echo "Error: Failed to create target directory '$TARGET_DIR'" >&2
  exit 1
fi

# Check if source directory exists
if [[ ! -d "$SOURCE_BASE" ]]; then
  echo "Warning: Source directory '$SOURCE_BASE' not found. Skipping." >&2
  exit 0
fi

echo "Copying system wallpapers from $SOURCE_BASE..."
copied=0
skipped=0

# Iterate through each wallpaper subdirectory
for wallpaper_dir in "$SOURCE_BASE"/*/; do
  [[ -d "$wallpaper_dir" ]] || continue

  name=$(basename "$wallpaper_dir")
  images_dir="$wallpaper_dir/contents/images"

  # Check if images directory exists
  if [[ ! -d "$images_dir" ]]; then
    echo "  ✗ Skipping '$name': no 'contents/images' subdirectory" >&2
    skipped=$((skipped + 1))
    continue
  fi

  # Find first available resolution by priority
  found=false
  for resolution in "${RESOLUTIONS[@]}"; do
    source_file="$images_dir/$resolution"
    if [[ -f "$source_file" ]]; then
      # Preserve original extension in filename
      target_filename="${name}_$resolution"
      target_path="$TARGET_DIR/$target_filename"

      # Skip if file already exists
      if [[ -f "$target_path" ]]; then
        echo "  ⊝ Skipping (already exists): $name ($resolution)"
        skipped=$((skipped + 1))
        found=true
        break
      fi

      if cp -n "$source_file" "$target_path"; then
        echo "  ✓ Copied: $name ($resolution)"
        copied=$((copied + 1))
      else
        echo "  ✗ Failed to copy: $name ($resolution)" >&2
      fi
      found=true
      break
    fi
  done

  if [[ "$found" == false ]]; then
    echo "  ✗ Skipping '$name': no matching resolution found" >&2
    skipped=$((skipped + 1))
  fi
done

echo "✓ Complete: $copied wallpaper(s) copied, $skipped skipped"
