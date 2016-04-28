#!/bin/sh

# Delete common initial whitespace from all lines.

version=0.1
prog=${0##*/}

usage () {
  echo "Usage: $prog [-x] [file ...]"
  echo "       $prog -h"
  echo "       $prog -v"
}

help () {
  echo "Delete the common amount of leading whitespace from all line."
}

while getopts hv FLAG; do
  case $FLAG in
    h) usage; help; exit;;
    v) echo "$prog -- version $version"; exit;;
    x) set -x;;
    *) usage >&2; exit 2;;
  esac
done
shift $((OPTIND - 1))

if [ $# -eq 0 ]; then
  tempfile=$(mktemp)
  trap
  cat > "$tempfile"
  set -- "$tempfile"
fi

for file in "$@"; do
  amount=$(expand -i -t 8 "$file" | \
    awk '
      BEGIN { amount = 0 }
      /^[^[:space:]]/ { print 0; exit }
      /^$/ { next }
      /^[[:space:]]/ { amount = match($0, "[^[:space:]]") - 1 }
      END { print amount }
    ')
  expand -i -t 8 "$file" | sed "s/^[[:space:]]\\{$amount\\}//"
done

if [ -n "$tempfile" ]; then
  rm "$tempfile"
fi
