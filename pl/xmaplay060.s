;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
; ==============================================================================
; xmaplay060 - Port of Fasttracker II's XM replayer for 68060 Amigas
; by 8bitbubsy, aug. 2020 - mar. 2026. Syntax is Asm-Pro.
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
; 1) Support AHI and 14-bit CyberSound calibration files
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
	incdir	include:
	include	exec/exec_lib.i
	include	devices/ahi_lib.i
	include	devices/ahi.i
	include	hardware/intbits.i
	include libraries/expansion_lib.i
    include libraries/timer_lib.i
    include devices/timer.i
  ifnd __VASM
	incdir	p:include
  endif
    include libraries/amigus_lib.i
    include libraries/amigus.i

DEBUG        = 0          * Enable debug print to serial
FAKE_AGUS    = 0

 ifnd __VASM
 printt "*** Test mode! ***"
TESTMODE     = 1           * Build a stand-alone test executable
 else
TESTMODE     = 0
 endif


* Print to debug console, very clever.
* Param 1: string
* d0-d6:    formatting parameters, d7 is reserved
DPRINT macro
	ifne DEBUG
	jsr	desmsgDebugAndPrint
    	dc.b  \1,10,0
    	even
	endc
	endm

pushm	macro
	ifc	"\1","all"
	movem.l	d0-a6,-(sp)
	else
	movem.l	\1,-(sp)
	endc
	endm

popm	macro
	ifc	"\1","all"
	movem.l	(sp)+,d0-a6
	else
	movem.l	(sp)+,\1
	endc
	endm

push	macro
	move.l	\1,-(sp)
	endm

pop	macro
	move.l	(sp)+,\1
	endm

_MC68020 macro
    ifd __VASM
       MC68020
    endif
    endm

_MC68000 macro
    ifd __VASM
       MC68000
    endif
    endm

    _MC68000    ; start with this

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

 ifne TESTMODE

testMain:
    DPRINT  "start test"

    lea     .module,a0           * module data
    lea     .songOver,a1         * ptr to song end indicator
    moveq   #1,d0                * AHI on
    move.l  #24000,d1            * AHI mixing rate
    move.l  #$0002000a,d2        * AHI mode: 8 bit stereo
    move.l  #.moduleE-.module,d3 * module len
    jsr     _init
    DPRINT  "_init=%ld"
    tst.l   d0
    bne     .error

    moveq   #64,d0
    jsr	    _setVolume
    
.loop
    move.l  GraphicsBase,a6
    jsr     _LVOWaitTOF(a6)	
    btst    #6,$bfe001
    bne     .loop
 
    jsr     _end
.error
    rts

.songOver   dc.w    0
;.module  incbin     "sys:music/Mods/imploder.xm"
.module  incbin     "sys:music/Mods/7181-InternationalKarate.xm"
.moduleE

 endif ; TESTMODE

;------------------------------------------------------------------------------
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
*   a0 = module address
*   a1 = song end trigger
*   d0 = AHI on or off
*        0 = no AHI
*        1 = yes AHI
*       -1 = AmiGUS
*       -2 = AmiGUS interpolated 
*   d1 = AHI mixing rate
*   d2 = AHI mode
*   d3 = module length
* Out:
*   d0 = status
*   d1 = position mask (Paula playback)
*   d2 = channel count
*   a0 = null (patternscope support data)
*   a1 = ptr to Paula buffer position
*   a2 = address to left Paula buffer
*   a3 = address to right Paula buffer
_init:
    push    a5
    bsr     .doInit
    pop     a5
    rts
.doInit 
ier_filerr          = -17
ier_ahi             = -19
ier_amigus          = -26
ier_nomem	        = -9

    DPRINT  "*** xmaplay060 init ***" 
 ifne FAKE_AGUS
    moveq   #-1,d0 * test AGUS
    move.l  #fake_agus_base,amigus_base
 endif
 ifne DEBUG
    and.l   #$ff,d0
    ext.w   d0
    ext.l   d0
    move.l  a0,d4
    DPRINT  "ahi/agus=%ld ahirate=%ld ahimode=%08.8lx modlen=%ld mod=%lx"
 endif
    move.b  d0,AHI
    move.w  d1,AHIMixingFreq
    move.l  d2,setmode
    move.l  a1,songOverPtr
    move.l  a0,modulePtr
    move.l  d3,moduleLen
    move.l  a0,readPtr

    move.l  a5,-(sp)
    bsr     MAIN
    move.l  (sp)+,a5
    DPRINT  "MAIN=%ld"
    * d0 = 0: ok, 1: error
    tst.l   d0
    bne    .error

    tst.b   AHI
    beq     .normal
    bmi     .agus
    
    DPRINT  "-- AHI --"
    moveq   #0,d0
    move.w  AHIMixingFreq,d0
    DPRINT  "AHIMixingFreq=%ld Hz"
    move.l  d0,setfreq
    bsr     ahiSetup
    DPRINT  "ahiSetup=%ld"
    tst.l   d0
    beq     .ahiError

    * Start playback
    bsr     ahi_cont

    * Set initial tempo
    moveq   #-1,d0
    bsr     ahi_tempo
    bra     .normal


.agus
    DPRINT  "-- AGUS --"
 ifne FAKE_AGUS
    DPRINT  "Fake mode!"
    bsr     loadSamplesAGUS
	move.w	Speed(pc),d0			; d0 = tempo (BPM)
	bsr		amigus_tempo			; Set initial tempo
    st      setpause    ; play
    moveq   #0,d7
.floop  
    move    $dff006,$dff180
    push    d7
	bsr 	MainPlayer
	bsr 	Mix_UpdateChannelVolPanFrq_AGUS
    pop     d7
    addq    #1,d7
    cmp     #1000,d7
    bne     .floop
    bra     .normal
 else
    bsr     amigus_init
    DPRINT  "amigus_init=%ld"
    tst.l   d0
    bne     .agusError
 endif

.normal
    * Return access to mixer buffers when Paula mixer engaged
    move.l  PaulaPosMask(pc),d1
    lea     PaulaPos(pc),a1
    move.l  PaulaCh1Buf(pc),a2
    move.l  PaulaCh2Buf(pc),a3
    sub.l   a0,a0
    lea     InstrNames,a4

    moveq   #0,d2
    move    hAntChn,d2
    moveq   #0,d0   * null = ok
    DPRINT  "_init ok=%ld mask=%lx channels=%ld"
    rts
.error
    move.l  lastMessagePtr(pc),a0
    moveq   #ier_filerr,d0
    rts

.agusError
    moveq   #ier_amigus,d0
    rts
.ahiError
    moveq   #ier_ahi,d0
    rts

_end:
    tst.b   AHI
    bmi     .agus
    bne     .ahi
.1
    DPRINT  "normal end"
    bsr     StopTask
    bsr     cleanUp
    rts
.ahi
    bsr     ahi_stop
    bsr     ahi_end
    bra     .1
.agus
    bsr     amigus_stop
    bsr     amigus_end
    bra     .1


* out:
*   d0 = current position
*   d1 = max position
_getPosLen:
    move    SongPos(pc),d0
    move    hLen,d1
    rts

* in: 
*   d0 = volume
_setVolume:
    move    d0,ahi_mastervol
    tst.b   AHI
    bmi     amigus_setmastervol
    bne     ahi_setmastervol

    bra     SetMixingVolume

_forward:
    bra     NextPattern

_backward:
    bra     PrevPattern

_stop:
 ifne DEBUG
    push    d0
    move.b  AHI,d0
    ext.w   d0
    ext.l   d0
    DPRINT  "_stop mode=%ld"
    pop     d0
 endif
    tst.b   AHI
    bmi     amigus_stop
    bne     ahi_stop
   
    bsr    StopTask
    
	lea	    $dff000,a0
	move.w	#$000f,$96(a0)	; stop all audio DMAs
	clr.w	$a8(a0)		; clear voice volumes
	clr.w	$b8(a0)
	clr.w	$c8(a0)
	clr.w	$d8(a0)	
    rts

_cont:
    tst.b   AHI
    bmi     amigus_cont
    bne     ahi_cont
    
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
moduleLen       dc.l    0
modulePtr       dc.l    0
readPtr         dc.l    0

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

 ifne DEBUG
desmsgDebugAndPrint:
	* sp contains the return address, which is
	* the string to print
	movem.l	d0-d7/a0-a3/a6,-(sp)
	* get string
	move.l	4*(8+4+1)(sp),a0
	* find end of string
	move.l	a0,a1
.e	tst.b	(a1)+
	bne.b	.e
	move.l	a1,d7
	btst	#0,d7
	beq.b	.even
	addq.l	#1,d7
.even
	* overwrite return address 
	* for RTS to be just after the string
	move.l	d7,4*(8+4+1)(sp)

	lea	debugDesBuf(pc),a3
	move.l	sp,a1	
    lea     .putCharSerial(pc),a2
	move.l	4.w,a6
	jsr     _LVORawDoFmt(a6)
	movem.l	(sp)+,d0-d7/a0-a3/a6
	rts	* teleport!
.putc	
	move.b	d0,(a3)+	
	rts
.putCharSerial
    move.l  4.w,a6
    jmp     -516(a6)
debugDesBuf ds.b    64
 endif

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; AHI 
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

ahiSetup:
    DPRINT  "ahiSetup"
    move    hAntChn,d0
    move    d0,setchannels

    bsr     calcSampleCount
    addq    #1,d5
    move    d5,setsounds

	OPENAHI	1
	move.l	d0,ahibase
	beq     .error
	move.l	d0,a6

 ifne DEBUG
    move.l  setfreq,d0
    move.l  setmode,d1
    clr.l   d2
    move.w  setchannels,d2
    clr.l   d3
    move.w  setsounds,d3
    DPRINT  "freq=%ld mode=%08.8lx ch=%ld snd=%lx"
 endif
 
	lea	  ahi_tags(pc),a1
	jsr	_LVOAHI_AllocAudioA(a6)
	move.l	d0,ahi_ctrl
	beq	    .error
    bsr     loadSamples
    beq     .error

    move.l  ahibase(pc),a6
	move.l	setmode(pc),d0
	lea	    .getattr_tags(pc),a1
	jsr	    _LVOAHI_GetAudioAttrsA(a6)

 ifne DEBUG
    DPRINT  "mode attrs:"
    move.l  attr_stereo,d0
    DPRINT  "stereo=%ld"
    move.l  attr_panning,d0
    DPRINT  "panning=%ld"
    move.l  attr_maxchannels,d0
    DPRINT  "maxchannels=%ld"
    move.l  attr_pingpong,d0
    DPRINT  "pingpong=%ld"
 endif

    moveq   #1,d0
    rts

.error
    moveq   #0,d0
    rts


.getattr_tags
	dc.l	AHIDB_Stereo,attr_stereo
	dc.l	AHIDB_Panning,attr_panning
	dc.l	AHIDB_MaxChannels,attr_maxchannels
	dc.l	AHIDB_PingPong,attr_pingpong
	dc.l	TAG_END

attr_stereo		    dc.l	0
attr_panning		dc.l	0
attr_pingpong		dc.l	0
attr_maxchannels	dc.l	0



calcSampleCount:
    moveq   #128-1,d7
    lea     Instr,a4
    moveq   #0,d5
.instrs
    move.l  (a4)+,d0
    beq     .next
    move.l  d0,a3
    move.b  s16Bit(a3),d0   

    move    iAntSamp(a3),d6
    beq     .next
    subq    #1,d6
    lea	    iSamp(a3),a2		; a2 = sample struct

.samples
    move.l  sPek(a2),d0
    beq     .nextS
    move.l  d0,a0
    move.l  sLen(a2),d0
    beq     .nextS
    addq    #1,d5
.nextS
    lea     SMP_SIZE(a2),a2
    dbf     d6,.samples
.next
    dbf     d7,.instrs
    rts

* Load each instrument sample to AHI
loadSamples:
    moveq   #128-1,d7
    lea     Instr,a4
    moveq   #0,d5               * AHI sound number
.instrs
    move.l  (a4)+,d0
    beq     .next
    move.l  d0,a3
    move    iAntSamp(a3),d6
    beq     .next
    subq    #1,d6
    lea	    iSamp(a3),a2		; a2 = sample struct

.samples
    move.l  sPek(a2),d0
    beq     .nextS
    move.l  d0,a0
    move.l  sOrigLen(a2),d0    
    beq     .nextS

    ; Make AHISampleInfo
    lea     -12(sp),sp
    move.l  sp,a0
    move.l  sPek(a2),ahisi_Address(a0)
    move.l  #AHIST_M8S,ahisi_Type(a0)
    tst.b   s16Bit(a2)
    beq     .1
    move.l  #AHIST_M16S,ahisi_Type(a0)
    lsl.l   #1,d0                   * number of samples
.1  
    move.w  d5,sAHISound(a2)        * Store AHI sound number to the Sample struct
    move.l  d0,ahisi_Length(a0)     * a0 = info
    move.l  d5,d0                   * d0 = sound number
    moveq   #AHIST_SAMPLE,d1        * d1 = type
    push    a2
    move.l  ahi_ctrl(pc),a2         * a2 = control
    jsr     _LVOAHI_LoadSound(a6)
    pop     a2
 ifne DEBUG
    move.l  d5,d1
    move.l  ahisi_Address(sp),d2
    move.l  ahisi_Length(sp),d3
    move.l  ahisi_Type(sp),d4
    pushm   d5/d6
    moveq   #0,d5
    move.b  sLoopType(a2),d5
    moveq   #0,d6
    move.b  sFine(a2),d6
    DPRINT  "LoadSound=%lx num=%lx addr=%lx len=%lx type=%lx loop=%ld fine=%ld"
    popm    d5/d6
 endif
    lea     12(sp),sp
    tst.l   d0
    bne     .err

    addq    #1,d5                  * Next AHI sound number
.nextS
    lea     SMP_SIZE(a2),a2
    dbf     d6,.samples
.next
    dbf     d7,.instrs
    moveq   #1,d0
    rts
.err
    moveq   #0,d0
    rts




; ; AHISampleInfo
;        STRUCTURE AHISampleInfo,0
;        ULONG   ahisi_Type                      ; Format of samples
;        APTR    ahisi_Address                   ; Address to array of samples
;        ULONG   ahisi_Length                    ; Number of samples in array
;        LABEL   AHISampleInfo_SIZEOF


ahi_end:
    DPRINT  "ahi end"
	move.l	ahibase(pc),d0
	beq.b	.1
	move.l	d0,a6

    ; for safety stop playback first, SB128 reportedly crashes otherwise
    clr.b   setpause
    bsr     ahi_stopcont

	move.l	ahi_ctrl(pc),a2
	jsr	_LVOAHI_FreeAudio(a6)
	CLOSEAHI
    clr.l   ahi_ctrl
	clr.l	ahibase
.1  
    rts


ahi_stop:
    DPRINT  "ahi stop"
    clr.b   setpause
    bsr     ahi_stopChannels
    bra     ahi_stopcont

ahi_cont:
    DPRINT  "ahi cont"
    st      setpause
    bsr     ahi_stopcont
    bra     ahi_restoreChannels
    
ahi_stopcont:
	pushm	d1/a0-a2/a6

	lea	ahi_ctrltags(pc),a1
	move.l	ahi_ctrl(pc),a2
	move.l	ahibase(pc),a6
	jsr	_LVOAHI_ControlAudioA(a6)
    DPRINT  "AHI_ControlAudioA=%ld"

	popm	d1/a0-a2/a6
	rts

ahi_stopChannels:
    pushm   all
	move	hAntChn,d7
	subq	#1,d7
	moveq	#0,d6
.chl
    move.l  d6,d0
    moveq   #0,d1   * NULL freq
	moveq	#AHISF_IMM,d2
	move.l	ahi_ctrl(pc),a2
	move.l	ahibase(pc),a6
	jsr	_LVOAHI_SetFreq(a6)
	addq	#1,d6
	dbf	d7,.chl
    popm     all
    rts

ahi_restoreChannels:
    pushm   all

    moveq   #0,d7
    lea     freqForChannel,a4
.chl
    move.l  d7,d0
    move.l  (a4)+,d1
	moveq	#AHISF_IMM,d2
	move.l	ahi_ctrl(pc),a2
	move.l	ahibase(pc),a6
	jsr     _LVOAHI_SetFreq(a6)

    addq    #1,d7
	cmp.w	hAntChn,d7
	bne     .chl

    popm     all
    rts


ahi_playmusic:
    tst.b  setpause
    bne.b   .1
    rts
.1
	pushm	d2-d7/a2-a6
; ifne DEBUG
;    move    $dff006,$dff180
; endif
	bsr 	MainPlayer
	bsr 	Mix_UpdateChannelVolPanFrq_AHI

	popm	d2-d7/a2-a6
	rts


ahi_setmastervol:
	pushm	d0/d1/a0-a2/a6
	moveq	#0,d0
	move	setchannels(pc),d0
	tst.l	attr_stereo
	beq.b	.mono
	tst.l	attr_panning		* sama jos panning
	bne.b	.mono
	lsr.l	#1,d0
.mono
	* d0 = max master vol
	subq	#1,d0
    mulu    ahi_mastervol(pc),d0    * make 16.16 FP
    lsl.l   #8,d0    
    lsl.l   #2,d0    

	move.l	#AHIET_MASTERVOLUME,.effect+ahie_Effect
	move.l	d0,.effect+ahiemv_Volume
    DPRINT  "ahi_setmastervol=%08.8lx"

	lea	    .effect(pc),a0
	move.l	ahi_ctrl(pc),a2
	move.l	ahibase(pc),a6
	jsr	    _LVOAHI_SetEffect(a6)

	popm	d0/d1/a0-a2/a6
	rts

.effect
	ds.b	AHIEffMasterVolume_SIZEOF



;in:
* a0	struct Hook *
* a1	struct AHISoundMessage *
* a2	struct AHIAudioCtrl *
ahi_soundfunc:
	movem.l d2-d4/a6,-(sp)

    moveq   #0,d0
	move	ahism_Channel(a1),d0

    lea     sampleForChannel(pc),a6
    move    d0,d2
    lsl     #2,d2
    move.l  (a6,d2.w),d2
    bne     .ok
    DPRINT  "no sample for channel=%ld"
    bra     .silent
.ok
    move.l  d2,a6
    move.l  sRepS(a6),d2        * Repeat start offset
    move.l  sOrigRepL(a6),d3    * Repeat length
  
	tst.b	s16Bit(a6)          * Adjust if 16-bit sample
	beq.b	.8b
    lsr.l   #1,d2
    lsr.l   #1,d3
.8b
 
    cmp.l   #2,d3               * Repeat length sanity check
    bls     .silent
  
    tst.b   sLoopType(a6)       * Test for no loop
    beq     .silent

    cmp.b   #2,sLoopType(a6)    * Test for ping pong loop
    bne     .forward            * else do forward loop

    tst.l   attr_pingpong      * Is ping pong supported?
    beq     .forward
        
    * Check the direction the playback should be going
    not.b   sAHILoopDir(a6)
    beq     .forward
    ;DPRINT  "BIDI fwd ch=%ld sLen=%lx RepS=%lx sRepL=%lx"
    ;BIDI ch=7 sLen=DA4C RepS=0 sRepL=DA4C
    ;DPRINT  "BIDI rev ch=%ld sLen=%lx RepS=%lx sRepL=%lx"

    * Go backward
    * Start offset at d2 should point to loop end
    add.l   d3,d2
    * Make length negative to indicate reverse playback
    neg.l   d3

.forward
    moveq   #0,d1
	move.w	sAHISound(a6),d1    ; sample bank
    bra     .sound

.silent
	moveq	#AHI_NOSOUND,d1
    moveq   #0,d2
    moveq   #0,d3
.sound
	moveq	#0,d4				; NOTE: AHISF_IMM *NOT* SET!!
	;move.l	ahi_ctrl(pc),a2 * already in a2
	move.l	ahibase(pc),a6
;    DPRINT  "SetSound ch=%02.2lx sound=%02.2lx offs=%04.4lx len=%04.4lx"
	; d0 = channel
	; d1 = sound ID
	; d2 = offset
	; d3 = length
	; d4 = flags (AHISF_IMM)
	jsr	_LVOAHI_SetSound(a6)
.exit
	movem.l (sp)+,d2-d4/a6
	rts


;---- Tempo ----

* In:
*   d0 = tempo value, -1 to re-set previous value
ahi_tempo:
	pushm   all
    DPRINT  "ahi_tempo=%ld"
    ext.l   d0
    bmi     .prev

;	lsl.w	#1,d0
;	divu	#5,d0

    * Use 24.8 FP for accuracy
    add.w   d0,d0
	lsl.l	#8,d0
    divu    #5,d0
    ext.l   d0
    lsl.l   #8,d0

	lea	    .tags(pc),a1
	move.l	d0,4(a1)
    move.l  d0,setplayerfreq
.prev
	move.l	ahi_ctrl(pc),d7
    beq     .1
    move.l  d7,a2
	move.l	ahibase(pc),a6
	jsr	_LVOAHI_ControlAudioA(a6)
.1
    popm    all
	RTS

.tags
	dc.l	AHIA_PlayerFreq
.freq	dc.l	50<<16
	dc.l	TAG_DONE


PlayerFunc:
	blk.b	MLN_SIZE
	dc.l	ahi_playmusic
	dc.l	0
	dc.l	0

SoundFunc:
	blk.b	MLN_SIZE
	dc.l	ahi_soundfunc
	dc.l	0
	dc.l	0

ahi_sound0:	    dc.l	AHIST_M8S
setsampletype 	=	*-4
setmodule 	    dc.l	0
setmodulelen	dc.l	0

ahi_effect:     ds.b	AHIEffMasterVolume_SIZEOF

ahi_ctrltags:	dc.l	AHIC_Play,1
setpause 	    =	*-1
		        dc.l	TAG_DONE

ahi_tags:
	dc.l	AHIA_MixFreq,22000
setfreq 	=	*-4
	dc.l	AHIA_AudioID,$0002000a	* 8 bit stereo
setmode 	= 	*-4
	dc.l	AHIA_Channels,4
setchannels 	= 	*-2
	dc.l	AHIA_Sounds,1
setsounds = *-2
	dc.l	AHIA_SoundFunc,SoundFunc
	dc.l	AHIA_PlayerFunc,PlayerFunc
	dc.l	AHIA_PlayerFreq,50<<16
setplayerfreq = *-4
	dc.l	AHIA_MinPlayerFreq,(32*2/5)<<16
	dc.l	AHIA_MaxPlayerFreq,(255*2/5)<<16
	dc.l	TAG_DONE


;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; AmiGUS
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

amigus_init:
    DPRINT  "--- amigus_init ---"
	move.l	4.w,a6					
	lea   	LibName(pc),a1	
	moveq   #0,d0
	jsr     _LVOOpenLibrary(a6)		
    DPRINT  "OpenLibrary=%lx"
    move.l  d0,amigus_lib
    beq     .ag_init_error
    ; ---------------------------------
	move.l	d0,a6					; Let's find AmiGUS card
    sub.l   a0,a0
    jsr     _LVOAmiGUS_FindCard(a6)
    DPRINT  "AmiGUS_FindCard=%lx"
    move.l  d0,amigus_card
    beq     .ag_init_error
    ; ---------------------------------
    move.l  d0,a0
    cmp.w   #AmiGUS_mini,agus_TypeId(a0)
    seq     amigus_hasleds
 ifne DEBUG
    move.l  agus_TypeName(a0),d0
    moveq   #0,d1
    move.w  agus_TypeId(a0),d1
    DPRINT  "TypeName=%s TypeId=%lx"
 endif
    move.l  #AMIGUS_FLAG_WAVETABLE,d0
    move.l  #"K-P!",d1
    jsr     _LVOAmiGUS_ReserveCard(a6)
    DPRINT  "AmiGUS_ReserveCard=%lx"
    cmp.l   #AmiGUS_NoError,d0
    seq     amigus_reserve
    bne     .ag_init_error
    ; ---------------------------------
    move.l  amigus_card,a0
    move.l  #AMIGUS_FLAG_WAVETABLE,d0
    move.l  #"K-P!",d1
    move.l  #AmiGUS_Int,d2  
    moveq   #0,d3           * data
    jsr     _LVOAmiGUS_InstallInterrupt(a6) 
    DPRINT  "AmiGUS_InstallInterrupt=%lx"
    cmp.l   #AmiGUS_NoError,d0
    seq     amigus_hasinterrupt
    bne     .ag_init_error
    ; ---------------------------------
    move.l  amigus_card,a0
    move.l  agus_WavetableBase(a0),amigus_base
    move.l  agus_PcmBase(a0),a1
    move.l  a1,amigus_pcm
    tst.w   amigus_hasleds
    beq     .nl
    move.w  $d4(a1),amigus_old_ledctrl       * word register
.nl
    ; ---------------------------------
	bsr     loadSamplesAGUS

    move.l	amigus_base(pc),a6		; a6 = AmiGUS register base
	bsr		amigus_voice_reset		; Initialize all AmiGUS voices
	
	move.w	Speed(pc),d0			; d0 = tempo (BPM)
	bsr		amigus_tempo			; Set initial tempo
	
	st   	setpause                ; play
    
	move.w	#$c000,HAGEN_INTE0(a6)	; Enable interrupt		
	
    DPRINT  "amigus_init SUCCESS"
	moveq	#0,d0       * OK
	rts

.ag_init_error
    bsr     amigus_uninit
    DPRINT  "amigus_init FAILURE"
	moveq	#ier_amigus,d0              ; Could not find or allocate AmiGUS
	rts



amigus_uninit:
    bsr     amigus_freeinterrupt
    bsr     amigus_freecard
    bsr     amigus_closelib
    clr.l   amigus_base
    rts

amigus_closelib:
    move.l  amigus_lib,d0
    beq     .x
    clr.l   amigus_lib
    move.l  d0,a1
    move.l  4.w,a6
    jsr     _LVOCloseLibrary(a6)
.x  rts

amigus_freecard:
    tst.w   amigus_reserve
    beq     .x
    clr.w   amigus_reserve

    move.l  amigus_card,a0
    move.l  #AMIGUS_FLAG_WAVETABLE,d0
    move.l  #"K-P!",d1
    move.l  amigus_lib,a6
    jsr     _LVOAmiGUS_FreeCard(a6)
.x
    rts

amigus_freeinterrupt:
    tst.w   amigus_hasinterrupt
    beq     .x
    clr.w   amigus_hasinterrupt

    move.l  amigus_card,a0
    move.l  #AMIGUS_FLAG_WAVETABLE,d0
    move.l  #"K-P!",d1
    move.l  amigus_lib,a6
    jsr     _LVOAmiGUS_RemoveInterrupt(a6)
.x
    rts


amigus_restoreLeds:
    tst.w   amigus_hasleds
    beq     .1
	move.l	amigus_pcm,a1
    move.w	amigus_old_ledctrl,$d4(a1)    
.1  rts

amigus_runleds:
    tst.w   amigus_hasleds
    bne     .hasLeds
    rts
.hasLeds
    tst.b   setpause
    bne     amigus_restoreLeds
    ; ---------------------------------
    * Paused, do effect
	move	.dir,d0
	move	.pos,d1
	add	d0,d1
	bpl	.p1
	neg	d0
	moveq	#0,d1
	bra	.ok
.p1
	cmp	#32,d1
	blo	.ok
	moveq	#31,d1
	neg	d0
.ok
    move    d0,.dir
	move	d1,.pos
    ; ---------------------------------
	move	.pos,d0
	lsr	#2,d0
	lea	.leds,a0
	add	d0,a0
	move.b	#$7f,(a0)
    ; ---------------------------------
	moveq	#28,d3
	moveq	#0,d2
	moveq	#8-1,d0
	lea	    .leds,a0
.3	move.b	(a0)+,d1
	lsr.b	#3,d1
	and.l	#$f,d1
	rol.l	d3,d1
	or.l	d1,d2
	subq	#4,d3
	dbf	d0,.3
    ; ---------------------------------
	move.l	amigus_pcm,a1
	move.w	#1,$d4(a1)      * manual led control
	move.l	d2,$d0(a1)      * write led values
    ; ---------------------------------
	lea	    .leds,a0
	moveq	#8-1,d0
.1 	subq.b	#6,(a0)
	tst.b	(a0)+
	bpl	.2
	clr.b	-1(a0)
.2	dbf	d0,.1
	rts

.dir	dc.w	1
.pos	ds.w	1
.leds	ds.b	8

amigus_base		     dc.l	 0 
amigus_pcm		     dc.l	 0 
amigus_lib           dc.l    0
amigus_card          dc.l    0
amigus_reserve       dc.w    0
amigus_hasinterrupt  dc.w    0
amigus_hasleds       dc.w    0
amigus_old_ledctrl   dc.w    0

LibName         dc.b    "amigus.library",0
 even

;=============================================================
amigus_end:	
    DPRINT  "amigus_end"
	move.l	amigus_base(pc),a6

	move.w	#$0000,HAGEN_TIMER_CTRL(a6)	; Disable Timer
	move.w	#$4000,HAGEN_INTE0(a6)		; Disable Timer interrupt
	move.w	#$4000,HAGEN_INTC0(a6)		; Clear Timer interrupt
	
    bsr     amigus_restoreLeds
	bsr		amigus_voice_reset
    bsr     amigus_uninit
	rts
;=============================================================

amigus_voice_reset:
	move.l	amigus_base(pc),a6
	moveq	#0,d0
	moveq	#0,d1
.ag_clear_loop
	move.w	d0,HAGEN_VOICE_BNK(a6)		; Set voice bank
	lea 	HAGEN_VOICE_CTRL(a6),a0		; Clear all voice registers
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	addq	#1,d0
	cmp.w	#32,d0
	bne	.ag_clear_loop
	rts

;==============================================================
amigus_stop:
    DPRINT  "amigus_stop"
	clr.b   setpause
	move.l	amigus_base(pc),a6
	move.w	#$4000,HAGEN_INTE0(a6)	; Disable interrupt
	bsr		.ag_mutechannels	
	rts
;---	
.ag_mutechannels
	moveq	#0,d0
	moveq	#0,d1
.ag_mute_loop
	move.w	d0,HAGEN_VOICE_BNK(a6)	; Set channel number
	move.l	d1,HAGEN_VOICE_VOLUMEL(a6)	; Also sets right volume (longword access)
	addq	#1,d0
	cmp.w	#32,d0
	bne	.ag_mute_loop
	rts	
;==============================================================
amigus_cont:
    DPRINT  "amigus_cont"
	st      setpause
	move.l	amigus_base(pc),a6
	bsr     .ag_restorechannels
	move.w	#$c000,HAGEN_INTE0(a6)	; Enable interrupt
	rts
;---	
.ag_restorechannels
	lea	    agusVolForChannel,a0
	moveq	#0,d7
.ag_restore_loop
	move.w	d7,HAGEN_VOICE_BNK(a6)	; Set channel number	
    move.w  (a0)+,HAGEN_VOICE_VOLUMEL(a6)
    move.w  (a0)+,HAGEN_VOICE_VOLUMER(a6)
    addq    #1,d7
    cmp     hAntChn,d7
    bne     .ag_restore_loop
	rts	
;==============================================================
amigus_tempo:
	movem.l d0-d7/a0-a6,-(sp)
	and.w	#$ff,d0
	lsl.w	#1,d0
	moveq	#0,d1
	move.w	d0,d1
	
	move.l	amigus_base(pc),d7
    beq     .x
    move.l  d7,a6
	move.w	#$0000,HAGEN_TIMER_CTRL(a6)	
	move.l 	#5*HAGEN_TIMER_TIMEBASE,d0
	bsr		divu_32
    ;divu.l  d1,d0
	move.l	d0,HAGEN_TIMER_RELOADH(a6)	; Set timer interrupt speed for playback
	move.w	#$8000,HAGEN_TIMER_CTRL(a6)
.x
	movem.l (sp)+,d0-d7/a0-a6	; Restore registers
	rts
;=============================================================
amigus_setmastervol:
    move    ahi_mastervol(pc),d1
	cmp.w	#64,d1				; Full PAULA volume?
	bne		.ag_novolovl		; No, then just shift it
	move.w	#$ffff,d1			; Yes, set full AmiGUS master volume
	bra		.ag_setmastervol
.ag_novolovl	
	lsl.l	#5,d1				; Convert volume value
	lsl.l	#5,d1	
.ag_setmastervol	
	move.l	amigus_base(pc),a6	; a6 = AmiGUS register base
	move.w	d1,HAGEN_GLOBAL_VOLUMEL(a6)	; Set AmiGUS master volume
	move.w	d1,HAGEN_GLOBAL_VOLUMER(a6)	
    rts

;======================================


AmiGUS_Int:
	movem.l d1-d7/a0-a6,-(sp)	; Save registers

	move.l	amigus_base(pc),a6

	move.w	HAGEN_INTC0(a6),d0			; read interrupt status
	and.w   #$4000,d0					; did AmiGUS Timer IRQ occur?
	beq.b	.noTimerInt					; if not, then there is nothing to do here	
	
	move.w	#$4000,HAGEN_INTC0(a6)	; Clear interrupt

    tst.b  setpause
    beq.b   .1
; ifne DEBUG
;    move    $dff006,$dff180
; endif
	bsr 	MainPlayer
	bsr 	Mix_UpdateChannelVolPanFrq_AGUS
.1
    bsr     amigus_runleds
.noTimerInt	
	movem.l (sp)+,d1-d7/a0-a6	; Restore registers
	moveq	#0,d0
	rts
	
;======================================


PUSH8M macro
    rol.l   #8,d3       * Push 8 bits
    move.b  \2,d3
    subq    #1,d4       * 1 byte
    bne.b   .\1
    move.l  d3,(a1)     * output 32 bits
    addq.l  #4,d5       * advance agus offset
    moveq   #0,d3       * clear buffer
    moveq   #4,d4       * do 4 bytes again
.\1:
    endm

PUSH16M macro           
    swap    d3          * Push 16 bits
    move.w  \2,d3
    subq    #2,d4       * 1 word
    bne.b   .\1
    move.l  d3,(a1)     * output 32 bits
    addq.l  #4,d5       * advance agus offset
    moveq   #0,d3       * clear buffer
    moveq   #4,d4       * do 4 bytes again
.\1:
    endm

* Load each instrument sample to AGUS
loadSamplesAGUS:
    DPRINT  "loadSamplesAGUS"
    
    moveq   #128-1,d7
    lea     Instr,a4
    moveq   #0,d5               * AGUS sample address

	move.l	amigus_base(pc),a1		
	move.l	d5,HAGEN_WADDRH(a1)   * destination address
    moveq   #4,d4               * push counter
    moveq   #0,d3               * push buffer
.instrs
    move.l  (a4)+,d0
    beq     .next
    move.l  d0,a3 
    move    iAntSamp(a3),d6
    beq     .next
    subq    #1,d6
    lea	    iSamp(a3),a2		; a2 = sample struct

.samples
    move.l  sPek(a2),d0
    beq     .nextS
    move.l  d0,a0
    move.l  sOrigLen(a2),d0    
    beq     .nextS
    move.l  d5,sAGUSOffset(a2)   * Store AGUS address for later

 ifne DEBUG
    push    d1
    move.l  d5,d1
    DPRINT  "Sample len=%lx - AGUS offset=%lx"
    pop     d1
 endif

    ; ---------------------------------    
    ; Copy d0 bytes from a0 to AGUS
	move.l	amigus_base(pc),a1		
    lea     HAGEN_WDATAH(a1),a1   * destination address
 REM
    ; ---------------------------------    
    ; Copy d0 bytes from a0 to AGUS - old non-bidi
    moveq   #4,d1
    bra.b   .s            * handle very short ones
.copy
    move.l  (a0)+,(a1)
    add.l   d1,d5
    sub.l   d1,d0
.s  cmp.l   d1,d0
    bhs.b   .copy

    tst.l   d0
    beq     .done
    clr.l   -(sp)
    move.l  sp,a5
.rest
    move.b  (a0)+,(a5)+
    subq    #1,d0
    bne     .rest
    move.l  (sp)+,(a1)
    addq.l  #4,d5
.done
 EREM
; REM ;;;;;; NEW
    ; ---------------------------------    
    ; Copy d0 bytes from a0 to AGUS - with BIDI support
    ; Check for bidi loop
    cmp.l   #4,sOrigRepL(a2)
    bls     .noLoop
    cmp.b   #2,sLoopType(a2)
    beq     .bidi
.noLoop
    tst.b   s16Bit(a2)
    bne     .loop16
.loop8
    ;move.b  (a0)+,d1
    ;bsr     .push8
    PUSH8M  1,(a0)+
    subq.l  #1,d0
    bne.b   .loop8
    bsr     .flush
    bra     .continue
.loop16
;    move.w  (a0)+,d1
;    bsr     .push16
    PUSH16M  2,(a0)+
    subq.l  #2,d0
    bpl.b   .loop16
    bsr     .flush
    bra     .continue
    ; ---------------------------------    
.bidi
    ; Calc bytes to loop end
    move.l  sRepS(a2),d0                ; Repeat start offset
    add.l   sOrigRepL(a2),d0            ; Repeat length

    tst.b   s16Bit(a2)
    bne     .bidiloop16a
.bidiloop8a
    ;move.b  (a0)+,d1
    ;bsr     .push8
    PUSH8M  3,(a0)+
    subq.l  #1,d0
    bne.b    .bidiloop8a
    ; Append replen of data reversed
    move.l   sOrigRepL(a2),d0            ; Repeat length
.bidiloop8b
    ;move.b  -(a0),d1
    ;bsr     .push8
    PUSH8M  4,-(a0)
    subq.l  #1,d0
    bne.b   .bidiloop8b
    bsr     .flush
    bra     .continue

.bidiloop16a
;    move.w  (a0)+,d1
;    bsr     .push16
    PUSH16M  5,(a0)+
    subq.l  #2,d0
    bpl     .bidiloop16a
    ; Append replen of data reversed
    move.l   sOrigRepL(a2),d0            ; Repeat length
.bidiloop16b
;    move.w  -(a0),d1
;    bsr     .push16
    PUSH16M  6,-(a0)
    subq.l  #2,d0
    bne.b   .bidiloop16b
    bsr     .flush

.continue
; EREM ;;;;;;; NEW


    ; ---------------------------------    
    ; Free it
    move.l  sPek(a2),a1
    move.l	sLen(a2),d0
	beq.b	.nextS			; (length is zero, don't free)	
    bmi.b   .nextS
    neg.l   sLen(a2)        ; neg means freed
	addq.l	#2,d0			; fix-sample for linear interpolation
	bsr.w	FreeMem			; d0.l = len, a1 = smp ptr    
    ; ---------------------------------    
.nextS
    lea     SMP_SIZE(a2),a2
    dbf     d6,.samples
.next
    dbf     d7,.instrs
    moveq   #1,d0
    rts
.err
    moveq   #0,d0
    rts


* Push byte to AGUS
*   d1 = byte
*   a1 = HAGEN_WDATAH
*   d3 = buffer
*   d4 = counter
.push8
    rol.l   #8,d3
    move.b  d1,d3
    subq    #1,d4
    beq.b   .flush_
    rts
* Push word to AGUS
*   d1 = word
.push16
    swap    d3
    move.w  d1,d3
    subq    #2,d4
    beq.b   .flush_
    rts
* shift remaining data to the top
.flush
    lsl     #3,d4
    rol.l   d4,d3
.flush_
    move.l  d3,(a1)     * output 32 bits
    addq.l  #4,d5       * advance agus offset
    moveq   #0,d3       * clear buffer
    moveq   #4,d4       * do 4 bytes again
    rts


;---------------------------------------------------------------------------
;---------------------------------------------------------------------------


initSysTime:
    move.l  WorkerTask,a1    
    lea     sysTimerIORequest,a2
    lea     sysTimerPort,a3

* Utility to set up a timer
* In:
*   a1 = current task
*   a2 = io structure
*   a3 = port structure
* Out:
*   d0 = OpenDevice return code
.initTimer:
    ; ---------------------------------
    ; Create port
    move.l  a1,MP_SIGTASK(a3)
    move.b  #NT_MSGPORT,LN_TYPE(a3)
    clr.l   LN_NAME(a3)
    move.b  #PA_SIGNAL,MP_FLAGS(a3)
    lea     MP_MSGLIST(a3),a0
    NEWLIST a0
    moveq   #-1,d0
    move.l  4.w,a6
    jsr     _LVOAllocSignal(a6)       * error ignored
    move.b  d0,MP_SIGBIT(a3)
    ; ---------------------------------
    ; Create IO
    move.l  a3,MN_REPLYPORT(a2)
    move.b  #NT_MESSAGE,LN_TYPE(a2)
    move    #IOTV_SIZE,MN_LENGTH(a2)
    ; ---------------------------------
    ; timer.device
    lea     timerDeviceName,a0
    move.l  a2,a1
    moveq   #UNIT_VBLANK,d0
    moveq   #0,d1
    jsr     _LVOOpenDevice(a6)      * returns d0=non-zero on error
    rts

deinitSysTime:
    lea     sysTimerIORequest,a1
    move.l  4.w,a6
    jsr     _LVOCloseDevice(a6)
    move.b  sysTimerPort+MP_SIGBIT,d0
    jsr     _LVOFreeSignal(a6)
    rts

sysWait:
    lea     sysTimerIORequest,a1  
	move.w	#TR_ADDREQUEST,IO_COMMAND(a1)
	clr.l   IOTV_TIME+TV_SECS(a1)
	move.l	#20*1000,IOTV_TIME+TV_MICRO(a1)
    move.l  4.w,a6
    jmp     _LVODoIO(a6)

sysTimerPort        ds.b      MP_SIZE
sysTimerIORequest   ds.b      IOTV_SIZE
timerDeviceName     dc.b	  "timer.device",0
    even


* mulu_32 --- d0 = d0*d1
mulu_32	movem.l	d2/d3,-(sp)
	move.l	d0,d2
	move.l	d1,d3
	swap	d2
	swap	d3
	mulu	d1,d2
	mulu	d0,d3
	mulu	d1,d0
	add	d3,d2
	swap	d2
	clr	d2
	add.l	d2,d0
	movem.l	(sp)+,d2/d3
	rts	

* divu_32 --- d0 = d0/d1, d1=jakojäännös
divu_32	move.l	d3,-(a7)
	swap	d1
	tst	d1
	bne.b	lb_5f8c
	swap	d1
	move.l	d1,d3
	swap	d0
	move	d0,d3
	beq.b	lb_5f7c
	divu	d1,d3
	move	d3,d0
lb_5f7c	swap	d0
	move	d0,d3
	divu	d1,d3
	move	d3,d0
	swap	d3
	move	d3,d1
	move.l	(a7)+,d3
	rts	

lb_5f8c	swap	d1
	move	d2,-(a7)
	moveq	#16-1,d3
	move	d3,d2
	move.l	d1,d3
	move.l	d0,d1
	clr	d1
	swap	d1
	swap	d0
	clr	d0
lb_5fa0	add.l	d0,d0
	addx.l	d1,d1
	cmp.l	d1,d3
	bhi.b	lb_5fac
	sub.l	d3,d1
	addq	#1,d0
lb_5fac	dbf	d2,lb_5fa0
	move	(a7)+,d2
	move.l	(a7)+,d3
	rts	


; udivmod64 - divu.l d2,d0:d1
; by Meynaf/English Amiga Board
divu_64
	move.l d3,-(a7)
 	moveq #31,d3
.loop
	 add.l d1,d1
	 addx.l d0,d0
 	bcs.s .over
 	cmp.l d2,d0
 	bcs.s .sui
 	sub.l d2,d0
.re
 	addq.b #1,d1
.sui
 	dbf d3,.loop
 	move.l (a7)+,d3	; v=0
 	rts
.over
 	sub.l d2,d0
 	bcs.s .re
 	move.l (a7)+,d3
 	or.b #4,ccr		; v=1
 	rts

;---------------------------------------------------------------------------
; Multiply two unsigned 32 bit integers and return the 64 bit result
;
;   REGISTER USAGE
;       D4 -- scratch (restored)
;       D3 -- scratch (restored)
;       D2 -- scratch (restored)
;       D1 -- arg 1 (given), result 32:63
;       D0 -- arg 0 (given), result 0:31
;
UMult64S:
        movem.l d2-d4,-(sp)

        move.l  d1,d3
        mulu.w  d0,d3           ; 24
        move.l  d1,d2
        swap.w  d2
        swap.w  d0
        mulu.w  d0,d2           ; 13

        swap.w  d3

        move.l  d1,d4
        mulu.w  d0,d4           ; 14
        add.w   d4,d3
        clr.w   d4
        swap.w  d4
        addx.l  d4,d2

        swap.w  d0
        swap.w  d1

        move.l  d1,d4
        mulu.w  d0,d4           ; 23
        add.w   d4,d3
        clr.w   d4
        swap.w  d4
        addx.l  d4,d2

        swap.w  d3

        move.l  d2,d0
        move.l  d3,d1

        movem.l (sp)+,d2-d4
        rts



;------------------------------------------------------------------------------
;------------------------------------------------------------------------------


PAL_CIA_PERIOD		EQU 7093 ;  ~99.997Hz
NTSC_CIA_PERIOD		EQU 7158 ; ~100.001Hz

; Total sample buffer size in samples. Not the actual mix length per frame.
SMP_BUFF_SIZE		EQU 16384

LOOP_UNROLL_SIZE	EQU 1024
MIN_PERIOD		EQU 64		; Paula period, that is
MAX_PERIOD		EQU 450		; ^^^
MAX_NOTES 		EQU (12*10*16)+16
MAX_CHANNELS		EQU 32
MAX_PATH_LEN 		EQU 512		; ought to be plenty
NUM_ERROR_MSGS 		EQU 6

;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

SEEK_SET		EQU -1 ; OFFSET_BEGINNING relative to Beginning Of File 
SEEK_CUR		EQU 0  ; OFFSET_CURRENT  relative to Current file position 
MODE_OLDFILE		EQU 1005
MEMF_ANY		EQU 0
MEMF_CHIP		EQU 2
MEMF_FAST		EQU 4
MEMF_PUBLIC     EQU 1
MEMF_CLEAR		EQU 65536
MEMF_TOTAL		EQU 524288
;NT_INTERRUPT		EQU 2
;INTB_AUD0		EQU 7
;INTF_AUD0		EQU 128
;LN_NAME			EQU 10
;LN_PRI			EQU 9
;LN_TYPE			EQU 8
;NT_TASK			EQU 1
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
;_LVOForbid		EQU -132
;_LVOPermit		EQU -138
;_LVOSetIntVector	EQU -162
;_LVORemIntServer	EQU -174
;_LVOAllocMem		EQU -198
;_LVOFreeMem		EQU -210
_LVOWaitTOF		EQU -270
;_LVOAddTask		EQU -282
;_LVOFindTask		EQU -294
;_LVOSetSignal		EQU -306
;_LVOWait		EQU -318
;_LVOSignal		EQU -324
;_LVOAllocSignal		EQU -330
;_LVOFreeSignal		EQU -336
;_LVOCloseLibrary	EQU -414
;_LVOOpenDevice		EQU -444
;_LVOCloseDevice		EQU -450
;_LVODoIO		EQU -456
;_LVOOpenResource	EQU -498
;_LVOOpenLibrary		EQU -552
;_LVOCreateIORequest	EQU -654
;_LVODeleteIORequest	EQU -660
;_LVOCreateMsgPort 	EQU -666
;_LVODeleteMsgPort	EQU -672
_LVOPutStr		EQU -948
_LVODelay     EQU   -198

AttnFlags		EQU $128


swap16	MACRO
	rol.w	#8,\1
	ENDM
	
swap32	MACRO
	rol.w	#8,\1
	swap	\1
	rol.w	#8,\1
	ENDM
	
;swap16a        MACRO
;       move.w  \1,d0
;       rol.w   #8,d0
;       move.w  d0,\1
;       ENDM

	; warning: trashes d0!
swap16a	MACRO
    pea     \1
    bsr     swap16a_
    addq    #4,sp
	ENDM

;swap32a        MACRO
;       move.l  \1,d0
;       rol.w   #8,d0
;       swap    d0
;       rol.w   #8,d0
;       move.l  d0,\1
;	ENDM

	; warning: trashes d0!
swap32a	MACRO
    pea     \1
    bsr     swap32a_
    addq    #4,sp
	ENDM


swap16a_:
    movem.l d0/a0,-(sp)
    move.l  4+4+4(sp),a0
    move.b  0(a0),-(sp)
    move.b  1(a0),-(sp)
    move.b  (sp)+,d0
    move.b  d0,0(a0)
    move.b  (sp)+,d0
    move.b  d0,1(a0)
    movem.l (sp)+,d0/a0
    rts

swap32a_:
    movem.l d0/a0,-(sp)
    move.l  4+4+4(sp),a0
    move.b  0(a0),-(sp)
    move.b  1(a0),-(sp)
    move.b  2(a0),-(sp)
    move.b  3(a0),-(sp)
    move.b  (sp)+,d0
    move.b  d0,0(a0)
    move.b  (sp)+,d0
    move.b  d0,1(a0)
    move.b  (sp)+,d0
    move.b  d0,2(a0)
    move.b  (sp)+,d0
    move.b  d0,3(a0)
    movem.l (sp)+,d0/a0
    rts

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
sAHISound   EQU 36  ; W AHI sound number for this sample
sAGUSOffset EQU 36  ; L AGUS memory address for this sample                      
sAHILoopDir EQU 38  ; B AHI mode only
sPadding    EQU 39  ; B AGUS mode only
SMP_SIZE	EQU 40	; Must be a multiple of 4 for longword alignment.
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

INS_SIZE	EQU 840+16*4	; 264+(16*SMPSIZE) (must be multiple of 4)
                            ; 16*4 = add sAHISound worth of space

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
shLen		EQU 0	; L (DON'T CHANGE ORDER!) - SAMPLE LENGTH
shRepS		EQU 4	; L (DON'T CHANGE ORDER!) - SAMPLE LOOP START 
shRepL		EQU 8	; L (DON'T CHANGE ORDER!) - SAMPLE LOOP LENGTH
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
	dc.b "\\0$VER: 0.47"
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
fopen	
    ;movem.l	d1/a0/a1/a6,-(sp)
	;move.l	DosBase(pc),a6
	;jsr	_LVOOpen(a6)
    moveq   #1,d0
	;movem.l	(sp)+,d1/a0/a1/a6
	rts

	;-------------------------------------------------
	; Input:
	;   d1.l = file handle
	;-------------------------------------------------
fclose	
    ;movem.l	d0/d1/a0/a1/a6,-(sp)
	;move.l	DosBase(pc),a6
	;jsr	_LVOClose(a6)
	;movem.l	(sp)+,d0/d1/a0/a1/a6
	rts
	
	;-------------------------------------------------
	; Input:
	;   d1.l = file handle
	;   d2.l = pointer to destination buffer
	;   d3.l = bytes to read
	;
	; Output:
	;   d0.l = actual bytes read
	;-------------------------------------------------	
fread	movem.l	d1/a0/a1/a6,-(sp)
	;move.l	DosBase(pc),a6
	;jsr	_LVORead(a6)
    
    move.l  readPtr,a0
    add.l   d3,readPtr
    move.l  d2,a1
    move.l  d3,d0

    move.l  4.w,a6
    jsr     _LVOCopyMem(a6)
    move.l  d3,d0

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
	;move.l	DosBase(pc),a6
	;jsr	_LVOSeek(a6)

    cmp.l   #SEEK_SET,d3
    beq     .set
    cmp.l   #SEEK_CUR,d3
    beq     .x
    bra     .y
.set
    move.l  modulePtr,readPtr
.x
    add.l   d2,readPtr
.y
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
;	movem.l	d1-d3/a0/a1/a6,-(sp)
;	move.l	DosBase(pc),a6
;	moveq	#1,d3
;	move.l	#tmp8,d2
;	clr.b	tmp8
;	jsr	_LVORead(a6)
;	move.b	tmp8(pc),d0
    push    a0
    move.l  readPtr,a0
    move.b  (a0)+,d0
    move.l  a0,readPtr
    pop     a0
;	movem.l	(sp)+,d1-d3/a0/a1/a6
	rts
	
	;-------------------------------------------------
	; Input:
	;   d1.l = file handle
	;
	; Output:
	;   d0.w = byteswapped word
	;-------------------------------------------------	
ReadLittleEndian16
;	movem.l	d1-d3/a0/a1/a6,-(sp)
;	move.l	DosBase(pc),a6
;	moveq	#2,d3
;	move.l	#tmp16,d2
;	clr.w	tmp16
;	jsr	_LVORead(a6)
;	move.w	tmp16(pc),d0
    push    a0
    move.l  readPtr,a0
    move.b  (a0)+,d0
    rol.w   #8,d0
    move.b  (a0)+,d0
    move.l  a0,readPtr
	swap16	d0
    pop     a0
;	movem.l	(sp)+,d1-d3/a0/a1/a6
	rts
	
	;-------------------------------------------------
	; Input:
	;   d1.l = file handle
	;
	; Output:
	;   d0.l = byteswapped longword
	;-------------------------------------------------
ReadLittleEndian32
;	movem.l	d1-d3/a0/a1/a6,-(sp)
;	move.l	DosBase(pc),a6
;	move.l	#tmp32,d2
;	moveq	#4,d3
;	clr.l	tmp32
;	jsr	_LVORead(a6)
;	move.l	tmp32(pc),d0
    push    a0
    move.l  readPtr,a0
    move.b  (a0)+,d0
    rol.l   #8,d0
    move.b  (a0)+,d0
    rol.l   #8,d0
    move.b  (a0)+,d0
    rol.l   #8,d0
    move.b  (a0)+,d0
    move.l  a0,readPtr
	swap32	d0
    pop     a0
;	movem.l	(sp)+,d1-d3/a0/a1/a6
	rts
	
	; -----------------------------------------------------------
	; -----------------------------------------------------------

StartTask
    tst.b   AHI
    bne     .done

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
    bsr     initSysTime
    ; ------------------------------------
    move.l  MainTask(pc),a1
    moveq   #SIGF_SINGLE,d0
    jsr     _LVOSignal(a6)
    ; ------------------------------------
.loop	
;    move.l	GraphicsBase(pc),a6
;	jsr     _LVOWaitTOF(a6)	; wait for frame's idle time
    bsr     sysWait
	bsr 	MixAudioFrame
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
    bsr     deinitSysTime
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

MAIN:
    DPRINT  "MAIN"
	move.l	a0,ArgStr
	move.l	d0,ArgStrLen
	; ----------------------------
	bsr.w	OpenDOSLib
	bsr.w	OpenGraphicsLib
	; ----------------------------
	move.l	#HeaderText,d1
	bsr.w	PutStr
	; ----------------------------
	move.l	4.w,a6			; test if we have a 68020+ CPU
	;move.w	AttnFlags(a6),d0
	;btst	#1,d0			; 68020+ ?
	;beq.w	CpuIs68000
	; ----------------------------
;	bsr.w	GetFileNameFromArg
;	bne.b	.skip			; we got filename from cmd line arg
;	bsr.w	GetFileFromRequester
;	beq.w	mainRts
;.skip	; ----------------------------
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
	moveq	#36,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,GraphicsBase
	rts
	
CloseGraphicsLib
	tst.l	GraphicsBase
	beq.b	.done
	move.l	4.w,a6
	move.l	GraphicsBase(pc),a1
	jsr	_LVOCloseLibrary(a6)
	clr.l	GraphicsBase
.done	rts
	
OpenDOSLib
	move.l	4.w,a6
	lea	DosName(pc),a1
	moveq	#36,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,DosBase
	rts	
	
CloseDOSLib
	tst.l	DosBase
	beq.b	.done
	move.l	4.w,a6
	move.l	DosBase(pc),a1
	jsr	_LVOCloseLibrary(a6)
	clr.l	DosBase
.done	
    rts

CpuIs68000
	move.l	#CpuErrText,d1
	bsr.w	PutStr
	bra.w	mainErr
	
	; Input: a0
RightTrim
	movem.l	d0/a0,-(sp)
    cmp.w   #0,a0
	;tst.l	a0	; NULL pointer?
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
	cmp.w	#0,a1
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
	tst.b	AudioOpen
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
    tst.b   AHI
    bne     .x

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
.x
	moveq	#0,d0
	rts
.error	move.l	#CIAErrTxt,d1
	bsr.w	PutStr
	moveq	#1,d0
	rts

StopMixing
	sf	SongIsPlaying

    tst.b   AHI
    bne     .x

	bsr.w	DisableAudioMixer	; also clears Paula volumes
	; ---------------------------
	move.w	#$000f,$dff096		; stop Paula DMAs
	; ---------------------------
	bsr.w	RestorePaulaInterrupt
	bsr.w	CloseCIATimer
.x
	rts

    _MC68020
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
    _MC68000

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
    bsr     FreeCDAMixBuffer
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
	DPRINT  "SetMixerVars"
	; ------------------------------------
	; Test if we have an NTSC machine
	; ------------------------------------
	lea	GraphicsName(pc),a1			
	move.l	4.w,a6
	moveq	#36,d0
	jsr	_LVOOpenLibrary(a6)
	tst.l	d0
	bne.b	.L0
	moveq	#0,d0				; error
	bra.w	.exit
.L0	move.l	d0,a1
	move.w	206(a1),d7
	jsr	_LVOCloseLibrary(a6)
	btst	#2,d7				; Amiga is PAL?
	beq 	.NTSC				; nope

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
    tst.b   AHI
    beq     .1
    move.w  AHIMixingFreq,d0
    swap    d0
.1  move.l	d0,MixingFreq
 ifne DEBUG
    swap    d0
    and.l   #$ffff,d0
    DPRINT  "MixingFreq PAL=%ld"
 endif
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
    tst.b   AHI
    beq     .2
    move.w  AHIMixingFreq,d0
    swap    d0
.2	move.l	d0,MixingFreq
 ifne DEBUG
    swap    d0
    and.l   #$ffff,d0
    DPRINT  "MixingFreq NTSC=%ld"
 endif
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
;	divu.l	#200<<16,d0		; 200 = 5ms (FT2)
    move.l  #200<<16,d1
    bsr     divu_32
	move.w	d0,QuickVolSizeVal
.3
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
    tst.b   AHI
    bne     .error
	tst.w	d0
	beq.b	.error
    _MC68020
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
    _MC68000

	; Input:
	;   d0.w = period
	;   d1.b = 0 if PAL, 1 if NTSC
	;
	; Output:
	;   d0.l = rounded 16.16fp frequency (Hz)
PaulaPeriodToFreq
	tst.w	d0
	bne.b	.Not0
	; ---------------------------
	; Period 0 -> period 65536 (confirmed on Paula)
	; ---------------------------
	tst.b	d1
	bne.b	.NTSC0
	move.l	#3546895,d0
	bra.b	.done
.NTSC0	move.l	#3579545,d0
	bra.b	.done
	; ---------------------------
	; ---------------------------
.Not0	movem.l	d1-d4,-(sp)
	move.l	d0,d2
	swap	d2
	clr.w	d2			; d2.l = period * 65536
	; ---------------------------
	tst.b	d1
	bne.b	.NTSC1
	moveq	#0,d0			; PAL
	move.l	#3546895,d1 		; d1:d0 = round[3546895.0 * 2^32]
	bra.b	.L0
.NTSC1	move.l	#$745D1746,d0		; NTSC
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
    ; d1 = up 32
    ; d0 = low 32
	; divu.l	d2,d1:d0		; d0.l = rounded Paula frequency (16.16fp)
    ; d0 = out
    
    exg     d0,d1
    ; d0 = up 32
    ; d1 = low 32
    bsr     divu_64
    ; d1 = out
    move.l  d1,d0

	movem.l	(sp)+,d1-d4
.done	rts

; converts BPM 32..255 into SamplesPerTick LUT (16.16fp)
; Formula: (MixingFreq/(BPM*2.5))*2^16
GenerateBPMTable
    tst.b   AHI
    bne     .x
	lea	BPM2SmpsPerTick,a0
	; ---------------------------
	moveq	#0,d7
	; ---------------------------
	move.l	MixingFreq(pc),d0
	moveq	#0,d6
	move.l	d0,d4
	lsl.l	#1,d4
	addx.l	d7,d6
	lsr.l	#1,d0
	add.l	d0,d4
	addx.l	d7,d6			; d6:d4 = MixingFreq(16.16fp) * 2.5
	; ---------------------------
	moveq	#32,d5			; starting BPM
	; ---------------------------
.loop	move.l	d6,d1
	move.l	d4,d0
	; ---------------------------
	; Add rounding bias
	; ---------------------------
	move.l	d5,d3
	lsr.l	#1,d3
	add.l	d3,d0
	addx.l	d7,d1
	; ---------------------------
    _MC68020
	divu.l	d5,d1:d0		; d0.l = rounded samplesPerTick (16.16fp)
    _MC68000
	move.l	d0,(a0)+
	; ---------------------------
	addq.b	#1,d5
	bne.b	.loop			; haven't overflown yet (255 -> 0 (256))
	; ---------------------------
.x
	rts

EnableAudioMixer
    tst.b   AHI
    bne     .x

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
.x	rts

DisableAudioMixer
    tst.b   AHI
    bne     .x
	; ---------------------------
	; Clear Paula volumes
	; ---------------------------
	clr.w	$dff0a8
	clr.w	$dff0b8
	clr.w	$dff0c8
	clr.w	$dff0d8
	; ---------------------------
	sf	AudioMixFlag
    movem.l  d0-a6,-(sp)
    move.l  DosBase(pc),a6
.loop	
    tst.b	AudioMixRunning     	; wait until mixer is done
	beq.b   .1
    moveq   #1,d1
    jsr     _LVODelay(a6)       	; let other tasks run
    bra.b   .loop
.1  movem.l (sp)+,d0-a6
.x	rts

AllocCDAMixBuffer:
	move.l	#4*(SMP_BUFF_SIZE*2+1),d0
	moveq	#MEMF_PUBLIC,d1
	bsr.w	AllocMem
    tst.l   d0
	beq.b	.error		
    addq.l  #4,d0
    move.l  d0,CDA_MixBufferPtr
	moveq	#0,d0
	rts
.error	moveq	#1,d0
	rts


FreeCDAMixBuffer:
	move.l	CDA_MixBufferPtr,a1
	cmp.w   #0,a1
	beq.b	.1
    clr.l   CDA_MixBufferPtr
    subq.l  #4,a1
	move.l	#4*(SMP_BUFF_SIZE*2+1),d0
	bsr.w	FreeMem
.1  rts

FreeChipBuffers
	move.l	PaulaCh1Buf(pc),a1
	cmp.w   #0,a1
	beq.b	.L1
	move.l	#SMP_BUFF_SIZE,d0
	bsr.w	FreeMem
	; ---------------------------
.L1	move.l	PaulaCh2Buf(pc),a1
	cmp.w   #0,a1
	beq.b	.L2
	move.l	#SMP_BUFF_SIZE,d0
	bsr.w	FreeMem
.L2	; ---------------------------
	IF _14BIT
		move.l	PaulaCh3Buf(pc),a1
		cmp.w   #0,a1
		beq.b	.L3
		move.l	#SMP_BUFF_SIZE,d0
		bsr.w	FreeMem
	; ---------------------------
.L3		move.l	PaulaCh4Buf(pc),a1
		cmp.w   #0,a1
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
    tst.b   AHI
    bne     .ahi

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
	bsr.w	AllocCDAMixBuffer
	beq.b	.skip3
	move.l	#AudErrTxt,d1
	bsr.w	PutStr
	moveq	#0,d0
	rts
.skip3
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
.x
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

.ahi
	move.w	#MIX_PERIOD,d0
    move.w	d0,MixPeriod
	bsr 	SetMixerVars
	beq 	.error
	moveq	#125,d0
	bsr.w	P_SetSpeed
	bsr.w	ClearChannels
    moveq   #1,d0
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
	cmp.w   #0,a1
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
	cmp.w   #0,a1
	beq.b	.nextI			; instrument is empty!
	; -----------------------------
	; Free instrument's samples
	; -----------------------------
	move.w	iAntSamp(a1),d6
	beq.b	.freeI			; instrument has no samples...
	subq.w	#1,d6	
	lea	iSamp(a1),a0		; a0 = sample struct
.loop2	move.l	sPek(a0),a1
	cmp.w   #0,a1			; sample allocated?
	beq.b	.nextS			; nope
	move.l	sLen(a0),d0
	beq.b	.nextS			; (length is zero, don't free)	
    bmi.b   .nextS          ; neg means freed earlier
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
    lsl     #2,d0
	move.l	(a0,d0.w),d1
	bsr.w	PutStr
.end	moveq	#1,d0		; 1=error
	rts

HandleError
	bsr.w	CloseFile	; error
	bsr.w	FreeMusic
	bra.w	ShowError
	
CalcFrqTab
 ifne DEBUG
    move.l  MixingFreq,d0
    clr     d0
    swap    d0
    DPRINT  "CalcFrqTab mixfreq=%ld"
 endif

	movem.l	d0-d6/a0-a2,-(sp)
	lea	Note2Period,a0
	; ----------------------------
	tst.b	LinearFrqTab
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
	move.l	#256*8363,d0   ; Constant for GetFrequenceValue_AHI
    tst.b   AHI
    bne     .ahiFr
	move.l	MixingFreq(pc),d0
	lsr.l	#1,d0
	move.l	#256*8363,d1
    _MC68020
	divu.l	MixingFreq(pc),d1:d0	
    _MC68000
.ahiFr
	move.l	d0,d2			; d2.l = round[(8363*256) * 2^32 / MixingFreq]
	moveq	#24,d3
	moveq	#32-24,d4
	lea	LogTabSource(pc),a0
	lea	LogTab,a1
	move.w	#(12*16*4)-1,d5
.loop	move.l	(a0)+,d0

;	moveq	#0,d1
;	mulu.l	d2,d1:d0
    move.l  d2,d1
    bsr     UMult64S
    exg     d0,d1

	lsr.l	d3,d0
	lsl.l	d4,d1
	or.l	d1,d0			; d0 = ((uint64_t)LogTab[i] * d2) >> 24
	move.l	d0,(a1)+
	dbra	d5,.loop
	; -------------------------------------	
	bra 	.end	


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
    move.l  d1,FrequenceDivFactor   ; For AHI
    tst.b   AHI
    bne     .ahiFrq
	move.l	MixingFreq(pc),d0
	lsr.l	#1,d0
    _MC68020
	divu.l	MixingFreq(pc),d1:d0	; d0.l = round[(8363*1712) * 2^32 / MixingFreq]
    _MC68000
	move.l	d0,FrequenceDivFactor
.ahiFrq
	; -------------------------------------
.end	movem.l	(sp)+,d0-d6/a0-a2
	rts

LoadXM
    DPRINT  "LoadXM"
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
    move    d6,d0
    add.w   d0,d0
	move.w	d4,(a0,d0.w)
	; -----------------------------
	tst.w	d3			; dataLen == 0? (pattern empty)
	beq.b	.next			; yes, load next pattern (if any)
	; -----------------------------
	; Allocate memory for pattern
	; -----------------------------
	move.l	d4,d0
	mulu.w	TrackWidth(pc),d0	; d0.l = unpacked pattern length
	move.l	d0,d2			; d2.l = copy of unpacked pattern length
	moveq	#MEMF_PUBLIC,d1
	bsr.w	AllocMem
	tst.l	d0
	beq.w	LPOOM
	move.l	d0,a1
	lea	Patt,a0
    move.w  d6,d5
    lsl.w   #2,d5
	move.l	d0,(a0,d5.w)	
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
	;move.l	(a2)+,(a1)+		; warning: can be misaligned
    move.b  (a2)+,(a1)+
    move.b  (a2)+,(a1)+
    move.b  (a2)+,(a1)+
    move.b  (a2)+,(a1)+
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
	moveq	#MEMF_PUBLIC,d1
	bsr.w	AllocMem
	tst.l	d0
	beq.w	.cihErr
	move.l	d0,a1
	lea	Instr,a0
    move.w  d6,d7
    lsl.w   #2,d7
	move.l	a1,(a0,d7.w)	
	; -----------------------------
	; Copy instrument header
	; -----------------------------
	lea	InsHdr,a0		; a0 = src, a1 = dst	
	move.l	a0,-(sp)
	move.l	a1,-(sp)
	lea	ihTA(a0),a0
	move.w	#(208)-1,d7
.loop1	move.b	(a0)+,(a1)+
	dbra	d7,.loop1
	move.l	(sp)+,a1
	move.l	(sp)+,a0
	;move.w	ihAntSamp(a0),iAntSamp(a1)	; copy leftovers
	move.b	ihAntSamp(a0),iAntSamp(a1)	; copy leftovers
	move.b	ihAntSamp+1(a0),iAntSamp+1(a1)	; copy leftovers
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
    move.w  d7,d5
    add.w   d5,d5
	move.w	4(a2,d5.w),d1
	sub.w	0(a2,d5.w),d1
	ble.b	.skipV
	move.w	6(a2,d5.w),d0
	sub.w	2(a2,d5.w),d0
	lsl.w	#8,d0
	ext.l	d0
	divs.w	d1,d0
.skipV	move.w	d0,(a4,d7.w)
	moveq	#0,d0
    move.w  d7,d5
    add.w   d5,d5
	move.w	4(a3,d5.w),d1
	sub.w	0(a3,d5.w),d1
	ble.b	.skipP
	move.w	6(a3,d5.w),d0
	sub.w	2(a3,d5.w),d0
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
	beq 	.set			; empty instrSize == INS_HDR_SIZE (quirky XMs)
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
    ; -----------------------
    lea     InstrNames,a1
    move    d6,d0
    mulu    #24,d0
    add     d0,a1
    clr.b   (a1)
    lea     ihName(a0),a2
    moveq   #22-1,d0
.cp move.b  (a2)+,(a1)+
    dbeq    d0,.cp
    clr.b   (a1)
    ; -----------------------
 ifne DEBUG
    pea     ihName(a0)
    move.l  (sp)+,d1
    moveq   #0,d0
    move    d6,d0
    DPRINT  "%ld ihName=%s"
 endif
	; -----------------------------
	moveq	#0,d3
	;move.w	ihAntSamp(a0),d3	; does this instrumenth have any samples?
    move.b  ihAntSamp(a0),d3
    ror     #8,d3
    move.b  ihAntSamp+1(a0),d3
    tst.w   d3
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
;	move.w	ihAntSamp(a0),d7
	move.b	ihAntSamp(a0),d7
    ror     #8,d7
	move.b	ihAntSamp+1(a0),d7
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
 REM ; original
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
    DPRINT  "%08.8lx %08.8lx"
	dbra	d7,.loop3
 EREM ; original
; REM 
.loop3	
;    move.l	(a1),d0
    move.b  (a1),d0
    rol.l   #8,d0
    move.b  1(a1),d0
    rol.l   #8,d0
    move.b  2(a1),d0
    rol.l   #8,d0
    move.b  3(a1),d0

	rol.w	#8,d0
	swap	d0

;	move.l	(a2),d1
    move.b  (a2),d1
    rol.l   #8,d1
    move.b  1(a2),d1
    rol.l   #8,d1
    move.b  2(a2),d1
    rol.l   #8,d1
    move.b  3(a2),d1
	
    rol.w	#8,d0
	swap	d0
	
    ;move.l	d0,(a1)+
    rol.l   #8,d0
    move.b  d0,(a1)+
    rol.l   #8,d0
    move.b  d0,(a1)+
    rol.l   #8,d0
    move.b  d0,(a1)+
    rol.l   #8,d0
    move.b  d0,(a1)+

	rol.w	#8,d1
	swap	d1
	rol.w	#8,d1
	swap	d1

;	move.l	d1,(a2)+
    rol.l   #8,d1
    move.b  d1,(a2)+
    rol.l   #8,d1
    move.b  d1,(a2)+
    rol.l   #8,d1
    move.b  d1,(a2)+
    rol.l   #8,d1
    move.b  d1,(a2)+

;    DPRINT  "%08.8lx %08.8lx"

	dbra	d7,.loop3
; EREM

	; ----------------------------- 
	bsr.w	AllocAndCopyInstrHeader
	bne.w	.error
.end	moveq	#0,d0	; 0=successful
	rts
.error	moveq	#1,d0
	rts
	
	; This updates sRepL, sLen and sTimesToUnroll
	; a1 = sample struct
	; WARNING: Do NOT trash D3!
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
	subq.l	#1,d1
	divu.w	d0,d1			; (repL (d0.l) is already <65536 at this point)
	; -----------------------------
	cmp.b	#1,sLoopType(a1)	; bidi loop?
	beq.b	.L0			; nope
	add.w	d1,d1			; yes, unroll factor must be a multiple of 2
	; -----------------------------
.L0	move.w	d1,sTimesToUnroll(a1)
	mulu.w	d1,d0			; d0.l = extra bytes to add to repL
	add.l	d0,sLen(a1)
	add.l	d0,sRepL(a1)
.end	rts

	; a1 = sample struct
Load16BitSample
	move.l	sOrigLen(a1),d3		; bytes to read from file
	beq.b	.end			; length is empty, don't load sample
	bsr.w	PrepareLoopUnroll	
	move.l	sLen(a1),d0
	addq.l	#2,d0			; fix-sample for linear interpolation
    DPRINT  "Load16BitSample buffer=%lx"
	moveq	#MEMF_PUBLIC,d1
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
    add.w	d0,d1
	move.w	d1,(a6)+
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
    DPRINT  "Load8BitSample buffer=%lx"
	moveq	#MEMF_PUBLIC,d1
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
.loop	add.b	d1,(a6)
	move.b	(a6)+,d1
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
	cmp.w   #0,a0			; sample empty?
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
	; ----------------------
.end	rts

	; a1 = sample struct
UnrollSampleLoop16
	move.l	sPek(a1),a0
	cmp.w   #0,a0			; sample empty?
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
	; ----------------------
.end	rts

	; Puts an appropriate sample at smp[sampleEnd] so that the the
	; linear interpolation routine in the mixer will always read the
	; correct sample tap.
	;
	; a1 = sample struct
FixSample
	tst.l	sLen(a1)	; sample empty?
	beq.b	.done8		; yes, don't fix
	move.l	sPek(a1),a5
	cmp.w	#0,a5		; sample empty?
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
.bidi8	move.b	-1(a5),0(a5)	; smp8[loopEnd] = smp8[loopEnd-1]
	bra.b	.done8
.fwd8	move.b	0(a6),0(a5)	; smp8[loopEnd] = smp8[loopStart]
	bra.b	.done8
.loff8	move.b	-1(a5),0(a5)	; smp8[sampleEnd] = smp8[sampleEnd-1]
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
.bidi16	move.w	-2(a5),0(a5)	; smp16[loopEnd] = smp16[loopEnd-1]
	bra.b	.done16
.fwd16	move.w	0(a6),0(a5)	; smp16[loopEnd] = smp16[loopStart]
	bra.b	.done16
.loff16	move.w	-2(a5),0(a5)	; smp16[sampleEnd] = smp16[sampleEnd-1]
.done16	rts

	; d6.w = instrument number
LoadInstrSamples
	lea	Instr,a1
    move.w  d6,d7
    lsl.w   #2,d7
	move.l	(a1,d7.w),a1
	cmp.w   #0,a1			; instrument empty?
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
    DPRINT  "LoadData_XM_OldVer"
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
    DPRINT  "LoadInstrSamples=%ld"
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
    DPRINT  "LoadData_XMv104"
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
    DPRINT  "LoadInstrSamples=%ld"
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
    lsl.w   #2,d1
	move.l	(a0,d1.w),a0
	cmp.w   #0,a0
	bne.b	.InstrOK
.error	lea	SpareInstr,a0	; illegal instr, use placeholder instr
.InstrOK
	move.l	a0,cInstrSeg(a5)
	move.b	iMute(a0),cMute(a5)
    moveq   #0,d1           ; clear for below indexed access
	move.b	d0,d1
	subq.b	#1,d1
	move.b	(a0,d1.w),d1	; a0 points to TA table (first data in instrument)
	and.b	#$f,d1		; d1.w = sample	(upper byte already cleared above)

	; *** Finetune & volume ***
	
	lea	iSmpOffset(pc),a2
	move.l	a0,a3
    add.w   d1,d1
	add.w	(a2,d1.w),a3	; a3 = sample struct
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
    add.w   d0,d0
	move.w	(a0,d0.w),d0
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

;	jsr	([VolChTab,pc,d1.w*4])
    lea     VolChTab(pc),a0
    lsl.w   #2,d1
    move.l  (a0,d1.w),a0
    jsr     (a0)

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
	clr.w	cEnvVIPValue(a5)
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
    move.w  d1,d0
    add.w   d0,d0
	move.w	(a0,d0.w),PattLen	
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
.ok	
    tst.b   AHI
    beq     .1
    bmi     .2
    bsr     ahi_tempo
    bra     .1
.2  bsr     amigus_tempo
.1
    sub.b	#32,d0	
	lea	BPM2SmpsPerTick,a0
    lsl.w   #2,d0
	move.l	(a0,d0.w),SpeedVal	; 16.16fp
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
    move.w  d6,d0
    add.w   d0,d0
	move.w	(a0,d0.w),d0
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

;	jsr	([VolJumpTab0,pc,d1.w*4])
    lea     VolJumpTab0(pc),a0
    lsl.w   #2,d1
    move.l  (a0,d1.w),a0
    jsr     (a0)
	
	; handle normal effects
	; d0 is reserved for old cVolKolVol (manipulated by VolJumpTab effects)	
	moveq	#0,d1
	move.b	cEffTyp(a5),d1	
	moveq	#0,d2
	move.b	cEff(a5),d2
	move.b	d2,d3		; test if we have an effect at all (eff+effTyp > 0)
	or.b	d1,d3
	beq.b	.EffEnd		; no effect

;	jmp	([JumpTab0,pc,d1.w*4])	
    lea     JumpTab0(pc),a0
    lsl.w   #2,d1
    move.l  (a0,d1.w),a0
    jmp     (a0)

.EffEnd
	rts

	; E effects
EEffects0
	move.b	d2,d1
	and.b	#15,d2
	lsr.b	#4,d1
;	jmp	([EJumpTab0,pc,d1.w*4])
    lea     EJumpTab0(pc),a0
    lsl.w   #2,d1
    move.l  (a0,d1.w),a0
    jmp     (a0)

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
	tst.b	PattDelTime2
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

;	jsr	([VolJumpTab,pc,d1.w*4])	
    lea     VolJumpTab(pc),a0
    lsl.w   #2,d1
    move.l  (a0,d1.w),a0
    jsr     (a0)
	
	; normal effects
	moveq	#0,d1
	move.b	cEffTyp(a5),d1	
	moveq	#0,d0
	move.b	cEff(a5),d0
	move.b	d0,d2		; test if we have an effect at all (eff+effTyp > 0)
	or.b	d1,d2
	beq.b	.EffEnd		; no effect

;	jmp	([JumpTab,pc,d1.w*4])	
    lea     JumpTab(pc),a0
    lsl.w   #2,d1
    move.l  (a0,d1.w),a0
    jmp     (a0)

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
	tst.b	LinearFrqTab
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

	;mulu.l	d0,d1			; (d1.l * 0..32768) = d1.l 0..2147483648
    bsr     mulu_32
    move.l  d0,d1

	add.l	#1<<19,d1		; rounding bias
	swap	d1
	lsr.w	#4,d1			; d1.w = 0..2048 (rounded)
	; ----------------------------
	mulu.w	MixingVolume(pc),d1
	add.l	#1<<5,d1		; rounding bias
	lsr.l	#6,d1
	; ----------------------------
	move.w	d1,cFinalVol(a5)	; 0..2048
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
	move.w	d0,cFinalVol(a5)	; 0..2048
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
.Dskc	tst.b	PattDelTime2
	beq.b	.Dska
	subq.b	#1,PattDelTime2
	beq.b	.Dska
	subq.w	#1,PattPos
.Dska	tst.b	PBreakFlag
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
	tst.b	bxxOverflow
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
    move.l  songOverPtr,a0      * song over trigger
    st      (a0)
.NoNewSong
	move.w	d0,SongPos
	lea	hSongTab,a0
	move.b	(a0,d0.w),d0
	move.w	d0,PattNr
	lea	PattLens,a0
    add.w   d0,d0
	move.w	(a0,d0.w),PattLen
	; 8bb: fix for EVIL modules that use Dxx where xx>=nextPattLen
	move.w	PattPos(pc),d0
	move.w	PattLen(pc),d1
	cmp.w	d1,d0
	blo.b	.NoNewPosYet
	clr.w	PattPos
.NoNewPosYet
	tst.b	PosJumpFlag
	bne 	.NextPosition
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
	tst.b	PattDelTime2
	beq.b	.GetNewNote
	bra.b	.Dskip
.GetNewNote
	move.w	PattNr(pc),d2
	and.w	#$ff,d2
	lea	Patt,a4
    move.w  d2,d0
    lsl.w   #2,d0
	move.l	(a4,d0.w),a4
	cmp.w	#0,a4
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
	
    _MC68020
Mix_UpdateChannelVolPanFrq:
	lea	PanningTab(pc),a1
	lea	ChnReloc,a2             ; Table of WORD: 0,2,4,6..MAX_CHANNELS*2
	lea	VoiceOffsets,a3         ; Table of APTR MixVoices, 0..MAX_CHANNELS*2
	lea	LogTab,a4
    lea	StmTyp,a5
	moveq	#0,d7               ; loop number of channels in the mod
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
	beq 	.next
	; -----------------------------
	move.l	cSampleSeg(a5),a0
	tst.l	a0
	beq 	.stop
	move.l	sPek(a0),d0
	beq 	.stop
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
	addq.b	#1,d7           ; loop all channels
	cmp.w	hAntChn,d7
	bne.w	.loop
	rts
	; -----------------------------
.stop	move.b	#IST_Off,vType(a6)		; stops voice
	bra.b	.next

	; d0.l = volume (0..2048)
	; d2.l = volume ramp length (number of samples)
.SetVol
	move.l	d0,d1
	; ----------------------------
	moveq	#0,d3
	move.b	cFinalPan(a5),d3	
	mulu.w	(a1,d3.w*2),d1			; 0..2048 * 0..65535 = 0..134215680 (11.16fp)
	move.l	d1,vRVol1(a6)			; set dest. volL
	not.b	d3
	addq.w	#1,d3				; d3.w = 256 - d2
	mulu.w	(a1,d3.w*2),d0			; 0..2048 * 0..65535 = 0..134215680 (11.16fp)
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
    _MC68000

; ---------------------------------------------------------
; ---------------------------------------------------------
; ---------------------------------------------------------

Mix_UpdateChannelVolPanFrq_AHI:
    lea LogTab,a4
	lea	StmTyp,a5
    lea     freqForChannel(pc),a2
    lea     sampleForChannel(pc),a3
	moveq	#0,d7               ; loop number of channels in the mod
	; -----------------------------
.loop	
    move.b	cStatus(a5),d6
	beq.w	.next				; no update flags, skip channel
	clr.b	cStatus(a5)	
	; -----------------------------
	; -------------------------------------------------------------------
	;               SAMPLE PRE-TRIGGER (setup fadeout voice)
	; -------------------------------------------------------------------	
	;btst	#IB_NyTon,d6
	;beq 	.vol
	; -----------------------------
    ; Not available in AHI!
	;or.b	#IST_Fadeout,vType(a6)
	;moveq	#0,d0				; destination volume
	;moveq	#0,d2
	;move.w	QuickVolSizeVal(pc),d2		; volume ramp length
	;bsr.w	.SetVol
	;eor.w	#1,(a2,d7.w*2)			; swap voice with neighbor voice
	;move.w	(a2,d7.w*2),d0
	;move.l	(a3,d0.w*4),a6			; a6 points to mixer voice to use
	;move.b	#IST_Off,vType(a6)
	
	; -------------------------------------------------------------------
	;                            VOLUME UPDATE
	; -------------------------------------------------------------------
.vol	
    move.b	d6,d2
	and.b	#IS_Vol+IS_Pan,d2
	beq.b	.period
	; -----------------------------

;	pushm   all
    push    a2
	move.l	d7,d0		; channel (d7)

	; AHI_SetVol args: channel (d0), vol (d1 0..$10000), pan (d2 0..$10000), freq (d3), flags (d4)
    ; cFinalPan(a5) = 0..255. AHI expects 0..$10000
    ; 128 = center
	moveq	#0,d2
	move.b	cFinalPan(a5),d2    
    * AHI: 0x00000 full left, 0x8000 center, 0x10000 full right
	lsl.l	#8,d2		; 255 -> $FF00 (approx $10000)

	moveq	#0,d1
	move.w	cFinalVol(a5),d1
	lsl.l	#5,d1		; volume $0000 -> $10000
	move.l	d7,d0		; channel
	
	moveq	#AHISF_IMM,d3	; flags
   ;;; DPRINT  "SetVol ch=%02.2lx vol=%05.5lx pan=%05.5lx"
	move.l	ahibase(pc),a6
	move.l	ahi_ctrl(pc),a2
	jsr	_LVOAHI_SetVol(a6)
    pop     a2
;    popm    all


	; -------------------------------------------------------------------
	;                            PERIOD UPDATE
	; -------------------------------------------------------------------
.period	
    btst	#IB_Period,d6
	beq 	.trig
	; -----------------------------
	move.w	cFinalPeriod(a5),d0
	bsr 	GetFrequenceValue  	; Returns Hz

 ;   pushm   all
    push    a2
    move.w  d7,d1
    add.w   d1,d1
    add.w   d1,d1
    move.l  d0,(a2,d1.w)    ; Store frequency per channel

	move.l	d0,d1	    	; d1 = freq (Hz)
	move.l	d7,d0	    	; d0 = channel
	moveq	#AHISF_IMM,d2   ; d2 = flags
	move.l	ahibase(pc),a6
	move.l	ahi_ctrl(pc),a2
    ;;DPRINT  "SetFreq ch=%02.2lx fr=%ld Hz"
	jsr	_LVOAHI_SetFreq(a6)
    pop     a2
  ;  popm    all
	; -------------------------------------------------------------------
	;                           SAMPLE TRIGGER
	; -------------------------------------------------------------------
.trig	btst	#IB_NyTon,d6
	beq 	.next
	; -----------------------------
    move.w  d7,d1
    lsl.w   #2,d1
    clr.l   (a3,d1.w)        * Initially no smp for channel
	move.l	cSampleSeg(a5),d0
	beq 	.stop
    move.l  d0,a0
	move.l	sPek(a0),d0
	beq 	.stop    
    move.l  a0,(a3,d1.w)   ; Store sample ptr per channel for soundfunc

	; -----------------------------	
    move.l  sOrigLen(a0),d1
	move.l	cSmpStartPos(a5),d4
	; -----------------------------
	tst.b	s16Bit(a0)			; 16-bit sample?
	beq.b	.L2				    ; nope
	lsr.l	#1,d1				; yes, convert units from bytes to words
	; -----------------------------
.L2	
	cmp.l   d1,d4			    ; d4 >= (unrolled) sample end?
	bhs 	.stop				; yes, stop voice
	; -----------------------------
    ; sLoopType: 0 -> No Loop
    ;            1 -> Forward loop
    ;            2 -> ping pong loop

    push    a2
    clr.b   sAHILoopDir(a0)  * Reset ping pong state
    move.l  d1,d3            * d3=length (0=play full sample)	
    sub.l   d4,d3            * .. adjust based on start offset
    moveq   #0,d1
	move.w	sAHISound(a0),d1 * d1=sound number
	move.l	d7,d0            * d0=channel
	move.l	d4,d2            * d2=offset
	moveq	#AHISF_IMM,d4    * d4=flags
	move.l	ahibase(pc),a6
	move.l	ahi_ctrl(pc),a2
;    DPRINT  "SetSound ch=%02.2lx sound=%02.2lx offs=%04.4lx len=%04.4lx"
	jsr	_LVOAHI_SetSound(a6)
    pop     a2


	; -------------------------------------------------------------------
.next	lea	CHN_SIZE(a5),a5
	addq.b	#1,d7           ; loop all channels
	cmp.w	hAntChn,d7
	bne.w	.loop
	rts
	; -----------------------------
.stop	
    push    a2
    moveq	#AHI_NOSOUND,d1
	move.l	d7,d0
	moveq	#0,d2
	moveq	#0,d3
	moveq	#AHISF_IMM,d4
	move.l	ahibase(pc),a6
	move.l	ahi_ctrl(pc),a2
    DPRINT  "NOSOUND channel=%ld"
	jsr	_LVOAHI_SetSound(a6)
    pop     a2
	bra.b	.next



; ---------------------------------------------------------
; ---------------------------------------------------------
; ---------------------------------------------------------

Mix_UpdateChannelVolPanFrq_AGUS:
    lea LogTab,a4
	lea	StmTyp,a5
	moveq	#0,d7               ; loop number of channels in the mod
	move.l	amigus_base(pc),a6	; a6 = AmiGUS register base
    lea     agusVolForChannel,a3
	; -----------------------------
.loop	
    move.b	cStatus(a5),d6
	beq 	.next				; no update flags, skip channel
	clr.b	cStatus(a5)	
	move.w	d7,HAGEN_VOICE_BNK(a6)	; Set channel number
	; -------------------------------------------------------------------
	;               SAMPLE PRE-TRIGGER (setup fadeout voice)
	; -------------------------------------------------------------------	
	;btst	#IB_NyTon,d6
	;beq 	.vol
	; -----------------------------
    ; Not available!
	;or.b	#IST_Fadeout,vType(a6)
	;moveq	#0,d0				; destination volume
	;moveq	#0,d2
	;move.w	QuickVolSizeVal(pc),d2		; volume ramp length
	;bsr.w	.SetVol
	;eor.w	#1,(a2,d7.w*2)			; swap voice with neighbor voice
	;move.w	(a2,d7.w*2),d0
	;move.l	(a3,d0.w*4),a6			; a6 points to mixer voice to use
	;move.b	#IST_Off,vType(a6)
	
	; -------------------------------------------------------------------
	;                            VOLUME UPDATE
	; -------------------------------------------------------------------
.vol	
    move.b	d6,d2
	and.b	#IS_Vol+IS_Pan,d2
	beq.b	.period
	; -----------------------------

;def calculate_pan_volumes(pan, input_vol):
;    # 1. Scale input volume to output range (0..65535)
;    # Using 65535.0 to ensure float precision before final rounding
;    v_scaled = input_vol * (65535.0 / 2048.0)
;    
;    if pan == 128:
;        v_l = v_scaled
;        v_r = v_scaled
;    elif pan < 128:
;        # Panned Left: Left is full, Right is attenuated
;        v_l = v_scaled
;        v_r = v_scaled * (pan / 128.0)
;    else:
;        # Panned Right: Right is full, Left is attenuated
;        v_r = v_scaled
;        v_l = v_scaled * ((255 - pan) / 127.0)
;        
;    return round(v_l), round(v_r)
;
;# Examples:
;# Center (128) at Max Vol (2048) -> (65535, 65535)
;# Full Left (0) at Max Vol (2048) -> (65535, 0)
;# Full Right (255) at Max Vol (2048) -> (0, 65535)
;
	move.w	cFinalVol(a5),d0    * 0..2048 (0..$800)
    mulu    #$ffff,d0
    lsr.l   #8,d0
    lsr.l   #3,d0               * 0..0xffff
    move    d0,d1               * initial left, right

	moveq	#0,d2
	move.b	cFinalPan(a5),d2    * 0..128..255 = left..center..right
    cmp.b   #128,d2
    beq     .set

 ;   cmp.b   #128,d2
    bhs     .right
    * Panned Left: Left is full, Right is attenuated
    mulu.w  d2,d1    
    lsr.l   #7,d1
    bra     .set

.right
    * Panned Right: Right is full, Left is attenuated
    move.w  #255,d3
    sub     d2,d3
    mulu    d3,d0
    divu    #127,d0
.set
    ; 0xffff -> 0x3fff
    lsr.w   #2,d0
    lsr.w   #2,d1
	move.w	d0,HAGEN_VOICE_VOLUMEL(a6)
	move.w	d1,HAGEN_VOICE_VOLUMER(a6)
    move.w  d7,d2
    add.w   d2,d2
    move.w  d0,(a3,d2.w)        * stash channel vol
    move.w  d1,2(a3,d2.w)

	; -------------------------------------------------------------------
	;                            PERIOD UPDATE
	; -------------------------------------------------------------------
.period	
    btst	#IB_Period,d6
	beq 	.trig
	; -----------------------------
	move.w	cFinalPeriod(a5),d0
	bsr 	GetFrequenceValue  	; Returns Hz

    ; d0 = frequency
	move.l	#$15d8,d1
	mulu.w	d0,d1
	swap	d0
	mulu.w	#$15d8,d0
	swap	d0
	clr.w   d0
	add.l	d0,d1
	move.l	d1,HAGEN_VOICE_RATEH(a6)	; Update note frequency
	; -------------------------------------------------------------------
	;                           SAMPLE TRIGGER
	; -------------------------------------------------------------------
.trig	btst	#IB_NyTon,d6
	beq 	.next
	; -----------------------------
	move.l	cSampleSeg(a5),d0
	beq 	.stop
    move.l  d0,a0
	move.l	sPek(a0),d0
	beq 	.stop    

	; -----------------------------	
    move.l  sOrigLen(a0),d1
	move.l	cSmpStartPos(a5),d4
  
    ; Voice control register initial value
    ; Playback bit #15 set
    move.w   #$8000,d5  
    cmp.b   #-2,AHI
    bne     .1
    bset    #2,d5       * interpolation bit
.1
	; -----------------------------
	tst.b	s16Bit(a0)			; 16-bit sample?
	beq.b	.L2				    ; nope
;	lsr.l	#1,d1				; yes, convert units from bytes to words
    add.l   d4,d4               ; convert offset to bytes
    bset    #0,d5               ; bit 0, set 16-bit sample
	; -----------------------------
.L2	
	cmp.l   d1,d4			    ; d4 >= (unrolled) sample end?
	bhs 	.stop				; yes, stop voice
	; -----------------------------
    ; sLoopType: 0 -> No Loop
    ;            1 -> Forward loop
    ;            2 -> ping pong loop

	clr.w	HAGEN_VOICE_CTRL(a6)		; Temporarily disable voice playback
    move.l  sAGUSOffset(a0),d0          ; Start address
    add.l   d4,d0                       ; Possible offset change
	move.l	d0,HAGEN_VOICE_PSTRTH(a6)	; Store start
    move.l  sOrigLen(a0),d1             ; Length

    move.l  sRepS(a0),d3                ; Repeat start offset
    move.l  sOrigRepL(a0),d4            ; Repeat length
    cmp.l   #4,d4
    bls     .noLoop
    tst.b   sLoopType(a0)
    beq     .noLoop
    cmp.b   #2,sLoopType(a0)
    bne     .noBidi
    add.l   d4,d4                       ; double replen for bidi with mirrored data
.noBidi
    ; TODO: cannot set ping-pong loop
    bset    #1,d5                       ; loop bit
    ; Loop active
    move.l  d3,d1                       ; Calculate loop end as the new sample end
    add.l   d4,d1
.noLoop
    add.l   sAGUSOffset(a0),d1          ; Calc end address 
    subq.l  #2,d1                       ; Subtract a bit?
	move.l	d1,HAGEN_VOICE_PENDH(a6)    ; ...

    move.l  sRepS(a0),d3                ; Calc repeat start address
    add.l   sAGUSOffset(a0),d3         
    move.l  d3,HAGEN_VOICE_PLOOPH(a6)   ; set it

    move.w  d5,HAGEN_VOICE_CTRL(a6)     ; trigger


	; -------------------------------------------------------------------
.next	lea	CHN_SIZE(a5),a5
	addq.b	#1,d7           ; loop all channels
	cmp.w	hAntChn,d7
	bne.w	.loop
	rts
	; -----------------------------
.stop	
    ; Mute this channel
	move.w	#0,HAGEN_VOICE_VOLUMEL(a6)
	move.w	#0,HAGEN_VOICE_VOLUMER(a6)
	bra.b	.next


	; input:
	;  a4   = log table
	;  d0.w = period
	;
	; output: d0.l = delta (16.16fp) (or Hz if AHI tables used)
GetFrequenceValue:
	tst.w	d0
	beq 	.periodIsZero
	; -----------------------------
	;tst.b	LinearFrqTab(pc)
    move.b  LinearFrqTab(pc),d1
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
;	move.l	(a4,d1.w*4),d0
    lsl.w   #2,d1
	move.l	(a4,d1.w),d0
	lsr.l	d3,d0
    rts

.amiga	
    ext.l   d0
	move.l	FrequenceDivFactor(pc),d1
    exg     d0,d1
    bsr     divu_32
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
;  d3.l = #16 (for 'lsr.l Dn,Dn' - better pipelined than 'swap Dn')
;  d4.l = <free>
;  d5.l = <free>
;  d6.l = current volL
;  d7.l = sampling position 16-bit frac (upper word must stay cleared)
;
; ============================================================

; ------------------
; No-ramp mixers
; ------------------
    _MC68020
; 8-bit stereo mixing w/ linear interpolation
MIX8_S	MACRO ; 68060 OPTIMIZED!
	movem.w	(a3,d2.l),d4
	move.b	d4,d5
	clr.b	d4
	lsl.w	#8,d5
	ext.l	d5
	sub.l	d4,d5
	mulu.l	d7,d5
	lsr.l	d3,d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	move.w	d5,d4		; copy of sample
	; ---------------------
	add.w	a4,d7
	addx.l	d1,d2
	; ---------------------
	muls.w	d6,d5		; d6.w(0..2047) * d5.w(-32768..32765) -> d5.l(-67076096..67069955)
	add.l	d5,(a5)+
	; ---------------------	
	muls.w	d0,d4		; d0.w(0..2047) * d4.w(-32768..32767) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	ENDM
	
; 8-bit center mixing w/ linear interpolation
MIX8_C	MACRO ; 68060 OPTIMIZED!
	movem.w	(a3,d2.l),d4
	move.b	d4,d5
	clr.b	d4
	lsl.w	#8,d5
	ext.l	d5
	sub.l	d4,d5
	mulu.l	d7,d5
	lsr.l	d3,d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	; ---------------------
	muls.w	d0,d5		; d0.w(0..2047) * d5.w(-32768..32765) -> d5.l(-67076096..67069955)
	add.l	d5,(a5)+
	; ---------------------	
	add.w	a4,d7
	addx.l	d1,d2
	; ---------------------	
	add.l	d5,(a5)+
	ENDM
	
; 16-bit stereo mixing w/ linear interpolation
MIX16_S	MACRO ; 68060 OPTIMIZED!
	movem.w	(a3,d2.l*2),d4/d5
	sub.l	d4,d5
	mulu.l	d7,d5
	lsr.l	d3,d5
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
MIX16_C	MACRO ; 68060 OPTIMIZED!
	movem.w	(a3,d2.l*2),d4/d5
	sub.l	d4,d5
	mulu.l	d7,d5
	lsr.l	d3,d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	; ---------------------
	muls.w	d0,d5		; d0.w(0..2047) * d5.w(-32768..32765) -> d5.l(-67076096..67069955)
	add.l	d5,(a5)+
	; ---------------------	
	add.w	a4,d7
	addx.l	d1,d2
	; ---------------------	
	add.l	d5,(a5)+
	ENDM

; ------------------
; Volume ramp mixers
; ------------------

; 8-bit stereo mixing w/ linear interpolation & volume ramping
MIX8_RS	MACRO ; 68060 OPTIMIZED!
	movem.w	(a3,d2.l),d4
	move.b	d4,d5
	clr.b	d4
	lsl.w	#8,d5
	ext.l	d5
	sub.l	d4,d5
	mulu.l	d7,d5
	lsr.l	d3,d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	; ---------------------
	move.l	d6,d4
	lsr.l	d3,d4		; d4.w = volL integer (0..2047)
	muls.w	d5,d4		; d5.w(-32768..32765) * d5.w(0..2047) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	; ---------------------	
	move.l	d0,d4
	lsr.l	d3,d4		; d4.w = volR integer (0..2047)
	muls.w	d5,d4		; d5.w(-32768..32767) * d4.w(0..2047) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	; ---------------------
	add.w	a4,d7
	addx.l	d1,d2
	; ---------------------	
	add.l	a1,d6		; add volL ramp delta to curr. volL
	add.l	a2,d0		; add volR ramp delta to curr. volR
	ENDM

; 8-bit center mixing w/ linear interpolation & volume ramping
MIX8_RC	MACRO ; 68060 OPTIMIZED!
	movem.w	(a3,d2.l),d4
	move.b	d4,d5
	clr.b	d4
	lsl.w	#8,d5
	ext.l	d5
	sub.l	d4,d5
	mulu.l	d7,d5
	lsr.l	d3,d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	; ---------------------
	move.l	d6,d4
	lsr.l	d3,d4		; d4.w = volL integer (0..2047)
	muls.w	d5,d4		; d5.w(-32768..32765) * d4.w(0..2047) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	; ---------------------
	add.w	a4,d7
	addx.l	d1,d2
	; ---------------------	
	add.l	d4,(a5)+
	add.l	a1,d6		; add volL ramp delta to curr. volL
	ENDM
	
; 16-bit stereo mixing w/ linear interpolation & volume ramping
MIX16_RS	MACRO ; 68060 OPTIMIZED!
	movem.w	(a3,d2.l*2),d4/d5
	sub.l	d4,d5
	mulu.l	d7,d5
	lsr.l	d3,d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	; ---------------------
	move.l	d6,d4
	lsr.l	d3,d4		; d4.w = volL integer (0..2047)
	muls.w	d5,d4		; d5.w(-32768..32765) * d5.w(0..2047) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	; ---------------------
	move.l	d0,d4
	lsr.l	d3,d4		; d4.w = volR integer (0..2047)
	muls.w	d5,d4		; d5.w(-32768..32767) * d4.w(0..2047) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	; ---------------------
	add.w	a4,d7
	addx.l	d1,d2
	; ---------------------
	add.l	a1,d6		; add volL ramp delta to curr. volL
	add.l	a2,d0		; add volR ramp delta to curr. volR
	ENDM
	
; 16-bit center mixing w/ linear interpolation & volume ramping
MIX16_RC	MACRO ; 68060 OPTIMIZED!
	movem.w	(a3,d2.l*2),d4/d5
	sub.l	d4,d5
	mulu.l	d7,d5
	lsr.l	d3,d5
	add.w	d4,d5		; d5.w = interpolated 16-bit sample
	; ---------------------
	move.l	d6,d4
	lsr.l	d3,d4		; d4.w = volL integer (0..2047)
	muls.w	d5,d4		; d5.w(-32768..32765) * d4.w(0..2047) -> d4.l(-67076096..67069955)
	add.l	d4,(a5)+
	; ---------------------
	add.w	a4,d7
	addx.l	d1,d2
	; ---------------------	
	add.l	d4,(a5)+
	add.l	a1,d6		; add volL ramp delta to curr. volL
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
mix8S0 subq.w	#1,MixLoopCounter
       bpl.w	mix8SLoop
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
mix8C0 subq.w	#1,MixLoopCounter
       bpl.w	mix8CLoop
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
mix16S0 subq.w	#1,MixLoopCounter
        bpl.w	mix16SLoop
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
mix16C0 subq.w	#1,MixLoopCounter
        bpl.w	mix16CLoop
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
mix8RS0 subq.w	#1,MixLoopCounter
        bpl.w	mix8RSLoop
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
mix8RC0 subq.w	#1,MixLoopCounter
        bpl.w	mix8RCLoop
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
mix16RS0 subq.w	#1,MixLoopCounter
         bpl.w	mix16RSLoop
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
mix16RC0 subq.w	#1,MixLoopCounter
         bpl.w	mix16RCLoop
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
	move.w	d3,MixLoopCounter
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
	moveq	#16,d3
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
	move.w	d3,MixLoopCounter
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
	moveq	#16,d3
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
	move.w	d3,MixLoopCounter
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
	moveq	#16,d3
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
	move.l	CDA_MixBufferPtr,a0
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
	move.l	CDA_MixBufferPtr,a0
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
	moveq	#MEMF_PUBLIC,d1
	bsr.w	AllocMem
	tst.l	d0
	beq.b	.error		
	move.l	d0,PostMixTable	; set pointer	
.ok	moveq	#0,d0
	rts
.error	moveq	#1,d0
	rts

 _MC68000
FreePostMixTable
	IF _14BIT
		move.l	#65536*2,d0
	ELSE
		move.l	#65536,d0
	ENDIF
	move.l	PostMixTable(pc),a1
	cmp.w   #0,a1
	beq.b	.ok			; not allocated!
	bsr.w	FreeMem
	clr.l	PostMixTable
.ok	rts
	
	IF _14BIT

	; 14-bit output	(MIX_AMP controls the gain)
 _MC68020
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

    _MC68000

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
;	move.w	(a0,d0.w*2),PattLen
    add.w   d0,d0
	move.w	(a0,d0.w),PattLen
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
	tst.b	SongIsPlaying
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
		dc.b " xmaplay060 v0.47 ("
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
WasPlayingText	dc.b "Playback stopped. You can close this window now.",$a,0

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
MixLoopCounter		dc.w 0
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
HandlerName		dc.b "xmaplay060 input handler",0
InputDevice		dc.b "input.device",0
tmp8			dc.b 0
bxxOverflow		dc.b 0

; -------------------------------------
AHI                 dc.b 0
	EVEN
ahibase             dc.l 0
ahi_ctrl            dc.l 0
ahi_mastervol       dc.w 0
AHIMixingFreq       dc.w 58000
sampleForChannel    ds.l 32
freqForChannel      ds.l 32
agusVolForChannel   ds.l 32
; -------------------------------------

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
	
		; Panning table from FT2.08 and later.
	; Uses square root for constant power. Similar to Gravis Ultrasound.
	;
	; Note: last value reduced from 65536 to 65535 to halve table size.
	;
	; for (int32_t i = 0; i <= 256; i++)
	; {
	;    uint32_t x = (uint32_t)round(65536.0 * sqrt(i / 256.0));
	;    if (x > 65535) x = 65535;
	;    LUT[i] = (uint16_t)x;
	; }
	;
	CNOP 0,2
PanningTab
        dc.w $0000,$1000,$16A1,$1BB6,$2000,$23C7,$2731,$2A55,$2D41,$3000
        dc.w $3299,$3511,$376D,$39B0,$3BDE,$3DF8,$4000,$41F8,$43E2,$45BE
        dc.w $478E,$4952,$4B0C,$4CBC,$4E62,$5000,$5196,$5323,$54AA,$562A
        dc.w $57A3,$5916,$5A82,$5BEA,$5D4C,$5EA8,$6000,$6153,$62A1,$63EC
        dc.w $6531,$6673,$67B1,$68EB,$6A22,$6B55,$6C84,$6DB1,$6EDA,$7000
        dc.w $7123,$7243,$7361,$747B,$7593,$76A9,$77BC,$78CC,$79DA,$7AE6
        dc.w $7BEF,$7CF7,$7DFC,$7EFF,$8000,$80FF,$81FC,$82F7,$83F0,$84E8
        dc.w $85DE,$86D2,$87C4,$88B4,$89A3,$8A90,$8B7C,$8C66,$8D4F,$8E36
        dc.w $8F1C,$9000,$90E3,$91C4,$92A4,$9383,$9461,$953D,$9618,$96F2
        dc.w $97CA,$98A1,$9977,$9A4C,$9B20,$9BF3,$9CC4,$9D95,$9E64,$9F33
        dc.w $A000,$A0CC,$A198,$A262,$A32B,$A3F4,$A4BB,$A581,$A647,$A70B
        dc.w $A7CF,$A892,$A954,$AA15,$AAD5,$AB95,$AC53,$AD11,$ADCE,$AE8A
        dc.w $AF45,$B000,$B0BA,$B173,$B22B,$B2E3,$B399,$B450,$B505,$B5BA
        dc.w $B66E,$B721,$B7D3,$B885,$B937,$B9E7,$BA97,$BB46,$BBF5,$BCA3
        dc.w $BD51,$BDFD,$BEA9,$BF55,$C000,$C0AA,$C154,$C1FD,$C2A6,$C34E
        dc.w $C3F6,$C49C,$C543,$C5E9,$C68E,$C733,$C7D7,$C87B,$C91E,$C9C1
        dc.w $CA63,$CB04,$CBA6,$CC46,$CCE6,$CD86,$CE25,$CEC4,$CF62,$D000
        dc.w $D09D,$D13A,$D1D7,$D272,$D30E,$D3A9,$D444,$D4DE,$D577,$D611
        dc.w $D6AA,$D742,$D7DA,$D872,$D909,$D9A0,$DA36,$DACC,$DB62,$DBF7
        dc.w $DC8B,$DD20,$DDB4,$DE47,$DEDB,$DF6E,$E000,$E092,$E124,$E1B5
        dc.w $E246,$E2D7,$E367,$E3F7,$E487,$E516,$E5A5,$E633,$E6C1,$E74F
        dc.w $E7DD,$E86A,$E8F7,$E983,$EA0F,$EA9B,$EB27,$EBB2,$EC3D,$ECC7
        dc.w $ED51,$EDDB,$EE65,$EEEE,$EF77,$F000,$F088,$F110,$F198,$F220
        dc.w $F2A7,$F32E,$F3B4,$F43B,$F4C1,$F546,$F5CC,$F651,$F6D6,$F75B
        dc.w $F7DF,$F863,$F8E7,$F96A,$F9EE,$FA71,$FAF3,$FB76,$FBF8,$FC7A
        dc.w $FCFB,$FD7D,$FDFE,$FE7F,$FEFF,$FF80,$FFFF

	; for (int32_t i = 0; i < 12*16*4; i++)
	;     LogTabSource[i] = (uint32_t)round(16777216.0 * exp2(i / (12.0 * 16.0 * 4.0)));
	;
        CNOP 0,4
LogTabSource
        dc.l $1000000,$1003B2D,$1007667,$100B1B0,$100ED06,$1012869,$10163DB
        dc.l $1019F5A,$101DAE7,$1021681,$102522A,$1028DE0,$102C9A4,$1030576
        dc.l $1034155,$1037D43,$103B93E,$103F547,$104315F,$1046D84,$104A9B6
        dc.l $104E5F7,$1052246,$1055EA3,$1059B0D,$105D786,$106140C,$10650A1
        dc.l $1068D43,$106C9F4,$10706B3,$107437F,$107805A,$107BD43,$107FA3A
        dc.l $108373E,$1087452,$108B173,$108EEA2,$1092BDF,$109692B,$109A685
        dc.l $109E3ED,$10A2163,$10A5EE7,$10A9C7A,$10ADA1A,$10B17CA,$10B5587
        dc.l $10B9352,$10BD12C,$10C0F14,$10C4D0B,$10C8B10,$10CC923,$10D0744
        dc.l $10D4574,$10D83B2,$10DC1FF,$10E005A,$10E3EC3,$10E7D3B,$10EBBC1
        dc.l $10EFA56,$10F38F9,$10F77AB,$10FB66B,$10FF53A,$1103417,$1107303
        dc.l $110B1FD,$110F106,$111301D,$1116F43,$111AE78,$111EDBB,$1122D0D
        dc.l $1126C6D,$112ABDC,$112EB5A,$1132AE6,$1136A81,$113AA2B,$113E9E4
        dc.l $11429AB,$1146981,$114A966,$114E959,$115295C,$115696D,$115A98D
        dc.l $115E9BB,$11629F9,$1166A45,$116AAA1,$116EB0B,$1172B84,$1176C0C
        dc.l $117ACA3,$117ED48,$1182DFD,$1186EC1,$118AF94,$118F075,$1193166
        dc.l $1197266,$119B374,$119F492,$11A35BF,$11A76FB,$11AB845,$11AF9A0
        dc.l $11B3B09,$11B7C81,$11BBE08,$11BFF9F,$11C4144,$11C82F9,$11CC4BD
        dc.l $11D0691,$11D4873,$11D8A65,$11DCC66,$11E0E76,$11E5095,$11E92C4
        dc.l $11ED502,$11F1750,$11F59AC,$11F9C18,$11FDE94,$120211E,$12063B9
        dc.l $120A662,$120E91B,$1212BE3,$1216EBB,$121B1A2,$121F499,$122379F
        dc.l $1227AB5,$122BDDA,$123010F,$1234453,$12387A7,$123CB0A,$1240E7D
        dc.l $1245200,$1249592,$124D934,$1251CE5,$12560A6,$125A477,$125E857
        dc.l $1262C47,$1267047,$126B456,$126F876,$1273CA5,$12780E3,$127C532
        dc.l $1280990,$1284DFE,$128927C,$128D70A,$1291BA7,$1296055,$129A512
        dc.l $129E9DF,$12A2EBC,$12A73A9,$12AB8A6,$12AFDB3,$12B42D0,$12B87FD
        dc.l $12BCD3A,$12C1287,$12C57E4,$12C9D50,$12CE2CD,$12D285A,$12D6DF8
        dc.l $12DB3A5,$12DF962,$12E3F2F,$12E850D,$12ECAFB,$12F10F8,$12F5706
        dc.l $12F9D25,$12FE353,$1302992,$1306FE1,$130B640,$130FCAF,$131432F
        dc.l $13189BF,$131D05F,$1321710,$1325DD1,$132A4A2,$132EB84,$1333276
        dc.l $1337978,$133C08B,$13407AE,$1344EE2,$1349626,$134DD7B,$13524E0
        dc.l $1356C56,$135B3DC,$135FB73,$136431A,$1368AD2,$136D29A,$1371A73
        dc.l $137625D,$137AA57,$137F262,$1383A7E,$13882AA,$138CAE7,$1391334
        dc.l $1395B93,$139A402,$139EC81,$13A3512,$13A7DB3,$13AC665,$13B0F28
        dc.l $13B57FC,$13BA0E1,$13BE9D6,$13C32DC,$13C7BF3,$13CC51B,$13D0E54
        dc.l $13D579E,$13DA0F9,$13DEA65,$13E33E1,$13E7D6F,$13EC70E,$13F10BE
        dc.l $13F5A7E,$13FA450,$13FEE33,$1403827,$140822C,$140CC42,$141166A
        dc.l $14160A2,$141AAEC,$141F546,$1423FB2,$1428A30,$142D4BE,$1431F5E
        dc.l $1436A0E,$143B4D1,$143FFA4,$1444A89,$144957F,$144E086,$1452B9F
        dc.l $14576C9,$145C204,$1460D51,$14658AF,$146A41F,$146EFA0,$1473B32
        dc.l $14786D6,$147D28C,$1481E53,$1486A2B,$148B615,$1490211,$1494E1E
        dc.l $1499A3D,$149E66D,$14A32AF,$14A7F03,$14ACB68,$14B17DF,$14B6467
        dc.l $14BB101,$14BFDAD,$14C4A6B,$14C973A,$14CE41C,$14D310E,$14D7E13
        dc.l $14DCB2A,$14E1852,$14E658C,$14EB2D8,$14F0036,$14F4DA6,$14F9B27
        dc.l $14FE8BB,$1503660,$1508418,$150D1E1,$1511FBD,$1516DAA,$151BBAA
        dc.l $15209BB,$15257DF,$152A614,$152F45C,$15342B5,$1539121,$153DF9F
        dc.l $1542E2F,$1547CD2,$154CB86,$1551A4D,$1556925,$155B811,$156070E
        dc.l $156561D,$156A53F,$156F473,$15743BA,$1579313,$157E27E,$15831FB
        dc.l $158818B,$158D12D,$15920E2,$15970A9,$159C082,$15A106E,$15A606D
        dc.l $15AB07E,$15B00A1,$15B50D7,$15BA120,$15BF17B,$15C41E8,$15C9269
        dc.l $15CE2FB,$15D33A1,$15D8459,$15DD524,$15E2601,$15E76F1,$15EC7F4
        dc.l $15F190A,$15F6A32,$15FBB6D,$1600CBB,$1605E1C,$160AF8F,$1610115
        dc.l $16152AE,$161A45A,$161F619,$16247EB,$16299D0,$162EBC7,$1633DD2
        dc.l $1638FEF,$163E220,$1643463,$16486BA,$164D923,$1652BA0,$1657E30
        dc.l $165D0D2,$1662388,$1667651,$166C92D,$1671C1C,$1676F1F,$167C234
        dc.l $168155D,$1686899,$168BBE9,$1690F4B,$16962C1,$169B64A,$16A09E6
        dc.l $16A5D96,$16AB159,$16B0530,$16B5919,$16BAD17,$16C0127,$16C554B
        dc.l $16CA983,$16CFDCE,$16D522C,$16DA69E,$16DFB24,$16E4FBD,$16EA469
        dc.l $16EF92A,$16F4DFD,$16FA2E5,$16FF7E0,$1704CEE,$170A210,$170F746
        dc.l $1714C90,$171A1ED,$171F75F,$1724CE3,$172A27C,$172F828,$1734DE9
        dc.l $173A3BD,$173F9A5,$1744FA0,$174A5B0,$174FBD3,$175520B,$175A856
        dc.l $175FEB5,$1765529,$176ABB0,$177024B,$17758FA,$177AFBE,$1780695
        dc.l $1785D80,$178B480,$1790B94,$17962BB,$179B9F7,$17A1147,$17A68AB
        dc.l $17AC024,$17B17B1,$17B6F51,$17BC707,$17C1ED0,$17C76AE,$17CCEA0
        dc.l $17D26A6,$17D7EC1,$17DD6F0,$17E2F33,$17E878B,$17EDFF8,$17F3878
        dc.l $17F910D,$17FE9B7,$1804275,$1809B48,$180F42F,$1814D2B,$181A63B
        dc.l $181FF60,$182589A,$182B1E8,$1830B4A,$18364C2,$183BE4E,$18417EF
        dc.l $18471A4,$184CB6F,$185254E,$1857F41,$185D94A,$1863367,$1868D9A
        dc.l $186E7E1,$187423D,$1879CAE,$187F733,$18851CE,$188AC7E,$1890742
        dc.l $189621C,$189BD0A,$18A180E,$18A7326,$18ACE54,$18B2997,$18B84EF
        dc.l $18BE05C,$18C3BDE,$18C9775,$18CF321,$18D4EE3,$18DAABA,$18E06A6
        dc.l $18E62A7,$18EBEBE,$18F1AEA,$18F772B,$18FD381,$1902FED,$1908C6E
        dc.l $190E905,$19145B1,$191A272,$191FF49,$1925C35,$192B937,$193164E
        dc.l $193737B,$193D0BD,$1942E15,$1948B83,$194E906,$195469E,$195A44D
        dc.l $1960211,$1965FEA,$196BDDA,$1971BDF,$19779F9,$197D82A,$1983670
        dc.l $19894CC,$198F33E,$19951C6,$199B064,$19A0F17,$19A6DE0,$19ACCC0
        dc.l $19B2BB5,$19B8AC0,$19BE9E1,$19C4918,$19CA865,$19D07C8,$19D6742
        dc.l $19DC6D1,$19E2676,$19E8632,$19EE603,$19F45EB,$19FA5E9,$1A005FD
        dc.l $1A06627,$1A0C668,$1A126BE,$1A1872C,$1A1E7AF,$1A24848,$1A2A8F8
        dc.l $1A309BF,$1A36A9B,$1A3CB8F,$1A42C98,$1A48DB8,$1A4EEEE,$1A5503B
        dc.l $1A5B19E,$1A61318,$1A674A9,$1A6D650,$1A7380D,$1A799E1,$1A7FBCC
        dc.l $1A85DCD,$1A8BFE5,$1A92214,$1A98459,$1A9E6B5,$1AA4928,$1AAABB2
        dc.l $1AB0E52,$1AB7109,$1ABD3D7,$1AC36BC,$1AC99B8,$1ACFCCA,$1AD5FF4
        dc.l $1ADC334,$1AE268B,$1AE89FA,$1AEED7F,$1AF511B,$1AFB4CE,$1B01899
        dc.l $1B07C7A,$1B0E073,$1B14482,$1B1A8A9,$1B20CE7,$1B2713C,$1B2D5A8
        dc.l $1B33A2C,$1B39EC6,$1B40378,$1B46841,$1B4CD22,$1B5321A,$1B59729
        dc.l $1B5FC4F,$1B6618D,$1B6C6E3,$1B72C4F,$1B791D4,$1B7F76F,$1B85D22
        dc.l $1B8C2ED,$1B928CF,$1B98EC9,$1B9F4DA,$1BA5B03,$1BAC144,$1BB279C
        dc.l $1BB8E0B,$1BBF493,$1BC5B32,$1BCC1E9,$1BD28B8,$1BD8F9E,$1BDF69C
        dc.l $1BE5DB2,$1BEC4E0,$1BF2C26,$1BF9383,$1BFFAF9,$1C06286,$1C0CA2B
        dc.l $1C131E9,$1C199BE,$1C201AB,$1C269B0,$1C2D1CE,$1C33A03,$1C3A250
        dc.l $1C40AB6,$1C47334,$1C4DBCA,$1C54478,$1C5AD3E,$1C6161C,$1C67F13
        dc.l $1C6E822,$1C75149,$1C7BA89,$1C823E0,$1C88D51,$1C8F6D9,$1C9607A
        dc.l $1C9CA34,$1CA3405,$1CA9DF0,$1CB07F3,$1CB720E,$1CBDC42,$1CC468E
        dc.l $1CCB0F3,$1CD1B70,$1CD8607,$1CDF0B5,$1CE5B7D,$1CEC65D,$1CF3156
        dc.l $1CF9C67,$1D00792,$1D072D5,$1D0DE30,$1D149A5,$1D1B533,$1D220D9
        dc.l $1D28C98,$1D2F871,$1D36462,$1D3D06C,$1D43C8F,$1D4A8CB,$1D51520
        dc.l $1D5818E,$1D5EE15,$1D65AB5,$1D6C76F,$1D73441,$1D7A12D,$1D80E31
        dc.l $1D87B4F,$1D8E887,$1D955D7,$1D9C341,$1DA30C4,$1DA9E60,$1DB0C16
        dc.l $1DB79E5,$1DBE7CD,$1DC55CF,$1DCC3EA,$1DD321F,$1DDA06D,$1DE0ED5
        dc.l $1DE7D56,$1DEEBF1,$1DF5AA5,$1DFC973,$1E0385B,$1E0A75C,$1E11677
        dc.l $1E185AB,$1E1F4F9,$1E26461,$1E2D3E3,$1E3437E,$1E3B334,$1E42303
        dc.l $1E492EC,$1E502EE,$1E5730B,$1E5E342,$1E65392,$1E6C3FD,$1E73481
        dc.l $1E7A520,$1E815D8,$1E886AB,$1E8F797,$1E9689E,$1E9D9BF,$1EA4AFA
        dc.l $1EABC4F,$1EB2DBF,$1EB9F48,$1EC10EC,$1EC82AA,$1ECF483,$1ED6676
        dc.l $1EDD883,$1EE4AAA,$1EEBCEC,$1EF2F48,$1EFA1BF,$1F01450,$1F086FC
        dc.l $1F0F9C2,$1F16CA2,$1F1DF9E,$1F252B3,$1F2C5E4,$1F3392F,$1F3AC95
        dc.l $1F42015,$1F493B0,$1F50766,$1F57B36,$1F5EF22,$1F66328,$1F6D748
        dc.l $1F74B84,$1F7BFDB,$1F8344C,$1F8A8D9,$1F91D80,$1F99242,$1FA0720
        dc.l $1FA7C18,$1FAF12B,$1FB665A,$1FBDBA3,$1FC5108,$1FCC688,$1FD3C23
        dc.l $1FDB1D9,$1FE27AA,$1FE9D97,$1FF139F,$1FF89C2

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

;	CNOP 0,4
;	ds.l 1	; pre-padding needed for word-alignment trick
;CDA_MixBuffer
;	ds.l SMP_BUFF_SIZE*2 ; *2 for stereo

CDA_MixBufferPtr    
    dc.l    0

InstrNames  ds.b    128*24

 ifne FAKE_AGUS
fake_agus_base  ds.b    1024
 endif
