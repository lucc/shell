#!/bin/sh

tempdir=`mktemp -d -t XXXXXX`
olddir=`pwd`
inputfile="$1"

pdfseparate "$inputfile" "$tempdir/page-%d.pdf"

cd "$tempdir"

rename 's/(\d)/0$1/;s/(\d\d)/0$1/;s/(\d\d\d)/0$1/' page-*.pdf

for file in page-*.pdf; do
  open --background --new -a PDF\ OCR\ X "$file"
  sleep 2
done

# wait for all instances

pdftk page-*.pdf.searchable.pdf cat output new.pdf

cd "$olddir"
mv "$tempdir/new.pdf" "$inputfile.searchable.pdf"

rm -rf "$tempdir"
