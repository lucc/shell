# makefile to link scripts to ~/bin {{{1
# vim: foldmethod=marker

# general variables {{{1
override ROOT  := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
BIN             = ~/bin
FILELIST        = .filelist
override FILES := $(shell \
  find . -type f -perm -1 -print -o \( -type d -name .git -prune \) | \
  cut -c3- )
.DEFAULT_GOAL  := $(FILELIST)

# variables for some targets {{{1
# macbook pro running os x {{{2
MBP =                    \
      airport            \
      battery.sh         \
      emails.sh          \
      fixperm.sh         \
      internet-search.sh \
      lock-screen.scpt   \
      mailnotify.sh      \
      secure.sh          \
      ssid.sh            \
      tagesschau.sh      \
      volume.scpt        \
      wlan.sh            \
# raspberry pi running arch linux {{{2
RPI = \

# rules for certain machines {{{1
mbp: $(MBP)
rpi: $(RPI)
# rules to link local files {{{1
$(FILES): %: $(BIN)/%
$(BIN)/%:
	@-ln -fhsv $(ROOT)$(notdir $@) $@
.PHONY: $(FILES)

# rules to link external binaries to ~/bin {{{1
airport: $(BIN)/airport
$(BIN)/airport: /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport
	ln -s $< $@

# rules to build file list {{{1
$(FILELIST):
	@echo '# Dynamically created makefile for zsh completion' >$(FILELIST)
	@echo $(FILES): >>$(FILELIST)

#$(FILELIST):
#	echo $(FILES):\; @ln -sv $(ROOT)\$$@ $(BIN)/\$$@ > .filelist

#$(FILELIST):
#	@test -r .filelist || echo recreating file list ...
#	@find . -type f -perm -1 -print -o \( -type d -name .git -prune \) | \
#	  sed 's@\./\(.*\)@\1: $(BIN)/\1@' > $(FILELIST)

# other rules {{{1
clean: ; $(RM) $(FILELIST)
clean-links:
	@flist= ;                                                \
	for file in $(FILES); do                                 \
	  if [ -L ~/bin/$$file ] &&                              \
	     [ "`readlink ~/bin/$$file`" = $(ROOT)$$file ]; then \
	    flist="$$flist $(HOME)/bin/$$file";                  \
	  fi;                                                    \
	done ;                                                   \
	echo $(RM) $$flist;                                      \
	$(RM) $$flist

# include generated makefile for zsh completion {{{1
# this should be $(FILELIST) but the zsh completion will not see it
include .filelist
