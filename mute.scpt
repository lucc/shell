#!/usr/bin/osascript

-- applescript to mute and unmute the volume
on run argv
  if length of argv = 1
    set arg1 to item 1 of argv
    if arg1 = "on" or arg1 = "true" or arg1 = "mute"
      set volume output muted true
    else if arg1 = "off" or arg1 = "false" or arg1 = "unmute"
      set volume output muted false
    else
      set result to "Wrong argument.  Say 'on' or 'off'."
    end if
  else if length of argv = 0
    if output muted of (get volume settings)
      set volume output muted false
    else
      set volume output muted true
    end if
  else
    set result to "Wrong argument. Say 'on' or 'off'."
  end if
end run
