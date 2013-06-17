#!/bin/sh

# Add a DANCE value to the vorbis comments of a flac file.
# Call with -h for help.


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
  case `echo "$1"|sed -E 's/[ _-.:,;]+/-/g;s/.*/\L&/'` in
    chacha|chachacha|cha|cha-cha|cha-cha-cha) echo Cha-Cha;;
    dicofox|disco-fox)                        echo Discofox;;
    foxtrott|fox-trott)                       echo Foxtrott;;
    jive)                                     echo Jive;;
    quickstep)                                echo Quickstep;;
    rumba)                                    echo Rumba;;
    salsa)                                    echo Salsa;;
    samba)                                    echo Samba;;
    slowfox|slow-fox)                         echo Slow-Fox;;
    tango)                                    echo Tango;;
    walzer|waltz|slow-waltz|langsamer-walzer) echo Slow-Waltz;;
    wiener|viennese|viennese-waltz)           echo Viennese-Waltz;;
    *)
      echo Unknown dance. >&2
      return 1
      ;;
  esac
}

# print the filename of the current song from mpd
mpd_current () {
  local conf dir file
  if [ -r $HOME/.mpdconf ]; then
    conf=$HOME/.mpdconf
  elif [ -r $HOME/.mpd/mpd.conf ]; then
    conf=$HOME/.mpd/mpd.conf
  else
    return 1
  fi
  dir="`sed -n '/music_directory/{s/.*"\(.*\)"/\1/;s#\~#'$HOME'#;p;}' $conf`"
  file="`mpc --format %file% current`"
  echo "$dir/$file"
}

# parse command line options
prog=`basename "$0"`
dance=
while getopts cd:hnx FLAG; do
  case $FLAG in
    c) additional="`mpd_current`" || exit 3;;
    d) dance=`fix_dance_name "$OPTARG"` || exit 2;;
    h) help; exit;;
    n) just_print=echo;;
    x) set -x;;
  esac
done
shift $((OPTIND-1))

if [ -z "$dance" ]; then
  dance=`fix_dance_name "$1"` || exit 2
  shift
fi

# write the dance to the files
$just_print \
metaflac --set-tag=DANCE=$dance "$@" "$additional"
metaflac --block-type=VORBIS_COMMENT --list "$@" "$additional"
