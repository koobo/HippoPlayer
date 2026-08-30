
	incdir	include:
	include	"exec/exec_lib.i"
	include	graphics/gfxbase.i
	include	graphics/graphics_lib.i
	include	graphics/rastport.i

	include	intuition/intuition_lib.i
	include	intuition/intuition.i


	include	mucro.i
	incdir	

	rsreset
_ExecBase	rs.l	1
_GFXBase	rs.l	1
_IntuiBase	rs.l	1
windowbase	rs.l	1
rastport	rs.l	1
userport	rs.l	1
wbscreen	rs.l	1
wbkorkeus	rs	1
wbleveys	rs	1
windowtop	rs	1

lev		rs	1
kork		rs	1

omabitmap	rs.b	bm_SIZEOF
draw1		rs.l	1
draw2		rs.l	1


size_var	rs.b	0


	lea	var_b,a5

	move.l	4.w,(a5)
	move.l	(a5),a6

	lea	gfxn(pc),a1
	lob	OldOpenLibrary
	move.l	d0,_GFXBase(a5)
	beq.w	exit
	lea	intn(pc),a1
	lob	OldOpenLibrary
	move.l	d0,_IntuiBase(a5)
	beq.w	exit

*** Initialisoidaan oma bitmappi

	move.l	_IntuiBase(a5),a6
	lea	winstruc(pc),a0
	lob	OpenWindow
	move.l	d0,windowbase(a5)
	beq.w	exit
	move.l	d0,a0
	move.l	wd_RPort(a0),rastport(a5)
	move.l	wd_UserPort(a0),userport(a5)

	move.l	d0,a0
	move.l	wd_WScreen(a0),a1		* WB screen addr
	move.l	a1,wbscreen(a5)
	move	sc_Width(a1),wbleveys(a5)	* WB:n leveys
	move	sc_Height(a1),wbkorkeus(a5)	* WB:n korkeus
	move.b	sc_BarHeight(a1),windowtop+1(a5) * palkin korkeus
	sub	#10,windowtop(a5)


	move.l	windowbase(a5),a1

	moveq	#0,d1
	moveq	#0,d2
	move	wd_Width(a5),d1
	move	wd_Height(a5),d2
	sub	#20,d1
	sub	#20,d2
	move	d1,lev(a5)
	move	d2,kork(a5)
	
	lea	omabitmap(a5),a0
	moveq	#1,d0
	lore	GFX,InitBitMap

	move.l	#screen2,omabitmap+bm_Planes(a5)

	move.l	#screen,draw1(a5)
	move.l	#screen2,draw2(a5)





	bsr.w	makedivtable
	bsr.w	makestartable

qloop
	lore	GFX,WaitTOF

	bsr	droo

	move.l	userport(a5),a0
	lore	Exec,GetMsg
	tst.l	d0
	beq.b	qloop
	move.l	d0,a1

	move.l	im_Class(a1),d2		* luokka	
	lob	ReplyMsg
	cmp.l	#IDCMP_CLOSEWINDOW,d2
	beq.b	exit
	cmp.l	#IDCMP_NEWSIZE,d2
	bne.b	qloop
	bchg	#1,$bfe001
	bra	qloop
	
exit




	move.l	windowbase(a5),d0
	beq.b	.uh1
	move.l	d0,a0
	move.l	_IntuiBase(a5),a6		
	lob	CloseWindow
.uh1

	move.l	_IntuiBase(a5),d0
	bsr.b	closel
	move.l	_GFXBase(a5),d0
	bsr.b	closel


	moveq	#0,d0
	rts	

closel	beq.b	.nopel
	move.l	d0,a1
	move.l	(a5),a6
	lob	CloseLibrary
.nopel	rts

gfxn	dc.b	"graphics.library",0
intn	dc.b	"intuition.library",0
 even

wflags set WFLG_SMART_REFRESH!WFLG_DRAGBAR!WFLG_CLOSEGADGET!WFLG_DEPTHGADGET
wflags set wflags!WFLG_SIZEGADGET
idcmpflags = IDCMP_CLOSEWINDOW!IDCMP_NEWSIZE

winstruc
	dc	0,0		* paikka
	dc	340,120		* koko
	dc.b	2,1	;palkin värit
	dc.l	idcmpflags
	dc.l	wflags
	dc.l	0
	dc.l	0	
	dc.l	.ti
	dc.l	0
	dc.l	0	
	dc	64,64	* min
	dc	640,256	* max
	dc	WBENCHSCREEN
;	dc.l	enw_tags
	dc.l	0

.ti	dc.b	"Blah ikkuna",0



droo
***************** Piirretään

	lore	GFX,OwnBlitter
	lob	WaitBlit

	move.l	draw2(a5),$dff054	* tyhjennetään piirtoalue
	move	#0,$dff066
	move.l	#$01000000,$dff040
	move	#100*64+20,$dff058

;	lob	WaitBlit
	lob	DisownBlitter

	move.l	draw1(a5),a0
	move	#(100*40)/16-1,d0
	moveq	#-1,d1
.er	
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	dbf	d0,.er


	bsr	stareffect
	bsr	sindirec
	
	move.l	draw1(a5),d0
	move.l	draw2(a5),d1
	move.l	d1,draw1(a5)
	move.l	d0,draw2(a5)


	lea	omabitmap(a5),a0
	move.l	d0,bm_Planes(a0)


	move.l	rastport(a5),a1
	moveq	#0,d0		* lähde x,y
	moveq	#0,d1
	moveq	#10,d2		* kohde x,y
	moveq	#15,d3
	move.l	#$c0,d6		* minterm, suora kopio a->d
	move.l	#320,d4		* x-koko
	moveq	#100,d5		* y-koko
	lore	GFX,BltBitMapRastPort

	rts
 


stareffect

nstars = 1400	* neljällä jaollinen!

stars	
	movem.l	d0-a6,-(sp)
	bsr.b	rars
	movem.l	(sp)+,d0-a6
	rts

rars
	
	lea	startable(pc),a5

	move	#(nstars/4)-1,d7

	move	#$7ff*2,d5

	movem	sdir(pc),d0-d2

dloo	
	rept	4
	add	d2,(a5)
	and	d5,(a5)+
	add	d0,(a5)+
	add	d1,(a5)+
	endr

	dbf	d7,dloo

	lea	xtab(pc),a6
	lea	startable(pc),a5
	lea	divtable(pc),a3
	lea	multable(pc),a4
	move.l	draw1+var_b,a0
	lea	39(a0),a0


;	lea	39(a0),a0
;	move	#127,d7
;	move	#255,d5
;	move	#160,d4
;	move	#319,a2

	move	#50,d7
	move	#100-1,d5
	move	#160,d4
	move	#319,a2

	move	#nstars-1,d6

ploo
	movem	(a5)+,d1-d3

	move	(a3,d1),d0
	beq.b	nextus

	muls	d0,d3
	swap	d3
	add	d7,d3
	cmp	d5,d3
	bhi.b	nextus

	muls	d0,d2
	add.l	d2,d2
	swap	d2
	add	d4,d2
	cmp	a2,d2
	bhi.b	nextus

	add	d3,d3
	move	(a4,d3),d0

	move	d2,d3
	lsr	#3,d3
	sub	d3,d0

;	lsr	#8,d1
;	lsr	#2,d1

	bclr	d2,(a0,d0)

nextus	dbf	d6,ploo
	rts


makestartable				;randomoidaan tähdet
	lea	startable(pc),a0
	lea	divtable(pc),a1
	move.l	#nstars-1,d2
nsloop
	bsr.s	newstarz
 	add	d0,d0
	move.w	d0,(a0)+
	bsr.s	newstar
	move.w	d0,(a0)+
	bsr.s	newstar
	move.w	d0,(a0)+
	dbf	d2,nsloop
	rts
newstar	
	moveq	#0,d0
	moveq	#0,d1
	move.b	$dff007,d0
	move.b	$bfd800,d1
	eor.b	d1,d0
	muls	d1,d0
	beq.b	newstar
	ext	d0
	asl	#8,d0
	rts

newstarz
	moveq	#0,d0
	moveq	#0,d1
	move.b	$dff007,d0
	move.b	$bfd800,d1
	eor.b	d1,d0
	muls	d1,d0
	ext	d0
	and	#$7f,d0
	asl	#4,d0
	rts

makedivtable
	lea	divtable(pc),a0
	moveq	#1,d1
dlop	move.l	#$20000,d0
	divs	d1,d0
	move	d0,(a0)+
	addq	#1,d1
	cmp	#1024*2,d1
	blo.b	dlop
	rts



sindirec
	lea	sine1(pc),a0
	lea	sdir(pc),a1
	lea	sinep(pc),a2
	movem	(a2),d0-d5
	move	(a0,d0),d0
	move	(a0,d1),d1
	move	(a0,d2),d2
	add	(a0,d3),d0
	add	(a0,d4),d1
	add	(a0,d5),d2
	lsr	#1,d0
	lsr	#1,d1
	lsr	#1,d2

	moveq	#14,d3
	sub	d0,d3
	asl	#7,d3
	move	d3,(a1)+

	moveq	#14,d3
	sub	d1,d3
	asl	#7,d3
	move	d3,(a1)+

	moveq	#14,d3
	sub	d2,d3
	mulu	#3,d3
	move	d3,(a1)

	addq	#8,(a2)
	addq	#4,2(a2)
;	addq	#0,4(a2)

	addq	#4,6(a2)
	addq	#6,8(a2)
	add	#2,10(a2)

	moveq	#6-1,d0
	
test	cmp	#1000*2,(a2)
	blo.b	nok
	sub	#1000*2,(a2)
nok	addq	#2,a2
	dbf	d0,test
	rts


sdir	dc	0*32	;sivusuunta
	dc	0*32	;pustusuunta
	dc	-12*2	;suvuussuunta


startable ds	3*nstars

multable
a set 0
	rept	100
	dc	a
a set a+40
	endr


divtable 
	ds	1024*2
	
xtab
aa set 0
	rept	320
	dc.b	aa>>3
	dc.b	(1<<(~aa&$7))
aa set aa+1
	endr
 even

sine1	
	DC.W	$000E,$000E,$000E,$000E,$000E,$000E,$000E,$000E
	DC.W	$000E,$000E,$000E,$000E,$000F,$000F,$000F,$000F
	DC.W	$000F,$000F,$000F,$000F,$000F,$000F,$000F,$0010
	DC.W	$0010,$0010,$0010,$0010,$0010,$0010,$0010,$0010
	DC.W	$0010,$0010,$0010,$0011,$0011,$0011,$0011,$0011
	DC.W	$0011,$0011,$0011,$0011,$0011,$0011,$0011,$0012
	DC.W	$0012,$0012,$0012,$0012,$0012,$0012,$0012,$0012
	DC.W	$0012,$0012,$0012,$0013,$0013,$0013,$0013,$0013
	DC.W	$0013,$0013,$0013,$0013,$0013,$0013,$0013,$0014
	DC.W	$0014,$0014,$0014,$0014,$0014,$0014,$0014,$0014
	DC.W	$0014,$0014,$0014,$0014,$0015,$0015,$0015,$0015
	DC.W	$0015,$0015,$0015,$0015,$0015,$0015,$0015,$0015
	DC.W	$0015,$0016,$0016,$0016,$0016,$0016,$0016,$0016
	DC.W	$0016,$0016,$0016,$0016,$0016,$0016,$0016,$0016
	DC.W	$0017,$0017,$0017,$0017,$0017,$0017,$0017,$0017
	DC.W	$0017,$0017,$0017,$0017,$0017,$0017,$0017,$0018
	DC.W	$0018,$0018,$0018,$0018,$0018,$0018,$0018,$0018
	DC.W	$0018,$0018,$0018,$0018,$0018,$0018,$0018,$0018
	DC.W	$0019,$0019,$0019,$0019,$0019,$0019,$0019,$0019
	DC.W	$0019,$0019,$0019,$0019,$0019,$0019,$0019,$0019
	DC.W	$0019,$0019,$0019,$0019,$001A,$001A,$001A,$001A
	DC.W	$001A,$001A,$001A,$001A,$001A,$001A,$001A,$001A
	DC.W	$001A,$001A,$001A,$001A,$001A,$001A,$001A,$001A
	DC.W	$001A,$001A,$001A,$001A,$001A,$001A,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001C,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001B
	DC.W	$001B,$001B,$001B,$001B,$001B,$001B,$001B,$001A
	DC.W	$001A,$001A,$001A,$001A,$001A,$001A,$001A,$001A
	DC.W	$001A,$001A,$001A,$001A,$001A,$001A,$001A,$001A
	DC.W	$001A,$001A,$001A,$001A,$001A,$001A,$001A,$001A
	DC.W	$001A,$0019,$0019,$0019,$0019,$0019,$0019,$0019
	DC.W	$0019,$0019,$0019,$0019,$0019,$0019,$0019,$0019
	DC.W	$0019,$0019,$0019,$0019,$0019,$0018,$0018,$0018
	DC.W	$0018,$0018,$0018,$0018,$0018,$0018,$0018,$0018
	DC.W	$0018,$0018,$0018,$0018,$0018,$0018,$0017,$0017
	DC.W	$0017,$0017,$0017,$0017,$0017,$0017,$0017,$0017
	DC.W	$0017,$0017,$0017,$0017,$0017,$0016,$0016,$0016
	DC.W	$0016,$0016,$0016,$0016,$0016,$0016,$0016,$0016
	DC.W	$0016,$0016,$0016,$0016,$0015,$0015,$0015,$0015
	DC.W	$0015,$0015,$0015,$0015,$0015,$0015,$0015,$0015
	DC.W	$0015,$0014,$0014,$0014,$0014,$0014,$0014,$0014
	DC.W	$0014,$0014,$0014,$0014,$0014,$0014,$0013,$0013
	DC.W	$0013,$0013,$0013,$0013,$0013,$0013,$0013,$0013
	DC.W	$0013,$0013,$0012,$0012,$0012,$0012,$0012,$0012
	DC.W	$0012,$0012,$0012,$0012,$0012,$0012,$0011,$0011
	DC.W	$0011,$0011,$0011,$0011,$0011,$0011,$0011,$0011
	DC.W	$0011,$0011,$0010,$0010,$0010,$0010,$0010,$0010
	DC.W	$0010,$0010,$0010,$0010,$0010,$0010,$000F,$000F
	DC.W	$000F,$000F,$000F,$000F,$000F,$000F,$000F,$000F
	DC.W	$000F,$000E,$000E,$000E,$000E,$000E,$000E,$000E
	DC.W	$000E,$000E,$000E,$000E,$000E,$000D,$000D,$000D
	DC.W	$000D,$000D,$000D,$000D,$000D,$000D,$000D,$000D
	DC.W	$000C,$000C,$000C,$000C,$000C,$000C,$000C,$000C
	DC.W	$000C,$000C,$000C,$000B,$000B,$000B,$000B,$000B
	DC.W	$000B,$000B,$000B,$000B,$000B,$000B,$000B,$000A
	DC.W	$000A,$000A,$000A,$000A,$000A,$000A,$000A,$000A
	DC.W	$000A,$000A,$000A,$0009,$0009,$0009,$0009,$0009
	DC.W	$0009,$0009,$0009,$0009,$0009,$0009,$0009,$0008
	DC.W	$0008,$0008,$0008,$0008,$0008,$0008,$0008,$0008
	DC.W	$0008,$0008,$0008,$0007,$0007,$0007,$0007,$0007
	DC.W	$0007,$0007,$0007,$0007,$0007,$0007,$0007,$0007
	DC.W	$0006,$0006,$0006,$0006,$0006,$0006,$0006,$0006
	DC.W	$0006,$0006,$0006,$0006,$0006,$0005,$0005,$0005
	DC.W	$0005,$0005,$0005,$0005,$0005,$0005,$0005,$0005
	DC.W	$0005,$0005,$0005,$0005,$0004,$0004,$0004,$0004
	DC.W	$0004,$0004,$0004,$0004,$0004,$0004,$0004,$0004
	DC.W	$0004,$0004,$0004,$0003,$0003,$0003,$0003,$0003
	DC.W	$0003,$0003,$0003,$0003,$0003,$0003,$0003,$0003
	DC.W	$0003,$0003,$0003,$0003,$0002,$0002,$0002,$0002
	DC.W	$0002,$0002,$0002,$0002,$0002,$0002,$0002,$0002
	DC.W	$0002,$0002,$0002,$0002,$0002,$0002,$0002,$0002
	DC.W	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	DC.W	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	DC.W	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	DC.W	$0001,$0001,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	DC.W	$0000,$0000,$0000,$0001,$0001,$0001,$0001,$0001
	DC.W	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	DC.W	$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
	DC.W	$0001,$0001,$0001,$0001,$0001,$0002,$0002,$0002
	DC.W	$0002,$0002,$0002,$0002,$0002,$0002,$0002,$0002
	DC.W	$0002,$0002,$0002,$0002,$0002,$0002,$0002,$0002
	DC.W	$0002,$0003,$0003,$0003,$0003,$0003,$0003,$0003
	DC.W	$0003,$0003,$0003,$0003,$0003,$0003,$0003,$0003
	DC.W	$0003,$0003,$0004,$0004,$0004,$0004,$0004,$0004
	DC.W	$0004,$0004,$0004,$0004,$0004,$0004,$0004,$0004
	DC.W	$0004,$0005,$0005,$0005,$0005,$0005,$0005,$0005
	DC.W	$0005,$0005,$0005,$0005,$0005,$0005,$0005,$0005
	DC.W	$0006,$0006,$0006,$0006,$0006,$0006,$0006,$0006
	DC.W	$0006,$0006,$0006,$0006,$0006,$0007,$0007,$0007
	DC.W	$0007,$0007,$0007,$0007,$0007,$0007,$0007,$0007
	DC.W	$0007,$0007,$0008,$0008,$0008,$0008,$0008,$0008
	DC.W	$0008,$0008,$0008,$0008,$0008,$0008,$0009,$0009
	DC.W	$0009,$0009,$0009,$0009,$0009,$0009,$0009,$0009
	DC.W	$0009,$0009,$000A,$000A,$000A,$000A,$000A,$000A
	DC.W	$000A,$000A,$000A,$000A,$000A,$000A,$000B,$000B
	DC.W	$000B,$000B,$000B,$000B,$000B,$000B,$000B,$000B
	DC.W	$000B,$000B,$000C,$000C,$000C,$000C,$000C,$000C
	DC.W	$000C,$000C,$000C,$000C,$000C,$000D,$000D,$000D
	DC.W	$000D,$000D,$000D,$000D,$000D,$000D,$000D,$000D

sinep	ds	6
	



	section	ocm,bss_p

var_b	ds.b	size_var

	section	chup,bss_c

plane	=	320/8*102

screen	ds.b	plane
screen2	ds.b	plane

 end


