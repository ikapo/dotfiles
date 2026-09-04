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

`.config/ai` holds the shared agent instructions, skills, and Claude Code
settings for Claude Code and Codex. `stow` puts it at `~/.config/ai`; each tool
then needs one symlink to the file it expects:

```sh
stow ./ -t ~/

ln -sfn ~/.config/ai/AGENTS.md            ~/.claude/CLAUDE.md
ln -sfn ~/.config/ai/AGENTS.md            ~/.codex/AGENTS.md
ln -sfn ~/.config/ai/skills               ~/.claude/skills
ln -sfn ~/.config/ai/claude/settings.json ~/.claude/settings.json
```

MCP servers are not synced or generated — `.config/ai/MCP.md` lists each one
with the command to add it, and marks the ones that need a GUI so they can be
skipped on a headless machine. See `.config/ai/README.md` for the layout.

Never put a credential anywhere in this repository. Prefer a remote MCP server,
whose token lives in the tool's own credential store after a browser login; a
local server that needs one reads it from the Keychain at runtime.
`.githooks/pre-commit` blocks commits containing credential-shaped strings.

## Packages

Everything I installed deliberately, as of 2026-09-04. Regenerate with
`brew leaves --installed-on-request` and `brew list --cask`.

### Formulae

| Category | Packages |
| --- | --- |
| VCS & dev tools | gh, git, git-lfs, github-mcp-server, gitu, lazygit, stow, watchman |
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
| Productivity | raycast, obsidian, google-drive, monitorcontrol, logi-options+, openwhispr |
| Security | bitwarden, trezor-suite |
| Fonts | font-fira-code-nerd-font, font-mononoki-nerd-font |
| Other | altserver, openmtp, prusaslicer, tradingview, vorssaint |

```sh
brew install --cask altserver bitwarden brave-browser chatgpt claude claude-code@latest \
  codex devtoys discord font-fira-code-nerd-font font-mononoki-nerd-font google-drive \
  iterm2 linear linear-linear logi-options+ monitorcontrol obsidian openlens openmtp \
  openwhispr prusaslicer raycast telegram thunderbird tradingview trezor-suite vorssaint \
  whatsapp \
  zed zoom
```
