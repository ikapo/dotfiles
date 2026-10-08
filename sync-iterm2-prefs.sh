#!/usr/bin/env bash
# Regenerate .config/iterm2-prefs/com.googlecode.iterm2.plist from the live
# iTerm2 defaults, with only true per-machine noise stripped. iTerm2 usually
# writes this file back itself (Settings > General > Settings is set to save
# changes automatically), so you should rarely need to run this by hand.
#
# Keep the DROP list narrow. Previously it dropped every "NoSync*" key on the
# assumption those were all UI noise (window positions, "don't show again"
# dialogs), but that also wiped the Claude Code integration's one-time setup
# flags (NoSyncClaudeCodeIntegrationCompleted and friends), which broke the
# integration on reload. Only add a key here once you've confirmed it is
# position/timestamp/counter noise, not integration or migration state.
set -euo pipefail
cd "$(dirname "$0")"

out=.config/iterm2-prefs/com.googlecode.iterm2.plist
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
defaults export com.googlecode.iterm2 "$tmp"

python3 - "$tmp" "$out" <<'PY'
import plistlib, sys

drop_prefixes = (
    "NSWindow Frame", "NSNav", "NSSplitView", "NSToolbar", "PMPrinting",
    "NSOverlayScrollers",
)
drop_keys = {
    "SUHasLaunchedBefore",
    "PrefsCustomFolder", "LoadPrefsFromCustomFolder",  # set by macos-defaults.sh, not by this file
    "NoSyncAllAppVersions",
    "NoSyncBFPRecents",
    "NoSyncBrowserUpsell", "NoSyncBrowserUpsell_selection",
    "NoSyncFrame_SessionsPreferences",
    "NoSyncFrame_SharedPreferences",
    "NoSyncInstallationId",
    "NoSyncLastOSVersion",
    "NoSyncLastShutdownWasClean",
    "NoSyncLastTipTime",
    "NoSyncLaunchExperienceControllerRunCount",
    "NoSyncNextAnnoyanceTime",
    "NoSyncOnboardingWindowHasBeenShown34",
    "NoSyncPermissionToShowTip",
    "NoSyncPersistentRateLimitedUpdates",
    "NoSyncRecordedVariables",
    "NoSyncRestoreWindowsCount",
    "NoSyncSavedWindowPositions",
    "NoSyncStatusToolLastUseDate",
    "NoSyncSuppressedAlertsCatalog",
    "NoSyncTipOfTheDayEligibilityBeganTime",
    "NoSyncTipsToNotShow",
    "NoSyncWindowCornerRadiusCache",
    "NoSyncWindowRestoresWorkspaceAtLaunch",
}

src, dst = sys.argv[1], sys.argv[2]
d = plistlib.load(open(src, "rb"))
kept = {
    k: v for k, v in d.items()
    if k not in drop_keys and not k.startswith(drop_prefixes)
}
print(f"{len(d)} -> {len(kept)} keys", file=sys.stderr)
plistlib.dump(kept, open(dst, "wb"), fmt=plistlib.FMT_XML, sort_keys=True)
PY

plutil -lint "$out"
echo "Wrote $out"
