#!/usr/bin/env bash

# Add a DANCE value to the vorbis comments of a flac file.
# Call with -h for help.

set -euo pipefail

help () {
  echo "Usage: $prog [-cnx] -d dance [file.flac [...]]"
  echo "       $prog [-cnx] dance [file.flac [...]]"
  echo "Add a DANCE= value to the vorbis comments of file.flac"
  echo "(or the current song of mpd(1) with -c)."
  echo "Options:"
  echo "  -n do not actually write to file, just print"
  echo "  -x activate debugging output (like sh -x)"
  echo "  -c add the current song from mpd(1) to list of files"
  echo "  -d specify the dance value to be added"
  echo "Either -c or at least one filename must be given. All files must"
  echo "be flac files."
}

# print a canonicalized dance name
fix_dance_name () {
  #case `echo "$1"|sed -E 's/[ _.:,;-]+/-/g;s/.*/\L&/'` in
  case $(echo "$1" | sed -E 's/[[:punct:]]+//g' | tr '[:upper:]' '[:lower:]') in
    chacha|chachacha|cha)
      echo Cha-Cha;;
    blues)
      echo Blues;;
    boogie)
      echo Boogie;;
    dicofox|df)
      echo Discofox;;
    foxtrott|ft)
      echo Foxtrott;;
    jive)
      echo Jive;;
    quickstep|qs)
      echo Quickstep;;
    rumba)
      echo Rumba;;
    salsa)
      echo Salsa;;
    samba)
      echo Samba;;
    slowfox|sf)
      echo Slow-Fox;;
    tango)
      echo Tango;;
    walzer|waltz|slowwaltz|langsamerwalzer|lw)
      echo Slow-Waltz;;
    wiener|viennese|viennesewaltz|ww)
      echo Viennese-Waltz;;
    *)
      echo Unknown dance. >&2
      return 1
      ;;
  esac
}

# print the filename of the current song from mpd
mpd_current () {
  local conf dir file
  if [ -r "$HOME"/.mpdconf ]; then
    conf=$HOME/.mpdconf
  elif [ -r "$HOME"/.mpd/mpd.conf ]; then
    conf=$HOME/.mpd/mpd.conf
  else
    return 1
  fi
  dir=$(sed -n '/music_directory/{s/.*"\(.*\)"/\1/;s#\~#'"$HOME"'#;p;}' "$conf")
  file=$(mpc --format %file% current)
  echo "$dir/$file"
}

beet_interface () {
  # The song query is in $@ the dance value in $dance.
  beet modify --nowrite --yes "$@" dance="$dance"
}

# parse command line options
prog=$(basename "$0")
dance=
just_print=
while getopts cd:hnvx FLAG; do
  case $FLAG in
    c) additional=$(mpd_current) || exit 3;;
    d) dance=$(fix_dance_name "$OPTARG") || exit 2;;
    h) help; exit;;
    n) just_print=echo;;
    v) metaflac --block-type=VORBIS_COMMENT --list "$(mpd_current)" && exit;;
    x) set -x;;
    *) echo help >&2; exit 2;;
  esac
done
shift $((OPTIND-1))

if [ -z "$dance" ]; then
  dance=$(fix_dance_name "$1") || exit 2
  shift
fi

# write the dance to the files
$just_print \
metaflac --set-tag=DANCE="$dance" "$@" "$additional"
metaflac --block-type=VORBIS_COMMENT --list "$@" "$additional"
