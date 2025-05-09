# Define base subdirectories
BASE_SUBDIRS := base alignment upx stop

# Detect the operating system and set the extension
ifeq ($(shell uname), Darwin)
    EXT = .macho
    SUBDIRS := $(BASE_SUBDIRS)
else
    EXT = .elf
    # On Linux, also build these additional examples
    SUBDIRS := $(BASE_SUBDIRS) sections dataflow vectorized
endif

all:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir EXT=$(EXT); \
	done

clean:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean EXT=$(EXT); \
	done

