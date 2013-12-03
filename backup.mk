#!/usr/bin/make -f
# vim: ft=make foldmethod=marker

# date {{{1
DATE        := $(shell date +%F)
TIME        := $(shell date +%T)
DATETIME     = $(subst -,,$(DATE))$(subst :,,$(TIME))
LOGGING      = >/dev/null 2>&1

# command options {{{1
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

# files {{{1
BAK          = ~/bak
# configfiles {{{2
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

#exclude {{{2
EXCLUDE      = \
	      .DS_Store                \
	      .git                     \
	      /.config/music/mpd/music \
	      /.wine/dosdevices        \
	      /.wine/drive_c/users     \
	      /.wine/drive_c/windows   \
	      /.subversion/auth        \
	      '/*'                     \

# targets {{{1

all fullbk: statistics rsync baktar lima

statistics:
	statistics.sh -d ~

# rsync {{{2
rsync:
	@echo rsync --options --filter ... ~/ $(BAK)/$(USER)
	@rsync                      \
	  $(RSYNCOPTIONS)           \
	  $(INCLUDE:%=--include /%) \
	  $(EXCLUDE:%=--exclude %)  \
	  --filter 'P bak*.tar*'    \
	  ~/ $(BAK)/$(USER)         \
	  $(LOGGING)

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
	  $(USER)                               \
	  $(LOGGING)

lima:
	$(MAKE) -C ~/.config lima