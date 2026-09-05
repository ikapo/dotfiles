# Ikapo's Dotfiles

These are my dotfiles.

I use MacOS.

I edit with [Zed](https://zed.dev/) and [Neovim](https://neovim.io/) (via
[NvChad](https://nvchad.com/)). Both use Doom Emacs style `SPC` keybindings —
see `.config/zed/keymap.json` and `.config/nvim/lua/mappings.lua`, which are
kept in sync with each other.

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
7. Launch `nvim` once. Lazy bootstraps itself and installs the plugins in
   `.config/nvim/lua/plugins/init.lua`; `lazy-lock.json` pins the versions.

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

Everything I installed deliberately, as of 2026-09-05. Regenerate with
`brew leaves --installed-on-request` and `brew list --cask`.

### Formulae

| Category | Packages |
| --- | --- |
| VCS & dev tools | gh, git, git-lfs, gitu, lazygit, stow, watchman |
| Languages & runtimes | bun, node@24, pnpm, pyenv, python@3.12, gcc, gcc@11, libgccjit, zlib |
| Editors & shell | neovim, zsh-autosuggestions, zsh-syntax-highlighting, ranger, television |
| CLI utilities | bat, fd, fzf, jq, lsd, ripgrep, zoxide, coreutils, gnu-sed, wget, speedtest-cli, librsync |
| Linters & formatters | mypy, shellcheck, shfmt, stylua, pygments |
| Mobile / iOS | cocoapods, facebook/fb/idb-companion |
| Window management | asmvik/formulae/yabai, asmvik/formulae/skhd |
| Media & docs | imagemagick, mpv, pandoc |
| Security & network | gnupg, pinentry-mac, wireguard-tools |
| Misc | ccusage, vercel, python-requests, python-setuptools |

```sh
brew install asmvik/formulae/skhd asmvik/formulae/yabai bat bun ccusage cocoapods \
  coreutils facebook/fb/idb-companion fd fzf gcc gcc@11 gh git git-lfs gitu gnu-sed \
  gnupg imagemagick jq lazygit libgccjit librsync lsd mpv mypy neovim node@24 pandoc \
  pinentry-mac pnpm pyenv pygments python-requests python-setuptools python@3.12 ranger \
  ripgrep shellcheck shfmt speedtest-cli stow stylua television vercel watchman wget \
  wireguard-tools zlib zoxide zsh-autosuggestions zsh-syntax-highlighting
```

### Casks

| Category | Packages |
| --- | --- |
| Browsers & comms | brave-browser, discord, telegram, whatsapp, thunderbird, zoom |
| Dev | zed, iterm2, claude, claude-code@latest, codex, chatgpt, devtoys, linear |
| Productivity | raycast, obsidian, google-drive, logi-options+, openwhispr |
| Security | bitwarden, trezor-suite |
| Fonts | font-fira-code-nerd-font, font-mononoki-nerd-font |
| Other | altserver, prusaslicer, tradingview, vorssaint |

```sh
brew install --cask altserver bitwarden brave-browser chatgpt claude claude-code@latest \
  codex devtoys discord font-fira-code-nerd-font font-mononoki-nerd-font google-drive \
  iterm2 linear logi-options+ obsidian openwhispr prusaslicer raycast telegram \
  thunderbird tradingview trezor-suite vorssaint whatsapp zed zoom
```
