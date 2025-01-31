; ====================================
; AmiGUS play routines for PS3M player
;        (c)2025 by O.Achten
; ====================================

	include amigus_proto.i
	include libraries/expansion_lib.i

;=============================================================
amigus_init:
	move.l	4.w,a6					
	lea   	ExpansionName(pc),a1	
	moveq   #33,d0
	jsr     _LVOOpenLibrary(a6)		; Open expansion.library
	tst.l   d0
	bne.s   .ag_open_okay

	moveq	#-1,d0					; Could not open library
	rts
.ag_open_okay
	move.l	d0,a6
	move.l	#AMIGUS_MANUFACTURER_ID,d0
	move.l	#AMIGUS_HAGEN_PRODUCT_ID,d1
	move.l	#0,a0
	jsr		_LVOFindConfigDev(a6)	; Check for AmiGUS card

	push	d0
	
	move.l	d0,a0
	move.l 	32(a0),d0 				; d0 = cd_BoardAddr
	move.l	d0,amigus_base			; Store AmiGUS register base
	
	move.l	a6,a1
	move.l	4.w,a6
	jsr     _LVOCloseLibrary(a6)	; Close expansion.library
	
	pop		d0
	tst.l	d0						; Did we find AmiGUS card?
	bne.s	.ag_init_memory

	moveq	#-1,d0					; Could not find AmiGUS card
	rts

.ag_init_memory
    bsr     allocPatternBuffers
	beq		.ag_memerror
	
	bsr		init
	bsr		FinalInit	
	
	move.l	4.w,a6
	move.b	#INTB_PORTS,d0
	lea		AmiGUS_IntServer(pc),a1	; Set-up interrupt for play routine (INT2)
	jsr		_LVOAddIntServer(a6)
	
	move.l	amigus_base(pc),a6		; a6 = AmiGUS register base

	move.l	setmodule(pc),a0		; a0 = Pointer to module (=sample) data
	move.l	setmodulelen(pc),d0		; d0 = Length of module data (in bytes)
	lsr.l	#2,d0
	
	moveq	#0,d4
	move.l	d4,HAGEN_WADDRH(a6)
	lea		HAGEN_WDATAH(a6),a1
.ag_memory_copyloop					; Copy entire module to AmiGUS sample memory
	move.l	(a0)+,(a1)
	sub.l	#1,d0
	bne		.ag_memory_copyloop
	
	bsr		amigus_voice_reset		; Initialize all AmiGUS voices
	
	move.w	tempo,d0				; d0 = tempo (BPM)
	bsr		amigus_tempo			; Set initial tempo
	move.w	#$c000,HAGEN_INTE0(a6)	; Enable interrupt
	
	moveq	#0,d0
	lea		PatternInfo(pc),a0
	move.l	unpackedPatternPtr,a1

	popm	d1-d7/a2-a6	
	rts
	
.ag_memerror
	popm	d1-d7/a2-a6		
	moveq	#ier_nomem,d0
	rts
;=============================================================
amigus_end:	
	move.l	amigus_base(pc),a6

	move.w	#$0000,HAGEN_TIMER_CTRL(a6)	; Disable Timer
	move.w	#$4000,HAGEN_INTE0(a6)		; Disable Timer interrupt
	move.w	#$4000,HAGEN_INTC0(a6)		; Clear Timer interrupt
	
	bsr		amigus_voice_reset
	
	move.l	4.w,a6
	lea		AmiGUS_IntServer(pc),a1
	moveq  	#INTB_PORTS,d0
	jsr		_LVORemIntServer(a6)

    bsr     freePatternBuffers
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
;=============================================================
amigus_update:	; d0 = volume? d1 = stereo level?
; Code for master volume update
	rts
;==============================================================
amigus_stop:
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
	st      setpause
	move.l	amigus_base(pc),a6
	bsr .ag_restorechannels
	move.w	#$c000,HAGEN_INTE0(a6)	; Enable interrupt
	rts
;---	
.ag_restorechannels
	lea	    cha0,a4
	move	numchans,d7
	subq	#1,d7
	moveq	#0,d6
.ag_restore_loop
	move.w	d6,HAGEN_VOICE_BNK(a6)	; Set channel number	
	bsr	amigus_volume	
	
	dbf		d7,.ag_restore_loop
	rts	
;==============================================================
amigus_tempo:
	movem.l d0-d7/a0-a6,-(sp)
	
	and.l	#$ff,d0
	lsl.w	#1,d0
	divu.w	#5,d0
	moveq	#0,d1
	move.w	d0,d1
	
	move.l	amigus_base(pc),a6

	move.w	#$0000,HAGEN_TIMER_CTRL(a6)	
	move.l 	#HAGEN_TIMER_TIMEBASE,d0
	bsr		divu_32
	move.l	d0,HAGEN_TIMER_RELOADH(a6)	; Set timer interrupt speed for playback
	move.w	#$8000,HAGEN_TIMER_CTRL(a6)
	
	movem.l (sp)+,d0-d7/a0-a6	; Restore registers
	rts
;=============================================================
amigus_playmusic:
    move.b  setpause(pc),d0
    bne.b   .ag_nopause
    rts
.ag_nopause
	pushm	d2-d7/a2-a6

	bsr		s3vol				; Update master volume

	move.l	amigus_base(pc),a6		; a6 = AmiGUS register base
	move.w	PS3M_master,d1			; Master Volume

	move	mtype,d0			; Select appropriate player routine
	lea		s3m_music(pc),a0
	subq	#1,d0
	beq.b	.ag_player_exe	
	lea		mt_music(pc),a0
	subq	#1,d0
	beq.b	.ag_player_exe	
	subq	#1,d0
	beq.b	.ag_player_exe	
	lea		xm_music(pc),a0
	subq	#1,d0
	beq.b  	.ag_player_exe	
	lea		it_music(pc),a0
.ag_player_exe	
	jsr	(a0)

	lea		cha0,a4				; a4 = Note structure
	move	numchans,d7			; d7 = Channel numbers
	subq	#1,d7
	moveq	#0,d6				; d6 = current channel number
.ag_channel_loop				; Main channel loop
	move.w	d6,HAGEN_VOICE_BNK(a6)	; Set channel number
	
	bsr 	amigus_volume
	bsr		amigus_period
	bsr		amigus_setrepeat

	tst		mPeriod(a4)
	beq.b	.ag_silence
	tst.b	mOnOff(a4)
	bne.b	.ag_silence			;sound off

	tst.l	mFPos(a4)
	bne.b	.ag_ty
	addq.l	#1,mFPos(a4)
	bsr		amigus_sample
    bsr     amigus_sample_scope
.ag_ty
.ag_silence
	bsr     amigus_data_scope

	lea		mChanBlock_SIZE(a4),a4	; Increment to next channel block
	addq	#1,d6
	dbf		d7,.ag_channel_loop

	popm	d2-d7/a2-a6
	rts
;---
amigus_volume:					; d6 = channel number, a4 = channel block; a6 = AmiGUS base
	move.w	mVolume(a4),d1					; Channel Volume
	lsl.w 	#7,d1
	btst	#0,d6
	beq.b	.ag_even_ch
	move.w	d1,HAGEN_VOICE_VOLUMEL(a6)
	move.w	#0,HAGEN_VOICE_VOLUMER(a6)
	rts
.ag_even_ch
	move.w	#0,HAGEN_VOICE_VOLUMEL(a6)
	move.w	d1,HAGEN_VOICE_VOLUMER(a6)
	rts
;---
amigus_period:
	move.l	clock,d0			; Get frequency base
	lsl.l	#2,d0
	
	moveq	#0,d1
	move.w	mPeriod(a4),d1		; Get note value
	beq		.ag_period_exit		; Prevent division by 0
	divu.w	d1,d0				; Convert to frequency
	
	moveq	#0,d1				
	move.w	d0,d1				; Get rid of the remainder
	
	move.w	#$15d8,d0			; Convert to AmiGUS register value
	mulu	d1,d0
	
	move.l	d0,HAGEN_VOICE_RATEH(a6)	; Update note frequency
.ag_period_exit	
	rts
;---	
amigus_setrepeat:
	move.w	ahi_use,d0
	cmp.w	#-1,d0
	bne		.ag_interpolated
	move.w	#$8000,d0
	tst.b	mLoop(a4)
	beq.b	.ag_norepeat
	move.w	#$8002,d0
	move.w	d0,amigus_mtrig
	rts
	
.ag_interpolated
	move.w	#$8004,d0
	tst.b	mLoop(a4)
	beq.b	.ag_norepeat
	move.w	#$8006,d0
	move.w	d0,amigus_mtrig
	rts
.ag_norepeat
	move.w	d0,amigus_mtrig	
	rts
;---
amigus_sample:
	move.l	mStart(a4),d2
	move.l	mLength(a4),d3
	sub.l	s3m,d2

	cmp.l	#4,d3
	bhs.b	.ag_length_ok
	
	clr.w	amigus_mtrig
	
.ag_length_ok
	move.w	amigus_mtrig(pc),d1	
	clr.w	HAGEN_VOICE_CTRL(a6)		; Temporarily disable voice playback
	
	move.l	d2,HAGEN_VOICE_PSTRTH(a6)	; Update pointers
	move.l	d2,HAGEN_VOICE_PLOOPH(a6)
	add.l	d2,d3	
	move.l	d3,HAGEN_VOICE_PENDH(a6)
	
	move.w	d1,HAGEN_VOICE_CTRL(a6)	; Re-trigger voice
	rts
;---	
amigus_sample_scope
    cmp     #3,d6
    bls     .ag_ok
    rts
.ag_ok
    move.l  scopeData,a0
    move    d6,d0
    lsl     #4,d0
    add     d0,a0

    move.l  mStart(a4),ns_start(a0)
    move.l  mLength(a4),d0
    lsr.l   #1,d0
    move    d0,ns_length(a0)
	rts
;---
amigus_data_scope:
    cmp     #3,d6
    bls     .ag_ok_ds
    rts
.ag_ok_ds
    move.l  scopeData,a0
    move    d6,d0
    lsl     #4,d0
    add     d0,a0

    move    mVolume(a4),ns_tempvol(a0)
    * mPeriod is 4x, convert back
    move    mPeriod(a4),d0
    lsr     #2,d0
    move    d0,ns_period(a0)

    clr.l   ns_loopstart(a0)
    clr.w   ns_replen(a0)

	tst.b	mLoop(a4)
	beq 	.ag_noLoop
    move.l  mLStart(a4),ns_loopstart(a0)
    move.l  mLLength(a4),d0
    lsr.l   #1,d0
    move    d0,ns_replen(a0)

.ag_noLoop
    tst.l   ns_loopstart(a0)
    bne.b   .ag_1
    move.l  #emptyScopeWord,ns_loopstart(a0)
.ag_1  
	tst.w   ns_replen(a0)
    bne     .ag_2
    move.w  #1,ns_replen(a0)
.ag_2  
	rts
;======================================

AmiGUS_Int:
	movem.l d1-d7/a0-a6,-(sp)	; Save registers

	move.l	amigus_base(pc),a6

	move.w	HAGEN_INTC0(a6),d0			; read interrupt status
	and.w   #$4000,d0					; did AmiGUS Timer IRQ occur?
	beq		.noTimerInt					; if not, then there is nothing to do here	
	
	move.w	#$0f0f,$dff180		
	move.w	#$4000,HAGEN_INTC0(a6)	; Clear interrupt

	bsr	amigus_playmusic
	move.w	#$8888,$dff180		
.noTimerInt	

	movem.l (sp)+,d1-d7/a0-a6	; Restore registers
	moveq	#0,d0
	rts
	
;======================================
amigus_base		dc.l	0
amigus_mtrig	dc.w	0

AmiGUS_IntServer
	dc.l  0,0
	dc.b  0,-10
	dc.l  AmiGUS_IntName
	dc.l  0,AmiGUS_Int
	
ExpansionName	dc.b	"expansion.library",0

AmiGUS_IntName	dc.b	"AmiGUS_PS3MPlay",0
even