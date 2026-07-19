# Claude Code agents

The curated subagent set, version-controlled here and symlinked as a whole
to `~/.claude/agents` (see `install.sh`). One flat directory — no
sub-folders, no segregation. Every agent is built to be used **two ways**:

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
| `rust-mentor` | Rust that **teaches** — ownership, async, idioms | Rust 1.97, edition 2024 |
| `frontend-rockstar` | modern web platform, TS, current frameworks, perf, a11y | React 19.2, Svelte 5, Vite 8, TS 6, Node 24 |
| `ux-design-specialist` | visual + UI/UX design into real, accessible CSS (owns deep CSS + utility styling) | CSS Baseline (oklch, container queries), WCAG 2.2 |
| `unix-cli-specialist` | zsh/POSIX, coreutils, kernel/syscalls, tracing, low-level | Linux 6.18/6.12 LTS, macOS Tahoe 26, zsh 5.9 |
| `container-oci-specialist` | Docker/BuildKit/OCI, minimal secure images, supply chain | Docker 29.6, BuildKit 0.31, OCI 1.1.1 |
| `lua-rockstar` | idiomatic Lua (5.5/5.4 + LuaJIT), metatables, embedding | Lua 5.5.0 / 5.4.8 |
| `nvim-rockstar` | modern Neovim Lua API, plugin authoring, LSP/treesitter | Neovim 0.12 |
| `ai-claude-specialist` | Claude Code / agents / AGENTS.md / MCP — improves this very set | Opus 4.8 / Sonnet 5 / Haiku 4.5 / Fable 5 |

## Supporting cast — kept and trimmed

Non-overlapping utility agents from the prior set, trimmed to the same
tight style and repointed to the current roster.

- **Review & quality:** `code-reviewer` (security), `idiomatic-code-reviewer`
  (style/idioms), `performance-optimizer` (latency/throughput),
  `deadcode-eliminator` (cruft).
- **Understand & document:** `code-archaeologist` (map unfamiliar code),
  `documentation-specialist` (READMEs/runbooks/ADRs), `mermaid-diagram-expert`
  (diagrams-as-code).
- **Orchestrate:** `project-analyst` (classify a stack), `tech-lead-orchestrator`
  (break down multi-step work and route it to these agents).
- **Deploy & domain:** `cloud-vm-specialist` (fly.io/AWS/GCP/Hetzner),
  `crypto-blockchain-expert` (protocols/DeFi/MEV), `quant-finance-expert`
  (pricing/risk/position sizing).

## What was removed (and how to get it back)

The prior `~/.claude/agents/` (from the awesome-claude-agents pack) held
31 agents; several were **bloated** (700–942-line framework agents) or
**duplicated a rockstar**. Removed:

- **Rockstar duplicates:** `frontend-developer`, `frontend-css-designer`,
  `tailwind-frontend-expert`, `backend-developer`, `api-architect`,
  `vim-neovim-lua-expert`, `team-configurator`.
- **Unused framework packs:** all `react-*`, `vue-*`/`nuxt`, `django-*`,
  `rails-*`, `laravel-*` (this is a Go/Neovim/shell setup; `frontend-rockstar`
  and `backend-architect` cover modern web/back-end).

The full original tree is preserved in a tarball at
`~/.claude/agents-backup-<timestamp>.tar.gz` — restore any file from there
if a removal was wrong.

## Maintaining them

Living files — the pinned versions go stale. To refresh, add, or re-trim a
specialist, delegate to `ai-claude-specialist` (it knows the format and
these conventions). Keep each one **dense, not bloated**: current idioms +
sharp-edge anti-patterns + explicit ask/do modes, nothing generic. A
`name:` is an agent's identity — keep it unique; a duplicate silently
shadows another agent.
