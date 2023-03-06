#!/usr/bin/env bash

set -euo pipefail

filter=cat
once=false
test=false
interval=60

usage () {
  echo "Usage: ${0##*/} [-f filter] [-i sec] [-o] url address [address ...]"
  echo "       ${0##*/} [-f filter] -t url"
}
help () {
  cat <<-EOF
	Watch an URL and if it changes send a mail

	The first non option argument is the url that will be watched.
	Following arguments are email addresses that are notified on changes.

	Options:
	    -t   run in test mode
	    -i   set the interval
	    -f   filter to parse html before comparing
	    -o   exit after the first change was found
	EOF
}
fetch () {
  curl --location --silent --connect-timeout 10 "$@" | $filter
}

while getopts hf:i:ot FLAG; do
  case $FLAG in
    h) usage; help; exit;;
    f) filter=$OPTARG;;
    i) interval=$OPTARG;;
    o) once=true;;
    t) test=true interval=1;;
    *) usage >&2; exit 2;;
  esac
done

shift $((OPTIND-1))
url=$1
shift
addresses=("$@")

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cd "$dir"
fetch "$url" > new

if "$test"; then
  mv new old
  sleep "$interval"
  fetch "$url" > new
  diff old new
  exit
fi

while sleep "$interval"; do
  mv new old
  fetch "$url" > new
  if ! diff -q old new; then
    date "+%F %T: change detected"
    mail -s "URL Watcher: $url changed" "${addresses[@]}" <<-EOF
	The URL $url has changed during the last $interval seconds.
	EOF
    if "$once"; then exit; fi
  fi
done
