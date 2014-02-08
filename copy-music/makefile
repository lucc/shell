# makefile by luc

# set up PATH to include the projects bin/ directory
ROOTDIR := $(dir $(CURDIR)/$(lastword $(MAKEFILE_LIST)))
export PROJECTBIN := $(ROOTDIR)bin
override PATH := $(PROJECTBIN):$(PATH)

# variables
QUALITY  = middle   # other possibilities are 'bad' and 'good'
FORMAT   = ogg      # other possibilities are 'mp3' and ?

# command variables
FLAC2OGG        =
FLAC2MP3        =
FLAC2OGG_BAD    =
FLAC2OGG_MIDDLE =
FLAC2OGG_GOOD   =
FLAC2MP3_BAD    =
FLAC2MP3_MIDDLE =
FLAC2MP3_GOOD   =

.DEFAULT_GOAL = testx

# set the right switches for FORMAT
ifeq      ($(strip $(FORMAT)), ogg)
  CONVERTER     = $(FLAC2OGG)
  OPTION_BAD    = $(FLAC2OGG_BAD)
  OPTION_MIDDLE = $(FLAC2OGG_MIDDLE)
  OPTION_GOOD   = $(FLAC2OGG_GOOD)
else ifeq ($(strip $(FORMAT)), mp3)
  CONVERTER     = $(FLAC2MP3)
  OPTION_BAD    = $(FLAC2MP3_BAD)
  OPTION_MIDDLE = $(FLAC2MP3_MIDDLE)
  OPTION_GOOD   = $(FLAC2MP3_GOOD)
else
  .DEFAULT_GOAL = format-error
endif

# set the right switches for QUALITY
ifeq      ($(strip $(QUALITY)), bad)
  OPTION = $(OPTION_BAD)
else ifeq ($(strip $(QUALITY)), middle)
  OPTION = $(OPTION_MIDDLE)
else ifeq ($(strip $(QUALITY)), good)
  OPTION = $(OPTION_GOOD)
else
  .DEFAULT_GOAL = quality-error
endif




# targets
help:
	@echo 'This makefile will convert the music collection in ./src/ to'
	@echo 'the specified format.  You can set the FORMAT and QUALITY'
	@echo 'options from the commandline, like so:'
	@echo '  make QUALITY=good FORMAT=mp3'

index: $(shell find src)
	find src > index

build/%.ogg: src/%.flac
	@echo '$$< -> ' $<
	@echo '$$@ -> ' $@
	#$(PROJECTBIN)/flac2ogg --quality $(QUALITY) --input $< --output $@
build/%.mp3: src/%.flac
	@echo '$$< -> ' $<
	@echo '$$@ -> ' $@
	#$(PROJECTBIN)/flac2mp3 --quality $(QUALITY) --input $< --output $@

format-error:
	@echo FORMAT must be set to one of 'ogg', 'mp3' >&2
	@exit 2

quality-error:
	@echo QUALITY must be set to one of 'bad', 'middle', 'good' >&2
	@exit 2


#
# TESTS ######################################################################
#
t%st: notest null
	@echo '$$< -> ' $<
	@echo '$$@ -> ' $@
	@echo '$$^ -> ' $^

notest:
	echo $$PATH
	$(PROJECTBIN)/flac2mp3
null:
	@echo >/dev/null
testx:
	@echo $x $y
