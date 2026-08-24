#!/bin/sh
# tmux-record-pane — PostToolUse hook on Bash. Remembers every %N pane id a
# tmux create command printed via -P -F '#{pane_id}', per Claude session, so
# tmux-guard can tell "a pane you made" from "the user's pane" on send-keys.
set -u
in=$(cat)
cmd=$(printf '%s' "$in" | jq -r '.tool_input.command // empty')
case $cmd in *tmux*-P*) ;; *) exit 0 ;; esac
sid=$(printf '%s' "$in" | jq -r '.session_id // empty')
# The id is a path component; a UUID is the only shape it ever has.
case $sid in ''|*[!0-9a-fA-F-]*) exit 0 ;; esac
d="${XDG_CACHE_HOME:-$HOME/.cache}/agent-panes"
mkdir -p "$d"
# Only the id the creation printed: the first %N on the LAST line of stdout.
# Recording every %N anywhere in the output let a command that also echoed
# the user's pane id put that pane on the allowlist.
printf '%s' "$in" | jq -r '(.tool_response.stdout // .tool_response // "") | tostring' \
    | awk 'NF { last = $0 } END { print last }' | grep -oE '%[0-9]+' | head -1 >> "$d/$sid"
exit 0
