testi = 0


 ifne testi

	section	omcwd,code_c

;	move.l	#mdat,d0
;	move.l	#smpl,d1
;	moveq	#18,d2	* rate
;	moveq	#2,d3	* song
;	move.l	#buffer2048,d4


	move.l	#mdat,d0
	move.l	#smpl,d1
	moveq	#20,d2
	moveq	#0,d3
	move.l	#buf,d4
	jsr	start

ee	btst	#6,$bfe001
	bne.b	ee

	jsr	start+4
	rts

	section	cc,code_c

 endc

start
	jmp	init(pc)
	jmp	end(pc)
	jmp	vol(pc)

old	dc.l	0

init
lbL00024C
	bsr	gvbr
	lea	old(pc),a0
	move.l	$70(a5),(a0)

	move.l	d3,-(sp)
	move.l	d2,-(sp)
	move.l	d4,d2
	lea	lbL0002D8(pc),a0
	jsr	$34(a0)
	move.l	(sp)+,d0
	lea	lbL0002D8(pc),a0
	jsr	$80(a0)
	lea	lbL0002D8(pc),a0
	jsr	$4c(a0)
	clr	$1e(a0)
	move.l	(sp)+,d0
	lea	lbL0002D8(pc),a0
	jsr	$2c(a0)
;	bsr	lbC0002C8
	rts

end
lbL00028C
	lea	lbL0002D8(pc),a0
	JSR	$0028(A0)
	MOVEQ	#$00,D0
	lea	lbL0002D8(pc),a0
	JSR	$0040(A0)
	MOVEQ	#$01,D0
	lea	lbL0002D8(pc),a0
	JSR	$0040(A0)
	MOVEQ	#$02,D0
	lea	lbL0002D8(pc),a0
	JSR	$0040(A0)
	MOVEQ	#$03,D0
	lea	lbL0002D8(pc),a0
	JSR	$0040(A0)

	bsr	gvbr
	move.l	old(pc),$70(a5)
	RTS	


vol
lbC0002C8
	and.l	#$ff,d0
	lea	lbL0002D8(PC),A0
	jsr	$48(A0)
	rts

lbL0002D8	
	ORI.B	#$00,D0
	ORI.B	#$00,D0
	ORI.B	#$00,D0
	ORI.B	#$00,D0
	ORI.B	#$00,D0
	ORI.B	#$00,D0
	ORI.B	#$00,D0
	ORI.B	#$00,D0


	bra	lbC00124A

	bra	lbC00037E

	bra	lbC00124A

	bra	lbC0012C8

	bra	lbC000F90

	bra	lbC0013E4

	bra	lbC00124A

	bra	lbC00124A

	bra	lbC001120

	bra	lbC0012C8

	bra	lbC001168

	bra	lbC00124A

	bra	lbC00124A

	bra	lbC00124A

	bra	lbC00124A

	bra	lbC0011A8

	bra	lbC0012E0

	bra	lbC00124A

	bra	lbC00124A

	bra	lbC00124A

	bra	lbC00124A

	bra	lbC00124A

	bra	lbC00124A

	bra	lbC00124A

	bra	lbC001E78

gvbr
lbC00035C	move.l	A6,-(SP)
	sub.l	A5,A5
	move.l	4.w,A6
	btst	#0,$129(A6)
	beq.s	lbC000374

	lea	lbL000378(PC),A5
	jsr	-$1E(A6)
lbC000374	move.l	(SP)+,A6
	rts

lbL000378	dc.l	$4E7AD801	* MOVEC VBR,a5

	rte

lbC00037E	movem.l	D0-D7/A0-A6,-(SP)
	lea	lbL001564(PC),A6
	tst.b	$1F(A6)
	beq.s	lbC000398

	move.w	#$F66,$DFF180
	bra	lbC000480

lbC000398	move.b	#1,$1F(A6)
	move.l	12(A6),-(SP)
	move.w	$34(A6),D0
	beq.s	lbC0003E4

	move.w	D0,$DFF096
	moveq	#9,D1
	btst	#0,D0
	beq.s	lbC0003BC

	move.w	D1,$DFF0A6
lbC0003BC	btst	#1,D0
	beq.s	lbC0003C8

	move.w	D1,$DFF0B6
lbC0003C8	btst	#2,D0
	beq.s	lbC0003D4

	move.w	D1,$DFF0C6
lbC0003D4	btst	#3,D0
	beq.s	lbC0003E0

	move.w	D1,$DFF0D6
lbC0003E0	clr.w	$34(A6)
lbC0003E4	move.w	$4C(A6),$DFF096
	tst.b	$12(A6)
	bne.s	lbC0003F6

	bra	lbC000478

lbC0003F6	bsr	lbC000864
	tst.b	10(A6)
	bmi.s	lbC000404

	bsr	lbC000486
lbC000404	lea	lbL0015F2(PC),A5
	move.w	$58(A5),$DFF0A6
	lea	lbL001656(PC),A5
	move.w	$58(A5),$DFF0B6
	lea	lbL0016BA(PC),A5
	move.w	$58(A5),$DFF0C6
	lea	lbL00171E(PC),A5
	move.w	$58(A5),$DFF0D6
	lea	lbL001782(PC),A5
	lea	lbL002606(PC),A4
	move.w	$58(A5),6(A4)
	lea	lbL0017E6(PC),A5
	lea	lbL002616(PC),A4
	move.w	$58(A5),6(A4)
	lea	lbL00184A(PC),A5
	lea	lbL002626(PC),A4
	move.w	$58(A5),6(A4)
	lea	lbL0018AE(PC),A5
	lea	lbL002636(PC),A4
	move.w	$58(A5),6(A4)
	move.w	$32(A6),$DFF096
	clr.w	$32(A6)
lbC000478	clr.b	$1F(A6)
	move.l	(SP)+,12(A6)
lbC000480	movem.l	(SP)+,D0-D7/A0-A6
lbC000484	rts

lbC000486	lea	lbL001AA2(PC),A5
	move.l	0(A6),A4
	subq.w	#1,$10(A6)
	bpl.s	lbC000484

	move.w	6(A5),$10(A6)
lbC00049A	move.l	A5,A0
	clr.b	9(A6)
	bsr.s	lbC0004E4
	tst.b	9(A6)
	bne.s	lbC00049A

	bsr.s	lbC0004E2
	tst.b	9(A6)
	bne.s	lbC00049A

	bsr.s	lbC0004E2
	tst.b	9(A6)
	bne.s	lbC00049A

	bsr.s	lbC0004E2
	tst.b	9(A6)
	bne.s	lbC00049A

	bsr.s	lbC0004E2
	tst.b	9(A6)
	bne.s	lbC00049A

	bsr.s	lbC0004E2
	tst.b	9(A6)
	bne.s	lbC00049A

	bsr.s	lbC0004E2
	tst.b	9(A6)
	bne.s	lbC00049A

	bsr.s	lbC0004E2
	tst.b	9(A6)
	bne.s	lbC00049A

	rts

lbC0004E2	addq.l	#4,A0
lbC0004E4	cmp.b	#$90,$48(A0)
	blo.s	lbC000500

	cmp.b	#$FE,$48(A0)
	bne.s	lbC00050A

	st	$48(A0)
	move.b	$49(A0),D0
	bra	lbC001120

lbC000500	tst.b	$6A(A0)
	beq.s	lbC00050C

	subq.b	#1,$6A(A0)
lbC00050A	rts

lbC00050C	move.w	$68(A0),D0
	add.w	D0,D0
	add.w	D0,D0
	move.l	$28(A0),A1
	move.l	0(A1,D0.W),12(A6)
	move.b	12(A6),D0
	cmp.b	#$F0,D0
	bhs.s	lbC00056C

	move.b	D0,D7
	cmp.b	#$C0,D0
	bhs.s	lbC000540

	cmp.b	#$7F,D0
	blo.s	lbC000540

	move.b	15(A6),$6A(A0)
	clr.b	15(A6)
lbC000540	move.b	$49(A0),D1
	add.b	D1,D0
	cmp.b	#$C0,D7
	bhs.s	lbC000550

	and.b	#$3F,D0
lbC000550	move.b	D0,12(A6)
	move.l	12(A6),D0
	bsr	lbC000F90
	cmp.b	#$C0,D7
	bhs.s	lbC0005B4

	cmp.b	#$7F,D7
	blo.s	lbC0005B4

	bra	lbC000630

lbC00056C	and.w	#15,D0
	add.w	D0,D0
	add.w	D0,D0
	jmp	lbC000578(PC,D0.W)

lbC000578	bra	lbC0005BC

	bra	lbC0005E0

	bra	lbC000606

	bra	lbC00062A

	bra	lbC000636

	bra	lbC00063C

	bra	lbC000644

	bra	lbC000644

	bra	lbC0005B4

	bra	lbC0005B4

	bra	lbC0005B4

	bra	lbC000650

	bra	lbC000644

	bra	lbC0005B4

	bra	lbC000636

lbC0005B4	addq.w	#1,$68(A0)
	bra	lbC00050C

lbC0005BC	st	$48(A0)
	move.w	4(A5),D0
	cmp.w	2(A5),D0
	bne.s	lbC0005D2

	move.w	0(A5),4(A5)
	bra.s	lbC0005D6

lbC0005D2	addq.w	#1,4(A5)
lbC0005D6	bsr	lbC00068C
	st	9(A6)
	rts

lbC0005E0	tst.b	$4A(A0)
	beq.s	lbC0005F6

	subq.b	#1,$4A(A0)
	beq.s	lbC0005B4

	move.w	14(A6),$68(A0)
	bra	lbC00050C

lbC0005F6	move.b	13(A6),$4A(A0)
	move.w	14(A6),$68(A0)
	bra	lbC00050C

lbC000606	move.b	13(A6),D0
	move.b	D0,$48(A0)
	add.w	D0,D0
	add.w	D0,D0
	move.l	$26(A6),A1
	move.l	0(A1,D0.W),D0
	add.l	A4,D0
	move.l	D0,$28(A0)
	move.w	14(A6),$68(A0)
	bra	lbC00050C

lbC00062A	move.b	13(A6),$6A(A0)
lbC000630	addq.w	#1,$68(A0)
	rts

lbC000636	st	$48(A0)
	rts

lbC00063C	move.b	$49(A0),D1
	add.b	D1,13(A6)
lbC000644	move.l	12(A6),D0
	bsr	lbC000F90
	bra	lbC0005B4

lbC000650	move.b	14(A6),D1
	and.w	#7,D1
	add.w	D1,D1
	add.w	D1,D1
	move.b	13(A6),D0
	move.b	D0,$48(A5,D1.W)
	move.b	15(A6),$49(A5,D1.W)
	and.w	#$7F,D0
	add.w	D0,D0
	add.w	D0,D0
	move.l	$26(A6),A1
	move.l	0(A1,D0.W),D0
	add.l	A4,D0
	move.l	D0,$28(A5,D1.W)
	clr.l	$68(A5,D1.W)
	sf	$4A(A5,D1.W)
	bra	lbC0005B4

lbC00068C	movem.l	A0/A1,-(SP)
lbC000690	move.w	4(A5),D0
	lsl.w	#4,D0
	move.l	$22(A6),A0
	add.w	D0,A0
	move.l	$26(A6),A1
	move.w	(A0)+,D0
	cmp.w	#$EFFE,D0
	bne.s	lbC0006C6

	move.w	(A0)+,D0
	add.w	D0,D0
	add.w	D0,D0
	jmp	lbC0006B2(PC,D0.W)

lbC0006B2	bra	lbC0007B0

	bra	lbC0007BA

	bra	lbC0007E8

	bra	lbC0007F8

	bra	lbC000820

lbC0006C6	move.w	D0,$48(A5)
	bmi.s	lbC0006E2

	clr.b	D0
	lsr.w	#6,D0
	move.l	0(A1,D0.W),D0
	add.l	A4,D0
	move.l	D0,$28(A5)
	clr.l	$68(A5)
	sf	$4A(A5)
lbC0006E2	movem.w	(A0)+,D0-D6
	move.w	D0,$4C(A5)
	bmi.s	lbC000702

	clr.b	D0
	lsr.w	#6,D0
	move.l	0(A1,D0.W),D0
	add.l	A4,D0
	move.l	D0,$2C(A5)
	clr.l	$6C(A5)
	sf	$4E(A5)
lbC000702	move.w	D1,$50(A5)
	bmi.s	lbC00071E

	clr.b	D1
	lsr.w	#6,D1
	move.l	0(A1,D1.W),D0
	add.l	A4,D0
	move.l	D0,$30(A5)
	clr.l	$70(A5)
	sf	$52(A5)
lbC00071E	move.w	D2,$54(A5)
	bmi.s	lbC00073A

	clr.b	D2
	lsr.w	#6,D2
	move.l	0(A1,D2.W),D0
	add.l	A4,D0
	move.l	D0,$34(A5)
	clr.l	$74(A5)
	sf	$56(A5)
lbC00073A	move.w	D3,$58(A5)
	bmi.s	lbC000756

	clr.b	D3
	lsr.w	#6,D3
	move.l	0(A1,D3.W),D0
	add.l	A4,D0
	move.l	D0,$38(A5)
	clr.l	$78(A5)
	sf	$5A(A5)
lbC000756	move.w	D4,$5C(A5)
	bmi.s	lbC000772

	clr.b	D4
	lsr.w	#6,D4
	move.l	0(A1,D4.W),D0
	add.l	A4,D0
	move.l	D0,$3C(A5)
	clr.l	$7C(A5)
	sf	$5E(A5)
lbC000772	move.w	D5,$60(A5)
	bmi.s	lbC00078E

	clr.b	D5
	lsr.w	#6,D5
	move.l	0(A1,D5.W),D0
	add.l	A4,D0
	move.l	D0,$40(A5)
	clr.l	$80(A5)
	sf	$62(A5)
lbC00078E	move.w	D6,$64(A5)
	bmi.s	lbC0007AA

	clr.b	D6
	lsr.w	#6,D6
	move.l	0(A1,D6.W),D0
	add.l	A4,D0
	move.l	D0,$44(A5)
	clr.l	$84(A5)
	sf	$66(A5)
lbC0007AA	movem.l	(SP)+,A0/A1
	rts

lbC0007B0	clr.b	$12(A6)
	movem.l	(SP)+,A0/A1
	rts

lbC0007BA	tst.w	$20(A6)
	beq.s	lbC0007C8

	bmi.s	lbC0007D6

	subq.w	#1,$20(A6)
	bra.s	lbC0007E0

lbC0007C8	move.w	#$FFFF,$20(A6)
	addq.w	#1,4(A5)
	bra	lbC000690

lbC0007D6	move.w	2(A0),D0
	subq.w	#1,D0
	move.w	D0,$20(A6)
lbC0007E0	move.w	(A0),4(A5)
	bra	lbC000690

lbC0007E8	move.w	(A0),6(A5)
	move.w	(A0),$10(A6)
	addq.w	#1,4(A5)
	bra	lbC000690

lbC0007F8	addq.w	#1,4(A5)
	tst.w	(A0)
	bmi	lbC000806

	move.w	(A0),$38(A6)
lbC000806	tst.w	2(A0)
	bmi	lbC000818

	move.w	2(A0),D0
	ext.w	D0
	move.w	D0,$3A(A6)
lbC000818	bsr	lbC001CE2
	bra	lbC000690

lbC000820	addq.w	#1,4(A5)
	move.b	3(A0),$1B(A6)
	move.b	1(A0),$1C(A6)
	move.b	1(A0),$1D(A6)
	beq.s	lbC000854

	move.b	#1,11(A6)
	move.b	$1A(A6),D0
	cmp.b	$1B(A6),D0
	beq.s	lbC00085A

	blo	lbC000690

	neg.b	11(A6)
	bra	lbC000690

lbC000854	move.b	$1B(A6),$1A(A6)
lbC00085A	move.b	#0,11(A6)
	bra	lbC000690

lbC000864	lea	lbL0015F2(PC),A5
	bsr.s	lbC000898
	lea	lbL001656(PC),A5
	bsr.s	lbC000898
	lea	lbL0016BA(PC),A5
	bsr.s	lbC000898
	tst.b	$36(A6)
	beq.s	lbC000894

	lea	lbL001782(PC),A5
	bsr.s	lbC000898
	lea	lbL0017E6(PC),A5
	bsr.s	lbC000898
	lea	lbL00184A(PC),A5
	bsr.s	lbC000898
	lea	lbL0018AE(PC),A5
	bra.s	lbC000898

lbC000894	lea	lbL00171E(PC),A5
lbC000898	move.l	$4C(A5),A4
	tst.w	$3E(A5)
	bmi.s	lbC0008A8

	subq.w	#1,$3E(A5)
	bra.s	lbC0008B0

lbC0008A8	clr.b	$3C(A5)
	clr.b	$3D(A5)
lbC0008B0	move.l	$54(A5),D0
	beq.s	lbC0008C8

	clr.l	$54(A5)
	clr.b	$3C(A5)
	bsr	lbC000F90
	move.b	$3D(A5),$3C(A5)
lbC0008C8	tst.b	0(A5)
	beq	lbC000DFA

	tst.w	$12(A5)
	beq.s	lbC0008DE

	subq.w	#1,$12(A5)
	bra	lbC000DFA

lbC0008DE	move.l	12(A5),A0
	move.w	$10(A5),D0
	add.w	D0,D0
	add.w	D0,D0
	lea	0(A0,D0.W),A0
	move.l	(A0),12(A6)
	moveq	#0,D0
	move.b	12(A6),D0
	clr.b	12(A6)
	add.w	D0,D0
	add.w	D0,D0
	jmp	lbC000904(PC,D0.W)

lbC000904	bra	lbC0009EE

	bra	lbC000A3C

	bra	lbC000A7A

	bra	lbC000ACC

	bra	lbC000AE0

	bra	lbC000BB6

	bra	lbC000D60

	bra	lbC000BDE

	bra	lbC000C4E

	bra	lbC000C46

	bra	lbC000D1C

	bra	lbC000CA6

	bra	lbC000CC8

	bra	lbC000BE6

	bra	lbC000C00

	bra	lbC000CFC

	bra	lbC000BAE

	bra	lbC000A94

	bra	lbC000AB2

	bra	lbC0009FA

	bra	lbC000D30

	bra	lbC000D54

	bra	lbC000DA8

	bra	lbC000C8E

	bra	lbC000DB8

	bra	lbC000DD8

	bra	lbC000AEA

	bra	lbC000BAE

	bra	lbC000B5E

	bra	lbC000B74

	bra	lbC000BAE

	bra	lbC000C3C

	bra	lbC0009E6

	bra	lbC000C0E

	bra	lbC0009E6

	bra	lbC0009E6

	bra	lbC0009E6

	bra	lbC0009E6

	bra	lbC0009E6

	bra	lbC0009E6

	bra	lbC0009E6

	bra	lbC0009E6

	bra	lbC0009E6

	bra	lbC0009E6

	bra	lbC0009E6

	bra	lbC0009E6

	bra	lbC0009E6

	bra	lbC0009E6

	bra	lbC000D90

	bra	lbC000C2A

	bra	lbC000B8A

	bra	lbC000B9C

lbC0009D4	tst.b	$5A(A5)
	beq.s	lbC0009E2

	addq.w	#1,$10(A5)
	bra	lbC000DFA

lbC0009E2	st	$5A(A5)
lbC0009E6	addq.w	#1,$10(A5)
	bra	lbC0008DE

lbC0009EE	clr.b	$1C(A5)
	clr.b	$26(A5)
	clr.w	$30(A5)
lbC0009FA	addq.w	#1,$10(A5)
	move.l	$5C(A5),A0
	cmp.l	#0,A0
	beq.s	lbC000A1A

	clr.b	(A0)
	clr.b	$5A(A5)
	move.l	$60(A5),A0
	jsr	(A0)
	bra	lbC0008DE

lbC000A1A	tst.b	13(A6)
	bne.s	lbC000A2C

	move.w	$16(A5),$DFF096
	bra	lbC0008DE

lbC000A2C	move.w	$16(A5),D0
	or.w	D0,$34(A6)
	clr.b	$5A(A5)
	bra	lbC000DFA

lbC000A3C	move.w	$46(A5),$DFF09A
	move.w	$46(A5),$DFF09C
	move.b	13(A6),1(A5)
	addq.w	#1,$10(A5)
	move.l	$5C(A5),A0
	cmp.l	#0,A0
	beq.s	lbC000A6E

	st	(A0)
	move.l	$60(A5),A0
	jsr	(A0)
	bra	lbC000DFA

lbC000A6E	move.w	$14(A5),D0
	or.w	D0,$32(A6)
	bra	lbC0008DE

lbC000A7A	clr.b	3(A5)
	move.l	12(A6),D0
	add.l	4(A6),D0
lbC000A86	move.l	D0,$2C(A5)
	move.l	D0,(A4)
	addq.w	#1,$10(A5)
	bra	lbC0008DE

lbC000A94	move.b	13(A6),3(A5)
	move.b	13(A6),$1B(A5)
	move.w	14(A6),D1
	ext.l	D1
	move.l	D1,$50(A5)
	move.l	$2C(A5),D0
	add.l	D1,D0
	bra.s	lbC000A86

lbC000AB2	move.w	14(A6),D0
	move.w	$34(A5),D1
	add.w	D0,D1
	move.w	D1,$34(A5)
	move.w	D1,4(A4)
	addq.w	#1,$10(A5)
	bra	lbC0008DE

lbC000ACC	move.w	14(A6),$34(A5)
	move.w	14(A6),4(A4)
	addq.w	#1,$10(A5)
	bra	lbC0008DE

lbC000AE0	move.w	14(A6),$12(A5)
	bra	lbC0009D4

lbC000AEA	move.w	14(A6),6(A5)
	clr.b	0(A5)
	move.w	$44(A5),$DFF09A
	bra	lbC0009D4

lbC000B00	movem.l	D0/A5,-(SP)
	lea	lbL0015F2(PC),A5
	move.w	$DFF01E,D0
	and.w	$DFF01C,D0
	btst	#7,D0
	bne.s	lbC000B3C

	lea	lbL001656(PC),A5
	btst	#8,D0
	bne.s	lbC000B3C

	lea	lbL0016BA(PC),A5
	btst	#9,D0
	bne.s	lbC000B3C

	move.b	lbB00159A(PC),D0
	beq.s	lbC000B38

	bra	lbC00202C

lbC000B38	lea	lbL00171E(PC),A5
lbC000B3C	move.w	$46(A5),$DFF09C
	subq.w	#1,6(A5)
	bpl.s	lbC000B58

	move.b	#$FF,0(A5)
	move.w	$46(A5),$DFF09A
lbC000B58	movem.l	(SP)+,D0/A5
	rte

lbC000B5E	move.b	13(A6),D0
	cmp.b	5(A5),D0
	bhs	lbC0009E6

	move.w	14(A6),$10(A5)
	bra	lbC0008DE

lbC000B74	move.b	13(A6),D0
	cmp.b	$18(A5),D0
	bhs	lbC0009E6

	move.w	14(A6),$10(A5)
	bra	lbC0008DE

lbC000B8A	move.w	12(A6),D1
	add.w	D1,D1
	move.w	14(A6),D0
	add.w	D0,0(A0,D1.W)
	bra	lbC0009E6

lbC000B9C	move.w	12(A6),D1
	add.w	D1,D1
	move.w	14(A6),D0
	and.w	D0,0(A0,D1.W)
	bra	lbC0009E6

lbC000BAE	tst.b	$36(A5)
	beq	lbC0009E6

lbC000BB6	tst.b	$1A(A5)
	beq.s	lbC000BCE

	subq.b	#1,$1A(A5)
	beq	lbC0009E6

	move.w	14(A6),$10(A5)
	bra	lbC0008DE

lbC000BCE	move.b	13(A6),$1A(A5)
	move.w	14(A6),$10(A5)
	bra	lbC0008DE

lbC000BDE	clr.b	0(A5)
	bra	lbC000DFA

lbC000BE6	move.w	8(A5),D0
	add.w	D0,D0
	add.w	8(A5),D0
	add.w	14(A6),D0
	move.b	D0,$18(A5)
	addq.w	#1,$10(A5)
	bra	lbC0008DE

lbC000C00	move.b	15(A6),$18(A5)
	addq.w	#1,$10(A5)
	bra	lbC0008DE

lbC000C0E	move.b	5(A5),12(A6)
	move.b	9(A5),D0
	lsl.b	#4,D0
	or.b	D0,14(A6)
	move.l	12(A6),D0
	bsr	lbC000F90
	bra	lbC0009E6

lbC000C2A	move.b	#$F5,12(A6)
	move.l	12(A6),D0
	bsr	lbC000F90
	bra	lbC0009E6

lbC000C3C	move.b	4(A5),D2
	lea	lbC0009D4(PC),A1
	bra.s	lbC000C56

lbC000C46	moveq	#0,D2
	lea	lbC0009D4(PC),A1
	bra.s	lbC000C56

lbC000C4E	move.b	5(A5),D2
	lea	lbC0009D4(PC),A1
lbC000C56	move.b	13(A6),D0
	add.b	D2,D0
	and.b	#$3F,D0
	ext.w	D0
	add.w	D0,D0
	lea	lbW001C32(PC),A0
	move.w	0(A0,D0.W),D0
	move.w	10(A5),D1
	add.w	14(A6),D1
	beq.s	lbC000C7E

	add.w	#$100,D1
	mulu	D1,D0
	lsr.l	#8,D0
lbC000C7E	move.w	D0,$28(A5)
	tst.w	$30(A5)
	bne.s	lbC000C8C

	move.w	D0,$58(A5)
lbC000C8C	jmp	(A1)

lbC000C8E	move.w	14(A6),$28(A5)
	tst.w	$30(A5)
	bne	lbC0009E6

	move.w	14(A6),$58(A5)
	bra	lbC0009E6

lbC000CA6	move.b	13(A6),$22(A5)
	move.b	#1,$23(A5)
	tst.w	$30(A5)
	bne.s	lbC000CBE

	move.w	$28(A5),$32(A5)
lbC000CBE	move.w	14(A6),$30(A5)
	bra	lbC0009E6

lbC000CC8	move.b	13(A6),D0
	move.b	D0,$26(A5)
	lsr.b	#1,D0
	move.b	D0,$27(A5)
	move.b	15(A6),$20(A5)
	move.b	#1,$21(A5)
	tst.w	$30(A5)
	bne	lbC0009E6

	move.w	$28(A5),$58(A5)
	clr.w	$24(A5)
	addq.w	#1,$10(A5)
	bra	lbC0008DE

lbC000CFC	move.b	14(A6),$1C(A5)
	move.b	13(A6),$1F(A5)
	move.b	14(A6),$1D(A5)
	move.b	15(A6),$1E(A5)
	addq.w	#1,$10(A5)
	bra	lbC0008DE

lbC000D1C	clr.b	3(A5)
	clr.b	$1C(A5)
	clr.b	$26(A5)
	clr.w	$30(A5)
	bra	lbC0009E6

lbC000D30	tst.b	$36(A5)
	beq	lbC0009E6

	tst.b	$1A(A5)
	beq.s	lbC000D4A

	subq.b	#1,$1A(A5)
	beq	lbC0009E6

	bra	lbC000DFA

lbC000D4A	move.b	15(A6),$1A(A5)
	bra	lbC000DFA

lbC000D54	move.l	12(A5),$38(A5)
	move.w	$10(A5),$40(A5)
lbC000D60	move.b	13(A6),D0
	and.l	#$7F,D0
	move.l	$2A(A6),A0
	add.w	D0,D0
	add.w	D0,D0
	add.w	D0,A0
	move.l	(A0),D0
	add.l	0(A6),D0
	move.l	D0,12(A5)
	move.w	14(A6),$10(A5)
	sf	$1A(A5)
	sf	$5B(A5)
	bra	lbC0008DE

lbC000D90	tst.b	$5B(A5)
	bne.s	lbC000D9E

	st	$5B(A5)
	bra	lbC0009E6

lbC000D9E	move.w	14(A6),$10(A5)
	bra	lbC0008DE

lbC000DA8	move.l	$38(A5),12(A5)
	move.w	$40(A5),$10(A5)
	bra	lbC0009E6

lbC000DB8	move.l	12(A6),D0
	add.l	D0,$2C(A5)
	move.l	$2C(A5),(A4)
	lsr.w	#1,D0
	sub.w	D0,$34(A5)
	move.w	$34(A5),4(A4)
	addq.w	#1,$10(A5)
	bra	lbC0008DE

lbC000DD8	clr.b	3(A5)
	move.l	4(A6),$2C(A5)
	move.l	4(A6),(A4)
	move.w	#1,$34(A5)
	move.w	#1,4(A4)
	addq.w	#1,$10(A5)
	bra	lbC0008DE

lbC000DFA	tst.b	1(A5)
	bmi.s	lbC000E08

	bne.s	lbC000E0C

	move.b	#1,1(A5)
lbC000E08	bra	lbC000F2A

lbC000E0C	tst.b	3(A5)
	beq.s	lbC000E32

	move.l	$2C(A5),D0
	add.l	$50(A5),D0
	move.l	D0,$2C(A5)
	move.l	D0,(A4)
	sub.b	#1,3(A5)
	bne.s	lbC000E32

	move.b	$1B(A5),3(A5)
	neg.l	$50(A5)
lbC000E32	tst.b	$26(A5)
	beq.s	lbC000E7C

	move.b	$20(A5),D0
	ext.w	D0
	add.w	D0,$24(A5)
	move.w	$28(A5),D0
	move.w	$24(A5),D1
	beq.s	lbC000E5C

	and.l	#$FFFF,D0
	add.w	#$800,D1
	mulu	D1,D0
	lsl.l	#5,D0
	swap	D0
lbC000E5C	tst.w	$30(A5)
	bne.s	lbC000E66

	move.w	D0,$58(A5)
lbC000E66	subq.b	#1,$27(A5)
	bne.s	lbC000E7C

	move.b	$26(A5),$27(A5)
	eor.b	#$FF,$20(A5)
	addq.b	#1,$20(A5)
lbC000E7C	tst.w	$30(A5)
	beq	lbC000EDC

	subq.b	#1,$23(A5)
	bne.s	lbC000EDC

	move.b	$22(A5),$23(A5)
	move.w	$28(A5),D1
	moveq	#0,D0
	move.w	$32(A5),D0
	cmp.w	D1,D0
	beq.s	lbC000EB2

	blo.s	lbC000EC8

	move.w	#$100,D2
	sub.w	$30(A5),D2
	mulu	D2,D0
	lsr.l	#8,D0
	cmp.w	D1,D0
	beq.s	lbC000EB2

	bhs.s	lbC000EBA

lbC000EB2	clr.w	$30(A5)
	move.w	$28(A5),D0
lbC000EBA	and.w	#$7FF,D0
	move.w	D0,$32(A5)
	move.w	D0,$58(A5)
	bra.s	lbC000EDC

lbC000EC8	move.w	$30(A5),D2
	add.w	#$100,D2
	mulu	D2,D0
	lsr.l	#8,D0
	cmp.w	D1,D0
	beq.s	lbC000EB2

	bhs.s	lbC000EB2

	bra.s	lbC000EBA

lbC000EDC	tst.b	$1C(A5)
	beq.s	lbC000F2A

	tst.b	$1D(A5)
	beq.s	lbC000EEE

	subq.b	#1,$1D(A5)
	bra.s	lbC000F2A

lbC000EEE	move.b	$1C(A5),$1D(A5)
	move.b	$1E(A5),D0
	cmp.b	$18(A5),D0
	bgt.s	lbC000F1C

	move.b	$1F(A5),D1
	sub.b	D1,$18(A5)
	bmi.s	lbC000F10

	cmp.b	$18(A5),D0
	bge.s	lbC000F10

	bra.s	lbC000F2A

lbC000F10	move.b	$1E(A5),$18(A5)
	clr.b	$1C(A5)
	bra.s	lbC000F2A

lbC000F1C	move.b	$1F(A5),D1
	add.b	D1,$18(A5)
	cmp.b	$18(A5),D0
	ble.s	lbC000F10

lbC000F2A	tst.b	11(A6)
	beq.s	lbC000F52

	subq.b	#1,$1C(A6)
	bne.s	lbC000F52

	move.b	$1D(A6),$1C(A6)
	move.b	11(A6),D0
	add.b	D0,$1A(A6)
	move.b	$1B(A6),D0
	cmp.b	$1A(A6),D0
	bne.s	lbC000F52

	clr.b	11(A6)
lbC000F52	moveq	#0,D1
	move.b	$1A(A6),D1
	moveq	#0,D0
	move.b	$18(A5),D0
	tst.b	$36(A6)
	beq.s	lbC000F76

	tst.l	$5C(A5)
	beq.s	lbC000F76

	move.w	D1,$DFF0D8
	move.w	D0,8(A4)
	bra.s	lbC000F8E

lbC000F76	tst.w	$3E(A5)
	bpl.s	lbC000F8A

	btst	#6,D1
	bne.s	lbC000F8A

	add.w	D0,D0
	add.w	D0,D0
	mulu	D1,D0
	lsr.w	#8,D0
lbC000F8A	move.w	D0,8(A4)
lbC000F8E	rts

lbC000F90	movem.l	D0/A4-A6,-(SP)
	lea	lbL001564(PC),A6
	move.l	12(A6),-(SP)
	lea	lbL0015B2(PC),A5
	move.l	D0,12(A6)
	move.b	14(A6),D0
	and.w	#15,D0
	cmp.w	#3,D0
	beq.s	lbC000FC6

	ble.s	lbC000FD0

	cmp.w	#7,D0
	bgt.s	lbC000FD0

	tst.b	$36(A6)
	bne.s	lbC000FD0

	bsr	lbC001CE2
	bra.s	lbC000FD0

lbC000FC6	tst.b	$36(A6)
	beq.s	lbC000FD0

	bsr	lbC001DC4
lbC000FD0	add.w	D0,D0
	add.w	D0,D0
	move.l	0(A5,D0.W),A5
	move.b	12(A6),D0
	cmp.b	#$FC,D0
	bne.s	lbC000FF4

	move.b	13(A6),$3C(A5)
	move.b	15(A6),D0
	move.w	D0,$3E(A5)
	bra	lbC0010DA

lbC000FF4	tst.b	$3C(A5)
	bne	lbC0010DA

	tst.b	D0
	bpl	lbC001066

	cmp.b	#$F7,D0
	bne.s	lbC001028

	move.b	13(A6),$1F(A5)
	move.b	14(A6),D0
	lsr.b	#4,D0
	addq.b	#1,D0
	move.b	D0,$1D(A5)
	move.b	D0,$1C(A5)
	move.b	15(A6),$1E(A5)
	bra	lbC0010DA

lbC001028	cmp.b	#$F6,D0
	bne.s	lbC001054

	move.b	13(A6),D0
	and.b	#$FE,D0
	move.b	D0,$26(A5)
	lsr.b	#1,D0
	move.b	D0,$27(A5)
	move.b	15(A6),$20(A5)
	move.b	#1,$21(A5)
	clr.w	$24(A5)
	bra	lbC0010DA

lbC001054	cmp.b	#$F5,D0
	bne.s	lbC001060

	clr.b	$36(A5)
	bra.s	lbC0010DA

lbC001060	cmp.b	#$BF,D0
	bhs.s	lbC0010E4

lbC001066	move.b	15(A6),D0
	ext.w	D0
	move.w	D0,10(A5)
	move.b	14(A6),D0
	lsr.b	#4,D0
	and.w	#15,D0
	move.b	D0,9(A5)
	move.b	13(A6),D0
	move.b	5(A5),4(A5)
	move.b	12(A6),5(A5)
	move.l	$2A(A6),A4
	add.w	D0,D0
	add.w	D0,D0
	add.w	D0,A4
	move.l	(A4),A4
	add.l	0(A6),A4
	cmp.l	12(A5),A4
	beq.s	lbC0010A8

	sf	$5B(A5)
lbC0010A8	move.l	A4,12(A5)
	clr.w	$10(A5)
	clr.w	$12(A5)
	clr.b	1(A5)
	sf	$1A(A5)
	st	0(A5)
	clr.w	6(A5)
	move.w	$46(A5),$DFF09A
	move.w	$46(A5),$DFF09C
	move.b	#1,$36(A5)
lbC0010DA	move.l	(SP)+,12(A6)
	movem.l	(SP)+,D0/A4-A6
	rts

lbC0010E4	move.b	13(A6),$22(A5)
	move.b	#1,$23(A5)
	tst.w	$30(A5)
	bne.s	lbC0010FC

	move.w	$28(A5),$32(A5)
lbC0010FC	clr.w	$30(A5)
	move.b	15(A6),$31(A5)
	move.b	12(A6),D0
	and.w	#$3F,D0
	move.b	D0,5(A5)
	add.w	D0,D0
	lea	lbW001C32(PC),A4
	move.w	0(A4,D0.W),$28(A5)
	bra.s	lbC0010DA

lbC001120	move.l	A5,-(SP)
	lea	lbL0015B2(PC),A5
	and.w	#15,D0
	add.w	D0,D0
	add.w	D0,D0
	move.l	0(A5,D0.W),A5
	tst.b	$3C(A5)
	bne.s	lbC001164

	move.w	$46(A5),$DFF09A
	move.w	$16(A5),$DFF096
	clr.b	0(A5)
	move.l	A0,-(SP)
	move.l	$5C(A5),A0
	cmp.l	#0,A0
	beq.s	lbC001162

	clr.b	(A0)
	move.l	$60(A5),A0
	jsr	(A0)
lbC001162	move.l	(SP)+,A0
lbC001164	move.l	(SP)+,A5
	rts

lbC001168	movem.l	A5/A6,-(SP)
	lea	lbL001564(PC),A6
	move.b	D0,$1B(A6)
	swap	D0
	move.b	D0,$1C(A6)
	move.b	D0,$1D(A6)
	beq.s	lbC001198

	move.b	$1A(A6),D0
	move.b	#1,11(A6)
	cmp.b	$1B(A6),D0
	beq.s	lbC00119E

	blo.s	lbC0011A2

	neg.b	11(A6)
	bra.s	lbC0011A2

lbC001198	move.b	$1B(A6),$1A(A6)
lbC00119E	clr.b	11(A6)
lbC0011A2	movem.l	(SP)+,A5/A6
	rts

lbC0011A8	movem.l	D1-D3/A4-A6,-(SP)
	lea	lbL001564(PC),A6
	lea	lbL0015B2(PC),A4
	move.w	D0,D2
	move.l	0(A6),A5
	tst.l	$1D0(A5)
	bne.s	lbC0011CA

	move.l	$5FC(A5),A5
	add.l	0(A6),A5
	bra.s	lbC0011CE

lbC0011CA	move.l	$2E(A6),A5
lbC0011CE	lsl.w	#3,D2
	move.b	2(A5,D2.W),D3
	tst.b	10(A6)
	bpl.s	lbC0011DE

	move.b	4(A5,D2.W),D3
lbC0011DE	and.w	#15,D3
	add.w	D3,D3
	add.w	D3,D3
	move.l	0(A4,D3.W),A4
	lsl.w	#6,D3
	move.b	5(A5,D2.W),D1
	bclr	#7,D1
	cmp.b	$3D(A4),D1
	bhs.s	lbC001200

	tst.w	$3E(A4)
	bpl.s	lbC001232

lbC001200	cmp.b	$42(A4),D2
	bne.s	lbC001214

	tst.w	$3E(A4)
	bmi.s	lbC001214

	btst	#7,5(A5,D2.W)
	bne.s	lbC001232

lbC001214	move.l	0(A5,D2.W),D0
	and.l	#$FFFFF0FF,D0
	or.w	D3,D0
	move.l	D0,$54(A4)
	move.b	D1,$3D(A4)
	move.w	6(A5,D2.W),$3E(A4)
	move.b	D2,$42(A4)
lbC001232	movem.l	(SP)+,D1-D3/A4-A6
	rts

lbC001238	clr.b	0(A6)
	sf	$5B(A6)
	clr.l	$3C(A6)
	clr.l	$54(A6)
	rts

lbC00124A	move.l	A6,-(SP)
	lea	lbL001564(PC),A6
	clr.b	$12(A6)
	clr.w	$32(A6)
	lea	lbL0015F2(PC),A6
	bsr.s	lbC001238
	lea	lbL001656(PC),A6
	bsr.s	lbC001238
	lea	lbL0016BA(PC),A6
	bsr.s	lbC001238
	lea	lbL00171E(PC),A6
	bsr.s	lbC001238
	lea	lbL001782(PC),A6
	bsr.s	lbC001238
	lea	lbL0017E6(PC),A6
	bsr.s	lbC001238
	lea	lbL00184A(PC),A6
	bsr.s	lbC001238
	lea	lbL0018AE(PC),A6
	bsr.s	lbC001238
	bsr	lbC001DC4
	clr.w	$DFF0A8
	clr.w	$DFF0B8
	clr.w	$DFF0C8
	clr.w	$DFF0D8
	move.w	#15,$DFF096
	move.w	#$780,$DFF09C
	move.w	#$780,$DFF09A
	move.w	#$780,$DFF09C
	move.l	(SP)+,A6
	rts

lbC0012C8	movem.l	D1-D7/A0-A6,-(SP)
	lea	lbL001564(PC),A6
	move.b	D0,$19(A6)
	clr.b	$1F(A6)
	bsr.s	lbC001300
	movem.l	(SP)+,D1-D7/A0-A6
	rts

lbC0012E0	movem.l	D1-D7/A0-A6,-(SP)
	lea	lbL001564(PC),A6
	or.w	#$100,D0
	move.w	D0,$18(A6)
	clr.b	$1F(A6)
	bsr.s	lbC001300
	movem.l	(SP)+,D1-D7/A0-A6
	rts

	lea	lbL001564(PC),A6
lbC001300	bsr	lbC00124A
	clr.b	$12(A6)
	move.l	0(A6),A4
	move.b	$19(A6),D0
	and.w	#$1F,D0
	add.w	D0,D0
	add.w	D0,A4
	lea	lbL001AA2(PC),A5
	move.b	10(A6),D1
	bmi	lbC00133A

	and.w	#$1F,D1
	add.w	D1,D1
	lea	lbL001B6A(PC),A0
	add.w	D1,A0
	move.w	4(A5),(A0)
	move.b	7(A5),$41(A0)
lbC00133A	move.w	$100(A4),4(A5)
	move.w	$100(A4),0(A5)
	move.w	$140(A4),2(A5)
	move.w	$180(A4),D2
	btst	#0,$18(A6)
	beq.s	lbC001368

	lea	lbL001B6A(PC),A0
	add.w	D0,A0
	move.w	(A0),4(A5)
	moveq	#0,D2
	move.b	$41(A0),D2
lbC001368	move.w	#$1C,D1
	lea	lbW001C2A(PC),A4
lbC001370	move.l	A4,$28(A5,D1.W)
	move.w	#$FF00,$48(A5,D1.W)
	clr.l	$68(A5,D1.W)
	subq.w	#4,D1
	bpl.s	lbC001370

	move.w	D2,6(A5)
	tst.b	$19(A6)
	bmi.s	lbC001394

	move.l	0(A6),A4
	bsr	lbC00068C
lbC001394	clr.b	9(A6)
	clr.w	$10(A6)
	st	$20(A6)
	move.b	$19(A6),10(A6)
	clr.b	$18(A6)
	clr.w	$32(A6)
	bset	#1,$BFE001
	move.w	#$FF,$DFF09E
	move.b	#1,$12(A6)
	tst.b	$36(A6)
	beq.s	lbC0013E2

	move.w	#$8208,$DFF096
	move.w	#$C400,$DFF09A
	move.w	#$8400,$DFF09C
lbC0013E2	rts

lbC0013E4	movem.l	A2-A6,-(SP)
	lea	lbL001564(PC),A6
	move.l	#$40400000,$1A(A6)
	clr.b	11(A6)
	move.l	D0,0(A6)
	move.l	D1,4(A6)
	move.l	D2,$3C(A6)
	move.l	D1,A4
	clr.l	(A4)
	move.l	D0,A4
	tst.l	$1D0(A4)
	beq.s	lbC00143A

	move.l	$1D0(A4),D1
	add.l	D0,D1
	move.l	D1,$22(A6)
	move.l	$1D4(A4),D1
	add.l	D0,D1
	move.l	D1,$26(A6)
	move.l	$1D8(A4),D1
	add.l	D0,D1
	move.l	D1,$2A(A6)
	add.l	#$200,D0
	move.l	D0,$2E(A6)
	bra.s	lbC00145E

lbC00143A	move.l	#$800,D1
	add.l	D0,D1
	move.l	D1,$22(A6)
	move.l	#$400,D1
	add.l	D0,D1
	move.l	D1,$26(A6)
	move.l	#$600,D1
	add.l	D0,D1
	move.l	D1,$2A(A6)
lbC00145E	bsr	lbC00035C
	tst.l	$14(A6)
	bne.s	lbC00146E

	move.l	$70(A5),$14(A6)
lbC00146E	
	lea	lbC000B00(PC),A4
	move.l	A4,$70(A5)
	lea	lbL001AA2(PC),A5
	move.w	#5,6(A5)
	lea	lbL001B6A(PC),A6
	move.w	#$1F,D0
lbC001488	move.w	#5,$40(A6)
	clr.w	$80(A6)
	clr.w	(A6)+
	dbra	D0,lbC001488

	lea	lbL001564(PC),A6
	lea	lbL0015B2(PC),A4
	lea	lbL0015F2(PC),A5
	move.l	A5,(A4)+
	lea	lbL001656(PC),A5
	move.l	A5,(A4)+
	lea	lbL0016BA(PC),A5
	move.l	A5,(A4)+
	lea	lbL00171E(PC),A5
	move.l	A5,(A4)+
	moveq	#11,D0
lbC0014BA	move.l	-$10(A4),(A4)+
	dbra	D0,lbC0014BA

	lea	lbL0015C2(PC),A4
	lea	lbL001782(PC),A5
	lea	lbL002606(PC),A3
	move.l	A3,$4C(A5)
	lea	lbC001EFA(PC),A3
	move.l	A3,$60(A5)
	lea	lbL002682(PC),A2
	move.l	A2,$5C(A5)
	move.l	A5,(A4)+
	lea	lbL0017E6(PC),A5
	lea	lbL002616(PC),A3
	move.l	A3,$4C(A5)
	lea	lbC001F20(PC),A3
	move.l	A3,$60(A5)
	addq.l	#4,A2
	move.l	A2,$5C(A5)
	move.l	A5,(A4)+
	lea	lbL00184A(PC),A5
	lea	lbL002626(PC),A3
	move.l	A3,$4C(A5)
	lea	lbC001F46(PC),A3
	move.l	A3,$60(A5)
	addq.l	#4,A2
	move.l	A2,$5C(A5)
	move.l	A5,(A4)+
	lea	lbL0018AE(PC),A5
	lea	lbL002636(PC),A3
	move.l	A3,$4C(A5)
	lea	lbC001F6C(PC),A3
	move.l	A3,$60(A5)
	addq.l	#4,A2
	move.l	A2,$5C(A5)
	move.l	A5,(A4)+
	move.l	$3C(A6),$40(A6)
	move.l	$3C(A6),$44(A6)
	move.l	$3C(A6),$48(A6)
	add.l	#$1E0,$44(A6)
	add.l	#$3C0,$48(A6)
	bsr	lbC001E8E
	movem.l	(SP)+,A2-A6
	rts

lbL001564	dcb.l	$5,0
lbL001578	dc.l	0
	dc.l	$4040
	dc.l	0
	dc.l	$FFFF0000
	dcb.l	$4,0
	dc.w	0
lbB00159A	dcb.b	$3,0
	dc.b	$12
	dcb.b	$14,0
lbL0015B2	dcb.l	$4,0
lbL0015C2	dcb.l	$C,0
lbL0015F2	dcb.l	$5,0
	dc.l	$82010001
	dcb.l	$B,0
	dc.l	$80800080
	dc.l	$64
	dc.l	$DFF0A0
	dcb.l	$2,0
	dc.l	$FF00
	dcb.l	$2,0
lbL001656	dcb.l	$5,0
	dc.l	$82020002
	dcb.l	$B,0
	dc.l	$81000100
	dc.l	$64
	dc.l	$DFF0B0
	dcb.l	$2,0
	dc.l	$FF00
	dcb.l	$2,0
lbL0016BA	dcb.l	$5,0
	dc.l	$82040004
	dcb.l	$B,0
	dc.l	$82000200
	dc.l	$64
	dc.l	$DFF0C0
	dcb.l	$2,0
	dc.l	$FF00
	dcb.l	$2,0
lbL00171E	dcb.l	$5,0
	dc.l	$82080008
	dcb.l	$B,0
	dc.l	$84000400
	dc.l	$FFFFFED4
	dc.l	$DFF0D0
	dcb.l	$2,0
	dc.l	$FF00
	dcb.l	$2,0
lbL001782	dcb.l	$6,0
	dc.l	$40000000
	dcb.l	$B,0
	dc.l	$64
	dc.l	$DFF0D0
	dcb.l	$2,0
	dc.l	$FF00
	dcb.l	$2,0
lbL0017E6	dcb.l	$6,0
	dc.l	$40000000
	dcb.l	$B,0
	dc.l	$64
	dc.l	$DFF0D0
	dcb.l	$2,0
	dc.l	$FF00
	dcb.l	$2,0
lbL00184A	dcb.l	$6,0
	dc.l	$40000000
	dcb.l	$B,0
	dc.l	$64
	dc.l	$DFF0D0
	dcb.l	$2,0
	dc.l	$FF00
	dcb.l	$2,0
lbL0018AE	dcb.l	$6,0
	dc.l	$40000000
	dcb.l	$B,0
	dc.l	$FFFFFED4
	dc.l	$DFF0D0
	dcb.l	$2,0
	dc.l	$FF00
	dcb.l	$7,0
	dc.l	$82010001
	dcb.l	$D,0
	dc.l	$DFF0A0
	dcb.l	$2,0
	dc.l	$FF00
	dcb.l	$7,0
	dc.l	$82020002
	dcb.l	$D,0
	dc.l	$DFF0B0
	dcb.l	$2,0
	dc.l	$FF00
	dcb.l	$7,0
	dc.l	$82040004
	dcb.l	$D,0
	dc.l	$DFF0C0
	dcb.l	$2,0
	dc.l	$FF00
	dcb.l	$18,0
	dc.l	$FF00
	dcb.l	$2,0
lbL001AA2	dc.l	0
	dc.l	6
	dcb.l	$30,0
lbL001B6A	dcb.l	$30,0
lbW001C2A	dc.w	$F400
	dc.w	0
	dc.w	$F000
	dc.w	0
lbW001C32	dc.w	$6AE
	dc.w	$64E
	dc.w	$5F4
	dc.w	$59E
	dc.w	$54D
	dc.w	$501
	dc.w	$4B9
	dc.w	$475
	dc.w	$435
	dc.w	$3F9
	dc.w	$3C0
	dc.w	$38C
	dc.w	$358
	dc.w	$32A
	dc.w	$2FC
	dc.w	$2D0
	dc.w	$2A8
	dc.w	$282
	dc.w	$25E
	dc.w	$23B
	dc.w	$21B
	dc.w	$1FD
	dc.w	$1E0
	dc.w	$1C6
	dc.w	$1AC
	dc.w	$194
	dc.w	$17D
	dc.w	$168
	dc.w	$154
	dc.w	$140
	dc.w	$12F
	dc.w	$11E
	dc.w	$10E
	dc.w	$FE
	dc.w	$F0
	dc.w	$E3
	dc.w	$D6
	dc.w	$CA
	dc.w	$BF
	dc.w	$B4
	dc.w	$AA
	dc.w	$A0
	dc.w	$97
	dc.w	$8F
	dc.w	$87
	dc.w	$7F
	dc.w	$78
	dc.w	$71
	dc.w	$D6
	dc.w	$CA
	dc.w	$BF
	dc.w	$B4
	dc.w	$AA
	dc.w	$A0
	dc.w	$97
	dc.w	$8F
	dc.w	$87
	dc.w	$7F
	dc.w	$78
	dc.w	$71
	dc.w	$D6
	dc.w	$CA
	dc.w	$BF
	dc.w	$B4
lbL001CB2	dc.l	$DFC0DFC
	dc.l	$6FE04A9
	dc.w	$37F
	dc.w	$2CC
	dc.w	$255
	dc.w	$1FF
	dc.w	$1BF
	dc.w	$18E
	dc.w	$166
	dc.w	$145
	dc.w	$12A
	dc.w	$113
	dc.w	$100
	dc.w	$EF
	dc.w	$E0
	dc.w	$D3
	dc.w	$C7
	dc.w	$BC
	dc.w	$B3
	dc.w	$AA
	dc.w	$A3
	dc.w	$9C

lbC001CE2	movem.l	D0-D7/A0-A6,-(SP)
	move.w	#$400,$DFF09A
	lea	lbL001564(PC),A6
	lea	lbL00171E(PC),A4
	lea	lbL0025E6(PC),A5
	move.w	$38(A6),D0
	cmp.w	#$16,D0
	ble.s	lbC001D06

	moveq	#$16,D0
lbC001D06	move.w	D0,D1
	mulu	#$64,D1
	divu	#5,D1
	moveq	#$64,D3
	cmp.w	#$FFE0,$3A(A6)
	bge.s	lbC001D20

	move.w	#$FFE0,$3A(A6)
lbC001D20	add.w	$3A(A6),D3
	mulu	D3,D1
	divu	#$64,D1
	addq.l	#1,D1
	and.b	#$FE,D1
	move.w	D1,D2
	lsr.w	#1,D2
	move.w	D2,$72(A5)
	subq.w	#1,D1
	move.w	D1,$70(A5)
	lea	lbL001CB2(PC),A0
	add.w	D0,D0
	moveq	#0,D1
	move.w	0(A0,D0.W),D1
	move.l	D1,D2
	lsl.l	#8,D2
	lsl.l	#3,D2
	move.w	D1,$58(A4)
	move.w	D1,$DFF0D6
	and.w	#$FFF7,$34(A6)
	move.l	D2,$74(A5)
	move.l	$40(A6),$64(A5)
	move.l	$44(A6),$68(A5)
	move.l	$48(A6),$6C(A5)
	move.w	#0,$DFF0D8
	move.l	$64(A5),$DFF0D0
	move.w	#2,$DFF0D4
	move.w	#$8208,$4C(A6)
	move.w	#$C400,$DFF09A
	bsr	lbC001EFA
	bsr	lbC001F20
	bsr	lbC001F46
	bsr	lbC001F6C
	tst.b	$36(A6)
	bne.s	lbC001DBE

	move.w	#$8400,$DFF09C
	st	$36(A6)
lbC001DBE	movem.l	(SP)+,D0-D7/A0-A6
	rts

lbC001DC4	movem.l	D0-D7/A0-A6,-(SP)
	lea	lbL001564(PC),A6
	clr.w	$4C(A6)
	lea	lbL0025E6(PC),A5
	clr.b	$36(A6)
	clr.b	$37(A6)
	moveq	#3,D0
	bsr	lbC001120
	lea	lbL002682(PC),A5
	clr.l	(A5)+
	clr.l	(A5)+
	clr.l	(A5)+
	clr.l	(A5)+
	lea	lbL0025E6(PC),A5
	move.w	#$D0,D0
	move.w	D0,$2E(A5)
	move.w	D0,$3E(A5)
	move.w	D0,$4E(A5)
	move.w	D0,$5E(A5)
	moveq	#0,D0
	move.l	D0,0(A5)
	move.l	D0,4(A5)
	move.l	D0,8(A5)
	move.l	D0,12(A5)
	sf	$60(A5)
	sf	$61(A5)
	sf	$62(A5)
	sf	$63(A5)
	move.l	#$FFF0,D0
	move.l	D0,D1
	move.l	D0,D2
	move.l	D0,D3
	move.l	$48(A6),A0
	move.l	A0,A1
	move.l	A0,A2
	move.l	A0,A3
	move.l	A0,$2A(A5)
	move.l	A0,$3A(A5)
	move.l	A0,$4A(A5)
	move.l	A0,$5A(A5)
	movem.l	D0-D3/A0-A3,$78(A5)
	bsr	lbC001EFA
	bsr	lbC001F20
	bsr	lbC001F46
	bsr	lbC001F6C
	move.l	$3C(A6),A5
	move.w	#$167,D6
lbC001E6C	clr.l	(A5)+
	dbra	D6,lbC001E6C

	movem.l	(SP)+,D0-D7/A0-A6
	rts

lbC001E78	movem.l	D0/A6,-(SP)
	lea	lbL001564(PC),A6
	move.w	D0,$38(A6)
	bsr	lbC001CE2
	movem.l	(SP)+,D0/A6
	rts

lbC001E8E	lea	lbL001564(PC),A6
	lea	lbL0025E6(PC),A5
	clr.b	$36(A6)
	clr.b	$37(A6)
	lea	lbB0021E6(PC),A0
	move.w	#$17F,D0
lbC001EA6	move.b	#$80,(A0)+
	move.b	#$7F,$27F(A0)
	dbra	D0,lbC001EA6

	lea	lbL002366(PC),A0
	move.w	#$FF,D0
	move.b	#$80,D1
lbC001EC0	move.b	D1,(A0)+
	addq.b	#1,D1
	dbra	D0,lbC001EC0

	lea	lbL002712(PC),A0
	moveq	#0,D7
	moveq	#$3F,D0
lbC001ED0	moveq	#0,D6
	move.w	#$FF,D1
lbC001ED6	move.w	D6,D2
	ext.w	D2
	muls	D7,D2
	lsr.w	#6,D2
	eor.b	#$80,D2
	move.b	D2,(A0)+
	addq.w	#1,D6
	dbra	D1,lbC001ED6

	lea	$80(A0),A0
	addq.w	#1,D7
	dbra	D0,lbC001ED0

	bsr	lbC001DC4
	rts

lbC001EFA	movem.l	D0/D1/A0-A5,-(SP)
	lea	lbL0025E6(PC),A5
	lea	$20(A5),A0
	lea	$78(A5),A1
	lea	lbL002682(PC),A2
	lea	0(A5),A3
	lea	$60(A5),A4
	bsr	lbC001F92
	movem.l	(SP)+,D0/D1/A0-A5
	rts

lbC001F20	movem.l	D0/D1/A0-A5,-(SP)
	lea	lbL0025E6(PC),A5
	lea	$30(A5),A0
	lea	$7C(A5),A1
	lea	lbL002686(PC),A2
	lea	4(A5),A3
	lea	$61(A5),A4
	bsr	lbC001F92
	movem.l	(SP)+,D0/D1/A0-A5
	rts

lbC001F46	movem.l	D0/D1/A0-A5,-(SP)
	lea	lbL0025E6(PC),A5
	lea	$40(A5),A0
	lea	$80(A5),A1
	lea	lbL00268A(PC),A2
	lea	8(A5),A3
	lea	$62(A5),A4
	bsr	lbC001F92
	movem.l	(SP)+,D0/D1/A0-A5
	rts

lbC001F6C	movem.l	D0/D1/A0-A5,-(SP)
	lea	lbL0025E6(PC),A5
	lea	$50(A5),A0
	lea	$84(A5),A1
	lea	lbL00268E(PC),A2
	lea	12(A5),A3
	lea	$63(A5),A4
	bsr	lbC001F92
	movem.l	(SP)+,D0/D1/A0-A5
	rts

lbC001F92	tst.b	(A2)
	bne	lbC001F9E

	clr.l	(A3)
	st	(A4)
	rts

lbC001F9E	move.l	(A0),D0
	move.w	4(A0),D1
	cmp.w	#$20,D1
	bge.s	lbC001FB2

	move.w	#$D0,D1
	move.l	$6C(A5),D0
lbC001FB2	and.l	#$3FFF,D1
	add.l	D1,D1
	add.l	D1,D0
	move.l	D0,10(A0)
	move.w	D1,14(A0)
	tst.b	(A4)
	beq.s	lbC001FF0

	sf	(A4)
	move.l	(A0),D1
	move.w	4(A0),D0
	cmp.w	#$20,D0
	bge.s	lbC001FDE

	move.w	#$D0,D0
	move.l	$6C(A5),D1
lbC001FDE	and.l	#$3FFF,D0
	add.w	D0,D0
	add.l	D0,D1
	move.l	D1,$10(A1)
	neg.l	D0
	move.l	D0,(A1)
lbC001FF0	rts

lbC001FF2	moveq	#0,D2
	move.w	6(A0),D0
	beq.s	lbC00202A

	move.w	8(A0),D2
	and.l	#$FF,D2
	cmp.w	#$40,D2
	blt.s	lbC00200C

	moveq	#$3F,D2
lbC00200C	mulu	#$180,D2
	move.l	D3,D1
	divu	D0,D1
	and.l	#$FFFF,D1
	lsl.l	#5,D1
	swap	D1
	move.l	D1,(A2)
	add.l	A3,D2
	sub.l	A1,D2
	subq.w	#2,D2
	move.w	D2,2(A1)
lbC00202A	rts

lbC00202C	lea	lbL0025E6(PC),A5
	move.l	$68(A5),$DFF0D0
	move.w	$72(A5),$DFF0D4
	movem.l	D1-D7/A0-A4/A6,-(SP)
	lea	lbL001564(PC),A6
	tst.b	$12(A6)
	beq	lbC002146

	lea	lbL002712(PC),A3
	move.l	$74(A5),D3
	lea	$20(A5),A0
	lea	lbC00217C(PC),A1
	lea	0(A5),A2
	bsr.s	lbC001FF2
	lea	$30(A5),A0
	lea	lbC002188(PC),A1
	lea	4(A5),A2
	bsr	lbC001FF2
	lea	$40(A5),A0
	lea	lbC002196(PC),A1
	lea	8(A5),A2
	bsr	lbC001FF2
	lea	$50(A5),A0
	lea	lbC0021A4(PC),A1
	lea	12(A5),A2
	bsr	lbC001FF2
	lea	$20(A5),A0
	lea	$78(A5),A1
	lea	lbL002682(PC),A2
	lea	0(A5),A3
	lea	$60(A5),A4
	bsr	lbC001F92
	lea	$30(A5),A0
	lea	$7C(A5),A1
	lea	lbL002686(PC),A2
	lea	4(A5),A3
	lea	$61(A5),A4
	bsr	lbC001F92
	lea	$40(A5),A0
	lea	$80(A5),A1
	lea	lbL00268A(PC),A2
	lea	8(A5),A3
	lea	$62(A5),A4
	bsr	lbC001F92
	lea	$50(A5),A0
	lea	$84(A5),A1
	lea	lbL00268E(PC),A2
	lea	12(A5),A3
	lea	$63(A5),A4
	bsr	lbC001F92
	move.l	$68(A5),A4
	move.l	$64(A5),$68(A5)
	move.l	A4,$64(A5)
	move.l	SP,$98(A5)
	movem.l	lbW00265E(PC),D0-D3/A0-A3
	movem.l	lbL0025E6(PC),D6/D7/A5/A6
	moveq	#0,D4
	moveq	#0,D5
	move.w	lbW002656(PC),D5
	bra.s	lbC002176

lbC00211E	lea	lbL0025E6(PC),A5
	movem.l	D0-D3/A0-A3,$78(A5)
	move.l	$98(A5),SP
	lea	lbL001564(PC),A6
	tst.b	$1F(A6)
	bne.s	lbC002146

	st	$37(A6)
	move.w	#$400,$DFF09C
	bsr	lbC00037E
lbC002146	movem.l	(SP)+,D1-D7/A0-A4/A6
	movem.l	(SP)+,D0/A5
	move.w	#$400,$DFF09C
	rte

lbC002158	move.l	lbL002610(PC),A0
	sub.w	lbW002614(PC),D0
	bra.s	lbC0021BC

lbC002162	move.l	lbL002620(PC),A1
	sub.w	lbW002624(PC),D1
	bra.s	lbC0021C2

lbC00216C	move.l	lbL002630(PC),A2
	sub.w	lbW002634(PC),D2
	bra.s	lbC0021C8

lbC002176	swap	D5
	move.b	0(A0,D0.W),D4
lbC00217C	lea	lbL008592(PC),SP
	move.b	0(SP,D4.W),D4
	move.b	0(A1,D1.W),D5
lbC002188	lea	lbL008592(PC),SP
	move.b	0(SP,D5.W),D5
	add.w	D5,D4
	move.b	0(A2,D2.W),D5
lbC002196	lea	lbL008592(PC),SP
	move.b	0(SP,D5.W),D5
	add.w	D5,D4
	move.b	0(A3,D3.W),D5
lbC0021A4	lea	lbL008592(PC),SP
	move.b	0(SP,D5.W),D5
	add.w	D5,D4
	swap	D5
	move.b	lbB0021E6(PC,D4.W),(A4)+
	moveq	#0,D4
	add.l	D6,D0
	addx.w	D4,D0
	bpl.s	lbC002158

lbC0021BC	add.l	D7,D1
	addx.w	D4,D1
	bpl.s	lbC002162

lbC0021C2	add.l	A5,D2
	addx.w	D4,D2
	bpl.s	lbC00216C

lbC0021C8	add.l	A6,D3
	addx.w	D4,D3
	bpl.s	lbC0021D6

	dbra	D5,lbC002176

	bra	lbC00211E

lbC0021D6	move.l	lbL002640(PC),A3
	sub.w	lbW002644(PC),D3
	dbra	D5,lbC002176

	bra	lbC00211E

lbB0021E6	dcb.b	$3F,0
	dcb.b	$3F,0
	dcb.b	$3F,0
	dcb.b	$3F,0
	dcb.b	$3F,0
	dcb.b	$3F,0
	dcb.b	$6,0
lbL002366	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$22,0
lbL0025E6	dcb.l	$8,0
lbL002606	dcb.l	$2,0
	dc.w	$3F
lbL002610	dc.l	0
lbW002614	dc.w	0
lbL002616	dcb.l	$2,0
	dc.w	$3F
lbL002620	dc.l	0
lbW002624	dc.w	0
lbL002626	dcb.l	$2,0
	dc.w	$3F
lbL002630	dc.l	0
lbW002634	dc.w	0
lbL002636	dcb.l	$2,0
	dc.w	$3F
lbL002640	dc.l	0
lbW002644	dcb.w	$9,0
lbW002656	dcb.w	$4,0
lbW00265E	dcb.w	$12,0
lbL002682	dc.l	0
lbL002686	dc.l	0
lbL00268A	dc.l	0
lbL00268E	dcb.l	$21,0
lbL002712	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
	dcb.l	$3F,0
lbL008592	dcb.l	$3F,0
	dcb.l	$2,0
	dc.w	$3F2


stop

 ifne testi

buffer
lbL008698	ds.l	$200


	section	da,data_c

buf	ds.b	10000


mdat	incbin	music:tfmx/mdat.turrican3_intro
smpl	incbin	music:tfmx/smpl.turrican3_intro
 endc

