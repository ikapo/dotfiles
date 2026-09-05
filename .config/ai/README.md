# `.config/ai`

Shared configuration for Claude Code and Codex.

| Path | Purpose |
|---|---|
| `AGENTS.md` | Shared agent instructions. Both tools read it. |
| `MCP.md` | Which MCP servers to install and how. Not automated; run what you need. |
| `skills/` | Personal skills, one directory per skill. |
| `claude/settings.json` | Claude Code settings: model, effort, enabled plugins, marketplaces. |

## Setup on a new machine

`stow` handles all of it. Neither tool looks in `~/.config/ai`, so the repo
carries committed symlinks at the paths they do read:

| Committed symlink | Points at |
|---|---|
| `.claude/CLAUDE.md` | `../.config/ai/AGENTS.md` |
| `.claude/skills` | `../.config/ai/skills` |
| `.claude/settings.json` | `../.config/ai/claude/settings.json` |
| `.codex/AGENTS.md` | `../.config/ai/AGENTS.md` |

`stow` links those into `~/.claude` and `~/.codex` like any other file, so
setup is the same one command as the rest of the repo:

```sh
mkdir -p ~/.claude ~/.codex
stow ./ -t ~/
```

**The `mkdir` matters.** If `~/.claude` does not already exist, stow folds the
whole directory into a single symlink pointing back at the repo, and the tool
then writes its plugins, sessions and credentials inside your git checkout.
Creating the directories first keeps stow linking file by file.

`settings.local.json` is listed in `.stow-local-ignore`; it is this repository's
own project settings and must not be linked into `~`.

Then set up MCP servers: see [MCP.md](MCP.md).

## Why none of this is automated

There was a tool here, `ai-sync`, that generated the symlinks above and
registered MCP servers from a tracked `mcp.json`. It was removed the same day
it shipped. Both halves turned out not to need automating: the symlinks are the
four `ln -sfn` calls above, run once per machine, and remote MCP servers keep
their token in the tool's own credential store after a browser login, so the
wrapper indirection the generator existed to manage stopped being necessary —
`claude mcp add` and `codex mcp add` each register a server in one command.

Prefer adding a line to [MCP.md](MCP.md) over writing something that generates
it. The full design and its post-mortem are in git history, at the commit that
removed `docs/superpowers/`.

## Notes

`~/.claude/settings.json` is a symlink into this repo, and Claude Code writes
that file when you change a setting in the UI. It follows the symlink rather
than replacing it, so such a change lands here as a normal edit — review it with
`git diff` before committing.

Never put a credential in this directory. It is public.
