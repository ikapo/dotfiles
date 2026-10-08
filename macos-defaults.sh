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

# Apply without logging out. Skipped when writing to a test plist.
if [[ "$hotkeys" == com.apple.symbolichotkeys ]]; then
  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u ||
    echo "Could not apply live; log out and back in."
fi

echo "Done. The Switch to Desktop shortcuts only work for desktops that exist:"
echo "open Mission Control and add desktops until there are 9."
