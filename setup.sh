#!/usr/bin/env bash
set -euo pipefail

# Setup script for Neovim 0.12 + LazyVim
# Installs only what nvim and its plugins need — nothing else.
# Re-runnable: shell config block is replaced in-place via markers.
#
# Supports: Ubuntu/Debian, Fedora/RHEL, Arch, macOS

NVIM_VERSION="v0.12.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="$HOME/.bashrc"
MARKER="# >>> nvim-config >>>"
SOURCE_LINE="source ~/.config/nvim/shell-init.bash $MARKER"

# ── Helpers ───────────────────────────────────────────────────────────

info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
error() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*"; exit 1; }
command_exists() { command -v "$1" &>/dev/null; }

detect_os() {
  if [[ "$OSTYPE" == darwin* ]]; then echo "macos"
  elif command_exists apt-get;    then echo "debian"
  elif command_exists dnf;        then echo "fedora"
  elif command_exists pacman;     then echo "arch"
  else                                 echo "unknown"
  fi
}

# ── Neovim ────────────────────────────────────────────────────────────

install_neovim() {
  if command_exists nvim; then
    local current
    current=$(nvim --version | head -1 | grep -oP 'v[\d.]+')
    if [[ "$current" == "$NVIM_VERSION" ]]; then
      info "Neovim $NVIM_VERSION already installed"
      return
    fi
    warn "Neovim $current found — upgrading to $NVIM_VERSION"
  fi

  info "Installing Neovim $NVIM_VERSION …"
  local os; os=$(detect_os)

  case "$os" in
    macos)
      if command_exists brew; then
        brew install neovim
      else
        local arch; arch=$(uname -m)
        local tarball="nvim-macos-${arch}.tar.gz"
        curl -fLO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${tarball}"
        xattr -c "./${tarball}" 2>/dev/null || true
        tar xzf "${tarball}"
        sudo cp -r "nvim-macos-${arch}/"* /usr/local/
        rm -rf "${tarball}" "nvim-macos-${arch}"
      fi
      ;;
    debian|fedora|arch)
      local arch; arch=$(uname -m)
      [[ "$arch" == "aarch64" ]] && arch="arm64"
      [[ "$arch" =~ ^(x86_64|arm64)$ ]] || error "Unsupported architecture: $arch"

      local tarball="nvim-linux-${arch}.tar.gz"
      curl -fLO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${tarball}"
      sudo rm -rf /opt/nvim
      sudo tar xzf "${tarball}" -C /opt/
      sudo mv "/opt/nvim-linux-${arch}" /opt/nvim
      rm -f "${tarball}"
      export PATH="/opt/nvim/bin:$PATH"
      ;;
    *)
      error "Unsupported OS — install Neovim $NVIM_VERSION manually: https://github.com/neovim/neovim/releases/tag/$NVIM_VERSION"
      ;;
  esac

  info "Neovim installed: $(nvim --version | head -1)"
}

# ── Nvim plugin dependencies ─────────────────────────────────────────
# fzf, ripgrep, fd, bat  — fzf-lua plugin
# gcc/cc                  — treesitter parser compilation

install_dependencies() {
  info "Installing nvim plugin dependencies …"
  local os; os=$(detect_os)

  case "$os" in
    macos)
      brew install fzf ripgrep fd bat
      ;;
    debian)
      sudo apt-get update
      sudo apt-get install -y fzf ripgrep fd-find bat build-essential
      command_exists fdfind && ! command_exists fd  && sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
      command_exists batcat && ! command_exists bat && sudo ln -sf "$(which batcat)" /usr/local/bin/bat
      ;;
    fedora)
      sudo dnf install -y fzf ripgrep fd-find bat gcc make
      ;;
    arch)
      sudo pacman -Syu --noconfirm fzf ripgrep fd bat base-devel
      ;;
    *)
      error "Unsupported OS — install manually: fzf, ripgrep, fd, bat, gcc"
      ;;
  esac

  info "Dependencies installed"
}

# ── Link config ──────────────────────────────────────────────────────

link_config() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

  if [[ "$SCRIPT_DIR" == "$config_dir" ]]; then
    info "Config already in place at $config_dir"
    return
  fi

  if [[ -e "$config_dir" ]]; then
    local backup="${config_dir}.bak.$(date +%s)"
    warn "Backing up existing config to $backup"
    mv "$config_dir" "$backup"
  fi

  ln -sf "$SCRIPT_DIR" "$config_dir"
  info "Linked $SCRIPT_DIR -> $config_dir"
}

# ── Shell config ─────────────────────────────────────────────────────
# Single source line in .bashrc tagged with a marker comment.
# Re-runs replace it in-place via sed.
# First run inserts after the tools marker (so nvim PATH/aliases
# override tools defaults), or appends if tools marker is absent.

TOOLS_MARKER="# >>> tools >>>"

configure_shell() {
  local init_file="$SCRIPT_DIR/shell-init.bash"
  [[ -f "$init_file" ]] || error "shell-init.bash not found at $init_file"

  touch "$BASHRC"

  if grep -qF "$MARKER" "$BASHRC"; then
    info "Replacing nvim-config line in $BASHRC"
    sed -i "s|.*${MARKER}.*|${SOURCE_LINE}|" "$BASHRC"
  elif grep -qF "$TOOLS_MARKER" "$BASHRC"; then
    info "Inserting nvim-config line after tools in $BASHRC"
    sed -i "/${TOOLS_MARKER}/a ${SOURCE_LINE}" "$BASHRC"
  else
    info "Appending nvim-config line to $BASHRC"
    printf '\n%s\n' "$SOURCE_LINE" >> "$BASHRC"
  fi

  # shellcheck disable=SC1090
  source "$init_file"
  info "Shell configured — restart your shell or: source $BASHRC"
}

# ── Bootstrap plugins ────────────────────────────────────────────────

bootstrap_plugins() {
  info "Bootstrapping Neovim plugins (lazy.nvim sync) …"
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
  info "Plugins synced"
}

# ── Main ─────────────────────────────────────────────────────────────

main() {
  info "=== Neovim $NVIM_VERSION Setup ==="
  echo
  install_neovim
  install_dependencies
  link_config
  configure_shell
  bootstrap_plugins
  echo
  info "=== Setup complete ==="
  info "Run 'nvim' to start. Mason will auto-install LSP servers on first launch."
}

main "$@"
