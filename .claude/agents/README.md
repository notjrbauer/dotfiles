# Claude Code agents, rules, and skills

What lives under `.claude/` and why each piece has the shape it does.
Everything here is version-controlled and symlinked into `~/.claude/` **one
entry at a time** (`link_children` in `install.sh`) — `agents/*`, `rules/*`,
`skills/*` — so anything installed there later stays on this machine instead
of landing in a public repo.

## Why three shapes

A **subagent** buys *isolation*: a separate context that does a bounded job
and hands back a result. That's worth paying for when the job must be
read-only, must not see the authoring session, or would flood the main
context with file dumps. Every subagent's description is injected into every
session to route on, so each one costs context on every turn whether or not
it's used.

Reference knowledge — idioms, sharp edges, what replaced what — is not that.
It wants to be *in* the main model's context while it edits a matching file,
and nowhere else. That is exactly a **rule with `paths:` frontmatter**: it
loads when Claude reads a file matching the glob, and costs nothing until
then (https://code.claude.com/docs/en/memory#path-specific-rules). The old
roster had nine "rockstar" agents whose bodies were reference sheets; those
are now six rules.

A **skill** is for knowledge that isn't tied to a file type. `user-invocable:
false` makes it model-loaded background (its description still routes);
`disable-model-invocation: true` makes it a `/command` that costs nothing
until typed (https://code.claude.com/docs/en/skills).

## Subagents (3)

| agent | job | shape |
|---|---|---|
| `code-archaeologist` | map an unfamiliar repo: entry points, data flow, what's safe to remove | read-only (`disallowedTools: Write, Edit`), `model: sonnet` |
| `code-reviewer` | security review of a diff or PR; reports, never edits | `tools: Read, Grep, Glob, Bash` — no `Agent`, so no write path by spawning |
| `idiomatic-code-reviewer` | idiom/style pass on Go, shell, TS, Python | `model: sonnet` |

## Rules (6) — `.claude/rules/`

| rule | loads when a file matches |
|---|---|
| `go.md` | `**/*.go`, `**/go.mod` |
| `lua.md` | `**/*.lua`, `**/nvim/**` (Lua language + a Neovim API section) |
| `frontend.md` | `**/*.{ts,tsx,js,jsx,svelte,vue}` |
| `shell.md` | `**/*.sh`, `**/*.bash`, `**/*.zsh`, `**/.zsh*`, `**/bin/**` |
| `docker.md` | `**/Dockerfile*`, `**/*.dockerfile`, `**/docker-compose*.y*ml`, `**/compose.y*ml` |
| `docs.md` | `**/*.md`, `docs/**` |

A rule **without** `paths:` is loaded at launch, every session — that's the
cost being removed, so every file here has one. Rules carry idioms,
anti-patterns, and macOS-vs-GNU divergences, not version pins: pins rot, so
each rule says to verify version-specific claims at the source instead.

## Skills — `.claude/skills/`

- `backend-design` — `user-invocable: false`. Endpoint/schema/datastore/
  queue/retry/idempotency/consensus/replication reference, model-loaded when
  a design decision of that shape comes up. Merges the old
  `backend-architect` and `distributed-systems-specialist`.
- `perf` — `disable-model-invocation: true`; run `/perf`. The
  profile → fix → re-measure discipline and its report format.
- `fresh-review`, `tmux-panes`, `review-billing-change` — unchanged.

## What's deliberately absent

- **`ai-claude-specialist`** — the built-in `claude-code-guide` agent covers
  Claude Code, Agent SDK, and API questions.
- **Stack classification and multi-step breakdown** — the built-in `Explore`
  agent and plan mode already do that, and a read-only planner can only hand
  back text the main loop must re-execute.
- **Dead-code hunting** — `staticcheck` and `go tool deadcode` do it better
  than a prompt, and the main loop can just run them.
- **Rules or agents for stacks this machine doesn't have.** The set is sized
  to the evidence in `~/dev` and the Brewfile, not to what might be useful
  someday. No Rust: the idiom reviewer dropped its Rust section for that
  reason.

## Adding one

- **A rule**: `rules/<topic>.md` with `paths:` frontmatter (required — see
  above), under ~150 lines, idioms and sharp edges only, no pinned versions.
- **A subagent**: only when isolation is the point. `description:` is a
  routing sentence (when to use it, ≤ ~220 chars, "use proactively" if it
  should fire unasked); scope `tools:`/`disallowedTools:` to the job; `name:`
  must be unique — a duplicate silently shadows another agent.
- **A skill**: `skills/<name>/SKILL.md`; decide up front whether the model or
  the user invokes it and set the frontmatter accordingly.

Then re-run `./install.sh` so the new entry is linked into `~/.claude/`.
