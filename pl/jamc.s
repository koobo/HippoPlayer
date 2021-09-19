;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
testi	=	1

 ifne testi

	incdir	include:
	include mucro.i

	lea	mod,a0
	lea	w(pc),a1
	lea	songend_(pc),a2
	lea	vol(pc),a3
	lea	nullsample,a4
	jsr	init

	
loop
	cmp.b	#$80,$dff006
	bne.b	loop
.x	cmp.b	#$80,$dff006
	beq.b	.x

	move	#$ff0,$dff180
	jsr	play
	clr	$dff180

	btst	#6,$bfe001
	bne.b	loop

	move	#$f,$dff096
	rts

vol	dc	$40

w
dmawait
	pushm	d0/d1
	moveq	#12-1,d1
.d	move.b	$dff006,d0
.k	cmp.b	$dff006,d0
	beq.b	.k
	dbf	d1,.d
	popm	d0/d1
	rts 
songend_	dc	0

endc



	basereg	jam,a6
jam
	jmp	init(pc)
	jmp	play(pc)

* in:
*   a0 = mod
*   a1 = dmawait
*   a2 = songover
*   a3 = main volume
* out:
*   d0 = max song pos

init
	pushm	a5/a6
	lea	jam(pc),a6
	move.l	a0,moduleAddr(a6)
	move.l	a1,dmaWaitAddr(a6)
	move.l	a2,songOverAddr(a6)
	move.l	a3,mainVolAddr(a6)
	move.l	a4,nullSampleAddr(a6)
	bsr.b	jamc_init
	move	SongLength(pc),d0
	popm	a5/a6
	rts

play
	pushm	a5/a6
	lea	jam(pc),a6
	move.l	mainVolAddr(a6),a0
	move	(a0),mainVol(a6)
	bsr.w	jamc_music
	move	SongLength(a6),d0
	sub	CurPos(a6),d0
	popm	a5/a6
	rts


moduleAddr		dc.l	0
dmaWaitAddr		dc.l	0
songOverAddr		dc.l	0
mainVolAddr		dc.l	0
mainVol			dc.w	0
nullSampleAddr		dc.l	0

jamc_init
JAMCC000170	movem.l	D2-D7/A2-A6,-(SP)
	addq.w	#4,A0
	move.w	(A0)+,D0
	move.w	D0,D1
	move.l	A0,JAMCL0007C0(a6)
	mulu	#$28,D0
	add.w	D0,A0
	move.w	(A0)+,D0
	move.w	D0,D2
	move.l	A0,JAMCL0007C4(a6)
	mulu	#6,D0
	add.w	D0,A0
	move.w	(A0)+,D0
	move.w	D0,JAMCW0007BA(a6)
	move.l	A0,JAMCL0007BC(a6)
	add.w	D0,D0
	add.w	D0,A0
	move.l	JAMCL0007C4(a6),A1
	move.w	D2,D0
	subq.w	#1,D0
JAMCC0001B2	move.l	A0,2(A1)
	move.w	(A1),D3
	mulu	#$20,D3
	add.w	D3,A0
	addq.w	#6,A1
	dbra	D0,JAMCC0001B2
	move.l	JAMCL0007C0(a6),A1
	move.w	D1,D0
	subq.w	#1,D0
JAMCC0001CE	move.l	A0,$24(A1)
	move.l	$20(A1),D2
	add.l	D2,A0
	add.w	#$28,A1
	dbra	D0,JAMCC0001CE
	move.l	JAMCL0007BC(a6),JAMCL0007D0(a6)
	move.w	JAMCW0007BA(a6),JAMCW0007D4(a6)
	move.l	JAMCL0007D0(a6),A0
	move.w	(A0),D0
	mulu	#6,D0
	add.l	JAMCL0007C4(a6),D0
	move.l	D0,A0
	move.l	A0,JAMCL0007D6(a6)
	move.b	1(A0),JAMCB0007CA(a6)
	move.l	2(A0),JAMCL0007CC(a6)
	move.b	#6,JAMCB0007C8(a6)
	move.b	#1,JAMCB0007C9(a6)
	move.l	nullSampleAddr(a6),a0
	clr.w	(a0)
	move.w	#15,$DFF096
	lea	JAMCL0007DC(a6),A0
	lea	$DFF0A0,A1
	moveq	#1,D1
	move.w	#$80,D2
	moveq	#3,D0
JAMCC000250	
	move.w	#0,8(A1)
	move.w	D2,(A0)
	move.w	D1,2(A0)
	move.l	A1,4(A0)
	pea	JAMCL000754(a6)
	move.l	(sp)+,14(A0)
	move.w	#$3FB,$12(A0)
	clr.w	$14(A0)
	clr.w	$16(A0)
	clr.l	$18(A0)
	clr.w	$1C(A0)
	clr.l	$1E(A0)
	clr.l	$22(A0)
	move.w	#$40,$26(A0)
	clr.l	$28(A0)
	clr.w	$2C(A0)
	clr.b	$2E(A0)
	add.w	#$30,A0
	add.w	#$10,A1
	add.w	D1,D1
	add.w	#$40,D2
	dbra	D0,JAMCC000250
	bset	#1,$BFE001
JAMCC0002B2	movem.l	(SP)+,D2-D7/A2-A6
	moveq	#0,D0
	rts

jamc_music
JAMCC0002BA	movem.l	D2-D7/A2-A6,-(SP)
	lea	jam(pc),a6
	bsr.s	JAMCC0002C2
	bra.s	JAMCC0002B2

JAMCC0002C2
;	lea	$DFF000,A6
	subq.b	#1,JAMCB0007C9(a6)
	bne.s	JAMCC0002DE
	bsr.w	JAMCC000428
	move.b	JAMCB0007C8(a6),JAMCB0007C9(a6)
JAMCC0002DE	lea	JAMCL0007DC(a6),A1
	bsr.s	JAMCC0002FC
	lea	JAMCL00080C(a6),A1
	bsr.s	JAMCC0002FC
	lea	JAMCL00083C(a6),A1
	bsr.s	JAMCC0002FC
	lea	JAMCL00086C(a6),A1
JAMCC0002FC	move.l	4(A1),A0
JAMCC000300	move.w	$12(A1),D0
	bne.s	JAMCC00030C
	bsr.w	JAMCC000412
	bra.s	JAMCC000300

JAMCC00030C	add.w	$18(A1),D0
	tst.w	$18(A1)
	beq.s	JAMCC00032A
	bpl.s	JAMCC000320
	cmp.w	$1C(A1),D0
	bge.s	JAMCC00032A
	bra.s	JAMCC000326

JAMCC000320	cmp.w	$1C(A1),D0
	ble.s	JAMCC00032A
JAMCC000326	move.w	$1C(A1),D0
JAMCC00032A	add.w	$1E(A1),D0
	cmp.w	#$87,D0
	bge.s	JAMCC00033A
	move.w	#$87,D0
	bra.s	JAMCC000344

JAMCC00033A	cmp.w	#$3FB,D0
	ble.s	JAMCC000344
	move.w	#$3FB,D0
JAMCC000344	move.w	D0,6(A0)
	bsr.w	JAMCC000412
	move.w	$1A(A1),D0
	add.w	D0,$18(A1)
	cmp.w	#$FC05,$18(A1)
	bge.s	JAMCC000364
	move.w	#$FC05,$18(A1)
	bra.s	JAMCC000372

JAMCC000364	cmp.w	#$3FB,$18(A1)
	ble.s	JAMCC000372
	move.w	#$3FB,$18(A1)
JAMCC000372	tst.b	$2C(A1)
	beq.s	JAMCC000390
	move.w	$20(A1),D0
	add.w	D0,$1E(A1)
	subq.b	#1,$2C(A1)
	bne.s	JAMCC000390
	neg.w	$20(A1)
	move.b	$2D(A1),$2C(A1)
JAMCC000390	move.w	2(A1),D0
	* vol
	;move.w	$22(A1),8(A0)
	move.w	$22(A1),d0
	mulu	mainVol(pc),d0
	lsr	#6,d0
	move	d0,8(a0)

	move.w	$24(A1),D0
	add.w	D0,$22(A1)
	tst.w	$22(A1)
	bpl.s	JAMCC0003AE
	clr.w	$22(A1)
	bra.s	JAMCC0003BC

JAMCC0003AE	cmp.w	#$40,$22(A1)
	ble.s	JAMCC0003BC
	move.w	#$40,$22(A1)
JAMCC0003BC	btst	#1,$2E(A1)
	beq.s	JAMCC000410
	tst.w	$2A(A1)
	beq.s	JAMCC000410
	bpl.s	JAMCC0003D0
	clr.w	$2A(A1)
JAMCC0003D0	move.l	10(A1),A0
	move.w	(A1),D0
	neg.w	D0
	lea	0(A0,D0.W),A2
	move.l	A2,A3
	move.w	$28(A1),D0
	lsr.w	#2,D0
	add.w	D0,A3
	moveq	#$3F,D0
JAMCC0003E8	move.b	(A2)+,D1
	ext.w	D1
	move.b	(A3)+,D2
	ext.w	D2
	add.w	D1,D2
	asr.w	#1,D2
	move.b	D2,(A0)+
	dbra	D0,JAMCC0003E8
	move.w	$2A(A1),D0
	add.w	D0,$28(A1)
	cmp.w	#$100,$28(A1)
	blt.s	JAMCC000410
	sub.w	#$100,$28(A1)
JAMCC000410	rts

JAMCC000412	move.w	$12(A1),D0
	move.w	$14(A1),$12(A1)
	move.w	$16(A1),$14(A1)
	move.w	D0,$16(A1)
	rts

JAMCC000428	move.l	JAMCL0007CC(a6),A0
	add.l	#$20,JAMCL0007CC(a6)
	subq.b	#1,JAMCB0007CA(a6)
	bne.s	JAMCC000486
	addq.l	#2,JAMCL0007D0(a6)
	subq.w	#1,JAMCW0007D4(a6)
	bne.s	JAMCC000462
	move.l	JAMCL0007BC(a6),JAMCL0007D0(a6)
	move.w	JAMCW0007BA(a6),JAMCW0007D4(a6)

	move.l	songOverAddr(pc),a1		* SONGEND!!!!
	st	(a1)

JAMCC000462	move.l	JAMCL0007D0(a6),A1
	move.w	(A1),D0
	mulu	#6,D0
	add.l	JAMCL0007C4(a6),D0
	move.l	D0,A1
	move.b	1(A1),JAMCB0007CA(a6)
	move.l	2(A1),JAMCL0007CC(a6)
JAMCC000486	clr.w	JAMCW0007DA(a6)
	lea	JAMCL0007DC(a6),A1
	bsr.w	JAMCC00057C
	addq.w	#8,A0
	lea	JAMCL00080C(a6),A1
	bsr.w	JAMCC00057C
	addq.w	#8,A0
	lea	JAMCL00083C(a6),A1
	bsr.w	JAMCC00057C
	addq.w	#8,A0
	lea	JAMCL00086C(a6),A1
	bsr.w	JAMCC00057C
	move.w	JAMCW0007DA(a6),$dff096

;	move.w	#$12B,D0
;JAMCC0004C6	dbra	D0,JAMCC0004C6
	move.l	dmaWaitAddr(pc),a1
	jsr	(a1)

	lea	JAMCL0007DC(a6),A1
	bsr.b	JAMCC000544
	lea	JAMCL00080C(a6),A1
	bsr.b	JAMCC000544
	lea	JAMCL00083C(a6),A1
	bsr.b	JAMCC000544
	lea	JAMCL00086C(a6),A1
	bsr.b	JAMCC000544
	bset	#7,JAMCW0007DA(a6)
	move.w	JAMCW0007DA(a6),$dff096

;	move.w	#$12B,D0
;JAMCC0004FE	dbra	D0,JAMCC0004FE

	move.l	dmaWaitAddr(pc),a1
	jsr	(a1)

	move.l	JAMCL0007E6(a6),$dff0A0
	move.w	JAMCW0007E4(a6),$dff0A4
	move.l	JAMCL000816(a6),$dff0B0
	move.w	JAMCW000814(a6),$dff0B4
	move.l	JAMCL000846(a6),$dff0C0
	move.w	JAMCW000844(a6),$dff0C4
	move.l	JAMCL000876(a6),$dff0D0
	move.w	JAMCW000874(a6),$dff0D4
	rts

JAMCC000544	move.w	JAMCW0007DA(a6),D0
	and.w	2(A1),D0
	beq.s	JAMCC00057A
	move.l	4(A1),A0
	move.l	10(A1),(A0)
	move.w	8(A1),4(A0)
	move.w	$12(A1),6(A0)
	btst	#0,$2E(A1)
	bne.s	JAMCC00057A
	move.l	nullSampleAddr(a6),10(A1)
	move.w	#1,8(A1)
JAMCC00057A	rts

JAMCC00057C	move.b	(A0),D1
	beq.w	JAMCC00061C
	and.l	#$FF,D1
	add.w	D1,D1

	pea	JAMCB000752(a6)
	add.l	(sp)+,d1
	
	move.l	D1,A2
	btst	#6,2(A0)
	beq.s	JAMCC0005A0
	move.w	(A2),$1C(A1)
	bra.s	JAMCC00061C

JAMCC0005A0	move.w	2(A1),D0
	or.w	D0,JAMCW0007DA(a6)
	move.l	A2,14(A1)
	move.w	(A2),$12(A1)
	move.w	(A2),$14(A1)
	move.w	(A2),$16(A1)
	clr.w	$18(A1)
	move.b	1(A0),D0
	ext.w	D0
	mulu	#$28,D0
	add.l	JAMCL0007C0(a6),D0
	move.l	D0,A2
	tst.l	$24(A2)
	bne.s	JAMCC0005EA
	move.l	nullSampleAddr(a6),10(A1)
	move.w	#1,8(A1)
	clr.b	$2E(A1)
	bra.s	JAMCC00061C

JAMCC0005EA	move.l	$24(A2),A3
	btst	#1,$1F(A2)
	bne.s	JAMCC000602
	move.l	$20(A2),D0
	lsr.l	#1,D0
	move.w	D0,8(A1)
	bra.s	JAMCC00060C

JAMCC000602	move.w	(A1),D0
	add.w	D0,A3
	move.w	#$20,8(A1)
JAMCC00060C	move.l	A3,10(A1)
	move.b	$1F(A2),$2E(A1)
	move.w	$26(A1),$22(A1)
JAMCC00061C	move.b	2(A0),D0
	and.b	#15,D0
	beq.s	JAMCC00062C
	move.b	D0,JAMCB0007C8(a6)
JAMCC00062C	move.l	14(A1),A2
	move.b	3(A0),D0
	beq.s	JAMCC00066C
	cmp.b	#$FF,D0
	bne.s	JAMCC00064A
	move.w	(A2),$12(A1)
	move.w	(A2),$14(A1)
	move.w	(A2),$16(A1)
	bra.s	JAMCC00066C

JAMCC00064A	and.b	#15,D0
	add.b	D0,D0
	ext.w	D0
	move.w	0(A2,D0.W),$16(A1)
	move.b	3(A0),D0
	lsr.b	#4,D0
	add.b	D0,D0
	ext.w	D0
	move.w	0(A2,D0.W),$14(A1)
	move.w	(A2),$12(A1)
JAMCC00066C	move.b	4(A0),D0
	beq.s	JAMCC0006A0
	cmp.b	#$FF,D0
	bne.s	JAMCC000682
	clr.l	$1E(A1)
	clr.b	$2C(A1)
	bra.s	JAMCC0006A0

JAMCC000682	clr.w	$1E(A1)
	and.b	#15,D0
	ext.w	D0
	move.w	D0,$20(A1)
	move.b	4(A0),D0
	lsr.b	#4,D0
	move.b	D0,$2D(A1)
	lsr.b	#1,D0
	move.b	D0,$2C(A1)
JAMCC0006A0	move.b	5(A0),D0
	beq.s	JAMCC0006C6
	cmp.b	#$FF,D0
	bne.s	JAMCC0006B8
	clr.w	$28(A1)
	move.w	#$FFFF,$2A(A1)
	bra.s	JAMCC0006C6

JAMCC0006B8	and.b	#15,D0
	ext.w	D0
	move.w	D0,$2A(A1)
	clr.w	$28(A1)
JAMCC0006C6	move.b	6(A0),D0
	bne.s	JAMCC0006D6
	btst	#7,2(A0)
	beq.s	JAMCC000706
	bra.s	JAMCC0006EA

JAMCC0006D6	cmp.b	#$FF,D0
	bne.s	JAMCC0006E2
	clr.w	$24(A1)
	bra.s	JAMCC000706

JAMCC0006E2	btst	#7,2(A0)
	beq.s	JAMCC0006F8
JAMCC0006EA	move.b	D0,$23(A1)
	move.b	D0,$27(A1)
	clr.w	$24(A1)
	bra.s	JAMCC000706

JAMCC0006F8	bclr	#7,D0
	beq.s	JAMCC000700
	neg.b	D0
JAMCC000700	ext.w	D0
	move.w	D0,$24(A1)
JAMCC000706	move.b	7(A0),D0
	beq.s	JAMCC00074E
	cmp.b	#$FF,D0
	bne.s	JAMCC000718
	clr.l	$18(A1)
	bra.s	JAMCC00074E

JAMCC000718	clr.w	$18(A1)
	btst	#6,2(A0)
	beq.s	JAMCC000732
	move.w	$1C(A1),D1
	cmp.w	$12(A1),D1
	bgt.s	JAMCC000748
	neg.b	D0
	bra.s	JAMCC000748

JAMCC000732	bclr	#7,D0
	bne.s	JAMCC000742
	neg.b	D0
	move.w	#$87,$1C(A1)
	bra.s	JAMCC000748

JAMCC000742	move.w	#$3FB,$1C(A1)
JAMCC000748	ext.w	D0
	move.w	D0,$1A(A1)
JAMCC00074E	rts

JAMCW000750	dc.w	0
JAMCB000752	dcb.b	$2,0

JAMCL000754	dc.l	$3FB03C2,$38C0359,$32902FB,$2D002A8,$282025E
	dc.l	$23C021C,$1FD01E1,$1C601AC,$194017D,$1680154
	dc.l	$141012F,$11E010E,$FE00F0,$E300D6,$CA00BE,$B400AA
	dc.l	$A00097,$8F0087,$870087,$870087,$870087,$870087
	dcb.l	$3,$870087
	dc.w	$87
SongLength
JAMCW0007BA	dc.w	0
JAMCL0007BC	dc.l	0
JAMCL0007C0	dc.l	0
JAMCL0007C4	dc.l	0
JAMCB0007C8	dc.b	0
JAMCB0007C9	dc.b	0
JAMCB0007CA	dcb.b	$2,0
JAMCL0007CC	dc.l	0
JAMCL0007D0	dc.l	0
* Current position (decreasing)
CurPos
JAMCW0007D4	dc.w	0
JAMCL0007D6	dc.l	0
JAMCW0007DA	dc.w	0

Channel1 ; $30 bytes
JAMCL0007DC	dcb.l	$2,0
Ch1SampleLen
JAMCW0007E4	dc.w	0
Ch1SampleAddress
JAMCL0007E6	dcb.l	$9,0
	dc.w	0
Channel2
JAMCL00080C	dcb.l	$2,0
JAMCW000814	dc.w	0
JAMCL000816	dcb.l	$9,0
	dc.w	0
Channel3
JAMCL00083C	dcb.l	$2,0
JAMCW000844	dc.w	0
JAMCL000846	dcb.l	$9,0
	dc.w	0
Channel4
JAMCL00086C	dcb.l	$2,0
JAMCW000874	dc.w	0
JAMCL000876	dcb.l	$9,0
	dc.w	0
	* nullsample!

;JAMCW00089C	dcb.w	$2,0
jame
 endb	a6

 ifne testi

	section	cc,data_c
nullsample	ds.l	1
mod	incbin	sys:music/modsanthology/synth/jamcrack/jam.dr-awesome-3
 endc
