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
  perl -ne '
    BEGIN{
      use Getopt::Std;
      my $maximum = 0;
      getopts("r:", \%args) or die("Command line error.");
      #print "Got $args{r} for -r.";
      #if ($args{r} == "") {
      #  die("Need a regex with -r");
      #}
      our ($re1, $re2) = split("#", $args{r});
      #print "$re1\n";
      #print "$re2\n";
    }
    chomp; # remove newline
    s/.*?$re1(\d+)$re2.*/$1/; # TODO "@" or "$"?
    $maximum = length if length > $maximum;
    END{
      for (my $i = 1; $i < $maximum; $i++) {
	print "s/$re1(\\d{$i})$re2/${re1}0\$1$re2/;";
      }
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
# split the pattern at the # character
pre="${pattern%%#*}"
post="${pattern##*#}"
# escape pattern for use as a regex and find files to work on
if $regex; then
  pre_re="$pre"
  post_re="$post"
  if [ $# -eq 0 ]; then
    set -- *
  fi
else
  pre_re="\\Q$pre\\E"
  post_re="\\Q$post\\E"
  if [ $# -eq 0 ]; then
    set -- *$pre*$post*
  fi
fi

#n=`ls -d "$@" 2>/dev/null | prepare_perl_expresion "$pre_re" "$post_re"`
perl_expr=`ls -d "$@" 2>/dev/null | prepare_perl_expresion -r "$pattern"`
#  perl -ne 'BEGIN{ my $maximum = 0 };
#	    chomp; # remove newline
#	    s/.*?'"$pre_re"'(\d+)'"$post_re"'.*/$1/;
#	    $maximum = length if length > $maximum;
#	    END{ print $maximum }'`

#for ((i = 1; i < n; i++)); do
#  perl_expr="${perl_expr}s/$pre_re(\\d{$i})$post_re/${pre_re}0\$1$post_re/;"
#done
$rename $options "$perl_expr" "$@"
