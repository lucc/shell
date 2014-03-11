#! /bin/bash

# bk.sh by luc
# This is a multi purpose backup script.

# functions {{{1
# ideas {{{2
backup_with_git () {
  local srcdir=$1
  local backupdir=$2
  export GIT_WORK_TREE=$srcdir
  # or git-config core.worktree
  export GIT_DIR=$backupdir
  git --git-dir=$backupdir --work-tree=$srcdir commit --all
  # --allow-empty --no-edit ...
  # git add --all
}
# main functions {{{2
incremental_main () {
  :
}
background_scp_main () {
  # copy files to a remote destination via scp and notify the user about
  # completion.
  (
    log=`mktemp -t $$.XXXX`
    trap "rm -f $log" INIT QUIT TERM

    if scp "$@" 2>$log; then
      growlnotify --title 'Background scp successful!'
    else
      cat $log | growlnotify --title 'Background scp failed!'
    fi

    rm -f $log
  ) & >/dev/null 2>&1
}
# wrapper functions {{{2
rsync_wrapper () {
  :
}
tar_wrapper () {
  :
}
scp_wrapper () {
  :
}
cp_wrapper () {
  :
}
bzip2_wrapper () {
  :
}
gzip_wrapper () {
  :
}

# old scripts as Functions {{{2
original_bk_sh_script_as_function () { #{{{3

# A list of settings which should go into the ultimate bk.sh file:
#
# MODE = incremental | tarball | plain_copy
# COMPRESSION = zip | gzip | bz2 | 7z | xz
# WORKINGDIR = ...
# EXCLUDE = ...
# INCLUDE = ...
# TARGET = local | remote
# REMOTE = host
# TARGETDIR = ...
# VERBOSE = true | flase
# FOLLOW_LINKS = true | flase

# Usecases:
#
# 1) with rsync: copy files to a ~/bak folder. incremental.
# 2) with rsync: copy files to a user@server:/bak folder. incremental.
# 3) compress files into a tar archve. save the archive in local folder.
# 4) compress files into a tar archive. copy archive to a remote folder.

# operation mode
MODE=tarball
TARGET=local

# basic data
DATE=`date +%F`
TIME=`date +%T`

# important file names
WORKINGDIR=$HOME
EXCLUDE=.DS_Store
INCLUDE=files
TARGETDIR=$HOME/Documents
#TARGETDIR=$HOME/bak
TARFILE=files-$DATE.$TIME.tar
SERVER=localhost
SOURCE_FILES=files
FILES_TO_UPDATE="
.abook
.aliases
.apparixrc
.bashrc
.config
.cpan
.cshrc
.ctags
.easytag
.eclipse
.eclipse_keyring
.elinks
.emacs
.emacs.d
.emacs_mathias_benk
.envrc
.epspdf
.fehrc
.fontconfig
.gem
.gvimrc
.htoprc
.ido.last
.inkscape-etc
.inputrc
.latexmkrc
.links
.local
.lyra
.MacOSX
.mailcap
.mc
.mpd
.mplayer
.muttator
.muttrc
.ncmpc
.ncmpcpp
.netbeans
.netbeans-derby
.netbeans-registration
.NetBeansProjects
.nload
.npm
.pentadactyl
.pentadactylrc
.private
.profile
.rtorrent.rc
.ssh
.subversion
.terminfo
.tilemill
.tmux.conf
.vifm
.vim
.viminfo
.vimpagerrc
.vimpcrc
.vimperator
.vimrc
.w3m
.wine
.Xauthority
.z
.zsh
.zshenv
.zshrc
batterylog.txt
bin
boottime.app
boottimelog.txt
files
vim-navi-plugin
vim-session-plugin
vim.mbox
"

# User specific settings
COMPRESSION=bzip2
VERBOSE=true
FOLLOW_LINKS=true
CONFIG_FILE=.bkrc
REWRITE_CONFIG_FILE=false

# Internal variales, do not change.
SELF=`basename "$0"`
CHANGED=2012-08-27
OPTIONS=hLPqv
TEMPDIR=`mktemp -d -t $SELF.XXXXX`
TEMPFILE=`mktemp $TEMPDIR/$SELF.XXXXX`

# Functions
help_function () {
cat<<EOF
This is a bakup script by Luc. Last changed $CHANGED.
Usage: $SELF [options]
All options are single letter options and can be given in a block, except for
options expecting an argument (options are parsed with the getopts builtin).
Valid options are:

 -h   Display this help message.
 -v   Verbose output.
 -q   No verbose output.
 -b   Use bz2 compression (overrides all previous compression-method-options)
 -g   Use gzip compression (overrides all previous compression-method-options)
 -7   Use 7z compression (overrides all previous compression-method-options)
 -i   incremental
 -t   tarball
 -r   remote
 -l   local
 -L   links
 -P   no links
EOF
}

usage_function () {
  echo Usage: $SELF [options]
  echo For a complete list of options try \`$SELF -h\'.
  exit 2
#help_function () {
#  echo "Usage: $(basename "$0") [ -c <config_file> ] [ -b | -g ] [<target dir>]"
#  echo "       $(basename "$0") [ -c <config_file> ] -m <file>"
#  echo "       $(basename "$0") [ -c <config_file> ] -u <file>"
#  echo "       $(basename "$0") -h"
#  echo ""
#  exit ;;
#}
}

set_command_options_function () {
  # This function will set the different variables containing the options for
  # different commands depending on the global value.
  if $VERBOSE; then
    TAR_VERBOSE_OPTION=-v
    CP_VERBOSE_OPTION=-v
    SCP_VERBOSE_OPTION=-v
    FTP_VERBOSE_OPTION=-v
    RSYNC_VERBOSE_OPTION=-vv
  else
    TAR_VERBOSE_OPTION=
    CP_VERBOSE_OPTION=
    SCP_VERBOSE_OPTION=-q
    FTP_VERBOSE_OPTION=-V
    RSYNC_VERBOSE_OPTION=-q
  fi
  if $FOLLOW_LINKS; then
    TAR_LINK_OPTION=-L
    CP_LINK_OPTION=-L
  else
    TAR_LINK_OPTION=
    CP_LINK_OPTION=
  fi
  case $COMPRESSION in
    bzip2)
      TAR_COMPRESSION_OPTION=-j
      EXTENSION=.bz2
      ;;
    gzip)
      TAR_COMPRESSION_OPTION=-z
      EXTENSION=.gz
      ;;
    *)
      TAR_COMPRESSION_OPTION=
      EXTENSION=
      ;;
  esac
}

source_config_file () {
  if [ -r "$1" ]; then
    . "$1"
  elif [ ! -e "$1" ]; then
    REWRITE_CONFIG_FILE=true
  fi
}

check_for_existing_backup_function () {
  false
}

ceep_track_of_last_backups () {
  local logfile="$HOME/.backuplog"
  if [ -r "$logfile" ] ; then
    last=`sed -n '${s/-//g;p;}' "$logfile"`
    if [ $last -gt `date -v-1m +%Y%m%d` ] ; then
      echo "Come back next month."
    else
      echo $DATE >> "$logfile"
      echo "Please backup your data. Todays date $DATE was appended to $logfile."
    fi
  else
    echo "Error! Can't check for last backup. There is no file $logfile"
    echo "now creating ..."
    echo "$DATE" > "$logfile"
    echo "$DATE was written on $logfile. Please backup your data."
  fi
}

rsync_function () {
  rsync                               \
    $RSYNC_VERBOSE_OPTION             \
    --copy-unsafe-links               \
    --delete-during                   \
    --delete-excluded                 \
    --devices                         \
    --group                           \
    --links                           \
    --one-file-system                 \
    --owner                           \
    --perms                           \
    --recursive                       \
    --specials                        \
    --times                           \
    --update                          \
    --include /.abook                 \
    --include /.aliases               \
    --include /.apparixrc             \
    --include /.bashrc                \
    --include /.config                \
    --include /.ctags                 \
    --include /.cups                  \
    --include /.easytag               \
    --include /.elinks                \
    --include /.emacs                 \
    --include /.emacs.d               \
    --include /.emacs_mathias_benk    \
    --include /.envrc                 \
    --include /.epspdf                \
    --include /.fehrc                 \
    --include /.fontconfig            \
    --include /.gem                   \
    --include /.gitconfig             \
    --include /.gvimrc                \
    --include /.htoprc                \
    --include /.inkscape-etc          \
    --include /.inputrc               \
    --include /.latexmkrc             \
    --include /.links                 \
    --include /.local                 \
    --include /.lyra                  \
    --include /.MacOSX                \
    --include /.mailcap               \
    --include /.mc                    \
    --include /.mpd                   \
    --include /.muttrc                \
    --include /.netbeans              \
    --include /.NetBeansProjects      \
    --include /.nload                 \
    --include /.npm                   \
    --include /.pentadactyl           \
    --include /.pentadactylrc         \
    --include /.private               \
    --include /.profile               \
    --include /.rtorrent.rc           \
    --include /.ssh                   \
    --include /.subversion            \
    --include /.terminfo              \
    --include /.tmux.conf             \
    --include /.vifm                  \
    --include /.vim                   \
    --include /.viminfo               \
    --include /.vimpagerrc            \
    --include /.vimpcrc               \
    --include /.vimrc                 \
    --include /.w3m                   \
    --include /.wine                  \
    --include /.Xauthority            \
    --include /.zsh                   \
    --include /.zshenv                \
    --include /.zshrc                 \
    --include /batterylog.txt         \
    --include /bin                    \
    --include /boottime.app           \
    --include /boottimelog.txt        \
    --include /files                  \
    --include /vim-navi-plugin        \
    --include /vim-session-plugin     \
    --include /vim.mbox               \
    --exclude .DS_Store               \
    --exclude /.wine/dosdevices       \
    --exclude /.wine/drive_c/users    \
    --exclude /.wine/drive_c/windows  \
    --exclude '/*'                    \
    $HOME/                            \
    $HOME/bak
  tar                                  \
    -c                                 \
    -C $HOME                           \
    $TAR_VERBOSE_OPTION                \
    $TAR_COMPRESSION_OPTION            \
    $TAR_LINK_OPTION                   \
    -f "$TARGETDIR/$TARFILE$EXTENSION" \
    --                                 \
    bak
}

tarball_function () {
  # function to create a tarball of the files and folders in
  # "$SOURCE_FILES" which will be saved to "$TARGETDIR/$TARFILE.$EXTENSION".
  tar                                  \
    -c                                 \
    $TAR_VERBOSE_OPTION                \
    $TAR_COMPRESSION_OPTION            \
    $TAR_LINK_OPTION                   \
    -C "$WORKINGDIR"                   \
    -f "$TARGETDIR/$TARFILE$EXTENSION" \
    --exclude .DS_Store                \
    --                                 \
    $SOURCE_FILES
}

cp_function () {
  # TODO: GNU cp supports the -u option, BSD doesn't.
  cd "$WORKINGDIR"
  cp                   \
    -Rp                \
    $CP_VERBOSE_OPTION \
    $CP_LINK_OPTION    \
    --                 \
    $SOURCE_FILES      \
    "$TARGET_DIR/"
  cd -
}

scp_function () {
  # function to put some files to a remote folder via ssh.
  scp                                             \
    -pr                                           \
    $SCP_VERBOSE_OPTION                           \
    $SOURCE_FILES                                 \
    $REMOTE_USER@$REMOTE_HOST:$REMOTE_TARGET_DIR/
}

ftp_funtion () {
  cd "$WORKINGDIR"
  ftp                                                      \
    -u ftp://$REMOTE_USER@$REMOTE_HOST/$REMOTE_TARGET_DIR/ \
    $SOURCE_FILES
  cd -
}

ftp_create_dir_and_copy_function () {
  cd "$WORKINGDIR"
  ftp                   \
    -in                 \
    $FTP_VERBOSE_OPTION \
    $REMOTE_HOST <<EOF
    user $REMOTE_USER
    cd $REMOTE_TARGET_DIR
    mkdir $DATE
    cd $DATE
    mput $SOURCE_FILES
    bye
EOF
  cd -
}

server_backup_archives () {
# A backupscript to put compressed .tar files on a ssh or ftp server
# by luc

  local file=$USER-`date +%F`
  local user=$USER
  local server=`hostname`

  while getopts vu:s:r:f: opt ; do
    case $opt in
      f) file="$OPTARG" ;;
      r) local remote_folder="$OPTARG" ;;
      s) server=$OPTARG ;;
      u) user=$OPTARG ;;
      v) local verbose=v ;;
      h|\?) echo "Usage: $(basename "$0") [-v] [-u user] [-s server]" \
		 "[-r remote_folder] [-f filename] files ..." 1>&2
	 return 1
	 ;;
    esac
  done

  shift $(($OPTIND-1))

  target="${remote_folder:+.}/$file.tar.bz2"

  if [[ $server = `hostname` ]] ; then
    echo "Backing up locally ..."
    tar -cj${verbose} -f "$target" "$@"
  else
    tar -cj${verbose} "$@" | ssh ${user}@${server} "cat > \"$target\""
  fi
}

# current version (2012-08-28). This one is rather small and basic.

while getopts $OPTIONS FLAG; do
  case $FLAG in
    h) help_function ;;
    L) FOLLOW_LINKS=true ;;
    P) FOLLOW_LINKS=false ;;
    q) VERBOSE=false ;;
    v) VERBOSE=true ;;
    *) ;;
  esac
done

set_command_options_function
#tarball_function
rsync_function

exit

} # end of original_bk_sh_script_as_function

old_file_backup6_sh_as_function () { # {{{3

#!/bin/bash

##### AUTHORS #####
# inspired by aravinthrk, anonymous, jmbarnes, tunafish, sector11, luc & johnraff
# If you work on this add your name, please.
# Developed at:   http://crunchbanglinux.org/forums/topic/10436/

##### LICENCE #####
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

##### DOCUMENTATION #####
#
##############################################################################
# TODO: sane pathname handling
# do not try to mark non existing files!
##############################################################################
#
##### END OF DOCUMENTATION #####

##### SET DEFAULT VALUES (YOU MAY EDIT THESE) #####
TARGET_PATH="$HOME/bak"
#  $INDEX is the file where the entries given to the -m and -u options will be
#+ written and deleted to/from. when actually backing up there will be a test
#+ and If it does not exist the entries of the arrays below will be used
#+ instead (the test is done after "case ... esac" with "if [[ -r $INDEX ]] ..." )
INDEX=.backup_index.txt
HIDDENFOLDERS=(.local .mc .ssh)
VISIBLEFOLDERS=(bin boottime.app)
HIDDENFILES=(.Xauthority .bash_aliases .bashrc .bootlog.sh .gvimrc .mute.sh .profile .rtorrent.rc .vimrc)
VISIBLEFILES=(batterylog.txt boottimelog.txt)
CP_OPT=-aRu  #see 'man cp' for options
VERBOSE=-v   #(un)comment to toggle verbose output of either cp or tar
DATE_FMT=%F  #see http://linux.die.net/man/3/strftime for DATE formatting

##### DO NOT EDIT BELOW THIS LINE! #####
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
    echo "Usage: $(basename "$0") [ -g | --gzip | -b | --bzip2 ] [<target directory>]"
    echo "       $(basename "$0") -m | --mark <file> [ ... ]"
    echo "       $(basename "$0") -u | --unmark <file> [ ... ]"
    echo "       $(basename "$0") -h | --help"
    echo ""
    exit ;;
  -m|--mark)
    shift
    #FIXME: untested !!
    if [[ -z "$@" &&   ! ( -s $INDEX && -r $INDEX ) ]]; then
      echo "No files listed for backup."
    else
      echo "Files now listed for backup:"
      readlink -f "$@" | cat "$INDEX" - | sort -u | tee "$INDEX"
    fi
    exit ;;
  -u|--unmark)
    shift
    #FIXME: untested !! (non existing files might break this!! )
    echo "Files now listed for backup:"
    grep -xvF "$(readlink -f "$@")" "$INDEX" | tee "$INDEX"
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
if [[ $1 ]]; then TARGET="$1" ; fi

#  we really want to back up, so look for the index file. if there is no index
#+ file we will use the values defined in the beginning of the script instead.
#+ (see comment at definition of INDEX above as well)
if [[ -r $INDEX ]]; then
  while read line; do ALL=("${ALL[@]}" $(readlink -f "$line")); done <"$INDEX"
else
  echo "No index file! Only backing up defaults."
  ALL=("${HIDDENFOLDERS[@]}" "${VISIBLEFOLDERS[@]}" "${HIDDENFILES[@]}" "${VISIBLEFILES[@]}")
fi

#  set the target from $TARGET_PATH and the $USER who is running this and
#+ todays date
TARGET="$TARGET_PATH/$USER-$(date +"$DATE_FMT")"

if [[ $COMPRESS != false ]] ; then
  if [[ ! -d $TARGET_PATH ]] ; then
    mkdir -p "$TARGET_PATH" || error_exit
  fi
  tar -c $VERBOSE $COMPRESS -C "$HOME/.." -f "$TARGET.tar.$EXT" -- "${ALL[@]##$(readlink -f "$HOME/..")/}/"
else
  if [[ -d $TARGET ]] ; then
    echo "Directory \`\`$TARGET'' already exists."
  else
    echo "Directory doesn't exist - creating \`\`$TARGET''."
    mkdir -p "$TARGET" || error_exit
   fi
  cp $CP_OPT $VERBOSE -- "${ALL[@]}" "$TARGET/"
fi

echo ""
echo "Back up of $HOME completed."

exit


} # end of old_file_backup6_sh_as_function

old_script_bk_selfcontained_as_function () { #{{{3

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

}

old_backup_make_file_as_function () { #{{{3

# date {{{4
DATE        := $(shell date +%F)
TIME        := $(shell date +%T)
DATETIME     = $(subst -,,$(DATE))$(subst :,,$(TIME))
LOGGING      = >/dev/null 2>&1

# command options {{{4
TAROPTIONS   = -cpvz --exclude .DS_Store
TAREXT       = .gz
CPOPTIONS    = -pR
RSYNCOPTIONS = \
	       --copy-unsafe-links \
               --delete-during     \
               --delete-excluded   \
               --devices           \
               --group             \
               --links             \
               --one-file-system   \
               --owner             \
               --perms             \
               --recursive         \
               --specials          \
               --times             \
               --update            \
               --verbose           \

SCPOPTIONS   = -prv

# files {{{4
BAK          = ~/bak
# configfiles {{{5
INCLUDE      = \
	      .config    \
	      art        \
	      bank       \
	      bib        \
	      bin        \
	      cook       \
	      etc        \
	      files.txt  \
	      go         \
	      leh        \
	      lit        \
	      log        \
	      mail       \
	      phon       \
	      sammersee  \
	      src        \
	      todo       \
	      uni        \

#exclude {{{5
EXCLUDE      = \
	      .DS_Store                \
	      .git                     \
	      /.config/music/mpd/music \
	      /.wine/dosdevices        \
	      /.wine/drive_c/users     \
	      /.wine/drive_c/windows   \
	      /.subversion/auth        \
	      '/*'                     \

# targets {{{4

all fullbk: statistics rsync baktar lima

statistics:
	statistics.sh -d ~

# rsync {{{5
rsync:
	@echo rsync --options --filter ... ~/ $(BAK)/$(USER)
	@rsync                      \
	  $(RSYNCOPTIONS)           \
	  $(INCLUDE:%=--include /%) \
	  $(EXCLUDE:%=--exclude %)  \
	  --filter 'P bak*.tar*'    \
	  ~/ $(BAK)/$(USER)         \
	  $(LOGGING)

# tar {{{5
filestar:
	tar $(TAROPTIONS) -LC ~/ -f ~/Documents/files-$(DATE).tar$(TAREXT) \
	  -- files

baktar:
	tar                                     \
	  $(TAROPTIONS)                         \
	  -C $(BAK)                             \
	  -f $(BAK)/bak$(DATETIME).tar$(TAREXT) \
	  --exclude .cache                      \
	  --                                    \
	  $(USER)                               \
	  $(LOGGING)

lima:
	$(MAKE) -C ~/.config lima

} # end of old_backup_make_file_as_function

# variables {{{1

# parsing the commandline {{{1

# main script {{{1


# vim: foldmethod=marker
