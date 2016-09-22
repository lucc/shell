#!/bin/bash

# Use tmux to manage some youtube-dl processes

version=0.1
prog=${0##*/}
session=youtube-dl
dir=~/vid/tmp

usage () {
  echo "Usage: $prog [options] url"
  echo "       $prog [options] -l"
  echo "       $prog [options] -q"
  echo "       $prog [options] -t"
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
  echo "  -a    attach to the tmux session for manuall interaction"
  echo "  -l    list urls of running jobs"
  echo "  -q    kill all jobs, quit the server"
  echo "  -t    show the tail -n 1 of every job"
  echo "  -i    run the downloading loop (for internal use only)"
}

list_windows () {
  tmux list-windows -t "$session" -F "$1"
}

command=load
while getopts ahi:lqtvx FLAG; do
  case $FLAG in
    a) command=attach;;
    h) usage; help; exit;;
    i) command=inner-load url=$OPTARG;;
    l) command=list;;
    q) command=quit;;
    t) command=tail;;
    v) echo "$prog -- version $version"; exit;;
    x) set -x;;
    *) usage >&2; exit 2;;
  esac
done
shift $((OPTIND - 1))

case $command in
  attach)
    exec tmux attach-session -t "$session"
    ;;
  load)
    if [ $# -ne 1 ] || [ -z "$1" ]; then
      usage >&2
      exit 2
    fi
    url=$1
    # If the tmux $session is running check if the url is alreay beeing
    # downloaded.  Else start $session and download the url.
    if tmux has-session -t "$session" 2>/dev/null; then
      # If $url is already beeing downloaded don't start a second instance.
      if list_windows '#{#window_name}' | fgrep -q "$url"; then
	echo Alread registered: "$url"
      else
	tmux new-window -c "$dir" -d -a -t "$session:1" -n "$url" \
	  "$0" -i "$url"
      fi
    else
      tmux new-session -d -s "$session" -n "$url" -c "$dir" "$0" -i "$url"
    fi
    ;;
  inner-load)
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
  quit) tmux kill-session -t "$session";;
  tail)
    list_windows '#{window_index}' | while read -r index; do
      tmux capture-pane -J -p -t "$session:$index" | grep -v '^$' | tail -n 1
    done
    ;;
  *)
    echo This should never happen >&2
    exit 3
    ;;
esac
