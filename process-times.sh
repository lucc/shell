#!/bin/sh

# script to report some time information about a process

while getopts hx FLAG; do
  case $FLAG in
    h) help; exit;;
    x) set -x;;
    *) usage; exit 2;;
  esac
done
shift $((OPTIND - 1))

if echo "$1" | grep -q '^[0-9]*$'; then
  process=$1
else
  process=$(pgrep "$1")
fi

ps -o pid,m_size,lstart,cputime,%cpu,%mem,command $process
