#!/bin/zsh

inputdir=$1
outputfile=$2

function sed-function-1 () {
  sed -E '
  /Metadata/,/Duration: .*start.*bitrate/!d
  /^  Metadata:$/d
  /Duration.*start.*bitrate.*$/d
  s/^ +([[:alnum:]]+) +:/\1=/'
}

for file in $inputdir/**/*(.); do
  ffprobe $file |& sed-function-1 | while read -r key value; do
    echo -n $key \"
    echo -n $value | sed -E 's/\\/\\\\/g;s/"/\\"/g'
    echo -n '" '
  done
  echo
done
