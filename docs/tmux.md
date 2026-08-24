# tmux

Prefix is **`C-a`** (`.tmux.conf`). The terminals bind SUPER-only chords and no
ctrl keys, so `C-a` reaches tmux on a single tap. Windows and panes number
from **1**. `C-a ?` is the complete key list.

| Layer | Holds | Rule of thumb |
| --- | --- | --- |
| **Session** | one project or task, plus long-lived services | switch, don't stack |
| **Window** | one unit of work inside that project | the window list is the WIP limit |
| **Pane** | the editor / agent / shell of that unit | zoom, don't resize |

## Sessions

One session per project, so `cd`-ing around is replaced by switching.

| Key | Does |
| --- | --- |
| `C-a S` | session/window tree (`choose-tree -Zs`) — the main way to move; `x` in the list kills the highlighted item |
| `C-a L` | last session (the toggle you'll use most) |
| `C-a C-s` | new session, prompts for a name, inherits the current pane's cwd |
| `C-a $` | rename session (prefills current) |
| `C-a d` | detach — leaves everything running |
| `C-a D` | choose which client to detach |
| `C-a C-q` | kill the whole session — **asks first**, and lands you in the next session rather than dropping you out of tmux |

From the shell, outside or inside tmux:

| Command | Does |
| --- | --- |
| `ta [name]` | attach to `name`, creating it if needed; defaults to the **main repo root's** basename |
| `ts` / `^S` | fzf picker over live sessions |
| `tkill [name…]` | kill sessions by exact name; with no args resolves the same name as `ta` |
| `tsvc <name> <cmd> [args…]` | park a long-running command in its own detached session |

`ta` is the normal entry point: `cd` anywhere inside a project, run `ta`, and you
get a session named after the **main repo root** — the same name from any depth,
so it reattaches instead of piling up duplicates. It resolves that through
`git rev-parse --git-common-dir`, not `--show-toplevel`, so a **linked worktree
still names its session after the repo**: `--show-toplevel` returns the worktree
directory, which lost the repo name and let a `fix-tests` worktree in two
different projects collide onto one session.

A worktree per workstream is Claude Code's own feature now: `claude --worktree
<name> --tmux=classic` creates `.claude/worktrees/<name>` on branch
`worktree-<name>` and a tmux session for it, copies the gitignored files listed
in `.worktreeinclude` (`.env`, `node_modules` are the usual ones), and on exit
asks whether to keep the worktree. `claude -r` returns a session to its
worktree. (The hand-rolled `tw` that did this lived in `.zshrc` until Aug 2026.)

`.` and `:` in any name become `_` — `C-a C-s` and `C-a C` sanitize what you type
too — because tmux reads them as session/window/pane separators and a name
containing them cannot be targeted or killed afterwards.

`^S` also works at a shell prompt when no server is running yet, where there is
no prefix to press.

### Long-running commands

A VPN client, tunnel, watcher, or log tail that must hold a terminal all day
does not want to be a split in a working window — it eats space, and a `C-a q`
aimed at a work pane can take it out.

```sh
tsvc vpn vpn connect --env staging     # starts detached, returns immediately
ta vpn                                 # look at it
```

`tsvc` is idempotent: run it again and it says the session is already up rather
than starting a second copy. The session keeps `remain-on-exit on`, so a command
that dies leaves the pane as `Pane is dead (status N)` with its scrollback
intact — and `tsvc` restarts a dead one in place. An existing session is
therefore *not* proof the command is still running; check the pane.

Args go through as argv, not a shell — `tsvc x sh -c 'a; b'` if you need one.

### Interactive TUIs — k9s

A TUI you actively *watch* is the opposite case, and `tsvc` is wrong for it: it
detaches and sets `remain-on-exit`, so quitting k9s leaves a dead pane behind.
Use `k9` instead — one session per kube context:

```sh
k9              # current context
k9 staging      # a named one
```

Session per context rather than per window: re-attaching is instant because k9s
keeps its place in the resource tree, and a stray `C-c` lands in k9s instead of
the editor that would otherwise be split beside it. `C-a L` gets you back.

Naming is `k9s-<context>`, with an EKS arn cut to its last path segment, so
`ta k9s-prod` and tab-completion both work on it.

## Windows

| Key | Does |
| --- | --- |
| `C-a c` | new window in the current pane's cwd |
| `C-a C` | **task window** — prompts for a name, opens `nvim` left and `claude` right at 40% |
| `C-a Tab` | last window |
| `C-a n` / `C-a p` | next / previous window |
| `C-a M-n` / `C-a M-p` | next / previous window **with an alert** |
| `C-a ,` | rename window (prefills current) |
| `C-a w` | window tree |
| `C-a f` | find window by name |
| `C-a Q` | kill window (asks first) |

`C-a C` is the one to reach for when starting a piece of work: name it after the
task, and the window list becomes the to-do list.

## Panes

Navigation needs no prefix. Bare `C-h/j/k/l` is Vim- and fzf-aware: when the
pane's foreground program is nvim/vim or fzf the key is passed through
(`if-shell -F` on `#{pane_current_command}`, no `ps` fork), otherwise tmux
moves. Neovim's own `C-h/j/k/l` maps hop to the adjacent tmux pane at a window
edge (`init.lua`'s `win_or_tmux`), so the same keys walk splits and panes as one
grid; fzf keeps `C-j/C-k` for its list. `C-Space` and `C-\` get the same
treatment, so blink's manual-complete trigger and `:terminal`'s `C-\ C-n` exit
work inside tmux. Claude Code panes are deliberately not in the pattern — it
binds none of these keys, so passing them through would only strand you.
`C-a h/j/k/l` always moves, from anywhere.

| Key | Does |
| --- | --- |
| `C-h` `C-j` `C-k` `C-l` | move left/down/up/right (no prefix; Vim- and fzf-aware) |
| `C-\` | last pane |
| `C-Space` | next pane |
| `C-a h/j/k/l` | same moves, with prefix — the way out of any pane |
| `C-a s` or `C-a "` | split vertically (new pane below) |
| `C-a v` or `C-a %` | split horizontally (new pane right) |
| `C-a z` | zoom the pane — prefer this to resizing |
| `C-a i` | show pane numbers |
| `C-a !` | break the pane out into its own window |
| `C-a q` | kill pane, no confirmation (`C-a x` asks first) |
| `C-a m` | mark the pane for `swap-pane`/`join-pane` (stock tmux) |
| `C-a - = ( )` | resize by 10 cells (up / down / left / right) — this shadows stock `(`/`)` = previous/next **session**; use `C-a S` or `C-a L` instead |
| `C-a Enter` | **scratch shell** — a popup shell in this pane's cwd; any key dismisses it once the shell exits |
| `C-a e` | **broadcast** — toggle typing into every pane of this window |
| `C-a g` | **agent-log picker** — fzf over `~/.cache/agent-logs/`, newest first, Enter pages it in `less -R` |

## Agents

Claude Code runs in a pane like anything else.

| Key | Does |
| --- | --- |
| `C-a g` | page an agent log — fzf popup over `~/.cache/agent-logs/`, newest first |
| `C-a a` | **jump to a Claude** — fzf popup over `claude agents --json` (state, name, dir); picks the pane whose session it is |
| `C-a A` | open a **lead** Claude with tmux teammates, in a window of its own |

`~/.cache/agent-logs/` is the agreed drop for long command output. An agent that
runs something loud — a test suite, build, migration, benchmark — is instructed
(`~/.claude/CLAUDE.md`, and the `tmux-panes` skill) to put it in a window of its
own, tee it to `~/.cache/agent-logs/<job>.log`, and report a summary plus the
path rather than pasting the body back at you. `C-a g` is how you read it: a
popup costs no rows and closes on `q`. Nothing prunes that directory —
`rm ~/.cache/agent-logs/*` when it gets noisy.

A window and not a split, for the loud case: on a 120-column window one
`split-window` halves the pane you are reading the agent in, so splitting to fix
"I can't read this" makes it worse. A window costs nothing and is one `C-a Tab`
away.

`C-a A` is a separate window too. Agent teams are experimental and their tmux
backend runs `select-layout main-vertical` on whatever window the lead starts
in, which would flatten your editor window's layout. It passes
`--teammate-mode tmux` because the default flipped from `auto` to `in-process`,
so an explicit value is now required; the flag is hidden from `claude --help`
deliberately, not removed.

Keep to 2-3 teammates, and note which way it runs out: the backend splits
horizontally at 70% and then stacks teammates **vertically** in that right
column, so each gets `(height - 1) / N` rows. On a 50-row terminal three get
about 16 rows each and a fourth is unusable. Width is never the constraint.

### Knowing an agent wants you

A background agent that finished, or is waiting on a permission prompt, shows up
in two places without you looking:

- **the bell.** `.claude/settings.json` sets `preferredNotifChannel` to
  `terminal_bell` — Claude Code's desktop notifications cover Ghostty, Kitty and
  iTerm2 and there is no WezTerm channel, so the bell is the path that works
  here. The window goes pink in the list, and WezTerm and Ghostty flash and
  bounce the dock. `C-a M-n` / `C-a M-p` jump between alerting windows.
- **the badge.** Claude hooks run `~/.config/tmux/tmux-agent-state`, which sets a
  window option the window list renders: a red `!` means that window wants you
  (a permission prompt, an elicitation, or a session that died on an API
  error), a green `*` means it finished while you were elsewhere — "elsewhere"
  includes another session, not just another window. Moving to the window
  clears it, by `C-a n` and by a session switch alike; so does the session
  ending. `monitor-activity` stays off — an agent streams output continuously,
  so activity flagged every agent window permanently and meant nothing.
- **the pane border.** Every pane's border shows its title: Claude Code writes
  its current task there, Neovim its file, and a shell its directory (or the
  running command). So a glance at a window says what each pane is doing.
- **the window list.** A window whose active pane is a Claude shows 󱚝 and the
  agent's live title instead of the window name (its `pane_current_command` is
  Claude's version string, which nothing else looks like). A green `*` only
  appears when the agent has nothing running in the background — a `Stop`
  with background tasks still going is not "done".
- **session names.** A `SessionStart` hook names every session `<repo>@<branch>`
  (unless you `/rename`d it), so `claude -r dotfiles@main` resumes by name and
  `C-a a` shows something readable. `terminalTitleFromRename` is off so the
  pane border keeps the live task title rather than the name.

Hook edits in `settings.json` are picked up by a running `claude` within a few
seconds (it watches the file); only a hook that never appears needs a restart.

Resuming after a restart: Claude's `SessionStart` hook stores each session's id
on its tmux pane (`@claude_session`), the snapshot records it, and `C-a V` puts
the directories back **and types `claude -r <id>` into every pane that held an
agent** — unsent, so nothing runs until you press Enter. (`claude -c` resumes
"the most recent in this cwd", which is the wrong one as soon as two panes
share a directory.) Agent teams do not resume.

When an agent needs you, the same hook that badges the window also sends a
desktop notification through WezTerm (OSC 777, forwarded by
`allow-passthrough all` even from a window you are not looking at). macOS shows
it when WezTerm is not the frontmost app — the case it exists for; inside
WezTerm the badge and bell are the signal. Needs System Settings → Notifications
→ WezTerm set to Banners (it was None here, and every toast was silently
recorded and never shown).

## Sessions that survive the server

`C-a V` puts your sessions back after a reboot or a `tmux kill-server`. There is
no plugin manager here; `~/.config/tmux/tmux-snapshot` is a POSIX shell script
the config shells out to.

| Key | Does |
| --- | --- |
| `C-a W` | write a snapshot now |
| `C-a V` | revive every session in the snapshot that is not already open |

A snapshot records session names, window indexes and names, each window's layout
string, and every pane's working directory. It deliberately does **not** record
the commands that were running — that is how resurrect-style tools end up
re-running a migration at you on login. Panes come back as shells in the right
directory, and you restart what you meant to restart.

Saving is automatic, driven by tmux hooks — `session-created`, `session-closed`,
`session-renamed`, `window-linked`, `window-unlinked`, `window-renamed`,
`pane-exited` and `client-detached`. `window-layout-changed` is deliberately not
among them: it fires once per `resize-pane` step, so holding a resize key would
write a snapshot per keystroke. `client-detached` is the catch-all for layout
and cwd drift instead.

Three things keep an autosave from destroying what you want back:

- the snapshot file is **scoped to its tmux server**. Every tmux on this machine
  loads this config, so a throwaway `tmux -L scratch` would otherwise take over
  your real snapshot. The default server writes `snapshot`; anything else writes
  `snapshot.<socket>`, and a non-default server never autosaves at all.
- it **refuses to record a server smaller than the file on disk** until that
  server has been restored or explicitly saved. `C-a W` still writes whatever is
  there, and re-arms the guard.
- the previous snapshot is kept beside it as `snapshot.prev`.

Window names are recorded only when you set them. A window still on
`automatic-rename` is stored as `~auto~`, because its "name" is whatever command
happens to be running — a snapshot taken mid-`git push` recorded the window as
`git`, and restoring that name turned automatic renaming off for good.

Both files live under `~/.local/state/tmux/`. `C-a V` never touches a session
that already exists, so it is safe to press twice — but press it **before**
rebuilding sessions by hand with `ta`, or it will skip the ones you recreated.

## Copy and paste

**Selecting is inert; copying is an act.** Stock tmux binds
`copy-pipe-and-cancel` to mouse drag-release *and* to double- and triple-click,
and `set-clipboard` is `external`, so each of those reaches the macOS clipboard
over OSC 52. The effect is that a stray drag in the pane you are about to paste
*into* silently overwrites what you just copied. Rebound here so the mouse only
ever highlights, in both mouse tables.

| Key | Does |
| --- | --- |
| `C-a [` | enter copy mode (vi keys, `/` and `?` to search) |
| `v` | start selecting |
| mouse drag | select — stays in copy mode, clipboard untouched |
| double / triple click | select word / line — again, no copy |
| **`y`** | copy the selection to the macOS clipboard, then leave copy mode |
| `D` | copy to end of line, same path as `y` |
| `Escape` | drop the highlight, stay in copy mode |
| `q` or `C-c` | leave copy mode without copying |
| `C-a ]` | paste tmux's buffer into a pane |

So: select however you like (mouse or `v`), press **`y`**, then **`Cmd+V`** to
paste anywhere, including outside the terminal. Nothing you do with the *mouse*
afterwards can overwrite it. `A` (append to buffer) is unbound, because with
`set-clipboard external` it reached the system clipboard too.

There is a second layer. With `mouse on` tmux owns the mouse, but **Shift** is
the mouse-reporting bypass, so a Shift-drag is handled by the *terminal* — and
terminals copy on select by default. That is turned off in the terminal configs
too, so a Shift-drag highlights without copying and `Cmd+C` is the deliberate
act.

`y` fills the tmux buffer as well, so `C-a ]` pastes the same text back into a
pane without touching the system clipboard.

Pane navigation (`C-h/j/k/l`, `C-\`, `C-Space`) works inside copy mode, so you
can leave a selection highlighted, look at another pane, and come back. At the
bottom of the scrollback a plain click leaves copy mode; scrolled back it does
nothing, so reading history keeps its place.

## Config

`C-a r` reloads `~/.tmux.conf` and says so.

A reload cannot re-evaluate an **attached client**, so a change to
`terminal-features` or `extended-keys` does not take until you detach and
reattach — `C-a d`, then `tmux attach`. Never `tmux kill-server` for this: it
takes every session on the machine with it. Check what the client negotiated:

```sh
tmux display-message -p '#{client_termfeatures}'
```

`~/.tmux.conf.local` is sourced last and is untracked — the tmux twin of
`~/.gitconfig.local` and `~/.zshenv.local`, seeded by `install.sh`. Machine- or
host-specific settings belong there, because `~/.tmux.conf` is a symlink into a
public repo. It is also where the platform split goes: `y` pipes to `pbcopy`,
which is macOS-only. `%if` cannot help — it is evaluated at parse time while
`#()` is asynchronous, so `%if "#{==:#(uname),Darwin}"` takes the *else* branch
on macOS.

This is stock tmux plus `fzf` — no plugin manager, nothing to install.

tmux 3.8 (unreleased as of Aug 2026) makes `mouse` default on, binds `Tab` to a
new `switch-mode` (this config's `bind Tab last-window` still wins), and turns
hooks into events with payloads — `set-hook -B` and OSC 133
`pane-command-finished` could then replace the bell-driven badge for plain
shells. Nothing here needs to change for it.
