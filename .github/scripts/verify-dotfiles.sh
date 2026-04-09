#!/usr/bin/env bash
set -euo pipefail

FILES=(
  "$HOME/.cargo/config.toml"
  "$HOME/.claude/plugins/claude-hud/config.json"
  "$HOME/.config/cava/config"
  "$HOME/.config/chezmoi/chezmoi.toml"
  "$HOME/.config/DankMaterialShell/settings.json"
  "$HOME/.config/environment.d/90-dms.conf"
  "$HOME/.config/fcitx5/config"
  "$HOME/.config/fcitx5/conf/classicui.conf"
  "$HOME/.config/fontconfig/fonts.conf"
  "$HOME/.config/ghostty/config"
  "$HOME/.config/go/env"
  "$HOME/.config/go-musicfox/config.toml"
  "$HOME/.config/imv/config"
  "$HOME/.config/matugen/config.toml"
  "$HOME/.config/matugen/templates/cava.ini"
  "$HOME/.config/matugen/templates/starship.toml"
  "$HOME/.config/matugen/templates/tmux.conf"
  "$HOME/.config/mimeapps.list"
  "$HOME/.config/mpv/mpv.conf"
  "$HOME/.config/niri/config.kdl"
  "$HOME/.config/niri/dms/binds.kdl"
  "$HOME/.config/niri/dms/windowrules.kdl"
  "$HOME/.config/nvim/.neoconf.json"
  "$HOME/.config/nvim/init.lua"
  "$HOME/.config/nvim/lazyvim.json"
  "$HOME/.config/nvim/lua/config/autocmds.lua"
  "$HOME/.config/nvim/lua/config/keymaps.lua"
  "$HOME/.config/nvim/lua/config/lazy.lua"
  "$HOME/.config/nvim/lua/config/options.lua"
  "$HOME/.config/nvim/lua/plugins/blink.lua"
  "$HOME/.config/nvim/lua/plugins/colorscheme.lua"
  "$HOME/.config/nvim/lua/plugins/conform.lua"
  "$HOME/.config/nvim/lua/plugins/lsp.lua"
  "$HOME/.config/nvim/lua/plugins/lualine.lua"
  "$HOME/.config/nvim/lua/plugins/markdown.lua"
  "$HOME/.config/nvim/lua/plugins/noice.lua"
  "$HOME/.config/nvim/lua/plugins/pairs.lua"
  "$HOME/.config/nvim/lua/plugins/snacks.lua"
  "$HOME/.config/nvim/lua/plugins/tmux.lua"
  "$HOME/.config/nvim/lua/plugins/treesitter.lua"
  "$HOME/.config/nvim/lua/plugins/wakatime.lua"
  "$HOME/.config/nvim/README.md"
  "$HOME/.config/nvim/stylua.toml"
  "$HOME/.config/satty/config.toml"
  "$HOME/.config/television/cable/aur.toml"
  "$HOME/.config/tmux/tmux.conf"
  "$HOME/.gitmsg.md"
  "$HOME/.local/bin/pacman-owns.sh"
  "$HOME/.local/bin/tmux-entry.sh"
  "$HOME/.local/bin/tmux-music.sh"
  "$HOME/.local/share/fcitx5/rime/default.custom.yaml"
  "$HOME/.local/state/DankMaterialShell/session.json"
  "$HOME/.ripgreprc"
  "$HOME/.zshrc"
)

CHEZMOI_LOG="${1:-}"

echo "==> Verifying dotfiles setup..."

echo "Checking chezmoi status..."
if chezmoi status 2>/dev/null | grep -qv '^$'; then
  echo "Error: chezmoi status shows pending changes"
  chezmoi status
  exit 1
fi
echo "  Status clean"

echo "Checking managed files..."
for file in "${FILES[@]}"; do
  if [ ! -e "$file" ]; then
    echo "Error: $file not found"
    exit 1
  fi
  echo "  ✓ $file"
done

if [ -n "$CHEZMOI_LOG" ] && [ -f "$CHEZMOI_LOG" ]; then
  echo "Checking applied files match expected list..."
  UNEXPECTED_FILES=""
  MISSING_FILES=""

  mapfile -t APPLIED_ARRAY < <(
    awk '
      /^diff --git a/ {
        match($0, / b\/([^ ]+)/, m)
        print ENVIRON["HOME"] "/" m[1]
      }
    ' "$CHEZMOI_LOG" | while IFS= read -r path; do
      [ -f "$path" ] && printf '%s\n' "$path"
    done | sort -u
  )

  for actual_file in "${APPLIED_ARRAY[@]}"; do
    [ -z "$actual_file" ] && continue

    is_expected=false
    for expected_file in "${FILES[@]}"; do
      if [ "$actual_file" = "$expected_file" ]; then
        is_expected=true
        break
      fi
    done

    if [ "$is_expected" = true ]; then
      echo "  ✓ $actual_file"
    else
      echo "  ✗ $actual_file (unexpected)"
      UNEXPECTED_FILES="${UNEXPECTED_FILES}  - ${actual_file}"$'\n'
    fi
  done

  for file in "${FILES[@]}"; do
    is_found=false
    for applied_file in "${APPLIED_ARRAY[@]}"; do
      if [ "$file" = "$applied_file" ]; then
        is_found=true
        break
      fi
    done

    if [ "$is_found" = false ]; then
      echo "  ✗ $file (missing)"
      MISSING_FILES="${MISSING_FILES}  - ${file}"$'\n'
    fi
  done

  if [ -n "$UNEXPECTED_FILES" ]; then
    echo "Error: Found unexpected files applied by chezmoi (not in expected list):"
    echo "$UNEXPECTED_FILES"
    echo "This may indicate .chezmoiignore is missing entries."
    echo "Please update .chezmoiignore or add the file to the expected list in verify-dotfiles.sh"
    exit 1
  fi

  if [ -n "$MISSING_FILES" ]; then
    echo "Error: Expected files were not applied by chezmoi:"
    echo "$MISSING_FILES"
    exit 1
  fi

  echo "  Applied files match expected list (${#APPLIED_ARRAY[@]} files)"
else
  echo "Warning: No chezmoi log provided, skipping applied files comparison"
fi

echo "==> All verifications passed"
