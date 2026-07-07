# ~/.config/zsh/.zshenv — sourced for every shell (via the ~/.zshenv bootstrap).
# Keep this limited to environment: vars, PATH, and framework flags. No output
# and no interactive-only settings (those belong in .zshrc).

# Improves performance on Debian-based distros (skips the global compinit).
skip_global_compinit=1

# ---- zunder-zsh framework flags ----
DISABLE_AUTOSUGGESTIONS=false
DISABLE_EXA=false
# Allowed values: "none", "fast-syntax-highlighting"
SYNTAX_HIGHLIGHTING_PROVIDER="fast-syntax-highlighting"
ZSH_AUTOSUGGEST_STRATEGY=(history)

# ---- Toolchain env ----
export GOPATH="$HOME"
export BUNPATH="$HOME/.bun"
export CPPFLAGS="-I/usr/local/opt/openjdk/include"

# ---- PATH ----
# `typeset -U` keeps entries unique; the array form is order-preserving and far
# easier to read than repeated `export PATH=$PATH:...` lines. Intel mac: Homebrew
# lives in /usr/local/bin, which is already on the default PATH.
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
