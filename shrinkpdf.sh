#!/bin/bash
 
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo usage: shrinkpdf \<filename\> \<resolution\> \[\<output\>\]
    exit
fi
 
if [ ! -e "$1" ]; then
    echo "$1" does not exist. Exiting.
    exit
fi
 
if [ $# = 3 ]; then
    NEWNAME=$3
else
    NEWNAME=`basename $1 .pdf`_shrinked.pdf
fi
 
if [ "$1 " = "$NEWNAME " ]; then
    echo Input and output are identical. Won\'t overwrite---exiting.
    exit
fi
 
if [ -e "$NEWNAME" ]; then
    echo "$NEWNAME" exists. Delete? \(y/n\)
    read ANS
    if [ "$ANS " = "y " ]; then
        rm "$NEWNAME"
    else
        exit
    fi
fi
 
gs    -q -dNOPAUSE -dBATCH -dSAFER \
-name=true \
    -sDEVICE=pdfwrite \
    -dCompatibilityLevel=1.3 \
    -dPDFSETTINGS=/screen \
    -dEmbedAllFonts=true \
    -dSubsetFonts=true \
    -dColorImageDownsampleType=/Bicubic \
    -dColorImageResolution=$2 \
    -dGrayImageDownsampleType=/Bicubic \
    -dGrayImageResolution=$2 \
    -dMonoImageDownsampleType=/Bicubic \
    -dMonoImageResolution=$2 \
    -sOutputFile="$NEWNAME" \
     "$1"

