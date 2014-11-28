#!/bin/sh
# This script is specific to Mac OSX.

#CURRENT=`networksetup -getairportpower en1 | grep -o '[Onf]*$'`

echo Stopping airport ...
networksetup -setairportpower en1 off

if echo "$1" | grep '^[0-9]\+$' >/dev/null; then
  sleep $1
else
  sleep 1
fi

echo Starting airport ...
networksetup -setairportpower en1 on

# what is the difference? (from
# http://alvinalexander.com/source-code/mac-os-x/how-restart-mac-os-x-networking-command-line
# and
# http://blog.jeffcosta.com/2011/02/06/restart-the-network-on-osx-from-command-line/)
#sudo ifconfig en0 down
#sudo ifconfig en0 up
