# Ikapo's Dotfiles

These are my dotfiles.

I use MacOS.

I edit with [Zed](https://zed.dev/) and [Neovim](https://neovim.io/) (via
[NvChad](https://nvchad.com/)). Both use Doom Emacs style `SPC` keybindings —
see `.config/zed/keymap.json` and `lua/mappings.lua` in
[ikapo/nvim](https://github.com/ikapo/nvim), which are kept in sync with each
other. The Neovim config is its own repo, shared with my Orange Pis.

I window manage with [yabai](https://github.com/koekeishiya/yabai) and [skhd](https://github.com/koekeishiya/skhd).

I manage packages with [Homebrew](https://brew.sh/).

Moving from an existing Mac? See [TRANSFER.md](TRANSFER.md) instead — same
steps, plus what to carry over by hand. Setting up a Mac that only runs agents
over SSH? See [Headless Mac](#headless-mac).

## How to install

1. [Install Homebrew](https://brew.sh/)
2. Clone the repository: `git clone https://github.com/ikapo/dotfiles && cd dotfiles`
3. Sign in to the App Store app, then install every package in the `Brewfile`
   (see [Packages](#packages)). `mas` cannot sign in for you, so without that
   the App Store entries fail; the rest still installs. Leave Xcode out with
   the variable if this machine will not build iOS:

   ```sh
   brew bundle                                     # everything
   HOMEBREW_BUNDLE_MAS_SKIP=497799835 brew bundle  # everything but Xcode
   ```

4. Symlink the dotfiles. Create the directories first, or stow folds each one
   into a single link and the tool's state and credentials land in the repo:

   ```sh
   mkdir -p ~/.claude ~/.local/bin ~/.config/{herdr,television,gh,gnupg,zsh}
   chmod 700 ~/.config/gnupg
   ln -s .config/gnupg ~/.gnupg   # for GUI apps, which never see GNUPGHOME
   stow ./ -t ~/
   ```

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

7. Start services: `skhd --start-service && yabai --start-service`. The
   `asmvik` tap's formulae manage their own launchd service rather than
   implementing `brew services`, so `brew services start` fails on them with
   "has not implemented #plist, #service".
8. Apply the macOS settings that no dotfile holds — `⌥1`–`⌥9` switch to
   Desktop 1–9 and the fastest key repeat rate: `./macos-defaults.sh`. The
   shortcuts only reach desktops that exist, so open Mission Control and add
   desktops until there are 9. If they do not take effect, log out and back in.
9. Remap Caps Lock to Escape — not scriptable, since macOS stores it per
   keyboard rather than as one global setting: System Settings → Keyboard →
   Keyboard Shortcuts… → Modifier Keys, pick the keyboard if more than one is
   listed, set Caps Lock to Escape.
10. Install [One](https://getone.one) from its website — it is not on Homebrew
    and updates itself. Do this after `herdr` from the [Formulae](#formulae)
    list is installed. Its state in `~/.config/one` is not tracked.
11. Clone the Neovim config (its own repo, not stowed) and launch `nvim` once.
    Lazy installs the plugins pinned in `lazy-lock.json` and treesitter
    parsers compile on first file open (needs `tree-sitter-cli`); then run
    `:MasonInstallAll` for the language servers:

    ```sh
    git clone git@github.com:ikapo/nvim.git ~/.config/nvim
    ```

    Afterwards `dotpull` (in `aliasrc`) pulls both repos and restows.

## Headless Mac

A Mac reached only over SSH, running Claude Code — no editor, no
window manager. Follow [How to install](#how-to-install) with these changes.

**Steps that change:**

- Step 3: install `Brewfile.server` instead: the CLI half of `Brewfile`,
  Xcode, Obsidian, Ghostty, Helium, Claude, Claude Code, Grok, Grok Build and
  T3 Code. Sign in to the App Store app first, as for `Brewfile` — do it at
  the Mac or over Screen Sharing, since `mas` cannot sign in from SSH:

  ```sh
  brew bundle --file=Brewfile.server
  ```

  Then point the developer tools at Xcode — Homebrew's installer set them to
  the Command Line Tools, and `xcodebuild` refuses to run against those —
  accept the licence and install Xcode's first-launch components, or
  `xcodebuild` stops on a prompt the first time it runs over SSH:

  ```sh
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -license accept
  sudo xcodebuild -runFirstLaunch
  ```

- Step 4: stow the whole repo as usual. The yabai, skhd and Zed configs land
  too but stay inert without their apps. GnuPG is not installed
  and nothing signs (see Signing below), so skip the `chmod` and the `~/.gnupg`
  link — but keep `gnupg` in the `mkdir`, or stow folds `~/.config/gnupg` into
  the repo and anything that ever runs gpg writes its keyring there:

  ```sh
  mkdir -p ~/.claude ~/.local/bin ~/.config/{herdr,television,gh,gnupg,zsh}
  stow ./ -t ~/
  ```
- Steps 7–9 (yabai/skhd, `macos-defaults.sh`, Caps Lock) and step 10 (One) do
  not apply. Run the one line of `macos-defaults.sh` that does, plus restart
  after a power cut:

  ```sh
  sudo pmset -a sleep 0 autorestart 1
  ```

- Step 11: still clone the Neovim config. `EDITOR` is `nvim`, and `dotpull`
  stops before restowing if `~/.config/nvim` is missing.

**Signing.** `.config/git/config` signs every commit, and `gpg-agent.conf`
asks for the passphrase through `pinentry-mac` — a dialog on a screen nobody
is watching, so commits from an SSH session hang or fail. Turn signing off in
this machine's `~/.gitconfig`, which overrides the repo's file:

```sh
git config --file ~/.gitconfig commit.gpgSign false
git config --file ~/.gitconfig tag.gpgSign false
```

**Keychain.** Claude Code keeps its login in the macOS Keychain, and any MCP
server that needs a secret reads it from there (see `.config/ai/MCP.md`). An SSH session
may find the login keychain locked; unlock it before signing in or starting a
server that reads it:

```sh
security unlock-keychain ~/Library/Keychains/login.keychain-db
```

**Sessions.** Run agents inside `herdr`, which keeps them alive when SSH
drops. From another machine, `herdr --remote <ssh-target>` attaches straight
to it.

**MCP servers.** Skip the ones `.config/ai/MCP.md` marks GUI-only
(`ios-simulator`, `xcode`); the rest work over plain HTTPS. Xcode itself is
still useful without them — `xcodebuild` builds and tests over SSH.

**Connecting from Ghostty.** Ghostty sets `TERM=xterm-ghostty`, which a fresh
Mac does not recognise ("unknown terminal type") — not even with Ghostty
installed, since Ghostty keeps the entry inside its app bundle and points only
its own windows at it. Copy the terminfo entry over once, from the machine
running Ghostty:

```sh
infocmp -x xterm-ghostty | ssh <ssh-target> -- tic -x -
```

**Obsidian.** Agents read and write the vault, which syncs through Obsidian
Sync — and Sync only runs while the Obsidian app is open. Set it up at the Mac
or over Screen Sharing:

1. Open Obsidian, sign in to the Obsidian account, and pick **Open vault from
   Obsidian Sync**. Choose the vault, and put it at `~/Workspace/Obsidian` —
   the same path as on the laptop, which notes and agent memory refer to.
2. Let the first sync finish before an agent touches the vault.
3. Add Obsidian to System Settings → General → Login Items, so it starts —
   and keeps syncing — after every reboot.

**Staying current.** A launchd agent runs what `dotpull` does every hour and
at login, so changes pushed from the laptop reach this Mac without anyone
logging in. Aliases do not exist outside an interactive shell, so the command
is spelled out, and launchd starts jobs with a bare `PATH` that lacks
Homebrew's `stow`. `--ff-only` makes a run fail rather than merge if this
Mac has local commits; the log says so. Both clones must use HTTPS, as in
step 2 — a background job cannot unlock an SSH key. If
`git -C ~/Workspace/dotfiles remote get-url origin` (or the same for
`~/.config/nvim`) starts with `git@`, switch it with
`git remote set-url origin https://github.com/ikapo/<repo>.git`, then run
`gh auth setup-git` so pushes from this Mac still authenticate.

```sh
cat > ~/Library/LaunchAgents/com.ikapo.dotpull.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.ikapo.dotpull</string>
  <key>ProgramArguments</key><array>
    <string>/bin/zsh</string><string>-c</string>
    <string>date; git -C ~/Workspace/dotfiles pull --ff-only &amp;&amp; git -C ~/.config/nvim pull --ff-only &amp;&amp; stow -d ~/Workspace/dotfiles -t ~ .</string>
  </array>
  <key>EnvironmentVariables</key><dict><key>PATH</key><string>/opt/homebrew/bin:/usr/bin:/bin</string></dict>
  <key>StartInterval</key><integer>3600</integer>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>/tmp/dotpull.log</string>
  <key>StandardErrorPath</key><string>/tmp/dotpull.log</string>
</dict></plist>
EOF
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.ikapo.dotpull.plist
```

Check it with `tail /tmp/dotpull.log`. It pulls and restows only: a new entry
in `Brewfile.server` still needs `brew bundle --file=Brewfile.server` by hand,
since an unattended cask install can stop on a password prompt. Plugins are
not installed by the job either. A plugin install replaces the
`.claude/settings.json` symlink, which would stop later pulls. Instead,
`.config/ai/AGENTS.md` has Claude install missing plugins at the start of each
session and restore the symlink.

**Not in the repo:** turn on System Settings → General → Sharing → Remote
Login. With FileVault on, a reboot waits at the unlock screen before your
account — and its herdr sessions — comes up, so decide how you will unlock it
remotely, or leave FileVault off and turn on automatic login.

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

`.config/gh/config.yml` holds gh's settings and aliases; the login token in
`hosts.yml` beside it stays out of the repo. `.config/herdr/config.toml` and
`.config/television/config.toml` are tracked the same way, without the runtime
files around them.

`.config/gnupg/gpg-agent.conf` and `gpg.conf` are tracked the same way too —
notably the line that points gpg-agent at `pinentry-mac` for a native
passphrase dialog instead of a curses prompt that fails outside a real
terminal. Everything else in that directory (keys, keyring, trustdb) stays
out of the repo and must exist as a real directory before `stow` runs, same
as `herdr`/`television`/`gh`.

`.config/ghostty/config` holds Ghostty's settings as plain text; `stow` just
links the file into place, and Ghostty reloads it live on save.

`.config/lazygit/config.yml` points lazygit's `e` at Zed and returns cleanly to
it afterwards.

## AI tool config

`.config/ai` holds Claude Code's agent instructions and settings.
Claude Code does not read `~/.config/ai`, so the repo carries committed
symlinks in `.claude/` pointing back into it, and `stow` links those into
place along with everything else:

```sh
mkdir -p ~/.claude
stow ./ -t ~/
```

Create that directory first. Stow folds a directory that does not yet exist
into a single symlink back to the repo, which would leave Claude Code writing
sessions and credentials inside the git checkout.

Plugins and third-party skills are not synced either — `.config/ai/PLUGINS.md`
lists what to install. Skills come from the `skills` CLI.

MCP servers are not synced or generated — `.config/ai/MCP.md` lists each one
with the command to add it, and marks the ones that need a GUI so they can be
skipped on a headless machine. See `.config/ai/README.md` for the layout.

Never put a credential anywhere in this repository. Prefer a remote MCP server,
whose token lives in the tool's own credential store after a browser login; a
local server that needs one reads it from the Keychain at runtime.
`.githooks/pre-commit` blocks commits containing credential-shaped strings.

## Packages

Everything I installed deliberately, as of 2026-10-08. `Brewfile` holds the
same list and `brew bundle` installs it; keep the two in step. To spot drift,
compare against `brew leaves --installed-on-request` and `brew list --cask`
rather than `brew bundle dump`, which also lists every dependency. The App Store
list is curated rather than generated, see the note under it.

### Formulae

| Category | Packages |
| --- | --- |
| VCS & dev tools | gh, git, git-lfs, gitu, lazygit, stow, watchman, pkgconf |
| Languages & runtimes | bun, node@24, pnpm, uv |
| Editors & shell | neovim, tree-sitter-cli, zsh-autosuggestions, zsh-syntax-highlighting, ranger, pillow, television, herdr |
| CLI utilities | bat, fd, fzf, jq, lsd, ripgrep, zoxide, coreutils, gnu-sed, wget, speedtest-cli, librsync, mole, todoist-cli, skills |
| Linters & formatters | stylua |
| Mobile / iOS | cocoapods, fastlane, facebook/fb/idb-companion, mobai-app/tap/simslim |
| Window management | asmvik/formulae/yabai, asmvik/formulae/skhd |
| Media & docs | mpv, kepubify, md2pdf |
| Security & network | gnupg, pinentry-mac, wireguard-tools |
| Misc | mas |

### App Store

Installed through the App Store; `brew bundle` hands these to `mas`, which
drives the App Store from the CLI but cannot sign in — open the App Store
app and sign in first, and note that `mas install` only fetches apps already in
this Apple ID's purchase history.

| Category | Apps |
| --- | --- |
| Dev | Xcode |
| Productivity | Structured, Streaks |
| Travel & finance | Tripsy, Flighty, Crypto Pro |
| Security & network | WireGuard |

Xcode is a ~10 GB download; skip it on a machine that will not build iOS.

This list is curated, not a dump of `mas list`. Apple's iWork apps (Numbers,
Keynote, Pages) come preinstalled on new Macs but are ordinary App Store apps;
I don't use them, so they're deleted rather than listed. Merge by hand rather
than overwriting.

### Casks

| Category | Packages |
| --- | --- |
| Browsers & comms | helium-browser, telegram, whatsapp, zoom |
| Dev | zed, ghostty, claude, claude-code@latest, grok-bot, grok-build, t3-code@nightly, linear, vercel, loops-so/tap/loops |
| Productivity | obsidian, openlogi, monitorcontrol, wispr-flow, todoist-app |
| Security | bitwarden, trezor-suite |
| Fonts | font-mononoki-nerd-font |
| Other | tradingview, vorssaint, spotify |
