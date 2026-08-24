#!/bin/sh
# tmux-guard — PreToolUse hook on Bash. Enforces the three tmux traps that
# ~/.claude/CLAUDE.md and the tmux-panes skill can only ask for:
#
#   1. new-session / new-window / split-window need -d, or they steal focus
#      from whatever the user is looking at.
#   2. capture-pane needs -p, or the dump lands on the paste-buffer stack and
#      the user's next paste inserts a screen scrape.
#   3. send-keys goes only to a pane this session created — tmux-record-pane
#      (PostToolUse) records every pane id a `-P -F '#{pane_id}'` printed.
#
# A prompt is a request; a hook is a guarantee. Denied calls come back to the
# model with the reason, so it can redo them properly.
set -u

in=$(cat)
cmd=$(printf '%s' "$in" | jq -r '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0
case $cmd in *tmux*) ;; *) exit 0 ;; esac
sid=$(printf '%s' "$in" | jq -r '.session_id // empty')
panes="${XDG_CACHE_HOME:-$HOME/.cache}/agent-panes/$sid"

deny() {
    jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
    exit 0
}

# One subcommand per line: rules must hold for each part of a pipeline. Only a
# subcommand whose command word IS tmux (bare, by path, or behind env/command)
# is checked — not any text that mentions tmux, so quoting a tmux command inside
# another program's argument is not a false positive. `sh -c '…'` wrappers are
# left to the permission classifier.
printf '%s\n' "$cmd" | sed -E 's/(&&|\|\||;|\|)/\n/g' | while IFS= read -r c; do
    c=$(printf '%s' "$c" | sed -E 's/^[[:space:]]*//; s/^(command[[:space:]]+|env([[:space:]]+[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*)*[[:space:]]+)*//; s#^[^[:space:]]*/tmux([[:space:]]|$)#tmux\1#')
    case $c in tmux\ *|tmux) ;; *) continue ;; esac
    case $c in
        *new-session*|*new-window*|*split-window*|*tmux\ new\ *|*tmux\ neww\ *|*tmux\ splitw\ *|*tmux\ new-s\ *|*tmux\ new-w\ *|*tmux\ split\ *)
            printf '%s' "$c" | grep -qE -- '(^|[[:space:]])-[A-Za-z]*d' \
                || deny "tmux: creating a session/window/pane without -d steals the user's focus — add -d" ;;
    esac
    case $c in
        *capture-pane*|*tmux\ capturep\ *|*tmux\ capture\ *)
            printf '%s' "$c" | grep -qE -- '(^|[[:space:]])-[A-Za-z]*p' \
                || deny "tmux: capture-pane without -p clobbers the user's paste buffer — add -p" ;;
    esac
    case $c in
        *send-keys*|*tmux\ send\ *)
            t=$(printf '%s' "$c" | grep -oE -- '-t[[:space:]]*[^[:space:]]+' | head -1 | sed -E 's/^-t[[:space:]]*//; s/^["'"'"']//; s/["'"'"']$//')
            [ -n "$t" ] || deny "tmux: send-keys with no -t targets the user's active pane — target a pane id you created"
            case $t in
                %*) grep -qxF "$t" "$panes" 2>/dev/null \
                        || deny "tmux: send-keys into $t — not a pane this session created (use -P -F '#{pane_id}' when creating it)" ;;
                *)  deny "tmux: send-keys target '$t' is not a %N pane id — indices shift with base-index; use the id you created" ;;
            esac ;;
    esac
done
exit 0
