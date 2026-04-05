#!/usr/bin/env bash
set -euo pipefail

# Setup script for Neovim 0.12 with LazyVim configuration
# Supports: Ubuntu/Debian, Fedora/RHEL, Arch, macOS

NVIM_VERSION="v0.12.0"

# --- Helpers ---

info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
error() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*"; exit 1; }

command_exists() { command -v "$1" &>/dev/null; }

detect_os() {
  if [[ "$OSTYPE" == darwin* ]]; then
    echo "macos"
  elif command_exists apt-get; then
    echo "debian"
  elif command_exists dnf; then
    echo "fedora"
  elif command_exists pacman; then
    echo "arch"
  else
    echo "unknown"
  fi
}

# --- Install Neovim 0.12 ---

install_neovim() {
  if command_exists nvim; then
    local current
    current=$(nvim --version | head -1 | grep -oP 'v[\d.]+')
    if [[ "$current" == "$NVIM_VERSION" ]]; then
      info "Neovim $NVIM_VERSION is already installed"
      return
    fi
    warn "Neovim $current found, will install $NVIM_VERSION"
  fi

  info "Installing Neovim $NVIM_VERSION..."

  local os
  os=$(detect_os)

  case "$os" in
    macos)
      if command_exists brew; then
        brew install neovim
      else
        local arch
        arch=$(uname -m)
        local tarball="nvim-macos-${arch}.tar.gz"
        curl -fLO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${tarball}"
        xattr -c "./${tarball}" 2>/dev/null || true
        tar xzf "${tarball}"
        sudo cp -r "nvim-macos-${arch}/"* /usr/local/
        rm -rf "${tarball}" "nvim-macos-${arch}"
      fi
      ;;
    debian|fedora|arch)
      local arch
      arch=$(uname -m)
      if [[ "$arch" == "x86_64" ]]; then
        arch="x86_64"
      elif [[ "$arch" == "aarch64" ]]; then
        arch="arm64"
      else
        error "Unsupported architecture: $arch"
      fi
      local tarball="nvim-linux-${arch}.tar.gz"
      curl -fLO "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${tarball}"
      sudo rm -rf /opt/nvim
      sudo tar xzf "${tarball}" -C /opt/
      sudo mv "/opt/nvim-linux-${arch}" /opt/nvim
      rm -f "${tarball}"

      # Add to PATH if not already there
      if ! echo "$PATH" | grep -q '/opt/nvim/bin'; then
        info "Adding /opt/nvim/bin to PATH in ~/.bashrc"
        echo 'export PATH="/opt/nvim/bin:$PATH"' >> ~/.bashrc
        export PATH="/opt/nvim/bin:$PATH"
      fi
      ;;
    *)
      error "Unsupported OS. Install Neovim $NVIM_VERSION manually: https://github.com/neovim/neovim/releases/tag/$NVIM_VERSION"
      ;;
  esac

  info "Neovim installed: $(nvim --version | head -1)"
}

# --- Install system dependencies ---

install_dependencies() {
  info "Installing system dependencies..."

  local os
  os=$(detect_os)

  case "$os" in
    macos)
      brew install git ripgrep fd fzf bat node python3 luarocks
      ;;
    debian)
      sudo apt-get update
      sudo apt-get install -y \
        git \
        curl \
        unzip \
        ripgrep \
        fd-find \
        fzf \
        bat \
        nodejs \
        npm \
        python3 \
        python3-pip \
        python3-venv \
        luarocks \
        build-essential
      # fd-find installs as 'fdfind' on Debian/Ubuntu — create symlink
      if command_exists fdfind && ! command_exists fd; then
        sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
      fi
      # bat installs as 'batcat' on Debian/Ubuntu — create symlink
      if command_exists batcat && ! command_exists bat; then
        sudo ln -sf "$(which batcat)" /usr/local/bin/bat
      fi
      ;;
    fedora)
      sudo dnf install -y \
        git \
        curl \
        unzip \
        ripgrep \
        fd-find \
        fzf \
        bat \
        nodejs \
        npm \
        python3 \
        python3-pip \
        luarocks \
        gcc \
        gcc-c++ \
        make
      ;;
    arch)
      sudo pacman -Syu --noconfirm \
        git \
        curl \
        unzip \
        ripgrep \
        fd \
        fzf \
        bat \
        nodejs \
        npm \
        python \
        python-pip \
        luarocks \
        base-devel
      ;;
    *)
      error "Unsupported OS. Install these manually: git, curl, unzip, ripgrep, fd, fzf, bat, nodejs, npm, python3, luarocks"
      ;;
  esac

  info "System dependencies installed"
}

# --- Link config ---

link_config() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

  if [[ "$script_dir" == "$config_dir" ]]; then
    info "Config already in place at $config_dir"
    return
  fi

  if [[ -e "$config_dir" ]]; then
    local backup="${config_dir}.bak.$(date +%s)"
    warn "Backing up existing config to $backup"
    mv "$config_dir" "$backup"
  fi

  ln -sf "$script_dir" "$config_dir"
  info "Linked $script_dir -> $config_dir"
}

# --- Shell aliases (vi/vim -> nvim, EDITOR) ---

configure_shell() {
  local rc="$HOME/.bashrc"
  local marker="# nvim-config-aliases"

  if grep -qF "$marker" "$rc" 2>/dev/null; then
    info "Shell aliases already configured in $rc"
    return
  fi

  info "Adding vi/vim/EDITOR aliases to $rc"
  cat >> "$rc" <<EOF

$marker
alias vim="nvim"
alias vi="nvim"
export EDITOR="nvim"
export VISUAL="nvim"
EOF

  info "Shell aliases added — restart your shell or run: source $rc"
}

# --- Bootstrap plugins ---

bootstrap_plugins() {
  info "Bootstrapping Neovim plugins (first run of lazy.nvim)..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
  info "Plugins synced"
}

# --- Main ---

main() {
  info "=== Neovim 0.12 Setup ==="
  echo

  install_neovim
  install_dependencies
  link_config
  configure_shell
  bootstrap_plugins

  echo
  info "=== Setup complete ==="
  info "Run 'nvim' to start. Mason will auto-install LSP servers on first launch."
  info "Configured language servers: lua_ls, clojure-lsp, jdtls (Java), terraform-ls"
  info "Required CLI tools installed: ripgrep, fd, fzf, bat, git"
}

main "$@"
