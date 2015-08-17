#!/usr/bin/env python3

'''Script to normalize bib files and snippets.'''

import argparse
import os
import urllib.request
import tempfile
import subprocess

# script to manage .bib files.  This script uses bibtool.  The official
# homepage is
HOMEPAGE = 'http://www.gerd-neugebauer.de/software/TeX/BibTool'
# documentation:
DOCURL = 'http://www.gerd-neugebauer.de/software/TeX/BibTool/bibtool.pdf'

def resource_file():
    resource = '''
               fmt.name.title = "."
               key.format = {
                 {
                   %-2n(author)
                 # %-2n(editor)
                 }
                 {
                   %s($fmt.name.title) %-1T(title)
                 # %s($fmt.name.title) %-1T(booktitle)
                 #
                 }
               }
               #
               {
                 {
                   %s($fmt.name.title) %-1T(title)
                 # %s($fmt.name.title) %-1T(booktitle)
                 }
               }
               # %s($default.key)
               '''
    tmp = tempfile.NamedTemporaryFile(delete=False)
    tmp.write(resource)
    tmp.close()
    return tmp.name

def help():
    filename = '~/doc/bibtool.pdf'
    url = DOCURL
    if not os.path.exists(filename):
        urllib.request.urlretrieve(url, filename)
    subprocess.call(['open', filename])

def sort_bibs():
    subprocess.call(
            ['bibtool',
                '-s',
                '--', 'sort.format="%N(author)"',
                '--', 'sort.format="%N(editor)"',
                ...])

def keygen():
    subprocess.call(['bibtool', '-r', resource, ...])
    os.unlink(resource)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--sort', action='store_true')
    parser.add_argument('-k', '--key', action='store_true')
    parser.add_argument('-f', '--file', default=[], action='append')




#if [ $# -eq 0 ]; then
#  bibtool -f '%-1n(author)%-4d(year)%-T(title)'
#else
#  bibtool -f '%-1n(author)%-4d(year)%-T(title)' "$@"
#fi | iconv -f UTF8 -t LATIN1 | bibtool -r iso2tex | iconv -f LATIN1 -t UTF8 | expand
