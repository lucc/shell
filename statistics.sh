#!/bin/sh

## static data:
DIR=.
LOGFILE=files.txt
OUTPUT=
BAD_FILES=false
REMOVE=
POS=
LENGTH=80

help () {
  local PROG=`basename "$0"`
  echo "$PROG [-b] [-t] [-d directory] [-l length]"
  echo "$PROG -r [-d directory] [-l length]"
  echo "$PROG -p d[ir]|f[ile]|s[ize]|b[ad] [-d directory] [-l length]"
  echo "$PROG -h"
}

find_bad_files () {
  #local BAD_CHARS='][{}()<>!?,:;^#§$%&@+*"'"'"
  #local BAD_CHARS='][{}()<>!?,;^#§$%&@+*"'"'"
  # filenames of mail files have : and , chars
  local BAD_CHARS='][{}()<>!?;^#§$%&@+*"'"'"
  find -LE . \
    -path '*.wine/dosdevices' -prune -o \
    \( -name ".?*" -o -name "*[$BAD_CHARS]*" -o -regex ".{$LENGTH,}" \) \
    -print $REMOVE
}

hirarchy_info_function () {
  # redirect all errors to /dev/null
  exec 2>/dev/null
  # need tree to be installed
  which -s tree || exit -1
  #summed up info about trees at "$@" (or ".")
  local count=
  local size=
  local sizeH=
  if [ "$1" ]; then
    for file; do
      count=`tree -ai "$file" | tail -n 1`
      #darwin/OSX no '-b=1' for du
      size_=`duI dosdevices -s "$file"`
      sizeH=`duI dosdevices -hs "$file"`
      #darwin/OSX: '512'
      echo "$file: ${count}, ${sizeH%%$'\t'*} ($((512*${size_%%$'\t'*})))"
    done
    echo ""
  fi
  count=`tree -ai "$@" | tail -n 1`
  #darwin/OSX no '-b=1' for du
  size_=`du -csI dosdevices "$@" | tail -n 1`
  sizeH=`du -chsI dosdevices "$@" | tail -n 1`
  #darwin/OSX: '512'
  echo "${count}, ${sizeH%%$'\t'*} ($((512*${size_%%$'\t'*})))"
}

while getopts "bd:hl:p:rtw" FLAG; do
  case "$FLAG" in
    b) BAD_FILES=true;;
    d)
      DIR="$OPTARG"
      if [ ! -d "$DIR" ]; then
	echo "Error: $DIR is not a directory" 1>&2
	exit 2
      fi
      ;;
    h) help; exit;;
    l)
      if [ "$OPTARG" -gt 0 ]; then
	LENGTH=$OPTARG
      fi
      ;;
    p)
      case "$OPTARG" in
	d|dir) POS=6;;
	f|file) POS=8;;
	s|size) POS=12;;
	b|bad) POS=14;;
	*) help >&2; exit 2;;
      esac
      ;;
    r) REMOVE=-delete BAD_FILES=true OUTPUT=false;;
    t) OUTPUT=false;;
    w) OUTPUT=true;;
    *) help >&2; exit 2;;
  esac
done
cd "$DIR"

if [ "$POS" ]; then
  sed 's/(/( /g;s/)/ )/g' "$LOGFILE" | \
    sort -n -t " " -k $POS | \
    sed 's/( /(/g;s/ )/)/g' | \
    grep --color=always \
         --after-context 5 \
	 --before-context `wc -l <"$LOGFILE"` \
	 "`tail -n 1 "$LOGFILE"`"
  exit
fi

# should we write to ${LOGFILE} or to /dev/stdout ?
if [ -z "$OUTPUT" ]; then
  if [ -f "$LOGFILE" ] && \
    [ `sed -n '${s/ .*//;s/-//g;p;}' "$LOGFILE"` -ge `date +%Y%m%d` ]; then
    OUTPUT=false
  else
    OUTPUT=true
  fi
# else do nothing
fi
if ! $OUTPUT; then
  echo "Not writing to file." 1>&2
  OUTPUT=/dev/null
else
  OUTPUT=$LOGFILE
fi

# the man page says tab is the default delimiter
sizeh=`du -LhsI dosdevices 2>/dev/null | cut -f 1`
size=`du -LksI dosdevices 2>/dev/null | cut -f 1`
DIR=$((`find -L . -path '*.wine/dosdevices' -prune -o -type d 2>/dev/null | wc -l` - 1))
files=`find -L . -path '*.wine/dosdevices' -prune -o -not -type d -print 2>/dev/null | wc -l`

# do we need the names of the bad files, or only the count?
if $BAD_FILES; then
  # we need the names
  BAD_FILES=`find_bad_files`
  count=`echo "$BAD_FILES" | wc -l`
  if [ -z "$BAD_FILES" ]; then count=0; fi
else
  # only the count
  count=`find_bad_files | wc -l`
  BAD_FILES=
fi

# give the old statistics for comparison
tail "$LOGFILE" 2>/dev/null

# echo data to $OUTPUT
#FIXME there are unescaped tab characters needed here.
#echo `LANG=en date '+%F %T (%a)'`: $DIR directories, $files files, ${sizeh%	*} \(${size%	*}\), $count bad filenames. | tee -a "$OUTPUT"
echo `LANG=en date '+%F %T (%a)'`: $DIR directories, $files files, $sizeh \($size\), $count bad filenames. | tee -a "$OUTPUT"

# print bad filenames if asked.
#if $REMOVE; then
#  echo "Removing:"
#  echo "${BAD_FILES:-...nothing!}"
#  echo "$BAD_FILES" | while read line; do
#    rm "$line"
#  done
#elif [ "$BAD_FILES" ]; then echo; echo "$BAD_FILES"; fi
if [ "$BAD_FILES" ]; then echo; echo "$BAD_FILES"; fi
