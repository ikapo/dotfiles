# `.config/ai`

Configuration for Claude Code.

| Path | Purpose |
|---|---|
| `AGENTS.md` | Agent instructions, read as `~/.claude/CLAUDE.md`. |
| `MCP.md` | Which MCP servers to install and how. Not automated; run what you need. |
| `PLUGINS.md` | Which plugins to install. |
| `claude/settings.json` | Claude Code settings: model, effort, enabled plugins, marketplaces. |

## Setup on a new machine

`stow` handles all of it. Claude Code does not look in `~/.config/ai`, so the
repo carries committed symlinks at the paths it does read:

| Committed symlink | Points at |
|---|---|
| `.claude/CLAUDE.md` | `../.config/ai/AGENTS.md` |
| `.claude/settings.json` | `../.config/ai/claude/settings.json` |

`stow` links those into `~/.claude` like any other file, so setup is the same
one command as the rest of the repo:

```sh
mkdir -p ~/.claude
stow ./ -t ~/
```

**The `mkdir` matters.** If `~/.claude` does not already exist, stow folds the
whole directory into a single symlink pointing back at the repo, and Claude
Code then writes its plugins, sessions and credentials inside your git
checkout. Creating the directory first keeps stow linking file by file.

### Skills

`~/.claude/skills` is a plain directory, not linked into the repo. The `skills`
CLI fills it with links into `~/.agents/skills`, and Claude keeps its claude.ai
cache there in `synced/`. The list and commands are in
[PLUGINS.md](PLUGINS.md#skills). If you ever track a personal skill under
`.claude/skills/`, run `mkdir -p ~/.claude/skills` before stow, or stow folds
the directory into a symlink and the CLI's relative links break.

`settings.local.json` is listed in `.stow-local-ignore`; it is this repository's
own project settings and must not be linked into `~`.

Then set up MCP servers ([MCP.md](MCP.md)), plugins and skills ([PLUGINS.md](PLUGINS.md)).

## Why none of this is automated

There was a tool here, `ai-sync`, that generated the symlinks above and
registered MCP servers from a tracked `mcp.json`. It was removed the same day
it shipped. Both halves turned out not to need automating: the symlinks are now
committed to the repo and placed by stow, so there is nothing left to generate,
and remote MCP servers keep their token in the tool's own credential store after
a browser login, so the wrapper indirection the generator existed to manage
stopped being necessary — `claude mcp add` registers a server in one command.

Prefer adding a line to [MCP.md](MCP.md) or [PLUGINS.md](PLUGINS.md) over
writing something that generates them. The full design and its post-mortem are
in git history, at the commit that removed `docs/superpowers/`.

## Notes

`~/.claude/settings.json` is a symlink into this repo, and Claude Code writes
that file when you change a setting. A setting changed in the UI follows the
links and lands in `claude/settings.json` as a normal edit — review it with
`git diff` before committing.

Plugin commands do not — `claude plugin uninstall` and `/plugin install` both.
They follow only the first link, to `.claude/settings.json` in this repo —
itself a link — and replace that with a plain file holding the new settings,
leaving `claude/settings.json` untouched. After a plugin command, check
`git status`: if `.claude/settings.json` shows as changed (`T`), copy the
change into `claude/settings.json` and restore the link with
`git checkout -- .claude/settings.json`.

Never put a credential in this directory. It is public.
