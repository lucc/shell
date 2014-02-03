#!/bin/sh

# A script to terminate mpd if it is not used for a specific time.

logfile=~/.mpd/playtime.log

# if  no mpd is running clear the logfile and exit
if ! mpc --no-status 2>/dev/null; then
  cat /dev/null > "$logfile"
  exit
fi

new=`mpc stats | \
  sed -nE 's/^Play Time:[[:space:]]*([[:digit:]]*) days, /\1:/p'`
old=`cat "$logfile"`

# if the logfile was empty fill it and exit
if [ -z "$old" ]; then
  echo $new > "$logfile"
  exit
fi

old_d=${old%%:*}
old_h=${old%:??:??}
old_h=${old_h##*:}
old_m=${old%:??}
old_m=${old_m##*:}
old_s=${old##*:}
new_d=${new%%:*}
new_h=${new%:??:??}
new_h=${new_h##*:}
new_m=${new%:??}
new_m=${new_m##*:}
new_s=${new##*:}

# check if mpd played some music since the last check
if [ $old_d -lt $new_d -o \
     $old_h -lt $new_h -o \
     $old_m -lt $new_m -o \
     $old_s -lt $new_s ]; then
  echo $new > "$logfile"
else
  mpd --kill
  cat /dev/null > "$logfile"
fi
