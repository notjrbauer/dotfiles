---
name: tmux-panes
description: Run a command in a tmux session, window, or split and read its output back. Use when starting a dev server, watcher, tunnel, log tail, or interactive TUI that must outlive a single tool call, when the user asks to *see* something running live, or when driving an interactive TUI with send-keys. Covers the exact invocations, the -d flag, capture-pane read-back, and the rules for not disturbing panes you did not create.
---

# Running things in tmux

`$TMUX` is set inside Bash calls — this machine lives in tmux, and you are
already inside the user's attached session, in the pane `$TMUX_PANE`.
Bindings and layout: `docs/tmux.md` in the dotfiles repo.

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

`$TMUX_PANE` is your own pane, so this lands in their current window with no
index guessing, and `-d` leaves their cursor where it was:

```sh
pane=$(tmux split-window -d -h -l 40% -t "$TMUX_PANE" \
         -c /abs/dir -P -F '#{pane_id}' '<cmd>')
```

This resizes their window, so do it when they asked to see something — not for
your own bookkeeping — and say that the pane appeared. To drive an interactive
TUI in a pane **you** created: `tmux send-keys -t "$pane" '<keys>' Enter`, then
capture.

## Read it back with `capture-pane -p`

Without the read-back a detached pane is a black hole; without the `-p` you
hijack the user's clipboard — plain `capture-pane` pushes the dump onto the
paste-buffer stack, so their next paste inserts your screen scrape. Target the
`%N` id you captured above: pane and window *indices* shift with `base-index`
and will quietly hit the wrong thing.

```sh
tmux capture-pane -p -J -t "$pane"          # -J unwraps wrapped lines
tmux capture-pane -p -J -S -200 -t "$pane"  # with scrollback
```

A pane dies with its command and takes the output with it, so tee anything you
need afterwards: `'<cmd> 2>&1 | tee /abs/scratch/job.log'`. `remain-on-exit` is
no substitute — a dead pane captures as `Pane is dead (status N)`, not as your
output.

## Don't disturb what you didn't create

`new-window` / `split-window` default to the *current* session and select what
they create, so always pass `-d` and an explicit `-t`. Experiments that need to
change server state go on a private socket — `tmux -L <name> …` — and you kill
only that: `tmux -L <name> kill-server`.

## Clean up, then report

Kill sessions you created. If you leave one up, name it and hand over the
`capture-pane` line that reads it; the user gets there with `prefix S` (session
picker) or `prefix w` (window tree).
