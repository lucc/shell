#!/bin/sh


#if [ -t 0 ] && [ -t 1 ]; then
#  true
#else
#  sudo () {
#    osascript -e "do shell script \"$*\" with administrator privileges"
#  }
#fi

ssid () {
  # find the current ssid

  # airport should be linked to
  # /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport
  airport -I | awk '/ SSID: / {print substr($0, index($0, $2))}'
  return

  # alternatives
  ioreg -n AirPortPCI -S -w 0 # doesn't work?
  networksetup -getairportnetwork en1 | cut -f 2- -d :
  system_profiler SPAirPortDataType | \
    grep -A 1 'Current Network Information:' | tail -1 | tr -d ' :'
}

list () {
  launchctl list "$1" || sudo launchctl list "$1"
}

load () {
  launchctl load -w "$1" || sudo launchctl load -w "$1"
}

unload () {
  launchctl unload -w "$1" || sudo launchctl unload -w "$1"
}

internetsharing () {
  # start or stop the InternetSharing launchd service

  local job=com.apple.InternetSharing
  local file=/System/Library/LaunchDaemons/${job}.plist
  if [ "$1" = start ] && !      launchctl list $job >/dev/null 2>&1 && \
			 ! sudo launchctl list $job >/dev/null 2>&1; then
      logger -is Loading InternetSharing ...
      launchctl load -w $file
  elif [ "$1" = stop ]; then
    if launchctl list $job >/dev/null 2>&1; then
      logger -is Unloading InternetSharing ...
      launchctl unload -w $file
    elif sudo launchctl list $job >/dev/null 2>&1; then
      sudo launchctl unload -w $file
    fi
  fi
}

case `ssid` in
  eduroam)
    internetsharing stop
    volume.scpt off
    ;;

  o2-WLAN51)
    internetsharing start
    volume.scpt on
    ;;
  'FRITZ!Box Fon WLAN 7141') # bei Simone
    internetsharing stop
    volume.scpt on
    ;;
  *)
    echo Nothing to do for this network.
    ;;
esac
