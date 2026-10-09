#!/usr/bin/env bash
# macOS settings that live outside any dotfile. Safe to re-run.
#
# Usage: ./macos-defaults.sh [plist]
# Pass a plist path to write there instead of the live preferences (for testing).
set -euo pipefail

hotkeys="${1:-com.apple.symbolichotkeys}"
option=524288 # modifier mask for ⌥

# ⌥1..⌥9 → Switch to Desktop 1..9 (symbolic hotkey IDs 118–126).
# Each pair is "<digit> <keycode>"; macOS keycodes for the number row are not sequential.
id=118
for pair in "1 18" "2 19" "3 20" "4 21" "5 23" "6 22" "7 26" "8 28" "9 25"; do
  read -r digit keycode <<<"$pair"
  ascii=$((48 + digit))
  defaults write "$hotkeys" AppleSymbolicHotKeys -dict-add "$id" "
    <dict>
      <key>enabled</key><true/>
      <key>value</key><dict>
        <key>type</key><string>standard</string>
        <key>parameters</key><array>
          <integer>$ascii</integer><integer>$keycode</integer><integer>$option</integer>
        </array>
      </dict>
    </dict>"
  id=$((id + 1))
done

# Everything below changes live settings, so it is skipped for a test plist.
if [[ "$hotkeys" != com.apple.symbolichotkeys ]]; then
  echo "Wrote the hotkeys to $hotkeys."
  exit 0
fi

# Apply the hotkeys without logging out.
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u ||
  echo "Could not apply live; log out and back in."

# Key repeat: how fast a held key repeats, and the delay before it starts.
# 2/15 is the fastest pair selectable in System Settings' sliders; most apps
# pick this up live, but Terminal-style apps may need a restart.
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

echo "Done."
echo "The Switch to Desktop shortcuts only work for desktops that exist:"
echo "open Mission Control and add desktops until there are 9."
echo "If a keyboard paired/connected AFTER this ran doesn't trigger the"
echo "shortcuts (⌥+number types a special character instead), reboot — a"
echo "keyboard added after the hotkeys were set can need a full restart"
echo "before WindowServer picks it up, even though it types normally."
