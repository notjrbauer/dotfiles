# ~/.config/zsh/.zprofile — login-shell PATH setup.
#
# WHY THIS FILE EXISTS: macOS's /etc/zprofile runs `eval $(path_helper -s)`,
# which REBUILDS $PATH from scratch (from /etc/paths + /etc/paths.d) every login.
# /etc/zprofile is sourced AFTER ~/.zshenv, so any `path=(...)` set in .zshenv is
# silently clobbered on real login shells (cargo/go/openjdk vanish from PATH).
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
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$GOPATH/bin"
  $path
)

# rustup is keg-only (it conflicts with the `rust` formula), so its shims —
# cargo, rustc, rust-analyzer, clippy-driver — are NOT symlinked into
# $HOMEBREW_PREFIX/bin and nothing else puts them on PATH. The formula also no
# longer ships rustup-init, so ~/.cargo/bin holds `cargo install` output only,
# never shims. APPENDED, not prepended: brew's `rust` keeps serving cargo/rustc
# (it's what builds tree-sitter-cli in bootstrap.sh), and rustup fills the gaps
# brew's rust has no binary for — chiefly rust-analyzer, which nvim's LSP config
# resolves from PATH after `make -C .config/nvim servers`.
[[ -n "$HOMEBREW_PREFIX" && -d "$HOMEBREW_PREFIX/opt/rustup/bin" ]] \
  && path+=("$HOMEBREW_PREFIX/opt/rustup/bin")
