# Experimental makefile

INCLUDE=-I$(HOME)/A/Asm/Include -I. -I./Include 
ASM=~/Prj/vbcc/bin/vasmm68k_mot
FLAGS=
TARGET=

# Normal and debug build of the main app
all: HiP HiP-debug group

# Same as above with debug build of the group as well.
# This enables logging with PS3M and sampleplayer.
debug: FLAGS+=-DDEBUG=1
debug: TARGET=debug
debug: all

# Main app
HiP: puu016.s kpl playerIds.i
	$(ASM) $(INCLUDE) -m68000 -kick1hunks -Fhunkexe -nosym -DDEBUG=0 -o $@ $<
	@echo Built $@

# Debug logging version 
HiP-debug: puu016.s kpl playerIds.i
	$(ASM) $(INCLUDE) -m68000 -kick1hunks -Fhunkexe -nosym -DDEBUG=1 -L $@.txt -o $@ $<
	@echo Built $@

# Protracker replayer binary
kpl: kpl14.s
	$(ASM) $(INCLUDE) -m68000 -no-opt -Fbin -o $@ $<

# Build the group file, assemble replayers and compress them
HippoPlayer.group: playergroup2.s playerIds.i eaglepl hippopl
	$(ASM) $(INCLUDE) -m68000 -no-opt -Fbin -o $@ $<
	@echo Built $@

group: HippoPlayer.group

eaglepl:
	cd eagleplayers && make 

hippopl:
	cd pl && make $(TARGET)
	
# A separate compress target
compress:
	cd pl && bash ./compress_shr
	cd eagleplayers && bash ./compress_shr

cleaner: clean
	cd eagleplayers && make clean
	cd pl && make clean

clean:	
	rm -f HiP HiP-debug 

dist: HiP HiP-debug group
	cd dist && make

stil: STIL.txt

STIL.txt: 
	wget https://hvsc.brona.dk/HVSC/C64Music/DOCUMENTS/STIL.txt
