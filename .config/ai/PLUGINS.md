# Plugins and skills

Which Claude Code plugins to install on a new machine. Written to be handed to
an AI agent: each entry below has the exact command.

Nothing here is automated. Run the commands for what you want, skip the rest.

## What to install

| Plugin | Skills | Marketplace |
|---|---|---|
| `superpowers` | 14 | bundled marketplace |
| `mattpocock-skills` | 25 | bundled marketplace |
| `claude-mem` | 18 | `thedotmack` |
| `context7` | 0 | bundled marketplace |
| `grok-build` | 4 | `xai-grok-build` |
| `ponytail` | 6 | `ponytail` |
| `cloudflare` | 14 | bundled marketplace |
| `neon` | 8 | bundled marketplace |
| `revenuecat` | toolkit + MCP | `RevenueCat` |

```sh
claude plugin marketplace add thedotmack/claude-mem
claude plugin marketplace add xai-org/grok-build-plugin-cc
claude plugin marketplace add DietrichGebert/ponytail
claude plugin marketplace add RevenueCat/ai-toolkit

claude plugin install superpowers@claude-plugins-official
claude plugin install mattpocock-skills@claude-plugins-official
claude plugin install context7@claude-plugins-official
claude plugin install claude-mem@thedotmack
claude plugin install grok-build@xai-grok-build
claude plugin install ponytail@ponytail
claude plugin install cloudflare@claude-plugins-official
claude plugin install neon@claude-plugins-official
claude plugin install revenuecat@RevenueCat
```

`superpowers`, `mattpocock-skills`, `context7`, `cloudflare` and `neon` come from
`claude-plugins-official`, which ships with Claude Code and needs no
`marketplace add`.

`grok-build` is xAI's own bridge: it lets Claude hand reviews and tasks to the
Grok Build CLI. It shells out to `grok`, which the `grok-build` cask installs,
so sign that in first with `grok login`. `/grok-build:check` confirms it is
ready.

`revenuecat` is RevenueCat's AI Toolkit: it registers RevenueCat's MCP server
(`https://mcp.revenuecat.ai/mcp`) plus skills for RevenueCat workflows. It signs in
with OAuth to the RevenueCat account: run `/mcp` in an interactive session and pick
it. Don't add the raw endpoint on top; the plugin already ships it.

`claude/settings.json` in this directory already lists these under
`enabledPlugins`, and stow symlinks it into place. That setting records the
choice; it does not fetch anything, so the installs above are still needed.

## Skills

Third-party skills that do not come in a plugin are installed with the
`skills` CLI (`brew "skills"` in the Brewfiles), never copied into the repo.

| Source | Skills |
|---|---|
| `Doist/todoist-cli` | `todoist-cli` (drives the `td` formula) |
| `elayadesign/ai-design-skills` | all |
| `emilkowalski/skills` | all |
| `nextlevelbuilder/ui-ux-pro-max-skill` | all (was the `ui-ux-pro-max` plugin) |
| `rossark0/rossark-motion-skill` | `rossark-motion-skill` |

```sh
skills add Doist/todoist-cli --skill todoist-cli -g -y
skills add elayadesign/ai-design-skills --skill '*' -g -y
skills add emilkowalski/skills --skill '*' -g -y
skills add nextlevelbuilder/ui-ux-pro-max-skill --skill '*' -g -y
skills add rossark0/rossark-motion-skill --skill rossark-motion-skill -g -y
```

Without `-a`, `-y` installs to every agent the CLI detects on that machine:
one copy in `~/.agents/skills`, linked from each agent's own directory
(`~/.claude/skills` for Claude Code). Detection happens at install time, so
re-run the commands after installing a new agent. Ignore the PromptScript
error each install prints; it is project-only and the install still succeeds.

`skills ls -g` shows what is installed and for which agents; `skills update -g -y`
updates them. The CLI's lock file (`~/.agents/.skill-lock.json`) records each
skill's source but is not tracked: it cannot restore global skills on another
machine, so this table is the list. Add a row and its command when you add a
source.

### Pending: more plugins could move here

A plugin that is only skills belongs here instead, but the CLI (1.7.4) has no
way to prefix or namespace skills: two sources with a same-named skill
overwrite each other, and only the last install survives. Plugins avoid this
with their `plugin:` prefix. So `mattpocock-skills` stays a plugin for now:
its `prototype` would replace `emilkowalski/skills`' `prototype`.

Check whether that is fixed: `skills add --help | grep -i prefix`, or the
status of [PR #1464](https://github.com/vercel-labs/skills/pull/1464)
(`--prefix`) and issues [#2394](https://github.com/vercel-labs/skills/issues/2394)
and [#1802](https://github.com/vercel-labs/skills/issues/1802). Once released,
move `mattpocock-skills` here with a prefix (install its 27 enabled skills by
name, matching the plugin's `skills` list), then drop this section. The other
plugins also ship hooks, MCP servers, agents or commands, so they stay plugins.
