#!/bin/sh

# there is a package "unp" to do exactly this.

# idea from http://crunchbanglinux.org/forums/topic/1093/post-your-bashrc/
if [ $# -ne 1 ]; then
  echo "Specify exactly one argument." >&2
  exit 1
fi
if [ -f "$1" ]; then
  case "$1" in
    *.tar.bz2|*.tbz2)			tar xvjf                 "$1";;
    *.tar.gz|*.tgz|*.tar.Z|*.taz)	tar xvzf                 "$1";;
    *.tar.xz)				tar xvJf                 "$1";;
    *.tar)       			tar xvf                  "$1";;
    *.bz2)     	  			bunzip2                  "$1";;
    *.rar)       			unrar x                  "$1";;
    *.jar) 				unzip                    "$1";;
    *.gz)        			gzip --decompress --name "$1";;
    *.zip)       			unzip                    "$1";;
    *.Z)         			uncompress               "$1";;
    *.7z)        			7z x                     "$1";;
    *.xz)				xz x                     "$1";;
    *.exe)				cabextract               "$1";;
    *.deb|ar) echo TODO; exit 1;;
    *) echo "`basename "$0"`: Don't know how to extract '$1'." >&2; exit 1;;
  esac
else
  if [ -d "$1" ]; then
    tar cvzf "$1.tar.gz" "$1"
  else
    echo "Unknown argument try: cat `which $0`" >&2
    exit 1
  fi
fi
