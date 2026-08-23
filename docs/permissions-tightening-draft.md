# settings.json permission tightening — DRAFT, not applied

Three holes, all pre-existing. Each was reproduced on tmux 3.7c against a
throwaway socket, never the live server.

## Hole 1 — the allow-list grants arbitrary command execution

`Bash(tmux new-session -d *)` is in `allow`. The trailing argument to
`new-session` *is* a shell command, so the pattern grants unrestricted exec:

```
tmux new-session -d 'touch /tmp/pwn-proof'   → file created, no prompt
```

Same for `new-window -d *` and `split-window -d *`. A `deny` rule cannot patch
this: the inner command is never separately classified, so
`tmux new-session -d 'tmux kill-server'` sails past `Bash(tmux kill-server*)`.

**Fix: remove those three from `allow`.** With `defaultMode: auto` they fall
through to the classifier, which judges each call on its content instead of
rubber-stamping the verb.

Cost, stated honestly: pane creation is no longer instant-approved, so agents
will occasionally pause on it. That is the price of closing an unrestricted
exec grant, and there is no pattern that keeps the speed without keeping the
hole.

## Hole 2 — deny rules are prefix-anchored; tmux accepts abbreviations

Any unambiguous prefix resolves, and there are short aliases besides. Verified:

| denied today | bypassed by |
| --- | --- |
| `Bash(tmux attach*)` | `tmux a`, `tmux at`, `tmux att` |
| `Bash(tmux kill-pane*)` (ask) | `tmux killp` |
| `Bash(tmux kill-window*)` (ask) | `tmux killw` |
| `Bash(tmux kill-session*)` (ask) | `tmux kills` |
| — | `neww`, `splitw` |

Ambiguity checked against `list-commands` so the globs below are safe:

- `a` → only `attach-session`, so `tmux a*` is unambiguous and total.
- `kill-se` → ambiguous (`kill-server`, `kill-session`); tmux rejects it.
  `kill-ser` → only `kill-server`.
- `killp` / `killw` / `kills` are aliases, not prefixes — they do not appear in
  `list-commands` and must be listed explicitly.

## Hole 3 — nothing protects the default socket in its usual spelling

`Bash(tmux -L default*)` and `Bash(tmux -S *default*)` only catch the explicit
form. The ordinary way to reach your live server is to pass **no `-L` at all**,
and a prefix glob cannot express "absence of a flag."

There is no pattern that fixes this directly. The mitigation is to gate the
destructive *verbs* regardless of socket — which the rules below do — so that
hitting the live server still cannot silently kill or detach anything.

## Proposed block

```json
"permissions": {
  "allow": [
    "Bash(tmux list-*)",
    "Bash(tmux ls*)",
    "Bash(tmux show-*)",
    "Bash(tmux has-session*)",
    "Bash(tmux display-message -p*)",
    "Bash(tmux capture-pane -p*)"
  ],
  "deny": [
    "Bash(tmux a*)",
    "Bash(tmux kill-ser*)",
    "Bash(tmux swit*)",
    "Bash(tmux source*)",
    "Bash(killall tmux*)",
    "Bash(pkill*tmux*)",
    "Bash(tmux -L default*)",
    "Bash(tmux -S *default*)",
    "Read(~/.zshenv.local)"
  ],
  "ask": [
    "Bash(tmux send-keys*)",
    "Bash(tmux send*)",
    "Bash(tmux kill-session*)",
    "Bash(tmux kills*)",
    "Bash(tmux kill-window*)",
    "Bash(tmux killw*)",
    "Bash(tmux kill-pane*)",
    "Bash(tmux killp*)",
    "Bash(tmux respawn*)",
    "Bash(tmux rename*)",
    "Bash(tmux run-shell*)",
    "Bash(tmux run*)",
    "Bash(tmux display-popup*)"
  ],
  "defaultMode": "auto"
}
```

Changes from today: the three exec-granting allows are gone; `ls*` is added
(the alias for `list-sessions`, currently unmatched); `attach` widens to `a*`;
kill aliases and `run-shell` / `display-popup` are covered; `Read(~/.zshenv.local)`
guards the documented secret store.

`run-shell` is **`ask`, never `allow`** — like `new-session`, its argument is an
arbitrary command.

## What this does not do

- It does not stop a determined agent. `zsh -lic '…'` reaches anything a shell
  can reach, and `settings.local.json` already allows some `zsh -lic` forms.
  A `Read` deny does not reach a subprocess that reads the file itself.
- It does not cover every abbreviation of every verb — prefix matching against
  a command with many spellings cannot be exhaustive. It covers the destructive
  ones.

Defense in depth, not a seal. The exec-grant removal in Hole 1 is the change
that actually matters; the rest is closing the obvious doors.
