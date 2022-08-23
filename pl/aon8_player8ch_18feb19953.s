;APS00000046000000460000004600000046000000460000004600000046000000460000004600000046
	incdir	include:
	include	exec/exec_lib.i
	include	hardware/intbits.i
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


  ifnd TEST
TEST=1
  endif
  
  ifne TEST

		section	test,code

main
	lea	mod,a0
	lea	mastervol,a1
	lea	songend_,a2
	lea	tempofunc,a3
	lea	scope_,a4
	jsr	init
	bne	exit
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

	jsr	end
exit
	rts


tempofunc
	rts

mastervol	dc	64/1
songend_	dc	0
scope_		ds.b 	scope_size
 endif
	

;####################################################################
			section	replay,code
playerstart
; jumptable
;			jmp	aon_init(pc)
;			jmp	aon_end(pc)
;			jmp	aon_init(pc)



	jmp init(pc) 
	jmp play(pc)
	jmp end(pc) 
	jmp stop(pc)
	jmp continue(pc)

masterAddr	dc.l	0
master		dc.w	0
ciasetter	dc.l 	0
songend		dc.l 	0
scopeAddr	dc.l	0
buffers		dc.l	0

* a0 = module
* a1 = main vol
* a2 = songend 
* a3 = cia timer setter func
* a4 = scope data
init
	move.l	a4,scopeAddr
	lea	masterAddr(pc),a4
	move.l	a1,(a4)
	lea	songend(pc),a4  
	move.l	a2,(a4)
	lea	ciasetter(pc),a4  
	move.l	a3,(a4)

	push	a0
	move.l	4.w,a6
	move.l	#512+mix_buflen*4*2,d0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	lore	Exec,AllocMem
	move.l	d0,buffers
	pop	a0
	tst.l	d0
	beq		.err
	
	move.l	buffers(pc),a1
	moveq	#0,d0		; startpos
	move	#135,d1		; mixrate, as Paula period
	jsr	aon_init
	;tst.l	d0
	;bmi	.err

	move.l	scopeAddr(pc),a0
	move	#64,ns_vol+scope_ch1(a0)
	move	#64,ns_vol+scope_ch2(a0)
	move	#64,ns_vol+scope_ch3(a0)
	move	#64,ns_vol+scope_ch4(a0)
	move	mix_mixrate(pc),ns_period+scope_ch1(a0)
	move	mix_mixrate(pc),ns_period+scope_ch2(a0)
	move	mix_mixrate(pc),ns_period+scope_ch3(a0)
	move	mix_mixrate(pc),ns_period+scope_ch4(a0)
	move	#mix_buflen/2,ns_length+scope_ch1(a0)
	move	#mix_buflen/2,ns_length+scope_ch2(a0)
	move	#mix_buflen/2,ns_length+scope_ch3(a0)
	move	#mix_buflen/2,ns_length+scope_ch4(a0)
	move	#mix_buflen/2,ns_replen+scope_ch1(a0)
	move	#mix_buflen/2,ns_replen+scope_ch2(a0)
	move	#mix_buflen/2,ns_replen+scope_ch3(a0)
	move	#mix_buflen/2,ns_replen+scope_ch4(a0)
	move.l	mix_buff1(pc),ns_start+scope_ch1(a0)
	move.l	mix_buff2(pc),ns_start+scope_ch2(a0)
	move.l	mix_buff3(pc),ns_start+scope_ch3(a0)
	move.l	mix_buff4(pc),ns_start+scope_ch4(a0)
	move.l	mix_buff1(pc),ns_loopstart+scope_ch1(a0)
	move.l	mix_buff2(pc),ns_loopstart+scope_ch2(a0)
	move.l	mix_buff3(pc),ns_loopstart+scope_ch3(a0)
	move.l	mix_buff4(pc),ns_loopstart+scope_ch4(a0)


	bsr.w	PatternInit
	moveq	#0,d0 
	rts 

.err
	moveq	#-1,d0 
	rts

play 
	move.l	masterAddr(pc),a0
	move	(a0),master

	bsr	aon8_playcia


	moveq	#0,d0 
	moveq	#0,d1 
	lea	aon_data(PC),A0
	move.l	aon_statdata(a0),a1
	move.b	aon.songinfo_maxpos(a1),d1	; get maxpos
	move.b	aon_pos(a0),d0 
	rts 

end 	
	bsr.w	aon_end

	lea	buffers(pc),a2
	move.l	(a2),d0
	beq.b 	.x
	clr.l	(a2)
	move.l	d0,a1 
	move.l	#512+mix_buflen*4*2,d0
	move.l	4.w,a6
	lob	FreeMem
.x	rts 

continue
	move	#$800f,$dff096
	rts

stop
	move	#$f,$dff096
	rts


PatternInfo
	ds.b	PI_Stripes	
Stripe1	dc.l	1
Stripe2	dc.l	1
Stripe3	dc.l	1
Stripe4	dc.l	1
Stripe5	dc.l	1
Stripe6	dc.l	1
Stripe7	dc.l	1
Stripe8	dc.l	1


PatternInit
	lea	PatternInfo(PC),A0
	move.w	#8,PI_Voices(A0)	; Number of stripes (MUST be at least 4)
	pea	ConvertNote(pc) 
	move.l	(sp)+,PI_Convert(a0)
	move.l	#4+4+4+4+4+4+4+4,PI_Modulo(A0)	; Number of bytes to next row
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




mix_buflen		=128

aon_timerval		=1773447		pal!!

; ## aon-includes ##

aon.songinfo_mfver	=0
aon.songinfo_maxpos	=1
aon.songinfo_respos	=2

aon.instrtypesample8bit	=0
aon.instrtypesynth1	=1

			rsreset
instr_control		rs.b	1	; instr-type (check out aon.instrtypexxxxx)
instr_volume		rs.b	1	; volume 0-64
instr_finetune		rs.b	1	; finetune -7 to 7  bits 4-7 are unused
instr_waveform		rs.b	1	; waveform 0-63

; sample 8 bit
			rsset	4
sample8_dmaoffset	rs.l	1	; sampleoffset/2 (words)
sample8_dmalen		rs.l	1	; samplelen/2 (words)
sample8_dmarepoffset	rs.l	1	; repeatstrt/2 (words)
sample8_dmareplen	rs.l	1	; repeatlen/2 (words)

; wavetable 8 bit
			rsset	4
synth8_partwavedmalen	rs.b	1	; in words (--> up to 512 bytes)

			rs.b	1	; unused
			rs.b	1
			rs.b	1
			rs.b	1
			rs.b	1

synth8_vibpara		rs.b	1	; the same param. like with effect '4'
synth8_vibdelay		rs.b	1	; framecnt
synth8_vibwave		rs.b	1	; sine,triangle,rectangle
synth8_wavespd		rs.b	1	; framecnt
synth8_wavelen		rs.b	1
synth8_waverep		rs.b	1
synth8_wavereplen	rs.b	1
synth8_waverepctrl	rs.b	1	; 0=repeatnormal/1=backwards/1=pingpong

			rsset	32-4
instr_astart		rs.b	1	; vol_startlevel
instr_aadd		rs.b	1	; zeit bis maximallevel
instr_aend		rs.b	1	; vol_endlevel
instr_asub		rs.b	1	; zeit bis endlevel


;--------------------------------------------------------------------
;--------------------------------------------------------------------
; cia b allokieren
allocciab
 REM
			movem.l	d1-a6,-(sp)
			lea	timerintserverb+10(pc),a0
			lea	timerintnameb(pc),a1
			move.l	a1,(a0)

			move.l	4,a6
			moveq	#0,d0
			lea	ciabname(pc),a1
			jsr	-498(a6)	; openresource
			lea	ciabbase(pc),a1
			move.l	d0,(a1)
			beq.b	ciaerrorb	; resource geöffnet?!

			move.l	d0,a6

			lea	timerintserverb(pc),a1
			lea	aon8_playcia(pc),a0
			move.l	a0,18(a1)
			moveq	#1,d0			; bit 1: timer b
			jsr	-6(a6)		; timer-interrupt dazu
			tst.l	d0
			bne.b	ciaerrorb	; installiert?!?!?!

			move.b	#$6c,$bfd600
			move.b	#$37,$bfd700
			bset	#0,$bfdf00	; timer start
			movem.l	(sp)+,d1-a6
			rts
;--------------------------------------------------------------------
freeciab		movem.l	d1-a6,-(sp)
			bclr	#0,$bfdf00		; timer b stop
			move.l	ciabbase(pc),a6
			lea	timerintserverb(pc),a1
			moveq	#1,d0			; timer-b
			jsr	-12(a6)			; freigeben
			movem.l	(sp)+,d1-a6
			moveq	#0,d0
			rts
ciaerrorb		moveq	#-1,d0
			movem.l	(sp)+,d1-a6
			rts
ciabname		dc.b	"ciab.resource",0
ciabbase		dc.l	0
			even
timerintserverb		dc.l	0,0
			dc.b	2,99 ; type, priority
			dc.l	0		;timerintnameb
			dc.l	0,0
timerintnameb		dc.b	"artofnoise- 8ch-player",0
			even
 EREM

;========================================================================
aon8_playcia:
			movem.l	d1-a6,-(sp)

			bsr.w	aon8_play

			lea	mix_bypass(pc),a0
			moveq	#8-1,d7
			bsr.w	mix_startsamples

			movem.l	(sp)+,d1-a6
			moveq	#0,d0
			rts
;========================================================================
; in:	d0=startpos
;	d1=mixperiod
;	a0=moduleadr
;	a1=bufferptr
; out:	d0= result (0=ok,-1=error occured)
aon_init
			movem.l	d1-d7/a0-a6,-(sp)

			lea	aon_channels,a4
			move	#aon_chdatasize*2-1,d7
.clrch			clr.l	(a4)+
			dbf	d7,.clrch


			cmp.l	#"AON8",(a0)
			bne.w	aon_notinitalized

			lea	aon_data(pc),a6
			move.b	#6,aon_speed(a6)
			move.b	d0,aon_pos(a6)

			move.l	a0,aon_modulestart(a6)

			lea	mix_buff1(pc),a2
			lea	mix_buff1hear(pc),a3
			move.l	a1,(a2)+		; workbuf
			lea	mix_buflen(a1),a1
			move.l	a1,(a3)+		; hearbuf
			lea	mix_buflen(a1),a1
			move.l	a1,(a2)+		; workbuf
			lea	mix_buflen(a1),a1
			move.l	a1,(a3)+		; hearbuf
			lea	mix_buflen(a1),a1
			move.l	a1,(a2)+		; workbuf
			lea	mix_buflen(a1),a1
			move.l	a1,(a3)+		; hearbuf
			lea	mix_buflen(a1),a1
			move.l	a1,(a2)+		; workbuf
			lea	mix_buflen(a1),a1
			move.l	a1,(a3)+		; hearbuf

			lea	mix_mixrate(pc),a1
			move	d1,(a1)

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
			bsr.b	aon_searchchunk
			move.l	a1,a3			; a3=ptr on wlen-tab
			move.l	#"WAVE",d0
			bsr.b	aon_searchchunk		; a1=ptr on wave-adr0
			lea	aon_wavestarts(a6),a2
			move.l	a1,d0
			moveq	#64-1,d7
aon_initwavetab		move.l	d0,(a2)+
			add.l	(a3)+,d0
			dbf	d7,aon_initwavetab

			lea	aon_channels+aon_trackvol(pc),a0
			moveq	#64,d0
			move	d0,aon_chdatasize*0(a0)
			move	d0,aon_chdatasize*1(a0)
			move	d0,aon_chdatasize*2(a0)
			move	d0,aon_chdatasize*3(a0)
			move	d0,aon_chdatasize*4(a0)
			move	d0,aon_chdatasize*5(a0)
			move	d0,aon_chdatasize*6(a0)
			move	d0,aon_chdatasize*7(a0)

			bset	#1,$bfe001 ; filter off
		;	bclr	#1,$bfe001

			;bsr.w	allocciab
			;tst	d0
			;bmi.w	aon_notinitalized
			bsr.w	aon_resettimer

			bsr.w	mix_init

			;move.l	$70,oldaudio(a6)
			;lea	mix_play(pc),a1
			;move.l	a1,$70
			bsr	SetIntVector

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

SetIntVector
;	rts

        movea.l 4.W,A6
        lea     StructInt(PC),A1
        moveq   #INTB_AUD0,D0
        jsr     _LVOSetIntVector(A6)            ; SetIntVector
        move.l  D0,Channel0
        lea     StructInt(PC),A1
        moveq   #INTB_AUD1,D0
        jsr     _LVOSetIntVector(A6)
        move.l  D0,Channel1
        lea     StructInt(PC),A1
        moveq   #INTB_AUD2,D0
        jsr     _LVOSetIntVector(A6)
        move.l  D0,Channel2
        lea     StructInt(PC),A1
        moveq   #INTB_AUD3,D0
        jsr     _LVOSetIntVector(A6)
        move.l  D0,Channel3
	move	#$c780,$dff09a
        rts

ClearIntVector
;	rts

        movea.l 4.W,A6
        movea.l Channel0(PC),A1
        moveq   #INTB_AUD0,D0
        jsr     _LVOSetIntVector(A6)
        movea.l Channel1(PC),A1
        moveq   #INTB_AUD1,D0
        jsr     _LVOSetIntVector(A6)
        movea.l Channel2(PC),A1
        moveq   #INTB_AUD2,D0
        jsr     _LVOSetIntVector(A6)
        movea.l Channel3(PC),A1
        moveq   #INTB_AUD3,D0
        jmp     _LVOSetIntVector(A6)


Channel0
        dc.l    0
Channel1
        dc.l    0
Channel2
        dc.l    0
Channel3
        dc.l    0
StructInt
        dc.l    0
        dc.l    0
        dc.w    $205
        dc.l    IntName
        dc.l    0
        dc.l    mix_play
IntName
        dc.b    'AON8 audio',0,0
        even



aon_notinitalized	movem.l	(sp)+,d1-d7/a0-a6
			moveq	#-1,d0		; yep,seems that an error
			rts			; has occured... bad luck..!

;========================================================================
aon_end

			move	#$0780,$dff09a
;			move.l	oldaudio(a6),$70
			bsr	ClearIntVector
			lea	aon_data(pc),a6
			;bsr.w	freeciab
			move	#$ff,$dff09e	; no modulation
			move	#$f,$dff096	; dma off
			clr	$dff0a8
			clr	$dff0b8
			clr	$dff0c8
			clr	$dff0d8
			rts
;========================================================================
; a6=data
; get new step ...!
aon_getdachannel
			move.b	2(a0),aon_fxcom(a4)	; needed l8r on
			and.b	#$3f,aon_fxcom(a4)
			move	2(a0),d0
			and	#$3fff,d0
			move.b	d0,d1
			move.b	d0,aon_fxdat(a4)
			cmp.b	#$d,aon_fxcom(a4)
			bne.b	.nobreak
			cmp.b	#$100-4,aon_patcnt+1(a6)
			bne.b	.nobreak
			move.b	#$100-8,aon_patcnt+1(a6)
.nobreak

			and.b	#$f0,d0
			and.b	#$0f,d1

			clr.b	aon_stepfxcnt(a4)

			cmp.b	#16,aon_fxcom(a4)	; 'g' volset
			bne.b	.novoldel
			move.b	aon_fxdat(a4),d2
			and.b	#$f,d2
			move.b	d2,aon_stepfxcnt(a4)
			bra.b	aon_gdc_nomorefx
.novoldel
			cmp	#$0ec0,d0
			bne.s	aon_gdc_nonotecut	; note cut ?
			move.b	d1,aon_stepfxcnt(a4)
			bra.b	aon_gdc_nomorefx
aon_gdc_nonotecut
			cmp	#$0ee0,d0		; pattern delay?
			bne.s	aon_gdc_nopatdelay
			tst.b	aon_patdelaycnt+1(a6)	; delaying ?
			bpl.s	aon_gdc_nopatdelay
			move.b	d1,aon_patdelaycnt+1(a6) ; start delay!
			bra.b	aon_gdc_nomorefx
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

aon_gdc_nomorefx
			moveq	#0,d0
			moveq	#0,d1
			moveq	#0,d5			; flag for useoldinstr
			move.b	1(a0),d1		; get instrnr.
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
			cmp.b	#3,aon_fxcom(a4)
			beq.w	aon_gdc_nonewinstr
			cmp.b	#5,aon_fxcom(a4)
			beq.w	aon_gdc_nonewinstr
			cmp.b	#27,aon_fxcom(a4)
			beq.w	aon_gdc_nonewinstr
			cmp.b	#28,aon_fxcom(a4)
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
			move.b	#01,aon_chflag(a4)	; 01=new repeatwave
			bra.w	aon_startrepeat
aon_gdc_notchangerepeat
			clr.l	aon_oldsampoff(a4)

			add.b	d1,d1
			add.b	d1,d1
			lea	aon_instrstarts(a6),a2
			move.l	(a2,d1),a2

			cmp.l	aon_instrptr(a4),a2
			bne.s	aon_gdc_notsameinstr
			cmp.b	#3,aon_fxcom(a4)
			beq.w	aon_gdc_resetvolume.etc
			cmp.b	#5,aon_fxcom(a4)
			beq.w	aon_gdc_resetvolume.etc
			cmp.b	#27,aon_fxcom(a4)
			beq.w	aon_gdc_resetvolume.etc
			cmp.b	#28,aon_fxcom(a4)
			beq.w	aon_gdc_resetvolume.etc
aon_gdc_notsameinstr
			move.l	a2,aon_instrptr(a4)	; save in channeldata
aon_gdc_useoldinstr

			clr.b	aon_vibcont(a4)
			bsr.w	aon_initadsr

			tst.b	instr_control(a2)	; synthmode on??
			beq.w	aon_startsample
************* hier nach instrumenten-typen unterscheiden!!!!!!!!!!!!!********
************* hier nach instrumenten-typen unterscheiden!!!!!!!!!!!!!********
************* hier nach instrumenten-typen unterscheiden!!!!!!!!!!!!!********

; ---- init synthetic instrument ---------------	16-juli-1994
aon_gdc_initsynth

			move.b	#1,aon_chmode(a4)

			move	aon_fxcom(a4),d0
			move.b	d0,d1
			and.b	#$f0,d0

			cmp	#$0e90,d0		; retrig note?
			bne.s	.noretrigging
			and.b	#$0f,d1
			move.b	d1,aon_stepfxcnt(a4)
.noretrigging

			lea	aon_wavestarts(a6),a3

			move.b	(a0),d2			; alter fehler: bei
			and.b	#63,d2			; wechsel des instr.
			beq.w	aon_gdc_resetvolume.etc	; wurde «perslide» re-
			clr	aon_perslide(a4)	; settet!

			moveq	#0,d3
			cmp.b	#17,aon_fxcom(a4)	; 'h'  synthcontrol?!
			bne.b	.noth
			move.b	aon_fxdat(a4),d3
.noth
			btst	#4,d3
			bne.w	.initvib

			cmp	#$0ed0,d0		; delay note?
			bne.s	.notdelaynote
			and.b	#$0f,d1
			move.b	d1,aon_stepfxcnt(a4)
			bra.b	.startrepeat
.notdelaynote		move.b	#3,aon_chflag(a4)	; 3=new wave
.startrepeat

			moveq	#0,d0
			move.b	instr_waveform(a2),d0	; nr. of waveform
			move.b	d0,aon_actwavenr(a4)
			add	d0,d0
			add	d0,d0			; *4 (longword!)
			move.l	(a3,d0.l),d1		; get address..
; d1=address of actual waveform
			cmp.l	aon_waveform(a4),d1
			bne.b	.notsamewaveu
			clr.b	aon_chflag(a4)

			tst.b	aon_synthwavecont(a4)	; wave
			bne.w	.initvib		; nicht resetten!!

.notsamewaveu		move.l	d1,aon_waveform(a4)

.checkoffset
			moveq	#0,d0
			move.b	synth8_partwavedmalen(a2),d0

			cmp.b	#9,aon_fxcom(a4)
			bne.b	.notoffset
			moveq	#0,d2
			move.b	aon_fxdat(a4),d2
			mulu	d0,d2
			add.l	d1,d2
			move.l	d2,d1
;aon_synthwaveactptr(a4)
			tst.b	aon_synthwavestop(a4)
			beq.b	.notoffset
			move.l	d1,aon_synthwaveactptr(a4)
			move.l	d1,aon_repeatstrt(a4)
			bra.b	.initvib
.notoffset
			tst.b	aon_synthwavestop(a4)
			bne.b	.initvib

			move.l	d1,aon_synthwaveactptr(a4)


			move	aon_wavelen(a4),aon_oldwavelen(a4)

			move	d0,aon_wavelen(a4)
			move	d0,aon_replen(a4)

			add	d0,d0
			move.l	d0,aon_synthwaveaddbytes(a4)

			moveq	#0,d2
			move.b	synth8_waverep(a2),d2
			mulu	d0,d2
			add.l	d1,d2
			move.l	d2,aon_repeatstrt(a4)

			moveq	#0,d2
			move.b	synth8_wavelen(a2),d2
			mulu	d0,d2
			add.l	d1,d2
			move.l	d2,aon_synthwaveendptr(a4)

			moveq	#0,d2
			move.b	synth8_waverep(a2),d2
			mulu	d0,d2
			add.l	d1,d2
			move.l	d2,aon_synthwaverepptr(a4)

			moveq	#0,d2
			move.b	synth8_wavereplen(a2),d2
			add.b	synth8_waverep(a2),d2
			mulu	d0,d2
			add.l	d1,d2
			move.l	d2,aon_synthwaverependptr(a4)

			move.b	synth8_wavespd(a2),aon_synthwavecnt(a4)
			move.b	synth8_wavespd(a2),aon_synthwavespd(a4)
			move.b	synth8_waverepctrl(a2),aon_synthwaverepctrl(a4)


; vibrato initalisieren
.initvib
;			btst	#0,d3			; restart
;			beq.b	.vibke			; volume
;			clr.b	aon_synthenv(a4)	; envelope ?!?
;.vibke
			clr.b	aon_vibon(a4)
			cmp.b	#3,synth8_vibwave(a2)	; 'off' ?!
			beq.b	.viboff

			moveq	#0,d1
			move.b	synth8_vibdelay(a2),d1
			move	d1,aon_vibratotrigdelay(a4)
			moveq	#0,d1
			move.b	synth8_vibpara(a2),d1
			bne.b	.vib
			move	#-2,aon_vibratotrigdelay(a4)
			bra.b	.novib
.vib			move.l	a2,-(sp)
			bsr.w	aon_dofx_vibratoparam	; set parameters
			move.l	(sp)+,a2
			move.b	synth8_vibwave(a2),d0
			ror.b	#3,d0
			and.b	#%10011111,aon_vibratoampl(a4)
			or.b	d0,aon_vibratoampl(a4)
			move.b	#1,aon_vibcont(a4)
			
.novib
			bra.w	aon_gdc_resetvolume.etc
.viboff			move.b	#"!",aon_vibon(a4)
			bra.w	aon_gdc_resetvolume.etc

; --------------------- init sample8bit instrument ----------------------
aon_startsample

			move.b	#"!",aon_vibon(a4)
			clr.b	aon_chmode(a4)
			move	aon_fxcom(a4),d0
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
			move.b	#03,aon_chflag(a4)	; 03=new samplewave
aon_startrepeat		lea	aon_wavestarts(a6),a3

;			cmp.b	#$3,aon_fxcom(a4)
;			beq.w	.resetper
;		cmp.b	#$5,aon_fxcom(a4)
;		bne.b	.noresetper
;.resetper
			move.b	(a0),d2			; alter fehler: bei
			and.b	#63,d2			; wechsel des instr.
			beq.b	.noresetper		; wurde «perslide» re-
			clr	aon_perslide(a4)	; settet!
.noresetper			

			moveq	#0,d0
			move.b	instr_waveform(a2),d0	; nr. of waveform
			move.b	d0,aon_actwavenr(a4)
			add	d0,d0
			add	d0,d0			; *4 (longword!)
			move.l	(a3,d0.l),d1		; get address..
; d1=address of actual waveform

			move.l	sample8_dmalen(a2),d4
			move	aon_wavelen(a4),aon_oldwavelen(a4)
			move	d4,aon_wavelen(a4)

			tst.l	sample8_dmareplen(a2)	; is there any repeat?!
			bne.b	sample8_theresarepeat
			move.l	a2,-(sp)
			lea	aon_leer(pc),a2
			move.l	a2,aon_repeatstrt(a4)
			move.l	(sp)+,a2
			move	#1,aon_replen(a4)
			bra.b	sample8_theresnorepeat
sample8_theresarepeat

			move.l	sample8_dmarepoffset(a2),d2

		tst.b	aon_oversize(a6)
		bne.b	sample8_notzerorep
		tst.l	d2
		bne.b	sample8_notzerorep	; sonst sind keine
						; samples >128k möglich
		move.l	d1,aon_repeatstrt(a4)	;!!!!!!!!!!!!!!!!
		move	sample8_dmareplen+2(a2),aon_replen(a4)
		bra.b	sample8_zerorep
sample8_notzerorep
			move.l	d2,d3		; save repeatstart in words
			add.l	d2,d2
			add.l	d1,d2
			move.l	d2,aon_repeatstrt(a4)
			moveq	#0,d2
			move	sample8_dmareplen+2(a2),d2	; get repeatlen
			move	d2,aon_replen(a4)	; replen in words

		tst.b	aon_oversize(a6)
		bne.b	sample8_zerorep
		add	d3,d2		; replen+repstart=wavelen
		move	d2,aon_wavelen(a4)

sample8_zerorep
sample8_theresnorepeat
			move.l	sample8_dmaoffset(a2),d2
			add.l	d2,d2			; get bytesize!

			move.l	aon_oldsampoff(a4),d4
			lsr.l	#1,d4
			sub	d4,aon_wavelen(a4)	; offset from last com

			cmp.b	#9,aon_fxcom(a4)	; effect 'sampoff'
			bne.s	aon_gdc_nonewsampoff	; no ??

			moveq	#0,d3
			move.b	aon_fxdat(a4),d3	; get offset
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
			add.l	d1,d2			; realstart of wave
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
			move.b	(a0),d0			; get note
			and.b	#%00111111,d0
			bne.s	aon_gdc_notefound	; 0=pause

			move.b	aon_lastnote(a4),d0	; use last note!
			beq.w	aon_gdc_nonewnote
			cmp	#60,d0
			bgt.w	aon_gdc_nonewnote	; >b-3? -->pause!!!
			bra.b	aon_gdc_getarpeggio	; no instr retrig!!

aon_gdc_notefound	
			clr.b	aon_slideflag(a4)
			move.b	d0,aon_lastnote(a4)
			cmp	#60,d0
			bgt.w	aon_gdc_nonewnote	; >b-3? -->pause!!!

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

			cmp.b	#27,aon_fxcom(a4)
			beq.b	aon_arpslide
			cmp.b	#28,aon_fxcom(a4)
			beq.b	aon_arpslide
			cmp.b	#5,aon_fxcom(a4)
			beq.b	aon_arpslide
			cmp.b	#3,aon_fxcom(a4)
			bne.b	aon_notarpslide
aon_arpslide		move.b	(a0),d0
			and.b	#$3f,d0
			beq.b	aon_notarpslide
			move.b	#1,aon_slideflag(a4)
			lea	aon_periods(pc),a1
			move	(a1,d2.l),d1

			move	aon_period(a4),d0
			add	aon_perslide(a4),d0
			sub	d1,d0			; -actual periode=diff.
			move	d0,aon_perslide(a4)

;;;;;bra	aon_notarpslide

aon_notarpslide
			lea	aon_arpeggiotab(a4),a1
			cmp	#-1,2(a1)		; arpeggio im letzten
			bne.b	aon_noarpreset		; step aktiv ?!
			clr	aon_arpeggiooff(a4)
			clr.b	aon_arpeggiocnt(a4)
aon_noarpreset
			tst.b	aon_fxcom(a4)
			bne.b	aon_gdc_noproarp
			tst.b	aon_fxdat(a4)
			beq.s	aon_gdc_noproarp
; protracker-arpeggio (fxcom=0) auslesen
			moveq	#0,d0
			moveq	#0,d1
			move.b	aon_fxdat(a4),d0
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
; professional arpeggio
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
aon_gdc_writearps	moveq	#0,d1
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
			bne.b	aon_gdc_writearps
aon_gdc_arpend		move	#-1,(a1)
aon_gdc_nonewnote	rts
aon_gdc_emptyarp
			clr	aon_arpeggiooff(a4)
			move.b	aon_arpeggiospd(a4),aon_arpeggiocnt(a4)
			subq.b	#1,aon_arpeggiocnt(a4)
			move	d2,(a1)+
			bra.b	aon_gdc_arpend
;========================================================================
; vol-envelope initalisieren
;
; start		0-255
; add 0-255 bis	255
; sub 0-255 bis
; end		0-255

;
; a2=instrumentdata
; a4=channeldata
aon_initadsr:		
			cmp.b	#17,aon_fxcom(a4)
			bne.b	.noth
			move.b	aon_fxdat(a4),d3
			btst	#0,d3
			bne.b	.exit
.noth
			move.b	instr_astart(a2),aon_synthvol(a4)
			move.b	instr_aadd(a2),d0
			beq.b	.noadsr
			move.b	d0,aon_synthadd(a4)
			move.b	instr_asub(a2),aon_synthsub(a4)
			move.b	instr_aend(a2),aon_synthend(a4)

			move.b	#1,aon_synthenv(a4)	; envelope add
.exit			rts

.noadsr			move.b	#127,aon_synthvol(a4)
			clr.b	aon_synthenv(a4)	; envelope off
			rts

;========================================================================
; dont change a1!!!!!!1
; a4=chptr
aon_dosynth
			clr.b	aon_vibdone(a4)
			tst.b	aon_chflag(a4)
			bne.w	.exit
			tst.b	aon_chmode(a4)		; isssees n sample?!
			beq.w	.exitsmpl
			tst.l	aon_waveform(a4)	; keine wellenform !?!
			beq.w	.exit

			tst.b	aon_synthwavestop(a4)
			bne.w	.nonewwave


			addq.b	#1,aon_synthwavecnt(a4)
			move.b	aon_synthwavespd(a4),d0
			cmp.b	aon_synthwavecnt(a4),d0	; framecnt
			bgt.w	.nonewwave
			clr.b	aon_synthwavecnt(a4)
			move.l	aon_synthwaveaddbytes(a4),d0
			add.l	d0,aon_synthwaveactptr(a4)

			tst.l	d0	; partwave wandert nach links?!?!
			bpl.b	.rightloop
			move.l	aon_synthwaverepptr(a4),d0	; links clippen
			cmp.l	aon_synthwaveactptr(a4),d0
			ble.b	.notwaveend
			bra.b	.jumprepeat
.rightloop
			move.l	aon_synthwaveendptr(a4),d0	;rechts clippen
			cmp.l	aon_synthwaveactptr(a4),d0
			bgt.b	.notwaveend
.jumprepeat		tst.b	aon_synthwaverepctrl(a4)
			beq.b	.normalrep
			cmp.b	#1,aon_synthwaverepctrl(a4)
			beq.b	.backrep

.pingpong
		move.l	aon_synthwaverependptr(a4),aon_synthwaveendptr(a4)
			move.l	aon_synthwaveaddbytes(a4),d0
			sub.l	d0,aon_synthwaveactptr(a4)
			neg.l	d0
			move.l	d0,aon_synthwaveaddbytes(a4)
			bra.b	.notwaveend

.normalrep		move.l	aon_synthwaverepptr(a4),aon_synthwaveactptr(a4)
		move.l	aon_synthwaverependptr(a4),aon_synthwaveendptr(a4)
			bra.b	.notwaveend
.backrep	move.l	aon_synthwaverependptr(a4),aon_synthwaveactptr(a4)
			move.l	aon_synthwaveaddbytes(a4),d0
			bmi.b	.alreadyneg
			neg.l	d0
			tst.b	aon_synthwavestop(a4)
			bne.b	.notwaveend
.alreadyneg		add.l	d0,aon_synthwaveactptr(a4)
			move.l	d0,aon_synthwaveaddbytes(a4)
.notwaveend
			move.b	#1,aon_chflag(a4)	; new repoff

;		cmp.b	#9,aon_fxcom(a4)
;		beq.b	.setit
.setit			move.l	aon_synthwaveactptr(a4),aon_repeatstrt(a4)
.nonewwave


.exitsmpl
; do envelope

			tst.b	aon_synthenv(a4)
			beq.b	.dovib
			moveq	#0,d0
			move.b	aon_synthvol(a4),d0
			cmp.b	#1,aon_synthenv(a4)
			bne.b	.decay
			add.b	aon_synthadd(a4),d0
			bpl.b	.newvol
			moveq	#127,d0
			move.b	#2,aon_synthenv(a4)
			bra.b	.newvol
.decay			sub.b	aon_synthsub(a4),d0
			cmp.b	aon_synthend(a4),d0
			bgt.b	.newvol
			move.b	aon_synthend(a4),d0
			clr.b	aon_synthenv(a4)
.newvol			move.b	d0,aon_synthvol(a4)


; vibrato
.dovib
			cmp.b	#"!",aon_vibon(a4)
			beq.b	.vibok
			cmp	#-1,aon_vibratotrigdelay(a4)
			bne.b	.delayvib
			move.b	#1,aon_vibon(a4)
			bra.b	.vibok
.delayvib		subq	#1,aon_vibratotrigdelay(a4)
.vibok

.exit
			cmp.b	#1,aon_vibon(a4)
			bne.b	.viboff
			bra.w	aon_dofx_viboldampl
.viboff			rts
;========================================================================
; a4=channelptr
; don't use a1
aon_dofx
			tst.b	aon_vibcont(a4)
			bne.b	.dauervibrato
			move.b	#"!",aon_vibon(a4)
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
			lea	aon_periods(pc),a3
			move	(a3,d7.l),d0		; get periode
			move	d0,aon_period(a4)	; store in chdata
			addq.b	#2,aon_arpeggiooff+1(a4) ; next value
			and.b	#$0f,aon_arpeggiooff+1(a4)
aon_dofx_nonewarpval

			lea	aon_dosynth(pc),a2
			move.l	a2,-(sp)
;bsr	aon_dosynth

			moveq	#0,d0
			moveq	#0,d1
			move.b	aon_fxdat(a4),d1

			move.b	aon_fxcom(a4),d0
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
			beq.w	aon_dofx_ecommands
			cmp.b	#$f,d0
			beq.w	aon_dofx_setspd
			cmp.b	#16,d0		'g'
			beq.w	aon_dofx_setvoldel
			cmp.b	#18,d0		'i'
			beq.w	aon_dofx_setwaveadsrspd
			cmp.b	#19,d0		'j'
			beq.w	aon_dofx_setarpspd
			cmp.b	#20,d0		'k'
			beq.w	aon_dofx_vibsetvolume
			cmp.b	#21,d0		'l'
			beq.w	aon_dofx_portvolslideup
			cmp.b	#22,d0		'm'
			beq.w	aon_dofx_portvolslidedown
			cmp.b	#23,d0		'n'
			beq.w	aon_dofx_togglenoiseavoid
			cmp.b	#24,d0		'o'
			beq.w	aon_dofx_toggleoversize
			cmp.b	#25,d0		'p'
			beq.w	aon_dofx_finevolslidevib
			cmp.b	#26,d0		'q'
			beq.w	aon_dofx_synthdrums
			cmp.b	#27,d0		'r'
			beq.w	aon_dofx_setvolumeport
			cmp.b	#28,d0		's'
			beq.w	aon_dofx_finevolslideport
			cmp.b	#29,d0		't'
			beq.w	aon_dofx_settrackvol
			cmp.b	#30,d0		'u'
			beq.w	aon_dofx_setwavecont
			cmp.b	#33,d0		'x'
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
			beq.b	aon_dofx_toneslidenow
			move.b	d1,aon_glissspd(a4)
aon_dofx_toneslidenow
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
			move.b	#1,aon_vibon(a4)
aon_dofx_vibratoparam
			tst.b	d1
			beq.b	.goon		; vibrato-parameter
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

; einsprung um vibrato-effekt zu erzeugen
aon_dofx_viboldampl	
			tst.b	aon_vibdone(a4)	; nur ·1· vibrato zur zeit
			bne.b	aon_dofx_vibnotend
			move.b	#1,aon_vibdone(a4)

			moveq	#0,d2
			move.b	aon_vibratoampl(a4),d2
			and.b	#%01100000,d2
			beq.s	aon_dofx_vibsine
			cmp.b	#32,d2
			beq.s	aon_dofx_vibrampdown
			lea	aon_vibrato_square(pc),a2
			bra.b	aon_dofx_vibsquare
aon_dofx_vibrampdown	lea	aon_vibrato_rampdown(pc),a2
			bra.b	aon_dofx_vibsquare
aon_dofx_vibsine	lea	aon_vibrato_sine(pc),a2
aon_dofx_vibsquare
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
			bsr.w	aon_dofx_toneslidenow
			move	(sp)+,d1
			bra.b	aon_dofx_volumeslide
; --------------------------------------------------------------------
; $6
aon_dofx_vibvolumeslide	move	d1,-(sp)
			bsr.w	aon_dofx_viboldampl
			move	(sp)+,d1
			bra.w	aon_dofx_volumeslide
; --------------------------------------------------------------------
; $a
aon_dofx_volumeslide	move.b	d1,d2
			and.b	#$0f,d1
			and.b	#$f0,d2
			lsr.b	#4,d2
			tst.b	d2	; protracker-kompatibilität:
			bne.s	aon_dofx_vsok1	; wenn volume slide up <>0
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
; $b
aon_dofx_breakto
			subq.b	#1,d1
			move.b	d1,aon_pos(a6)
			move	#$ff00,aon_patcnt(a6)
			rts
; --------------------------------------------------------------------
; $c
aon_dofx_setvolume	move.b	d1,aon_volume(a4)
			rts
; --------------------------------------------------------------------
; $d
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
; $f
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
	push	a0		
	move.l	ciasetter(pc),a0
	jsr		(a0)
	pop		a0
			;move.b	d0,$bfd600	; msb	timer setzen
			;lsr	#8,d0		; 8-15
			;move.b	d0,$bfd700	; lsb
aon_dofx_vbireplay
			rts
aon_dofx_replayend	clr.b	aon_speed(a6)
aon_resettimer		move.b	#125,aon_tempo(a6)
	pushm	d0/a0		
			;move.b	#$6c,$bfd600	600
			;move.b	#$37,$bfd700	700
	move	#$376c,d0 
	move.l	ciasetter(pc),a0
	jsr		(a0)
	popm	d0/a0
			rts
; --------------------------------------------------------------------
; | e1- fineslide up                  e1x : value			   |
; | e2- fineslide down                e2x : value			   |
; | e3- glissando control             e3x : 0-off, 1-on (use with tonep.)  |
; | e4- set vibrato waveform          e4x : 0-sine, 1-ramp down, 2-square  |
; | e5- set loop                      e5x : set loop point		   |
; | e6- jump to loop                  e6x : jump to loop, play x times	   |
; | e7- set tremolo waveform          e7x : 0-sine, 1-ramp down. 2-square  |
; | e8- not used							   |
; | e9- retrig note                   e9x : retrig from note + x vblanks   |
; | ea- fine volumeslide up           eax : add x to volume		   |
; | eb- fine volumeslide down         ebx : subtract x from volume	   |
; | ec- notecut                       ecx : cut from note + x vblanks	   |
; | ed- notedelay                     edx : delay note x vblanks	   |
; | ee- patterndelay                  eex : delay pattern x notes	   |
; | ef- invert loop                   efx : speed			   |
; $ex
aon_dofx_ecommands	move.b	d1,d0
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
; $e0
aon_dofx_setfilter	tst.b	d1
			beq.s	aon_dofx_filteron
			bset	#1,$bfe001

			rts
aon_dofx_filteron	bclr	#1,$bfe001

			rts
; --------------------------------------------------------------------
; $e1
aon_dofx_fineportamentoup
			tst.b	aon_framecnt(a6)
			bne.s	aon_dofx_tool8
			sub	d1,aon_perslide(a4)
aon_dofx_tool8		rts
; --------------------------------------------------------------------
; $e2
aon_dofx_fineportamentodn
			tst.b	aon_framecnt(a6)
			bne.s	aon_dofx_tool82
			add	d1,aon_perslide(a4)
aon_dofx_tool82		rts
; --------------------------------------------------------------------
; $e4
aon_dofx_setvibratowave
			and.b	#3,d1
			ror.b	#3,d1
			and.b	#%10011111,aon_vibratoampl(a4)
			or.b	d1,aon_vibratoampl(a4)
			rts
; --------------------------------------------------------------------
; $e5
aon_dofx_setlooppoint
			move.b	aon_patcnt+1(a6),d0
			subq.b	#4,d0
			cmp.b	aon_looppoint(a6),d0
			beq.s	aon_dofx_justloopin
			move.b	d0,aon_looppoint(a6)
			clr.b	aon_loopcnt(a6)
aon_dofx_justloopin	rts
; --------------------------------------------------------------------
; $e6
aon_dofx_jump2loop
			tst.b	d1
			beq.s	aon_dofx_setlooppoint
			rts
; --------------------------------------------------------------------
; $e9
aon_dofx_retrignote	tst.b	aon_stepfxcnt(a4)
			bne.s	aon_dofx_noretrig
			move.b	#3,aon_chflag(a4)
			move.b	#$ef,aon_fxcom(a4)
			rts
aon_dofx_noretrig	subq.b	#1,aon_stepfxcnt(a4)
			rts
; --------------------------------------------------------------------
; $ea
aon_dofx_finevolup
			tst.b	aon_framecnt(a6)
			bne.s	aon_dofx_volresisup
			add.b	d1,aon_volume(a4)
			cmp.b	#64,aon_volume(a4)
			ble.s	aon_dofx_volresisup
			move.b	#64,aon_volume(a4)
aon_dofx_volresisup	rts
; --------------------------------------------------------------------
; $eb
aon_dofx_finevoldn	tst.b	aon_framecnt(a6)
			bne.s	aon_dofx_volresisdn
			sub.b	d1,aon_volume(a4)
			bpl.s	aon_dofx_volresisdn
			clr.b	aon_volume(a4)
aon_dofx_volresisdn	rts
; --------------------------------------------------------------------
; $ec
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
			move.b	d1,aon_synthwavespd(a4)
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
aon_dofx_portvolslideup
			lea	aon_nibbletab(pc),a0
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

aon_nibbletab		dc.b	0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1
; --------------------------------------------------------------------
; 'm'
aon_dofx_portvolslidedown
			lea	aon_nibbletab(pc),a0
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
aon_dofx_finevolslidevib
			move	d1,-(sp)
			bsr.w	aon_dofx_viboldampl
			move	(sp)+,d1
aon_dofx_finevolupdown	moveq	#0,d2
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
aon_dofx_setvolumeport
			move	d1,-(sp)
			bsr.w	aon_dofx_toneslidenow
			move	(sp)+,d1
			bra.w	aon_dofx_setvolume
; --------------------------------------------------------------------
; 's'
aon_dofx_finevolslideport
			move	d1,-(sp)
			bsr.w	aon_dofx_toneslidenow
			move	(sp)+,d1
			bra.b	aon_dofx_finevolupdown
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
			move.b	d1,aon_synthwavecont(a4)
			lsr.b	#4,d2
			move.b	d2,aon_synthwavestop(a4)
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
aon_startinstr.1
			move	aon_fxcom(a4),d0
			and	#$0ff0,d0
			cmp	#$0ed0,d0
			beq.b	aon_strtinsonlyrep.1

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
.noperalert		move	d0,$6(a5)

			moveq	#0,d0
			move.b	aon_volume(a4),d0
			moveq	#0,d2
			move.b	aon_synthvol(a4),d2
			lsr.b	#1,d2
			mulu	d2,d0
			lsr	#6,d0
			mulu	aon_trackvol(a4),d0
			lsr	#6,d0
			move.b	d0,$9(a5)

			btst	#1,aon_chflag(a4)
			beq.s	aon_strtinsonlyrep.1
			move.l	aon_waveform(a4),$0(a5)

			move	aon_wavelen(a4),$4(a5)

aon_strtinsonlyrep.1
			addq.b	#1,d7
aon_strtinsonlyrep.2	lea	aon_chdatasize(a4),a4
			lea	$10(a5),a5
			rts
aon_startinstr.2
			move	aon_fxcom(a4),d0
			and	#$0ff0,d0
			cmp	#$0ed0,d0
			beq.s	aon_strtinsonlyrep.1


			move.l	aon_repeatstrt(a4),(a5)
			move	aon_replen(a4),$4(a5)
			clr.b	aon_chflag(a4)
			bra.b	aon_strtinsonlyrep.1
;========================================================================
;aon_dmawait		dc.b	40,0				; rastlines

aon_event		dc.b	0,0,0	; z.b für demo-synchronisation
			even


aon_leer		ds.b	mix_buflen
aon_hi			dc.b	64,64
aon_multab120	dc	120*0,120*1,120*2,120*3,120*4,120*5,120*6,120*7
		dc	120*8,120*9,120*10,120*11,120*12,120*13,120*14,120*15
aon_periods
	dc.b	$0d,$60,$0c,$a0,$0b,$e8,$0b,$40		16 finetunes,5 octaves
	dc.b	$0a,$98,$0a,$00,$09,$70,$08,$e8
	dc.b	$08,$68,$07,$f0,$07,$80,$07,$14
	dc.b	$06,$b0,$06,$50,$05,$f4,$05,$a0
	dc.b	$05,$4c,$05,$00,$04,$b8,$04,$74
	dc.b	$04,$34,$03,$f8,$03,$c0,$03,$8a
	dc.b	$03,$58,$03,$28,$02,$fa,$02,$d0
	dc.b	$02,$a6,$02,$80,$02,$5c,$02,$3a
	dc.b	$02,$1a,$01,$fc,$01,$e0,$01,$c5
	dc.b	$01,$ac,$01,$94,$01,$7d,$01,$68
	dc.b	$01,$53,$01,$40,$01,$2e,$01,$1d
	dc.b	$01,$0d,$00,$fe,$00,$f0,$00,$e2
	dc.b	$00,$d6,$00,$ca,$00,$be,$00,$b4
	dc.b	$00,$aa,$00,$a0,$00,$97,$00,$8f
	dc.b	$00,$87,$00,$7f,$00,$78,$00,$71
	dc.b	$0d,$48,$0c,$88,$0b,$d4,$0b,$2c
	dc.b	$0a,$88,$09,$f4,$09,$64,$08,$dc
	dc.b	$08,$5c,$07,$e4,$07,$74,$07,$08
	dc.b	$06,$a4,$06,$44,$05,$ea,$05,$96
	dc.b	$05,$44,$04,$fa,$04,$b2,$04,$6e
	dc.b	$04,$2e,$03,$f2,$03,$ba,$03,$84
	dc.b	$03,$52,$03,$22,$02,$f5,$02,$cb
	dc.b	$02,$a2,$02,$7d,$02,$59,$02,$37
	dc.b	$02,$17,$01,$f9,$01,$dd,$01,$c2
	dc.b	$01,$a9,$01,$91,$01,$7b,$01,$65
	dc.b	$01,$51,$01,$3e,$01,$2c,$01,$1c
	dc.b	$01,$0c,$00,$fd,$00,$ef,$00,$e1
	dc.b	$00,$d5,$00,$c9,$00,$bd,$00,$b3
	dc.b	$00,$a9,$00,$9f,$00,$96,$00,$8e
	dc.b	$00,$86,$00,$7e,$00,$77,$00,$71
	dc.b	$0d,$30,$0c,$70,$0b,$c0,$0b,$14
	dc.b	$0a,$78,$09,$e0,$09,$54,$08,$cc
	dc.b	$08,$50,$07,$d8,$07,$68,$06,$fc
	dc.b	$06,$98,$06,$38,$05,$e0,$05,$8a
	dc.b	$05,$3c,$04,$f0,$04,$aa,$04,$66
	dc.b	$04,$28,$03,$ec,$03,$b4,$03,$7e
	dc.b	$03,$4c,$03,$1c,$02,$f0,$02,$c5
	dc.b	$02,$9e,$02,$78,$02,$55,$02,$33
	dc.b	$02,$14,$01,$f6,$01,$da,$01,$bf
	dc.b	$01,$a6,$01,$8e,$01,$78,$01,$63
	dc.b	$01,$4f,$01,$3c,$01,$2a,$01,$1a
	dc.b	$01,$0a,$00,$fb,$00,$ed,$00,$e0
	dc.b	$00,$d3,$00,$c7,$00,$bc,$00,$b1
	dc.b	$00,$a7,$00,$9e,$00,$95,$00,$8d
	dc.b	$00,$85,$00,$7d,$00,$76,$00,$70
	dc.b	$0d,$18,$0c,$5c,$0b,$a8,$0b,$00
	dc.b	$0a,$64,$09,$d0,$09,$40,$08,$bc
	dc.b	$08,$40,$07,$c8,$07,$58,$06,$f0
	dc.b	$06,$8c,$06,$2e,$05,$d4,$05,$80
	dc.b	$05,$32,$04,$e8,$04,$a0,$04,$5e
	dc.b	$04,$20,$03,$e4,$03,$ac,$03,$78
	dc.b	$03,$46,$03,$17,$02,$ea,$02,$c0
	dc.b	$02,$99,$02,$74,$02,$50,$02,$2f
	dc.b	$02,$10,$01,$f2,$01,$d6,$01,$bc
	dc.b	$01,$a3,$01,$8b,$01,$75,$01,$60
	dc.b	$01,$4c,$01,$3a,$01,$28,$01,$18
	dc.b	$01,$08,$00,$f9,$00,$eb,$00,$de
	dc.b	$00,$d1,$00,$c6,$00,$bb,$00,$b0
	dc.b	$00,$a6,$00,$9d,$00,$94,$00,$8c
	dc.b	$00,$84,$00,$7d,$00,$76,$00,$6f
	dc.b	$0d,$00,$0c,$44,$0b,$94,$0a,$ec
	dc.b	$0a,$50,$09,$bc,$09,$30,$08,$ac
	dc.b	$08,$30,$07,$bc,$07,$4c,$06,$e4
	dc.b	$06,$80,$06,$22,$05,$ca,$05,$76
	dc.b	$05,$28,$04,$de,$04,$98,$04,$56
	dc.b	$04,$18,$03,$de,$03,$a6,$03,$72
	dc.b	$03,$40,$03,$11,$02,$e5,$02,$bb
	dc.b	$02,$94,$02,$6f,$02,$4c,$02,$2b
	dc.b	$02,$0c,$01,$ef,$01,$d3,$01,$b9
	dc.b	$01,$a0,$01,$88,$01,$72,$01,$5e
	dc.b	$01,$4a,$01,$38,$01,$26,$01,$16
	dc.b	$01,$06,$00,$f7,$00,$e9,$00,$dc
	dc.b	$00,$d0,$00,$c4,$00,$b9,$00,$af
	dc.b	$00,$a5,$00,$9c,$00,$93,$00,$8b
	dc.b	$00,$83,$00,$7c,$00,$75,$00,$6e
	dc.b	$0c,$e8,$0c,$2c,$0b,$80,$0a,$d8
	dc.b	$0a,$3c,$09,$ac,$09,$20,$08,$9c
	dc.b	$08,$20,$07,$ac,$07,$3c,$06,$d4
	dc.b	$06,$74,$06,$16,$05,$c0,$05,$6c
	dc.b	$05,$1e,$04,$d6,$04,$90,$04,$4e
	dc.b	$04,$10,$03,$d6,$03,$9e,$03,$6a
	dc.b	$03,$3a,$03,$0b,$02,$e0,$02,$b6
	dc.b	$02,$8f,$02,$6b,$02,$48,$02,$27
	dc.b	$02,$08,$01,$eb,$01,$cf,$01,$b5
	dc.b	$01,$9d,$01,$86,$01,$70,$01,$5b
	dc.b	$01,$48,$01,$35,$01,$24,$01,$14
	dc.b	$01,$04,$00,$f5,$00,$e8,$00,$db
	dc.b	$00,$ce,$00,$c3,$00,$b8,$00,$ae
	dc.b	$00,$a4,$00,$9b,$00,$92,$00,$8a
	dc.b	$00,$82,$00,$7b,$00,$74,$00,$6d
	dc.b	$0c,$d0,$0c,$18,$0b,$68,$0a,$c4
	dc.b	$0a,$2c,$09,$98,$09,$10,$08,$8c
	dc.b	$08,$10,$07,$9c,$07,$30,$06,$c8
	dc.b	$06,$68,$06,$0c,$05,$b4,$05,$62
	dc.b	$05,$16,$04,$cc,$04,$88,$04,$46
	dc.b	$04,$08,$03,$ce,$03,$98,$03,$64
	dc.b	$03,$34,$03,$06,$02,$da,$02,$b1
	dc.b	$02,$8b,$02,$66,$02,$44,$02,$23
	dc.b	$02,$04,$01,$e7,$01,$cc,$01,$b2
	dc.b	$01,$9a,$01,$83,$01,$6d,$01,$59
	dc.b	$01,$45,$01,$33,$01,$22,$01,$12
	dc.b	$01,$02,$00,$f4,$00,$e6,$00,$d9
	dc.b	$00,$cd,$00,$c1,$00,$b7,$00,$ac
	dc.b	$00,$a3,$00,$9a,$00,$91,$00,$89
	dc.b	$00,$81,$00,$7a,$00,$73,$00,$6d
	dc.b	$0c,$b8,$0c,$00,$0b,$54,$0a,$b0
	dc.b	$0a,$18,$09,$88,$08,$fc,$08,$7c
	dc.b	$08,$04,$07,$90,$07,$24,$06,$bc
	dc.b	$06,$5c,$06,$00,$05,$aa,$05,$58
	dc.b	$05,$0c,$04,$c4,$04,$7e,$04,$3e
	dc.b	$04,$02,$03,$c8,$03,$92,$03,$5e
	dc.b	$03,$2e,$03,$00,$02,$d5,$02,$ac
	dc.b	$02,$86,$02,$62,$02,$3f,$02,$1f
	dc.b	$02,$01,$01,$e4,$01,$c9,$01,$af
	dc.b	$01,$97,$01,$80,$01,$6b,$01,$56
	dc.b	$01,$43,$01,$31,$01,$20,$01,$10
	dc.b	$01,$00,$00,$f2,$00,$e4,$00,$d8
	dc.b	$00,$cc,$00,$c0,$00,$b5,$00,$ab
	dc.b	$00,$a1,$00,$98,$00,$90,$00,$88
	dc.b	$00,$80,$00,$79,$00,$72,$00,$6c
	dc.b	$0e,$2c,$0d,$60,$0c,$a0,$0b,$e8
	dc.b	$0b,$40,$0a,$98,$0a,$00,$09,$70
	dc.b	$08,$e8,$08,$68,$07,$f0,$07,$80
	dc.b	$07,$16,$06,$b0,$06,$50,$05,$f4
	dc.b	$05,$a0,$05,$4c,$05,$00,$04,$b8
	dc.b	$04,$74,$04,$34,$03,$f8,$03,$c0
	dc.b	$03,$8b,$03,$58,$03,$28,$02,$fa
	dc.b	$02,$d0,$02,$a6,$02,$80,$02,$5c
	dc.b	$02,$3a,$02,$1a,$01,$fc,$01,$e0
	dc.b	$01,$c5,$01,$ac,$01,$94,$01,$7d
	dc.b	$01,$68,$01,$53,$01,$40,$01,$2e
	dc.b	$01,$1d,$01,$0d,$00,$fe,$00,$f0
	dc.b	$00,$e2,$00,$d6,$00,$ca,$00,$be
	dc.b	$00,$b4,$00,$aa,$00,$a0,$00,$97
	dc.b	$00,$8f,$00,$87,$00,$7f,$00,$78
	dc.b	$0e,$10,$0d,$48,$0c,$88,$0b,$d4
	dc.b	$0b,$2c,$0a,$8c,$09,$f0,$09,$64
	dc.b	$08,$dc,$08,$5c,$07,$e4,$07,$74
	dc.b	$07,$08,$06,$a4,$06,$44,$05,$ea
	dc.b	$05,$96,$05,$46,$04,$f8,$04,$b2
	dc.b	$04,$6e,$04,$2e,$03,$f2,$03,$ba
	dc.b	$03,$84,$03,$52,$03,$22,$02,$f5
	dc.b	$02,$cb,$02,$a3,$02,$7c,$02,$59
	dc.b	$02,$37,$02,$17,$01,$f9,$01,$dd
	dc.b	$01,$c2,$01,$a9,$01,$91,$01,$7b
	dc.b	$01,$65,$01,$51,$01,$3e,$01,$2c
	dc.b	$01,$1c,$01,$0c,$00,$fd,$00,$ee
	dc.b	$00,$e1,$00,$d4,$00,$c8,$00,$bd
	dc.b	$00,$b3,$00,$a9,$00,$9f,$00,$96
	dc.b	$00,$8e,$00,$86,$00,$7e,$00,$77
	dc.b	$0d,$f8,$0d,$30,$0c,$70,$0b,$c0
	dc.b	$0b,$14,$0a,$78,$09,$e0,$09,$54
	dc.b	$08,$cc,$08,$50,$07,$d8,$07,$68
	dc.b	$06,$fc,$06,$98,$06,$38,$05,$e0
	dc.b	$05,$8a,$05,$3c,$04,$f0,$04,$aa
	dc.b	$04,$66,$04,$28,$03,$ec,$03,$b4
	dc.b	$03,$7e,$03,$4c,$03,$1c,$02,$f0
	dc.b	$02,$c5,$02,$9e,$02,$78,$02,$55
	dc.b	$02,$33,$02,$14,$01,$f6,$01,$da
	dc.b	$01,$bf,$01,$a6,$01,$8e,$01,$78
	dc.b	$01,$63,$01,$4f,$01,$3c,$01,$2a
	dc.b	$01,$1a,$01,$0a,$00,$fb,$00,$ed
	dc.b	$00,$df,$00,$d3,$00,$c7,$00,$bc
	dc.b	$00,$b1,$00,$a7,$00,$9e,$00,$95
	dc.b	$00,$8d,$00,$85,$00,$7d,$00,$76
	dc.b	$0d,$dc,$0d,$18,$0c,$5c,$0b,$a8
	dc.b	$0b,$00,$0a,$64,$09,$d0,$09,$40
	dc.b	$08,$bc,$08,$40,$07,$c8,$07,$58
	dc.b	$06,$ee,$06,$8c,$06,$2e,$05,$d4
	dc.b	$05,$80,$05,$32,$04,$e8,$04,$a0
	dc.b	$04,$5e,$04,$20,$03,$e4,$03,$ac
	dc.b	$03,$77,$03,$46,$03,$17,$02,$ea
	dc.b	$02,$c0,$02,$99,$02,$74,$02,$50
	dc.b	$02,$2f,$02,$10,$01,$f2,$01,$d6
	dc.b	$01,$bc,$01,$a3,$01,$8b,$01,$75
	dc.b	$01,$60,$01,$4c,$01,$3a,$01,$28
	dc.b	$01,$18,$01,$08,$00,$f9,$00,$eb
	dc.b	$00,$de,$00,$d1,$00,$c6,$00,$bb
	dc.b	$00,$b0,$00,$a6,$00,$9d,$00,$94
	dc.b	$00,$8c,$00,$84,$00,$7d,$00,$76
	dc.b	$0d,$c4,$0d,$00,$0c,$44,$0b,$94
	dc.b	$0a,$ec,$0a,$50,$09,$bc,$09,$30
	dc.b	$08,$ac,$08,$30,$07,$b8,$07,$4c
	dc.b	$06,$e2,$06,$80,$06,$22,$05,$ca
	dc.b	$05,$76,$05,$28,$04,$de,$04,$98
	dc.b	$04,$56,$04,$18,$03,$dc,$03,$a6
	dc.b	$03,$71,$03,$40,$03,$11,$02,$e5
	dc.b	$02,$bb,$02,$94,$02,$6f,$02,$4c
	dc.b	$02,$2b,$02,$0c,$01,$ee,$01,$d3
	dc.b	$01,$b9,$01,$a0,$01,$88,$01,$72
	dc.b	$01,$5e,$01,$4a,$01,$38,$01,$26
	dc.b	$01,$16,$01,$06,$00,$f7,$00,$e9
	dc.b	$00,$dc,$00,$d0,$00,$c4,$00,$b9
	dc.b	$00,$af,$00,$a5,$00,$9c,$00,$93
	dc.b	$00,$8b,$00,$83,$00,$7b,$00,$75
	dc.b	$0d,$ac,$0c,$e8,$0c,$2c,$0b,$80
	dc.b	$0a,$d8,$0a,$3c,$09,$ac,$09,$20
	dc.b	$08,$9c,$08,$20,$07,$ac,$07,$3c
	dc.b	$06,$d6,$06,$74,$06,$16,$05,$c0
	dc.b	$05,$6c,$05,$1e,$04,$d6,$04,$90
	dc.b	$04,$4e,$04,$10,$03,$d6,$03,$9e
	dc.b	$03,$6b,$03,$3a,$03,$0b,$02,$e0
	dc.b	$02,$b6,$02,$8f,$02,$6b,$02,$48
	dc.b	$02,$27,$02,$08,$01,$eb,$01,$cf
	dc.b	$01,$b5,$01,$9d,$01,$86,$01,$70
	dc.b	$01,$5b,$01,$48,$01,$35,$01,$24
	dc.b	$01,$14,$01,$04,$00,$f5,$00,$e8
	dc.b	$00,$db,$00,$ce,$00,$c3,$00,$b8
	dc.b	$00,$ae,$00,$a4,$00,$9b,$00,$92
	dc.b	$00,$8a,$00,$82,$00,$7b,$00,$74
	dc.b	$0d,$90,$0c,$d0,$0c,$18,$0b,$68
	dc.b	$0a,$c4,$0a,$2c,$09,$98,$09,$10
	dc.b	$08,$8c,$08,$10,$07,$9c,$07,$30
	dc.b	$06,$c8,$06,$68,$06,$0c,$05,$b4
	dc.b	$05,$62,$05,$16,$04,$cc,$04,$88
	dc.b	$04,$46,$04,$08,$03,$ce,$03,$98
	dc.b	$03,$64,$03,$34,$03,$06,$02,$da
	dc.b	$02,$b1,$02,$8b,$02,$66,$02,$44
	dc.b	$02,$23,$02,$04,$01,$e7,$01,$cc
	dc.b	$01,$b2,$01,$9a,$01,$83,$01,$6d
	dc.b	$01,$59,$01,$45,$01,$33,$01,$22
	dc.b	$01,$12,$01,$02,$00,$f4,$00,$e6
	dc.b	$00,$d9,$00,$cd,$00,$c1,$00,$b7
	dc.b	$00,$ac,$00,$a3,$00,$9a,$00,$91
	dc.b	$00,$89,$00,$81,$00,$7a,$00,$73
	dc.b	$0d,$78,$0c,$b8,$0c,$00,$0b,$54
	dc.b	$0a,$b0,$0a,$18,$09,$88,$08,$fc
	dc.b	$08,$7c,$08,$04,$07,$90,$07,$24
	dc.b	$06,$bc,$06,$5c,$06,$00,$05,$aa
	dc.b	$05,$58,$05,$0c,$04,$c4,$04,$7e
	dc.b	$04,$3e,$04,$02,$03,$c8,$03,$92
	dc.b	$03,$5e,$03,$2e,$03,$00,$02,$d5
	dc.b	$02,$ac,$02,$86,$02,$62,$02,$3f
	dc.b	$02,$1f,$02,$01,$01,$e4,$01,$c9
	dc.b	$01,$af,$01,$97,$01,$80,$01,$6b
	dc.b	$01,$56,$01,$43,$01,$31,$01,$20
	dc.b	$01,$10,$01,$00,$00,$f2,$00,$e4
	dc.b	$00,$d8,$00,$cb,$00,$c0,$00,$b5
	dc.b	$00,$ab,$00,$a1,$00,$98,$00,$90
	dc.b	$00,$88,$00,$80,$00,$79,$00,$72


;========================================================================
aon_vibrato_sine
; ripped from ptreplay2.3
	dc.b	0,24,49,74,97,120,141,161
	dc.b	180,197,212,224,235,244,250,253
	dc.b	255,253,250,244,235,224,212,197
	dc.b	180,161,141,120,97,74,49,24	; ->32 bytes
aon_vibrato_rampdown
	dc.b	255,248,240,232,224,216,208,200,192,184,176,168,160,152,144
	dc.b	136,128,120,112,104,96,88,80,72,64,56,48,40,32,24,16,8
aon_vibrato_square
	dcb.b	32,255

;========================================================================
;========================================================================
aon_data
;¯¯¯¯¯¯¯
aon_speed		rs.b	1	0=off , 1-255
aon_framecnt		rs.b	1	0-aon_speed
aon_patcnt		rs	1	-1= break pat
aon_looppoint		rs.b	1
aon_loopcnt		rs.b	1
aon_loopflag		rs.b	1
aon_pos			rs.b	1	actual pos while replaying 
aon_statdata		rs.l	1	address of static data in module
aon_arpdata		rs.l	1	pointer on arpeggio lists
aon_posdata		rs.l	1	address of position tab
aon_pattdata		rs.l	1	pointer on patterns	(1st)
aon_patdelaycnt		rs	1
aon_wavestarts		rs.b	256	adrs of waveforms (0-63)
aon_instrstarts		rs.b	256	adrs of instruments (1-61)
aon_modulestart		rs.l	1	start of module
aon_replaymode		rs.b	1	0=vbi,1=cia a&b
aon_tempo		rs.b	1	tempo 32-255 (bei cia-use speed=6)
aon_noiseavoid		rs.b	1
aon_oversize		rs.b	1
aon_dmaflag		rs.b	1+1
aon_dmacon		rs	1
oldaudio		rs.l	1
aon_datasize		rs	1
			dcb.b	aon_datasize

aon_channels
;¯¯¯¯¯¯¯¯¯¯¯
			rsreset
aon_chflag		rs.b	1	<>0 = new wave! (1=sample,2=synth)
aon_lastnote		rs.b	1	well,the last note i guess ?!!!!
aon_waveform		rs.l	1	wavestart
aon_wavelen		rs	1	wavelen/2 (dma!)
aon_oldwavelen		rs	1	to avoid noise when using rep <512bytes
aon_repeatstrt		rs.l	1	repeatwavestart
aon_replen		rs	1	repeat-lenght/2 (dma!)
aon_instrptr		rs.l	1	pointer on act. instrdata
aon_volume		rs.b	1	act.volume (written into register)

aon_stepfxcnt		rs.b	1	notecut/delay/retrig

aon_chmode		rs.b	1	0=sample8,1=synth8
aon_vibratospd		rs.b	1
aon_vibratoampl		rs.b	1
aon_vibratopos		rs.b	1
aon_vibratotrigdelay	rs	1	-1=already triggered

aon_period		rs	1	act.periode (written into register)
				;	(including slide up/down etc..)
aon_perslide		rs	1	added to periode (e.g. 4 portamento)

aon_arpeggiooff		rs	1
aon_arpeggiotab		rs.b	16	7 øffsets (+ endmark) in per.tab
aon_arpeggiospd		rs.b	1	frame-change-speed
aon_arpeggiocnt		rs.b	1	countdown

aon_synthwaveactptr	rs.l	1	actptr	(absolute waveform-adressen!!)
aon_synthwaveendptr	rs.l	1	endwaveptr
aon_synthwaverepptr	rs.l	1	anfang des repeat-teils
aon_synthwaverependptr	rs.l	1	ende des repeat teils
aon_synthwaveaddbytes	rs.l	1	addiere/subtrahiere xxxx bytes
aon_synthwavecnt	rs.b	1	framecnt
aon_synthwavespd	rs.b	1	wechsel der waveform jeden n-ten frame
aon_synthwaverepctrl	rs.b	1	0=normal,1=back,2=pingpong
aon_synthwavecont	rs.b	1	0=normal,1=wave durchlaufen lassen
aon_synthadd		rs.b	1
aon_synthsub		rs.b	1
aon_synthend		rs.b	1
aon_synthenv		rs.b	1	0=no ar envelope
aon_synthvol		rs.b	1	akt. adsr byte (*volume/64=abs vol!!)
aon_vibon		rs.b	1	1=do vibrato!
aon_synthwavestop	rs.b	1	1=dont continue wave until u10
aon_vibdone		rs.b	1	1=vibrato done
aon_vibcont		rs.b	1+1	1=dauervibrato(wavetable),0=only '4'etc


aon_fxcom		rs.b	1	effect-command
aon_fxdat		rs.b	1	effect-parameter

aon_oldsampoff		rs.l	1	used for '9' effect
aon_glissspd		rs	1	speed for '3' effect

aon_slideflag		rs.b	1	<>0=sliding active
aon_actwavenr		rs.b	1

aon_trackvol		rs	1	64=max,0=track mute

aon_chdatasize		rs	1

			ds.b	aon_chdatasize*8


;========================================================================







;; program	:	8-channelmix-test (7bit)
;; author	:	bastian spiegel (twice of lego)
;; date		:	- 23.jan.1995
;; equ		:	68020+ is recommended!

	rem
-mixrate 1-64khz
-7-bit sampleauflösung
-freie lautstärkeeinstellung für jeden kanal
-repeat für jeden kanal
	erem


loop			=1	; if loop is on,the routine needs about 4
				; rastlines more for every channel


mix_init2
			movem.l	d0-a6,-(sp)
			lea	$dff000,a5
			bra.b	mix_init22

mix_init

			movem.l	d0-a6,-(sp)

			lea	$dff000,a5

			lea	mix_multab64(pc),a0
			moveq	#0,d6	; 0-$40
			moveq	#0,d7	; 0-255
mix_in_mtab		moveq	#0,d1
			move.b	d7,d1
			ext	d1
			muls	d6,d1
			asr	#6+1,d1	; /2 teilen!!!!!
			move.b	d1,(a0)+
			addq.b	#1,d7
			bne.s	mix_in_mtab
			addq.b	#1,d6
			cmp.b	#$41,d6
			bne.s	mix_in_mtab

mix_init22
			move	#$f,$96(a5)
			moveq	#2-1,d7
			move.b	#254,d0
.rastwait1		cmp.b	$dff006,d0
			bne.b	.rastwait1
			subq.b	#1,d0
			dbf	d7,.rastwait1

			move.l	mix_buff1(pc),$a0(a5)
			move.l	mix_buff2(pc),$b0(a5)
			move.l	mix_buff3(pc),$c0(a5)
			move.l	mix_buff3(pc),$d0(a5)
			move	#mix_buflen/2,d0
			move	d0,$a4(a5)
			move	d0,$b4(a5)
			move	d0,$c4(a5)
			move	d0,$d4(a5)
			move	mix_mixrate(pc),d0
			move	d0,$a6(a5)
			move	d0,$b6(a5)
			move	d0,$c6(a5)
			move	d0,$d6(a5)
			moveq	#64,d0
			move	d0,$a8(a5)
			move	d0,$b8(a5)
			move	d0,$c8(a5)
			move	d0,$d8(a5)

			move	#$ff,$dff09e	; no modulation
			move	#$800f,$96(a5)

			movem.l	(sp)+,d0-a6
			rts
;--------------------------------------------------------------------
; in:	a0=bypass-ch
;	d7=anzahl kanäle (bis zu 8 !)
mix_startsamples
			moveq	#0,d6
.loop
			moveq	#0,d4
			move	6(a0),d4	; period
			moveq	#0,d5
			move.b	9(a0),d5	; volume
		mulu	master(pc),d5
		lsr		#6,d5
			cmp	#$40,d5
			ble.b	.volok
			moveq	#$40,d5
.volok			move.l	(a0),d0		; samplestart
			moveq	#0,d1
			move	4(a0),d1	; sampledmalen
			add.l	d1,d1		; *2 für bytes
			move.l	10(a0),d2	; repeatstart
			moveq	#0,d3
			move	14(a0),d3	; repeatdmalen
			add.l	d3,d3		; *2 für bytes
			bsr.b	mix_startsample
.nonewsample		lea	$10(a0),a0
			addq	#1,d6
			dbf	d7,.loop
			rts
;--------------------------------------------------------------------
; in:	d0=wavestart
;	d1=wavelen
;	d2=repoff
;	d3=replen
;	d4=period
;	d5=volume
;	d6=channel (0-7)
mix_startsample
			movem.l	d0-a6,-(sp)
			lea	mix_data,a1
			mulu	#mix_datasize,d6
			lea	(a1,d6),a1

			btst	#1,8(a0)
			beq.b	.repeat

			clr	mix_lastfloat(a1)
			move.b	#1,mix_status(a1)
			move.l	d0,mix_wavestart(a1)
			clr.l	mix_waveoff(a1)
			move.l	d1,mix_wavelen(a1)
.repeat			btst	#0,8(a0)
			beq.b	.norepeat

			move.l	d2,mix_repstrt(a1)
			move.l	d3,mix_replen(a1)

.norepeat		lsl.l	#8,d5
			add.l	#mix_multab64,d5
			move.l	d5,mix_volumeptr(a1)

			tst	d4
			beq.b	.noper
			move	d4,mix_period(a1)
			moveq	#0,d0
			move	mix_mixrate(pc),d0
			swap	d0
			divu.l	d4,d0
			tst	d0
			bne.b	.ok
			move	#$ffff,mix_period.float(a1)
			swap	d0
			tst	d0
			beq.b	.set
			subq	#1,d0
			bra.b	.set
.ok			move	d0,mix_period.float(a1)
			swap	d0
.set			move	d0,mix_norm.add(a1)
.noper			clr.b	8(a0)
			movem.l	(sp)+,d0-a6
			rts
;--------------------------------------------------------------------
; durch audioirqs aufrufen
mix_play
;			move	#$f00,$dff180

			btst	#7,$dff01f
			bne.b	mix_play0
			btst	#0,$dff01e
			bne.b	mix_play1
			btst	#1,$dff01e
			bne.w	mix_play2
			btst	#2,$dff01e
			bne.w	mix_play3
			rts
			;nop
			;nop
			;nop
			;rte
mix_play0		movem.l	d0-a6,-(sp)
			;move	#$4000,$dff09a
			lea	mix_buff1(pc),a0
			move.l	(a0),d0
			move.l	16(a0),(a0)
			move.l	d0,16(a0)	
			move.l	d0,$dff0a0
			lea	mix_data+mix_datasize*0,a5
			lea	mix_data+mix_datasize*1,a6
			move.l	16(a0),a4
			bsr.w	mix_channels
			;move	#$c000,$dff09a
			movem.l	(sp)+,d0-a6
			move	#$80,$dff09c
;			move	#$aab,$dff180
			;nop
			;nop
			;nop
			;rte
			rts
mix_play1		movem.l	d0-a6,-(sp)
			;move	#$4000,$dff09a
			lea	mix_buff2(pc),a0
			move.l	(a0),d0
			move.l	16(a0),(a0)	
			move.l	d0,16(a0)	
			move.l	d0,$dff0b0
			lea	mix_data+mix_datasize*2,a5
			lea	mix_data+mix_datasize*3,a6
			move.l	16(a0),a4
			bsr.w	mix_channels
			;move	#$c000,$dff09a
			movem.l	(sp)+,d0-a6
			move	#$100,$dff09c
;			move	#$aab,$dff180
			;nop
			;nop
			;nop
			;rte
			rts
mix_play2		movem.l	d0-a6,-(sp)
			;move	#$4000,$dff09a
			lea	mix_buff3(pc),a0
			move.l	(a0),d0
			move.l	16(a0),(a0)	
			move.l	d0,16(a0)	
			move.l	d0,$dff0c0
			lea	mix_data+mix_datasize*4,a5
			lea	mix_data+mix_datasize*5,a6
			move.l	16(a0),a4
			bsr.b	mix_channels
			;move	#$c000,$dff09a
			movem.l	(sp)+,d0-a6
			move	#$200,$dff09c
;			move	#$aab,$dff180
			;nop
			;nop
			;nop
			;rte
			rts
mix_play3		movem.l	d0-a6,-(sp)
			;move	#$4000,$dff09a
			lea	mix_buff4(pc),a0
			move.l	(a0),d0
			move.l	16(a0),(a0)	
			move.l	d0,16(a0)	
			move.l	d0,$dff0d0
			lea	mix_data+mix_datasize*6,a5
			lea	mix_data+mix_datasize*7,a6
			move.l	16(a0),a4
			bsr.b	mix_channels
			;move	#$c000,$dff09a
			movem.l	(sp)+,d0-a6
			move	#$400,$dff09c
;			move	#$aab,$dff180
			;nop
			;nop
			;nop
			;rte
			rts

;--------------------------------------------------------------------
; a5=ptr on chdata1
; a6=ptr on chdata2
; a4=ptr on destbuffer (chipmem!)
mix_channels:
;			bsr	mix_mix_mix
;
;			rts
;
;			move.l	a4,a3
;			moveq	#128/4-1,d7
;.interpol		rept	4
;			move.b	(a4),d1
;			move.b	1(a4),d2	; interpol-dreck
;			sub.b	d1,d2
;			asr.b	#2,d2
;			add.b	d2,d1
;			move.b	d1,(a4)+
;			endr
;			dbf	d7,.interpol
;			rts
;
;			rept	3
;			move.b	(a4),d1
;			move.b	1(a4),d2
;			sub.b	d1,d2
;			asr.b	#1,d2
;			add.b	d2,d1
;			move.b	d1,(a4)+
;			endr
;			move.b	(a4),d1
;			move.b	(a3),d2
;			sub.b	d1,d2
;			asr.b	#1,d2
;			add.b	d2,d1
;			move.b	d1,(a4)
;			rts


mix_mix_mix:		movem.l	a4-a6,-(sp)

			move.l	mix_wavestart(a5),a0	; wave1 startadr
			move.l	mix_wavestart(a6),a1	; wave2 startadr
			move.l	mix_waveoff(a5),d0	; wave1 mixoff
			move.l	mix_waveoff(a6),d1	; wave2 mixoff
			move.l	mix_volumeptr(a5),a2	; wave1 volumeptr
			move.l	mix_volumeptr(a6),a3	; wave2 volumeptr
			moveq	#0,d2
			move	mix_period.float(a5),d2
			swap	d2			; wave1 addx-add
			moveq	#0,d3			; wave1 addx-cnt
			move	mix_lastfloat(a5),d3
			swap	d3
			moveq	#0,d4
			move	mix_norm.add(a5),d4	; wave1 integer-add
			moveq	#0,d5
			move	mix_period.float(a6),d5	; wave2 addx-add
			moveq	#0,d6			; wave2 addx-cnt
			move	mix_lastfloat(a6),d6
			moveq	#0,d7
			move	mix_norm.add(a6),d7	; wave2 integer-add
			
			move	#mix_buflen/2,mix_cnt(a5)

			tst.b	mix_status(a5)
			beq.w	mix_right
			tst.b	mix_status(a6)
			beq.w	mix_left

mix_both

.loop


			rept	2

 move.b	(a0,d0.l),d2	; ein byte aus wave 1 holen		14

 add	d5,d6		; add float wave2			4

 move.b	(a1,d1.l),d3	; ein byte aus wave 2 holen		14

 addx.l	d7,d1		; floating-point wave2			8

 move.b	(a2,d2),d2	; *volume & div 2			14

 add.b	(a3,d3),d2	; *volume & div 2			14

 swap	d2		; hi-word holen				4
 swap	d3		; hi-word holen				4
 add	d2,d3		; addx-trick				4
 swap	d2		; lo-word holen				4
 swap	d3		; lo-word holen				4

 move.b	d2,(a4)+	; write to buffer			8

 addx.l	d4,d0		; floating-point wave1			8

			endr

			cmp.l	mix_wavelen(a5),d0
			bge.b	.resetwave1
.set1
			cmp.l	mix_wavelen(a6),d1
			bge.b	.resetwave2
.set2
			sub	#1,mix_cnt(a5)
			cmp	#0,mix_cnt(a5)
			bne.b	.loop

			swap	d3
			move	d3,mix_lastfloat(a5)
			move	d6,mix_lastfloat(a6)

			move.l	d0,mix_waveoff(a5)
			move.l	d1,mix_waveoff(a6)
			movem.l	(sp)+,a4-a6
			rts
.resetwave1		move.l	mix_repstrt(a5),a0
			move.l	a0,mix_wavestart(a5)
			moveq	#0,d0
			move.l	mix_replen(a5),mix_wavelen(a5)
			cmp.l	#2,mix_wavelen(a5)
			ble.w	mix_right.leftoff
			bra.b	.set1
.resetwave2		move.l	mix_repstrt(a6),a1
			move.l	a1,mix_wavestart(a6)
			moveq	#0,d1
			move.l	mix_replen(a6),mix_wavelen(a6)
			cmp.l	#2,mix_wavelen(a6)
			ble.b	mix_left.rightoff
			bra.b	.set2
.d4			dc.l	0
.d7			dc.l	0
;----------------------------------------
mix_nothing.leftoff	clr.b	mix_status(a5)
			bra.b	mix_nothing
mix_nothing.rightoff	clr.b	mix_status(a6)
mix_nothing

.loop			clr	(a4)+
			sub	#1,mix_cnt(a5)
			cmp	#0,mix_cnt(a5)
			bne.b	.loop
			

			movem.l	(sp)+,a4-a6
			rts
;----------------------------------------
mix_left.rightoff	clr.b	mix_status(a6)
mix_left
			cmp.l	#2,mix_wavelen(a5)
			ble.b	mix_nothing

			swap	d2
			swap	d3
			moveq	#0,d5

.loop

			rept	2
 move.b	(a0,d0.l),d5	; ein byte aus wave 1 holen		14
 add	d2,d3		; mix-bytes & add float wave1		6
 move.b	(a2,d5),(a4)+	; *volume & div 2			14
 addx.l	d4,d0		; floating-point wave1			8
			endr

			cmp.l	mix_wavelen(a5),d0
			bge.b	.resetwave1
.set1
			sub	#1,mix_cnt(a5)
			cmp	#0,mix_cnt(a5)
			bne.b	.loop

			swap	d3
			move	d3,mix_lastfloat(a5)

			move.l	d0,mix_waveoff(a5)
			movem.l	(sp)+,a4-a6
			rts
.resetwave1
			move.l	mix_repstrt(a5),a0
			move.l	a0,mix_wavestart(a5)
			moveq	#0,d0
			move.l	mix_replen(a5),mix_wavelen(a5)
			cmp.l	#2,mix_wavelen(a5)
			ble.w	mix_nothing.leftoff
			bra.b	.set1
;----------------------------------------
mix_right.leftoff	clr.b	mix_status(a5)
mix_right
			tst.b	mix_status(a6)
			beq.w	mix_nothing

			cmp.l	#0,a1
			beq.w	mix_nothing
			cmp.l	#2,mix_wavelen(a6)
			ble.w	mix_nothing

			moveq	#0,d3
.loop
			rept	2
 move.b	(a1,d1.l),d3	; ein byte aus wave 2 holen		14
 add	d5,d6		; add float wave2			4
 move.b	(a3,d3),(a4)+	; *volume & div 2			14
 addx.l	d7,d1		; floating-point wave2			8
			endr

			cmp.l	mix_wavelen(a6),d1
			bge.b	.resetwave2
.set2
			sub	#1,mix_cnt(a5)
			cmp	#0,mix_cnt(a5)
			bne.b	.loop

			move	d6,mix_lastfloat(a6)
			move.l	d1,mix_waveoff(a6)
			movem.l	(sp)+,a4-a6
			rts
.resetwave2		move.l	mix_repstrt(a6),a1
			move.l	a1,mix_wavestart(a6)
			moveq	#0,d1
			move.l	mix_replen(a6),mix_wavelen(a6)
			cmp.l	#2,mix_wavelen(a6)
			ble.w	mix_nothing.rightoff
			bra.b	.set2
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------
mix_buff1		dc.l	0	; diese buffer werden gerade berechnet
mix_buff2		dc.l	0
mix_buff3		dc.l	0
mix_buff4		dc.l	0
mix_buff1hear		dc.l	0	; diese buffer werden gerade angehört
mix_buff2hear		dc.l	0
mix_buff3hear		dc.l	0
mix_buff4hear		dc.l	0

mix_multab64		ds.b	256*65
mix_mixrate		ds	1	; period

mix_data
			rsreset
mix_wavestart		rs.l	1
mix_waveoff		rs.l	1
mix_wavelen		rs.l	1
mix_repstrt		rs.l	1
mix_replen		rs.l	1
mix_period		rs	1
mix_period.float	rs	1	umgerechnet auf mixrate/addx trick-add
;					float-cnt
;					$ffff= period  125
;					$8000= ...     250
;					$4000= ...     500
;					$2000= ...    1000
mix_norm.add		rs	1
mix_cnt			rs	1
mix_lastfloat		rs	1
mix_status		rs.b	1+1	0=ch off , 1=ch plays
mix_volumeptr		rs.l	1
mix_datasize		rs	1
			ds.b	mix_datasize*8


mix_bypass		ds.b	$10*8
;--------------------------------------------------------------------


;--------------------------------------------------------------------


;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################
;########################################################################

****************************************************************************
; ________________________________________________________________________
; 									
;                      -<>-o art.of.noise.replay v1.6 o-<>-		
; 			   coded by twice/lego! '93/4		
; ________________________________________________________________________

;========================================================================
aon8_play		movem.l	d0-d7/a0-a6,-(sp)
			lea	aon_data,a6

			addq.b	#1,aon_framecnt(a6)
			move.b	aon_speed(a6),d0
			beq.b	aon8_playcurrent_nonewpos2
			cmp.b	aon_framecnt(a6),d0
			bhi.b	aon8_playcurrent_nonewpos2
			clr.b	aon_framecnt(a6)

			bsr.w	aon8_playnewstep
aon8_playcurrent_nonewpos2
			bsr.b	aon8_playfx

			movem.l	(sp)+,d0-d7/a0-a6
			rts

;---------------------- effekte & samplestarts ----------------------
aon8_playfx		
			moveq	#0,d7
			move.b	aon_pos(a6),d7
			tst.l	aon_posdata(a6)
			beq.w	.x

			move.l	aon_posdata(a6),a1	; get start of posdat
			moveq	#0,d0
	* enforcer hit
			move.b	(a1,d7),d0		; d7=act. pos + choff

;	cmp.b	#replayst_all,replaystatus+main_data
;	bne.s	.dontsetpatnr
			move.b	d0,acteditpattern
;.dontsetpatnr

			lea	aon_dofx,a1
			lea	aon_channels,a4	; do effect command
			jsr	(a1)
			lea	aon_chdatasize(a4),a4
			jsr	(a1)
			lea	aon_chdatasize(a4),a4
			jsr	(a1)
			lea	aon_chdatasize(a4),a4
			jsr	(a1)
			lea	aon_chdatasize(a4),a4
			jsr	(a1)
			lea	aon_chdatasize(a4),a4
			jsr	(a1)
			lea	aon_chdatasize(a4),a4
			jsr	(a1)
			lea	aon_chdatasize(a4),a4
			jsr	(a1)

			moveq	#0,d1			; make channel-mask
			moveq	#0,d7
			lea	aon8_startinstr.1(pc),a1


			lea	aon_channels,a4	; do effect command
			lea	mix_bypass,a5
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)

			lea	-8*$10(a5),a5

			lea	-(8*aon_chdatasize)(a4),a4

			moveq	#0,d7

			lea	aon8_startinstr.2(pc),a1
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)
			jsr	(a1)
.x
			rts

;========================================================================
;---------------------- neuen step auslesen -------------------------
aon8_playnewstep

;	tst.b	replaystatus+main_data
;	beq	aon8_playcurrent_nonewposx

			cmp.b	#$ff,aon_patcnt(a6)
			beq.w	aon8_breakpat

; read new step
aon8_getstep
			tst.b	aon_patdelaycnt+1(a6)
			bmi.s	aon8_nopatdelay
			beq.s	aon8_nopatdelay
			subq.b	#1,aon_patdelaycnt+1(a6)
			bra.w	aon8_playcurrent_nonewposx
aon8_nopatdelay		move.b	#-1,aon_patdelaycnt+1(a6)
	
			lea	aon_channels,a4
			lea	aon_multab120,a5	; needed for periodtab

			moveq	#0,d0
			move.b	acteditpattern,d0

;move.b	aon_actpat(a6),d0
			move.l	aon_pattdata(a6),a0	; get start of patdat

			moveq	#11,d1
			lsl.l	d1,d0			; patnr*1024=patoff
			lea	(a0,d0.l),a0		; add to start of data
			move	aon_patcnt(a6),d1

;	move.b	d1,disppatcnt+main_data

			lsl	#3,d1			; *8
			lea	(a0,d1.l),a0		; add pattcounter


      					push    a1
                        move.l a0,a1
                        move.l a1,Stripe1
                        addq    #4,a1
                        move.l a1,Stripe2
                        addq    #4,a1
                        move.l a1,Stripe3
                        addq    #4,a1
                        move.l a1,Stripe4
                        addq    #4,a1
                        move.l a1,Stripe5
                        addq    #4,a1
                        move.l a1,Stripe6
                        addq    #4,a1
                        move.l a1,Stripe7
                        addq    #4,a1
                        move.l a1,Stripe8
                        pop     a1
						move	aon_patcnt(a6),d1	* increments of 4
						lsr 	#2,d1
						move	d1,PatternInfo+PI_Pattpos

; a0=pointer on actual step
			jsr	aon_getdachannel	; get first channel
			lea	aon_chdatasize(a4),a4
			addq.l	#4,a0
			jsr	aon_getdachannel	; get second channel
			lea	aon_chdatasize(a4),a4
			addq.l	#4,a0
			jsr	aon_getdachannel	; get third channel
			lea	aon_chdatasize(a4),a4
			addq.l	#4,a0
			jsr	aon_getdachannel	; get fourth channel
			lea	aon_chdatasize(a4),a4
			addq.l	#4,a0
			jsr	aon_getdachannel	; get fifth channel
			lea	aon_chdatasize(a4),a4
			addq.l	#4,a0
			jsr	aon_getdachannel	; get sixth channel
			lea	aon_chdatasize(a4),a4
			addq.l	#4,a0
			jsr	aon_getdachannel	; get seventh channel
			lea	aon_chdatasize(a4),a4
			addq.l	#4,a0
			jsr	aon_getdachannel	; get eighth channel

			tst.b	aon_loopflag(a6)
			beq.s	aon8_nolooping
			clr.b	aon_loopflag(a6)
			move.b	aon_looppoint(a6),aon_patcnt+1(a6)
			bra.b	aon8_playcurrent_nonewposx
aon8_nolooping		addq.b	#4,aon_patcnt+1(a6)
			bne.b	aon8_playcurrent_nonewposx  ; end of pattern??
aon8_breakpat		

;	move.b	#%1111,pattdspreq+main_data

			clr.b	aon_patdelaycnt+1(a6)
			clr	aon_looppoint(a6)

;	cmp.b	#replayst_pat,replaystatus+main_data
;	beq.b	aon8_playcurrent2

			addq.b	#1,aon_pos(a6)	; pos=pos+1
			move.l	aon_statdata(a6),a3
			move.b	aon.songinfo_maxpos(a3),d0	; get maxpos
			cmp.b	aon_pos(a6),d0	; end of song ??
			bhi.b	aon8_playcurrent2
			move.b	aon.songinfo_respos(a3),aon_pos(a6) ; get restart pos!

			push	a0 
			move.l 	songend(pc),a0 
			st      (a0)
			pop   	a0

aon8_playcurrent2	tst.b	aon_patcnt(a6)
			beq.b	aon8_playcurrent_nonewposx
			clr.b	aon_patcnt(a6)

			moveq	#0,d7
			move.b	aon_pos(a6),d7
			move.l	aon_posdata(a6),a1	; get start of posdat
			moveq	#0,d0
			move.b	(a1,d7),d0		; d7=act. pos + choff

;	cmp.b	#replayst_all,replaystatus+main_data
;	bne.s	aon8_dontsetpatnr2
			move.b	d0,acteditpattern

aon8_dontsetpatnr2
			bra.w	aon8_getstep
aon8_playcurrent_nonewposx
			rts
;========================================================================
aon8_startinstr.1
			move	aon_fxcom(a4),d0
			and	#$0ff0,d0
			cmp	#$0ed0,d0
			beq.b	aon8_strtinsonlyrep.1

			move	aon_period(a4),d0	; baseper+arpeggio
			add	aon_perslide(a4),d0	; portamento value
.checkhiper
			cmp	#103,d0
			bhs.b	.noperalert
			moveq	#103,d0
.noperalert		move	d0,$6(a5)


			move.b	aon_chflag(a4),$8(a5)


			moveq	#0,d0
			move.b	aon_volume(a4),d0
			moveq	#0,d2
			move.b	aon_synthvol(a4),d2
			mulu	d2,d0
			lsr	#6,d0
			mulu	aon_trackvol(a4),d0
			lsr	#6,d0
			move.b	d0,$9(a5)

			move.l	aon_waveform(a4),$0(a5)

			move	aon_wavelen(a4),$4(a5)

aon8_strtinsonlyrep.1
			addq.b	#1,d7
aon8_strtinsonlyrep.2	lea	aon_chdatasize(a4),a4
			lea	$10(a5),a5
			rts
aon8_startinstr.2
			move	aon_fxcom(a4),d0
			and	#$0ff0,d0
			cmp	#$0ed0,d0
			beq.b	aon8_strtinsonlyrep.1

.sample2
			move.l	aon_repeatstrt(a4),10(a5)
			move	aon_replen(a4),14(a5)
			clr.b	aon_chflag(a4)
			bra.b	aon8_strtinsonlyrep.1
;--------------------------------------------------------------------
acteditpattern		ds.b	2


;====================================================================


;			section	buffer,bss_c
;buffers			ds.b	512+mix_buflen*4*2	; double buffering

 ifne TEST
			section	sdfsdf,data
mod
	incbin	"m:exo/art of noise/aon8.trancemission-2"
;	incbin	"dh1:sfx/mods/own.modules/1995/aon8.silence of the rain"
;	incbin	"dh1:sfx/mods/artofnoise/tommy/aon8.fm-demosong"
;	incbin	"dh1:sfx/mods/artofnoise/aon8.ethnomagic (nhp)"
;	incbin	"dh1:sfx/mods/artofnoise/aon8.scrambled mind"
;	incbin	"dh1:sfx/mods/artofnoise/tommy/aon8.trancemission2"
;	incbin	"dh1:sfx/mods/artofnoise/aon8.disk-maskin"
 endif
