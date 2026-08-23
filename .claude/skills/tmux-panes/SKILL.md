---
name: tmux-panes
description: Run a command in a tmux session, window, split, or popup and read its output back. Use whenever a command's output is long enough to be worth scrolling — a test suite, build, lint, plan, migration, or benchmark — as well as for a dev server, watcher, tunnel, log tail, or interactive TUI that must outlive a single tool call, when the user asks to see something running live, or when driving a TUI with send-keys. Covers the exact invocations, the -d flag, capture-pane read-back, popups, and the rules for not disturbing panes you did not create.
---

# Running things in tmux

| The thing… | Goes in |
| --- | --- |
| runs and exits, output is short | `run_in_background` — not tmux |
| runs and exits, output is long or worth scrolling | its own window, tee'd to a log under `~/.cache/agent-logs/` |
| must keep running, nobody needs to watch | its own detached session |
| is worth watching happen, or they asked to see it | a split beside them, in their window |
| is a whole parallel workstream | its own session; then tell them the name |
| is a log they want to page through *now* | a backgrounded `display-popup` over the log file |

`$TMUX` and `$TMUX_PANE` **are** populated inside Bash calls — measured:
`TMUX=/private/tmp/tmux-501/default,<pid>,0`, `TMUX_PANE=%1`. What matters is
what they point at: the user's live attached server, and a pane you did not
create. So never target `-t "$TMUX_PANE"` — not because it expands to `-t ""`,
but because it expands to *their* pane. Omit `-t` to mean "the active pane" on
purpose, or resolve an id first:

```sh
tmux list-panes -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{pane_current_command}'
```

Shell state does not survive between Bash calls either, so a `pane=$(...)`
capture is dead by the next call — print the `%N` id, then paste it literally
into the commands that follow. Bindings and layout: `docs/tmux.md` in the
dotfiles repo.

## Long-running and unattended — its own session

Guard on the name so a re-run doesn't spawn a twin, and use `=` for an exact
match (a bare `-t x` also matches `xy`):

```sh
tmux has-session -t '=agent-<repo>-<job>' 2>/dev/null ||
  tmux new-session -d -s 'agent-<repo>-<job>' -c /abs/dir '<cmd>'
```

`-d` is not optional: a tool call has no terminal, so `attach` fails (`open
terminal failed: not a terminal`) and a plain `new-session` refuses to nest.
The `tsvc` helper wraps this with `remain-on-exit` and restarts a dead one in
place — it's a zsh function, so reach it as `zsh -ic 'tsvc <name> <cmd>'`.

## The user wants to watch it — split next to yourself

With no `-t` this splits the active pane — the one they are reading you in — so
it lands in their current window with no index guessing, and `-d` leaves their
cursor where it was. `-P -F` prints the new pane's id:

```sh
tmux split-window -d -h -l 40% -c /abs/dir -P -F '#{pane_id}' '<cmd>'
# prints e.g. %7 — paste that literal id into the commands below
```

A split resizes their window, which is fine; that is what the window is for.
Use one whenever the output deserves a screen of its own, and say that the pane
appeared and how to reach it. Check the width first, though: below ~160 columns
a `-h` split leaves both halves too narrow for wrapped output or a table, so
prefer a new window there.

```sh
tmux display-message -p '#{window_width}x#{window_height}'
```

To drive an interactive TUI in a pane **you** created:
`tmux send-keys -t %7 '<keys>' Enter`, then capture.

## Short-lived but loud — a window you read and close

A one-shot command with a lot of output — a test suite, build, lint, plan,
migration, benchmark — goes in a window, not a split. A split takes rows off the
pane they are reading you in; a window takes none, and they reach it with
`prefix Tab` or `prefix w`.

```sh
tmux new-window -d -n <job> -c /abs/dir -P -F '#{pane_id}' \
  'sh -c "<cmd> 2>&1 | tee ~/.cache/agent-logs/<job>.log"'
```

Poll until the pane is gone (`tmux list-panes -a -F '#{pane_id}' | grep -q %7`),
then read the **log**, not the capture — the pane dies with the command and the
capture is bounded by the pane height. Report the summary and the log path; do
not paste the body into the transcript.

## Page it right now — a popup

A popup is the surface for "read this log, then get out of my way": it floats
over the whole window at whatever size you ask, costs no rows, and vanishes on
`q`. It is modal, so it fits reading — never a persistent process.

```sh
tmux run-shell -b "tmux display-popup -E -w 90% -h 85% -T ' <job> ' \
  'less -R ~/.cache/agent-logs/<job>.log'"
```

`run-shell -b` is load-bearing: a foreground `display-popup -E` running an
interactive pager blocks the tool call until a human presses `q`, which is
indistinguishable from a wedged command. Backgrounded it returns in
milliseconds. A popup running a command that *exits on its own* is safe in the
foreground — `display-popup -E -w 20% -h 3 'sleep 1'` returns `rc=0` — but
prefer `-b` and you never have to make the distinction.

`-E` closes the popup when the command exits; without it the user is stuck with
a dead popup. `-T ' title '` labels it. Tilde expands in both the `tee` and the
popup forms above — verified, not assumed.

**A popup needs an attached client.** On a server with nobody attached it fails
silently: `run-shell -b` swallows the error, the command inside never runs, and
you get no output and no exit code to notice. So a popup is only ever for the
user's live session — never for a `tmux -L <scratch>` server, and never as a way
to run something you need the result of. Use a window for that.

The user also has `prefix g`, an fzf popup over `~/.cache/agent-logs/`, so naming
the log well is the handoff.

## Read it back with `capture-pane -p`

Without the read-back a detached pane is a black hole; without the `-p` you
hijack the user's clipboard — plain `capture-pane` pushes the dump onto the
paste-buffer stack, so their next paste inserts your screen scrape. Target the
`%N` id printed above: pane and window *indices* shift with `base-index` and
will quietly hit the wrong thing.

```sh
tmux capture-pane -p -J -t %7          # -J unwraps wrapped lines
tmux capture-pane -p -J -S -200 -t %7  # with scrollback
```

A pane dies with its command and takes the output with it, so tee anything you
need afterwards: `'<cmd> 2>&1 | tee ~/.cache/agent-logs/<job>.log'`.
`remain-on-exit` is no substitute — a dead pane captures as `Pane is dead
(status N)`, not as your output. `~/.cache/agent-logs/` is the agreed scratch
dir; `prefix g` pages anything in it.

## Don't disturb what you didn't create

`new-window` / `split-window` default to the *current* session and select what
they create, so always pass `-d`. **Never `send-keys` into a pane you did not
create** — only into one whose `%N` you printed yourself.

Experiments that need to change server state go on a private socket —
`tmux -L <name> …` — and you kill only that: `tmux -L <name> kill-server`.
Pick a name nothing else uses: **`-L default` is not isolation, it is the
user's live server**.

Never run a popup with an interactive pager in the foreground (above), and never
`set-option -g` on the user's server to make something work — their `.tmux.conf`
is the source of truth and a runtime override silently diverges from it.

## Clean up, then report

Kill sessions you created. If you leave one up, name it and hand over the
`capture-pane` line that reads it; the user gets there with `prefix S` (session
picker) or `prefix w` (window tree).
