# AGENTS.md — dotfiles

Repo-specific rules. Global ethos and commit rules: `.claude/CLAUDE.md`
(symlinked to `~/.claude/CLAUDE.md`); this file wins on conflict.

## What this repo is

Personal dotfiles for macOS + Linux, installed by **symlink, not copy** —
the file in this repo is the source of truth, the `$HOME` path is a link to
it. `install.sh` is idempotent, and moves a pre-existing real file to
`<path>.bak.<timestamp>` before linking. Every new managed file needs a
`link` line there.

- `.claude/agents/*.md` — personal specialist subagents, symlinked into
  `~/.claude/agents` one entry at a time (`link_children`) so agents
  installed there later stay out of this public repo.
- `agents-scaffold/` — a **portable, self-contained** scaffold (AGENTS.md +
  ADR log + journal + git hooks) dropped into *other* repos. It must not
  depend on `~/.claude/CLAUDE.md`; it runs on machines without it.

## How to work here

- **Match the existing pattern.** New shell → follow `.config/zsh`; new
  managed dotfile → a `link` line in `install.sh`; new nvim config → match
  `.config/nvim`'s single-`init.lua` structure (native `vim.pack`; lazy.nvim
  is gone). Read the neighbor first.
- **Never clobber a user's edits.** The installer's don't-overwrite /
  back-up-first behavior is load-bearing — preserve it in any change to
  `install.sh` or `agents-scaffold/install.sh`.
- **Symlinks, not copies.** Track it here and link it; don't write into
  `$HOME` except through `install.sh`'s `link`.
- **Verify by running it.** Dry-run the `link` logic and confirm the symlink
  resolves back into the repo; load nvim changes (`nvim --headless`,
  `:checkhealth`) rather than assuming.
- **Watch for write-through diffs.** `~/.claude/settings.json` and friends
  are symlinks into this repo, so runtime "always allow" grants edit tracked
  files — see "Mind the write-through" in `.claude/README.md`.

## Don't silently revert

- **Secrets → `~/.zshenv.local`** (untracked, sourced last). Never a token in
  `.config/zsh/` — that path is a symlink into this public repo.
- **Git identity → `~/.gitconfig.local`** (untracked, included last). Don't
  put an email back in the tracked `.gitconfig`.
- **The Brewfile is curated by hand.** Never `brew bundle dump` — it re-adds
  transitive deps, re-pins `terraform` to the disabled core formula, and
  resurrects removed tools.
- **`brew "mas"` is the CLI only.** The App Store apps went in `5e98061`;
  there are no `mas` entries by design.

The rest of the Brewfile lore (tap trust, `lkctl` needing `cockroach`) is
documented in the Brewfile itself, and the neovim nightly-vs-brew split in
`bootstrap.sh`. Read them there.

## The specialists

`.claude/agents/` holds personal subagents — each is both an ask-me and a
delegate-to-me. Hand agent work to `ai-claude-specialist`; roster in
`.claude/agents/README.md`.

Keep this file to what nearly every session here needs; point at the
authoritative file instead of restating it. Commits: `.claude/CLAUDE.md`
governs — commit only when asked, never any AI attribution.
