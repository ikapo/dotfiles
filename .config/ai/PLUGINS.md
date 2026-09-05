# Plugins and skills

Which plugins to install on a new machine, per tool. Written to be handed to an
AI agent: each entry below has the exact command.

Nothing here is automated. Run the commands for what you want, skip the rest.

## Read this first

Claude Code and Codex have separate plugin systems — separate install
locations, separate marketplaces, separate manifests:

| | Claude Code | Codex |
|---|---|---|
| Installed under | `~/.claude/plugins/` | `~/.codex/plugins/` |
| Managed with | `claude plugin marketplace add` | `codex plugin marketplace add` |
| Marketplace manifest | `.claude-plugin/marketplace.json` | `.agents/plugins/marketplace.json` |

That does **not** mean a plugin is Claude-only. Most of these ship for both,
by three different routes: Codex's own curated marketplace, a repo added as a
Codex marketplace, or the project's own CLI installer. Check all three before
concluding something is unavailable.

`codex plugin list` prints several thousand entries across three marketplaces.
Pipe it through `grep`; do not read the head of it and assume a plugin is
missing.

## What to install

| Plugin | Skills | Claude Code | Codex |
|---|---|---|---|
| `superpowers` | 14 | bundled marketplace | curated marketplace |
| `claude-mem` | 18 | `thedotmack` | repo as marketplace |
| `ui-ux-pro-max` | 7 | `ui-ux-pro-max-skill` | `uipro` CLI |
| `context7` | 0 | bundled marketplace | — MCP only, see [MCP.md](MCP.md) |
| `codex` | 3 | `openai-codex` | — not applicable |

`codex` is the plugin that lets *Claude* drive the Codex CLI. Codex does not
need it.

## Claude Code

```sh
claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill
claude plugin marketplace add openai/codex-plugin-cc
claude plugin marketplace add thedotmack/claude-mem

claude plugin install superpowers@claude-plugins-official
claude plugin install context7@claude-plugins-official
claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill
claude plugin install codex@openai-codex
claude plugin install claude-mem@thedotmack
```

`superpowers` and `context7` come from `claude-plugins-official`, which ships
with Claude Code and needs no `marketplace add`.

`claude/settings.json` in this directory already lists these under
`enabledPlugins`, and stow symlinks it into place. That setting records the
choice; it does not fetch anything, so the installs above are still needed.

## Codex

**superpowers** — in Codex's own curated marketplace, no setup required:

```sh
codex plugin add superpowers@openai-curated-remote
```

Or from inside Codex: `/plugins`, search `superpowers`, Install Plugin.

**claude-mem** — the repo carries a Codex marketplace manifest, so add the repo
and install from it:

```sh
codex plugin marketplace add https://github.com/thedotmack/claude-mem
codex plugin add claude-mem@claude-mem-local
```

**ui-ux-pro-max** — not a Codex plugin; it installs through its own npm CLI,
which writes skills for whichever assistant you name:

```sh
npm install -g ui-ux-pro-max-cli
uipro init --ai codex --global
```

`--global` installs for every project rather than the current directory.
`uipro update` refreshes the skill files later, and `uipro uninstall --ai codex`
removes them.

## Copying a single skill instead

Only worth it for a skill with no upstream install route. Both tools read
`SKILL.md` with `name` and `description` frontmatter, so a skill directory can
simply be copied — at the cost of forking it from upstream updates. Skip any
skill that names Claude-Code-only tooling, and skip `claude-mem`'s: they drive
an MCP server Codex is not running.

Put the skill in `skills/` here and let stow place both links:

```sh
cp -R <source-skill-dir> ~/.config/ai/skills/<name>
```

Claude picks it up at once, since `~/.claude/skills` is a symlink to this
directory. Codex needs one committed link per skill, because `~/.codex/skills/`
also holds Codex's own `.system/` built-ins and so cannot itself be a symlink:

```sh
cd <repo> && ln -sfn ../../.config/ai/skills/<name> .codex/skills/<name>
stow ./ -t ~/
```

Codex also ships a `skill-installer` skill that pulls skills from any GitHub
repo path. Prefer it over copying whenever the skill has a real upstream.
