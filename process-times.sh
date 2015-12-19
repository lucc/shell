#!/bin/sh

# script to report some time information about a process

quiet=false

while getopts hvq FLAG; do
  case $FLAG in
    h) print_help; exit;;
    v) quiet=false;;
    q) quiet=true;;
  esac
done

if echo "$1" | grep -q '^[0-9]*$'; then
  process=$1
else
  process="`pgrep "$1"`"
fi

ps -o pid,m_size,start=start,start_time=start_time,lstart=lstart,cputime,%cpu,%mem,command $process
