#!/usr/bin/awk -f

# we require the user to set two variables on the command line with the -v
# option. "path" should be set to the path we are looking for. 

## gloabl variables
# now		the current time. This is set on command line and only read.
# list
# dx
# typ
# i
#

function frecent(rank, time) {
  dx = now - time
  if (dx < 3600) return rank * 4
  if (dx < 86400) return rank * 2
  if (dx < 604800) return rank / 2
  return rank / 4
}

function output(files, toopen, override) {
  if (list) {
    if (typ == "recent") {
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
    # is short surely false at this moment?
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

BEGIN {
  FS = "|"
  SUBSEP = " "
  datafile = ENVIRON[_Z_DATA] ? ENVIRON[_Z_DATA] : (ENVIRON[HOME] "/.z")

  # bail out if we don't own ~/.z (we're another user but our ENV is still set)
  if (!system("%s %s %s %s", "test -f", datafile, "-a ! -O", datafile)) exit

  ind = 1

  # add entries
  if (ARGV[ind] == "--add") { # nummber one
    ind += 1
    # and define a function for the behaviour.
  

    # The rest of ARGV should contain the string to look for.
    path = ""
    for ( ; ind < ARGC; ind++) path = path ARGV[ind]


    # $HOME isn't worth matching
    if (ENVIRON[HOME] == path) exit;

    # maintain the file
    tempfile = "";
    result = "";
    cmd = "mktemp " datafile ".XXXXXX";
    while ( ( cmd | getline result ) > 0 ) {
      tempfile = tempfile result;
    } 
    close(cmd);

    #tempfile="$(mktemp $datafile.XXXXXX)" || return
    #awk -v path="$*" -v now="$(date +%s)" -F"|" '
    path = ARGV[ind];
    cmd = "date +%s";
    now = "";
    result = "";
    while ( (cmd|getline result) > 0 ) {
      now = now result;
    }
    close(cmd)

    rank[path] = 1
    time[path] = now

    function every_line(line) {
      $2 >= 1 {
	if( $1 == path ) {
	  rank[$1] = $2 + 1
	  time[$1] = now
	} else {
	  rank[$1] = $2
	  time[$1] = $3
	}
	count += $2
      }
    }


   # ' "$datafile" 2>/dev/null >| "$tempfile"


  } # end of nummber one (--add)




  # tab completion
  else if (ARGV[ind] == "--complete") { # nummber two
#  awk -v q="$2" -F"|" '
#   BEGIN {
#    if( q == tolower(q) ) nocase = 1
#    split(substr(q,3),fnd," ")
#   }
#   {
#    if( system("test -d \"" $1 "\"") ) next
#    if( nocase ) {
#     for( i in fnd ) tolower($1) !~ tolower(fnd[i]) && $1 = ""
#    } else {
#     for( i in fnd ) $1 !~ fnd[i] && $1 = ""
#    }
#    if( $1 ) print $1
#   }
#  ' "$datafile" 2>/dev/null

    # luc
    q = ARGV[ind+1]


    #original
    if( q == tolower(q) ) nocase = 1
    # split q at spaces and create array fnd from it
    split(substr(q,3),fnd," ")
    #luc:uses global 'nocase' and 'fnd'
    function every_line(line) {
      if( system("test -d \"" $1 "\"") ) next                    
      if( nocase ) {                                             
       for( i in fnd ) tolower($1) !~ tolower(fnd[i]) && $1 = "" 
      } else {                                                   
       for( i in fnd ) $1 !~ fnd[i] && $1 = ""                   
      }                                                          
      if( $1 ) print $1                                          
    }

  } # end of nummber two (--complete)
  else
  ## END OF REVISED CODE   ##########################################################

#  # list/go
#  while [ "$1" ]; do case "$1" in
#   -h) echo "z [-h][-l][-r][-t] args" >&2; return;;
#   -l) local list=1;;
#   -r) local typ="rank";;
#   -t) local typ="recent";;
#   --) while [ "$1" ]; do shift; local fnd="$fnd $1";done;;
#    *) local fnd="$fnd $1";;
#  esac; local last=$1; shift; done
#  [ "$fnd" ] || local list=1
#
#  # if we hit enter on a completion just go there
#  case "$last" in
#   # completions will always start with /
#   /*) [ -z "$list" -a -d "$last" ] && cd "$last" && return;;
#  esac
#
#  # no file yet
#  [ -f "$datafile" ] || return
#
#  local cd
#  cd="$(awk -v t="$(date +%s)" -v list="$list" -v typ="$typ" -v q="$fnd" -F"|" '
#   function frecent(rank, time) {
#    dx = t-time
#    if( dx < 3600 ) return rank*4
#    if( dx < 86400 ) return rank*2
#    if( dx < 604800 ) return rank/2
#    return rank/4
#   }
#   function output(files, toopen, override) {
#    if( list ) {
#     if( typ == "recent" ) {
#      cmd = "sort -nr >&2"
#     } else cmd = "sort -n >&2"
#     for( i in files ) if( files[i] ) printf "%-10s %s\n", files[i], i | cmd
#     if( override ) printf "%-10s %s\n", "common:", override > "/dev/stderr"
#    } else {
#     if( override ) toopen = override
#     print toopen
#    }
#   }
#   function common(matches) {
#    # shortest match
#    for( i in matches ) {
#     if( matches[i] && (!short || length(i) < length(short)) ) short = i
#    }
#    if( short == "/" ) return
#    # shortest match must be common to each match
#    for( i in matches ) if( matches[i] && i !~ short ) return
#    return short
#   }
#   BEGIN { split(q, a, " ") }
#   {
#    if( system("test -d \"" $1 "\"") ) next
#    if( typ == "rank" ) {
#     f = $2
#    } else if( typ == "recent" ) {
#     f = t-$3
#    } else f = frecent($2, $3)
#    wcase[$1] = nocase[$1] = f
#    for( i in a ) {
#     if( $1 !~ a[i] ) delete wcase[$1]
#     if( tolower($1) !~ tolower(a[i]) ) delete nocase[$1]
#    }
#    if( wcase[$1] > oldf ) {
#     cx = $1
#     oldf = wcase[$1]
#    } else if( nocase[$1] > noldf ) {
#     ncx = $1
#     noldf = nocase[$1]
#    }
#   }
#   END {
#    if( cx ) {
#     output(wcase, cx, common(wcase))
#    } else if( ncx ) output(nocase, ncx, common(nocase))
#   }
#  ' "$datafile")"
#  [ $? -gt 0 ] && return
#  [ "$cd" ] && cd "$cd"
# fi




END { # --add
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
