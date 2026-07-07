# ~/.config/zsh/.zshenv — sourced for every shell (via the ~/.zshenv bootstrap).
# Keep this limited to environment: vars, PATH, and framework flags. No output
# and no interactive-only settings (those belong in .zshrc).

# Improves performance on Debian-based distros (skips the global compinit).
skip_global_compinit=1

# ---- shell flags ----
DISABLE_EXA=false                    # set true to fall back from eza to plain ls
ZSH_AUTOSUGGEST_STRATEGY=(history)   # read by zsh-autosuggestions

# ---- Toolchain env ----
export GOPATH="$HOME"
export BUNPATH="$HOME/.bun"
# Only leak the openjdk include path into builds where it actually exists.
[ -d /usr/local/opt/openjdk/include ] && export CPPFLAGS="-I/usr/local/opt/openjdk/include"

# ---- PATH ----
# PATH additions live in .zprofile, NOT here. macOS's /etc/zprofile runs
# `path_helper` AFTER .zshenv and rebuilds $PATH from /etc/paths, which would
# clobber anything set here on login shells. See $ZDOTDIR/.zprofile.
# (Homebrew's /usr/local/bin is on the default PATH via /etc/paths already.)
