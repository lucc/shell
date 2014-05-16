#!/bin/sh

command=wc
files=''
directory=.
filter='tail -n 1'

while getopts c:d:f:F:h FLAG; do
  case $FLAG in
    c)
      command="$OPTARG"
      ;;
    d)
      directory="$OPTARG"
      ;;
    f)
      files="$files $OPTARG"
      ;;
    F)
      filter="$OPTARG"
      ;;
    h)
      echo HELP
      exit
      ;;
    *)
      exit 2
      ;;
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

git log --oneline | while read ref msg; do
  git checkout -f $ref 2>/dev/null
  printf '%s %-70s %s\n' $ref "$msg" "$($command $files 2>/dev/null | $filter)"
done

git checkout $head 2>/dev/null
