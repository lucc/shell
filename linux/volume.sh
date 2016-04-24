#!/bin/sh

# A simple script to collect some volume setting actions into a nice
# interface.

prog="$(basename "$0")"
device=Master
done=false

amixer_set () {
  amixer --quiet set $device "$@"
}

mute () {
  amixer_set mute
}

unmute () {
  amixer_set unmute
}

set_volume () {
  amixer_set ${1:-100}%
}

inc_volume () {
  amixer_set ${1:-1}%+
}

dec_volume () {
  amixer_set ${1:-1}%-
}

usage () {
  echo "$prog [[+-]num]"
  echo "$prog [-mu]"
  echo "$prog -h"
}

help () {
  echo
  echo "Set, increase, decrease, mute and unmute the speaker with amixer(1)."
  echo "Options:"
  echo "  -m	mute speaker"
  echo "  -u	unmute speaker"
  echo "  num   set the volume to num%"
  echo "  +num  increase the volume by num%"
  echo "  -num  decrease the volume by num% (not implemented)"
}

while getopts hmud:0123456789 FLAG; do
  case $FLAG in
    h) usage; help; exit;;
    m) mute; done=true;;
    u) unmute; done=true;;
    d) device="$OPTARG";;
    [0-9]*) true;; # skip numbers
    *) usage; exit 2;;
  esac
done

shift $(($OPTIND - 1))

func=
if [ $# -eq 1 -o $# -eq 2 ]; then
  case "$1" in
    +) func=inc_volume; shift;;
    -) func=dec_volume; shift;;
    +[0-9]*) func=inc_volume; set "${1#+}";;
    -[0-9]*) func=dec_volume; set "${1#-}";;
    [0-9]*) func=set_volume;;
    *) usage; exit 2;;
  esac
  case "$1" in
    [0-9]|[0-9][0-9]|100) true;;
    *) usage; exit 2;;
  esac
elif [ $# -eq 0 ]; then
  set_volume
  unmute
  exit
else
  usage
  exit 2
fi

$func $1
