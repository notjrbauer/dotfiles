---
# Not **/*.md: that fires on every CLAUDE.md, memory file and rule Claude reads,
# which is most sessions. Documentation proper lives here.
paths:
  - "docs/**"
  - "**/README.md"
  - "**/runbooks/**"
  - "**/adr/**"
---

# Documentation

Docs that operators actually read. Most docs fail because they're written for the author, not the reader — write for the reader. This is for READMEs, architecture docs, API references, runbooks, ADRs; not for inline comments or commit messages.

## Document types and their formats

**README.md** (project root)
- **Hook**: 1-2 sentences. What is this? Who's it for?
- **Quickstart**: 3-5 commands the reader can copy-paste to see it work
- **Why this exists**: 1 paragraph answering "what's the alternative and why is this better"
- **Architecture (high level)**: Mermaid diagram + 2 paragraphs
- **Common operations**: 5-10 things operators actually do (run, deploy, debug, restart)
- **Where to look next**: paths to deeper docs
- NOT in a README: the full API spec, every config option, project history / motivation essays (separate doc or DELETE)

**Architecture doc** (`docs/ARCHITECTURE.md`)
- One Mermaid diagram of the WHOLE system, even if simplified
- One section per major component: what it does, what it owns, what it depends on
- Data flow for the 2-3 most important user-visible flows
- Trade-offs explicitly stated: "We chose X over Y because Z; this means we sacrifice W."

**API reference** (`docs/API.md` or OpenAPI YAML)
- Endpoint name + method + path; request shape (required + optional fields, types); response shape (success + error variants)
- Example: real, copyable curl
- Error codes specific to this endpoint

**Runbook** (`docs/runbooks/<name>.md`)
- **When to use this**: 1-2 sentences (the symptom or trigger)
- **Pre-checks**: commands to verify the symptom is what you think
- **Procedure**: numbered steps; each step has the command AND the expected output
- **Verification**: how to confirm it worked
- **Rollback**: how to undo if it didn't
- **Escalation**: who/what to ping if this runbook doesn't fix it

**ADR** (`docs/adr/NNNN-<title>.md`)
- **Status**: Proposed / Accepted / Deprecated / Superseded by NNNN
- **Context**: what's the situation that demanded a decision?
- **Decision**: what did we pick?
- **Consequences**: what does this make easier / harder / impossible?
- **Alternatives considered**: what we rejected and why
- SHORT — 1-2 pages max. Anything longer is documentation, not a decision record.

## Quality bar
- **Concrete over abstract** — code examples > prose descriptions
- **Verbs in the active voice** — "The scanner writes opportunities" not "Opportunities are written by the scanner"
- **Numeric ranges over weasel words** — "5-30 minute first sync" not "may take some time"
- **One concept per paragraph** — paragraph break = topic change
- **Headings are TOC entries** — should make sense out of context
- **Code samples runnable as-is** — the operator should be able to copy-paste
- **Diagrams over walls of text** when describing structure

## Anti-patterns to eliminate
- "Welcome!" / "Thanks for checking out our project!" — patronizing, no info
- Excessive emoji decoration — operators are professionals
- "This is easy / simple / straightforward" — if it were, you wouldn't be writing about it
- Lorem ipsum / TBD / TODO sections — finish or omit
- Outdated info living next to current info — flag and fix
- Documentation that lies — every code example must work as written

## Workflow
1. **Inventory existing docs** — read the `*.md` in the repo; note what's current, stale, contradicting itself.
2. **Identify the audience** — internal ops? external integrators? new hires? open-source visitors? Each gets different content.
3. **Find the gap** — what does the audience need that doesn't exist?
4. **Write tight** — fewer words, more concrete examples, specific numbers.
5. **Verify by walking through** — pretend you're the audience, follow your own doc, see if it works.

## Diagrams
Write the Mermaid yourself — it renders natively in GitHub, GitLab, and most doc platforms. Place a diagram inline where the prose introduces the concept it illustrates, never in a separate "Diagrams" appendix. Default to `flowchart` when in doubt; `sequenceDiagram` for request/protocol exchanges, `stateDiagram-v2` for workflows, `erDiagram` for schema. The rules that decide whether a diagram reads:
- **8–15 nodes.** Past 25 it's unreadable — split it.
- **`TB` for hierarchy and data flow, `LR` for a sequence of steps.**
- **Subgraphs** to group related nodes; **edge labels** when the relationship isn't obvious from the node names (`A -->|publishes| B`).
- **Shapes carry meaning**: `[Rect]` system, `(Round)` data, `{Diamond}` decision, `[(Cylinder)]` database.
- **`classDef` colors only at ≥4 clusters** — monochrome reads cleaner below that.
- Each diagram in a section answers a **distinct question**. Never two views of the same thing at adjacent abstraction levels.
