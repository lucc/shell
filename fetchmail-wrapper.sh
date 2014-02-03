#!/bin/sh

export PATH=/usr/local/bin:/usr/bin:/bin
fetchmail
ret=$?
if [ $ret -eq 1 ]; then
  exit 0
else
  exit $ret
fi
