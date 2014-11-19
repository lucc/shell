#!/usr/bin/env osascript

-- script to move the iterm window to the internal display.

on run argv

  if length of argv = 0
    set theApp to "iTerm"
  else
    set theApp to item 1 of argv
  end if

  -- find the number of displays
  tell application "Automator Runner" to ¬
    set screens to count of (call method "screens" of class "NSScreen")

  if screens = 2
    tell application theApp
      activate
      -- This is valid for my display if it is above the internal displays
      -- get the window douns with
      --get bounds of window 1
      set bounds of window 1 to {0, 1024, 1280, 1824}
    end tell
  else
    set result to "Only one display."
  end if
end run
