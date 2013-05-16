#! /bin/bash
# FIXME: /bin/bash needed for [[ $x = *\ * ]] and ${!x}

# CREDIT #####################################################################
# This script is based on an idea of johnraff @ crunchbanglinux.org/forums see
# http://crunchbanglinux.org/forums/post/87022/#p87022
# this version by luc
#
# DEPENDENCIES ###############################################################
# xsel, firefox, lynx, elinks
#
# TODO #######################################################################
# add options to urls
#

# urls
CMDFU='http://www.commandlinefu.com/commands/matching/'
DUCKDUCKGO='https://duckduckgo.com/?q='
GOOGLE='http://www.google.de/search?q='
LEO='http://dict.leo.org/ende?search='
WIKI='http://de.wikipedia.org/w/index.php?fulltext=Search&search='
WIKIEN='http://en.wikipedia.org/w/index.php?fulltext=Search&search='
YOUTUBE='http://www.youtube.com/results?search_query='


# Preparing the different commands depending on the system. TYPE may be one of
# XORG CLI TEXT
XORG=
CLI=lynx
TEXT='elinks --dump'
FALLBACK='wget --output-document=-'
TYPE=XORG

case `uname` in
  linux|Linux|LINUX) XORG=firefox CLIPBOARD=xsel;;
  Darwin)	     XORG=open CLIPBOARD=pbpaste;;
  *)		     TYPE=CLI;; #unknown system. some kind of unix?
esac

while getopts cdfgltwxy FLAG; do
  case $FLAG in
    # general options
    h) help; exit;;
    # type options
    c) TYPE=CLI;;
    t) TYPE=TEXT;;
    x) TYPE=XORG;;
    # search engine options
    d) BASE="$DUCKDUCKGO";;
    f) BASE="$CMDFU";;
    g) BASE="$GOOGLE";;
    l) BASE="$LEO";;
    w) BASE="$WIKI";;
    y) BASE="$YOUTUBE";;
  esac
  #OPTIONS=??
done
shift $((OPTIND-1))
if [ -z "$BASE" ]; then
  echo "Which search engine should be used?" >&2
  exit 1
fi

# Preparing the searchterms and puting them together for the URL.
if [[ "$1" = *\ * ]]; then SEARCH="\"$1\""; else SEARCH="$1"; fi
shift
for TERM in "$@"; do
  if [[ "$TERM" = *\ * ]]; then
    SEARCH="$SEARCH+\"$TERM\""
  else
    SEARCH="$SEARCH+$TERM"
  fi
done
if [ -z "$SEARCH" ]; then SEARCH=`eval $CLIPBOARD`; fi
if [ -z "$SEARCH" ]; then echo "No search terms."; exit 2; fi
if [[ "$BASE" = *commandlinefu* ]]; then
  SEARCH+="/`echo -n "$SEARCH" | openssl base64`"
  TEXT="wget --quiet -O -"
  if [ $TYPE = TEXT ]; then OPTIONS=/plaintext
  else OPTIONS=/sort-by-votes
  fi
fi

# Execute the search. Pick the specified method for it.
COMMAND=${!TYPE}
${COMMAND} "${BASE}${SEARCH}${OPTIONS}"
exit



#######  VERSION 1.0 by johnraff@crunchbanglinux.org/forums  ############

#!/bin/bash
# g.sh google search on inputted string
# needs xsel to read from clipboard

# edit to taste:
REGULAR_BROWSER=firefox
QUICK_BROWSER=dillo

#############################################

if [[ -n "$1" ]] # get input from command line or clipboard, put in array
then
     terms=("$@")
else
     terms=($(xsel))
fi

for i in ${!terms[@]} # put back quotes
do
    [[ ${terms[$i]} = *\ * ]] && terms[$i]=\"${terms[$i]}\"
done

SEARCH="${terms[*]}"
SEARCH=$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$SEARCH") # from: http://stackoverflow.com/questions/296536/urlencode-from-a-bash-script

if pgrep $REGULAR_BROWSER >/dev/null
then
    BROWSER=$REGULAR_BROWSER
else
    BROWSER=$QUICK_BROWSER
fi

# Feel free to change the google request string if you know what those options do...
# The "#res" at the end skips the stuff at the top of the page and takes you straight to the search results.
$BROWSER "http://www.google.co.jp/search?as_q=${SEARCH}&num=25&hl=en&btnG=Google+Search&as_qdr=all&as_occt=any&safe=off#res"
exit

##############################  SOME OLD FUNCTIONS  ##########################
cmdfu () {
  if [ -z "$1" ]; then
    echo "Give an arguemnt." 1>&2
    return 2
  fi
  local search
  search="http://www.commandlinefu.com/commands/matching/$@/"
  search="$search`echo -n "$@" | openssl base64`/plaintext"
  wget --quiet -O - "$search"
}

wiki () {
  dig +short txt $1.wp.dg.cx
}

yt () {
  # from:
  # http://www.commandlinefu.com/commands/view/6689/stream-youtube-url-directly-to-mplayer 
  mplayer -fs -quiet $(youtube-dl -g "$1")
}

dict() {
  # from:
  # http://www.commandlinefu.com/commands/view/1884/look-up-the-definition-of-a-word
  #curl dict://dict.org/d:$1
  curl -s dict://dict.org/d:$1 | \
    perl -ne 's/\r//; last if /^\.$/; print if /^151/../^250/'
}
urlencode () {
  # ideas from
  # http://stackoverflow.com/questions/296536/urlencode-from-a-bash-script
  # encode the argument to be used in search urls.
  #perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$@"
  perl -MURI::Escape -e 'print join("+", map{uri_escape $_}(@ARGV));' "$@"
}
