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

resolve_symlinks () {
  file="$1"
  while [ -l "$file" ]; do
    file="`readlink "$file"`"
  done
  echo "$file"
}

ffmpeg_wrapper () {
  ffmpeg              \
    -n                \
    -nostdin          \
    -loglevel warning \
    "$@"
  # -loglevel quiet   \
  # -loglevel panic   \
  # -loglevel fatal   \
  # -loglevel error   \
  # -loglevel warning \
  # -loglevel info    \
  # -loglevel verbose \
  # -loglevel debug
}

to_ogg () {
  # TODO quality
  ffmpeg_wrapper       \
    -i "$1"            \
    -codec:a libvorbis \
    "${2%.ogg}.ogg"
}

to_mp3 () {
  # TODO quality
  ffmpeg_wrapper       \
    -i "$1"            \
    "${2%.mp3}.mp3"
}

convert_file () {
  to_ogg "$1" "$dest/${1%.*}.ogg"
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
  target="$dest/${file%.*}.ogg"
  printf "\nconverting $COLOR$file$NOCOLOR ..."
  if [ "$target" -nt "$file" ]; then
    echo " $target is newer.  Skipping."
  else
    echo
    mkdir -p "`dirname "$target"`"
    to_ogg "$file" "$target"
  fi
done
