#!/bin/sh

if [ $# -gt 0 ]; then
  URL="$1"
else
  URL=http://luc42.lima-city.de
fi

for BROWSER in \
    w3m        \
    links      \
  ; do
    #elinks     \
  BROWSER="`which $BROWSER`"
  if [ -x "$BROWSER" ]; then
    exec iterm-session.scpt Big "$BROWSER" "'$URL'"
  fi
done

echo No suitable browser available. >&2
exit 1
