#!/usr/bin/env python3
# vim: foldmethod=marker

# Introduction: {{{1
# TODO
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

# imports {{{1
import argparse
#import lxml
import os
import re
import sys
import urllib.request, urllib.parse, urllib.error
from bs4 import BeautifulSoup

# variables/options {{{1
#WGET_OPTION=--no-verbose
#CURL_OPTION='--write-out "Done: %{url_effective}"'
#START="Started '$PROG${@:+ $@}' at `date '+%F %H:%M:%S'`"
job = "all"
view = False

class Constants():
    mangadir = os.path.join(os.getenv(("HOME"), "manga"))
    logfile = "manga.log"

# classes {{{1

class SiteLoader(): #{{{2
    directory = None
    logfile = None
    protocol = None
    domain = None
    manga = None
    current_page = None
    # I want to use generators
    def __init__(self, url, directory=None, logfile="manga.log"):
        if directory == None:
            directory = '.'
        self.prepare_output_dir(directory)
        self.logfile = open(os.path.join(self.directory, logfile), 'a')
    def find_manga_name():
        raise NotImplementedError()
    def find_chapter():
        raise NotImplementedError()
    def find_next_page():
        raise NotImplementedError()
    def find_next_chapter():
        raise NotImplementedError()
    def prepare_output_dir(self, string):
        # or should we used a named argument and detect the manga name
        # automatically if it is not given.
        '''Find the correct directory to save output files to and set
        self.directory'''
        mangadir = '.'
        if not os.path.sep in string:
            mangadir = os.getenv("MANGADIR")
            if mangadir == None or mangadir == "":
                mangadir = os.path.join(os.getenv("HOME"), "manga")
            mangadir = os.path.realpath(mangadir)
        self.directory = os.path.realpath(os.path.join(mangadir, string))
        if os.path.exists(self.directory):
            if not os.path.isdir(self.directory):
                raise EnvironmentError("Path exists but is not a directory.")
        else:
            os.mkdir(self.directory)
        #os.chdir(self.directory)
        #if not args.quiet:
        #    print('Working in ' + os.path.realpath(os.path.curdir) + '.')

class ImageLoader: #{{{2
    # TODO
    '''TODO'''
    log = {}
    def __init__(self, url, filename):
        if os.path.exists(filename):
            size = os.path.getsize(filename)
            pass
        #else:
        #    urllib.urlretrieve(url, filename=filename)
        urllib.request.urlretrieve(url, filename=filename)

    def add_download(url, filename):
        log.update({url: filename})
        

    def remove_download(filename, success=True):
        pass

# side specific classes {{{2
class Mangareader(SiteLoader): # {{{3
    '''
    the image is in the <img> tag with id #img 
    the parent <a> tag holds the link to the next page
    the <select> tag with id #pageMenu holds the pages for the current chapter
    '''
    protocol = 'http'
    domain = 'www.mangareader.net'
    manga = ''
    chapter = 0
    page = 0

#    def __init__ (self, url): #{{{4
#        super()

    def parse_page(html): # {{{4
        '''extract the image and next url out of an BeautifulSoup object'''
        try:
            tag = html.find(id="img").parent
            imgurl = tag.img["src"]
            nexturl = tag["href"]
            filename = re.sub(r'[ -]+', '-', tag.img["alt"]).lower() + '.' + \
                    imgurl.split('.')[-1]
        except AttributeError:
            return None, None, None
        return nexturl, imgurl, filename

    def download_all(self, url): # {{{4
        html = BeautifulSoup(urllib.request.urlopen(url))
        nexturl, imgurl, filename = self.parse_page(html)
        while nexturl != None and imgurl != None and filename != None:
            urllib.request.urlretrieve(imgurl, os.path.join(self.directory, \
                    filename))
            nexturl, imgurl, filename = parse_page(html)


    def find_manga_name(parsed_page): # {{{4
        '''parsed_page must be the BeautifulSoup object from the current
        page'''
        return parsed_page.title.string.split()[0].lower()
    def find_chapter(parsed_page): # {{{4
        #for line in parsed_page.find_all("script")[2].string:
        #    if "chapterno" in line:
        #        return int(line.split("=")[1])
        raise NotImplementedError()
    def find_next_chapter(parsed_page): #{{{4
        return int(parsed_page.find(class_="c6").tr.find_all("td")[1].a \
                ['href'].split('/')[-1])
        # old version
        marker = False
        for lines in page:
            if '<span class="chapternav_next">Next Chapter:</span>' in line:
                marker = True
                continue
            if marker:
                return line

    def is_the_end(page): #{{{4
        return not "chapternav_next" in page

    def get_pages_of_chapter(parsed_page): #{{{4
        return len(parsed_page.find(id="pageMenu").find_all("option"))
        # old version
        count = 0
        page = urllib.request.urlopen(base + manga + "/" + chap)
        # maybe we can use a html/xml parser to get a saver result
        for line in page.readlines():
            if "<option" in line and "</option>" in line:
                count = count + 1
        return count

    def check_url(url): #{{{4
        return base in url[:len(base)]

    def parse_url(url): #{{{4
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

    def download(url):
        html = BeautifulSoup(urllib.request.urlopen(url))
        chapter = find_chapter(html)
        pages = get_pages_of_chapter(html)
        while True:
            for p in range(pages):
                pass

            





    # temporary solution
    def short_and_ugly(start): #{{{4
        regex = r'.*href="([^"]*)".*src="([^"]*)".*alt="([^"]*)".*'
        page = urllib.request.urlopen(start)
        img = ""
        url = ""
        filename = ""
        found = False
        while True:
            for line in page.readlines():
                line = str(line, encoding='utf8')
                if "imgholder" in line:
                    s = re.sub(regex, r'\1 \2 \3', line)
                    print(s)
                    url, img, filename = s.split(' ', 2)
                    filename = re.sub('\n', '', filename)
                    found = True
                    break
            if found:
                urllib.request.urlretrieve(img,filename + ".jpg")
                page = urllib.request.urlopen("http://www.mangareader.net" + url)
                found = False
            else:
                return

class Mangafox(SiteLoader): #{{{3
    ### www.mangafox.me
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
    pass


class manga_animea(SiteLoader): # {{{3
    ### www.manga.animea.net {{{4
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
    pass

class homeunix(SiteLoader): # {{{3
    ### www.homeunix.com {{{4
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
    pass

# functions: {{{1

def cleanup_on_interrupt (signal): #{{{2
    # a function to be called when a signal is caught.
    pass


def find_initial_url (): #{{{2
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
    pass

def fork_to_background (): #{{{2
    ## a function to fork to the background. The arguments are passed through.
    #exec sh -c "$0 -q $@ &"
    pass

def view_function (): #{{{2
    #view_function () {
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

def all_function(): #{{{2
    #all_function () { 
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

def preload_function(): #{{{2
    #preload_function () {
    #  # load all image urls but no images
    #  while $GET_NEXT "$URL"; do
    #    echo "$URL $IMG" >> "$LOGFILE"
    #    echo "Currently loading $URL"
    #    URL=$NEXT
    #    unset NEXT
    #  done
    #}
    pass

def img_function(): #{{{2
    #img_function () {
    #  while read URL IMG; do
    #    #TODO
    #    #echo "Not implemented yet!" >&2
    #    #exit -1
    #    echo "URL=$URL"
    #    echo "IMG=$IMG"
    #  done < "$LOGFILE"
    #}
    pass

def new_function(): #{{{2
    #new_function () {
    #  # check for new manga online
    #  if [ -r $MANGADIR/mangalist.csv ]; then
    #    echo 
    #  else
    #    echo 
    #  fi
    #}
    pass

def end_message(): #{{{2
    #end_message () {
    #  # display a short message just before the program exits
    #  if ! $QUIET; then
    #    wait
    #    echo "$START"
    #    date +"%F %H:%M:%S finished. Exiting ..."
    #  fi
    #}
    pass

# parsing the command line {{{1
parser = argparse.ArgumentParser( \
        description="Download manga from some websites.")
### further ideas for the command line:
#######################################
#shortopt = 'abc:d:f:hj:nqrvx'
#longopt = ['archive=', 'debug', 'view']
## die Idee für "archive": tar --wildcards -xOf "$OPTARG" "*/$LOGFILE"
#for o, a in opts:
#    elif o == '-d' or o == '--directory':
#        if os.sep in a:
#            directory = a
#        else:
#            directory = os.path.join(mangadir, a)
#    elif o == '-f' or o == '--logfile':
#        f = os.path.basename(a)
#        d = os.path.dirname(a)
#        d, f = os.path.split(a)
#        pass
parser.add_argument('-a', '--auto', \
        action='store_true', help='do everything automatically')
parser.add_argument('-b', '--background', \
        action='store_true', help='fork to background')
parser.add_argument('-d', '--directory', \
        metavar='DIR', default='.', help='the directory to work in')
parser.add_argument('-f', '--logfile', \
        metavar='LOG', default='manga.log', \
        help='the filename of the logfile to use')
parser.add_argument('-q', '--quiet', \
        dest='quiet', default=False, action='store_true', help='supress output')
parser.add_argument('-v', '--verbose', \
        dest='quiet', default=False, action='store_false', help='verbose output')
parser.add_argument('-r', '--resume', \
        action='store_true', help='resume from a logfile')
parser.add_argument('url', nargs='+')

args = parser.parse_args()
print(args)

# preparation: {{{1
#find_working_directory(args.directory)
#print(os.path.realpath(os.path.curdir))
for url in args.url:
    loader = Mangareader(url, directory=args.directory, logfile=args.logfile)
    loader.download_all(url)

#find_initial_url "$1"
#GET_NEXT=${URL#http://}
#GET_NEXT=${GET_NEXT%%/*}
#GET_NEXT=get_next_${GET_NEXT//./_}
#if $RESUME; then $GET_NEXT "$URL"; URL=$NEXT; unset NEXT; fi

## work: {{{1
#case $JOB in
#  all|preload|img|new) CMD=${JOB}_function;;
#  *) echo "Not a valid job name!"; exit 1;;
#esac
#
#eval '(' $CMD ';' end_message ')' $BACKGOUND

