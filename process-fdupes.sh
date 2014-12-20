#!/bin/sh

delete='rm -f "$next"'
link='ln -vf "$last" "$next"'
message=false
cmd="$link"
die () { echo "$@" >&2; exit 2; }
ask () {
  local reply
  read -n 1 -p "$1 [y|N]" reply
  [ "$reply" = y -o "$reply" = Y ]
}

if [ -t 0 ]; then
  die You have to pipe the ouput of fdupes into this script.
fi
while getopts ahnvqldc: FLAG; do
  case $FLAG in
    a) ask=true;;
    h) die \
      'Pipe the ouput of fdupes into this script.
      Valid options are
	-l to link or
	-d to delete duplicates,
	-v and -q for verbose or quiet mode,
	-a to ask before running the command and
	-n for test runs (noop).';;
    n) noop=true;;
    v) message=echo;;
    q) message=false;;
    l) cmd="$link";;
    d) cmd="$delete";;
    c) cmd="$OPTARG";;
    *) die Try $0 -h;;
  esac
done
if [ "$noop" ]; then cmd="echo $cmd"
#elif [ "$ask" ]; then cmd="ask 'Run $cmd ?' && $cmd"
fi

next=
last=
while read next; do
  if [ "$last" = '' ]; then
    $message \$last was empty when reading \$next, continueing... >&2
    last="$next"
  elif [ "$next" = '' ]; then
    $message Read empty line, reseting \$last ... >&2
    last=
  else
    eval $cmd
    last="$next"
  fi
done
