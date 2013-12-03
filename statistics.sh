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
  find -LE "$@"                                                         \
    -path '*.wine/dosdevices' -prune -o                                 \
    \( -name ".?*" -o -name "*[$BAD_CHARS]*" -o -regex ".{$LENGTH,}" \) \
    -print $REMOVE
}

count_files () {
  # find -H means follow symlinks on command line but nowhere else
  find -H "$@" -not -type d 2>/dev/null | wc -l
  # originally this was
  #find -H . -path '*.wine/dosdevices' -prune -o -not -type d -print 2>/dev/null | wc -l
}

count_dirs () {
  # find -H means follow symlinks on command line but nowhere else.
  echo $(( `find -H "$@" -type d 2>/dev/null | wc -l` - 1 ))
  # originally this was
  #$((`find -H . -path '*.wine/dosdevices' -prune -o -type d 2>/dev/null | wc -l` - 1))
}

count_with_tree () {
  tree -ai "$@" | tail -n 1
}

size () {
  # du -H means follow symlinks on command line but nowhere else.
  # the man page for cut says tab is the default delimiter
  # darwin/OSX no '-b=1' for du
  du -H -s "$@" 2>/dev/null | cut -f 1
  # originally this was
  #du -H -s -I dosdevices "$@" 2>/dev/null | cut -f 1
}

hirarchy_info_function () {
  # redirect all errors to /dev/null
  exec 2>/dev/null
  # need tree to be installed
  which -s tree || return -1
  # summed up info about trees at "$@" (or ".")
  if [ "$1" ]; then
    for file; do
      #darwin/OSX: '512'
      echo "$file:"                \
	`count_with_tree "$file"`, \
	`size -h "$file"`          \
	"($((512*`size "$file"`)))"
    done
    echo
  fi
  #darwin/OSX: '512'
  echo `count_with_tree "$@"`,  \
    `size -ch "$@" | tail -n 1` \
    "($((512*`size -c "$@" | tail -n 1`)))"
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
  sed 's/(/( /g;s/)/ )/g' "$LOGFILE" |        \
    sort -n -t " " -k $POS           |        \
    sed 's/( /(/g;s/ )/)/g'          |        \
    grep --color=always                       \
         --after-context 5                    \
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

# first we collect all the data (this can take a long time)
sizeh=`size -h .`
sizek=`size -k .`
DIR=`count_dirs .`
files=`count_files .`

# do we need the names of the bad files, or only the count?
if $BAD_FILES; then
  # we need the names
  BAD_FILES=`find_bad_files .`
  count=`echo "$BAD_FILES" | wc -l`
  if [ -z "$BAD_FILES" ]; then count=0; fi
else
  # only the count
  count=`find_bad_files . | wc -l`
  BAD_FILES=
fi

# give the old statistics for comparison
tail "$LOGFILE" 2>/dev/null

# echo data to $OUTPUT
echo `LANG=en date '+%F %T (%a)'`: \
  $DIR directories,                \
  $files files,                    \
  $sizeh \($sizek\),               \
  $count bad filenames. |          \
  tee -a "$OUTPUT"

# print bad filenames if asked.
if [ "$BAD_FILES" ]; then echo; echo "$BAD_FILES"; fi
