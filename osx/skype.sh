#!/bin/sh

# open the skype window after all other actions are taken
OPEN=true

help_function () {
  # display help about usage
  echo "Usage:  `basename "$0"` [ away | on[line] | off[line] | q[uit] ]" >&2
  echo "Set user status an display the skype window." >&2
}

skype_status() {
  # change the status of the skype user currently logged in.
  # possible status are ONLINE, INVISIBLE, AWAY, DND (do not disturb), and
  # OFFLINE.
  osascript -e 'tell application "Skype"
      send command "SET USERSTATUS '$1'" script name "skype.sh"
    end tell'
}

if [ $# -ge 1 ]; then
  # parse the commandline and optionally set the user status
  case "$1" in
    -h|--help|help)
      help_function
      exit 0
      ;;
    away)
      skype_status AWAY
      ;;
    on|online)
      skype_status ONLINE
      ;;
    off|offline)
      skype_status INVISIBLE
      OPEN=false
      ;;
    q|quit)
      osascript -e 'tell application "Skype" to quit'
      OPEN=false
      ;;
    *)
      help_function
      exit 2
      ;;
  esac
  # warn about ignored arguments
  if [ $# -gt 1 ]; then
    echo "Only the first argument is used." >&2
  fi
fi

# open the skype window
if $OPEN; then
  open -a Skype
fi
