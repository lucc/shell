#!/bin/sh

mac-defaults-passon () {
  # does not seem to work
  defaults write com.apple.screensaver askForPassword -int 0
  defaults write com.apple.screensaver askForPassword -int 1
  defaults write com.apple.screensaver askForPasswordDelay -int 0
}

mac-defaults-passoff () {
  # does not seem to work
  defaults write com.apple.screensaver askForPassword -int 0
}

mac-applescript-passon () {
}

mac-applescript-passoff () {
# osascript -e 'tell application "System Events"
# tell application process "System Preferences"
# click checkbox "Require password" of tab group 1 of window "Security"
# end tell
# end tell'
}

mac-applescript-passtoggle () {
  osascript -e <<EOF
  tell app "System Preferences" to activate
  tell app "System Events"
    tell app process "System Preferences"
      click checkbox "Require password" of tab group 1 of window "Security"
    end tell
  end tell
EOF
}

