#!/bin/sh

# i counld try to write a perl program to do this

options=-n
pattern=
# name of the rename executable (sometimes it is perl-rename)
rename=

usage () {
  # print usage information for the user
  local prog="`basename "$0"`"
  echo "$prog [-fnqvx] pattern [file ...]"
  echo "$prog [-fnqvx] -p pattern [file ...]"
  echo "$prog -h"
  echo "The pattern must contain one #, where the numbers are."
  echo "Unless -f is given no renaming is done"
  echo "There must be a string before and after the hash symbol for this"
  echo "program to work reliably."
  echo TODO: explain more ...
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
  # Print the perl expresion used for renameing.
  perl -we '
    use strict;
    use List::Util qw(max);
    my $pattern = shift;
    die("No pattern given.") if (! $pattern);
    die("Pattern does not contain a # character.") if ! ($pattern =~ /#/);
    my ($re1, $re2) = split("#", $pattern); # split the pattern at the "#" char
    my $max = max(map { /.*?$re1(\d+)$re2.*/; length $1 } glob("*"));
    my $expr = "";
    for (my $i = 1; $i < $max; $i++) {
      $expr .= "s/$re1(\\d{$i})$re2/${re1}0\$1$re2/;";
    }
    print $expr' -- "$@"
}

if ! find_rename; then
  echo Can not find the correct rename executable.
  exit 1
fi

# parse the command line
while getopts fhnp:x FLAG; do
  case $FLAG in
    f) options=;;
    h) usage; exit;;
    n) options=-n;;
    p) pattern="$OPTARG";;
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
if [ $# -eq 0 ]; then
  set -- *
fi
perl_expr=`prepare_perl_expresion "$pattern"` || exit 1
$rename $options "$perl_expr" "$@"
