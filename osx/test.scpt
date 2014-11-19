#!/usr/bin/osascript

tell application "iTerm"
  activate
  tell the first terminal to set mysess to (make new session at the end of sessions)
  tell mysess
    set name to "mutt"
    exec command "/usr/local/bin/mutt -H /Users/luc/bin/test.scpt"
  end tell
end tell

