# AGENTS.md

Guidance to coding agents when working with code in this repository.

Hackable personal dotfiles managed with chezmoi.

## Structure

```plaintext
dot_*/            # Managed dotfiles (public)
private_dot_*/    # Managed dotfiles (private)
themes/           # Shell themes (zsh, bash)
wallpapers/       # Wallpaper management scripts
```

## Chezmoi Conventions

- Files under `dot_config/` install to `~/.config/`
- Files under `dot_local/` install to `~/.local/`
- `dot_*` files are installed to `~/.*`: e.g., `dot_zshrc` → `~/.zshrc`
- `executable_*` files are deployed with `+x` permission:
  e.g., `dot_local/bin/executable_tmux-entry.sh` → `~/.local/bin/tmux-entry.sh`
- `modify_*` files are `stdin`→`stdout` bash scripts that patch the target file in-place:
  placed alongside the target in the same directory
- `private_*` files are private: e.g., `dot_local/share/private_fcitx5/` -> `~/.local/share/fcitx5/`
- `*.tmpl` files are chezmoi templates: e.g., `.chezmoi.toml.tmpl`

## Commit

Conventional commits: `chore:`, `feat:`, `fix:`, `docs:`.
