# ~/.config/zsh/.zshrc — interactive shell: plugins, completion, keys, aliases.
# Environment and PATH live in .zshenv / .zprofile alongside this file.

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
# 🧠 Autosuggestions + syntax highlighting (deferred)
# ================================
plug-defer zsh-users/zsh-autosuggestions
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

plug-defer zdharma-continuum/fast-syntax-highlighting

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
# -C (the slowest part of compinit) — measured ~12ms vs ~3ms here. Clause 1
# catches a missing dump: (#qN.mh+24) can't, since N drops a nonexistent file.
#
# The third clause is what makes a *newly installed* completion show up today
# rather than whenever the 24h window happens to lapse: -C reuses the dump
# verbatim and never rescans $fpath, so `brew install foo` that links a new
# _foo went unnoticed for up to a day. Linking into a directory bumps that
# directory's mtime, so "any $fpath dir newer than the dump" is exactly the
# signal. ${^fpath} expands per entry; (#qN/e[…]) keeps dirs passing the test,
# and N means a missing entry is skipped instead of erroring. ~0.04ms for 5
# entries — far less than the -C it protects. Wrapped in an anonymous function
# so the $REPLY that e[…] sets stays out of the global namespace.
#
# EXTENDED_GLOB is required, not cosmetic: inside [[ … ]] a bare trailing
# (N.mh+24) is NOT expanded — it stays a literal non-empty string and the test
# is silently always true. Only (#q…) forces globbing there.
setopt EXTENDED_GLOB           # ^, ~, # glob operators — needed here for (#q…) below
autoload -Uz compinit
if () { local REPLY
        [[ ! -f "$ZCOMPDUMP_PATH" || -n $ZCOMPDUMP_PATH(#qN.mh+24) \
           || -n ${^fpath}(#qN/e['[[ $REPLY -nt $ZCOMPDUMP_PATH ]]']) ]]
      }; then
  compinit -d "$ZCOMPDUMP_PATH"
  # compinit only REWRITES the dump when the completion-file count (or the zsh
  # version) changed, so a 24h lapse — or a dir mtime bumped by an in-place
  # relink — leaves the dump's own mtime untouched. Without this stamp the test
  # above stays true on every later shell and -C is never taken again.
  touch "$ZCOMPDUMP_PATH"
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

# gcloud completion. Only the completion half: the gcloud-cli cask already
# links gcloud/gsutil/bq into $HOMEBREW_PREFIX/bin, so the SDK's path.zsh.inc
# has nothing to add. Must load AFTER compinit — the script runs its own
# compinit when compdef is missing, which would bypass the cached branch above
# (and is why this can't live in .zshenv.local, sourced from .zshenv earlier).
# Not deferred: it measures under a millisecond warm, and deferring it means
# the first Tab after login can miss it.
_gcloud_inc="${HOMEBREW_PREFIX:-/opt/homebrew}/share/google-cloud-sdk/completion.zsh.inc"
[[ -f "$_gcloud_inc" ]] && source "$_gcloud_inc"
unset _gcloud_inc

# ================================
# ⌨️ Keybindings
# ================================
autoload -U up-line-or-beginning-search
zle -N up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -v
KEYTIMEOUT=20   # 200ms — snappier `jj`→cmd-mode without breaking multi-key seqs
bindkey -M viins 'jj' vi-cmd-mode

# fzf must load AFTER `bindkey -v` and after compinit. Its ^T/^R/\ec go into
# emacs, viins and vicmd explicitly, but its completion hook is a bare
# `bindkey '^I' fzf-completion` targeting whatever `main` is at eval time —
# bound any earlier, `bindkey -v` relinks main to viins and **<TAB> is lost.
[[ -n "$commands[fzf]" ]] && eval "$(fzf --zsh)"

# Prefix + ↑/↓ (and k/j in cmd mode) searches history for matching commands.
# Bind the literal sequences, not just $terminfo: kcuu1/kcud1 are the
# APPLICATION-mode forms (^[OA/^[OB), and zsh never sends smkx, so terminals
# stay in normal mode and send ^[[A/^[[B — binding terminfo alone left the
# default up-line-or-history in place and this never fired. terminfo is still
# bound for terminals that do send application mode, guarded because it's empty
# under TERM=dumb, where bindkey would error on an empty key sequence.
bindkey -M viins '^[[A' up-line-or-beginning-search    # ↑ (normal cursor mode)
bindkey -M viins '^[[B' down-line-or-beginning-search  # ↓
[[ -n "$terminfo[kcuu1]" ]] && bindkey -M viins "$terminfo[kcuu1]" up-line-or-beginning-search
[[ -n "$terminfo[kcud1]" ]] && bindkey -M viins "$terminfo[kcud1]" down-line-or-beginning-search
bindkey -M vicmd 'k' up-line-or-beginning-search
bindkey -M vicmd 'j' down-line-or-beginning-search

# ================================
# 🧠 History
# ================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000   # matched to HISTSIZE; a smaller SAVEHIST truncates silently on save
# share_history implies incremental append — inc_append_history would be redundant
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
  # Bake the binary into the alias bodies. Writing them against `exa` and
  # relying on the shim below to re-expand worked, but made every listing
  # alias depend on zsh re-expanding an alias body — one indirection too many.
  # eza is the maintained fork; exa is archived, so prefer eza when both exist.
  _lsbin=${commands[eza]:+eza}; : ${_lsbin:=exa}
  alias ls="$_lsbin --icons --group-directories-first -a"
  alias ll="$_lsbin --icons --group-directories-first --git -l"
  alias lla="$_lsbin --icons --group-directories-first --git -la"
  alias lt="$_lsbin --icons -T"
  unset _lsbin
  # Muscle memory: `exa` at the prompt still works on an eza-only machine.
  [[ -n "$commands[eza]" && -z "$commands[exa]" ]] && alias exa="eza"
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
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }
# Fresh-context review worktree: gwr [ref] adds a detached ../<repo>-review and
# enters it (a separate cwd keys a separate Claude session); gwrx removes it.
gwr() { local r; r=$(git rev-parse --show-toplevel) && git worktree add --detach "$r-review" "${1:-HEAD}" && cd "$r-review"; }
gwrx() { local w; w=$(git rev-parse --show-toplevel) && [[ "$w" == *-review ]] || { echo "gwrx: not in a -review worktree" >&2; return 1; }; cd "${w%-review}" && git worktree remove "$w"; }
alias reload='exec zsh'
alias path='print -l -- $path'                 # one PATH entry per line

# ================================
# 🖥️  tmux
# ================================
# Two tmux target-spec rules drive everything below.
#
# 1. ':' separates session:window and '.' separates window.pane, so a session
#    named `foo.bar` is created happily and is then unreachable FOREVER —
#    `has-session -t foo.bar` fails with "can't find pane: bar", and so does
#    kill-session. Sanitize both to '_' on the way in.
# 2. A bare `-t foo` also matches an existing `foobar` (prefix match). The '='
#    prefix forces an exact match, but only on the SESSION part: `=foo` for a
#    session target, `=foo:` for a window target, and not at all for a pane
#    target (`capture-pane -t '=foo'` errors).
if command -v tmux &>/dev/null; then

  # ta [name] — attach to session `name`, creating it if it doesn't exist. With
  # no name: the basename of the git repo's root, so `ta` from any depth inside
  # a project lands on the same session — a bare $PWD:t made .config/zsh its own
  # "zsh" session. Falls back to the current directory outside a repo, and the
  # default is only expanded when $1 is empty, so `ta foo` never runs git.
  # Already inside tmux, attach-session refuses to nest, so switch the client.
  ta() {
    local base="${1:-$(git rev-parse --show-toplevel 2>/dev/null || print -r -- "$PWD")}"
    local name="${${base:t}//[.:]/_}"
    [[ -n "$name" ]] || name=tmux            # $PWD is '/', so :t came back empty
    if [[ -n "$TMUX" ]]; then
      tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name" || return
      tmux switch-client -t "=$name"
    else
      tmux new-session -A -s "$name"         # -A attaches if it exists; -s is exact
    fi
  }

  # ts — fzf picker over live sessions (inherits $FZF_DEFAULT_OPTS set above).
  # list-sessions doubles as the "is anything running?" probe: a server with zero
  # sessions cannot exist, so its only failure here is "no server" — which
  # deserves a word rather than the silent non-zero exit it used to give.
  ts() {
    local list sel
    (( $+commands[fzf] )) || { print -u2 "ts: fzf is not installed"; return 1 }
    list=$(tmux list-sessions -F $'#{session_name}\t#{session_windows} win#{?session_attached, (attached),}' 2>/dev/null) \
      || { print -u2 "ts: no tmux server running"; return 1 }
    sel=$(print -r -- "$list" | fzf --height=40% --reverse --prompt='session> ') || return
    sel="${sel%%$'\t'*}"                     # names may contain spaces; split on the tab
    [[ -n "$sel" ]] || return
    if [[ -n "$TMUX" ]]; then
      tmux switch-client -t "=$sel"
    else
      tmux attach-session -t "=$sel"
    fi
  }

  # ^S — the session picker at the prompt: what ^R is for history. A zle widget
  # rather than another tmux key, because it also works with no server running
  # (there is no prefix to press yet) and it is where your hands already are.
  # push-line stashes a half-typed command and the next prompt restores it, and
  # running `ts` as a real command rather than inside the widget is what lets
  # attach-session take the terminal when you are not in tmux yet. The leading
  # space keeps it out of history (hist_ignore_space, set above).
  # ^S is free at every layer: NO_FLOW_CONTROL released it (so the terminal's
  # XOFF never sees it), viins leaves it self-insert, the tmux prefix is C-a and
  # .tmux.conf's C-s is prefix-only. C-h/C-j/C-k/C-l are NOT free — tmux's root
  # table hands those to vim-tmux-navigator before zsh ever sees them.
  tmux-session-picker() {
    zle push-line
    BUFFER=" ts"
    zle accept-line
  }
  zle -N tmux-session-picker
  bindkey -M viins '^S' tmux-session-picker
  bindkey -M vicmd '^S' tmux-session-picker

  # tsvc <name> <command> [args…] — park a long-lived foreground command (a
  # tunnel or other connection client that must hold a terminal all day) in its
  # own detached session and return immediately. Keeps it away from editing
  # panes, so a stray C-c can't kill it, and makes it trivial to find again.
  # Args are passed as argv, not through a shell — `tsvc x foo 'a; b'` sends
  # `a; b` as one argument and never runs `b`.
  tsvc() {
    (( $# >= 2 )) || { print -u2 "usage: tsvc <name> <command> [args…]"; return 2 }
    local name="${1//[.:]/_}"; shift
    # An empty name is not a harmless no-op: tmux creates the session happily,
    # `-t '='` then fails to resolve, and `-t ''` means the CURRENT session — so
    # a later tkill would kill the wrong one.
    [[ -n "$name" ]] || { print -u2 "tsvc: empty session name"; return 2 }
    if tmux has-session -t "=$name" 2>/dev/null; then
      # remain-on-exit leaves the corpse behind, so an existing session is NOT
      # proof the command is still up — restart it in place if it died.
      # -s makes this a SESSION target: without it `-t name` is a window target,
      # which resolves to the session's *current window* only, so a dead service
      # in any other window was reported as "already running".
      if [[ "$(tmux list-panes -s -t "=$name" -F '#{pane_dead}')" == *1* ]]; then
        tmux respawn-pane -k -t "=$name" "$@" && print "tsvc: restarted '$name'"
      else
        print "tsvc: '$name' already running — attach with: ta ${(q)name}"
      fi
      return
    fi
    # remain-on-exit rides in the SAME command list on purpose: the server runs
    # a list to completion before returning to its event loop, so it is already
    # set even if the command dies instantly. Without it the pane, window and
    # session all disappear on exit and take the error message with them; with
    # it the pane stays as "Pane is dead (status N)" with its scrollback.
    tmux new-session -d -s "$name" "$@" \; set-option -w -t "=$name:" remain-on-exit on \
      && print "tsvc: '$name' started — attach with: ta ${(q)name}"
  }

  # tkill [name…] — kill sessions by EXACT name (plain `kill-session -t foo`
  # would also match `foobar`, and `-t '*'` fnmatches — lethal exactly when you
  # have a single session, since it takes the server with it). With no args it
  # resolves the same name `ta` would — the repo root's basename — so `ta` then
  # `tkill` from anywhere in a project act on one session; a bare $PWD:t made
  # them disagree on every subdirectory. git only runs when no args are given.
  # rc is 1 if ANY name failed: a loop's status is just its last iteration, so
  # `tkill gone alive` used to report success.
  tkill() {
    local s rc=0
    local -a targets=("$@")
    (( $# )) || targets=("${${$(git rev-parse --show-toplevel 2>/dev/null || print -r -- "$PWD")}:t}")
    for s in "${targets[@]}"; do
      [[ -n "$s" ]] || { print -u2 "tkill: empty session name"; rc=1; continue }
      tmux kill-session -t "=${s//[.:]/_}" || rc=1
    done
    return $rc
  }

  # k9 [context] — k9s in a session of its own, one per context, so re-attaching
  # is instant (k9s keeps its place) and a stray C-c lands in k9s rather than the
  # editor beside it. Deliberately NOT tsvc: k9s is something you quit, and
  # tsvc's remain-on-exit would leave a dead pane behind every time you did.
  # Context defaults to the current one; :t cuts an EKS arn (…:cluster/prod) down
  # to a name you can type.
  if command -v k9s &>/dev/null; then
    k9() {
      local ctx="${1:-$(kubectl config current-context 2>/dev/null)}"
      [[ -n "$ctx" ]] || { print -u2 "k9: no current kube context — pass one"; return 1 }
      local name="k9s-${${ctx:t}//[.:]/_}"
      if [[ -n "$TMUX" ]]; then
        tmux has-session -t "=$name" 2>/dev/null \
          || tmux new-session -d -s "$name" k9s --context "$ctx" || return
        tmux switch-client -t "=$name"
      else
        tmux new-session -A -s "$name" k9s --context "$ctx"
      fi
    }
  fi

  # Tab-complete live session names. compdef only exists once compinit has run
  # (above), so guard it rather than erroring on a stripped-down shell.
  if (( $+functions[compdef] )); then
    _tmux_session_names() {
      local -a names
      names=(${(f)"$(tmux list-sessions -F '#{session_name}' 2>/dev/null)"})
      compadd -a names
    }
    # tsvc's first arg is a session, everything after it is the command to run.
    _tmux_svc() {
      case $CURRENT in
        2) _tmux_session_names ;;
        3) _command_names -e ;;
        *) _default ;;
      esac
    }
    compdef _tmux_session_names ta tkill
    compdef _tmux_svc tsvc
  fi
fi

# ================================
# 🪟 Title / Misc
# ================================
if [[ $TERM != "xterm-kitty" ]]; then
  case "$TERM" in
    xterm* | alacritty | foot*)
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
# launch/reload, so this re-rolls the pick for the NEXT launch (or apply now
# with cmd+shift+,).
#
# It fires far less often than it looks: tmux sets TERM_PROGRAM=tmux in every
# pane, and ghostty's `command =` starts tmux from a NON-interactive login
# shell, which never reads this file. So the only shell that runs it is the
# one you land on after quitting tmux. Move it into ghostty's `command =` if
# you want it once per launch.
[[ $TERM_PROGRAM == ghostty ]] && ~/.config/ghostty/backdrop >/dev/null 2>&1

# fnm (Node version manager) — --use-on-cd switches version per directory.
command -v fnm &>/dev/null && eval "$(fnm env --use-on-cd --shell zsh)"

# direnv — per-directory env vars from .envrc.
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# Prompt — starship, last so nothing later overrides it.
command -v starship &>/dev/null && eval "$(starship init zsh)"
