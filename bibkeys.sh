#!/bin/sh

# script to manage .bib files.

# Some resources files for bibtool.
write_keygen_resource () {
  cat > "$1" <<EOF
    fmt.name.title = "."
    key.format = {
      {
	%-2n(author)
      # %-2n(editor)
      }
      {
	%s($fmt.name.title) %-1T(title)
      # %s($fmt.name.title) %-1T(booktitle)
      #
      }
    }
    #
    {
      {
	%s($fmt.name.title) %-1T(title)
      # %s($fmt.name.title) %-1T(booktitle)
      }
    }
    # %s($default.key)
EOF
}


help () {
  local file=~/doc/bibtool.pdf
  local url=http://www.gerd-neugebauer.de/software/TeX/BibTool/bibtool.pdf
  if [ -r $file ]; then
    open $file
  else
    wget -O $file $url
  fi
}

sort_bibs () {
  bibtool -s                      \
    -- 'sort.format="%N(author)"' \
    -- 'sort.format="%N(editor)"' \
    "$@"
}

keygen () {
  local tmp=$(mktemp -t $(basename "$0").XXXX)
  write_keygen_resource "$tmp"
  bibtool -r "$tmp" "$@"
  rm "$tmp"
}

while getopts h FLAG; do
  case $FLAG in
    h) help;;
  esac
done
exit



#if [ $# -eq 0 ]; then
  bibtool -f '%-1n(author)%-4d(year)%-T(title)'
#else
#  bibtool -f '%-1n(author)%-4d(year)%-T(title)' "$@"
#fi | iconv -f UTF8 -t LATIN1 | bibtool -r iso2tex | iconv -f LATIN1 -t UTF8 | expand
