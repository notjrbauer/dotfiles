# agents-scaffold

A portable working system for long-horizon **agentic development** —
distilled to the parts that aren't project-specific. Drop it into any
repo and an AI coding agent (or a human) knows how to work there:
autonomous small commits, a decision log, a session journal, a
human-decision queue, and git hooks that keep all three honest.

## What it installs

```
README.md                              # what the project IS (vision/overview)
AGENTS.md                              # how we work here (the centerpiece)
docs/decisions.md                      # append-only ADR log — the "why"
project/journal/                       # per-session history (append-only)
project/brainstorms/                   # discovery captures
project/human-in-the-loop/QUEUE.md     # design forks only a human can rule on
.claude/rules/commit-message-style.md  # commit style + attribution rule
.githooks/
  pre-commit    # requires a journal entry + runs the fast verify gate
  commit-msg    # requires the Assisted-by trailer; blocks Co-Authored-By/banners
  pre-push      # re-runs the full verify — nothing red leaves the machine
  lib-verify.sh # resolves a verify target: scripts/verify | npm | make
```

## Usage

```sh
# from the repo you want to set up:
/path/to/dotfiles/agents-scaffold/install.sh

# or point it at another repo:
/path/to/dotfiles/agents-scaffold/install.sh ~/code/my-project
```

The installer:

- copies template files **without clobbering** ones you've already
  edited (safe to re-run),
- installs/updates the managed hooks in `.githooks/`,
- sets `git config core.hooksPath .githooks` (skips if you already point
  it elsewhere).

Then edit `AGENTS.md` to name the project and prune anything that
doesn't apply.

## The verify gate

The hooks look for a verify target in this order and run the first hit:
`scripts/verify` (executable) → npm `"verify"` script → Makefile
`verify:` target. If none exists yet the gate is skipped with a notice,
so a fresh repo isn't blocked. Keep verify **fast** (typecheck + tests +
build); `pre-push` runs it with `VERIFY_FULL=1` for a fuller lane your
script can branch on.

## Escape hatches

- `SKIP_JOURNAL=1 git commit …` — trivial commit, no journal entry.
- `SKIP_ATTRIB=1 git commit …` — genuinely human commit, no trailer.
- `git config --unset core.hooksPath` — fully detach the hooks.
