#!/bin/sh

if [ "$1" = -p ]; then
  shift
  mvv () {
    mv -nv "$1" "`dirname "$1"`"/"`basename "$1"|cut -c1-2`"-$RANDOM
  }
else
  mvv () {
    mv -nv "$1" `dirname "$1"`/$RANDOM
  }
fi

for file; do mvv "$file"; done
