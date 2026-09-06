#!/usr/bin/env bash
# install.sh — idempotently symlink these dotfiles into $HOME / $XDG_CONFIG_HOME.
#
# Safe to re-run. If a real (non-symlink) file already exists at a destination,
# it is moved aside to <path>.bak.<timestamp> before the symlink is created.
set -euo pipefail

# pwd -P (physical path) so link targets match the Makefile's $(realpath) —
# otherwise uninstall/status miss every link when the repo sits behind a symlink.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

link() {
  local src="$1" dest="$2"
  if [ ! -e "$src" ]; then
    echo "skip: $src does not exist"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  # Only a link that already points into this repo is ours to refresh in
  # place. A link that points anywhere else — another dotfiles manager, stow, a
  # hand-made one — is the user's, and gets the same back-up as a real file
  # (mv moves the link itself, dangling or not, and never follows it).
  if [ -L "$dest" ] && case "$(readlink "$dest")" in "$DOTFILES"/*) true ;; *) false ;; esac; then
    ln -sfn "$src" "$dest"                       # refresh our own symlink
  elif [ -e "$dest" ] || [ -L "$dest" ]; then
    local bak="$dest.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$bak"
    echo "backed up  $dest -> $bak"
    ln -sfn "$src" "$dest"
  else
    ln -sfn "$src" "$dest"
  fi
  echo "linked     $dest -> $src"
}

# Link each ENTRY of a directory, leaving the destination itself a real dir.
#
# Symlinking the directory itself makes this repo the destination for anything
# that writes into it -- `lightdash install-skills --global`, a plugin
# installer, Claude Code's own /agents -- so machine-local or work-specific
# files land in a public repo without anyone choosing that. Per-entry links keep
# the repo's contents shared and everything else machine-local.
#
# Tradeoff: entries added to the repo elsewhere need a re-run to show up here.
link_children() {
  local src="$1" dest="$2" entry
  if [ ! -d "$src" ]; then
    echo "skip: $src does not exist"
    return
  fi

  # Replace a whole-directory symlink left by an older install. Removing the
  # link never touches the repo it points at.
  if [ -L "$dest" ]; then
    rm "$dest"
    echo "unlinked   $dest (was a whole-directory symlink)"
  fi
  mkdir -p "$dest"

  # Drop links we own whose target has since left the repo. Real files and
  # links pointing anywhere else are left alone -- those are the user's.
  for entry in "$dest"/*; do
    [ -L "$entry" ] || continue
    case "$(readlink "$entry")" in
      "$src"/*) [ -e "$entry" ] || { rm "$entry"; echo "pruned     $entry (target gone)"; } ;;
    esac
  done

  for entry in "$src"/*; do
    [ -e "$entry" ] || continue # unmatched glob
    # The roster README is documentation for this repo, not an agent or skill.
    case "$(basename "$entry")" in README.md) continue ;; esac
    link "$entry" "$dest/$(basename "$entry")"
  done
}

# --- Shell (XDG) ---------------------------------------------------------
# ZDOTDIR lives at ~/.config/zsh; ~/.zshenv is just the bootstrap that sets it.
link "$DOTFILES/.zshenv"             "$HOME/.zshenv"
link "$DOTFILES/.config/zsh"         "$XDG_CONFIG_HOME/zsh"
link "$DOTFILES/.config/starship.toml" "$XDG_CONFIG_HOME/starship.toml"

# --- Editor / terminal ---------------------------------------------------
link "$DOTFILES/.config/nvim"        "$XDG_CONFIG_HOME/nvim"
link "$DOTFILES/.config/wezterm"     "$XDG_CONFIG_HOME/wezterm"
link "$DOTFILES/.config/ghostty"     "$XDG_CONFIG_HOME/ghostty"
link "$DOTFILES/.tmux.conf"          "$HOME/.tmux.conf"
# The conf stays at ~/.tmux.conf; only the helper scripts it shells out to are
# XDG. Nothing here is named tmux.conf on purpose — tmux also looks for
# $XDG_CONFIG_HOME/tmux/tmux.conf, and a second config found there would load
# instead of the one above.
link "$DOTFILES/.config/tmux"        "$XDG_CONFIG_HOME/tmux"

# Hammerspoon: link the file, not ~/.hammerspoon itself — Spoons install into
# that directory and would otherwise land in this repo (same trap as .claude).
link "$DOTFILES/.hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"

# --- Git / CLI -----------------------------------------------------------
link "$DOTFILES/.gitconfig"          "$HOME/.gitconfig"
link "$DOTFILES/.psqlrc"             "$HOME/.psqlrc"

# Git identity files (untracked, seeded once, never symlinked). .gitconfig
# selects between them by directory, so a work machine never has to remember to
# override anything: repos under ~/dev get the work address, ~/dev/notjrbauer/
# carves personal back out, everything else falls back to .gitconfig's [user].
# The work address is a placeholder here on purpose — this repo is public — and
# it is seeded COMMENTED OUT: a live placeholder was the identity every commit
# under ~/dev got until someone noticed (git config --show-origin user.email).
seed() {
  local path="$1" body="$2"
  [ -f "$path" ] && return
  printf '%s\n' "$body" > "$path"
  echo "seeded     $path"
}

seed "$HOME/.gitconfig.work" '; Work identity (untracked). Applied to every repo under ~/dev.
; Uncomment and fill in. Until then git falls back to [user] in .gitconfig
; rather than committing under a placeholder address.
;[user]
;	name = john b
;	email = you@company.example'

seed "$HOME/.gitconfig.personal" '; Personal identity (untracked). Applied to repos under ~/dev/notjrbauer/,
; which sits inside the work tree and so needs to override it.
[user]
	name = john b
	email = notjrbauer@gmail.com'

seed "$HOME/.gitconfig.local" '; Machine-local git overrides (untracked). Identity comes from
; ~/.gitconfig.work and ~/.gitconfig.personal, selected by directory in
; .gitconfig — keep this for things that are genuinely per-machine, like
; signing keys or credential helpers.'

# --- tmux local overrides -------------------------------------------------
# Sourced last by .tmux.conf (`source-file -q`), so it wins over everything
# above it. Same reason as the git and shell files: .tmux.conf is a symlink
# into a public repo. It is also where the platform split belongs — `y` pipes
# to pbcopy and the URL picker calls `open`, both macOS-only.
seed "$HOME/.tmux.conf.local" '# Machine-local tmux overrides (untracked), sourced last by ~/.tmux.conf.
# Reload with prefix r. Examples:
#   set -g status-position bottom
#   bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"   # Linux'

# --- Shell secrets --------------------------------------------------------
# Sourced by $ZDOTDIR/.zshenv. Deliberately in $HOME and not ~/.config/zsh —
# that path is a symlink to this repo, so a secrets file there would sit in a
# public tree. 600 because it holds tokens.
seed "$HOME/.zshenv.local" '# Machine-local shell env (untracked) — sourced by $ZDOTDIR/.zshenv.
# Secrets and per-machine vars only. Never commit this file; it is not in the
# repo, and must not be moved into ~/.config/zsh (that is a symlink to it).

# GitHub PAT for Homebrew. Required — not just a rate-limit nicety — by the
# livekit/nebula formula, which pulls release assets from a private repo via a
# custom download strategy that raises if this is unset. Needs `repo` scope.
# export HOMEBREW_GITHUB_API_TOKEN=ghp_xxx'
chmod 600 "$HOME/.zshenv.local" \
  || echo "warn: could not chmod 600 ~/.zshenv.local (owned by someone else?) — it holds tokens"

# --- Agent log drop -------------------------------------------------------
# ~/.claude/CLAUDE.md and the tmux-panes skill both tell agents to tee long
# command output here instead of pasting it into the transcript, and .tmux.conf
# binds prefix g to page it. Nothing created it, so on a fresh machine the
# first `tee ~/.cache/agent-logs/x.log` failed and prefix g just said "no agent
# logs yet" forever.
mkdir -p "$HOME/.cache/agent-logs" && echo "ensured    $HOME/.cache/agent-logs"

# --- Git hooks ------------------------------------------------------------
# .githooks/pre-commit blocks staged credentials. Only wired if nothing else
# owns core.hooksPath, so a different hooks setup here is never clobbered.
# Reversible with: git config --unset core.hooksPath
chmod +x "$DOTFILES/.githooks/pre-commit" 2>/dev/null || true
if git -C "$DOTFILES" rev-parse --git-dir >/dev/null 2>&1; then
  existing="$(git -C "$DOTFILES" config --local --get core.hooksPath || true)"
  if [ -z "$existing" ]; then
    git -C "$DOTFILES" config --local core.hooksPath .githooks
    echo "wired      core.hooksPath -> .githooks"
  elif [ "$existing" != ".githooks" ]; then
    echo "skip: core.hooksPath is already '$existing' — leaving it alone"
  fi
else
  echo "skip: $DOTFILES is not a git checkout — hooks not wired"   # a tarball; set -e would have aborted here
fi

# --- Claude Code ---------------------------------------------------------
# Portable config only (see .claude/README.md). Runtime state — transcripts,
# caches, credentials, plugins — stays local in ~/.claude and is never tracked.
# agents/ and skills/ are linked per entry, not as whole directories, so that
# anything installed into them later stays on this machine instead of landing
# in a public repo (see link_children).
link "$DOTFILES/.claude/CLAUDE.md"      "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/.claude/settings.json"  "$HOME/.claude/settings.json"
link_children "$DOTFILES/.claude/agents" "$HOME/.claude/agents"
link_children "$DOTFILES/.claude/skills" "$HOME/.claude/skills"
link_children "$DOTFILES/.claude/rules"  "$HOME/.claude/rules"    # path-scoped, load with matching files
link_children "$DOTFILES/.claude/hooks"  "$HOME/.claude/hooks"    # scripts settings.json's hooks call
chmod +x "$DOTFILES"/.claude/hooks/*.sh 2>/dev/null || true
# A subagent or skill with bad frontmatter is skipped silently by Claude Code,
# and `claude plugin validate` only understands plugin/marketplace manifests —
# so check the frontmatter ourselves: a closed --- block with a non-empty name
# and description, and a skill's name matching its directory. Non-fatal, so a
# bad file cannot stop the links above from landing.
check_frontmatter() {
  local file="$1" want_name="$2"
  awk -v f="${file#"$DOTFILES"/}" -v want="$want_name" '
    function warn(msg) { print "warn: " f ": " msg; bad = 1 }
    NR == 1 { if (!/^---[ \t]*$/) { warn("no YAML frontmatter (first line is not ---)"); exit } next }
    /^---[ \t]*$/ { closed = 1; exit }
    # a folded description ("description: >-") counts once an indented line
    # with content follows; hitting a top-level key first means it was empty
    indesc && /[^ \t]/ { desc = ($0 ~ /^[ \t]/); indesc = 0 }
    /^name:/ { name = $0; sub(/^name:[ \t]*/, "", name); sub(/[ \t]+$/, "", name) }
    /^description:/ {
      d = $0; sub(/^description:[ \t]*/, "", d)
      if (d == "" || d ~ /^[>|][+-]?[ \t]*$/) indesc = 1; else desc = 1
    }
    END {
      if (!bad) {
        if (!closed) warn("unterminated frontmatter (no closing ---)")
        if (name == "") warn("missing or empty name")
        else if (want != "" && name != want) warn("name \"" name "\" does not match \"" want "\"")
        if (!desc) warn("missing or empty description")
      }
      exit bad
    }' "$file" >&2
}
frontmatter_ok=1
for f in "$DOTFILES"/.claude/agents/*.md; do
  [ -e "$f" ] || continue # unmatched glob
  case "$(basename "$f")" in README.md) continue ;; esac
  check_frontmatter "$f" "" || frontmatter_ok=0
done
for d in "$DOTFILES"/.claude/skills/*/; do
  [ -d "$d" ] || continue # unmatched glob
  d="${d%/}"
  if [ -f "$d/SKILL.md" ]; then
    check_frontmatter "$d/SKILL.md" "$(basename "$d")" || frontmatter_ok=0
  else
    echo "warn: ${d#"$DOTFILES"/} has no SKILL.md — Claude Code will not see it" >&2
    frontmatter_ok=0
  fi
done
[ "$frontmatter_ok" -eq 1 ] || echo "warn: some agents/skills have frontmatter problems (see above) — Claude Code skips those silently" >&2

echo ""
echo "Done. Start a new shell (or run: exec zsh -l) to pick up the changes."
