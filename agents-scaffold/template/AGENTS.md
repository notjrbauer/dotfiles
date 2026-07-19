<!--
  Fill in <PROJECT_NAME> and the one-line description below, then prune
  any convention that doesn't apply to this project (the determinism and
  pure-core notes are optional; delete them if irrelevant). This file is
  about HOW we work — what the project *is* lives in README.md, docs/,
  and the ADR log (docs/decisions.md).
-->

# AGENTS.md

**\<PROJECT_NAME\>** — \<one-line description of the project\>. This file
is *how we work* here; it's read by AI coding agents (and humans) at the
start of every session. What the project *is* — vision, stack,
architecture, plan — lives in `README.md`, `docs/`, and the decision log
`docs/decisions.md`.

## Philosophy

When a tactic conflicts with one of these, the philosophy wins.

- **No clock, and no shortcuts.** Correct & slow beats shoddy & fast.
  You are never on a deadline; never compress quality to fit a window.
  Partial-and-excellent beats complete-and-compromised.
- **Verify, don't trust.** Check existing files, docs, and other agents'
  work against reality. Where a doc and the code disagree, the code
  wins — then fix the doc.
- **Done is earned, not declared.** Be skeptical of your own green.
  Never claim done/shipped unless it's literally, verifiably true. A
  passing check counts only if it could have gone RED.
- **Bias to motion: act, self-vet, surface.** The human owns direction
  and the irreversible; you own execution. Reversible progress by
  default; surface forks for async override rather than blocking.
- **A passing build is the floor, not the goal.** Compiling/green is the
  minimum. The bar is work that is correct, legible, and intentional —
  never generic filler. Decide the shape early and honor it.
- **If a user can't reach it, it doesn't exist.** What counts as built
  is what a user can actually exercise in the running system. Build in
  complete vertical slices, not horizontal layers no one can run yet.

## How to work here

- **Autonomous by default.** Pick the next task → build → verify →
  commit → journal → repeat. Don't ask permission for routine forward
  progress; sensible default? take it, note it, move on.
- **Many small commits.** Committing as you go *is* the workflow. In a
  solo repo, commit straight to your working branch. In a shared repo,
  branch + PR per your team's policy — adjust this line to match. Once a
  build exists, gate every commit on a fast `verify` (typecheck + tests
  + build); the pre-commit hook runs it automatically. Keep verify fast
  — a slow gate rots into a skipped gate.
- **Enable the hooks once:** `git config core.hooksPath .githooks` (the
  installer does this for you). For Node projects, also wire it into
  `package.json` `"prepare"` so it survives clones.
- **Journal every session.** The pre-commit hook requires a staged
  `project/journal/` entry (`SKIP_JOURNAL=1` for trivial commits). See
  [project/journal/README.md](project/journal/README.md).
- **Leave it resumable.** The session is disposable; the repo is the
  memory. If it isn't a committed file, it doesn't exist — plans,
  decisions, and progress live on disk, so a context compaction or cold
  pickup never loses work.
- **Stop and ask only for** (1) product/design decisions that change
  what the project *is* — prefer filing these async in
  [project/human-in-the-loop/QUEUE.md](project/human-in-the-loop/QUEUE.md)
  with your self-picked default already applied, so you keep moving; and
  (2) anything outward-facing or hard to reverse (push to a shared
  branch, deploy, publish, delete) — never without explicit approval.
- **Record decisions as ADRs** in [docs/decisions.md](docs/decisions.md)
  — the *why* survives even when the code changes.

## Conventions

- **Separate pure logic from I/O.** Core logic (rules, state, math)
  lives in modules with no framework/DOM/network imports; adapters
  consume it as plain data. Deterministic and unit-testable — one of the
  highest-leverage architectural rules there is. *(Adapt to your stack;
  delete if it genuinely doesn't fit.)*
- **Determinism where it matters.** If the project has randomness or
  time-dependence, funnel it through a single injectable source (one
  seeded RNG, an injected clock) so runs reproduce. *(Delete if N/A.)*
- **Single source of truth — generate, don't duplicate.** Anything
  derivable from other data is generated, never hand-maintained in two
  places that can drift.
- **Tests must be able to go RED.** A false green is worse than no test.
  Red-before-green; sanity-check that a test around existing code can
  actually fail.
- **Verify by exercising the real thing.** Before calling something
  done, drive the actual flow — the CLI, the endpoint, the UI — not just
  unit tests. Observe behavior, don't infer it.
- **Durable by default.** A plan, brainstorm, or analysis substantial
  enough to act on is a committed `.md` file, never only a chat message.
  Plans → `docs/plans/`; discovery → `project/brainstorms/`; settled
  design → `docs/`.
- **Docs taxonomy.** `docs/` says what the project *is now* (living,
  edited in place). `project/` is the process home: `journal/` says *how
  it got here* (append-only log), plus `brainstorms/` and
  `human-in-the-loop/`. One doc per concern; edit living docs in place.
- **Markdown prose wraps at ~72 characters** (soft norm, not a gate;
  tables/URLs exempt).

## AI commit attribution (required)

Every AI-generated commit **must end with an
`Assisted-by: AGENT_NAME:MODEL_VERSION` trailer** (after a blank line) —
e.g. `Assisted-by: Claude Code:claude-opus-4-8`. `MODEL_VERSION` is the
**actual** model you're running, never hardcoded (`unknown` if
unavailable). **Never** use `Co-Authored-By:` for AI agents or add emoji
/ "Generated with" banners. Enforced by `.githooks/commit-msg`
(`SKIP_ATTRIB=1` bypasses a genuinely human commit). Full message style:
[.claude/rules/commit-message-style.md](.claude/rules/commit-message-style.md).
