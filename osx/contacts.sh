#!/bin/sh

if test $# -eq 1; then
  email="$1"
  name="${1%%@*}"
elif [ $# -eq 3 ]; then
  first="$1"
  last="$2"
  email="$3"
else
  echo Error >&2
  exit 2
fi

osascript <<EOF
tell application "Contacts"
  set thePerson to make new person with properties {first name:"$first", last name:"$last"}
  tell thePerson
    make new email at end of emails of thePerson with properties {label:"Home", value:"$email"}
  end tell
  save
end tell
EOF


