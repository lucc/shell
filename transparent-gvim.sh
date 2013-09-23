#!/bin/sh

# A script to use gvim as a replacement for different programs like man and
# info or to call a gvim server.

# find a vim server
#PROG=`basename "$0" | tr ' ' _`
TMP=`mktemp -t $PROG.$$.XXXXXX`
#WAIT=false
SAVE_STDIN=false
if [ -z "`vim --serverlist`" ]; then
  gvim &
fi

#CMD=vimserver

# other functions
save_stdin () { cat > $TMP; }

# wrapper functions for basic interaction with Vim
#vimserver ()  { vim --servername "$SERVER" "$@"; }
#call ()       { vimserver --remote-expr "$@"; }
foreground () { wait_server && vim --remote-expr 'foreground()' > /dev/null; }
#send ()       { vimserver --remote-send "<C-\><C-N>$*"; }
tab ()        { wait_server && vim --remote-tab-wait-silent "$@"; }
wait_server () {
  vim -u NONE --cmd 'while serverlist() == "" | sleep 100m | endwhile | quit'
}

# generic function to open documentation
doc () {
  if [ $# -eq 0 ]; then
    echo Topic needed >&2
    exit 2
  fi
  call "LucTManWrapper('"$1"', '"${@:2}"')" > /dev/null
  #foreground
}
doc () {
  if [ $# -eq 0 ]; then
    echo Topic needed >&2
    exit 2
  fi
  vim -u NONE --cmd "
    while serverlist() == ''
      sleep 100m
    endwhile
    let s = split(serverlist())[0]
    call remote_expr(s, 'LucTManWrapper(\"$1\", \"${@:2}\")')
    call remote_foreground(s)
    quit
  "
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
  # trying to implement long options
  for arg; do
    case "$arg" in
      --info) CMD=info;;
      --man) CMD=man;;
      --perldoc|--perl|--pl) CMD=perldoc;;
      --php) CMD=php;;
      --pydoc|--python|--py) CMD=pydoc;;
      --stdin) SAVE_STDIN=true; CMD=${CMD:-tab};;
      --tab) CMD=tab WAIT=true;;
      *) new_args=("${new_args[@]}" "$arg");;
    esac
  done
fi

shift $(($OPTIND - 1))

if $SAVE_STDIN; then
  save_stdin
  new_args=("${new_args[@]}" "$TMP")
fi

#$CMD "$@"
#$WAIT && wait
$CMD "${new_args[@]}" >/dev/null
