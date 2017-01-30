testi = 1

 ifne testi

	bset	#1,$bfe001
	
	lea	module,a0
	lea	vol,a1
	lea	foo,a2
	bsr	init

loop	
	cmp.b	#$80,$dff006	
	bne.b	loop
.e	cmp.b	#$81,$dff006	
	bne.b	.e

	move	#$ff0,$dff180
	bsr	init+466
	clr	$dff180

	btst	#6,$bfe001
	bne.b	loop

	move	#$f,$dff096
	rts


vol	dc	$40
foo	dc	0


 endc


* Futurecomposer v1.4
* init: 0
* music: 466

init
lbC0001B0
	move.l	a0,lbL000102
	move	(a1),lbW00010A
	move.l	a1,volume
	move.l	a2,songend

	move.w	#1,lbW0009F6
	move.l	lbL000102,A0
	lea	$B4(A0),A1
	move.l	A1,lbL000A08
	move.l	A0,A1
	add.l	8(A0),A1
	move.l	A1,lbL000A0C
	move.l	A0,A1
	add.l	$10(A0),A1
	move.l	A1,lbL000A10
	move.l	A0,A1
	add.l	$18(A0),A1
	move.l	A1,lbL000A14
	move.l	4(A0),D0
	divu	#13,D0
	lea	$28(A0),A1
	lea	lbL000B2C(PC),A2
	moveq	#9,D1
lbC0001FE	move.w	(A1)+,(A2)+
	move.l	(A1)+,(A2)+
	add.w	#10,A2
	dbra	D1,lbC0001FE

	move.l	A0,D1
	add.l	$20(A0),D1
	lea	lbL000B28(PC),A3
	move.l	D1,(A3)+
	moveq	#8,D3
	moveq	#0,D2
lbC00021A	move.w	(A3),D2
	add.l	D2,D1
	add.l	D2,D1
	addq.l	#2,D1
	add.w	#12,A3
	move.l	D1,(A3)+
	dbra	D3,lbC00021A

	lea	$64(A0),A1
	lea	lbL000BC8(PC),A2
	move.l	A0,A3
	add.l	$24(A0),A3
	moveq	#$4F,D1
	moveq	#0,D2
lbC00023E	move.l	A3,(A2)+
	move.b	(A1)+,D2
	move.w	D2,(A2)+
	clr.w	(A2)+
	move.w	D2,(A2)+
	addq.w	#6,A2
	add.w	D2,A3
	add.w	D2,A3
	dbra	D1,lbC00023E

	move.l	lbL000A08(PC),A0
	moveq	#0,D2
	move.b	12(A0),D2
	bne.s	lbC000262

	move.b	#3,D2
lbC000262	move.w	D2,lbW0009F2
	move.w	D2,lbW0009F4
	clr.w	lbW0009EE
	clr.w	lbW0009F0
	move.w	#15,$DFF096
	move.w	#$780,$DFF09A
	moveq	#0,D7
	mulu	#13,D0
	moveq	#3,D6
	lea	lbL0008C6(PC),A0
	lea	lbL000A18(PC),A1
	lea	lbL0009F8(PC),A2
lbC00029E	move.l	A1,10(A0)
	move.l	A1,$12(A0)
	clr.w	4(A0)
	move.w	#13,6(A0)
	clr.w	8(A0)
	clr.l	14(A0)
	move.b	#1,$17(A0)
	move.b	#1,$18(A0)
	clr.b	$19(A0)
	clr.l	$1A(A0)
	clr.w	$1E(A0)
	clr.l	$26(A0)
	clr.w	$2A(A0)
	clr.l	$2C(A0)
	clr.l	$30(A0)
	clr.w	$38(A0)
	moveq	#0,D3
	move.w	(A2)+,D1
	move.w	(A2),D3
	divu	#3,D3
	moveq	#0,D4
	bset	D3,D4
	move.w	D4,$20(A0)
	move.w	(A2)+,D3
	and.l	#$FF,D3
	and.l	#$FF,D1
	lea	$DFF0A0,A6
	add.w	D1,A6
	move.l	#0,(A6)
	move.w	#$100,4(A6)
	move.w	#0,6(A6)
	move.w	#0,8(A6)
	move.l	A6,$3C(A0)
	move.l	lbL000A08(PC),(A0)
	move.l	lbL000A08(PC),$34(A0)
	add.l	D0,$34(A0)
	add.l	D3,$34(A0)
	add.l	D7,(A0)
	add.l	D3,(A0)
	move.l	(A0),A3
	move.b	(A3),D1
	and.l	#$FF,D1
	lsl.w	#6,D1
	move.l	lbL000A0C(PC),A4
	add.w	D1,A4
	move.l	A4,$22(A0)
	move.b	1(A3),$2C(A0)
	move.b	2(A3),$16(A0)
	lea	$4A(A0),A0
	dbra	D6,lbC00029E

	rts

music
lbC00036A
	move.l	volume(pc),a5
	move	(a5),lbW00010A

	lea	lbW0009EE(PC),A5
	tst.w	8(A5)
	bne.s	lbC000376

	rts

lbC000376	subq.w	#1,4(A5)
	bne.s	lbC0003A6

	move.w	6(A5),4(A5)
	moveq	#0,D5
	moveq	#6,D6
	lea	lbL0008C6(PC),A0
	bsr.w	lbC0004AC
	lea	lbL000910(PC),A0
	bsr.w	lbC0004AC
	lea	lbL00095A(PC),A0
	bsr.w	lbC0004AC
	lea	lbL0009A4(PC),A0
	bsr.w	lbC0004AC
lbC0003A6	clr.w	(A5)
	lea	$DFF000,A6
	lea	lbL0008C6(PC),A0
	bsr.w	lbC0005B6
	move.w	lbW00010A,D1
	bsr.w	lbC0010C8
	move.l	D0,$A6(A6)
	lea	lbL000910(PC),A0
	bsr.w	lbC0005B6
	move.w	lbW00010A,D1
	bsr.w	lbC0010C8
	move.l	D0,$B6(A6)
	lea	lbL00095A(PC),A0
	bsr.w	lbC0005B6
	move.w	lbW00010A,D1
	bsr.w	lbC0010C8
	move.l	D0,$C6(A6)
	lea	lbL0009A4(PC),A0
	bsr.w	lbC0005B6
	move.w	lbW00010A,D1
	bsr.w	lbC0010C8
	move.l	D0,$D6(A6)
	lea	lbL0008C6(PC),A0
	move.l	$44(A0),A1
	add.w	$40(A0),A1
	move.l	$8E(A0),A2
	add.w	$8A(A0),A2
	move.l	$D8(A0),A3
	add.w	$D4(A0),A3
	move.l	$122(A0),A4
	add.w	$11E(A0),A4
	move.w	$42(A0),D1
	move.w	$8C(A0),D2
	move.w	$D6(A0),D3
	move.w	$120(A0),D4
	moveq	#2,D0
	moveq	#0,D5
	move.w	(A5),D7
	or.w	#$8000,D7
	move.w	D7,$DFF096
	lea	lbW00090E(PC),A0
	move.w	(A0),D7
	beq.s	lbC000462

	subq.w	#1,(A0)
	cmp.w	D0,D7
	bne.s	lbC000462

	move.w	D5,(A0)
	move.l	A1,$A0(A6)
	move.w	D1,$A4(A6)
lbC000462	lea	lbW000958(PC),A0
	move.w	(A0),D7
	beq.s	lbC00047A

	subq.w	#1,(A0)
	cmp.w	D0,D7
	bne.s	lbC00047A

	move.w	D5,(A0)
	move.l	A2,$B0(A6)
	move.w	D2,$B4(A6)
lbC00047A	lea	lbW0009A2(PC),A0
	move.w	(A0),D7
	beq.s	lbC000492

	subq.w	#1,(A0)
	cmp.w	D0,D7
	bne.s	lbC000492

	move.w	D5,(A0)
	move.l	A3,$C0(A6)
	move.w	D3,$C4(A6)
lbC000492	lea	lbW0009EC(PC),A0
	move.w	(A0),D7
	beq.s	lbC0004AA

	subq.w	#1,(A0)
	cmp.w	D0,D7
	bne.s	lbC0004AA

	move.w	D5,(A0)
	move.l	A4,$D0(A6)
	move.w	D4,$D4(A6)
lbC0004AA	rts

lbC0004AC	move.l	$22(A0),A1
	add.w	$28(A0),A1
	cmp.b	#$49,(A1)
	beq.s	lbC0004C4

	cmp.w	#$40,$28(A0)
	bne.b	lbC00051C

lbC0004C4	move.w	D5,$28(A0)
	move.l	(A0),A2
	add.w	6(A0),A2
	cmp.l	$34(A0),A2
	bne.s	lbC0004E2

	move.l	songend(pc),a2
	st	(a2)

	move.w	D5,6(A0)
	move.l	(A0),A2
lbC0004E2	lea	lbW0009F0(PC),A3
	moveq	#1,D1
	addq.b	#1,(A3)
	cmp.b	#5,(A3)
	bne.s	lbC000500

	move.b	D1,(A3)
	move.b	12(A2),D1
	beq.s	lbC000500

	move.w	D1,2(A3)
	move.w	D1,4(A3)
lbC000500	move.b	(A2)+,D1
	move.b	(A2)+,$2C(A0)
	move.b	(A2)+,$16(A0)
	lsl.w	D6,D1
	move.l	lbL000A0C(PC),A1
	add.w	D1,A1
	move.l	A1,$22(A0)
	add.w	#13,6(A0)
lbC00051C	move.b	1(A1),D1
	move.b	(A1)+,D0
	bne.s	lbC00052C

	and.w	#$C0,D1
	beq.s	lbC000540

	bra.s	lbC000530

lbC00052C	move.w	D5,$38(A0)
lbC000530	move.b	D5,$2F(A0)
	btst	#7,D1
	beq.s	lbC000540

	move.b	2(A1),$2F(A0)
lbC000540	and.w	#$7F,D0
	beq.b	lbC0005B0

	move.b	D0,8(A0)
	move.b	(A1),D1
	move.b	D1,9(A0)
	move.w	$20(A0),D3
	or.w	D3,(A5)
	move.w	D3,$DFF096
	and.w	#$3F,D1
	add.b	$16(A0),D1
	move.l	lbL000A14(PC),A2
	lsl.w	D6,D1
	add.w	D1,A2
	move.w	D5,$10(A0)
	move.b	(A2),$17(A0)
	move.b	(A2)+,$18(A0)
	moveq	#0,D1
	move.b	(A2)+,D1
	move.b	(A2)+,$1B(A0)
	move.b	#$40,$2E(A0)
	move.b	(A2),$1C(A0)
	move.b	(A2)+,$1D(A0)
	move.b	(A2)+,$1E(A0)
	move.l	A2,10(A0)
	move.l	lbL000A10(PC),A2
	lsl.w	D6,D1
	add.w	D1,A2
	move.l	A2,$12(A0)
	move.w	D5,$32(A0)
	move.b	D5,$19(A0)
	move.b	D5,$1A(A0)
lbC0005B0	addq.w	#2,$28(A0)
	rts

lbC0005B6	moveq	#0,D7
lbC0005B8	tst.b	$1A(A0)
	beq.s	lbC0005C6

	subq.b	#1,$1A(A0)
	bra.w	lbC00074A

lbC0005C6	move.l	$12(A0),A1
	add.w	$32(A0),A1
lbC0005CE	cmp.b	#$E1,(A1)
	beq.w	lbC00074A

	move.b	(A1),D0
	cmp.b	#$E0,D0
	bne.s	lbC0005F2

	move.b	1(A1),D1
	and.w	#$3F,D1
	move.w	D1,$32(A0)
	move.l	$12(A0),A1
	add.w	D1,A1
	move.b	(A1),D0
lbC0005F2	cmp.b	#$E2,D0
	bne.s	lbC00063E

	move.w	$20(A0),D1
	or.w	D1,(A5)
	move.w	D1,$DFF096
	moveq	#0,D0
	move.b	1(A1),D0
	lea	lbL000B28(PC),A4
	lsl.w	#4,D0
	add.w	D0,A4
	move.l	$3C(A0),A3
	move.l	(A4)+,D1
	move.l	D1,(A3)
	move.l	D1,$44(A0)
	move.w	(A4)+,4(A3)
	move.l	(A4),$40(A0)
	move.w	#3,$48(A0)
	move.w	D7,$10(A0)
	move.b	#1,$17(A0)
	addq.w	#2,$32(A0)
	bra.w	lbC00073A

lbC00063E	cmp.b	#$E4,D0
	bne.s	lbC000674

	moveq	#0,D0
	move.b	1(A1),D0
	lea	lbL000B28(PC),A4
	lsl.w	#4,D0
	add.w	D0,A4
	move.l	$3C(A0),A3
	move.l	(A4)+,D1
	move.l	D1,(A3)
	move.l	D1,$44(A0)
	move.w	(A4)+,4(A3)
	move.l	(A4),$40(A0)
	move.w	#3,$48(A0)
	addq.w	#2,$32(A0)
	bra.w	lbC00073A

lbC000674	cmp.b	#$E9,D0
	bne.b	lbC0006DC

	move.w	$20(A0),D1
	or.w	D1,(A5)
	move.w	D1,$DFF096
	moveq	#0,D0
	move.b	1(A1),D0
	lea	lbL000B28(PC),A4
	lsl.w	#4,D0
	add.w	D0,A4
	move.l	(A4),A2
	cmp.l	#'SSMP',(A2)+
	bne.s	lbC0006D6

	lea	$140(A2),A4
	moveq	#0,D1
	move.b	2(A1),D1
	lsl.w	#4,D1
	add.w	D1,A2
	add.l	(A2),A4
	move.l	$3C(A0),A3
	move.l	A4,(A3)
	move.l	4(A2),4(A3)
	move.l	A4,$44(A0)
	move.l	6(A2),$40(A0)
	move.w	D7,$10(A0)
	move.b	#1,$17(A0)
	move.w	#3,$48(A0)
lbC0006D6	addq.w	#3,$32(A0)
	bra.s	lbC00073A

lbC0006DC	cmp.b	#$E7,D0
	bne.s	lbC0006FC

	moveq	#0,D0
	move.b	1(A1),D0
	lsl.w	D6,D0
	move.l	lbL000A10(PC),A1
	add.w	D0,A1
	move.l	A1,$12(A0)
	move.w	D7,$32(A0)
	bra.w	lbC0005CE

lbC0006FC	cmp.b	#$EA,D0
	bne.s	lbC000714

	move.b	1(A1),4(A0)
	move.b	2(A1),5(A0)
	addq.w	#3,$32(A0)
	bra.s	lbC00073A

lbC000714	cmp.b	#$E8,D0
	bne.s	lbC000728

	move.b	1(A1),$1A(A0)
	addq.w	#2,$32(A0)
	bra.w	lbC0005B8

lbC000728	cmp.b	#$E3,(A1)+
	bne.s	lbC00073A

	addq.w	#3,$32(A0)
	move.b	(A1)+,$1B(A0)
	move.b	(A1),$1C(A0)
lbC00073A	move.l	$12(A0),A1
	add.w	$32(A0),A1
	move.b	(A1),$2B(A0)
	addq.w	#1,$32(A0)
lbC00074A	tst.b	$19(A0)
	beq.s	lbC000758

	subq.b	#1,$19(A0)
	bra.w	lbC0007E2

lbC000758	tst.b	15(A0)
	bne.s	lbC0007BA

	subq.b	#1,$17(A0)
	bne.s	lbC0007E2

	move.b	$18(A0),$17(A0)
lbC00076A	move.l	10(A0),A1
	add.w	$10(A0),A1
	move.b	(A1),D0
	cmp.b	#$E1,D0
	beq.s	lbC0007E2

	cmp.b	#$EA,D0
	bne.s	lbC000792

	move.b	1(A1),14(A0)
	move.b	2(A1),15(A0)
	addq.w	#3,$10(A0)
	bra.s	lbC0007BA

lbC000792	cmp.b	#$E8,D0
	bne.s	lbC0007A4

	addq.w	#2,$10(A0)
	move.b	1(A1),$19(A0)
	bra.s	lbC0007E2

lbC0007A4	cmp.b	#$E0,D0
	bne.s	lbC0007DA

	move.b	1(A1),D0
	and.w	#$3F,D0
	subq.b	#5,D0
	move.w	D0,$10(A0)
	bra.s	lbC00076A

lbC0007BA	not.b	$26(A0)
	beq.s	lbC0007E2

	subq.b	#1,15(A0)
	move.b	14(A0),D1
	add.b	D1,$2D(A0)
	bpl.s	lbC0007E2

	moveq	#0,D1
	move.b	D1,15(A0)
	move.b	D1,$2D(A0)
	bra.s	lbC0007E2

lbC0007DA	move.b	(A1),$2D(A0)
	addq.w	#1,$10(A0)
lbC0007E2	move.b	$2B(A0),D0
	bmi.s	lbC0007F0

	add.b	8(A0),D0
	add.b	$2C(A0),D0
lbC0007F0	moveq	#$7F,D1
	and.l	D1,D0
	lea	lbL000A20(PC),A1
	add.w	D0,D0
	move.w	D0,D1
	add.w	D0,A1
	move.w	(A1),D0
	move.b	$2E(A0),D7
	tst.b	$1E(A0)
	beq.s	lbC000810

	subq.b	#1,$1E(A0)
	bra.s	lbC000862

lbC000810	moveq	#5,D2
	move.b	D1,D5
	move.b	$1C(A0),D4
	add.b	D4,D4
	move.b	$1D(A0),D1
	tst.b	D7
	bpl.s	lbC000828

	btst	#0,D7
	bne.s	lbC000848

lbC000828	btst	D2,D7
	bne.s	lbC000838

	sub.b	$1B(A0),D1
	bhs.s	lbC000844

	bset	D2,D7
	moveq	#0,D1
	bra.s	lbC000844

lbC000838	add.b	$1B(A0),D1
	cmp.b	D4,D1
	blo.s	lbC000844

	bclr	D2,D7
	move.b	D4,D1
lbC000844	move.b	D1,$1D(A0)
lbC000848	lsr.b	#1,D4
	sub.b	D4,D1
	bhs.s	lbC000852

	sub.w	#$100,D1
lbC000852	add.b	#$A0,D5
	blo.s	lbC000860

lbC000858	add.w	D1,D1
	add.b	#$18,D5
	bhs.s	lbC000858

lbC000860	add.w	D1,D0
lbC000862	eor.b	#1,D7
	move.b	D7,$2E(A0)
	not.b	$27(A0)
	beq.s	lbC000888

	moveq	#0,D1
	move.b	$2F(A0),D1
	beq.s	lbC000888

	cmp.b	#$1F,D1
	bls.s	lbC000884

	and.w	#$1F,D1
	neg.w	D1
lbC000884	sub.w	D1,$38(A0)
lbC000888	not.b	$2A(A0)
	beq.s	lbC0008A6

	tst.b	5(A0)
	beq.s	lbC0008A6

	subq.b	#1,5(A0)
	moveq	#0,D1
	move.b	4(A0),D1
	bpl.s	lbC0008A2

	ext.w	D1
lbC0008A2	sub.w	D1,$38(A0)
lbC0008A6	add.w	$38(A0),D0
	cmp.w	#$70,D0
	bhi.s	lbC0008B4

	move.w	#$71,D0
lbC0008B4	cmp.w	#$D60,D0
	bls.s	lbC0008BE

	move.w	#$D60,D0
lbC0008BE	swap	D0
	move.b	$2D(A0),D0
	rts

lbL0008C6	dcb.l	$12,0
lbW00090E	dc.w	0
lbL000910	dcb.l	$12,0
lbW000958	dc.w	0
lbL00095A	dcb.l	$12,0
lbW0009A2	dc.w	0
lbL0009A4	dcb.l	$12,0
lbW0009EC	dc.w	0
lbW0009EE	dc.w	0
lbW0009F0	dc.w	0
lbW0009F2	dc.w	0
lbW0009F4	dc.w	0
lbW0009F6	dc.w	0
lbL0009F8	dc.l	0
	dc.l	$100003
	dc.l	$200006
	dc.l	$300009
lbL000A08	dc.l	0
lbL000A0C	dc.l	0
lbL000A10	dc.l	0
lbL000A14	dc.l	0
lbL000A18	dc.l	$1000000
	dc.l	$E1
lbL000A20	dc.l	$6B00650
	dc.l	$5F405A0
	dc.l	$54C0500
	dc.l	$4B80474
	dc.l	$43403F8
	dc.l	$3C0038A
	dc.l	$3580328
	dc.l	$2FA02D0
	dc.l	$2A60280
	dc.l	$25C023A
	dc.l	$21A01FC
	dc.l	$1E001C5
	dc.l	$1AC0194
	dc.l	$17D0168
	dc.l	$1530140
	dc.l	$12E011D
	dc.l	$10D00FE
	dc.l	$F000E2
	dc.l	$D600CA
	dc.l	$BE00B4
	dc.l	$AA00A0
	dc.l	$97008F
	dc.l	$87007F
	dc.l	$780071
	dcb.l	$6,$710071
	dc.l	$D600CA0
	dc.l	$BE80B40
	dc.l	$A980A00
	dc.l	$97008E8
	dc.l	$86807F0
	dc.l	$7800714
	dc.l	$1AC01940
	dc.l	$17D01680
	dc.l	$15301400
	dc.l	$12E011D0
	dc.l	$10D00FE0
	dc.l	$F000E28
	dc.l	$6B00650
	dc.l	$5F405A0
	dc.l	$54C0500
	dc.l	$4B80474
	dc.l	$43403F8
	dc.l	$3C0038A
	dc.l	$3580328
	dc.l	$2FA02D0
	dc.l	$2A60280
	dc.l	$25C023A
	dc.l	$21A01FC
	dc.l	$1E001C5
	dc.l	$1AC0194
	dc.l	$17D0168
	dc.l	$1530140
	dc.l	$12E011D
	dc.l	$10D00FE
	dc.l	$F000E2
	dc.l	$D600CA
	dc.l	$BE00B4
	dc.l	$AA00A0
	dc.l	$97008F
	dc.l	$87007F
	dc.l	$780071
lbL000B28	dc.l	0
lbL000B2C	dcb.l	$27,0
lbL000BC8	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$5,0

lbC0010C8	moveq	#0,D7
	move.b	D0,D7
	mulu	D1,D7
	lsr.w	#6,D7
	move.w	D7,D0
	rts

lbL000102	dc.l	0	* modaddr
lbW00010A	dc.w	0	* volume
volume		dc.l	0
songend		dc.l	0
end



	ifne	testi
	section	dd,data_c

module	incbin	music:fc/fc14.Walkman-Complex

	endc


