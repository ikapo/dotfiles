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
skills add Doist/todoist-cli --skill todoist-cli -g -a claude-code -y
skills add emilkowalski/skills --skill '*' -g -a claude-code -y
```

`skills ls -g` shows what is installed; `skills update -g -y` updates them.
They land in `~/.claude/skills`, which links into this repo, so the files sit
in `skills/` but are gitignored. The CLI's lock file (`~/.agents/.skill-lock.json`)
is not tracked: it cannot restore global skills on another machine, so this
table is the list. Add a row and its command when you add a source.
