---
description: Commit messages and PR bodies carry no AI attribution
condition:
  - 'Co-Authored-By:[^\n]*(Claude|Anthropic|GPT|OpenAI|omp|Codex)'
  - 'Generated with'
  - 'Assisted-by:'
  - '🤖'
scope:
  - 'tool:bash'
  - 'tool:write'
---

Remove the attribution line. The owner attributes manually. Keep the message to one logical change
and why it was made.
