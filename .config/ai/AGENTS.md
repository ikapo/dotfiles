# Agent Instructions

Shared across Claude Code and Codex. Edit this file only; each tool reaches it
through a symlink (see `~/.config/ai/README.md`).

MCP servers are not synced or generated. If one is missing, `~/.config/ai/MCP.md`
has the command to add it. Servers marked GUI-only in that file cannot work in a
headless environment — skip them there rather than trying to make them run.

Plugins are likewise manual: `~/.config/ai/PLUGINS.md` lists what to install in
each tool. Claude Code and Codex keep separate plugin systems, but most of these
plugins ship for both — by Codex's curated marketplace, by adding a repo as a
Codex marketplace, or by the project's own CLI installer. Check all three routes
in that file before concluding a plugin is Claude-only. `codex plugin list`
returns thousands of entries; grep it rather than reading the first screen.
