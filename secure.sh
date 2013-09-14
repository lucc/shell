#!/bin/sh

CONTAINER=~/etc/tcc
MOUNTPOINT=~/.config/secure
METHOD=--text
ACTION=

help () {
  local PROG="`basename "$0"`"
  echo "Usage: $PROG [-g] [ -m | -u ]"
  echo "       $PROG -h"
  echo "The program will automatically mount or unmount the container."
  echo "You can use the options to force (un)mounting or see this help."
}

if [ `uname` = Darwin ]; then
  alias truecrypt=/Applications/TrueCrypt.app/Contents/MacOS/TrueCrypt
fi

if mount | grep -q $MOUNTPOINT; then
  ACTION=unmount
else
  ACTION=mount
fi

while getopts ghmu FLAG; do
  case $FLAG in
    g) METHOD=;;
    h) ACTION=help;;
    m) ACTION=mount;;
    u) ACTION=unmount;;
    \?) exit 2;;
  esac
done

shift $(($OPTIND - 1))
if [ $# -ne 0 ]; then
  echo "$0: illegal argument -- $1" 1>&2
  exit 2
fi

case $ACTION in
  mount)
    echo Mounting ...
    truecrypt $METHOD --protect-hidden=no --keyfiles= $CONTAINER $MOUNTPOINT
    ;;
  unmount)
    echo Unmounting ...
    truecrypt $METHOD --dismount $MOUNTPOINT
    ;;
  help)
    help
    ;;
esac
