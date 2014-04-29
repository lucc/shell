#!/usr/bin/osascript

on run argv

  -- set the default values
  set theSession to "Default"
  set theCommand to ""
  set theLength to length of argv

  -- parse the command line
  -- The first argument is the Profile name in iTerm.  The rest is a command
  -- line to execute.
  if theLength >= 1
    set theSession to item 1 of argv
    if theLength >=2
      repeat with i from 2 to theLength
	set theCommand to theCommand & " " & quoted form of item i of argv
      end repeat
    end if
  end if

  -- open iTerm and run the command
  tell application "iTerm" to tell current terminal
    launch session theSession
    if theCommand is not ""
      tell the last session to write text "exec " & theCommand
    end if
    activate
  end tell

end run
