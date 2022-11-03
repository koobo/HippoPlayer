; ==============================================================================
; xmaplay060 - Port of Fasttracker II's XM replayer for 68060 Amigas
; by 8bitbubsy, aug. 2020 - oct 2022. Syntax is Asm-Pro.
;
; Because of lack of 14-bit calibration support, there will be quite a bit of
; static noise in the audio on some songs on a real Amiga. It will sound good
; in (most?) emulators, though...
;
; It can actually run on 68020+ Amigas too, but it will be WAY too slow.
;
; NOTE: Code best viewed with tab width set to 8 (spaces).
;       Some labels are in Swedish from the original code.
;
; WARNING: This is work in progress, and not finished!
;          It's very possible that loading/free'ing is bugged and will freak
;          out once you allow loading a new song after play.
;
; TODOs:
; 1) Make the main loop more system friendly, don't read keys directly
; 2) Support AHI and 14-bit CyberSound calibration files
;
; Features:
; - 32 stereo channels with 11-bit input volumes (left/right)
; - Free voice panning with an 8-bit range
; - Full FT2 volume ramping (16-bit fractional precision)
; - 32-bit mixing with linear interpolation (16-bit fractional precision)
; - Loop unrolling on tight sample loops for better performance
; - Supports 8-bit/16-bit samples, whose length is up to 2GB
; - 8-bit/14-bit output
; - PAL/NTSC compliant (NTSC is untested)
; ==============================================================================

;------------------------------------------------------------------------------
; User configurable constants
;------------------------------------------------------------------------------
_14BIT			EQU 1   ; 1 = 14-bit output, 0 = 8-bit output (noisy)
MIX_AMP			EQU 10	; 1..32 ("FT2 amp")
MIX_PERIOD		EQU 128 ; ~27710.12Hz on PAL (divisable by 64 for 14-bit)
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; HippoPlayer glue
;------------------------------------------------------------------------------

    jmp     _init(pc)
    jmp     _end(pc)
    jmp     _stop(pc)
    jmp     _cont(pc)
    jmp     _forward(pc)
    jmp     _backward(pc)
    jmp     _getPosLen(pc)
    jmp     _setVolume(pc)


* In:
*   a0 = module filename
*   a1 = song end trigger
_init:
    move.l  a1,songOverPtr

	move.l	a0,a1
.1  tst.b   (a1)+
    bne.b   .1
    move.l  a1,d0
    sub.l   a0,d0

    move.l  a5,-(sp)
    bsr     MAIN
    move.l  (sp)+,a5
    * d0 = 0: ok, 1: error
    tst.l   d0
    bne.b   .error

    move.l  PaulaPosMask(pc),d1
    lea     PaulaPos(pc),a1
    move.l  PaulaCh1Buf(pc),a2
    move.l  PaulaCh2Buf(pc),a3

    sub.l   a0,a0
    moveq   #1,d0   * ok
    rts
.error
    move.l  lastMessagePtr(pc),a0
    moveq   #0,d0
    rts

_end:
    bsr     StopTask
    bsr     cleanUp
    rts

* out:
*   d0 = current position
*   d1 = max position
_getPosLen:
    move    SongPos(pc),d0
    move    hLen(pc),d1
    rts

* in: 
*   d0 = volume
_setVolume:
    bra     SetMixingVolume

_forward:
    bra     NextPattern

_backward:
    bra     PrevPattern

_stop:
    bsr    StopTask
    
	lea	    $dff000,a0
	move.w	#$000f,$96(a0)	; stop all audio DMAs
	clr.w	$a8(a0)		; clear voice volumes
	clr.w	$b8(a0)
	clr.w	$c8(a0)
	clr.w	$d8(a0)	
    rts

_cont:
    moveq	#64,d0			; set voice volumes
	lea	    $dff000,a0
	move.w	d0,$a8(a0)
	move.w	d0,$b8(a0)
    IF _14BIT
		moveq	#1,d0
    ENDIF	
	move.w	d0,$c8(a0)
	move.w	d0,$d8(a0)
	move.w	#$800f,$96(a0)		
    
    bsr     StartTask
    rts

songOverPtr     dc.l    0
lastMessagePtr  dc.l    0


;------------------------------------------------------------------------------
;------------------------------------------------------------------------------


PAL_CIA_PERIOD		EQU 7093 ;  ~99.997Hz
NTSC_CIA_PERIOD		EQU 7158 ; ~100.001Hz

; Total sample buffer size in samples. Not the actual mix length per frame.
SMP_BUFF_SIZE		EQU 8192

LOOP_UNROLL_SIZE	EQU 1024
MIN_PERIOD		EQU 64		; Paula period, that is
MAX_PERIOD		EQU 450		; ^^^
MAX_NOTES 		EQU (12*10*16)+16
MAX_CHANNELS		EQU 32
MAX_PATH_LEN 		EQU 512		; ought to be plenty
NUM_ERROR_MSGS 		EQU 6

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

SEEK_SET		EQU -1
SEEK_CUR		EQU 0
MODE_OLDFILE		EQU 1005
MEMF_ANY		EQU 0
MEMF_CHIP		EQU 2
MEMF_FAST		EQU 4
MEMF_CLEAR		EQU 65536
MEMF_TOTAL		EQU 524288
NT_INTERRUPT		EQU 2
INTB_AUD0		EQU 7
INTF_AUD0		EQU 128
LN_NAME			EQU 10
LN_PRI			EQU 9
LN_TYPE			EQU 8
NT_TASK			EQU 1
TC_SIZE			EQU 92
TC_SPLOWER		EQU 58
TC_SPREG		EQU 54
TC_SPUPPER		EQU 62
TASK_STACK_SIZE		EQU 4096
SIGBREAKF_CTRL_C	EQU 4096
SIGF_SINGLE		EQU 16

_LVOAddICRVector	EQU -6
_LVORemICRVector	EQU -12
_LVOOpen		EQU -30
_LVOAllocFileRequest	EQU -30
_LVOClose		EQU -36
_LVOFreeFileRequest	EQU -36
_LVORead		EQU -42
_LVORequestFile		EQU -42
_LVOWrite		EQU -48
_LVOSeek		EQU -66
_LVOForbid		EQU -132
_LVOPermit		EQU -138
_LVOSetIntVector	EQU -162
_LVORemIntServer	EQU -174
_LVOAllocMem		EQU -198
_LVOFreeMem		EQU -210
_LVOWaitTOF		EQU -270
_LVOAddTask		EQU -282
_LVOFindTask		EQU -294
_LVOSetSignal		EQU -306
_LVOWait		EQU -318
_LVOSignal		EQU -324
_LVOAllocSignal		EQU -330
_LVOFreeSignal		EQU -336
_LVOCloseLibrary	EQU -414
_LVOOpenDevice		EQU -444
_LVOCloseDevice		EQU -450
_LVOOpenResource	EQU -498
_LVOOpenLibrary		EQU -552
_LVOPutStr		EQU -948

swap16	MACRO
	rol.w	#8,\1
	ENDM
	
swap32	MACRO
	rol.w	#8,\1
	swap	\1
	rol.w	#8,\1
	ENDM
	
	; warning: trashes d0!
swap16a	MACRO
	move.l	d0,-(sp)
	move.w	\1,d0
	rol.w	#8,d0
	move.w	d0,\1
	move.l	(sp)+,d0
	ENDM
	
	; warning: trashes d0!
swap32a	MACRO
	move.l	d0,-(sp)
	move.l	\1,d0
	rol.w	#8,d0
	swap	d0
	rol.w	#8,d0
	move.l	d0,\1
	move.l	(sp)+,d0
	ENDM

;------------------------------------------------------------------------------
;                              XM STRUCTURES
;------------------------------------------------------------------------------

;------------------------------
; Channel update flags
;------------------------------
IS_Vol		EQU 1
IS_Period	EQU 2
IS_NyTon	EQU 4
IS_Pan		EQU 8
IS_QuickVol	EQU 16
IB_Vol		EQU 0	; same as the ones above, but bit number
IB_Period	EQU 1
IB_NyTon	EQU 2
IB_Pan		EQU 3
IB_QuickVol	EQU 4

;------------------------------
; Voice flags
;------------------------------
IST_Fwd		EQU 1
IST_Rev		EQU 2
IST_RevDir	EQU 4
IST_Off		EQU 8
IST_Fadeout	EQU 16
IBT_Fwd		EQU 0	; same as the ones above, but bit number
IBT_Rev		EQU 1
IBT_RevDir	EQU 2
IBT_Off		EQU 3
IBT_Fadeout	EQU 4

;------------------------------
; Mixer voice struct
;------------------------------
vLVol1		EQU 0	; L (DON'T CHANGE ORDER!)
vRVol1		EQU 4	; L (DON'T CHANGE ORDER!)
vLVolIP		EQU 8	; L (DON'T CHANGE ORDER!)
vRVolIP		EQU 12	; L (DON'T CHANGE ORDER!)
vLVol2		EQU 16	; L (DON'T CHANGE ORDER!)
vRVol2		EQU 20	; L (DON'T CHANGE ORDER!)
vFrq		EQU 24	; L (DON'T CHANGE ORDER!)
vFrqH32		EQU 28	; L (DON'T CHANGE ORDER!)
vFrqL32		EQU 32	; L (DON'T CHANGE ORDER!)
vFrqH32Inv	EQU 36	; L (DON'T CHANGE ORDER!)
vFrqL32Inv	EQU 40	; L (DON'T CHANGE ORDER!)
vBase		EQU 44	; L (DON'T CHANGE ORDER!)
vLen		EQU 48	; L (DON'T CHANGE ORDER!)
vRepS		EQU 52	; L (DON'T CHANGE ORDER!)
vRepL		EQU 56	; L (DON'T CHANGE ORDER!)
vPos		EQU 60	; L (DON'T CHANGE ORDER!)
vRevBase	EQU 64	; L (DON'T CHANGE ORDER!)
vPosDec		EQU 68 	; L
vVolIPLen	EQU 72	; W
vType		EQU 74	; B
vMixTabOffset	EQU 75	; B
v16Bit		EQU 76	; B
vCenterMixFlag	EQU 77	; B

VOICE_SIZE	EQU 80	; must be a multiple of 4 for longword alignment

;------------------------------
; Replayer channel struct
;------------------------------
cInstrSeg		EQU 0	; L
cSampleSeg		EQU 4	; L
cSmpStartPos		EQU 8	; L
cTonTyp			EQU 12	; W
cRealPeriod		EQU 14	; W
cWantPeriod		EQU 16	; W
cPortaSpeed		EQU 18	; W
cOutPeriod		EQU 20	; W
cFinalPeriod		EQU 22	; W
cFinalVol		EQU 24	; W
cEnvVCnt		EQU 26	; W
cEnvVPos		EQU 28	; W
cEnvVAmp		EQU 30	; W
cEnvVIPValue		EQU 32	; W
cEnvPCnt		EQU 34	; W
cEnvPPos		EQU 36	; W
cEnvPAmp		EQU 38	; W
cEnvPIPValue		EQU 40	; W
cEVibAmp		EQU 42	; W
cEVibSweep		EQU 44	; W	
cFadeOutAmp		EQU 46	; W
cFadeOutSpeed		EQU 48	; W
cEffTyp			EQU 50	; B
cStOff			EQU 51	; B
cInstrNr		EQU 52	; B
cEff			EQU 53	; B
cOldVol			EQU 54	; B
cSmpOffset		EQU 55	; B
cRealVol		EQU 56	; B
cFineTune		EQU 57	; B
cOldPan			EQU 58	; B
cOutPan			EQU 59	; B
cWaveCtrl		EQU 60	; B
cStatus			EQU 61	; B
cPortaDir		EQU 62	; B
cGlissFunk		EQU 63	; B
cVibPos			EQU 64	; B
cTremPos		EQU 65	; B
cVibSpeed		EQU 66	; B
cVibDepth		EQU 67	; B
cTremSpeed		EQU 68	; B
cTremDepth		EQU 69	; B
cPattPos		EQU 70	; B
cLoopCnt		EQU 71	; B
cVolSlideSpeed		EQU 72	; B
cFVolSlideUpSpeed	EQU 73	; B
cFVolSlideDownSpeed	EQU 74	; B
cPortaUpSpeed		EQU 75	; B
cPortaDownSpeed		EQU 76	; B
cFPortaUpSpeed		EQU 77	; B
cFPortaDownSpeed	EQU 78	; B
cEPortaUpSpeed		EQU 79	; B
cEPortaDownSpeed	EQU 80	; B
cRetrigSpeed		EQU 81	; B
cRetrigCnt		EQU 82	; B
cRetrigVol		EQU 83	; B
cOutVol			EQU 84	; B
cRelTonNr		EQU 85	; B
cVolKolVol		EQU 86	; B
cTonNr			EQU 87	; B
cFinalPan		EQU 88	; B        
cEnvSustainActive	EQU 89	; B
cEVibPos		EQU 90	; B
cTremorSave		EQU 91	; B
cTremorPos		EQU 92	; B
cGlobVolSlideSpeed	EQU 93	; B
cPanningSlideSpeed	EQU 94	; B
cWantTon		EQU 95	; B
cMute			EQU 96	; B

CHN_SIZE		EQU 100	; must be a multiple of 4 for longword alignment

XM_HDR_SIZE		EQU 336

;------------------------------
; Sample struct
;------------------------------
sPek		EQU 0	; L (DON'T CHANGE ORDER!)
sLen		EQU 4	; L (DON'T CHANGE ORDER!)
sRepS		EQU 8	; L (DON'T CHANGE ORDER!)
sRepL		EQU 12	; L (DON'T CHANGE ORDER!)
sOrigLen	EQU 16  ; L
sOrigRepL	EQU 20	; L
sLenInFile	EQU 24	; L
sTimesToUnroll	EQU 28  ; W
sVol		EQU 30	; B
sFine		EQU 31	; B
sLoopType	EQU 32	; B (8bb: was Typ, but no 16-bit smps, so it's all we need)
sPan		EQU 33	; B
sRelTon		EQU 34	; B
s16Bit		EQU 35	; B

SMP_SIZE	EQU 36	; Must be a multiple of 4 for longword alignment.
			; If you change this, remember to update INS_SIZE below

;------------------------------
; Instrument struct
;------------------------------
iTA		EQU 0	; 96 bytes
iEnvVP		EQU 96	; 24 words
iEnvPP		EQU 144	; 24 words
iEnvVPAnt	EQU 192	; B
iEnvPPAnt	EQU 193	; B
iEnvVSust	EQU 194	; B
iEnvVRepS	EQU 195	; B
iEnvVRepE	EQU 196	; B
iEnvPSust	EQU 197	; B
iEnvPRepS	EQU 198	; B
iEnvPRepE	EQU 199	; B
iEnvVTyp	EQU 200	; B
iEnvPTyp	EQU 201	; B
iVibTyp		EQU 202	; B
iVibSweep	EQU 203	; B
iVibDepth	EQU 204	; B
iVibRate	EQU 205	; B
iFadeOut	EQU 206	; W
iAntSamp	EQU 208	; W
; --------------------------------- (8bb: pre-calcs to prevent realtime DIVs)
iSweepDelta	EQU 210 ; W
iEnvVDeltas	EQU 212 ; 12 words
iEnvPDeltas	EQU 236 ; 12 words
; ---------------------------------
iMute		EQU 260	; B
iSamp		EQU 264	; 16*SMPSIZE (must be multiple of 4)

INS_SIZE	EQU 840	; 264+(16*SMPSIZE) (must be multiple of 4)

;------------------------------
; Instrument header struct
;------------------------------
ihInstrSize	EQU 0	; L
ihName		EQU 4	; 22 bytes
ihTyp		EQU 26	; B
ihAntSamp	EQU 27	; W
ihSampleSize	EQU 29	; L
ihTA		EQU 33	; 96 bytes
ihEnvVP		EQU 129	; 24 words 
ihEnvPP		EQU 177 ; 24 words 
ihEnvVPAnt	EQU 225	; B
ihEnvPPAnt	EQU 226	; B
ihEnvVSust	EQU 227	; B
ihEnvVRepS	EQU 228	; B
ihEnvVRepE	EQU 229	; B
ihEnvPSust	EQU 230	; B
ihEnvPRepS	EQU 231	; B
ihEnvPRepE	EQU 232	; B
ihEnvVtyp	EQU 233	; B
ihEnvPtyp	EQU 234	; B
ihVibTyp	EQU 235	; B
ihVibSweep	EQU 236	; B
ihVibDepth	EQU 237	; B
ihVibRate	EQU 238	; B
ihFadeOut	EQU 239	; W
ihMIDIOn	EQU 241	; B
ihMIDIChannel	EQU 242	; B
ihMIDIProgram	EQU 243	; W
ihMIDIBend	EQU 245	; W
ihMute		EQU 247	; B
ihReserved	EQU 248 ; 15 bytes

INS_HDR_SIZE	EQU 263

;------------------------------
; Sample header struct
;------------------------------
shLen		EQU 0	; L (DON'T CHANGE ORDER!)
shRepS		EQU 4	; L (DON'T CHANGE ORDER!)
shRepL		EQU 8	; L (DON'T CHANGE ORDER!)
shVol		EQU 12	; B
shFine		EQU 13	; B
shTyp		EQU 14	; B
shPan		EQU 15	; B
shRelTon	EQU 16	; B
shReserved	EQU 17	; B
shName		EQU 18	; 22 bytes

SMP_HDR_SIZE	EQU 40

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

	;SECTION maincode,CODE
	
	bra.w	MAIN
	dc.b "\\0$VER: 0.40"
	EVEN
	
	;-------------------------------------------------
	; Input:
	;   d1.l = pointer to NUL-terminated string
	;-------------------------------------------------
PutStr
	movem.l	d0/d1/a0/a1/a6,-(sp)
	move.l	DosBase(pc),a6
	;jsr	_LVOPutStr(a6)
    move.l  d1,lastMessagePtr
	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts

	;-------------------------------------------------
	; Input:
	;   d0.l = memory block size
	;   d1.l = alloc flags
	;
	; Output:
	;   d0.l = pointer to memory block
	;-------------------------------------------------
AllocMem
	movem.l	d1/a0/a1/a6,-(sp)
	move.l	4.w,a6
	jsr	_LVOAllocMem(a6)
	movem.l	(sp)+,d1/a0/a1/a6
	rts

	;-------------------------------------------------
	; Input:
	;   a1   = pointer to memory block
	;   d0.l = memory block size (must be same as when AllocMem'd)
	;-------------------------------------------------	
FreeMem	movem.l	d0/d1/a0/a1/a6,-(sp)
	move.l	4.w,a6
	jsr	_LVOFreeMem(a6)
	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts

	; some POSIX-like functions

	;-------------------------------------------------
	; Input:
	;   a0   = pointer to source NUL-terminated string
	;
	; Output:
	;   d0.l = string length
	;-------------------------------------------------
strlen
	movem.l	a0/a1,-(sp)
	move.l	a0,a1
.loop	tst.b	(a0)+
	bne.b	.loop
	addq	#1,a1
	sub.l	a1,a0
	move.l	a0,d0
	movem.l	(sp)+,a0/a1
	rts

	;-------------------------------------------------
	; Input:
	;   a0 = pointer to dest.  NUL-terminated string
	;   a1 = pointer to source NUL-terminated string
	;-------------------------------------------------
strcpy
	movem.l	a0/a1,-(sp)
.loop	move.b	(a1)+,(a0)+
	bne.b	.loop
	movem.l	(sp)+,a0/a1
.end	rts

	;-------------------------------------------------
	; Input:
	;   d0.l = max read length
	;   a0   = pointer to NUL-terminated string #1
	;   a1   = pointer to NUL-terminated string #2
	; Output:
	;   d0.l = 0 = same (BEQ), 1 = not same (BNE)
	;-------------------------------------------------
strncmp
	movem.l	a0/a1,-(sp)
.loop	cmpm.b	(a0)+,(a1)+
	bne.b	.error
	subq.b	#1,d0
	beq.b	.done
	tst.b	-1(a0)
	bne.b	.loop
.done	moveq	#0,d0
	movem.l	(sp)+,a0/a1
	rts
.error	moveq	#1,d0
	movem.l	(sp)+,a0/a1
	rts
	
	;-------------------------------------------------
	; Input:
	;   d1.l = pointer to NUL-terminated filename string
	;   d2.l = file access mode
	;
	; Output:
	;   d0.l = file handle
	;-------------------------------------------------
fopen	movem.l	d1/a0/a1/a6,-(sp)
	move.l	DosBase(pc),a6
	jsr	_LVOOpen(a6)
	movem.l	(sp)+,d1/a0/a1/a6
	rts

	;-------------------------------------------------
	; Input:
	;   d1.l = file handle
	;-------------------------------------------------
fclose	movem.l	d0/d1/a0/a1/a6,-(sp)
	move.l	DosBase(pc),a6
	jsr	_LVOClose(a6)
	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts
	
	;-------------------------------------------------
	; Input:
	;   d1.l = file handle
	;   d2.l = pointer to destination buffer
	;   d3.l = bytes to read
	;
	; Output:
	;   d0.l = actual bytes written
	;-------------------------------------------------	
fread	movem.l	d1/a0/a1/a6,-(sp)
	move.l	DosBase(pc),a6
	jsr	_LVORead(a6)
	movem.l	(sp)+,d1/a0/a1/a6
	rts
	
	;-------------------------------------------------
	; Input:
	;   d1.l = file handle
	;   d2.l = position
	;   d3.l = seek mode
	;
	; Output:
	;   d0.l = old position
	;-------------------------------------------------	
fseek	movem.l	d1/a0/a1/a6,-(sp)
	move.l	DosBase(pc),a6
	jsr	_LVOSeek(a6)
	movem.l	(sp)+,d1/a0/a1/a6
	rts

	;-------------------------------------------------
	; Input:
	;   d1.l = file handle
	;
	; Output:
	;   d0.b = byte
	;-------------------------------------------------
ReadByte
	movem.l	d1-d3/a0/a1/a6,-(sp)
	move.l	DosBase(pc),a6
	moveq	#1,d3
	move.l	#tmp8,d2
	clr.b	tmp8
	jsr	_LVORead(a6)
	move.b	tmp8(pc),d0
	movem.l	(sp)+,d1-d3/a0/a1/a6
	rts
	
	;-------------------------------------------------
	; Input:
	;   d1.l = file handle
	;
	; Output:
	;   d0.w = byteswapped word
	;-------------------------------------------------	
ReadLittleEndian16
	movem.l	d1-d3/a0/a1/a6,-(sp)
	move.l	DosBase(pc),a6
	moveq	#2,d3
	move.l	#tmp16,d2
	clr.w	tmp16
	jsr	_LVORead(a6)
	move.w	tmp16(pc),d0
	swap16	d0
	movem.l	(sp)+,d1-d3/a0/a1/a6
	rts
	
	;-------------------------------------------------
	; Input:
	;   d1.l = file handle
	;
	; Output:
	;   d0.l = byteswapped longword
	;-------------------------------------------------
ReadLittleEndian32
	movem.l	d1-d3/a0/a1/a6,-(sp)
	move.l	DosBase(pc),a6
	move.l	#tmp32,d2
	moveq	#4,d3
	clr.l	tmp32
	jsr	_LVORead(a6)
	move.l	tmp32(pc),d0
	swap32	d0
	movem.l	(sp)+,d1-d3/a0/a1/a6
	rts
	
	; -----------------------------------------------------------
	; -----------------------------------------------------------

StartTask
    tst.l   WorkerTask
	bne.b	.done
	; ------------------------------------
	move.l  4.w,a6
	sub.l   a1,a1	; a1 = 0
    jsr     _LVOFindTask(a6)
    move.l  d0,MainTask
	; ------------------------------------
    moveq   #0,d0
    moveq   #SIGF_SINGLE,d1
    jsr     _LVOSetSignal(a6)
	; ------------------------------------
	lea     WorkerTaskStruct,a0
	move.b  #NT_TASK,LN_TYPE(a0)
	move.b  #-1,LN_PRI(a0)
	move.l  #WorkerTaskName,LN_NAME(a0)
	lea     WorkerTaskStack,a1
	move.l  a1,TC_SPLOWER(a0)
	lea     TASK_STACK_SIZE(a1),a1
	move.l  a1,TC_SPUPPER(a0)
	move.l  a1,TC_SPREG(a0)
	; ------------------------------------
	move.l  a0,a1
	lea     WorkerEntry(pc),a2
	sub.l   a3,a3	; a3 = 0
	jsr     _LVOAddTask(a6)
	; ------------------------------------
    moveq   #SIGF_SINGLE,d0
    jsr     _LVOWait(a6)
.done	rts

StopTask
	move.l  4.w,a6
    jsr     _LVOForbid(a6)
	tst.l	WorkerTask
	beq.b	.done
	; ------------------------------------
    moveq   #0,d0
    moveq   #SIGF_SINGLE,d1
    jsr     _LVOSetSignal(a6)
	; ------------------------------------
    ; Send a break to the worker
    move.l  WorkerTask(pc),a1
    move.l  #SIGBREAKF_CTRL_C,d0
    jsr     _LVOSignal(a6)
	; ------------------------------------
    jsr     _LVOPermit(a6)
    ; ------------------------------------
     ; Wait for confirmation
    moveq   #SIGF_SINGLE,d0
    jsr     _LVOWait(a6)
    rts
.done	
    jsr     _LVOPermit(a6)
    rts

WorkerEntry
    move.l  4.w,a6
	sub.l   a1,a1	; a1 = 0
    jsr     _LVOFindTask(a6)
    move.l  d0,WorkerTask
    ; ------------------------------------
    move.l  MainTask(pc),a1
    moveq   #SIGF_SINGLE,d0
    jsr     _LVOSignal(a6)
    ; ------------------------------------
.loop	move.l	GraphicsBase(pc),a6
	jsr     _LVOWaitTOF(a6)	; wait for frame's idle time
	bsr.w	MixAudioFrame
	; ------------------------------------
    ; Check for the break signal
	; ------------------------------------
    move.l  4.w,a6
    moveq   #0,d0
    moveq   #0,d1
    jsr     _LVOSetSignal(a6)
    and.l   #SIGBREAKF_CTRL_C,d0
    beq.b   .loop
	; ------------------------------------
    ; Signal main task that we're done
	; ------------------------------------
    jsr     _LVOForbid(a6)
    clr.l   WorkerTask
    move.l  MainTask(pc),a1
    move.l  #SIGF_SINGLE,d0
    jsr     _LVOSignal(a6)
    rts

SilencePaula
	move.l	a0,-(sp)
	lea	$dff000,a0
	clr.w	$a8(a0)		; set volumes to zero
	clr.w	$b8(a0)
	clr.w	$c8(a0)
	clr.w	$d8(a0)
	move.w	#$000f,$96(a0)	; turn off voice DMAs
	move.l	(sp)+,a0
	rts

MAIN
	move.l	a0,ArgStr
	move.l	d0,ArgStrLen
	; ----------------------------
	bsr.w	OpenDOSLib
	; ----------------------------
	move.l	#HeaderText,d1
	bsr.w	PutStr
	; ----------------------------
	move.l	4.w,a6			; test if we have a 68020+ CPU
	btst	#1,297(a6)
	beq.w	CpuIs68000
	; ----------------------------
	bsr.w	GetFileNameFromArg
	bne.b	.skip			; we got filename from cmd line arg
	bsr.w	GetFileFromRequester
	beq.w	mainRts
.skip	; ----------------------------
	bsr.w	SetupAudio
	beq.w	mainErr
	bsr.w	LoadXM
	bne.w	mainErr
	; ----------------------------
	bsr.w	PlaySong	
	move.l	#IsPlayingText,d1
	bsr.w	PutStr
	bsr.w	StartMixing
	bne.w	mainErr
	; ----------------------------
	bsr.w	OpenGraphicsLib
	bsr.w	StartTask
    bra     mainRts
;.mainLoop
;	move.l	GraphicsBase(pc),a6
;	jsr	_LVOWaitTOF(a6)	; we're now at the frame's idle time, call software mixer
;
;	move.b	$BFEC01,d0	; read key (NOT system-friendly, but works for now)
;	not.b   d0
;	ror.b   #1,d0		; d0 = raw key
;	
;	cmp.b	#$4E,d0		; check for right arrow key
;	beq.b	.right
;	
;	cmp.b	#$4F,d0		; check for left arrow key
;	beq.b	.left
;	
;	cmp.b   #$45,d0		; check for Esc key
;	beq.b	.done
;	
;	bra.b	.mainLoop
;	
;.right
;	bsr.w	NextPattern
;	bra.b	.mainLoop
;.left
;	bsr.w	PrevPattern
;	bra.b	.mainLoop
;
;.done	bsr.w	StopTask
	; --------------------
	; --------------------
cleanUp:
	bsr.w	CloseGraphicsLib
	bsr.w	StopMixing
	bsr.w	CloseAudio
	bsr.w	FreeMusic
	bsr.w	SilencePaula	; again (needed after FreeMusic() call)
	; --------------------	
	bsr.w	CloseDOSLib
mainRts	moveq	#0,d0
	rts

mainErr	bsr.w	CloseAudio
	bsr.w	FreeMusic
	bsr.w	SilencePaula
	bsr.w	CloseDOSLib
	moveq	#1,d0
	rts

OpenGraphicsLib
	move.l	4.w,a6
	lea	GraphicsName(pc),a1
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,GraphicsBase
	rts
	
CloseGraphicsLib
	tst.l	GraphicsBase(pc)
	beq.b	.done
	move.l	4.w,a6
	move.l	DosBase(pc),a1
	jsr	_LVOCloseLibrary(a6)
.done	rts
	
OpenDOSLib
	move.l	4.w,a6
	lea	DosName(pc),a1
	moveq	#36,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,DosBase
	rts	
	
CloseDOSLib
	tst.l	DosBase(pc)
	beq.b	.done
	move.l	4.w,a6
	move.l	DosBase(pc),a1
	jsr	_LVOCloseLibrary(a6)
.done	rts

CpuIs68000
	move.l	#CpuErrText,d1
	bsr.w	PutStr
	bra.w	mainErr
	
	; Input: a0
RightTrim
	movem.l	d0/a0,-(sp)
	tst.l	a0	; NULL pointer?
	beq.b	.end
	tst.b	(a0)	; string empty?
	beq.b	.end
	bsr.w	strlen	; d0 = string length
	add.l	d0,a0
.loop	cmp.b	#' ',-(a0)
	bne.b	.ok
	dbra	d0,.loop
.ok	clr.b	1(a0)
.end	movem.l	(sp)+,d0/a0
	rts

GetFileNameFromArg
	move.l	ArgStr(pc),a0
	move.l	ArgStrLen(pc),d0
	cmp.l	#1+2,d0			; space after progname is counted for
	bls.b	.err
	subq.l	#1,d0
	cmp.l	#MAX_PATH_LEN,d0
	bls.b	.ok
	move.l	#MAX_PATH_LEN,d0
.ok	subq.l	#1,d0
	lea	FileName,a1
	; --------------------------
	; Remove quotes (if present)
	; --------------------------
	cmp.b	#'"',(a0)
	bne.b	.L1
	addq	#1,a0
	subq.l	#1,d0
.L1	move.l	a0,a2
	add.l	d0,a2			; a2 = last character in string	
	cmp.b	#'"',(a2)
	bne.b	.L2
	clr.b	(a2)
	subq	#1,d0
.L2	; --------------------------
.loop	move.b	(a0)+,(a1)+
	dbra	d0,.loop
	clr.b	(a1)			; just in case
	; --------------------------
	lea	FileName,a0
	bsr.w	RightTrim		; remove spaces from end of string
	; --------------------------
	moveq	#1,d0
	rts
.err	moveq	#0,d0
	rts

; This routine is hardcoded for GetFileFromRequester
CreateAbsoluteFilename
	movem.l	d0-a6,-(sp)
	lea	FileName,a2
	move.l	8(a1),a3	; a3 = rf_Dir (directory string)
	move.l	4(a1),a4	; a4 = rf_File (filename string)
	; --------------------
	move.l	a3,a0
	tst.b	(a0)		; string empty?
	beq.b	.noDir
	bsr.w	strlen
	move.l	d0,d1		; d1 = strlen(rf_Dir)
	; --------------------
	move.l	a2,a0
	move.l	a3,a1
	bsr.w	strcpy
	add.l	d1,a2		; a2 now points to end of directory string
	cmp.b	#':',-1(a2)	; was we in the root of a different volume?
	beq.b	.noDir		; yep, don't add directory delimiter
	move.b	#'/',(a2)+
	clr.b	(a2)
.noDir	; --------------------
	move.l	a2,a0		; destination
	move.l	a4,a1		; source
	bsr.w	strcpy
	movem.l	(sp)+,d0-a6
	rts

GetFileFromRequester
	movem.l	d1/d2/a1/a6,-(sp)
	move.l	4.w,a6
	lea	ASLName(pc),a1
	moveq	#36,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,ASLBase
	beq.b	ofrErr
	; -----------------------------
	move.l	d0,a6
	jsr	_LVOAllocFileRequest(a6)
	move.l	d0,FileReqStruct
	move.l	d0,a0
	jsr	_LVORequestFile(a6)
	move.l	d0,d7
	; -----------------------------
	move.l	FileReqStruct(pc),a1
	bsr.w	CreateAbsoluteFilename
	; -----------------------------
	move.l	FileReqStruct(pc),a0
	jsr	_LVOFreeFileRequest(a6)
	moveq	#0,d0
	tst.l	d7			; did we close the requster?
	beq.b	ofrDone			; yep, file not selected.
	; -----------------------------
ofrOK	moveq	#1,d0
ofrDone	; -----------------------------
	move.l	ASLBase(pc),a1
	tst.l	a1
	beq.b	.skip
	move.l	4.w,a6
	move.l	d0,-(sp)
	jsr	_LVOCloseLibrary(a6)
	move.l	(sp)+,d0
	; -----------------------------
.skip	movem.l	(sp)+,d1/d2/a1/a6
	rts
ofrErr	moveq	#0,d0
	bra.b	ofrDone


; ------------------------------------------------------------------------------
;                                AUDIO ROUTINES
; ------------------------------------------------------------------------------
; This part of the code is heavily inspired by the PS3M source code
; I have also borrowed some of its code, and modified it.

	; called when Paula buffer is about to play from the beginning
	; a0 = $dff000
	; a1 = PaulaPos
PaulaInterrupt
	clr.l	(a1)
	move.w	#INTF_AUD0,$9c(a0)	; acknowledge Paula interrupt
	rts

	; updates current Paula buffer position (D0-D1/A0-A1 can safely be trashed)
	; a1 = PaulaPos
CIAInterrupt
	move.l	(a1),d0			; 16.16fp (keep cached, update once done)
	add.l	PaulaPosDelta(pc),d0
	and.l	PaulaPosMask(pc),d0	; mask integer part to SMP_BUFF_SIZE-1
	move.l	d0,(a1)
	rts

SetPaulaInterrupt
	moveq	#INTB_AUD0,d0
	lea	PaulaIntStruct(pc),a1
	move.l	4.w,a6
	jsr	_LVOSetIntVector(a6)
	move.l	d0,OldPaulaInt
	rts

RestorePaulaInterrupt
	lea	$dff000,a1
	move.w	#INTF_AUD0,$9c(a1)	; clear pending AUD0 interrupt
	move.w	#INTF_AUD0,$9a(a1)	; disable interrupt
	; -------------------------
	moveq	#INTB_AUD0,d0
	lea	OldPaulaInt(pc),a1
	move.l	4.w,a6
	jsr	_LVOSetIntVector(a6)
	rts
	
OpenAudioDevice
	move.l	4.w,a6
	moveq	#-1,d0
	jsr	_LVOAllocSignal(a6)
	move.b	d0,SigBit
	bmi.w	.error
	; -------------------------
	lea	AllocPort(pc),a1
	move.b	d0,15(a1)
	move.l	a1,-(sp)
	suba.l	a1,a1
	jsr	_LVOFindTask(a6)
	move.l	(sp)+,a1
	move.l	d0,16(a1)
	lea	ReqList(pc),a0
	move.l	a0,(a0)
	addq.l	#4,(a0)
	clr.l	4(a0)
	move.l	a0,8(a0)
	; -------------------------
	lea	AllocReq(pc),a1
	lea	AudioDevName(pc),a0
	moveq	#0,d0
	moveq	#0,d1
	jsr	_LVOOpenDevice(a6)
	tst.b	d0
	bne.b	.error
	st	AudioOpen
	moveq	#0,d0
	rts
.error	moveq	#1,d0
	rts

CloseAudioDevice
	move.l	4.w,a6
	tst.b	AudioOpen(pc)
	beq.b	.L0
	lea	AllocReq(pc),a1
	jsr	_LVOCloseDevice(a6)
.L0	moveq	#0,d0
	move.b	SigBit(pc),d0
	bmi.b	.L1
	jsr	_LVOFreeSignal(a6)
.L1	rts

	; d0.w = CIA period
SetupCIATimer
	moveq	#8,d3
	lea	CIAName(pc),a1
	move.b	#'a',3(a1)
.openciares
	move.l	4.w,a6
	jsr	_LVOOpenResource(a6)
	move.l	d0,CIARes
	beq.b	.tryCIAB
	move.l	d0,a6
	lea	CIAIntStruct(pc),a1
	moveq	#0,d0
	jsr	_LVOAddICRVector(a6)
	tst.l	d0
	beq.b	.gottimer
	addq.l	#4,d3
	lea	CIAIntStruct(pc),a1
	moveq	#1,d0
	jsr	_LVOAddICRVector(a6)
	tst.l	d0
	beq.b	.gottimer
.tryCIAB
	lea	CIAName(pc),a1
	cmp.b	#'a',3(a1)
	bne.w	.error
	addq.b	#1,3(a1)
	moveq	#0,d3
	bra.b	.openciares
.gottimer
	lea	8+craddr(pc),a6
	lea	CIAAddr(pc),a2
	move.l	(a2,d3.w),d0
	move.l	d0,(a6)
	sub.w	#$100,d0
	move.l	d0,-(a6)
	moveq	#2,d3
	btst	#9,d0
	bne.b	.timerB
	subq.b	#1,d3
	add.w	#$100,d0
.timerB
	add.w	#$900,d0
	move.l	d0,-(a6)
	move.l	d0,a0
	and.b	#%10000000,(a0)
	move.b	d3,WhichCIAOpen
	; -------------------------
	move.l	4+craddr(pc),a1
	move.w	CIA_Period(pc),d0
	move.b	d0,(a1)
	lsr.w	#8,d0
	move.b	d0,$100(a1)
	move.b	#$11,(a0)		; continuous, force load
	moveq	#0,d0
	rts
.error	moveq	#1,d0
	rts
	
CloseCIATimer
	moveq	#0,d0
	move.b	WhichCIAOpen(pc),d0
	beq.b	.done
	subq.b	#1,d0
	move.l	CIARes(pc),a6
	lea	CIAIntStruct(pc),a1
	jsr	_LVORemICRVector(a6)
	clr.b	WhichCIAOpen
.done	rts

StartMixing
	bsr.w	SetPaulaInterrupt
	; -----------------------------
	lea	$dff000,a0
	; -----------------------------
	; Enable Paula interrupts and DMAs
	; -----------------------------
	move.w	#$8000!INTF_AUD0,$9a(a0)
	move.w	#$800f,$96(a0)
	; -------------------------
	clr.l	PaulaPos
	clr.l	MixPos
	bsr.w	SetupCIATimer
	bne.b	.error			; no free CIA timers...
	; -----------------------------
	bsr.w	EnableAudioMixer
	moveq	#0,d0
	rts
.error	move.l	#CIAErrTxt,d1
	bsr.w	PutStr
	moveq	#1,d0
	rts

StopMixing
	sf	SongIsPlaying
	bsr.w	DisableAudioMixer	; also clears Paula volumes
	; ---------------------------
	move.w	#$000f,$dff096		; stop Paula DMAs
	; ---------------------------
	bsr.w	RestorePaulaInterrupt
	bsr.w	CloseCIATimer
	rts

MixAudioFrame
	moveq	#0,d2
	move.w	PaulaPos(pc),d2	; d2.l = integer part of PaulaPos
	move.l	MixPos(pc),d0
	cmp.l	d2,d0
	ble.b	.norm
	sub.l	#SMP_BUFF_SIZE,d0
.norm	move.l	PaulaPosDelta(pc),d1
	lsr.l	#8,d1
	lsr.l	#7,d1		; *2.0 (keep MSB frac bit)
	add.l	d0,d1
	; ---------------------
	sub.l	d1,d2
	bmi.b	.end
	; ---------------------
	and.l	#~3,d2		; align to blocks of 4 (important)
	; ---------------------
	cmp.l	#16,d2
	blt.b	.end
	; ---------------------
	move.l	d2,MixSamples
	; ---------------------
	tst.b	AudioMixFlag(pc)
	beq.b	.skip
	; ---------------------
	st	AudioMixRunning
	bsr.w	Mix_UpdateBuffer
	sf	AudioMixRunning
.skip	; ---------------------
	; Update mixing position
	; ---------------------
	move.l	MixPos(pc),d0
	add.l	MixSamples(pc),d0
	and.l	#SMP_BUFF_SIZE-1,d0
	move.l	d0,MixPos
.end	rts

; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
	
Mix_ClearChannels
	; ----------------------------
	; Set initial channel relocs (volume ramping uses this)
	; ----------------------------
	lea	ChnReloc,a0
	move.w	#MAX_CHANNELS-1,d7
	moveq	#0,d0
.loop1	move.w	d0,(a0)+
	addq.w	#2,d0
	dbra	d7,.loop1
	; ----------------------------
	; Set voice offsets
	; ----------------------------
	lea	VoiceOffsets,a0
	lea	MixVoices,a6
	move.w	#(MAX_CHANNELS*2)-1,d7
.loop2	move.l	a6,(a0)+
	lea	VOICE_SIZE(a6),a6
	dbra	d7,.loop2
	; ----------------------------
	; Clear voices
	; ----------------------------
	lea	MixVoices,a6
	move.w	#((VOICE_SIZE*MAX_CHANNELS*2)/4)-1,d7
	moveq	#0,d0
.loop3	move.l	d0,(a6)+
	dbra	d7,.loop3
	; ----------------------------
	rts

ClearChannels
	movem.l	d0-a6,-(sp)
	; ----------------------------
	sf	SongIsPlaying
	bsr.w	DisableAudioMixer
	; ----------------------------
	bsr.w	Mix_ClearChannels
	; ----------------------------
	; Clear replayer channels
	; ----------------------------
	lea	StmTyp,a5
	move.w	#((CHN_SIZE*MAX_CHANNELS)/4)-1,d7
	moveq	#0,d0
.loop1	move.l	d0,(a5)+
	dbra	d7,.loop1
	; ----------------------------
	; Set initial replayer channel values
	; ----------------------------
	lea	StmTyp,a5
	move.w	#MAX_CHANNELS-1,d7
	move.b	#128,d0	; center panning
	move.b	#IS_Vol,d1
	move.l	#SpareInstr,d2
.loop2	move.b	d0,cOldPan(a5)
	move.b	d0,cOutPan(a5)
	move.b	d0,cFinalPan(a5)
	move.b	d1,cStatus(a5)
	move.l	d2,cInstrSeg(a5)
	lea	CHN_SIZE(a5),a5
	dbra	d7,.loop2
	; -------------------
	bsr.w	EnableAudioMixer
	; -------------------
	movem.l	(sp)+,d0-a6
	rts

CloseAudio
	bsr.w	CloseAudioDevice
	; ----------------------------
	bsr.w	FreeChipBuffers
	bsr.w	FreePostMixTable	
	; ----------------------------
	; Set back old LED filter state
	; ----------------------------
	bclr	#1,$bfe001		
	move.b	OldLEDStatus(pc),d0
	and.b	#2,d0
	or.b	d0,$bfe001
	rts

SetMixerVars	
	movem.l	d7/a1/a6,-(sp)
	
	; ------------------------------------
	; Test if we have an NTSC machine
	; ------------------------------------
	lea	GraphicsName(pc),a1			
	moveq	#0,d0
	move.l	4.w,a6
	jsr	_LVOOpenLibrary(a6)
	tst.l	d0
	bne.b	.L0
	moveq	#0,d0				; error
	bra.w	.exit
.L0	move.l	d0,a1
	move.w	206(a1),d7
	jsr	_LVOCloseLibrary(a6)
	btst	#2,d7				; Amiga is PAL?
	beq.b	.NTSC				; nope

	; ------------------------------------
	;                 PAL
	; ------------------------------------
	sf	AmigaIsNTSC
	move.w	#PAL_CIA_PERIOD,CIA_Period	; CIA mixing timer period
	; ------------------------------------
	; Calculate PAL 16.16fp mixing frequency
	; ------------------------------------
	move.w	MixPeriod(pc),d0
	moveq	#0,d1	; 0 = PAL
	bsr.w	PaulaPeriodToFreq
	move.l	d0,MixingFreq
	; ------------------------------------
	; Calculate PAL 16.16fp Paula delta
	; ------------------------------------
	move.w	CIA_Period(pc),d0
	move.l	MixingFreq(pc),d1
	moveq	#0,d2	; 0 = PAL
	bsr.w	CalcCiaDelta
	move.l	d0,PaulaPosDelta
	bra.w	.L1

.NTSC	; ------------------------------------
	;                 NTSC
	; ------------------------------------
	st	AmigaIsNTSC
	move.w	#NTSC_CIA_PERIOD,CIA_Period
	; ------------------------------------
	; Calculate NTSC 16.16fp mixing frequency
	; ------------------------------------
	move.w	MixPeriod(pc),d0
	moveq	#1,d1	; 1 = NTSC
	bsr.w	PaulaPeriodToFreq
	move.l	d0,MixingFreq
	; ------------------------------------
	; Calculate NTSC 16.16fp Paula delta
	; ------------------------------------
	move.w	CIA_Period(pc),d0
	move.l	MixingFreq(pc),d1
	moveq	#1,d2	; 1 = NTSC
	bsr.w	CalcCiaDelta
	move.l	d0,PaulaPosDelta

.L1	; ------------------------------------
	; Calculate "quick" volume ramp length
	; ------------------------------------
	move.l	MixingFreq(pc),d0
	add.l	#(200<<16)/2,d0		; rounding bias
	divu.l	#200<<16,d0		; 200 = 5ms (FT2)
	move.w	d0,QuickVolSizeVal
	; -------------------------------------
	bsr.w	GenerateBPMTable
	; -------------------------------------
	moveq	#1,d0
.exit	movem.l	(sp)+,d7/a1/a6
	rts
	
	; Input:
	;  d0.w = CIA period
	;  d1.l = 16.16fp mixing frequency
	;  d2.b = 0 if PAL, 1 if NTSC
	;
	; Output:
	;  d0.l = rounded 16.16fp CIA Paula delta	
CalcCiaDelta
	tst.w	d0
	beq.b	.error
	; ---------------------------
	movem.l	d1-d7,-(sp)
	move.b	d2,d7
	; ---------------------------
	and.l	#$FFFF,d0
	addq.l	#1,d0			; CIA triggers on underflow (add 1 to period)
	swap	d0
	move.l	d0,d2			; d2.l = (ciaPeriod + 1) << 16
	; ---------------------------
	move.l	d1,d0
	swap	d0
	clr.w	d0
	clr.w	d1
	swap	d1			; d1:d0 = d1 << 16
	; ---------------------------		
	move.l	d0,d5
	move.l	d1,d6
	; ---------------------------
	; CIA period -> rounded 16.16fp CIA frequency
	; ---------------------------
	tst.b	d7
	bne.b	.NTSC
	moveq	#0,d0			; PAL
	move.l	#709379,d1		; d1:d0 = round[709379.0 * 2^32] 	
	bra.b	.L0
.NTSC	move.l	#$E8BA2E8C,d0		; NTSC
	move.l	#715909,d1		; d1:d0 = round[715909.0909 (recurring) * 2^32]
.L0	; ---------------------------
	; Add rounding bias
	; ---------------------------
	move.l	d2,d3
	lsr.l	#1,d3
	moveq	#0,d4
	add.l	d3,d0
	addx.l	d4,d1	
	; ---------------------------
	divu.l	d2,d1:d0
	move.l	d0,d2			; d2.l = rounded CIA frequency (16.16fp)
	; ---------------------------
	; Calculate CIA Paula delta
	; ---------------------------
	move.l	d5,d0
	move.l	d6,d1
	; ---------------------------
	; Add rounding bias
	; ---------------------------
	move.l	d2,d3
	lsr.l	#1,d3
	moveq	#0,d4
	add.l	d3,d0
	addx.l	d4,d1	
	; ---------------------------
	divu.l	d2,d1:d0		; d0.l = result
	movem.l	(sp)+,d1-d7
	rts
.error	moveq	#0,d0
	rts

	; Input:
	;   d0.w = period
	;   d1.b = 0 if PAL, 1 if NTSC
	;
	; Output:
	;   d0.l = rounded 16.16fp frequency
PaulaPeriodToFreq
	movem.l	d1-d4,-(sp)
	tst.w	d0
	bne.b	.Not0
	moveq	#-1,d0			; period 0 = period 65535 on Amiga
	; ---------------------------
.Not0	move.l	d0,d2
	swap	d2
	clr.w	d2			; d2.l = period * 65536
	; ---------------------------
	tst.b	d1
	bne.b	.NTSC
	moveq	#0,d0			; PAL
	move.l	#3546895,d1 		; d1:d0 = round[3546895.0 * 2^32]
	bra.b	.L0
.NTSC	move.l	#$745D1746,d0		; NTSC
	move.l	#3579545,d1 		; d1:d0 = round[3579545.4545 (recurring) * 2^32]	
.L0	; ---------------------------
	; Add rounding bias
	; ---------------------------
	move.l	d2,d3
	lsr.l	#1,d3
	moveq	#0,d4
	add.l	d3,d0
	addx.l	d4,d1
	; ---------------------------
	divu.l	d2,d1:d0		; d0.l = rounded Paula frequency (16.16fp)
	movem.l	(sp)+,d1-d4
	rts

; converts BPM 32..255 into SamplesPerTick LUT (16.16fp)
GenerateBPMTable
	lea	BPM2SmpsPerTick,a0
	move.l	MixingFreq(pc),d3	; 16.16fp
	moveq	#32,d5			; starting BPM
	move.l	d3,d6
	move.l	d3,d4
	lsr.l	#7,d6
	lsl.l	#8,d4
	lsl.l	#8,d4
	lsl.l	#7,d4			; d6:d4 = MixingFreq(16.16fp) << 25
	moveq	#0,d7
	; ---------------------------
.loop	move.l	d6,d1
	move.l	d4,d0
	; ---------------------------
	move.l	d5,d2			; d2 = BPM (32..255)
	mulu.l	#13421773,d2		; 13421773 = round[2^25 / 2.5]
					; d2 = (BPM / 2.5) * 2^25 (with small error)
	; ---------------------------
	; Add rounding bias
	; ---------------------------
	move.l	d2,d3
	lsr.l	#1,d3
	add.l	d3,d0
	addx.l	d7,d1
	; ---------------------------
	divu.l	d2,d1:d0		; d0.l = rounded samplesPerTick (16.16fp)
	move.l	d0,(a0)+
	; ---------------------------
	addq.b	#1,d5
	bne.b	.loop			; haven't overflown yet (255 -> 0 (256))
	; ---------------------------
	rts

EnableAudioMixer
	st	AudioMixFlag
	; ---------------------------
	; Restore Paula volumes now
	; ---------------------------
	move.w	#64,$dff0a8
	move.w	#64,$dff0b8
	IF _14BIT
		move.w	#1,$dff0c8
		move.w	#1,$dff0d8
	ELSE
		move.w	#64,$dff0c8
		move.w	#64,$dff0d8
	ENDIF
	; ---------------------------
	rts

DisableAudioMixer
	; ---------------------------
	; Clear Paula volumes
	; ---------------------------
	clr.w	$dff0a8
	clr.w	$dff0b8
	clr.w	$dff0c8
	clr.w	$dff0d8
	; ---------------------------
	sf	AudioMixFlag
.loop	tst.b	AudioMixRunning(pc)	; wait until mixer is done
	bne.b	.loop
	rts

FreeChipBuffers
	move.l	PaulaCh1Buf(pc),a1
	tst.l	a1
	beq.b	.L1
	move.l	#SMP_BUFF_SIZE,d0
	bsr.w	FreeMem
	; ---------------------------
.L1	move.l	PaulaCh2Buf(pc),a1
	tst.l	a1
	beq.b	.L2
	move.l	#SMP_BUFF_SIZE,d0
	bsr.w	FreeMem
.L2	; ---------------------------
	IF _14BIT
		move.l	PaulaCh3Buf(pc),a1
		tst.l	a1
		beq.b	.L3
		move.l	#SMP_BUFF_SIZE,d0
		bsr.w	FreeMem
	; ---------------------------
.L3		move.l	PaulaCh4Buf(pc),a1
		tst.l	a1
		beq.b	.L4
		move.l	#SMP_BUFF_SIZE,d0
		bsr.w	FreeMem
.L4	; ---------------------------
	ENDIF
	rts
	
AllocChipBuffers
	move.l	#SMP_BUFF_SIZE,d0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	bsr.w	AllocMem
	tst.l	d0
	beq.b	.error
	move.l	d0,PaulaCh1Buf
	; ---------------------------
	move.l	#SMP_BUFF_SIZE,d0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	bsr.w	AllocMem
	tst.l	d0
	beq.b	.error
	move.l	d0,PaulaCh2Buf
	; ---------------------------
	IF _14BIT
		move.l	#SMP_BUFF_SIZE,d0
		move.l	#MEMF_CHIP!MEMF_CLEAR,d1
		bsr.w	AllocMem
		tst.l	d0
		beq.b	.error
		move.l	d0,PaulaCh3Buf
	; ---------------------------
		move.l	#SMP_BUFF_SIZE,d0
		move.l	#MEMF_CHIP!MEMF_CLEAR,d1
		bsr.w	AllocMem
		tst.l	d0
		beq.b	.error
		move.l	d0,PaulaCh4Buf
	ENDIF
	; ---------------------------
	moveq	#0,d0
	rts
.error	moveq	#1,d0
	rts

SetupAudio
	bsr.w	SilencePaula
	; --------------------
	bsr.w	OpenAudioDevice
	beq.w	.skip0
	move.l	#AudDevErrText,d1
	bsr.w	PutStr
	moveq	#0,d0
	rts
.skip0	; --------------------
	bsr.w	AllocChipBuffers
	beq.b	.skip1
	move.l	#AudErrTxt,d1
	bsr.w	PutStr
	moveq	#0,d0
	rts
.skip1	; --------------------
	bsr.w	AllocPostMixTable
	beq.b	.skip2
	move.l	#AudErrTxt,d1
	bsr.w	PutStr
	moveq	#0,d0
	rts	
.skip2	; --------------------
	move.w	#MIX_PERIOD,d0
	cmp.w	#MIN_PERIOD,d0
	bhs.b	.ok1
	move.w	#MIN_PERIOD,d0
.ok1	cmp.w	#MAX_PERIOD,d0
	bls.b	.ok2
	move.w	#MAX_PERIOD,d0
.ok2	move.w	d0,MixPeriod
	bsr.w	SetMixerVars
	beq.w	.error
	; ---------------------------
	; Turn off LED filter
	; ---------------------------
	move.b	$bfe001,OldLEDStatus
	bset	#1,$bfe001
	; ---------------------------
	bsr.w	GeneratePostMixTable
	move.l	PostMixTable(pc),a0
	IF _14BIT
		add.l	#32768*2,a0
	ELSE
		add.l	#32768,a0
	ENDIF
	move.l	a0,PostMixTableCentered
	; ---------------------------
	; Setup Paula voices
	; ---------------------------
	lea	$dff000,a0
	; ---------------------------
	move.l	PaulaCh1Buf(pc),$a0(a0)	; data
	move.l	PaulaCh2Buf(pc),$b0(a0)
	IF _14BIT
		move.l	PaulaCh3Buf(pc),$c0(a0)
		move.l	PaulaCh4Buf(pc),$d0(a0)
	ELSE
		move.l	PaulaCh2Buf(pc),$c0(a0)
		move.l	PaulaCh1Buf(pc),$d0(a0)
	ENDIF
	; ---------------------------
	move.w	#SMP_BUFF_SIZE/2,d0	; length
	move.w	d0,$a4(a0)
	move.w	d0,$b4(a0)
	move.w	d0,$c4(a0)
	move.w	d0,$d4(a0)
	; ---------------------------
	move.w	MixPeriod(pc),d0	; period
	move.w	d0,$a6(a0)
	move.w	d0,$b6(a0)
	move.w	d0,$c6(a0)
	move.w	d0,$d6(a0)
	; ---------------------------
	; Set default BPM
	; ---------------------------
	moveq	#125,d0
	bsr.w	P_SetSpeed
	clr.l	PMPLeft
	; ---------------------------
	bsr.w	ClearChannels
	; ---------------------------
	moveq	#1,d0
	rts
.error	moveq	#0,d0
	rts

; ------------------------------------------------------------------------------
;                              XM LOADER ROUTINES
; ------------------------------------------------------------------------------

	; frees all patterns
FreePatterns
	move.w	#256-1,d7
	lea	Patt,a2
	lea	PattLens,a0
.loop1	move.l	(a2),a1
	tst.l	a1
	beq.b	.next			; pattern not allocated!
	moveq	#0,d0
	move.w	(a0),d0			; d0.w = rows in pattern
	mulu.w	TrackWidth(pc),d0	; d0.l = unpacked pattern length
	bsr.w	FreeMem			; a1 = patt ptr
.freeP	clr.l	(a2)			; zero out pointer	
.next	move.w	#64,(a0)		; set default pattern length
	addq	#4,a2
	addq	#2,a0
	dbra	d7,.loop1
	rts
	
	; frees all instruments including sample data
FreeInstruments
	moveq	#128-1,d7
	lea	Instr,a2
.loop1	move.l	(a2),a1
	tst.l	a1
	beq.b	.nextI			; instrument is empty!
	; -----------------------------
	; Free instrument's samples
	; -----------------------------
	move.w	iAntSamp(a1),d6
	beq.b	.freeI			; instrument has no samples...
	subq.w	#1,d6	
	lea	iSamp(a1),a0		; a0 = sample struct
.loop2	move.l	sPek(a0),a1
	tst.l	a1			; sample allocated?
	beq.b	.nextS			; nope
	move.l	sLen(a0),d0
	beq.b	.nextS			; (length is zero, don't free)	
	addq.l	#2,d0			; fix-sample for linear interpolation
	bsr.w	FreeMem			; d0.l = len, a1 = smp ptr
.nextS	lea	SMP_SIZE(a0),a0
	dbra	d6,.loop2
	; -----------------------------
	; Free instrument
	; -----------------------------
.freeI	move.l	(a2),a1
	move.l	#INS_SIZE,d0
	bsr.w	FreeMem			; a1 = instr ptr
	clr.l	(a2)			; zero out pointer
.nextI	addq	#4,a2
	dbra	d7,.loop1
	rts

FreeMusic
	movem.l	d0-a6,-(sp)
	sf	SongIsPlaying
	bsr.w	DisableAudioMixer
	; ----------------------------- 
	bsr.w	FreePatterns
	bsr.w	FreeInstruments
.skip	; ----------------------------- 
	bsr.w	EnableAudioMixer
	movem.l	(sp)+,d0-a6
	rts

CloseFile
	move.l	FileHandle(pc),d1
	beq.b	.end	
	bsr.w	fclose
	clr.l	FileHandle
.end	rts

	; d0.b = XM load error
ShowError
	ext.w	d0
	beq.b	.end
	cmp.b	#NUM_ERROR_MSGS,d0
	bhi.b	.end
	subq.b	#1,d0
	lea	ErrorTexts(pc),a0
	move.l	(a0,d0.w*4),d1
	bsr.w	PutStr
.end	moveq	#1,d0		; 1=error
	rts

HandleError
	bsr.w	CloseFile	; error
	bsr.w	FreeMusic
	bra.w	ShowError
	
CalcFrqTab
	movem.l	d0-d6/a0-a2,-(sp)
	lea	Note2Period,a0
	; ----------------------------
	tst.b	LinearFrqTab(pc)
	beq.b	.Amiga

	; -------------------------------------
	; Linear periods
	; -------------------------------------

	move.w	#(192*10+16)*4,d0
	move.w	#(12*10*16+16)-1,d1
.L0	move.w	d0,(a0)+
	subq.w	#4,d0
	dbra	d1,.L0

	; -------------------------------------
	; Calculate log table
	; -------------------------------------	
	move.l	MixingFreq(pc),d2 	; 16.16fp
	move.l	d2,d3
	lsr.l	#1,d3			; rounding bias
	lea	LogTabSource(pc),a0	; src (64-bit)
	lea	LogTab,a1		; dst (32-bit)
	moveq	#0,d4
	move.w	#(12*16*4)-1,d5
.loop	move.l	(a0)+,d0
	move.l	(a0)+,d1
	add.l	d3,d0			; add rounding bias
	addx.l	d4,d1
	divu.l	d2,d1:d0
	move.l	d0,(a1)+
	dbra	d5,.loop
	; -------------------------------------	
	bra.b	.end	


.Amiga	; -------------------------------------
	; Amiga periods
	; -------------------------------------

	lea	AmigaFinePeriod(pc),a2	
	moveq	#12*8,d5
	moveq	#1,d6
	moveq	#0,d2
	moveq	#10,d3
.L1	move.w	d3,d4
	cmp.w	d6,d3	; d3.w == 1?
	beq.b	.Is1
	moveq	#0,d3
.Is1	lsl.w	#3,d3
	add.w	d5,d3
	move.l	a2,a1
	moveq	#-1,d1	; d1.w = $FFFF
	lsl.w	d3,d1
	not.w	d1
.L2	move.w	(a1)+,d0
	lsl.w	#2+3+1,d0
	add.w	d1,d0
	lsr.w	d2,d0
	lsr.w	#1,d0
	move.w	d0,(a0)+
	move.w	d0,(a0)+
	subq.w	#1,d3
	bne.b	.L2
	addq.w	#1,d2
	move.w	d4,d3
	subq.w	#1,d3
	bne.b	.L1

	; -------------------------------------
	; Interpolate between points
	; -------------------------------------
	lea	Note2Period,a0
	move.w	#(12*10*8+7)-1,d2
	move.w	(a0),d1
.L3	move.w	d1,d0
	move.w	4(a0),d1
	add.w	d1,d0
	lsr.w	#1,d0
	move.w	d0,2(a0)
	addq	#4,a0
	dbra	d2,.L3

	; -------------------------------------
	; -------------------------------------

	move.l	#8363*1712,d1
	move.l	MixingFreq(pc),d0
	lsr.l	#1,d0
	divu.l	MixingFreq(pc),d1:d0	; d0.l = round[(8363*1712) * 2^32 / MixingFreq]
	move.l	d0,FrequenceDivFactor

	; -------------------------------------
.end	movem.l	(sp)+,d0-d6/a0-a2
	rts

LoadXM
	bsr.w	FreeMusic
	;---------------------------
	; Open file
	;---------------------------
	move.l	#LoadingModText,d1
	bsr.w	PutStr	
	move.l	#FileName,d1
	move.l	#MODE_OLDFILE,d2
	bsr.w	fopen
	bne.w	.skip1
	moveq	#1,d0
	bra.w	HandleError
.skip1	move.l	d0,FileHandle
	;---------------------------
	bsr.w	LoadXMHeader
	bne.w	HandleError
	;---------------------------
	cmp.b	#4,XM_MinorVer
	blo.b	.oldVer	
.v104	bsr.w	LoadData_XMv104
	bne.w	HandleError
	bra.b	.end
	;---------------------------
.oldVer	bsr.w	LoadData_XM_OldVer
	bne.w	HandleError
	;---------------------------	
.end	bsr.w	CloseFile
	;---------------------------	
	bsr.w	CalcFrqTab
	;---------------------------	
	moveq	#0,d0	; 0 = successful
	rts
	
LoadXMHeader
	move.l	FileHandle(pc),d1
	move.l	#hSig,d2
	move.l	#XM_HDR_SIZE,d3
	bsr.w	fread
	; ---------------------
	lea	hSig,a0
	lea	XMSig(pc),a1
	moveq.l	#17,d0
	bsr.w	strncmp
	beq.b 	.isXM
	moveq	#3,d0		; error: not an XM
	rts
.isXM	; ---------------------	
	lea	hName,a0
	clr.b	20(a0)		; 0x1A -> 0x00 (end-of-name terminator)
	; ---------------------
	; Byte-swapping
	; ---------------------
	swap16a	hVer
	swap32a	hHeaderSize
	swap16a	hLen
	swap16a	hRepS
	swap16a	hAntChn
	swap16a	hAntPtn
	swap16a	hAntInstrs
	swap16a	hFlags
	swap16a	hDefTempo
	swap16a	hDefSpeed
	; ---------------------
	; Version checking
	; ---------------------
	move.w	hVer,d0
	cmp.w	#$0102,d0
	beq.b	.v102
	cmp.w	#$0103,d0
	beq.b	.v103
	cmp.w	#$0104,d0
	beq.b	.v104
	moveq	#4,d0		; unsupported version
	rts	
.v102	move.b	#2,XM_MinorVer
	bra.b	.verOk
.v103	move.b	#3,XM_MinorVer
	bra.b	.verOk
.v104	move.b	#4,XM_MinorVer
.verOk	; ---------------------
	; Check song repeat position
	; ---------------------
	move.w	hLen,d0
	cmp.w	hRepS,d0
	bhs.b	.ok0
	clr.w	hRepS
.ok0	; ---------------------
	; Clamp default tempo and speed
	; ---------------------
	move.w	hDefSpeed,d0	; actually BPM (tempo)
	cmp.w	#32,d0
	bhs.b	.ok1
	moveq	#32,d0
.ok1	cmp.w	#255,d0
	bls.b	.ok2
	move.w	#255,d0
.ok2	move.w	d0,hDefSpeed		
	move.w	hDefTempo,d0	; actually ticks per row (speed)
	cmp.w	#1,d0
	bhs.b	.ok3
	moveq	#1,d0
.ok3	cmp.w	#31,d0
	bls.b	.ok4
	moveq	#31,d0
.ok4	move.w	d0,hDefTempo		
	; ---------------------
	; Validation
	; ---------------------
	moveq	#5,d0			; error code
	tst.w	hAntChn
	beq.b	.error			; zero channels, don't load
	tst.w	hAntPtn
	beq.b	.error			; zero patterns, don't load
	tst.w	hAntInstrs
	beq.b	.error			; zero instruments, don't load
	cmp.w	#256,hLen
	bhi.b	.error
	tst.w	hAntChn
	beq.b	.error
	cmp.w	#32,hAntChn
	bhi.b	.error
	cmp.w	#256,hAntPtn
	bhi.b	.error
	cmp.w	#128,hAntInstrs
	bhi.b	.error
	; ---------------------
	move.l	FileHandle(pc),d1
	move.l	hHeaderSize,d2
	add.l	#60,d2
	moveq	#SEEK_SET,d3
	bsr.w	fseek
	; ---------------------
	move.w	hAntChn,d0
	mulu.w	#5,d0
	move.w	d0,TrackWidth
	; ---------------------
	move.w	hFlags,d0
	and.b	#1,d0
	move.b	d0,LinearFrqTab
	; ---------------------
	moveq	#0,d0			; 0=successful
.error	rts				; d0 (error code) is already set

; ------------------------------------------
	
LPErr	moveq	#1,d0
	rts
LPOOM	moveq	#6,d0
	rts
LoadPatterns
	move.w	hAntPtn,d7
	beq.w	lpRTS			; this module has no patterns...
	subq.b	#1,d7
	moveq	#0,d6			; curr pattern
	; -----------------------------
	; Read pattern header
	; -----------------------------
.loop	move.l	FileHandle(pc),d1
	bsr.w	ReadLittleEndian32
	move.l	d0,d4
	moveq	#1,d2
	moveq	#SEEK_CUR,d3
	bsr.w	fseek			; skip byte
	move.l	d4,d2			; d2.l = pattern header length
	; -----------------------------
	cmp.b	#2,XM_MinorVer
	beq.b	.v102
.v103	bsr.w	ReadLittleEndian16
	moveq	#0,d4
	move.w	d0,d4			; d4.w = number of rows in pattern
	bsr.w	ReadLittleEndian16	
	moveq	#0,d3
	move.w	d0,d3			; d1.w = packed pattern length
	; -----------------------------
	cmp.l	#9,d2			; do we have non-standard stuff in header?
	bls.b	.ok			; nope
	movem.l	d2/d3,-(sp)
	sub.l	#9,d2
	moveq	#SEEK_CUR,d3
	bsr.w	fseek
	movem.l	(sp)+,d2/d3
	bra.b	.ok
.v102	bsr.w	ReadByte
	moveq	#0,d4
	move.b	d0,d4
	addq.w	#1,d4			; d4.w = number of rows in pattern
	bsr.w	ReadLittleEndian16	
	moveq	#0,d3
	move.w	d0,d3			; d3.l = packed pattern length
	; -----------------------------
	cmp.l	#8,d2			; do we have non-standard stuff in header?
	bls.b	.ok			; nope
	movem.l	d2/d3,-(sp)
	subq.l	#8,d2
	moveq	#SEEK_CUR,d3
	bsr.w	fseek
	movem.l	(sp)+,d2/d3	
	; -----------------------------
	; Set pattern row length
	; -----------------------------
.ok	lea	PattLens,a0
	move.w	d4,(a0,d6.w*2)
	; -----------------------------
	tst.w	d3			; dataLen == 0? (pattern empty)
	beq.b	.next			; yes, load next pattern (if any)
	; -----------------------------
	; Allocate memory for pattern
	; -----------------------------
	move.l	d4,d0
	mulu.w	TrackWidth(pc),d0	; d0.l = unpacked pattern length
	move.l	d0,d2			; d2.l = copy of unpacked pattern length
	moveq	#MEMF_FAST,d1
	bsr.w	AllocMem
	tst.l	d0
	beq.w	LPOOM
	move.l	d0,a1
	lea	Patt,a0
	move.l	d0,(a0,d6.w*4)	
	; ----------------------------- ; (a1=pattAddr, d1.l=unpackLen, d3.l=packLen, d4.l=numRows)
	move.l	d2,d5
	sub.l	d3,d5
	move.l	a1,a2
	add.l	d5,a2			; a2=pattAddr+(unpackLen-packLen)	
	; -----------------------------
	; Read and unpack pattern data
	; -----------------------------
	move.l	a2,d2
	move.l	FileHandle(pc),d1
	bsr.w	fread
	bsr.w	UnpackPatt
	; -----------------------------
.next	addq.l	#1,d6	; curr pattern
	dbra	d7,.loop
lpRTS	moveq	#0,d0	; 0=successful
	rts

UnpackPatt ; (a1=pattAddr, a2=pattAddr+(unpackLen-packLen), d4.l=numRows)
	movem.l	d4/d6/d7/a1,-(sp)	
	move.w	hAntChn,d5
	subq.b	#1,d5
	mulu.w	TrackWidth(pc),d4	; d4.l = unpacked length
	move.w	d4,d6
	subq.w	#1,d6
	; ----------------------------
	moveq	#0,d3
.loop2	move.w	d5,d7
	; ---------------------------- (a1 = dst, a1 = src)
.loop1	cmp.l	d4,d3
	bhs.b	.done
	move.b	(a2)+,d0
	; ----------------------------
	btst	#7,d0
	bne.b	.packed
	move.b	d0,(a1)+
	move.l	(a2)+,(a1)+		; warning: can be misaligned
	bra.b	.next
	; ----------------------------
.packed	moveq	#0,d1
	btst	#0,d0
	beq.b	.L1
	move.b	(a2)+,d1
.L1	move.b	d1,(a1)+
	moveq	#0,d1
	btst	#1,d0
	beq.b	.L2
	move.b	(a2)+,d1
.L2	move.b	d1,(a1)+
	moveq	#0,d1
	btst	#2,d0
	beq.b	.L3
	move.b	(a2)+,d1
.L3	move.b	d1,(a1)+
	moveq	#0,d1
	btst	#3,d0
	beq.b	.L4
	move.b	(a2)+,d1
.L4	move.b	d1,(a1)+
	moveq	#0,d1
	btst	#4,d0
	beq.b	.L5
	move.b	(a2)+,d1
.L5	move.b	d1,(a1)+
.next	; ----------------------------
	; Sanitize data (FT2 doesn't do this)
	; ----------------------------
	cmp.b	#97,-5(a1)		; note <= 97?
	bhi.b	.HiN			; nope, clear note
.L6	cmp.b	#128,-4(a1)		; instrument <= 128?
	bhi.b	.HiI			; nope, clear instrument
.L7	cmp.b	#35,-2(a1)		; effect type <= 35?
	bhi.b	.HiE			; nope, clear efx+param
.L8	addq.l	#5,d3
	dbra	d7,.loop1
	; ----------------------------
	dbra	d6,.loop2
.done	movem.l	(sp)+,d4/d6/d7/a1
	rts
	; ----------------------------
.HiN	clr.b	-5(a1)	; clear note
	bra.b	.L6
.HiI	clr.b	-4(a1)	; clear instrument
	bra.b	.L7
.HiE	clr.w	-2(a1)	; clear efx+param
	bra.b	.L8
	; ----------------------------

	; d6.w = instrument number
AllocAndCopyInstrHeader
	move.l	#INS_SIZE,d0		; alloc and set instr. pointer
	moveq	#MEMF_FAST,d1
	bsr.w	AllocMem
	tst.l	d0
	beq.w	.cihErr
	move.l	d0,a1
	lea	Instr,a0
	move.l	a1,(a0,d6.w*4)	
	; -----------------------------
	; Copy instrument header
	; -----------------------------
	lea	InsHdr,a0		; a0 = src, a1 = dst	
	move.l	a0,-(sp)
	move.l	a1,-(sp)
	lea	ihTA(a0),a0
	move.w	#(208/4)-1,d7
.loop1	move.l	(a0)+,(a1)+
	dbra	d7,.loop1
	move.l	(sp)+,a1
	move.l	(sp)+,a0
	move.w	ihAntSamp(a0),iAntSamp(a1)	; copy leftovers
	move.b	ihMute(a0),iMute(a1)
	; -----------------------------
	; Pre-calculate vibrato sweep delta (prevents DIV in replayer)
	; -----------------------------
	clr.w	iSweepDelta(a1)
	moveq	#0,d1
	move.b	iVibSweep(a1),d1
	beq.b	.skip
	moveq	#0,d0
	move.b	iVibDepth(a1),d0
	lsl.w	#8,d0
	divu.w	d1,d0
	move.w	d0,iSweepDelta(a1)
.skip	; ----------------------------- 
	; Pre-calculate envelope deltas (prevents DIVs in replayer)
	; -----------------------------
	lea	iEnvVP(a1),a2
	lea	iEnvPP(a1),a3
	lea	iEnvVDeltas(a1),a4
	lea	iEnvPDeltas(a1),a5
	moveq	#0,d7
.loop2	moveq	#0,d0
	move.w	4(a2,d7.w*2),d1
	sub.w	0(a2,d7.w*2),d1
	ble.b	.skipV
	move.w	6(a2,d7.w*2),d0
	sub.w	2(a2,d7.w*2),d0
	lsl.w	#8,d0
	ext.l	d0
	divs.w	d1,d0
.skipV	move.w	d0,(a4,d7.w)
	moveq	#0,d0
	move.w	4(a3,d7.w*2),d1
	sub.w	0(a3,d7.w*2),d1
	ble.b	.skipP
	move.w	6(a3,d7.w*2),d0
	sub.w	2(a3,d7.w*2),d0
	lsl.w	#8,d0
	ext.l	d0
	divs.w	d1,d0
.skipP	move.w	d0,(a5,d7.w)
	addq.b	#2,d7
	cmp.b	#24,d7
	blo.b	.loop2
	; -----------------------------
	; Copy sample headers
	; -----------------------------
	move.w	iAntSamp(a1),d7
	beq.w	.end
	subq.b	#1,d7
	lea	SmpHdrs,a0
	lea	iSamp(a1),a1		; a0 = src, a1 = dst
	; -----------------------------
.loop3	clr.l	sPek(a1)		; clear pointer (it's set later)
	move.l	shVol(a0),sVol(a1)	; Vol,Fine,Type,Pan (four bytes in one write)
	move.b	shRelTon(a0),sRelTon(a1)
	and.b	#3,sLoopType(a1)	; this variable (was Type) now contains "loop type"
	; -----------------------------
	movem.l	shLen(a0),d0-d2		; d0.l = len, d1.l = repS, d2.l = repL
	movem.l	d0-d2,sLen(a1)
	; -----------------------------		
	move.l	d0,sOrigLen(a1)		; Len (copy)
	move.l	d0,sLenInFile(a1)	; Len (copy)
	move.l	d2,sOrigRepL(a1)	; RepL (copy)
	; -----------------------------
	sf	s16Bit(a1)		; clear 16-bit flag
	btst	#4,shTyp(a0)		; do we have a 16-bit sample?
	beq.b	.no16			; nope
	st	s16Bit(a1)		; yes, set 16-bit flag
.no16	; -----------------------------
	tst.b	sLoopType(a1)		; do we have a looped sample?
	beq.b	.next			; nope
	tst.l	sRepL(a1)		; we have a loop, but is loop length > 0?
	beq.b	.disLoop		; nope, disable loop
	; -----------------------------
	add.l	d2,d1			; d1.l = loopEnd (repS+repL)
	cmp.l	sLen(a1),d1		; loopEnd <= sample length?
	bls.b	.loopOk			; yes, we're good
	clr.l	sRepL(a1)		; nope, disable loop
	clr.l	sOrigRepL(a1)
	clr.l	sRepS(a1)
	clr.b	sLoopType(a1)
	bra.b	.skip2
.loopOk	move.l	d1,sLen(a1)		; set sample length to loopEnd
	move.l	d1,sOrigLen(a1)
	bra.b	.skip2
.disLoop
	clr.l	sRepL(a1)
	clr.l	sOrigRepL(a1)
	clr.l	sRepS(a1)
	clr.b	sLoopType(a1)
.skip2	; -----------------------------
	cmp.b	#3,sLoopType(a1)	; both loop types set at once? (quirk)
	bne.b	.next			; nope, we're good
	and.b	#$fe,sLoopType(a1)	; yes, set to pingpong loop (disable forward loop)
	; -----------------------------
.next	lea	SMP_HDR_SIZE(a0),a0
	lea	SMP_SIZE(a1),a1	
	dbra	d7,.loop3
	; ---------------------
.end	moveq	#0,d0	; 0 = successful
	rts
.cihErr	moveq	#1,d0
	rts

	; d6.w = instrument number
LoadInstrHeader
	; -----------------------------
	; Clear instrument header
	; -----------------------------
	lea	InsHdr,a0
	moveq	#0,d0
	move.w	#((INS_HDR_SIZE+1)/4)-1,d7 ;+1 for multiple of 4 (yes, we have a pad byte)
.loop1	move.l	d0,(a0)+
	dbra	d7,.loop1
	; -----------------------------
	; Clear sample headers
	; -----------------------------
	lea	SmpHdrs,a0
	moveq	#0,d0
	move.w	#((SMP_HDR_SIZE*16)/4)-1,d7
.loop2	move.l	d0,(a0)+
	dbra	d7,.loop2
	; ----------------------------
	; Read instrument header
	; -----------------------------
	lea	InsHdr,a0
	move.l	FileHandle(pc),d1
	bsr.w	ReadLittleEndian32
	move.l	d0,d3
	move.l	d3,ihInstrSize(a0)
	beq.l	.set			; empty instrSize == INS_HDR_SIZE (quirky XMs)
	cmp.l	#4,d3
	blo.w	.error
	cmp.l	#INS_HDR_SIZE,d3
	bls.b	.ok
.set	move.l	#INS_HDR_SIZE,d3	
.ok	sub.l	#4,d3			; d3 = InstrSize
	move.l	FileHandle(pc),d1
	move.l	#InsHdr+ihName,d2
	bsr.w	fread
	swap16a	ihAntSamp(a0)
	swap32a	ihSampleSize(a0)
	; -----------------------------
	moveq	#0,d3
	move.w	ihAntSamp(a0),d3	; does this instrumenth have any samples?
	beq.w	.end			; no, don't do any further loading
	cmp.w	#16,d3
	bhi.w	.error			; too many samples!		
	; -----------------------------
	; Read sample headers
	; -----------------------------
	mulu.w	#SMP_HDR_SIZE,d3	; d3.l = total sample headers length
	move.l	FileHandle(pc),d1
	move.l	#SmpHdrs,d2
	bsr.w	fread
.noSmps	; -----------------------------
	; Byte-swap sample header
	; -----------------------------
	move.w	ihAntSamp(a0),d7
	subq.b	#1,d7
	lea	SmpHdrs,a1
.loop4	movem.l	(a1),d0-d2
	swap32	d0			; len
	swap32	d1			; repS
	swap32	d2			; repL
	movem.l	d0-d2,(a1)	
	lea	SMP_HDR_SIZE(a1),a1
	dbra	d7,.loop4
.skip	swap16a	ihFadeOut(a0)
	; -----------------------------
	; Byte-swap envelope points
	; -----------------------------
	moveq	#12-1,d7
	lea	ihEnvVP(a0),a1
	lea	ihEnvPP(a0),a2
.loop3	move.l	(a1),d0
	rol.w	#8,d0
	swap	d0
	move.l	(a2),d1
	rol.w	#8,d0
	swap	d0
	move.l	d0,(a1)+
	rol.w	#8,d1
	swap	d1
	rol.w	#8,d1
	swap	d1
	move.l	d1,(a2)+
	dbra	d7,.loop3
	; ----------------------------- 
	bsr.w	AllocAndCopyInstrHeader
	bne.w	.error
.end	moveq	#0,d0	; 0=successful
	rts
.error	moveq	#1,d0
	rts
	
	; This updates sRepL, sLen and sTimesToUnroll
	; a1 = sample struct
PrepareLoopUnroll
	clr.w	sTimesToUnroll(a1)
	tst.b	sLoopType(a1)
	beq.b	.end			; no loop, nothing to do here!	
	; -----------------------------
	move.l	sRepL(a1),d0
	beq.b	.end			; loopLength=0, panic!
	; -----------------------------
	move.l	#LOOP_UNROLL_SIZE,d1
	tst.b	s16Bit(a1)		; is this a 16-bit sample?
	beq.b	.ok			; nope, units are in bytes, not words
	add.l	d1,d1
.ok	cmp.l	d1,d0
	bhs.b	.end			; loop already big enough, no unroll needed!
	; -----------------------------
	divu.w	d0,d1			; repL (d0.l) is already <65536 at this point
	mulu.w	d1,d0
	move.w	d1,sTimesToUnroll(a1)
	add.l	d0,sRepL(a1)
	add.l	d0,sLen(a1)
.end	rts

	; a1 = sample struct
Load16BitSample
	move.l	sOrigLen(a1),d3		; bytes to read from file
	beq.b	.end			; length is empty, don't load sample
	bsr.w	PrepareLoopUnroll	
	move.l	sLen(a1),d0
	addq.l	#2,d0			; fix-sample for linear interpolation
	moveq	#MEMF_FAST,d1
	bsr.w	AllocMem
	tst.l	d0
	beq.b	.l16Err
	move.l	d0,sPek(a1)
	; ------------------------
	move.l	FileHandle(pc),d1
	move.l	d0,d2			; d2.l = pointer
	bsr.w	fread			; d3.l = length
	; ------------------------
	; Convert delta sample to PCM
	; ------------------------
	move.l	d2,a6
	moveq	#0,d1			; old sample
.loop	move.w	(a6),d0
	swap16	d0
	add.w	d1,d0
	move.w	d0,(a6)+
	move.w	d0,d1
	subq.l	#2,d3
	bne.b	.loop
	; ------------------------	
	move.l	sLenInFile(a1),d2	; skip data after loop end
	move.l	sOrigLen(a1),d0
	cmp.l	d0,d2
	beq.b	.noSkip
	sub.l	d0,d2
	move.l	FileHandle(pc),d1
	moveq	#SEEK_CUR,d3
	bsr.w	fseek	
.noSkip	; ---------------------- 
.end	moveq	#0,d0	; 0=successful
	rts
.l16Err	moveq	#1,d0
	rts

	; a1 = sample struct
Load8BitSample
	move.l	sOrigLen(a1),d3		; bytes to read from file
	beq.b	.end			; length is empty, don't load sample
	bsr.w	PrepareLoopUnroll	
	move.l	sLen(a1),d0
	addq.l	#2,d0			; fix-sample for linear interpolation
	moveq	#MEMF_FAST,d1
	bsr.w	AllocMem
	tst.l	d0
	beq.b	.l8Err
	move.l	d0,sPek(a1)
	; ------------------------
	move.l	FileHandle(pc),d1
	move.l	d0,d2			; d2.l = pointer
	bsr.w	fread			; d3.l = length
	; ------------------------
	; Convert delta sample to PCM
	; ------------------------
	move.l	d2,a6
	moveq	#0,d1			; old sample
.loop	move.b	(a6),d0
	add.b	d1,d0
	move.b	d0,(a6)+
	move.b	d0,d1
	subq.l	#1,d3
	bne.b	.loop	
	; ------------------------	
	move.l	sLenInFile(a1),d2	; skip data after loop end
	move.l	sOrigLen(a1),d0
	cmp.l	d0,d2
	beq.b	.noSkip
	sub.l	d0,d2
	move.l	FileHandle(pc),d1
	moveq	#SEEK_CUR,d3
	bsr.w	fseek	
.noSkip	; ---------------------- 
.end	moveq	#0,d0	; 0=successful
	rts
.l8Err	moveq	#1,d0
	rts

	; a1 = sample struct
UnrollSampleLoop8
	move.l	sPek(a1),a0
	tst.l	a0			; sample empty?
	beq.w	.end			; yes, no unroll needed
	tst.l	sLen(a1)		; sample empty?
	beq.w	.end			; yes, no unroll needed
	tst.b	sLoopType(a1)		; sample looped?
	beq.w	.end			; nope, no unroll needed
	tst.l	sRepL(a1)		; loop length == 0?
	beq.w	.end			; yes, don't do unroll
	move.w	sTimesToUnroll(a1),d6
	beq.w	.end			; no unroll needed
	subq.w	#1,d6
	; at this point, smp has looping, and repL fits in a word
	move.l	sPek(a1),a0
	move.l	sRepS(a1),d0
	add.l	d0,a0
	move.l	a0,a2
	move.l	sOrigRepL(a1),d1
	beq.w	.end			; panic!
	add.l	d1,a2
	subq.w	#1,d1
	; ----------------------
	cmp.b	#1,sLoopType(a1)
	bne.b	.bidi
	; ---- NORMAL LOOP -----
.loop1	move.w	d1,d5
	move.l	a0,a4
.loop2	move.b	(a4)+,(a2)+
	dbra	d5,.loop2
	dbra	d6,.loop1
	rts
	; --- PING-PONG LOOP ---
.bidi	st	d4			; initial direction = backwards
.loop3	move.w	d1,d5
	move.l	a0,a4
	tst.b	d4
	bne.b	.bwrd		
.fwrd	; ------ FORWARDS ------
.floop	move.b	(a4)+,(a2)+
	dbra	d5,.floop
	st	d4			; change direction to backwards
	dbra	d6,.loop3
	rts
	; ----- BACKWARDS ------
.bwrd	add.l	sOrigRepL(a1),a4
.bloop	move.b	-(a4),(a2)+
	dbra	d5,.bloop
	sf	d4			; change direction to forwards
	dbra	d6,.loop3	
	btst	#0,sTimesToUnroll(a1)	; uneven unroll value = set loop to forward
	beq.b	.end
	move.b	#1,sLoopType(a1)
	; ----------------------
.end	rts

	; a1 = sample struct
UnrollSampleLoop16
	move.l	sPek(a1),a0
	tst.l	a0			; sample empty?
	beq.w	.end			; yes, no unroll needed
	tst.l	sLen(a1)		; sample empty?
	beq.w	.end			; yes, no unroll needed
	tst.b	sLoopType(a1)		; sample looped?
	beq.w	.end			; nope, no unroll needed
	tst.l	sRepL(a1)		; loop length == 0?
	beq.w	.end			; yes, don't do unroll
	move.w	sTimesToUnroll(a1),d6
	beq.w	.end			; no unroll needed
	subq.w	#1,d6
	; at this point, smp has looping, and repL fits in a word
	move.l	sPek(a1),a0
	move.l	sRepS(a1),d0
	add.l	d0,a0
	move.l	a0,a2
	move.l	sOrigRepL(a1),d1
	beq.w	.end		; Panic!
	add.l	d1,a2
	lsr.l	#1,d1		; convert loopLength from bytes to words
	subq.l	#1,d1
	; ----------------------
	cmp.b	#1,sLoopType(a1)
	bne.b	.bidi
	; ---- NORMAL LOOP -----
.loop1	move.w	d1,d5
	move.l	a0,a4
.loop2	move.w	(a4)+,(a2)+
	dbra	d5,.loop2
	dbra	d6,.loop1
	rts
	; --- PING-PONG LOOP ---
.bidi	st	d4			; initial direction = backwards
.loop3	move.w	d1,d5
	move.l	a0,a4
	tst.b	d4
	bne.b	.bwrd		
.fwrd	; ------ FORWARDS ------
.floop	move.w	(a4)+,(a2)+
	dbra	d5,.floop
	st	d4			; change direction to backwards
	dbra	d6,.loop3
	rts
	; ----- BACKWARDS ------
.bwrd	add.l	sOrigRepL(a1),a4
.bloop	move.w	-(a4),(a2)+
	dbra	d5,.bloop
	sf	d4			; change direction to forwards
	dbra	d6,.loop3	
	btst	#0,sTimesToUnroll(a1)	; uneven unroll value = set loop to forward
	beq.b	.end
	move.b	#1,sLoopType(a1)
	; ----------------------
.end	rts

	; Puts an appropriate sample after loopEnd on looped samples,
	; so that the linear interpolation routine in the mixer will
	; always read the correct sample taps.
	;
	; a1 = sample struct
FixSample
	tst.l	sLen(a1)	; sample empty?
	beq.b	.done8		; yes, don't fix
	move.l	sPek(a1),a5
	tst.l	a5		; sample empty?
	beq.b	.done8		; yes, don't fix
	; ---------------------
	move.l	a5,a6
	add.l	sRepS(a1),a6	; a6 = &sampleData[loopStart]
	add.l	sLen(a1),a5	; a5 = &sampleData[sampleEnd] (or loopEnd)
	; ---------------------
	tst.b	s16Bit(a1)
	bne.b	.smp16		
	; ---------------------
	;      8-BIT SAMPLE
	; ---------------------
.smp8	tst.b	sLoopType(a1)	; looped sample?
	beq.b	.loff8		; no loop
	; ---------------------
	tst.l	sRepL(a1)	; loop length = 0?
	beq.b	.done8		; yes, don't fix
	cmp.b	#1,sLoopType(a1)
	beq.b	.fwd8
.bidi8	move.b	-(a5),1(a5)
	bra.b	.done8
.fwd8	move.b	(a6),(a5)
	bra.b	.done8
.loff8	clr.b	(a5)
.done8	rts

	; ---------------------
	;     16-BIT SAMPLE
	; ---------------------
.smp16	tst.b	sLoopType(a1)	; looped sample?
	beq.b	.loff16		; no loop
	; ---------------------
	tst.l	sRepL(a1)	; loop length = 0?
	beq.b	.done16		; yes, don't fix
	cmp.b	#1,sLoopType(a1)
	beq.b	.fwd16
.bidi16	move.w	-(a5),2(a5)
	bra.b	.done16
.fwd16	move.w	(a6),(a5)
	bra.b	.done16
.loff16	clr.w	(a5)
.done16	rts

	; d6.w = instrument number
LoadInstrSamples
	lea	Instr,a1
	move.l	(a1,d6.w*4),a1
	tst.l	a1			; instrument empty?
	beq.w	.done			; yes, no samples to load!
	move.w	iAntSamp(a1),d7
	beq.w	.done			; instrument has no samples!
	subq.w	#1,d7
	lea	iSamp(a1),a1		; a1 = sample struct	
	; -----------------------------
.loop	move.l	d7,-(sp)
	; -----------------------------
	tst.l	sLenInFile(a1)		; empty sample?
	beq.b	.next			; yes, don't load!
	; -----------------------------
	tst.b	s16Bit(a1)		; 16-bit sample?
	beq.b	.s8bit			; nope!
	; -----------------------------
.s16bit	bsr.w	Load16BitSample
	bne.b	.error
	bsr.w	UnrollSampleLoop16
	bra.b	.skip
	; -----------------------------
.s8bit	bsr.w	Load8BitSample
	bne.b	.error
	bsr.w	UnrollSampleLoop8
.skip	; -----------------------------
	bsr.w	FixSample
.next	lea	SMP_SIZE(a1),a1
	move.l	(sp)+,d7
	dbra	d7,.loop
.done	moveq	#0,d0	; 0=successful
	rts
.error	move	#1,d0
	rts	
; --------------------------------------------------
LIErr	moveq	#1,d0
	rts
LIOOM	moveq	#6,d0
	rts

LoadData_XM_OldVer ; v1.02 and v1.03
	; -------------------------------------
	; Load instruments
	; -------------------------------------
	move.l	#LoadInsTxt,d1
	bsr.w	PutStr
	moveq	#0,d6			; d6.w = instrument number
.loop1	move.l	d6,-(sp)
	bsr.w	LoadInstrHeader
	move.l	(sp)+,d6
	tst.b	d0			; instrument successfully loaded?
	bne.b	LIOOM			; nope, out of memory!	
	addq.w	#1,d6
	cmp.w	hAntInstrs,d6
	blo.b	.loop1
	
	; -------------------------------------
	; Load patterns
	; -------------------------------------
	move.l	#LoadPatTxt,d1
	bsr.w	PutStr
	bsr.w	LoadPatterns
	bne.w	HandleError
	
	; -------------------------------------
	; Load instrument samples
	; -------------------------------------
	move.l	#LoadSmpTxt,d1
	bsr.w	PutStr
	moveq	#0,d6			; d6.w = instrument number
.loop2	move.l	d6,-(sp)
	bsr.w	LoadInstrSamples
	move.l	(sp)+,d6
	tst.b	d0			; instrument samples loaded?
	bne.b	LIOOM			; nope, out of memory!	
	addq.w	#1,d6
	cmp.w	hAntInstrs,d6
	blo.b	.loop2
	; ------------------------------
	moveq	#0,d0	; 0=successful
	rts

LoadData_XMv104 ; v1.04
	; -------------------------------------
	; Load patterns
	; -------------------------------------
	move.l	#LoadPatTxt,d1
	bsr.w	PutStr
	bsr.w	LoadPatterns
	bne.w	HandleError
	
	; -------------------------------------
	; Load instruments & instrument samples
	; -------------------------------------
	move.l	#LoadInsSmpTxt,d1
	bsr.w	PutStr
	moveq	#0,d6			; d6.w = instrument number
.loop	move.l	d6,-(sp)
	bsr.w	LoadInstrHeader
	move.l	(sp)+,d6
	tst.b	d0			; instrument successfully loaded?
	bne.w	LIOOM			; nope!	
	; ---------------------------
	move.l	d6,-(sp)
	bsr.w	LoadInstrSamples
	move.l	(sp)+,d6
	tst.b	d0			; instrument samples loaded?
	bne.w	LIOOM			; nope!	
	; ---------------------------
	addq.w	#1,d6
	cmp.w	hAntInstrs,d6
	blo.b	.loop
	; ------------------------------
	moveq	#0,d0	; 0=successful
	rts

; ------------------------------------------------------------------------------
;                              XM REPLAYER ROUTINES
; ------------------------------------------------------------------------------

	; a5 = channel
KeyOff
	movem.l	d0/d1/a0/a1,-(sp)	
	clr.b	cEnvSustainActive(a5)
	move.l	cInstrSeg(a5),a0	
	btst	#0,iEnvPTyp(a0)
	bne.b	.NoKeyOffEnvP	
	move.w	cEnvPCnt(a5),d0
	move.w	cEnvPPos(a5),d1
	lsl.w	#2,d1
	lea	iEnvPP(a0),a1
	move.w	(a1,d1.w),d1
	cmp.w	d1,d0
	blo.b	.KeyOffEnvPOK
	move.w	d1,d0
	subq.w	#1,d0
	move.w	d0,cEnvPCnt(a5)
.KeyOffEnvPOK

.NoKeyOffEnvP
	btst	#0,iEnvVTyp(a0)
	bne.b	.KeyOffEnv
	clr.b	cRealVol(a5)
	clr.b	cOutVol(a5)
	or.b	#IS_Vol+IS_QuickVol,cStatus(a5)	
	bra.b	.end
.KeyOffEnv
	move.w	cEnvVCnt(a5),d0
	move.w	cEnvVPos(a5),d1
	lsl.w	#2,d1
	lea	iEnvVP(a0),a1
	move.w	(a1,d1.w),d1
	cmp.w	d1,d0
	blo.b	.KeyOffEnvVOK
	move.w	d1,d0
	subq.w	#1,d0
	move.w	d0,cEnvVCnt(a5)
.KeyOffEnvVOK		
.end	movem.l	(sp)+,d0/d1/a0/a1
	rts

	; a5 = StmTyp, d0 = Ton, d3 = effTyp, d4 = eff
StartTone
	cmp.b	#97,d0
	beq.w	KeyOff
	tst.b	d0
	bne.b	.Ton
	move.b	cTonNr(a5),d0	; we came from DoMultiRetrig
	beq.w	.End
.Ton	move.b	d0,cTonNr(a5)	
	moveq	#0,d1
	move.b	cInstrNr(a5),d1
	beq.b	.error
	subq.b	#1,d1
	lea	Instr,a0
	move.l	(a0,d1.w*4),a0
	tst.l	a0
	bne.b	.InstrOK
.error	lea	SpareInstr,a0	; illegal instr, use placeholder instr
.InstrOK
	move.l	a0,cInstrSeg(a5)
	move.b	iMute(a0),cMute(a5)
	move.b	d0,d1
	subq.b	#1,d1
	move.b	(a0,d1.w),d1	; a0 points to TA table (first data in instrument)
	and.b	#$f,d1		; d1.w = sample	(upper byte already cleared above)

	; *** Finetune & volume ***
	
	lea	iSmpOffset(pc),a2
	move.l	a0,a3
	add.w	(a2,d1.w*2),a3	; a3 = sample struct
	move.b	sRelTon(a3),d1
	move.b	d1,cRelTonNr(a5)
	add.b	d1,d0
	cmp.b	#10*12,d0
	bhs.w	.End
	move.b	sVol(a3),cOldVol(a5)
	move.b	sPan(a3),cOldPan(a5)
	moveq	#0,d6
	move.b	sFine(a3),d6
	move.b	d4,d5
	lsl.w	#8,d5
	move.b	d3,d5
	and.w	#$f00f,d5
	cmp.w	#$500e,d5
	bne.b	.NoSetFineTune
	move.b	d4,d6
	and.b	#$f,d6
	lsl.b	#4,d6
	sub.b	#128,d6
.NoSetFineTune
	move.b	d6,cFineTune(a5)

	; *** Period ***

	tst.b	d0
	beq.b	.NoPeriod
	subq.b	#1,d0
	ext.w	d0	; clear upper byte (d0 was 0..95)
	lsl.w	#4,d0
	asr.b	#3,d6
	add.b	#16,d6
	add.w	d6,d0	; upper byte of d6 is cleared above
	;cmp.w	#MAX_NOTES,d0 (8bitbubsy: this will never hit)
	;bhi.b	.NoPeriod
	lea	Note2Period,a0
	move.w	(a0,d0.w*2),d0
	move.w	d0,cRealPeriod(a5)
	move.w	d0,cOutPeriod(a5)	
.NoPeriod
	or.b	#IS_Period+IS_Vol+IS_Pan+IS_NyTon+IS_QuickVol,cStatus(a5)
	moveq	#0,d6
	cmp.b	#9,d3		; EffTyp == $9?
	bne.b	.NoSmpOfs
	move.b	d4,d6

	; Sample offset

	tst.b	d4		; Eff > 0?
	bne.b	.NewOfs
	move.b	cSmpOffset(a5),d6
.NewOfs	move.b	d6,cSmpOffset(a5)
	lsl.w	#8,d6
.NoSmpOfs
	move.l	d6,cSmpStartPos(a5)
	
	move.l	a3,cSampleSeg(a5)	; picked up in Mix_UpdateChannelVolPanFrq
.End	rts

	; a5 = channel
RetrigVolume
	move.b	cOldVol(a5),d0
	move.b	d0,cRealVol(a5)
	move.b	d0,cOutVol(a5)
	move.b	cOldPan(a5),cOutPan(a5)	
	or.b	#IS_Vol+IS_Pan+IS_QuickVol,cStatus(a5)
	rts

	; a5 = channel
RetrigEnvelopeVibrato
	move.l	d0,-(sp)
	move.l	a0,-(sp)	
	move.l	cInstrSeg(a5),a0	
	move.b	cWaveCtrl(a5),d0
	btst	#2,d0
	bne.b	.NoVibClr
	clr.b	cVibPos(a5)
.NoVibClr
	btst	#6,d0
	bne.b	.NoTremClr
	clr.b	cTremPos(a5)
.NoTremClr
	clr.b	cRetrigCnt(a5)
	clr.b	cTremorPos(a5)

	; *** Envelope ***

	st	cEnvSustainActive(a5)
	btst	#0,iEnvVTyp(a0)
	beq.b	.NoEnvV
	move.w	#$ffff,cEnvVCnt(a5)
	clr.w	cEnvVPos(a5)
.NoEnvV
	btst	#0,iEnvPTyp(a0)
	beq.b	.NoEnvP
	move.w	#$ffff,cEnvPCnt(a5)
	clr.w	cEnvPPos(a5)
.NoEnvP
	; *** Fadeout ***

	move.w	iFadeOut(a0),cFadeOutSpeed(a5)
	move.w	#$8000,cFadeOutAmp(a5)

	; *** Vibrato ***

	move.b	iVibDepth(a0),d0
	beq.b	.NoVibrato
	clr.b	cEVibPos(a5)
	tst.b	iVibSweep(a0)
	beq.b	.NoVibSweep	
	clr.w	cEVibAmp(a5)
	move.w	iSweepDelta(a0),cEVibSweep(a5) ; 8bb: DIV->pre-calced value on XM load
	bra.b	.NoVibrato	
.NoVibSweep
	lsl.w	#8,d0
	move.w	d0,cEVibAmp(a5)
	clr.w	cEVibSweep(a5)
.NoVibrato
	move.l	a0,(sp)+
	move.l	d0,(sp)+
	rts

	; a5 = channel
DoMultiRetrig
	move.b	cRetrigCnt(a5),d0
	addq.b	#1,d0
	cmp.b	cRetrigSpeed(a5),d0
	blo.b	.NoRetrig	
	clr.b	cRetrigCnt(a5)
	move.b	cRealVol(a5),d0
	moveq	#0,d1
	move.b	cRetrigVol(a5),d1	
	jsr	([VolChTab,pc,d1.w*4])
	move.b	d0,cRealVol(a5)
	move.b	d0,cOutVol(a5)		
	moveq	#0,d0
	move.b	cVolKolVol(a5),d1
	cmp.b	#16,d1
	blo.b	.DR_NoVol
	cmp.b	#16+$40,d1
	bhi.b	.DR_NoVol
	sub.b	#16,d1
	move.b	d1,cOutVol(a5)
	move.b	d1,cRealVol(a5)
.DR_NoVol
	cmp.b	#$c0,d1
	blo.b	.DR_NoPan
	cmp.b	#$cf,d1
	bhi.b	.DR_NoPan
	lsl.b	#4,d1
	move.b	d1,cOutPan(a5)
.DR_NoPan
	moveq	#0,d3	; 8bb: zero out Eff and EffTyp for StartTone
	moveq	#0,d4
	bra.w	StartTone	
.NoRetrig
	move.b	d0,cRetrigCnt(a5)
Vol0	rts
Vol1	subq.b	#1,d0
	bcc.b	Vol0
	moveq	#0,d0
	rts
Vol2	subq.b	#2,d0
	bcc.b	Vol0
	moveq	#0,d0
	rts
Vol3	subq.b	#4,d0
	bcc.b	Vol0
	moveq	#0,d0
	rts
Vol4	subq.b	#8,d0
	bcc.b	Vol0
	moveq	#0,d0
	rts
Vol5	sub.b	#16,d0
	bcc.b	Vol0
	moveq	#0,d0
	rts
Vol6	lsr.b	#1,d0
	move.b	d0,d1
	lsr.b	#2,d1
	add.b	d1,d0
	lsr.b	#1,d1
	add.b	d1,d0
	rts
Vol7	lsr.b	#1,d0
	rts
Vol8	moveq	#$40,d0
	rts
Vol9	addq.b	#1,d0
	cmp.b	#$40,d0
	bhi.b	Vol8
	rts
VolA	addq.b	#2,d0
	cmp.b	#$40,d0
	bhi.b	Vol8
	rts
VolB	addq.b	#4,d0
	cmp.b	#$40,d0
	bhi.b	Vol8
	rts
VolC	addq.b	#8,d0
	cmp.b	#$40,d0
	bhi.b	Vol8
	rts
VolD	add.b	#16,d0
	cmp.b	#$40,d0
	bhi.b	Vol8
	rts
VolE	move.b	d0,d1
	lsr.b	#1,d0
	add.b	d1,d0
	cmp.b	#$40,d0
	bhi.b	Vol8
	rts
VolF	add.b	d0,d0
	cmp.b	#$40,d0
	bhi.b	Vol8
	rts

	; a5 = channel, d2.w = position
SetEnvelopePos
	move.w	d2,d0
	move.w	d0,d5	; backup of position

	; *** Volume envelope ***	

	move.l	cInstrSeg(a5),a0
	lea	iEnvVP(a0),a1
	lea	iEnvVDeltas(a0),a4
	move.b	iEnvVTyp(a0),d6
	btst	#0,d6
	beq.w	.NoEnvV
	subq.w	#1,d0
	move.w	d0,cEnvVCnt(a5)
	addq.w	#1,d0
	moveq	#0,d2
	move.b	iEnvVPAnt(a0),d6
	cmp.b	#1,d6
	ble.b	.EnvVSkip
	subq.b	#1,d6
	addq.w	#4,d2
.EnvVL1	cmp.w	(a1,d2.w),d0
	blo.b	.EnvVDoIP
	addq.w	#4,d2
	subq.b	#1,d6
	bne.b	.EnvVL1
	subq.w	#4,d2	
.EnvVSkip
	clr.w	cEnvVIPValue
	moveq	#0,d0
	move.b	3(a1,d2.w),d0
	move.w	d0,cEnvVAmp(a5)
	bra.b	.EnvVEnd	
.EnvVDoIP
	subq.w	#4,d2
	sub.w	(a1,d2.w),d0
	beq.b	.EnvVEnd
	move.w	d0,d4		; copy of pos
	move.w	4(a1,d2.w),d1
	sub.w	0(a1,d2.w),d1
	ble.b	.EnvVStopAtPoint	
	; 8bb patch: use pre-calced deltas to prevent DIV
	lsr.w	#1,d2
	move.w	(a4,d2.w),d0
	move.w	d0,cEnvVIPValue(a5)
	add.w	d2,d2
	; -----------------------------------------------
	subq.w	#1,d4
	muls.w	d4,d0
	moveq	#0,d1
	move.b	3(a1,d2.w),d1
	lsl.w	#8,d1
	add.w	d1,d0
	move.w	d0,cEnvVAmp(a5)
	addq.w	#4,d2
	bra.b	.EnvVEnd
.EnvVStopAtPoint
	move.w	d5,d0	; set back copy of position
	bra.b	.EnvVSkip
.EnvVEnd
	lsr.w	#2,d2
	moveq	#0,d0
	move.b	iEnvVPAnt(a0),d0
	cmp.w	d0,d2
	blo.b	.OK
	move.w	d0,d2
	subq.w	#1,d2
	bcc.b	.OK
	moveq	#0,d2
.OK	move.w	d2,cEnvVPos(a5)

	; *** Panning envelope ***
.NoEnvV
	move.w	d5,d0	; set back copy of position
	lea	iEnvPP(a0),a1
	lea	iEnvPDeltas(a0),a4
	move.b	iEnvPTyp(a0),d6
	btst	#0,d6
	beq.w	.NoEnvP
	subq.w	#1,d0
	move.w	d0,cEnvPCnt(a5)
	addq.w	#1,d0
	moveq	#0,d2
	move.b	iEnvPPAnt(a0),d6
	cmp.b	#1,d6
	ble.b	.EnvPSkip
	subq.b	#1,d6
	addq.w	#4,d2
.EnvPL1	cmp.w	(a1,d2.w),d0
	blo.b	.EnvPDoIP
	addq.w	#4,d2
	subq.b	#1,d6
	bne.b	.EnvPL1
	subq.w	#4,d2	
.EnvPSkip
	clr.w	cEnvPIPValue
	moveq	#0,d0
	move.b	3(a1,d2.w),d0
	move.w	d0,cEnvPAmp(a5)
	bra.b	.EnvPEnd	
.EnvPDoIP
	subq.w	#4,d2
	sub.w	(a1,d2.w),d0
	beq.b	.EnvPEnd
	move.w	d0,d4		; copy of pos
	move.w	4(a1,d2.w),d1
	sub.w	0(a1,d2.w),d1
	ble.b	.EnvPStopAtPoint	
	; 8bb patch: use pre-calced deltas to prevent DIV
	lsr.w	#1,d2
	move.w	(a4,d2.w),d0
	move.w	d0,cEnvPIPValue(a5)
	add.w	d2,d2
	; -----------------------------------------------
	subq.w	#1,d4
	muls.w	d4,d0
	moveq	#0,d1
	move.b	3(a1,d2.w),d1
	lsl.w	#8,d1
	add.w	d1,d0
	move.w	d0,cEnvPAmp(a5)
	addq.w	#4,d2
	bra.b	.EnvPEnd
.EnvPStopAtPoint
	move.w	d5,d0	; set back copy of position
	bra.b	.EnvPSkip
.EnvPEnd
	lsr.w	#2,d2
	moveq	#0,d0
	move.b	iEnvPPAnt(a0),d0
	cmp.w	d0,d2
	blo.b	.P_OK
	move.w	d0,d2
	subq.w	#1,d2
	bcc.b	.P_OK
	moveq	#0,d2
.P_OK	move.w	d2,cEnvPPos(a5)
.NoEnvP	rts

PlaySong
	bsr.w	DisableAudioMixer
	; ---------------------------	
	clr.w	SongPos
	clr.w	PattPos
	move.w	#1,Timer
	move.w	#64,GlobVol
	move.w	hDefSpeed,Speed		; 32..255 from XM loader
	move.w	hDefTempo,Tempo		; 1..31 from XM loader
	clr.b	PattDelTime
	clr.b	PattDelTime2
	clr.b	PBreakFlag
	clr.b	PBreakPos
	clr.b	PosJumpFlag
	clr.b	bxxOverflow		; clear this bugfix-kludge too!
	; ---------------------------
	; Setup song pattern
	; ---------------------------
	move.w	SongPos(pc),d0
	lea	hSongTab,a0
	moveq	#0,d1
	move.b	(a0,d0.w),d1	
	lea	PattLens,a0
	move.w	(a0,d1.w*2),PattLen	
	move.w	d1,PattNr
	; ---------------------------
	; Set initial BPM (from song header)
	; ---------------------------
	move.w	hDefSpeed,d0
	bsr.w	P_SetSpeed
	clr.l	PMPLeft
	; ---------------------------
	bsr.w	EnableAudioMixer
	st	SongIsPlaying
	rts

P_SetSpeed
	and.w	#$ff,d0
	cmp.b	#32,d0
	bhs.b	.ok
	moveq	#32,d0
.ok	sub.b	#32,d0	
	lea	BPM2SmpsPerTick,a0
	move.l	(a0,d0.w*4),SpeedVal	; 16.16fp
	rts

	; a4 = pattern, a5 = StmTyp
GetNewNote
	move.b	0(a4),d0		; Ton
	move.b	1(a4),d1		; Ins
	move.b	2(a4),cVolKolVol(a5)	; VolKol
	move.b	3(a4),d3		; EffTyp
	move.b	4(a4),d4		; Eff
	move.b	d0,d6			; backup of Ton	
	move.b	d1,d7			; backup of Ins			
	move.b	cEff(a5),d5
	move.b	cEffTyp(a5),d2		; old EffTyp
	beq.b	.FrqTest2
	cmp.b	#4,d2
	beq.b	.FrqTest1
	cmp.b	#6,d2
	bne.b	.NoFrqReset
.FrqTest1
	cmp.b	#4,d3			; new EffTyp
	beq.b	.NoFrqReset
	cmp.b	#6,d3
	beq.b	.NoFrqReset
	st	d5
.FrqTest2
	tst.b	d5
	beq.b	.NoFrqReset
.FrqReset
	move.w	cRealPeriod(a5),cOutPeriod(a5)
	or.b	#IS_Period,cStatus(a5)	
.NoFrqReset	
	move.b	d3,cEffTyp(a5)
	move.b	d4,cEff(a5)
	move.b	d0,cTonTyp(a5)
	move.b	d1,cTonTyp+1(a5)

	; *** New instrument ***

	tst.b	d7	; Instrument present in pattern?
	beq.b	.NoNewInstr
	cmp.b	#128,d7
	bls.b	.NewInstrOK
	moveq	#0,d7
	bra.b	.NoNewInstr
.NewInstrOK
	move.b	d7,cInstrNr(a5)
.NoNewInstr

	; *** Handle special effects ***

	move.b	d4,d5
	lsl.w	#8,d5
	move.b	d3,d5
	and.w	#$f00f,d5		
	cmp.w	#$d00e,d5
	bne.b	.NoNoteDelay
	move	d4,d5
	and.b	#$f,d5
	beq.b	.SpecEffEnd
	rts	; End
.NoNoteDelay
	cmp.w	#$900e,d5
	bne.b	.NoNoteRetrig
	move	d4,d5
	and.b	#$f,d5
	beq.b	.ForceSetPeriod
.NoNoteRetrig
.SpecEffEnd

	; *** Handle tone portamento ***

	move.b	cVolKolVol(a5),d0
	and.b	#$f0,d0
	cmp.b	#$f0,d0
	beq.b	.V_SetTonePorta
	cmp.b	#3,d3
	beq.b	.SetTonePorta
	cmp.b	#5,d3
	beq.b	.SetTonePorta
	cmp.b	#$14,d3
	beq.b	.KeyOffCmd
.NoKeyOffCmd
	bra.b	.SetPeriod
.DonePeriod		; copy below
	tst.b	d7	; Instrument present in pattern?
	beq.w	.CheckEffects
	bsr.w	RetrigVolume
	bsr.w	RetrigEnvelopeVibrato
	bra.w	.CheckEffects

	; *** New note ***
.SetPeriod
	tst.b	d6	; Note present in pattern?
	beq.b	.DonePeriod
.ForceSetPeriod
	cmp.b	#97,d6
	bne.b	.NoKeyOff
.DoKeyOff
	bsr.w	KeyOff	
	tst.b	d7	; Instrument present in pattern?
	beq.w	.CheckEffects
	bsr.w	RetrigVolume
	bra.w	.CheckEffects

.NoKeyOff
	moveq	#0,d0
	move.b	d6,d0
	bsr.w	StartTone
	bra.b	.DonePeriod	

	; *** Key-off cmd ***
.KeyOffCmd
	tst.b	d4	; Non-zero effect parameter?
	beq.b	.DoKeyOff
	bra.b	.NoKeyOffCmd

	; *** Toneporta ***
.SetTonePorta
	cmp.b	#5,d3
	beq.b	.NoPortaSpeed
	moveq	#0,d0
	move.b	d4,d0
	beq.b	.NoPortaSpeed
	lsl.w	#2,d0
	move.w	d0,cPortaSpeed(a5)
.NoPortaSpeed
	bra.b	.FixTonePorta

.V_SetTonePorta
	moveq	#0,d0
	move.b	cVolKolVol(a5),d0
	lsl.b	#4,d0
	beq.b	.V_NoPortaSpeed
	lsl.w	#2,d0
	move.w	d0,cPortaSpeed(a5)
.V_NoPortaSpeed
	; fall-through
.FixTonePorta
	tst.b	d6	; Note present in pattern?
	beq.b	.NoPortaFrq
	cmp.b	#97,d6
	beq.b	.DoKeyOff	
	move.b	d6,cWantTon(a5)
	subq.b	#1,d6
	add.b	cRelTonNr(a5),d6
	and.w	#$ff,d6
	lsl.w	#4,d6
	moveq	#0,d1
	move.b	cFineTune(a5),d1
	asr.b	#3,d1
	add.b	#16,d1
	add.w	d1,d6
	cmp.w	#MAX_NOTES,d6
	bhs.b	.NoPortaFrq
	lea	Note2Period,a0
	move.w	(a0,d6.w*2),d0
	move.w	d0,cWantPeriod(a5)
	cmp.w	cRealPeriod(a5),d0
	beq.b	.NoPorta
	blo.b	.PortaUp
	move.b	#1,cPortaDir(a5)
	bra.b	.NoPortaFrq
.PortaUp
	move.b	#2,cPortaDir(a5)
	bra.b	.NoPortaFrq
.NoPorta
	clr.b	cPortaDir(a5)
.NoPortaFrq
	bra.w	.DonePeriod

	; **********************
	; *   Handle effects   *
	; **********************

.CheckEffects
	; handle volume column effects
	moveq	#0,d0
	move.b	cVolKolVol(a5),d0
	move.w	d0,d1
	lsr.b	#4,d1
	jsr	([VolJumpTab0,pc,d1.w*4])
	
	; handle normal effects
	; d0 is reserved for old cVolKolVol (manipulated by VolJumpTab effects)	
	moveq	#0,d1
	move.b	cEffTyp(a5),d1	
	moveq	#0,d2
	move.b	cEff(a5),d2
	move.b	d2,d3		; test if we have an effect at all (eff+effTyp > 0)
	or.b	d1,d3
	beq.b	.EffEnd		; no effect
	jmp	([JumpTab0,pc,d1.w*4])	
.EffEnd
	rts

	; E effects
EEffects0
	move.b	d2,d1
	and.b	#15,d2
	lsr.b	#4,d1
	jmp	([EJumpTab0,pc,d1.w*4])

fxRet rts

V_SetVibSpeed
	and.b	#15,d0
	lsl.b	#2,d0
	beq.b	.end
	move.b	d0,cVibSpeed(a5)
.end	rts

V_Volume
	sub.b	#$10,d0
	cmp.b	#64,d0
	bls.b	.NewVolOK
	moveq	#64,d0
.NewVolOK
	move.b	d0,cOutVol(a5)
	move.b	d0,cRealVol(a5)
	or.b	#IS_Vol+IS_QuickVol,cStatus(a5)	
	rts

V_FineSlideDown
	and.b	#15,d0
	neg.b	d0
	add.b	cRealVol(a5),d0
	bge.b	.V_FSDOK
	moveq	#0,d0
.V_FSDOK
	move.b	d0,cOutVol(a5)
	move.b	d0,cRealVol(a5)
	or.b	#IS_Vol,cStatus(a5)	
	rts

V_FineSlideUp
	and.b	#15,d0
	add.b	cRealVol(a5),d0
	cmp.b	#64,d0
	ble.b	.V_FSUOK
	moveq	#64,d0
.V_FSUOK
	move.b	d0,cOutVol(a5)
	move.b	d0,cRealVol(a5)
	or.b	#IS_Vol,cStatus(a5)	
	rts

V_SetPan
	lsl.b	#4,d0
	move.b	d0,cOutPan(a5)
	or.b	#IS_Pan,cStatus(a5)	
	rts

	; *****************************
	; *   Effect implementation   *
	; *****************************

SetPan
	move.b	d2,cOutPan(a5)
	or.b	#IS_Pan,cStatus(a5)
	rts

PosJump
	moveq	#0,d0
	move.b	d2,d0
	subq.w	#1,d0
	move.w	d0,SongPos
	
	; FT2 fix
	bmi.b	PosOverflow
	cmp.w	hLen,d0
	bhs.b	PosOverflow
	; ----------
	
GotoNextZero
	clr.b	PBreakPos
	st	PosJumpFlag
	rts
	
	; FT2 fix
PosOverflow
	st	bxxOverflow
	rts
	; ----------

SetVol
	cmp.b	#64,d2
	bls.b	.VolOK
	moveq	#64,d2
.VolOK	move.b	d2,cOutVol(a5)
	move.b	d2,cRealVol(a5)
	or.b	#IS_Vol+IS_QuickVol,cStatus(a5)
	rts

PattBreak
	move.b	d2,d0
	and.b	#240,d0
	lsr.b	#1,d0
	move.b	d2,d1
	lsr.b	#2,d1
	add.b	d0,d1
	and.b	#15,d2
	add.b	d0,d2
	cmp.b	#63,d2
	bhi.b	GotoNextZero
	move.b	d2,PBreakPos
	st	PosJumpFlag
	rts

SetGlobalVol
	cmp.b	#64,d2
	bls.b	.SGV_OK
	moveq	#64,d2
.SGV_OK	move.b	d2,GlobVol+1
	; ----------------------------
	; Force-update channel volumes
	; ----------------------------
	lea	cStatus+StmTyp,a0
	move.w	hAntChn,d0
	subq.b	#1,d0
	moveq	#IS_Vol,d1
.SGV_L1	or.b	d1,(a0)
	lea	CHN_SIZE(a0),a0
	dbra	d0,.SGV_L1
	rts

SetSpeed
	moveq	#0,d0
	move.b	d2,d0
	cmp.b	#32,d0
	blo.b	.SetTempo
	move.w	d0,Speed
	bra.w	P_SetSpeed
.SetTempo
	move.w	d0,Tempo
	move.w	d0,Timer
	rts

FinePortaUp
	and.b	#15,d2
	bne.b	.FPUp_NoGet
	move.b	cFPortaUpSpeed(a5),d2
.FPUp_NoGet
	move.b	d2,cFPortaUpSpeed(a5)
	move.w	cRealPeriod(a5),d1
	moveq	#0,d0
	move.b	d2,d0
	lsl.w	#2,d0
	sub.w	d0,d1
	cmp.w	#1,d1
	bge.b	.FinePortaUpOK
	moveq	#1,d1
.FinePortaUpOK
	move.w	d1,cRealPeriod(a5)
	move.w	d1,cOutPeriod(a5)
	or.b	#IS_Period,cStatus(a5)
	rts

FinePortaDown
	and.b	#15,d2
	bne.b	.FPDown_NoGet
	move.b	cFPortaDownSpeed(a5),d2
.FPDown_NoGet
	move.b	d2,cFPortaDownSpeed(a5)
	move.w	cRealPeriod(a5),d1
	moveq	#0,d0
	move.b	d2,d0
	lsl.w	#2,d0
	add.w	d0,d1
	cmp.w	#32000-1,d1
	ble.b	.FinePortaDownOK
	move.w	#32000-1,d1
.FinePortaDownOK
	move.w	d1,cRealPeriod(a5)
	move.w	d1,cOutPeriod(a5)
	or.b	#IS_Period,cStatus(a5)
	rts

MultiRetrig
	move.b	d2,d1
	and.b	#15,d1
	bne.b	.MR_NoGetSpeed
	move.b	cRetrigSpeed(a5),d1
.MR_NoGetSpeed
	move.b	d1,cRetrigSpeed(a5)
	lsr.b	#4,d2
	bne.b	.MR_NoGetVol
	move.b	cRetrigVol(a5),d2
.MR_NoGetVol
	move.b	d2,cRetrigVol(a5)
	tst.b	d0	; old cVolKolVol (FT2 quirk)
	bne.b	.MR_NoRetrig
	bra.w	DoMultiRetrig
.MR_NoRetrig
	rts

XFinePorta
	move.b	d2,d0
	and.b	#240,d0
	cmp.b	#16,d0
	beq.b	.XFinePortaUp
	cmp.b	#32,d0
	beq.b	.XFinePortaDown
	rts

.XFinePortaUp
	and.b	#15,d2
	bne.b	.XFPUp_NoGet
	move.b	cEPortaUpSpeed(a5),d2
.XFPUp_NoGet
	move.b	d2,cEPortaUpSpeed(a5)	
	move.w	cRealPeriod(a5),d1
	moveq	#0,d0
	move.b	d2,d0
	sub.w	d0,d1
	cmp.w	#1,d1
	bge.b	.XFinePortaUpOK
	moveq	#1,d1
.XFinePortaUpOK
	move.w	d1,cRealPeriod(a5)
	move.w	d1,cOutPeriod(a5)
	or.b	#IS_Period,cStatus(a5)
	rts

.XFinePortaDown
	and.b	#15,d2
	bne.b	.XFPDown_NoGet
	move.b	cEPortaDownSpeed(a5),d2
.XFPDown_NoGet
	move.b	d2,cEPortaDownSpeed(a5)	
	move.w	cRealPeriod(a5),d1
	moveq	#0,d0
	move.b	d2,d0
	add.w	d0,d1
	cmp.w	#32000-1,d1
	ble.b	.XFinePortaDownOK
	move.w	#32000-1,d1
.XFinePortaDownOK
	move.w	d1,cRealPeriod(a5)
	move.w	d1,cOutPeriod(a5)
	or.b	#IS_Period,cStatus(a5)
	rts

SetGlissCtrl
	and.b	#15,d2
	move.b	d2,cGlissFunk(a5)
	rts

SetVibratoCtrl
	and.b	#15,d2
	and.b	#240,cWaveCtrl(a5)
	or.b	d2,cWaveCtrl(a5)
	rts

JumpLoop
	and.b	#15,d2
	beq.b	.SetLoop
	tst.b	cLoopCnt(a5)
	beq.b	.StartLoop
	subq.b	#1,cLoopCnt(a5)
	beq.b	.LoopEnd
.JumpLoop2
	move.b	cPattPos(a5),PBreakPos
	st	PBreakFlag
.LoopEnd
	rts
.StartLoop
	move.b	d2,cLoopCnt(a5)
	bra.b	.JumpLoop2
.SetLoop
	move.w	PattPos(pc),d0
	move.b	d0,cPattPos(a5)
	rts

SetTremoloCtrl
	lsl.b	#4,d2
	and.b	#15,cWaveCtrl(a5)
	or.b	d2,cWaveCtrl(a5)
	rts

VolFineUp
	and.b	#15,d2
	bne.b	.FVUp_NoGet
	move.b	cFVolSlideUpSpeed(a5),d2
.FVUp_NoGet
	move.b	d2,cFVolSlideUpSpeed(a5)
	add.b	cRealVol(a5),d2
	cmp.b	#64,d2
	bls.b	.VolFineUpOK
	moveq	#64,d2
.VolFineUpOK
	move.b	d2,cOutVol(a5)
	move.b	d2,cRealVol(a5)
	or.b	#IS_Vol,cStatus(a5)
	rts

VolFineDown
	and.b	#15,d2
	bne.b	.FVDown_NoGet
	move.b	cFVolSlideDownSpeed(a5),d2
.FVDown_NoGet
	move.b	d2,cFVolSlideDownSpeed(a5)
	sub.b	cRealVol(a5),d2
	bcc.b	.VolFineDownOK
	moveq	#0,d2
.VolFineDownOK
	move.b	d2,cOutVol(a5)
	move.b	d2,cRealVol(a5)
	or.b	#IS_Vol,cStatus(a5)
	rts

NoteCut0
	and.b	#15,d2
	bne.b	.NoteCutEnd
	clr.b	cRealVol(a5)
	clr.b	cOutVol(a5)
	or.b	#IS_Vol+IS_QuickVol,cStatus(a5)
.NoteCutEnd
	rts

PattDelay
	tst.b	PattDelTime2(pc)
	bne.b	.PattEnd
	and.b	#15,d2
	addq.b	#1,d2
	move.b	d2,PattDelTime2
.PattEnd
	rts

	; TICK>0 EFFECTS
DoEffects
	; volume column effects
	moveq	#0,d0
	move.b	cVolKolVol(a5),d0
	move.w	d0,d1
	lsr.b	#4,d1
	jsr	([VolJumpTab,pc,d1.w*4])	
	
	; normal effects
	moveq	#0,d1
	move.b	cEffTyp(a5),d1	
	moveq	#0,d0
	move.b	cEff(a5),d0
	move.b	d0,d2		; test if we have an effect at all (eff+effTyp > 0)
	or.b	d1,d2
	beq.b	.EffEnd		; no effect
	jmp	([JumpTab,pc,d1.w*4])	
.EffEnd	
	rts

	; 8bb: This is used for portamento in semitone-mode, and
	; arpeggio in Amiga period mode.

	; d0.b = relative tone, d3.w = period, d1.w = output period
	;
	; Warning: trashes d0-d7/a0 (this is fine the way it's currently used)
RelocateTon
	and.w	#$ff,d0	; just in case
	move.l	d0,-(sp)
	lea	Note2Period,a0			
	moveq	#0,d5
	move.b	cFineTune(a5),d5
	asr.b	#3,d5
	add.b	#16,d5
	add.b	d5,d5		; d5.w = finetune
	moveq	#0,d0		; d0.w = low period
	move.w	#(8*12*16)*2,d6	; d6.w = high period (8bb: wrong range!)
	
	; *** Converts period number to note number ***
	;     Log2(8*12) iterations.
	moveq	#8-1,d7
	move.b	#$ff-31,d4
.RTL1	move.w	d0,d1		; d1 = lowPeriod
	add.w	d6,d1		; d1 += hiPeriod
	lsr.w	#1,d1		; d1 >>= 1
	and.b	d4,d1		; d1 &= 0xFFFFFFE0
	add.w	d5,d1		; d1 += finetune
	move.w	d1,d2
	sub.w	#16,d2
	cmp.w	(a0,d2.w),d3
	bhs.b	.RTL2
	sub.w	d5,d1
	and.b	d4,d1
	move.w	d1,d0
	dbra	d7,.RTL1
	bra.b	.RTL3	
.RTL2	sub.w	d5,d1
	and.b	d4,d1
	move.w	d1,d6
	dbra	d7,.RTL1	
.RTL3	move.w	d0,d1
	add.w	d5,d1
	move.l	(sp)+,d0
	lsl.w	#5,d0
	add.w	d0,d1
	cmp.w	#(8*12*16+15)*2-1,d1
	blo.b	.RTL4
	move.w	#(8*12*16+15)*2,d1
.RTL4	move.w	(a0,d1.w),d1
	rts

Arp
	tst.b	d0
	beq.b	.ArpEnd
	move.w	Timer(pc),d1
	and.w	#31,d1			; 8bb: protection for LUT
	lea	ArpTab(pc),a0
	cmp.b	#1,(a0,d1.w)
	beq.b	.Arp1
	bhi.b	.Arp2
	move.w	cRealPeriod(a5),cOutPeriod(a5)
	or.b	#IS_Period,cStatus(a5)
.ArpEnd
	rts
.Arp1	lsr.b	#4,d0
.Arp3	move.w	cRealPeriod(a5),d3
	; --------------------------
	tst.b	LinearFrqTab(pc)
	beq.b	.Amiga
.Linear	; --------------------------	; 8bb: added this (faster than RelocateTon)
	lsl.w	#6,d0
	sub.w	d0,d3
	cmp.w	#1540,d3		; 8bb: simulate RelocateTon range bug
	blt.b	.LiLo
	move.w	d3,cOutPeriod(a5)
	or.b	#IS_Period,cStatus(a5)
	rts
.LiLo	move.w	#1540,cOutPeriod(a5)
	or.b	#IS_Period,cStatus(a5)
	rts
.Amiga	; --------------------------
	bsr.w	RelocateTon
	move.w	d1,cOutPeriod(a5)
	or.b	#IS_Period,cStatus(a5)
	rts
	; --------------------------
.Arp2	and.b	#15,d0
	bra.b	.Arp3

PortaUp
	tst.b	d0
	bne.b	.PUp_NoGet
	move.b	cPortaUpSpeed(a5),d0
.PUp_NoGet
	move.b	d0,cPortaUpSpeed(a5)
	move.w	cRealPeriod(a5),d1
	lsl.w	#2,d0
	sub.w	d0,d1
	cmp.w	#1,d1
	bge.b	.PortaUpOK
	moveq	#1,d1
.PortaUpOK
	move.w	d1,cRealPeriod(a5)
	move.w	d1,cOutPeriod(a5)
	or.b	#IS_Period,cStatus(a5)	
	rts

PortaDown
	tst.b	d0
	bne.b	.PDown_NoGet
	move.b	cPortaDownSpeed(a5),d0
.PDown_NoGet
	move.b	d0,cPortaDownSpeed(a5)
	move.w	cRealPeriod(a5),d1
	lsl.w	#2,d0
	add.w	d0,d1
	cmp.w	#32000-1,d1
	ble.b	.PortaDownOK
	move.w	#32000-1,d1
.PortaDownOK
	move.w	d1,cRealPeriod(a5)
	move.w	d1,cOutPeriod(a5)
	or.b	#IS_Period,cStatus(a5)	
	rts

TonePorta
	cmp.b	#1,cPortaDir(a5)
	bhi.b	.TPortaUp
	bne.b	.TPortaEnd
	move.w	cRealPeriod(a5),d1
	add.w	cPortaSpeed(a5),d1
	cmp.w	cWantPeriod(a5),d1
	blo.b	.TPortaOK
	move.w	cWantPeriod(a5),d1
	move.b	#1,cPortaDir(a5)
	bra.b	.TPortaOK
.TPortaUp
	move.w	cRealPeriod(a5),d1
	sub.w	cPortaSpeed(a5),d1
	cmp.w	cWantPeriod(a5),d1
	bgt.b	.TPortaOK
	move.w	cWantPeriod(a5),d1
	move.b	#1,cPortaDir(a5)
.TPortaOK
	move.w	d1,cRealPeriod(a5)
	tst.b	cGlissFunk(a5)
	beq.b	.NoGliss		
	moveq	#0,d0
	move.w	d1,d3
	bsr.w	RelocateTon	
.NoGliss
	move.w	d1,cOutPeriod(a5)
	or.b	#IS_Period,cStatus(a5)
.TPortaEnd
	rts

Vibrato
	tst.b	d0
	beq.b	Vibrato2
	move.b	d0,d1
	and.b	#15,d1
	beq.b	.Vibrato1
	move.b	d1,cVibDepth(a5)
.Vibrato1
	and.b	#240,d0
	lsr.b	#2,d0
	beq.b	Vibrato2
	move.b	d0,cVibSpeed(a5)
Vibrato2 ; global label
	moveq	#0,d0
	move.b	cVibPos(a5),d0
	lsr.b	#2,d0
	and.b	#$1f,d0
	move.b	cWaveCtrl(a5),d1
	and.b	#3,d1
	beq.b	.VibSine
	cmp.b	#1,d1
	beq.b	.VibRamp
	moveq	#-1,d0	; 255
	bra.b	.VibSet
.VibSine
	lea	VibTab(pc),a0
	move.b	(a0,d0.w),d0
.VibSet	moveq	#0,d1
	move.b	cVibDepth(a5),d1
	mulu.w	d1,d0
	lsr.w	#5,d0
	move.w	cRealPeriod(a5),d1
	tst.b	cVibPos(a5)
	bmi.b	.VibNeg
	add.w	d0,d1
	bra.b	.VibOK
.VibNeg	sub.w	d0,d1
.VibOK	move.w	d1,cOutPeriod(a5)
	or.b	#IS_Period,cStatus(a5)
	move.b	cVibSpeed(a5),d0
	add.b	d0,cVibPos(a5)	
	rts
.VibRamp
	lsl.b	#3,d0
	tst.b	cVibPos(a5)
	bpl.b	.VibSet
	not.b	d0
	bra.b	.VibSet

TonePlusVol
	move.l	d0,-(sp)
	bsr.w	TonePorta
	move.l	(sp)+,d0
	bra.w	Volume

VibratoPlusVol
	move.l	d0,-(sp)
	bsr.w	Vibrato2
	move.l	(sp)+,d0
	bra.w	Volume

Tremolo
	tst.b	d0
	beq.b	.Tremolo2
	move.b	d0,d1
	and.b	#15,d1
	beq.b	.Tremolo1
	move.b	d1,cTremDepth(a5)
.Tremolo1
	and.b	#240,d0
	lsr.b	#2,d0
	beq.b	.Tremolo2
	move.b	d0,cTremSpeed(a5)
.Tremolo2
	moveq	#0,d0
	move.b	cTremPos(a5),d0
	lsr.b	#2,d0
	and.b	#$1f,d0
	move.b	cWaveCtrl(a5),d1
	lsr.b	#4,d1
	and.b	#3,d1
	beq.b	.TremSine
	cmp.b	#1,d1
	beq.b	.TremRamp
	moveq	#-1,d0	; 255
	bra.b	.TremSet
.TremSine
	lea	VibTab(pc),a0
	move.b	(a0,d0.w),d0
.TremSet
	moveq	#0,d1
	move.b	cTremDepth(a5),d1
	mulu.w	d1,d0
	lsr.w	#6,d0
	move.b	cRealVol(a5),d1
	tst.b	cTremPos(a5)
	bmi.b	.TremNeg
	add.w	d0,d1
	cmp.b	#64,d1
	bls.b	.TremOK
	moveq	#64,d1
	bra.b	.TremOK
.TremNeg
	sub.w	d0,d1
	bcc.b	.TremOK
	clr.b	d1
.TremOK
	move.b	d1,cOutVol(a5)
	or.b	#IS_Vol,cStatus(a5)
	move.b	cTremSpeed(a5),d0
	add.b	d0,cTremPos(a5)	
	rts
.TremRamp
	lsl.b	#3,d0
	tst.b	cVibPos(a5)	; FT2 bug: should've been TremPos
	bpl.b	.TremSet
	not.b	d0
	bra.b	.TremSet

Volume
	tst.b	d0
	bne.b	.V_NoGet
	move.b	cVolSlideSpeed(a5),d0
.V_NoGet
	move.b	d0,cVolSlideSpeed(a5)
	move.b	d0,d1
	lsr.b	#4,d1
	beq.b	.VolDown
	add.b	cRealVol(a5),d1
	cmp.b	#64,d1
	bls.b	.VolEnd
	moveq	#64,d1
	bra.b	.VolEnd
.VolDown
	move.b	cRealVol(a5),d1
	sub.b	d0,d1
	bcc.b	.VolEnd
	moveq	#0,d1
.VolEnd
	move.b	d1,cOutVol(a5)
	move.b	d1,cRealVol(a5)
	or.b	#IS_Vol,cStatus(a5)
	rts

KeyOffCmd2
	move.w	Tempo(pc),d1
	sub.w	Timer(pc),d1
	and.b	#31,d0
	cmp.b	d1,d0
	bne.b	.NoKeyOffCmd
	bra.w	KeyOff
.NoKeyOffCmd
	rts

GlobalVolSlide
	tst.b	d0
	bne.b	.GVS_NoGet
	move.b	cGlobVolSlideSpeed(a5),d0
.GVS_NoGet
	move.b	d0,cGlobVolSlideSpeed(a5)
	move.b	d0,d1
	lsr.b	#4,d1
	beq.b	.GVolDown
	add.b	GlobVol+1(pc),d1
	cmp.b	#64,d1
	bls.b	.GVolEnd
	moveq	#64,d1
	bra.b	.GVolEnd
.GVolDown
	move.b	GlobVol+1(pc),d1
	sub.b	d0,d1
	bcc.b	.GVolEnd
	moveq	#0,d1
.GVolEnd
	move.b	d1,GlobVol+1
	; ----------------------------
	; Force-update channel volumes
	; ----------------------------
	lea	cStatus+StmTyp,a0
	move.w	hAntChn,d0
	subq.b	#1,d0
	moveq	#IS_Vol,d1
.GVS_L1	or.b	d1,(a0)
	lea	CHN_SIZE(a0),a0
	dbra	d0,.GVS_L1
	rts

PanningSlide
	tst.b	d0
	bne.b	.PS_NoGet
	move.b	cPanningSlideSpeed(a5),d0
.PS_NoGet
	move.b	d0,cPanningSlideSpeed(a5)

	move.b	d0,d1
	lsr.b	#4,d1
	beq.b	.PanDown
	add.b	cOutPan(a5),d1
	bcc.b	.PanEnd
	moveq	#-1,d1	; 255
	bra.b	.PanEnd
.PanDown
	move.b	cOutPan(a5),d1
	sub.b	d0,d1
	bcc.b	.PanEnd
	moveq	#0,d1
.PanEnd
	move.b	d1,cOutPan(a5)
	or.b	#IS_Pan,cStatus(a5)
	rts

Tremor
	tst.b	d0
	bne.b	.TremorNoGet
	move.b	cTremorSave(a5),d0
.TremorNoGet
	move.b	d0,cTremorSave(a5)	
	move.b	cTremorPos(a5),d1
	move.b	d1,d2
	and.b	#$7f,d1
	and.b	#$80,d2
	subq.b	#1,d1
	bpl.b	.TremorOK
	cmp.b	#$80,d2
	beq.b	.TremorOn
	move.b	#$80,d2
	move.b	d0,d1
	lsr.b	#4,d1
	bra.b	.TremorOK
.TremorOn
	moveq	#0,d2
	move.b	d0,d1
	and.b	#15,d1
.TremorOK
	or.b	d2,d1
	move.b	d1,cTremorPos(a5)
	move.b	cRealVol(a5),d0
	cmp.b	#$80,d2
	beq.b	.TremorIsOn
	moveq	#0,d0
.TremorIsOn
	move.b	d0,cOutVol(a5)
	or.b	#IS_Vol+IS_QuickVol,cStatus(a5)
	rts

V_SlideDown
	and.b	#15,d0
	neg.b	d0
	add.b	cRealVol(a5),d0
	bpl.b	.V_VSDOK
	moveq	#0,d0
.V_VSDOK
	move.b	d0,cOutVol(a5)
	move.b	d0,cRealVol(a5)
	or.b	#IS_Vol,cStatus(a5)
	rts

V_SlideUp
	and.b	#15,d0
	add.b	cRealVol(a5),d0
	cmp.b	#64,d0
	bls.b	.V_VSUOK
	moveq	#64,d0
.V_VSUOK
	move.b	d0,cOutVol(a5)
	move.b	d0,cRealVol(a5)
	or.b	#IS_Vol,cStatus(a5)
	rts

V_Vibrato
	and.b	#15,d0
	beq.b	.V_Vibrato1
	move.b	d0,cVibDepth(a5)
.V_Vibrato1
	bra.w	Vibrato2

V_PanSlideLeft
	and.b	#15,d0
	neg.b	d0
	add.b	cOutPan(a5),d0
	bcs.b	.V_PSLOK
	moveq	#0,d0
.V_PSLOK
	move.b	d0,cOutPan(a5)
	or.b	#IS_Pan,cStatus(a5)
	rts

V_PanSlideRight
	and.b	#15,d0
	add.b	cOutPan(a5),d0
	bcc.b	.V_PSROK
	moveq	#-1,d0	; 255
.V_PSROK
	move.b	d0,cOutPan(a5)
	or.b	#IS_Pan,cStatus(a5)
	rts

	; *** E Effects *
EEffects
	move.b	d0,d1
	and.b	#15,d0
	lsr.b	#4,d1
	cmp.b	#9,d1
	beq.w	RetrigNote
	cmp.b	#$C,d1
	beq.w	NoteCut
	cmp.b	#$D,d1
	beq.w	NoteDelay
	rts

RetrigNote
	tst.b	d0
	beq.b	.NoRetrigNote
	moveq	#0,d1
	move.w	Tempo(pc),d1
	sub.w	Timer(pc),d1
	and.w	#31,d1				; 8bb: protection for out LUT
	lsl.w	#5,d0
	add.w	d0,d1
	lea	RetrigTickTab(pc),a0
	tst.b	(a0,d1.w)
	bne.b	.NoRetrigNote
	moveq	#0,d0
	moveq	#0,d3
	moveq	#0,d4
	bsr.w	StartTone
	bra.w	RetrigEnvelopeVibrato
.NoRetrigNote
	rts

NoteCut
	move.w	Tempo(pc),d1
	sub.w	Timer(pc),d1
	cmp.w	d0,d1
	bne.b	.NoteCutEnd
	clr.b	cOutVol(a5)
	clr.b	cRealVol(a5)
	or.b	#IS_Vol+IS_QuickVol,cStatus(a5)
.NoteCutEnd
	rts

NoteDelay
	move.w	Tempo(pc),d1
	sub.w	Timer(pc),d1
	cmp.w	d0,d1
	bne.b	.NoteDelayEnd
	move.w	cTonTyp(a5),d0
	moveq	#0,d1
	move.b	d0,d1
	lsr.w	#8,d0
	moveq	#0,d3
	moveq	#0,d4
	bsr.w	StartTone
	move.w	cTonTyp(a5),d0
	lsr.w	#8,d0
	beq.b	.DR_NoVolPan
	bsr.w	RetrigVolume
.DR_NoVolPan
	bsr.w	RetrigEnvelopeVibrato
	move.b	cVolKolVol(a5),d0
	cmp.b	#16,d0
	blo.b	.DR_NoVol
	cmp.b	#16+$40,d0
	bhi.b	.DR_NoVol
	sub.b	#16,d0
	move.b	d0,cOutVol(a5)
	move.b	d0,cRealVol(a5)
.DR_NoVol
	cmp.b	#$c0,d0
	blo.b	.DR_NoPan
	cmp.b	#$cf,d0
	bhi.b	.DR_NoPan
	lsl.b	#4,d0
	move.b	d0,cOutPan(a5)
.DR_NoPan

.NoteDelayEnd
	rts
   
	; a5 = channel
FixaEnvelopeVibrato
	move.l	a4,-(sp)

	; *** Fadeout ***

	tst.b	cEnvSustainActive(a5)
	bne.b	.NoFadeOut
	or.b	#IS_Vol,cStatus(a5)
	move.w	cFadeOutSpeed(a5),d0
	sub.w	d0,cFadeOutAmp(a5)
	bcc.b	.NoFadeOut
	clr.w	cFadeOutAmp(a5)
	clr.w	cFadeOutSpeed(a5)
.NoFadeOut	

	; *** Volume envelope ***

	cmp.b	#1,cMute(a5)
	beq.w	.Muted	
	move.l	cInstrSeg(a5),a0
	lea	iEnvVP(a0),a1
	lea	iEnvVDeltas(a0),a4	
	move.b	iEnvVTyp(a0),d6
	btst	#0,d6
	beq.w	.NoEnvV
	move.w	cEnvVCnt(a5),d1
	addq.w	#1,d1
	move.w	d1,cEnvVCnt(a5)
	move.w	cEnvVPos(a5),d2
	move.w	d2,d3
	lsl.w	#2,d2		
	cmp.w	(a1,d2.w),d1
	bne.w	.EnvVNoNewPnt

	; *** New point ***

	move.b	3(a1,d2.w),d0
	lsl.w	#8,d0
	move.w	d0,cEnvVAmp(a5)
	addq.w	#1,d3

	; *** Check loops ***

	btst	#2,d6
	beq.b	.EnvVNoLoop
	subq.w	#1,d3
	cmp.b	iEnvVRepE(a0),d3
	bne.b	.EnvVNoLoopX
	btst	#1,d6
	beq.b	.EnvVLoopNoSust
	cmp.b	iEnvVSust(a0),d3
	bne.b	.EnvVLoopNoSust
	tst.b	cEnvSustainActive(a5)
	beq.b	.EnvVNoLoopX	
.EnvVLoopNoSust
	move.b	iEnvVRepS(a0),d3
	move.w	d3,d2
	lsl.w	#2,d2
	move.w	(a1,d2.w),cEnvVCnt(a5)
	move.b	3(a1,d2.w),d0
	lsl.w	#8,d0
	move.w	d0,cEnvVAmp(a5)
.EnvVNoLoopX
	addq.w	#1,d3
.EnvVNoLoop

	; *** Check if we're at the last envelope point ***

	cmp.b	iEnvVPAnt(a0),d3
	blo.b	.EnvVAntOK

	; *** We're at the last envelope point ***
.EnvVStopAtPoint
	clr.w	cEnvVIPValue(a5)
	bra.b	.EnvVNoNewPnt	
.EnvVAntOK

	; *** Check sustain ***

	btst	#1,d6
	beq.b	.EnvVNoSustain
	tst.b	cEnvSustainActive(a5)
	beq.b	.EnvVNoSustain
	subq.w	#1,d3
	cmp.b	iEnvVSust(a0),d3
	beq.b	.EnvVStopAtPoint
	addq.w	#1,d3
.EnvVNoSustain

	; *** Get new interpolation constant ***

	move.w	d3,cEnvVPos(a5)
	move.w	4(a1,d2.w),d1
	sub.w	0(a1,d2.w),d1
	ble.b	.EnvVStopAtPoint	
	; 8bb patch: use pre-calced deltas to prevent DIV
	lsr.w	#1,d2
	move.w	(a4,d2.w),cEnvVIPValue(a5)
	add.w	d2,d2
	; -----------------------------------------------
	move.w	cEnvVAmp(a5),d0
	bra.b	.EnvVNoIP

	; *** Interpolate ***	
.EnvVNoNewPnt
	move.w	cEnvVAmp(a5),d0
	add.w	cEnvVIPValue(a5),d0
	move.w	d0,cEnvVAmp(a5)
	move.w	d0,d6
	lsr.w	#8,d6
	cmp.b	#$40,d6
	bls.b	.EnvVNoIP
	cmp.b	#$40+$c0/2,d6
	bls.b	.EnvVTooHigh
	moveq	#0,d0
	clr.w	cEnvVIPValue(a5)
	bra.b	.EnvVNoIP
.EnvVTooHigh
	move.w	#$4000,d0
	clr.w	cEnvVIPValue(a5)
.EnvVNoIP
	; --------------------------------------------------------------
	; calculate vol w/ vol envelope
	; --------------------------------------------------------------
	moveq	#0,d1
	move.b	cOutVol(a5),d1		; d1 = 0..64
	mulu.w	GlobVol(pc),d1		; (d1.w * 0..64) = d1.w 0..4096
	mulu.w	d0,d1			; (d1.w * 0..16384) = d1.l 0..67108864
	add.l	#1<<9,d1		; rounding bias
	lsr.l	#8,d1
	lsr.l	#2,d1			; d1.l = 0..65536 (rounded)
	moveq	#0,d0
	move.w	cFadeOutAmp(a5),d0
	mulu.l	d0,d1			; (d1.l * 0..32768) = d1.l 0..2147483648
	add.l	#1<<19,d1		; rounding bias
	swap	d1
	lsr.w	#4,d1			; d1.w = 0..2048 (rounded)
	; ----------------------------
	mulu.w	MixingVolume(pc),d1
	add.l	#1<<5,d1		; rounding bias
	lsr.l	#6,d1
	; ----------------------------
	tst.w	d1	
	beq.b	.VolOK1	
	subq.w	#1,d1			; if (d1 > 0) d1--; (0..2047)
.VolOK1	move.w	d1,cFinalVol(a5)
	or.b	#IS_Vol,cStatus(a5)	; recalc vol every tick when vol env is on
	bra.b	.EnvVEnd
.NoEnvV	; --------------------------------------------------------------
	; calculate vol without vol envelope
	; --------------------------------------------------------------
	moveq	#0,d0
	move.b	cOutVol(a5),d0		; d0 = 0..64
	mulu.w	GlobVol(pc),d0		; (d0.w * 0..64)    = d0.w 0..4096
	mulu.w	cFadeOutAmp(a5),d0	; (d0.w * 0..32768) = d0.l 0..134217728
	add.l	#1<<15,d0		; rounding bias
	swap	d0			; d0.w = 0..2048 (rounded)
	; ----------------------------
	mulu.w	MixingVolume(pc),d0
	add.l	#1<<5,d0		; rounding bias
	lsr.l	#6,d0
	; ----------------------------
	tst.w	d0
	beq.b	.VolOK2	
	subq.w	#1,d0			; if (d0 > 0) d0--; (0..2047)
.VolOK2	move.w	d0,cFinalVol(a5)
	bra.b	.EnvVEnd
	; --------------------------------------------------------------
.Muted	clr.w	cFinalVol(a5)
.EnvVEnd

	; *** Panning envelope ***

	lea	iEnvPP(a0),a1
	lea	iEnvPDeltas(a0),a4
	move.b	iEnvPTyp(a0),d6
	btst	#0,d6
	beq.w	.NoEnvP
	move.w	cEnvPCnt(a5),d1
	addq.w	#1,d1
	move.w	d1,cEnvPCnt(a5)
	move.w	cEnvPPos(a5),d2
	move.w	d2,d3
	lsl.w	#2,d2	
	cmp.w	(a1,d2.w),d1
	bne.w	.EnvPNoNewPnt

	; *** New point ***

	move.b	3(a1,d2.w),d0
	lsl.w	#8,d0
	move.w	d0,cEnvPAmp(a5)
	addq.w	#1,d3

	; *** Check loops ***

	btst	#2,d6
	beq.b	.EnvPNoLoop
	subq.w	#1,d3
	cmp.b	iEnvPRepE(a0),d3
	bne.b	.EnvPNoLoopX
	btst	#1,d6
	beq.b	.EnvPLoopNoSust
	cmp.b	iEnvPSust(a0),d3
	bne.b	.EnvPLoopNoSust
	tst.b	cEnvSustainActive(a5)
	beq.b	.EnvPNoLoopX
.EnvPLoopNoSust
	move.b	iEnvPRepS(a0),d3
	move.w	d3,d2
	lsl.w	#2,d2
	move.w	(a1,d2.w),cEnvPCnt(a5)
	move.b	3(a1,d2.w),d0
	lsl.w	#8,d0
	move.w	d0,cEnvPAmp(a5)
.EnvPNoLoopX
	addq.w	#1,d3
.EnvPNoLoop

	; *** Check if we're at the last envelope point ***

	cmp.b	iEnvPPAnt(a0),d3
	blo.b	.EnvPAntOK

	; *** We're at the last envelope point ***
.EnvPStopAtPoint
	clr.w	cEnvPIPValue(a5)
	bra.b	.EnvPNoNewPnt	
.EnvPAntOK
	; *** Check sustain ***	
	btst	#1,d6
	beq.b	.EnvPNoSustain
	tst.b	cEnvSustainActive(a5)
	beq.b	.EnvPNoSustain
	subq.w	#1,d3
	cmp.b	iEnvPSust(a0),d3
	beq.b	.EnvPStopAtPoint
	addq.w	#1,d3
.EnvPNoSustain

	; *** Get new interpolation constant ***

	move.w	d3,cEnvPPos(a5)
	move.w	4(a1,d2.w),d1
	sub.w	0(a1,d2.w),d1
	ble.b	.EnvPStopAtPoint	
	; 8bb patch: use pre-calced deltas to prevent DIV
	lsr.w	#1,d2
	move.w	(a4,d2.w),cEnvPIPValue(a5)
	add.w	d2,d2
	; -----------------------------------------------
	move.w	cEnvPAmp(a5),d0
	bra.b	.EnvPNoIP

	; *** Interpolate ***
.EnvPNoNewPnt
	move.w	cEnvPAmp(a5),d0
	add.w	cEnvPIPValue(a5),d0
	move.w	d0,cEnvPAmp(a5)
	move.w	d0,d6
	lsr.w	#8,d6
	cmp.b	#$40,d6
	bls.b	.EnvPNoIP
	cmp.b	#$40+$c0/2,d6
	bls.b	.EnvPTooHigh
	moveq	#0,d0
	clr.w	cEnvPIPValue(a5)
	bra.b	.EnvPNoIP	
.EnvPTooHigh
	move.w	#$4000,d0
	clr.w	cEnvPIPValue(a5)	
.EnvPNoIP
	moveq	#0,d1
	move.b	cOutPan(a5),d1
	move.b	d1,d2
	sub.b	#128,d1
	bmi.b	.EnvPClcIPNeg
	neg.b	d1
.EnvPClcIPNeg
	add.b	#128,d1
	lsl.w	#3,d1
	sub.w	#32*256,d0
	muls.w	d1,d0
	swap	d0
	add.b	d0,d2	
	move.b	d2,cFinalPan(a5)	
	or.b	#IS_Pan,cStatus(a5)
	bra.b	.EnvPEnd
.NoEnvP	move.b	cOutPan(a5),cFinalPan(a5)
.EnvPEnd

	; *** Auto vibrato ***

	tst.b	iVibDepth(a0)
	beq.w	.NoVib
.DoVibrato
	move.w	cEVibSweep(a5),d1
	bne.w	.VibSweep
	move.w	cEVibAmp(a5),d1
	bra.b	.NoVibSweep	
.VibSweep
	tst.b	cEnvSustainActive(a5)
	beq.b	.NoVibSweep
	add.w	cEVibAmp(a5),d1
	move.w	d1,d0
	lsr.w	#8,d0
	cmp.b	iVibDepth(a0),d0
	bls.b	.VibSweepOK
.StopVibSweep
	move.b	iVibDepth(a0),d1
	lsl.w	#8,d1
	clr.w	cEVibSweep(a5)
.VibSweepOK
	move.w	d1,cEVibAmp(a5)
.NoVibSweep
	moveq	#0,d0
	move.b	cEVibPos(a5),d0
	add.b	iVibRate(a0),d0
	move.b	d0,cEVibPos(a5)	
	move.b	iVibTyp(a0),d2
	cmp.b	#3,d2
	beq.b	.VibRampDown
	cmp.b	#1,d2
	bhi.b	.VibRampUp
	beq.b	.VibSquare
	lea	VibSineTab(pc),a1
	move.b	(a1,d0.w),d0
	bra.b	.DoVib
.VibRampDown
	lsr.b	#1,d0
	neg.b	d0
	add.b	#64,d0
	and.b	#127,d0
	sub.b	#64,d0
	bra.b	.DoVib
.VibRampUp
	lsr.b	#1,d0
	add.b	#64,d0
	and.b	#127,d0
	sub.b	#64,d0
	bra.b	.DoVib
.VibSquare
	move.b	d0,d2
	moveq	#64,d0
	tst.b	d2
	bmi.b	.DoVib
	moveq	#-64,d0
.DoVib	ext.w	d0
	lsl.w	#2,d0
	muls.w	d1,d0
	swap	d0
	add.w	cOutPeriod(a5),d0
	cmp.w	#32000-1,d0
	bls.b	.VibOK
	moveq	#0,d0
.VibOK	move.w	d0,cFinalPeriod(a5)
	or.b	#IS_Period,cStatus(a5)
	move.l	(sp)+,a4
	rts
.NoVib	move.w	cOutPeriod(a5),cFinalPeriod(a5)
	move.l	(sp)+,a4
	rts

GetNextPos
	cmp.w	#1,Timer
	bne.w	.Exit
	addq.w	#1,PattPos
	move.b	PattDelTime(pc),d0
	beq.b	.Dskc
	move.b	d0,PattDelTime2
	clr.b	PattDelTime
.Dskc	tst.b	PattDelTime2(pc)
	beq.b	.Dska
	subq.b	#1,PattDelTime2
	beq.b	.Dska
	subq.w	#1,PattPos
.Dska	tst.b	PBreakFlag(pc)
	beq.b	.NNPysk
	clr.b	PBreakFlag
	moveq	#0,d0
	move.b	PBreakPos(pc),d0
	move.w	d0,PattPos
.NNPysk	move.w	PattPos(pc),d1
	cmp.w	PattLen(pc),d1
	blo.b	.NoNewPosYet
.NextPosition
	moveq	#0,d0
	move.b	PBreakPos(pc),d0
	move.w	d0,PattPos
	clr.b	PBreakPos
	clr.b	PosJumpFlag
	; 8bb: fix for EVIL modules that use Bxx where xx>=SongLength
	tst.b	bxxOverflow(pc)
	beq.b	.NoFix
	clr.b	bxxOverflow
	moveq	#0,d0
	bra.b	.NoNewSong
.NoFix	; ----------------------------
	move.w	SongPos(pc),d0
	addq.w	#1,d0
	cmp.w	hLen,d0
	blo.b	.NoNewSong
	move.w	hRepS,d0
.NoNewSong
	move.w	d0,SongPos
	lea	hSongTab,a0
	move.b	(a0,d0.w),d0
	move.w	d0,PattNr
	lea	PattLens,a0
	move.w	(a0,d0.w*2),PattLen
	; 8bb: fix for EVIL modules that use Dxx where xx>=nextPattLen
	move.w	PattPos(pc),d0
	move.w	PattLen(pc),d1
	cmp.w	d1,d0
	blo.b	.NoNewPosYet
	clr.w	PattPos
.NoNewPosYet
	tst.b	PosJumpFlag(pc)
	bne.b	.NextPosition
.Exit	rts

	; ticked from mixer
MainPlayer
	sf	d0
	move.w	Timer(pc),d1
	subq.w	#1,d1
	bne.b	.NoNewTimerVal
	move.w	Tempo(pc),d1
	st	d0	
.NoNewTimerVal
	move.w	d1,Timer
	tst.b	d0
	beq.w	.NoNewNote	
	tst.b	PattDelTime2(pc)
	beq.b	.GetNewNote
	bra.b	.Dskip
.GetNewNote
	move.w	PattNr(pc),d2
	and.w	#$ff,d2
	lea	Patt,a4
	move.l	(a4,d2.w*4),a4
	tst.l	a4
	beq.b	.NilPointer
	move.w	PattPos(pc),d0
	mulu.w	TrackWidth(pc),d0
	add.l	d0,a4
	bra.b	.PointerOK
.NilPointer
	lea	NilPatternLine,a4
.PointerOK	; a4 = pattern pointer
	lea	StmTyp,a5
	lea	MixVoices,a6
	move.w	hAntChn,d7
	subq.b	#1,d7
.Loop1	move.l	d7,-(sp)
	move.l	a4,-(sp)
	bsr.w	GetNewNote
	bsr.w	FixaEnvelopeVibrato
	move.l	(sp)+,a4
	move.l	(sp)+,d7
	addq	#5,a4
	lea	CHN_SIZE(a5),a5
	lea	VOICE_SIZE(a6),a6
	dbra	d7,.Loop1
.Dskip	bra.w	GetNextPos

.NoNewAllChannels
	lea	StmTyp,a5
	lea	MixVoices,a6
	move.w	hAntChn,d7
	subq.b	#1,d7
.Loop2	move.l	d7,-(sp)
	bsr.w	DoEffects
	bsr.w	FixaEnvelopeVibrato
	move.l	(sp)+,d7
	lea	CHN_SIZE(a5),a5
	lea	VOICE_SIZE(a6),a6
	dbra	d7,.Loop2
	rts

.NoNewNote
	bsr.w	.NoNewAllChannels
	bra.b	.Dskip


; ------------------------------------------------------------------------------
;                        AUDIO CHANNEL MIXER ROUTINES
; ------------------------------------------------------------------------------

	IF 0
	; (this one is currently not used)
	; a5 = channel
	; input: d0.w (voice number)
	; output: a6 (pointer to voice struct)
GetVoice
	movem.l	d0/a0/a1,-(sp)
	and.w	#31,d0
	lea	ChnReloc,a0
	lea	VoiceOffsets,a1
	move.w	(a0,d0.w*2),d0
	move.l	(a1,d0.w*4),a6
	movem.l	(sp)+,d0/a0/a1
	rts
	ENDIF
	
Mix_UpdateChannelVolPanFrq
	lea	PanningTab(pc),a1
	lea	ChnReloc,a2
	lea	VoiceOffsets,a3
	lea	LogTab,a4
	lea	StmTyp,a5
	moveq	#0,d7
	; -----------------------------
.loop	move.b	cStatus(a5),d6
	beq.w	.next				; no update flags, skip channel
	clr.b	cStatus(a5)	
	; -----------------------------
	move.w	(a2,d7.w*2),d0
	move.l	(a3,d0.w*4),a6			; a6 points to mixer voice to use

	; -------------------------------------------------------------------
	;               SAMPLE PRE-TRIGGER (setup fadeout voice)
	; -------------------------------------------------------------------	
	btst	#IB_NyTon,d6
	beq.b	.vol
	; -----------------------------
	or.b	#IST_Fadeout,vType(a6)
	moveq	#0,d0				; destination volume
	moveq	#0,d2
	move.w	QuickVolSizeVal(pc),d2		; volume ramp length
	bsr.w	.SetVol
	eor.w	#1,(a2,d7.w*2)			; swap voice with neighbor voice
	move.w	(a2,d7.w*2),d0
	move.l	(a3,d0.w*4),a6			; a6 points to mixer voice to use
	move.b	#IST_Off,vType(a6)
	
	; -------------------------------------------------------------------
	;                            VOLUME UPDATE
	; -------------------------------------------------------------------
.vol	move.b	d6,d2
	and.b	#IS_Vol+IS_Pan,d2
	beq.b	.period
	; -----------------------------
	moveq	#0,d2
	move.w	SpeedVal(pc),d2			; integer part of 16.16fp
	btst	#IB_QuickVol,d6			; use quick vol ramp instead of normal?
	beq.b	.L1				; nope, use normal ramp length
	move.w	QuickVolSizeVal(pc),d2
.L1	moveq	#0,d0
	move.w	cFinalVol(a5),d0		; destionation volume
	bsr.w	.SetVol

	; -------------------------------------------------------------------
	;                            PERIOD UPDATE
	; -------------------------------------------------------------------
.period	btst	#IB_Period,d6
	beq.b	.trig
	; -----------------------------
	move.w	cFinalPeriod(a5),d0
	bsr.w	GetFrequenceValue
	; -----------------------------
	move.l	d0,d1				; d1 = copy of freq
	move.l	d0,d2				; d2 = copy of freq
	swap	d2
	clr.w	d2				; d2.l = (freq & 0xFFFF) << 16
	clr.w	d1
	swap	d1				; d1.l = freq >> 16
	move.l	d1,d3
	not.l	d3
	move.l	d2,d4
	neg.l	d4
	movem.l	d0-d4,vFrq(a6)			; write 5 longwords from offset
	
	; -------------------------------------------------------------------
	;                           SAMPLE TRIGGER
	; -------------------------------------------------------------------
.trig	btst	#IB_NyTon,d6
	beq.b	.next
	; -----------------------------
	move.l	cSampleSeg(a5),a0
	tst.l	a0
	beq.b	.stop
	move.l	sPek(a0),d0
	beq.b	.stop
	; -----------------------------	
	movem.l	sLen(a0),d1-d3			; d0=base, d1=end, d2=repS, d3=repL
	move.l	cSmpStartPos(a5),d4
	; -----------------------------
	move.l	d0,d5
	add.l	d1,d5
	add.l	d2,d5				; d5.l = revBase (base + len + repS)		
	; -----------------------------
	sf	v16Bit(a6)
	tst.b	s16Bit(a0)			; 16-bit sample?
	beq.b	.L2				; nope
	lsr.l	#1,d1				; yes, convert units from bytes to words
	lsr.l	#1,d2
	lsr.l	#1,d3
	st	v16Bit(a6)
	; -----------------------------
.L2	movem.l	d0-d5,vBase(a6)			; write 6 longwords from offset
	cmp.l	sOrigLen(a0),d4			; d4 >= (unrolled) sample end?
	bhs.b	.stop				; yes, stop voice
	; -----------------------------
	clr.w	vPosDec+2(a6)			; clear sampling pos fraction
	move.b	sLoopType(a0),vType(a6)		; set loop flags (& clears "Off" flag)

	; -------------------------------------------------------------------
.next	lea	CHN_SIZE(a5),a5
	addq.b	#1,d7
	cmp.w	hAntChn,d7
	bne.w	.loop
	rts
	; -----------------------------
.stop	move.b	#IST_Off,vType(a6)		; stops voice
	bra.b	.next

	; d0.l = volume (0..2047)
	; d2.l = volume ramp length (number of samples)
.SetVol
	move.l	d0,d1
	; ----------------------------
	moveq	#0,d3
	move.b	cFinalPan(a5),d3	
	mulu.l	(a1,d3.w*4),d1			; 0..2047 * 0..65536 = 0..134152192 (11.16fp)
	move.l	d1,vRVol1(a6)			; set dest. volL
	not.b	d3
	addq.w	#1,d3				; d3.w = 256 - d2
	mulu.l	(a1,d3.w*4),d0			; 0..2047 * 0..65536 = 0..134152192 (11.16fp)
	move.l	d0,vLVol1(a6)			; set dest. volR
	; ----------------------------
	; Left channel vol. ramp
	; ----------------------------
	move.l	vLVol2(a6),d3
	cmp.l	d3,d0				; curr. volL == dest. volL?
	bne.b	.VL1				; nope, calculate deltas
	moveq	#0,d0
	bra.b	.VL2
.VL1	sub.l	d3,d0
	divs.l	d2,d0
.VL2	move.l	d0,vLVolIP(a6)
	; ----------------------------
	; Right channel vol. ramp
	; ----------------------------
	move.l	vRVol2(a6),d3
	cmp.l	d3,d1				; curr. volR == dest. volR?
	bne.b	.VL3				; nope, calculate deltas
	moveq	#0,d1
	bra.b	.VL4
.VL3	sub.l	d3,d1
	divs.l	d2,d1	
.VL4	move.l	d1,vRVolIP(a6)
	; ----------------------------
	or.l	d1,d0				; L/R vol deltas zero?
	bne.b	.VL5				; nope
	moveq	#0,d2
.VL5	move.w	d2,vVolIPLen(a6)
	rts

	; input:
	;  a4   = log table
	;  d0.w = period
	;
	; output: d0.l = delta (16.16fp)
GetFrequenceValue
	tst.w	d0
	beq.w	.periodIsZero
	; -----------------------------
	tst.b	LinearFrqTab(pc)
	beq.b	.amiga
	; -----------------------------
.linear	moveq	#0,d1
	move.w	#12*192*4,d1
	sub.w	d0,d1
	divu.w	#12*16*4,d1		; d1.w = (uint16_t)(12*192*4 - period) / (12*16*4)
	move.w	d1,d2			; d2.w = quotient
	swap	d1			; d1.w = remainder (0 .. 12*16*4-1)	
	moveq	#14,d3
	sub.w	d2,d3
	and.b	#31,d3			; d3.b = oct shift
	; -----------------------------
	move.l	(a4,d1.w*4),d0
	; -----------------------------
	; Add rounding bias
	; -----------------------------
	moveq	#1,d2
	lsl.l	d3,d2
	lsr.l	#1,d2
	add.l	d2,d0
	; -----------------------------	
	lsr.l	d3,d0
	rts

.amiga	moveq	#0,d1
	move.w	d0,d1
	move.l	d1,d2
	lsr.l	#1,d2			; rounding bias
	move.l	FrequenceDivFactor(pc),d0
	add.l	d2,d0			; add rounding bias
	divu.l	d1,d0
	rts

.periodIsZero
	moveq	#0,d0	; period 0 -> mixer delta 0
	rts

; ============================================================
; Audio channel mixer
;
; Before you say "that's slow!": MULs are 2 cycles on a 68060!
;
; - Thanks to ross @ EAB for the fast linear interpolation code!
;
; Features:
; - 8-bit/16-bit PCM data input
; - 32-bit mixing w/ 11-bit input L/R volume
; - Linear interpolation w/ 16-bit frac precision
; - Full FT2 volume ramping w/ 16-bit frac precision
;
; Register map:
;  a0   = <free>
;  a1   = volL ramp delta
;  a2   = volR ramp delta
;  a3   = sample data base address
;  a4   = lower 16-bit sampling delta
;  a5   = mixing buffer (LRLR..)
;  a6   = <reserved>
;  d0.l = current volR
;  d1.l = upper 16-bit sampling delta (signed)
;  d2.l	= sampling position 32-bit integer
;  d3.l = <reserved>
;  d4.l = <free>
;  d5.l = <free>
;  d6.l = current volL
;  d7.l = sampling position 16-bit frac (upper word must stay cleared)
;
; ============================================================

; ------------------
; No-ramp mixers
; ------------------

; 8-bit stereo mixing w/ linear interpolation
MIX8_S	MACRO
	movem.w	(a3,d2.l),d4
	move.b	d4,d5
	clr.b	d4
	lsl.w	#8,d5
	ext.l	d5
	sub.l	d4,d5
	mulu.l	d7,d5
	swap	d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	move.w	d5,d4		; copy of sample
	; ---------------------
	muls.w	d6,d5		; d6.w(0..2047) * d5.w(-32768..32765) -> d5.l(-67076096..67069955)
	add.l	d5,(a5)+
	; ---------------------	
	add.w	a4,d7
	addx.l	d1,d2
	; ---------------------	
	muls.w	d0,d4		; d0.w(0..2047) * d4.w(-32768..32767) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	ENDM
	
; 8-bit center mixing w/ linear interpolation
MIX8_C	MACRO
	movem.w	(a3,d2.l),d4
	move.b	d4,d5
	clr.b	d4
	lsl.w	#8,d5
	ext.l	d5
	sub.l	d4,d5
	mulu.l	d7,d5
	swap	d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	; ---------------------
	muls.w	d0,d5		; d0.w(0..2047) * d5.w(-32768..32765) -> d5.l(-67076096..67069955)
	add.l	d5,(a5)+
	add.w	a4,d7
	addx.l	d1,d2
	add.l	d5,(a5)+
	ENDM
	
; 16-bit stereo mixing w/ linear interpolation
MIX16_S	MACRO
	movem.w	(a3,d2.l*2),d4/d5
	sub.l	d4,d5
	mulu.l	d7,d5
	swap	d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	move.w	d5,d4		; copy of sample
	; ---------------------
	muls.w	d6,d5		; d6.w(0..2047) * d5.w(-32768..32765) -> d5.l(-67076096..67069955)
	add.l	d5,(a5)+
	; ---------------------	
	add.w	a4,d7
	addx.l	d1,d2
	; ---------------------	
	muls.w	d0,d4		; d0.w(0..2047)  * d4.w(-32768..32767) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	ENDM
	
; 16-bit center mixing w/ linear interpolation
MIX16_C	MACRO
	movem.w	(a3,d2.l*2),d4/d5
	sub.l	d4,d5
	mulu.l	d7,d5
	swap	d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	; ---------------------
	muls.w	d0,d5		; d0.w(0..2047) * d5.w(-32768..32765) -> d5.l(-67076096..67069955)
	add.l	d5,(a5)+
	add.w	a4,d7
	addx.l	d1,d2
	add.l	d5,(a5)+
	ENDM

; ------------------
; Volume ramp mixers
; ------------------

; 8-bit stereo mixing w/ linear interpolation & volume ramping
MIX8_RS	MACRO
	movem.w	(a3,d2.l),d4
	move.b	d4,d5
	clr.b	d4
	lsl.w	#8,d5
	ext.l	d5
	sub.l	d4,d5
	mulu.l	d7,d5
	swap	d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	; ---------------------
	move.l	d6,d4
	swap	d4		; d4.w = volL integer (0..2047)
	muls.w	d5,d4		; d5.w(-32768..32765) * d5.w(0..2047) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	add.l	a1,d6		; add volL ramp delta to curr. volL
	; ---------------------	
	move.l	d0,d4
	swap	d4		; d4.w = volR integer (0..2047)
	muls.w	d5,d4		; d5.w(-32768..32767) * d4.w(0..2047) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	add.l	a2,d0		; add volR ramp delta to curr. volR
	; ---------------------
	add.w	a4,d7
	addx.l	d1,d2
	ENDM

; 8-bit center mixing w/ linear interpolation & volume ramping
MIX8_RC	MACRO
	movem.w	(a3,d2.l),d4
	move.b	d4,d5
	clr.b	d4
	lsl.w	#8,d5
	ext.l	d5
	sub.l	d4,d5
	mulu.l	d7,d5
	swap	d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	; ---------------------
	move.l	d6,d4
	swap	d4		; d4.w = volL integer (0..2047)
	muls.w	d5,d4		; d5.w(-32768..32765) * d4.w(0..2047) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	add.l	a1,d6		; add volL ramp delta to curr. volL
	add.l	d4,(a5)+
	; ---------------------
	add.w	a4,d7
	addx.l	d1,d2
	ENDM
	
; 16-bit stereo mixing w/ linear interpolation & volume ramping
MIX16_RS	MACRO
	movem.w	(a3,d2.l*2),d4/d5
	sub.l	d4,d5
	mulu.l	d7,d5
	swap	d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	; ---------------------
	move.l	d6,d4
	swap	d4		; d4.w = volL integer (0..2047)
	muls.w	d5,d4		; d5.w(-32768..32765) * d5.w(0..2047) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	add.l	a1,d6		; add volL ramp delta to curr. volL
	; ---------------------
	move.l	d0,d4
	swap	d4		; d4.w = volR integer (0..2047)
	muls.w	d5,d4		; d5.w(-32768..32767) * d4.w(0..2047) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	add.l	a2,d0		; add volR ramp delta to curr. volR
	; ---------------------
	add.w	a4,d7
	addx.l	d1,d2
	ENDM
	
; 16-bit center mixing w/ linear interpolation & volume ramping
MIX16_RC	MACRO
	movem.w	(a3,d2.l*2),d4/d5
	sub.l	d4,d5
	mulu.l	d7,d5
	swap	d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	; ---------------------
	move.l	d6,d4
	swap	d4		; d4.w = volL integer (0..2047)
	muls.w	d5,d4		; d5.w(-32768..32765) * d4.w(0..2047) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	add.l	a1,d6		; add volL ramp delta to curr. volL
	add.l	d4,(a5)+
	; ---------------------
	add.w	a4,d7
	addx.l	d1,d2
	ENDM
		
; -----------------------------------------------------------------------------

; ------------------
; No-ramp mixers
; ------------------

mix8SLoop
       MIX8_S
mix8SF MIX8_S
mix8SE MIX8_S
mix8SD MIX8_S
mix8SC MIX8_S
mix8SB MIX8_S
mix8SA MIX8_S
mix8S9 MIX8_S
mix8S8 MIX8_S
mix8S7 MIX8_S
mix8S6 MIX8_S
mix8S5 MIX8_S
mix8S4 MIX8_S
mix8S3 MIX8_S
mix8S2 MIX8_S
mix8S1 MIX8_S
mix8S0 dbra d3,mix8SLoop
       rts

mix8CLoop
       MIX8_C
mix8CF MIX8_C
mix8CE MIX8_C
mix8CD MIX8_C
mix8CC MIX8_C
mix8CB MIX8_C
mix8CA MIX8_C
mix8C9 MIX8_C
mix8C8 MIX8_C
mix8C7 MIX8_C
mix8C6 MIX8_C
mix8C5 MIX8_C
mix8C4 MIX8_C
mix8C3 MIX8_C
mix8C2 MIX8_C
mix8C1 MIX8_C
mix8C0 dbra d3,mix8CLoop
       rts
	
mix16SLoop
        MIX16_S
mix16SF MIX16_S
mix16SE MIX16_S
mix16SD MIX16_S
mix16SC MIX16_S
mix16SB MIX16_S
mix16SA MIX16_S
mix16S9 MIX16_S
mix16S8 MIX16_S
mix16S7 MIX16_S
mix16S6 MIX16_S
mix16S5 MIX16_S
mix16S4 MIX16_S
mix16S3 MIX16_S
mix16S2 MIX16_S
mix16S1 MIX16_S
mix16S0 dbra d3,mix16SLoop
        rts

mix16CLoop
        MIX16_C
mix16CF MIX16_C
mix16CE MIX16_C
mix16CD MIX16_C
mix16CC MIX16_C
mix16CB MIX16_C
mix16CA MIX16_C
mix16C9 MIX16_C
mix16C8 MIX16_C
mix16C7 MIX16_C
mix16C6 MIX16_C
mix16C5 MIX16_C
mix16C4 MIX16_C
mix16C3 MIX16_C
mix16C2 MIX16_C
mix16C1 MIX16_C
mix16C0 dbra d3,mix16CLoop
        rts

; ------------------
; Volume ramp mixers
; ------------------

mix8RSLoop
        MIX8_RS
mix8RSF MIX8_RS
mix8RSE MIX8_RS
mix8RSD MIX8_RS
mix8RSC MIX8_RS
mix8RSB MIX8_RS
mix8RSA MIX8_RS
mix8RS9 MIX8_RS
mix8RS8 MIX8_RS
mix8RS7 MIX8_RS
mix8RS6 MIX8_RS
mix8RS5 MIX8_RS
mix8RS4 MIX8_RS
mix8RS3 MIX8_RS
mix8RS2 MIX8_RS
mix8RS1 MIX8_RS
mix8RS0 dbra d3,mix8RSLoop
        rts

mix8RCLoop
        MIX8_RC
mix8RCF MIX8_RC
mix8RCE MIX8_RC
mix8RCD MIX8_RC
mix8RCC MIX8_RC
mix8RCB MIX8_RC
mix8RCA MIX8_RC
mix8RC9 MIX8_RC
mix8RC8 MIX8_RC
mix8RC7 MIX8_RC
mix8RC6 MIX8_RC
mix8RC5 MIX8_RC
mix8RC4 MIX8_RC
mix8RC3 MIX8_RC
mix8RC2 MIX8_RC
mix8RC1 MIX8_RC
mix8RC0 dbra d3,mix8RCLoop
        rts
	
mix16RSLoop
         MIX16_RS
mix16RSF MIX16_RS
mix16RSE MIX16_RS
mix16RSD MIX16_RS
mix16RSC MIX16_RS
mix16RSB MIX16_RS
mix16RSA MIX16_RS
mix16RS9 MIX16_RS
mix16RS8 MIX16_RS
mix16RS7 MIX16_RS
mix16RS6 MIX16_RS
mix16RS5 MIX16_RS
mix16RS4 MIX16_RS
mix16RS3 MIX16_RS
mix16RS2 MIX16_RS
mix16RS1 MIX16_RS
mix16RS0 dbra d3,mix16RSLoop
         rts

mix16RCLoop
         MIX16_RC
mix16RCF MIX16_RC
mix16RCE MIX16_RC
mix16RCD MIX16_RC
mix16RCC MIX16_RC
mix16RCB MIX16_RC
mix16RCA MIX16_RC
mix16RC9 MIX16_RC
mix16RC8 MIX16_RC
mix16RC7 MIX16_RC
mix16RC6 MIX16_RC
mix16RC5 MIX16_RC
mix16RC4 MIX16_RC
mix16RC3 MIX16_RC
mix16RC2 MIX16_RC
mix16RC1 MIX16_RC
mix16RC0 dbra d3,mix16RCLoop
         rts

; ============================================================
; -- Mixing handlers
;
; Input:
;  a0 = audio buffer pointer
;  d0.w = output samples to mix
;
; Trashes:
; Almost all regs!
; ============================================================

	; Oneshot (no loop) mix handler
OneshotHandler
.loop	moveq	#0,d0
	move.w	CDA_BytesLeft(pc),d0	; calculate max number of safe samples to mix
	move.l	vPos(a6),d2
	st	CDA_SmpEndFlag	
	move.l	vLen(a6),d5
	subq.l	#1,d5
	sub.l	d2,d5
	cmp.l	#$ffff,d5		; d5.l > 65535?
	bls.b	.ok			; nope
	moveq	#-1,d5			; d5.w = $ffff
	sf	CDA_SmpEndFlag
.ok	swap	d5
	move.w	vPosDec+2(a6),d5
	not.w	d5			; change rounding
	move.l	vFrq(a6),d1		; always > 0 at this point	
	divu.l	d1,d5			; !! this is slow and benefits from unrolled sample loops !!
	addq.l	#1,d5			; d5 = max samples to safely mix
	cmp.l	d0,d5
	bls.b	.L1
	move.w	d0,d5
	sf	CDA_SmpEndFlag
.L1	; ----------------------------
	moveq	#16*4,d7		; use volume ramping
	move.w	vVolIPLen(a6),d6
	beq.w	.L3
	move.l	vLVolIP(a6),a1		; volL ramp delta
	move.l	vRVolIP(a6),a2		; volR ramp delta
	cmp.w	d6,d5
	ble.b	.L2
	move.w	d6,d5
	sf	CDA_SmpEndFlag
.L2	sub.w	d5,vVolIPLen(a6)
	bra.b	.L4
.L3	moveq	#0,d7			; don't use volume ramping
	; ----------------------------
	; Volume ramp is done
	; ----------------------------
	btst	#IBT_Fadeout,vType(a6)	; is this a volume ramp fadeout voice?
	beq.b	.L4			; nope
	move.b	#IST_Off,vType(a6)	; stop voice
	rts				; stop mixing
	; ----------------------------
.L4	move.l	d5,-(sp)
	; ----------------------------
	move.w	d5,d3
	lsr.w	#4,d3			; d3.w = samples to mix (for mix loop)	
	and.w	#16-1,d5
	add.b	vMixTabOffset(a6),d5
	add.b	d7,d5			; add "use volramp" offset
	move.l	vBase(a6),a3
	tst.w	d7	
	bne.w	.HasVolRamp
	move.w	vLVol1(a6),d6		; this tick's L volume (upper word)
	move.w	vRVol1(a6),d0		; this tick's R volume (upper word)
	bra.b	.L5
.HasVolRamp
	move.l	vLVol2(a6),d6		; previous tick's L volume
	move.l	vRVol2(a6),d0		; previous tick's R volume
.L5	move.l	vPosDec(a6),d7		; d7.l = frac (0..65535)
	move.l	vFrqH32(a6),d1
	move.w	vFrqL32(a6),a4
	jsr	([MixFuncTab,pc,d5.w*4])
	; ----------------------------
	; Set back volumes
	; ----------------------------
	tst.w	vVolIPLen(a6)
	beq.w	.L7
	move.l	d6,vLVol2(a6)		; set back curr. volL
	tst.b	vCenterMixFlag(a6)	; did we do center mix?
	beq.b	.L6			; nope
	move.l	d6,d0			; curr. volR = curr. volL
.L6	move.l	d0,vRVol2(a6)		; set back curr. volR
	; ----------------------------
.L7	tst.b	CDA_SmpEndFlag(pc)	; end of sample reached?
	beq.b	.setPos			; nope
	; ----------------------------
	move.b	#IST_Off,vType(a6)	; stop voice
	addq.l	#4,sp			; don't do any more mixing for this voice
	rts
	; ----------------------------
.setPos	move.l	d2,vPos(a6)
	move.l	d7,vPosDec(a6)
	; ----------------------------
.done	move.l	(sp)+,d5
	sub.w	d5,CDA_BytesLeft
	bgt.w	.loop
	rts

	; "Forward loop" mix handler
FwdLoopHandler
.loop	moveq	#0,d0
	move.w	CDA_BytesLeft(pc),d0	; calculate max number of safe samples to mix
	move.l	vPos(a6),d2
	st	CDA_SmpEndFlag
	move.l	vLen(a6),d5
	subq.l	#1,d5
	sub.l	d2,d5
	cmp.l	#$ffff,d5		; d5.l > 65535?
	bls.b	.ok			; nope
	moveq	#-1,d5			; d5.w = $ffff
	sf	CDA_SmpEndFlag
.ok	swap	d5
	move.w	vPosDec+2(a6),d5
	not.w	d5			; change rounding
	move.l	vFrq(a6),d1		; always > 0 at this point	
	divu.l	d1,d5			; !! this is slow and benefits from unrolled sample loops !!
	addq.l	#1,d5			; d5 = max samples to safely mix
	cmp.l	d0,d5
	bls.b	.L1
	move.w	d0,d5
	sf	CDA_SmpEndFlag
.L1	; ----------------------------
	moveq	#16*4,d7		; use volume ramping
	move.w	vVolIPLen(a6),d6
	beq.w	.L3
	move.l	vLVolIP(a6),a1		; volL ramp delta
	move.l	vRVolIP(a6),a2		; volR ramp delta
	cmp.w	d6,d5
	ble.b	.L2
	move.w	d6,d5
	sf	CDA_SmpEndFlag
.L2	sub.w	d5,vVolIPLen(a6)
	bra.b	.L4
.L3	moveq	#0,d7			; don't use volume ramping
	; ----------------------------
	; Volume ramp is done
	; ----------------------------
	btst	#IBT_Fadeout,vType(a6)	; is this a volume ramp fadeout voice?
	beq.b	.L4			; nope
	move.b	#IST_Off,vType(a6)	; stop voice
	rts				; stop mixing
	; ----------------------------
.L4	move.l	d5,-(sp)
	; ----------------------------
	move.w	d5,d3
	lsr.w	#4,d3			; d3.w = samples to mix (for mix loop)	
	and.w	#16-1,d5
	add.b	vMixTabOffset(a6),d5
	add.b	d7,d5			; add "use volramp" offset
	move.l	vBase(a6),a3
	tst.w	d7	
	bne.w	.HasVolRamp
	move.w	vLVol1(a6),d6		; this tick's L volume (upper word)
	move.w	vRVol1(a6),d0		; this tick's R volume (upper word)
	bra.b	.L5
.HasVolRamp
	move.l	vLVol2(a6),d6		; previous tick's L volume
	move.l	vRVol2(a6),d0		; previous tick's R volume
.L5	move.l	vPosDec(a6),d7		; d7.l = frac (0..65535)
	move.l	vFrqH32(a6),d1
	move.w	vFrqL32(a6),a4
	jsr	([MixFuncTab,pc,d5.w*4])
	; ----------------------------
	; Set back volumes
	; ----------------------------
	tst.w	vVolIPLen(a6)
	beq.w	.L7
	move.l	d6,vLVol2(a6)		; set back curr. volL
	tst.b	vCenterMixFlag(a6)	; did we do center mix?
	beq.b	.L6			; nope
	move.l	d6,d0			; curr. volR = curr. volL
.L6	move.l	d0,vRVol2(a6)		; set back curr. volR
	; ----------------------------
.L7	tst.b	CDA_SmpEndFlag(pc)	; end of sample reached?
	beq.b	.setPos			; nope
	; ----------------------------
	move.l	vRepL(a6),d5
	move.l	vLen(a6),d6			
.loop2	sub.l	d5,d2
	cmp.l	d6,d2
	bhs.b	.loop2
	; ----------------------------
.setPos	move.l	d2,vPos(a6)
	move.l	d7,vPosDec(a6)
	; ----------------------------
	move.l	(sp)+,d5
	sub.w	d5,CDA_BytesLeft
	bgt.w	.loop
	rts

	; "Pingpong loop" mix handler
BidiLoopHandler
.loop	moveq	#0,d0
	move.w	CDA_BytesLeft(pc),d0	; calculate max number of safe samples to mix
	move.l	vPos(a6),d2
	st	CDA_SmpEndFlag	
	move.l	vLen(a6),d5
	subq.l	#1,d5
	sub.l	d2,d5
	cmp.l	#$ffff,d5		; d5.l > 65535?
	bls.b	.ok			; nope
	moveq	#-1,d5			; d5.w = $ffff
	sf	CDA_SmpEndFlag
.ok	swap	d5
	move.w	vPosDec+2(a6),d5
	not.w	d5			; change rounding
	move.l	vFrq(a6),d1		; always > 0 at this point	
	divu.l	d1,d5			; !! this is slow and benefits from unrolled sample loops !!
	addq.l	#1,d5			; d5 = max samples to safely mix
	cmp.l	d0,d5
	bls.b	.L1
	move.w	d0,d5
	sf	CDA_SmpEndFlag
.L1	; ----------------------------
	moveq	#16*4,d7		; use volume ramping
	move.w	vVolIPLen(a6),d6
	beq.w	.L3
	move.l	vLVolIP(a6),a1		; volL ramp delta
	move.l	vRVolIP(a6),a2		; volR ramp delta
	cmp.w	d6,d5
	ble.b	.L2
	move.w	d6,d5
	sf	CDA_SmpEndFlag
.L2	sub.w	d5,vVolIPLen(a6)
	bra.b	.L4
.L3	moveq	#0,d7			; don't volume ramping
	; ----------------------------
	; Volume ramp is done
	; ----------------------------
	btst	#IBT_Fadeout,vType(a6)	; is this a volume ramp fadeout voice?
	beq.b	.L4			; nope
	move.b	#IST_Off,vType(a6)	; stop voice
	rts				; stop mixing
	; ----------------------------
.L4	move.l	d5,-(sp)
	; ----------------------------
	move.w	d5,d3
	lsr.w	#4,d3			; d3.w = samples to mix (for mix loop)	
	and.w	#16-1,d5
	add.b	vMixTabOffset(a6),d5
	add.b	d7,d5			; add "use volramp" offset
	; ----------------------------
	tst.w	d7	
	bne.w	.HasVolRamp
	move.w	vLVol1(a6),d6		; this tick's L volume (upper word)
	move.w	vRVol1(a6),d0		; this tick's R volume (upper word)
	bra.b	.L5
.HasVolRamp
	move.l	vLVol2(a6),d6		; previous tick's L volume
	move.l	vRVol2(a6),d0		; previous tick's R volume
.L5	move.l	vPosDec(a6),d7		; d7.l = frac (0..65535)
	; ----------------------------
	btst	#IBT_RevDir,vType(a6)	; reverse (backwards) sampling?
	beq.b	.fwd			; nope, forwards
	; ----------------------------
.rev	move.l	vRevBase(a6),a3
	move.w	vFrqL32Inv(a6),a4
	not.l	d2			; invert pos
	move.l	vFrqH32Inv(a6),d1
	neg.w	d7			; negate frac	
	move.l	#.MixRevRet,-(sp)
	jmp	([MixFuncTab,pc,d5.w*4])
	; ----------------------------
.fwd	move.l	vBase(a6),a3
	move.w	vFrqL32(a6),a4
	move.l	vFrqH32(a6),d1
	move.l	#.MixFwdRet,-(sp)
	jmp	([MixFuncTab,pc,d5.w*4])
	; ----------------------------
.MixRevRet
	not.l	d2			; invert pos (back to normal)
	neg.w	d7			; negate frac (back to normal)	
.MixFwdRet
	; ----------------------------
	; Set back volumes
	; ----------------------------
	tst.w	vVolIPLen(a6)
	beq.w	.L7	
	move.l	d6,vLVol2(a6)		; set back curr. volL
	tst.b	vCenterMixFlag(a6)	; did we do center mix?
	beq.b	.L6			; nope
	move.l	d6,d0			; curr. volR = curr. volL
.L6	move.l	d0,vRVol2(a6)		; set back curr. volR
	; ----------------------------
.L7	tst.b	CDA_SmpEndFlag(pc)	; end of sample reached?
	beq.b	.setPos			; nope
	; ----------------------------
	move.l	vRepL(a6),d5
	move.l	vLen(a6),d6
	move.b	vType(a6),d1
	move.b	#IST_RevDir,d4	
.loop2	sub.l	d5,d2
	eor.b	d4,d1
	cmp.l	d6,d2
	bhs.b	.loop2
	move.b	d1,vType(a6)
	; ----------------------------
.setPos	move.l	d2,vPos(a6)
	move.l	d7,vPosDec(a6)
	; ----------------------------
	move.l	(sp)+,d5
	sub.w	d5,CDA_BytesLeft
	bgt.w	.loop
	rts

MixSilence
	move.w	SamplesToMix(pc),d0
	move.w	d0,d1
	; ----------------------------
	move.l	vFrq(a6),d2
	mulu.w	d2,d1 			; fractional samples to add
	swap	d2
	mulu.w	d2,d0			; integer samples to add
	; ----------------------------
	move.l	vPos(a6),d3
	add.l	d0,d3			; add integer samples to pos
	; ----------------------------
	moveq	#0,d0
	move.w	vPosDec+2(a6),d0
	add.l	d1,d0
	move.w	d0,vPosDec+2(a6)	; set new frac
	clr.w	d0
	swap	d0
	add.l	d0,d3			; add whole frac samples to pos
	; ----------------------------
	move.l	vLen(a6),d0
	cmp.l	d0,d3			; end of sample reached?
	bhs.b	.ended			; yep
	move.l	d3,vPos(a6)
	rts	
.ended	; ----------------------------
	move.b	vType(a6),d1
	and.b	#3,d1			; looped sample?
	bne.b	.looped			; yep
.noloop	move.b	#IST_Off,vType(a6)	; no, stop voice
	rts
	; ----------------------------
.looped	move.l	vRepL(a6),d2
	moveq	#IST_RevDir,d5
	move.b	vType(a6),d6
.loop	sub.l	d2,d3
	eor.b	d5,d6
	cmp.l	d0,d3
	bhs.b	.loop
	move.b	d6,vType(a6)
	move.l	d3,vPos(a6)
	rts

PMPMix32Proc
	tst.w	d0
	beq.w	.end				; no samples to mix (shouldn't happen)
	; ------------------------------------
	move.l	a0,MixBufferTmpPtr		; aligned to longword
	move.w	d0,SamplesToMix			; multiple of 4 (4 stereo samples)
	; ------------------------------------
	; Clear to-be-mixed portion of buffer
	; ------------------------------------
	lea	(a0,d0.w*8),a1
	movem.l	ClearRegs(pc),d0-d7
.loopc	movem.l	d0-d7,(a0)
	lea	8*4(a0),a0
	cmp.l	a1,a0
	blo.b	.loopc
	; ------------------------------------
	lea	MixVoices,a6
	move.w	hAntChn,d7			
	mulu.w	#VOICE_SIZE*2,d7		; *2 to include fadeout voices
	add.l	a6,d7
	move.l	d7,OuterMixVoiceEnd
	; ------------------------------------
.loop	btst	#IBT_Off,vType(a6)
	bne.w	.next				; voice is not active
	tst.l	vFrq(a6)
	beq.w	.next				; delta is zero (FT2 supports it, but we don't)
	tst.l	vLen(a6)
	beq.w	.next				; sample is empty (shouldn't really happen)
	; ------------------------------------
	move.l	vLVol1(a6),d0
	; ------------------------------------
	; Test if we can do fast silence-mix
	; ------------------------------------
	move.l	d0,d1
	or.l	vLVol2(a6),d1
	or.l	vRVol1(a6),d1
	or.l	vRVol2(a6),d1
	beq.b	.vol0				; curr/dest vols. zero, do fast vol0 mix
	; ------------------------------------
	sf	vMixTabOffset(a6)
	tst.b	v16Bit(a6)
	beq.b	.L1
	add.b	#32,vMixTabOffset(a6)
.L1	move.l	vLVolIP(a6),d1
	; ------------------------------------
	; Test if we can do center mixing
	; ------------------------------------
	sf	vCenterMixFlag(a6)
	cmp.l	vRVol1(a6),d0			; dest. volumes equal?
	bne.b	.start				; nope, don't do center mixing
	cmp.l	vRVolIP(a6),d1			; ramp deltas equal?
	bne.b	.start				; nope, don't do center mixing
	st	vCenterMixFlag(a6)
	add.b	#16,vMixTabOffset(a6)		; use center mix routines
	; ------------------------------------
.start	move.l	MixBufferTmpPtr(pc),a5
	move.w	SamplesToMix(pc),CDA_BytesLeft
	; ------------------------------------
	move.b	vType(a6),d0
	and.l	#3,d0
	jsr	([MixHandlerFuncTab,pc,d0.w*4])
	; ------------------------------------
.next	lea	VOICE_SIZE(a6),a6
	cmp.l	OuterMixVoiceEnd(pc),a6
	bne.w	.loop
.end	rts
	; ------------------------------------
.vol0	bsr.w	MixSilence
	bra.b	.next

	; restores volume ramp state
Mix_SaveIPVolumes
	move.w	hAntChn,d7
	add.w	d7,d7
	subq.w	#1,d7
	lea	MixVoices,a6
	moveq	#0,d0
.loop	move.l	vLVol1(a6),vLVol2(a6)	; curr. volL = dest. volL
	move.l	vRVol1(a6),vRVol2(a6)	; curr. volR = dest. volR
	move.w	d0,vVolIPLen(a6)	; clear volume ramp length
	lea	VOICE_SIZE(a6),a6
	dbra	d7,.loop	
	rts

Mix_UpdateBuffer
	move.l	MixSamples(pc),d7
	lea	CDA_MixBuffer,a0
.loop	tst.l	PMPLeft(pc)		; PMPLeft (16.16fp) <= 0?
	bgt.b	.NoTick			; nope, no tick trigger yet
	tst.b	SongIsPlaying(pc)
	beq.b	.NoPlay
	move.l	a0,-(sp)
	move.l	d7,-(sp)
	bsr.w	Mix_SaveIPVolumes
	bsr.w	MainPlayer
	bsr.w	Mix_UpdateChannelVolPanFrq
	move.l	(sp)+,d7
	move.l	(sp)+,a0
.NoPlay	move.l	SpeedVal(pc),d0
	add.l	d0,PMPLeft
.NoTick	move.w	d7,d0			; d0.w = samples to mix
	move.l	PMPLeft(pc),d6
	add.l	#65535,d6
	swap	d6			; d6.w = (PMPLeft+65535)>>16 (ceil rounding)
					; d6.w = remaining tick samples (integer)
	cmp.w	d6,d0			; samples to mix <= remaining tick samples?
	bls.b	.skip			; yep
	move.w	d6,d0			; samples to mix = remaining tick samples
.skip	movem.l	d0/d7/a0,-(sp)
	bsr.w	PMPMix32Proc
.skip2	movem.l	(sp)+,d0/d7/a0
	lea	(a0,d0.w*8),a0
	sub.w	d0,PMPLeft
	sub.w	d0,d7
	bgt.b	.loop
	; ----------------------------------
	; Copy mixed samples to Paula buffer
	; ----------------------------------
	lea	CDA_MixBuffer,a0
	move.l	MixSamples(pc),d7	; samples to copy
	move.l	MixPos(pc),d6		; Paula buffer position
	IF _14BIT
		movem.l	PaulaCh1Buf(pc),a1-a4
		bra.w	CopyMixedSamples14Bit
	ELSE
		move.l	PaulaCh1Buf(pc),a1
		move.l	PaulaCh2Buf(pc),a2
		bra.w	CopyMixedSamples8Bit
	ENDIF
	; ----------------------------------

; ============================================================
; -- Copy samples from fastmem mix buffer to chipmem Paula
;    buffers.
;
; Thanks to Ross @ EAB for optimization ideas!
;
; input (reserved registers):
;  a0   = mix buffer (interleaved left/right signed 32-bit samples)
;  d6.l = Paula buffer position (is always a multiple of 4)
;  a1   = Paula ch1 chipmem-buffer (L1 - upper 8-bits)
;  a2   = Paula ch2 chipmem-buffer (R1 - upper 8-bits)
;  a3   = Paula ch3 chipmem-buffer (R2 - lower 6-bits)
;  a4   = Paula ch4 chipmem-buffer (L2 - lower 6-bits)
;  d7.w = samples to copy (is always a multiple of 4)
; ============================================================

	IF _14BIT

CopyMixedSamples14Bit
	and.l	#$FFFF,d7
	lsr.w	#2,d7			; 4 stereo samples at once
	beq.w	.end

	move.l	d7,-(sp)		; loop counter
	
	subq	#2,a0			; safe, buffer has a 32-bit zero before it

	; LUT to convert signed 16-bit to normalized pre-clamped signed 14-bit
	move.l	PostMixTableCentered(pc),a5
.loop
	; A 68060 is heavily bottlenecked by the chipmem speed, so we should
	; write a longword per write (4x samples). This explains all the overhead,
	; but it's going to pay off in the end.

	move.l	d6,a6
	
	; read 7x signed mixed 32-bit samples, upper word in Dx.w
	movem.l	(a0)+,d0-d6
	; D0=L1, D1=R1, D2=L2, D3=R2, D4=L3, D5=R3, D6=L4, -> R4

	; turn into pre-clamped, normalized sample through LUT (16-bit -> 14-bit)
	; and shuffle bytes around (intertwining accesses to memory)

	move.w	(a5,d0.w*2),d0	; L1	; xxxx|xxxx|L1u8|L1l6
	lsl.l	#8,d0		;	; xxxx|L1u8|L1l6|0000 
	move.l	d0,d7		;	; xxxx|L1u8|L1l6|0000

	move.w	(a5,d2.w*2),d2	; L2	; xxxx|xxxx|L2u8|L2l6
	move.b	d2,d7		;	; xxxx|xxxx|L1l6|L2l6
	move.w	d2,d0			; xxxx|L1u8|L2u8|L2l6
	swap	d7		;	; L1l6|L2l6|xxxx|xxxx

	move.w	(a5,d4.w*2),d7	; L3	; xxxx|xxxx|L3u8|L3l6
	ror.w	#8,d7		;	; L1l6|L2l6|L3l6|L3u8
	move.b	d7,d0		;	; xxxx|L1u8|L2u8|L3u8
	lsl.l	#8,d0		;	; L1u8|L2u8|L3u8|0000

	move.w	(a5,d6.w*2),d6	; L4	; xxxx|xxxx|L4u8|L4l6
	move.b	d6,d7		;	; L1l6|L2l6|L3l6|L4l6 D7 -> Ll6
	lsr.l	#8,d6		;	; xxxx|xxxx|xxxx|L4u8
	move.b	d6,d0		;	; L1u8|L2u8|L3u8|L4u8 D0 -> Lu8

	; read 1x signed mixed 32-bit sample, upper word in Dx.w
	move.l	(a0)+,d4	; R4    <-
	move.l	a6,d6

	move.w	(a5,d1.w*2),d1	; R1	; xxxx|xxxx|R1u8|R1l6
	lsl.l	#8,d1		;	; xxxx|R1u8|R1l6|0000 
	move.l	d1,d2		;	; xxxx|R1u8|R1l6|0000

	move.w	(a5,d3.w*2),d3	; R2	; xxxx|xxxx|R2u8|R2l6
	move.b	d3,d2		;	; xxxx|xxxx|R1l6|R2l6

	; note: address + d6 is always longword aligned :-)
	move.l	d0,(a1,d6.w)	; write longword to Paula ch 1 (L, upper 8-bit)

	move.w	d3,d1		;	; xxxx|R1u8|R2u8|R2l6
	swap	d2		;	; R1l6|R2l6|xxxx|xxxx

	move.w	(a5,d5.w*2),d2	; R3	; xxxx|xxxx|R3u8|R3l6
	ror.w	#8,d2		;	; R1l6|R2l6|R3l6|R3u8

	move.l	d7,(a4,d6.w)	; write longword to Paula ch 4 (L, lower 6-bit)

	move.b	d2,d1		;	; xxxx|R1u8|R2u8|R3u8
	lsl.l	#8,d1		;	; R1u8|R2u8|R3u8|0000

	move.w	(a5,d4.w*2),d4	; R4	; xxxx|xxxx|R4u8|R4l6
	move.b	d4,d2		;	; R1l6|R2l6|R3l6|R4l6 D2 -> Rl6
	lsr.l	#8,d4		;	; xxxx|xxxx|xxxx|R4u8

	move.l	d2,(a3,d6.w)	; write longword to Paula ch 3 (R, lower 6-bit)

	move.b	d4,d1		;	; R1u8|R2u8|R3u8|R4u8 D1 -> Ru8

	move.l	d1,(a2,d6.w)	; write longword to Paula ch 2 (R, upper 8-bit)

	; increase ring-buffer position
	addq.w	#4,d6
	and.w	#SMP_BUFF_SIZE-1,d6

	subq.l	#1,(sp)
	bne.b	.loop

	addq.l	#4,sp
.end
	rts
	
	ELSE
	
; ============================================================
; -- Copy samples from fastmem mix buffer to chipmem Paula
;    buffers.
;
; Thanks to Ross @ EAB for optimization ideas!
;
; input (reserved registers):
;  a0   = mix buffer (interleaved left/right signed 32-bit samples)
;  d6.w = Paula buffer position (is always a multiple of 4)
;  a1   = Paula L chipmem-buffer
;  a2   = Paula R chipmem-buffer
;  d7.w = samples to copy (is always a multiple of 4)
; ============================================================

CopyMixedSamples8Bit
	and.l	#$FFFF,d7
	lsr.w	#2,d7			; 4 stereo samples at once
	beq.w	.end

	move.l	d7,-(sp)		; loop counter

	subq	#2,a0			; safe, buffer has a 32-bit zero before it

	; LUT to convert signed 16-bit to normalized pre-clamped signed 8-bit
	move.l	PostMixTableCentered(pc),a5
.loop
	; A 68060 is heavily bottlenecked by the chipmem speed, so we should
	; write a longword per write (4x samples). This explains all the overhead,
	; but it's going to pay off in the end.

	move.l	d6,a6

	movem.l	(a0)+,d0-d7	; unaligned!	
	; d0.w .. d7.w now contains signed 16-bit samples (d0.w=L, d1.w=R, ...)
	
	; LEFT - get pre-clamped normalized samples (LUT) and shuffle bytes into longword
	move.b	(a5,d0.w),d0
	lsl.w	#8,d0
	move.b	(a5,d2.w),d0
	swap	d0
	move.b	(a5,d4.w),d0
	lsl.w	#8,d0
	move.b	(a5,d6.w),d0

	; RIGHT - get pre-clamped normalized samples (LUT) and shuffle bytes into longword
	move.b	(a5,d1.w),d1
	lsl.w	#8,d1
	move.b	(a5,d3.w),d1
	swap	d1
	move.b	(a5,d5.w),d1
	lsl.w	#8,d1
	move.b	(a5,d7.w),d1

	; d0.l & d1.l -> 4x 8-bit samples (d0=left,d1=right), pre-clamped	
	
	move.l	a6,d6

	; note: address + d6 is always longword aligned :-)
	move.l	d0,(a1,d6.w)	; write longword to Paula ch 1 (L)
	move.l	d1,(a2,d6.w)	; write longword to Paula ch 2 (R)

	; increase Paula ring-buffer position
	addq.w	#4,d6
	and.w	#SMP_BUFF_SIZE-1,d6	

	subq.l	#1,(sp)
	bne.w .loop
	
	addq.l	#4,sp
.end	rts

	ENDIF
	
; ============================================================
; Post-mix table generator
;
; Generates a 14-bit/8-bit table for the audio channel mixer
; for use in post-mixing (pre-clamping and normalization).
; ============================================================
AllocPostMixTable
	IF _14BIT
		move.l	#65536*2,d0
	ELSE
		move.l	#65536,d0
	ENDIF
	moveq	#MEMF_FAST,d1
	bsr.w	AllocMem
	tst.l	d0
	beq.b	.error		
	move.l	d0,PostMixTable	; set pointer	
.ok	moveq	#0,d0
	rts
.error	moveq	#1,d0
	rts

FreePostMixTable
	IF _14BIT
		move.l	#65536*2,d0
	ELSE
		move.l	#65536,d0
	ENDIF
	move.l	PostMixTable(pc),a1
	tst.l	a1
	beq.b	.ok			; not allocated!
	bsr.w	FreeMem
	clr.l	PostMixTable
.ok	rts
	
	IF _14BIT

	; 14-bit output	(MIX_AMP controls the gain)
GeneratePostMixTable
	movem.l	d0-a6,-(sp)
	move.l	PostMixTable(pc),a0
	add.l	#65536*2,a0 ; start at end of table	
	move.l	#32767,d3
	move.l	#-32767,d4
	move.w	#32768,d5
	moveq	#MIX_AMP+1,d6	; +1 for the quiet 14-bit mode
	move.l	#65536-1,d7
.loop	move.w	d7,d0
	add.w	d5,d0
	ext.l	d0
	muls.l	d6,d0		; d0.l = output sample
	cmp.l	d4,d0		; d0.l >= -32768?
	bge.b	.L1		; nope, clamp it
	move.l	d4,d0
.L1	cmp.l	d3,d0		; d0.l <= 32767?
	ble.b	.L2		; nope, clamp it
	move.l	d3,d0
.L2	lsr.b	#2,d0		; convert lower byte for 14-bit output
	move.w	d0,-(a0)
	dbra	d7,.loop
	; ---------------------
	movem.l	(sp)+,d0-a6
	rts
	
	ELSE
	
	; 8-bit output (MIX_AMP controls the gain)
GeneratePostMixTable
	movem.l	d0-a6,-(sp)
	move.l	PostMixTable(pc),a0
	add.l	#65536,a0 ; start at end of table	
	move.l	#32767,d3
	move.l	#-32767,d4
	move.w	#32768,d5
	moveq	#MIX_AMP,d6
	move.l	#65536-1,d7
.loop	move.w	d7,d0
	add.w	d5,d0
	ext.l	d0
	muls.l	d6,d0		; d0.l = output sample
	; ---------------------
	; Apply rounding
	; ---------------------
	tst.l	d0
	bmi.b	.Neg
	add.l	#128,d0
	bra.b	.L0
.Neg	sub.l	#128,d0
.L0	; ---------------------
	; Clamp
	; ---------------------
	cmp.l	d4,d0		; d0.l >= -32768?
	bge.b	.L1		; nope, clamp it
	move.l	d4,d0
.L1	cmp.l	d3,d0		; d0.l <= 32767?
	ble.b	.L2		; nope, clamp it
	move.l	d3,d0
.L2	; ---------------------
	asr.l	#8,d0
	move.b	d0,-(a0)
	dbra	d7,.loop
	; ---------------------
	movem.l	(sp)+,d0-a6
	rts

	ENDIF

	; input: d0.b = song position (0..255, order)
SetPos
	tst.w	hLen			; song length > 0?
	beq.w	.Len0
	; -----------------------------
	bsr.w	DisableAudioMixer	; make sure mixer is not running!
	; -----------------------------	
	movem.l	d0/a0,-(sp)	
	; -----------------------------
	; Clear states and reset globvol
	; -----------------------------
	move.w	#1,Timer
	clr.b	PattDelTime
	clr.b	PattDelTime2
	clr.b	PosJumpFlag
	clr.b	PBreakPos
	clr.b	PBreakFlag
	clr.b	bxxOverflow		; clear this bugfix-kludge too!
	move.w	#64,GlobVol
	; -----------------------------
	; Set song position
	; -----------------------------
	clr.w	PattPos
	and.w	#$ff,d0
	cmp.w	hLen,d0
	blo.b	.L0
	move.w	hLen,d0
	subq.w	#1,d0
.L0	move.w	d0,SongPos
	lea	hSongTab,a0
	move.b	(a0,d0.w),d0
	move.w	d0,PattNr
	lea	PattLens,a0
	move.w	(a0,d0.w*2),PattLen
	; -----------------------------
	; Clear pattloop and recalc vols
	; -----------------------------
	lea	StmTyp,a0
	move.w	#MAX_CHANNELS-1,d0
.loop1	clr.b	cPattPos(a0)
	clr.b	cLoopCnt(a0)
	or.b	#IS_Vol,cStatus(a0)
	lea	CHN_SIZE(a0),a0
	dbra	d0,.loop1
	; -----------------------------
	; Stop mix voices
	; -----------------------------
	lea	MixVoices,a0
	move.w	#(MAX_CHANNELS*2)-1,d0	; include ramp voices
.loop2	move.b	#IST_Off,vType(a0)
	lea	VOICE_SIZE(a0),a0
	dbra	d0,.loop2
	; -----------------------------
	movem.l	(sp)+,d0/a0
	; -----------------------------
	bsr.w	EnableAudioMixer	; allow mixer to run now
.Len0	rts

	; no input
NextPattern
	tst.w	hLen			; song length > 0?
	beq.b	.Len0
	; -----------------------
	move.l	d0,-(sp)
	move.w	SongPos(pc),d0
	addq.w	#1,d0
	cmp.w	hLen,d0
	bhs.b	.Done
	bsr.w	SetPos
.Done	move.l	(sp)+,d0
.Len0	rts
	
	; no input 
PrevPattern
	tst.w	hLen			; song length > 0?
	beq.b	.Len0
	; -----------------------
	move.l	d0,-(sp)
	move.w	SongPos(pc),d0
	beq.w	.Done
	subq.w	#1,d0
	bsr.w	SetPos
.Done	move.l	(sp)+,d0
.Len0	rts

	; Input: d0.b = 0..64
SetMixingVolume
	movem.l	d0/d1/a0,-(sp)
	; ----------------------------
	and.w	#$ff,d0
	cmp.b	#64,d0
	bls.b	.L0
	moveq	#64,d0
.L0	move.w	d0,MixingVolume
	; ----------------------------
	tst.b	SongIsPlaying(pc)
	beq.b	.NoVolUpdate
	; ----------------------------
	; Force-update channel volumes
	; ----------------------------
	lea	cStatus+StmTyp,a0
	move.w	hAntChn,d0
	subq.b	#1,d0
	moveq	#IS_Vol,d1
.L1	or.b	d1,(a0)
	lea	CHN_SIZE(a0),a0
	dbra	d0,.L1
	; ----------------------------
.NoVolUpdate
	movem.l	(sp)+,d0/d1/a0
	rts
	
	; Output: a0 = pointer to song name (22 bytes, may not be NUL-terminated!)
GetSongName
	lea	hName,a0
	rts

; ------------------------------------------------------------------------------
;                                     DATA
; ------------------------------------------------------------------------------

HeaderText	dc.b "--------------------------------------------------------",$a
		dc.b " xmaplay060 v0.40 ("
	IF _14BIT
		dc.b "14-bit"
	ELSE
		dc.b "8-bit"
	ENDIF
		dc.b " output), by 8bitbubsy",$a
		dc.b " Note: Wire up your Amiga audio for stereo, not mono!",$a
		dc.b "--------------------------------------------------------",$a,0
LoadingModText	dc.b "Opening module...",$a,0
LoadPatTxt	dc.b "Loading pattern data...",$a,0
LoadInsSmpTxt	dc.b "Loading instruments and sample data...",$a,0
LoadInsTxt	dc.b "Loading instruments...",$a,0	; for old XM format
LoadSmpTxt	dc.b "Loading sample data...",$a,0	; for old XM format
AudDevErrText	dc.b "Error: Couldn't allocate task signal and allocate audio!",$a,0
LoadXMErr1Text	dc.b "Error: Couldn't open file for reading!",$a,0
LoadXMErr2Text	dc.b "Error: General I/O error during module reading!",$a,0
LoadXMErr3Text	dc.b "Error: This is an invalid (or unsupported) XM module!",$a,0
LoadXMErr4Text	dc.b "Error: This XM file version is not supported (not v1.02/v1.03/v1.04)!",$a,0
LoadXMErr5Text	dc.b "Error: Unsupported number of channels, orders, instruments and/or patterns!",$a,0
LoadXMErr6Text	dc.b "Error: Out of memory, or corrupt/unsupported XM!",$a,0
AudErrTxt	dc.b "Error initializing audio: Out of memory!",$a,0
CIAErrTxt	dc.b "Error initializing audio: No CIA timers available!",$a,0
CpuErrText	dc.b "Error: This program requires a 020+ CPU!",$a,0
IsPlayingText	dc.b "Now playing, press ESC to stop...",$a,0

XMSig		dc.b "Extended Module: ",0
DosName		dc.b "dos.library",0
ASLName 	dc.b "asl.library",0
GraphicsName	dc.b "graphics.library",0
AudioDevName 	dc.b "audio.device",0
	EVEN

	CNOP 0,4
ErrorTexts
	dc.l LoadXMErr1Text,LoadXMErr2Text,LoadXMErr3Text
	dc.l LoadXMErr4Text,LoadXMErr5Text,LoadXMErr6Text

; offset to samples (0..15) in instrument struct
	CNOP 0,2
iSmpOffset
	dc.w iSamp+(0*SMP_SIZE),iSamp+(1*SMP_SIZE),iSamp+(2*SMP_SIZE),iSamp+(3*SMP_SIZE)
	dc.w iSamp+(4*SMP_SIZE),iSamp+(5*SMP_SIZE),iSamp+(6*SMP_SIZE),iSamp+(7*SMP_SIZE)
	dc.w iSamp+(8*SMP_SIZE),iSamp+(9*SMP_SIZE),iSamp+(10*SMP_SIZE),iSamp+(11*SMP_SIZE)
	dc.w iSamp+(12*SMP_SIZE),iSamp+(13*SMP_SIZE),iSamp+(14*SMP_SIZE),iSamp+(15*SMP_SIZE)

	CNOP 0,4
PaulaIntStruct
	dc.l 0,0
	dc.b NT_INTERRUPT,127
	dc.l PaulaIntName
	dc.l PaulaPos
	dc.l PaulaInterrupt

	CNOP 0,4
CIAIntStruct
	dc.l 0,0
	dc.b NT_INTERRUPT,-1
	dc.l CIAIntName
	dc.l PaulaPos
	dc.l CIAInterrupt
	
	; stuff for allocating audio device
	CNOP 0,4
AudioOpen	dc.b 0
SigBit		dc.b -1
dat		dc.w $f00
AllocPort	dc.l 0,0
		dc.b 4,0
		dc.l 0
		dc.b 0,0
		dc.l 0
ReqList		dc.l 0,0,0
		dc.b 5,0
AllocReq	dc.l 0,0
		dc.w 127
		dc.l 0
		dc.l AllocPort
		dc.w 68
		dc.l 0,0,0
		dc.w 0
		dc.l dat
		dc.l 1,0,0,0,0,0,0
		dc.w 0
	
	CNOP 0,4
ClearRegs		dcb.l 8,0
tmp32 			dc.l 0
MixPos			dc.l 0
MixSamples		dc.l 0
PaulaPos		dc.l 0	; 16.16fp
PaulaPosDelta		dc.l 0	; 16.16fp
PaulaPosMask		dc.l (SMP_BUFF_SIZE-1)<<16!$ffff
OldPaulaInt		dc.l 0
CIARes			dc.l 0
craddr			dc.l 0,0,0
CIAAddr			dc.l $BFD500,$BFD700,$BFE501,$BFE701
PaulaCh1Buf		dc.l 0
PaulaCh2Buf		dc.l 0
	IF _14BIT
PaulaCh3Buf		dc.l 0
PaulaCh4Buf		dc.l 0
	ENDIF
FileReqStruct		dc.l 0
DosBase			dc.l 0
GraphicsBase		dc.l 0
ASLBase			dc.l 0
ArgStr			dc.l 0	
ArgStrLen		dc.l 0
MixingFreq		dc.l 0	; 16.16fp
FileHandle		dc.l 0
MixBufferTmpPtr		dc.l 0
FrequenceDivFactor	dc.l 0
PostMixTable		dc.l 0
PostMixTableCentered	dc.l 0
PMPLeft			dc.l 0	; 16.16fp
SpeedVal		dc.l 0	; 16.16fp
OuterMixVoiceEnd	dc.l 0
MainTask		dc.l 0
WorkerTask		dc.l 0
CopyLoopCounter		dc.w 0
CIA_Period		dc.w 0	; CIA mixing timer period
QuickVolSizeVal		dc.w 0	; vol ramp length (mixfreq / 200)
SamplesToMix		dc.w 0
CDA_BytesLeft		dc.w 0
SongPos			dc.w 0
PattNr			dc.w 0
PattPos			dc.w 0
PattLen			dc.w 64
Speed			dc.w 125
Tempo			dc.w 6
GlobVol			dc.w 64
Timer			dc.w 0
MixPeriod		dc.w 0
TrackWidth		dc.w 0
tmp16			dc.w 0
MixingVolume		dc.w 64 ; 0..64
PattDelTime		dc.b 0
PattDelTime2		dc.b 0
PBreakFlag		dc.b 0
PBreakPos		dc.b 0
PosJumpFlag		dc.b 0
SongIsPlaying		dc.b 0
CDA_SmpEndFlag		dc.b 0
AudioMixFlag		dc.b 0
AudioMixRunning		dc.b 0
XM_MinorVer		dc.b 0
LinearFrqTab		dc.b 0
AmigaIsNTSC		dc.b 0
OldLEDStatus		dc.b 0
CIAName			dc.b "ciax.resource",0
WhichCIAOpen		dc.b 0
PaulaIntName		dc.b "xmaplay060 paula interrupt",0
CIAIntName		dc.b "xmaplay060 cia interrupt",0
WorkerTaskName		dc.b "xmaplay060 task",0
tmp8			dc.b 0
bxxOverflow		dc.b 0
	EVEN

; ------------------------------------------------------------------------------
;                                JUMP TABLES
; ------------------------------------------------------------------------------

	CNOP 0,4
MixFuncTab
	; 8-bit stereo
	dc.l mix8S0,mix8S1,mix8S2,mix8S3,mix8S4,mix8S5,mix8S6,mix8S7
	dc.l mix8S8,mix8S9,mix8SA,mix8SB,mix8SC,mix8SD,mix8SE,mix8SF
	
	; 8-bit center
	dc.l mix8C0,mix8C1,mix8C2,mix8C3,mix8C4,mix8C5,mix8C6,mix8C7
	dc.l mix8C8,mix8C9,mix8CA,mix8CB,mix8CC,mix8CD,mix8CE,mix8CF
	
	; 16-bit stereo
	dc.l mix16S0,mix16S1,mix16S2,mix16S3,mix16S4,mix16S5,mix16S6,mix16S7
	dc.l mix16S8,mix16S9,mix16SA,mix16SB,mix16SC,mix16SD,mix16SE,mix16SF
	
	; 16-bit center
	dc.l mix16C0,mix16C1,mix16C2,mix16C3,mix16C4,mix16C5,mix16C6,mix16C7
	dc.l mix16C8,mix16C9,mix16CA,mix16CB,mix16CC,mix16CD,mix16CE,mix16CF

	; 8-bit stereo (volume ramped)
	dc.l mix8RS0,mix8RS1,mix8RS2,mix8RS3,mix8RS4,mix8RS5,mix8RS6,mix8RS7
	dc.l mix8RS8,mix8RS9,mix8RSA,mix8RSB,mix8RSC,mix8RSD,mix8RSE,mix8RSF
	
	; 8-bit center (volume ramped)
	dc.l mix8RC0,mix8RC1,mix8RC2,mix8RC3,mix8RC4,mix8RC5,mix8RC6,mix8RC7
	dc.l mix8RC8,mix8RC9,mix8RCA,mix8RCB,mix8RCC,mix8RCD,mix8RCE,mix8RCF
	
	; 16-bit stereo (volume ramped)
	dc.l mix16RS0,mix16RS1,mix16RS2,mix16RS3,mix16RS4,mix16RS5,mix16RS6,mix16RS7
	dc.l mix16RS8,mix16RS9,mix16RSA,mix16RSB,mix16RSC,mix16RSD,mix16RSE,mix16RSF
	
	; 16-bit center (volume ramped)
	dc.l mix16RC0,mix16RC1,mix16RC2,mix16RC3,mix16RC4,mix16RC5,mix16RC6,mix16RC7
	dc.l mix16RC8,mix16RC9,mix16RCA,mix16RCB,mix16RCC,mix16RCD,mix16RCE,mix16RCF

MixHandlerFuncTab
	dc.l OneshotHandler,FwdLoopHandler,BidiLoopHandler

VolChTab
	dc.l Vol0,Vol1,Vol2,Vol3,Vol4,Vol5,Vol6,Vol7
	dc.l Vol0,Vol9,VolA,VolB,VolC,VolD,VolE,VolF

VolJumpTab
	dc.l fxRet, fxRet, fxRet, fxRet
	dc.l fxRet, fxRet, V_SlideDown, V_SlideUp
	dc.l fxRet, fxRet, fxRet, V_Vibrato
	dc.l fxRet, V_PanSlideLeft, V_PanSlideRight, TonePorta

JumpTab
	dc.l Arp
	dc.l PortaUp
	dc.l PortaDown
	dc.l TonePorta
	dc.l Vibrato
	dc.l TonePlusVol
	dc.l VibratoPlusVol
	dc.l Tremolo
	dc.l fxRet
	dc.l fxRet
	dc.l Volume
	dc.l fxRet
	dc.l fxRet
	dc.l fxRet
	dc.l EEffects
	dc.l fxRet
	dc.l fxRet
	dc.l GlobalVolSlide
	dc.l fxRet
	dc.l fxRet
	dc.l KeyOffCmd2
	dc.l fxRet
	dc.l fxRet
	dc.l fxRet
	dc.l fxRet
	dc.l PanningSlide
	dc.l fxRet
	dc.l DoMultiRetrig
	dc.l fxRet
	dc.l Tremor
	dc.l fxRet
	dc.l fxRet
	dc.l fxRet
	dc.l fxRet
	dc.l fxRet
	dc.l fxRet

EJumpTab0
	dc.l fxRet, FinePortaUp, FinePortaDown, SetGlissCtrl
	dc.l SetVibratoCtrl, fxRet, JumpLoop, SetTremoloCtrl
	dc.l fxRet, fxRet, VolFineUp, VolFineDown
	dc.l NoteCut0, fxRet, PattDelay, fxRet

	; Normal effects
JumpTab0
	dc.l fxRet ; 0
	dc.l fxRet ; 1
	dc.l fxRet ; 2
	dc.l fxRet ; 3
	dc.l fxRet ; 4
	dc.l fxRet ; 5
	dc.l fxRet ; 6
	dc.l fxRet ; 7
	dc.l SetPan ; 8
	dc.l fxRet ; 9
	dc.l fxRet ; A
	dc.l PosJump ; B
	dc.l SetVol ; C
	dc.l PattBreak ; D
	dc.l EEffects0 ; E
	dc.l SetSpeed ; F
	dc.l SetGlobalVol ; G
	dc.l fxRet ; H
	dc.l fxRet ; I
	dc.l fxRet ; J
	dc.l fxRet ; K
	dc.l SetEnvelopePos ; L
	dc.l fxRet ; M
	dc.l fxRet ; N
	dc.l fxRet ; O
	dc.l fxRet ; P
	dc.l fxRet ; Q
	dc.l MultiRetrig ; R
	dc.l fxRet ; S
	dc.l fxRet ; T
	dc.l fxRet ; U
	dc.l fxRet ; V
	dc.l fxRet ; W
	dc.l XFinePorta ; X
	dc.l fxRet ; Y
	dc.l fxRet ; Z

	; Volumn column	
VolJumpTab0
	dc.l fxRet, V_Volume, V_Volume, V_Volume
	dc.l V_Volume, V_Volume, fxRet, fxRet
	dc.l V_FineSlideDown, V_FineSlideUp, V_SetVibSpeed, fxRet
	dc.l V_SetPan, fxRet, fxRet, fxRet


; ------------------------------------------------------------------------------
;                                    TABLES
; ------------------------------------------------------------------------------

	CNOP 0,2
AmigaFinePeriod
	dc.w 907,900,894,887,881,875,868,862,856,850,844,838,832,826,820,814
	dc.w 808,802,796,791,785,779,774,768,762,757,752,746,741,736,730,725
	dc.w 720,715,709,704,699,694,689,684,678,675,670,665,660,655,651,646
	dc.w 640,636,632,628,623,619,614,610,604,601,597,592,588,584,580,575
	dc.w 570,567,563,559,555,551,547,543,538,535,532,528,524,520,516,513
	dc.w 508,505,502,498,494,491,487,484,480,477,474,470,467,463,460,457

; for arpeggio
ArpTab
	dc.b 0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0
	; The following are overflown bytes from FT2.08/FT2.09's binary.
	; Needed for speeds above 15 (bug in FT2).
	dc.b $00,$18,$31,$4A,$61,$78,$8D,$A1,$B4,$C5,$D4,$E0,$EB,$F4,$FA,$FD
	
; for vibrato and tremolo
VibTab	
	dc.b 0,24,49,74,97,120,141,161
	dc.b 180,197,212,224,235,244,250,253
	dc.b 255,253,250,244,235,224,212,197
	dc.b 180,161,141,120,97,74,49,24

; for auto vibrato
VibSineTab
	dc.b 0,-2,-3,-5,-6,-8,-9,-11,-12,-14,-16,-17,-19,-20,-22,-23,-24,-26,-27
	dc.b -29,-30,-32,-33,-34,-36,-37,-38,-39,-41,-42,-43,-44,-45,-46,-47,-48
	dc.b -49,-50,-51,-52,-53,-54,-55,-56,-56,-57,-58,-59,-59,-60,-60,-61,-61
	dc.b -62,-62,-62,-63,-63,-63,-64,-64,-64,-64,-64,-64,-64,-64,-64,-64,-64
	dc.b -63,-63,-63,-62,-62,-62,-61,-61,-60,-60,-59,-59,-58,-57,-56,-56,-55
	dc.b -54,-53,-52,-51,-50,-49,-48,-47,-46,-45,-44,-43,-42,-41,-39,-38,-37
	dc.b -36,-34,-33,-32,-30,-29,-27,-26,-24,-23,-22,-20,-19,-17,-16,-14,-12
	dc.b -11,-9,-8,-6,-5,-3,-2,0,2,3,5,6,8,9,11,12,14,16,17,19,20,22,23,24,26
	dc.b 27,29,30,32,33,34,36,37,38,39,41,42,43,44,45,46,47,48,49,50,51,52,53
	dc.b 54,55,56,56,57,58,59,59,60,60,61,61,62,62,62,63,63,63,64,64,64,64,64
	dc.b 64,64,64,64,64,64,63,63,63,62,62,62,61,61,60,60,59,59,58,57,56,56,55
	dc.b 54,53,52,51,50,49,48,47,46,45,44,43,42,41,39,38,37,36,34,33,32,30,29
	dc.b 27,26,24,23,22,20,19,17,16,14,12,11,9,8,6,5,3,2

; 8bb: prevents modulus (DIV instruction) in RetrigNote
RetrigTickTab
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b 0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1
	dc.b 0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1
	dc.b 0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3,0,1,2,3
	dc.b 0,1,2,3,4,0,1,2,3,4,0,1,2,3,4,0,1,2,3,4,0,1,2,3,4,0,1,2,3,4,0,1
	dc.b 0,1,2,3,4,5,0,1,2,3,4,5,0,1,2,3,4,5,0,1,2,3,4,5,0,1,2,3,4,5,0,1
	dc.b 0,1,2,3,4,5,6,0,1,2,3,4,5,6,0,1,2,3,4,5,6,0,1,2,3,4,5,6,0,1,2,3
	dc.b 0,1,2,3,4,5,6,7,0,1,2,3,4,5,6,7,0,1,2,3,4,5,6,7,0,1,2,3,4,5,6,7
	dc.b 0,1,2,3,4,5,6,7,8,0,1,2,3,4,5,6,7,8,0,1,2,3,4,5,6,7,8,0,1,2,3,4
	dc.b 0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1
	dc.b 0,1,2,3,4,5,6,7,8,9,10,0,1,2,3,4,5,6,7,8,9,10,0,1,2,3,4,5,6,7,8,9
	dc.b 0,1,2,3,4,5,6,7,8,9,10,11,0,1,2,3,4,5,6,7,8,9,10,11,0,1,2,3,4,5,6,7
	dc.b 0,1,2,3,4,5,6,7,8,9,10,11,12,0,1,2,3,4,5,6,7,8,9,10,11,12,0,1,2,3,4,5
	dc.b 0,1,2,3,4,5,6,7,8,9,10,11,12,13,0,1,2,3,4,5,6,7,8,9,10,11,12,13,0,1,2,3
	dc.b 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,0,1
	
	; Panning table from FT2.08 and later
	; Uses square root for constant power. Similar to Gravis Ultrasound.
	;
	; for (int32_t i = 0; i <= 256; i++)
	;    LUT[i] = (uint32_t)round(65536.0 * sqrt(i / 256.0));
	;
	CNOP 0,4
PanningTab
        dc.l $0000,$1000,$16A1,$1BB6,$2000,$23C7,$2731,$2A55,$2D41,$3000
        dc.l $3299,$3511,$376D,$39B0,$3BDE,$3DF8,$4000,$41F8,$43E2,$45BE
        dc.l $478E,$4952,$4B0C,$4CBC,$4E62,$5000,$5196,$5323,$54AA,$562A
        dc.l $57A3,$5916,$5A82,$5BEA,$5D4C,$5EA8,$6000,$6153,$62A1,$63EC
        dc.l $6531,$6673,$67B1,$68EB,$6A22,$6B55,$6C84,$6DB1,$6EDA,$7000
        dc.l $7123,$7243,$7361,$747B,$7593,$76A9,$77BC,$78CC,$79DA,$7AE6
        dc.l $7BEF,$7CF7,$7DFC,$7EFF,$8000,$80FF,$81FC,$82F7,$83F0,$84E8
        dc.l $85DE,$86D2,$87C4,$88B4,$89A3,$8A90,$8B7C,$8C66,$8D4F,$8E36
        dc.l $8F1C,$9000,$90E3,$91C4,$92A4,$9383,$9461,$953D,$9618,$96F2
        dc.l $97CA,$98A1,$9977,$9A4C,$9B20,$9BF3,$9CC4,$9D95,$9E64,$9F33
        dc.l $A000,$A0CC,$A198,$A262,$A32B,$A3F4,$A4BB,$A581,$A647,$A70B
        dc.l $A7CF,$A892,$A954,$AA15,$AAD5,$AB95,$AC53,$AD11,$ADCE,$AE8A
        dc.l $AF45,$B000,$B0BA,$B173,$B22B,$B2E3,$B399,$B450,$B505,$B5BA
        dc.l $B66E,$B721,$B7D3,$B885,$B937,$B9E7,$BA97,$BB46,$BBF5,$BCA3
        dc.l $BD51,$BDFD,$BEA9,$BF55,$C000,$C0AA,$C154,$C1FD,$C2A6,$C34E
        dc.l $C3F6,$C49C,$C543,$C5E9,$C68E,$C733,$C7D7,$C87B,$C91E,$C9C1
        dc.l $CA63,$CB04,$CBA6,$CC46,$CCE6,$CD86,$CE25,$CEC4,$CF62,$D000
        dc.l $D09D,$D13A,$D1D7,$D272,$D30E,$D3A9,$D444,$D4DE,$D577,$D611
        dc.l $D6AA,$D742,$D7DA,$D872,$D909,$D9A0,$DA36,$DACC,$DB62,$DBF7
        dc.l $DC8B,$DD20,$DDB4,$DE47,$DEDB,$DF6E,$E000,$E092,$E124,$E1B5
        dc.l $E246,$E2D7,$E367,$E3F7,$E487,$E516,$E5A5,$E633,$E6C1,$E74F
        dc.l $E7DD,$E86A,$E8F7,$E983,$EA0F,$EA9B,$EB27,$EBB2,$EC3D,$ECC7
        dc.l $ED51,$EDDB,$EE65,$EEEE,$EF77,$F000,$F088,$F110,$F198,$F220
        dc.l $F2A7,$F32E,$F3B4,$F43B,$F4C1,$F546,$F5CC,$F651,$F6D6,$F75B
        dc.l $F7DF,$F863,$F8E7,$F96A,$F9EE,$FA71,$FAF3,$FB76,$FBF8,$FC7A
        dc.l $FCFB,$FD7D,$FDFE,$FE7F,$FEFF,$FF80,$10000

	; 32.32fp values for calculating LogTab for XMs using linear periods
	;
	; for (int32_t i = 0; i < (12*16*4)*2; i++)
	; {
	;     uint64_t x64 = (uint64_t)round(8363.0 * 256.0 * exp2((i/2)
	;                       / (12.0 * 16.0 * 4.0)) * (UINT32_MAX+1.0));
	;     LUT[i] = (i & 1) ? (x64 >> 32) : (x64 & 0xFFFFFFFF);
	; }
	;
        CNOP 0,4
LogTabSource
        dc.l $00000000,$0020AB00,$22B17C8E,$0020B28D,$043CC4CE,$0020BA1C
        dc.l $A5092340,$0020C1AC,$057DFA46,$0020C93F,$2602C42A,$0020D0D3
        dc.l $06FF1320,$0020D869,$A8DA9148,$0020E000,$0BFD00C8,$0020E79A
        dc.l $30CE3BAC,$0020EF35,$17B63412,$0020F6D2,$C11CF41A,$0020FE70
        dc.l $2D6A9DEE,$00210611,$5D076BCC,$00210DB3,$505BB00C,$00211557
        dc.l $07CFD520,$00211CFD,$83CC5D9E,$002124A4,$C4B9E442,$00212C4D
        dc.l $CB011BFA,$002133F8,$970ACFEC,$00213BA5,$293FE368,$00214354
        dc.l $8209520C,$00214B04,$A1D02FB0,$002152B6,$88FDA880,$00215A6A
        dc.l $37FB00EA,$00216220,$AF3195C4,$002169D7,$EF0ADC26,$00217190
        dc.l $F7F061A0,$0021794B,$CA4BCC20,$00218108,$6686D9FC,$002188C7
        dc.l $CD0B61FA,$00219087,$FE435360,$00219849,$FA98B5E6,$0021A00D
        dc.l $C275A9D2,$0021A7D3,$564467E8,$0021AF9B,$B66F4180,$0021B764
        dc.l $E360A080,$0021BF2F,$DD83076E,$0021C6FC,$A5411166,$0021CECB
        dc.l $3B057232,$0021D69C,$9F3AF642,$0021DE6E,$D24C82AE,$0021E642
        dc.l $D4A51552,$0021EE18,$A6AFC4BA,$0021F5F0,$48D7C036,$0021FDCA
        dc.l $BB884FE4,$002205A5,$FF2CD4A4,$00220D82,$1430C82A,$00221562
        dc.l $FAFFBD06,$00221D42,$B4055EA8,$00222525,$3FAD7158,$00222D0A
        dc.l $9E63D254,$002234F0,$D09477BE,$00223CD8,$D6AB70B6,$002244C2
        dc.l $B114E550,$00224CAE,$603D16A2,$0022549C,$E4905ECC,$00225C8B
        dc.l $3E7B30F2,$0022647D,$6E6A1950,$00226C70,$74C9BD38,$00227465
        dc.l $5206DB14,$00227C5C,$068E4A7A,$00228455,$92CCFC1E,$00228C4F
        dc.l $F72FF9EE,$0022944B,$34246708,$00229C4A,$4A177FBC,$0022A44A
        dc.l $397699A4,$0022AC4C,$02AF23A2,$0022B450,$A62EA5D8,$0022BC55
        dc.l $2462C1C4,$0022C45D,$7DB93238,$0022CC66,$B29FCB60,$0022D471
        dc.l $C3847AD0,$0022DC7E,$B0D54786,$0022E48D,$7B0051E8,$0022EC9E
        dc.l $2273D3D4,$0022F4B1,$A79E20A4,$0022FCC5,$0AEDA53A,$002304DC
        dc.l $4CD0E7EC,$00230CF4,$6DB688AC,$0023150E,$6E0D40F8,$00231D2A
        dc.l $4E43E3E8,$00232548,$0EC95E2E,$00232D68,$B00CB62A,$00233589
        dc.l $327D0BDA,$00233DAD,$968998F2,$002345D2,$DCA1B0DA,$00234DF9
        dc.l $0534C0BA,$00235623,$10B24F74,$00235E4E,$FF89FDBA,$0023667A
        dc.l $D22B8600,$00236EA9,$8906BCA2,$002376DA,$248B8FC0,$00237F0D
        dc.l $A52A0760,$00238741,$0B524574,$00238F78,$577485D4,$002397B0
        dc.l $8A011E4C,$00239FEA,$A3687E9C,$0023A826,$A41B3084,$0023B064
        dc.l $8C89D7C6,$0023B8A4,$5D253230,$0023C0E6,$165E179C,$0023C92A
        dc.l $B8A579FE,$0023D16F,$446C6564,$0023D9B7,$BA23FFF8,$0023E200
        dc.l $1A3D8A12,$0023EA4C,$652A5E38,$0023F299,$9B5BF11E,$0023FAE8
        dc.l $BD43D1B8,$00240339,$CB53A938,$00240B8C,$C5FD3B14,$002413E1
        dc.l $ADB2650E,$00241C38,$82E51F3C,$00242491,$46077C0A,$00242CEC
        dc.l $F78BA848,$00243548,$97E3EB22,$00243DA7,$2782A630,$00244608
        dc.l $A6DA5586,$00244E6A,$165D8F9E,$002456CF,$767F0578,$00245F35
        dc.l $C7B18296,$0024679D,$0A67ED00,$00247008,$3F154552,$00247874
        dc.l $662CA6BA,$002480E2,$80214702,$00248952,$8D667698,$002491C4
        dc.l $8E6FA08A,$00249A38,$83B04A9C,$0024A2AE,$6D9C1548,$0024AB26
        dc.l $4CA6BBB6,$0024B3A0,$214413DC,$0024BC1C,$EBE80E6C,$0024C499
        dc.l $AD06B6F0,$0024CD19,$651433B6,$0024D59B,$1484C5F4,$0024DE1F
        dc.l $BBCCC9B6,$0024E6A4,$5B60B5F2,$0024EF2C,$F3B51C8C,$0024F7B5
        dc.l $853EAA52,$00250041,$10722712,$002508CF,$95C4758E,$0025115E
        dc.l $15AA939C,$002519F0,$90999A12,$00252283,$0706BCDC,$00252B19
        dc.l $79674AFA,$002533B0,$E830AE8E,$00253C49,$53D86CD8,$002544E5
        dc.l $BCD4264A,$00254D82,$23999680,$00255622,$889E9452,$00255EC3
        dc.l $EC5911CE,$00256766,$4F3F1C50,$0025700C,$B1C6DC72,$002578B3
        dc.l $14669628,$0025815D,$7794A8B8,$00258A08,$DBC78EC2,$002592B5
        dc.l $4175DE50,$00259B65,$A91648D0,$0025A416,$131F9B1C,$0025ACCA
        dc.l $8008BD96,$0025B57F,$F048B400,$0025BE36,$64569DB8,$0025C6F0
        dc.l $DCA9B59A,$0025CFAB,$59B9520E,$0025D869,$DBFCE51E,$0025E128
        dc.l $63EBFC64,$0025E9EA,$F1FE4122,$0025F2AD,$86AB7842,$0025FB73
        dc.l $226B8260,$0026043B,$C5B65BCA,$00260D04,$71041C8C,$002615D0
        dc.l $24CCF876,$00261E9E,$E1893F1E,$0026276D,$A7B15BEA,$0026303F
        dc.l $77BDD616,$00263913,$522750BC,$002641E9,$37668AD8,$00264AC1
        dc.l $27F45F50,$0026539B,$2449C4F6,$00265C77,$2CDFCE96,$00266555
        dc.l $422FAAF6,$00266E35,$64B2A4E4,$00267717,$94E2232E,$00267FFB
        dc.l $D337A8B8,$002688E1,$202CD482,$002691CA,$7C3B619C,$00269AB4
        dc.l $E7DD2746,$0026A3A0,$638C18E0,$0026AC8F,$EFC24604,$0026B57F
        dc.l $8CF9DA78,$0026BE72,$3BAD1E48,$0026C767,$FC5675C4,$0026D05D
        dc.l $CF70617E,$0026D956,$B5757E64,$0026E251,$AEE085B8,$0026EB4E
        dc.l $BC2C4D14,$0026F44D,$DDD3C67C,$0026FD4E,$14520064,$00270652
        dc.l $602225A8,$00270F57,$C1BF7DA4,$0027185E,$39A56C30,$00272168
        dc.l $C84F71AA,$00272A73,$6E392AFC,$00273381,$2BDE51A2,$00273C91
        dc.l $01BABBB4,$002745A3,$F04A5BE8,$00274EB6,$F809419C,$002757CC
        dc.l $197398DC,$002760E5,$5505AA62,$002769FF,$AB3BDBAC,$0027731B
        dc.l $1C92AEF0,$00277C3A,$A986C332,$0027855A,$5294D442,$00278E7D
        dc.l $1839BAC6,$002797A2,$FAF26C40,$0027A0C8,$FB3BFB12,$0027A9F1
        dc.l $1993968C,$0027B31D,$56768AEA,$0027BC4A,$B262415C,$0027C579
        dc.l $2DD44018,$0027CEAB,$C94A2A52,$0027D7DE,$8541C044,$0027E114
        dc.l $6238DF44,$0027EA4C,$60AD81BA,$0027F386,$811DBF2A,$0027FCC2
        dc.l $C407CC44,$00280600,$29E9FAE0,$00280F41,$B342BA0C,$00281883
        dc.l $6090960A,$002821C8,$32523866,$00282B0F,$290667EC,$00283458
        dc.l $452C08B4,$00283DA3,$87421C36,$002846F0,$EFC7C136,$0028503F
        dc.l $7F3C33E6,$00285991,$361ECDE0,$002862E5,$14EF0628,$00286C3B
        dc.l $1C2C7140,$00287593,$4C56C120,$00287EED,$A5EDC550,$00288849
        dc.l $29716AD2,$002891A8,$D761BC48,$00289B08,$B03EE1EC,$0028A46B
        dc.l $B489218E,$0028ADD0,$E4C0DEB2,$0028B737,$41669A7E,$0028C0A1
        dc.l $CAFAF3D0,$0028CA0C,$81FEA744,$0028D37A,$66F28F34,$0028DCEA
        dc.l $7A57A3C8,$0028E65C,$BCAEFAF0,$0028EFD0,$2E79C87C,$0028F947
        dc.l $D0395E12,$002902BF,$A26F2B3E,$00290C3A,$A59CBD7E,$002915B7
        dc.l $DA43C036,$00291F36,$40E5FCCE,$002928B8,$DA055AAC,$0029323B
        dc.l $A623DF38,$00293BC1,$A5C3ADEC,$00294549,$D967085C,$00294ED3
        dc.l $41904E2C,$00295860,$DEC1FD2A,$002961EE,$B17EB150,$00296B7F
        dc.l $BA4924C6,$00297512,$F9A42FE8,$00297EA7,$7012C958,$0029883F
        dc.l $1E1805FA,$002991D9,$04371900,$00299B75,$22F353EE,$0029A513
        dc.l $7AD026A4,$0029AEB3,$0C511F62,$0029B856,$D7F9EAD6,$0029C1FA
        dc.l $DE4E5416,$0029CBA1,$1FD244B6,$0029D54B,$9D09C4C8,$0029DEF6
        dc.l $5678FADA,$0029E8A4,$4CA42C12,$0029F254,$800FBC1E,$0029FC06
        dc.l $F1402D50,$002A05BA,$A0BA2094,$002A0F71,$8F025584,$002A192A
        dc.l $BC9DAA64,$002A22E5,$2A111C34,$002A2CA3,$D7E1C6AC,$002A3662
        dc.l $C694E44A,$002A4024,$F6AFCE5E,$002A49E8,$68B7FD02,$002A53AF
        dc.l $1D330730,$002A5D78,$14A6A2C2,$002A6743,$4F98A47A,$002A7110
        dc.l $CE8F0008,$002A7ADF,$920FC814,$002A84B1,$9AA12E44,$002A8E85
        dc.l $E8C98344,$002A985B,$7D0F36CA,$002AA234,$57F8D7A2,$002AAC0F
        dc.l $7A0D13AC,$002AB5EC,$E3D2B7F2,$002ABFCB,$95D0B0A0,$002AC9AD
        dc.l $908E091C,$002AD391,$D491EBF2,$002ADD77,$6263A304,$002AE760
        dc.l $3A8A9764,$002AF14B,$5D8E5178,$002AFB38,$CBF67900,$002B0527
        dc.l $864AD518,$002B0F19,$8D134C32,$002B190D,$E0D7E438,$002B2303
        dc.l $8220C27A,$002B2CFC,$71762BC8,$002B36F7,$AF60846E,$002B40F4
        dc.l $3C685046,$002B4AF4,$191632AA,$002B54F6,$45F2EE9C,$002B5EFA
        dc.l $C38766A8,$002B6900,$925C9D0E,$002B7309,$B2FBB3B0,$002B7D14
        dc.l $25EDEC28,$002B8722,$EBBCA7C2,$002B9131,$04F16798,$002B9B44
        dc.l $7215CC88,$002BA558,$33B39738,$002BAF6F,$4A54A830,$002BB988
        dc.l $B682FFD0,$002BC3A3,$78C8BE64,$002BCDC1,$91B02420,$002BD7E1
        dc.l $01C39134,$002BE204,$C98D85C8,$002BEC28,$E998A206,$002BF64F
        dc.l $626FA624,$002C0079,$349D726E,$002C0AA5,$60AD074A,$002C14D3
        dc.l $E729853A,$002C1F03,$C89E2CEE,$002C2936,$05965F46,$002C336C
        dc.l $9E9D9D58,$002C3DA3,$943F8876,$002C47DD,$E707E240,$002C5219
        dc.l $97828C9E,$002C5C58,$A63B89D0,$002C6699,$13BEFC78,$002C70DD
        dc.l $E0992790,$002C7B22,$0D566E8E,$002C856B,$9A83554C,$002C8FB5
        dc.l $88AC802A,$002C9A02,$D85EB402,$002CA451,$8A26D644,$002CAEA3
        dc.l $9E91ECE4,$002CB8F7,$162D1E78,$002CC34E,$F185B236,$002CCDA6
        dc.l $31290FF6,$002CD802,$D5A4C046,$002CE25F,$DF866C6C,$002CECBF
        dc.l $4F5BDE60,$002CF722,$25B300F6,$002D0187,$6319DFC0,$002D0BEE
        dc.l $081EA72A,$002D1658,$154FA478,$002D20C4,$8B3B45E2,$002D2B32
        dc.l $6A701A7A,$002D35A3,$B37CD254,$002D4016,$66F03E74,$002D4A8C
        dc.l $855950EA,$002D5504,$0F471CD0,$002D5F7F,$0548D64E,$002D69FC
        dc.l $67EDD2A6,$002D747B,$37C58840,$002D7EFD,$755F8EAE,$002D8981
        dc.l $214B9EAC,$002D9408,$3C19923A,$002D9E91,$C659648C,$002DA91C
        dc.l $C09B3224,$002DB3AA,$2B6F38DC,$002DBE3B,$0765D7D4,$002DC8CE
        dc.l $550F8F96,$002DD363,$14FD0216,$002DDDFB,$47BEF2B0,$002DE895
        dc.l $EDE64638,$002DF331,$08040302,$002DFDD1,$96A950E4,$002E0872
        dc.l $9A67794A,$002E1316,$13CFE72C,$002E1DBD,$03742720,$002E2866
        dc.l $69E5E76A,$002E3311,$47B6F7EC,$002E3DBF,$9D794A4E,$002E486F
        dc.l $6BBEF1E6,$002E5322,$B31A23D4,$002E5DD7,$741D3702,$002E688F
        dc.l $AF5AA430,$002E7349,$656505F8,$002E7E06,$96CF18DA,$002E88C5
        dc.l $442BBB3C,$002E9387,$6E0DED7A,$002E9E4B,$1508D1E8,$002EA912
        dc.l $39AFACE8,$002EB3DB,$DC95E4D4,$002EBEA6,$FE4F0224,$002EC974
        dc.l $9F6EAF70,$002ED445,$C088B960,$002EDF18,$62310EDC,$002EE9EE
        dc.l $84FBC0EA,$002EF4C6,$297D02D8,$002EFFA1,$50492A2E,$002F0A7E
        dc.l $F9F4AEC2,$002F155D,$27142AB4,$002F2040,$D83C5A8A,$002F2B24
        dc.l $0E021D24,$002F360C,$C8FA73CA,$002F40F5,$09BA823C,$002F4BE2
        dc.l $D0D78EA6,$002F56D0,$1EE701CA,$002F61C2,$F47E66E2,$002F6CB5
        dc.l $52336BC0,$002F77AC,$389BE0CC,$002F82A5,$A84DB914,$002F8DA0
        dc.l $A1DF0A4E,$002F989E,$25E60CE2,$002FA39F,$34F91BE8,$002FAEA2
        dc.l $CFAEB548,$002FB9A7,$F69D79AA,$002FC4AF,$AA5C2C86,$002FCFBA
        dc.l $EB81B43A,$002FDAC7,$BAA519F8,$002FE5D7,$185D89DE,$002FF0EA
        dc.l $05425304,$002FFBFF,$81EAE770,$00300716,$8EEEDC34,$00301230
        dc.l $2CE5E962,$00301D4D,$5C67EA28,$0030286C,$1E0CDCCC,$0030338E
        dc.l $726CE2AC,$00303EB2,$5A204062,$003049D9,$D5BF5DAA,$00305502
        dc.l $E5E2C584,$0030602E,$8B23262E,$00306B5D,$C6195134,$0030768E
        dc.l $975E3B76,$003081C2,$FF8AFD2C,$00308CF8,$FF38D1F2,$00309831
        dc.l $970118D4,$0030A36D,$C77D5448,$0030AEAB,$91472A4C,$0030B9EC
        dc.l $F4F8645A,$0030C52F,$F32AEF7A,$0030D075,$8C78DC4A,$0030DBBE
        dc.l $C17C5F06,$0030E709,$92CFCF8E,$0030F257,$010DA968,$0030FDA8
        dc.l $0CD08BD8,$003108FB,$B6B339E6,$00311450,$FF509A52,$00311FA8
        dc.l $E743B7AC,$00312B03,$6F27C064,$00313661,$979806C6,$003141C1
        dc.l $613000FE,$00314D24,$CC8B4934,$00315889,$DA459D72,$003163F1
        dc.l $8AFADFDE,$00316F5C,$DF471694,$00317AC9,$D7C66BC4,$00318639
        dc.l $75152DBE,$003191AC,$B7CFCEEE,$00319D21,$A092E5E0,$0031A899
        dc.l $2FFB2D5E,$0031B414,$66A58478,$0031BF91,$452EEE62,$0031CB11
        dc.l $CC3492BA,$0031D693,$FC53BD60,$0031E218,$D629DE90,$0031EDA0
        dc.l $5A548AF8,$0031F92B,$89717BA4,$003204B8,$641E8E16,$00321048
        dc.l $EAF9C45C,$00321BDA,$1EA144FE,$00322770,$FFB35B12,$00323307
        dc.l $8ECE764C,$00323EA2,$CC912AFC,$00324A3F,$B99A321A,$003255DF
        dc.l $56886950,$00326182,$A3FAD2F8,$00326D27,$A290963E,$003278CF
        dc.l $52E8FF0C,$0032847A,$B5A37E20,$00329027,$CB5FA912,$00329BD7
        dc.l $94BD3A64,$0032A78A,$125C117E,$0032B340,$44DC32BC,$0032BEF8
        dc.l $2CDDC77E,$0032CAB3,$CB011E20,$0032D670,$1FE6AA0C,$0032E231
        dc.l $2C2F03D6,$0032EDF4,$F07AE918,$0032F9B9,$6D6B3CA0,$00330582
        dc.l $A3A10670,$0033114D,$93BD73B8,$00331D1B,$3E61D6F6,$003328EC
        dc.l $A42FA7E8,$003334BF,$C5C883A6,$00334095,$A3CE2C9C,$00334C6E
        dc.l $3EE28AA2,$0033584A,$97A7AAFC,$00336428,$AEBFC060,$00337009
        dc.l $84CD22FA,$00337BED,$1A725098,$003387D4,$7051EC74,$003393BD
        dc.l $870EBF7A,$00339FA9,$5F4BB82E,$0033AB98,$F9ABEABE,$0033B789
        dc.l $56D29108,$0033C37E,$77630AAE,$0033CF75,$5C00DD02,$0033DB6F
        dc.l $054FB33A,$0033E76C,$73F35E52,$0033F36B,$A88FD528,$0033FF6D
        dc.l $A3C93482,$00340B72,$6643BF16,$0034177A,$F0A3DD8E,$00342384
        dc.l $438E1E96,$00342F92,$5FA736E8,$00343BA2,$4594014C,$003447B5
        dc.l $F5F97EA6,$003453CA,$717CD602,$00345FE3,$B8C35492,$00346BFE
        dc.l $CC726DC6,$0034781C,$AD2FBB42,$0034843D,$5BA0FD00,$00349061
        dc.l $D86C193C,$00349C87,$24371C92,$0034A8B1,$3FA83A02,$0034B4DD
        dc.l $2B65CAF0,$0034C10C,$E8164F3C,$0034CD3D,$76606D3A,$0034D972
        dc.l $D6EAF1CE,$0034E5A9,$0A5CD062,$0034F1E4,$115D22F2,$0034FE21
        dc.l $EC932A30,$00350A60,$9CA64D5A,$003516A3,$223E1A7E,$003522E9
        dc.l $7E02464E,$00352F31,$B09AAC4C,$00353B7C,$BAAF4EBC,$003547CA
        dc.l $9CE856CC,$0035541B,$57EE1476,$0035606F,$EC68FEA0,$00356CC5
        dc.l $5B01B32A,$0035791F,$A460F6E0,$0035857B,$C92FB59C,$003591DA
        dc.l $CA170244,$00359E3C,$A7C016CA,$0035AAA1,$62D4543E,$0035B709
        dc.l $FBFD42E8,$0035C373,$73E4922E,$0035CFE1,$CB3418B4,$0035DC51
        dc.l $0295D46A,$0035E8C5,$1AB3EA7A,$0035F53B,$1438A76E,$003601B4
        dc.l $EFCE7F2E,$00360E2F,$AE200D02,$00361AAE,$4FD813A8,$00362730
        dc.l $D5A17D50,$003633B4,$40275BB4,$0036403C,$9014E816,$00364CC6
        dc.l $C6158348,$00365953,$E2D4B5BC,$003665E3,$E6FE2F8C,$00367276
        dc.l $D33DC884,$00367F0C,$A83F8022,$00368BA5,$66AF7DAC,$00369841
        dc.l $0F3A102E,$0036A4E0,$A28BAE8E,$0036B181,$2150F78C,$0036BE26
        dc.l $8C36B1CE,$0036CACD,$E3E9CBEE,$0036D777,$29175C7E,$0036E425
        dc.l $5C6CA212,$0036F0D5,$7E970344,$0036FD88,$90440ECE,$00370A3E
        dc.l $92217B84,$003716F7,$84DD285A,$003723B3,$69251C80,$00373072
        dc.l $3FA78758,$00373D34,$0912C092,$003749F9,$C615481A,$003756C0
        dc.l $775DC642,$0037638B,$1D9B0BB2,$00377059,$B97C1180,$00377D29
        dc.l $4BAFF932,$003789FD,$D4E60CC6,$003796D3,$55CDBEC8,$0037A3AD
        dc.l $CF16AA46,$0037B089,$417092EE,$0037BD69,$AD8B650E,$0037CA4B
        dc.l $1417359E,$0037D731,$75C44242,$0037E419,$D342F16A,$0037F104
        dc.l $2D43D242,$0037FDF3,$84779CC6,$00380AE4,$D98F31C8,$003817D8
        dc.l $2D3B9B10,$003824D0,$802E0B3A,$003831CA,$D317DDE2,$00383EC7
        dc.l $26AA97AC,$00384BC8,$7B97E638,$003858CB,$D291A03A,$003865D1
        dc.l $2C49C586,$003872DB,$89727F12,$00387FE7,$EABE1F08,$00388CF6
        dc.l $50DF20C2,$00389A09,$BC8828E2,$0038A71E,$2E6C054E,$0038B437
        dc.l $A73DAD4C,$0038C152,$27B04178,$0038CE71,$B0770BD8,$0038DB92
        dc.l $42457FE4,$0038E8B7,$DDCF3A8E,$0038F5DE,$83C80248,$00390309
        dc.l $34E3C724,$00391037,$F1D6A2B6,$00391D67,$BB54D83C,$00392A9B
        dc.l $9212D4A6,$003937D2,$76C52E90,$0039450C,$6A20A652,$00395249
        dc.l $6CDA261A,$00395F89,$7FA6C1DA,$00396CCC,$A33BB766,$00397A12
        dc.l $D84E6E70,$0039875B,$1F9478A4,$003994A8,$79C3919A,$0039A1F7
        dc.l $E7919EF8,$0039AF49,$69B4B068,$0039BC9F,$00E2FFAA,$0039C9F8
        dc.l $ADD2F0A0,$0039D753,$713B1152,$0039E4B2,$4BD21A02,$0039F214
        dc.l $3E4EED22,$0039FF79,$49689776,$003A0CE1,$6DD6500A,$003A1A4C
        dc.l $AC4F784C,$003A27BA,$058B9C02,$003A352C,$7A42716E,$003A42A0
        dc.l $0B2BD934,$003A5018,$B8FFDE98,$003A5D92,$8476B746,$003A6B10
        dc.l $6E48C3A0,$003A7891,$772E8E88,$003A8615,$9FE0CD9C,$003A939C
        dc.l $E9186128,$003AA126,$538E5436,$003AAEB4,$DFFBDC8A,$003ABC44
        dc.l $8F1A5ACA,$003AC9D8,$61A35A68,$003AD76F,$585091BC,$003AE509
        dc.l $73DBE210,$003AF2A6,$B4FF57A8,$003B0046,$1C7529BC,$003B0DEA
        dc.l $AAF7BA9E,$003B1B90,$614197B0,$003B293A,$400D7970,$003B36E7
        dc.l $48164386,$003B4497,$7A1704D0,$003B524A,$D6CAF76E,$003B6000
        dc.l $5EED80B8,$003B6DBA,$133A316A,$003B7B77,$F46CC58C,$003B8936
        dc.l $03412496,$003B96FA,$40736166,$003BA4C0,$ACBFBA5A,$003BB289
        dc.l $48E29950,$003BC056,$159893B4,$003BCE26,$139E6A8A,$003BDBF9
        dc.l $43B10A7C,$003BE9CF,$A68D8BDA,$003BF7A8,$3CF132A4,$003C0585
        dc.l $07996EA8,$003C1365,$0743DB76,$003C2148,$3CAE4072,$003C2F2E
        dc.l $A89690E0,$003C3D17,$4BBAEBE8,$003C4B04,$26D99CA8,$003C58F4
        dc.l $3AB11A42,$003C66E7,$880007D4,$003C74DD,$0F853486,$003C82D7
        dc.l $D1FF9BB4,$003C90D3,$D02E64D0,$003C9ED3,$0AD0E376,$003CACD7
        dc.l $82A69782,$003CBADD,$386F2D18,$003CC8E7,$2CEA7CAA,$003CD6F4
        dc.l $60D88AF8,$003CE504,$D4F98932,$003CF317,$8A0DD4EC,$003D012E
        dc.l $80D5F832,$003D0F48,$BA12A99C,$003D1D65,$3684CC3C,$003D2B86
        dc.l $F6ED6FCC,$003D39A9,$FC0DD098,$003D47D0,$46A757A2,$003D55FB
        dc.l $D77B9A96,$003D6428,$AF4C5BF0,$003D7259,$CEDB8ADE,$003D808D
        dc.l $36EB437E,$003D8EC5,$E83DCEB0,$003D9CFF,$E395A256,$003DAB3D
        dc.l $29B56134,$003DB97F,$BB5FDB16,$003DC7C3,$99580CC2,$003DD60B
        dc.l $C4612028,$003DE456,$3D3E6C3E,$003DF2A5,$04B3752C,$003E00F7
        dc.l $1B83EC50,$003E0F4C,$8273B032,$003E1DA4,$3A46CCB6,$003E2C00
        dc.l $43C17B0A,$003E3A5F,$9FA821AE,$003E48C1,$4EBF5492,$003E5727
        dc.l $51CBD514,$003E6590,$A9929214,$003E73FC,$56D8A7E6,$003E826C
        dc.l $5A636080,$003E90DF,$B4F83368,$003E9F55,$675CC5CE,$003EADCF
        dc.l $7256EA90,$003EBC4C,$D6ACA248,$003ECACC,$95241B50,$003ED950
        dc.l $AE83B1D6,$003EE7D7,$2391EFE6,$003EF662,$F5158D62,$003F04EF
        dc.l $23D57030,$003F1381,$B098AC1C,$003F2215,$9C2682FC,$003F30AD
        dc.l $E74664C4,$003F3F48,$92BFEF6A,$003F4DE7,$9F5AEF1C,$003F5C89
        dc.l $0DDF5E2A,$003F6B2F,$DF15652A,$003F79D7,$13C55AE8,$003F8884
        dc.l $ACB7C488,$003F9733,$AAB55588,$003FA5E6,$0E86EFCC,$003FB49D
        dc.l $D8F5A3A2,$003FC356,$0ACAAFCC,$003FD214,$A4CF81A2,$003FE0D4
        dc.l $A7CDB506,$003FEF98,$148F1464,$003FFE60,$EBDD98E8,$00400D2A
        dc.l $2E836A54,$00401BF9,$DD4ADF30,$00402ACA,$F8FE7CD4,$0040399F
        dc.l $8268F758,$00404878,$7A5531B0,$00405754,$E18E3DC0,$00406633
        dc.l $B8DF5C58,$00407516,$0113FD40,$004083FD,$BAF7BF4C,$004092E6
        dc.l $E7567060,$0040A1D3,$86FC0D70,$0040B0C4,$9AB4C2B0,$0040BFB8
        dc.l $234CEB6C,$0040CEB0,$21911244,$0040DDAB,$964DF10C,$0040ECA9
        dc.l $825070F0,$0040FBAB,$E665AA8C,$00410AB0,$C35AE5C4,$004119B9
        dc.l $19FD9A10,$004128C6,$EB1B6E50,$004137D5,$378238F4,$004146E9

; ------------------------------------------------------------------------------
;                                   BSS HUNK
; ------------------------------------------------------------------------------
	;SECTION bss,BSS

	CNOP 0,4
WorkerTaskStack		ds.b TASK_STACK_SIZE
WorkerTaskStruct	ds.b TC_SIZE
ChnReloc		ds.w MAX_CHANNELS
FileName		ds.b MAX_PATH_LEN

	CNOP 0,4
SpareInstr		ds.b INS_SIZE

	CNOP 0,4
; -------------------------
; XM header
; -------------------------
hSig		ds.b 	17
hName		ds.b 	21
hProgName	ds.b	20
hVer		ds.w 	1
hHeaderSize	ds.l 	1
hLen		ds.w 	1
hRepS		ds.w 	1
hAntChn		ds.w 	1
hAntPtn		ds.w 	1
hAntInstrs	ds.w 	1
hFlags		ds.w 	1
hDefTempo	ds.w 	1
hDefSpeed 	ds.w 	1
hSongTab 	ds.b 	256	; order/position table
; -------------------------

; channels
	CNOP 0,4
StmTyp	ds.b CHN_SIZE*MAX_CHANNELS

; voices
	CNOP 0,4
VoiceOffsets
	ds.l MAX_CHANNELS*2

	CNOP 0,4
MixVoices
	ds.b VOICE_SIZE*(MAX_CHANNELS*2)
	
	CNOP 0,4
Patt		ds.l 256	; pointers to pattern data
Instr		ds.l 128	; pointers to instruments
PattLens	ds.w 256	; number of rows in patterns
NilPatternLine	ds.b 5*32	; empty pattern row

; ------------------------
; Temporary XM headers
; ------------------------
	CNOP 0,4
InsHdr	ds.b INS_HDR_SIZE+1	; +1 to make it 263->264 (multiple of 4)
	CNOP 0,4
SmpHdrs	ds.b SMP_HDR_SIZE*16
; ------------------------

	CNOP 0,2
	ds.w 8	; pre-padding needed for buggy RelocateTon routine
Note2Period
	ds.w (12*10*16)+16 ; calculated later

	CNOP 0,4
BPM2SmpsPerTick
	ds.l (255-32)+1 ; calculated later

	CNOP 0,4
LogTab	ds.l 12*16*4 ; calculated later

	CNOP 0,4
	ds.l 1	; pre-padding needed for word-alignment trick
CDA_MixBuffer
	ds.l SMP_BUFF_SIZE*2 ; *2 for stereo
