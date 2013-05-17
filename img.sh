#!/bin/sh

# default values
DIR=.
NAME="Lucas Hoffmann"

# parese commandline
while getopts hd:n: FLAG; do
  case $FLAG in
    d)
      DIR="$OPTARG"
      ;;
    n)
      NEW="$OPTARG"
      ;;
    h)
      exec -c cat "$0"
      ;;
  esac
done

# change directory
if [ -d "$DIR" ]; then
  cd "$DIR"
  echo Working in "`pwd -P`"
else
  echo "$DIR" is not a directory. >&2
  exit 1
fi

# set name for new files if not set from commandline
if [ -z "$NEW" ]; then
  NEW=`pwd -P`
  NEW=`basename "$NEW"`
fi

# work on exif data
echo Deleting all exif data, only setting exif:artist and exif:copyright. >&2
exiftool -P -all= -exif:artist="$NAME" -exif:copyright="$NAME" *

# rename new files
echo Renameing new files to dvd/$NEW'*' ... >&2
mkdir dvd || exit 3
i=1
for file in `ls *.jpg *.JPG 2>/dev/null`; do
  mv "$file" "dvd/$NEW `printf %03d $i`.jpg"
  i=$((i+1))
done

# rename old files
echo Renameing original files. >&2
rename 's/_original$//' *_original
