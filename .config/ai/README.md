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
