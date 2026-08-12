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
  match `.config/nvim`'s single-init.lua structure (native `vim.pack` —
  lazy.nvim is gone). Read the neighbor first.
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
- **Watch for write-through diffs.** `~/.claude/settings.json` (and
  friends) are symlinks into this repo, so runtime "always allow" grants
  edit the tracked files — see "Mind the write-through" in
  [`.claude/README.md`](.claude/README.md) before committing a surprise
  diff.

## Deliberate decisions — don't silently revert

Choices that look like mistakes but aren't:

- **The Brewfile is curated, not dumped.** Never regenerate it with
  `brew bundle dump` — that would re-add transitive deps (they install
  with their parents), re-pin `terraform` to the disabled homebrew-core
  formula instead of `hashicorp/tap`, and resurrect removed tools.
- **`brew "neovim"` and the nightly coexist.** `init.lua` targets 0.12+
  (`vim.pack`, treesitter main); `bootstrap.sh` installs the nightly
  into `~/.local/bin`, which outranks brew's stable on PATH. The brew
  formula stays as a fallback — don't "deduplicate" either away.
- **Git identity lives in `~/.gitconfig.local`** (seeded by
  `install.sh`, included last, untracked). Don't add an email back into
  the tracked `.gitconfig`; work machines override locally.
- **Secrets go in `~/.zshenv.local`** (seeded by `install.sh`, sourced
  last by `$ZDOTDIR/.zshenv`, untracked). Never put a token in
  `.config/zsh/` — that path is a *symlink to this repo*, so anything
  written there lands in a public tree. Same trap as `.claude/`.
- **`brew "mas"` has no `mas` entries to install.** The App Store apps
  were dropped in `5e98061`; only the CLI remains, for ad-hoc use. Don't
  "fix" the bundle by re-adding `mas` lines. `brew bundle` is still
  tolerated on failure, but the expected cause is now the livekit taps.
- **Tap trust belongs in the Brewfile's `trusted:`, not `brew trust`.**
  Homebrew 6 won't load non-official tap formulae until trusted. `bundle`
  resolves each item against the tap's `clone_target`, so for the two taps
  added by git URL it writes the URL-bound entry Homebrew actually checks —
  which `brew trust --formula livekit/nebula/nebula` cannot do on a fresh
  machine, where the tap has no remote yet and only the bare name exists.
  `nebula`/`nats` need their own `trusted:` despite being unlisted; trusting
  `lkctl` does not trust what it pulls in. Don't switch to
  `HOMEBREW_NO_REQUIRE_TAP_TRUST` — deprecated, slated for removal.
- **`lkctl` needs more than the formula.** It shells out to `cockroach sql`
  by name (hence `cockroachdb/tap/cockroach`, not a transitive dep), and
  installing it needs `HOMEBREW_GITHUB_API_TOKEN` from `~/.zshenv.local` —
  which is why step 3 sources that file before bundling.

## Maintaining this file

Add only what nearly every future session in this repo needs. Don't
repeat what the code already shows — point at the authoritative file or
command instead. Prefer rewriting or pruning entries over appending, and
hold new entries to that bar.

## Commits & attribution

Governed by [`.claude/CLAUDE.md`](.claude/CLAUDE.md), summarized here so
it's impossible to miss:

- **Commit/push only when explicitly asked.** No self-initiated commits,
  amends, or pushes. Never force-push or rewrite history without a
  specific go-ahead.
- **No AI attribution.** Never add an `Assisted-by:` or `Co-Authored-By:`
  trailer for an AI, and no emoji / "Generated with" banners — the owner
  adds attribution manually when they choose.

## The specialists

`.claude/agents/` holds personal "rockstar" subagents — each is both an
**ask-me** (current, idiom-accurate answers) and a **delegate-to-me**
(implements to current standards). To improve or add to them, hand the
work to `ai-claude-specialist`. See the roster in
[`.claude/agents/README.md`](.claude/agents/README.md).
