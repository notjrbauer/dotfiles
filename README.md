# dotfiles

Personal macOS/Linux dev environment. Everything is **symlinked** into
`$HOME` / `$XDG_CONFIG_HOME` from this repo — the file in the repo is the
source of truth; the home-dir path is just a link back to it. One repo
bootstraps a whole workstation, including the Claude Code setup.

## Install

```sh
git clone <this-repo> && cd dotfiles
make install      # or: ./install.sh
exec zsh -l       # pick up the new shell
```

`make install` (via `install.sh`) is idempotent and safe to re-run: it
refreshes existing symlinks and backs up any pre-existing **real** file to
`<path>.bak.<timestamp>` before linking.

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
| `.gitconfig`, `.psqlrc`, `.tmux.conf`, `Brewfile` | Git / psql / tmux / Homebrew bundle |
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

Fresh machine: `make install` then `claude login` (auth stays local).

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
- **Terminal:** [WezTerm](https://wezterm.org)
- **Editor:** [Neovim](https://neovim.io) 0.12+
- **Tools:** fnm (node) · colima (docker) · zoxide (`j`) · fzf · eza · bat

## Conventions

- **No tmux.** WezTerm panes cover it. `C-a` is the leader: split `s`/`v`,
  navigate `h/j/k/l`, resize mode `r`, zoom `z`, copy-mode `[`.
- **No key clash:** bare `C-h/j/k/l` navigates Neovim windows; `C-a h/j/k/l`
  navigates WezTerm panes. `Cmd+C`/`Cmd+V` copy/paste (in a full-screen TUI,
  hold **Shift while dragging** to make a selection first).
- **Docker:** colima (`colima start`). The `default` context targets colima.
- **AI commits:** assisted commits use an `Assisted-by:` trailer, never
  `Co-Authored-By:` for an AI. See `.claude/CLAUDE.md`.
