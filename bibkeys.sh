#!/bin/sh
#if [ $# -eq 0 ]; then
  bibtool -f '%-1n(author)%-4d(year)%-T(title)'
#else
#  bibtool -f '%-1n(author)%-4d(year)%-T(title)' "$@"
#fi | iconv -f UTF8 -t LATIN1 | bibtool -r iso2tex | iconv -f LATIN1 -t UTF8 | expand
