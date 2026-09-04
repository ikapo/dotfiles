# `.config/ai`

Single source of truth for personal AI tool configuration.

| Path | Purpose |
|---|---|
| `AGENTS.md` | Shared instructions. Linked to `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`. |
| `mcp.json` | MCP server definitions. Each server lists the tools that receive it. |
| `skills/` | Personal skills, one directory per skill. Shared by Claude Code and Codex. |
| `claude/settings.json` | Claude Code settings: model, effort, enabled plugins, marketplaces. |

## Usage

    stow -t ~ .     # first time, or after adding a file
    ai-sync         # apply
    ai-sync --check # report drift, exit 1 if any

Never put a credential in `mcp.json`. Use a `.local/bin` wrapper that reads
Keychain at runtime, like `gh-mcp`.

Design: `docs/superpowers/specs/2026-09-04-unified-ai-config-design.md`
