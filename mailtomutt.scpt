#!/usr/bin/osascript

on run argv
  set filename to item 1 of argv
  tell application "iTerm"
    activate
    tell the first terminal to set mysession to ¬
      (make new session at the end of sessions)
    tell mysession
      set name to "mutt"
      exec command "/usr/local/bin/mutt -H '%@' "
    end tell
  end tell
end run
