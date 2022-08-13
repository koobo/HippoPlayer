# Experimental makefile

INCLUDE=-I$(HOME)/A/Asm/Include -I. -I./Include 
ASM=vasmm68k_mot

# Main app
hipv: puu016.s HippoPlayer.group kpl playerIds.i
	$(ASM) $(INCLUDE) -m68000 -kick1hunks -Fhunkexe -o hipv -nosym puu016.s

# Protracker replayer binary
kpl: kpl14.s
	$(ASM) $(INCLUDE) -m68000 -no-opt -Fbin -o kpl kpl14.s

# Group file which includes the compressed replay binaries
HippoPlayer.group: playergroup2.s playerIds.i
	$(ASM) $(INCLUDE) -m68000 -no-opt -Fbin -o HippoPlayer.group playergroup2.s

# Compress prebuilt replay binaries (slow)
compress:
	cd pl && bash ./compress_shr
	cd eagleplayers && bash ./compress_shr

clean:
	rm hipv kpl HippoPlayer.group

