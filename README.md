# Horacio.Dots

Dotfiles for macOS managed with **Homebrew**. Interactive installer with selectable components — pick what you need, skip what you don't.

## Quick Start

```bash
git clone git@github.com:HoracioEspinosa/Horacio.Dots.git
cd Horacio.Dots
bash install.sh
```

The installer asks for your password once at the beginning and runs everything non-interactively after that.

## Components

Select by number (space-separated) or type `all`:

| # | Component | What it installs | Config |
|---|-----------|-----------------|--------|
| 1 | **Window Management** | yabai, skhd, sketchybar | Tiling WM + hotkeys + status bar |
| 2 | **Shell** | fish, carapace, zoxide, atuin, fzf, starship | Fish shell with completions, history search, fuzzy finder, polyglot prompt |
| 3 | **Terminal** | ghostty | GPU-accelerated terminal with custom shaders and Gentleman theme |
| 4 | **Multiplexer** | tmux + TPM | Terminal multiplexer with Kanagawa theme, vim navigation |
| 5 | **Editor** | neovim, tree-sitter | Full LazyVim config with LSP, AI integrations, Oil file manager |
| 6 | **Development** | node, bun, go, rust, volta | Languages and runtimes |
| 7 | **CLI Tools** | jq, fd, ripgrep, bat, lazygit, yazi, television, gh, and more | Modern CLI replacements |
| 8 | **Fonts** | Iosevka Term Nerd Font | Patched font with icons for terminal and editor |

## What Each Component Does

### 1. Window Management

- **yabai** — Tiling window manager with BSP layout, auto-padding, and opacity rules
- **skhd** — Hotkey daemon for window focus (`alt+ctrl+hjkl`), swapping (`alt+shift+hjkl`), resizing, and space switching (`alt+1-7`)
- **sketchybar** — Status bar with 25 plugins: spaces, current app, CPU, RAM, music, docker, power, datetime, and more

The installer automatically:
- Disables Mission Control auto-reorder (required for numbered spaces)
- Configures the yabai sudoers entry for the scripting addition
- Starts all three services

### 2. Shell

- **fish** — Modern shell with syntax highlighting and autosuggestions
- **carapace** — Multi-shell completion engine
- **zoxide** — Smarter `cd` that learns your most-used directories
- **atuin** — Shell history stored in a SQLite database with full-text search
- **fzf** — Fuzzy finder for files, history, and more
- **starship** — Polyglot prompt (Node, Python, Rust, Go, Docker, git branch, etc.)

The installer:

1. Adds fish to `/etc/shells` and sets it as your login shell (`chsh`)
2. Deploys canonical fish configs to `~/.config/fish/` — `config.fish`, `conf.d/`, `functions/`, `themes/`, `custom/`, `fish_plugins`
3. Bootstraps `fisher` and installs the declared plugins (fisher, nvm.fish, fzf.fish, plugin-pj)
4. Drops `starship.toml` at `~/.config/starship.toml`

**Customization without conflicts.** The fish deploy is overlay-style — `install.sh` copies shipped files but **never removes** files you added locally. The convention is:

| Location | Who owns it | Goes into git? |
|----------|-------------|----------------|
| `~/.config/fish/config.fish` | The repo (source of truth) | Yes (this repo) |
| `~/.config/fish/conf.d/<repo-file>.fish` | The repo (e.g. `nvm.fish`, `rustup.fish`) | Yes |
| `~/.config/fish/conf.d/secrets.fish` | **You** — tokens, AWS creds, private env vars | **No — never commit** |
| `~/.config/fish/conf.d/<yourname>-local.fish` | **You** — machine-specific PATHs, `$EDITOR`, etc. | Optional (personal repo) |
| `~/.config/fish/functions/<yourname>-*.fish` | **You** — personal scripts (e.g. `vpn.fish`, `tst-*.fish`) | Optional (personal repo) |

Since `conf.d/*.fish` is autoloaded alphabetically, your files layered on top of the shipped ones — a typical `conf.d/secrets.fish` just `set -Ux TOKEN "..."` and you're done.

### 3. Terminal (Ghostty)

GPU-accelerated terminal with:
- **52 custom shaders** including cursor smear, CRT effects, particle effects
- **Gentleman theme** — Dark theme with Kanagawa-inspired colors
- Splits, tabs, and vim-style navigation (`alt+hjkl`)
- macOS Alt key fix for option-as-alt

### 4. Multiplexer (tmux)

Tmux configured with:
- **Prefix**: `Ctrl+A` (remapped from `Ctrl+B`)
- **Kanagawa theme** with git, CPU, and RAM status
- **vim-tmux-navigator** — Seamless navigation between vim and tmux panes
- **tmux-resurrect** — Persist sessions across restarts
- **tmux-yank** — System clipboard integration
- **Floating scratch terminal** — `Alt+G` to toggle

TPM (Tmux Plugin Manager) and all plugins are installed automatically.

### 5. Editor (Neovim)

Full LazyVim configuration with:
- LSP support for multiple languages
- AI integrations (Copilot, Avante, CodeCompanion, Claude Code)
- Oil.nvim file manager with floating window and Zed integration
- Gentleman colorscheme
- Markdown preview, DAP debugging, and more

### 6–8. Development, CLI Tools, Fonts

Standard development toolchain and modern CLI replacements. See the component table above.

## Re-running

The installer is idempotent and **auto-upgrades outdated packages**. On a re-run:

- Packages already installed are checked via `brew outdated`; stale ones (e.g. neovim that needs to keep up with LazyVim's minimum) get `brew upgrade`d automatically
- Config files shipped by this repo get re-deployed; your local additions under `conf.d/`, `functions/`, etc. are preserved
- Fisher runs `fisher update` so plugin changes in `fish_plugins` take effect

```bash
bash install.sh
```

## Updating Configs Only

If you only want to re-deploy config files without reinstalling packages, you can copy them manually:

```bash
# Example: update sketchybar config
cp -r configs/sketchybar/* ~/.config/sketchybar/
chmod +x ~/.config/sketchybar/sketchybarrc ~/.config/sketchybar/plugins/*.sh
brew services restart sketchybar
```

## Service Management

```bash
# Window manager
yabai --restart-service
skhd --restart-service
brew services restart sketchybar

# After yabai update, regenerate sudoers:
echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d ' ' -f 1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai
```

## Project Structure

```
.
├── install.sh              # Interactive installer
├── Brewfile                # All Homebrew packages
└── configs/                # All configuration files
    ├── ghostty/            # Terminal config + 52 shaders + themes
    ├── yabai/              # Window manager config
    ├── skhd/               # Hotkey daemon config
    ├── sketchybar/         # Status bar + 25 plugins
    ├── tmux/               # Multiplexer config
    ├── nvim/               # Full Neovim/LazyVim config
    ├── nvim-oil-minimal/   # Minimal Oil.nvim config
    ├── zed/                # Zed editor settings + themes
    ├── television/         # Television file browser config
    ├── fish/               # Fish shell completions
    └── raycast/            # Raycast scripts
```

## Requirements

- macOS (Apple Silicon or Intel)
- Homebrew (installed automatically if missing)

## Key Bindings

### yabai + skhd

| Binding | Action |
|---------|--------|
| `alt+ctrl+h/j/k/l` | Focus window left/down/up/right |
| `alt+shift+h/j/k/l` | Swap window left/down/up/right |
| `alt+1-7` | Switch to space 1-7 |
| `alt+shift+1-7` | Move window to space 1-7 |
| `alt+r` | Rotate layout 90° |
| `alt+-/=` | Resize window |
| `alt+t` | Toggle float |
| `alt+f` | Toggle fullscreen |

### tmux

| Binding | Action |
|---------|--------|
| `Ctrl+A` | Prefix |
| `prefix+v` | Vertical split |
| `prefix+d` | Horizontal split |
| `Alt+G` | Toggle floating scratch terminal |
| `prefix+K` | Kill all other sessions |
| `prefix+I` | Install plugins (TPM) |

### Ghostty

| Binding | Action |
|---------|--------|
| `alt+v` | Split right |
| `alt+d` | Split down |
| `alt+h/j/k/l` | Navigate splits |
| `cmd+k` | Clear screen |
