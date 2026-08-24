# ~/.config/zsh/.zprofile — login-shell PATH setup.
#
# WHY THIS FILE EXISTS: macOS's /etc/zprofile runs `eval $(path_helper -s)`,
# which REBUILDS $PATH (from /etc/paths + /etc/paths.d, then whatever was
# already there, appended) every login. /etc/zprofile is sourced AFTER
# ~/.zshenv, so any `path=(...)` set in .zshenv is demoted behind /usr/local/bin
# on real login shells — cargo/go/openjdk are still on PATH, but shadowed.
#
# .zprofile is read from $ZDOTDIR and runs AFTER /etc/zprofile, so PATH additions
# made here survive path_helper. On macOS every terminal starts a login shell, so
# this covers all interactive sessions; non-login child shells inherit $PATH from
# their parent. (Tradeoff vs. putting this in .zshrc: .zprofile also covers
# non-interactive login shells like `zsh -lc`, and keeps PATH out of the rc file.)
#
# GOPATH is exported in .zshenv (runs earlier), so it's set here.

# Homebrew first: /opt/homebrew (Apple Silicon) is NOT in /etc/paths, and the
# installer's usual ~/.zprofile append never runs because ZDOTDIR points here.
# shellenv also prepends brew's zsh site-functions to fpath before compinit.
# Cached: shellenv is a 30ms ruby-free script whose output only changes with
# the brew binary — a third of this shell's startup, paid once per pane.
if [[ -x /opt/homebrew/bin/brew ]]; then
  _evalcache /opt/homebrew/bin/brew /opt/homebrew/bin/brew shellenv
elif [[ -x /usr/local/bin/brew ]]; then
  _evalcache /usr/local/bin/brew /usr/local/bin/brew shellenv
fi
# shellenv exports FPATH. Exported, a nested shell (every tmux pane, `ta`,
# `exec zsh`) inherits the parent's RUNTIME fpath — plugin dirs included — so
# compinit counted 1027 files in one shell and 1026 in another and rebuilt the
# dump (~500ms) each time the two disagreed. fpath is built by startup files,
# not inherited.
typeset +x FPATH

typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$GOPATH/bin"
  $path
)

# rustup is keg-only (it conflicts with the `rust` formula), so its shims —
# cargo, rustc, rust-analyzer, clippy-driver — are NOT symlinked into
# $HOMEBREW_PREFIX/bin and nothing else puts them on PATH. APPENDED, not
# prepended, so a `rust` formula or a ~/.cargo/bin toolchain ahead of it keeps
# serving cargo/rustc and rustup only fills gaps such as rust-analyzer, which
# nvim's LSP config resolves from PATH. (On this machine brew's `rust` is not
# installed despite the Brewfile; cargo resolves to ~/.cargo/bin.)
[[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/opt/rustup/bin" ]] \
  && path+=("$HOMEBREW_PREFIX/opt/rustup/bin")
