# Experimental makefile

INCLUDE=-I$(HOME)/A/Asm/Include -I.. -I../Include 
ASM=vasmm68k_mot
EXE=-m68000 -no-opt -kick1hunks -Fhunkexe -ldots -nosym -D_test=0
EXE020=-m68020 -no-opt -kick1hunks -Fhunkexe -nosym -D_test=0
EXE020opt=-m68020 -kick1hunks -Fhunkexe -nosym -D_test=0
BIN=-m68000 -no-opt -Fbin -ldots -D_test=0
COMPRESS=shrinkler -w -p -d -9

TARGETS=\
	bin/Aon4 \
	bin/CustomMade_v1 \
	bin/DaveLowe \
	bin/Delta1 \
	bin/SidMon_v2 \
	bin/SonicArranger \
	bin/StarTrekker \
	bin/bendaglish \
	bin/bpsm \
	bin/dbpro \
	bin/digi \
	bin/fc10 \
	bin/fc14 \
	bin/future_player \
	bin/gamemusiccreator \
	bin/gluemon13 \
	bin/hippelcoso \
	bin/imploder \
	bin/jamc \
	bin/okta \
	bin/ps3m \
	bin/pumatracker \
	bin/sampleplay \
	bin/soundfx \
	bin/soundmon3 \
	bin/tfmx \
	bin/tfmx7c \
	bin/thx \
	bin/vss

COMPRESSED_TARGETS=\
	shr/Aon4.shr \
	shr/CustomMade_v1.shr \
	shr/DaveLowe.shr \
	shr/Delta1.shr \
	shr/SidMon_v2.shr \
	shr/SonicArranger.shr \
	shr/StarTrekker.shr \
	shr/bendaglish.shr \
	shr/bpsm.shr \
	shr/dbpro.shr \
	shr/digi.shr \
	shr/fc10.shr \
	shr/fc14.shr \
	shr/future_player.shr \
	shr/gamemusiccreator.shr \
	shr/gluemon13.shr \
	shr/hippelcoso.shr \
	shr/imploder.shr \
	shr/jamc.shr \
	shr/okta.shr \
	shr/ps3m.shr \
	shr/pumatracker.shr \
	shr/sampleplay.shr \
	shr/soundfx.shr \
	shr/soundmon3.shr \
	shr/tfmx.shr \
	shr/tfmx7c.shr \
	shr/thx.shr \
	shr/vss.shr \
	shr/p61a.shr \
	shr/pretracker.bin.shr

all: $(COMPRESSED_TARGETS)

clean:
	rm -f $(TARGETS) 
	rm -f $(COMPRESSED_TARGETS)

# Compile

bin/bendaglish: Benn\ Daglishv3.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/DaveLowe: Dave\ Lowe_v3.asm
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/SonicArranger: Sonic\ Arranger_v1.asm
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/Aon4: aon4channel.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/bpsm: bpsm.S	
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/CustomMade_v1: CustomMade_v1.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/dbpro: DBM0player_v2.16.s
	$(ASM) $(INCLUDE) $(EXE020opt) -nocase -o $@ "$<"
bin/Delta1: Delta1.0.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/digi: DigiBooster16.s
	$(ASM) $(INCLUDE) $(EXE020) -o $@ "$<"
bin/fc10: fc10.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/fc14: FC14.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/future_player: future_player.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/gamemusiccreator: GameMusicCreator_v1.0.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/gluemon13: gluemon13.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/hippelcoso: Hippelcoso_ahi5.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/imploder: imploder.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/jamc: jamcrackerproreplay.asm
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/okta: okta.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/ps3m: Hippo_PS3M3.s
	$(ASM) $(INCLUDE) $(EXE020) -o $@ "$<"
bin/pumatracker: Puma_Replay.S
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/sampleplay: sampleplayer6.s
	$(ASM) $(INCLUDE) $(EXE020) -o $@ "$<"
bin/SidMon_v2: SidMon_v2.0.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/soundfx: SoundFX_Optimised.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/soundmon3: SoundMon3.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/StarTrekker: StarTrekker_v1.2_AM.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/tfmx: tfmx.asm
	$(ASM) $(INCLUDE) $(BIN) -o $@ "$<"
bin/tfmx7c: tfmx7c.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"
bin/thx: thx.asm
	$(ASM) $(INCLUDE) $(BIN) -o $@ "$<"
bin/vss: vss.s
	$(ASM) $(INCLUDE) $(EXE) -o $@ "$<"

# Compress

shr/Aon4.shr:             bin/Aon4
	$(COMPRESS) "$<" "$@"
shr/CustomMade_v1.shr:    bin/CustomMade_v1
	$(COMPRESS) "$<" "$@"
shr/DaveLowe.shr:         bin/DaveLowe
	$(COMPRESS) "$<" "$@"
shr/Delta1.shr:           bin/Delta1
	$(COMPRESS) "$<" "$@"
shr/SidMon_v2.shr:        bin/SidMon_v2
	$(COMPRESS) "$<" "$@"
shr/SonicArranger.shr:    bin/SonicArranger
	$(COMPRESS) "$<" "$@"
shr/StarTrekker.shr:      bin/StarTrekker
	$(COMPRESS) "$<" "$@"
shr/bendaglish.shr:       bin/bendaglish
	$(COMPRESS) "$<" "$@"
shr/bpsm.shr:             bin/bpsm
	$(COMPRESS) "$<" "$@"
shr/dbpro.shr:            bin/dbpro
	$(COMPRESS) "$<" "$@"
shr/digi.shr:             bin/digi
	$(COMPRESS) "$<" "$@"
shr/fc10.shr:             bin/fc10
	$(COMPRESS) "$<" "$@"
shr/fc14.shr:             bin/fc14
	$(COMPRESS) "$<" "$@"
shr/future_player.shr:    bin/future_player
	$(COMPRESS) "$<" "$@"
shr/gamemusiccreator.shr: bin/gamemusiccreator
	$(COMPRESS) "$<" "$@"
shr/gluemon13.shr:        bin/gluemon13
	$(COMPRESS) "$<" "$@"
shr/hippelcoso.shr:       bin/hippelcoso
	$(COMPRESS) "$<" "$@"
shr/imploder.shr:         bin/imploder
	$(COMPRESS) "$<" "$@"
shr/jamc.shr:             bin/jamc
	$(COMPRESS) "$<" "$@"
shr/okta.shr:             bin/okta
	$(COMPRESS) "$<" "$@"
shr/ps3m.shr:             bin/ps3m
	$(COMPRESS) "$<" "$@"
shr/pumatracker.shr:      bin/pumatracker
	$(COMPRESS) "$<" "$@"
shr/sampleplay.shr:       bin/sampleplay
	$(COMPRESS) "$<" "$@"
shr/soundfx.shr:          bin/soundfx
	$(COMPRESS) "$<" "$@"
shr/soundmon3.shr:        bin/soundmon3
	$(COMPRESS) "$<" "$@"
shr/tfmx.shr:             bin/tfmx
	$(COMPRESS) "$<" "$@"
shr/tfmx7c.shr:           bin/tfmx7c
	$(COMPRESS) "$<" "$@"
shr/thx.shr:              bin/thx
	$(COMPRESS) "$<" "$@"
shr/vss.shr:              bin/vss
	$(COMPRESS) "$<" "$@"
shr/p61a.shr:             bin/p61a
	$(COMPRESS) "$<" "$@"
shr/pretracker.bin.shr:   bin/pretracker.bin
	$(COMPRESS) "$<" "$@"