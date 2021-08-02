;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000

test=1


 ifne test

	section 	play,code_c

	lea	zaks,a1
zloop
	move.l	(a1)+,a0
	bsr.b	bob
	tst.l	(a1)
	bne.b	zloop
	rts
zaks
	dc.l	muzak1
	dc.l	muzak2
	dc.l	muzak3
	dc.l	muzak4
	dc.l	muzak5
	dc.l	muzak6
	dc.l	muzak7
	dc.l	muzak8
	dc.l	muzak9
	dc.l	0
	
	

bob
	movem.l	d0-d7/a0-a6,-(a7)
	lea	mastervol,a1
	moveq	#0,d0
	jsr	init
	
loop
        cmp.b   #$80,$dff006    
        bne.b   loop
.e      cmp.b   #$81,$dff006    
        bne.b   .e

        move    #$ff0,$dff180
        jsr	doPlay
        clr     $dff180

        btst    #6,$bfe001
        bne.b   loop
		
.x		btst    #6,$bfe001
        beq.b   .x

*********
	jsr	deinit
*********

	movem.l	(a7)+,d0-d7/a0-a6
	rts

mastervol	dc	$40
songcount	dc	0

	section	muzaksszz,data_c

muzak1
 incbin "sys:music/roots/modules/digital mugician/ramon/hoi-level-1.dmu"
muzak2
 incbin "sys:music/roots/modules/digital mugician/rhino/wintercamp-title.dmu"
muzak3
  incbin "sys:music/roots/modules/digital mugician/ramon/guitar fever.dmu"
muzak4
 incbin "sys:music/synth/digimugi/DMU.magic"
muzak5
 incbin "sys:music/synth/digimugi/DMU.ferry_tell"
muzak6
 incbin "sys:music/synth/digimugi/DMU.jetset-2"
muzak7
 incbin "sys:music/roots/modules/digital mugician/yodelking/dreaming.dmu"
muzak8
 incbin "sys:music/roots/modules/digital mugician/ramon/peanut power game.dmu"
muzak9
 incbin "sys:music/roots/modules/digital mugician/ramon/mugician-demo.dmu"

	section	muzakcode,code_c
 endif

MUGSTART

	jmp	init(pc)
	jmp	doPlay(pc)
	jmp	deinit(pc)

* in:
*   a0 = module address
*   a1 = master volume address
init	
	moveq	#0,d0
	lea	muzakAddr(pc),a4
	move.l	a0,(a4)
	lea	masterVolumeAddr(pc),a4
	move.l	a1,(a4)
	bsr.w	doInit
	bsr.w	getStatus
	rts

deinit
	bsr.w	doEnd
	bsr.b	reset
	rts

muzakAddr			dc.l	0
masterVolumeAddr	dc.l	0

****************************************************************************
lbC000000	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVEQ	#0,D0
	BSR.W	lbC0001F8
lbC00000A	BTST	#6,$BFE001
	BNE.B	lbC00000A
	BSR.W	lbC000330
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

lbL000020	
	dc.l	lbC000058-lbC000000
	dc.l	lbC000082-lbC000000
	dc.l	lbC00008A-lbC000000
	dc.l	lbC00009C-lbC000000
	dc.l	lbC0000BA-lbC000000
	dc.l	lbC0000D0-lbC000000
	dc.l	lbC0000E6-lbC000000
	dc.l	lbC000104-lbC000000

	LEA	lbC000000(PC),A0
	LEA	lbL000020(PC),A1
	AND.L	#7,D0
	ASL.W	#2,D0
	ADD.L	0(A1,D0.L),A0
	JSR	(A0)
	RTS

reset
lbC000058	LEA	lbL000E16(PC),A5
	CLR.W	$2E(A5)
	CLR.W	$5E(A5)
	CLR.W	$8E(A5)
	CLR.W	$BE(A5)
	LEA	lbW00011E(PC),A0
	TST.W	2(A0)
	BEQ.W	lbC0001F6
	MOVE.W	(A0),D0
	LEA	lbW000E10(PC),A0
	MOVE.W	D0,(A0)
	RTS

lbC000082	LEA	lbW000E0E(PC),A0
	MOVE.W	(A0),D0
	RTS

getStatus
lbC00008A	LEA	lbL000E08(PC),A0
	MOVE.W	(A0),D1
	MOVE.W	2(A0),D0
	LEA	lbW000E10(PC),A0
	MOVE.W	(A0),D2
	RTS

lbC00009C	LEA	lbL000E16(PC),A5
	MOVE.W	4(A5),D0
	MOVE.W	$34(A5),D1
	MOVE.W	$64(A5),D2
	MOVE.W	$94(A5),D3
	ADDQ.W	#1,D0
	ADDQ.W	#1,D1
	ADDQ.W	#1,D2
	ADDQ.W	#1,D3
	RTS

lbC0000BA	LEA	lbL000E16(PC),A5
	MOVE.W	$10(A5),D0
	MOVE.W	$40(A5),D1
	MOVE.W	$70(A5),D2
	MOVE.W	$A0(A5),D3
	RTS

lbC0000D0	LEA	lbL000E16(PC),A5
	MOVE.W	$24(A5),D0
	MOVE.W	$54(A5),D1
	MOVE.W	$84(A5),D2
	MOVE.W	$B4(A5),D3
	RTS

lbC0000E6	SUB.W	#1,D1
	AND.W	#3,D1
	LEA	lbL000E16(PC),A5
	MULU	#$30,D1
	LEA	0(A5,D1.L),A5
	AND.W	#15,D2
	MOVE.W	D2,$2E(A5)
	RTS

lbC000104	LEA	lbW000E10(PC),A0
	AND.W	#$FF,D2
	MOVE.W	(A0),D0
	MOVE.W	D2,(A0)
	LEA	lbW00011E(PC),A0
	MOVE.W	D0,(A0)
	MOVE.W	#1,2(A0)
	RTS

lbW00011E	dc.w	0
lbW000120	dc.w	0

lbC000122	MOVEQ	#0,D7
	LEA	MUGICIANSOFTE.MSG(PC),A0
	move.l	muzakAddr(pc),a1
	MOVEQ	#$17,D6
lbC00012E	MOVE.B	(A0)+,D2
	CMP.B	(A1)+,D2
	BNE.W	lbC0001DA
	DBRA	D6,lbC00012E
	MOVEQ	#0,D4
	MOVE.W	D0,D4
	MOVE.W	D4,D6
	ASL.W	#4,D6

	move.l	muzakAddr(pc),a5
	lea 	76(a5),a4

	LEA	lbL000ED6(PC),A6
	MOVE.L	A4,(A6)
	ADD.L	D6,(A6)
	LEA	$80(A4),A4
	LEA	$1C(A5),A2
	MOVEQ	#0,D2
	MOVEQ	#7,D5
lbC00015E	MOVE.L	(A2)+,D3
	ASL.L	#3,D3
	CMP.W	D2,D4
	BNE.B	lbC00016C
	MOVE.L	A4,4(A6)
lbC00016C	ADDQ.W	#1,D2
	LEA	0(A4,D3.L),A4
	DBRA	D5,lbC00015E
	MOVE.L	$3C(A5),D3
	ASL.L	#4,D3
	MOVE.L	A4,8(A6)
	LEA	0(A4,D3.L),A4
	MOVE.L	$40(A5),D3
	ASL.L	#7,D3
	MOVE.L	A4,$10(A6)
	LEA	0(A4,D3.L),A4
	MOVE.L	$44(A5),D3
	MOVE.L	A4,$18(A6)
	ASL.L	#5,D3
	LEA	0(A4,D3.L),A4
	MOVEQ	#0,D3
	MOVE.W	$1A(A5),D3
	ASL.L	#8,D3
	MOVE.L	A4,$14(A6)
	LEA	0(A4,D3.L),A4
	MOVE.L	A4,$1C(A6)
	MOVE.L	$48(A5),D3
	LEA	0(A4,D3.L),A4
	TST.W	$18(A5)
	BEQ.B	lbC0001CA
	MOVE.L	A4,12(A6)
	RTS

lbC0001CA	MOVE.L	A4,12(A6)
	MOVE.W	#$FF,D7
lbC0001D2	CLR.B	(A4)+
	DBRA	D7,lbC0001D2
	RTS

lbC0001DA	MOVEQ	#-1,D7
	RTS

MUGICIANSOFTE.MSG	dc.b	' MUGICIAN/SOFTEYES 1990 '

lbC0001F6	RTS

doInit
lbC0001F8	LEA	lbW000E0E(PC),A0
	MOVE.W	D0,(A0)
	BSR.W	lbC000122
	CMP.W	#$FFFF,D7
	BEQ.B	lbC0001F6
	LEA	lbL000E16(PC),A0
	MOVEQ	#$5F,D7
lbC000210	CLR.W	(A0)+
	DBRA	D7,lbC000210
	LEA	lbW000E02(PC),A0
	CLR.L	(A0)+
	CLR.W	(A0)+
	ADDQ.W	#2,A0
	CLR.L	(A0)+
	MOVE.W	#$7C,$DFF0A4
	MOVE.W	#$7C,$DFF0B4
	MOVE.W	#$7C,$DFF0C4
	MOVE.W	#$7C,$DFF0D4
	MOVE.W	#0,$DFF0A8
	MOVE.W	#0,$DFF0B8
	MOVE.W	#0,$DFF0C8
	MOVE.W	#0,$DFF0D8
	MOVE.W	#15,$DFF096
	LEA	lbW000E0E(PC),A0
	MOVE.W	(A0),D0
	MOVEQ	#3,D7
	LEA	lbL000E16(PC),A0
	LEA	(A0),A1
lbC000278	MOVE.W	D0,(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	CLR.W	(A0)+
	LEA	$30(A1),A1
	LEA	(A1),A0
	DBRA	D7,lbC000278
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.L	lbL000ED6(PC),A0
	MOVE.B	3(A0),D1
	LEA	lbW000E12(PC),A2
	MOVE.W	D1,(A2)
	LEA	lbW000E14(PC),A2
	MOVE.W	#$40,(A2)
	MOVE.B	2(A0),D1
	LEA	lbW000E02(PC),A2
	MOVE.W	D1,(A2)
	MOVE.B	D1,D0
	AND.B	#15,D0
	AND.B	#15,D1
	ASL.B	#4,D0
	OR.B	D0,D1
	LEA	lbW000E10(PC),A2
	MOVE.W	D1,(A2)
	LEA	lbL000E08(PC),A2
	CLR.W	(A2)
	LEA	lbW000E04(PC),A2
	MOVE.W	#1,(A2)
	LEA	lbW000E06(PC),A2
	MOVE.W	#1,(A2)
	LEA	lbL000324(PC),A2
	TST.W	(A2)
	BNE.B	lbC000322
	LEA	lbC00035E(PC),A0
	;LEA	lbC000494(PC),A1
	;MOVE.L	$6C,2(A1)
	;MOVE.L	A0,$6C
	MOVE.W	#15,$DFF096
	MOVE.W	#1,(A2)
lbC000322	RTS

lbL000324	dc.l	0
	dc.l	0
	dc.l	0

doEnd
lbC000330	MOVE.W	#15,$DFF096
	LEA	lbL000324(PC),A2
	TST.W	(A2)
	BEQ.B	lbC000322
	CLR.W	(A2)
	;LEA	lbC000494(PC),A1
	;MOVE.L	2(A1),$6C
	LEA	lbL000E16(PC),A0
	MOVEQ	#$5F,D7
lbC000356	CLR.W	(A0)+
	DBRA	D7,lbC000356
	RTS

doPlay
lbC00035E	MOVEM.L	D0-D7/A0-A6,-(SP)
	LEA	lbL000776(PC),A2
	MOVE.L	#$80808080,(A2)
	LEA	lbL000772(PC),A3
	MOVE.L	A2,(A3)
	BSR.W	lbC000D94
	LEA	lbW000E02(PC),A1
	LEA	$DFF0A0,A6
	LEA	lbL000E16(PC),A5
	MOVE.W	#1,10(A1)
	MOVEQ	#0,D6
	BSR.W	lbC00049A
	LEA	$10(A6),A6
	LEA	$30(A5),A5
	MOVEQ	#2,D6
	MOVE.W	D6,10(A1)
	BSR.W	lbC00049A
	LEA	$10(A6),A6
	LEA	$30(A5),A5
	MOVEQ	#4,D6
	MOVE.W	D6,10(A1)
	BSR.W	lbC00049A
	LEA	$10(A6),A6
	LEA	$30(A5),A5
	MOVE.W	#8,10(A1)
	MOVEQ	#6,D6
	BSR.W	lbC00049A
	LEA	$DFF0A0,A6
	LEA	lbL000E16(PC),A5
	BSR.W	lbC00077E
	LEA	$10(A6),A6
	LEA	$30(A5),A5
	BSR.W	lbC00077E
	LEA	$10(A6),A6
	LEA	$30(A5),A5
	BSR.W	lbC00077E
	LEA	$10(A6),A6
	LEA	$30(A5),A5
	BSR.W	lbC00077E
	CLR.L	2(A1)
	SUB.W	#1,(A1)
	BNE.B	lbC000488
	MOVE.W	14(A1),(A1)
	AND.W	#15,(A1)
	MOVE.W	14(A1),D5
	AND.W	#15,D5
	MOVE.W	14(A1),D0
	AND.W	#$F0,D0
	ASR.W	#4,D0
	ASL.W	#4,D5
	OR.W	D0,D5
	MOVE.W	D5,14(A1)
	MOVE.W	#1,4(A1)
	ADD.W	#1,8(A1)
	MOVE.W	$12(A1),D5
	CMP.W	#$40,8(A1)
	BEQ.B	lbC00044A
	CMP.W	8(A1),D5
	BNE.B	lbC000488
lbC00044A	CLR.W	8(A1)
	MOVE.W	#1,2(A1)
	ADD.W	#1,6(A1)
	MOVE.W	$10(A1),D5
	CMP.W	6(A1),D5
	BNE.B	lbC000488
	MOVE.L	lbL000ED6(PC),A0
	MOVEQ	#0,D0
	TST.B	(A0)
	BEQ.B	lbC000480
	MOVE.B	1(A0,D0.L),7(A1)
	CLR.B	6(A1)
	BRA.B	lbC000488

lbC000480	BSR.W	lbC000330
	BRA.B	lbC000490

lbC000488	MOVE.W	#$800F,$DFF096
lbC000490	MOVEM.L	(SP)+,D0-D7/A0-A6
lbC000494	
		;JMP	0
		rts

lbC00049A	MOVEQ	#0,D0
	TST.W	2(A1)
	BEQ.B	lbC0004BC
	MOVE.L	lbL000EDA(PC),A0
	MOVE.W	6(A1),D0
	ASL.W	#3,D0
	ADD.W	D0,D6
	MOVE.B	0(A0,D6.L),3(A5)
	MOVE.B	1(A0,D6.L),9(A5)
lbC0004BC	TST.W	4(A1)
	BEQ.W	lbC0006B8
	MOVE.L	lbL000EEA(PC),A0
	MOVE.W	2(A5),D0
	ASL.W	#8,D0
	LEA	0(A0,D0.L),A0
	MOVE.W	8(A1),D0
	ASL.W	#2,D0
	TST.B	0(A0,D0.L)
	BEQ.W	lbC0006B8
	LEA	0(A0,D0.L),A0
	CMP.B	#$4A,2(A0)
	BEQ.B	lbC000506
	MOVE.B	(A0),7(A5)
	TST.B	1(A0)
	BEQ.B	lbC000506
	MOVE.B	1(A0),5(A5)
	SUB.B	#1,5(A5)
lbC000506	MOVE.L	lbL000EDE(PC),A4
	MOVE.W	4(A5),D0
	ASL.W	#4,D0
	LEA	0(A4,D0.L),A4
	MOVE.B	8(A4),$13(A5)
	AND.B	#$3F,5(A5)
	CLR.B	15(A5)
	CMP.B	#$40,2(A0)
	BLO.B	lbC00053E
	MOVE.B	2(A0),15(A5)
	SUB.B	#$3E,15(A5)
	BRA.B	lbC000544

lbC00053E	MOVE.B	#1,15(A5)
lbC000544	MOVE.B	3(A0),13(A5)
	CMP.B	#12,15(A5)
	BEQ.B	lbC000596
	MOVE.B	2(A0),11(A5)
	CMP.B	#1,15(A5)
	BNE.B	lbC0005C8
	LEA	lbW000F04(PC),A2
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.B	11(A5),D1
	MOVE.W	8(A5),D0
	EXT.W	D0
	ADD.W	D0,D1
	MOVE.W	$12(A5),D0
	ADD.W	$2E(A5),D0
	AND.W	#15,D0
	ASL.W	#7,D0
	LEA	0(A2,D0.L),A2
	ADD.W	D1,D1
	MOVE.W	0(A2,D1.L),$2A(A5)
	BRA.B	lbC0005C8

lbC000596	MOVE.B	(A0),11(A5)
	LEA	lbW000F04(PC),A2
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.B	11(A5),D1
	MOVE.W	8(A5),D0
	EXT.W	D0
	ADD.W	D0,D1
	MOVE.W	$12(A5),D0
	ADD.W	$2E(A5),D0
	AND.W	#15,D0
	ASL.W	#7,D0
	LEA	0(A2,D0.L),A2
	ADD.W	D1,D1
	MOVE.W	0(A2,D1.L),$2A(A5)
lbC0005C8	CMP.B	#11,15(A5)
	BNE.B	lbC0005DE
	MOVE.B	13(A5),4(A4)
	AND.B	#7,4(A4)
lbC0005DE	MOVEQ	#0,D1
	MOVE.L	lbL000EE6(PC),A3
	MOVE.B	(A4),D1
	CMP.B	#12,15(A5)
	BEQ.B	lbC0005F8
	CMP.B	#$20,D1
	BHS.W	lbC000D5A
lbC0005F8	ASL.W	#7,D1
	LEA	0(A3,D1.L),A3
	MOVE.L	A3,(A6)
	MOVEQ	#0,D1
	MOVE.B	1(A4),D1
	MOVE.W	D1,4(A6)
	CMP.B	#12,15(A5)
	BEQ.B	lbC000626
	CMP.B	#10,15(A5)
	BEQ.B	lbC000626
	MOVE.W	10(A1),$DFF096
lbC000626	TST.B	11(A4)
	BEQ.B	lbC00067E
	CMP.B	#2,15(A5)
	BEQ.B	lbC00067E
	CMP.B	#4,15(A5)
	BEQ.B	lbC00067E
	CMP.B	#12,15(A5)
	BEQ.B	lbC00067E
	MOVEQ	#0,D0
	MOVE.B	12(A4),D0
	ASL.W	#7,D0
	MOVE.L	lbL000EE6(PC),A3
	LEA	0(A3,D0.L),A3
	MOVEQ	#0,D0
	MOVE.B	(A4),D0
	ASL.W	#7,D0
	MOVE.L	lbL000EE6(PC),A2
	LEA	0(A2,D0.L),A2
	CLR.B	6(A4)
	MOVEQ	#0,D7
	MOVEQ	#$1F,D7
lbC000672	MOVE.L	(A3)+,(A2)+
	DBRA	D7,lbC000672
	MOVE.B	14(A4),$29(A5)
lbC00067E	CMP.B	#3,15(A5)
	BEQ.B	lbC0006A6
	CMP.B	#4,15(A5)
	BEQ.B	lbC0006A6
	CMP.B	#12,15(A5)
	BEQ.B	lbC0006A6
	MOVE.W	#1,$18(A5)
	CLR.W	$16(A5)
lbC0006A6	CLR.W	$2C(A5)
	MOVE.B	7(A4),$1D(A5)
	CLR.W	$1E(A5)
	CLR.W	$1A(A5)
lbC0006B8	CMP.B	#5,15(A5)
	BEQ.B	lbC000700
	CMP.B	#6,15(A5)
	BEQ.B	lbC00071A
	CMP.B	#7,15(A5)
	BEQ.B	lbC0006EC
	CMP.B	#8,15(A5)
	BEQ.B	lbC0006F6
	CMP.B	#13,15(A5)
	BEQ.B	lbC000744
	RTS

lbC0006EC	BCLR	#1,$BFE001
	RTS

lbC0006F6	BSET	#1,$BFE001
	RTS

lbC000700	MOVEQ	#0,D0
	MOVE.B	13(A5),D0
	TST.W	D0
	BEQ.W	lbC0009BA
	CMP.W	#$40,D0
	BHI.W	lbC0009BA
	MOVE.W	D0,$12(A1)
	RTS

lbC00071A	MOVEQ	#0,D0
	MOVE.B	13(A5),D0
	AND.W	#15,D0
	MOVE.B	D0,D1
	ASL.B	#4,D0
	OR.B	D1,D0
	TST.B	D1
	BEQ.W	lbC0009BA
	CMP.B	#15,D1
	BHI.W	lbC0009BA
	MOVE.W	D0,14(A1)
	LEA	lbW000120(PC),A2
	CLR.W	(A2)
	RTS

lbC000744	CLR.B	15(A5)
	MOVEQ	#0,D0
	MOVE.B	13(A5),D0
	MOVE.B	D0,D1
	AND.B	#15,D1
	TST.B	D1
	BEQ.W	lbC0009BA
	MOVE.B	D0,D1
	AND.B	#$F0,D1
	TST.B	D1
	BEQ.W	lbC0009BA
	MOVE.W	D0,14(A1)
	LEA	lbW000120(PC),A2
	CLR.W	(A2)
	RTS

lbL000772	dc.l	0
lbL000776	dc.l	0
	dc.l	0

lbC00077E	CMP.B	#9,15(A5)
	BNE.B	lbC000790
	BCHG	#1,$BFE001
lbC000790	MOVEQ	#0,D0
	MOVE.L	lbL000EDE(PC),A4
	MOVE.W	4(A5),D0
	ASL.W	#4,D0
	LEA	0(A4,D0.L),A4
	MOVEM.L	D0-D7/A0-A6,-(SP)
	TST.B	11(A4)
	BEQ.B	lbC000828
	CMP.B	#$20,(A4)
	BHS.B	lbC000828
	MOVE.L	lbL000772(PC),A2
	LEA	lbL000776(PC),A3
	MOVEQ	#0,D0
	MOVE.B	5(A5),D0
	ADDQ.W	#1,D0
	CMP.B	(A3)+,D0
	BEQ.B	lbC000828
	CMP.B	(A3)+,D0
	BEQ.B	lbC000828
	CMP.B	(A3)+,D0
	BEQ.B	lbC000828
	CMP.B	(A3)+,D0
	BEQ.B	lbC000828
	MOVE.B	D0,(A2)+
	LEA	lbL000772(PC),A2
	ADD.L	#1,(A2)
	TST.B	$29(A5)
	BNE.B	lbC000822
	MOVE.B	14(A4),$29(A5)
	LEA	lbL0009BC(PC),A2
	MOVEQ	#0,D0
	MOVE.B	11(A4),D0
	ASL.W	#2,D0
	MOVE.L	0(A2,D0.L),D0
	LEA	lbC000000(PC),A2
	LEA	0(A2,D0.L),A2
	MOVE.L	lbL000EE6(PC),A3
	MOVEQ	#0,D3
	MOVE.B	(A4),D3
	ASL.W	#7,D3
	LEA	0(A3,D3.L),A3
	JSR	(A2)
	BRA.B	lbC000828

lbC000822	SUB.B	#1,$29(A5)
lbC000828	MOVEM.L	(SP)+,D0-D7/A0-A6
	TST.W	$18(A5)
	BEQ.B	lbC000898
	SUB.W	#1,$18(A5)
	TST.W	$18(A5)
	BNE.B	lbC000898
	MOVE.B	3(A4),$19(A5)
	ADD.W	#1,$16(A5)
	AND.W	#$7F,$16(A5)
	TST.W	$16(A5)
	BNE.B	lbC00086E
	BTST	#1,15(A4)
	BNE.B	lbC00086E
	CLR.W	$18(A5)
	BRA.B	lbC000898

lbC00086E	MOVE.W	$16(A5),D0
	MOVEQ	#0,D1
	MOVE.L	lbL000EE6(PC),A3
	MOVE.B	2(A4),D1
	ASL.W	#7,D1
	ADD.W	D0,D1
	LEA	0(A3,D1.L),A3
	MOVEQ	#0,D1
	MOVE.B	(A3),D1
	ADD.B	#$81,D1
	NEG.B	D1
	ASR.W	#2,D1
	MOVE.W	D1,$24(A5)

	move.l	masterVolumeAddr(pc),a2
	mulu	(a2),d1
	lsr	#6,d1
	MOVE.W	D1,8(A6)

lbC000898	LEA	lbW000F04(PC),A2
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.W	6(A5),D1
	TST.B	4(A4)
	BEQ.B	lbC0008CE
	MOVE.L	lbL000EE2(PC),A3
	MOVE.B	4(A4),D0
	ASL.W	#5,D0
	LEA	0(A3,D0.L),A3
	MOVE.W	$1A(A5),D0
	ADD.B	0(A3,D0.L),D1
	ADD.W	#1,$1A(A5)
	AND.W	#$1F,$1A(A5)
lbC0008CE	MOVE.W	8(A5),D0
	EXT.W	D0
	ADD.W	D0,D1
	MOVE.W	$12(A5),D0
	ADD.W	$2E(A5),D0
	AND.W	#15,D0
	ASL.W	#7,D0
	LEA	0(A2,D0.L),A2
	ADD.W	D1,D1
	MOVE.W	0(A2,D1.L),$10(A5)
	MOVE.W	$10(A5),D3
	CMP.B	#12,15(A5)
	BEQ.B	lbC000908
	CMP.B	#1,15(A5)
	BNE.B	lbC000960
lbC000908	MOVE.W	12(A5),D0
	EXT.W	D0
	NEG.W	D0
	ADD.W	D0,$2C(A5)
	MOVE.W	$10(A5),D1
	ADD.W	$2C(A5),D1
	MOVE.W	D1,$10(A5)
	TST.W	12(A5)
	BEQ.B	lbC000960
	BTST	#15,D0
	BEQ.B	lbC00094A
	CMP.W	$2A(A5),D1
	BHI.B	lbC000960
	MOVE.W	$2A(A5),D1
	SUB.W	D3,D1
	MOVE.W	D1,$2C(A5)
	CLR.W	12(A5)
	BRA.B	lbC000960

lbC00094A	CMP.W	$2A(A5),D1
	BLO.B	lbC000960
	MOVE.W	$2A(A5),D1
	SUB.W	D3,D1
	MOVE.W	D1,$2C(A5)
	CLR.W	12(A5)
lbC000960	TST.B	5(A4)
	BEQ.B	lbC0009B4
	TST.B	$1D(A5)
	BEQ.B	lbC00097A
	SUB.B	#1,$1D(A5)
	BRA.B	lbC0009B4

lbC00097A	MOVE.L	lbL000EE6(PC),A3
	MOVEQ	#0,D1
	MOVE.B	5(A4),D1
	ASL.W	#7,D1
	LEA	0(A3,D1.L),A3
	MOVE.W	$1E(A5),D1
	ADD.W	#1,$1E(A5)
	AND.W	#$7F,$1E(A5)
	TST.W	$1E(A5)
	BNE.B	lbC0009A8
	MOVE.B	9(A4),$1F(A5)
lbC0009A8	MOVE.B	0(A3,D1.L),D1
	EXT.W	D1
	NEG.W	D1
	ADD.W	D1,$10(A5)
lbC0009B4	MOVE.W	$10(A5),6(A6)
lbC0009BA	RTS

lbL0009BC	dc.l	lbC0009BA-lbC000000
	dc.l	lbC000CFC-lbC000000
	dc.l	lbC000BD6-lbC000000
	dc.l	lbC000CB6-lbC000000
	dc.l	lbC000CC6-lbC000000
	dc.l	lbC000B7E-lbC000000
	dc.l	lbC000B68-lbC000000
	dc.l	lbC000C5C-lbC000000
	dc.l	lbC000B98-lbC000000
	dc.l	lbC000C30-lbC000000
	dc.l	lbC000D14-lbC000000
	dc.l	lbC000A3C-lbC000000
	dc.l	lbC000AD2-lbC000000
	dc.l	lbC000D3A-lbC000000
	dc.l	lbC000C80-lbC000000
	dc.l	lbC000CDA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000
	dc.l	lbC0009BA-lbC000000

lbC000A3C	MOVEQ	#0,D3
	MOVE.L	lbL000EE6(PC),A0
	MOVE.B	12(A4),D3
	ASL.W	#7,D3
	LEA	0(A0,D3.L),A0
	MOVEQ	#0,D3
	MOVE.L	lbL000EE6(PC),A2
	MOVE.B	13(A4),D3
	ASL.W	#7,D3
	LEA	0(A2,D3.L),A2
	ADD.B	#1,6(A4)
	AND.B	#$7F,6(A4)
	MOVEQ	#0,D0
	MOVE.B	6(A4),D0
	CMP.B	#$40,D0
	BHS.B	lbC000AA2
	MOVE.L	D0,D3
	EOR.B	#$FF,D3
	AND.W	#$3F,D3
	MOVEQ	#0,D7
	MOVE.B	1(A4),D7
	ADD.B	D7,D7
	SUBQ.W	#1,D7
lbC000A8A	MOVE.B	(A0)+,D1
	MOVE.B	(A2)+,D2
	EXT.W	D1
	EXT.W	D2
	MULU	D0,D1
	MULU	D3,D2
	ADD.W	D1,D2
	ASR.W	#6,D2
	MOVE.B	D2,(A3)+
	DBRA	D7,lbC000A8A
	RTS

lbC000AA2	MOVEQ	#0,D7
	MOVE.B	1(A4),D7
	ADD.B	D7,D7
	SUBQ.W	#1,D7
	MOVEQ	#$7F,D3
	SUB.L	D0,D3
	MOVE.L	D3,D0
	EOR.B	#$FF,D3
	AND.W	#$3F,D3
lbC000ABA	MOVE.B	(A0)+,D1
	MOVE.B	(A2)+,D2
	EXT.W	D1
	EXT.W	D2
	MULU	D0,D1
	MULU	D3,D2
	ADD.W	D1,D2
	ASR.W	#6,D2
	MOVE.B	D2,(A3)+
	DBRA	D7,lbC000ABA
	RTS

lbC000AD2	MOVEQ	#0,D3
	MOVE.L	lbL000EE6(PC),A0
	MOVE.B	12(A4),D3
	ASL.W	#7,D3
	LEA	0(A0,D3.L),A0
	MOVEQ	#0,D3
	MOVE.L	lbL000EE6(PC),A2
	MOVE.B	13(A4),D3
	ASL.W	#7,D3
	LEA	0(A2,D3.L),A2
	ADD.B	#1,6(A4)
	AND.B	#$1F,6(A4)
	MOVEQ	#0,D0
	MOVE.B	6(A4),D0
	CMP.B	#$10,D0
	BHS.B	lbC000B38
	MOVE.L	D0,D3
	EOR.B	#$FF,D3
	AND.W	#15,D3
	MOVEQ	#0,D7
	MOVE.B	1(A4),D7
	ADD.B	D7,D7
	SUBQ.W	#1,D7
lbC000B20	MOVE.B	(A0)+,D1
	MOVE.B	(A2)+,D2
	EXT.W	D1
	EXT.W	D2
	MULU	D0,D1
	MULU	D3,D2
	ADD.W	D1,D2
	ASR.W	#4,D2
	MOVE.B	D2,(A3)+
	DBRA	D7,lbC000B20
	RTS

lbC000B38	MOVEQ	#0,D7
	MOVE.B	1(A4),D7
	ADD.B	D7,D7
	SUBQ.W	#1,D7
	MOVEQ	#$1F,D3
	SUB.L	D0,D3
	MOVE.L	D3,D0
	EOR.B	#$FF,D3
	AND.W	#15,D3
lbC000B50	MOVE.B	(A0)+,D1
	MOVE.B	(A2)+,D2
	EXT.W	D1
	EXT.W	D2
	MULU	D0,D1
	MULU	D3,D2
	ADD.W	D1,D2
	ASR.W	#4,D2
	MOVE.B	D2,(A3)+
	DBRA	D7,lbC000B50
	RTS

lbC000B68	LEA	(A3),A2
	LEA	$80(A3),A3
	LEA	$40(A2),A2
	MOVEQ	#$3F,D7
lbC000B74	MOVE.B	-(A2),-(A3)
	MOVE.B	(A2),-(A3)
	DBRA	D7,lbC000B74
	RTS

lbC000B7E	LEA	(A3),A2
	LEA	(A2),A0
	MOVEQ	#$3F,D7
lbC000B84	MOVE.B	(A2)+,(A3)+
	ADDQ.W	#1,A2
	DBRA	D7,lbC000B84
	LEA	(A0),A2
	MOVEQ	#$3F,D7
lbC000B90	MOVE.B	(A2)+,(A3)+
	DBRA	D7,lbC000B90
	RTS

lbC000B98	ADD.B	#1,6(A4)
	AND.B	#$7F,6(A4)
	MOVEQ	#0,D1
	MOVE.B	6(A4),D1
	MOVEQ	#0,D3
	MOVE.L	lbL000EE6(PC),A0
	MOVE.B	13(A4),D3
	ASL.W	#7,D3
	LEA	0(A0,D3.L),A0
	MOVEQ	#0,D0
	MOVE.B	1(A4),D0
	ADD.B	D0,D0
	SUBQ.W	#1,D0
	MOVE.B	0(A0,D1.L),D2
	MOVE.B	#3,D1
lbC000BCC	ADD.B	D1,(A3)+
	ADD.B	D2,D1
	DBRA	D0,lbC000BCC
	RTS

lbC000BD6	MOVEQ	#0,D3
	MOVE.L	lbL000EE6(PC),A0
	MOVE.B	12(A4),D3
	ASL.W	#7,D3
	LEA	0(A0,D3.L),A0
	MOVEQ	#0,D3
	MOVE.L	lbL000EE6(PC),A2
	MOVE.B	13(A4),D3
	ASL.W	#7,D3
	LEA	0(A2,D3.L),A2
	MOVEQ	#0,D2
	MOVE.B	6(A4),D2
	ADD.B	#1,6(A4)
	AND.B	#$7F,6(A4)
	MOVEQ	#0,D7
	MOVE.B	1(A4),D7
	ADD.B	D7,D7
	SUBQ.W	#1,D7
lbC000C12	MOVE.B	(A0)+,D0
	MOVE.B	0(A2,D2.L),D1
	EXT.W	D0
	EXT.W	D1
	ADD.W	D0,D1
	ASR.W	#1,D1
	MOVE.B	D1,(A3)+
	ADD.B	#1,D2
	AND.B	#$7F,D2
	DBRA	D7,lbC000C12
	RTS

lbC000C30	MOVEQ	#0,D3
	MOVE.L	lbL000EE6(PC),A0
	MOVE.B	13(A4),D3
	ASL.W	#7,D3
	LEA	0(A0,D3.L),A0
	MOVEQ	#0,D7
	MOVE.B	1(A4),D7
	ADD.B	D7,D7
	SUBQ.W	#1,D7
lbC000C4A	MOVE.B	(A0)+,D0
	MOVE.B	(A3),D1
	EXT.W	D0
	EXT.W	D1
	ADD.W	D0,D1
	MOVE.B	D1,(A3)+
	DBRA	D7,lbC000C4A
	RTS

lbC000C5C	MOVEQ	#0,D0
	MOVE.B	6(A4),D0
	NEG.B	0(A3,D0.L)
	ADD.B	#1,6(A4)
	MOVE.B	1(A4),D0
	ADD.B	D0,D0
	CMP.B	6(A4),D0
	BHI.W	lbC0009BA
	CLR.B	6(A4)
	RTS

lbC000C80	MOVEQ	#0,D0
	MOVE.B	6(A4),D0
	NEG.B	0(A3,D0.L)
	MOVE.B	1(A4),D1
	ADD.B	13(A4),D0
	ADD.B	D1,D1
	SUBQ.W	#1,D1
	AND.B	D1,D0
	NEG.B	0(A3,D0.L)
	ADD.B	#1,6(A4)
	MOVE.B	1(A4),D0
	ADD.B	D0,D0
	CMP.B	6(A4),D0
	BHI.W	lbC0009BA
	CLR.B	6(A4)
	RTS

lbC000CB6	MOVEQ	#$7E,D7
	MOVE.B	(A3),D0
lbC000CBA	MOVE.B	1(A3),(A3)+
	DBRA	D7,lbC000CBA
	MOVE.B	D0,(A3)+
	RTS

lbC000CC6	MOVEQ	#$7E,D7
	LEA	$80(A3),A3
	MOVE.B	-(A3),D0
lbC000CCE	MOVE.B	-(A3),1(A3)
	DBRA	D7,lbC000CCE
	MOVE.B	D0,(A3)
	RTS

lbC000CDA	LEA	(A3),A2
	BSR.B	lbC000CFC
	LEA	(A2),A3
	ADD.B	#1,6(A4)
	MOVE.B	6(A4),D0
	CMP.B	13(A4),D0
	BNE.W	lbC0009BA
	CLR.B	6(A4)
	BRA.W	lbC000B7E

lbC000CFC	MOVEQ	#$7E,D7
lbC000CFE	MOVE.B	(A3),D0
	EXT.W	D0
	MOVE.B	1(A3),D1
	EXT.W	D1
	ADD.W	D0,D1
	ASR.W	#1,D1
	MOVE.B	D1,(A3)+
	DBRA	D7,lbC000CFE
	RTS

lbC000D14	LEA	$7E(A3),A2
	MOVEQ	#$7D,D7
	CLR.W	D2
lbC000D1C	MOVE.B	(A3)+,D0
	EXT.W	D0
	MOVE.W	D0,D1
	ADD.W	D0,D0
	ADD.W	D1,D0
	MOVE.B	1(A3),D1
	EXT.W	D1
	ADD.W	D0,D1
	ASR.W	#2,D1
	MOVE.B	D1,(A3)
	ADDQ.W	#1,D2
	DBRA	D7,lbC000D1C
	RTS

lbC000D3A	LEA	$7E(A3),A2
	MOVEQ	#$7D,D7
	CLR.W	D2
lbC000D42	MOVE.B	(A3)+,D0
	EXT.W	D0
	MOVE.B	1(A3),D1
	EXT.W	D1
	ADD.W	D0,D1
	ASR.W	#1,D1
	MOVE.B	D1,(A3)
	ADDQ.W	#1,D2
	DBRA	D7,lbC000D42
	RTS

lbC000D5A	SUB.W	#$20,D1
	ASL.W	#5,D1
	MOVE.L	lbL000EEE(PC),A3
	LEA	0(A3,D1.L),A3
	MOVE.L	A3,$20(A5)
	MOVE.W	#1,$14(A5)
	MOVE.L	lbL000EF2(PC),A2
	LEA	(A2),A0
	ADD.L	(A3),A0
	MOVE.L	A0,(A6)
	MOVE.L	4(A3),D1
	SUB.L	(A3),D1
	ASR.L	#1,D1
	MOVE.W	D1,4(A6)
	MOVE.W	10(A1),$DFF096
	BRA.W	lbC00067E

lbC000D94	MOVE.L	lbL000EF2(PC),A2
	LEA	lbL000DFA(PC),A4
	LEA	lbL000E16(PC),A5
	LEA	$DFF0A0,A6
	MOVEQ	#3,D5
lbC000DA8	TST.W	$14(A5)
	BEQ.B	lbC000DD6
	CLR.W	$14(A5)
	MOVE.L	$20(A5),A3
	TST.L	8(A3)
	BEQ.B	lbC000DE4
	LEA	(A2),A1
	ADD.L	8(A3),A1
	MOVE.L	A1,(A6)
	MOVE.L	4(A3),D1
	SUB.L	8(A3),D1
	ASR.L	#1,D1
	MOVE.W	D1,4(A6)
lbC000DD6	LEA	$30(A5),A5
	LEA	$10(A6),A6
	DBRA	D5,lbC000DA8
	RTS

lbC000DE4	MOVE.L	A4,(A6)
	MOVE.W	#4,4(A6)
	LEA	$30(A5),A5
	LEA	$10(A6),A6
	DBRA	D5,lbC000DA8
	RTS

lbL000DFA	dc.l	0
	dc.l	0
lbW000E02	dc.w	0
lbW000E04	dc.w	0
lbW000E06	dc.w	0
lbL000E08	dc.l	0
	dc.w	0
lbW000E0E	dc.w	0
lbW000E10	dc.w	5
lbW000E12	dc.w	1
lbW000E14	dc.w	$40
lbL000E16	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
lbL000ED6	dc.l	0
lbL000EDA	dc.l	0
lbL000EDE	dc.l	0
lbL000EE2	dc.l	0
lbL000EE6	dc.l	0
lbL000EEA	dc.l	0
lbL000EEE	dc.l	0
lbL000EF2	dc.l	0
	dc.w	$12D9
	dc.w	$11CA
	dc.w	$10CB
	dc.w	$FD9
	dc.w	$EF6
	dc.w	$E1F
	dc.w	$D54
lbW000F04	dc.w	$C94
	dc.w	$BE0
	dc.w	$B35
	dc.w	$A94
	dc.w	$9FC
	dc.w	$96C
	dc.w	$8E5
	dc.w	$865
	dc.w	$7ED
	dc.w	$77B
	dc.w	$70F
	dc.w	$6AA
	dc.w	$64A
	dc.w	$5F0
	dc.w	$59A
	dc.w	$54A
	dc.w	$4FE
	dc.w	$4B6
	dc.w	$473
	dc.w	$433
	dc.w	$3F6
	dc.w	$3BD
	dc.w	$388
	dc.w	$355
	dc.w	$325
	dc.w	$2F8
	dc.w	$2CD
	dc.w	$2A5
	dc.w	$27F
	dc.w	$25B
	dc.w	$239
	dc.w	$219
	dc.w	$1FB
	dc.w	$1DF
	dc.w	$1C4
	dc.w	$1AA
	dc.w	$193
	dc.w	$17C
	dc.w	$167
	dc.w	$152
	dc.w	$13F
	dc.w	$12E
	dc.w	$11D
	dc.w	$10D
	dc.w	$FE
	dc.w	$EF
	dc.w	$E2
	dc.w	$D5
	dc.w	$C9
	dc.w	$BE
	dc.w	$B3
	dc.w	$A9
	dc.w	$A0
	dc.w	$97
	dc.w	$8E
	dc.w	$86
	dc.w	$7F
	dc.w	$12EA
	dc.w	$11DB
	dc.w	$10DA
	dc.w	$FE8
	dc.w	$F03
	dc.w	$E2C
	dc.w	$D60
	dc.w	$CA0
	dc.w	$BEB
	dc.w	$B3F
	dc.w	$A9E
	dc.w	$A05
	dc.w	$975
	dc.w	$8ED
	dc.w	$86D
	dc.w	$7F4
	dc.w	$782
	dc.w	$716
	dc.w	$6B0
	dc.w	$650
	dc.w	$5F5
	dc.w	$5A0
	dc.w	$54F
	dc.w	$503
	dc.w	$4BB
	dc.w	$477
	dc.w	$437
	dc.w	$3FA
	dc.w	$3C1
	dc.w	$38B
	dc.w	$358
	dc.w	$328
	dc.w	$2FB
	dc.w	$2D0
	dc.w	$2A7
	dc.w	$281
	dc.w	$25D
	dc.w	$23B
	dc.w	$21B
	dc.w	$1FD
	dc.w	$1E0
	dc.w	$1C5
	dc.w	$1AC
	dc.w	$194
	dc.w	$17D
	dc.w	$168
	dc.w	$154
	dc.w	$141
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
	dc.w	$12FC
	dc.w	$11EB
	dc.w	$10EA
	dc.w	$FF7
	dc.w	$F11
	dc.w	$E39
	dc.w	$D6D
	dc.w	$CAC
	dc.w	$BF6
	dc.w	$B4A
	dc.w	$AA8
	dc.w	$A0E
	dc.w	$97E
	dc.w	$8F6
	dc.w	$875
	dc.w	$7FB
	dc.w	$789
	dc.w	$71C
	dc.w	$6B6
	dc.w	$656
	dc.w	$5FB
	dc.w	$5A5
	dc.w	$554
	dc.w	$507
	dc.w	$4BF
	dc.w	$47B
	dc.w	$43A
	dc.w	$3FE
	dc.w	$3C4
	dc.w	$38E
	dc.w	$35B
	dc.w	$32B
	dc.w	$2FD
	dc.w	$2D2
	dc.w	$2AA
	dc.w	$284
	dc.w	$25F
	dc.w	$23D
	dc.w	$21D
	dc.w	$1FF
	dc.w	$1E2
	dc.w	$1C7
	dc.w	$1AE
	dc.w	$195
	dc.w	$17F
	dc.w	$169
	dc.w	$155
	dc.w	$142
	dc.w	$130
	dc.w	$11F
	dc.w	$10F
	dc.w	$FF
	dc.w	$F1
	dc.w	$E4
	dc.w	$D7
	dc.w	$CB
	dc.w	$BF
	dc.w	$B5
	dc.w	$AA
	dc.w	$A1
	dc.w	$98
	dc.w	$8F
	dc.w	$87
	dc.w	$80
	dc.w	$130E
	dc.w	$11FC
	dc.w	$10F9
	dc.w	$1006
	dc.w	$F1F
	dc.w	$E46
	dc.w	$D79
	dc.w	$CB7
	dc.w	$C01
	dc.w	$B54
	dc.w	$AB1
	dc.w	$A18
	dc.w	$987
	dc.w	$8FE
	dc.w	$87D
	dc.w	$803
	dc.w	$790
	dc.w	$723
	dc.w	$6BC
	dc.w	$65C
	dc.w	$600
	dc.w	$5AA
	dc.w	$559
	dc.w	$50C
	dc.w	$4C3
	dc.w	$47F
	dc.w	$43E
	dc.w	$401
	dc.w	$3C8
	dc.w	$392
	dc.w	$35E
	dc.w	$32E
	dc.w	$300
	dc.w	$2D5
	dc.w	$2AC
	dc.w	$286
	dc.w	$262
	dc.w	$23F
	dc.w	$21F
	dc.w	$201
	dc.w	$1E4
	dc.w	$1C9
	dc.w	$1AF
	dc.w	$197
	dc.w	$180
	dc.w	$16B
	dc.w	$156
	dc.w	$143
	dc.w	$131
	dc.w	$120
	dc.w	$110
	dc.w	$100
	dc.w	$F2
	dc.w	$E4
	dc.w	$D8
	dc.w	$CB
	dc.w	$C0
	dc.w	$B5
	dc.w	$AB
	dc.w	$A1
	dc.w	$98
	dc.w	$90
	dc.w	$88
	dc.w	$80
	dc.w	$131F
	dc.w	$120C
	dc.w	$1109
	dc.w	$1014
	dc.w	$F2D
	dc.w	$E53
	dc.w	$D85
	dc.w	$CC3
	dc.w	$C0C
	dc.w	$B5F
	dc.w	$ABB
	dc.w	$A21
	dc.w	$990
	dc.w	$906
	dc.w	$885
	dc.w	$80A
	dc.w	$797
	dc.w	$72A
	dc.w	$6C3
	dc.w	$662
	dc.w	$606
	dc.w	$5AF
	dc.w	$55E
	dc.w	$511
	dc.w	$4C8
	dc.w	$483
	dc.w	$442
	dc.w	$405
	dc.w	$3CB
	dc.w	$395
	dc.w	$361
	dc.w	$331
	dc.w	$303
	dc.w	$2D8
	dc.w	$2AF
	dc.w	$288
	dc.w	$264
	dc.w	$242
	dc.w	$221
	dc.w	$203
	dc.w	$1E6
	dc.w	$1CA
	dc.w	$1B1
	dc.w	$198
	dc.w	$181
	dc.w	$16C
	dc.w	$157
	dc.w	$144
	dc.w	$132
	dc.w	$121
	dc.w	$111
	dc.w	$101
	dc.w	$F3
	dc.w	$E5
	dc.w	$D8
	dc.w	$CC
	dc.w	$C1
	dc.w	$B6
	dc.w	$AC
	dc.w	$A2
	dc.w	$99
	dc.w	$90
	dc.w	$88
	dc.w	$81
	dc.w	$1331
	dc.w	$121D
	dc.w	$1119
	dc.w	$1023
	dc.w	$F3B
	dc.w	$E61
	dc.w	$D92
	dc.w	$CCF
	dc.w	$C17
	dc.w	$B69
	dc.w	$AC5
	dc.w	$A2B
	dc.w	$998
	dc.w	$90F
	dc.w	$88C
	dc.w	$812
	dc.w	$79E
	dc.w	$730
	dc.w	$6C9
	dc.w	$667
	dc.w	$60B
	dc.w	$5B5
	dc.w	$563
	dc.w	$515
	dc.w	$4CC
	dc.w	$487
	dc.w	$446
	dc.w	$409
	dc.w	$3CF
	dc.w	$398
	dc.w	$364
	dc.w	$334
	dc.w	$306
	dc.w	$2DA
	dc.w	$2B1
	dc.w	$28B
	dc.w	$266
	dc.w	$244
	dc.w	$223
	dc.w	$204
	dc.w	$1E7
	dc.w	$1CC
	dc.w	$1B2
	dc.w	$19A
	dc.w	$183
	dc.w	$16D
	dc.w	$159
	dc.w	$145
	dc.w	$133
	dc.w	$122
	dc.w	$112
	dc.w	$102
	dc.w	$F4
	dc.w	$E6
	dc.w	$D9
	dc.w	$CD
	dc.w	$C1
	dc.w	$B7
	dc.w	$AC
	dc.w	$A3
	dc.w	$9A
	dc.w	$91
	dc.w	$89
	dc.w	$81
	dc.w	$1343
	dc.w	$122E
	dc.w	$1129
	dc.w	$1032
	dc.w	$F49
	dc.w	$E6E
	dc.w	$D9E
	dc.w	$CDB
	dc.w	$C22
	dc.w	$B74
	dc.w	$ACF
	dc.w	$A34
	dc.w	$9A1
	dc.w	$917
	dc.w	$894
	dc.w	$819
	dc.w	$7A5
	dc.w	$737
	dc.w	$6CF
	dc.w	$66D
	dc.w	$611
	dc.w	$5BA
	dc.w	$568
	dc.w	$51A
	dc.w	$4D1
	dc.w	$48B
	dc.w	$44A
	dc.w	$40D
	dc.w	$3D2
	dc.w	$39B
	dc.w	$368
	dc.w	$337
	dc.w	$309
	dc.w	$2DD
	dc.w	$2B4
	dc.w	$28D
	dc.w	$268
	dc.w	$246
	dc.w	$225
	dc.w	$206
	dc.w	$1E9
	dc.w	$1CE
	dc.w	$1B4
	dc.w	$19B
	dc.w	$184
	dc.w	$16E
	dc.w	$15A
	dc.w	$146
	dc.w	$134
	dc.w	$123
	dc.w	$113
	dc.w	$103
	dc.w	$F5
	dc.w	$E7
	dc.w	$DA
	dc.w	$CE
	dc.w	$C2
	dc.w	$B7
	dc.w	$AD
	dc.w	$A3
	dc.w	$9A
	dc.w	$91
	dc.w	$89
	dc.w	$82
	dc.w	$1354
	dc.w	$123F
	dc.w	$1139
	dc.w	$1041
	dc.w	$F58
	dc.w	$E7B
	dc.w	$DAB
	dc.w	$CE7
	dc.w	$C2D
	dc.w	$B7E
	dc.w	$AD9
	dc.w	$A3D
	dc.w	$9AA
	dc.w	$91F
	dc.w	$89C
	dc.w	$821
	dc.w	$7AC
	dc.w	$73E
	dc.w	$6D6
	dc.w	$673
	dc.w	$617
	dc.w	$5BF
	dc.w	$56D
	dc.w	$51F
	dc.w	$4D5
	dc.w	$490
	dc.w	$44E
	dc.w	$410
	dc.w	$3D6
	dc.w	$39F
	dc.w	$36B
	dc.w	$33A
	dc.w	$30B
	dc.w	$2E0
	dc.w	$2B6
	dc.w	$28F
	dc.w	$26B
	dc.w	$248
	dc.w	$227
	dc.w	$208
	dc.w	$1EB
	dc.w	$1CF
	dc.w	$1B5
	dc.w	$19D
	dc.w	$186
	dc.w	$170
	dc.w	$15B
	dc.w	$148
	dc.w	$135
	dc.w	$124
	dc.w	$114
	dc.w	$104
	dc.w	$F5
	dc.w	$E8
	dc.w	$DB
	dc.w	$CE
	dc.w	$C3
	dc.w	$B8
	dc.w	$AE
	dc.w	$A4
	dc.w	$9B
	dc.w	$92
	dc.w	$8A
	dc.w	$82
	dc.w	$1366
	dc.w	$1250
	dc.w	$1149
	dc.w	$1050
	dc.w	$F66
	dc.w	$E89
	dc.w	$DB8
	dc.w	$CF3
	dc.w	$C39
	dc.w	$B89
	dc.w	$AE3
	dc.w	$A47
	dc.w	$9B3
	dc.w	$928
	dc.w	$8A4
	dc.w	$828
	dc.w	$7B3
	dc.w	$744
	dc.w	$6DC
	dc.w	$679
	dc.w	$61C
	dc.w	$5C5
	dc.w	$572
	dc.w	$523
	dc.w	$4DA
	dc.w	$494
	dc.w	$452
	dc.w	$414
	dc.w	$3D9
	dc.w	$3A2
	dc.w	$36E
	dc.w	$33D
	dc.w	$30E
	dc.w	$2E2
	dc.w	$2B9
	dc.w	$292
	dc.w	$26D
	dc.w	$24A
	dc.w	$229
	dc.w	$20A
	dc.w	$1ED
	dc.w	$1D1
	dc.w	$1B7
	dc.w	$19E
	dc.w	$187
	dc.w	$171
	dc.w	$15C
	dc.w	$149
	dc.w	$136
	dc.w	$125
	dc.w	$115
	dc.w	$105
	dc.w	$F6
	dc.w	$E9
	dc.w	$DB
	dc.w	$CF
	dc.w	$C4
	dc.w	$B9
	dc.w	$AE
	dc.w	$A4
	dc.w	$9B
	dc.w	$92
	dc.w	$8A
	dc.w	$83
	dc.w	$1378
	dc.w	$1261
	dc.w	$1159
	dc.w	$105F
	dc.w	$F74
	dc.w	$E96
	dc.w	$DC4
	dc.w	$CFF
	dc.w	$C44
	dc.w	$B94
	dc.w	$AED
	dc.w	$A50
	dc.w	$9BC
	dc.w	$930
	dc.w	$8AC
	dc.w	$830
	dc.w	$7BA
	dc.w	$74B
	dc.w	$6E2
	dc.w	$67F
	dc.w	$622
	dc.w	$5CA
	dc.w	$577
	dc.w	$528
	dc.w	$4DE
	dc.w	$498
	dc.w	$456
	dc.w	$418
	dc.w	$3DD
	dc.w	$3A6
	dc.w	$371
	dc.w	$340
	dc.w	$311
	dc.w	$2E5
	dc.w	$2BB
	dc.w	$294
	dc.w	$26F
	dc.w	$24C
	dc.w	$22B
	dc.w	$20C
	dc.w	$1EF
	dc.w	$1D3
	dc.w	$1B9
	dc.w	$1A0
	dc.w	$188
	dc.w	$172
	dc.w	$15E
	dc.w	$14A
	dc.w	$138
	dc.w	$126
	dc.w	$116
	dc.w	$106
	dc.w	$F7
	dc.w	$E9
	dc.w	$DC
	dc.w	$D0
	dc.w	$C4
	dc.w	$B9
	dc.w	$AF
	dc.w	$A5
	dc.w	$9C
	dc.w	$93
	dc.w	$8B
	dc.w	$83
	dc.w	$138A
	dc.w	$1272
	dc.w	$1169
	dc.w	$106E
	dc.w	$F82
	dc.w	$EA4
	dc.w	$DD1
	dc.w	$D0B
	dc.w	$C4F
	dc.w	$B9E
	dc.w	$AF7
	dc.w	$A5A
	dc.w	$9C5
	dc.w	$939
	dc.w	$8B4
	dc.w	$837
	dc.w	$7C1
	dc.w	$752
	dc.w	$6E9
	dc.w	$685
	dc.w	$628
	dc.w	$5CF
	dc.w	$57C
	dc.w	$52D
	dc.w	$4E3
	dc.w	$49C
	dc.w	$45A
	dc.w	$41C
	dc.w	$3E1
	dc.w	$3A9
	dc.w	$374
	dc.w	$343
	dc.w	$314
	dc.w	$2E8
	dc.w	$2BE
	dc.w	$296
	dc.w	$271
	dc.w	$24E
	dc.w	$22D
	dc.w	$20E
	dc.w	$1F0
	dc.w	$1D4
	dc.w	$1BA
	dc.w	$1A1
	dc.w	$18A
	dc.w	$174
	dc.w	$15F
	dc.w	$14B
	dc.w	$139
	dc.w	$127
	dc.w	$117
	dc.w	$107
	dc.w	$F8
	dc.w	$EA
	dc.w	$DD
	dc.w	$D1
	dc.w	$C5
	dc.w	$BA
	dc.w	$AF
	dc.w	$A6
	dc.w	$9C
	dc.w	$94
	dc.w	$8B
	dc.w	$83
	dc.w	$139C
	dc.w	$1283
	dc.w	$1179
	dc.w	$107E
	dc.w	$F91
	dc.w	$EB1
	dc.w	$DDE
	dc.w	$D17
	dc.w	$C5B
	dc.w	$BA9
	dc.w	$B02
	dc.w	$A63
	dc.w	$9CE
	dc.w	$941
	dc.w	$8BC
	dc.w	$83F
	dc.w	$7C8
	dc.w	$759
	dc.w	$6EF
	dc.w	$68B
	dc.w	$62D
	dc.w	$5D5
	dc.w	$581
	dc.w	$532
	dc.w	$4E7
	dc.w	$4A1
	dc.w	$45E
	dc.w	$41F
	dc.w	$3E4
	dc.w	$3AC
	dc.w	$377
	dc.w	$346
	dc.w	$317
	dc.w	$2EA
	dc.w	$2C0
	dc.w	$299
	dc.w	$274
	dc.w	$250
	dc.w	$22F
	dc.w	$210
	dc.w	$1F2
	dc.w	$1D6
	dc.w	$1BC
	dc.w	$1A3
	dc.w	$18B
	dc.w	$175
	dc.w	$160
	dc.w	$14C
	dc.w	$13A
	dc.w	$128
	dc.w	$118
	dc.w	$108
	dc.w	$F9
	dc.w	$EB
	dc.w	$DE
	dc.w	$D1
	dc.w	$C6
	dc.w	$BB
	dc.w	$B0
	dc.w	$A6
	dc.w	$9D
	dc.w	$94
	dc.w	$8C
	dc.w	$84
	dc.w	$13AF
	dc.w	$1294
	dc.w	$1189
	dc.w	$108D
	dc.w	$F9F
	dc.w	$EBF
	dc.w	$DEB
	dc.w	$D23
	dc.w	$C66
	dc.w	$BB4
	dc.w	$B0C
	dc.w	$A6D
	dc.w	$9D7
	dc.w	$94A
	dc.w	$8C4
	dc.w	$846
	dc.w	$7D0
	dc.w	$75F
	dc.w	$6F5
	dc.w	$691
	dc.w	$633
	dc.w	$5DA
	dc.w	$586
	dc.w	$537
	dc.w	$4EC
	dc.w	$4A5
	dc.w	$462
	dc.w	$423
	dc.w	$3E8
	dc.w	$3B0
	dc.w	$37B
	dc.w	$349
	dc.w	$31A
	dc.w	$2ED
	dc.w	$2C3
	dc.w	$29B
	dc.w	$276
	dc.w	$252
	dc.w	$231
	dc.w	$212
	dc.w	$1F4
	dc.w	$1D8
	dc.w	$1BD
	dc.w	$1A4
	dc.w	$18D
	dc.w	$176
	dc.w	$161
	dc.w	$14E
	dc.w	$13B
	dc.w	$129
	dc.w	$119
	dc.w	$109
	dc.w	$FA
	dc.w	$EC
	dc.w	$DF
	dc.w	$D2
	dc.w	$C6
	dc.w	$BB
	dc.w	$B1
	dc.w	$A7
	dc.w	$9D
	dc.w	$95
	dc.w	$8C
	dc.w	$84
	dc.w	$13C1
	dc.w	$12A5
	dc.w	$1199
	dc.w	$109C
	dc.w	$FAE
	dc.w	$ECC
	dc.w	$DF8
	dc.w	$D2F
	dc.w	$C72
	dc.w	$BBF
	dc.w	$B16
	dc.w	$A77
	dc.w	$9E0
	dc.w	$953
	dc.w	$8CD
	dc.w	$84E
	dc.w	$7D7
	dc.w	$766
	dc.w	$6FC
	dc.w	$698
	dc.w	$639
	dc.w	$5DF
	dc.w	$58B
	dc.w	$53B
	dc.w	$4F0
	dc.w	$4A9
	dc.w	$466
	dc.w	$427
	dc.w	$3EB
	dc.w	$3B3
	dc.w	$37E
	dc.w	$34C
	dc.w	$31C
	dc.w	$2F0
	dc.w	$2C6
	dc.w	$29E
	dc.w	$278
	dc.w	$255
	dc.w	$233
	dc.w	$214
	dc.w	$1F6
	dc.w	$1DA
	dc.w	$1BF
	dc.w	$1A6
	dc.w	$18E
	dc.w	$178
	dc.w	$163
	dc.w	$14F
	dc.w	$13C
	dc.w	$12A
	dc.w	$11A
	dc.w	$10A
	dc.w	$FB
	dc.w	$ED
	dc.w	$DF
	dc.w	$D3
	dc.w	$C7
	dc.w	$BC
	dc.w	$B1
	dc.w	$A7
	dc.w	$9E
	dc.w	$95
	dc.w	$8D
	dc.w	$85
	dc.w	$13D3
	dc.w	$12B6
	dc.w	$11A9
	dc.w	$10AC
	dc.w	$FBC
	dc.w	$EDA
	dc.w	$E05
	dc.w	$D3B
	dc.w	$C7D
	dc.w	$BCA
	dc.w	$B20
	dc.w	$A80
	dc.w	$9EA
	dc.w	$95B
	dc.w	$8D5
	dc.w	$856
	dc.w	$7DE
	dc.w	$76D
	dc.w	$702
	dc.w	$69E
	dc.w	$63F
	dc.w	$5E5
	dc.w	$590
	dc.w	$540
	dc.w	$4F5
	dc.w	$4AE
	dc.w	$46A
	dc.w	$42B
	dc.w	$3EF
	dc.w	$3B7
	dc.w	$381
	dc.w	$34F
	dc.w	$31F
	dc.w	$2F2
	dc.w	$2C8
	dc.w	$2A0
	dc.w	$27A
	dc.w	$257
	dc.w	$235
	dc.w	$215
	dc.w	$1F8
	dc.w	$1DB
	dc.w	$1C1
	dc.w	$1A7
	dc.w	$190
	dc.w	$179
	dc.w	$164
	dc.w	$150
	dc.w	$13D
	dc.w	$12B
	dc.w	$11B
	dc.w	$10B
	dc.w	$FC
	dc.w	$EE
	dc.w	$E0
	dc.w	$D4
	dc.w	$C8
	dc.w	$BD
	dc.w	$B2
	dc.w	$A8
	dc.w	$9F
	dc.w	$96
	dc.w	$8D
	dc.w	$85
	dc.w	$13E5
	dc.w	$12C8
	dc.w	$11BA
	dc.w	$10BB
	dc.w	$FCB
	dc.w	$EE8
	dc.w	$E12
	dc.w	$D47
	dc.w	$C89
	dc.w	$BD5
	dc.w	$B2B
	dc.w	$A8A
	dc.w	$9F3
	dc.w	$964
	dc.w	$8DD
	dc.w	$85E
	dc.w	$7E5
	dc.w	$774
	dc.w	$709
	dc.w	$6A4
	dc.w	$644
	dc.w	$5EA
	dc.w	$595
	dc.w	$545
	dc.w	$4F9
	dc.w	$4B2
	dc.w	$46E
	dc.w	$42F
	dc.w	$3F3
	dc.w	$3BA
	dc.w	$384
	dc.w	$352
	dc.w	$322
	dc.w	$2F5
	dc.w	$2CB
	dc.w	$2A3
	dc.w	$27D
	dc.w	$259
	dc.w	$237
	dc.w	$217
	dc.w	$1F9
	dc.w	$1DD
	dc.w	$1C2
	dc.w	$1A9
	dc.w	$191
	dc.w	$17B
	dc.w	$165
	dc.w	$151
	dc.w	$13E
	dc.w	$12C
	dc.w	$11C
	dc.w	$10C
	dc.w	$FD
	dc.w	$EE
	dc.w	$E1
	dc.w	$D4
	dc.w	$C9
	dc.w	$BD
	dc.w	$B3
	dc.w	$A9
	dc.w	$9F
	dc.w	$96
	dc.w	$8E
	dc.w	$86
MUGEND
	end
