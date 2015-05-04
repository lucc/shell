#!/bin/zsh
# vim: foldmethod=marker
# description {{{1
#
# a script to convert all music files in the source directory to a uniform
# format, saving them in destination directory
#
# TODO: nice and cpulimit
# TODO: quality specification
# TODO: format/filetype filter to ignore cover.jpg ...
# TODO: format/filetype filter to inhibit mp3 -> flac conversion ...
# TODO: time reporting with the times builtin
# TODO: other converters? lame, oggencode, ...
# TODO: use cp for no conversion (which checks are to made?)

# variables {{{1
# the name of this program
PROG=$(basename $0)
# variable used by traps to stop the script (can be true or false)
CONTINUE=true
# array of directories with music to be converted
typeset -a SRC
# directory to convert music to
OUT=
# format (file ending) to convert music to
FORMAT=ogg
QUALITY=middle
# merge all input directories into the output directory or create
# subdirectories
MERGE=false
# if possible use color output
if [[ -t 1 && -t 2 ]]; then
  COLOR="\033[1m"
  NOCOLOR="\033[m"
else
  COLOR=
  NOCOLOR=
fi

# functions {{{1
# fuctions for user interaction and general script execution {{{2
usage () { # {{{3
  echo $PROG src target
  echo Convert all music files in src to ogg files into target.
}

die () { # {{{3
  ret=$1
  shift
  echo $PROG: $@ >&2
  exit $ret
}

handle_signal () { # {{{3
  if $CONTINUE; then
    TIMESTAMP=$(date +%s)
    CONTINUE=false
    echo Let me just finish converting $file ... >&2
  elif [[ $(($TIMESTAMP + 10)) -lt $(date +%s) ]]; then
    echo 'OK, if you force me.  Engines STOP!' >&2
    exit 10
  else
    echo Let me just finish converting $file ... >&2
  fi
}

# filesystem interaction {{{2
resolve_symlinks () { # {{{3
  file=$1
  while [[ -l $file ]]; do
    file=$(readlink $file)
  done
  echo $file
}

# conversion functions {{{2
ffmpeg_wrapper () { # {{{3
  ffmpeg              \
    -n                \
    -nostdin          \
    -loglevel warning \
    $@
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
    -i $1              \
    -codec:a libvorbis \
    -f ogg             \
    ${2%.ogg}.ogg
}

to_mp3 () { # {{{3
  # TODO quality
  ffmpeg_wrapper       \
    -i $1              \
    -f mp3             \
    ${2%.mp3}.mp3
}

parse_options () { # {{{2
  # parse command line: getopt
  opts=$(getopt \
    --options hs:o:q:f:m \
    --longoptions help,src:,source:,out:,output:,quality:,format:,merge \
    --name $PROG \
    -- $@)
  local err=$?
  eval set -- $opts
  # parse command line: read the options
  while [[ $# -ne 0 ]]; do
    case $1 in
      -h|--help) usage; exit;;
      -s|--src|--source) SRC+=$2; shift 2;;
      -o|--out|--output) OUT=$2; shift 2;;
      -q|--quality) QUALITY=$2; shift 2;;
      -f|--format) FORMAT=$2; shift 2;;
      -m|--merge) MERGE=true;;
      --) shift; break;;
    esac
  done
  if [[ $#SRC -eq 0 || -z $OUT ]]; then
    die 2 You need to specify at least one input and output path.
  fi
}

check_dirs () { # {{{2
  # check input and output directories for permissions
  # TODO: Does this work correctly?
  if mkdir -p $OUT; then
    ( cd $OUT || die 3 Can not cd to $OUT. )
    dest=$(cd $OUT && pwd -P)
  else
    die 3 Can not use $OUT as output directory.
  fi
  for dir in $SRC; do
    if [[ -d $dir ]] && [[ -r $dir ]]; then
      continue
      # TODO This does not work with multible input dirs.
      # change to the source directory to be able to work with relative filenames
      #cd "$src" || die 3 Can not cd to "$src".
    else
      die 2 $dir is not a readable directory.
    fi
  done
}

main () { # {{{2
  for srcdir in $SRC; do
    if ! $MERGE; then
      currdest=$dest/$(basename $srcdir)
    else
      currdest=$dest
    fi
    find $srcdir -type f | LC_ALL=C sort --ignore-case | \
	while read -r file && $CONTINUE; do
      ##  TODO TODO
      target=$dest/${file%.*}.$FORMAT
      printf "\nconverting $COLOR$file$NOCOLOR ..."
      if [[ $target -nt $file ]]; then
	echo " $target is newer.  Skipping."
      else
	echo
	mkdir -p $(dirname $target)
	to_ogg $file $target
      fi
    done
  done
}

# run {{{1
parse_options $@
check_dirs

trap handle_signal SIGINT SIGQUIT
main
trap - SIGINT SIGQUIT
