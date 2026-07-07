# ~/.zshrc – Clean and Fast ZSH Config (Autosuggest + Highlight optimized)

# ================================
# 🧠 Config Paths
# ================================
ZUNDER_ZSH_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zunder-zsh"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
ZAP_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/zap"
ZCOMPDUMP_PATH="$CACHE_DIR/.zcompdump"

# ================================
# ⚙️  Early Bootstrapping
# ================================
[[ ! -d "$CACHE_DIR" ]] && mkdir -p "$CACHE_DIR"
[[ ! -d "$ZAP_DIR" ]] && git clone https://github.com/zap-zsh/zap.git --depth=1 "$ZAP_DIR"
[[ -f "$ZAP_DIR/zap.zsh" ]] && source "$ZAP_DIR/zap.zsh"

# ================================
# 🔌 Plugin System
# ================================
plug romkatv/zsh-defer
autoload plug-defer
fpath+=("$ZUNDER_ZSH_DIR/functions")

# ================================
# 🧠 Prompt + Visuals (Load last)
# ================================
# Load autosuggestions + syntax highlighting early
plug-defer zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

plug-defer zdharma-continuum/fast-syntax-highlighting

# Load your prompt last
plug spaceship-prompt/spaceship-prompt

# ================================
# 🧩 Platform Tweaks
# ================================
[[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]] && SYNTAX_HIGHLIGHTING_PROVIDER="none"

if [[ "$TERM" == "linux" ]]; then
  DISABLE_AUTOSUGGESTIONS=true
  DISABLE_EXA=true
fi

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
# 🔄 Startup Hooks
# ================================
[[ -f "$ZUNDER_ZSH_DIR/before.zsh" ]] && source "$ZUNDER_ZSH_DIR/before.zsh"
[[ -f "$ZUNDER_ZSH_DIR/after.zsh" ]]  && source "$ZUNDER_ZSH_DIR/after.zsh"

# ================================
# ✅ Completions
# ================================
autoload -Uz compinit && compinit -d "$ZCOMPDUMP_PATH"
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
bindkey -M viins 'jj' vi-cmd-mode

# ================================
# 🧠 History
# ================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000   # was 10000 — matched to HISTSIZE so history isn't silently truncated on save
setopt share_history inc_append_history extended_history \
       hist_ignore_all_dups hist_ignore_space hist_reduce_blanks hist_verify

# ================================
# 📁 Aliases
# ================================
if [[ "$(uname)" = "Darwin" ]]; then
  alias ls="ls -G"
else
  alias ls="ls --color=auto"
fi

alias grep="grep --color=auto"
[[ -n "$commands[tree]" ]] && alias lt="tree"

alias la="ls -A"
alias ll="ls -l"
alias lla="ls -lA"
alias vim="nvim"

if [[ "$DISABLE_EXA" != true && (-n "$commands[eza]" || -n "$commands[exa]") ]]; then
  [[ -n "$commands[eza]" && -z "$commands[exa]" ]] && alias exa="eza"
  alias ls="exa --icons --group-directories-first"
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

# Docker CLI completions
fpath=("$HOME/.docker/completions" $fpath)

# fnm (Node version manager) — PATH entries for opencode/etc. live in .zshenv
eval "$(fnm env --use-on-cd --shell zsh)"
