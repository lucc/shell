#!/usr/bin/osascript

-- Applescript to mute and unmute or set the system volume.  To use this
-- script as a logout hook:
-- sudo defaults read com.apple.loginwindow
-- sudo defaults write com.apple.loginwindow LogoutHook /path/volume.scpt off

-- mute the system volume
on mute_volume()
  set volume output muted true
end mute_volume

-- unmute the system volume
on unmute_volume()
  set volume output muted false
end unmute_volume

-- set the system volume to vol, don't change the muted status
on set_volume(vol)
  if output muted of (get volume settings)
    set volume with output muted output volume vol
  else
    set volume vol
  end if
end set_volume

-- run from the command line
on run argv
  set usageString to ¬
    "You have to give 'get', 'on', 'off' or an integer as argument."
  if length of argv = 1
    set arg1 to item 1 of argv
    if arg1 is in {"help", "--help", "-h"}
      return usageString
    else if arg1 is in {"get", "see"}
      set xxx to get volume settings
      return ¬
        "Volume:   " & output volume of xxx & "\n" & ¬
        "Muted:    " & output muted  of xxx
    else if arg1 is in {"off", "mute"}
      mute_volume()
    else if arg1 is in {"on", "unmute"}
      unmute_volume()
    else
      set_volume(arg1)
    end if
  else
    error usageString
  end if
end run
