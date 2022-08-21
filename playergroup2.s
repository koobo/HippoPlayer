;APS0000008C0000008C0000008C0000008C0000008C0000008C0000015D0000008C0000008C0000008C

IM=0
SHR=1
P61A=0

	incdir	include/
	include	playerIds.i

 ifnd __VASM
	auto	j\
;	auto	wb ram:HippoPlayer.group\
	auto	wb s:HippoPlayer.group\
	auto	a0\
	auto	a1\
 
	lea	start(pc),a0
	lea	pend,a1

	rts
 endif
 


start	dc.b	"HiPxPla",25	* Tunnistus ja versio, 8 bytes

head	macro
	dc.w	\1
	dc.l	\21-start
	dc.l	\22-\21
	endm



	head	pt_multi,ps3m
	head	pt_tfmx,tfmx
	head	pt_tfmx7,tfmx7c
	head	pt_jamcracker,jamc
	head	pt_future10,fc10
	head	pt_future14,fc14
	head	pt_soundmon2,bpsm
	head	pt_soundmon3,soundmon3
	head	pt_oktalyzer,okta
 ifne P61A
	head	pt_player,p61a
 endif
	head	pt_hippelcoso,hippelcoso
	head	pt_digibooster,digi
	head	pt_thx,thx
	head	pt_sample,sampleplay
	head	pt_aon,aon4
	head	pt_digiboosterpro,dbpro
	head	pt_pumatracker,pumatracker
	head	pt_gamemusiccreator,gmc
	head	pt_digitalmugician,mugician
	head	pt_medley,medley
	head	pt_futureplayer,futureplayer
	head	pt_bendaglish,bendaglish
	head	pt_sidmon2,sidmonv2
	head	pt_deltamusic1,delta1
	head	pt_soundfx,soundfx
	head	pt_gluemon,gluemon
	head	pt_pretracker,pretracker
	head	pt_custommade,custommade
	head	pt_sonicarranger,sonicarranger
	head	pt_davelowe,davelowe
	head	pt_startrekker,startrekker
	head	pt_voodoosupremesynthesizer,vss

	head	pt_synthesis,synthesis
	head	pt_syntracker,syntracker
	head	pt_robhubbard2,robhubbard2
	head	pt_chiptracker,chiptracker
	head	pt_quartet,quartet
	head	pt_facethemusic,facethemusic	
	head	pt_richardjoseph,richardjoseph
	head	pt_instereo1,instereo1
	head	pt_instereo2,instereo2
	head	pt_jasonbrooke,jasonbrooke
	head	pt_earache,earache
	head	pt_krishatlelid,krishatlelid
	head	pt_richardjoseph2,richardjoseph2
	head	pt_hippel7,hippel7
	head	pt_aprosys,aprosys
	head	pt_hippelst,hippelst
	head	pt_tcbtracker,tcbtracker
	head	pt_markcooksey,markcooksey
	head	pt_activisionpro,activisionpro
	head	pt_maxtrax,maxtrax
	head	pt_wallybeben,wallybeben
	head	pt_synthpack,synthpack
	head	pt_jeroentel,jeroentel 
	head	pt_robhubbard,robhubbard
	head	pt_sonix,sonix
	head	pt_coredesign,coredesign
	head	pt_quartetst,quartetst
	head	pt_digitalmugician2,digitalmugician2
	head	pt_musicmaker4,musicmaker4
	head	pt_musicmaker8,musicmaker8
	head	pt_soundcontrol,soundcontrol
	head	pt_stonetracker,stonetracker
	head	pt_themusicalenlightenment,tme
	head	pt_timfollin2,timfollin2
	head	pt_steveturner,steveturner
	head	pt_jasonpage,jasonpage
	head	pt_specialfx,specialfx
	head	pt_davidwhittaker,davidwhittaker

	dc	0
	dc.l	0,0

headend

 ifne IM
	incdir	pl/im/

ps3m1 incbin	ps3m.im
ps3m2

tfmx1 incbin tfmx.im
tfmx2 

tfmx7c1 incbin tfmx7c.im
tfmx7c2

jamc1 incbin jamc.im
jamc2

fc101 incbin fc10.im
fc102 

fc141 incbin fc14.im
fc142 

bpsm1 incbin bpsm.im
bpsm2 

soundmon31 incbin soundmon3.im
soundmon32 

okta1 incbin okta.im
okta2 

 ifne P61A
p61a1 incbin p61a.im
p61a2
 endif

hippelcoso1 incbin hippelcoso.im
hippelcoso2

digi1 incbin digi.im
digi2 

thx1 incbin thx.im
thx2 

sampleplay1 incbin sampleplay.im
sampleplay2 

aon41
	incbin aon4.im
aon42

dbpro1
	incbin dbpro.im
dbpro2 

pumatracker1 
	incbin pumatracker.im
pumatracker2 

gmc1
	incbin gamemusiccreator.im
gmc2 

medley1 
	incbin imploder.im
medley2

futureplayer1 
	incbin future_player.im
futureplayer2 

bendaglish1 
	incbin bendaglish.im
bendaglish2 

sidmonv21
	incbin sidmon_v2.im
sidmonv22

delta11 
	incbin delta1.im
delta12

soundfx1
	incbin soundfx.im
soundfx2 

gluemon1 
	incbin gluemon13.im
gluemon2

pretracker1 
	incbin pretracker.bin.im
pretracker2 

custommade1 
	incbin custommade_v1.im
custommade2 

sonicarranger1
	incbin sonicarranger.im
sonicarranger2

davelowe1
	incbin davelowe.im
davelowe2 

startrekker1 
	incbin startrekker.im
startrekker2

vss1
	incbin	vss.im
vss2
  endif

  ifne SHR
 	incdir	pl/shr/

ps3m1 incbin	ps3m.shr
ps3m2

tfmx1 incbin tfmx.shr
tfmx2 

tfmx7c1 incbin tfmx7c.shr
tfmx7c2

jamc1 incbin jamc.shr
jamc2

fc101 incbin fc10.shr
fc102 

fc141 incbin fc14.shr
fc142 

bpsm1 incbin bpsm.shr
bpsm2 

soundmon31 incbin soundmon3.shr
soundmon32 

okta1 incbin okta.shr
okta2 

 ifne P61A
p61a1 incbin p61a.shr
p61a2
 endif

hippelcoso1 incbin hippelcoso.shr
hippelcoso2

digi1 incbin digi.shr
digi2 

thx1 incbin thx.shr
thx2 

sampleplay1 incbin sampleplay.shr
sampleplay2 

aon41
	incbin aon4.shr
aon42

dbpro1
	incbin dbpro.shr
dbpro2 

pumatracker1 
	incbin pumatracker.shr
pumatracker2 

gmc1
	incbin gamemusiccreator.shr
gmc2 

medley1 
	incbin imploder.shr
medley2

futureplayer1 
	incbin future_player.shr
futureplayer2 

bendaglish1 
	incbin bendaglish.shr
bendaglish2 

sidmonv21
	incbin sidmon_v2.shr
sidmonv22

delta11 
	incbin delta1.shr
delta12

soundfx1
	incbin soundfx.shr
soundfx2 

gluemon1 
	incbin gluemon13.shr
gluemon2

pretracker1 
	incbin pretracker.bin.shr
pretracker2 

custommade1 
	incbin custommade_v1.shr
custommade2 

sonicarranger1
	incbin sonicarranger.shr
sonicarranger2

davelowe1
	incbin davelowe.shr
davelowe2 

startrekker1 
	incbin startrekker.shr
startrekker2

vss1
	incbin	vss.shr
vss2
	endif

 ifne IM
	incdir	eagleplayers/im/

synthesis1
	incbin "synth 4.0.im"
synthesis2

syntracker1
	incbin syntracker.im
syntracker2

robhubbard21
	incbin "rob hubbard 2.im"
robhubbard22

chiptracker1
	incbin chiptracker.im
chiptracker2

quartet1
	incbin quartet.im
quartet2

facethemusic1
	incbin "face the music.im"
facethemusic2

richardjoseph1
	incbin "richard joseph player.im"
richardjoseph2

instereo11
	incbin "in stereo 1.0.im"
instereo12

instereo21
	incbin "in stereo 2.0.im"
instereo22

jasonbrooke1
	incbin "jason brooke.im"
jasonbrooke2

earache1
	incbin earache.im
earache2

krishatlelid1
	incbin "kris hatlelid.im"
krishatlelid2

richardjoseph21
	incbin "richard joseph.im"
richardjoseph22

hippel71
	incbin "jochen hippel 7v.im"
hippel72

aprosys1
	incbin aprosys.im
aprosys2

hippelst1
	incbin "jochen hippel st.im"
hippelst2

tcbtracker1
	incbin "tcb tracker.im"
tcbtracker2

markcooksey1
;	incbin "mark cooksey.im"
markcooksey2

activisionpro1
	incbin "activision pro.im"
activisionpro2

maxtrax1
	incbin maxtrax.im
maxtrax2

wallybeben1
	incbin "wally beben.im"
wallybeben2

synthpack1
	incbin "synth pack.im"
synthpack2

jeroentel1
	incbin "jeroen tel.im"
jeroentel2

robhubbard1
	incbin "rob hubbard.im"
robhubbard2

sonix1
	incbin "sonix music driver.im"
sonix2

coredesign1
;	incbin "core design.im"
coredesign2

quartetst1
	incbin "quartet st.im"
quartetst2

digitalmugician21
	incbin "mugician ii.im"
digitalmugician22

mugician1 
	incbin "mugician.amp.im"
mugician2 

musicmaker41
	incbin musicmaker4.im
musicmaker42

musicmaker81
	incbin musicmaker8.im
musicmaker82

soundcontrol1
	incbin soundcontrol.im
soundcontrol2

stonetracker1
	incbin eaglestone.im
stonetracker2

tme1
	incbin	tme.im
tme2

timfollin21
	incbin	"tim follin ii.im"
timfollin22	
 	endif


  ifne SHR
	incdir	eagleplayers/shr/

synthesis1
	incbin "synth 4.0.shr"
synthesis2

syntracker1
	incbin syntracker.shr
syntracker2

robhubbard21
	incbin "rob hubbard 2.shr"
robhubbard22

chiptracker1
	incbin chiptracker.shr
chiptracker2

quartet1
	incbin quartet.shr
quartet2

facethemusic1
	incbin "face the music.shr"
facethemusic2

richardjoseph1
	incbin "richard joseph player.shr"
richardjoseph2

instereo11
	incbin "in stereo 1.0.shr"
instereo12

instereo21
	incbin "in stereo 2.0.shr"
instereo22

jasonbrooke1
	incbin "jason brooke.shr"
jasonbrooke2

earache1
	incbin earache.shr
earache2

krishatlelid1
	incbin "kris hatlelid.shr"
krishatlelid2

richardjoseph21
	incbin "richard joseph.shr"
richardjoseph22

hippel71
	incbin "jochen hippel 7v.shr"
hippel72

aprosys1
	incbin aprosys.shr
aprosys2

hippelst1
	incbin "jochen hippel st.shr"
hippelst2

tcbtracker1
	incbin "tcb tracker.shr"
tcbtracker2

markcooksey1
;	incbin "mark cooksey.amp.shr"
	incbin "mark cooksey.shr"
markcooksey2

activisionpro1
	incbin "activision pro.shr"
activisionpro2

maxtrax1
	incbin maxtrax.shr
maxtrax2

wallybeben1
	incbin "wally beben.shr"
wallybeben2

synthpack1
	incbin "synth pack.shr"
synthpack2

jeroentel1
	incbin "jeroen tel.shr"
jeroentel2

robhubbard1
	incbin "rob hubbard.shr"
robhubbard2

sonix1
	incbin "sonix music driver.shr"
sonix2

coredesign1
;	incbin "core design.shr"
coredesign2

quartetst1
	incbin "quartet st.shr"
quartetst2

digitalmugician21
	incbin "mugician ii.shr"
digitalmugician22

mugician1 
	incbin "mugician.amp.shr"
mugician2 

musicmaker41
	incbin musicmaker4.shr
musicmaker42

musicmaker81
	incbin musicmaker8.shr
musicmaker82

soundcontrol1
	incbin soundcontrol.shr
soundcontrol2

stonetracker1
	incbin eaglestone.shr
stonetracker2

tme1
	incbin	tme.shr
tme2

timfollin21
	incbin	"tim follin ii.shr"
timfollin22	
	endif


steveturner1
	incbin	"steve turner.shr"
steveturner2


jasonpage1
	incbin	"jason page.shr"
jasonpage2


specialfx1
	incbin	"special fx.shr"
specialfx2

davidwhittaker1
	incbin	"david whittaker.shr"
davidwhittaker2


pend
