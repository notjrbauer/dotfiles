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
| `skills/` — portable skills (custom slash commands live here too) | `plugins/` — cloned plugin repos (reinstall) |
| `rules/` — path-scoped reference sheets (Go, Lua, shell…); load only with matching files | `*-cache/`, `file-history/`, `history.jsonl`, `sessions/`, `daemon*`, `jobs/`, `tasks/` |
| `hooks/` — scripts `settings.json`'s hooks run (tmux guard, pane recorder) |  |

So `~/.claude` itself stays a real directory; only the portable files are
symlinks back into this repo. The `.gitignore` here is a belt-and-suspenders
blocklist so none of that runtime state can slip in even by accident.

**Mind the write-through:** because `~/.claude/settings.json` is a symlink,
runtime "always allow" grants and `/config` edits land in the tracked repo
file. `settings.local.json` is **project**-scope only — there's no user-scope
variant, so it can't catch these. Answer permission prompts at project scope
when a rule shouldn't be shared, and review `git diff` before committing.
`.githooks/pre-commit` blocks credentials outright.

## What gets linked (see `../install.sh`)

```
~/.claude/CLAUDE.md      -> .claude/CLAUDE.md      # loaded every session
~/.claude/settings.json  -> .claude/settings.json  # model, permissions, plugins
~/.claude/agents/*       -> .claude/agents/*       # per-entry (link_children)
~/.claude/skills/*       -> .claude/skills/*       # per-entry (link_children)
~/.claude/rules/*        -> .claude/rules/*        # per-entry; each has `paths:` frontmatter
~/.claude/hooks/*        -> .claude/hooks/*        # per-entry
```

## What the hooks in `settings.json` do

All of them shell out to small scripts so the JSON stays readable:

- **tmux badge** (`~/.config/tmux/tmux-agent-state`): `UserPromptSubmit` clears,
  `Stop` sets `done`, `PermissionRequest` / `StopFailure` / a filtered
  `Notification` set `wait` (and send a WezTerm toast), `SessionEnd` clears.
- **resume after reboot**: `SessionStart` stores the session id as the tmux
  pane option `@claude_session`; `tmux-snapshot` records it and a restore
  types `claude -r <id>` into the pane, unsent.
- **tmux guard** (`hooks/tmux-guard.sh`, `PreToolUse` on Bash): denies
  `new-session`/`new-window`/`split-window` without `-d`, `capture-pane`
  without `-p`, and `send-keys` into any pane this session did not create.
  `hooks/tmux-record-pane.sh` (`PostToolUse`) is how it knows which panes
  those are. These used to be three sentences in `CLAUDE.md`; a hook holds
  every time, a sentence does not.

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

`extraKnownMarketplaces` names a private repo here deliberately — `--scope
user` is the only scope that enables a plugin everywhere, and that scope is
this file. Don't "clean it up"; only the name is exposed.

## Adding more portable config later

Drop it in this directory, add a `link` line in `../install.sh`, and (if
it's a new top-level name) it's already covered — the `.gitignore` blocks
runtime state, not config. A custom slash command is a skill (`skills/<name>/SKILL.md`);
`commands/` was merged into skills.
See `agents/README.md` for the subagent roster.
