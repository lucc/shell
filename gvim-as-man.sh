#!/bin/sh

# A script to use gvim as a replacement for different programs like man and
# info or to call a gvim server.

# find a vim server
SERVER=`vim --serverlist | head -n 1`
if [ -z "$SERVER" ]; then
  echo No VIM server running. Aborting ... >&2
  exit 1
fi

vimserver () {
  vim --servername "$SERVER" "$@"
}

man () {
  if [ $# -eq 0 ]; then
    echo Topic needed >&2
    exit
  fi
  vimserver --remote-send '<C-\><C-N>:tabnew +Man\ '${1}'<CR>'
}

info () {
  if [ $# -eq 0 ]; then
    echo Topic needed >&2
    exit
  fi
  vimserver --remote-send '<C-\><C-N>:tabnew +Man\ '${1}'.i<CR>'
}

foreground () {
  if [ `uname` = Darwin ]; then
    open -a MacVim
  else
    vimserver --remote-send '<C-\><C-N>:call foreground()<CR>'
  fi
}

send () {
  vimserver --remote-send "<C-\><C-N>$*"
}

if [ $# -eq 0 ]; then
  foreground
else
  case "$1" in
    man|--man|-m)
      shift
      man "$@"
      ;;
    info|--info|-i)
      shift
      info "$@"
      ;;
    send|--send|-s)
      shift
      send "$@"
      ;;
    open|--open|-o)
      shift
      vimserver --remote-tab-wait-silent -- "$@"
      ;;
    foreground|--foreground|-f)
      foreground
      ;;
    plain|--plain|-p)
      vimserver --remote-tab-wait-silent "$@"
      ;;
    *)
      echo Unkown action! Aborting ... >&2
      exit 2
      ;;
  esac
fi
