#!/bin/sh
# tmux-record-pane — PostToolUse hook on Bash. Remembers every %N pane id a
# tmux create command printed via -P -F '#{pane_id}', per Claude session, so
# tmux-guard can tell "a pane you made" from "the user's pane" on send-keys.
set -u
in=$(cat)
cmd=$(printf '%s' "$in" | jq -r '.tool_input.command // empty')
case $cmd in *tmux*-P*) ;; *) exit 0 ;; esac
sid=$(printf '%s' "$in" | jq -r '.session_id // empty')
[ -n "$sid" ] || exit 0
d="${XDG_CACHE_HOME:-$HOME/.cache}/agent-panes"
mkdir -p "$d"
printf '%s' "$in" | jq -r '(.tool_response.stdout // .tool_response // "") | tostring' \
    | grep -oE '%[0-9]+' >> "$d/$sid"
exit 0
