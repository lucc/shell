#!/bin/sh -x
# vim: foldmethod=marker

# variables
TIME_LOG=$HOME/log/boottime.log
BATT_LOG=$HOME/log/battery.log

# fix PATH
# on my OSX rtorrent is not in the default PATH
if [ -r $HOME/.config/shell/envrc ]; then
  . $HOME/.config/shell/envrc
else
  PATH=$HOME/bin:/usr/local/bin:$PATH
fi

# log the startup time and the battery status
date +"%F %H:%M:%S `uptime | cut -c8-`" >> $TIME_LOG
battery.sh >> $BATT_LOG

# set the volume to a sensible value
osascript -e 'set volume 1.5'

# search for info files on Mac
if [ -x /usr/local/bin/brew ]; then
  find /usr/local/Cellar -type d -name info > /usr/local/brew-infofiles
fi
