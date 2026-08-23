# tmux

Prefix is **`C-a`** (`.tmux.conf`). The terminals deliberately bind SUPER-only
chords and no ctrl keys, so `C-a` reaches tmux on a single tap. Windows and
panes are numbered from **1**.

Three layers, and the point of each here:

| Layer | Holds | Rule of thumb |
| --- | --- | --- |
| **Session** | one project or task, plus long-lived services | switch, don't stack |
| **Window** | one unit of work inside that project | the window list is the WIP limit |
| **Pane** | the editor / agent / shell of that unit | zoom, don't resize |

## Sessions

One session per project, so `cd`-ing around is replaced by switching. A second
kind of session exists for things that just need to keep running (below).

| Key | Does |
| --- | --- |
| `C-a S` | **fuzzy session picker** — `C-r`, but for sessions. The main way to move |
| `C-a C-s` | new session, prompts for a name, inherits the current pane's cwd |
| `C-a L` | last session (the toggle you'll use most) |
| `C-a N` / `C-a P` | next / previous session |
| `C-a $` | rename session (prefills current) |
| `C-a d` | detach — leaves everything running |
| `C-a D` | choose which client to detach |
| `C-a C-q` | kill the whole session — **asks first**, and lands you in the next session rather than dropping you out of tmux |

`C-a S` opens an fzf popup over your live sessions: type to filter, Enter to switch,
`ctrl-x` to kill the highlighted one (it refuses the session you're attached to). The
right pane previews that session's windows. The session you came from sits under the
cursor, so `C-a S Enter` is a fast toggle. Without `fzf` installed it falls back to
tmux's own `choose-tree`.

From the shell, outside or inside tmux:

| Command | Does |
| --- | --- |
| `ta [name]` | attach to `name`, creating it if needed; defaults to the **main repo root's** basename |
| `tw <branch>` | git worktree + session for that branch, named `<repo>-<branch>` |
| `ts` / `^S` | fzf picker over live sessions — `^S` is the keybinding, `C-r` for sessions |
| `tkill [name…]` | kill sessions by exact name; with no args resolves the same name as `ta` |
| `tsvc <name> <cmd> [args…]` | park a long-running command in its own detached session |

`ta` is the normal entry point: `cd` anywhere inside a project, run `ta`, and you
get a session named after the **main repo root** — the same name from any depth,
so it reattaches instead of piling up duplicates (a bare directory basename would
make `.config/zsh` its own `zsh` session). It resolves that through
`git rev-parse --git-common-dir`, not `--show-toplevel`, so a **linked worktree
still names its session after the repo**: `--show-toplevel` returns the worktree
directory, which lost the repo name entirely and let a `fix-tests` worktree in two
different projects collide onto one session.

`tw <branch>` is the worktree entry point: it creates `<repo>__worktrees/<branch>`
beside the repo (never inside it, so the main checkout's `git status` stays clean),
creates or reuses the branch, and opens a session called `<repo>-<branch>` — so
every worktree of one project sorts together under its prefix in `C-a S`. A
worktree is a checkout, not a copy: gitignored files do not come along, so `.env`,
`node_modules` and `.venv` are missing until you put them there, and an agent will
fail on its first command without them.

`.` and `:` in any name become `_` — `C-a C-s` and `C-a C` sanitize what you type
too — because tmux reads them as session/window/pane separators and a name
containing them cannot be targeted or killed afterwards.

Two ways to the picker, deliberately: `C-a S` inside tmux, and `^S` at a shell
prompt — which also works when no server is running yet, where there's no prefix
to press.

### Long-running commands

A VPN client, tunnel, watcher, or log tail that must hold a terminal all day
does not want to be a split in a working window — it eats space, and a `C-a q`
aimed at a work pane can take it out.

```sh
tsvc vpn vpn connect --env staging     # starts detached, returns immediately
ta vpn                                 # look at it
```

`tsvc` is idempotent: run it again and it tells you the session is already up
rather than starting a second copy. The session keeps `remain-on-exit on`, so a
command that dies leaves the pane as `Pane is dead (status N)` with its
scrollback intact instead of vanishing along with the error — and `tsvc` will
restart a dead one in place. Note that an existing session is therefore *not*
proof the command is still running; check the pane.

`C-a T` jumps to (or creates) a session named `tunnel` for this same purpose,
with no arguments to type.

Args go through as argv, not a shell — `tsvc x sh -c 'a; b'` if you need a
shell.

### Interactive TUIs — k9s

A TUI you actively *watch* is the opposite case, and `tsvc` is the wrong tool for
it: `tsvc` detaches and sets `remain-on-exit`, so every time you quit k9s you'd
leave a dead pane behind. Use `k9` instead — one session per kube context:

```sh
k9              # current context
k9 staging      # a named one
```

Session per context rather than per window, for two reasons: re-attaching is
instant because k9s keeps its place in the resource tree, and a stray `C-c` lands
in k9s instead of the editor that would otherwise be split beside it. Get back to
what you were doing with `C-a L` (last session) — the pair of them is a two-key
round trip.

Naming is `k9s-<context>`, with an EKS arn cut down to its last path segment, so
`ta k9s-prod` and tab-completion both work on it.

## Windows

| Key | Does |
| --- | --- |
| `C-a c` | new window in the current pane's cwd |
| `C-a C` | **task window** — prompts for a name, opens `nvim` left and `claude` right at 40% |
| `C-a Tab` | last window |
| `C-a C-h` / `C-a C-l` | previous / next window |
| `C-a ,` | rename window (prefills current) |
| `C-a w` | window tree |
| `C-a f` | find window by name |
| `C-a Q` | kill window |

`C-a C` is the one to reach for when starting a piece of work: name it after
the task, and the window list becomes the to-do list.

Careful: **`C-a C-h`/`C-a C-l` move windows, bare `C-h`/`C-l` move panes.** Those
two used to be `bind -r`, which kept the prefix table armed for 500ms afterwards
and swallowed the *next* bare `C-h` into a window move. Press the prefix again
instead; pane navigation now always means pane navigation.

## Panes

Navigation needs no prefix. Bare `C-h/j/k/l` is Vim- and fzf-aware, so the same
keys move between Neovim splits, through an fzf list, and across tmux panes
without thinking about which one has focus.

| Key | Does |
| --- | --- |
| `C-h` `C-j` `C-k` `C-l` | move left/down/up/right (no prefix; Vim-aware, and fzf-aware on `C-j`/`C-k`) |
| `C-\` | last pane |
| `C-Space` | next pane |
| `C-a h/j/k/l` | same moves, with prefix |
| `C-a s` or `C-a "` | split vertically (new pane below) |
| `C-a v` or `C-a %` | split horizontally (new pane right) |
| `C-a z` | zoom the pane — prefer this to resizing |
| `C-a i` | show pane numbers |
| `C-a b` | break the pane out into its own window |
| `C-a q` | kill pane |
| `C-a m` | open a man page in a split |
| `C-a F` | **which-key palette** — a menu of the everyday bindings, for when you forget one |
| `C-a u` | **URL picker** — fzf over every URL in this pane's scrollback, Enter opens it (Tab multi-selects) |
| `C-a O` | **path picker** — fzf over every path in the scrollback that really exists; Enter opens it in nvim, at `:LINE` if one was printed |
| `C-a G` | **git picker** — fzf over the working tree with a real diff preview; Enter opens the file in its own window |
| `C-a Enter` | **scratch shell** — a popup shell in this pane's cwd; `Escape` dismisses it |
| `C-a e` | **broadcast** — toggle typing into every pane of this window |
| `C-a g` | **agent-log picker** — fzf over `~/.cache/agent-logs/`, newest first, Enter pages it in `less -R` |

`C-a u` and `C-a O` read the pane's **scrollback**, which a full-screen TUI does
not have: Claude Code's fullscreen renderer draws on the alternate screen, where
tmux keeps no history, so both pickers see one screen of a Claude pane and
usually say "no URLs in this pane". `C-o` (transcript mode) then `[` writes the
conversation into real scrollback where they can see it; `/tui default` or
`CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` fixes it for good.

Resizing, when a zoom won't do: `C-a -` `=` `(` `)` nudge by 10 cells, or
`C-a R` for sticky resize mode — then `h/j/k/l` repeatedly, `Escape` or `q` to
leave.

## Agents

Claude Code runs in a pane like anything else, but two conventions keep its
output out of your scrollback.

| Key | Does |
| --- | --- |
| `C-a g` | page an agent log — fzf popup over `~/.cache/agent-logs/`, newest first |
| `C-a A` | open a **lead** Claude with tmux teammates, in a window of its own |
| `C-a a` | **ask Claude** — one question in a popup, answered in the pane's cwd, no layout touched |

`C-a a` is the throwaway sibling of `C-a A`: type a question, read the answer,
press `q`. It runs `claude -p` in the current pane's directory, so "what does
this script do" has the right context.

It is deliberately **not** an interactive Claude. A popup has no pane id — it
does not appear in `list-panes` at all — so nothing that makes an agent
manageable here applies to it: no `@agent` badge, no `C-h/j/k/l` into it, no
`capture-pane`, no place in a snapshot. It belongs to the client, so it dies
when you detach, and it cannot be zoomed or left running. An agent you want to
come back to is a pane: `C-a C` for a task window, `C-a A` for a team.

`~/.cache/agent-logs/` is the agreed drop for long command output. An agent that
runs something loud — a test suite, build, migration, benchmark — is instructed
(`~/.claude/CLAUDE.md`, and the `tmux-panes` skill) to put it in a window of its
own, tee it to `~/.cache/agent-logs/<job>.log`, and report a summary plus the
path rather than pasting the body back at you. `C-a g` is how you then read it:
a popup costs no rows, floats over the whole window, and closes on `q`. Nothing
prunes that directory — `rm ~/.cache/agent-logs/*` when it gets noisy.

Why a window and not a split, for the loud case: on a 120-column window one
`split-window` halves the pane you are reading the agent in, so splitting to fix
"I can't read this" makes it worse. A window costs nothing and is one `C-a Tab`
away.

`C-a A` is deliberately a separate window too. Agent teams are experimental and
their tmux backend runs `select-layout main-vertical` on whatever window the lead
starts in, which discards that window's layout — from your editor window it would
flatten what you were working in.

It passes `--teammate-mode tmux` rather than `auto` because **the default flipped
from `auto` to `in-process`**, so an explicit value is now required. (An earlier
version of this file said `auto` fails because `$TMUX` is empty inside Claude's
own process. That is false — a pane command sees `$TMUX` normally. The
empty-`$TMUX` rule elsewhere is about a *tool subprocess*, and is not true there
either.) The flag is hidden from `claude --help` deliberately, not removed.

Keep to 2-3 teammates, and note which way it runs out: the backend splits
horizontally at 70% and then stacks teammates **vertically** in that right
column, so each gets `(height - 1) / N` rows. On a 50-row terminal three get
about 16 rows each and a fourth is unusable. Width is never the constraint.

### Knowing an agent wants you

A background agent that finished, or is waiting on a permission prompt, shows up
in two places without you looking for it:

- **the bell.** `.claude/settings.json` sets `preferredNotifChannel` to
  `terminal_bell` — Claude Code's desktop notifications cover Ghostty, Kitty and
  iTerm2 and there is no WezTerm channel, so the bell is the path that works
  here. `monitor-bell` is on, so the window goes pink in the list, and WezTerm
  and Ghostty are already configured to flash and bounce the dock.
  `C-a M-n` / `C-a M-p` jump to the next/previous window with an alert.
- **the badge.** Claude hooks run `~/.config/tmux/tmux-agent-state`, which sets a
  window option the window list renders: a red `!` means that window wants you, a
  green `*` means it finished while you were elsewhere. Moving to the window
  clears it. `monitor-activity` is deliberately **off** — an agent streams output
  continuously, so activity flagged every agent window permanently and meant
  nothing.

Hooks are read when `claude` starts, so a change to `settings.json` does nothing
to an agent already running.

Resuming after a restart: `claude -c` continues the most recent conversation **in
the current directory**, and a snapshot restores every pane's directory — so
`C-a V` puts the directories back and you type `claude -c` in the pane that held
an agent. Nothing is recorded and nothing is re-executed; the resume stays an
explicit act, like restarting a dev server. Agent teams do not resume.

## Sessions that survive the server

`C-a V` puts your sessions back after a reboot or a `tmux kill-server`. There
is no plugin manager here; `~/.config/tmux/tmux-snapshot` is a POSIX shell
script the config shells out to.

| Key | Does |
| --- | --- |
| `C-a W` | write a snapshot now |
| `C-a V` | revive every session in the snapshot that is not already open |

A snapshot records session names, window indexes and names, each window's
layout string, and every pane's working directory. It deliberately does **not**
record the commands that were running. Restoring those is how resurrect-style
tools end up re-running a migration at you on login; panes come back as shells
in the right directory, and you restart what you meant to restart.

Saving is automatic, driven by **tmux hooks** — `session-created`,
`session-closed`, `session-renamed`, `window-linked`, `window-unlinked`,
`window-renamed`, `pane-exited` and `client-detached`. So the save happens when
the shape actually changes, rather than up to a status interval afterwards.

> This used to ride a `#(…)` on `status-right`, described here as "the only
> periodic hook a config without a plugin manager gets". tmux 3.5 made that
> false. The old description was wrong twice more, which is worth knowing if you
> ever go back to a poll: `status-interval` is a *floor*, not a rate — tmux
> re-expands `status-right` on every status redraw, measured at 9 calls in 9
> seconds — and the snapshot rotated on far more than opening or closing
> something, because a terminal resize, a bare `cd`, and attaching a client all
> change the recorded shape.

`window-layout-changed` is deliberately **not** in that list: it fires once per
`resize-pane` step, so holding `j` in `C-a R` resize mode would have written a
snapshot per keystroke. `client-detached` is the catch-all for layout and cwd
drift instead.

Three things keep an autosave from destroying what you want back:

- the snapshot file is **scoped to its tmux server**. Every tmux on this machine
  loads this same config, so a throwaway `tmux -L scratch` used to take
  ownership of your real snapshot within one status tick — and then push the
  junk into the backup too. The default server writes `snapshot`; anything else
  writes `snapshot.<socket>`, and a non-default server never autosaves at all.
- it **refuses to record a server smaller than the file on disk** until that
  server has been restored or explicitly saved. Refusing only a *one-pane*
  server was not enough: two keystrokes after a crash — one split, or one
  `C-a C` — and the old guard let a snapshot of ten sessions be replaced by one
  of one. `C-a W` still writes whatever is there, and re-arms the guard.
- the previous snapshot is kept beside it as `snapshot.prev`.

Window names are recorded only when you set them. A window still on
`automatic-rename` is stored as `~auto~`, because its "name" is whatever command
happens to be running — a snapshot taken mid-`git push` recorded the window as
`git`, and restoring that name turned automatic renaming off for good.

Both files live under `~/.local/state/tmux/`. `C-a V` never touches a session
that already exists, so it is safe to press twice, and safe when only some of
your sessions are gone — but press it **before** rebuilding sessions by hand
with `ta`, or it will skip the ones you already recreated.

The one thing it cannot save you from is a config reload: a `terminal-features`
or `extended-keys` change needs a detach and reattach, **not** a `kill-server` —
see Config below.

## Copy and paste

**Selecting is inert; copying is an act.** Stock tmux binds `copy-pipe-and-cancel`
to mouse drag-release *and* to double- and triple-click, and `set-clipboard` is
`external` — so tmux forwards each of those to the macOS clipboard over OSC 52. No
plugin is involved; that is tmux out of the box. The effect is that a stray drag in
the pane you are about to paste *into* silently overwrites what you just copied.
Rebound here so the mouse only ever highlights, in both mouse tables, and the
right-click menu (whose "Copy" rows do the same thing) no longer opens on a plain
two-finger tap.

| Key | Does |
| --- | --- |
| `C-a [` | enter copy mode (vi keys, `/` and `?` to search) |
| `v` | start selecting |
| mouse drag | select — stays in copy mode, clipboard untouched |
| double / triple click | select word / line — again, no copy |
| **`y`** | copy the selection to the macOS clipboard, then leave copy mode |
| `Escape` | drop the highlight, stay in copy mode |
| `q` or `C-c` | leave copy mode without copying |
| `C-a ]` | paste tmux's buffer into a pane |

So the flow that answers "how do I select without clobbering my buffer":
select however you like (mouse or `v`), press **`y`**, then **`Cmd+V`** to paste
anywhere — including outside the terminal. Nothing you do with the *mouse*
afterwards can overwrite it. A mouse-made selection works with `y` exactly like a
`v`-made one.

`y` is not quite the only keyboard path, and this file used to claim it was:
copy-mode ships `D` (copy to end of line) and `A` (append to the buffer), and
because `set-clipboard` is `external` both reached the system clipboard as well.
`D` now pipes through `pbcopy` like `y`; `A` is unbound.

There is a second layer to know about. With `mouse on`, tmux owns the mouse — but
**Shift** is the mouse-reporting bypass, so a Shift-drag is handled by the *terminal*
instead, and terminals copy on select by default (WezTerm completes every left-button
release to the clipboard; Ghostty's `copy-on-select` defaults to on). That path is
turned off in the terminal configs too, so a Shift-drag highlights without copying
and `Cmd+C` is the deliberate act.

`y` fills the tmux buffer too, so `C-a ]` pastes the same text back into a pane
without touching the system clipboard.

Prefer `y` regardless — it is one keystroke and it works the same in every pane.

Pane navigation (`C-h/j/k/l`, `C-\`, `C-Space`) also works inside copy mode, so
you can leave a selection highlighted, look at another pane, and come back.

## Config

`C-a F` opens a **which-key palette** — a themed `display-menu` of the everyday
bindings, for when you know the thing exists but not the key. It is additive:
the letter shown is the real binding, so the palette teaches the key instead of
replacing it. Nothing destructive is on it (`q`, `Q`, `C-a C-q` are deliberately
absent — a menu is mouse-clickable and the pointer can land on a row you did not
read), and the five fzf popups are not on it either, because each is a small
shell program and a second copy in a menu is a second copy to keep correct.
`C-a ?` remains the complete list.

`C-a r` (or `C-a C-r`) reloads `~/.tmux.conf` and says so.

One thing a reload cannot do is re-evaluate an **attached client**, so a change
to `terminal-features` (see the block in `.tmux.conf`) does not take until you
detach and reattach — `C-a d`, then `tmux attach`. Never `tmux kill-server` for
this: it takes every session on the machine with it, and a reattach is enough.
Check what the client actually negotiated with:

```sh
tmux display-message -p '#{client_termfeatures}'
```

`~/.tmux.conf.local` is sourced last and is untracked — the tmux twin of
`~/.gitconfig.local` and `~/.zshenv.local`, seeded by `install.sh`. Machine- or
host-specific settings belong there, because `~/.tmux.conf` is a symlink into a
public repo. It is also where the platform split goes: `y` pipes to `pbcopy` and
the URL picker calls `open`, both macOS-only. `%if` cannot help — it is
evaluated at parse time while `#()` is asynchronous, so `%if
"#{==:#(uname),Darwin}"` takes the *else* branch on macOS.

This is stock tmux plus `fzf` — no plugin manager, nothing to install.
