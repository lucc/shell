#!/bin/sh

# http://ask.libreoffice.org/en/question/2641/convert-to-command-line-parameter/
# http://ask.libreoffice.org/en/question/1686/how-to-not-connect-to-a-running-instance/

office2 () {
  # find path to LO
  local lo=
  if [ `uname` = Darwin ]; then
    lo=/Applications/LibreOffice.app/Contents/MacOS/soffice
  else
    lo=libreoffice
  fi
  type="$1"
  shift
  "$lo"                                                      \
    --nologo                                                 \
    --nodefault                                              \
    --nolockcheck                                            \
    --nofirststartwizard                                     \
    -env:UserInstallation=file:///tmp/LibO_Conversion$RANDOM \
    --convert-to "$type"                                     \
    --outdir ./                                              \
    "$@"
}

office2pdf_2 () { office2 pdf:writer_pdf_Export "$@"; }

if [ -z "$PS1" ]; then
  echo source "$0"
else
  office2csv () { office2 csv      "$@"; }; echo office2csv
  office2ods () { office2 ods      "$@"; }; echo office2ods
  office2odt () { office2 odt      "$@"; }; echo office2odt
  office2pdf () { office2 pdf      "$@"; }; echo office2pdf
  office2tex () { office2 tex      "$@"; }; echo office2tex
  office2txt () { office2 txt:Text "$@"; }; echo office2txt
fi
