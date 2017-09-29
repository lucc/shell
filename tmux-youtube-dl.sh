#!/bin/bash

# Use tmux to manage some youtube-dl processes

version=0.1
prog=${0##*/}
session=youtube-dl
dir=~/vid/tmp
xtrace=

usage () {
  echo "Usage: $prog [options] url [url ...]"
  echo "       $prog [options] -l"
  echo "       $prog [options] -p index"
  echo "       $prog [options] -q"
  echo "       $prog [options] -t [ -- <tail-options>]"
  echo "       $prog [options] -i url"
  echo "       $prog -h"
  echo "       $prog -v"
}

help () {
  echo "Use tmux to manage some youtube-dl processes"
  echo
  echo "  -h    display help"
  echo "  -v    display version"
  echo "  -x    debugging output"
  echo "  -d    set working directory to given argument"
  echo "  -a    attach to the tmux session for manuall interaction"
  echo "  -l    list urls of running jobs"
  # TODO poke
  echo "  -p    poke TODO ..."
  echo "  -q    kill all jobs, quit the server"
  echo "  -t    show the tail -n 1 of every job"
  echo "  -i    run the downloading loop (for internal use only)"
}

list_windows () {
  tmux list-windows -t "$session" -F "$1"
}
has_session () {
  tmux has-session -t "$session${1+:$1}" 2>/dev/null
}

command=load
while getopts ad:hi:lp:qtvx FLAG; do
  case $FLAG in
    a) command=attach;;
    d) dir=$OPTARG;;
    h) usage; help; exit;;
    i) command=inner-load url=$OPTARG;;
    l) command=list;;
    p) command=poke; index=$OPTARG;;
    q) command=quit;;
    t) command=tail;;
    v) echo "$prog -- version $version"; exit;;
    x) set -x; xtrace=-x;;
    *) usage >&2; exit 2;;
  esac
done
shift $((OPTIND - 1))

case $command in
  attach)
    exec tmux attach-session -t "$session"
    ;;
  load)
    if [ $# -eq 0 ]; then
      usage >&2
      exit 2
    fi
    for url; do
      if [ -z "$url" ]; then
	usage >&2
	exit 2
      fi
      # If the tmux $session is running check if the url is alreay beeing
      # downloaded.  Else start $session and download the url.
      if has_session; then
	# If $url is already beeing downloaded don't start a second instance.
	if list_windows '#{window_name}' | fgrep -q "$url"; then
	  echo Alread registered: "$url"
	else
	  if has_session 0; then
	    append=-a
	  else
	    append=
	  fi
	  tmux new-window -c "$dir" -d $append -t "$session:0" -n "$url" \
	    "$0" -i "$url"
	fi
      else
	tmux new-session -d -s "$session" -n "$url" -c "$dir" \
	  "$0" $xtrace -i "$url"
      fi
    done
    ;;
  inner-load)
    # TODO this is still buggy.  The success and failure conditions are not
    # set correctly.  Normally the loop runs too often but on some error
    # conditions it exits prematurely.
    tmp=$(mktemp)
    while
      youtube-dl "$url" 2>&1 | tee "$tmp"
      youtube_dl_return_code=${PIPESTATUS[0]}
      errors="Unsupported URL|Unable to extract (URL|encrypted data)"
      errors+="|Video .* does not exist"
      if grep -E -q "^ERROR: ($errors)" "$tmp"; then
	break
      fi
      ((youtube_dl_return_code == 0))
    do
      sleep 10
    done
    rm "$tmp"
    ;;
  list) list_windows '#{window_index}: #{window_name}';;
  poke)
    if [[ "$index" == all ]]; then
      ppids=( $(list_windows '#{pane_pid}') )
    else
      ppids=( $(list_windows '#{window_index} #{pane_pid}' | sed -n "s/^$index //p") )
    fi
    for ppid in "${ppids[@]}"; do
      # TODO
      :
    done
    ;;
  quit) tmux kill-session -t "$session";;
  tail)
    list_windows '#{window_index}' | while read -r index; do
      tmux capture-pane -J -p -t "$session:$index" | grep -v '^$' | \
	tail "${@:--n1}"
    done
    ;;
  *)
    echo This should never happen >&2
    exit 3
    ;;
esac
