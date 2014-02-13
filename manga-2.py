#!/usr/bin/env python

# Introduction: {{{1
# This script can download images from different manga hosting sites on the
# internet.  The user provides the url by which one would read the first page
# of the manga (or the first page he wants to read).  The script will parse
# the URL and if it knows the provider will start to download the image
# embedged into the page.  Then it will download the next page, parse the html
# code and download the next image.  And then so on until the last page of the
# last available chapter is reached.  By default the images are saved to the
# current working directory and a list of the URLs used is written to a file
# "./manga.log".  This and some other things can be configured via command
# line switches.

#from urllib import urlopen
import urllib
import os
import sys
#import lxml
#import argparse
import getopt
import re

# Options: {{{1
# Command line options are:
# -c <arc>   cat the logfile inside the archive file <arc>
# -d <dir>   working directory, defaults to `.'
# -f <log>   log file, defaults to `.'
# -h         give help on command line (calls `help_function')
# -j <job>   do <job> (for debugging)
# -r         resume where the logfile ends
# -x         set the shell options `-x' for the executing shell (debuggin) 
# -q         be quiet, don't print any messages (usefull for running in the
#            background)
# -a         automatic mode: find a working dir and fork to the background

# some variables
### constants {{{2
##PROG=`basename "$0"`
##WGET_OPTION=--no-verbose
##CURL_OPTION='--write-out "Done: %{url_effective}"'
##START="Started '$PROG${@:+ $@}' at `date '+%F %H:%M:%S'`"
##
### variables/options {{{2
##LOGFILE=manga.log
##RESUME=false
##JOB=all
##QUIET=false
##MANGADIR=${MANGADIR:-~/manga}
##VIEW=false
##AUTOMODE=false
##BACKGOUND=
logfile = "manga.log"
resume = False
job = "all"
quiet = False
mangadir = os.getenv("MANGADIR")
if mangadir == None or mangadir == "":
    mangadir = os.path.join(os.getenv("HOME"), "manga")
view = False
automode = False
background = False
directory = "./."

# functions: {{{1

def cleanup_on_interrupt (signal):
    # a function to be called when a signal is caught.
    pass

def find_working_directory ():
    #find_working_directory () { #{{{2
    #  # a function to set the variable DIR and cd there.
    #  if [ "$DIR" ]; then
    #    #if [[ $DIR != */* ]]; then DIR=$MANGADIR/$DIR; fi
    #    if echo "$DIR" | grep -v "/" >/dev/null 2>&1; then
    #      DIR=$MANGADIR/$DIR
    #    fi
    #    if mkdir -p "$DIR"; then
    #      cd "$DIR"
    #    else
    #      exit -1
    #    fi
    #    if ! $QUIET; then
    #      echo "Working in $PWD"
    #    fi
    #  fi
    #}
    if os.path.exists(directory):
        if not os.path.isdir(directory):
            print "Error"
            sys.exit(1)
    else:
        os.mkdir(directory)
    os.chdir(directory)

def help ():
    #help_function () { #{{{2
    #  # a function to display general help for this program
    #  echo "usage: $PROG [ -xq ] [ -d dir | -f log ] URL"
    #  echo "       $PROG -r [ -d dir | -f log ]"
    #  echo "       $PROG [ -f log ] -c archive"
    #  echo dir defaults to \`.a\' and log defaults to \`manga.log\'
    #  echo normal behavior is to load the images starting with the one embedged \
    #    in URL
    #  echo -r will resume from a logfile \(i.e. if new chapters where published\)
    #  echo -c will cat the logfile inside an archive \(not very sufisticated\)
    #}
    usage()
    print "help"

def usage ():
    prog = os.path.basename(sys.argv[0])
    print "Usage: " + prog + " options"
#urlopen("http://mangareader.com")




def find_initial_url ():
    #find_initial_url () { #{{{2
    #  # a function to set the variable URL to an initial value. Uses $1
    #  if $RESUME; then
    #    URL=`tail -n 1 "$LOGFILE"`
    #    URL=${URL%% *}
    #  else
    #    URL="$1"
    #  fi
    #  if [ -z "$URL" ]; then
    #    echo "No URL given. Try '$PROG -h' for help."
    #    exit 1
    #  fi
    #}
    pass

def fork_to_background ():
    #fork_to_background () { #{{{2
    #  # a function to fork to the background. The arguments are passed through.
    #  exec sh -c "$0 -q $@ &"
    #}
    pass


def view_function ():
    #view_function () { #{{{2
    #  # a function to rename the image files in a directory and create a html file
    #  # to display them all.
    #  # TODO: test rename command with mult line command
    #  rename -n 's/([^0-9])([0-9]{1})([^0-9])/${1}00$2$3/g
    #	     s/([^0-9])([0-9]{2})([^0-9])/${1}0$2$3/g' *
    #  #rename -n 's/([^0-9])([0-9]{2})([^0-9])/${1}0$2$3/g' *
    #  printf %s 'Do you want to rename these? (y|N) '
    #  read
    #  if [ "$REPLY" = y -o "$REPLY" = Y ]; then
    #    rename 's/([^0-9])([0-9]{1})([^0-9])/${1}00$2$3/g
    #	    s/([^0-9])([0-9]{2})([^0-9])/${1}0$2$3/g' *
    #    #rename 's/([^0-9])([0-9]{1})([^0-9])/${1}00$2$3/g' *
    #    #rename 's/([^0-9])([0-9]{2})([^0-9])/${1}0$2$3/g' *
    #  fi
    #  local TMP=`mktemp -t mangaXXXXX`
    #  echo '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
    #	"http://www.w3.org/TR/html4/strict.dtd">
    #	<html>
    #	<head>
    #	<meta http-equiv="content-type" content="text/html; charset=UTF-8">
    #	<title>Manga</title>
    #	</head>
    #	<body>' >> $TMP
    #  ls | \
    #    sed 's#^.*$#<p align="center"><img src="'"$PWD/"'&" alt="&"></p>#' >> $TMP
    #  echo '</body></html>' >> $TMP
    #  mv $TMP $TMP.html
    #  # FIXME: this uses an OS X command!
    #  open $TMP.html
    #  rm $TMP.html
    #}
    pass

### side specific functions {{{2
### a function for every known host to fetch the next URL, IMG and FILENAME.
### These functions need $URL to be set to the page which would be viewed in the
### browser. They will set NEXT to the next page that would be viewed in the
### browser (the URL for the next call to themselfs), IMG to the image
### embeddeged into the page and FILE to the filename where the image should be
### saved.
##
### www.mangafox.me {{{3
##get_next_mangafox_me () {
##  # TODO: filenames are to short so chapters overwrite each other.
##  if [ -z "$1" ]; then exit -1 ; fi
##  local TMP=`load_to_pipe "$1"`
##  NEXT=`echo "$TMP" | \
##    sed -n '/return enlarge/{
##        s/.*href="\([^"]*\)".*src="\([^"]*\)".*/\1 \2/p
##      }'`
##  # NEXT should now contain two fields. The first field might be just a
##  # relative path.
##  IMG=${NEXT#* }
##  FILE=${1#http://mangafox.me/manga/}
##  FILE=`echo $FILE | sed 's#/#_#g'`
##  FILE=${FILE%.html}.${IMG##*.}
##  FILE=${FILE##*/}
##  if [ "${NEXT%% *}" = "javascript:void(0);" ]; then
##    NEXT=`echo "$TMP" | \
##      sed -n '/Next Chapter:/{s/.*href="\([^"]*\)".*/\1/p;}'`
##  elif [ "$NEXT" = "" ]; then
##    return 1
##  else
##    NEXT=${1%/*}/${NEXT%% *}
##  fi
##  return 0
##}
##
### www.mangareader.net {{{3
##get_next_www_mangareader_net () {
##  NEXT=`load_to_pipe "$1" | \
##    sed -n '/imgholder/{
##	N
##	s/.*href="\([^"]*\)".*src="\([^"]*\)".*alt="\([^"]*\)".*/\2"\1"\3/p
##	q
##      }'`
##  IMG=${NEXT%%\"*}
##  FILE="${NEXT##*\"}.${IMG##*.}"
##  NEXT=${NEXT#*\"}
##  NEXT=http://www.mangareader.net${NEXT%\"*}
##  if [ "$IMG" ]; then return 0; else return 1; fi
##}
##
### www.manga.animea.net {{{3
##get_next_manga_animea_net () { #TODO test w/o array
##  #eval LINE=(`load_to_pipe "$URL" | sed -n '/imagelink/{s/ /%20/g;s/.*href="\([^"]*\)".*src="\([^"]*\)".*/\1 \2/;p;}'`)
##  LINE=`load_to_pipe "$1" | \
##    sed -n '/imagelink/{
##	s/ /%20/g
##	s/.*href="\([^"]*\)".*src="\([^"]*\)".*/\1 \2/
##	p
##      }'`
##  #IMG=${LINE[1]}
##  IMG=${LINE#* }
##  FILE="${1%%.html}.${IMG##*.}"
##  FILE=${FILE##*/}
##  #NEXT=${LINE[0]}
##  NEXT=${LINE% *}
##  #if [ ${#LINE[@]} -eq 2 ]; then return 0; else return 1; fi
##  if [ "$IMG" ] && [ "$NEXT" ]; then return 0; else return 1; fi
##}
##
### www.homeunix.com {{{3
##get_next_read_homeunix_com () {
##  if [ -z "$1" ]; then return 1; fi
##  LINE=`load_to_pipe "$URL" | \
##    grep "document.write.*\(IMG ALT\)\|\(NEXT CHAPTER\)"`
##  IMG=`echo "$LINE" | \
##    sed -n '/SRC/{;s/.*SRC="\([^"]*\).*/\1/;s/ /%20/g;p;}'`
##  #if [[ "$LINE" = *NEXT\ CHAPTER* ]]; then
##  if echo "$LINE" | grep "NEXT CHAPTER" >/dev/null 2>&1; then
##    NEXT=`echo "$LINE" | \
##      sed -n '/NEXT CHAPTER/{
##	  s#.*href ="\([^"]*\).*#http://read.homeunix.com/onlinereading/\1#
##	  s/ /%20/g
##	  p
##        }'`
##  else
##    NEXT=`echo "$LINE" | \
##      sed -n '/IMG ALT/{s/.*href ="\([^"]*\)".*/\1/;s/ /%20/g;p;}'`
##  fi
##  #FIXME: What filename to use?
##  FILE=$((++i)).${IMG##*.}
##  return 0
##}

## TODO ##
# I want to use generators

class downloader:
    # TODO
    def __init__(self, url, filename):
        if os.path.exists(filename):
            size = os.path.getsize(filename)
            pass
        #else:
        #    urllib.urlretrieve(url, filename=filename)
        urllib.urlretrieve(url, filename=filename)

class www_mangareader_net:
    protocol = "http"
    domain = 'www.mangareader.net'
    manga = ''
    chapter = 0
    page = 0

    def __init__ (self, url):
        if check_url(url):
            self.manga = url[len(base):]

    def find_next_chapter(page):
        marker = False
        for lines in page:
            if '<span class="chapternav_next">Next Chapter:</span>' in line:
                marker = True
                continue
            if marker:
                return line

    def is_the_end(page):
        return not "chapternav_next" in page


    def get_pages_of_chapter(chap):
        count = 0
        page = urllib.urlopen(base + manga + "/" + chap)
        # maybe we can use a html/xml parser to get a saver result
        for line in page.readlines():
            if "<option" in line and "</option>" in line:
                count = count + 1
        return count

    def check_url(url):
        return base in url[:len(base)]

    def parse_url(url):
        if url[:len(protocol)+3] == protocol + '://':
            url = url[len(protocol)+3:]
        if url == None or url == "":
            return False
        if url[:len(domain)] == domain:
            url = url[len(domain):]
        if url == None or url == "":
            return False
        #split(url, '/')
        
        pass

def mangareader_short_and_ugly(start):
    regex = r'.*href="([^"]*)".*src="([^"]*)".*alt="([^"]*)".*'
    page = urllib.urlopen(start)
    img = ""
    url = ""
    filename = ""
    found = False
    while True:
        for line in page.readlines():
            if "imgholder" in line:
                s = re.sub(regex, r'\1 \2 \3', line)
                print s
                url, img, filename = s.split(' ', 2)
                filename = re.sub('\n', '', filename)
                found = True
                break
        if found:
            urllib.urlretrieve(img,filename + ".jpg")
            page = urllib.urlopen("http://www.mangareader.net" + url)
            found = False
        else:
            return
            



# functions for the actual jobs {{{2

def all_function():
    #all_function () { #{{{3
    #  # load urls and images
    #  while $GET_NEXT "$URL"; do
    #    load_to_file "$IMG" "$FILE" & 
    #    #wget $WGET_OPTION --output-document="$FILE" "$IMG" &
    #    echo "$URL $IMG" >> "$LOGFILE"
    #    URL=$NEXT
    #    unset NEXT
    #  done
    #}
    pass

def preload_function():
    #preload_function () { #{{{3
    #  # load all image urls but no images
    #  while $GET_NEXT "$URL"; do
    #    echo "$URL $IMG" >> "$LOGFILE"
    #    echo "Currently loading $URL"
    #    URL=$NEXT
    #    unset NEXT
    #  done
    #}
    pass

def img_function():
    #img_function () { #{{{3
    #  while read URL IMG; do
    #    #TODO
    #    #echo "Not implemented yet!" >&2
    #    #exit -1
    #    echo "URL=$URL"
    #    echo "IMG=$IMG"
    #  done < "$LOGFILE"
    #}
    pass

def new_function():
    #new_function () { #{{{3
    #  # check for new manga online
    #  if [ -r $MANGADIR/mangalist.csv ]; then
    #    echo 
    #  else
    #    echo 
    #  fi
    #}
    pass

def end_message():
    #end_message () { #{{{2
    #  # display a short message just before the program exits
    #  if ! $QUIET; then
    #    wait
    #    echo "$START"
    #    date +"%F %H:%M:%S finished. Exiting ..."
    #  fi
    #}
    pass

## parsing commandline options: {{{1
## after 300 lines of code :)
#while getopts abc:d:f:hj:nqrvx FLAG; do
#  case $FLAG in
#    a) AUTOMODE=true;;
#    b) BACKGOUND='&';;
#    c) tar --wildcards -xOf "$OPTARG" "*/$LOGFILE"; exit;;
#    d) DIR=$OPTARG;;
#    f) LOGFILE=`basename "${OPTARG}"`; DIR=`dirname "${OPTARG}"`;;
#    h) help_function; exit 1;;
#    j) JOB=$OPTARG;;
#    n) JOB=new;;
#    q) WGET_OPTION=--quiet CURL_OPTION=--silent QUIET=true;;
#    r) RESUME=true;;
#    v) VIEW=true;;
#    x) set -x;;
#    \?) exit 43;;
#  esac
#done
#shift $((OPTIND-1))
shortopt = 'abc:d:f:hj:nqrvx'
longopt = [ \
        'archive=',    \
        'auto',        \
        'background',  \
        'debug',       \
        'directory=',  \
        'help',        \
        'logfile=',    \
        'quiet',       \
        'resume',      \
        'view',        \
        ]
try:
    opts, args = getopt.getopt(sys.argv[1:], shortopt, longopt)
except getopt.GetoptError as err:
    print str(err)
    usage()
    sys.exit(2)
for o, a in opts:
    if   o == '-a' or o == '--auto':
        pass
    elif o == '-b' or o == '--background':
        pass
    elif o == '-c' or o == '--archive':
        pass
    elif o == '-d' or o == '--directory':
        if os.sep in a:
            directory = a
        else:
            directory = os.path.join(mangadir, a)
    elif o == '-f' or o == '--logfile':
        f = os.path.basename(a)
        d = os.path.dirname(a)
        d, f = os.path.split(a)
        pass
    elif o == '-h' or o == '--help':
        help()
        sys.exit(0)
    elif o == '-j':
        pass
    elif o == '-n':
        pass
    elif o == '-q' or o == '--quiet':
        pass
    elif o == '-v' or o == '--view':
        pass
    elif o == '-x':
        pass

find_working_directory()
print os.path.realpath( os.path.curdir)
mangareader_short_and_ugly(args[0])

# preparation: {{{1
#find_working_directory
#
#if $VIEW; then
#  view_function
#  exit
#else
#  find_initial_url "$1"
#  GET_NEXT=${URL#http://}
#  GET_NEXT=${GET_NEXT%%/*}
#  GET_NEXT=get_next_${GET_NEXT//./_}
#  if $RESUME; then $GET_NEXT "$URL"; URL=$NEXT; unset NEXT; fi
#fi
#
#
## work: {{{1
#case $JOB in
#  all|preload|img|new) CMD=${JOB}_function;;
#  *) echo "Not a valid job name!"; exit 1;;
#esac
#
#eval '(' $CMD ';' end_message ')' $BACKGOUND