;APS0000ACF50000D59D0000009100000091000000910000009100000091000000910000009100000091
	incdir	include:
	include	exec/exec_lib.i
	include	exec/memory.i
	include	misc/eagleplayer.i
	include	mucro.i


	* Scope data for one channel
              rsreset
ns_start      rs.l       1 * Sample start address
ns_length     rs         1 * Length in words
ns_loopstart  rs.l       1 * Loop start address
ns_replen     rs         1 * Loop length in words
ns_vol    rs         1 * Volume
ns_period     rs         1 * Period
ns_size       rs.b       0 * = 16 bytes

* Combined scope data structure
              rsreset
scope_ch1	  rs.b	ns_size
scope_ch2	  rs.b	ns_size
scope_ch3	  rs.b	ns_size
scope_ch4	  rs.b	ns_size
scope_trigger rs.b  1 * Audio channel enable DMA flags
scope_pad	  rs.b  1
scope_size    rs.b  0

TESTI	=	0

 ifne TESTI

	lea	mod,a0
	lea	mastervol,a1
	lea	songend_,a2
	lea	tempofunc,a3
	lea	scope_,a4
	jsr	init
	bne	exit
loop
	cmp.b	#$80,$dff006
	bne.b	loop
.x	cmp.b	#$80,$dff006
	beq.b	.x

	move	#$ff0,$dff180
	jsr	play
	clr	$dff180

	btst	#6,$bfe001
	bne.b	loop

	jsr	end
exit
	rts


tempofunc
	rts

mastervol	dc	64/1
songend_		dc	0
scope_		ds.b scope_size

	section	dd,data_c
mod
	incbin	"m:exo/art of noise/AON4.last_ninja-2_end"
	
	section	aon,code
 endif

start

	jmp init(pc) 
	jmp play(pc)
	jmp end(pc) 
	jmp stop(pc)
	jmp continue(pc)

master		dc.l	0
ciasetter	dc.l 	0
songend		dc.l 	0
AON_leer	dc.l 	0
scopeAddr	dc.l	0

* a0 = module
* a1 = main vol
* a2 = songend 
* a3 = cia timer setter func
* a4 = scope data
init
	move.l	a4,scopeAddr
	lea	master(pc),a4
	move.l	a1,(a4)
	lea	songend(pc),a4  
	move.l	a2,(a4)
	lea	ciasetter(pc),a4  
	move.l	a3,(a4)

	push	a0
	move.l	4.w,a6
	move.l	#256,d0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	lore	Exec,AllocMem
	lea	AON_leer(pc),a0 
	move.l	d0,(a0)
	pop	a0
	tst.l	d0
	beq.b	.err
	
	moveq #0,d0 * start pos
	bsr.w	AON_INITFIX
	bne.b	.err
	bsr.w	PatternInit
	moveq	#0,d0 
	rts 

.err
	moveq	#-1,d0 
	rts

play 
	bsr.w AON_PLAYCIA

	moveq	#0,d0 
	moveq	#0,d1 
	LEA	AON_DATA(PC),A0
	move.l	aon_statdata(a0),a1
	move.b	aon.songinfo_maxpos(a1),d1	; get maxpos
	move.b	aon_pos(a0),d0 
	rts 

end 	
	bsr.w	AON_END

	lea	AON_leer(pc),a2
	move.l	(a2),d0
	beq.b 	.x
	clr.l	(a2)
	move.l	d0,a1 
	move.l	#256,d0
	move.l	4.w,a6
	lob	FreeMem
.x	rts 

stop
	clr	$dff0a8
	clr	$dff0b8
	clr	$dff0c8
	clr	$dff0d8
	rts

* Restore volume
continue
			push	a5
			LEA	AON_CHANNELS(PC),A0
			moveq	#4-1,d1
			lea	$dff0a0,a1
.loop4		
			moveq	#0,d0
			move.b	aon_volume(a0),d0
			moveq	#0,d2
			move.b	aon_synthVOL(a0),d2
			lsr.b	#1,d2
			mulu	d2,d0
			lsr	#6,d0
			mulu	aon_trackvol(a0),d0
			lsr	#6,d0
			move.l	master(pc),a2
			mulu	(a2),d0
			lsr	#6,d0
			move	d0,8(a1)

			move.l	a1,a5
			bsr	setVol

			lea	aon_chdatasize(a0),a0
			lea 	$10(a1),a1
			dbf	d1,.loop4
			pop	a5
			rts



setVol
	push	a5
	sub.l	#$dff0a0,a5
	add.l	scopeAddr(pc),a5
	move	d0,ns_vol(a5)
	pop	a5
	rts

setPer
	push	a5
	sub.l	#$dff0a0,a5
	add.l	scopeAddr(pc),a5
	move	d0,ns_period(a5)
	pop	a5
	rts

setAddr
	push	a5
	sub.l	#$dff0a0,a5
	add.l	scopeAddr(pc),a5
	move.l	d0,ns_start(a5)
	move	d1,ns_length(a5)
	move.l	d0,ns_loopstart(a5)
	move	d1,ns_replen(a5)
	pop	a5
	rts

setRep
	push	a5
	sub.l	#$dff0a0,a5
	add.l	scopeAddr(pc),a5
	move.l	d0,ns_loopstart(a5)
	move	d1,ns_replen(a5)
	pop	a5
	rts


PatternInfo
	ds.b	PI_Stripes	
Stripe1	dc.l	1
Stripe2	dc.l	1
Stripe3	dc.l	1
Stripe4	dc.l	1

PatternInit
	lea	PatternInfo(PC),A0
	move.w	#4,PI_Voices(A0)	; Number of stripes (MUST be at least 4)
	pea	ConvertNote(pc) 
	move.l	(sp)+,PI_Convert(a0)
	move.l	#4+4+4+4,PI_Modulo(A0)	; Number of bytes to next row
	move.w	#64,PI_Pattlength(A0)	; Length of each stripe in rows
	clr.w	PI_Pattpos(A0)		; Current Position in Pattern (from 0)
	move	#-1,PI_Speed(a0)	; Magic! Indicates notes, not periods
	rts

* Called by the PI engine to get values for a particular row
ConvertNote
	moveq	#0,D0		; Period, Note
	moveq	#0,D1		; Sample number
	moveq	#0,D2		; Command 
	moveq	#0,D3		; Command argument

	* note: zero = no note

	moveq	#63,d0
	and.b	(a0),d0
	
	moveq	#%00111111,d1
	and.b	1(a0),d1

	* MAX is "z", $7a
	moveq	#$3f,d2
	and.b	2(a0),d2

	move.b	3(a0),d3
	rts


****************************************************************************

PLAYERSTART
;
; Program	:	Art Of Noise - playerSource for 4 channel modules
; Author	:	Bastian Spiegel (Twice/Lego)
; Date		:	(last change) 6.february 1995

; Notes		:
;			100% PC-Relativ !!
;			Easy to use in own productions!!!
;			In case of an player+mod file, just jump to
;			�FILESTART+0� to init-cia&start module
;			and jump to �FILESTART+4� to free-cia&stop module!!
;			To start any other module, just make sure that
;			all cia-irqs are free (normally this is the case..)
;			and make a jump to �FILESTART+8�. Be sure that
;			a0 contains the module-startadr and d0 the song-
;			startposition!!

; ----------------------------------------------------------------------------
; OFFSET	DESCR
; ----------------------------------------------------------------------------
; 0		�init player+mod�	inits module stored right after player
;					d0=Startposition
; ----------------------------------------------------------------------------
; 4		�end�			ends module
; ----------------------------------------------------------------------------
; 8		�init mod�		inits module
;					a0=Moduleaddress
;					d0=Startposition
; ----------------------------------------------------------------------------
; 12		�read events�		reads current eventlist
;					returns a ptr (a0) to the following
;					datafield:
;					OFFSET	DESCR
;					0	event-nr �1�
;					1	event-nr �2�
;					2	event-nr �3�
; NOTE: Events should be resetted to ZERO after reading, in order to avoid
;	double triggering !	( clr.b ?(a0) )
; ----------------------------------------------------------------------------

aon_timerval		=1773447/3		;PAL!!

; /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

; ## AON-INCLUDES ##

aon.songinfo_mfver	=0
aon.songinfo_maxpos	=1
aon.songinfo_respos	=2

aon.instrtypeSample8bit	=0
aon.instrtypeSynth1	=1

			rsreset
instr_control		rs.b	1	; Instr-Type (check out aon.instrtypexxxxx)
instr_volume		rs.b	1	; volume 0-64
instr_finetune		rs.b	1	; finetune -7 to 7  bits 4-7 are unused
instr_waveform		rs.b	1	; waveform 0-63

; Sample 8 bit
			rsset	4
sample8_dmaoffset	rs.l	1	; Sampleoffset/2 (words)
sample8_dmalen		rs.l	1	; Samplelen/2 (words)
sample8_dmarepoffset	rs.l	1	; Repeatstrt/2 (words)
sample8_dmareplen	rs.l	1	; Repeatlen/2 (words)

; Wavetable 8 bit
			rsset	4
synth8_partwaveDMALen	rs.b	1	; in words (--> up to 512 bytes)

			rs.b	1	; Unused
			rs.b	1
			rs.b	1
			rs.b	1
			rs.b	1

synth8_VIBpara		rs.b	1	; the same param. like with effect '4'
synth8_vibdelay		rs.b	1	; framecnt
synth8_vibwave		rs.b	1	; sine,triangle,rectangle
synth8_WAVEspd		rs.b	1	; framecnt
synth8_WAVElen		rs.b	1
synth8_WAVErep		rs.b	1
synth8_WAVEreplen	rs.b	1
synth8_WAVErepCtrl	rs.b	1	; 0=Repeatnormal/1=Backwards/1=PingPong

			rsset	32-4
instr_Astart		rs.b	1	; Vol_startlevel
instr_Aadd		rs.b	1	; Zeit bis maximalLevel
instr_Aend		rs.b	1	; Vol_endlevel
instr_Asub		rs.b	1	; Zeit bis endlevel



;--------------------------------------------------------------------
;--------------------------------------------------------------------
; AON-JUMPTABLE:
;			BRA.W	AON_INITFIX
;			BRA.W	AON_END
;			BRA.W	AON_INIT
;			BRA.W	AON_READEVENTS

;--------------------------------------------------------------------
;--------------------------------------------------------------------
; CIA B allokieren
;ALLOCCIAB
;			movem.l	d1-a6,-(sp)
;			lea	TimerIntServerB+10(pc),a0
;			lea	TimerIntNameB(pc),a1
;			move.l	a1,(a0)
;
;			move.l	4,a6
;			moveq	#0,d0
;			lea	CiaBName(pc),a1
;			jsr	-498(a6)	; openresource
;			lea	CiaBBase(pc),a1
;			move.l	d0,(a1)
;			beq.b	CiaErrorB	; Resource ge�ffnet?!
;
;			move.l	d0,a6
;
;			lea	TimerIntServerB(pc),a1
;			LEA	AON_PLAYCIA(PC),A0
;			move.l	a0,18(a1)
;			moveq	#1,d0			; bit 1: timer b
;			jsr	-6(a6)		; Timer-Interrupt dazu
;			tst.l	d0
;			bne.b	CiaErrorB	; Installiert?!?!?!
;
;			move.b	#$79,$bfd600
;			move.b	#$12,$bfd700
;			bset	#0,$bfdf00	; Timer Start
;			movem.l	(sp)+,d1-a6
;			rts
;--------------------------------------------------------------------
;FREECIAB	
;			movem.l	d1-a6,-(sp)
;			bclr	#0,$bfdf00		; Timer B STOP
;			move.l	CiaBBase(pc),a6
;			lea	TimerIntServerB(pc),a1
;			moveq	#1,d0			; Timer-B
;			jsr	-12(a6)			; freigeben
;			movem.l	(sp)+,d1-a6
;			moveq	#0,d0
;			rts
;CiaErrorB		moveq	#-1,d0
;			movem.l	(sp)+,d1-a6
;			rts
;CiaBName		dc.b	"ciab.resource",0
;CiaBBase		dc.l	0
;			even
;TimerIntServerB		dc.l	0,0
;			dc.b	2,99 ; type, priority
;			dc.l	0		;TimerIntnameB
;			dc.l	0,0
;TimerIntNameB		dc.b	"ArtOfNoise- 4ch-player",0
;			even


;========================================================================
; IN:	d0=Startpos
; OUT:	d0= result (0=ok,-1=error occured)
AON_INITFIX		;lea	mod(pc),a0

;========================================================================
; IN:	d0=Startpos
;	a0=Moduleadr
; OUT:	d0= result (0=ok,-1=error occured)
AON_INIT
			movem.l	d1-d7/a0-a6,-(sp)


			cmp.l	#"AON4",(a0)
			BNE.W	AON_NOTINITALIZED

			LEA	AON_DATA(PC),A6
			move	#aon_datasize-1,d7
.clraondata		clr.b	(a6,d7)
			dbf	d7,.clraondata

			move.b	#6,aon_speed(a6)
			move.b	d0,aon_pos(a6)


			move.l	a0,aon_modulestart(a6)

			move.l	#"INFO",d0
			bsr.w	aon_searchchunk
			move.l	a1,aon_statdata(a6)
			move.l	#"ARPG",d0
			bsr.w	aon_searchchunk
			move.l	a1,aon_arpdata(a6)
			move.l	#"PLST",d0
			bsr.w	aon_searchchunk
			move.l	a1,aon_posdata(a6)
			move.l	#"PATT",d0
			bsr.w	aon_searchchunk
			move.l	a1,aon_pattdata(a6)

			move.l	#"INST",d0
			bsr.w	aon_searchchunk

			lea	aon_instrstarts(a6),a2
			moveq	#61-1,d7
aon_initinstradrtab	move.l	a1,(a2)+
			lea	32(a1),a1
			dbf	d7,aon_initinstradrtab

			move.l	#"WLEN",d0
			bsr.w	aon_searchchunk
			move.l	a1,a3			; a3=ptr on wlen-tab
			move.l	#"WAVE",d0
			bsr.w	aon_searchchunk		; a1=ptr on wave-adr0
			lea	aon_wavestarts(a6),a2
			move.l	a1,d0
			moveq	#64-1,d7
aon_initwavetab		move.l	d0,(a2)+
			add.l	(a3)+,d0
			dbf	d7,aon_initwavetab

			LEA	AON_CHANNELS(PC),A0
			move	#aon_chdatasize-1,d7
.clrch			clr.l	(a0)+
			dbf	d7,.clrch

			LEA	AON_CHANNELS(PC),A0
			moveq	#64,d0
			moveq	#4-1,d7
.loop4			clr.l	aon_waveform(a0)
			clr	aon_wavelen(a0)
			clr	aon_oldwavelen(a0)
			clr.l	aon_repeatstrt(a0)
			clr	aon_replen(a0)
			clr.l	aon_instrptr(a0)
			clr.b	aon_volume(a0)
			clr	aon_perslide(a0)
			clr.l	aon_synthWAVErepPTR(a0)
			clr.l	aon_synthWAVErependPTR(a0)
			clr.l	aon_synthWAVEactPTR(a0)
			clr.l	aon_synthWAVEendPTR(a0)
			clr.b	aon_synthWAVErepctrl(a0)
			clr.b	aon_synthWAVEspd(a0)
			clr.b	aon_synthWAVEcnt(a0)
			clr.b	aon_synthwaveSTOP(a0)
			move	d0,aon_trackvol(a0)
			lea	aon_chdatasize(a0),a0
			dbf	d7,.loop4

			bset	#1,$bfe001

			;bsr.w	allocCIAB
			;tst	d0
			;bmi.b	aon_notinitalized
			bsr.w	aon_resettimer


			movem.l	(sp)+,d1-d7/a0-a6
			moveq	#0,d0
			rts
aon_searchchunk		move.l	a0,a1
.search			cmp.l	(a1),d0
			beq.b	.ok
			addq.l	#2,a1
			bra.b	.search
.ok			addq.l	#8,a1
			rts


AON_NOTINITALIZED	movem.l	(sp)+,d1-d7/a0-a6
			moveq	#-1,d0		; yep,seems that an error
			rts			; has occured... bad luck..!

;========================================================================
; Return ptr to �aon_eventlist� in a0
AON_READEVENTS		lea	aon_event(pc),a0
			rts
;========================================================================
AON_END
			;bsr.w	freeCIAB
			move	#$ff,$dff09e	; no modulation
			move	#$f,$dff096	; DMA off
			clr	$dff0a8
			clr	$dff0b8
			clr	$dff0c8
			clr	$dff0d8
			rts
;========================================================================
AON_PLAYCIA		movem.l	d1-a6,-(sp)
			lea	AON_DATA(pc),a6
			tst.b	aon_dmaflag(a6)
			beq.b	.setsamples
			cmp.b	#1,aon_dmaflag(a6)
			beq.b	.setdma
			bsr.w	AON_SETREPEATS
.out			movem.l	(sp)+,d1-a6
			moveq	#0,d0
			rts
.setsamples
;	move	#$0f0,$dff180
			bsr.b	AON_PLAY
;	move	#$aab,$dff180
			bra.b	.out
.setdma			bsr.b	AON_SETDMA
			bra.b	.out
;========================================================================
AON_PLAY		

			addq.b	#1,aon_framecnt(a6)
			move.b	aon_speed(a6),d0
			beq.b	aon_playcurrent_nonewpos2
			cmp.b	aon_framecnt(a6),d0
			bhi.b	aon_playcurrent_nonewpos2
			clr.b	aon_framecnt(a6)

			bsr.w	aon_playnewstep
aon_playcurrent_nonewpos2
			bra.w	AON_PLAYFX

;---------------------- Effekte & Samplestarts ----------------------
AON_PLAYFX		
			moveq	#0,d7
			move.b	aon_pos(a6),d7
			move.l	aon_posdata(a6),a1	; get start of posdat
			moveq	#0,d0
			move.b	(a1,d7),d0		; d7=act. pos + choff
			move.b	d0,acteditpattern(a6)


			lea	AON_DOFX(pc),a1
			; do effect command
			LEA	AON_CHANNELS(PC),a4
			jsr	(a1)
			lea	aon_chdatasize(a4),a4
			jsr	(a1)
			lea	aon_chdatasize(a4),a4
			jsr	(a1)
			lea	aon_chdatasize(a4),a4
			jsr	(a1)

			moveq	#0,d1			; Make channel-mask
			moveq	#0,d7
			lea	AON_STARTINSTR.1-AON_DOFX(a1),a1

			lea	AON_CHANNELS(pc),a4	; do effect command
			lea	$dff0a0,a5
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)

			move	d1,-$4a(a5)		; Channels off
			or	#$8000,d1
			move	d1,aon_dmacon(a6)
			move.b	#1,aon_dmaflag(a6)	; set repeats
			rts
;========================================================================
AON_SETDMA:
			move.b	#2,aon_dmaflag(a6)
			move	aon_dmacon(a6),$dff096
			rts
;========================================================================
AON_SETREPEATS:
			clr.b	aon_dmaflag(a6)		; set samples
			lea	AON_CHANNELS(pc),a4
			lea	$dff0a0,a5
			lea	AON_STARTINSTR.2(pc),a1
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)
			jmp	(a1)
;========================================================================
;---------------------- Neuen Step auslesen -------------------------
aon_playnewstep
			cmp.b	#$ff,aon_patcnt(a6)
			beq.w	aon_breakpat

; read new step
aon_getstep
			tst.b	aon_patdelaycnt+1(a6)
			bmi.s	aon_nopatdelay
			beq.s	aon_nopatdelay
			subq.b	#1,aon_patdelaycnt+1(a6)
			bra.w	aon_playcurrent_nonewposX
aon_nopatdelay		move.b	#-1,aon_patdelaycnt+1(a6)
	
			lea	AON_CHANNELS(pc),a4
			lea	AON_multab120(pc),a5	; needed for periodtab

			moveq	#0,d0
			move.b	acteditpattern(a6),d0
			move.l	aon_pattdata(a6),a0	; get start of patdat
			moveq	#10,d1
			lsl.l	d1,d0			; patnr*1024=patoff
			lea	(a0,d0.l),a0		; add to start of data

			push 	a1
			move.l a0,a1
			move.l a1,Stripe1
			addq	#4,a1
			move.l a1,Stripe2
			addq	#4,a1
			move.l a1,Stripe3
			addq	#4,a1
			move.l a1,Stripe4
			pop 	a1
			move	aon_patcnt(a6),d1	* increments of 4
			lsr 	#2,d1
			move	d1,PatternInfo+PI_Pattpos

			move	aon_patcnt(a6),d1
			add	d1,d1			; *4 bcoz 1 Pattern
			add	d1,d1			; =4 Channels
			lea	(a0,d1.l),a0		; add pattcounter

; a0=pointer on actual step
			bsr.b	AON_GETDACHANNEL	; get first channel
			lea	aon_chdatasize(a4),a4
			addq.l	#4,a0
			bsr.b	AON_GETDACHANNEL	; get second channel
			lea	aon_chdatasize(a4),a4
			addq.l	#4,a0
			bsr.b	AON_GETDACHANNEL	; get third channel
			lea	aon_chdatasize(a4),a4
			addq.l	#4,a0
			bsr.b	AON_GETDACHANNEL	; get fourth channel

			tst.b	aon_loopflag(a6)
			beq.s	aon_nolooping
			clr.b	aon_loopflag(a6)
			move.b	aon_looppoint(a6),aon_patcnt+1(a6)
			bra.b	aon_playcurrent_nonewposX
aon_nolooping		addq.b	#4,aon_patcnt+1(a6)
			bne.b	aon_playcurrent_nonewposX  ; End of pattern??
aon_breakpat		

			clr.b	aon_patdelaycnt+1(a6)
			clr	aon_looppoint(a6)
			addq.b	#1,aon_pos(a6)	; pos=pos+1
			move.l	aon_statdata(a6),a3
			move.b	aon.songinfo_maxpos(a3),d0	; get maxpos
			cmp.b	aon_pos(a6),d0	; End of song ??
			bhi.b	aon_playcurrent2
			move.b	aon.songinfo_respos(a3),aon_pos(a6) ; Get restart pos!

			push	a0 
			move.l 	songend(pc),a0 
			st      (a0)
			pop   	a0

aon_playcurrent2	tst.b	aon_patcnt(a6)
			beq.b	aon_playcurrent_nonewposX
			clr.b	aon_patcnt(a6)

			moveq	#0,d7
			move.b	aon_pos(a6),d7
			move.l	aon_posdata(a6),a1	; get start of posdat
			moveq	#0,d0
			move.b	(a1,d7),d0		; d7=act. pos + choff
			move.b	d0,acteditpattern(a6)

			bra.w	aon_getstep
aon_playcurrent_nonewposX
			rts
;========================================================================
; a6=data
; get new step ...!
AON_GETDACHANNEL
			move.b	2(a0),aon_fxCOM(a4)	; needed l8r on
			and.b	#$3f,aon_fxCOM(a4)
			move	2(a0),d0
			and	#$3fff,d0
			move.b	d0,d1
			move.b	d0,aon_fxDAT(a4)
			cmp.b	#$d,aon_fxCOM(a4)
			bne.b	.nobreak
			cmp.b	#$100-4,aon_patcnt+1(a6)
			bne.b	.nobreak
			move.b	#$100-8,aon_patcnt+1(a6)
.nobreak

			and.b	#$f0,d0
			and.b	#$0f,d1

			clr.b	aon_stepfxcnt(a4)

			cmp.b	#16,aon_fxCOM(a4)	; 'g' volset
			bne.b	.novoldel
			move.b	aon_fxDAT(a4),d2
			and.b	#$f,d2
			move.b	d2,aon_stepfxcnt(a4)
			bra.b	aon_gdc_nomoreFX
.novoldel
			cmp	#$0ec0,d0
			bne.s	aon_gdc_nonotecut	; note cut ?
			move.b	d1,aon_stepfxcnt(a4)
			bra.b	aon_gdc_nomoreFX
aon_gdc_nonotecut
			cmp	#$0ee0,d0		; pattern delay?
			bne.s	aon_gdc_nopatdelay
			tst.b	aon_patdelaycnt+1(a6)	; delaying ?
			bpl.s	aon_gdc_nopatdelay
			move.b	d1,aon_patdelaycnt+1(a6) ; start delay!
			bra.b	aon_gdc_nomoreFX
aon_gdc_nopatdelay
			cmp	#$0e60,d0		; pattern loop?
			bne.s	aon_gdc_noloopreset
			cmp.b	#$f0,aon_loopcnt(a6)	; loop over flag set ?
			beq.s	aon_gdc_noloopreset
			tst.b	d1			; no loop?
			beq.s	aon_gdc_noloopreset

			tst.b	aon_loopcnt(a6)
			bne.s	aon_gdc_dothatloopin
			move.b	d1,aon_loopcnt(a6)	; write counter
aon_gdc_dothatloopin	subq.b	#1,aon_loopcnt(a6)	; continue looping!
			bne.s	aon_gdc_notjustlooped
			move.b	#$f0,aon_loopcnt(a6)	; loop over flag
aon_gdc_notjustlooped	move.b	#-1,aon_loopflag(a6)
aon_gdc_noloopreset

aon_gdc_nomoreFX
			moveq	#0,d0
			moveq	#0,d1
			moveq	#0,d5			; flag for useoldinstr
			move.b	1(a0),d1		; Get Instrnr.
			and.b	#%00111111,d1		; skip unused bits
			subq.b	#1,d1
			bpl.s	aon_gdc_notoldinstr	; -1-> old instr
			tst.l	aon_instrptr(a4)	; get last instrptr
			beq.w	aon_gdc_nonewnote	; no instrument ?!!
							; then exit
			move.l	aon_instrptr(a4),a2	; last instrptr
			move.b	(a0),d2
			and.b	#63,d2			; no note?
			beq.w	aon_gdc_nonewinstr	; then pause !
			moveq	#1,d5			; flag for useoldinstr
			cmp.b	#3,aon_fxCOM(a4)
			beq.w	aon_gdc_nonewinstr
			cmp.b	#5,aon_fxCOM(a4)
			beq.w	aon_gdc_nonewinstr
			cmp.b	#27,aon_fxCOM(a4)
			beq.w	aon_gdc_nonewinstr
			cmp.b	#28,aon_fxCOM(a4)
			beq.w	aon_gdc_nonewinstr
			bra.b	aon_gdc_useoldinstr
aon_gdc_notoldinstr	move.b	(a0),d2
			and.b	#63,d2			; no note?
			bne.s	aon_gdc_notchangerepeat	; then only set repeat

			add.b	d1,d1
			add.b	d1,d1
			lea	aon_instrstarts(a6),a2
			move.l	(a2,d1),a2

			tst.b	instr_control(a2)
			bne.w	aon_gdc_resetvolume.etc		;aon_gdc_notsameinstr


			cmp.l	aon_instrptr(a4),a2
			beq.w	aon_gdc_resetvolume.etc
			move.l	a2,aon_instrptr(a4)	; save in channeldata
			move.b	#01,aon_chflag(a4)	; 01=NEW REPEATWAVE
			bra.w	aon_startrepeat
aon_gdc_notchangerepeat
			clr.l	aon_oldsampoff(a4)

			add.b	d1,d1
			add.b	d1,d1
			lea	aon_instrstarts(a6),a2
			move.l	(a2,d1),a2

			cmp.l	aon_instrptr(a4),a2
			bne.s	aon_gdc_notsameinstr
			cmp.b	#3,aon_fxCOM(a4)
			beq.w	aon_gdc_resetvolume.etc
			cmp.b	#5,aon_fxCOM(a4)
			beq.w	aon_gdc_resetvolume.etc
			cmp.b	#27,aon_fxCOM(a4)
			beq.w	aon_gdc_resetvolume.etc
			cmp.b	#28,aon_fxCOM(a4)
			beq.w	aon_gdc_resetvolume.etc
aon_gdc_notsameinstr
			move.l	a2,aon_instrptr(a4)	; save in channeldata
aon_gdc_useoldinstr

			clr.b	aon_vibCONT(a4)
			bsr.w	aon_initADSR

			tst.b	instr_control(a2)	; Synthmode on??
			beq.w	aon_startsample
************* HIER NACH INSTRUMENTEN-TYPEN UNTERSCHEIDEN!!!!!!!!!!!!!********
************* HIER NACH INSTRUMENTEN-TYPEN UNTERSCHEIDEN!!!!!!!!!!!!!********
************* HIER NACH INSTRUMENTEN-TYPEN UNTERSCHEIDEN!!!!!!!!!!!!!********

; ---- INIT SYNTHETIC INSTRUMENT ---------------	16-juli-1994
aon_gdc_initsynth

			move.b	#1,aon_chMODE(a4)

			move	aon_fxCOM(a4),d0
			move.b	d0,d1
			and.b	#$f0,d0

			cmp	#$0e90,d0		; retrig note?
			bne.s	.noretrigging
			and.b	#$0f,d1
			move.b	d1,aon_stepfxcnt(a4)
.noretrigging

			lea	aon_wavestarts(a6),a3

			move.b	(a0),d2			; Alter Fehler: Bei
			and.b	#63,d2			; Wechsel des Instr.
			beq.w	aon_gdc_resetvolume.etc	; wurde �perslide� re-
			clr	aon_perslide(a4)	; settet!

			moveq	#0,d3
			cmp.b	#17,aon_fxCOM(a4)	; 'h'  synthcontrol?!
			bne.b	.noth
			move.b	aon_fxDAT(a4),d3
.noth
			btst	#4,d3
			bne.w	.initVIB

			cmp	#$0ed0,d0		; delay note?
			bne.s	.notdelaynote
			and.b	#$0f,d1
			move.b	d1,aon_stepfxcnt(a4)
			bra.b	.startrepeat
.notdelaynote		move.b	#3,aon_chflag(a4)	; 3=New WAVE
.startrepeat

			moveq	#0,d0
			move.b	instr_waveform(a2),d0	; Nr. of waveform
			move.b	d0,aon_actwavenr(a4)
			add	d0,d0
			add	d0,d0			; *4 (longword!)
			move.l	(a3,d0.l),d1		; Get address..
; d1=Address of actual waveform
			cmp.l	aon_waveform(a4),d1
			bne.b	.notsamewaveU
			clr.b	aon_chflag(a4)

			tst.b	aon_synthWAVECONT(a4)	; Wave
			bne.w	.initVIB		; NICHT resetten!!

.notsamewaveU		move.l	d1,aon_waveform(a4)

.checkoffset
			moveq	#0,d0
			move.b	synth8_partwaveDMALen(a2),d0

			cmp.b	#9,aon_fxCOM(a4)
			bne.b	.notoffset
			moveq	#0,d2
			move.b	aon_fxDAT(a4),d2
			mulu	d0,d2
			add.l	d1,d2
			move.l	d2,d1
;aon_synthwaveactptr(a4)
			tst.b	aon_synthwaveSTOP(a4)
			beq.b	.notoffset
			move.l	d1,aon_synthWAVEactPTR(a4)
			move.l	d1,aon_repeatstrt(a4)
			bra.b	.initVIB
.notoffset
			tst.b	aon_synthwaveSTOP(a4)
			bne.b	.initVIB

			move.l	d1,aon_synthWAVEactPTR(a4)


			move	aon_wavelen(a4),aon_oldwavelen(a4)

			move	d0,aon_wavelen(a4)
			move	d0,aon_replen(a4)

			add	d0,d0
			move.l	d0,aon_synthWAVEaddbytes(a4)

			moveq	#0,d2
			move.b	synth8_WAVErep(a2),d2
			mulu	d0,d2
			add.l	d1,d2
			move.l	d2,aon_repeatstrt(a4)

			moveq	#0,d2
			move.b	synth8_WAVElen(a2),d2
			mulu	d0,d2
			add.l	d1,d2
			move.l	d2,aon_synthWAVEendPTR(a4)

			moveq	#0,d2
			move.b	synth8_WAVErep(a2),d2
			mulu	d0,d2
			add.l	d1,d2
			move.l	d2,aon_synthWAVErepPTR(a4)

			moveq	#0,d2
			move.b	synth8_WAVEreplen(a2),d2
			add.b	synth8_WAVErep(a2),d2
			mulu	d0,d2
			add.l	d1,d2
			move.l	d2,aon_synthWAVErependPTR(a4)

			move.b	synth8_WAVEspd(a2),aon_synthWAVEcnt(a4)
			move.b	synth8_WAVEspd(a2),aon_synthWAVEspd(a4)
			move.b	synth8_WAVErepCtrl(a2),aon_synthWAVErepctrl(a4)


; Vibrato initalisieren
.initVIB
;			btst	#0,d3			; Restart
;			beq.b	.vibke			; Volume
;			clr.b	aon_synthENV(a4)	; Envelope ?!?
;.vibke
			clr.b	aon_vibON(a4)
			cmp.b	#3,synth8_vibwave(a2)	; 'Off' ?!
			beq.b	.vibOFF

			moveq	#0,d1
			move.b	synth8_vibdelay(a2),d1
			move	d1,aon_vibratotrigdelay(a4)
			moveq	#0,d1
			move.b	synth8_VIBpara(a2),d1
			bne.b	.vib
			move	#-2,aon_vibratotrigdelay(a4)
			bra.b	.novib
.vib			move.l	a2,-(sp)
			bsr.w	aon_dofx_vibratoPARAM	; set parameters
			move.l	(sp)+,a2
			move.b	synth8_vibwave(a2),d0
			ror.b	#3,d0
			and.b	#%10011111,aon_vibratoampl(a4)
			or.b	d0,aon_vibratoampl(a4)
			move.b	#1,aon_vibCONT(a4)
			
.novib
			bra.w	aon_gdc_resetvolume.etc
.vibOFF			move.b	#"!",aon_vibON(a4)
			bra.w	aon_gdc_resetvolume.etc

; --------------------- INIT SAMPLE8BIT INSTRUMENT ----------------------
aon_startsample

			move.b	#"!",aon_vibON(a4)
			clr.b	aon_chMODE(a4)
			move	aon_fxCOM(a4),d0
			move.b	d0,d1
			and.b	#$f0,d0

			cmp	#$0ed0,d0		; delay note?
			bne.s	aon_gdc_notdelaynote
			and.b	#$0f,d1
			move.b	d1,aon_stepfxcnt(a4)
			bra.b	aon_startrepeat
aon_gdc_notdelaynote
			cmp	#$0e90,d0		; retrig note?
			bne.s	aon_gdc_noretrigging
			and.b	#$0f,d1
			move.b	d1,aon_stepfxcnt(a4)
aon_gdc_noretrigging
			move.b	#03,aon_chflag(a4)	; 03=New SAMPLEWAVE
aon_startrepeat		lea	aon_wavestarts(a6),a3

;			cmp.b	#$3,aon_fxCOM(a4)
;			beq.w	.resetper
;		cmp.b	#$5,aon_fxCOM(a4)
;		bne.b	.noresetper
;.resetper
			move.b	(a0),d2			; Alter Fehler: Bei
			and.b	#63,d2			; Wechsel des Instr.
			beq.b	.noresetper		; wurde �perslide� re-
			clr	aon_perslide(a4)	; settet!
.noresetper			

			moveq	#0,d0
			move.b	instr_waveform(a2),d0	; Nr. of waveform
			move.b	d0,aon_actwavenr(a4)
			add	d0,d0
			add	d0,d0			; *4 (longword!)
			move.l	(a3,d0.l),d1		; Get address..
; d1=Address of actual waveform

			move.l	sample8_dmalen(a2),d4
			move	aon_wavelen(a4),aon_oldwavelen(a4)
			move	d4,aon_wavelen(a4)

			tst.l	sample8_dmareplen(a2)	; Is there any repeat?!
			bne.b	sample8_theresARepeat
			move.l	a2,-(sp)
			;lea	AON_leer(pc),a2
			move.l	AON_leer(pc),a2
			move.l	a2,aon_repeatstrt(a4)
			move.l	(sp)+,a2
			move	#1,aon_replen(a4)
			bra.b	sample8_theresNorepeat
sample8_theresARepeat

			move.l	sample8_dmarepoffset(a2),d2

		tst.b	aon_oversize(a6)
		bne.b	sample8_NotzeroRep
		tst.l	d2
		bne.b	sample8_NotzeroRep	; sonst sind keine
						; samples >128k m�glich
		move.l	d1,aon_repeatstrt(a4)	;!!!!!!!!!!!!!!!!
		move	sample8_dmareplen+2(a2),aon_replen(a4)
		bra.b	sample8_zeroRep
sample8_NotzeroRep
			move.l	d2,d3		; save repeatstart in WORDS
			add.l	d2,d2
			add.l	d1,d2
			move.l	d2,aon_repeatstrt(a4)
			moveq	#0,d2
			move	sample8_dmareplen+2(a2),d2	; get repeatlen
			move	d2,aon_replen(a4)	; replen in WORDS

		tst.b	aon_oversize(a6)
		bne.b	sample8_zeroRep
		add	d3,d2		; replen+repstart=wavelen
		move	d2,aon_wavelen(a4)

sample8_zeroRep
sample8_theresNorepeat
			move.l	sample8_dmaoffset(a2),d2
			add.l	d2,d2			; get bytesize!

			move.l	aon_oldsampoff(a4),d4
			lsr.l	#1,d4
			sub	d4,aon_wavelen(a4)	; offset from last com

			cmp.b	#9,aon_fxCOM(a4)	; effect 'SAMPOFF'
			bne.s	aon_gdc_nonewsampoff	; no ??

			moveq	#0,d3
			move.b	aon_fxDAT(a4),d3	; get offset
			lsl	#8,d3			; ->*256

			move.l	d3,d4
			lsr.l	#1,d4
			sub	d4,aon_wavelen(a4)
			bpl.s	aon_gdc_usesampoff
			move.l	aon_repeatstrt(a4),aon_waveform(a4)
			move	aon_replen(a4),aon_wavelen(a4)
			bra.b	aon_gdc_offendofsample
aon_gdc_usesampoff	add.l	d3,aon_oldsampoff(a4)
aon_gdc_nonewsampoff	
			add.l	d1,d2			; Realstart of wave
			add.l	aon_oldsampoff(a4),d2	; add offset
			move.l	d2,aon_waveform(a4)
aon_gdc_offendofsample
aon_gdc_resetvolume.etc

			tst.b	d5
			bne.s	aon_gdc_nonewinstr
			move.b	instr_volume(a2),aon_volume(a4)
; -----------------------------------

aon_gdc_nonewinstr

			moveq	#0,d0
			move.b	(a0),d0			; Get note
			and.b	#%00111111,d0
			bne.s	aon_gdc_notefound	; 0=Pause

			move.b	aon_lastnote(a4),d0	; Use last note!
			beq.w	aon_gdc_nonewnote
			cmp	#60,d0
			bgt.w	aon_gdc_nonewnote	; >B-3? -->pause!!!
			bra.b	aon_gdc_getarpeggio	; no instr retrig!!

aon_gdc_notefound	
			clr.b	aon_slideflag(a4)
			move.b	d0,aon_lastnote(a4)
			cmp	#60,d0
			bgt.w	aon_gdc_nonewnote	; >B-3? -->pause!!!

aon_gdc_getarpeggio
			move.l	aon_arpdata(a6),a3
			moveq	#0,d2
			moveq	#0,d3
			move.b	2(a0),d2
			move.b	1(a0),d3
			and.b	#%11000000,d2		; upper
			and.b	#%11000000,d3		; and lower 2 bits
			rol.b	#6,d2			; of arp.nr to use
			rol.b	#4,d3
			or.b	d2,d3			; *4 (4bytes/arp)

			lea	(a3,d3.l),a3		; get pointer on arpdat

			moveq	#0,d2
			move.b	instr_finetune(a2),d2	; get da finetune!!
			add	d2,d2
			move	(a5,d2.l),d2		; *120 (pertabsize)

			subq.b	#1,d0			; skip 'pause' mark
			add	d0,d0
			add	d0,d2			; offset in pertab

			cmp.b	#27,aon_fxCOM(a4)
			beq.b	aon_arpslide
			cmp.b	#28,aon_fxCOM(a4)
			beq.b	aon_arpslide
			cmp.b	#5,aon_fxCOM(a4)
			beq.b	aon_arpslide
			cmp.b	#3,aon_fxCOM(a4)
			bne.b	AON_notarpslide
aon_arpslide		move.b	(a0),d0
			and.b	#$3f,d0
			beq.b	AON_notarpslide
			move.b	#1,aon_slideflag(a4)
			lea	AON_PERIODS(pc),a1
			move	(a1,d2.l),d1

			move	aon_period(a4),d0
			add	aon_perslide(a4),d0
			sub	d1,d0			; -actual periode=diff.
			move	d0,aon_perslide(a4)

;;;;;bra	aon_notarpslide

AON_notarpslide
			lea	aon_arpeggiotab(a4),a1
			cmp	#-1,2(a1)		; arpeggio im letzten
			bne.b	aon_noarpreset		; step aktiv ?!
			clr	aon_arpeggiooff(a4)
			clr.b	aon_arpeggiocnt(a4)
aon_noarpreset
			tst.b	aon_fxCOM(a4)
			bne.b	aon_gdc_noproarp
			tst.b	aon_fxDAT(a4)
			beq.s	aon_gdc_noproarp
; Protracker-Arpeggio (fxcom=0) auslesen
			moveq	#0,d0
			moveq	#0,d1
			move.b	aon_fxDAT(a4),d0
			move.b	d0,d1
			and.b	#$f0,d0
			and.b	#$0f,d1
			lsr.b	#4,d0
			add	d0,d0
			add	d1,d1
			move	d2,(a1)+
			add	d2,d0
			add	d2,d1
			move	d0,(a1)+
			move	d1,(a1)+
			bra.b	aon_gdc_arpend
aon_gdc_noproarp
; Professional arpeggio
			moveq	#0,d0
			moveq	#0,d1
			move.b	(a3)+,d0	; 1.nibble=anzahl arpeggios
			move.b	d0,d1
			lsr.b	#4,d0
			beq.b	aon_gdc_emptyarp	; arp_entry leer?!?!
			and.b	#$f,d1
			add	d1,d1
			add	d2,d1
			move	d1,(a1)+
			subq.b	#1,d0
			beq.b	aon_gdc_arpend
AON_GDC_writearps	moveq	#0,d1
			moveq	#0,d3
			move.b	(a3)+,d1	; 2 nibbles holen
			move.b	d1,d3
			lsr.b	#4,d1
			and.b	#$f,d3
			add	d1,d1
			add	d3,d3
			add	d2,d1
			move	d1,(a1)+
			subq.b	#1,d0
			beq.b	aon_gdc_arpend
			add	d2,d3
			move	d3,(a1)+
			subq.b	#1,d0
			bne.b	AON_GDC_writearps
aon_gdc_arpend		move	#-1,(a1)
aon_gdc_nonewnote	rts
aon_gdc_emptyarp
			clr	aon_arpeggiooff(a4)
			move.b	aon_arpeggiospd(a4),aon_arpeggiocnt(a4)
			subq.b	#1,aon_arpeggiocnt(a4)
			move	d2,(a1)+
			bra.b	aon_gdc_arpend
;========================================================================
; Vol-Envelope initalisieren
;
; Start		0-255
; Add 0-255 bis	255
; Sub 0-255 bis
; End		0-255

;
; a2=Instrumentdata
; a4=Channeldata
aon_initADSR:		
			cmp.b	#17,aon_fxCOM(a4)
			bne.b	.notH
			move.b	aon_fxDAT(a4),d3
			btst	#0,d3
			bne.b	.exit
.notH
			move.b	instr_Astart(a2),aon_synthVOL(a4)
			move.b	instr_Aadd(a2),d0
			beq.b	.noADSR
			move.b	d0,aon_synthADD(a4)
			move.b	instr_Asub(a2),aon_synthSUB(a4)
			move.b	instr_Aend(a2),aon_synthEND(a4)

			move.b	#1,aon_synthENV(a4)	; Envelope ADD
.exit			rts

.noADSR			move.b	#127,aon_synthVOL(a4)
			clr.b	aon_synthENV(a4)	; Envelope OFF
			rts

;========================================================================
; dont change a1!!!!!!1
; a4=chptr
AON_DOSYNTH
			clr.b	aon_vibDONE(a4)
			tst.b	aon_chflag(a4)
			bne.w	.exit
			tst.b	aon_chMODE(a4)		; isssees n sample?!
			beq.w	.exitSMPL
			tst.l	aon_waveform(a4)	; keine wellenform !?!
			beq.w	.exit

			tst.b	aon_synthwaveSTOP(a4)
			bne.w	.nonewWAVE


			addq.b	#1,aon_synthWAVEcnt(a4)
			move.b	aon_synthWAVEspd(a4),d0
			cmp.b	aon_synthWAVEcnt(a4),d0	; framecnt
			bgt.w	.nonewWAVE
			clr.b	aon_synthWAVEcnt(a4)
			move.l	aon_synthWAVEaddbytes(a4),d0
			add.l	d0,aon_synthWAVEactPTR(a4)

			tst.l	d0	; partwave wandert nach links?!?!
			bpl.b	.rightloop
			move.l	aon_synthWAVErepPTR(a4),d0	; links clippen
			cmp.l	aon_synthWAVEactPTR(a4),d0
			ble.b	.notwaveend
			bra.b	.jumprepeat
.rightloop
			move.l	aon_synthWAVEendPTR(a4),d0	;rechts clippen
			cmp.l	aon_synthWAVEactPTR(a4),d0
			bgt.b	.notwaveend
.jumprepeat		tst.b	aon_synthWAVErepctrl(a4)
			beq.b	.normalrep
			cmp.b	#1,aon_synthWAVErepctrl(a4)
			beq.b	.backrep

.pingpong
		move.l	aon_synthWAVErependPTR(a4),aon_synthWAVEendPTR(a4)
			move.l	aon_synthWAVEaddbytes(a4),d0
			sub.l	d0,aon_synthWAVEactPTR(a4)
			neg.l	d0
			move.l	d0,aon_synthWAVEaddbytes(a4)
			bra.b	.notwaveend

.normalrep		move.l	aon_synthWAVErepPTR(a4),aon_synthWAVEactPTR(a4)
		move.l	aon_synthWAVErependPTR(a4),aon_synthWAVEendPTR(a4)
			bra.b	.notwaveend
.backrep	move.l	aon_synthWAVErependPTR(a4),aon_synthWAVEactPTR(a4)
			move.l	aon_synthWAVEaddbytes(a4),d0
			bmi.b	.alreadyNeg
			neg.l	d0
			tst.b	aon_synthwaveSTOP(a4)
			bne.b	.notwaveend
.alreadyNeg		add.l	d0,aon_synthWAVEactPTR(a4)
			move.l	d0,aon_synthWAVEaddbytes(a4)
.notwaveend
			move.b	#1,aon_chflag(a4)	; new repoff

;		cmp.b	#9,aon_fxCOM(a4)
;		beq.b	.setit
.setit			move.l	aon_synthWAVEactPTR(a4),aon_repeatstrt(a4)
.nonewWAVE


.exitSMPL
; DO Envelope

			tst.b	aon_synthENV(a4)
			beq.b	.dovib
			moveq	#0,d0
			move.b	aon_synthVOL(a4),d0
			cmp.b	#1,aon_synthENV(a4)
			bne.b	.decay
			add.b	aon_synthADD(a4),d0
			bpl.b	.newVOL
			moveq	#127,d0
			move.b	#2,aon_synthENV(A4)
			bra.b	.newVOL
.decay			sub.b	aon_synthSUB(a4),d0
			cmp.b	aon_synthEND(a4),d0
			bgt.b	.newVOL
			move.b	aon_synthEND(a4),d0
			clr.b	aon_synthENV(a4)
.newVOL			move.b	d0,aon_synthVOL(a4)


; Vibrato
.dovib
			cmp.b	#"!",aon_vibON(a4)
			beq.b	.vibok
			cmp	#-1,aon_vibratotrigdelay(a4)
			bne.b	.delayvib
			move.b	#1,aon_vibON(a4)
			bra.b	.vibok
.delayvib		subq	#1,aon_vibratotrigdelay(a4)
.vibok

.exit
			cmp.b	#1,aon_vibON(a4)
			bne.b	.VIBoff
			bra.w	aon_dofx_viboldampl
.VIBoff			rts
;========================================================================
; a4=channelptr
; don't use a1
AON_DOFX
			tst.b	aon_vibCONT(a4)
			bne.b	.dauervibrato
			move.b	#"!",aon_vibON(a4)
.dauervibrato

			addq.b	#1,aon_arpeggiocnt(a4)
			move.b	aon_arpeggiospd(a4),d0	; time for arpeggio
			cmp.b	aon_arpeggiocnt(a4),d0	; tone-change ?!
			bgt.s	aon_dofx_nonewarpval

			clr.b	aon_arpeggiocnt(a4)	; clear counter

aon_dofx_newarpval	move	aon_arpeggiooff(a4),d1	; offset in tab
			lea	aon_arpeggiotab(a4),a3
			moveq	#0,d7
			move	(a3,d1),d7		; get act. note
			bpl.s	aon_dofx_notarpend
			clr	aon_arpeggiooff(a4)
			bra.b	aon_dofx_newarpval
aon_dofx_notarpend
			lea	AON_PERIODS(pc),a3
			move	(a3,d7.l),d0		; get periode
			move	d0,aon_period(a4)	; store in chdata
			addq.b	#2,aon_arpeggiooff+1(a4) ; next value
			and.b	#$0f,aon_arpeggiooff+1(a4)
aon_dofx_nonewarpval

			lea	AON_DOSYNTH(pc),a2
			move.l	a2,-(sp)
;bsr	aon_dosynth

			moveq	#0,d0
			moveq	#0,d1
			move.b	aon_fxDAT(a4),d1

			move.b	aon_fxCOM(a4),d0
			beq.w	aon_dofx_end

			tst.b	aon_framecnt(a6)
			beq.b	aon_dofx_atonce

			cmp.b	#1,d0
			beq.w	aon_dofx_portamentoup
			cmp.b	#$2,d0
			beq.w	aon_dofx_portamentodown
			cmp.b	#$3,d0
			beq.w	aon_dofx_toneslide
			cmp.b	#$4,d0
			beq.w	aon_dofx_vibrato
			cmp.b	#$5,d0
			beq.w	aon_dofx_glissvolumeslide
			cmp.b	#$6,d0
			beq.w	aon_dofx_vibvolumeslide
			cmp.b	#$a,d0
			beq.w	aon_dofx_volumeslide
aon_dofx_atonce
			cmp.b	#$b,d0
			beq.w	aon_dofx_breakto
			cmp.b	#$c,d0
			beq.w	aon_dofx_setvolume
			cmp.b	#$d,d0
			beq.w	aon_dofx_breakpat
			cmp.b	#$e,d0
			beq.w	aon_dofx_ECOMMANDS
			cmp.b	#$f,d0
			beq.w	aon_dofx_setspd
			cmp.b	#16,d0		;'g'
			beq.w	aon_dofx_setvoldel
			cmp.b	#18,d0		;'i'
			beq.w	aon_dofx_setwaveadsrspd
			cmp.b	#19,d0		;'j'
			beq.w	aon_dofx_setarpspd
			cmp.b	#20,d0		;'k'
			beq.w	aon_dofx_vibsetvolume
			cmp.b	#21,d0		;'l'
			beq.w	aon_dofx_portvolslideUP
			cmp.b	#22,d0		;'m'
			beq.w	aon_dofx_portvolslideDOWN
			cmp.b	#23,d0		;'n'
			beq.w	aon_dofx_togglenoiseavoid
			cmp.b	#24,d0		;'o'
			beq.w	aon_dofx_toggleoversize
			cmp.b	#25,d0		;'p'
			beq.w	aon_dofx_fineVOLslidevib
			cmp.b	#26,d0		;'q'
			beq.w	aon_dofx_synthdrums
			cmp.b	#27,d0		;'r'
			beq.w	aon_dofx_setvolumePort
			cmp.b	#28,d0		;'s'
			beq.w	aon_dofx_finevolslidePort
			cmp.b	#29,d0		;'t'
			beq.w	aon_dofx_settrackvol
			cmp.b	#30,d0		;'u'
			beq.w	aon_dofx_setwavecont
			cmp.b	#33,d0		;'x'
			beq.w	aon_dofx_externalevent
aon_dofx_end		rts
; --------------------------------------------------------------------
; $1
aon_dofx_portamentoup
			sub	d1,aon_perslide(a4)
			rts
; --------------------------------------------------------------------
; $2
aon_dofx_portamentodown
			add	d1,aon_perslide(a4)
			rts
; --------------------------------------------------------------------
; $3
aon_dofx_toneslide	tst.b	d1
			beq.b	aon_dofx_toneslideNOW
			move.b	d1,aon_glissspd(a4)
aon_dofx_toneslideNOW
			tst.b	aon_slideflag(a4)
			beq.b	.exit
			move.b	aon_glissspd(a4),d1
			tst	aon_perslide(a4)
			beq.b	aon_dofx_end
			bpl.b	.sub
			add	d1,aon_perslide(a4)
			bmi.b	aon_dofx_end
			clr	aon_perslide(a4)
			rts
.sub			sub	d1,aon_perslide(a4)
			bpl.b	aon_dofx_end
			clr	aon_perslide(a4)
.exit			rts
; --------------------------------------------------------------------
; $4
aon_dofx_vibrato
			move.b	#1,aon_vibON(a4)
aon_dofx_vibratoPARAM
			tst.b	d1
			beq.b	.goon		; Vibrato-Parameter
			move.b	d1,d2		; setzen!!
			and.b	#$f0,d1
			lsr.b	#4,d1
			beq.b	.oldspd
			move.b	d1,aon_vibratospd(a4)
.oldspd			and.b	#$0f,d2
			beq.s	.goon
			and.b	#$f0,aon_vibratoampl(a4)
			or.b	d2,aon_vibratoampl(a4)
.goon			rts

; Einsprung um Vibrato-Effekt zu erzeugen
aon_dofx_viboldampl	
			tst.b	aon_vibDONE(a4)	; Nur �1� Vibrato zur Zeit
			bne.b	aon_dofx_vibnotend
			move.b	#1,aon_vibDONE(a4)

			moveq	#0,d2
			move.b	aon_vibratoampl(a4),d2
			and.b	#%01100000,d2
			beq.s	aon_dofx_vibSINE
			cmp.b	#32,d2
			beq.s	aon_dofx_vibRAMPDOWN
			lea	AON_vibrato_square(pc),a2
			bra.b	aon_dofx_vibSQUARE
aon_dofx_vibRAMPDOWN	lea	AON_vibrato_rampdown(pc),a2
			bra.b	aon_dofx_vibSQUARE
aon_dofx_vibSINE	lea	AON_vibrato_sine(pc),a2
aon_dofx_vibSQUARE
			move.b	aon_vibratopos(a4),d2
			moveq	#0,d0

			move.b	(a2,d2),d2		; vibrato-value
			move.b	aon_vibratoampl(a4),d0
			and.b	#$f,d0
			mulu	d0,d2			; *vibrato amplitude
			lsr	#7,d2

			move	aon_period(a4),d0	; period (smaller)

			btst	#7,aon_vibratoampl(a4)	; negativ ?
			beq.s	aon_dofx_vibpositiv
			sub	d2,d0
			bra.b	aon_dofx_vibnegativ
aon_dofx_vibpositiv
			add	d2,d0
aon_dofx_vibnegativ
			move	d0,aon_period(a4)

			move.b	aon_vibratospd(a4),d0
			add.b	d0,aon_vibratopos(a4)
			btst	#5,aon_vibratopos(a4)
			beq.s	aon_dofx_vibnotend
			and.b	#$1f,aon_vibratopos(a4)
			bchg	#7,aon_vibratoampl(a4)	; toggle pos/neg
aon_dofx_vibnotend	rts
; --------------------------------------------------------------------
; $5
aon_dofx_glissvolumeslide
			move	d1,-(sp)
			moveq	#0,d1
			bsr.w	aon_dofx_toneslideNOW
			move	(sp)+,d1
			bra.b	aon_dofx_volumeslide
; --------------------------------------------------------------------
; $6
aon_dofx_vibvolumeslide	move	d1,-(sp)
			bsr.w	aon_dofx_viboldampl
			move	(sp)+,d1
			bra.w	aon_dofx_volumeslide
; --------------------------------------------------------------------
; $A
aon_dofx_volumeslide	move.b	d1,d2
			and.b	#$0f,d1
			and.b	#$f0,d2
			lsr.b	#4,d2
			tst.b	d2	; Protracker-Kompatibilit�t:
			bne.s	aon_dofx_vsok1	; Wenn volume slide up <>0
			; dann volume slide down nicht beachten!!
			sub.b	d1,aon_volume(a4)
			bpl.s	aon_dofx_vsok1
			clr.b	aon_volume(a4)
aon_dofx_vsok1		add.b	d2,aon_volume(a4)
			cmp.b	#64,aon_volume(a4)
			bls.s	aon_dofx_vsok2
			move.b	#64,aon_volume(a4)
aon_dofx_vsok2		rts
; --------------------------------------------------------------------
; $B
aon_dofx_breakto
			subq.b	#1,d1
			move.b	d1,aon_pos(a6)
			move	#$ff00,aon_patcnt(a6)
			rts
; --------------------------------------------------------------------
; $C
aon_dofx_setvolume	move.b	d1,aon_volume(a4)
			rts
; --------------------------------------------------------------------
; $D
aon_dofx_breakpat
			move.b	d1,d0		; e.g	$32 -> #32
			and.b	#$0f,d1
			and.b	#$f0,d0
			lsr.b	#1,d0		; -> $30->$18=#24
			move.b	d0,d2
			lsr.b	#3,d2		; -> $18/8->$03
			add.b	d2,d0		; #24+3
			add.b	d2,d0		; #27+3 (=#30)
			add.b	d1,d0		; +2!
			add.b	d0,d0		; =#32
			add.b	d0,d0		; ->*4
			or	#$ff00,d0	; add breakflag
			move	d0,aon_patcnt(a6)
			rts
; --------------------------------------------------------------------
; $F
aon_dofx_setspd
			tst.b	d1
			beq.b	aon_dofx_replayend

			cmp.b	#32,d1
			bhi.b	.settempo2
			move.b	d1,aon_speed(a6)
.quit			rts

.settempo2		cmp.b	#200,d1
			bhi.b	.quit
			move.l	#aon_timerval,d0
			divu	d1,d0

			move.b	d1,aon_tempo(a6)
aon_dofx_settempo		
			;move.b	d0,$bfd600	; MSB	Timer setzen
			;lsr	#8,d0		; 8-15
			;move.b	d0,$bfd700	; LSB
			push    a0
			move.l 	ciasetter(pc),a0 
			jsr		(a0)
			pop     a0
aon_dofx_vbireplay
			rts
aon_dofx_replayend	clr.b	aon_speed(a6)
aon_resettimer		move.b	#125,aon_tempo(a6)
			;move.b	#$79,$bfd600	;600
			;move.b	#$12,$bfd700	;700
			pushm	d0/a0
			move	#$1279,d0 
			move.l 	ciasetter(pc),a0 
			jsr		(a0)
			popm    d0/a0
			rts
; --------------------------------------------------------------------
; | E1- FineSlide Up                  E1x : value			   |
; | E2- FineSlide Down                E2x : value			   |
; | E3- Glissando Control             E3x : 0-off, 1-on (use with tonep.)  |
; | E4- Set Vibrato Waveform          E4x : 0-sine, 1-ramp down, 2-square  |
; | E5- Set Loop                      E5x : set loop point		   |
; | E6- Jump to Loop                  E6x : jump to loop, play x times	   |
; | E7- Set Tremolo Waveform          E7x : 0-sine, 1-ramp down. 2-square  |
; | E8- NOT USED							   |
; | E9- Retrig Note                   E9x : retrig from note + x vblanks   |
; | EA- Fine VolumeSlide Up           EAx : add x to volume		   |
; | EB- Fine VolumeSlide Down         EBx : subtract x from volume	   |
; | EC- NoteCut                       ECx : cut from note + x vblanks	   |
; | ED- NoteDelay                     EDx : delay note x vblanks	   |
; | EE- PatternDelay                  EEx : delay pattern x notes	   |
; | EF- Invert Loop                   EFx : speed			   |
; $Ex
aon_dofx_ECOMMANDS	move.b	d1,d0
			and.b	#$0f,d1
			and.b	#$f0,d0
			beq.s	aon_dofx_setfilter
			cmp.b	#$10,d0
			beq.s	aon_dofx_fineportamentoup
			cmp.b	#$20,d0
			beq.s	aon_dofx_fineportamentodn
			cmp.b	#$40,d0
			beq.s	aon_dofx_setvibratowave
			cmp.b	#$50,d0
			beq.b	aon_dofx_setlooppoint
			cmp.b	#$60,d0
			beq.b	aon_dofx_jump2loop
			cmp.b	#$90,d0
			beq.b	aon_dofx_retrignote
			cmp.b	#$a0,d0
			beq.w	aon_dofx_finevolup
			cmp.b	#$b0,d0
			beq.w	aon_dofx_finevoldn
			cmp.b	#$c0,d0
			beq.w	aon_dofx_notecut
			cmp.b	#$d0,d0
			beq.b	aon_dofx_retrignote
			rts
; --------------------------------------------------------------------
; $E0
aon_dofx_setfilter	tst.b	d1
			beq.s	aon_dofx_filteron
			bset	#1,$bfe001

			rts
aon_dofx_filteron	bclr	#1,$bfe001

			rts
; --------------------------------------------------------------------
; $E1
aon_dofx_fineportamentoup
			tst.b	aon_framecnt(a6)
			bne.s	aon_dofx_tool8
			sub	d1,aon_perslide(a4)
aon_dofx_tool8		rts
; --------------------------------------------------------------------
; $E2
aon_dofx_fineportamentodn
			tst.b	aon_framecnt(a6)
			bne.s	aon_dofx_tool82
			add	d1,aon_perslide(a4)
aon_dofx_tool82		rts
; --------------------------------------------------------------------
; $E4
aon_dofx_setvibratowave
			and.b	#3,d1
			ror.b	#3,d1
			and.b	#%10011111,aon_vibratoampl(a4)
			or.b	d1,aon_vibratoampl(a4)
			rts
; --------------------------------------------------------------------
; $E5
aon_dofx_setlooppoint
			move.b	aon_patcnt+1(a6),d0
			subq.b	#4,d0
			cmp.b	aon_looppoint(a6),d0
			beq.s	aon_dofx_justloopin
			move.b	d0,aon_looppoint(a6)
			clr.b	aon_loopcnt(a6)
aon_dofx_justloopin	rts
; --------------------------------------------------------------------
; $E6
aon_dofx_jump2loop
			tst.b	d1
			beq.s	aon_dofx_setlooppoint
			rts
; --------------------------------------------------------------------
; $E9
aon_dofx_retrignote	tst.b	aon_stepfxcnt(a4)
			bne.s	aon_dofx_noretrig
			move.b	#3,aon_chflag(a4)
			move.b	#$ef,aon_fxCOM(a4)
			rts
aon_dofx_noretrig	subq.b	#1,aon_stepfxcnt(a4)
			rts
; --------------------------------------------------------------------
; $EA
aon_dofx_finevolup
			tst.b	aon_framecnt(a6)
			bne.s	aon_dofx_volresisup
			add.b	d1,aon_volume(a4)
			cmp.b	#64,aon_volume(a4)
			ble.s	aon_dofx_volresisup
			move.b	#64,aon_volume(a4)
aon_dofx_volresisup	rts
; --------------------------------------------------------------------
; $EB
aon_dofx_finevoldn	tst.b	aon_framecnt(a6)
			bne.s	aon_dofx_volresisdn
			sub.b	d1,aon_volume(a4)
			bpl.s	aon_dofx_volresisdn
			clr.b	aon_volume(a4)
aon_dofx_volresisdn	rts
; --------------------------------------------------------------------
; $EC
aon_dofx_notecut	tst.b	aon_stepfxcnt(a4)
			bne.s	.nonotecut
			clr.b	aon_volume(a4)
			rts
.nonotecut		subq.b	#1,aon_stepfxcnt(a4)
			rts
; --------------------------------------------------------------------
; 'g'
aon_dofx_setvoldel
			tst.b	aon_stepfxcnt(a4)
			bne.b	.novolset
			and.b	#$f0,d1
			lsr.b	#4,d1
			add.b	d1,d1
			add.b	d1,d1
			addq.b	#4,d1
			move.b	d1,aon_volume(a4)
			rts
.novolset		subq.b	#1,aon_stepfxcnt(a4)
			rts
; --------------------------------------------------------------------
; 'i'
aon_dofx_setwaveadsrspd
			move.b	d1,d2
			and.b	#$f0,d1
			lsr.b	#4,d1
			move.b	d1,aon_synthWAVEspd(a4)
			rts
; --------------------------------------------------------------------
; 'j'
aon_dofx_setarpspd	and.b	#$f,d1
			beq.b	.not
			move.b	d1,aon_arpeggiospd(a4)
.not			rts
; --------------------------------------------------------------------
; 'k'
aon_dofx_vibsetvolume	move	d1,-(sp)
			bsr.w	aon_dofx_viboldampl
			move	(sp)+,d1
			bra.w	aon_dofx_setvolume
; --------------------------------------------------------------------
; 'l'
aon_dofx_portvolslideUP
			lea	aoN_nibbletab(pc),a0
			move	d1,d2
			lsr.b	#4,d1
			and.b	#$f,d2
			move.b	(a0,d1),d1
			bpl.b	.up1
			neg.b	d1
			bsr.b	aon_dofx_finevoldn
			bra.b	.down1
.up1			bsr.w	aon_dofx_finevolup
.down1
			tst.b	aon_framecnt(a6)
			beq.b	.out
			moveq	#0,d1
			move.b	d2,d1
			bsr.w	aon_dofx_portamentoup

.out			rts

aoN_nibbletab		dc.b	0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1
; --------------------------------------------------------------------
; 'm'
aon_dofx_portvolslideDOWN
			lea	aoN_nibbletab(pc),a0
			move	d1,d2
			lsr.b	#4,d1
			and.b	#$f,d2
			move.b	(a0,d1),d1
			bpl.b	.up1
			neg.b	d1
			bsr.w	aon_dofx_finevoldn
			bra.b	.down1
.up1			bsr.w	aon_dofx_finevolup
.down1
			tst.b	aon_framecnt(a6)
			beq.b	.out
			moveq	#0,d1
			move.b	d2,d1
			bsr.w	aon_dofx_portamentodown

.out			rts
; --------------------------------------------------------------------
; 'n'
aon_dofx_togglenoiseavoid
			move.b	d1,aon_noiseavoid(a6)
			rts
; --------------------------------------------------------------------
; 'o'
aon_dofx_toggleoversize
			move.b	d1,aon_oversize(a6)
			rts
; --------------------------------------------------------------------
; 'p'
aon_dofx_fineVOLslidevib
			move	d1,-(sp)
			bsr.w	aon_dofx_viboldampl
			move	(sp)+,d1
aon_dofx_fineVOlUpDown	moveq	#0,d2
			move.b	d1,d2
			lsr.b	#4,d2
			beq.b	.no
			move	d2,d1
			bra.w	aon_dofx_finevolup
.no			and.b	#$f,d1
			bra.w	aon_dofx_finevoldn
; --------------------------------------------------------------------
; 'q'
aon_dofx_synthdrums
			move	d1,d2
			lsr	#4,d1
			lsl	#3,d1
			bsr.w	aon_dofx_portamentodown
			move	d2,d1
			and	#$f,d1
			bra.w	aon_dofx_volumeslide
; --------------------------------------------------------------------
; 'r'
aon_dofx_setvolumePort
			move	d1,-(sp)
			bsr.w	aon_dofx_toneslideNOW
			move	(sp)+,d1
			bra.w	aon_dofx_setvolume
; --------------------------------------------------------------------
; 's'
aon_dofx_finevolslidePort
			move	d1,-(sp)
			bsr.w	aon_dofx_toneslideNOW
			move	(sP)+,d1
			bra.b	aon_dofx_fineVOlUpDown
; --------------------------------------------------------------------
; 't'
aon_dofx_settrackvol
			move	d1,aon_trackvol(a4)
			rts
; --------------------------------------------------------------------
; 'u'
;
aon_dofx_setwavecont	move.b	d1,d2
			and.b	#$f,d1
			move.b	d1,aon_synthWAVECONT(a4)
			lsr.b	#4,d2
			move.b	d2,aon_synthwaveSTOP(a4)
			rts
; --------------------------------------------------------------------
; 'v'
; --------------------------------------------------------------------
; 'w'
; --------------------------------------------------------------------
; 'x'
aon_dofx_externalevent
			tst.b	aon_framecnt(a6)	; nur 1* aufrufen!!!
			beq.b	.yo
			rts
.yo			lea	aon_event(pc),a0	; pc-relativ bleiben
			move.b	d1,(a0)
			rts
; --------------------------------------------------------------------
; 'y'
aon_dofx_externalevent2
			tst.b	aon_framecnt(a6)	; nur 1* aufrufen!!!
			beq.b	.yo
			rts
.yo			lea	aon_event+1(pc),a0	; pc-relativ bleiben
			move.b	d1,(a0)
			rts
; --------------------------------------------------------------------
; 'z'
aon_dofx_externalevent3
			tst.b	aon_framecnt(a6)	; nur 1* aufrufen!!!
			beq.b	.yo
			rts
.yo			lea	aon_event+2(pc),a0	; pc-relativ bleiben
			move.b	d1,(a0)
			rts
; --------------------------------------------------------------------

;========================================================================
AON_STARTINSTR.1
			move	aon_fxCOM(a4),d0
			and	#$0ff0,d0
			cmp	#$0ed0,d0
			beq.w	aon_strtinsonlyrep.1

			btst	#1,aon_chflag(a4)	; bit1= aonflag=2 or 3
			beq.b	aon_strtins.notset1

		tst.b	aon_noiseavoid(a6)
		beq.b	.letsknack
		cmp	#255,aon_oldwavelen(a4)
		bhi.b	.letsknack
		tst	aon_oldwavelen(a4)
		beq.b	.letsknack
		cmp	#255,aon_wavelen(a4)
		ble.b	aon_strtins.notset1
.letsknack		bset	d7,d1
aon_strtins.notset1

			move	aon_period(a4),d0	; baseper+arpeggio
			add	aon_perslide(a4),d0	; portamento value
.checkhiper
			cmp	#103,d0
			bhs.b	.noperalert
			moveq	#103,d0
.noperalert		
			move	d0,$6(a5)
			bsr	setPer

			moveq	#0,d0
			move.b	aon_volume(a4),d0
			moveq	#0,d2
			move.b	aon_synthVOL(a4),d2
			lsr.b	#1,d2
			mulu	d2,d0
			lsr	#6,d0
			mulu	aon_trackvol(a4),d0
			lsr	#6,d0

	move.l	a0,-(sp)
	move.l	master(pc),a0
	mulu	(a0),d0
	move.l	(sp)+,a0
	lsr	#6,d0

			move	d0,$8(a5)
			bsr	setVol

			btst	#1,aon_chflag(a4)
			beq.s	aon_strtinsonlyrep.1
			move.l	aon_waveform(a4),$0(a5)
			move	aon_wavelen(a4),$4(a5)

			pushm	d0/d1
			move.l	aon_waveform(a4),d0
			move	aon_wavelen(a4),d1
			bsr		setAddr
			popm 	d0/d1

aon_strtinsonlyrep.1
			addq.b	#1,d7
aon_strtinsonlyrep.2	lea	aon_chdatasize(a4),a4
			lea	$10(a5),a5
			rts
AON_STARTINSTR.2
			move	aon_fxCOM(a4),d0
			and	#$0ff0,d0
			cmp	#$0ed0,d0
			beq.s	aon_strtinsonlyrep.1


			move.l	aon_repeatstrt(a4),(a5)
			move	aon_replen(a4),$4(a5)
			clr.b	aon_chflag(a4)

			pushm	d0/d1
			move.l	aon_repeatstrt(a4),d0
			move	aon_replen(a4),d1
			bsr		setRep
			popm 	d0/d1

			bra.b	aon_strtinsonlyrep.1
;========================================================================
;aon_dmawait		dc.b	40,0				; rastlines

aon_event		dc.b	0,0,0	; z.b f�r demo-synchronisation
			even

;AON_leer		ds.b	256
AON_hi			dc.b	64,64
AON_multab120	dc	120*0,120*1,120*2,120*3,120*4,120*5,120*6,120*7
		dc	120*8,120*9,120*10,120*11,120*12,120*13,120*14,120*15
AON_PERIODS
	DC.B	$0D,$60,$0C,$A0,$0B,$E8,$0B,$40		;16 finetunes,5 octaves
	DC.B	$0A,$98,$0A,$00,$09,$70,$08,$E8
	DC.B	$08,$68,$07,$F0,$07,$80,$07,$14
	DC.B	$06,$B0,$06,$50,$05,$F4,$05,$A0
	DC.B	$05,$4C,$05,$00,$04,$B8,$04,$74
	DC.B	$04,$34,$03,$F8,$03,$C0,$03,$8A
	DC.B	$03,$58,$03,$28,$02,$FA,$02,$D0
	DC.B	$02,$A6,$02,$80,$02,$5C,$02,$3A
	DC.B	$02,$1A,$01,$FC,$01,$E0,$01,$C5
	DC.B	$01,$AC,$01,$94,$01,$7D,$01,$68
	DC.B	$01,$53,$01,$40,$01,$2E,$01,$1D
	DC.B	$01,$0D,$00,$FE,$00,$F0,$00,$E2
	DC.B	$00,$D6,$00,$CA,$00,$BE,$00,$B4
	DC.B	$00,$AA,$00,$A0,$00,$97,$00,$8F
	DC.B	$00,$87,$00,$7F,$00,$78,$00,$71
	DC.B	$0D,$48,$0C,$88,$0B,$D4,$0B,$2C
	DC.B	$0A,$88,$09,$F4,$09,$64,$08,$DC
	DC.B	$08,$5C,$07,$E4,$07,$74,$07,$08
	DC.B	$06,$A4,$06,$44,$05,$EA,$05,$96
	DC.B	$05,$44,$04,$FA,$04,$B2,$04,$6E
	DC.B	$04,$2E,$03,$F2,$03,$BA,$03,$84
	DC.B	$03,$52,$03,$22,$02,$F5,$02,$CB
	DC.B	$02,$A2,$02,$7D,$02,$59,$02,$37
	DC.B	$02,$17,$01,$F9,$01,$DD,$01,$C2
	DC.B	$01,$A9,$01,$91,$01,$7B,$01,$65
	DC.B	$01,$51,$01,$3E,$01,$2C,$01,$1C
	DC.B	$01,$0C,$00,$FD,$00,$EF,$00,$E1
	DC.B	$00,$D5,$00,$C9,$00,$BD,$00,$B3
	DC.B	$00,$A9,$00,$9F,$00,$96,$00,$8E
	DC.B	$00,$86,$00,$7E,$00,$77,$00,$71
	DC.B	$0D,$30,$0C,$70,$0B,$C0,$0B,$14
	DC.B	$0A,$78,$09,$E0,$09,$54,$08,$CC
	DC.B	$08,$50,$07,$D8,$07,$68,$06,$FC
	DC.B	$06,$98,$06,$38,$05,$E0,$05,$8A
	DC.B	$05,$3C,$04,$F0,$04,$AA,$04,$66
	DC.B	$04,$28,$03,$EC,$03,$B4,$03,$7E
	DC.B	$03,$4C,$03,$1C,$02,$F0,$02,$C5
	DC.B	$02,$9E,$02,$78,$02,$55,$02,$33
	DC.B	$02,$14,$01,$F6,$01,$DA,$01,$BF
	DC.B	$01,$A6,$01,$8E,$01,$78,$01,$63
	DC.B	$01,$4F,$01,$3C,$01,$2A,$01,$1A
	DC.B	$01,$0A,$00,$FB,$00,$ED,$00,$E0
	DC.B	$00,$D3,$00,$C7,$00,$BC,$00,$B1
	DC.B	$00,$A7,$00,$9E,$00,$95,$00,$8D
	DC.B	$00,$85,$00,$7D,$00,$76,$00,$70
	DC.B	$0D,$18,$0C,$5C,$0B,$A8,$0B,$00
	DC.B	$0A,$64,$09,$D0,$09,$40,$08,$BC
	DC.B	$08,$40,$07,$C8,$07,$58,$06,$F0
	DC.B	$06,$8C,$06,$2E,$05,$D4,$05,$80
	DC.B	$05,$32,$04,$E8,$04,$A0,$04,$5E
	DC.B	$04,$20,$03,$E4,$03,$AC,$03,$78
	DC.B	$03,$46,$03,$17,$02,$EA,$02,$C0
	DC.B	$02,$99,$02,$74,$02,$50,$02,$2F
	DC.B	$02,$10,$01,$F2,$01,$D6,$01,$BC
	DC.B	$01,$A3,$01,$8B,$01,$75,$01,$60
	DC.B	$01,$4C,$01,$3A,$01,$28,$01,$18
	DC.B	$01,$08,$00,$F9,$00,$EB,$00,$DE
	DC.B	$00,$D1,$00,$C6,$00,$BB,$00,$B0
	DC.B	$00,$A6,$00,$9D,$00,$94,$00,$8C
	DC.B	$00,$84,$00,$7D,$00,$76,$00,$6F
	DC.B	$0D,$00,$0C,$44,$0B,$94,$0A,$EC
	DC.B	$0A,$50,$09,$BC,$09,$30,$08,$AC
	DC.B	$08,$30,$07,$BC,$07,$4C,$06,$E4
	DC.B	$06,$80,$06,$22,$05,$CA,$05,$76
	DC.B	$05,$28,$04,$DE,$04,$98,$04,$56
	DC.B	$04,$18,$03,$DE,$03,$A6,$03,$72
	DC.B	$03,$40,$03,$11,$02,$E5,$02,$BB
	DC.B	$02,$94,$02,$6F,$02,$4C,$02,$2B
	DC.B	$02,$0C,$01,$EF,$01,$D3,$01,$B9
	DC.B	$01,$A0,$01,$88,$01,$72,$01,$5E
	DC.B	$01,$4A,$01,$38,$01,$26,$01,$16
	DC.B	$01,$06,$00,$F7,$00,$E9,$00,$DC
	DC.B	$00,$D0,$00,$C4,$00,$B9,$00,$AF
	DC.B	$00,$A5,$00,$9C,$00,$93,$00,$8B
	DC.B	$00,$83,$00,$7C,$00,$75,$00,$6E
	DC.B	$0C,$E8,$0C,$2C,$0B,$80,$0A,$D8
	DC.B	$0A,$3C,$09,$AC,$09,$20,$08,$9C
	DC.B	$08,$20,$07,$AC,$07,$3C,$06,$D4
	DC.B	$06,$74,$06,$16,$05,$C0,$05,$6C
	DC.B	$05,$1E,$04,$D6,$04,$90,$04,$4E
	DC.B	$04,$10,$03,$D6,$03,$9E,$03,$6A
	DC.B	$03,$3A,$03,$0B,$02,$E0,$02,$B6
	DC.B	$02,$8F,$02,$6B,$02,$48,$02,$27
	DC.B	$02,$08,$01,$EB,$01,$CF,$01,$B5
	DC.B	$01,$9D,$01,$86,$01,$70,$01,$5B
	DC.B	$01,$48,$01,$35,$01,$24,$01,$14
	DC.B	$01,$04,$00,$F5,$00,$E8,$00,$DB
	DC.B	$00,$CE,$00,$C3,$00,$B8,$00,$AE
	DC.B	$00,$A4,$00,$9B,$00,$92,$00,$8A
	DC.B	$00,$82,$00,$7B,$00,$74,$00,$6D
	DC.B	$0C,$D0,$0C,$18,$0B,$68,$0A,$C4
	DC.B	$0A,$2C,$09,$98,$09,$10,$08,$8C
	DC.B	$08,$10,$07,$9C,$07,$30,$06,$C8
	DC.B	$06,$68,$06,$0C,$05,$B4,$05,$62
	DC.B	$05,$16,$04,$CC,$04,$88,$04,$46
	DC.B	$04,$08,$03,$CE,$03,$98,$03,$64
	DC.B	$03,$34,$03,$06,$02,$DA,$02,$B1
	DC.B	$02,$8B,$02,$66,$02,$44,$02,$23
	DC.B	$02,$04,$01,$E7,$01,$CC,$01,$B2
	DC.B	$01,$9A,$01,$83,$01,$6D,$01,$59
	DC.B	$01,$45,$01,$33,$01,$22,$01,$12
	DC.B	$01,$02,$00,$F4,$00,$E6,$00,$D9
	DC.B	$00,$CD,$00,$C1,$00,$B7,$00,$AC
	DC.B	$00,$A3,$00,$9A,$00,$91,$00,$89
	DC.B	$00,$81,$00,$7A,$00,$73,$00,$6D
	DC.B	$0C,$B8,$0C,$00,$0B,$54,$0A,$B0
	DC.B	$0A,$18,$09,$88,$08,$FC,$08,$7C
	DC.B	$08,$04,$07,$90,$07,$24,$06,$BC
	DC.B	$06,$5C,$06,$00,$05,$AA,$05,$58
	DC.B	$05,$0C,$04,$C4,$04,$7E,$04,$3E
	DC.B	$04,$02,$03,$C8,$03,$92,$03,$5E
	DC.B	$03,$2E,$03,$00,$02,$D5,$02,$AC
	DC.B	$02,$86,$02,$62,$02,$3F,$02,$1F
	DC.B	$02,$01,$01,$E4,$01,$C9,$01,$AF
	DC.B	$01,$97,$01,$80,$01,$6B,$01,$56
	DC.B	$01,$43,$01,$31,$01,$20,$01,$10
	DC.B	$01,$00,$00,$F2,$00,$E4,$00,$D8
	DC.B	$00,$CC,$00,$C0,$00,$B5,$00,$AB
	DC.B	$00,$A1,$00,$98,$00,$90,$00,$88
	DC.B	$00,$80,$00,$79,$00,$72,$00,$6C
	DC.B	$0E,$2C,$0D,$60,$0C,$A0,$0B,$E8
	DC.B	$0B,$40,$0A,$98,$0A,$00,$09,$70
	DC.B	$08,$E8,$08,$68,$07,$F0,$07,$80
	DC.B	$07,$16,$06,$B0,$06,$50,$05,$F4
	DC.B	$05,$A0,$05,$4C,$05,$00,$04,$B8
	DC.B	$04,$74,$04,$34,$03,$F8,$03,$C0
	DC.B	$03,$8B,$03,$58,$03,$28,$02,$FA
	DC.B	$02,$D0,$02,$A6,$02,$80,$02,$5C
	DC.B	$02,$3A,$02,$1A,$01,$FC,$01,$E0
	DC.B	$01,$C5,$01,$AC,$01,$94,$01,$7D
	DC.B	$01,$68,$01,$53,$01,$40,$01,$2E
	DC.B	$01,$1D,$01,$0D,$00,$FE,$00,$F0
	DC.B	$00,$E2,$00,$D6,$00,$CA,$00,$BE
	DC.B	$00,$B4,$00,$AA,$00,$A0,$00,$97
	DC.B	$00,$8F,$00,$87,$00,$7F,$00,$78
	DC.B	$0E,$10,$0D,$48,$0C,$88,$0B,$D4
	DC.B	$0B,$2C,$0A,$8C,$09,$F0,$09,$64
	DC.B	$08,$DC,$08,$5C,$07,$E4,$07,$74
	DC.B	$07,$08,$06,$A4,$06,$44,$05,$EA
	DC.B	$05,$96,$05,$46,$04,$F8,$04,$B2
	DC.B	$04,$6E,$04,$2E,$03,$F2,$03,$BA
	DC.B	$03,$84,$03,$52,$03,$22,$02,$F5
	DC.B	$02,$CB,$02,$A3,$02,$7C,$02,$59
	DC.B	$02,$37,$02,$17,$01,$F9,$01,$DD
	DC.B	$01,$C2,$01,$A9,$01,$91,$01,$7B
	DC.B	$01,$65,$01,$51,$01,$3E,$01,$2C
	DC.B	$01,$1C,$01,$0C,$00,$FD,$00,$EE
	DC.B	$00,$E1,$00,$D4,$00,$C8,$00,$BD
	DC.B	$00,$B3,$00,$A9,$00,$9F,$00,$96
	DC.B	$00,$8E,$00,$86,$00,$7E,$00,$77
	DC.B	$0D,$F8,$0D,$30,$0C,$70,$0B,$C0
	DC.B	$0B,$14,$0A,$78,$09,$E0,$09,$54
	DC.B	$08,$CC,$08,$50,$07,$D8,$07,$68
	DC.B	$06,$FC,$06,$98,$06,$38,$05,$E0
	DC.B	$05,$8A,$05,$3C,$04,$F0,$04,$AA
	DC.B	$04,$66,$04,$28,$03,$EC,$03,$B4
	DC.B	$03,$7E,$03,$4C,$03,$1C,$02,$F0
	DC.B	$02,$C5,$02,$9E,$02,$78,$02,$55
	DC.B	$02,$33,$02,$14,$01,$F6,$01,$DA
	DC.B	$01,$BF,$01,$A6,$01,$8E,$01,$78
	DC.B	$01,$63,$01,$4F,$01,$3C,$01,$2A
	DC.B	$01,$1A,$01,$0A,$00,$FB,$00,$ED
	DC.B	$00,$DF,$00,$D3,$00,$C7,$00,$BC
	DC.B	$00,$B1,$00,$A7,$00,$9E,$00,$95
	DC.B	$00,$8D,$00,$85,$00,$7D,$00,$76
	DC.B	$0D,$DC,$0D,$18,$0C,$5C,$0B,$A8
	DC.B	$0B,$00,$0A,$64,$09,$D0,$09,$40
	DC.B	$08,$BC,$08,$40,$07,$C8,$07,$58
	DC.B	$06,$EE,$06,$8C,$06,$2E,$05,$D4
	DC.B	$05,$80,$05,$32,$04,$E8,$04,$A0
	DC.B	$04,$5E,$04,$20,$03,$E4,$03,$AC
	DC.B	$03,$77,$03,$46,$03,$17,$02,$EA
	DC.B	$02,$C0,$02,$99,$02,$74,$02,$50
	DC.B	$02,$2F,$02,$10,$01,$F2,$01,$D6
	DC.B	$01,$BC,$01,$A3,$01,$8B,$01,$75
	DC.B	$01,$60,$01,$4C,$01,$3A,$01,$28
	DC.B	$01,$18,$01,$08,$00,$F9,$00,$EB
	DC.B	$00,$DE,$00,$D1,$00,$C6,$00,$BB
	DC.B	$00,$B0,$00,$A6,$00,$9D,$00,$94
	DC.B	$00,$8C,$00,$84,$00,$7D,$00,$76
	DC.B	$0D,$C4,$0D,$00,$0C,$44,$0B,$94
	DC.B	$0A,$EC,$0A,$50,$09,$BC,$09,$30
	DC.B	$08,$AC,$08,$30,$07,$B8,$07,$4C
	DC.B	$06,$E2,$06,$80,$06,$22,$05,$CA
	DC.B	$05,$76,$05,$28,$04,$DE,$04,$98
	DC.B	$04,$56,$04,$18,$03,$DC,$03,$A6
	DC.B	$03,$71,$03,$40,$03,$11,$02,$E5
	DC.B	$02,$BB,$02,$94,$02,$6F,$02,$4C
	DC.B	$02,$2B,$02,$0C,$01,$EE,$01,$D3
	DC.B	$01,$B9,$01,$A0,$01,$88,$01,$72
	DC.B	$01,$5E,$01,$4A,$01,$38,$01,$26
	DC.B	$01,$16,$01,$06,$00,$F7,$00,$E9
	DC.B	$00,$DC,$00,$D0,$00,$C4,$00,$B9
	DC.B	$00,$AF,$00,$A5,$00,$9C,$00,$93
	DC.B	$00,$8B,$00,$83,$00,$7B,$00,$75
	DC.B	$0D,$AC,$0C,$E8,$0C,$2C,$0B,$80
	DC.B	$0A,$D8,$0A,$3C,$09,$AC,$09,$20
	DC.B	$08,$9C,$08,$20,$07,$AC,$07,$3C
	DC.B	$06,$D6,$06,$74,$06,$16,$05,$C0
	DC.B	$05,$6C,$05,$1E,$04,$D6,$04,$90
	DC.B	$04,$4E,$04,$10,$03,$D6,$03,$9E
	DC.B	$03,$6B,$03,$3A,$03,$0B,$02,$E0
	DC.B	$02,$B6,$02,$8F,$02,$6B,$02,$48
	DC.B	$02,$27,$02,$08,$01,$EB,$01,$CF
	DC.B	$01,$B5,$01,$9D,$01,$86,$01,$70
	DC.B	$01,$5B,$01,$48,$01,$35,$01,$24
	DC.B	$01,$14,$01,$04,$00,$F5,$00,$E8
	DC.B	$00,$DB,$00,$CE,$00,$C3,$00,$B8
	DC.B	$00,$AE,$00,$A4,$00,$9B,$00,$92
	DC.B	$00,$8A,$00,$82,$00,$7B,$00,$74
	DC.B	$0D,$90,$0C,$D0,$0C,$18,$0B,$68
	DC.B	$0A,$C4,$0A,$2C,$09,$98,$09,$10
	DC.B	$08,$8C,$08,$10,$07,$9C,$07,$30
	DC.B	$06,$C8,$06,$68,$06,$0C,$05,$B4
	DC.B	$05,$62,$05,$16,$04,$CC,$04,$88
	DC.B	$04,$46,$04,$08,$03,$CE,$03,$98
	DC.B	$03,$64,$03,$34,$03,$06,$02,$DA
	DC.B	$02,$B1,$02,$8B,$02,$66,$02,$44
	DC.B	$02,$23,$02,$04,$01,$E7,$01,$CC
	DC.B	$01,$B2,$01,$9A,$01,$83,$01,$6D
	DC.B	$01,$59,$01,$45,$01,$33,$01,$22
	DC.B	$01,$12,$01,$02,$00,$F4,$00,$E6
	DC.B	$00,$D9,$00,$CD,$00,$C1,$00,$B7
	DC.B	$00,$AC,$00,$A3,$00,$9A,$00,$91
	DC.B	$00,$89,$00,$81,$00,$7A,$00,$73
	DC.B	$0D,$78,$0C,$B8,$0C,$00,$0B,$54
	DC.B	$0A,$B0,$0A,$18,$09,$88,$08,$FC
	DC.B	$08,$7C,$08,$04,$07,$90,$07,$24
	DC.B	$06,$BC,$06,$5C,$06,$00,$05,$AA
	DC.B	$05,$58,$05,$0C,$04,$C4,$04,$7E
	DC.B	$04,$3E,$04,$02,$03,$C8,$03,$92
	DC.B	$03,$5E,$03,$2E,$03,$00,$02,$D5
	DC.B	$02,$AC,$02,$86,$02,$62,$02,$3F
	DC.B	$02,$1F,$02,$01,$01,$E4,$01,$C9
	DC.B	$01,$AF,$01,$97,$01,$80,$01,$6B
	DC.B	$01,$56,$01,$43,$01,$31,$01,$20
	DC.B	$01,$10,$01,$00,$00,$F2,$00,$E4
	DC.B	$00,$D8,$00,$CB,$00,$C0,$00,$B5
	DC.B	$00,$AB,$00,$A1,$00,$98,$00,$90
	DC.B	$00,$88,$00,$80,$00,$79,$00,$72


;========================================================================
AON_vibrato_sine
; ripped from ptreplay2.3
	dc.b	0,24,49,74,97,120,141,161
	dc.b	180,197,212,224,235,244,250,253
	dc.b	255,253,250,244,235,224,212,197
	dc.b	180,161,141,120,97,74,49,24	; ->32 bytes
AON_vibrato_rampdown
	dc.b	255,248,240,232,224,216,208,200,192,184,176,168,160,152,144
	dc.b	136,128,120,112,104,96,88,80,72,64,56,48,40,32,24,16,8
AON_vibrato_square
	dcb.b	32,255


;========================================================================
AON_DATA
;�������
aon_speed		rs.b	1	;0=off , 1-255
aon_framecnt		rs.b	1	;0-aon_speed
aon_patcnt		rs	1	;-1= break pat
aon_looppoint		rs.b	1
aon_loopcnt		rs.b	1
aon_loopflag		rs.b	1
aon_pos			rs.b	1	;actual pos while replaying 
aon_statdata		rs.l	1	;address of static data in module
aon_arpdata		rs.l	1	;Pointer on arpeggio lists
aon_posdata		rs.l	1	;address of position tab
aon_pattdata		rs.l	1	;Pointer on patterns	(1st)
aon_patdelaycnt		rs	1
aon_wavestarts		rs.b	256	;adrs of waveforms (0-63)
aon_instrstarts		rs.b	256	;adrs of instruments (1-61)
aon_modulestart		rs.l	1	;Start of module
aon_replayMode		rs.b	1	;0=VBI,1=CIA A&B
aon_tempo		rs.b	1	;tempo 32-255 (bei cia-use speed=6)
aon_noiseavoid		rs.b	1
aon_oversize		rs.b	1
acteditpattern		rs.b	1
aon_dmaflag		rs.b	1
aon_dmacon		rs	1
aon_datasize		rs	1
			dcb.b	aon_datasize

AON_CHANNELS
;�����������
			rsreset
aon_chflag		rs.b	1	;<>0 = new wave! (1=sample,2=synth)
aon_lastnote		rs.b	1	;well,the last note I guess ?!!!!
aon_waveform		rs.l	1	;wavestart
aon_wavelen		rs	1	;wavelen/2 (dma!)
aon_oldwavelen		rs	1	;to avoid noise when using rep <512bytes
aon_repeatstrt		rs.l	1	;repeatwavestart
aon_replen		rs	1	;repeat-lenght/2 (dma!)
aon_instrptr		rs.l	1	;POINTER oN ACT. INSTRDATA
aon_volume		rs.b	1	;Act.Volume (written into register)

aon_stepfxcnt		rs.b	1	;notecut/delay/retrig

aon_chMODE		rs.b	1	;0=sample8,1=synth8
aon_vibratospd		rs.b	1
aon_vibratoampl		rs.b	1
aon_vibratopos		rs.b	1
aon_vibratotrigdelay	rs	1	;-1=already triggered

aon_period		rs	1	;Act.periode (written into register)
				;	;(including slide up/down etc..)
aon_perslide		rs	1	;Added to periode (e.g. 4 portamento)

aon_arpeggiooff		rs	1
aon_arpeggiotab		rs.b	16	;7 �ffsets (+ endmark) in per.tab
aon_arpeggiospd		rs.b	1	;Frame-Change-Speed
aon_arpeggiocnt		rs.b	1	;Countdown

aon_synthWAVEactPTR	rs.l	1	;actptr	(absolute waveform-adressen!!)
aon_synthWAVEendPTR	rs.l	1	;endwaveptr
aon_synthWAVErepPTR	rs.l	1	;anfang des repeat-teils
aon_synthWAVErependPTR	rs.l	1	;ende des repeat teils
aon_synthWAVEaddbytes	rs.l	1	;addiere/subtrahiere xxxx bytes
aon_synthWAVEcnt	rs.b	1	;framecnt
aon_synthWAVEspd	rs.b	1	;wechsel der waveform jeden n-ten frame
aon_synthWAVErepctrl	rs.b	1	;0=normal,1=back,2=pingpong
aon_synthWAVECONT	rs.b	1	;0=normal,1=wave durchlaufen lassen
aon_synthADD		rs.b	1
aon_synthSUB		rs.b	1
aon_synthEND		rs.b	1
aon_synthENV		rs.b	1	;0=NO AR envelope
aon_synthVOL		rs.b	1	;akt. adsr byte (*volume/64=abs vol!!)
aon_vibON		rs.b	1	;1=Do Vibrato!
aon_synthwaveSTOP	rs.b	1	;1=dont continue wave until U10
aon_vibDONE		rs.b	1	;1=Vibrato done
aon_vibCONT		rs.b	1+1	;1=Dauervibrato(wavetable),0=Only '4'etc


aon_fxCOM		rs.b	1	;Effect-Command
aon_fxDAT		rs.b	1	;Effect-Parameter

aon_oldsampoff		rs.l	1	;used for '9' effect
aon_glissspd		rs	1	;speed for '3' effect

aon_slideflag		rs.b	1	;<>0=Sliding active
aon_actwavenr		rs.b	1

aon_trackvol		rs	1	;64=max,0=track mute

aon_chdatasize		rs	1

			ds.b	aon_chdatasize*4


;			dcb.b	aon_datasize
;========================================================================

			dc	0




PLAYEREND
