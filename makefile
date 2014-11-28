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
      wlan               \
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
