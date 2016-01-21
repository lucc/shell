#!/bin/sh

connect_to_headset () {
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
  bluetoothctl <<EOF
power off
exit
EOF
}

check_bluttooth () {
  if ! systemctl status bluetooth | grep -q 'Status: "Running"'; then
    echo Starting bluetooth ...
    sudo systemctl start bluetooth
  fi
}

while getopts h FLAG; do
  case $FLAG in
    h) echo connect to bluetooth headset >&2; exit;;
    *) echo Error >&2; exit 2;;
  esac
done

connect_to_headset
