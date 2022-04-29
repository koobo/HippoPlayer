;APS00000040000000400000004000000040000000400000004000000040000000400000004000000040

	incdir	include:
	include mucro.i
	include	misc/eagleplayer.i


* Scope data for one channel
              rsreset
ns_start      rs.l       1 * Sample start address
ns_length     rs         1 * Length in words
ns_loopstart  rs.l       1 * Loop start address
ns_replen     rs         1 * Loop length in words
ns_volume    rs         1 * Volume
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

testi	=	0

 ifne testi

	lea	mod,a0
	lea	w(pc),a1
	lea	songend_(pc),a2
	lea	vol(pc),a3
	lea	nullsample,a4
	lea	scope_(pc),a5
	jsr	init

	
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

	move	#$f,$dff096
	rts

vol	dc	$40/1

w
dmawait
	pushm	d0/d1
	moveq	#12-1,d1
.d	move.b	$dff006,d0
.k	cmp.b	$dff006,d0
	beq.b	.k
	dbf	d1,.d
	popm	d0/d1
	rts 
songend_	dc	0
scope_	ds.b	scope_size

	section	cc,data_c
nullsample	ds.l	1
mod	incbin	sys:music/modsanthology/synth/jamcrack/jam.dr-awesome-1
 endc


		SECTION	BTLCRACKER_PLAYER,CODE_P

	jmp	init(pc)
	jmp	play(pc)

* in:
*   a0 = mod
*   a1 = dmawait
*   a2 = songover
*   a3 = main volume
*   a4 = null sample
*   a5 = scope data
* out:
*   d0 = max song pos

init
	pushm	a5/a6
	move.l	a0,moduleAddr
	move.l	a1,dmaWaitAddr
	move.l	a2,songOverAddr
	move.l	a3,mainVolAddr
	move.l	a4,nullSampleAddr
	move.l  a5,scope
	bsr.w	pp_init
	bsr.b	PatternInit
	move	songlen(pc),d0
	popm	a5/a6
	rts

play
	pushm	a5/a6
	move.l	mainVolAddr(pc),a0
	move	(a0),mainVol
	bsr.w	pp_play
	move	songlen(pc),d0
	sub	pp_songcnt(pc),d0
	popm	a5/a6
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
	move.l	#4*nt_sizeof,PI_Modulo(A0)	; Number of bytes to next row
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

	move.b	nt_period(a0),d0
	beq.b	.noPer 
	* index 1 is the first period
	* bump one octave to contain lower notes
	* ie. index 3 must be 12
	;add	#12,d0
	move.b	nt_instr(a0),d1
.noPer
	* Need to prioritize which operation to show in the
	* one slot available.

	move.b	nt_arpeggio(a0),d3 
	beq.b	.noArp
	rts
.noArp 
	move.b	nt_vibrato(a0),d3 
	beq.b	.noVib
	moveq	#4,d2
	rts
.noVib
	move.b	nt_porta(a0),d3
	beq.b	.noPorta
	moveq	#3,d2
	rts
.noPorta 
	move.b	nt_volume(a0),d3
	beq.b	.noVol 
	moveq	#$c,d2
	rts
.noVol
	move.b	nt_phase(a0),d3
	beq.b 	.noPhase
	* Map this to some non-PT command
	moveq	#7,d2
.noPhase
	rts


;nt_arpeggio	RS.B	1
;nt_vibrato	RS.B	1
;nt_phase		RS.B	1
;nt_volume		RS.B	1
;nt_porta		RS.B	1


	rts

moduleAddr		dc.l	0
dmaWaitAddr		dc.l	0
songOverAddr		dc.l	0
mainVolAddr		dc.l	0
mainVol			dc.w	0
nullSampleAddr		dc.l	0
scope		dc.l 	0
 

setPer
	pushm	a0/a1
	sub	#$f0a0,a0
	move.l	scope(pc),a1
	add	a0,a1
	move	d0,ns_period(a1)
	popm	a0/a1
	rts


setVol
	pushm	a0/a1
	sub	#$f0a0,a0
	move.l	scope(pc),a1
	add	a0,a1
	move	d0,ns_volume(a1)
	popm	a0/a1
	rts





                  ****************************************
                  *** JamCrackerPro V1.0a play-routine ***
                  ***   Originally coded by M. Gemmel  ***
                  ***           Code optimised         ***
                  ***         by Xag of Betrayal       ***
                  ***    See docs for important info   ***
                  ****************************************

;DMAWAIT		EQU	$12C	;Change to suit

	*** Relative offset definitions ***

		RSRESET		;Instrument info structure
it_name		RS.B	31
it_flags		RS.B	1
it_size		RS.L	1
it_address	RS.L	1
it_sizeof		RS.W	0

		RSRESET		;Pattern info structure
pt_size		RS.W	1
pt_address	RS.L	1
pt_sizeof		RS.W	0

		RSRESET		;Note info structure
nt_period		RS.B	1
nt_instr		RS.B	1
nt_speed		RS.B	1
nt_arpeggio		RS.B	1
nt_vibrato		RS.B	1
nt_phase		RS.B	1
nt_volume		RS.B	1
nt_porta		RS.B	1
nt_sizeof		RS.W	0

		RSRESET		;Voice info structure
pv_waveoffset	RS.W	1
pv_dmacon	RS.W	1
pv_custbase	RS.L	1
pv_inslen	RS.W	1
pv_insaddress	RS.L	1
pv_peraddress	RS.L	1
pv_pers		RS.W	3
pv_por		RS.W	1
pv_deltapor	RS.W	1
pv_porlevel	RS.W	1
pv_vib		RS.W	1
pv_deltavib	RS.W	1
pv_vol		RS.W	1
pv_deltavol	RS.W	1
pv_vollevel	RS.W	1
pv_phase	RS.W	1
pv_deltaphase	RS.W	1
pv_vibcnt		RS.B	1
pv_vibmax		RS.B	1
pv_flags		RS.B	1
			RS.B	1	 * PADDING to get even
pv_sizeof		RS.W	0



;	*** Test routine ***
;
;Start:		move.l	4.w,a6
;		jsr	-132(a6)
;
;		bsr.s	pp_init
;
;.loop:		cmp.b	#$50,$DFF006
;		bne.s	.loop
;		move.w	#$0F00,$DFF180
;		bsr	pp_play
;		move.w	#$0000,$DFF180
;		btst	#6,$BFE001
;		bne.s	.loop
;
;		bsr	pp_end
;
;		move.l	4.w,a6
;		jsr	-138(a6)
;
;		moveq	#0,d0
;		rts
;
	*** Initialise routine ***

pp_init:		
	;lea	pp_song(PC),a0
		addq.w	#4,a0
		move.w	(a0)+,d0
		move.w	d0,d1
		move.l	a0,instable
		mulu	#it_sizeof,d0
		add.w	d0,a0

		move.w	(a0)+,d0
		move.w	d0,d2
		move.l	a0,patttable
		mulu	#pt_sizeof,d0
		add.w	d0,a0

		move.w	(a0)+,d0
		move.w	d0,songlen
		move.l	a0,songtable
		add.w	d0,d0
		add.w	d0,a0

		move.l	patttable(PC),a1
		move.w	d2,d0
		subq.w	#1,d0
.l0:		move.l	a0,pt_address(a1)
		move.w	(a1),d3		;pt_size
		mulu	#nt_sizeof*4,d3
		add.w	d3,a0
		addq.w	#pt_sizeof,a1
		dbra	d0,.l0

		move.l	instable(PC),a1
		move.w	d1,d0
		subq.w	#1,d0
.l1:		move.l	a0,it_address(a1)
		move.l	it_size(a1),d2
		add.l	d2,a0
		add.w	#it_sizeof,a1
		dbra	d0,.l1

		move.l	songtable(PC),pp_songptr
		move.w	songlen(PC),pp_songcnt
		move.l	pp_songptr(PC),a0
		move.w	(a0),d0
		mulu	#pt_sizeof,d0
		add.l	patttable(PC),d0
		move.l	d0,a0
		move.l	a0,pp_pattentry
		move.b	pt_size+1(a0),pp_notecnt
		move.l	pt_address(a0),pp_address
	
		move.l	pp_address(pc),a0 
		move.l	a0,Stripe1
		lea	nt_sizeof(a0),a0
		move.l	a0,Stripe2
		lea	nt_sizeof(a0),a0
		move.l	a0,Stripe3
		lea	nt_sizeof(a0),a0
		move.l	a0,Stripe4
	
		move.b	#6,pp_wait
		move.b	#1,pp_waitcnt
		;clr.w	pp_nullwave
		move.w	#$000F,$DFF096

		lea	pp_variables(PC),a0
		lea	$DFF0A0,a1
		moveq	#1,d1
		move.w	#$80,d2
		moveq	#4-1,d0
.l2:		move.w	#0,8(a1)
		move.w	d2,(a0)		;pv_waveoffset
		move.w	d1,pv_dmacon(a0)
		move.l	a1,pv_custbase(a0)
		move.l	#pp_periods,pv_peraddress(a0)
		move.w	#1019,pv_pers(a0)
		clr.w	pv_pers+2(a0)
		clr.w	pv_pers+4(a0)
		clr.l	pv_por(a0)
		clr.w	pv_porlevel(a0)
		clr.l	pv_vib(a0)
		clr.l	pv_vol(a0)
		move.w	#$40,pv_vollevel(a0)
		clr.l	pv_phase(a0)
		clr.w	pv_vibcnt(a0)
		clr.b	pv_flags(a0)
		add.w	#pv_sizeof,a0
		add.w	#$10,a1
		add.w	d1,d1
		add.w	#$40,d2
		dbra	d0,.l2

		bset	#1,$BFE001

		rts

	*** Clean-up routine ***

pp_end:		moveq	#0,d0
		lea	$DFF000,a0
		move.w	d0,$A8(a0)
		move.w	d0,$B8(a0)
		move.w	d0,$C8(a0)
		move.w	d0,$D8(a0)
		move.w	#$000F,$96(a0)
		bclr	#1,$BFE001
		rts

	*** Play routine ***

pp_play:		lea	$DFF000,a6
		subq.b	#1,pp_waitcnt
		bne.s	.l0
		bsr.w	pp_nwnt
		move.b	pp_wait(PC),pp_waitcnt

.l0:		lea	pp_variables(PC),a1
		bsr.s	pp_uvs
		lea	pp_variables+pv_sizeof(PC),a1
		bsr.s	pp_uvs
		lea	pp_variables+2*pv_sizeof(PC),a1
		bsr.s	pp_uvs
		lea	pp_variables+3*pv_sizeof(PC),a1

pp_uvs:		move.l	pv_custbase(a1),a0

.l0:		move.w	pv_pers(a1),d0
		bne.s	.l1
		bsr.w	pp_rot
		bra.s	.l0
.l1:		add.w	pv_por(a1),d0
		tst.w	pv_por(a1)
		beq.s	.l1c
		bpl.s	.l1a
		cmp.w	pv_porlevel(a1),d0
		bge.s	.l1c
		bra.s	.l1b
.l1a:		cmp.w	pv_porlevel(a1),d0
		ble.s	.l1c
.l1b:		move.w	pv_porlevel(a1),d0

.l1c:		add.w	pv_vib(a1),d0
		cmp.w	#135,d0
		bge.s	.l1d
		move.w	#135,d0
		bra.s	.l1e
.l1d:		cmp.w	#1019,d0
		ble.s	.l1e
		move.w	#1019,d0
.l1e:		move.w	d0,6(a0) * AUDxPER	
		bsr	setPer
		bsr.w	pp_rot

		move.w	pv_deltapor(a1),d0
		add.w	d0,pv_por(a1)
		cmp.w	#-1019,pv_por(a1)
		bge.s	.l3
		move.w	#-1019,pv_por(a1)
		bra.s	.l5
.l3:		cmp.w	#1019,pv_por(a1)
		ble.s	.l5
		move.w	#1019,pv_por(a1)

.l5:		tst.b	pv_vibcnt(a1)
		beq.s	.l7
		move.w	pv_deltavib(a1),d0
		add.w	d0,pv_vib(a1)
		subq.b	#1,pv_vibcnt(a1)
		bne.s	.l7
		neg.w	pv_deltavib(a1)
		move.b	pv_vibmax(a1),pv_vibcnt(a1)

.l7:		move.w	pv_dmacon(a1),d0
		;move.w	pv_vol(a1),8(a0)
		
		move.w	pv_vol(a1),d0
		mulu	mainVol(pc),d0
		lsr	#6,d0
		move	d0,8(a0)
		bsr	setVol

		move.w	pv_deltavol(a1),d0
		add.w	d0,pv_vol(a1)
		tst.w	pv_vol(a1)
		bpl.s	.l8
		clr.w	pv_vol(a1)
		bra.s	.la
.l8:		cmp.w	#$40,pv_vol(a1)
		ble.s	.la
		move.w	#$40,pv_vol(a1)

.la:		btst	#1,pv_flags(a1)
		beq.s	.l10
		tst.w	pv_deltaphase(a1)
		beq.s	.l10
		bpl.s	.sk
		clr.w	pv_deltaphase(a1)
.sk:		move.l	pv_insaddress(a1),a0
		move.w	(a1),d0		;pv_waveoffset
		neg.w	d0
		lea	(a0,d0.w),a2
		move.l	a2,a3
		move.w	pv_phase(a1),d0
		lsr.w	#2,d0
		add.w	d0,a3

		moveq	#$40-1,d0
.lb:		move.b	(a2)+,d1
		ext.w	d1
		move.b	(a3)+,d2
		ext.w	d2
		add.w	d1,d2
		asr.w	#1,d2
		move.b	d2,(a0)+
		dbra	d0,.lb

		move.w	pv_deltaphase(a1),d0
		add.w	d0,pv_phase(a1)
		cmp.w	#$100,pv_phase(a1)
		blt.s	.l10
		sub.w	#$100,pv_phase(a1)

.l10:		rts

pp_rot:		move.w	pv_pers(a1),d0
		move.w	pv_pers+2(a1),pv_pers(a1)
		move.w	pv_pers+4(a1),pv_pers+2(a1)
		move.w	d0,pv_pers+4(a1)
		rts

pp_nwnt:		
		move.l	pp_address(PC),a0
		add.l	#4*nt_sizeof,pp_address
		addq	#1,PatternInfo+PI_Pattpos
		subq.b	#1,pp_notecnt
		bne.s	.l5

.l0:		addq.l	#2,pp_songptr
		subq.w	#1,pp_songcnt
		bne.s	.l1
		move.l	songtable(PC),pp_songptr
		move.w	songlen(PC),pp_songcnt

		move.l	songOverAddr(pc),a1
		st	(a1)

.l1:		move.l	pp_songptr(PC),a1
		move.w	(a1),d0
		mulu	#pt_sizeof,d0
		add.l	patttable(PC),d0
		move.l	d0,a1
		move.b	pt_size+1(a1),pp_notecnt
		move.l	pt_address(a1),pp_address

		push	a0
		clr	PatternInfo+PI_Pattpos
		move.w	pt_size(a1),PatternInfo+PI_Pattlength
		move.l	pt_address(a1),a0
		move.l	a0,Stripe1
		lea	nt_sizeof(a0),a0
		move.l	a0,Stripe2
		lea	nt_sizeof(a0),a0
		move.l	a0,Stripe3
		lea	nt_sizeof(a0),a0
		move.l	a0,Stripe4
		pop 	a0
	
.l5:		


		clr.w	pp_tmpdmacon
		lea	pp_variables(PC),a1
		bsr.w	pp_nnt
		addq.w	#nt_sizeof,a0
		lea	pp_variables+pv_sizeof(PC),a1
		bsr.w	pp_nnt
		addq.w	#nt_sizeof,a0
		lea	pp_variables+2*pv_sizeof(PC),a1
		bsr.w	pp_nnt
		addq.w	#nt_sizeof,a0
		lea	pp_variables+3*pv_sizeof(PC),a1
		bsr.w	pp_nnt

		move.w	pp_tmpdmacon(PC),$96(a6)

;		move.w	#DMAWAIT-1,d0
;.loop1:		dbra	.loop1
		move.l	dmaWaitAddr(pc),a1 
		jsr	 (a1)

		lea	pp_variables(PC),a1
		bsr.w	pp_scr
		lea	pp_variables+pv_sizeof(PC),a1
		bsr.w	pp_scr
		lea	pp_variables+2*pv_sizeof(PC),a1
		bsr.w	pp_scr
		lea	pp_variables+3*pv_sizeof(PC),a1
		bsr.s	pp_scr

		bset	#7,pp_tmpdmacon
		move.w	pp_tmpdmacon(PC),$96(a6)

;		move.w	#DMAWAIT-1,d0
;.loop2:		dbra	.loop2
		move.l	dmaWaitAddr(pc),a1 
		jsr	 (a1)

		move.l	pp_variables+pv_insaddress(PC),$A0(a6)
		move.w	pp_variables+pv_inslen(PC),$A4(a6)
		move.l	pp_variables+pv_sizeof+pv_insaddress(PC),$B0(a6)
		move.w	pp_variables+pv_sizeof+pv_inslen(PC),$B4(a6)
		move.l	pp_variables+2*pv_sizeof+pv_insaddress(PC),$C0(a6)
		move.w	pp_variables+2*pv_sizeof+pv_inslen(PC),$C4(a6)
		move.l	pp_variables+3*pv_sizeof+pv_insaddress(PC),$D0(a6)
		move.w	pp_variables+3*pv_sizeof+pv_inslen(PC),$D4(a6)

		move.l	scope(pc),a1
		move.l	pp_variables+pv_insaddress(PC),scope_ch1+ns_loopstart(a1)
		move.w	pp_variables+pv_inslen(PC),scope_ch1+ns_replen(a1)
		move.l	pp_variables+pv_sizeof+pv_insaddress(PC),scope_ch2+ns_loopstart(a1)
		move.w	pp_variables+pv_sizeof+pv_inslen(PC),scope_ch2+ns_replen(a1)
		move.l	pp_variables+2*pv_sizeof+pv_insaddress(PC),scope_ch3+ns_loopstart(a1)
		move.w	pp_variables+2*pv_sizeof+pv_inslen(PC),scope_ch3+ns_replen(a1)
		move.l	pp_variables+3*pv_sizeof+pv_insaddress(PC),scope_ch4+ns_loopstart(a1)
		move.w	pp_variables+3*pv_sizeof+pv_inslen(PC),scope_ch4+ns_replen(a1)

		rts

pp_scr:		move.w	pp_tmpdmacon(PC),d0
		and.w	pv_dmacon(a1),d0
		beq.s	.l5

		move.l	pv_custbase(a1),a0
		move.l	pv_insaddress(a1),(a0)
		move.w	pv_inslen(a1),4(a0)
		move.w	pv_pers(a1),6(a0)

		sub	#$f0a0,a0
		move.l	scope(pc),a2
		add	a0,a2		
		move.l	pv_insaddress(a1),ns_start(a2)
		move	pv_inslen(a1),ns_length(a2)
		move	pv_pers(a1),ns_period(a2)

		btst	#0,pv_flags(a1)
		bne.s	.l5
		;move.l	#pp_nullwave,pv_insaddress(a1)
		move.l  nullSampleAddr(pc),pv_insaddress(a1)
		move.w	#1,pv_inslen(a1)
.l5:		rts

pp_nnt:		move.b	(a0),d1		;nt_period
		beq.w	.l5

		and.l	#$000000FF,d1
		add.w	d1,d1
		add.l	#pp_periods-2,d1
		move.l	d1,a2

		btst	#6,nt_speed(a0)
		beq.s	.l2
		move.w	(a2),pv_porlevel(a1)
		bra.s	.l5

.l2:		move.w	pv_dmacon(a1),d0
		or.w	d0,pp_tmpdmacon

		move.l	a2,pv_peraddress(a1)
		move.w	(a2),pv_pers(a1)
		move.w	(a2),pv_pers+2(a1)
		move.w	(a2),pv_pers+4(a1)

		clr.w	pv_por(a1)

		move.b	nt_instr(a0),d0
		ext.w	d0
		mulu	#it_sizeof,d0
		add.l	instable(PC),d0
		move.l	d0,a2
		tst.l	it_address(a2)
		bne.s	.l1
		;move.l	#pp_nullwave,pv_insaddress(a1)
		move.l	nullSampleAddr(pc),pv_insaddress(a1)
		move.w	#1,pv_inslen(a1)
		clr.b	pv_flags(a1)
		bra.s	.l5

.l1:		move.l	it_address(a2),a3
		btst	#1,it_flags(a2)
		bne.s	.l0a
		move.l	it_size(a2),d0
		lsr.l	#1,d0
		move.w	d0,pv_inslen(a1)
		bra.s	.l0
.l0a:		move.w	(a1),d0		;pv_waveoffset
		add.w	d0,a3
		move.w	#$20,pv_inslen(a1)
.l0:		move.l	a3,pv_insaddress(a1)
		move.b	it_flags(a2),pv_flags(a1)
		move.w	pv_vollevel(a1),pv_vol(a1)

.l5:		move.b	nt_speed(a0),d0
		and.b	#$0F,d0
		beq.s	.l6
		move.b	d0,pp_wait

.l6:		move.l	pv_peraddress(a1),a2
		move.b	nt_arpeggio(a0),d0
		beq.s	.l9
		cmp.b	#$FF,d0
		bne.s	.l7
		move.w	(a2),pv_pers(a1)
		move.w	(a2),pv_pers+2(a1)
		move.w	(a2),pv_pers+4(a1)
		bra.s	.l9

.l7:		and.b	#$0F,d0
		add.b	d0,d0
		ext.w	d0
		move.w	(a2,d0.w),pv_pers+4(a1)
		move.b	nt_arpeggio(a0),d0
		lsr.b	#4,d0
		add.b	d0,d0
		ext.w	d0
		move.w	(a2,d0.w),pv_pers+2(a1)
		move.w	(a2),pv_pers(a1)

.l9:		move.b	nt_vibrato(a0),d0
		beq.s	.ld
		cmp.b	#$FF,d0
		bne.s	.la
		clr.l	pv_vib(a1)
		clr.b	pv_vibcnt(a1)
		bra.s	.ld
.la:		clr.w	pv_vib(a1)
		and.b	#$0F,d0
		ext.w	d0
		move.w	d0,pv_deltavib(a1)
		move.b	nt_vibrato(a0),d0
		lsr.b	#4,d0
		move.b	d0,pv_vibmax(a1)
		lsr.b	#1,d0
		move.b	d0,pv_vibcnt(a1)

.ld:		move.b	nt_phase(a0),d0
		beq.s	.l10
		cmp.b	#$FF,d0
		bne.s	.le
		clr.w	pv_phase(a1)
		move.w	#$FFFF,pv_deltaphase(a1)
		bra.s	.l10
.le:		and.b	#$0F,d0
		ext.w	d0
		move.w	d0,pv_deltaphase(a1)
		clr.w	pv_phase(a1)

.l10:		move.b	nt_volume(a0),d0
		bne.s	.l10a
		btst	#7,nt_speed(a0)
		beq.s	.l16
		bra.s	.l11a
.l10a:		cmp.b	#$FF,d0
		bne.s	.l11
		clr.w	pv_deltavol(a1)
		bra.s	.l16
.l11:		btst	#7,nt_speed(a0)
		beq.s	.l12
.l11a:		move.b	d0,pv_vol+1(a1)
		move.b	d0,pv_vollevel+1(a1)
		clr.w	pv_deltavol(a1)
		bra.s	.l16
.l12:		bclr	#7,d0
		beq.s	.l13
		neg.b	d0
.l13:		ext.w	d0
		move.w	d0,pv_deltavol(a1)

.l16:		move.b	nt_porta(a0),d0
		beq.s	.l1a
		cmp.b	#$FF,d0
		bne.s	.l17
		clr.l	pv_por(a1)
		bra.s	.l1a
.l17:		clr.w	pv_por(a1)
		btst	#6,nt_speed(a0)
		beq.s	.l17a
		move.w	pv_porlevel(a1),d1
		cmp.w	pv_pers(a1),d1
		bgt.s	.l17c
		neg.b	d0
		bra.s	.l17c

.l17a:		bclr	#7,d0
		bne.s	.l18
		neg.b	d0
		move.w	#135,pv_porlevel(a1)
		bra.s	.l17c

.l18:		move.w	#1019,pv_porlevel(a1)
.l17c:		ext.w	d0
.l18a:		move.w	d0,pv_deltapor(a1)

.l1a:		rts

	*** Data section ***

;periods
;	dc	856,808,762,720,678,640,604,570,538,508,480,453
;	dc	428,404,381,360,339,320,302,285,269,254,240,226
;	dc	214,202,190,180,170,160,151,143,135,127,120,113
;periodsEnd
;
pp_periods:	                
		DC.W	1019,962,908
		DC.W     857,809,763,720,680,642,606,572,540,509,481,454
		dc.w     428,404,381,360,340,321,303,286,270,254,240,227
		dc.w     214,202,190,180,170,160,151,143,135,135,135,135
		dc.w     135,135,135,135,135,135,135,135,135,135,135,135

songlen:	DS.W	1
songtable:	DS.L	1
instable:	DS.L	1
patttable:	DS.L	1

pp_wait:	DS.B	1
pp_waitcnt:	DS.B	1
pp_notecnt:	DS.B	1
 even
pp_address:	DS.L	1
pp_songptr:	DS.L	1
pp_songcnt:	DS.W	1
pp_pattentry:	DS.L	1
pp_tmpdmacon:	DS.W	1

pp_variables:	DS.B	4*48

;pp_nullwave:	DS.W	1

;pp_song:		INCBIN	""

