#!/usr/bin/env python3

# A little script to search with different online search engines from the
# commandline.
#
# Author: luc
# Thanks:
# * This script is based on an idea of johnraff @ crunchbanglinux.org/forums
#   see http://crunchbanglinux.org/forums/post/87022/#p87022
#
# dependencies:
# xsel, firefox, lynx, elinks
#
# TODO list
# add options to urls

import webbrowser
import urllib.parse
import base64


class Searcher():

    """Class to search a specific site."""

    def __init__(self, interface=None):
        """TODO: to be defined1.

        :interface:
        """
        pass

    def _query(self, *query):
        """TODO: Docstring for _query.

        :*query: TODO
        :returns: TODO

        """
        return '+'.join(['"{}"'.format(q) if ' ' in q else q for q in query])

    def search(self, *query):
        """Make a search with the given query strings."""
        webbrowser.open(self.base+self._query(*query))


class Duckduckgo(Searcher): base='https://duckduckgo.com/?q='
class Google(Searcher): _base = 'http://www.google.{}/search?q='
class Googlecom(Searcher): base = _base.format('com')
class Googlede(Searcher): base = _base.format('de')
class Leoorg(Searcher): base = 'http://dict.leo.org/ende?search='
class Wikipedia(Searcher): _base = 'http://{}.wikipedia.org/w/index.php?fulltext=Search&search='
class Wikipediade(Searcher): base = _base.format('de')
class Wikipediaen(Searcher): base = _base.format('en')
class Youtube(Searcher): base='http://www.youtube.com/results?search_query='

class Commandlinefu(Searcher):
    base = 'http://www.commandlinefu.com/commands/matching/'
    def _query(self, *query):
        """TODO: Docstring for _query.

        :*query: TODO
        :returns: TODO

        """
        q = super()._query(*query)
        q += '/' + base64.b64encode(q) + '/'
        q += 'plaintext' if self.interface == 'text' else 'sort-by-votes'
        return q


class MVV(Searcher):

    """Docstring for MVV. """

    base='http://www.mvv-muenchen.de/de/fahrplanauskunft/index.html'

    def _query(self, start, destination, time=None):
        """TODO: Docstring for _query.

        :returns: TODO

        """
        name_origin=`urlencode "$1"`
        name_destination=`urlencode "$2"`
        echo "$base?name_origin=$name_origin&name_destination=$name_destination"



# helper functions {{{1
urlencode () {
  perl -MURI::Escape -e 'print join("+", map{uri_escape $_}(@ARGV));' "$@"
}

# Preparing the different commands depending on the system. TYPE may be one of
# XORG CLI TEXT
XORG=
CLI=lynx
TEXT='elinks --dump'
FALLBACK='wget --output-document=-'
TYPE=XORG

for CLI in lynx elinks links w3m w3; do
  if which $CLI >/dev/null 2>&1; then
    break
  fi
  CLI=
done
if [ -z $CLI ]; then
  echo 'Error: No command line browser found!' >&2
fi

case `uname` in
  linux|Linux|LINUX) XORG=firefox CLIPBOARD=xsel;;
  Darwin)	     XORG=open CLIPBOARD=pbpaste;;
  *)		     TYPE=CLI;; #unknown system. some kind of unix?
esac

help () {
  echo search engines:
  echo '  -d    duckduckgo.com'
  echo '  -f    www.commandlinefu.com'
  echo '  -g    www.google.de'
  echo '  -l    dict.leo.org'
  echo '  -w    de.wikipedia.org'
  echo '  -y    www.youtube.com'
  echo
  echo other options:
  echo '  -c    use a command line browser'
  echo '  -t    display results as text'
  echo '  -x    use a graphical browser'
}

if [ -z "$BASE" ]; then
  echo "Which search engine should be used?" >&2
  exit 1
fi

# Preparing the searchterms and puting them together for the URL.
if [ -z "$SEARCH" ]; then SEARCH=`eval $CLIPBOARD`; fi
if [ -z "$SEARCH" ]; then echo "No search terms."; exit 2; fi



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
  # http://www.commandlinefu.com/commands/view/10813
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
