#!/bin/bash

##### AUTHORS #####
# aravinthrk, anonymous, jmbarnes, tunafish, sector11, luc & johnraff
# If you work on this add your name, please.
# Developed at:   http://crunchbanglinux.org/forums/topic/10436/

##### LICENCE #####
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
##
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
##
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

##### DOCUMENTATION #####
# This is a little backup script to copy some files from $HOME to $TARGET_DIR.
# The script has its own index of files to back up at the end, after the
# marker consisting of 35 times '#' then '  EOF  ' and again '#' 35 times.
# After the marker every line contains exactly one filename (no extra
# characters, no need to escape anything). If the filename is relative it is
# assumed to be in $HOME. The script will read itself to get a list of these
# files during run. You can edit the list by hand (make shure to put exactly
# one filename in one line without any additional characters) or you can use
# the -m and -u options to do it from commandline. Try the -h option for help.

##### BUGS #####
# Filenames may not contain newline characters.

##### SET DEFAULT VALUES (YOU MAY EDIT THESE) #####
TARGET_PATH="$HOME/bak"
CP_OPT=-Ra  #see 'man cp' for options
#VERBOSE=-v   #(un)comment to toggle verbose output of either cp or tar
DATE_FMT=%F  #see http://linux.die.net/man/3/strftime for DATE formatting

##### DO NOT EDIT BELOW THIS LINE! #####
# content of this file up to ``## EOF ##''
SCRIPT=$(sed -En '1,/^#{35}  EOF  #{35}$/p' "$0")
# content of this file after ``## EOF ##''
INDEX=$(sed -E '1,/^#{35}  EOF  #{35}$/d' "$0" | \
          while read -r line ; do readlink -f "$line"; done)
COMPRESS=false  #do not compress files by default, use cp
#function to handle errors (not very fancy)
error_exit () {
  echo "Could not create directory. Aborting ..." 1>&2
  exit 1
}

#  if we have arguments we look for options. everything else will be assumed
#+ to be the target dir.
case "$1" in
  -h|--help)   
    echo "Usage: $(basename "$0") [-g | --gzip | -b | --bzip2] [<target dir>]"
    echo "       $(basename "$0") -m | --mark <file> [...]"
    echo "       $(basename "$0") -u | --unmark <file> [...]"
    echo "       $(basename "$0") -h | --help"
    echo ""
    exit ;;
  -m|--mark)
    shift
    if [[ -z $@ && -z $INDEX ]]; then 
      echo "No files listed for backup."
    else
      readlink -f "$@" | sort -u - <(echo "$INDEX") | sed 's,^'$HOME'/,,' | \
        cat <(echo "$SCRIPT") - > "$0"
    fi
    exit ;;
  -u|--unmark)
    shift
    grep -xvF "$(readlink -f "$@")" <<<"${INDEX}" | sed 's,^'$HOME'/,,' | \
      cat <(echo "$SCRIPT") - > "$0"
    exit ;;
  -g|--gzip)
    echo "Compressing data with gzip ..."
    COMPRESS=-z  # the gzip option for tar
    EXT=gz       # the file extension
    shift ;;
  -b|--bzip2)
    echo "Compressing data with bzip2 ..."
    COMPRESS=-j  # the bzip2 option for tar
    EXT=bz2      # file extension
    shift ;;
esac
if [[ $1 ]]; then TARGET="$1" ; fi # did the user specify a terget dir?

if [[ $INDEX ]]; then # are any files listed for backup?
  unset FILES
  while read -r line; do
    FILES=("${FILES[@]}" $(readlink -f "$line"))
  done <<<"$INDEX"
else
  echo "No files listed for backup. You can add some wit the -m option."
  echo "Type \`\`$(basename "$0") --help'' for help."
  exit 1
fi

#  set the target from $TARGET_PATH and the $USER who is running this and
#+ todays date
TARGET="$TARGET_PATH/$USER-$(date +"$DATE_FMT")"

if [[ $COMPRESS != false ]] ; then
  if [[ ! -d $TARGET_PATH ]] ; then
    mkdir -p "$TARGET_PATH" || error_exit
  fi
  tar -c $VERBOSE $COMPRESS -C "$HOME/.." -f "$TARGET.tar.$EXT" \
      -- "${FILES[@]##$(readlink -f "$HOME/..")/}/"
else
  if [[ -d $TARGET ]] ; then
    echo "Directory \`\`$TARGET'' already exists."
  else
    echo "Directory doesn't exist - creating \`\`$TARGET''."
    mkdir -p "$TARGET" || error_exit
   fi
  cp $CP_OPT $VERBOSE -- "${FILES[@]}" "$TARGET/"
fi

echo ""
echo "Back up of $HOME completed."

exit

###################################  EOF  ###################################
.aliases
.bashrc
.gvimrc
.local
.profile
.ssh
.vimrc
bin
