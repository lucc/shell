# makefile to link scripts to ~/bin {{{1
# vim: foldmethod=marker

# variables {{{1
# general variables {{{2
UNAME := $(strip $(shell uname))
ifeq ($(UNAME),Darwin)
  SYSTEM = osx
  LN     = ln -fnsv
else ifeq ($(UNAME),Linux)
  SYSTEM = linux
  LN     = ln --force --symbolic --no-dereference --verbose
else
  $(error Unknown system $(UNAME).  Plesae edit the makefile.)
endif

override ROOT := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
BIN            = ~/bin
FILELIST       = .filelist
FILES         := $(foreach file,                                            \
			   $(shell find . -type f -perm -1 -print -o        \
					  \( -type d -name .git -prune \)), \
			   $(if $(filter $(dir $(file)),./ ./$(SYSTEM)/),   \
				$(file:./%=%)))
.DEFAULT_GOAL := $(FILELIST)
SEP            = :
get            = $(word $1,$(subst $(SEP), ,$2))

define internal-linker
# the name (frontend) depends on the link in ~/bin
$1: $(BIN)/$(notdir $1)
# the link is created from the file in this directory
$(BIN)/$(notdir $1): $(ROOT)$1
	@$(LN) $$< $$@
endef
define external-linker
# the name (frontend) depends on the link in ~/bin
$(call get,2,$1): $(BIN)/$(call get,2,$1)
# the link is created from the file specified in the variable
$(BIN)/$(call get,2,$1): $(call get,1,$1)
	@$(LN) $$< $$@
.PHONY: $(call get,2,$1)
endef

# variables for some targets {{{2
# color {{{3
COLOR = \
	color.sh      \
	colordemo.vim \
	colorize.sh   \
# old mac stuff {{{3
OLD_MAC = \
	  brew-up.sh              \
	  compile-macvim.sh       \
	  contacts.sh             \
	  create-encrypted-dmg.sh \
	  display.scpt            \
	  ff                      \
	  firefox                 \
	  fetchmail-wrapper.sh    \
	  fixperm.sh              \
	  growl.scpt              \
	  mailtomutt.scpt         \
	  test.scpt               \
	  volume.scpt             \
	  iterm-session.scpt      \
	  mpd-killer.sh           \
# legacy code {{{3
LEGACY = \
	 2utf8.sh            \
	 can.sh              \
	 cb.sh               \
	 cinclude.sh         \
	 imagebackground.php \
	 lpq.sh              \
	 uptime.sed          \
	 vide.sh             \
# other {{{3
OTHER = \
	backup.sh              \
	batch-ocr.sh           \
	battery.py             \
	battery.sh             \
	bibkeys.py             \
	bibkeys.sh             \
	cleanlatex.sh          \
	convert-pdf.sh         \
	docx2txt.pl            \
	exif2ctime.sh          \
	funny-self-cat-file    \
	img.sh                 \
	internet-search.sh     \
	latexmk.py             \
	libreoffice            \
	mb2md-3.20.pl          \
	minlog-luc.scm         \
	mv-dialog.sh           \
	nicenummber.sh         \
	office2any.sh          \
	passtoggle.sh          \
	pdfcrack.sh            \
	post-install.sh        \
	print_ssh.sh           \
	renumber-file.sh       \
	sanename.sh            \
	secure.sh              \
	shrinkpdf.sh           \
	sig2dot.pl             \
	skype.sh               \
	ssid.sh                \
	statistics.sh          \
	system-password.sh     \
	tagesschau.sh          \
	term                   \
	tmux-daemon-session.sh \
	translate.sh           \
	vpn.sh                 \
	wlan.sh                \
	www-text-browser.sh    \
# git {{{3
GIT = \
      git-foreach-ref.sh \
      gitautocommit.sh   \
      homegit.sh         \
# music {{{3
MUSIC = \
	get-metadata.py \
	add-dance.sh    \
	mpdclient2.py   \
	copy-music.mk   \
	copy-music.py   \
	copy-music.sh   \
# mail {{{3
MAIL = \
       emails.sh     \
       mailnotify.sh \
       mailtomutt.sh \
# macbook pro running os x {{{3
MBP = \
      airport            \
      battery.sh         \
      emails.sh          \
      fixperm.sh         \
      internet-search.sh \
      lock               \
      mailnotify.sh      \
      secure.sh          \
      ssid.sh            \
      tagesschau.sh      \
      volume.scpt        \
      wlan.sh            \
# other apple stuff {{{3
APPLE = \
      /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport$(SEP)airport \
      /System/Library/CoreServices/backupd.bundle/Contents/Resources/backupd-helper$(SEP)timemachine         \
      /Applications/TrueCrypt.app/Contents/MacOS/TrueCrypt$(SEP)truecrypt                                    \
# raspberry pi running arch linux {{{3
RPI = \
# mbp running arch {{{3
MBPARCH = \
        $(NOTHING)
# default target {{{1
.DEFAULT_GOAL := $(if $(findstring Darwin,$(shell uname)),mbp,rpi)

# front end rules {{{1
mbp: $(MBP)
mbp-arch: $(MBPARCH)
rpi: $(RPI)
# generic rules {{{2
clean: ; $(RM) $(FILELIST)
clean-links:
	$(RM) $(addprefix $(BIN)/, \
	      $(notdir $(filter $(ROOT)%,$(realpath $(wildcard $(BIN)/*)))))

# back end rules {{{1
# rules to link local files {{{2
$(foreach file,$(FILES),$(eval $(call internal-linker,$(file))))
$(foreach pair,$(APPLE),$(eval $(call external-linker,$(pair))))
.PHONY: $(FILES)

# rules to build file list {{{2
$(FILELIST):
	@echo '# Dynamically created makefile for zsh completion' >$(FILELIST)
	@echo $(FILES): >>$(FILELIST)

# include generated makefile for zsh completion {{{1
# this should be $(FILELIST) but the zsh completion will not see it
include .filelist

# tests and debugging {{{1
