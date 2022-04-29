;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
start	lea	player(pc),a3
	lea	myPlayer,a0
	lea	mySong,a1
	lea	song0,a2
	add.l	(a3),a3
	jsr	(a3)		; songInit

	lea	player(pc),a3
	lea	myPlayer,a0
	lea	chipmem,a1
	lea	mySong,a2
	add.l	4(a3),a3
	jsr	(a3)		; playerInit

.loop	btst	#6,$bfe001
	beq	.exit
;	jsr	waitVbl
;	move	#$f00,$dff180

	lea	player(pc),a1
	lea	myPlayer,a0
	add.l	8(a1),a1
	jsr	(a1)		; playerTick

	bsr	dodiff
;	bsr	copy
	
;	move	#0,$dff180
	bra	.loop
.exit	rts

waitVbl	
.0	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#80<<8,d0
	beq	.0

.1	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#80<<8,d0
	bne	.1
	rts

NUM=256
SIZ=16*1024

copy
	lea	myPlayer,a0
	lea	myPlayerCopy,a1
	move	#SIZ-1,d0
.c	
	move.b	(a0)+,(a1)+
	dbf	d0,.c

	rts

	move	toggle,d0
	bne	.skip
	
	lea	myPlayer,a0
	move	copyIndex,d0
	cmp	#NUM,d0
	bhs.b	.stop
	addq	#1,copyIndex

	mulu	#SIZ,d0
	lea	myPlayerCopy,a1
	add.l	d0,a1
	move	#SIZ-1,d0
.c1	
	move.b	(a0)+,(a1)+
	dbf	d0,.c1

	move	#$0f0,$dff180
.skip
	addq	#1,toggle
	and	#3,toggle
	rts	
.stop
	move	#$f00,$dff180
	rts

dodiff
	lea	myPlayer,a0
	lea	myPlayerCopy,a1
	lea	diff,a2
	moveq	#0,d0
loop
	move.b	(a0,d0),d2
	cmp.b	(a1,d0),d2
	beq.b	same
bob
	move.b	d2,(a1,d0)
	move.b	d2,(a2)+
	bra.w	diff2
same	
	clr.b	(a2)+
diff2
	addq	#1,d0
	cmp	#SIZ,d0
	bne.b	loop
	
	rts

* 1: -28
* 2: $668
* 3: +28
* 4: +44

	incdir  "p:pl/bin/"
player	incbin	"pretracker-orig.bin"
;song0	incbin	"sys:music/pretracker/prefix.prt"
;song0	incbin	"m:exo/pretracker/prt.break your limits 2019"
;song0	incbin	"m:exo/pretracker/serpent - shinnos delight.prt"
;song0	incbin	"m:exo/pretracker/pink - rewind.prt" ; len $32
song0	incbin	"m:exo/pretracker/pink - ub42.prt" ; len $10
;song0	incbin	"m:exo/pretracker/pink - wesley bitcrusher.prt" ; len $1d

* song length at module offset: 62

copyIndex	dc	0
toggle		dc	0

diff	ds.b	SIZ
	dc.b	"*******************************************"
	dc.b	"*******************************************"
	dc.b	"*******************************************"
	dc.b	"*******************************************"
	dc.b	"*******************************************"
	dc.b	"*******************************************"

	section bss,bss
mySong		ds.w	16*1024/2
myPlayer	ds.b	SIZ

myPlayerCopy
	ds.b	SIZ


	

	section	chip,bss_c
chipmem	ds.b	128*1024
	ds.b	$30000
