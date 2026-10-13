#!/bin/dash
# yabai signal action for system_woke / display_added (see yabairc). Waking in
# clamshell mode or reconnecting a display can leave the Dock without the
# ⌥2–⌥9 Switch to Desktop hotkeys (⌥1 survives), so they type ™£¢… instead.
# Restarting the Dock re-registers them. Both events often fire together, so
# the lock lets only one restart through; the wait lets the displays settle.
lock="${TMPDIR:-/tmp}/restart-dock.lock"
mkdir "$lock" 2>/dev/null || exit 0
sleep 3
killall Dock
rmdir "$lock"
