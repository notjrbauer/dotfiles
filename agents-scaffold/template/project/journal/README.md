# project/journal/ — per-session work logs

The journal is a chronological **log**, not a live snapshot: it says how
the build got here, so any session can resume cold.

- **One file per session:** `YYYY-MM-DD-session-NN-<slug>.md`.
- **Summary at the TOP** (a few lines: what this session was about,
  where it landed), then entries **appended at the BOTTOM** —
  oldest → newest, never prepend.
- Write an entry when a session decided something `git log` won't
  explain. A convention, not a gate — nothing enforces it (see
  `.githooks/pre-commit` for why). An entry can be one or two lines:
  what changed and why.
- No stale "current state" blocks — the living docs (`docs/`) carry
  current state; the journal carries history.

Entry sketch:

```
# YYYY-MM-DD — session 01 — <slug>

<summary: goal, outcome, where the next session should pick up>

---

- <HH:MM> <what was done / decided / learned>
- ...
```
