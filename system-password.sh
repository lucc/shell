#!/bin/sh

# A script enable and disable the password querry after sleep and hibernate
# for Mac OS X.

set_ask_password () {
  # required argument one is true/1/on/yes or flase/0/off/no
  case "`echo "$1" | tr A-Z a-z`" in
    true|yes|on|1) local use_int=1 use_string=true;;
    false|no|off|0) local use_int=0 use_string=false;;
    *) return 2;;
  esac
  # Require password immediately after sleep or screen saver begins
  # 1 = true, 0 = false
  defaults write com.apple.screensaver askForPassword -int $use_int
  # FIXME the above settings do not seem to be picked up.  This applescript
  # will force them to be used:
  osascript -e 'tell application "System Events" to ¬' \
    -e "set require password to wake of security preferences to $use_string"
  #osascript -e 'tell application "System Events" to ¬' \
  #  -e 'get require password to unlock of security preferences'
}

set_delay () {
  # Set the delay after which a password will be required. In seconds.
  defaults write com.apple.screensaver askForPasswordDelay -int "$1"
}

get_ask_password () {
  defaults read com.apple.screensaver askForPassword
}

get_delay () {
  defaults read com.apple.screensaver askForPasswordDelay
}
