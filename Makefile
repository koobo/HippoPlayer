# Experimental makefile

INCLUDE=-I$(HOME)/A/Asm/Include -I. -I./Include 
ASM=vasmm68k_mot

all: HiP HiP-debug group

# Main app
HiP: puu016.s kpl playerIds.i
	$(ASM) $(INCLUDE) -m68000 -kick1hunks -Fhunkexe -nosym -DDEBUG=0 -o $@ $<

# Debug logging version 
HiP-debug: puu016.s kpl playerIds.i
	$(ASM) $(INCLUDE) -m68000 -kick1hunks -Fhunkexe -nosym -DDEBUG=1 -o $@ $<

# Protracker replayer binary
kpl: kpl14.s
	$(ASM) $(INCLUDE) -m68000 -no-opt -Fbin -o $@ $<

# Build the group file, assemble replayers and compress them
HippoPlayer.group: playergroup2.s playerIds.i eaglepl hippopl
	$(ASM) $(INCLUDE) -m68000 -no-opt -Fbin -o $@ $<

group: HippoPlayer.group

eaglepl:
	cd eagleplayers && make

hippopl:
	cd pl && make
	
# A separate compress target
compress:
	cd pl && bash ./compress_shr
	cd eagleplayers && bash ./compress_shr

clean:
	rm HiP HiP-debug kpl HippoPlayer.group
	cd eagleplayers && make clean
	cd pl && make clean

