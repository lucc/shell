#!/bin/sh

delete='rm -f $verbose_opt "$next"'
link='ln -f $verbose_opt "$last" "$next"'
message=false
verbose_opt=-v
cmd="$link"
header=false
die () { echo "$@" >&2; exit 2; }
ask () {
  local reply
  read -n 1 -p "$1 [y|N]" reply
  [ "$reply" = y -o "$reply" = Y ]
}

while getopts ahnvqldc: FLAG; do
  case $FLAG in
    a) ask=true;;
    h) die \
      'Pipe the ouput of fdupes into this script.
      Valid options are
	-l to link or
	-d to delete duplicates,
	-v and -q for verbose or quiet mode,
	-a to ask before running the command,
	-n for test runs (noop) and
	-H to skip first line of each duplicates block (header lines).';;
    H) header=true;;
    n) noop=true;;
    v) message=echo verbose_opt=-v;;
    q) message=false verbose_opt=;;
    l) cmd="$link";;
    d) cmd="$delete";;
    c) cmd="$OPTARG";;
    *) die Try $0 -h;;
  esac
done
if [ -t 0 ]; then
  die You have to pipe the ouput of fdupes into this script.
fi
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
    if $header; then
      $message Reading \(and dropping\) header line ... >&2
      read next
    fi
  else
    eval $cmd
    last="$next"
  fi
done
