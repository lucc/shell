#!/bin/sh

prog=`basename "$0"`
title=Notification
text=''

help () {
  echo "Send a notification with the naughty library of awesome(1)."
  echo "Usage: $prog [-t title] message ..."
  echo "       echo message | $prog [-t title]"
}

while getopts ht: FLAG; do
  case $FLAG in
    h)
      help
      exit
      ;;
    t)
      title="$OPTARG"
      ;;
    *)
      help >&2
      exit 2
      ;;
  esac
done

shift $((OPTIND-1))

if [ $# -ne 0 ]; then
  text="$*"
else
  text="`cat`"
fi

(
  echo "naughty = require('naughty')"
  echo "arg = {"
  echo "  title = '${title//\'/\\\'}',"
  echo "  text = '${text//\'/\\\'/}',"
  echo "  timeout = 0"
  echo "}"
  echo "naughty.notify(arg)"
) | awesome-client
