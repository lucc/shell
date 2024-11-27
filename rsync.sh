#!/usr/bin/env bash

set -e -o pipefail

print_help () {
  cat <<-'EOF'
	This script wraps rsync(1) to create incremental snapshots to a given
	destination.  Disk space is saved by hardlinking unchanged files with
	rsync's --link-dest.
	EOF
}
print_usage () {
  echo "Usage: ${0##*/} -d dest [--] sources and any rsync options"
  echo "       ${0##*/} -h"
}

unset dest

set -u

while getopts d:h FLAG; do
  case $FLAG in
    d) dest=$OPTARG;;
    h) print_usage; print_help; exit;;
    *) print_usage >&2; exit 2;;
  esac
done
shift $((OPTIND - 1))

if [[ $dest =~ ::|^rsync:// ]]; then
  cat >&2 <<-'EOF'
	The rsync protocol is not supported by this script, only ssh and
	local transfers.
	EOF
  exit 1
fi

timestamp=$(date +%Y%m%d%H%M%S)

# Hide the exit code because rsync "fails" for some errors that I'm not
# interested in.
rsync --archive --one-file-system --link-dest=../latest \
  "$@" "$dest/$timestamp.in_progress" || true

host=${dest%%:*}
path=${dest#*:}
if [[ $host ]]; then
  ssh "$host" cd "'$path'" \
    '&&' mv $timestamp.in_progress $timestamp \
    '&&' ln -fns $timestamp latest
else
  cd "$path"
  mv $timestamp.in_progress $timestamp
  ln -fns $timestamp latest
fi
