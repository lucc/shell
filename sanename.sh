#!/bin/sh

OPTIONS=
RECURSIVE=flase
RENAME_PATTERN_1='s/[^.~_\w\/-]/_/g;tr/[A-Z]/[a-z]/;s/^/_/'
RENAME_PATTERN_2='s/^_*//'

while getopts nr FLAG; do
  case $FLAG in
    n) OPTIONS=-n;;
    r) RECURSIVE=true;;
  esac
done
shift $((OPTIND-1))

if [ $# -eq 0 ]; then
  set *
fi

if $RECURSIVE; then
  find -f "$@" -exec rename "$RENAME_PATTERN_1" $OPTIONS {} +
  find -f "$@" -exec rename "$RENAME_PATTERN_2" $OPTIONS {} +
else
  rename "$RENAME_PATTERN_1" $OPTIONS "$@" 
  rename "$RENAME_PATTERN_2" $OPTIONS "$@"
fi
