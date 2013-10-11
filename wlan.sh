#!/bin/sh
# This script is specific to Mac OSX.

#CURRENT=`networksetup -getairportpower en1 | grep -o '[Onf]*$'`

echo Stopping airport ...
networksetup -setairportpower en1 off
sleep 1
echo Starting airport ...
networksetup -setairportpower en1 on

# what is the difference? (from
# http://alvinalexander.com/source-code/mac-os-x/how-restart-mac-os-x-networking-command-line
# and
# http://blog.jeffcosta.com/2011/02/06/restart-the-network-on-osx-from-command-line/)
#sudo ifconfig en0 down
#sudo ifconfig en0 up
