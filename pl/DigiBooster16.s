;APS000007100000000D0000000D0000000D000025DF0000000D0000000D0000000D0000000D0000000D
testi	=	0



;----------------- digi booster by tap & walt ----------------
;		     player v 1.6 pure code
;		     by tap - tomasz piasta
;			  © 14.06.1996
;
; the player plays modules from digi booster 1.0-1.6 with packed
; and unpacked pattern data. eight channels modules take about 0.25 frame
; (on standard amiga 1200). the player automticly recognize
; processor (old motorola 68000/68010 or 68020 and higher) and uses
; suitable instructions. if you want to use this player in your
; productions please buy the original (digi booster with player
; source code).
; the code of player isn't optimized yet (except the mix routine
; which is extremly fast!).
;
; db_init output
; d7 =  0  all right
; d7 = -1  not enough memory for mixbuffers
; d7 = -2  cant alloc cia timers
;
;
;------------------------- effects commands --------------------------
; * 0xx arpeggio
; * 1xx portamento up
; * 2xx portamento down
; * 3xx glissando
; * 4xx vibrato
; * 5xx glissando + slide volume
; * 6xx vibrato + slide volume
;   7xx volume vibrato
; * 8xx robot
; * 9xx sample offset - main
; * axx slide volume
; * bxx song repeat
; * cxx set volume
; * dxx pattern break
; * fxx set speed
;
;----------------------------- exx commands ---------------------------
; * e00 filter off
; * e01 filter on
; * e1x fine slide up
; * e2x fine slide down
; * e30 backwd play sample
; * e31 backwd play sample+loop
; * e40 stop playing sample
; * e50 channel	off
; * e51 channel	on
; * e6x loops
; * e8x sample offset 2
; * e9x retrace
; * eax fine volume up
; * ebx fine volume down
; * ecx cut sample
;   edx sample delay
; * eex pause


	section	code,code_p

 ifne testi
	lea	module,a0
	lea	songover_,a1
	lea	stopcont_,a2

	bsr.b	init

loop	btst	#6,$bfe001
	bne.b	loop

	bsr.w	db_end
	rts

songover_	dc	0
stopcont_	dc.b	1
	even

 endc



	jmp	init(pc)
	jmp	db_end(pc)

songover	dc.l	0
stopcont	dc.l	0

init
	move.l	a0,moddigi
	move.l	a1,songover
	move.l	a2,stopcont
	
	bsr.w	db_init
* d7 = returncode
	

	lea	songpos(pc),a0
	move.l	moddigi(pc),a1
	lea	ordnum(a1),a1
	lea	pattpos(pc),a2
	lea	mainvolvalue(pc),a3

	move.l	d7,d0
	rts


chanarea	equ	108
version:	equ	24
channels:	equ	25
packenable:	equ	26
patnum:		equ	46
ordnum:		equ	47
orders:		equ	48
samlens:	equ	176
samreps:	equ	300
samreplens:	equ	424
samvols:	equ	548
samfins:	equ	579
songname:	equ	610
samnames:	equ	642
songdata:	equ	1572


sambuffadr:	equ	0	; 4
samrep1:	equ	4	; 4
samrep2:	equ	8	; 4
changeadr:	equ	12	; 1
mixdon:		equ	13	; 1
vola:		equ	14	; 1
volb:		equ	15	; 1
slidevololda	equ	16	; 1
slidevololdb	equ	17	; 1
replaceenable	equ	18	; 1
offenable	equ	19	; 1
samoffseta	equ	20	; 1
samoffsetb	equ	21	; 1
retracecnta	equ	22	; 1
retracecntb	equ	23	; 1
oldsamnuma:	equ	24	; 1
oldsamnumb:	equ	25	; 1
robotoldval:	equ	26	; 1
robotenable:	equ	27	; 1
mainperiod:	equ	28	; 2
mainvol:	equ	30	; 1
mbrpointer	equ	31	; 1
playpointer	equ	32	; 1
oldd0		equ	34	; 2
oldd1		equ	36	; 2
oldd2		equ	38	; 2
oldd3		equ	40	; 2
oldd4		equ	42	; 2
oldd5		equ	44	; 2
oldd6		equ	46	; 2
loopsdataschana	equ	48	; 3
loopsdataschanb	equ	51	; 3
backwdenable:	equ	56	; 1
eqnewsama	equ	57	; 1
eqnewsamb	equ	58	; 1
maindtalen:	equ	60	; 2
portupoldvala	equ	62	; 1
portupoldvalb	equ	63	; 1
portdownoldvala	equ	64	; 1
portdownoldvalb	equ	65	; 1
vibratodatasa	equ	66	; 4
vibratodatasb	equ	70	; 4
glissandodatasa	equ	74	; 6
glissandodatasb	equ	80	; 6
buffbegadr	equ	86	; 4
buffendadr	equ	90	; 4
buffmixadr	equ	94	; 4
onoffchana	equ	98	; 1
onoffchanb	equ	99	; 1
orgperioda	equ	100	; 2
orgperiodb	equ	102	; 2
oldvola:	equ	104	; 1
oldvolb:	equ	105	; 1
notecount	equ	106	; 2



plugcia:
	move.l	4.w,a6
	lea	graphname,a1
	moveq	#0,d0
	jsr	-408(a6) 
	move.l	d0,graphbase

	lea	$bfd000,a5
	moveq	#2,d6
irqcialoop:
	moveq	#0,d0
	lea	cianame(pc),a1
	movea.l	4,a6
	jsr	-498(a6) * OpenResource
	move.l	d0,ciabase
	beq.w	nocia

	move.l	graphbase(pc),d0
	move.l	d0,a1

	tst.l	d0
	beq.w	unplugcia

	move.l	#125*14209,d7
	divu.w	#125,d7
	jsr	-414(a6)  * CloseLibrary
	move.l	ciabase(pc),a6
	cmp.w	#2,d6
	beq.s	ciab

	lea	irqdata(pc),a1
	moveq	#1,d0  * Timer B
	jsr	-6(a6)	* AddICRVector

	move.l	#1,whichcia
	tst.l	d0
	bne.s	changecia
	move.l	a5,ciaadress

	move.b	d7,$600(a5)
	lsr.w	#8,d7
	move.b	d7,$700(a5)
	move.b	#%00010001,$f00(a5)
	rts

ciab:
	lea	irqdata(pc),a1
	moveq	#0,d0 * Timer A
	jsr	-6(a6)	* alloc ciab
	clr.l	whichcia
	tst.l	d0
	bne.s	changecia
	move.l	a5,ciaadress

	move.b	d7,$400(a5)
	lsr.w	#8,d7
	move.b	d7,$500(a5)
	move.b	#%00010001,$e00(a5)
	rts

changecia:
	move.b	#"a",cianame+3
	lea	$bfe001,a5
	subq.w	#1,d6
	bne.w	irqcialoop
nocia:
	clr.l	ciabase
	rts

unplugcia:
	move.l	4.w,a6
	move.l	graphbase,a1
	jsr	-414(a6)
	move.l	ciabase(pc),d0
	beq.b	nocia
	move.l	d0,a6
	move.l	ciaadress(pc),a5
	tst.l	whichcia
	beq.s	ciaboff
	bclr	#0,$f00(a5)
	moveq	#1,d0
	bra.s	offevery
ciaboff:
	bclr	#0,$e00(a5)
	moveq	#0,d0
offevery:
	lea	irqdata(pc),a1
	moveq	#0,d0
	jsr	-12(a6)
	rts

graphbase:	dc.l	0
ciabase:	dc.l	0
ciaadress:	dc.l	0
whichcia:	dc.l	0
graphname:	dc.b	'graphics.library',0
cianame:	dc.b	"ciab.resource",0
		even
irqdata:
	dc.l	0,0
	dc.b	2,1
	dc.l	0
	dc.l	softserver * data to a1
	dc.l	irqproc_

softserver
	dc.l	0,0
	dc.b	2
	dc.b	0	* priority
	dc.l	0 ; name
	dc.l	0           * is_Data passed in a1
	dc.l	irqproc     * code entry point


irqproc_
._LVOCause	EQU	-180
	move.l	a6,-(sp)
	move.l	4.w,a6
	jsr	._LVOCause(a6)
	move.l	(sp)+,a6
	rts

irqproc:
	movem.l	d0-a6,-(sp)
	tst.w	ciachanged
	beq.s	cia_done
	clr.w	ciachanged
	move.l	ciaadress(pc),a5
	move.l	#14209*125,d7
	divu	ciatempo,d7
	and.l	#$ffff,d7
	tst.l	whichcia
	bne.s	cia_b
	move.b	d7,$400(a5)
	lsr.w	#8,d7
	move.b	d7,$500(a5)
	bset	#0,$e00(a5)
	bra.s	cia_done
cia_b
	move.b	d7,$600(a5)
	lsr.w	#8,d7
	move.b	d7,$700(a5)
	bset	#0,$f00(a5)
cia_done
	bsr.w	db_music
	movem.l	(sp)+,d0-a6
	rts
; --------------------------------------------------------------------

db_init:
;	move.l	#$10001,memtype
	move.l	#$10002,memtype
	move.w	#14-1,wdma
	move.w	#125,ciatempo
	clr.b	fast
	move.l	4.w,a6
	move.l	#4,d1
	jsr	-216(a6)
	tst.l	d0
	beq.b	nofast
	move.b	#1,fast
	move.w	#8-1,wdma
nofast:
	move.l	4.w,a6	
	move.w	296(a6),d0	

	btst	#0,d0
	beq.s	mc68010
	move.b	#1,oldcpu
mc68010:
	btst	#1,d0
	beq.s	mc68020
	clr.b	oldcpu
mc68020:
	btst	#2,d0
	beq.s	mc68030
	clr.b	oldcpu
mc68030:
	btst	#3,d0
	beq.s	mc68040
	clr.b	oldcpu
mc68040:
	tst.b	oldcpu
	beq.s	newcpu
	clr.b	fast
	move.w	#14-1,wdma
	move.l	#$10002,memtype
newcpu
	bsr.w	allocmixbuffers
	tst.b	d7
	bne.w	exit		; if there's no mem just exit this shit

	moveq	#0,d7
	move.w	buffsize,d7
	lea	channel1,a0
	move.l	sample_buff1_1(pc),(a0)
	move.l	sample_buff1_1(pc),buffbegadr(a0)
	move.l	sample_buff1_1(pc),buffendadr(a0)
	add.l	d7,buffendadr(a0)
	move.l	sample_buff1_2(pc),chanarea(a0)
	move.l	sample_buff1_2(pc),chanarea+buffbegadr(a0)
	move.l	sample_buff1_2(pc),chanarea+buffendadr(a0)
	add.l	d7,chanarea+buffendadr(a0)
	move.l	sample_buff1_3(pc),chanarea*2(a0)
	move.l	sample_buff1_3(pc),(chanarea*2)+buffbegadr(a0)
	move.l	sample_buff1_3(pc),(chanarea*2)+buffendadr(a0)
	add.l	d7,(chanarea*2)+buffendadr(a0)
	move.l	sample_buff1_4(pc),chanarea*3(a0)
	move.l	sample_buff1_4(pc),(chanarea*3)+buffbegadr(a0)
	move.l	sample_buff1_4(pc),(chanarea*3)+buffendadr(a0)
	add.l	d7,(chanarea*3)+buffendadr(a0)

	clr.b	songpos
	clr.b	pattpos
	clr.b	count
	move.b	#6,temp

	bset	#1,$bfe001
	bsr.w	db_initvoices

	move.b	temp(pc),count
	move.l	moddigi,a5

	lea	1572(a5),a1
	lea	pattadresses,a2
	move.l	a1,(a2)+
	moveq	#0,d7
	move.b	patnum(a5),d7
	move.l	#2048,d0
db_makepatadr
	tst.b	packenable(a5)
	beq.s	dp_setpatadr
	move.w	(a1),d0
	addq	#2,d0
dp_setpatadr
	add.l	d0,a1
	move.l	a1,(a2)+
	dbf	d7,db_makepatadr

	lea	samlens(a5),a0
	move.l	a1,d6
	lea	sample_starts,a2
	moveq	#30,d7
db_makesamadr
	move.l	d6,(a2)+
	add.l	(a0)+,d6
	dbf	d7,db_makesamadr

	lea	samlens(a5),a0
	lea	sample_lenghts,a1
	moveq	#31-1,d7
db_cploop1:
	move.l	(a0)+,(a1)+
	dbf	d7,db_cploop1
	bsr.w	make_voltab

	cmp.b	#$10,version(a5)
	beq.s	olddigimod
	cmp.b	#$11,version(a5)
	beq.s	olddigimod
	cmp.b	#$12,version(a5)
	beq.s	olddigimod
	cmp.b	#$13,version(a5)
	beq.s	olddigimod
	bra.b	ciaon

exit	rts

olddigimod
	lea	samfins(a5),a6
	moveq	#31-1,d7
clrfins	clr.b	(a6)+
	dbf	d7,clrfins
ciaon
	bsr.w	plugcia
	tst.l	ciabase
	bne.s	ciaok
	bsr.w	freemixbuffers
	moveq	#-2,d7
	rts
ciaok
	moveq	#0,d7
	rts

db_initvoices:
	move.l	sample_buff1_1,$dff0a0
	move.w	#166,$dff0a4
	move.w	#214,$dff0a6
	clr.w	$dff0a8
	move.l	sample_buff1_2,$dff0b0
	move.w	#166,$dff0b4
	move.w	#214,$dff0b6
	clr.w	$dff0b8
	move.l	sample_buff1_3,$dff0c0
	move.w	#166,$dff0c4
	move.w	#214,$dff0c6
	clr.w	$dff0c8
	move.l	sample_buff1_4,$dff0d0
	move.w	#166,$dff0d4
	move.w	#214,$dff0d6
	clr.w	$dff0d8
	rts

allocmixbuffers:
	move.l	4.w,a6
	move.l	#2500*3,d0
	add.l	#8+8,d0
	move.l	memtype(pc),d1
	jsr	-198(a6)
	tst.l	d0
	beq.w	allocmixbufferror
	addq.l	#8,d0
	move.l	d0,sample_buff1_mix

	move.l	4.w,a6
	move.l	#2500*3,d0
	add.l	#8+8,d0
	move.l	memtype(pc),d1
	jsr	-198(a6)
	tst.l	d0
	beq.w	allocmixbufferror
	addq.l	#8,d0
	move.l	d0,sample_buff2_mix

	move.l	4.w,a6
	move.l	#2500*3,d0
	add.l	#8+8,d0
	move.l	memtype(pc),d1
	jsr	-198(a6)
	tst.l	d0
	beq.w	allocmixbufferror
	addq.l	#8,d0
	move.l	d0,sample_buff3_mix

	move.l	4.w,a6
	move.l	#2500*3,d0
	add.l	#8+8,d0
	move.l	memtype(pc),d1
	jsr	-198(a6)
	tst.l	d0
	beq.w	allocmixbufferror
	addq.l	#8,d0
	move.l	d0,sample_buff4_mix


*	clear	$10000
*	chip	$00002
*	fast	$00004

	move.l	4.w,a6
	moveq	#0,d0
	move.w	buffsize,d0
	add.l	#8+8,d0
	move.l	#$10002,d1
	jsr	-198(a6)
	tst.l	d0
	beq.w	allocmixbufferror
	addq.l	#8,d0
	move.l	d0,sample_buff1_1

	moveq	#0,d0
	move.w	buffsize,d0
	add.l	#8+8,d0
	move.l	#$10002,d1
	jsr	-198(a6)
	tst.l	d0
	beq.b	allocmixbufferror
	addq.l	#8,d0
	move.l	d0,sample_buff1_2

	moveq	#0,d0
	move.w	buffsize,d0
	add.l	#8+8,d0
	move.l	#$10002,d1
	jsr	-198(a6)
	tst.l	d0
	beq.b	allocmixbufferror
	addq.l	#8,d0
	move.l	d0,sample_buff1_3

	moveq	#0,d0
	move.w	buffsize,d0
	add.l	#8+8,d0
	move.l	#$10002,d1
	jsr	-198(a6)
	tst.l	d0
	beq.b	allocmixbufferror
	addq.l	#8,d0
	move.l	d0,sample_buff1_4

	moveq	#0,d0
	move.w	#66*256,d0
	add.l	#8+8,d0
	move.l	#$10004,d1
	jsr	-198(a6)
	tst.l	d0
	beq.b	allocmixbufferror
	addq.l	#8,d0
	move.l	d0,voltabadr

	moveq	#0,d7
	rts
allocmixbufferror
	bsr.b	freemixbuffers
	moveq	#-1,d7
	rts

freemixbuffers:
	move.l	4.w,a6
	move.l	#2500*3,d0
	move.l	sample_buff1_mix(pc),a1
	cmp.l	#0,a1
	beq.s	nofree1_1b
	subq.l	#8,a1
	add.l	#8+8,d0
	jsr	-210(a6)
nofree1_1b
	move.l	#2500*3,d0
	move.l	sample_buff2_mix(pc),a1
	cmp.l	#0,a1
	beq.s	nofree1_2b
	subq.l	#8,a1
	add.l	#8+8,d0
	jsr	-210(a6)
nofree1_2b
	move.l	#2500*3,d0
	move.l	sample_buff3_mix(pc),a1
	cmp.l	#0,a1
	beq.s	nofree1_3b
	subq.l	#8,a1
	add.l	#8+8,d0
	jsr	-210(a6)
nofree1_3b
	move.l	#2500*3,d0
	move.l	sample_buff4_mix(pc),a1
	cmp.l	#0,a1
	beq.s	nofree1_4b
	subq.l	#8,a1
	add.l	#8+8,d0
	jsr	-210(a6)
nofree1_4b

	move.l	4.w,a6
	moveq	#0,d0
	move.w	buffsize,d0
	move.l	sample_buff1_1(pc),a1
	cmp.l	#0,a1
	beq.s	nofree1_1
	subq.l	#8,a1
	add.l	#8+8,d0
	jsr	-210(a6)
nofree1_1
	moveq	#0,d0
	move.w	buffsize,d0
	move.l	sample_buff1_2(pc),a1
	cmp.l	#0,a1
	beq.s	nofree1_2
	subq.l	#8,a1
	add.l	#8+8,d0
	jsr	-210(a6)
nofree1_2
	moveq	#0,d0
	move.w	buffsize,d0
	move.l	sample_buff1_3(pc),a1
	cmp.l	#0,a1
	beq.s	nofree1_3
	subq.l	#8,a1
	add.l	#8+8,d0
	jsr	-210(a6)
nofree1_3
	moveq	#0,d0
	move.w	buffsize,d0
	move.l	sample_buff1_4(pc),a1
	cmp.l	#0,a1
	beq.s	nofree1_4
	subq.l	#8,a1
	add.l	#8+8,d0
	jsr	-210(a6)
nofree1_4
	move.l	#66*256,d0
	move.l	voltabadr,a1
	cmp.l	#0,a1
	beq.s	nofreevol
	subq.l	#8,a1
	add.l	#8+8,d0
	jsr	-210(a6)
nofreevol
	rts

sample_buff1_mix:	dc.l	0
sample_buff2_mix:	dc.l	0
sample_buff3_mix:	dc.l	0
sample_buff4_mix:	dc.l	0
sample_buff1_1:		dc.l	0
sample_buff1_2:		dc.l	0
sample_buff1_3:		dc.l	0
sample_buff1_4:		dc.l	0

memtype:	dc.l	0
wdma:		dc.w	0
fast:		dc.b	0
oldcpu:		dc.b	0
songpos:	dc.b	0
pattpos:	dc.b	0
temp:		dc.b	0
count:		dc.b	0
jmpen:		dc.b	0
oldpattpos:	dc.b	0
pauseen:	dc.b	0
hisam:		dc.b	0
pausevbl:	dc.w	0
olddepadr:	dc.l	0
moddigi:	dc.l	0
channelenable:	dc.w	0
mixperioda:	dc.w	0
mixperiodb:	dc.w	0
leng:		dc.w	0
what:		dc.w	0
ciatempo:	dc.w	0
ciachanged:	dc.w	0

; ------------------- paremeters --------------
mainvolvalue:	dc.w	64	; 0-64
confvolboost	dc.w	75	; 0-100%
confmix:	dc.b	0	; 0 - mix only joined chennels eg. mix when
				; 1a and 1b channels are used...
		even		; 1 - mix all channels
buffsize	dc.w	40960	; sample mix buffer size
		even

db_music:
	move.l	stopcont(pc),a5
	tst.b	(a5)
	beq.b	.x
	;move	#$f00,$dff180
	bsr.b	.do
	;move	#0,$dff180
.x	rts
.do
	
	move.l	moddigi,a5
	lea	sample_starts,a0	; sample starts, 124(a0) lenghts
	lea	samreps(a5),a3		; sample repeats, 124(a3) replens
	lea	samvols(a5),a4		; sample volumes

	move.b	count(pc),d7
	cmp.b	temp(pc),d7
	blt.w	depackdone

	tst.b	temp
	beq.s	nonewpos
	cmp.b	#64,pattpos
	bne.s	nonewpos
	clr.b	pattpos
	addq.b	#1,songpos
nonewpos:
	moveq	#0,d6
	moveq	#0,d7
	move.b	ordnum(a5),d7
	move.b	songpos(pc),d6
	cmp.w	d6,d7
	bge.s	norepeatsong
	clr.b	songpos
	clr.b	pattpos
	move.l	pattadresses,a1
norepeatsong:

	moveq	#0,d7
	move.b	songpos(pc),d7
	move.b	orders(a5,d7.w),d7
	lsl.w	#2,d7
	lea	pattadresses,a1
	move.l	(a1,d7.w),a1

	tst.b	packenable(a5)
	bne.s	depackpattern

	moveq	#0,d7
	move.b	pattpos(pc),d7
	lsl.w	#2,d7
	add.w	d7,a1

	lea	unpackeddata,a6
	moveq	#3,d7
copydataloop
	move.l	0(a1),(a6)+
	move.l	1024(a1),(a6)+
	lea	256(a1),a1
	dbf	d7,copydataloop
	bra.w	depackdone
depackpattern:

	addq.w	#2,a1
	lea	(a1),a6
	lea	64(a1),a5
	moveq	#0,d7
	move.b	pattpos(pc),d7
	add.w	d7,a1
	move.b	oldpattpos(pc),d6
	addq.b	#1,d6
	cmp.b	d6,d7
	beq.s	nocalcadr

	tst.w	d7
	beq.s	depackdata
	subq	#1,d7
	moveq	#0,d1
depackcalcadr:
	move.b	(a6)+,d0
	btst	#7,d0
	beq.s	depacknoadd7
	addq	#4,d1
depacknoadd7
	btst	#6,d0
	beq.s	depacknoadd6
	addq	#4,d1
depacknoadd6
	btst	#5,d0
	beq.s	depacknoadd5
	addq	#4,d1
depacknoadd5
	btst	#4,d0
	beq.s	depacknoadd4
	addq	#4,d1
depacknoadd4
	btst	#3,d0
	beq.s	depacknoadd3
	addq	#4,d1
depacknoadd3
	btst	#2,d0
	beq.s	depacknoadd2
	addq	#4,d1
depacknoadd2
	btst	#1,d0
	beq.s	depacknoadd1
	addq	#4,d1
depacknoadd1
	btst	#0,d0
	beq.s	depacknoadd0
	addq	#4,d1
depacknoadd0
	dbf	d7,depackcalcadr
	add.l	d1,a5
	bra.s	depackdata
nocalcadr
	move.l	olddepadr(pc),a5
depackdata:
	move.b	pattpos(pc),oldpattpos
	lea	unpackeddata,a6
	moveq	#7,d7
depackdataloop
	btst	d7,(a1)
	beq.s	depackputzero
	move.l	(a5)+,(a6)+
	dbf	d7,depackdataloop
	move.l	a5,olddepadr
	bra.s	depackdone
depackputzero
	clr.l	(a6)+
	dbf	d7,depackdataloop
	move.l	a5,olddepadr
depackdone

	lea	unpackeddata,a1
	moveq	#0,d6
	moveq	#0,d5
	lea	channel1,a6
	lea	$dff0a0,a5
	bsr.w	playvoice
	moveq	#1,d5
	lea	channel2,a6
	lea	$dff0b0,a5
	bsr.w	playvoice
	moveq	#2,d5
	lea	channel3,a6
	lea	$dff0c0,a5
	bsr.b	playvoice
	moveq	#3,d5
	lea	channel4,a6
	lea	$dff0d0,a5
	bsr.b	playvoice

	tst.w	d6
	beq.s	nosetdma

	bsr.w	wait_dma

	or.w	#$8000,d6
	move.w	d6,$dff096

nosetdma:
	move.l	moddigi,a5
	lea	channel1,a6
	bsr.w	mixchan

	tst.w	pausevbl
	beq.s	nopause
	move.b	#1,pauseen
	subq.w	#1,pausevbl
nopause:

	move.b	count(pc),d7
	cmp.b	temp(pc),d7
	blt.s	no_new
	clr.b	count

	tst.w	pausevbl
	bne.s	dopause
	addq.b	#1,pattpos
	clr.b	pauseen
dopause
no_new
	addq.b	#1,count
	rts

playvoice:
	clr.b	eqnewsama(a6)
	clr.b	eqnewsamb(a6)

	tst.w	mainperiod(a6)
	beq.w	playok

	tst.b	offenable(a6)
	beq.s	nooffchan
	clr.b	offenable(a6)

	tst.w	oldd0(a6)
	beq.s	nodata1
	tst.w	oldd4(a6)
	bne.s	offchan
nodata1
	tst.b	playpointer(a6)
	beq.s	offchan
	move.w	oldd2(a6),d1
	lsr.w	#8,d1
	cmp.b	#3,d1
	beq.s	nooffchan
	cmp.b	#5,d1
	beq.s	nooffchan
	move.w	oldd6(a6),d1
	lsr.w	#8,d1
	cmp.b	#3,d1
	beq.s	nooffchan
	cmp.b	#5,d1
	beq.s	nooffchan
offchan
	moveq	#0,d0
	bset	d5,d0
	move.w	d0,$dff096
	bset	d5,d6
nooffchan
	cmp.w	#-1,mainperiod(a6)
	beq.b	stopchan

	cmp.b	#1,mbrpointer(a6)
	beq.s	noplaymixbuff
	move.l	buffbegadr(a6),(a5)
	move.w	buffsize,d7
	lsr.w	#1,d7
	move.w	d7,4(a5)
	move.w	mainperiod(a6),6(a5)
	moveq	#0,d7
	move.b	mainvol(a6),d7
	move.w	d7,8(a5)
	cmp.b	#2,mbrpointer(a6)
	beq.s	playok
	move.b	#1,playpointer(a6)
	bra.s	playok
noplaymixbuff
	move.l	buffmixadr(a6),(a5)
	move.w	oldd3(a6),d3
	lsr.w	#1,d3
	move.w	d3,4(a5)
	move.w	mainperiod(a6),6(a5)
	moveq	#0,d7
	move.b	mainvol(a6),d7
	move.w	d7,8(a5)
	bra.s	playok
stopchan
	moveq	#0,d0
	bset	d5,d0
	bclr	d5,d6
	move.w	d0,$dff096
	move.b	#1,playpointer(a6)
	clr.w	mainperiod(a6)
playok	rts


wait_dma:
	move.w	wdma,d0
wait_loop1:
	move.b	$dff006,d1
wait_loop2:
	cmp.b	$dff006,d1
	beq.s	wait_loop2
	dbf	d0,wait_loop1
	rts

mixchan:
*-------------------- channel 1a,1b mix ---------------------------
	lea	sample_pos1,a2	; sample positions
	move.w	oldd0(a6),d0
	move.w	oldd1(a6),d1
	move.w	oldd2(a6),d2
	move.w	oldd3(a6),d3
	move.w	oldd4(a6),d4
	move.w	oldd5(a6),d5
	move.w	oldd6(a6),d6

	tst.w	what
	bne.s	ok1
	move.l	sample_buff1_mix,buffmixadr(a6)
ok1:
	cmp.w	#1,what
	bne.s	ok2
	move.l	sample_buff1_mix,buffmixadr(a6)
	add.l	#2500,buffmixadr(a6)
ok2:
	cmp.w	#2,what
	bne.s	ok3
	move.l	sample_buff1_mix,buffmixadr(a6)
	add.l	#5000,buffmixadr(a6)
ok3:
	bsr.w	mainproc
	move.w	d0,oldd0(a6)
	move.w	d1,oldd1(a6)
	move.w	d2,oldd2(a6)
	move.w	d3,oldd3(a6)
	move.w	d4,oldd4(a6)
	move.w	d5,oldd5(a6)
	move.w	d6,oldd6(a6)

*-------------------- channel 2a,2b mix ---------------------------
	lea	chanarea(a6),a6
	lea	sample_pos2,a2	; sample positions
	move.w	oldd0(a6),d0
	move.w	oldd1(a6),d1
	move.w	oldd2(a6),d2
	move.w	oldd3(a6),d3
	move.w	oldd4(a6),d4
	move.w	oldd5(a6),d5
	move.w	oldd6(a6),d6
	lea	8(a1),a1

	tst.w	what
	bne.s	ok1_2
	move.l	sample_buff2_mix,buffmixadr(a6)
ok1_2:
	cmp.w	#1,what
	bne.s	ok2_2
	move.l	sample_buff2_mix,buffmixadr(a6)
	add.l	#2500,buffmixadr(a6)
ok2_2:
	cmp.w	#2,what
	bne.s	ok3_2
	move.l	sample_buff2_mix,buffmixadr(a6)
	add.l	#5000,buffmixadr(a6)
ok3_2:
	bsr.w	mainproc
	move.w	d0,oldd0(a6)
	move.w	d1,oldd1(a6)
	move.w	d2,oldd2(a6)
	move.w	d3,oldd3(a6)
	move.w	d4,oldd4(a6)
	move.w	d5,oldd5(a6)
	move.w	d6,oldd6(a6)
*-------------------- channel 3a,3b mix ---------------------------
	lea	chanarea(a6),a6
	lea	sample_pos3,a2	; sample positions
	move.w	oldd0(a6),d0
	move.w	oldd1(a6),d1
	move.w	oldd2(a6),d2
	move.w	oldd3(a6),d3
	move.w	oldd4(a6),d4
	move.w	oldd5(a6),d5
	move.w	oldd6(a6),d6
	lea	8(a1),a1

	tst.w	what
	bne.s	ok1_3
	move.l	sample_buff3_mix,buffmixadr(a6)
ok1_3:
	cmp.w	#1,what
	bne.s	ok2_3
	move.l	sample_buff3_mix,buffmixadr(a6)
	add.l	#2500,buffmixadr(a6)
ok2_3:
	cmp.w	#2,what
	bne.s	ok3_3
	move.l	sample_buff3_mix,buffmixadr(a6)
	add.l	#5000,buffmixadr(a6)
ok3_3:
	bsr.w	mainproc
	move.w	d0,oldd0(a6)
	move.w	d1,oldd1(a6)
	move.w	d2,oldd2(a6)
	move.w	d3,oldd3(a6)
	move.w	d4,oldd4(a6)
	move.w	d5,oldd5(a6)
	move.w	d6,oldd6(a6)
*-------------------- channel 4a,4b mix ---------------------------
	lea	chanarea(a6),a6
	lea	sample_pos4,a2	; sample positions
	move.w	oldd0(a6),d0
	move.w	oldd1(a6),d1
	move.w	oldd2(a6),d2
	move.w	oldd3(a6),d3
	move.w	oldd4(a6),d4
	move.w	oldd5(a6),d5
	move.w	oldd6(a6),d6
	lea	8(a1),a1

	tst.w	what
	bne.s	ok1_4
	move.l	sample_buff4_mix,buffmixadr(a6)
ok1_4:
	cmp.w	#1,what
	bne.s	ok2_4
	move.l	sample_buff4_mix,buffmixadr(a6)
	add.l	#2500,buffmixadr(a6)
ok2_4:
	cmp.w	#2,what
	bne.s	ok3_4
	move.l	sample_buff4_mix,buffmixadr(a6)
	add.l	#5000,buffmixadr(a6)
ok3_4:
	bsr.b	mainproc
	move.w	d0,oldd0(a6)
	move.w	d1,oldd1(a6)
	move.w	d2,oldd2(a6)
	move.w	d3,oldd3(a6)
	move.w	d4,oldd4(a6)
	move.w	d5,oldd5(a6)
	move.w	d6,oldd6(a6)
* ----------------------------------------------------------
	tst.w	what
	bne.s	whatok
	move.w	#3,what
whatok
	subq	#1,what
	rts

; -------------- main procedure ----------------------------
mainproc:
	move.b	oldvola(a6),vola(a6)
	move.b	oldvolb(a6),volb(a6)

	addq.w	#1,notecount(a6)

	tst.b	temp
	beq.w	old_data

	move.b	count(pc),d7
	cmp.b	temp(pc),d7
	blt.w	old_data

	tst.b	pauseen
	bne.w	oldperiod_1
	tst.b	onoffchana(a6)
	bne.w	oldperiod_1

	moveq	#0,d3

	tst.w	(a1)
	beq.w	oldperiod_1

	move.w	2(a1),d7
	and.w	#$0f00,d7
	cmp.w	#$300,d7
	bne.s	noclrgliss_1
	clr.w	glissandodatasa+4(a6)
noclrgliss_1

	clr.w	vibratodatasa(a6)

	move.b	#1,offenable(a6)
	move.b	#1,eqnewsama(a6)
	move.w	(a1),d7

	btst	#12,d7
	beq.s	nohisam1
	move.b	#1,hisam
	bclr	#12,d7
	tst.w	d7
	beq.w	oldperiod_1
nohisam1
	move.w	d7,d0

;					 finetunes
	movem.l	d1-d3/d7/a0/a1,-(sp)
	move.w	2(a1),d7
	lsr.w	#8,d7
	lsr.w	#4,d7
	tst.b	hisam
	beq.s	nohisam111
	add.w	#$10,d7
nohisam111
	tst.w	d7
	bne.s	notakeold1
	moveq	#0,d7
	move.b	oldsamnuma(a6),d7
	lsr.w	#2,d7
	addq	#1,d7
notakeold1
	moveq	#0,d2
	moveq	#0,d3
	move.b	30(a4,d7.w),d2
	subq.b	#1,d2
	ext.w	d2
	beq.s	fintok3

	cmp.w	#7,d2
	bgt.s	notfromtable1
	cmp.w	#-8,d2
	blt.s	notfromtable1

	lea	periods,a1
	moveq	#36,d7
ftulop1	cmp.w	(a1)+,d0
	beq.s	ftufnd1
	dbf	d7,ftulop1
	cmp.w	#74,a1
	bge.s	notfromtable1
ftufnd1	sub.l	#periods,a1
	move.l	a1,d1
	subq.w	#2,d1

	lea	tunnings,a0
	add.w	#8,d2
	mulu	#72,d2
	add.w	d2,a0
	move.w	(a0,d1.w),d0
	bra.s	fintok3
notfromtable1

	tst.w	d2
	bgt.s	fintok1
	mulu	#-1,d2
	moveq	#-1,d3
fintok1	moveq	#0,d1
	move.w	d0,d1
	mulu	d2,d1
	divu	#140,d1
	tst.w	d3
	bne.s	fintok2
	sub.w	d1,d0
	bra.s	fintok3
fintok2	add.w	d1,d0
fintok3	movem.l	(sp)+,d1-d3/d7/a0/a1
	move.w	d0,orgperioda(a6)

	tst.b	mixdon(a6)
	beq.s	cont1

	move.l	(a0,d5.w),d7
	add.l	124(a0,d5.w),d7
	cmp.l	124(a2,d5.w),d7
	bgt.s	cont1

	tst.l	(a3,d5.w)
	bne.s	cont1

	clr.l	124(a2,d5.w)
	moveq	#0,d4
	moveq	#0,d5
	clr.b	mixdon(a6)
cont1:
	bra.s	newperiod_1
oldperiod_1:
	moveq	#-1,d3
newperiod_1:

	moveq	#0,d2

	tst.b	hisam
	bne.s	neweff_1
	tst.w	2(a1)
	beq.b	oldeff_1
neweff_1
	move.w	2(a1),d2
	move.w	d2,d7
	lsr.w	#8,d7
	lsr.w	#4,d7

	tst.b	hisam
	beq.s	nohisam11
	add.w	#$10,d7
	clr.b	hisam
nohisam11

	tst.b	d7
	beq.s	oldeff_1

	cmp.b	#-1,d3
	bne.s	noupvol_1
	move.w	d1,d3
	lsr.w	#2,d3
	move.b	(a4,d3.w),vola(a6)
	and.w	#$0fff,d2
	bra.s	nooldnum_1
noupvol_1:

	move.w	d7,d1
	subq	#1,d1
	lsl.w	#2,d1
	move.w	d2,d7
	and.w	#$0f00,d7
	cmp.w	#$300,d7
	bne.s	newadr_1

	tst.l	(a2,d1.w)
	bne.s	nonewadr_1
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	bra.s	nooldnum_1
newadr_1
	move.l	(a0,d1.w),(a2,d1.w)
nonewadr_1
	move.w	d1,d3
	lsr.w	#2,d3
	move.b	(a4,d3.w),vola(a6)
	and.w	#$0fff,d2
	move.b	d1,oldsamnuma(a6)
	clr.b	backwdenable(a6)
	bra.s	nooldnum_1
oldeff_1:
	tst.w	(a1)
	beq.s	nooldnum_1

	moveq	#0,d1
	move.b	oldsamnuma(a6),d1

	move.w	d2,d7
	and.w	#$0f00,d7
	cmp.w	#$500,d7
	beq.s	yegl_1
	cmp.w	#$300,d7
	bne.s	nogl_1
yegl_1
	tst.l	(a2,d1.w)
	bne.s	nooldnum_1
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	bra.s	nooldnum_1
nogl_1

	move.l	(a0,d1.w),(a2,d1.w)
nooldnum_1


	tst.b	pauseen
	bne.w	oldperiod_2
	tst.b	onoffchanb(a6)
	bne.w	oldperiod_2

	moveq	#0,d3

	tst.w	4(a1)
	beq.w	oldperiod_2

	move.w	6(a1),d7
	and.w	#$0f00,d7
	cmp.w	#$300,d7
	bne.s	noclrgliss_2
	clr.w	glissandodatasb+4(a6)
noclrgliss_2

	clr.w	vibratodatasb(a6)
	add.b	#1,offenable(a6)
	move.b	#1,eqnewsamb(a6)

	move.w	4(a1),d7

	btst	#12,d7
	beq.s	nohisam_2
	move.b	#1,hisam
	bclr	#12,d7
	tst.w	d7
	beq.w	oldperiod_2
nohisam_2:
	move.w	d7,d4

;					 finetunes
	movem.l	d1-d3/d7/a0/a1,-(sp)
	move.w	6(a1),d7
	lsr.w	#8,d7
	lsr.w	#4,d7
	tst.b	hisam
	beq.s	nohisam222
	add.w	#$10,d7
nohisam222
	tst.w	d7
	bne.s	notakeold2
	moveq	#0,d7
	move.b	oldsamnumb(a6),d7
	lsr.w	#2,d7
	addq	#1,d7
notakeold2
	moveq	#0,d2
	moveq	#0,d3
	move.b	30(a4,d7.w),d2
	subq.b	#1,d2
	ext.w	d2
	beq.s	fintok3b

	cmp.w	#7,d2
	bgt.s	notfromtable2
	cmp.w	#-8,d2
	blt.s	notfromtable2

	lea	periods,a1
	moveq	#36,d7
ftulop2	cmp.w	(a1)+,d4
	beq.s	ftufnd2
	dbf	d7,ftulop2
	cmp.w	#74,a1
	bge.s	notfromtable2
ftufnd2	sub.l	#periods,a1
	move.l	a1,d1
	subq.w	#2,d1

	add.w	#8,d2
	lea	tunnings,a0
	mulu	#72,d2
	add.w	d2,a0
	move.w	(a0,d1.w),d4
	bra.s	fintok3b
notfromtable2


	tst.w	d2
	bge.s	fintok1b
	mulu	#-1,d2
	moveq	#-1,d3
fintok1b
	moveq	#0,d1
	move.w	d4,d1
	mulu	d2,d1
	divu	#140,d1
	tst.w	d3
	bne.s	fintok2b
	sub.w	d1,d4
	bra.s	fintok3b
fintok2b
	add.w	d1,d4
fintok3b
	movem.l	(sp)+,d1-d3/d7/a0/a1
	move.w	d4,orgperiodb(a6)

	tst.b	mixdon(a6)
	beq.s	cont2

	move.l	(a0,d1.w),d7
	add.l	124(a0,d1.w),d7
	cmp.l	(a2,d1.w),d7
	bgt.s	cont2

	tst.l	(a3,d1.w)
	bne.s	cont2

	clr.l	(a2,d1.w)
	moveq	#0,d0
	moveq	#0,d1
	clr.b	mixdon(a6)
cont2:
	bra.s	newperiod_2
oldperiod_2:
	moveq	#-1,d3
newperiod_2:

	moveq	#0,d6

	tst.b	hisam
	bne.s	neweff_2
	tst.w	6(a1)
	beq.b	oldeff_2
neweff_2
	move.w	6(a1),d6

	move.w	d6,d7
	lsr.w	#8,d7
	lsr.w	#4,d7

	tst.b	hisam
	beq.s	nohisam22
	add.w	#$10,d7
	clr.b	hisam
nohisam22

	tst.b	d7
	beq.s	oldeff_2

	cmp.b	#-1,d3
	bne.s	noupvol_2
	move.w	d5,d3
	lsr.w	#2,d3
	move.b	(a4,d3.w),volb(a6)
	and.w	#$0fff,d6
	bra.s	nooldnum_2
noupvol_2:
	move.w	d7,d5
	subq	#1,d5
	lsl.w	#2,d5

	move.w	d6,d7
	and.w	#$0f00,d7
	cmp.w	#$300,d7
	bne.s	newadr_2

	tst.l	124(a2,d5.w)		; adres sampla
	bne.s	nonewadr_2
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
	bra.s	nooldnum_2
newadr_2
	move.l	(a0,d5.w),124(a2,d5.w)	; adres sampla
nonewadr_2
	move.w	d5,d3
	lsr.w	#2,d3
	move.b	(a4,d3.w),volb(a6)
	and.w	#$0fff,d6
	move.b	d5,oldsamnumb(a6)
	clr.b	backwdenable(a6)
	bra.s	nooldnum_2
oldeff_2:
	tst.w	4(a1)
	beq.s	nooldnum_2

	moveq	#0,d5
	move.b	oldsamnumb(a6),d5

	move.w	d6,d7
	and.w	#$0f00,d7
	cmp.w	#$500,d7
	beq.s	yegl_2
	cmp.w	#$300,d7
	bne.s	nogl_2
yegl_2
	tst.l	124(a2,d5.w)
	bne.s	nooldnum_2
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
	bra.s	nooldnum_2
nogl_2
	move.l	(a0,d5.w),124(a2,d5.w)
nooldnum_2

	tst.l	(a0,d5.w)
	bne.s	nozerosam2
	moveq	#0,d4
	moveq	#0,d5
nozerosam2
	tst.l	(a0,d1.w)
	bne.s	nozerosam1
	moveq	#0,d0
	moveq	#0,d1
nozerosam1


	move.l	a5,-(sp)
	bsr.w	effectcommandsa2
	bsr.w	effectcommandsb2
	move.l	(sp)+,a5

	tst.b	onoffchana(a6)
	bne.s	stop1
	cmp.w	#$0e40,d2
	bne.s	no_stop1
	move.l	buffbegadr(a6),(a6)
	move.b	#1,offenable(a6)
stop1	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
no_stop1
	tst.b	onoffchanb(a6)
	bne.s	stop2
	cmp.w	#$0e40,d6
	bne.s	no_stop2
	move.l	buffbegadr(a6),(a6)
	move.b	#1,offenable(a6)
stop2	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
no_stop2

old_data:

	move.b	temp(pc),d7
	subq	#1,d7
	cmp.b	count(pc),d7
	bne.s	no_clreff
	move.w	d2,d7
	lsr.w	#8,d7
	cmp.b	#8,d7
	beq.s	no_clreff1
	cmp.b	#3,d7
	beq.s	no_clreff1
	cmp.b	#4,d7
	beq.s	no_clreff1
	cmp.b	#5,d7
	beq.s	clreffsp1
	tst.b	d7
	beq.s	no_clreff1

	move.w	d2,d7
	lsr.w	#4,d7
	cmp.w	#$ec,d7
	beq.s	no_clreff1
	cmp.w	#$e9,d7
	beq.s	no_clreff1
	moveq	#0,d2
	bra.s	no_clreff1
clreffsp1:
	move.w	#$0300,d2
no_clreff1
	move.w	d6,d7
	lsr.w	#8,d7
	cmp.b	#3,d7
	beq.s	no_clreff2
	cmp.b	#4,d7
	beq.s	no_clreff2
	cmp.b	#5,d7
	beq.s	clreffsp2
	tst.b	d7
	beq.s	no_clreff2

	move.w	d6,d7
	lsr.w	#4,d7
	cmp.w	#$ec,d7
	beq.s	no_clreff2
	cmp.w	#$e9,d7
	beq.s	no_clreff2

	moveq	#0,d6
	bra.s	no_clreff2
clreffsp2:
	move.w	#$0300,d6
no_clreff2

no_clreff

	bsr.w	testperiod
	move.l	a5,-(sp)
	bsr.w	effectcommandsa
	bsr.w	effectcommandsb
	move.l	(sp)+,a5
	bsr.w	testperiod

	move.w	d0,glissandodatasa+2(a6)
	move.w	d4,glissandodatasb+2(a6)

; -----------------------------------
	movem.l	d0-a6,-(sp)
	move.b	vola(a6),oldvola(a6)
	move.b	volb(a6),oldvolb(a6)
	move.w	mainvolvalue,d0
	mulu	confvolboost,d0
	divu	#100,d0
	moveq	#0,d1
	move.b	vola(a6),d1
	mulu	d0,d1
	lsr.w	#6,d1
	move.b	d1,vola(a6)
	moveq	#0,d1
	move.b	volb(a6),d1
	mulu	d0,d1
	lsr.w	#6,d1
	move.b	d1,volb(a6)
	movem.l	(sp)+,d0-a6

	tst.w	d0
	bne.s	noreplace1
	tst.w	d4
	beq.s	noreplace1
	move.l	124(a2,d5.w),(a2,d5.w)
	clr.l	124(a2,d5.w)
	move.w	d4,d0
	move.w	d5,d1
	move.w	d6,d2
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
	move.b	#1,replaceenable(a6)
	move.b	vola(a6),d3
	move.b	volb(a6),vola(a6)
	move.b	d3,volb(a6)
noreplace1

	tst.w	d4
	bne.w	mixing

	clr.b	mbrpointer(a6)

	tst.w	d0
	beq.w	nothing

	move.w	d0,mainperiod(a6)
	move.b	vola(a6),mainvol(a6)

	tst.b	offenable(a6)
	beq.s	noatstartbuff
	tst.b	playpointer(a6)
	beq.s	buffatstart
	move.w	d2,d7
	lsr.w	#8,d7
	cmp.b	#3,d7
	beq.s	noatstartbuff
	cmp.b	#5,d7
	beq.s	noatstartbuff
buffatstart
	move.l	buffbegadr(a6),(a6)
noatstartbuff

	bsr.w	calc
; - - - - - - - - - - - - - - -  backwd play - - - - - - - - - - - - - - -
	tst.b	backwdenable(a6)
	bne.s	bckok

	move.w	d2,d7
	lsr.w	#4,d7
	cmp.w	#$e3,d7
	bne.w	no_backwd
	move.l	124(a0,d1.w),d7
	add.l	d7,(a2,d1.w)
	move.b	#1,backwdenable(a6)

	move.b	d2,d7
	and.b	#$0f,d7
	beq.s	bckok
	move.b	#2,backwdenable(a6)
bckok
	move.b	#1,mbrpointer(a6)
	movem.l	d0-d1/a4-a5,-(sp)

	move.l	(a0,d1.w),d0
	move.w	d3,d7
	subq	#1,d7
	move.l	(a2,d1.w),a5
	move.l	buffmixadr(a6),a4

	cmp.b	#1,backwdenable(a6)
	beq.s	copy_loopbck1

copy_loopbck2:
	cmp.l	d0,a5
	ble.s	sampleend_str
	move.b	-(a5),(a4)+
	dbf	d7,copy_loopbck2
	bra.s	bck_done
sampleend_str:
copy_loopbck3:
	move.b	(a5)+,(a4)+
	dbf	d7,copy_loopbck3
	clr.b	backwdenable(a6)
	bra.s	bck_done

copy_loopbck1:
	cmp.l	d0,a5
	bgt.s	notasampleend
	moveq	#0,d0
	clr.b	-1(a4)
clr_loop2:
	move.b	d0,(a4)+
	dbf	d7,clr_loop2
	tst.b	fast
	beq.s	nocopyfromfast
	bsr.w	copyfromfast
nocopyfromfast
	bra.w	realsampleend
notasampleend

	move.b	-(a5),(a4)+
	dbf	d7,copy_loopbck1
bck_done:
	move.l	a5,(a2,d1.w)
	movem.l	(sp)+,d0-d1/a4-a5
	tst.b	fast
	beq.s	nocopyfromfast2
	bsr.w	copyfromfast
nocopyfromfast2
	bra.w	replace2
no_backwd
	move.w	d2,d7
	lsr.w	#8,d7
	cmp.b	#$8,d7
	beq.w	roboteffect

	tst.b	robotenable(a6)
	beq.s	nooffch
	move.b	#1,offenable(a6)
	move.l	buffbegadr(a6),(a6)
nooffch	clr.b	robotenable(a6)
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	addq	#1,d3

	tst.l	124(a3,d1.w)
	bne.w	sampleloop

	movem.l	d0-d1/a4-a5,-(sp)

	move.l	124(a0,d1.w),d0
	add.l	(a0,d1.w),d0
	move.l	(a2,d1.w),a5
	cmp.l	d0,a5
	blt.s	notsamend0
	move.w	#-1,mainperiod(a6)
	bra.w	realsampleend
notsamend0

	move.l	(a6),d7
	move.l	(a6),d1
	add.l	d3,d1
	cmp.l	buffendadr(a6),d1
	ble.s	notendbuff

	move.l	a5,d7
	add.l	d3,d7
	cmp.l	d0,d7
	ble.s	notsamend2
	move.w	#-1,mainperiod(a6)
	bra.w	realsampleend
notsamend2
	sub.l	buffendadr(a6),d1
	move.w	d3,d7
	sub.w	d1,d7
	subq.w	#1,d7
	move.l	(a6),a4
	bsr.b	copy_loop

	move.l	buffbegadr(a6),(a6)
	move.l	(a6),a4

	move.w	d1,d7
	subq.w	#1,d7
	bsr.b	copy_loop
	bra.s	copydone
notendbuff

	move.l	(a6),a4

	move.l	a5,d7
	add.l	d3,d7
	cmp.l	d0,d7
	ble.s	notsamend1
	sub.l	d0,d7
	move.w	d7,d0
	move.w	d3,d7
	sub.w	d0,d7
	subq.w	#1,d7
	bsr.b	copy_loop

	move.w	d0,d7
	beq.s	nosubq1
	subq.w	#1,d7
nosubq1
	bra.w	sampleend
notsamend1
	move.w	d3,d7
	subq	#1,d7
	bsr.b	copy_loop
copydone:
	move.l	a4,(a6)
	movem.l	(sp)+,d0-d1/a4-a5
	add.l	d3,(a2,d1.w)

replace2:
	move.w	d3,maindtalen(a6)
replace_r:
	tst.b	replaceenable(a6)
	beq.s	noreplace2
	move.l	(a2,d1.w),124(a2,d1.w)
	clr.l	(a2,d1.w)
	move.w	d0,d4
	move.w	d1,d5
	move.w	d2,d6
	clr.b	replaceenable(a6)
	move.b	vola(a6),d0
	move.b	volb(a6),vola(a6)
	move.b	d0,volb(a6)
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
noreplace2
	rts

copy_loopm:
	tst.w	d7
	blt.s	copy_loopex
	bra.s	copy_loopm2
copy_loop:
	tst.w	d7
	blt.s	copy_loopex
	tst.b	confmix
	bne.s	copy_loop2
copy_loopm2:
	tst.b	oldcpu
	bne.s	copy_loopl68000
	movem.l	d7/a4-a5,-(sp)
	lsr.w	#2,d7
copy_loopl
	move.l	(a5)+,(a4)+
	dbf	d7,copy_loopl
	movem.l	(sp)+,d7/a4-a5
	addq	#1,d7
	add.w	d7,a5
	add.w	d7,a4
	rts
copy_loopl68000
	move.b	(a5)+,(a4)+
	dbf	d7,copy_loopl68000
copy_loopex
	rts

copy_loop2:
	movem.l	d0/a3,-(sp)
	moveq	#0,d0
	move.b	vola(a6),d0
	lsl.w	#8,d0
	add.l	voltabptr,d0
	move.b	#$40,mainvol(a6)
copy_loopl2
	move.b	(a5)+,d0
	move.l	d0,a3
	move.b	(a3),(a4)+
	dbf	d7,copy_loopl2
	movem.l	(sp)+,d0/a3
	rts


nothing:
	tst.w	mainperiod(a6)
	beq.s	nostopperiod
	move.w	#-1,mainperiod(a6)
nostopperiod
	rts

sampleend:
	moveq	#0,d0
	clr.b	-1(a4)
clr_loop:
	move.b	d0,(a4)+
	dbf	d7,clr_loop
realsampleend:
	movem.l	(sp)+,d0-d1/a4-a5
	clr.l	(a2,d1.w)
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	clr.b	replaceenable(a6)
	clr.b	backwdenable(a6)
	rts

sampleloop:
	movem.l	d0-d4/a4-a5,-(sp)

	move.l	(a2,d1.w),a5
	move.l	124(a3,d1.w),d4
	add.l	(a3,d1.w),d4
	add.l	(a0,d1.w),d4

	cmp.l	d4,a5
	ble.s	notsamendl
	move.l	d4,(a2,d1.w)
	subq.l	#1,(a2,d1.w)
	move.l	d4,a5
	subq.l	#1,a5
notsamendl

	move.l	(a6),d7
	move.l	(a6),d2
	add.l	d3,d2
	cmp.l	buffendadr(a6),d2
	ble.w	notendbuff_l

	move.l	(a6),a4
	move.l	a5,d7
	add.l	d3,d7
	cmp.l	d4,d7
	ble.w	nomakeloop_eb

	sub.l	d4,d7			; loop
	move.w	d7,d4
	move.w	d3,d7
	sub.w	d4,d7

	sub.l	buffendadr(a6),d2
	move.w	d3,d0
	sub.w	d2,d0

	cmp.w	d0,d7
	bge.s	copy_toendbuff
; d0=>d7 koniec buff pozniej niz petla

	move.l	buffendadr(a6),d2

	move.w	d3,d7
	subq	#1,d7
	move.l	124(a3,d1.w),d4
	add.l	(a3,d1.w),d4
	add.l	(a0,d1.w),d4

	move.l	(a3,d1.w),d0
	add.l	(a0,d1.w),d0
	tst.b	confmix
	bne.s	copy_loop3ebmh
	bra.s	copy_loop3ebml2
copy_loop4ebml2:
	move.l	d0,a5
copy_loop3ebml2:
	cmp.l	d4,a5
	bge.s	copy_loop4ebml2

	cmp.l	d2,a4
	blt.s	ebmlcont
	move.l	buffbegadr(a6),(a6)
	move.l	(a6),a4
ebmlcont
	move.b	(a5)+,(a4)+
	dbf	d7,copy_loop3ebml2
	bra.w	makeloopeb_done

***********************************
copy_loop3ebmh:
	movem.l	d1/a3,-(sp)
	moveq	#0,d1
	move.b	vola(a6),d1
	lsl.w	#8,d1
	add.l	voltabptr,d1
	move.b	#$40,mainvol(a6)
	bra.s	copy_loop3ebmlh2
copy_loop4ebmlh2:
	move.l	d0,a5
copy_loop3ebmlh2:
	cmp.l	d4,a5
	bge.s	copy_loop4ebmlh2
	cmp.l	d2,a4
	blt.s	ebmlhcont
	move.l	buffbegadr(a6),(a6)
	move.l	(a6),a4
ebmlhcont
	move.b	(a5)+,d1
	move.l	d1,a3
	move.b	(a3),(a4)+
	dbf	d7,copy_loop3ebmlh2
	movem.l	(sp)+,d1/a3
	bra.s	makeloopeb_done
***********************************


copy_toendbuff
	exg	d0,d7
	sub.w	d7,d0
	subq	#1,d7
	bsr.w	copy_loop
	move.l	buffbegadr(a6),(a6)
	move.l	(a6),a4
	exg	d0,d7
	subq	#1,d7
	bsr.w	copy_loop

	move.w	d4,d7
	subq.w	#1,d7
	move.l	124(a3,d1.w),d4
	add.l	(a3,d1.w),d4
	add.l	(a0,d1.w),d4

	move.l	(a3,d1.w),d0
	add.l	(a0,d1.w),d0

	tst.b	confmix
	bne.s	copy_loop4ebmlhm

copy_loop4ebml:
	move.l	d0,a5
copy_loop3ebml:
	cmp.l	d4,a5
	bge.s	copy_loop4ebml
	move.b	(a5)+,(a4)+
	dbf	d7,copy_loop3ebml
	bra.s	makeloopeb_done

***********************************
copy_loop4ebmlhm:
	movem.l	d1/a3,-(sp)
	moveq	#0,d1
	move.b	vola(a6),d1
	lsl.w	#8,d1
	add.l	voltabptr,d1
	move.b	#$40,mainvol(a6)
copy_loop4ebmlh:
	move.l	d0,a5
copy_loop3ebmlh:
	cmp.l	d4,a5
	bge.s	copy_loop4ebmlh
	move.b	(a5)+,d1
	move.l	d1,a3
	move.b	(a3),(a4)+
	dbf	d7,copy_loop3ebmlh
	movem.l	(sp)+,d1/a3
***********************************

makeloopeb_done
	move.l	a4,(a6)
	move.l	a5,(a2,d1.w)
	movem.l	(sp)+,d0-d4/a4-a5
	bsr.w	replace2
	rts

nomakeloop_eb
	sub.l	buffendadr(a6),d2
	move.w	d3,d7
	sub.w	d2,d7
	subq.w	#1,d7
	bsr.w	copy_loop

	move.l	buffbegadr(a6),(a6)
	move.l	(a6),a4

	move.w	d2,d7
	subq.w	#1,d7
	bsr.w	copy_loop

	move.l	a4,(a6)
	move.l	a5,(a2,d1.w)
	movem.l	(sp)+,d0-d4/a4-a5
	bsr.w	replace2
	rts

notendbuff_l
	move.l	(a6),a4
	move.l	a5,d7
	add.l	d3,d7

	cmp.l	d4,d7
	ble.s	nomakeloop

	sub.l	d4,d7
	move.w	d7,d4
	move.w	d3,d7
	sub.w	d4,d7
	subq.w	#1,d7
	bsr.w	copy_loop

	move.w	d4,d7
	subq.w	#1,d7

	move.l	124(a3,d1.w),d4
	add.l	(a3,d1.w),d4
	add.l	(a0,d1.w),d4

	move.l	(a3,d1.w),d0
	add.l	(a0,d1.w),d0
	tst.b	confmix
	bne.s	copy_loop4hm
copy_loop4:
	move.l	d0,a5
copy_loop3:
	cmp.l	d4,a5
	bge.s	copy_loop4
	move.b	(a5)+,(a4)+
	dbf	d7,copy_loop3
	bra.s	copy_loophdone
***********************************
copy_loop4hm:
	movem.l	d1/a3,-(sp)
	moveq	#0,d1
	move.b	vola(a6),d1
	lsl.w	#8,d1
	add.l	voltabptr,d1
	move.b	#$40,mainvol(a6)
copy_loop4h:
	move.l	d0,a5
copy_loop3h:
	cmp.l	d4,a5
	bge.s	copy_loop4h
	move.b	(a5)+,d1
	move.l	d1,a3
	move.b	(a3),(a4)+
	dbf	d7,copy_loop3h
	movem.l	(sp)+,d1/a3
***********************************

copy_loophdone:
	move.l	a4,(a6)
	move.l	a5,(a2,d1.w)
	movem.l	(sp)+,d0-d4/a4-a5
	bsr.w	replace2
	rts

nomakeloop
	move.w	d3,d7
	subq	#1,d7
	bsr.w	copy_loop
	move.l	a4,(a6)
	move.l	a5,(a2,d1.w)
	movem.l	(sp)+,d0-d4/a4-a5
	bsr.w	replace2
	rts

testperiod:
	cmp.w	#113,d0
	bge.s	okki1
	tst.w	d0
	beq.s	okki1
	moveq	#113,d0
okki1	cmp.w	#113,d4
	bge.s	okki2
	tst.w	d4
	beq.s	okki2
	moveq	#113,d4
okki2	tst.w	d0
	bne.s	okki3
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
okki3	tst.w	d4
	bne.s	okki4
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
okki4	rts
; --------------------------- effectcommands ---------------------------

effectcommandsa2:
; effects 9xx, bxx, cxx, dxx, fxx chan a

	move.w	d2,d7
	beq.w	effcoma2exit
	lsr.w	#8,d7
	clr.b	channelenable
	move.w	d2,d3

	lea	samoffseta(a6),a5
	cmp.b	#9,d7
	beq.w	sampleoffset

	cmp.b	#$b,d7
	beq.w	songrepeat

	lea	vola(a6),a5
	cmp.b	#$c,d7
	beq.w	setvolume

	lea	hex(pc),a5
	cmp.b	#$d,d7
	beq.w	pattbreak

	cmp.b	#$f,d7
	beq.w	settempo

; effects e0x, e1x, e2x, e6x, e8x, eax, ebx eex chan a

	cmp.w	#$e00,d3
	beq.w	offfilter

	cmp.w	#$e01,d3
	beq.w	onfilter

	cmp.w	#$e50,d3
	beq.w	offchannela

	cmp.w	#$e51,d3
	beq.w	onchannela

	move.w	d2,d7
	lsr.w	#4,d7
	move.w	d2,d3

	cmp.b	#$e1,d7
	beq.w	fineslideup

	cmp.b	#$e2,d7
	beq.w	fineslidedown

	lea	loopsdataschana(a6),a5
	cmp.b	#$e6,d7
	beq.w	loops

	lea	samoffseta(a6),a5
	cmp.b	#$e8,d7
	beq.w	offsets

	lea	vola(a6),a5
	cmp.b	#$ea,d7
	beq.w	finevolup

	cmp.b	#$eb,d7
	beq.w	finevoldown

	cmp.b	#$ee,d7
	beq.w	pause
effcoma2exit
	rts

effectcommandsb2:
; effects 9xx, bxx, cxx, dxx, fxx chan b

	move.w	d6,d7
	beq.w	effcomb2exit
	lsr.w	#8,d7
	move.b	#1,channelenable
	move.w	d6,d3

	lea	samoffsetb(a6),a5
	cmp.b	#9,d7
	beq.w	sampleoffset

	cmp.b	#$b,d7
	beq.w	songrepeat

	lea	volb(a6),a5
	cmp.b	#$c,d7
	beq.w	setvolume

	lea	hex(pc),a5
	cmp.b	#$d,d7
	beq.w	pattbreak

	cmp.b	#$f,d7
	beq.w	settempo

; effects e0x, e1x, e2x, e6x, e8x, eax, ebx eex chan b

	cmp.w	#$e00,d3
	beq.w	offfilter

	cmp.w	#$e01,d3
	beq.w	onfilter

	cmp.w	#$e50,d3
	beq.w	offchannelb

	cmp.w	#$e51,d3
	beq.w	onchannelb

	move.w	d6,d7
	lsr.w	#4,d7
	move.w	d6,d3

	cmp.b	#$e1,d7
	beq.w	fineslideup

	cmp.b	#$e2,d7
	beq.w	fineslidedown

	lea	loopsdataschanb(a6),a5
	cmp.b	#$e6,d7
	beq.w	loops

	lea	samoffsetb(a6),a5
	cmp.b	#$e8,d7
	beq.w	offsets

	lea	volb(a6),a5
	cmp.b	#$ea,d7
	beq.w	finevolup

	cmp.b	#$eb,d7
	beq.w	finevoldown

	cmp.b	#$ee,d7
	beq.w	pause
effcomb2exit
	rts




effectcommandsa:
; effects 0xx 1xx, 2xx, 3xx, 4xx, 5xx, 6xx, axx, chan a
	move.w	d2,d7
	beq.b	effcomaexit
	lsr.w	#8,d7
	clr.b	channelenable
	move.w	d2,d3

	lea	orgperioda(a6),a5
	tst.b	d7
	beq.w	arpeggio

	cmp.b	#1,d7
	beq.w	portup

	cmp.b	#2,d7
	beq.w	portdown

	lea	glissandodatasa(a6),a5
	cmp.b	#3,d7
	beq.w	glissando

	lea	vibratodatasa(a6),a5
	cmp.b	#4,d7
	beq.w	vibrato

	cmp.b	#5,d7
	beq.w	slidevolgliss

	cmp.b	#6,d7
	beq.w	slidevolvib

	lea	vola(a6),a5
	cmp.b	#$a,d7
	beq.w	slidevolume

; effects e9x, ecx chan a

	move.w	d2,d7
	lsr.w	#4,d7
	move.w	d2,d3

	lea	retracecnta(a6),a5
	cmp.b	#$e9,d7
	beq.w	retrace

	lea	vola(a6),a5
	cmp.b	#$ec,d7
	beq.w	cutsample
effcomaexit
	rts


effectcommandsb:
; effects 1xx, 2xx, 3xx, 4xx, 5xx, 6xx, axx, chan b
	move.w	d6,d7
	beq.b	effcombexit
	lsr.w	#8,d7
	move.b	#1,channelenable
	move.w	d6,d3

	lea	orgperiodb(a6),a5
	tst.b	d7
	beq.w	arpeggio

	cmp.b	#1,d7
	beq.w	portup

	cmp.b	#2,d7
	beq.w	portdown

	lea	glissandodatasb(a6),a5
	cmp.b	#3,d7
	beq.w	glissando

	lea	vibratodatasb(a6),a5
	cmp.b	#4,d7
	beq.w	vibrato

	cmp.b	#5,d7
	beq.w	slidevolgliss

	cmp.b	#6,d7
	beq.w	slidevolvib

	lea	volb(a6),a5
	cmp.b	#$a,d7
	beq.w	slidevolume

; effects e9x, ecx chan b

	move.w	d6,d7
	lsr.w	#4,d7
	move.w	d6,d3

	lea	retracecntb(a6),a5
	cmp.b	#$e9,d7
	beq.w	retrace

	lea	volb(a6),a5
	cmp.b	#$ec,d7
	beq.w	cutsample
effcombexit
	rts

;------------------------------ effects -------------------------------------

;looppattpos	(a5)
;loopsongpos	1(a5)
;loophowmany	2(a5)

loops:
	cmp.w	#$e60,d3
	bne.s	no_loop
	tst.b	2(a5)
	bne.s	loops_done
	move.b	pattpos(pc),(a5)
	subq.b	#1,(a5)
	move.b	songpos(pc),1(a5)
	bra.s	loops_done
no_loop
	tst.b	2(a5)
	beq.s	storehowmany
	subq.b	#1,2(a5)
	bne.s	no_done
	clr.b	(a5)
	clr.b	1(a5)
	clr.b	2(a5)
	bra.s	loops_done
no_done
	move.b	(a5),pattpos
	move.b	1(a5),songpos
	bra.s	loops_done
storehowmany
	and.b	#$0f,d3
	move.b	d3,2(a5)
	move.b	(a5),pattpos
	move.b	1(a5),songpos
loops_done
	rts

pause:
	tst.b	pauseen
	bne.s	no_pause

	moveq	#0,d7
	move.b	d3,d7
	and.b	#$0f,d7
	beq.s	no_pause
	moveq	#0,d3
	move.b	temp(pc),d3
	mulu	d3,d7
	addq.w	#1,d7
	move.w	d7,pausevbl
no_pause
	rts

songrepeat:
	move.b	#-1,pattpos
	moveq	#0,d7
	move.b	d3,d7
	cmp.w	#$7f,d7
	blt.s	songrep_ok
	move.b	#$7f,d7
songrep_ok
	move.b	d7,songpos
	rts

pattbreak:
	moveq	#0,d7
	move.b	d3,d7
	cmp.w	#$63,d7
	blt.s	patt_ok
	move.b	#$63,d7
patt_ok
	cmp.b	#-1,pattpos
	beq.s	noaddsp
	addq.b	#1,songpos
noaddsp
	move.b	(a5,d7.w),d7
	move.b	d7,pattpos
	subq.b	#1,pattpos
	rts

sampleoffset:
	moveq	#0,d7
	move.b	(a5),d7
	lsl.w	#8,d7
	lsl.l	#8,d7
	and.w	#$00ff,d3
	lsl.w	#8,d3
	add.w	d3,d7
	tst.b	channelenable
	bne.s	samoffschanb
	add.l	d7,(a2,d1.w)
	rts
samoffschanb
	add.l	d7,124(a2,d5.w)
	rts


offsets:
	move.b	d3,d7
	and.b	#$0f,d7
	move.b	d7,(a5)
	rts

settempo:
	moveq	#0,d7
	move.b	d3,d7
	cmp.w	#$1f,d7
	bgt.s	cia_temp
	move.b	d3,temp
	move.b	d3,count
	rts
cia_temp
	tst.l	ciabase
	beq.s	nocia_temp
	move.w	d7,ciatempo
	move.w	#1,ciachanged
nocia_temp
	rts

offchannela:
	bset	#0,onoffchana(a6)
	rts
onchannela:
	bclr	#0,onoffchana(a6)
	rts
offchannelb:
	bset	#0,onoffchanb(a6)
	rts
onchannelb:
	bclr	#0,onoffchanb(a6)
	rts

offfilter:
	bclr	#1,$bfe001
	rts
onfilter:
	bset	#1,$bfe001
	rts



retrace:
	cmp.b	#1,count
	bne.s	retrno_2
	clr.b	(a5)
retrno_2
	moveq	#0,d7
	move.b	d3,d7
	and.b	#$0f,d7
	subq.b	#1,d7
	cmp.b	(a5),d7
	bne.s	retrno_1

	tst.b	channelenable
	beq.s	retr_chan_a
	move.l	(a0,d5.w),124(a2,d5.w)	; adres sampla
	move.b	#1,offenable(a6)
	bra.s	retr_chan_b
retr_chan_a
	move.b	#1,offenable(a6)
	move.l	(a0,d1.w),(a2,d1.w)	; adres sampla
retr_chan_b
	clr.b	(a5)
	rts
retrno_1
	addq.b	#1,(a5)
no_retrace_1
	rts

cutsample:
	moveq	#0,d7
	move.b	d3,d7
	and.b	#$0f,d7
	cmp.b	count(pc),d7
	bne.s	no_cut_sam
	clr.b	(a5)
no_cut_sam:
	rts

; ------------- arpeggio -------------
arplist:
	dc.b 0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1
arpeggio:
	movem.l	d2/a6,-(sp)
	bsr.b	arpeggiomain
	movem.l	(sp)+,d2/a6
	rts

arpeggiomain:
	moveq	#0,d7
	move.b	count(pc),d7
	subq.b	#1,d7

	move.b	arplist(pc,d7.w),d7
	beq.s	arp0
	cmp.b	#2,d7
	beq.s	arp2

arp1:	moveq	#0,d2
	move.b	d3,d2
	lsr.b	#4,d2
	bra.s	arpdo

arp2:	moveq	#0,d2
	move.b	d3,d2
	and.b	#$f,d2
arpdo:
	asl.w	#1,d2
	move.w	(a5),d7
	lea	periods(pc),a6
	moveq	#36,d3
arp3:	cmp.w	(a6)+,d7
	bge.s	arpfound
	dbf	d3,arp3
arp0:
	tst.b	channelenable
	bne.s	arp_chanb1
	move.w	(a5),d0
	rts
arp_chanb1
	move.w	(a5),d4
	rts
arpfound:
	add.w	d2,a6
	cmp.l	#periodsend,a6
	ble.s	arpok1
	move.l	#periodsend,a6
	moveq	#0,d2
	bra.s	arpok2
arpok1	sub.w	d2,a6
arpok2	tst.b	channelenable
	bne.s	arp_chanb2
	move.w	-2(a6,d2.w),d0
	rts
arp_chanb2
	move.w	-2(a6,d2.w),d4
	rts

; ------------- portamento up -------------

portup:
	moveq	#0,d7
	move.b	d3,d7

	tst.b	channelenable
	bne.s	portup_chan_b
	
portup_chan_a
	tst.b	d7
	bne.s	nooldportupa
	move.b	portupoldvala(a6),d7
nooldportupa
	move.b	d7,portupoldvala(a6)
	sub.w	d7,d0
	cmp.w	#113,d0
	bge.s	portupoka
	move.w	#113,d0
portupoka
	rts

portup_chan_b
	tst.b	d7
	bne.s	nooldportupb
	move.b	portupoldvalb(a6),d7
nooldportupb
	move.b	d7,portupoldvalb(a6)
	sub.w	d7,d4
	cmp.w	#113,d4
	bge.s	portupokb
	move.w	#113,d4
portupokb
	rts
noportup:
	rts

; ------------- portamento down -------------
portdown:
	moveq	#0,d7
	move.b	d3,d7

	tst.b	channelenable
	bne.s	portdown_chan_b
portdown_chan_a
	tst.b	d7
	bne.s	nooldportdowna
	move.b	portdownoldvala(a6),d7
nooldportdowna
	move.b	d7,portdownoldvala(a6)
	add.w	d7,d0
	cmp.w	#856,d0
	ble.s	portdownoka
	move.w	#856,d0
portdownoka
	rts

portdown_chan_b
	tst.b	d7
	bne.s	nooldportdownb
	move.b	portdownoldvalb(a6),d7
nooldportdownb
	move.b	d7,portdownoldvalb(a6)
	add.w	d7,d4
	cmp.w	#856,d4
	ble.s	portdownokb
	move.w	#856,d4
portdownokb
	rts
noportdown:
	rts

; --------------- set volume  -------------
setvolume:
	move.b	d3,(a5)
	rts

; --------------- slide volume up -------------
slidevolume:
	tst.b	d3
	bne.s	nooldslidevol
	move.b	2(a5),d3	; old slidevolvolue
nooldslidevol
	move.b	d3,2(a5)

	moveq	#0,d7
	move.b	d3,d7
	cmp.w	#$10,d7
	blt.s	voldown
	lsr.b	#4,d7
	add.b	d7,(a5)
	cmp.b	#64,(a5)
	blt.s	voldone
	move.b	#64,(a5)
	rts
voldown
	sub.b	d3,(a5)
	tst.b	(a5)
	bgt.s	voldone
	clr.b	(a5)
voldone:rts


; --------------- fine slide down -------------
fineslidedown:
	move.w	d3,d7
	and.w	#$000f,d7

	tst.b	channelenable
	bne.s	fineslidedownb

	add.w	d7,d0
	cmp.w	#856,d0
	ble.s	fineslidedownoka
	move.w	#856,d0
fineslidedownoka
	moveq	#0,d2
	rts

fineslidedownb
	add.w	d7,d4
	cmp.w	#856,d4
	ble.s	fineslidedownokb
	move.w	#856,d4
fineslidedownokb
	moveq	#0,d6
	rts

; --------------- fine slide up -------------
fineslideup:
	move.w	d3,d7
	and.w	#$000f,d7

	tst.b	channelenable
	bne.s	fineslideupb

	sub.w	d7,d0
	cmp.w	#113,d0
	bge.s	fineslideupoka
	move.w	#113,d0
fineslideupoka
	moveq	#0,d2
	rts

fineslideupb
	sub.w	d7,d4
	cmp.w	#113,d4
	bge.s	fineslideupokb
	move.w	#113,d4
fineslideupokb
	moveq	#0,d6
	rts

; --------------- fine volume up  -------------
finevolup:
	move.w	d3,d7
	and.b	#$0f,d7
	add.b	d7,(a5)
	cmp.b	#64,(a5)
	blt.s	fvuok
	move.b	#64,(a5)
fvuok
	tst.b	channelenable
	bne.s	fvuclrvolb
	moveq	#0,d2
	rts
fvuclrvolb
	moveq	#0,d6
	rts


; --------------- fine volume down  -------------
finevoldown:
	move.w	d3,d7
	and.b	#$0f,d7
	sub.b	d7,(a5)
	tst.b	(a5)
	bge.s	fvdok
	clr.b	(a5)
fvdok
	tst.b	channelenable
	bne.s	fvdclrvolb
	moveq	#0,d2
	rts
fvdclrvolb
	moveq	#0,d6
nofvd	rts


; ------------- glissando -------------

;glissoldvalue:		 (a5)
;glissenable:		1(a5)
;glissoldperiod:	2(a5)
;glissnewperiod:	4(a5)

glissando:
	move.w	d3,d7
	tst.b	d3
	bne.s	nooldgliss
	move.b	(a5),d3
nooldgliss

	cmp.b	#1,count
	bne.s	nostore
	move.b	d3,(a5)
nostore

	tst.w	2(a5)
	beq.w	glissrts

	tst.b	channelenable
	bne.s	glissok1b

glissok1a:
	tst.w	4(a5)
	bne.s	glissok2
	move.w	d0,d7
	move.w	d0,4(a5)
	move.w	2(a5),d0
	clr.b	1(a5)
	cmp.w	d0,d7
	beq.s	clrnp
	bge.w	glissrts
	move.b	#1,1(a5)
	rts

glissok1b:
	tst.w	4(a5)
	bne.s	glissok2
	move.w	d4,d7
	move.w	d4,4(a5)
	move.w	2(a5),d4
	clr.b	1(a5)
	cmp.w	d4,d7
	beq.s	clrnp
	bge.s	glissrts
	move.b	#1,1(a5)
	rts

clrnp:	clr.w	4(a5)
	rts

glissok2:
	move.w	d3,d7
	and.w	#$0ff,d7
	tst.w	4(a5)
	beq.s	glissrts
	tst.b	1(a5)
	bne.s	glisssub
	add.w	d7,2(a5)
	move.w	4(a5),d7
	cmp.w	2(a5),d7
	bgt.s	glissok3
	move.w	4(a5),2(a5)
	clr.w	4(a5)
glissok3:
	tst.b	channelenable
	bne.s	glisschanb
glisschana
	move.w	2(a5),d0
	rts
glisschanb
	move.w	2(a5),d4
	rts

glisssub:
	sub.w	d7,2(a5)
	move.w	4(a5),d7
	cmp.w	2(a5),d7
	blt.s	glissok3
	move.w	4(a5),2(a5)
	clr.w	4(a5)
	bra.s	glissok3

glissrts:
	rts

slidevolgliss:
	and.w	#$00ff,d3
	add.w	#$a00,d3
	tst.b	channelenable
	bne.s	slidechanb
	lea	vola(a6),a5
	bra.s	doslidechan
slidechanb
	lea	volb(a6),a5
doslidechan
	bsr.w	slidevolume

	move.w	#$0300,d3
	tst.b	channelenable
	bne.s	glissbchan
	lea	glissandodatasa(a6),a5
	bra.s	doglisschan
glissbchan
	lea	glissandodatasb(a6),a5
doglisschan
	bra.w	glissando


slidevolvib:
	and.w	#$00ff,d3
	add.w	#$a00,d3
	tst.b	channelenable
	bne.s	slidechanbv
	lea	vola(a6),a5
	bra.s	doslidechanv
slidechanbv
	lea	volb(a6),a5
doslidechanv
	bsr.w	slidevolume

	move.w	#$0400,d3
	tst.b	channelenable
	bne.s	vibbchan
	lea	vibratodatasa(a6),a5
	bra.s	dovibchan
vibbchan
	lea	vibratodatasb(a6),a5
dovibchan
	bra.w	vibrato




;vibperiod	(a5)
;vibvalue	2(a5)
;viboldvalue	3(a5)

vibrato:
	movem.l	d2/d5,-(sp)

	move.w	d4,d2
	tst.b	channelenable
	bne.s	vibchanb1
	move.w	d0,d2
vibchanb1
	bsr.b	vibratomain
	tst.b	channelenable
	bne.s	vibchanb2
	move.w	d2,d0
	bra.s	vibmaindone
vibchanb2
	move.w	d2,d4
vibmaindone
	movem.l	(sp)+,d2/d5
	rts

vibratomain:
	move.b	count(pc),d7
	cmp.b	temp(pc),d7
	bne.s	nonewperiod
	tst.w	(a5)
	bne.s	nonewperiod
	move.w	d2,(a5)
nonewperiod
	move.w	(a5),d2
	move.b	temp(pc),d7
	subq	#1,d7
	cmp.b	count(pc),d7
	bne.s	dovibrato
	clr.w	(a5)
	rts
dovibrato
	move.b	d3,d5
	and.b	#$0f,d5
	bne.s	nonew1
	move.b	3(a5),d5
	and.b	#$0f,d5
	add.b	d5,d3
nonew1
	move.b	d3,d5
	and.b	#$f0,d5
	bne.s	nonew2
	move.b	3(a5),d5
	and.b	#$f0,d5
	add.b	d5,d3
nonew2
	move.w	d3,-(sp)

	move.b	d3,3(a5)

	move.b	d3,d7
	move.b	2(a5),d3
	lsr.w	#2,d3
	and.w	#$1f,d3
	moveq	#0,d5
	move.b	vibsin(pc,d3.w),d5

	move.b	d7,d3
	and.w	#$f,d3
	mulu	d3,d5
	lsr.w	#7,d5

	tst.b	2(a5)
	bmi.s	vibsub
	add.w	d5,d2
	bra.s	vibnext
vibsub:
	sub.w	d5,d2
vibnext:
	move.w	d2,d5
	move.b	d7,d5
	lsr.w	#2,d5
	and.w	#$3c,d5
	add.b	d5,2(a5)
	move.w	(sp)+,d3
	rts
vibsin:
	dc.b	$00,$18,$31,$4a,$61,$78,$8d,$a1,$b4,$c5,$d4,$e0,$eb,$f4,$fa,$fd
	dc.b	$ff,$fd,$fa,$f4,$eb,$e0,$d4,$c5,$b4,$a1,$8d,$78,$61,$4a,$31,$18

calc:	tst.b	oldcpu
	bne.s	oldcpurout
	tst.b	fast
	beq.s	oldcpurout
	move.l	#35795*2*125,d3
	moveq	#0,d7
	move.w	ciatempo,d7
	divu.l	d7,d3
	divu	d0,d3
	and.l	#$ffff,d3
	addq	#1,d3
	rts
oldcpurout
	cmp.w	#70,ciatempo
	ble.s	newrout
	move.l	#35795*125,d3
	divu	ciatempo,d3
	and.l	#$ffff,d3
	divu	d0,d3
	and.l	#$ffff,d3
	add.w	d3,d3
	addq	#2,d3
	rts
newrout:move.l	#35795*125/4,d3
	divu	ciatempo,d3
	and.l	#$ffff,d3
	lsl.l	#2,d3
	divu	d0,d3
	and.l	#$ffff,d3
	add.w	d3,d3
	addq	#2,d3
	rts

mixing:
	move.w	d0,mixperioda
	move.w	d4,mixperiodb

	bsr.w	calc
	movem.l	d0-d6/a0-a4,-(sp)

	move.l	(a2,d1.w),a0

	tst.b	oldcpu
	bne.s	oldcpurout2
	tst.b	fast
	beq.s	oldcpurout2
	move.l	#35795*2*125,d0
	moveq	#0,d7
	move.w	ciatempo,d7
	divu.l	d7,d0
	divu	d4,d0
	and.l	#$ffff,d0
	addq	#1,d0
	bra.s	routdone
oldcpurout2
	cmp.w	#70,ciatempo
	ble.s	newrout2
	move.l	#35795*125,d0
	divu	ciatempo,d0
	and.l	#$ffff,d0
	bra.s	newrout3
newrout2
	move.l	#35795*125/4,d0
	divu	ciatempo,d0
	and.l	#$ffff,d0
	lsl.l	#2,d0
newrout3
	divu	d4,d0
	and.l	#$ffff,d0
	add.w	d0,d0
	addq	#2,d0
routdone:

	move.l	124(a2,d5.w),a1
	move.l	d0,d4
	cmp.w	d3,d4
	ble.b	noreplace

	add.l	d0,124(a2,d5.w)
	exg	d1,d5
	lea	-124(a2),a2

	exg	d3,d4
	exg	d2,d6
	exg	a0,a1
	move.w	d3,leng
	move.b	vola(a6),d7
	move.b	volb(a6),vola(a6)
	move.b	d7,volb(a6)

	bsr.w	mix
	movem.l	(sp)+,d0-d6/a0-a4

	move.w	leng(pc),d3
	exg	d0,d4
	bsr.w	play
	exg	d0,d4
	move.b	vola(a6),d7
	move.b	volb(a6),vola(a6)
	move.b	d7,volb(a6)

	tst.b	changeadr(a6)
	beq.s	nochadr1
	move.l	samrep2(a6),124(a2,d5.w)
nochadr1:
	cmp.b	#1,mixdon(a6)
	beq.s	offsam1
	rts

offsam1:clr.l	(a2,d1.w)
	clr.l	124(a2,d5.w)
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	clr.b	mixdon(a6)
	rts

noreplace
	add.l	d3,(a2,d1.w)
	bsr.w	mix

	movem.l	(sp)+,d0-d6/a0-a4

	bsr.w	play

	tst.b	changeadr(a6)
	beq.s	nochadr2
	move.l	samrep2(a6),(a2,d1.w)
nochadr2:
	cmp.b	#1,mixdon(a6)
	beq.s	offsam1
	rts


; --------------- robot -------------

makebuff_robot:
	move.b	#1,mbrpointer(a6)

	tst.l	124(a3,d1.w)
	bne.b	sampleloop_r

	movem.l	d0-d1/a4-a5,-(sp)
	move.l	buffmixadr(a6),a4
	move.l	124(a0,d1.w),d0
	add.l	(a0,d1.w),d0
	move.w	d3,d7
	subq	#1,d7
	move.l	(a2,d1.w),a5
	cmp.l	d0,a5
	bgt.w	realsampleend
	move.l	a5,d1
copy_loop_r:
	cmp.l	d0,a5
	bgt.w	sampleend
	move.b	(a5)+,(a4)+
	dbf	d7,copy_loop_r
	movem.l	(sp)+,d0-d1/a4-a5
	add.l	d3,(a2,d1.w)
	rts

sampleloop_r:
	movem.l	d0-d4/a4-a5,-(sp)
	move.l	124(a3,d1.w),d4
	add.l	(a3,d1.w),d4
	add.l	(a0,d1.w),d4

	move.w	d3,d7
	subq	#1,d7
	move.l	(a2,d1.w),a5
	move.l	buffmixadr(a6),a4
copy_loop2_r:
	cmp.l	d4,a5
	bge.s	makeloop_r
	move.b	(a5)+,(a4)+
	dbf	d7,copy_loop2_r
	movem.l	(sp)+,d0-d4/a4-a5
	add.l	d3,(a2,d1.w)
	rts

makeloop_r:
	move.l	(a3,d1.w),d0
	add.l	(a0,d1.w),d0
copy_loop4_r:
	move.l	d0,a5
copy_loop3_r:
	cmp.l	d4,a5
	bge.s	copy_loop4_r
	move.b	(a5)+,(a4)+
	dbf	d7,copy_loop3_r
	move.l	a5,(a2,d1.w)
	movem.l	(sp)+,d0-d4/a4-a5
	rts

roboteffect:
	tst.b	robotenable(a6)
	bne.s	noroffch
	move.b	#1,offenable(a6)
noroffch
	move.b	#1,robotenable(a6)
	bsr.w	makebuff_robot

	tst.b	fast
	beq.s	nocopyfromfast3
	bsr.w	copyfromfast
	move.l	(a6),buffmixadr(a6)
	move.b	#1,mbrpointer(a6)
nocopyfromfast3

	move.w	d3,maindtalen(a6)
	bsr.b	robotmain
	bsr.w	replace_r
	rts

robotmain:
	tst.b	d2
	bne.s	nooldrobot
	move.b	robotoldval(a6),d2
nooldrobot
	move.b	d2,robotoldval(a6)

	moveq	#0,d7
	move.b	d2,d7
	add.w	#80,d7

	move.w	d3,d4
	lsr.w	#6,d4
	lsr.w	#2,d7
	mulu	d7,d4

	cmp.w	d4,d3
	ble.s	clrrobot
	sub.w	d4,d3
	addq	#1,d3
	bra.s	norobot
clrrobot:
	moveq	#2,d3
norobot:
	moveq	#0,d4
	rts


play:	move.w	d0,mainperiod(a6)
	move.b	#$40,mainvol(a6)

	cmp.b	#1,offenable(a6)
	bne.b	noset3onen
	cmp.w	maindtalen(a6),d3
	beq.s	noset3onen
	move.b	#1,offenable(a6)
	clr.w	notecount(a6)
	move.l	buffbegadr(a6),(a6)
	bra.s	noset2onen
noset3onen
	cmp.b	#2,offenable(a6)	; jesli jedn. dwa mix sampl. to wait
	bne.b	noset1onen
	move.b	#1,offenable(a6)
	clr.w	notecount(a6)
	move.l	buffbegadr(a6),(a6)
	bra.s	noset2onen
noset1onen
	cmp.b	#1,offenable(a6)
	bne.s	noset4onen
	cmp.w	#100,notecount(a6)
	blt.s	noset4onen
	clr.w	notecount(a6)
	move.l	buffbegadr(a6),(a6)
	bra.s	noset2onen
noset4onen
	clr.b	offenable(a6)
	tst.b	fast
	bne.s	noset2onen
	tst.b	playpointer(a6)
	beq.s	noset2onen
	clr.b	playpointer(a6)
	move.b	#1,offenable(a6)
	clr.w	notecount(a6)
	move.l	buffbegadr(a6),(a6)
noset2onen
	move.w	d3,maindtalen(a6)
	tst.b	fast
	bne.s	copyfromfast
	rts

copyfromfast:
	move.b	#2,mbrpointer(a6)
	movem.l	d0-a6,-(sp)

	move.l	buffmixadr(a6),a5
	move.l	(a6),d1
	and.l	#$ffff,d3
	add.l	d3,d1
	cmp.l	buffendadr(a6),d1
	ble.s	notendbufm
	sub.l	buffendadr(a6),d1
	move.w	d3,d7
	sub.w	d1,d7
	subq.w	#1,d7
	move.l	(a6),a4
	bsr.w	copy_loopm
	move.l	buffbegadr(a6),(a6)
	move.l	(a6),a4
	move.w	d1,d7
	subq.w	#1,d7
	bsr.w	copy_loopm
	bra.s	copydonem
notendbufm
	move.l	(a6),a4
	moveq	#0,d7
	move.w	d3,d7
	subq	#1,d7
	bsr.w	copy_loopm
copydonem
	move.l	a4,(a6)
	movem.l	(sp)+,d0-a6
	rts

db_end:
	bsr.w	unplugcia
	bsr.w	freemixbuffers

	move.w	#$f,$dff096
	clr.w	$dff0a8
	clr.w	$dff0b8
	clr.w	$dff0c8
	clr.w	$dff0d8
	rts

getvol1:macro
	move.b	(a0)+,d1
	move.l	d1,a4
	move.b	(a4),d1
	endm

getvol2:macro
	move.b	(a1)+,d0
	move.l	d0,a5
	move.b	(a5),d0
	endm

mix:
	move.b	#1,mbrpointer(a6)

	movem.l	d5/a2,-(sp)
	lea	sample_starts,a4
	lea	(a3),a5			; smaple repeats

	move.l	buffmixadr(a6),a2
	moveq	#0,d2
	move.w	d4,d2
	move.w	d3,d7
	subq	#1,d7

	moveq	#0,d0
	move.b	vola(a6),d0
	cmp.w	#$40,d0
	ble.s	mix_volok1
	move.b	#$40,vola(a6)
mix_volok1
	moveq	#0,d0
	move.b	volb(a6),d0
	cmp.w	#$40,d0
	ble.s	mix_volok2
	move.b	#$40,volb(a6)
mix_volok2

	tst.b	oldcpu
	beq.s	_68020
	move.l	d3,d6
	lsl.l	#8,d6
	lsl.l	#4,d6
	divu.w	d2,d6
	and.l	#$ffff,d6
	lsl.l	#4,d6
	bra.s	_68000
_68020:
	move.l	d3,d6
	swap	d6
	divu.l	d2,d6
_68000:
	tst.l	124(a5,d1.w)
	beq.s	nosamloop2
	move.l	(a5,d1.w),d4
	add.l	124(a5,d1.w),d4
	add.l	(a4,d1.w),d4
	tst.l	124(a5,d5.w)
	bne.s	doubleloop
	bra.w	samloopmix2
doubleloop
	move.l	(a5,d5.w),d0
	add.l	124(a5,d5.w),d0
	add.l	(a4,d5.w),d0
	bra.w	samloopmix3
nosamloop2:

	move.l	124(a4,d1.w),d4
	add.l	(a4,d1.w),d4

	tst.l	124(a5,d5.w)
	beq.s	nosamloop1
	move.l	(a5,d5.w),d0
	add.l	124(a5,d5.w),d0
	add.l	(a4,d5.w),d0
	bra.w	samloopmix1
nosamloop1:
	move.l	124(a4,d5.w),d0
	add.l	(a4,d5.w),d0
	move.l	d0,d5

; -------------- mixing norm. sample + norm. sample
	movem.l	d3-d4,-(sp)

	moveq	#0,d0
	moveq	#0,d1
	move.b	vola(a6),d0
	move.b	volb(a6),d1
	lsl.w	#8,d0
	lsl.w	#8,d1
	move.l	voltabptr,a4
	move.l	voltabptr,a5
	add.l	d0,a4
	add.l	d1,a5

	cmp.l	d4,a0
	bge.b	sammixloop1_11

	cmp.l	d5,a1
	bge.w	sammixloop1_111

	move.l	a0,d0
	add.l	d3,d0
	cmp.l	d4,d0
	bge.w	sammixloop1_1111

	move.l	a1,d1
	add.l	d2,d1
	cmp.l	d5,d1
	bge.w	sammixloop1_1111

sammixloop1_1:
	move.l	a4,d1
	move.l	a5,d0
	move.l	d6,d2
	move.l	d6,d3
	move.l	#$10000,d4
mixloop1_1:
	getvol1
	add.l	d4,d2
	cmp.l	d2,d3
	ble.s	newdata1_1
	add.b	d0,d1
	move.b	d1,(a2)+
	dbf	d7,mixloop1_1
	bra.w	mixdone
newdata1_1:
	add.l	d6,d3
	getvol2
	add.b	d0,d1
	move.b	d1,(a2)+
	dbf	d7,mixloop1_1
	bra.w	mixdone

;				 test d5,a1

sammixloop1_11:
	move.l	a4,d1
	move.l	a5,d0
	move.l	d6,d2
	move.l	d6,d3
	move.l	#$10000,d4
mixloop1_11:
	add.l	d4,d2
	cmp.l	d2,d3
	ble.s	newdata1_11
	move.b	d0,(a2)+
	dbf	d7,mixloop1_11
	bra.w	mixdone

newdata1_11
	add.l	d6,d3
	cmp.l	a1,d5
	bgt.s	mixgoon2_11
	clr.b	d0
	move.b	d0,(a2)+
	dbf	d7,mixloop1_11
	bra.w	mixdone

mixgoon2_11
	getvol2
	move.b	d0,(a2)+
	dbf	d7,mixloop1_11
	bra.w	mixdone

;				 test d4,a0

sammixloop1_111:
	moveq	#0,d0
	move.l	a4,d1
	moveq	#0,d2
	moveq	#0,d6
mixloop1_111:
	getvol1
	cmp.l	a0,d4
	bgt.s	mixgoon1_111
	move.b	d0,(a2)+
	dbf	d7,mixloop1_111
	bra.w	mixdone
mixgoon1_111
	move.b	d1,(a2)+
	dbf	d7,mixloop1_111
	bra.w	mixdone

;				 test d4,a0,	 d5,a1

sammixloop1_1111:
	move.l	a4,d1
	move.l	a5,d0
	move.l	d6,d2
	move.l	d6,d3
	move.l	d4,a3
	move.l	#$10000,d4
mixloop1_1111:
	getvol1
	cmp.l	a0,a3	; a0,d4
	bgt.s	mixgoon1_1111
	clr.b	d1
mixgoon1_1111
	add.l	d4,d2
	cmp.l	d2,d3
	ble.s	newdata1_1111
	add.b	d0,d1
	move.b	d1,(a2)+
	dbf	d7,mixloop1_1111
	bra.w	mixdone

newdata1_1111
	add.l	d6,d3
	getvol2
	cmp.l	a1,d5
	bgt.s	mixgoon2_1111
	clr.b	d0
	move.b	d1,(a2)+
	dbf	d7,mixloop1_1111
	bra.w	mixdone
mixgoon2_1111
	add.b	d0,d1
	move.b	d1,(a2)+
	dbf	d7,mixloop1_1111
	bra.w	mixdone



; -------------- mixing norm. sample + loop. sample

samloopmix1:
	movem.l	d3-d4,-(sp)
	move.l	(a5,d5.w),d1
	add.l	(a4,d5.w),d1
	move.l	d1,samrep1(a6)
	move.l	d0,d5

	moveq	#0,d0
	moveq	#0,d1
	move.b	vola(a6),d0
	move.b	volb(a6),d1
	lsl.w	#8,d0
	lsl.w	#8,d1
	move.l	voltabptr,a4
	move.l	voltabptr,a5
	add.l	d0,a4
	add.l	d1,a5

	cmp.l	a0,d4
	blt.b	sammixloop1_22

	move.l	a0,d0
	add.l	d3,d0
	cmp.l	d4,d0
	bge.b	sammixloop1_2

	move.l	a1,d1
	add.l	d2,d1
	cmp.l	d5,d1
	bge.b	sammixloop1_2
	bra.w	sammixloop1_1

sammixloop1_2:
	move.l	a4,d1
	move.l	a5,d0
	move.l	d6,d2
	move.l	d6,d3
	move.l	d4,a3
	move.l	#$10000,d4
mixloop1_2:
	getvol1
	cmp.l	a0,a3
	bgt.s	mixgoon1_2
	clr.b	d1
mixgoon1_2
	add.l	d4,d2
	cmp.l	d2,d3
	ble.s	newdata1_2
	add.b	d0,d1
	move.b	d1,(a2)+
	dbf	d7,mixloop1_2
	bra.w	mixdone
newdata1_2
	add.l	d6,d3
	getvol2
	cmp.l	a1,d5
	bgt.s	mixgoon2_2
	move.l	samrep1(a6),a1	; samrep1
mixgoon2_2
	add.b	d0,d1
	move.b	d1,(a2)+
	dbf	d7,mixloop1_2
	bra.w	mixdone

sammixloop1_22:
	move.l	a4,d1
	move.l	a5,d0
	move.l	d6,d2
	move.l	d6,d3
	move.l	#$10000,d4
mixloop1_22:
	add.l	d4,d2
	cmp.l	d2,d3
	ble.s	newdata1_22
	move.b	d0,(a2)+
	dbf	d7,mixloop1_22
	bra.w	mixdone
newdata1_22
	add.l	d6,d3
	getvol2
	cmp.l	a1,d5
	bgt.s	mixgoon2_22
	move.l	samrep1(a6),a1	; samrep1
mixgoon2_22
	move.b	d0,(a2)+
	dbf	d7,mixloop1_22
	bra.w	mixdone

; -------------- mixing loop. sample + norm. sample

samloopmix2:
	movem.l	d3-d4,-(sp)
	move.l	124(a4,d5.w),d0
	add.l	(a4,d5.w),d0
	move.l	d0,d5

	move.l	(a5,d1.w),d0
	add.l	(a4,d1.w),d0
	move.l	d0,samrep2(a6)

	moveq	#0,d0
	moveq	#0,d1
	move.b	vola(a6),d0
	move.b	volb(a6),d1
	lsl.w	#8,d0
	lsl.w	#8,d1
	move.l	voltabptr,a4
	move.l	voltabptr,a5
	add.l	d0,a4
	add.l	d1,a5

	cmp.l	a1,d5
	blt.b	sammixloop1_33

	move.l	a0,d0
	add.l	d3,d0
	cmp.l	d4,d0
	bge.b	sammixloop1_3

	move.l	a1,d1
	add.l	d2,d1
	cmp.l	d5,d1
	bge.b	sammixloop1_3
	bra.w	sammixloop1_1

sammixloop1_3
	move.l	a4,d1
	move.l	a5,d0
	move.l	d6,d2
	move.l	d6,d3
	move.l	d4,a3
	move.l	#$10000,d4
mixloop1_3:
	getvol1
	cmp.l	a0,a3
	bgt.s	mixgoon1_3
	move.l	samrep2(a6),a0
	move.b	#1,changeadr(a6)
mixgoon1_3
	add.l	d4,d2
	cmp.l	d2,d3
	ble.s	newdata1_3
	add.b	d0,d1
	move.b	d1,(a2)+
	dbf	d7,mixloop1_3
	bra.w	mixdone
newdata1_3
	add.l	d6,d3
	getvol2
	cmp.l	a1,d5
	bgt.s	mixgoon2_3
	clr.b	d0
	move.b	d1,(a2)+
	dbf	d7,mixloop1_3
	bra.w	mixdone
mixgoon2_3
	add.b	d0,d1
	move.b	d1,(a2)+
	dbf	d7,mixloop1_3
	bra.w	mixdone

sammixloop1_33
	move.l	a4,d1
	move.l	a5,d0
mixloop1_33:
	move.b	(a0)+,d1
	cmp.l	a0,d4
	bgt.s	mixgoon1_33
	move.l	samrep2(a6),a0
	move.b	#1,changeadr(a6)
mixgoon1_33
	move.l	d1,a4
	move.b	(a4),(a2)+
	dbf	d7,mixloop1_33
	bra.w	mixdone

; -------------- mixing loop. sample + loop. sample

samloopmix3:
	movem.l	d3-d4,-(sp)
	move.l	(a5,d1.w),samrep2(a6)
	move.l	(a4,d1.w),d1
	add.l	d1,samrep2(a6)

	move.l	(a5,d5.w),d1
	add.l	(a4,d5.w),d1
	move.l	d1,samrep1(a6)
	move.l	d0,d5

	moveq	#0,d0
	moveq	#0,d1
	move.b	vola(a6),d0
	move.b	volb(a6),d1
	lsl.w	#8,d0
	lsl.w	#8,d1
	move.l	voltabptr,a4
	move.l	voltabptr,a5
	add.l	d0,a4
	add.l	d1,a5

	move.l	a4,d1
	move.l	a5,d0
	move.l	d6,d2
	move.l	d6,d3
	move.l	d5,a3
	move.l	d4,d5
	move.l	#$10000,d4
mixloop1_4:
	getvol1
	cmp.l	a0,d5		; a0;d4
	bgt.s	mixgoon1_4
	move.l	samrep2(a6),a0
	move.b	#1,changeadr(a6)
mixgoon1_4
	add.l	d4,d2
	cmp.l	d2,d3
	ble.s	newdata1_4
	add.b	d0,d1
	move.b	d1,(a2)+
	dbf	d7,mixloop1_4
	move.l	a3,d5
	bra.b	mixdone
newdata1_4
	add.l	d6,d3
	getvol2
	cmp.l	a1,a3		; a0;d5
	bgt.s	mixgoon2_4
	move.l	samrep1(a6),a1
mixgoon2_4
	add.b	d0,d1
	move.b	d1,(a2)+
	dbf	d7,mixloop1_4
	move.l	a3,d5
	bra.w	mixdone

; -------------------------------------------------- 

mixdone:
	movem.l	(sp)+,d3-d4

	move.l	d0,-(sp)
	move.w	mixperiodb,d0
	cmp.w	mixperioda(pc),d0
	beq.s	nosubad
;	lsl.w	#1,d0
;	cmp.w	mixperioda(pc),d0
;	beq.s	nosubad
;	lsr.w	#2,d0
;	cmp.w	mixperioda(pc),d0
;	beq.s	nosubad

	cmp.l	samrep1(a6),a1
	bne.s	nosubok
	move.l	d5,a1
	bra.s	nosubad
nosubok	subq.l	#1,a1
	subq.l	#2,d5
nosubad	move.l	(sp)+,d0

	lea	mixdon(a6),a4
	cmp.l	a0,d4
	bge.s	notyet3
	move.b	#3,(a4)
notyet3
	cmp.l	a1,d5
	bge.s	notyet2
	move.b	#2,(a4)
notyet2
	cmp.l	a1,d5
	bge.s	notyet1
	cmp.l	a0,d4
	bge.s	notyet1
	move.b	#1,(a4)
notyet1
	movem.l	(sp)+,d5/a2
	move.l	a0,samrep2(a6)
	move.l	a1,124(a2,d5.w)
	rts


make_voltab:
	move.l	voltabadr,d0
	add.l	#256,d0
	and.l	#$ffffff00,d0
	move.l	d0,voltabptr
	move.l	d0,a0
	moveq	#0,d2
	move.w	#128,d3

	moveq	#64,d6
make_voltabl2
	move.w	#$ff,d7
	moveq	#0,d0
make_voltabl1
	move.b	d0,d1
	ext.w	d1
	muls	d2,d1
	divs	d3,d1
	cmp.b	#63,d1
	blt.s	make_volok1
	moveq	#63,d1
make_volok1
	cmp.b	#-64,d1
	bgt.s	make_volok2
	moveq	#-64,d1
make_volok2
	move.b	d1,(a0)+
	addq	#1,d0
	dbf	d7,make_voltabl1
	addq	#2,d2
	dbf	d6,make_voltabl2
	rts

hex:
 dc.b	0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,10,11,12,13,14,15,16,17,18,19
 dc.b	0,0,0,0,0,0,20,21,22,23,24,25,26,27,28,29,0,0,0,0,0,0,30,31
 dc.b	32,33,34,35,36,37,38,39,0,0,0,0,0,0,40,41,42,43,44,45,46,47
 dc.b	48,49,0,0,0,0,0,0,50,51,52,53,54,55,56,57,58,59,0,0,0,0,0,0
 dc.b	60,61,62,63

tunnings:

; tuning -8
	dc.w	907,856,808,762,720,678,640,604,570,538,508,480
	dc.w	453,428,404,381,360,339,320,302,285,269,254,240
	dc.w	226,214,202,190,180,170,160,151,143,135,127,120
; tuning -7
	dc.w	900,850,802,757,715,675,636,601,567,535,505,477
	dc.w	450,425,401,379,357,337,318,300,284,268,253,238
	dc.w	225,212,200,189,179,169,159,150,142,134,126,119
; tuning -6
	dc.w	894,844,796,752,709,670,632,597,563,532,502,474
	dc.w	447,422,398,376,355,335,316,298,282,266,251,237
	dc.w	223,211,199,188,177,167,158,149,141,133,125,118
; tuning -5
	dc.w	887,838,791,746,704,665,628,592,559,528,498,470
	dc.w	444,419,395,373,352,332,314,296,280,264,249,235
	dc.w	222,209,198,187,176,166,157,148,140,132,125,118
; tuning -4
	dc.w	881,832,785,741,699,660,623,588,555,524,494,467
	dc.w	441,416,392,370,350,330,312,294,278,262,247,233
	dc.w	220,208,196,185,175,165,156,147,139,131,123,117
; tuning -3
	dc.w	875,826,779,736,694,655,619,584,551,520,491,463
	dc.w	437,413,390,368,347,328,309,292,276,260,245,232
	dc.w	219,206,195,184,174,164,155,146,138,130,123,116
; tuning -2
	dc.w	868,820,774,730,689,651,614,580,547,516,487,460
	dc.w	434,410,387,365,345,325,307,290,274,258,244,230
	dc.w	217,205,193,183,172,163,154,145,137,129,122,115
; tuning -1
	dc.w	862,814,768,725,684,646,610,575,543,513,484,457
	dc.w	431,407,384,363,342,323,305,288,272,256,242,228
	dc.w	216,203,192,181,171,161,152,144,136,128,121,114
; tuning 0, normal
periods:
	dc.w	856,808,762,720,678,640,604,570,538,508,480,453
	dc.w	428,404,381,360,339,320,302,285,269,254,240,226
	dc.w	214,202,190,180,170,160,151,143,135,127,120,113
periodsend:
; tuning 1
	dc.w	850,802,757,715,674,637,601,567,535,505,477,450
	dc.w	425,401,379,357,337,318,300,284,268,253,239,225
	dc.w	213,201,189,179,169,159,150,142,134,126,119,113
; tuning 2
	dc.w	844,796,752,709,670,632,597,563,532,502,474,447
	dc.w	422,398,376,355,335,316,298,282,266,251,237,224
	dc.w	211,199,188,177,167,158,149,141,133,125,118,112
; tuning 3
	dc.w	838,791,746,704,665,628,592,559,528,498,470,444
	dc.w	419,395,373,352,332,314,296,280,264,249,235,222
	dc.w	209,198,187,176,166,157,148,140,132,125,118,111
; tuning 4
	dc.w	832,785,741,699,660,623,588,555,524,495,467,441
	dc.w	416,392,370,350,330,312,294,278,262,247,233,220
	dc.w	208,196,185,175,165,156,147,139,131,124,117,110
; tuning 5
	dc.w	826,779,736,694,655,619,584,551,520,491,463,437
	dc.w	413,390,368,347,328,309,292,276,260,245,232,219
	dc.w	206,195,184,174,164,155,146,138,130,123,116,109
; tuning 6
	dc.w	820,774,730,689,651,614,580,547,516,487,460,434
	dc.w	410,387,365,345,325,307,290,274,258,244,230,217
	dc.w	205,193,183,172,163,154,145,137,129,122,115,109
; tuning 7
	dc.w	814,768,725,684,646,610,575,543,513,484,457,431
	dc.w	407,384,363,342,323,305,288,272,256,242,228,216
	dc.w	204,192,181,171,161,152,144,136,128,121,114,108


;	section	tabs,bss_p

voltabadr:	ds.l	1
voltabptr:	ds.l	1

unpackeddata:	ds.l	8
pattadresses:	ds.l	129
sample_starts:	ds.l	31
sample_lenghts:	ds.l	31
sample_pos1:	ds.l	31
		ds.l	31
sample_pos2:	ds.l	31
		ds.l	31
sample_pos3:	ds.l	31
		ds.l	31
sample_pos4:	ds.l	31
		ds.l	31
; channel 1a&1b
channel1:	ds.b	chanarea
; channel 2a&2b datas
channel2:	ds.b	chanarea
; channel 3a&3b datas
channel3:	ds.b	chanarea
; channel 4a&4b datas
channel4:	ds.b	chanarea

 ifne testi

	section	module,data_p
;module:	incbin	"music:digi/religious.digi"
;module:	incbin	"sys:music/exo/digiboos/digi.crazy_cat"
module:	incbin	"sys:music/exo/digiboos/digi.rave_base"
 endc
