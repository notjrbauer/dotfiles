# Claude Code agents

The curated subagent set, version-controlled here and symlinked into
`~/.claude/agents` **one entry at a time** (`link_children` in `install.sh`),
so anything installed there later stays on this machine instead of landing in
a public repo. One flat directory — no sub-folders, no segregation. Every
agent is built to be used **two ways**:

- **Ask it** — a current, idiom-accurate answer that *teaches* (the why,
  the exact current API/version, the common footguns).
- **Delegate to it** — hand it real work; it implements to current
  standards, matches surrounding code, and verifies.

## Rockstars — the primary set

Each carries a `## Current as of 2026` block pinning the concrete versions
it was researched against (re-verify as the world moves).

| agent | domain | pinned to |
|---|---|---|
| `golang-rockstar` | idiomatic modern Go, stdlib-first, concurrency, tooling | Go 1.26 |
| `backend-architect` | language-agnostic server/API/persistence/observability (owns API design) | OTel 1.43, OAuth 2.1, PG 18 |
| `distributed-systems-specialist` | consistency, consensus, replication, messaging, failure | Kafka 4.3, NATS 2.14, etcd 3.6, Temporal 1.31 |
| `frontend-rockstar` | modern TypeScript + web platform, perf, a11y | TS 6, Vite 8, Node 24 |
| `unix-cli-specialist` | zsh/POSIX, coreutils, kernel/syscalls, tracing, low-level | Linux 6.18/6.12 LTS, macOS Tahoe 26, zsh 5.9 |
| `container-oci-specialist` | Docker/BuildKit/OCI, minimal secure images, supply chain | Docker 29.6, BuildKit 0.31, OCI 1.1.1 |
| `lua-rockstar` | idiomatic Lua (5.5/5.4 + LuaJIT), metatables, embedding | Lua 5.5.0 / 5.4.8 |
| `nvim-rockstar` | modern Neovim Lua API, plugin authoring, LSP/treesitter | Neovim 0.12 |
| `ai-claude-specialist` | Claude Code / agents / AGENTS.md / MCP — improves this very set | Opus 4.8 / Sonnet 5 / Haiku 4.5 / Fable 5 |

## Supporting cast — kept and trimmed

Non-overlapping utility agents from the prior set, trimmed to the same
tight style and repointed to the current roster.

- **Review & quality:** `code-reviewer` (security), `idiomatic-code-reviewer`
  (style/idioms), `performance-optimizer` (latency/throughput).
- **Understand & document:** `code-archaeologist` (map unfamiliar code),
  `documentation-specialist` (READMEs/runbooks/ADRs — and the Mermaid that
  goes in them).

## What's deliberately absent

- **Stack classification and multi-step breakdown** — the built-in `Explore`
  agent and plan mode already do that, and a read-only planner can only hand
  back text the main loop must re-execute.
- **Dead-code hunting** — `staticcheck` and `go tool deadcode` do it better
  than a prompt, and the main loop can just run them.
- **Agents for stacks this machine doesn't have.** The set is sized to the
  evidence in `~/dev` and the Brewfile, not to what might be useful someday.
  Descriptions are injected into *every* session to route on, so an unused
  agent costs context on every turn — keep them short and keep them earned.

## Maintaining them

Living files — the pinned versions go stale. To refresh, add, or re-trim a
specialist, delegate to `ai-claude-specialist` (it knows the format and
these conventions). Keep each one **dense, not bloated**: current idioms +
sharp-edge anti-patterns + explicit ask/do modes, nothing generic. A
`name:` is an agent's identity — keep it unique; a duplicate silently
shadows another agent.
