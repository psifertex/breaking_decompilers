SUBDIRS := 0 1 2 upx stop

# Detect the operating system and set the extension
ifeq ($(shell uname), Darwin)
    EXT = .macho
else
    EXT = .elf
endif

all:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir EXT=$(EXT); \
	done

clean:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean EXT=$(EXT); \
	done

