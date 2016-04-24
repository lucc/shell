#!/bin/sh

# suspend the system iff running on battery

# Script to repeatedly check the battery status and hibernate the computer in
# case the level drops below a threshold.

version=2.1
delay=0
prog=${0##*/}
battery_threshhold=5
time_threshold=5

usage () {
  echo "Usage: $prog [-x] [-b percent] [-t minutes] [-d delay]"
  echo "       $prog -v"
  echo "       $prog -h"
}
help () {
  usage
  cat <<EOF

Monitor the power level and put the system to sleep if it dropes to low.  If
the battery is charging the script will exit.

Options:
  -b  set the battery level threshold in percent (default $battery_threshhold)
  -t  set the time remaining threshold in percent (default $time_threshold)
  -d  set the delay when to start monitoring the battery (default $delay)
  -x  enable debugging output
  -v  show verion information
  -h  show this help message

EOF
}
connected () {
  # return 0 iff the external power supply is connected
  [ "$(cat /sys/class/power_supply/ADP1/online)" -eq 1 ]
}
parse_data () {
  acpi --battery | sed -e 's/.*: /state=/'         \
                       -e 's/, /;percent=/'        \
		       -e 's/%, 0\?/;time=$((60*/' \
		       -e 's/:0\?/+/'              \
		       -e 's/:.*/))/'
}

while getopts b:d:ht:vx FLAG; do
  case $FLAG in
    b) battery_threshhold="$OPTARG";;
    d) delay="$OPTARG";;
    h) help; exit;;
    t) time_threshold="$OPTARG";;
    v) echo "$prog -- Version $version"; exit 0;;
    x) set -x;;
    *) usage >&2; exit 2;;
  esac
done

sleep "$delay"

while ! connected; do
  eval $(parse_data)
  #echo state: $state
  #echo percent: $percent
  #echo time: $time
  if [ "$state" = Charging ]; then
    exit
  elif [ "$percent" -lt "$battery_threshhold" -o "$time" -lt "$time_threshold" ]; then
    systemctl hybrid-sleep
  else
    sleep 1
  fi
done
