#!/bin/sh

size=.webl
quiet=
background=
view=false
url=http://www.tagesschau.de/export/video-podcast/tagesschau/

usage () {
  local prog="`basename "$0"`"
  echo "Usage: $prog [ -s | -m | -l ] [ -q ] [ -b ] [ -v ] [ -x ]"
  echo "       $prog -h"
}

help () {
  echo This will download the latest Tagesschau from www.tagesschau.de.
}

options () {
  echo "Options:"
  echo "-s, -m, -l  size to download"
  echo "-q          supress output"
  echo "-b          work in background"
  echo "-v          open file after downloading"
  echo "-x          debugging output"
}

load () {
  # find the right file to download online
  url=`load_to_pipe $url | \
    sed -n '/<enclosure url/{
              s/<enclosure url="\([^"]*\)" length.*\/>/\1/p
	      q
	    }'`
  url=${url%.h264.mp4}${size}.h264.mp4
  # go to final download directory
  load_to_file $quiet $url
}

view () {
  # open the video after downloading it.
  case `uname` in
    Darwin) open --background "`basename "$url"`";;
    *) echo "Not implemente yet!" >&2; exit 1;;
  esac
}

# Select command to run or bail out.  If wget can be found we use it,
# otherwise we look for curl.  If both are not available we exit.
if which -s wget; then
  load_to_pipe () { wget --quiet --output-document=- "$@"; }
  load_to_file () { wget --no-verbose --continue "$@"; }
  quiet_switch=--quiet
elif which -s curl; then
  load_to_pipe () { curl --silent "$@"; }
  load_to_file () { curl --remote-name --continue-at - "$@"; }
  quiet_switch=--silent
elif which -s elinks; then
  echo "Warning: Using elinks(1) which doesn't support continueing of" \
    "partial downloads." >&2
  load_to_pipe () { elinks -source "$1"; }
  load_to_file () { elinks -source "$1" > "`basename "$1"`"; }
  quiet_switch=
else
  echo "Can not find wget/curl/elinks.  Stop."
  exit 127
fi

# give help on commandline
while getopts bhlmqsvx FLAG; do
  case $FLAG in
    b) background='&';;
    h) help; usage; options; exit;;
    l) size=.webl;;
    m) size=.webm;;
    q) quiet=$quiet_switch;;
    s) size=;;
    v) view=true;;
    x) set -x;;
    *) usage >&2; exit 2;;
  esac
done

# load the file
cd $HOME/Desktop || cd $HOME/tmp || cd
#eval if load; then if $view; then view; fi; fi $background
eval "( load && $view && view )" $background

exit 0

##############################################################################
# old stuff and notes
#sed -n '/^<item>$/,${s/<enclosure url="\([^"]*\)" length.*\/>/\1/p;}'
#file.hans| head -1
#http://www.tagesschau.de/export/video-podcast/webl/tagesschau/
#http://www.tagesschau.de/export/video-podcast/webm/tagesschau/
#http://www.tagesschau.de/export/video-podcast/tagesschau/

##URL=`$load_to_pipe http://www.tagesschau.de/download/podcast/ | \
##  sed -n '/tagesschau 20:00/,${/mp4/{s/.*href="//;s/".*//p;q;};}'`
###sed -n '/tagesschau 20:00/,${/mp4/{s/.*href="//;s/h264.*/webm.ogv/p;q;};}'`
