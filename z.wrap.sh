# Copyright (c) 2009 rupa deadwyler under the WTFPL license

# maintains a jump-list of the directories you actually use
#
# INSTALL:
#   * optionally:
#     set $_Z_CMD in .bashrc/.zshrc to change the command (default z).
#     set $_Z_DATA in .bashrc/.zshrc to change the datafile (default ~/.z).
#   * put something like this in your .bashrc:
#     . /path/to/z.sh
#   * put something like this in your .zshrc:
#     . /path/to/z.sh
#     function precmd () {
#       _z --add "$(pwd -P)"
#     }
#   * cd around for a while to build up the db
#   * PROFIT!!
#
# USE:
#   * z foo     # cd to most frecent dir matching foo
#   * z foo bar # cd to most frecent dir matching foo and bar
#   * z -r foo  # cd to highest ranked dir matching foo
#   * z -t foo  # cd to most recently accessed dir matching foo
#   * z -l foo  # list all dirs matching foo (by frecency)

_z() {

 local datafile="${_Z_DATA:-$HOME/.z}"

 # bail out if we don't own ~/.z (we're another user but our ENV is still set)
 [ -f "$datafile" -a ! -O "$datafile" ] && return

 # add entries
 if [ "$1" = "--add" ]; then
  shift

  # $HOME isn't worth matching
  [ "$*" = "$HOME" ] && return

  # maintain the file
  local tempfile
  tempfile="$(mktemp $datafile.XXXXXX)" || return
  #awk -v path="$*" -f /User/lucas/bin/z.complete.awk "$datafile" 2>/dev/null >| "$tempfile"
  /User/lucas/bin/z.add.awk --add "$datafile" 2>/dev/null >| "$tempfile"
  if [ $? -ne 0 -a -f "$datafile" ]; then
   env rm -f "$tempfile"
  else
   env mv -f "$tempfile" "$datafile"
  fi

 # tab completion
 elif [ "$1" = "--complete" ]; then
   #awk -v q="$2" -f /Users/lucas/bin/z.complete.awk "$datafile" 2>/dev/null
    /Users/lucas/bin/z.complete.awk --complete "$2" "$datafile" 2>/dev/null

 else
  # list/go
  while [ "$1" ]; do case "$1" in
   -h) echo "z [-h][-l][-r][-t] args" >&2; return;;
   -l) local list=1;;
   -r) local typ="rank";;
   -t) local typ="recent";;
   --) while [ "$1" ]; do shift; local fnd="$fnd $1";done;;
    *) local fnd="$fnd $1";;
  esac; local last=$1; shift; done
  [ "$fnd" ] || local list=1

  # if we hit enter on a completion just go there
  case "$last" in
   # completions will always start with /
   /*) [ -z "$list" -a -d "$last" ] && cd "$last" && return;;
  esac

  # no file yet
  [ -f "$datafile" ] || return

  local cd
  cd="$(awk -v t="$(date +%s)" -v list="$list" -v typ="$typ" -v q="$fnd" -f /Users/lucas/bin/z.else.awk "$datafile")"
  [ $? -gt 0 ] && return
  [ "$cd" ] && cd "$cd"
 fi
}

alias ${_Z_CMD:-z}='_z 2>&1'

if complete &> /dev/null; then
 # bash tab completion
 complete -C '_z --complete "$COMP_LINE"' ${_Z_CMD:-z}
 # populate directory list. avoid clobbering other PROMPT_COMMANDs.
 echo $PROMPT_COMMAND | grep -q "_z --add"
 [ $? -gt 0 ] && PROMPT_COMMAND='_z --add "$(pwd -P 2>/dev/null)" 2>/dev/null;'"$PROMPT_COMMAND"
elif compctl &> /dev/null; then
 # zsh tab completion
 _z_zsh_tab_completion() {
  local compl
  read -l compl
  reply=(${(f)"$(_z --complete "$compl")"})
 }
 compctl -U -K _z_zsh_tab_completion _z
fi
