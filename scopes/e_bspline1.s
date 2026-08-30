ùúùúÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ*******************************************************************************
*                       External WeirdScope for HippoPlayer
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
	
WIDTH	=	7*16	* Drawing dimensions
HEIGHT	=	97
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

tr1		rs.b	1
tr2		rs.b	1
tr3		rs.b	1
tr4		rs.b	1

vol1		rs	1
vol2		rs	1
vol3		rs	1
vol4		rs	1

note1		rs	1
note2		rs	1
note3		rs	1
note4		rs	1

wbmessage	rs.l	1

omabitmap	rs.b	bm_SIZEOF


coeffs		rs	4*256
nuottaulu1	rs	36
nuottaulu2	rs	36
nuottaulu3	rs	36
nuottaulu4	rs	36

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
	moveq   #332-160-32-21,plx2
	move  	#80+30,ply2
	moveq   #13,ply1
	add	windowleft(a5),plx1
	add	windowleft(a5),plx2
	add	windowtop(a5),ply1
	add	windowtop(a5),ply2
	move.l	rastport(a5),a1
	bsr.w	laatikko1

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

	bsr.w	bspline_init

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

	subq	#4,windowleft(a5)		* saattaa mennä negatiiviseksi
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





** bevelboksit, reunat kaks pixeliä

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
	bsr.w	notescroller		* Do the scope

;	move.l	draw1(a5),a0
;	move	#HEIGHT*(WIDTH/8),d0
;.c	move.b	#-1,(a0)+
;	subq	#1,d0
;	bne.b	.c
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
	move	#$c0,d6		* minterm a->d
	move	#WIDTH,d4	* x-size
	move	#HEIGHT,d5	* y-size
	lore	GFX,BltBitMapRastPort
	rts







mulu_32
	move.l	d2,-(a7)
	move.l	d3,-(a7)
	move.l	d0,d2
	move.l	d1,d3
	swap	d2
	swap	d3
	mulu.w	d1,d2
	mulu.w	d0,d3
	mulu.w	d1,d0
	add.w	d3,d2
	swap	d2
	clr.w	d2
	add.l	d2,d0
	move.l	(a7)+,d3
	move.l	(a7)+,d2
	rts	


bspline_init
	

	lea	coeffs(a5),a0
	moveq	#0,d6
.coef
	move	d6,d5
	mulu	d5,d5
	move.l	d5,d4
	add.l	#1<<8/2,d5
	lsr.l	#8,d5		* t^2

;	mulu.l	d6,d4

	pushm	d0/d1
	move.l	d6,d0
	move.l	d4,d1
	bsr.b	mulu_32
	move.l	d0,d4
	popm	d0/d1

	add.l	#1<<16/2,d4	* t^3
	swap	d4

;		C(t) = (-1/6*t³ + 1/2*t² - 1/2*t + 1/6) * P(i-1) +

* -1/6*t^3 
	moveq	#-43,d0		* -256/6=42.66
	muls	d4,d0
	add.l	#1<<8/2,d0
	asr.l	#8,d0

* + 1/2*t^2
	move	#256/2,d1
	mulu	d5,d1
	add.l	#1<<8/2,d1
	asr.l	#8,d1
	add	d1,d0
* - 1/2*t
	move	d6,d1
	addq	#1,d1
	lsr	#1,d1
	sub	d1,d0
* + 1/6
	add	#43,d0		* 256/6=42.66
	move	d0,(a0)+

;		       ( 1/2*t³ -     t²         + 2/3) * P(i)   +


* 1/2*t^3
	move	d4,d0
	addq	#1,d0
	lsr	#1,d0
* - t^2
	sub	d5,d0
* + 2/3
	add	#171,d0		* (2*256)/3
	move	d0,(a0)+


;		       (-1/2*t³ + 1/2*t² + 1/2*t + 1/6) * P(i+1) +

* -1/2*t^3
	move	d4,d0
	neg	d0
* 1/2*t^2
	add	d5,d0
* 1/2*t
	add	d6,d0
	asr	#1,d0
* 1/6
	add	#43,d0
	move	d0,(a0)+

;		       ( 1/6*t³                       ) * P(i+2)
* 1/6*t^3
	moveq	#43,d1
	mulu	d4,d1
	add.l	#1<<8/2,d1
	lsr.l	#8,d1
	move	d1,(a0)+

	addq	#8,d6
	cmp	#256,d6
	bne.w	.coef



;		C(t) = (-1/6*t³ + 1/2*t² - 1/2*t + 1/6) * P(i-1) +
;		       ( 1/2*t³ -     t²         + 2/3) * P(i)   +
;		       (-1/2*t³ + 1/2*t² + 1/2*t + 1/6) * P(i+1) +
;		       ( 1/6*t³                       ) * P(i+2)

	rts



CX	=	60-8
CY	=	46


*******************************
* NoteScroller (ProTracker)
*



notescroller


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

	move.b	2(a3),d4
	move.b	4+2(a3),d5
	move.b	8+2(a3),d6
	move.b	12+2(a3),d7


	tst.b	d4
	beq.b	.h1
	move.b	d4,note1+1(a5)
.h1	tst.b	d5
	beq.b	.h2
	move.b	d5,note2+1(a5)
.h2	tst.b	d6
	beq.b	.h3
	move.b	d6,note3+1(a5)
.h3	tst.b	d7
	beq.b	.h4
	move.b	d7,note4+1(a5)
.h4


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

	

* 1. neljännes

	lea	controlpoints1(pc),a0
	move	note1(a5),d1
	move	vol1(a5),d0
	bsr.w	.projektio
	beq.b	.p1

	neg	d0
	neg	d1
	add	#CX,d0
	add	#CY,d1
	movem	d0/d1,(a0)

.p1
	lea	controlpoints2(pc),a0
	move	note2(a5),d1
	move	vol2(a5),d0
	bsr.b	.projektio
	beq.b	.p2

	neg	d1
	add	#CX,d0
	add	#CY,d1
	movem	d0/d1,(a0)

.p2
	lea	controlpoints3(pc),a0
	move	note3(a5),d1
	move	vol3(a5),d0
	bsr.b	.projektio
	beq.b	.p3

	add	#CX,d0
	add	#CY,d1
	movem	d0/d1,(a0)

.p3
	lea	controlpoints4(pc),a0
	move	note4(a5),d1
	move	vol4(a5),d0
	bsr.b	.projektio
	beq.b	.p4

	neg	d0
	add	#CX,d0
	add	#CY,d1
	movem	d0/d1,(a0)

.p4


	bsr.b	.bspline

	lea	vol1(a5),a0
	bsr.b	.or
	lea	vol2(a5),a0
	bsr.b	.or
	lea	vol3(a5),a0
	bsr.b	.or
	lea	vol4(a5),a0
	bsr.b	.or

	rts


.or	tst	(a0)
	beq.b	.xxx
	subq	#1,(a0)
.xxx	rts



** 

.projektio
	move	#CX,(a0)
	move	#CY,2(a0)

	lea	sinetable(pc),a1


	and	#$7f,d1
	beq.b	.xx

** kulma
	subq	#1,d1	
	lsr	#1,d1		* d1=0-35
	mulu	#25,d1
	addq	#5,d1
	ext.l	d1
	divu	#10,d1		* kulma 0-90

	add	d1,d1
	move	(a1,d1),d2	* sin
	add	#90*2,d1
	move	(a1,d1),d1	* cos


** pituus
	lsl	#8,d0		* fixed point

	muls	d0,d1		* r·cosß
	muls	d0,d2		* r·sinß
	swap	d1
	swap	d2

;	asr	#3,d1
;	asr	#3,d2

	move	d1,d0
	move	d2,d1

;	asr.l	#8,d1
;	asr.l	#8,d2
;	asr.l	#8,d1
;	asr.l	#8,d2

	moveq	#-1,d2

.xx	rts


.bspline
	lea	controlpoints(pc),a0
	lea	cpend(pc),a1
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+


	move.l	draw1(a5),a0
	
	lea	controlpoints+4(pc),a3
	move.l	#1<<8/2,d5
	move	CPOINTS(pc),d7
	subq	#2+2,d7
.loop1
	moveq	#256/8-1,d6
	lea	coeffs(a5),a4
.loop2

	movem	(a4),d0/d1/d2/d3
	muls	-4(a3),d0
	muls	(a3),d1
	muls	4(a3),d2
	muls	8(a3),d3
	add.l	d3,d2
	add.l	d2,d1
	add.l	d1,d0
	add.l	d5,d0
	lsr.l	#8,d0
	move	d0,d4

	movem	(a4)+,d0/d1/d2/d3
	muls	-4+2(a3),d0
	muls	2(a3),d1
	muls	4+2(a3),d2
	muls	8+2(a3),d3
	add.l	d3,d2
	add.l	d2,d1
	add.l	d1,d0
	add.l	d5,d0
	lsr.l	#8,d0

	add	d0,d0
	move	mtab(pc,d0),d0
	move	d4,d2
	lsr	#3,d2
	add	d2,d0
	not	d4
	bset	d4,(a0,d0)

	dbf	d6,.loop2

	addq	#4,a3
	dbf	d7,.loop1


.x	rts


mtab	
aa set 0
	rept	HEIGHT
	dc	aa
aa set aa+WIDTH/8
	endr



controlpoints
controlpoints1
	ds.l	1
	dc	CX,CY-20
controlpoints2
	ds.l	1
	dc	CX+20,CY
controlpoints3
	ds.l	1
	dc	CX,CY+20
controlpoints4
	ds.l	1
	dc	CX-20,CY
cpend
	ds.l	3
cpe
		dc	-1

CPOINTS		dc	(cpe-controlpoints)/4


* sinit kulmista 0°-452° kerrottuna 256:lla

sinetable
	dc.w	0,4,8,13,$11,$16,$1A,$1F,$23,$28,$2C,$30,$35,$39
	dc.w	$3D,$42,$46,$4A,$4F,$53,$57,$5B,$5F,$64,$68,$6C
	dc.w	$70,$74,$78,$7C,$7F,$83,$87,$8B,$8F,$92,$96,$9A
	dc.w	$9D,$A1,$A4,$A7,$AB,$AE,$B1,$B5,$B8,$BB,$BE,$C1
	dc.w	$C4,$C6,$C9,$CC,$CF,$D1,$D4,$D6,$D9,$DB,$DD,$DF
	dc.w	$E2,$E4,$E6,$E8,$E9,$EB,$ED,$EE,$F0,$F2,$F3,$F4
	dc.w	$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FC,$FD,$FE,$FE,$FF
	dcb.w	$4,$FF
	dc.w	$100,$FF,$FF,$FF,$FF,$FF,$FE,$FE,$FD,$FC,$FC,$FB
	dc.w	$FA,$F9,$F8,$F7,$F6,$F4,$F3,$F2,$F0,$EE,$ED,$EB
	dc.w	$E9,$E8,$E6,$E4,$E2,$DF,$DD,$DB,$D9,$D6,$D4,$D1
	dc.w	$CF,$CC,$C9,$C6,$C4,$C1,$BE,$BB,$B8,$B5,$B1,$AE
	dc.w	$AB,$A7,$A4,$A1,$9D,$9A,$96,$92,$8F,$8B,$87,$83
	dc.w	$80,$7C,$78,$74,$70,$6C,$68,$64,$5F,$5B,$57,$53
	dc.w	$4F,$4A,$46,$42,$3D,$39,$35,$30,$2C,$28,$23,$1F
	dc.w	$1A,$16,$11,13,8,4,0,$FFFC,$FFF8,$FFF3,$FFEF
	dc.w	$FFEA,$FFE6,$FFE1,$FFDD,$FFD8,$FFD4,$FFD0,$FFCB
	dc.w	$FFC7,$FFC3,$FFBE,$FFBA,$FFB6,$FFB1,$FFAD,$FFA9
	dc.w	$FFA5,$FFA1,$FF9C,$FF98,$FF94,$FF90,$FF8C,$FF88
	dc.w	$FF84,$FF81,$FF7D,$FF79,$FF75,$FF71,$FF6E,$FF6A
	dc.w	$FF66,$FF63,$FF5F,$FF5C,$FF59,$FF55,$FF52,$FF4F
	dc.w	$FF4B,$FF48,$FF45,$FF42,$FF3F,$FF3C,$FF3A,$FF37
	dc.w	$FF34,$FF31,$FF2F,$FF2C,$FF2A,$FF27,$FF25,$FF23
	dc.w	$FF21,$FF1E,$FF1C,$FF1A,$FF18,$FF17,$FF15,$FF13
	dc.w	$FF12,$FF10,$FF0E,$FF0D,$FF0C,$FF0A,$FF09,$FF08
	dc.w	$FF07,$FF06,$FF05,$FF04,$FF04,$FF03,$FF02,$FF02
	dcb.w	$5,$FF01
	dc.w	$FF00,$FF01,$FF01,$FF01,$FF01,$FF01,$FF02,$FF02
	dc.w	$FF03,$FF04,$FF04,$FF05,$FF06,$FF07,$FF08,$FF09
	dc.w	$FF0A,$FF0C,$FF0D,$FF0E,$FF10,$FF12,$FF13,$FF15
	dc.w	$FF17,$FF18,$FF1A,$FF1C,$FF1E,$FF21,$FF23,$FF25
	dc.w	$FF27,$FF2A,$FF2C,$FF2F,$FF31,$FF34,$FF37,$FF3A
	dc.w	$FF3C,$FF3F,$FF42,$FF45,$FF48,$FF4B,$FF4F,$FF52
	dc.w	$FF55,$FF59,$FF5C,$FF5F,$FF63,$FF66,$FF6A,$FF6E
	dc.w	$FF71,$FF75,$FF79,$FF7D,$FF80,$FF84,$FF88,$FF8C
	dc.w	$FF90,$FF94,$FF98,$FF9C,$FFA1,$FFA5,$FFA9,$FFAD
	dc.w	$FFB1,$FFB6,$FFBA,$FFBE,$FFC3,$FFC7,$FFCB,$FFD0
	dc.w	$FFD4,$FFD8,$FFDD,$FFE1,$FFE6,$FFEA,$FFEF,$FFF3
	dc.w	$FFF8,$FFFC,0,4,8,13,$11,$16,$1A,$1F,$23,$28,$2C
	dc.w	$30,$35,$39,$3D,$42,$46,$4A,$4F,$53,$57,$5B,$5F
	dc.w	$64,$68,$6C,$70,$74,$78,$7C,$7F,$83,$87,$8B,$8F
	dc.w	$92,$96,$9A,$9D,$A1,$A4,$A7,$AB,$AE,$B1,$B5,$B8
	dc.w	$BB,$BE,$C1,$C4,$C6,$C9,$CC,$CF,$D1,$D4,$D6,$D9
	dc.w	$DB,$DD,$DF,$E2,$E4,$E6,$E8,$E9,$EB,$ED,$EE,$F0
	dc.w	$F2,$F3,$F4,$F6,$F7,$F8,$F9,$FA,$FB,$FC,$FC,$FD
	dcb.w	$2,$FE
	dcb.w	$5,$FF
	dc.w	$100,$FF




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
winsiz	dc	128,115	* x,y size
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

.t	dc.b	"WeirdScope",0

intuiname	dc.b	"intuition.library",0
gfxname		dc.b	"graphics.library",0
dosname		dc.b	"dos.library",0
portname	dc.b	"HiP-Port",0
 even

 	section	udnm,bss_p

var_b		ds.b	size_var

	section	hihi,bss_c

buffer1	ds.b	WIDTH/8*RHEIGHT
buffer2	ds.b	WIDTH/8*RHEIGHT

 end
