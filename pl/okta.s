;APS0000000B0000000B0000000B0000000B0000000B0000000B0000000B0000000B0000000B0000000B

 ifnd TEST
TEST = 1
 endif


	incdir	include:
	include exec/memory.i
	include exec/exec_lib.i
	include	misc/eagleplayer.i
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


 ifne TEST

	lea	Music,a0 
	lea	songend_,a1
	lea scope_,a2
	jsr	init_

	move	#$40,d0
	jsr	vol

loop
.1	cmp.b	#$80,$dff006
	bne.b 	.1
.2	cmp.b	#$80,$dff006
	beq.b 	.2 

	move	#$f00,$dff180 
	jsr	music_ 
	move	#0,$dff180 

	btst	#6,$bfe001 
	bne.b 	loop 

	jsr 	end_ 
	rts

songend_	dc	0
scope_		ds.b 	scope_size

		section	dc,data_c

;Music:		incbin	"m:exo/oktalyzer/captain/okt.popcorn"
Music:		incbin	"m:exo/oktalyzer/mohr/1 love night dub.okta"



	SECTION	absplay2rs000000,CODE_p
 endc

	jmp	init_(pc)
	jmp 	music_(pc)
	jmp 	end_(pc)
	jmp	vol(pc)

songEndAddr		dc.l	0
moduleAddr 		dc.l 	0
chipAddr		dc.l	0
scopeAddr		dc.l	0

	rsreset 
chip_18c0	rs.l 	$14
		rs.w	1 
chip_1912	rs.l 	$230
chip_21d2 	rs.l 	$230 
		rs.w 	1
chip_2a94	rs.l 	1
chipSize	rs.b 	0

lbL0018C0	dc.l	0
lbL001912	dc.l	0
lbL0021D2	dc.l	0
lbL002A94	dc.l	0

numOfVoices	dc		0

init_ 
	move.l	a0,moduleAddr
	move.l	a1,songEndAddr
	move.l	a2,scopeAddr

	move.l	4.w,a6
	move.l	#chipSize,d0
	move.l	#MEMF_CHIP|MEMF_CLEAR,d1 
	jsr	_LVOAllocMem(a6)
	move.l	d0,chipAddr 
	beq.b .mem

	move.l	d0,a0 
	lea	chip_18c0(a0),a1
	move.l	a1,lbL0018C0
	lea	chip_1912(a0),a1
	move.l	a1,lbL001912
	lea	chip_21d2(a0),a1 
	move.l	a1,lbL0021D2
	lea	chip_2a94(a0),a1 
	move.l	a1,lbL002A94

	lea	lbL0006BA(pc),a0 
	move.l	lbL001912(pc),(a0)+
	move.l	lbL0021D2(pc),(a0)+


	MOVE.L	moduleAddr(PC),D0
	MOVE.L	D0,A0
	ADDQ.L	#8,A0
	MOVE.L	#"CMOD",D0
	BSR	FindBlock
	MOVEQ	#4,D0
	ADD.W	(A0)+,D0
	ADD.W	(A0)+,D0
	ADD.W	(A0)+,D0
	ADD.W	(A0)+,D0
	MOVE	D0,numOfVoices


	move.l	moduleAddr(pc),a0
	bsr.w	init
	bsr	PatternInit
	moveq	#0,d0
	rts
.mem 
	moveq	#-1,d0 
	rts
music_
	bsr.w	music
	move	curPos(pc),d0 
	move	maxPos(pc),d1
	rts 
end_ 
	bsr.w	end
	move.l	chipAddr(pc),d0 
	beq.b 	.x 
	move.l	d0,a1 
	move.l	#chipSize,d0
	move.l	4.w,a6 
	jsr	_LVOFreeMem(a6) 
	clr.l	chipAddr 
.x	rts


setPer
	push	a4
	sub.l	#$dff0a0,a4
	add.l	scopeAddr(pc),a4
	move	d0,ns_period(a4)
	pop		a4
	rts

setPerB
	push	a1
	sub.l	#$dff0a6,a1
	add.l	scopeAddr(pc),a1
	move	d1,ns_period(a1)
	pop		a1
	rts


setPerC
	push	a4
	sub.l	#$dff0a0,a4
	add.l	scopeAddr(pc),a4
	move	10(a3),ns_period(a4)
	pop		a4
	rts

setAddr
	push	a4
	sub.l	#$dff0a0,a4
	add.l	scopeAddr(pc),a4
	move.l	d2,ns_start(a4)
	move.l	d2,ns_loopstart(a4)
	pop	a4
	rts


setLen
	push	a4
	sub.l	#$dff0a0,a4
	add.l	scopeAddr(pc),a4
	move	d1,ns_length(a4)
	move	d1,ns_replen(a4)
	pop	a4
	rts


setLenB
	push	a4
	sub.l	#$dff0a0,a4
	add.l	scopeAddr(pc),a4
	move	d0,ns_length(a4)
	move	d0,ns_replen(a4)
	pop	a4
	rts


setRep
	push	a1
	sub.l	#$dff0a0,a1
	add.l	scopeAddr(pc),a1
	move.l	d1,ns_loopstart(a1)
	move	6(a0),ns_replen(a1)
	; ??
	;move.l	d1,ns_start(a1)
	;move	6(a0),ns_length(a1)
	pop	a1
	rts

setRepLen1
	push	a5
	move.l	scopeAddr(pc),a5
;	move.l	(a1),scope_ch1+ns_start(a5)
;	move.w	4(a1),scope_ch1+ns_length(a5)
	move.l	(a1),scope_ch1+ns_loopstart(a5)
	move.w	4(a1),scope_ch1+ns_replen(a5)
	pop		a5
	rts	

setRepLen2
	push	a5
	move.l	scopeAddr(pc),a5
;	move.l	$1c(a1),scope_ch2+ns_start(a5)
;	move.w	$20(a1),scope_ch2+ns_length(a5)
	move.l	$1c(a1),scope_ch2+ns_loopstart(a5)
	move.w	$20(a1),scope_ch2+ns_replen(a5)
	pop		a5
	rts	

setRepLen3
	push	a5
	move.l	scopeAddr(pc),a5
	;move.l	$38(a1),scope_ch3+ns_start(a5)
	;move.w	$3c(a1),scope_ch3+ns_length(a5)
	move.l	$38(a1),scope_ch3+ns_loopstart(a5)
	move.w	$3c(a1),scope_ch3+ns_replen(a5)	
	;move	#$0f0,$dff180
	pop		a5
	rts	


setRepLen4
	push	a5
	move.l	scopeAddr(pc),a5
;	move.l	$54(a1),scope_ch4+ns_start(a5)
;	move.w	$58(a1),scope_ch4+ns_length(a5)
	move.l	$54(a1),scope_ch4+ns_loopstart(a5)
	move.w	$58(a1),scope_ch4+ns_replen(a5)
	pop		a5
	rts	

setVol1
	push	a1
	move.l	scopeAddr(pc),a1
	move	d0,ns_vol+scope_ch1(a1)
	pop		a1
	rts

setVol2
	push	a1
	move.l	scopeAddr(pc),a1
	move	d0,ns_vol+scope_ch2(a1)
	pop		a1
	rts

setVol3
	push	a1
	move.l	scopeAddr(pc),a1
	move	d0,ns_vol+scope_ch3(a1)
	pop		a1
	rts

setVol4
	push	a1
	move.l	scopeAddr(pc),a1
	move	d0,ns_vol+scope_ch4(a1)
	pop		a1
	rts

PatternInfo
	ds.b	PI_Stripes
Stripe1	dc.l	1
Stripe2	dc.l	1
Stripe3	dc.l	1
Stripe4	dc.l	1
Stripe5	dc.l	1
Stripe6	dc.l	1
Stripe7	dc.l	1
Stripe8	dc.l	1

PatternInit
	lea	PatternInfo(PC),A0
	
	move	numOfVoices(pc),d0
	move	d0,PI_Voices(A0)	; Number of stripes (MUST be at least 4)
	lsl		#2,d0
	ext.l	d0 
	move.l	d0,PI_Modulo(a0)
	
	pea	ConvertNote(pc) 
	move.l	(sp)+,PI_Convert(a0)
	move.w	#64,PI_Pattlength(A0)	; Length of each stripe in rows
	clr.w	PI_Pattpos(A0)		; Current Position in Pattern (from 0)
	move	#-1,PI_Speed(a0)	; Magic! Indicates notes, not periods
	rts




FindBlock	MOVEM.L	D2/D3,-(SP)
.l	MOVEM.L	(A0)+,D2/D3
	ADD.L	D3,A0
	CMP.L	D2,D0
	BNE.S	.l
	SUB.L	D3,A0
	MOVE.L	D3,D0
	MOVEM.L	(SP)+,D2/D3
	RTS

* Called by the PI engine to get values for a particular row
ConvertNote
	moveq	#0,D0		; Period, Note
	moveq	#0,D1		; Sample number
	moveq	#0,D2		; Command 
	moveq	#0,D3		; Command argument

	* note index, 0 = no note
	move.b	(a0),D0
	move.b	1(a0),d1
	move.b	2(a0),d2
	move.b	3(a0),d3
	rts
	
init
	JMP	lbC00002C(pc)
music
	JMP	lbC00013A(pc)
end
	JMP	lbC000FBE(pc)

	JMP	lbC000F80(pc)

	JMP	lbC000FA4(pc)
vol
	JMP	lbC001006(pc)
balance
	JMP	lbC00101C(pc)

	dc.w	0


;	SECTION	absplay2rs00002C,CODE
lbC00002C	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.W	D0,-(SP)
	BSR.W	lbC000FB8
	ADDQ.W	#8,A0
	MOVE.L	A0,lbL000136
	MOVE.L	#$434D4F44,D0
	BSR.W	FindHunk
	LEA	lbL00013E(PC),A1
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	#$53414D50,D0
	BSR.W	FindHunk
	LEA	lbL0010D0,A1
	MOVE.W	#$47F,D0
lbC000064	MOVE.B	(A0)+,(A1)+
	DBRA	D0,lbC000064
	MOVE.L	#$53504545,D0
	BSR.W	FindHunk
	MOVE.W	(A0)+,lbW000146
	MOVE.L	#$534C454E,D0
	BSR.W	FindHunk
	MOVE.W	(A0)+,lbW00010A
	MOVE.L	#$504C454E,D0
	BSR.B	FindHunk
	MOVE.W	(A0)+,lbW000148
	MOVE.L	#$50415454,D0
	BSR.B	FindHunk
	LEA	lbL001550,A1
	MOVEQ	#$7F,D0
lbC0000AC	MOVE.B	(A0)+,(A1)+
	DBRA	D0,lbC0000AC
	LEA	lbL0015D0,A1
	MOVEQ	#0,D7
lbC0000BA	MOVE.L	#$50424F44,D0
	BSR.B	FindHunk
	MOVE.L	A0,(A1)+
	ADDQ.W	#1,D7
	CMP.W	lbW00010A(PC),D7
	BNE.S	lbC0000BA

	LEA	lbL0010E4,A5
	LEA	lbL0016D0,A1
	MOVEQ	#0,D7

lbC0000DC	TST.L	(A5)
	BEQ.S	lbC0000F0
	MOVE.L	#$53424F44,D0
	BSR.B	FindHunk	* ENFORCER HIT when d7=$22
	MOVE.L	A0,(A1)
	MOVE.L	D0,4(A1)
lbC0000F0	ADDQ.W	#8,A1
	LEA	$20(A5),A5
	ADDQ.W	#1,D7
	CMP.W	#$24,D7
	BNE.S	lbC0000DC
	MOVE.W	(SP)+,D0
	BSR.B	lbC00014C
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

lbW00010A	dc.w	0
	dc.w	0
	dc.w	0

FindHunk	MOVEM.L	D2/D3,-(SP)
	MOVE.L	lbL000136(PC),A0
lbC000118	MOVEM.L	(A0)+,D2/D3
	CMP.L	D2,D0
	BEQ.S	lbC000124
	ADD.L	D3,A0
	BRA.S	lbC000118

lbC000124	ADD.L	D3,A0
	MOVE.L	A0,lbL000136
	SUB.L	D3,A0
	MOVE.L	D3,D0
	MOVEM.L	(SP)+,D2/D3
	RTS

lbL000136	dc.l	0

lbC00013A	BRA.W	lbC000206

lbL00013E	dc.l	0
	dc.l	0
lbW000146	dc.w	0
maxPos
lbW000148	dc.w	0
	dc.w	0

lbC00014C	LEA	lbW0006C6(PC),A0
	TST.B	D0
	BEQ.S	lbC000158
	LEA	lbW00070A(PC),A0
lbC000158	MOVE.L	A0,lbL0006C2
	BSR.W	lbC000EC8
	MOVEQ	#0,D1
	LEA	lbL0017F0,A0
	MOVEQ	#15,D0
lbC00016C	MOVE.L	D1,(A0)+
	DBRA	D0,lbC00016C
	move.l	lbL001912(pc),A0
	move.l	lbL0021D2(pc),A1
	MOVE.W	#$22F,D0
lbC000182	MOVE.L	D1,(A0)+
	MOVE.L	D1,(A1)+
	DBRA	D0,lbC000182
	LEA	lbL00013E,A0
	MOVEQ	#0,D1
	MOVEQ	#3,D0
lbC000194	OR.W	(A0)+,D1
	ROR.W	#1,D1
	DBRA	D0,lbC000194
	ROR.W	#5,D1
	MOVE.W	D1,lbW000202
	LEA	$DFF000,A6
	* Disable DMA
	MOVE.W	#15,$96(A6)
	move.l	scopeAddr(pc),a1
	move.l	lbL0018C0(pc),A0
	MOVE.L	A0,$A0(A6)
	MOVE.L	A0,$B0(A6)
	MOVE.L	A0,$C0(A6)
	MOVE.L	A0,$D0(A6)
	move.l	a0,scope_ch1+ns_start(a1)
	move.l	a0,scope_ch2+ns_start(a1)
	move.l	a0,scope_ch3+ns_start(a1)
	move.l	a0,scope_ch4+ns_start(a1)
	move.l	a0,scope_ch1+ns_loopstart(a1)
	move.l	a0,scope_ch2+ns_loopstart(a1)
	move.l	a0,scope_ch3+ns_loopstart(a1)
	move.l	a0,scope_ch4+ns_loopstart(a1)
	MOVEQ	#$29,D0
	MOVE.W	D0,$A4(A6)
	MOVE.W	D0,$B4(A6)
	MOVE.W	D0,$C4(A6)
	MOVE.W	D0,$D4(A6)
	move	d0,scope_ch1+ns_length(a1)
	move	d0,scope_ch2+ns_length(a1)
	move	d0,scope_ch3+ns_length(a1)
	move	d0,scope_ch4+ns_length(a1)
	move	d0,scope_ch1+ns_replen(a1)
	move	d0,scope_ch2+ns_replen(a1)
	move	d0,scope_ch3+ns_replen(a1)
	move	d0,scope_ch4+ns_replen(a1)
	MOVE.W	#$358,D0
	MOVE.W	D0,$A6(A6)
	MOVE.W	D0,$B6(A6)
	MOVE.W	D0,$C6(A6)
	MOVE.W	D0,$D6(A6)
	move	d0,scope_ch1+ns_period(a1)
	move	d0,scope_ch2+ns_period(a1)
	move	d0,scope_ch3+ns_period(a1)
	move	d0,scope_ch4+ns_period(a1)
	MOVE.W	#$FF,$9E(A6)
	BSR.W	dmaWait
	BSR.W	dmaWait
	ST	lbB000204
	RTS

lbW000202	dc.w	0
lbB000204	dc.b	0
	dc.b	0

* Play
lbC000206	MOVE.B	lbB000204(PC),D0
	BEQ.S	lbC00021A
	MOVE.W	#$800F,$DFF096
	SF	lbB000204
lbC00021A	BSR.W	lbC00056A
	BSR.W	lbC000750
	LEA	lbW001850,A0
	LEA	lbL0006BA(PC),A2
	MOVE.L	(A2)+,A1
	MOVE.L	(A2),-(A2)
	MOVE.L	A1,4(A2)
	MOVEQ	#0,D0
lbC000236	TST.W	(A0)
	BEQ.S	lbC000246
	MOVEM.L	D0/A0-A2,-(SP)
	BSR.B	lbC00025C
	MOVEM.L	(SP)+,D0/A0-A2
lbC000246	LEA	$1C(A0),A0
	LEA	$230(A1),A1
	ADDQ.W	#1,D0
	CMP.W	#4,D0
	BNE.S	lbC000236
	BSR.W	lbC0005C6
	RTS

lbC00025C	TST.L	2(A0)
	BEQ.S	lbC000290
	TST.L	$10(A0)
	BEQ.S	lbC000294
	BSR.B	lbC00029C
	MOVE.W	D1,D2
	LEA	14(A0),A0
	BSR.B	lbC00029C
	CMP.W	D1,D2
	BLT.S	lbC000284
	MOVE.L	A1,A2
	LEA	-14(A0),A1
	BRA.B	lbC0002B6

lbC000284	MOVE.L	A1,A2
	LEA	-14(A0),A1
	EXG	A0,A1
	BRA.B	lbC0002B6

lbC000290	LEA	14(A0),A0
lbC000294	BSR.B	lbC00029C
	BRA.W	lbC0004E0

lbC00029C	MOVE.W	10(A0),D1
	BPL.S	lbC0002A8
	CLR.W	10(A0)
	RTS

lbC0002A8	CMP.W	#$21,D1
	BLE.S	lbC0002B4
	MOVE.W	#$21,10(A0)
lbC0002B4	RTS

lbC0002B6	LEA	lbL0017F0,A3
	LSL.W	#4,D0
	ADD.W	D0,A3
	MOVE.W	10(A1),D0
	ADD.W	D0,D0
	LEA	lbW00105A,A4
	MOVE.W	0(A4,D0.W),D2
	MOVE.W	D2,4(A3)
	MOVE.W	10(A0),D3
	ADD.W	D3,D3
	MOVE.W	0(A4,D3.W),D3
	MOVE.L	lbL0006C2(PC),A4
	MOVE.W	0(A4,D0.W),D1
	ADD.W	8(A3),D1
	MOVE.W	D1,6(A3)
	SWAP	D2
	CLR.W	D2
	DIVU	D3,D2
	MOVE.L	6(A0),D0
	LSR.L	#1,D0
	MOVE.L	A2,(A3)
	MOVEM.L	D0/A0/A1,-(SP)
	MOVE.L	2(A0),A0
	MOVE.L	A2,A1
	BSR.W	lbC0003EA
	MOVE.L	A0,A4
	MOVEM.L	(SP)+,D1/A0/A1
	SUB.W	D0,D1
	BHS.S	lbC000326
	CLR.L	2(A0)
	CLR.L	6(A0)
	CLR.W	10(A0)
	CLR.W	12(A0)
	BRA.S	lbC000330

lbC000326	MOVE.L	A4,2(A0)
	ADD.L	D1,D1
	MOVE.L	D1,6(A0)
lbC000330	MOVE.L	6(A1),D0
	LSR.L	#1,D0
	MOVE.W	6(A3),D1
	MOVEM.L	D0/D1/A1,-(SP)
	MOVE.L	2(A1),A0
	MOVE.L	A2,A1
	BSR.B	lbC000370
	MOVE.L	A0,A4
	MOVEM.L	(SP)+,D0/D1/A1
	SUB.W	D1,D0
	BHS.S	lbC000364
	CLR.L	2(A1)
	CLR.L	6(A1)
	CLR.W	10(A1)
	CLR.W	12(A1)
	RTS

lbC000364	MOVE.L	A4,2(A1)
	ADD.L	D0,D0
	MOVE.L	D0,6(A1)
	RTS

lbC000370	CMP.W	D0,D1
	BHI.S	lbC000376
	MOVE.W	D1,D0
lbC000376	BRA.S	lbC00037A

	NOP
lbC00037A	CMP.W	#$20,D0
	BLO.S	lbC0003C6
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	SUB.W	#$20,D0
	BRA.S	lbC00037A

lbC0003C6	CMP.W	#8,D0
	BLO.S	lbC0003E4
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	MOVE.L	(A0)+,D1
	ADD.L	D1,(A1)+
	SUBQ.W	#8,D0
	BRA.S	lbC0003C6

lbC0003E0	MOVE.W	(A0)+,D1
	ADD.W	D1,(A1)+
lbC0003E4	DBRA	D0,lbC0003E0
	RTS

lbC0003EA	TST.W	D2
	BNE.S	lbC0003F8
	MOVE.W	D1,-(SP)
	BSR.W	lbC000604
	MOVE.W	(SP)+,D0
	RTS

lbC0003F8	MOVE.L	D3,-(SP)
	MOVE.W	D2,D3
	MULU	D1,D3
	SWAP	D3
	CMP.W	D0,D3
	BHI.S	lbC00040C
	MOVE.W	D2,D0
	BSR.B	lbC00041A
	BRA.S	lbC000416

lbC00040C	MOVE.W	D0,-(SP)
	MOVE.W	D1,D0
	BSR.W	lbC000672
	MOVE.W	(SP)+,D0
lbC000416	MOVE.L	(SP)+,D3
	RTS

lbC00041A	MOVEM.L	D2-D5/A2,-(SP)
	MOVE.L	A0,A2
	MOVE.W	D1,D2
	MOVEQ	#0,D3
	SUBQ.W	#1,D1
lbC000426	SUBQ.W	#8,D2
	BMI.W	lbC0004B0
	SUB.W	D0,D3
	BHS.S	lbC000432
	MOVE.B	(A0)+,D5
lbC000432	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC00043A
	MOVE.B	(A0)+,D5
lbC00043A	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC000442
	MOVE.B	(A0)+,D5
lbC000442	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC00044A
	MOVE.B	(A0)+,D5
lbC00044A	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC000452
	MOVE.B	(A0)+,D5
lbC000452	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC00045A
	MOVE.B	(A0)+,D5
lbC00045A	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC000462
	MOVE.B	(A0)+,D5
lbC000462	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC00046A
	MOVE.B	(A0)+,D5
lbC00046A	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC000472
	MOVE.B	(A0)+,D5
lbC000472	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC00047A
	MOVE.B	(A0)+,D5
lbC00047A	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC000482
	MOVE.B	(A0)+,D5
lbC000482	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC00048A
	MOVE.B	(A0)+,D5
lbC00048A	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC000492
	MOVE.B	(A0)+,D5
lbC000492	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC00049A
	MOVE.B	(A0)+,D5
lbC00049A	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC0004A2
	MOVE.B	(A0)+,D5
lbC0004A2	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC0004AA
	MOVE.B	(A0)+,D5
lbC0004AA	MOVE.B	D5,(A1)+
	BRA.W	lbC000426

lbC0004B0	ADDQ.W	#8,D2
	BRA.S	lbC0004C4

lbC0004B4	SUB.W	D0,D3
	BHS.S	lbC0004BA
	MOVE.B	(A0)+,D5
lbC0004BA	MOVE.B	D5,(A1)+
	SUB.W	D0,D3
	BHS.S	lbC0004C2
	MOVE.B	(A0)+,D5
lbC0004C2	MOVE.B	D5,(A1)+
lbC0004C4	DBRA	D2,lbC0004B4
	SUB.L	A0,A2
	MOVE.W	A2,D0
	NEG.W	D0
	BTST	#0,D0
	BEQ.S	lbC0004D8
	ADDQ.W	#1,A0
	ADDQ.W	#1,D0
lbC0004D8	LSR.W	#1,D0
	MOVEM.L	(SP)+,D2-D5/A2
	RTS

lbC0004E0	LEA	lbL0017F0,A2
	LSL.W	#4,D0
	ADD.W	D0,A2
	TST.L	2(A0)
	BEQ.S	lbC00054E
	MOVE.W	10(A0),D0
	ADD.W	D0,D0
	LEA	lbW00105A,A3
	MOVE.W	0(A3,D0.W),4(A2)
	MOVE.L	lbL0006C2(PC),A3
	MOVE.W	0(A3,D0.W),D1
	ADD.W	8(A2),D1
	MOVE.W	D1,6(A2)
	MOVE.L	6(A0),D0
	LSR.L	#1,D0
	MOVE.L	A1,(A2)
	MOVEM.L	D0/D1/A0,-(SP)
	MOVE.L	2(A0),A0
	BSR.W	lbC000604
	MOVE.L	A0,A1
	MOVEM.L	(SP)+,D0/D1/A0
	SUB.W	D1,D0
	BHS.S	lbC000542
	CLR.L	2(A0)
	CLR.L	6(A0)
	CLR.W	10(A0)
	CLR.W	12(A0)
	RTS

lbC000542	MOVE.L	A1,2(A0)
	ADD.L	D0,D0
	MOVE.L	D0,6(A0)
	RTS

lbC00054E	MOVE.L	A1,(A2)
	MOVE.W	lbW00105A,4(A2)
	MOVE.L	lbL0006C2(PC),A0
	MOVE.W	(A0),D0
	ADD.W	8(A2),D0
	MOVE.W	D0,6(A2)
	BRA.W	lbC000672

lbC00056A	MOVEM.L	D2/D3/A2,-(SP)
	LEA	lbL0017F0,A0
	LEA	$DFF01E,A2
	; $DFF0A6
	LEA	$88(A2),A1
	MOVEQ	#3,D0
lbC000580	MOVE.W	4(A0),D1
	BEQ.S	lbC00058C
	MOVE.W	D1,(A1)
	MOVE.W	(A2),10(A0)
	bsr		setPerB
lbC00058C	LEA	$10(A0),A0
	LEA	$10(A1),A1
	DBRA	D0,lbC000580
	LEA	lbL0017F0,A0
	MOVEQ	#7,D1
lbC0005A0	TST.L	(A0)
	BEQ.S	lbC0005B4
	CLR.W	8(A0)
	MOVE.W	10(A0),D0
	BTST	D1,D0
	BEQ.S	lbC0005B4
	ADDQ.W	#1,8(A0)
lbC0005B4	LEA	$10(A0),A0
	ADDQ.W	#1,D1
	CMP.W	#11,D1
	BNE.S	lbC0005A0
	MOVEM.L	(SP)+,D2/D3/A2
	RTS

* 8 channel buffer switch magic
lbC0005C6	MOVE.W	lbW000202(PC),D1
lbC0005CA	
	MOVE.W	$DFF01E,D0
	AND.W	D1,D0
	CMP.W	D1,D0
	BNE.S	lbC0005CA
	MOVE.W	D1,$DFF09C
	LEA	lbL0017F0,A0
	LEA	$DFF0A0,A1
	MOVEQ	#3,D0
	; loopstart?
lbC0005EA	MOVE.L	(A0),D1
	BEQ.S	lbC0005F6
	MOVE.L	D1,(A1)
	MOVE.W	6(A0),4(A1)
	;move	6(a0),$104
	bsr	setRep
	;move	#$f00,$dff180
lbC0005F6	LEA	$10(A0),A0
	LEA	$10(A1),A1
	DBRA	D0,lbC0005EA
	RTS

lbC000604	MOVEM.L	D2/A2,-(SP)
	MOVE.W	D1,D2
	CMP.W	D0,D2
	BHI.S	lbC000616
	MOVE.W	D2,D0
	BSR.B	lbC00062C
	BRA.S	lbC000626

lbC000616	SUB.W	D0,D2
	BSR.B	lbC00062C
	MOVE.L	A0,A2
	MOVE.W	D2,D0
	BSR.B	lbC000672
	MOVE.L	A2,A0
lbC000626	MOVEM.L	(SP)+,D2/A2
	RTS

lbC00062C	CMP.W	#$20,D0
	BLO.S	lbC000658
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	SUB.W	#$20,D0
	BRA.S	lbC00062C

lbC000658	CMP.W	#8,D0
	BLO.S	lbC00066C
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	SUBQ.W	#8,D0
	BRA.S	lbC000658

lbC00066A	MOVE.W	(A0)+,(A1)+
lbC00066C	DBRA	D0,lbC00066A
	RTS

lbC000672	MOVEQ	#0,D1
lbC000674	CMP.W	#$20,D0
	BLO.S	lbC0006A0
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	SUB.W	#$20,D0
	BRA.S	lbC000674

lbC0006A0	CMP.W	#8,D0
	BLO.S	lbC0006B4
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	MOVE.L	D1,(A1)+
	SUBQ.W	#8,D0
	BRA.S	lbC0006A0

lbC0006B2	MOVE.W	D1,(A1)+
lbC0006B4	DBRA	D0,lbC0006B2
	RTS

lbL0006BA	dc.l	0 ;lbL001912
	dc.l	0 ;lbL0021D2
lbL0006C2	dc.l	0
lbW0006C6	dc.w	$29
	dc.w	$2B
	dc.w	$2E
	dc.w	$31
	dc.w	$34
	dc.w	$37
	dc.w	$3A
	dc.w	$3E
	dc.w	$42
	dc.w	$45
	dc.w	$4A
	dc.w	$4E
	dc.w	$53
	dc.w	$57
	dc.w	$5D
	dc.w	$62
	dc.w	$68
	dc.w	$6F
	dc.w	$75
	dc.w	$7C
	dc.w	$84
	dc.w	$8B
	dc.w	$94
	dc.w	$9D
	dc.w	$A6
	dc.w	$AF
	dc.w	$BA
	dc.w	$C5
	dc.w	$D0
	dc.w	$DE
	dc.w	$EB
	dc.w	$F8
	dc.w	$107
	dc.w	$117
lbW00070A	dc.w	$22
	dc.w	$25
	dc.w	$27
	dc.w	$29
	dc.w	$2C
	dc.w	$2E
	dc.w	$31
	dc.w	$34
	dc.w	$37
	dc.w	$3A
	dc.w	$3E
	dc.w	$42
	dc.w	$45
	dc.w	$4A
	dc.w	$4E
	dc.w	$53
	dc.w	$58
	dc.w	$5D
	dc.w	$63
	dc.w	$68
	dc.w	$6F
	dc.w	$75
	dc.w	$7C
	dc.w	$84
	dc.w	$8B
	dc.w	$94
	dc.w	$9D
	dc.w	$A6
	dc.w	$AF
	dc.w	$BA
	dc.w	$C6
	dc.w	$D1
	dc.w	$DD
	dc.w	$EB
	dc.w	0

lbC000750	BSR.W	lbC00095E
	ADDQ.W	#1,lbW0010A4
	MOVE.W	lbW0010AE(PC),D0
	CMP.W	lbW0010A4(PC),D0
	BGT.S	lbC00076C
	BSR.W	lbC000814
	BSR.W	lbC0008E8
lbC00076C	LEA	lbL001832,A2
	LEA	lbW001850,A5
	MOVEQ	#7,D7
lbC00077A	TST.B	(A5)
	BNE.S	lbC00078C
	ADDQ.W	#4,A2
	LEA	$1C(A5),A5
	SUBQ.W	#1,D7
	DBRA	D7,lbC00077A
	RTS

lbC00078C	MOVEQ	#0,D0
	MOVE.B	(A2),D0
	ADD.W	D0,D0
	MOVE.W	lbW0007CC(PC,D0.W),D0
	BEQ.S	lbC0007A2
	MOVEQ	#0,D1
	MOVE.B	1(A2),D1
	JSR	lbW0007CC(PC,D0.W)
lbC0007A2	ADDQ.W	#4,A2
	LEA	14(A5),A5
	SUBQ.W	#1,D7
	MOVEQ	#0,D0
	MOVE.B	(A2),D0
	ADD.W	D0,D0
	MOVE.W	lbW0007CC(PC,D0.W),D0
	BEQ.S	lbC0007C0
	MOVEQ	#0,D1
	MOVE.B	1(A2),D1
	JSR	lbW0007CC(PC,D0.W)
lbC0007C0	ADDQ.W	#4,A2
	LEA	14(A5),A5
	DBRA	D7,lbC00077A
	RTS

lbW0007CC	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbC000D20-lbW0007CC
	dc.w	lbC000D62-lbW0007CC
	dc.w	lbC000D98-lbW0007CC
	dc.w	lbC000DF4-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbC000E36-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbC000DDA-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbC000DEC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbC000DFE-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbC000E20-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbC000DE2-lbW0007CC
	dc.w	lbC000E46-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC
	dc.w	lbW0007CC-lbW0007CC

lbC000814	CLR.W	lbW0010A4
	MOVE.L	patternAddr(PC),A1
	ADD.W	lbW0010AA(PC),A1
	MOVE.L	A1,patternAddr
	ADDQ.W	#1,okta_PattPos
	BSR.B	lbC0008A2
	TST.W	lbW0010B0
	BPL.S	lbC000840
	CMP.W	okta_PattPos(PC),D0
	BGT.S	lbC000888
lbC000840	CLR.W	okta_PattPos
	MULU	lbW0010AA(PC),D0
	SUB.L	D0,patternAddr
	TST.W	lbW0010B0
	BMI.S	lbC000862
	MOVE.W	lbW0010B0(PC),lbW0010B2
	BRA.S	lbC000868

NextSongPos
lbC000862	
	ADDQ.W	#1,lbW0010B2	* cur pos
lbC000868	MOVE.W	lbW0010B2(PC),D0
	CMP.W	lbW000148(pc),D0	* max pos
	BNE.S	lbC000884
	; SONGEND HERE
	move.l	songEndAddr(pc),a0 
	st (a0)
	CLR.W	lbW0010B2
	MOVE.W	lbW000146(pc),lbW0010AE
lbC000884	BSR.B	lbC0008B4
lbC000888	MOVE.L	patternAddr(PC),A0
	MOVEM.L	(A0),D0-D7
	MOVEM.L	D0-D7,lbW001830
	MOVE.W	#$FFFF,lbW0010B0

	push	a0
	lea		PatternInfo(pc),a0
	move	okta_PattPos(pc),PI_Pattpos(a0)
	pop 	a0
	RTS

lbC0008A2	MOVE.W	lbW0010B2(PC),D0
	LEA	lbL001550,A0
	MOVE.B	0(A0,D0.W),D0
	BRA.B	lbC0008D6

lbC0008B4	LEA	lbL001550,A0
	MOVE.W	lbW0010B2(PC),D2
	MOVEQ	#0,D0
	MOVE.B	0(A0,D2.W),D0

	LEA	PatternInfo(PC),A0
	MOVE.W	D0,PI_Pattern(A0)
	BSR.B	lbC0008D6
	MOVE.L	A0,patternAddr
	CLR.W	okta_PattPos

	MOVEM.L	D0/A0/A1,-(SP)
	LEA	PatternInfo(PC),A1
	MOVE.W	D0,PI_Pattlength(A1)	
	LEA		PI_Stripes(A1),A1	
	MOVEQ	#8-1,D0
.s	MOVE.L	A0,(A1)+
	ADDQ.L	#4,A0
	DBRA	D0,.s
	MOVEM.L	(SP)+,D0/A0/A1
	RTS

lbC0008D6	LEA	lbL0015D0,A0
	ADD.W	D0,D0
	ADD.W	D0,D0
	MOVE.L	0(A0,D0.W),A0
	MOVE.W	(A0)+,D0
	RTS

lbC0008E8	LEA	lbL0016D0,A0
	LEA	lbL0010D0,A1
	LEA	lbW001830,A2
	LEA	lbW001850,A3
	MOVEQ	#7,D7
lbC000902	TST.B	(A3)
	BNE.S	lbC000914
	ADDQ.W	#4,A2
	LEA	$1C(A3),A3
	SUBQ.W	#1,D7
	DBRA	D7,lbC000902
	RTS

lbC000914	BSR.S	lbC000920
	SUBQ.W	#1,D7
	BSR.S	lbC000920
	DBRA	D7,lbC000902
	RTS

lbC000920	MOVEQ	#0,D3
	MOVE.B	(A2),D3
	BEQ.B	lbC000956
	SUBQ.W	#1,D3
	MOVEQ	#0,D0
	MOVE.B	1(A2),D0
	LSL.W	#3,D0
	MOVE.L	0(A0,D0.W),D2
	BEQ.S	lbC000956
	ADD.W	D0,D0
	ADD.W	D0,D0
	CMP.W	#1,$1E(A1,D0.W)
	BEQ.S	lbC000956
	MOVE.L	D2,2(A3)
	MOVE.L	$14(A1,D0.W),6(A3)
	MOVE.W	D3,10(A3)
	MOVE.W	D3,12(A3)
lbC000956	ADDQ.W	#4,A2
	LEA	14(A3),A3
	RTS

lbC00095E	BSR.W	lbC000AE6
	MOVE.W	lbW0010A4(PC),D0
	BNE.S	lbC000972
	BSR.W	lbC0009EE
	OR.W	D4,lbW0010C6
lbC000972	BSR.W	lbC000B58
	MOVE.B	lbB0010CA(PC),D1
	MOVE.W	lbW0010CC(PC),D2
	MOVE.W	lbW0010CE(PC),D3
	LEA	lbL0010BC(PC),A0
	MOVE.L	(A0)+,(A0)
	LEA	$DFF0A8,A1
	MOVEQ	#0,D0
	BTST	#0,D1
	BNE.S	lbC00099E
	MOVE.B	(A0),D0
	MULU	D3,D0
	LSR.W	#6,D0
	MOVE.W	D0,(A1)
	bsr		setVol1
lbC00099E	BTST	#1,D1
	BNE.S	lbC0009B0
	MOVE.B	1(A0),D0
	MULU	D2,D0
	LSR.W	#6,D0
	MOVE.W	D0,$10(A1)
	bsr		setVol2
lbC0009B0	BTST	#2,D1
	BNE.S	lbC0009C2
	MOVE.B	2(A0),D0
	MULU	D2,D0
	LSR.W	#6,D0
	MOVE.W	D0,$20(A1)
	bsr		setVol3
lbC0009C2	BTST	#3,D1
	BNE.S	lbC0009D4
	MOVE.B	3(A0),D0
	MULU	D3,D0
	LSR.W	#6,D0
	MOVE.W	D0,$30(A1)
	bsr		setVol4
lbC0009D4	MOVE.B	lbB0010C4(PC),D0
	BEQ.S	lbC0009E4
	BCLR	#1,$BFE001
	RTS

lbC0009E4	BSET	#1,$BFE001
	RTS

lbC0009EE	LEA	lbL0016D0,A0
	LEA	lbW001830,A2
	LEA	lbW001850,A3
	LEA	$DFF0A0,A4
	LEA	lbW00105A(PC),A6
	MOVEQ	#0,D4
	MOVEQ	#1,D5
	MOVEQ	#7,D7
lbC000A10	TST.B	(A3)
	BNE.S	lbC000A2A
	BSR.S	lbC000A3E
	ADDQ.W	#4,A2
	LEA	$1C(A3),A3
	LEA	$10(A4),A4
	ADD.W	D5,D5
	SUBQ.W	#1,D7
	DBRA	D7,lbC000A10
	RTS

lbC000A2A	ADDQ.W	#8,A2
	LEA	$1C(A3),A3
	LEA	$10(A4),A4
	ADD.W	D5,D5
	SUBQ.W	#1,D7
	DBRA	D7,lbC000A10
	RTS

lbC000A3E	MOVE.B	D5,D3
	AND.B	lbB0010CA(PC),D3
	BNE	lbC000ACA
	MOVEQ	#0,D3
	MOVE.B	(A2),D3
	BEQ	lbC000ACA
	SUBQ.W	#1,D3
	MOVEQ	#0,D0
	MOVE.B	1(A2),D0
	LSL.W	#3,D0
	MOVE.L	0(A0,D0.W),D2
	BEQ		lbC000ACA
	ADD.W	D0,D0
	ADD.W	D0,D0
	LEA	lbL0010D0,A1
	ADD.W	D0,A1
	TST.W	$1E(A1)
	BEQ	lbC000ACA
	MOVE.L	$14(A1),D1
	LSR.L	#1,D1
	TST.W	D1
	BEQ	lbC000ACA
	* DMA off
	MOVE.W	D5,$DFF096
	OR.W	D5,D4
	* sample start?
	MOVE.L	D2,(A4)
	bsr		setAddr
	MOVE.W	D3,8(A3)
	ADD.W	D3,D3
	MOVE.W	0(A6,D3.W),D0
	MOVE.W	D0,10(A3)
	MOVE.W	D0,6(A4)
	bsr		setPer
	MOVE.L	A0,-(SP)
	LEA	lbL0010BC(PC),A0
	MOVEQ	#0,D0
	MOVE.B	-8(A0,D7.W),D0
	MOVE.B	$1D(A1),0(A0,D0.W)
	MOVE.L	(SP)+,A0
	MOVE.W	$1A(A1),D0
	BNE.S	lbC000ACC
	MOVE.W	D1,4(A4)
	bsr		setLen
		
	MOVE.L	lbL002A94(pc),2(A3)
	MOVE.W	#1,6(A3)
lbC000ACA	RTS

lbC000ACC	MOVE.W	D0,6(A3)
	MOVEQ	#0,D1
	MOVE.W	$18(A1),D1
	ADD.W	D1,D0
	MOVE.W	D0,4(A4)
	bsr		setLenB
	ADD.L	D1,D1
	ADD.L	D2,D1
	MOVE.L	D1,2(A3)
	RTS

lbC000AE6	LEA	lbW0010C6(PC),A0
	MOVE.W	(A0),D0
	BEQ.W	lbC000B56
	CLR.W	(A0)
	OR.W	#$8000,D0
	LEA	$DFF006,A0
	* Enable DMA
	MOVE.W	D0,$90(A0)
	MOVE.B	(A0),D1
lbC000B00	CMP.B	(A0),D1
	BEQ.S	lbC000B00
	MOVE.B	(A0),D1
lbC000B06	CMP.B	(A0),D1
	BEQ.S	lbC000B06
	LEA	lbL001852,A1
	BTST	#0,D0
	BEQ.S	lbC000B20
	MOVE.L	(A1),$9A(A0)
	MOVE.W	4(A1),$9E(A0)
	bsr		setRepLen1
lbC000B20	BTST	#1,D0
	BEQ.S	lbC000B32
	MOVE.L	$1C(A1),$AA(A0)
	MOVE.W	$20(A1),$AE(A0)
	bsr		setRepLen2
lbC000B32	BTST	#2,D0
	BEQ.S	lbC000B44
	MOVE.L	$38(A1),$BA(A0)
	MOVE.W	$3C(A1),$BE(A0)
	bsr		setRepLen3
lbC000B44	BTST	#3,D0
	BEQ.S	lbC000B56
	MOVE.L	$54(A1),$CA(A0)
	MOVE.W	$58(A1),$CE(A0)
	bsr		setRepLen4
lbC000B56	RTS

lbC000B58	LEA	lbW001830,A2
	LEA	lbW001850,A3	* patterndata?
	LEA	$DFF0A0,A4
	LEA	lbW00105A(PC),A6
	MOVEQ	#1,D5
	MOVEQ	#7,D7
lbC000B72	TST.B	(A3)
	BNE.S	lbC000B8C
	BSR.S	lbC000BA0
	ADDQ.W	#4,A2
	LEA	$1C(A3),A3	* next row?
	LEA	$10(A4),A4	* next chan data?
	ADD.W	D5,D5
	SUBQ.W	#1,D7
	DBRA	D7,lbC000B72
	RTS

lbC000B8C	ADDQ.W	#8,A2
	LEA	$1C(A3),A3
	LEA	$10(A4),A4
	ADD.W	D5,D5
	SUBQ.W	#1,D7
	DBRA	D7,lbC000B72
	RTS

lbC000BA0	MOVEQ	#0,D0
	MOVE.B	2(A2),D0
	ADD.W	D0,D0
	MOVEQ	#0,D1
	MOVE.B	3(A2),D1
	MOVE.W	lbW000BB8(PC,D0.W),D0
	JMP	lbW000BB8(PC,D0.W)

lbC000BB6	RTS

lbW000BB8	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000C1A-lbW000BB8
	dc.w	lbC000C00-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000C34-lbW000BB8
	dc.w	lbC000C70-lbW000BB8
	dc.w	lbC000C9E-lbW000BB8
	dc.w	lbC000CF4-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000E36-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000CD8-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000CEC-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000EAC-lbW000BB8
	dc.w	lbC000DFE-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000E20-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000CE0-lbW000BB8
	dc.w	lbC000E46-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8
	dc.w	lbC000BB6-lbW000BB8

lbC000C00	ADD.W	D1,10(A3)
	CMP.W	#$358,10(A3)
	BLE.S	lbC000C12
	MOVE.W	#$358,10(A3)
lbC000C12	
	MOVE.W	10(A3),6(A4)
	bsr		setPerC
	RTS

lbC000C1A	SUB.W	D1,10(A3)
	CMP.W	#$71,10(A3)
	BGE.S	lbC000C2C
	MOVE.W	#$71,10(A3)
lbC000C2C	
	MOVE.W	10(A3),6(A4)
	bsr		setPerC
	RTS

lbC000C34	MOVE.W	8(A3),D2
	MOVE.W	lbW0010A4(PC),D0
	MOVE.B	lbB000C60(PC,D0.W),D0
	BNE.S	lbC000C4E
	AND.W	#$F0,D1
	LSR.W	#4,D1
	SUB.W	D1,D2
	BRA.W	lbC000D02

lbC000C4E	SUBQ.B	#1,D0
	BNE.S	lbC000C56
	BRA.W	lbC000D02

lbC000C56	AND.W	#15,D1
	ADD.W	D1,D2
	BRA.W	lbC000D02

lbB000C60	dc.b	0
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

lbC000C70	MOVE.W	8(A3),D2
	MOVE.W	lbW0010A4(PC),D0
	AND.W	#3,D0
	BNE.S	lbC000C82
	BRA.B	lbC000D02

lbC000C82	SUBQ.B	#1,D0
	BNE.S	lbC000C8E
	AND.W	#15,D1
	ADD.W	D1,D2
	BRA.S	lbC000D02

lbC000C8E	SUBQ.B	#1,D0
	BEQ.S	lbC000D02
	AND.W	#$F0,D1
	LSR.W	#4,D1
	SUB.W	D1,D2
	BRA.B	lbC000D02

lbC000C9E	MOVE.W	8(A3),D2
	MOVE.W	lbW0010A4(PC),D0
	MOVE.B	lbB000CC8(PC,D0.W),D0
	BNE.S	lbC000CAE
	RTS

lbC000CAE	SUBQ.B	#1,D0
	BNE.S	lbC000CBC
	AND.W	#$F0,D1
	LSR.W	#4,D1
	ADD.W	D1,D2
	BRA.S	lbC000D02

lbC000CBC	SUBQ.B	#1,D0
	BNE.S	lbC000CC6
	AND.W	#15,D1
	ADD.W	D1,D2
lbC000CC6	BRA.S	lbC000D02

lbB000CC8	dc.b	0
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

lbC000CD8	MOVE.W	lbW0010A4(PC),D0
	BEQ.S	lbC000CE0
	RTS

lbC000CE0	MOVE.W	8(A3),D2
	ADD.W	D1,D2
	MOVE.W	D2,8(A3)
	BRA.S	lbC000D02

lbC000CEC	MOVE.W	lbW0010A4(PC),D0
	BEQ.S	lbC000CF4
	RTS

lbC000CF4	MOVE.W	8(A3),D2
	SUB.W	D1,D2
	MOVE.W	D2,8(A3)
	BRA.S	lbC000D02

	NOP
lbC000D02	TST.W	D2
	BPL.S	lbC000D08
	MOVEQ	#0,D2
lbC000D08	CMP.W	#$23,D2
	BLE.S	lbC000D10
	MOVEQ	#$23,D2
lbC000D10	ADD.W	D2,D2
	MOVE.W	0(A6,D2.W),D0
	MOVE.W	D0,6(A4)
	;setPer
	MOVE.W	D0,10(A3)
	RTS

lbC000D20	MOVE.W	12(A5),D2
	MOVE.W	lbW0010A4(PC),D0
	MOVE.B	lbB000D52(PC,D0.W),D0
	BNE.S	lbC000D3C
	AND.W	#$F0,D1
	LSR.W	#4,D1
	SUB.W	D1,D2
	MOVE.W	D2,10(A5)
	RTS

lbC000D3C	SUBQ.B	#1,D0
	BNE.S	lbC000D46
	MOVE.W	D2,10(A5)
	RTS

lbC000D46	AND.W	#15,D1
	ADD.W	D1,D2
	MOVE.W	D2,10(A5)
	RTS

lbB000D52	dc.b	0
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

lbC000D62	MOVE.W	12(A5),D2
	MOVE.W	lbW0010A4(PC),D0
	AND.W	#3,D0
	BNE.S	lbC000D76
lbC000D70	MOVE.W	D2,10(A5)
	RTS

lbC000D76	SUBQ.B	#1,D0
	BNE.S	lbC000D86
	AND.W	#15,D1
	ADD.W	D1,D2
	MOVE.W	D2,10(A5)
	RTS

lbC000D86	SUBQ.B	#1,D0
	BEQ.S	lbC000D70
	AND.W	#$F0,D1
	LSR.W	#4,D1
	SUB.W	D1,D2
	MOVE.W	D2,10(A5)
	RTS

lbC000D98	MOVE.W	12(A5),D2
	MOVE.W	lbW0010A4(PC),D0
	MOVE.B	lbB000DCA(PC,D0.W),D0
	BNE.S	lbC000DA8
	RTS

lbC000DA8	SUBQ.B	#1,D0
	BNE.S	lbC000DBA
	AND.W	#$F0,D1
	LSR.W	#4,D1
	ADD.W	D1,D2
	MOVE.W	D2,10(A5)
	RTS

lbC000DBA	SUBQ.B	#1,D0
	BNE.S	lbC000DC4
	AND.W	#15,D1
	ADD.W	D1,D2
lbC000DC4	MOVE.W	D2,10(A5)
	RTS

lbB000DCA	dc.b	0
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

lbC000DDA	MOVE.W	lbW0010A4(PC),D0
	BEQ.S	lbC000DE2
	RTS

lbC000DE2	ADD.W	D1,12(A5)
	ADD.W	D1,10(A5)
	RTS

lbC000DEC	MOVE.W	lbW0010A4(PC),D0
	BEQ.S	lbC000DF4
	RTS

lbC000DF4	SUB.W	D1,12(A5)
	SUB.W	D1,10(A5)
	RTS

lbC000DFE	MOVE.W	lbW0010A4(PC),D0
	BNE.S	lbC000E1E
	MOVE.W	D1,D0
	AND.W	#15,D0
	LSR.W	#4,D1
	MULU	#10,D1
	ADD.W	D1,D0
	CMP.W	lbW000148(PC),D0
	BHS.S	lbC000E1E
	MOVE.W	D0,lbW0010B0
lbC000E1E	RTS

lbC000E20	MOVE.W	lbW0010A4(PC),D0
	BNE.S	lbC000E34
	AND.W	#15,D1
	TST.B	D1
	BEQ.S	lbC000E34
	MOVE.W	D1,lbW0010AE
lbC000E34	RTS

lbC000E36	MOVE.W	lbW0010A4(PC),D0
	BNE.S	lbC000E44
	TST.B	D1
	SNE	lbB0010C4
lbC000E44	RTS

lbC000E46	MOVE.L	A0,-(SP)
	MOVEQ	#0,D0
	LEA	lbL0010BC(PC),A0
	MOVE.B	-8(A0,D7.W),D0
	ADD.W	D0,A0
	CMP.W	#$40,D1
	BGT.S	lbC000E60
	MOVE.B	D1,(A0)
lbC000E5C	MOVE.L	(SP)+,A0
	RTS

lbC000E60	SUB.B	#$40,D1
	CMP.B	#$10,D1
	BLT.S	lbC000E90
	SUB.B	#$10,D1
	CMP.B	#$10,D1
	BLT.S	lbC000E9E
	SUB.B	#$10,D1
	CMP.B	#$10,D1
	BLT.S	lbC000E8A
	SUB.B	#$10,D1
	CMP.B	#$10,D1
	BLT.S	lbC000E98
	BRA.S	lbC000E5C

lbC000E8A	MOVE.W	lbW0010A4(PC),D0
	BNE.S	lbC000E5C
lbC000E90	SUB.B	D1,(A0)
	BPL.S	lbC000E5C
	SF	(A0)
	BRA.S	lbC000E5C

lbC000E98	MOVE.W	lbW0010A4(PC),D0
	BNE.S	lbC000E5C
lbC000E9E	ADD.B	D1,(A0)
	CMP.B	#$40,(A0)
	BLS.S	lbC000E5C
	MOVE.B	#$40,(A0)
	BRA.S	lbC000E5C

lbC000EAC	MOVE.L	A0,-(SP)
	MOVEQ	#0,D0
	LEA	lbL0010BC(PC),A0
	MOVE.B	-8(A0,D7.W),D0
	ADD.W	D0,A0
	MOVE.B	4(A0),(A0)
	CMP.B	#$40,D1
	BHI.S	lbC000E60
	MOVE.L	(SP)+,A0
	RTS

lbC000EC8	CLR.W	lbW0010C8
	CLR.W	lbW0010B2
	SF	lbB0010CA
	LEA	lbW001850,A0
	MOVE.W	#$6F,D0
lbC000EE4	SF	(A0)+
	DBRA	D0,lbC000EE4
	LEA	lbL00013E,A0
	LEA	lbW001850,A1
	MOVEQ	#3,D0
	MOVEQ	#0,D1
lbC000EFA	TST.W	(A0)
	SNE	(A1)
	SNE	14(A1)
	ADD.W	(A0)+,D1
	LEA	$1C(A1),A1
	DBRA	D0,lbC000EFA
	ADDQ.W	#4,D1
	ADD.W	D1,D1
	ADD.W	D1,D1
	MOVE.W	D1,lbW0010AA
	LEA	lbW001830,A0
	MOVEQ	#0,D1
	MOVEQ	#7,D0
lbC000F22	MOVE.L	D1,(A0)+
	DBRA	D0,lbC000F22
	LEA	lbL0010B4(PC),A0
	MOVE.L	#$3030202,(A0)+
	MOVE.L	#$1010000,(A0)+
	MOVE.L	#$40404040,D0
	MOVE.L	D0,(A0)+
	MOVE.L	D0,(A0)+
	BSR.W	lbC0008B4
	SUBQ.W	#1,okta_PattPos
	MOVE.W	#$FFFF,lbW0010B0
	MOVE.L	patternAddr(PC),A0
	SUB.W	lbW0010AA(PC),A0
	MOVE.L	A0,patternAddr
	MOVE.W	lbW000146,lbW0010AE
	CLR.W	lbW0010A4
	CLR.W	lbB0010C4
	CLR.W	lbW0010C6
	RTS

lbC000F80	AND.W	#3,D0
	MOVE.W	D0,D1
	LEA	lbW001850,A0
	MULU	#$1C,D1
	TST.B	0(A0,D1.W)
	BNE.S	lbC000FA0
	BSET	D0,lbB0010CA
	MOVEQ	#1,D0
	RTS

lbC000FA0	MOVEQ	#0,D0
	RTS

lbC000FA4	AND.W	#3,D0
	BCLR	D0,lbB0010CA
	BEQ.S	lbC000FB4
	MOVEQ	#1,D0
	RTS

lbC000FB4	MOVEQ	#0,D0
	RTS

lbC000FB8	SF	lbB0010CA
lbC000FBE	MOVEM.L	D0/D1/A6,-(SP)
	LEA	$DFF000,A6
	MOVE.B	lbB0010CA(PC),D1
	MOVE.W	#15,D0
	EOR.B	D1,D0
	* Enable DMA
	MOVE.W	D0,$96(A6)
	* Zero volume
	MOVEQ	#0,D0
	BTST	#0,D1
	BNE.S	lbC000FE2
	MOVE.W	D0,$A8(A6)
	bsr		setVol1
lbC000FE2	BTST	#1,D1
	BNE.S	lbC000FEC
	MOVE.W	D0,$B8(A6)
	bsr		setVol2
lbC000FEC	BTST	#2,D1
	BNE.S	lbC000FF6
	MOVE.W	D0,$C8(A6)
	bsr		setVol3
lbC000FF6	BTST	#3,D1
	BNE.S	lbC001000
	MOVE.W	D0,$D8(A6)
	bsr		setVol4
lbC001000	MOVEM.L	(SP)+,D0/D1/A6
	RTS

lbC001006	CMP.W	#$40,D0
	BLS.S	lbC00100E
	MOVEQ	#$40,D0
lbC00100E	MOVE.W	D0,lbW0010CC
	MOVE.W	D0,lbW0010CE
	RTS

lbC00101C	CMP.W	#$40,D0
	BLS.S	lbC001024
	MOVEQ	#$40,D0
lbC001024	CMP.W	#$40,D1
	BLS.S	lbC00102C
	MOVEQ	#$40,D1
lbC00102C	MOVE.W	D0,lbW0010CC
	MOVE.W	D1,lbW0010CE
	RTS

dmaWait	MOVEM.L	D0/D1,-(SP)
	MOVEQ	#4,D1
lbC001040	MOVE.B	$DFF006,D0
lbC001046	CMP.B	$DFF006,D0
	BEQ.S	lbC001046
	DBRA	D1,lbC001040
	MOVEM.L	(SP)+,D0/D1
	RTS

	dc.w	0
lbW00105A	dc.w	$358
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
	dc.w	$1C5
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
	dc.w	0
lbW0010A4	dc.w	0
patternAddr	dc.l	0
lbW0010AA	dc.w	0
okta_PattPos	dc.w	0
lbW0010AE	dc.w	0
lbW0010B0	dc.w	0
curPos
lbW0010B2	dc.w	0
lbL0010B4	dc.l	0
	dc.l	0
lbL0010BC	dc.l	0
	dc.l	0
lbB0010C4	dc.b	0
	dc.b	0
lbW0010C6	dc.w	0
lbW0010C8	dc.w	0
lbB0010CA	dc.b	0
	dc.b	0
lbW0010CC	dc.w	$40
lbW0010CE	dc.w	$40

;	SECTION	absplay2rs0010D0,BSS
lbL0010D0	ds.l	5
lbL0010E4	ds.l	$11B
lbL001550	ds.l	$20
lbL0015D0	ds.l	$40
lbL0016D0	ds.l	$48
lbL0017F0	ds.l	$10
lbW001830	ds.w	1
lbL001832	ds.l	7
	ds.w	1
lbW001850	ds.w	1
lbL001852	ds.l	$1B
	ds.w	1

;	SECTION	absplay2rs0018C0,BSS_c
;
;lbL0018C0	ds.l	$14
;	ds.w	1
;lbL001912	ds.l	$230
;lbL0021D2	ds.l	$230
;	ds.w	1
;lbL002A94	ds.l	1
;
;	end
