;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000

test	=	0

	incdir	include:
	include	mucro.i
	include	misc/eagleplayer.i
	include	hardware/custom.i
	include	exec/exec_lib.i
	include	exec/exec.i
	include	exec/memory.i

 ifne test
bob
	lea	module,a0
	move.l	#modend-modstart,d0
	jsr	Check2

	* initial song number
	lea	module,a0
	lea	masterVol,a1
	lea	songo,a2
	lea	curpo,a3
	move.l	#modend-modstart,d0
	jsr	init
	bne.w	error

	bsr.b	playLoop
	moveq	#1,d0
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
songo		dc 0
curpo		dc 0

	SECTION	modu,data_c
modstart
;module  incbin	"sys:music/roots/Modules/SonicArranger/Firefox/mega end.sa"
;module  incbin	"sys:music/ModsAnthology/Synth/SonicArr/SA.Nucleogenesis"
;module  incbin	"sys:music/ModsAnthology/Synth/SonicArr/SA.axis-replay.pc"
;module  incbin	"sys:music/MOdland/Sonic Arranger/- unknown/black kangaroo.sa"
module  incbin "sys:music/MOdland/Sonic Arranger/Frank Lautensack/dimos quest - ingame 2.sa"
modend


	*****************************************************
	****   Sonic Arranger replayer for EaglePlayer,  ****
	****	     all adaptions by Wanted Team	 ****
	****      DeliTracker compatible (?) version	 ****
	*****************************************************

 endc
	SECTION	Player_Code,CODE

	jmp	init(pc)
	jmp	play(pc)
	jmp	end(pc)
	jmp	song(pc)
	jmp	forward(pc)
	jmp	backward(pc)

flushCaches
	move.l	4.w,a6
	cmp	#37,LIB_VERSION(a6)
	blo.b	.old
	jsr	_LVOCacheClearU(a6)
.old
	rts

* in:
*   a0 = module address
*   a1 = main volume address
*   a2 = song over address
*   a3 = current position address
*   d0 = module length
* out:
*   d0 = 0, ok, -1, fail
*   d1 = max position
*   d2 = cia timer value
*   d3 = subsong count 
init
	move.l	a0,moduleAddress
	move.l	a1,mainVolumeAddr
	move.l	a2,songOverAddr
	move.l	a3,currentPosAddr
	move.l	d0,moduleLength

	bsr.b	.allocChip
	beq.b	.noMem
	
	move.l	moduleAddress(pc),a0
	move.l	moduleLength(pc),d0
	bsr.w	InitPlayer
	tst.l	d0
	bne.b	.initErr
	bsr.b	flushCaches
	bsr.w	InitSound

	bsr.w	SubSongRange
	move.l	d1,d3
	move	ciaTimerValue(pc),d2
	move.l	InfoBuffer+Length(pc),d1

	moveq	#0,d0
	rts

.noMem
	moveq	#-1,d0
	rts

.initErr
	bsr.b	end
	moveq	#-2,d0
	rts

.allocChip
	move.l	#206*4+4,d0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	lore	Exec,AllocMem
	move.l	d0,chipBuffer
	beq.b	.memErr
	move.l	d0,a0
	move.l 	a0,chip1
	lea	206(a0),a0
	move.l 	a0,chip2
	lea	206(a0),a0
	move.l 	a0,chip3
	lea	206(a0),a0
	move.l 	a0,chip4
	lea	206(a0),a0
	move.l 	a0,emptyWord
.memErr	rts

play
	move.l	mainVolumeAddr(pc),a0
	move	(a0),sonicMasterVol
	bsr.w	Interrupt
	bsr.w	GetPosition
	move.l	currentPosAddr(pc),a0
	move	d0,(a0)
	rts

end	
	move.l chipBuffer(pc),d0 
	beq.b 	.x
	move.l	d0,a1
	clr.l	chipBuffer
	move.l	#206*4+4,d0
	lore 	Exec,FreeMem
.x	rts

* in:
*   d0 = song number
* out:
*   d0 = length in patterns
song
	move	d0,songNumber
	bsr.w	InitSound
	move.l	InfoBuffer+Length(pc),d0
	rts

forward
	bra.b	NextPattern

backward
	bra.b	PrevPattern

chipBuffer		dc.l	0
songNumber		dc.w	0
moduleAddress		dc.l	0
moduleLength		dc.l	0
songOverAddr		dc.l	0
currentPosAddr		dc.l	0
ciaTimerValue		dc.w	1773447/125	* default timer
mainVolumeAddr		dc.l	0

chip1			dc.l 	0
chip2			dc.l 	0
chip3			dc.l 	0
chip4			dc.l 	0
emptyWord		dc.l 	0


;	PLAYERHEADER Tags
;
;	dc.b	'$VER: Sonic Arranger 2.18 player module V1.0 (28 Feb 2009)',0
;	even
;Tags
;	dc.l	DTP_PlayerVersion,1
;	dc.l	EP_PlayerVersion,9
;	dc.l	DTP_RequestDTVersion,DELIVERSION
;	dc.l	DTP_PlayerName,PlayerName
;	dc.l	DTP_Creator,Creator
;	dc.l	DTP_Check2,Check2
;	dc.l	DTP_InitPlayer,InitPlayer
;	dc.l	DTP_Interrupt,Interrupt
;	dc.l	DTP_EndPlayer,EndPlayer
;	dc.l	DTP_InitSound,InitSound
;	dc.l	DTP_EndSound,EndSound
;	dc.l	DTP_Volume,SetVolume
;	dc.l	DTP_Balance,SetBalance
;	dc.l	EP_Voices,SetVoices
;	dc.l	EP_StructInit,StructInit
;	dc.l	DTP_SubSongRange,SubSongRange
;	dc.l	EP_Get_ModuleInfo,GetInfos
;	dc.l	EP_GetPositionNr,GetPosition
;	dc.l	EP_SampleInit,SampleInit
;	dc.l	DTP_NextPatt,NextPattern
;	dc.l	DTP_PrevPatt,PrevPattern
;	dc.l	EP_PatternInit,PatternInit
;	dc.l	EP_Flags,EPB_Volume!EPB_Balance!EPB_ModuleInfo!EPB_Voices!EPB_SampleInfo!EPB_PrevPatt!EPB_NextPatt!EPB_Songend!EPB_Analyzer!EPB_Packable!EPB_Restart
;	dc.l	0

;PlayerName
;	dc.b	'Sonic Arranger',0
;Creator
;	dc.b	'(c) 1991-95 by Carsten Schlote, Branko',10
;	dc.b	'Mikiç & Carsten Herbst, adapted by WT',0
;Prefix	dc.b	'SA.',0
;	even
ModulePtr
	dc.l	0
;EagleBase
;	dc.l	0
SongPtr
	dc.l	0
Timer
	dc.l	0
Max
	dc.w	0
;RightVolume
;	dc.w	64
;LeftVolume
;	dc.w	64
;Voice1
;	dc.w	1
;Voice2
;	dc.w	1
;Voice3
;	dc.w	1
;Voice4
;	dc.w	1
;OldVoice1
;	dc.w	0
;OldVoice2
;	dc.w	0
;OldVoice3
;	dc.w	0
;OldVoice4
;	dc.w	0
;StructAdr;
;	ds.b	UPS_SizeOF

***************************************************************************
****************************** EP_PatternInit *****************************
***************************************************************************

;PATTERNINFO:
;	DS.B	PI_Stripes	; This is the main structure
;
;* Here you store the address of each "stripe" (track) for the current
;* pattern so the PI engine can read the data for each row and send it
;* to the CONVERTNOTE function you supply.  The engine determines what
;* data needs to be converted by looking at the Pattpos and Modulo fields.
;
;STRIPE1	DS.L	1
;STRIPE2	DS.L	1
;STRIPE3	DS.L	1
;STRIPE4	DS.L	1
;
;* More stripes go here in case you have more than 4 channels.
;
;
;* Called at various and sundry times (e.g. StartInt, apparently)
;* Return PatternInfo Structure in A0
;PatternInit
;	lea	PATTERNINFO(PC),A0
;	moveq	#4,D0
;	move.w	D0,PI_Voices(A0)	; Number of stripes (MUST be at least 4)
;	move.l	#CONVERTNOTE,PI_Convert(A0)
;	move.l	D0,PI_Modulo(A0)	; Number of bytes to next row
;	clr.w	PI_Pattpos(A0)		; Current Position in Pattern (from 0)
;	clr.w	PI_Songpos(A0)		; Current Position in Song (from 0)
;	move.w	InfoBuffer+Length+2(PC),PI_MaxSongPos(A0)	; Songlength
;	rts
;
;* Called by the PI engine to get values for a particular row
;CONVERTNOTE:
;
;* The command string is a single character.  It is NOT ASCII, howver.
;* The character mapping starts from value 0 and supports letters from A-Z
;
;* $00 ~ '0'
;* ...
;* $09 ~ '9'
;* $0A ~ 'A'
;* ...
;* $0F ~ 'F'
;* $10 ~ 'G'
;* etc.
;
;	moveq	#0,D0		; Period? Note?
;	moveq	#0,D1		; Sample number
;	moveq	#0,D2		; Command string
;	moveq	#0,D3		; Command argument
;	move.b	(A0)+,D0
;	beq.b	NoNote
;	lea	lbW001716(PC),A1
;	add.w	D0,D0
;	cmp.w	#$DA,D0
;	bcs.b	GetNote
;	moveq	#0,D0
;GetNote
;	move.w	(A1,D0.W),D0
;NoNote
;	move.b	(A0)+,D1
;	move.b	(A0)+,D2
;	and.b	#15,D2
;	move.b	(A0)+,D3
;	rts
;
;PATINFO
;	move.l	A0,-(SP)
;	lea	PATTERNINFO(PC),A0
;	move.w	lbW000618(PC),PI_Speed(A0)	; Speed Value
;	move.w	lbW00061A(PC),PI_Pattlength(A0)	; Length of each stripe in rows
;	move.w	lbW00063E(PC),PI_Pattpos(A0)
;	move.w	lbW000640(PC),PI_Songpos(A0)
;	move.l	(SP)+,A0
;	rts
;
***************************************************************************
******************************* DTP_NextPatt ******************************
***************************************************************************

NextPattern
	move.w	lbW000640(PC),D0
	addq.w	#1,D0
	cmp.w	lbW00061E(PC),D0
	bgt.w	NoChange
	lea	lbW000640(PC),A0
	move.w	D0,(A0)
	bra.b	SetPos

***************************************************************************
******************************* DTP_PrevPatt ******************************
***************************************************************************

PrevPattern
	move.w	lbW000640(PC),D0
	subq.w	#1,D0
	cmp.w	lbW00061C(PC),D0
	bmi.b	NoChange
	ble.b	NoChange
	lea	lbW000640(PC),A0
	move.w	D0,(A0)
SetPos
	lea	lbW00063E(PC),A0
	clr.w	(A0)
	moveq	#0,D0
	move.w	lbW000640(PC),D0
	lsl.l	#4,D0
	move.l	lbL000400(PC),A0
	lea	0(A0,D0.L),A0
	move.l	lbL000404(PC),A1
	lea	lbL00064A(PC),A2
	lea	lbW000642(PC),A3
	lea	lbL00065A(PC),A4
	moveq	#0,D0
	move.w	(A0)+,D0
	asl.l	#2,D0
	lea	(A1,D0.L),A6
	move.l	A6,(A2)+
	move.l	(A6),(A4)+
	move.w	(A0)+,(A3)+
	moveq	#0,D0
	move.w	(A0)+,D0
	asl.l	#2,D0
	lea	(A1,D0.L),A6
	move.l	A6,(A2)+
	move.l	(A6),(A4)+
	move.w	(A0)+,(A3)+
	moveq	#0,D0
	move.w	(A0)+,D0
	asl.l	#2,D0
	lea	(A1,D0.L),A6
	move.l	A6,(A2)+
	move.l	(A6),(A4)+
	move.w	(A0)+,(A3)+
	moveq	#0,D0
	move.w	(A0)+,D0
	asl.l	#2,D0
	lea	(A1,D0.L),A6
	move.l	A6,(A2)
	move.l	(A6),(A4)
	move.w	(A0),(A3)
NoChange
	rts

***************************************************************************
***************************** DTP_SubSongRange ****************************
***************************************************************************

SubSongRange	
	moveq	#0,D0
	move.l	InfoBuffer+SubSongs(PC),D1
	subq.l	#1,D1
	rts

***************************************************************************
******************************* EP_SampleInit *****************************
***************************************************************************

;SampleInit
;	moveq	#EPR_NotEnoughMem,D7
;	lea	EPG_SampleInfoStructure(A5),A3
;	lea	lbL000418(PC),A4
;	move.l	lbL000408(PC),A2
;	move.l	InfoBuffer+Samples(PC),D5
;	add.l	InfoBuffer+SynthSamples(PC),D5
;	subq.l	#1,D5
;Normal
;	jsr	ENPP_AllocSampleStruct(A5)
;	move.l	D0,(A3)
;	beq.b	return
;	move.l	D0,A3
;
;	move.w	#30,EPS_MaxNameLen(A3)
;	lea	122(A2),A1
;	move.l	A1,EPS_SampleName(A3)
;	move.w	#USITY_AMSynth,EPS_Type(A3)
;	tst.w	(A2)
;	bne.b	Synth
;	move.w	2(A2),D1
;	lsl.w	#2,D1
;	move.l	(A4,D1.W),EPS_Adr(A3)		; sample address
;	moveq	#0,D1
;	move.w	4(A2),D1
;	add.l	D1,D1
;	move.l	D1,EPS_Length(A3)		; sample length
;	move.l	#64,EPS_Volume(A3)
;	move.w	#USITY_RAW,EPS_Type(A3)
;;	move.w	#USIB_Playable!USIB_Saveable!USIB_8BIT,EPS_Flags(A3)
;Synth
;	lea	152(A2),A2
;	dbf	D5,Normal
;	moveq	#0,D7
;return
;	move.l	D7,D0
;	rts

***************************************************************************
***************************** EP_GetPositionNr ****************************
***************************************************************************

GetPosition
	moveq	#0,D0
	move.w	lbW000640(PC),D0
	rts

***************************************************************************
***************************** EP_Get_ModuleInfo ***************************
***************************************************************************

;GetInfos
;	lea	InfoBuffer(PC),A0
;	rts

SubSongs	=	4
LoadSize	=	12
CalcSize	=	20
SongSize	=	28
Length		=	36
SamplesSize	=	44
Samples		=	52
SynthSamples	=	60
Special		=	68

InfoBuffer
	dc.l	MI_SubSongs,0		;4
	dc.l	MI_LoadSize,0		;12
	dc.l	MI_Calcsize,0		;20
	dc.l	MI_Songsize,0		;28
	dc.l	MI_Length,0			;36
	dc.l	MI_SamplesSize,0	;44
	dc.l	MI_Samples,0		;52
	dc.l	MI_SynthSamples,0	;60
	dc.l	MI_SpecialInfo,0	;68
	dc.l	MI_MaxLength,1000
	dc.l	MI_MaxSamples,128
	dc.l	MI_MaxSynthSamples,255
;	dc.l	MI_Prefix,Prefix
	dc.l	0

***************************************************************************
******************************* EP_StructInit *****************************
***************************************************************************

;StructInit
;	lea	StructAdr(PC),A0
;	rts
;
***************************************************************************
************************* DTP_Volume, DTP_Balance *************************
***************************************************************************
; Copy Volume and Balance Data to internal buffer

;SetVolume
;	mulu.w	mainVolume(pc),D0
;	lsr.w	#6,D0				; durch 64
;	and.w	#$7F,D0
;	moveq	#3,D1
;	lea	$DFF0A0,A3
;.SetNew
;	move.w	D0,8(A3)
;	lea	16(A3),A3
;	dbf	D1,.SetNew
;	rts
;
SetVol
	move.w	D0,8(A3)
	rts


*------------------------------- Set Vol -------------------------------*

;SetVol
;	move.l	A0,-(A7)
;	lea	StructAdr+UPS_Voice1Vol(PC),A0
;	cmp.l	#$DFF0A0,A3
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice2Vol(PC),A0
;	cmp.l	#$DFF0B0,A3
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice3Vol(PC),A0
;	cmp.l	#$DFF0C0,A3
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice4Vol(PC),A0
;.SetVoice
;	move.w	D0,(A0)
;	move.l	(A7)+,A0
;	rts

*------------------------------- Set Adr -------------------------------*

;SetAdr
;	move.l	A1,-(A7)
;	lea	StructAdr+UPS_Voice1Adr(PC),A1
;	cmp.l	#$DFF0A0,A3
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice2Adr(PC),A1
;	cmp.l	#$DFF0B0,A3
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice3Adr(PC),A1
;	cmp.l	#$DFF0C0,A3
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice4Adr(PC),A1
;.SetVoice
;	move.l	D0,(A1)
;	move.l	(A7)+,A1
;	rts

*------------------------------- Set Len -------------------------------*

;SetLen
;	move.l	A1,-(A7)
;	lea	StructAdr+UPS_Voice1Len(PC),A1
;	cmp.l	#$DFF0A0,A3
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice2Len(PC),A1
;	cmp.l	#$DFF0B0,A3
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice3Len(PC),A1
;	cmp.l	#$DFF0C0,A3
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice4Len(PC),A1
;.SetVoice
;	move.w	D0,(A1)
;	move.l	(A7)+,A1
;	rts

*------------------------------- Set Per -------------------------------*

;SetPer
;	move.l	A1,-(A7)
;	lea	StructAdr+UPS_Voice1Per(PC),A1
;	cmp.l	#$DFF0A0,A3
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice2Per(PC),A1
;	cmp.l	#$DFF0B0,A3
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice3Per(PC),A1
;	cmp.l	#$DFF0C0,A3
;	beq.s	.SetVoice
;	lea	StructAdr+UPS_Voice4Per(PC),A1
;.SetVoice
;	move.w	D3,(A1)
;	move.l	(A7)+,A1
;	rts

***************************************************************************
**************************** EP_Voices ************************************
***************************************************************************

;SetVoices
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
;	rts

***************************************************************************
******************************* DTP_Check2 ********************************
***************************************************************************

Check2
;	movea.l	dtg_ChkData(A5),A0
	move.l	d0,d3
	moveq	#-1,D0

	cmp.l	#'SOAR',(A0)
	bne.b	NoSong
	addq.l	#4,A0
	cmp.l	#'V1.0',(A0)+
	bne.w	Fault
	cmp.l	#'STBL',(A0)
	bne.w	Fault
	bra.w	Found
NoSong
;	move.l	dtg_ChkSize(A5),D3
	cmp.w	#$4EFA,(A0)
	bne.b	NoRepa
	move.w	2(A0),D1
	beq.b	Fault
	bmi.b	Fault
	btst	#0,D1
	bne.b	Fault
	lea	6(A0,D1.W),A1
	cmp.w	#$41FA,(A1)+
	bne.b	Fault
	moveq	#0,D1
	move.w	(A1),D1
	beq.b	Fault
	bmi.b	Fault
	btst	#0,D1
	bne.b	Fault
	add.w	D1,A1
	subq.l	#8,D3
	sub.l	D1,D3
	bmi.b	Fault
	move.l	A1,A0
NoRepa
	move.l	A0,A1
	moveq	#$28,D1
	sub.l	D1,D3
	bmi.b	Fault
	cmp.l	(A1)+,D1
	bne.b	Fault
	moveq	#6,D1
NextLong
	move.l	(A1)+,D2
	beq.b	Fault
	bmi.b	Fault
	btst	#0,D2
	bne.b	Fault
	dbf	D1,NextLong
	sub.l	D2,D3
	bmi.b	Fault
	lea	(A0,D2.L),A1
	move.l	(A1)+,D1
	beq.b	SynthOnly
	move.l	A1,A0
NextSize
	sub.l	(A0),D3
	bmi.b	Fault
	add.l	(A0)+,A1
	addq.l	#4,A1
	subq.l	#1,D1
	bne.b	NextSize
SynthOnly
	moveq	#12,D1
	sub.l	D1,D3
	bmi.b	Fault
	lea	Text(PC),A0
CheckString
	cmpm.b	(A0)+,(A1)+
	bne.b	Fault
	dbeq	D1,CheckString
Found
	moveq	#0,D0
Fault
	rts
Text
	dc.b	'deadbeef'
	dc.l	0

***************************************************************************
***************************** DTP_InitPlayer ******************************
***************************************************************************

InitPlayer
	;moveq	#0,D0
	;movea.l	dtg_GetListData(A5),A0
	;jsr	(A0)


	lea	ModulePtr(PC),A6
	move.l	A0,(A6)+		; module buffer
	;move.l	A5,(A6)+		; EagleBase


	lea	lbL000418(PC),A1
	moveq	#127,D1
Clear2
	clr.l	(A1)+
	dbf	D1,Clear2

	lea	InfoBuffer(PC),A4
	move.l	D0,LoadSize(A4)
	cmp.w	#'SO',(A0)
	bne.w	NoAR
	move.l	D0,D3
	moveq	#16,D1
	sub.l	D1,D0
	add.l	D1,A0
	lea	lbL0003FC(PC),A1
	move.l	A0,(A1)
	move.l	-4(A0),D1
	move.l	D1,SubSongs(A4)
	mulu.w	#12,D1
	sub.l	D1,D0
	bmi.w	TooShort
	add.l	D1,A0
	subq.l	#8,D0
	bmi.w	TooShort
	cmp.l	#'OVTB',(A0)+
	bne.w	InFile
	move.l	(A0)+,D1
	mulu.w	#16,D1
	sub.l	D1,D0
	bmi.w	TooShort
	lea	lbL000400(PC),A1
	move.l	A0,(A1)
	add.l	D1,A0
	subq.l	#8,D0
	bmi.w	TooShort
	cmp.l	#'NTBL',(A0)+
	bne.w	InFile
	move.l	(A0)+,D1
	add.l	D1,D1			; *2
	add.l	D1,D1			; *4
	sub.l	D1,D0
	bmi.w	TooShort
	lea	lbL000404(PC),A1
	move.l	A0,(A1)
	add.l	D1,A0
	subq.l	#8,D0
	bmi.w	TooShort
	cmp.l	#'INST',(A0)+
	bne.w	InFile
	move.l	(A0)+,D1
	lea	Max(PC),A2
	move.w	D1,(A2)
	move.l	D1,D4
	move.l	A0,A2
	moveq	#0,D5
	moveq	#0,D6
NextIn
	tst.w	(A2)
	bne.b	AMS
	addq.l	#1,D6
	bra.b	NoAMS
AMS
	addq.l	#1,D5
NoAMS
	lea	152(A2),A2
	subq.l	#1,D4
	bne.b	NextIn
	move.l	D6,Samples(A4)
	move.l	D5,SynthSamples(A4)
	mulu.w	#152,D1
	sub.l	D1,D0
	bmi.w	TooShort
	lea	lbL000408(PC),A1
	move.l	A0,(A1)
	add.l	D1,A0
	subq.l	#8,D0
	bmi.w	TooShort
	cmp.l	#'SD8B',(A0)+
	bne.w	InFile
	move.l	(A0)+,D1
	beq.b	NoSample
	move.l	D1,D2
	mulu.w	#38,D1
	sub.l	D1,D0
	bmi.w	TooShort
	add.l	D1,A0
	lea	lbL000418(PC),A1
	move.l	D2,D1
	asl.l	#2,D1
	sub.l	D1,D0
	bmi.w	TooShort
	lea	(A0,D1.L),A2
	moveq	#0,D1
NextSamp
	move.l	A2,(A1)+
	add.l	(A0),D1
	add.l	(A0)+,A2
	subq.l	#1,D2
	bne.b	NextSamp
	sub.l	D1,D0
	bmi.w	TooShort
	add.l	D1,A0
NoSample
	move.l	D1,SamplesSize(A4)
	subq.l	#8,D0
	bmi.b	TooShort
	cmp.l	#'SYWT',(A0)+
	bne.b	InFile
	move.l	(A0)+,D1
	mulu.w	#128,D1
	sub.l	D1,D0
	bmi.b	TooShort
	lea	lbL00040C(PC),A1
	move.l	A0,(A1)
	add.l	D1,A0
	subq.l	#8,D0
	bmi.b	TooShort
	cmp.l	#'SYAR',(A0)+
	bne.b	InFile
	move.l	(A0)+,D1
	mulu.w	#128,D1
	sub.l	D1,D0
	bmi.b	TooShort
	lea	lbL000414(PC),A1
	move.l	A0,(A1)
	add.l	D1,A0
	subq.l	#8,D0
	bmi.b	TooShort
	cmp.l	#'SYAF',(A0)+
	bne.b	InFile
	move.l	(A0)+,D1
	mulu.w	#128,D1
	sub.l	D1,D0
	bmi.b	TooShort
	lea	lbL000410(PC),A1
	move.l	A0,(A1)
	add.l	D1,A0
	moveq	#24,D1
	sub.l	D1,D0
	bmi.b	TooShort
	cmp.l	#'EDAT',(A0)
	bne.b	InFile
	sub.l	D0,D3
	move.l	D3,CalcSize(A4)
	sub.l	SamplesSize(A4),D3
	move.l	D3,SongSize(A4)
	clr.l	Special(A4)
	bra.w	Alloc
InFile
	moveq	#EPR_ErrorInFile,D0		; error message
	rts

TooShort
	moveq	#EPR_ModuleTooShort,D0		; error message
	rts

NoAR
	lea	(A0,D0.L),A3
	cmp.w	#$4EFA,(A0)
	bne.b	NoRep
	add.w	2(A0),A0
	addq.l	#8,A0
	add.w	(A0),A0
NoRep
	move.l	A0,(A6)			; SongPtr
	move.l	SongPtr(PC),A0
	move.l	4(A0),D0
	sub.l	(A0),D0
	divu.w	#12,D0
	moveq	#1,D1
	cmp.l	D1,D0
	beq.b	SongOK
	tst.w	60(A0)			; check if stripped version
	bpl.b	SongOK
	move.l	D1,D0	
SongOK
	move.l	D0,SubSongs(A4)

	move.l	16(A0),D0
	move.l	12(A0),D2
	lea	(A0,D2.L),A1
	lea	(A0,D0.L),A2
	moveq	#0,D0
	moveq	#0,D2
NextInfo
	tst.w	(A1)
	bne.b	AM
	addq.l	#1,D2
	bra.b	NoAM
AM
	addq.l	#1,D0
NoAM
	lea	152(A1),A1
	cmp.l	A1,A2
	bne.b	NextInfo
	move.l	D2,Samples(A4)
	move.l	D0,SynthSamples(A4)

	move.l	28(A0),D2
	lea	(A0,D2.L),A1
	moveq	#0,D3
	move.l	(A1)+,D1
	beq.b	Synthia
NextSi
	add.l	(A1)+,D3
	subq.l	#1,D1
	bne.b	NextSi
	add.l	D3,A1
Synthia
	lea	12(A1),A1
	move.l	A1,A2
NextByte
	cmp.l	A1,A3
	blt.w	TooShort
	cmp.b	#$F5,(A1)+
	bne.b	NextByte
	tst.b	(A1)
	bne.b	NextByte
	addq.l	#1,A1
	sub.l	ModulePtr(PC),A1
	move.l	A1,CalcSize(A4)
	move.l	D3,SamplesSize(A4)
	sub.l	D3,A1
	move.l	A1,SongSize(A4)
	move.l	A2,Special(A4)
Notuj
	not.b	(A2)+
	tst.b	(A2)
	bne.b	Notuj
	bsr.b	InitPlay
Alloc
;	movea.l	dtg_AudioAlloc(A5),A0
;	jmp	(A0)
	rts

***************************************************************************
***************************** DTP_EndPlayer *******************************
***************************************************************************

EndPlayer
;	movea.l	dtg_AudioFree(A5),A0
;	jmp	(A0)
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
	;move.w	dtg_SndNum(A5),D0
	move	songNumber(pc),d0
	bsr.w	InitSong
	lea	InfoBuffer(PC),A0
	move.w	lbW00061E(PC),Length+2(A0)
;	lea	PATTERNINFO(PC),A0
;	move.w	lbW000622(PC),D1	; Hz value
;	mulu.w	#125,D1
;	divu.w	#50,D1
;	move.w	D1,PI_BPM(A0)		; Beats Per Minute
;	move.w	lbW000618(PC),PI_Speed(A0)	; Speed Value
;	move.w	lbW00061A(PC),PI_Pattlength(A0)	; Length of each stripe in rows
	bset	#1,$BFE001
	lea	lbW000624(PC),A0
	move.w	#-1,(A0)
	rts

***************************************************************************
***************************** DTP_EndSound ********************************
***************************************************************************

;EndSound
;	lea	$DFF000,A0
;	move.w	#15,$96(A0)
;	moveq	#0,D0
;	move.w	D0,$A8(A0)
;	move.w	D0,$B8(A0)
;	move.w	D0,$C8(A0)
;	move.w	D0,$D8(A0)
;	rts

***************************************************************************
***************************** DTP_Interrupt *******************************
***************************************************************************

;Interrupt
;	movem.l	D1-A6,-(A7)
;	lea	StructAdr(PC),A0
;	st	UPS_Enabled(A0)
;	clr.w	UPS_Voice1Per(A0)
;	clr.w	UPS_Voice2Per(A0)
;	clr.w	UPS_Voice3Per(A0)
;	clr.w	UPS_Voice4Per(A0)
;	move.w	#UPSB_Adr!UPSB_Len!UPSB_Per!UPSB_Vol,UPS_Flags(A0)

;	bsr.w	Play

;	lea	StructAdr(PC),A0
;	clr.w	UPS_Enabled(A0)
;	movem.l	(A7)+,D1-A6
;	moveq	#0,D0
;	rts

SongEnd
	push	a0
	move.l	songOverAddr(pc),a0
	st	(a0)
	pop 	a0
	rts
	;movem.l	A1/A5,-(A7)
	;move.l	EagleBase(PC),A5
	;move.l	dtg_SongEnd(A5),A1
	;jsr	(A1)
	;movem.l	(A7)+,A1/A5
	;rts

***************************************************************************
************************* Sonic Arranger 2.18 player **********************
***************************************************************************

; Player from Sonic Arranger 2.18

;lbL000000
;	JMP	lbC00002C(PC)	; Hardcalculate some pointers

;	JMP	lbC000702(PC)	; Set CIA B Timer B Irq as Irq-Handler

;	JMP	lbC000786(PC)	; Remove Irq-Handler

;	JMP	lbC000822(PC)	; Start song Nummber 'd0.l'

;	JMP	lbC000858(PC)	; Stop song

;	JMP	lbC0018F2(PC)	; Insert SynthEffect ( d0.l = note, d1.l = voice, d2.l = locktime )

;	JMP	lbC000908(PC)	; Interruptroutine, if you want to bypass offset 4 and 8

;lbL00001C
;	dc.w	0		; VolumeLevel 1  ( 0.255)    For Equalizers
;	dc.w	0		; VolumeLevel 2  ( 0.255)
;	dc.w	0		; VolumeLevel 3  ( 0.255)
;	dc.w	0		; VolumeLevel 4  ( 0.255)
;	dc.w	lbW00062C-lbL000000	; OffsetPointer to VoiceControl Flags
;         |    ( Module + OffsetPointer = Addresse des Flagfeldes )
;         |
;         -----> dc.w  VoiceOn0,VoiceOn1,VoiceOn2,VoiceOn3
;
;                 0 = Stimme aus     1 = Stimme ein
;
;	dc.w	$75  		; Replayerversionsnummer (akt. 117)
;lbL000028	dc.w	0	; SyncValue      ( 0..255 )
;	dc.w	lbW000626-lbL000000	; Offsetpointer to MasterVolume.w   ( 0..64  )
;         |	( Module + OffsetPointer = Addresse des Wortes )
;         |
;         -----> dc.w (0..64)

InitPlay
;lbC00002C	MOVEM.L	D0-D7/A0-A6,-(SP)
;	LEA	*+$1950(PC),A0			; song ptr
	LEA	lbL0003FC(PC),A1
	MOVE.L	(A0),D0
	LEA	0(A0,D0.L),A2
	MOVE.L	A2,(A1)
	LEA	lbL000400(PC),A1
	MOVE.L	4(A0),D0
	LEA	0(A0,D0.L),A2
	MOVE.L	A2,(A1)
	LEA	lbL000404(PC),A1
	MOVE.L	8(A0),D0
	LEA	0(A0,D0.L),A2
	MOVE.L	A2,(A1)
	LEA	lbL000408(PC),A1
	MOVE.L	12(A0),D0
	LEA	0(A0,D0.L),A2
	MOVE.L	A2,(A1)

	move.l	A2,D1

	LEA	lbL00040C(PC),A1
	MOVE.L	$10(A0),D0
	LEA	0(A0,D0.L),A2
	MOVE.L	A2,(A1)

	sub.l	D1,A2
	move.l	A2,D1
	divu.w	#152,D1
	lea	Max(PC),A2
	move.w	D1,(A2)

	LEA	lbL000414(PC),A1
	MOVE.L	$14(A0),D0
	LEA	0(A0,D0.L),A2
	MOVE.L	A2,(A1)
	LEA	lbL000410(PC),A1
	MOVE.L	$18(A0),D0
	LEA	0(A0,D0.L),A2
	MOVE.L	A2,(A1)
	LEA	lbL000418(PC),A1
	MOVE.L	$1C(A0),D0
	LEA	0(A0,D0.L),A0
	MOVE.L	(A0)+,D0
	BEQ.S	lbC0000B4
	MOVE.L	D0,D1
	ASL.L	#2,D1
	LEA	0(A0,D1.L),A2
lbC0000AC	MOVE.L	A2,(A1)+
	ADDA.L	(A0)+,A2
	SUBQ.L	#1,D0
	BNE.S	lbC0000AC
lbC0000B4
;	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

lbL0003FC	dc.l	0
lbL000400	dc.l	0
lbL000404	dc.l	0
lbL000408	dc.l	0
lbL00040C	dc.l	0
lbL000410	dc.l	0
lbL000414	dc.l	0
lbL000418	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
lbW000618	dc.w	0
lbW00061A	dc.w	0
lbW00061C	dc.w	0
lbW00061E	dc.w	0
lbW000620	dc.w	0
lbW000622	dc.w	0
lbW000624	dc.w	0
sonicMasterVol
lbW000626	dc.w	$3F
lbB000628	dc.b	0
lbB000629	dc.b	0
lbB00062A	dc.b	0
lbB00062B	dc.b	0
lbW00062C	dc.w	1
lbW00062E	dc.w	1
lbW000630	dc.w	1
lbW000632	dc.w	1
lbW000634	dc.w	0
lbW000636	dc.w	0
lbW000638	dc.w	0
lbW00063A	dc.w	0
lbW00063C	dc.w	0
lbW00063E	dc.w	0
lbW000640	dc.w	0
lbW000642	dc.w	0
lbW000644	dc.w	0
lbW000646	dc.w	0
lbW000648	dc.w	0
lbL00064A	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
lbL00065A	dc.l	0
	dc.l	0
	dc.l	0
	dc.l	0
lbW00066A	dc.w	0

InitSong
lbC00066C	LEA	$DFF000,A0
	MOVE.W	#15,$96(A0)
;	MOVE.W	#$FF,$9E(A0)
;	MOVE.W	#$780,$9A(A0)
;	MOVE.W	#$780,$9C(A0)
	BSR.B	lbC000804
	MOVEA.L	lbL0003FC(PC),A0
	MULU.W	#12,D0
	ADDA.L	D0,A0
	LEA	lbW000618(PC),A1
	* boom
	MOVEQ	#11,D1
lbC00069E	MOVE.B	(A0)+,(A1)+
	DBRA	D1,lbC00069E
	LEA	lbW000640(PC),A0
	MOVE.W	lbW00061C(PC),D0
	SUBQ.W	#1,D0
	MOVE.W	D0,(A0)
	LEA	lbW00063C(PC),A0
	MOVE.W	lbW000618(PC),(A0)
	LEA	lbW00063E(PC),A0
	MOVE.W	lbW00061A(PC),(A0)
	LEA	lbW000626(PC),A0
;	MOVE.W	#$3F,(A0)		; why not 64?

	move.w	#64,(A0)		; set master volume

	BSR.B	lbC0007D6		; set timer
	RTS

;lbW0006CE	dc.w	0
;lbL0006D0	dc.l	0
;lbL0006D4	dc.l	0
;	dc.l	0
;	dc.l	0
;	dc.l	0
;	dc.l	0
;	dc.w	0
;musicirq.MSG	dc.b	'musicirq',0
;ciabresource.MSG	dc.b	'ciab.resource',0,0

;lbC000702	MOVE.L	A6,-(SP)
;	LEA	ciabresource.MSG(PC),A1
;	MOVEA.L	4,A6
;	JSR	-$1F2(A6)
;	LEA	lbL0006D0(PC),A1
;	MOVE.L	D0,(A1)
;	BNE.S	lbC00071C
;	MOVEQ	#0,D0
;	BRA.S	lbC000756

;lbC00071C	LEA	lbL0006D4(PC),A1
;	MOVE.B	#2,8(A1)
;	CLR.B	9(A1)
;	LEA	musicirq.MSG(PC),A0
;	MOVE.L	A0,10(A1)
;	CLR.L	14(A1)
;	LEA	lbC0008D2(PC),A0
;	MOVE.L	A0,$12(A1)
;	MOVEA.L	lbL0006D0(PC),A6
;	MOVEQ	#1,D0
;	LEA	lbL0006D4(PC),A1
;	JSR	-6(A6)
;	TST.L	D0
;	BEQ.S	lbC000754
;	MOVEQ	#0,D0
;	BRA.S	lbC000756

;lbC000754	MOVEQ	#1,D0
;lbC000756	LEA	lbW0006CE(PC),A0
;	MOVE.W	D0,(A0)
;	TST.W	D0
;	BEQ.S	lbC00077E
;	MOVEQ	#0,D0
;	BSR.L	lbC00066C
;	LEA	lbW000640(PC),A0
;	ADDQ.W	#1,(A0)
;	LEA	$BFD000,A0
;	MOVE.B	#$11,$F00(A0)
;	MOVE.B	#$82,$D00(A0)
;lbC00077E	MOVE.W	lbW0006CE(PC),D0
;	MOVEA.L	(SP)+,A6
;	RTS

;lbC000786	MOVE.L	A6,-(SP)
;	LEA	lbW0006CE(PC),A0
;	TST.W	(A0)
;	BEQ.S	lbC0007B8
;	MOVEA.L	4,A6
;	JSR	-$78(A6)
;	MOVEA.L	lbL0006D0(PC),A6
;	MOVEQ	#1,D0
;	LEA	lbL0006D4(PC),A1
;	JSR	-12(A6)
;	MOVEA.L	4,A6
;	JSR	-$7E(A6)
;	BSR.S	lbC000804
;	MOVE.W	#15,$DFF096
;lbC0007B8	MOVEA.L	(SP)+,A6
;	RTS

;lbC0007BC	LEA	$BFD000,A0
;	MOVE.B	$700(A0),D0
;	MOVE.B	$600(A0),D1
;	CMP.B	$700(A0),D0
;	BNE.S	lbC0007BC
;	LSL.W	#8,D0
;	MOVE.B	D1,D0
;	RTS

lbC0007D6
;	MOVE.L	D1,-(SP)
;	MOVE.L	#$AD303,D0		; only PAL clock

	move.l	Timer(PC),D0
	bne.b	TimerSet
	;move.w	dtg_Timer(A5),D0
	move	ciaTimerValue(pc),d0
	mulu.w	#50,D0			; now PAL or NTSC clock
	lea	Timer(PC),A0
	move.l	D0,(A0)
TimerSet
	MOVE.W	lbW000622(PC),D1	; Hz value
	BEQ.S	lbC0007EC
	DIVU.W	D1,D0

	move.w	D0,ciaTimerValue

;	LEA	$BFD000,A0		; bug, too late must be before branch
lbC0007EC
;	CLR.B	$F00(A0)
;	MOVE.B	D0,$600(A0)
;	LSR.W	#8,D0
;	MOVE.B	D0,$700(A0)
;	MOVE.B	#$11,$F00(A0)

;	MOVE.L	(SP)+,D1
	RTS

lbC000804	move.l	chip1(pc),A0			; was PC

	move.l	A0,A1
	move.w	#205,D1
Clear1
	clr.l	(A1)+
	dbf	D1,Clear1

	lea	lbB000628(PC),A1
	clr.l	(A1)

	BSET	#0,$B5(A0)
	BSET	#0,$183(A0)
	BSET	#0,$251(A0)
	BSET	#0,$31F(A0)
	RTS

;lbC000822	BSET	#1,$BFE001
;	MOVE.L	A6,-(SP)
;	LEA	lbW000624(PC),A6
;	CLR.W	(A6)
;	BSR.L	lbC00066C
;	MOVE.W	#$FFFF,(A6)
;	MOVEA.L	(SP)+,A6
;	RTS

;	LEA	lbW000624(PC),A1
;	CLR.W	(A1)
;	LEA	lbW00063E(PC),A0
;	MOVE.W	lbW00061A(PC),(A0)
;	LEA	lbW000640(PC),A0
;	MOVE.W	D0,(A0)
;	MOVE.W	#1,(A1)
;	RTS

;lbC000858	BCLR	#1,$BFE001
;	LEA	lbW000624(PC),A0
;	CLR.W	(A0)
;	LEA	lbB000628(PC),A0
;	CLR.L	(A0)
;	BSR.S	lbC000804
;	RTS

lbC000870	MOVEA.L	$8A(A4),A5
	TST.W	6(A5)
	BNE.S	lbC00087C
	RTS

lbC00087C	CMPI.W	#1,6(A5)
	BNE.S	lbC000892
lbC000884	move.l	emptyWord(pc),A0		; was PC
	MOVE.L	A0,(A3)				; address
	MOVE.W	#1,4(A3)			; length
	RTS

lbC000892	MOVE.L	$BC(A4),D2
	BEQ.S	lbC000884
	MOVEQ	#0,D0
	MOVEM.W	4(A5),D0/D1
	ADD.L	D0,D0
	ADD.L	D0,D2
	MOVE.L	D2,(A3)				; address
	MOVE.W	D1,4(A3)			; length
	RTS

;lbW0008AC	dc.w	0
;	dc.w	0
;	dc.w	0
;	dc.w	0
;	dc.w	0
;	dc.w	0
;	dc.w	0
;	dc.w	0
;	dc.w	0
;	dc.w	0
;	dc.w	0
;music_soft_ir.MSG	dc.b	'music_soft_irq',0,0

;lbC0008D2	MOVEM.L	D0-D7/A0-A6,-(SP)
;	LEA	lbW0008AC(PC),A1
;	MOVE.B	#2,8(A1)
;	CLR.B	9(A1)
;	LEA	music_soft_ir.MSG(PC),A0
;	MOVE.L	A0,10(A1)
;	CLR.L	14(A1)
;	LEA	lbC000908(PC),A0
;	MOVE.L	A0,$12(A1)
;	MOVEA.L	4,A6
;	JSR	-$B4(A6)
;	MOVEM.L	(SP)+,D0-D7/A0-A6
;	MOVEQ	#0,D0
;	RTS

Interrupt
Play
;lbC000908	MOVEM.L	D0-D7/A0-A6,-(SP)
	LEA	lbB000628(PC),A6
	MOVE.L	(A6),D0
	BEQ.S	lbC000964
	TST.B	(A6)
	BEQ.S	lbC000926
	LEA	$DFF0A0,A3
	move.l	chip1(pc),A4			; was PC
	BSR.B	lbC000870
lbC000926	TST.B	1(A6)
	BEQ.S	lbC00093A
	LEA	$DFF0B0,A3
	move.l	chip2(pc),A4			; was PC
	BSR.B	lbC000870
lbC00093A	TST.B	2(A6)
	BEQ.S	lbC00094E
	LEA	$DFF0C0,A3
	move.l	chip3(pc),A4			; was PC
	BSR.B	lbC000870
lbC00094E	TST.B	3(A6)
	BEQ.S	lbC000962
	LEA	$DFF0D0,A3
	move.l	chip4(pc),A4			; was PC
	BSR.W	lbC000870
lbC000962	CLR.L	(A6)
lbC000964	LEA	lbW00063C(PC),A0
	ADDQ.W	#1,(A0)
	MOVE.W	(A0),D0
	CMP.W	lbW000618(PC),D0
	BLT.S	lbC00097C
	CLR.W	(A0)
	MOVE.W	lbW000624(PC),D0
	BEQ.S	lbC00097C
	BSR.S	lbC000998
lbC00097C	BSR.W	lbC000E62
	LEA	lbW00066A(PC),A0
	TST.W	(A0)
	BEQ.S	lbC000990
	MOVE.W	(A0),$DFF096
	CLR.W	(A0)
lbC000990
;	MOVEM.L	(SP)+,D0-D7/A0-A6
;	MOVEQ	#0,D0
	RTS

lbC000998	LEA	lbW00063E(PC),A0
	ADDQ.W	#1,(A0)
	MOVE.W	lbW00061A(PC),D0
	CMP.W	(A0),D0
	BGT.W	lbC000A26
	CLR.W	(A0)
	LEA	lbW000624(PC),A1
	TST.W	(A1)
	BGT.S	lbC0009C4
	LEA	lbW000640(PC),A0
	ADDQ.W	#1,(A0)
	MOVE.W	lbW00061E(PC),D0
	CMP.W	(A0),D0
	BGE.S	lbC0009C4
	MOVE.W	lbW000620(PC),(A0)

	bsr.w	SongEnd

lbC0009C4	MOVEQ	#0,D0
	MOVE.W	lbW000640(PC),D0
	LSL.L	#4,D0
	MOVEA.L	lbL000400(PC),A0
	LEA	0(A0,D0.L),A0
	MOVEA.L	lbL000404(PC),A1
	LEA	lbL00064A(PC),A2
	LEA	lbW000642(PC),A3
	LEA	lbL00065A(PC),A4
	MOVEQ	#0,D0
	MOVE.W	(A0)+,D0
	ASL.L	#2,D0

;	move.l	A5,-(SP)
;	lea	PATTERNINFO(PC),A5

	LEA	0(A1,D0.L),A6
	MOVE.L	A6,(A2)+

;	move.l	A6,PI_Stripes(A5)	; STRIPE1

	MOVE.L	(A6),(A4)+
	MOVE.W	(A0)+,(A3)+
	MOVEQ	#0,D0
	MOVE.W	(A0)+,D0
	ASL.L	#2,D0
	LEA	0(A1,D0.L),A6
	MOVE.L	A6,(A2)+

;	move.l	A6,PI_Stripes+4(A5)	; STRIPE2

	MOVE.L	(A6),(A4)+
	MOVE.W	(A0)+,(A3)+
	MOVEQ	#0,D0
	MOVE.W	(A0)+,D0
	ASL.L	#2,D0
	LEA	0(A1,D0.L),A6
	MOVE.L	A6,(A2)+

;	move.l	A6,PI_Stripes+8(A5)	; STRIPE3

	MOVE.L	(A6),(A4)+
	MOVE.W	(A0)+,(A3)+
	MOVEQ	#0,D0
	MOVE.W	(A0)+,D0
	ASL.L	#2,D0
	LEA	0(A1,D0.L),A6
	MOVE.L	A6,(A2)+

;	move.l	A6,PI_Stripes+12(A5)	; STRIPE4
;	move.l	(SP)+,A5

	MOVE.L	(A6),(A4)+
	MOVE.W	(A0)+,(A3)+
	BRA.S	lbC000A4C

lbC000A26	LEA	lbL00064A(PC),A0
	LEA	lbL00065A(PC),A1
	ADDQ.L	#4,(A0)
	ADDQ.L	#4,4(A0)
	ADDQ.L	#4,8(A0)
	ADDQ.L	#4,12(A0)
	MOVEA.L	(A0)+,A2
	MOVE.L	(A2)+,(A1)+
	MOVEA.L	(A0)+,A2
	MOVE.L	(A2)+,(A1)+
	MOVEA.L	(A0)+,A2
	MOVE.L	(A2)+,(A1)+
	MOVEA.L	(A0)+,A2
	MOVE.L	(A2)+,(A1)+
lbC000A4C

;	bsr.w	PATINFO

	LEA	lbL00065A(PC),A0
	MOVE.L	A0,-(SP)
	MOVEQ	#0,D5
	MOVE.W	lbW00062C(PC),D0
	BEQ.S	lbC000A82
	LEA	lbW000634(PC),A0
	TST.W	(A0)
	BEQ.S	lbC000A66
	SUBQ.W	#1,(A0)
	BRA.S	lbC000A82

lbC000A66	MOVEA.L	(SP),A0
	MOVE.L	(A0),D7
	MOVE.W	lbW000642(PC),D6
	MOVEQ	#1,D2
	LEA	lbB000628(PC),A2
	LEA	$DFF0A0,A3
	move.l	chip1(pc),A4			; was PC
	BSR.W	lbC000C60
lbC000A82	MOVE.W	lbW00062E(PC),D0
	BEQ.S	lbC000AB2
	LEA	lbW000636(PC),A0
	TST.W	(A0)
	BEQ.S	lbC000A94
	SUBQ.W	#1,(A0)
	BRA.S	lbC000AB2

lbC000A94	MOVEA.L	(SP),A0
	MOVE.L	4(A0),D7
	MOVE.W	lbW000644(PC),D6
	MOVEQ	#2,D2
	LEA	lbB000629(PC),A2
	LEA	$DFF0B0,A3
	move.l	chip2(pc),A4			; was PC
	BSR.W	lbC000C60
lbC000AB2	MOVE.W	lbW000630(PC),D0
	BEQ.S	lbC000AE2
	LEA	lbW000638(PC),A0
	TST.W	(A0)
	BEQ.S	lbC000AC4
	SUBQ.W	#1,(A0)
	BRA.S	lbC000AE2

lbC000AC4	MOVEA.L	(SP),A0
	MOVE.L	8(A0),D7
	MOVE.W	lbW000646(PC),D6
	MOVEQ	#4,D2
	LEA	lbB00062A(PC),A2
	LEA	$DFF0C0,A3
	move.l	chip3(pc),A4			; was PC
	BSR.W	lbC000C60
lbC000AE2	MOVE.W	lbW000632(PC),D0
	BEQ.S	lbC000B12
	LEA	lbW00063A(PC),A0
	TST.W	(A0)
	BEQ.S	lbC000AF4
	SUBQ.W	#1,(A0)
	BRA.S	lbC000B12

lbC000AF4	MOVEA.L	(SP),A0
	MOVE.L	12(A0),D7
	MOVE.W	lbW000648(PC),D6
	MOVEQ	#8,D2
	LEA	lbB00062B(PC),A2
	LEA	$DFF0D0,A3
	move.l	chip4(pc),A4			; was PC
	BSR.W	lbC000C60
lbC000B12	ADDQ.L	#4,SP
	OR.W	#$8000,D5
	LEA	lbW00066A(PC),A6
	MOVE.W	D5,(A6)
;	LEA	chip1(PC),A4
;	LEA	lbL00001C(PC),A1
;	MOVE.B	$B3(A4),1(A1)
;	MOVE.B	$181(A4),3(A1)
;	MOVE.B	$24F(A4),5(A1)
;	MOVE.B	$31D(A4),7(A1)
	RTS

lbW000B40	dc.w	lbC000B88-lbC000B86
	dc.w	lbC000B8A-lbC000B86
	dc.w	lbC000B90-lbC000B86
	dc.w	lbC000B88-lbC000B86
	dc.w	lbC000B96-lbC000B86
	dc.w	lbC000BBE-lbC000B86
	dc.w	lbC000BC6-lbC000B86
	dc.w	lbC000BD2-lbC000B86
	dc.w	lbC000BD8-lbC000B86
	dc.w	lbC000BDE-lbC000B86
	dc.w	lbC000BF0-lbC000B86
	dc.w	lbC000BF6-lbC000B86
	dc.w	lbC000C08-lbC000B86
	dc.w	lbC000C28-lbC000B86
	dc.w	lbC000C32-lbC000B86
	dc.w	lbC000C4A-lbC000B86

lbC000B60	CLR.W	$86(A4)
	CLR.W	$90(A4)
	MOVE.W	D7,D0
	AND.L	#$F00,D0
	LSR.L	#7,D0
	LEA	lbW000B40(PC),A0
	MOVE.W	0(A0,D0.W),D0
	LEA	lbC000B86(PC,D0.W),A0
	MOVEQ	#0,D1
	MOVE.B	D7,D0
	MOVE.B	D7,D1
	EXT.W	D0
lbC000B86	JMP	(A0)

lbC000B88	RTS

lbC000B8A	MOVE.W	D0,$86(A4)
	RTS

lbC000B90	MOVE.W	D1,$9E(A4)
	RTS

lbC000B96	CLR.W	$94(A4)
	MOVE.W	D1,D0
	AND.W	#$F0,D0
	ASR.W	#3,D0
	MOVE.W	D0,$96(A4)
	MOVE.B	D1,D0
	AND.L	#15,D0
	ASL.L	#4,D0
	NEG.L	D0
	ADD.L	#$A0,D0
	MOVE.W	D0,$98(A4)
	RTS

lbC000BBE
;	LEA	lbL000028(PC),A0
;	MOVE.W	D1,(A0)				; sync value
	RTS

lbC000BC6	LEA	lbW000626(PC),A0

	cmp.w	#64,D1
	beq.b	MaxVol

	AND.W	#$3F,D1
MaxVol
	MOVE.W	D1,(A0)
	RTS

lbC000BD2	MOVE.W	D1,$9A(A4)
	RTS

lbC000BD8	CLR.W	$9A(A4)
	RTS

lbC000BDE	TST.W	D1
	BLE.S	lbC000B88
	CMP.W	#$40,D1
	BHI.S	lbC000B88
	LEA	lbW00061A(PC),A6
	MOVE.W	D1,(A6)
	RTS

lbC000BF0	MOVE.W	D0,$90(A4)
	RTS

lbC000BF6	LEA	lbW000640(PC),A6
	SUBQ.W	#1,D1
	MOVE.W	D1,(A6)
	LEA	lbW00063E(PC),A6
	MOVE.W	lbW00061A(PC),(A6)
	RTS

lbC000C08	CMP.W	#$40,D1
	BLS.S	lbC000C12
	MOVE.W	#$40,D1
lbC000C12	MOVE.W	D1,$8E(A4)
	MOVE.W	lbW000626(PC),D0
	MULU.W	D0,D1
	ASR.L	#6,D1
	ADD.W	D1,D1
	ADD.W	D1,D1
	MOVE.W	D1,$B2(A4)
	RTS

lbC000C28	LEA	lbW00063E(PC),A6
	MOVE.W	lbW00061A(PC),(A6)
	RTS

lbC000C32	TST.B	D0
	BNE.S	lbC000C40
	BCLR	#1,$BFE001
	RTS

lbC000C40	BSET	#1,$BFE001
	RTS

lbC000C4A	TST.B	D1
	BLE.W	lbC000B88
	CMP.B	#$10,D1
	BGT.W	lbC000B88
	LEA	lbW000618(PC),A6
	MOVE.W	D1,(A6)
	RTS

lbC000C60	MOVE.L	D7,D3
	ROL.L	#8,D3
	AND.L	#$FF,D3
	MOVE.L	D7,D4
	SWAP	D4
	AND.L	#$FF,D4
	TST.B	D3
	BNE.S	lbC000C86
	TST.B	D4
	BEQ.W	lbC000D16
	BSR.W	lbC000DAE
	BRA.W	lbC000D16

lbC000C86	CMP.B	#$80,D3
	BEQ.W	lbC000D16
	CMP.B	#$7F,D3
	BNE.S	lbC000C9A
	BSR.W	lbC000E3C
	BRA.w	lbC000D16

lbC000C9A	MOVE.W	D7,D0
	MOVEQ	#12,D1
	LSR.L	D1,D0
	MOVEQ	#12,D1
	AND.L	D1,D0
	BTST	#2,D0
	BNE.S	lbC000CB0
	MOVE.B	D6,D1
	EXT.W	D1
	ADD.W	D1,D3
lbC000CB0	TST.W	D4
	BEQ.S	lbC000CC2
	BTST	#3,D0
	BNE.S	lbC000CC2
	MOVE.W	D6,D1
	ROR.W	#8,D1
	EXT.W	D1
	ADD.W	D1,D4
lbC000CC2	AND.W	#$FF,D4
	MOVE.W	$80(A4),$82(A4)
	MOVE.W	D3,$80(A4)
	TST.W	$82(A4)
	BNE.S	lbC000CDA
	MOVE.W	D3,$82(A4)
lbC000CDA	TST.W	$BA(A4)
	BNE.S	lbC000CF2
;	MOVE.W	D2,$DFF096
;	MOVE.W	#1,4(A3)		; length
;	MOVE.W	#$72,6(A3)		; period buggy? 

	lea	$DFF000,A5		; load CustomBase
	move.b	vhposr(A5),D0
.WaitLine1
	cmp.b	vhposr(A5),D0		; sync routine to start at linestart
	beq.s	.WaitLine1
.WaitDMA1
	cmp.b	#$16,vhposr+1(A5)	; wait til after Audio DMA slots
	bcs.s	.WaitDMA1

	move.w	#1,6(A3)		; max speed

	move.w	dmaconr(A5),D0		; get active channels
	and.w	D2,D0
	move.w	D0,D1
	lsl.w	#7,D0
	move.w	D0,intreq(A5)		; clear requests
	move.w	D1,dmacon(A5)		; stop channels
.WaitStop
	move.w	intreqr(A5),D1		; wait until all channels are stopped
	and.w	D0,D1
	cmp.w	D0,D1
	bne.s	.WaitStop
.Skip

lbC000CF2	TST.W	D4
	BNE.S	lbC000D06
	MOVE.L	$8A(A4),D4
	BEQ.W	lbC000E3C
	MOVEA.L	D4,A5
	BSR.W	lbC000DF0
	BRA.S	lbC000D0A

lbC000D06	BSR.W	lbC000DAE
lbC000D0A	MOVE.W	(A5),$BA(A4)
	BNE.S	lbC000D14
	BSR.S	lbC000D1C
	BRA.S	lbC000D16

lbC000D14	BSR.S	lbC000D6C
lbC000D16	BSR.W	lbC000B60
	RTS

lbC000D1C	LEA	lbL000418(PC),A0
	MOVEQ	#0,D0
	MOVE.W	2(A5),D0
	ADD.W	D0,D0
	ADD.W	D0,D0
	MOVE.L	0(A0,D0.W),D0
	BNE.S	lbC000D3E
	BSET	#0,$B5(A4)
	BSR.W	lbC000E3C
	SF	(A2)
	RTS

lbC000D3E	MOVE.L	D0,(A3)			; address

	;bsr.w	SetAdr

	MOVE.L	D0,$BC(A4)
	MOVEQ	#0,D1
	MOVE.W	4(A5),D1
	MOVEQ	#0,D0
	CMPI.W	#1,6(A5)
	BEQ.S	lbC000D58
	MOVE.W	6(A5),D0
lbC000D58	ADD.L	D1,D0
	MOVE.W	D0,4(A3)			; length

	;bsr.w	SetLen

	MOVE.W	D0,$B8(A4)
	OR.W	D2,D5
	MOVE.W	D2,$B6(A4)
	ST	(A2)
	RTS

lbC000D6C	MOVEA.L	lbL00040C(PC),A0
	MOVEQ	#0,D0
	MOVE.W	2(A5),D0
	ASL.L	#7,D0
	LEA	0(A0,D0.L),A0
	MOVE.L	A0,$BC(A4)
	CLR.L	$C0(A4)
	LEA	(A4),A1
	MOVE.L	A1,(A3)				; address

	move.l	A1,D0
	;bsr.w	SetAdr

	MOVE.W	4(A5),D0
	MOVE.W	D0,4(A3)			; length

	;bsr.w	SetLen

	MOVE.W	D0,$B8(A4)
	SUBQ.W	#1,D0
	ASR.W	#3,D0
lbC000D98	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	MOVE.L	(A0)+,(A1)+
	DBRA	D0,lbC000D98
	OR.W	D2,D5
	MOVE.W	D2,$B6(A4)
	SF	(A2)
	RTS

lbC000DAE	MOVEA.L	lbL000408(PC),A5
	AND.L	#$FF,D4
	MOVE.W	D4,$88(A4)

	move.w	Max(PC),D0
	cmp.w	D4,D0
	bcc.b	InRange
	move.w	D0,D4
InRange
	SUBQ.L	#1,D4
	MULU.W	#$98,D4
	LEA	0(A5,D4.L),A5
	MOVE.L	A5,$8A(A4)
	MOVE.W	$10(A5),$8E(A4)
	MOVE.W	$14(A5),$9A(A4)
	CLR.W	$9C(A4)
	CLR.W	$92(A4)
	MOVE.W	$16(A5),$94(A4)
	MOVE.W	$18(A5),$96(A4)
	MOVE.W	$1A(A5),$98(A4)
lbC000DF0	MOVE.W	$12(A5),D0
	EXT.W	D0
	MOVE.W	D0,$84(A4)
	MOVE.W	$26(A5),$A2(A4)
	CLR.L	$9E(A4)
	MOVE.W	$1E(A5),$A6(A4)
	CLR.W	$A4(A4)
	MOVE.W	$44(A5),$A8(A4)
	CLR.W	$AA(A4)
	MOVE.W	$48(A5),$AC(A4)
	CLR.L	$AE(A4)
	MOVE.W	$8E(A4),D0
	MOVE.W	lbW000626(PC),D1
	MULU.W	D1,D0
	ASR.L	#6,D0
	ADD.W	D0,D0
	ADD.W	D0,D0
	MOVE.W	D0,$B2(A4)
	CLR.W	$B4(A4)
	RTS

lbC000E3C	MOVEQ	#0,D0
	MOVE.W	D0,8(A3)			; volume
	move.l	emptyWord(pc),A0			; was PC
;	MOVE.W	A0,(A3)				; bug !!!

	move.l	A0,(A3)				; address

	MOVE.W	#1,4(A3)			; length
	MOVE.W	D0,$8E(A4)
	MOVE.W	D0,$B2(A4)
	MOVE.W	D0,$88(A4)
;	MOVE.W	D0,$8A(A4)			; bug !!!

	move.l	D0,$8A(A4)

	SF	(A2)
	RTS

lbC000E62	LEA	lbL00065A(PC),A0
	MOVE.L	A0,-(SP)
	MOVE.L	(A0),D7
	move.l	chip1(pc),A4			; was PC
	LEA	$DFF0A0,A3
	BSR.S	lbC000EB0
	MOVEA.L	(SP),A0
	MOVE.L	4(A0),D7
	move.l	chip2(pc),A4			; was PC
	LEA	$DFF0B0,A3
	BSR.S	lbC000EB0
	MOVEA.L	(SP),A0
	MOVE.L	8(A0),D7
	move.l	chip3(pc),A4			; was PC
	LEA	$DFF0C0,A3
	BSR.S	lbC000EB0
	MOVEA.L	(SP),A0
	MOVE.L	12(A0),D7
	move.l	chip4(pc),A4			; was PC
	LEA	$DFF0D0,A3
	BSR.S	lbC000EB0
	ADDQ.L	#4,SP
	RTS

lbC000EB0	BTST	#0,$B5(A4)
	BNE.S	lbC000EBE
	TST.L	$8A(A4)
	BNE.S	lbC000EDC
lbC000EBE	MOVEQ	#0,D0
	MOVE.W	D0,8(A3)			; volume
	MOVE.W	#1,4(A3)			; length
	move.l	emptyWord(pc),A0			; was PC
	MOVE.L	A0,(A3)				; address
	TST.W	$B2(A4)
	BEQ.S	lbC000EDA
	SUBQ.W	#4,$B2(A4)
lbC000EDA	RTS

lbC000EDC	MOVEQ	#0,D3
	MOVE.W	$80(A4),D3
	MOVEQ	#0,D4
	MOVE.W	$82(A4),D4
	MOVEA.L	$8A(A4),A5
	MOVE.W	D7,D0
	MOVEQ	#12,D1
	LSR.W	D1,D0
	AND.W	#3,D0
	TST.W	D0
	BEQ.S	lbC000F2A
	SUBQ.W	#1,D0
	ASL.L	#4,D0
	LEA	$4A(A5,D0.W),A0
	MOVE.W	$AE(A4),D0
	MOVE.B	2(A0,D0.W),D1
	ADD.B	D1,D3
	ADD.B	D1,D4
	ADDQ.W	#1,$AE(A4)
	MOVEQ	#0,D0
	MOVE.B	(A0),D0
	ADD.B	1(A0),D0
	CMP.W	$AE(A4),D0
	BGT.S	lbC000F5E
	MOVEQ	#0,D0
	MOVE.B	(A0),D0
	MOVE.W	D0,$AE(A4)
	BRA.S	lbC000F5E

lbC000F2A	MOVE.W	D7,D0
	AND.W	#$F00,D0
	BNE.S	lbC000F5E
	MOVE.B	D7,D0
	BEQ.S	lbC000F5E
	MOVE.W	$B0(A4),D1
	TST.W	D1
	BNE.S	lbC000F44
	ADDQ.W	#1,$B0(A4)
	BRA.S	lbC000F5E

lbC000F44	CMP.W	#1,D1
	BNE.S	lbC000F52
	ADDQ.W	#1,$B0(A4)
	ASR.W	#4,D0
	BRA.S	lbC000F56

lbC000F52	CLR.W	$B0(A4)
lbC000F56	AND.W	#15,D0
	ADD.W	D0,D3
	ADD.W	D0,D4
lbC000F5E	LEA	lbW001716(PC),A0
	ADD.L	D3,D3
	ADD.L	D4,D4
	MOVE.W	0(A0,D3.W),D3
	MOVE.W	0(A0,D4.W),D4
	TST.W	$9A(A4)
	BEQ.S	lbC000FAA
	TST.W	$9C(A4)
	BNE.S	lbC000F7E
	MOVE.W	D4,$9C(A4)
lbC000F7E	MOVE.W	$9C(A4),D4
	MOVE.L	D3,D0
	SUB.L	D4,D0
	BPL.S	lbC000F8A
	NEG.L	D0
lbC000F8A	SUB.W	$9A(A4),D0
	BPL.S	lbC000F96
	CLR.W	$9A(A4)
	BRA.S	lbC000FAA

lbC000F96	CMP.L	D3,D4
	BGE.S	lbC000FA0
	ADD.W	$9A(A4),D4
	BRA.S	lbC000FA4

lbC000FA0	SUB.W	$9A(A4),D4
lbC000FA4	MOVE.W	D4,$9C(A4)
	MOVE.W	D4,D3
lbC000FAA	CMPI.B	#$FF,$95(A4)
	BEQ.S	lbC000FF2
	TST.W	$94(A4)
	BEQ.S	lbC000FBE
	SUBQ.W	#1,$94(A4)
	BRA.S	lbC000FF2

lbC000FBE	MOVE.W	$92(A4),D0
	LEA	lbL0017F2(PC),A6
	LEA	0(A6,D0.W),A6
	MOVEQ	#0,D1
	MOVE.B	(A6),D1
	EXT.W	D1
	EXT.L	D1
	MOVEQ	#0,D0
	MOVE.W	$1A(A5),D0
	TST.W	D0
	BEQ.S	lbC000FE4
	ADD.L	D1,D1
	ADD.L	D1,D1
	DIVS.W	D0,D1
	ADD.W	D1,D3
lbC000FE4	MOVE.W	$18(A5),D0
	ADD.W	D0,$92(A4)
	ANDI.W	#$FF,$92(A4)
lbC000FF2	MOVEQ	#0,D0
	MOVE.W	$20(A5),D0
	ADD.W	$22(A5),D0
	MOVE.W	D0,D2
	BEQ.S	lbC001042
	MOVEA.L	lbL000410(PC),A0
	MOVEQ	#0,D0
	MOVE.W	$1C(A5),D0
	ASL.L	#7,D0
	LEA	0(A0,D0.L),A0
	MOVE.W	$A4(A4),D0
	MOVE.B	0(A0,D0.W),D0
	EXT.W	D0
	SUB.W	D0,D3
	SUBQ.W	#1,$A6(A4)
	BNE.S	lbC001042
	MOVE.W	$1E(A5),$A6(A4)
	ADDQ.W	#1,$A4(A4)
	CMP.W	$A4(A4),D2
	BGT.S	lbC001042
	MOVE.W	$20(A5),D0
	TST.W	$22(A5)
	BNE.S	lbC00103E
	SUBQ.W	#1,D0
lbC00103E	MOVE.W	D0,$A4(A4)
lbC001042	SUB.W	$84(A4),D3
	CMP.W	#$71,D3
	BGE.S	lbC001050
	MOVE.W	#$71,D3
lbC001050	LEA	lbW00063C(PC),A6
	TST.W	(A6)
	BEQ.S	lbC001060
	MOVE.W	$86(A4),D0
	ADD.W	D0,$84(A4)
lbC001060	MOVE.W	D3,6(A3)		; period

	;bsr.w	SetPer

	TST.W	(A5)
	BEQ.S	lbC00106C
	BSR.W	lbC00117A
lbC00106C	MOVEQ	#0,D0
	MOVE.W	$28(A5),D0
	ADD.W	$2A(A5),D0
	MOVE.W	D0,D2
	BNE.S	lbC001098
	MOVE.W	$8E(A4),D0
	MOVE.W	lbW000626(PC),D1
	MULU.W	D1,D0
	ASR.L	#6,D0
;	MOVE.W	D0,8(A3)			; volume

	;bsr.w	ChangeVolume
	bsr.w	SetVol

	TST.W	$B2(A4)
	BEQ.S	lbC001094
	SUBQ.W	#4,$B2(A4)
lbC001094	BRA.W	lbC001134

lbC001098	MOVEA.L	lbL000414(PC),A0
	MOVE.W	$24(A5),D0
	ASL.W	#7,D0
	LEA	0(A0,D0.W),A0
	MOVE.W	$9E(A4),D0
	MOVEQ	#0,D1
	MOVE.B	0(A0,D0.W),D1
	MOVE.W	lbW000626(PC),D0
	MULU.W	D0,D1
	ASR.L	#6,D1
	MOVEQ	#0,D0
	MOVE.W	$8E(A4),D0
	MULU.W	D1,D0
	ASR.L	#6,D0
;	MOVE.W	D0,8(A3)			; volume

	;bsr.w	ChangeVolume
	bsr.w	SetVol

	ADD.W	D0,D0
	ADD.W	D0,D0
	MOVE.W	D0,$B2(A4)
	MOVE.L	D7,D0
	ROL.L	#8,D0
	AND.W	#$FF,D0
	CMP.W	#$80,D0
	BNE.S	lbC0010FE
	MOVE.W	$9E(A4),D0
	CMP.W	$2C(A5),D0
	BLT.S	lbC0010FE
	TST.W	$2E(A5)
	BEQ.S	lbC001134
	TST.W	$A0(A4)
	BEQ.S	lbC0010F8
	SUBQ.W	#1,$A0(A4)
	BRA.S	lbC001134

lbC0010F8	MOVE.W	$2E(A5),$A0(A4)
lbC0010FE	SUBQ.W	#1,$A2(A4)
	BNE.S	lbC001134
	MOVE.W	$26(A5),$A2(A4)
	ADDQ.W	#1,$9E(A4)
	CMP.W	$9E(A4),D2
	BGT.S	lbC001134
	MOVE.W	$28(A5),D0
	TST.W	$2A(A5)
	BNE.S	lbC001120
	SUBQ.W	#1,D0
lbC001120	MOVE.W	D0,$9E(A4)
	TST.W	$2A(A5)
	BNE.S	lbC001134
	TST.B	D1
	BNE.S	lbC001134
	BSET	#0,$B5(A4)
lbC001134	MOVE.W	$90(A4),D0
	MOVE.W	$8E(A4),D1
	ADD.W	D0,D1
	TST.W	D1
	BGE.S	lbC001146
	MOVEQ	#0,D1
	BRA.S	lbC001150

lbC001146	CMP.W	#$40,D1
	BLS.S	lbC001150
	MOVE.W	#$40,D1
lbC001150	MOVE.W	D1,$8E(A4)
	RTS

lbW001156	dc.w	lbC001714-lbC0011AA
	dc.w	lbC0011AC-lbC0011AA
	dc.w	lbC0011BC-lbC0011AA
	dc.w	lbC001280-lbC0011AA
	dc.w	lbC0012CE-lbC0011AA
	dc.w	lbC0012F0-lbC0011AA
	dc.w	lbC00135A-lbC0011AA
	dc.w	lbC00138E-lbC0011AA
	dc.w	lbC0013F6-lbC0011AA
	dc.w	lbC001452-lbC0011AA
	dc.w	lbC001552-lbC0011AA
	dc.w	lbC00156E-lbC0011AA
	dc.w	lbC00160C-lbC0011AA
	dc.w	lbC00164C-lbC0011AA
	dc.w	lbC00169E-lbC0011AA
	dc.w	lbC001422-lbC0011AA
	dc.w	lbC001620-lbC0011AA
	dc.w	lbC001524-lbC0011AA

lbC00117A	SUBQ.W	#1,$AC(A4)
	BNE.W	lbC001714
	MOVE.W	$48(A5),$AC(A4)
	MOVEQ	#0,D0
	MOVE.W	$42(A5),D0
	TST.W	D0
	BLE.W	lbC001714
	CMP.W	#$11,D0
	BGT.W	lbC001714
	ADD.W	D0,D0
	LEA	lbW001156(PC),A0
	MOVE.W	0(A0,D0.W),D0
	LEA	lbC0011AA(PC,D0.W),A0
lbC0011AA	JMP	(A0)

lbC0011AC	LEA	(A4),A0
	MOVEQ	#0,D0
	MOVE.W	$A8(A4),D0
	NEG.B	0(A0,D0.W)
	BRA.W	lbC001700

lbC0011BC	MOVE.L	D4,-(SP)
	BTST	#2,$B5(A4)
	BNE.W	lbC00127A
	LEA	(A4),A0
	MOVEA.L	lbL00040C(PC),A1
	MOVEQ	#0,D0
	MOVE.W	$40(A5),D0
	ASL.W	#7,D0
	LEA	0(A1,D0.L),A1
	MOVE.W	$AA(A4),D0
	MOVE.B	0(A1,D0.W),D0
	AND.W	#$7F,D0
	MOVE.W	D0,D4
	MOVEA.L	lbL00040C(PC),A1
	MOVEQ	#0,D1
	MOVE.W	2(A5),D1
	ASL.W	#7,D1
	LEA	0(A1,D1.W),A1
	MOVE.W	4(A5),D1
	ADD.W	D1,D1
	LEA	0(A0,D1.W),A0
	LEA	0(A1,D1.W),A1
	TST.W	D1
	BRA.S	lbC001212

lbC00120A	CMP.W	D1,D0
	BGT.S	lbC001214
	MOVE.L	-(A1),-(A0)
	SUBQ.W	#4,D1
lbC001212	BGT.S	lbC00120A
lbC001214	SUB.W	D1,D0
	ADD.W	D0,D1
	LEA	0(A1,D0.W),A1
	LEA	0(A0,D0.W),A0
	TST.W	D1
	BLE.S	lbC001250
	BTST	#0,D0
	BEQ.S	lbC001234
	MOVE.B	-(A1),D0
	NEG.B	D0
	MOVE.B	D0,-(A0)
	SUBQ.W	#1,D1
	BRA.S	lbC00124E

lbC001234	MOVE.L	-(A1),D0
	NEG.B	D0
	MOVE.B	D0,-(A0)
	ROR.L	#8,D0
	NEG.B	D0
	MOVE.B	D0,-(A0)
	ROR.L	#8,D0
	NEG.B	D0
	MOVE.B	D0,-(A0)
	ROR.L	#8,D0
	NEG.B	D0
	MOVE.B	D0,-(A0)
	SUBQ.W	#4,D1
lbC00124E	BGT.S	lbC001234
lbC001250	ADDQ.W	#1,$AA(A4)
	MOVE.W	$44(A5),D0
	ADD.W	$46(A5),D0
	MOVE.W	$AA(A4),D1
	CMP.W	D0,D1
	BLS.S	lbC00127A
	MOVE.W	$44(A5),$AA(A4)
	TST.W	$46(A5)
	BNE.S	lbC00127A
	TST.B	D4
	BNE.S	lbC00127A
	BSET	#2,$B5(A4)
lbC00127A	MOVE.L	(SP)+,D4
	BRA.W	lbC001714

lbC001280	LEA	(A4),A0
	MOVEQ	#0,D0
	MOVE.W	$46(A5),D0
	MOVE.W	$40(A5),D1
	MOVE.W	$44(A5),D2
	SUB.W	D2,D0
	LEA	0(A0,D2.W),A0
	BTST	#0,D2
	BEQ.S	lbC0012BA
	ADD.B	D1,(A0)+
	SUBQ.W	#1,D0
	BMI.S	lbC0012CA
	BRA.S	lbC0012BA

lbC0012A4	MOVE.L	(A0),D2
	ROL.L	#8,D2
	ADD.B	D1,D2
	ROL.L	#8,D2
	ADD.B	D1,D2
	ROL.L	#8,D2
	ADD.B	D1,D2
	ROL.L	#8,D2
	ADD.B	D1,D2
	MOVE.L	D2,(A0)+
	SUBQ.W	#4,D0
lbC0012BA	CMP.W	#3,D0
	BPL.S	lbC0012A4
	TST.W	D0
	BRA.S	lbC0012C8

lbC0012C4	ADD.B	D1,(A0)+
	SUBQ.W	#1,D0
lbC0012C8	BPL.S	lbC0012C4
lbC0012CA	BRA.W	lbC001700

lbC0012CE	LEA	(A4),A0
	MOVEQ	#0,D0
	MOVE.W	$46(A5),D0
	MOVE.W	$44(A5),D1
	LEA	0(A0,D1.W),A0
	SUB.W	D1,D0
	MOVE.B	(A0),D1
lbC0012E2	MOVE.B	1(A0),(A0)+
	SUBQ.W	#1,D0
	BPL.S	lbC0012E2
	MOVE.B	D1,(A0)
	BRA.W	lbC001700

lbC0012F0	LEA	(A4),A0
	MOVEA.L	lbL00040C(PC),A1
	MOVEQ	#0,D0
	MOVE.W	$40(A5),D0
	ASL.W	#7,D0
	LEA	0(A1,D0.W),A1
	MOVE.W	$46(A5),D1
	MOVE.W	$44(A5),D0
	LEA	0(A0,D0.W),A0
	LEA	0(A1,D0.W),A1
	SUB.W	D0,D1
	BTST	#0,D0
	BEQ.S	lbC001344
	MOVE.B	(A1)+,D2
	ADD.B	D2,(A0)+
	DBRA	D1,lbC001344
	BRA.S	lbC001356

lbC001324	MOVE.L	(A0),D2
	MOVE.L	(A1)+,D0
	ROL.L	#8,D0
	ROL.L	#8,D2
	ADD.B	D0,D2
	ROL.L	#8,D0
	ROL.L	#8,D2
	ADD.B	D0,D2
	ROL.L	#8,D0
	ROL.L	#8,D2
	ADD.B	D0,D2
	ROL.L	#8,D0
	ROL.L	#8,D2
	ADD.B	D0,D2
	MOVE.L	D2,(A0)+
	SUBQ.W	#4,D1
lbC001344	CMP.W	#3,D1
	BPL.S	lbC001324
	TST.W	D1
	BRA.S	lbC001354

lbC00134E	MOVE.B	(A1)+,D2
	ADD.B	D2,(A0)+
	SUBQ.W	#1,D1
lbC001354	BPL.S	lbC00134E
lbC001356	BRA.W	lbC001714

lbC00135A	LEA	(A4),A0
	MOVEA.L	lbL00040C(PC),A1
	MOVEQ	#0,D0
	MOVE.W	2(A5),D0
	ASL.W	#7,D0
	LEA	0(A1,D0.W),A1
	MOVEQ	#0,D0
	MOVE.W	$A8(A4),D0
	MOVE.B	0(A1,D0.W),0(A0,D0.W)
	MOVE.W	$46(A5),D1
	CMP.W	D1,D0
	BLT.S	lbC001386
	MOVE.W	$44(A5),D0
	SUBQ.W	#1,D0
lbC001386	NEG.B	1(A0,D0.W)
	BRA.W	lbC001700

lbC00138E	BSR.S	lbC001394
	BRA.W	lbC001700

lbC001394	LEA	(A4),A0
	MOVEA.L	lbL00040C(PC),A1
	MOVEQ	#0,D0
	MOVE.W	$40(A5),D0
	ASL.W	#7,D0
	LEA	0(A1,D0.W),A1
	ADDA.W	$44(A5),A1
	MOVE.W	$A8(A4),D0
	MOVE.B	0(A1,D0.W),D2
	MOVE.W	$46(A5),D1
	MOVE.W	$44(A5),D0
	LEA	0(A0,D0.W),A0
	SUB.W	D0,D1
	BTST	#0,D0
	BEQ.S	lbC0013E4
	ADD.B	D2,(A0)+
	DBRA	D1,lbC0013E4
	BRA.S	lbC0013F4

lbC0013CE	MOVE.L	(A0),D0
	ROL.L	#8,D0
	ADD.B	D2,D0
	ROL.L	#8,D0
	ADD.B	D2,D0
	ROL.L	#8,D0
	ADD.B	D2,D0
	ROL.L	#8,D0
	ADD.B	D2,D0
	MOVE.L	D0,(A0)+
	SUBQ.W	#4,D1
lbC0013E4	CMP.W	#3,D1
	BPL.S	lbC0013CE
	TST.W	D1
	BRA.S	lbC0013F2

lbC0013EE	ADD.B	D2,(A0)+
	SUBQ.W	#1,D1
lbC0013F2	BPL.S	lbC0013EE
lbC0013F4	RTS

lbC0013F6	BSR.S	lbC001394
	LEA	(A4),A0
	MOVE.W	$44(A5),D1
	LEA	0(A0,D1.W),A0
	MOVE.W	$AA(A4),D0
	NEG.B	0(A0,D0.W)
	ADDQ.W	#1,$AA(A4)
	MOVE.W	$46(A5),D0
	SUB.W	D1,D0
	CMP.W	$AA(A4),D0
	BPL.S	lbC00141E
	CLR.W	$AA(A4)
lbC00141E	BRA.W	lbC001700

lbC001422	MOVE.L	D4,-(SP)
	BTST	#1,$B5(A4)
	BEQ.S	lbC001438
	BCHG	#3,$B5(A4)
	BCLR	#1,$B5(A4)
lbC001438	BTST	#3,$B5(A4)
	BEQ.S	lbC00145E
	MOVEA.L	lbL00040C(PC),A1
	MOVEQ	#0,D0
	MOVE.W	2(A5),D0
	ASL.W	#7,D0
	LEA	0(A1,D0.W),A1
	BRA.S	lbC00146E

lbC001452	MOVE.L	D4,-(SP)
	BTST	#1,$B5(A4)
	BNE.W	lbC00151E
lbC00145E	MOVEA.L	lbL00040C(PC),A1
	MOVEQ	#0,D0
	MOVE.W	$40(A5),D0
	ASL.W	#7,D0
	LEA	0(A1,D0.W),A1
lbC00146E	MOVEQ	#0,D4
	LEA	(A4),A0
	MOVE.W	$46(A5),D1
	MOVE.W	$44(A5),D0
	LEA	0(A0,D0.W),A0
	LEA	0(A1,D0.W),A1
	SUB.W	D0,D1
	BTST	#0,D0
	BEQ.S	lbC0014F2
	MOVE.B	(A0)+,D0
	CMP.B	(A1)+,D0
	BEQ.S	lbC00149E
	ST	D4
	BLT.S	lbC001498
	SUBQ.B	#1,D0
	BRA.S	lbC00149A

lbC001498	ADDQ.B	#1,D0
lbC00149A	MOVE.B	D0,-1(A0)
lbC00149E	DBRA	D1,lbC0014F2
	BRA.S	lbC001514

lbC0014A4	MOVE.L	(A0)+,D0
	MOVE.L	(A1)+,D2
	CMP.L	D0,D2
	BEQ.S	lbC0014F0
	ST	D4
	CMP.B	D2,D0
	BEQ.S	lbC0014BA
	BLT.S	lbC0014B8
	SUBQ.B	#1,D0
	BRA.S	lbC0014BA

lbC0014B8	ADDQ.B	#1,D0
lbC0014BA	ROR.L	#8,D0
	ROR.L	#8,D2
	CMP.B	D2,D0
	BEQ.S	lbC0014CA
	BLT.S	lbC0014C8
	SUBQ.B	#1,D0
	BRA.S	lbC0014CA

lbC0014C8	ADDQ.B	#1,D0
lbC0014CA	ROR.L	#8,D0
	ROR.L	#8,D2
	CMP.B	D2,D0
	BEQ.S	lbC0014DA
	BLT.S	lbC0014D8
	SUBQ.B	#1,D0
	BRA.S	lbC0014DA

lbC0014D8	ADDQ.B	#1,D0
lbC0014DA	ROR.L	#8,D0
	ROR.L	#8,D2
	CMP.B	D2,D0
	BEQ.S	lbC0014EA
	BLT.S	lbC0014E8
	SUBQ.B	#1,D0
	BRA.S	lbC0014EA

lbC0014E8	ADDQ.B	#1,D0
lbC0014EA	ROR.L	#8,D0
	MOVE.L	D0,-4(A0)
lbC0014F0	SUBQ.W	#4,D1
lbC0014F2	CMP.W	#3,D1
	BPL.S	lbC0014A4
	TST.W	D1
	BRA.S	lbC001512

lbC0014FC	MOVE.B	(A0)+,D0
	CMP.B	(A1)+,D0
	BEQ.S	lbC001510
	ST	D4
	BLT.S	lbC00150A
	SUBQ.B	#1,D0
	BRA.S	lbC00150C

lbC00150A	ADDQ.B	#1,D0
lbC00150C	MOVE.B	D0,-1(A0)
lbC001510	SUBQ.W	#1,D1
lbC001512	BPL.S	lbC0014FC
lbC001514	TST.B	D4
	BNE.S	lbC00151E
	BSET	#1,$B5(A4)
lbC00151E	MOVE.L	(SP)+,D4
	BRA.W	lbC001714

lbC001524	MOVE.W	$46(A5),D0
	CMP.W	$AA(A4),D0
	BLS.S	lbC001544
lbC00152E	MOVE.W	$44(A5),D0
	MOVE.W	$40(A5),D1
	MULU.W	D0,D1
	SUB.W	D1,$84(A4)
	ADDQ.W	#1,$AA(A4)
	BRA.W	lbC001700

lbC001544	MOVE.W	$12(A5),$84(A4)
	MOVEQ	#0,D0
	MOVE.W	D0,$AA(A4)
	BRA.S	lbC00152E

lbC001552	MOVE.W	$46(A5),D0
	CMP.W	$AA(A4),D0
	BLS.S	lbC00156A
	MOVE.W	$44(A5),D1
	EXT.W	D1
	ADD.W	D1,$84(A4)
	ADDQ.W	#1,$AA(A4)
lbC00156A	BRA.W	lbC001700

lbC00156E	MOVE.L	D4,-(SP)
	LEA	(A4),A0
	MOVEQ	#0,D0
	MOVE.W	$40(A5),D2
	MOVE.W	$46(A5),D1
	MOVE.W	$44(A5),D0
	LEA	0(A0,D0.W),A0
	SUB.W	D0,D1
	BTST	#0,D0
	BEQ.S	lbC0015E8
	MOVE.B	(A0),D0
	CMP.B	1(A0),D0
	BGT.S	lbC001598
	ADD.B	D2,D0
	BRA.S	lbC00159A

lbC001598	SUB.W	D2,D0
lbC00159A	MOVE.B	D0,(A0)+
	DBRA	D1,lbC0015E8
	BRA.S	lbC001606

lbC0015A2	MOVE.L	(A0),D0
	MOVE.L	D0,D4
	ROL.L	#8,D4
	MOVE.B	4(A0),D4
	ROL.L	#8,D0
	ROL.L	#8,D4
	CMP.B	D4,D0
	BGT.S	lbC0015B8
	ADD.W	D2,D0
	BRA.S	lbC0015BA

lbC0015B8	SUB.W	D2,D0
lbC0015BA	ROL.L	#8,D0
	ROL.L	#8,D4
	CMP.B	D4,D0
	BGT.S	lbC0015C6
	ADD.W	D2,D0
	BRA.S	lbC0015C8

lbC0015C6	SUB.W	D2,D0
lbC0015C8	ROL.L	#8,D0
	ROL.L	#8,D4
	CMP.B	D4,D0
	BGT.S	lbC0015D4
	ADD.W	D2,D0
	BRA.S	lbC0015D6

lbC0015D4	SUB.W	D2,D0
lbC0015D6	ROL.L	#8,D0
	ROL.L	#8,D4
	CMP.B	D4,D0
	BGT.S	lbC0015E2
	ADD.W	D2,D0
	BRA.S	lbC0015E4

lbC0015E2	SUB.W	D2,D0
lbC0015E4	MOVE.L	D0,(A0)+
	SUBQ.W	#4,D1
lbC0015E8	CMP.W	#3,D1
	BPL.S	lbC0015A2
	TST.W	D1
	BRA.S	lbC001604

lbC0015F2	MOVE.B	(A0),D0
	CMP.B	1(A0),D0
	BGT.S	lbC0015FE
	ADD.W	D2,D0
	BRA.S	lbC001600

lbC0015FE	SUB.W	D2,D0
lbC001600	MOVE.B	D0,(A0)+
	SUBQ.W	#1,D1
lbC001604	BPL.S	lbC0015F2
lbC001606	MOVE.L	(SP)+,D4
	BRA.W	lbC001700

lbC00160C	LEA	(A4),A0
	MOVE.W	$A8(A4),D1
	MOVE.B	$DFF007,D0
	EOR.B	D0,0(A0,D1.W)
	BRA.W	lbC001700

lbC001620	LEA	(A4),A0
	MOVE.W	$46(A5),D1
	MOVE.W	$44(A5),D0
	LEA	0(A0,D0.W),A0
	SUB.W	D0,D1
lbC001630	MOVE.B	0(A0,D1.W),D0
	EORI.B	#5,D0
	ROL.B	#2,D0
	ADD.B	$DFF007,D0
	MOVE.B	D0,0(A0,D1.W)
	SUBQ.W	#1,D1
	BPL.S	lbC001630
	BRA.W	lbC001714

lbC00164C	MOVE.L	D4,-(SP)
	LEA	(A4),A0
	MOVEQ	#0,D0
	MOVE.W	$40(A5),D4
	MOVE.W	$46(A5),D1
	MOVE.W	$44(A5),D0
	LEA	0(A0,D1.W),A1
	LEA	0(A0,D0.W),A0
	MOVEA.L	A0,A2
lbC001668	SF	D2
	MOVE.B	(A0),D0
	CMPA.L	A1,A0
	BNE.S	lbC001674
	MOVE.B	(A2),D1
	BRA.S	lbC001678

lbC001674	MOVE.B	1(A0),D1
lbC001678	CMP.B	D1,D0
	BGT.S	lbC00167E
	ST	D2
lbC00167E	SUB.B	D1,D0
	BPL.S	lbC001684
	NEG.B	D0
lbC001684	MOVE.W	D4,D1
	CMP.W	D1,D0
	BLE.S	lbC001694
	TST.B	D2
	BNE.S	lbC001692
	SUBQ.B	#2,(A0)
	BRA.S	lbC001694

lbC001692	ADDQ.B	#2,(A0)
lbC001694	ADDQ.L	#1,A0
	CMPA.L	A0,A1
	BGE.S	lbC001668
	MOVE.L	(SP)+,D4
	BRA.S	lbC001700

lbC00169E	MOVEA.L	lbL00040C(PC),A6
	MOVEQ	#0,D0
	MOVE.W	$40(A5),D0
	ASL.L	#7,D0
	LEA	0(A6,D0.L),A6
	LEA	(A4),A0
	MOVEQ	#0,D0
	MOVE.W	$46(A5),D0
	LEA	0(A0,D0.W),A1
	LEA	0(A6,D0.W),A6
	MOVE.W	$44(A5),D0
	LEA	0(A0,D0.W),A0
	MOVEA.L	A0,A2
lbC0016C8	SF	D2
	MOVE.B	(A0),D0
	CMPA.L	A1,A0
	BNE.S	lbC0016D4
	MOVE.B	(A2),D1
	BRA.S	lbC0016D8

lbC0016D4	MOVE.B	1(A0),D1
lbC0016D8	CMP.B	D1,D0
	BGT.S	lbC0016DE
	ST	D2
lbC0016DE	SUB.B	D1,D0
	BPL.S	lbC0016E4
	NEG.B	D0
lbC0016E4	MOVEQ	#0,D1
	MOVE.B	(A6)+,D1
	AND.W	#$7F,D1
	CMP.W	D1,D0
	BLE.S	lbC0016FA
	TST.B	D2
	BNE.S	lbC0016F8
	SUBQ.B	#2,(A0)
	BRA.S	lbC0016FA

lbC0016F8	ADDQ.B	#2,(A0)
lbC0016FA	ADDQ.L	#1,A0
	CMPA.L	A0,A1
	BGE.S	lbC0016C8
lbC001700	ADDQ.W	#1,$A8(A4)
	MOVE.W	$A8(A4),D0
	CMP.W	$46(A5),D0
	BLS.S	lbC001714
	MOVE.W	$44(A5),$A8(A4)
lbC001714	RTS

lbW001716	dc.w	0
	dc.w	$3580
	dc.w	$3280
	dc.w	$2FA0
	dc.w	$2D00
	dc.w	$2A60
	dc.w	$2800
	dc.w	$25C0
	dc.w	$23A0
	dc.w	$21A0
	dc.w	$1FC0
	dc.w	$1E00
	dc.w	$1C50
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
	dc.w	$E28
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
	dc.w	$6B
	dc.w	$65
	dc.w	$5F
	dc.w	$5A
	dc.w	$55
	dc.w	$50
	dc.w	$4B
	dc.w	$47
	dc.w	$43
	dc.w	$3F
	dc.w	$3C
	dc.w	$38
	dc.w	$35
	dc.w	$32
	dc.w	$2F
	dc.w	$2D
	dc.w	$2A
	dc.w	$28
	dc.w	$25
	dc.w	$23
	dc.w	$21
	dc.w	$1F
	dc.w	$1E
	dc.w	$1C
	dc.w	$FFFF
lbL0017F2	dc.l	$30609
	dc.l	$C101316
	dc.l	$191C1F22
	dc.l	$25282B2E
	dc.l	$31343639
	dc.l	$3C3F4244
	dc.l	$47494C4E
	dc.l	$51535658
	dc.l	$5A5C5E60
	dc.l	$62646668
	dc.l	$6A6C6D6F
	dc.l	$70727374
	dc.l	$76777879
	dc.l	$7A7B7B7C
	dc.l	$7D7D7E7E
	dc.l	$7E7F7F7F
	dc.l	$7F7F7F7F
	dc.l	$7E7E7D7D
	dc.l	$7C7C7B7A
	dc.l	$79787776
	dc.l	$75747271
	dc.l	$706E6C6B
	dc.l	$69676563
	dc.l	$615F5D5B
	dc.l	$59575452
	dc.l	$504D4B48
	dc.l	$4543403D
	dc.l	$3B383532
	dc.l	$2F2C2927
	dc.l	$24201D1A
	dc.l	$1714110E
	dc.l	$B080502
	dc.l	$FFFCF9F6
	dc.l	$F2EFECE9
	dc.l	$E6E3E0DD
	dc.l	$DAD7D4D1
	dc.l	$CECBC9C6
	dc.l	$C3C0BEBB
	dc.l	$B8B6B3B1
	dc.l	$AEACAAA8
	dc.l	$A5A3A19F
	dc.l	$9D9B9998
	dc.l	$96949391
	dc.l	$908E8D8C
	dc.l	$8A898887
	dc.l	$86868584
	dc.l	$84838382
	dc.l	$82828282
	dc.l	$82828282
	dc.l	$82838384
	dc.l	$84858687
	dc.l	$88898A8B
	dc.l	$8C8D8F90
	dc.l	$92939597
	dc.l	$989A9C9E
	dc.l	$A0A2A4A6
	dc.l	$A9ABADB0
	dc.l	$B2B5B7BA
	dc.l	$BCBFC2C4
	dc.l	$C7CACDD0
	dc.l	$D3D6D9DB
	dc.l	$DEE2E5E8
	dc.l	$EBEEF1F4
	dc.l	$F7FAFD00

;lbC0018F2	MOVEM.L	D0-D7/A0-A6,-(SP)
;	MOVEQ	#0,D5
;	MOVEQ	#0,D6
;	MOVE.L	D0,D7
;	LEA	lbW000634(PC),A0
;	LEA	0(A0,D1.W),A0
;	LEA	0(A0,D1.W),A0
;	MOVE.W	D2,(A0)
;	MOVEQ	#1,D2
;	LSL.L	D1,D2
;	MOVE.L	D1,D0
;	ASL.L	#2,D0
;	LEA	lbL00065A(PC),A0
;	CLR.L	0(A0,D0.L)
;	MOVE.L	D1,D0
;	ADD.L	D0,D0
;	LEA	lbW000642(PC),A0
;	CLR.W	0(A0,D0.L)
;	LEA	lbW00062C(PC),A0
;	LEA	0(A0,D1.W),A0
;	LEA	0(A0,D1.W),A0
;	LEA	lbB000628(PC),A2
;	LEA	0(A2,D1.W),A2
;	LEA	chip1(PC),A4
;	MOVE.L	D1,D0
;	MULU.W	#$CE,D0
;	LEA	0(A4,D0.W),A4
;	LEA	$DFF0A0,A3
;	MOVE.L	D1,D0
;	LSL.L	#4,D0
;	LEA	0(A3,D0.W),A3
;	MOVEA.L	4,A6
;	JSR	-$78(A6)
;	BSR.L	lbC000C60
;	BSR.L	lbC000E62
;	OR.W	#$8000,D5
;	MOVE.W	D5,$DFF096
;	MOVEA.L	4,A6
;	JSR	-$7E(A6)
;	MOVEM.L	(SP)+,D0-D7/A0-A6
;	RTS

;	Section	Buffy,BSS_C
;
;chip1
;	ds.b	206
;chip2
;	ds.b	206
;chip3
;	ds.b	206
;chip4
;	ds.b	206
;emptyWord
;	ds.b	2
