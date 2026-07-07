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
export DOCKER_HOST="unix:///var/run/docker.sock"
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd j)"
fi
[[ -n "$commands[fzf]" ]] && eval "$(fzf --zsh)"

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
SAVEHIST=10000
setopt share_history

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
fpath=(/Users/johnbauer/.docker/completions $fpath)

