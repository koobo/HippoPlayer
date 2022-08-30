;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
	incdir	include:
	include	exec/exec_lib.i
	include libraries/gadtools_lib.i
	include	devices/ahi_lib.i
	include	devices/ahi.i
	include	"utility/hooks.i"
	include	mucro.i

;----------------- DIGI Booster PRO By Tap & Walt ----------------
;		     player v 2.16 pure code                     ;
;		     by Tap - Tomasz Piasta                      ;
;-----------------------------------------------------------------
;new in 2.16 
;added pannings and panning envelopes
;added DSP echo effect commands
;----------------------------------------------------------------- 
;You have to fill in following data:
;
;	ReadMemAdr - which is start adress of loaded module
;	ReadMemEnd - which is end adress of loaded module
;
;       to configurate DB player use:
;
;       AutoBoostEn - 0 - auto boost disabled
;                   - 1 - auto boost enabled (default)
;
;       MasterVol   - which is a master volume of all channels
;                     (use this parameter in volumeslider)
;
;       SongPos     - change song position
;       PattPos     - change current position in pattern
;
;       InstrNames - list of instrument's names (each takes 30 bytes)
;
;
;------------------------------------------------------------------

init
;	move.l	moduleaddress(a5),a0
;	move.l	ahi_rate(a5),d0
;	move	ahi_mastervol(a5),d1
;	move	ahi_stereolev(a5),d2
;	move.l	ahi_mode(a5),d3
;	move.l	digiboosterproroutines(a5),a1
;	lea	mainvolume(a5),a2
;	lea	songover(a5),a3

test = 0

 ifne test
	lea	MODULE,a0
	move.l	#MODULEE-MODULE,d4

	move.l	#28000,d0
 	move.l	#$00020002,d3
	lea	voo(pc),a2
	lea	vuu(pc),a3

	bsr	ini

loo	btst	#6,$bfe001
	bne.b	loo

	bsr	end

	rts

voo	dc	64
vuu	dc	0

 endc

main
	jmp	ini(pc)
	jmp	end(pc)
	jmp	stopcont(pc)
	rts
	rts
	rts
	rts

ini
	move.l	a0,ReadMemAdr
	add.l	d4,a0
	move.l	a0,ReadMemEnd

	move.l	d0,ahi_freq
	move.l	d3,ahi_audioid
	move.l	a2,mainvolume
	move.l	a3,songover

	move	#1,AutoBoostEn
	move	(a2),MasterVol

	bsr	s
	

	lea	SongPos(pc),a0
	lea	OrdNum(pc),a1
	lea	PattPos(pc),a2

	tst.l	d0
	rts

end	bra	endplay

stopcont
	pushm	d0/d1/a0-a2/a6

	lea	ahi_ctrltags_(pc),a1
	eor.b	#1,setpause-ahi_ctrltags_(a1)
	move.l	ahi_ctrl(pc),a2
	move.l	ahibase(pc),a6
	jsr	_LVOAHI_ControlAudioA(a6)

	popm	d0/d1/a0-a2/a6
	rts


ahi_ctrltags_:	dc.l	AHIC_Play,1
setpause 	=	*-1
		dc.l	TAG_DONE


mainvolume	dc.l	0
songover	dc.l	0




Open		equ	-30
Close		equ 	-36
Read		equ	-42
ModeRead	equ	1005

Lock		=-84
UnLock		=-90
Examine		=-102
ExNext		=-108
AccesRead	=-2

Write		equ -48
ModeWrite	equ 1006	

s:
	move.l	4.w,ExecBase

	move.l	4.w,a6
	lea	DosName,a1
	moveq	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,DosBase

	move.l	4.w,a6
	lea	ReqName,a1
	moveq	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,ReqBase

	lea	InstrGeneralPan,a1
	move.l	#256-1,d7
.setpan	move.w	#128,(a1)+
	dbf	d7,.setpan

	move.l	ReadMemEnd,d0
	sub.l	ReadMemAdr,d0
	move.l	d0,FileLen
	jsr	DBM0

	cmp.w	#1,LoadModError
	beq.w	.WASERROR

	clr.w	SongPos
	clr.w	PattPos
	clr.w	FirstTrack
	clr.w	PattPos
	clr.b	count
	moveq	#0,d0
	move.w	GeneralSpeed,d0
	move.b	d0,Orgtemp
	bset	#1,$bfe001
	move.b	Orgtemp,count
	move.w	GeneralTempo,CiaTempo

	clr.w	PauseVBL
	clr.b	PauseEn

	clr.b	count
	clr.b	count2
	clr.w	PattPos
	lea	channel1,a0
	move.w	#128-1,d7
.clr	jsr	ClearSongData
	lea	ChanArea(a0),a0
	dbf	d7,.Clr

.retry

	jsr	ahi_initstart
	tst.l	d0
	beq.s	.ok
	bsr	OpenAhiError
	cmp.w	#1,d0
	beq.s	.retry
	clr.l	AhiBase
	bra	.end
.ok
	move.b	#6,Temp

	moveq	#0,d0		* OK!
	rts


.END
.WASERROR
	jsr	FreeModule
	moveq	#-1,d0
	rts


endplay
	jsr	Ahi_End
	jsr	FreeModule
	rts


DOSName:	dc.b	"dos.library",0
reqname:	dc.b	'reqtools.library',0
		even
ExecBase:	dc.l	0
DosBase:	dc.l	0
ReqBase:	dc.l	0
ReadName:	dc.l	0

GeneralTempo:	dc.w	125
GeneralSpeed:	dc.w	6
InstrNum:	dc.w	1
FirstTrack:	dc.w	0
ActualTrack:	dc.w	0
TrackNumber:	dc.w	0

INSNUM:		dc.w	0
PATNUM:		dc.w	0
SNGNUM:		dc.w	0
SMPNUM:		dc.w	0

OrdNum:		dc.w	0

OrdNum0:	dc.w	0
OrdNum1:	dc.w	0
OrdNum2:	dc.w	0
OrdNum3:	dc.w	0
OrdNum4:	dc.w	0

ActualSong:	dc.w	1

FileHandle:	dc.l	0
LoadModError:	dc.w	0
Mode16BitEn:	dc.w	0

PP_LENG:	dc.w	0
PP_ADR:		dc.l	0

NoLoopEnable:	dc.w	0
MIXITENABLE:	dc.w	0

playenable:	dc.w	0
stopenable:	dc.w	0

OrgTemp:	dc.b	0
SPAHIENABLE	dc.b	0
PlayPattEn:	dc.w	0
OldSPos:	dc.w	0
EditEnable:	dc.w	0
ACTCHAN:	dc.w	0

AutoBoostEn:
		dc.w	1
		even

*-----------------------------------------------------------------------*
;
; Cleanup Routines

ClearSongData:
	clr.w	MainPeriod(a0)
	clr.w	Oldd0(a0)
	clr.w	Oldd1(a0)
	clr.w	Oldd2(a0)
	clr.w	Oldd3(a0)
	clr.w	Oldd4(a0)
	clr.w	Oldd5(a0)
	clr.w	Oldd6(a0)

	clr.b	loopsdataschanA(a0)
	clr.b	loopsdataschanA+1(a0)
	clr.w	loopsdataschanA+2(a0)

	clr.b	loopsdataschanB(a0)
	clr.b	loopsdataschanB+1(a0)
	clr.w	loopsdataschanB+2(a0)

	clr.b	RetraceCntA(a0)
	clr.b	RetraceCntB(a0)

	clr.w	PauseVBL
	clr.b	PauseEn

	clr.b	EqNewSamA(a0)
	clr.b	EqNewSamB(a0)

	clr.w	OrgPeriod(a0)
	clr.w	OrgPeriodARP(a0)

	clr.l	GlissandoDatasA(a0)
	clr.w	GlissandoDatasA+4(a0)
	clr.l	GlissandoDatasB(a0)
	clr.w	GlissandoDatasB+4(a0)


	clr.b	OffEnable(a0)
	clr.w	OldMainVol(a0)
	clr.l	OldPanPos(a0)
	rts

	
FreeModule:
	lea	Channel1+OnOffChanA,a0
	moveq	#128-1,d7
.onoff	bclr	#0,(a0)
	lea	ChanArea(a0),a0
	dbf	d7,.onoff

	bsr	FreeSong
	bsr	FreeSamples

	move.w	#64,MasterVol
	rts

FreeSong:
	move.l	#1024-1,d7
	lea	PattAdresses,a5
	lea	PattLens,a4
	moveq	#0,d6
	move.w	TrackNumber,d6
	mulu	#6,d6
FreePatts
	move.l	4,a6

	moveq	#0,d5
	move.w	(a4)+,d5
	mulu	d6,d5
	move.l	d5,d0

	move.l	(a5),a1		;adres zajetej pamieci
	tst.l	(a5)+
	beq.s	FreePattsDone

	subq.l	#8,a1
	addq.l	#8,d0
	jsr	-210(a6)
	clr.l	-4(a5)
;	clr.w	-2(a4)
	dbf	d7,FreePatts
FreePattsDone


	lea	SongOrders,a1
	move.l	#1024-1,d7
MMMCLR1	clr.w	(a1)+
	dbf	d7,MMMCLR1

	lea	SongOrders0,a1
	move.l	#(1024+1-1)*5,d7
MMMCLR11
	clr.w	(a1)+
	dbf	d7,MMMCLR11

	bsr	ClrModName

	lea	SongNameBuffer,a1
	move.w	#42-1,d7
MMMCLR6	clr.b	(a1)+
	dbf	d7,MMMCLR6

	lea	SongNameBuffer0,a1
	move.w	#44*5-1,d7
MMMCLR66
	clr.b	(a1)+
	dbf	d7,MMMCLR66

	clr.w	PATNUM
	clr.w	ORDNUM
	clr.w	ORDNUM0
	clr.w	ORDNUM1
	clr.w	ORDNUM2
	clr.w	ORDNUM3
	clr.w	ORDNUM4
	clr.w	ActualSong
	move.w	#64,GlobalVol

	move.l	Ahi_freq,d7
	lsl.l	#8,d7
	divu	#500,d7
	and.l	#$ffff,d7
	mulu	#64,d7
	lsr.l	#8,d7
	move.l	d7,DSPECHODELAY

	move.l	#$8000,DSPECHOFEEDBACK
	move.l	#$8000,DSPECHOMIX
	move.l	#$10000,DSPECHOCROSS


	lea	DSPParamTab,a1
	move.w	#$40,(a1)
	move.w	#$80,2(a1)
	move.w	#$80,4(a1)
	move.w	#$ff,6(a1)

	move.w	#125,RealTempo
	move.w	#125,RealCiaTempo

	lea	mask1channels+2,a1
	move.w	#128-1,d7
.clr	move.b	#AHIEDM_DRY,(a1)+
	dbf	d7,.clr

	clr.w	FirstTrack
	rts


ClrModName:
	lea	ModNameBuffer,a1
	move.w	#42-1,d7
MMMCLR4	clr.b	(a1)+
	dbf	d7,MMMCLR4
	rts



FreeSamples:
	move.l	#255-1,d7
	lea	AHI_Samples,a5
FreeSampleLoop
	move.l	4,a6
	move.l	(a5),a1			;adres zajetej pamieci
	move.l	4(a5),d0

	clr.l	8(a5)
	clr.l	12(a5)
	clr.l	4(a5)

	tst.l	(a5)
	beq.s	FreeSamMKL

	cmp.l	#0,Ahi_Sound0
	beq.s	.8bit
	add.l	d0,d0
.8bit

	clr.l	(a5)
	subq.l	#8,a1
	addq.l	#8,d0
	jsr	-210(a6)
FreeSamMKL
	lea	16(a5),a5
	dbf	d7,FreeSampleLoop

	lea	SamVol,a1
	move.l	#256-1,d7
MMMCLR2	clr.b	(a1)+
	dbf	d7,MMMCLR2

	lea	samfin,a1
	move.l	#256-1,d7
MMMCLR3	move.l	#8363,(a1)+
	dbf	d7,MMMCLR3

	lea	InstrNames,a1
	move.l	#30*256/4-1,d7
MMMCLR5	clr.l	(a1)+
	dbf	d7,MMMCLR5

	lea	VolEnvelope,a1
	move.l	#134*256/4-1,d7
MMMCLR7	clr.l	(a1)+
	dbf	d7,MMMCLR7

	lea	PanEnvelope,a1
	move.l	#134*256/4-1,d7
.MMMCLR7p
	clr.l	(a1)+
	dbf	d7,.MMMCLR7p

	lea	SampleType,a1
	move.l	#256*2-1,d7
MMMCLR8	clr.b	(a1)+
	dbf	d7,MMMCLR8

	lea	LoopTab,a1
	move.l	#256-1,d7
MMMCLR9	clr.b	(a1)+
	dbf	d7,MMMCLR9

	lea	InstrGeneralPan,a1
	move.l	#256-1,d7
MMMCLRA move.w	#128,(a1)+
	dbf	d7,MMMCLRA

	bsr	makeinstr

	move.w	#125,RealTempo
	move.w	#125,RealCiaTempo

	clr.w	INSNUM
	move.w	#64,GlobalVol

	tst.w	CANDO
	beq.s	CANTDO
	move.l	#AHIST_M8S,AHI_Sound0
	clr.w	Mode16biten
CANTDO
	rts

CANDO:	dc.w	0

MakeInstr:
	lea	Instruments,a0
	move.l	#256-1,d7
	moveq	#0,d0
.mi
	move.w	d0,(a0)+
	addq	#1,d0
	dbf	d7,.mi
	rts


DSPParamTab:
	dc.w	0,0,0,0

UpdateEffects:
	lea	DSPParamTab,a0
	moveq	#0,d3
	move.w	(a0),d3
	add.w	#$2000,d3
	jsr	SetDelay

	lea	DSPParamTab,a0
	moveq	#0,d3
	move.w	2(a0),d3
	add.w	#$2100,d3
	jsr	SetFeedBack

	lea	DSPParamTab,a0
	moveq	#0,d3
	move.w	4(a0),d3
	add.w	#$2200,d3
	jsr	SetMix

	lea	DSPParamTab,a0
	moveq	#0,d3
	move.w	6(a0),d3
	add.w	#$2300,d3
	jsr	SetCross

	bsr	EchoOn
	rts

ChooseReqTitle:
	dc.b	"Digi Booster 2.12 player Request",0
	even

RT_TagBase		equ	$80000000
RTEZ_ReqTitle		equ	 (RT_TagBase+20)
RTEZ_DefaultResponse	equ	 (RT_TagBase+23)
RT_Underscore		equ	 (RT_TagBase+11)
RT_ReqPos		equ	 (RT_TagBase+3)
REQPOS_CENTERSCR	equ	 2
rtEZRequestA		equ	-66

ChooseReqTags:
	dc.l	RTEZ_ReqTitle,ChooseReqTitle
	dc.l	RTEZ_DefaultResponse,1
	dc.l	RT_Underscore,'_'
	dc.l	RT_ReqPos,REQPOS_CENTERSCR
	dc.l	0,0

OpenChooseReq:
	move.l	ReqBase,a6
	lea	ChooseReqTags,a0
	move.l	#0,a3
	move.l	#0,a4
	jsr	rtEZRequestA(a6)
	rts

NotEnoughMemoryError
	movem.l	d0-a6,-(sp)
	move.l	#NoMemoryText,a1
	move.l	#AboutOKText,a2
	bsr	OpenChooseReq
	movem.l	(sp)+,d0-a6
	rts

NotEnoughForConvert
	movem.l	d0-a6,-(sp)
	move.l	#NoMemForConvert,a1
	move.l	#AboutOKText,a2
	bsr	OpenChooseReq
	movem.l	(sp)+,d0-a6
	rts

ReadError:
	movem.l	d0-a6,-(sp)
	move.l	#ReadErrorText,a1
	move.l	#AboutOKText,a2
	bsr	OpenChooseReq
	movem.l	(sp)+,d0-a6
	rts


OpenAhiError:
	movem.l	d1-a6,-(sp)
	move.l	#OpenAhiErrorText,a1
	move.l	#OpenAhiErrorAskText,a2
	bsr	OpenChooseReq
	movem.l	(sp)+,d1-a6
	rts

OpenAhiError2:
	movem.l	d1-a6,-(sp)
	move.l	#OpenAhiErrorText2,a1
	move.l	#AboutOKText,a2
	bsr	OpenChooseReq
	movem.l	(sp)+,d1-a6
	rts



ReadErrorTEXT:
	dc.b	" Read Error! ",10
	dc.b	0
	even

NoMemForConvert:
	dc.b	"Sorry! There is no memory to",10
	dc.b	"convert samples to 16 bit!!!",10
	dc.b	0
	even

NoMemoryTEXT:
	dc.b	" Not Enough Memory! ",10
	dc.b	0
	even

OpenAhiErrorTEXT:
	dc.b	" Can't open AHI.device !",10
	dc.b	0
	even

OpenAhiErrorTEXT2:
	dc.b	" Can't open AHI.device !",10
	dc.b	"       Try again.",10
	dc.b	0
	even

OpenAhiErrorASKTEXT:
	dc.b	"_Retry |_Cancel",0
	even

AboutOKText:
	dc.b	"_OK",0
	even



ConvertAllTo16BIT:
	movem.l	d0-a6,-(sp)
	cmp.l	#0,Ahi_Sound0
	beq.s	.no16bitmode

	move.w	#0,Mode16biten
	move.l	#0,Ahi_Sound0
;	jsr	FreeSampleBuffer
	move.w	#1,Mode16biten
	move.l	#1,Ahi_Sound0


	move.l	#255-1,d6
	moveq	#0,d7
.loop
	movem.l	d0-d6/a0-a6,-(sp)
	bsr	ConvertTO16BIT
	movem.l	(sp)+,d0-d6/a0-a6

	cmp.w	#-1,d7
	beq.s	NotMem

	dbf	d6,.loop

.no16bitmode
	movem.l	(sp)+,d0-a6
	rts

NotMem:
	jsr	NotEnoughForConvert

;	move.w	#0,Mode16BitEn
;	move.l	#AHIST_M8S,AHI_Sound0
;	jsr	ConvertAllTO8bit

	movem.l	(sp)+,d0-a6
	rts

ConvertTO16BIT:
	lea	SampleType,a6
	tst.b	(a6,d6.w)
	bne.s	.juzjest16bit
	move.b	#1,(a6,d6.w)
	move.l	d6,d7
	lsl.w	#4,d7
	lea	AHI_Samples,a5
	move.l	4(a5,d7.w),d0
	tst.l	d0
	beq.s	.juzjest16bit

	movem.l	d1-a6,-(sp)
	move.l	4,a6
	add.l	d0,d0
	addq.l	#8,d0
	move.l	#$10001,d1
	jsr	-198(a6)
	movem.l	(sp)+,d1-a6
	tst.l	d0
	beq	.allocerror
	addq.l	#8,d0

	movem.l	d0-a6,-(sp)
	move.l	(a5,d7.w),a2
	move.l	d0,a3
	move.l	4(a5,d7.w),d6
.expandto16
	move.b	(a2)+,(a3)+
	clr.b	(a3)+
	subq.l	#1,d6
	tst.l	d6
	bgt.s	.expandto16
	movem.l	(sp)+,d0-a6

	movem.l	d0-a6,-(sp)
	move.l	(a5,d7.w),a1
	move.l	4(a5,d7.w),d0
	subq.l	#8,a1
	addq.l	#8,d0
	move.l	4,a6
	jsr	-210(a6)
	movem.l	(sp)+,d0-a6

	move.l	d0,(a5,d7.w)

.juzjest16bit
	moveq	#0,d7
	rts

.allocerror
	clr.b	(a6,d6.w)
	moveq	#-1,d7
	rts



; ------------------------- read DBM0
DBM0:
	clr.w	DBM0_DONE1
	clr.w	DBM0_DONE2
	clr.l	DBM0_len

	lea	MODBUFFER,a5
	move.l	a5,d2
	move.l	#8,d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	RM_ReadError

; ----------- read hunks
.mainloop
	move.l	a5,d2
	move.l	#8,d3
	add.l	d3,DBM0_len
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	lea	Headers,a0
.loop
	move.l	(a0)+,d0
	move.l	(a0)+,a1

	cmp.l	#-1,d0
	beq.s	.notfound
	cmp.l	(a5),d0
	bne.s	.loop
	addq.w	#1,DBM0_DONE1

	move.l	4(a5),d7
	add.l	d7,DBM0_len

	jsr	(a1)
	cmp.w	#0,LoadModError
	bne.s	.done
	cmp.w	#9,DBM0_DONE1
	beq.w	.done
	bra.s	.mainloop

.notfound
	move.l	4(a5),d3
	add.l	d3,DBM0_len

	move.l	DBM0_len,d7
	cmp.l	FileLen,d7
	bge.s	.done

	tst.l	d3
	beq.s	.zero

	move.l	filehandle,d1
	move.l	a5,d2
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError
.zero
	addq.w	#1,DBM0_DONE2
	cmp.w	#10,DBM0_DONE2
	beq.s	.done
	bra.w	.mainloop

.done
	movem.l	d0-a6,-(sp)
	bsr	ConvertAllTo16BIT
	movem.l	(sp)+,d0-a6
	rts


HEADERS:
	dc.b	"NAME"
	dc.l	DBM0_ReadName

	dc.b	"INFO"
	dc.l	DBM0_ReadInfo

	dc.b	"SONG"
	dc.l	DBM0_ReadSong

	dc.b	"INST"
	dc.l	DBM0_ReadInst

	dc.b	"PATT"
	dc.l	DBM0_ReadPatt

	dc.b	"SMPL"
	dc.l	DBM0_ReadSmpl

	dc.b	"VENV"
	dc.l	DBM0_ReadVenv

	dc.b	"PENV"
	dc.l	DBM0_ReadPenv

	dc.b	"DSPE"
	dc.l	DBM0_ReadDSPecho
	dc.l	-1

DBM0_DONE1:
	dc.w	0
DBM0_DONE2:
	dc.w	0
DBM0_len:
	dc.l	0

DBM0_ReadError:
	moveq	#-1,d0
	jsr	ReadError
	move.w	#2,LoadModError
	rts


DBM0_ReadName:
	move.l	filehandle,d1
	move.l	a5,d2
	move.l	4(a5),d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	move.l	a5,a6
	lea	ModNameBuffer,a4
	moveq	#42-1,d7
.copyname
	move.b	(a6)+,(a4)+
	dbf	d7,.copyname
	moveq	#0,d0
	rts

DBM0_ReadInfo:
	move.l	filehandle,d1
	move.l	a5,d2
	move.l	4(a5),d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	move.w	(a5),InsNum
	move.w	2(a5),SmpNum
	move.w	4(a5),SngNum
	move.w	6(a5),PatNum
	subq	#1,InsNum
	subq	#1,SmpNum
	subq	#1,SngNum
	subq	#1,PatNum
	clr.l	AHI_CHAN
	move.w	8(a5),AHI_CHAN+2
	move.w	8(a5),TrackNumber
	moveq	#0,d0
	rts




DBM0_ReadSong:
	move.l	a5,d2
	move.l	#46,d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	move.l	a5,a6
	lea	SongNameBuffer,a4
	moveq	#42-1,d7
.copyname
	move.b	(a6)+,(a4)+
	dbf	d7,.copyname
	moveq	#0,d0

	move.l	#SongOrders,d2
	moveq	#0,d3
	move.w	44(a5),d3
	subq	#1,d3
	move.w	d3,OrdNum
	addq	#1,d3
	add.w	d3,d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	move.w	SngNum,d7
	tst.w	d7
	beq.w	.notmore
	subq	#1,d7


	lea	SongNameBuffer1,a2
	lea	OrdNum1,a3
	lea	SongOrders1,a4
.more
	move.l	a5,d2
	move.l	#46,d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	movem.l	d0-a6,-(sp)
	move.l	a5,a6
	lea	(a2),a4
	moveq	#42-1,d6
.copyname2
	move.b	(a6)+,(a4)+
	dbf	d6,.copyname2
	movem.l	(sp)+,d0-a6

	move.l	a4,d2
	moveq	#0,d3
	move.w	44(a5),d3
	subq	#1,d3
	move.w	d3,(a3)
	addq	#1,d3
	add.w	d3,d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	addq	#2,a3
	add.l	#44,a2
	add.l	#1025*2,a4

	dbf	d7,.more
.notmore
	moveq	#0,d0
	rts





DBM0_ReadInst:
	move.w	InsNum,d7
	moveq	#0,d6
.instloop
	addq	#1,d6

	move.l	a5,d2
	move.l	#50,d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	lea	InstrNames,a6
	move.l	d6,d5
	mulu	#30,d5
	add.w	d5,a6
	moveq	#30-1,d4
	lea	(a5),a4
.copyname
	move.b	(a4)+,(a6)+
	dbf	d4,.copyname

	lea	Instruments,a6
	move.l	d6,d5
	add.w	d5,d5
	move.w	30(a5),(a6,d5.w)

	lea	SamVol,a6
	move.w	32(a5),d4
	move.b	d4,-1(a6,d6.w)

	lea	SamFin,a6
	move.l	d6,d5
	lsl.w	#2,d5
	move.l	34(a5),(a6,d5.w)

	lea	Ahi_Samples,a6
	move.l	d6,d5
	lsl.w	#4,d5
	move.l	38(a5),8(a6,d5.w)
	move.l	42(a5),12(a6,d5.w)

	lea	LoopTab,a6
	move.l	46(a5),d5
	move.b	d5,(a6,d6.w)

	dbf	d7,.instloop
	moveq	#0,d0
	rts






DBM0_ReadVenv:
	move.l	a5,d2
	move.l	#2,d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	move.w	(a5),d7
	beq.s	.exit
	subq	#1,d7
.venvloop
	move.l	a5,d2
	move.l	#2,d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	lea	VolEnvelope,a0
	moveq	#0,d6
	move.w	(a5),d6
	subq	#1,d6
	mulu	#134,d6
	add.l	d6,a0
	move.l	a0,d2

	move.l	#134,d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	dbf	d7,.venvloop
.exit
	moveq	#0,d0
	rts




DBM0_ReadPenv:
	move.l	a5,d2
	move.l	#2,d3
	jsr	readmem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	move.w	(a5),d7
	beq.s	.exit
	subq	#1,d7
.penvloop
	move.l	a5,d2
	move.l	#2,d3
	jsr	readmem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	lea	PanEnvelope,a0
	moveq	#0,d6
	move.w	(a5),d6
	subq	#1,d6
	mulu	#134,d6
	add.l	d6,a0
	move.l	a0,d2

	move.l	#134,d3
	jsr	readmem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	dbf	d7,.penvloop
.exit
	moveq	#0,d0
	rts


DBM0_ReadDSPecho:
	move.l	a5,d2
	move.l	#2,d3
	jsr	readmem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError


	move.w	(a5),mask1channels
	moveq	#0,d3
	move.w	(a5),d3

	move.l	#mask1channels+2,d2
	jsr	readmem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	move.l	#DSPparamtab,d2
	move.l	#8,d3
	jsr	readmem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	rts



DBM0_ReadPatt:
	move.l	4.w,a6
	moveq	#0,d0
	move.w	TrackNumber,d0
	mulu	#8,d0
	mulu	#256,d0
	addq.l	#8,d0
	move.l	#$10001,d1
	jsr	-198(a6)
	tst.l	d0
	beq	DBM0_ReadError
	addq.l	#8,d0
	move.l	d0,PP_ADR


	lea	PATTLENS,a3
	lea	PATTAdresses,a4

	moveq	#0,d5
	move.w	PATNUM,d5
.onepatt
	move.l	a5,d2
	move.l	#6,d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError


	moveq	#0,d0
	move.w	(a5),d0
;	addq	#1,d0
	move.w	d0,(a3)+
	moveq	#0,d1
	move.w	TrackNumber,d1
	mulu	#6,d1
	mulu	d0,d1
	move.l	d0,d6

; ----------- alloc do rozpakowanego
	move.l	4,a6
	move.l	d1,d0
	addq.l	#8,d0
	move.l	#$10001,d1
	jsr	-198(a6)
	tst.l	d0
	beq	RM_AllocError
	addq.l	#8,d0
	move.l	d0,(a4)+


	move.l	PP_ADR,d2
	move.l	2(a5),d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	movem.l	d0-a6,-(sp)
	move.l	PP_ADR,a0
	move.l	-4(a4),a2
	moveq	#0,d4
	moveq	#0,d5
	move.w	TrackNumber,d4		; tracks
	move.w	-2(a3),d5		; rows
	subq	#1,d5
	bsr	DEPACKPATT
	movem.l	(sp)+,d0-a6

	dbf	d5,.onepatt


	move.l	4.w,a6

	moveq	#0,d0
	move.w	TrackNumber,d0
	mulu	#8,d0
	mulu	#256,d0

	move.l	PP_ADR,a1		;adres zajetej pamieci
	subq.l	#8,a1
	addq.l	#8,d0
	jsr	-210(a6)



	moveq	#0,d0
	rts




DBM0_ReadSmpl:
	move.w	SmpNum,d7
	moveq	#0,d6

.readsample
	move.l	a5,d2
	move.l	#8,d3
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError

	addq	#1,d6
	move.l	4(a5),d3
	tst.l	d3
	beq.w	.doloop

	move.l	(a5),d0


	btst	#0,d0
	bne.s	.8bit

	add.l	d3,d3
	lea	SampleType,a6
	move.b	#1,(a6,d6.w)
	lea	256(a6),a6
	move.b	#1,(a6,d6.w)
	move.l	#AHIST_M16S,AHI_Sound0
	move.w	#1,Mode16BitEn
.8bit


	move.l	d3,d0
	addq.l	#8,d0
	move.l	#$10001,d1
	move.l	4,a6
	jsr	-198(a6)
	tst.l	d0
	beq	RM_AllocErrorDBM0SAM
	addq.l	#8,d0

	move.l	d6,d5
	lsl.w	#4,d5

	lea	Ahi_samples,a6
	tst.l	4(a5)
	beq.s	.qw
	move.l	d0,(a6,d5.w)
.qw
	move.l	4(a5),4(a6,d5.w)
**

	move.l	d0,d2
	jsr	ReadMem
	cmp.l	#-1,d0
	beq.w	DBM0_ReadError
.doloop
	dbf	d7,.readsample



	moveq	#0,d0
	rts




DEPACKPATT:
	mulu	#6,d4
	moveq	#0,d2
	moveq	#0,d3
.depackloop
	moveq	#0,d0
	move.b	(a0)+,d0
	tst.b	d0
	beq.w	.NextPos

	subq	#1,d0
	mulu	#6,d0
	add.l	d3,d0

	moveq	#0,d1
	move.b	(a0)+,d1

	btst	#0,d1
	beq.s	.notakenuta
	move.b	(a0)+,0(a2,d0.l)
.notakenuta
	btst	#1,d1
	beq.s	.notakenum
	move.b	(a0)+,1(a2,d0.l)
.notakenum
	btst	#2,d1
	beq.s	.notakeeffcom1
	move.b	(a0)+,2(a2,d0.l)
.notakeeffcom1
	btst	#3,d1
	beq.s	.notakeeffpar1
	move.b	(a0)+,3(a2,d0.l)
.notakeeffpar1
	btst	#4,d1
	beq.s	.notakeeffcom2
	move.b	(a0)+,4(a2,d0.l)
.notakeeffcom2
	btst	#5,d1
	beq.s	.notakeeffpar2
	move.b	(a0)+,5(a2,d0.l)
.notakeeffpar2
	bra.s	.depackloop

.NextPos:
	addq	#1,d2
	move.l	d2,d3
	mulu	d4,d3

	cmp.w	d2,d5
	bge.s	.depackloop
	rts

ReadMemAdr:	dc.l	0
ReadMemEnd:	dc.l	0
FileLen:	dc.l	0

ReadMem:
	movem.l	d0-a6,-(sp)
	move.l	d2,a0
	move.l	ReadMemAdr,a1
.loop
	cmp.l	ReadMemEnd,a1
	bge.s	.EndOfFile

	move.b	(a1)+,(a0)+
	subq.l	#1,d3
	tst.l	d3
	bne.s	.loop

	move.l	a1,ReadMemAdr

	movem.l	(sp)+,d0-a6
	moveq	#0,d0
	rts

.EndOfFile
	move.l	a1,ReadMemAdr

	movem.l	(sp)+,d0-a6
	moveq	#0,d0
	rts

; -------------------------------------------------------

RM_ReadError:
	moveq	#0,d7
	move.w	#1,LoadModError
	jsr	ReadError
	rts

RM_AllocErrorDBM0SAM
	moveq	#0,d7
	move.w	#1,LoadModError
	jsr	NotEnoughMemoryError
	move.l	#AHIST_M8S,AHI_Sound0
	move.w	#0,Mode16BitEn
	rts

RM_AllocError:
	moveq	#0,d7
	move.w	#1,LoadModError
	jsr	NotEnoughMemoryError
	rts

RM_AllocSamError:
	clr.l	(a4)
	clr.l	4(a4)
	clr.l	8(a4)
	clr.l	12(a4)
	moveq	#0,d7
	move.w	#1,LoadModError
	jsr	NotEnoughMemoryError
	rts


ChanArea	equ	118

VolA:		equ	0	; 2
SlideVolOldA	equ	2	; 1
OldGlobalVolA	equ	3	; 1

VolB:		equ	4	; 2
SlideVolOldB	equ	6	; 1
OldGlobalVolB	equ	7	; 1

OLDVolA:	equ	8	; 2
OLDVolB:	equ	10	; 2
SlideSamOffset	equ	12	; 2
OldSlideOffsetA	equ	14	; 1
OldSlideOffsetB	equ	15	; 1
MainVol:	equ	16	; 2

;ReplaceEnable	equ	18	; 1

OFFenable	equ	19	; 1
SamOffsetA	equ	20	; 1
SamOffsetB	equ	21	; 1
RetraceCntA	equ	22	; 1
RetraceCntB	equ	23	; 1
OldInstrNumA:	equ	24	; 1
OldInstrNumB:	equ	25	; 1

OrgPeriod	equ	26	; 2
MainPeriod:	equ	28	; 2
OldPeriod:	equ	30	; 2
OrgPeriodARP	equ	32	; 2
Oldd0		equ	34	; 2
Oldd1		equ	36	; 2
Oldd2		equ	38	; 2
Oldd3		equ	40	; 2
Oldd4		equ	42	; 2
Oldd5		equ	44	; 2
Oldd6		equ	46	; 2
loopsdataschanA	equ	48	; 4
loopsdataschanB	equ	52	; 4

EqNewSamA	equ	56	; 1
EqNewSamB	equ	57	; 1

VolEnvTime	equ	58	; 2
VolEnvOff	equ	60	; 1
VolEnvMode	equ	61	; 1

PortUpOldValA	equ	62	; 1
PortUpOldValB	equ	63	; 1
PortDownOldValA	equ	64	; 1
PortDownOldValB	equ	65	; 1
VibratoDatasA	equ	66	; 4
VibratoDatasB	equ	70	; 4
GlissandoDatasA	equ	74	; 6
GlissandoDatasB	equ	80	; 6

NoteDelayPeriodA	equ	86	; 2
NoteDelayInstrNumA	equ	88	; 2
NoteDelayPeriodB	equ	90	; 2
NoteDelayInstrNumB	equ	92	; 2

PanPos		equ	94	; 4		; it is a calculated panning

OnOffChanA	equ	98	; 1
OnOffChanB	equ	99	; 1

PanEnvTime	equ	100	; 2
PanEnvOff	equ	102	; 1
PanEnvMode	equ	103	; 1

GeneralPan	equ	104	; 2		; it is a default pan 
						; changeable by 8xx e8x and
						; general pan parameter in pan env
						; range (0-256)

OldMainVol:	equ	106	; 2
OldPanPos:	equ	108	; 4

SlidePanOldA	equ	112	; 1
SlidePanOldB	equ	113	; 1

LastFreq	equ	114	; 4
;----------------------------------------------


ahibase:	dc.l	0
ahi_ctrl:	dc.l	0

ahi_ctrltags:
        dc.l	AHIC_Play,1
        dc.l	TAG_DONE
ahi_tags
        dc.l	AHIA_MixFreq
ahi_freq
        dc.l	32600
        dc.l	AHIA_Channels
ahi_chan:
        dc.l	8
        dc.l	AHIA_Sounds,1
        dc.l	AHIA_AudioID
ahi_audioid
        dc.l	$00020002	; 2 pan, 4 stereo, 6 mono   8 8bit pan
        dc.l	AHIA_SoundFunc,SoundFunc
        dc.l	AHIA_PlayerFunc,PlayerFunc
        dc.l	AHIA_PlayerFreq,50<<16
        dc.l	AHIA_MinPlayerFreq,(8*2/5)<<16
        dc.l	AHIA_MaxPlayerFreq,(600*2/5)<<16
        dc.l	TAG_DONE

ahi_sound0:
        dc.l	AHIST_M8S
ahi_sta	dc.l	0	        ; start
ahi_len	dc.l	-1                ; len

AHI_VOLBOOST:
        dc.l	Ahiet_MasterVolume
AHIBoost
        dc.l	$10000
        dc.l	TAG_DONE


AHI_DSPEFF:
	dc.l    AHIET_DSPECHO    ; ahie_Effect

DSPECHODELAY
	dc.l	0		; ahiede_Delay

DSPECHOFEEDBACK
	dc.l    $8000            ; ahiede_Feedback

DSPECHOMIX
	dc.l    $8000            ; ahiede_Mix

DSPECHOCROSS
	dc.l    $10000           ; ahiede_Cross
	dc.l	TAG_DONE




PlayerFunc:
        blk.b	MLN_SIZE
        dc.l	mmusic
        dc.l	0
        dc.l	0

SoundFunc:
        blk.b	MLN_SIZE
        dc.l	soundfunc2
        dc.l	0
        dc.l	0


;in:
* a0        struct Hook *                  
* a1        struct AHISoundMessage *         
* a2        struct AHIAudioCtrl *           


soundfunc2:
	movem.l	d2-d4/a6,-(sp)
	moveq	#0,d0
	move.w	ahism_Channel(a1),d0
	lea	ahi_channels,a0
	lsl.w	#2,d0
	move.w	2(a0,d0.w),d1
	and.w	#$00ff,d1
	move.w	(a0,d0.w),d7
	lsl.l	#4,d1


	lea	ahi_samples,a0
	move.l	(a0,d1.w),d2			;sample start
	cmp.l	#0,Ahi_Sound0
	beq.s	.no16bit_1
	lsr.l	#1,d2
.no16bit_1

	tst.w	NoLoopEnable
	beq.s	.noloop1
	moveq	#0,d3
	bra.s	.noloop2
.noloop1

	add.l	8(a0,d7.w),d2			;repeat start
	move.l	12(a0,d7.w),d3			;repeat length

.noloop2

	moveq	#0,d4				;NOTE: AHISF_IMM *NOT* SET!!
;----------------------------
	lea	LoopTab,a0
	move.w	d7,d1
	moveq	#0,d7
	lsr.w	#4,d1
	btst	#1,(a0,d1.w)
	beq.s	.nopingpong
	moveq	#0,d4
	lea	ahi_channels,a0
	move.b	2(a0,d0.w),d4
	subq.w	#1,d4
	muls	#-1,d4
	move.b	d4,2(a0,d0.w)
	moveq	#1,d7
.nopingpong
;----------------------------

	lsr.l	#2,d0				; chnnum
	moveq	#0,d1				;sample bank

	tst.l	d3
	beq.w	.length_0

	tst.w	d7				; gdy ping pong loop
	bne.w	.pingpongproc

	cmp.w	#32,d0				; tylko dla 32 kanalow
	bgt.w	.length_ok
	cmp.l	#512,d3
	bge.w	.length_ok

	cmp.l	#0,Ahi_Sound0			; gdy 16 bit to olewa i skacze do proc2
	bne.s	.16bitproc

.8bitproc:
	movem.l	d0-d1/d4-a2,-(sp)

	lea	SamBuff,a0
	mulu	#1024+(16),d0
	add.w	d0,a0

	cmp.l	(a0),d2
	bne.s	.notakedata
	cmp.l	4(a0),d3
	beq.s	.takedata
.notakedata
	move.l	d2,(a0)
	move.l	d3,4(a0)

	add.l	#16,a0
	move.l	d2,a1
	move.l	a0,d2
	move.l	d2,-8(a0)

	move.l	d3,d7
	move.l	#1024,d6
	divu	d7,d6
	and.l	#$ffff,d6
	move.l	d7,d3
	mulu	d6,d3
	move.l	d3,-4(a0)

	subq	#1,d6
	subq	#1,d7
	move.l	a1,d4
	move.l	d7,d5
.makebuffloopM
	move.l	d4,a1
	move.l	d5,d7
.makebuff
	move.b	(a1)+,(a0)+
	dbf	d7,.makebuff
	dbf	d6,.makebuffloopM
	bra.s	.makebuffdone
.takedata
	move.l	8(a0),d2
	move.l	12(a0),d3
.makebuffdone
	movem.l	(sp)+,d0-d1/d4-a2
	bra.w	.length_ok





.16bitproc:
	cmp.l	#512/2,d3
	bge.w	.length_ok

	movem.l	d0-d1/d4-a2,-(sp)

	lea	SamBuff,a0
	mulu	#1024+(16),d0
	add.w	d0,a0

	cmp.l	(a0),d2
	bne.s	.notakedata16
	cmp.l	4(a0),d3
	beq.s	.takedata16
.notakedata16
	move.l	d2,(a0)
	move.l	d3,4(a0)

	add.l	#16,a0
	move.l	d2,a1
	add.l	d2,a1
	move.l	a0,d2
	move.l	d2,-8(a0)

	move.l	d3,d7
	move.l	#1024/2,d6
	divu	d7,d6
	and.l	#$ffff,d6
	move.l	d7,d3
	mulu	d6,d3
	move.l	d3,-4(a0)

	subq	#1,d6
	subq	#1,d7
	move.l	a1,d4
	move.l	d7,d5
.makebuffloopM16
	move.l	d4,a1
	move.l	d5,d7
.makebuff16
	move.w	(a1)+,(a0)+
	dbf	d7,.makebuff16
	dbf	d6,.makebuffloopM16
	bra.s	.makebuffdone16
.takedata16
	move.l	8(a0),d2
	move.l	12(a0),d3
.makebuffdone16
	cmp.l	#0,Ahi_Sound0
	beq.s	.no16bit_2
	lsr.l	#1,d2
.no16bit_2
	movem.l	(sp)+,d0-d1/d4-a2
	bra.w	.length_ok





.pingpongproc:
	cmp.w	#32,d0				; tylko dla 32 kanalow
	bgt.w	.length_ok
	cmp.l	#512/2,d3			; ping pong musi miec parzyste
	bge.w	.length_ok


	cmp.l	#0,Ahi_Sound0			; gdy 16 bit to olewa i skacze do proc2
	bne.w	.16bitprocpp


.8bitproc_pp:
	movem.l	d0-d1/d4-a2,-(sp)

	lea	SamBuff,a0
	mulu	#1024+(16),d0
	add.w	d0,a0

	cmp.l	(a0),d2
	bne.s	.notakedata_pp
	cmp.l	4(a0),d3
	beq.s	.takedata_pp
.notakedata_pp
	move.l	d2,(a0)
	move.l	d3,4(a0)

	add.l	#16,a0
	move.l	d2,a1
	move.l	a0,d2
	move.l	d2,-8(a0)

	move.l	d3,d7
	move.l	#1024,d6
	divu	d7,d6
	and.l	#$ffff,d6
	move.l	d7,d3
	mulu	d6,d3
	move.l	d3,-4(a0)

	lsr.l	#1,d6		; dziele przez dwa ilosc petli bo jest ping pong

	subq	#1,d6
	subq	#1,d7
	move.l	a1,d4
	move.l	d7,d5
.makebuffloopM_pp
	move.l	d4,a1
	move.l	d5,d7
.makebuff_pp
	move.b	(a1)+,(a0)+
	dbf	d7,.makebuff_pp


;	move.l	d4,a1
	move.l	d5,d7
.makebuff_pp2
	move.b	-(a1),(a0)+
	dbf	d7,.makebuff_pp2


	dbf	d6,.makebuffloopM_pp
	bra.s	.makebuffdone_pp
.takedata_pp
	move.l	8(a0),d2
	move.l	12(a0),d3
.makebuffdone_pp
	movem.l	(sp)+,d0-d1/d4-a2

	moveq	#0,d4
	bra.w	.length_ok







.16bitprocpp:
	cmp.l	#512/2/2,d3
	bge.w	.length_ok

	movem.l	d0-d1/d4-a2,-(sp)

	lea	SamBuff,a0
	mulu	#1024+(16),d0
	add.w	d0,a0

	cmp.l	(a0),d2
	bne.s	.notakedata16pp
	cmp.l	4(a0),d3
	beq.s	.takedata16pp
.notakedata16pp
	move.l	d2,(a0)
	move.l	d3,4(a0)

	add.l	#16,a0
	move.l	d2,a1
	add.l	d2,a1
	move.l	a0,d2
	move.l	d2,-8(a0)

	move.l	d3,d7
	move.l	#1024/2,d6
	divu	d7,d6
	and.l	#$ffff,d6
	move.l	d7,d3
	mulu	d6,d3
	move.l	d3,-4(a0)

	lsr.l	#1,d6		; dziele przez dwa ilosc petli bo jest ping pong

	subq	#1,d6
	subq	#1,d7
	move.l	a1,d4
	move.l	d7,d5
.makebuffloopM16pp


	move.l	d4,a1
	move.l	d5,d7
.makebuff16pp
	move.w	(a1)+,(a0)+
	dbf	d7,.makebuff16pp

;	move.l	d4,a1
	move.l	d5,d7
.makebuff16pp2
	move.w	-(a1),(a0)+
	dbf	d7,.makebuff16pp2


	dbf	d6,.makebuffloopM16pp
	bra.s	.makebuffdone16pp
.takedata16pp
	move.l	8(a0),d2
	move.l	12(a0),d3
.makebuffdone16pp
	cmp.l	#0,Ahi_Sound0
	beq.s	.no16bit_2pp
	lsr.l	#1,d2
.no16bit_2pp
	movem.l	(sp)+,d0-d1/d4-a2

	moveq	#0,d4
	bra.w	.length_ok





.length_0
	moveq	#AHI_NOSOUND,d1
.length_ok

	lea	SampleOffsets,a6

	cmp.l	#AHI_NOSOUND,d1
	bne.s	.nozero
	cmp.l	(a6,d0.w*4),d2
	beq.s	.nozero

; --------------------------------------- ;
	lea	SampleOffsetsFT,a6
	tst.b	(a6,d0.w)
	beq.s	.okft1
	clr.b	(a6,d0.w)
	bra.s	.nozero
.okft1
; ^-------------------------------------- ;

	lea	SampleOffsets,a6
	move.l	#0,(a6,d0.w*4)			;start
.nozero

	cmp.l	#0,(a6,d0.w*4)	
	beq.s	.zero

	lea	SampleOffsetsFT,a6
	tst.b	(a6,d0.w)
	beq.s	.okft2
	clr.b	(a6,d0.w)
	bra.s	.zero
.okft2
; ^-------------------------------------- ;
	lea	SampleOffsets,a6
	move.l	d2,(a6,d0.w*4)			;start
.zero


	tst.b	d4
	beq.s	.nopingpong2

	subq.l	#1,d3
	add.l	d3,d2
	subq.l	#1,d2
	not.l	d3
	bra.s	.yapingpong
.nopingpong2
	tst.w	d7
	beq.s	.yapingpong
	cmp.l	#0,(a6,d0.w*4)	
	beq.s	.yapingpong
	add.l	d3,(a6,d0.w*4)			;start
.yapingpong
	moveq	#0,d4				;NOTE: AHISF_IMM *NOT* SET!!
	move.l	ahibase(pc),a6
	jsr	_LVOAHI_SetSound(a6)

	movem.l	(sp)+,d2-d4/a6
.exit	rts


lastinstrnum:	dc.w	0

mmusic:
	movem.l	d0-a6,-(sp)

	move.l	mainvolume(pc),a0
	move	(a0),MasterVol


	bsr.w	db_music

;   	cmp.w	#1,MIXITENABLE
;	bne.s	.ominit
;	moveq	#0,d0
;	move.w	EndSongPos,d0
;	cmp.w	SOngPos,d0
;	bne.s	.ominit
;
;
;	moveq	#0,d0
;	move.w	SongPos,d0
;	add.w	d0,d0
;	lea	SongOrders,a0
;	move.w	(a0,d0.w),d0
;	add.w	d0,d0
;	lea	PattLens,a0
;	move.w	(a0,d0.w),d0
;	subq	#1,d0
;
;	moveq	#0,d1
;	move.w	PattPos,d1
;	cmp.w	d0,d1
;	bne.s	.ominit
;	move.w	#1,StopITNOW
;.ominit
	tst.w	StopEnable
	beq.s	No_clr_volumes
	bsr	stop_play
No_clr_volumes
	movem.l	(sp)+,d0-a6
	rts

clr_volumes:
	moveq	#0,d0
	moveq	#0,d1
	move.w	TrackNumber,d7
	subq	#1,d7
init_vols
	movem.l	d0-a6,-(sp)
	bsr.w	ahi_volume
	movem.l	(sp)+,d0-a6
	addq	#1,d0
	dbf	d7,init_vols
	rts

stop_play:
	clr.w	StopEnable
	moveq	#0,d0
	moveq	#0,d1
	move.w	TrackNumber,d7
	subq	#1,d7
clr_vols
	movem.l	d0-a6,-(sp)
	moveq	#AHISF_IMM,d4
	moveq	#AHI_NOSOUND,d1
	move.l	ahibase,a6
	move.l	ahi_ctrl,a2
	jsr	_LVOAHI_SetSound(a6)
	movem.l	(sp)+,d0-a6
	addq	#1,d0
	dbf	d7,clr_vols
	rts


FreeShortSamBuff:
	movem.l	d0-a6,-(sp)
	lea	SamBuff,a0
	moveq	#32-1,d7
.freeshortsambuffloop
	clr.l	(a0)
	clr.l	4(a0)
	add.l	#1024+16,a0
	dbf	d7,.freeshortsambuffloop
	movem.l	(sp)+,d0-a6
	rts

ahi_init:
.retry	bsr.w	ahi_initmain
	tst.l	d0
	beq.s	.ok
	bsr.w	OpenAhiError2
	bra	.retry
.ok	rts


ahi_initstart:
	bsr.w	ahi_initmain
	rts

ahi_initmain:
	OPENAHI 1
	move.l	d0,ahibase
	beq.w	ahi_eror_at_start

	move.l	d0,a6
	lea	ahi_tags(pc),a1
	jsr	_LVOAHI_AllocAudioA(a6)
	move.l	d0,ahi_ctrl
	beq.w	ahi_eror

	move.l	d0,a2
	moveq	#0,d0				;Load module as one sound!
	moveq	#AHIST_SAMPLE,d1
	lea	ahi_sound0(pc),a0
	jsr	_LVOAHI_LoadSound(a6)
	tst.l	d0
	bne.w	ahi_eror_allocaudio_ok

	lea	ahi_ctrltags(pc),a1
	jsr	_LVOAHI_ControlAudioA(a6)
	tst.l	d0
	bne.w	ahi_eror_allocaudio_ok

	move.w	CiaTempo,d7

	movem.l	d0-d6/a0-a6,-(sp)
	moveq	#0,d0
	moveq	#0,d1
	move.w	RealTempo,d0
	move.w	d7,d1
	lsl.l	#8,d0
	divu	#125,d0
	and.l	#$ffff,d0
	mulu	d0,d1
	lsr.l	#8,d1
	move.w	d1,d7
	movem.l	(sp)+,d0-d6/a0-a6

	and.l	#$ffff,d7
	lsl.w	#1,d7
	divu	#5,d7
	and.l	#$ffff,d7
	swap	d7
	move.l	d7,afreq

	move.l	ahibase(pc),a6
	lea	atags(pc),a1
	move.l	ahi_ctrl(pc),a2
	jsr	_LVOAHI_ControlAudioA(a6)

	move.l	ahibase,a6
	move.l	#AHI_VOLBOOST,a0

	tst.w	AutoBoostEn
	beq.s	.nieauto

	move.l	20(a6),d0
	cmp.l	#$40063,d0
	blt.s	.nieauto

	moveq	#0,d0
	move.w	TrackNumber,d0
	mulu	#$4000,d0
	tst.w	MixItEnable
	bne.s	.nieauto
	move.l	d0,AhiBoost
.nieauto
	move.l	ahi_ctrl,a2
	jsr	_LVOAHI_Seteffect(a6)

	movem.l	d0-a6,-(sp)
	jsr	UpdateEffects
	movem.l	(sp)+,d0-a6

	moveq	#0,d0
	rts

ahi_eror_at_start:
	CLOSEAHI
	moveq	#-1,d0
	rts

ahi_eror:
	CLOSEAHI
	moveq	#-1,d0
	rts


ahi_eror_allocaudio_ok:
	move.l	ahibase(pc),d0
	beq.w	.exit
	move.l	ahibase(pc),d0
	move.l	d0,a6
	move.l	ahi_ctrl(pc),a2
	jsr	_LVOAHI_FreeAudio(a6)

	CLOSEAHI
.exit
	moveq	#-1,d0
	rts

ahi_end:
	move.l	ahibase(pc),d0
	beq.w	.exit

	move.l	ahibase(pc),a6
	lea	AHI_VOLBOOST,a0
	or.l	#AHIET_CANCEL,ahie_Effect(a0)
	move.l	ahi_ctrl(pc),a2
	jsr	_LVOAHI_Seteffect(a6)
	lea	AHI_VOLBOOST,a0
	eor.l	#AHIET_CANCEL,ahie_Effect(a0)

	bsr	EchoOff

	move.l	ahibase(pc),d0
	move.l	d0,a6
	move.l	ahi_ctrl(pc),a2
	jsr	_LVOAHI_FreeAudio(a6)

	CLOSEAHI


	lea	channel1,a0
	move.w	TrackNumber,d7
	subq	#1,d7
.clr	clr.w	MainVol(a0)
	clr.w	MainPeriod(a0)
	lea	ChanArea(a0),a0
	dbf	d7,.Clr

.exit
	rts



EchoEn:		dc.w	0

EchoON:
; ---------------------------------------;
	move.w	Ahi_Chan+2,d7
	move.w	d7,mask1channels

	lea	mask1channels+2,a0
	subq	#1,d7
.test
	cmp.b	#AHIEDM_WET,(a0)+
	beq.s	.mam
	dbf	d7,.test
	tst.w	EchoEn
	bne.s	EchoOffMain
	rts
.mam
; ---------------------------------------;
	clr.w	EchoEn
	move.l	ahibase,a6
	lea	mask1struct(pc),a0
	move.l	ahi_ctrl,a2
	jsr	_LVOAHI_Seteffect(a6)


	move.l	ahibase,a6
	move.l	#AHI_DSPEFF,a0
	move.l	ahi_ctrl,a2
	jsr	_LVOAHI_Seteffect(a6)
	rts








EchoOFF:
; ---------------------------------------;
	move.w	Ahi_Chan+2,d7
	move.w	d7,mask1channels

	lea	mask1channels+2,a0
	subq	#1,d7
.test
	cmp.b	#AHIEDM_WET,(a0)+
	beq.s	.mam
	dbf	d7,.test
	rts
.mam
; ---------------------------------------;
EchoOffMain
	clr.w	EchoEn
	move.l	ahibase(pc),a6
	lea	mask1struct(pc),a0
	or.l	#AHIET_CANCEL,ahie_Effect(a0)
	move.l	ahi_ctrl(pc),a2
	jsr	_LVOAHI_Seteffect(a6)
	lea	mask1struct(pc),a0
	eor.l	#AHIET_CANCEL,ahie_Effect(a0)

	move.l	ahibase(pc),a6
	lea	AHI_DSPEFF,a0
	or.l	#AHIET_CANCEL,ahie_Effect(a0)
	move.l	ahi_ctrl(pc),a2
	jsr	_LVOAHI_Seteffect(a6)
	lea	AHI_DSPEFF,a0
	eor.l	#AHIET_CANCEL,ahie_Effect(a0)
	rts


mask1struct
	dc.l    AHIET_DSPMASK
mask1channels
	dc.w    0
	blk.b	128,AHIEDM_DRY
	dc.l	TAG_DONE





db_init:
	move.w	GeneralTempo,CiaTempo
	moveq	#0,d0
	move.w	GeneralSpeed,d0
	move.b	d0,Orgtemp

	clr.w	SongPos
	clr.w	PattPos
	clr.b	Count

	bset	#1,$bfe001
	move.b	Orgtemp,Count
	rts

CheckCpu:
	move.l	ExecBase,a6
	moveq	#0,d0
	move.b	297(a6),d0

	move.b	#1,OldCPU
MC68000:
	btst	#0,d0
	beq.s	MC68010
	move.b	#1,OldCPU
MC68010:
	btst	#1,d0
	beq.s	MC68020
	clr.b	OldCPU
MC68020:
	btst	#2,d0
	beq.s	MC68030
	clr.b	OldCPU
MC68030:
	btst	#3,d0
	beq.s	MC68040
	clr.b	OldCPU
MC68040:
	rts
	
SongPos:	dc.w	0
PattPos:	dc.w	0
OldPattPos:	dc.w	0

OldCPU:		dc.b	0
temp:		dc.b	0
count:		dc.b	0
count2:		dc.b	0
JMPEN:		dc.b	0
PauseEn:	dc.b	0
hisam:		dc.b	0
		even

PauseVBL:	dc.w	0
OldDepAdr:	dc.l	0
;modDIGI:	dc.l	0
channelenable:	dc.w	0
MixPeriodA:	dc.w	0
MixPeriodB:	dc.w	0
leng:		dc.w	0
whichchan:	dc.w	0
CiaTempo:	dc.w	0
CiaChanged:	dc.w	0
GlobalVol:	dc.w	64
OldGlobalVol:	dc.w	0

; ------------------- Paremeters --------------


db_music:
; free a0,a2,a3,

	move.b	count2(pc),d7
	cmp.b	temp(pc),d7
	blt.s	.NoNewPos
	clr.b	count2
.NoNewPos



	tst.b	temp
	beq.s	DepackDone

	move.b	count(pc),d7
	cmp.b	temp(pc),d7
	blt.s	DepackDone

	moveq	#0,d6
	moveq	#0,d7
	move.w	OrdNum,d7
	move.w	SongPos(pc),d6
	cmp.w	d6,d7
	bge.s	NoRepeatSong
	clr.w	SongPos
	clr.w	PattPos

	move.l	songover(pc),a0
	st	(a0)
	
NoRepeatSong:

	moveq	#0,d7
	move.w	SongPos(pc),d7
	lea	SongOrders,a0
	move.w	(a0,d7.w*2),d7
	lea	PattAdresses,a1
	move.l	(a1,d7.w*4),a1

	move.w	PattPos(pc),d7
	moveq	#0,d6
	move.w	TrackNumber,d6
	mulu	#6,d6
	mulu	d6,d7
	add.l	d7,a1

	lea	UnPackedData,a6
	move.l	d6,d7
	lsr.w	#2,d7
	subq	#1,d7
CopyDataLoop
	move.l	(a1)+,(a6)+
	dbf	d7,CopyDataLoop

DepackDone

DB_musicMAIN:

	lea	UnPackedData,a1

***************
	tst.b	SPAHIENABLE
	bne.w	ominplaykey
***************

	moveq	#0,d6
	moveq	#0,d0
	lea	Channel1,a6
	moveq	#0,d7
	move.w	TrackNumber,d7
	subq	#1,d7
channelsloopM:
	movem.l	d0/d7/a6,-(sp)

; -------------------------------------------------------
	move.w	MainVol(a6),d1
	cmp.w	OldMainVol(a6),d1
	bne.s	.doit0

	move.w	GlobalVol(pc),d1
	cmp.w	OldGlobalVol(pc),d1
	bne.s	.doit0

	move.w	MasterVol(pc),d1
	cmp.w	OldMasterVol(pc),d1
	bne.s	.doit0

	move.l	PanPos(a6),d1
	cmp.l	OldPanPos(a6),d1
	beq.s	.skip0
.doit0
	bsr.w	ahi_volume
	move.w	MainVol(a6),OldMainVol(a6)
	move.l	PanPos(a6),OldPanPos(a6)
.skip0

	moveq	#0,d1
	move.w	MainPeriod(a6),d1
	beq.s	.skip1
	cmp.w	OldPeriod(a6),d1
	bne.s	.doit1

	move.w	RealTempo(pc),d2
	cmp.w	OldRealTempo(pc),d2
	beq.s	.skip1

.doit1
	bsr	ahi_period
.skip1
	move.w	MainPeriod(a6),OldPeriod(a6)


	lea	SampleOffsets,a4
	tst.l	(a4,d0.w*4)
	beq.s	.zero

	move.l	LastFreq(a6),d2

	lea	LoopTab,a5
	move.w	OldD1(a6),d1
	lsr.w	#2,d1
	addq	#1,d1

	lea	ahi_channels,a3
	move.b	2(a3,d0.w*4),d4

	btst	#1,(a5,d1.w)
	beq.s	.nopingpong
	eor.b	#1,d4
.nopingpong
	tst.b	d4
	beq.s	.add
	sub.l	d2,(a4,d0.w*4)
	bra.s	.zero
.add
	add.l	d2,(a4,d0.w*4)

.zero
	moveq	#0,d1
	move.w	OldD1(a6),d1
	bsr	ahi_sample

; -------------------------------------------------------
	movem.l	(sp)+,d0/d7/a6
	lea	ChanArea(a6),a6
	addq	#1,d0
	dbf	d7,ChannelsLoopM

	move.w	MasterVol(pc),OldMasterVol
	move.w	GlobalVol(pc),OldGlobalVol

***************
	bra.s	noominplaykey
ominplaykey
	clr.b	SPAHIENABLE
noominplaykey
***************


	move.w	SongPos(pc),OldSPos

	lea	channel1,a6
	lea	SamVol,a4
	bsr	MIXCHAN


;	tst.w	EchoEn2
;	bne.s	.mam
	tst.w	EchoEn
	beq.s	.noEchoChanged
.mam
	movem.l	d0-a6,-(sp)
	bsr.w	EchoOn
	movem.l	(sp)+,d0-a6
.noEchoChanged

	tst.b	temp
	beq.w	No_new

	tst.w	PauseVBL
	beq.s	NoPause
	move.b	#1,PauseEn
	subq.w	#1,PauseVBL
NoPause:

	move.b	count(pc),d7
	cmp.b	temp(pc),d7
	blt.s	NoNEWPos
	clr.b	count

	tst.w	PauseVBL
	bne.s	DoPAUSE

	addq.w	#1,pattpos
	clr.b	PauseEn

	tst.b	temp
	beq.s	NoNewPos

	move.l	a0,-(sp)
	moveq	#0,d7
	move.w	SongPos(pc),d7
	lea	SongOrders,a0
	add.w	d7,d7
	move.w	(a0,d7.w),d7
	lsl.w	#1,d7
	lea	PattLens,a0
	move.w	(a0,d7.w),d7
	move.l	(sp)+,a0

	moveq	#0,d3
	move.w	PattPos,d3
	cmp.w	d7,d3
	blt.s	NoNewPos
.newpos
	clr.w	PattPos
	addq.w	#1,SongPos
NoNewPos:

DoPAUSE
	addq.b	#1,count
	addq.b	#1,count2
*
	tst.w	PlayPattEn
	beq.s	.ok
	move.w	OldSpos,d7
	cmp.w	SongPos(pc),d7
	beq.s	.ok
	move.w	d7,SongPos
.ok
*
No_NEW
	move.w	RealTempo,OldRealTempo
	rts


ahi_volume:
	movem.l	d0-d3/a0-a2/a6,-(sp)

	moveq	#0,d1
	move.w	MainVol(a6),d1
	cmp.l	#$40*256,d1
	ble.s	.okV1
	move.l	#$40*256,d1
.okV1

	move.w	GlobalVol(pc),d2
	cmp.w	#$40,d2
	ble.s	.okV2
	moveq	#$40,d2
.okV2
	mulu.w	d2,d1
	lsr.l	#6,d1

	move.w	MasterVol(pc),d2
	cmp.w	#$40,d2
	ble.s	.okV3
	moveq	#$40,d2
.okV3
	mulu.w	d2,d1
	lsr.l	#4,d1


	move.l	PanPos(a6),d2

	move.l	ahibase(pc),a6

	movem.l	d0-a6,-(sp)
	moveq	#AHISF_IMM,d3
	move.l	ahi_ctrl,a2
	jsr	_LVOAHI_SetVol(a6)
	movem.l	(sp)+,d0-a6

	movem.l	(sp)+,d0-d3/a0-a2/a6
	rts

ahi_period:
	movem.l	d0-d2/a0-a2/a6,-(sp)

	move.l	#3546895*4,d2
	divu.l	d1,d2
	move.l	d2,d1


	moveq	#0,d7
	move.w	RealTempo,d7
	cmp.w	OldRealTempo,d7
	bne.s	.doit

	moveq	#0,d7
	move.w	Mainperiod(a6),d7
	cmp.w	OldPeriod(a6),d7
	beq.w	.nonote
.doit
	movem.l	d0/d2-a6,-(sp)
	move.l	d1,d2
	moveq	#0,d1
	move.l	#125,d0
	move.w	RealTempo,d1
	lsl.l	#8,d1
	divu	d0,d1
	and.l	#$ffff,d1
	lsr.l	#2,d2
	mulu.l	d1,d2
	lsr.l	#6,d2
	move.l	d2,d1
	movem.l	(sp)+,d0/d2-a6


	;cmp.l	#2^20,d1
	cmp.l	#1<<20,d1
	ble.s	.ok
	clr.b	OffEnable(a6)
	moveq	#AHISF_IMM,d4
	moveq	#AHI_NOSOUND,d1
	move.l	ahibase,a6
	move.l	ahi_ctrl,a2
	jsr	_LVOAHI_SetSound(a6)
	bra.s	.exit
.ok

	move.l	d1,-(sp)
	divu	#50,d1
	and.l	#$ffff,d1
	mulu	#125,d1
	divu.w	RealCiaTempo(pc),d1
	and.l	#$ffff,d1
	move.l	d1,LastFreq(a6)
	move.l	(sp)+,d1

	move.l	ahibase,a6
	moveq	#AHISF_IMM,d2
	move.l	ahi_ctrl,a2
	jsr	_LVOAHI_SetFreq(a6)
.exit
.nonote

	movem.l	(sp)+,d0-d2/a0-a2/a6
	rts

RealCiaTempo	dc.w	125
RealTempo:	dc.w	125
OldRealTempo:	dc.w	0
MasterVol:	dc.w	64
OldMasterVol:	dc.w	0

ahi_sample:
	movem.l	d0-d2/a0-a2/a6,-(sp)

	tst.b	OffEnable(a6)
	beq.w	.exit
	clr.b	OffEnable(a6)


	moveq	#0,d3
	cmp.w	#$e40,Oldd2(a6)
	beq.w	.playmain
	cmp.w	#$e40,Oldd6(a6)
	beq.w	.playmain

	move.w	Oldd2(a6),d2
	lsr.w	#8,d2
	cmp.b	#3,d2
	beq.w	.exit
	cmp.b	#5,d2
	beq.w	.exit
	move.w	Oldd6(a6),d6
	lsr.w	#8,d6
	cmp.b	#3,d6
	beq.w	.exit
	cmp.b	#5,d6
	beq.w	.exit

; ---------------------- calc sam offset
	moveq	#0,d4
	moveq	#0,d7
	move.b	SamOffsetA(a6),d7
	lsl.w	#8,d7
	lsl.l	#8,d7

	cmp.b	#$9,d2
	bne.s	.nosamoffset1
	add.l	d7,d4
	moveq	#0,d7
	move.w	OldD2(a6),d7
	and.w	#$00ff,d7
	lsl.w	#8,d7
	add.l	d7,d4
	lsr.w	#8,d7
	tst.w	d7
	beq.s	.nosend1
	move.w	d7,SlideSamOffset(a6)
.nosend1
	moveq	#0,d7
.nosamoffset1
	cmp.b	#$9,d6
	bne.s	.nosamoffset2
	add.l	d7,d4
	moveq	#0,d7
	move.w	OldD6(a6),d7
	and.w	#$00ff,d7
	lsl.w	#8,d7
	add.l	d7,d4
	move.l	d4,d7
	lsr.l	#8,d7
	tst.w	d7
	beq.s	.nosend2
	move.w	d7,SlideSamOffset(a6)
.nosend2
.nosamoffset2

	moveq	#0,d4
	move.w	SlideSamOffset(a6),d4
	lsl.l	#8,d4
; --------------------------------------


	lea	Instruments,a0
	move.l	d1,d7
	lsl.w	#2,d7
	add.l	#16,d7
	and.l	#$ffff,d7

	lsr.l	#1,d1
	moveq	#0,d2
	move.w	2(a0,d1.w),d2

; -------------------------------- do sample cursora
	cmp.w	InstrNum,d2
	bne.s	.notthis
	move.w	d0,ACTCHAN
.notthis
; ----------------------------------------------------

	subq	#1,d2
	lsl.l	#2,d2
	move.l	d2,d1

	move.l	d1,d2
	addq.l	#4,d2
	lsr.l	#2,d2
	lea	ahi_channels,a0
	move.l	d2,(a0,d0.l*4)			;store instr for each channel
	move.w	d7,(a0,d0.l*4)

	addq.l	#4,d1
	lsl.l	#2,d1

	lea	ahi_samples,a0
	move.l	(a0,d1.l),d2			;start

	cmp.l	#0,Ahi_Sound0
	beq.s	.no16bit_1
	lsr.l	#1,d2
.no16bit_1

	add.l	d4,d2
	move.l	4(a0,d1.l),d3			;length

	move.l	d7,d1


	sub.l	d4,d3
	bgt.s	.NieWyszlo1			; gdy po dodaniu offsetu end<0 offsam

	tst.l	12(a0,d1.l)			; ale gdy sampl jest zapetlony gra go
	beq.s	.ONEshotSample1
	move.l	(a0,d1.l),d2
	cmp.l	#0,Ahi_Sound0
	beq.s	.no16bit_2
	lsr.l	#1,d2
.no16bit_2
	add.l	8(a0,d1.l),d2
	move.l	12(a0,d1.l),d3
	bra.s	.WyszloZapetlenieDONE
.ONEshotSample1
	moveq	#AHI_NOSOUND,d1
	moveq	#AHISF_IMM,d4
	bra.w	.length_ok
.NieWyszlo1

	tst.l	12(a0,d1.l)
	beq.s	.ONEshotSample2
	move.l	8(a0,d1.l),d3
	add.l	12(a0,d1.l),d3
	sub.l	d4,d3
	bgt.s	.NieWyszlo2			; gdy po dodaniu offsetu end<0 offsam
	move.l	(a0,d1.l),d2
	cmp.l	#0,Ahi_Sound0
	beq.s	.no16bit_3
	lsr.l	#1,d2
.no16bit_3
	add.l	8(a0,d1.l),d2
	move.l	12(a0,d1.l),d3
.NieWyszlo2

.ONEshotSample2

.WyszloZapetlenieDONE

; ------------- test backward
	move.w	Oldd2(a6),d7
	lsr.w	#4,d7
	cmp.b	#$e3,d7
	beq.s	.backwd
	move.w	Oldd6(a6),d7
	lsr.w	#4,d7
	cmp.b	#$e3,d7
	bne.s	.no_backwd
.backwd
	add.l	d3,d2
	not.l	d3
.no_backwd
; ----------------------------

.playmain
	moveq	#0,d1				;sample bank
	moveq	#AHISF_IMM,d4

	lea	SampleOffsets,a6
	move.l	d2,(a6,d0.w*4)			;start



	lea	SampleOffsetsFT,a6
	move.b	#1,(a6,d0.w)


	tst.l	d3
	bne.b	.length_ok			;length=0 means "no sound"
	moveq	#AHI_NOSOUND,d1
.length_ok

	lea	SampleOffsets,a6
	cmp.l	#AHI_NOSOUND,d1
	bne.s	.nozero
	move.l	#0,(a6,d0.w*4)			;start
	lea	SampleOffsetsFT,a6
	clr.b	(a6,d0.w)
.nozero

	move.l	ahibase,a6
	move.l	ahi_ctrl,a2
	jsr	_LVOAHI_SetSound(a6)

.exit	movem.l	(sp)+,d0-d2/a0-a2/a6
	rts

MIXCHAN:
	moveq	#0,d7
	move.w	TrackNumber,d7
	subq	#1,d7
	clr.w	WhichChan
ChannelsLoop:
	addq.w	#1,WhichChan
	move.l	d7,-(sp)
	move.w	Oldd0(a6),d0
	move.w	Oldd1(a6),d1
	move.w	Oldd2(a6),d2
	move.w	Oldd6(a6),d6
	bsr	mainPROC
	move.w	d0,Oldd0(a6)
	move.w	d1,Oldd1(a6)
	move.w	d2,Oldd2(a6)
	move.w	d6,Oldd6(a6)
	lea	ChanArea(a6),a6
	addq.w	#6,a1
	move.l	(sp)+,d7
	dbf	d7,ChannelsLoop
	rts



************* finetunes **********************************************

FINETUNES:
	movem.l	d1-a6,-(sp)
	lea	SamFin,a2
	moveq	#0,d4
	moveq	#0,d3
	add.w	d7,d7
	move.l	(a2,d7.w),d4
	tst.w	d0
	beq.s	.fintdone

	move.l	#3579545,d1
	divu	d0,d1
	and.l	#$ffff,d1
.ok8
	lsl.l	#8,d4
	beq.s	.ok7
	move.l	#8363,d2
	divu	d2,d4
.ok7	and.l	#$ffff,d4

	mulu	d4,d1
	lsr.l	#8,d1

	move.l	#3579545,d0
	tst.l	d1
	bne.s	.ok9
	moveq	#1,d1
.ok9
	divu.l	d1,d0

.fintdone
	movem.l	(sp)+,d1-a6
	move.w	d0,OrgPeriod(a6)
	rts

; -------------- main procedure ----------------------------
mainPROC:
	move.w	OldVolA(a6),VolA(a6)
	move.w	OldVolB(a6),VolB(a6)

	tst.b	Temp
	beq.w	NothingToDo ;Old_data

	move.b	count(pc),d7
	cmp.b	temp(pc),d7
	blt	old_data

	tst.b	PauseEn
	bne.w	oldperiod_1

	moveq	#0,d3

	tst.b	(a1)
	beq.w	oldperiod_1

	cmp.b	#$1f,(a1)
	bne.s	.novolenvoff
	addq.b	#1,VolEnvOff(a6)
	addq.b	#1,PanEnvOff(a6)
	bra.w	oldInstrNum_1
.novolenvoff

	clr.w	NoLoopEnable
	clr.w	OldPeriod(a6)

	clr.w	VibratoDatasA(a6)
	clr.w	VibratoDatasB(a6)

	move.w	2(a1),d7
	cmp.w	#$ed0,d7
	beq.s	.ClrEnvDatas
	and.w	#$fff0,d7
	cmp.w	#$ed0,d7
	beq.s	.NoClrEnvDatas

	move.w	4(a1),d7
	cmp.w	#$ed0,d7
	beq.s	.ClrEnvDatas
	and.w	#$fff0,d7
	cmp.w	#$ed0,d7
	beq.s	.NoClrEnvDatas
.ClrEnvDatas
	clr.b	VolEnvOff(a6)
	clr.b	VolEnvMode(a6)
	clr.w	VolEnvTime(a6)

	clr.b	PanEnvOff(a6)
	clr.b	PanEnvMode(a6)
	clr.w	PanEnvTime(a6)
.NoClrEnvDatas
	move.b	#1,OffEnable(a6)
	move.b	#1,EqNewSamA(a6)

	moveq	#0,d0
	move.b	(a1),d0

	move.l	a3,-(sp)
	lea	Periods,a3
	moveq	#0,d3
	move.b	d0,d3
	lsr.b	#4,d3
	subq.b	#1,d3
	mulu	#24,d3
	and.b	#$0f,d0
	add.w	d0,d0
	add.w	d3,d0
	move.w	(a3,d0.w),d0
	move.l	(sp)+,a3

	move.w	2(a1),d7
	and.w	#$ff00,d7
	cmp.w	#$300,d7
	bne.s	NoClrGliss_1
	clr.w	GlissandoDatasA+4(a6)
NoClrGliss_1
	move.w	4(a1),d7
	and.w	#$ff00,d7
	cmp.w	#$300,d7
	bne.s	NoClrGliss_2
	clr.w	GlissandoDatasB+4(a6)
NoClrGliss_2

	cmp.b	#$18,2(a1)
	beq.s	.NoClrSlideOffset
	cmp.b	#$18,4(a1)
	beq.s	.NoClrSlideOffset
	cmp.w	#$0900,2(a1)
	beq.s	.NoClrSlideOffset
	cmp.w	#$0900,4(a1)
	beq.s	.NoClrSlideOffset
	clr.w	SlideSamOffset(a6)
.NoClrSlideOffset

	move.w	d0,OrgPeriodARP(a6)
	moveq	#0,d7
	move.b	1(a1),d7
	tst.w	d7
	bne.s	.notakeold
	moveq	#0,d7
	move.b	OldInstrNumA(a6),d7
	moveq	#0,d1
	move.b	d7,d1
	subq	#1,d1
	lsl.w	#2,d1
.notakeold
	add.w	d7,d7
	bsr	FINETUNES

*********************************************************************


oldperiod_1:
	tst.b	1(a1)
	beq.w	oldInstrNum_1
	moveq	#0,d1
	move.b	1(a1),d1
	move.b	d1,OldInstrNumA(a6)
	subq	#1,d1
	moveq	#0,d2

	move.b	(a4,d1.w),d2
	lsl.w	#8,d2
	move.w	d2,VolA(a6)


; ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp
	move.l	d0,-(sp)
	lea	InstrGeneralPan,a0
	move.w	2(a0,d1.w*2),GeneralPan(a6)
	move.l	(sp)+,d0
; ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp

	lsl.w	#2,d1
oldInstrNum_1

	move.w	2(a1),d2
	move.w	4(a1),d6
	move.l	d0,-(sp)
	moveq	#0,d0
	move.w	d2,d0
	and.w	#$ff00,d0

	cmp.w	#$1400,d0
	bne.s	.onkeyoff1
	and.w	#$00ff,d2
	cmp.w	#$f,d2
	ble.s	.oki1
	moveq	#$0,d2
	bra.s	.onkeyoff1
.oki1
	and.w	#$000f,d2
	add.w	#$ec0,d2
.onkeyoff1

	moveq	#0,d0
	move.w	d6,d0
	and.w	#$ff00,d0

	cmp.w	#$1400,d0
	bne.s	.onkeyoff2
	and.w	#$00ff,d6
	cmp.w	#$f,d6
	ble.s	.oki2
	moveq	#$0,d6
	bra.s	.onkeyoff2
.oki2
	and.w	#$000f,d6
	add.w	#$ec0,d6
.onkeyoff2
	move.l	(sp)+,d0


	move.l	a5,-(sp)
	bsr	EffectCommandsA2
	bsr	EffectCommandsB2
	move.l	(sp)+,a5


	tst.b	OnOffChanA(a6)
	beq.s	No_Stop1
	move.w	#$e40,d2
	move.b	#1,OffEnable(a6)
No_Stop1:

old_data:

	move.b	temp(pc),d7
	subq	#1,d7
	cmp.b	count(pc),d7
	bne.s	no_CLReff
	move.w	d2,d7
	lsr.w	#8,d7
	cmp.b	#8,d7
	beq.s	no_CLReff1
	cmp.b	#3,d7
	beq.s	no_CLReff1
	cmp.b	#4,d7
	beq.s	no_CLReff1
	cmp.b	#5,d7
	beq.s	CLReffSP1
	TST.b	d7
	beq.s	no_CLReff1

	move.w	d2,d7
	lsr.w	#4,d7
	cmp.w	#$ec,d7
	beq.s	no_CLReff1
	cmp.w	#$e9,d7
	beq.s	no_CLReff1
	cmp.w	#$ed,d7
	beq.s	no_CLReff1
	moveq	#0,d2
	bra.s	no_CLReff1
CLReffSP1:
	move.w	#$0300,d2
no_CLReff1
	move.w	d6,d7
	lsr.w	#8,d7
	cmp.b	#3,d7
	beq.s	no_CLReff2
	cmp.b	#4,d7
	beq.s	no_CLReff2
	cmp.b	#5,d7
	beq.s	CLReffSP2
	TST.b	d7
	beq.s	no_CLReff2

	move.w	d6,d7
	lsr.w	#4,d7
	cmp.w	#$ec,d7
	beq.s	no_CLReff2
	cmp.w	#$e9,d7
	beq.s	no_CLReff2
	cmp.w	#$ed,d7
	beq.s	no_CLReff2

	moveq	#0,d6
	bra.s	no_CLReff2
CLReffSP2:
	move.w	#$0300,d6
no_CLReff2

no_CLReff

nothingtodo

	move.l	a5,-(sp)
	bsr	EffectCommandsA
	bsr	EffectCommandsB
	move.l	(sp)+,a5

	move.w	d0,GlissandoDatasA+2(a6)
	move.w	d0,GlissandoDatasB+2(a6)

	tst.w	d0
	beq.s	nothing

; -----------------------------------
	bsr.s	VolumeEnvelope
; -----------------------------------

	move.w	d0,MainPeriod(a6)
	tst.w	d7
	bne.s	.onim
	move.w	VolA(a6),MainVol(a6)
.onim

	tst.w	MainVol(a6)
	beq.s	.noPan

; -----------------------------------
	move.l	#$7fff,d3
	bsr.w	PanningEnvelope

; -----------------------------------------------------
;   FinalPan=Pan+(EnvelopePan-32)*(128-Abs(Pan-128))/32;
; -----------------------------------------------------
;	d3		=	 EnvelopePan 0-$10000
;	d4		=	 GeneralPan 0-256

	moveq	#0,d4
	move.w	GeneralPan(a6),d4		; GeneralPan	0-256


	movem.l	d5/d6,-(sp)
	sub.l	#$7fff,d3
	move.l	d4,d6


	sub.w	#128,d4
	tst.w	d4
	bge.s	.okp1
	muls	#-1,d4
.okp1
	move.l	#128,d5
	sub.w	d4,d5

	lsl.l	#8,d5
	muls.l	d5,d3
	divs.l	#$7fff,d3

	
	lsl.l	#8,d6
	add.l	d6,d3

	move.l	d3,PanPos(a6)
	movem.l	(sp)+,d5/d6

.noPan
; -----------------------------------

	move.w	VolA(a6),OldVolA(a6)
	move.w	VolB(a6),OldVolB(a6)
	rts


nothing:
	tst.w	MainPeriod(a6)
	beq.s	nostopperiod
	move.w	#-1,MainPeriod(a6)
nostopperiod
	rts



;- - - - - - - - - - - -  envelopes
VolumeEnvelope:
	movem.l	d0-d6/a0-a6,-(sp)


	lsr.l	#2,d1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lea	LoopTab,a0
	move.b	1(a0,d1.w),d6
	lsr.b	#1,d6
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	lea	VolEnvelope,a0
	mulu	#134,d1
	add.w	d1,a0

	tst.b	VolEnvOff(a6)
	beq.s	.doenvelope
	btst.b	#0,(a0)		; vol env points
	bne.s	.doenvelope
	clr.b	VolEnvOff(a6)
	clr.w	VolA(a6)
	bra.w	.noenvelope
.doenvelope

	btst	#0,(a0)
	beq.w	.noenvelope


	lea	6(a0),a1
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,d5
	move.b	1(a0),d4	; vol env points
	beq.w	.noenvelope

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	btst	#7,VolEnvMode(a6)
	beq.s	.noback

	move.b	3(a0),d5	; 1st loop point
	move.w	(a1,d5.w*4),d0
	cmp.w	VolEnvTime(a6),d0
	blt.w	.noreach1stpoint
	bclr	#7,VolEnvMode(a6)
	bra.s	.noback
.noreach1stpoint

	subq.w	#2,VolEnvTime(a6)
.noback

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	addq.w	#1,VolEnvTime(a6)

;-------- envelope loop -------------

	btst	#1,VolEnvMode(a6)
	bne.s	.noloop

	btst	#2,(a0)
	beq.s	.noloop

	move.b	4(a0),d5	; 2nd loop point
	move.w	(a1,d5.w*4),d0
	cmp.w	VolEnvTime(a6),d0
	bgt.w	.noloop

	tst.b	VolEnvOff(a6)
	bne.s	.setloop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	tst.b	d6
	beq.s	.noping
	bset	#7,VolEnvMode(a6)
	bra.s	.noloop
.noping
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	move.b	3(a0),d5	; 1st loop point
	move.w	(a1,d5.w*4),VolEnvTime(a6)
	bra.s	.noloop
.setloop
	bset	#1,VolEnvMode(a6)
	tst.b	VolEnvOff(a6)
	beq.s	.noloop
	subq.b	#1,VolEnvOff(a6)
.noloop

;-------- envelope sustain1 -------------

	btst	#0,VolEnvMode(a6)
	bne.s	.nosustain1

	btst	#1,(a0)
	beq.s	.nosustain1

	move.b	2(a0),d5	; sustain1 point 
	move.w	(a1,d5.w*4),d0

	addq	#1,d0
	cmp.w	VolEnvTime(a6),d0
	bne.w	.nosustain1

	tst.b	VolEnvOff(a6)
	bne.s	.setsustain1

	move.w	(a1,d5.w*4),VolEnvTime(a6)
	bra.s	.nosustain1
.setsustain1
	bset	#0,VolEnvMode(a6)
	tst.b	VolEnvOff(a6)
	beq.s	.nosustain1
	subq.b	#1,VolEnvOff(a6)
.nosustain1

;-------- envelope sustain2 -------------

	btst	#2,VolEnvMode(a6)
	bne.s	.nosustain2

	btst	#3,(a0)
	beq.s	.nosustain2

	move.b	5(a0),d5	; sustain2 point
	move.w	(a1,d5.w*4),d0

	addq	#1,d0
	cmp.w	VolEnvTime(a6),d0
	bne.w	.nosustain2

	tst.b	VolEnvOff(a6)
	bne.s	.setsustain2

	move.w	(a1,d5.w*4),VolEnvTime(a6)
	bra.s	.nosustain2
.setsustain2
	bset	#2,VolEnvMode(a6)
	tst.b	VolEnvOff(a6)
	beq.s	.nosustain2
	subq.b	#1,VolEnvOff(a6)
.nosustain2

;---------------------------------------



.getpoint
	move.w	(a1),d0
	cmp.w	VolEnvTime(a6),d0
	blt.s	.nextpoint
	tst.w	VolEnvTime(a6)
	beq.s	.firstpoint
	bra.s	.thispoint
.nextpoint
	addq	#4,a1
	dbf	d4,.getpoint
	subq	#1,VolEnvTime(a6)
	subq	#4,a1
.thispoint
	subq	#4,a1
.firstpoint
	move.w	(a1),d0		; time
	move.w	4(a1),d1

	move.w	2(a1),d2	; vol
	move.w	6(a1),d3


	sub.w	d2,d3
	ext.l	d3
	asl.l	#8,d3
	sub.w	d0,d1
	beq.s	.nodiv1
	divs	d1,d3
.nodiv1
	and.l	#$ffff,d3
	ext.l	d3

	moveq	#0,d0
	move.w	(a1),d0			; time
	moveq	#0,d1
	move.w	VolEnvTime(a6),d1
	tst.l	d3
	bge.s	.ok1
	move.w	4(a1),d0		; time
	moveq	#0,d5
	move.w	6(a1),d5
	lsl.w	#8,d5
	bra.s	.ok2
.ok1
	moveq	#0,d5
	move.w	2(a1),d5
	lsl.w	#8,d5
.ok2

	sub.w	d0,d1
	bne.s	.niezero		; gdy rowne zero czas na envelopa

	btst	#1,VolEnvMode(a6)
	beq.s	.niezero

	move.w	6(a1),d3		; dobiegl konca (przesyla koncowa
	lsl.w	#8,d3			; glosnosc)
	bra.s	.envelopefinished
.niezero
	muls	d1,d3
	add.w	d5,d3
.envelopefinished

	moveq	#0,d4
	move.w	VolA(a6),d4
	lsr.l	#6,d4
;	divu	#64,d4
;	and.l	#$ffff,d4
	mulu	d3,d4
	lsr.l	#8,d4
	move.w	d4,MainVol(a6)


;	move.l	muj,a5
;	move.w	d4,(a5)+
;	move.l	a5,muj

	moveq	#1,d7
	bra.s	.envelopedone
.noenvelope
	moveq	#0,d7
.envelopedone
	movem.l	(sp)+,d0-d6/a0-a6
;- - - - - - - - - - - -  envelopes end
	rts










;- - - - - - - - - - - -  envelopes    

; ;;;;;;;;;;;; - procedurki do ping pong loopa

PanningEnvelope:
	movem.l	d0-d2/d4-d7/a0-a6,-(sp)

	lsr.l	#2,d1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lea	LoopTab,a0
	move.b	1(a0,d1.w),d6
	lsr.b	#1,d6
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	lea	PanEnvelope,a0
	mulu	#134,d1
	add.w	d1,a0

	tst.b	PanEnvOff(a6)
	beq.s	.doenvelope
	btst.b	#0,(a0)		; Pan env points
	bne.s	.doenvelope
	clr.b	PanEnvOff(a6)
	bra.w	.noenvelope
.doenvelope

	btst	#0,(a0)
	beq.w	.noenvelope


	lea	6(a0),a1
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,d5
	move.b	1(a0),d4	; Pan env points
	beq.w	.noenvelope

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	btst	#7,PanEnvMode(a6)
	beq.s	.noback

	move.b	3(a0),d5	; 1st loop point
	move.w	(a1,d5.w*4),d0
	cmp.w	PanEnvTime(a6),d0
	blt.w	.noreach1stpoint
	bclr	#7,PanEnvMode(a6)
	bra.s	.noback
.noreach1stpoint

	subq.w	#2,PanEnvTime(a6)
.noback

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	addq.w	#1,PanEnvTime(a6)

;-------- envelope loop -------------

	btst	#1,PanEnvMode(a6)
	bne.s	.noloop

	btst	#2,(a0)
	beq.s	.noloop

	move.b	4(a0),d5	; 2nd loop point
	move.w	(a1,d5.w*4),d0
	cmp.w	PanEnvTime(a6),d0
	bgt.w	.noloop

	tst.b	PanEnvOff(a6)
	bne.s	.setloop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	tst.b	d6
	beq.s	.noping
	bset	#7,PanEnvMode(a6)
	bra.s	.noloop
.noping
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	move.b	3(a0),d5	; 1st loop point
	move.w	(a1,d5.w*4),PanEnvTime(a6)
	bra.s	.noloop
.setloop
	bset	#1,PanEnvMode(a6)
	tst.b	PanEnvOff(a6)
	beq.s	.noloop
	subq.b	#1,PanEnvOff(a6)
.noloop

;-------- envelope sustain1 -------------

	btst	#0,PanEnvMode(a6)
	bne.s	.nosustain1

	btst	#1,(a0)
	beq.s	.nosustain1

	move.b	2(a0),d5	; sustain1 point 
	move.w	(a1,d5.w*4),d0

	addq	#1,d0
	cmp.w	PanEnvTime(a6),d0
	bne.w	.nosustain1

	tst.b	PanEnvOff(a6)
	bne.s	.setsustain1

	move.w	(a1,d5.w*4),PanEnvTime(a6)
	bra.s	.nosustain1
.setsustain1
	bset	#0,PanEnvMode(a6)
	tst.b	PanEnvOff(a6)
	beq.s	.nosustain1
	subq.b	#1,PanEnvOff(a6)
.nosustain1

;-------- envelope sustain2 -------------

	btst	#2,PanEnvMode(a6)
	bne.s	.nosustain2

	btst	#3,(a0)
	beq.s	.nosustain2

	move.b	5(a0),d5	; sustain2 point
	move.w	(a1,d5.w*4),d0

	addq	#1,d0
	cmp.w	PanEnvTime(a6),d0
	bne.w	.nosustain2

	tst.b	PanEnvOff(a6)
	bne.s	.setsustain2

	move.w	(a1,d5.w*4),PanEnvTime(a6)
	bra.s	.nosustain2
.setsustain2
	bset	#2,PanEnvMode(a6)
	tst.b	PanEnvOff(a6)
	beq.s	.nosustain2
	subq.b	#1,PanEnvOff(a6)
.nosustain2

;---------------------------------------



.getpoint
	move.w	(a1),d0
	cmp.w	PanEnvTime(a6),d0
	blt.s	.nextpoint
	tst.w	PanEnvTime(a6)
	beq.s	.firstpoint
	bra.s	.thispoint
.nextpoint
	addq	#4,a1
	dbf	d4,.getpoint
	subq	#1,PanEnvTime(a6)
	subq	#4,a1
.thispoint
	subq	#4,a1
.firstpoint
	move.w	(a1),d0		; time
	move.w	4(a1),d1


	move.w	2(a1),d2	; Pan
	move.w	6(a1),d3


	sub.w	d2,d3
	ext.l	d3
	asl.l	#8,d3
	sub.w	d0,d1
	beq.s	.nodiv1
	divs	d1,d3
.nodiv1
	and.l	#$ffff,d3
	ext.l	d3

	moveq	#0,d0
	move.w	(a1),d0			; time
	moveq	#0,d1
	move.w	PanEnvTime(a6),d1
	tst.l	d3
	bge.s	.ok1
	move.w	4(a1),d0		; time
	moveq	#0,d5
	move.w	6(a1),d5
	lsl.w	#8,d5
	bra.s	.ok2
.ok1
	moveq	#0,d5
	move.w	2(a1),d5
	lsl.w	#8,d5
.ok2

	sub.w	d0,d1
	bne.s	.niezero		; gdy rowne zero czas na envelopa

	btst	#1,PanEnvMode(a6)
	beq.s	.niezero

	move.w	6(a1),d3		; dobiegl konca (przesyla koncowa
	lsl.w	#8,d3			; glosnosc)
	bra.s	.envelopefinished
.niezero
	muls	d1,d3
	add.w	d5,d3
.envelopefinished

	moveq	#0,d4
	lsl.l	#2,d3

;	move.l	muj,a5
;	move.l	d3,(a5)+
;	move.l	a5,muj

.noenvelope
.envelopedone
	movem.l	(sp)+,d0-d2/d4-d7/a0-a6
;- - - - - - - - - - - -  envelopes end
	rts










;muj:	dc.l	huj

; --------------------------- EffectCommands ---------------------------

EffectCommandsA2:
; effects 9xx, bxx, cxx, dxx, fxx, gxx, lxx, oxx chan A

	move.w	d2,d7
	beq	EffComA2exit
	lsr.w	#8,d7
	clr.b	channelenable
	move.w	d2,d3

	cmp.b	#8,d7
	beq	Pannings2

	lea	SamoffsetA(a6),a5
	cmp.b	#9,d7
	beq	SampleOffset

	cmp.b	#$b,d7
	beq	SongRepeat

	lea	VolA(a6),a5
	cmp.b	#$c,d7
	beq	SetVolume

	cmp.b	#$10,d7
	beq	SetGlobalVolume

	cmp.b	#$15,d7
	beq	SetEnvelopePos

	lea	Hex(pc),a5
	cmp.b	#$d,d7
	beq	PattBreak

	cmp.b	#$f,d7
	beq	SetTempo

	cmp.b	#$1c,d7
	beq	SetRealBPM

	cmp.b	#$1f,d7
	beq	EchoOnOff
	cmp.b	#$20,d7
	beq	SetDelay
	cmp.b	#$21,d7
	beq	SetFeedBack
	cmp.b	#$22,d7
	beq	SetMix
	cmp.b	#$23,d7
	beq	SetCross

	lea	OldSlideOffsetA(a6),a5
	cmp.b	#$18,d7
	beq	SlideOffset

; effects E0x, E1x, E2x, E4x, E4x, E6x, E7x, E8x, EAx, EBx EEx chan A

	cmp.w	#$e00,d3
	beq.w	OffFilter

	cmp.w	#$e01,d3
	beq.w	OnFilter

	cmp.w	#$e50,d3
	beq.w	OffChannelA

	cmp.w	#$e51,d3
	beq.w	OnChannelA

	move.w	d2,d7
	lsr.w	#4,d7
	move.w	d2,d3

	cmp.b	#$e1,d7
	beq.w	FineSlideUp

	cmp.b	#$e2,d7
	beq.w	FineSlideDown

	cmp.b	#$e4,d7
	beq.w	TurnOffSam

	lea	loopsdataschanA(a6),a5
	cmp.b	#$e6,d7
	beq.w	Loops

	lea	SamOffsetA(a6),a5
	cmp.b	#$e7,d7
	beq	offsets

	cmp.b	#$e8,d7
	beq	pannings

	lea	VolA(a6),a5
	cmp.b	#$ea,d7
	beq	FineVolUp

	cmp.b	#$eb,d7
	beq	FineVolDown

	cmp.b	#$ee,d7
	beq	Pause

EffComA2exit
	rts

EffectCommandsB2:
; effects 9xx, bxx, cxx, dxx, fxx, gxx, lxx, oxx chan B

	move.w	d6,d7
	beq	EffComB2exit
	lsr.w	#8,d7
	move.b	#1,channelenable
	move.w	d6,d3

	cmp.b	#8,d7
	beq	Pannings2

	lea	SamoffsetB(a6),a5
	cmp.b	#9,d7
	beq	SampleOffset

	cmp.b	#$b,d7
	beq	SongRepeat

	lea	VolA(a6),a5
	cmp.b	#$c,d7
	beq	SetVolume

	cmp.b	#$10,d7
	beq	SetGlobalVolume

	cmp.b	#$15,d7
	beq	SetEnvelopePos

	lea	Hex(pc),a5
	cmp.b	#$d,d7
	beq	PattBreak

	cmp.b	#$f,d7
	beq	SetTempo

	cmp.b	#$1c,d7
	beq	SetRealBPM

	cmp.b	#$1f,d7
	beq	EchoOnOff
	cmp.b	#$20,d7
	beq	SetDelay
	cmp.b	#$21,d7
	beq	SetFeedBack
	cmp.b	#$22,d7
	beq	SetMix
	cmp.b	#$23,d7
	beq	SetCross

	lea	OldSlideOffsetB(a6),a5
	cmp.b	#$18,d7
	beq	SlideOffset

; effects E0x, E1x, E2x, E4x, E4x, E6x, E7x, E8x, EAx, EBx EEx chan B

	cmp.w	#$e00,d3
	beq.w	OffFilter

	cmp.w	#$e01,d3
	beq.w	OnFilter

	cmp.w	#$e50,d3
	beq.w	OffChannelA

	cmp.w	#$e51,d3
	beq.w	OnChannelA

	move.w	d6,d7
	lsr.w	#4,d7
	move.w	d6,d3

	cmp.b	#$e1,d7
	beq.w	FineSlideUp

	cmp.b	#$e2,d7
	beq.w	FineSlideDown

	cmp.b	#$e4,d7
	beq.w	TurnOffSam

	lea	loopsdataschanB(a6),a5
	cmp.b	#$e6,d7
	beq.w	Loops

	lea	SamOffsetA(a6),a5
	cmp.b	#$e7,d7
	beq	offsets

	cmp.b	#$e8,d7
	beq	pannings

	lea	VolA(a6),a5
	cmp.b	#$ea,d7
	beq	FineVolUp

	cmp.b	#$eb,d7
	beq	FineVolDown

	cmp.b	#$ee,d7
	beq	Pause

EffComB2exit
	rts




EffectCommandsA:
; effects 0xx 1xx, 2xx, 3xx, 4xx, 5xx, 6xx, axx, hxx chan A
	move.w	d2,d7
	beq	EffComAexit
	lsr.w	#8,d7
	clr.b	channelenable
	move.w	d2,d3

	lea	OrgPeriodARP(a6),a5
	tst.b	d7
	beq.w	Arpeggio

	cmp.b	#1,d7
	beq.w	PortUp

	cmp.b	#2,d7
	beq.w	PortDown

	lea	GlissandoDatasA(a6),a5
	cmp.b	#3,d7
	beq.w	Glissando

	lea	VibratoDatasA(a6),a5
	cmp.b	#4,d7
	beq.w	Vibrato

	cmp.b	#5,d7
	beq.w	SlideVolGliss

	cmp.b	#6,d7
	beq.w	SlideVolVib

	lea	VolA(a6),a5
	cmp.b	#$a,d7
	beq	SlideVolume

	lea	OldGlobalVolA(a6),a5
	cmp.b	#$11,d7
	beq	SlideGlobalVolume

	lea	SlidePanOldA(a6),a5
	cmp.b	#$19,d7
	beq	SlidePan

; effects E9x, ECx EDx chan A

	move.w	d2,d7
	lsr.w	#4,d7
	move.w	d2,d3

	lea	RetraceCntA(a6),a5
	cmp.b	#$e9,d7
	beq.w	Retrace

	lea	VolA(a6),a5
	cmp.b	#$ec,d7
	beq	CutSample

	lea	NoteDelayPeriodA(a6),a5
	cmp.b	#$ed,d7
	beq	DelaySample
EffComAexit
	rts


EffectCommandsB:
; effects 1xx, 2xx, 3xx, 4xx, 5xx, 6xx, axx, hxx chan B
	move.w	d6,d7
	beq	EffComBexit
	lsr.w	#8,d7
	move.b	#1,channelenable
	move.w	d6,d3

	lea	OrgPeriodARP(a6),a5
	tst.b	d7
	beq.w	Arpeggio

	cmp.b	#1,d7
	beq.w	PortUp

	cmp.b	#2,d7
	beq.w	PortDown

	lea	GlissandoDatasB(a6),a5
	cmp.b	#3,d7
	beq.w	Glissando

	lea	VibratoDatasB(a6),a5
	cmp.b	#4,d7
	beq.w	Vibrato

	cmp.b	#5,d7
	beq.w	SlideVolGliss

	cmp.b	#6,d7
	beq.w	SlideVolVib

	lea	VolB(a6),a5	; musi byc B
	cmp.b	#$a,d7
	beq	SlideVolume

	lea	OldGlobalVolB(a6),a5
	cmp.b	#$11,d7
	beq	SlideGlobalVolume

	lea	SlidePanOldB(a6),a5
	cmp.b	#$19,d7
	beq	SlidePan

; effects E9x, ECx, EDx chan B

	move.w	d6,d7
	lsr.w	#4,d7
	move.w	d6,d3

	lea	RetraceCntB(a6),a5
	cmp.b	#$e9,d7
	beq.w	Retrace

	lea	VolA(a6),a5
	cmp.b	#$ec,d7
	beq	CutSample

	lea	NoteDelayPeriodB(a6),a5
	cmp.b	#$ed,d7
	beq	DelaySample
EffComBexit
	rts

;------------------------------ effects -------------------------------------
TurnOffSam:
	move.b	#1,OffEnable(a6)
	rts

SetEnvelopePos:
	moveq	#0,d7
	move.b	d3,d7
	move.w	d7,VolEnvTime(a6)
	moveq	#0,d3
	rts


;looppattpos	(a5)      0OFS
;loopsongpos	1(a5)     1OFS
;loophowmany	2(a5)     2OFS

_0OFS	equ	0
_1OFS	equ	2
_2OFS	equ	1

loops:
	cmp.w	#$e60,d3
	bne.s	no_loop
	tst.b	_2OFS(a5)
	bne.s	loops_done
	moveq	#0,d7
	move.w	pattpos(pc),d7
	move.b	d7,(a5)

	move.w	songpos(pc),_1OFS(a5)

	bra.s	loops_done
no_loop
	tst.b	_2OFS(a5)
	beq.s	storehowmany
	subq.b	#1,_2OFS(a5)
	bne.s	no_done
	clr.b	(a5)
	clr.w	_1OFS(a5)
	clr.b	_2OFS(a5)
	bra.s	loops_done
no_done
	moveq	#0,d7
	move.b	(a5),d7
	subq.w	#1,d7
	move.w	d7,PattPos

	move.w	_1OFS(a5),songpos
	bra.s	loops_done
storehowmany
	and.b	#$0f,d3
	move.b	d3,_2OFS(a5)

	moveq	#0,d7
	move.b	(a5),d7
	subq.w	#1,d7
	move.w	d7,PattPos

	move.w	_1OFS(a5),songpos
loops_done
	rts

Pause:
	tst.b	PauseEn
	bne.s	no_pause

	moveq	#0,d7
	move.b	d3,d7
	and.b	#$0f,d7
	beq.s	No_pause
	moveq	#0,d3
	move.b	Temp(pc),d3
	mulu	d3,d7
	addq.w	#1,d7
	move.w	d7,PauseVBL
no_pause
	rts

SongRepeat:
	move.w	#-1,pattpos
	moveq	#0,d7
	move.b	d3,d7
	cmp.w	#1024,d7
	blt.s	songrep_ok
	move.w	#1024,d7
songrep_ok
	move.w	d7,songpos
	rts

PattBreak:
	moveq	#0,d7
	move.b	d3,d7
	cmp.w	#99,d7
	blt.s	patt_ok
	move.w	#99,d7
patt_ok
	cmp.w	#-1,pattpos
	beq.s	NoAddSP
	move.l	d0,-(sp)
	moveq	#0,d0
	move.w	OrdNum,d0
	cmp.w	SongPos,d0
	bne.s	.skip1
	clr.w	SongPos
	bra.s	.skip2
.skip1
	addq.w	#1,songpos
.skip2
	move.l	(sp)+,d0
NoAddSP
	move.l	d0,-(sp)
	moveq	#0,d0
	move.b	(a5,d7.w),d0
	move.w	d0,pattpos
	subq.w	#1,pattpos
	move.l	(sp)+,d0
	rts

SampleOffset:
	tst.b	d3
	bne.w	.nozero

.nozero
	moveq	#0,d7
	move.b	(a5),d7
	lsl.w	#8,d7
	lsl.l	#8,d7
	and.w	#$00ff,d3
	lsl.w	#8,d3
	add.w	d3,d7
	tst.b	channelenable
	bne.s	SamOffsChanB
;	add.l	d7,(a2,d1.w)
	rts
SamOffsChanB
;	add.l	d7,124(a2,d5.w)
	rts


offsets:
	move.b	d3,d7
	and.b	#$0f,d7
	move.b	d7,(a5)
	rts



pannings:
	moveq	#0,d7
	move.b	d3,d7
	and.b	#$0f,d7
	mulu	#17,d7
	lea	GeneralPan(a6),a5
	move.w	d7,(a5)
	rts

pannings2:
	moveq	#0,d7
	move.b	d3,d7
	lea	GeneralPan(a6),a5
	move.w	d7,(a5)
	rts

SlidePan:
	tst.b	d3
	bne.s	.NoOldSlidePan
	move.b	(a5),d3
.NoOldSlidePan
	move.b	d3,(a5)

	moveq	#0,d7
	move.b	d3,d7
	cmp.w	#$10,d7
	blt.s	Pandown

	lsr.b	#4,d7
	add.w	d7,GeneralPan(a6)
	cmp.w	#256,GeneralPan(a6)
	blt.s	Pandone
	move.w	#256,GeneralPan(a6)
	rts
PanDown
	sub.w	d7,GeneralPan(a6)
	tst.w	GeneralPan(a6)
	bgt.s	Pandone
	clr.w	GeneralPan(a6)
Pandone:rts



SetTempo:
	moveq	#0,d7
	move.b	d3,d7
	tst.w	d7
	beq.s	.Set
	cmp.w	#$1f,d7
	bgt.w	Cia_temp
.Set
	move.b	d3,temp
	move.b	d3,orgtemp
	move.b	d3,count
	rts


SetRealBPM:
	moveq	#0,d7
	move.b	d3,d7

	cmp.w	#$20,d7
	bge.s	.ok
	moveq	#$20,d7
.ok

	move.w	d7,RealTempo

	moveq	#0,d7
	move.w	CiaTempo,d7
	bsr.w	SetAhiTempo

;	move.w	#1,RefreshSlider6en
	rts

EchoOnOff
	cmp.w	#$1f10,d3
	beq.s	EchoOnAll
	cmp.w	#$1f11,d3
	beq.s	EchoOffAll
	lea	mask1channels+2-1,a5
	add.w	WhichChan,a5

	moveq	#0,d7
	move.b	d3,d7

	cmp.l	#1,d7
	bgt.s	.exit

	cmp.b	(a5),d7
	beq.s	.exit
	move.b	d7,(a5)
	move.w	#1,EchoEn
.exit
	rts


EchoOnAll:
	lea	mask1channels+2,a5
	move.l	ahi_chan,d7
	subq	#1,d7
.test
	cmp.b	#AHIEDM_WET,(a5)+
	beq.s	.niemam
	move.w	#1,EchoEn
	move.b	#AHIEDM_WET,-1(a5)
.niemam
	dbf	d7,.test
	rts

EchoOffAll:
	lea	mask1channels+2,a5
	move.l	ahi_chan,d7
	subq	#1,d7
.test
	cmp.b	#AHIEDM_DRY,(a5)+
	beq.s	.niemam
	move.w	#1,EchoEn
	move.b	#AHIEDM_DRY,-1(a5)
.niemam
	dbf	d7,.test
	rts

SetDelay:
	moveq	#0,d7
	move.b	d3,d7

	move.w	d7,DSPparamtab

;	move.w	#1,DSPEchoSignal

	move.l	Ahi_freq,d7
	lsl.l	#8,d7
	divu	#500,d7
	and.l	#$ffff,d7

	move.l	d6,-(sp)
	moveq	#0,d6
	move.b	d3,d6
	mulu	d6,d7
	lsr.l	#8,d7
	cmp.l	DSPECHODELAY,d7
	beq.s	.exit
	move.l	d7,DSPECHODELAY
	move.w	#1,EchoEn
.exit
	move.l	(sp)+,d6
.skip
	rts



SetFeedBack:
	moveq	#0,d7
	move.b	d3,d7

	move.w	d7,DSPparamtab+2
;	move.w	#1,DSPEchoSignal

	mulu	#257,d7
	cmp.l	#$ffff,d7
	bne.s	.noffff
	addq.l	#1,d7
.noffff
	cmp.l	DSPECHOFEEDBACK,d7
	beq.s	.exit
	move.l	d7,DSPECHOFEEDBACK
	move.w	#1,EchoEn
.exit
	rts




SetMix:
	moveq	#0,d7
	move.b	d3,d7

	move.w	d7,DSPparamtab+4
;	move.w	#1,DSPEchoSignal

	mulu	#257,d7
	cmp.l	#$ffff,d7
	bne.s	.noffff
	addq.l	#1,d7
.noffff
	cmp.l	DSPECHOMIX,d7
	beq.s	.exit
	move.l	d7,DSPECHOMIX
	move.w	#1,EchoEn
.exit
	rts




SetCross:
	moveq	#0,d7
	move.b	d3,d7

	move.w	d7,DSPparamtab+6
;	move.w	#1,DSPEchoSignal

	mulu	#257,d7
	cmp.l	#$ffff,d7
	bne.s	.noffff
	addq.l	#1,d7
.noffff
	cmp.l	DSPECHOCROSS,d7
	beq.s	.exit
	move.l	d7,DSPECHOCROSS
	move.w	#1,EchoEn
.exit
	rts





Cia_temp

SetAHItempo:
	move.w	d7,CiaTempo


	movem.l	d0-d6/a0-a6,-(sp)
	moveq	#0,d0
	moveq	#0,d1
	move.w	RealTempo,d0
	move.w	d7,d1
	lsl.l	#8,d0
	divu	#125,d0
	and.l	#$ffff,d0
	mulu	d0,d1
	lsr.l	#8,d1
	move.w	d1,d7
	move.w	d7,RealCiaTempo
	movem.l	(sp)+,d0-d6/a0-a6


	and.l	#$ffff,d7
	lsl.w	#1,d7
	divu	#5,d7
	and.l	#$ffff,d7
	swap	d7
	move.l	d7,afreq

	movem.l	d0-a6,-(sp)
	move.l	ahibase(pc),a6
	lea	atags(pc),a1
	move.l	ahi_ctrl(pc),a2
	jsr	_LVOAHI_ControlAudioA(a6)
	movem.l	(sp)+,d0-a6
	rts
atags
	dc.l	AHIA_PlayerFreq
afreq	dc.l	50<<16
	dc.l	TAG_DONE


OffChannelA:
	bset	#0,OnOffChanA(a6)
	rts
OnChannelA:
	bclr	#0,OnOffChanA(a6)
	rts
OffChannelB:
	bset	#0,OnOffChanB(a6)
	rts
OnChannelB:
	bclr	#0,OnOffChanB(a6)
	rts

OffFilter:
	bclr	#1,$bfe001
	rts
OnFilter:
	bset	#1,$bfe001
	rts



Retrace:
	cmp.b	#1,count
	bne.s	retrno_2
	clr.b	(a5)
retrno_2
	moveq	#0,d7
	move.b	d3,d7
	and.b	#$0f,d7
	subq.b	#1,d7
	cmp.b	(a5),d7
	bne.s	retrno_1

	tst.b	channelenable
	beq.s	retr_chan_a
;	move.l	(a0,d5.w),124(a2,d5.w)	; adres sampla
	move.b	#1,OffEnable(a6)
	bra.s	retr_chan_b
retr_chan_a
	move.b	#1,OffEnable(a6)
;	move.l	(a0,d1.w),(a2,d1.w)	; adres sampla
retr_chan_b
	clr.b	(a5)
	rts
retrno_1
	addq.b	#1,(a5)
no_retrace_1
	rts

cutsample:
	moveq	#0,d7
	move.b	d3,d7
	and.b	#$0f,d7
	beq.s	.doit
	cmp.b	count(pc),d7
	bne.s	no_cut_sam


	moveq	#0,d7
	move.b	count,d7
	cmp.b	temp(pc),d7
	beq.s	no_cut_sam

.doit	clr.w	(a5)
no_cut_sam:
	rts


delaysample:
	moveq	#0,d7
	move.b	d3,d7
	and.b	#$0f,d7
	beq.s	no_delay_sam

	clr.b	OffEnable(a6)

	moveq	#0,d7
	move.b	count2,d7
	bne.s	.nostore
	move.w	d0,(a5)
	move.w	d1,2(a5)
.nostore
	move.w	OldD0(a6),d0
	move.w	OldD1(a6),d1

	moveq	#0,d7
	move.b	d3,d7
	and.b	#$0f,d7

	cmp.b	count2(pc),d7
	bne.s	no_delay_sam
	move.w	(a5),d0
	move.w	2(a5),d1
	clr.w	OldPeriod(a6)
	move.b	#1,OffEnable(a6)

	clr.b	VolEnvOff(a6)
	clr.b	VolEnvMode(a6)
	clr.w	VolEnvTime(a6)
no_delay_sam:
	rts

; ------------- arpeggio -------------
arplist:
	dc.b 0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1
Arpeggio:
	movem.l	d2/a6,-(sp)
	bsr	ArpeggioMain
	movem.l	(sp)+,d2/a6
	move.l	d1,d7
	lsr.w	#1,d7
	addq	#2,d7
	bsr	FINETUNES

	move.w	d0,VibratoDatasA(a6)
	move.w	d0,VibratoDatasB(a6)
	rts

ArpeggioMain:
	moveq	#0,d7
	move.b	count(pc),d7
	subq.b	#1,d7

	move.b	arplist(pc,d7.w),d7
	beq.s	arp0
	cmp.b	#2,d7
	beq.s	arp2

arp1:	moveq	#0,d2
	move.b	d3,d2
	lsr.b	#4,d2
	bra.s	arpdo

arp2:	moveq	#0,d2
	move.b	d3,d2
	and.b	#$f,d2
arpdo:
	asl.w	#1,d2
	move.w	(a5),d7
	lea	periods,a6
	moveq	#12*7,d3
arp3:	cmp.w	(a6)+,d7
	bge.s	arpfound
	dbf	d3,arp3
arp0:
	tst.b	channelenable
	bne.s	ARP_chanB1
	move.w	(a5),d0
	rts
ARP_chanB1
	move.w	(a5),d0
	rts
arpfound:
	add.w	d2,a6
	cmp.l	#PeriodsEnd,a6
	ble.s	ArpOk1
	move.l	#PeriodsEnd,a6
	moveq	#0,d2
	bra.s	ArpOk2
ArpOk1	sub.w	d2,a6
ArpOk2	tst.b	channelenable
	bne.s	ARP_chanB2
	move.w	-2(a6,d2.w),d0
	rts
ARP_chanB2
	move.w	-2(a6,d2.w),d0
	rts

; ------------- portamento up -------------

PortUp:
	moveq	#0,d7
	move.b	d3,d7

	tst.b	channelenable
	bne.s	PortUp_chan_b
	
PortUp_chan_a
	tst.b	d7
	bne.s	NoOldPortUpA
	move.b	PortUpOldValA(a6),d7
NoOldPortUpA
	move.b	d7,PortUpOldValA(a6)

	move.b	d7,d3
	and.b	#$f0,d7
	cmp.b	#$f0,d7
	beq.w	FineSU
	move.b	d3,d7

	lsl.w	#2,d7
	sub.w	d7,d0
;	cmp.w	#113,d0
;	bge.s	PortUpOkA
;	move.w	#113,d0
;PortUpOkA
	move.w	d0,VibratoDatasA(a6)
	move.w	d0,VibratoDatasB(a6)
	rts

PortUp_chan_b
	tst.b	d7
	bne.s	NoOldPortUpB
	move.b	PortUpOldValB(a6),d7
NoOldPortUpB
	move.b	d7,PortUpOldValB(a6)
	move.b	d7,d3
	and.b	#$f0,d7
	cmp.b	#$f0,d7
	beq.w	FineSU
	move.b	d3,d7

	lsl.w	#2,d7
	sub.w	d7,d0

;	cmp.w	#113,d0
;	bge.s	PortUpOkB
;	move.w	#113,d0
;PortUpOkB
;	rts

	move.w	d0,VibratoDatasA(a6)
	move.w	d0,VibratoDatasB(a6)
NoPortUp:
	rts

; ------------- portamento down -------------
PortDown:
	moveq	#0,d7
	move.b	d3,d7

	tst.b	channelenable
	bne.s	PortDown_chan_b
PortDown_chan_a
	tst.b	d7
	bne.s	NoOldPortDownA
	move.b	PortDownOldValA(a6),d7
NoOldPortDownA
	move.b	d7,PortDownOldValA(a6)
	move.b	d7,d3
	and.b	#$f0,d7
	cmp.b	#$f0,d7
	beq.w	FineSD
	move.b	d3,d7

	lsl.w	#2,d7
	add.w	d7,d0
;	cmp.w	#856,d0
;	ble.s	PortDownOkA
;	move.w	#856,d0
;PortDownOkA
	move.w	d0,VibratoDatasA(a6)
	move.w	d0,VibratoDatasB(a6)
	rts

PortDown_chan_b
	tst.b	d7
	bne.s	NoOldPortDownB
	move.b	PortDownOldValB(a6),d7
NoOldPortDownB
	move.b	d7,PortDownOldValB(a6)
	move.b	d7,d3
	and.b	#$f0,d7
	cmp.b	#$f0,d7
	beq.w	FineSD
	move.b	d3,d7

	lsl.w	#2,d7
	add.w	d7,d0
;	cmp.w	#856,d0
;	ble.s	PortDownOkB
;	move.w	#856,d0
;PortDownOkB
	move.w	d0,VibratoDatasA(a6)
	move.w	d0,VibratoDatasB(a6)
noPortDown:
	rts

; --------------- set global volume  -------------
SetGlobalVolume:
	moveq	#0,d7
	move.b	d3,d7
	move.w	d7,GlobalVol
	rts
; ------------- slide global volume  -------------
SlideGlobalVolume:
	tst.b	d3
	bne.s	.NoOldSlideVol
	move.b	(a5),d3	; Old SlideVolValue
.NoOldSlideVol
	move.b	d3,(a5)

	moveq	#0,d7
	move.b	d3,d7
	cmp.w	#$10,d7
	blt.s	.Voldown

	moveq	#0,d7
	move.b	d3,d7
	lsr.b	#4,d7
	add.w	d7,GlobalVol
	cmp.w	#64,GlobalVol
	blt.s	.Voldone
	move.w	#64,GlobalVol
	rts
.Voldown
	moveq	#0,d7
	move.b	d3,d7
	sub.w	d7,GlobalVol
	tst.w	GlobalVol
	bgt.s	.Voldone
	clr.w	GlobalVol
.Voldone:
	rts

; ------------- slide offset -------------
SlideOffset:
	tst.b	d3
	bne.s	.NoOldSlide
	move.b	(a5),d3	; Old SlideOffset
.NoOldSlide
	move.b	d3,(a5)

	moveq	#0,d7
	move.b	d3,d7
	cmp.w	#$10,d7
	blt.s	.down

	moveq	#0,d7
	move.b	d3,d7
	lsr.b	#4,d7
	add.w	d7,SlideSamOffset(a6)
	rts
.down
	moveq	#0,d7
	move.b	d3,d7
	sub.w	d7,SlideSamOffset(a6)
	tst.w	SlideSamOffset(a6)
	bgt.s	.done
	clr.w	SlideSamOffset(a6)
.done:
	rts

; --------------- set volume  -------------
SetVolume:
	moveq	#0,d7
	move.b	d3,d7
	lsl.w	#8,d7
	move.w	d7,(a5)
	rts

; --------------- slide volume up -------------
SlideVolume:
	tst.b	d3
	bne.s	NoOldSlideVol
	move.b	2(a5),d3	; Old SlideVolVolue
NoOldSlideVol
	move.b	d3,2(a5)

	moveq	#0,d7
	move.b	d3,d7
	cmp.w	#$10,d7
	blt.s	Voldown

	and.b	#$0f,d7
	cmp.b	#$0f,d7
	beq.s	FineVol
	move.b	d3,d7
	and.b	#$f0,d7
	cmp.b	#$f0,d7
	beq.s	FineVol

	moveq	#0,d7
	move.b	d3,d7
	lsr.b	#4,d7
	lsl.w	#8,d7
	add.w	d7,VolA(a6)
	cmp.w	#64*256,VolA(a6)
	blt.s	Voldone
	move.w	#64*256,VolA(a6)
	rts
Voldown
;	and.b	#$f0,d7

	moveq	#0,d7
	move.b	d3,d7
	lsl.w	#8,d7
	sub.w	d7,VolA(a6)
	tst.w	VolA(a6)
	bgt.s	Voldone
	clr.w	VolA(a6)
Voldone:rts


FineVol:
	cmp.b	#$0f,d7
	beq.s	.FineUp
	moveq	#0,d7
	move.b	d3,d7
	and.b	#$0f,d7
	add.w	#$eb0,d7
	move.w	d7,d3
	bsr	FineVolDown
	rts
.FineUp:
	moveq	#0,d7
	move.b	d3,d7
	lsr.b	#4,d7
	add.w	#$ea0,d7
	move.w	d7,d3
	bsr	FineVolUp
	rts

FineSU:
	moveq	#0,d7
	move.b	d3,d7
	and.b	#$0f,d7
;	add.w	#$ea0,d7
	move.w	d7,d3
	bsr	FineSlideUp
	rts
FineSD:
	moveq	#0,d7
	move.b	d3,d7
	and.b	#$0f,d7
;	add.w	#$eb0,d7
	move.w	d7,d3
	bsr	FineSlideDown
	rts


; --------------- fine slide down -------------
FineSlideDown:
	move.w	d3,d7
	and.w	#$000f,d7
	lsl.w	#2,d7

	tst.b	channelenable
	bne.s	FineSlideDownB

	add.w	d7,d0
;	cmp.w	#856,d0
;	ble.s	FineSlideDownOkA
;	move.w	#856,d0
;FineSlideDownOkA
	moveq	#0,d2

	move.w	d0,VibratoDatasA(a6)
	move.w	d0,VibratoDatasB(a6)
	rts

FineSlideDownB
	add.w	d7,d0
;	cmp.w	#856,d0
;	ble.s	FineSlideDownOkB
;	move.w	#856,d0
;FineSlideDownOkB
	moveq	#0,d6
	move.w	d0,VibratoDatasA(a6)
	move.w	d0,VibratoDatasB(a6)
	rts

; --------------- fine slide up -------------
FineSlideUp:
	move.w	d3,d7
	and.w	#$000f,d7
	lsl.w	#2,d7

	tst.b	channelenable
	bne.s	FineSlideUpB

	sub.w	d7,d0
;	cmp.w	#113,d0
;	bge.s	FineSlideUpOkA
;	move.w	#113,d0
;FineSlideUpOkA
	moveq	#0,d2
	move.w	d0,VibratoDatasA(a6)
	move.w	d0,VibratoDatasB(a6)
	rts

FineSlideUpB
	sub.w	d7,d0

;	cmp.w	#113,d0
;	bge.s	FineSlideUpOkB
;	move.w	#113,d0
;FineSlideUpOkB
	moveq	#0,d6
	move.w	d0,VibratoDatasA(a6)
	move.w	d0,VibratoDatasB(a6)
	rts

; --------------- fine volume up  -------------
FineVolUp:
	move.w	d3,d7
	and.w	#$000f,d7
	lsl.w	#8,d7
	add.w	d7,VolA(a6)
	cmp.w	#64*256,VolA(a6)
	blt.s	FVUOK
	move.w	#64*256,VolA(a6)
FVUOK
	tst.b	channelenable
	bne.s	FVUClrVolB
	moveq	#0,d2
	rts
FVUClrVolB
	moveq	#0,d6
	rts


; --------------- fine volume down  -------------
FineVolDown:
	move.w	d3,d7
	and.w	#$000f,d7
	lsl.w	#8,d7
	sub.w	d7,VolA(a6)
	tst.w	VolA(a6)
	bge.s	FVDOK
	clr.w	VolA(a6)
FVDOK
	tst.b	channelenable
	bne.s	FVDClrVolB
	moveq	#0,d2
	rts
FVDClrVolB
	moveq	#0,d6
NoFVD	rts


; ------------- glissando -------------

;GlissOldValue:		 (a5)
;GlissEnable:		1(a5)
;GlissOldPeriod:	2(a5)
;GlissNewPeriod:	4(a5)

Glissando:
	move.w	d3,d7
	tst.b	d3
	bne.s	NoOLDgliss
	move.b	(a5),d3
NoOLDgliss

	cmp.b	#1,count
	bne.s	NoStore
	move.b	d3,(a5)
NoStore
	lea	GlissandoDatasA(a6),a5

	tst.w	2(a5)
	beq.w	GlissRTS

;	tst.b	channelenable
;	bne.s	GlissOK1B

GlissOK1A:
	tst.w	4(a5)
	bne.s	GlissOk2
	move.w	d0,d7
	move.w	d0,4(a5)
	move.w	2(a5),d0
	clr.b	1(a5)
	cmp.w	d0,d7
	beq.s	ClrNP
	bge.w	GlissRTS
	move.b	#1,1(a5)
	rts

;GlissOK1B:
;	tst.w	4(a5)
;	bne.s	GlissOk2
;	move.w	d4,d7
;	move.w	d4,4(a5)
;	move.w	2(a5),d4
;	clr.b	1(a5)
;	cmp.w	d4,d7
;	beq.s	ClrNP
;	bge.s	GlissRTS
;	move.b	#1,1(a5)
;	rts

ClrNP:	clr.w	4(a5)
	rts

GlissOk2:
	move.w	d3,d7
	and.w	#$0ff,d7
	tst.w	4(a5)
	beq.s	Glissrts
	tst.b	1(a5)
	bne.s	Glisssub
	lsl.w	#2,d7
	add.w	d7,2(a5)
	move.w	4(a5),d7
	cmp.w	2(a5),d7
	bgt.s	GlissOK3
	move.w	4(a5),2(a5)
	clr.w	4(a5)
GlissOK3:
;	tst.b	channelenable
;	bne.s	GlissChanB
;GlissChanA
	move.w	2(a5),d0
	move.w	d0,VibratoDatasA(a6)
	move.w	d0,VibratoDatasB(a6)
	rts

;GlissChanB
;	move.w	2(a5),d0
;	rts

Glisssub:
	lsl.w	#2,d7
	sub.w	d7,2(a5)
	move.w	4(a5),d7
	cmp.w	2(a5),d7
	blt.s	GlissOK3
	move.w	4(a5),2(a5)
	clr.w	4(a5)
	bra.s	GlissOK3

Glissrts:
	rts

SlideVolGliss:
	and.w	#$00ff,d3
	add.w	#$a00,d3
	tst.b	channelenable
	bne.s	SlideChanB
	lea	VolA(a6),a5
	bra.s	DoSlideChan
SlideChanB
	lea	VolB(a6),a5
DoSlideChan
	bsr	SlideVolume

	move.w	#$0300,d3
	tst.b	channelenable
	bne.s	GlissBChan
	lea	GlissandoDatasA(a6),a5
	tst.w	d2
	bne.s	.ok
	move.w	#$0300,d2
.ok
	bra.s	DoGlissChan
GlissBChan
	tst.w	d6
	bne.s	.ok
	move.w	#$0300,d6
.ok
	lea	GlissandoDatasB(a6),a5
DoGlissChan
	bra	Glissando


SlideVolVib:
	and.w	#$00ff,d3
	add.w	#$a00,d3
	tst.b	channelenable
	bne.s	SlideChanBV
	lea	VolA(a6),a5
	bra.s	DoSlideChanV
SlideChanBV
	lea	VolB(a6),a5
DoSlideChanV
	bsr	SlideVolume

	move.w	#$0400,d3
	tst.b	channelenable
	bne.s	VibBChan
	lea	VibratoDatasA(a6),a5
	tst.w	d2
	bne.s	.ok
	move.w	#$0400,d2
.ok
	bra.s	DoVibChan
VibBChan
	lea	VibratoDatasB(a6),a5
	tst.w	d6
	bne.s	.ok
	move.w	#$0400,d6
.ok
DoVibChan
	bra	Vibrato




;VibPeriod	(a5)
;VibValue	2(a5)
;ViboldValue	3(a5)

Vibrato:
	movem.l	d2/d5,-(sp)

	move.w	d0,d2
;	tst.b	channelenable
;	bne.s	VibCHANB1
;	move.w	d0,d2
;VibCHANB1
	bsr	VibratoMain
;	tst.b	channelenable
;	bne.s	VibCHANB2
;	move.w	d2,d0
;	bra.s	VibMainDone
;VibCHANB2
	move.w	d2,d0
VibMainDone
	movem.l	(sp)+,d2/d5
	rts

VibratoMain:
	move.b	Count(pc),d7
	cmp.b	Temp(pc),d7
	bne.s	NoNewPeriod
	tst.w	(a5)
	bne.s	NoNewPeriod
	move.w	d2,(a5)
NoNewPeriod
	move.w	(a5),d2
	move.b	temp(pc),d7
	subq	#1,d7
	cmp.b	count(pc),d7
	bne.s	DoVibrato
	clr.w	(a5)
	rts
DoVibrato
	move.b	d3,d5
	and.b	#$0f,d5
	bne.s	NoNew1
	move.b	3(a5),d5
	and.b	#$0f,d5
	add.b	d5,d3
NoNew1
	move.b	d3,d5
	and.b	#$f0,d5
	bne.s	NoNew2
	move.b	3(a5),d5
	and.b	#$f0,d5
	add.b	d5,d3
NoNew2
	move.w	d3,-(sp)

	move.b	d3,3(a5)

	move.b	d3,d7
	move.b	2(a5),d3
	lsr.w	#2,d3
	and.w	#$1f,d3
	moveq	#0,d5
	move.b	VibSin(pc,d3.w),d5
	mulu	#5,d5
	divu	#3,d5
	and.l	#$ffff,d5

	move.b	d7,d3
	and.w	#$f,d3
	mulu	d3,d5
	lsr.w	#7,d5

	tst.b	2(a5)
	bmi.s	VibSub
	add.w	d5,d2
	bra.s	VibNext
VibSub:
	sub.w	d5,d2
VibNext:
	move.w	d2,d5
	move.b	d7,d5
	lsr.w	#2,d5
	and.w	#$3c,d5
	add.b	d5,2(a5)
	move.w	(sp)+,d3
	rts

VibSin:
	dc.b	$00,$18,$31,$4a,$61,$78,$8d,$a1,$b4,$c5,$d4,$e0,$eb,$f4,$fa,$fd
	dc.b	$ff,$fd,$fa,$f4,$eb,$e0,$d4,$c5,$b4,$a1,$8d,$78,$61,$4a,$31,$18


Hex:
 dc.b	0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,10,11,12,13,14,15,16,17,18,19
 dc.b	0,0,0,0,0,0,20,21,22,23,24,25,26,27,28,29,0,0,0,0,0,0,30,31
 dc.b	32,33,34,35,36,37,38,39,0,0,0,0,0,0,40,41,42,43,44,45,46,47
 dc.b	48,49,0,0,0,0,0,0,50,51,52,53,54,55,56,57,58,59,0,0,0,0,0,0
 dc.b	60,61,62,63,64,65,66,67,68,69,0,0,0,0,0,0
 dc.b	70,71,72,73,74,75,76,77,78,79,0,0,0,0,0,0
 dc.b	80,81,82,83,84,85,86,87,88,89,0,0,0,0,0,0
 dc.b	90,91,92,93,94,95,96,97,98,99,0,0,0,0,0,0
 even

PERIODS:
 dc.w	856*16,808*16,762*16,720*16,678*16,640*16,604*16,570*16,538*16,508*16,480*16,453*16
 dc.w	856*8,808*8,762*8,720*8,678*8,640*8,604*8,570*8,538*8,508*8,480*8,453*8
 dc.w	856*4,808*4,762*4,720*4,678*4,640*4,604*4,570*4,538*4,508*4,480*4,453*4
 dc.w	428*4,404*4,381*4,360*4,339*4,320*4,302*4,285*4,269*4,254*4,240*4,226*4
 dc.w	214*4,202*4,190*4,180*4,170*4,160*4,151*4,143*4,135*4,127*4,120*4,113*4
 dc.w	214*2,202*2,190*2,180*2,170*2,160*2,151*2,143*2,135*2,127*2,120*2,113*2
 dc.w	214,202,190,180,170,160,151,143,135,127,120,113
 dc.w	214/2,202/2,190/2,180/2,170/2,160/2,151/2,143/2,135/2,127/2,120/2,113/2
PERIODSEND:


;	SECTION	DATA,BSS_p

UnPackedData:	ds.l	128*6
PattAdresses:	ds.l	1024
PATTLENS:	ds.w	1024

SAMVOL:		ds.b	256
Instruments:	ds.w	256
SampleType:	ds.b	256	; 0-8bit ; 1-16bit
		ds.b	256	; original
LoopTab:	ds.b	256
SAMFIN:		ds.l	256
SONGORDERS:	ds.w	1024+1

SONGORDERS0:	ds.w	1024+1
SONGORDERS1:	ds.w	1024+1
SONGORDERS2:	ds.w	1024+1
SONGORDERS3:	ds.w	1024+1
SONGORDERS4:	ds.w	1024+1

ahi_samples	ds.b	(4*4)*256
ModNameBuffer:	ds.b	44
SongNameBuffer:	ds.b	44

SongNameBuffer0:ds.b	44
SongNameBuffer1:ds.b	44
SongNameBuffer2:ds.b	44
SongNameBuffer3:ds.b	44
SongNameBuffer4:ds.b	44

InstrNames:	ds.b	256*30
InstrGeneralPan:
		ds.w	256


VolEnvelope:	ds.b	((32*4)+6)*256	; 1 - type / 2 - point number
PanEnvelope:	ds.b	((32*4)+6)*256	; 1 - type / 2 - point number

SamBuff:	ds.b	32*(1024+16)

SampleOffsets	ds.l	128+2
SampleOffsetsFT	ds.b	128+2


; Channels
Channel1:	ds.b	ChanArea*128
ahi_channels	ds.l	128



MODBUFFER:
	ds.b	128*128-1572
	ds.b	1572
Tap_Buffer1:
	ds.b	2048
TAP_Buffer2:
	ds.b	2048
PackedPattLen:
	ds.w	1


 ifne test

	section	dad,data_f

MODULE:	incbin	"m:digibooster/## experience ##.dbm"
MODULEE
 endc
