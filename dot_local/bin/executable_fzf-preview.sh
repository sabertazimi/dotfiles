#!/usr/bin/env bash
# Unified fzf preview: picks the right tool based on file type.
# Usage: fzf-preview.sh <path>

path="$1"

if [[ -d "$path" ]]; then
  eza -1 --color=always --icons --group-directories-first "$path"
else
  mime=$(file --mime-type -Lb "$path" 2>/dev/null)
  case $mime in
    image/*)
      if command -v chafa >/dev/null 2>&1; then
        chafa -s "${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}" "$path"
      else
        file --brief "$path"
      fi
      ;;
    text/*|*/json|*/xml|*/javascript|application/x-shellscript|inode/x-empty)
      (bat --color=always --style=numbers "$path" || cat "$path") 2>/dev/null
      ;;
    *)
      file --brief "$path"
      ;;
  esac
fi
