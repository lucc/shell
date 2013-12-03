#!/usr/bin/osascript

on run argv

  -- TODO: add some command line parsing

  set theLength to length of argv
  if theLength = 0
    return "Please give two arguments at minimum."
    quit 1
  end if

  set theSession to item 1 of argv
  set theCommand to item 2 of argv

  -- TODO: very ugly
  repeat with i from 3 to theLength
    set theCommand to theCommand & " " & item i of argv
  end repeat

  tell application "iTerm"
    tell current terminal
      launch session theSession
      tell the last session
	write text "exec " & theCommand
      end tell
    end tell
    activate
  end tell
end run
