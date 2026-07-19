# AGENTS.md — dotfiles

How to work **in this repo**. It's read by AI agents (and humans) at the
start of a session. The shared ethos and commit rules live once in
[`.claude/CLAUDE.md`](.claude/CLAUDE.md) (symlinked to `~/.claude/CLAUDE.md`,
so it loads into *every* Claude Code session on this machine) — this file
adds only what's specific to the dotfiles repo. Read that file first; on
conflict, this repo-local file wins.

## What this repo is

Personal dotfiles for macOS + Linux, installed by **symlink**, not copy.
`install.sh` links tracked files into `$HOME` / `$XDG_CONFIG_HOME` and is
idempotent — safe to re-run; a pre-existing real file at a destination is
moved to `<path>.bak.<timestamp>` before linking. The source of truth is
always the file *in this repo*; the home-dir path is just a symlink to it.

Layout that matters:

- `install.sh` — the `link src dest` symlink installer. Every new managed
  file gets a `link` line here.
- `.claude/CLAUDE.md` — global Claude Code defaults → `~/.claude/CLAUDE.md`.
- `.claude/agents/*.md` — personal specialist subagents. The whole
  directory is symlinked as `~/.claude/agents` (one flat dir, one
  `link` line) — this repo is the single source of truth for the set.
- `agents-scaffold/` — a **portable, self-contained** project scaffold
  (AGENTS.md + ADR log + journal + enforcing git hooks) to drop into
  *other* repos via `agents-scaffold/install.sh`. It intentionally does
  **not** depend on `~/.claude/CLAUDE.md` — it must work on machines that
  don't have it. Don't couple it to this repo's globals.

## How to work here

- **Match the existing pattern.** New shell → follow `.config/zsh`; new
  managed dotfile → add a `link` line in `install.sh`; new nvim config →
  match `.config/nvim`'s Lua/lazy.nvim structure. Read the neighbor first.
- **Never clobber a user's edits.** The installer's don't-overwrite /
  back-up-first behavior is a load-bearing invariant. Preserve it in any
  change to `install.sh` or `agents-scaffold/install.sh`.
- **Symlinks, not copies.** If you add something meant to live in `$HOME`,
  track it here and symlink it — don't write into `$HOME` directly except
  through `install.sh`'s `link`.
- **Verify by running it.** After touching `install.sh`, dry-run the
  relevant `link` logic and confirm the symlink resolves back into the
  repo. For nvim changes, load them (`nvim --headless`/`:checkhealth`)
  rather than assuming.

## Commits & attribution

Governed by [`.claude/CLAUDE.md`](.claude/CLAUDE.md), summarized here so
it's impossible to miss:

- **Commit/push only when explicitly asked.** No self-initiated commits,
  amends, or pushes. Never force-push or rewrite history without a
  specific go-ahead.
- **AI-assisted commits** end with an `Assisted-by: AGENT_NAME:MODEL_VERSION`
  trailer (the *actual* running model) — e.g.
  `Assisted-by: Claude Code:claude-opus-4-8`. **Never** `Co-Authored-By:`
  for an AI, and no emoji / "Generated with" banners.

## The specialists

`.claude/agents/` holds personal "rockstar" subagents — each is both an
**ask-me** (current, idiom-accurate answers) and a **delegate-to-me**
(implements to current standards). To improve or add to them, hand the
work to `ai-claude-specialist`. See the roster in
[`.claude/agents/README.md`](.claude/agents/README.md).
