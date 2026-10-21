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
Git syncs the list of enabled plugins between machines, but not the installed
plugins. At the start of each session, compare `claude plugin list` with
`enabledPlugins` in `~/.config/ai/claude/settings.json`. Install any that are
missing with the commands in `PLUGINS.md`. Installing a plugin replaces the
`.claude/settings.json` symlink with a plain file, so afterwards run
`git -C ~/Workspace/dotfiles checkout -- .claude/settings.json`. Without that,
the hourly pull on the headless Mac stops.

Third-party skills go through the `skills` CLI, never copied into the repo:
`skills add <source> -g -y`, then add the source and command to the Skills
section of `PLUGINS.md`. At the start of each session, compare `skills ls -g`
with that section and install any that are missing. `~/.claude/skills` must be
a plain directory: if it is still a symlink into the dotfiles repo, `unlink` it,
`mkdir` it, and move any `synced/` folder from the repo's old
`.config/ai/skills/` into it before installing. The CLI's links are relative
and dangle through a symlink.
