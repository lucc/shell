#!/bin/sh

# i counld try to write a perl program to do this

options=-n
pattern=
# name of the rename executable (sometimes it is perl-rename)
rename=

usage () {
  local prog="`basename "$0"`"
  echo "$prog [-n|-f|-q|-v] pattern [file ...]"
  echo "$prog [-n|-f|-q|-v] -p pattern [file ...]"
  echo "$prog -h"
  echo "The pattern must contain one #, where the numbers are."
  echo "Unless -f is given no renaming is done"
  echo TODO: explain more ...
}
die () {
  local ret="$1"
  shift
  echo "$@" >&2
  exit "$ret"
}
find_rename () {
  for rename in perl-rename rename; do
    if $rename --version >/dev/null && \
	$rename --version | grep -qv 'from util-linux'; then
      return
    fi
  done
  rename=
  return 1
}

if ! find_rename; then
  die 1 Can not find the correct rename executable.
fi

# parse the command line
while getopts fhnp:qvx FLAG; do
  case $FLAG in
    f) options=;;
    h) usage; exit;;
    n) options=-n;;
    p) pattern="$OPTARG";;
    q) quiet=true;;
    v) quiet=false;;
    x) set -x;;
    *) usage; exit 2;;
  esac
done
# remove options from command line
shift $(($OPTIND-1))
# check that a pattern can be used
if [ -z "$pattern" ]; then
  pattern="$1"
  shift
fi
if [ -z "$pattern" ]; then
  die 2 No pattern given.
fi
if echo "$pattern" | grep -qv \#; then
  die 2 Pattern does not contain a \# character.
fi
# ...
pre_plain="${pattern%%#*}"
pre_escaped="${pre_plain//./\\.}"
post_plain="${pattern##*#}"
post_escaped="${post_plain//./\\.}"

i=`ls *$pre_plain*$post_plain* 2>/dev/null | \
  sed -n "s/.*${pre_escaped}\([0-9]\{1,\}\)${post_escaped}.*/\\1/p" | \
  awk 'length > x { x = length } END { print int(x) }'`

while [ "$i" -gt 1 ]; do
  num="$num\d"
  i=$((i-1))
  $rename $options "s/${pre_escaped}(${num})${post_escaped}/${pre_plain}0\$1${post_plain}/" *
done

echo "$rename 's/${pre_escaped}(${num})${post_escaped}/${pre_plain}0\$1${post_plain}/' *"
