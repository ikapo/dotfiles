# Agent Instructions

Instructions for Claude Code. Edit this file only; Claude Code reaches it
through a symlink (see `~/.config/ai/README.md`).

MCP servers are not synced or generated. If one is missing, `~/.config/ai/MCP.md`
has the command to add it. Servers marked GUI-only in that file cannot work in a
headless environment — skip them there rather than trying to make them run.

Before registering a server by hand, check whether an official plugin already
ships it — `context7` comes with the `context7` plugin, and adding the raw
endpoint on top registers the same tools twice under two names. Add the
endpoint directly only when no plugin provides it.

Plugins are likewise manual: `~/.config/ai/PLUGINS.md` lists what to install.
