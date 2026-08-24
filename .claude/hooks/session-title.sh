#!/bin/sh
# session-title — SessionStart hook. Names a new session <repo>@<branch>
# unless it already has a name (a /rename, or --name), so `claude -r
# dotfiles@main` works, `claude agents --json` shows a real name, and the
# statusline's session_name is populated. terminalTitleFromRename is false in
# settings.json on purpose: the tmux pane border keeps Claude's live task
# title, which is the whole point of pane-border-status. Same root logic as
# `ta`: --git-common-dir, so a linked worktree still names the main repo.
set -u
in=$(cat)
case $(printf '%s' "$in" | jq -r '.source // ""') in startup|resume|fork) ;; *) exit 0 ;; esac
[ -z "$(printf '%s' "$in" | jq -r '.session_title // ""')" ] || exit 0
cwd=$(printf '%s' "$in" | jq -r '.cwd // ""')
[ -d "$cwd" ] || exit 0
common=$(git -C "$cwd" rev-parse --git-common-dir 2>/dev/null) || exit 0
case $common in /*) ;; *) common="$cwd/$common" ;; esac
repo=$(basename "$(dirname "$common")")
branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
jq -nc --arg t "$repo@${branch:-detached}" \
    '{hookSpecificOutput:{hookEventName:"SessionStart",sessionTitle:$t}}'
