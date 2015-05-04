#!/bin/sh

dialog () {
  osascript <<EOF
  tell application "Finder"
    activate
    set v to the text returned of ¬
    (display dialog "new name" default answer "$1")
    set visible of process "Finder" to false
    return v
  end tell
EOF
}

new=`dialog "$1"`

if [ $? -eq 0 ]; then
  mv -nv "$1" "$new"
fi
