#!/bin/sh

if ! [ -t 0 -a -t 1 ]; then
  exec term -e "$0" "$@"
fi

dict "$@" 2>&1 | VIMPAGER_NO_PASSTHROUGH=1 $PAGER
