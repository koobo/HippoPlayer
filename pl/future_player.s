;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000

test	=	0

	incdir	include:
	include	exec/exec_lib.i
	include	dos/dos_lib.i
	include	exec/memory.i

 ifne test

	lea	mod,a0
	jsr	Check3

;	bra	.skop
 	move.l	4.w,a6
	lea	dosname,a1
	jsr	_LVOOldOpenLibrary(a6)
	move.l d0,dosbase

	move.l	dosbase,a6
	move.l	#modulePath,d1
	jsr	_LVOLoadSeg(A6)
	tst.l	d0 
	beq		error

	* initial song number
	moveq	#0,d1
	lea	emptySample,a1
	lea	masterVol,a2
	lea 	songCount,a3
	lea setTempoFunc,a4
	jsr		init
	bne	error

	bsr	playLoop

	moveq	#1,d0
	jsr	song
	bsr	playLoop

	jsr	end
error
	rts

playLoop
.loop	
	cmp.b	#$80,$dff006
	bne.b	.loop
.x	cmp.b	#$80,$dff006
	beq.b	.x	

	move	#$ff0,$dff180
	jsr	play
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

dosbase dc.l 0
dosname dc.b "dos.library",0 
	section d,data_c

mod   		incbin	"sys:music/paulvandervalk/imploder.fp"
modulePath	dc.b	"sys:music/paulvandervalk/imploder.fp",0
;mod   		incbin	"sys:music/future player/hybris title.fp"
;modulePath	dc.b	"sys:music/future player/hybris title.fp",0
;mod   		incbin	"sys:music/future player/hybris ingame.fp"
;modulePath	dc.b	"sys:music/future player/hybris ingame.fp",0
;mod   		incbin	"sys:music/future player/tune.fp"
;modulePath	dc.b	"sys:music/future player/tune.fp",0
;mod   		incbin	"sys:music/future player/defjam intro.fp"
;modulePath	dc.b	"sys:music/future player/defjam intro.fp",0
;mod   		incbin	"sys:music/future player/drums.fp"
;modulePath	dc.b	"sys:music/future player/drums.fp",0

	Section	Empty,BSS_C

emptySample
;lbL00379A	
	ds.b	4

	section c,code_p

 endc

impStart

	jmp init(pc)
	jmp play(pc)
	jmp end(pc)
	jmp song(pc)

masterVolumeAddress 	dc.l 0
masterVolume		dc 	$40
songNumber			dc 	0
songCountAddress	dc.l  0	
setTempoFuncAddress dc.l 0

* in
*   d0 = LoadSeg data
*   d1 = initial songnumber
*   a1 = empty sample address
*   a2 = main volume address
*   a3 = song count address
*   a4 = set tempo function address

init
	move.l	a1,emptySampleAddress
	move.l	a2,masterVolumeAddress
	move.l	a3,songCountAddress
	move.l	a4,setTempoFuncAddress
	move	d1,songNumber

	* d0 = seglist goes in
	bsr.w	InitPlayer
	bne.b	.er

	bsr.w	SubSongRange
	* d1 = subsongs starting from 0
	move.l	songCountAddress(pc),a0
	move	d1,(a0)

	bsr.w	InitSound

	bsr.w	GetSongName
	* a0 = SongName
	moveq	#0,d0	* ok
.er
	rts

play
	move.l	masterVolumeAddress(pc),a0 
	move	(a0),masterVolume
	bra.w		Interrupt
	
end 
	bsr.w	EndSound
	bsr.w	EndPlayer
	rts

song
	move	d0,songNumber
	bsr.w	EndSound
	bsr.w	InitSound
	rts

; timer value in d0
setTempo
	movem.l	d0/a0,-(sp)
	lsl.w	#8,D0
	move.l	setTempoFuncAddress(pc),a0
	jsr		(a0)
	movem.l	(sp)+,d0/a0
	rts


	******************************************************
	****    Future Player replayer for EaglePlayer,   ****
	****         all adaptions by Wanted Team	  ****
	****      DeliTracker (?) compatible version	  ****
	******************************************************

; 	incdir	"dh2:include/"
; 	include 'misc/eagleplayer2.01.i'
; 	include	'dos/dos_lib.i'

; 	SECTION	Player,CODE

; 	PLAYERHEADER Tags

; 	dc.b	'$VER: Future Player replayer module V1.0 (14 Oct 2003)',0
; 	even
; Tags
; 	dc.l	DTP_PlayerVersion,1
; 	dc.l	EP_PlayerVersion,9
; 	dc.l	DTP_RequestDTVersion,DELIVERSION
; 	dc.l	DTP_PlayerName,PlayerName
; 	dc.l	DTP_Creator,Creator
; 	dc.l	DTP_DeliBase,DeliBase
; 	dc.l	DTP_Check1,Check1
; 	dc.l	EP_Check3,Check3
; 	dc.l	DTP_Interrupt,Interrupt
; 	dc.l	DTP_SubSongRange,SubSongRange
; 	dc.l	DTP_InitPlayer,InitPlayer
; 	dc.l	DTP_EndPlayer,EndPlayer
; 	dc.l	DTP_InitSound,InitSound
; 	dc.l	DTP_EndSound,EndSound
; 	dc.l	EP_Get_ModuleInfo,GetInfos
; 	dc.l	DTP_Volume,SetVolume
; 	dc.l	DTP_Balance,SetBalance
; 	dc.l	EP_Voices,SetVoices
; 	dc.l	EP_StructInit,StructInit
; 	dc.l	EP_Flags,EPB_Volume!EPB_Balance!EPB_ModuleInfo!EPB_Voices!EPB_Songend!EPB_Analyzer!EPB_NextSong!EPB_PrevSong!EPB_Restart
; 	dc.l	TAG_DONE
;PlayerName
;	dc.b	'Future Player',0
;Creator
;	dc.b	'(c) 1988-89 by Paul van der Valk,',10
;	dc.b	'adapted by Wanted Team',0
Prefix
	dc.b	'FP.',0
	even
;DeliBase
;	dc.l	0
ModulePtr
	dc.l	0
SongPtr
	dc.l	0
EagleBase
	dc.l	0
SongEnd
	dc.b	'WTWT'
SongEndTemp
	dc.b	'WTWT'
RightVolume
	dc.w	64
LeftVolume
	dc.w	64
Voice1
	dc.w	1
Voice2
	dc.w	1
Voice3
	dc.w	1
Voice4
	dc.w	1
OldVoice1
	dc.w	0
OldVoice2
	dc.w	0
OldVoice3
	dc.w	0
OldVoice4
	dc.w	0
;StructAdr
;	ds.b	UPS_SizeOF

***************************************************************************
************************* DTP_Volume, DTP_Balance *************************
***************************************************************************
; Copy Volume and Balance Data to internal buffer

SetVolume
SetBalance
;	move.w	dtg_SndLBal(A5),D0
;	mulu.w	dtg_SndVol(A5),D0
;	lsr.w	#6,D0				; durch 64
;	move.w	D0,LeftVolume
;
;	move.w	dtg_SndRBal(A5),D0
;	mulu.w	dtg_SndVol(A5),D0
;	lsr.w	#6,D0				; durch 64
;	move.w	D0,RightVolume			; Right Volume
;
;	lea	OldVoice1(PC),A0
;	moveq	#3,D1
;	lea	$DFF0A0,A1
;SetNew
;	move.w	(A0)+,D0
;	bsr.b	ChangeVolume
;	lea	16(A1),A1
;	dbf	D1,SetNew
	rts

ChangeVolume
	and		#$7f,d0
	mulu	masterVolume(pc),d0 
	lsr		#6,d0
	move	d0,8(a1)	* AUDxVOL
;	move.l	A3,-(SP)
;	lea	StructAdr(PC),A3
;	and.w	#$7F,D0
;	cmpa.l	#$DFF0A0,A1			;Left Volume
;	bne.b	NoVoice1
;SetVoice1
;	move.w	D0,OldVoice1
;	tst.w	Voice1
;	bne.b	Voice1On
;	moveq	#0,D0
;Voice1On
;	mulu.w	LeftVolume(PC),D0
;	lsr.w	#6,D0
;	move.w	D0,8(A1)
;	move.w	D0,UPS_Voice1Vol(A3)
;	bra.b	SetIt
;NoVoice1
;	cmpa.l	#$DFF0B0,A1			;Right Volume
;	bne.b	NoVoice2
;SetVoice2
;	move.w	D0,OldVoice2
;	tst.w	Voice2
;	bne.b	Voice2On
;	moveq	#0,D0
;Voice2On
;	mulu.w	RightVolume(PC),D0
;	lsr.w	#6,D0
;	move.w	D0,8(A1)
;	move.w	D0,UPS_Voice2Vol(A3)
;	bra.b	SetIt
;NoVoice2
;	cmpa.l	#$DFF0C0,A1			;Right Volume
;	bne.b	NoVoice3
;SetVoice3
;	move.w	D0,OldVoice3
;	tst.w	Voice3
;	bne.b	Voice3On
;	moveq	#0,D0
;Voice3On
;	mulu.w	RightVolume(PC),D0
;	lsr.w	#6,D0
;	move.w	D0,8(A1)
;	move.w	D0,UPS_Voice3Vol(A3)
;	bra.b	SetIt
;NoVoice3
;	cmpa.l	#$DFF0D0,A1			;Left Volume
;	bne.b	SetIt
;SetVoice4
;	move.w	D0,OldVoice4
;	tst.w	Voice4
;	bne.b	Voice4On
;	moveq	#0,D0
;Voice4On
;	mulu.w	LeftVolume(PC),D0
;	lsr.w	#6,D0
;	move.w	D0,8(A1)
;	move.w	D0,UPS_Voice4Vol(A3)
;SetIt
;	move.l	(SP)+,A3
	rts

SetTwo
	move.l	d2,(a1)		* AUDxLCH AUDxLCL
	move	d0,4(a1)	* AUDxLEN

;	move.l	A0,-(SP)
;	lea	StructAdr+UPS_Voice1Adr(PC),A0
;	cmp.l	#$DFF0A0,A1
;	beq.b	.SetVoice
;	lea	StructAdr+UPS_Voice2Adr(PC),A0
;	cmp.l	#$DFF0B0,A1
;	beq.b	.SetVoice
;	lea	StructAdr+UPS_Voice3Adr(PC),A0
;	cmp.l	#$DFF0C0,A1
;	beq.b	.SetVoice
;	lea	StructAdr+UPS_Voice4Adr(PC),A0
;.SetVoice
;	move.l	D2,(A0)
;	move.w	D0,UPS_Voice1Len(A0)
;	move.l	(SP)+,A0
;	rts

SetPer
	move.w	D1,6(A1)			* AUDxPER
;	move.l	A0,-(SP)
;	lea	StructAdr+UPS_Voice1Per(PC),A0
;	cmp.l	#$DFF0A0,A1
;	beq.b	.SetVoice
;	lea	StructAdr+UPS_Voice2Per(PC),A0
;	cmp.l	#$DFF0B0,A1
;	beq.b	.SetVoice
;	lea	StructAdr+UPS_Voice3Per(PC),A0
;	cmp.l	#$DFF0C0,A1
;	beq.b	.SetVoice
;	lea	StructAdr+UPS_Voice4Per(PC),A0
;.SetVoice
;	move.w	D1,(A0)
;	move.l	(SP)+,A0
	rts

***************************************************************************
**************************** EP_Voices ************************************
***************************************************************************

SetVoices
;	lea	Voice1(PC),A0
;	lea	StructAdr(PC),A1
;	moveq	#1,D1
;	move.w	D1,(A0)+			Voice1=0 setzen
;	btst	#0,D0
;	bne.b	No_Voice1
;	clr.w	-2(A0)
;	clr.w	$DFF0A8
;	clr.w	UPS_Voice1Vol(A1)
;No_Voice1
;	move.w	D1,(A0)+			Voice2=0 setzen
;	btst	#1,D0
;	bne.b	No_Voice2
;	clr.w	-2(A0)
;	clr.w	$DFF0B8
;	clr.w	UPS_Voice2Vol(A1)
;No_Voice2
;	move.w	D1,(A0)+			Voice3=0 setzen
;	btst	#2,D0
;	bne.b	No_Voice3
;	clr.w	-2(A0)
;	clr.w	$DFF0C8
;	clr.w	UPS_Voice3Vol(A1)
;No_Voice3
;	move.w	D1,(A0)+			Voice4=0 setzen
;	btst	#3,D0
;	bne.b	No_Voice4
;	clr.w	-2(A0)
;	clr.w	$DFF0D8
;	clr.w	UPS_Voice4Vol(A1)
;No_Voice4
;	move.w	D0,UPS_DMACon(A1)	;Stimme an = Bit gesetzt
;					;Bit 0 = Kanal 1 usw.
	moveq	#0,D0
	rts

***************************************************************************
******************************* EP_StructInit *****************************
***************************************************************************

StructInit
;	lea	StructAdr(PC),A0
	rts

***************************************************************************
******************************** DTP_Check1 *******************************
***************************************************************************

;Check1
;	move.l	DeliBase(PC),D0
;	beq.b	fail

***************************************************************************
******************************* EP_Check3 *********************************
***************************************************************************

Check3
	;movea.l	dtg_ChkData(A5),A0
	;lea	mod,a0

	cmp.l	#$000003F3,(A0)
	bne.b	fail
	tst.b	20(A0)				; loading into chip check
	beq.b	fail
	lea	32(A0),A0
	cmp.l	#$70FF4E75,(A0)+
	bne.b	fail
	cmp.l	#'F.PL',(A0)+
	bne.b	fail
	cmp.l	#'AYER',(A0)+
	bne.b	fail
	tst.l	20(A0)				; Song pointer check
	beq.b	fail

	moveq	#0,D0
	rts
fail
	moveq	#-1,D0
	rts

***************************************************************************
***************************** EP_Get_ModuleInfo ***************************
***************************************************************************

GetInfos
	lea	InfoBuffer(PC),A0
	rts

SubSongs	=	4
LoadSize	=	12
CalcSize	=	20
SpecialInfo	=	28
AuthorName	=	36
SongName	=	44
Voices		=	52

MI_SubSongs		= 1		
MI_LoadSize		= 2	
MI_Calcsize		= 3		
MI_SpecialInfo	= 4
MI_AuthorName	= 5	
MI_SongName		= 6		
MI_Voices		= 7	
MI_MaxVoices	= 8
MI_Prefix       = 9

InfoBuffer
	dc.l	MI_SubSongs,0		;4
	dc.l	MI_LoadSize,0		;12
	dc.l	MI_Calcsize,0		;20
	dc.l	MI_SpecialInfo,0	;28
	dc.l	MI_AuthorName,0		;36
	dc.l	MI_SongName,0		;44
	dc.l	MI_Voices,0		;52
	dc.l	MI_MaxVoices,4
	dc.l	MI_Prefix,Prefix
	dc.l	0

***************************************************************************
***************************** DTP_Intterrupt ******************************
***************************************************************************

Interrupt	
	movem.l	D1-D7/A0-A6,-(SP)

;	lea	StructAdr(PC),A0
;	st	UPS_Enabled(A0)
;	clr.w	UPS_Voice1Per(A0)
;	clr.w	UPS_Voice2Per(A0)
;	clr.w	UPS_Voice3Per(A0)
;	clr.w	UPS_Voice4Per(A0)
;	move.w	#UPSB_Adr!UPSB_Len!UPSB_Per!UPSB_Vol,UPS_Flags(A0)
;
	moveq	#0,D4
	bsr.w	Play

;	lea	StructAdr(PC),A0
;	clr.w	UPS_Enabled(A0)
;
	movem.l	(SP)+,D1-D7/A0-A6
	moveq	#0,D0
	rts

SongEndTest
;	movem.l	A1/A5,-(A7)
;	lea	SongEnd(PC),A1
;	cmp.l	#$DFF0A0,$78(A0)
;	bne.b	test1
;	clr.b	(A1)
;	bra.b	test
;test1
;	cmp.l	#$DFF0B0,$78(A0)
;	bne.b	test2
;	clr.b	1(A1)
;	bra.b	test
;test2
;	cmp.l	#$DFF0C0,$78(A0)
;	bne.b	test3
;	clr.b	2(A1)
;	bra.b	test
;test3
;	cmp.l	#$DFF0D0,$78(A0)
;	bne.b	test
;	clr.b	3(A1)
;test
;	tst.l	(A1)
;	bne.b	SkipEnd
;	move.l	SongEndTemp(PC),(A1)
;	move.l	EagleBase(PC),A5
;	move.l	dtg_SongEnd(A5),A1
;	jsr	(A1)
;SkipEnd
;	movem.l	(A7)+,A1/A5
	rts

DMAWait
	movem.l	D0/D1,-(SP)
	moveq	#8,D0
.dma1	move.b	$DFF006,D1
.dma2	cmp.b	$DFF006,D1
	beq.b	.dma2
	dbeq	D0,.dma1
	movem.l	(SP)+,D0/D1
	rts

***************************************************************************
***************************** DTP_SubSongRange ****************************
***************************************************************************

SubSongRange	
	moveq	#0,D0
	move.l	InfoBuffer+SubSongs(PC),D1
	subq.l	#1,D1
	rts

GetSongName
	move.l	InfoBuffer+SongName(PC),a0
;	move.l	(a0),a0
	rts

***************************************************************************
***************************** DTP_InitPlayer ******************************
***************************************************************************

InitPlayer
	;move.l	dtg_DOSBase(A5),A6
	;move.l	dtg_PathArrayPtr(A5),D1
;	move.l	dosbase,a6
;	move.l	#modulePath,d1
;	jsr	_LVOLoadSeg(A6)
	lsl.l	#2,D0
	beq.b	InitFail
	addq.l	#4,D0

	move.l	D0,A0				; module address
	lea	ModulePtr(PC),A1
	move.l	D0,(A1)+
	addq.l	#8,A0
	addq.l	#4,A0

	lea	InfoBuffer(PC),A2
	move.l	(A0)+,SongName(A2)
	move.l	(A0)+,AuthorName(A2)
	move.l	(A0)+,SpecialInfo(A2)
	move.l	(A0)+,LoadSize(A2)
	move.l	(A0)+,CalcSize(A2)
	move.l	A0,(A1)+			; SongPtr
	move.l	A5,(A1)				; EagleBase
	moveq	#0,D0
CheckSongs
	tst.l	(A0)+
	beq.b	NoMore
	addq.l	#1,D0
	addq.l	#4,A0
	bra.b	CheckSongs
NoMore
	move.l	D0,SubSongs(A2)
	moveq	#0,d0
	rts
	;movea.l	dtg_AudioAlloc(A5),A0
	;jmp	(A0)

InitFail
	;moveq	#EPR_NotEnoughMem,D0
	moveq	#-1,d0
	rts

***************************************************************************
***************************** DTP_EndPlayer *******************************
***************************************************************************

EndPlayer
	;move.l	dtg_DOSBase(A5),A6
	;move.l	dosbase,a6
	;move.l	ModulePtr(PC),D1
	;subq.l	#4,D1
	;lsr.l	#2,D1
	;jsr	_LVOUnLoadSeg(A6)
	;rts
	;movea.l	dtg_AudioFree(A5),A0
	;jmp	(A0)

***************************************************************************
***************************** DTP_InitSound *******************************
***************************************************************************

InitSound
;	lea	StructAdr(PC),A0
;	lea	UPS_SizeOF(A0),A1
;ClearUPS
;	clr.w	(A0)+
;	cmp.l	A0,A1
;	bne.b	ClearUPS
;	lea	OldVoice1(PC),A0
;	clr.l	(A0)+
;	clr.l	(A0)

	lea	lbL003858,A0
	lea	760(A0),A1
Clear
	clr.l	(A0)+
	cmp.l	A0,A1
	bne.b	Clear

	bsr.b	Init_1
	;move.w	dtg_SndNum(A5),D1
	move	songNumber(pc),d1
	lsl.w	#3,D1
	move.l	SongPtr(PC),A0
	move.l	4(A0,D1.W),D0
	move.w	D0,lbL003680+2
	move.l	(A0,D1.W),A0
	swap	D0
	move.l	A0,A1
	addq.l	#8,A1
	moveq	#4,D1
	lea	SongEnd(PC),A2
	move.l	#'WTWT',(A2)
	moveq	#3,D2
NextV
	tst.l	(A1)+
	bne.b	NextVoice
	subq.l	#1,D1
	clr.b	(A2)
NextVoice
	addq.l	#1,A2
	dbf	D2,NextV
	move.l	SongEnd(PC),(A2)
	lea	InfoBuffer(PC),A1
	move.l	D1,Voices(A1)
	bra.w	Init_2

***************************************************************************
***************************** DTP_EndSound ********************************
***************************************************************************

EndSound
	lea	$DFF000,A0
	move.w	#15,$96(A0)
	moveq	#0,D0
	move.w	D0,$A8(A0)
	move.w	D0,$B8(A0)
	move.w	D0,$C8(A0)
	move.w	D0,$D8(A0)
	rts

***************************************************************************
************************* Future Player replayer **************************
***************************************************************************

; Player from Hybris (title music) (c) 1989 by Discovery Software

Init_1
;lbC002A12	TST.B	lbB00366B
;	BNE.L	lbC0032EE
;	BSR.L	lbC0034D4
	CLR.B	lbB003664
	CLR.B	lbB003666
;	CLR.L	lbL00367C
;	CLR.L	lbL003678
;	CLR.B	lbB003668
	MOVEQ	#0,D0
	BSR.W	lbC0034E8
	MOVE.B	#1,lbB00366E
;	MOVE.L	$78,lbL003684
;	MOVE.L	#lbC002AC4,$78
;	MOVE.B	#0,$BFDE00
;	MOVE.B	#0,$BFD400
;	MOVE.B	#$30,$BFD500
;	MOVE.B	#$81,$BFDD00
;	MOVE.B	#$11,$BFDE00
;	MOVE.B	#$FF,lbB00366B
;	MOVEQ	#1,D0
	RTS

;lbC002A90	BSR.L	lbC0033FC
;	TST.B	lbB00366B
;	BEQ.L	lbC0032EE
;	CLR.B	lbB003664
;	BSR.L	lbC0034D4
;	MOVE.B	#1,$BFDD00
;	MOVE.L	lbL003684,$78
;	CLR.B	lbB00366B
;	RTS

;	MOVEQ	#0,D0
;	RTS

;lbC002AC4	MOVEM.L	D0/D1,-(SP)
;	BSR.S	lbC002ADE
;	MOVE.B	$BFDD00,D0
;	MOVE.W	#$2000,$DFF09C
;	MOVEM.L	(SP)+,D0/D1
;	RTE

Play
;lbC002ADE	TST.B	lbB00366C
;	BNE.L	lbC002BC2
;	MOVEM.L	D0-D7/A0-A6,-(SP)
;	TST.L	lbL003678
;	BNE.L	lbC002BCE
	MOVE.B	lbB003664(pc),D0
	BEQ.S	lbC002B4E
	BMI.S	lbC002B16
	MOVE.B	lbB003666(pc),D0
	BEQ.S	lbC002B42
	ADD.B	lbB003665(pc),D0
	BCS.S	lbC002B42
	BSR.W	lbC0034E8
	BRA.S	lbC002B4E

lbC002B16	MOVE.B	lbB003666(pc),D1
	BEQ.S	lbC002B2E
	MOVE.B	lbB003665(pc),D0
	SUB.B	D1,D0
	BCS.S	lbC002B2E
	BSR.W	lbC0034E8
	BRA.S	lbC002B4E

lbC002B2E	CLR.B	lbB003664
	MOVEQ	#0,D0
	BSR.W	lbC0034E8
	BSR.W	lbC0033FC
	BRA.B	lbC002BB6

lbC002B42	MOVEQ	#-1,D0
	CLR.B	lbB003664
	BSR.W	lbC0034E8
lbC002B4E	SUBQ.B	#1,lbB00366E
	BNE.S	lbC002B8E
	MOVE.B	lbB00366D(pc),lbB00366E
;	ADDQ.L	#1,lbL00369C
	LEA	lbL003858,A0
	BSR.B	lbC002C4A
	LEA	lbL003916,A0
	BSR.B	lbC002C4A
	LEA	lbL0039D4,A0
	BSR.B	lbC002C4A
	LEA	lbL003A92,A0
	BSR.B	lbC002C4A
lbC002B8E	LEA	lbL003858,A0
	BSR.W	lbC002E00
	LEA	lbL003916,A0
	BSR.W	lbC002E00
	LEA	lbL0039D4,A0
	BSR.W	lbC002E00
	LEA	lbL003A92,A0
	BSR.W	lbC002E00
lbC002BB6
;	MOVEM.L	(SP)+,D0-D7/A0-A6
;lbC002BBA	MOVEQ	#1,D0
	RTS

;	MOVEQ	#0,D0
;	RTS

;lbC002BC2	TST.L	lbL003678
;	BEQ.S	lbC002BBA
;	MOVEM.L	D0-D7/A0-A6,-(SP)
;lbC002BCE	MOVE.L	lbL00367C,D0
;	BEQ.S	lbC002C00
;	CMP.L	lbL003678,D0
;	BEQ.S	lbC002C2C
;	CMPI.B	#$FF,lbB003664
;	BEQ.L	lbC002B16
;	MOVE.B	lbB003672,lbB003666
;	MOVE.B	#$FF,lbB003664
;	BRA.L	lbC002B16

;lbC002C00	CLR.B	lbB003668
;	MOVEQ	#0,D0
;	BSR.L	lbC0034E8
;	MOVE.B	lbB003672,lbB003666
;	MOVEA.L	lbL003678,A0
;	CLR.L	lbL003678
;	BSR.L	lbC0032F0
;	BSR.L	lbC0034BE
;	BRA.S	lbC002BB6

;lbC002C2C	CLR.L	lbL003678
;	CMPI.B	#$FF,lbB003664
;	BNE.L	lbC002B4E
;	MOVE.B	#1,lbB003664
;	BRA.L	lbC002B4E

lbC002C4A	TST.B	1(A0)
	BNE.W	lbC0032EE
	CLR.B	$A5(A0)
	CLR.B	lbB00366F
	SUBQ.B	#1,$9F(A0)
	BNE.W	lbC0032EE
	MOVEA.L	$A6(A0),A1
lbC002C68	MOVE.B	(A1)+,D0
	BMI.S	lbC002C9A
	BEQ.S	lbC002C72
	MOVE.B	D0,$9E(A0)
lbC002C72	MOVE.B	(A1)+,D1
	BMI.S	lbC002C88
	MOVE.L	A1,$A6(A0)
	MOVE.B	D1,$9F(A0)
	MOVE.B	D0,$A4(A0)
	MOVE.B	D0,$A5(A0)
	RTS

lbC002C88	MOVE.L	A1,$A6(A0)
	ANDI.B	#$7F,D1
	MOVE.B	D1,$9F(A0)
	MOVE.B	D0,$A4(A0)
	RTS

lbC002C9A	SUBQ.B	#1,lbB00366F
	BEQ.S	lbC002CB8
	ASL.B	#2,D0
	ANDI.W	#$FF,D0
	LEA	lbL003808(pc),A2
	MOVEA.L	0(A2,D0.W),A2
	MOVE.B	(A1)+,D0
	JSR	(A2)
	BRA.S	lbC002C68

lbC002CB8	MOVE.B	#$81,lbB00366F
	RTS

lbC002CC2	TST.B	lbB00366A
	BEQ.S	lbC002CD4
	RTS

lbC002CCC	TST.W	4(A0)
	BNE.W	lbC002DE2
lbC002CD4	TST.L	(SP)+
	MOVE.B	#$80,1(A0)
	TST.B	0(A0)
	BNE.S	lbC002CF0
	MOVE.B	#$80,0(A0)
	MOVE.W	$7C(A0),$DFF096

	bsr.w	SongEndTest

lbC002CF0	RTS

lbC002CF2	MOVEA.L	(A1)+,A2
	MOVE.L	A2,$68(A0)
	MOVEA.L	12(A2),A3
	MOVE.B	14(A3),D0
	EXT.W	D0
	LEA	lbL003858,A4
	MOVE.W	D0,$86(A4)
	MOVE.B	15(A3),D0
	EXT.W	D0
	LEA	lbL003916,A4
	MOVE.W	D0,$86(A4)
	MOVE.B	$10(A3),D0
	EXT.W	D0
	LEA	lbL0039D4,A4
	MOVE.W	D0,$86(A4)
	MOVE.B	$11(A3),D0
	EXT.W	D0
	LEA	lbL003A92,A4
	MOVE.W	D0,$86(A4)
	CLR.W	$88(A0)
	CLR.W	$8A(A0)
	CLR.W	$8C(A0)
	CLR.W	$8E(A0)
	CLR.B	$90(A0)
	CLR.B	$91(A0)
	CLR.B	$92(A0)
	CLR.B	$93(A0)
	CLR.B	$B0(A0)
	RTS

lbC002D62	MOVE.L	(A1)+,$70(A0)
	RTS

lbC002D68	MOVE.L	#lbL00378E,$70(A0)
	CLR.W	$74(A0)
	RTS

lbC002D76	MOVE.W	(A1)+,$76(A0)
	RTS

lbC002D7C	RTS

lbC002D7E	MOVE.W	4(A0),D1
	MOVE.L	A1,6(A0,D1.W)
	ADDQ.L	#4,6(A0,D1.W)
	CMPI.W	#$1C,D1
	BEQ.S	lbC002D92
	ADDQ.W	#4,D1
lbC002D92	MOVE.W	D1,4(A0)
	MOVE.B	#1,$26(A0,D1.W)
lbC002D9C	MOVEA.L	(A1),A2
	MOVEA.L	8(A2),A1
	RTS

lbC002DA4	MOVE.W	4(A0),D1
	MOVE.L	A1,$46(A0,D1.W)
	MOVE.B	D0,$26(A0,D1.W)
	CLR.B	$AF(A0)
	RTS

lbC002DB6	MOVE.W	4(A0),D1
	SUBQ.B	#1,$26(A0,D1.W)
	BEQ.S	lbC002DC4
	MOVEA.L	$46(A0,D1.W),A1
lbC002DC4	RTS

lbC002DC6	TST.B	$AF(A0)
	BNE.S	lbC002DD4
	MOVE.W	4(A0),D1
	MOVEA.L	$46(A0,D1.W),A1
lbC002DD4	RTS

lbC002DD6	MOVE.B	D0,$94(A0)
	RTS

lbC002DDC	MOVE.B	D0,$95(A0)
	RTS

lbC002DE2	TST.W	4(A0)
	BEQ.S	lbC002DEC
	SUBQ.W	#4,4(A0)
lbC002DEC	MOVE.W	4(A0),D1
	MOVEA.L	6(A0,D1.W),A1
	RTS

lbC002DF6
;	CLR.L	lbL00369C
	RTS

;	RTS

lbC002E00	MOVEA.L	$78(A0),A1
	MOVEA.L	$68(A0),A2
	MOVE.B	0(A0),D0
	BMI.W	lbC0032EE
	BEQ.S	lbC002E4E
	MOVEA.L	$6C(A0),A2
	TST.W	$9C(A0)
	BEQ.S	lbC002E4E
	SUBQ.W	#1,$9C(A0)
	BNE.S	lbC002E4E
	MOVE.W	$7C(A0),$DFF096
	TST.B	1(A0)
	BEQ.S	lbC002E38
	MOVE.B	#$80,0(A0)
	RTS

lbC002E38	TST.B	$A5(A0)
	BNE.S	lbC002E46
	MOVE.B	#1,$9C(A0)
	RTS

lbC002E46	CLR.B	0(A0)
	MOVEA.L	$68(A0),A2
lbC002E4E	TST.B	$A5(A0)
	BEQ.B	lbC002ECC
	MOVE.W	$7C(A0),$DFF096
	CLR.W	$74(A0)
	CLR.B	$B0(A0)
	MOVEA.L	12(A2),A4
	CLR.B	$84(A0)
	TST.B	$19(A4)
	BNE.S	lbC002E7E
	MOVE.B	$83(A0),D0
	CMP.B	$12(A4),D0
	BHI.S	lbC002E84
lbC002E7E	MOVE.B	$12(A4),$83(A0)
lbC002E84	CMPI.B	#1,$20(A4)
	BEQ.S	lbC002E96
	CLR.W	$88(A0)
	MOVE.B	$1F(A4),$90(A0)
lbC002E96	CMPI.B	#1,$28(A4)
	BEQ.S	lbC002EA8
	CLR.W	$8A(A0)
	MOVE.B	$27(A4),$91(A0)
lbC002EA8	CMPI.B	#1,$30(A4)
	BEQ.S	lbC002EBA
	CLR.W	$8C(A0)
	MOVE.B	$2F(A4),$92(A0)
lbC002EBA	CMPI.B	#1,$38(A4)
	BEQ.S	lbC002ECC
	CLR.W	$8E(A0)
	MOVE.B	$37(A4),$93(A0)
lbC002ECC	MOVEA.L	8(A2),A3
	TST.B	8(A3)
	BEQ.S	lbC002F3C
	TST.B	$B0(A0)
	BNE.S	lbC002F04
	MOVEA.L	10(A3),A3
	LEA	8(A3),A3
	TST.L	(A3)
	BEQ.S	lbC002F34
	MOVE.L	A3,$BA(A0)
	MOVE.L	(A3),$B2(A0)
	MOVE.B	4(A3),$B1(A0)
	LEA	6(A3),A3
	MOVE.L	A3,$B6(A0)
	MOVE.B	#$FF,$B0(A0)
lbC002F04	MOVEA.L	$B2(A0),A3
	SUBQ.B	#1,$B1(A0)
	BNE.S	lbC002F40
	MOVEA.L	$B6(A0),A4
	TST.L	(A4)
	BNE.S	lbC002F1A
	MOVEA.L	$BA(A0),A4
lbC002F1A	MOVE.L	(A4)+,$B2(A0)
	MOVE.B	(A4)+,$B1(A0)
	TST.B	(A4)+
	BEQ.S	lbC002F2E
	MOVE.L	A4,$BA(A0)
	SUBQ.L	#6,$BA(A0)
lbC002F2E	MOVE.L	A4,$B6(A0)
	BRA.S	lbC002F40

lbC002F34	LEA	lbL0037F6(pc),A3
	BRA.S	lbC002F40

lbC002F3C	MOVEA.L	10(A3),A3
lbC002F40	CLR.W	D0
	MOVE.L	A3,D7
	MOVE.B	$11(A3),D0
	ADD.B	$9E(A0),D0
	ADD.B	$94(A0),D0
	ADD.B	$95(A0),D0
	TST.W	$76(A0)
	BNE.S	lbC002F8A
	MOVEA.L	$70(A0),A4
	MOVE.W	$74(A0),D1
	MOVE.B	8(A4,D1.W),D2
	CMPI.B	#$80,D2
	BNE.S	lbC002F74
	MOVE.B	8(A4),D2
	MOVE.W	#$FFFF,D1
lbC002F74	ADDQ.W	#1,D1
	MOVE.W	D1,$74(A0)
	ADD.B	D2,D0
	ASL.B	#1,D0
	LEA	lbW0036C4(pc),A4
	MOVE.W	0(A4,D0.W),D1
	BRA.S	lbC002FB8

lbC002F8A	ASL.B	#1,D0
	LEA	lbW0036C4(pc),A4
	MOVE.W	0(A4,D0.W),D1
	MOVE.W	$A0(A0),D2
	CMP.W	D2,D1
	BCS.S	lbC002FAA
	ADD.W	$76(A0),D2
	BCS.S	lbC002FB4
	CMP.W	D1,D2
	BCS.S	lbC002FB6
	BRA.S	lbC002FB4

lbC002FAA	SUB.W	$76(A0),D2
	BCS.S	lbC002FB4
	CMP.W	D1,D2
	BHI.S	lbC002FB6
lbC002FB4	MOVE.W	D1,D2
lbC002FB6	MOVE.W	D2,D1
lbC002FB8	MOVE.W	D1,$A0(A0)
	MOVEA.L	12(A2),A4
	TST.L	$1A(A4)
	BEQ.S	lbC003010
	MOVEA.L	$1A(A4),A5
	MOVEA.L	8(A5),A6
	TST.B	$90(A0)
	BEQ.S	lbC002FDA
	SUBQ.B	#1,$90(A0)
	BRA.S	lbC003010

lbC002FDA	MOVE.W	$88(A0),D3
	BMI.S	lbC003010
	MOVE.B	0(A6,D3.W),D0
	EXT.W	D0
	TST.B	$21(A4)
	BEQ.S	lbC002FEE
	NEG.W	D0
lbC002FEE	MOVE.B	$1E(A4),D2
	ASL.W	D2,D0
	ADD.W	D0,D1
	ADDQ.W	#1,D3
	CMP.W	12(A5),D3
	BCS.S	lbC00300C
	CLR.W	D3
	BTST	#7,$20(A4)
	BEQ.S	lbC00300C
	MOVE.W	#$FFFF,D3
lbC00300C	MOVE.W	D3,$88(A0)
lbC003010	TST.L	$22(A4)
	BEQ.S	lbC003060
	MOVEA.L	$22(A4),A5
	MOVEA.L	8(A5),A6
	TST.B	$91(A0)
	BEQ.S	lbC00302A
	SUBQ.B	#1,$91(A0)
	BRA.S	lbC003060

lbC00302A	MOVE.W	$8A(A0),D3
	BMI.S	lbC003060
	MOVE.B	0(A6,D3.W),D0
	EXT.W	D0
	TST.B	$29(A4)
	BEQ.S	lbC00303E
	NEG.W	D0
lbC00303E	MOVE.B	$26(A4),D2
	ASL.W	D2,D0
	ADD.W	D0,D1
	ADDQ.W	#1,D3
	CMP.W	12(A5),D3
	BCS.S	lbC00305C
	CLR.W	D3
	BTST	#7,$28(A4)
	BEQ.S	lbC00305C
	MOVE.W	#$FFFF,D3
lbC00305C	MOVE.W	D3,$8A(A0)
lbC003060	ADD.W	$86(A0),D1
	MOVE.W	D1,6(A1)			; period

	bsr.w	SetPer

	MOVE.W	D1,$A2(A0)
	MOVEA.L	8(A2),A3
	TST.B	8(A3)
	BEQ.S	lbC00307A
	MOVEA.L	D7,A3
	BRA.S	lbC00308E

lbC00307A	MOVEA.L	10(A3),A3
	TST.B	$A5(A0)
	BNE.S	lbC00308E
	BTST	#0,$10(A3)
	BEQ.W	lbC00314A
lbC00308E	MOVE.L	8(A3),D2
	MOVE.W	12(A3),D0
	LSR.W	#1,D0
	BTST	#0,$10(A3)
	BEQ.W	lbC003144
	LSR.W	#1,D0
	MOVEA.L	12(A2),A4
	TST.L	$2A(A4)
	BEQ.S	lbC0030F6
	MOVEA.L	$2A(A4),A5
	MOVEA.L	8(A5),A6
	TST.B	$92(A0)
	BEQ.S	lbC0030C2
	SUBQ.B	#1,$92(A0)
	BRA.S	lbC0030F6

lbC0030C2	MOVE.W	$8C(A0),D3
	BMI.S	lbC0030F6
	MOVE.B	0(A6,D3.W),D6
	MOVE.B	$2E(A4),D4
	ADDQ.B	#1,D4
	ANDI.L	#$FF,D6
	ASL.W	D4,D6
	ADD.L	D6,D2
	ADDQ.W	#1,D3
	CMP.W	12(A5),D3
	BCS.S	lbC0030F2
	CLR.W	D3
	BTST	#7,$30(A4)
	BEQ.S	lbC0030F2
	MOVE.W	#$FFFF,D3
lbC0030F2	MOVE.W	D3,$8C(A0)
lbC0030F6	TST.L	$32(A4)
	BEQ.S	lbC003144
	MOVEA.L	$32(A4),A5
	MOVEA.L	8(A5),A6
	TST.B	$93(A0)
	BEQ.S	lbC003110
	SUBQ.B	#1,$93(A0)
	BRA.S	lbC0030F6

lbC003110	MOVE.W	$8E(A0),D3
	BMI.S	lbC003144
	MOVE.B	0(A6,D3.W),D6
	MOVE.B	$36(A4),D4
	ADDQ.B	#1,D4
	ANDI.L	#$FF,D6
	ASL.W	D4,D6
	ADD.L	D6,D2
	ADDQ.W	#1,D3
	CMP.W	12(A5),D3
	BCS.S	lbC003140
	CLR.W	D3
	BTST	#7,$38(A4)
	BEQ.S	lbC003140
	MOVE.W	#$FFFF,D3
lbC003140	MOVE.W	D3,$8E(A0)
lbC003144	MOVE.W	D0,4(A1)			; length
	MOVE.L	D2,(A1)					; address

	bsr.w	SetTwo

lbC00314A	MOVEA.L	12(A2),A4
	MOVE.W	$82(A0),D0
	CLR.W	D1
	MOVE.B	8(A4),D1
	MULU.W	D1,D0
	MOVE.W	$80(A0),D1
	MULU.W	D1,D0
	SWAP	D0
	LSR.B	#2,D0
;	MOVE.B	D0,8(A1)				; volume

	bsr.w	ChangeVolume

	TST.B	$A4(A0)
	BEQ.S	lbC003186
	MOVE.B	$84(A0),D1
	BEQ.S	lbC00319A
	CMPI.B	#2,D1
	BEQ.S	lbC0031E6
	BCS.S	lbC0031C4
	MOVE.B	$17(A4),$83(A0)
	BRA.W	lbC00322A

lbC003186	MOVE.B	$18(A4),D0
	SUB.B	D0,$83(A0)
	BCC.W	lbC00322A
	CLR.B	$83(A0)
	BRA.W	lbC00322A

lbC00319A	MOVE.B	$12(A4),D0
	CMP.B	$13(A4),D0
	BEQ.S	lbC0031C4
	ADD.B	D0,$83(A0)
	BCS.S	lbC0031B6
	MOVE.B	$83(A0),D0
	CMP.B	$13(A4),D0
	BCS.B	lbC00322A
lbC0031B6	MOVE.B	$13(A4),$83(A0)
	MOVE.B	#1,$84(A0)
	BRA.S	lbC00322A

lbC0031C4	MOVE.B	$14(A4),D0
	SUB.B	D0,$83(A0)
	BCS.S	lbC0031D8
	MOVE.B	$83(A0),D0
	CMP.B	$15(A4),D0
	BHI.S	lbC00322A
lbC0031D8	MOVE.B	$15(A4),$83(A0)
	MOVE.B	#2,$84(A0)
	BRA.S	lbC00322A

lbC0031E6	MOVE.B	$16(A4),D0
	BMI.S	lbC00320A
	ADD.B	D0,$83(A0)
	BCS.S	lbC0031FC
	MOVE.B	$83(A0),D0
	CMP.B	$17(A4),D0
	BCS.S	lbC00322A
lbC0031FC	MOVE.B	$17(A4),$83(A0)
	MOVE.B	#3,$84(A0)
	BRA.S	lbC00322A

lbC00320A	ANDI.B	#$7F,D0
	SUB.B	D0,$83(A0)
	BCS.S	lbC00321E
	MOVE.B	$83(A0),D0
	CMP.B	$17(A4),D0
	BHI.S	lbC00322A
lbC00321E	MOVE.B	$17(A4),$83(A0)
	MOVE.B	#3,$84(A0)
lbC00322A

	bsr.w	DMAWait

	TST.B	$A5(A0)
	BEQ.S	lbC00323E
	MOVE.W	$7E(A0),$DFF096
	CLR.B	$A5(A0)
	RTS

lbC00323E	MOVEA.L	8(A2),A3
	TST.B	8(A3)
	BNE.S	lbC003260
	MOVEA.L	10(A3),A3
	BTST	#1,$10(A3)
	BEQ.S	lbC003260
	MOVE.W	#2,4(A1)				; length
	MOVE.L	emptySampleAddress(pc),(A1)				; address
lbC003260	RTS

lbC003262
;	BSR.L	lbC0034D4
	BSR.W	lbC003424
	CLR.B	D0
	BSR.S	lbC003278
	MOVEQ	#1,D0
	BSR.S	lbC003278
	MOVEQ	#2,D0
	BSR.S	lbC003278
	MOVEQ	#3,D0
lbC003278	MOVEQ	#1,D1
	ASL.W	D0,D1
	ANDI.W	#3,D0
	ASL.W	#2,D0
	LEA	lbL003786(pc),A0
	MOVEA.L	0(A0,D0.W),A1
	MOVE.B	#$80,0(A1)
	MOVE.B	#$80,1(A1)
	MOVE.W	D1,$7C(A1)
	ORI.W	#$8000,D1
	MOVE.W	D1,$7E(A1)
	ASL.W	#2,D0
	ADDI.W	#$A0,D0
	ANDI.L	#$FF,D0
	ADDI.L	#$DFF000,D0
	MOVE.L	D0,$78(A1)
	MOVE.L	#lbL00378E,$70(A1)
	MOVE.L	#lbL00379E,$68(A1)
	CLR.W	$76(A1)
	MOVE.W	#0,$80(A1)
	MOVE.B	#1,$9F(A1)
	CLR.B	$82(A1)
	CLR.W	$86(A1)
	CLR.B	$94(A1)
	CLR.B	$95(A1)
	CLR.B	$96(A1)
lbC0032EE	RTS

lbC0032F0	MOVEA.L	A0,A1
;	MOVE.L	A0,lbL00367C
	TST.B	lbB003666
	BNE.S	lbC003312
	MOVEQ	#-1,D0
	MOVE.L	A1,-(SP)
	BSR.W	lbC0034E8
	MOVEA.L	(SP)+,A1
	CLR.B	lbB003664
	BRA.S	lbC00331A

lbC003312	MOVE.B	#1,lbB003664
lbC00331A
;	CLR.L	lbL00369C
	MOVE.L	A1,-(SP)
	BSR.W	lbC003262
	BSR.W	lbC003424
	MOVEA.L	(SP)+,A1
	MOVE.B	$18(A1),D0
	ANDI.B	#7,D0
	BNE.S	lbC00333A
	MOVE.B	#8,D0
lbC00333A	MOVE.B	D0,lbB00366D
;	MOVE.B	$19(A1),$BFD500

	move.b	$19(A1),D0
	;lsl.w	#8,D0
	;move.w	D0,dtg_Timer(A5)
	bsr.w	setTempo

	MOVE.L	8(A1),D0
	BEQ.S	lbC00336E
	MOVEA.L	D0,A0
	MOVE.L	8(A0),D0
	LEA	lbL003858,A0
	MOVE.L	D0,$A6(A0)
	MOVE.L	D0,6(A0)
	CLR.W	4(A0)
	CLR.B	0(A0)
	CLR.B	1(A0)
lbC00336E	MOVE.L	12(A1),D0
	BEQ.S	lbC003394
	MOVEA.L	D0,A0
	MOVE.L	8(A0),D0
	LEA	lbL003916,A0
	MOVE.L	D0,$A6(A0)
	MOVE.L	D0,6(A0)
	CLR.W	4(A0)
	CLR.B	0(A0)
	CLR.B	1(A0)
lbC003394	MOVE.L	$10(A1),D0
	BEQ.S	lbC0033BA
	MOVEA.L	D0,A0
	MOVE.L	8(A0),D0
	LEA	lbL0039D4,A0
	MOVE.L	D0,$A6(A0)
	MOVE.L	D0,6(A0)
	CLR.W	4(A0)
	CLR.B	0(A0)
	CLR.B	1(A0)
lbC0033BA	MOVE.L	$14(A1),D0
	BEQ.S	lbC0033E0
	MOVEA.L	D0,A0
	MOVE.L	8(A0),D0
	LEA	lbL003A92,A0
	MOVE.L	D0,$A6(A0)
	MOVE.L	D0,6(A0)
	CLR.W	4(A0)
	CLR.B	0(A0)
	CLR.B	1(A0)
lbC0033E0	RTS

;	MOVE.B	D0,lbB003667
;lbC0033E8	TST.B	lbB003666
;	BEQ.S	lbC0033FC
;	MOVE.B	#$FF,lbB003664
;	BRA.L	lbC0034B6

lbC0033FC
;	BSR.L	lbC0034D4
;	CLR.L	lbL00367C
	CLR.B	lbB003664
	BSR.B	lbC003424
;	BSR.L	lbC0034B6
;	TST.B	lbB003668
;	BEQ.S	lbC003422
;	MOVE.L	D0,lbL003680
lbC003422	RTS

lbC003424	LEA	$DFF000,A0
	MOVE.W	#15,$96(A0)
	MOVE.W	#$A0,D0
	BSR.S	lbC00344A
	MOVE.W	#$B0,D0
	BSR.S	lbC00344A
	MOVE.W	#$C0,D0
	BSR.S	lbC00344A
	MOVE.W	#$D0,D0
	BSR.S	lbC00344A
	RTS

lbC00344A	LEA	$DFF000,A0
	MOVE.L	emptySampleAddress(pc),0(A0,D0.W)			; address
	MOVE.W	#2,4(A0,D0.W)				; length
;	CLR.B	8(A0,D0.W)				; volume
;	CLR.B	6(A0,D0.W)				; period

	move.l	#$10000,6(A0,D0.W)

	RTS

lbC003468	MOVE.L	D0,lbL003698
;	MOVE.L	D0,lbL00369C
	BEQ.S	lbC0034AE
	MOVE.B	#1,lbB00366A
lbC00347E	LEA	lbL003858,A0
	BSR.W	lbC002C4A
	LEA	lbL003916,A0
	BSR.W	lbC002C4A
	LEA	lbL0039D4,A0
	BSR.W	lbC002C4A
	LEA	lbL003A92,A0
	BSR.W	lbC002C4A
	SUBQ.L	#1,lbL003698
	BNE.S	lbC00347E
lbC0034AE	CLR.B	lbB00366A
	RTS

;lbC0034B6	MOVE.L	lbL00369C,D0
;	RTS

lbC0034BE	TST.B	lbB003664
	BNE.S	lbC0034CC
	MOVEQ	#-1,D0
	BSR.B	lbC0034E8
lbC0034CC
;	CLR.B	lbB00366C
	RTS

;lbC0034D4	MOVE.B	#$FF,lbB00366C
;	RTS

;	LEA	lbL003786,A0
;	MOVE.L	A0,D0
;	RTS

lbC0034E8	MOVE.B	D0,lbB003665
	LEA	lbL003786,A0
	MOVEQ	#3,D1
lbC0034F6	MOVEA.L	(A0)+,A1
	MOVE.B	D0,$81(A1)
	DBRA	D1,lbC0034F6
	RTS

;	MOVE.B	lbB003665,D0
;	RTS

;lbC00350A	MOVE.B	D0,lbB003666
;	RTS

;	MOVE.B	lbB00366B,D0
;	BEQ.S	lbC00351E
;	MOVEQ	#-1,D0
;	RTS

;lbC00351E	MOVEQ	#0,D0
;	RTS

;	TST.B	D1
;	BNE.S	lbC003534
;	MOVE.B	D0,lbB003672
;	MOVE.L	A0,lbL003678
;	RTS

Init_2
;lbC003534	TST.B	lbB003668
;	BNE.L	lbC003578
lbC00353E	MOVEM.L	D0/A0,-(SP)
	BSR.W	lbC0033FC
	MOVEQ	#0,D0
	BSR.S	lbC0034E8
	MOVEM.L	(SP)+,D0/A0
	MOVE.B	D0,lbB003666
	BSR.W	lbC0032F0
	MOVE.L	lbL003680(pc),D0
	BSR.W	lbC003468
;	MOVE.L	lbL003680,lbL00369C
;	MOVE.B	#$FF,lbB003668
	BRA.B	lbC0034BE

;lbC003578	TST.B	lbB003664
;	BEQ.S	lbC0035A0
;	CMPI.B	#$FF,lbB003664
;	BNE.L	lbC00359E
;lbC00358C	MOVE.B	#1,lbB003664
;	CMPI.B	#1,lbB003664
;	BNE.S	lbC00358C
;lbC00359E	RTS

;lbC0035A0	TST.L	lbL00367C
;	BEQ.S	lbC00353E
;	RTS

;	LEA	lbL003858,A0
;	LEA	lbL003B50,A1
;	MOVE.W	#$BD,D0
;lbC0035BA	MOVE.L	(A0)+,(A1)+
;	DBRA	D0,lbC0035BA
;	RTS

;	LEA	lbL003B50,A0
;	LEA	lbL003858,A1
;	MOVE.W	$BD,D0
;lbC0035D2	MOVE.L	(A0)+,(A1)+
;	DBRA	D0,lbC0035D2
;	RTS

;lbC0035DA	TST.B	lbB00366B
;	BEQ.S	lbC003606
;	MOVE.B	lbB003664,D0
;	BEQ.S	lbC0035F2
;	BMI.S	lbC0035F0
;	MOVEQ	#1,D0
;	RTS

;lbC0035F0	MOVEQ	#2,D0
;lbC0035F2	TST.B	lbB00366C
;	BEQ.S	lbC003604
;	TST.L	lbL003678
;	BNE.S	lbC003604
;	MOVEQ	#3,D0
;lbC003604	RTS

;lbC003606	MOVEQ	#4,D0
;	RTS

;	MOVE.B	lbB003668,D0
;	RTS

;	MOVE.L	lbL003680,D0
;	RTS

;	LEA	lbL0039D4,A0
;	MOVE.L	#lbL003688,$78(A0)
;	CLR.W	$7C(A0)
;	CLR.W	$7E(A0)
;	MOVE.W	#2,$DFF0C4
;	MOVE.L	#lbL003644,$DFF0C0
;	RTS

;lbL003644	dc.l	0

;	LEA	lbL0039D4,A0
;	MOVE.L	#$DFF0C0,$78(A0)
;	MOVE.W	#$40,$7C(A0)
;	MOVE.W	#$8040,$7E(A0)
;	RTS

lbB003664	dc.b	0			; +
lbB003665	dc.b	0			; +
lbB003666	dc.b	0			; +
;lbB003667	dc.b	0
;lbB003668	dc.b	0
;	dc.b	0
lbB00366A	dc.b	0			; +
;lbB00366B	dc.b	0
;lbB00366C	dc.b	0
lbB00366D	dc.b	4			; +
lbB00366E	dc.b	0			; +
lbB00366F	dc.b	0			; +
	dc.b	0
;	dc.b	0
;lbB003672	dc.b	0
;	dc.b	0
;	dc.b	0
;	dc.b	0
;	dc.b	0
;	dc.b	0
;lbL003678	dc.l	0
;lbL00367C	dc.l	0
lbL003680	dc.l	0			; +
;lbL003684	dc.l	0
;lbL003688	dc.l	0
;	dc.l	0
;	dc.l	0
;	dc.l	0
lbL003698	dc.l	0
;lbL00369C	dc.l	0
;	dc.l	0
;	dc.l	0
;	dc.w	$200
;	dc.l	FuturePlayer.MSG
;	dc.l	lbC002ADE
;	dc.l	lbC002ADE
;FuturePlayer.MSG	dc.b	'Future Player',0
lbW0036C4	dc.w	$1C40
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
lbL003786	dc.l	lbL003858
	dc.l	lbL003916
lbL00378E	dc.l	lbL0039D4
	dc.l	lbL003A92
	dc.l	$808000
lbL00379E	dc.l	0
	dc.l	0
	dc.l	lbL0037E8
	dc.l	lbL0037AE
lbL0037AE	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
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
lbL0037E8	dc.l	0
	dc.l	0
	dc.w	0
	dc.l	lbL0037F6
lbL0037F6	dc.l	0
	dc.l	0
emptySampleAddress
	;dc.l	emptySample
	dc.l	0

	dc.l	$20002
	dc.w	0
lbL003808	dc.l	lbC002CCC
	dc.l	lbC002CF2
	dc.l	lbC002D62
	dc.l	lbC002D68
	dc.l	lbC002D76
	dc.l	lbC002D7C
	dc.l	lbC002D7E
	dc.l	lbC002D9C
	dc.l	lbC002DA4
	dc.l	lbC002DB6
	dc.l	lbC002DC6
	dc.l	lbC002DD6
	dc.l	lbC002DDC
	dc.l	lbC002CC2
	dc.l	lbC002DF6
;	dc.b	'ciaa.resource',0,0
;	dc.b	0
;	dc.b	0
;	dc.b	0
;	dc.b	0
;	dc.b	0

;	Section	Buffy,BSS

lbL003858
	ds.b	190
lbL003916
	ds.b	190
lbL0039D4
	ds.b	190
lbL003A92
	ds.b	190
lbL003B50
;	ds.b	760


impEnd
