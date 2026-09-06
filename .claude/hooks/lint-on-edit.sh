#!/bin/sh
# lint-on-edit — PostToolUse hook on Edit|Write|MultiEdit. Lints the ONE file
# Claude just wrote and, if it has problems, feeds the linter output straight
# back as additionalContext so the same turn can fix it — instead of leaving a
# lint nit (shellcheck, stylua, gofmt) for the next session to find.
#
# Informational, never blocking: it does not set decision:block, so it can
# annoy but never trap. Dependency-tolerant — every linter is behind a
# command -v, so a machine without shellcheck/stylua/ruff simply skips that
# language rather than erroring. Fast: one file, one tool, no project build.
set -u

f=$(jq -r '.tool_input.file_path // empty')
[ -n "$f" ] && [ -f "$f" ] || exit 0

have() { command -v "$1" >/dev/null 2>&1; }
out=''

# Run shellcheck into $out (gcc format is one finding per line, terse).
lint_shell() { have shellcheck || return 0; d=$(shellcheck -x -f gcc "$f" 2>&1) || out="shellcheck:
$d"; }

# Prose red flags for docs, mirroring the simple-english skill's own self-check
# so its "please self-check" request becomes a guarantee on every doc write.
# ADVISORY only — a grep cannot tell prose from a quoted error, so it is a nudge,
# not a verdict. Fenced code blocks are blanked first (kept as empty lines so the
# reported line numbers still match the file), because a code example legitimately
# holds semicolons and "has been".
#
# DELIBERATELY NOT flagged: the em-dash and the ", <verb>ing" continuation. The
# skill bans em-dashes in documents, but this repo's own prose uses them on
# nearly every line by choice, so enforcing that turns the hook into noise you
# would just disable. Kept to the high-signal patterns that stay silent on this
# repo's real docs (README, AGENTS.md, .claude/README) and still catch slop.
# To enforce the skill strictly, add -e '—' back.
lint_prose() {
    prose=$(awk 'BEGIN{f=0} /^[[:space:]]*```/{f=!f; print ""; next} {print (f?"":$0)}' "$f")
    d=$(printf '%s\n' "$prose" | grep -nE \
        -e '(^|[^A-Za-z])(has|have|had) been([^A-Za-z]|$)' \
        -e '([Ss]eamless|[Ee]ffortless|[Ll]everage|[Cc]rucial|[Ii]n order to|[Ii]t is worth noting|game.?chang|cutting.edge|best.in.class)')
    [ -n "$d" ] && out="simple-english (advisory — prose red flags; ignore any inside quoted errors or examples):
$d"
}

ext=${f##*/}; case $ext in *.*) ext=${ext##*.} ;; *) ext='' ;; esac

case $ext in
    lua)
        if have stylua; then d=$(stylua --check "$f" 2>&1) || out="stylua (not formatted):
$d"; fi
        if [ -z "$out" ] && have luacheck; then d=$(luacheck --no-color --codes "$f" 2>&1) || out="luacheck:
$d"; fi ;;
    go)
        if have gofmt; then d=$(gofmt -d "$f" 2>&1); [ -n "$d" ] && out="gofmt -d (needs formatting):
$d"; fi ;;
    json)
        have jq && { d=$(jq empty "$f" 2>&1) || out="invalid JSON:
$d"; } ;;
    py)
        have ruff && { d=$(ruff check "$f" 2>&1) || out="ruff:
$d"; } ;;
    sh|bash)
        lint_shell ;;
    md|mdx|markdown)
        lint_prose ;;
    '')
        # Extensionless: shell only if the shebang says so — covers the repo's
        # own tmux-snapshot / tmux-agent-state and the hook scripts.
        IFS= read -r shebang < "$f" 2>/dev/null || shebang=''
        case $shebang in '#!'*sh*) lint_shell ;; esac ;;
esac

[ -n "$out" ] || exit 0
jq -n --arg c "lint-on-edit found issues in ${f##*/}:
$out" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
exit 0
