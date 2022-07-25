#!/usr/bin/env bash

set -euo pipefail

filter=(cat)
once=false
test=false
interval=60

usage () {
  echo "Usage: "${0##*/} [-i sec] [-f] [-o] url address [address ...]
  echo "       "${0##*/} -t url
}
help () {
  cat <<-EOF
	Watch an URL and if it changes send a mail
	EOF
}
fetch () {
  curl --location --silent --connect-timeout 10 "$@" | "${filter[@]}"
}

while getopts fhi:ot FLAG; do
  case $FLAG in
    f) filter=(elinks -force-html -dump);;
    h) usage; help; exit;;
    i) interval=$OPTARG;;
    o) once=true;;
    t) test=true;;
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
  sleep 1
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
	The URL $url has changed during the last $iterval seconds.
	EOF
    if "$once"; then exit; fi
  fi
done
