;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000

	incdir 	include:
	include mucro.i 
	include	misc/eagleplayer.i

test=0

 ifne test

	jmp TESTPLAY

	section	cc,data_c
;mt_data		incbin	"sys:music/Modland/Startrekker AM/broom/kingkeldon.mod"
;mt_data		incbin	"sys:music/Modland/Startrekker AM/the wiz/link(zelda2).mod"
mt_data		incbin	"sys:music/Modland/Startrekker AM/GTS/fa.worse face.mod"
e1
  rept	32 
   dc.l $deadbeef
  endr
	
;mt_data2	incbin	"sys:music/Modland/Startrekker AM/broom/kingkeldon.mod.nt"
mt_data2		incbin	"sys:music/Modland/Startrekker AM/GTS/fa.worse face.mod.nt"
e2
  rept	32 
   dc.l $deadbeef
  endr
		section cod,code_c

; STARTREKKER 1.2      AM REPLAYROUTINE
;
; BY BJOERN WESEN / EXOLON OF FAIRLIGHT


; Call mt_init, then mt_music each frame, call mt_end to stop

; NOTE! The mt_amwaveforms have to reside in CHIPMEM! Therefore the ORG
;       below...

TESTPLAY:
	lea	mt_data,a0 
	lea mt_data2,a1
	lea	vol,a2
	lea songend,a3
	lea dmawait,a4
	move.l	#e1-mt_data,d0
	jsr init

tp_loop:cmp.b	#$80,$dff006
	bne.s	tp_loop
tp_loop2:
	cmp.b	#$80,$dff006
	beq.s	tp_loop2

	move	#$f00,$dff180
	jsr play
	move	#0,$dff180
	
	btst	#6,$bfe001
	bne.s	tp_loop

	bsr	mt_end
	rts

dmawait
	pushm	d0/d1
	moveq	#12-1,d1
.d	move.b	$dff006,d0
.k	cmp.b	$dff006,d0
	beq.b	.k
	dbf	d1,.d
	popm	d0/d1
	rts 

vol 		dc $40/4
songend 	dc 0
 endc 

* in:
*   a0 = module
*   a1 = extra data
*   a2 = main volume ptr
*   a3 = song end ptr
*   a4 = dma wait ptr
*   d0 = module len
* out:
*   d1 = max pos
	jmp	init(pc)
* out:
*  d0 = cur pos
	jmp play(pc)
	jmp end(pc)

init
	move.l	a0,moduleAddr
	lea	24(a1),a1 
	move.l	a1,dataAddr
	move.l  a2,mainVolAddr 
	move.l  a3,songEndAddr
	move.l  a4,dmaWaitAddr

	bsr.w	mt_init
	bsr.b	PatternInit

	move.l	moduleAddr(pc),a1 
	moveq	#0,d1
	move.b	$3b6(a1),d1 
	moveq	#0,d0
	rts 

play	
	move.l	mainVolAddr(pc),a0 
	move	(a0),mainVol

	bsr.w	mt_music
	moveq	#0,d0 
	move.b	mt_songpos(pc),d0 
	rts 

end 
	rts


moduleAddr 		dc.l 	0
dataAddr		dc.l 	0
songEndAddr		dc.l 	0
dmaWaitAddr		dc.l 	0
mainVolAddr		dc.l 	0
mainVol			dc.w 	0






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
	move	#6,PI_Speed(a0)		; Magic! Indicates periods
	rts

* Called by the PI engine to get values for a particular row
ConvertNote
	moveq	#0,D0		; Period, Note
	moveq	#0,D1		; Sample number
	moveq	#0,D2		; Command 
	moveq	#0,D3		; Command argument

	; 00 11 22 33
	; Sp pp Sc aa

	* sample num
	move.b	2(a0),d1
	lsr.b	#4,d1
	move.b	(a0),d0
	and.b	#$f0,d0
	or.b	d0,d1

	moveq	#$f,d2
	and.b	2(a0),d2
	move.b	3(a0),d3

	move	(a0),d0
	and	#$fff,d0
	rts

mt_init:
	move.l moduleAddr(pc),a0
	lea	(a0,d0.l),a3	* end bound

	lea	$3b8(a0),a1

	moveq	#$7f,d0
	moveq	#0,d2
	moveq	#0,d1
mt_lop2:move.b	(a1)+,d1
	cmp.b	d2,d1
	ble.s	mt_lop
	move.l	d1,d2
mt_lop:	
	dbf	d0,mt_lop2
	addq.b	#1,d2
xx
	asl.l	#8,d2
	asl.l	#2,d2
	* addr of first sample
	lea	4(a1,d2.l),a2
	lea	mt_samplestarts(pc),a1
	add.w	#42,a0
	moveq	#$1e,d0
	moveq	#1,d1

	subQ	#4,a3
mt_lop3:	
	cmp.l	a3,a2	* overwrite check
	bhs.b	.s
	clr.l	(a2)
.s	move.l	a2,(a1)+
	moveq	#0,d1
	move.w	(a0),d1		* sample len
	clr.b	2(a0)		* ?
	asl.l	#1,d1
	add.l	d1,a2		* next sample data address
	add.l	#30,a0		
	dbf	d0,mt_lop3

	or.b	#2,$bfe001
	move.b	#6,mt_speed
	moveq	#0,d0
	lea	$dff000,a0
	move.w	d0,$a8(a0)
	move.w	d0,$b8(a0)
	move.w	d0,$c8(a0)
	move.w	d0,$d8(a0)
	clr.b	mt_songpos
	clr.b	mt_counter
	clr.w	mt_pattpos
	rts

mt_end:	clr.w	$dff0a8
	clr.w	$dff0b8
	clr.w	$dff0c8
	clr.w	$dff0d8
	move.w	#$f,$dff096
	rts

mt_music:
	move.l	moduleAddr(pc),a0
	addq.b	#1,mt_counter
	move.b	mt_counter(pc),d0
	cmp.b	mt_speed(pc),d0
	blt.w	mt_nonew
	clr.b	mt_counter

	move.l	moduleAddr(pc),a0
	lea	$c(a0),a3
	lea	$3b8(a0),a2
	lea	$43c(a0),a0

	moveq	#0,d0
	moveq	#0,d1
	move.b	mt_songpos(pc),d0
	move.b	(a2,d0.w),d1
	lsl.w	#8,d1
	lsl.w	#2,d1

	lea		(a0,d1.l),a5
	move.l	a5,Stripe1
	addq	#4,a5
	move.l	a5,Stripe2
	addq	#4,a5
	move.l	a5,Stripe3
	addq	#4,a5
	move.l	a5,Stripe4
	move	mt_pattpos(pc),d2
	lsr		#4,d2
	move	d2,PatternInfo+PI_Pattpos	

	add.w	mt_pattpos(pc),d1
	clr.w	mt_dmacon

	lea	$dff0a0,a5
	lea	mt_voice1(pc),a4
	bsr.w	mt_playvoice
	addq.l	#4,d1
	lea	$dff0b0,a5
	lea	mt_voice2(pc),a4
	bsr.w	mt_playvoice
	addq.l	#4,d1
	lea	$dff0c0,a5
	lea	mt_voice3(pc),a4
	bsr.w	mt_playvoice
	addq.l	#4,d1
	lea	$dff0d0,a5
	lea	mt_voice4(pc),a4
	bsr.w	mt_playvoice

	bsr.w	mt_wait
	move.w	mt_dmacon(pc),d0
	or.w	#$8000,d0
	move.w	d0,$dff096
	bsr.w	mt_wait
mt_nodma:
	lea	$dff000,a3
	lea	mt_voice1(pc),a4
	move.l	$a(a4),$a0(a3)
	move.w	$e(a4),$a4(a3)
	tst.w	30(a4)
	bne.s	mt_nov1
;	move.w	$12(a4),$a8(a3)
	move.w	$12(a4),d0
	mulu	mainVol(pc),d0
	lsr	#6,d0
	move	d0,$a8(a3)
mt_nov1:lea	mt_voice2(pc),a4
	move.l	$a(a4),$b0(a3)
	move.w	$e(a4),$b4(a3)
	tst.w	30(a4)
	bne.s	mt_nov2
;	move.w	$12(a4),$b8(a3)
	move.w	$12(a4),d0
	mulu	mainVol(pc),d0
	lsr	#6,d0
	move	d0,$b8(a3)
mt_nov2:lea	mt_voice3(pc),a4
	move.l	$a(a4),$c0(a3)
	move.w	$e(a4),$c4(a3)
	tst.w	30(a4)
	bne.s	mt_nov3
;	move.w	$12(a4),$c8(a3)
	move.w	$12(a4),d0
	mulu	mainVol(pc),d0
	lsr	#6,d0
	move	d0,$c8(a3)
mt_nov3:lea	mt_voice4(pc),a4
	move.l	$a(a4),$d0(a3)
	tst.w	30(a4)
	bne.s	mt_nov4
	move.w	$e(a4),$d4(a3)
;	move.w	$12(a4),$d8(a3)
	move.w	$12(a4),d0
	mulu	mainVol(pc),d0
	lsr	#6,d0
	move	d0,$d8(a3)
mt_nov4:add.w	#$10,mt_pattpos
	cmp.w	#$400,mt_pattpos
	bne.s	mt_exit
mt_next:clr.w	mt_pattpos
	clr.b	mt_break
	move.l	moduleAddr(pc),a0
	addq.b	#1,mt_songpos
	and.b	#$7f,mt_songpos
	move.b	$3b6(a0),d0
	cmp.b	mt_songpos(pc),d0
	bne.s	mt_exit
	push	a0 
	move.l	songEndAddr(pc),a0 
	st (a0)
	pop a0 
	move.b	$3b7(a0),mt_songpos
mt_exit:tst.b	mt_break
	bne.s	mt_next
	bra.w	mt_amhandler

;mt_wait:moveq	#4,d3		
;mt_wai2:move.b	$dff006,d2	
;mt_wai3:cmp.b	$dff006,d2	
;	beq.s	mt_wai3
;	dbf	d3,mt_wai2	
;	moveq	#8,d2
;mt_wai4:dbf	d2,mt_wai4

mt_wait:
	push	a0 
	move.l	dmaWaitAddr(pc),a0 
	jsr 	 (a0)
	pop a0 
	rts

mt_nonew:
	lea	mt_voice1(pc),a4
	lea	$dff0a0,a5
	bsr.w	mt_com
	lea	mt_voice2(pc),a4
	lea	$dff0b0,a5
	bsr.w	mt_com
	lea	mt_voice3(pc),a4
	lea	$dff0c0,a5
	bsr.w	mt_com
	lea	mt_voice4(pc),a4
	lea	$dff0d0,a5
	bsr.w	mt_com
	bra.s	mt_exit

mt_mulu:
	dc.w	0,$1e,$3c,$5a,$78,$96,$b4,$d2,$f0,$10e,$12c,$14a
	dc.w	$168,$186,$1a4,$1c2,$1e0,$1fe,$21c,$23a,$258,$276
	dc.w	$294,$2b2,$2d0,$2ee,$30c,$32a,$348,$366,$384,$3a2

mt_playvoice:
	move.l	(a0,d1.l),(a4)
	moveq	#0,d2
	move.b	2(a4),d2
	lsr.b	#4,d2
	move.b	(a4),d0
	and.b	#$f0,d0
	or.b	d0,d2
	beq.w	mt_oldinstr

	lea	mt_samplestarts-4(pc),a1
	move.w	d2,34(a4)
	move.w	d2,d0
	mulu	#120,d0
	;add.l	#mt_data2+24,d0
	add.l	dataAddr(pc),d0

	move.l	a0,-(sp)
	move.l	d0,a0
	clr.w	30(a4)
	cmp.w	#"AM",(a0)
	bne.s	mt_noa9
	move.w	6(a0),d0
	lsr.w	#2,d0
	st	30(a4)
mt_noa9:move.l	(sp)+,a0

	asl.w	#2,d2
	move.l	(a1,d2.l),4(a4)
	lsr.w	#2,d2
	mulu	#30,d2
	move.w	(a3,d2.w),8(a4)
	tst.w	30(a4)
	beq.s	mt_noa8
	move.w	d0,$12(a4)
	bra.s	mt_noa7
mt_noa8:move.w	2(a3,d2.w),$12(a4)
mt_noa7:moveq	#0,d3
	move.w	4(a3,d2.w),d3
	tst.w	d3
	beq.s	mt_noloop
	move.l	4(a4),d0
	asl.w	#1,d3
	add.l	d3,d0
	move.l	d0,$a(a4)
	move.w	4(a3,d2.w),d0
	add.w	6(a3,d2.w),d0
	move.w	d0,8(a4)
	bra.s	mt_hejaSverige
mt_noloop:
	move.l	4(a4),d0
	add.l	d3,d0
	move.l	d0,$a(a4)
mt_hejaSverige:
	move.w	6(a3,d2.w),$e(a4)

mt_oldinstr:
	move.w	(a4),d0
	and.w	#$fff,d0
	beq.w	mt_com2
	tst.w	30(a4)
	bne.s	mt_rambo
	tst.w	8(a4)
	beq.w	mt_stopsound
	tst.b	$12(a4)
	bne.w	mt_stopsound
	move.b	2(a4),d0
	and.b	#$f,d0
	cmp.b	#5,d0
	beq.w	mt_setport
	cmp.b	#3,d0
	beq.w	mt_setport

mt_rambo:
	move.w	(a4),$10(a4)
	and.w	#$fff,$10(a4)
	move.w	$1a(a4),$dff096
	clr.b	$19(a4)

	tst.w	30(a4)
	beq.s	mt_noaminst
	move.l	a0,-(sp)
	move.w	34(a4),d0
	mulu	#120,d0
	;add.l	#mt_data2+24,d0
	add.l	dataAddr(pc),d0

	move.l	d0,a0
	moveq	#0,d0
	move.w	26(a0),d0
	lsl.w	#5,d0
	add.l	#mt_amwaveforms,d0
	move.l	d0,(a5)
	move.w	#16,4(a5)
	move.l	d0,$a(a4)
	move.w	#16,$e(a4)
	move.w	6(a0),32(a4)
	move.l	#1,36(a4)
	move.w	34(a0),d0
	move.w	d1,-(sp)
	move.w	$10(a4),d1
	lsl.w	d0,d1
	move.w	d1,$10(a4)
	move.w	d1,6(a5)
	move.w	(sp)+,d1
	move.l	(sp)+,a0
	bra.s	mt_juck

mt_noaminst:
	move.l	4(a4),(a5)
	move.w	8(a4),4(a5)
	move.w	$10(a4),6(a5)

mt_juck:move.w	$1a(a4),d0
	or.w	d0,mt_dmacon
	bra.w	mt_com2

mt_stopsound:
	move.w	$1a(a4),$dff096
	bra.w	mt_com2

mt_setport:
	move.w	(a4),d2
	and.w	#$fff,d2
	move.w	d2,$16(a4)
	move.w	$10(a4),d0
	clr.b	$14(a4)
	cmp.w	d0,d2
	beq.s	mt_clrport
	bge.w	mt_com2
	move.b	#1,$14(a4)
	bra.w	mt_com2
mt_clrport:
	clr.w	$16(a4)
	rts

mt_port:move.b	3(a4),d0
	beq.s	mt_port2
	move.b	d0,$15(a4)
	clr.b	3(a4)
mt_port2:
	tst.w	$16(a4)
	beq.s	mt_rts
	moveq	#0,d0
	move.b	$15(a4),d0
	tst.b	$14(a4)
	bne.s	mt_sub
	add.w	d0,$10(a4)
	move.w	$16(a4),d0
	cmp.w	$10(a4),d0
	bgt.s	mt_portok
	move.w	$16(a4),$10(a4)
	clr.w	$16(a4)
mt_portok:
	move.w	$10(a4),6(a5)
mt_rts:	rts

mt_sub:	sub.w	d0,$10(a4)
	move.w	$16(a4),d0
	cmp.w	$10(a4),d0
	blt.s	mt_portok
	move.w	$16(a4),$10(a4)
	clr.w	$16(a4)
	move.w	$10(a4),6(a5)
	rts

mt_sin:	dc.b	0,$18,$31,$4a,$61,$78,$8d,$a1,$b4,$c5,$d4,$e0,$eb,$f4
	dc.b	$fa,$fd
	dc.b	$ff,$fd,$fa,$f4,$eb,$e0,$d4,$c5,$b4,$a1,$8d,$78,$61
	dc.b	$4a,$31,$18

mt_vib:	move.b	$3(a4),d0
	beq.s	mt_vib2
	move.b	d0,$18(a4)

mt_vib2:move.b	$19(a4),d0
	lsr.w	#2,d0
	and.w	#$1f,d0
	moveq	#0,d2
	move.b	mt_sin(pc,d0.w),d2
	move.b	$18(a4),d0
	and.w	#$f,d0
	mulu	d0,d2
	lsr.w	#7,d2
	move.w	$10(a4),d0
	tst.b	$19(a4)
	bmi.s	mt_vibsub
	add.w	d2,d0
	bra.s	mt_vib3
mt_vibsub:
	sub.w	d2,d0
mt_vib3:move.w	d0,6(a5)
	move.b	$18(a4),d0
	lsr.w	#2,d0
	and.w	#$3c,d0
	add.b	d0,$19(a4)
	rts

mt_arplist:
	dc.b	0,1,2,0,1,2,0,1,2,0,1,2,0
	dc.b	1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1

mt_arp:	moveq	#0,d0
	move.b	mt_counter(pc),d0
	move.b	mt_arplist(pc,d0.w),d0
	beq.s	mt_arp0
	cmp.b	#2,d0
	beq.s	mt_arp2
mt_arp1:moveq	#0,d0
	move.b	3(a4),d0
	lsr.b	#4,d0
	bra.s	mt_arpdo
mt_arp2:moveq	#0,d0
	move.b	3(a4),d0
	and.b	#$f,d0
mt_arpdo:
	asl.w	#1,d0
	move.w	$10(a4),d1
	and.w	#$fff,d1
	lea	mt_periods(pc),a0
	moveq	#$24,d2
mt_arp3:cmp.w	(a0)+,d1
	bge.s	mt_arpfound
	dbf	d2,mt_arp3
mt_arp0:move.w	$10(a4),6(a5)
	rts
mt_arpfound:
	move.w	-2(a0,d0.w),6(a5)
	rts

mt_normper:
	move.w	$10(a4),6(a5)
	rts

mt_com:	move.w	2(a4),d0
	and.w	#$fff,d0
	beq.s	mt_normper
	move.b	2(a4),d0
	and.b	#$f,d0
	tst.b	d0
	beq.s	mt_arp
	cmp.b	#1,d0
	beq.s	mt_portup
	cmp.b	#2,d0
	beq.s	mt_portdown
	cmp.b	#3,d0
	beq.w	mt_port
	cmp.b	#4,d0
	beq.w	mt_vib
	cmp.b	#5,d0
	beq.s	mt_volport
	cmp.b	#6,d0
	beq.s	mt_volvib
	move.w	$10(a4),6(a5)
	cmp.b	#$a,d0
	beq.s	mt_volslide
	rts

mt_portup:
	moveq	#0,d0
	move.b	3(a4),d0
	sub.w	d0,$10(a4)
	move.w	$10(a4),d0
	cmp.w	#$71,d0
	bpl.s	mt_portup2
	move.w	#$71,$10(a4)
mt_portup2:
	move.w	$10(a4),6(a5)
	rts

mt_portdown:
	moveq	#0,d0
	move.b	3(a4),d0
	add.w	d0,$10(a4)
	move.w	$10(a4),d0
	cmp.w	#$358,d0
	bmi.s	mt_portdown2
	move.w	#$358,$10(a4)
mt_portdown2:
	move.w	$10(a4),6(a5)
	rts

mt_volvib:
	 bsr.w	mt_vib2
	 bra.s	mt_volslide
mt_volport:
	 bsr.w	mt_port2

mt_volslide:
	moveq	#0,d0
	move.b	3(a4),d0
	lsr.b	#4,d0
	beq.s	mt_vol3
	add.b	d0,$13(a4)
	cmp.b	#$40,$13(a4)
	bmi.s	mt_vol2
	move.b	#$40,$13(a4)
mt_vol2:moveq	#0,d0
	move.b	$13(a4),d0
	mulu	mainVol(pc),d0 
	lsr	#6,d0
	move.w	d0,8(a5)
	rts

mt_vol3:move.b	3(a4),d0
	and.b	#$f,d0
	sub.b	d0,$13(a4)
	bpl.s	mt_vol4
	clr.b	$13(a4)
mt_vol4:moveq	#0,d0
	move.b	$13(a4),d0
	mulu	mainVol(pc),d0 
	lsr	#6,d0
	move.w	d0,8(a5)
	rts

mt_com2:move.b	$2(a4),d0
	and.b	#$f,d0
	cmp.b	#$e,d0
	beq.s	mt_filter
	cmp.b	#$d,d0
	beq.s	mt_pattbreak
	cmp.b	#$b,d0
	beq.s	mt_songjmp
	cmp.b	#$c,d0
	beq.s	mt_setvol
	cmp.b	#$f,d0
	beq.s	mt_setspeed
	rts

mt_filter:
	move.b	3(a4),d0
	and.b	#1,d0
	asl.b	#1,d0
	and.b	#$fd,$bfe001
	or.b	d0,$bfe001
	rts

mt_pattbreak:
	move.b	#1,mt_break
	rts

mt_songjmp:
	move.b	#1,mt_break
	move.b	3(a4),d0
	subq.b	#1,d0
	move.b	d0,mt_songpos
	rts

mt_setvol:
	cmp.b	#$40,3(a4)
	bls.s	mt_sv2
	move.b	#$40,3(a4)
mt_sv2:	moveq	#0,d0
	move.b	3(a4),d0
	move.b	d0,$13(a4)
	mulu	mainVol(pc),d0 
	lsr	#6,d0
	move.w	d0,8(a5)
	rts

mt_setspeed:
	moveq	#0,d0
	move.b	3(a4),d0
	cmp.b	#$1f,d0
	bls.s	mt_sp2
	moveq	#$1f,d0
mt_sp2:	tst.w	d0
	bne.s	mt_sp3
	moveq	#1,d0
mt_sp3:	move.b	d0,mt_speed
	rts

mt_amhandler:
	moveq	#3,d7
	lea	mt_voice1,a6
	lea	$dff0a0,a5
mt_amloop:
	tst.w	30(a6)
	beq.w	mt_anrp
	move.w	34(a6),d0
	mulu	#120,d0
	;add.l	#mt_data2+24,d0
	add.l	dataAddr(pc),d0
	move.l	d0,a0
	tst.w	38(a6)
	beq.w	mt_anrp
	cmp.w	#1,38(a6)
	bne.s	mt_anat
	move.w	32(a6),d0
	cmp.w	8(a0),d0
	beq.s	mt_aaeq
	cmp.w	8(a0),d0
	blt.s	mt_aaad
	move.w	10(a0),d0
	sub.w	d0,32(a6)
	move.w	32(a6),d0
	cmp.w	8(a0),d0
	bgt.w	mt_anxt
	move.w	8(a0),32(a6)
mt_aaeq:move.w	#2,38(a6)
	bra.w	mt_anxt
mt_aaad:move.w	10(a0),d0
	add.w	d0,32(a6)
	move.w	32(a6),d0
	cmp.w	8(a0),d0
	blt.w	mt_anxt
	move.w	8(a0),32(a6)
	bra.s	mt_aaeq
mt_anat:cmp.w	#2,38(a6)
	bne.s	mt_ana2
	move.w	32(a6),d0
	cmp.w	12(a0),d0
	beq.s	mt_a2eq
	cmp.w	12(a0),d0
	blt.s	mt_a2ad
	move.w	14(a0),d0
	sub.w	d0,32(a6)
	move.w	32(a6),d0
	cmp.w	12(a0),d0
	bgt.w	mt_anxt
	move.w	12(a0),32(a6)
mt_a2eq:move.w	#3,38(a6)
	bra.w	mt_anxt
mt_a2ad:move.w	14(a0),d0
	add.w	d0,32(a6)
	move.w	32(a6),d0
	cmp.w	12(a0),d0
	blt.w	mt_anxt
	move.w	12(a0),32(a6)
	bra.s	mt_a2eq
mt_ana2:cmp.w	#3,38(a6)
	bne.s	mt_andc
	move.w	32(a6),d0
	cmp.w	16(a0),d0
	beq.s	mt_adeq
	cmp.w	16(a0),d0
	blt.s	mt_adad
	move.w	18(a0),d0
	sub.w	d0,32(a6)
	move.w	32(a6),d0
	cmp.w	16(a0),d0
	bgt.s	mt_anxt
	move.w	16(a0),32(a6)
mt_adeq:move.w	#4,38(a6)
	move.w	20(a0),40(a6)
	bra.s	mt_anxt
mt_adad:move.w	18(a0),d0
	add.w	d0,32(a6)
	move.w	32(a6),d0
	cmp.w	16(a0),d0
	blt.s	mt_anxt
	move.w	16(a0),32(a6)
	bra.s	mt_adeq
mt_andc:cmp.w	#4,38(a6)
	bne.s	mt_anst
	subq.w	#1,40(a6)
	bpl.s	mt_anxt
	move.w	#5,38(a6)
	bra.s	mt_anxt
mt_anst:move.w	24(a0),d0
	sub.w	d0,32(a6)
	bpl.s	mt_anxt
	clr.l	30(a6)
	clr.w	38(a6)
	move.w	26(a6),$dff096
mt_anxt:move.w	32(a6),d0
	lsr.w	#2,d0
	mulu  mainVol(pc),d0 
	lsr 	#6,d0
	move.w	d0,8(a5)
	move.w	28(a0),d0
	add.w	d0,16(a6)
	move.w	30(a0),d1
	beq.s	mt_nvib
	move.w	36(a6),d2
	moveq	#0,d3
	cmp.w	#360,d2
	blt.s	mt_vibq
	sub.w	#360,d2
	moveq	#1,d3
mt_vibq:lea	mt_amsinus,a2
	muls	(a2,d2.w),d1
	asr.w	#7,d1
	tst.w	d3
	beq.s	mt_nvib
	neg.w	d1
mt_nvib:add.w	16(a6),d1
	move.w	d1,6(a5)
	move.w	32(a0),d0
	add.w	d0,d0
	add.w	d0,36(a6)
	cmp.w	#720,36(a6)
	blt.s	mt_anrp
	sub.w	#720,36(a6)
mt_anrp:lea	$10(a5),a5
	lea	42(a6),a6
	dbra	d7,mt_amloop

	lea	mt_noisewave,a0
	move.w	#$7327,d0
	moveq	#31,d1
mt_nlop:move.b	d0,(a0)+
	add.b	$dff007,d0
	eor.w	#124,d0
	rol.w	#3,d0
	dbra	d1,mt_nlop
	rts

mt_amwaveforms:
	dc.b	0,25,49,71,90,106,117,125
	dc.b	127,125,117,106,90,71,49,25
	dc.b	0,-25,-49,-71,-90,-106,-117
	dc.b	-125,-127,-125,-117,-106
	dc.b	-90,-71,-49,-25
	dc.b	-128,-120,-112,-104,-96,-88,-80,-72,-64,-56,-48
	dc.b	-40,-32,-24,-16,-8,0,8,16,24,32,40,48,56,64,72,80
	dc.b	88,96,104,112,120
	blk.b	16,-128
	blk.b	16,127
mt_noisewave:
	blk.b	32,0

mt_amsinus:
	dc.w	0,2,4,6,8,$b,$d,$f,$11,$14,$16,$18,$1a,$1c,$1e,$21
	dc.w	$23,$25,$27,$29,$2b,$2d,$2f,$32,$34,$36,$38,$3a,$3c,$3e
	dc.w	$3f,$41,$43,$45,$47,$49,$4b,$4d,$4e,$50,$52,$53,$55,$57
	dc.w	$58,$5a,$5c,$5d,$5f,$60,$62,$63,$64,$66,$67,$68,$6a,$6b
	dc.w	$6c,$6d,$6e,$6f,$71,$72,$73,$74,$74,$75,$76,$77,$78,$79
	dc.w	$79,$7a,$7b,$7b,$7c,$7c,$7d,$7d,$7e,$7e,$7e,$7f,$7f,$7f
	dc.w	$7f,$7f,$7f,$7f,$80,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7e,$7e
	dc.w	$7e,$7d,$7d,$7c,$7c,$7b,$7b,$7a,$79,$79,$78,$77,$76,$75
	dc.w	$74,$73,$72,$71,$6f,$6e,$6d,$6c,$6b,$6a,$68,$67,$66,$64
	dc.w	$63,$62,$60,$5f,$5d,$5c,$5a,$58,$57,$55,$53,$52,$50,$4e
	dc.w	$4d,$4b,$49,$47,$45,$43,$41,$40,$3e,$3c,$3a,$38,$36,$34
	dc.w	$32,$2f,$2d,$2b,$29,$27,$25,$23,$21,$1e,$1c,$1a,$18,$16
	dc.w	$14,$11,$f,$d,$b,$8,$6,$4,$2,0
	
mt_periods:
	dc.w	$358,$328,$2fa,$2d0,$2a6,$280,$25c,$23a,$21a,$1fc,$1e0
	dc.w	$1c5,$1ac,$194,$17d,$168,$153,$140,$12e,$11d,$10d,$fe
	dc.w	$f0,$e2,$d6,$ca,$be,$b4,$aa,$a0,$97,$8f,$87
	dc.w	$7f,$78,$71,0

mt_speed:	dc.b	6
mt_counter:	dc.b	0
mt_pattpos:	dc.w	0
mt_songpos:	dc.b	0
mt_break:	dc.b	0
mt_dmacon:	dc.w	0
mt_samplestarts:blk.l	$1f,0
mt_voice1:	blk.w	13,0
		dc.w	1
		blk.w	7,0
mt_voice2:	blk.w	13,0
		dc.w	2
		blk.w	7,0
mt_voice3:	blk.w	13,0
		dc.w	4
		blk.w	7,0
mt_voice4:	blk.w	13,0
		dc.w	8
		blk.w	7,0

