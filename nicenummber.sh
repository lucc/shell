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
    use File::Which;
    use Getopt::Std;
    my %args;
    my $options = "-n";
    getopts("fnp:", \%args);
    if ($args{f} && ! $args{n}) {
      $options = "";
    }
    my $rename = which("perl-rename", "rename");
    # TODO test rename program ...
    my $pattern = $args{p};
    die("No pattern given.") if (! $pattern);
    die("Pattern does not contain a # character.") if ! ($pattern =~ /#/);
    my ($re1, $re2) = split("#", $pattern); # split the pattern at the "#" char
    my $max = max(map { /.*?$re1(\d+)$re2.*/; length $1 } glob("*"));
    my $expr = "";
    for (my $i = 1; $i < $max; $i++) {
      $expr .= "s/$re1(\\d{$i})$re2/${re1}0\$1$re2/;";
    }
    my @files = @ARGV || glob("*"); # TODO
    system($rename, "-n", $expr, @files);
    ' -- "$@"
}

if ! find_rename; then
  echo Can not find the correct rename executable.
  exit 1
fi

# parse the command line
#while getopts hx FLAG; do
#  case $FLAG in
#    h) usage; exit;;
#    x) set -x;;
#    *) usage; exit 2;;
#  esac
#done
## remove options from command line
#shift $(($OPTIND-1))
prepare_perl_expresion "$@"
