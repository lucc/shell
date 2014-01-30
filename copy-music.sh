#!/bin/sh

# a script to convert all music files in the source directory to a uniform
# format, saving them in destination directory
#
# TODO: nice and cpulimit

PROG="`basename "$0"`"
if [ -t 1 -a -t 2 ]; then
  COLOR="\033[1m"
  NOCOLOR="\033[m"
else
  COLOR=
  NOCOLOR=
fi

usage () {
  echo "$PROG src target"
  echo "Convert all music files in src to ogg files into target."
}

die () {
  ret=$1
  shift
  echo "$PROG: $@" >&2
  exit $ret
}

deref () {
  file="$1"
  while [ -l "$file" ]; do
    file="`readlink "$file"`"
  done
  echo "$file"
}

convert_file () {
  ffmpeg              \
    -n                \
    -nostdin          \
    -loglevel warning \
    -i "$1"           \
    -acodec libvorbis \
    "$dest/${1%.*}.ogg"
  # -loglevel quiet   \
  # -loglevel panic   \
  # -loglevel fatal   \
  # -loglevel error   \
  # -loglevel warning \
  # -loglevel info    \
  # -loglevel verbose \
  # -loglevel debug   \
}

if [ $# -ne 2 ]; then
  usage
  exit 2
fi

src="$1"
dest="$2"

mkdir -p "$dest"
cd "$dest" || die 3 Can not cd to "$dest".
dest="`pwd -P`"
cd - >/dev/null 2>&1

# change to the source directory to be able to work with relative filenames
cd "$src" || die 3 Can not cd to "$src".

# first duplicate the directory structure of $src to $dest
#find . -type d -exec mkdir -p "$dest"/{} \;

find . -type f | while read file; do
  echo
  echo "converting $COLOR$file$NOCOLOR ..."
  mkdir -p "$dest"/"`dirname "$file"`"
  convert_file "$file"
done
