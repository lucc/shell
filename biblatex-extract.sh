#!/bin/sh

# ideas from http://tex.stackexchange.com/a/164365/63498

input="$1"
base=`basename "$input" .tex`

for file in tmp1 tmp2 final.bib; do
  if [ -f $file ]; then
    echo "Warning: $file exists, should it be deleted? [Y|n]"
    read -c 1
    if [ "$REPLY" = '' -o "$REPLY" = y -o "$REPLY" = Y ]; then
      rm "$file"
    else
      exit 3
    fi
  fi
done

pdflatex "$input"
biber -m 1 "$base"
sed -n '/\\entry/{s/\\entry{/\\nocite{/;s/}{.*/}/;p;}' "$base.bbl" > tmp1
sed 's/\\begin{document}/\\begin{document}\\input{tmp1}/' "$input" > tmp2

pdflatex tmp2
biber -m 1 tmp2
pdflatex tmp2
# not usefull yet !!!!
biber --output-align --output-indent 2 --output-fieldcase lower --output-format bibtex --output-resolve -O final.bib tmp2.bcf
rm tmp1 tmp2
