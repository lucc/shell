#!/usr/bin/env bash

# Use tmux to manage some youtube-dl processes

version=0.2
prog=${0##*/}
session=youtube-dl
dir=~/vid/new

usage () {
  echo "Usage: $prog [options] [url ...]"
  echo "       $prog [options] [-a]"
  echo "       $prog [options] {-l,-q}"
  echo "       $prog [options] -p index"
  echo "       $prog [options] -t [ -- <tail-options>]"
  echo "       $prog [options] -k index"
  echo "       $prog [options] -r {url,index}"
  echo "       $prog [options] -i url"
  echo "       $prog -h"
  echo "       $prog -v"
}

help () {
  echo "Use tmux to manage some youtube-dl processes."
  echo
  echo Commands:
  echo "  -h    display help"
  echo "  -v    display version"
  echo "  -a    attach to the tmux session for manuall interaction"
  echo "  -l    list urls of running jobs"
  # TODO poke
  echo "  -p    poke TODO ..."
  echo "  -q    kill all jobs, quit the server"
  echo "  -t    show the tail -n 1 of every job"
  echo "  -k    kill a job"
  echo "  -r    restart a job"
  echo "  -i    run the downloading loop (for internal use only)"
  echo
  echo Options:
  echo "  -x    debugging output"
  echo "  -d    set working directory to given argument"
  echo
  echo "The default command is 'attach' if no arguments are given.  If urls"
  echo "are given they will be loaded in the background."
}

list_windows () {
  tmux list-windows -t "$session" -F "$1"
}
has_session () {
  tmux has-session -t "$session${1+:$1}" 2>/dev/null
}

command=load
while getopts ad:hi:k:lp:qr:tvx FLAG; do
  case $FLAG in
    a) command=attach;;
    d) dir=$OPTARG;;
    h) usage; help; exit;;
    i) command=inner-load url=$OPTARG;;
    k) command=kill index=$OPTARG;;
    l) command=list;;
    p) command=poke; index=$OPTARG;;
    q) command=quit;;
    r) command=restart id=$OPTARG;;
    t) command=tail;;
    v) echo "$prog -- version $version"; exit;;
    x) set -x;;
    *) usage >&2; exit 2;;
  esac
done
shift $((OPTIND - 1))

if [[ "$command" = load && $# -eq 0 ]]; then
  command=attach
fi

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
      # If the tmux $session is running check if the url is already being
      # downloaded.  Else start $session and download the url.
      if has_session; then
	# If $url is already being downloaded don't start a second instance.
	if list_windows '#{window_name}' | grep --quiet --fixed-strings "$url"
	then
	  echo Already registered: "$url"
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
	  bash -$- "$0" -i "$url"
      fi
    done
    ;;
  inner-load)
    # TODO this is still buggy.  The success and failure conditions are not
    # set correctly.  Normally the loop runs too often but on some error
    # conditions it exits prematurely.
    tmp=$(mktemp)
    while
      command youtube-dl "$url" 2>&1 | tee "$tmp"
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
  kill) tmux kill-window -t "$session:$index";;
  list) list_windows '#{window_index}: #{window_name}';;
  poke)
    if [[ "$index" == all ]]; then
      ppids=( $(list_windows '#{pane_pid}') )
    else
      ppids=( $(list_windows '#{window_index} #{pane_pid}' | sed -n "s/^$index //p") )
    fi
    for ppid in "${ppids[@]}"; do
      # TODO
      : "$ppid"
    done
    ;;
  quit) tmux kill-session -t "$session";;
  restart)
    list_windows '#{window_index}	#{window_name}' | \
      while read -r index name; do
	if [[ "$index" == "$id" || "$name" == "$id" ]]; then
	  "$0" -k "$index"
	  "$0" "$name"
	fi
      done
    ;;
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
