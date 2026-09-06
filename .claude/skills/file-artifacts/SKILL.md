---
name: file-artifacts
description: Save published Claude artifacts both to claude.ai and locally — publish or update the page, write the HTML source into billing-docs/design/, add its row to the registry, and regenerate the doc index. Use when the user says "file the artifacts", "save the artifacts", "back up my artifacts", or asks where an artifact went; and run it as the finishing step after creating or updating any artifact.
---

# Filing an artifact

An artifact lives in two places and both have to be kept: the **published page** on claude.ai
(survives sessions, private until shared) and the **HTML source** in `~/dev/billing-docs/design/`
(survives claude.ai, greppable, version-controlled alongside the notes). A scratchpad copy is neither
— `/private/tmp/...` is session-scoped and gets cleaned.

## Before creating anything

```
Artifact({action: "list"})
```

Ten-plus already exist. A near-duplicate splits the shared link and leaves people reading the stale
half — this has happened (*The Rollup Crosswalk* duplicated *Rollup Column Atlas*). Prefer updating.

## The four steps

**1. Publish.** New artifact: `file_path` only. Existing one: `file_path` **and** `url=<the link>`.
Publishing without `url` from a conversation that did not create it makes a *separate* artifact.

**2. Save the source** to `~/dev/billing-docs/design/<slug>.html` with the folder's two-line header
(`credit-pools-artifact.html` is the model):

```html
<!-- index: what it is (repo: … · TICKET) -->
<!-- published: https://claude.ai/code/artifact/<uuid> -->
```

Line 1 is what the index generator renders. Line 2 is how the next session finds the URL without
having to list.

**3. Register it** in `~/dev/billing-docs/design/artifacts.md`: add or update the row under the right
theme heading, with tags, repo/ticket, source path and URL. Keep the tag vocabulary small — it is a
lookup surface, not a taxonomy.

**4. Reindex.**

```
cd ~/dev/billing-docs && make index && make check
```

`make check` fails if the index is stale, so skipping this breaks the next person's run. A
`PostToolUse` hook on the Artifact tool (`~/.claude/hooks/artifact-reindex.sh`) also does step 4
automatically, but it only covers sessions started after that hook was registered — run it anyway.

## Filing artifacts that only exist on claude.ai

Most published artifacts have no local source. To adopt one:

```
Artifact({action: "list"})            # find the URL
WebFetch(url, "return the full HTML") # read the page back
```

Then write it to `design/` with the two comment lines and continue from step 3.

## Rules that do not bend

- **Never publish a file you have not read**, including one the user says is fine.
- Artifacts are private until shared from the page's share menu, so publishing is not sending. But
  the contents are still governed by the privacy rules in `~/dev/CLAUDE.md` — sharing is John's call.
- Keep `<title>`, favicon and URL stable across updates. People find a tab by its icon.
