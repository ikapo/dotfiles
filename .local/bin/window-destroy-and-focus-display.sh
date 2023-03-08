#!/bin/dash
# Get current display ID
displayId=$(yabai -m query --windows --window | jq -re ".display")

# Get current window ID
currentWindowId=$(yabai -m query --windows --window | jq -re ".id")

# Destroy current window
yabai -m window $currentWindowId --close

# Get the first window that is visible, not focused and in the current display
windowInDisplay=$(yabai -m query --windows | jq -re ".[] | select(.[\"is-visible\"] == true and .[\"has-focus\"] == false and .display == $displayId).id" | sed 1q)

# Focus on that window, if it exists
yabai -m window --focus $windowInDisplay
