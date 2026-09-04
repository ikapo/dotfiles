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
ai-sync         # apply: writes Claude's mcp.json, patches Zed's
                # context_servers, registers Codex MCP servers, and
                # symlinks AGENTS.md/CLAUDE.md and skills
ai-sync --check # report drift only; exit 1 if out of sync, 0 if clean
```

`ai-sync` is idempotent — re-run it any time `.config/ai` changes. Never put a
credential in `.config/ai/mcp.json`; route it through a `.local/bin` wrapper
that reads the macOS Keychain at startup, like `gh-mcp` (see below).

## MCP servers (Zed)

Zed's `settings.json` has no environment-variable interpolation and no secret
references, so any token written there is plaintext in this repo. Instead, every
MCP server is launched through a small wrapper in `.local/bin/` that reads its
credential from the macOS Keychain at startup.

The GitHub server is the worked example: `.local/bin/gh-mcp`.

`settings.json` stays tracked rather than ignored, so it remains the single
source of truth — Zed rewrites it whenever you change a setting from the UI, so
a generated copy would drift. `.githooks/pre-commit` is the backstop: it blocks
any commit containing a credential-shaped string.

### Adding a new server

1. Install the server binary, ideally via Homebrew so it is pinned to a real
   package rather than an extension's download directory:

   ```sh
   brew install <server>
   ```

2. Store the credential in the Keychain. The same command rotates it later —
   `-U` updates an existing entry:

   ```sh
   security add-generic-password -a "$USER" -s <service-name> -w '<token>' -U
   ```

3. Add a wrapper at `.local/bin/<name>-mcp`, `chmod +x` it, and use absolute
   paths — Zed does not reliably inherit `$PATH`:

   ```sh
   #!/bin/sh
   TOKEN_ENV_VAR=$(security find-generic-password -s <service-name> -w) || {
   	echo "<name>-mcp: no '<service-name>' entry in Keychain" >&2
   	exit 1
   }
   export TOKEN_ENV_VAR

   exec /opt/homebrew/bin/<server> stdio "$@"
   ```

4. Symlink it into `~`, or the script will not exist at the path Zed runs and
   the server will fail to start with no obvious cause:

   ```sh
   stow ./ -t ~/
   ```

5. Point Zed at the wrapper in `.config/zed/settings.json`:

   ```json
   "context_servers": {
     "<name>": {
       "command": "/Users/ikapo/.local/bin/<name>-mcp",
       "args": []
     }
   }
   ```

6. Verify the handshake before trusting it, by piping a JSON-RPC `initialize`
   into the wrapper. A `serverInfo` reply means the Keychain read and the binary
   both work:

   ```sh
   { printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"probe","version":"0"}}}'
     sleep 2
   } | ~/.local/bin/<name>-mcp
   ```

### Prefer a `command` entry over extensions

Zed extensions that bundle an MCP server define their own `settings` block, and
the token has to go in it verbatim — there is no way to indirect it. A plain
`command` entry runs a process instead, which is what makes the Keychain wrapper
possible. The GitHub server was originally the `mcp-server-github` extension; it
was dropped for exactly this reason, and the extension turned out to just
download the same binary Homebrew ships.

Do not add a `"source": "custom"` key. Older Zed docs still show it, but Zed
1.18 rejects it with `property "source" is not allowed` and its settings
migrator strips the line.

## Packages

Everything I installed deliberately, as of 2026-09-03. Regenerate with
`brew leaves --installed-on-request` and `brew list --cask`.

### Formulae

| Category | Packages |
| --- | --- |
| VCS & dev tools | gh, git, git-lfs, gitu, lazygit, stow, watchman, github-mcp-server |
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
  fzf gcc gcc@11 gh git git-lfs github-mcp-server gitu gnu-sed gnupg \
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
