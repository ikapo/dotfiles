#!/usr/bin/env bash

# Detects if Ghostty is running
if ! pgrep -f "Ghostty" > /dev/null 2>&1; then
    open -a "/Applications/Ghostty.app"
else
    # Create a new window
    osascript -e 'tell application "Ghostty" to new window' > /dev/null 2>&1
fi
