#!/bin/bash
# access translate.google.com from terminal
# credits: johnraff@crunchbanglinux.org/forums
# see: http://crunchbang.org/forums/viewtopic.php?pid=176917#p176917

# adjust to taste
DEFAULT_TARGET_LANG=en

help () {
  echo 'translate <text> [[<source language>] <target language>]'
  echo 'if target missing, use DEFAULT_TARGET_LANG'
  echo 'if source missing, use auto'
}

querry () {
  # $1 -> text to translate
  # $2 -> source language (can be auto)
  # $3 -> target language
  curl \
    --silent        \
    --include       \
    --user-agent '' \
    -d "sl=$2"      \
    -d "tl=$3"      \
    --data-urlencode "text=$1" \
    http://translate.google.com
}

find_encoding () {
  awk \
    '/Content-Type: .* charset=/ {
       sub(/^.*charset=["'\'']?/,"");
       sub(/[ "'\''].*$/,"");
       print
     }'
}

extrct_result () {
  # $1 -> the encoding of the input
  iconv -f $1 | \
    awk \
      'BEGIN {RS="</div>"};
       /<span[^>]* id=["'\'']?result_box["'\'']?/' | \
    html2text -utf8
}

if [[ $1 = -h || $1 = --help ]]; then
  help
  exit
fi

if [[ $3 ]]; then
    source="$2"
    target="$3"
elif [[ $2 ]]; then
    source=auto
    target="$2"
else
    source=auto
    target="$DEFAULT_TARGET_LANG"
fi

result=$(querry "$1" "$source" "$target")
encoding=$(find_encoding <<<"$result")
#iconv -f $encoding <<<"$result" | awk 'BEGIN {RS="<div"};/<span[^>]* id=["'\'']?result_box["'\'']?/ {sub(/^.*id=["'\'']?result_box["'\'']?(>| [^>]*>)([ \n\t]*<[^>]*>)*/,"");sub(/<.*$/,"");print}' | html2text -utf8
echo "$result" | extrct_result $encoding
exit
