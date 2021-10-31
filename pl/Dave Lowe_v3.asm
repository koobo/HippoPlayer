;APS00000004000000040000000400000004000000040000000400000004000000040000000400000004
test_	=	0

	incdir	include:
	include	mucro.i
	include	misc/eagleplayer.i
	include	hardware/custom.i
	include	exec/exec_lib.i
	include	exec/memory.i
	include	dos/dos_lib.i
	include	exec/exec.i

 ifne test_
bob
	;lea	module,a0
	;jsr	Check3

	move.l	4.w,a6
	lea	dosname,a1
	jsr	_LVOOldOpenLibrary(a6)
	move.l d0,dosbase

	move.l	dosbase,a6
	move.l	#modulePath,d1
	jsr	_LVOLoadSeg(A6)
	tst.l	d0 
	beq.b		error
	lsl.l	#2,d0
	move.l	d0,a0

	* initial song number
	;lea	module,a0
	lea	masterVol,a1
	lea	songo,a2
	jsr	init
	bne.b	error

	bsr.b	playLoop

	addq	#1,SubSong
	move	SubSong,d0
	jsr	song
	bsr.b	playLoop

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
.y	btst	#6,$bfe001
	beq.b	.y

	rts


masterVol 	dc $40/1
songo		dc  0
dosbase dc.l 0
dosname dc.b "dos.library",0 

	SECTION	modu,data_c
;modulePath  dc.b "sys:music/roots/modules/dave lowe/dave lowe/afterburner.dl",0
;modulePath  dc.b "sys:music/roots/modules/dave lowe/dave lowe/international karate+.dl",0
modulePath  dc.b "sys:music/roots/modules/dave lowe/dave lowe/midwinter 2.dl",0
 even 
*****************************************************
	****      Dave Lowe replayer for EaglePlayer,	 ****
	****         all adaptions by Wanted Team	 ****
	****      DeliTracker 2.32 compatible version	 ****
	*****************************************************
 endc

	SECTION	Player,CODE

	jmp	init(pc)
	jmp	play(pc) 
	jmp	end(pc)
	jmp	song(pc)

flushCaches
	move.l	4.w,a6
	cmp	#37,LIB_VERSION(a6)
	blo.b	.old
	jsr	_LVOCacheClearU(a6)
.old
	rts

init	
	pushm	d4-a6
	move.l	a0,ModuleAddr
	move.l	a1,MainVolAddr
	move.l	a2,SongOverAddr

	move.l	ModuleAddr(pc),d0
	bsr.w	InitPlayer
	bsr.b	patch
	bsr.b	flushCaches
			
	bsr.w	InitSound
	bsr.w	SubSongRange
	move.l	d1,d2
	move.l	d0,d1
	move.l	InfoBuffer+SongName(PC),d3
	moveq	#0,d0
	popm	d4-a6
	rts 
play 
	move.l	MainVolAddr(pc),a0 
	move	(a0),MainVol
	bsr.w	Interrupt
	;move.l	CurrentPos(pc),d0 
	;move.l 	MaxPos(pc),d1
	;lsr.l	#2,d0
	;lsr.l	#2,d1
	rts 
end 
	bsr.w	EndSound
	;bsr.w	EndPlayer
	rts

song
	move	d0,SubSong
	bsr.w	InitSound
	rts

ModuleAddr		dc.l	0
MainVolAddr		dc.l	0
MainVol			dc.w 	0
SubSong  		dc.w 	1 * starts from 1
SongOverAddr	dc.l	0


patch
	lea	PatchTable(pc),a1

loop
	* find from a3 to a4
	move.l	ModuleAddr(pc),a0
	move.l	a0,a3
	move.l	InfoBuffer+LoadSize(pc),d0
	lea	(a0,d0.l),a4
	* Get code to find
	lea	PatchTable(pc),a2
	add	(a1),a2
findCode
	* read data word
	move	(a3),d7
	cmp.l	a4,a3
	bhs.b	notFound
	* compare patch word
	cmp	(a2),d7
	beq.b	found
notF	addq	#2,a3
	bra.b	findCode

found
	* compare length
	move	2(a1),d6
	move.l	a3,a6
	move.l	a2,a5
cmp	cmpm.w	(a5)+,(a6)+
	bne.b	notF
	dbf	d6,cmp
	* Found correct data at a3
	* apply patch

	* patch address
; JSR x = $4eB9 xxxx xxxx
; NOP   = $4e71
	lea	PatchTable(pc),a5
	add	4(a1),a5
	move	2(a1),d6
	move	#$4eb9,(a3)+
	move.l	a5,(a3)+
	subq	#3,d6	
	bmi.b	NoNop
nopFill	move	#$4e71,(a3)+
	dbf	d6,nopFill
NoNop	

notFound
	addq	#6,a1
	tst	(a1)
	bne.b	loop
	
	rts

;	PLAYERHEADER Tags
;
;	dc.b	'$VER: Dave Lowe player module V1.2 (9 June 2001)',0
;	even
;Tags
;	dc.l	DTP_PlayerVersion,3
;	dc.l	EP_PlayerVersion,9
;	dc.l	DTP_RequestDTVersion,'WT'
;	dc.l	DTP_PlayerName,PlayerName
;	dc.l	DTP_Creator,Creator
;;	dc.l	DTP_DeliBase,DeliBase
;;	dc.l	DTP_Check1,Check1
;	dc.l	EP_Check3,Check3
;	dc.l	DTP_Interrupt,Interrupt
;	dc.l	DTP_SubSongRange,SubSongRange
;	dc.l	DTP_InitPlayer,InitPlayer
;	dc.l	DTP_EndPlayer,EndPlayer
;	dc.l	DTP_InitSound,InitSound
;	dc.l	DTP_EndSound,EndSound
;	dc.l	EP_Get_ModuleInfo,GetInfos
;;	dc.l	EP_SampleInit,SampleInit
;	dc.l	EP_ModuleChange,ModuleChange
;;	dc.l	DTP_Volume,SetVolume
;;	dc.l	DTP_Balance,SetBalance
;;	dc.l	EP_Voices,SetVoices
;;	dc.l	EP_StructInit,StructInit
;	dc.l	EP_GetPositionNr,GetPosition
;	dc.l	EP_Flags,EPB_Volume!EPB_Balance!EPB_ModuleInfo!EPB_Voices!EPB_SampleInfo!EPB_Songend!EPB_Analyzer!EPB_NextSong!EPB_PrevSong!EPB_Restart
;	dc.l	TAG_DONE
;PlayerName
;	dc.b	'Dave Lowe',0
;Creator
;	dc.b	'(c) 1988-94 Dave Lowe from Uncle Art,',10
;	dc.b	'adapted by Wanted Team',0
;Prefix
;	dc.b	'DL.',0
;	even
;DeliBase
;	dc.l	0
ModulePtr
	dc.l	0
InitPtr
	dc.l	0
PlayPtr
	dc.l	0
EndPtr
	dc.l	0
SubsongPtr
	dc.l	0
SampleInfoPtr
	dc.l	0
EndSampleInfoPtr
	dc.l	0
Init2Ptr
	dc.l	0
InitPlayerPtr
	dc.l	0
FirstSubsongPtr
	dc.l	0
EagleBase
	dc.l	0
Change
	dc.w	0
SpecialFX
	dc.l	0
SongEnd
	dc.b	'WTWT'
CurrentPos
	dc.l	0
Hardware
	dc.l	$00DF0000
MaxPos
	dc.l	0
***************************************************************************
********************************* EP_GetPosNr *****************************
***************************************************************************

GetPosition
	move.l	CurrentPos(PC),D0
	lsr.l	#2,D0
	rts

***************************************************************************
**************************** EP_ModuleChange ******************************
***************************************************************************

;ModuleChange
;	move.w	Change(PC),D0
;	bne.s	NoChange
;	move.l	PlayPtr(PC),EPG_ARG1(A5)
;	lea	PatchTable(PC),A1
;	move.l	A1,EPG_ARG3(A5)
;	move.l	FirstSubsongPtr(PC),D1
;	beq.b	Old
;	sub.l	PlayPtr(PC),D1
;	bra.b	Skip
;Old
;	move.l	#900,D1
;Skip
;	move.l	D1,EPG_ARG2(A5)
;	moveq	#-2,D0
;	move.l	D0,EPG_ARG5(A5)		
;	moveq	#1,D0
;	move.l	D0,EPG_ARG4(A5)			;Search-Modus
;	moveq	#5,D0
;	move.l	D0,EPG_ARGN(A5)
;	move.l	EPG_ModuleChange(A5),A0
;	jsr	(A0)
;NoChange
;	move.w	#1,Change
;	moveq	#0,D0
;	rts

***************************************************************************
******************** DTP_Volume DTP_Balance *******************************
***************************************************************************

;SetVolume
;SetBalance
;	move.w	dtg_SndLBal(A5),D0
;	mulu.w	dtg_SndVol(A5),D0
;	lsr.w	#6,D0
;
;	move.w	D0,LeftVolume
;
;	move.w	dtg_SndRBal(A5),D0
;	mulu.w	dtg_SndVol(A5),D0
;	lsr.w	#6,D0
;
;	move.w	D0,RightVolume
;	moveq	#0,D0
	rts

ChangeVolume
	move.l	D0,-(A7)
	and.w	#$7F,D0
	mulu	MainVol(pc),d0
	lsr	#6,d0
	move	d0,8(a2)
	move.l	(A7)+,D0
	rts

*------------------------------- Set Vol -------------------------------*

;SetVol
;	move.l	A0,-(A7)
;	lea	StructAdr+UPS_Voice1Vol(PC),A0
;	cmp.l	#$DFF0A0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice2Vol(PC),A0
;	cmp.l	#$DFF0B0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice3Vol(PC),A0
;	cmp.l	#$DFF0C0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice4Vol(PC),A0
;.SetVoice
;	move.w	D0,(A0)
;	move.l	(A7)+,A0
;	rts

*------------------------------- Set Adr -------------------------------*

;SetAdr
;	move.l	A0,-(A7)
;	lea	StructAdr+UPS_Voice1Adr(PC),A0
;	cmp.l	#$DFF0A0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice2Adr(PC),A0
;	cmp.l	#$DFF0B0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice3Adr(PC),A0
;	cmp.l	#$DFF0C0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice4Adr(PC),A0
;.SetVoice
;	move.l	A1,(A0)
;	move.l	(A7)+,A0
;	rts

*------------------------------- Set Len -------------------------------*

;SetLen
;	move.l	A0,-(A7)
;	lea	StructAdr+UPS_Voice1Len(PC),A0
;	cmp.l	#$DFF0A0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice2Len(PC),A0
;	cmp.l	#$DFF0B0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice3Len(PC),A0
;	cmp.l	#$DFF0C0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice4Len(PC),A0
;.SetVoice
;	move.w	D0,(A0)
;	move.l	(A7)+,A0
;	rts

*------------------------------- Set Per -------------------------------*

;SetPer
;	move.l	A0,-(A7)
;	lea	StructAdr+UPS_Voice1Per(PC),A0
;	cmp.l	#$DFF0A0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice2Per(PC),A0
;	cmp.l	#$DFF0B0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice3Per(PC),A0
;	cmp.l	#$DFF0C0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice4Per(PC),A0
;.SetVoice
;	move.w	D0,(A0)
;	move.l	(A7)+,A0
;	rts

***************************************************************************
****************************** EP_Voices  *********************************
***************************************************************************

;SetVoices
;	lea	Voice1(PC),A0
;	lea	StructAdr(PC),A1
;	move.w	#$FFFF,D1
;	move.w	D1,(A0)+			Voice1=0 setzen
;	btst	#0,D0
;	bne.s	.NoVoice1
;	clr.w	-2(A0)
;	clr.w	$DFF0A8
;	clr.w	UPS_Voice1Vol(A1)
;.NoVoice1
;	move.w	D1,(A0)+			Voice2=0 setzen
;	btst	#1,D0
;	bne.s	.NoVoice2
;	clr.w	-2(A0)
;	clr.w	$DFF0B8
;	clr.w	UPS_Voice2Vol(A1)
;.NoVoice2
;	move.w	D1,(A0)+			Voice3=0 setzen
;	btst	#2,D0
;	bne.s	.NoVoice3
;	clr.w	-2(A0)
;	clr.w	$DFF0C8
;	clr.w	UPS_Voice3Vol(A1)
;.NoVoice3
;	move.w	D1,(A0)+			Voice4=0 setzen
;	btst	#3,D0
;	bne.s	.NoVoice4
;	clr.w	-2(A0)
;	clr.w	$DFF0D8
;	clr.w	UPS_Voice4Vol(A1)
;.NoVoice4
;	move.w	D0,UPS_DMACon(A1)
;	moveq	#0,D0
;	rts

***************************************************************************
******************************* EP_StructInit *****************************
***************************************************************************

;StructInit
;	lea	StructAdr(PC),A0
;	rts

***************************************************************************
******************************* EP_SampleInit *****************************
***************************************************************************

;SampleInit
;	moveq	#EPR_NotEnoughMem,D7
;	lea	EPG_SampleInfoStructure(A5),A3
;	move.l	SampleInfoPtr(PC),D0
;	beq.b	return
;	move.l	D0,A0
;
;	move.l	InfoBuffer+Samples(PC),D5
;	beq.b	return
;	subq.l	#1,D5
;hop
;	jsr	ENPP_AllocSampleStruct(A5)
;	move.l	D0,(A3)
;	beq.b	return
;	move.l	D0,A3
;
;	moveq	#0,D0
;	move.l	2(A0),D1
;	beq.b	Empty
;	move.w	6(A0),D0
;	add.l	D0,D0
;	move.l	D1,EPS_Adr(A3)			; sample address
;Empty
;	move.l	D0,EPS_Length(A3)		; sample length
;	move.l	#64,EPS_Volume(A3)
;	move.w	#USITY_RAW,EPS_Type(A3)
;;	move.w	#USIB_Playable!USIB_Saveable!USIB_8BIT,EPS_Flags(A3)
;	lea	14(A0),A0
;	dbf	D5,hop
;
;	moveq	#0,D7
;return
;	move.l	D7,D0
;	rts

***************************************************************************
******************************** DTP_Check1 *******************************
***************************************************************************

;Check1
;	move.l	DeliBase(PC),D0
	;beq.b	fail

***************************************************************************
******************************* EP_Check3 *********************************
***************************************************************************

;Check3
;;	movea.l	dtg_ChkData(A5),A0
;
;	cmp.l	#$000003F3,(A0)
;	bne.b	fail
;	tst.b	20(A0)				; loading into chip check
;	beq.b	fail
;	lea	32(A0),A0
;	cmp.l	#$70FF4E75,(A0)+
;	bne.b	fail
;	cmp.l	#'UNCL',(A0)+
;	bne.b	fail
;	cmp.l	#'EART',(A0)+
;	bne.b	fail
;	tst.l	(A0)+				; InitSound pointer check
;	beq.b	fail
;	tst.l	(A0)+				; Interrupt pointer check
;	beq.b	fail
;	addq.l	#4,A0
;	tst.l	(A0)				; Subsong Counter label check
;	beq.b	fail
;	moveq	#0,D0
;	rts
;fail
;	moveq	#-1,D0
;	rts

***************************************************************************
***************************** EP_Get_ModuleInfo ***************************
***************************************************************************

;GetInfos
;	lea	InfoBuffer(PC),A0
;	rts

SubSongs	=	4
LoadSize	=	12
SongSize	=	20
SamplesSize	=	28
Samples		=	36
CalcSize	=	44
SpecialInfo	=	52
AuthorName	=	60
SongName	=	68
Length		=	76

InfoBuffer
	dc.l	MI_SubSongs,0		;4
	dc.l	MI_LoadSize,0		;12
	dc.l	MI_Songsize,0		;20
	dc.l	MI_SamplesSize,0	;28
	dc.l	MI_Samples,0		;36
	dc.l	MI_Calcsize,0		;44
	dc.l	MI_SpecialInfo,0	;52
	dc.l	MI_AuthorName,0		;60
	dc.l	MI_SongName,0		;68
	dc.l	MI_Length,0		;76
;	dc.l	MI_Prefix,Prefix
	dc.l	0

***************************************************************************
***************************** DTP_Intterrupt ******************************
***************************************************************************

Interrupt	
	movem.l	D1-A6,-(SP)

;	lea	StructAdr(PC),A0
;	st	UPS_Enabled(A0)
;	clr.w	UPS_Voice1Per(A0)
;	clr.w	UPS_Voice2Per(A0)
;	clr.w	UPS_Voice3Per(A0)
;	clr.w	UPS_Voice4Per(A0)
;	move.w	#UPSB_Adr!UPSB_Len!UPSB_Per!UPSB_Vol,UPS_Flags(A0)

	move.l	PlayPtr(PC),A0

	jsr	(A0)			; play module

;	lea	StructAdr(PC),A0
;	clr.w	UPS_Enabled(A0)
;
	movem.l	(SP)+,D1-A6
	moveq	#0,D0
	rts

***************************************************************************
***************************** DTP_SubSongRange ****************************
***************************************************************************

SubSongRange	
	moveq	#1,D0
	move.l	InfoBuffer+SubSongs(PC),D1
	rts

***************************************************************************
***************************** DTP_InitPlayer ******************************
***************************************************************************

InitPlayer
	addq.l	#4,D0
	move.l	D0,A0				; module address
	lea	ModulePtr(PC),A1
	move.l	D0,(A1)+
	addq.l	#8,A0
	addq.l	#4,A0
	move.l	(A0)+,(A1)+			; Init pointer
	move.l	(A0)+,(A1)+			; Play pointer
	move.l	(A0)+,(A1)+			; End pointer
	move.l	(A0)+,(A1)+			; SubsongCtr pointer
	move.l	(A0)+,(A1)+			; SampleInfo pointer
	move.l	(A0)+,(A1)+			; EndSampleInfo pointer
	move.l	(A0)+,(A1)+			; Init2 pointer
	move.l	(A0)+,(A1)+			; InitPlayer pointer
	move.l	(A0)+,(A1)			; FirstSubsong pointer
	lea	EagleBase(PC),A3
	;move.l	A5,(A3)+			; EagleBase
	clr.l	(A3)+
	clr.w	(A3)+				; clearing change flag
	lea	InfoBuffer(PC),A2
	move.l	(A0)+,SongName(A2)
	move.l	(A0)+,AuthorName(A2)
	move.l	(A0)+,SpecialInfo(A2)
	move.l	(A0)+,LoadSize(A2)
	move.l	(A0)+,CalcSize(A2)
	move.l	(A0)+,SamplesSize(A2)
	move.l	(A0)+,SongSize(A2)
	move.l	(A0),(A3)			; SpecialFX number
	moveq	#1,D0
	move.l	(A1),D1
	beq.b	SubEnd
	move.l	D1,A1
NextSub
	lea	16(A1),A1
	move.l	(A1),D1
	beq.b	SubEnd
	sub.b	3(A1),D1
	tst.l	D1
	beq.b	SubEnd
	addq.l	#1,D0
	bra.b	NextSub
SubEnd
	move.l	D0,SubSongs(A2)

	clr.l	Samples(A2)
	move.l	EndSampleInfoPtr(PC),D0
	beq.b	SkipSamples
	sub.l	SampleInfoPtr(PC),D0
	divu.w	#14,D0
	move.l	D0,Samples(A2)
SkipSamples
	move.l	PlayPtr(PC),A0
	lea	380(A0),A0
Find
	cmp.l	#$35400008,(A0)
	beq.b	Patch
	cmp.l	#$35590008,(A0)			; ISS exception
	beq.b	SkipPatch
	addq.l	#2,A0
	bra.b	Find
Patch						; branch patch 
	cmp.w	#$6000,4(A0)			; from bra.w to bra.b
	bne.b	SkipPatch
	add.w	#$6002,6(A0)
SkipPatch

	cmp.l	#77554,LoadSize(A2)		; fixes for Midwinter2
	bne.b	NoMidwinter2
	cmp.w	#17,SubSongs+2(A2)
	bne.b	NoMidwinter2
	move.l	ModulePtr(PC),A0
	lea	Song_03(PC),A2
	lea	$2E44(A0),A1
	moveq	#3,D0
Fix_03
	move.l	A2,(A1)+
	dbf	D0,Fix_03
	lea	8494(A1),A4
	lea	Label_03(PC),A1
	move.l	A4,(A1)
	lea	Song_11(PC),A2
	lea	$261A(A0),A1
	move.l	A2,(A1)
	lea	Label_11_A(PC),A1
	move.l	A4,(A1)
	lea	Label_11_B(PC),A1
	move.l	A4,(A1)

	lea	Song_13(PC),A2
	lea	$2F6E(A0),A1
	moveq	#4,D0
Fix_13
	move.l	A2,(A1)+
	dbf	D0,Fix_13
	lea	Label_13(PC),A1
	move.l	A4,(A1)

NoMidwinter2
	;bsr.w	ModuleChange

	move.l	InitPlayerPtr(PC),D0
	beq.b	SkipInit
	move.l	D0,A1
	jsr	(A1)
SkipInit
	;movea.l	dtg_AudioAlloc(A5),A0
	;jmp	(A0)
	rts

;InitFail
;	moveq	#EPR_NotEnoughMem,D0
;	rts

***************************************************************************
***************************** DTP_EndPlayer *******************************
***************************************************************************

;EndPlayer
;	move.l	dtg_DOSBase(A5),A6
;	move.l	ModulePtr(PC),D1
;	subq.l	#4,D1
;	lsr.l	#2,D1
;	jsr	_LVOUnLoadSeg(A6)
;	movea.l	dtg_AudioFree(A5),A0
;	jmp	(A0)

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
	lea	SongEnd(PC),A3
	move.l	#$FEFEFEFE,(A3)+
	clr.l	(A3)				; clearing CurrentPos
	lea	InfoBuffer(PC),A2
	move.w	#245,Length+2(A2)		; fix for IK+ (length)
	move.w	#$F0A0,6(A3)
	move.l	FirstSubsongPtr(PC),D0
	beq.b	NoLength
	move.l	D0,A0
	moveq	#-1,D2
	add.w	SubSong(pc),D2
FindMaxLength
	moveq	#3,D3
	moveq	#0,D0
	move.w	#$F090,D4
NextLength
	addq.w	#8,D4
	addq.w	#8,D4
	move.l	(A0),A1
	moveq	#-1,D1
FindZero
	addq.l	#1,D1
	tst.l	(A1)+
	bne.b	FindZero
	cmp.l	D1,D0
	bgt.b	MaxLength
	move.l	D1,D0
	move.w	D4,6(A3)
MaxLength
	addq.l	#4,A0
	dbf	D3,NextLength
	dbf	D2,FindMaxLength
	move.l	D0,Length(A2)

NoLength
	move.l	Init2Ptr(PC),D0
	beq.b	NoInit2
	move.l	D0,A0
	jsr	(A0)
NoInit2
	move.l	SubsongPtr(PC),A1
	move.w	SubSong(pc),(A1)
	move.l	SpecialFX(PC),D1
	beq.b	NoSFX
	cmp.w	#1,(A1)
	bne.b	NoSFX
	move.l	D1,-6(A1)
NoSFX
	move.l	InitPtr(PC),A0
	jmp	(A0)

***************************************************************************
***************************** DTP_EndSound ********************************
***************************************************************************

EndSound
	move.l	EndPtr(PC),D0
	beq.b	Standard
	move.l	D0,A0
	jmp	(A0)

Standard
	lea	$DFF000,A0
	move.w	#15,$96(A0)
	moveq	#0,D0
	move.w	D0,$A8(A0)
	move.w	D0,$B8(A0)
	move.w	D0,$C8(A0)
	move.w	D0,$D8(A0)
	rts


	*----------------- PatchTable for Dave Lowe -------------------*

PatchTable
	dc.w	Code0-PatchTable,(Code0End-Code0)/2-1,Patch0-PatchTable
	dc.w	Code1-PatchTable,(Code1End-Code1)/2-1,Patch1-PatchTable
	dc.w	Code2-PatchTable,(Code2End-Code2)/2-1,Patch1-PatchTable
	dc.w	Code3-PatchTable,(Code3End-Code3)/2-1,Patch3-PatchTable
	dc.w	Code4-PatchTable,(Code4End-Code4)/2-1,Patch4-PatchTable
	dc.w	Code5-PatchTable,(Code5End-Code5)/2-1,Patch5-PatchTable
	dc.w	Code6-PatchTable,(Code6End-Code6)/2-1,Patch6-PatchTable
	dc.w	Code7-PatchTable,(Code7End-Code7)/2-1,Patch7-PatchTable
	dc.w	Code8-PatchTable,(Code8End-Code8)/2-1,Patch8-PatchTable
	dc.w	Code9-PatchTable,(Code9End-Code9)/2-1,Patch9-PatchTable
	dc.w	CodeA-PatchTable,(CodeAEnd-CodeA)/2-1,PatchA-PatchTable
	dc.w	CodeB-PatchTable,(CodeBEnd-CodeB)/2-1,PatchB-PatchTable
	dc.w	CodeC-PatchTable,(CodeCEnd-CodeC)/2-1,PatchC-PatchTable
	dc.w	0

; Volume patch and fix (!!!) for Dave Lowe modules
; Priority before patch 2 !!!

Code0
	SUB.W	$3E(A0),D0
	BCC.B	lbC00089C
	MOVE.W	0,D0
lbC00089C	MOVE.W	D0,8(A2)
	dc.w	$6000
Code0End
Patch0
	sub.w	$3E(A0),D0
	bcc.b	SkipZero
	move.w	#0,D0
SkipZero
	bsr.b	Patch1
	rts

; Volume patch for Dave Lowe modules

Code1
	MOVE.W	D0,8(A2)
	MOVE.L	A1,$12(A0)
Code1End
Patch1
	bsr.w	ChangeVolume
	;bsr.w	SetVol
	move.l	A1,$12(A0)
	rts

; Volume patch for Dave Lowe modules

Code2
	MOVE.W	D0,8(A2)
	dc.w	$6000
Code2End
Patch2							; used patch 1

; Period patch for Dave Lowe modules

Code3
	MOVE.W	D2,6(A0)
	MOVE.W	D2,6(A2)
Code3End
Patch3
	move.w	D2,6(A0)
	move.w	D2,6(A2)
	move.l	D0,-(A7)
	move.w	D2,D0
	;bsr.w	SetPer
	move.l	(A7)+,D0
	rts

; Period patch for Dave Lowe modules
; Priority before patch C !!!

Code4
	MOVE.W	D0,6(A0)
	MOVE.W	D0,6(A2)
	MOVE.W	(A1)+,2(A0)
Code4End
Patch4
	move.w	D0,6(A0)
	move.w	D0,6(A2)
	;bsr.w	SetPer
	move.w	(A1)+,2(A0)
	rts

; Address/length patch for Dave Lowe modules

Code5
	MOVE.L	$26(A0),(A2)
	MOVE.W	$2A(A0),4(A2)
Code5End
Patch5
	movem.l	D0/A1,-(A7)
	move.l	$26(A0),A1
	move.l	A1,(A2)
	;bsr.w	SetAdr
	move.w	$2A(A0),D0
	move.w	D0,4(A2)
	;bsr.w	SetLen
	movem.l	(A7)+,D0/A1
	rts

; Volume patch for Dave Lowe modules
; Priority before patch 8 !!!

Code6
	MOVE.W	D0,8(A2)
	MOVE.W	(A1)+,8(A2)
	MOVE.L	A1,$12(A0)
Code6End
Patch6
	bsr.w	ChangeVolume
	;bsr.w	SetVol
	bsr.b	Patch8
	rts

; Address/length patch for Dave Lowe modules
; Unused because lame scopes output

;CodeX
;	MOVE.L	$2C(A0),(A2)
;	MOVE.W	$30(A0),4(A2)
;CodeXEnd
;PatchX
;	movem.l	D0/A1,-(A7)
;	move.l	$2C(A0),A1
;	move.l	A1,(A2)
;	bsr.w	SetAdr
;	move.w	$30(A0),D0
;	move.w	D0,4(A2)
;	bsr.w	SetLen
;	movem.l	(A7)+,D0/A1
;	rts

; Address/length patch for Dave Lowe modules

Code7
	MOVE.L	(A3)+,(A2)
	MOVE.W	(A3),4(A2)
Code7End
Patch7
	movem.l	D0/A1,-(A7)
	move.l	(A3)+,A1
	move.l	A1,(A2)
	;bsr.w	SetAdr
	move.w	(A3),D0
	move.w	D0,4(A2)
	;bsr.w	SetLen
	movem.l	(A7)+,D0/A1
	rts

; Volume patch for Dave Lowe modules

Code8
	MOVE.W	(A1)+,8(A2)
	MOVE.L	A1,$12(A0)
Code8End
Patch8
	move.l	D0,-(A7)
	move.w	(A1)+,D0
	bsr.w	ChangeVolume
	;bsr.w	SetVol
	move.l	(A7)+,D0
	move.l	A1,$12(A0)
	rts

; Fix (!!!) for Dave Lowe modules

Code9
	MOVE.W	0,$42(A0)
Code9End
Patch9
	move.w	#0,$42(A0)
	rts

; SongEnd patch for Dave Lowe modules
; Priority before patch B !!!

CodeA
	MOVE.L	$1E(A0),$1A(A0)
	MOVEA.L	$1A(A0),A1
	ADDQ.L	#4,$1A(A0)

CodeAEnd
PatchA
	move.l	$1E(A0),$1A(A0)
	move.l	$1A(A0),A1
	addq.l	#4,$1A(A0)
SongEndTest
	movem.l	A1/A5,-(A7)
	lea	SongEnd(PC),A1
	cmp.l	#$DFF0A0,A2
	bne.b	test1
	tst.b	(A1)
	beq.b	test
	addq.b	#1,(A1)
	bra.b	test
test1
	cmp.l	#$DFF0B0,A2
	bne.b	test2
	tst.b	1(A1)
	beq.b	test
	addq.b	#1,1(A1)
	bra.b	test
test2
	cmp.l	#$DFF0C0,A2
	bne.b	test3
	tst.b	2(A1)
	beq.b	test
	addq.b	#1,2(A1)
	bra.b	test
test3
	cmp.l	#$DFF0D0,A2
	bne.b	test
	tst.b	3(A1)
	beq.b	test
	addq.b	#1,3(A1)
test
	tst.l	(A1)
	bne.b	SkipEnd
	move.l	#$FFFFFFFF,(A1)+
	clr.l	(A1)
	;move.l	EagleBase(PC),A5
	tst.l	-8(A1)
	beq.b	NoSFX2
	cmp.w	#1,SubSong
	bne.b	NoSFX2
	move.l	SubsongPtr(PC),A1
	move.l	SpecialFX(PC),-6(A1)
NoSFX2
	move.l 	SongOverAddr(pc),a1 
	st (a1)
	;move.l	dtg_SongEnd(A5),A1
	;jsr	(A1)
SkipEnd
	movem.l	(A7)+,A1/A5
	rts

; Position Counter patch for Dave Lowe modules

CodeB
	ADDQ.L	#4,$1A(A0)
	MOVEA.L	(A1),A1
CodeBEnd
PatchB
	cmp.l	Hardware(PC),A2
	bne.b	Exit3
	move.l	$1A(A0),D0
	move.l	d0,MaxPos
	sub.l	$1E(A0),D0
	move.l	D0,CurrentPos
Exit3
	addq.l	#4,$1A(A0)
	move.l	(A1),A1
	rts

; SongEnd patch for Dave Lowe modules

CodeC
	MOVE.W	(A1)+,2(A0)
	SUBQ.W	#1,2(A0)
CodeCEnd
PatchC
	move.w	(A1)+,D7
	bpl.b	OKi
	bsr.w	SongEndTest
OKi
	move.w	D7,2(A0)
	subq.w	#1,2(A0)
	rts


; Midwinter2 patches

Song_03
	dc.w	12
	dc.l	Fiksik_1
	dc.w	4
Label_03
	dc.l	'WTWTWTWT'		;lbW035156
	dc.l	$1AC000A
	dc.l	$194000A
	dc.l	$1C5000A
	dc.l	$1AC000A
	dc.l	$1AC000A
	dc.l	$194000A
	dc.l	$1C5000A
	dc.l	$1AC000A
	dc.w	8

Song_11
	dc.w	12
	dc.l	Fiksik_1
	dc.w	4
Label_11_A
	dc.l	'WTWTWTWT'		;lbW035156
	dc.l	$1AC0018
	dc.l	$17D0020
	dc.l	$1680020
	dc.l	$17D0028
	dc.l	$1AC0018
	dc.l	$17D0020
	dc.l	$1680020
	dc.l	$1400028
	dc.w	12
	dc.l	Fiksik_2
	dc.w	4
Label_11_B
	dc.l	'WTWTWTWT'		;lbW035156
	dc.l	$11D0008
	dc.l	$11D0008
	dc.l	$11D0008
	dc.l	$11D0008
	dc.l	$11D0008
	dc.l	$11D0008
	dc.l	$11D0008
	dc.l	$11D0008
	dc.l	$11D0008
	dc.l	$11D0008
	dc.l	$11D0008
	dc.l	$11D0008
	dc.l	$11D0008
	dc.l	$1400008
	dc.l	$1680008
	dc.l	$17D0008
	dc.l	$1AC0008
	dc.w	8
Song_13
	dc.w	12
	dc.l	Fiksik_1
	dc.w	4
Label_13
	dc.l	'WTWTWTWT'		;lbW035156
	dc.l	$1AC000A
	dc.l	$1AC000A
	dc.l	$D6000A
	dc.l	$1680005
	dc.l	$F0000A
	dc.l	$1400005
	dc.l	$D6000A
	dc.l	$11D000A
	dc.l	$12E000A
	dc.l	$801AC
	dc.l	$A0020
	dc.l	$460008

Fiksik_1
	dc.w	0
	dc.l	$2C00FF
Fiksik_2
	dc.w	0
	dc.l	$400040
	dc.l	$3B0036
	dc.l	$31002C
	dc.l	$280023
	dc.l	$1E0019
	dc.l	$14000F
	dc.w	$FF

