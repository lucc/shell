#!/bin/sh

# Check pacman leaf packages if they can be removed.

version=0.1
prog="$(basename "$0")"

usage () {
  echo "Usage: $prog"
  echo "       $prog -h"
  echo "       $prog -v"
}

help () {
  echo "TODO: help text"
}

random=0
all=1

while getopts hvrx1a FLAG; do
  case $FLAG in
    h) usage; help; exit;;
    v) echo "$prog -- version $version"; exit;;
    x) set -x;;
    a) all=1 random=0;;
    r) random=1;;
    1) all=0;;
    *) usage >&2; exit 2;;
  esac
done

cache=~/.cache/check-pack
packages="$(pacman --query --explicit --unrequired --quiet)"
uninstall=

if ((random)); then
  packages="$(echo "$packages" | sort --random)"
fi
if ! ((all)); then
  packages=$(echo "$packages" | head -n 1)
fi

for package in $packages; do
  reply=
  pacman --query --search "^$package$"
  while true; do
    echo 'Do you want to uninstall this package? [yes|No|view|quit|skip to uninstall]'
    read reply
    if [ -z "$reply" ]; then
      reply=no
    fi
    case "$reply" in
      y*|Y*) uninstall="$uninstall $package"; break;;
      n*|N*)
	count=$(($(cat "$cache/$package" 2>/dev/null) + 1))
	echo $count "$cache/$package"
	break
	;;
      v*|V*) pacman --query --info "$package";;
      s*|S*) break 2;;
      q*|Q*) exit;;
      *)     pacman --query --info "$package";;
    esac
  done
done

if [ -n "$uninstall" ]; then
  sudo pacman --remove --nosave --recursive $uninstall
fi
