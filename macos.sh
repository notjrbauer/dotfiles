#!/usr/bin/env bash
# macos.sh — opinionated macOS defaults, kept to what still works.
#
# Descended from Mathias Bynens' .osx (https://mths.be/osx), with everything
# that died between Yosemite and macOS 26 stripped out:
#   - Dashboard keys            — Dashboard removed in 10.15
#   - the whole Safari block    — Safari's prefs are sandboxed; the writes no-op
#   - tmutil disablelocal       — removed from tmutil
#   - EmptyTrashSecurely        — removed in 10.11
#   - sleepimage rm / chflags   — SIP-protected, and Apple Silicon owns sleep
#   - nvram boot-args="mbasd=1" — needs reduced security on Apple Silicon and
#                                 risks an unbootable machine, for a 2010 SuperDrive
#   - menuExtras / systemuiserver — superseded by Control Center
#   - AppleFontSmoothing        — subpixel AA gone since Mojave
#   - Twitter.app / GPGMail / Dropbox — dead apps
#
# Deliberately requires NO sudo: every setting below is per-user. Nothing here
# changes system policy, which also means nothing here will fight MDM.
#
# Run it explicitly (`make macos`). bootstrap.sh does not call it — changing
# system preferences shouldn't be a side effect of setting up a laptop.
#
# Safe to re-run: `defaults write` is idempotent.
set -euo pipefail

echo "==> macOS defaults"

###############################################################################
# Keyboard & input — the reason this file exists                              #
###############################################################################

# Key repeat instead of the accent-picker popup. Non-negotiable in a modal
# editor: without it, holding j/k in nvim opens a diacritic menu.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Repeat rate, in 15ms ticks. KeyRepeat 1 is the floor macOS accepts (~15ms
# between repeats) and InitialKeyRepeat 20 (~300ms) is the pause before repeat
# starts. These are the .osx values -- deliberately the fastest setting, well
# past what the Keyboard settings pane can reach, so holding j/k scrolls a
# buffer at full speed.
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 20

# Tab reaches every control in dialogs, not just text fields.
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Scroll direction: content follows the fingers = OFF, i.e. the pre-Lion
# "traditional" direction .osx set. Already the case on this machine; here so a
# fresh one matches instead of defaulting to natural.
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Trackpad: tap to click, for this user and the login screen.
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

###############################################################################
# Text substitution — all of these corrupt code                               #
###############################################################################

defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

###############################################################################
# Responsiveness — "faster popup"                                             #
###############################################################################

# Dock shows the instant you hit the edge, with no slide animation.
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock autohide -bool true

# Mission Control and window resize.
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Spring-loaded folders open immediately when you hover with a dragged file.
defaults write NSGlobalDomain com.apple.springing.enabled -bool true
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Finder's own animations, including the Get Info zoom.
defaults write com.apple.finder DisableAllAnimations -bool true

# Don't animate app launches from the Dock.
defaults write com.apple.dock launchanim -bool false

# Keep Spaces in the order I put them in.
defaults write com.apple.dock mru-spaces -bool false

###############################################################################
# Finder                                                                      #
###############################################################################

defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Search the current folder, not the whole Mac, by default.
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Column view everywhere. Other codes: `icnv` (icon), `Nlsv` (list), `Flwv` (gallery).
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder QuitMenuItem -bool true

# No .DS_Store on network shares.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Expanded save/print sheets instead of the collapsed one-line version.
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk, not iCloud, by default.
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# ~/Library is hidden by default; unhide it.
chflags nohidden "$HOME/Library"

###############################################################################
# Screenshots                                                                 #
###############################################################################

mkdir -p "$HOME/Desktop/screenshots"
defaults write com.apple.screencapture location -string "$HOME/Desktop/screenshots"
defaults write com.apple.screencapture type -string "png"
# The drop shadow adds ~100px of transparent margin to every window capture.
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Misc                                                                        #
###############################################################################

# Lock as soon as the screensaver starts. (MDM may already enforce this.)
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Print queue window closes itself when the job is done.
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# TextEdit: plain text, UTF-8.
defaults write com.apple.TextEdit RichText -int 0
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# Activity Monitor: show everything, sorted by CPU, main window on launch.
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Apply                                                                       #
###############################################################################

# Restarting these makes the changes visible without a logout. Failures are
# ignored: an app that isn't running has nothing to restart.
for app in Dock Finder SystemUIServer cfprefsd; do
  killall "$app" >/dev/null 2>&1 || true
done

echo "==> done. A few (key repeat, Finder view) need a logout or app restart."
