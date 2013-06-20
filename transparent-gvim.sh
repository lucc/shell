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
#if [ -z "$SERVER" ]; then
#  echo No VIM server running. Aborting ... >&2
#  exit 1
#fi

vimserver () {
  vim --servername "$SERVER" "$@"
}

man () {
  if [ $# -eq 0 ]; then
    echo Topic needed >&2
    exit
  fi
  #send ':tabnew +Man\ '${1}'<CR>'
  call "LucManPageFunction('$@')" > /dev/null
  foreground
}

info () {
  man "$1${1:+.i}" "${@:2}"
}

foreground () {
  if [ `uname` = Darwin ]; then
    open -a MacVim
  else
    vimserver --remote-expr 'foreground()' > /dev/null
  fi
}

send () {
  vimserver --remote-send "<C-\><C-N>$*"
}

call () {
  vimserver --remote-expr "$@"
}

if [ $# -eq 0 ]; then
  if [ -z "$SERVER" ]; then
    CMD=vim
  else
    CMD=foreground
  fi
else
  while getopts fimpst FLAG; do
    case $FLAG in
      f)
	# force to open a vim instance even if no server is running
	if [ -z "$SERVER" ]; then
	  CMD=vim
	fi
	;;
      i)
	CMD=info
	;;
      m)
	CMD=man
	;;
      p)
	CMD=vimserver
	;;
      s)
	CMD=send
	;;
      t)
	CMD='vimserver --remote-tab-wait-silent'
	;;
      *)
	echo Unkown action! Aborting ... >&2
	exit 2
	;;
    esac
  done
fi

shift $(($OPTIND - 1))

$CMD "$@"
