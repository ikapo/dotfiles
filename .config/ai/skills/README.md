# Skills

`~/.claude/skills` links to this directory. Everything else in it is
gitignored machine state:

- third-party skills the `skills` CLI installed (`skills add -g -a claude-code`),
  listed in [../PLUGINS.md](../PLUGINS.md);
- `synced/`, Claude's cache of skills from claude.ai.

This file stays tracked so the directory exists after a fresh clone; without
it `~/.claude/skills` would dangle and `skills add` would fail.
