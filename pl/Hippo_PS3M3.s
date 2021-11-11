;APS0001A9E30000D8E2000034AA00002D1C000000000000000000000000000000000000000000000000
* Uusin.
* Tämä on käytössä

;PS3M 0.960 020+ 14-bit stereo surround version ;) 22.02.1996
;Copyright (c) Jarno Paananen a.k.a. Guru / S2 1994-95

;Some portions based on STMIK 0.9ß by Sami Tammilehto / PSI of Future Crew

;ASM-ONE 1.20 or newer is required unless disable020 is set to 1, when
;at least 1.09 (haven't tried older) is sufficient.

DEBUG	=	0
TEST 	= 	1


* Print to debug console, very clever.
* Param 1: string
* d0-d6:    formatting parameters, d7 is reserved
DPRINT macro
	ifne DEBUG
	jsr	desmsgDebugAndPrint
  dc.b 	\1,10,0
  even
	endc
	endm

CHECKCRC	=	$FB289E39	; tekstien tarkistussumma


MONO = 1
STEREO = 2
SURROUND = 3
REAL = 4
STEREO14 = 5

mtS3M = 1
mtMOD = 2
mtMTM = 3
mtXM  = 4

ENABLED = 0
DISABLED = 1

BUFFER = 16*1024				; MUST BE 2^N
						; MIN 4K
debug = 0
allocchans = 1
disable020 = 0

ier_nomem	=	-9
ier_noprocess	=	-13
ier_ahi		=	-19

	incdir	include:

	include	exec/exec_lib.i
	include	exec/execbase.i
	include	exec/memory.i

	include	graphics/gfxbase.i
	include	graphics/graphics_lib.i
	include	intuition/intuition_lib.i

	include	dos/dos_lib.i
	include	dos/dos.i

	include	hardware/intbits.i
	include	resources/cia_lib.i

	include	exec/io.i

	include	devices/ahi_lib.i
	include	devices/ahi.i

	include	misc/eagleplayer.i

	include	Guru.i
	include	ps3m.i
	include	mucro.i



iword	macro
	ror	#8,\1
	endm

ilword	macro
	ror	#8,\1
	swap	\1
	ror	#8,\1
	endm

tlword	macro
	move.b	\1,\2
	ror.l	#8,\2
	move.b	\1,\2
	ror.l	#8,\2
	move.b	\1,\2
	ror.l	#8,\2
	move.b	\1,\2
	ror.l	#8,\2
	endm

tword	macro
	move.b	\1,\2
	ror	#8,\2
	move.b	\1,\2
	ror	#8,\2
	endm

;sVER	macro
;	dc.b	`Replay version 0.942/020+ / 30.10.1994 `,10,10
;	endm


 ifne TEST
TESTMODE
	move.l	4.w,a6
	lea	.dosname(pc),a1
	lob	OldOpenLibrary
	move.l	d0,._DosBase
	lea	.gfxname(pc),a1
	lob	OldOpenLibrary
	move.l	d0,._GfxBase

	* cybercalib: false
	moveq	#0,d0
	moveq	#0,d1
	* ahi_use: false
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,D5
	moveq	#0,D6
	move.l	#moduleE-module,D7
	lea	.ps3m_mname(pc),a0
	lea	.ps3m_numchans(pc),a1
	lea	.ps3m_mtype(pc),a2
	lea	.ps3m_samples(pc),a3
	lea	.ps3m_xm_insts(pc),a4
	jsr	init1j

	lea	.ps3m_buff1(pc),a0
	lea	.ps3m_buff2(pc),a1
	lea	.ps3m_mixingperiod(pc),a2
	lea	.ps3m_playpos(pc),a3
	lea	.ps3m_buffSizeMask(pc),a4
	jsr	init2j

	* mix rate
	move.l	#15000,d0
	* volume boost
	moveq	#3,d1
	* mode
;	moveq	#sm_stereo,d3
	moveq	#2,d3
	* priority, killer
	moveq	#2,d4
	* mod address
	move.l	#module,d2
	* mixing buffer size, shift for 4096
	* 3 = 32 kB (MAX)
	moveq	#3,d5
	lea	.playing(pc),a0
	lea	.dummyFunc(pc),a1
	lea	.volume(pc),a2
	move.l	._DosBase(pc),a3
	lea	.songover(pc),a4
	move.l	._GfxBase(pc),a6
	move.l	#.songpos,d6
	move.l	#.dummyFunc,d7
	pea	.dummyFunc(pc)
	jsr	init0j
	addq	#4,sp
	; playing
	jsr	endj	

	
	rts

.gfxname	dc.b	"graphics.library",0
.dosname	dc.b	"dos.library",0
 even

._DosBase	dc.l 	0 
._GfxBase	dc.l	0
.songpos	dc.l 	0
.songover	dc 	0
.volume		dc	64
.dummyFunc	rts
.dummy  	dc 	0

.playing	dc.w	-1
 
.ps3m_mname 	dc.l 	0
.ps3m_numchans	dc.l 	0 
.ps3m_mtype 	dc.l	0
.ps3m_samples 	dc.l 	0
.ps3m_xm_insts 	dc.l 	0

.ps3m_buff1	dc.l 	0
.ps3m_buff2	dc.l 	0
.ps3m_mixingperiod dc.l 0
.ps3m_playpos 	dc.l	0
.ps3m_buffSizeMask dc.l 0

	section	mod,data_p
module	
;	incbin	"m:multichannel/title.mod"
	incbin	"m:multichannel/approaching antares.mod"
moduleE
	section	co,code_p
 endc



	dc.l	16
s3m_segment
	dc.l	0
	jmp	s3m_code


init1j	jmp	init1r(pc)
init2j	jmp	init2r(pc)
init0j	jmp	s3init(pc)
poslenj	jmp	s3poslen(pc)
endj	jmp	s3end(pc)
stopj	jmp	s3stop(pc)
contj	jmp	s3cont(pc)
eteenj	jmp	eteen(pc)
taaksej	jmp	taakse(pc)
volj	jmp	s3vol(pc)
vboostj	jmp	boosto(pc)

inforivit	dc.l	0
var_playing	dc.l	0
var_volume	dc.l	0
_DosBase
dosbase		dc.l	0
songoverf	dc.l	0
gfxbase		dc.l	0
poslen		dc.l	0
adjustroutine	dc.l	0
voluproutine	dc.l	0
s3mmode1a	dc.b	0

ahi_use		dc.b	0
ahi_rate	dc.l	0
ahi_mastervol	dc	0
ahi_stereolev	dc	0
ahi_mode	dc.l	0


init1r

	move.l	#mname,(a0)
	move.l	#numchans,(a1)
	move.l	#mtype,(a2)
	move.l	#samples,(a3)
	move.l	#xm_insts,(a4)

	move.b	d0,CyberCalibration
	move.l	d1,CyberTable


*** ahi-tiedot
;	moveq	#-1,d2
;	move.l	#28000,d3
;	move	#1000,d4

* d5 = stereolev 0-100, muutetaan 0-$8000
	mulu	#$8000,d5
	divu	#100,d5

;	move.l	#$0002000a,d6	* 8 bit stereo

	move.b	d2,ahi_use
	move.l	d3,ahi_rate
	move	d4,ahi_mastervol
	move	d5,ahi_stereolev
	move.l	d6,ahi_mode

	move.l	d7,setmodulelen
	rts

init2r	

*******************************************************************************
* lasketaan tekstien tarkistussumma

;TABSIZE		=	256
;CRC_32          =	$edb88320    * CRC-32 polynomial *
;INITCRC		=	$ffffffff

; 	pushm	d2-a6
; 	move.l	d0,a0
; 	move.l	#1998,d0

; 	pushm	d0/a0
; 	move.l	#TABSIZE*4,d0
; 	moveq	#MEMF_PUBLIC,d1
; 	move.l	4.w,a6
; 	lob	AllocMem
; 	move.l	d0,a3

; ** make crc table

; 	move.l	a3,a0
; 	moveq	#0,d4
; .loop	move.l	d4,d0
; 	moveq	#0,d1		* accum = 0
; 	lsl.l	#1,d0		* item <<=1
; 	moveq	#8-1,d2		* for (i = 8;  i > 0;  i--) {
; .loop2	lsr.l	#1,d0		* item >>=1
; 	move.l	d0,d3
; 	eor.l	d1,d3
; 	and	#1,d3		* if ((item ^ accum) & 0x0001)
; 	beq.b	.else
; 	lsr.l	#1,d1
; 	eor.l	#CRC_32,d1	* accum = (accum >> 1) ^ CRC_32;
; 	bra.b	.o
; .else	lsr.l	#1,d1		* accum>>=1
; .o	dbf	d2,.loop2
; 	move.l	d1,(a0)+
; 	addq	#1,d4
; 	cmp	#TABSIZE,d4
; 	bne.b	.loop
; 	popm	d0/a0

; ** calc crc
; 	moveq	#INITCRC,d7
; 	move.l	#$ff,d1
; .oop	move.l	d7,d6
; 	lsr.l	#8,d6
; 	move.b	(a0)+,d5
; 	eor.l	d7,d5
; 	and.l	d1,d5
; 	lsl.l	#2,d5
; 	move.l	(a3,d5),d5
; 	eor.l	d5,d6
; 	move.l	d6,d7
; 	subq.l	#1,d0
; 	bne.b	.oop
; 	move.l	a3,a1
; 	move.l	#4*TABSIZE,d0
; 	lob	FreeMem

; *	cmp.l	#CHECKCRC,d7
; *	beq.b	.jeez
; *.douch	move	$dff006,$dff180
; *	bra.b	.douch
; *.jeez

;	popm	d2-a6
*******************************************************************************

	move.l	#buff1,(a0)
	move.l	#buff2,(a1)
	move.l	#mixingperiod,(a2)
	move.l	#playpos,(a3)
	move.l	#buffSizeMask,(a4)
	move.l	#cha0,d0
	rts

*** päivitysrutiini

boosto
	tst.b	ahi_use
	bne.w	ahi_update

	move.b	d0,vboost+3
	lea	data,a5
	bra.w	makedivtabs

s3poslen
	move.l	poslen(pc),a0
	move	PS3M_position,(a0)+
	move	positioneita,(a0)
	rts


s3init	

	move.l	4(sp),voluproutine

	pushm	d1-d7/a1-a6

	clr	PS3M_eject
	clr	PS3M_position
	clr	PS3M_wait
	clr	PS3M_play
	clr	PS3M_initialized

	move.l	d7,adjustroutine
	move.l	d6,poslen

	move.l	d0,mixingrate
	move.b	d1,vboost+3
	move.l	d2,s3m
	move.l	d2,setmodule
	move	d3,pmode
	move.b	d4,s3mmode1a

	move.l	a0,var_playing
	move.l	a1,inforivit
	move.l	a2,var_volume
	move.l	a3,dosbase
	move.l	a4,songoverf
	move.l	a6,gfxbase

;	DPRINT	"s3init"

	tst.b	ahi_use
	bne.w	ahi_init

	clr	system
	cmp.b	#5,d4
	bne.b	.fr
	move	#1,system		* killer!
.fr
	push	d5
	bsr.w	init

	bsr.w	s3vol

 ifeq TEST
	move	numchans,d0
	move.l	adjustroutine(pc),a5	* rutiini joka antaa uudet parametrit
	jsr	(a5)			* kanavien määrästä ja tunen nimestä
	beq.b	.noadj			* riippuen
	move.l	d0,mixingrate
	move.b	d1,vboost+3
	move	d3,pmode
	move.b	d4,s3mmode1a
 endc
	clr	system
	cmp.b	#5,d4
	bne.b	.fr2
	move	#1,system		* killer!
.fr2
.noadj

	pop	d5

	lea	data,a5
	basereg	data,a5

;	move.b	ps3mb+var_b,d1
	move.l	#4096,d0
	lsl.l	d5,d0

;	move.l	#BUFFER,d0
	move.l	d0,buffSize(a5)
	subq.l	#1,d0
	move.l	d0,buffSizeMask(a5)
	lsl.l	#8,d0
	move.b	#$ff,d0
	move.l	d0,buffSizeMaskFF

	move.l	buffSize(a5),d0
	DPRINT 	"buffSize=%lx"

	move.l	4.w,a6

	move.l	#1024*4*2,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	lob	AllocMem
	move.l	d0,tbuf(a5)
	beq.w	.memerr
	add.l	#1024*4,d0
	move.l	d0,tbuf2(a5)	

	move.l	buffSize(a5),d0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	lob	AllocMem
	move.l	d0,buff1(a5)
	beq.w	.memerr

	move.l	buffSize(a5),d0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	lob	AllocMem
	move.l	d0,buff2(a5)
	beq.w	.memerr

	move.l	#66*256,d7			; Volume tab size

	cmp	#REAL,pmode(a5)
	beq.b	.varaa
	cmp	#STEREO14,pmode(a5)
	bne.b	.ala2

.varaa	move.l	buffSize(a5),d0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	lob	AllocMem
	move.l	d0,buff3(a5)
	beq.b	.memerr

	move.l	buffSize(a5),d0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	lob	AllocMem
	move.l	d0,buff4(a5)
	beq.b	.memerr

.ala2	cmp	#STEREO14,pmode(a5)
	beq.b	.bit14

	moveq	#0,d0
	move	maxchan(a5),d1
	move.l	#256,d2
	subq	#1,d1
.l	add.l	d2,d0
	add.l	#256,d2
	dbf	d1,.l

	move.l	d0,dtabsize(a5)
	moveq	#MEMF_PUBLIC,d1
	lob	AllocMem
	move.l	d0,dtab(a5)
	beq.b	.memerr	
	bra.b	.alavaraa

.bit14	move.l	#66*256*2,d7			; Volume tab size

	move.l	#64*1024,d0

	tst.b	CyberCalibration(a5)
	beq.b	.nocyb
	add.l	d0,d0
.nocyb
	moveq	#MEMF_PUBLIC,d1
	lob	AllocMem
	move.l	d0,buff14(a5)
	bne.b	.alavaraa

.memerr	bsr.w	s3end
	popm	d1-a6
	moveq	#ier_nomem,d0
	rts

.alavaraa
	move.l	d7,d0
	moveq	#MEMF_PUBLIC,d1
	lob	AllocMem
	move.l	d0,vtab(a5)
	beq.b	.memerr

	add.l	#255,d0
	and.l	#~$ff,d0
	move.l	d0,vtabaddr(a5)

	cmp	#1,system(a5)
	bne.b	.syssy

	clr	PS3M_cont(a5)

	clr	PS3M_eject(a5)
	clr	PS3M_position(a5)
	st 	PS3M_play(a5)

.kala	
	bsr.w	s3mPlay
	bsr.w	s3end
	move.l	var_playing(pc),a0
	clr.b	(a0)
	move.l	inforivit(pc),a0
	jsr	(a0)
	moveq	#0,d0
	popm	d1-a6
	move	#333,d0		* killeri lopettanut
	rts

.syssy	clr	PS3M_cont(a5)

	endb	a5


	move.l	dosbase(pc),a6
	move.l	#.s3mprocname,d1

	moveq	#0,d2
	move.b	s3mmode1a(pc),d2
	move.b	.prit(pc,d2),d2
	ext	d2
	ext.l	d2

 ifne TEST
	jsr	s3m_code
 else
	move.l	#s3m_segment,d3
	lsr.l	#2,d3
	move.l	#3000,d4
	lob	CreateProc
	tst.l	d0
	bne.b	.ne
	moveq	#ier_noprocess,d0
	bsr.w	s3end
	bra.b	.en
.ne	
	moveq	#0,d0
.en 
	bsr	PatternInit
 endif 

	popm	d1-d7/a1-a6
	rts

.prit	dc.b	-10,-1,0,1,9

.s3mprocname dc.b "HiP-PS3M",0
 even



* current playback position = playpos/mrate50 
* data write position = 
*    (playpos + bufferSize) & buffSizeMaskFF
*    /mrate50
* data write position should be IN FRONT of playback
* position as much as it takes for mix buffer to
* play through, bufferSize/mrate50 ticks.

* write stripe data to data write pos

* Set active song and pattern position
* in:
*   d0 = song pos
*   d1 = pattern pos
pushPatternInfo
	movem 	d0/d1,activeSongPos
	rts

	basereg	data,a5

* Get info related to what is currently being played
* out:
*  d0 = song position 
*  d1 = pattern position
getPatternInfo
	pushm	d2/d3/d4/a0
	move.l	playpos(a5),d3
	move.l	mrate50(a5),d4
	lsr.l	#8,d4
	divu	d4,d3
	lsr	#8,d3
	
	lea	patternInfoBuffer(a5),a0
	lsl	#2,d3
	add.w	d3,a0	

 if DEBUG
	moveq	#0,d0 
	move	d3,d0
	lsr		#2,d0
	move.l	playpos(a5),d1
	lsr.l	#8,d1
	moveq	#0,d2
	moveq	#0,d3
	movem	(a0),d2/d3
	DPRINT	"Read idx=%03ld ppos=%04lx song=%02ld pat=%02ld"
 endif 

	movem	(a0),d0/d1

	popm	d2/d3/d4/a0
	rts

updatePatternInfoBuffer
	* This stores the currently active positions
	* into the buffer, ahead of time relative
	* to what is being played.

	pushm 	d1-d3/a0
	
	move.l	playpos(a5),d0
	move.l	mrate50(a5),d1
	lsr.l	#8,d1
	divu	d1,d0
	lsr.w	#8,d0
	
	* pick the previous slot, that is farthest from the current
	* position timewise.

	subq	#1,d0

 if DEBUG
	ext.l	d0
	move.l	playpos(a5),d1
	lsr.l	#8,d1
	moveq	#0,d2
	move	activeSongPos(a5),d2
	moveq	#0,d3
	move	activePattPos(a5),d3
	DPRINT	"Push idx=%03ld ppos=%04lx song=%02ld pat=%02ld"
 endif

	lea	patternInfoBuffer(a5),a0 
	* times 4 since it's 4 bytes
	asl	#2,d0
	add.w	d0,a0

	move	activeSongPos(a5),(a0)+
	move	activePattPos(a5),(a0)+
	
	popm	d1-d3/a0
	rts	


updatePatternInfoData
	* This updates the information that
	* corresponds to what is being played currently

	cmp	#mtMOD,mtype
	beq.b	.mod 
	rts 
.mod
	pushm	d0/d1/a0-a2

	move.l	mt_songdataptr(pc),a0
	lea	952(a0),a2	;pattpo
	lea	1084(a0),a0	;patterndata

	bsr.w	getPatternInfo
	* d0 = song pos
	* d1 = patt pos
	move	d1,PatternInfo+PI_Pattpos

	moveq	#0,d1
	move.b	(a2,d0),d1
	lsl.w	#8,d1
	mulu	numchans(a5),d1

	* Start of pattern corresponding to this song pos
	lea	(a0,d1.l),a0 

	move	numchans(a5),d0
	subq	#1,d0
	lea	Stripe1(pc),a1
.stripes
	move.l	a0,(a1)+
	addq	#4,a0
	dbf	d0,.stripes

	popm	d0/d1/a0-a2
	rts
 
 endb a5
 



s3vol	
	move.l	var_volume(pC),a0
	move	(a0),PS3M_master
	rts


s3stop	
	tst.b	ahi_use
	bne.w	ahi_stop

	pushm	all
	lea	data,a5
	st	PS3M_paused-data(a5)
	bsr.w	PS3M_pause
	st	jjo
	popm	all
	rts


s3cont	tst.b	ahi_use
	bne.w	ahi_cont

	tst	jjo
	bne.b	.jm
	rts
.jm	pushm	all
	lea	data,a5
	clr	PS3M_paused-data(a5)
	bsr.w	PS3M_pause
	clr	jjo
	popm	all
	rts


s3end	tst.b	ahi_use
	bne.w	ahi_end
	
	pushm	all
	bsr.b	.joopajoo
	popm	all
	rts


.joopajoo
	DPRINT	"Stop"

	lea	data,a5
	basereg	data,a5

	bsr.b	s3cont

	st	PS3M_eject(a5)
	st	PS3M_wait(a5)
	tst	PS3M_play(a5)
	beq.b	.d

	cmp	#DISABLED,system(a5)
	beq.b	.d

.ll	
	pushm	d0/d1/a0/a1/a6
	move.l	gfxbase,a6
	lob	WaitTOF
	popm	d0/d1/a0/a1/a6
  
 ifeq TEST
	tst	PS3M_wait(a5)			; Wait for player
	bne.b	.ll				; task to finish
 endc

.d


******
;	clr	PS3M_reinit
*******



	move.l	4.w,a6

	move.l	tbuf(a5),d0
	beq.b	.eumg
	move.l	d0,a1
	move.l	#1024*4*2,d0
	lob	FreeMem
	clr.l	tbuf(a5)
	clr.l	tbuf2(a5)

.eumg	move.l	buff1(a5),d0
	beq.b	.eimem
	move.l	d0,a1
	move.l	buffSize(a5),d0
	lob	FreeMem
	clr.l	buff1(a5)

.eimem	move.l	buff2(a5),d0
	beq.b	.eimem1
	move.l	d0,a1
	move.l	buffSize(a5),d0
	lob	FreeMem
	clr.l	buff2(a5)

.eimem1	move.l	buff3(a5),d0
	beq.b	.eimem2
	move.l	d0,a1
	move.l	buffSize(a5),d0
	lob	FreeMem
	clr.l	buff3(a5)

.eimem2	move.l	buff4(a5),d0
	beq.b	.eimem3
	move.l	d0,a1
	move.l	buffSize(a5),d0
	lob	FreeMem
	clr.l	buff4(a5)

.eimem3	move.l	buff14(a5),d0
	beq.b	.eimem4
	move.l	d0,a1
	move.l	#64*1024,d0
	tst.b	CyberCalibration(a5)
	beq.b	.nocyb
	add.l	d0,d0
.nocyb	lob	FreeMem
	clr.l	buff14(a5)

.eimem4	move.l	vtab(a5),d0
	beq.b	.eimem5
	move.l	d0,a1
	move.l	#66*256,d0
	cmp	#STEREO14,pmode(a5)
	bne.b	.cd
	add.l	d0,d0
.cd	lob	FreeMem
	clr.l	vtab(a5)

.eimem5	move.l	dtab(a5),d0
	beq.b	.eimem6
	move.l	d0,a1
	move.l	dtabsize(a5),d0
	lob	FreeMem
	clr.l	dtab(a5)

.eimem6	

 ifne DEBUG
	move.l	#2*50,d1
	move.l	dosbase,a6
	lob 	Delay
	move.l	output,d1
	beq.b	.noDbg
	lob	Close
.noDbg
 endif

	rts

	endb	a5





eteen	pushm	all
	move	positioneita,d1
	subq	#2,d1
	bmi.b	.bb
	move	PS3M_position,d0
	addq	#1,d0
	cmp	d1,d0
	blo.b	.a
	clr	d0
.a	bsr.w	setPosition
.bb	popm	all
	rts
taakse	pushm	all
	move	PS3M_position,d0
	subq	#1,d0
	bpl.b	.b
	clr	d0
.b	bsr.w	setPosition
	popm	all
	rts




s3m_code
	move.l	4.w,a6
	sub.l	a1,a1
	lob	FindTask
	move.l	d0,ps3m_task

	DPRINT	"s3m_code"
	
	st	PS3M_play
	jmp	syss3mPlay


ps3m_task	dc.l	0



********************** AHI liittymä
ahi_init
	bsr.w	init
	bsr.w	FinalInit

	move	numchans(pc),setchannels
	move.l	ahi_rate(pc),setfreq
	move.l	ahi_mode(pc),setmode

	bsr.b	ahi_init0
	tst.l	d0
	bne.b	.erro

.x	popm	d1-a6
	rts

.erro	push	d0
	bsr.w	ahi_end
	pop	d0
	moveq	#ier_ahi,d0
	bra.b	.x


ahi_init0
	OPENAHI	1
	move.l	d0,ahibase
	beq.b	.ahi_error
	move.l	d0,a6

	lea	ahi_tags(pc),a1
	jsr	_LVOAHI_AllocAudioA(a6)
	move.l	d0,ahi_ctrl
	beq.b	.ahi_error

	move.l	d0,a2
	moveq	#0,d0				;Load module as one sound!
	moveq	#AHIST_SAMPLE,d1
	lea	ahi_sound0(pc),a0
	jsr	_LVOAHI_LoadSound(a6)
	tst.l	d0
	bne.b	.ahi_error

	move.l	setmode(pc),d0
	lea	getattr_tags(pc),a1
	jsr	_LVOAHI_GetAudioAttrsA(a6)

	bsr.w	ahi_setmastervol

	move	tempo(pc),d0
	bsr.w	ahi_tempo

	lea	ahi_ctrltags(pc),a1
	move.b	#1,setpause-ahi_ctrltags(a1)
	move.l	ahi_ctrl(pc),a2
	jsr	_LVOAHI_ControlAudioA(a6)
	tst.l	d0
	bne.b	.ahi_error
	moveq	#0,d0
	rts
.ahi_error:
	moveq	#-1,d0
	rts



ahi_end
	move.l	ahibase(pc),d0
	beq.b	.1
	move.l	d0,a6
	move.l	ahi_ctrl(pc),a2
	jsr	_LVOAHI_FreeAudio(a6)
	CLOSEAHI
.1
	rts


ahi_update
	move	d0,ahi_mastervol

	mulu	#$8000,d1
	divu	#100,d1
	move	d1,ahi_stereolev

;	bsr	ahi_setmastervol
;	rts

ahi_setmastervol
	pushm	d0/d1/a0-a2/a6

	moveq	#0,d0
	move	setchannels(pc),d0
	tst.l	attr_stereo
	beq.b	.mono
	tst.l	attr_panning		* sama jos panning
	bne.b	.mono
	lsr.l	#1,d0
.mono			* d0 = max master vol
	subq	#1,d0
	lsl.l	#8,d0

	mulu	ahi_mastervol(pc),d0
	divu	#1000,d0
	ext.l	d0
	add	#1<<8,d0
	lsl.l	#8,d0

	move.l	#AHIET_MASTERVOLUME,ahi_effect+ahie_Effect
	move.l	d0,ahi_effect+ahiemv_Volume

	lea	ahi_effect(pc),a0
	move.l	ahi_ctrl(pc),a2
	move.l	ahibase(pc),a6
	jsr	_LVOAHI_SetEffect(a6)

	popm	d0/d1/a0-a2/a6
	rts


ahi_stop
ahi_cont
	pushm	d0/d1/a0-a2/a6

	lea	ahi_ctrltags(pc),a1
	eor.b	#1,setpause-ahi_ctrltags(a1)
	move.l	ahi_ctrl(pc),a2
	move.l	ahibase(pc),a6
	jsr	_LVOAHI_ControlAudioA(a6)

	popm	d0/d1/a0-a2/a6
	rts



ahi_playmusic
	pushm	d2-d7/a2-a6

	bsr	s3vol

	move	mtype(pc),d0
	lea	s3m_music(pc),a0
	subq	#1,d0
	beq.b	.m
	lea	mt_music(pc),a0
	subq	#1,d0
	beq.b	.m
	subq	#1,d0
	beq.b	.m
	lea	xm_music(pc),a0
.m	jsr	(a0)

	lea	cha0,a4
	move	numchans(pc),d7
	subq	#1,d7
	moveq	#0,d6
.chl
	bsr.b	ahi_volume
	bsr.w	ahi_period
	bsr.w	ahi_setrepeat

	tst	mPeriod(a4)
	beq.b	.hiljaa
	tst.b	mOnOff(a4)
	bne.b	.hiljaa			;sound off

	tst.l	mFPos(a4)
	bne.b	.ty
	addq.l	#1,mFPos(a4)
	bsr.w	ahi_sample
.ty
.hiljaa
	lea	mChanBlock_SIZE(a4),a4
	addq	#1,d6
	dbf	d7,.chl

	popm	d2-d7/a2-a6
	rts

;.hiljaa
;	bsr.b	ahi_quiet
;	bra.b	.ty




* parittomat ovat vasemmalla, parilliset oikealla

;in:
* d0	volume
* d6	channel


ahi_volume:
	movem.l	d0-d3/d6/a0-a2/a6,-(sp)

	tst.b	Pro4
	beq.b	.n
	lea	chantab(pc),a6
	move.b	(a6,d6),d6
.n	
	move.l	d6,d0

	move	mVolume(a4),d1
	mulu	PS3M_master(pc),d1
	lsl.l	#4,d1			* max=$10000

	move.l	#$8000,d2
	moveq	#0,d3
	move	ahi_stereolev(pc),d3

	btst	#0,d6		
	beq.b	.parillinen
	neg.l	d3			
.parillinen				* parillinen = oikealla
	sub.l	d3,d2

	moveq	#AHISF_IMM,d3
	move.l	ahi_ctrl(pc),a2
	move.l	ahibase(pc),a6
	jsr	_LVOAHI_SetVol(a6)
	movem.l	(sp)+,d0-d3/d6/a0-a2/a6
	rts

ahi_quiet
	movem.l	d0-d3/d6/a0-a2/a6,-(sp)

	tst.b	Pro4
	beq.b	.n
	lea	chantab(pc),a6
	move.b	(a6,d6),d6
.n	
	move.l	d6,d0
	moveq	#0,d1			* volume 0, quiet sound
	move.l	#$8000,d2

	moveq	#AHISF_IMM,d3
	move.l	ahi_ctrl(pc),a2
	move.l	ahibase(pc),a6
	jsr	_LVOAHI_SetVol(a6)
	movem.l	(sp)+,d0-d3/d6/a0-a2/a6
	rts



;in:
* d0	period
* da6 	channel
ahi_period:

	movem.l	d0-d2/d6/a0-a2/a6,-(sp)

	tst.b	Pro4
	beq.b	.n
	lea	chantab(pc),a6
	move.b	(a6,d6),d6
.n	
	moveq	#0,d1
	move	mPeriod(a4),d1
	beq.b	.exit

	move.l	clock(pc),d0
	lsl.l	#2,d0

	bsr.w	divu_32
	move.l	d0,d1

	move.l	d6,d0

	moveq	#AHISF_IMM,d2
	move.l	ahi_ctrl(pc),a2
	move.l	ahibase(pc),a6
	jsr	_LVOAHI_SetFreq(a6)
.exit

	movem.l	(sp)+,d0-d2/d6/a0-a2/a6
	rts



ahi_setrepeat
	move.l	d6,d0

	tst.b	Pro4
	beq.b	.n
	lea	chantab(pc),a0
	move.b	(a0,d0),d0
.n	
	lsl	#3,d0
	lea	chanreps(pc),a0
	add	d0,a0

	clr.l	(a0)+
	clr.l	(a0)+
	tst.b	mLoop(a4)
	beq.b	.r
	move.l	mLLength(a4),-(a0)
	move.l	mLStart(a4),-(a0)
.r	rts




;in:
* d6	channel
ahi_sample:
	movem.l	d0-d4/d6/a0-a2/a6,-(sp)

	tst.b	Pro4
	beq.b	.n
	lea	chantab(pc),a6
	move.b	(a6,d6),d6
.n	
	move.l	d6,d0

	move.l	mStart(a4),d2
	move.l	mLength(a4),d3
	sub.l	s3m,d2

	moveq	#AHISF_IMM,D4			* immediate!
	moveq	#0,d1				* samplebank

	cmp.l	#4,d3
	bhs.b	.length_ok
	moveq	#AHI_NOSOUND,d1
.length_ok

	move.l	ahi_ctrl(pc),a2
	move.l	ahibase(pc),a6
	jsr	_LVOAHI_SetSound(a6)
	movem.l	(sp)+,d0-d4/d6/a0-a2/a6
	rts



;in:
* a0	struct Hook *
* a1	struct AHISoundMessage *
* a2	struct AHIAudioCtrl *
soundfunc:
	movem.l	d2-d4/a6,-(sp)

	move	ahism_Channel(a1),d0
	move	d0,d2
	lsl	#3,d2

	lea	chanreps(pc),a6
	movem.l	(a6,d2),d2/d3
	sub.l	s3m,d2

	moveq	#0,d1				;sample bank
	moveq	#0,d4				;NOTE: AHISF_IMM *NOT* SET!!

	cmp.l	#4,d3
	bhs.b	.length_ok
	moveq	#AHI_NOSOUND,d1
.length_ok

	move.l	ahibase(pc),a6
	jsr	_LVOAHI_SetSound(a6)

	movem.l	(sp)+,d2-d4/a6
	rts


;---- Tempo ----

ahi_tempo
	movem.l	d0-d1/a0-a2/a6,-(sp)

	and.l	#$ffff,d0
	lsl.w	#1,d0
	divu	#5,d0

	move.l	ahibase(pc),a6
	lea	.tags(pc),a1
	move	d0,4(a1)

	move.l	ahi_ctrl(pc),a2
	jsr	_LVOAHI_ControlAudioA(a6)
	movem.l	(sp)+,d0-d1/a0-a2/a6
	RTS

.tags
	dc.l	AHIA_PlayerFreq
.freq	dc.l	50<<16
	dc.l	TAG_DONE


PlayerFunc:
	blk.b	MLN_SIZE
	dc.l	ahi_playmusic
	dc.l	0
	dc.l	0

SoundFunc:
	blk.b	MLN_SIZE
	dc.l	soundfunc
	dc.l	0
	dc.l	0


** omia variaabeleita


jjo		dc	0

** ahi

chanreps	ds.l	2*32

chantab		dc.b	0,1,3,2		* Protrackerille kanavajärjestys
Pro4		dc.b	0		* jos ~0, käytetään chantabbia
 even

ahi_sound0:	dc.l	AHIST_M8S
setsampletype 	=	*-4
setmodule 	dc.l	0
setmodulelen	dc.l	0

ahibase:	dc.l	0
ahi_ctrl:	dc.l	0

attr_stereo		dc.l	0
attr_panning		dc.l	0
attr_pingpong		dc.l	0
attr_maxchannels	dc.l	0


getattr_tags
	dc.l	AHIDB_Stereo,attr_stereo
	dc.l	AHIDB_Panning,attr_panning
	dc.l	AHIDB_MaxChannels,attr_maxchannels
	dc.l	AHIDB_PingPong,attr_pingpong
	dc.l	TAG_END


ahi_effect
	ds.b	AHIEffMasterVolume_SIZEOF

ahi_ctrltags:	dc.l	AHIC_Play,1
setpause 	=	*-1
		dc.l	TAG_DONE

ahi_tags
	dc.l	AHIA_MixFreq,28000
setfreq 	=	*-4
	dc.l	AHIA_AudioID,$0002000a	* 8 bit stereo
setmode 	= 	*-4
	dc.l	AHIA_Channels,4
setchannels 	= 	*-2
	dc.l	AHIA_Sounds,1
	dc.l	AHIA_SoundFunc,SoundFunc
	dc.l	AHIA_PlayerFunc,PlayerFunc
	dc.l	AHIA_PlayerFreq,50<<16
	dc.l	AHIA_MinPlayerFreq,(32*2/5)<<16
	dc.l	AHIA_MaxPlayerFreq,(255*2/5)<<16
	dc.l	TAG_DONE





PatternInfo
	ds.b	PI_Stripes	
Stripe1	ds.l	32

PatternInit
	lea	PatternInfo(PC),A0
	move.w	#4,PI_Voices(A0)	; Number of stripes (MUST be at least 4)
	pea	ConvertNote(pc) 
	move.l	(sp)+,PI_Convert(a0)
	move.w	#64,PI_Pattlength(A0)	; Length of each stripe in rows
	clr.w	PI_Pattpos(A0)		; Current Position in Pattern (from 0)
	move	numchans(pc),PatternInfo+PI_Voices


	cmp	#mtMOD,mtype
	beq.b	.mod
	cmp	#mtMTM,mtype
	beq.b	.mtm
	rts

.mtm 
	move.l	#3,PI_Modulo(A0)		; Number of bytes to next row
	move	#-1,PI_Speed(a0)		; Magic! Negative: note index
	rts

.mod
	* 4 bytes per note, per channel
	move	numchans(pc),d1
	mulu	#4,d1
	move.l	d1,PI_Modulo(A0)	; Number of bytes to next row
	move	#6,PI_Speed(a0)		; Magic! Positive: period, Negative: note index
	rts

* Called by the PI engine to get values for a particular row
ConvertNote
	moveq	#0,D0		; Period, Note
	moveq	#0,D1		; Sample number
	moveq	#0,D2		; Command 
	moveq	#0,D3		; Command argument

	move	mtype(pc),d0
	cmp 	#mtMOD,d0
	beq.b	.mtMOD
	cmp		#mtMTM,d0 
	beq.b	.mtMTM
	cmp		#mtS3M,d0 
	beq.b	.mtS3M
	cmp		#mtXM,d0 
	beq.b	.mtXM
	rts

.mtXM
	rts

.mtS3M
	rts

.mtMTM
;(NOS*37)³192   ³Each track is saved independently and takes exactly 192 bytes.
;	³      ³The tracks are arranged as 64 consecutive 3-byte notes.  These
;	³      ³notes have the following format:
;	³      ³
;	³      ³
;	³      ³  BYTE 0   BYTE 1   BYTE 2
;	³      ³ ppppppii iiiieeee aaaaaaaa
;	³      ³
;	³      ³ p = pitch value (0=no pitch stated)
;	³      ³ i = instrument number (0=no instrument number)
;	³      ³ e = effect number
;	³      ³ a = effect argument
	move.b	(a0),d0
	lsr.b	#2,d0

	moveq	#%11,d1
	and.b	(a0),d1
	lsl.b	#4,d1

	move.b	1(a0),d2
	lsr.b	#4,d2
	or.b	d2,d1

	moveq	#%1111,d2
	and.b	2(a0),d2

	move.b	3(a0),d3
	rts

.mtMOD
	; 00 11 22 33
	; Sp pp Sc aa

	; 0 or positive: period values

	* sample num
	move.b	2(a0),d1
	lsr.b	#4,d1
	move.b	(a0),d0
	and.b	#$f0,d0
	or.b	d0,d1

	moveq	#$f,d2
	and.b	2(a0),d2
	move.b	3(a0),d3

	move	(a0),d0
	and	#$fff,d0

	rts





*********************************
*	   PS3M 0.9A ®		*
*	  Version 0.960		*
*   © 1994-96 Jarno Paananen	*
*      All rights reserved	*
*********************************

;; LEV4 - IRQ HANDLER

lev4	clr.l	playpos
	move	#$80,$dff09c
	nop
	rte

slev4	;move	d1,$9c(a0)
	;clr.l	(a1)

	clr.l	playpos
	move	#INTF_AUD0,$9c(a0)
	moveq	#0,d0
	rts


lev3	move.l	d0,-(sp)
	move	#$20,$dff09c
	move.l	mrate50(pc),d0
	add.l	d0,playpos
	move.l	buffSizeMaskFF(pc),d0
	and.l	d0,playpos
	move.l	(sp)+,d0
	nop
	rte



* a1 = playpos
lev6server
	move.l	mrate50-playpos(a1),d0
	* grab previous value
	;move.l	(a1),d1
	* next playpos
	add.l	d0,(a1)
	
	* clamp playpos
	move.l	buffSizeMaskFF(pc),d0

	* next pattern pbuf pos
;	addq.l	#1,playpos2

;	move.l	(a1),comp1
;	move.l	d1,comp2

;	cmp.l	(a1),d1
;	blo.b	.o

;	sub.l	(a1),d1
;	bmi.b	.o

;	cmp.l	#$7fffff,(a1)
;	bhs.b	.o
;
;	* if playpos wraps, wrap this too
;	clr.l	playpos2
;	move	#$f00,$dff180
;.o
	and.l	d0,(a1)

;	moveq	#1,d0
	moveq	#0,d0
	rts

comp1	dc.l	 0
comp2	dc.l	0

buffSizeMaskFF
	dc.l	(BUFFER-1)<<8!$ff


	basereg	data,a5
play	;movem.l	d0-a6,-(sp)
	lea	data,a5

	move.l	playpos(a5),d2
	lsr.l	#8,d2
	move.l	bufpos(a5),d0
	cmp.l	d2,d0
	ble.b	.norm
	sub.l	buffSize(a5),d0
.norm	move.l	mrate50(a5),d1
	lsr.l	#7,d1
	add.l	d0,d1

	sub.l	d1,d2
	bmi.w	.ei

	moveq	#1,d0
	and.l	d2,d0
	add	d0,d2

	cmp.l	#16,d2
	blt.b	.ei

	move	d2,todobytes(a5)

.mix	move	bytes2music(a5),d0
	cmp	todobytes(a5),d0
	bgt.b	.mixaa

	sub	d0,todobytes(a5)
	sub	d0,bytes2music(a5)
	move	d0,bytes2do(a5)
	beq.b	.q
	
	bsr.w	domix

.q	tst	PS3M_paused
	bne.b	.o

	tst	PS3M_play
	beq.b	.o

	cmp	#mtS3M,mtype(a5)
	bne.b	.xm
	bsr.w	s3m_music
	lea	data,a5
	bra.b	.o

.xm	cmp	#mtXM,mtype(a5)
	bne.b	.mod

	bsr.w	xm_music
	lea	data,a5
	bra.b	.o

.mod	bsr.w	mt_music			; Also with MTMs

.o	move	bytesperframe(a5),d0
	add	d0,bytes2music(a5)
	bra.b	.mix

.mixaa	move	todobytes(a5),d0
	sub	d0,bytes2music(a5)
	move	d0,bytes2do(a5)
	beq.b	.q2

	bsr.w	domix

.q2	lea	data,a5
.ei	moveq	#0,d7
	rts







init	
	lea	data,a5
	clr	mtype(a5)

	move.l	s3m(a5),a0
	cmp.l	#'SCRM',44(a0)
	beq.w	.s3m

	move.l	(a0),d0
	lsr.l	#8,d0
	cmp.l	#'MTM',d0
	beq.w	.mtm

	move.l	a0,a1
	lea	xmsign(a5),a2
	moveq	#3,d0
.ll	cmpm.l	(a1)+,(a2)+
	bne.b	.jj
	dbf	d0,.ll
	bra.w	.xm

.jj	move.l	1080(a0),d0
	cmp.l	#'OCTA',d0
	beq.w	.fast8
	cmp.l	#'M.K.',d0
	beq.w	.pro4
	cmp.l	#'M!K!',d0
	beq.w	.pro4
	cmp.l	#'FLT4',d0
	beq.w	.pro4

	move.l	d0,d1
	and.l	#$ffffff,d1
	cmp.l	#'CHN',d1
	beq.b	.chn

	and.l	#$ffff,d1
	cmp.l	#'CH',d1
	beq.b	.ch

	move.l	d0,d1
	and.l	#$ffffff00,d1
	cmp.l	#'TDZ'<<8,d1
	beq.b	.tdz
	bra.w	.error

.chn	move.l	d0,d1
	swap	d1
	lsr	#8,d1
	sub	#'0',d1
	move	#mtMOD,mtype(a5)
	move	d1,numchans(a5)
	addq	#1,d1
	lsr	d1
	move	d1,maxchan(a5)
	bra.w	.init

.ch	move.l	d0,d1
	swap	d1
	sub	#'00',d1
	move	d1,d0
	lsr	#8,d0
	mulu	#10,d0
	and	#$f,d1
	add	d0,d1

	move	#mtMOD,mtype(a5)
	move	d1,numchans(a5)
	addq	#1,d1
	lsr	d1
	move	d1,maxchan(a5)
	bra.b	.init

.tdz	and.l	#$ff,d0
	sub	#'0',d0
	move	#mtMOD,mtype(a5)
	move	d0,numchans(a5)
	addq	#1,d0
	lsr	d0
	move	d0,maxchan(a5)
	bra.b	.init

.fast8	move	#mtMOD,mtype(a5)
	move	#8,numchans(a5)
	move	#4,maxchan(a5)
	bra.b	.init

.pro4	move	#mtMOD,mtype(a5)
	move	#4,numchans(a5)
	move	#2,maxchan(a5)
	st	Pro4
	bra.b	.init

.mtm	move	#mtMTM,mtype(a5)
	bra.b	.init

.xm	cmp	#$401,xmVersion(a0)		; Kool turbo-optimizin'...
	bne.w	.jj
	move	#mtXM,mtype(a5)
	bra.b	.init

.s3m	move	#mtS3M,mtype(a5)


.init

; TEMPORARY BUGFIX...

	cmp	#2,maxchan(a5)
	bhs.b	.opk

	move	#2,maxchan(a5)

.opk	tst	mtype(a5)
	beq.b	.error

	cmp	#mtS3M,mtype(a5)
	beq.w	s3m_init

	cmp	#mtMOD,mtype(a5)
	beq.w	mt_init

	cmp	#mtMTM,mtype(a5)
	beq.w	mtm_init

	cmp	#mtXM,mtype(a5)
	beq.w	xm_init

.error	moveq	#1,d0
	rts


FinalInit
	clr.l	bufpos(a5)
	clr.l	playpos(a5)

	clr	cn(a5)
	clr.b	mt_counter

	tst.b	ahi_use
	bne.b	.boing

	lea	buff1,a0
	moveq	#3,d6
.clloop
	move.l	(a0)+,d0
	beq.b	.skip
	move.l	d0,a1

	move.l	buffSize(a5),d7
	lsr.l	#2,d7
	subq.l	#1,d7
.cl	clr.l	(a1)+
	dbf	d7,.cl
.skip	dbf	d6,.clloop

.boing
	tst	PS3M_cont(a5)
	bne.w	.q

.huu	lea	cha0(a5),a0
	move	#mChanBlock_SIZE*16-1,d7
.cl2	clr	(a0)+
	dbf	d7,.cl2

	lea	c0(a5),a0
	move	#s3mChanBlock_SIZE*8-1,d7
.cl3	clr.l	(a0)+
	dbf	d7,.cl3

	tst.b	ahi_use
	bne.w	.boing2

	move	tempo(a5),d0
	bne.b	.qw
	moveq	#125,d0
.qw	move.l	mrate(a5),d1
	move.l	d1,d2
	lsl.l	#2,d1
	add.l	d2,d1
	add	d0,d0
	divu	d0,d1

	addq	#1,d1
	and	#~1,d1

	move	d1,bytesperframe(a5)
	clr	bytes2do(a5)

	bset	#1,$bfe001

	bsr.w	makedivtabs
	bsr.w	Makevoltable

	ifeq	disable020
	
	move.l	4.w,a6
	btst	#1,297(a6)
	beq.b	.no020

; Processor is 020+!

	st	opt020(a5)
	
	cmp	#STEREO14,pmode(a5)
	beq.b	.s14_020

	move.l	#mix_020,mixad1(a5)
	move.l	#mix2_020,mixad2(a5)
	bra.b	.e

.s14_020
	move.l	#mix16_020,mixad1(a5)
	move.l	#mix162_020,mixad2(a5)
	bra.b	.e
	endc

; Processor is 000/010

.no020	clr	opt020(a5)

	cmp	#STEREO14,pmode(a5)
	beq.b	.s14_000

	move.l	#mix,mixad1(a5)
	move.l	#mix2,mixad2(a5)
	bra.b	.e

.s14_000
	move.l	#mix16,mixad1(a5)
	move.l	#mix162,mixad2(a5)

.e	cmp	#STEREO14,pmode(a5)
	bne.b	.nop

	move.l	#copybuf14,cbufad(a5)

	bsr.w	do14tab
	bra.b	.q

.nop	cmp	#REAL,pmode(a5)
	beq.b	.surr

	move.l	#copybuf,cbufad(a5)
	bra.b	.q

.surr	move.l	#copysurround,cbufad(a5)

.boing2
.q	moveq	#0,d0
	rts




; D0 = New position

setPosition
	lea	data,a5
	move	d0,PS3M_position(a5)
	cmp	#mtS3M,mtype(a5)
	beq.b	.s3m

	cmp	#mtXM,mtype(a5)
	beq.b	.xm

; MOD or MTM
	subq.b	#1,d0
	move.b	d0,mt_songpos
	clr.b	mt_pbreakpos
	st 	mt_posjumpflag
	clr.b	mt_counter
	
	movem.l	d0-d4/a0-a6,-(sp)
	bra.w	mt_nextposition

; S3M
.s3m	subq	#1,d0
	move	d0,pos(a5)
	clr	rows(a5)
	move.l	s3m(a5),a0
	move.b	initialspeed(a0),d0
	bne.b	.ok
	moveq	#6,d0
.ok	move	d0,spd(a5)
	clr	cn(a5)
	bra.w	burk

; XM
.xm	subq	#1,d0
	move	d0,pos(a5)
	move.l  s3m(a5),a0
	clr	rows(a5)
	clr	cn(a5)
	bra.w	burki

PS3M_pause
	tst	PS3M_paused(a5)
	beq.b	.restore

.save	lea	cha0,a0
	lea	saveArray(pc),a1
	moveq	#31,d0
.ll	move.b	mOnOff(a0),(a1)+
	st	mOnOff(a0)
	lea	mChanBlock_SIZE(a0),a0
	dbf	d0,.ll
	rts

.restore
	lea	cha0,a0
	lea	saveArray(pc),a1
	moveq	#31,d0
.l2	move.b	(a1)+,mOnOff(a0)
	lea	mChanBlock_SIZE(a0),a0
	dbf	d0,.l2
	rts

saveArray
	dcb.b	32







;;***** Mixing routines *********


domix	lea	cha0(a5),a4
	lea	pantab(a5),a0
	moveq	#31,d7
	move.l	mixad1(a5),a1
.loo	tst.b	(a0)+
	beq.b	.n
	bmi.b	.n

	move.l	tbuf(a5),a2
	Push	a0/a1/d7
	jsr	(a1)				; Mix
	Pull	a0/a1/d7
	move	#1,chans(a5)
	lea	mChanBlock_SIZE(a4),a4
	subq	#1,d7
	bra.b	.loo2

.n	lea	mChanBlock_SIZE(a4),a4
	dbf	d7,.loo
	bra.b	.ddq


.loo2	cmp	#1,maxchan(a5)
	beq.b	.ddq

	move.l	mixad2(a5),a1
.loka	tst.b	(a0)+
	beq.b	.n2
	bmi.b	.n2

	move.l	tbuf(a5),a2
	Push	a0/a1/d7
	jsr	(a1)
	Pull	a0/a1/d7

.n2	lea	mChanBlock_SIZE(a4),a4
	dbf	d7,.loka

.ddq	move.l	tbuf(a5),a0
	move.l	buff1(a5),a1
	move.l	buff3(a5),a4
	move.l	cbufad(a5),a2
	jsr	(a2)


right	lea	cha0(a5),a4
	lea	pantab(a5),a0
	move.l	mixad1(a5),a1
	moveq	#31,d7
.loo	tst.b	(a0)+
	bpl.b	.n

	move.l	tbuf2(a5),a2
	Push	a0/a1/d7
	jsr	(a1)
	Pull	a0/a1/d7
	move	#1,chans(a5)
	lea	mChanBlock_SIZE(a4),a4
	subq	#1,d7
	bra.b	.loo2

.n	lea	mChanBlock_SIZE(a4),a4
	dbf	d7,.loo
	bra.b	.ddq


.loo2	cmp	#1,maxchan(a5)
	beq.b	.ddq
	move.l	mixad2(a5),a1
.loka	tst.b	(a0)+
	bpl.b	.n2

	move.l	tbuf2(a5),a2
	Push	a0/a1/d7
	jsr	(a1)
	Pull	a0/a1/d7

.n2	lea	mChanBlock_SIZE(a4),a4
	dbf	d7,.loka

.ddq	move.l	tbuf2(a5),a0
	move.l	buff2(a5),a1
	move.l	buff4(a5),a4
	move.l	cbufad(a5),a2
	jsr	(a2)

	moveq	#0,d0
	move	bytes2do(a5),d0
	add.l	d0,bufpos(a5)
	move.l	buffSizeMask(a5),d0
	and.l	d0,bufpos(a5)
	clr	bytes2do(a5)
	rts


copybuf	move.l	bufpos(a5),d0
	move.l	d0,d1
	moveq	#0,d2
	move	bytes2do(a5),d2
	add.l	d2,d1
	cmp.l	buffSizeMask(a5),d1
	ble.b	.dd

	move.l	a1,a3

	move.l	buffSize(a5),d7
	sub.l	d0,d7
	lsr.l	#1,d7
	subq	#1,d7
	add.l	d0,a1
	lea	divtabs(a5),a2
	move	chans(a5),d0
	lsl	#2,d0
	move.l	-4(a2,d0),a2

.ldd	move	(a0)+,d2
	move.b	(a2,d2),(a1)+
	move	(a0)+,d2
	move.b	(a2,d2),(a1)+
	dbf	d7,.ldd

	move.l	a3,a1
	move.l	d1,d7
	sub.l	buffSize(a5),d7
	lsr.l	#1,d7
	subq	#1,d7
	bmi.b	.ddq
.ldd2	move	(a0)+,d2
	move.b	(a2,d2),(a1)+
	move	(a0)+,d2
	move.b	(a2,d2),(a1)+
	dbf	d7,.ldd2
.ddq	rts

.dd	add.l	d0,a1
	lea	divtabs(a5),a2
	move	chans(a5),d0
	lsl	#2,d0
	move.l	-4(a2,d0),a2
	move	bytes2do(a5),d7
	lsr	#1,d7
	subq	#1,d7
.ldd3	move	(a0)+,d1
	move.b	(a2,d1),(a1)+
	move	(a0)+,d1
	move.b	(a2,d1),(a1)+
	dbf	d7,.ldd3
	rts

copysurround
	move.l	bufpos(a5),d0
	move.l	d0,d1

	moveq	#0,d2
	move	bytes2do(a5),d2
	add.l	d2,d1

	cmp.l	buffSizeMask(a5),d1
	ble.b	.dd

	movem.l	a1/a4,-(sp)

	move.l	buffSize(a5),d7
	sub.l	d0,d7
	lsr.l	#1,d7
	subq	#1,d7
	add.l	d0,a1
	add.l	d0,a4
	lea	divtabs(a5),a2
	move	chans(a5),d0
	lsl	#2,d0
	move.l	-4(a2,d0),a2

.ldd	move	(a0)+,d2
	move.b	(a2,d2),d2
	move.b	d2,(a1)+
	not	d2
	move.b	d2,(a4)+

	move	(a0)+,d2
	move.b	(a2,d2),d2
	move.b	d2,(a1)+
	not	d2
	move.b	d2,(a4)+
	dbf	d7,.ldd

	movem.l	(sp)+,a1/a4

	move.l	d1,d7
	sub.l	buffSize(a5),d7
	lsr.l	#1,d7
	subq	#1,d7
	bmi.b	.ddq
.ldd2	move	(a0)+,d2
	move.b	(a2,d2),d2
	move.b	d2,(a1)+
	not	d2
	move.b	d2,(a4)+

	move	(a0)+,d2
	move.b	(a2,d2),d2
	move.b	d2,(a1)+
	not	d2
	move.b	d2,(a4)+
	dbf	d7,.ldd2
.ddq	rts

.dd	add.l	d0,a1
	add.l	d0,a4
	lea	divtabs(a5),a2
	move	chans(a5),d0
	lsl	#2,d0
	move.l	-4(a2,d0),a2
	move	bytes2do(a5),d7
	lsr	#1,d7
	subq	#1,d7
.ldd3	move	(a0)+,d2
	move.b	(a2,d2),d2
	move.b	d2,(a1)+
	not	d2
	move.b	d2,(a4)+

	move	(a0)+,d2
	move.b	(a2,d2),d2
	move.b	d2,(a1)+
	not	d2
	move.b	d2,(a4)+
	dbf	d7,.ldd3
	rts


copybuf14
	move.l	bufpos(a5),d0
	move.l	d0,d1
	moveq	#0,d2
	move	bytes2do(a5),d2
	add.l	d2,d1
	cmp.l	buffSizeMask(a5),d1
	ble.b	.dd

	movem.l	a1/a4,-(sp)

	move.l	buffSize(a5),d7
	sub.l	d0,d7
	subq	#1,d7
	add.l	d0,a1
	add.l	d0,a4
	moveq	#0,d2
	move.l	buff14(a5),a2

	bsr.b	.convert14

.huu	movem.l	(sp)+,a1/a4
	move.l	d1,d7
	sub.l	buffSize(a5),d7
	subq	#1,d7
	bmi.b	.ddq

	bsr.b	.convert14
.ddq	rts


.dd	add.l	d0,a1
	add.l	d0,a4
	move	bytes2do(a5),d7
	subq	#1,d7
	move.l	buff14(a5),a2
	moveq	#0,d2

	bsr.b	.convert14
	rts



.convert14
	tst.b	CyberCalibration(a5)
	bne.b	.convert14_cyber

	moveq	#-2,d0
.ldd	move	(a0)+,d2
	and.l	d0,d2
	move.b	(a2,d2.l),(a1)+
	move.b	1(a2,d2.l),(a4)+
	dbf	d7,.ldd
	rts

.convert14_cyber

	tst.b	opt020(a5)
	bne.b	.convert14_cyber020

.lddC0	moveq	#0,d2
	move	(a0)+,d2
	add.l	d2,d2
	move.b	(a2,d2.l),(a1)+
	move.b	1(a2,d2.l),(a4)+
	dbf	d7,.lddC0
	rts


.convert14_cyber020
.lddC	move	(a0)+,d2
	move.b	(a2,d2.l*2),(a1)+
	move.b	1(a2,d2.l*2),(a4)+
	dbf	d7,.lddC
	rts



; 000/010 Mixing routines

; Mixing routine for the first channel (moves data)


mix	moveq	#0,d7
	move	bytes2do(a5),d7
	subq	#1,d7
	
	tst	mPeriod(a4)
	beq.w	.ty
	tst.b	mOnOff(a4)
	bne.w	.ty			;sound off

	tst	mVolume(a4)
	beq.w	.vol0

.dw	move.l	clock(a5),d4
	divu	mPeriod(a4),d4
	swap	d4
	clr	d4
	lsr.l	#2,d4

	move.l	mrate(a5),d0
	divu	d0,d4
	swap	d4
	clr	d4
	rol.l	#4,d4

	move.l	vtabaddr(a5),d2
	move	mVolume(a4),d0
	mulu	PS3M_master(a5),d0
	lsr	#6,d0
	lsl.l	#8,d0
	add.l	d0,d2				; Position in volume table

	move.l	(a4),a0				;mStart
	move.l	mFPos(a4),d0

	moveq	#0,d3
	moveq	#0,d5

	move.l	mLength(a4),d6
	bne.b	.2

	tst.b	mLoop(a4)
	bne.b	.q
	st	mOnOff(a4)
	bra.b	.qw

.2	cmp.l	#$ffff,d6
	bls.b	.leii
	move	#$ffff,d6

.leii	cmp	#32,d7
	blt.b	.lep
	move.l	d4,d1
	swap	d1
	lsl.l	#5,d1
	swap	d1
	add.l	d0,d1
	cmp	d6,d1
	bhs.b	.lep
	pea	.leii(pc)
	bra.w	.mix32

.lep	move.b	(a0,d0),d2
	move.l	d2,a1
	add.l	d4,d0
	move.b	(a1),d3
	addx	d5,d0
	move	d3,(a2)+

	cmp	d6,d0
	bhs.b	.ddwq
	dbf	d7,.lep
	bra.b	.qw

.ddwq	tst.b	mLoop(a4)
	bne.b	.q
	st	mOnOff(a4)
	dbf	d7,.ty
	bra.b	.qw

.q	move.l	mLStart(a4),a0
	moveq	#0,d1
	move	d0,d1
	sub.l	mLength(a4),d1
	add.l	d1,a0
	move.l	mLLength(a4),d6
	sub.l	d1,d6
	move.l	d6,mLength(a4)

	cmp.l	#$ffff,d6
	bls.b	.j
	move	#$ffff,d6
.j	clr	d0				;reset integer part
	dbf	d7,.leii

.qw	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)				;mStart
	move.l	d0,mFPos(a4)

	sub.l	d1,mLength(a4)
	bpl.b	.u

	tst.b	mLoop(a4)
	bne.b	.q2
	st	mOnOff(a4)
	bra.b	.u

.q2	move.l	mLLength(a4),d6
	sub.l	(a4),a0
	add.l	mLStart(a4),a0
	sub.l	d6,a0
	add.l	d6,mLength(a4)
	move.l	a0,(a4)				; mStart
.u	rts

.ty	addq	#1,d7
	beq.b	.u

	move.l	#$800080,d0
	lsr	d7
	bcc.b	.sk
	move	d0,(a2)+
.sk	subq	#1,d7
	bmi.b	.u
.lk	move.l	d0,(a2)+
	dbf	d7,.lk
	rts

.mix32	rept	16
	move.b	(a0,d0),d2
	move.l	d2,a1
	move.b	(a1),d3
	add.l	d4,d0
	addx	d5,d0
	swap	d3
	move.b	(a0,d0),d2
	move.l	d2,a1
	move.b	(a1),d3
	move.l	d3,(a2)+
	add.l	d4,d0
	addx	d5,d0
	endr

	sub	#32,d7
	rts



.vol0	move.l	clock(a5),d4
	divu	mPeriod(a4),d4		;period
	swap	d4
	clr	d4
	lsr.l	#2,d4

	move.l	mrate(a5),d0
	divu	d0,d4
	swap	d4
	clr	d4
	rol.l	#4,d4
	swap	d4

	move.l	(a4),a0			;mStart
	move.l	mFPos(a4),d0

	addq	#1,d7

	movem.l	d0/d1,-(sp)
	move.l	d7,d1
	move.l	d4,d0
	bsr.w	mulu_32
	move.l	d0,d4
	movem.l	(sp)+,d0/d1

	subq	#1,d7

	swap	d0
	add.l	d4,d0			; Position after "mixing"
	swap	d0
	
	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)
	sub.l	d1,mLength(a4)
	bpl.w	.ty			; OK, Done!

; We're about to mix past the end of the sample

	tst.b	mLoop(a4)
	bne.b	.q3
	st	mOnOff(a4)
	bra.w	.ty

.q3	move.l	mLLength(a4),d6
.loop	sub.l	d6,a0
	add.l	d6,mLength(a4)
	bmi.b	.loop
	beq.b	.loop

	move.l	a0,(a4)
	bra.w	.ty



; Mixing routine for rest of the channels (adds data)

mix2	moveq	#0,d7
	move	bytes2do(a5),d7

	tst	mPeriod(a4)
	beq.w	.ty
	tst.b	mOnOff(a4)
	bne.w	.ty			;noloop

	tst	mVolume(a4)
	beq.w	.vol0

.dw	subq	#1,d7

	move.l	clock(a5),d4
	divu	mPeriod(a4),d4
	swap	d4
	clr	d4
	lsr.l	#2,d4

	move.l	mrate(a5),d0
	divu	d0,d4
	swap	d4
	clr	d4
	rol.l	#4,d4

	move.l	vtabaddr(a5),d2
	move	mVolume(a4),d0
	mulu	PS3M_master(a5),d0
	lsr	#6,d0
	lsl.l	#8,d0
	add.l	d0,d2

	move.l	(a4),a0			;mStart
	move.l	mFPos(a4),d0

	moveq	#0,d3
	moveq	#0,d5

	move.l	mLength(a4),d6
	bne.b	.2

	tst.b	mLoop(a4)
	bne.b	.q
	st	mOnOff(a4)
	bra.b	.qw

.2	cmp.l	#$ffff,d6
	bls.b	.leii
	move	#$ffff,d6

.leii	cmp	#32,d7
	blt.b	.lep
	move.l	d4,d1
	swap	d1
	lsl.l	#5,d1
	swap	d1
	add.l	d0,d1
	cmp	d6,d1
	bhs.b	.lep
	pea	.leii(pc)
	bra.w	.mix32

.lep	move.b	(a0,d0),d2
	move.l	d2,a1
	add.l	d4,d0
	move.b	(a1),d3
	addx	d5,d0
	add	d3,(a2)+

	cmp	d6,d0
	bhs.b	.ddwq
	dbf	d7,.lep
	bra.b	.qw

.ddwq	tst.b	mLoop(a4)
	bne.b	.q
	st	mOnOff(a4)
	dbf	d7,.tyy
	bra.b	.qw

.q	move.l	mLStart(a4),a0
	moveq	#0,d1
	move	d0,d1
	sub.l	mLength(a4),d1
	add.l	d1,a0
	move.l	mLLength(a4),d6
	sub.l	d1,d6
	move.l	d6,mLength(a4)
	cmp.l	#$ffff,d6
	bls.b	.j
	move	#$ffff,d6
.j	clr	d0			;reset integer part
	dbf	d7,.leii

.qw	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)

	sub.l	d1,mLength(a4)
	bpl.b	.u

	tst.b	mLoop(a4)
	bne.b	.q2
	st	mOnOff(a4)
	bra.b	.u

.q2	move.l	mLLength(a4),d6
	sub.l	(a4),a0
	add.l	mLStart(a4),a0
	sub.l	d6,a0
	add.l	d6,mLength(a4)
	move.l	a0,(a4)

.u	addq	#1,chans(a5)
.ty	rts

.tyy	addq	#1,d7
	beq.b	.u

	move.l	#$800080,d0
	lsr	d7
	bcc.b	.sk
	add	d0,(a2)+
.sk	subq	#1,d7
	bmi.b	.u
.lk	add.l	d0,(a2)+
	dbf	d7,.lk
	bra.b	.u

.mix32	rept	16
	move.b	(a0,d0),d2
	move.l	d2,a1
	move.b	(a1),d3
	add.l	d4,d0
	addx	d5,d0
	swap	d3
	move.b	(a0,d0),d2
	move.l	d2,a1
	move.b	(a1),d3
	add.l	d3,(a2)+
	add.l	d4,d0
	addx	d5,d0
	endr
	sub	#32,d7
	rts


.vol0	move.l	clock(a5),d4
	divu	mPeriod(a4),d4
	swap	d4
	clr	d4
	lsr.l	#2,d4

	move.l	mrate(a5),d0
	divu	d0,d4
	swap	d4
	clr	d4
	rol.l	#4,d4
	swap	d4

	move.l	(a4),a0			;pos (addr)
	move.l	mFPos(a4),d0

	addq	#1,d7
	movem.l	d0/d1,-(sp)
	move.l	d7,d1
	move.l	d4,d0
	bsr.w	mulu_32
	move.l	d0,d4
	movem.l	(sp)+,d0/d1

	subq	#1,d7
	swap	d0
	add.l	d4,d0			; Position after "mixing"
	swap	d0
	
	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)
	sub.l	d1,mLength(a4)
	bpl.w	.ty			; OK, Done!

; We're about to mix past the end of the sample

	tst.b	mLoop(a4)
	bne.b	.q3
	st	mOnOff(a4)
	bra.w	.ty

.q3	move.l	mLLength(a4),d6
.loop	sub.l	d6,a0
	add.l	d6,mLength(a4)
	bmi.b	.loop
	beq.b	.loop

	move.l	a0,(a4)
	bra.w	.ty


; 16-bit mixing routine for first channel (moves data)

mix16	moveq	#0,d7
	move	bytes2do(a5),d7
	subq	#1,d7

	tst	mPeriod(a4)
	beq.w	.ty
	tst.b	mOnOff(a4)
	bne.w	.ty

	tst	mVolume(a4)
	beq.w	.vol0

.dw	move.l	clock(a5),d4
	divu	mPeriod(a4),d4
	swap	d4
	clr	d4
	lsr.l	#2,d4

	move.l	mrate(a5),d0
	divu	d0,d4
	swap	d4
	clr	d4
	rol.l	#4,d4

	move.l	vtabaddr(a5),a3
	move	mVolume(a4),d0
	mulu	PS3M_master(a5),d0
	lsr	#6,d0
	add	d0,d0
	lsl.l	#8,d0
	add.l	d0,a3				; Position in volume table

	move.l	(a4),a0				;mStart
	move.l	mFPos(a4),d0

	moveq	#0,d3
	moveq	#0,d5

	move.l	mLength(a4),d6
	bne.b	.2

	tst.b	mLoop(a4)
	bne.b	.q
	st	mOnOff(a4)
	bra.b	.qw

.2	cmp.l	#$ffff,d6
	bls.b	.leii
	move	#$ffff,d6

.leii	cmp	#32,d7
	blt.b	.lep
	move.l	d4,d1
	swap	d1
	lsl.l	#5,d1
	swap	d1
	add.l	d0,d1
	cmp	d6,d1
	bhs.b	.lep
	pea	.leii(pc)
	bra.w	.mix32

.lep	moveq	#0,d2
	move.b	(a0,d0),d2
	add	d2,d2
	add.l	d4,d0
	move	(a3,d2),(a2)+
	addx	d5,d0

	cmp	d6,d0
	bhs.b	.ddwq
	dbf	d7,.lep
	bra.b	.qw

.ddwq	tst.b	mLoop(a4)
	bne.b	.q
	st	mOnOff(a4)
	dbf	d7,.ty
	bra.b	.qw

.q	move.l	mLStart(a4),a0
	moveq	#0,d1
	move	d0,d1
	sub.l	mLength(a4),d1
	add.l	d1,a0
	move.l	mLLength(a4),d6
	sub.l	d1,d6
	move.l	d6,mLength(a4)

	cmp.l	#$ffff,d6
	bls.b	.j
	move	#$ffff,d6
.j	clr	d0				;reset integer part
	dbf	d7,.leii

.qw	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)				;mStart
	move.l	d0,mFPos(a4)

	sub.l	d1,mLength(a4)
	bpl.b	.u

	tst.b	mLoop(a4)
	bne.b	.q2
	st	mOnOff(a4)
	bra.b	.u

.q2	move.l	mLLength(a4),d6
	sub.l	(a4),a0
	add.l	mLStart(a4),a0
	sub.l	d6,a0
	add.l	d6,mLength(a4)
	move.l	a0,(a4)				; mStart
.u	rts

.ty	addq	#1,d7
	beq.b	.u

	moveq	#0,d0
	lsr	d7
	bcc.b	.sk
	move	d0,(a2)+
.sk	subq	#1,d7
	bmi.b	.u
.lk	move.l	d0,(a2)+
	dbf	d7,.lk
	rts

.mix32	rept	32

	moveq	#0,d2
	move.b	(a0,d0),d2
	add	d2,d2
	add.l	d4,d0
	move	(a3,d2),(a2)+
	addx	d5,d0

	endr

	sub	#32,d7
	rts


.vol0	move.l	clock(a5),d4
	divu	mPeriod(a4),d4		;period
	swap	d4
	clr	d4
	lsr.l	#2,d4

	move.l	mrate(a5),d0
	divu	d0,d4
	swap	d4
	clr	d4
	rol.l	#4,d4
	swap	d4

	move.l	(a4),a0			;mStart
	move.l	mFPos(a4),d0

	addq	#1,d7

	movem.l	d0/d1,-(sp)
	move.l	d7,d1
	move.l	d4,d0
	bsr.w	mulu_32
	move.l	d0,d4
	movem.l	(sp)+,d0/d1

	subq	#1,d7

	swap	d0
	add.l	d4,d0			; Position after "mixing"
	swap	d0
	
	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)
	sub.l	d1,mLength(a4)
	bpl.w	.ty			; OK, Done!

; We're about to mix past the end of the sample

	tst.b	mLoop(a4)
	bne.b	.q3
	st	mOnOff(a4)
	bra.w	.ty

.q3	move.l	mLLength(a4),d6
.loop	sub.l	d6,a0
	add.l	d6,mLength(a4)
	bmi.b	.loop
	beq.b	.loop

	move.l	a0,(a4)
	bra.w	.ty



; Mixing routine for rest of the channels (adds data)

mix162	moveq	#0,d7
	move	bytes2do(a5),d7

	tst	mPeriod(a4)
	beq.w	.ty
	tst.b	mOnOff(a4)
	bne.w	.ty

	tst	mVolume(a4)
	beq.w	.vol0

.dw	subq	#1,d7

	move.l	clock(a5),d4
	divu	mPeriod(a4),d4
	swap	d4
	clr	d4
	lsr.l	#2,d4

	move.l	mrate(a5),d0
	divu	d0,d4
	swap	d4
	clr	d4
	rol.l	#4,d4

	move.l	vtabaddr(a5),a3
	move	mVolume(a4),d0		;volu
	mulu	PS3M_master(a5),d0
	lsr	#6,d0
	add	d0,d0
	lsl.l	#8,d0
	add.l	d0,a3

	move.l	(a4),a0			;mStart
	move.l	mFPos(a4),d0

	moveq	#0,d3
	moveq	#0,d5

	move.l	mLength(a4),d6
	bne.b	.2

	tst.b	mLoop(a4)
	bne.b	.q
	st	mOnOff(a4)
	bra.b	.qw

.2	cmp.l	#$ffff,d6
	bls.b	.leii
	move	#$ffff,d6

.leii	cmp	#32,d7
	blt.b	.lep
	move.l	d4,d1
	swap	d1
	lsl.l	#5,d1
	swap	d1
	add.l	d0,d1
	cmp	d6,d1
	bhs.b	.lep
	pea	.leii(pc)
	bra.w	.mix32

.lep	moveq	#0,d2
	move.b	(a0,d0),d2
	add	d2,d2
	add.l	d4,d0
	move	(a3,d2),d3
	addx	d5,d0
	add	d3,(a2)+

	cmp	d6,d0
	bhs.b	.ddwq
	dbf	d7,.lep
	bra.b	.qw

.ddwq	tst.b	mLoop(a4)
	bne.b	.q
	st	mOnOff(a4)
	dbf	d7,.tyy
	bra.b	.qw

.q	move.l	mLStart(a4),a0
	moveq	#0,d1
	move	d0,d1
	sub.l	mLength(a4),d1
	add.l	d1,a0
	move.l	mLLength(a4),d6
	sub.l	d1,d6
	move.l	d6,mLength(a4)
	cmp.l	#$ffff,d6
	bls.b	.j
	move	#$ffff,d6
.j	clr	d0			;reset integer part
	dbf	d7,.leii

.qw	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)

	sub.l	d1,mLength(a4)
	bpl.b	.u

	tst.b	mLoop(a4)
	bne.b	.q2
	st	mOnOff(a4)
	bra.b	.u

.q2	move.l	mLLength(a4),d6
	sub.l	(a4),a0
	add.l	mLStart(a4),a0
	sub.l	d6,a0
	add.l	d6,mLength(a4)
	move.l	a0,(a4)

.u
.ty
.tyy
	rts


.mix32	rept	32
	moveq	#0,d2
	move.b	(a0,d0),d2
	add	d2,d2
	move	(a3,d2),d3
	add	d3,(a2)+
	add.l	d4,d0
	addx	d5,d0
	endr
	sub	#32,d7
	rts

.vol0	move.l	clock(a5),d4
	divu	mPeriod(a4),d4
	swap	d4
	clr	d4
	lsr.l	#2,d4

	move.l	mrate(a5),d0
	divu	d0,d4
	swap	d4
	clr	d4
	rol.l	#4,d4
	swap	d4

	move.l	(a4),a0			;pos (addr)
	move.l	mFPos(a4),d0

	addq	#1,d7
	movem.l	d0/d1,-(sp)
	move.l	d7,d1
	move.l	d4,d0
	bsr.w	mulu_32
	move.l	d0,d4
	movem.l	(sp)+,d0/d1

	subq	#1,d7
	swap	d0
	add.l	d4,d0			; Position after "mixing"
	swap	d0
	
	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)
	sub.l	d1,mLength(a4)
	bpl.w	.ty			; OK, Done!

; We're about to mix past the end of the sample

	tst.b	mLoop(a4)
	bne.b	.q3
	st	mOnOff(a4)
	bra.w	.ty

.q3	move.l	mLLength(a4),d6
.loop	sub.l	d6,a0
	add.l	d6,mLength(a4)
	bmi.b	.loop
	beq.b	.loop

	move.l	a0,(a4)
	bra.w	.ty




	ifeq	disable020

; 020+ Optimized versions!

; Mixing routine for the first channel (moves data)


mix_020	moveq	#0,d7
	move	bytes2do(a5),d7
	tst	mPeriod(a4)
	beq.w	.ty
	tst.b	mOnOff(a4)
	bne.w	.ty

	tst	mVolume(a4)
	beq.w	.vol0

.dw	move.l	clock(a5),d4
	moveq	#0,d0
	move	mPeriod(a4),d0

	divu.l	d0,d4

	lsl.l	#8,d4
	lsl.l	#6,d4

	move.l	mrate(a5),d0
	lsr.l	#4,d0

	divu.l	d0,d4
	swap	d4

	move.l	vtabaddr(a5),d2
	move	mVolume(a4),d0
	mulu	PS3M_master(a5),d0
	lsr	#6,d0
	lsl.l	#8,d0
	add.l	d0,d2			; Position in volume table

	move.l	(a4),a0			;pos (addr)
	move.l	mFPos(a4),d0		;fpos

	move.l	mLength(a4),d6		;len
	beq.w	.resloop

	cmp.l	#$ffff,d6
	bls.b	.restart
	move	#$ffff,d6
.restart
	swap	d6
	swap	d0
	sub.l	d0,d6
	swap	d0
	move.l	d4,d5
	swap	d5

	divul.l	d5,d5:d6		; bytes left to loop end
	tst.l	d5
	beq.b	.e
	addq.l	#1,d6
.e
	moveq	#0,d3
	moveq	#0,d5
.mixloop
	moveq	#8,d1
	cmp	d1,d7
	bhs.b	.ok
	move	d7,d1
.ok	cmp.l	d1,d6
	bhs.b	.ok2
	move.l	d6,d1
.ok2	sub	d1,d7
	sub.l	d1,d6

	jmp	.jtab1(pc,d1*2)

.a set 0
.jtab1
	rept	8
	bra.b	.mend-.a
.a set .a+14				; (mend - dmix) / 8
	endr

.dmix	rept	8
	move.b	(a0,d0),d2
	move.l	d2,a1
	move.b	(a1),d3
	move	d3,(a2)+
	add.l	d4,d0
	addx	d5,d0
	endr
.mend	tst	d7
	beq.b	.done
	tst.l	d6
	bne.w	.mixloop

.resloop
	tst.b	mLoop(a4)
	bne.b	.q
	st	mOnOff(a4)
	bra.b	.ty

.q	moveq	#0,d1
	move	d0,d1
	sub.l	mLength(a4),d1
	move.l	mLStart(a4),a0
	add.l	d1,a0
	move.l	mLLength(a4),d6
	sub.l	d1,d6
	move.l	d6,mLength(a4)
	cmp.l	#$ffff,d6
	bls.b	.j
	move	#$ffff,d6
.j	clr	d0			;reset integer part
	bra.w	.restart

.done	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)
	sub.l	d1,mLength(a4)
	bpl.b	.u

	tst.b	mLoop(a4)
	bne.b	.q2
	st	mOnOff(a4)
	bra.b	.u

.q2	move.l	mLLength(a4),d6
	sub.l	(a4),a0
	add.l	mLStart(a4),a0
	sub.l	d6,a0
	add.l	d6,mLength(a4)
	move.l	a0,(a4)
.u	rts

.ty	move.l	#$800080,d0
	lsr	d7
	bcc.b	.sk
	move	d0,(a2)+
.sk	subq	#1,d7
	bmi.b	.u
.lk	move.l	d0,(a2)+
	dbf	d7,.lk
	rts


.vol0	move.l	clock(a5),d4
	moveq	#0,d0
	move	mPeriod(a4),d0

	divu.l	d0,d4

	lsl.l	#8,d4
	lsl.l	#6,d4

	move.l	mrate(a5),d0
	lsr.l	#4,d0

	divu.l	d0,d4

	move.l	(a4),a0
	move.l	mFPos(a4),d0

	mulu.l	d7,d4

	swap	d0
	add.l	d4,d0			; Position after "mixing"
	swap	d0
	
	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)
	sub.l	d1,mLength(a4)
	bpl.b	.ty			; OK, Done!

; We're about to mix past the end of the sample

	tst.b	mLoop(a4)
	bne.b	.q3
	st	mOnOff(a4)
	bra.b	.ty

.q3	move.l	mLLength(a4),d6
.loop	sub.l	d6,a0
	add.l	d6,mLength(a4)
	bmi.b	.loop
	beq.b	.loop

	move.l	a0,(a4)
	bra.b	.ty


; Mixing routine for rest of the channels (adds data)

mix2_020
	moveq	#0,d7
	move	bytes2do(a5),d7
	tst	mPeriod(a4)
	beq.w	.ty
	tst.b	mOnOff(a4)
	bne.w	.ty

	tst	mVolume(a4)
	beq.w	.vol0

.dw	move.l	clock(a5),d4
	moveq	#0,d0
	move	mPeriod(a4),d0

	divu.l	d0,d4

	lsl.l	#8,d4
	lsl.l	#6,d4

	move.l	mrate(a5),d0
	lsr.l	#4,d0

	divu.l	d0,d4

	swap	d4

	move.l	vtabaddr(a5),d2
	move	mVolume(a4),d0
	mulu	PS3M_master(a5),d0
	lsr	#6,d0
	lsl.l	#8,d0
	add.l	d0,d2			; Position in volume table

	move.l	(a4),a0
	move.l	mFPos(a4),d0

	move.l	mLength(a4),d6
	beq.w	.resloop

	cmp.l	#$ffff,d6
	bls.b	.restart
	move	#$ffff,d6
.restart
	swap	d6
	swap	d0
	sub.l	d0,d6
	swap	d0

	move.l	d4,d5
	swap	d5

	divul.l	d5,d5:d6		; bytes left to loop end
	tst.l	d5
	beq.b	.e
	addq.l	#1,d6
.e	moveq	#0,d3
	moveq	#0,d5
.mixloop
	moveq	#8,d1
	cmp	d1,d7
	bhi.b	.ok
	move	d7,d1
.ok	cmp.l	d1,d6
	bhi.b	.ok2
	move	d6,d1
.ok2	sub	d1,d7
	sub.l	d1,d6
	jmp	.jtab1(pc,d1*2)

.a set 0
.jtab1	rept	8
	bra.b	.mend-.a
.a set .a+14				; (mend - dmix) / 8
	endr

.dmix	rept	8
	move.b	(a0,d0),d2
	move.l	d2,a1
	move.b	(a1),d3
	add	d3,(a2)+
	add.l	d4,d0
	addx	d5,d0
	endr
.mend	tst	d7
	beq.b	.done
	tst.l	d6
	bne.w	.mixloop

.resloop
	tst.b	mLoop(a4)
	bne.b	.q
	st	mOnOff(a4)
	bra.b	.tyy

.q	moveq	#0,d1
	move	d0,d1
	sub.l	mLength(a4),d1
	move.l	mLStart(a4),a0
	add.l	d1,a0
	move.l	mLLength(a4),d6
	sub.l	d1,d6
	move.l	d6,mLength(a4)
	cmp.l	#$ffff,d6
	bls.b	.j
	move	#$ffff,d6
.j	clr	d0			;reset integer part
	bra.w	.restart

.done	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)
	sub.l	d1,mLength(a4)
	bpl.b	.u

	tst.b	mLoop(a4)
	bne.b	.q2
	st	mOnOff(a4)
	bra.b	.u

.q2	move.l	mLLength(a4),d6
	sub.l	(a4),a0
	add.l	mLStart(a4),a0
	sub.l	d6,a0
	add.l	d6,mLength(a4)
	move.l	a0,(a4)

.u	addq	#1,chans
.ty	rts

.tyy	move.l	#$800080,d0
	lsr	d7
	bcc.b	.sk
	add	d0,(a2)+
.sk	subq	#1,d7
	bmi.b	.u
.lk	add.l	d0,(a2)+
	dbf	d7,.lk
	bra.b	.u


.vol0	move.l	clock(a5),d4
	moveq	#0,d0
	move	mPeriod(a4),d0

	divu.l	d0,d4

	lsl.l	#8,d4
	lsl.l	#6,d4

	move.l	mrate(a5),d0
	lsr.l	#4,d0

	divu.l	d0,d4

	move.l	(a4),a0
	move.l	mFPos(a4),d0

	mulu.l	d7,d4

	swap	d0
	add.l	d4,d0			; Position after "mixing"
	swap	d0
	
	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)
	sub.l	d1,mLength(a4)
	bpl.b	.ty			; OK, Done!

; We're about to mix past the end of the sample

	tst.b	mLoop(a4)
	bne.b	.q3
	st	mOnOff(a4)
	bra.b	.ty

.q3	move.l	mLLength(a4),d6
.loop	sub.l	d6,a0
	add.l	d6,mLength(a4)
	bmi.b	.loop
	beq.b	.loop

	move.l	a0,(a4)
	bra.b	.ty



; Mixing routine for the first channel (moves data)


mix16_020
	moveq	#0,d7
	move	bytes2do(a5),d7
	tst	mPeriod(a4)
	beq.w	.ty
	tst.b	mOnOff(a4)
	bne.w	.ty

	tst	mVolume(a4)
	beq.w	.vol0

.dw	move.l	clock(a5),d4
	moveq	#0,d0
	move	mPeriod(a4),d0

	divu.l	d0,d4

	lsl.l	#8,d4
	lsl.l	#6,d4

	move.l	mrate(a5),d0
	lsr.l	#4,d0

	divu.l	d0,d4
	swap	d4

	move.l	vtabaddr(a5),a3
	move	mVolume(a4),d0
	mulu	PS3M_master(a5),d0
	lsr	#6,d0
	add	d0,d0
	lsl.l	#8,d0
	add.l	d0,a3			; Position in volume table

	move.l	(a4),a0			;pos (addr)
	move.l	mFPos(a4),d0		;fpos

	move.l	mLength(a4),d6		;len
	beq.w	.resloop

	cmp.l	#$ffff,d6
	bls.b	.restart
	move	#$ffff,d6
.restart
	swap	d6
	swap	d0
	sub.l	d0,d6
	swap	d0
	move.l	d4,d5
	swap	d5

	divul.l	d5,d5:d6		; bytes left to loop end
	tst.l	d5
	beq.b	.e
	addq.l	#1,d6
.e
	moveq	#0,d5
	moveq	#0,d2
.mixloop
	moveq	#8,d1
	cmp	d1,d7
	bhs.b	.ok
	move	d7,d1
.ok	cmp.l	d1,d6
	bhs.b	.ok2
	move.l	d6,d1
.ok2	sub	d1,d7
	sub.l	d1,d6

	jmp	.jtab1(pc,d1*2)

.a set 0
.jtab1
	rept	8
	bra.b	.mend-.a
.a set .a+12				; (mend - dmix) / 8
	endr

.dmix	rept	8
	move.b	(a0,d0),d2
	add.l	d4,d0
	move	(a3,d2*2),(a2)+
	addx	d5,d0
	endr

.mend	tst	d7
	beq.b	.done
	tst.l	d6
	bne.w	.mixloop

.resloop
	tst.b	mLoop(a4)
	bne.b	.q
	st	mOnOff(a4)
	bra.b	.ty

.q	moveq	#0,d1
	move	d0,d1
	sub.l	mLength(a4),d1
	move.l	mLStart(a4),a0
	add.l	d1,a0
	move.l	mLLength(a4),d6
	sub.l	d1,d6
	move.l	d6,mLength(a4)
	cmp.l	#$ffff,d6
	bls.b	.j
	move	#$ffff,d6
.j	clr	d0			;reset integer part
	bra.w	.restart

.done	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)
	sub.l	d1,mLength(a4)
	bpl.b	.u

	tst.b	mLoop(a4)
	bne.b	.q2
	st	mOnOff(a4)
	bra.b	.u

.q2	move.l	mLLength(a4),d6
	sub.l	(a4),a0
	add.l	mLStart(a4),a0
	sub.l	d6,a0
	add.l	d6,mLength(a4)
	move.l	a0,(a4)
.u	rts

.ty	addq	#1,d7
	beq.b	.u

	moveq	#0,d0
	lsr	d7
	bcc.b	.sk
	move	d0,(a2)+
.sk	subq	#1,d7
	bmi.b	.u
.lk	move.l	d0,(a2)+
	dbf	d7,.lk
	rts

.vol0	move.l	clock(a5),d4
	moveq	#0,d0
	move	mPeriod(a4),d0

	divu.l	d0,d4

	lsl.l	#8,d4
	lsl.l	#6,d4

	move.l	mrate(a5),d0
	lsr.l	#4,d0

	divu.l	d0,d4

	move.l	(a4),a0
	move.l	mFPos(a4),d0

	mulu.l	d7,d4

	swap	d0
	add.l	d4,d0			; Position after "mixing"
	swap	d0
	
	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)
	sub.l	d1,mLength(a4)
	bpl.b	.ty			; OK, Done!

; We're about to mix past the end of the sample

	tst.b	mLoop(a4)
	bne.b	.q3
	st	mOnOff(a4)
	bra.b	.ty

.q3	move.l	mLLength(a4),d6
.loop	sub.l	d6,a0
	add.l	d6,mLength(a4)
	bmi.b	.loop
	beq.b	.loop

	move.l	a0,(a4)
	bra.b	.ty


; Mixing routine for rest of the channels (adds data)

mix162_020
	moveq	#0,d7
	move	bytes2do(a5),d7
	tst	mPeriod(a4)
	beq.w	.ty
	tst.b	mOnOff(a4)
	bne.w	.ty

	tst	mVolume(a4)
	beq.w	.vol0

.dw	move.l	clock(a5),d4
	moveq	#0,d0
	move	mPeriod(a4),d0

	divu.l	d0,d4

	lsl.l	#8,d4
	lsl.l	#6,d4

	move.l	mrate(a5),d0
	lsr.l	#4,d0

	divu.l	d0,d4

	swap	d4

	move.l	vtabaddr(a5),a3
	move	mVolume(a4),d0
	mulu	PS3M_master(a5),d0
	lsr	#6,d0
	add	d0,d0
	lsl.l	#8,d0
	add.l	d0,a3			; Position in volume table

	move.l	(a4),a0
	move.l	mFPos(a4),d0

	move.l	mLength(a4),d6
	beq.w	.resloop

	cmp.l	#$ffff,d6
	bls.b	.restart
	move	#$ffff,d6
.restart
	swap	d6
	swap	d0
	sub.l	d0,d6
	swap	d0

	move.l	d4,d5
	swap	d5

	divul.l	d5,d5:d6		; bytes left to loop end
	tst.l	d5
	beq.b	.e
	addq.l	#1,d6
.e	moveq	#0,d2
	moveq	#0,d5
.mixloop
	moveq	#8,d1
	cmp	d1,d7
	bhi.b	.ok
	move	d7,d1
.ok	cmp.l	d1,d6
	bhi.b	.ok2
	move	d6,d1
.ok2	sub	d1,d7
	sub.l	d1,d6
	jmp	.jtab1(pc,d1*2)

.a set 0
.jtab1
	rept	8
	bra.b	.mend-.a
.a set .a+14				; (mend - dmix) / 8
	endr

.dmix	rept	8
	move.b	(a0,d0),d2
	move	(a3,d2*2),d3
	add	d3,(a2)+
	add.l	d4,d0
	addx	d5,d0
	endr

.mend	tst	d7
	beq.b	.done
	tst.l	d6
	bne.w	.mixloop

.resloop
	tst.b	mLoop(a4)
	bne.b	.q
	st	mOnOff(a4)
	bra.b	.tyy

.q	moveq	#0,d1
	move	d0,d1
	sub.l	mLength(a4),d1
	move.l	mLStart(a4),a0
	add.l	d1,a0
	move.l	mLLength(a4),d6
	sub.l	d1,d6
	move.l	d6,mLength(a4)
	cmp.l	#$ffff,d6
	bls.b	.j
	move	#$ffff,d6
.j	clr	d0			;reset integer part
	bra.w	.restart

.done	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)
	sub.l	d1,mLength(a4)
	bpl.b	.u

	tst.b	mLoop(a4)
	bne.b	.q2
	st	mOnOff(a4)
	bra.b	.u

.q2	move.l	mLLength(a4),d6
	sub.l	(a4),a0
	add.l	mLStart(a4),a0
	sub.l	d6,a0
	add.l	d6,mLength(a4)
	move.l	a0,(a4)
.u
.ty
.tyy	rts


.vol0	move.l	clock(a5),d4
	moveq	#0,d0
	move	mPeriod(a4),d0

	divu.l	d0,d4

	lsl.l	#8,d4
	lsl.l	#6,d4

	move.l	mrate(a5),d0
	lsr.l	#4,d0

	divu.l	d0,d4

	move.l	(a4),a0
	move.l	mFPos(a4),d0

	mulu.l	d7,d4

	swap	d0
	add.l	d4,d0			; Position after "mixing"
	swap	d0
	
	moveq	#0,d1
	move	d0,d1
	add.l	d1,a0
	clr	d0
	move.l	a0,(a4)
	move.l	d0,mFPos(a4)
	sub.l	d1,mLength(a4)
	bpl.b	.ty			; OK, Done!

; We're about to mix past the end of the sample

	tst.b	mLoop(a4)
	bne.b	.q3
	st	mOnOff(a4)
	bra.b	.ty

.q3	move.l	mLLength(a4),d6
.loop	sub.l	d6,a0
	add.l	d6,mLength(a4)
	bmi.b	.loop
	beq.b	.loop

	move.l	a0,(a4)
	bra.b	.ty

	endc


* mulu_32 --- d0 = d0*d1
mulu_32	movem.l	d2/d3,-(sp)
	move.l	d0,d2
	move.l	d1,d3
	swap	d2
	swap	d3
	mulu	d1,d2
	mulu	d0,d3
	mulu	d1,d0
	add	d3,d2
	swap	d2
	clr	d2
	add.l	d2,d0
	movem.l	(sp)+,d2/d3
	rts	

* divu_32 --- d0 = d0/d1, d1=jakojäännös
divu_32	move.l	d3,-(a7)
	swap	d1
	tst	d1
	bne.b	lb_5f8c
	swap	d1
	move.l	d1,d3
	swap	d0
	move	d0,d3
	beq.b	lb_5f7c
	divu	d1,d3
	move	d3,d0
lb_5f7c	swap	d0
	move	d0,d3
	divu	d1,d3
	move	d3,d0
	swap	d3
	move	d3,d1
	move.l	(a7)+,d3
	rts	

lb_5f8c	swap	d1
	move	d2,-(a7)
	moveq	#16-1,d3
	move	d3,d2
	move.l	d1,d3
	move.l	d0,d1
	clr	d1
	swap	d1
	swap	d0
	clr	d0
lb_5fa0	add.l	d0,d0
	addx.l	d1,d1
	cmp.l	d1,d3
	bhi.b	lb_5fac
	sub.l	d3,d1
	addq	#1,d0
lb_5fac	dbf	d2,lb_5fa0
	move	(a7)+,d2
	move.l	(a7)+,d3
	rts	


;;******** Init routines ***********


detectchannels
	lea	ch(pc),a0
	moveq	#7,d0
.l2	clr.l	(a0)+
	dbf	d0,.l2

	move.l	patts(a5),a1
	lea	ch(pc),a2
	move.l	s3m(a5),a0
	move	pats(a5),d7
	subq	#1,d7
.pattloop
	moveq	#0,d0
	move	(a1)+,d0
	beq.b	.qt
	iword	d0
	lsl.l	#4,d0
	lea	(a0,d0.l),a3
	addq.l	#2,a3
	moveq	#63,d6
.rowloop
	move.b	(a3)+,d0
	beq.b	.newrow

	moveq	#31,d1
	and	d0,d1

	moveq	#32,d2
	and	d0,d2
	beq.b	.nnot

	tst.b	(a3)
	bmi.b	.skip
	beq.b	.skip

	tst.b	1(a3)
	bmi.b	.skip
	beq.b	.skip

	st	(a2,d1)

.skip	addq.l	#2,a3

.nnot	moveq	#64,d2
	and	d0,d2
	beq.b	.nvol

	addq.l	#1,a3

.nvol	and	#128,d0
	beq.b	.rowloop

	move.b	(a3),d0
	cmp.b	#1,d0
	blo.b	.skip2

	cmp.b	#`Z`-`@`,d0
	bhi.b	.skip2

	st	(a2,d1)

.skip2	addq.l	#2,a3
	bra.b	.rowloop

.newrow
	dbf	d6,.rowloop
.qt
	dbf	d7,.pattloop	

	moveq	#1,d0
	moveq	#1,d1
	moveq	#31,d7
	moveq	#0,d5
	moveq	#0,d6
	lea	$40(a0),a1
	lea	pantab(a5),a0
.l	clr.b	(a0)
	tst.b	(a2)+
	beq.b	.d

	move.b	(a1),d2
	bmi.b	.d
	cmp.b	#8,d2
	blo.b	.vas
	move.b	#-1,(a0)
	move	d1,d0
	addq	#1,d5
	bra.b	.d
.vas	move.b	#1,(a0)
	move	d1,d0
	addq	#1,d6
.d	addq.l	#1,a1
	addq.l	#1,a0
	addq	#1,d1
	dbf	d7,.l

	cmp	d5,d6
	bls.b	.k	
	move	d6,d5
.k	move	d5,maxchan(a5)
	
	move	d0,numchans(a5)
ret	rts

ch	ds.b	32


makedivtabs
	cmp	#STEREO14,pmode(a5)
	beq.b	ret

	lea	divtabs(a5),a1
	move.l	dtab(a5),a0

	move	#255,d6
	moveq	#0,d5
	move	maxchan(a5),d5
	move.l	d5,d3
	move.l	d5,d2

	subq	#1,d5
	move	d5,d4
	lsl.l	#7,d5

	lsl.l	#7,d2

	sub.l	vboost(a5),d3
	cmp	#1,d3
	bge.b	.laa
	moveq	#1,d3

.laa	moveq	#0,d0
	move	d6,d7
	move.l	a0,(a1)+
.l	move.l	d0,d1
	add.l	d5,d1
	sub.l	d2,d1
	divs	d3,d1
	cmp	#$7f,d1
	ble.b	.d
	move	#$7f,d1
.d	cmp	#$ff80,d1
	bge.b	.d2
	move	#$80,d1
.d2	move.b	d1,(a0)+
	addq.l	#1,d0
	dbf	d7,.l

	add	#256,d6
	sub.l	#$80,d5
	dbf	d4,.laa
	rts


Makevoltable
	move.l	vtabaddr(a5),a0

	cmp	#STEREO14,pmode(a5)
	beq.b	bit16

	moveq	#0,d3		;volume
	cmp	#1,fformat(a5)
	beq.b	signed

.lop	moveq	#0,d4		;data
.lap	move	d4,d5
	sub	#$80,d5
	mulu	d3,d5
	asr.l	#6,d5
	add	#$80,d5
	move.b	d5,(a0)+
	addq	#1,d4
	cmp	#256,d4
	bne.b	.lap
	addq	#1,d3
	cmp	#65,d3
	bne.b	.lop
	rts

signed
.lop	moveq	#0,d4		;data
.lap	move.b	d4,d5
	ext	d5
	mulu	d3,d5
	asr.l	#6,d5
	add	#$80,d5
	move.b	d5,(a0)+
	addq	#1,d4
	cmp	#256,d4
	bne.b	.lap
	addq	#1,d3
	cmp	#65,d3
	bne.b	.lop
	rts


bit16	move	maxchan(a5),d3
	moveq	#0,d7		; "index"

	cmp	#1,fformat(a5)
	beq.b	signed2

.lop	move	d7,d6
	tst.b	d7
	bmi.b	.above

	and	#127,d6
	move	#128,d5
	sub	d6,d5
	lsl	#8,d5
	move	d7,d6
	lsr	#8,d6
	mulu	d6,d5
	divu	#63,d5
	swap	d5
	clr	d5
	swap	d5
	divu	d3,d5
	neg	d5
	move	d5,(a0)+
	addq	#1,d7
	cmp	#256*65,d7
	bne.b	.lop
	rts

.above	and	#127,d6
	lsl	#8,d6

	move	d7,d5
	lsr	#8,d5
	mulu	d6,d5
	divu	#63,d5
	swap	d5
	clr	d5
	swap	d5
	divu	d3,d5
	move	d5,(a0)+
	addq	#1,d7
	cmp	#256*65,d7
	bne.b	.lop
	rts

signed2
.lop	move	d7,d6
	tst.b	d7
	bpl.b	.above

	and	#127,d6
	move	#128,d5
	sub	d6,d5
	lsl	#8,d5
	move	d7,d6
	lsr	#8,d6
	mulu	d6,d5
	divu	#63,d5
	swap	d5
	clr	d5
	swap	d5
	divu	d3,d5
	neg	d5
	move	d5,(a0)+
	addq	#1,d7
	cmp	#256*65,d7
	bne.b	.lop
	rts

.above	and	#127,d6
	lsl	#8,d6

	move	d7,d5
	lsr	#8,d5
	mulu	d6,d5
	divu	#63,d5
	swap	d5
	clr	d5
	swap	d5
	divu	d3,d5
	move	d5,(a0)+
	addq	#1,d7
	cmp	#256*65,d7
	bne.b	.lop
	rts


do14tab	move.l	buff14(a5),a0

	tst.b	CyberCalibration(a5)
	bne.b	.docyber


	moveq	#0,d7
.loo	move	d7,d2
	bpl.b	.plus

	neg	d2
	move	d2,d3
	lsr	#8,d2
	neg.b	d2

	lsr.b	#2,d3
	neg	d3

	move.b	d2,(a0)+
	move.b	d3,(a0)+
	addq.l	#2,d7
	cmp.l	#$10000,d7
	bne.b	.loo
	rts

.plus	move	d2,d3
	lsr	#8,d2
	lsr.b	#2,d3
	move.b	d2,(a0)+
	move.b	d3,(a0)+
	addq.l	#2,d7
	cmp.l	#$10000,d7
	bne.b	.loo
	rts



*****************************************************************************
*
* CyberSound: 14 Bit sound driver
*
* (c) 1995 by Christian Buchner
*
*****************************************************************************
*
* AsmSupport.asm
*

* _CreateTable **************************************************************

		; Parameters

.docyber
	move.l	CyberTable(a5),a1


		; a0 = Table address
		; (MUST have enough space for 65536 UWORDS)
		; a1 = Additive Array
		; 256 UBYTEs
		;
		; the table is organized as follows:
		; 32768 UWORDS positive range, ascending order
		; 32768 UWORDS negative range, ascending order
		; access: (a0,d0.l*2)
		; where d0.w is signed word sample data
		; and the upper word of d0.l is *cleared!*



		movem.l	a2/d2-d6,-(sp)

		lea	128(a1),a2

		move.l	a2,a1			; count the number of steps
		moveq	#128-1,d0		; in the positive range
		moveq	#0,d5
.countpositive	move.b	(a1)+,d1
		ext.w	d1
		ext.l	d1
		add.l	d1,d5
		dbra	d0,.countpositive	; d5=number of steps
		move.l	#32768,d6		; reset stretch counter
		
		move.l	a2,a1			; middle value in calibdata
		move.w	#32768-1,d0		; number of positive values -1
		moveq	#0,d1			; HI value
		moveq	#0,d2			; LO value
		moveq	#0,d3			; counter
.fetchnext2	move.b	(a1)+,d4		; add calibtable to counter
		ext.w	d4
		add.w	d4,d3
.outerloop2	tst.w	d3
		bgt.s	.positive2
.negative2	addq.w	#1,d1			; increment HI value
		sub.w	d4,d2			; reset LO value
		bra.s	.fetchnext2
.positive2	move.b	d1,(a0)+		; store HI and LO value
		move.b	d2,(a0)+
		sub.l	d5,d6			; stretch the table
		bpl.s	.repeat2		; to 32768 entries
		add.l	#32768,d6
		addq.w	#1,d2			; increment LO value
		subq.w	#1,d3			; decrement counter
.repeat2	dbra	d0,.outerloop2

		move.l	a2,a1			; count the number of steps
		moveq	#128-1,d0		; in the negative range
		moveq	#0,d5
.countnegative	move.b	-(a1),d1
		ext.w	d1
		ext.l	d1
		add.l	d1,d5
		dbra	d0,.countnegative	; d5=number of steps
		move.l	#32768,d6		; reset stretch counter
		
		add.l	#2*32768,a0		; place at the end of the table
		move.l	a2,a1			; middle value in calibdata
		move.w	#32768-1,d0		; number of negative values -1
		moveq	#-1,d1			; HI value
		moveq	#-1,d2			; LO value
		moveq	#0,d3			; counter
.fetchnext1	move.b	-(a1),d4		; add calibtable to counter
		ext.w	d4
		add.w	d4,d3
		add.w	d4,d2			; maximize LO value
.outerloop1	tst.w	d3
		bgt.s	.positive1
.negative1	subq.w	#1,d1
		bra.s	.fetchnext1
.positive1	move.b	d2,-(a0)		; store LO and HI value
		move.b	d1,-(a0)
		sub.l	d5,d6			; stretch the table
		bpl.s	.repeat1		; to 32768 entries
		add.l	#32768,d6
		subq.w	#1,d2			; decrement lo value
		subq.w	#1,d3			; decrement counter
.repeat1	dbra	d0,.outerloop1

		movem.l	(sp)+,a2/d2-d6
		rts




;;********** S3M Play Routine **********


s3m_init
;	move.l	#AHIST_M8U,setsampletype
	move.l	#AHIST_M8S,setsampletype

	move.l	s3m(a5),a0
	move.l	a0,mname(a5)
	move	ordernum(a0),d0
	iword	d0
	move	d0,slen(a5)
	move	d0,positioneita(a5)

	move	patnum(a0),d0
	iword	d0
	move	d0,pats(a5)

	move	insnum(a0),d0
	iword	d0
	move	d0,inss(a5)

	move	ffv(a0),d0
	iword	d0
	move	#$0100,ffv(a0)	* signed!
	

	move	flags(a0),d0
	iword	d0
	move	d0,sflags(a5)

	cmp	#$1301,fformat(a5)
	bhi.b	.ok

	bset	#6,sflags+1(a5)

.ok	lea	$60(a0),a1
	moveq	#0,d0
	move	slen(a5),d0
	moveq	#1,d1
	and	d0,d1
	add	d1,d0
	lea	(a1,d0.l),a2
	move.l	a2,samples(a5)

	move	inss(a5),d0
	add	d0,d0
	lea	(a2,d0.l),a3
	move.l	a3,patts(a5)

 	moveq	#0,d0
	move.b	(a1),d0
	add	d0,d0
	sub.l	a1,a1
	move	(a3,d0),d0
	beq.b	.q
	iword	d0
	asl.l	#4,d0
	lea	2(a0,d0.l),a1
.q	move.l	a1,ppos(a5)

	moveq	#0,d0
	move.b	initialspeed(a0),d0
	bne.b	.ok2
	moveq	#6,d0
.ok2	move	d0,spd(a5)

	move.b	initialtempo(a0),d0
	cmp	#32,d0
	bhi.b	.qw
	moveq	#125,d0
.qw	move	d0,tempo(a5)


	move	inss(a5),d0
	subq	#1,d0
	move.l	samples(a5),a2

.instloop
	moveq	#0,d1
	move	(a2)+,d1
	iword	d1
	lsl.l	#4,d1
	lea	(a0,d1.l),a1

*** Vaihdetaan unsigned -> signed
	cmp	#1,fformat(a5)		* unsigned samples?
	beq.b	.kon0	

	moveq	#0,d1
	move	insmemseg(a1),d1
	iword	d1
	lsl.l	#4,d1
	lea	(a0,d1.l),a3	* sample data start
	move.l	inslength(a1),d1
	beq.b	.skip
	ilword	d1
	subq	#1,d1
	moveq	#-128,d2
.kon	eor.b	d2,(a3)+
	dbf	d1,.kon
.skip
.kon0	
***
	btst	#0,insflags(a1)
	beq.b	.eloo
	move.l	insloopend(a1),d1
	ilword	d1
	cmp.l	#2,d1
	bls.b	.eloo
	move.l	insloopend(a1),inslength(a1)
.eloo	dbf	d0,.instloop


	move	#1,fformat(a5)		* muutetaan signed.

	clr	pos(a5)
	clr	rows(a5)
	clr	cn(a5)
	clr	pdelaycnt(a5)
	clr	pjmpflag(a5)
	clr	pbrkflag(a5)
	clr	pbrkrow(a5)

	bsr.w	detectchannels

	move.l	#14317056/4,clock(a5)		; Clock constant
	move	#64,globalVol(a5)
	moveq	#0,d0
	rts


s3m_music
	lea	data,a5
	move.l	s3m(a5),a0

	addq	#1,cn(a5)
	move	cn(a5),d0
	cmp	spd(a5),d0
	beq.b	uusrow

ccmds	lea	c0(a5),a2
	lea	cha0(a5),a4
	move	numchans(a5),d7
	subq	#1,d7
.loo	btst	#7,5(a2)
	beq.b	.edi

	lea	cct(pc),a1
	moveq	#0,d0
	move.b	cmd(a2),d0
	cmp	#'Z'-'@',d0
	bhi.b	.edi
	add	d0,d0
	move	(a1,d0),d0
	jsr	(a1,d0)

.edi	lea	s3mChanBlock_SIZE(a2),a2
	lea	mChanBlock_SIZE(a4),a4
	dbf	d7,.loo
	rts

uusrow	clr	cn(a5)

	tst	pdelaycnt(a5)
	bne.b	process

	lea	c0(a5),a2
	move	numchans(a5),d7
	subq	#1,d7
.cl	clr.b	flgs(a2)
	lea	s3mChanBlock_SIZE(a2),a2
	dbf	d7,.cl

	move.l	ppos(a5),a1
	lea	c0(a5),a4		;chanblocks
.loo	move.b	(a1)+,d0
	beq.b	.end

	moveq	#$1f,d5
	and	d0,d5			;chan
	mulu	#s3mChanBlock_SIZE,d5
	lea	(a4,d5),a2

	and	#~31,d0
	move.b	d0,flgs(a2)
	
	moveq	#32,d2
	and	d0,d2
	beq.b	.nnot

	move.b	(a1)+,(a2)
	move.b	(a1)+,inst(a2)

.nnot	moveq	#64,d2
	and	d0,d2
	beq.b	.nvol

	move.b	(a1)+,vol(a2)

.nvol	and	#128,d0
	beq.b	.loo

	move.b	(a1)+,d0
	bmi.b	.d
	move.b	d0,cmd(a2)
.d	move.b	(a1)+,info(a2)
	bra.b	.loo

.end	move.l	a1,ppos(a5)

process	lea	c0(a5),a2
	lea	cha0(a5),a4
	move	numchans(a5),d7
	move.l	samples(a5),a5
	subq	#1,d7
	endb	a5

.lloo	tst.b	flgs(a2)
	beq.w	.evol

	moveq	#32,d0
	and.b	flgs(a2),d0
	beq.w	.f

	move.b	inst(a2),d0
	beq.w	.esmp
	bmi.w	.esmp

	cmp	inss,d0
	bgt.w	.mute

	btst	#7,flgs(a2)
	beq.b	.eii
	cmp.b	#'S'-'@',cmd(a2)
	bne.b	.eii
	move.b	info(a2),d1
	and	#$f0,d1
	cmp	#$d0,d1
	beq.w	.evol

.eii	add	d0,d0
	move	-2(a5,d0),d0
	iword	d0
	lsl	#4,d0
	lea	(a0,d0),a1

	moveq	#0,d0
	move	insmemseg(a1),d0
	iword	d0
	lsl.l	#4,d0
	move.l	a0,d4
	add.l	d0,d4

	move.l	insloopbeg(a1),d1
	ilword	d1
	move.l	insloopend(a1),d2
	ilword	d2
	sub.l	d1,d2
	add.l	d4,d1

	move.l	d1,mLStart(a4)
	move.l	d2,mLLength(a4)
	move.b	insvol(a1),volume+1(a2)
	cmp	#64,volume(a2)
	blo.b	.e
	move	#63,volume(a2)
.e	move.l	a1,sample(a2)

	btst	#0,insflags(a1)
	beq.b	.eloo
	cmp.l	#2,d2
	shi	mLoop(a4)
	bra.b	.esmp


.mute	st	mOnOff(a4)
	bra.w	.f

.eloo	clr.b	mLoop(a4)
.esmp	moveq	#0,d0
	move.b	(a2),d0
	beq.w	.f
	cmp.b	#254,d0
	beq.b	.mute
	cmp.b	#255,d0
	beq.w	.f

	move.b	d0,note(a2)
	move	d0,d1
	lsr	#4,d1

	and	#$f,d0
	add	d0,d0

	move.l	sample(a2),a1
	move.l	$20(a1),d2
	ilword	d2

	lea	Periods(pc),a1
	move	(a1,d0),d0
	mulu	#8363,d0
	lsl.l	#4,d0
	lsr.l	d1,d0	

	divu	d2,d0


	btst	#7,flgs(a2)
	beq.b	.ei

	cmp.b	#'Q'-'@',cmd(a2)	;retrig
	beq.b	.eiik

.ei	clr.b	retrigcn(a2)

.eiik	clr.b	vibpos(a2)


	btst	#7,flgs(a2)
	beq.b	.eitopo

	cmp.b	#'G'-'@',cmd(a2)	;TOPO
	beq.b	.eddo

	cmp.b	#'L'-'@',cmd(a2)	;TOPO+VSLD
	bne.b	.eitopo

.eddo	move	d0,toperiod(a2)
	bra.b	.f

.eitopo	move	d0,mPeriod(a4)
	move	d0,period(a2)
	clr.l	mFPos(a4)

	move.l	sample(a2),d0
	beq.b	.f
	move.l	d0,a1

	moveq	#0,d0
	move	insmemseg(a1),d0
	iword	d0
	lsl.l	#4,d0
	move.l	a0,d4
	add.l	d0,d4

	move.l	inslength(a1),d0
	ilword	d0

	move.l	d4,(a4)
	move.l	d0,mLength(a4)
	clr.b	mOnOff(a4)

.f	moveq	#64,d0
	and.b	flgs(a2),d0
	beq.b	.evol
	move.b	vol(a2),volume+1(a2)
	cmp	#64,volume(a2)
	blo.b	.evol
	move	#63,volume(a2)

.evol	btst	#7,flgs(a2)
	beq.b	.eivib

	cmp.b	#'H'-'@',cmd(a2)
	beq.b	.vib

.eivib	bsr.w	checklimits
.vib

	btst	#7,flgs(a2)
	beq.b	.eitre

	cmp.b	#'R'-'@',cmd(a2)
	beq.b	.tre
	cmp.b	#'I'-'@',cmd(a2)
	beq.b	.tre

.eitre	move	volume(a2),d0
	mulu	globalVol,d0
	lsr	#6,d0
	move	d0,mVolume(a4)

.tre	btst	#7,flgs(a2)
	beq.b	.edd

	move.b	info(a2),d0
	beq.b	.dd
	move.b	d0,lastcmd(a2)
.dd	lea	ct(pc),a1
	moveq	#0,d0
	move.b	cmd(a2),d0
	cmp	#'Z'-'@',d0
	bhi.b	.edd

	add	d0,d0
	move	(a1,d0),d0
	jsr	(a1,d0)

.edd	lea	s3mChanBlock_SIZE(a2),a2
	lea	mChanBlock_SIZE(a4),a4
	dbf	d7,.lloo

	basereg	data,a5
	lea	data,a5

	tst	pdelaycnt(a5)
	beq.b	.oke

	subq	#1,pdelaycnt(a5)
	bra.w	xm_exit
.oke
	addq	#1,rows(a5)

	tst	pbrkflag(a5)		; do we have to break this pattern?
	beq.b	.nobrk
	move	pbrkrow(a5),rows(a5)
	clr	pbrkrow(a5)		; clr break position
.nobrk
	cmp	#64,rows(a5)
	bcc.b	.newpos				; worst case opt: branch not taken

	tst	pjmpflag(a5)		; do we have to jump?
	bne.b	.newpos

	tst	pbrkflag(a5)
	beq.w	dee
	bra.b	cont
.newpos
	move	pbrkrow(a5),rows(a5)
	clr	pbrkrow(a5)		; clr break position

burk	addq	#1,pos(a5)			; inc songposition
	move	slen(a5),d0
	cmp	pos(a5),d0			; are we thru with all patterns?
	bgt.b	cont				; nope
	clr	pos(a5)
	st	PS3M_break(a5)

	moveq	#0,d0
	move.b	initialspeed(a0),d0
	bne.b	.ok
	moveq	#6,d0
.ok	move	d0,spd(a5)

cont	move	pos(a5),d0
	move	d0,PS3M_position(a5)
	st	PS3M_poscha(a5)

	moveq	#0,d1
	move.b	orders(a0,d0),d1
	cmp.b	#$fe,d1				; marker that is skipped
	beq.b	burk
	cmp.b	#$ff,d1				; end of tune mark
	beq.b	burk
	cmp	pats(a5),d1
	bhs.b	burk

	add	d1,d1
	move.l	patts(a5),a3
	moveq	#0,d0
	move	(a3,d1),d0
	beq.b	burk
	iword	d0
	lsl.l	#4,d0
	lea	2(a0,d0.l),a1

	clr	pjmpflag(a5)
	clr	pbrkflag(a5)

	move	rows(a5),d0
	beq.b	.setp
	subq	#1,d0
	moveq	#0,d1
.loop	move.b	(a1)+,d1
	beq.b	.next

	moveq	#32,d2
	and	d1,d2
	beq.b	.nnot
	addq	#2,a1
.nnot
	moveq	#64,d2
	and	d1,d2
	beq.b	.nvol
	addq	#1,a1
.nvol
	and	#128,d1
	beq.b	.loop
	addq	#2,a1

	bra.b	.loop
.next
	dbf	d0,.loop
.setp
	move.l	a1,ppos(a5)

dee	bra.w	xm_dee
	endb	a5


ct	dc	rt-ct
	dc	changespeed-ct
	dc	posjmp-ct
	dc	patbrk-ct
	dc	vslide-ct
	dc	portadwn-ct
	dc	portaup-ct
	dc	rt-ct
	dc	rt-ct
	dc	tremor-ct
	dc	arpeggio-ct
	dc	rt-ct
	dc	rt-ct
	dc	rt-ct
	dc	rt-ct
	dc	soffset-ct
	dc	rt-ct
	dc	retrig-ct
	dc	rt-ct
	dc	specials-ct
	dc	stempo-ct
	dc	rt-ct
	dc	setmaster-ct
	dc	rt-ct
	dc	rt-ct
	dc	rt-ct
	dc	rt-ct



cct	dc	rt-cct
	dc	rt-cct
	dc	rt-cct
	dc	rt-cct
	dc	vslide-cct
	dc	portadwn-cct
	dc	portaup-cct
	dc	noteporta-cct
	dc	vibrato-cct
	dc	tremor-cct
	dc	arpeggio-cct
	dc	vvslide-cct
	dc	pvslide-cct
	dc	rt-cct
	dc	rt-cct
	dc	rt-cct
	dc	rt-cct
	dc	retrig-cct
	dc	tremolo-cct
	dc	specials-cct
	dc	rt-cct
	dc	finevib-cct
	dc	rt-cct
	dc	rt-cct
	dc	rt-cct
	dc	rt-cct
	dc	rt-cct

tremolo
rt	rts

tremor
	move.b	info(a2),d0
	beq.b	.toggle
	move.b	d0,tvalue(a2)
.toggle
	subq.b	#1,tcount(a2)
	bhi.b	.volume
	move.b	tvalue(a2),d0
	not	ttoggle(a2)
	beq.b	.off
	lsr.b	#4,d0				; ontime
.off	and.b	#$f,d0				; offtime
	move.b	d0,tcount(a2)
.volume
	move	volume(a2),d0
	and	ttoggle(a2),d0
	move	d0,mVolume(a4)
	rts

changespeed
	move.b	info(a2),d0
	bne.b	.d
	moveq	#6,d0
.d	cmp.b	#32,d0
	bcs.b	.e
	moveq	#31,d0
.e	move.b	d0,spd+1
	rts

posjmp	clr	pbrkrow
	st	pjmpflag

	moveq	#0,d0
	move	pos,d0
	addq	#1,d0

	cmp	slen,d0
	bne.b	.notlast
	st	PS3M_break
.notlast
	moveq	#0,d0
	move.b	info(a2),d0
	cmp	pos,d0
	bhi.b	.e
	st	PS3M_break
.e	subq	#1,d0
	move	d0,pos
	st	PS3M_poscha
	rts

patbrk	moveq	#0,d0
	move.b	info(a2),d0
	moveq	#$f,d2
	and	d0,d2
	lsr	#4,d0
	add.b	.dtab(pc,d0),d2
	cmp.b	#63,d2		; valid line number given?
	ble.b	.ok	
	moveq	#0,d2		; else zero it
.ok	move	d2,pbrkrow
	st	pjmpflag
	st	PS3M_poscha
	rts

.dtab:	dc.b	0,10,20,30	; Don't think this little table is a waste!
	dc.b 	40,50,60,70	; The routine is shorter using this table
	dc.b	80,90,100,110	; and faster too :-)
	dc.b 	120,130,140,150	; 16 bytes vs. 8 instructions (wordlength)

vslide	moveq	#0,d0
	move.b	lastcmd(a2),d0
	moveq	#$f,d1
	and	d0,d1
	move	d0,d2
	lsr	#4,d2

	cmp.b	#$f,d1
	beq.b	.addfine

	cmp.b	#$f,d2
	beq.b	.subfine

	btst	#6,sflags+1
	bne.b	.ok

	tst	cn
	beq.b	.dd	

.ok	tst	d1
	beq.b	.add
	and	#$f,d0
	bra.b	.sub

.subfine
	tst	cn
	bne.b	.dd
	and	#$f,d0
.sub	sub	d0,volume(a2)
	bpl.b	.dd
	clr	volume(a2)
.dd	move	volume(a2),d0
	mulu	globalVol,d0
	lsr	#6,d0
	move	d0,mVolume(a4)
	rts

.addfine
	tst	d2
	beq.b	.sub
	tst	cn
	bne.b	.dd
.add	lsr	#4,d0

.add2	add	d0,volume(a2)
	cmp	#64,volume(a2)
	blo.b	.dd
	move	#63,volume(a2)
	bra.b	.dd


portadwn
	moveq	#0,d0
	move.b	lastcmd(a2),d0

	tst	cn
	beq.b	.fined
	cmp.b	#$e0,d0
	bhs.b	.dd
	lsl	#2,d0

.ddd	add	d0,period(a2)
	bra.b	checklimits
.dd	rts

.fined	cmp.b	#$e0,d0
	bls.b	.dd
	cmp.b	#$f0,d0
	bls.b	.extr
	and	#$f,d0
	lsl	#2,d0
	bra.b	.ddd

.extr	and	#$f,d0
	bra.b	.ddd

portaup
	moveq	#0,d0
	move.b	lastcmd(a2),d0

	tst	cn
	beq.b	.fined
	cmp.b	#$e0,d0
	bhs.b	.dd
	lsl	#2,d0

.ddd	sub	d0,period(a2)
	bra.b	checklimits

.dd	rts

.fined	cmp.b	#$e0,d0
	bls.b	.dd
	cmp.b	#$f0,d0
	bls.b	.extr
	and	#$f,d0
	lsl	#2,d0
	bra.b	.ddd

.extr	and	#$f,d0
	bra.b	.ddd


checklimits
	move	period(a2),d0
	btst	#4,sflags+1
	beq.b	.sii
	
	cmp	#856*4,d0
	bls.b	.dd
	move	#856*4,d0
.dd	cmp	#113*4,d0
	bhs.b	.dd2
	move	#113*4,d0
.dd2	move	d0,period(a2)
	move	d0,mPeriod(a4)
	rts

.sii	cmp	#$7fff,d0
	bls.b	.dd3
	move	#$7fff,d0
.dd3	cmp	#64,d0
	bhs.b	.dd4
	move	#64,d0
.dd4	move	d0,mPeriod(a4)
	rts


noteporta
	move.b	info(a2),d0
	beq.b	notchange
	move.b	d0,notepspd(a2)
notchange
	move	toperiod(a2),d0
	beq.b	.1
	moveq	#0,d1
	move.b	notepspd(a2),d1
	lsl	#2,d1

	cmp	period(a2),d0
	blt.b	.topoup

	add	d1,period(a2)
	cmp	period(a2),d0
	bgt.b	.1
	move	d0,period(a2)
	clr	toperiod(a2)
.1	move	period(a2),mPeriod(a4)
	rts

.topoup	sub	d1,period(a2)
	cmp	period(a2),d0
	blt.b	.dd
	move	d0,period(a2)
	clr	toperiod(a2)
.dd	move	period(a2),mPeriod(a4)
	rts


vibrato	move.b	cmd(a2),d0
	bne.b	.e
	move.b	vibcmd(a2),d0
	bra.b	.skip2

.e	move	d0,d1
	and	#$f0,d1
	bne.b	.skip2

	move.b	vibcmd(a2),d1
	and	#$f0,d1
	or	d1,d0

.skip2
	move.b	d0,vibcmd(a2)

vibrato2
	moveq	#$1f,d0
	and.b	vibpos(a2),d0
	moveq	#0,d2
	lea	mt_vibratotable(pc),a3
	move.b	(a3,d0),d2
	moveq	#$f,d0
	and.b	vibcmd(a2),d0
	mulu	d0,d2

	moveq	#4,d0
	btst	#0,sflags+1
	bne.b	.sii
	moveq	#5,d0
.sii	lsr	d0,d2
	move	period(a2),d0
	btst	#5,vibpos(a2)
	bne.b	.neg
	add	d2,d0
	bra.b	.vib3
.neg
	sub	d2,d0
.vib3
	move	d0,mPeriod(a4)
	move.b	vibcmd(a2),d0
	lsr.b	#4,d0
	add.b	d0,vibpos(a2)
	rts


finevib	move.b	cmd(a2),d0
	bne.b	.e
	move.b	vibcmd(a2),d0
	bra.b	.skip2

.e	move	d0,d1
	and	#$f0,d1
	bne.b	.skip2

	move.b	vibcmd(a2),d1
	and	#$f0,d1
	or	d1,d0

.skip2
	move.b	d0,vibcmd(a2)
	moveq	#$1f,d0
	and.b	vibpos(a2),d0
	moveq	#0,d2
	lea	mt_vibratotable(pc),a3
	move.b	(a3,d0),d2
	moveq	#$f,d0
	and.b	vibcmd(a2),d0
	mulu	d0,d2

	lsr	#7,d2
	move	period(a2),d0
	btst	#5,vibpos(a2)
	bne.b	.neg
	add	d2,d0
	bra.b	.vib3
.neg	sub	d2,d0
.vib3	move	d0,mPeriod(a4)
	move.b	vibcmd(a2),d0
	lsr.b	#4,d0
	add.b	d0,vibpos(a2)
	rts


arpeggio
	moveq	#0,d0
	move.b	note(a2),d0
	beq.b	.qq

	moveq	#$70,d1
	and	d0,d1
	and	#$f,d0

	moveq	#0,d2
	move	cn,d2
	divu	#3,d2
	swap	d2
	tst	d2
	beq.b	.norm
	subq	#1,d2
	beq.b	.1

	moveq	#$f,d2
	and.b	lastcmd(a2),d2
	add	d2,d0
.f	cmp	#12,d0
	blt.b	.norm
	sub	#12,d0
	add	#$10,d1
	bra.b	.f

.1	move.b	lastcmd(a2),d2
	lsr.b	#4,d2
	add.b	d2,d0
.f2	cmp	#12,d0
	blt.b	.norm
	sub	#12,d0
	add	#$10,d1
	bra.b	.f2

.norm	add	d0,d0
	lsr	#4,d1

	move.l	sample(a2),a1

	move.l	$20(a1),d2
	ilword	d2

	lea	Periods(pc),a1
	move	(a1,d0),d0
	mulu	#8363,d0
	lsl.l	#4,d0
	lsr.l	d1,d0
	divu	d2,d0
	move	d0,mPeriod(a4)
.qq	rts


pvslide	bsr.w	notchange
	bra.w	vslide

vvslide	bsr.w	vibrato2
	bra.w	vslide

soffset	moveq	#32,d0
	and.b	flgs(a2),d0
	beq.b	.f
	move.b	(a2),d0
	beq.b	.f
	cmp.b	#255,d0
	beq.b	.f

	move.l	sample(a2),d0
	beq.b	.f
	move.l	d0,a1

	moveq	#0,d0
	move	insmemseg(a1),d0
	iword	d0
	lsl.l	#4,d0
	move.l	a0,d4
	add.l	d0,d4

	move.l	inslength(a1),d0
	ilword	d0

	moveq	#0,d2
	move.b	lastcmd(a2),d2
	lsl.l	#8,d2
	add.l	d2,d4
	sub.l	d2,d0
	bpl.b	.ok
	move.l	mLStart(a4),d4
	move.l	mLLength(a4),d0
.ok	move.l	d4,(a4)
	move.l	d0,mLength(a4)
.f	rts


retrig	move.b	retrigcn(a2),d0
	subq.b	#1,d0
	cmp.b	#0,d0
	ble.b	.retrig

	move.b	d0,retrigcn(a2)
	rts

.retrig	move.l	sample(a2),d0
	beq.w	.f
	move.l	d0,a1
	moveq	#0,d1
	move	insmemseg(a1),d1
	iword	d1
	lsl.l	#4,d1
	move.l	a0,d4
	add.l	d1,d4

	move.l	inslength(a1),d1
	ilword	d1

	move.l	d4,(a4)
	move.l	d1,mLength(a4)
	clr.b	mOnOff(a4)
	clr.l	mFPos(a4)

	move.b	lastcmd(a2),d0
	moveq	#$f,d1
	and.b	d0,d1
	move.b	d1,retrigcn(a2)

	and	#$f0,d0
	lsr	#4,d0
	lea	ftab2(pc),a3
	moveq	#0,d2
	move.b	(a3,d0),d2
	beq.b	.ddq

	mulu	volume(a2),d2
	lsr	#4,d2
	move	d2,volume(a2)
	bra.b	.ddw

.ddq	lea	ftab1(pc),a3
	move.b	(a3,d0),d2
	ext	d2
	add	d2,volume(a2)

.ddw	tst	volume(a2)
	bpl.b	.ei0
	clr	volume(a2)
.ei0	cmp	#64,volume(a2)
	blo.b	.ei64
	move	#63,volume(a2)
.ei64	move	volume(a2),d0
	mulu	globalVol,d0
	lsr	#6,d0
	move	d0,mVolume(a4)
.f	rts

; NOTE: All subroutines expect the command parameter (the x of Fx, that is) in d0!
specials
	move.b	info(a2),d1
	moveq	#$f,d0
	and	d1,d0
	and	#$f0,d1
	cmp	#$b0,d1
	beq.b	.ploop
	cmp	#$d0,d1
	beq.b	.delay
	cmp	#$e0,d1
	beq.b	.pdelay
	cmp	#$c0,d1
	bne.b	.dd

	cmp	cn,d0
	bne.b	.dd
	clr	volume(a2)
	clr	mVolume(a4)
.dd	rts

.ploop	tst	cn
	bne.b	.dd

	tst	d0
	beq.b	.setlp			; 0 means "set loop mark" in current line

	tst	loopcnt(a2)		; dont allow nesting, accept value
	beq.b	.jcnt			; only if we counted down the last loop

	subq	#1,loopcnt(a2)		; count down
	bne.b	.jloop			; jump again if still not zero
	rts
.jcnt	move	d0,loopcnt(a2)		; accept new loop value
.jloop	move	looprow(a2),pbrkrow	; put line number to jump to
	st	pbrkflag
	rts
.setlp	move	rows,looprow(a2)
	rts

.pdelay	tst	cn
	bne.b	.dd

	tst	pdelaycnt
	bne.b	.skip

	move	d0,pdelaycnt
.skip	rts

.delay	cmp	cn,d0
	bne.b	.dd
	
	moveq	#32,d0
	and.b	flgs(a2),d0
	beq.w	.f

	move.b	inst(a2),d0
	beq.w	.esmp
	bmi.w	.esmp

	cmp	inss,d0
	bgt.b	.dd

	move.l	samples,a5
	add	d0,d0
	move	-2(a5,d0),d0
	iword	d0
	asl	#4,d0
	lea	(a0,d0),a1

	moveq	#0,d0
	move	insmemseg(a1),d0
	iword	d0
	asl.l	#4,d0
	move.l	a0,d4
	add.l	d0,d4

	move.l	insloopbeg(a1),d1
	ilword	d1
	move.l	insloopend(a1),d2
	ilword	d2
	sub.l	d1,d2
	add.l	d4,d1

	move.l	inslength(a1),d0
	ilword	d0

	move.l	d4,(a4)
	move.l	d0,mLength(a4)
	move.l	d1,mLStart(a4)
	move.l	d2,mLLength(a4)
	move.b	insvol(a1),volume+1(a2)
	cmp	#64,volume(a2)
	blo.b	.e
	move	#63,volume(a2)
.e	clr.b	mOnOff(a4)

	move.l	a1,sample(a2)

	btst	#0,insflags(a1)
	bne.b	.loo
	clr.b	mLoop(a4)
	bra.b	.esmp
.loo	cmp.l	#2,d2
	shi	mLoop(a4)

.esmp	moveq	#0,d0
	move.b	(a2),d0
	beq.b	.f
	bmi.b	.f

	moveq	#$70,d1
	and	d0,d1
	lsr	#4,d1

	and	#$f,d0
	add	d0,d0

	move.l	sample(a2),a1

	move.l	$20(a1),d2
	ilword	d2

	lea	Periods(pc),a1
	move	(a1,d0),d0
	mulu	#8363,d0
	lsl.l	#4,d0
	lsr.l	d1,d0
	divu	d2,d0

	move	d0,mPeriod(a4)
	move	d0,period(a2)
	clr.l	mFPos(a4)
	clr.b	vibpos(a2)

.f	moveq	#64,d0
	and.b	flgs(a2),d0
	beq.b	.evol
	move.b	vol(a2),volume+1(a2)
	cmp	#64,volume(a2)
	blo.b	.evol
	move	#63,volume(a2)
.evol	move	volume(a2),d0
	mulu	globalVol,d0
	lsr	#6,d0
	move	d0,mVolume(a4)
	rts


stempo	moveq	#0,d0
	move.b	info(a2),d0
	cmp	#32,d0
	bls.b	.e

	tst.b	ahi_use
	bne.w	ahi_tempo

	move.l	mrate,d1
	move.l	d1,d2
	lsl.l	#2,d1
	add.l	d2,d1
	add	d0,d0
	divu	d0,d1

	addq	#1,d1
	and	#~1,d1
	move	d1,bytesperframe
.e	rts

setmaster
	moveq	#0,d0
	move.b	info(a2),d0
	cmp	#64,d0
	bls.b	.d
	moveq	#64,d0
.d	move	d0,globalVol
	rts

Periods
 dc	1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960,907

ftab1	dc.b	0,-1,-2,-4,-8,-16,0,0
	dc.b	0,1,2,4,8,16,0,0

ftab2	dc.b	0,0,0,0,0,0,10,8
	dc.b	0,0,0,0,0,0,24,32

********** Fasttracker ][ XM player **************

	basereg	data,a5

xm_init	
	move.l	#AHIST_M8S,setsampletype

	move.l	s3m(a5),a0
	lea	xmName(a0),a1
	move.l	a1,mname(a5)

	lea	xmNum1A(a0),a2
	moveq	#18,d0
.t	cmp.b	#' ',-(a2)
	bne.b	.x
	dbf	d0,.t
.x	clr.b	1(a2)

	move	xmSpeed(a0),d0
	iword	d0
	tst	d0
	bne.b	.ok
	moveq	#6,d0
.ok	move	d0,spd(a5)

	move	xmTempo(a0),d0
	iword	d0
	cmp	#32,d0
	bhi.b	.qw
	moveq	#125,d0
.qw	move	d0,tempo(a5)

	move	xmFlags(a0),d0
	iword	d0
	move	d0,sflags(a5)

	tst	PS3M_reinit(a5)
	bne.w	xm_skipinit

	move	xmSongLength(a0),d0
	iword	d0
	move	d0,slen(a5)
	move	d0,positioneita(a5)

	moveq	#0,d0
	move.b	xmNumChans(a0),d0
	move	d0,numchans(a5)
	addq	#1,d0
	lsr	#1,d0
	move	d0,maxchan(a5)			;!!!

	move	xmNumInsts(a0),d0
	iword	d0
	move	d0,inss(a5)

	lea	xmHdrSize(a0),a1
	move.l	(a1),d0
	ilword	d0
	add.l	d0,a1
	lea	xm_patts,a2
	move	xmNumPatts(a0),d7
	iword	d7
	subq	#1,d7
.pattloop
	move.l	a1,(a2)+
	move.l	a1,a3				; xmPattHdrSize
	tlword	(a3)+,d0
	lea	xmPattDataSize(a1),a3
	add.l	d0,a1
	moveq	#0,d0
	tword	(a3)+,d0
	add.l	d0,a1
	dbf	d7,.pattloop

	lea	xm_insts,a2
	move	inss(a5),d7
	subq	#1,d7
.instloop
	moveq	#0,d5				; instlength
	move.l	a1,(a2)+
	move.l	a1,a3				; xmInstSize
	tlword	(a3)+,d0
	cmp.l	#1<<24,d0		* järjettömän iso?
	bhs.w	.q
	lea	xmNumSamples(a1),a3
	tword	(a3)+,d1
	lea	xmSmpHdrSize(a1),a3
	add.l	d0,a1
	tst	d1
	beq.b	.q
	tlword	(a3)+,d2			; xmSmpHdrSize
	move	d2,d6
	mulu	d1,d6
	lea	(a1,d6.l),a4			; sample start
	subq	#1,d1
.ll	move.l	a1,a3				; xmSmpLength
	tlword	(a3)+,d0
	tst.l	d0
	beq.b	.e
	add.l	d0,d5

	btst	#xm16bitf,xmSmpFlags(a1)
	beq.b	.bit8

;	move.l	#AHIST_M16S,setsampletype

; Dedelta the samples

.bit16	moveq	#0,d4
	move.l	a4,a6
.l3	move.b	(a4)+,d3
	move.b	(a4)+,d6
	lsl	#8,d6
	move.b	d3,d6
	add	d4,d6
	move	d6,d4
	lsr	#8,d6
	move.b	d6,(a6)+
	subq.l	#2,d0
	bne.b	.l3
	bra.b	.e

.bit8	
;	move.l	#AHIST_M8S,setsampletype

	moveq	#0,d4
.l2	add.b	(a4),d4
	move.b	d4,(a4)+
	subq.l	#1,d0
	bne.b	.l2

.e	add.l	d2,a1
	dbf	d1,.ll

	add.l	d5,a1

.q	dbf	d7,.instloop


xm_skipinit
	clr	pos(a5)
	clr	rows(a5)
	clr	cn(a5)
	clr	pdelaycnt(a5)
	clr	pjmpflag(a5)
	clr	pbrkflag(a5)
	clr	pbrkrow(a5)
	move	#64,globalVol(a5)

	lea	pantab(a5),a1
	move.l	a1,a2
	moveq	#7,d0
.l9	clr.l	(a2)+
	dbf	d0,.l9

	move	numchans(a5),d0
	subq	#1,d0
	moveq	#0,d1
.lop	tst	d1
	beq.b	.vas
	cmp	#3,d1
	beq.b	.vas
.oik	move.b	#-1,(a1)+
	bra.b	.je
.vas	move.b	#1,(a1)+
.je	addq	#1,d1
	and	#3,d1
	dbf	d0,.lop

	move.l	#8363*1712/4,clock(a5)		; Clock constant
	move	#1,fformat(a5)			; signed samples

	moveq	#0,d1
	move.b	xmOrders(a0),d1
	lsl.l	#2,d1
	lea	xm_patts,a1
	move.l	(a1,d1),a1

	lea	xmNumRows(a1),a3
	tword	(a3)+,d0
	move	d0,plen(a5)
	move.l	a1,a3
	tlword	(a3)+,d0
	add.l	d0,a1
	move.l	a1,ppos(a5)

	st	PS3M_reinit(a5)
	moveq	#0,d0
	rts


xm_music
	lea	data,a5
	move.l	s3m(a5),a0
	pea	xm_runEnvelopes(pc)

	addq	#1,cn(a5)
	move	cn(a5),d0
	cmp	spd(a5),d0
	beq.w	xm_newrow

xm_ccmds
	lea	c0(a5),a2
	lea	cha0(a5),a4
	move	numchans(a5),d7
	subq	#1,d7

.loo	moveq	#0,d0
	move.b	vol(a2),d0
	cmp.b	#$60,d0
	blo.b	.eivol

	lea	xm_cvct(pc),a1
	moveq	#$f,d1
	and	d0,d1
	move	d1,d2
	lsr	#4,d0
	subq	#6,d0
	add	d0,d0
	move	(a1,d0),d0
	jsr	(a1,d0)

.eivol	lea	xm_cct(pc),a1
	moveq	#0,d0
	move.b	cmd(a2),d0
	cmp.b	#$20,d0
	bhi.b	.edi
	moveq	#0,d1
	move.b	info(a2),d1
	beq.b	.zero
	move.b	d1,lastcmd(a2)
.zero	moveq	#0,d2
	move.b	lastcmd(a2),d2
	add	d0,d0
	move	(a1,d0),d0
	jsr	(a1,d0)

.edi	lea	s3mChanBlock_SIZE(a2),a2
	lea	mChanBlock_SIZE(a4),a4
	dbf	d7,.loo
	rts


xm_runEnvelopes
	lea	c0(a5),a2
	lea	cha0(a5),a4
	move	numchans(a5),d7
	subq	#1,d7
.envloop
	move.l	sample(a2),d1
	beq.w	.skip

	move.l	d1,a1	

	move	rVolume(a2),d0

			btst	#xmEnvOn,xmVolType(a1)
			beq	.0BAE
			moveq	#0,d1
			move.b	xmNumVolPnts(a1),d1
			lea	xmVolEnv(a1),a3
			subq	#1,d1
			blo.b	.0A8E

.0A78			
			tword	(a3)+,d2
			addq	#2,a3	
			cmp	volEnvX(a2),d2
			bhs.b	.0A8C
			dbf	d1,.0A78

.0A8C		subq	#4,a3
.0A8E		move.l	a3,a0

		tword	(a0)+,d2
		cmp	volEnvX(a2),d2
		bne.b	.0AAE
		lea	2(a3),a0
		tword	(a0)+,d3
		lsl	#8,d3
		bra.b	.0AEA

.0AAE
.points
	lea	-4(a3),a0
	tword	(a0)+,d2			; x
	tword	(a0)+,d3			; y
	tword	(a0)+,d4
	sub	d2,d4				; tx
	tword	(a0)+,d5
	sub	d3,d5				; ty
	lsl	#8,d3
	ext.l	d5
	lsl.l	#8,d5

	move	volEnvX(a2),d1
	sub	d2,d1
	muls	d4,d1
	beq.b	.vol
	divs	d1,d5
	add	d5,d3
.0AEA
.vol
	muls	d3,d0
	bpl.b	.vtst
	moveq	#0,d0
	bra.b	.sust
.vtst	lsl.l	#2,d0
	swap	d0
	moveq	#64,d1
	cmp	d0,d1
	bcc.b	.sust
	move	d1,d0
.sust
	tst.b	keyoff(a2)
	bne.b	.0B12

	moveq	#0,d1
	move.b	xmVolSustain(a1),d1
	btst	#xmEnvSustain,xmVolType(a1)
	bne.b	.0B28
.0B12

	moveq	#0,d1
	move.b	xmVolLoopEnd(a1),d1
	btst	#xmEnvLoop,xmVolType(a1)
	bne.b	.0B28

;	moveq	#0,d1
	move.b	xmNumVolPnts(a1),d1
	subq.b	#1,d1
.0B28
	tst.b	d1
	bmi.b	.0B46
	lsl	#2,d1
	lea	xmVolEnv(a1),a3
	add	d1,a3
	tword	(a3)+,d1
	cmp	volEnvX(a2),d1
	bls.b	.ninc
	addq	#1,volEnvX(a2)
.0B46
.ninc
	btst	#xmEnvLoop,xmVolType(a1)
	beq.b	.nloo

	moveq	#0,d1
	move.b	xmVolLoopEnd(a1),d1
	bmi.s	.nloo
	lsl	#2,d1
	lea	xmVolEnv(a1),a3
	add	d1,a3
	tword	(a3)+,d1
	cmp	volEnvX(a2),d1
	bhi.b	.nloo
	moveq	#0,d1
	move.b	xmVolLoopStart(a1),d1
	bmi.s	.nloo
	lsl	#2,d1
	lea	xmVolEnv(a1),a3
	add	d1,a3
	tword	(a3)+,d1
	move	d1,volEnvX(a2)
.nloo

	tst.b	keyoff(a2)
	beq.b	.0BAE

	mulu	fadeOut(a2),d0
	swap	d0
	lea	xmVolFadeout(a1),a3
	tword	(a3)+,d1
	move	fadeOut(a2),d2
	sub	d1,d2
	bhs.b	.0BAA
	moveq	#0,d2
.0BAA
	move	d2,fadeOut(a2)
.0BAE

.nsus
	move	globalVol(a5),d1
	cmp	#64,d1
	beq.b	.skipgvol
	mulu	d1,d0
	lsr	#6,d0
.skipgvol
	move	d0,mVolume(a4)

.skip	btst	#0,sflags+1(a5)
	beq.b	.amigaperiods

	moveq	#0,d0
	move	rPeriod(a2),d0
	divu	#768,d0
	move	d0,d1
	swap	d0
	lsl	#2,d0
	lea	xm_linFreq(pc),a0
	move.l	(a0,d0),d0
	lsr.l	d1,d0
	move.l	d0,d1
	move.l	#8363*1712,d0
	bsr.w	divu_32

	move	d0,mPeriod(a4)
	bra.b	.k

.amigaperiods
	move	rPeriod(a2),mPeriod(a4)

.k	lea	s3mChanBlock_SIZE(a2),a2
	lea	mChanBlock_SIZE(a4),a4
	dbf	d7,.envloop
	rts




*****************************************888888


xm_newrow
	clr	cn(a5)

	tst	pdelaycnt(a5)
	bne.w	.process

	move	pos(a5),d0
	moveq	#0,d1
	move.b	xmOrders(a0,d0),d1	
	lsl	#2,d1
	lea	xm_patts,a1
	move.l	(a1,d1),a1
	addq.l	#xmPattDataSize,a1
	tst.b	(a1)+
	bne.b	.pattok
	tst.b	(a1)+
	bne.b	.pattok

	lea	c0(a5),a2		;chanblocks
	move	numchans(a5),d7
	subq	#1,d7
.luu	clr.l	(a2)
	clr.b	info(a2)
	lea	s3mChanBlock_SIZE(a2),a2
	dbf	d7,.luu
	bra.b	.process

.pattok	move.l	ppos(a5),a1
	lea	c0(a5),a2		;chanblocks
	move	numchans(a5),d7
	subq	#1,d7
.loo	move.b	(a1)+,d0
	bpl.b	.all

	clr.l	(a2)
	clr.b	info(a2)

	btst	#0,d0
	beq.b	.nonote
	move.b	(a1)+,(a2)
.nonote	btst	#1,d0
	beq.b	.noinst
	move.b	(a1)+,inst(a2)
.noinst	btst	#2,d0
	beq.b	.novol
	move.b	(a1)+,vol(a2)
.novol	btst	#3,d0
	beq.b	.nocmd
	move.b	(a1)+,cmd(a2)
.nocmd	btst	#4,d0
	beq.b	.next
	move.b	(a1)+,info(a2)
	bra.b	.next
	
.all	move.b	d0,(a2)
	move.b	(a1)+,inst(a2)
	move.b	(a1)+,vol(a2)
	move.b	(a1)+,cmd(a2)
	move.b	(a1)+,info(a2)

.next	lea	s3mChanBlock_SIZE(a2),a2
	dbf	d7,.loo
	move.l	a1,ppos(a5)

.process
	lea	c0(a5),a2
	lea	cha0(a5),a4
	move	numchans(a5),d7
	subq	#1,d7
.channelloop
	tst	pdelaycnt(a5)
	bne.w	.skip

	tst	(a2)
	beq.w	.skip

	moveq	#0,d0
	move.b	(a2),d0
	bne.b	.note
	move.b	note(a2),d0
.note	move.b	d0,note(a2)

	moveq	#0,d1
	move.b	inst(a2),d1
	beq.b	.esmp

	cmp	inss,d1
	bgt.b	.esmp

	lsl	#2,d1
	lea	xm_insts,a1
	move.l	-4(a1,d1),a1

	move.l	a1,sample(a2)
	bra.b	.ju
.esmp	move.l	sample(a2),d2
	beq.w	.skip
	move.l	d2,a1

.ju	moveq	#$f,d1
	and.b	cmd(a2),d1
	cmp	#$e,d1
	bne.b	.s
	move.b	info(a2),d1
	and	#$f0,d1
	cmp	#$d0,d1
	beq.w	.skip

.s	bsr.w	xm_getInst
	beq.w	.skip

	tst.b	inst(a2)
	beq.w	.smpok

; Handle envelopes
	move	#$ffff,fadeOut(a2)
;	clr.b	fading(a2)
	clr.b	keyoff(a2)

	move.l	sample(a2),d2
	beq.w	.skip
	move.l	d2,a3

	btst	#xmEnvOn,xmVolType(a3)
	beq.b	.voloff

	clr	volEnvX(a2)
	st	volEnvOn(a2)
;	clr.b	volSustained(a2)
	bra.b	.jep

.voloff	clr.b	volEnvOn(a2)

.jep	btst	#xmEnvOn,xmPanType(a3)
	beq.b	.panoff

	st	panEnvOn(a2)
	clr.b	panSustained(a2)
	bra.b	.jep2

.panoff	clr.b	panEnvOn(a2)

.jep2	move.b	xmVolume(a1),volume+1(a2)
	cmp	#64,volume(a2)
	bls.b	.e
	move	#64,volume(a2)
.e	move	volume(a2),rVolume(a2)

	tst.b	(a2)
	beq.b	.smpok

	lea	xmLoopStart(a1),a3
	tlword	(a3)+,d1
	lea	xmLoopLength(a1),a3
	tlword	(a3)+,d2

	btst	#xm16bitf,xmSmpFlags(a1)
	beq.b	.bit8
	lsr.l	#1,d1
	lsr.l	#1,d2
.bit8	add.l	a6,d1

	move.l	d1,mLStart(a4)
	move.l	d2,mLLength(a4)
	cmp.l	#2,d2
	bhi.b	.ok

	clr.b	mLoop(a4)
	st.b	mOnOff(a4)
	bra.b	.smpok

.ok	moveq	#xmLoopType,d1
	and.b	xmSmpFlags(a1),d1
	sne	mLoop(a4)

.smpok	tst.b	(a2)
	beq.w	.skip

	cmp.b	#97,(a2)			; Key off -note
	beq.w	.keyoff

	bsr.w	xm_getPeriod

	cmp.b	#3,cmd(a2)
	beq.w	.tonep
	cmp.b	#5,cmd(a2)
	beq.w	.tonep

	move	d0,rPeriod(a2)
	move	d0,period(a2)
	clr.l	mFPos(a4)

	move.l	a1,a3
	tst.b	mLoop(a4)
	beq.b	.nloop

	addq.l	#4,a3
	tlword	(a3)+,d0
	tlword	(a3)+,d1
	add.l	d1,d0
	cmp.l	#2,d0
	bgt.b	.look
	subq.l	#8,a3

.nloop	tlword	(a3)+,d0			; sample length

.look	moveq	#0,d1
	cmp.b	#9,cmd(a2)
	bne.b	.nooffset

	move.b	info(a2),d1
	bne.b	.ok3
	move.b	lastOffset(a2),d1
.ok3	move.b	d1,lastOffset(a2)
	lsl	#8,d1
	add.l	d1,a6
	sub.l	d1,d0
	bpl.b	.nooffset
	st	mOnOff(a4)
	bra.b	.skip

.nooffset
	btst	#xm16bitf,xmSmpFlags(a1)
	beq.b	.bit8_2
	lsr.l	#1,d0
	lsr.l	#1,d1
	sub.l	d1,a6
.bit8_2	move.l	a6,(a4)				; sample start
	move.l	d0,mLength(a4)
	clr.b	mOnOff(a4)
	bra.b	.skip

.keyoff	tst.b	volEnvOn(a2)
	beq.b	.vol0

;	clr.b	volSustained(a2)
;	st	fading(a2)
	st	keyoff(a2)
	bra.b	.skip

.vol0	tst.b	inst(a2)
	bne.b	.skip
	clr	volume(a2)
	bra.b	.skip

.tonep	move	d0,toperiod(a2)

.skip	moveq	#0,d0
	move.b	vol(a2),d0
	cmp.b	#$10,d0
	blo.b	.eivol

	cmp.b	#$50,d0
	bhi.b	.volcmd

	sub	#$10,d0
	move	d0,volume(a2)
	bra.b	.eivol

.volcmd	cmp.b	#$60,d0
	blo.b	.eivol

	lea	xm_vct(pc),a1
	moveq	#$f,d1
	and	d0,d1
	move	d1,d2
	lsr	#4,d0
	subq	#6,d0
	add	d0,d0
	move	(a1,d0),d0
	jsr	(a1,d0)

.eivol	lea	xm_ct(pc),a1
	moveq	#0,d0
	move.b	cmd(a2),d0
	cmp.b	#$20,d0
	bhs.b	.skipa
	moveq	#0,d1
	move.b	info(a2),d1
	beq.b	.zero
	move.b	d1,lastcmd(a2)

.zero	moveq	#0,d2
	move.b	lastcmd(a2),d2

	ifne	debug
	move.l	kalas(a5),a3
	st	(a3,d0)
	endc

	add	d0,d0
	move	(a1,d0),d0
	jsr	(a1,d0)

.skipa	move	volume(a2),rVolume(a2)
	move	period(a2),rPeriod(a2)

	lea	s3mChanBlock_SIZE(a2),a2
	lea	mChanBlock_SIZE(a4),a4
	dbf	d7,.channelloop

	tst	pdelaycnt(a5)
	beq.b	.oke

	subq	#1,pdelaycnt(a5)
	bra.w	xm_exit

.oke	addq	#1,rows(a5)		; incr. linecounter

	tst	pbrkflag(a5)		; do we have to break this pattern?
	beq.b	.nobrk
	move	pbrkrow(a5),rows(a5)
	clr	pbrkrow(a5)		; clr break position
.nobrk
	move	rows(a5),d0
	cmp	plen(a5),d0
	bcc.b	.newpos				; worst case opt: branch not taken

	tst	pjmpflag(a5)		; do we have to jump?
	bne.b	.newpos

	tst.w	pbrkflag(a5)
	beq.w	xm_dee
	moveq	#0,d2
	bra.b	conti
.newpos
	move	pbrkrow(a5),rows(a5)
	clr	pbrkrow(a5)		; clr break position
burki
	moveq	#0,d2
burkii
	addq.w	#1,pos(a5)			; inc songposition
	move.w	slen(a5),d0
	cmp.w	pos(a5),d0			; are we thru with all patterns?
	bhi.b	conti				; nope

	move.w	xmRestart(a0),d0
	iword	d0
	tst.l	d2
	beq.b	.okay
	moveq	#0,d0
.okay	move.w	d0,pos(a5)
	st	PS3M_break(a5)

	moveq	#1,d2

conti	move	pos(a5),d0
	move	d0,PS3M_position(a5)
	st	PS3M_poscha(a5)

	moveq	#0,d1
	move.b	xmOrders(a0,d0),d1	
	cmp.b	xmNumPatts(a0),d1
	bhs.b	burkii
	lsl	#2,d1
	lea	xm_patts,a1
	move.l	(a1,d1),a1
	lea	xmNumRows(a1),a3
	tword	(a3)+,d0
	move	d0,plen(a5)
	move.l	a1,a3
	tlword	(a3)+,d0
	add.l	d0,a1

	clr	pjmpflag(a5)
	clr	pbrkflag(a5)

	move.w	rows(a5),d1
	beq.b	.setp
	subq.w	#1,d1
.loop	move.w	numchans(a5),d7
	subq.w	#1,d7
.llop	move.b	(a1)+,d0
	bpl.b	.tout
	btst	#0,d0
	beq.b	.nono
	addq.w	#1,a1
.nono	btst	#1,d0
	beq.b	.noin
	addq.w	#1,a1
.noin	btst	#2,d0
	beq.b	.novo
	addq.w	#1,a1
.novo	btst	#3,d0
	beq.b	.nocm
	addq.w	#1,a1
.nocm	btst	#4,d0
	beq.b	.cont
	addq.w	#1,a1
	bra.b	.cont
.tout	addq.w	#4,a1
.cont	dbf	d7,.llop
	dbf	d1,.loop
.setp	move.l	a1,ppos(a5)

xm_dee	lea	c0(a5),a2
	lea	cha0(a5),a4
	move	numchans(a5),d7
	subq	#1,d7

.luu	tst	volume(a2)
	bne.b	.noaging

	cmp.b	#8,age(a2)
	bhs.b	.stop
	addq.b	#1,age(a2)
	bra.b	.nextt
.stop	st	mOnOff(a4)
	bra.b	.nextt
.noaging
	clr.b	age(a2)

.nextt	lea	s3mChanBlock_SIZE(a2),a2
	lea	mChanBlock_SIZE(a4),a4
	dbf	d7,.luu
xm_exit	rts

xm_ret	rts


; COMMANDS!


; Returns zero-flag set, if no samples in this instrument
; Needs pattern note number in d0 and instrument in a1

xm_getInst
	moveq	#0,d6
	move.b	xmSmpNoteNums-1(a1,d0),d6	; sample number
	lea	xmNumSamples(a1),a3
	tword	(a3)+,d2
	tst	d2
	beq.b	.nosample
	lea	xmSmpHdrSize(a1),a3
	tlword	(a3)+,d3
	move.l	a1,a3				; InstHdrSize
	tlword	(a3)+,d1
	add.l	d1,a1				; Now at the first sample!

	move.l	d3,d4
	mulu	d2,d4
	lea	(a1,d4),a6

	tst	d6
	beq.b	.rightsample

.skiploop
	lea	xmSmpLength(a1),a3
	tlword	(a3)+,d4
	add.l	d4,a6
	add.l	d3,a1
	subq	#1,d6
	bne.b	.skiploop

.rightsample
	moveq	#1,d6
	rts

.nosample
	st	mOnOff(a4)
	moveq	#0,d6
	rts


; Needs instrument in a1

xm_getPeriod
	move.b	xmRelNote(a1),d1
	ext	d1
	add	d1,d0
	bpl.b	.ok
	moveq	#0,d0
.ok	cmp	#118,d0
	bls.b	.ok2
	moveq	#118,d0
.ok2	move.b	xmFinetune(a1),d1
	ext.l	d0
	ext	d1

	btst	#0,sflags+1(a5)
	beq.b	.amigafreq

	move	#121*64,d2
	lsl	#6,d0
	sub	d0,d2
	asr	d1
	sub	d1,d2
	move	d2,d0
	rts

.amigafreq
	divu	#12,d0
	swap	d0
	move	d0,d2				; note
	clr	d0
	swap	d0				; octave
	lsl	#3,d2

	move	d1,d3
	asr	#4,d3
	move	d2,d4
	add	d3,d4

	add	d4,d4
	lea	xm_periods(pc),a3
	moveq	#0,d5
	move	(a3,d4),d5

	tst	d1
	bpl.b	.k
	subq	#1,d3
	neg	d1
	bra.b	.k2
.k	addq	#1,d3
.k2	move	d2,d4
	add	d3,d4
	add	d4,d4
	moveq	#0,d6
	move	(a3,d4),d6

	and	#$f,d1
	mulu	d1,d6
	move	#16,d3
	sub	d1,d3
	mulu	d3,d5
	add.l	d6,d5

	subq	#1,d0
	bmi.b	.f2
	lsr.l	d0,d5
	bra.b	.d

.f2	add.l	d5,d5
.d	move	d5,d0
	rts


; Command 0 - Arpeggio

xm_arpeggio
	tst.b	info(a2)
	beq.b	.skip

	moveq	#0,d0
	move.b	note(a2),d0
	beq.b	.skip

	move.l	sample(a2),d2
	beq.b	.skip
	move.l	d2,a1

	bsr.w	xm_getInst
	beq.b	.skip

	moveq	#0,d2
	move	cn(a5),d2
	divu	#3,d2
	swap	d2
	tst	d2
	beq.b	.f
	subq	#1,d2
	beq.b	.1

.2	moveq	#$f,d2
	and.b	lastcmd(a2),d2
	add	d2,d0
	bra.b	.f

.1	move.b	lastcmd(a2),d2
	lsr.b	#4,d2
	add.b	d2,d0

.f	bsr.w	xm_getPeriod
	move	d0,mPeriod(a4)
.skip	rts



; Command 1 - Portamento up
; Also command E1 - fine portamento up
; and command X1 - extra fine portamento up

xm_slideup
	lsl	#2,d2
xm_xslideup
	sub	d2,period(a2)
	bra.b	xm_checklimits


; Command 2 - Portamento down
; Also command E2 - fine portamento down
; and command X2 - extra fine portamento down

xm_slidedwn
	lsl	#2,d2
xm_xslidedwn
	add	d2,period(a2)

xm_checklimits
	move	period(a2),d0
	btst	#0,sflags+1(a5)
	beq.b	.amiga

	cmp	#2*64,d0
	bhs.b	.ok
	move	#2*64,d0
.ok	cmp	#121*64,d0
	bls.b	.dd2
	move	#121*64,d0
	bra.b	.dd2

.amiga	cmp	#$7fff,d0
	bls.b	.dd
	move	#$7fff,d0
.dd	cmp	#64,d0
	bhs.b	.dd2
	move	#64,d0
.dd2	move	d0,period(a2)
	move	d0,rPeriod(a2)
	rts


; Command 3 - Tone portamento

xm_tonep
	tst	d1
	beq.b	xm_tonepnoch
	move.b	d1,notepspd(a2)
xm_tonepnoch
	move	toperiod(a2),d0
	beq.b	.1
	moveq	#0,d1
	move.b	notepspd(a2),d1
	lsl	#2,d1

	cmp	period(a2),d0
	blt.b	.topoup

	add	d1,period(a2)
	cmp	period(a2),d0
	bhi.b	.1
	move	d0,period(a2)
	clr	toperiod(a2)
.1	move	period(a2),rPeriod(a2)
	rts

.topoup	sub	d1,period(a2)
	cmp	period(a2),d0
	blt.b	.dd
	move	d0,period(a2)
	clr	toperiod(a2)
.dd	move	period(a2),rPeriod(a2)
	rts


; Command 4 - Vibrato

xm_svibspd
	move.b	vibcmd(a2),d2
	moveq	#$f,d0
	and	d1,d0
	beq.b	.skip
	and	#$f0,d2
	or	d0,d2
.skip	move.b	d2,vibcmd(a2)
	rts

xm_vibrato
	move.b	vibcmd(a2),d2
	move	d1,d0
	and	#$f0,d0
	beq.b	.vib2

	and	#$f,d2
	or	d0,d2

.vib2	moveq	#$f,d0
	and	d1,d0
	beq.b	.vibskip2

	and	#$f0,d2
	or	d0,d2
.vibskip2
	move.b	d2,vibcmd(a2)

xm_vibrato2
	moveq	#$1f,d0
	and.b	vibpos(a2),d0
	moveq	#0,d2
	lea	mt_vibratotable(pc),a3
	move.b	(a3,d0),d2
	moveq	#$f,d0
	and.b	vibcmd(a2),d0
	mulu	d0,d2
	lsr	#5,d2

	move	period(a2),d0
	btst	#5,vibpos(a2)
	bne.b	.neg
	add	d2,d0
	bra.b	.vib3
.neg
	sub	d2,d0
.vib3
	move	d0,mPeriod(a4)
	move.b	vibcmd(a2),d0
	lsr.b	#4,d0
	add.b	d0,vibpos(a2)
	rts

; Command 5 - Tone portamento and volume slide

xm_tpvsl
	bsr.w	xm_tonepnoch
	bra.b	xm_vslide

; Command 6 - Vibrato and volume slide

xm_vibvsl
	move	d2,-(sp)
	bsr.b	xm_vibrato2
	move	(sp)+,d2
	bra.b	xm_vslide


; Command 7 - Tremolo

xm_tremolo
	move.b	vibcmd(a2),d2
	move	d1,d0
	and	#$f0,d0
	beq.b	.vib2

	and	#$f,d2
	or	d0,d2

.vib2	moveq	#$f,d0
	and	d1,d0
	beq.b	.vibskip2

	and	#$f0,d2
	or	d0,d2
.vibskip2
	move.b	d2,vibcmd(a2)

	moveq	#$1f,d0
	and.b	vibpos(a2),d0
	moveq	#0,d2
	lea	mt_vibratotable(pc),a3
	move.b	(a3,d0),d2
	moveq	#$f,d0
	and.b	vibcmd(a2),d0
	mulu	d0,d2
	lsr	#6,d2

	move	volume(a2),d0
	btst	#5,vibpos(a2)
	bne.b	.neg
	add	d2,d0
	bra.b	.vib3
.neg
	sub	d2,d0
.vib3	move	d0,mVolume(a4)
	move.b	vibcmd(a2),d0
	lsr.b	#4,d0
	add.b	d0,vibpos(a2)
	rts


; Command A - Volume slide
; Also commands EA and EB, fine volume slides

xm_vslide
	lsr	#4,d2
	beq.b	xm_vslidedown
xm_vslideup
	add	d2,volume(a2)
	cmp	#64,volume(a2)
	bls.b	xm_vsskip
	move	#64,volume(a2)
xm_vsskip
	move	volume(a2),rVolume(a2)
	rts

xm_vslidedown
	moveq	#$f,d2
	and.b	lastcmd(a2),d2
xm_vslidedown2
	sub	d2,volume(a2)
	bpl.b	xm_vsskip
	clr	volume(a2)
	clr	rVolume(a2)
	rts


; Command B - Pattern jump

xm_pjmp	cmp.b	pos(a5),d1
	bhi.b	.e
	st	PS3M_break
.e	subq	#1,d1
	move	d1,pos(a5)
	clr	pbrkrow(a5)
	st	pjmpflag(a5)
	st	PS3M_poscha(a5)
	rts


; Command C - Set volume

xm_setvol
	cmp	#64,d1
	bls.b	.ok
	moveq	#64,d1
.ok	move	d1,volume(a2)
	rts


; Command D - Pattern break

xm_pbrk	st	pjmpflag(a5)
	moveq	#$f,d2
	and.l	d1,d2
	lsr.l	#4,d1
	mulu	#10,d1
	add	d2,d1
	move	d1,pbrkrow(a5)
	st	PS3M_poscha(a5)
	rts


; Command E - Extended commands

xm_ecmds
	lea	xm_ect(pc),a1
xm_ee	move	d1,d0
	moveq	#$f,d1
	and	d0,d1
	move	d1,d2
	lsr	#4,d0

	ifne	debug
	move.l	kalas(a5),a3
	st	$40(a3,d0)
	endc

	add	d0,d0
	move	(a1,d0),d0
	jmp	(a1,d0)

xm_cecmds
	lea	xm_cect(pc),a1
	bra.b	xm_ee


; Command E6 - Pattern loop

xm_pattloop
	tst	d1
	beq.b	.setlp				; 0 means "set loop mark" in current line
	tst.w	loopcnt(a2)			; dont allow nesting, accept value
	beq.b	.jcnt				; only if we counted down the last loop
	subq.w	#1,loopcnt(a2)			; count down
	bne.b	.jloop				; jump again if still not zero
	rts
.jcnt	move.w	d1,loopcnt(a2)			; accept new loop value
.jloop	move.w	looprow(a2),pbrkrow(a5)	; put line number to jump to
	st	pbrkflag(a5)
	rts
.setlp	move.w	rows(a5),looprow(a2)
	rts


; Command E9 - Retrig note

xm_retrig
	subq.b	#1,retrigcn(a2)
	bne.w	xm_eret

	move.l	sample(a2),d2
	beq.w	xm_eret
	move.l	d2,a1

	move	d1,-(sp)

	moveq	#0,d0
	move.b	note(a2),d0
	beq.w	xm_sretrig

	bsr.w	xm_getInst
	beq.w	.skip

	clr.l	mFPos(a4)
; Handle envelopes
	move	#$ffff,fadeOut(a2)
;	clr.b	fading(a2)
	clr.b	keyoff(a2)

	move.l	sample(a2),a3
	btst	#xmEnvOn,xmVolType(a3)
	beq.b	.voloff

	clr	volEnvX(a2)
	st	volEnvOn(a2)
;	clr.b	volSustained(a2)
	bra.b	.jep

.voloff	clr.b	volEnvOn(a2)


.jep	btst	#xmEnvOn,xmPanType(a3)
	beq.b	.panoff

	st	panEnvOn(a2)
	clr.b	panSustained(a2)
	bra.b	.jep2

.panoff	clr.b	panEnvOn(a2)

.jep2	move.l	a1,a3
	tst.b	mLoop(a4)
	beq.b	.nloop

	addq.l	#4,a3
	tlword	(a3)+,d0
	tlword	(a3)+,d1
	add.l	d1,d0
	cmp.l	#2,d0
	bgt.b	.look
	subq.l	#8,a3

.nloop	tlword	(a3)+,d0			; sample length

.look	move.l	a6,(a4)				; sample start
	btst	#xm16bitf,xmSmpFlags(a1)
	beq.b	.bit8_2
	lsr.l	#1,d0
.bit8_2	move.l	d0,mLength(a4)
	clr.b	mOnOff(a4)
.skip	move	(sp)+,d1
xm_sretrig
	move.b	d1,retrigcn(a2)
	rts


; Command EC - Note cut

xm_ncut	cmp	cn(a5),d1
	bne.b	xm_eret
	clr	volume(a2)
	clr	rVolume(a2)
xm_eret	rts


; Command ED - Delay note

xm_ndelay
	cmp	cn(a5),d1
	bne.b	xm_eret

	tst	(a2)
	beq.w	.skip

	moveq	#0,d0
	move.b	(a2),d0
	beq.w	.skip

	cmp.b	#97,d0				; Key off -note
	beq.w	.keyoff

	move.b	d0,note(a2)

	moveq	#0,d1
	move.b	inst(a2),d1
	beq.b	.esmp

	cmp	inss,d1
	bgt.b	.esmp

	lsl	#2,d1
	lea	xm_insts,a1
	move.l	-4(a1,d1),a1

	move.l	a1,sample(a2)
	bra.b	.ju
.esmp	move.l	sample(a2),d2
	beq.w	.skip
	move.l	d2,a1

.ju	bsr.w	xm_getInst
	beq.w	.skip

	tst.b	inst(a2)
	beq.b	.smpok

	lea	xmLoopStart(a1),a3
	tlword	(a3)+,d1
	lea	xmLoopLength(a1),a3
	tlword	(a3)+,d2

	btst	#xm16bitf,xmSmpFlags(a1)
	beq.b	.bit8
	lsr.l	#1,d1
	lsr.l	#1,d2
.bit8	add.l	a6,d1

	move.l	d1,mLStart(a4)
	move.l	d2,mLLength(a4)
	cmp.l	#2,d2
	bhi.b	.ok

	clr.b	mLoop(a4)
	st.b	mOnOff(a4)
	bra.b	.huu

.ok	moveq	#xmLoopType,d1
	and.b	xmSmpFlags(a1),d1
	sne	mLoop(a4)

.huu	move.b	xmVolume(a1),volume+1(a2)
	cmp	#64,volume(a2)
	bls.b	.e
	move	#64,volume(a2)
.e	move	volume(a2),rVolume(a2)

.smpok	bsr.w	xm_getPeriod

	move	d0,rPeriod(a2)
	move	d0,period(a2)
	clr.l	mFPos(a4)

; Handle envelopes
	move	#$ffff,fadeOut(a2)
;;;;	clr.b	fading(a2)
	clr.b	keyoff(a2)

	move.l	sample(a2),a3

	btst	#xmEnvOn,xmVolType(a3)
	beq.b	.voloff

	clr	volEnvX(a2)
	st	volEnvOn(a2)
;	clr.b	volSustained(a2)
	bra.b	.jep

.voloff	clr.b	volEnvOn(a2)


.jep	btst	#xmEnvOn,xmPanType(a3)
	beq.b	.panoff

	st	panEnvOn(a2)
	clr.b	panSustained(a2)
	bra.b	.jep2

.panoff	clr.b	panEnvOn(a2)

.jep2	move.l	a1,a3
	tst.b	mLoop(a4)
	beq.b	.nloop

	addq.l	#4,a3
	tlword	(a3)+,d0
	tlword	(a3)+,d1
	add.l	d1,d0
	cmp.l	#2,d0
	bgt.b	.look
	subq.l	#8,a3

.nloop	tlword	(a3)+,d0			; sample length

.look	move.l	a6,(a4)				; sample start
	btst	#xm16bitf,xmSmpFlags(a1)
	beq.b	.bit8_2
	lsr.l	#1,d0
.bit8_2	move.l	d0,mLength(a4)
	clr.b	mOnOff(a4)
	bra.b	.skip

.keyoff	tst.b	volEnvOn(a2)
	beq.b	.vol0

	clr.b	volSustained(a2)
	st	fading(a2)
	st	keyoff(a2)
	bra.b	.skip

.vol0	tst.b	inst(a2)
	bne.b	.skip
	clr	volume(a2)
.skip
.ret	rts


; Command EE - Pattern delay

xm_pdelay
	tst	pdelaycnt(a5)
	bne.b	.skip

	move	d1,pdelaycnt(a5)

.skip	rts


; Command F - Set speed

xm_spd	cmp	#$20,d1
	bhs.b	.bpm

	tst	d1
	bne.b	.g
	st	PS3M_break(a5)
	st	PS3M_poscha(a5)
	rts

.g	move	d1,spd(a5)
	rts

.bpm	move	d1,tempo(a5)

	move	d1,d0
	tst.b	ahi_use
	bne.w	ahi_tempo

	move.l	mrate(a5),d0
	move.l	d0,d2
	lsl.l	#2,d0
	add.l	d2,d0
	add	d1,d1
	divu	d1,d0

	addq	#1,d0
	and	#~1,d0
	move	d0,bytesperframe(a5)
	rts


; Command G - Set global volume

xm_sgvol
	cmp	#64,d1
	bls.b	.ok
	moveq	#64,d1
.ok	move	d1,globalVol(a5)
	rts


; Command H - Global volume slide

xm_gvslide
	lsr	#4,d2
	beq.b	.down
	add	d2,globalVol(a5)
	cmp	#64,globalVol(a5)
	bls.b	.x
	move	#64,globalVol(a5)
.x	rts

.down	moveq	#$f,d2
	and.b	lastcmd(a2),d2
	sub	d2,globalVol(a5)
	bpl.b	.x
	clr	globalVol(a5)
	rts


; Command K - Key off

xm_keyoff
;	clr.b	volSustained(a2)
;	st	fading(a2)
	st	keyoff(a2)
	rts


; Command L - Set envelope position

xm_setenvpos
	tst.b	volEnvOn(a2)
	beq.b	.skip

	move.l	sample(a2),d2
	beq.b	.skip
	move.l	d2,a3

	btst	#xmEnvOn,xmVolType(a1)
	beq.b	.skip

	move	d1,volEnvX(a2)
	st	volEnvOn(a2)
;;	clr.b	volSustained(a2)
.skip	rts



; Command R - Multi retrig note

xm_rretrig
	subq.b	#1,retrigcn(a2)
	bne.w	xm_eret

	move.l	sample(a2),d2
	beq.w	xm_eret
	move.l	d2,a1

	move	d1,-(sp)

	moveq	#0,d0
	move.b	note(a2),d0
	beq.w	xm_srretrig

	bsr.w	xm_getInst
	beq.b	.skip

	clr.l	mFPos(a4)
; Handle envelopes
	move	#$ffff,fadeOut(a2)
;	clr.b	fading(a2)
	clr.b	keyoff(a2)

	move.l	sample(a2),a3
	btst	#xmEnvOn,xmVolType(a3)
	beq.b	.voloff

	clr	volEnvX(a2)
	st	volEnvOn(a2)
;	clr.b	volSustained(a2)
	bra.b	.jep

.voloff	clr.b	volEnvOn(a2)


.jep	btst	#xmEnvOn,xmPanType(a3)
	beq.b	.panoff

	st	panEnvOn(a2)
	clr.b	panSustained(a2)
	bra.b	.jep2

.panoff	clr.b	panEnvOn(a2)

.jep2	move.l	a1,a3
	tlword	(a3)+,d0			; sample length

	move.l	a6,(a4)				; sample start
	btst	#xm16bitf,xmSmpFlags(a1)
	beq.b	.bit8_2
	lsr.l	#1,d0
.bit8_2	move.l	d0,mLength(a4)
	clr.b	mOnOff(a4)

.skip	moveq	#0,d0
	move.b	lastcmd(a2),d0
	lsr	#4,d0
	lea	ftab2(pc),a3
	moveq	#0,d2
	move.b	(a3,d0),d2
	beq.b	.ddq

	mulu	volume(a2),d2
	lsr	#4,d2
	move	d2,volume(a2)
	bra.b	.ddw

.ddq	lea	ftab1(pc),a3
	move.b	(a3,d0),d2
	ext	d2
	add	d2,volume(a2)

.ddw	tst	volume(a2)
	bpl.b	.ei0
	clr	volume(a2)
.ei0	cmp	#64,volume(a2)
	bls.b	.ei64
	move	#64,volume(a2)
.ei64	move	volume(a2),mVolume(a4)
	move	(sp)+,d1
xm_srretrig
	and	#$f,d1
	move.b	d1,retrigcn(a2)
	rts


; Command T - Tremor

xm_tremor
	rts


; Command X - Extra fine slides

xm_xfinesld
	move.b	d2,d1
	and	#$f,d2
	cmp.b	#$10,d1
	blo.b	.q
	cmp.b	#$20,d1
	blo.w	xm_xslideup
	cmp.b	#$30,d1
	blo.w	xm_xslidedwn
.q	rts

	dc	960,954,948,940,934,926,920,914
xm_periods
	dc	907,900,894,887,881,875,868,862,856,850,844,838,832,826,820,814
	dc	808,802,796,791,785,779,774,768,762,757,752,746,741,736,730,725
	dc	720,715,709,704,699,694,689,684,678,675,670,665,660,655,651,646
	dc	640,636,632,628,623,619,614,610,604,601,597,592,588,584,580,575
	dc	570,567,563,559,555,551,547,543,538,535,532,528,524,520,516,513
	dc	508,505,502,498,494,491,487,484,480,477,474,470,467,463,460,457

xm_linFreq
	dc.l	535232,534749,534266,533784,533303,532822,532341,531861
	dc.l	531381,530902,530423,529944,529466,528988,528511,528034
	dc.l	527558,527082,526607,526131,525657,525183,524709,524236
	dc.l	523763,523290,522818,522346,521875,521404,520934,520464
	dc.l	519994,519525,519057,518588,518121,517653,517186,516720
	dc.l	516253,515788,515322,514858,514393,513929,513465,513002
	dc.l	512539,512077,511615,511154,510692,510232,509771,509312
	dc.l	508852,508393,507934,507476,507018,506561,506104,505647
	dc.l	505191,504735,504280,503825,503371,502917,502463,502010
	dc.l	501557,501104,500652,500201,499749,499298,498848,498398
	dc.l	497948,497499,497050,496602,496154,495706,495259,494812
	dc.l	494366,493920,493474,493029,492585,492140,491696,491253
	dc.l	490809,490367,489924,489482,489041,488600,488159,487718
	dc.l	487278,486839,486400,485961,485522,485084,484647,484210
	dc.l	483773,483336,482900,482465,482029,481595,481160,480726
	dc.l	480292,479859,479426,478994,478562,478130,477699,477268
	dc.l	476837,476407,475977,475548,475119,474690,474262,473834
	dc.l	473407,472979,472553,472126,471701,471275,470850,470425
	dc.l	470001,469577,469153,468730,468307,467884,467462,467041
	dc.l	466619,466198,465778,465358,464938,464518,464099,463681
	dc.l	463262,462844,462427,462010,461593,461177,460760,460345
	dc.l	459930,459515,459100,458686,458272,457859,457446,457033
	dc.l	456621,456209,455797,455386,454975,454565,454155,453745
	dc.l	453336,452927,452518,452110,451702,451294,450887,450481
	dc.l	450074,449668,449262,448857,448452,448048,447644,447240
	dc.l	446836,446433,446030,445628,445226,444824,444423,444022
	dc.l	443622,443221,442821,442422,442023,441624,441226,440828
	dc.l	440430,440033,439636,439239,438843,438447,438051,437656
	dc.l	437261,436867,436473,436079,435686,435293,434900,434508
	dc.l	434116,433724,433333,432942,432551,432161,431771,431382
	dc.l	430992,430604,430215,429827,429439,429052,428665,428278
	dc.l	427892,427506,427120,426735,426350,425965,425581,425197
	dc.l	424813,424430,424047,423665,423283,422901,422519,422138
	dc.l	421757,421377,420997,420617,420237,419858,419479,419101
	dc.l	418723,418345,417968,417591,417214,416838,416462,416086
	dc.l	415711,415336,414961,414586,414212,413839,413465,413092
	dc.l	412720,412347,411975,411604,411232,410862,410491,410121
	dc.l	409751,409381,409012,408643,408274,407906,407538,407170
	dc.l	406803,406436,406069,405703,405337,404971,404606,404241
	dc.l	403876,403512,403148,402784,402421,402058,401695,401333
	dc.l	400970,400609,400247,399886,399525,399165,398805,398445
	dc.l	398086,397727,397368,397009,396651,396293,395936,395579
	dc.l	395222,394865,394509,394153,393798,393442,393087,392733
	dc.l	392378,392024,391671,391317,390964,390612,390259,389907
	dc.l	389556,389204,388853,388502,388152,387802,387452,387102
	dc.l	386753,386404,386056,385707,385359,385012,384664,384317
	dc.l	383971,383624,383278,382932,382587,382242,381897,381552
	dc.l	381208,380864,380521,380177,379834,379492,379149,378807
	dc.l	378466,378124,377783,377442,377102,376762,376422,376082
	dc.l	375743,375404,375065,374727,374389,374051,373714,373377
	dc.l	373040,372703,372367,372031,371695,371360,371025,370690
	dc.l	370356,370022,369688,369355,369021,368688,368356,368023
	dc.l	367691,367360,367028,366697,366366,366036,365706,365376
	dc.l	365046,364717,364388,364059,363731,363403,363075,362747
	dc.l	362420,362093,361766,361440,361114,360788,360463,360137
	dc.l	359813,359488,359164,358840,358516,358193,357869,357547
	dc.l	357224,356902,356580,356258,355937,355616,355295,354974
	dc.l	354654,354334,354014,353695,353376,353057,352739,352420
	dc.l	352103,351785,351468,351150,350834,350517,350201,349885
	dc.l	349569,349254,348939,348624,348310,347995,347682,347368
	dc.l	347055,346741,346429,346116,345804,345492,345180,344869
	dc.l	344558,344247,343936,343626,343316,343006,342697,342388
	dc.l	342079,341770,341462,341154,340846,340539,340231,339924
	dc.l	339618,339311,339005,338700,338394,338089,337784,337479
	dc.l	337175,336870,336566,336263,335959,335656,335354,335051
	dc.l	334749,334447,334145,333844,333542,333242,332941,332641
	dc.l	332341,332041,331741,331442,331143,330844,330546,330247
	dc.l	329950,329652,329355,329057,328761,328464,328168,327872
	dc.l	327576,327280,326985,326690,326395,326101,325807,325513
	dc.l	325219,324926,324633,324340,324047,323755,323463,323171
	dc.l	322879,322588,322297,322006,321716,321426,321136,320846
	dc.l	320557,320267,319978,319690,319401,319113,318825,318538
	dc.l	318250,317963,317676,317390,317103,316817,316532,316246
	dc.l	315961,315676,315391,315106,314822,314538,314254,313971
	dc.l	313688,313405,313122,312839,312557,312275,311994,311712
	dc.l	311431,311150,310869,310589,310309,310029,309749,309470
	dc.l	309190,308911,308633,308354,308076,307798,307521,307243
	dc.l	306966,306689,306412,306136,305860,305584,305308,305033
	dc.l	304758,304483,304208,303934,303659,303385,303112,302838
	dc.l	302565,302292,302019,301747,301475,301203,300931,300660
	dc.l	300388,300117,299847,299576,299306,299036,298766,298497
	dc.l	298227,297958,297689,297421,297153,296884,296617,296349
	dc.l	296082,295815,295548,295281,295015,294749,294483,294217
	dc.l	293952,293686,293421,293157,292892,292628,292364,292100
	dc.l	291837,291574,291311,291048,290785,290523,290261,289999
	dc.l	289737,289476,289215,288954,288693,288433,288173,287913
	dc.l	287653,287393,287134,286875,286616,286358,286099,285841
	dc.l	285583,285326,285068,284811,284554,284298,284041,283785
	dc.l	283529,283273,283017,282762,282507,282252,281998,281743
	dc.l	281489,281235,280981,280728,280475,280222,279969,279716
	dc.l	279464,279212,278960,278708,278457,278206,277955,277704
	dc.l	277453,277203,276953,276703,276453,276204,275955,275706
	dc.l	275457,275209,274960,274712,274465,274217,273970,273722
	dc.l	273476,273229,272982,272736,272490,272244,271999,271753
	dc.l	271508,271263,271018,270774,270530,270286,270042,269798
	dc.l	269555,269312,269069,268826,268583,268341,268099,267857

xm_ct	dc	xm_arpeggio-xm_ct	;0
	dc	xm_ret-xm_ct		;1
	dc	xm_ret-xm_ct		;2
	dc	xm_ret-xm_ct		;3
	dc	xm_ret-xm_ct		;4
 	dc	xm_ret-xm_ct		;5
	dc	xm_ret-xm_ct		;6
	dc	xm_ret-xm_ct		;7
	dc	xm_ret-xm_ct		;8
	dc	xm_ret-xm_ct		;9
	dc	xm_ret-xm_ct		;A
 	dc	xm_pjmp-xm_ct		;B
 	dc	xm_setvol-xm_ct		;C
 	dc	xm_pbrk-xm_ct		;D
 	dc	xm_ecmds-xm_ct		;E
 	dc	xm_spd-xm_ct		;F
	dc	xm_sgvol-xm_ct		;G
 	dc	xm_ret-xm_ct		;H
 	dc	xm_ret-xm_ct		;I
 	dc	xm_ret-xm_ct		;J
 	dc	xm_keyoff-xm_ct		;K
 	dc	xm_setenvpos-xm_ct	;L
 	dc	xm_ret-xm_ct		;M
 	dc	xm_ret-xm_ct		;N
 	dc	xm_ret-xm_ct		;O
 	dc	xm_ret-xm_ct		;P
 	dc	xm_ret-xm_ct		;Q
 	dc	xm_srretrig-xm_ct	;R
 	dc	xm_ret-xm_ct		;S
 	dc	xm_tremor-xm_ct		;T
 	dc	xm_ret-xm_ct		;U
 	dc	xm_ret-xm_ct		;V
 	dc	xm_ret-xm_ct		;W
 	dc	xm_xfinesld-xm_ct	;X
 	dc	xm_ret-xm_ct		;Y
 	dc	xm_ret-xm_ct		;Z

xm_cct	dc	xm_arpeggio-xm_cct	;0
	dc	xm_slideup-xm_cct	;1
	dc	xm_slidedwn-xm_cct	;2
	dc	xm_tonep-xm_cct		;3
	dc	xm_vibrato-xm_cct	;4
	dc	xm_tpvsl-xm_cct		;5
	dc	xm_vibvsl-xm_cct	;6
	dc	xm_tremolo-xm_cct	;7
	dc	xm_ret-xm_cct		;8
	dc	xm_ret-xm_cct		;9
	dc	xm_vslide-xm_cct	;A
 	dc	xm_ret-xm_cct		;B
 	dc	xm_ret-xm_cct		;C
 	dc	xm_ret-xm_cct		;D
 	dc	xm_cecmds-xm_cct	;E
 	dc	xm_ret-xm_cct		;F
 	dc	xm_ret-xm_cct		;G
	dc	xm_gvslide-xm_cct	;H
 	dc	xm_ret-xm_cct		;I
 	dc	xm_ret-xm_cct		;J
 	dc	xm_ret-xm_cct		;K
 	dc	xm_ret-xm_cct		;L
 	dc	xm_ret-xm_cct		;M
 	dc	xm_ret-xm_cct		;N
 	dc	xm_ret-xm_cct		;O
 	dc	xm_ret-xm_cct		;P
 	dc	xm_ret-xm_cct		;Q
 	dc	xm_rretrig-xm_cct	;R
 	dc	xm_ret-xm_cct		;S
 	dc	xm_tremor-xm_cct	;T
 	dc	xm_ret-xm_cct		;U
 	dc	xm_ret-xm_cct		;V
 	dc	xm_ret-xm_cct		;W
 	dc	xm_ret-xm_cct		;X
 	dc	xm_ret-xm_cct		;Y
 	dc	xm_ret-xm_cct		;Z

xm_ect	dc	xm_ret-xm_ect		;0
	dc	xm_slideup-xm_ect	;1
	dc	xm_slidedwn-xm_ect	;2
	dc	xm_ret-xm_ect		;3
	dc	xm_ret-xm_ect		;4
	dc	xm_ret-xm_ect		;5
	dc	xm_pattloop-xm_ect	;6
	dc	xm_ret-xm_ect		;7
	dc	xm_ret-xm_ect		;8
	dc	xm_sretrig-xm_ect	;9
	dc	xm_vslideup-xm_ect	;A
 	dc	xm_vslidedown2-xm_ect	;B
 	dc	xm_ncut-xm_ect		;C
 	dc	xm_ret-xm_ect		;D
 	dc	xm_pdelay-xm_ect	;E
 	dc	xm_ret-xm_ect		;F

xm_cect	dc	xm_ret-xm_cect		;0
	dc	xm_ret-xm_cect		;1
	dc	xm_ret-xm_cect		;2
	dc	xm_ret-xm_cect		;3
	dc	xm_ret-xm_cect		;4
	dc	xm_ret-xm_cect		;5
	dc	xm_ret-xm_cect		;6
	dc	xm_ret-xm_cect		;7
	dc	xm_ret-xm_cect		;8
	dc	xm_retrig-xm_cect	;9
	dc	xm_ret-xm_cect		;A
 	dc	xm_ret-xm_cect		;B
 	dc	xm_ncut-xm_cect		;C
 	dc	xm_ndelay-xm_cect	;D
 	dc	xm_ret-xm_cect		;E
 	dc	xm_ret-xm_cect		;F

xm_vct	dc	xm_ret-xm_vct		;6
	dc	xm_ret-xm_vct		;7
	dc	xm_vslidedown2-xm_vct	;8
	dc	xm_vslideup-xm_vct	;9
	dc	xm_svibspd-xm_vct	;A
 	dc	xm_ret-xm_vct		;B
 	dc	xm_ret-xm_vct		;C
 	dc	xm_ret-xm_vct		;D
 	dc	xm_ret-xm_vct		;E
 	dc	xm_ret-xm_vct		;F

xm_cvct	dc	xm_vslidedown2-xm_cvct	;6
	dc	xm_vslideup-xm_cvct	;7
	dc	xm_ret-xm_cvct		;8
	dc	xm_ret-xm_cvct		;9
	dc	xm_ret-xm_cvct		;A
 	dc	xm_vibrato-xm_cvct	;B
 	dc	xm_ret-xm_cvct		;C
 	dc	xm_ret-xm_cvct		;D
 	dc	xm_ret-xm_cvct		;E
 	dc	xm_tonep-xm_cvct	;F


   *************************
   *   Standard effects:   *
   *************************

;!      0      Arpeggio
;!      1  (*) Porta up
;!      2  (*) Porta down
;!      3  (*) Tone porta
;-      4  (*) Vibrato
;!      5  (*) Tone porta+Volume slide
;-      6  (*) Vibrato+Volume slide
;-      7  (*) Tremolo
;*      8      Set panning
;!      9      Sample offset
;!      A  (*) Volume slide
;!      B      Position jump
;!      C      Set volume
;!      D      Pattern break
;!      E1 (*) Fine porta up
;!      E2 (*) Fine porta down
;-      E3     Set gliss control
;-      E4     Set vibrato control
;-      E5     Set finetune
;-      E6     Set loop begin/loop
;-      E7     Set tremolo control
;!      E9     Retrig note
;!      EA (*) Fine volume slide up
;!      EB (*) Fine volume slide down
;!      EC     Note cut
;!      ED     Note delay
;-      EE     Pattern delay
;!      F      Set tempo/BPM
;!      G      Set global volume
;!      H  (*) Global volume slide
;!     	K      Key off
;!      L      Set envelope position
;*      P  (*) Panning slide
;!      R  (*) Multi retrig note
;-      T      Tremor
;-      X1 (*) Extra fine porta up
;-      X2 (*) Extra fine porta down
;
;      (*) = If the command byte is zero, the last nonzero byte for the
;            command should be used.
;
;   *********************************
;   *   Effects in volume column:   *
;   *********************************
;
;   All effects in the volume column should work as the standard effects.
;   The volume column is interpreted before the standard effects, so
;   some standard effects may override volume column effects.
;
;   Value      Meaning
;
;      0       Do nothing
;    $10-$50   Set volume Value-$10
;      :          :        :
;      :          :        :
;!    $60-$6f   Volume slide down
;!    $70-$7f   Volume slide up
;!    $80-$8f   Fine volume slide down
;!    $90-$9f   Fine volume slide up
;-    $a0-$af   Set vibrato speed
;-    $b0-$bf   Vibrato
;*    $c0-$cf   Set panning
;*    $d0-$df   Panning slide left
;*    $e0-$ef   Panning slide right
;!    $f0-$ff   Tone porta

********** Protracker (Fasttracker player) **************

n_note		equ	0
n_cmd		equ	2
n_cmdlo		equ	3
n_start		equ	4
n_length	equ	8
n_loopstart	equ	10
n_replen	equ	14
n_period	equ	16
n_finetune	equ	18
n_volume	equ	19
n_dmabit	equ	20
n_toneportdirec	equ	22
n_toneportspeed	equ	23
n_wantedperiod	equ	24
n_vibratocmd	equ	26
n_vibratopos	equ	27
n_tremolocmd	equ	28
n_tremolopos	equ	29
n_wavecontrol	equ	30
n_glissfunk	equ	31
n_sampleoffset	equ	32
n_pattpos	equ	33
n_loopcount	equ	34
n_funkoffset	equ	35
n_wavestart	equ	36
n_reallength	equ	40

mtm_init
;	move.l	#AHIST_M8U,setsampletype
	move.l	#AHIST_M8S,setsampletype


	move.l	s3m(a5),a0
	move.l	a0,mt_songdataptr
	lea	4(a0),a1
	move.l	a1,mname(a5)

	move.l	#mtm_periodtable,peris
	move	#1616,lowlim
	move	#45,upplim
	move	#126,octs

	moveq	#0,d0
	move.b	27(a0),d0
	addq.b	#1,d0
	move.b	d0,slene
	move	d0,positioneita(a5)

	moveq	#0,d1
	move.b	33(a0),d1
	move	d1,numchans(a5)

	moveq	#0,d0
	move.b	32(a0),d0
	lsl	#2,d0
	mulu	d1,d0
	move	d0,patlen

	move.l	a0,d0
	add.l	#66,d0

	moveq	#0,d1
	move.b	30(a0),d1			; NOS
	mulu	#37,d1
	add.l	d1,d0

	move.l	d0,orderz
	add.l	#128,d0
	move.l	d0,tracks

	move	24(a0),d1			; number of tracks
	iword	d1
	mulu	#192,d1
	add.l	d1,d0

	move.l	d0,sequ

	moveq	#0,d1
	move.b	26(a0),d1			; last pattern saved
	addq	#1,d1
	lsl	#6,d1
	add.l	d1,d0

	moveq	#0,d1
	move	28(a0),d1			; length of comment field
	iword	d1
	add.l	d1,d0

	lea	66(a0),a2			; sample infos

	moveq	#0,d7
	move.b	30(a0),d7			; NOS
	subq	#1,d7

	lea	mt_sampleinfos(pc),a1
.loop	move.l	d0,(a1)+
	lea	22(a2),a3
	tlword	(a3)+,d1

	tst.l	d1
	beq.b	.eik

	tst.b	31(a0)
	bne.b	.eik
** signediks!
	move.l	d0,a4
	move	d1,d3
	subq	#1,d3
	moveq	#-128,d4
.doh	eor.b	d4,(a4)+
	dbf	d3,.doh
.eik

	add.l	d1,d0
	lsr.l	#1,d1
	move	d1,(a1)+

	lea	26(a2),a3
	tlword	(a3)+,d1
	lsr.l	#1,d1
	move	d1,(a1)+			; rep offset

	lea	30(a2),a3
	tlword	(a3)+,d2
	lsr.l	#1,d2
	sub.l	d1,d2	
	move	d2,(a1)+			; rep length

	clr.b	(a1)+				; no finetune
	move.b	35(a2),(a1)+			; volume

	lea	37(a2),a2
	dbf	d7,.loop

	st	31(a0)		* asetetaan byte merkiks samplekäännöksestä!


	or.b	#2,$bfe001
	move.b	#6,mt_speed
	clr.b	mt_counter
	clr.b	mt_songpos
	clr	mt_patternpos

;	move	#2,fformat			; unsigned data
	move	#1,fformat			; signed data
	move	#125,tempo
	move.l	#14317056/4,clock		; Clock constant

	lea	34(a0),a2
	lea	pantab(a5),a0
	move.l	a0,a1
	moveq	#7,d0
.ll	clr.l	(a1)+
	dbf	d0,.ll

	move	numchans(a5),d0
	subq	#1,d0
	moveq	#0,d5
	moveq	#0,d6
.lop	move.b	(a2)+,d1
	cmp.b	#8,d1
	blo.b	.vas
	move.b	#-1,(a0)+
	addq	#1,d5
	bra.b	.je
.vas	move.b	#1,(a0)+
	addq	#1,d6
.je	dbf	d0,.lop

	cmp	d5,d6
	bls.b	.k
	move	d6,d5
.k	move	d5,maxchan(a5)

	lea	mt_chan1temp(pc),a0
	move	#44*8-1,d0
.cl	clr.l	(a0)+
	dbf	d0,.cl

	moveq	#0,d0
	rts

orderz	dc.l	0
tracks	dc.l	0
sequ	dc.l	0
slene	dc	0
patlen	dc	0
upplim	dc	0
lowlim	dc	0
peris	dc.l	0
octs	dc	0

mt_init	lea	data,a5
	move.l	s3m(a5),a0
	move.l	a0,mname
	move.l	a0,mt_songdataptr
	move.l	a0,a1
	moveq	#0,d0
	move.b	950(a1),d0
	move.b	d0,slene
	move	d0,positioneita

	move	#256,d0
	mulu	numchans(a5),d0
	move	d0,patlen

	move	#113,upplim
	move	#856,lowlim
	move.l	#mt_periodtable,peris
	move	#36*2,octs

	lea	952(a1),a1
	moveq	#127,d0
	moveq	#0,d1
mtloop	move.l	d1,d2
	subq	#1,d0
mtloop2	move.b	(a1)+,d1
	cmp.b	d2,d1
	bgt.b	mtloop
	dbra	d0,mtloop2
	addq.b	#1,d2
			
	lea	mt_sampleinfos(pc),a1
	asl	#8,d2
	mulu	numchans(a5),d2

	add.l	#1084,d2
	add.l	a0,d2
	move.l	d2,a2
	moveq	#30,d0
mtloop3	move.l	a2,(a1)+
	moveq	#0,d1
	move	42(a0),d1
	move	d1,(a1)+
	asl.l	#1,d1
	add.l	d1,a2

	move	46(a0),(a1)+
	move	48(a0),(a1)+
	move	44(a0),(a1)+			; finetune and volume

	add.l	#30,a0
	dbra	d0,mtloop3

	or.b	#2,$bfe001
	move.b	#6,mt_speed
	clr.b	mt_counter
	clr.b	mt_songpos
	clr	mt_patternpos

	move	#1,fformat
	move	#125,tempo
	move.l	#14187580/4,clock		; Clock constant

	lea	pantab(a5),a0
	move.l	a0,a1
	moveq	#7,d0
.ll	clr.l	(a1)+
	dbf	d0,.ll

	move	numchans(a5),d0
	subq	#1,d0
	moveq	#0,d1
.lop	tst	d1
	beq.b	.vas
	cmp	#3,d1
	beq.b	.vas
.oik	move.b	#-1,(a0)+
	bra.b	.je
.vas	move.b	#1,(a0)+
.je	addq	#1,d1
	and	#3,d1
	dbf	d0,.lop

	lea	mt_chan1temp(pc),a0
	move	#44*8-1,d0
.cl	clr.l	(a0)+
	dbf	d0,.cl

	moveq	#0,d0
	rts

	endb	a5
mt_music
	movem.l	d0-d4/a0-a6,-(sp)
	addq.b	#1,mt_counter
	move.b	mt_counter(pc),d0
	cmp.b	mt_speed(pc),d0
	blo.b	mt_nonewnote
	clr.b	mt_counter
	tst.b	mt_pattdeltime2
	beq.b	mt_getnewnote
	bsr.b	mt_nonewallchannels
	bra.w	mt_dskip

mt_nonewnote
	bsr.b	mt_nonewallchannels
	bra.w	mt_nonewposyet

mt_nonewallchannels
	move	numchans,d7
	subq	#1,d7
	lea	cha0,a5
	lea	mt_chan1temp(pc),a6
.loo	move	d7,-(sp)
	bsr.w	mt_checkefx
	move	(sp)+,d7
	lea	mChanBlock_SIZE(a5),a5
	lea	44(a6),a6			; Size of MT_chanxtemp
	dbf	d7,.loo
	rts

mt_getnewnote
	move.l	mt_songdataptr(pc),a0
	lea	12(a0),a3
	lea	952(a0),a2	;pattpo
	lea	1084(a0),a0	;patterndata
	moveq	#0,d0
	moveq	#0,d1
	move.b	mt_songpos(pc),d0
	move.b	(a2,d0),d1
	asl.l	#8,d1
	mulu	numchans(pc),d1

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; MOD
;	cmp	#mtMOD,mtype
;	bne.b	.skip
;	pushm 	d0/a0/a5
;	lea	(a0,d1.l),a5
;
;	move	numchans(pc),d0
;	subq	#1,d0
;	lea	Stripe1(pc),a0
;.stripes
;	move.l	a5,(a0)+
;	addq	#4,a5
;	dbf	d0,.stripes
;
;	moveq	#0,d0
;	move	mt_patternpos(pc),d0
;	divu	numchans(pc),d0
;	lsr	#2,d0
;	move	d0,PatternInfo+PI_Pattpos	
;	popm	d0/a0/a5
;.skip
	pushm	d0/d1
	moveq	#0,d0 
	move.b 	mt_songpos(pc),d0
	moveq	#0,d1
	move	mt_patternpos(pc),d1
	divu	numchans(pc),d1
	lsr	#2,d1
	bsr	pushPatternInfo
	popm	d0/d1
;	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	add	mt_patternpos(pc),d1
	clr	mt_dmacontemp

	cmp	#mtMTM,mtype
	bne.b	.ei
	moveq	#0,d1
.ei
	move	numchans(pc),d7
	subq	#1,d7
	lea	cha0,a5
	lea	mt_chan1temp(pc),a6

	lea	Stripe1(pc),a4
.loo
	move	d7,-(sp)
	tst.l	(a6)
	bne.b	.mt_plvskip
	bsr.w	mt_pernop
.mt_plvskip
	bsr.b	getnew

	push	a4
	bsr.w	mt_playvoice
	pop 	a4
	move	(sp)+,d7
	lea	mChanBlock_SIZE(a5),a5
	lea	44(a6),a6			; Size of MT_chanxtemp
	dbf	d7,.loo

	bra.w	mt_setdma

getnew	cmp	#mtMOD,mtype
	bne.b	.mtm

* MOD get note data
	move.l	(a0,d1.l),(a6)
	addq.l	#4,d1
	rts

* MTM get note data
.mtm	

	move.l	mt_songdataptr(pc),a0
	move.l	orderz(pc),a2
	moveq	#0,d0
	move.b	mt_songpos(pc),d0
	move.b	(a2,d0),d0

	lsl	#6,d0				; 32 channels * word
	move.l	sequ(pc),a2
	add	d1,d0
	move.b	(a2,d0),d2
	lsl	#8,d2
	move.b	1(a2,d0),d2
	move	d2,d0
	beq.b	.zero
	iword	d0
	move.l	tracks(pc),a2
	subq	#1,d0
	mulu	#192,d0

	* mt_patternpos back to multiples of 1
	moveq	#0,d2
	move	mt_patternpos(pc),d2
	divu	numchans(pc),d2
	lsr	#2,d2

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	move	d2,PatternInfo+PI_Pattpos
	lea	(a2,d0.l),a1 
	move.l	a1,(a4)+
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	* MTM note takes 3 bytes
	mulu	#3,d2
	add.l	d2,d0

	moveq	#0,d2
	move.b	(a2,d0.l),d2
	lsr	#2,d2
	beq.b	.huu
	move.l	peris(pc),a1
	subq	#1,d2
	add	d2,d2
	move	(a1,d2),d2

.huu	clr.l	(a6)
	or	d2,(a6)

	moveq	#0,d2
	move.b	(a2,d0.l),d2
	lsl	#8,d2
	move.b	1(a2,d0.l),d2
	and	#$3f0,d2
	lsr	#4,d2
	move.b	d2,d3
	and	#$10,d3
	or.b	d3,(a6)
	lsl.b	#4,d2
	or.b	d2,2(a6)

	moveq	#0,d2
	move.b	1(a2,d0.l),d2
	lsl	#8,d2
	move.b	2(a2,d0.l),d2
	and	#$fff,d2
	or	d2,2(a6)

	addq.l	#2,d1
	rts

.zero	clr.l	(a6)
	addq.l	#2,d1
	rts

mt_playvoice
	moveq	#0,d2
	move.b	n_cmd(a6),d2
	and.b	#$f0,d2
	lsr.b	#4,d2
	move.b	(a6),d0
	and.b	#$f0,d0
	or.b	d0,d2
	tst.b	d2
	beq.w	mt_setregs
	moveq	#0,d3
	lea	mt_sampleinfos(pc),a1
	move	d2,d4
	subq	#1,d4
	mulu	#12,d4
	move.l	(a1,d4.l),n_start(a6)
	move	4(a1,d4.l),n_length(a6)
	move	4(a1,d4.l),n_reallength(a6)
	move.b	10(a1,d4.l),n_finetune(a6)
	move.b	11(a1,d4.l),n_volume(a6)
	move	6(a1,d4.l),d3 ; get repeat
	tst	d3
	beq.b	mt_noloop
	tst	8(a1,d4.l)
	beq.b	mt_noloop
	move.l	n_start(a6),d2	; get start
	asl	#1,d3
	add.l	d3,d2		; add repeat
	move.l	d2,n_loopstart(a6)
	move.l	d2,n_wavestart(a6)
	move	6(a1,d4.l),d0	; get repeat
	add	8(a1,d4.l),d0	; add replen
	move	d0,n_length(a6)
	move	8(a1,d4.l),n_replen(a6)	; save replen
	moveq	#0,d0
	move.b	n_volume(a6),d0
	move	d0,mVolume(a5)	; set volume
	bra.b	mt_setregs

mt_noloop
	move.l	n_start(a6),d2
	move.l	d2,n_loopstart(a6)
	move.l	d2,n_wavestart(a6)
	move	8(a1,d4.l),n_replen(a6)	; save replen
	moveq	#0,d0
	move.b	n_volume(a6),d0
	move	d0,mVolume(a5)	; set volume
mt_setregs
	move	(a6),d0
	and	#$fff,d0
	beq.w	mt_checkmoreefx	; if no note
	move	2(a6),d0
	and	#$ff0,d0
	cmp	#$e50,d0
	beq.b	mt_dosetfinetune
	move.b	2(a6),d0
	and.b	#$f,d0
	cmp.b	#3,d0	; toneportamento
	beq.b	mt_chktoneporta
	cmp.b	#5,d0
	beq.b	mt_chktoneporta
	cmp.b	#9,d0	; sample offset
	bne.b	mt_setperiod
	bsr.w	mt_checkmoreefx
	bra.b	mt_setperiod

mt_dosetfinetune
	bsr.w	mt_setfinetune
	bra.b	mt_setperiod

mt_chktoneporta
	bsr.w	mt_settoneporta
	bra.w	mt_checkmoreefx

mt_setperiod
	movem.l	d0-d1/a0-a1,-(sp)
	move	(a6),d1
	and	#$fff,d1
	move.l	peris(pc),a1
	moveq	#0,d0
	move	octs(pc),d7
	lsr	#1,d7
mt_ftuloop
	cmp	(a1,d0),d1
	bhs.b	mt_ftufound
	addq.l	#2,d0
	dbra	d7,mt_ftuloop
mt_ftufound
	moveq	#0,d1
	move.b	n_finetune(a6),d1
	mulu	octs(pc),d1
	add.l	d1,a1
	move	(a1,d0),n_period(a6)
	movem.l	(sp)+,d0-d1/a0-a1

	move	2(a6),d0
	and	#$ff0,d0
	cmp	#$ed0,d0 ; notedelay
	beq.w	mt_checkmoreefx

	btst	#2,n_wavecontrol(a6)
	bne.b	mt_vibnoc
	clr.b	n_vibratopos(a6)
mt_vibnoc
	btst	#6,n_wavecontrol(a6)
	bne.b	mt_trenoc
	clr.b	n_tremolopos(a6)
mt_trenoc
	move.l	n_start(a6),(a5)	; set start
	moveq	#0,d0
	move	n_length(a6),d0
	add.l	d0,d0
	move.l	d0,mLength(a5)		; set length
	move	n_period(a6),d0
	lsl	#2,d0
	move	d0,mPeriod(a5)		; set period

	clr.b	mOnOff(a5)		; turn on
	clr.l	mFPos(a5)		; retrig
	bra.w	mt_checkmoreefx

 
mt_setdma
	move	numchans,d7
	subq	#1,d7
	lea	cha0,a5
	lea	mt_chan1temp(pc),a6
.loo	move	d7,-(sp)
	bsr.w	setreg
	move	(sp)+,d7
	lea	mChanBlock_SIZE(a5),a5
	lea	44(a6),a6			; Size of MT_chanxtemp
	dbf	d7,.loo

mt_dskip
	moveq	#4,d0
	mulu	numchans,d0
	add	d0,mt_patternpos
	move.b	mt_pattdeltime,d0
	beq.b	mt_dskc
	move.b	d0,mt_pattdeltime2
	clr.b	mt_pattdeltime
mt_dskc	tst.b	mt_pattdeltime2
	beq.b	mt_dska
	subq.b	#1,mt_pattdeltime2
	beq.b	mt_dska

	moveq	#4,d0
	mulu	numchans,d0
	sub	d0,mt_patternpos

mt_dska	tst.b	mt_pbreakflag
	beq.b	mt_nnpysk
	sf	mt_pbreakflag
	moveq	#0,d0
	move.b	mt_pbreakpos(pc),d0
	clr.b	mt_pbreakpos
	lsl	#2,d0
	mulu	numchans,d0	
	move	d0,mt_patternpos
mt_nnpysk
	move	patlen(pc),d0
	cmp	mt_patternpos(pc),d0
	bhi.b	mt_nonewposyet
mt_nextposition	
	moveq	#0,d0
	move.b	mt_pbreakpos(pc),d0
	lsl	#2,d0
	mulu	numchans,d0
	move	d0,mt_patternpos
	clr.b	mt_pbreakpos
	clr.b	mt_posjumpflag
	addq.b	#1,mt_songpos
	and.b	#$7f,mt_songpos

	moveq	#0,d1
	move.b	mt_songpos(pc),d1
	st	PS3M_poscha
	move	d1,PS3M_position

	cmp.b	slene(pc),d1
	blo.b	mt_nonewposyet
	clr.b	mt_songpos
	st	PS3M_break
mt_nonewposyet	
	tst.b	mt_posjumpflag
	bne.b	mt_nextposition
	movem.l	(sp)+,d0-d4/a0-a6
	rts


setreg	move.l	n_loopstart(a6),mLStart(a5)
	moveq	#0,d0
	move	n_replen(a6),d0
	add.l	d0,d0
	move.l	d0,mLLength(a5)
	cmp.l	#2,mLLength(a5)
	bls.b	.eloo
	st	mLoop(a5)
	tst.b	mOnOff(a5)
	beq.b	.ok
	clr.b	mOnOff(a5)
	clr.l	mFPos(a5)
.ok	rts
.eloo	clr.b	mLoop(a5)
	rts


mt_checkefx
	bsr.w	mt_updatefunk
	move	n_cmd(a6),d0
	and	#$fff,d0
	beq.b	mt_pernop
	move.b	n_cmd(a6),d0
	and.b	#$f,d0
	beq.b	mt_arpeggio
	cmp.b	#1,d0
	beq.w	mt_portaup
	cmp.b	#2,d0
	beq.w	mt_portadown
	cmp.b	#3,d0
	beq.w	mt_toneportamento
	cmp.b	#4,d0
	beq.w	mt_vibrato
	cmp.b	#5,d0
	beq.w	mt_toneplusvolslide
	cmp.b	#6,d0
	beq.w	mt_vibratoplusvolslide
	cmp.b	#$e,d0
	beq.w	mt_e_commands
setback	move	n_period(a6),d2
	lsl	#2,d2
	move	d2,mPeriod(a5)
	cmp.b	#7,d0
	beq.w	mt_tremolo
	cmp.b	#$a,d0
	beq.w	mt_volumeslide
mt_return2
	rts

mt_pernop
	move	n_period(a6),d2
	lsl	#2,d2
	move	d2,mPeriod(a5)
	rts

mt_arpeggio
	moveq	#0,d0
	move.b	mt_counter(pc),d0
	divs	#3,d0
	swap	d0
	cmp	#0,d0
	beq.b	mt_arpeggio2
	cmp	#2,d0
	beq.b	mt_arpeggio1
	moveq	#0,d0
	move.b	n_cmdlo(a6),d0
	lsr.b	#4,d0
	bra.b	mt_arpeggio3

mt_arpeggio1
	moveq	#0,d0
	move.b	n_cmdlo(a6),d0
	and.b	#15,d0
	bra.b	mt_arpeggio3

mt_arpeggio2
	move	n_period(a6),d2
	bra.b	mt_arpeggio4

mt_arpeggio3
	asl	#1,d0
	moveq	#0,d1
	move.b	n_finetune(a6),d1
	mulu	octs(pc),d1
	move.l	peris(pc),a0
	add.l	d1,a0
	moveq	#0,d1
	move	n_period(a6),d1
	move	octs(pc),d7
	lsr	#1,d7
	subq	#1,d7
mt_arploop
	move	(a0,d0),d2
	cmp	(a0),d1
	bhs.b	mt_arpeggio4
	addq.l	#2,a0
	dbra	d7,mt_arploop
	rts

mt_arpeggio4
	lsl	#2,d2
	move	d2,mPeriod(a5)
	rts

mt_fineportaup
	tst.b	mt_counter
	bne.w	mt_return2
	move.b	#$f,mt_lowmask
mt_portaup
	moveq	#0,d0
	move.b	n_cmdlo(a6),d0
	and.b	mt_lowmask(pc),d0
	move.b	#$ff,mt_lowmask
	sub	d0,n_period(a6)
	move	n_period(a6),d0
	and	#$fff,d0
	cmp	upplim(pc),d0
	bpl.b	mt_portauskip
	and	#$f000,n_period(a6)
	move	upplim(pc),d0
	or	d0,n_period(a6)
mt_portauskip
	move	n_period(a6),d0
	and	#$fff,d0
	lsl	#2,d0
	move	d0,mPeriod(a5)
	rts	
 
mt_fineportadown
	tst.b	mt_counter
	bne.w	mt_return2
	move.b	#$f,mt_lowmask
mt_portadown
	clr	d0
	move.b	n_cmdlo(a6),d0
	and.b	mt_lowmask(pc),d0
	move.b	#$ff,mt_lowmask
	add	d0,n_period(a6)
	move	n_period(a6),d0
	and	#$fff,d0
	cmp	lowlim(pc),d0
	bmi.b	mt_portadskip
	and	#$f000,n_period(a6)
	move	lowlim(pc),d0
	or	d0,n_period(a6)
mt_portadskip
	move	n_period(a6),d0
	and	#$fff,d0
	lsl	#2,d0
	move	d0,mPeriod(a5)
	rts

mt_settoneporta
	move.l	a0,-(sp)
	move	(a6),d2
	and	#$fff,d2
	moveq	#0,d0
	move.b	n_finetune(a6),d0
	mulu	octs(pc),d0
	move.l	peris(pc),a0
	add.l	d0,a0
	moveq	#0,d0
mt_stploop
	cmp	(a0,d0),d2
	bhs.b	mt_stpfound
	addq	#2,d0
	cmp	octs(pc),d0
	blo.b	mt_stploop
	move	octs(pc),d0
	subq	#2,d0
mt_stpfound
	move.b	n_finetune(a6),d2
	and.b	#8,d2
	beq.b	mt_stpgoss
	tst	d0
	beq.b	mt_stpgoss
	subq	#2,d0
mt_stpgoss
	move	(a0,d0),d2
	move.l	(sp)+,a0
	move	d2,n_wantedperiod(a6)
	move	n_period(a6),d0
	clr.b	n_toneportdirec(a6)
	cmp	d0,d2
	beq.b	mt_cleartoneporta
	bge.w	mt_return2
	move.b	#1,n_toneportdirec(a6)
	rts

mt_cleartoneporta
	clr	n_wantedperiod(a6)
	rts

mt_toneportamento
	move.b	n_cmdlo(a6),d0
	beq.b	mt_toneportnochange
	move.b	d0,n_toneportspeed(a6)
	clr.b	n_cmdlo(a6)
mt_toneportnochange
	tst	n_wantedperiod(a6)
	beq.w	mt_return2
	moveq	#0,d0
	move.b	n_toneportspeed(a6),d0
	tst.b	n_toneportdirec(a6)
	bne.b	mt_toneportaup
mt_toneportadown
	add	d0,n_period(a6)
	move	n_wantedperiod(a6),d0
	cmp	n_period(a6),d0
	bgt.b	mt_toneportasetper
	move	n_wantedperiod(a6),n_period(a6)
	clr	n_wantedperiod(a6)
	bra.b	mt_toneportasetper

mt_toneportaup
	sub	d0,n_period(a6)
	move	n_wantedperiod(a6),d0
	cmp	n_period(a6),d0
	blt.b	mt_toneportasetper
	move	n_wantedperiod(a6),n_period(a6)
	clr	n_wantedperiod(a6)

mt_toneportasetper
	move	n_period(a6),d2
	move.b	n_glissfunk(a6),d0
	and.b	#$f,d0
	beq.b	mt_glissskip
	moveq	#0,d0
	move.b	n_finetune(a6),d0
	mulu	octs(pc),d0
	move.l	peris(pc),a0
	add.l	d0,a0
	moveq	#0,d0
mt_glissloop
	cmp	(a0,d0),d2
	bhs.b	mt_glissfound
	addq	#2,d0
	cmp	octs(pc),d0
	blo.b	mt_glissloop
	move	octs(pc),d0
	subq	#2,d0
mt_glissfound
	move	(a0,d0),d2
mt_glissskip
	lsl	#2,d2
	move	d2,mPeriod(a5) ; set period
	rts

mt_vibrato
	move.b	n_cmdlo(a6),d0
	beq.b	mt_vibrato2
	move.b	n_vibratocmd(a6),d2
	and.b	#$f,d0
	beq.b	mt_vibskip
	and.b	#$f0,d2
	or.b	d0,d2
mt_vibskip
	move.b	n_cmdlo(a6),d0
	and.b	#$f0,d0
	beq.b	mt_vibskip2
	and.b	#$f,d2
	or.b	d0,d2
mt_vibskip2
	move.b	d2,n_vibratocmd(a6)
mt_vibrato2
	move.b	n_vibratopos(a6),d0
	lea	mt_vibratotable(pc),a4
	lsr	#2,d0
	and	#$1f,d0
	moveq	#0,d2
	move.b	n_wavecontrol(a6),d2
	and.b	#3,d2
	beq.b	mt_vib_sine
	lsl.b	#3,d0
	cmp.b	#1,d2
	beq.b	mt_vib_rampdown
	move.b	#255,d2
	bra.b	mt_vib_set
mt_vib_rampdown
	tst.b	n_vibratopos(a6)
	bpl.b	mt_vib_rampdown2
	move.b	#255,d2
	sub.b	d0,d2
	bra.b	mt_vib_set
mt_vib_rampdown2
	move.b	d0,d2
	bra.b	mt_vib_set
mt_vib_sine
	move.b	0(a4,d0),d2
mt_vib_set
	move.b	n_vibratocmd(a6),d0
	and	#15,d0
	mulu	d0,d2
	lsr	#7,d2
	move	n_period(a6),d0
	tst.b	n_vibratopos(a6)
	bmi.b	mt_vibratoneg
	add	d2,d0
	bra.b	mt_vibrato3
mt_vibratoneg
	sub	d2,d0
mt_vibrato3
	lsl	#2,d0
	move	d0,mPeriod(a5)
	move.b	n_vibratocmd(a6),d0
	lsr	#2,d0
	and	#$3c,d0
	add.b	d0,n_vibratopos(a6)
	rts

mt_toneplusvolslide
	bsr.w	mt_toneportnochange
	bra.w	mt_volumeslide

mt_vibratoplusvolslide
	bsr.b	mt_vibrato2
	bra.w	mt_volumeslide

mt_tremolo
	move.b	n_cmdlo(a6),d0
	beq.b	mt_tremolo2
	move.b	n_tremolocmd(a6),d2
	and.b	#$f,d0
	beq.b	mt_treskip
	and.b	#$f0,d2
	or.b	d0,d2
mt_treskip
	move.b	n_cmdlo(a6),d0
	and.b	#$f0,d0
	beq.b	mt_treskip2
	and.b	#$f,d2
	or.b	d0,d2
mt_treskip2
	move.b	d2,n_tremolocmd(a6)
mt_tremolo2
	move.b	n_tremolopos(a6),d0
	lea	mt_vibratotable(pc),a4
	lsr	#2,d0
	and	#$1f,d0
	moveq	#0,d2
	move.b	n_wavecontrol(a6),d2
	lsr.b	#4,d2
	and.b	#3,d2
	beq.b	mt_tre_sine
	lsl.b	#3,d0
	cmp.b	#1,d2
	beq.b	mt_tre_rampdown
	move.b	#255,d2
	bra.b	mt_tre_set
mt_tre_rampdown
	tst.b	n_vibratopos(a6)
	bpl.b	mt_tre_rampdown2
	move.b	#255,d2
	sub.b	d0,d2
	bra.b	mt_tre_set
mt_tre_rampdown2
	move.b	d0,d2
	bra.b	mt_tre_set
mt_tre_sine
	move.b	0(a4,d0),d2
mt_tre_set
	move.b	n_tremolocmd(a6),d0
	and	#15,d0
	mulu	d0,d2
	lsr	#6,d2
	moveq	#0,d0
	move.b	n_volume(a6),d0
	tst.b	n_tremolopos(a6)
	bmi.b	mt_tremoloneg
	add	d2,d0
	bra.b	mt_tremolo3
mt_tremoloneg
	sub	d2,d0
mt_tremolo3
	bpl.b	mt_tremoloskip
	clr	d0
mt_tremoloskip
	cmp	#$40,d0
	bls.b	mt_tremolook
	move	#$40,d0
mt_tremolook
	move	d0,mVolume(a5)
	move.b	n_tremolocmd(a6),d0
	lsr	#2,d0
	and	#$3c,d0
	add.b	d0,n_tremolopos(a6)
	rts

mt_sampleoffset
	moveq	#0,d0
	move.b	n_cmdlo(a6),d0
	beq.b	mt_sononew
	move.b	d0,n_sampleoffset(a6)
mt_sononew
	move.b	n_sampleoffset(a6),d0
	lsl	#7,d0
	cmp	n_length(a6),d0
	bge.b	mt_sofskip
	sub	d0,n_length(a6)
	lsl	#1,d0
	add.l	d0,n_start(a6)
	rts
mt_sofskip
	move	#1,n_length(a6)
	rts

mt_volumeslide
	move.b	n_cmdlo(a6),d0
	lsr.b	#4,d0
	tst.b	d0
	beq.b	mt_volslidedown
mt_volslideup
	add.b	d0,n_volume(a6)
	cmp.b	#$40,n_volume(a6)
	bmi.b	mt_vsuskip
	move.b	#$40,n_volume(a6)
mt_vsuskip
	move.b	n_volume(a6),d0
	move.b	d0,mVolume+1(a5)
	rts

mt_volslidedown
	moveq	#$f,d0
	and.b	n_cmdlo(a6),d0
mt_volslidedown2
	sub.b	d0,n_volume(a6)
	bpl.b	mt_vsdskip
	clr.b	n_volume(a6)
mt_vsdskip
	move.b	n_volume(a6),d0
	move	d0,mVolume(a5)
	rts

mt_positionjump
	move.b	n_cmdlo(a6),d0
	cmp.b	mt_songpos(pc),d0
	bhi.b	.e
	st	PS3M_break

.e	subq.b	#1,d0
	move.b	d0,mt_songpos
mt_pj2	clr.b	mt_pbreakpos
	st 	mt_posjumpflag
	st	PS3M_poscha
	rts

mt_volumechange
	moveq	#0,d0
	move.b	n_cmdlo(a6),d0
	cmp.b	#$40,d0
	bls.b	mt_volumeok
	moveq	#$40,d0
mt_volumeok
	move.b	d0,n_volume(a6)
	move	d0,mVolume(a5)
	rts

mt_patternbreak
	moveq	#0,d0
	move.b	n_cmdlo(a6),d0
	move.l	d0,d2
	lsr.b	#4,d0
	mulu	#10,d0
	and.b	#$f,d2
	add.b	d2,d0
	cmp.b	#63,d0
	bhi.b	mt_pj2
	move.b	d0,mt_pbreakpos
	st	mt_posjumpflag
	st	PS3M_poscha
	rts

mt_setspeed
	moveq	#0,d0
	move.b	3(a6),d0
	bne.b	.e
	st	PS3M_break
	st	PS3M_poscha
	rts
.e	clr.b	mt_counter
	cmp	#32,d0
	bhs.b	mt_settempo
	move.b	d0,mt_speed
	rts

mt_settempo
	tst.b	ahi_use
	bne.w	ahi_tempo

	move.l	d1,-(sp)
	move.l	mrate,d1
	move.l	d1,d2
	lsl.l	#2,d1
	add.l	d2,d1
	add	d0,d0
	divu	d0,d1

	addq	#1,d1
	and	#~1,d1
	move	d1,bytesperframe
	move.l	(sp)+,d1
	rts

mt_checkmoreefx
	bsr.w	mt_updatefunk
	move.b	2(a6),d0
	and.b	#$f,d0
	cmp.b	#$9,d0
	beq.w	mt_sampleoffset
	cmp.b	#$b,d0
	beq.w	mt_positionjump
	cmp.b	#$d,d0
	beq.w	mt_patternbreak
	cmp.b	#$e,d0
	beq.b	mt_e_commands
	cmp.b	#$f,d0
	beq.w	mt_setspeed
	cmp.b	#$c,d0
	beq.w	mt_volumechange

	cmp	#mtMOD,mtype
	beq.w	mt_pernop

; MTM runs these also in set frames

	cmp.b	#1,d0
	beq.w	mt_portaup
	cmp.b	#2,d0
	beq.w	mt_portadown
	cmp.b	#3,d0
	beq.w	mt_toneportamento
	cmp.b	#4,d0
	beq.w	mt_vibrato
	cmp.b	#5,d0
	beq.w	mt_toneplusvolslide
	cmp.b	#6,d0
	beq.w	mt_vibratoplusvolslide
	bra.w	mt_pernop


mt_e_commands
	move.b	n_cmdlo(a6),d0
	and.b	#$f0,d0
	lsr.b	#4,d0
;	beq.b	mt_filteronoff
	cmp.b	#1,d0
	beq.w	mt_fineportaup
	cmp.b	#2,d0
	beq.w	mt_fineportadown
	cmp.b	#3,d0
	beq.b	mt_setglisscontrol
	cmp.b	#4,d0
	beq.w	mt_setvibratocontrol
	cmp.b	#5,d0
	beq.w	mt_setfinetune
	cmp.b	#6,d0
	beq.w	mt_jumploop
	cmp.b	#7,d0
	beq.w	mt_settremolocontrol
	cmp.b	#9,d0
	beq.w	mt_retrignote
	cmp.b	#$a,d0
	beq.w	mt_volumefineup
	cmp.b	#$b,d0
	beq.w	mt_volumefinedown
	cmp.b	#$c,d0
	beq.w	mt_notecut
	cmp.b	#$d,d0
	beq.w	mt_notedelay
	cmp.b	#$e,d0
	beq.w	mt_patterndelay
	cmp.b	#$f,d0
	beq.w	mt_funkit
	rts

mt_filteronoff
	move.b	n_cmdlo(a6),d0
	and.b	#1,d0
	asl.b	#1,d0
	and.b	#$fd,$bfe001
	or.b	d0,$bfe001
	rts	

mt_setglisscontrol
	move.b	n_cmdlo(a6),d0
	and.b	#$f,d0
	and.b	#$f0,n_glissfunk(a6)
	or.b	d0,n_glissfunk(a6)
	rts

mt_setvibratocontrol
	move.b	n_cmdlo(a6),d0
	and.b	#$f,d0
	and.b	#$f0,n_wavecontrol(a6)
	or.b	d0,n_wavecontrol(a6)
	rts

mt_setfinetune
	move.b	n_cmdlo(a6),d0
	and.b	#$f,d0
	move.b	d0,n_finetune(a6)
	rts

mt_jumploop
	tst.b	mt_counter
	bne.w	mt_return2
	move.b	n_cmdlo(a6),d0
	and.b	#$f,d0
	beq.b	mt_setloop
	tst.b	n_loopcount(a6)
	beq.b	mt_jumpcnt
	subq.b	#1,n_loopcount(a6)
	beq.w	mt_return2
mt_jmploop
	move.b	n_pattpos(a6),mt_pbreakpos
	st	mt_pbreakflag
	rts

mt_jumpcnt
	move.b	d0,n_loopcount(a6)
	bra.b	mt_jmploop

mt_setloop
	move	mt_patternpos(pc),d0
	lsr	#4,d0
	move.b	d0,n_pattpos(a6)
	rts

mt_settremolocontrol
	move.b	n_cmdlo(a6),d0
	and.b	#$f,d0
	lsl.b	#4,d0
	and.b	#$f,n_wavecontrol(a6)
	or.b	d0,n_wavecontrol(a6)
	rts

mt_retrignote
	move.l	d1,-(sp)
	moveq	#0,d0
	move.b	n_cmdlo(a6),d0
	and.b	#$f,d0
	beq.b	mt_rtnend
	moveq	#0,d1
	move.b	mt_counter(pc),d1
	bne.b	mt_rtnskp
	move	(a6),d1
	and	#$fff,d1
	bne.b	mt_rtnend
	moveq	#0,d1
	move.b	mt_counter(pc),d1
mt_rtnskp
	divu	d0,d1
	swap	d1
	tst	d1
	bne.b	mt_rtnend
mt_doretrig
	move.l	n_start(a6),(a5)	; set start
	moveq	#0,d1
	move	n_length(a6),d1
	add.l	d1,d1
	move.l	d1,mLength(a5)		; set length
	clr.b	mOnOff(a5)		; turn on
	clr.l	mFPos(a5)		; retrig

	move.l	n_loopstart(a6),mLStart(a5)
	moveq	#0,d1
	move	n_replen(a6),d1
	add.l	d1,d1
	move.l	d1,mLLength(a5)
	cmp.l	#2,mLLength(a5)
	bls.b	.eloo
	st	mLoop(a5)
	move.l	(sp)+,d1
	rts
.eloo	clr.b	mLoop(a5)

mt_rtnend
	move.l	(sp)+,d1
	rts

mt_volumefineup
	tst.b	mt_counter
	bne.w	mt_return2
	moveq	#$f,d0
	and.b	n_cmdlo(a6),d0
	bra.w	mt_volslideup

mt_volumefinedown
	tst.b	mt_counter
	bne.w	mt_return2
	moveq	#0,d0
	move.b	n_cmdlo(a6),d0
	and.b	#$f,d0
	bra.w	mt_volslidedown2

mt_notecut
	moveq	#$f,d0
	and.b	n_cmdlo(a6),d0
	cmp.b	mt_counter(pc),d0
	bne.w	mt_return2
	clr.b	n_volume(a6)
	clr	mVolume(a5)
	rts

mt_notedelay
	moveq	#$f,d0
	and.b	n_cmdlo(a6),d0
	cmp.b	mt_counter(pc),d0
	bne.w	mt_return2
	move	(a6),d0
	beq.w	mt_return2

	move	n_period(a6),d0
	lsl	#2,d0
	move	d0,mPeriod(a5)		; set period
	move.l	d1,-(sp)
	bra.w	mt_doretrig

mt_patterndelay
	tst.b	mt_counter
	bne.w	mt_return2
	moveq	#$f,d0
	and.b	n_cmdlo(a6),d0
	tst.b	mt_pattdeltime2
	bne.w	mt_return2
	addq.b	#1,d0
	move.b	d0,mt_pattdeltime
	rts

mt_funkit
	tst.b	mt_counter
	bne.w	mt_return2
	move.b	n_cmdlo(a6),d0
	lsl.b	#4,d0
	and.b	#$f,n_glissfunk(a6)
	or.b	d0,n_glissfunk(a6)
	tst.b	d0
	beq.w	mt_return2
mt_updatefunk
	movem.l	a0/d1,-(sp)
	moveq	#0,d0
	move.b	n_glissfunk(a6),d0
	lsr.b	#4,d0
	beq.b	mt_funkend
	lea	mt_funktable(pc),a0
	move.b	(a0,d0),d0
	add.b	d0,n_funkoffset(a6)
	btst	#7,n_funkoffset(a6)
	beq.b	mt_funkend
	clr.b	n_funkoffset(a6)

	move.l	n_loopstart(a6),d0
	moveq	#0,d1
	move	n_replen(a6),d1
	add.l	d1,d0
	add.l	d1,d0
	move.l	n_wavestart(a6),a0
	addq.l	#1,a0
	cmp.l	d0,a0
	blo.b	mt_funkok
	move.l	n_loopstart(a6),a0
mt_funkok
	move.l	a0,n_wavestart(a6)
	moveq	#-1,d0
	sub.b	(a0),d0
	move.b	d0,(a0)
mt_funkend
	movem.l	(sp)+,a0/d1
	rts


mt_funktable dc.b 0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128

mt_vibratotable	
	dc.b   0, 24, 49, 74, 97,120,141,161
	dc.b 180,197,212,224,235,244,250,253
	dc.b 255,253,250,244,235,224,212,197
	dc.b 180,161,141,120, 97, 74, 49, 24

mt_periodtable
; tuning 0, normal
	dc	856,808,762,720,678,640,604,570,538,508,480,453
	dc	428,404,381,360,339,320,302,285,269,254,240,226
	dc	214,202,190,180,170,160,151,143,135,127,120,113
; tuning 1
	dc	850,802,757,715,674,637,601,567,535,505,477,450
	dc	425,401,379,357,337,318,300,284,268,253,239,225
	dc	213,201,189,179,169,159,150,142,134,126,119,113
; tuning 2
	dc	844,796,752,709,670,632,597,563,532,502,474,447
	dc	422,398,376,355,335,316,298,282,266,251,237,224
	dc	211,199,188,177,167,158,149,141,133,125,118,112
; tuning 3
	dc	838,791,746,704,665,628,592,559,528,498,470,444
	dc	419,395,373,352,332,314,296,280,264,249,235,222
	dc	209,198,187,176,166,157,148,140,132,125,118,111
; tuning 4
	dc	832,785,741,699,660,623,588,555,524,495,467,441
	dc	416,392,370,350,330,312,294,278,262,247,233,220
	dc	208,196,185,175,165,156,147,139,131,124,117,110
; tuning 5
	dc	826,779,736,694,655,619,584,551,520,491,463,437
	dc	413,390,368,347,328,309,292,276,260,245,232,219
	dc	206,195,184,174,164,155,146,138,130,123,116,109
; tuning 6
	dc	820,774,730,689,651,614,580,547,516,487,460,434
	dc	410,387,365,345,325,307,290,274,258,244,230,217
	dc	205,193,183,172,163,154,145,137,129,122,115,109
; tuning 7
	dc	814,768,725,684,646,610,575,543,513,484,457,431
	dc	407,384,363,342,323,305,288,272,256,242,228,216
	dc	204,192,181,171,161,152,144,136,128,121,114,108
; tuning -8
	dc	907,856,808,762,720,678,640,604,570,538,508,480
	dc	453,428,404,381,360,339,320,302,285,269,254,240
	dc	226,214,202,190,180,170,160,151,143,135,127,120
; tuning -7
	dc	900,850,802,757,715,675,636,601,567,535,505,477
	dc	450,425,401,379,357,337,318,300,284,268,253,238
	dc	225,212,200,189,179,169,159,150,142,134,126,119
; tuning -6
	dc	894,844,796,752,709,670,632,597,563,532,502,474
	dc	447,422,398,376,355,335,316,298,282,266,251,237
	dc	223,211,199,188,177,167,158,149,141,133,125,118
; tuning -5
	dc	887,838,791,746,704,665,628,592,559,528,498,470
	dc	444,419,395,373,352,332,314,296,280,264,249,235
	dc	222,209,198,187,176,166,157,148,140,132,125,118
; tuning -4
	dc	881,832,785,741,699,660,623,588,555,524,494,467
	dc	441,416,392,370,350,330,312,294,278,262,247,233
	dc	220,208,196,185,175,165,156,147,139,131,123,117
; tuning -3
	dc	875,826,779,736,694,655,619,584,551,520,491,463
	dc	437,413,390,368,347,328,309,292,276,260,245,232
	dc	219,206,195,184,174,164,155,146,138,130,123,116
; tuning -2
	dc	868,820,774,730,689,651,614,580,547,516,487,460
	dc	434,410,387,365,345,325,307,290,274,258,244,230
	dc	217,205,193,183,172,163,154,145,137,129,122,115
; tuning -1
	dc	862,814,768,725,684,646,610,575,543,513,484,457
	dc	431,407,384,363,342,323,305,288,272,256,242,228
	dc	216,203,192,181,171,161,152,144,136,128,121,114


mtm_periodtable
; Tuning 0, Normal
	dc	1616,1524,1440,1356,1280,1208,1140,1076,1016,960,907
	dc	856,808,762,720,678,640,604,570,538,508,480,453
	dc	428,404,381,360,339,320,302,285,269,254,240,226
	dc	214,202,190,180,170,160,151,143,135,127,120,113
	dc	107,101,95,90,85,80,75,71,67,63,60,56
	dc	53,50,48,45

; Tuning 1
	dc	1604,1514,1430,1348,1274,1202,1134,1070,1010,954,900
	dc	850,802,757,715,674,637,601,567,535,505,477,450
	dc	425,401,379,357,337,318,300,284,268,253,239,225
	dc	213,201,189,179,169,159,150,142,134,126,119,113
	dc	106,100,94,89,84,80,75,71,67,63,59,56
	dc	53,50,47,45

; Tuning 2
	dc	1592,1504,1418,1340,1264,1194,1126,1064,1004,948,894
	dc	844,796,752,709,670,632,597,563,532,502,474,447
	dc	422,398,376,355,335,316,298,282,266,251,237,224
	dc	211,199,188,177,167,158,149,141,133,125,118,112
	dc	105,99,94,88,83,79,74,70,66,62,59,56
	dc	53,50,47,44

; Tuning 3
	dc	1582,1492,1408,1330,1256,1184,1118,1056,996,940,888
	dc	838,791,746,704,665,628,592,559,528,498,470,444
	dc	419,395,373,352,332,314,296,280,264,249,235,222
	dc	209,198,187,176,166,157,148,140,132,125,118,111
	dc	104,99,93,88,83,78,74,70,66,62,59,55
	dc	52,49,47,44

; Tuning 4
	dc	1570,1482,1398,1320,1246,1176,1110,1048,990,934,882
	dc	832,785,741,699,660,623,588,555,524,495,467,441
	dc	416,392,370,350,330,312,294,278,262,247,233,220
	dc	208,196,185,175,165,156,147,139,131,124,117,110
	dc	104,98,92,87,82,78,73,69,65,62,58,55
	dc	52,49,46,44

; Tuning 5
	dc	1558,1472,1388,1310,1238,1168,1102,1040,982,926,874
	dc	826,779,736,694,655,619,584,551,520,491,463,437
	dc	413,390,368,347,328,309,292,276,260,245,232,219
	dc	206,195,184,174,164,155,146,138,130,123,116,109
	dc	103,97,92,87,82,77,73,69,65,61,58,54
	dc	52,49,46,43

; Tuning 6
	dc	1548,1460,1378,1302,1228,1160,1094,1032,974,920,868
	dc	820,774,730,689,651,614,580,547,516,487,460,434
	dc	410,387,365,345,325,307,290,274,258,244,230,217
	dc	205,193,183,172,163,154,145,137,129,122,115,109
	dc	102,97,91,86,81,77,72,68,64,61,57,54
	dc	51,48,46,43

; Tuning 7
	dc	1536,1450,1368,1292,1220,1150,1086,1026,968,914,862
	dc	814,768,725,684,646,610,575,543,513,484,457,431
	dc	407,384,363,342,323,305,288,272,256,242,228,216
	dc	204,192,181,171,161,152,144,136,128,121,114,108
	dc	102,96,91,85,81,76,72,68,64,60,57,54
	dc	51,48,45,43

; Tuning -8
	dc	1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960
	dc	907,856,808,762,720,678,640,604,570,538,508,480
	dc	453,428,404,381,360,339,320,302,285,269,254,240
	dc	226,214,202,190,180,170,160,151,143,135,127,120
	dc	113,107,101,95,90,85,80,75,71,67,63,60
	dc	56,53,50,48

; Tuning -7
	dc	1700,1604,1514,1430,1350,1272,1202,1134,1070,1010,954
	dc	900,850,802,757,715,675,636,601,567,535,505,477
	dc	450,425,401,379,357,337,318,300,284,268,253,238
	dc	225,212,200,189,179,169,159,150,142,134,126,119
	dc	112,106,100,94,89,84,79,75,71,67,63,60
	dc	56,53,50,47

; Tuning -6
	dc	1688,1592,1504,1418,1340,1264,1194,1126,1064,1004,948
	dc	894,844,796,752,709,670,632,597,563,532,502,474
	dc	447,422,398,376,355,335,316,298,282,266,251,237
	dc	223,211,199,188,177,167,158,149,141,133,125,118
	dc	112,105,99,94,89,84,79,75,70,66,63,59
	dc	56,53,50,47

; Tuning -5
	dc	1676,1582,1492,1408,1330,1256,1184,1118,1056,996,940
	dc	887,838,791,746,704,665,628,592,559,528,498,470
	dc	444,419,395,373,352,332,314,296,280,264,249,235
	dc	222,209,198,187,176,166,157,148,140,132,125,118
	dc	111,105,99,93,88,83,78,74,70,66,62,59
	dc	55,52,49,47

; Tuning -4
	dc	1664,1570,1482,1398,1320,1246,1176,1110,1048,988,934
	dc	881,832,785,741,699,660,623,588,555,524,494,467
	dc	441,416,392,370,350,330,312,294,278,262,247,233
	dc	220,208,196,185,175,165,156,147,139,131,123,117
	dc	110,104,98,93,87,82,78,73,69,65,62,58
	dc	55,52,49,46

; Tuning -3
	dc	1652,1558,1472,1388,1310,1238,1168,1102,1040,982,926
	dc	875,826,779,736,694,655,619,584,551,520,491,463
	dc	437,413,390,368,347,328,309,292,276,260,245,232
	dc	219,206,195,184,174,164,155,146,138,130,123,116
	dc	109,103,97,92,87,82,77,73,69,65,61,58
	dc	55,52,49,46

; Tuning -2
	dc	1640,1548,1460,1378,1302,1228,1160,1094,1032,974,920
	dc	868,820,774,730,689,651,614,580,547,516,487,460
	dc	434,410,387,365,345,325,307,290,274,258,244,230
	dc	217,205,193,183,172,163,154,145,137,129,122,115
	dc	108,102,97,91,86,81,77,72,68,64,61,57
	dc	54,51,48,46

; Tuning -1
	dc	1628,1536,1450,1368,1292,1220,1150,1086,1026,968,914
	dc	862,814,768,725,684,646,610,575,543,513,484,457
	dc	431,407,384,363,342,323,305,288,272,256,242,228
	dc	216,203,192,181,171,161,152,144,136,128,121,114
	dc	108,102,96,91,85,81,76,72,68,64,60,57
	dc	54,51,48,45

mt_chan1temp	ds.b	44*32

mt_sampleinfos
	ds	31*12

mt_songdataptr	dc.l 0

mt_speed	dc.b 6
mt_tempo	dc.b 0
mt_counter	dc.b 0
mt_songpos	dc.b 0
mt_pbreakpos	dc.b 0
mt_posjumpflag	dc.b 0
mt_pbreakflag	dc.b 0
mt_lowmask	dc.b 0
mt_pattdeltime	dc.b 0
mt_pattdeltime2	dc.b 0

mt_patternpos	dc 0
mt_dmacontemp	dc 0



; PLAYING PROCESSES
; ­­­­­­­­­­­­­­­­­

	;section	system,code
syss3mPlay
	movem.l	d0-a6,-(sp)
	lea	data,a5
	basereg	data,a5
	
	move	#$f,$dff096

	move.l	4.w,a6

	if	allocchans
	moveq	#-1,d0
	CALL	AllocSignal
	move.b	d0,sigbit(a5)
	bmi.w	exiz

	lea	allocport(a5),a1
	move.b	d0,15(a1)
	move.l	a1,-(sp)
	suba.l	a1,a1
	CALL	FindTask
	move.l	(sp)+,a1
	move.l	d0,16(a1)
	lea	reqlist(a5),a0
	move.l	a0,(a0)
	addq.l	#4,(a0)
	clr.l	4(a0)
	move.l	a0,8(a0)

	lea	allocreq(a5),a1
	lea	audiodev(a5),a0
	moveq	#0,d0
	moveq	#0,d1
	CALL	OpenDevice
	tst.b	d0
	bne.w	exiz
	st.b	audioopen(a5)

	endc

	lea	lev4int(a5),a1
	moveq	#INTB_AUD0,d0
	CALL	SetIntVector
	move.l	d0,olev4(a5)

	move.l	gfxbase,a2
	move.l	a2,-(sp)

	move.b	PowerSupplyFrequency(a6),d0
	cmp.b	#60,d0
	beq.b	.NTSC

.PAL	move.l	#3546895,audiorate(a5)
	move.l	#1773447,timer(a5)
	bra.b	.qw

.NTSC	move	gb_DisplayFlags(a2),d0
	btst	#4,d0				; REALLY_PAL
	bne.b	.PAL				; Just to be sure

	move.l	#3579545,audiorate(a5)
	move.l	#1789773,timer(a5)
.qw
	move.l	timer(a5),d0
	divu	#250,d0				; 100 Hz
	move	d0,thi(a5)

	move.l	audiorate(a5),d0
	move.l	mixingrate(a5),d1
	divu	d1,d0
	move.l	audiorate(a5),d1
	divu	d0,d1
	swap	d1
	clr	d1
	swap	d1
	move.l	d1,mrate(a5)

	move.l	audiorate(a5),d0
	divu	d1,d0
	swap	d0
	clr	d0
	swap	d0
	move.l	d0,mixingperiod(a5)

	lsl.l	#8,d1				; 8-bit fraction
	move.l	d1,d0
	moveq	#100,d1
	jsr	divu_32
	move.l	d0,mrate50(a5)			;In fact vblankfrequency


	move.l	buffSize,d0
	move.l	mrate50,d1
	lsr.l	#8,d1
	divu	d1,d0
	ext.l	d0
	move.l	d0,maxPlayPos2
	DPRINT	"Max ppos2=%ld"



	moveq	#8,d3
	lea	cianame(a5),a1
	move.b	#'a',3(a1)
openciares
	moveq	#0,d0
	CLIB	Exec,OpenResource
	move.l	d0,ciares(a5)
	beq.b	tryCIAB
	move.l	d0,a6
	lea	timerinterrupt(a5),a1
	moveq	#0,d0
	CALL	AddICRVector
	tst.l	d0
	beq.b	gottimer
	addq.l	#4,d3
	lea	timerinterrupt(a5),a1
	moveq	#1,d0
	CALL	AddICRVector
	tst.l	d0
	beq.b	gottimer
tryCIAB
	lea	cianame(a5),a1
	cmp.b	#'a',3(a1)
	bne.w	exits
	addq.b	#1,3(a1)
	moveq	#0,d3
	bra.b	openciares

ciaaddr		dc.l	$bfd500,$bfd700,$bfe501,$bfe701

gottimer
	lea	craddr+8(a5),a6
	move.l	ciaaddr(pc,d3),d0
	move.l	d0,(a6)
	sub	#$100,d0
	move.l	d0,-(a6)
	moveq	#2,d3
	btst	#9,d0
	bne.b	timerB
	subq.b	#1,d3
	add	#$100,d0
timerB
	add	#$900,d0
	move.l	d0,-(a6)
	move.l	d0,a0
	and.b	#%10000000,(a0)
	move.b	d3,timeropen(a5)
	moveq	#0,d0

	move.l	craddr+4(a5),a1
	move.b	tlo(a5),(a1)
	move.b	thi(a5),$100(a1)
	move.b	#$11,(a0)			; Continuous, force load

	move.l	mixingperiod(a5),d0

	lea	$dff000,a6
	move.l	buffSize(a5),d1
	lsr.l	#1,d1
	move	d1,$a4(a6)
	move	d1,$b4(a6)
	move	d1,$c4(a6)
	move	d1,$d4(a6)
	move	d0,$a6(a6)
	move	d0,$b6(a6)
	move	d0,$c6(a6)
	move	d0,$d6(a6)

	movem.l	buff1(a5),a0-a3
	moveq	#64,d1

	move	pmode(a5),d0
	subq	#1,d0
	bne.b	.nosurround

	moveq	#32,d2

	move.l	a0,$a0(a6)
	move.l	a1,$b0(a6)
	move.l	a0,$c0(a6)
	move.l	a1,$d0(a6)
	move	d1,$a8(a6)
	move	d1,$b8(a6)
	move	d2,$c8(a6)
	move	d2,$d8(a6)


	pushm	all
	move.l	voluproutine,a0
	jsr	(a0)
	popm	all

	bra.w	.ohiis

.nosurround
	subq	#1,d0
	bne.b	.nostereo

	move.l	a0,$a0(a6)
	move.l	a1,$b0(a6)
	move.l	a1,$c0(a6)
	move.l	a0,$d0(a6)
	move	d1,$a8(a6)
	move	d1,$b8(a6)
	move	d1,$c8(a6)
	move	d1,$d8(a6)
	bra.b	.ohiis

.nostereo
	subq	#1,d0
	bne.b	.nomono

	move.l	a0,$a0(a6)
	move.l	a1,$b0(a6)
	move.l	a0,$c0(a6)
	move.l	a1,$d0(a6)
	move	d1,$a8(a6)
	move	d1,$b8(a6)
	move	d1,$c8(a6)
	move	d1,$d8(a6)
	bra.b	.ohiis

.nomono

; REAL SURROUND

	subq	#1,d0
	bne.b	.bit14

	move.l	a0,$a0(a6)
	move.l	a2,$b0(a6)
	move.l	a3,$c0(a6)
	move.l	a1,$d0(a6)

	move	d1,$a8(a6)
	move	d1,$b8(a6)
	move	d1,$c8(a6)
	move	d1,$d8(a6)
	bra.b	.ohiis


; 14-BIT STEREO

.bit14	moveq	#1,d2

	move.l	a0,$a0(a6)
	move.l	a1,$b0(a6)
	move.l	a3,$c0(a6)
	move.l	a2,$d0(a6)
	move	d1,$a8(a6)
	move	d1,$b8(a6)
	move	d2,$c8(a6)
	move	d2,$d8(a6)

.ohiis	jsr	FinalInit

	lea	$dff000,a6
	move	#$80,$9c(a6)
	move	#$c080,$9a(a6)
	move	#$820f,$96(a6)
	clr.l	playpos

syncz	move.l	(sp),a6
	CALL	WaitTOF
	lea	$dff000,a6
	jsr	play

	lea	data,a5
	bsr 	updatePatternInfoBuffer
	bsr		updatePatternInfoData

 ifne TEST
; 	move	#$550,$dff180
 	btst	#10,$dff016
 	bne.b	.noRMB
	;btst	#6,$bfe001 
	;bne.b 	.noMouse
	DPRINT	"eject"
	st	PS3M_eject(a5)
.noRMB
 endif

	tst	PS3M_break(a5)
	beq.b	.nb
	clr	PS3M_break(a5)
	move.l	songoverf,a6
	st	(a6)
;	st	songover+var_b
.nb

	tst	PS3M_eject(a5)
	beq.b	syncz

exits	lea	$dff000,a6
	move	#$f,$96(a6)
	clr	$a8(a6)
	clr	$b8(a6)
	clr	$c8(a6)
	clr	$d8(a6)
	move	#$80,$9c(a6)
	move	#$80,$9a(a6)

	addq.l	#4,sp				; Flush GFXbase

	move.l	olev4(a5),a1
	moveq	#INTB_AUD0,d0
	CLIB	Exec,SetIntVector

exiz	lea	data,a5
	moveq	#0,d0
	move.b	timeropen(a5),d0
	beq.b	rem1
	move.l	ciares(a5),a6
	lea	timerinterrupt(a5),a1
	subq.b	#1,d0
	CALL	RemICRVector

rem1	move.l	4.w,a6
	tst.b	audioopen(a5)
	beq.b	rem2
	lea	allocreq(a5),a1
	CALL	CloseDevice

rem2	moveq	#0,d0
	move.b	sigbit(a5),d0
	bmi.b	rem3
	CALL	FreeSignal

rem3	
 ifeq TEST
	CALL	Forbid
 endc
	clr	PS3M_wait(a5)
	movem.l	(sp)+,d0-a6
	moveq	#0,d0			;No error code
	rts

*************

	;section	killer,code
s3mPlay	movem.l	d0-a6,-(sp)
	lea	data,a5
	move	$dff002,-(sp)		;Old DMAs

	move.l	gfxbase,a6
	move.l	34(a6),-(sp)		;Old view
	move.l	a6,-(sp)
	sub.l	a1,a1
	CALL	LoadView
	CALL	WaitTOF
	CALL	WaitTOF


	move.l	a6,-(sp)

	move.l	4.w,a6
	lob	Forbid

	move.l	(sp)+,a6
	lob	WaitBlit

	lea	$dff000,a6

	move	$1c(a6),d1
.irqs	move	$1e(a6),d0		;Wait for all IRQs to finish...
	and	d1,d0			;before killing the system...
	bne.b	.irqs			;Over safety you might think, but...

	move	#$7ff,$96(a6)		;Disable DMAs
	move	#$8200,$96(a6)		;Enable master DMA
	move	$1c(a6),-(sp)		;Old IRQs
	move	#$7fff,$9a(a6)		;Disable IRQs

	move.l	4.w,a6
	move.b	PowerSupplyFrequency(a6),d0
	cmp.b	#60,d0
	beq.b	.NTSC
	move.l	#3546895,audiorate(a5)
	bra.b	.qw
.NTSC
	move.l	#3579545,audiorate(a5)
.qw
	move.l	audiorate(a5),d0
	move.l	mixingrate(a5),d1
	divu	d1,d0
	move.l	audiorate(a5),d1
	divu	d0,d1
	swap	d1
	clr	d1
	swap	d1
	move.l	d1,mrate(a5)

	move.l	audiorate(a5),d0
	divu	d1,d0

	swap	d0
	clr	d0
	swap	d0
	move.l	d0,mixingperiod(a5)

	lsl.l	#8,d1				; 8-bit fraction
	move.l	d1,d0
	move.l	4.w,a6
	moveq	#0,d1
	move.b	VBlankFrequency(a6),d1
	jsr	divu_32
	move.l	d0,mrate50(a5)			;In fact vblank frequency

	movem.l	buff1(a5),a0-a3
	move.l	mixingperiod(a5),d0

	lea	$dff000,a6
	move.l	buffSize(a5),d1
	lsr.l	#1,d1
	move	d1,$a4(a6)
	move	d1,$b4(a6)
	move	d1,$c4(a6)
	move	d1,$d4(a6)
	move	d0,$a6(a6)
	move	d0,$b6(a6)
	move	d0,$c6(a6)
	move	d0,$d6(a6)

	moveq	#64,d1

	move	pmode(a5),d0
	subq	#1,d0
	bne.b	.nosurround

	moveq	#32,d2

	move.l	a0,$a0(a6)
	move.l	a1,$b0(a6)
	move.l	a0,$c0(a6)
	move.l	a1,$d0(a6)
	move	d1,$a8(a6)
	move	d1,$b8(a6)
	move	d2,$c8(a6)
	move	d2,$d8(a6)
	bra.w	.ohiis

.nosurround
	subq	#1,d0
	bne.b	.nostereo

	move.l	a0,$a0(a6)
	move.l	a1,$b0(a6)
	move.l	a1,$c0(a6)
	move.l	a0,$d0(a6)
	move	d1,$a8(a6)
	move	d1,$b8(a6)
	move	d1,$c8(a6)
	move	d1,$d8(a6)
	bra.b	.ohiis

.nostereo
	subq	#1,d0
	bne.b	.nomono

	move.l	a0,$a0(a6)
	move.l	a1,$b0(a6)
	move.l	a0,$c0(a6)
	move.l	a1,$d0(a6)
	move	d1,$a8(a6)
	move	d1,$b8(a6)
	move	d1,$c8(a6)
	move	d1,$d8(a6)
	bra.b	.ohiis

.nomono

; REAL SURROUND!

	subq	#1,d0
	bne.b	.bit14

	move.l	a0,$a0(a6)
	move.l	a1,$b0(a6)
	move.l	a2,$c0(a6)
	move.l	a3,$d0(a6)
	move	d1,$a8(a6)
	move	d1,$b8(a6)
	move	d1,$c8(a6)
	move	d1,$d8(a6)
	bra.b	.ohiis


; 14-BIT STEREO

.bit14	moveq	#1,d2

	move.l	a0,$a0(a6)
	move.l	a1,$b0(a6)
	move.l	a3,$c0(a6)
	move.l	a2,$d0(a6)
	move	d1,$a8(a6)
	move	d1,$b8(a6)
	move	d2,$c8(a6)
	move	d2,$d8(a6)

.ohiis	move.l	4.w,a6
	moveq	#0,d0
	btst	d0,AttnFlags+1(a6)
	beq.b	.no68010

	Push	a5
	lea	liko(pc),a5
	CALL	Supervisor
	Pull	a5
.no68010
	move.l	d0,vbrr(a5)

	Push	a5
	jsr	FinalInit
	Pull	a5

	lea	$dff000,a6
	move.l	vbrr(a5),a0
	move.l	$70(a0),olev4(a5)
	move.l	#lev4,$70(a0)
	move.l	$6c(a0),olev3(a5)
	move.l	#lev3,$6c(a0)
	move	#$800f,$96(a6)

	move	#$80+$20,$9c(a6)
	move	#$c080+$20,$9a(a6)

sync	move	#4,$180(a6)
	jsr	play

	lea	$dff000,a6
	move	#$5a,$180(a6)
	btst	#6,$bfe001
	bne.b	sync

exitz	move	#$f00,$180(a6)
	move	#$7fff,$9a(a6)		;Restore system status
	move	#$7ff,$96(a6)
	move	#$7fff,$9c(a6)		;Clear possible IRQ-requests (4 safety)

	move.l	vbrr(a5),a0
	move.l	olev4(a5),$70(a0)	;Restore IRQ-vectors
	move.l	olev3(a5),$6c(a0)

.q	move	6(a6),$180(a6)
	btst	#6,$bfe001
	beq.b	.q

	move	(sp)+,d7		;Old IRQs

	move.l	(sp)+,a6		;Old gfxbase
	move.l	(sp)+,a1		;Old view

	lea	$dff000,a0
	move	#$ff0,$180(a0)		;!!! debug color

	or	#$8000,d7
	and	#~$780,d7		;And off Audio IRQs (for safety again)
	move	d7,$9a(a0)		;Old IRQs

	move	(sp)+,d7		;Old DMAs
	or	#$8000,d7
	and	#~$f,d7			;And off Audio DMAs (convenience...)
	move	d7,$96(a0)

	clr	$a8(a0)			;Volumes down...
	clr	$b8(a0)
	clr	$c8(a0)
	clr	$d8(a0)

	move	#$ff,$180(a0)		;!!! debug color2

	CALL	LoadView		;Old view
	move.l	38(a6),d3		;Old Copper1
	move.l	d3,$dff080		;Set old Copper
	move	d3,$dff088		;Trigger

	move.l	4.w,a6
	lob	Permit


	lea	.in(pc),a1
	lob	OldOpenLibrary
	move.l	d0,a6

	lob	RethinkDisplay

	move.l	a6,a1
	move.l	4.w,a6
	lob	CloseLibrary


	movem.l	(sp)+,d0-a6
	moveq	#0,d0			;No error code
;	move	#$f0,$dff000		;Safe! (Hopefully...)
	rts


.in	dc.b	"intuition.library",0
 even

liko	ifeq	disable020
	MOVEC	VBR,d0
	endc
	rte



*******

;*** Datas ***


	;section	datas,data
data

lev4int		dc.l	0,0
		dc.b	NT_INTERRUPT,127
		dc.l	l4name
		dc.l	playpos
		dc.l	slev4

timerinterrupt 	dc.l	0,0
		dc.b	NT_INTERRUPT,-1
		dc.l	timerint
		dc.l	playpos
		dc.l	lev6server


CyberCalibration dc.b	0
		dc.b	0
CyberTable	dc.l	0

vbrr		dc.l	0
olev4		dc.l	0
olev3		dc.l	0
vtabaddr	dc.l	0
playpos		dc.l	0
bufpos		dc.l	0
buffSize	dc.l	BUFFER
buffSizeMask	dc.l	BUFFER-1

bytesperframe	dc	0
bytes2do	dc	0
todobytes	dc	0
bytes2music	dc	0

mixad1		dc.l	0
mixad2		dc.l	0
cbufad		dc.l	0
opt020		dc	0

mixingrate	dc.l	16000
mixingperiod	dc.l	0
vboost		dc.l	0
pmode		dc	SURROUND
system		dc	DISABLED

playpos2	dc.l	0
maxPlayPos2	dc.l	0

PS3M_play	dc	0
PS3M_break	dc	0
PS3M_poscha	dc	0
PS3M_position	dc	0
PS3M_master	dc	64
PS3M_eject	dc	0
PS3M_wait	dc	0
PS3M_cont	dc	0
PS3M_paused	dc	0
PS3M_initialized dc	0
PS3M_reinit	dc	0

audiorate	dc.l	0
mrate		dc.l	0
mrate50		dc.l	0

slen		dc	0
pats		dc	0
inss		dc	0

samples		dc.l	0
patts		dc.l	0

fformat		dc	0
sflags		dc	0

rows		dc	63
pbrkrow		dc	0
pbrkflag	dc	0
spd		dc	6
tempo		dc	125

cn		dc	0

pdelaycnt	dc	0
pjmpflag	dc	0

chans		dc	0
numchans	dc	0
maxchan		dc	0
mtype		dc	0			
clock		dc.l	0			; 14317056/4 for S3Ms
globalVol	dc	0

pos		dc	0
plen		dc	0
ppos		dc.l	0

divtabs		ds.l	16

c0		ds.b	s3mChanBlock_SIZE*32

cha0		ds.b	mChanBlock_SIZE*32

pantab		ds.b	32			;channel panning infos


s3m		dc.l	0
s3mlen		dc.l	0

tbuf		dc.l	0
tbuf2		dc.l	0
buff1		dc.l	0
buff2		dc.l	0
buff3		dc.l	0
buff4		dc.l	0
buff14		dc.l	0
vtab		dc.l	0
dtab		dc.l	0
dtabsize	dc.l	0

mname		dc.l	0

positioneita	dc	1

thi		dc.b	0
tlo		dc.b	0
timer		dc.l	0
ciares		dc.l	0
craddr		dc.l	0,0,0

timeropen	dc.b	0
		even

audioopen	dc.b	0
sigbit		dc.b	-1

dat		dc	$f00

allocport	dc.l	0,0
		dc.b	4,0
		dc.l	0
		dc.b	0,0
		dc.l	0
reqlist	dc.l	0,0,0
		dc.b	5,0

allocreq	dc.l	0,0
		dc	127
		dc.l	0
		dc.l	allocport
		dc	68
		dc.l	0,0,0
		dc	0
		dc.l	dat
		dc.l	1,0,0,0,0,0,0
		dc	0

xmsign		dc.b	`Extended Module:`

timerint 	dc.b	`PS3M-CIA`,0
l4name		dc.b	`PS3M-Audio`,0

cianame		dc.b	`ciax.resource`,0
audiodev 	dc.b	`audio.device`,0

		even

xm_patts	ds.l	256
xm_insts	ds.l	128


activeSongPos 	dc 	0
activePattPos 	dc 	0
* buffered information: song position, pattern position
			ds.l	4	* underflow room
patternInfoBuffer
			ds.l	2048




 if DEBUG
PRINTOUT_DEBUGBUFFER
	pea	debugDesBuf(pc)
	bsr.b PRINTOUT
	rts

PRINTOUT
	pushm	d0-d3/a0/a1/a5/a6
	move.l	output(pc),d1
	bne.w	.open

	* try tall window firsr
	move.l	#.bmb,d1
	move.l	#MODE_NEWFILE,d2
	move.l	dosbase,a6
	lob 	Open
	move.l	d0,output
	bne.b	.open
	* smaller next
	move.l	#.bmbSmall,d1
	move.l	#MODE_NEWFILE,d2
	move.l	dosbase,a6
	lob	Open
	move.l	d0,output
	bne.b	.open
	* still not open! exit
	bra.b	.x

.bmb	dc.b	"CON:20/10/350/490/HiP PS3M debug",0
.bmbSmall
	dc.b	"CON:20/10/350/190/HiP PS3M debug",0
    even
.open
	move.l	32+4(sp),a0

	moveq	#0,d3
	move.l	a0,d2
.p	addq	#1,d3
	tst.b	(a0)+
	bne.b	.p
	move.l	_DosBase,a6
 	lob	Write
.x	popm	d0-d3/a0/a1/a5/a6
	move.l	(sp)+,(sp)
	rts
 
desmsgDebugAndPrint
	* sp contains the return address, which is
	* the string to print
	movem.l	d0-d7/a0-a3/a6,-(sp)
	* get string
	move.l	4*(8+4+1)(sp),a0
	* find end of string
	move.l	a0,a1
.e	tst.b	(a1)+
	bne.b	.e
	move.l	a1,d7
	btst	#0,d7
	beq.b	.even
	addq.l	#1,d7
.even
	* overwrite return address 
	* for RTS to be just after the string
	move.l	d7,4*(8+4+1)(sp)

	lea	debugDesBuf(pc),a3
	move.l	sp,a1	
	lea	.putc(pc),a2	
	move.l	4.w,a6
	lob	RawDoFmt
	movem.l	(sp)+,d0-d7/a0-a3/a6
	bsr.w	PRINTOUT_DEBUGBUFFER
	rts	* teleport!
.putc	
	move.b	d0,(a3)+	
	rts

output			ds.l 	1
debugDesBuf		ds.b	1024

 endif
