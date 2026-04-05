#!/usr/bin/env bash
set -euo pipefail

# Update LazyVim starter files and all plugins, then sync the lockfile.
# Usage: ./update.sh [--commit]
#   --commit   Stage and commit all changes after a successful update.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCKFILE="$SCRIPT_DIR/lazy-lock.json"
STARTER_REPO="https://github.com/LazyVim/starter"

# ── Helpers ───────────────────────────────────────────────────────────

info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
error() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*"; exit 1; }

# ── Pre-flight checks ────────────────────────────────────────────────

command -v nvim &>/dev/null || error "nvim not found — run setup.sh first"
command -v git  &>/dev/null || error "git not found"

info "Neovim version: $(nvim --version | head -1)"
info "Config dir: $SCRIPT_DIR"
echo

# ── Update LazyVim starter files ─────────────────────────────────────
# Clone the latest LazyVim starter template into a temp directory and
# copy base config files into our repo. Custom plugin specs (lua/plugins/*)
# and repo-specific files (setup.sh, shell-init.bash, etc.) are preserved.

update_starter() {
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  info "Cloning LazyVim starter from $STARTER_REPO …"
  git clone --depth 1 "$STARTER_REPO" "$tmpdir" 2>&1 | while IFS= read -r line; do
    printf '  %s\n' "$line"
  done
  rm -rf "$tmpdir/.git"

  # Files to sync from the starter (base scaffolding).
  # lua/config/lazy.lua is excluded — it contains user customizations
  # (extra imports, spec overrides, etc.) that must be maintained by hand.
  local -a starter_files=(
    init.lua
    .neoconf.json
    stylua.toml
    lua/config/options.lua
    lua/config/keymaps.lua
    lua/config/autocmds.lua
  )

  local updated=0
  for f in "${starter_files[@]}"; do
    local src="$tmpdir/$f"
    local dst="$SCRIPT_DIR/$f"

    [[ -f "$src" ]] || continue

    # Create parent directory if needed
    mkdir -p "$(dirname "$dst")"

    if [[ -f "$dst" ]] && diff -q "$src" "$dst" &>/dev/null; then
      continue  # unchanged
    fi

    if [[ -f "$dst" ]]; then
      info "  updated: $f"
    else
      info "  new:     $f"
    fi
    cp "$src" "$dst"
    ((updated++))
  done

  if ((updated == 0)); then
    info "LazyVim starter files are already up to date"
  else
    info "Updated $updated starter file(s)"
    warn "Review changes — your customizations in lua/config/ may need merging"
  fi
}

update_starter
echo

# ── Update plugins ───────────────────────────────────────────────────

info "Updating plugins (Lazy sync) …"
nvim --headless "+Lazy! sync" +qa 2>&1 | while IFS= read -r line; do
  printf '  %s\n' "$line"
done
info "Plugin sync complete"

# ── Update treesitter parsers ────────────────────────────────────────

info "Updating Treesitter parsers …"
nvim --headless "+TSUpdateSync" +qa 2>&1 | while IFS= read -r line; do
  printf '  %s\n' "$line"
done
info "Treesitter update complete"

# ── Update Mason tools ──────────────────────────────────────────────

info "Updating Mason tools …"
nvim --headless "+MasonUpdate" +qa 2>&1 | while IFS= read -r line; do
  printf '  %s\n' "$line"
done
info "Mason update complete"

# ── Show what changed ────────────────────────────────────────────────

echo
if git -C "$SCRIPT_DIR" diff --quiet 2>/dev/null; then
  info "No changes — everything already up to date"
else
  info "Changes summary:"
  git -C "$SCRIPT_DIR" diff --stat 2>/dev/null || true
  echo
  git -C "$SCRIPT_DIR" diff 2>/dev/null || true
fi

# ── Optional commit ──────────────────────────────────────────────────

if [[ "${1:-}" == "--commit" ]]; then
  echo
  if git -C "$SCRIPT_DIR" diff --quiet 2>/dev/null; then
    info "Nothing to commit"
  else
    git -C "$SCRIPT_DIR" add \
      init.lua .neoconf.json stylua.toml \
      lua/config/ \
      lazy-lock.json lazyvim.json
    git -C "$SCRIPT_DIR" commit -m "chore: update LazyVim starter files and plugins"
    info "Committed all updates"
  fi
fi
