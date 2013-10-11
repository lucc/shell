#!/bin/sh

CONTAINER=~/etc/tcc
MOUNTPOINT=~/.config/secure
METHOD=--text
ACTION=

help () {
  # display help on commandline
  local PROG="`basename "$0"`"
  echo "Usage: $PROG [-g] [ -m | -u ]"
  echo "       $PROG -h"
  echo "The program will automatically mount or unmount the container."
  echo "You can use the options to force (un)mounting or see this help."
}

tc () {
  # wrapper for truecrypt to pass standard options
  local truecrypt=truecrypt
  if [ `uname` = Darwin ]; then
    truecrypt=/Applications/TrueCrypt.app/Contents/MacOS/TrueCrypt
  fi
  $truecrypt $METHOD --verbose --keyfiles= "$@"
}

create_new_container () {
  # create a new container, double the size of the old one
  local dir=`mktemp -d -t $$.XXXXXX`
  local size=`wc -c < $CONTAINER`
  mkdir -p $dir
  echo Creating new container ...
  tc                            \
    --create                    \
    --encryption=AES            \
    --hash=RIPEMD-160           \
    --random-source=/dev/random \
    --size=$((2 * size))        \
    --volume-type=normal        \
    ${CONTAINER}.new
  echo Mounting new container to copy files ...
  mount ${CONTAINER}.new $dir
  cp -rv "$MOUNTPOINT/"* $dir
  echo Unmounting and moving containers ...
  dismount $dir
  dismount $MOUNTPOINT
  mv -v $CONTAINER ${CONTAINER}.old
  mv -v ${CONTAINER}.new $CONTAINER
  echo Mounting new container ...
  mount $CONTAINER $MOUNTPOINT
}

mount_tc () {
  # mount a truecrypt container
  tc --protect-hidden=no "$@"
}

dismount () {
  # unmount a truecrypt container from the given mountpoint
  tc --dismount "$@"
}

if mount | grep -q $MOUNTPOINT; then
  ACTION=unmount
else
  ACTION=mount
fi

while getopts ghmu FLAG; do
  case $FLAG in
    c) ACTION=create;;
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
  create)
    create_new_container
    ;;
  mount)
    echo Mounting ...
    mount_tc $CONTAINER $MOUNTPOINT
    ;;
  unmount)
    echo Unmounting ...
    dismount $MOUNTPOINT
    ;;
  help)
    help
    ;;
esac
