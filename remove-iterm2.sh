#!/usr/bin/env bash
# Fully removes iTerm2, in case it ever shows up on a machine again (e.g.
# carried over by Migration Assistant from an old Mac). Safe to re-run.
#
# `brew uninstall --cask iterm2 --zap` alone isn't enough: on this machine it
# errored with "Unable to remove some files. Please enable Full Disk Access
# for your terminal" and left the app, its Caskroom copy, and most of its zap
# paths behind. This re-deletes everything by hand afterwards regardless of
# whether the brew step succeeded.
#
# The path list below is the iterm2 cask's zap stanza as of 2026-10-09
# (`brew info --cask --json=v2 iterm2`), not derived at runtime, so it stays
# correct even after the cask is uninstalled and no longer tracked here.
set -uo pipefail

if brew list --cask iterm2 &>/dev/null; then
  brew uninstall --cask iterm2 --zap --force || true
fi

rm -rf /opt/homebrew/Caskroom/iterm2
rm -rf "/Applications/iTerm.app"

cd "$HOME"
rm -rf "Library/Application Scripts/com.googlecode.iterm2.iTermFileProvider"
rm -rf Library/Application\ Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.googlecode.iterm2.itermai.sfl*
rm -rf Library/Application\ Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.googlecode.iterm2.sfl*
rm -rf "Library/Application Support/iTerm"
rm -rf "Library/Application Support/iTerm2"
rm -rf Library/Caches/com.googlecode.iterm2
rm -rf Library/Containers/com.googlecode.iterm2.iTermFileProvider
rm -rf Library/Containers/iTermAI
rm -rf Library/Cookies/com.googlecode.iterm2.binarycookies
rm -rf Library/HTTPStorages/com.googlecode.iterm2
rm -rf Library/HTTPStorages/com.googlecode.iterm2.binarycookies
rm -rf Library/Preferences/com.googlecode.iterm2.plist
rm -rf Library/Preferences/com.googlecode.iterm2.private.plist
rm -rf Library/Saved\ Application\ State/com.googlecode.iterm2*.savedState
rm -rf Library/WebKit/com.googlecode.iterm2

echo "iTerm2 and all its files are gone."
