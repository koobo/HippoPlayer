;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000

test	=	0

	incdir	include:
	include	mucro.i

* Scope data for one channel
              rsreset
ns_start      rs.l       1 * Sample start address
ns_length     rs         1 * Length in words
ns_loopstart  rs.l       1 * Loop start address
ns_replen     rs         1 * Loop length in words
ns_vol    rs         1 * Volume
ns_period     rs         1 * Period
ns_size       rs.b       0 * = 16 bytes

* Combined scope data structure
              rsreset
scope_ch1	  rs.b	ns_size
scope_ch2	  rs.b	ns_size
scope_ch3	  rs.b	ns_size
scope_ch4	  rs.b	ns_size
scope_trigger rs.b  1 * Audio channel enable DMA flags
scope_pad	  rs.b  1
scope_size    rs.b  0

 ifne test
bob
;	lea	module,a0
;	jsr	Check2

	* initial song number
	lea	module,a0
	lea	masterVol,a1
	lea	dmawait,a2
    lea songOver_,a3
    lea scope_,a4
	jsr	init
	bne.b	error

	bsr.b	playLoop
;	jsr	end
error
	rts


dmawait
	pushm	d0/d1
	moveq	#12-1,d1
.d	move.b	$dff006,d0
.k	cmp.b	$dff006,d0
	beq.b	.k
	dbf	d1,.d
	popm	d0/d1
	rts

playLoop
.loop	
; REM
	cmp.b	#$80,$dff006
	bne.b	.loop
.x	cmp.b	#$80,$dff006
	beq.b	.x	
; EREM
	move	#$ff0,$dff180
	jsr	play
	clr	$dff180

    tst     songOver
    bne     .xx

	btst	#6,$bfe001
	bne.b	.loop
.xx
	rts


masterVol 	dc $40/2
songOver_   dc.w    0
scope_		ds.b scope_size

	SECTION	modu,data_c

module  incbin	"m:exo/Delta Music/Dr. Awesome/cryptoburners.dm"



****************************************************************************
	SECTION	Delta10000000,CODE

 endif


	jmp 	init(pc)
	jmp	play(pc)

init
	move.l	a0,moduleAddress
	move.l	a1,masterVolumeAddress
	move.l	a2,dmaWaitAddress
    move.l  a3,songOverAddress
    move.l  a4,scope
	bra.w	_init

play
	move.l	masterVolumeAddress(pc),a0
	move	(a0),masterVolume
	bra	_play
	

masterVolumeAddress	dc.l	0
moduleAddress		dc.l	0
masterVolume		dc.w	0
dmaWaitAddress		dc.l	0
songOverAddress     dc.l    0
scope               dc.l    0

setStart
    move.l  a4,a1
    sub.l   #$dff0a0,a1
    add.l   scope(pc),a1
    move.l  d0,ns_start(a1)
    move.l  d0,ns_loopstart(a1)
    rts

setLength
    move.l  a4,a1
    sub.l   #$dff0a0,a1
    add.l   scope(pc),a1
    move.w  d0,ns_length(a1)
    move.w  d0,ns_replen(a1)
    rts


setPeriod
    move.l  a4,a1
    sub.l   #$dff0a0,a1
    add.l   scope(pc),a1
    move.w  d0,ns_period(a1)
    rts

setVol
    move.l  a4,a1
    sub.l   #$dff0a0,a1
    add.l   scope(pc),a1
    move.w  d1,ns_vol(a1)
    rts


_play
	MOVEM.L	D0-D7/A0-A6,-(SP)
	LEA	lbL0008F0(PC),A6
	BSR.W	lbC00023E
	LEA	lbL00092A(PC),A6
	BSR.W	lbC00023E
	LEA	lbL000964(PC),A6
	BSR.W	lbC00023E
	LEA	lbL00099E(PC),A6
	BSR.W	lbC00023E
	MOVE.W	#$800F,$DFF096
	move.l	dmaWaitAddress(pc),a6
	jsr	(a6)
	LEA	lbL0008F0(PC),A6 * channel 1 data
    move.l  scope(pc),a3
	MOVE.L	(A6),A4     * audio base
	MOVE.L	6(A6),A5
	TST.B	14(A5)
	BEQ.S	lbC0001BA
	MOVE.W	$1C(A5),4(A4)   * replen?
	MOVE.W	$1C(A5),ns_replen(A3)   
	MOVEQ	#0,D7
	MOVE.W	$1A(A5),D7
	ADD.L	A5,D7
	ADD.L	#$1E,D7
	MOVE.L	D7,(A4)         * loopstart?
    move.l  d7,ns_loopstart(a3)
lbC0001BA	
    lea     ns_size(a3),a3
    LEA	lbL00092A(PC),A6    * channel 2 data
	MOVE.L	(A6),A4
	MOVE.L	6(A6),A5
	TST.B	14(A5)
	BEQ.S	lbC0001E4
	MOVE.W	$1C(A5),4(A4)
	MOVE.W	$1C(A5),ns_replen(A3)   
	MOVEQ	#0,D7
	MOVE.W	$1A(A5),D7
	ADD.L	A5,D7
	ADD.L	#$1E,D7
	MOVE.L	D7,(A4)
    move.l  d7,ns_loopstart(a3)
lbC0001E4	
    lea     ns_size(a3),a3
    LEA	lbL000964(PC),A6
	MOVE.L	(A6),A4
	MOVE.L	6(A6),A5
	TST.B	14(A5)
	BEQ.S	lbC00020E
	MOVE.W	$1C(A5),4(A4)
	MOVE.W	$1C(A5),ns_replen(A3)   
	MOVEQ	#0,D7
	MOVE.W	$1A(A5),D7
	ADD.L	A5,D7
	ADD.L	#$1E,D7
	MOVE.L	D7,(A4)
    move.l  d7,ns_loopstart(a3)
lbC00020E	
    lea     ns_size(a3),a3
    LEA	lbL00099E(PC),A6
	MOVE.L	(A6),A4
	MOVE.L	6(A6),A5
	TST.B	14(A5)
	BEQ.S	lbC000238
	MOVE.W	$1C(A5),4(A4)
	MOVE.W	$1C(A5),ns_replen(A3)   
	MOVEQ	#0,D7
	MOVE.W	$1A(A5),D7
	ADD.L	A5,D7
	ADD.L	#$1E,D7
	MOVE.L	D7,(A4)
    move.l  d7,ns_loopstart(a3)
lbC000238	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

* play voice 
* a6 = channel data
lbC00023E	MOVE.L	(A6),A4     * get audio base
	MOVE.L	6(A6),A5
	SUBQ.B	#1,$2F(A6)      * speed counter
	BNE.W	lbC00036E
	MOVE.B	lbB000836,$2F(A6)
	TST.L	$1C(A6)
	BNE.S	lbC000296
lbC00025C	MOVE.L	$12(A6),A0
	MOVE.W	$16(A6),D7
	MOVE.W	(A0,D7.W),D0
	CMP.W	#$FFFF,D0
	BNE.S	lbC00027E

    * song end?
    move.l  songOverAddress(pc),a1
    st      (a1)

	MOVE.W	2(A0,D7.W),D0
	AND.W	#$7FF,D0
	ASL.W	#1,D0
	MOVE.W	D0,$16(A6)
	BRA.S	lbC00025C

lbC00027E	MOVE.B	D0,$32(A6)
	ASR.L	#2,D0
	AND.L	#$3FC0,D0
	ADD.L	lbL0009E8(PC),D0
	MOVE.L	D0,$18(A6)
	ADDQ.W	#2,$16(A6)
lbC000296	MOVE.L	$18(A6),A0  * current pattern data ptr
	ADD.L	$1C(A6),A0
	TST.B	2(A0)
	BEQ.S	lbC0002B0
	MOVE.B	2(A0),$37(A6)
	MOVE.B	3(A0),$38(A6)
lbC0002B0	MOVEQ	#0,D0
	MOVE.B	1(A0),D0
	BEQ.W	lbC00035C
	ADD.B	$32(A6),D0
	MOVE.B	D0,$28(A6)
	MOVE.W	4(A6),D0
	SUB.W	#$8000,D0
	MOVE.W	D0,$DFF096
	MOVEQ	#0,D0
	MOVE.B	D0,$33(A6)
	MOVE.W	D0,$30(A6)
	MOVE.W	D0,$34(A6)
	MOVE.B	D0,$36(A6)
	MOVE.B	2(A0),$37(A6)
	MOVE.B	3(A0),$38(A6)
	LEA	lbL0009EC(PC),A1
	MOVE.B	(A0),D0
	ASL.L	#2,D0
	MOVE.L	0(A1,D0.L),D0
	MOVE.L	D0,6(A6)
	MOVE.L	D0,A5
	ADD.L	#$1E,D0
	MOVE.L	D0,12(A6)
	CLR.B	$10(A6)
	TST.B	14(A5)
	BEQ.S	lbC00031C
	CLR.W	$1E(A5) 
	MOVE.L	D0,(A4)         * start
    bsr     setStart
lbC00031C	MOVE.W	$18(A5),D0
	ASR.W	#1,D0
	MOVE.W	D0,4(A4)
    bsr     setLength
	MOVE.B	9(A5),$20(A6)
	MOVE.B	11(A5),D0
	MOVE.B	D0,$21(A6)
	MOVE.B	D0,$22(A6)
	ASL.B	#1,D0
	MOVE.B	D0,$23(A6)
	CLR.B	$29(A6)
	CLR.B	$11(A6)
	CLR.B	$10(A6)
	CLR.B	$2A(A6)
	CLR.B	$2B(A6)
	MOVE.W	4(A5),$2C(A6)
	CLR.B	$2E(A6)
lbC00035C	ADDQ.L	#4,$1C(A6)
	CMP.L	#$40,$1C(A6)
	BNE.S	lbC00036E
	CLR.L	$1C(A6)
lbC00036E	TST.B	14(A5)
	BNE.S	lbC0003D6
	TST.B	$11(A6)
	BEQ.S	lbC000380
	SUBQ.B	#1,$11(A6)
	BRA.S	lbC0003D6

lbC000380	MOVE.B	15(A5),$11(A6)
lbC000386	MOVE.L	12(A6),A0
	MOVEQ	#0,D6
	MOVE.B	$10(A6),D6
	CMP.B	#$30,D6
	BMI.S	lbC00039C
	CLR.B	$10(A6)
	MOVEQ	#0,D6
lbC00039C	ADD.L	D6,A0
	MOVEQ	#0,D7
	MOVE.B	(A0),D7
	BPL.S	lbC0003C2
	CMP.B	#$FF,D7
	BNE.S	lbC0003B4
	MOVE.B	1(A0),D7
	MOVE.B	D7,$10(A6)
	BRA.S	lbC000386

lbC0003B4	AND.B	#$7F,D7
	MOVE.B	D7,15(A5)
	ADDQ.B	#1,$10(A6)
	BRA.S	lbC000386

lbC0003C2	ASL.L	#5,D7
	ADD.L	#$4E,D7
	ADD.L	6(A6),D7
	MOVE.L	D7,(A4)
    move.l  d7,d0
    bsr     setStart
	ADDQ.B	#1,$10(A6)
lbC0003D6	TST.B	13(A5)
	BEQ.S	lbC00043E
	MOVE.W	10(A6),D1
	BNE.S	lbC0003FC
	MOVEQ	#0,D0
	LEA	lbW000848(PC),A1
	MOVE.B	$28(A6),D0
	ASL.W	#1,D0
	MOVE.W	0(A1,D0.W),D0
	ADD.W	$30(A6),D0
	MOVE.W	D0,10(A6)
	BRA.S	lbC00043E

lbC0003FC	MOVEQ	#0,D0
	MOVEQ	#0,D2
	MOVE.B	13(A5),D2
	LEA	lbW000848(PC),A1
	MOVE.B	$28(A6),D0
	ASL.W	#1,D0
	MOVE.W	0(A1,D0.W),D0
	ADD.W	$30(A6),D0
	CMP.W	D0,D1
	BEQ.S	lbC00043E
	BLO.S	lbC00042E
	SUB.W	D2,D1
	CMP.W	D0,D1
	BPL.S	lbC000428
	MOVE.W	D0,10(A6)
	BRA.S	lbC00043E

lbC000428	MOVE.W	D1,10(A6)
	BRA.S	lbC00043E

lbC00042E	ADD.W	D2,D1
	CMP.W	D0,D1
	BMI.S	lbC00043A
	MOVE.W	D0,10(A6)
	BRA.S	lbC00043E

lbC00043A	MOVE.W	D1,10(A6)
lbC00043E	TST.B	$20(A6)
	BEQ.S	lbC00044A
	SUBQ.B	#1,$20(A6)
	BRA.S	lbC000488

lbC00044A	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.B	$22(A6),D0
	MOVE.B	D0,D2
	MOVE.B	10(A5),D1
	MULU	D1,D0
	MOVE.W	D0,$24(A6)
	BTST	#0,$33(A6)
	BNE.S	lbC00047A
	ADDQ.B	#1,D2
	CMP.B	$23(A6),D2
	BNE.S	lbC000474
	EOR.B	#1,$33(A6)
lbC000474	MOVE.B	D2,$22(A6)
	BRA.S	lbC000488

lbC00047A	SUBQ.B	#1,D2
	BNE.S	lbC000484
	EOR.B	#1,$33(A6)
lbC000484	MOVE.B	D2,$22(A6)
lbC000488	MOVEQ	#0,D0
	MOVE.L	6(A6),A1
	MOVE.B	12(A1),D0
	BPL.S	lbC00049C
	NEG.B	D0
	ADD.W	D0,$30(A6)
	BRA.S	lbC0004A0

lbC00049C	SUB.W	D0,$30(A6)
lbC0004A0	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.B	$38(A6),D0
	MOVE.B	$37(A6),D1
	LEA	lbL0007B6(PC),A1
	AND.B	#$1F,D1
	ASL.L	#2,D1
	MOVE.L	0(A1,D1.W),A1
	JSR	(A1)
	MOVE.L	A5,A1
	ADD.L	#$10,A1
	MOVEQ	#0,D0
	MOVE.B	$34(A6),D0
	MOVE.B	0(A1,D0.W),D1
	ADDQ.B	#1,$34(A6)
	AND.B	#7,$34(A6)
	LEA	lbW000848(PC),A1
	MOVE.B	$28(A6),D0
	ADD.B	D1,D0
	ASL.W	#1,D0
	MOVE.W	0(A1,D0.L),D0
	MOVEQ	#0,D1
	MOVEQ	#0,D2
	MOVE.B	$21(A6),D1
	MOVE.B	10(A5),D2
	MULU	D2,D1
	SUB.W	D1,D0
	ADD.W	$30(A6),D0
	TST.B	13(A5)
	BEQ.S	lbC000508
	MOVE.W	10(A6),D0
	BRA.S	lbC00050C

lbC000508	CLR.W	10(A6)
lbC00050C	ADD.W	$24(A6),D0
	MOVE.W	D0,6(A4)
    bsr     setPeriod
	MOVEQ	#0,D1
	MOVE.B	$29(A6),D1
	MOVE.B	$33(A6),D0
	AND.B	#14,D0
	TST.B	D0
	BNE.S	lbC000552
	TST.B	$2A(A6)
	BEQ.S	lbC000534
	SUBQ.B	#1,$2A(A6)
	BRA.W	lbC0005C6

lbC000534	MOVE.B	1(A5),$2A(A6)
	ADD.B	0(A5),D1
	CMP.B	#$40,D1
	BLO.S	lbC000552
	OR.B	#2,D0
	OR.B	#2,$33(A6)
	MOVE.B	#$40,D1
lbC000552	CMP.B	#2,D0
	BNE.S	lbC000584
	TST.B	$2B(A6)
	BEQ.S	lbC000564
	SUBQ.B	#1,$2B(A6)
	BRA.S	lbC0005C6

lbC000564	MOVE.B	3(A5),$2B(A6)
	MOVE.B	8(A5),D2
	SUB.B	2(A5),D1
	CMP.B	D2,D1
	BHI.S	lbC000584
	MOVE.B	8(A5),D1
	OR.B	#6,D0
	OR.B	#6,$33(A6)
lbC000584	CMP.B	#6,D0
	BNE.S	lbC0005A0
	TST.W	$2C(A6)
	BEQ.S	lbC000596
	SUBQ.W	#1,$2C(A6)
	BRA.S	lbC0005C6

lbC000596	OR.B	#14,D0
	OR.B	#14,$33(A6)
lbC0005A0	CMP.B	#14,D0
	BNE.S	lbC0005C6
	TST.B	$2E(A6)
	BEQ.S	lbC0005B2
	SUBQ.B	#1,$2E(A6)
	BRA.S	lbC0005C6

lbC0005B2	MOVE.B	7(A5),$2E(A6)
	SUB.B	6(A5),D1
	BPL.S	lbC0005C6
	AND.B	#9,$33(A6)
	MOVEQ	#0,D1
lbC0005C6	MOVE.B	D1,$29(A6)
	; VOL?
	mulu	masterVolume(pc),d1
	lsr	#6,d1
	MOVE.W	D1,8(A4)
    bsr     setVol
	RTS

_init
lbC0005D0	MOVE.L	moduleAddress(pc),A0
	LEA	$68(A0),A0
	LEA	lbL0009D8(PC),A1
	MOVEQ	#$18,D7
lbC0005E0	MOVE.L	A0,(A1)+
	DBRA	D7,lbC0005E0
	MOVEQ	#$17,D6
	LEA	lbL000A38(PC),A1
lbC0005EC	MOVE.L	moduleAddress(pc),A0
	LEA	4(A0),A0
	MOVE.L	D6,D7
lbC0005F8	MOVE.L	(A0)+,D0
	ADD.L	D0,(A1)
	DBRA	D7,lbC0005F8
	SUBQ.L	#4,A1
	DBRA	D6,lbC0005EC
	MOVE.B	#6,lbB000836
	LEA	$DFF0A0,A0
	MOVE.L	lbL0009D8(PC),A1
	MOVE.W	#$8001,D0
	LEA	lbL0008F0(PC),A6
	BSR.S	lbC000660
	lea	$10(A0),A0
	MOVE.L	lbL0009DC(PC),A1
	MOVE.W	#$8002,D0
	LEA	lbL00092A(PC),A6
	BSR.S	lbC000660
	lea	$10(A0),A0
	MOVE.L	lbL0009E0(PC),A1
	MOVE.W	#$8004,D0
	LEA	lbL000964(PC),A6
	BSR.S	lbC000660
	lea	$10(A0),A0
	MOVE.L	lbL0009E4(PC),A1
	MOVE.W	#$8008,D0
	LEA	lbL00099E(PC),A6
	BSR.S	lbC000660
	RTS

* a0 = $DFF0A0...
* d0 = dma enable 
lbC000660	MOVE.L	A0,(A6) * write audio base to channel data
	MOVE.W	D0,4(A6)
	MOVE.W	#$10,4(A0)     
	CLR.W	8(A0)
	MOVE.L	#lbL000838,6(A6)
	CLR.W	10(A6)
	MOVE.L	lbL0009EC(PC),D0
	ADD.L	#$10,D0
	MOVE.L	D0,12(A6)
	CLR.W	$10(A6)
	MOVE.L	A1,$12(A6)
	CLR.W	$16(A6)
	MOVE.L	lbL0009E8(PC),$18(A6)
	CLR.L	$1C(A6)
	CLR.L	$20(A6)
	CLR.L	$24(A6)
	CLR.L	$28(A6)
	MOVE.L	#1,$2C(A6)
	CLR.L	$30(A6)
	CLR.L	$34(A6)
	CLR.W	$38(A6)
	RTS

lbC0006C4	RTS

lbC0006C6	AND.B	#15,D0
	BEQ.S	lbC0006D2
	MOVE.B	D0,lbB000836
lbC0006D2	RTS

lbC0006D4	SUB.W	D0,$30(A6)
	RTS

lbC0006DA	ADD.W	D0,$30(A6)
	RTS
lbC0006E0	RTS

lbC0006E2	MOVE.B	D0,9(A5)
	RTS

lbC0006E8	MOVE.B	D0,10(A5)
	RTS

lbC0006EE	MOVE.B	D0,11(A5)
	RTS

lbC0006F4	MOVE.B	D0,12(A5)
	RTS

lbC0006FA	MOVE.B	D0,13(A5)
	RTS

lbC000700	CMP.B	#$41,D0
	BMI.S	lbC00070A
	MOVE.B	#$40,D0
lbC00070A	
	MOVE.B	D0,8(A5)
	RTS

lbC000710	MOVE.B	D0,$10(A5)
	RTS

lbC000716	MOVE.B	D0,$11(A5)
	RTS

lbC00071C	MOVE.B	D0,$12(A5)
	RTS

lbC000722	MOVE.B	D0,$13(A5)
	RTS

lbC000728	MOVE.B	D0,$14(A5)
	RTS

lbC00072E	MOVE.B	D0,$15(A5)
	RTS

lbC000734	MOVE.B	D0,$16(A5)
	RTS

lbC00073A	MOVE.B	D0,$17(A5)
	RTS

lbC000740	MOVE.B	D0,$10(A5)
	MOVE.B	D0,$14(A5)
	RTS

lbC00074A	MOVE.B	D0,$11(A5)
	MOVE.B	D0,$15(A5)
	RTS

lbC000754	MOVE.B	D0,$12(A5)
	MOVE.B	D0,$16(A5)
	RTS

lbC00075E	MOVE.B	D0,$13(A5)
	MOVE.B	D0,$17(A5)
	RTS

lbC000768	CMP.B	#$41,D0
	BMI.S	lbC000772
	MOVE.B	#$40,D0
lbC000772	MOVE.B	D0,(A5)
	RTS


lbC000778	MOVE.B	D0,1(A5)
	RTS

lbC00077E	CMP.B	#$41,D0
	BMI.S	lbC000788
	MOVE.B	#$40,D0
lbC000788	MOVE.B	D0,2(A5)
	RTS


lbC00078E	MOVE.B	D0,3(A5)
	RTS

lbC000794	MOVE.B	D0,4(A5)
	RTS

lbC00079A	MOVE.B	D0,5(A5)
	RTS

lbL0007A0	
	CMP.B	#$41,D0
	BMI.B	lbC0007AA
	MOVE.B	#$40,D0
lbC0007AA	MOVE.B	D0,6(A5)
	RTS

lbC0007B0	MOVE.B	D0,7(A5)
	RTS

lbL0007B6	dc.l	lbC0006C4
	dc.l	lbC0006C6
	dc.l	lbC0006D4
	dc.l	lbC0006DA
	dc.l	lbC0006E0
	dc.l	lbC0006E2
	dc.l	lbC0006E8
	dc.l	lbC0006EE
	dc.l	lbC0006F4
	dc.l	lbC0006FA
	dc.l	lbC000700
	dc.l	lbC000710
	dc.l	lbC000716
	dc.l	lbC00071C
	dc.l	lbC000722
	dc.l	lbC000728
	dc.l	lbC00072E
	dc.l	lbC000734
	dc.l	lbC00073A
	dc.l	lbC000740
	dc.l	lbC00074A
	dc.l	lbC000754
	dc.l	lbC00075E
	dc.l	lbC000768
	dc.l	lbC000778
	dc.l	lbC00077E
	dc.l	lbC00078E
	dc.l	lbC000794
	dc.l	lbC00079A
	dc.l	lbL0007A0
	dc.l	lbC0007B0
	dc.l	lbC0006C4
lbB000836	dc.b	0
	dc.b	0
lbL000838	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
lbW000848	dc.w	0
	dc.w	$1AC0
	dc.w	$1940
	dc.w	$17D0
	dc.w	$1680
	dc.w	$1530
	dc.w	$1400
	dc.w	$12E0
	dc.w	$11D0
	dc.w	$10D0
	dc.w	$FE0
	dc.w	$F00
	dc.w	$E20
	dc.w	$D60
	dc.w	$CA0
	dc.w	$BE8
	dc.w	$B40
	dc.w	$A98
	dc.w	$A00
	dc.w	$970
	dc.w	$8E8
	dc.w	$868
	dc.w	$7F0
	dc.w	$780
	dc.w	$710
	dc.w	$6B0
	dc.w	$650
	dc.w	$5F4
	dc.w	$5A0
	dc.w	$54C
	dc.w	$500
	dc.w	$4B8
	dc.w	$474
	dc.w	$434
	dc.w	$3C0
	dc.w	$388
	dc.w	$358
	dc.w	$328
	dc.w	$2FA
	dc.w	$2D0
	dc.w	$2A6
	dc.w	$280
	dc.w	$25C
	dc.w	$23A
	dc.w	$21A
	dc.w	$1FC
	dc.w	$1E0
	dc.w	$1C4
	dc.w	$1AC
	dc.w	$194
	dc.w	$17D
	dc.w	$168
	dc.w	$153
	dc.w	$140
	dc.w	$12E
	dc.w	$11D
	dc.w	$10D
	dc.w	$FE
	dc.w	$F0
	dc.w	$E2
	dc.w	$D6
	dc.w	$CA
	dc.w	$BE
	dc.w	$B4
	dc.w	$AA
	dc.w	$A0
	dc.w	$97
	dc.w	$8F
	dc.w	$87
	dc.w	$7F
	dc.w	$78
	dc.w	$71
	dc.w	$71
	dc.w	$71
	dc.w	$71
	dc.w	$71
	dc.w	$71
	dc.w	$71
	dc.w	$71
	dc.w	$71
	dc.w	$71
	dc.w	$71
	dc.w	$71
	dc.w	$71
lbL0008F0	dc.l	$DFF0A0
	dc.l	$80010000
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	1
	dc.l	0
	dc.l	0
	dc.w	0
lbL00092A	dc.l	0
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
	dc.w	0
lbL000964	dc.l	0
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
	dc.w	0
lbL00099E	dc.l	0
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
	dc.w	0
lbL0009D8	dc.l	0
lbL0009DC	dc.l	0
lbL0009E0	dc.l	0
lbL0009E4	dc.l	0
lbL0009E8	dc.l	0
lbL0009EC	dc.l	0
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
lbL000A38	dc.l	0

	end
