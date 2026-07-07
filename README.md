# dotfiles

Personal macOS dev environment. Everything is symlinked into `$HOME` /
`$XDG_CONFIG_HOME` from this repo by `install.sh`.

## Install

```sh
git clone <this-repo> ~/dotfiles && ~/dotfiles/install.sh
exec zsh -l
```

`install.sh` is idempotent and backs up any pre-existing real file to
`<path>.bak.<timestamp>` before linking.

## Layout

| Path | What |
|------|------|
| `.zshenv` | Bootstrap — sets `ZDOTDIR=~/.config/zsh`, then loads the real env |
| `.config/zsh/` | `ZDOTDIR`: `.zshenv` (env + PATH) and `.zshrc` (interactive) |
| `.config/zunder-zsh/` | zunder framework hooks + spaceship prompt config |
| `.config/nvim/` | Neovim 0.12 — native LSP, `vim.pack`, blink.cmp, fzf-lua, treesitter |
| `.config/wezterm/` | WezTerm — catppuccin mocha, tmux-style `C-a` leader |

## Stack

- **Shell:** zsh + [zap](https://github.com/zap-zsh/zap), XDG layout via `ZDOTDIR`
- **Prompt:** spaceship
- **Terminal:** [WezTerm](https://wezterm.org)
- **Editor:** [Neovim](https://neovim.io) 0.12+
- **Multiplexer:** none — WezTerm native panes
- **Tools:** fnm (node) · colima (docker) · zoxide (`j`) · fzf · eza · bat

## Conventions

- **No tmux.** WezTerm panes cover it. `C-a` is the leader: split `s`/`v`,
  navigate `h/j/k/l`, resize mode `r`, zoom `z`, copy-mode `[`.
- **No key clash:** bare `C-h/j/k/l` navigates Neovim windows; `C-a h/j/k/l`
  navigates WezTerm panes.
- **Docker:** colima (`colima start`). No `DOCKER_HOST` override — the `default`
  context targets colima; switch with `docker context use <name>`.
