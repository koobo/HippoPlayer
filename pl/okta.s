
* init: 0
* play: 526
* end: 52
* volume: 4096

	section	efdc,code_c

	incdir	include:
	include	exec/exec_lib.i
	include	exec/memory.i
	include	mucro.i

testi	=	0

 ifne testi

	lea	mod,a0
	lea	$100,a1
	bsr	ok_init
;	move	#$4000,$dff09a

loop
	move.l	$dff004,d0
	and.l	#$1ff00,d0
	lsr.l	#8,d0
	cmp.l	#80,d0
	bne.b	loop

	move	#$ff0,$dff180
	bsr	ok_music
	clr	$dff180

	btst	#6,$bfe001
	bne.b	loop

	bsr	ok_end
	move	#$c000,$dff09a
	rts
 endc

ok_init
	move.l	a0,song
	move.l	a1,songend
	move.l	song(pc),a0
	bsr.w	ok_0001AC
	rts

ok_songo
	move.w	ok_0002C6,ok_001220
	move.l	a0,-(sp)
	move.l	songend(pc),a0		* songend
	st	(a0)
	move.l	(sp)+,a0
	rts

songend	dc.l	0
song	dc.l	0

ok_end	bra	ok_end2


ok_0001AC
	movem.l	D0-D7/A0-A6,-(SP)
	move.w	D0,-(SP)
	bsr	ok_00112A
	addq.w	#8,A0
	move.l	A0,ok_0002B6
	move.l	#$434D4F44,D0
	bsr	ok_000290
	lea	ok_0002BE(PC),A1
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	#$53414D50,D0
	bsr	ok_000290
	lea	ok_001244,A1
	move.w	#$47F,D0
ok_0001E4	move.b	(A0)+,(A1)+
	dbra	D0,ok_0001E4
	move.l	#$53504545,D0
	bsr	ok_000290
	move.w	(A0)+,ok_0002C6
	move.l	#$534C454E,D0
	bsr	ok_000290
	move.w	(A0)+,ok_00028A
	move.l	#$504C454E,D0
	bsr	ok_000290
	move.w	(A0)+,ok_0002C8
	move.l	#$50415454,D0
	bsr	ok_000290
	lea	ok_0016C4,A1
	moveq	#$7F,D0
ok_00022C	move.b	(A0)+,(A1)+
	dbra	D0,ok_00022C
	lea	ok_001744,A1
	moveq	#0,D7
ok_00023A	move.l	#$50424F44,D0
	bsr	ok_000290
	move.l	A0,(A1)+
	addq.w	#1,D7
	cmp.w	ok_00028A(PC),D7
	bne.s	ok_00023A
	lea	ok_001258,A5
	lea	ok_001844,A1
	moveq	#0,D7
ok_00025C	tst.l	(A5)
	beq.s	ok_000270
	move.l	#$53424F44,D0
	bsr	ok_000290
	move.l	A0,(A1)
	move.l	D0,4(A1)
ok_000270	addq.w	#8,A1
	lea	$20(A5),A5
	addq.w	#1,D7
	cmp.w	#$24,D7
	bne.s	ok_00025C
	move.w	(SP)+,D0
	bsr	ok_0002CC
	movem.l	(SP)+,D0-D7/A0-A6
	rts

ok_00028A	dcb.w	$3,0

ok_000290	movem.l	D2/D3,-(SP)
	move.l	ok_0002B6(PC),A0
ok_000298	movem.l	(A0)+,D2/D3
	cmp.l	D2,D0
	beq.s	ok_0002A4
	add.l	D3,A0
	bra.s	ok_000298

ok_0002A4	add.l	D3,A0
	move.l	A0,ok_0002B6
	sub.l	D3,A0
	move.l	D3,D0
	movem.l	(SP)+,D2/D3
	rts

ok_0002B6	dc.l	0


ok_0002BE	dcb.l	$2,0
ok_0002C6	dc.w	0
ok_0002C8	dcb.w	$2,0

ok_0002CC	lea	ok_00083C(PC),A0
	tst.b	D0
	beq.s	ok_0002D8
	lea	ok_000880(PC),A0
ok_0002D8	move.l	A0,ok_000838
	bsr	ok_00103A
	moveq	#0,D1
	lea	ok_001964,A0
	moveq	#15,D0
ok_0002EC	move.l	D1,(A0)+
	dbra	D0,ok_0002EC
	lea	ok_001A86,A0
	lea	ok_002346,A1
	move.w	#$22F,D0
ok_000302	move.l	D1,(A0)+
	move.l	D1,(A1)+
	dbra	D0,ok_000302
	lea	ok_0002BE,A0
	moveq	#0,D1
	moveq	#3,D0
ok_000314	or.w	(A0)+,D1
	ror.w	#1,D1
	dbra	D0,ok_000314
	ror.w	#5,D1
	move.w	D1,ok_000382
	lea	$DFF000,A6
	move.w	#15,$96(A6)
	lea	ok_001A34,A0
	move.l	A0,$A0(A6)
	move.l	A0,$B0(A6)
	move.l	A0,$C0(A6)
	move.l	A0,$D0(A6)
	moveq	#$29,D0
	move.w	D0,$A4(A6)
	move.w	D0,$B4(A6)
	move.w	D0,$C4(A6)
	move.w	D0,$D4(A6)
	move.w	#$358,D0
	move.w	D0,$A6(A6)
	move.w	D0,$B6(A6)
	move.w	D0,$C6(A6)
	move.w	D0,$D6(A6)
	move.w	#$FF,$9E(A6)
	bsr	ok_0011AC
	bsr	ok_0011AC
	st	ok_000384
	rts

ok_000382	dc.w	0
ok_000384	dcb.b	$2,0

ok_music
ok_000386	move.b	ok_000384(PC),D0
	beq.s	ok_00039A
	move.w	#$800F,$DFF096
	sf	ok_000384
ok_00039A	bsr	ok_0006E8
	bsr	ok_0008C4
	lea	ok_0019C4,A0
	lea	ok_000830(PC),A2
	move.l	(A2)+,A1
	move.l	(A2),-(A2)
	move.l	A1,4(A2)
	moveq	#0,D0
ok_0003B6	tst.w	(A0)
	beq.s	ok_0003C6
	movem.l	D0/A0-A2,-(SP)
	bsr	ok_0003DA
	movem.l	(SP)+,D0/A0-A2
ok_0003C6	lea	$1C(A0),A0
	lea	$230(A1),A1
	addq.w	#1,D0
	cmp.w	#4,D0
	bne.s	ok_0003B6
	bra	ok_00073C

ok_0003DA	tst.l	2(A0)
	beq.s	ok_00040E
	tst.l	$10(A0)
	beq.s	ok_000412
	bsr	ok_00041A
	move.w	D1,D2
	lea	14(A0),A0
	bsr	ok_00041A
	cmp.w	D1,D2
	blt.s	ok_000402
	move.l	A1,A2
	lea	-14(A0),A1
	bra	ok_000434

ok_000402	move.l	A1,A2
	lea	-14(A0),A1
	exg	A0,A1
	bra	ok_000434

ok_00040E	lea	14(A0),A0
ok_000412	bsr	ok_00041A
	bra	ok_00065E

ok_00041A	move.w	10(A0),D1
	bpl.s	ok_000426
	clr.w	10(A0)
	rts

**************************
ok_000426
	cmp.w	#$21,D1
	ble.s	ok_000432
	move.w	#$21,10(A0)
ok_000432	rts

ok_000434	lea	ok_001964,A3
	lsl.w	#4,D0
	add.w	D0,A3
	move.w	10(A1),D0
	add.w	D0,D0
	lea	ok_0011CC,A4
	move.w	0(A4,D0.W),D2
	move.w	D2,4(A3)
	move.w	10(A0),D3
	add.w	D3,D3
	move.w	0(A4,D3.W),D3
	move.l	ok_000838(PC),A4
	move.w	0(A4,D0.W),D1
	add.w	8(A3),D1
	move.w	D1,6(A3)
	swap	D2
	clr.w	D2
	divu	D3,D2
	move.l	6(A0),D0
	lsr.l	#1,D0
	move.l	A2,(A3)
	movem.l	D0/A0/A1,-(SP)
	move.l	2(A0),A0
	move.l	A2,A1
	bsr	ok_000568
	move.l	A0,A4
	movem.l	(SP)+,D1/A0/A1
	sub.w	D0,D1
	bhs.s	ok_0004A4
	clr.l	2(A0)
	clr.l	6(A0)
	clr.w	10(A0)
	clr.w	12(A0)
	bra.s	ok_0004AE

ok_0004A4	move.l	A4,2(A0)
	add.l	D1,D1
	move.l	D1,6(A0)
ok_0004AE	move.l	6(A1),D0
	lsr.l	#1,D0
	move.w	6(A3),D1
	movem.l	D0/D1/A1,-(SP)
	move.l	2(A1),A0
	move.l	A2,A1
	bsr	ok_0004EE
	move.l	A0,A4
	movem.l	(SP)+,D0/D1/A1
	sub.w	D1,D0
	bhs.s	ok_0004E2
	clr.l	2(A1)
	clr.l	6(A1)
	clr.w	10(A1)
	clr.w	12(A1)
	rts

ok_0004E2	move.l	A4,2(A1)
	add.l	D0,D0
	move.l	D0,6(A1)
	rts

ok_0004EE	cmp.w	D0,D1
	bhi.s	ok_0004F4
	move.w	D1,D0
ok_0004F4	bra	ok_0004F8

ok_0004F8	cmp.w	#$20,D0
	blo.s	ok_000544
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	sub.w	#$20,D0
	bra.s	ok_0004F8

ok_000544	cmp.w	#8,D0
	blo.s	ok_000562
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	move.l	(A0)+,D1
	add.l	D1,(A1)+
	subq.w	#8,D0
	bra.s	ok_000544

ok_00055E	move.w	(A0)+,D1
	add.w	D1,(A1)+
ok_000562	dbra	D0,ok_00055E
	rts

ok_000568	tst.w	D2
	bne.s	ok_000576
	move.w	D1,-(SP)
	bsr	ok_00077A
	move.w	(SP)+,D0
	rts

ok_000576	move.l	D3,-(SP)
	move.w	D2,D3
	mulu	D1,D3
	swap	D3
	cmp.w	D0,D3
	bhi.s	ok_00058A
	move.w	D2,D0
	bsr	ok_000598
	bra.s	ok_000594

ok_00058A	move.w	D0,-(SP)
	move.w	D1,D0
	bsr	ok_0007E8
	move.w	(SP)+,D0
ok_000594	move.l	(SP)+,D3
	rts

ok_000598	movem.l	D2-D5/A2,-(SP)
	move.l	A0,A2
	move.w	D1,D2
	moveq	#0,D3
	subq.w	#1,D1
ok_0005A4	subq.w	#8,D2
	bmi	ok_00062E
	sub.w	D0,D3
	bhs.s	ok_0005B0
	move.b	(A0)+,D5
ok_0005B0	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_0005B8
	move.b	(A0)+,D5
ok_0005B8	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_0005C0
	move.b	(A0)+,D5
ok_0005C0	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_0005C8
	move.b	(A0)+,D5
ok_0005C8	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_0005D0
	move.b	(A0)+,D5
ok_0005D0	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_0005D8
	move.b	(A0)+,D5
ok_0005D8	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_0005E0
	move.b	(A0)+,D5
ok_0005E0	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_0005E8
	move.b	(A0)+,D5
ok_0005E8	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_0005F0
	move.b	(A0)+,D5
ok_0005F0	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_0005F8
	move.b	(A0)+,D5
ok_0005F8	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_000600
	move.b	(A0)+,D5
ok_000600	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_000608
	move.b	(A0)+,D5
ok_000608	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_000610
	move.b	(A0)+,D5
ok_000610	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_000618
	move.b	(A0)+,D5
ok_000618	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_000620
	move.b	(A0)+,D5
ok_000620	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_000628
	move.b	(A0)+,D5
ok_000628	move.b	D5,(A1)+
	bra	ok_0005A4

ok_00062E	addq.w	#8,D2
	bra.s	ok_000642

ok_000632	sub.w	D0,D3
	bhs.s	ok_000638
	move.b	(A0)+,D5
ok_000638	move.b	D5,(A1)+
	sub.w	D0,D3
	bhs.s	ok_000640
	move.b	(A0)+,D5
ok_000640	move.b	D5,(A1)+
ok_000642	dbra	D2,ok_000632
	sub.l	A0,A2
	move.w	A2,D0
	neg.w	D0
	btst	#0,D0
	beq.s	ok_000656
	addq.w	#1,A0
	addq.w	#1,D0
ok_000656	lsr.w	#1,D0
	movem.l	(SP)+,D2-D5/A2
	rts

ok_00065E	lea	ok_001964,A2
	lsl.w	#4,D0
	add.w	D0,A2
	tst.l	2(A0)
	beq.s	ok_0006CC
	move.w	10(A0),D0
	add.w	D0,D0
	lea	ok_0011CC,A3
	move.w	0(A3,D0.W),4(A2)
	move.l	ok_000838(PC),A3
	move.w	0(A3,D0.W),D1
	add.w	8(A2),D1
	move.w	D1,6(A2)
	move.l	6(A0),D0
	lsr.l	#1,D0
	move.l	A1,(A2)
	movem.l	D0/D1/A0,-(SP)
	move.l	2(A0),A0
	bsr	ok_00077A
	move.l	A0,A1
	movem.l	(SP)+,D0/D1/A0
	sub.w	D1,D0
	bhs.s	ok_0006C0
	clr.l	2(A0)
	clr.l	6(A0)
	clr.w	10(A0)
	clr.w	12(A0)
	rts

ok_0006C0	move.l	A1,2(A0)
	add.l	D0,D0
	move.l	D0,6(A0)
	rts

ok_0006CC	move.l	A1,(A2)
	move.w	ok_0011CC,4(A2)
	move.l	ok_000838(PC),A0
	move.w	(A0),D0
	add.w	8(A2),D0
	move.w	D0,6(A2)
	bra	ok_0007E8

ok_0006E8	lea	ok_001964,A0
	lea	$DFF01E,A2
	lea	$88(A2),A1
	moveq	#3,D0
ok_0006FA	move.w	4(A0),D1
	beq.s	ok_000706
	move.w	D1,(A1)
	move.w	(A2),10(A0)
ok_000706	lea	$10(A0),A0
	lea	$10(A1),A1
	dbra	D0,ok_0006FA
	lea	ok_001964,A0
	moveq	#7,D1
ok_00071A	tst.l	(A0)
	beq.s	ok_00072E
	clr.w	8(A0)
	move.w	10(A0),D0
	btst	D1,D0
	beq.s	ok_00072E
	addq.w	#1,8(A0)
ok_00072E	lea	$10(A0),A0
	addq.w	#1,D1
	cmp.w	#11,D1
	bne.s	ok_00071A
	rts

ok_00073C	move.w	ok_000382(PC),D1
ok_000740	move.w	$DFF01E,D0
	and.w	D1,D0
	cmp.w	D1,D0
	bne.s	ok_000740
	move.w	D1,$DFF09C
	lea	ok_001964,A0
	lea	$DFF0A0,A1
	moveq	#3,D0
ok_000760	move.l	(A0),D1
	beq.s	ok_00076C
	move.l	D1,(A1)
	move.w	6(A0),4(A1)
ok_00076C	lea	$10(A0),A0
	lea	$10(A1),A1
	dbra	D0,ok_000760
	rts

ok_00077A	movem.l	D2/A2,-(SP)
	move.w	D1,D2
	cmp.w	D0,D2
	bhi.s	ok_00078C
	move.w	D2,D0
	bsr	ok_0007A2
	bra.s	ok_00079C

ok_00078C	sub.w	D0,D2
	bsr	ok_0007A2
	move.l	A0,A2
	move.w	D2,D0
	bsr	ok_0007E8
	move.l	A2,A0
ok_00079C	movem.l	(SP)+,D2/A2
	rts

ok_0007A2	cmp.w	#$20,D0
	blo.s	ok_0007CE
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	sub.w	#$20,D0
	bra.s	ok_0007A2

ok_0007CE	cmp.w	#8,D0
	blo.s	ok_0007E2
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	subq.w	#8,D0
	bra.s	ok_0007CE

ok_0007E0	move.w	(A0)+,(A1)+
ok_0007E2	dbra	D0,ok_0007E0
	rts

ok_0007E8	moveq	#0,D1
ok_0007EA	cmp.w	#$20,D0
	blo.s	ok_000816
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	sub.w	#$20,D0
	bra.s	ok_0007EA

ok_000816	cmp.w	#8,D0
	blo.s	ok_00082A
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	move.l	D1,(A1)+
	subq.w	#8,D0
	bra.s	ok_000816

ok_000828	move.w	D1,(A1)+
ok_00082A	dbra	D0,ok_000828
	rts

ok_000830	
	dc.l	ok_001A86
	dc.l	ok_002346

ok_000838	dc.l	0
ok_00083C	dc.w	$29,$2B,$2E,$31,$34,$37,$3A,$3E,$42,$45,$4A,$4E
	dc.w	$53,$57,$5D,$62,$68,$6F,$75,$7C,$84,$8B,$94,$9D
	dc.w	$A6,$AF,$BA,$C5,$D0,$DE,$EB,$F8,$107,$117
ok_000880	dc.w	$22,$25,$27,$29,$2C,$2E,$31,$34,$37,$3A,$3E,$42
	dc.w	$45,$4A,$4E,$53,$58,$5D,$63,$68,$6F,$75,$7C,$84
	dc.w	$8B,$94,$9D,$A6,$AF,$BA,$C6,$D1,$DD,$EB

ok_0008C4	bsr	ok_000AD0
	addq.w	#1,ok_001216
	move.w	ok_001220(PC),D0
	cmp.w	ok_001216(PC),D0
	bgt.s	ok_0008E0
	bsr	ok_000988
	bsr	ok_000A5C
ok_0008E0	lea	ok_0019A6,A2
	lea	ok_0019C4,A5
	moveq	#7,D7
ok_0008EE	tst.b	(A5)
	bne.s	ok_000900
	addq.w	#4,A2
	lea	$1C(A5),A5
	subq.w	#1,D7
	dbra	D7,ok_0008EE
	rts

ok_000900	moveq	#0,D0
	move.b	(A2),D0
	add.w	D0,D0
	move.w	ok_000940(PC,D0.W),D0
	beq.s	ok_000916
	moveq	#0,D1
	move.b	1(A2),D1
	jsr	ok_000940(PC,D0.W)
ok_000916	addq.w	#4,A2
	lea	14(A5),A5
	subq.w	#1,D7
	moveq	#0,D0
	move.b	(A2),D0
	add.w	D0,D0
	move.w	ok_000940(PC,D0.W),D0
	beq.s	ok_000934
	moveq	#0,D1
	move.b	1(A2),D1
	jsr	ok_000940(PC,D0.W)
ok_000934	addq.w	#4,A2
	lea	14(A5),A5
	dbra	D7,ok_0008EE
	rts

ok_000940	dcb.w	$A,0
	dc.w	$552,$594,$5CA,$626,0,$668,0,$60C,0,0,0,$61E,0,0
	dc.w	0,$630,0,0,$652,0,$614,$678,0,0,0,0

ok_000988	clr.w	ok_001216
	move.l	ok_001218(PC),A1
	add.w	ok_00121C(PC),A1
	move.l	A1,ok_001218
	addq.w	#1,ok_00121E
	bsr	ok_000A16
	tst.w	ok_001222
	bpl.s	ok_0009B4
	cmp.w	ok_00121E(PC),D0
	bgt.s	ok_0009FC
ok_0009B4	clr.w	ok_00121E
	mulu	ok_00121C(PC),D0
	sub.l	D0,ok_001218
	tst.w	ok_001222
	bmi.s	ok_0009D6
	move.w	ok_001222(PC),ok_001224
	bra.s	ok_0009DC

ok_0009D6	addq.w	#1,ok_001224
ok_0009DC	move.w	ok_001224(PC),D0
	cmp.w	ok_0002C8,D0
	bne.s	ok_0009F8
	clr.w	ok_001224

	bsr	ok_songo
	nop
	nop
	nop
	
;	move.w	ok_0002C6,ok_001220
	

ok_0009F8	bsr	ok_000A28
ok_0009FC	move.l	ok_001218(PC),A0
	movem.l	(A0),D0-D7
	movem.l	D0-D7,ok_0019A4
	move.w	#$FFFF,ok_001222
	rts

ok_000A16	move.w	ok_001224(PC),D0
	lea	ok_0016C4,A0
	move.b	0(A0,D0.W),D0
	bra	ok_000A4A

ok_000A28	lea	ok_0016C4,A0
	move.w	ok_001224(PC),D2
	moveq	#0,D0
	move.b	0(A0,D2.W),D0
	bsr	ok_000A4A
	move.l	A0,ok_001218
	clr.w	ok_00121E
	rts

ok_000A4A	lea	ok_001744,A0
	add.w	D0,D0
	add.w	D0,D0
	move.l	0(A0,D0.W),A0
	move.w	(A0)+,D0
	rts

ok_000A5C	lea	ok_001844,A0
	lea	ok_001244,A1
	lea	ok_0019A4,A2
	lea	ok_0019C4,A3
	moveq	#7,D7
ok_000A76	tst.b	(A3)
	bne.s	ok_000A88
	addq.w	#4,A2
	lea	$1C(A3),A3
	subq.w	#1,D7
	dbra	D7,ok_000A76
	rts

ok_000A88	bsr.s	ok_000A94
	subq.w	#1,D7
	bsr.s	ok_000A94
	dbra	D7,ok_000A76
	rts

ok_000A94	moveq	#0,D3
	move.b	(A2),D3
	beq.s	ok_000AC8
	subq.w	#1,D3
	moveq	#0,D0
	move.b	1(A2),D0
	lsl.w	#3,D0
	move.l	0(A0,D0.W),D2
	beq.s	ok_000AC8
	add.w	D0,D0
	add.w	D0,D0
	cmp.w	#1,$1E(A1,D0.W)
	beq.s	ok_000AC8
	move.l	D2,2(A3)
	move.l	$14(A1,D0.W),6(A3)
	move.w	D3,10(A3)
	move.w	D3,12(A3)
ok_000AC8	addq.w	#4,A2
	lea	14(A3),A3
	rts

ok_000AD0	bsr	ok_000C58
	move.w	ok_001216(PC),D0
	bne.s	ok_000AE4
	bsr	ok_000B60
	or.w	D4,ok_001238
ok_000AE4	bsr	ok_000CCA
	move.b	ok_00123C(PC),D1
	move.w	ok_00123E(PC),D2
	move.w	ok_001240(PC),D3
	lea	ok_00122E(PC),A0
	move.l	(A0)+,(A0)
	lea	$DFF0A8,A1
	moveq	#0,D0
	btst	#0,D1
	bne.s	ok_000B10
	move.b	(A0),D0
	mulu	D3,D0
	lsr.w	#6,D0
	move.w	D0,(A1)
ok_000B10	btst	#1,D1
	bne.s	ok_000B22
	move.b	1(A0),D0
	mulu	D2,D0
	lsr.w	#6,D0
	move.w	D0,$10(A1)
ok_000B22	btst	#2,D1
	bne.s	ok_000B34
	move.b	2(A0),D0
	mulu	D2,D0
	lsr.w	#6,D0
	move.w	D0,$20(A1)
ok_000B34	btst	#3,D1
	bne.s	ok_000B46
	move.b	3(A0),D0
	mulu	D3,D0
	lsr.w	#6,D0
	move.w	D0,$30(A1)
ok_000B46	move.b	ok_001236(PC),D0
	beq.s	ok_000B56
	bclr	#1,$BFE001
	rts

ok_000B56	bset	#1,$BFE001
	rts

ok_000B60	lea	ok_001844,A0
	lea	ok_0019A4,A2
	lea	ok_0019C4,A3
	lea	$DFF0A0,A4
	lea	ok_0011CC(PC),A6
	moveq	#0,D4
	moveq	#1,D5
	moveq	#7,D7
ok_000B82	tst.b	(A3)
	bne.s	ok_000B9C
	bsr.s	ok_000BB0
	addq.w	#4,A2
	lea	$1C(A3),A3
	lea	$10(A4),A4
	add.w	D5,D5
	subq.w	#1,D7
	dbra	D7,ok_000B82
	rts

ok_000B9C	addq.w	#8,A2
	lea	$1C(A3),A3
	lea	$10(A4),A4
	add.w	D5,D5
	subq.w	#1,D7
	dbra	D7,ok_000B82
	rts

ok_000BB0	move.b	D5,D3
	and.b	ok_00123C(PC),D3
	bne	ok_000C3C
	moveq	#0,D3
	move.b	(A2),D3
	beq	ok_000C3C
	subq.w	#1,D3
	moveq	#0,D0
	move.b	1(A2),D0
	lsl.w	#3,D0
	move.l	0(A0,D0.W),D2
	beq	ok_000C3C
	add.w	D0,D0
	add.w	D0,D0
	lea	ok_001244,A1
	add.w	D0,A1
	tst.w	$1E(A1)
	beq	ok_000C3C
	move.l	$14(A1),D1
	lsr.l	#1,D1
	tst.w	D1
	beq	ok_000C3C
	move.w	D5,$DFF096
	or.w	D5,D4
	move.l	D2,(A4)
	move.w	D3,8(A3)
	add.w	D3,D3
	move.w	0(A6,D3.W),D0
	move.w	D0,10(A3)
	move.w	D0,6(A4)
	move.l	A0,-(SP)
	lea	ok_00122E(PC),A0
	moveq	#0,D0
	move.b	-8(A0,D7.W),D0
	move.b	$1D(A1),0(A0,D0.W)
	move.l	(SP)+,A0
	move.w	$1A(A1),D0
	bne.s	ok_000C3E
	move.w	D1,4(A4)

	move.l	#ok_002C08,2(A3)

	move.w	#1,6(A3)
ok_000C3C	rts

ok_000C3E	move.w	D0,6(A3)
	moveq	#0,D1
	move.w	$18(A1),D1
	add.w	D1,D0
	move.w	D0,4(A4)
	add.l	D1,D1
	add.l	D2,D1
	move.l	D1,2(A3)
	rts

ok_000C58	lea	ok_001238(PC),A0
	move.w	(A0),D0
	beq.s	ok_000CC8
	clr.w	(A0)
	or.w	#$8000,D0
	lea	$DFF006,A0
	move.w	D0,$90(A0)
	move.b	(A0),D1
ok_000C72	cmp.b	(A0),D1
	beq.s	ok_000C72
	move.b	(A0),D1
ok_000C78	cmp.b	(A0),D1
	beq.s	ok_000C78
	lea	ok_0019C6,A1
	btst	#0,D0
	beq.s	ok_000C92
	move.l	(A1),$9A(A0)
	move.w	4(A1),$9E(A0)
ok_000C92	btst	#1,D0
	beq.s	ok_000CA4
	move.l	$1C(A1),$AA(A0)
	move.w	$20(A1),$AE(A0)
ok_000CA4	btst	#2,D0
	beq.s	ok_000CB6
	move.l	$38(A1),$BA(A0)
	move.w	$3C(A1),$BE(A0)
ok_000CB6	btst	#3,D0
	beq.s	ok_000CC8
	move.l	$54(A1),$CA(A0)
	move.w	$58(A1),$CE(A0)
ok_000CC8	rts

ok_000CCA	lea	ok_0019A4,A2
	lea	ok_0019C4,A3
	lea	$DFF0A0,A4
	lea	ok_0011CC(PC),A6
	moveq	#1,D5
	moveq	#7,D7
ok_000CE4	tst.b	(A3)
	bne.s	ok_000CFE
	bsr.s	ok_000D12
	addq.w	#4,A2
	lea	$1C(A3),A3
	lea	$10(A4),A4
	add.w	D5,D5
	subq.w	#1,D7
	dbra	D7,ok_000CE4
	rts

ok_000CFE	addq.w	#8,A2
	lea	$1C(A3),A3
	lea	$10(A4),A4
	add.w	D5,D5
	subq.w	#1,D7
	dbra	D7,ok_000CE4
	rts

ok_000D12	moveq	#0,D0
	move.b	2(A2),D0
	add.w	D0,D0
	moveq	#0,D1
	move.b	3(A2),D1
	move.w	ok_000D2A(PC,D0.W),D0
	jmp	ok_000D2A(PC,D0.W)

	rts

ok_000D2A	dc.w	$FFFE,$62,$48,$FFFE,$FFFE,$FFFE,$FFFE,$FFFE,$FFFE
	dc.w	$FFFE,$7C,$B8,$E6,$13C,$FFFE,$27E,$FFFE,$120
	dcb.w	$3,$FFFE
	dc.w	$134,$FFFE,$FFFE,$2F4,$246,$FFFE,$FFFE
	dc.w	$268,$FFFE
	dc.w	$128
	dc.w	$28E
	dcb.w	$4,$FFFE

	add.w	D1,10(A3)
	cmp.w	#$358,10(A3)
	ble.s	ok_000D84
	move.w	#$358,10(A3)
ok_000D84	move.w	10(A3),6(A4)
	rts

	sub.w	D1,10(A3)
	cmp.w	#$71,10(A3)
	bge.s	ok_000D9E
	move.w	#$71,10(A3)
ok_000D9E	move.w	10(A3),6(A4)
	rts

	move.w	8(A3),D2
	move.w	ok_001216(PC),D0
	move.b	ascii.MSG(PC,D0.W),D0
	bne.s	ok_000DC0
	and.w	#$F0,D1
	lsr.w	#4,D1
	sub.w	D1,D2
	bra	ok_000E74

ok_000DC0	subq.b	#1,D0
	bne.s	ok_000DC8
	bra	ok_000E74

ok_000DC8	and.w	#15,D1
	add.w	D1,D2
	bra	ok_000E74

ascii.MSG	dc.b	0
	dc.b	1
	dc.b	2
	dc.b	0
	dc.b	1
	dc.b	2
	dc.b	0
	dc.b	1
	dc.b	2
	dc.b	0
	dc.b	1
	dc.b	2
	dc.b	0
	dc.b	1
	dc.b	2
	dc.b	0

	move.w	8(A3),D2
	move.w	ok_001216(PC),D0
	and.w	#3,D0
	bne.s	ok_000DF4
	bra	ok_000E74

ok_000DF4	subq.b	#1,D0
	bne.s	ok_000E00
	and.w	#15,D1
	add.w	D1,D2
	bra.s	ok_000E74

ok_000E00	subq.b	#1,D0
	beq.s	ok_000E74
	and.w	#$F0,D1
	lsr.w	#4,D1
	sub.w	D1,D2
	bra	ok_000E74

	move.w	8(A3),D2
	move.w	ok_001216(PC),D0
	move.b	ascii.MSG0(PC,D0.W),D0
	bne.s	ok_000E20
	rts

ok_000E20	subq.b	#1,D0
	bne.s	ok_000E2E
	and.w	#$F0,D1
	lsr.w	#4,D1
	add.w	D1,D2
	bra.s	ok_000E74

ok_000E2E	subq.b	#1,D0
	bne.s	ok_000E38
	and.w	#15,D1
	add.w	D1,D2
ok_000E38	bra.s	ok_000E74

ascii.MSG0	dc.b	0
	dc.b	1
	dc.b	2
	dc.b	3
	dc.b	1
	dc.b	2
	dc.b	3
	dc.b	1
	dc.b	2
	dc.b	3
	dc.b	1
	dc.b	2
	dc.b	3
	dc.b	1
	dc.b	2
	dc.b	3

	move.w	ok_001216(PC),D0
	beq.s	ok_000E52
	rts

ok_000E52	move.w	8(A3),D2
	add.w	D1,D2
	move.w	D2,8(A3)
	bra.s	ok_000E74

	move.w	ok_001216(PC),D0
	beq.s	ok_000E66
	rts

ok_000E66	move.w	8(A3),D2
	sub.w	D1,D2
	move.w	D2,8(A3)
	bra	ok_000E74

ok_000E74	tst.w	D2
	bpl.s	ok_000E7A
	moveq	#0,D2
ok_000E7A	cmp.w	#$23,D2
	ble.s	ok_000E82
	moveq	#$23,D2
ok_000E82	add.w	D2,D2
	move.w	0(A6,D2.W),D0
	move.w	D0,6(A4)
	move.w	D0,10(A3)
	rts

	move.w	12(A5),D2
	move.w	ok_001216(PC),D0
	move.b	ok_000EC4(PC,D0.W),D0
	bne.s	ok_000EAE
	and.w	#$F0,D1
	lsr.w	#4,D1
	sub.w	D1,D2
	move.w	D2,10(A5)
	rts

ok_000EAE	subq.b	#1,D0
	bne.s	ok_000EB8
	move.w	D2,10(A5)
	rts

ok_000EB8	and.w	#15,D1
	add.w	D1,D2
	move.w	D2,10(A5)
	rts

ok_000EC4	dc.b	0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,$34,$2D,0,12,$30
	dc.b	$3A,3,$3C,$C0,$7C,0,3,$66,6,$3B,$42,0,10,$4E,$75
	dc.b	$53,0,$66,12,$C2,$7C,0,15,$D4,$41,$3B,$42,0,10
	dc.b	$4E,$75,$53,0,$67,$E6,$C2,$7C,0,$F0,$E8,$49,$94
	dc.b	$41,$3B,$42,0,10,$4E,$75,$34,$2D,0,12,$30,$3A,3,6
	dc.b	$10,$3B,0,$28,$66,2,$4E,$75,$53,0,$66,14,$C2,$7C
	dc.b	0,$F0,$E8,$49,$D4,$41,$3B,$42,0,10,$4E,$75,$53,0
	dc.b	$66,6,$C2,$7C,0,15,$D4,$41,$3B,$42,0,10,$4E,$75,0
	dc.b	1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,$30,$3A,2,$C8,$67,2
	dc.b	$4E,$75,$D3,$6D,0,12,$D3,$6D,0,10,$4E,$75,$30,$3A
	dc.b	2,$B6,$67,2,$4E,$75,$93,$6D,0,12,$93,$6D,0,10,$4E
	dc.b	$75,$30,$3A,2,$A4,$66,$1A,$30,1,$C0,$7C,0,15,$E8
	dc.b	$49,$C2,$FC,0,10,$D0,$41,$B0,$7A,$F3,$42,$64,6
	dc.b	$33,$C0
	dc.l	ok_001222
	dc.b	$4E,$75,$30,$3A,2,$82,$66,14,$C2,$7C,0,15,$4A,1
	dc.b	$67,6,$33,$C1
	dc.l	ok_001220
	dc.b	$4E,$75,$30,$3A,2,$6C,$66,8,$4A,1,$56,$F9
	dc.l	ok_001236
	dc.b	$4E,$75,$2F,8,$70,0,$41,$FA,2,$70,$10,$30,$70,$F8
	dc.b	$D0,$C0,12,$41,0,$40,$6E,6,$10,$81,$20,$5F,$4E
	dc.b	$75,$92,$3C,0,$40,12,1,0,$10,$6D,$26,$92,$3C,0
	dc.b	$10,12,1,0,$10,$6D,$2A,$92,$3C,0,$10,12,1,0,$10
	dc.b	$6D,12,$92,$3C,0,$10,12,1,0,$10,$6D,$10,$60,$D2
	dc.b	$30,$3A,2,$18,$66,$CC,$93,$10,$6A,$C8,$51,$D0,$60
	dc.b	$C4,$30,$3A,2,10,$66,$BE,$D3,$10,12,$10,0,$40,$63
	dc.b	$B6,$10,$BC,0,$40,$60,$B0,$2F,8,$70,0,$41,$FA,2
	dc.b	10,$10,$30,$70,$F8,$D0,$C0,$10,$A8,0,4,12,1,0,$40
	dc.b	$62,$9C,$20,$5F,$4E,$75

ok_00103A	clr.w	ok_00123A
	clr.w	ok_001224
	sf	ok_00123C
	lea	ok_0019C4,A0
	move.w	#$6F,D0
ok_001056	sf	(A0)+
	dbra	D0,ok_001056
	lea	ok_0002BE,A0
	lea	ok_0019C4,A1
	moveq	#3,D0
	moveq	#0,D1
ok_00106C	tst.w	(A0)
	sne	(A1)
	sne	14(A1)
	add.w	(A0)+,D1
	lea	$1C(A1),A1
	dbra	D0,ok_00106C
	addq.w	#4,D1
	add.w	D1,D1
	add.w	D1,D1
	move.w	D1,ok_00121C
	lea	ok_0019A4,A0
	moveq	#0,D1
	moveq	#7,D0
ok_001094	move.l	D1,(A0)+
	dbra	D0,ok_001094
	lea	ok_001226(PC),A0
	move.l	#$3030202,(A0)+
	move.l	#$1010000,(A0)+
	move.l	#$40404040,D0
	move.l	D0,(A0)+
	move.l	D0,(A0)+
	bsr	ok_000A28
	subq.w	#1,ok_00121E
	move.w	#$FFFF,ok_001222
	move.l	ok_001218(PC),A0
	sub.w	ok_00121C(PC),A0
	move.l	A0,ok_001218
	move.w	ok_0002C6,ok_001220
	clr.w	ok_001216
	clr.w	ok_001236
	clr.w	ok_001238
	rts

	and.w	#3,D0
	move.w	D0,D1
	lea	ok_0019C4,A0
	mulu	#$1C,D1
	tst.b	0(A0,D1.W)
	bne.s	ok_001112
	bset	D0,ok_00123C
	moveq	#1,D0
	rts

ok_001112	moveq	#0,D0
	rts

	and.w	#3,D0
	bclr	D0,ok_00123C
	beq.s	ok_001126
	moveq	#1,D0
	rts

ok_001126	moveq	#0,D0
	rts

ok_00112A	sf	ok_00123C
ok_end2
ok_001130	movem.l	D0/D1/A6,-(SP)
	lea	$DFF000,A6
	move.b	ok_00123C(PC),D1
	move.w	#15,D0
	eor.b	D1,D0
	move.w	D0,$96(A6)
	moveq	#0,D0
	btst	#0,D1
	bne.s	ok_001154
	move.w	D0,$A8(A6)
ok_001154	btst	#1,D1
	bne.s	ok_00115E
	move.w	D0,$B8(A6)
ok_00115E	btst	#2,D1
	bne.s	ok_001168
	move.w	D0,$C8(A6)
ok_001168	btst	#3,D1
	bne.s	ok_001172
	move.w	D0,$D8(A6)
ok_001172	movem.l	(SP)+,D0/D1/A6
	rts

ok_volume
	cmp.w	#$40,D0
	bls.s	ok_001180
	moveq	#$40,D0
ok_001180	move.w	D0,ok_00123E
	move.w	D0,ok_001240
	rts

ok_00118E	cmp.w	#$40,D0
	bls.s	ok_001196
	moveq	#$40,D0
ok_001196	cmp.w	#$40,D1
	bls.s	ok_00119E
	moveq	#$40,D1
ok_00119E	move.w	D0,ok_00123E
	move.w	D1,ok_001240
	rts

ok_0011AC	movem.l	D0/D1,-(SP)
	moveq	#4,D1
ok_0011B2	move.b	$DFF006,D0
ok_0011B8	cmp.b	$DFF006,D0
	beq.s	ok_0011B8
	dbra	D1,ok_0011B2
	movem.l	(SP)+,D0/D1
	rts

	dc.w	0
ok_0011CC	dc.w	$358,$328,$2FA,$2D0,$2A6,$280,$25C,$23A,$21A,$1FC
	dc.w	$1E0,$1C5,$1AC,$194,$17D,$168,$153,$140,$12E,$11D
	dc.w	$10D,$FE,$F0,$E2,$D6,$CA,$BE,$B4,$AA,$A0,$97,$8F
	dc.w	$87,$7F,$78,$71,0
ok_001216	dc.w	0
ok_001218	dc.l	0
ok_00121C	dc.w	0
ok_00121E	dc.w	0
ok_001220	dc.w	0
ok_001222	dc.w	0
ok_001224	dc.w	0
ok_001226	dcb.l	$2,0
ok_00122E	dcb.l	$2,0
ok_001236	dcb.b	$2,0
ok_001238	dc.w	0
ok_00123A	dc.w	0
ok_00123C	dcb.b	$2,0
ok_00123E	dc.w	$40
ok_001240	dc.w	$40,0

ok_001244	ds.l	5
ok_001258	ds.l	$11B
ok_0016C4	ds.l	$20
ok_001744	ds.l	$40
ok_001844	ds.l	$48
ok_001964	ds.l	$10
ok_0019A4	ds.w	1
ok_0019A6	ds.l	7
		ds.w	1
ok_0019C4	ds.w	1
ok_0019C6	ds.l	$1B
		ds.w	1

ok_001A34	ds.l	$14
		ds.w	1
ok_001A86	ds.l	$230
ok_002346	ds.l	$230
		ds.w	1
ok_002C08	ds.l	1

 ifne testi

	section	sc,data_f

mod	incbin	mux:popcorn

 endc
