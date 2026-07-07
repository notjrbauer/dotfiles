# ~/.config/zsh/.zprofile — login-shell PATH setup.
#
# WHY THIS FILE EXISTS: macOS's /etc/zprofile runs `eval $(path_helper -s)`,
# which REBUILDS $PATH from scratch (from /etc/paths + /etc/paths.d) every login.
# /etc/zprofile is sourced AFTER ~/.zshenv, so any `path=(...)` set in .zshenv is
# silently clobbered on real login shells (cargo/bun/openjdk vanish from PATH).
#
# .zprofile is read from $ZDOTDIR and runs AFTER /etc/zprofile, so PATH additions
# made here survive path_helper. On macOS every terminal starts a login shell, so
# this covers all interactive sessions; non-login child shells inherit $PATH from
# their parent. (Tradeoff vs. putting this in .zshrc: .zprofile also covers
# non-interactive login shells like `zsh -lc`, and keeps PATH out of the rc file.)
#
# GOPATH / BUNPATH are exported in .zshenv (runs earlier), so they're set here.

typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.opencode/bin"
  "$BUNPATH/bin"
  "$GOPATH/bin"
  /usr/local/opt/openjdk/bin
  $path
)

# Rust env (guarded so machines without Rust don't error out).
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
