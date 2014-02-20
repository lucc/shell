#!/usr/bin/awk -f

#awk -v q="$2" -F"|" '

BEGIN {
  FS="|"
  if (ARGV[1] == "--complete") {
    # The rest of ARGV should contain the string to look for.
    q = ""
    for (ind = 2; ind < ARGC; ind++) q = q ARGV[ind]
  }
  if (q == tolower(q)) nocase = 1
  split(substr(q, 3), fnd, " ")
}

{ # all lines
  if (system("test -d \"" $1 "\"")) next
  if (nocase) {
    for (i in fnd) tolower($1) !~ tolower(fnd[i]) && $1 = ""
  } else {
    for (i in fnd) $1 !~ fnd[i] && $1 = ""
  }
  if ($1) print $1
}
