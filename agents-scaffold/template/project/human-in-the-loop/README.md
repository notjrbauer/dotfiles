# project/human-in-the-loop/ — the human's queue

The inverse of the agent's task list: items only a **person** can
action. The agent files here **instead of blocking** — pick a sensible
default, apply it, and queue the fork for async override.

Everything lives in [QUEUE.md](QUEUE.md), two sections:

- **Decisions (HD-nn)** — product/design forks that change what the
  project *is*. State the fork, the options, the self-picked default
  already applied, and what a reversal would cost.
- **Reviews (HR-nn)** — taste/feel/quality checks a proxy can't certify.
  Point at exactly what to look at or run.

Tick or answer items inline; the agent drains answers next session and
promotes settled decisions to `docs/decisions.md`.
