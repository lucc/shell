# makefile to link scripts to ~/bin
override ROOT := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
.DEFAULT_GOAL  = .filelist
NEWLINE        =

include .filelist

.filelist:
	@test -r .filelist || echo recreating file list ...
	@find . -type f -perm -1 -print -o \( -type d -name .git -prune \) | \
	  cut -f 2- -d / | while read file; do                               \
	    echo "$$file: ~/bin/$$file";                                     \
	    echo "~/bin/$$file: ; @ln -sv $(ROOT)$$file ~/bin/$$file";       \
	  done > .filelist

clean: ; $(RM) .filelist

.PHONY: .filelist
