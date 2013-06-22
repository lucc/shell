#!/bin/sh

# A script to use gvim as a replacement for different programs like man and
# info or to call a gvim server.

# find a vim server
SERVER=`vim --serverlist | head -n 1`
if [ -z $SERVER ]; then
  ( gvim && sleep 2 ) >/dev/null 2>&1
fi
SERVER=`vim --serverlist | head -n 1`
CMD=vimserver

# wrapper functions for basic interaction with Vim
vimserver ()  { vim --servername "$SERVER" "$@"; }
call ()       { vimserver --remote-expr "$@"; }
foreground () { vimserver --remote-expr 'foreground()' > /dev/null; }
send ()       { vimserver --remote-send "<C-\><C-N>$*"; }

# generic function to open documentation
doc () {
  if [ $# -eq 0 ]; then
    echo Topic needed >&2
    exit 2
  fi
  call "LucTManWrapper('"$1"', '"${@:2}"')" > /dev/null
  foreground
}

# wrapper functions for individual help systems
info    () { doc i   "$@"; }
man     () { doc man "$@"; }
perldoc () { doc pl  "$@"; }
php     () { doc php "$@"; }
pydoc   () { doc py  "$@"; }

if [ $# -eq 0 ]; then
  CMD=foreground
else
  #while getopts fimpsty FLAG; do
  #  case $FLAG in
  #    i) CMD=info;;
  #    m) CMD=man;;
  #    p) CMD=perldoc;;
  #    s) CMD=send;;
  #    t) CMD='vimserver --remote-tab-wait-silent';;
  #    y) CMD=pydoc;;
  #    *)
  #      echo Unkown action! Aborting ... >&2
  #      exit 2
  #      ;;
  #  esac
  #done
  # trying to implement long options
  for arg; do
    case "$arg" in
      --info) CMD=info;;
      --man) CMD=man;;
      --perldoc|--perl|--pl) CMD=perldoc;;
      --php) CMD=php;;
      --pydoc|--python|--py) CMD=pydoc;;
      --tab) CMD='vimserver --remote-tab-wait-silent';;
      *) new_args=("${new_args[@]}" "$arg")
    esac
  done
fi

shift $(($OPTIND - 1))

#$CMD "$@"
$CMD "${new_args[@]}"
