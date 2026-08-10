# ~/.zshrc – Clean and Fast ZSH Config (Autosuggest + Highlight optimized)

# ================================
# 🧠 Config Paths
# ================================
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
ZAP_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/zap"
ZCOMPDUMP_PATH="$CACHE_DIR/.zcompdump"

# ================================
# ⚙️  Early Bootstrapping
# ================================
[[ ! -d "$CACHE_DIR" ]] && mkdir -p "$CACHE_DIR"
[[ ! -d "$ZAP_DIR" ]] && git clone https://github.com/zap-zsh/zap.git --depth=1 "$ZAP_DIR"
[[ -f "$ZAP_DIR/zap.zsh" ]] && source "$ZAP_DIR/zap.zsh"
# Fallback stub if zap didn't load (e.g. offline on a fresh machine) so the
# rest of this file degrades gracefully instead of erroring on every `plug`.
(( $+functions[plug] )) || plug() { :; }

# ================================
# 🔌 Plugin System
# ================================
plug romkatv/zsh-defer
# zsh-defer comes from the plug above; if it didn't load, run eagerly instead.
(( $+functions[zsh-defer] )) || zsh-defer() { "$@" }

# Deferred plugin loader: git-clone into zap's plugin dir if missing, then
# source with zsh-defer for instant-prompt startup. (Inlined from zunder-zsh.)
plug-defer() {
  [[ -n "$ZAP_PLUGIN_DIR" ]] || return 0   # zap absent — don't clone into /
  local repo="$1" dir="$ZAP_PLUGIN_DIR/${1:t}"
  [[ -d "$dir" ]] || git clone -q --depth 1 "https://github.com/$repo.git" "$dir"
  local files=("$dir"/*.plugin.zsh(N) "$dir"/*.zsh(N))
  (( $#files )) && zsh-defer source "$files[1]"
}

# ================================
# 🧠 Prompt + Visuals (Load last)
# ================================
# Load autosuggestions + syntax highlighting early
plug-defer zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

plug-defer zdharma-continuum/fast-syntax-highlighting

# Prompt is starship, initialized at the end of this file.

# ================================
# 🧩 Platform Tweaks
# ================================
# On a bare Linux console, skip eza's icons (they render as tofu).
[[ "$TERM" == "linux" ]] && DISABLE_EXA=true

# ================================
# ⚡ Environment + Tools
# ================================
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd j)"
fi
[[ -n "$commands[fzf]" ]] && eval "$(fzf --zsh)"

# fzf theme — catppuccin mocha to match the terminal. No `bg` is set (and
# gutter is -1) so WezTerm's transparent background shows through.
export FZF_DEFAULT_OPTS="
  --color=fg:#cdd6f4,fg+:#cdd6f4,bg+:#313244,hl:#f38ba8,hl+:#f38ba8
  --color=info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc,marker:#a6e3a1
  --color=spinner:#f5e0dc,header:#94e2d5,border:#585b70,gutter:-1
"

export BAT_COLOR="ansi"
export FZF_PREVIEW_COMMAND="COLORTERM=truecolor bat --style=numbers --color=always {}"
export FZF_CTRL_T_OPTS="--walker-skip .git,node_modules,target --preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_CTRL_R_OPTS="--bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard'"

# ================================
# ✅ Completions
# ================================
# Extra completion dirs must be on $fpath BEFORE compinit or they won't load.
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

# Run the full fpath security check at most once a day; otherwise skip it with
# -C (the slowest part of compinit). (#qN.mh+24) = dump older than 24h or absent.
setopt EXTENDED_GLOB           # ^, ~, # glob operators — needed here for (#q…) below
autoload -Uz compinit
if [[ ! -f "$ZCOMPDUMP_PATH" || -n $ZCOMPDUMP_PATH(#qN.mh+24) ]]; then
  compinit -d "$ZCOMPDUMP_PATH"
else
  compinit -C -d "$ZCOMPDUMP_PATH"
fi
[[ "$ZCOMPDUMP_PATH.zwc" -nt "$ZCOMPDUMP_PATH" ]] || zsh-defer zcompile "$ZCOMPDUMP_PATH"

zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' use-cache true
zstyle ':completion:*' cache-path "$CACHE_DIR/.zcompcache"
zstyle ':completion:*' rehash true
zstyle ':completion:*:*:*:*:*' menu select
[[ -n $LS_COLORS ]] && zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
WORDCHARS='_-'

# ================================
# ⌨️ Keybindings
# ================================
autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -v
export KEYTIMEOUT=20   # 200ms — snappier `jj`→cmd-mode without breaking multi-key seqs
bindkey -M viins 'jj' vi-cmd-mode

# Prefix + ↑/↓ (and k/j in cmd mode) searches history for matching commands.
# (These widgets were autoloaded above but previously never bound.)
bindkey -M viins "$terminfo[kcuu1]" up-line-or-beginning-search    # ↑
bindkey -M viins "$terminfo[kcud1]" down-line-or-beginning-search  # ↓
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

# ================================
# 🧠 History
# ================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000   # was 10000 — matched to HISTSIZE so history isn't silently truncated on save
# (dropped inc_append_history — share_history already implies incremental append)
setopt share_history extended_history \
       hist_ignore_all_dups hist_ignore_space hist_reduce_blanks hist_verify \
       hist_find_no_dups hist_save_no_dups

# ================================
# ⚙️  Shell Options
# ================================
setopt AUTO_CD                 # bare `foo/` behaves like `cd foo/`
setopt AUTO_PUSHD              # every cd pushes onto the dir stack
setopt PUSHD_IGNORE_DUPS       # no duplicate stack entries
setopt PUSHD_SILENT            # don't dump the stack on pushd/popd
# (EXTENDED_GLOB is set earlier, in the Completions section)
setopt INTERACTIVE_COMMENTS    # allow `# comments` at the prompt
setopt NO_FLOW_CONTROL         # free ^S / ^Q (matters for fzf + history search)
setopt NO_BEEP

# ================================
# 📁 Aliases
# ================================
if [[ "$(uname)" = "Darwin" ]]; then
  alias ls="ls -Ga"
else
  alias ls="ls --color=auto -a"
fi

alias grep="grep --color=auto"
[[ -n "$commands[tree]" ]] && alias lt="tree"

alias la="ls -A"
alias ll="ls -l"
alias lla="ls -lA"
command -v nvim &>/dev/null && alias vim="nvim"

if [[ "$DISABLE_EXA" != true && (-n "$commands[eza]" || -n "$commands[exa]") ]]; then
  [[ -n "$commands[eza]" && -z "$commands[exa]" ]] && alias exa="eza"
  alias ls="exa --icons --group-directories-first -a"
  alias ll="exa --icons --group-directories-first --git -l"
  alias la="exa --icons --group-directories-first -a"
  alias lla="exa --icons --group-directories-first --git -la"
  alias lt="exa --icons -T"
fi

alias rm="rm -v"
alias cp="cp -vi"
alias mv="mv -vi"

if command -v bat &>/dev/null; then
  alias cat="bat"
fi

# git muscle-memory shortcuts (heavier git aliases live in .gitconfig)
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --oneline -20'

# dir-stack navigation (pairs with AUTO_PUSHD): `d` lists, 1-9 jump
alias d='dirs -v'
for i in {1..9}; do alias "$i"="cd +$i"; done

# small utilities
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }   # make a dir and enter it
# Fresh-context review worktree: gwr [ref] adds a detached ../<repo>-review and
# enters it (a separate cwd keys a separate Claude session); gwrx removes it.
gwr() { local r; r=$(git rev-parse --show-toplevel) && git worktree add --detach "$r-review" "${1:-HEAD}" && cd "$r-review"; }
gwrx() { local w; w=$(git rev-parse --show-toplevel) && [[ "$w" == *-review ]] || { echo "gwrx: not in a -review worktree" >&2; return 1; }; cd "${w%-review}" && git worktree remove "$w"; }
alias reload='exec zsh'                        # reload the shell
alias path='print -l -- $path'                 # one PATH entry per line

# ================================
# 🪟 Title / Misc
# ================================
if [[ $TERM != "xterm-kitty" ]]; then
  case "$TERM" in
    cygwin | xterm* | putty* | rxvt* | konsole* | ansi | mlterm* | alacritty | st* | foot* | contour*)
      set_window_title() {
        print -Pn "\e]2;${USER}@${HOST}:${PWD/$HOME/~}\a"
      }
      autoload -Uz add-zsh-hook
      add-zsh-hook precmd set_window_title
      ;;
  esac
fi

zle_highlight+=(paste:none)

# Ghostty backdrop reshuffle — wezterm parity (utils/backdrops.lua :random()
# runs at every startup). Ghostty reads ~/.cache/ghostty/backdrop-image only at
# launch/reload, so each Ghostty shell re-rolls the pick for the NEXT launch
# (or apply now with cmd+shift+,). Guarded to Ghostty shells; runs in ms.
[[ $TERM_PROGRAM == ghostty ]] && ~/.config/ghostty/backdrop >/dev/null 2>&1

# fnm (Node version manager) — guarded so a machine without fnm still loads.
command -v fnm &>/dev/null && eval "$(fnm env --use-on-cd --shell zsh)"

# direnv — per-directory env vars (.envrc). Guarded; no-op if not installed.
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# Prompt — load last so nothing overrides it. Guarded so a missing starship
# doesn't leave you with a broken prompt / startup error.
command -v starship &>/dev/null && eval "$(starship init zsh)"
