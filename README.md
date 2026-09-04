# Ikapo's Dotfiles

These are my dotfiles.

I use MacOS.

I edit with [Doom Emacs](https://github.com/doomemacs/doomemacs).

I window manage with [yabai](https://github.com/koekeishiya/yabai) and [skhd](https://github.com/koekeishiya/skhd).

I manage packages with [Homebrew](https://brew.sh/).

## How to install

1. [Install Homebrew](https://brew.sh/)
2. Install the core dependencies (see [Packages](#packages) for the full list):

   ```sh
   brew install asmvik/formulae/yabai asmvik/formulae/skhd stow ranger ripgrep fd \
     lsd zoxide fzf bat node@24 zsh-syntax-highlighting zsh-autosuggestions
   brew install --cask iterm2 font-mononoki-nerd-font font-fira-code-nerd-font
   ```

3. Clone the repository: `git clone https://github.com/ikapo/dotfiles`
4. Symlink the dotfiles: `cd dotfiles && stow ./ -t ~/`
5. Enable the secret-scanning pre-commit hook (local git config, so it does
   not survive a clone):

   ```sh
   git config core.hooksPath .githooks
   ```

6. Start services: `brew services start skhd && brew services start yabai`
7. Install Emacs: `brew tap d12frosted/emacs-plus && brew install emacs-plus@29 --with-native-comp --with-nobu417-big-sur-icon`
8. Clone Doom Emacs: `git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.emacs.d`
9. Install Doom: `doom install`

## AI tool config

`.config/ai` is the single source of truth for MCP servers, shared
instructions, and skills across Claude Code, Codex, and Zed — see
`.config/ai/README.md` for the file layout. After stowing, apply it with
`ai-sync`:

```sh
stow ./ -t ~/
ai-sync         # apply: merges Claude's servers into ~/.claude.json,
                # patches Zed's context_servers, registers Codex MCP
                # servers, and symlinks AGENTS.md/CLAUDE.md and skills
ai-sync --check # report drift only; exit 1 if out of sync, 0 if clean
```

`ai-sync` is idempotent — re-run it any time `.config/ai` changes. Claude Code
reads MCP servers from `~/.claude.json`, which it also rewrites as it runs, so
`ai-sync` merges into that file rather than generating it: everything outside
`mcpServers` is preserved, servers it does not manage are left alone, and only
servers a previous run added are pruned. Run it with Claude Code closed, and
restart Claude Code afterwards — it reads MCP config once at startup. Never put
a credential in `.config/ai/mcp.json`; this file is public.

## MCP servers

Prefer a **remote** server over a local one. A remote server is a URL, the tool
runs an OAuth flow against it, and the resulting token lands in that tool's own
credential store — never in this repo. Nothing has to be installed, so a new
machine reproduces the setup by running `ai-sync` and logging in once:

```json
"github": {
  "url": "https://api.githubcopilot.com/mcp/",
  "oauth": {"client_id": "<client id>", "callback_port": 33418},
  "targets": ["claude", "codex"]
}
```

The `oauth` block is only needed when the server's authorization server
supports neither dynamic client registration nor CIMD, which is GitHub's case —
its metadata at `github.com/.well-known/oauth-authorization-server/login/oauth`
advertises no `registration_endpoint`. Such a server has to be handed a client
id you registered by hand. A client id is not a secret; a client **secret** is,
and `ai-sync` refuses one in `mcp.json`. Register a PKCE public client instead —
GitHub advertises `code_challenge_methods_supported: ["S256"]`.

Tool support for a hand-registered client id, as of 2026-09:

| Tool | Remote servers | Hand-registered client id |
|---|---|---|
| Claude Code | yes | yes — `oauth.clientId` / `oauth.callbackPort` |
| Codex | yes | yes — `codex mcp add --oauth-client-id` |
| Zed 1.18 | yes | **no** |

Zed only knows CIMD and dynamic registration (`crates/context_server/src/oauth.rs`,
`determine_registration_strategy`), so it cannot authenticate against a server
offering neither. Its only alternative is a literal `Authorization` header in
`settings.json`, which would put a token in this repo. That is why `github`
targets only `claude` and `codex`.

### Local servers

A local server is a `command` that `ai-sync` launches. Use one only when no
remote equivalent exists — `ios-simulator` drives the local simulator, so it
could not be remote:

```json
"ios-simulator": {
  "command": "npx",
  "args": ["-y", "ios-simulator-mcp"],
  "targets": ["claude"]
}
```

A local server that needs a credential must not name it here. Route it through
a `.local/bin` wrapper that reads the macOS Keychain at startup and `exec`s the
real binary, and give the wrapper's bare name as `command` — `ai-sync` rewrites
a `~/.local/bin` name to an absolute path for the targets that launch outside a
login shell, since Zed and the desktop apps do not inherit `$PATH`. Anything
else stays a bare name so it keeps tracking `$PATH`.

`.githooks/pre-commit` is the backstop: it blocks any commit containing a
credential-shaped string.

### Zed settings

`.config/zed/settings.json` stays tracked rather than ignored, so it remains the
single source of truth — Zed rewrites it whenever you change a setting from the
UI, so a generated copy would drift. `ai-sync` patches only its
`context_servers` key, preserving the leading comment header.

Do not add a `"source": "custom"` key. Older Zed docs still show it, but Zed
1.18 rejects it with `property "source" is not allowed` and its settings
migrator strips the line.

## Packages

Everything I installed deliberately, as of 2026-09-03. Regenerate with
`brew leaves --installed-on-request` and `brew list --cask`.

### Formulae

| Category | Packages |
| --- | --- |
| VCS & dev tools | gh, git, git-lfs, gitu, lazygit, stow, watchman |
| Languages & runtimes | bun, node@24, pnpm, python@3.9, python@3.10, pyenv, pipx, poetry, rustup, gcc, gcc@11, automake |
| Editors & shell | neovim, d12frosted/emacs-plus/emacs-plus@29, zsh-autosuggestions, zsh-syntax-highlighting, ranger, television |
| CLI utilities | bat, fd, fzf, jq, lsd, ripgrep, zoxide, coreutils, gnu-sed, wget, speedtest-cli, showkey, librsync, wimlib |
| Linters & formatters | mypy, prettier, shellcheck, shfmt, ispell, pygments |
| Mobile / iOS | cocoapods, facebook/fb/idb-companion |
| Window management | asmvik/formulae/yabai, asmvik/formulae/skhd |
| Data & DB | postgresql@14, pgcli |
| Media & docs | imagemagick, mpv, pandoc |
| Security & network | gnupg, pinentry-mac, wireguard-tools |
| Misc | ccusage, vercel, gobject-introspection, python-requests, python-setuptools |

```sh
brew install asmvik/formulae/skhd asmvik/formulae/yabai automake bat bun ccusage \
  cocoapods coreutils d12frosted/emacs-plus/emacs-plus@29 facebook/fb/idb-companion fd \
  fzf gcc gcc@11 gh git git-lfs gitu gnu-sed gnupg \
  gobject-introspection imagemagick ispell jq lazygit librsync lsd mpv mypy neovim \
  node@24 pandoc pgcli pinentry-mac pipx pnpm poetry postgresql@14 prettier pyenv \
  pygments python-requests python-setuptools python@3.10 python@3.9 ranger ripgrep \
  rustup shellcheck shfmt showkey speedtest-cli stow television vercel watchman wget \
  wimlib wireguard-tools zoxide zsh-autosuggestions zsh-syntax-highlighting
```

### Casks

| Category | Packages |
| --- | --- |
| Browsers & comms | brave-browser, discord, telegram, whatsapp, thunderbird, zoom |
| Dev | zed, iterm2, claude, claude-code@latest, codex, chatgpt, openlens, devtoys, linear, linear-linear |
| Productivity | raycast, obsidian, google-drive, monitorcontrol, logi-options+ |
| Security | bitwarden, trezor-suite |
| Fonts | font-fira-code-nerd-font, font-mononoki-nerd-font |
| Other | altserver, openmtp, prusaslicer, tradingview, vorssaint |

```sh
brew install --cask altserver bitwarden brave-browser chatgpt claude claude-code@latest \
  codex devtoys discord font-fira-code-nerd-font font-mononoki-nerd-font google-drive \
  iterm2 linear linear-linear logi-options+ monitorcontrol obsidian openlens openmtp \
  prusaslicer raycast telegram thunderbird tradingview trezor-suite vorssaint whatsapp \
  zed zoom
```
