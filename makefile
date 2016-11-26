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
  $(error Unknown system $(UNAME).  Please edit the makefile.)
endif

override ROOT := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
DESTDIR = ~/.local
FILES := $(foreach file,                                          \
  $(shell find . \( -type f -o -type l \) -perm -1 -print -o      \
		\( -type d -name .git -prune \)),                 \
  $(if $(filter $(dir $(file)),./ ./$(SYSTEM)/ ./git/ ./mailcap/), \
  $(file:./%=%)))
NAMES  = $(foreach triple,$(NAMED),$(call get,1,$(triple)))
LINKED = $(addprefix $(DESTDIR)/bin/, \
         $(notdir $(filter $(ROOT)%,$(realpath $(wildcard $(DESTDIR)/bin/*)))))
SEP    = :
get    = $(word $1,$(subst $(SEP), ,$2))

define internal-linker
# the name (frontend) depends on the link in $(DESTDIR)/bin
$1: $(DESTDIR)/bin/$(notdir $1)
# the link is created from the file in this directory
$(DESTDIR)/bin/$(notdir $1): $(ROOT)$1
	@$(LN) $$< $$@
endef
define external-linker
# the name (frontend) depends on the link in $(DESTDIR)/bin
$(call get,2,$1): $(DESTDIR)/bin/$(call get,2,$1)
# the link is created from the file specified in the variable
$(DESTDIR)/bin/$(call get,2,$1): $(call get,1,$1)
	@$(LN) $$< $$@
.PHONY: $(call get,2,$1)
endef
define named-linker
# the name (frontend) depends on first argument
$(call get,1,$1): $(call get,3,$1)
# the link is created from the second to the third argument
$(call get,3,$1): $(ROOT)$(call get,2,$1)
	@$(LN) $$< $$@
.PHONY: $(call get,1,$1)
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
# files to link to custom locations {{{3
NAMED = \
	git-completions$(SEP)git/_git_custom_scripts.zsh$(SEP)~/.config/zsh/functions/_git-luc-custom-scripts
# raspberry pi running arch linux {{{3
RPI = \
# mbp running arch {{{3
MBPARCH = \
        $(NOTHING)

# front end rules {{{1
all:
mbp: $(MBP)
mbp-arch: $(MBPARCH)
rpi: $(RPI)
relink: clean-links $(LINKED)
# generic rules {{{2
clean: ; $(RM) $(FILELIST)
clean-links:
	$(RM) $(LINKED)

# back end rules {{{1
$(foreach file,$(FILES),$(eval $(call internal-linker,$(file))))
$(foreach pair,$(APPLE),$(eval $(call external-linker,$(pair))))
$(foreach args,$(NAMED),$(eval $(call named-linker,$(args))))
.PHONY: $(FILES) $(NAMES)

# hack to enable zsh completion for some dynamically generated targets {{{1
FILELIST = .filelist
include .filelist
$(FILELIST):
	@echo '# Dynamically created makefile for zsh completion' >$(FILELIST)
	@echo $(FILES) $(NAMES): >>$(FILELIST)
.PHONY: $(FILELIST)
