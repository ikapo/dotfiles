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

```sh
claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill
claude plugin marketplace add thedotmack/claude-mem

claude plugin install superpowers@claude-plugins-official
claude plugin install mattpocock-skills@claude-plugins-official
claude plugin install context7@claude-plugins-official
claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill
claude plugin install claude-mem@thedotmack
```

`superpowers`, `mattpocock-skills` and `context7` come from
`claude-plugins-official`, which ships with Claude Code and needs no
`marketplace add`.

`claude/settings.json` in this directory already lists these under
`enabledPlugins`, and stow symlinks it into place. That setting records the
choice; it does not fetch anything, so the installs above are still needed.

## Copying a single skill instead

Only worth it for a skill with no upstream install route. A skill is a
directory with a `SKILL.md` carrying `name` and `description` frontmatter, so
it can simply be copied — at the cost of forking it from upstream updates.

```sh
cp -R <source-skill-dir> ~/.config/ai/skills/<name>
```

Claude picks it up at once, since `~/.claude/skills` is a symlink to this
directory.
