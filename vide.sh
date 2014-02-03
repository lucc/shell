#!/bin/sh
FILE=Session.vim
if ls .*.swp >/dev/null 2>&1; then 
  open -a MacVim
elif [ -z "$1" -a -r $FILE ]; then
  vi -g -S ${FILE}
else
  vi -g "$@"
fi
