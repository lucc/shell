#!/usr/bin/perl -w

use strict;
use List::Util qw(max);
use File::Which;
use File::Basename;
use Devel::Trace;
use Getopt::Std;

sub usage {
  my $prog = basename($0);
  print "$prog [-fnqvx] pattern [file ...]\n";
  print "$prog [-fnqvx] -p pattern [file ...]\n";
  print "$prog -h\n";
  # TODO: explain more ...
}

sub help {
  (my $msg = <<EOF) =~ s/^\s+//gm;
    The pattern must contain one #, where the numbers are.
    Unless -f is given no renaming is done
    There must be a string before and after the hash symbol for this
    program to work reliably.
EOF
  print $msg;
}

sub find_rename {
  for my $rename ("perl-rename", "rename") {
    # TODO: broken
    # test the executable more ...
    if ($rename) {
      continue if (system("$rename --version > /dev/null"));
      if (open($_, "-|", "$rename --version") =~ /from util-linux/) {
	print "found wrong rename: $rename\n";
	continue;
      }
      return $rename;
    }
  }
  die("Can not find the correct rename executable.");
}

sub main {
  my %args;
  my $options = "-n";
  # -v is still mising
  getopts("fhnp:xq", \%args);
  if ($args{x}) {
    Devel::Trace::trace('on');
  }
  if ($args{h}) {
    usage;
    help;
    exit;
  }
  if ($args{f} && ! $args{n}) {
    $options = "";
  }
  if ($args{q}) {
    Devel::Trace::trace('off');
  }
  #my $rename = find_rename;
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
  system($rename, $options, $expr, @files);
}

main;
