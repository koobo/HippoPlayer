;APS0000003B0000003B0000003B0000003B0000003B0000003B0000003B0000003B0000003B0000003B

	auto	j\
	auto	wb l:HippoPlayer.key\
	auto	a0\
	auto	a1\

	bsr.b	dokey

	lea	key(pc),a0
	lea	64(a0),a1
	rts
	bra.w	check_key

***** tekee keyfilen

dokey

	lea	key(pc),a4
	lea	name(pc),a3
	bra.b	.l
.ll	move.b	-2(a3),d0
	add.b	d0,-1(a4)
.l	move.b	(a3)+,(a4)+
	bne.b	.ll
	
	lea	key(pc),a0
	moveq	#32-1,d0
	moveq	#0,d2
.cle	moveq	#0,d1
	move.b	(a0)+,d1
	add	d1,d2
	dbf	d0,.cle

	lea	key(pc),a0

	moveq	#%111,d0
	and	d2,d0
	lsl	#1,d0
	move	d0,30(a0)

	lsr	#3,d2
	moveq	#%111,d0
	and	d2,d0
	addq.b	#1,d0
	move	d0,34(a0)
	move	d0,d4

	lsr	#3,d2
	moveq	#%11111,d0
	and	d2,d0
	add	d4,d0
	move.b	d0,32(a0)

	lsr	#5,d2
	moveq	#%11111,d0
	and	d2,d0
	add	d0,d0
	move.b	d0,36(a0)


	lea	key(pc),a0
	moveq	#38-1,d0
	moveq	#0,d1
.k	sub.b	(a0)+,d1
	dbf	d0,.k

	lea	key(pc),a0
	move.l	#"k­P¡",50(a0)
	move.l	#732134,60(a0)

	lea	key(pc),a0
	mulu	#1005,d1
	add.l	d1,d1
	swap	d1
	move.l	d1,56(a0)

	rts

***** Tarkistaa keyfilen

check_key
	lea	key(pc),a4
	move.l	56(a0),d0
	swap	d0
	lsr.l	#1,d0
	divu	#1005,d0

	move.l	a4,a0
	moveq	#38-1,d2
	moveq	#0,d1
.k	sub.b	(a0)+,d1
	dbf	d2,.k

	sub.l	d1,d0
	sne	check1


	move.l	a4,a0
	move	30(a0),d0		* %111
	lsr	#1,d0

	moveq	#0,d1			* %111
	move	34(a0),d1
	move	d1,d2
	subq.b	#1,d1
	lsl	#3,d1
	or.l	d1,d0

	moveq	#0,d1			* %11111
	move.b	32(a0),d1
	sub	d2,d1
	lsl.l	#6,d1
	or.l	d1,d0

	moveq	#0,d1
	move.b	36(a0),d1
	lsl.l	#8,d1
	lsl.l	#2,d1
	or.l	d1,d0

	clr.b	36(a0)
	clr.b	32(a0)
	clr	34(a0)
	clr	30(a0)

	lea	key(pc),a0
	moveq	#32-1,d3
	moveq	#0,d2
.cle	moveq	#0,d1
	move.b	(a0)+,d1
	add	d1,d2
	dbf	d3,.cle

	sub.l	d2,d0
	sne	check2


	lea	key(pc),a4
;	lea	name(pc),a3
	bra.b	.l
.ll	move.b	-2(a4),d0
	sub.b	d0,-1(a4)
.l	tst.b	(a4)+
	bne.b	.ll
	

	rts

check1	dc.b	0
check2	dc.b	0


	dc.b	33
key	ds.b	64
	ds.b	1000

	dc.b	33
name	dc.b	"James T. Kirk",0

