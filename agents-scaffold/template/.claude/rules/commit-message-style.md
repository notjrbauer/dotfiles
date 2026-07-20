# Commit message style

- **Subject:** imperative mood, ≤~50 chars, no trailing period.
  "Add retry to fetch client" — not "Added…" / "Adds…".
- **Body:** blank line after the subject, then wrap at ~72 chars.
  Explain *why*, not just *what* — the diff already shows what.
- **One logical change per commit.** Small and frequent beats large and
  rare.
- Reference decisions by ADR id where relevant ("see D-004").
- **Agents never add AI attribution.** Do NOT add an `Assisted-by:`
  trailer, do NOT use `Co-Authored-By:` for AI agents, and do NOT add
  emoji / "Generated with" banners — the owner adds attribution
  manually when they choose. `.githooks/commit-msg` blocks AI
  Co-Authored-By/banners and format-checks a manually added
  `Assisted-by:` trailer.
