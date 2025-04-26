ùúùúÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ*******************************************************************************
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
coeffs		rs	4*256

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
 
	moveq   #8,plx1
	move    #331,plx2
	moveq   #13,ply1
	moveq   #80,ply2
	add	windowleft(a5),plx1
	add	windowleft(a5),plx2
	add	windowtop(a5),ply1
	add	windowtop(a5),ply2
	move.l	rastport(a5),a2
	bsr.w	piirra_loota2
	subq	#1,plx1
	addq	#1,plx2
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

	bsr	bspline_init

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


*** Draw a bevel box

piirra_loota2a
	pushm	all
	moveq	#1,d3
	bra.b	prl

piirra_loota2
	pushm	all
	moveq	#0,d3
prl
	move.l	rastport(a5),a2
	move	#1,a3
	move	#2,a4

	move.l	_GFXBase(a5),a6
	move.l	a3,d0
	move.l	a2,a1
	lob	SetAPen

	move.l	plx1,d0
	move.l	ply2,d1
	lob	Move
	move.l	a2,a1
	move.l	plx1,d0
	move.l	ply1,d1
	lob	Draw

	move.l	a2,a1
	move.l	plx2,d0
	move.l	ply1,d1
	lob	Draw

	move.l	a2,a1
	move.l	a4,d0
	lob	SetAPen

	move.l	a2,a1
	move.l	plx2,d0
	move.l	ply1,d1
	addq.l	#1,d1
	sub.l	d3,d1
	lob	Move
	move.l	a2,a1
	move.l	plx2,d0
	move.l	ply2,d1
	lob	Draw

	move.l	a2,a1
	move.l	plx1,d0
	addq.l	#1,d0
	move.l	ply2,d1
	lob	Draw

	move.l	a2,a1
	moveq	#1,d0
	lob	SetAPen

	popm	all
	rts



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








bspline_init
	

	lea	coeffs(a5),a0
	moveq	#0,d6
.coef
	move	d6,d5
	mulu	d5,d5
	move.l	d5,d4
	add.l	#1<<8/2,d5
	lsr.l	#8,d5		* t^2

	mulu.l	d6,d4
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

	addq	#1,d6
	cmp	#256,d6
	bne.b	.coef



;		C(t) = (-1/6*t³ + 1/2*t² - 1/2*t + 1/6) * P(i-1) +
;		       ( 1/2*t³ -     t²         + 2/3) * P(i)   +
;		       (-1/2*t³ + 1/2*t² + 1/2*t + 1/6) * P(i+1) +
;		       ( 1/6*t³                       ) * P(i+2)

	rts





*******************************
* NoteScroller (ProTracker)
*

notescroller
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

;	move	vol1(a5),d0
;	mulu	#40,d0
;	lsr	#6,d0
;	move	d0,v1
;	clr	v2
;	clr	v3
;	clr	v4

	move	vol1(a5),v1
	move	vol2(a5),v2
	move	vol3(a5),v3
	move	vol4(a5),v4

** nuotit


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

	lea	nuottaulu(pc),a0

	moveq	#0,d0
	move.b	2(a3),d0		* (0-36)*2
	beq.b	.n
	move	#32,-1(a0,d0)

.n	move.b	4+2(a3),d0		* (0-36)*2
	beq.b	.n2
	move	#32,-1(a0,d0)

.n2	move.b	8+2(a3),d0		* (0-36)*2
	beq.b	.n3
	move	#32,-1(a0,d0)

.n3	move.b	12+2(a3),d0		* (0-36)*2
	beq.b	.n4
	move	#32,-1(a0,d0)
.n4


*** kanavat

	lea	controlpoints+2(pc),a3
	move	CPOINTS(pc),d7
	subq	#2+2,d7
	moveq	#0,d4		* x
	move	d4,a2
	move.l	#1<<8/2,d5
.loop1
	move	#256-1,d6
	lea	coeffs(a5),a4
.loop2
	addq	#1,a2
	cmp	#7,a2
	bhs.b	.plot

	addq	#8,a4
	bra.b	.noplot
.plot
	movem	(a4)+,d0/d1/d2/d3
	muls	-2(a3),d0
	muls	(a3),d1
	muls	2(a3),d2
	muls	4(a3),d3
	add.l	d3,d2
	add.l	d2,d1
	add.l	d0,d1
	add.l	d5,d1
	lsr.l	#8,d1
	move	d4,d0
	bsr.w	plot

	sub	a2,a2
	addq	#1,d4
.noplot
	dbf	d6,.loop2
	addq	#2,a3
	dbf	d7,.loop1

.og
*** nuotit
	lea	controlpoints2+2(pc),a3
	move	CPOINTS2(pc),d7
	subq	#2+2,d7
	moveq	#0,d4		* x
	move	d4,a2
	move.l	#1<<8/2,d5
.loop1a
	move	#256-1,d6
	lea	coeffs(a5),a4
.loop2a
	addq	#1,a2
	cmp	#32,a2
	bhs.b	.plota

	addq	#8,a4
	bra.b	.noplota
.plota
	movem	(a4)+,d0/d1/d2/d3
	muls	-2(a3),d0
	muls	(a3),d1
	muls	2(a3),d2
	muls	4(a3),d3
	add.l	d3,d2
	add.l	d2,d1
	add.l	d0,d1
	add.l	d5,d1
	lsr.l	#8,d1

	moveq	#63,d0
	sub	d1,d0
	move	d0,d1

	move	d4,d0
	bsr.w	plot

	sub	a2,a2
	addq	#1,d4
.noplota
	dbf	d6,.loop2a
	addq	#2,a3
	dbf	d7,.loop1a


	lea	nuottaulu(pc),a0
	moveq	#36-1,d0
.l
	tst	(a0)+
	beq.b	.f
	subq	#1,-2(a0)
.f	dbf	d0,.l


	lea	vol1(a5),a0
	bsr.b	.orl
	lea	vol2(a5),a0
	bsr.b	.orl
	lea	vol3(a5),a0
	bsr.b	.orl
	lea	vol4(a5),a0
	bsr.b	.orl

	rts


.orl	tst	(a0)
	beq.b	.urh
	subq	#1,(a0)
.urh	rts


plot	
	move.l	draw1(a5),a0
	add	d1,d1
	move	mtab(pc,d1),d1
	move	d0,d2
	lsr	#3,d0
	add	d0,d1
	not	d2
	bset	d2,(a0,d1)
	rts


mtab	
aa set 0
	rept	256
	dc	aa
aa set aa+40
	endr




controlpoints	
	dc	0,0
v1	dc	100
	dc	0
v2	dc	100
	dc	0
v3	dc	100
	dc	0
v4	dc	100
	dc	0,0

cpe
		dc	-1

CPOINTS		dc	(cpe-controlpoints)/2


controlpoints2
	dc	0,0
nuottaulu
	ds	36
	dc	0,0

cpe2
	dc	-1

CPOINTS2		dc	(cpe2-controlpoints2)/2




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

.t	dc.b	"CurveScope",0

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
