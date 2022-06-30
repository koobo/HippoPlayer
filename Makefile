INCLUDE=-I$(HOME)/A/Asm/Include -I$(HOME)/H -I$(HOME)/H/Include 
VPATH = ./pl:./pl2


#EPs0=$(shell find eagleplayers/bin/ -type f | sed 's/ /\\ /g')
#EPs0=$(shell find eagleplayers/bin/ -type f | sed 's/ /X/g')


#src=$(shell find Photos/ -iname '*.JPG' | sed 's/ /\\ /g')
#
#out=$(subst Photos,Compressed,$(src))
#
#all : $(out)
#
#Compressed:
#  @mkdir Compressed
#
#Compressed/%: Photos/% Compressed
#  @echo "Compressing $<"
#  @convert "$<" -scale 20% "$@"



EPs := $(wildcard eagleplayers/bin/*)
EPs := $(filter-out eagleplayers/bin/%.uaem, $(EPs))
EPs := $(filter-out eagleplayers/bin/%.md, $(EPs))
EPs := $(filter-out eagleplayers/bin/%~, $(EPs))
EPs2 := $(subst bin,shr,$(EPs))
EPs2 := $(addsuffix .shr,$(EPs2))
#EPs4 := $(subst eagleplayers/,,$(EPs))

# Create output directory
eagleplayers/shr:
	mkdir -p eagleplayers/shr

# $@ = target being generated
# $< = prequisite for generating target
eagleplayers/shr/%: 
#$(EPs) eagleplayers/shr 
#	@echo "prereq " $<
#	@echo "target " $@
#	@echo "prereq " $(subst eagleplayers/,,$<)
	@echo "target " $(subst .shr,,$(subst eagleplayers/shr,bin,$@))
#cd eagleplayers && ../shrinkle.sh  $(subst .shr,,$(subst eagleplayers/shr,bin,$@))

bob: $(EPs2)
	@echo $(EPs2)
	@echo BOBBB

bob2: pl/bin/ps3m2
	@echo BABB

bob3:
	echo $(VPATH)

pl/bin/ps3m2: Hippo_PS3M.s
	@echo bobobo
	@echo prereq $<
	@echo target $@


#eagleplayers/shr/%: eagleplayers/shr $(EPs2)



#CompressedEPs = eagleplayers/shr/activision\ pro.shr\
#				eagleplayers/shr/aprosys.shr\
#				eagleplayers/shr/chiptracker.shr\
#				eagleplayers/shr/david\ whittaker.shr\
#				eagleplayers/shr/eaglestone.shr\
#				eagleplayers/shr/earache.shr\
#				eagleplayers/shr/face\ the\ music.shr\
#				eagleplayers/shr/in\ stereo\ 1.0.shr\
#				eagleplayers/shr/in\ stereo\ 2.0.shr\
#				eagleplayers/shr/jason\ brooke.shr\
#				eagleplayers/shr/jason\ page.shr\
#				eagleplayers/shr/jeroen\ tel.shr\
#				eagleplayers/shr/jochen\ hippel\ 7v.shr\
#				eagleplayers/shr/jochen\ hippel\ st.shr\
#				eagleplayers/shr/kris\ hatlelid.shr\
#				eagleplayers/shr/mark\ cooksey.shr\
#				eagleplayers/shr/mark\ cooksey.amp.shr\
#				eagleplayers/shr/maxtrax.shr\
#				eagleplayers/shr/mugician\ ii.shr\
#				eagleplayers/shr/mugician.amp.shr\
#				eagleplayers/shr/musicmaker4.shr\
#				eagleplayers/shr/musicmaker8.shr\
#				eagleplayers/shr/quartet.shr\
#				eagleplayers/shr/quartet\ st.shr\
#				eagleplayers/shr/richard\ joseph.shr\
#				eagleplayers/shr/richard\ joseph\ player.shr\
#				eagleplayers/shr/rob\ hubbard.shr\
#				eagleplayers/shr/rob\ hubbard\ 2.shr\
#				eagleplayers/shr/sonix\ music\ driver.shr\
#				eagleplayers/shr/soundcontrol.shr\
#				eagleplayers/shr/special\ fx.shr\
#				eagleplayers/shr/steve\ turner.shr\
#				eagleplayers/shr/synth\ 4.0.shr\
#				eagleplayers/shr/synth\ pack.shr\
#				eagleplayers/shr/syntracker.shr\
#				eagleplayers/shr/tcb\ tracker.shr\
#				eagleplayers/shr/tim\ follin\ ii.shr\
#				eagleplayers/shr/tme.shr\
#				eagleplayers/shr/wally\ beben.shr

info:
	@echo $(EPs2)

	

hipvasm: HippoPlayer.group kpl playerIds.i
	#vasmm68k_mot $(INCLUDE) -m68000 -showcrit -showopt -Fbin -o hipvasm -nosym puu016.s
	vasmm68k_mot $(INCLUDE) -m68000 -no-opt -kick1hunks -Fhunkexe -o hipvasm -nosym puu016.s

clean:
	rm hipvasm kpl HippoPlayer.group eagleplayers/shr/maxtrax.shr

kpl: kpl14.s
	vasmm68k_mot $(INCLUDE) -m68000 -no-opt -Fbin -o kpl kpl14.s

HippoPlayer.group: playergroup2.s playerIds.i
#	$(CompressedEPs) 
	vasmm68k_mot $(INCLUDE) -m68000 -no-opt -Fbin -o HippoPlayer.group playergroup2.s

#eagleplayers/shr/maxtrax.shr: eagleplayers/bin/maxtrax
#	cd eagleplayers && ../shrinkle.sh bin/maxtrax
#
#eagleplayers/shr/activision\ pro.shr: eagleplayers/bin/activision\ pro
#	cd eagleplayers && ../shrinkle.sh "bin/activision pro"

#eagleplayers/shr/activision pro
#eagleplayers/shr/aprosys
#eagleplayers/shr/chiptracker
#eagleplayers/shr/david whittaker
#eagleplayers/shr/eaglestone
#eagleplayers/shr/earache
#eagleplayers/shr/face the music
#eagleplayers/shr/in stereo 1.0
#eagleplayers/shr/in stereo 2.0
#eagleplayers/shr/jason brooke
#eagleplayers/shr/jason page
#eagleplayers/shr/jeroen tel
#eagleplayers/shr/jochen hippel 7v
#eagleplayers/shr/jochen hippel st
#eagleplayers/shr/kris hatlelid
#eagleplayers/shr/mark cooksey
#eagleplayers/shr/mark cooksey.amp
#eagleplayers/shr/maxtrax
#eagleplayers/shr/mugician ii
#eagleplayers/shr/mugician.amp
#eagleplayers/shr/musicmaker4
#eagleplayers/shr/musicmaker8
#eagleplayers/shr/quartet
#eagleplayers/shr/quartet st
#eagleplayers/shr/richard joseph
#eagleplayers/shr/richard joseph player
#eagleplayers/shr/rob hubbard
#eagleplayers/shr/rob hubbard 2
#eagleplayers/shr/sonix music driver
#eagleplayers/shr/soundcontrol
#eagleplayers/shr/special fx
#eagleplayers/shr/steve turner
#eagleplayers/shr/synth 4.0
#eagleplayers/shr/synth pack
#eagleplayers/shr/syntracker
#eagleplayers/shr/tcb tracker
#eagleplayers/shr/tim follin ii
#eagleplayers/shr/tme
#eagleplayers/shr/wally beben

#eagleplayers/shr/activision\ pro.shr\
#eagleplayers/shr/aprosys.shr\
#eagleplayers/shr/chiptracker.shr\
#eagleplayers/shr/david\ whittaker.shr\
#eagleplayers/shr/eaglestone.shr\
#eagleplayers/shr/earache.shr\
#eagleplayers/shr/face\ the\ music.shr\
#eagleplayers/shr/in\ stereo\ 1.0.shr\
#eagleplayers/shr/in\ stereo\ 2.0.shr\
#eagleplayers/shr/jason\ brooke.shr\
#eagleplayers/shr/jason\ page.shr\
#eagleplayers/shr/jeroen\ tel.shr\
#eagleplayers/shr/jochen\ hippel\ 7v.shr\
#eagleplayers/shr/jochen\ hippel\ st.shr\
#eagleplayers/shr/kris\ hatlelid.shr\
#eagleplayers/shr/mark\ cooksey.shr\
#eagleplayers/shr/mark\ cooksey.amp.shr\
#eagleplayers/shr/maxtrax.shr\
#eagleplayers/shr/mugician\ ii.shr\
#eagleplayers/shr/mugician.amp.shr\
#eagleplayers/shr/musicmaker4.shr\
#eagleplayers/shr/musicmaker8.shr\
#eagleplayers/shr/quartet.shr\
#eagleplayers/shr/quartet\ st.shr\
#eagleplayers/shr/richard\ joseph.shr\
#eagleplayers/shr/richard\ joseph\ player.shr\
#eagleplayers/shr/rob\ hubbard.shr\
#eagleplayers/shr/rob\ hubbard\ 2.shr\
#eagleplayers/shr/sonix\ music\ driver.shr\
#eagleplayers/shr/soundcontrol.shr\
#eagleplayers/shr/special\ fx.shr\
#eagleplayers/shr/steve\ turner.shr\
#eagleplayers/shr/synth\ 4.0.shr\
#eagleplayers/shr/synth\ pack.shr\
#eagleplayers/shr/syntracker.shr\
#eagleplayers/shr/tcb\ tracker.shr\
#eagleplayers/shr/tim\ follin\ ii.shr\
#eagleplayers/shr/tme.shr\
#eagleplayers/shr/wally\ beben.shr