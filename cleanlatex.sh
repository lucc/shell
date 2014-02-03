#!/bin/sh
if [ "$1" = -h ] || [ "$1" = --help ]; then
  echo "usage: `basename $0` [ -bor ] [ directory ]"
  echo "List/remove intermediate/output LaTeX/BibTex files."
  exit
fi
BIB=false
OUT=false
REM=false
while getopts bor OPT; do
  case "$OPT" in
    b) BIB=true;;
    o) OUT=true;;
    r) REM=true;;
    *) echo "Try `basename $0` -h" >&2; exit 1;;
  esac
done
shift $((OPTIND-1))
if [ "$1" ]; then
  if [ -d "$1" ]; then cd "$1"
  else echo "$1 is not a directory." >&2; exit 1
  fi
fi
find . -name "*.tex" -type f | while read line; do
  # default intermediate files
  ls "${line%tex}aux" "${line%tex}log" "${line%tex}out" "${line%tex}toc"
  # bibtex files
  if $BIB; then ls "${line%tex}bbl" "${line%tex}blg"; fi
  # output files
  if $OUT; then ls "${line%tex}dvi" "${line%tex}pdf"; fi
done 2>/dev/null | if $REM; then
  cat | while read line; do
    rm "$line"
  done
else
  cat
fi
