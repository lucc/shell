#!/bin/sh
# This script is specific to Mac OS X.

if [ "$1" = -f ]; then
  # to relaunch the authentification process or something like this
  # https://discussions.apple.com/thread/2700971
  echo Relauncing authentification service ...
  sudo launchctl stop com.apple.racoon
  sudo launchctl start com.apple.racoon
elif [ $# -ne 0 ]; then
  echo Unrecognized option. Use \"-f\" or no option.
fi

networksetup -connectpppoeservice "lmu-vpn"

# trying to put the password does not work!
#osascript -e <<EOF
#  tell app "System Events"
#    tell app process "UserNotificationCenter"
#      put "hans" in textfield of window "alert"
#    end tell
#  end tell
#EOF

# 71:108: syntax error: Can’t get "hans" in textfield of window "alert".
# Access not allowed. (-1723)
