#!/bin/sh

# i counld try to write a perl program to do this

options=-n
pattern=
# name of the rename executable (sometimes it is perl-rename)
rename=
regex=false

usage () {
  # print usage information for the user
  local prog="`basename "$0"`"
  echo "$prog [-fnqrsvx] pattern [file ...]"
  echo "$prog [-fnqrsvx] -p pattern [file ...]"
  echo "$prog -h"
  echo "The pattern must contain one #, where the numbers are."
  echo "Unless -f is given no renaming is done"
  echo "There must be a string before and after the hash symbol for this"
  echo "program to work reliably."
  echo TODO: explain more ...
}
die () {
  # exit with an error message and an error code
  local ret="$1"
  shift
  echo "$@" >&2
  exit "$ret"
}
find_rename () {
  # find the correct rename executable
  for rename in perl-rename rename; do
    if $rename --version >/dev/null && \
	$rename --version | grep -qv 'from util-linux'; then
      return
    fi
  done
  rename=
  return 1
}
prepare_perl_expresion () {
  # Print the perl expresion used for renameing.  $1 and $2 are the parts of
  # the pattern given by the user, on stdin is the list of files.
  perl -we '
    use List::Util qw(max);
    my ($re1, $re2) = split("#", shift); # split the pattern at the "#" char
    my $max = max(map { /.*?$re1(\d+)$re2.*/; length $1 } <>);
    for (my $i = 1; $i < $max; $i++) {
      print "s/$re1(\\d{$i})$re2/${re1}0\$1$re2/;";
    }' -- "$@"
}

if ! find_rename; then
  die 1 Can not find the correct rename executable.
fi

# parse the command line
while getopts fhnp:qrsvx FLAG; do
  case $FLAG in
    f) options=;;
    h) usage; exit;;
    n) options=-n;;
    p) pattern="$OPTARG";;
    q) quiet=true;;
    r) regex=true;;
    s) regex=false;;
    v) quiet=false;;
    x) set -x;;
    *) usage; exit 2;;
  esac
done
# remove options from command line
shift $(($OPTIND-1))
# check that a pattern can be used
if [ -z "$pattern" ]; then
  pattern="$1"
  shift
fi
if [ -z "$pattern" ]; then
  die 2 No pattern given.
fi
if echo "$pattern" | grep -qv \#; then
  die 2 Pattern does not contain a \# character.
fi

perl_expr=`ls | prepare_perl_expresion "$pattern"`
$rename $options "$perl_expr" "$@"
