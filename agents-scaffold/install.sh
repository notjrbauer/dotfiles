#!/usr/bin/env bash
# Install the agentic project scaffold into a target repo.
#
#   ./install.sh [target-dir]     # defaults to the current directory
#
# Copies the template files (never clobbering ones that already exist),
# installs the managed git hooks into .githooks/, and wires
# core.hooksPath. Safe to re-run: it updates hooks and adds any missing
# template files, and leaves your edited AGENTS.md / decisions.md alone.
set -euo pipefail

SCAFFOLD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMPL="$SCAFFOLD_DIR/template"
HOOKS_SRC="$SCAFFOLD_DIR/githooks"

TARGET="${1:-$PWD}"
TARGET="$(cd "$TARGET" && pwd)"

# Prefer the git repo root if the target sits inside one.
if git -C "$TARGET" rev-parse --show-toplevel >/dev/null 2>&1; then
	TARGET="$(git -C "$TARGET" rev-parse --show-toplevel)"
fi

echo "Installing agent scaffold into: $TARGET"
echo

copied=0
skipped=0
# Copy template files, never overwriting existing ones (your edits win).
while IFS= read -r -d '' src; do
	rel="${src#"$TMPL"/}"
	dst="$TARGET/$rel"
	if [ -e "$dst" ]; then
		echo "  skip (exists): $rel"
		skipped=$((skipped + 1))
	else
		mkdir -p "$(dirname "$dst")"
		cp "$src" "$dst"
		echo "  add:           $rel"
		copied=$((copied + 1))
	fi
done < <(find "$TMPL" -type f -print0)

# Install git hooks (these ARE overwritten — they're managed here). Check
# core.hooksPath FIRST: if the repo already uses a different hooks setup,
# don't touch its files at all.
install_hooks() {
	mkdir -p "$TARGET/.githooks"
	# Managed, so they are replaced — but a hand-written hook of the same name
	# that differs from ours is the repo's own work; move it aside first.
	for h in "$HOOKS_SRC"/*; do
		dst="$TARGET/.githooks/$(basename "$h")"
		if [ -e "$dst" ] && ! cmp -s "$h" "$dst"; then
			mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
			echo "  backed up:     .githooks/$(basename "$h") (differed from the managed copy)"
		fi
		cp "$h" "$dst"
	done
	chmod +x "$TARGET/.githooks/pre-commit" "$TARGET/.githooks/pre-push" "$TARGET/.githooks/commit-msg"
	echo "  hooks:         .githooks/ (pre-commit, commit-msg, pre-push, lib-verify.sh)"
}

# Wire the hooks path (per-repo, reversible with: git config --unset core.hooksPath).
if git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
	existing="$(git -C "$TARGET" config --local --get core.hooksPath || true)"
	if [ -n "$existing" ] && [ "$existing" != ".githooks" ]; then
		echo "  WARNING: core.hooksPath is already '$existing' — leaving it AND its hooks untouched."
		echo "           Set it to .githooks and re-run if you want these hooks."
	else
		install_hooks
		git -C "$TARGET" config core.hooksPath .githooks
		echo "  git config core.hooksPath .githooks  OK"
	fi
else
	install_hooks
	echo "  NOTE: not a git repo yet — run 'git init', then 'git config core.hooksPath .githooks'."
fi

echo
echo "Done: $copied added, $skipped skipped (already present)."
echo
echo "Next steps:"
echo "  1. Edit AGENTS.md — set the project name/description, prune conventions that don't apply."
echo "  2. Fill docs/decisions.md D-001's date; add ADRs as you lock decisions."
echo '  3. Add a verify target so the hooks can gate commits: an executable'
echo '     scripts/verify, an npm "verify" script, or a Makefile "verify:" target.'
echo '  4. First journal entry:  project/journal/$(date +%F)-session-01-bootstrap.md'
