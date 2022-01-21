;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
testi = 0

	incdir	include:
	Include	mucro.i
	include	misc/eagleplayer.i
	incdir	include/
	include	patternInfo.i
	incdir


 ifne testi

;		bsr.w	BP_Config
;		bsr.w	BP_Check	
;		bne.s	error
;		bsr.w	BP_InitPlayer
;		bne.s	error
;		bsr.w	BP_InitSound


	move.l	#dmawait_,d0
	lea	data,a0
	lea	dum(pc),a1
	lea	dum(pc),a2
	lea	vol(pc),a4
	lea	zum,a3
	jsr	init
wait:	
	cmp.b	#$80,$dff006
	bne.s	wait
.w	cmp.b	#$80,$dff006
	beq.s	.w

	move	#$ff0,$dff180
	jsr	BP_Music
	clr	$dff180
	btst	#6,$bfe001
	bne.s	wait
error:		
	move.w	#15,$dff096
	rts
	
vol	dc	64
dum	dc.l	0

dmawait_
	pushm	d0/d1
	moveq	#12-1,d1
.d	move.b	$dff006,d0
.k	cmp.b	$dff006,d0
	beq.b	.k
	dbf	d1,.d
	popm	d0/d1
	rts

	rts

	section	chippo,bss_c
zum	ds.l	0

 endc

;	section	chippo2,code_c

main
	jmp 	init(pc)
	jmp	BP_Music(pc)
	jmp	forward(pc)
	jmp	rewind(pc)


init
	bsr	BP_InitSound
	bsr 	 PatternInit
	rts

;------------------------------------------------------------------------------
; Rewind
; IN :	A1 = Address
; OUT:	D1 = New Position

rewind
	move.l	BP_Data(pc),a1

	move.w	currentposition(pc),d1
	beq.b	sforwa1
	subq.w	#1,d1
	bra.b	sforwa1
;------------------------------------------------------------------------------
; Forward
; IN :	A1 = Address
; OUT:	D1 = New Position

forward
	move.l	BP_Data(pc),a1

	move.w	currentposition(pc),d1
	addq.w	#1,d1
	cmp.w	$1e(a1),d1
	blo.b	sforwa1
	moveq	#0,d1

sforwa1	move.w	d1,currentposition
;	clr.b	SMON_BPPatCount(a0)
	clr.b	patcounter

	rts


songover	dc.l	0
poslen		dc.l	0
mainvolume	dc.l	0
volume		dc	0
dmawait		dc.l	0



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
	move.l	#3,PI_Modulo(A0)	; Number of bytes to next row
	move.w	#16,PI_Pattlength(A0)	; Length of each stripe in rows
	clr.w	PI_Pattpos(A0)		; Current Position in Pattern (from 0)
	move	#-1,PI_Speed(a0)	; Magic! Indicates notes, not periods
	rts


* Called by the PI engine to get values for a particular row
ConvertNote
	moveq	#0,D0		; Period, Note
	moveq	#0,D1		; Sample number
	moveq	#0,D2		; Command 
	moveq	#0,D3		; Command argument

	* Period index starting from 1, 0 for no period
	move.b	(a0),d0
	beq.b	.optional
		
	* this could be the sample number
	move.b	1(a0),d1
	lsr.b	#4,d1

	* Sample transpose
	lea	PI_SampleTranspose1(a1),a3
	add	PI_CurrentChannelNumber(a1),a3
	add.b	(a3),d1

	moveq	#15,d2
	and.b 	1(a0),d2		* cmd

	cmpi.b	#10,d2    		;Option 10->transposes off
	bne.b	.bp_do1
	move.b	2(a0),d3
	and.b	#240,d3	  		;Higher nibble=transpose
	bne.b	.bp_not1
.bp_do1
	lea	PI_NoteTranspose1(a1),a3
	add	PI_CurrentChannelNumber(a1),a3
	add.b	(a3),d0
	ext	d0
.bp_not1	
	* scale is 7 octaves.
	* note 0 is the 4th octave.
	add		#4*12,d0

.optional
	moveq	#15,d2
	and.b 	1(a0),d2	* cmd
	move.b	2(a0),d3	* arg
	rts




*----------------------------------------------------------------------------*
BP_InitSound:
	movem.l	a0-a5,-(sp)
	move.l	d0,dmawait
;
;BP_Config:	lea	BP_StartPuffer,a0
;		lea	BP_MerkPuffer,a1
;		move.w	#BP_SizePuffer-1,d0
;.opyIt:		move.b	(a0)+,(a1)+
;		dbf	d0,.opyIt

	movem.l	(sp)+,a0-a5
	
	move.l	a0,BP_Data
	move.l	a1,songover
	move.l	a2,poslen
	move.l	a4,mainvolume
	move.l	a3,BP_ZeroSample

	move	$1e(a0),2(a2)		* last step
	subq	#1,2(a2)

	lea	BP_A7C(pc),a0
	move.l	a3,4(a0)
	move.l	a3,4+36(a0)
	move.l	a3,4+36+36(a0)
	move.l	a3,4+36+36+36(a0)


	bset	#1,$bfe001


;		lea	BP_StartPuffer,a0
;		lea	BP_MerkPuffer,a1
;		move.w	#BP_SizePuffer-1,d0
;.CopyIt:	move.b	(a1)+,(a0)+
;		dbf	d0,.CopyIt


		lea	BP_WaveBuffer,a0
		move.l	BP_Data(pc),a1
		clr.b	BP_B15
		move.b	$1D(a1),BP_B15
		move.l	#$200,d0
		move.w	$1E(a1),d1
		move.l	#1,d2
		lsl.w	#2,d1
		subq.w	#1,d1
		andi.l	#$FFFF,d1
BP_1C4:		cmp.w	(a1,d0.w),d2
		bge.s	BP_1CE
		move.w	(a1,d0.w),d2
BP_1CE:		addq.l	#4,d0
		dbra	d1,BP_1C4

		move.w	$1E(a1),d1
		lsl.w	#4,d1
		andi.l	#$FFFF,d1
		move.l	#$200,d0
		mulu.w	#$30,d2
		add.l	d2,d0
		add.l	d1,d0
		add.l	BP_Data(pc),d0
		move.l	d0,BP_B2E
		moveq	#0,d1
		move.b	BP_B15,d1
		lsl.l	#6,d1
		add.l	d1,d0
		moveq	#14,d1
		lea	$20(a1),a1
BP_20A:		move.l	d0,(a0)+
		cmpi.b	#$FF,(a1)
		beq.s	BP_220
		move.w	$18(a1),d2
		add.w	d2,d2
		andi.l	#$FFFF,d2
		add.l	d2,d0
BP_220:		lea	$20(a1),a1
		dbra	d1,BP_20A
		rts

*----------------------------------------------------------------------------*
BP_Music:	
	move.l	poslen(pc),a2
	move	currentposition(pc),(a2)
	move.l	mainvolume(pc),a2
	move	(a2),volume

.BP_M:		lea	BP_Counter,a2
		subq.b	#1,(a2)			;BP_Counter
		andi.b	#3,(a2)			;BP_Counter
		moveq	#3,d0
		lea	BP_A7C-BP_Counter(a2),a0
		lea	$DFF0A0,a1
		addq.l	#2,BP_B18-BP_Counter(a2)
		cmpi.l	#BP_DMACon,BP_B18-BP_Counter(a2)
		bne.s	.BP_260
		move.l	#BP_B1C,BP_B18-BP_Counter(a2)
.BP_260:	move.l	BP_B18-BP_Counter(a2),a5
BP_264:		move.b	12(a0),d4
		ext.w	d4
		add.w	d4,(a0)
		tst.b	$22(a0)
		beq.s	BP_286
		moveq	#0,d4
		move.b	$22(a0),d4
		move.w	(a5),d5
		ext.l	d5
		divs.w	d4,d5
		add.w	(a0),d5
		move.w	d5,6(a1)
		bra.s	BP_28A

BP_286:		move.w	(a0),6(a1)
BP_28A:		move.l	4(a0),(a1)
		move.w	8(a0),4(a1)
		tst.b	11(a0)
		bne.s	BP_2A0
		tst.b	13(a0)
		beq.s	BP_2F6
BP_2A0:		tst.b	BP_Counter
		bne.s	BP_2C8
		move.b	11(a0),d3
		move.b	13(a0),d4
		andi.w	#$F0,d4
		andi.w	#$F0,d3
		lsr.w	#4,d3
		lsr.w	#4,d4
		add.w	d3,d4
		add.b	10(a0),d4
		bsr.w	BP_78E
		bra.s	BP_2F6

BP_2C8:		cmpi.b	#1,BP_Counter
		bne.s	BP_2EE
		move.b	11(a0),d3
		move.b	13(a0),d4
		andi.w	#15,d3
		andi.w	#15,d4
		add.w	d3,d4
		add.b	10(a0),d4
		bsr.w	BP_78E
		bra.s	BP_2F6

BP_2EE:		move.b	10(a0),d4
		bsr.w	BP_78E
BP_2F6:		lea	$10(a1),a1
		lea	$24(a0),a0
		dbra	d0,BP_264
		bsr.w	BP_7A2
		subq.b	#1,BP_B11
		beq.s	BP_310
		rts

BP_310:		lea	BP_B11,a0
		move.b	BP_B12-BP_B11(a0),(a0)
		bsr.w	BP_3A0
		move.w	BP_DMACon,$DFF096

;	;Wait !!!
;		if	Test
;		moveq	#$7F,d0
;.BP_326:	dbra	d0,.BP_326
;		else
;	;	move.l	EP_Base(pc),a5
;	;	jsr	ENPP_WaitAudioDMA(a5)
;		endc
;	;Wait !!!



	move.l	dmawait(pc),a5
	jsr	(a5)


		moveq	#3,d0
		lea	BP_B32,a5
		lea	BP_A7C-BP_B32(a5),a2
.BP_334:	btst	#7,(a2)
		beq.s	.BP_34C
		tst.l	(a5)
		beq.s	.BP_34C
		move.l	(a5),a4
		clr.l	(a5)
		movem.l	4(a5),d1-d7/a0
		movem.l	d1-d7/a0,(a4)
.BP_34C:	lea	$24(a5),a5
		lea	$24(a2),a2
		dbra	d0,.BP_334

		moveq	#3,d0
		lea	$DFF0A0,a1
		move.w	#1,d1
		lea	BP_A7C,a2
		lea	BP_B32-BP_A7C(a2),a5
		clr.w	BP_DMACon-BP_A7C(a2)
.BP_372:	btst	#7,(a2)
		beq.s	.BP_37C
		bsr.w	BP_5F0
.BP_37C:	asl.w	#1,d1
		lea	$10(a1),a1
		lea	$24(a2),a2
		lea	$24(a5),a5
		dbra	d0,.BP_372
		ori.w	#$8000,BP_DMACon
		move.w	BP_DMACon,$DFF096
		rts

BP_3A0:		clr.w	BP_DMACon
		move.l	BP_Data(pc),a0
		lea	$DFF0A0,a3
		moveq	#3,d0
		move.w	#1,d7
		lea	BP_A7C,a1
BP_3BA:		moveq	#0,d1
		move.w	BP_B0C,d1
		lsl.w	#4,d1
		move.l	d0,d2
		lsl.l	#2,d2
		add.l	d2,d1
		addi.l	#$200,d1
		move.w	(a0,d1.w),d2
		move.b	2(a0,d1.w),BP_B0F	* SMON_ST
		move.b	3(a0,d1.w),BP_B10	* SMON_TR
		subq.w	#1,d2
		mulu.w	#$30,d2
		moveq	#0,d3
		move.w	$1E(a0),d3
		lsl.w	#4,d3
		add.l	d2,d3
		
	;	move.l	#$200,d4
	;	move.b	BP_B0E,d4
	;	add.l	d3,d4
	;	move.l	d4,a2
	;	add.l	a0,a2
		
		lea	$200(a0),a2
		add.l	d3,a2

		cmp.b	#1,d7
		bne.b 	.a 
		move.l	a2,Stripe1
		move.b	SMON_ST(pc),PatternInfo+PI_SampleTranspose1
		move.b	SMON_TR(pc),PatternInfo+PI_NoteTranspose1
		bra.b	.d
.a
		cmp.b	#2,d7
		bne.b 	.b 
		move.l	a2,Stripe2
		move.b	SMON_ST(pc),PatternInfo+PI_SampleTranspose2
		move.b	SMON_TR(pc),PatternInfo+PI_NoteTranspose2
		bra.b	.d
.b
		cmp.b	#4,d7
		bne.b 	.c 
		move.l	a2,Stripe3
		move.b	SMON_ST(pc),PatternInfo+PI_SampleTranspose3
		move.b	SMON_TR(pc),PatternInfo+PI_NoteTranspose3
		bra.b	.d
.c
		cmp.b	#8,d7
		bne.b 	.d 
		move.l	a2,Stripe4
		move.b	SMON_ST(pc),PatternInfo+PI_SampleTranspose4
		move.b	SMON_TR(pc),PatternInfo+PI_NoteTranspose4
.d
		moveq	#0,d4
		move.b	BP_B0E,d4
		divu	#3,d4
		move	d4,PatternInfo+PI_Pattpos

		moveq	#0,d4
		move.b	BP_B0E,d4
		add.l	d4,a2
		
		moveq	#0,d3
		move.b	(a2),d3
		tst.b	d3
		beq.w	BP_4A2
		clr.w	12(a1)
		clr.b	$22(a1)
		move.b	1(a2),d5
		andi.b	#15,d5
		cmpi.b	#10,d5
		bne.s	BP_42C
		move.b	2(a2),d4
		andi.b	#$F0,d4
		bne.s	BP_432
BP_42C:		add.b	BP_B10,d3
		ext.w	d3
BP_432:		move.b	d3,10(a1)
		lea	PeriodeTable,a4
		lsl.w	#1,d3
		move.w	-2(a4,d3.w),(a1)
		cmpi.b	#13,d5
		bge.s	BP_450
		bset	#7,(a1)
		move.b	#$FF,2(a1)
BP_450:		move.b	1(a2),d3
		lsr.b	#4,d3
		andi.w	#15,d3
		tst.b	d3
		bne.s	BP_462
		move.b	3(a1),d3
BP_462:		move.b	1(a2),d4
		andi.b	#15,d4
		cmpi.b	#10,d4
		bne.s	BP_47A
		move.b	2(a2),d4
		andi.b	#15,d4
		bne.s	BP_47E
BP_47A:		add.b	BP_B0F,d3
BP_47E:		move.b	1(a2),d4
		andi.b	#15,d4
		cmpi.b	#13,d4
		bge.s	BP_4A2
		tst.b	$1B(a1)
		beq.s	BP_498
		cmp.b	3(a1),d3
		beq.s	BP_4A2
BP_498:		move.b	d3,3(a1)
		or.w	d7,BP_DMACon
BP_4A2:		clr.w	d4
		move.b	1(a2),d3
		move.b	2(a2),d4
		andi.w	#15,d3
		bne.s	BP_4BA
		move.b	d4,11(a1)
		bra.w	BP_592

BP_4BA:		cmpi.b	#1,d3
		bne.s	BP_4D4
		move.b	d4,2(a1)
		tst.b	$1B(a1)
		bne.w	BP_592

**************
	mulu	volume(pc),d4
	lsr	#6,d4
	move.w	d4,8(a3)

		bra.w	BP_592

BP_4D4:		cmpi.b	#2,d3
		bne.s	BP_4EA
		move.b	d4,BP_B11
		move.b	d4,BP_B12
		bra.w	BP_592

BP_4EA:		cmpi.b	#3,d3
		bne.s	BP_50C
		tst.b	d4
		bne.s	BP_500
		bset	#1,$BFE001
		bra.w	BP_592

BP_500:		bclr	#1,$BFE001
		bra.w	BP_592

BP_50C:		cmpi.b	#4,d3
		bne.s	BP_51A
		sub.w	d4,(a1)
		clr.b	11(a1)
		bra.s	BP_592

BP_51A:		cmpi.b	#5,d3
		bne.s	BP_528
		add.w	d4,(a1)
		clr.b	11(a1)
		bra.s	BP_592

BP_528:		cmpi.b	#6,d3
		bne.s	BP_534
		move.b	d4,$22(a1)
		bra.s	BP_592

BP_534:		cmpi.b	#7,d3
		bne.s	BP_54A
		move.b	d4,BP_B17
		move.b	#$FF,BP_B16
		bra.s	BP_592

BP_54A:		cmpi.b	#8,d3
		bne.s	BP_556
		move.b	d4,12(a1)
		bra.s	BP_592

BP_556:		cmpi.b	#11,d3
		bne.s	BP_560
		move.b	d4,$23(a1)
BP_560:		cmpi.b	#13,d3
		bge.s	BP_56C
		cmpi.b	#9,d3
		bne.s	BP_592
BP_56C:		move.b	d4,13(a1)
		cmpi.b	#13,d3
		bne.s	BP_57C
		eori.b	#1,$23(a1)
BP_57C:		cmpi.b	#15,d3
		beq.s	BP_592
		clr.w	$12(a1)
		tst.b	$1F(a1)
		bne.s	BP_592
		move.b	#1,$1F(a1)
BP_592:		lea	$10(a3),a3
		lea	$24(a1),a1
		asl.w	#1,d7
		dbra	d0,BP_3BA
		tst.b	BP_B16
		beq.s	BP_5BE
		clr.b	BP_B16
		clr.b	BP_B0E
		move.b	BP_B17,BP_B0D
		bra.s	BP_5EE

BP_5BE:		
		addq.b	#3,BP_B0E
		cmpi.b	#$30,BP_B0E
		bne.s	BP_5EE
		clr.b	BP_B0E
		addq.w	#1,BP_B0C
		move.l	BP_Data(pc),a0
		move.w	$1E(a0),d1
		cmp.w	BP_B0C,d1
		bne.s	BP_5EE
		clr.w	BP_B0C		* songover!

	move.l	a0,-(sp)
	move.l	songover(pc),a0
	st	(a0)
	move.l	(sp)+,a0


BP_5EE:		rts

BP_5F0:		bclr	#7,(a2)
		move.w	(a2),6(a1)
		moveq	#0,d7
		move.b	3(a2),d7
		move.l	d7,d6
		lsl.l	#5,d7
		move.l	BP_Data(pc),a3
		cmpi.b	#$FF,(a3,d7.w)
		beq.w	BP_68C
		clr.b	$1B(a2)
		clr.b	$1E(a2)
		addi.l	#$18,d7
		lsl.l	#2,d6
		lea	BP_WaveBuffer,a4
		move.l	-4(a4,d6.w),d4
		beq.s	BP_662
		move.l	d4,(a1)
		move.w	(a3,d7.w),4(a1)
		move.b	2(a2),9(a1)
		cmpi.b	#$FF,2(a2)
		bne.s	BP_646

****
	move.w	6(a3,d7.w),8(a1)
	move	6(a3,d7),d6
	mulu	volume(pc),d6
	lsr	#6,d6
	move	d6,8(a1)

BP_646:		move.w	4(a3,d7.w),8(a2)
		moveq	#0,d6
		move.w	2(a3,d7.w),d6
		add.l	d6,d4
		lsr.w	#1,d6
		move.l	d4,4(a2)
		cmpi.w	#1,8(a2)
		bne.s	BP_66C
BP_662:		move.l	BP_ZeroSample(pc),4(a2)
		bra.s	BP_684

BP_66C:		tst.w	d6
		beq.s	BP_67A
		add.w	8(a2),d6
		move.w	d6,4(a1)
		bra.s	BP_684

BP_67A:		move.w	8(a2),4(a1)
		move.l	4(a2),(a1)
BP_684:		or.w	d1,BP_DMACon
		rts

BP_68C:		move.b	#1,$1B(a2)
		clr.l	14(a2)
		clr.l	$12(a2)
		move.b	$14(a3,d7.w),$16(a2)
		addq.b	#1,$16(a2)
		move.b	14(a3,d7.w),$17(a2)
		addq.b	#1,$17(a2)
		move.b	#1,$18(a2)
		move.b	$1C(a3,d7.w),$19(a2)
		addq.b	#1,$19(a2)
		move.b	$18(a3,d7.w),$1A(a2)
		addi.b	#1,$1A(a2)
		move.b	$16(a3,d7.w),$23(a2)
		move.b	$10(a3,d7.w),$1D(a2)
		move.b	9(a3,d7.w),$1E(a2)
		move.b	4(a3,d7.w),$1F(a2)
		move.b	$19(a3,d7.w),$20(a2)
		clr.b	$1C(a2)
		move.l	BP_B2E,a4
		moveq	#0,d3
		move.b	1(a3,d7.w),d3
		lsl.l	#6,d3
		add.l	d3,a4
		move.l	a4,(a1)
		move.l	a4,4(a2)
		move.w	2(a3,d7.w),4(a1)
		move.w	2(a3,d7.w),8(a2)
		tst.b	$1F(a2)
		beq.s	BP_746
		move.l	BP_B2E,a4
		moveq	#0,d3
		move.b	5(a3,d7.w),d3
		lsl.l	#6,d3
		add.l	d3,a4
		move.w	#$80,d3
		add.b	(a4),d3
		lsr.w	#2,d3
		cmpi.b	#$FF,2(a2)
		bne.s	BP_736
		move.b	$1D(a3,d7.w),2(a2)
BP_736:		clr.w	d4
		move.b	2(a2),d4

****
		mulu.w	d4,d3
		lsr.w	#6,d3
		move.w	d3,8(a1)
	mulu	volume(pc),d3
	lsr	#6,d3
	move	d3,8(a1)
	
		bra.s	BP_75A

BP_746:	
*****
;		move.b	2(a2),9(a1)
	move.l	d0,-(sp)
	moveq	#0,d0
	move.b	2(a2),d0
	mulu	volume(pc),d0
	lsr	#6,d0
	move	d0,8(a1)
	move.l	(sp)+,d0

		cmpi.b	#$FF,2(a2)
		bne.s	BP_75A
*****
;		move.b	$1D(a3,d7.w),9(a1)
	move.l	d0,-(sp)
	moveq	#0,d0
	move.b	$1d(a3,d7),d0
	mulu	volume(pc),d0
	lsr	#6,d0
	move	d0,8(a1)
	move.l	(sp)+,d0


BP_75A:		tst.b	$1D(a2)
		bne.s	BP_76E
		tst.b	$20(a2)
		bne.s	BP_76E
		tst.b	$23(a2)
		beq.w	BP_684
BP_76E:		move.l	4(a2),a4
		move.l	a4,(a5)
		movem.l	(a4),d2-d5
		movem.l	d2-d5,4(a5)
		movem.l	$10(a4),d2-d5
		movem.l	d2-d5,$14(a5)
		bra.w	BP_684

BP_78E:		lea	PeriodeTable,a4
		ext.w	d4
		asl.w	#1,d4
		move.w	-2(a4,d4.w),6(a1)
		move.w	-2(a4,d4.w),(a0)
		rts

BP_7A2:		moveq	#3,d0
		lea	BP_A7C,a2
		lea	BP_B32-BP_A7C(a2),a5
		lea	$DFF0A0,a1
		move.l	BP_Data(pc),a3
BP_7B6:		tst.b	$1B(a2)
		beq.s	BP_7BE
		bsr.s	BP_7D0
BP_7BE:		lea	$24(a5),a5
		lea	$24(a2),a2
		lea	$10(a1),a1
		dbra	d0,BP_7B6
		rts

BP_7D0:		clr.w	d7
		move.b	3(a2),d7
		lsl.w	#5,d7
		tst.b	$1F(a2)
		beq.s	BP_832
		subq.b	#1,$18(a2)
		bne.s	BP_832
		moveq	#0,d3
		move.b	8(a3,d7.w),$18(a2)
		move.l	BP_B2E,a4
		move.b	5(a3,d7.w),d3
		lsl.l	#6,d3
		add.l	d3,a4
		move.w	$12(a2),d3
		move.w	#$80,d4
		add.b	(a4,d3.w),d4
		lsr.w	#2,d4
		clr.w	d3
		move.b	2(a2),d3
		mulu.w	d3,d4
		lsr.w	#6,d4
;		move.w	d4,8(a1)
*****
	mulu	volume(pc),d4
	lsr	#6,d4
	move	d4,8(a1)


		addq.w	#1,$12(a2)
		move.w	6(a3,d7.w),d4
		cmp.w	$12(a2),d4
		bne.s	BP_832
		clr.w	$12(a2)
		cmpi.b	#1,$1F(a2)
		bne.s	BP_832
		clr.b	$1F(a2)
BP_832:		tst.b	$1E(a2)
		beq.s	BP_890
		subq.b	#1,$17(a2)
		bne.s	BP_890
		moveq	#0,d3
		move.b	15(a3,d7.w),$17(a2)
		move.l	BP_B2E,a4
		move.b	10(a3,d7.w),d3
		lsl.l	#6,d3
		add.l	d3,a4
		move.w	$10(a2),d3
		move.b	(a4,d3.w),d4
		ext.w	d4
		ext.l	d4
		moveq	#0,d5
		move.b	11(a3,d7.w),d5
		tst.b	d5
		beq.s	BP_86A
		divs.w	d5,d4
BP_86A:		move.w	(a2),d5
		add.w	d4,d5
		move.w	d5,6(a1)
		addq.w	#1,$10(a2)
		move.w	12(a3,d7.w),d3
		cmp.w	$10(a2),d3
		bne.s	BP_890
		clr.w	$10(a2)
		cmpi.b	#1,$1E(a2)
		bne.s	BP_890
		clr.b	$1E(a2)
BP_890:		tst.l	(a5)
		beq.w	BP_A78
		tst.b	$1D(a2)
		beq.w	BP_920
		subq.b	#1,$16(a2)
		bne.s	BP_920
		tst.l	(a5)
		beq.s	BP_920
		moveq	#0,d3
		move.b	$15(a3,d7.w),$16(a2)
		move.l	BP_B2E,a4
		move.b	$11(a3,d7.w),d3
		lsl.l	#6,d3
		add.l	d3,a4
		move.w	14(a2),d3
		moveq	#0,d4
		move.b	(a4,d3.w),d4
		move.l	(a5),a4
		addi.b	#$80,d4
		lsr.l	#3,d4
		moveq	#0,d3
		move.b	$1C(a2),d3
		move.b	d4,$1C(a2)
		add.l	d3,a4
		move.l	a5,a6
		add.l	d3,a6
		addq.l	#4,a6
		cmp.b	d3,d4
		beq.s	BP_902
		bgt.s	BP_8F4
		sub.l	d4,d3
		subq.l	#1,d3
BP_8EA:		move.b	-(a6),d4
		move.b	d4,-(a4)
		dbra	d3,BP_8EA
		bra.s	BP_902

BP_8F4:		sub.l	d3,d4
		subq.l	#1,d4
BP_8F8:		move.b	(a6)+,d3
		neg.b	d3
		move.b	d3,(a4)+
		dbra	d4,BP_8F8
BP_902:		addq.w	#1,14(a2)
		move.w	$12(a3,d7.w),d3
		cmp.w	14(a2),d3
		bne.s	BP_920
		clr.w	14(a2)
		cmpi.b	#1,$1D(a2)
		bne.s	BP_920
		clr.b	$1D(a2)
BP_920:		cmpi.b	#1,$23(a2)
		bne.s	BP_95C
		subq.b	#1,$1A(a2)
		bne.w	BP_9B0
		move.b	$17(a3,d7.w),$1A(a2)
		move.l	(a5),a4
		moveq	#15,d5
		move.b	-1(a4),d3
		ext.w	d3
BP_940:		move.b	1(a4),d4
		ext.w	d4
		add.w	d3,d4
		asr.w	#1,d4
		move.b	d4,(a4)+
		move.b	1(a4),d3
		ext.w	d3
		add.w	d4,d3
		asr.w	#1,d3
		move.b	d3,(a4)+
		dbra	d5,BP_940
BP_95C:		cmpi.b	#2,$23(a2)
		bne.s	BP_986
		move.b	$17(a3,d7.w),d4
		lea	$24(a5),a4
		move.l	(a5),a6
		moveq	#$1F,d5
BP_970:		move.b	-(a4),d3
		cmp.b	(a6)+,d3
		beq.s	BP_982
		bge.s	BP_97E
		sub.b	d4,-1(a6)
		bra.s	BP_982

BP_97E:		add.b	d4,-1(a6)
BP_982:		dbra	d5,BP_970
BP_986:		cmpi.b	#3,$23(a2)
		bne.s	BP_9B0
		move.b	$17(a3,d7.w),d4
		lea	4(a5),a4
		move.l	(a5),a6
		moveq	#$1F,d5
BP_99A:		move.b	(a4)+,d3
		cmp.b	(a6)+,d3
		beq.s	BP_9AC
		bge.s	BP_9A8
		sub.b	d4,-1(a6)
		bra.s	BP_9AC

BP_9A8:		add.b	d4,-1(a6)
BP_9AC:		dbra	d5,BP_99A
BP_9B0:		cmpi.b	#4,$23(a2)
		bne.s	BP_9DC
		move.b	$17(a3,d7.w),d4
		move.l	(a5),a4
		lea	$40(a4),a4
		move.l	(a5),a6
		moveq	#$1F,d5
BP_9C6:		move.b	(a4)+,d3
		cmp.b	(a6)+,d3
		beq.s	BP_9D8
		bge.s	BP_9D4
		sub.b	d4,-1(a6)
		bra.s	BP_9D8

BP_9D4:		add.b	d4,-1(a6)
BP_9D8:		dbra	d5,BP_9C6
BP_9DC:		cmpi.b	#5,$23(a2)
		bne.s	BP_A06
		move.b	$17(a3,d7.w),d4
		lea	4(a5),a4
		move.l	(a5),a6
		moveq	#$1F,d5
BP_9F0:		move.b	(a4)+,d3
		cmp.b	(a6)+,d3
		beq.s	BP_A02
		bge.s	BP_9FE
		sub.b	d4,-1(a6)
		bra.s	BP_A02

BP_9FE:		add.b	d4,-1(a6)
BP_A02:		dbra	d5,BP_9F0
BP_A06:		cmpi.b	#6,$23(a2)
		bne.s	BP_A2C
		subq.b	#1,$1A(a2)
		bne.b	BP_A2C
		clr.b	$23(a2)
		move.b	#1,$1A(a2)
		move.l	(a5),a4
		moveq	#7,d5
BP_A24:		move.l	$40(a4),(a4)+
		dbra	d5,BP_A24
BP_A2C:		tst.b	$20(a2)
		beq.s	BP_A78
		subq.b	#1,$19(a2)
		bne.s	BP_A78
		move.b	$1B(a3,d7.w),$19(a2)
		move.l	BP_B2E,a4
		moveq	#0,d3
		move.b	$1A(a3,d7.w),d3
		lsl.l	#6,d3
		add.l	d3,a4
		move.w	$14(a2),d3
		move.l	(a5),a6
		move.b	(a4,d3.w),$20(a6)
		addq.w	#1,$14(a2)
		move.w	$1E(a3,d7.w),d3
		cmp.w	$14(a2),d3
		bne.s	BP_A78
		clr.w	$14(a2)
		cmpi.b	#1,$20(a2)
		bne.s	BP_A78
		clr.b	$20(a2)
BP_A78:		rts

*----------------------------------------------------------------------------*
BP_Data	dc.l	0

;	SECTION	SoundMonSampleBuffer,Data_f
BP_StartPuffer:
BP_ZeroSample:	dc.l	0
BP_A7C:		dc.l	0,BP_ZeroSample,$10000,0,0,0,0,0,0
		dc.l	0,BP_ZeroSample,$10000,0,0,0,0,0,0
		dc.l	0,BP_ZeroSample,$10000,0,0,0,0,0,0
		dc.l	0,BP_ZeroSample,$10000,0,0,0,0,0,0
currentposition
BP_B0C:		dc.b	0
BP_B0D:		dc.b	0
patcounter
BP_B0E:		dc.b	0

SMON_ST:
BP_B0F:		dc.b	0
SMON_TR:
BP_B10:		dc.b	0
BP_B11:		dc.b	1
BP_B12:		dc.b	6
BP_Counter:	dc.b	1
		dc.b	1
BP_B15:		dc.b	0
BP_B16:		dc.b	0
BP_B17:		dc.b	0
BP_B18:		dc.l	BP_B1C
BP_B1C:		dc.l	$40,$800040,$FFC0,$FF80FFC0
BP_DMACon:	dc.w	0
BP_B2E:		dc.l	0
BP_B32:		dcb.l	$24,0
		dc.w	$1AC0,$1940,$17C0,$1680,$1540,$1400,$12E0,$11E0,$10E0
		dc.w	$FE0,$F00,$E20,$D60,$CA0,$BE0,$B40,$AA0,$A00,$970
		dc.w	$8F0,$870,$7F0,$780,$710,$6B0,$650,$5F0,$5A0,$550
		dc.w	$500,$4B8,$478,$438,$3F8,$3C0,$388
PeriodeTable:	dc.w	$358,$328,$2F8,$2D0,$2A8,$280,$25C,$23C,$21C,$1FC
		dc.w	$1E0,$1C4,$1AC,$194,$17C,$168,$154,$140,$12E,$11E
		dc.w	$10E,$FE,$F0,$E2,$D6,$CA,$BE,$B4,$AA,$A0,$97,$8F,$87
		dc.w	$7F,$78,$71,$6B,$65,$5F,$5A,$55,$50,$4C,$48,$44,$40
		dc.w	$3C,$39
BP_WaveBuffer:	ds.b	60
BP_SizePuffer	= *-BP_StartPuffer
		dc.w	0				;Sicherheit

;	SECTION	SoundMonBSSPuffer,Bss_f
;BP_MerkPuffer:	ds.b	BP_SizePuffer

 ifne testi

	SECTION	SoundMonModule,Data_C
data:		incbin "m:Exo/BP SoundMon 3/Brian Postma/blockbrain.bp3"

 endc
