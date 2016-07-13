#!/bin/sh

# Connect to the bluetooth headset.

version=1
prog="${0##*/}"

usage () {
  echo "Usage: $prog [-cdpsx]"
  echo "       $prog -h"
  echo "       $prog -v"
}

help () {
  echo "Connect to the bluetooth headset."
  echo
  echo "  -h    display help"
  echo "  -v    display version"
  echo "  -x    debugging output"
  echo
  echo "  -c    connect the headset"
  echo "  -d    disconnect the headset"
  echo "  -s    stop the bluetooth service"
  echo "  -p    power off bluetooth"
}

bluetooth_service_running () {
  systemctl status bluetooth | grep -q 'Status: "Running"'
}

connect_to_headset () {
  check_bluttooth
  bluetoothctl <<EOF
power on
agent on
default-agent
scan on
connect 00:07:04:CE:08:63
scan off
exit
EOF
}

bluetooth_poweroff () {
  if bluetooth_service_running; then
    bluetoothctl <<EOF
power off
exit
EOF
  fi
}

check_bluttooth () {
  if ! bluetooth_service_running; then
    echo Starting bluetooth ...
    sudo systemctl start bluetooth
  fi
}

while getopts cdhpsvx FLAG; do
  case $FLAG in
    c) connect_to_headset; exit;;
    d) echo disconnect: TODO; exit 2;;
    h) usage; echo; help; exit;;
    p) bluetooth_poweroff; exit;;
    s)
      bluetooth_poweroff
      check_bluttooth && sudo systemctl stop bluetooth
      exit;;
    v) echo "$prog -- version $version"; exit;;
    x) set -x;;
    *) usage >&2; exit 2;;
  esac
done
shift $((OPTIND - 1))

# If no option was given connect the headset.
connect_to_headset
