#
# try to use suffix rules whenever possible in any of the lower makefiles
# in the case of exceptions, just use an explicit build rule
#
# there are also some bizarre things being done with case-sensitive sources
# make is very much case-sensitive, so we use this.  if your underlying
# filesystem is not case-preserving, forget it.
#
# .asm:  TASM sources, except somewheres it is MAC or RMAC
# .z80:  Z80ASM sources, except ZSDOS, where they are ZMAC
# .azm:  zsm sources
#
UNAME := $(shell uname)
BINDIR = $(TOOLS)/$(UNAME)

#
# since this file is included from below, it's handy to have an idea
# where we are relative to the tree
#
TREEROOT := $(shell cd $(TOOLS)/.. ; pwd)
HERE := $(shell pwd)
RELPATH := $(subst $(TREEROOT),,$(HERE))

#
# where's a copy of this tree for windows so we can diff binaries
#
WINROOT = $(TREEROOT)/../RomWBW.windows
DIFFTO := $(shell if [ -d $(WINROOT) ] ; then cd $(WINROOT); pwd; fi)
DIFFPATH := $(DIFFTO)/$(RELPATH)

#
# this is a script that resolves a filename in a case-insensitive way
# to be used in diff'ing objects
#
CASEFN = $(TOOLS)/unix/casefn.sh

#
# compiler/assembler locations and flags
#
ZXCC=$(BINDIR)/zxcc
export CPMDIR80=$(TOOLS)/cpm/
TASM=$(BINDIR)/uz80as -t z80
TASMFLAGS=
OPENSPIN=$(BINDIR)/openspin
CPMCP=$(BINDIR)/cpmcp
CPMLS=$(BINDIR)/cpmls
CPMCHATTR=$(BINDIR)/cpmchattr

#
# directory containing cpm binaries
#
CPM=$(TOOLS)/cpm/bin80/

#
# .ONESHELL uses a single shell instance for all shell scripts.
# .SHELLFLAGS is used to cause all shell scripts to echo ("e") and to
#    exit if any command returns a non-zero result ("x").
#
.ONESHELL:
.SHELLFLAGS = -ce

%.com: %.asm
	@if [ "$(USETASM)" = 1 ] ; then \
		$(TASM) $(TASMFLAGS) $< $@ $*.lst ; \
	else \
		$(ZXCC) $(CPM)/MAC -$< -$$PO ; \
		$(ZXCC) $(CPM)/MLOAD25 -tmp.bin=$*.hex ; \
		mv tmp.bin $@ ; \
		rm -f /tmp/casefn.cache ; \
		rm -f $$($(CASEFN) $*.hex) ; \
	fi

%.rom: %.asm
	@$(TASM) $(TASMFLAGS) $< $@ $*.lst

%.hex: %.asm
	@$(ZXCC) $(CPM)/MAC -$< -$$PO

%.bin: %.ASM
	@$(ZXCC) $(CPM)/MAC -$< -$$PO
	$(ZXCC) $(CPM)/MLOAD25 -tmp.bin=$*.hex
	mv tmp.bin $@
	rm -f /tmp/casefn.cache
	rm -f $$($(CASEFN) $*.hex)

%.com: %.z80
	@$(ZXCC) $(CPM)/Z80ASM -$(basename $<)/F
	rm -f /tmp/casefn.cache
	mv $$($(CASEFN) $@) tmp.com ; mv tmp.com $@

%.bin: %.asm
	@$(TASM) $(TASMFLAGS) $< $@ $(basename $<).lst

%.rel: %.asm
	@$(ZXCC) $(CPM)/RMAC -$<

%.rel: %.z80
	@$(ZXCC) $(CPM)/Z80ASM -$(basename $<)/MF

#%.hex: %.z80
#	@$(ZXCC) $(CPM)/Z80ASM -$(basename $<)/HF

%.hex: %.z80
	@$(ZXCC) $(CPM)/SLR180 -$(basename $<)/HF

%.rel: %.azm
	@$(ZXCC) $(CPM)/ZSM =$< -/L

%.bin: %.rel
	@$(ZXCC) $(CPM)/LINK -$@=$<

%.rel: %.mac
	@$(ZXCC) $(CPM)/M80 -=$(basename $<)

%.com: %.rel
	@$(ZXCC) $(CPM)/L80 -$(basename $<),$(basename $<).com/n/e

%.eeprom: %.spin
	@$(OPENSPIN) -e $<

#
# first target is default
#
all:: $(OBJECTS)
	@for dir in $(SUBDIRS) ; do \
		$(MAKE) --directory $$dir ; \
	done
	rm -f /tmp/casefn.cache
	@if [ "$(DEST)" ] && [ "$(OBJECTS)" ] ; then for file in $(filter-out $(NOCOPY),$(OBJECTS)) ; do \
		mkdir -p $(DEST) ; \
		echo Copying $$file to $(DEST) ; \
		cp $$($(CASEFN) $$file) $(DEST) ; \
	done ; fi
	@if [ "$(DOCDEST)" ] && [ "$(DOCS)" ] ; then for file in $(DOCS) ; do \
		mkdir -p $(DOCDEST) ; \
		echo Copying $$file to $(DOCDEST) ; \
		cp $$($(CASEFN) $$file) $(DOCDEST) ; \
	done ; fi

clean::
	@-rm -f $$($(CASEFN) make.out *.sym *.lst *.prn *.diff *.dump $(OTHERS) $(filter-out $(NODELETE),$(OBJECTS)))
	@for dir in $(SUBDIRS) ; do \
		$(MAKE) --directory $$dir clean ; \
	done

clobber:: clean

#
# this is used to verify that the unix and windows tool chains are generating
# the same objects
#
diff::
ifneq ($(DIFFTO),)
	@for dir in $(SUBDIRS) ; do \
		( echo "diff in $(HERE)/$$dir" ; cd "$$dir" ; make diff ) ; \
	done
	@for i in $(filter-out $(NODIFF),$(OBJECTS) $(MOREDIFF)) ; do \
        sf=$$($(CASEFN) $$i) ; \
		df=$$($(CASEFN) $(DIFFPATH)/$$i) ; \
        if [ -f "$$df" -a -f "$$sf" ] ; then \
			if [ "$(VERBOSEDIFF)" ] ; then \
				echo compare $$sf and $$df ; \
			fi ; \
			if ! cmp -s $$sf $$df ; then \
				echo " " $$sf and $$df differ ; \
				if [ "$(VERBOSEDIFF)" = "2" ] ; then \
					hexdump -Cv $$sf > $$sf.dump ; \
					hexdump -Cv $$df > $$(basename $$df).dump.diff ; \
				fi \
			fi \
		else \
			if [ ! -f "$$sf" ] ; then echo $$i missing ; fi ; \
			if [ ! -f "$$df" ] ; then echo $(DIFFPATH)/$$i missing ; fi ; \
		fi ; \
    done
endif


vdiff:
	make VERBOSEDIFF=2 diff
