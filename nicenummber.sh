#!/bin/sh

# i counld try to write a perl program to do this

# name of the rename executable (sometimes it is perl-rename)
rename=
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
if ! find_rename; then
  echo Can not find the correct rename executable.
  exit 1
fi

perl -we '
  use strict;
  use List::Util qw(max);
  use File::Which;
  use Getopt::Std;
  sub usage {
    my $prog = "nicenummber.sh";
    (my $msg = <<EOF) =~ s/^\s+//gm;
      $prog [-fnqvx] pattern [file ...]"
      $prog [-fnqvx] -p pattern [file ...]"
      $prog -h"
      The pattern must contain one #, where the numbers are."
      Unless -f is given no renaming is done"
      There must be a string before and after the hash symbol for this"
      program to work reliably."
EOF
    print $msg;
    # TODO: explain more ...
  }
  my %args;
  my $options = "-n";
  # -x is still mising
  getopts("fhnp:", \%args);
  if ($args{h}) {
    usage;
    exit;
  }
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
