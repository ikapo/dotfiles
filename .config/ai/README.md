# `.config/ai`

Shared configuration for Claude Code and Codex.

| Path | Purpose |
|---|---|
| `AGENTS.md` | Shared agent instructions. Both tools read it. |
| `MCP.md` | Which MCP servers to install and how. Not automated; run what you need. |
| `skills/` | Personal skills, one directory per skill. |
| `claude/settings.json` | Claude Code settings: model, effort, enabled plugins, marketplaces. |

## Setup on a new machine

`stow` puts this directory at `~/.config/ai`. Each tool then needs a symlink to
the file it expects, because none of them look in `~/.config/ai`:

```sh
stow ./ -t ~/

ln -sfn ~/.config/ai/AGENTS.md            ~/.claude/CLAUDE.md
ln -sfn ~/.config/ai/AGENTS.md            ~/.codex/AGENTS.md
ln -sfn ~/.config/ai/skills               ~/.claude/skills
ln -sfn ~/.config/ai/claude/settings.json ~/.claude/settings.json
```

Four links, run once. They point through `~/.config/ai` rather than at the
repository's real path, so they survive the repo moving.

`ln -sfn` replaces an existing symlink but refuses to overwrite a real file. If
one of these paths already holds real content, move it aside first — its
content belongs in this directory.

Then set up MCP servers: see [MCP.md](MCP.md).

## Notes

`~/.claude/settings.json` is a symlink into this repo, and Claude Code writes
that file when you change a setting in the UI. It follows the symlink rather
than replacing it, so such a change lands here as a normal edit — review it with
`git diff` before committing.

Never put a credential in this directory. It is public.
