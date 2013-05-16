#!/bin/sh
# This script is specific to Mac OSX.

#CURRENT=`networksetup -getairportpower en1 | grep -o '[Onf]*$'`

echo Stopping airport ...
networksetup -setairportpower en1 off
sleep 1
echo Starting airport ...
networksetup -setairportpower en1 on
