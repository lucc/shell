#!/bin/sh

# A shell wrapper to call different programms.  To be used in the mailcap
# file.

version=0.2
prog=${0##*/}
mimetype=
charset=

usage () {
  echo "Usage: $prog [-m mime/type] [-c charset] file"
  echo "       $prog -h"
  echo "       $prog -v"
}

help () {
  echo "Mailcap wrapper script."
}

while getopts c:hm:v FLAG; do
  case $FLAG in
    c) charset=$OPTARG;;
    h) usage; help; exit;;
    m) mimetype=$OPTARG;;
    v) echo "$prog -- version $version"; exit;;
    *) usage >&2; exit 2;;
  esac
done
shift $((OPTIND - 1))

if [ $# -ne 1 ]; then
  usage >&2
  exit 2
fi
case $mimetype in
  text/html)
    # Thanks to don_christi: http://unix.stackexchange.com/a/279635/88313
    # and pazz: https://github.com/pazz/alot/pull/1015
    eval=
    code=
    if [ -n "$charset" ]; then
      eval=-eval
      code="set document.codepage.assume = \"$charset\""
    fi
    #-dump-color-mode 3 \
    elinks \
      -no-home \
      -force-html \
      -dump \
      -dump-charset utf8 \
      "$eval" "$code" \
      "$1" | \
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
    echo "Unsuported mime type: $mimetype" >&2
    exit 1
    ;;
esac
