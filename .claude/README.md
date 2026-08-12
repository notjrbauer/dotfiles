# .claude — portable Claude Code config

This directory bootstraps `~/.claude` on any machine. `install.sh`
symlinks each portable piece into `~/.claude/`; run it once on a new box,
`claude login`, and you have your full setup.

## Why not just symlink all of `~/.claude`?

Because most of `~/.claude` is **not** config — it's runtime state Claude
Code writes as you work, and none of it belongs in git:

| tracked here (portable) | left in `~/.claude`, never tracked |
|---|---|
| `CLAUDE.md` — global defaults | `projects/` — session transcripts (tens of MB) |
| `agents/` — the curated subagents | `.credentials.json` — OAuth tokens |
| `settings.json` — model/permissions/plugins | `~/.claude.json` — usage, project history, MCP |
| `skills/` — portable skills | `plugins/` — cloned plugin repos (reinstall) |
| (future) `commands/`, `output-styles/` |  |
|  | `*-cache/`, `file-history/`, `history.jsonl`, `sessions/`, `daemon*`, `jobs/`, `tasks/` |

So `~/.claude` itself stays a real directory; only the portable files are
symlinks back into this repo. The `.gitignore` here is a belt-and-suspenders
blocklist so none of that runtime state can slip in even by accident.

**Mind the write-through:** because `~/.claude/settings.json` is a symlink,
runtime "always allow" grants and `/config` edits land in the tracked repo
file. Review `git diff` before committing — on a work machine, answer
permission prompts at project scope or put rules in `settings.local.json`
(gitignored on both sides).

## What gets linked (see `../install.sh`)

```
~/.claude/CLAUDE.md      -> .claude/CLAUDE.md      # loaded every session
~/.claude/settings.json  -> .claude/settings.json  # model, permissions, plugins
~/.claude/agents         -> .claude/agents         # whole curated set (one link)
~/.claude/skills         -> .claude/skills         # whole skills dir (one link)
```

## Bootstrapping a fresh machine

```sh
git clone <dotfiles> && cd dotfiles
./install.sh          # symlinks everything, including the .claude pieces
claude login          # one-time auth (credentials stay local, untracked)
```

Plugins are declared in `settings.json` (`enabledPlugins`, plus
`extraKnownMarketplaces` for non-official sources) but the plugin repos live
in `~/.claude/plugins/` per machine — on a new box `./install.sh` restores the
declarations and Claude Code clones the repos on next start.

`extraKnownMarketplaces` names `livekit/lkctl`, a **private** repo, in this
**public** one. That's deliberate, not a leak to clean up: `--scope user` is
the only scope that enables a plugin everywhere, and on this setup that scope
*is* this repo (see the write-through note above). The alternative was
re-running `--scope local` per project. Only the repo's name is exposed —
never a token, and cloning it still requires org access.

## Adding more portable config later

Drop it in this directory, add a `link` line in `../install.sh`, and (if
it's a new top-level name) it's already covered — the `.gitignore` blocks
runtime state, not config. Custom slash commands go in `commands/`, custom
output styles in `output-styles/`; both are auto-discovered under `~/.claude`.
See `agents/README.md` for the subagent roster.
