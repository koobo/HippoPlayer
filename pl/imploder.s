;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000

test	=	1

; use medley irq
medleyIrq = 0

	incdir	include:
	include	exec/exec_lib.i
	include	exec/memory.i

 ifne test

;	bra	.skop
 
	moveq	#1,d0
	lea	  medley,a0
	lea	masterVol,a1 
	lea 	songCount,a2
	lea setTempoFunc,a3
	jsr		init
	bsr	playLoop

;	bra	skip
	moveq	#8,d0
	jsr	song
	bsr	playLoop
	moveq	#4,d0
	jsr	song
	bsr	playLoop
skip
	jsr	end
	rts

playLoop
.loop	
	cmp.b	#$80,$dff006
	bne.b	.loop
.x	cmp.b	#$80,$dff006
	beq.b	.x	
	move	#$ff0,$dff180

 ifeq medleyIrq
	jsr	play
 endif
	clr	$dff180

	btst	#6,$bfe001
	bne.b	.loop

.m	btst	#6,$bfe001
	beq.b	.m
	rts


setTempoFunc 
	rts

masterVol 	dc $40
songCount	dc 0

	section d,data_c

medley  
	incbin	"sys:music/roots/modules/medley/paul van der valk/imploder4.mso"

	section c,code_p

 endc

impStart

	jmp init(pc)
	jmp play(pc)
	jmp end(pc)
	jmp song(pc)

* d0 = song number
* a0 = module address
* a1 = master volume address
* a2 = max songs address
* a3 = set tempo function
init
	move	d0,d3

	movem.l	d1-a6,-(sp)
	move.l	4.w,a6
	move.l	#ChipSpaceSize+4,d0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	jsr	_LVOAllocMem(a6)
	move.l	d0,ChipSpaceAddr
	movem.l	(sp)+,d1-a6
	beq.b	.error
	
	move.l	d0,a4
	lea	ChipSpaceSize(a4),a4
	move.l	a4,EmptySampleAddr

	move.l	a2,-(sp)
	move.l	d3,-(sp)

	move.l	a1,masterVolAddr
	move.l	a3,setTempoFuncAddr

	* Skip 4 byte id
	addq.l	#4,a0
	bsr		InstallMedley

	moveq	#1,d0	* 0: ciaa, 1: ciab
	bsr	InstallSound
	tst.l	d0
	beq.b	.ok
	illegal
.ok

	* minimum is 1?
	move.l	(sp)+,d0 
	bsr	InstallScore

	bsr	EnablePlay


	* number of scores in this medley
	move.l	ScoTable,A0
	moveq	#0,d0
	move.b	-1(a0),d0
	move.l	(sp)+,a2
	move	d0,(a2)


	moveq	#0,d0
	rts

.error
	moveq	#-1,d0
	rts

song
	bsr	DisablePlay
	bsr	InstallScore
	bsr	EnablePlay
	rts

play
	move.l	masterVolAddr(pc),a0
	move	(a0),masterVolValue
	
	bra  	IrqCode

end	
	bsr	RemoveSound
	bsr	ClrChannels

	movem.l	d0-a6,-(sp)
	move.l	ChipSpaceAddr(pc),d0
	beq.b	.x
	move.l	d0,a1
	move.l	#ChipSpaceSize+4,d0	
	move.l	4.w,a6
	jsr		_LVOFreeMem(a6)
.x	movem.l	(sp)+,d0-a6
	rts



masterVolAddr			dc.l 	0
masterVolValue			dc.w	$40
setTempoFuncAddr		dc.l	0
ChipSpaceAddr			dc.l	0
EmptySampleAddr			dc.l	0

InstallExtMedley:
;^^^^^^^^^^^^^^^
	;
	; a0	Songs (if 0 then ignored)
	; a1	Instruments (if 0 then ignored)

lbC007D26	MOVE.L	A1,D0
	BEQ.S	lbC007D3A
	MOVE.L	A0,-(SP)
	MOVE.L	A1,A0
	BSR.S	lbC007D3A
	MOVE.L	(SP)+,A0
	MOVEQ	#1,D0
	MOVE.L	A0,D1
	BNE.S	lbC007D3C
	RTS

InstallMedley:
;^^^^^^^^^^^^
	;
	; a0	Medley address

lbC007D3A	MOVEQ	#3,D0
lbC007D3C	LEA	lbL008B7C(PC),A1
lbC007D40	MOVE.L	A0,D1
	ADD.L	(A0)+,D1
	MOVE.L	D1,(A1)+
	DBRA	D0,lbC007D40
	RTS

InstallSound:
;^^^^^^^^^^^
	;
	; d0.b	CIA num: 0 = ciaa, 1 = ciab
	;

lbC007D4C	
	;move.l	GP,GpStore

	BSR	lbC008050
	MOVE.B	D0,lbB00997A
	;BTST	#1,D0
	;BEQ.W	lbC007D62
	;BSR	lbC007C20 allocate audio
	;BEQ.S	lbC007D7E
lbC007D62
	MOVE.B	lbB00997A(PC),D0	
 ifne medleyIrq
	BSR	lbC007D96		; initIRq
	BNE.S	lbC007D7C
 endif
	BSR	lbC007F16
	MOVEQ	#$3F,D0
	BSR	lbC00801E
	LEA	ok.MSG(PC),A0
	MOVEQ	#0,D0
lbC007D7C	RTS

;lbC007D7E	LEA	audiolocked.MSG(PC),A0
;	MOVEQ	#2,D0
;	RTS

RemoveSound
lbC007D86	BSR	lbC0082F0
 ifne medleyIrq
	BSR	lbC007E6C  ; exitirc
 endc
	;BSR	lbC007CE4		; free audio?
	MOVEQ	#0,D0
	RTS

InitIrq
lbC007D96	AND.B	#1,D0
	BNE.S	lbC007DA8

InitIrqA
	LEA	$BFE001,A0
	LEA	ciaaresource.MSG(PC),A1
	BRA.S	lbC007DB2

InitIrqB
lbC007DA8	LEA	$BFD000,A0
	LEA	ciabresource.MSG(PC),A1
lbC007DB2	TST.B	lbB009975
	BEQ.S	lbC007DBE
	MOVEQ	#-1,D0
	RTS

_InitIrq
lbC007DBE	MOVEM.L	A2/A6,-(SP)
	MOVEM.L	A0/A1,-(SP)
	MOVE.L	#$84,D0
	MOVE.L	#$10003,D1
	MOVE.L	4.W,A6
	JSR	-$C6(A6)
	MOVEM.L	(SP)+,A0/A1
	MOVE.L	D0,lbL00995C
	BEQ.S	lbC007E3C
	MOVE.L	A0,lbL009954
	MOVEQ	#0,D0
	MOVE.L	4.W,A6
	
	JSR	-$1F2(A6)
	MOVE.L	D0,lbL009958
	BEQ.S	lbC007E44
	MOVE.L	D0,A6
	LEA	lbL007E98(PC),A1
	BTST	#2,lbB00997A(PC)
	BNE.S	lbC007E10
	LEA	lbL007EAE(PC),A1
lbC007E10	MOVEQ	#0,D0
	JSR	-6(A6)
	TST.L	D0
	BNE.S	lbC007E44
	MOVE.W	#$3000,D0
	BSR	lbC007F8E
	MOVE.B	#$81,$D01(A0)
	MOVE.B	#1,$E01(A0)
	ST	lbB009975
	MOVEQ	#0,D0
lbC007E36	MOVEM.L	(SP)+,A2/A6
	RTS

lbC007E3C	LEA	outofmemory.MSG(PC),A0
	MOVEQ	#3,D0
	BRA.S	lbC007E36

lbC007E44	BSR.S	lbC007E4E
	LEA	timerbusy.MSG(PC),A0
	MOVEQ	#1,D0
	BRA.S	lbC007E36

lbC007E4E	MOVE.L	lbL00995C(PC),D0
	BEQ.S	lbC007E6A
	CLR.L	lbL00995C
	MOVE.L	D0,A1
	MOVE.L	#$84,D0
	MOVE.L	4.W,A6
	JSR	-$D2(A6)
lbC007E6A	RTS

ExitIrq
lbC007E6C	MOVE.L	A6,-(SP)
	TST.B	lbB009975
	BEQ.S	lbC007E8C
	BSR	lbC0082F0
	MOVE.L	lbL009958,D0
	BEQ.S	lbC007E8C
	MOVE.L	D0,A6
	MOVE.W	#0,D0
	JSR	-12(A6)
lbC007E8C	BSR.S	lbC007E4E
	CLR.B	lbB009975
	MOVE.L	(SP)+,A6
	RTS

lbL007E98	dc.l	0
	dc.l	0
	dc.w	$200
	dc.l	PVSynth10.MSG
	dc.w	0
	dc.w	0
	dc.l	lbC008366
lbL007EAE	dc.l	0
	dc.l	0
	dc.w	$200
	dc.l	PVSynth10.MSG
	dc.w	0
	dc.w	0
	dc.l	lbC00834A
PVSynth10.MSG	dc.b	'PV Synth 1.0',0
ciaaresource.MSG	dc.b	'ciaa.resource',0
ciabresource.MSG	dc.b	'ciab.resource',0
ok.MSG	dc.b	'ok',0
timerbusy.MSG	dc.b	'timer busy',0
audiolocked.MSG	dc.b	'audio locked',0
outofmemory.MSG	dc.b	'out of memory',0

InitSCHs
lbC007F16	LEA	lbL008B8C(PC),A0
	MOVEQ	#0,D0
	BSR.S	lbC007F34
	LEA	lbL008C9A(PC),A0
	MOVEQ	#1,D0
	BSR.S	lbC007F34
	LEA	lbL008DA8(PC),A0
	MOVEQ	#2,D0
	BSR.S	lbC007F34
	LEA	lbL008EB6(PC),A0
	MOVEQ	#3,D0
lbC007F34	AND.W	#3,D0
	CLR.B	0(A0)
	MOVEQ	#1,D1
	ASL.W	D0,D1
	MOVE.W	D1,8(A0)
	OR.W	#$8000,D1
	MOVE.W	D1,10(A0)
	MOVEQ	#0,D1
	MOVE.B	D0,D1
	ASL.W	#4,D1
	ADD.L	#$DFF0A0,D1
	MOVE.L	D1,4(A0)
	MOVEQ	#0,D1
	MOVE.B	D0,D1
	ASL.W	#5,D1
	;MOVE.L	lbL00995C,A1
	;TST.L	(A1)+
	;lea	ChipSpace,a1
	move.l	ChipSpaceAddr(pc),a1

	ADD.W	D1,A1
	MOVE.L	A1,$4A(A0)
	CLR.B	$58(A0)
	MOVE.B	D0,D1
	CMP.B	#2,D1
	BLO.S	lbC007F84
	ST	$58(A0)
	EOR.B	#1,D1
lbC007F84	BTST	#0,D1
	SNE	$57(A0)
	RTS

SetTempo
lbC007F8E	
	CMP.W	#$1000,D0
	BHI.S	lbC007F98
	MOVE.W	#$1000,D0
lbC007F98	MOVE.W	D0,lbW008FC4

 ifne medleyIrq
 	MOVE.L	lbL009954(PC),A0
	;lsr	#3,d0
	MOVE.B	D0,$401(A0)
	LSR.W	#8,D0
	MOVE.B	D0,$501(A0)
 else
	 move.l	setTempoFuncAddr(pc),a0 
	jsr	 (a0)
 endif
	RTS

GetTempo
	MOVE.W	lbW008FC4(PC),D0
	RTS

SetTranspose
lbC007FB4	MOVE.B	D0,lbB008FD2
	RTS

SetSongRepeat
lbC007FBC	MOVE.B	D0,lbB008FD3
	RTS

SetSoundUpdRate
lbC007FC4	MOVE.B	D0,lbB008FD6
	RTS

SetFlangSpeed
lbC007FCC	MOVE.B	D0,lbB008FD4
	MOVE.B	#1,lbB008FD5
	RTS

SetFlangAlgo
lbC007FDC	LEA	lbB008FD7(PC),A0
	MOVE.B	D0,(A0)
	LEA	lbW008B26(PC),A0
	CMP.B	-1(A0),D0
	BLS.S	lbC007FEE
	MOVEQ	#0,D0
lbC007FEE	AND.W	#$FF,D0
	ASL.W	#1,D0
	ADD.W	D0,A0
	ADD.W	(A0),A0
	MOVE.L	A0,lbL008FC6
	MOVE.L	A0,lbL008FCA
lbC008004	MOVE.L	A2,-(SP)
	LEA	lbL009960(PC),A2
	MOVEQ	#3,D1
lbC00800C	MOVE.L	(A2)+,A1
	MOVE.B	(A0)+,D0
	EXT.W	D0
	MOVE.W	D0,$5A(A1)
	DBRA	D1,lbC00800C
	MOVE.L	(SP)+,A2
	RTS


SetSongVolume
lbC00801E	LEA	lbL008FD8(PC),A0
	; a0	BufPtr (64 bytes)
	; d0.B	max level (0..63)
	;
lbC008022	MOVEM.L	D2-D4,-(SP)
	AND.B	#$3F,D0
	MOVEQ	#$3F,D1
	MOVEQ	#$3F,D2
	MOVEQ	#$3F,D3
	MOVEQ	#0,D4
lbC008032	MOVE.B	D4,(A0)+
	ADD.B	D0,D1
	CMP.B	D3,D1
	BLO.S	lbC00803E
	SUB.B	D3,D1
	ADDQ.B	#1,D4
lbC00803E	DBRA	D2,lbC008032
	MOVEM.L	(SP)+,D2-D4
	RTS

EnablePlay
lbC008048	ST	lbB009974
	RTS

DisablePlay
lbC008050	CLR.B	lbB009974
	RTS

InstallScore
lbC008058	MOVE.L	lbL008B7C(PC),A0
	CMP.B	-1(A0),D0		
	BHI	lbC008146		* if > numentries
	AND.W	#$FF,D0
	ASL.W	#2,D0
	ADD.W	D0,A0
	MOVE.L	(A0),D0
	BEQ	lbC008146
	ADD.L	D0,A0
	BSR.S	lbC008050
	CLR.B	lbB009976
	CLR.B	lbB009977
	MOVEM.L	D2-D7/A2-A6,-(SP)
	MOVE.L	A0,A2
	LEA	lbL009960(PC),A3
	MOVEQ	#0,D2
lbC00808E	MOVE.L	(A3)+,A4
	MOVE.L	A4,A0
	BSR	lbC008166
	MOVEQ	#0,D0
	MOVE.B	$10(A2,D2.W),D0
	BEQ	lbC008134
	ASL.W	#2,D0
	MOVE.L	lbL008B80(PC),A0
	ADD.W	D0,A0
	ADD.L	(A0),A0
	ADD.W	#$10,A0
	MOVE.L	A0,$2C(A4)
	MOVE.L	A0,$5C(A4)
	MOVEQ	#0,D0
	MOVE.B	$1A(A2,D2.W),D0
	BNE.S	lbC0080C6
	MOVE.B	$1E(A2),D0
	BNE.S	lbC0080C6
	MOVEQ	#1,D0
lbC0080C6	MOVE.B	D0,$A4(A4)
	ASL.W	#2,D0
	MOVE.L	lbL008B84(PC),A0
	ADD.W	D0,A0
	ADD.L	(A0),A0
	MOVE.L	A0,12(A4)
	MOVE.B	$26(A2,D2.W),$A6(A4)
	BNE.S	lbC0080E4
	ST	0(A4)
lbC0080E4	MOVE.B	$2A(A2,D2.W),$A7(A4)
	MOVE.B	$24(A2),D0
	BSR	lbC00801E
	MOVE.B	$20(A2),D0
	BSR	lbC007FC4
	MOVE.B	$21(A2),D0
	BSR	lbC007FBC
	MOVE.B	$1F(A2),D0
	BSR	lbC007FB4
	MOVE.B	$22(A2),D0
	BSR	lbC007FDC
	MOVE.B	$23(A2),D0
	BSR	lbC007FCC
	MOVE.W	$18(A2),D0
	BSR	lbC007F8E
	MOVE.B	$2E(A2,D2.W),D0
	LEA	$64(A4),A0
	BSR	lbC008022
	MOVE.B	#1,$30(A4)
lbC008134	ADDQ.B	#1,D2
	CMP.B	#4,D2
	BLO	lbC00808E
	MOVEM.L	(SP)+,D2-D7/A2-A6
	MOVEQ	#-1,D0
	BRA.S	lbC008148

is_Fail:
lbC008146	MOVEQ	#0,D0
lbC008148	LEA	lbB009978(PC),A0
	MOVE.B	D0,(A0)
	RTS

ClrChannels:
	LEA	lbL008B8C(PC),A0
	BSR.S	lbC008166
	LEA	lbL008C9A(PC),A0
	BSR.S	lbC008166
	LEA	lbL008DA8(PC),A0
	BSR.S	lbC008166
	LEA	lbL008EB6(PC),A0
lbC008166	CLR.B	0(A0)
	CLR.B	$30(A0)
	CLR.B	2(A0)
	CLR.B	3(A0)
	CLR.B	$62(A0)
	CLR.B	$A8(A0)
	CLR.B	$A9(A0)
	MOVE.B	#1,$2B(A0)
	CLR.W	$AA(A0)
	CLR.W	$AC(A0)
	CLR.W	$5A(A0)
	CLR.W	$10(A0)
	LEA	$1A(A0),A1
	CLR.L	(A1)+
	CLR.L	(A1)+
	CLR.L	(A1)+
	CLR.L	(A1)+
	TST.B	$51(A0)
	BNE.S	lbC0081B2
	MOVE.W	8(A0),$DFF096
lbC0081B2	MOVEQ	#$3F,D0
	MOVE.B	D0,$63(A0)
	LEA	$64(A0),A0
	BRA	lbC008022

lbC0081C0	TST.B	lbB009976
	BNE.S	lbC0081FE
	BSR	lbC0082F0
	LEA	lbL008B7C(PC),A0
	LEA	lbL0094B4(PC),A1
	BRA.S	lbC0081F4

lbC0081D6	BSR	lbC0082F0
	ST	lbB009979
	LEA	lbL008B7C(PC),A0
	LEA	lbL009018(PC),A1
	TST.B	lbB009976
	BEQ.S	lbC0081F4
	LEA	lbL0094B4(PC),A0
lbC0081F4	MOVE.W	#$24D,D0
lbC0081F8	MOVE.W	(A0)+,(A1)+
	DBRA	D0,lbC0081F8
lbC0081FE	RTS

lbC008200	BSR	lbC0082F0
	TST.B	lbB009979
	BEQ.S	lbC0081FE
	LEA	lbL009018(PC),A0
	LEA	lbL008B7C(PC),A1
	TST.B	lbB009976
	BEQ.S	lbC008220
	LEA	lbL0094B4(PC),A1
lbC008220	BSR.S	lbC0081F4
	MOVE.W	lbW008FC4(PC),D0
	BRA	lbC007F8E

RestoreSong
lbC00822A	BSR	lbC0082F0
	LEA	lbL0094B4(PC),A0
	LEA	lbL008B7C(PC),A1
	BSR.S	lbC0081F4
	MOVE.W	lbW008FC4(PC),D0
	BRA	lbC007F8E

InstallJingle
	MOVE.W	D0,-(SP)
	BSR	lbC0081C0
	MOVE.W	(SP)+,D0
	BSR	lbC008058
	SNE	lbB009976
	RTS

InstallExtJingle
	MOVE.W	D0,-(SP)
	MOVEM.L	A0/A1,-(SP)
	BSR	lbC0082F0
	BSR	lbC0081C0
	MOVEM.L	(SP)+,A0/A1
	BSR	lbC007D26
	MOVE.W	(SP)+,D0
	BSR	lbC008058
	SNE	lbB009976
	RTS

GetMsScore
	MOVE.L	lbL008B7C(PC),A0
	BRA.S	lbC00828E

GetMsTrack
	MOVE.L	lbL008B80(PC),A0
	BRA.S	lbC00828E

GetMsInstr
lbC008284	MOVE.L	lbL008B84(PC),A0
	BRA.S	lbC00828E

	MOVE.L	lbL008B88(PC),A0
lbC00828E	CMP.B	-1(A0),D0
	BLS.S	lbC008298
	MOVEQ	#0,D0
	BRA.S	lbC0082A6

lbC008298	AND.W	#$FF,D0
	ASL.W	#2,D0
	ADD.W	D0,A0
	MOVE.L	(A0),D0
	BEQ.S	lbC0082A6
	ADD.L	A0,D0
lbC0082A6	MOVE.L	D0,A0
	RTS

	BSR	lbC008284
	BEQ.S	lbC0082B6
	LEA	lbC0082BA(PC),A0
	BSR.S	lbC0082D0
lbC0082B6	TST.L	D0
	RTS

lbC0082BA	MOVE.L	D0,12(A0)
	CLR.W	$10(A0)
	LEA	$1A(A0),A1
	CLR.L	(A1)+
	CLR.L	(A1)+
	CLR.L	(A1)+
	CLR.L	(A1)+
	RTS

With4ChnDo
lbC0082D0	MOVE.L	A6,-(SP)
	MOVE.L	A0,A6
	LEA	lbL008B8C(PC),A0
	JSR	(A6)
	LEA	lbL008C9A(PC),A0
	JSR	(A6)
	LEA	lbL008DA8(PC),A0
	JSR	(A6)
	LEA	lbL008EB6(PC),A0
	JSR	(A6)
	MOVE.L	(SP)+,A6
	RTS
	
DisableSound
lbC0082F0	BSR	lbC008050
	LEA	lbC0082FA(PC),A0
	BRA.S	lbC0082D0

lbC0082FA	TST.B	$51(A0)
	BNE.S	lbC008308
	MOVE.W	8(A0),$DFF096
lbC008308	RTS

	BSR.S	lbC00831E
	ST	$51(A0)
	MOVE.L	4(A0),A0
	RTS

	BSR.S	lbC00831E
	CLR.B	$51(A0)
	RTS

lbC00831E	AND.W	#3,D0
	ASL.W	#2,D0
	LEA	lbL009960(PC),A0
	MOVE.L	0(A0,D0.W),A0
	RTS

	CMP.W	#$1000,D0
	BLO.S	lbC008338
	MOVE.W	#$1000,D0
lbC008338	MOVE.L	D2,-(SP)
	MOVE.W	D0,D2
	BEQ.S	lbC008346
lbC00833E	BSR	lbC00835E
	SUBQ.W	#1,D2
	BNE.S	lbC00833E
lbC008346	MOVE.L	(SP)+,D2
	RTS

lbC00834A	MOVE.L	A6,-(SP)
	MOVE.L	4,A6
	LEA	lbL007E98(PC),A1
	jsr	_LVOCause(a6)	* level 1 trigger
	MOVE.L	(SP)+,A6
	RTS

lbC00835E	ADDQ.W	#1,lbW009970
	BRA.S	lbC008374

;-----------------------------------------------------
; interrupt code

IrqCode:
lbC008366	
;	move	#$f00,$dff180
;	bsr.b	.x
;	move	#$0,$dff180
;	rts
;.x

	ADDQ.W	#1,lbW009970
	;TST.B	lbB009974	; IrqStatus
	;BEQ.S	lbC0083D8
lbC008374	MOVEM.L	D0-D7/A0-A6,-(SP)
	TST.B	lbB009977
	BEQ.S	lbC008394
	CLR.B	lbB009977
	CLR.B	lbB009976
	BSR	lbC00822A
	BSR	lbC008048
NoJingReq
lbC008394	
	MOVE.B	lbB008FD4(PC),D0
	BEQ.S	lbC0083BC
	LEA	lbB008FD5(PC),A0
	SUBQ.B	#1,(A0)
	BNE.S	lbC0083BC
	MOVE.B	D0,(A0)
	MOVE.L	lbL008FC6(PC),A0
	CMP.B	#$80,(A0)
	BNE.S	lbC0083B2
	MOVE.L	lbL008FCA(PC),A0
UpdFlangNoInit
lbC0083B2	
	BSR	lbC008004
	MOVE.L	A0,lbL008FC6
UpdFlangEnd
lbC0083BC	
; update channels
	LEA	lbL008B8C(PC),A2
	BSR.S	lbC0083DA
	LEA	lbL008C9A(PC),A2
	BSR.S	lbC0083DA
	LEA	lbL008DA8(PC),A2
	BSR.S	lbC0083DA
	LEA	lbL008EB6(PC),A2
	BSR.S	lbC0083DA
	MOVEM.L	(SP)+,D0-D7/A0-A6
lbC0083D8	RTS

;---------------------------
; the channel update routine

UpdSch
lbC0083DA	TST.B	0(A2)
	BEQ	lbC0088AE
	MOVE.L	12(A2),A3
	TST.B	$30(A2)
	BEQ.S	lbC008466
	SUBQ.B	#1,$2B(A2)
	BNE.S	lbC008466
	ST	$3F(A2)
	CLR.B	$62(A2)
	MOVE.L	$2C(A2),A0
lbC0083FE	MOVEQ	#0,D0
	MOVE.B	(A0)+,D0
	BMI.S	lbC008434
	BEQ.S	lbC008414
	MOVE.B	D0,1(A2)
	ST	2(A2)
	ST	3(A2)
	BRA.S	lbC00841C

lbC008414	CLR.B	2(A2)
	CLR.B	3(A2)
lbC00841C	MOVE.B	(A0)+,$2B(A2)
	BEQ.S	lbC0083FE
	BPL.S	lbC00842E
	CLR.B	3(A2)
	BCLR	#7,$2B(A2)
lbC00842E	MOVE.L	A0,$2C(A2)
	BRA.S	lbC008466

lbC008434	MOVE.B	(A0)+,D1
	AND.W	#15,D0
	ASL.W	#1,D0
	LEA	lbW008446(PC,D0.W),A1
	ADD.W	(A1),A1
	JSR	(A1)
	BRA.S	lbC0083FE

lbW008446	dc.w	lbC008926-lbW008446
x1	dc.w	lbC0083D8-x1
x2	dc.w	lbC008976-x2
x3	dc.w	lbC00898C-x3
x4	dc.w	lbC0089AA-x4
x5	dc.w	lbC0089D2-x5
x6	dc.w	lbC008A02-x6
x7	dc.w	lbC008A22-x7
x8	dc.w	lbC008A42-x8
x9	dc.w	lbC0083D8-x9
x10	dc.w	lbC0083D8-x10
x11	dc.w	lbC0083D8-x11
x12	dc.w	lbC0083D8-x12
x13	dc.w	lbC0083D8-x13
x14	dc.w	lbC0083D8-x14
x15	dc.w	lbC0083D8-x15

lbC008466	SUBQ.B	#1,$62(A2)
	BPL	lbC0083D8
	MOVE.B	lbB008FD6(PC),$62(A2)
	TST.B	$3F(A2)
	BEQ	lbC0085E6
	CLR.B	$3F(A2)
	MOVE.B	1(A2),D2
	ADD.B	lbB008FD2(PC),D2
	ADD.B	$A9(A2),D2
	ADD.B	$13(A3),D2
	CMP.B	#2,$10(A3)
	BNE.S	lbC0084E0
	MOVEQ	#-1,D0
	MOVEQ	#12,D1
lbC00849C	ADDQ.B	#1,D0
	SUB.B	D1,D2
	BHS.S	lbC00849C
	MOVE.B	D0,$3E(A2)
	ADD.B	D1,D2
	EXT.W	D2
	ASL.W	#1,D2
	LEA	lbW008A60(PC),A0
	MOVE.W	0(A0,D2.W),$4E(A2)
	MOVEQ	#0,D0
	MOVE.B	$14(A3),D0
	ASL.W	#2,D0
	MOVE.L	lbL008B88(PC),A0
	ADD.W	D0,A0
	ADD.L	(A0),A0
	MOVE.L	A0,$40(A2)
	MOVE.W	$10(A0),$44(A2)
	ADD.W	#$18,A0
	MOVE.L	A0,$46(A2)
	CLR.B	$50(A2)
	BRA	lbC0085E6

lbC0084E0	MOVE.B	D2,D0
	CMP.B	#$3E,D0
	BLO.S	lbC00852A
	CMP.B	#$56,D0
	BLO.S	lbC00850C
	CMP.B	#$62,D0
	BLO.S	lbC008500
	LEA	$1C(A3),A0
	MOVE.B	#7,$3E(A2)
	BRA.S	lbC008572

lbC008500	LEA	$1B(A3),A0
	MOVE.B	#6,$3E(A2)
	BRA.S	lbC008576

lbC00850C	CMP.B	#$4A,D0
	BLO.S	lbC00851E
	LEA	$1A(A3),A0
	MOVE.B	#5,$3E(A2)
	BRA.S	lbC00857A

lbC00851E	LEA	$19(A3),A0
	MOVE.B	#4,$3E(A2)
	BRA.S	lbC00857E

lbC00852A	CMP.B	#$26,D0
	BLO.S	lbC00854E
	CMP.B	#$32,D0
	BLO.S	lbC008542
	LEA	$18(A3),A0
	MOVE.B	#3,$3E(A2)
	BRA.S	lbC008582

lbC008542	LEA	$17(A3),A0
	MOVE.B	#2,$3E(A2)
	BRA.S	lbC008586

lbC00854E	CMP.B	#$1A,D0
	BLO.S	lbC008560
	LEA	$16(A3),A0
	MOVE.B	#1,$3E(A2)
	BRA.S	lbC00858A

lbC008560	LEA	$15(A3),A0
	CLR.B	$3E(A2)
	BRA.S	lbC00858E

lbB00856A	dc.b	0
	dc.b	12
	dc.b	$18
	dc.b	$24
	dc.b	$30
	dc.b	$3C
	dc.b	$48
	dc.b	$54

lbC008572	MOVE.B	-(A0),D0
	BNE.S	lbC008590
lbC008576	MOVE.B	-(A0),D0
	BNE.S	lbC008590
lbC00857A	MOVE.B	-(A0),D0
	BNE.S	lbC008590
lbC00857E	MOVE.B	-(A0),D0
	BNE.S	lbC008590
lbC008582	MOVE.B	-(A0),D0
	BNE.S	lbC008590
lbC008586	MOVE.B	-(A0),D0
	BNE.S	lbC008590
lbC00858A	MOVE.B	-(A0),D0
	BNE.S	lbC008590
lbC00858E	MOVE.B	-(A0),D0
lbC008590	MOVE.B	D0,$3D(A2)
	MOVEQ	#0,D1
	MOVE.B	D0,D1
	ASL.W	#2,D1
	MOVE.L	lbL008B88(PC),A1
	ADD.W	D1,A1
	ADD.L	(A1),A1
	MOVE.L	A1,$40(A2)
	MOVE.L	A1,A0
	ADD.W	#$18,A0
	MOVE.L	A0,$46(A2)
	MOVEQ	#0,D1
	MOVE.B	$14(A1),D1
	SUB.B	lbB00856A(PC,D1.W),D2
	MOVE.W	$10(A1),D6
	CMP.B	#1,$10(A3)
	BNE.S	lbC0085CA
	SUBQ.B	#6,D2
	SUBQ.B	#6,D2
lbC0085CA	ADD.B	#$30,D2
	MOVEQ	#0,D1
	MOVE.B	D2,D1
	MOVE.B	D1,$3C(A2)
	ASL.W	#1,D1
	LEA	lbW008A48(PC),A0
	MOVE.W	0(A0,D1.W),$4E(A2)
	MOVE.W	D6,$44(A2)
lbC0085E6	MOVE.W	$4E(A2),$12(A2)
	MOVE.W	$10(A2),D0
	TST.B	3(A2)
	BEQ.S	lbC0085FC
	MOVEQ	#0,D0
	CLR.B	$2A(A2)
lbC0085FC	TST.B	2(A2)
	BEQ.S	lbC008630
	TST.B	$2A(A2)
	BEQ.S	lbC00861A
	SUB.W	$2E(A3),D0
	BLO.S	lbC008614
	CMP.W	$2A(A3),D0
	BHI.S	lbC008638
lbC008614	MOVE.W	$2A(A3),D0
	BRA.S	lbC008638

lbC00861A	ADD.W	$2C(A3),D0
	BLO.S	lbC008626
	CMP.W	$28(A3),D0
	BLO.S	lbC008638
lbC008626	MOVE.W	$28(A3),D0
	ST	$2A(A2)
	BRA.S	lbC008638

lbC008630	SUB.W	$30(A3),D0
	BHS.S	lbC008638
	MOVEQ	#0,D0
lbC008638	MOVE.W	D0,$10(A2)
	MOVE.W	D0,$14(A2)
	CLR.W	$16(A2)
	CLR.W	$18(A2)
	CLR.B	$61(A2)
	LEA	$32(A3),A4
	LEA	$1A(A2),A6
	MOVEQ	#3,D7
lbC008656	TST.B	(A4)
	BEQ	lbC008760
	MOVE.W	(A6),D0
	TST.B	3(A2)
	BEQ.S	lbC0086AA
	MOVE.B	6(A4),2(A6)
	TST.B	2(A4)
	BNE.S	lbC0086AA
	CLR.B	3(A6)
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.B	7(A4),D1
	BEQ.S	lbC00868C
	TST.B	$56(A2,D1.W)
	BEQ.S	lbC00868C
	ST	3(A6)
	MOVE.W	12(A4),D0
lbC00868C	CMP.B	#1,(A4)
	BNE.S	lbC008698
	TST.B	6(A4)
	BNE.S	lbC0086A4
lbC008698	MOVE.B	8(A4),D1
	BEQ.S	lbC0086AA
	TST.B	$56(A2,D1.W)
	BEQ.S	lbC0086AA
lbC0086A4	MOVE.W	12(A4),D0
	LSR.W	#1,D0
lbC0086AA	TST.B	2(A6)
	BNE.S	lbC0086E2
	TST.B	3(A6)
	BNE.S	lbC0086CC
	ADD.W	14(A4),D0
	BLO.S	lbC0086C2
	CMP.W	12(A4),D0
	BLO.S	lbC0086E6
lbC0086C2	MOVE.W	12(A4),D0
	ST	3(A6)
	BRA.S	lbC0086E6

lbC0086CC	SUB.W	$10(A4),D0
	BEQ.S	lbC0086D6
	BHS.S	lbC0086E6
	MOVEQ	#0,D0
lbC0086D6	TST.B	3(A4)
	BNE.S	lbC0086E6
	CLR.B	3(A6)
	BRA.S	lbC0086E6

lbC0086E2	SUBQ.B	#1,2(A6)
lbC0086E6	MOVE.W	D0,(A6)
	TST.B	1(A4)
	BEQ.S	lbC0086FA
	MOVEQ	#0,D0
	TST.B	3(A6)
	BEQ.S	lbC0086FA
	MOVE.W	12(A4),D0
lbC0086FA	TST.B	5(A4)
	BEQ.S	lbC008706
	NEG.W	D0
	ADD.W	12(A4),D0
lbC008706	CMP.B	#2,(A4)
	BLO.S	lbC008752
	BEQ.S	lbC008726
	CMP.B	#4,(A4)
	BLO.S	lbC008732
	BEQ.S	lbC00873A
	CMP.B	#6,(A4)
	BLO.S	lbC008742
	BEQ.S	lbC00874A
	LSR.W	#8,D0
	ADD.B	D0,$61(A2)
	BRA.S	lbC008760

lbC008726	SUB.W	D0,$14(A2)
	BHS.S	lbC008760
	CLR.W	$14(A2)
	BRA.S	lbC008760

lbC008732	LSR.W	#8,D0
	ADD.W	D0,$16(A2)
	BRA.S	lbC008760

lbC00873A	LSR.W	#8,D0
	ADD.W	D0,$18(A2)
	BRA.S	lbC008760

lbC008742	LSR.W	#5,D0
	ADD.W	D0,$12(A2)
	BRA.S	lbC008760

lbC00874A	LSR.W	#5,D0
	SUB.W	D0,$12(A2)
	BRA.S	lbC008760

lbC008752	MOVE.W	12(A4),D1
	LSR.W	#1,D1
	SUB.W	D0,D1
	ASR.W	#8,D1
	ADD.W	D1,$12(A2)
lbC008760	ADD.W	#$12,A4
	ADDQ.W	#4,A6
	DBRA	D7,lbC008656
	MOVE.L	$40(A2),A1
	MOVE.W	$44(A2),D6
	MOVE.L	$46(A2),A0
	MOVE.B	$10(A3),D0
	BEQ	lbC008836
	SUBQ.B	#1,D0
	BEQ	lbC00883C
	SUBQ.B	#1,D0
	BNE	lbC008828
	MOVEQ	#0,D2
	MOVE.B	$12(A3),D2
	ADD.W	$18(A2),D2
	CMP.W	$54(A2),D2
	BNE.S	lbC0087A0
	TST.B	$50(A2)
	BNE.S	lbC008810
lbC0087A0	MOVE.W	D2,$54(A2)
	MOVEQ	#$20,D6
	MOVEQ	#0,D4
	MOVE.B	$1C(A3),D4
	ADD.B	$61(A2),D4
	MOVE.W	D4,D5
	LSR.W	#4,D4
	BNE.S	lbC0087B8
	MOVEQ	#$10,D4
lbC0087B8	AND.W	#15,D5
	BNE.S	lbC0087C0
	MOVEQ	#$10,D5
lbC0087C0	MOVE.B	$3E(A2),D0
	MOVE.B	D0,D1
	SUBQ.B	#4,D1
	BLO.S	lbC0087DA
	CMP.B	#4,D1
	BLS.S	lbC0087D2
	MOVEQ	#4,D1
lbC0087D2	LSR.W	D1,D6
	ASL.W	D1,D4
	ASL.W	D1,D5
	MOVEQ	#4,D0
lbC0087DA	MOVE.B	D0,$60(A2)
	MOVE.L	$46(A2),A0
	MOVE.L	$4A(A2),A1
	MOVEQ	#0,D3
	MOVE.W	D6,D7
	LSR.W	#1,D6
	MOVE.W	D6,$52(A2)
	MOVE.W	$44(A2),D6
	SUBQ.W	#1,D6
lbC0087F6	AND.W	D6,D2
	AND.W	D6,D3
	MOVE.B	0(A0,D2.W),D0
	ADD.B	0(A0,D3.W),D0
	ADD.W	D4,D2
	ADD.W	D5,D3
	MOVE.B	D0,(A1)+
	SUBQ.B	#1,D7
	BNE.S	lbC0087F6
	ST	$50(A2)
lbC008810	MOVE.W	$12(A2),D0
	MOVE.B	$60(A2),D1
	LSR.W	D1,D0
	MOVE.W	D0,$12(A2)
	MOVE.W	$52(A2),D2
	MOVE.L	$4A(A2),A0
	BRA.S	lbC008866

lbC008828	TST.B	3(A2)
	BNE.S	lbC008836
	;MOVE.L	lbL00995C(PC),A0
	move.l	EmptySampleAddr(pc),a0
	MOVEQ	#2,D2
	BRA.S	lbC008866

lbC008836	MOVE.W	D6,D2
	LSR.W	#1,D2
	BRA.S	lbC008866

lbC00883C	MOVE.W	D6,D2
	LSR.W	#2,D2
	MOVEQ	#0,D0
	MOVE.B	$11(A3),D0
	ADD.W	$16(A2),D0
	MOVE.B	$14(A1),D1
	LSR.B	D1,D0
	BCLR	#0,D0
	BEQ.S	lbC00885E
	TST.B	$16(A1)
	BEQ.S	lbC00885E
	ADD.W	D6,A0
lbC00885E	LSR.W	#1,D6
	SUBQ.W	#1,D6
	AND.W	D6,D0
	ADD.W	D0,A0
lbC008866	MOVE.L	A0,$36(A2)
	MOVE.W	D2,$3A(A2)
	TST.B	$51(A2)
	BNE.S	lbC0088A8
	MOVE.L	4(A2),A1
	MOVE.L	A0,(A1)
	MOVE.W	D2,4(A1)
	MOVE.W	$12(A2),D0
	ADD.W	$5A(A2),D0
	MOVE.W	D0,6(A1)
	MOVEQ	#0,D0
	MOVE.B	$14(A2),D0
	LSR.B	#2,D0
	MOVE.B	$64(A2,D0.W),D0	

	;Fix this:
	LEA	lbL008FD8(PC),A0
	;MOVE.B	0(A0,D0.W),8(A1)
	moveq	#0,d1
	MOVE.B	0(A0,D0.W),d1
	mulu	masterVolValue(pc),d1
	lsr	#6,d1
	move	d1,8(A1)

	
	MOVE.W	10(A2),$DFF096
lbC0088A8	CLR.B	3(A2)
	RTS

;----------------------
; EFFECT checking
; if sch_FxTimeBase<>0 then effectmode = TRUE
; track should be auto-activated after time sch_FxOffTime has ellapsed
;

ChkEffect:
lbC0088AE	TST.B	$A6(A2)
	BEQ.S	lbC008912
	MOVE.W	lbW009970(PC),D0
	AND.W	#3,D0
	BNE.S	lbC008912
	TST.B	$A8(A2)
	BNE.S	lbC0088D6
	BSR.S	lbC008914
	MOVE.B	$A7(A2),D1
	SUBQ.B	#1,D1
	AND.B	D1,D0
	ADD.B	$A6(A2),D0
	MOVE.B	D0,$A8(A2)
lbC0088D6	SUBQ.B	#1,$A8(A2)
	BNE.S	lbC008912
	BSR.S	lbC008914
	MOVE.L	$5C(A2),A0
	MOVEQ	#0,D1
	MOVE.B	1(A0),D1
	SUBQ.B	#1,D1
	AND.W	D1,D0
	ASL.W	#1,D0
	MOVE.B	3(A0,D0.W),D1
	ASL.W	#2,D1
	MOVE.L	lbL008B80(PC),A0
	ADD.W	D1,A0
	MOVE.L	(A0),D0
	BEQ.S	lbC008912
	ADD.L	D0,A0
	ADD.W	#$10,A0
	MOVE.L	A0,$2C(A2)
	MOVE.B	#1,$2B(A2)
	ST	0(A2)
lbC008912	RTS

GetRndByte
lbC008914	MOVE.W	lbW009972(PC),D0
	ADD.W	lbW009970(PC),D0
	MOVE.W	D0,lbW009972
	LSR.W	#4,D0
	RTS

lbC008926	MOVE.W	$AA(A2),D0
	BEQ.S	lbC00893A
	SUBQ.W	#4,$AA(A2)
	LEA	$AE(A2),A1
	MOVE.L	-4(A1,D0.W),A0
	RTS


;----------------------
; SCODE handlers
;
; are called with:
;	a0	noteptr
;	a1	jumpadr
;	d1	operand byte
;
;	a1/d0/d1 are scratch
;	a0 should be preserved!!!

lbC00893A	TST.B	lbB009976
	BEQ.S	lbC008948
	ST	lbB009977
lbC008948	TST.B	$A6(A2)
	BNE.S	lbC00895C
	TST.B	lbB008FD3
	BEQ.S	lbC00895C
	MOVE.L	$5C(A2),A0
	RTS


lbC00895C	CLR.B	0(A2)
	TST.B	$51(A2)
	BNE.S	lbC008972
	MOVE.L	4(A2),A1
	MOVE.W	8(A2),$DFF096
lbC008972	TST.L	(SP)+
	RTS

scode_dynlevel
lbC008976	MOVE.B	D1,D0
	LSR.B	#1,D0
	MOVE.B	D0,$63(A2)
	MOVE.L	A0,-(SP)
	LEA	$64(A2),A0
	BSR	lbC008022
	MOVE.L	(SP)+,A0
	RTS

scode_instr
lbC00898C	MOVEQ	#0,D0
	MOVE.B	D1,D0
	ASL.W	#2,D0
	MOVE.L	lbL008B84(PC),A1
	ADD.W	D0,A1
	MOVE.L	(A1),D0
	BEQ.S	lbC0089A8
	ADD.L	D0,A1
	MOVE.L	A1,A3
	MOVE.L	A1,12(A2)
	MOVE.B	D1,$A4(A2)
lbC0089A8	RTS

lbC0089AA	AND.W	#$FF,D1
	BEQ.S	lbC0089D0
	SUBQ.W	#1,D1
	BSR	lbC008914
	AND.W	D1,D0
	ASL.W	#1,D0
	MOVEQ	#0,D1
	MOVE.B	1(A0,D0.W),D1
	ASL.W	#2,D1
	MOVE.L	lbL008B80(PC),A1
	MOVE.L	0(A1,D1.W),D0
	BEQ.S	lbC0089D0
	ADD.L	D0,A1
	MOVE.L	A1,A0
lbC0089D0	RTS


lbC0089D2	MOVEQ	#0,D0
	MOVE.B	D1,D0
	ASL.W	#2,D0
	MOVE.L	lbL008B80(PC),A1
	ADD.W	D0,A1
	MOVE.L	(A1),D1
	BEQ.S	lbC008A00
	ADD.W	#$10,A1
	ADD.L	A1,D1
	MOVE.W	$AA(A2),D0
	CMP.W	#$20,D0
	BHS.S	lbC008A00
	ADDQ.W	#4,$AA(A2)
	LEA	$AE(A2),A1
	MOVE.L	A0,0(A1,D0.W)
	MOVE.L	D1,A0
lbC008A00	RTS

lbC008A02	MOVE.W	$AC(A2),D0
	CMP.W	#$20,D0
	BHS.S	lbC008A20
	ADDQ.W	#4,$AC(A2)
	LEA	$CE(A2),A1
	MOVE.L	A0,0(A1,D0.W)
	LEA	$EE(A2),A1
	MOVE.B	D1,0(A1,D0.W)
lbC008A20	RTS

lbC008A22	MOVE.W	$AC(A2),D0
	BEQ.S	lbC008A3A
	LEA	$EE(A2),A1
	SUBQ.B	#1,-4(A1,D0.W)
	BEQ.S	lbC008A3C
	LEA	$CE(A2),A1
	MOVE.L	-4(A1,D0.W),A0
lbC008A3A	RTS

lbC008A3C	SUBQ.W	#4,$AC(A2)
	RTS

lbC008A42	MOVE.B	D1,$A9(A2)
	RTS

lbW008A48	dc.w	$3C00
	dc.w	$3880
	dc.w	$3580
	dc.w	$3280
	dc.w	$2FA0
	dc.w	$2D00
	dc.w	$2A60
	dc.w	$2800
	dc.w	$25C0
	dc.w	$23A0
	dc.w	$21A0
	dc.w	$1F9C
lbW008A60	dc.w	$1E00
	dc.w	$1C40
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
	dc.w	$3F8
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
	dc.w	$6B
	dc.w	$65
	dc.w	$5F
	dc.w	$5A
	dc.w	$55
	dc.w	$50
	dc.w	$4C
	dc.w	$48
	dc.w	$44
	dc.w	$40
	dc.w	$3C
	dc.w	$39
	dc.w	$35
	dc.w	$32
	dc.w	$2F
	dc.w	$2D
	dc.w	$2A
	dc.w	$28
	dc.w	$26
	dc.w	$24
	dc.w	$22
	dc.w	$20
	dc.w	$1E
	dc.w	$1C


	dc.w	5
FlangTable
lbW008B26	dc.w	12
	dc.w	15
	dc.w	$16
	dc.w	$1D
	dc.w	$2C
	dc.w	$3B
	dc.w	0
	dc.w	0
	dc.w	$8001
	dc.w	$100
	dc.w	0
	dc.w	1
	dc.w	$180
	dc.w	1
	dc.w	$2FF
	dc.w	$100
	dc.w	$FF02
	dc.w	$8000
	dc.w	$102
	dc.w	$FF01
	dc.w	$2FF
	dc.w	2
	dc.w	$FF00
	dc.w	$1FF
	dc.w	1
	dc.w	$280
	dc.w	0
	dc.w	$FE02
	dc.w	$1FF
	dc.w	$FF01
	dc.w	$2FE
	dc.w	0
	dc.w	$1FF
	dc.w	$FF01
	dc.w	$80FE
	dc.w	$FF00
	dc.w	$1FF
	dc.w	1
	dc.w	$200
	dc.w	$102
	dc.w	$FF01
	dc.w	$2FF
	dc.w	$FE80
ScoTable
lbL008B7C	dc.l	0
TrkTable
lbL008B80	dc.l	0
InsTable
lbL008B84	dc.l	0
WavTable
lbL008B88	dc.l	0
SCH0
lbL008B8C	dc.l	0
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
	dc.w	0
SCH1
lbL008C9A	dc.l	0
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
	dc.w	0
SCH2
lbL008DA8	dc.l	0
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
	dc.w	0
SCH3
lbL008EB6	dc.l	0
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
	dc.w	0
CurSpeed
lbW008FC4	dc.w	0
FlangPtr
lbL008FC6	dc.l	0
FlangInitPtr
lbL008FCA	dc.l	0
	dc.l	0
lbB008FD2	dc.b	0
lbB008FD3	dc.b	0
lbB008FD4	dc.b	0
lbB008FD5	dc.b	0
lbB008FD6	dc.b	0
lbB008FD7	dc.b	0
SongVolTable
lbL008FD8	dc.l	0
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
BackupSpace
lbL009018	dc.l	0
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
lbL0094B4	dc.l	0
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
GpStore
lbL009954	dc.l	0

CiaBaseAdr
lbL009958	dc.l	0

* Allocated chip buffer
lbL00995C	dc.l	0

ChannelTable
lbL009960	dc.l	lbL008B8C
	dc.l	lbL008C9A
	dc.l	lbL008DA8
	dc.l	lbL008EB6
Jiffies
lbW009970	dc.w	0
RandSeed
lbW009972	dc.w	0
lbB009974	dc.b	0
lbB009975	dc.b	0
lbB009976	dc.b	0
lbB009977	dc.b	0
lbB009978	dc.b	0
lbB009979	dc.b	0
lbB00997A	dc.b	0
	dc.b	0

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; CHIP section

;	SECTION	CHIP,bss_c
;
;ChipSpace:
;	ds.b	4*32
;ChipSpaceEnd

ChipSpaceSize	= 4*32

impEnd
