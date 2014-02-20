#!/usr/bin/awk -f

# cd="$(awk -v now="$(date +%s)" -v list="$list" -v typ="$typ" -v q="$fnd" -F"|" '

function frecent(rank, time) {
  dx = now-time
  if( dx < 3600 ) return rank*4
  if( dx < 86400 ) return rank*2
  if( dx < 604800 ) return rank/2
  return rank/4
}
function output(files, toopen, override) {
  if( list ) {
    if( typ == "recent" ) {
      cmd = "sort -nr >&2"
    } else {
      cmd = "sort -n >&2"
    }
    for (i in files) {
      if (files[i]) printf "%-10s %s\n", files[i], i | cmd
    }
    if (override) {
      printf "%-10s %s\n", "common:", override > "/dev/stderr"
    }
  } else {
    if (override) toopen = override
    print toopen
  }
}
function common(matches) {
  # shortest match
  for( i in matches ) {
    if( matches[i] && (!short || length(i) < length(short)) ) short = i
  }
  if( short == "/" ) return
  # shortest match must be common to each match
  for( i in matches ) if( matches[i] && i !~ short ) return
  return short
}

BEGIN { 
  "date +%s" | getline now
  FS="|"
  split(q, a, " ")
}

{
  if (system("test -d \"" $1 "\"")) next
  if (typ == "rank") {
    f = $2
  } else {
    if( typ == "recent" ) {
      f = now-$3
    } else {
      f = frecent($2, $3)
    }
  }
  wcase[$1] = nocase[$1] = f
  for (i in a) {
    if ($1 !~ a[i]) delete wcase[$1]
    if (tolower($1) !~ tolower(a[i])) delete nocase[$1]
  }
  if (wcase[$1] > oldf) {
    cx = $1
    oldf = wcase[$1]
  } else {
    if( nocase[$1] > noldf ) {
      ncx = $1
      noldf = nocase[$1]
    }
  }
}

END {
  if( cx ) {
    output(wcase, cx, common(wcase))
  } else if( ncx ) output(nocase, ncx, common(nocase))
}
