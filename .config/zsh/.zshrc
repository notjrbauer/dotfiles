# ~/.config/zsh/.zshrc — interactive shell: plugins, completion, keys, aliases.
# Environment and PATH live in .zshenv / .zprofile alongside this file.

# ================================
# 🧠 Config Paths
# ================================
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
ZCOMPDUMP_PATH="$CACHE_DIR/.zcompdump"

# ================================
# ⚙️  Early Bootstrapping
# ================================
[[ ! -d "$CACHE_DIR" ]] && mkdir -p "$CACHE_DIR"

# `_evalcache` (init-output cache for fzf/zoxide/starship) lives in .zshenv so
# .zprofile can use it for brew shellenv too.
#
# No plugin manager. Exactly two plugins, at the very end of this file — the
# two things zsh cannot do itself: syntax colouring and ghost-text
# suggestions. Everything else is zsh, the tools' own init scripts, and
# completion files.

# ================================
# 🧩 Platform Tweaks
# ================================
# On a bare Linux console, skip eza's icons (they render as tofu).
[[ "$TERM" == "linux" ]] && DISABLE_EXA=true

# ================================
# ⚡ Environment + Tools
# ================================
# fzf theme — catppuccin mocha to match the terminal. No `bg` is set (and
# gutter is -1) so WezTerm's transparent background shows through.
export FZF_DEFAULT_OPTS="
  --color=fg:#cdd6f4,fg+:#cdd6f4,bg+:#313244,hl:#f38ba8,hl+:#f38ba8
  --color=info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc,marker:#a6e3a1
  --color=spinner:#f5e0dc,header:#94e2d5,border:#585b70,gutter:-1
"

export FZF_CTRL_T_OPTS="--walker-skip .git,node_modules,target --preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_CTRL_R_OPTS="--bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard'"

# ================================
# ✅ Completions
# ================================
# Extra completion dirs must be on $fpath BEFORE compinit or they won't load.
# ~/.local/share/zsh/site-functions holds completions no package ships in a
# usable form — _cargo (rustup), _uv, _golang (zsh's own _go completes gccgo,
# not go). bootstrap.sh writes them; the dir-mtime probe below sees new ones.
fpath=("${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"(N) $fpath)
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
# is silently always true. Only (#q…) forces globbing there. It is LOCAL to the
# probe: set globally it makes `^` a glob operator at the prompt, and
# `git show HEAD^` fails with "no matches found: HEAD^".
autoload -Uz compinit
if () { setopt localoptions extendedglob; local REPLY
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
# Compiled dump loads in 4ms vs 10ms for the text one. Recompiled inline only
# when stale — a few ms, on the shells right after a compinit rebuild.
[[ "$ZCOMPDUMP_PATH.zwc" -nt "$ZCOMPDUMP_PATH" ]] || zcompile "$ZCOMPDUMP_PATH"

zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' use-cache true
zstyle ':completion:*' cache-path "$CACHE_DIR/.zcompcache"
zstyle ':completion:*' rehash true
zstyle ':completion:*' menu select
# Empty when LS_COLORS is unset (eza does not set it) — that selects zsh's own
# default colours rather than none at all.
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS:-}

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

# zoxide — AFTER compinit for the same reason gcloud is: its init ends with
# `[[ ${+functions[compdef]} -ne 0 ]] && compdef __zoxide_z_complete j`, so run
# any earlier and it silently skips the registration — `j <TAB>` does nothing.
if (( $+commands[zoxide] )); then
  _evalcache zoxide zoxide init zsh --cmd j
fi

# ================================
# ⌨️ Keybindings
# ================================
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey -v
# KEYTIMEOUT is in hundredths: 200ms is the window `jj` needs to be typeable
# and short enough that a bare Esc feels instant. (The common `KEYTIMEOUT=1`
# would make `jj` impossible.) Local escape sequences arrive in <1ms.
KEYTIMEOUT=20
bindkey -M viins 'jj' vi-cmd-mode
# /etc/zshrc binds Home/End/Delete into `emacs` before `bindkey -v` relinks
# main to viins, so in viins they were undefined-key (measured). tmux sends
# ^[[1~ / ^[[4~, WezTerm ^[[H / ^[[F; terminfo covers application mode.
for _k in '^[[H' '^[OH' '^[[1~' "$terminfo[khome]"; do
  [[ -n $_k ]] && bindkey -M viins "$_k" beginning-of-line
done
for _k in '^[[F' '^[OF' '^[[4~' "$terminfo[kend]"; do
  [[ -n $_k ]] && bindkey -M viins "$_k" end-of-line
done
[[ -n $terminfo[kdch1] ]] && bindkey -M viins "$terminfo[kdch1]" delete-char
unset _k

# fzf must load AFTER `bindkey -v` and after compinit. Its ^T/^R/\ec go into
# emacs, viins and vicmd explicitly, but its completion hook is a bare
# `bindkey '^I' fzf-completion` targeting whatever `main` is at eval time —
# bound any earlier, `bindkey -v` relinks main to viins and **<TAB> is lost.
(( $+commands[fzf] )) && _evalcache fzf fzf --zsh

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
# share_history implies incremental append — inc_append_history would be redundant.
# hist_fcntl_lock: a dozen panes append to one file; lock it rather than race.
setopt share_history extended_history hist_fcntl_lock \
       hist_ignore_all_dups hist_ignore_space hist_reduce_blanks hist_verify \
       hist_find_no_dups hist_save_no_dups

# ================================
# ⚙️  Shell Options
# ================================
setopt AUTO_CD                 # bare `foo/` behaves like `cd foo/`
setopt AUTO_PUSHD              # every cd pushes onto the dir stack
setopt PUSHD_IGNORE_DUPS       # no duplicate stack entries
setopt PUSHD_SILENT            # don't dump the stack on pushd/popd
# No EXTENDED_GLOB here: it turns `^` into a glob operator and breaks `HEAD^`.
setopt INTERACTIVE_COMMENTS    # allow `# comments` at the prompt
setopt NO_FLOW_CONTROL         # free ^S / ^Q (matters for fzf + history search)
setopt NO_BEEP

# ================================
# 📁 Aliases
# ================================
if [[ $OSTYPE == darwin* ]]; then
  alias ls="ls -Ga"
else
  alias ls="ls --color=auto -a"
fi

alias grep="grep --color=auto"
(( $+commands[tree] )) && alias lt="tree"

alias la="ls -A"
alias ll="ls -l"
alias lla="ls -lA"
(( $+commands[nvim] )) && alias vim="nvim"

if [[ "$DISABLE_EXA" != true ]] && (( $+commands[eza] || $+commands[exa] )); then
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
  (( $+commands[eza] && ! $+commands[exa] )) && alias exa="eza"
fi

alias rm="rm -v"
alias cp="cp -vi"
alias mv="mv -vi"

if (( $+commands[bat] )); then
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
# Copy Claude Code's folder-trust from one path to another so a freshly made
# worktree skips the "do you trust this folder?" prompt. No-op unless the source
# is already trusted and ~/.claude.json exists. Atomic temp+mv (never corrupts
# the live config); a lost race with a running Claude just re-prompts once — the
# same bargain a friend's standalone version takes, minus its mkdir mutex, which
# only earns its keep under concurrent hooks (gwr is interactive). Also callable
# by hand for a `claude --worktree` dir: cctrust <trusted-path> <new-path>.
cctrust() {
  local cfg="$HOME/.claude.json" from=$1 to=$2 tmp
  [[ -n $from && -n $to && -f $cfg ]] || return 0
  [[ "$(jq -r --arg p "$from" '.projects[$p].hasTrustDialogAccepted // false' "$cfg" 2>/dev/null)" == true ]] || return 0
  [[ "$(jq -r --arg p "$to"   '.projects[$p].hasTrustDialogAccepted // false' "$cfg" 2>/dev/null)" == true ]] && return 0
  tmp=$(mktemp "$cfg.XXXXXX") || return 0
  if jq --arg p "$to" '.projects[$p].hasTrustDialogAccepted = true' "$cfg" >| "$tmp" 2>/dev/null && [[ -s $tmp ]]; then
    command mv -f "$tmp" "$cfg"
  else
    command rm -f "$tmp"
  fi
  return 0
}

# Fresh-context review worktree: gwr [ref] adds a detached ../<repo>-review and
# enters it (a separate cwd keys a separate Claude session); gwrx removes it.
# cctrust carries trust over so the review Claude opens without a prompt; cd runs
# regardless of whether the trust copy succeeded.
gwr() { local r; r=$(git rev-parse --show-toplevel) && git worktree add --detach "$r-review" "${1:-HEAD}" && { cctrust "$r" "$r-review"; cd "$r-review"; }; }
gwrx() { local w; w=$(git rev-parse --show-toplevel) && [[ "$w" == *-review ]] || { print -u2 "gwrx: not in a -review worktree"; return 1; }; cd "${w%-review}" && git worktree remove "$w"; }
# -l: a login shell re-runs .zprofile, which is the only file that puts brew's
# site-functions on fpath (and re-runs path_helper); a bare `exec zsh` starts a
# non-login shell and, since .zprofile un-exports FPATH, silently loses those
# completions. typeset -U keeps the re-run idempotent.
alias reload='exec zsh -l'
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
if (( $+commands[tmux] )); then

  # ta [name] — attach to session `name`, creating it if it doesn't exist. With
  # no name: the basename of the git repo's root, so `ta` from any depth inside
  # a project lands on the same session — a bare $PWD:t made .config/zsh its own
  # "zsh" session. Falls back to the current directory outside a repo, and the
  # default is only expanded when $1 is empty, so `ta foo` never runs git.
  # Already inside tmux, attach-session refuses to nest, so switch the client.
  #
  # --git-common-dir, not --show-toplevel: inside a linked worktree, toplevel is
  # the *worktree* directory, so `ta` in repo__worktrees/feature-auth opened a
  # session called "feature-auth" with the repo name gone — and a "fix-tests"
  # worktree in two different repos collided onto one session, silently
  # attaching you to the wrong agent. --git-common-dir points at the main
  # repo's .git from both a worktree and the main checkout, so its parent is
  # the repo root in either. Per-worktree sessions are Claude Code's own
  # `claude --worktree <name> --tmux=classic` (worktree under .claude/worktrees/,
  # gitignored files copied per .worktreeinclude) — the tw() that lived here
  # did the same by hand.
  ta() {
    local base=$1 root
    if [[ -z $base ]]; then
      root=$(git rev-parse --git-common-dir 2>/dev/null) &&
        base=$(cd -- "$root/.." 2>/dev/null && pwd)
      [[ -n $base ]] || base=$PWD
    fi
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
      local dead
      dead=$(tmux list-panes -s -t "=$name" -F '#{pane_dead} #{pane_id}' | awk '$1==1{print $2; exit}')
      if [[ -n $dead ]]; then
        # respawn-pane takes a PANE target, where '=' is rejected outright
        # ("can't find pane: =name") — see rule 2 above. Resolve the exact pane
        # id via the session target instead of guessing by name.
        tmux respawn-pane -k -t "$dead" "$@" && print "tsvc: restarted '$name'"
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
    if (( ! $# )); then
      # Same resolution as ta: --git-common-dir, not --show-toplevel, so a
      # linked worktree still names the MAIN repo. See ta's comment above.
      local root base
      root=$(git rev-parse --git-common-dir 2>/dev/null) &&
        base=$(cd -- "$root/.." 2>/dev/null && pwd)
      targets=("${${base:-$PWD}:t}")
    fi
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
  if (( $+commands[k9s] )); then
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
# Pane title. Inside tmux OSC 2 sets #{pane_title}, which .tmux.conf draws on
# every pane border — so a shell pane names its directory at the prompt and
# the command while one runs, the same signal Claude Code gives its own pane.
# TERM inside tmux is tmux-256color; the old xterm*-only match skipped it, and
# every shell pane showed tmux's fallback — the hostname — all day.
# kitty sets titles through its own shell integration; leave it alone.
case "$TERM" in
  xterm-kitty) ;;
  xterm* | tmux* | screen* | alacritty | foot*)
    _title() { print -rn -- $'\e]2;'"$1"$'\a' }
    _title_precmd()  { _title "${(%):-%~}" }
    _title_preexec() { _title "${1[(w)1]} · ${(%):-%~}" }   # first word of the command
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _title_precmd
    add-zsh-hook preexec _title_preexec
    ;;
esac

# zle_highlight is unset by default, so this is the whole array — but zsh
# applies its built-in defaults to every context not listed, so only paste
# changes: pasted text is no longer drawn in standout.
zle_highlight+=(paste:none)

# fnm (Node version manager) — --use-on-cd switches version per directory.
# fnm prepends a fresh per-shell multishell dir every time it runs and never
# drops the parent's, so a nested shell (tmux pane -> ta -> reload -> claude)
# accumulates one dead PATH entry per level. typeset -U cannot dedupe them —
# each is a distinct string. Strip the inherited one before adding ours.
if (( $+commands[fnm] )); then
  [[ -n $FNM_MULTISHELL_PATH ]] && path=(${path:#"$FNM_MULTISHELL_PATH/bin"})
  eval "$(fnm env --use-on-cd --shell zsh)"
  # fnm never removes the per-shell symlink it made (Schniz/fnm#1157, closed
  # won't-fix) — 1,412 dead ones here against 2 live shells. Drop ours on exit,
  # and once the prompt is up sweep the graveyard: the name starts with the pid
  # of the shell that made it, and a dead pid is a dead shell.
  _fnm_cleanup() { [[ -L $FNM_MULTISHELL_PATH ]] && command rm -f -- "$FNM_MULTISHELL_PATH" }
  _fnm_sweep() {
    local d
    for d in ${FNM_MULTISHELL_PATH:h}/*(@N); do
      kill -0 "${${d:t}%%_*}" 2>/dev/null || command rm -f -- "$d"
    done
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook zshexit _fnm_cleanup
  _fnm_sweep   # a handful of entries once the exit hook is doing its job
fi

# direnv — per-directory env vars from .envrc.
(( $+commands[direnv] )) && _evalcache direnv direnv hook zsh

# Prompt — starship.
(( $+commands[starship] )) && _evalcache starship starship init zsh

# ================================
# 🎨 The two plugins
# ================================
# Cloned once, pinned to a commit, sourced — no manager. Their dirs go on
# fpath so any completion they ship is visible (compinit has already run;
# it sees them on the next dump rebuild). Highlighting is sourced LAST: it
# wraps every zle widget, so anything bound after it is not coloured.
# ~10ms together, not deferred — deferral needed a third plugin.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1          # skip per-prompt rebinding: nothing rebinds after startup
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
_plugin() {  # _plugin owner/repo sha
  local dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins/${1:t}"
  if [[ ! -d $dir ]]; then
    git clone -q --depth 1 "https://github.com/$1" "$dir" \
      && git -C "$dir" fetch -q --depth 1 origin "$2" && git -C "$dir" checkout -q "$2" \
      || { print -u2 "zshrc: could not fetch $1"; return }
  fi
  fpath+=("$dir")
  source "$dir/${1:t}.plugin.zsh"
}
_plugin zsh-users/zsh-autosuggestions        0e810e5afa27acbd074398eefbe28d13005dbc15
_plugin zdharma-continuum/fast-syntax-highlighting cf318e06a9b7c9f2219d78f41b46fa6e06011fd9
unfunction _plugin
