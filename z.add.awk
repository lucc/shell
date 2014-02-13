#!/usr/bin/awk -f

#awk -v path="$*" -v now="$(date +%s)" -F"|" '


BEGIN {
  FS= "|"
  if (ARGV[1] == "--add") {
    "date +%%s" | getline now
    # The rest of ARGV should contain the string to look for.
    path = ""
    for (ind = 2; ind < ARGC; ind++) path = path ARGV[ind]
    rank[path] = 1
    time[path] = now
  }
}


$2 >= 1 {
  if ($1 == path) {
    rank[$1] = $2 + 1
    time[$1] = now
  } else {
    rank[$1] = $2
    time[$1] = $3
  }
  count += $2
}

END {
  if (count > 1000) {
    for (i in rank) {
      print i "|" 0.9*rank[i] "|" time[i] # aging
    }
  } else {
    for (i in rank) {
      print i "|" rank[i] "|" time[i]
    }
  }
}

