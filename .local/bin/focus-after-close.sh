#!/bin/dash
# yabai signal action for window_destroyed / application_terminated (see
# yabairc). When the closed window was its app's last one, macOS leaves that app
# active with no window and nothing has focus. Hand focus to a visible window on
# the same display.

# macOS already moved focus to a sibling window: leave it there.
yabai -m query --windows --window > /dev/null 2>&1 && exit 0

displayIndex=$(yabai -m query --displays --display | jq -re ".index")

# Standard windows only: overlays such as OpenWhispr's sticky recorder panel are
# visible on every space but can't take keyboard focus. Skip the window that
# just closed, which yabai can still list as visible for a moment.
windowId=$(yabai -m query --windows | jq -re \
    --argjson display "$displayIndex" --argjson closed "${YABAI_WINDOW_ID:-0}" \
    'first(.[] | select(.["is-visible"] and (.["is-minimized"] | not) and .subrole == "AXStandardWindow" and .display == $display and .id != $closed)).id')

[ -n "$windowId" ] && yabai -m window --focus "$windowId"
