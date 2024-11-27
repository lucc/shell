#!/bin/sh

git_cmd="$(basename "$0")"
git_cmd="${git_cmd#git-}"
command=wc
files=''
directory=.
filter='tail -n 1'
log_args=''

usage () {
  echo "Usage: git $git_cmd [-x] [-c command] [-d directory] [-f files]"
  echo "           ${git_cmd//?/ } [-F filter_cmd] [-l log_args]"
  echo "       git $git_cmd -h"
}
help () {
  echo "Check out each rev and execute a command.  Then print a line with the"
  echo "output of the command prefixed with the commit id."
  echo "Defaults:"
  echo "  command: $command"
  echo "  files: $files"
  echo "  directory: $directory"
  echo "  filter: $filter"
  echo "  log_args: $log_args"
}

while getopts c:d:f:F:l:hx FLAG; do
  case $FLAG in
    c) command="$OPTARG";;
    d) directory="$OPTARG";;
    f) files="$files $OPTARG";;
    F) filter="$OPTARG";;
    l) log_args="$OPTARG";;
    h) usage; help; exit;;
    x) set -x;;
    *) usage >&2; exit 2;;
  esac
done

if [ -z "$files" ]; then
  files='*'
fi

cd "$directory" || exit 2
if [ "$(git status --porcelain)" != '' ]; then
  echo Please clean up your working directory first. >&2
  exit 2
fi

head=$(git rev-parse --abbrev-ref HEAD)

git log --oneline $log_args | while read ref msg; do
  git checkout -f $ref 2>/dev/null
  printf '%s %-70s %s\n' $ref "$msg" "$($command $files 2>/dev/null | $filter)"
done

git checkout $head 2>/dev/null
