# dotfiles

Personal macOS/Linux dev environment. Everything is **symlinked** into
`$HOME` / `$XDG_CONFIG_HOME` from this repo — the file in the repo is the
source of truth; the home-dir path is just a link back to it. One repo
bootstraps a whole workstation, including the Claude Code setup.

## Install

**Fresh machine (one command):**

```sh
git clone <this-repo> && cd dotfiles
make bootstrap    # CLT + Homebrew + brew bundle + symlinks + node LTS + nvim nightly
exec zsh -l       # pick up the new shell — then: claude login
```

`bootstrap.sh` is idempotent — if a step fails (e.g. `mas` apps before you've
signed into the App Store), fix the cause and re-run it. On Linux it just
links the dotfiles.

**Already-provisioned machine (symlinks only):**

```sh
make install      # or: ./install.sh
```

`make install` (via `install.sh`) is idempotent and safe to re-run: it
refreshes existing symlinks and backs up any pre-existing **real** file to
`<path>.bak.<timestamp>` before linking. It also seeds `~/.gitconfig.local`
(machine-local git identity — set your work email there) and
`~/.zshenv.local` (machine-local shell env — put API tokens there).

```sh
make status      # show which of this repo's links are live / stale
make uninstall   # remove only the symlinks that point back into this repo
make relink      # uninstall + install — repoint everything (e.g. after moving the repo)
make help        # list targets
```

## Layout

| Path | What |
|------|------|
| `.zshenv` | Bootstrap — sets `ZDOTDIR=~/.config/zsh`, then loads the real env |
| `.config/zsh/` | `ZDOTDIR`: `.zshenv` (env), `.zprofile` (PATH), `.zshrc` (interactive + aliases) |
| `.config/starship.toml` | Prompt config |
| `.config/nvim/` | Neovim 0.12 — native LSP, `vim.pack`, blink.cmp, fzf-lua, treesitter |
| `.config/wezterm/` | WezTerm — catppuccin mocha, tmux-style `C-a` leader |
| `.config/ghostty/` | Ghostty — same palette/font, native tabs & splits |
| `.gitconfig`, `.psqlrc`, `.tmux.conf`, `Brewfile` | Git / psql / tmux / Homebrew bundle |
| `docs/` | Guides — [`tmux.md`](docs/tmux.md) (sessions, panes, copy/paste) |
| `.claude/` | **Portable Claude Code config** — global rules, curated agents, settings |
| `agents-scaffold/` | Drop-in **agentic project scaffold** for *other* repos |

## Claude Code setup

`.claude/` is version-controlled here and symlinked into `~/.claude` by
`install.sh` — but only the **portable config**, never the runtime state
(transcripts, caches, credentials, plugins stay local). See
[`.claude/README.md`](.claude/README.md) for the portable-vs-local split.

- **[`.claude/CLAUDE.md`](.claude/CLAUDE.md)** — global defaults loaded into
  every session (ethos, commit rules, stop-and-ask thresholds).
- **[`.claude/agents/`](.claude/agents/README.md)** — a curated set of
  "rockstar" specialists (Go, Rust, Neovim, Lua, shell, containers,
  distributed systems, frontend, design, AI/Claude, …), each usable to
  *ask* current-idiom questions or *delegate* real work.
- **[`.claude/settings.json`](.claude/settings.json)** — model, permissions,
  enabled plugins.

Fresh machine: `make bootstrap` (installs the `claude-code` cask too), then
`claude login` (auth stays local). Note: runtime "always allow" grants and
`/config` edits write **through the symlink** into the tracked
`settings.json` — review diffs before committing; keep machine-local rules in
`settings.local.json` (gitignored).

## agents-scaffold

A portable, self-contained working system for agentic development — an
`AGENTS.md`, an ADR log, a session journal, a human-decision queue, and
enforcing git hooks — to drop into any *other* repo:

```sh
./agents-scaffold/install.sh ~/code/some-project
```

It deliberately does **not** depend on this repo's `~/.claude` globals, so it
stands alone on teammates' machines and CI. See
[`agents-scaffold/README.md`](agents-scaffold/README.md).

## Stack

- **Shell:** zsh + [zap](https://github.com/zap-zsh/zap), XDG layout via `ZDOTDIR`
- **Prompt:** [starship](https://starship.rs)
- **Terminal:** [WezTerm](https://wezterm.org) (a [Ghostty](https://ghostty.org) config is maintained in parallel)
- **Editor:** [Neovim](https://neovim.io) 0.12+
- **Tools:** fnm (node) · colima (docker) · zoxide (`j`) · fzf · eza · bat

## Conventions

- **tmux is the multiplexer** (3.7, same palette), inside WezTerm or Ghostty —
  one session per project, one window per task. `C-a` is the leader everywhere:
  split `s`/`v`, navigate `h/j/k/l`, resize mode `r` (tmux: `R`), zoom `z`,
  copy-mode `[`. Sessions get `S` (tree), `C-s` (new), plus `ta`/`ts`/`tsvc`
  from the shell. Full guide: [`docs/tmux.md`](docs/tmux.md).
- **Selecting isn't copying.** In tmux the mouse only highlights; `y` is the
  one path to the clipboard, so a drag in the pane you're pasting *into* can't
  clobber the buffer you just filled.
- **No key clash:** bare `C-h/j/k/l` crosses Neovim windows *and* tmux panes —
  it's Vim- and fzf-aware, so the same keys work wherever focus is; `C-a
  h/j/k/l` is the explicit-prefix form. `Cmd+C`/`Cmd+V` are the terminal's own
  copy/paste (in a full-screen TUI, hold **Shift while dragging** to select
  first) — inside tmux, prefer `y`.
- **Docker:** colima (`colima start`). The `default` context targets colima.
- **AI commits:** no AI attribution — never add `Assisted-by:` or
  `Co-Authored-By:` for an AI; the owner attributes manually. See
  `.claude/CLAUDE.md`.
