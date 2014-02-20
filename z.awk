#!/usr/bin/awk -f

# we require the user to set two variables on the command line with the -v
# option. "path" should be set to the path we are looking for. 

function frecent(rank, time) {
  dx = now - time #TODO "now" is not local
  if (dx < 3600) return rank * 4
  if (dx < 86400) return rank * 2
  if (dx < 604800) return rank / 2
  return rank / 4
}

function output(files, toopen, override) {
  if (list) {#TODO "list" ist not local
    if (typ == "recent") {#TODO "typ" ist not local
      cmd = "sort -nr >&2"
    } else {
      cmd = "sort -n >&2"
    }
    for (i in files) {
      if (files[i]) {
        printf "%-10s %s\n", files[i], i | cmd
      }
    }
    if (override) {
      printf "%-10s %s\n", "common:", override > "/dev/stderr"
    }
  } else {
    #better print override ? override : toopen
    if (override) {
      toopen = override
    }
    print toopen
  }
}

function common(matches) {
  # shortest match
  for (i in matches) {
    if (matches[i] && (!short || length(i) < length(short))) {
      short = i
    }
  }
  if (short == "/") {
    return
  }
  # shortest match must be common to each match
  for (i in matches) {
    if (matches[i] && i !~ short) {
      return
    }
  }
  return short
}

function complete_f() { #TODO needs datafile on stdin
  if (system("test -d \"" $1 "\"")) next
  if (nocase) {
    for (i in fnd) tolower($1) !~ tolower(fnd[i]) && $1 = ""
  } else {
    for (i in fnd) $1 !~ fnd[i] && $1 = ""
  }
  if ($1) print $1
}

BEGIN {
  FS = "|"
  SUBSEP = " "
  datafile = ENVIRON[_Z_DATA] ? ENVIRON[_Z_DATA] : (ENVIRON[HOME] "/.z")

  # bail out if we don't own ~/.z (we're another user but our ENV is still set)
  if (!system("%s %s %s %s", "test -f", datafile, "-a ! -O", datafile)) exit 3
  
  i = 1
  if (ARGV[1] == "--add") action = "add"
  else if (ARGV[1] == "--complete") action = "comp"
  else if (ARGV[1] == "--") {
    action = "cd"
    i++
  }
  else action = ""
  for (j = 0; i < ARGC; i++, j++) {
    querry_a[j] = ARGV[i]
    querry_s = querry_s " " ARGV[i]
  }
  querry_s = sub(" ", "", querry_s)
  delete ARGV
  ARGC = 2
  ARGV[1] = datafile

  if (action == "add") {
    rank[querry_s] = 1
    rank[querry_s] = now
  }
  if (action == "comp") {
    if (querry_s == tolower(querry_s)) nocase = 1
    split(substr(querry_s,3), fnd, " ") #TODO what is fnd?
  }
  if (action == "cd") {
    split(querry_s, a, " ")
  }
    


}


END {
  if (action == "add") {
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
  if (action == "complete") {
  }
  if (action == "cd") {
    if (cx) {
     output(wcase, cx, common(wcase))
    } else {
      if (ncx) {
	output(nocase, ncx, common(nocase))
      }
    }
  }
}
