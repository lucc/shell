#!/bin/sh

DRYRUNOPTION=-n

help () {
  local PROGRAM=`basename "$0"`
  echo "$PROGRAM <pattern>"
  echo "$PROGRAM <pattern> -f"
  echo
  echo "the pattern must contain one # where the numbers are. If -f is given files are renamed otherwise only a simulation is run."
  exit 1
}

while getopts fnp: FLAG; do
  case $FLAG in
    f)
      DRYRUNOPTION=
      ;;
    n)
      DRYRUNOPTION=-n
      ;;
    p)
      PATTERN="$OPTARG"
      ;;
    *)
      help
      ;;
  esac
done

shift $(($OPTIND-1))

while [ $# -ne 0 ]; do
  PATTERN="$1"
  shift
done

if [ -z "$PATTERN" ]; then
  echo "No pattern given."
  help
fi

#if [ $# -ne 1 -a $# -ne 2 ]; then help; fi;

if echo "$PATTERN" | grep --color=auto -qv "#"; then
  exit 1
fi
#if [ "$2" = -f ]; then DRYRUNOPTION= ; fi

pre2="${PATTERN%%#*}"
#pre2=`echo "$PATTERN" | sed 's/#.*$//'`
pre1="${pre2//./\.}"
#pre1=`echo "$pre2" | sed 's/\./\\./g'`
post2="${PATTERN##*#}"
#post2=`echo "$PATTERN" | sed 's/^.*#//'`
post1="${post2//./\.}"
#post1=`echo "$post2" | sed 's/\./\\\\./g'`

i=`ls | \
  sed -n s/".*${pre1}\([0-9]\{1,\}\)${post1}.*"/'\1'/p | \
  awk '{ if (length > x) { x = length } } END { print x }'`

while [ $i -gt 1 ]; do
  num="$num\d"
  i=$((i-1))
  rename ${DRYRUNOPTION} "s/${pre1}(${num})${post1}/${pre2}0\$1${post2}/" *
done

echo "rename 's/${pre1}(${num})${post1}/${pre2}0\$1${post2}/' *"

exit 




# i counld try to write a perl program to do this
