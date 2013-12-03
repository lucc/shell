#!/bin/sh

# A shell script to set up some environment variables.  This should be run or
# sourced early in the boot or login procedure.

add_to_var () {
  local varname="$1"
  eval local tmp='$'$varname
  shift
  for dir; do
    if [ -d "$dir" ]; then
      tmp=$dir:$tmp
    fi
  done
  tmp=`printf %s $tmp | awk -v RS=: -v ORS=: '!path[$0]{path[$0]=1;print}'`
  eval export $varname=${tmp%:}
}

set_path () {
  add_to_var PATH            \
    /usr/local/share/python3 \
    /usr/texbin              \
    /sbin                    \
    /bin                     \
    /usr/bin                 \
    /usr/sbin                \
    /usr/local/bin           \
    /usr/local/sbin          \
    /opt/X11/bin             \
    /usr/X11/bin             \
    /opt/local/bin           \
    /opt/local/sbin          \
    $HOME/src/shell          \
    $HOME/.cabal/bin         \

}

set_manpath () {
  # TODO
  :
}

set_infopath () {
  add_to_var INFOPATH                      \
    /usr/local/share/info                  \
    /usr/share/info                        \
    /usr/local/texlive/2012/texmf/doc/info \

}

export_to_launchd () {
  for var in                           \
      PATH                             \
      MANPATH                          \
      INFOPATH                         \
      PYTHONSTARTUP                    \
      COPY_EXTENDED_ATTRIBUTES_DISABLE \
      LANG                             \
      ; do
    eval launchctl setenv $var \$$var
  done
}

export PYTHONSTARTUP=~/.config/shell/pystartup
export COPY_EXTENDED_ATTRIBUTES_DISABLE=true
export LANG=en_US.UTF-8
set_path
set_manpath
set_infopath

if [ "$1" = --launchd -o "$1" = launchd ]; then
  export_to_launchd
fi
