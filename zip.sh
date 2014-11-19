#!/bin/sh

# Shell script to quickly extract archives.  There is a package "unp" to do
# exactly this.

if [ "$1" = -h -o "$1" = --help ]; then
  echo Give some archives as arguments,                >&2
  echo they will be unpacked to the current directory. >&2
  exit 2
fi
if which atool; then
  unpack () {
    atool --extract "$1"
  }
else
  unpack () {
    # idea from http://crunchbanglinux.org/forums/topic/1093/post-your-bashrc/
    case "$1" in
      *.tar.bz2|*.tbz2)             tar xvjf                 "$1";;
      *.tar.gz|*.tgz|*.tar.Z|*.taz) tar xvzf                 "$1";;
      *.tar.xz)                     tar xvJf                 "$1";;
      *.tar)                        tar xvf                  "$1";;
      *.bz2)                        bunzip2                  "$1";;
      *.rar)                        unrar x                  "$1";;
      *.jar)                        unzip                    "$1";;
      *.gz)                         gzip --decompress --name "$1";;
      *.zip)                        unzip                    "$1";;
      *.Z)                          uncompress               "$1";;
      *.7z)                         7z x                     "$1";;
      *.xz)                         xz x                     "$1";;
      *.exe)                        cabextract               "$1";;
      *.deb|ar) echo TODO; exit 1;;
      *) echo "`basename "$0"`: Don't know how to extract '$1'." >&2; exit 1;;
    esac
  }
fi
for arg; do
  unpack "$arg"
done
