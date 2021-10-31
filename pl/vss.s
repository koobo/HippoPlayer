;APS0000005A0000005A0000005A0000005A0000005A0000005A0000005A0000005A0000005A0000005A
	incdir	include:
	include mucro.i
	include	misc/deliplayer.i
	include	hardware/intbits.i

testi	=	1

 ifne testi

	lea	mod,a0 
	move.l	#modlen,d0 
	lea	songend_,a1
	jsr	init_
	tst.l	d0
	bne.b	exit

	moveq	#$40,d0
	jsr	volume_
	bsr.b	loop
	bra.b	exit

	moveq	#1,d0
	jsr	song_
	bsr.b	loop

	moveq	#2,d0
	jsr	song_
	bsr.b	loop

	moveq	#1,d0
	jsr	song_
	bsr.b	loop

exit
	jsr	end_
	rts

	
loop
	cmp.b	#$80,$dff006
	bne.b	loop
.x	cmp.b	#$80,$dff006
	beq.b	.x

	move	#$ff0,$dff180
	jsr	play_
	clr	$dff180

	btst	#6,$bfe001
	bne.b	loop
.y	btst	#6,$bfe001
	beq.b	.y

	rts

songend_	dc	0

	SECTION	vss00000,data_c 

mod	incbin m:exo/voodoosupremesynthesizer/qang.vss
;mod	incbin m:exo/voodoosupremesynthesizer/silkworm.vss
;mod	incbin m:exo/voodoosupremesynthesizer/voo8.vss
;mod	incbin m:exo/voodoosupremesynthesizer/voo7.vss
;mod	incbin m:exo/voodoosupremesynthesizer/voo6.vss
mode

modlen = mode-mod
 endif 


	SECTION	vss000000,CODE

start
	jmp	init_(pc)
	jmp	play_(pc)
	jmp	end_(pc)
	jmp	volume_(pc)
	jmp	song_(pc)

moduleAddress		dc.l	0
moduleLength		dc.l	0
songEndAddress		dc.l	0
currentSong		dc.w	0

init_	
	move.l 	a0,moduleAddress 
	move.l	d0,moduleLength 
	move.l	a1,songEndAddress

	bsr.w	InitPlayer
	tst.l	d0
	bne.b	.initErr

	bsr.w	InitSound
	bsr.w	StartInt
	moveq	#%1111,d0
	bsr.w	SetVoices


	bsr.w	SubSongRange
	move.l	d1,d2
	move.l	d0,d1

	moveq	#0,d0
	rts

.initErr
	moveq	#-1,d0 
	rts

play_
	bsr.w	Interrupt
	move	currentSong(pc),d0
	rts
	
end_
	bsr.w	StopInt
	bsr.w	EndSound
	bsr.w	EndPlayer
	rts

song_
	move	currentSong(pc),d1
	sub	d1,d0
	beq.b 	.x
	bpl.w	NextSong
	bra.b	PrevSong
.x 	rts

volume_
	bra.w Volume

;ProgStart
;	MOVEQ	#-1,D0
;	RTS
;
;	dc.b	'EPPLAYER'
;	dc.l	lbL000050
;	dc.b	'$VER: Voodoo Supreme Synthesizer player modu'
;	dc.b	'le V1.2 (Apr/11/94)',0
;lbL000050
;	dc.l	DTP_PlayerVersion
;	dc.l	1
;	dc.l	DTP_PlayerName
;	dc.l	VSS.MSG
;	dc.l	DTP_Creator
;	dc.l	c1993TomasPar.MSG
;	dc.l	DTP_Check2
;	dc.l	lbC000342
;	dc.l	DTP_SubSongRange
;	dc.l	lbC00053A
;	dc.l	DTP_InitPlayer
;	dc.l	lbC00041E
;	dc.l	DTP_EndPlayer
;	dc.l	lbC0004E8
;	dc.l	DTP_InitSound
;	dc.l	lbC000382
;	dc.l	DTP_EndSound
;	dc.l	lbC000402
;	dc.l	DTP_StartInt
;	dc.l	lbC000204
;	dc.l	DTP_StopInt
;	dc.l	lbC0002DA
;	dc.l	DTP_Interrupt
;	dc.l	lbC00067C
;	dc.l	DTP_PrevSong
;	dc.l	lbC0001A8
;	dc.l	DTP_NextSong
;	dc.l	lbC0001DC
;	dc.l	DTP_Volume
;	dc.l	lbC0005DC
;	dc.l	DTP_Balance
;	dc.l	lbC0005DC
;	dc.l	$80004552
;	dc.l	lbC0005C2
;;	dc.l	$8000455D
;;	dc.l	lbC0002C6
;	dc.l	$80004558
;	dc.l	lbC0001A2
;	dc.l	$8000455E
;	dc.l	$9734
;	dc.l	0
;VSS.MSG	dc.b	'VSS',0
;c1993TomasPar.MSG	dc.b	'(c) 1993 Tomas Partl,',$A
;	dc.b	'Voodoo Software / Buggs of DEFECT',0
;ciabresource.MSG	dc.b	'ciab.resource',0
;lbL00013E	dc.l	0
;_Base_	dc.l	0
;lbW000146	dc.w	0
lbW000148	dc.w	0
lbW00014A	dc.w	0
lbW00014C	dc.w	0
lbW00014E	dc.w	0
lbW000150	dc.w	0
lbL000152	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.w	0
lbL000164	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.w	0
lbL000176	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.w	0
lbL000188	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.w	0


;lbC0001A2	LEA	lbL000152(PC),A0
;	RTS

PrevSong
lbC0001A8	LEA	DataArea(PC),A4
	BTST	#2,$48(A4)
	BEQ.B	lbC0001D4
	BSR.W	lbC0002DA
	BSR.W	lbC000574
	TST.L	D0
	BEQ.B	lbC0001C8
	BRA.B	lbC000204

lbC0001C8	BSR.W	lbC000402
	BSR.W	lbC000382
	BRA.B	lbC000204

lbC0001D4	BSR.W	lbC000574
	BRA.W	lbC000382

NextSong
lbC0001DC	LEA	DataArea(PC),A4
	BTST	#2,$48(A4)
	BEQ.B	lbC0001FC
	BSR.B	lbC0002DA
	BSR.W	lbC000550
	TST.L	D0
	BEQ.B	lbC0001C8
	BRA.B	lbC000204

lbC0001FC	BSR.W	lbC000550
	BRA.W	lbC000382

StartInt
lbC000204	MOVEQ	#-1,D0
	LEA	DataArea(PC),A4
	BTST	#2,$48(A4)
	BNE.W	lbC000340
	CLR.W	lbW000148
;	MOVE.L	lbL00013E(PC),A6
;	LEA	lbL00073A(PC),A1
;	MOVEQ	#0,D0
;	JSR	-6(A6)
;	TST.L	D0
;	BNE	lbC0002C4
	LEA	lbL00075E(PC),A1
	MOVEQ	#7,D0
	MOVE.L	4.W,A6
	JSR	-$A2(A6)
	MOVE.L	D0,$28(A4)
	LEA	lbL000780(PC),A1
	MOVEQ	#8,D0
	JSR	-$A2(A6)
	MOVE.L	D0,$2C(A4)
	LEA	lbL0007A2(PC),A1
	MOVEQ	#9,D0
	JSR	-$A2(A6)
	MOVE.L	D0,$30(A4)
	LEA	lbL0007C4(PC),A1
	MOVEQ	#10,D0
	JSR	-$A2(A6)
	MOVE.L	D0,$34(A4)
lbC00026A	
	;MOVE.B	#$81,$BFDE00
	;MOVE.L	_Base_(PC),A5
	;MOVE.L	12(A5),A1 	* GFXBase
	;BTST	#2,$CF(A1)	
	;BEQ.S	lbC000288
	;MOVE.W	#$37EE,D2	* PAL/NTSC TIMER
	;BRA.S	lbC00028C

;lbC000288	
;	MOVE.W	#$376B,D2 * PAL/NTSC TIMER
;lbC00028C	
;	SUB.W	lbW000146(PC),D2
;	CMP.W	#$700,D2
;	BHI.S	lbC00029A
;	MOVE.W	#$700,D2
;lbC00029A	LEA	$BFD000,A3
;	MOVE.B	D2,$400(A3)
;	LSR.W	#8,D2
;	MOVE.B	D2,$500(A3)
;	MOVEQ	#0,D0
	MOVE.W	#1,lbW000148
;	MOVE.W	#$8780,$DFF09A
	move	#INTF_SETCLR|INTF_AUD0|INTF_AUD1|INTF_AUD2|INTF_AUD3,$dff09a
	BSET	#2,$48(A4)
	MOVEQ	#0,D0
lbC0002C4	RTS

;SetSpeed
;lbC0002C6	TST.W	lbW000148
;	BEQ.S	lbC0002C4
;	MULU	#$14A,D0
;	MOVE.W	D0,lbW000146
;	BRA.S	lbC00026A

StopInt
lbC0002DA	
	;MOVE.W	#$780,$DFF09A
	move	#INTF_AUD0|INTF_AUD1|INTF_AUD2|INTF_AUD3,$dff09a
	LEA	DataArea(PC),A4
	BTST	#2,$48(A4)
	BEQ.B	lbC000340
	TST.W	lbW000148
	BEQ.S	lbC000340
	CLR.W	lbW000148
;	MOVE.L	lbL00013E(PC),A6
;	LEA	lbL00073A(PC),A1
;	MOVEQ	#0,D0
;	JSR	-12(A6)
	MOVE.L	4.W,A6
	MOVE.L	$28(A4),A1
	MOVEQ	#7,D0
	JSR	-$A2(A6)
	MOVE.L	$2C(A4),A1
	MOVEQ	#8,D0
	JSR	-$A2(A6)
	MOVE.L	$30(A4),A1
	MOVEQ	#9,D0
	JSR	-$A2(A6)
	MOVE.L	$34(A4),A1
	MOVEQ	#10,D0
	JSR	-$A2(A6)
	BCLR	#2,$48(A4)
	MOVEQ	#0,D0
lbC000340	RTS

;Check2
;lbC000342	
;	;MOVE.L	$24(A5),A0
;	;MOVE.L	$28(A5),D0
;	
lbC00034A	ADDQ.L	#1,D0
	AND.L	#$FFFFFFFE,D0
	ADD.L	D0,A0
	LEA	DataArea(PC),A4
	MOVEQ	#-1,D0
	SUB.W	#$40,A0
	MOVEQ	#$1F,D1
lbC000360	CMP.L	#$56535330,(A0)
	BEQ.B	lbC000372
	ADDQ.L	#2,A0
	DBRA	D1,lbC000360
	RTS

lbC000372	CMP.L	#$100,4(A0)
	BHS.B	lbC000340
	MOVEQ	#0,D0
	RTS

InitSound
lbC000382	LEA	DataArea(PC),A4
	;MOVE.L	A5,0(A4)
	MOVEQ	#0,D0
	;MOVE.L	$38(A5),A0	* dtg_GetListData
	;JSR	(A0)
	move.l	moduleAddress(pc),a0
	move.l	moduleLength(pc),d0
	BSR.B	lbC00034A
	MOVE.L	A0,$10(A4)
	CLR.L	4(A4)
	MOVE.L	4(A0),D3
	SUBQ.L	#1,D3
	MOVE.L	D3,12(A4)
	MOVEQ	#-1,D0
	LEA	DataArea(PC),A4
	BTST	#2,$48(A4)
	BNE.B	lbC000340
	MOVE.L	$10(A4),A0
	BSR.W	lbC00059C
	MOVE.L	8(A4),D1
	ASL.W	#2,D1
	ADDQ.W	#8,D1
	MOVE.L	0(A0,D1.W),D0
	ADD.L	D0,A0
	MOVE.L	A0,$14(A4)
	MOVE.L	A0,D1
	MOVE.L	(A0),D0
	ADD.L	D1,D0
	MOVE.L	D0,$18(A4)
	MOVE.L	4(A0),D0
	ADD.L	D1,D0
	MOVE.L	D0,$1C(A4)
	MOVE.L	8(A0),D0
	ADD.L	D1,D0
	MOVE.L	D0,$20(A4)
	MOVE.L	12(A0),D0
	ADD.L	D1,D0
	MOVE.L	D0,$24(A4)
	BSR.W	lbC0008BA
	CLR.L	D0
	RTS

EndSound
lbC000402	MOVEQ	#-1,D0
	LEA	DataArea(PC),A4
	BTST	#2,$48(A4)
	BNE.W	lbC000340
	MOVE.W	#15,$DFF096
	MOVEQ	#0,D0
	RTS

InitPlayer
lbC00041E	
;	MOVE.L	A5,_Base_
;	LEA	ciabresource.MSG(PC),A1
;	MOVEQ	#0,D0
;	MOVE.L	4.W,A6
;	JSR	-$1F2(A6)
;	MOVE.L	D0,lbL00013E
;	TST.L	D0
;	BNE.S	lbC000440
;	MOVEQ	#1,D0
;	RTS

lbC000440
;	MOVE.L	4(A5),lbL0007E6
;	MOVE.L	8(A5),lbL0007EA
;	MOVE.L	12(A5),lbL0007EE
	LEA	DataArea(PC),A4
	CLR.L	8(A4)
	BTST	#1,$48(A4)
	BNE.B	lbC0004BE
	MOVE.L	#$200,D0
	MOVE.L	#$10003,D1
	MOVE.L	4.w,A6
	JSR	-$C6(A6)
	TST.L	D0
	BEQ.B	lbC0004E4
	LEA	DataArea(PC),A4
	MOVE.L	D0,$38(A4)
	ADD.L	#$40,D0
	MOVE.L	D0,$3C(A4)
	ADD.L	#$40,D0
	MOVE.L	D0,$40(A4)
	ADD.L	#$40,D0
	MOVE.L	D0,$44(A4)
	ADD.L	#$40,D0
	MOVE.L	D0,lbL00172A
	BSET	#1,$48(A4)
lbC0004BE	BTST	#0,$48(A4)
	BNE.W	lbC000340
	;MOVE.L	$4C(A5),A0	 * dtg_AudioAlloc
	;JSR	(A0)
	;TST.L	D0
	;BNE	lbC0004E0
	LEA	DataArea(PC),A4
	BSET	#0,$48(A4)   * Initialization flag
	moveq	#0,d0
	RTS

;lbC0004E0	MOVEQ	#2,D0
;	RTS

lbC0004E4	
	* No memory
	MOVEQ	#1,D0
	RTS

EndPlayer
lbC0004E8	LEA	DataArea(PC),A4
	MOVE.L	$38(A4),A1
	BTST	#1,$48(A4)
	BEQ.B	lbC000514
	MOVE.L	#$200,D0
	MOVE.L	4.w,A6
	JSR	-$D2(A6)
	LEA	DataArea(PC),A4
	BCLR	#1,$48(A4)
lbC000514	LEA	DataArea(PC),A4
	BTST	#0,$48(A4)
	BEQ.B	lbC000532
	;MOVE.L	$50(A5),A0
	;JSR	(A0)
	LEA	DataArea(PC),A4
	BCLR	#0,$48(A4)
lbC000532	MOVE.W	#15,$96(A1)
	RTS

SubSongRange
lbC00053A	
	MOVEQ	#0,D0
;	MOVE.L	$38(A5),A0	* dtg_GetListData
;	JSR	(A0)
	move.l	moduleAddress(pc),a0
	move.l	moduleLength(pc),d0
	BSR.W	lbC00034A
	MOVE.L	4(A0),D1
	SUBQ.L	#1,D1
	MOVEQ	#0,D0
	RTS

lbC000550	MOVEQ	#-1,D0
	LEA	DataArea(PC),A4
	MOVE.L	8(A4),D1
	MOVE.L	12(A4),D2
	CMP.L	D2,D1
	BHS.W	lbC000340
	ADDQ.L	#1,8(A4)
	MOVE.L	8(A4),D0
	;MOVE.W	D0,$2C(A5)	; dtg_SndNum
	move	d0,currentSong
	CLR.L	D0
	RTS

lbC000574	MOVE.L	#$FFFFFFFF,D0
	LEA	DataArea(PC),A4
	MOVE.L	8(A4),D1
	MOVE.L	4(A4),D2
	CMP.L	D1,D2
	BHS.W	lbC000340
	SUBQ.L	#1,8(A4)
	MOVE.L	8(A4),D0
	;MOVE.W	D0,$2C(A5)	;dtg_SndNum
	move	d0,currentSong
	CLR.L	D0
	RTS

lbC00059C	MOVE.L	D0,-(SP)
	MOVE.L	8(A4),D0
	CMP.L	4(A4),D0
	BLO.B	lbC0005B6
	CMP.L	12(A4),D0
	BHI.B	lbC0005B6
	MOVE.L	(SP)+,D0
	RTS

lbC0005B6
	CLR.L	8(A4)
	;CLR.W	$2C(A5)	; dtg_SndNum
	clr	currentSong
	MOVE.L	(SP)+,D0
	RTS

SetVoices
lbC0005C2	MOVE.W	D0,lbW000150
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVEQ	#0,D2
	MOVE.W	lbW00014A(PC),D0
	MOVE.W	lbW00014C(PC),D1
	MOVE.W	lbW00014E(PC),D2
	BRA.S	lbC000600

Volume
lbC0005DC	
	;MOVEQ	#0,D0
	;MOVEQ	#0,D1
	;MOVEQ	#0,D2
	;MOVE.W	$2E(A5),D0
	;;MOVE.W	$30(A5),D1
	;MOVE.W	$32(A5),D2
	;move	#$40,d0
	moveq	#$40,d1
	moveq	#$40,d2
	
	MOVE.W	D0,lbW00014A
	MOVE.W	D1,lbW00014C
	MOVE.W	D2,lbW00014E
lbC000600	MOVE.W	lbW000150(PC),D5
	MULU	D0,D1
	LSR.W	#6,D1
	MULU	D0,D2
	LSR.W	#6,D2
	MOVE.W	D1,D4
	MOVE.W	D2,D3
	BTST	#0,D5
	BNE.S	lbC00061E
	MOVEQ	#0,D1
	CLR.W	$DFF0A8
lbC00061E	LEA	lbL000152(PC),A1
	MOVE.B	D1,lbB001658
	MOVE.W	D1,8(A1)
	BTST	#3,D5
	BNE.S	lbC00063A
	MOVEQ	#0,D4
	CLR.W	$DFF0D8
lbC00063A	MOVE.B	D4,lbB00171E
	MOVE.W	D4,$3E(A1)
	BTST	#1,D5
	BNE.S	lbC000652
	MOVEQ	#0,D2
	CLR.W	$DFF0B8
lbC000652	MOVE.B	D2,lbB00169A
	MOVE.W	D2,$1A(A1)
	BTST	#2,D5
	BNE.S	lbC00066A
	MOVEQ	#0,D3
	CLR.W	$DFF0C8
lbC00066A	MOVE.W	D5,$48(A1)
	MOVE.B	D3,lbB0016DC
	MOVE.W	D3,$2C(A1)
	MOVEQ	#0,D0
	RTS

Interrupt
lbC00067C
	MOVEM.L	D0-D7/A0-A6,-(SP)
	LEA	lbL000152(PC),A3
	MOVE.W	#$FFFF,$4C(A3)
	MOVE.W	#$8F,$4A(A3)
	CLR.W	6(A3)
	CLR.W	$18(A3)
	CLR.W	$2A(A3)
	CLR.W	$3C(A3)
	BSR.W	lbC000A9C
	LEA	lbL000152(PC),A1
	CLR.W	$4C(A1)
	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

lbC0006B2	MOVEM.L	D0-D7/A0-A6,-(SP)
	LEA	lbL001618(PC),A0
	BSR.W	lbC000A50
	BEQ.S	lbC0006C6
	MOVE.L	D1,lbL000152
lbC0006C6	MOVEM.L	(SP)+,D0-D7/A0-A6
	MOVE.W	#$80,$DFF09C
	RTS

lbC0006D4	MOVEM.L	D0-D7/A0-A6,-(SP)
	LEA	lbL00165A(PC),A0
	BSR.W	lbC000A50
	BEQ.S	lbC0006E8
	MOVE.L	D1,lbL000164
lbC0006E8	MOVEM.L	(SP)+,D0-D7/A0-A6
	MOVE.W	#$100,$DFF09C
	RTS

lbC0006F6	MOVEM.L	D0-D7/A0-A6,-(SP)
	LEA	lbL00169C(PC),A0
	BSR.W	lbC000A50
	BEQ.S	lbC00070A
	MOVE.L	D1,lbL000176
lbC00070A	MOVEM.L	(SP)+,D0-D7/A0-A6
	MOVE.W	#$200,$DFF09C
	RTS

lbC000718	MOVEM.L	D0-D7/A0-A6,-(SP)
	LEA	lbL0016DE(PC),A0
	BSR.W	lbC000A50
	BEQ.S	lbC00072C
	MOVE.L	D1,lbL000188
lbC00072C	MOVEM.L	(SP)+,D0-D7/A0-A6
	MOVE.W	#$400,$DFF09C
	RTS
;
;lbL00073A	dc.l	0
;	dc.l	0
;	dc.w	$400
;	dc.l	VSSsoundstep.MSG
;	dc.w	0
;	dc.w	0
;	dc.l	lbC00067C
;VSSsoundstep.MSG	dc.b	'VSS soundstep',0
lbL00075E	dc.l	0
	dc.l	0
	dc.w	$400
	dc.l	VSSaudio0.MSG
	dc.w	0
	dc.w	0
	dc.l	lbC0006B2
VSSaudio0.MSG	dc.b	'VSS audio 0',0
lbL000780	dc.l	0
	dc.l	0
	dc.w	$400
	dc.l	VSSaudio1.MSG
	dc.w	0
	dc.w	0
	dc.l	lbC0006D4
VSSaudio1.MSG	dc.b	'VSS audio 1',0
lbL0007A2	dc.l	0
	dc.l	0
	dc.w	$400
	dc.l	VSSaudio2.MSG
	dc.w	0
	dc.w	0
	dc.l	lbC0006F6
VSSaudio2.MSG	dc.b	'VSS audio 2',0
lbL0007C4	dc.l	0
	dc.l	0
	dc.w	$400
	dc.l	VSSaudio3.MSG
	dc.w	0
	dc.w	0
	dc.l	lbC000718
VSSaudio3.MSG	dc.b	'VSS audio 3',0
lbL0007E6	dc.l	0
lbL0007EA	dc.l	0
lbL0007EE	dc.l	0
DataArea	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0

lbC0008BA	MOVE.B	lbB001658(pc),D2
	MOVE.B	lbB00169A(pc),D3
	MOVE.B	lbB0016DC(pc),D4
	MOVE.B	lbB00171E(pc),D5
	LEA	lbL001618(PC),A0
	MOVE.L	A0,D1
	MOVE.L	#lbL00165A,D0
	SUB.L	D1,D0
lbC0008E0	CLR.L	(A0)+
	DBRA	D0,lbC0008E0
	MOVE.B	D2,lbB001658
	MOVE.B	D3,lbB00169A
	MOVE.B	D4,lbB0016DC
	MOVE.B	D5,lbB00171E
	MOVE.B	#1,lbB001632
	MOVE.B	#1,lbB001674
	MOVE.B	#1,lbB0016B6
	MOVE.B	#1,lbB0016F8
	MOVE.B	#1,lbB001622
	MOVE.B	#1,lbB001664
	MOVE.B	#1,lbB0016A6
	MOVE.B	#1,lbB0016E8
	MOVE.L	#lbL001524,lbL001636
	MOVE.L	#lbL001574,lbL001678
	MOVE.L	#lbL0015C4,lbL0016BA
	MOVE.L	#lbL001614,lbL0016FC
	CLR.B	lbB001649
	CLR.B	lbB00168B
	CLR.B	lbB0016CD
	CLR.B	lbB00170F
	LEA	DataArea(PC),A4
	MOVE.L	$14(A4),lbL001726
	MOVE.L	$18(A4),lbL00162E
	MOVE.L	$1C(A4),lbL001670
	MOVE.L	$20(A4),lbL0016B2
	MOVE.L	$24(A4),lbL0016F4
	LEA	$DFF000,A1
	MOVE.W	#$10,$A4(A1)
	MOVE.W	#$10,$B4(A1)
	MOVE.W	#$10,$C4(A1)
	MOVE.W	#$10,$D4(A1)
	MOVE.W	#0,$A8(A1)
	MOVE.W	#0,$B8(A1)
	MOVE.W	#0,$C8(A1)
	MOVE.W	#0,$D8(A1)
	MOVE.L	$38(A4),lbL001624
	MOVE.L	$3C(A4),lbL001666
	MOVE.L	$40(A4),lbL0016A8
	MOVE.L	$44(A4),lbL0016EA
	MOVE.L	#$DFF0A0,lbL00162A
	MOVE.L	#$DFF0B0,lbL00166C
	MOVE.L	#$DFF0C0,lbL0016AE
	MOVE.L	#$DFF0D0,lbL0016F0
	MOVE.L	lbL00172A(pc),$A0(A1)
	MOVE.L	lbL00172A(pc),$B0(A1)
	MOVE.L	lbL00172A(pc),$C0(A1)
	MOVE.L	lbL00172A(pc),$D0(A1)
	MOVE.W	#$800F,$96(A1)
	RTS

lbC000A50	BTST	#5,$3A(A0)
	BEQ.W	lbC000340
	MOVEQ	#0,D0
	MOVE.W	10(A0),D0
	MOVE.L	(A0),D1
	ADD.L	D0,(A0)
	BTST	#1,$3A(A0)
	BNE.S	lbC000A7C
	MOVE.L	4(A0),A1
	MOVE.W	-2(A1),D0
	ADD.L	4(A0),D0
	CMP.L	(A0),D0
	BHS.S	lbC000A8C
lbC000A7C	MOVE.L	lbL00172A(pc),D1
	MOVE.L	D1,(A0)
	BSET	#1,$3A(A0)
	BRA.S	lbC000A92

lbC000A8C	BCLR	#1,$3A(A0)
lbC000A92	MOVE.L	$12(A0),A1
	MOVE.L	D1,(A1)
	MOVEQ	#1,D0
	RTS

lbC000A9C	MOVE.L	lbL001722(pc),D0
lbC000AA2	MOVE.L	D0,-(SP)
	CLR.W	lbW001720
	LEA	lbL001618,A0
	MOVE.W	#$8001,D7
	BSR.S	lbC000B0E
	LEA	lbL00165A,A0
	MOVE.W	#$8002,D7
	BSR.S	lbC000B0E
	LEA	lbL00169C,A0
	MOVE.W	#$8004,D7
	BSR.S	lbC000B0E
	LEA	lbL0016DE,A0
	MOVE.W	#$8008,D7
	BSR.S	lbC000B0E
	CMP.W	#15,lbW001720
	BNE.B	lbC000AF4
	move.l	songEndAddress(pc),a4
	st	(a4)
	;LEA	DataArea(PC),A4
	;MOVE.L	0(A4),A5
	;MOVE.L	$5C(A5),A0	;dtg_SongEnd
	;JSR	(A0)
lbC000AF4	MOVE.L	(SP)+,D0
	DBRA	D0,lbC000AA2
	RTS

lbC000AFC	MOVE.B	D1,$1B(A0)
	MOVE.B	#1,$2E(A0)
	ADDQ.B	#2,D0
	MOVE.B	D0,$32(A0)
	BRA.S	lbC000B5E

lbC000B0E	SUB.B	#1,$1A(A0)
	BNE.S	lbC000B1A
	BSR.W	lbC0010BA
lbC000B1A	SUBQ.B	#1,$2E(A0)
	BNE.S	lbC000B56
lbC000B20	MOVE.L	$22(A0),A3
	CLR.L	D0
	MOVE.B	$32(A0),D0
	ADD.L	D0,A3
	MOVE.B	(A3),D1
	CMP.B	#$88,D1
	BNE.S	lbC000B3C
	MOVE.B	1(A3),$32(A0)
	BRA.S	lbC000B20

lbC000B3C	tst.b 1(A3)
	BEQ.S	lbC000AFC
	MOVE.B	D1,$3F(A0)
	MOVE.B	1(A3),$2E(A0)
	ADD.B	#2,D0
	MOVE.B	D0,$32(A0)
lbC000B56	MOVE.B	$3F(A0),D1
	ADD.B	D1,$1B(A0)
lbC000B5E	SUB.B	#1,$2F(A0)
	BNE.S	lbC000B96
lbC000B66	
	tst.l	$26(a0)
	beq.b	skip2
	MOVE.L	$26(A0),A3
	CLR.L	D0
	MOVE.B	$33(A0),D0
	ADD.L	D0,A3
	CLR.L	D1
	* ENFORCER:
	MOVE.B	(A3),D1
	CMP.B	#$FF,D1
	BNE.S	lbC000B84
	MOVE.B	1(A3),$33(A0)
	BRA.S	lbC000B66

lbC000B84	MOVE.B	D1,$34(A0)
	* ENFORCER:
	MOVE.B	1(A3),$2F(A0)
	ADD.B	#2,D0
	MOVE.B	D0,$33(A0)
lbC000B96	SUB.B	#1,$2D(A0)
	BNE.S	lbC000BAC
	MOVE.B	#0,$2B(A0)
	MOVE.B	#0,$30(A0)
	BRA.S	lbC000BD4

lbC000BAC	SUB.B	#1,$30(A0)
	BNE.S	lbC000BD4
	MOVE.B	$2C(A0),$30(A0)
	CLR.L	D0
	MOVE.B	$2B(A0),D0
	CMP.W	#$7F,D0
	BPL.S	lbC000BCC
	ADD.W	D0,$1C(A0)
	BRA.S	lbC000BD4

lbC000BCC	AND.W	#$7F,D0
	SUB.W	D0,$1C(A0)
skip2
lbC000BD4	
	CLR.L	D0
	MOVE.B	$34(A0),D0
	CMP.B	#$FE,D0
	BEQ.S	lbC000C08
	CMP.B	#$7F,D0
	BEQ.S	lbC000C00
	CMP.B	#$7E,D0
	BEQ.S	lbC000C10
	CMP.B	#$7F,D0
	BLO.W	lbC000CD6
	AND.W	#$7F,D0
	SUB.W	D0,$1C(A0)
	BRA.W	lbC000CDA

lbC000C00	LSR.W	$1C(A0)
	BRA.W	lbC000CDA

lbC000C08	ASL.W	$1C(A0)
	BRA.W	lbC000CDA

lbC000C10	CLR.L	D0
	MOVE.B	$2F(A0),D0
	MOVE.B	#1,$2F(A0)
	BTST	#7,D0
	BNE.S	lbC000C5A
	CMP.B	#13,D0
	BLO.S	lbC000C42
	DIVU	#12,D0
	MOVE.W	D0,D3
	AND.L	#7,D3
	MOVE.W	$1C(A0),D2
	LSR.W	D3,D2
	MOVE.W	D2,$1C(A0)
	CLR.W	D0
	SWAP	D0
lbC000C42	LEA	lbL0014A0,A1
	ASL.W	#2,D0
	ADD.L	D0,A1
	CLR.L	D2
	MOVE.W	(A1),D2
	MOVE.W	2(A1),D1
	MOVE.W	#0,D4
	BRA.S	lbC000C94

lbC000C5A	AND.B	#$7F,D0
	CMP.B	#13,D0
	BLO.S	lbC000C7E
	DIVU	#12,D0
	MOVE.W	D0,D3
	AND.L	#7,D3
	MOVE.W	$1C(A0),D2
	ASL.W	D3,D2
	MOVE.W	D2,$1C(A0)
	CLR.W	D0
	SWAP	D0
lbC000C7E	LEA	lbL0014A0(pc),A1
	ASL.W	#2,D0
	ADD.L	D0,A1
	CLR.L	D2
	MOVE.W	(A1),D1
	MOVE.W	2(A1),D2
	MOVE.W	#1,D4
lbC000C94	CLR.L	D3
	MOVE.W	$1C(A0),D3
	MULU	D1,D3
	MOVE.L	D3,D1
	SWAP	D3
	DIVU	D2,D3
	SWAP	D3
	DIVU	D2,D1
	MOVE.W	D1,D3
	SWAP	D1
	CMP.W	#0,D1
	BEQ.S	lbC000CB2
	ADD.W	D4,D3
lbC000CB2	MOVE.W	D3,$1C(A0)
	BRA.S	lbC000CDA

lbC000CB8	MOVEM.L	D0/D1,-(SP)
	MOVEQ	#4,D0
lbC000CBE	MOVE.B	$DFF006,D1
lbC000CC4	CMP.B	$DFF006,D1
	BEQ.S	lbC000CC4
	DBRA	D0,lbC000CBE
	MOVEM.L	(SP)+,D0/D1
	RTS

lbC000CD6	ADD.W	D0,$1C(A0)
lbC000CDA	BSR.B	lbC000CB8
	MOVE.W	D7,$DFF096
	BSR.B	lbC000CB8
	MOVE.L	$12(A0),A2
	MOVE.W	$3C(A0),6(A2)
	MOVE.B	$3E(A0),9(A2)
	MOVE.L	A1,-(SP)
	LEA	lbL000152(PC),A1
	CMP.L	#$DFF0A0,A2
	BEQ.S	lbC000D22
	LEA	lbL000164(PC),A1
	CMP.L	#$DFF0B0,A2
	BEQ.S	lbC000D22
	LEA	lbL000176(PC),A1
	CMP.L	#$DFF0C0,A2
	BEQ.S	lbC000D22
	LEA	lbL000188(PC),A1
lbC000D22	MOVE.W	$3C(A0),D0
	BEQ.S	lbC000D3E
	MOVEQ	#0,D1
	MOVE.B	$3E(A0),D1
	BEQ.S	lbC000D3E
	MOVE.L	12(A0),0(A1)
	MOVE.W	#$40,4(A1)
	BRA.S	lbC000D46

lbC000D3E	CLR.L	0(A1)
	CLR.W	4(A1)
lbC000D46	MOVE.W	D0,6(A1)
	MOVE.W	D1,8(A1)
	MOVE.L	(SP)+,A1
	MOVE.W	$1C(A0),$3C(A0)
	CLR.L	D0
	CLR.L	D1
	MOVE.B	$1B(A0),D0
	MOVE.B	$40(A0),D1
	MULU	D1,D0
	LSR.W	#6,D0
	MOVE.B	D0,$3E(A0)
	BTST	#6,$3A(A0)
	BNE.W	lbC000E4C
	BTST	#7,$3A(A0)
	BNE.W	lbC000F12
	BTST	#5,$3A(A0)
	BNE.W	lbC00102C
	SUBQ.B	#1,$11(A0)
	BNE.S	lbC000DBA
lbC000D8E	
	tst.l	$36(a0)
	beq.w	skip
	MOVE.L	$36(A0),A3
	CLR.L	D0
	MOVE.B	$35(A0),D0
	ADD.L	D0,A3
	* ENFORCER:
	MOVE.B	(A3),D1
	BTST	#7,D1
	BEQ.S	lbC000DAA
	* ENFORCER:
	MOVE.B	1(A3),$35(A0)
	BRA.S	lbC000D8E

lbC000DAA	MOVE.B	D1,10(A0)
	* ENFORCER:
	MOVE.B	1(A3),$11(A0)
	ADDQ.B	#2,D0
	MOVE.B	D0,$35(A0)
lbC000DBA	MOVE.B	9(A0),D0

	ADD.B	10(A0),D0
	AND.B	#$1F,D0
	MOVE.B	D0,9(A0)
	MOVE.L	$12(A0),A1
	MOVE.L	12(A0),A2
	MOVEQ	#0,D0
	MOVE.B	8(A0),D0
	ADD.L	D0,A2
	MOVE.L	A2,(A1)
	EOR.B	#$20,8(A0)
	MOVE.L	12(A0),A1
	MOVE.B	8(A0),D0
	ADD.L	D0,A1

	tst.l	(a0) 
	beq.b	skip
	MOVE.L	(A0),A2		* can be null
	tst.l	4(a0) 
	beq.b	skip
	MOVE.L	4(A0),A3	* 

	MOVE.B	9(A0),D0
	ADD.L	D0,A3
	SUB.B	#$1F,D0
	NEG.B	D0
	MOVE.L	#$1F,D1
	CLR.L	D2
	MOVE.B	10(A0),D2
	CLR.L	D4
	MOVE.B	11(A0),D4
	MOVE.L	D4,D3
	ADD.B	D2,D4
	MOVE.B	$10(A0),D7
lbC000E18
	* enforcer hit

	MOVE.B	(A2)+,D5
	EXT.W	D5
	MOVE.B	(A3)+,D6
	EXT.W	D6
	ADD.W	D6,D5
	LSR.W	#1,D5
	BTST	#7,D5
	BEQ.S	lbC000E32
	NEG.B	D5
	OR.B	D7,D5
	NEG.B	D5
	BRA.S	lbC000E34

lbC000E32	OR.B	D7,D5
lbC000E34	MOVE.B	D5,(A1)+
	DBRA	D0,lbC000E46
	SUB.L	#$20,A3
	MOVE.L	#$20,D0
lbC000E46	DBRA	D1,lbC000E18
skip	RTS

lbC000E4C	SUBQ.B	#1,$11(A0)
	BNE.S	lbC000E80
lbC000E52	MOVE.L	$36(A0),A3
	CLR.L	D0
	MOVE.B	$35(A0),D0
	ADD.L	D0,A3
	MOVE.B	(A3),D1
	CMP.B	#$FF,D1
	BNE.S	lbC000E6E
	MOVE.B	1(A3),$35(A0)
	BRA.S	lbC000E52

lbC000E6E	MOVE.B	D1,10(A0)
	MOVE.B	1(A3),$11(A0)
	ADD.B	#2,D0
	MOVE.B	D0,$35(A0)
lbC000E80	MOVE.L	$12(A0),A1
	MOVE.L	12(A0),A3
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVEQ	#0,D2
	MOVE.B	8(A0),D0
	ADD.L	D0,A3
	MOVE.L	A3,(A1)
	EOR.B	#$20,8(A0)
	MOVE.L	12(A0),A1
	MOVE.B	8(A0),D0
	ADD.L	D0,A1
	BTST	#7,10(A0)
	BNE.W	lbC00101E
	MOVE.L	4(A0),A2
	MOVE.B	9(A0),D0
	CLR.W	D3
	MOVE.B	10(A0),D1
	AND.B	#$1F,D1
	ADD.B	D0,D1
	BTST	#5,D1
	BEQ.S	lbC000ED2
	MOVE.B	#1,D3
	AND.B	#$1F,D1
lbC000ED2	CLR.W	D2
lbC000ED4	MOVE.B	(A3)+,D4
	CMP.B	D2,D0
	BNE.S	lbC000EDE
	EOR.B	#1,D3
lbC000EDE	CMP.B	D2,D1
	BNE.S	lbC000EE6
	EOR.B	#1,D3
lbC000EE6	BTST	#0,D3
	BEQ.S	lbC000EF4
	MOVE.B	(A2),D5
	AND.B	$10(A0),D5
	EOR.B	D5,D4
lbC000EF4	MOVE.B	D4,(A1)+
	ADDQ.L	#1,A2
	ADDQ.B	#1,D2
	CMP.B	#$20,D2
	BNE.S	lbC000ED4
	MOVE.B	10(A0),D0
	ADD.B	9(A0),D0
	AND.B	#$1F,D0
	MOVE.B	D0,9(A0)
	RTS

lbC000F12	SUBQ.B	#1,$11(A0)
	BNE.S	lbC000F4C
lbC000F18	MOVE.L	$36(A0),A3
	CLR.L	D0
	MOVE.B	$35(A0),D0
	ADD.L	D0,A3
	MOVE.B	(A3),D1
	CMP.B	#$FF,D1
	BNE.S	lbC000F34
	MOVE.B	1(A3),$35(A0)
	BRA.S	lbC000F18

lbC000F34	MOVE.B	D1,10(A0)
	MOVE.B	1(A3),$3B(A0)
	MOVE.B	2(A3),$11(A0)
	ADD.B	#3,D0
	MOVE.B	D0,$35(A0)
lbC000F4C	MOVE.L	$12(A0),A1
	MOVE.L	12(A0),A3
	CLR.L	D0
	CLR.L	D1
	CLR.L	D2
	MOVE.B	8(A0),D0
	ADD.L	D0,A3
	MOVE.L	A3,(A1)
	EOR.B	#$20,8(A0)
	MOVE.L	12(A0),A1
	MOVE.B	8(A0),D0
	ADD.L	D0,A1
	MOVE.B	$3B(A0),D6
	MOVE.B	10(A0),D0
	CMP.B	#$80,D0
	BEQ.W	lbC00101E
	AND.B	#$C0,D0
	MOVE.L	4(A0),A2
	CMP.B	#$40,D0
	BNE.S	lbC000F92
	MOVE.L	(A0),A2
lbC000F92	MOVE.B	9(A0),D0
	CLR.W	D3
	MOVE.B	10(A0),D1
	AND.B	#$1F,D1
	ADD.B	D0,D1
	BTST	#5,D1
	BEQ.S	lbC000FB0
	MOVE.B	#1,D3
	AND.B	#$1F,D1
lbC000FB0	CLR.W	D2
lbC000FB2	MOVE.B	(A3)+,D4
	CMP.B	D2,D0
	BNE.S	lbC000FBC
	EOR.B	#1,D3
lbC000FBC	CMP.B	D2,D1
	BNE.S	lbC000FC4
	EOR.B	#1,D3
lbC000FC4	BTST	#0,D3
	BEQ.S	lbC000FF4
	SUB.B	#$80,D4
	MOVE.B	(A2),D5
	SUB.B	#$80,D5
	SUB.B	D4,D5
	BHS.S	lbC000FEA
	NEG.B	D5
	CMP.B	D5,D6
	BHS.S	lbC000FE6
	ADD.B	#$80,D4
	SUB.B	D6,D4
	BRA.S	lbC000FF4

lbC000FE6	MOVE.B	(A2),D4
	BRA.S	lbC000FF4

lbC000FEA	CMP.B	D5,D6
	BHS.S	lbC000FE6
	ADD.B	#$80,D4
	ADD.B	D6,D4
lbC000FF4	MOVE.B	D4,(A1)+
	ADDQ.L	#1,A2
	ADDQ.B	#1,D2
	CMP.B	#$20,D2
	BNE.S	lbC000FB2
	MOVE.B	10(A0),D0
	MOVE.B	D0,D1
	AND.B	#$C0,D1
	CMP.B	#$C0,D1
	BEQ.S	lbC00101C
	ADD.B	9(A0),D0
	AND.B	#$1F,D0
	MOVE.B	D0,9(A0)
lbC00101C	RTS

lbC00101E	MOVE.L	(A0),A2
	MOVE.B	#$1F,D1
lbC001024	MOVE.B	(A2)+,(A1)+
	DBRA	D1,lbC001024
	RTS

lbC00102C	SUBQ.B	#1,$11(A0)
	BNE.S	lbC001070
lbC001032	MOVE.L	$36(A0),A3
	CLR.L	D0
	MOVE.B	$35(A0),D0
	ADD.L	D0,A3
	MOVE.B	(A3),D1
	CMP.B	#$FF,D1
	BNE.S	lbC00104E
	MOVE.B	1(A3),$35(A0)
	BRA.S	lbC001032

lbC00104E	CLR.L	D0
	MOVE.B	D1,D0
	ASL.W	#8,D0
	MOVE.B	1(A3),D0
	MOVE.L	4(A0),D1
	ADD.L	D1,D0
	MOVE.L	D0,(A0)
	BCLR	#1,$3A(A0)
	MOVE.B	2(A3),$11(A0)
	ADDQ.B	#3,$35(A0)
lbC001070	BTST	#0,$3A(A0)
	BNE.S	lbC001080
	MOVE.W	#$80,10(A0)
	RTS

lbC001080	CLR.L	D2
	MOVE.B	$10(A0),D2
	LEA	lbW0013E0(pc),A4
	ADD.L	D2,A4
	ADD.L	D2,A4
	MOVE.W	(A4),D2
	CLR.L	D0
	MOVE.W	$1C(A0),D0
	DIVU	D2,D0
	MOVE.L	D0,D1
	MOVE.W	#0,D1
	SWAP	D1
	AND.L	#$FFFF,D0
	MULU	#$80,D0
	MULU	#$80,D1
	DIVU	D2,D1
	ADD.L	D1,D0
	MOVE.W	D0,10(A0)
	RTS

lbC0010BA	MOVE.L	$16(A0),A2
lbC0010BE	CLR.L	D0
	MOVE.B	(A2)+,D0
	CMP.B	#$80,D0
	BHS.B	lbC00113C
	BSR.B	lbC00112C
	CLR.L	D1
	MOVE.W	(A3),$1C(A0)
lbC0010D4	BCLR	#1,$3A(A0)
	MOVE.B	(A2)+,$1A(A0)
	BTST	#5,$2A(A0)
	BNE.S	lbC0010FE
	MOVE.B	#0,$35(A0)
	MOVE.B	#1,$11(A0)
	MOVE.B	11(A0),9(A0)
	BCLR	#1,$3A(A0)
lbC0010FE	BTST	#7,$2A(A0)
	BNE.S	lbC001112
	MOVE.B	#0,$32(A0)
	MOVE.B	#1,$2E(A0)
lbC001112	BTST	#6,$2A(A0)
	BNE.S	lbC001126
	MOVE.B	#0,$33(A0)
	MOVE.B	#1,$2F(A0)
lbC001126	MOVE.L	A2,$16(A0)
	RTS

lbC00112C	LEA	lbW0013E0(pc),A3
	ADD.B	$31(A0),D0
	ADD.L	D0,A3
	ADD.L	D0,A3
	RTS

lbC00113C	AND.B	#$7F,D0
	CMP.B	#$7F,D0
	BEQ.S	lbC00118C
	SUBQ.B	#1,D0
	LEA	lbL001158(pc),A5
lbC00114E	MOVE.L	(A5)+,A4
	DBRA	D0,lbC00114E
	JMP	(A4)

	RTS

lbL001158	dc.l	lbC0011A6
	dc.l	lbC0011C4
	dc.l	lbC0011D2
	dc.l	lbC0011EE
	dc.l	lbC00120E
	dc.l	lbC001240
	dc.l	lbC00125A
	dc.l	lbC001274
	dc.l	lbC001344
	dc.l	lbL0013AC
	dc.l	lbC0013B4
	dc.l	lbC0013D0
	dc.l	lbC0013D8

lbC00118C	MOVE.B	#0,$1B(A0)
	MOVE.B	#0,$2E(A0)
	MOVE.B	(A2)+,$1A(A0)
	MOVE.W	#0,$3E(A0)
	BRA.B	lbC001126

lbC0011A6	CLR.L	D1
	CLR.L	D0
	MOVE.B	(A2)+,D0
	MOVE.L	$1E(A0),A4
	MOVE.L	A2,-(A4)
	MOVE.L	A4,$1E(A0)
	BSR.S	lbC001224
	MOVE.L	lbL001726(pc),A2
	ADD.L	D0,A2
	BRA.W	lbC0010BE

lbC0011C4	MOVE.L	$1E(A0),A4
	MOVE.L	(A4)+,A2
	MOVE.L	A4,$1E(A0)
	BRA.W	lbC0010BE

lbC0011D2	CLR.L	D0
	ADD.L	#2,A2
	MOVE.L	$1E(A0),A4
	MOVE.L	A2,-(A4)
	MOVE.B	-2(A2),D0
	MOVE.L	D0,-(A4)
	MOVE.L	A4,$1E(A0)
	BRA.W	lbC0010BE

lbC0011EE	MOVE.L	$1E(A0),A4
	MOVE.L	(A4)+,D0
	MOVE.L	(A4)+,A5
	MOVE.L	A4,$1E(A0)
	SUBQ.L	#1,D0
	BEQ.W	lbC0010BE
	MOVE.L	A5,A2
	MOVE.L	A2,-(A4)
	MOVE.L	D0,-(A4)
	MOVE.L	A4,$1E(A0)
	BRA.W	lbC0010BE

lbC00120E	CLR.L	D0
	MOVE.B	(A2)+,D0
	BSR.S	lbC001234
	MOVE.L	A3,(A0)
	CLR.L	D0
	MOVE.B	(A2)+,D0
	BSR.S	lbC001234
	MOVE.L	A3,4(A0)
	BRA.W	lbC0010BE

lbC001224	MOVE.L	lbL001726(PC),A3
	ADD.L	D0,A3
	ADD.L	D0,A3
	ADD.L	D0,A3
	ADD.L	D0,A3
	MOVE.L	(A3),D0
	RTS

lbC001234	BSR.S	lbC001224
	MOVE.L	lbL001726,A3
	ADD.L	D0,A3
	RTS

lbC001240	CLR.L	D0
	MOVE.B	(A2)+,D0
	BSR.S	lbC001234
	MOVE.L	A3,$22(A0)
	MOVE.B	#0,$32(A0)
	MOVE.B	#1,$2E(A0)
	BRA.W	lbC0010BE

lbC00125A	CLR.L	D0
	MOVE.B	(A2)+,D0
	BSR.S	lbC001234
	MOVE.L	A3,$26(A0)
	MOVE.B	#0,$33(A0)
	MOVE.B	#1,$2F(A0)
	BRA.W	lbC0010BE

lbC001274	CLR.L	D0
	MOVE.B	(A2)+,D0
	BSR.S	lbC001234
	MOVE.L	A3,$36(A0)
	MOVE.B	#0,$35(A0)
	MOVE.B	#1,$11(A0)
	MOVE.B	(A2)+,D0
	MOVE.B	$3A(A0),D1
	MOVE.L	$12(A0),A4
	BTST	#5,D0
	BNE.S	lbC001304
	MOVE.B	D0,9(A0)
	AND.B	#$1F,9(A0)
	MOVE.B	D0,$3A(A0)
	MOVE.B	9(A0),11(A0)
	BTST	#5,D1
	BNE.S	lbC0012B8
	BRA.W	lbC0010BE

lbC0012B8	MOVE.L	12(A0),(A4)
	MOVE.W	#$10,4(A4)
	MOVE.L	A2,-(SP)
	LEA	lbL000152(PC),A2
	CMP.L	#$DFF0A0,A4
	BEQ.S	lbC0012EC
	LEA	lbL000164(PC),A2
	CMP.L	#$DFF0B0,A4
	BEQ.S	lbC0012EC
	LEA	lbL000176(PC),A2
	CMP.L	#$DFF0C0,A4
	BEQ.S	lbC0012EC
	LEA	lbL000188(PC),A2
lbC0012EC	MOVE.L	12(A0),0(A2)
	MOVE.W	#$10,4(A2)
	MOVE.L	(SP)+,A2
	MOVE.W	#0,10(A0)
	BRA.W	lbC0010BE

lbC001304	MOVE.B	D0,$3A(A0)
	MOVE.W	#$40,4(A4)
	MOVE.L	A2,-(SP)
	LEA	lbL000152(PC),A2
	CMP.L	#$DFF0A0,A4
	BEQ.S	lbC001338
	LEA	lbL000164(PC),A2
	CMP.L	#$DFF0B0,A4
	BEQ.S	lbC001338
	LEA	lbL000176(PC),A2
	CMP.L	#$DFF0C0,A4
	BEQ.S	lbC001338
	LEA	lbL000188(PC),A2
lbC001338	MOVE.W	#$40,4(A2)
	MOVE.L	(SP)+,A2
	BRA.W	lbC0010BE

lbC001344	CLR.L	D0
	MOVE.B	(A2),D0
	BSR.W	lbC00112C
	MOVE.W	(A3),D1
	MOVE.W	D1,$1C(A0)
	CLR.L	D0
	MOVE.B	1(A2),D0
	BSR.W	lbC00112C
	MOVE.W	(A3),D0
	CLR.L	D2
	SUB.W	D1,D0
	BPL.S	lbC00136A
	MOVE.B	#$80,D2
	NEG.W	D0
lbC00136A	MOVE.L	D0,D3
	CLR.L	D4
	MOVE.B	2(A2),D4
	DIVU	D4,D0
	CMP.B	#0,D0
	BNE.S	lbC00137E
	MOVE.B	#1,D0
lbC00137E	OR.B	D0,D2
	MOVE.B	D2,$2B(A0)
	DIVU	D3,D4
	MOVE.B	D4,$2C(A0)
	MOVE.B	#1,$30(A0)
	CMP.B	#0,D4
	BNE.S	lbC00139C
	MOVE.B	#1,$2C(A0)
lbC00139C	MOVE.B	2(A2),$2D(A0)
	ADD.L	#2,A2
	BRA.W	lbC0010D4

lbL0013AC	
	MOVE.B	(A2)+,$0031(A0)
	bra.w	lbC0010BE

lbC0013B4
	CLR.L	D0
	MOVE.B	(A2)+,D0
	BSR.W	lbC001234
	MOVE.L	A3,A2
	ASL.W	lbW001720
	OR.W	#1,lbW001720
	BRA.W	lbC0010BE

lbC0013D0	MOVE.B	(A2)+,$2A(A0)
	BRA.W	lbC0010BE

lbC0013D8	MOVE.B	(A2)+,$10(A0)
	BRA.W	lbC0010BE

lbW0013E0	dc.w	$7E00
	dc.w	$7700
	dc.w	$7000
	dc.w	$6A00
	dc.w	$6400
	dc.w	$5E80
	dc.w	$5900
	dc.w	$5400
	dc.w	$4F80
	dc.w	$4B00
	dc.w	$4680
	dc.w	$4519
	dc.w	$3F00
	dc.w	$3B80
	dc.w	$3800
	dc.w	$3500
	dc.w	$3200
	dc.w	$2F40
	dc.w	$2C80
	dc.w	$2A00
	dc.w	$27C0
	dc.w	$2580
	dc.w	$2340
	dc.w	$2140
	dc.w	$1F80
	dc.w	$1DC0
	dc.w	$1C00
	dc.w	$1A80
	dc.w	$1900
	dc.w	$17A0
	dc.w	$1640
	dc.w	$1500
	dc.w	$13E0
	dc.w	$12C0
	dc.w	$11A0
	dc.w	$10A0
	dc.w	$FC0
	dc.w	$EE0
	dc.w	$E00
	dc.w	$D40
	dc.w	$C80
	dc.w	$BD0
	dc.w	$B20
	dc.w	$A80
	dc.w	$9F0
	dc.w	$960
	dc.w	$8D0
	dc.w	$850
	dc.w	$7E0
	dc.w	$770
	dc.w	$700
	dc.w	$6A0
	dc.w	$640
	dc.w	$5E8
	dc.w	$590
	dc.w	$540
	dc.w	$4F8
	dc.w	$4B0
	dc.w	$468
	dc.w	$428
	dc.w	$3F0
	dc.w	$3B8
	dc.w	$380
	dc.w	$350
	dc.w	$320
	dc.w	$2F4
	dc.w	$2C8
	dc.w	$2A0
	dc.w	$27C
	dc.w	$258
	dc.w	$234
	dc.w	$214
	dc.w	$1F8
	dc.w	$1DC
	dc.w	$1C0
	dc.w	$1A8
	dc.w	$190
	dc.w	$17A
	dc.w	$164
	dc.w	$150
	dc.w	$13E
	dc.w	$12C
	dc.w	$11A
	dc.w	$10A
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
lbL0014A0	dc.l	$10001
	dc.l	$6B0065
	dc.l	$370031
	dc.l	$2C0025
	dc.l	$A0007F
	dc.l	$40003
	dc.l	$8C0063
	dc.l	$DA0092
	dc.l	$64003F
	dc.l	$6F0042
	dc.l	$620037
	dc.l	$A80059
	dc.l	$20001
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
lbL001524	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
lbL001574	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
lbL0015C4	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
lbL001614	dc.l	0
lbL001618	dc.l	0
	dc.l	0
	dc.w	0
lbB001622	dc.b	0
	dc.b	0
lbL001624	dc.l	$38
	dc.w	0
lbL00162A	dc.l	$DFF0A0
lbL00162E	dc.l	0
lbB001632	dc.b	1
	dc.b	0
	dc.b	0
	dc.b	0
lbL001636	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.w	0
	dc.b	0
lbB001649	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
lbB001658	dc.b	0
	dc.b	0
lbL00165A	dc.l	0
	dc.l	0
	dc.w	0
lbB001664	dc.b	0
	dc.b	0
lbL001666	dc.l	$3C
	dc.w	0
lbL00166C	dc.l	$DFF0B0
lbL001670	dc.l	0
lbB001674	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
lbL001678	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.w	0
	dc.b	0
lbB00168B	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
lbB00169A	dc.b	0
	dc.b	0
lbL00169C	dc.l	0
	dc.l	0
	dc.w	0
lbB0016A6	dc.b	0
	dc.b	0
lbL0016A8	dc.l	$40
	dc.w	0
lbL0016AE	dc.l	$DFF0C0
lbL0016B2	dc.l	0
lbB0016B6	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
lbL0016BA	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.w	0
	dc.b	0
lbB0016CD	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
lbB0016DC	dc.b	0
	dc.b	0
lbL0016DE	dc.l	0
	dc.l	0
	dc.w	0
lbB0016E8	dc.b	0
	dc.b	0
lbL0016EA	dc.l	$44
	dc.w	0
lbL0016F0	dc.l	$DFF0D0
lbL0016F4	dc.l	0
lbB0016F8	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
lbL0016FC	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.w	0
	dc.b	0
lbB00170F	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	0
lbB00171E	dc.b	0
	dc.b	0
lbW001720	dc.w	0
lbL001722	dc.l	0
lbL001726	dc.l	0
lbL00172A	dc.l	0
	dc.b	0
	dc.b	0
stop
	end
