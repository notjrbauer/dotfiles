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
| `C-a C-q` | kill the whole session |

`C-a S` opens an fzf popup over your live sessions: type to filter, Enter to switch,
`ctrl-x` to kill the highlighted one (it refuses the session you're attached to). The
right pane previews that session's windows. The session you came from sits under the
cursor, so `C-a S Enter` is a fast toggle. Without `fzf` installed it falls back to
tmux's own `choose-tree`.

From the shell, outside or inside tmux:

| Command | Does |
| --- | --- |
| `ta [name]` | attach to `name`, creating it if needed; defaults to the **git repo root's** basename |
| `ts` / `^S` | fzf picker over live sessions — `^S` is the keybinding, `C-r` for sessions |
| `tkill [name…]` | kill sessions by exact name; defaults to the current dir's basename |
| `tsvc <name> <cmd> [args…]` | park a long-running command in its own detached session |

`ta` is the normal entry point: `cd` anywhere inside a project, run `ta`, and you
get a session named after the **repo root** — the same name from any depth, so it
reattaches instead of piling up duplicates (a bare directory basename would make
`.config/zsh` its own `zsh` session). `.` and `:` in a name become `_`, because
tmux reads them as window/pane separators and a session containing them cannot be
targeted or killed afterwards.

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
| `C-a C-h` / `C-a C-l` | previous / next window (repeatable — hold the ctrl key) |
| `C-a ,` | rename window (prefills current) |
| `C-a w` | window tree |
| `C-a f` | find window by name |
| `C-a Q` | kill window |

`C-a C` is the one to reach for when starting a piece of work: name it after
the task, and the window list becomes the to-do list.

Careful: **`C-a C-h`/`C-a C-l` move windows, bare `C-h`/`C-l` move panes.**

## Panes

Navigation needs no prefix. Bare `C-h/j/k/l` is Vim- and fzf-aware, so the same
keys move between Neovim splits, through an fzf list, and across tmux panes
without thinking about which one has focus.

| Key | Does |
| --- | --- |
| `C-h` `C-j` `C-k` `C-l` | move left/down/up/right (no prefix; Vim- and fzf-aware) |
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
| `C-a u` | **URL picker** — fzf over every URL in this pane's scrollback, Enter opens it (Tab multi-selects) |

Resizing, when a zoom won't do: `C-a -` `=` `(` `)` nudge by 10 cells, or
`C-a R` for sticky resize mode — then `h/j/k/l` repeatedly, `Escape` or `q` to
leave.

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
anywhere — including outside the terminal. `y` is the only path to the clipboard
from tmux, so nothing you do with the mouse afterwards can overwrite it. A
mouse-made selection works with `y` exactly like a `v`-made one.

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

`C-a r` (or `C-a C-r`) reloads `~/.tmux.conf` and says so.

This is stock tmux plus `fzf` — no plugin manager, nothing to install.
