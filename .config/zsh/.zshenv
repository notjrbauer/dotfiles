# ~/.config/zsh/.zshenv — sourced for every shell (via the ~/.zshenv bootstrap).
# Keep this limited to environment: vars, PATH, and framework flags. No output
# and no interactive-only settings (those belong in .zshrc).

# Ubuntu's /etc/zsh/zshrc runs a global compinit unless this is set (Debian
# proper does not); a no-op on macOS, kept for the Linux install.
skip_global_compinit=1

# Cache `<tool> init` output. Measured here: brew shellenv 30ms, starship 12ms,
# fzf 10ms, zoxide 8ms per shell, and each emits identical text per version.
# Stale when the cache is older than the binary OR the binary's resolved path
# changed — bottle binaries carry BUILD mtimes, which can predate a cache
# written before the upgrade, and a Cellar path carries the version. Written
# via temp file + mv so a tool that dies mid-write cannot leave a partial init
# for the next shell; falls back to a live eval if anything looks wrong. Here,
# not .zshrc, because .zprofile uses it for brew before .zshrc exists.
_evalcache() {  # _evalcache <name-or-path> <command...>
  local f="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/init-${1:t}.zsh"; shift
  local bin="${1:/[^\/]*/$commands[$1]}" first
  [[ -n $bin ]] && bin=${bin:A}
  if [[ -s $f && -n $bin && $f -nt $bin ]] && { read -r first < "$f"; [[ $first == "# $bin" ]] }; then
    source "$f"
    return
  fi
  [[ -d ${f:h} ]] || command mkdir -p -- "${f:h}"
  local t; t=$(command mktemp "$f.XXXXXX") || { eval "$("$@" 2>/dev/null)"; return }
  if { print -r -- "# $bin"; "$@" } >| "$t" 2>/dev/null && [[ -s $t ]]; then
    command mv -f "$t" "$f" && source "$f" && return
  fi
  command rm -f "$t"
  eval "$("$@" 2>/dev/null)"
}

# ---- shell flags ----
DISABLE_EXA=false                    # set true to fall back from eza to plain ls

# `brew shellenv` prepends to fpath unconditionally AND exports FPATH, so every
# nested login shell (macOS starts one per terminal; tmux nests another) added a
# duplicate — 3 copies of brew's site-functions here before this. That makes
# compinit's scan and the mtime probe in .zshrc do the same work repeatedly.
# Here rather than .zprofile: typeset -U is a sticky attribute, and .zshenv is
# the only file that also runs for non-login shells, so it covers `exec zsh`
# and brew's later fpath[1,0]= too.
typeset -U fpath FPATH

# ---- Toolchain env ----
# Deliberately $HOME, not Go's ~/go default: this predates the default and is
# why ~/bin and ~/pkg exist on this machine. Changing it strands both.
export GOPATH="$HOME"

# Editor. Here, not .zshrc: `kubectl edit`, `crontab -e` and friends often run
# from scripts or non-interactive shells, which never read the rc file.
# `nvim` on PATH is the nightly in ~/.local/bin. .gitconfig sets core.editor.
export EDITOR=nvim
export VISUAL="$EDITOR"

# ---- PATH ----
# PATH additions live in .zprofile, NOT here. macOS's /etc/zprofile runs
# `path_helper` AFTER .zshenv and rebuilds $PATH from /etc/paths, appending
# whatever was already set — so anything prepended here lands BEHIND
# /usr/local/bin on login shells and is shadowed. See $ZDOTDIR/.zprofile.
# (Homebrew is initialized there too, via `brew shellenv` — /opt/homebrew is
# not in /etc/paths on Apple Silicon.)

# ---- Machine-local env (untracked) ----
# Secrets and per-machine vars — API tokens and anything else that must not land
# in a public repo. Lives in $HOME, NOT in $ZDOTDIR: ~/.config/zsh is a symlink
# to this repo, so a file created there would be inside it. Same split as
# ~/.gitconfig.local; install.sh seeds it. Sourced last so it can override.
[ -f "$HOME/.zshenv.local" ] && source "$HOME/.zshenv.local"
