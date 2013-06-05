#!/bin/sh

libreoffice_to () {
  # find path to LO
  if [ `uname` = Darwin ]; then
    lo= /Applications/LibreOffice.app/Contents/
  else
    lo=libreoffice
  fi
  type="$1"
  dir="$2"
  shift 2
  $lo \
    --nologo \
    --nodefault \
    --nolockcheck \
    --nofirststartwizard \
    --convert-to "$type" \
    --outdir "$dir" \
    "$@"
}

libreoffice2txt () {
  # dir ?
  dir=.
  # shift ?
  libreoffice_to txt:Text "$dir" "$@"
}

libreoffice2pdf () {
  # dir ?
  dir=.
  # shift ?
  libreoffice_to pdf "$dir" "$@"
}
