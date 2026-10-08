# Moving to a new Mac

A checklist for setting up a new machine from this repo. [How to
install](README.md#how-to-install) covers the same ground for a from-scratch
clone; this adds the parts that only matter when there's an old Mac to carry
things over from — credentials and local app data that are deliberately not
in git.

Work through it in order; later steps assume earlier ones are done.

## On the new Mac

- [ ] Install Homebrew, clone the repo, and run [How to install](README.md#how-to-install)
      steps 1–3: `brew bundle` (sign in to the App Store app first; add
      `HOMEBREW_BUNDLE_MAS_SKIP=497799835` to skip Xcode's ~10 GB download).
- [ ] Step 4: create `~/.claude ~/.codex ~/.config/{herdr,television,gh,gnupg}`
      (`chmod 700` the last one), then `stow -n -v ./ -t ~/` as a dry run
      before the real `stow ./ -t ~/`. If it reports a conflict (commonly
      `~/.claude/settings.json` if Claude Code has already run on this Mac, or
      `~/.zprofile`/`~/.config/gh/config.yml` from Homebrew's or gh's own
      first-run setup), move the conflicting file aside and stow again.
- [ ] Step 5: `git config core.hooksPath .githooks`.

## Carry over from the old Mac

Nothing here is in git on purpose — identity and credentials don't belong in a
public repo, and most of it is per-machine state anyway.

- [ ] GPG signing key (commits are signed, so do this before the first one):
      on the **old** Mac, `gpg --export-secret-keys --armor DACDD792 > key.asc`;
      copy it over securely; on the **new** Mac, `gpg --import key.asc`; delete
      `key.asc` on both ends. `gpg-agent.conf` is tracked (see [Git](README.md#git)),
      so signing should prompt with a native dialog rather than failing with
      `Inappropriate ioctl for device` — if it still does, `gpgconf --kill
      gpg-agent` and retry.
- [ ] `~/.ssh` (keys + `config`).
- [ ] `~/.config/paliasrc` (private shell aliases, sourced by `.zshrc` if present).
- [ ] Write `~/.gitconfig` with your identity — [Git](README.md#git) has the
      commands. Use `--file ~/.gitconfig`, not `--global`, until that file exists.
- [ ] Raycast settings (export, or turn on Cloud Sync).
- [ ] Browser bookmarks/history, if moving off Helium's predecessor.
- [ ] Obsidian vaults, unless they already sync.
- [ ] Claude history and memory: `~/.claude-mem` and `~/.claude/projects`.

## Finish the setup

- [ ] `skhd --start-service && yabai --start-service` (not `brew services
      start` — the `asmvik` tap's formulae don't implement it), then grant both
      Accessibility access when macOS prompts
      (System Settings → Privacy & Security → Accessibility).
- [ ] `./macos-defaults.sh` — sets ⌥1–⌥9 to switch desktops and points iTerm2
      at `.config/iterm2-prefs`. The shortcuts only reach desktops that exist,
      so open Mission Control and add desktops until there are 9.
- [ ] Restart iTerm2 so it loads settings from the repo.
- [ ] Remap Caps Lock to Escape by hand — macOS stores this per keyboard, not
      as one global setting, so it isn't scriptable: System Settings →
      Keyboard → Keyboard Shortcuts… → Modifier Keys.
- [ ] `herdr integration install claude` (and `codex`, if used there too).
- [ ] Install [One](https://getone.one) — not on Homebrew, updates itself.
- [ ] `gh auth login`, then sign in to Claude Code and Codex.
- [ ] Install the plugins in [`.config/ai/PLUGINS.md`](.config/ai/PLUGINS.md)
      and add the MCP servers in [`.config/ai/MCP.md`](.config/ai/MCP.md).
- [ ] Launch `nvim` once so Lazy bootstraps its plugins.

## Sanity check

- [ ] `stow -n -v ./ -t ~/` reports nothing to do.
- [ ] `brew bundle check` reports everything installed.
- [ ] A test commit is GPG-signed (`git log --show-signature -1`).
