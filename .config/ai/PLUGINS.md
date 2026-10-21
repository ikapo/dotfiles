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
| `ui-ux-pro-max` | 7 | `ui-ux-pro-max-skill` |
| `context7` | 0 | bundled marketplace |
| `grok-build` | 4 | `xai-grok-build` |
| `ponytail` | 6 | `ponytail` |

```sh
claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill
claude plugin marketplace add thedotmack/claude-mem
claude plugin marketplace add xai-org/grok-build-plugin-cc
claude plugin marketplace add DietrichGebert/ponytail

claude plugin install superpowers@claude-plugins-official
claude plugin install mattpocock-skills@claude-plugins-official
claude plugin install context7@claude-plugins-official
claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill
claude plugin install claude-mem@thedotmack
claude plugin install grok-build@xai-grok-build
claude plugin install ponytail@ponytail
```

`superpowers`, `mattpocock-skills` and `context7` come from
`claude-plugins-official`, which ships with Claude Code and needs no
`marketplace add`.

`grok-build` is xAI's own bridge: it lets Claude hand reviews and tasks to the
Grok Build CLI. It shells out to `grok`, which the `grok-build` cask installs,
so sign that in first with `grok login`. `/grok-build:check` confirms it is
ready.

`claude/settings.json` in this directory already lists these under
`enabledPlugins`, and stow symlinks it into place. That setting records the
choice; it does not fetch anything, so the installs above are still needed.

## Skills

Third-party skills that do not come in a plugin are installed with the
`skills` CLI (`brew "skills"` in the Brewfiles), never copied into the repo.

| Source | Skills |
|---|---|
| `Doist/todoist-cli` | `todoist-cli` (drives the `td` formula) |
| `emilkowalski/skills` | all |

```sh
skills add Doist/todoist-cli --skill todoist-cli -g -y
skills add emilkowalski/skills --skill '*' -g -y
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
