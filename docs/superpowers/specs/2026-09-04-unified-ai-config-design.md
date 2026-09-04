# Unified AI Configuration in `.config/ai`

Date: 2026-09-04

## Problem

AI tool configuration is scattered across four locations in three incompatible
formats, and none of it is tracked in this repository:

| Location | Format | Contents |
|---|---|---|
| `~/.claude.json` | `{"mcpServers": {...}}` among Claude Code's own runtime state | `ios-simulator` |
| `~/.claude/settings.json` | JSON | model, effort, enabled plugins, marketplaces |
| `.config/zed/settings.json` | `context_servers` key | `github` via `gh-mcp` |
| `~/.codex/config.toml` | `[mcp_servers.x]` TOML | `node_repl` (app-managed) |

Consequences:

- A new machine cannot reproduce the AI setup. Nothing under `~/.claude` or
  `~/.codex` is version controlled.
- Adding one MCP server means three hand edits in three formats.
- There is no canonical place to author personal skills. `~/.claude/skills/`
  does not exist; `~/.codex/skills/` contains only `.system/`.
- Personal instructions would have to be duplicated as `~/.claude/CLAUDE.md`
  and `~/.codex/AGENTS.md`.

## Goals

1. One directory, `.config/ai`, holding skills, MCP definitions, shared
   instructions, and tracked Claude settings.
2. One MCP definition per server, from which each tool's form is derived.
3. A home for hand-written skills, shared by Claude Code and Codex.
4. Shared instructions read identically by every tool.
5. Reproducible on a new machine via `stow` plus one command.

## Non-Goals

- Hoisting plugin-bundled MCP servers (`superpowers`, `claude-mem`,
  `context7`, `github`) into `mcp.json`. Plugins own their servers.
  Reproducibility for these comes from tracking `enabledPlugins` and
  `extraKnownMarketplaces` in `settings.json`.
- Managing `~/.claude` as a stow package. It is mostly machine-local runtime
  state (`sessions/`, `cache/`, `plugins/`, `history.jsonl`).
- Rewriting `~/.codex/config.toml`. The ChatGPT desktop app owns that file.
- Unifying Cursor or GitHub Copilot. Both are present but neither exposes a
  shareable skills or MCP surface worth targeting yet.

## Layout

```
.config/ai/
  AGENTS.md              # shared instructions — single source of truth
  mcp.json               # MCP source of truth
  skills/                # personal skills, one directory per skill
    <name>/SKILL.md
  claude/
    settings.json        # model, effort, enabled plugins, marketplaces
  README.md              # what this directory is, how to sync
.local/bin/
  ai-sync                # generator and symlink installer
```

`.config/ai` and `.local/bin` are already inside the stow package rooted at the
repository root, so `stow -t ~ .` yields `~/.config/ai` and
`~/.local/bin/ai-sync` with no new package and no `.stow-local-ignore` change
for these paths.

## MCP Source of Truth

`.config/ai/mcp.json` declares each server once, plus the tools that receive it:

```json
{
  "servers": {
    "github": {
      "command": "gh-mcp",
      "args": [],
      "targets": ["claude", "zed", "codex"]
    },
    "ios-simulator": {
      "command": "npx",
      "args": ["-y", "ios-simulator-mcp"],
      "targets": ["claude"]
    }
  }
}
```

Schema:

- `command` (string, required) — executable. Bare names resolve via `PATH`.
- `args` (array of strings, optional, default `[]`).
- `env` (object, optional) — literal values only. See Secrets.
- `targets` (array, required) — subset of `claude`, `zed`, `codex`.

An unrecognized `targets` entry is an error, not a silent skip; a typo must not
quietly drop a server.

## Sync Mechanisms

`ai-sync` uses a different mechanism per target because each tool differs.

| Target path | Mechanism |
|---|---|
| `~/.claude/skills` | symlink → `~/.config/ai/skills` |
| `~/.codex/skills/<name>` | one symlink per skill; the directory itself holds `.system/` and cannot be replaced |
| `~/.claude/CLAUDE.md` | symlink → `~/.config/ai/AGENTS.md` |
| `~/.codex/AGENTS.md` | symlink → `~/.config/ai/AGENTS.md` |
| `~/.claude/settings.json` | symlink → `~/.config/ai/claude/settings.json` |
| `~/.claude.json` | `mcpServers` merged from `mcp.json`, `claude` targets |
| Codex MCP servers | `codex mcp add` / `codex mcp remove` |
| Zed `context_servers` | patch `.config/zed/settings.json` in-repo |

Three mechanism choices carry rationale worth recording:

**Codex via CLI, not file.** `~/.codex/config.toml` is written by the ChatGPT
desktop app, which maintains `node_repl`, plugin marketplace paths, and
versioned absolute paths inside it. Generating or symlinking that file would
clobber app-managed state. `codex mcp add|remove|list` mutates only the
`[mcp_servers.*]` blocks, so Codex is driven through its own CLI.

**Zed patched in-repo.** Zed has no import or include mechanism; a server must
appear literally in its `settings.json`. That file is already tracked and
stow-linked, so `ai-sync` patches the repository copy and stow propagates it.
Patching `~/.config/zed/settings.json` directly would write through the symlink
into the repo anyway, but doing it explicitly keeps the write visible as a git
diff.

**Per-skill symlinks for Codex.** `~/.codex/skills/` already contains
`.system/`, which Codex owns. Replacing the directory with a symlink to
`.config/ai/skills` would hide it. `ai-sync` instead links each skill
individually and removes stale links whose source no longer exists.

## Secrets

`mcp.json` contains no credentials, ever. A server needing authentication gets
a wrapper script in `.local/bin` that reads the value from Keychain at
invocation time, following the existing `gh-mcp` pattern:

```sh
security find-generic-password -s <service> -a "$USER" -w
```

The repository's `.githooks/pre-commit` hook already scans staged content for
secrets and covers `.config/ai` without modification.

`env` in `mcp.json` is for non-sensitive values only — feature flags, paths,
log levels. Anything secret belongs behind a wrapper.

## Resolved: Claude Code Preserves the `settings.json` Symlink

Claude Code writes `~/.claude/settings.json` itself when the user changes theme
or runs `/config` or `/model`. Whether it edited in place (preserving a symlink)
or replaced the file (clobbering it) was the design's one unverified risk.

**Tested 2026-09-04, on Claude Code 2.1.260: the symlink survives.** With
`~/.claude/settings.json` symlinked into this repo, changing the theme through
`/config` wrote *through* the link — `theme` went from `dark` to
`dark-daltonized` in `.config/ai/claude/settings.json`, and
`~/.claude/settings.json` remained a symlink.

This is the desired outcome: interactive settings changes land in the repo as
reviewable git diffs, with no sync step. The fallback the design reserved —
`ai-sync` copying the file and reporting drift — is not needed and was not
implemented.

Two caveats worth keeping:

- This is empirical, not contractual. A future Claude Code release could write
  via replace-and-rename instead. `ai-sync --check` reports the resulting drift
  rather than hiding it, and the fallback remains available.
- `~/.claude.json` is different in kind: Claude Code owns it and rewrites it
  while it runs, so ai-sync merges rather than generates. Everything outside
  `mcpServers` round-trips untouched, unmanaged servers inside it are left
  alone, and only servers ai-sync placed on a previous run are pruned. The
  merge is recomputed at apply time and swapped in with an atomic rename, but a
  concurrent Claude Code write can still win the race — run `ai-sync` with
  Claude Code closed.

## Interface

```
ai-sync            apply all sync operations; idempotent
ai-sync --check    report what would change; exit 1 on drift, 0 when clean
```

`--check` exits nonzero on drift so it can later be wired into a pre-commit
hook or a login check without modification.

Output names each action taken:

```
$ ai-sync
  link   ~/.claude/skills -> ~/.config/ai/skills
  link   ~/.claude/CLAUDE.md -> ~/.config/ai/AGENTS.md
  write  ~/.claude.json (2 servers)
  codex  + github
  zed    patched context_servers (1 server)
```

## Fix Bundled With This Work

`stow -n -v -t ~ .` currently reports:

```
LINK: .claude/settings.local.json => ../Workspace/Code/dotfiles/.claude/settings.local.json
```

The repository's project-local Claude permissions would be linked into the
user's global Claude configuration directory. `.claude` needs a
`.stow-local-ignore` entry. `docs` needs one too, added by this work, so the
spec directory is not linked to `~/docs`.

## Testing

Verification is behavioral, run against the real tools:

1. **Idempotency.** Run `ai-sync` twice. The second run reports no changes.
   Then `ai-sync --check` exits 0.
2. **Drift detection.** Add a server to `mcp.json`; `--check` exits 1 and names
   it. Run `ai-sync`; `--check` exits 0.
3. **Claude.** `claude mcp list` shows every `claude`-targeted server.
4. **Codex.** `codex mcp list` shows every `codex`-targeted server, and
   `node_repl` plus all `[plugins.*]` and `[marketplaces.*]` blocks in
   `config.toml` are unchanged — diff the file before and after.
5. **Zed.** Restart Zed; `github` appears and its handshake succeeds in the
   log.
6. **Removal.** Delete a server from `mcp.json`, run `ai-sync`, confirm it is
   gone from all three tools — additive-only sync is a failure.
7. **Skills.** Create `.config/ai/skills/test-skill/SKILL.md`, run `ai-sync`,
   confirm it resolves in both Claude Code and Codex. Delete it, re-run,
   confirm the stale Codex symlink is removed.
8. **Stow.** `stow -n -v -t ~ .` no longer mentions `.claude/settings.local.json`
   and does not mention `docs`.
9. **Secrets.** Staging a fake token in `.config/ai/mcp.json` is blocked by the
   pre-commit hook.

## Migration

Existing configuration is moved, not recreated:

1. `~/.claude/settings.json` → `.config/ai/claude/settings.json`.
2. `ios-simulator` from `~/.claude/mcp.json` → `mcp.json`, `targets: ["claude"]`.
3. `github` from Zed's `context_servers` → `mcp.json`,
   `targets: ["claude", "zed", "codex"]`.
4. `AGENTS.md` starts empty apart from a heading. No personal instructions
   exist to migrate.
5. `skills/` starts empty. No hand-written skills exist to migrate.
6. Back up `~/.claude/settings.json` and `~/.codex/config.toml` before the
   first `ai-sync`.

## Open Questions

None. The one unresolved item, symlink survival for
`~/.claude/settings.json`, is settled empirically during implementation and has
a defined fallback.
