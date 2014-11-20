#!/bin/sh

file=/sys/class/leds/smc::kbd_backlight/brightness
help () {
  echo Use -g to get the current calue and -s to set a new value.
  echo The argument to -s is a number and can be prefixed with + or - .
}

error () {
  help
  exit 2
}

get_kblight () {
  cat $file
}

set_kblight () {
  local new=0
  if echo "$1" | grep -Eqv '^[+-]?[0-9]+'; then
    error
  fi
  case $1 in
    +*|-*)
      eval 'new=$(('`get_kblight` $1 '))'
      ;;
    *)
      new=$1
  esac
  if [ $new -gt 255 ]; then
    new=255
  elif [ $new -lt 0 ]; then
    new=0
  fi
  if [ `id -u` -ne 0 ]; then
    if [ -t 0 -a -t 1 ]; then
      exec sudo "$0" -s $new
    else
      exec gksu "$0" -s $new
    fi
  else
    echo $new > $file
  fi
}

if [ $# -eq 0 ]; then
  error
fi

while getopts hgs: FLAG; do
  case $FLAG in
    h) help; exit 0;;
    g) get_kblight;;
    s) set_kblight "$OPTARG";;
    *) error;;
  esac
done
