#!/bin/sh

dir=/sys/class/backlight/nvidia_backlight

get_brightness () { cat $dir/actual_brightness; }
set_brightness () { echo $1 | sudo tee $dir/brightness; }
max_brightness () { cat $dir/max_brightness; }
test_argument  () { [ "$1" -ge 0 -a "$1" -le `max_brightness` ]; }
help () { echo "`basename "$0"` {get|set NUMBER}"; }

case "$1" in
  -g|--get|get) get_brightness;;
  -s|--set|set) test_argument "$2" && set_brightness "$2";;
  -h|--help|help) help;;
  *) help; exit 2;;
esac
