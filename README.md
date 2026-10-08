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
4. Symlink the dotfiles: `cd dotfiles && mkdir -p ~/.claude ~/.codex && stow ./ -t ~/`
5. Enable the secret-scanning pre-commit hook (local git config, so it does
   not survive a clone):

   ```sh
   git config core.hooksPath .githooks
   ```

6. Write `~/.gitconfig` with your own identity (see [Git](#git)). Pass
   `--file` rather than `--global`: until `~/.gitconfig` exists, `--global`
   writes to `~/.config/git/config` instead, which `stow` has just pointed at
   this repo.

   ```sh
   git config --file ~/.gitconfig user.name  "your name"
   git config --file ~/.gitconfig user.email "you@example.com"
   git config --file ~/.gitconfig user.signingkey "<your GPG key id>"
   ```

7. Start services: `brew services start skhd && brew services start yabai`
8. Apply the macOS settings that no dotfile holds — `⌥1`–`⌥9` switch to
   Desktop 1–9: `./macos-defaults.sh`. The shortcuts only reach desktops that
   exist, so open Mission Control and add desktops until there are 9. If they
   do not take effect, log out and back in.
9. Launch `nvim` once. Lazy bootstraps itself and installs the plugins in
   `.config/nvim/lua/plugins/init.lua`; `lazy-lock.json` pins the versions.

## Git

`.config/git/config` carries the settings that are the same on any machine and
for any person — GPG signing on for commits and tags, `main` as the default
branch, the git-lfs filters. `stow` links it to `~/.config/git/config`.

Identity is not tracked. `[user]` and `[github]` are per-person, not
per-machine, and a clone of this repo should not start committing as me against
a signing key it does not have. Those live in `~/.gitconfig`, which stays out of
the repo — git reads `~/.config/git/config` first and `~/.gitconfig` second, so
anything set there wins. `.config/zsh/.zshrc` treats private shell aliases the
same way, sourcing `~/.config/paliasrc` if it happens to exist.

`.config/lazygit/config.yml` points lazygit's `e` at Zed and returns cleanly to
it afterwards.

## AI tool config

`.config/ai` holds the shared agent instructions, skills, and Claude Code
settings for Claude Code and Codex. Neither tool reads `~/.config/ai`, so the
repo carries committed symlinks at `.claude/` and `.codex/` pointing back into
it, and `stow` links those into place along with everything else:

```sh
mkdir -p ~/.claude ~/.codex
stow ./ -t ~/
```

Create those two directories first. Stow folds a directory that does not yet
exist into a single symlink back to the repo, which would leave the tools
writing sessions and credentials inside the git checkout.

Plugins are not synced either — `.config/ai/PLUGINS.md` lists what to install
in each tool. Claude Code and Codex have separate plugin systems, but most of
these ship for both, by three different routes.

MCP servers are not synced or generated — `.config/ai/MCP.md` lists each one
with the command to add it, and marks the ones that need a GUI so they can be
skipped on a headless machine. See `.config/ai/README.md` for the layout.

Never put a credential anywhere in this repository. Prefer a remote MCP server,
whose token lives in the tool's own credential store after a browser login; a
local server that needs one reads it from the Keychain at runtime.
`.githooks/pre-commit` blocks commits containing credential-shaped strings.

## Packages

Everything I installed deliberately, as of 2026-10-08. Regenerate the Homebrew
tables with `brew leaves --installed-on-request` and `brew list --cask`; the
App Store table is curated rather than generated, see the note under it.

### Formulae

| Category | Packages |
| --- | --- |
| VCS & dev tools | gh, git, git-lfs, gitu, lazygit, stow, watchman, pkgconf |
| Languages & runtimes | bun, node@24, pnpm |
| Editors & shell | neovim, zsh-autosuggestions, zsh-syntax-highlighting, ranger, television, herdr |
| CLI utilities | bat, fd, fzf, jq, lsd, ripgrep, zoxide, coreutils, gnu-sed, wget, speedtest-cli, librsync, mole |
| Linters & formatters | stylua |
| Mobile / iOS | cocoapods, facebook/fb/idb-companion |
| Window management | asmvik/formulae/yabai, asmvik/formulae/skhd |
| Media & docs | mpv, kepubify |
| Security & network | gnupg, pinentry-mac, wireguard-tools |
| Misc | mas, vercel |

```sh
brew install asmvik/formulae/skhd asmvik/formulae/yabai bat bun cocoapods coreutils \
  facebook/fb/idb-companion fd fzf gh git git-lfs gitu gnu-sed gnupg herdr jq kepubify \
  lazygit librsync lsd mas mole mpv neovim node@24 pinentry-mac pkgconf pnpm ranger \
  ripgrep speedtest-cli stow stylua television vercel watchman wget wireguard-tools \
  zoxide zsh-autosuggestions zsh-syntax-highlighting
```

### App Store

Installed through the App Store, so `brew` does not know about them. `mas`
drives the App Store from the CLI, but it cannot sign in — open the App Store
app and sign in first, and note that `mas install` only fetches apps already in
this Apple ID's purchase history.

| Category | Apps |
| --- | --- |
| Dev | Xcode |
| Productivity | Structured, Streaks |
| Travel & finance | Tripsy, Flighty, Crypto Pro |
| Security & network | WireGuard |

```sh
sudo mas install 497799835 1499198946 963034692 1429967544 \
  1358823008 980888073 1451685025
```

Xcode is a ~10 GB download; skip it on a machine that will not build iOS.

This list is curated, not a dump of `mas list`: Numbers ships with macOS and is
left out, and Flighty is wanted on a new machine but is not installed on this
one. Merge by hand rather than overwriting.

### Casks

| Category | Packages |
| --- | --- |
| Browsers & comms | helium-browser, discord, telegram, whatsapp, thunderbird, zoom |
| Dev | zed, iterm2, claude, claude-code@latest, codex, chatgpt, devtoys, linear |
| Productivity | raycast, obsidian, logi-options+, openwhispr |
| Security | bitwarden, trezor-suite |
| Fonts | font-fira-code-nerd-font, font-mononoki-nerd-font |
| Other | altserver, prusaslicer, tradingview, vorssaint |

```sh
brew install --cask altserver bitwarden chatgpt claude claude-code@latest codex devtoys \
  discord font-fira-code-nerd-font font-mononoki-nerd-font helium-browser iterm2 linear \
  logi-options+ obsidian openwhispr prusaslicer raycast telegram thunderbird tradingview \
  trezor-suite vorssaint whatsapp zed zoom
```
