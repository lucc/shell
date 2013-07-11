#!/bin/sh


office2 () {
  # find path to LO
  local lo=
  if [ `uname` = Darwin ]; then
    lo=/Applications/LibreOffice.app/Contents/MacOS/swriter
  else
    lo=libreoffice
  fi
  type="$1"
  shift
  "$lo"                  \
    --nologo             \
    --nodefault          \
    --nolockcheck        \
    --nofirststartwizard \
    --convert-to "$type" \
    --outdir ./          \
    "$@"
}

office2pdf () { office2 pdf      "$@"; }
office2tex () { office2 tex      "$@"; }
office2txt () { office2 txt:Text "$@"; }

if [ -z "$PS1" ]; then
  echo source "$0"
else
  echo office2pdf
  echo office2tex
  echo office2txt
  echo office_to
fi
