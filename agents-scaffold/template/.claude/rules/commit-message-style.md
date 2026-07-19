# Commit message style

- **Subject:** imperative mood, ≤~50 chars, no trailing period.
  "Add retry to fetch client" — not "Added…" / "Adds…".
- **Body:** blank line after the subject, then wrap at ~72 chars.
  Explain *why*, not just *what* — the diff already shows what.
- **One logical change per commit.** Small and frequent beats large and
  rare.
- Reference decisions by ADR id where relevant ("see D-004").
- **AI-authored commits MUST end with an attribution trailer** after a
  blank line: `Assisted-by: AGENT_NAME:MODEL_VERSION` — the actual
  running model (`unknown` if unavailable), e.g.
  `Assisted-by: Claude Code:claude-opus-4-8`.
- **Do NOT** use `Co-Authored-By:` for AI agents, and **do NOT** add
  emoji / "Generated with" banners. Enforced by `.githooks/commit-msg`
  (`SKIP_ATTRIB=1` bypasses for a genuinely human commit).
