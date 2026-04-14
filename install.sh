#!/usr/bin/env bash
set -euo pipefail

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                    GENTLEMAN DOTS - Homebrew Installer                       ║
# ║                Select components to install and configure                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

BREW_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIGS_DIR="$BREW_DIR/configs"

# ─── Brew: auto-accept, no prompts, no auto-update ───
export NONINTERACTIVE=1
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${BLUE}[info]${NC} $1"; }
ok()    { echo -e "${GREEN}[ok]${NC} $1"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $1"; }
err()   { echo -e "${RED}[error]${NC} $1"; }
header(){ echo -e "\n${BOLD}${CYAN}══ $1 ══${NC}\n"; }

# ─── Component flags ───
SEL_WM=0
SEL_SHELL=0
SEL_TERMINAL=0
SEL_TMUX=0
SEL_EDITOR=0
SEL_DEV=0
SEL_CLI=0
SEL_FONTS=0

select_components() {
  header "Component Selection"
  echo -e "Select what to install (space-separated numbers, or ${BOLD}all${NC}):\n"
  echo -e "  ${BOLD}1${NC}) Window Management (yabai + skhd + sketchybar)"
  echo -e "  ${BOLD}2${NC}) Shell (fish + carapace + zoxide + atuin + fzf)"
  echo -e "  ${BOLD}3${NC}) Terminal (ghostty)"
  echo -e "  ${BOLD}4${NC}) Multiplexer (tmux + TPM + kanagawa theme)"
  echo -e "  ${BOLD}5${NC}) Editor (neovim + tree-sitter)"
  echo -e "  ${BOLD}6${NC}) Development (node + bun + go + rust + volta)"
  echo -e "  ${BOLD}7${NC}) CLI Tools (jq + fd + rg + bat + lazygit + yazi + tv + gh)"
  echo -e "  ${BOLD}8${NC}) Fonts (Iosevka Term Nerd Font)"
  echo ""
  read -rp "Selection [all]: " choice
  choice="${choice:-all}"

  if [ "$choice" = "all" ]; then
    SEL_WM=1; SEL_SHELL=1; SEL_TERMINAL=1; SEL_TMUX=1; SEL_EDITOR=1; SEL_DEV=1; SEL_CLI=1; SEL_FONTS=1
  else
    for num in $choice; do
      case "$num" in
        1) SEL_WM=1 ;;
        2) SEL_SHELL=1 ;;
        3) SEL_TERMINAL=1 ;;
        4) SEL_TMUX=1 ;;
        5) SEL_EDITOR=1 ;;
        6) SEL_DEV=1 ;;
        7) SEL_CLI=1 ;;
        8) SEL_FONTS=1 ;;
      esac
    done
  fi

  echo ""
  info "Installing:"
  [ $SEL_WM -eq 1 ]       && echo -e "  ${GREEN}+${NC} Window Management (yabai + skhd + sketchybar)"
  [ $SEL_SHELL -eq 1 ]     && echo -e "  ${GREEN}+${NC} Shell (fish + carapace + zoxide + atuin + fzf)"
  [ $SEL_TERMINAL -eq 1 ]  && echo -e "  ${GREEN}+${NC} Terminal (ghostty)"
  [ $SEL_TMUX -eq 1 ]      && echo -e "  ${GREEN}+${NC} Multiplexer (tmux + TPM + kanagawa)"
  [ $SEL_EDITOR -eq 1 ]    && echo -e "  ${GREEN}+${NC} Editor (neovim + tree-sitter)"
  [ $SEL_DEV -eq 1 ]       && echo -e "  ${GREEN}+${NC} Development (node + bun + go + rust + volta)"
  [ $SEL_CLI -eq 1 ]       && echo -e "  ${GREEN}+${NC} CLI Tools"
  [ $SEL_FONTS -eq 1 ]     && echo -e "  ${GREEN}+${NC} Fonts (Iosevka Term Nerd Font)"
  echo ""
  read -rp "Continue? [Y/n]: " confirm
  if [ "${confirm:-y}" = "n" ] || [ "${confirm:-y}" = "N" ]; then
    exit 0
  fi
}

# ─── Homebrew ───
ensure_homebrew() {
  if ! command -v brew &>/dev/null; then
    header "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  ok "Homebrew ready"
}

# ─── Helpers ───
brew_install() {
  local pkg="$1"
  if brew list "$pkg" &>/dev/null; then
    ok "$pkg already installed"
  else
    info "Installing $pkg..."
    brew install "$pkg" || warn "Failed to install $pkg"
  fi
}

brew_cask_install() {
  local pkg="$1"
  if brew list --cask "$pkg" &>/dev/null; then
    ok "$pkg already installed"
  else
    info "Installing $pkg (cask)..."
    brew install --cask "$pkg" || warn "Failed to install $pkg"
  fi
}

deploy_config() {
  local name="$1"
  local src="$CONFIGS_DIR/$2"
  local dst="$HOME/.config/$3"

  if [ ! -d "$src" ] && [ ! -f "$src" ]; then
    warn "Source not found: $src"
    return
  fi

  rm -rf "$dst"
  mkdir -p "$dst"
  cp -r "$src"/* "$dst"/
  info "Deployed $name config to $dst"
}

# ─── Component Install Functions ───
install_wm() {
  header "Installing Window Management"
  brew tap FelixKratz/formulae 2>/dev/null || true
  brew tap koekeishiya/formulae 2>/dev/null || true
  brew_install koekeishiya/formulae/yabai
  brew_install koekeishiya/formulae/skhd
  brew_install FelixKratz/formulae/sketchybar
}

install_shell() {
  header "Installing Shell"
  for pkg in fish carapace zoxide atuin fzf; do
    brew_install "$pkg"
  done
}

install_terminal() {
  header "Installing Terminal"
  brew_cask_install ghostty
}

install_tmux() {
  header "Installing Tmux"
  brew_install tmux
}

install_editor() {
  header "Installing Editor"
  brew_install neovim
  brew_install tree-sitter
}

install_dev() {
  header "Installing Development Tools"
  for pkg in node bun go rust volta; do
    brew_install "$pkg"
  done
}

install_cli() {
  header "Installing CLI Tools"
  for pkg in jq fd ripgrep bat lazygit yazi television coreutils findutils unzip gh; do
    brew_install "$pkg"
  done
}

install_fonts() {
  header "Installing Fonts"
  brew_cask_install font-iosevka-term-nerd-font
}

# ─── Component Setup Functions ───
setup_wm() {
  header "Configuring Window Management"

  # ── yabai ──
  deploy_config "yabai" "yabai" "yabai"
  chmod +x "$HOME/.config/yabai/yabairc"
  chmod +x "$HOME/.config/yabai/move-window-to-space.sh"

  # Mission Control: disable auto space reorder
  defaults write com.apple.dock mru-spaces -bool false
  killall Dock 2>/dev/null || true
  info "Mission Control: auto space reorder disabled"

  # sudoers for scripting addition
  local yabai_bin
  yabai_bin="$(command -v yabai)"
  local yabai_hash
  yabai_hash="$(shasum -a 256 "$yabai_bin" | awk '{print $1}')"
  local expected_entry="$USER ALL=(root) NOPASSWD: sha256:$yabai_hash $yabai_bin --load-sa"

  local needs_update=false
  if [ ! -f /private/etc/sudoers.d/yabai ]; then
    needs_update=true
  elif ! grep -q "$yabai_hash" /private/etc/sudoers.d/yabai 2>/dev/null; then
    needs_update=true
  fi

  if [ "$needs_update" = true ]; then
    info "Updating yabai sudoers entry..."
    echo "$expected_entry" | sudo tee /private/etc/sudoers.d/yabai >/dev/null
    sudo yabai --load-sa
    ok "Yabai sudoers configured"
  else
    ok "Yabai sudoers already up to date"
  fi

  # Start yabai service
  yabai --stop-service 2>/dev/null || true
  yabai --start-service
  ok "Yabai service started"

  # ── skhd ──
  deploy_config "skhd" "skhd" "skhd"
  chmod +x "$HOME/.config/skhd/skhdrc"
  skhd --stop-service 2>/dev/null || true
  skhd --start-service
  ok "skhd service started"

  # ── sketchybar ──
  deploy_config "sketchybar" "sketchybar" "sketchybar"
  chmod +x "$HOME/.config/sketchybar/sketchybarrc"
  chmod +x "$HOME/.config/sketchybar/plugins/"*.sh 2>/dev/null || true
  brew services stop sketchybar 2>/dev/null || true
  brew services start sketchybar
  ok "SketchyBar service started"

  # ── sktoggle alias ──
  local fish_fn_dir="$HOME/.config/fish/functions"
  mkdir -p "$fish_fn_dir"
  cat > "$fish_fn_dir/sktoggle.fish" << 'FISHEOF'
function sktoggle --description "Toggle sketchybar items interactively"
    ~/.config/sketchybar/plugins/toggle_items.sh
end
FISHEOF
  info "Added sktoggle fish function"

  # Also add to bash profile
  local bashrc="$HOME/.bashrc"
  if ! grep -q "alias sktoggle" "$bashrc" 2>/dev/null; then
    echo 'alias sktoggle="~/.config/sketchybar/plugins/toggle_items.sh"' >> "$bashrc"
    info "Added sktoggle bash alias"
  fi
  ok "sktoggle ready — run 'sktoggle' to toggle sketchybar items"
}

setup_shell() {
  header "Configuring Shell"
  local fish_bin
  fish_bin="$(command -v fish)"

  if ! grep -qx "$fish_bin" /etc/shells 2>/dev/null; then
    info "Adding $fish_bin to /etc/shells..."
    echo "$fish_bin" | sudo tee -a /etc/shells >/dev/null
  fi

  if [ "$SHELL" != "$fish_bin" ]; then
    info "Setting fish as login shell..."
    chsh -s "$fish_bin"
    ok "Login shell set to $fish_bin"
  else
    ok "Fish is already the login shell"
  fi
}

setup_terminal() {
  header "Configuring Terminal"

  deploy_config "ghostty" "ghostty" "ghostty"

  # Ensure ghostty uses fish
  local fish_bin
  fish_bin="$(command -v fish)"
  local config="$HOME/.config/ghostty/config"

  if [ -f "$config" ] && ! grep -q "^command" "$config"; then
    printf 'command = %s -l\n\n' "$fish_bin" | cat - "$config" > "$config.tmp"
    mv "$config.tmp" "$config"
    info "Added fish command to ghostty config"
  fi
  ok "Ghostty configured"
}

setup_tmux() {
  header "Configuring Tmux"

  deploy_config "tmux" "tmux" "tmux"

  # Install TPM (Tmux Plugin Manager)
  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    info "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    ok "TPM installed"
  else
    ok "TPM already installed"
  fi

  # Install plugins via TPM
  info "Installing tmux plugins..."
  "$HOME/.tmux/plugins/tpm/bin/install_plugins" 2>/dev/null || warn "Run 'prefix + I' inside tmux to install plugins"
  ok "Tmux configured (prefix = Ctrl+A)"
}

setup_editor() {
  header "Configuring Editor"
  deploy_config "nvim" "nvim" "nvim"

  # Also deploy minimal oil config
  if [ -d "$CONFIGS_DIR/nvim-oil-minimal" ]; then
    rm -rf "$HOME/.config/nvim-oil-minimal"
    mkdir -p "$HOME/.config/nvim-oil-minimal"
    cp -r "$CONFIGS_DIR/nvim-oil-minimal/"* "$HOME/.config/nvim-oil-minimal/"
    info "Deployed nvim-oil-minimal config"
  fi
  ok "Neovim configured"
}

# ─── Main ───
main() {
  echo -e "${BOLD}${CYAN}"
  echo "  ╔════════════════════════════════════════╗"
  echo "  ║     Gentleman Dots - Brew Installer    ║"
  echo "  ╚════════════════════════════════════════╝"
  echo -e "${NC}"

  select_components

  # Ask for sudo upfront and keep it alive for the entire run
  header "Authentication"
  info "Some steps need admin privileges (sudoers, login shell, etc.)"
  sudo -v
  # Keep sudo alive in background
  while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null' EXIT

  ensure_homebrew

  # Install packages
  [ $SEL_WM -eq 1 ]       && install_wm
  [ $SEL_SHELL -eq 1 ]     && install_shell
  [ $SEL_TERMINAL -eq 1 ]  && install_terminal
  [ $SEL_TMUX -eq 1 ]      && install_tmux
  [ $SEL_EDITOR -eq 1 ]    && install_editor
  [ $SEL_DEV -eq 1 ]       && install_dev
  [ $SEL_CLI -eq 1 ]       && install_cli
  [ $SEL_FONTS -eq 1 ]     && install_fonts

  # Deploy configs and set up services
  [ $SEL_WM -eq 1 ]       && setup_wm
  [ $SEL_SHELL -eq 1 ]     && setup_shell
  [ $SEL_TERMINAL -eq 1 ]  && setup_terminal
  [ $SEL_TMUX -eq 1 ]      && setup_tmux
  [ $SEL_EDITOR -eq 1 ]    && setup_editor

  echo ""
  header "Installation Complete"
  ok "All selected components installed and configured"
  echo ""
  echo -e "  ${BOLD}Quick reference:${NC}"
  if [ $SEL_WM -eq 1 ]; then
    echo "    yabai --restart-service              Restart window manager"
    echo "    skhd --restart-service               Restart hotkeys"
    echo "    brew services restart sketchybar     Restart status bar"
  fi
  if [ $SEL_TMUX -eq 1 ]; then
    echo "    tmux                                 Start tmux (prefix: Ctrl+A)"
    echo "    prefix + I                           Install tmux plugins"
  fi
  echo "    brew bundle --file=$BREW_DIR/Brewfile  Re-install all packages"
  echo ""
}

main "$@"
