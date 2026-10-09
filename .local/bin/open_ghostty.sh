#!/usr/bin/env bash

# Detects if Ghostty is running
if ! pgrep -f "Ghostty" > /dev/null 2>&1; then
    open -a "/Applications/Ghostty.app"
else
    # Create a new window
    script='tell application "Ghostty" to new window'
    ! osascript -e "${script}" > /dev/null 2>&1 && {
        # Get pids for any app with "Ghostty" and kill
        while IFS="" read -r pid; do
            kill -15 "${pid}"
        done < <(pgrep -f "Ghostty")
        open -a "/Applications/Ghostty.app"
    }
fi
