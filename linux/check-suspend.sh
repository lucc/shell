#!/bin/sh

# suspend the system iff running on battery

version="1"
delay=0
self="`basename "$0"`"

connected() {
  # return 0 iff the external power supply is connected
  [ `cat /sys/class/power_supply/ADP1/online` -eq 1 ]
}

usage () {
  # Display usage information.
  echo Check if the system is running on battery power and if so, suspend the
  echo system.  Optionally wait for some seconds until checking and
  echo suspending.
  echo
  echo "  Usage: $self [-d delay]"
}

while getopts ":hvd:" opt; do
  case $opt in
  h|help     )  usage; exit 0   ;;
  v|version  )  echo "$0 -- Version $version"; exit 0   ;;
  d|delay    )  delay="$OPTARG";;
  \? )  echo -e "\n  Option does not exist : $OPTARG\n"
      usage; exit 1   ;;
  esac
done
shift $(($OPTIND-1))

sleep "$delay"
connected || systemctl hybrid-sleep
