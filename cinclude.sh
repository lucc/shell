#!/bin/sh

inclueds=(cctype.cpp cstdlib.cpp fsream.cpp gmp.c iostream.cpp limits.c list.cpp
	  map.cpp signal.c stat.c stdio.c stdlib.c string.cpp time.c utility.cpp
	  vector.cpp)

if [ -z "$1" ]; then echo "Need an argument." 1>&2; exit 2; fi

if [ --what = "$1" ]; then
  shift
  for file; do
    echo
    echo "  $file"
    case "$file" in 
      *.h) echo "#include<$file>" | cc -E -M -x c - | sed '1s/^.*://;s/ \\$//;s/^ *//;y/ /\n/' | sort;;
      *.c) echo "#include\"$file\"" | cc -E -M -x c - | sed '1s/^.*://;s/ \\$//;s/^ *//;y/ /\n/' | sort;;
      *.hpp) echo "#include<$file>" | c++ -E -x c++ -M - | sed '1s/^.*://;s/ \\$//;s/^ *//;y/ /\n/' | sort;;
      *.cpp) echo "#include\"$file\"" | c++ -E -x c++ -M - | sed '1s/^.*://;s/ \\$//;s/^ *//;y/ /\n/' | sort;;
    esac
  done  
elif [ --search = "$1" ]; then
  for file in *.c ; do
    if [ -f "$file" ] ; then
      echo
      echo "  $file"
      cc -E -M -x c "$file" | sed '1s/^.*://;s/ \\$//;s/^ *//;y/ /\n/' | grep --color=auto "$2"
    fi
  done
  for file in *.cpp ; do
    if [ -f "$file" ] ; then
      echo
      echo "  $file";
      c++ -E -M -x c++ "$file" | sed '1s/^.*://;s/ \\$//;s/^ *//;y/ /\n/' | grep --color=auto "$2"
    fi
  done
fi
