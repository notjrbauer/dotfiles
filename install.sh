#!/usr/bin/env bash
# install.sh — idempotently symlink these dotfiles into $HOME / $XDG_CONFIG_HOME.
#
# Safe to re-run. If a real (non-symlink) file already exists at a destination,
# it is moved aside to <path>.bak.<timestamp> before the symlink is created.
set -euo pipefail

# pwd -P (physical path) so link targets match the Makefile's $(realpath) —
# otherwise uninstall/status miss every link when the repo sits behind a symlink.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

link() {
  local src="$1" dest="$2"
  if [ ! -e "$src" ]; then
    echo "skip: $src does not exist"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    ln -sfn "$src" "$dest"                       # refresh an existing symlink
  elif [ -e "$dest" ]; then
    local bak="$dest.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$bak"
    echo "backed up  $dest -> $bak"
    ln -sfn "$src" "$dest"
  else
    ln -sfn "$src" "$dest"
  fi
  echo "linked     $dest -> $src"
}

# --- Shell (XDG) ---------------------------------------------------------
# ZDOTDIR lives at ~/.config/zsh; ~/.zshenv is just the bootstrap that sets it.
link "$DOTFILES/.zshenv"             "$HOME/.zshenv"
link "$DOTFILES/.config/zsh"         "$XDG_CONFIG_HOME/zsh"
link "$DOTFILES/.config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"

# --- Editor / terminal ---------------------------------------------------
link "$DOTFILES/.config/nvim"        "$XDG_CONFIG_HOME/nvim"
link "$DOTFILES/.config/wezterm"     "$XDG_CONFIG_HOME/wezterm"
link "$DOTFILES/.config/ghostty"     "$XDG_CONFIG_HOME/ghostty"
link "$DOTFILES/.tmux.conf"          "$HOME/.tmux.conf"

# --- Git / CLI -----------------------------------------------------------
link "$DOTFILES/.gitconfig"          "$HOME/.gitconfig"
link "$DOTFILES/.psqlrc"             "$HOME/.psqlrc"

# Machine-local git identity (work email etc.) — .gitconfig includes it last,
# so it overrides. Seeded once (real file, never symlinked, never tracked).
if [ ! -f "$HOME/.gitconfig.local" ]; then
  printf '# Machine-local git overrides (untracked). Set the identity for THIS machine.\n[user]\n    name = john b\n    email = notjrbauer@gmail.com\n' > "$HOME/.gitconfig.local"
  echo "seeded     $HOME/.gitconfig.local (edit for per-machine identity)"
fi

# --- tmux plugins ---------------------------------------------------------
# tpm isn't brewable; clone it like .zshrc auto-clones zap. Plugins install on
# first tmux start with prefix+I.
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone -q --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" \
    && echo "cloned     ~/.tmux/plugins/tpm" \
    || echo "skip: tpm clone failed (offline?) — rerun install.sh later"
fi

# --- Claude Code ---------------------------------------------------------
# Portable config only (see .claude/README.md). Runtime state — transcripts,
# caches, credentials, plugins — stays local in ~/.claude and is never
# tracked. ~/.claude/agents is a single symlink to the whole curated set.
link "$DOTFILES/.claude/CLAUDE.md"      "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/.claude/settings.json"  "$HOME/.claude/settings.json"
link "$DOTFILES/.claude/agents"         "$HOME/.claude/agents"

echo ""
echo "Done. Start a new shell (or run: exec zsh -l) to pick up the changes."
