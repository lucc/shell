#!/usr/bin/make -f
# vim: filetype=make
#
# makefile to convert music, by luc

# find the directory where the makefile lives
override ROOT := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))

# store the time the process was started
override START   := $(shell date +%s)
override NOW      = $(shell date +%s)

# all possible/allowed input file formats (file endings)
override IFORMATS = flac mp3 ogg

# commandline options (see target "help")
SRC      = $(ROOT)src
OUT      = $(ROOT)out
QUALITY  = middle
FORMAT   = ogg

# the list of files to be converted (source files)
FILELIST = $(patsubst $(SRC)/%, $(OUT)/%.$(FORMAT), $(basename $(shell \
           find $(SRC) -type f \( $(IFORMATS:%=-iname '*.%' -o) -false \))))

# the commands and options to use when converting files (all possible options
# are set here, the correct set of variables will be selectet later)
FFMPEG               = ffmpeg -n -nostdin -loglevel warning
FFMPEG_TO_OGG_OPTION = -codec:a libvorbis
LAME                 = xxx_TODO_xxx
OGGENCODE            = xxx_TODO_xxx
FLAC2OGG             = xxx_TODO_xxx
FLAC2MP3             = xxx_TODO_xxx
FLAC2OGG_BAD         = xxx_TODO_xxx
FLAC2OGG_MIDDLE      = xxx_TODO_xxx
FLAC2OGG_GOOD        = xxx_TODO_xxx
FLAC2MP3_BAD         = xxx_TODO_xxx
FLAC2MP3_MIDDLE      = xxx_TODO_xxx
FLAC2MP3_GOOD        = xxx_TODO_xxx

# set the right switches depending on FORMAT
ifeq      ($(strip $(FORMAT)), ogg)
  CONVERTER      = $(FFMPEG) -i $(1) $(FFMPEG_TO_OGG_OPTION) $(QUALITY_OPTION) $(2)
  QUALITY_BAD    = $(FLAC2OGG_BAD)
  QUALITY_MIDDLE = $(FLAC2OGG_MIDDLE)
  QUALITY_GOOD   = $(FLAC2OGG_GOOD)
else ifeq ($(strip $(FORMAT)), mp3)
  CONVERTER      = $(FFMPEG) -i $(1) $(QUALITY_OPTION) $(2)
  QUALITY_BAD    = $(FLAC2MP3_BAD)
  QUALITY_MIDDLE = $(FLAC2MP3_MIDDLE)
  QUALITY_GOOD   = $(FLAC2MP3_GOOD)
else
  .DEFAULT_GOAL = format-error
endif

# set the right switches depending on QUALITY
ifeq      ($(strip $(QUALITY)), bad)
  QUALITY_OPTION = $(QUALITY_BAD)
else ifeq ($(strip $(QUALITY)), middle)
  QUALITY_OPTION = $(QUALITY_MIDDLE)
else ifeq ($(strip $(QUALITY)), good)
  QUALITY_OPTION = $(QUALITY_GOOD)
else
  .DEFAULT_GOAL = quality-error
endif

# targets
main: $(FILELIST)
	@echo "All done.  Converting took $$(($(NOW)-$(START))) seconds."

help:
	@echo 'This makefile will copy the music collection in SRC to OUT,'
	@echo 'converting every file to FORMAT.  The possible values are:'
	@echo 'SRC:     a directory containing music (currently $(SRC))'
	@echo 'OUT:     a directory to put converted files (currently $(OUT))'
	@echo 'FORMAT:  one of "ogg", "mp3" (currently $(FORMAT))'
	@echo 'QUALITY: one of "bad", "middle", "good" (currently $(QUALITY))'
	@echo
	@echo 'You can set them like this:'
	@echo '    $$ make VAR1=value_x VAR2=value_y ...'
	@echo

# backend target to do the actual conversion of a single file
$(OUT)/%.$(FORMAT): $(SRC)/%.*
	@mkdir -p $(dir $@)
	@if [ $(<:$(SRC)%=$(OUT)%) = $@ ]; then                      \
	   if [ $< -nt $@ ]; then                                    \
	     cp -fv $< $@;                                           \
	   else                                                      \
	     echo The target file $@ is newer than $<, skipping ...; \
	   fi;                                                       \
	 else                                                        \
	     echo "$< -> $@";                                        \
	     $(call CONVERTER, $<, $@);                              \
	 fi

# error messages
format-error:
	@echo FORMAT must be set to one of ogg, mp3 >&2
	@exit 2

quality-error:
	@echo QUALITY must be set to one of bad, middle, good >&2
	@exit 2

# TODO correct quoting
#test:
#	@echo "This is TEXT: $(subst ,\",\",$(TEXT))"
