#!/bin/zsh
# vim: foldmethod=marker
# description {{{1
#
# a script to convert all music files in the source directory to a uniform
# format, saving them in destination directory
#
# TODO: nice and cpulimit

# variables {{{1
# the name of this program
PROG="`basename "$0"`"
# variable used by traps to stop the script (can be true or false)
CONTINUE=true
# array of directories with music to be converted
SRC=( )
# directory to convert music to
OUT=
# format (file ending) to convert music to
FORMAT=ogg
QUALITY=middle
# merge all input directories into the output directory or create
# subdirectories
MERGE=false
# if possible use color output
if [ -t 1 -a -t 2 ]; then
  COLOR="\033[1m"
  NOCOLOR="\033[m"
else
  COLOR=
  NOCOLOR=
fi

# functions {{{1
# fuctions for user interaction and general script execution {{{2
usage () { # {{{3
  echo "$PROG src target"
  echo "Convert all music files in src to ogg files into target."
}

die () { # {{{3
  ret=$1
  shift
  echo "$PROG: $@" >&2
  exit $ret
}

die_optarg () { # {{{3
  die 2 The option $1 needs an argument.
}

handle_signal () { # {{{3
  if $CONTINUE; then
    TIMESTAMP=`date +%s`
    CONTINUE=false
    echo "Let me just finish converting $file ..." >&2
  elif [ $(($TIMESTAMP + 10)) -lt `date +%s` ]; then
    echo 'OK, if you force me.  Engines STOP!' >&2
    exit 10
  fi
}

# filesystem interaction {{{2
resolve_symlinks () { # {{{3
  file="$1"
  while [ -l "$file" ]; do
    file="`readlink "$file"`"
  done
  echo "$file"
}

# conversion functions {{{2
ffmpeg_wrapper () { # {{{3
  ffmpeg              \
    -n                \
    -nostdin          \
    -loglevel warning \
    "$@"
  # -loglevel quiet   \
  # -loglevel panic   \
  # -loglevel fatal   \
  # -loglevel error   \
  # -loglevel warning \
  # -loglevel info    \
  # -loglevel verbose \
  # -loglevel debug
}

to_ogg () { # {{{3
  # TODO quality
  ffmpeg_wrapper       \
    -i "$1"            \
    -codec:a libvorbis \
    -f ogg             \
    "${2%.ogg}.ogg"
}

to_mp3 () { # {{{3
  # TODO quality
  ffmpeg_wrapper       \
    -i "$1"            \
    -f mp3             \
    "${2%.mp3}.mp3"
}

parse_options () { # {{{2
  while [ $# -ne 0 ]; do
    case "$1" in
      -h|--help)
	usage
	exit
	;;
      -i|--input|--src)
	if [ $# -ge 2 ]; then
	  SRC=("${SRC[@]}" "$2")
	  shift 2
	else
	  die_optarg $1
	fi
	;;
      -o|--output)
	if [ $# -ge 2 ]; then
	  OUT="$2"
	  shift 2
	else
	  die_optarg $1
	fi
	;;
      -q|--quality)
	if [ $# -ge 2 ]; then
	  QUALITY="$2"
	  shift 2
	else
	  die_optarg $1
	fi
	;;
      -f|--format)
	if [ $# -ge 2 ]; then
	  FORMAT="$2"
	  shift 2
	else
	  die_optarg $1
	fi
	;;
      -m|--merge)
	MERGE=true
	;;
      -*)
	die 2 "Unknown option '$1'.  If you want the filename use './$1'."
	;;
      *)
	# from here on out no more options are accepted.
	while [ $# -ne 0 ]; do
	  if [[ "$1" = /* ]]; then
	    SRC=("${SRC[@]}" "$1")
	  else
	    SRC=("${SRC[@]}" "./$1")
	  fi
	  shift
	done
	;;
    esac
  done
}

# check for correctly set variables {{{2
check_vars () {
  if [ -z "$OUT" ] && [ ${#SRC} -ge 2 ]; then
    OUT="${SRC[-1]}"
    SRC="${SRC[0,-2]}"
  else
    die 2 You need to specify at least one input and output path.
  fi
}

# check input and output directories for permissions {{{2
check_dirs () {
  # TODO: Does this work correctly?
  if mkdir -p "$OUT"; then
    ( cd "$OUT" || die 3 Can not cd to "$OUT". )
    dest="`cd "$OUT" && pwd -P`"
  else
    die 3 Can not use "$OUT" as output directory.
  fi
  for dir in "${SRC[@]}"; do
    if [ -d "$dir" ] && [ -r "$dir" ]; then
      continue
      # TODO This does not work with multible input dirs.
      # change to the source directory to be able to work with relative filenames
      #cd "$src" || die 3 Can not cd to "$src".
    else
      die 2 "$dir" is not a readable directory.
    fi
  done
}

# main function {{{2
main () {
  for srcdir in "${SRC[@]}"; do
    if ! $MERGE; then
      currdest="$dest/`basename "$srcdir"`"
    else
      currdest="$dest"
    fi
    find "$srcdir" -type f | LC_ALL=C sort --ignore-case | \
	while read -r file && $CONTINUE; do
      ##  TODO TODO
      target="$dest/${file%.*}.$FORMAT"
      printf "\nconverting $COLOR$file$NOCOLOR ..."
      if [ "$target" -nt "$file" ]; then
	echo " $target is newer.  Skipping."
      else
	echo
	mkdir -p "`dirname "$target"`"
	to_ogg "$file" "$target"
      fi
    done
  done
}

# run {{{1
parse_options $@
check_vars
check_dirs

trap handle_signal SIGINT SIGQUIT
main
trap - SIGINT SIGQUIT
