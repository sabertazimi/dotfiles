# Dotfiles

[![Author](https://img.shields.io/badge/author-sabertaz-lightgrey?style=for-the-badge)](https://github.com/sabertazimi)
[![LICENSE](https://img.shields.io/github/license/sabertazimi/dotfiles?style=for-the-badge)](https://raw.githubusercontent.com/sabertazimi/dotfiles/main/LICENSE)
[![Code Size](https://img.shields.io/github/languages/code-size/sabertazimi/dotfiles?logo=visualstudiocode&style=for-the-badge)](https://github.com/sabertazimi/dotfiles)

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=archlinux&logoColor=white)](https://github.com/archlinux)
[![Niri](https://img.shields.io/badge/Niri-D55C44?style=for-the-badge&logo=niri&logoColor=white)](https://github.com/niri-wm/niri)
[![GNOME](https://img.shields.io/badge/GNOME-4A86CF?style=for-the-badge&logo=gnome&logoColor=white)](https://github.com/gnome)
[![KDE Plasma](https://img.shields.io/badge/KDE_Plasma-1D99F3?style=for-the-badge&logo=kdeplasma&logoColor=white)](https://github.com/kde)
[![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://github.com/microsoft/TypeScript)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://github.com/python/cpython)
[![Rust](https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white)](https://github.com/rust-lang/rust)
[![Go](https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white)](https://github.com/golang/go)
[![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)](https://github.com/git/git)
[![Ghostty](https://img.shields.io/badge/Ghostty-3551F3?style=for-the-badge&logo=ghostty&logoColor=white)](https://github.com/ghostty-org/ghostty)
[![Tmux](https://img.shields.io/badge/Tmux-1BB91F?style=for-the-badge&logo=tmux&logoColor=white)](https://github.com/tmux/tmux)
[![Zsh](https://img.shields.io/badge/Zsh-F15A24?style=for-the-badge&logo=zsh&logoColor=white)](https://github.com/ohmyzsh/ohmyzsh)
[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://github.com/ohmybash/oh-my-bash)
[![Starship](https://img.shields.io/badge/Starship-DD0B78?style=for-the-badge&logo=starship&logoColor=white)](https://github.com/starship/starship)
[![Neovim](https://img.shields.io/badge/Neovim-57A143?style=for-the-badge&logo=neovim&logoColor=white)](https://github.com/neovim/neovim)
[![Claude Code](https://img.shields.io/badge/Claude_Code-D97757?style=for-the-badge&logo=claude&logoColor=white)](https://github.com/anthropics/claude-code)
[![Rime](https://img.shields.io/badge/Rime-000000?style=for-the-badge&logo=rime&logoColor=white)](https://github.com/rime)
[![MPV](https://img.shields.io/badge/MPV-691F69?style=for-the-badge&logo=mpv&logoColor=white)](https://github.com/mpv-player/mpv)
[![Music](https://img.shields.io/badge/Music-D43C33?style=for-the-badge&logo=neteasecloudmusic&logoColor=white)](https://github.com/go-musicfox/go-musicfox)
[![WakaTime](https://img.shields.io/badge/WakaTime-000000?style=for-the-badge&logo=wakatime&logoColor=white)](https://github.com/wakatime)

Hackable personal dotfiles managed with [`chezmoi`](https://github.com/twpayne/chezmoi)
(`/ʃeɪ mwa/`).

![Dank Material Shell](./.github/screenshots/dms.webp)
![Niri](./.github/screenshots/niri.webp)
![Ghostty](./.github/screenshots/ghostty.webp)
![Tmux](./.github/screenshots/tmux.webp)

## Installation

Set up new machine:

```bash
sudo pacman -S chezmoi
chezmoi init --apply -v sabertazimi
```

See [Arch Linux setup guide](https://notes.tazimi.dev/programming/linux/arch)
for detailed system configuration.

## Configured Applications

### Development

- Cargo: Rust package manager with `USTC` mirror
- Go: Go environment config file
- Grep: Enhanced `ripgrep` search (web file types, hidden files, smart-case)
- Television: Fancy `fzf` recipes
- Git: Conventional commit templates
- Neovim: Hackable LazyVim configuration
  - Language Extras: TypeScript, Python, Rust, Go, Markdown, JSON, TOML, YAML
  - LSP: ESLint, Harper (grammar checker)
  - Mason: `shellcheck`
  - Plugins: Aerial (symbols), Blink (completion), Snacks (picker/terminal)
  - Config: Custom keymaps, `catppuccin` color scheme, Markdown rendering

### Terminal & Shell

- Ghostty: Modern Wayland terminal with Dank colors theme
- Tmux: Terminal multiplexer with `catppuccin` theme
- Zsh: Blazing fast [`Zinit`](https://github.com/zdharma-continuum/zinit) configuration
  with modern CLI tools (`zoxide`, `fzf`, `eza`, `bat` etc.)
  and lightweight [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) integration.
- Starship: Dynamic prompt via matugen (Material You theming)

### Utilities

- Fcitx-Rime: Chinese input with vertical candidates and dark theme
- Satty: Wayland screenshot annotation tool
- MPV: Hardware-accelerated video player

### Window Manager

- Niri: Scrollable-tiling Wayland compositor with `DankMaterialShell` integration

### System

- `fontconfig`: Font rendering configuration
- MIME Apps: Default application associations

### Themes

- `DankMaterialShell`: Material You shell
- Matugen: Material You color scheme generator from wallpaper

## Wallpapers

Collection of wallpaper management scripts for Arch Linux:

- Interactive or command-line usage
- Automatic package installation
- Copies Arch Linux, GNOME, and KDE Plasma wallpapers
- `.jxl` to `.png` conversion for GNOME wallpapers
- Resolution priority selection for KDE Plasma wallpapers

```bash
# Fetch scripts
git clone --depth=1 https://github.com/sabertazimi/dotfiles.git ~/dotfiles
chmod +x ~/dotfiles/wallpapers/*.sh

# Install all wallpapers
~/dotfiles/wallpapers/install.sh

# Or run specific script
~/dotfiles/wallpapers/install.sh archlinux   # Arch Linux wallpapers
~/dotfiles/wallpapers/install.sh gnome       # GNOME wallpapers
~/dotfiles/wallpapers/install.sh kde         # KDE Plasma wallpapers
~/dotfiles/wallpapers/install.sh third-party # Third-party wallpapers
```

Wallpapers are copied to `~/.local/share/wallpapers/`.

Requirements:

- `ImageMagick` (for GNOME `.jxl` conversion)
- `archlinux-wallpaper`
- `gnome-backgrounds`
- `plasma-workspace-wallpapers`

## Shell Themes

### Zsh Theme

Minimalistic zsh prompt theme for git users:

```bash
mkdir -p ~/.oh-my-zsh/custom/themes
cp ~/dotfiles/themes/zsh/dragon.zsh-theme ~/.oh-my-zsh/custom/themes/
sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="dragon"/' ~/.zshrc
source ~/.zshrc
```

![Zsh Theme](./.github/screenshots/zsh.webp)

### Bash Theme

Minimalistic bash prompt theme for git-bash on Windows:

```bash
mkdir -p ~/.oh-my-bash/custom/themes/dragon
cp ~/dotfiles/themes/bash/dragon.theme.sh ~/.oh-my-bash/custom/themes/dragon/
sed -i 's/^OSH_THEME=".*"/OSH_THEME="dragon"/' ~/.bashrc
source ~/.bashrc
```

![Bash Theme](./.github/screenshots/bash.webp)

## Caveats

Dotfiles not synced:

`~/.gitconfig`, `~/.claude.json`, `~/.claude/settings.json`
contain keys and dynamically generated content.

## License

MIT License Copyright (c) [`Sabertaz`](https://github.com/sabertazimi)

## Contact

[![GitHub](https://img.shields.io/badge/-GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/sabertazimi)
[![Email](https://img.shields.io/badge/-Gmail-ea4335?style=for-the-badge&logo=gmail&logoColor=white)](mailto:sabertazimi@gmail.com)
[![X](https://img.shields.io/badge/-X.com-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/sabertazimi)
