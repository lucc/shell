#!/bin/sh

# Connect to the bluetooth headset.

version=2
prog="${0##*/}"
cmd=connect

usage () {
  echo "Usage: $prog [-cdpx]"
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
  echo "  -p    power off bluetooth"
}

is_on () {
  systemctl status bluetooth | grep -q 'Status: "Running"' \
    && [ "$(bluetooth)" = "bluetooth on" ]
}
on () {
  if ! is_on; then
    bluetooth on
    sudo systemctl start bluetooth
    bluetoothctl <<EOF
power on
agent on
default-agent
EOF
  fi
}
off () {
  systemctl is-active bluetooth >/dev/null && bluetoothctl power off
  sudo systemctl stop bluetooth
  bluetooth off >/dev/null
}
connect () {
  on
  bluetoothctl connect 00:07:04:CE:08:63
#power on
#agent on
#default-agent
#scan on
#connect 00:07:04:CE:08:63
#scan off
#exit
}
disconnect () {
  bluetoothctl disconnect
}


check_bluttooth () {
  if ! bluetooth_service_running; then
    echo Starting bluetooth ...
    sudo systemctl start bluetooth
  fi
}

while getopts cdhpvx FLAG; do
  case $FLAG in
    c) cmd=connect;;
    d) cmd=disconnect;;
    h) usage; echo; help; exit;;
    p) cmd=off;;
    v) echo "$prog -- version $version"; exit;;
    x) set -x;;
    *) usage >&2; exit 2;;
  esac
done
shift $((OPTIND - 1))

"$cmd"
