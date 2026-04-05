# Neovim configuration shell init
# Sourced from ~/.bashrc — managed by setup.sh

# Make nvim available (Linux tarball installs to /opt/nvim)
if [ -d /opt/nvim/bin ]; then
  export PATH="/opt/nvim/bin:$PATH"
fi

alias vim="nvim"
alias vi="nvim"
export EDITOR="nvim"
export VISUAL="nvim"
