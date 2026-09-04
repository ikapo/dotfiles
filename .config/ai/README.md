# `.config/ai`

Single source of truth for personal AI tool configuration.

| Path | Purpose |
|---|---|
| `AGENTS.md` | Shared instructions. Linked to `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`. |
| `mcp.json` | MCP server definitions: a remote `url` or a local `command`. Each server lists the tools that receive it. |
| `skills/` | Personal skills, one directory per skill. Shared by Claude Code and Codex. |
| `claude/settings.json` | Claude Code settings: model, effort, enabled plugins, marketplaces. |

## Usage

    stow -t ~ .     # first time, or after adding a file
    ai-sync         # apply
    ai-sync --check # report drift, exit 1 if any

Never put a credential in `mcp.json` — this file is public. Prefer a remote
(`url`) server, whose token lives in each tool's own credential store after an
OAuth login. A local server needing a credential must read it from the Keychain
at runtime, via a `.local/bin` wrapper named as its `command`.

See the MCP section of the root `README.md` for the `oauth` block and for which
tools accept a hand-registered client id.

Design: `docs/superpowers/specs/2026-09-04-unified-ai-config-design.md`
