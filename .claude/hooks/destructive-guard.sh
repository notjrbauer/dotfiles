#!/bin/sh
# destructive-guard — PreToolUse hook on Bash. Turns the "Stop and ask" section
# of ~/.claude/CLAUDE.md ("never force-push or rewrite history without a
# specific go-ahead", "destructive… Re-ask") from prose into an actual gate.
#
# It does NOT hard-deny — it returns permissionDecision "ask", so an irreversible
# command surfaces as a permission prompt you answer in the moment. That IS the
# "specific go-ahead": approve and it runs, decline and it does not. A plain
# settings.json permission pattern can't express these rules — they turn on a
# flag/target distinction (--force vs --force-with-lease, `rm -rf dist` vs
# `rm -rf ~`, `branch -D` vs `-d`) that only a parse can make. Same idea and the
# same deny/ask JSON protocol as the sibling tmux-guard.sh.
#
# Ported from a friend's opencode command-guard (allowlist and block/tip pairs);
# adapted to POSIX sh, to Claude Code's PreToolUse contract, and to "ask".
set -u

in=$(cat)
cmd=$(printf '%s' "$in" | jq -r '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0
# Quick reject: nothing here fires unless git, rm or gh is somewhere in the line.
case $cmd in *git*|*rm*|*gh*) ;; *) exit 0 ;; esac

ask() {
    jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
    exit 0
}

# Does part $1 carry the short flag $2, bare or in a cluster (-rf, -fr)? Long
# options (--force) never count as a cluster — checked separately by the caller.
has_short() { printf '%s' "$1" | grep -qE -- "(^|[[:space:]])-[A-Za-z]*$2[A-Za-z]*([[:space:]]|=|\$)"; }
# Does part $1 carry the exact long option $2 (e.g. --force, and NOT
# --force-with-lease, since the boundary requires whitespace/end/=)?
has_long()  { printf '%s' "$1" | grep -qE -- "(^|[[:space:]])$2([[:space:]]|=|\$)"; }

# One subcommand per line, same split and normalization as tmux-guard.sh: only a
# subcommand whose command WORD is git/rm/gh is inspected, so a url or message
# that merely mentions "git push --force" (a different command word: echo, gh
# pr comment, …) is never a false positive.
printf '%s\n' "$cmd" | sed -E 's/(&&|\|\||;|\|)/\n/g' | while IFS= read -r c; do
    c=$(printf '%s' "$c" | sed -E 's/^[[:space:]]*//; s/^(sudo[[:space:]]+)?(command[[:space:]]+|env([[:space:]]+[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*)*[[:space:]]+)*//; s#^[^[:space:]]*/(git|rm|gh)([[:space:]]|$)#\1\2#')

    case $c in
        git\ *)
            # The subcommand is the first non-option token after `git`, skipping
            # the global options that take an argument (-C dir, -c k=v) and any
            # other leading -flag. `git -C /r push --force` still resolves to push.
            sub=$(printf '%s\n' "$c" | awk '{for(i=2;i<=NF;i++){if($i=="-C"||$i=="-c"){i++;continue} if($i ~ /^-/)continue; print $i; exit}}')
            case $sub in
                reset)
                    has_long "$c" '--hard'  && ask "git reset --hard destroys uncommitted changes — stash first, then approve if you meant it"
                    has_long "$c" '--merge' && ask "git reset --merge destroys uncommitted changes — stash first, then approve if you meant it" ;;
                checkout)
                    # Only the unambiguous discard form `git checkout -- <path>`;
                    # `git checkout -b`, `--orphan`, or a branch name are safe.
                    has_long "$c" '--' && ask "git checkout -- discards file modifications — stash first, then approve if you meant it" ;;
                restore)
                    # --staged / -S only unstages (safe); anything else touches
                    # the worktree and discards changes.
                    { has_long "$c" '--staged' || has_short "$c" S; } \
                        || ask "git restore discards uncommitted changes — use --staged to only unstage, or approve if you meant it" ;;
                clean)
                    { has_long "$c" '--dry-run' || has_short "$c" n; } && continue
                    { has_long "$c" '--force' || has_short "$c" f; } \
                        && ask "git clean -f permanently deletes untracked files — 'git clean -n' previews; approve if you meant it" ;;
                push)
                    has_long "$c" '--force-with-lease' && continue   # the safe force
                    { has_long "$c" '--force' || has_short "$c" f; } \
                        && ask "git push --force overwrites remote history — prefer --force-with-lease, or approve if you meant it" ;;
                branch)
                    # -D (or --delete --force) force-deletes without a merge check;
                    # -d is the safe delete.
                    { has_short "$c" D || { has_long "$c" '--delete' && { has_long "$c" '--force' || has_short "$c" f; }; }; } \
                        && ask "git branch -D force-deletes a branch without a merge check — 'git branch -d' is the safe delete; approve if you meant it" ;;
                stash)
                    case $c in
                        *stash\ drop*)  ask "git stash drop permanently deletes a stash — check 'git stash list' first, then approve" ;;
                        *stash\ clear*) ask "git stash clear permanently deletes ALL stashes — check 'git stash list' first, then approve" ;;
                    esac ;;
                filter-branch|filter-repo)
                    ask "git $sub rewrites history across the repo — a specific go-ahead is required; approve if you meant it" ;;
            esac ;;

        rm|rm\ *)
            # Only the recursive-and-force form is guarded; a plain `rm file` is
            # left alone. If every target is a known-safe build/cache/tmp dir,
            # it passes without a prompt.
            { has_short "$c" r || has_long "$c" '--recursive'; } || continue
            { has_short "$c" f || has_long "$c" '--force'; }     || continue
            unsafe=$(printf '%s\n' "$c" | awk '{
                seen=0
                for(i=2;i<=NF;i++){
                    t=$i
                    if(t=="--"){seen=1;continue}
                    if(!seen && substr(t,1,1)=="-")continue
                    gsub(/^["'"'"']|["'"'"']$/,"",t)
                    if(t ~ /^(\.\/)?(node_modules|dist|build|coverage|__pycache__|\.cache|\.next|\.turbo)(\/|$)/)continue
                    if(t ~ /^(\/tmp|\/var\/tmp|\/private\/tmp)(\/|$)/)continue
                    if(t ~ /(\/|^)scratchpad(\/|$)/)continue
                    print t; exit
                }
            }')
            [ -n "$unsafe" ] && ask "rm -rf on '$unsafe' is outside the known-safe build/cache/tmp dirs — verify the path, then approve if you meant it" ;;

        gh\ *)
            case $c in
                *gh\ repo\ delete*)    ask "gh repo delete permanently deletes a GitHub repository — irreversible; approve only if you are certain" ;;
                *gh\ gist\ delete*)    ask "gh gist delete permanently deletes a gist — irreversible; approve only if you are certain" ;;
                *gh\ release\ delete*) ask "gh release delete removes a GitHub release — verify the tag, then approve" ;;
                *gh\ ssh-key\ delete*) ask "gh ssh-key delete removes an SSH key from your GitHub account — verify the id, then approve" ;;
            esac ;;
    esac
done
exit 0
