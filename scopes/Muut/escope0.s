*******************************************************************************
*                       External quadrascope for HippoPlayer
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
	include	mucro.i
	incdir

*** HippoPlayer's port:

	STRUCTURE	HippoPort,MP_SIZE
	LONG		hip_private1	* Private..
	LONG		hip_reserved1	* Private..
	WORD		hip_reserved2	* Private..
	BYTE		hip_reserved3	* Private..
	BYTE		hip_opencount	* Open count
	BYTE		hip_mainvolume	* Main volume, 0-64
	BYTE		hip_play	* If non-zero, HiP is playing
	BYTE		hip_playertype 	* 33 = Protracker, 49 = PS3M. 
	*** Protracker ***
	BYTE		hip_PTtrigger
	APTR		hip_PTch1	* Protracker channel data for ch1
	APTR		hip_PTch2	* ch2
	APTR		hip_PTch3	* ch3
	APTR		hip_PTch4	* ch4
	*** PS3M ***
	APTR		hip_ps3mleft	* Buffer for the left side
	APTR		hip_ps3mright	* Buffer for the right side
	LONG		hip_ps3moffs	* Playing position
	LONG		hip_ps3mmaxoffs	* Max value for hip_ps3moffs
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
	
WIDTH	=	512	* Drawing dimensions
HEIGHT	=	128
RHEIGHT	=	131	

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
windowright	rs	1
windowleft	rs	1
windowbottom	rs	1
draw1		rs.l	1
draw2		rs.l	1
icounter	rs	1
icounter2	rs	1

omabitmap	rs.b	bm_SIZEOF
size_var	rs.b	0



main
	lea	var_b,a5
	move.l	4.w,a6
	move.l	a6,(a5)

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

*** Get some data about the default public screen

	cmp	#37,LIB_VERSION(A5)
	blo.b	.old

	sub.l	a0,a0
	lore	Intui,LockPubScreen  * The only kick2.0+ function in this prg!
	move.l	d0,d7
	beq.w	exit

	move.l	d0,a0
	move.b	sc_BarHeight(a0),windowtop+1(a5) 
	move.b	sc_WBorLeft(a0),windowleft+1(a5)
	move.b	sc_WBorRight(a0),windowright+1(a5)
	move.b	sc_WBorBottom(a0),windowbottom+1(a5)
	subq	#4,windowleft(a5)
	subq	#4,windowright(a5)
	subq	#2,windowbottom(a5)
	sub	#10,windowtop(a5)
	bpl.b	.olde
	clr	windowtop(a5)
.olde

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
.old

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
 
	moveq	#8,plx1
	move	#523,plx2
	moveq	#13+2,ply1
	move	#147,ply2
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
	moveq	#2,d0			* depth
	move	#WIDTH,d1		* width
	move	#RHEIGHT,d2		* heigth
	lore	GFX,InitBitMap
	move.l	#buffer1,omabitmap+bm_Planes(a5)
	move.l	#buffer1,omabitmap+bm_Planes+4(a5)

	move.l	#buffer1,draw1(a5)	* Buffer pointers for drawing
	move.l	#buffer2,draw2(a5)

	bsr.w	mvoltab

	move.l	owntask(a5),a1		* Set our task to low priority
	moveq	#-30,d0
	lore	Exec,SetTaskPri
	move.l	d0,oldpri(a5)		* Store the old priority

*** Main loop

loop	move.l	_GFXBase(a5),a6		* Wait...
	lob	WaitTOF

	move.l	port(a5),a0		* Check if HiP is playing
	tst.b	hip_play(a0)
	beq.b	.oh
	cmp.b	#33,hip_playertype(a0)	* Playing a Protracker module?
	bne.b	.oh
	bsr.w	dung			* Do the scope
.oh
	move.l	userport(a5),a0		* Get messages from IDCMP
	lore	Exec,GetMsg
	tst.l	d0
	beq.b	loop
	move.l	d0,a1

	move.l	im_Class(a1),d2		
	lob	ReplyMsg
	cmp.l	#IDCMP_CLOSEWINDOW,d2	* Should we exit?
	bne.b	loop
	
	move.l	owntask(a5),a1		* Restore the old priority
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

	moveq	#0,d0			* No error
	rts
	
closel  beq.b   .huh
        move.l  d0,a1
        lore    Exec,CloseLibrary
.huh    rts


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
	move	#2*RHEIGHT*64+WIDTH/16,$dff058

	lob	DisownBlitter		* Free the blitter

	pushm	all
	bsr.w	quadrascope		* Do the scope
	popm	all

	bsr.w	roller			* Do the scroller

	tst	icounter(a5)		* Do the suprise
	beq.b	.oop
	subq	#1,icounter(a5)
	beq.b	.oop
	not.b	icounter2(a5)
	bne.b	.oop
	move	icounter(a5),d0
	and	#15,d0
	add	d0,d0
	move.l	draw1(a5),a0
	lea	WIDTH/8*(RHEIGHT+10)+7(a0),a0
	add	d0,a0
	moveq	#103-1,d0
	lea	hihi(pc),a1
.re	move.l	(a1)+,(a0)
	move.l	(a1)+,4(a0)
	move.l	(a1)+,8(a0)
	move.l	(a1)+,12(a0)
	move	(a1)+,16(a0)
	lea	WIDTH/8(a0),a0
	dbf	d0,.re
.oop


	movem.l	draw1(a5),d0/d1		* Doublebuffering
	exg	d0,d1
	movem.l	d0/d1,draw1(a5)

	lea	omabitmap(a5),a0	* Set the bitplane pointer so bitmap 
	move.l	d1,bm_Planes(a0)
	add.l	#WIDTH/8*RHEIGHT,d1
	move.l	d1,bm_Planes+4(a0)

;	lea	omabitmap(a5),a0	* Copy from bitmap to rastport
	move.l	rastport(a5),a1
	moveq	#0,d0		* source x,y
	moveq	#0,d1
	moveq	#10,d2		* dest x,y
	moveq	#16,d3
	add	windowleft(a5),d2
	add	windowtop(a5),d3
	move.l	#$c0,d6		* minterm a->d
	move.l	#WIDTH,d4	* x-size
	move	#RHEIGHT,d5	* y-size
	lore	GFX,BltBitMapRastPort
	rts



quadrascope
	move.l	port(a5),a3		* Channel data block
	move.l	hip_PTch1(a3),a3
	move.l	draw1(a5),a0
	lea	WIDTH/8/4(a0),a0
	bsr.b	.scope

	move.l	port(a5),a3
	move.l	hip_PTch2(a3),a3
	move.l	draw1(a5),a0
	lea	WIDTH/8/4*2(a0),a0
	bsr.b	.scope

	move.l	port(a5),a3
	move.l	hip_PTch3(a3),a3
	move.l	draw1(a5),a0
	lea	WIDTH/8/4*3(a0),a0
	bsr.b	.scope

	move.l	port(a5),a3
	move.l	hip_PTch4(a3),a3
	move.l	draw1(a5),a0
	lea	WIDTH/8/4*4(a0),a0
	bsr.b	.scope
	rts


.scope
	move.l	PTch_loopstart(a3),d0
	beq.b	.halt
	move.l	PTch_start(a3),d1
	bne.b	.jolt
.halt	rts

.jolt	
	moveq	#0,d3
	move.l	port(a5),a1
	move.b	hip_mainvolume(a1),d3
	mulu	PTch_volume(a3),d3
	lsr	#6,d3			* Volume multiplier
	move	d3,d2

	tst     d3
	bne.b   .heee
	moveq   #1,d3
.heee	subq    #1,d3
	add     d3,d3
	lsl.l   #8,d3
	lea	voltab,a2
	add.l	d3,a2

	move.l	d0,a4
	move.l	d1,a1

	move	PTch_length(a3),d5
	move	PTch_replen(a3),d4

	lea	WIDTH/8-1(a0),a0
	move.l	a0,d6

	moveq	#1,d0
	moveq	#(WIDTH/4-8)/8-1,d7

	moveq	#0,d1			* Height value for the VU-meter
	move.b	(a1)+,d1		
	sub.b	#$80,d1
	muls	d2,d1			
	asr	#7,d1


*** Macro for one pixel

pot	macro
	moveq	#0,d2
	move.b	(a1)+,d2		* Read sampledata
	add	d2,d2
	move	(a2,d2),d2		* Prescaled & multiplied value
	or.b	d0,-WIDTH/8(a0,d2)	* Draw 3 pixels
	or.b	d0,(a0,d2)
	or.b	d0,WIDTH/8(a0,d2)
	add.b	d0,d0
	ifne	\1
	subq	#2,d5			* End of sample?
	bpl.b	.h\2			* No.
	move	d4,d5			* Yes, loop.
	move.l	a4,a1
.h\2	endc
	endm

.url

*** Do 8 pixels
	pot	0,1
	pot	1,2
	pot	0,3
	pot	1,4
	pot	0,5
	pot	1,6
	pot	0,7
	pot	1,8
	moveq	#1,d0			* And loop
	subq	#1,a0
	dbf	d7,.url


*** Vu-meter

	move.l	d6,a0
	lea	-WIDTH/4/8+1(a0),a0
	lea	WIDTH/8*HEIGHT(a0),a0
	lea	WIDTH/8*RHEIGHT(a0),a1
	lea	block+256(pc),a2
	lea	256(a2),a3

	subq	#1,d1
	bmi.b	.x
.rhr	subq	#1,a2
	move.b	-(a2),(a0)
	subq	#1,a3
	move.b	-(a3),(a1)
	lea	-WIDTH/8(a0),a0
	lea	-WIDTH/8(a1),a1
	dbf	d1,.rhr
.x
	rts

multab
aa set 0
	rept	HEIGHT
	dc	aa
aa set aa+WIDTH/8
	endr


*** Precalculate the volume table

mvoltab
        lea	voltab,a0
        moveq   #$40-1,d3
        moveq   #0,d2
.olp2   moveq   #0,d0
        move    #256-1,d4
.olp1   move    d0,d1
	ext     d1
	muls	d2,d1
	asr	#7,d1
	add	#64,d1
	mulu	#WIDTH/8,d1
	move    d1,(a0)+
	addq    #1,d0
	dbf     d4,.olp1
	addq    #1,d2
	dbf     d3,.olp2
	rts               



*** Scroller

roller
	bsr.b	.r
	move.l	draw1(a5),a0
	lea	WIDTH/8*RHEIGHT(a0),a0
	move	.oump(pc),d0
	mulu	#WIDTH/8,d0
	add	d0,a0
	move	.iump(pc),d0
	add	d0,.oump
	cmp	#HEIGHT-8,.oump
	blo.b	.ok
	neg	.iump
.ok

	lea	scrollarea,a1
	moveq	#16*8-1,d0
.c	move.l	(a1)+,(a0)+
	dbf	d0,.c
	rts

.r	bsr.b	.rr
	bsr.b	.rr
	subq	#1,.kountteri
	beq.b	.joo
	rts

.rr	lea	scrollarea+8*WIDTH/8,a0
	move	#8*WIDTH/8/2-1,d0
.sil	roxl	-(a0)
	dbf	d0,.sil
	rts

.joo
	move	#4,.kountteri

	lea	scrollarea+WIDTH/8-1,a0
	lea	font(pc),a1
	move.l	.pointteri(pc),a2
	addq.l	#1,.pointteri

	moveq	#0,d0
	move.b	(a2),d0
	bne.b	.jaa
	move	#5*50,icounter(a5)
	lea	.extia(pc),a3
	move.l	a3,.pointteri
	rts

.jaa
	sub.b	#$20,d0
	add	d0,a1
	moveq	#8-1,d1
.loop1
	move.b	(a1),(a0)
	lea	192(a1),a1
	lea	WIDTH/8(a0),a0
	dbf	d1,.loop1
	rts

.kountteri	dc.w	4
.pointteri	dc.l	.extia
.oump		dc	0
.iump		dc	1

.extia	
 dc.b	"Hello there! This is an external quadrascope for HippoPlayer. "
 dc.b	"Pretty big, isn't it? It uses an area of 512*128 pixels in 4 colors "
 dc.b   "and is still pretty fast ... not! = hArDc0d3 oPt1MizInG ;-)  "
 dc.b   "Each channel consists of 128*3 pixels (total of 1536 pixels).   "
 dc.b	"Anyway, I think BltBitMapRastPort() is the best way for outputting "
 dc.b   "gfx into a window. You can do the actual drawing using demo coder's "
 dc.b   "code and it'd still be system friendly and fast.    "
 dc.b   "BTW, this font is the original topaz.8 from kick1.3 :-]         "
 dc.b   "Time for intel outside...                                       ",0
 even

 
*******************************************************************************
* Window

wflags 	= WFLG_SMART_REFRESH!WFLG_DRAGBAR!WFLG_CLOSEGADGET!WFLG_DEPTHGADGET
idcmpflags = IDCMP_CLOSEWINDOW


winstruc
	dc	54,51	* x,y position
winsiz	dc	532,153	* x,y size
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

.t	dc.b	"External scope for HippoPlayer",0

intuiname	dc.b	"intuition.library",0
gfxname		dc.b	"graphics.library",0
dosname		dc.b	"dos.library",0
portname	dc.b	"HiP-Port",0
 even


*** 2 bitplane 8x128 block
block
	DC.B	$00,$00,$00,$00,$88,$00,$00,$00
	DC.B	$A2,$00,$00,$00,$A8,$00,$00,$00
	DC.B	$AA,$00,$00,$00,$AA,$00,$11,$00
	DC.B	$AA,$00,$40,$00,$AA,$00,$11,$00
	DC.B	$AA,$00,$55,$00,$AA,$00,$55,$00
	DC.B	$AA,$00,$55,$00,$AA,$00,$DD,$00
	DC.B	$AA,$00,$77,$00,$AA,$00,$DD,$00
	DC.B	$AA,$00,$FF,$00,$AA,$00,$FF,$00
	DC.B	$AA,$00,$FF,$00,$BB,$00,$FF,$00
	DC.B	$EE,$00,$FF,$00,$FB,$00,$FF,$00
	DC.B	$FF,$00,$FF,$00,$77,$00,$FF,$00
	DC.B	$DF,$00,$FF,$00,$77,$00,$FF,$00
	DC.B	$55,$00,$FF,$00,$55,$00,$FF,$00
	DC.B	$55,$00,$FF,$00,$55,$00,$EE,$00
	DC.B	$55,$00,$BB,$00,$55,$00,$EE,$00
	DC.B	$55,$00,$AA,$00,$55,$00,$2A,$00
	DC.B	$55,$00,$AA,$00,$55,$00,$22,$00
	DC.B	$55,$00,$08,$00,$55,$00,$22,$00
	DC.B	$55,$00,$00,$00,$55,$00,$00,$00
	DC.B	$55,$00,$00,$00,$44,$00,$00,$00
	DC.B	$01,$00,$00,$00,$44,$00,$00,$00
	DC.B	$00,$00,$00,$00,$80,$00,$00,$00
	DC.B	$02,$00,$00,$00,$88,$00,$00,$00
	DC.B	$AA,$00,$00,$00,$A8,$00,$00,$00
	DC.B	$AA,$00,$00,$00,$AA,$00,$11,$00
	DC.B	$AA,$00,$45,$00,$AA,$00,$11,$00
	DC.B	$AA,$00,$55,$00,$AA,$00,$5D,$00
	DC.B	$AA,$00,$75,$00,$AA,$00,$DD,$00
	DC.B	$AA,$00,$FF,$00,$AA,$00,$DF,$00
	DC.B	$AA,$00,$FF,$00,$AB,$00,$FF,$00
	DC.B	$AE,$00,$FF,$00,$BB,$00,$FF,$00
	DC.B	$FF,$00,$FF,$00,$FB,$00,$FF,$00
	DC.B	$FF,$00,$FF,$00,$FF,$00,$FF,$00
	DC.B	$FF,$00,$FF,$00,$FF,$00,$FF,$00
	DC.B	$FF,$00,$FF,$00,$FF,$00,$FF,$00
	DC.B	$FF,$00,$FF,$00,$FF,$00,$FF,$00
	DC.B	$FF,$00,$FF,$00,$FF,$00,$FF,$00
	DC.B	$FF,$00,$FF,$00,$FF,$00,$FF,$00
	DC.B	$FF,$00,$FF,$00,$FF,$00,$FF,$00
	DC.B	$FF,$00,$FF,$00,$FF,$00,$FF,$00
	DC.B	$FF,$00,$FF,$00,$FF,$00,$FF,$00
	DC.B	$FF,$00,$FF,$00,$FF,$00,$FF,$00
	DC.B	$FF,$00,$FF,$00,$77,$00,$FF,$00
	DC.B	$DF,$00,$FF,$00,$77,$00,$FF,$00
	DC.B	$55,$00,$FF,$00,$55,$00,$FF,$00
	DC.B	$55,$00,$FF,$00,$55,$00,$EE,$00
	DC.B	$55,$00,$BB,$00,$55,$00,$EE,$00
	DC.B	$55,$00,$AA,$00,$55,$00,$2A,$00
	DC.B	$55,$00,$AA,$00,$55,$00,$22,$00
	DC.B	$55,$00,$08,$00,$55,$00,$22,$00
	DC.B	$55,$00,$00,$00,$55,$00,$00,$00
	DC.B	$55,$00,$00,$00,$44,$00,$00,$00
	DC.B	$01,$00,$00,$00,$44,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00

* 144x103x1
hihi
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$FF,$FF,$E0,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$01,$FF,$FF,$FF,$FF,$F0
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$7F,$FF,$FF,$FF
	DC.B	$FF,$FF,$80,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$0F,$FF,$FF
	DC.B	$FF,$FF,$FF,$FF,$80,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$01,$FF
	DC.B	$FF,$FF,$FF,$FF,$FF,$FF,$80,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	DC.B	$80,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$FF,$FF,$FF,$FF,$FF,$FF
	DC.B	$FF,$FF,$80,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$07,$FF,$FF,$FF,$FF
	DC.B	$FF,$FF,$FF,$FF,$80,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$3F,$FF,$FF
	DC.B	$FF,$FF,$FF,$FF,$FF,$FF,$80,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$FF
	DC.B	$FF,$FF,$FF,$FC,$01,$FF,$FF,$FF
	DC.B	$80,$00,$00,$00,$00,$00,$00,$00
	DC.B	$03,$FF,$FF,$FF,$E0,$00,$00,$00
	DC.B	$3F,$FF,$80,$00,$00,$00,$00,$00
	DC.B	$00,$00,$1F,$FF,$FF,$F8,$00,$00
	DC.B	$00,$00,$01,$FF,$80,$00,$00,$00
	DC.B	$00,$00,$00,$00,$7F,$FF,$FF,$00
	DC.B	$00,$00,$00,$00,$00,$1F,$00,$00
	DC.B	$00,$00,$00,$00,$00,$01,$FF,$FF
	DC.B	$F0,$00,$00,$00,$00,$00,$00,$03
	DC.B	$00,$00,$00,$00,$00,$00,$00,$07
	DC.B	$FF,$FF,$00,$00,$01,$FC,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$0F,$FF,$F8,$00,$00,$01,$FC
	DC.B	$00,$7C,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$3F,$FF,$E0,$00,$00
	DC.B	$01,$FC,$00,$7F,$C0,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$FF,$FF,$00
	DC.B	$00,$00,$01,$FC,$00,$67,$FC,$00
	DC.B	$00,$00,$00,$00,$00,$00,$01,$FF
	DC.B	$F8,$00,$00,$00,$01,$FC,$00,$71
	DC.B	$7F,$80,$00,$00,$00,$00,$00,$00
	DC.B	$03,$FF,$E0,$00,$00,$00,$01,$FC
	DC.B	$00,$73,$27,$E0,$00,$00,$00,$00
	DC.B	$00,$00,$0F,$FF,$80,$00,$00,$00
	DC.B	$01,$FC,$00,$73,$07,$FC,$00,$00
	DC.B	$00,$00,$00,$00,$1F,$FE,$00,$00
	DC.B	$80,$00,$00,$FC,$00,$72,$0F,$FE
	DC.B	$00,$00,$00,$00,$00,$00,$3F,$F8
	DC.B	$00,$00,$F0,$00,$00,$FC,$00,$7E
	DC.B	$AF,$FF,$80,$00,$00,$00,$00,$00
	DC.B	$7F,$F0,$00,$00,$FC,$00,$00,$FC
	DC.B	$00,$7F,$EF,$FF,$E0,$00,$00,$00
	DC.B	$00,$01,$FF,$C0,$00,$01,$FC,$00
	DC.B	$00,$FC,$00,$07,$FF,$FF,$F0,$00
	DC.B	$00,$00,$00,$03,$FF,$80,$00,$01
	DC.B	$FC,$78,$00,$FC,$00,$00,$3F,$FF
	DC.B	$FC,$00,$00,$00,$00,$03,$FE,$00
	DC.B	$00,$01,$FF,$F0,$00,$FC,$00,$00
	DC.B	$07,$FF,$FE,$00,$00,$00,$00,$07
	DC.B	$FC,$00,$00,$03,$FF,$E0,$00,$F8
	DC.B	$00,$00,$00,$FF,$FF,$00,$00,$00
	DC.B	$00,$0F,$F8,$00,$00,$0F,$FF,$87
	DC.B	$F0,$F8,$00,$00,$00,$1F,$FF,$80
	DC.B	$00,$00,$00,$1F,$E0,$00,$01,$FF
	DC.B	$FE,$0F,$F8,$F8,$00,$00,$00,$07
	DC.B	$FF,$C0,$00,$00,$00,$3F,$C0,$00
	DC.B	$01,$FF,$FC,$1F,$3C,$78,$00,$00
	DC.B	$00,$01,$FF,$E0,$00,$00,$00,$7F
	DC.B	$80,$00,$01,$FF,$FC,$3E,$3C,$78
	DC.B	$00,$00,$00,$00,$7F,$F0,$00,$00
	DC.B	$00,$FF,$00,$00,$01,$FD,$FC,$3C
	DC.B	$3C,$7C,$00,$00,$00,$00,$3F,$F8
	DC.B	$00,$00,$00,$FE,$00,$00,$00,$41
	DC.B	$FC,$7C,$38,$7C,$00,$00,$00,$00
	DC.B	$0F,$FC,$00,$00,$01,$FC,$00,$00
	DC.B	$00,$01,$FC,$7C,$78,$7C,$00,$00
	DC.B	$00,$00,$07,$FE,$00,$00,$01,$FC
	DC.B	$00,$07,$00,$01,$FC,$78,$F0,$7C
	DC.B	$00,$00,$00,$00,$03,$FE,$00,$00
	DC.B	$03,$F8,$04,$0F,$C0,$01,$FC,$7F
	DC.B	$E0,$7C,$00,$00,$00,$00,$01,$FF
	DC.B	$00,$00,$07,$F0,$0F,$0F,$CF,$C1
	DC.B	$FC,$FF,$80,$7C,$00,$00,$00,$00
	DC.B	$00,$FF,$00,$00,$07,$E0,$0F,$8F
	DC.B	$FF,$E1,$FC,$F8,$00,$7C,$00,$00
	DC.B	$00,$00,$00,$7F,$80,$00,$0F,$E0
	DC.B	$0F,$8F,$FF,$F1,$FC,$F8,$00,$7C
	DC.B	$00,$00,$00,$00,$00,$3F,$80,$00
	DC.B	$0F,$C0,$0F,$0F,$FF,$F1,$FC,$F8
	DC.B	$18,$7C,$00,$00,$00,$00,$00,$1F
	DC.B	$C0,$00,$1F,$80,$00,$0F,$FF,$F1
	DC.B	$FC,$F8,$3C,$7C,$00,$00,$00,$00
	DC.B	$00,$1F,$C0,$00,$1F,$80,$00,$0F
	DC.B	$E7,$F1,$FC,$78,$7C,$7C,$00,$00
	DC.B	$3C,$00,$00,$0F,$C0,$00,$1F,$00
	DC.B	$0F,$0F,$E3,$F1,$FC,$7D,$F8,$7C
	DC.B	$00,$00,$3E,$00,$00,$0F,$E0,$00
	DC.B	$3F,$00,$1F,$8F,$C3,$F1,$FC,$7F
	DC.B	$F0,$7C,$00,$00,$3F,$00,$00,$07
	DC.B	$E0,$00,$3E,$00,$1F,$CF,$C3,$F1
	DC.B	$FC,$3F,$E0,$78,$00,$00,$7F,$00
	DC.B	$00,$07,$E0,$00,$3E,$00,$1F,$CF
	DC.B	$C3,$F1,$FC,$1F,$C0,$00,$00,$00
	DC.B	$7E,$00,$00,$07,$E0,$00,$7E,$00
	DC.B	$1F,$CF,$C3,$F1,$FC,$00,$00,$00
	DC.B	$00,$00,$7E,$00,$00,$03,$F0,$00
	DC.B	$7C,$00,$1F,$CF,$C1,$F0,$FC,$00
	DC.B	$00,$00,$00,$00,$7E,$00,$00,$03
	DC.B	$F0,$00,$7C,$00,$1F,$CF,$C1,$F0
	DC.B	$FC,$00,$00,$00,$38,$00,$7E,$07
	DC.B	$E0,$03,$F0,$00,$7C,$00,$1F,$8F
	DC.B	$C1,$F0,$FC,$00,$00,$00,$7C,$00
	DC.B	$7E,$0F,$F8,$03,$F0,$00,$FC,$00
	DC.B	$1F,$8F,$C1,$F0,$F8,$1F,$00,$00
	DC.B	$7E,$00,$7E,$1F,$3C,$03,$F0,$00
	DC.B	$F8,$00,$1F,$8F,$C1,$F0,$F8,$1F
	DC.B	$00,$00,$7C,$00,$7E,$3E,$3C,$03
	DC.B	$F0,$00,$F8,$00,$0F,$8F,$81,$F0
	DC.B	$60,$1F,$00,$00,$3C,$01,$FE,$3C
	DC.B	$3C,$03,$F0,$00,$F8,$00,$0F,$87
	DC.B	$80,$F0,$00,$1F,$03,$00,$00,$07
	DC.B	$FE,$3C,$38,$03,$E0,$00,$F8,$00
	DC.B	$0F,$87,$80,$F0,$00,$1F,$BF,$00
	DC.B	$00,$0F,$FC,$7C,$78,$03,$E0,$00
	DC.B	$F8,$00,$0F,$80,$00,$70,$00,$3F
	DC.B	$FE,$78,$F0,$1F,$FC,$78,$F0,$07
	DC.B	$E0,$00,$F8,$00,$1F,$80,$00,$00
	DC.B	$00,$FF,$F8,$FC,$F8,$3F,$FC,$7F
	DC.B	$E0,$07,$E0,$00,$F8,$00,$1F,$80
	DC.B	$00,$00,$0F,$FF,$E1,$FC,$FC,$3C
	DC.B	$7C,$FF,$80,$07,$E0,$00,$F8,$00
	DC.B	$1F,$80,$00,$00,$1F,$FF,$C3,$FC
	DC.B	$FC,$7C,$3C,$FC,$00,$07,$E0,$00
	DC.B	$F8,$00,$0F,$80,$00,$00,$1F,$FF
	DC.B	$87,$F8,$FC,$78,$3C,$F8,$00,$07
	DC.B	$E0,$00,$F8,$00,$07,$00,$00,$00
	DC.B	$1F,$FF,$8F,$F0,$FC,$F8,$3C,$F8
	DC.B	$1C,$0F,$C0,$00,$F8,$00,$00,$00
	DC.B	$00,$00,$0F,$1F,$8F,$E0,$FC,$F8
	DC.B	$3C,$F8,$3C,$0F,$C0,$00,$F8,$00
	DC.B	$00,$00,$00,$00,$00,$1F,$8F,$C0
	DC.B	$FC,$F8,$3E,$78,$7C,$1F,$C0,$00
	DC.B	$F8,$00,$00,$00,$00,$00,$00,$1F
	DC.B	$8F,$80,$FC,$F8,$7E,$7C,$F8,$1F
	DC.B	$80,$00,$F8,$00,$00,$00,$00,$00
	DC.B	$0F,$1F,$8F,$80,$FC,$F8,$7E,$7F
	DC.B	$F0,$3F,$80,$00,$F8,$00,$00,$00
	DC.B	$00,$00,$1F,$1F,$8F,$C0,$F8,$F8
	DC.B	$FE,$3F,$E0,$3F,$80,$00,$F8,$00
	DC.B	$00,$00,$00,$08,$1F,$1F,$87,$E0
	DC.B	$F8,$FF,$FE,$1F,$C0,$7F,$00,$00
	DC.B	$7C,$00,$00,$00,$00,$3C,$1F,$1F
	DC.B	$83,$F0,$FC,$FF,$FE,$07,$00,$7F
	DC.B	$00,$00,$7C,$00,$00,$00,$00,$3C
	DC.B	$0F,$1F,$81,$F8,$FC,$FF,$BE,$00
	DC.B	$00,$FE,$00,$00,$7C,$00,$00,$01
	DC.B	$F8,$3C,$0F,$1F,$80,$FC,$7C,$FF
	DC.B	$3E,$00,$01,$FE,$00,$00,$3E,$00
	DC.B	$00,$03,$FC,$7C,$0F,$1F,$80,$7C
	DC.B	$7C,$7E,$3E,$00,$01,$FC,$00,$00
	DC.B	$3E,$00,$00,$07,$FE,$7C,$0F,$1F
	DC.B	$80,$7C,$7C,$38,$3E,$00,$03,$FC
	DC.B	$00,$00,$3E,$00,$00,$0F,$FF,$7C
	DC.B	$0F,$9F,$80,$7C,$7C,$00,$1C,$00
	DC.B	$07,$F8,$00,$00,$1F,$00,$00,$0F
	DC.B	$9F,$7C,$0F,$9F,$80,$FC,$7C,$00
	DC.B	$00,$00,$0F,$F0,$00,$00,$1F,$80
	DC.B	$00,$1F,$0F,$3E,$0F,$9F,$81,$FC
	DC.B	$38,$00,$00,$00,$1F,$F0,$00,$00
	DC.B	$0F,$80,$00,$1F,$0F,$BE,$0F,$9F
	DC.B	$83,$F8,$00,$00,$00,$00,$3F,$E0
	DC.B	$00,$00,$0F,$C0,$00,$1F,$0F,$BE
	DC.B	$0F,$9F,$87,$F8,$00,$00,$00,$00
	DC.B	$7F,$C0,$00,$00,$07,$C0,$00,$1F
	DC.B	$07,$BE,$1F,$9F,$87,$F0,$00,$00
	DC.B	$00,$00,$FF,$80,$00,$00,$07,$E0
	DC.B	$00,$1F,$07,$BF,$1F,$8F,$87,$E0
	DC.B	$00,$00,$00,$01,$FF,$80,$00,$00
	DC.B	$03,$F0,$00,$1F,$07,$9F,$3F,$8F
	DC.B	$83,$80,$00,$00,$00,$07,$FF,$00
	DC.B	$00,$00,$03,$F8,$00,$1F,$07,$9F
	DC.B	$FF,$8F,$80,$00,$00,$00,$00,$0F
	DC.B	$FE,$00,$00,$00,$01,$FC,$00,$1F
	DC.B	$07,$8F,$FF,$87,$00,$00,$00,$00
	DC.B	$00,$3F,$FC,$00,$00,$00,$00,$FE
	DC.B	$00,$1F,$0F,$8F,$FF,$80,$00,$00
	DC.B	$00,$00,$00,$7F,$F8,$00,$00,$00
	DC.B	$00,$7F,$00,$0F,$DF,$87,$F3,$00
	DC.B	$00,$00,$00,$00,$01,$FF,$F0,$00
	DC.B	$00,$00,$00,$3F,$C0,$0F,$FF,$03
	DC.B	$E0,$00,$00,$00,$00,$00,$07,$FF
	DC.B	$C0,$00,$00,$00,$00,$1F,$E0,$07
	DC.B	$FF,$00,$00,$00,$00,$00,$00,$00
	DC.B	$1F,$FF,$80,$00,$00,$00,$00,$0F
	DC.B	$F8,$03,$FE,$00,$00,$00,$00,$00
	DC.B	$00,$00,$7F,$FF,$00,$00,$00,$00
	DC.B	$00,$07,$FE,$01,$FC,$00,$00,$00
	DC.B	$00,$00,$00,$01,$FF,$FC,$00,$00
	DC.B	$00,$00,$00,$03,$FF,$80,$00,$00
	DC.B	$00,$00,$00,$00,$00,$0F,$FF,$F8
	DC.B	$00,$00,$00,$00,$00,$01,$FF,$E0
	DC.B	$00,$00,$00,$00,$00,$00,$00,$7F
	DC.B	$FF,$E0,$00,$00,$00,$00,$00,$00
	DC.B	$7F,$FC,$00,$00,$00,$00,$00,$00
	DC.B	$03,$FF,$FF,$C0,$00,$00,$00,$00
	DC.B	$00,$00,$3F,$FF,$80,$00,$00,$00
	DC.B	$00,$00,$1F,$FF,$FF,$00,$00,$00
	DC.B	$00,$00,$00,$00,$0F,$FF,$F0,$00
	DC.B	$00,$00,$00,$03,$FF,$FF,$FC,$00
	DC.B	$00,$00,$00,$00,$00,$00,$07,$FF
	DC.B	$FF,$80,$00,$00,$00,$7F,$FF,$FF
	DC.B	$F0,$00,$00,$00,$00,$00,$00,$00
	DC.B	$01,$FF,$FF,$FF,$C0,$00,$FF,$FF
	DC.B	$FF,$FF,$C0,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$3F,$FF,$FF,$FF,$FF
	DC.B	$FF,$FF,$FF,$FF,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$0F,$FF,$FF
	DC.B	$FF,$FF,$FF,$FF,$FF,$F8,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$01
	DC.B	$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$3F,$FF,$FF,$FF,$FF,$FF
	DC.B	$FC,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$07,$FF,$FF,$FF
	DC.B	$FF,$FF,$C0,$00,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$7F
	DC.B	$FF,$FF,$FF,$FC,$00,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00,$00,$00
	DC.B	$00,$00,$FF,$FF,$FE,$00,$00,$00
	DC.B	$00,$00,$00,$00,$00,$00


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
scrollarea	ds.b	WIDTH/8*8
voltab		ds	256*64

	section	hihi,bss_c

buffer1	ds.b	WIDTH/8*RHEIGHT*2
buffer2	ds.b	WIDTH/8*RHEIGHT*2

 end

