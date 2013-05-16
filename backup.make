#!/usr/bin/make -f
# vim: ft=make foldmethod=marker

# variables {{{1
SELF = backup.make
LIMA = ftp.lima-city.de

# date {{{1
DATE        := $(shell date +%F)
TIME        := $(shell date +%T)
DATETIME     = $(subst -,,$(DATE))$(subst :,,$(TIME))

# command options {{{1
TAROPTIONS   = -cpvz --exclude .DS_Store
TAREXT       = .gz
CPOPTIONS    = -pR
RSYNCOPTIONS = --copy-unsafe-links \
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
               --verbose
SCPOPTIONS   = -prv

# files {{{1
TEMPFILE    := $(shell mktemp -t $(SELF).XXXXX)
BAK          = ~/bak
# configdirs {{{2
CONFIGDIRS   = \
	      .abook            \
	      .antiword         \
	      .conkyrc          \
	      .config           \
	      .cups             \
	      .easytag          \
	      .elinks           \
	      .emacs.d          \
	      .epspdf           \
	      .fontconfig       \
	      .gem              \
	      .gitconfig        \
	      .gnupg            \
	      .inkscape-etc     \
	      .links            \
	      .local            \
	      .lyra             \
	      .MacOSX           \
	      .mc               \
	      .mpd              \
	      .mu               \
	      .mutt             \
	      .netbeans         \
	      .NetBeansProjects \
	      .npm              \
	      .pentadactyl      \
	      .postfix          \
	      .secure           \
	      .shell            \
	      .ssh              \
	      .subversion       \
	      .terminfo         \
	      .vifm             \
	      .vim              \
	      .w3m              \
	      .wine             \

# configfiles {{{2
CONFIGFILES  = \
	      .abcde.conf             \
	      .aliases                \
	      .apparixrc              \
	      .bashrc                 \
	      .ctags                  \
	      .emacs                  \
	      .emacs_mathias_benk     \
	      .envrc                  \
	      .fehrc                  \
	      .fetchmailrc            \
	      .gitconfig              \
	      .gvimrc                 \
	      .htoprc                 \
	      .inputrc                \
	      .latexmkrc              \
	      .mailcap                \
	      .mailcheckrc            \
	      .mailfilter             \
	      .mime.types             \
	      .muttrc                 \
	      .nload                  \
	      .pal                    \
	      .pentadactylrc          \
	      .private                \
	      .procmailrc             \
	      .profile                \
	      .pystartup              \
	      .rtorrent.rc            \
	      .tmux.conf              \
	      .vimpagerrc             \
	      .vimpcrc                \
	      .vimrc                  \
	      .xinitrc                \
	      .Xmodmap                \
	      .Xresources             \
	      .z                      \
	      .zshenv                 \
	      .zshrc                  \
	      batterylog.txt          \
	      boottimelog.txt         \
	      geektool-diskspace.glet \
	      geektool-mail.glet      \
	      geektool-weather.glet   \
	      TODO                    \

# otherdirs {{{2
OTHERDIRS    = \
	      apply                                     \
	      art                                       \
	      bank                                      \
	      bib                                       \
	      bin                                       \
	      cook                                      \
	      dsa                                       \
	      etc                                       \
	      files                                     \
	      go                                        \
	      leh                                       \
	      lit                                       \
	      log                                       \
	      mail                                      \
	      phon                                      \
	      sammersee                                 \
	      schule                                    \
	      src                                       \
	      uni                                       \
	      zis                                       \
	      'Library/Application Support/AddressBook' \
	      Library/Calendars                         \

INCLUDE      = $(CONFIGDIRS) $(CONFIGFILES) $(OTHERDIRS) files.txt

#exclude {{{2
EXCLUDE      = \
	      .DS_Store              \
	      /.wine/dosdevices      \
	      /.wine/drive_c/users   \
	      /.wine/drive_c/windows \
	      /.subversion/auth      \
	      '/*'                   \

# limafiles {{{2
LIMAFILES    = \
	      GetLatestVimScripts.dat \
	      aliases                 \
	      envrc                   \
	      gvimrc                  \
	      htoprc                  \
	      inputrc                 \
	      latexmkrc               \
	      profile                 \
	      rtorrent.rc             \
	      vimpagerrc              \
	      vimrc                   \
	      zshenv                  \
	      zshrc                   \

# targets {{{1

all fullbk: statistics rsync baktar lima

statistics:
	~/bin/statistics.sh -d ~

# rsync {{{2
rsync:
	@echo rsync --options --filter ... ~/ $(BAK)/$(USER)
	@rsync                      \
	  $(RSYNCOPTIONS)           \
	  $(INCLUDE:%=--include /%) \
	  $(EXCLUDE:%=--exclude %)  \
	  --filter 'P bak*.tar*'    \
	  ~/ $(BAK)/$(USER)

# tar {{{2
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
	  $(USER)

# ftp {{{2
#tempfilelima:
#	false &&                             \
#	cd ~/src/config &&                   \
#	ftp -iv luc42@ftp.lima-city.de <<EOF \
#	  cd files/dotfiles                  \
#	  mkdir $(DATE)                      \
#	  cd $(DATE)                         \
#	  mput $(LIMAFILES)                  \
#	  bye                                \
#	EOF
#
#otherlima:
#	ftp $(LIMA) <<<'mkdir files/dotfiles/$(DATE)'
#	cd ~/src/config && \
#	ftp -u $(LIMA)/files/dotfiles/$(DATE) $(LIMAFILES)
#
lima:
	@touch $(TEMPFILE)
	@echo mkdir files/dotfiles/$(DATE) > $(TEMPFILE)
	@echo cd files/dotfiles/$(DATE)   >> $(TEMPFILE)
	@echo mput $(LIMAFILES)           >> $(TEMPFILE)
	@echo bye                         >> $(TEMPFILE)
	cd ~/src/config && ftp -iV $(LIMA) < $(TEMPFILE)
	@echo > $(TEMPFILE)
	@$(RM) $(TEMPFILE)
