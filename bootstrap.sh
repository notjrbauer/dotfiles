#!/usr/bin/env bash
# bootstrap.sh — take a FRESH machine to a working environment in one command.
#
#   git clone <this-repo> && cd dotfiles && ./bootstrap.sh
#
# Order matters:
#   1. Xcode Command Line Tools   (git/cc — cloning usually triggered this already)
#   2. Homebrew                   (installed if missing, arch-aware)
#   3. brew bundle                (Brewfile; mas apps tolerated pre-App-Store-sign-in)
#   4. ./install.sh               (symlinks; seeds ~/.gitconfig.*, ~/.zshenv.local)
#   5. Node LTS via fnm           (nothing else installs an actual node)
#   6. cargo tools                (tree-sitter CLI; brew's tree-sitter is lib-only)
#   7. Login shell                (brew zsh; macOS ships an older one at /bin/zsh)
#   8. Neovim nightly             (init.lua targets 0.12+; brew stable may lag)
#
# Idempotent: every step checks before it acts; safe to re-run after a partial
# failure (e.g. sign into the App Store, then run it again).
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "==> non-macOS: linking dotfiles only (install packages via your distro)"
  "$DOTFILES/install.sh"
  exit 0
fi

# --- 1. Xcode Command Line Tools ------------------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  echo "==> installing Xcode Command Line Tools (accept the GUI prompt)…"
  xcode-select --install 2>/dev/null || true
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
fi

# --- 2. Homebrew -----------------------------------------------------------
if [[ ! -x /opt/homebrew/bin/brew && ! -x /usr/local/bin/brew ]]; then
  echo "==> installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/usr/local/bin/brew shellenv)"
fi

# --- 3. Packages -----------------------------------------------------------
# Tap trust is declared in the Brewfile itself (`trusted:`), not with `brew
# trust` calls here — see the comment at the top of that file for why the
# declarative form is the correct one for URL taps.
#
# The nebula formula hard-requires HOMEBREW_GITHUB_API_TOKEN — it pulls release
# assets from a private repo and raises without it. That token lives in
# ~/.zshenv.local, which only shells source, so read it out here or lkctl/nebula
# are the one thing a fresh bootstrap can't install.
#
# Read, not source: that file belongs to zsh, and a zsh-ism in it (path=(…),
# typeset -U, a glob qualifier) is a bash syntax error, while `set -u` makes any
# unset reference in it fatal — either would abort this whole script before a
# single package installs, and a stray `exit` in it would end the run reporting
# success. A throwaway zsh contains that, and keeps every other secret in the
# file out of brew's environment.
if [ -z "${HOMEBREW_GITHUB_API_TOKEN:-}" ] && [ -f "$HOME/.zshenv.local" ]; then
  token="$(zsh -fc '. "$HOME/.zshenv.local" >/dev/null 2>&1
                    print -rn -- "${HOMEBREW_GITHUB_API_TOKEN-}"' 2>/dev/null)" || token=""
  [ -n "$token" ] && export HOMEBREW_GITHUB_API_TOKEN="$token"
  unset token
fi
if [ -z "${HOMEBREW_GITHUB_API_TOKEN:-}" ]; then
  echo "warn: HOMEBREW_GITHUB_API_TOKEN unset — livekit/{lkctl,nebula} will fail."
  echo "      Step 4 creates ~/.zshenv.local; put the token there (needs \`repo\`"
  echo "      scope) and re-run ./bootstrap.sh."
fi

# Don't let one failing entry abort the rest — everything else still installs and
# a re-run picks up the remainder. On a fresh machine the expected failure is
# livekit/{lkctl,nebula} for want of the token above.
echo "==> brew bundle…"
if ! brew bundle --file="$DOTFILES/Brewfile" --no-upgrade; then
  echo "warn: brew bundle had failures — most likely livekit/{lkctl,nebula}"
  echo "      without HOMEBREW_GITHUB_API_TOKEN. Fix, then re-run:"
  echo "      brew bundle --file=$DOTFILES/Brewfile"
fi

# --- 4. Symlinks (+ seeded identity/secret files, git hooks) ---------------
"$DOTFILES/install.sh"

# --- 5. Node LTS via fnm ---------------------------------------------------
# fnm alone ships no node; install one or node/npm stay command-not-found.
if command -v fnm >/dev/null 2>&1; then
  if [[ -z "$(fnm ls 2>/dev/null | grep -v 'system$')" ]]; then
    echo "==> fnm: installing Node LTS…"
    fnm install --lts
    fnm default lts-latest
  fi
  eval "$(fnm env)"   # node/npm for any later step in THIS script
fi

# --- 6. cargo tools --------------------------------------------------------
# The `tree-sitter` brew formula ships only the C library (libtree-sitter,
# headers, pkgconfig) — no binary. nvim-treesitter's main branch shells out to
# the `tree-sitter` CLI, so build it from crates.io. --locked builds against the
# crate's own Cargo.lock instead of resolving fresh deps. ~/.cargo/bin is already
# on PATH via .config/zsh/.zprofile; prepend it here for the current script.
if command -v cargo >/dev/null 2>&1; then
  export PATH="$HOME/.cargo/bin:$PATH"
  if ! command -v tree-sitter >/dev/null 2>&1; then
    echo "==> cargo: installing tree-sitter-cli (compiles; takes a few minutes)…"
    cargo install --locked tree-sitter-cli \
      || echo "warn: tree-sitter-cli install failed — :TSInstall will not work"
  fi
else
  echo "warn: cargo not found — skipping tree-sitter-cli (is brew rust installed?)"
fi

# --- 7. Login shell --------------------------------------------------------
# The Brewfile installs a newer zsh than the one macOS ships, but installing it
# doesn't make it your shell: every terminal launches $SHELL, which stays
# /bin/zsh until chsh says otherwise. chpass(1) only accepts shells listed in
# /etc/shells, so the brew path has to be registered there first. Both steps
# need root and will prompt for your password; skipped non-interactively.
BREW_ZSH="$(brew --prefix)/bin/zsh"
if [[ -x "$BREW_ZSH" ]]; then
  if ! grep -qxF "$BREW_ZSH" /etc/shells; then
    echo "==> registering $BREW_ZSH in /etc/shells (needs sudo)…"
    if [[ -t 0 ]]; then
      echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null \
        || echo "warn: could not write /etc/shells — login shell left as $SHELL"
    else
      echo "warn: not a tty; run manually: echo '$BREW_ZSH' | sudo tee -a /etc/shells"
    fi
  fi
  current_shell="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
  if [[ "$current_shell" != "$BREW_ZSH" ]] && grep -qxF "$BREW_ZSH" /etc/shells; then
    echo "==> setting login shell to $BREW_ZSH…"
    chsh -s "$BREW_ZSH" || echo "warn: chsh failed — run it by hand"
  fi
fi

# --- 8. Neovim nightly -----------------------------------------------------
# init.lua targets 0.12+ (vim.pack, treesitter main). The nightly lands in
# ~/.local/bin, ahead of any brew-installed stable nvim on PATH.
if [[ ! -x "$HOME/.local/bin/nvim" ]]; then
  echo "==> installing Neovim nightly…"
  "$DOTFILES/.config/nvim/scripts/install-nvim-nightly.sh" nightly \
    || echo "warn: nvim nightly install failed — brew's stable nvim (if any) is the fallback"
fi

echo ""
echo "Done. Next steps:"
echo "  exec zsh -l                         # new shell: starship, PATH, plugins"
echo "  claude login                        # one-time Claude Code auth"
echo "  make macos                          # optional: macOS defaults (key repeat, Finder…)"
echo "  open -a Hammerspoon                 # then grant Accessibility for window hotkeys"
echo "  make -C .config/nvim servers        # optional: LSP servers (gopls, ruff, …)"
