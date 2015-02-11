#!/bin/sh

# Change the permissions and extendet file attributes for the given files and
# directories or the current directory.  Always work recursivly.

prog=`basename "$0"`
usage () {
  echo "Usage: $prog [path ...]"
  echo "       $prog -h"
}
rm_acl () {
  # remove acl entries  TODO how to delete all of them?
  chmod -RN "$@"
}
chmod_R () {
  # set unix file permissions
  find "$@"                                \
    \( -type f -exec chmod 600 {} + \) -or \
    \( -type d -exec chmod 700 {} + \)
  # alternatively
  #chmod -R u+rwX,go-rwx "$@"
}
xattr_r () {
  # delete apples extendet file attributes
  local attributes=
  attributes="$attributes com.apple.quarantine"
  attributes="$attributes com.apple.FinderInfo"
  attributes="$attributes com.apple.metadata:_kTimeMachineNewestSnapshot"
  attributes="$attributes com.apple.metadata:_kTimeMachineOldestSnapshot"
  for attribute in $attributes; do
    xattr -rd $attribute "$@"
  done
  # alternatively
  #xattr -rc "$@"
}

if [ "$1" = -h ]; then
  usage
  exit
fi

# if no arguments are given work on the current directory
if [ $# -eq 0 ]; then set .; fi

if [ `uname` = Darwin ]; then rm_acl "$@"; fi
chmod_R "$@"
if [ `uname` = Darwin ]; then xattr_r "$@"; fi
