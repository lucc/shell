#!/bin/sh

# Mount a encrypted image at ~/.config/secure.

MOUNTPOINT=${MOUNTPOINT:-~/.config/secure}
TRUECRYPT_CONTAINER=${CONTAINER:-~/etc/tcc}
DMG_CONTAINER=${CONTAINER:-~/luc.dmg}

ACTION=
METHOD=osx.dmg

INTERFACE=TUI
TRUECRYPT_TUI=--text
TRUECRYPT_GUI=
TUI=
GUI=

help () {
  # display help on commandline
  local PROG="`basename "$0"`"
  echo "Usage: $PROG [-g] [ -m | -u ]"
  echo "       $PROG -h"
  echo "The program will automatically mount or unmount the container."
  echo "You can use the options to force (un)mounting or see this help."
  echo "The environment variables CONTAINER and MOUNTPOINT are supported."
}

truecrypt_wrapper () {
  # wrapper for truecrypt to pass standard options
  local truecrypt=truecrypt
  if [ `uname` = Darwin ]; then
    truecrypt=/Applications/TrueCrypt.app/Contents/MacOS/TrueCrypt
  fi
  $truecrypt $INTERFACE --verbose --keyfiles= "$@"
}

truecrypt_create () {
  # create a new container, double the size of the old one
  # the filename of the container has to be passed as $1
  local CONTAINER="$1"
  local dir=`mktemp -d -t $$.XXXXXX`
  local size=`wc -c < $CONTAINER`
  mkdir -p $dir
  echo Creating new container ...
  truecrypt_wrapper             \
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

truecrypt_mount () {
  # mount a truecrypt container
  truecrypt_wrapper --protect-hidden=no "$@"
}

truecrypt_unmount () {
  # unmount a truecrypt container from the given mountpoint
  truecrypt_wrapper --dismount "$@"
}

truecrypt_find_mountpoint () {
  echo Not implemented >&2
  exit 100
}

dmg_create () {
  echo Not implemented >&2
  exit 101
}

dmg_mount () {
  hdiutil attach -mountpoint $MOUNTPOINT $CONTAINER
}

dmg_unmount () {
  diskutil unmount force $MOUNTPOINT
}

dmg_find_mountpoint () {
  # Print the path where the given dmg file might be mounted.
  local dmg="${1//\\/\\\\}"
  dmg="${dmg//\//\\/}"
  hdiutil info | sed -n                      \
    -e ':find_image'                         \
    -e '/<key>image-path<\/key>/{'           \
    -e '  N'                                 \
    -e '  /<string>'"$dmg"'<\/string>/{'     \
    -e '    b find_mountpoint'               \
    -e '  }'                                 \
    -e '}'                                   \
    -e 'd'                                   \
    -e ':find_mountpoint'                    \
    -e 'n'                                   \
    -e '/<key>mount-point<\/key>/{'          \
    -e '  N'                                 \
    -e '  s/.*<string>\(.*\)<\/string>/\1/p' \
    -e '  q'                                 \
    -e '}'                                   \
    -e 'b find_mountpoint'
}

case $METHOD in
  truecrypt)
    create () { truecrypt_create "$@"; }
    mount_wrapper () { truecrypt_mount "$@"; }
    unmount_wrapper () { truecrypt_unmount "$@"; }
    CONTAINER="$TRUECRYPT_CONTAINER"
    TUI=$TRUECRYPT_TUI
    GUI=$TRUECRYPT_GUI
    ;;
  osx.dmg)
    create () { dmg_create "$@"; }
    mount_wrapper () { dmg_mount "$@"; }
    unmount_wrapper () { dmg_unmount "$@"; }
    CONTAINER="$DMG_CONTAINER"
    ;;
  *)
    echo Error
    exit 102
    ;;
esac

if mount | grep -q $MOUNTPOINT; then
  ACTION=unmount
else
  ACTION=mount
fi

while getopts ghmu FLAG; do
  case $FLAG in
    c) ACTION=create;;
    g) INTERFACE=GUI;;
    h) ACTION=help;;
    m) ACTION=mount;;
    u) ACTION=unmount;;
    \?) exit 2;;
  esac
done

shift $(($OPTIND - 1))
if [ $# -ne 0 ]; then
  echo "$0: illegal argument -- $1" >&2
  exit 2
fi

eval INTERFACE=\$$INTERFACE

case $ACTION in
  create)
    create_new_container
    ;;
  mount)
    echo Mounting ...
    mount_wrapper $CONTAINER $MOUNTPOINT
    ;;
  unmount)
    echo Unmounting ...
    unmount_wrapper $MOUNTPOINT
    ;;
  help)
    help
    ;;
esac
