;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000


test	=	0

	incdir	include:
	include	exec/exec_lib.i
	include	exec/execbase.i
	include	dos/dos_lib.i
	include	exec/memory.i
	include "hardware/intbits.i"


 ifne test
bob
	lea	module,a0
	jsr	Check2

	* initial song number
	lea	module,a0
	moveq	#0,d0
	lea	masterVol,a1
	lea 	songCount,a2
	jsr	init
	bne	error

	bsr	playLoop
	moveq	#1,d0
	jsr	song
	bsr	playLoop
.e
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


masterVol 	dc $40
songCount	dc 0

	SECTION	modu,data_c

module  incbin	"sys:music/roots/Modules/Ben Daglish/Ben Daglish/super cars.bd"
;module  incbin	"sys:music/roots/Modules/Ben Daglish/Ben Daglish/switchblade.bd"
;module  incbin	"sys:music/roots/Modules/Ben Daglish/Ben Daglish/blasteroids.bd"

	SECTION	Player,CODE

 endif

bdStart
	jmp	init(pc)
	jmp	play(pc)
	jmp	end(pc)
	jmp	song(pc)


songCountAddress	dc.l 	0
moduleAddress		dc.l	0
masterVolumeAddress	dc.l	0
masterVolume		dc	$40
songNumber		dc	0

flushCaches
	move.l	4.w,a6
	cmp	#37,LIB_VERSION(a6)
	blo.b	.old
	jsr	_LVOCacheClearU(a6)
.old
	rts

init
	move.l	a0,moduleAddress
	move.l	a1,masterVolumeAddress
	move.l	a2,songCountAddress
	move	d0,songNumber

	bsr.w	InitPlayer
	bne.b	.error
	bsr.b	flushCaches

	bsr.w	SubSongRange
	move.l	songCountAddress(pc),a0
	move	d1,(a0)


	bsr.w	InitSound


	moveq	#0,d0
	rts

.error
	moveq	#-1,d0
	rts

play
	move.l	masterVolumeAddress(pc),a0
	move	(a0),masterVolume
	bsr.w	Interrupt
	rts
end	
	bsr.w	EndSound
	bsr.w	EndPlayer
	rts

song	
	move	d0,songNumber
	bsr.b	end
	bsr.w	InitPlayer
	bsr.w	InitSound
	rts



	****************************************************
	****   Benn Daglish replayer for EaglePlayer,	****
	****   all adaptions by Mr.Larmer/Wanted Team	****
	****     DeliTracker (?) compatible version	****
	****************************************************

	;incdir	"dh2:include/"
	;include "misc/eagleplayer2.01.i"
	;include	"exec/exec_lib.i"


;	PLAYERHEADER Tags
;
;	dc.b	'$VER: Benn Daglish player module V1.2 (6 Mar 2004)',0
;	even
;Tags
;	dc.l	DTP_PlayerVersion,3
;	dc.l	EP_PlayerVersion,9
;	dc.l	DTP_RequestDTVersion,DELIVERSION
;	dc.l	DTP_PlayerName,PlayerName
;	dc.l	DTP_Creator,Creator
;	dc.l	DTP_Check2,Check2
;	dc.l	DTP_Interrupt,Interrupt
;	dc.l	DTP_SubSongRange,SubSongRange
;	dc.l	DTP_InitPlayer,InitPlayer
;	dc.l	DTP_EndPlayer,EndPlayer
;	dc.l	DTP_InitSound,InitSound
;	dc.l	DTP_EndSound,EndSound
;	dc.l	EP_Get_ModuleInfo,GetInfos
;	dc.l	DTP_Volume,SetVolume
;	dc.l	DTP_Balance,SetBalance
;	dc.l	EP_StructInit,StructInit
;	dc.l	EP_SampleInit,SampleInit
;	dc.l	EP_Voices,SetVoices
;	dc.l	EP_GetPositionNr,GetPosition
;	dc.l	EP_Flags,EPB_Volume!EPB_Balance!EPB_ModuleInfo!EPB_Voices!EPB_SampleInfo!EPB_Songend!EPB_Analyzer!EPB_NextSong!EPB_PrevSong!EPB_Packable!EPB_Restart
;	dc.l	0

;PlayerName
;	dc.b	'Benn Daglish',0
;Creator
;	dc.b	'(c) 1988-92 by Colin Dooley & Ben(n)',10
;	dc.b	'Daglish, adapted by Mr.Larmer/WT',0
Prefix	dc.b	'BD.',0
	even
ModulePtr
	dc.l	0
SampleInfo1
	dc.l	0
SampleInfo2
	dc.l	0
SmpIn1SmpInfo
	dc.l	0
SmpIn2SmpInfo
	dc.l	0
SamplePtr
	dc.l	0
EagleBase
	dc.l	0
Base
	dc.l	0
VStart
	dc.l	0
Periods
	dc.l	0
	dc.l	0
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
********************************* EP_GetPosNr *****************************
***************************************************************************

GetPosition
	move.l	Base(PC),A0
	move.l	2(A0),D0
	sub.l	VStart(PC),D0
	rts

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
;	lea	OldVoice1(PC),A1
;	moveq	#3,D1
;	lea	$DFF0A0,A2
;SetNew
;	move.w	(A1)+,D0
;	bsr.b	ChangeVolume
;	lea	16(A2),A2
;	dbf	D1,SetNew
	rts

ChangeVolume
	and		#$7f,d0
	mulu	masterVolume(pc),d0 
	lsr		#6,d0
	move	d0,8(a2)	* AUDxVOL

;	cmpa.l	#$DFF0A0,A2			;Left Volume
;	bne.b	NoVoice1
;	move.w	D0,OldVoice1
;	tst.w	Voice1
;	bne.b	Voice1On
;	moveq	#0,D0
;Voice1On
;	mulu.w	LeftVolume(PC),D0
;	bra.b	SetIt
;NoVoice1
;	cmpa.l	#$DFF0B0,A2			;Right Volume
;	bne.b	NoVoice2
;	move.w	D0,OldVoice2
;	tst.w	Voice2
;	bne.b	Voice2On
;	moveq	#0,D0
;Voice2On
;	mulu.w	RightVolume(PC),D0
;	bra.b	SetIt
;NoVoice2
;	cmpa.l	#$DFF0C0,A2			;Right Volume
;	bne.b	NoVoice3
;	move.w	D0,OldVoice3
;	tst.w	Voice3
;	bne.b	Voice3On
;	moveq	#0,D0
;Voice3On
;	mulu.w	RightVolume(PC),D0
;	bra.b	SetIt
;NoVoice3
;	move.w	D0,OldVoice4
;	tst.w	Voice4
;	bne.b	Voice4On
;	moveq	#0,D0
;Voice4On
;	mulu.w	LeftVolume(PC),D0
;SetIt
;	lsr.w	#6,D0
;	move.w	D0,8(A2)
	rts

*------------------------------- Set Vol -------------------------------*

SetVol
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
	rts

*------------------------------- Set Two -------------------------------*

SetTwo
;	move.l	A1,-(A7)
;	lea	StructAdr+UPS_Voice1Adr(PC),A1
;	cmp.l	#$DFF0A0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice2Adr(PC),A1
;	cmp.l	#$DFF0B0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice3Adr(PC),A1
;	cmp.l	#$DFF0C0,A2
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice4Adr(PC),A1
;.SetVoice
;	move.l	A3,(A1)
;	move.w	8(A0),UPS_Voice1Len(A1)
;	move.l	(A7)+,A1
	rts

*------------------------------- Set Per -------------------------------*

SetPer

;	movem.l	A0/A1,-(A7)
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
;	add.w	New+2(PC),A1
;	move.w	(A1),(A0)
;	movem.l	(A7)+,A0/A1
	rts

***************************************************************************
****************************** EP_Voices **********************************
***************************************************************************

;		d0 Bit 0-3 = Set Voices Bit=1 Voice on

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
;	moveq	#0,D0
	rts

***************************************************************************
******************************* EP_StructInit *****************************
***************************************************************************

StructInit
;	lea	StructAdr(PC),A0
	rts

***************************************************************************
******************************* EP_SampleInit *****************************
***************************************************************************

SampleInit
;	moveq	#EPR_NotEnoughMem,D7
;	lea	EPG_SampleInfoStructure(A5),A3
;	move.l	SmpIn1SmpInfo(PC),D2
;	beq.w	return
;	lsl.l	#2,D2
;
;	moveq	#0,D1
;	move.l	SampleInfo1(PC),A1
;	move.l	A1,A4
;
;	bsr.b	l1
;
;	moveq	#0,D1
;	move.l	SmpIn2SmpInfo(PC),D2
;	beq.w	Skip
;	lsl.l	#2,D2
;	move.l	SampleInfo2(PC),A1
;
;l1
;	jsr	ENPP_AllocSampleStruct(A5)
;	move.l	D0,(A3)
;	beq.w	return
;	move.l	D0,A3
;
;	move.l	A4,A0
;	move.l	A1,A2
;	add.l	(A1,D1.W),A2
;	add.l	(A2),A0
;	moveq	#0,D3
;	move.w	8(A2),D3
;	move.l	(A2),D4
;	cmp.l	4(A2),D4
;	beq.b	NoS
;	moveq	#0,D4
;	move.w	10(A2),D4
;	add.l	D4,D3
;NoS
;	lsl.l	#1,D3
;
;	cmp.b	#'F',(A0)
;	bne.b	NoName
;	cmp.b	#'O',1(A0)
;	bne.b	NoName
;	cmp.b	#'R',2(A0)
;	bne.b	NoName
;	cmp.b	#'M',3(A0)
;	bne.b	NoName
;	lea	48(A0),A6
;	move.l	A6,EPS_SampleName(A3)
;	move.w	#20,EPS_MaxNameLen(A3)
;NoName
;	move.l	A0,EPS_Adr(A3)
;	move.l	D3,EPS_Length(A3)
;	move.l	#64,EPS_Volume(A3)
;	move.w	#USITY_RAW,EPS_Type(A3)
;	move.w	#USIB_Playable!USIB_Saveable!USIB_8BIT,EPS_Flags(A3)
;
;	addq.l	#4,D1
;
;	cmp.l	D1,D2
;	bne.b	l1
;Skip
;	moveq	#0,D7
;return
;	move.l	D7,D0
	rts

***************************************************************************
******************************* DTP_Check2 ********************************
***************************************************************************

 ifne test
Check2
;	movea.l	dtg_ChkData(A5),A0
	moveq	#-1,D0

	cmp.w	#$6000,(A0)+
	bne.s	fail
	move.l	A0,A1
	move.w	(A0)+,D1
	beq.b	fail
	bmi.b	fail
	btst	#0,D1
	bne.b	fail
	cmp.w	#$6000,(A0)+
	bne.s	fail
	move.w	(A0)+,D1
	beq.b	fail
	bmi.b	fail
	btst	#0,D1
	bne.b	fail
	addq.l	#2,A0
	cmp.w	#$6000,(A0)+
	bne.s	fail
	move.w	(A0),D1
	beq.b	fail
	bmi.b	fail
	btst	#0,D1
	bne.b	fail
	add.w	(A1),A1
	cmp.l	#$3F006100,(A1)
	bne.s	fail
	cmpi.w	#$3D7C,6(A1)
	bne.s	fail
	cmpi.w	#$41FA,12(A1)
	bne.s	fail

	moveq	#0,D0
fail
	rts
 endc
 
***************************************************************************
***************************** EP_Get_ModuleInfo ***************************
***************************************************************************

GetInfos
	lea	InfoBuffer(PC),A0
	rts

SubSongs	=	4
LoadSize	=	12
Songsize	=	20
SamplesSize	=	28
Samples		=	36
Calcsize	=	44
Length		=	52

MI_SubSongs		= 1		
MI_LoadSize		= 2	
MI_Calcsize		= 3		
MI_SpecialInfo	= 4
MI_AuthorName	= 5	
MI_SongName		= 6		
MI_Voices		= 7	
MI_MaxVoices	= 8
MI_Prefix       = 9
MI_Songsize	= 10
MI_SamplesSize	= 11
MI_Samples	= 12
MI_Length	= 13


InfoBuffer
	dc.l	MI_SubSongs,0		;4
	dc.l	MI_LoadSize,0		;12
	dc.l	MI_Songsize,0		;20
	dc.l	MI_SamplesSize,0	;28
	dc.l	MI_Samples,0		;36
	dc.l	MI_Calcsize,0		;44
	dc.l	MI_Length,0		;52
	dc.l	MI_AuthorName,0  ;;PlayerName
	dc.l	MI_Prefix,Prefix
	dc.l	0

***************************************************************************
***************************** DTP_SubSongRange ****************************
***************************************************************************

SubSongRange
	moveq	#0,D0
	move.l	InfoBuffer+SubSongs(PC),D1
	subq.l	#1,D1
	rts

***************************************************************************
***************************** DTP_InitPlayer ******************************
***************************************************************************

InitPlayer
	;moveq	#0,D0
	;movea.l	dtg_GetListData(A5),A0
	;jsr	(A0)

	move.l 	moduleAddress(pc),a0
	lea	ModulePtr(PC),A6
	move.l	A0,(A6)+			; module buffer

	lea	InfoBuffer(PC),A4
	;move.l	D0,LoadSize(A4)

	move.l	A0,A3
	addq.l	#2,A0
	add.w	(A0),A0

	moveq	#$7F,D0
.l6
	cmp.l	#$D040D040,(A0)			; add.w D0,D0 * 2
	beq.b	.ok4
	addq.l	#2,A0
	dbf	D0,.l6
	bra.w	.error
.ok4
	addq.l	#4,A0
	cmp.w	#$D040,(A0)			; add.w D0,D0
	bne.b	.l6
	cmp.w	#$41FA,2(A0)			; lea ..(pc),A0
	bne.b	.l6
	addq.l	#4,A0
	move.l	A0,A1
	add.w	(A0),A1				; adres tablicy subsongow

	moveq	#0,D1
.l7
	moveq	#3,D2
.l8
	move.w	(A1)+,D0
	and.w	#$FC00,D0
	tst.w	D0
	bne.b	.not_subsong
	dbf	D2,.l8
	addq.l	#1,D1
	bra.b	.l7
.not_subsong
	subq.l	#1,D1				; last subsong
	bpl.b	.ok5
	moveq	#0,D1
.ok5
	addq.l	#1,D1
	move.l	D1,SubSongs(A4)



	moveq	#$7F,D0
.l9
	cmp.w	#$41FA,(A0)+			; lea ..(pc),A0
	beq.b	.ok6
	dbf	D0,.l9
	bra.w	.error
.ok6
	move.l	A0,A1
	add.w	(A0),A1				; address 1 sample info
	move.l	A1,(A6)+			; SampleInfo1

	lea	12(A3),A0
	add.w	(A0),A0
	moveq	#$7F,D0
.l10
	cmp.l	#$D040D040,(A0)			; add.w D0,D0 * 2
	beq.b	.ok7
	addq.l	#2,A0
	dbf	D0,.l10
	bra.b	.ok7a
.ok7
	addq.l	#4,A0
	cmp.w	#$41FA,(A0)			; lea ..(pc),A0
	bne.b	.l10
	addq.l	#2,A0
	move.w	(A0),D0
	btst	#0,D0
	bne.b	.ok7a
	add.w	(A0),A0				; address 2 sample info
	tst.w	(A0)
	beq.b	.ok8
.ok7a
	sub.l	A0,A0				; or 0 if sample
.ok8
	move.l	A0,(A6)+			; SampleInfo2

	move.l	SampleInfo1(PC),A0
.com1
	move.l	(A0)+,D0
	beq.b	.ok9
	swap	D0
	tst.w	D0
	beq.b	.com1
	subq.l	#4,A0
.ok9
	subq.l	#8,A0
	move.l	A0,D0
	sub.l	SampleInfo1(PC),D0
	lsr.l	#2,D0		; how many samples in first sample info
	move.l	D0,Samples(A4)
	move.l	D0,(A6)+			; SmpIn1SmpInfo

	move.l	SampleInfo2(PC),D0
	beq.b	.one_smp_info
	move.l	D0,A0
.com2
	move.l	(A0)+,D0
	beq.b	.ok10
	swap	D0
	tst.w	D0
	beq.b	.com2
	addq.l	#4,A0
.ok10
	subq.l	#8,A0
	move.l	A0,D0
	sub.l	SampleInfo2(PC),D0
	lsr.l	#2,D0		; how many samples in second sample info
.one_smp_info
	add.l	D0,Samples(A4)
	move.l	D0,(A6)+			; SmpIn2SmpInfo

	move.l	SampleInfo1(PC),A0
	move.l	SmpIn1SmpInfo(PC),D3
	lsl.l	#2,D3
	moveq	#0,D2

	moveq	#0,D0
	moveq	#0,D5
	move.l	A0,A2
	add.l	(A0,D0.W),A2
	move.l	(A2),D1
	move.w	8(A2),D2
.l11
	addq.l	#4,D0

	cmp.l	D0,D3
	beq.b	.ok11

	move.l	A0,A2
	add.l	(A0,D0.W),A2
	move.l	(A2),D4
	cmp.l	D1,D4
	bcs.b	.l11
	cmp.l	D1,D4
	bne.b	.l111
	move.w	8(A2),D5
	cmp.l	D2,D5
	bcs.b	.l11
	bra.b	.l112
.l111
	move.w	8(A2),D5
	moveq	#0,D6
	move.l	(A2),D7
	cmp.l	4(A2),D7
	beq.b	.l112
	move.w	10(A2),D6
.l112
	move.l	D4,D1
	move.l	D5,D2
	bra.b	.l11
.ok11
	move.l	SampleInfo1(PC),A1
	add.l	D1,A1
	add.l	D6,D2
	lsl.l	#1,D2
	add.l	D2,A1
	sub.l	A3,A1
	move.l	A1,Calcsize(A4)

	move.l	SampleInfo2(PC),D0
	beq.b	.ok12
	move.l	D0,A0
	move.l	SmpIn2SmpInfo(PC),D3
	lsl.l	#2,D3
	moveq	#0,D2

	moveq	#0,D0
	move.l	A0,A2
	add.l	(A0,D0.W),A2
	move.l	(A2),D1
	move.w	8(A2),D2
.l12
	addq.l	#4,D0

	cmp.l	D0,D3
	beq.b	.ok13

	move.l	A0,A2
	add.l	(A0,D0.W),A2
	move.l	(A2),D4
	cmp.l	D1,D4
	bcs.b	.l12
	cmp.l	D1,D4
	bne.b	.l113
	move.w	8(A2),D5
	cmp.l	D2,D5
	bcs.b	.l12
	bra.b	.l114
.l113
	move.w	8(A2),D5
	moveq	#0,D6
	move.l	(A2),D7
	cmp.l	4(A2),D7
	beq.b	.l114
	move.w	10(A2),D6
.l114
	move.l	D4,D1
	move.l	D5,D2
	bra.b	.l12
.ok13
	move.l	SampleInfo1(PC),A1
	add.l	D1,A1
	add.l	D6,D2
	lsl.l	#1,D2
	add.l	D2,A1
	sub.l	ModulePtr(PC),A1
	cmp.l	Calcsize(A4),A1
	bcs.b	.ok12
	move.l	A1,Calcsize(A4)
.ok12

; wyliczenie najmniejszego offsetu dla sample info 1 i wyznaczenie smp adr

	move.l	SampleInfo1(PC),A0
	move.l	SmpIn1SmpInfo(PC),D3
	lsl.l	#2,D3
	moveq	#0,D2

	moveq	#0,D0
	move.l	A0,A2
	add.l	(A0,D0.W),A2
	move.l	(A2),D1
	move.w	8(A2),D2
.l14
	addq.l	#4,D0

	cmp.l	D0,D3
	beq.b	.ok14

	move.l	A0,A2
	add.l	(A0,D0.W),A2
	move.l	(A2),D4
	cmp.l	D1,D4
	bcc.b	.l14
	cmp.l	D1,D4
	bne.b	.l15
	move.w	8(A2),D5
	cmp.l	D2,D5
	bcc.b	.l14
	bra.b	.l16
.l15
	move.w	8(A2),D5
.l16
	move.l	D4,D1
	move.w	D5,D2
	bra.b	.l14
.ok14
	move.l	SampleInfo1(PC),A1
	add.l	D1,A1
	move.l	A1,(A6)				;SamplePtr

; wyliczenie najmniejszego offsetu dla sample info 2 i wyznaczenie smp adr

	move.l	SampleInfo2(PC),D0
	beq.b	.s17
	move.l	D0,A0
	move.l	SmpIn2SmpInfo(PC),D3
	lsl.l	#2,D3
	moveq	#0,D2

	moveq	#0,D0
	move.l	A0,A2
	add.l	(A0,D0.w),A2
	move.l	(A2),D1
	move.w	8(A2),D2
.l17
	addq.l	#4,D0

	cmp.l	D0,D3
	beq.b	.ok17

	move.l	A0,A2
	add.l	(A0,D0.W),A2
	move.l	(A2),D4
	cmp.l	D1,D4
	bcc.b	.l17
	cmp.l	D1,D4
	bne.b	.l18
	move.w	8(A2),D5
	cmp.l	D2,D5
	bcc.b	.l17
	bra.b	.l19
.l18
	move.w	8(A2),D5
.l19
	move.l	D4,D1
	move.w	D5,D2
	bra.b	.l17
.ok17
	move.l	SampleInfo1(PC),A1
	add.l	D1,A1
	cmp.l	SamplePtr(PC),A1
	bcc.b	.s17
	move.l	A1,(A6)				; SamplePtr
.s17
	move.l	(A6)+,D0
	sub.l	A3,D0
	move.l	D0,Songsize(A4)
	move.l	Calcsize(A4),D1
	sub.l	D0,D1
	move.l	D1,SamplesSize(A4)

	move.l	A5,(A6)				; Eaglebase

	move.l	A3,A0
.FindLea
	cmp.w	#$4DF9,(A0)+
	bne.b	.FindLea
	move.l	SampleInfo1(PC),A2
	move.l	#$4E714E71,D0
	move.l	#$4E714EB9,D1
.Patch
	cmp.l	#$40E7007C,(A0)
	bne.b	.NoSR1
	move.l	D0,(A0)+
	move.w	D0,(A0)+
	bra.w	.test
.NoSR1
	cmp.w	#$4E73,(A0)
	bne.b	.NoRTE
	addq.w	#2,(A0)+
	bra.w	.test
.NoRTE
	cmp.l	#$248B3568,(A0)
	bne.b	.No1
	cmp.l	#$00080004,4(A0)
	bne.b	.No1
	lea	Patch1(PC),A1
	move.l	D1,(A0)+
	move.l	A1,(A0)+
	bra.b	.test
.No1
	cmp.l	#$35400008,(A0)
	bne.b	.No3
	cmp.l	#$234B001A,4(A0)
	bne.b	.No3
	cmp.w	#$E448,-2(A0)
	bne.b	.NoUp
	move.w	D0,-2(A0)			; more volume power
.NoUp
	lea	Patch2(PC),A1
	move.l	D1,(A0)+
	move.l	A1,(A0)+
	bra.b	.test
.No3
	cmp.l	#$33400008,(A0)
	bne.b	.No4
	cmp.w	#$302B,4(A0)
	bne.b	.No4
	lea	Patch3(PC),A1
	move.l	D1,(A0)+
	lea	New(PC),A3
	move.l	(A0),(A3)
	move.l	A1,(A0)+
	bra.b	.test
.No4
	cmp.l	#$35420008,(A0)
	bne.b	.No5
	lea	Patch4(PC),A1
	move.l	D1,(A0)+
	lea	New2(PC),A3
	move.l	(A0),(A3)
	move.l	A1,(A0)+
	bra.b	.test
.No5
	cmp.l	#$21C80070,(A0)
	bne.b	.No70
	move.l	D0,(A0)+
	bra.b	.test
.No70
	cmp.w	#$46DF,(A0)
	bne.b	.NoSR2
	move.w	D0,(A0)
.NoSR2
	addq.l	#2,A0
.test
	cmp.l	A0,A2
	bne.w	.Patch

	;movea.l	dtg_AudioAlloc(A5),A0
	;jmp	(A0)
	moveq	#0,d0
	rts

.error
	;moveq	#EPR_CorruptModule,D0		; error message
	moveq	#-1,d0
	rts

***************************************************************************
***************************** DTP_EndPlayer *******************************
***************************************************************************

EndPlayer
	;movea.l	dtg_AudioFree(A5),A0
	;jmp	(A0)
		rts

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

	bsr.w	SetIntVector
	
	;move.w	dtg_SndNum(A5),D0
	move	songNumber(pc),d0
	movea.l	ModulePtr(PC),A0
	jsr	(A0)

	lea	Base(PC),A0
	move.l	A1,(A0)+
	move.l	2(A1),(A0)+
	clr.l	(A0)+
	clr.l	(A0)
	move.l	2(A2),D0
	cmp.l	2(A3),D0
	ble.b	Min1
	move.l	2(A3),D0
Min1
	cmp.l	2(A4),D0
	ble.b	Min2
	move.l	2(A4),D0
Min2
	sub.l	2(A1),D0
	beq.b	Again
	bpl.b	LengthOK
	moveq	#0,D0
	move.l	2(A1),A0
CalcLen
	addq.l	#1,D0
	cmp.b	#$FF,(A0)+
	bne.b	CalcLen
LengthOK
	lea	InfoBuffer(PC),A0
	move.l	D0,Length(A0)
	rts
Again
	move.l	2(A2),D0
	sub.l	2(A1),D0
	bra.b	LengthOK

***************************************************************************
***************************** DTP_EndSound ********************************
***************************************************************************

EndSound
	bsr.b	ClearIntVector

	rts
	

	movea.l	ModulePtr(PC),A0
	jmp	14(A0)

***************************************************************************
***************************** DTP_Interrupt *******************************
***************************************************************************

Interrupt
	movem.l	D1-D7/A0-A6,-(A7)
;	lea	StructAdr(PC),A0
;	st	UPS_Enabled(A0)
;	clr.w	UPS_Voice1Per(A0)
;	clr.w	UPS_Voice2Per(A0)
;	clr.w	UPS_Voice3Per(A0)
;	clr.w	UPS_Voice4Per(A0)
;	move.w	#UPSB_Adr!UPSB_Len!UPSB_Per!UPSB_Vol,UPS_Flags(A0)

	movea.l	ModulePtr(PC),A0
	jsr	4(A0)				; play module

	movea.l	ModulePtr(PC),A0
	tst.b	8(A0)
	bne.b	NoEnd
	;move.l	EagleBase(PC),A5
	;move.l	dtg_SongEnd(A5),A1
	;jsr	(A1)

	;move.w	dtg_SndNum(A5),D0
	move	songNumber(pc),d0
	jsr	(A0)				; init module
NoEnd
	;lea	StructAdr(PC),A0
	;clr.w	UPS_Enabled(A0)

	movem.l	(A7)+,D1-D7/A0-A6
	moveq	#0,D0
	rts

SetIntVector
	movea.l	4.W,A6
	lea	StructInt(PC),A1
	moveq	#INTB_AUD0,D0
	jsr	_LVOSetIntVector(A6)		; SetIntVector
	move.l	D0,Channel0
	lea	StructInt(PC),A1
	moveq	#INTB_AUD1,D0
	jsr	_LVOSetIntVector(A6)
	move.l	D0,Channel1
	lea	StructInt(PC),A1
	moveq	#INTB_AUD2,D0
	jsr	_LVOSetIntVector(A6)
	move.l	D0,Channel2
	lea	StructInt(PC),A1
	moveq	#INTB_AUD3,D0
	jsr	_LVOSetIntVector(A6)
	move.l	D0,Channel3
	rts

ClearIntVector
	movea.l	4.W,A6
	movea.l	Channel0(PC),A1
	moveq	#INTB_AUD0,D0
	jsr	_LVOSetIntVector(A6)
	movea.l	Channel1(PC),A1
	moveq	#INTB_AUD1,D0
	jsr	_LVOSetIntVector(A6)
	movea.l	Channel2(PC),A1
	moveq	#INTB_AUD2,D0
	jsr	_LVOSetIntVector(A6)
	movea.l	Channel3(PC),A1
	moveq	#INTB_AUD3,D0
	jmp	_LVOSetIntVector(A6)

Channel0
	dc.l	0
Channel1
	dc.l	0
Channel2
	dc.l	0
Channel3
	dc.l	0
StructInt
	dc.l	0
	dc.l	0
	dc.w	$205
	dc.l	IntName
	dc.l	0
	dc.l	Audio
IntName
	dc.b	'Benn Daglish Audio Interrupt',0,0
	even

Audio
	and.w	#$780,D1
	and.w	$1C(A0),D1
	move.w	D1,$9A(A0)
	move.w	D1,$9C(A0)
	lsr.w	#7,D1
	move.w	D1,$96(A0)
	rts

; Address/length patch for Benn Daglish modules

Patch1
	move.l	A3,(A2)
	move.w	8(A0),4(A2)
	bsr.w	SetTwo
	rts

; Volume/period patch for Benn Daglish (old) modules

Patch2
	bsr.w	SetPer
	bsr.w	ChangeVolume
	bsr.w	SetVol
	move.l	A3,$1A(A1)
	rts

; Volume patch for Benn Daglish modules

Patch3
	move.l	A2,-(SP)
	move.l	A1,A2
	bsr.w	ChangeVolume
	bsr.w	SetVol
	move.l	(SP)+,A2
New
	move.w	8(A3),D0
	rts

; Volume/period patch for Benn Daglish modules

Patch4
	bsr.w	SetPer
	move.l	D0,-(SP)
	move.l	D2,D0
	bsr.w	ChangeVolume
	bsr.w	SetVol
	move.l	(SP)+,D0
New2
	move.w	D3,14(A1)
	rts

bdEnd
