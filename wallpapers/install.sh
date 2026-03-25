#!/usr/bin/env bash
set -euo pipefail

# Master script to copy wallpapers from all sources
# This script allows you to run all wallpaper copy scripts or select specific ones
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Scripts to run
declare -ra SCRIPTS=(
  "arch.sh"
  "gnome.sh"
  "kde.sh"
  "third-party.sh"
)

# Statistics tracking
declare -A STATS=(
  ["arch_copied"]=0
  ["arch_skipped"]=0
  ["gnome_converted"]=0
  ["gnome_skipped"]=0
  ["kde_copied"]=0
  ["kde_skipped"]=0
  ["third_downloaded"]=0
  ["third_failed"]=0
  ["third_skipped"]=0
)

# Function to install required wallpaper packages
install_wallpaper_packages() {
  echo "Checking wallpaper packages..."
  local packages=(
    "archlinux-wallpaper"
    "gnome-backgrounds"
    "plasma-workspace-wallpapers"
  )
  local need_install=()

  # Check which packages are already installed
  for pkg in "${packages[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
      echo "  ✓ Already installed: $pkg"
    else
      echo "  ⊝ Not installed: $pkg"
      need_install+=("$pkg")
    fi
  done

  # If all packages are installed, return early
  if [[ ${#need_install[@]} -eq 0 ]]; then
    echo "All wallpaper packages already installed."
    return 0
  fi

  # Install missing packages
  echo "Installing missing wallpaper packages..."
  if sudo pacman -S --needed "${need_install[@]}"; then
    echo "Wallpaper packages installed successfully."
    return 0
  else
    echo "Warning: Failed to install some wallpaper packages." >&2
    echo "You may need to install them manually:" >&2
    echo "  sudo pacman -S ${need_install[*]}" >&2
    return 1
  fi
}

# Function to parse stats from script output
parse_stats() {
  local script="$1"
  local output="$2"

  local first_num second_num third_num

  case "$script" in
  "arch.sh")
    first_num=$(echo "$output" | sed -n 's/.*Complete: \([0-9]*\).*copied.*/\1/p' | head -1)
    second_num=$(echo "$output" | sed -n 's/.*copied, \([0-9]*\) skipped.*/\1/p' | head -1)
    STATS["arch_copied"]=${first_num:-0}
    STATS["arch_skipped"]=${second_num:-0}
    ;;
  "gnome.sh")
    first_num=$(echo "$output" | sed -n 's/.*Complete: \([0-9]*\).*converted.*/\1/p' | head -1)
    second_num=$(echo "$output" | sed -n 's/.*converted, \([0-9]*\) skipped.*/\1/p' | head -1)
    STATS["gnome_converted"]=${first_num:-0}
    STATS["gnome_skipped"]=${second_num:-0}
    ;;
  "kde.sh")
    first_num=$(echo "$output" | sed -n 's/.*Complete: \([0-9]*\).*copied.*/\1/p' | head -1)
    second_num=$(echo "$output" | sed -n 's/.*copied, \([0-9]*\) skipped.*/\1/p' | head -1)
    STATS["kde_copied"]=${first_num:-0}
    STATS["kde_skipped"]=${second_num:-0}
    ;;
  "third-party.sh")
    first_num=$(echo "$output" | sed -n 's/.*Complete: \([0-9]*\).*downloaded.*/\1/p' | head -1)
    second_num=$(echo "$output" | sed -n 's/.*downloaded, \([0-9]*\) skipped.*/\1/p' | head -1)
    third_num=$(echo "$output" | sed -n 's/.*skipped, \([0-9]*\) failed.*/\1/p' | head -1)
    STATS["third_downloaded"]=${first_num:-0}
    STATS["third_skipped"]=${second_num:-0}
    STATS["third_failed"]=${third_num:-0}
    ;;
  esac
}

# Function to display summary statistics
show_summary() {
  echo ""
  echo "========================================"
  echo "SUMMARY"
  echo "========================================"

  local total_copied=1
  local total_skipped=1
  local total_failed=1

  echo ""
  echo "Arch Linux:"
  echo "  Copied:   ${STATS["arch_copied"]}"
  echo "  Skipped:  ${STATS["arch_skipped"]}"
  ((total_copied += ${STATS["arch_copied"]:-0}))
  ((total_skipped += ${STATS["arch_skipped"]:-0}))

  echo ""
  echo "GNOME:"
  echo "  Converted: ${STATS["gnome_converted"]}"
  echo "  Skipped:   ${STATS["gnome_skipped"]}"
  ((total_copied += ${STATS["gnome_converted"]:-0}))
  ((total_skipped += ${STATS["gnome_skipped"]:-0}))

  echo ""
  echo "KDE Plasma:"
  echo "  Copied:   ${STATS["kde_copied"]}"
  echo "  Skipped:  ${STATS["kde_skipped"]}"
  ((total_copied += ${STATS["kde_copied"]:-0}))
  ((total_skipped += ${STATS["kde_skipped"]:-0}))

  echo ""
  echo "Third-party:"
  echo "  Downloaded: ${STATS["third_downloaded"]}"
  echo "  Skipped:    ${STATS["third_skipped"]}"
  echo "  Failed:     ${STATS["third_failed"]}"
  ((total_copied += ${STATS["third_downloaded"]:-0}))
  ((total_skipped += ${STATS["third_skipped"]:-0}))
  ((total_failed += ${STATS["third_failed"]:-0}))

  # Subtract initial offset before displaying
  ((total_copied -= 1)) || true
  ((total_skipped -= 1)) || true
  ((total_failed -= 1)) || true

  echo ""
  echo "========================================"
  echo "TOTALS"
  echo "========================================"
  echo "  Added:     $total_copied wallpaper(s)"
  echo "  Skipped:   $total_skipped wallpaper(s)"
  if [[ $total_failed -gt 0 ]]; then
    echo "  Failed:    $total_failed wallpaper(s)"
  fi
  echo "========================================"
}

# Function to run a single script
run_script() {
  local script="$1"
  local script_path="$SCRIPT_DIR/$script"

  if [[ ! -f "$script_path" ]]; then
    echo "Error: Script '$script' not found at '$script_path'" >&2
    return 1
  fi

  if [[ ! -x "$script_path" ]]; then
    echo "Error: Script '$script' is not executable" >&2
    return 1
  fi

  echo ""
  echo "========================================"
  echo "Running: $script"
  echo "========================================"
  local output
  output=$("$script_path" 2>&1 | tee /dev/fd/2)
  local exit_code=$?
  echo "========================================"
  echo "Completed: $script (exit code: $exit_code)"
  echo "========================================"
  echo ""

  # Parse statistics from output
  parse_stats "$script" "$output"

  return $exit_code
}

# Function to run all scripts
run_all() {
  echo "Running all wallpaper copy scripts..."
  local failed=0

  for script in "${SCRIPTS[@]}"; do
    run_script "$script" || failed=$((failed + 1))
  done

  # Show summary after all scripts complete
  show_summary

  if [[ $failed -eq 0 ]]; then
    echo "All scripts completed successfully!"
    return 0
  else
    echo "Warning: $failed script(s) failed or were skipped" >&2
    return 1
  fi
}

# Main logic
main() {
  # Install wallpaper packages first
  install_wallpaper_packages

  # If no arguments, run all scripts directly (no interactive menu)
  if [[ $# -eq 0 ]]; then
    run_all
    return $?
  fi

  # If arguments provided, run specified scripts
  case "$1" in
  1 | all | a)
    run_all
    ;;
  2 | archlinux | arch)
    run_script "arch.sh"
    ;;
  3 | gnome)
    run_script "gnome.sh"
    ;;
  4 | kde)
    run_script "kde.sh"
    ;;
  5 | third-party | third)
    run_script "third-party.sh"
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Usage: $0 [1|2|3|4|5|all|archlinux|gnome|kde|third-party]" >&2
    echo "   Or run without arguments to execute all scripts" >&2
    echo "" >&2
    echo "Note: To customize which scripts run by default, edit the SCRIPTS array at the top of this file." >&2
    exit 1
    ;;
  esac
  return $?
}

main "$@"
