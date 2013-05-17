#!/bin/sh

for ARG; do

DATE=`exiftool -createdate "$ARG" | \
  sed -n '/Create Date *: [0-9: ]\{19\}/{s/[^0-9]//g;s/..$/.&/;p;}'`
touch -t $DATE "$ARG"

done
