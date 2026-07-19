# Decision log (ADRs)

Append-only log of locked decisions — the *why* survives even when the
code changes. Newest at the bottom; never rewrite an entry — supersede
it with a new one that points back.

Format:

```
## D-0NN — <title>  (YYYY-MM-DD)
**Decision:** <one sentence — what is locked>
**Why:** <the reasoning, alternatives rejected>
**Consequences:** <what this binds; what it unblocks>
```

A decision that changes *what the project is* needs the human: file it
in [../project/human-in-the-loop/QUEUE.md](../project/human-in-the-loop/QUEUE.md)
with your self-picked default, apply the default, and mark the ADR
`PENDING HUMAN` until they rule.

---

## D-001 — Adopt AGENTS.md working conventions  (YYYY-MM-DD)

**Decision:** This repo adopts the conventions in `AGENTS.md`:
autonomous small commits, journal + verify + attribution git hooks,
logic/IO separation, tests-that-can-go-RED, durable docs, and the
human-in-the-loop queue for design forks.
**Why:** A portable, proven working system for long-horizon agentic
development; adopted without any project-specific process machinery.
**Consequences:** Stack, architecture, and plan are recorded as their
own ADRs below as they get locked.
