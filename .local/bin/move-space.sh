#!/bin/dash
windowId=$(yabai -m query --windows --window | jq -re ".id")
yabai -m window --space $1
yabai -m window --focus $windowId
