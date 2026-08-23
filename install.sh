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

# Link each ENTRY of a directory, leaving the destination itself a real dir.
#
# Symlinking the directory itself makes this repo the destination for anything
# that writes into it -- `lightdash install-skills --global`, a plugin
# installer, Claude Code's own /agents -- so machine-local or work-specific
# files land in a public repo without anyone choosing that. Per-entry links keep
# the repo's contents shared and everything else machine-local.
#
# Tradeoff: entries added to the repo elsewhere need a re-run to show up here.
link_children() {
  local src="$1" dest="$2" entry
  if [ ! -d "$src" ]; then
    echo "skip: $src does not exist"
    return
  fi

  # Replace a whole-directory symlink left by an older install. Removing the
  # link never touches the repo it points at.
  if [ -L "$dest" ]; then
    rm "$dest"
    echo "unlinked   $dest (was a whole-directory symlink)"
  fi
  mkdir -p "$dest"

  # Drop links we own whose target has since left the repo. Real files and
  # links pointing anywhere else are left alone -- those are the user's.
  for entry in "$dest"/*; do
    [ -L "$entry" ] || continue
    case "$(readlink "$entry")" in
      "$src"/*) [ -e "$entry" ] || { rm "$entry"; echo "pruned     $entry (target gone)"; } ;;
    esac
  done

  for entry in "$src"/*; do
    [ -e "$entry" ] || continue # unmatched glob
    link "$entry" "$dest/$(basename "$entry")"
  done
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
# The conf stays at ~/.tmux.conf; only the helper scripts it shells out to are
# XDG. Nothing here is named tmux.conf on purpose — tmux also looks for
# $XDG_CONFIG_HOME/tmux/tmux.conf, and a second config found there would load
# instead of the one above.
link "$DOTFILES/.config/tmux"        "$XDG_CONFIG_HOME/tmux"

# Hammerspoon: link the file, not ~/.hammerspoon itself — Spoons install into
# that directory and would otherwise land in this repo (same trap as .claude).
link "$DOTFILES/.hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"

# --- Git / CLI -----------------------------------------------------------
link "$DOTFILES/.gitconfig"          "$HOME/.gitconfig"
link "$DOTFILES/.psqlrc"             "$HOME/.psqlrc"

# Git identity files (untracked, seeded once, never symlinked). .gitconfig
# selects between them by directory, so a work machine never has to remember to
# override anything: repos under ~/dev get the work address, ~/dev/notjrbauer/
# carves personal back out, everything else falls back to .gitconfig's [user].
# The work address is a placeholder here on purpose — this repo is public.
seed() {
  local path="$1" body="$2"
  [ -f "$path" ] && return
  printf '%s\n' "$body" > "$path"
  echo "seeded     $path"
}

seed "$HOME/.gitconfig.work" '; Work identity (untracked). Applied to every repo under ~/dev.
[user]
	name = john b
	email = you@company.example'

seed "$HOME/.gitconfig.personal" '; Personal identity (untracked). Applied to repos under ~/dev/notjrbauer/,
; which sits inside the work tree and so needs to override it.
[user]
	name = john b
	email = notjrbauer@gmail.com'

seed "$HOME/.gitconfig.local" '; Machine-local git overrides (untracked). Identity comes from
; ~/.gitconfig.work and ~/.gitconfig.personal, selected by directory in
; .gitconfig — keep this for things that are genuinely per-machine, like
; signing keys or credential helpers.'

# --- Shell secrets --------------------------------------------------------
# Sourced by $ZDOTDIR/.zshenv. Deliberately in $HOME and not ~/.config/zsh —
# that path is a symlink to this repo, so a secrets file there would sit in a
# public tree. 600 because it holds tokens.
seed "$HOME/.zshenv.local" '# Machine-local shell env (untracked) — sourced by $ZDOTDIR/.zshenv.
# Secrets and per-machine vars only. Never commit this file; it is not in the
# repo, and must not be moved into ~/.config/zsh (that is a symlink to it).

# GitHub PAT for Homebrew. Required — not just a rate-limit nicety — by the
# livekit/nebula formula, which pulls release assets from a private repo via a
# custom download strategy that raises if this is unset. Needs `repo` scope.
# export HOMEBREW_GITHUB_API_TOKEN=ghp_xxx'
chmod 600 "$HOME/.zshenv.local" \
  || echo "warn: could not chmod 600 ~/.zshenv.local (owned by someone else?) — it holds tokens"

# --- Git hooks ------------------------------------------------------------
# .githooks/pre-commit blocks staged credentials. Only wired if nothing else
# owns core.hooksPath, so a different hooks setup here is never clobbered.
# Reversible with: git config --unset core.hooksPath
chmod +x "$DOTFILES/.githooks/pre-commit" 2>/dev/null || true
existing="$(git -C "$DOTFILES" config --local --get core.hooksPath || true)"
if [ -z "$existing" ]; then
  git -C "$DOTFILES" config --local core.hooksPath .githooks
  echo "wired      core.hooksPath -> .githooks"
elif [ "$existing" != ".githooks" ]; then
  echo "skip: core.hooksPath is already '$existing' — leaving it alone"
fi

# --- Claude Code ---------------------------------------------------------
# Portable config only (see .claude/README.md). Runtime state — transcripts,
# caches, credentials, plugins — stays local in ~/.claude and is never tracked.
# agents/ and skills/ are linked per entry, not as whole directories, so that
# anything installed into them later stays on this machine instead of landing
# in a public repo (see link_children).
link "$DOTFILES/.claude/CLAUDE.md"      "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/.claude/settings.json"  "$HOME/.claude/settings.json"
link_children "$DOTFILES/.claude/agents" "$HOME/.claude/agents"
link_children "$DOTFILES/.claude/skills" "$HOME/.claude/skills"

echo ""
echo "Done. Start a new shell (or run: exec zsh -l) to pick up the changes."
