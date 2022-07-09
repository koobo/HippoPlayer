;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
	incdir	include:
	Include	mucro.i
	include	misc/eagleplayer.i
	incdir	include/
	include	patternInfo.i
	incdir


test=0

 ifne test

ahxInitCIA          = 0*4
ahxInitPlayer       = 1*4
ahxInitModule       = 2*4
ahxInitSubSong      = 3*4
ahxInterrupt        = 4*4
ahxStopSong         = 5*4
ahxKillPlayer       = 6*4
ahxKillCIA          = 7*4
ahxNextPattern      = 8*4   ;implemented, although no-one requested it :-)
ahxPrevPattern      = 9*4   ;implemented, although no-one requested it :-)
ahxBSS_P            = 10*4  ;pointer to ahx's public (fast) memory block
ahxBSS_C            = 11*4  ;pointer to ahx's explicit chip memory block
ahxBSS_Psize        = 12*4  ;size of public memory (intern use only!)
ahxBSS_Csize        = 13*4  ;size of chip memory (intern use only!)
ahxModule           = 14*4  ;pointer to ahxModule after InitModule
ahxIsCIA            = 15*4  ;byte flag (using ANY (intern/own) cia?)
ahxTempo            = 16*4  ;word to cia tempo (normally NOT needed to xs)
ahx_pExternalTiming = 0         ;byte, offset to public memory block
ahx_pMainVolume     = 1         ;byte, offset to public memory block
ahx_pSubsongs       = 2         ;byte, offset to public memory block
ahx_pSongEnd        = 3         ;flag, offset to public memory block
ahx_pPlaying        = 4         ;flag, offset to public memory block
ahx_pVoice0Temp     = 14        ;struct, current Voice 0 values
ahx_pVoice1Temp     = 246       ;struct, current Voice 1 values
ahx_pVoice2Temp     = 478       ;struct, current Voice 2 values
ahx_pVoice3Temp     = 710       ;struct, current Voice 3 values
ahx_pvtTrack        = 0         ;byte          (relative to ahx_pVoiceXTemp!)
ahx_pvtTranspose    = 1         ;byte          (relative to ahx_pVoiceXTemp!)
ahx_pvtNextTrack    = 2         ;byte          (relative to ahx_pVoiceXTemp!)
ahx_pvtNextTranspose= 3         ;byte          (relative to ahx_pVoiceXTemp!)
ahx_pvtADSRVolume   = 4         ;word, 0..64:8 (relative to ahx_pVoiceXTemp!)
ahx_pvtAudioPointer = 92        ;pointer       (relative to ahx_pVoiceXTemp!)
ahx_pvtAudioPeriod  = 100       ;word          (relative to ahx_pVoiceXTemp!)
ahx_pvtAudioVolume  = 102       ;word          (relative to ahx_pVoiceXTemp!)

main
	lea	ahxCIAInterrupt(pc),a0
	moveq	#0,d0
	move.l	thxroutines(pc),a2
	jsr	ahxInitCIA(a2)


	moveq	#0,d0	* loadwavesfile if possible
	moveq	#0,d1	* calculate filters (ei thx v 1.xx!!)

	move.l	#module,a0
	tst.b	3(a0)
	bne.b	.new
	moveq	#1,d1	* ei filttereitä!
.new

	sub.l   a0,a0	* auto alloc fast mem
	sub.l   a1,a1	* auto alloc chip
	move.l	thxroutines(pc),a2
	jsr	ahxInitPlayer(a2)
	tst	d0
	beq.b	.ok4

	move.l	thxroutines(pc),a2
	jsr	ahxKillCIA(a2)
	bra.b	.xxx
.ok4
	
	moveq	#0,d0			* normal speed
	move.l	#module,a0
	jsr	ahxInitModule(a2)
	tst	d0
	bne.b	.thxInitFailed


	move.l	ahxBSS_P(a2),a0
	;clr	maxsongs(a5)
	;move.b	.ahx_pSubsongs(a0),maxsongs+1(a5)

	moveq	#0,d0
	;move	songnumber(a5),d0
	moveq   #0,d1
	jsr	ahxInitSubSong(a2)

.wait
	btst	#6,$bfe001
	bne	.wait

.thxInitFailed
	move.l	thxroutines(pc),a2
	jsr	ahxKillCIA(a2)
.halt2	
	move.l	thxroutines(pc),a2
	jsr	ahxStopSong(a2)
	jsr	ahxKillPlayer(a2)
.thxInitFailed2
.xxx
	movem.l	Stripe1,d0/d1/d2/d3

	rts



ahxCIAInterrupt
	;move	#$f00,$dff180
	move.l	thxroutines(pc),a0
	jsr	ahxInterrupt(a0)
	;move	#$000,$dff180
	rts

thxroutines	dc.l	lbC000000

	section da,data



module
;	incbin	"m:mortimer twang/jennipha.ahx"
	incbin	"m:ahx/pink/wearing the inside out.ahx"
;	incbin	"m:ahx/curt cool/rubber spine.ahx"

	section repl,code
 endif


_LVOOldOpenLibrary	EQU	-$198
_LVOFreeMem	EQU	-$D2
_LVOCloseLibrary	EQU	-$19E
_LVOOpenResource	EQU	-$1F2
_LVOAllocMem	EQU	-$C6
_LVOCause	EQU	-$B4
****************************************************************************
binstart
lbC000000	BRA	InitCia

	BRA	InitPlayer

	BRA	InitModule

	BRA	InitSubSong

	BRA	Interrupt

	BRA	StopSong

	BRA	KillPlayer

	BRA	KillCia

	BRA	NextPattern

	BRA	PrevPattern

BSS_P	dc.b	0	;Dynamic mem pointer
	dc.b	0
	dc.b	0
	dc.b	0
BSS_C	dc.l	0
BSS_P_size	dc.l	0
BSS_C_size	dc.l	0
modulePointer	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
lbL00003C	dc.l	0
lbB000040	dc.b	0
lbB000041	dc.b	$81
	dc.b	0
	dc.b	0
	dc.b	'$'
	dc.b	'VER: AHX-BinaryPlayer_2.3d-sp3 (Dec 98)',0,0
	dc.b	0
	dc.b	$3A

InitCia	LEA	lbC000000(PC),A4
	SUBQ.W	#1,D0
	BMI.S	lbC000088
	BEQ.S	lbC00007E
	MOVEQ	#-1,D0
	RTS

lbC00007E	MOVE.L	A0,lbB000250-lbC000000(A4)
	ST	lbL00003C-lbC000000(A4)
	RTS

lbC000088	MOVE.L	A0,lbW00024C-lbC000000(A4)
	LEA	lbC000200(PC),A0
	MOVE.L	A0,lbB000250-lbC000000(A4)
	LEA	AHXcAbyss.MSG(PC),A0
	MOVE.L	A0,lbW000226-lbC000000(A4)
	LEA	lbL00023A(PC),A0
	MOVE.L	A0,lbW00022A-lbC000000(A4)
	LEA	lbC000232(PC),A0
	MOVE.L	A0,lbW00022E-lbC000000(A4)
	LEA	ciaaresource.MSG(PC),A1
	MOVE.L	A1,-(SP)
	MOVE.B	#$61,3(A1)
	MOVEQ	#0,D0
	MOVE.L	4.W,A6
	JSR	_LVOOpenResource(A6)
	LEA	lbC000000(PC),A4
	MOVE.L	D0,lbW00025A-lbC000000(A4)
	MOVE.L	(SP)+,A1
	MOVE.B	#$62,3(A1)
	MOVEQ	#0,D0
	JSR	_LVOOpenResource(A6)
	LEA	lbC000000(PC),A4
	MOVE.L	D0,lbW00025E-lbC000000(A4)
	MOVE.W	#$3781,lbB000040-lbC000000(A4)
	LEA	$BFE001,A3
	LEA	lbL00021C(PC),A4
	MOVEQ	#0,D6
	MOVE.L	lbW00025A(PC),A6
	LEA	(A4),A1
	MOVE.L	D6,D0
	JSR	-6(A6)
	TST.L	D0
	BEQ.S	lbC00014C
	LEA	(A4),A1
	MOVEQ	#1,D6
	MOVE.L	D6,D0
	JSR	-6(A6)
	TST.L	D0
	BEQ.S	lbC00014C
	LEA	$BFD000,A3
	MOVEQ	#0,D6
	MOVE.L	lbW00025E(PC),A6
	LEA	(A4),A1
	MOVE.L	D6,D0
	LEA	lbC000000(PC),A4
	MOVE.L	D0,lbB000254-lbC000000(A4)
	JSR	-6(A6)
	TST.L	D0
	BEQ.S	lbC00014C
	LEA	(A4),A1
	MOVEQ	#1,D6
	MOVE.L	D6,D0
	LEA	lbC000000(PC),A4
	MOVE.L	D0,lbB000254-lbC000000(A4)
	JSR	-6(A6)
	TST.L	D0
	BEQ.S	lbC00014C
	MOVEQ	#-1,D0
	BRA	lbC000184

lbC00014C	LEA	lbC000000(PC),A4
	MOVE.L	A3,lbW000262-lbC000000(A4)
	MOVE.L	A6,lbW000266-lbC000000(A4)
	MOVE.B	D6,lbB00026A-lbC000000(A4)
	LEA	$400(A3),A2
	TST.B	D6
	BEQ.S	lbC000168
	LEA	$600(A3),A2
lbC000168	MOVE.B	lbB000041(PC),(A2)
	MOVE.B	lbB000040(PC),$100(A2)
	LEA	$E00(A3),A2
	TST.B	D6
	BEQ.S	lbC00017E
	LEA	$F00(A3),A2
lbC00017E	MOVE.B	#$11,(A2)
	CLR.L	D0
lbC000184	LEA	lbC000000(PC),A4
	TST.W	D0
	SEQ	lbL00003C-lbC000000(A4)
	ST	lbW000258-lbC000000(A4)
	RTS

KillCia	LEA	lbC000000(PC),A4
	TST.B	lbL00003C-lbC000000(A4)
	BEQ.S	lbC0001D4
	SF	lbL00003C-lbC000000(A4)
	TST.B	lbW000258-lbC000000(A4)
	BEQ.S	lbC0001D4
	MOVE.L	lbW000262(PC),A3
	TST.B	lbB00026A-lbC000000(A4)
	BNE.S	lbC0001BA
	MOVE.B	#0,$E00(A3)
	BRA.S	lbC0001C0

lbC0001BA	MOVE.B	#0,$F00(A3)
lbC0001C0	MOVE.L	lbW000266(PC),A6
	LEA	lbL00021C(PC),A1
	LEA	lbC000000(PC),A4
	MOVE.L	lbB000254-lbC000000(A4),D0
	JSR	-12(A6)
lbC0001D4	RTS

lbC0001D6	MOVEM.L	D0-D7/A0-A6,-(SP)
	LEA	lbW0001F8(PC),A4
	ADD.W	D3,D3
	MOVE.W	0(A4,D3.W),D0
	LEA	lbC000000(PC),A3
	MOVE.W	D0,lbB000040-lbC000000(A3)
	MOVE.L	lbB000250-lbC000000(A3),A4
	JSR	(A4)
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

lbW0001F8	dc.w	$3781	;CIA timer values
	dc.w	$1BC0
	dc.w	$1280
	dc.w	$DE0

lbC000200	MOVE.L	lbW000262(PC),A4
	LEA	$400(A4),A4
	TST.B	$26A(A3)
	BEQ.S	lbC000212
	LEA	$200(A4),A4
lbC000212	MOVE.B	D0,(A4)
	LSR.W	#8,D0
	MOVE.B	D0,$100(A4)
	RTS

lbL00021C	dc.l	0
	dc.l	0
	dc.w	$200
lbW000226	dc.w	0
	dc.w	0
lbW00022A	dc.w	0
	dc.w	0
lbW00022E	dc.w	0
	dc.w	0

lbC000232	JSR	_LVOCause(A6)
	MOVEQ	#0,D0
	RTS

lbL00023A	dc.l	0
	dc.l	0
	dc.w	$200
	dc.w	0
	dc.w	0
	dc.l	$BFE001
lbW00024C	dc.w	0
	dc.w	0
lbB000250	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
lbB000254	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
lbW000258	dc.w	0
lbW00025A	dc.w	0
	dc.w	0
lbW00025E	dc.w	0
	dc.w	0
lbW000262	dc.w	0
	dc.w	0
lbW000266	dc.w	0
	dc.w	0
lbB00026A	dc.b	0
ciaaresource.MSG	dc.b	'ciaa.resource',0
AHXcAbyss.MSG	dc.b	'AHX (c) Abyss!',0

KillPlayer	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.W	#15,$DFF096
	LEA	lbC000000(PC),A5
	MOVE.L	BSS_P_size(PC),D0
	BEQ.S	lbC0002AE
	MOVE.L	4.W,A6
	MOVE.L	BSS_P(PC),A1
	JSR	_LVOFreeMem(A6)
	CLR.L	BSS_P_size-lbC000000(A5)
lbC0002AE	MOVE.L	BSS_C_size(PC),D0
	BEQ.S	lbC0002C4
	MOVE.L	4.W,A6
	MOVE.L	BSS_C(PC),A1
	JSR	_LVOFreeMem(A6)
	CLR.L	BSS_C_size-lbC000000(A5)
lbC0002C4	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

lbW0002CA	dc.w	3
	dc.w	7
	dc.w	15
	dc.w	$1F
	dc.w	$3F
	dc.w	$7F
	dc.w	3
	dc.w	7
	dc.w	15
	dc.w	$1F
	dc.w	$3F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$7F
	dc.w	$77F

lbC000324	MOVE.W	D5,D7
	MOVEQ	#0,D0
lbC000328	MOVE.B	D0,(A1)+
	ADD.W	D1,D0
	DBRA	D7,lbC000328
	MOVE.B	#$7F,(A1)+
	MOVE.W	D5,D7
	BEQ.S	lbC000346
	SUBQ.W	#1,D7
	MOVE.W	#$80,D0
lbC00033E	SUB.W	D1,D0
	MOVE.B	D0,(A1)+
	DBRA	D7,lbC00033E
lbC000346	MOVE.W	D5,D7
	ADDQ.W	#1,D7
	LEA	0(A1,D4.W),A2
	ADD.W	D7,D7
	SUBQ.W	#1,D7
lbC000352	MOVE.B	(A2)+,(A1)
	CMP.B	#$7F,(A1)
	BNE.S	lbC000360
	MOVE.B	#$80,(A1)+
	BRA.S	lbC000362

lbC000360	NEG.B	(A1)+
lbC000362	DBRA	D7,lbC000352
	RTS

InitPlayer	MOVEM.L	D1-D7/A0-A6,-(SP)
	LEA	lbC000000(PC),A5
	MOVE.W	D0,lbB0007FC-lbC000000(A5)
	MOVE.W	D1,lbB0007FE-lbC000000(A5)
	MOVE.L	A1,BSS_C-lbC000000(A5)
	MOVE.L	A0,BSS_P-lbC000000(A5)
	BNE.S	lbC0003A2
	MOVE.L	4.W,A6
	MOVE.L	#$649F4,D0
	MOVE.L	D0,BSS_P_size-lbC000000(A5)
	MOVE.L	#$10001,D1
	JSR	_LVOAllocMem(A6)
	MOVE.L	D0,BSS_P-lbC000000(A5)
	BEQ	lbC0007F8
lbC0003A2	LEA	BSS_C(PC),A6
	TST.L	(A6)
	BNE.S	lbC0003C6
	MOVE.L	4.W,A6
	MOVE.L	#$A00,D0
	MOVE.L	D0,BSS_C_size-lbC000000(A5)
	MOVE.L	#$10002,D1
	JSR	_LVOAllocMem(A6)
	MOVE.L	D0,BSS_C-lbC000000(A5)
lbC0003C6	SF	lbB000800-lbC000000(A5)
	TST.W	lbB0007FC-lbC000000(A5)
	BNE	lbC00048C
	TST.W	lbB0007FE-lbC000000(A5)
	BNE	lbC00048C
	MOVE.L	4.W,A6
	MOVEQ	#0,D0
	LEA	doslibrary.MSG(PC),A1
	JSR	_LVOOldOpenLibrary(A6)
	MOVE.L	D0,A6
	LEA	SahxWavesLoca.MSG(PC),A1
	MOVE.L	A1,D1
	MOVE.L	#$3ED,D2
	JSR	-$1E(A6)
	MOVE.L	D0,lbB000802-lbC000000(A5)
	BEQ	lbC000482
	MOVE.L	lbB000802(PC),D1
	MOVE.L	BSS_P(PC),D2
	ADD.L	#$56C,D2
	MOVE.L	#$100,D3
	JSR	-$2A(A6)
	MOVE.L	lbB000802(PC),D1
	JSR	-$24(A6)
	MOVE.L	BSS_P(PC),A1
	ADD.L	#$56C,A1
	MOVE.W	#$FF,D7
lbC000430	CMP.B	#10,(A1)+
	BNE.S	lbC00043A
	CLR.B	-1(A1)
lbC00043A	DBRA	D7,lbC000430
	SUB.L	#$100,A1
	MOVE.L	A1,D1
	MOVE.L	#$3ED,D2
	JSR	-$1E(A6)
	MOVE.L	D0,lbB000802-lbC000000(A5)
	BEQ	lbC000482
	MOVE.L	lbB000802(PC),D1
	MOVE.L	BSS_P(PC),D2
	ADD.L	#$56C,D2
	MOVE.L	#$64488,D3
	JSR	-$2A(A6)
	CMP.L	#$64488,D0
	SEQ	$800(A5)
	MOVE.L	lbB000802(PC),D1
	JSR	-$24(A6)
lbC000482	MOVE.L	A6,A1
	MOVE.L	4.W,A6
	JSR	_LVOCloseLibrary(A6)
lbC00048C	TST.B	lbB000800-lbC000000(A5)
	BNE	lbC000708
	MOVE.L	BSS_P(PC),A1
	ADD.L	#$31AF4,A1
	MOVEQ	#5,D3
	MOVEQ	#4,D2
lbC0004A2	MOVE.W	D2,D5
	LSR.W	#2,D5
	MOVE.L	#$80,D1
	DIVU	D5,D1
	SUBQ.W	#1,D5
	MOVE.W	D2,D4
	LSR.W	#1,D4
	NEG.W	D4
	BSR	lbC000324
	LSL.W	#1,D2
	DBRA	D3,lbC0004A2
	MOVE.W	#3,D7
	MOVE.W	#$55,D2
	MOVE.W	#$FF80,D0
lbC0004CC	MOVE.B	D0,(A1)+
	ADD.B	D2,D0
	DBRA	D7,lbC0004CC
	MOVE.W	#7,D7
	MOVE.W	#$24,D2
	MOVE.W	#$FF80,D0
lbC0004E0	MOVE.B	D0,(A1)+
	ADD.B	D2,D0
	DBRA	D7,lbC0004E0
	MOVE.W	#15,D7
	MOVE.W	#$11,D2
	MOVE.W	#$FF80,D0
lbC0004F4	MOVE.B	D0,(A1)+
	ADD.B	D2,D0
	DBRA	D7,lbC0004F4
	MOVE.W	#$1F,D7
	MOVE.W	#8,D2
	MOVE.W	#$FF80,D0
lbC000508	MOVE.B	D0,(A1)+
	ADD.B	D2,D0
	DBRA	D7,lbC000508
	MOVE.W	#$3F,D7
	MOVE.W	#4,D2
	MOVE.W	#$FF80,D0
lbC00051C	MOVE.B	D0,(A1)+
	ADD.B	D2,D0
	DBRA	D7,lbC00051C
	MOVE.W	#$7F,D7
	MOVE.W	#2,D2
	MOVE.W	#$FF80,D0
lbC000530	MOVE.B	D0,(A1)+
	ADD.B	D2,D0
	DBRA	D7,lbC000530
	MOVE.L	BSS_P(PC),A1
	ADD.L	#$31CEC,A1
	MOVEQ	#1,D2
lbC000544	MOVE.W	#$40,D3
	SUB.W	D2,D3
	MOVE.W	D3,D7
	SUBQ.W	#1,D7
	MOVE.W	#$8080,D0
lbC000552	MOVE.W	D0,(A1)+
	DBRA	D7,lbC000552
	MOVE.W	D2,D7
	SUBQ.W	#1,D7
	MOVE.W	#$7F7F,D0
lbC000560	MOVE.W	D0,(A1)+
	DBRA	D7,lbC000560
	ADDQ.W	#1,D2
	CMP.W	#$20,D2
	BLE.S	lbC000544
	MOVE.L	BSS_P(PC),A1
	ADD.L	#$32CEC,A1
	MOVE.W	#$77F,D7
	MOVE.L	#$41595321,D0
lbC000582	BTST	#8,D0
	BEQ.S	lbC000598
	TST.W	D0
	BMI.S	lbC000592
	MOVE.B	#$7F,(A1)+
	BRA.S	lbC00059A

lbC000592	MOVE.B	#$80,(A1)+
	BRA.S	lbC00059A

lbC000598	MOVE.B	D0,(A1)+
lbC00059A	ROR.L	#5,D0
	EOR.B	#$9A,D0
	MOVE.W	D0,D1
	ROL.L	#2,D0
	ADD.W	D0,D1
	EOR.W	D1,D0
	ROR.L	#3,D0
	DBRA	D7,lbC000582
	TST.W	lbB0007FE-lbC000000(A5)
	BNE	lbC000708
	LEA	lbW001770(PC),A4
	LEA	$AE6(A4),A5
	MOVE.L	BSS_P(PC),A6
	MOVE.L	A6,A1
	ADD.L	#$3346C,A1
	MOVE.L	A6,A3
	ADD.L	#$56C,A3
	CLR.W	$56A(A6)
	MOVE.L	#$19,D5
lbC0005DC	MOVE.L	A6,A0
	ADD.L	#$31AF4,A0
	LEA	lbW0002CA(PC),A2
	MOVE.W	#$2C,D6
lbC0005EC	MOVE.W	(A2)+,D7
	MOVE.W	(A4)+,D2
	MOVE.W	(A5)+,D3
	EXT.L	D2
	EXT.L	D3
	ASL.L	#8,D2
	ASL.L	#8,D3
lbC0005FA	MOVE.B	(A0)+,D0
	EXT.W	D0
	SWAP	D0
	CLR.W	D0
	MOVE.L	D0,D1
	SUB.L	D2,D1
	SUB.L	D3,D1
	SWAP	D1
	CMP.W	#$7F,D1
	BLE.S	lbC000616
	MOVE.L	#$7F,D1
lbC000616	CMP.W	#$FF80,D1
	BGE.S	lbC000622
	MOVE.L	#$FF80,D1
lbC000622	MOVE.B	D1,(A1)+
	SWAP	D1
	MOVE.L	D1,D4
	ASR.L	#8,D4
	MOVEM.L	D2/D5,-(SP)
	MOVEQ	#0,D2
	TST.L	D4
	BPL.S	lbC000638
	NEG.L	D4
	ADDQ.W	#1,D2
lbC000638	TST.L	D5
	BPL.S	lbC000640
	NEG.L	D5
	SUBQ.W	#1,D2
lbC000640	MOVEM.L	D2/D3,-(SP)
	MOVE.L	D4,D2
	MOVE.L	D5,D3
	SWAP	D2
	SWAP	D3
	MULU	D5,D2
	MULU	D4,D3
	MULU	D5,D4
	ADD.W	D3,D2
	SWAP	D2
	CLR.W	D2
	ADD.L	D2,D4
	MOVEM.L	(SP)+,D2/D3
	TST.W	D2
	BEQ.S	lbC000666
	NOT.L	D4
	ADDQ.L	#1,D4
lbC000666	MOVEM.L	(SP)+,D2/D5
	ADD.L	D4,D2
	SWAP	D2
	CMP.W	#$7F,D2
	BLE.S	lbC00067A
	MOVE.L	#$7F,D2
lbC00067A	CMP.W	#$FF80,D2
	BGE.S	lbC000686
	MOVE.L	#$FF80,D2
lbC000686	SWAP	D2
	MOVE.L	D2,D4
	ASR.L	#8,D4
	MOVEM.L	D2/D5,-(SP)
	MOVEQ	#0,D2
	TST.L	D4
	BPL.S	lbC00069A
	NEG.L	D4
	ADDQ.W	#1,D2
lbC00069A	TST.L	D5
	BPL.S	lbC0006A2
	NEG.L	D5
	SUBQ.W	#1,D2
lbC0006A2	MOVEM.L	D2/D3,-(SP)
	MOVE.L	D4,D2
	MOVE.L	D5,D3
	SWAP	D2
	SWAP	D3
	MULU	D5,D2
	MULU	D4,D3
	MULU	D5,D4
	ADD.W	D3,D2
	SWAP	D2
	CLR.W	D2
	ADD.L	D2,D4
	MOVEM.L	(SP)+,D2/D3
	TST.W	D2
	BEQ.S	lbC0006C8
	NOT.L	D4
	ADDQ.L	#1,D4
lbC0006C8	MOVEM.L	(SP)+,D2/D5
	ADD.L	D4,D3
	SWAP	D3
	CMP.W	#$7F,D3
	BLE.S	lbC0006DC
	MOVE.L	#$7F,D3
lbC0006DC	CMP.W	#$FF80,D3
	BGE.S	lbC0006E8
	MOVE.L	#$FF80,D3
lbC0006E8	MOVE.B	D3,(A3)+
	SWAP	D3
	DBRA	D7,lbC0005FA
	DBRA	D6,lbC0005EC
	ADD.L	#9,D5
	ADDQ.W	#1,$56A(A6)
	CMP.W	#$1F,$56A(A6)
	BLT	lbC0005DC
lbC000708	MOVE.L	BSS_P(PC),A6
	MOVE.B	#$40,1(A6)
	MOVE.L	A6,A0
	ADD.L	#$31AF4,A0
	MOVE.L	A0,$55A(A6)
	MOVE.L	A6,A0
	ADD.L	#$31BF0,A0
	MOVE.L	A0,$55E(A6)
	MOVE.L	A6,A0
	ADD.L	#$32CEC,A0
	MOVE.L	A0,$566(A6)
	MOVE.L	BSS_C(PC),A5
	MOVE.L	BSS_P(PC),A6
	MOVEQ	#14,D0
	LEA	0(A5),A3
	MOVEQ	#3,D7
lbC000746	MOVE.L	A3,$5C(A6,D0.W)
	ADD.W	#$280,A3
	ADD.W	#$E8,D0
	DBRA	D7,lbC000746
	LEA	$DFF000,A5
	MOVE.W	#15,$96(A5)
	MOVEQ	#$4F,D7
lbC000764	MOVE.L	4(A5),D0
	AND.L	#$1FF00,D0
lbC00076E	MOVE.L	4(A5),D1
	AND.L	#$1FF00,D1
	CMP.L	D0,D1
	BEQ.S	lbC00076E
	DBRA	D7,lbC000764
	LEA	14(A6),A0
	LEA	$A0(A5),A3
	MOVEQ	#3,D7
lbC00078A	MOVE.W	#$88,6(A3)
	MOVE.L	$5C(A0),(A3)
	MOVE.W	#$140,4(A3)
	MOVE.W	#0,8(A3)
	ADD.W	#$E8,A0
	ADD.W	#$10,A3
	DBRA	D7,lbC00078A
	MOVE.W	#$800F,$96(A5)
	BSET	#1,$BFE001
	MOVE.W	#$FF,$DFF09E
	LEA	lbL00174E(PC),A0
	LEA	$3C4(A6),A1
	LEA	$404(A6),A2
	MOVEQ	#$10,D7
lbC0007D0	MOVE.W	(A0),(A1)+
	MOVE.W	(A0)+,(A2)+
	DBRA	D7,lbC0007D0
	SUB.W	#2,A0
	MOVEQ	#14,D7
lbC0007DE	MOVE.W	-2(A0),(A1)+
	MOVE.W	-(A0),(A2)+
	DBRA	D7,lbC0007DE
	MOVEQ	#$1F,D7
lbC0007EA	NEG.W	(A1)+
	DBRA	D7,lbC0007EA
	CLR.L	D0
lbC0007F2	MOVEM.L	(SP)+,D1-D7/A0-A6
	RTS

lbC0007F8	MOVEQ	#-1,D0
	BRA.S	lbC0007F2

lbB0007FC	dc.b	0
	dc.b	0
lbB0007FE	dc.b	0
	dc.b	0
lbB000800	dc.b	0
	dc.b	0
lbB000802	dc.b	0
	dc.b	0
	dc.w	0
doslibrary.MSG	dc.b	'dos.library',0
SahxWavesLoca.MSG	dc.b	'S:ahxWaves.Location',0,0
	dc.b	$40

InitModule	MOVEM.L	D2-D7/A0-A6,-(SP)
	LEA	lbC000000(PC),A5
	MOVE.L	A0,modulePointer-lbC000000(A5)
	MOVE.L	BSS_P(PC),A6
	MOVE.B	3(A0),$444(A6)
	MOVE.L	(A0)+,D1
	CLR.B	D1
	CMP.L	#$54485800,D1
	BNE	lbC0008FA
	ADDQ.W	#2,A0
	MOVE.W	(A0)+,D1
	BTST	#15,D1
	SNE	13(A6)
	MOVE.W	D1,D3
	ROL.W	#3,D3
	AND.W	#3,D3
	BNE.S	lbC00086E
	MOVE.B	lbL00003C(PC),D7
	BEQ.S	lbC00087A
	BSR	lbC0001D6
	BRA.S	lbC00087A

lbC00086E	MOVE.B	lbL00003C(PC),D7
	BEQ	lbC0008FE
	BSR	lbC0001D6
lbC00087A	MOVE.W	D3,6(A6)
	AND.W	#$3FF,D1
	MOVE.W	D1,$450(A6)
	MOVE.W	(A0)+,$44E(A6)
	MOVE.B	(A0)+,$3AF(A6)
	MOVE.B	(A0)+,$449(A6)
	MOVE.B	(A0)+,$447(A6)
	MOVEQ	#0,D1
	MOVE.B	(A0)+,D1
	MOVE.B	D1,2(A6)
	BEQ.S	lbC0008AA
	MOVE.L	A0,$556(A6)
	MOVE.W	D1,D3
	ADD.W	D3,D3
	ADD.W	D3,A0
lbC0008AA	MOVE.L	A0,$452(A6)
	MOVE.W	$450(A6),D3
	LSL.W	#3,D3
	ADD.W	D3,A0
	MOVE.L	A0,$456(A6)
	MOVE.W	$448(A6),D7	 
	TST.B	13(A6)
	BNE.S	lbC0008C6
	ADDQ.W	#1,D7
lbC0008C6	MOVE.W	$3AE(A6),D3
	MULU	#3,D3
	MULU	D7,D3
	ADD.L	D3,A0
	LEA	$45A(A6),A2
	MOVE.W	$446(A6),D7
	BEQ.S	lbC0008F2
	SUBQ.W	#1,D7
lbC0008DE	MOVE.L	A0,(A2)+
	MOVEQ	#0,D3
	MOVE.B	$15(A0),D3
	ADD.W	#$16,A0
	LSL.W	#2,D3
	ADD.W	D3,A0
	DBRA	D7,lbC0008DE
lbC0008F2	CLR.L	D0
lbC0008F4	MOVEM.L	(SP)+,D2-D7/A0-A6
	RTS

lbC0008FA	MOVEQ	#-1,D0
	BRA.S	lbC0008F4

lbC0008FE	MOVEQ	#-2,D0
	BRA.S	lbC0008F4

InitSubSong	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	BSS_P(PC),A6
	BTST	#15,D0
	BEQ.S	lbC000916
	BCLR	#15,D0
	BRA.S	lbC000926

lbC000916	TST.W	D0
	BEQ.S	lbC000926
	MOVE.L	$556(A6),A3
	SUBQ.W	#1,D0
	ADD.W	D0,D0
	MOVE.W	0(A3,D0.W),D0
lbC000926	MOVE.W	D0,$44C(A6)
	CLR.W	$3BC(A6)
	MOVE.W	#6,$3B4(A6)
	CLR.W	$3B0(A6)
	ST	$3B2(A6)
	SF	3(A6)
	CLR.B	0(A6)
	CLR.L	8(A6)
	CLR.W	$44A(A6)
	MOVEQ	#3,D6
	LEA	14(A6),A0
lbC000952	BSR	lbC00096C
	ADD.W	#$E8,A0
	DBRA	D6,lbC000952
	MOVEM.L	(SP)+,D0-D7/A0-A5
	TST.B	D1
	SEQ	4(A6)
	MOVE.L	(SP)+,A6
	RTS

lbC00096C	MOVE.W	#$E7,D7
	MOVE.L	A0,A1
	MOVE.B	$27(A1),D0
	MOVE.L	$5C(A1),-(SP)
lbC00097A	CLR.B	(A0)+
	DBRA	D7,lbC00097A
	MOVE.W	#$40,$20(A1)
	MOVE.B	D0,$27(A1)
	MOVE.L	(SP)+,$5C(A1)
	MOVE.L	A1,A0
	RTS

StopSong	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	BSS_P(PC),A6
	SF	4(A6)
	CLR.W	$DFF0A8
	CLR.W	$DFF0B8
	CLR.W	$DFF0C8
	CLR.W	$DFF0D8
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

NextPattern	MOVE.L	BSS_P(PC),A6
	MOVE.W	$44C(A6),$3BC(A6)
	ADDQ.W	#1,$3BC(A6)
	ST	$3B6(A6)
	RTS

PrevPattern	MOVE.L	BSS_P(PC),A6
	MOVE.W	$44C(A6),$3BC(A6)
	SUBQ.W	#1,$3BC(A6)
	BPL.S	lbC0009E4
	CLR.W	$3BC(A6)
lbC0009E4	ST	$3B6(A6)
	RTS

*  A1 = is_data = $BFE001
Interrupt	MOVEM.L	D0-D7/A0-A6,-(SP)
	MOVE.L	BSS_P(PC),D6
	BEQ	lbC000B06
	MOVE.L	D6,A6
	TST.W	4(A6)
	BEQ	lbC000B06
	LEA	$DFF000,A5
	LEA	14(A6),A0
	LEA	$A0(A5),A3
	MOVEQ	#3,D7
lbC000A10	BSR	lbC001650
	ADD.W	#$E8,A0
	ADD.W	#$10,A3
	DBRA	D7,lbC000A10
	TST.W	$3B0(A6)
	BNE	lbC000A94
	TST.B	$3B2(A6)
	BEQ	lbC000A7C
	MOVE.L	$452(A6),A3
	MOVE.W	$44C(A6),D2		* current position
	MOVE.W	D2,D3
	ADDQ.W	#1,D3
	CMP.W	$450(A6),D3		 * max position
	BNE.S	lbC000A44
	CLR.W	D3
lbC000A44	LSL.W	#3,D2
	MOVE.W	0(A3,D2.W),14(A6)
	MOVE.W	2(A3,D2.W),$F6(A6)
	MOVE.W	4(A3,D2.W),$1DE(A6)
	MOVE.W	6(A3,D2.W),$2C6(A6)
	LSL.W	#3,D3
	MOVE.W	0(A3,D3.W),$10(A6)
	MOVE.W	2(A3,D3.W),$F8(A6)
	MOVE.W	4(A3,D3.W),$1E0(A6)
	MOVE.W	6(A3,D3.W),$2C8(A6)
	SF	$3B2(A6)
lbC000A7C	MOVEQ	#3,D7
	LEA	14(A6),A0
lbC000A82	BSR	lbC000B0C
	ADD.W	#$E8,A0
	DBRA	D7,lbC000A82
	MOVE.W	$3B4(A6),$3B0(A6)
lbC000A94	MOVEQ	#3,D7
	LEA	14(A6),A0
lbC000A9A	BSR	lbC000F64
	ADD.W	#$E8,A0
	DBRA	D7,lbC000A9A
	ADDQ.L	#1,8(A6)
	SUBQ.W	#1,$3B0(A6)
	BNE	lbC000B06
	TST.B	$3B6(A6)
	BNE	lbC000AD6
	ADDQ.W	#1,$44A(A6)	* increment pattpos
	MOVE.W	$3AE(A6),D0	* patt length
	CMP.W	$44A(A6),D0	* at the end of pattern?
	BNE	lbC000B06
	MOVE.W	$44C(A6),$3BC(A6)
	ADD.W	#1,$3BC(A6)	* increment songpos
lbC000AD6	SF	$3B6(A6)
	MOVE.W	$3BE(A6),$44A(A6)
	CLR.W	$3BE(A6)
	MOVE.W	$3BC(A6),$44C(A6)
	CLR.W	$3BC(A6)
	MOVE.W	$44C(A6),D0	* current songpos
	CMP.W	$450(A6),D0 * max pos
	BNE.S	lbC000B02
	ST	3(A6)			* song end!
	MOVE.W	$44E(A6),$44C(A6)
lbC000B02	ST	$3B2(A6)
lbC000B06	MOVEM.L	(SP)+,D0-D7/A0-A6
bailOut
		RTS

; Get new note
lbC000B0C	TST.B	$27(A0)
	BNE	lbC000F62
	CLR.B	$29(A0)
	CLR.B	$2A(A0)
	MOVEQ	#0,D0
	MOVE.B	0(A0),D0
	TST.B	13(A6)
	BEQ.S	lbC000B30
	SUBQ.W	#1,D0
	BGE.S	lbC000B30

	MOVEQ	#0,D1
	
	; FIX enforcer hit
	MOVE.L	$456(A6),A1
	
	BRA.S	lbC000B4C

; Read note data
lbC000B30	MOVE.L	$456(A6),A1
	; Get track
	MOVE.W	$3AE(A6),D1
	MULU	D1,D0
	; Get current position in the track
	ADD.W	$44A(A6),D0
	MULU	#3,D0
	MOVE.B	0(A1,D0.L),D1
	ROR.W	#8,D1
	MOVE.B	1(A1,D0.L),D1
lbC000B4C	MOVE.W	D1,D3
	MOVE.W	D1,D2
	AND.W	#15,D2
	CMP.W	#14,D2
	BNE.S	lbC000BA4
	MOVEQ	#0,D5
	MOVE.B	2(A1,D0.L),D5
	MOVE.W	D5,D6
	LSR.W	#4,D5
	AND.W	#15,D6
	CMP.W	#12,D5
	BNE.S	lbC000B82
	CMP.B	$3B5(A6),D6
	BGE.S	lbC000B82
	MOVE.B	D6,$5A(A0)
	BEQ.S	lbC000B82
	ST	$5B(A0)
	SF	$2C(A0)
lbC000B82	CMP.W	#13,D5
	BNE.S	lbC000BA4
	TST.B	$59(A0)
	BNE.S	lbC000BA0
	CMP.B	$3B5(A6),D6
	BGE.S	lbC000BA4
	MOVE.B	D6,$58(A0)
	BEQ.S	lbC000BA4
	ST	$59(A0)
	RTS

lbC000BA0	SF	$59(A0)
lbC000BA4	TST.W	D2
	BNE.S	lbC000BC0
	* ENFORCER HITS
	* A1 can be BFE001
	TST.B	2(A1,D0.L)	
	BEQ.S	lbC000BC0
	MOVE.B	2(A1,D0.L),D5
	AND.W	#15,D5
	CMP.W	#9,D5
	BGT.S	lbC000BC0
	MOVE.W	D5,$3BC(A6)
lbC000BC0	CMP.W	#8,D2
	BNE.S	lbC000BCC
	MOVE.B	2(A1,D0.L),0(A6)
lbC000BCC	CMP.W	#13,D2
	BNE.S	lbC000C06
	MOVE.W	$44C(A6),$3BC(A6)
	ADDQ.W	#1,$3BC(A6)
	MOVE.B	2(A1,D0.L),D5
	MOVE.B	D5,D6
	AND.B	#15,D6
	LSR.B	#4,D5
	EXT.W	D5
	MULU	#10,D5
	ADD.B	D5,D6
	MOVE.B	D6,$3BF(A6)
	MOVE.W	$3AE(A6),D6
	CMP.W	$3BE(A6),D6
	BGT.S	lbC000C02
	CLR.W	$3BE(A6)
lbC000C02	ST	$3B6(A6)
lbC000C06	CMP.W	#11,D2
	BNE.S	lbC000C34
	MOVE.W	$3BC(A6),D5
	MULU	#$64,D5
	MOVE.B	2(A1,D0.L),D6
	AND.W	#15,D6
	ADD.W	D6,D5
	MOVEQ	#0,D6
	MOVE.B	2(A1,D0.L),D6
	LSR.W	#4,D6
	MULU	#10,D6
	ADD.W	D6,D5
	MOVE.W	D5,$3BC(A6)
	ST	$3B6(A6)
lbC000C34	CMP.W	#15,D2
	BNE.S	lbC000C40
	MOVE.B	2(A1,D0.L),$3B5(A6)
lbC000C40	CMP.W	#5,D2
	BEQ.S	lbC000C4C
	CMP.W	#10,D2
	BNE.S	lbC000C60
lbC000C4C	MOVE.B	2(A1,D0.L),D5
	MOVE.B	D5,D6
	AND.B	#15,D6
	MOVE.B	D6,$2A(A0)
	LSR.B	#4,D5
	MOVE.B	D5,$29(A0)
lbC000C60	AND.W	#$3F0,D3
	LSR.W	#4,D3
	SUBQ.W	#1,D3
	BMI	lbC000DD4
	MOVE.W	#$40,$1E(A0)
	CLR.W	$2E(A0)
	CLR.W	$30(A0)
	CLR.W	$32(A0)
	CLR.W	4(A0)
	LEA	$45A(A6),A3
	LSL.W	#2,D3
	MOVE.L	0(A3,D3.W),D3
	BEQ	lbC000DD4
	MOVE.L	D3,A3
	MOVE.L	D1,-(SP)
	MOVEQ	#0,D1
	MOVE.B	2(A3),D1
	MOVE.B	D1,6(A0)
	MOVEQ	#0,D4
	MOVE.B	3(A3),D4
	LSL.W	#8,D4
	tst	d1
	bne.b	.skip
	moveq	#1,d1
.skip
	DIVU	D1,D4  * DIVISION by null possible
	MOVE.W	D4,10(A0)
	MOVEQ	#0,D1
	MOVE.B	4(A3),D1
	MOVE.B	D1,7(A0)
	MOVE.B	5(A3),D4
	SUB.B	3(A3),D4
	EXT.W	D4
	ASL.W	#8,D4
	EXT.L	D4
	tst	d1
	bne.b	.skip2
	moveq	#1,d1
.skip2
	DIVS	D1,D4 * DIVISION by null possible
	MOVE.W	D4,12(A0)
	MOVE.B	6(A3),8(A0)
	MOVEQ	#0,D1
	MOVE.B	7(A3),D1
	MOVE.B	D1,9(A0)
	MOVE.B	8(A3),D4
	SUB.B	5(A3),D4
	EXT.W	D4
	ASL.W	#8,D4
	EXT.L	D4
	DIVS	D1,D4
	MOVE.W	D4,14(A0)
	MOVE.B	1(A3),D1
	AND.B	#7,D1
	MOVE.B	D1,$15(A0)
	MOVE.B	0(A3),$1D(A0)
	CLR.B	$3C(A0)
	MOVE.B	13(A3),$3B(A0)
	MOVE.B	14(A3),$3D(A0)
	AND.B	#15,$3D(A0)
	MOVE.B	15(A3),$3E(A0)
	CLR.W	$1A(A0)
	MOVE.B	14(A3),D6
	BTST	#7,D6
	SNE	$2C(A0)
	AND.B	#$70,D6
	LSR.B	#4,D6
	MOVE.B	D6,$2B(A0)
	SF	$25(A0)
	SF	$46(A0)
	CLR.B	$41(A0)
	CLR.B	$3F(A0)
	MOVEQ	#5,D6
	SUB.B	D1,D6
	MOVE.B	$10(A3),D3
	LSR.B	D6,D3
	MOVE.B	$11(A3),D4
	LSR.B	D6,D4
	CMP.B	D4,D3
	BLE.S	lbC000D5C
	EXG	D3,D4
lbC000D5C	MOVE.B	D3,$42(A0)
	MOVE.B	D4,$43(A0)
	SF	$50(A0)
	CLR.B	$49(A0)
	CLR.B	$47(A0)
	SF	$4F(A0)
	MOVE.B	1(A3),D6
	LSR.B	#3,D6
	MOVE.B	12(A3),D3
	MOVE.B	$13(A3),D4
	BTST	#7,D3
	BEQ.S	lbC000D8C
	BSET	#5,D6
lbC000D8C	BTST	#7,D4
	BEQ.S	lbC000D96
	BSET	#6,D6
lbC000D96	MOVE.B	D6,$4E(A0)
	BCLR	#7,D3
	BCLR	#7,D4
	CMP.B	D4,D3
	BLE.S	lbC000DA8
	EXG	D3,D4
lbC000DA8	MOVE.B	D3,$4A(A0)
	MOVE.B	D4,$4B(A0)
	MOVE.B	#$20,$4C(A0)
	CLR.B	$53(A0)
	MOVE.B	$14(A3),$52(A0)
	CLR.B	$51(A0)
	MOVE.L	A3,$10(A0)
	ADD.L	#$16,A3
	MOVE.L	A3,$54(A0)
	MOVE.L	(SP)+,D1
lbC000DD4	CMP.W	#9,D2
	BNE.S	lbC000DF2
	MOVE.B	2(A1,D0.L),D5
	MOVEQ	#5,D6
lbC000DE0	SUB.B	$15(A0),D6
	LSR.B	D6,D5
	MOVE.B	D5,$44(A0)
	ST	$23(A0)
	ST	$25(A0)
lbC000DF2	CMP.W	#4,D2
	BNE.S	lbC000E16
	TST.B	$444(A6)
	BEQ.S	lbC000E16
	MOVE.B	2(A1,D0.L),D5
	CMP.B	#$40,D5
	BGE.S	lbC000E0E
	MOVE.B	D5,$50(A0)
	BRA.S	lbC000E16

lbC000E0E	SUB.B	#$40,D5
	MOVE.B	D5,$4C(A0)
lbC000E16	SF	$34(A0)
	CMP.W	#5,D2
	BEQ.S	lbC000E36
	CMP.W	#3,D2
	BNE	lbC000E6E
	MOVEQ	#0,D5
	MOVE.B	2(A1,D0.L),D5
	BEQ	lbC000E36
	MOVE.W	D5,$2E(A0)
lbC000E36	MOVE.W	D1,D4
	ROL.W	#6,D4
	AND.W	#$3F,D4
	BEQ.S	lbC000E64
	MOVE.W	$18(A0),D6
	LEA	lbW0016D4(PC),A3
	ADD.W	D4,D4
	ADD.W	D6,D6
	MOVE.W	0(A3,D4.W),D4
	MOVE.W	0(A3,D6.W),D6
	SUB.W	D4,D6
	MOVE.W	D6,D4
	ADD.W	$30(A0),D4
	BEQ.S	lbC000E6E
	NEG.W	D6
	MOVE.W	D6,$32(A0)
lbC000E64	ST	$34(A0)
	ST	$35(A0)
	BRA.S	lbC000E7E

lbC000E6E	ROL.W	#6,D1
	AND.W	#$3F,D1
	BEQ.S	lbC000E7E
	MOVE.W	D1,$18(A0)
	ST	$26(A0)
lbC000E7E	CMP.W	#1,D2
	BNE.S	lbC000E98
	MOVEQ	#0,D5
	MOVE.B	2(A1,D0.L),D5
	NEG.W	D5
	MOVE.W	D5,$2E(A0)
	ST	$34(A0)
	SF	$35(A0)
lbC000E98	CMP.W	#2,D2
	BNE.S	lbC000EB0
	MOVEQ	#0,D5
	MOVE.B	2(A1,D0.L),D5
	MOVE.W	D5,$2E(A0)
	ST	$34(A0)
	SF	$35(A0)
lbC000EB0	CMP.W	#14,D2
	BNE	lbC000F1C
	MOVEQ	#0,D5
	MOVE.B	2(A1,D0.L),D5
	MOVE.W	D5,D6
	LSR.W	#4,D5
	AND.W	#15,D6
	CMP.W	#1,D5
	BNE.S	lbC000ED8
	NEG.W	D6
	ADD.W	D6,$30(A0)
	ST	$26(A0)
	BRA.S	lbC000F1C

lbC000ED8	CMP.W	#2,D5
	BNE.S	lbC000EE8
	ADD.W	D6,$30(A0)
	ST	$26(A0)
	BRA.S	lbC000F1C

lbC000EE8	CMP.W	#4,D5
	BNE.S	lbC000EF2
	MOVE.B	D6,$3D(A0)
lbC000EF2	CMP.W	#10,D5
	BNE.S	lbC000F0C
	ADD.B	D6,$1D(A0)
	CMP.B	#$40,$1D(A0)
	BLE.S	lbC000F1C
	MOVE.B	#$40,$1D(A0)
	BRA.S	lbC000F1C

lbC000F0C	CMP.W	#11,D5
	BNE.S	lbC000F1C
	SUB.B	D6,$1D(A0)
	BGE.S	lbC000F1C
	CLR.B	$1D(A0)
lbC000F1C	CMP.W	#12,D2
	BNE.S	lbC000F62
	MOVEQ	#0,D1
	MOVE.B	2(A1,D0.L),D1
	CMP.W	#$40,D1
	BLE.S	lbC000F5E
	SUB.W	#$50,D1
	BMI.S	lbC000F62
	CMP.W	#$40,D1
	BLE.S	lbC000F4C
	SUB.W	#$50,D1
	BMI.S	lbC000F62
	CMP.W	#$40,D1
	BGT.S	lbC000F62
	MOVE.B	D1,$21(A0)
	BRA.S	lbC000F62

lbC000F4C	MOVE.B	D1,$2F(A6)
	MOVE.B	D1,$117(A6)
	MOVE.B	D1,$1FF(A6)
	MOVE.B	D1,$2E7(A6)
	BRA.S	lbC000F62

lbC000F5E	MOVE.B	D1,$1D(A0)
lbC000F62	RTS

lbC000F64	TST.B	$27(A0)
	BNE	lbC0014F2
	TST.B	$2B(A0)
	BEQ	lbC000FDE
	MOVEQ	#0,D0
	MOVE.B	0(A0),D0
	MOVE.W	$44A(A6),D1
	ADDQ.W	#1,D1
	CMP.W	$3AE(A6),D1
	BNE.S	lbC000F8C
	MOVEQ	#0,D1
	MOVE.B	2(A0),D0
lbC000F8C	TST.B	13(A6)
	BEQ.S	lbC000F96
	SUBQ.W	#1,D0
	BMI.S	lbC000FDE
lbC000F96	MOVE.L	$456(A6),A1
	MOVE.W	$3AE(A6),D2
	MULU	D2,D0
	ADD.W	D1,D0
	MULU	#3,D0
	MOVE.B	0(A1,D0.L),D1
	LSL.W	#8,D1
	MOVE.B	1(A1,D0.L),D1
	AND.W	#$3F0,D1
	BEQ.S	lbC000FDE
	MOVE.W	$3B4(A6),D1
	SUB.B	$2B(A0),D1
	BPL.S	lbC000FC2
	MOVEQ	#0,D1
lbC000FC2	TST.B	$5B(A0)
	BNE.S	lbC000FDA
	ST	$5B(A0)
	MOVE.B	D1,$5A(A0)
	SUB.B	$3B5(A6),D1
	NEG.B	D1
	MOVE.B	D1,$2D(A0)
lbC000FDA	SF	$2B(A0)
lbC000FDE	TST.B	$5B(A0)
	BEQ.S	lbC001032
	TST.B	$5A(A0)
	BNE.S	lbC00102C
	SF	$5B(A0)
	TST.B	$2C(A0)
	BEQ.S	lbC001026
	MOVE.W	4(A0),D0
	MOVE.L	$10(A0),A3
	MOVE.B	8(A3),D1
	LSL.W	#8,D1
	SUB.W	D1,D0
	EXT.L	D0
	MOVE.B	$2D(A0),D1
	MOVE.B	D1,9(A0)
	EXT.W	D1
	DIVS	D1,D0
	NEG.W	D0
	MOVE.W	D0,14(A0)
	CLR.B	6(A0)
	CLR.B	7(A0)
	CLR.B	8(A0)
	BRA.S	lbC00102C

lbC001026	MOVE.W	#0,$1C(A0)
lbC00102C	SUB.B	#1,$5A(A0)
lbC001032	TST.B	$59(A0)
	BEQ.S	lbC00104A
	TST.B	$58(A0)
	BNE.S	lbC001044
	BSR	lbC000B0C
	BRA.S	lbC00104A

lbC001044	SUB.B	#1,$58(A0)
lbC00104A	MOVE.L	$10(A0),A3
	TST.B	6(A0)
	BEQ.S	lbC001072
	MOVE.W	10(A0),D0
	ADD.W	D0,4(A0)
	SUB.B	#1,6(A0)
	BNE	lbC0010C2
	MOVE.B	3(A3),D0
	LSL.W	#8,D0
	MOVE.W	D0,4(A0)
	BRA.S	lbC0010C2

lbC001072	TST.B	7(A0)
	BEQ.S	lbC001094
	MOVE.W	12(A0),D0
	ADD.W	D0,4(A0)
	SUB.B	#1,7(A0)
	BNE.S	lbC0010C2
	MOVE.B	5(A3),D0
	LSL.W	#8,D0
	MOVE.W	D0,4(A0)
	BRA.S	lbC0010C2

lbC001094	TST.B	8(A0)
	BEQ.S	lbC0010A2
	SUB.B	#1,8(A0)
	BRA.S	lbC0010C2

lbC0010A2	TST.B	9(A0)
	BEQ.S	lbC0010C2
	MOVE.W	14(A0),D0
	ADD.W	D0,4(A0)
	SUB.B	#1,9(A0)
	BNE.S	lbC0010C2
	MOVE.B	8(A3),D0
	LSL.W	#8,D0
	MOVE.W	D0,4(A0)
lbC0010C2	MOVE.B	$1D(A0),D0
	SUB.B	$2A(A0),D0
	ADD.B	$29(A0),D0
	BPL.S	lbC0010D2
	MOVEQ	#0,D0
lbC0010D2	CMP.B	#$40,D0
	BLE.S	lbC0010DC
	MOVE.B	#$40,D0
lbC0010DC	MOVE.B	D0,$1D(A0)
	TST.B	$34(A0)
	BEQ.S	lbC00111E
	MOVE.W	$30(A0),D0
	MOVE.W	$2E(A0),D2
	TST.B	$35(A0)
	BEQ.S	lbC001110
	MOVE.W	$32(A0),D1
	SUB.W	D1,D0
	BEQ.S	lbC00111E
	BMI.S	lbC001100
	NEG.W	D2
lbC001100	MOVE.W	D0,D3
	ADD.W	D2,D3
	EOR.W	D0,D3
	BTST	#15,D3
	BNE.S	lbC001114
	MOVE.W	$30(A0),D0
lbC001110	ADD.W	D2,D0
	BRA.S	lbC001116

lbC001114	MOVE.W	D1,D0
lbC001116	MOVE.W	D0,$30(A0)
	ST	$26(A0)
lbC00111E	MOVEQ	#0,D0
	MOVE.B	$3D(A0),D0
	BEQ.S	lbC001168
	TST.B	$3B(A0)
	BEQ.S	lbC001134
	SUB.B	#1,$3B(A0)
	BRA.S	lbC001168

lbC001134	MOVEQ	#0,D1
	MOVE.B	$3C(A0),D1
	ADD.W	D1,D1
	ADD.W	#$3C4,D1
	MOVE.W	0(A6,D1.W),D1
	MULS	D0,D1
	MOVE.L	D1,D2
	SWAP	D2
	AND.W	#$8000,D2
	ASR.W	#7,D1
	OR.W	D2,D1
	MOVE.W	D1,$1A(A0)
	ST	$26(A0)
	MOVE.B	$3E(A0),D1
	ADD.B	D1,$3C(A0)
	AND.B	#$3F,$3C(A0)
lbC001168	MOVE.L	$10(A0),A3
	TST.L	$10(A0)
	BEQ	lbC001218
	MOVE.B	$15(A3),D5
	CMP.B	$51(A0),D5
	BEQ	lbC001206
	SUB.B	#1,$53(A0)
	BGT	lbC001204
	MOVE.L	$54(A0),A2
	MOVE.W	(A2),D0
	LSR.W	#7,D0
	AND.W	#7,D0
	BEQ.S	lbC0011AC
	SUB.B	#1,D0
	MOVE.B	D0,$14(A0)
	ST	$22(A0)
	CLR.W	$36(A0)
	CLR.W	$38(A0)
lbC0011AC	SF	$3A(A0)
	MOVE.W	(A2),D0
	MOVE.L	A2,-(SP)
	ADDQ.W	#2,A2
	MOVE.W	D0,D1
	ROL.W	#6,D0
	AND.L	#7,D0
	BSR	lbC001500
	ADDQ.W	#1,A2
	ROL.W	#3,D1
	AND.L	#7,D1
	MOVE.L	D1,D0
	BSR	lbC001500
	MOVE.L	(SP)+,A2
	MOVE.W	(A2),D0
	MOVE.W	D0,D1
	AND.W	#$3F,D0
	BEQ.S	lbC0011F0
	MOVE.W	D0,$16(A0)
	ST	$26(A0)
	BTST	#6,D1
	SNE	$28(A0)
lbC0011F0	ADD.L	#4,$54(A0)
	ADD.B	#1,$51(A0)
	MOVE.B	$52(A0),$53(A0)
lbC001204	BRA.S	lbC001218

lbC001206	TST.B	$53(A0)
	BNE.S	lbC001212
	CLR.W	$36(A0)
	BRA.S	lbC001218

lbC001212	SUB.B	#1,$53(A0)
lbC001218	TST.B	$3A(A0)
	BEQ.S	lbC001230
	MOVE.W	$38(A0),D0
	SUB.W	$36(A0),D0
	MOVE.W	D0,$38(A0)
	BEQ.S	lbC001230
	ST	$26(A0)
lbC001230	CMP.B	#2,$14(A0)
	BNE	lbC0012B0
	TST.B	$3F(A0)
	BEQ	lbC0012B0
	SUB.B	#1,$41(A0)
	BGT	lbC0012B0
	MOVE.B	$42(A0),D1
	MOVE.B	$43(A0),D2
	MOVE.B	$44(A0),D3
	TST.B	$40(A0)
	BEQ.S	lbC001282
	SF	$40(A0)
	CMP.B	D1,D3
	BLE.S	lbC00126C
	CMP.B	D2,D3
	BGE.S	lbC001278
	BRA.S	lbC001282

lbC00126C	ST	$46(A0)
	MOVE.B	#1,$45(A0)
	BRA.S	lbC001282

lbC001278	ST	$46(A0)
	MOVE.B	#$FF,$45(A0)
lbC001282	CMP.B	D1,D3
	BEQ.S	lbC00128A
	CMP.B	D2,D3
	BNE.S	lbC00129A
lbC00128A	TST.B	$46(A0)
	BEQ.S	lbC001296
	SF	$46(A0)
	BRA.S	lbC00129A

lbC001296	NEG.B	$45(A0)
lbC00129A	ADD.B	$45(A0),D3
	MOVE.B	D3,$44(A0)
	ST	$23(A0)
	MOVE.L	$10(A0),A3
	MOVE.B	$12(A3),$41(A0)
lbC0012B0	TST.B	$47(A0)
	BEQ	lbC001346
	SUB.B	#1,$49(A0)
	BGT	lbC001346
	MOVE.B	$4A(A0),D1
	MOVE.B	$4B(A0),D2
	MOVE.B	$4C(A0),D3
	TST.B	$48(A0)
	BEQ.S	lbC0012F8
	SF	$48(A0)
	CMP.B	D1,D3
	BLE.S	lbC0012E2
	CMP.B	D2,D3
	BGE.S	lbC0012EE
	BRA.S	lbC0012F8

lbC0012E2	ST	$4F(A0)
	MOVE.B	#1,$4D(A0)
	BRA.S	lbC0012F8

lbC0012EE	ST	$4F(A0)
	MOVE.B	#$FF,$4D(A0)
lbC0012F8	MOVEQ	#0,D5
	MOVE.B	$4E(A0),D4
	CMP.B	#4,D4
	BGE.S	lbC001308
	MOVEQ	#4,D5
	SUB.B	D4,D5
lbC001308	CMP.B	D1,D3
	BEQ.S	lbC001310
	CMP.B	D2,D3
	BNE.S	lbC001320
lbC001310	TST.B	$4F(A0)
	BEQ.S	lbC00131C
	SF	$4F(A0)
	BRA.S	lbC001320

lbC00131C	NEG.B	$4D(A0)
lbC001320	ADD.B	$4D(A0),D3
	DBRA	D5,lbC001308
	MOVE.B	D3,$4C(A0)
	ST	$22(A0)
	MOVE.B	$4E(A0),D1
	SUB.B	#3,D1
	CMP.B	#1,D1
	BGE.S	lbC001342
	MOVE.B	#1,D1
lbC001342	MOVE.B	D1,$49(A0)
lbC001346	CMP.B	#2,$14(A0)
	BEQ.S	lbC001356
	TST.B	$23(A0)
	BEQ	lbC0013D8
lbC001356	MOVE.L	A6,A3
	ADD.L	#$31CEC,A3
	MOVE.B	$4C(A0),D3
	EXT.W	D3
	SUB.W	#$20,D3
	EXT.L	D3
	MULS	#$1978,D3
	ADD.L	D3,A3
	MOVEQ	#0,D1
	MOVE.B	$44(A0),D1
	MOVEQ	#5,D2
	SUB.B	$15(A0),D2
	LSL.B	D2,D1
	CMP.W	#$20,D1
	BLE.S	lbC001390
	MOVE.W	#$40,D2
	SUB.W	D1,D2
	MOVE.W	D2,D1
	ST	$24(A0)
lbC001390	SUBQ.W	#1,D1
	BGE.S	lbC001396
	CLR.W	D1
lbC001396	LSL.W	#7,D1
	ADD.W	D1,A3
	LEA	$68(A0),A2
	MOVE.L	A2,$562(A6)
	MOVEQ	#0,D2
	MOVE.B	$15(A0),D2
	MOVE.W	#$20,D5
	LSR.W	D2,D5
	MOVEQ	#1,D6
	LSL.B	D2,D6
	SUBQ.W	#1,D6
lbC0013B4	MOVE.B	(A3),D2
	ADD.W	D5,A3
	LSL.W	#8,D2
	MOVE.B	(A3),D2
	ADD.W	D5,A3
	SWAP	D2
	MOVE.B	(A3),D2
	ADD.W	D5,A3
	LSL.W	#8,D2
	MOVE.B	(A3),D2
	ADD.W	D5,A3
	MOVE.L	D2,(A2)+
	DBRA	D6,lbC0013B4
	ST	$22(A0)
	SF	$23(A0)
lbC0013D8	CMP.B	#3,$14(A0)
	BNE.S	lbC0013E4
	ST	$22(A0)
lbC0013E4	TST.B	$22(A0)
	BEQ	lbC00146C
	MOVEQ	#0,D0
	MOVE.B	$14(A0),D0
	LEA	$55A(A6),A3
	MOVE.W	D0,D1
	LSL.W	#2,D1
	MOVE.L	0(A3,D1.W),A3
	CMP.B	#2,D0
	BEQ.S	lbC001416
	MOVE.B	$4C(A0),D3
	EXT.W	D3
	SUB.W	#$20,D3
	EXT.L	D3
	MULS	#$1978,D3
	ADD.L	D3,A3
lbC001416	CMP.B	#2,D0
	BGE.S	lbC001436
	MOVEQ	#0,D1
	MOVE.B	$15(A0),D1
	ADD.W	D1,D1
	ADD.W	lbW00142A(PC,D1.W),A3
	BRA.S	lbC001436

lbW00142A	dc.w	0
	dc.w	4
	dc.w	12
	dc.w	$1C
	dc.w	$3C
	dc.w	$7C

lbC001436	CMP.B	#3,D0
	BNE.S	lbC001468
	MOVE.L	$3C0(A6),D0
	MOVE.W	D0,D1
	AND.W	#$4FF,D1
	BCLR	#0,D1
	ADD.W	D1,A3
	ADD.L	#$222B98,D0
	ROR.L	#8,D0
	ADD.L	#$BEFF3,D0
	EOR.B	#$4B,D0
	SUB.L	#$1A4F,D0
	MOVE.L	D0,$3C0(A6)
lbC001468	MOVE.L	A3,$60(A0)
lbC00146C	MOVE.W	$16(A0),D1
	TST.B	$28(A0)
	BNE.S	lbC001486
	MOVE.B	1(A0),D2
	EXT.W	D2
	ADD.W	D2,D1
	MOVE.W	$18(A0),D0
	SUBQ.W	#1,D0
	ADD.W	D0,D1
lbC001486	LEA	lbW0016D4(PC),A3
	CMP.W	#$3C,D1
	BLE	lbC001496
	MOVE.W	#$3C,D1
lbC001496	ADD.W	D1,D1
	MOVE.W	0(A3,D1.W),D1
	TST.B	$28(A0)
	BNE.S	lbC0014A6
	ADD.W	$30(A0),D1
lbC0014A6	ADD.W	$38(A0),D1
	ADD.W	$1A(A0),D1
	CMP.W	#$D60,D1
	BLE.S	lbC0014B8
	MOVE.W	#$D60,D1
lbC0014B8	CMP.W	#$71,D1
	BGE.S	lbC0014C2
	MOVE.W	#$71,D1
lbC0014C2	MOVE.W	D1,$64(A0)
	MOVE.B	4(A0),D0
	EXT.W	D0
	MOVE.W	$1C(A0),D1
	MULU	D1,D0
	LSR.W	#6,D0
	MOVE.W	$1E(A0),D1
	MULU	D1,D0
	LSR.W	#6,D0
	MOVE.W	$20(A0),D1
	MULU	D1,D0
	LSR.W	#6,D0
	MOVE.B	1(A6),D1
	EXT.W	D1
	MULU	D1,D0
	LSR.W	#6,D0
	MOVE.W	D0,$66(A0)
lbC0014F2	RTS

	dc.w	$7C
	dc.w	$78
	dc.w	$70
	dc.w	$60
	dc.w	$40
	dc.w	0

lbC001500	TST.W	D0
	BNE.S	lbC00152A
	TST.B	$444(A6)
	BEQ.S	lbC00152A
	MOVE.B	(A2),D5
	BEQ	lbC00164E
	TST.B	$50(A0)
	BEQ.S	lbC00151E
	MOVE.B	$50(A0),D5
	CLR.B	$50(A0)
lbC00151E	MOVE.B	D5,$4C(A0)
	ST	$22(A0)
	BRA	lbC00164E

lbC00152A	SUBQ.W	#1,D0
	BNE.S	lbC00153E
	MOVEQ	#0,D5
	MOVE.B	(A2),D5
	MOVE.W	D5,$36(A0)
	ST	$3A(A0)
	BRA	lbC00164E

lbC00153E	SUBQ.W	#1,D0
	BNE.S	lbC001554
	MOVEQ	#0,D5
	MOVE.B	(A2),D5
	NEG.W	D5
	MOVE.W	D5,$36(A0)
	ST	$3A(A0)
	BRA	lbC00164E

lbC001554	SUBQ.W	#1,D0
	BNE.S	lbC001578
	TST.B	$25(A0)
	BNE.S	lbC001570
	MOVE.B	(A2),D5
	MOVEQ	#5,D6
	SUB.B	$15(A0),D6
	LSR.B	D6,D5
	MOVE.B	D5,$44(A0)
	BRA	lbC00164E

lbC001570	SF	$25(A0)
	BRA	lbC00164E

lbC001578	SUBQ.W	#1,D0
	BNE	lbC0015E0
	TST.B	$444(A6)
	BEQ.S	lbC001588
	MOVE.B	(A2),D5
	BNE.S	lbC00159C
lbC001588	NOT.B	$3F(A0)
	MOVE.B	$3F(A0),$40(A0)
	MOVE.B	#1,$45(A0)
	BRA	lbC00164E

lbC00159C	MOVE.B	D5,D6
	AND.B	#15,D6
	BEQ.S	lbC0015BE
	NOT.B	$3F(A0)
	MOVE.B	$3F(A0),$40(A0)
	MOVE.B	#1,$45(A0)
	CMP.B	#15,D6
	BNE.S	lbC0015BE
	NEG.B	$45(A0)
lbC0015BE	LSR.B	#4,D5
	BEQ.S	lbC0015DC
	NOT.B	$47(A0)
	MOVE.B	$47(A0),$48(A0)
	MOVE.B	#1,$4D(A0)
	CMP.B	#15,D5
	BNE.S	lbC0015DC
	NEG.B	$4D(A0)
lbC0015DC	BRA	lbC00164E

lbC0015E0	SUBQ.W	#1,D0
	BNE.S	lbC001608
	MOVEQ	#0,D5
	MOVE.B	(A2),D5
	MOVE.L	$10(A0),A3
	ADD.L	#$12,A3
	MOVE.W	D5,D2
	SUB.W	#1,D2
	MOVE.B	D2,$51(A0)
	LSL.W	#2,D5
	ADD.W	D5,A3
	MOVE.L	A3,$54(A0)
	BRA	lbC00164E

lbC001608	SUBQ.W	#1,D0
	BNE.S	lbC001642
	MOVEQ	#0,D5
	MOVE.B	(A2),D5
	CMP.W	#$40,D5
	BLE.S	lbC00163A
	SUB.W	#$50,D5
	BMI.S	lbC00163E
	CMP.W	#$40,D5
	BGT.S	lbC001628
	MOVE.B	D5,$1F(A0)
	BRA.S	lbC00163E

lbC001628	SUB.W	#$50,D5
	BMI.S	lbC00163E
	CMP.W	#$40,D5
	BGT.S	lbC00163E
	MOVE.B	D5,$21(A0)
	BRA.S	lbC00163E

lbC00163A	MOVE.B	D5,$1D(A0)
lbC00163E	BRA	lbC00164E

lbC001642	SUBQ.W	#1,D0
	BNE.S	lbC00164E
	MOVE.B	(A2),$52(A0)
	MOVE.B	(A2),$53(A0)
lbC00164E	RTS

lbC001650	TST.B	$27(A0)
	BNE	lbC0016CC
	TST.B	$26(A0)
	BEQ.S	lbC001668
	MOVE.W	$64(A0),6(A3)
	SF	$26(A0)
lbC001668	TST.B	$22(A0)
	BEQ.S	lbC0016C4
	MOVEM.L	D2-D7/A1/A2/A4,-(SP)
	MOVE.L	$5C(A0),A2
	CMP.B	#3,$14(A0)
	BEQ	lbC0016AE
	MOVEQ	#1,D6
	MOVEQ	#5,D2
	SUB.B	$15(A0),D2
	LSL.W	D2,D6
	MULU	#5,D6
	SUBQ.W	#1,D6
lbC001690	MOVE.L	$60(A0),A1
	MOVEQ	#1,D7
	MOVEQ	#0,D2
	MOVE.B	$15(A0),D2
	LSL.B	D2,D7
	SUBQ.W	#1,D7
lbC0016A0	MOVE.L	(A1)+,(A2)+
	DBRA	D7,lbC0016A0
	DBRA	D6,lbC001690
	BRA	lbC0016BC

lbC0016AE	MOVE.L	$60(A0),A1
	MOVEQ	#$4F,D7
lbC0016B4	MOVE.L	(A1)+,(A2)+
	MOVE.L	(A1)+,(A2)+
	DBRA	D7,lbC0016B4
lbC0016BC	MOVEM.L	(SP)+,D2-D7/A1/A2/A4
	SF	$22(A0)
lbC0016C4	MOVE.W	$66(A0),8(A3)
	RTS

lbC0016CC	MOVE.W	#0,8(A3)
	RTS

lbW0016D4	dc.w	0
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
	dc.w	$714
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
	dc.w	$38A
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
lbL00174E	dc.l	$18
	dc.w	$31
	dc.w	$4A
	dc.w	$61
	dc.w	$78
	dc.w	$8D
	dc.w	$A1
	dc.w	$B4
	dc.w	$C5
	dc.w	$D4
	dc.w	$E0
	dc.w	$EB
	dc.w	$F4
	dc.w	$FA
	dc.w	$FD
	dc.w	$FF
lbW001770	dc.w	$FB77
	dc.w	$EEC3
	dc.w	$E407
	dc.w	$CCDA
	dc.w	$27B
	dc.w	$33C7
	dc.w	$88D
	dc.w	$1901
	dc.w	$2351
	dc.w	$3F02
	dc.w	$3494
	dc.w	$14F0
	dc.w	$18CD
	dc.w	$319B
	dc.w	$4A69
	dc.w	$6336
	dc.w	$7700
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F03
	dc.w	$7B89
	dc.w	$743C
	dc.w	$6A16
	dc.w	$5DFC
	dc.w	$50BB
	dc.w	$4304
	dc.w	$3692
	dc.w	$2C6F
	dc.w	$242F
	dc.w	$1D77
	dc.w	$17FE
	dc.w	$138A
	dc.w	$FEA
	dc.w	$CF6
	dc.w	$A8E
	dc.w	$882
	dc.w	$6DB
	dc.w	$587
	dc.w	$475
	dc.w	$38D
	dc.w	$2CC
	dc.w	$233
	dc.w	$1BC
	dc.w	$14B
	dc.w	$FD67
	dc.w	$F7DE
	dc.w	$E7E6
	dc.w	$DBED
	dc.w	$CACA
	dc.w	$3101
	dc.w	$2591
	dc.w	$F6F
	dc.w	$2099
	dc.w	$2BEE
	dc.w	$4836
	dc.w	$1B05
	dc.w	$F08
	dc.w	$21BB
	dc.w	$4377
	dc.w	$6533
	dc.w	$7DA3
	dc.w	$7F00
	dc.w	$7EC7
	dc.w	$780E
	dc.w	$6B20
	dc.w	$5A61
	dc.w	$47DD
	dc.w	$362D
	dc.w	$28BD
	dc.w	$1EA3
	dc.w	$1709
	dc.w	$1153
	dc.w	$D07
	dc.w	$9CB
	dc.w	$75D
	dc.w	$56D
	dc.w	$3FF
	dc.w	$2D0
	dc.w	$212
	dc.w	$161
	dc.w	$104
	dc.w	$AD
	dc.w	$60
	dc.w	$20
	dc.w	$FFEE
	dc.w	$FFC9
	dc.w	$FFB1
	dc.w	$FFA4
	dc.w	$FFA1
	dc.w	$FCBA
	dc.w	$F363
	dc.w	$E37E
	dc.w	$CF9E
	dc.w	$E43D
	dc.w	$367A
	dc.w	$1965
	dc.w	$1752
	dc.w	$23AD
	dc.w	$3A63
	dc.w	$41F1
	dc.w	$17C1
	dc.w	$BE8
	dc.w	$2AA9
	dc.w	$5553
	dc.w	$7A8B
	dc.w	$7F00
	dc.w	$7D44
	dc.w	$70C0
	dc.w	$5C86
	dc.w	$4508
	dc.w	$2FC9
	dc.w	$2115
	dc.w	$16E6
	dc.w	$FDA
	dc.w	$AF9
	dc.w	$798
	dc.w	$542
	dc.w	$384
	dc.w	$259
	dc.w	$173
	dc.w	$DF
	dc.w	$89
	dc.w	$40
	dc.w	7
	dc.w	$FFDE
	dc.w	$FFC6
	dc.w	$FFBB
	dc.w	$FFBA
	dc.w	$FFC1
	dc.w	$FFCC
	dc.w	$FFD9
	dc.w	$FFE6
	dc.w	$FFF2
	dc.w	$FFFB
	dc.w	$1378
	dc.w	$EE84
	dc.w	$E05A
	dc.w	$C5D4
	dc.w	$B4E
	dc.w	$31B3
	dc.w	$1313
	dc.w	$1F4A
	dc.w	$2616
	dc.w	$45DF
	dc.w	$2E0E
	dc.w	$13EB
	dc.w	$9D8
	dc.w	$3397
	dc.w	$672F
	dc.w	$7F00
	dc.w	$7EC9
	dc.w	$7012
	dc.w	$564D
	dc.w	$3949
	dc.w	$2460
	dc.w	$1719
	dc.w	$EAA
	dc.w	$950
	dc.w	$5E9
	dc.w	$38F
	dc.w	$224
	dc.w	$14A
	dc.w	$8F
	dc.w	3
	dc.w	$FFAA
	dc.w	$FF7E
	dc.w	$FF75
	dc.w	$FF83
	dc.w	$FF9F
	dc.w	$FFBF
	dc.w	$FFDD
	dc.w	$FFF5
	dc.w	6
	dc.w	15
	dc.w	$13
	dc.w	$13
	dc.w	$10
	dc.w	12
	dc.w	8
	dc.w	$1ADD
	dc.w	$E985
	dc.w	$DC57
	dc.w	$C2A3
	dc.w	$25E9
	dc.w	$2A8D
	dc.w	$103D
	dc.w	$269A
	dc.w	$2A91
	dc.w	$4B24
	dc.w	$1FD9
	dc.w	$10BD
	dc.w	$865
	dc.w	$3C85
	dc.w	$779A
	dc.w	$7F00
	dc.w	$760C
	dc.w	$599E
	dc.w	$377B
	dc.w	$2031
	dc.w	$12AD
	dc.w	$AD6
	dc.w	$649
	dc.w	$3A5
	dc.w	$1F5
	dc.w	$DC
	dc.w	$51
	dc.w	$23
	dc.w	2
	dc.w	$FFEE
	dc.w	$FFE6
	dc.w	$FFE7
	dc.w	$FFEC
	dc.w	$FFF3
	dc.w	$FFF9
	dc.w	$FFFF
	dc.w	2
	dc.w	4
	dc.w	4
	dc.w	3
	dc.w	2
	dc.w	1
	dc.w	0
	dc.w	0
	dc.w	$FFFF
	dc.w	$97F
	dc.w	$E4D4
	dc.w	$D636
	dc.w	$C6FE
	dc.w	$31B0
	dc.w	$2314
	dc.w	$E82
	dc.w	$2A8C
	dc.w	$314E
	dc.w	$4C62
	dc.w	$1B03
	dc.w	$EA1
	dc.w	$750
	dc.w	$4573
	dc.w	$7F00
	dc.w	$7F6E
	dc.w	$66AE
	dc.w	$3FAE
	dc.w	$219D
	dc.w	$11BE
	dc.w	$95D
	dc.w	$4F1
	dc.w	$257
	dc.w	$11B
	dc.w	$2D
	dc.w	$FFA4
	dc.w	$FF73
	dc.w	$FF7D
	dc.w	$FFA3
	dc.w	$FFCF
	dc.w	$FFF2
	dc.w	8
	dc.w	$12
	dc.w	$12
	dc.w	14
	dc.w	8
	dc.w	3
	dc.w	0
	dc.w	$FFFE
	dc.w	$FFFD
	dc.w	$FFFE
	dc.w	$FFFE
	dc.w	$FFFF
	dc.w	0
	dc.w	0
	dc.w	$F1BA
	dc.w	$E0B8
	dc.w	$CE39
	dc.w	$D4B0
	dc.w	$3539
	dc.w	$1CAE
	dc.w	$D02
	dc.w	$2C42
	dc.w	$3A0B
	dc.w	$4951
	dc.w	$1954
	dc.w	$CF7
	dc.w	$67C
	dc.w	$4E61
	dc.w	$7F00
	dc.w	$77EB
	dc.w	$5274
	dc.w	$2978
	dc.w	$13D3
	dc.w	$979
	dc.w	$487
	dc.w	$1DD
	dc.w	$C4
	dc.w	1
	dc.w	$FFA3
	dc.w	$FF93
	dc.w	$FFAE
	dc.w	$FFD4
	dc.w	$FFF4
	dc.w	7
	dc.w	14
	dc.w	13
	dc.w	9
	dc.w	4
	dc.w	0
	dc.w	$FFFE
	dc.w	$FFFE
	dc.w	$FFFF
	dc.w	$FFFF
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$E1AB
	dc.w	$DD5D
	dc.w	$C593
	dc.w	$E91A
	dc.w	$34EE
	dc.w	$17FB
	dc.w	$BAC
	dc.w	$2C14
	dc.w	$429E
	dc.w	$40DA
	dc.w	$1781
	dc.w	$BA3
	dc.w	$5D1
	dc.w	$574F
	dc.w	$7F00
	dc.w	$6DB3
	dc.w	$3CD8
	dc.w	$1A34
	dc.w	$B48
	dc.w	$4DB
	dc.w	$217
	dc.w	$BC
	dc.w	$20
	dc.w	$FFD1
	dc.w	$FFC0
	dc.w	$FFD1
	dc.w	$FFEA
	dc.w	$FFFD
	dc.w	7
	dc.w	8
	dc.w	5
	dc.w	3
	dc.w	0
	dc.w	$FFFF
	dc.w	$FFFF
	dc.w	$FFFF
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$DC89
	dc.w	$DAC4
	dc.w	$BDC0
	dc.w	$FEB1
	dc.w	$32C9
	dc.w	$14D5
	dc.w	$A90
	dc.w	$2BB8
	dc.w	$4936
	dc.w	$3581
	dc.w	$1551
	dc.w	$A8F
	dc.w	$547
	dc.w	$603D
	dc.w	$7F00
	dc.w	$5FEC
	dc.w	$2A63
	dc.w	$1059
	dc.w	$64E
	dc.w	$26E
	dc.w	$B8
	dc.w	15
	dc.w	$FFC7
	dc.w	$FFC5
	dc.w	$FFDE
	dc.w	$FFF7
	dc.w	5
	dc.w	8
	dc.w	6
	dc.w	2
	dc.w	0
	dc.w	$FFFF
	dc.w	$FFFF
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$DE80
	dc.w	$D8C5
	dc.w	$B789
	dc.w	$1114
	dc.w	$2F9E
	dc.w	$12C9
	dc.w	$9A8
	dc.w	$2BDE
	dc.w	$4D5B
	dc.w	$2BA2
	dc.w	$1359
	dc.w	$9A9
	dc.w	$4D4
	dc.w	$692B
	dc.w	$7F00
	dc.w	$5057
	dc.w	$1D06
	dc.w	$9F6
	dc.w	$36B
	dc.w	$D4
	dc.w	$33
	dc.w	$FFE2
	dc.w	$FFD5
	dc.w	$FFE7
	dc.w	$FFFA
	dc.w	3
	dc.w	5
	dc.w	3
	dc.w	1
	dc.w	0
	dc.w	$FFFF
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$E4D0
	dc.w	$D70B
	dc.w	$B2E4
	dc.w	$1EB8
	dc.w	$2BD7
	dc.w	$1161
	dc.w	$8E7
	dc.w	$2D67
	dc.w	$4F9C
	dc.w	$2510
	dc.w	$11C9
	dc.w	$8E8
	dc.w	$474
	dc.w	$7219
	dc.w	$7C55
	dc.w	$3F6B
	dc.w	$133C
	dc.w	$5D5
	dc.w	$1C4
	dc.w	$56
	dc.w	$FFF9
	dc.w	$FFE0
	dc.w	$FFEC
	dc.w	$FFFB
	dc.w	2
	dc.w	3
	dc.w	2
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$ED7D
	dc.w	$D522
	dc.w	$B289
	dc.w	$2800
	dc.w	$27CE
	dc.w	$1049
	dc.w	$842
	dc.w	$30EC
	dc.w	$50A9
	dc.w	$2153
	dc.w	$1082
	dc.w	$842
	dc.w	$421
	dc.w	$7B07
	dc.w	$73E8
	dc.w	$2E8C
	dc.w	$C60
	dc.w	$349
	dc.w	$79
	dc.w	$11
	dc.w	$FFEA
	dc.w	$FFEE
	dc.w	$FFFB
	dc.w	2
	dc.w	2
	dc.w	1
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$F6E3
	dc.w	$D287
	dc.w	$B4A8
	dc.w	$2DF5
	dc.w	$23D7
	dc.w	$F53
	dc.w	$7B3
	dc.w	$3641
	dc.w	$50A6
	dc.w	$1F47
	dc.w	$F66
	dc.w	$7B3
	dc.w	$3D9
lbW001BC0	dc.w	$7F00
	dc.w	$6B22
	dc.w	$20FE
	dc.w	$79D
	dc.w	$1C1
	dc.w	$2D
	dc.w	$FFF5
	dc.w	$FFF0
	dc.w	$FFFB
	dc.w	1
	dc.w	1
	dc.w	1
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
lbW001BE6	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$1D
	dc.w	$CEB8
	dc.w	$B9CD
	dc.w	$3192
	dc.w	$2037
	dc.w	$E6D
	dc.w	$736
	dc.w	$3D2E
	dc.w	$4F2F
	dc.w	$1DEA
	dc.w	$E6C
	dc.w	$736
	dc.w	$39B
	dc.w	$7F00
	dc.w	$622C
	dc.w	$188C
	dc.w	$4DD
	dc.w	$F6
	dc.w	$FFB9
	dc.w	$FFB2
	dc.w	$FFEF
	dc.w	8
	dc.w	7
	dc.w	1
	dc.w	$FFFF
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
lbW001C4A	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$8B8
	dc.w	$C94F
	dc.w	$C47E
	dc.w	$338E
	dc.w	$1D17
	dc.w	$D96
	dc.w	$6C8
	dc.w	$4401
	dc.w	$4BD3
	dc.w	$1CA4
	dc.w	$D90
	dc.w	$6C8
	dc.w	$364
	dc.w	$7F00
	dc.w	$5811
	dc.w	$1100
	dc.w	$2DB
	dc.w	$12
	dc.w	$FF8B
	dc.w	$FFD8
	dc.w	8
	dc.w	9
	dc.w	2
	dc.w	$FFFF
	dc.w	$FFFF
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$1065
	dc.w	$C224
	dc.w	$D328
	dc.w	$3460
	dc.w	$1A87
	dc.w	$CD1
	dc.w	$667
	dc.w	$4B18
	dc.w	$469A
	dc.w	$1B42
	dc.w	$CCC
	dc.w	$667
	dc.w	$333
	dc.w	$7F00
	dc.w	$4CC9
	dc.w	$A92
	dc.w	$17C
	dc.w	$FF6C
	dc.w	$FFAA
	dc.w	2
	dc.w	13
	dc.w	3
	dc.w	$FFFE
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$16E7
	dc.w	$BA2A
	dc.w	$DB0C
	dc.w	$344D
	dc.w	$187E
	dc.w	$C20
	dc.w	$60F
	dc.w	$5204
	dc.w	$402F
	dc.w	$19D8
	dc.w	$C1E
	dc.w	$60F
	dc.w	$308
	dc.w	$7F00
	dc.w	$40F9
	dc.w	$781
	dc.w	$DD
	dc.w	$FFA1
	dc.w	$FFD9
	dc.w	5
	dc.w	5
	dc.w	0
	dc.w	$FFFF
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$1C0C
	dc.w	$B0D2
	dc.w	$E7CE
	dc.w	$337D
	dc.w	$16EA
	dc.w	$B82
	dc.w	$5C1
	dc.w	$5814
	dc.w	$399A
	dc.w	$1881
	dc.w	$B82
	dc.w	$5C1
	dc.w	$2E1
	dc.w	$7F00
	dc.w	$3535
	dc.w	$4EF
	dc.w	$74
	dc.w	$FFCB
	dc.w	$FFF1
	dc.w	4
	dc.w	2
	dc.w	$FFFF
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$1FB5
	dc.w	$AD77
	dc.w	$F515
	dc.w	$3209
	dc.w	$15AE
	dc.w	$AF4
	dc.w	$57A
	dc.w	$5CA5
	dc.w	$340E
	dc.w	$174A
	dc.w	$AF4
	dc.w	$57A
	dc.w	$2BD
	dc.w	$7F00
	dc.w	$29BF
	dc.w	$308
	dc.w	$FFC8
	dc.w	$FFC8
	dc.w	4
	dc.w	4
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$2170
	dc.w	$B20F
	dc.w	$1FC
	dc.w	$300B
	dc.w	$14AF
	dc.w	$A73
	dc.w	$539
	dc.w	$6215
	dc.w	$2FE7
	dc.w	$1634
	dc.w	$A73
	dc.w	$53A
	dc.w	$29D
	dc.w	$7F00
	dc.w	$1EE1
	dc.w	$1B1
	dc.w	$FFDC
	dc.w	$FFEA
	dc.w	3
	dc.w	1
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$2128
	dc.w	$B6D5
	dc.w	$E58
	dc.w	$2D9F
	dc.w	$13D8
	dc.w	$9FE
	dc.w	$4FF
	dc.w	$68E7
	dc.w	$2CD8
	dc.w	$153A
	dc.w	$9FD
	dc.w	$4FF
	dc.w	$27F
	dc.w	$7F00
	dc.w	$14ED
	dc.w	$D4
	dc.w	$FFA1
	dc.w	0
	dc.w	4
	dc.w	$FFFF
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$1F29
	dc.w	$A209
	dc.w	$1989
	dc.w	$2AEA
	dc.w	$1313
	dc.w	$992
	dc.w	$4C9
	dc.w	$6FC3
	dc.w	$2AA6
	dc.w	$1456
	dc.w	$992
	dc.w	$4C9
	dc.w	$264
	dc.w	$7F00
	dc.w	$C3B
	dc.w	$53
	dc.w	$FFDD
	dc.w	2
	dc.w	1
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$1BB0
	dc.w	$8888
	dc.w	$235E
	dc.w	$2819
	dc.w	$1258
	dc.w	$92F
	dc.w	$498
	dc.w	$7023
	dc.w	$28FE
	dc.w	$1384
	dc.w	$92F
	dc.w	$497
	dc.w	$24C
	dc.w	$7F00
	dc.w	$780
	dc.w	$FF65
	dc.w	$FFF3
	dc.w	4
	dc.w	$FFFF
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$1740
	dc.w	$808D
	dc.w	$2BF1
	dc.w	$255C
	dc.w	$11A7
	dc.w	$8D4
	dc.w	$46A
	dc.w	$7006
	dc.w	$2781
	dc.w	$12C3
	dc.w	$8D4
	dc.w	$46A
	dc.w	$235
	dc.w	$7F00
	dc.w	$423
	dc.w	$FFB7
	dc.w	$FFFF
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$1215
	dc.w	$800F
	dc.w	$338F
	dc.w	$22E6
	dc.w	$10FF
	dc.w	$87F
	dc.w	$440
	dc.w	$6F1E
	dc.w	$262F
	dc.w	$120F
	dc.w	$87F
	dc.w	$43F
	dc.w	$220
	dc.w	$7F00
	dc.w	$1B2
	dc.w	$FFEA
	dc.w	1
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$C3C
	dc.w	$8000
	dc.w	$3B79
	dc.w	$20EE
	dc.w	$1062
	dc.w	$831
	dc.w	$419
	dc.w	$780C
	dc.w	$24DF
	dc.w	$1168
	dc.w	$831
	dc.w	$419
	dc.w	$20C
	dc.w	$7F00
	dc.w	$4B
	dc.w	$FFFA
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$541
	dc.w	$8000
	dc.w	$417D
	dc.w	$1FAB
	dc.w	$FD0
	dc.w	$7E9
	dc.w	$3F4
	dc.w	$7F00
	dc.w	$2398
	dc.w	$10CE
	dc.w	$7E9
	dc.w	$3F4
	dc.w	$1FA
	dc.w	$7E81
	dc.w	$188
	dc.w	5
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$FD3E
	dc.w	$8000
	dc.w	$45D7
	dc.w	$1F45
	dc.w	$F49
	dc.w	$7A4
	dc.w	$3D2
	dc.w	$7F00
	dc.w	$228B
	dc.w	$103D
	dc.w	$7A5
	dc.w	$3D2
	dc.w	$1E9
	dc.w	$79D0
	dc.w	$687
	dc.w	$7A
	dc.w	10
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$F416
	dc.w	$8000
	dc.w	$49EB
	dc.w	$1FE3
	dc.w	$ED7
	dc.w	$765
	dc.w	$3B2
	dc.w	$7F00
	dc.w	$21A5
	dc.w	$FB6
	dc.w	$765
	dc.w	$3B1
	dc.w	$1D9
	dc.w	$74CF
	dc.w	$C02
	dc.w	$13C
	dc.w	$34
	dc.w	11
	dc.w	3
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$E94C
	dc.w	$8000
	dc.w	$4D8B
	dc.w	$21B2
	dc.w	$E9B
	dc.w	$729
	dc.w	$395
	dc.w	$7F00
	dc.w	$1F2E
	dc.w	$F31
	dc.w	$729
	dc.w	$394
	dc.w	$1CB
	dc.w	$6F7D
	dc.w	$11D7
	dc.w	$2DB
	dc.w	$CE
	dc.w	$42
	dc.w	$17
	dc.w	8
	dc.w	1
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	$DBED
	dc.w	$8000
	dc.w	$506B
	dc.w	$24C0
	dc.w	$F01
	dc.w	$6F8
	dc.w	$379
	dc.w	$7F00
	dc.w	$1956
	dc.w	$E68
	dc.w	$6F0
	dc.w	$379
	dc.w	$1BF
	dc.w	$69DB
	dc.w	$17E0
	dc.w	$563
	dc.w	$139
	dc.w	$87
	dc.w	$41
	dc.w	$21
	dc.w	$11
	dc.w	7
	dc.w	4
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	$CE57
	dc.w	$4A4
	dc.w	$526
	dc.w	$FB66
	dc.w	$EF30
	dc.w	$9930
	dc.w	$C5AD
	dc.w	$F94C
	dc.w	$FA32
	dc.w	$9BE
	dc.w	$E1B
	dc.w	$5703
	dc.w	$6B3A
	dc.w	$83A1
	dc.w	$8C1C
	dc.w	$996E
	dc.w	$AB98
	dc.w	$C1F8
	dc.w	$DAA8
	dc.w	$F375
	dc.w	$C42
	dc.w	$2499
	dc.w	$3BB1
	dc.w	$50ED
	dc.w	$63E3
	dc.w	$744E
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7FEC
	dc.w	$7F58
	dc.w	$7FEE
	dc.w	$7F36
	dc.w	$7F93
	dc.w	$7FDA
	dc.w	$22B6
	dc.w	$6E2
	dc.w	$1FA
	dc.w	$F97F
	dc.w	$D0B0
	dc.w	$9FBF
	dc.w	$DEBF
	dc.w	$F750
	dc.w	$F7
	dc.w	$CD8
	dc.w	$26C6
	dc.w	$64BB
	dc.w	$70ED
	dc.w	$86B8
	dc.w	$9666
	dc.w	$AF0A
	dc.w	$CF0C
	dc.w	$F0C8
	dc.w	$127D
	dc.w	$32F3
	dc.w	$5058
	dc.w	$6982
	dc.w	$7DD7
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7FFA
	dc.w	$7FB8
	dc.w	$7F87
	dc.w	$7F00
	dc.w	$7F99
	dc.w	$7F00
	dc.w	$7F4B
	dc.w	$7F7E
	dc.w	$7F9D
	dc.w	$7FA9
	dc.w	$7FA7
	dc.w	$7F9B
	dc.w	$7F88
	dc.w	$7F70
	dc.w	$7F56
	dc.w	$1827
	dc.w	$85D
	dc.w	$FD8A
	dc.w	$F58E
	dc.w	$AAA0
	dc.w	$B87E
	dc.w	$E9B1
	dc.w	$F78F
	dc.w	$89F
	dc.w	$1097
	dc.w	$44D0
	dc.w	$676B
	dc.w	$7417
	dc.w	$8ABF
	dc.w	$A3D4
	dc.w	$CA53
	dc.w	$F4FD
	dc.w	$1F5D
	dc.w	$4681
	dc.w	$6766
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7FE2
	dc.w	$7F97
	dc.w	$7F64
	dc.w	$7FF4
	dc.w	$7F25
	dc.w	$7F5A
	dc.w	$7F75
	dc.w	$7F7C
	dc.w	$7F74
	dc.w	$7F62
	dc.w	$7F4C
	dc.w	$7F34
	dc.w	$7F1E
	dc.w	$7F0C
	dc.w	$7EFE
	dc.w	$7EF4
	dc.w	$7EEE
	dc.w	$7EEC
	dc.w	$E14
	dc.w	$8C8
	dc.w	$FA29
	dc.w	$EA14
	dc.w	$9750
	dc.w	$CB17
	dc.w	$ED77
	dc.w	$FA92
	dc.w	$D73
	dc.w	$1B3D
	dc.w	$5BC7
	dc.w	$6C4C
	dc.w	$7626
	dc.w	$8FB7
	dc.w	$B465
	dc.w	$E741
	dc.w	$1ACD
	dc.w	$4A39
	dc.w	$7012
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F9B
	dc.w	$7FE7
	dc.w	$7FF5
	dc.w	$7FDA
	dc.w	$7FA9
	dc.w	$7F70
	dc.w	$7F3C
	dc.w	$7F11
	dc.w	$7EF4
	dc.w	$7EE2
	dc.w	$7EDC
	dc.w	$7EDD
	dc.w	$7EE2
	dc.w	$7EE9
	dc.w	$7EF1
	dc.w	$7EF8
	dc.w	$7EFD
	dc.w	$7F01
	dc.w	$1F29
	dc.w	$7B7
	dc.w	$F8BB
	dc.w	$D9E8
	dc.w	$9ADB
	dc.w	$D85A
	dc.w	$EF6F
	dc.w	$56
	dc.w	$105E
	dc.w	$2993
	dc.w	$6293
	dc.w	$6F41
	dc.w	$779A
	dc.w	$95A1
	dc.w	$C7C2
	dc.w	$448
	dc.w	$3E6E
	dc.w	$6CE0
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7FDE
	dc.w	$7F77
	dc.w	$7FFF
	dc.w	$7F13
	dc.w	$7F29
	dc.w	$7F2D
	dc.w	$7F27
	dc.w	$7F1B
	dc.w	$7F0F
	dc.w	$7F04
	dc.w	$7EFD
	dc.w	$7EF9
	dc.w	$7EF8
	dc.w	$7EF9
	dc.w	$7EFA
	dc.w	$7EFC
	dc.w	$7EFE
	dc.w	$7EFF
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7EFF
	dc.w	$38C1
	dc.w	$56D
	dc.w	$F814
	dc.w	$C623
	dc.w	$A713
	dc.w	$E15B
	dc.w	$F142
	dc.w	$7C2
	dc.w	$1262
	dc.w	$38E2
	dc.w	$63C5
	dc.w	$715B
	dc.w	$78AE
	dc.w	$9C7C
	dc.w	$DBB2
	dc.w	$2144
	dc.w	$5DAB
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7FC4
	dc.w	$7FFA
	dc.w	$7FD7
	dc.w	$7F8E
	dc.w	$7F43
	dc.w	$7F0A
	dc.w	$7EEA
	dc.w	$7EDE
	dc.w	$7EE0
	dc.w	$7EE8
	dc.w	$7EF2
	dc.w	$7EFB
	dc.w	$7F00
	dc.w	$7F03
	dc.w	$7F03
	dc.w	$7F02
	dc.w	$7F01
	dc.w	$7F00
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$44FF
	dc.w	$22D
	dc.w	$F638
	dc.w	$B1EC
	dc.w	$B3D3
	dc.w	$E6DC
	dc.w	$F2F4
	dc.w	$1027
	dc.w	$1555
	dc.w	$4964
	dc.w	$65A0
	dc.w	$7308
	dc.w	$7983
	dc.w	$A447
	dc.w	$EFC0
	dc.w	$3BF3
	dc.w	$755D
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7FA2
	dc.w	$7FBC
	dc.w	$7F8E
	dc.w	$7F4A
	dc.w	$7F13
	dc.w	$7EF2
	dc.w	$7EE6
	dc.w	$7EE8
	dc.w	$7EF0
	dc.w	$7EF8
	dc.w	$7EFE
	dc.w	$7F01
	dc.w	$7F02
	dc.w	$7F01
	dc.w	$7F00
	dc.w	$7EFF
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$3F9E
	dc.w	$FE6E
	dc.w	$F23E
	dc.w	$A271
	dc.w	$BEFF
	dc.w	$EA01
	dc.w	$F459
	dc.w	$186B
	dc.w	$1AB5
	dc.w	$58FD
	dc.w	$6858
	dc.w	$745C
	dc.w	$7A2D
	dc.w	$AD04
	dc.w	$454
	dc.w	$552E
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7FB7
	dc.w	$7F40
	dc.w	$7F6E
	dc.w	$7F58
	dc.w	$7F2D
	dc.w	$7F08
	dc.w	$7EF5
	dc.w	$7EF0
	dc.w	$7EF4
	dc.w	$7EF9
	dc.w	$7EFD
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7EFF
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$347C
	dc.w	$FAB9
	dc.w	$ED47
	dc.w	$9AA4
	dc.w	$C870
	dc.w	$EBE1
	dc.w	$F572
	dc.w	$1E07
	dc.w	$2265
	dc.w	$6469
	dc.w	$6AD4
	dc.w	$7570
	dc.w	$7AB7
	dc.w	$B6B2
	dc.w	$16F0
	dc.w	$681C
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7FEB
	dc.w	$7F45
	dc.w	$7F6C
	dc.w	$7F4A
	dc.w	$7F1C
	dc.w	$7EFC
	dc.w	$7EF1
	dc.w	$7EF3
	dc.w	$7EF9
	dc.w	$7EFE
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7EFF
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$28BB
	dc.w	$F78E
	dc.w	$E420
	dc.w	$99DD
	dc.w	$D05D
	dc.w	$ED36
	dc.w	$F656
	dc.w	$2213
	dc.w	$2B5A
	dc.w	$6A73
	dc.w	$6CB8
	dc.w	$7655
	dc.w	$7B2A
	dc.w	$C151
	dc.w	$2A7D
	dc.w	$790E
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F48
	dc.w	$7F3B
	dc.w	$7F18
	dc.w	$7EFF
	dc.w	$7EF6
	dc.w	$7EF7
	dc.w	$7EFB
	dc.w	$7EFE
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$1E75
	dc.w	$F544
	dc.w	$D834
	dc.w	$9DAA
	dc.w	$D6E9
	dc.w	$EE5D
	dc.w	$F717
	dc.w	$24B5
	dc.w	$34A1
	dc.w	$6D21
	dc.w	$6E35
	dc.w	$7717
	dc.w	$7B8B
	dc.w	$CCE1
	dc.w	$3DC8
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7FCB
	dc.w	$7F26
	dc.w	$7F30
	dc.w	$7F16
	dc.w	$7F00
	dc.w	$7EF9
	dc.w	$7EFA
	dc.w	$7EFC
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$16D0
	dc.w	$F3F4
	dc.w	$CBF1
	dc.w	$A3BF
	dc.w	$DC27
	dc.w	$EF79
	dc.w	$F7BC
	dc.w	$26A4
	dc.w	$3DE3
	dc.w	$6E84
	dc.w	$6F7A
	dc.w	$77BC
	dc.w	$7BDE
	dc.w	$D962
	dc.w	$4F0B
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F26
	dc.w	$7F16
	dc.w	$7F02
	dc.w	$7EFB
	dc.w	$7EFB
	dc.w	$7EFE
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$11F0
	dc.w	$F371
	dc.w	$C1E6
	dc.w	$AAA0
	dc.w	$E033
	dc.w	$F08A
	dc.w	$F84C
	dc.w	$28A1
	dc.w	$4735
	dc.w	$6FC4
	dc.w	$7098
	dc.w	$784C
	dc.w	$7C25
	dc.w	$E441
	dc.w	$5DE5
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7FE9
	dc.w	$7F17
	dc.w	$7F16
	dc.w	$7F05
	dc.w	$7EFC
	dc.w	$7EFC
	dc.w	$7EFD
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$F7C
	dc.w	$F342
	dc.w	$B6DF
	dc.w	$B189
	dc.w	$E338
	dc.w	$F187
	dc.w	$F8C9
	dc.w	$2B06
	dc.w	$509A
	dc.w	$7144
	dc.w	$7193
	dc.w	$78C8
	dc.w	$7C63
	dc.w	$ED84
	dc.w	$6A6B
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F88
	dc.w	$7F73
	dc.w	$7F12
	dc.w	$7EEF
	dc.w	$7EF4
	dc.w	$7EFE
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$F12
	dc.w	$F2B4
	dc.w	$AA33
	dc.w	$B822
	dc.w	$E56F
	dc.w	$F269
	dc.w	$F936
	dc.w	$2EE9
	dc.w	$59B0
	dc.w	$72F5
	dc.w	$726E
	dc.w	$7936
	dc.w	$7C9A
	dc.w	$F717
	dc.w	$75F2
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7FBB
	dc.w	$7F39
	dc.w	$7EF0
	dc.w	$7EF0
	dc.w	$7EFD
	dc.w	$7F01
	dc.w	$7F00
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$1051
	dc.w	$F0E3
	dc.w	$A18C
	dc.w	$BE4C
	dc.w	$E714
	dc.w	$F330
	dc.w	$F998
	dc.w	$33B3
	dc.w	$61CB
	dc.w	$74A7
	dc.w	$7332
	dc.w	$7998
	dc.w	$7CCB
	dc.w	$FB
	dc.w	$7FF6
	dc.w	$7F00
	dc.w	$7FED
	dc.w	$7F8C
	dc.w	$7EFC
	dc.w	$7EEA
	dc.w	$7EFB
	dc.w	$7F01
	dc.w	$7F00
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$12E5
	dc.w	$ECCF
	dc.w	$98BC
	dc.w	$C3FC
	dc.w	$E858
	dc.w	$F3E1
	dc.w	$F9EF
	dc.w	$39A7
	dc.w	$6850
	dc.w	$7630
	dc.w	$73E0
	dc.w	$79EF
	dc.w	$7CF7
	dc.w	$B2F
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F91
	dc.w	$7F44
	dc.w	$7EF7
	dc.w	$7EF5
	dc.w	$7EFE
	dc.w	$7F00
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$167B
	dc.w	$E76E
	dc.w	$93CA
	dc.w	$C92C
	dc.w	$E964
	dc.w	$F47D
	dc.w	$FA3E
	dc.w	$40A5
	dc.w	$6D08
	dc.w	$778A
	dc.w	$747D
	dc.w	$7A3E
	dc.w	$7D1E
	dc.w	$15B3
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F50
	dc.w	$7F1D
	dc.w	$7EF9
	dc.w	$7EFB
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7F86
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$1AF2
	dc.w	$DD31
	dc.w	$9374
	dc.w	$CDD7
	dc.w	$EA52
	dc.w	$F50B
	dc.w	$FA85
	dc.w	$484D
	dc.w	$700F
	dc.w	$78BA
	dc.w	$750B
	dc.w	$7A84
	dc.w	$7D42
	dc.w	$2088
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F6F
	dc.w	$7EFF
	dc.w	$7EF6
	dc.w	$7EFE
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$1FAB
	dc.w	$D337
	dc.w	$963B
	dc.w	$D1F3
	dc.w	$EB33
	dc.w	$F58C
	dc.w	$FAC5
	dc.w	$4D79
	dc.w	$721D
	dc.w	$79CB
	dc.w	$758C
	dc.w	$7AC5
	dc.w	$7D62
	dc.w	$2BAD
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F31
	dc.w	$7EFC
	dc.w	$7EFC
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$241F
	dc.w	$CC6D
	dc.w	$9B30
	dc.w	$D57A
	dc.w	$EC0B
	dc.w	$F601
	dc.w	$FB00
	dc.w	$5244
	dc.w	$73C4
	dc.w	$7AC4
	dc.w	$7601
	dc.w	$7B00
	dc.w	$7D7F
	dc.w	$3722
	dc.w	$7F00
	dc.w	$7FA9
	dc.w	$7F11
	dc.w	$7EF6
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$280C
	dc.w	$BE21
	dc.w	$A145
	dc.w	$D867
	dc.w	$ECDA
	dc.w	$F66D
	dc.w	$FB36
	dc.w	$55B1
	dc.w	$7546
	dc.w	$7BA8
	dc.w	$766D
	dc.w	$7B36
	dc.w	$7D9A
	dc.w	$42E8
	dc.w	$7F00
	dc.w	$7F45
	dc.w	$7F02
	dc.w	$7EFC
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$2B18
	dc.w	$A865
	dc.w	$A7BA
	dc.w	$DAC1
	dc.w	$ED9F
	dc.w	$F6CF
	dc.w	$FB67
	dc.w	$5207
	dc.w	$76C6
	dc.w	$7C7B
	dc.w	$76CF
	dc.w	$7B67
	dc.w	$7DB3
	dc.w	$4EFE
	dc.w	$7F00
	dc.w	$7F4F
	dc.w	$7EF5
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$2D13
	dc.w	$B2BE
	dc.w	$AE1E
	dc.w	$DC9C
	dc.w	$EE56
	dc.w	$F72B
	dc.w	$FB95
	dc.w	$4C1E
	dc.w	$7845
	dc.w	$7D3D
	dc.w	$772B
	dc.w	$7B95
	dc.w	$7DC9
	dc.w	$5B64
	dc.w	$7F00
	dc.w	$7F17
	dc.w	$7EFC
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$2E1B
	dc.w	$CE29
	dc.w	$B467
	dc.w	$DE0E
	dc.w	$EEFF
	dc.w	$F77F
	dc.w	$FBBF
	dc.w	$4843
	dc.w	$79BD
	dc.w	$7DF0
	dc.w	$777F
	dc.w	$7BBE
	dc.w	$7DDE
	dc.w	$681B
	dc.w	$7F00
	dc.w	$7F02
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$2E32
	dc.w	$E25E
	dc.w	$BB9A
	dc.w	$DF40
	dc.w	$EF9C
	dc.w	$F7CD
	dc.w	$FBE6
	dc.w	$68ED
	dc.w	$7B21
	dc.w	$7E96
	dc.w	$77CD
	dc.w	$7BE6
	dc.w	$7DF1
	dc.w	$7522
	dc.w	$7F49
	dc.w	$7EFE
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$7EFF
	dc.w	$2D4F
	dc.w	$F4E0
	dc.w	$C241
	dc.w	$E05F
	dc.w	$F02D
	dc.w	$F817
	dc.w	$FC0A
	dc.w	$77E5
	dc.w	$7C6A
	dc.w	$7F31
	dc.w	$7817
	dc.w	$7C0B
	dc.w	$7E05
	dc.w	$7F00
	dc.w	$7F0C
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$2B1D
	dc.w	$EB4A
	dc.w	$C91D
	dc.w	$E1A6
	dc.w	$F0B7
	dc.w	$F85A
	dc.w	$FC2C
	dc.w	$6D81
	dc.w	$7DA5
	dc.w	$7FC1
	dc.w	$785A
	dc.w	$7C2D
	dc.w	$7E16
	dc.w	$7F00
	dc.w	$7FD9
	dc.w	$7F18
	dc.w	$7F01
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$2782
	dc.w	$E163
	dc.w	$CFFB
	dc.w	$E34C
	dc.w	$F13A
	dc.w	$F89A
	dc.w	$FC4C
	dc.w	$615E
	dc.w	$7ED9
	dc.w	$7F00
	dc.w	$7899
	dc.w	$7C4B
	dc.w	$7E26
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F44
	dc.w	$7F0F
	dc.w	$7F03
	dc.w	$7F00
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$2237
	dc.w	$D728
	dc.w	$D6A1
	dc.w	$E592
	dc.w	$F1CA
	dc.w	$F8D5
	dc.w	$FC6B
	dc.w	$5DFA
	dc.w	$7F58
	dc.w	$7F00
	dc.w	$78D6
	dc.w	$7C6A
	dc.w	$7E35
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7FD9
	dc.w	$7F4F
	dc.w	$7F19
	dc.w	$7F08
	dc.w	$7F02
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$7EFE
	dc.w	$1A9B
	dc.w	$CC9C
	dc.w	$DCAB
	dc.w	$E8B3
	dc.w	$F2A3
	dc.w	$F910
	dc.w	$FC86
	dc.w	$7B5E
	dc.w	$7DF6
	dc.w	$7F00
	dc.w	$790C
	dc.w	$7C86
	dc.w	$7E44
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F74
	dc.w	$7F3D
	dc.w	$7F1D
	dc.w	$7F0E
	dc.w	$7F06
	dc.w	$7F02
	dc.w	$7F01
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$7F00
	dc.w	$12E3
binend

 ifne test
emptyTrack 	ds.b	192
PatternInfo 	ds.b	PI_Stripes	
Stripe1		dc.l	1
Stripe2		dc.l	1
Stripe3		dc.l	1
Stripe4		dc.l	1

UpdateStripes
	pushm	d0-d3/a0-a4
	lea	PatternInfo+PI_NoteTranspose1(pc),a2
	move.l	thxroutines,a0
	move.l	ahxModule(a0),a1
	move.l	ahxBSS_P(a0),a0
	lea	ahx_pVoice0Temp(a0),a0
	lea	Stripe1(pc),a3
	bsr.b	.doStripe
	bsr.b	.doStripe
	bsr.b	.doStripe
	bsr.b	.doStripe
	popm	d0-d3/a0-a4
	rts

.doStripe
	move.b	ahx_pvtTranspose(a0),(a2)+
	moveq	#0,d3
	move.b	ahx_pvtTrack(a0),d3
	add	#232,a0

	tst.b	6(a1)
	bmi.b	.1
	* If bit 7 of byte 6 is 1, track 0 is included. 
	* If it is 0, track 0 was empty, and is
    * therefore not saved with the module, to save space.
	subq.b	#1,d3
	bpl.b	.1
	pushpea	emptyTrack(pc),(a3)+
	rts
.1
	* Get SS, number of subsongs
	moveq	#0,d1
	move.b	13(a1),d1
	* Subsong list length in bytes:
	add		d1,d1
	* Get LEN, length of the position list
	move	6(a1),d2
	and		#$fff,d2
	* Position list length in bytes:
	lsl		#3,d2
	* Skip over subsong list 
	lea		14(a1,d1),a4
	* Skip over position list
	add		d2,a4
	* Get TRL, track length
	moveq	#0,d0
	move.b	10(a1),d0 		
	* Track length in bytes
	mulu	#3,d0
	* Get current track offset
	mulu	d3,d0
	* Address of current track
	add		d0,a4
	* Into the stripe array
	move.l	a4,(a3)+
	rts

PatternInit
	; Use this as the empty track data
	lea	ptheader,a0
	moveq	#192/2-1,d0
.clrPt
	clr	(a0)+
	dbf	d0,.clrPt


	lea	PatternInfo(PC),A0
	move.w	#4,PI_Voices(A0)	; Number of stripes (MUST be at least 4)
	pea	ConvertNote(pc) 
	move.l	(sp)+,PI_Convert(a0)
	moveq	#3,D0
	move.l	D0,PI_Modulo(A0)	; Number of bytes to next row
	move.l	#module,a1
	move.b	10(a1),d0 			* TRL, track length 1-64
	move.w	d0,PI_Pattlength(A0)	; Length of each stripe in rows
	clr.w	PI_Pattpos(A0)		; Current Position in Pattern (from 0)
	move	#-1,PI_Speed(a0)	; Magic! Indicates notes, not periods
	rts

* Called by the PI engine to get values for a particular row
* Each entry is 24 bits (3 bytes) long, and consists of
* bits 23-18 (6 bits): The note. This ranges from 0 (no note) to 60 (B-5)
* bits 17-12 (6 bits): The sample. This ranges from 0 to 63.
* bits 11-8  (4 bits): The command. See list below
* bits 7-0   (8 bits): The command's data. See list below

ConvertNote
	moveq	#0,D0		; Period, Note
	moveq	#0,D1		; Sample number
	moveq	#0,D2		; Command 
	moveq	#0,D3		; Command argument

    * 01234567 01234567 01234567
	* nnnnnnSS SSSScccc PPPPPPPP

	move.b	(a1),d0
	rol		#8,d0
	move.b	1(a1),d0

	moveq	#$f,d2
	and.b	d0,d2 	* cmd
	
	lsr		#4,d0
	moveq	#%111111,d1
	and.b	d0,d1	* sample

	lsr		#6,d0	* note

	move.b	2(a1),d3	* arg
	rts


ptheader	ds.b	256


 endif

