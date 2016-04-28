#!/bin/sh

# A shell wrapper to call different programms.  To be used in the mailcap
# file.

version=0.1
prog="$(basename "$0")"

usage () {
  echo "Usage: $prog"
  echo "       $prog -h"
  echo "       $prog -v"
}

help () {
  echo "Mailcap wrapper script."
}

while getopts hv FLAG; do
  case $FLAG in
    h) usage; help; exit;;
    v) echo "$prog -- version $version"; exit;;
    *) usage >&2; exit 2;;
  esac
done
shift $((OPTIND - 1))

if [ $# -ne 2 ]; then
  usage >&2
  exit 2
fi
case "$1" in
  text/html)
    # Thanks to @don_christi: http://unix.stackexchange.com/a/279635/88313
    elinks -no-home -dump "$2" | \
      sed '    # Remove all common leading ws ignoring blank lines.
        H      # append to hold space
	$!d    # delete all but the last line
	g      # write the hold space over the pattern space
	: m    # label m
	/\n[^\n[:blank:]]/!s/\n[^\n]/\n/g # remove common space
	t m    # goto m
	s/.//  # delete leading newline
	'
    ;;
  *)
    echo "Unsuported mime type: $1" >&2
    exit 1
    ;;
esac
