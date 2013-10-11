#!/bin/sh

# copy files to a remote destination via scp and notify the user about
# completion.
(
  log=`mktemp -t $$.XXXX`

  if scp "$@" 2>$log; then
    growlnotify --title 'Background scp successful!'
  else
    cat $log | growlnotify --title 'Background scp failed!'
  fi

  rm -f $log
) & >/dev/null 2>&1
