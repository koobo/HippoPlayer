˘˙˘˙ˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇˇ*******************************************************************************
*                       External patternscope for HippoPlayer
*				By K-P Koljonen
*******************************************************************************
* Requires kick2.0+!

 	incdir	include:
	include	exec/exec_lib.i
	include	exec/ports.i
	include	exec/types.i
	include	graphics/graphics_lib.i
	include	graphics/rastport.i
	include	intuition/intuition_lib.i
	include	intuition/intuition.i
	include	dos/dosextens.i
	include	mucro.i
	incdir
	include	asm:pt/kpl_offsets.s

*** HippoPlayer's port:

	STRUCTURE	HippoPort,MP_SIZE
	LONG		hip_private1	* Private..
	APTR		hip_kplbase	* kplbase address
	WORD		hip_reserved0	* Private..
	BYTE		hip_quit
	BYTE		hip_opencount	* Open count
	BYTE		hip_mainvolume	* Main volume, 0-64
	BYTE		hip_play	* If non-zero, HiP is playing
	BYTE		hip_playertype 	* 33 = Protracker, 49 = PS3M. 
	*** Protracker ***
	BYTE		hip_reserved2
	APTR		hip_PTch1	* Protracker channel data for ch1
	APTR		hip_PTch2	* ch2
	APTR		hip_PTch3	* ch3
	APTR		hip_PTch4	* ch4
	*** PS3M ***
	APTR		hip_ps3mleft	* Buffer for the left side
	APTR		hip_ps3mright	* Buffer for the right side
	LONG		hip_ps3moffs	* Playing position
	LONG		hip_ps3mmaxoffs	* Max value for hip_ps3moffs

	BYTE		hip_PTtrigger1
	BYTE		hip_PTtrigger2
	BYTE		hip_PTtrigger3
	BYTE		hip_PTtrigger4

	LABEL		HippoPort_SIZEOF 

	*** PT channel data block
	STRUCTURE	PTch,0
	LONG		PTch_start	* Start address of sample
	WORD		PTch_length	* Length of sample in words
	LONG		PTch_loopstart	* Start address of loop
	WORD		PTch_replen	* Loop length in words
	WORD		PTch_volume	* Channel volume
	WORD		PTch_period	* Channel period
	WORD		PTch_private1	* Private...
	
WIDTH	=	320	* Drawing dimensions
HEIGHT	=	64
RHEIGHT	=	HEIGHT+2

*** Variables:

	rsreset
_ExecBase	rs.l	1
_GFXBase	rs.l	1
_IntuiBase	rs.l	1
port		rs.l	1
owntask		rs.l	1
screenlock	rs.l	1
oldpri		rs.l	1
windowbase	rs.l	1
rastport	rs.l	1
userport	rs.l	1
windowtop	rs	1
windowtopb	rs	1
windowright	rs	1
windowleft	rs	1
windowbottom	rs	1
draw1		rs.l	1
draw2		rs.l	1
icounter	rs	1
icounter2	rs	1

tr1		rs.b	1
tr2		rs.b	1
tr3		rs.b	1
tr4		rs.b	1

vol1		rs	1
vol2		rs	1
vol3		rs	1
vol4		rs	1

wbmessage	rs.l	1

omabitmap	rs.b	bm_SIZEOF
size_var	rs.b	0



main
	lea	var_b,a5
	move.l	4.w,a6
	move.l	a6,(a5)

	bsr.w	getwbmessage

	sub.l	a1,a1
	lob	FindTask
	move.l	d0,owntask(a5)

	lea	intuiname(pc),a1
	lore	Exec,OldOpenLibrary
	move.l	d0,_IntuiBase(a5)

	lea 	gfxname(pc),a1		
	lob	OldOpenLibrary
	move.l	d0,_GFXBase(a5)

*** Try to find HippoPlayer's port, add 1 to hip_opencount
*** Protect this phase with Forbid()-Permit()!

	lob	Forbid
	lea	portname(pc),a1
	lob	FindPort
	move.l	d0,port(a5)
	beq.w	exit
	move.l	d0,a0
	addq.b	#1,hip_opencount(a0)	* We are using the port now!
	lob	Permit

	bsr.w	getscreendata

*** Open our window
	lea	winstruc,a0
	lore	Intui,OpenWindow
	move.l	d0,windowbase(a5)
	beq.w	exit
	move.l	d0,a0
	move.l	wd_RPort(a0),rastport(a5)
	move.l	wd_UserPort(a0),userport(a5)

	move.l	rastport(a5),a1
	moveq	#1,d0
	lore	GFX,SetAPen

*** Draw some gfx

plx1	equr	d4
plx2	equr	d5
ply1	equr	d6
ply2	equr	d7
 
	moveq   #7,plx1
	move    #332,plx2
	moveq   #13,ply1
	moveq   #80,ply2
	add	windowleft(a5),plx1
	add	windowleft(a5),plx2
	add	windowtop(a5),ply1
	add	windowtop(a5),ply2
	move.l	rastport(a5),a1
	bsr.w	piirra_loota2a

*** Initialize our bitmap structure

	lea	omabitmap(a5),a0
	moveq	#1,d0			* depth
	move	#WIDTH,d1		* width
	move	#HEIGHT,d2		* heigth (turva-alue)
	lore	GFX,InitBitMap
	move.l	#buffer1,omabitmap+bm_Planes(a5)

	move.l	#buffer1,draw1(a5)	* Buffer pointers for drawing
	move.l	#buffer2,draw2(a5)


	move.l	owntask(a5),a1		* Set our task to low priority
	moveq	#-30,d0
	;moveq	#0,d0
	lore	Exec,SetTaskPri
	move.l	d0,oldpri(a5)		* Store the old priority

*** Main loop

loop	move.l	_GFXBase(a5),a6		* Wait...
	lob	WaitTOF

	move.l	port(a5),a0		* Check if HiP is playing
	tst.b	hip_quit(a0)
	bne.b	.x
	tst.b	hip_play(a0)
	beq.b	.oh
	cmp.b	#33,hip_playertype(a0)	* Playing a Protracker module?
	bne.b	.oh


*** See if we should actually update the window.
	move.l	_IntuiBase(a5),a1
	move.l	ib_FirstScreen(a1),a1
	move.l	windowbase(a5),a0	
	cmp.l	wd_WScreen(a0),a1	* Is our screen on top?
	beq.b	.yes
	tst	sc_TopEdge(a1)	 	* Some other screen is partially on top 
	beq.b	.oh		 	* of our screen?
.yes

	bsr.w	dung			* Do the scope
.oh
	move.l	userport(a5),a0		* Get messages from IDCMP
	lore	Exec,GetMsg
	tst.l	d0
	beq.b	loop
	move.l	d0,a1


	move.l	im_Class(a1),d2		
	move	im_Code(a1),d3
	lob	ReplyMsg
	cmp.l	#IDCMP_MOUSEBUTTONS,d2	* Right mousebutton pressed?
	bne.b	.xy
	cmp	#MENUDOWN,d3
	beq.b	.x
.xy	cmp.l	#IDCMP_CLOSEWINDOW,d2	* Should we exit?
	bne.b	loop			* No. Keep loopin'
	
.x	move.l	owntask(a5),a1		* Restore the old priority
	move.l	oldpri(a5),d0
	lore	Exec,SetTaskPri

exit

*** Exit program
	
	move.l	port(a5),d0		* IMPORTANT! Subtract 1 from
	beq.b	.uh0			* hip_opencount when exiting
	move.l	d0,a0
	subq.b	#1,hip_opencount(a0)
.uh0
	move.l	windowbase(a5),d0
	beq.b	.uh1
	move.l	d0,a0
	lore	Intui,CloseWindow
.uh1
	move.l	_IntuiBase(a5),d0
	bsr.b	closel
	move.l	_GFXBase(a5),d0
	bsr.b	closel

	bsr.w	replywbmessage

	moveq	#0,d0			* No error
	rts
	
closel  beq.b   .huh
        move.l  d0,a1
        lore    Exec,CloseLibrary
.huh    rts



***** Get info about screen we're running on

getscreendata
	move.l	(a5),a0
	cmp	#37,LIB_VERSION(a0)
	bhs.b	.new
	rts
.new

*** Get some data about the default public screen
	sub.l	a0,a0
	lore	Intui,LockPubScreen  * The only kick2.0+ function in this prg!
	move.l	d0,d7
	beq.b	exit


	move.l	d0,a0
	move.b	sc_BarHeight(a0),windowtop+1(a5) * Palkin korkeus
	move.b	sc_WBorBottom(a0),windowbottom+1(a5)
	move.b	sc_WBorTop(a0),windowtopb+1(a5)
	move.b	sc_WBorLeft(a0),windowleft+1(a5)
	move.b	sc_WBorRight(a0),windowright+1(a5)

	move	windowtopb(a5),d0
	add	d0,windowtop(a5)

	subq	#4,windowleft(a5)		* saattaa menn‰ negatiiviseksi
	subq	#4,windowright(a5)
	subq	#2,windowtop(a5)
	subq	#2,windowbottom(a5)

	sub	#10,windowtop(a5)
	bpl.b	.o
	clr	windowtop(a5)
.o


	move	windowtop(a5),d0	* Adjust the window size
	add	d0,winstruc+6		
	move	windowleft(a5),d1
	add	d1,winstruc+4		
	add	d1,winsiz
	move	windowbottom(a5),d3
	add	d3,winsiz+2

	move.l	d7,a1
	sub.l	a0,a0
	lob	UnlockPubScreen
	rts


*** Draw a bevel box

piirra_loota2a

** bevelboksit, reunat kaks pixeli‰

laatikko1
	moveq	#1,d3
	moveq	#2,d2

	move.l	a1,a3
	move	d2,a4
	move	d3,a2

** valkoset reunat

	move	a2,d0
	move.l	a3,a1
	lore	GFX,SetAPen

	move	plx2,d0		* x1
	subq	#1,d0		
	move	ply1,d1		* y1
	move	plx1,d2		* x2
	move	ply1,d3		* y2
	bsr.w	drawli

	move	plx1,d0		* x1
	move	ply1,d1		* y1
	move	plx1,d2
	addq	#1,d2
	move	ply2,d3
	bsr.w	drawli
	
** mustat reunat

	move	a4,d0
	move.l	a3,a1
	lob	SetAPen

	move	plx1,d0
	addq	#1,d0
	move	ply2,d1
	move	plx2,d2
	move	ply2,d3
	bsr.b	drawli

	move	plx2,d0
	move	ply2,d1
	move	plx2,d2
	move	ply1,d3
	bsr.b	drawli

	move	plx2,d0
	subq	#1,d0
	move	ply1,d1
	addq	#1,d1
	move	plx2,d2
	subq	#1,d2
	move	ply2,d3
	bsr.b	drawli

looex	moveq	#1,d0
	move.l	a3,a1
	jmp	_LVOSetAPen(a6)



drawli	cmp	d0,d2
	bhi.b	.e
	exg	d0,d2
.e	cmp	d1,d3
	bhi.b	.x
	exg	d1,d3
.x	move.l	a3,a1
	move.l	_GFXBase(a5),a6
	jmp	_LVORectFill(a6)





*** Draw the scope

dung

	move.l	_GFXBase(a5),a6		* Grab the blitter
	lob	OwnBlitter
	lob	WaitBlit

	move.l	draw2(a5),$dff054	* Clear the drawing area
	move	#0,$dff066
	move.l	#$01000000,$dff040
	move	#HEIGHT*64+WIDTH/16,$dff058

	lob	DisownBlitter		* Free the blitter

	pushm	all
	bsr.b	notescroller		* Do the scope
	popm	all

	movem.l	draw1(a5),d0/d1		* Doublebuffering
	exg	d0,d1
	movem.l	d0/d1,draw1(a5)

	lea	omabitmap(a5),a0	* Set the bitplane pointer so bitmap 
	move.l	d1,bm_Planes(a0)

;	lea	omabitmap(a5),a0	* Copy from bitmap to rastport
	move.l	rastport(a5),a1
	moveq	#0,d0		* source x,y
	moveq	#0,d1
	moveq	#10,d2		* dest x,y
	moveq	#15,d3
	add	windowleft(a5),d2
	add	windowtop(a5),d3
	move.l	#$c0,d6		* minterm a->d
	move.l	#WIDTH,d4	* x-size
	move	#HEIGHT,d5	* y-size
	lore	GFX,BltBitMapRastPort
	rts











*******************************
* NoteScroller (ProTracker)
*

notescroller
	pushm	all
	bsr.w	.notescr

*** viiva
	move.l	draw1(a5),a0
	lea	7*40+2*8*40(a0),a0
	moveq	#19-1,d0
.raita	or	#$aaaa,(a0)+
	or	#$aaaa,8*40-2(a0)
	dbf	d0,.raita

	move.l	port(a5),a2
	move.b	hip_PTtrigger1(a2),d0
	move.b	hip_PTtrigger2(a2),d1
	move.b	hip_PTtrigger3(a2),d2
	move.b	hip_PTtrigger4(a2),d3

	cmp.b	tr1(a5),d0
	beq.b	.q1
	move.l	hip_PTch1(a2),a0
	move	PTch_volume(a0),vol1(a5)
.q1	cmp.b	tr2(a5),d1
	beq.b	.q2
	move.l	hip_PTch2(a2),a0
	move	PTch_volume(a0),vol2(a5)
.q2	cmp.b	tr3(a5),d2
	beq.b	.q3
	move.l	hip_PTch3(a2),a0
	move	PTch_volume(a0),vol3(a5)
.q3	cmp.b	tr4(a5),d3
	beq.b	.q4
	move.l	hip_PTch4(a2),a0
	move	PTch_volume(a0),vol4(a5)
.q4

	move.b	d0,tr1(a5)
	move.b	d1,tr2(a5)
	move.b	d2,tr3(a5)
	move.b	d3,tr4(a5)


	move.l	port(a5),a0
	move.l	hip_PTch1(a0),a0
	move	vol1(a5),d0
	moveq	#2,d1
	bsr.w	.palkki

	move.l	port(a5),a0
	move.l	hip_PTch2(a0),a0
	move	vol2(a5),d0
	moveq	#11,d1
	bsr.w	.palkki

	move.l	port(a5),a0
	move.l	hip_PTch3(a0),a0
	move	vol3(a5),d0
	moveq	#20,d1
	bsr.b	.palkki

	move.l	port(a5),a0
	move.l	hip_PTch1(a0),a0
	move	vol4(a5),d0
	moveq	#29,d1
	bsr.b	.palkki

	move.l	port(a5),a0
	move.l	hip_PTch1(a0),a3
	move.b	#%11100000,d2
	moveq	#38,d1
	bsr.w	.palkki2

	move.l	port(a5),a0
	move.l	hip_PTch2(a0),a3
	moveq	#%1110,d2
	moveq	#38,d1
	bsr.b	.palkki2

	move.l	port(a5),a0
	move.l	hip_PTch3(a0),a3
	moveq	#39,d1
	move.b	#%11100000,d2
	bsr.b	.palkki2

	move.l	port(a5),a0
	move.l	hip_PTch4(a0),a3
	moveq	#%1110,d2
	moveq	#39,d1
	bsr.b	.palkki2

.ohi

	lea	vol1(a5),a0
	bsr.b	.orl
	lea	vol2(a5),a0
	bsr.b	.orl
	lea	vol3(a5),a0
	bsr.b	.orl
	lea	vol4(a5),a0
	bsr.b	.orl

	popm	all
	rts

.orl	tst	(a0)
	beq.b	.urh
	subq	#1,(a0)
.urh	rts



***** Volumepalkgi

.palkki

	move.l	port(a5),a0
	moveq	#0,d2
	move.b	hip_mainvolume(a0),d2
	mulu	d2,d0
	lsr	#6,d0

	move.l	draw1(a5),a0
	lea	64*40(a0),a0
	add	d1,a0
	lea	.paldata(pC),a1

	moveq	#-2,d2
	subq	#1,d0
	bmi.b	.yg
.purl	and.b	d2,(a0)
	move.b	-(a1),d1
	or.b	d1,(a0)
	lea	-40(a0),a0
	dbf	d0,.purl	
.yg	rts



**** Periodpalkki
	
.palkki2
	cmp	#2,PTch_length(a3)
	bls.b	.h
	moveq	#0,d0
	move	PTch_period(a3),d0
	beq.b	.h
	sub	#108,d0
	lsl	#1,d0
	divu	#27,d0		* lukualueeksi 0-59

	move.l	draw1(a5),a0
	lea	multab(pc),a1
	add	d0,d0
	move	(a1,d0),d0
	add	d0,a0
	add	d1,a0

	or.b	d2,(a0)
	or.b	d2,40(a0)
	or.b	d2,80(a0)
	or.b	d2,120(a0)

.h	rts



;* 8x58
;	DC.l	$FCFCDCFC,$FCFCDCFC,$74FCDCFC,$54FC5CFC,$54BC54FC,$54B854E8
;	DC.l	$54B854A8,$54B854A8,$548854A0,$54885420,$54885400,$54005000
;	DC.l	$54001000,$04001000
;	dc	$0000
;.paldata

* 8x64
	DC.B	$FC,$FC,$FC,$FC
	DC.B	$FC,$DC,$FC,$7C
	DC.B	$FC,$DC,$FC,$54
	DC.B	$FC,$5C,$FC,$54
	DC.B	$FC,$54,$FC,$54
	DC.B	$B8,$54,$FC,$54
	DC.B	$B8,$54,$AC,$54
	DC.B	$B8,$54,$A8,$54
	DC.B	$A8,$54,$A8,$54
	DC.B	$88,$54,$28,$54
	DC.B	$88,$54,$00,$54
	DC.B	$88,$54,$00,$54
	DC.B	$00,$54,$00,$54
	DC.B	$00,$10,$00,$54
	DC.B	$00,$10,$00,$00
	DC.B	$00,$10,$00,$00
.paldata



**************** Piirret‰‰n patterndata

.notescr
	move.l	port(a5),a0
	move.l	hip_kplbase(a0),a0

	move.l	k_songdataptr(a0),a3
	moveq	#0,d0
	move	k_songpos(a0),d0
	move.b	(a3,d0),d0
	lsl	#6,d0
	add	k_patternpos(a0),d0
	lsl.l	#4,d0
	add.l	d0,a3
	lea	1084-952(a3),a3

	move.l	draw1(a5),a4
	addq	#3,a4

	moveq	#8-1,d7
	move	k_patternpos(a0),d6	* eka rivi?

	move	d6,d0
	subq	#4,d0
	bpl.b	.ok
	neg	d0
	sub	d0,d7

	moveq	#4,d1
	sub	d0,d1
	sub	d1,d6
	lsl	#4,d1
	sub	d1,a3

	mulu	#8*40,d0
	add.l	d0,a4

	bra.b	.ok2
.ok
	lea	-4*16(a3),a3
	subq	#4,d6
.ok2



.plorl
	lea	.pos(pc),a0		* rivinumero
	move	d6,d0
	divu	#10,d0
	or.b	#'0',d0
	move.b	d0,(a0)
	swap	d0
	or.b	#'0',d0
	move.b	d0,1(a0)

	move.l	a4,a1
	subq	#3,a1
	moveq	#2-1,d1
	bsr.w	.print

	moveq	#4-1,d5
.plorl2

	lea	.note(pc),a2

	moveq	#0,d0
	move.b	2(a3),d0
	bne.b	.jee
	move.b	#' ',(a2)+
	move.b	#' ',(a2)+
	move.b	#' ',(a2)+
	bra.b	.nonote
.jee
	subq	#1,d0
	divu	#12*2,d0
	addq	#1,d0
	or.b	#'0',d0
	move.b	d0,2(a2)
	swap	d0
	lea	.notes(pc),a1
	lea	(a1,d0),a0
	move.b	(a0)+,(a2)+		* Nuotti
	move.b	(a0)+,(a2)+
	addq	#1,a2
.nonote

	moveq	#0,d0			* samplenumero
	move.b	3(a3),d0
	bne.b	.onh
	move.b	#' ',(a2)+
	move.b	#' ',(a2)+
	bra.b	.eihn
.onh

	lsr	#2,d0
	divu	#$10,d0
	bne.b	.onh2
	move.b	#' ',(a2)+
	bra.b	.eihn2
.onh2	or.b	#'0',d0
	move.b	d0,(a2)+
.eihn2	swap	d0
	bsr.b	.hegs
.eihn

	move.b	(a3),d0			* komento
	lsr.b	#2,d0
	bsr.b	.hegs
	moveq	#0,d0
	move.b	1(a3),d0
	divu	#$10,d0
	bsr.b	.hegs
	swap	d0
	bsr.b	.hegs


	move.l	a4,a1
	lea	.note(pc),a0
	moveq	#8-1,d1
	bsr.b	.print


	addq	#4,a3
	add	#9,a4
	dbf	d5,.plorl2

	add	#8*40-4*9,a4
	addq	#1,d6
	cmp	#64,d6
	beq.b	.lorl
	dbf	d7,.plorl
.lorl
	rts


.hegs	cmp.b	#9,d0
	bhi.b	.high1
	or.b	#'0',d0
	bra.b	.hge
.high1	sub.b	#10,d0
	add.b	#'A',d0
.hge	move.b	d0,(a2)+
	rts

.notes	dc.b	"C-"
	dc.b	"C#"
	dc.b	"D-"
	dc.b	"D#"
	dc.b	"E-"
	dc.b	"F-"
	dc.b	"F#"
	dc.b	"G-"
	dc.b	"G#"
	dc.b	"A-"
	dc.b	"A#"
	dc.b	"B-"

.note	dc.b	"00000000"
.pos	dc.b	"00"
 even

.print
	pushm	a3-a4
	lea	font(pc),a2
;	move	38(a2),d2		* font modulo
;	move.l	34(a2),a2		* data
	move	#192,d2

	moveq	#40,d4
	
.ooe	moveq	#0,d0
	move.b	(a0)+,d0
	cmp.b	#$20,d0
	beq.b	.space
	lea	-$20(a2,d0),a3
	move.l	a1,a4

	moveq	#8-1,d3
.lin	move.b	(a3),(a4)	
	add	d2,a3
	add	d4,a4
	dbf	d3,.lin

.space	addq	#1,a1
	dbf	d1,.ooe
	popm	a3-a4
	rts

	

multab
aa set 0
	rept	HEIGHT
	dc	aa
aa set aa+WIDTH/8
	endr




**
* Workbench viestit
**
getwbmessage
	sub.l	a1,a1
	lore	Exec,FindTask
	move.l	d0,owntask(a5)

	move.l	d0,a4			* Vastataan WB:n viestiin, jos on.
	tst.l	pr_CLI(a4)
	bne.b	.nowb
	lea	pr_MsgPort(a4),a0
	lob	WaitPort
	lea	pr_MsgPort(a4),a0
	lob	GetMsg
	move.l	d0,wbmessage(a5)	
.nowb	rts

replywbmessage
	move.l	wbmessage(a5),d3
	beq.b	.nomsg
	lore	Exec,Forbid
	move.l	d3,a1
	lob	ReplyMsg
.nomsg	rts


*******************************************************************************
* Window

wflags set WFLG_SMART_REFRESH!WFLG_DRAGBAR!WFLG_CLOSEGADGET!WFLG_DEPTHGADGET
wflags set wflags!WFLG_RMBTRAP
idcmpflags = IDCMP_CLOSEWINDOW!IDCMP_MOUSEBUTTONS


winstruc
	dc	110,85	* x,y position
winsiz	dc	340,85	* x,y size
	dc.b	2,1	
	dc.l	idcmpflags
	dc.l	wflags
	dc.l	0
	dc.l	0	
	dc.l	.t	* title
	dc.l	0
	dc.l	0	
	dc	0,640	* min/max x
	dc	0,256	* min/max y
	dc	WBENCHSCREEN
	dc.l	0

.t	dc.b	"PatternScope",0

intuiname	dc.b	"intuition.library",0
gfxname		dc.b	"graphics.library",0
dosname		dc.b	"dos.library",0
portname	dc.b	"HiP-Port",0
 even



font
	DC.B	$00,$18,$6C,$6C,$18,$00,$38,$18
	DC.B	$0C,$30,$00,$00,$00,$00,$00,$03
	DC.B	$3C,$18,$3C,$3C,$1C,$7E,$1C,$7E
	DC.B	$3C,$3C,$00,$00,$0C,$00,$30,$3C
	DC.B	$7C,$18,$FC,$3C,$F8,$FE,$FE,$3C
	DC.B	$66,$7E,$0E,$E6,$F0,$82,$C6,$38
	DC.B	$FC,$38,$FC,$3C,$7E,$66,$C3,$C6
	DC.B	$C3,$C3,$FE,$3C,$C0,$3C,$10,$00
	DC.B	$18,$00,$E0,$00,$0E,$00,$1C,$00
	DC.B	$E0,$18,$06,$E0,$38,$00,$00,$00
	DC.B	$00,$00,$00,$00,$08,$00,$00,$00
	DC.B	$00,$00,$00,$0E,$18,$70,$72,$CC
	DC.B	$7E,$18,$0C,$1C,$42,$C3,$18,$3C
	DC.B	$66,$7E,$30,$00,$3E,$00,$7E,$7E
	DC.B	$3C,$18,$F0,$F0,$18,$00,$7E,$00
	DC.B	$00,$30,$70,$00,$20,$20,$C0,$18
	DC.B	$30,$0C,$18,$71,$C3,$3C,$1F,$3C
	DC.B	$60,$18,$30,$66,$30,$0C,$18,$66
	DC.B	$F8,$71,$30,$0C,$18,$71,$C3,$00
	DC.B	$3D,$30,$0C,$18,$66,$06,$F0,$7C
	DC.B	$30,$0C,$18,$71,$33,$3C,$00,$00
	DC.B	$30,$0C,$18,$66,$30,$0C,$18,$66
	DC.B	$60,$71,$30,$0C,$18,$71,$66,$00
	DC.B	$00,$30,$0C,$18,$66,$0C,$F0,$66
	DC.B	$00,$3C,$6C,$6C,$3E,$C6,$6C,$18
	DC.B	$18,$18,$66,$18,$00,$00,$00,$06
	DC.B	$66,$38,$66,$66,$3C,$60,$30,$66
	DC.B	$66,$66,$18,$18,$18,$00,$18,$66
	DC.B	$C6,$3C,$66,$66,$6C,$66,$66,$66
	DC.B	$66,$18,$06,$66,$60,$C6,$E6,$6C
	DC.B	$66,$6C,$66,$66,$5A,$66,$C3,$C6
	DC.B	$66,$C3,$C6,$30,$60,$0C,$38,$00
	DC.B	$18,$00,$60,$00,$06,$00,$36,$00
	DC.B	$60,$00,$00,$60,$18,$00,$00,$00
	DC.B	$00,$00,$00,$00,$18,$00,$00,$00
	DC.B	$00,$00,$00,$18,$18,$18,$9C,$33
	DC.B	$66,$00,$3E,$36,$3C,$66,$18,$40
	DC.B	$00,$81,$48,$33,$06,$00,$81,$00
	DC.B	$66,$18,$18,$18,$30,$00,$F4,$00
	DC.B	$00,$70,$88,$CC,$63,$63,$23,$00
	DC.B	$08,$10,$24,$8E,$18,$66,$3C,$66
	DC.B	$10,$20,$48,$00,$08,$10,$24,$00
	DC.B	$6C,$8E,$08,$10,$24,$8E,$3C,$63
	DC.B	$66,$08,$10,$24,$00,$08,$60,$66
	DC.B	$08,$10,$24,$8E,$00,$66,$00,$00
	DC.B	$08,$10,$24,$00,$08,$10,$24,$00
	DC.B	$FC,$8E,$08,$10,$24,$8E,$00,$18
	DC.B	$01,$08,$10,$24,$00,$10,$60,$00
	DC.B	$00,$3C,$00,$FE,$60,$CC,$68,$30
	DC.B	$30,$0C,$3C,$18,$00,$00,$00,$0C
	DC.B	$6E,$18,$06,$06,$6C,$7C,$60,$06
	DC.B	$66,$66,$18,$18,$30,$7E,$0C,$06
	DC.B	$DE,$3C,$66,$C0,$66,$60,$60,$C0
	DC.B	$66,$18,$06,$6C,$60,$EE,$F6,$C6
	DC.B	$66,$C6,$66,$70,$18,$66,$66,$C6
	DC.B	$3C,$66,$8C,$30,$30,$0C,$6C,$00
	DC.B	$0C,$3C,$6C,$3C,$36,$3C,$30,$3B
	DC.B	$6C,$38,$06,$66,$18,$66,$7C,$3C
	DC.B	$DC,$3D,$EC,$3E,$3E,$66,$66,$63
	DC.B	$63,$66,$7E,$18,$18,$18,$00,$CC
	DC.B	$66,$18,$6C,$30,$66,$3C,$18,$3C
	DC.B	$00,$9D,$88,$66,$00,$7E,$B9,$00
	DC.B	$3C,$7E,$30,$30,$00,$C6,$F4,$18
	DC.B	$00,$30,$88,$66,$26,$26,$66,$18
	DC.B	$3C,$3C,$3C,$3C,$3C,$3C,$3C,$C0
	DC.B	$FE,$FE,$FE,$FE,$7E,$7E,$7E,$7E
	DC.B	$66,$C6,$3C,$3C,$3C,$3C,$66,$36
	DC.B	$CF,$66,$66,$66,$66,$C3,$7E,$66
	DC.B	$3C,$3C,$3C,$3C,$3C,$3C,$7E,$3C
	DC.B	$3C,$3C,$3C,$3C,$38,$38,$38,$38
	DC.B	$18,$7C,$3C,$3C,$3C,$3C,$3C,$00
	DC.B	$3E,$66,$66,$66,$66,$66,$7C,$66
	DC.B	$00,$18,$00,$6C,$3C,$18,$76,$00
	DC.B	$30,$0C,$FF,$7E,$00,$7E,$00,$18
	DC.B	$7E,$18,$1C,$1C,$CC,$06,$7C,$0C
	DC.B	$3C,$3E,$00,$00,$60,$00,$06,$0C
	DC.B	$DE,$66,$7C,$C0,$66,$78,$78,$CE
	DC.B	$7E,$18,$06,$78,$60,$FE,$DE,$C6
	DC.B	$7C,$C6,$7C,$38,$18,$66,$66,$D6
	DC.B	$18,$3C,$18,$30,$18,$0C,$C6,$00
	DC.B	$00,$06,$76,$66,$6E,$66,$78,$66
	DC.B	$76,$18,$06,$6C,$18,$77,$66,$66
	DC.B	$66,$66,$76,$60,$18,$66,$66,$6B
	DC.B	$36,$66,$4C,$70,$18,$0E,$00,$33
	DC.B	$66,$18,$6C,$78,$3C,$18,$00,$66
	DC.B	$00,$B1,$F8,$CC,$00,$7E,$B9,$00
	DC.B	$00,$18,$60,$18,$00,$C6,$74,$18
	DC.B	$00,$30,$70,$33,$2C,$2C,$2C,$30
	DC.B	$66,$66,$66,$66,$66,$66,$6F,$C0
	DC.B	$60,$60,$60,$60,$18,$18,$18,$18
	DC.B	$F6,$E6,$66,$66,$66,$66,$C3,$1C
	DC.B	$DB,$66,$66,$66,$66,$66,$63,$6C
	DC.B	$06,$06,$06,$06,$06,$06,$1B,$66
	DC.B	$66,$66,$66,$66,$18,$18,$18,$18
	DC.B	$7C,$66,$66,$66,$66,$66,$66,$7E
	DC.B	$67,$66,$66,$66,$66,$66,$66,$66
	DC.B	$00,$18,$00,$FE,$06,$30,$DC,$00
	DC.B	$30,$0C,$3C,$18,$00,$00,$00,$30
	DC.B	$76,$18,$30,$06,$FE,$06,$66,$18
	DC.B	$66,$06,$00,$00,$30,$00,$0C,$18
	DC.B	$DE,$7E,$66,$C0,$66,$60,$60,$C6
	DC.B	$66,$18,$66,$6C,$62,$D6,$CE,$C6
	DC.B	$60,$C6,$6C,$0E,$18,$66,$3C,$FE
	DC.B	$3C,$18,$32,$30,$0C,$0C,$00,$00
	DC.B	$00,$1E,$66,$60,$66,$7E,$30,$66
	DC.B	$66,$18,$06,$78,$18,$6B,$66,$66
	DC.B	$66,$66,$66,$3C,$18,$66,$66,$6B
	DC.B	$1C,$66,$18,$18,$18,$18,$00,$CC
	DC.B	$66,$3C,$3E,$30,$42,$3C,$18,$3C
	DC.B	$00,$B1,$00,$66,$00,$00,$B1,$00
	DC.B	$00,$18,$F8,$F0,$00,$C6,$14,$00
	DC.B	$00,$30,$00,$66,$19,$1B,$D9,$60
	DC.B	$7E,$7E,$7E,$7E,$7E,$7E,$7C,$66
	DC.B	$78,$78,$78,$78,$18,$18,$18,$18
	DC.B	$66,$D6,$C3,$C3,$C3,$C3,$C3,$36
	DC.B	$F3,$66,$66,$66,$66,$3C,$63,$66
	DC.B	$1E,$1E,$1E,$1E,$1E,$1E,$7F,$60
	DC.B	$7E,$7E,$7E,$7E,$18,$18,$18,$18
	DC.B	$C6,$66,$66,$66,$66,$66,$66,$00
	DC.B	$6B,$66,$66,$66,$66,$66,$66,$66
	DC.B	$00,$00,$00,$6C,$7C,$66,$CC,$00
	DC.B	$18,$18,$66,$18,$18,$00,$18,$60
	DC.B	$66,$18,$66,$66,$0C,$66,$66,$18
	DC.B	$66,$0C,$18,$18,$18,$7E,$18,$00
	DC.B	$C0,$C3,$66,$66,$6C,$66,$60,$66
	DC.B	$66,$18,$66,$66,$66,$C6,$C6,$6C
	DC.B	$60,$6C,$66,$66,$18,$66,$3C,$EE
	DC.B	$66,$18,$66,$30,$06,$0C,$00,$00
	DC.B	$00,$66,$66,$66,$66,$60,$30,$3C
	DC.B	$66,$18,$06,$6C,$18,$63,$66,$66
	DC.B	$7C,$3E,$60,$06,$1A,$66,$3C,$36
	DC.B	$36,$3C,$32,$18,$18,$18,$00,$33
	DC.B	$66,$3C,$0C,$30,$00,$18,$18,$02
	DC.B	$00,$9D,$FC,$33,$00,$00,$A9,$00
	DC.B	$00,$00,$00,$00,$00,$EE,$14,$00
	DC.B	$00,$00,$F8,$CC,$33,$31,$33,$66
	DC.B	$C3,$C3,$C3,$C3,$C3,$C3,$CC,$3C
	DC.B	$60,$60,$60,$60,$18,$18,$18,$18
	DC.B	$6C,$CE,$66,$66,$66,$66,$66,$63
	DC.B	$66,$66,$66,$66,$66,$18,$7E,$66
	DC.B	$66,$66,$66,$66,$66,$66,$D8,$66
	DC.B	$60,$60,$60,$60,$18,$18,$18,$18
	DC.B	$C6,$66,$66,$66,$66,$66,$66,$18
	DC.B	$73,$66,$66,$66,$66,$3C,$7C,$3C
	DC.B	$00,$18,$00,$6C,$18,$C6,$76,$00
	DC.B	$0C,$30,$00,$00,$18,$00,$18,$C0
	DC.B	$3C,$7E,$7E,$3C,$1E,$3C,$3C,$18
	DC.B	$3C,$38,$18,$18,$0C,$00,$30,$18
	DC.B	$78,$C3,$FC,$3C,$F8,$FE,$F0,$3E
	DC.B	$66,$7E,$3C,$E6,$FE,$C6,$C6,$38
	DC.B	$F0,$3C,$E3,$3C,$3C,$3E,$18,$C6
	DC.B	$C3,$3C,$FE,$3C,$03,$3C,$00,$00
	DC.B	$00,$3B,$3C,$3C,$3B,$3C,$78,$C6
	DC.B	$E6,$3C,$66,$E6,$3C,$63,$66,$3C
	DC.B	$60,$06,$F0,$7C,$0C,$3B,$18,$36
	DC.B	$63,$18,$7E,$0E,$18,$70,$00,$CC
	DC.B	$7E,$18,$00,$7E,$00,$3C,$18,$3C
	DC.B	$00,$81,$00,$00,$00,$00,$81,$00
	DC.B	$00,$7E,$00,$00,$00,$FA,$14,$00
	DC.B	$18,$00,$00,$00,$67,$62,$67,$3C
	DC.B	$C3,$C3,$C3,$C3,$C3,$C3,$CF,$08
	DC.B	$FE,$FE,$FE,$FE,$7E,$7E,$7E,$7E
	DC.B	$F8,$C6,$3C,$3C,$3C,$3C,$3C,$00
	DC.B	$BC,$3E,$3E,$3E,$3E,$3C,$60,$6C
	DC.B	$3B,$3B,$3B,$3B,$3B,$3B,$77,$3C
	DC.B	$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C
	DC.B	$7C,$66,$3C,$3C,$3C,$3C,$3C,$00
	DC.B	$3E,$3B,$3B,$3B,$3B,$18,$60,$18
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$30,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$30,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$06,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$FE
	DC.B	$00,$00,$00,$00,$00,$00,$00,$7C
	DC.B	$00,$00,$3C,$00,$00,$00,$00,$00
	DC.B	$F0,$07,$00,$00,$00,$00,$00,$00
	DC.B	$00,$70,$00,$00,$00,$00,$00,$33
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$7E,$00,$00,$00,$00,$7E,$00
	DC.B	$00,$00,$00,$00,$00,$C0,$00,$00
	DC.B	$30,$00,$00,$00,$01,$07,$01,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$30
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$F0,$60
	DC.B	$00,$00,$00,$00,$00,$00,$00,$10
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$40,$00,$00,$00,$00,$70,$F0,$70
	DC.B	$00,$00,$00,$08,$00,$08,$00,$08
	DC.B	$00,$10,$00,$08,$00,$18,$00,$08
	DC.B	$00,$20,$00,$08,$00,$28,$00,$08
	DC.B	$00,$30,$00,$08,$00,$38,$00,$08
	DC.B	$00,$40,$00,$08,$00,$48,$00,$08
	DC.B	$00,$50,$00,$08,$00,$58,$00,$08
	DC.B	$00,$60,$00,$08,$00,$68,$00,$08
	DC.B	$00,$70,$00,$08,$00,$78,$00,$08
	DC.B	$00,$80,$00,$08,$00,$88,$00,$08
	DC.B	$00,$90,$00,$08,$00,$98,$00,$08
	DC.B	$00,$A0,$00,$08,$00,$A8,$00,$08
	DC.B	$00,$B0,$00,$08,$00,$B8,$00,$08
	DC.B	$00,$C0,$00,$08,$00,$C8,$00,$08
	DC.B	$00,$D0,$00,$08,$00,$D8,$00,$08
	DC.B	$00,$E0,$00,$08,$00,$E8,$00,$08
	DC.B	$00,$F0,$00,$08,$00,$F8,$00,$08
	DC.B	$01,$00,$00,$08,$01,$08,$00,$08
	DC.B	$01,$10,$00,$08,$01,$18,$00,$08
	DC.B	$01,$20,$00,$08,$01,$28,$00,$08
	DC.B	$01,$30,$00,$08,$01,$38,$00,$08
	DC.B	$01,$40,$00,$08,$01,$48,$00,$08
	DC.B	$01,$50,$00,$08,$01,$58,$00,$08
	DC.B	$01,$60,$00,$08,$01,$68,$00,$08
	DC.B	$01,$70,$00,$08,$01,$78,$00,$08
	DC.B	$01,$80,$00,$08,$01,$88,$00,$08
	DC.B	$01,$90,$00,$08,$01,$98,$00,$08
	DC.B	$01,$A0,$00,$08,$01,$A8,$00,$08
	DC.B	$01,$B0,$00,$08,$01,$B8,$00,$08
	DC.B	$01,$C0,$00,$08,$01,$C8,$00,$08
	DC.B	$01,$D0,$00,$08,$01,$D8,$00,$08
	DC.B	$01,$E0,$00,$08,$01,$E8,$00,$08
	DC.B	$01,$F0,$00,$08,$01,$F8,$00,$08
	DC.B	$02,$00,$00,$08,$02,$08,$00,$08
	DC.B	$02,$10,$00,$08,$02,$18,$00,$08
	DC.B	$02,$20,$00,$08,$02,$28,$00,$08
	DC.B	$02,$30,$00,$08,$02,$38,$00,$08
	DC.B	$02,$40,$00,$08,$02,$48,$00,$08
	DC.B	$02,$50,$00,$08,$02,$58,$00,$08
	DC.B	$02,$60,$00,$08,$02,$68,$00,$08
	DC.B	$02,$70,$00,$08,$02,$78,$00,$08
	DC.B	$02,$80,$00,$08,$02,$88,$00,$08
	DC.B	$02,$90,$00,$08,$02,$98,$00,$08
	DC.B	$02,$A0,$00,$08,$02,$A8,$00,$08
	DC.B	$02,$B0,$00,$08,$02,$B8,$00,$08
	DC.B	$02,$C0,$00,$08,$02,$C8,$00,$08
	DC.B	$02,$D0,$00,$08,$02,$D8,$00,$08
	DC.B	$02,$E0,$00,$08,$02,$E8,$00,$08
	DC.B	$02,$F0,$00,$08,$02,$F8,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08
	DC.B	$03,$00,$00,$08,$03,$00,$00,$08



 	section	udnm,bss_p

var_b		ds.b	size_var

	section	hihi,bss_c

buffer1	ds.b	WIDTH/8*RHEIGHT
buffer2	ds.b	WIDTH/8*RHEIGHT

 end
