;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000

TESTI	=	0


	incdir	include:
	INCLUDE	"Exec/Types.i"
	include	mucro.i
	include	misc/eagleplayer.i

 ifne TESTI

	move.l	#dmawait_,d0
	lea	mod,a0
	lea	songend_,a1
	lea	poslen_,a2
	lea	null_,a3
	lea	mastervol,a4
	jsr	init
	bne.b	exit
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

;	jsr	end
exit
	rts

dmawait_
	pushm	d0/d1
	moveq	#12-1,d1
.d	move.b	$dff006,d0
.k	cmp.b	$dff006,d0
	beq.b	.k
	dbf	d1,.d
	popm	d0/d1
	rts

mastervol	dc	64/1
songend_	dc	0
poslen_		dc.l	0

	section	dd,data_c
mod
	incbin	"m:modsanthology/synth/soundmon/BP.Wonderworld"
null_
	dc.l	0
 endc

	section	ddd,code_p

	jmp	init(pc)
play	
	jmp 	SM_PlayModule(pc)
	jmp	SM_Forward(pc)
	jmp	SM_Rewind(pc)



init
;
* a0 = module
* a1 = songend
* a2 = pos/len
* a3 = null sample
* a4 = volume
* d0 = dmawait

	pushm	d1-d7/A1-a6
	lea	SM_DataArea(pc),a6
	move.l	d0,dmawait(a6)
	move.l	a4,volume(a6)
	move.l	a1,songend(a6)
	move.l	a2,poslen(a6)
	move.l	a3,null(a6)
	bsr.w	SM_InitSound
	bsr.b	PatternInit
	popm	d1-d7/A1-a6

	moveq	#0,d0	
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

.optional
	moveq	#15,d2
	and.b 	1(a0),d2
	move.b	2(a0),d3
	rts



;------------------------------------------------------------------------------
;******************************************************************************
;* Sound Monitor 2.0 Player
;******************************************************************************
;------------------------------------------------------------------------------
; Structure
;

	STRUCTURE SoundMonStruct,0
	APTR	SMON_Global
	APTR	SMON_Module
	APTR	SMON_Tables
	UWORD	SMON_DMA
	UWORD	SMON_BPStep
	UBYTE	SMON_NumTables
	UBYTE	SMON_ArpCount
	UBYTE	SMON_BPCount
	UBYTE	SMON_BPDelay
	UBYTE	SMON_ST
	UBYTE	SMON_TR
	UBYTE	SMON_BPPatCount
	UBYTE	SMON_BPRepCount
	STRUCT	SMON_Samples,15*4
	STRUCT	SMON_BPCurrent,14+18+32*3
	STRUCT	SMON_BPBuffer,144

	APTR	songend
	APTR	poslen
	APTR	volume
	APTR	dmawait
	APTR	null

	LABEL	SoundMonStruct_SIZEOF
;------------------------------------------------------------------------------
; InitSound



SM_InitSound	movem.l	d0-d2/a0-a1/a4,-(sp)
	
		lea	SM_DataArea(pc),a4
		move.l	a0,a1

	move	30(a0),2(a2)		* songlen talteen

		move.l	a1,SMON_Module(a4)
		move.l	a5,SMON_Global(a4)

		move.b	#1,SMON_ArpCount(a4)
		move.b	#1,SMON_BPCount(a4)
		move.b	#6,SMON_BPDelay(a4)
		move.b	#1,SMON_BPRepCount(a4)

		clr.w	SMON_DMA(a4)
		clr.w	SMON_BPStep(a4)
		clr.b	SMON_BPPatCount(a4)
		clr.b	SMON_ST(a4)
		clr.b	SMON_TR(a4)

		lea	SMON_BPCurrent(a4),a0
		move.l	null(a4),a1
		clr.l	(a0)+
		move.l	a1,(a0)+
		move.w	#1,(a0)+
		clr.l	(a0)+

		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		clr.w	(a0)+
		clr.w	(a0)+
		clr.w	(a0)+

		moveq	#3-1,d0
.initloop	clr.l	(a0)+
		move.l	a1,(a0)+
		move.w	#1,(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		clr.l	(a0)+
		clr.w	(a0)+
		dbra	d0,.initloop

		lea	SMON_BPBuffer(a4),a0
		moveq	#(144/2)-1,d0
.initloop1	clr.w	(a0)+
		dbra	d0,.initloop1

		lea	SMON_Samples(a4),a0
		move.l	SMON_Module(a4),a1

		clr.b	SMON_NumTables(a4)
		cmp.w	#'V.',26(a1)
		bne.b	bpnotv2
		cmp.b	#'2',28(a1)
		bne.b	bpnotv2
		move.b	29(a1),SMON_NumTables(a4)

bpnotv2		move.l	#512,d0
		move.w	30(a1),d1	;d1 now contains length in steps
		moveq	#1,d2		;1 is highest pattern number
		mulu	#4,d1		;4 voices per step
		subq.w	#1,d1		;correction for DBRA
findhighest	cmp.w	(a1,d0),d2	;Is it higher
		bge.b	nothigher	;No
		move.w	(a1,d0),d2	;Yes, so let D2 be highest
nothigher	addq.l	#4,d0		;Next Voice
		dbra	d1,findhighest	;And search

		move.w	30(a1),d1
		lsl.w	#4,d1		;16 bytes per step
		move.l	#512,d0		;header is 512 bytes
		mulu	#48,d2		;48 bytes per pattern
		add.l	d2,d0
		add.l	d1,d0		;offset for samples
		add.l	SMON_Module(a4),d0
		move.l	d0,SMON_Tables(a4)
		moveq	#0,d1
		move.b	SMON_NumTables(a4),d1	;Number of tables
		lsl.l	#6,d1			;x 64
		add.l	d1,d0

		moveq	#15-1,d1	;15 samples
		lea	32(a1),a1
initloop	move.l	d0,(a0)+
		cmp.b	#$ff,(a1)
		beq.b	bpissynth
		move.w	24(a1),d2
		add.w	d2,d2
		add.l	d2,d0		;offset next sample
bpissynth	lea	32(a1),a1	;Length of Sample Part in header
		dbra	d1,initloop

		movem.l	(sp)+,d0-d2/a0-a1/a4
		rts

;------------------------------------------------------------------------------
; PlayModule
;
; IN :	A1 = Address
;	D1 = VBlank/Cia (0=CIA)
;
; OUT:	Nothing
;

SM_PlayModule	movem.l	d0-d7/a0-a6,-(sp)
		lea	SM_DataArea(pc),a5
		bsr.b	bpmusic

	move.l	poslen(a5),a0		* position talteen
	move	SMON_BPStep(a5),(a0)

		movem.l	(sp)+,d0-d7/a0-a6
		rts

bpmusic		bsr.w	bpsynth
		subq.b	#1,SMON_ArpCount(a5)
		moveq	#3,d0
		lea	SMON_BPCurrent(a5),a0
		lea	$dff0a0,a1
bploop1		move.b	12(a0),d4
		ext.w	d4
		add.w	d4,(a0)
		tst.b	$1e(a0)
		bne.b	bplfo
		move.w	(a0),6(a1)
bplfo		move.l	4(a0),(a1)
		move.w	8(a0),4(a1)
		tst.b	11(a0)
		bne.b	bpdoarp
		tst.b	13(a0)
		beq.b	not2
bpdoarp		tst.b	SMON_ArpCount(a5)
		bne.b	not0
		move.b	11(a0),d3
		move.b	13(a0),d4
		and.w	#240,d4
		and.w	#240,d3
		lsr.w	#4,d3
		lsr.w	#4,d4
		add.w	d3,d4
		add.b	10(a0),d4
		bsr.w	bpplayarp
		bra.b	not2

not0		cmpi.b	#1,SMON_ArpCount(a5)
		bne.b	not1
		move.b	11(a0),d3
		move.b	13(a0),d4
		and.w	#15,d3
		and.w	#15,d4
		add.w	d3,d4
		add.b	10(a0),d4
		bsr.w	bpplayarp
		bra.b	not2

not1		move.b	10(a0),d4
		bsr.w	bpplayarp
not2		lea	$10(a1),a1
		lea	$20(a0),a0
		dbra	d0,bploop1

		tst.b	SMON_ArpCount(a5)
		bne.b	arpnotzero
		move.b	#3,SMON_ArpCount(a5)
arpnotzero	subq.b	#1,SMON_BPCount(a5)
		beq.b	bpskip1
		rts

bpskip1		move.b	SMON_BPDelay(a5),SMON_BPCount(a5)
bpplay		bsr.b	bpnext
		move.w	SMON_DMA(a5),$dff096

;		move.l	SMON_Global(a5),a1
;		move.l	APG_WaitDma(a1),a1
;		jsr	(a1)			;Wait For DMA


	move.l	dmawait(a5),a1
	jsr	(a1)


		moveq	#3,d0
		lea	$dff0a0,a1
		moveq	#1,d1
		move.l	a5,-(sp)
		lea	SMON_BPCurrent(a5),a2
		lea	SMON_BPBuffer(a5),a5
bploop2		btst	#15,(a2)
		beq.b	bpskip7
		bsr.w	bpplayit
bpskip7		asl.w	#1,d1
		lea	$10(a1),a1
		lea	$20(a2),a2
		lea	$24(a5),a5
		dbra	d0,bploop2
		move.l	(sp)+,a5
		rts

bpnext		clr.w	SMON_DMA(a5)
		move.l	SMON_Module(a5),a0
		lea	$dff0a0,a3
		moveq	#3,d0
		moveq	#1,d7
		lea	SMON_BPCurrent(a5),a1
bploop3		moveq	#0,d1
		move.w	SMON_BPStep(a5),d1
		lsl.w	#4,d1
		move.l	d0,d2
		lsl.l	#2,d2
		add.l	d2,d1
		add.l	#512,d1
		move.w	(a0,d1),d2
		move.b	2(a0,d1),SMON_ST(a5)
		move.b	3(a0,d1),SMON_TR(a5)
		subq.w	#1,d2
		mulu	#48,d2
		moveq	#0,d3
		move.w	30(a0),d3	* song length
		lsl.w	#4,d3
		add.l	d2,d3
		* skip over something to access pattern

		;move.l	#$00000200,d4
		;move.b	SMON_BPPatCount(a5),d4
		;add.l	d3,d4
		;move.l	d4,a2
		* offset to module start
		;add.l	a0,a2
		
		lea	$200(a0),a2
		add.l	d3,a2

		cmp.b	#1,d7
		bne.b 	.a 
		move.l	a2,Stripe1
		bra.b	.d
.a
		cmp.b	#2,d7
		bne.b 	.b 
		move.l	a2,Stripe2
		bra.b	.d
.b
		cmp.b	#4,d7
		bne.b 	.c 
		move.l	a2,Stripe3
		bra.b	.d
.c
		cmp.b	#8,d7
		bne.b 	.d 
		move.l	a2,Stripe4
.d
		moveq	#0,d4
		move.b	SMON_BPPatCount(a5),d4
		add.l	d4,a2

		* a2 points to current pattern data, modulo 3
		
		moveq	#0,d3 
		move.b	(a2),d3
		tst.b	d3
		bne.b	bpskip4
		bra.w	bpoptionals

bpskip4		clr.w	12(a1)			;Clear autoslide/autoarpeggio
		move.b	1(a2),d4
		and.b	#15,d4
		cmpi.b	#10,d4    		;Option 10->transposes off
		bne.b	bp_do1
		move.b	2(a2),d4
		and.b	#240,d4	  		;Higher nibble=transpose
		bne.b	bp_not1
bp_do1		add.b	SMON_TR(a5),d3
		ext.w	d3
bp_not1		move.b	d3,10(a1) 		;Voor Arpeggio's
		lea	bpper(pc),a4
		lsl.w	#1,d3
		move.w	-2(a4,d3.w),(a1)
		bset	#15,(a1)
		move.b	#$ff,2(a1)
		moveq	#0,d3
		move.b	1(a2),d3
		lsr.b	#4,d3
		and.b	#15,d3
		tst.b	d3
		bne.b	bpskip5
		move.b	3(a1),d3 
bpskip5 	move.b	1(a2),d4
		and.b	#15,d4
		cmpi.b	#10,d4 			;option 10
		bne.b	bp_do2
		move.b	2(a2),d4
		and.b	#15,d4
		bne.b	bp_not2
bp_do2		add.b	SMON_ST(a5),d3
bp_not2		cmpi.w	#1,8(a1)
		beq.b	bpsamplechange
		cmp.b	3(a1),d3
		beq.b	bpoptionals
bpsamplechange	move.b	d3,3(a1)
		or.w	d7,SMON_DMA(a5)
bpoptionals 	moveq	#0,d3
		moveq	#0,d4
		move.b	1(a2),d3	* Command
		and.b	#15,d3
		move.b	2(a2),d4	* Parameter

		cmpi.b	#0,d3			; Optionals Here
		bne.b	notopt0
		move.b	d4,11(a1)

notopt0		cmpi.b	#1,d3
		bne.b	bpskip3
		move.l	d0,-(sp)
		move.b	d4,2(a1) 		; Volume ook in BPCurrent
		move.b	d4,d0
		bsr.w	calvol
		move.w	d0,8(a3)
		move.l	(sp)+,d0

bpskip3		cmpi.b	#2,d3  			; Set Speed
		bne.b	bpskip9
		move.b	d4,SMON_BPCount(a5)
		move.b	d4,SMON_BPDelay(a5)

bpskip9		cmpi.b	#3,d3 			; Filter = LED control
		bne.b	bpskipa
		tst.b	d4
		bne.b	bpskipb
		bset	#1,$bfe001
		bra.b	bpskip2
bpskipb		bclr	#1,$bfe001

bpskipa		cmpi.b	#4,d3 			; PortUp
		bne.b	noportup
		sub.w	d4,(a1)			; Slide data in BPCurrent
		clr.b	11(a1) 			; Arpeggio's uit

noportup	cmpi.b	#5,d3 			; PortDown
		bne.b	noportdn
		add.w	d4,(a1)			; Slide down
		clr.b	11(a1)

noportdn	cmpi.b	#6,d3			; SetRepCount
		bne.b	notopt6
		move.b	d4,SMON_BPRepCount(a5)

notopt6		cmpi.b	#7,d3			; DBRA repcount
		bne.b	notopt7
		subq.b	#1,SMON_BPRepCount(a5)
		beq.b	notopt7
		move.w	d4,SMON_BPStep(a5)

notopt7		cmpi.b	#8,d3			;Set AutoSlide
		bne.b	notopt8
		move.b	d4,12(a1)

notopt8		cmpi.b	#9,d3			;Set AutoArpeggio
		bne.b	notopt9
		move.b	d4,13(a1)

notopt9
bpskip2		lea	$10(a3),a3
		lea	$20(a1),a1
		asl.w	#1,d7
		dbra	d0,bploop3

	* Pattern position
		addq	#1,PI_Pattpos+PatternInfo
		addq.b	#3,SMON_BPPatCount(a5)
		cmpi.b	#48,SMON_BPPatCount(a5)
		bne.b	bpskip8
		clr	PI_Pattpos+PatternInfo
		move.b	#0,SMON_BPPatCount(a5)
		* Increase song position
		addq.w	#1,SMON_BPStep(a5)

	;	move.l	SMON_Global(a5),a2
	;	move.l	APG_SendMsg(a2),a2
	;	move.w	#MSG_NextPos,d2
	;	jsr	(a2)

		move.l	SMON_Module(a5),a0
		move.w	30(a0),d1
		cmp.w	SMON_BPStep(a5),d1
		bne.b	bpskip8
		move.w	#0,SMON_BPStep(a5)

	;	move.l	SMON_Global(a5),a2
	;	move.l	APG_SendMsg(a2),a2
	;	move.w	#MSG_NextMod,d2
	;	jsr	(a2)

	move.l	songend(a5),a2		* kappale loppui!
	st	(a2)

bpskip8		rts

bpplayit	bclr	#15,(a2)
		tst.l	(a5) 			;Was EG used
		beq.b	noeg1 			;No ??
		moveq	#0,d3 			;Well then copy
		move.l	(a5),a4			;Old waveform back
		moveq	#7,d7 			;to waveform tables
eg1loop		move.l	4(a5,d3.w),(a4)+	;Copy...
		addq.w	#4,d3 			;Copy...
		dbra	d7,eg1loop		;Copy...

noeg1		move.w	(a2),6(a1)		;Period from bpcurrent
		moveq	#0,d7
		move.b	3(a2),d7		;Instrument number
		move.l	d7,d6 			;Also in d6
		lsl.l	#5,d7 			;Header offset
		move.l	4(sp),a3
		move.l	SMON_Module(a3),a3
		cmpi.b	#$ff,(a3,d7.w)		;Is synthetic
		beq.w	bpplaysynthetic		;Yes ??
		clr.l	(a5) 			;EG Off
		clr.b	$1a(a2)			;Synthetic mode off
		clr.w	$1e(a2)			;Lfo Off
		add.l	#24,d7 			;24 is name->ignore
		lsl.l	#2,d6 			;x4 for sample offset
		move.l	4(sp),a4
		lea	SMON_Samples(a4),a4
		move.l	-4(a4,d6),d4		;Fetch sample pointer
		beq.b	bp_nosamp		;is zero->no sample
		move.l	d4,(a1) 		;Sample pointer in hardware
		move.w	(a3,d7),4(a1)		;length in hardware

		movem.l	d0/a5,-(sp)
		move.l	12(sp),a5
		move.b	2(a2),d0
		bsr.w	calvol
		movem.l	(sp)+,d0/a5

		cmpi.b	#$ff,2(a2)		;Use default volume
		bne.b	skipxx 			;No ??

		movem.l	d0/a5,-(sp)
		move.l	12(sp),a5
		move.w	6(a3,d7),d0
		bsr.w	calvol
		move.w	d0,8(a1)
		movem.l	(sp)+,d0/a5

skipxx	 	move.w	4(a3,d7),8(a2)		;Length in bpcurrent
		moveq	#0,d6
		move.w	2(a3,d7),d6		;Calculate repeat
		add.l	d6,d4
		move.l	d4,4(a2)		;sample start in bpcurrent
		cmpi.w	#1,8(a2)		;has sample repeat part
		bne.b	bpskip6			;Yes ??
bp_nosamp	move.l	SM_DataArea+null(pc),4(a2)	;Play no sample
		bra.b	bpskip10

bpskip6		move.w	8(a2),4(a1)		;Length to hardware
		move.l	4(a2),(a1)		;pointer to hardware
bpskip10	or.w	#$8000,d1		;Turn on DMA for this voice
		move.w	d1,$dff096		;Yeah, do it
		rts

bpplaysynthetic	move.b	#$1,$1a(a2)		;Synthetic mode on
		clr.w	$e(a2) 			;EG Pointer restart
		clr.w	$10(a2) 		;LFO Pointer restart
		clr.w	$12(a2) 		;ADSR Pointer restart
		move.w	22(a3,d7.w),$14(a2)	;EG Delay
		addq.w	#1,$14(a2)		;0 is nodelay
		move.w	14(a3,d7.w),$16(a2)	;LFO Delay
		addq.w	#1,$16(a2)		;So I need correction
		move.w	#1,$18(a2)		;ADSR Delay->Start immediate
		move.b	17(a3,d7.w),$1d(a2)	;EG OOC
		move.b	9(a3,d7.w),$1e(a2)	;LFO OOC
		move.b	4(a3,d7.w),$1f(a2)	;ADSR OOC
		move.b	19(a3,d7.w),$1c(a2)	;Current EG Value
		move.l	4(sp),a4
		move.l	SMON_Tables(a4),a4	; so far so good,now what ??
		moveq	#0,d3			;Pointer to waveform tables
		move.b	1(a3,d7.w),d3		;Which waveform
		lsl.l	#6,d3 			;x64 is length waveform table
		add.l	d3,a4
		move.l	a4,(a1) 		;Sample Pointer
		move.l	a4,4(a2)		;In bpcurrent
		move.w	2(a3,d7.w),4(a1)	;Length in words
		move.w	2(a3,d7.w),8(a2)	;Length in bpcurrent
		tst.b	4(a3,d7.w)		;Is ADSR on
		beq.b	bpadsroff		;No ??
		move.l	4(sp),a4
		move.l	SMON_Tables(a4),a4	;Tables
		moveq	#0,d3
		move.b	5(a3,d7.w),d3		;ADSR table number
		lsl.l	#6,d3 			;x64 for length
		add.l	d3,a4 			;Add it
		moveq	#0,d3
		move.b	(a4),d3 		;Get table value
		add.b	#128,d3 		;I want it from 0..255
		lsr.w	#2,d3 			;Divide by 4->0..63
		cmpi.b	#$ff,2(a2)
		bne.b	bpskip99
		move.b	25(a3,d7.w),2(a2)
bpskip99	moveq	#0,d4
		move.b	2(a2),d4		;Default volume
		mulu	d4,d3 			;default maal init volume
		lsr.w	#6,d3 			;divide by 64

		movem.l	d0/a5,-(sp)
		move.l	12(sp),a5
		move.w	d3,d0
		bsr.w	calvol
		move.w	d0,8(a1)		;is new volume
		movem.l	(sp)+,d0/a5
		bra.b	bpflipper

bpadsroff	movem.l	d0/a5,-(sp)
		move.l	12(sp),a5
		move.b	2(a2),d0
		bsr.w	calvol
		move.w	d0,8(a1)		;is new volume
		movem.l	(sp)+,d0/a5

		cmpi.b	#$ff,2(a2)
		bne.b	bpflipper		;No ADSR
		movem.l	d0/a5,-(sp)
		move.l	12(sp),a5
		move.b	25(a3,d7.w),d0
		bsr.w	calvol
		move.w	d0,8(a1)		;So use default volume
		movem.l	(sp)+,d0/a5

bpflipper	move.l	4(a2),a4		;Pointer on waveform
		move.l	a4,(a5)			;Save it
		moveq	#0,d3 			;Save Old waveform
		moveq	#7,d4 			;data in bpbuffer
eg2loop		move.l	(a4,d3.w),4(a5,d3.w)
		addq.w	#4,d3 			;Copy 		
		dbra	d4,eg2loop

		tst.b	17(a3,d7.w)		;EG off
		beq.w	bpskip10		;Yes ??
		tst.b	19(a3,d7.w)		;Is there an init value for EG
		beq.w	bpskip10		;No ??
		moveq	#0,d3
		move.b	19(a3,d7.w),d3
		lsr.l	#3,d3 			;Divide by 8 ->0..31
		move.b	d3,$1c(a2)		;Current EG Value
		subq.l	#1,d3 			;-1,DBRA correction
eg3loop		neg.b	(a4)+
		dbra	d3,eg3loop
		bra.w	bpskip10

bpplayarp	lea	bpper(pc),a4
		ext.w	d4
		asl.w	#1,d4
		move.w	-2(a4,d4.w),6(a1)
		rts

bpsynth		move.l	a5,-(sp)
		moveq	#3,d0
		lea	SMON_BPCurrent(a5),a2
		lea	$dff0a0,a1
		move.l	SMON_Module(a5),a3
		lea	SMON_BPBuffer(a5),a5
bpsynthloop	tst.b	$1a(a2)			;Is synthetic sound
		beq.b	bpnosynth		;No ??
		bsr.b	bpyessynth		;Yes 		
bpnosynth	lea	$24(a5),a5
		lea	$20(a2),a2
		lea	$10(a1),a1
		dbra	d0,bpsynthloop
		move.l	(sp)+,a5
		rts

bpyessynth	moveq	#0,d7
		move.b	3(a2),d7		;Which instr. was I playing
		lsl.w	#5,d7 			;x32, is length of instr.
		tst.b	$1f(a2) 		;ADSR off
		beq.b	bpendadsr		;Yes ??
		subq.w	#1,$18(a2)		;Delay,May I
		bne.b	bpendadsr		;No ??
		moveq	#0,d3
		move.b	8(a3,d7.w),d3
		move.w	d3,$18(a2)		;Reset Delay Counter
		move.l	4(sp),a4
		move.l	SMON_Tables(a4),a4
		move.b	5(a3,d7.w),d3		;Which ADSR table
		lsl.l	#6,d3 			;x64
		add.l	d3,a4 			;This is my table
		move.w	$12(a2),d3		;Get ADSR table pointer
		moveq	#0,d4
		move.b	(a4,d3.w),d4		;Value from table
		add.b	#128,d4 		;Want it from 0..255
		lsr.w	#2,d4 			;And now from 0..63
		moveq	#0,d3
		move.b	2(a2),d3		;Current Volume
		mulu	d3,d4 			;MultiPly with table volume
		lsr.w	#6,d4 			;Divide by 64=New volume

		movem.l	d0/a5,-(sp)
		move.l	12(sp),a5
		move.w	d4,d0
		bsr.w	calvol
		move.w	d0,8(a1)		;Volume in hardware
		movem.l	(sp)+,d0/a5

		addq.w	#1,$12(a2)		;Increment of ADSR pointer
		move.w	6(a3,d7.w),d4		;Length of adsr table
		cmp.w	$12(a2),d4		;End of table reached
		bne.b	bpendadsr		;No ??
		clr.w	$12(a2) 		;Clear ADSR Pointer
		cmpi.b	#1,$1f(a2)		;Once
		bne.b	bpendadsr		;No ??
		clr.b	$1f(a2)			;ADSR off
bpendadsr	tst.b	$1e(a2)			;LFO On
		beq.b	bpendlfo		;No ??
		subq.w	#1,$16(a2)		;LFO delay,May I
		bne.b	bpendlfo		;No
		moveq	#0,d3
		move.b	16(a3,d7.w),d3
		move.w	d3,$16(a2)		;Set LFO Count
		move.l	4(sp),a4
		move.l	SMON_Tables(a4),a4
		move.b	10(a3,d7.w),d3		;Which LFO table
		lsl.l	#6,d3 			;x64
		add.l	d3,a4
		move.w	$10(a2),d3		;LFO pointer
		moveq	#0,d4
		move.b	(a4,d3.w),d4		;That's my value
		ext.w	d4 			;Make it a word
		ext.l	d4 			;And a longword
		moveq	#0,d5
		move.b	11(a3,d7.w),d5		;LFO depth
		tst.b	d5
		beq.b	bpnotx
		divs	d5,d4 			;Calculate it
bpnotx		move.w	(a2),d5 		;Period
		add.w	d4,d5 			;New Period
		move.w	d5,6(a1)		;In hardware
		addq.w	#1,$10(a2)		;Next position
		move.w	12(a3,d7.w),d3		;LFO table Length
		cmp.w	$10(a2),d3		;End Reached
		bne.b	bpendlfo		;NO ??
		clr.w	$10(a2)		 	;Reset LFO Pointer
		cmpi.b	#1,$1e(a2)		;Once LFO
		bne.b	bpendlfo		;NO ??
		clr.b	$1e(a2) 		;LFO Off
bpendlfo	tst.b	$1d(a2) 		;EG On
		beq.w	bpendeg			;No ??
		subq.w	#1,$14(a2)		;EG delay,May I
		bne.w	bpendeg 		;No
		tst.l	(a5)
		beq.b	bpendeg
		moveq	#0,d3
		move.b	24(a3,d7.w),d3
		move.w	d3,$14(a2)		;Set EG Count
		move.l	4(sp),a4
		move.l	SMON_Tables(a4),a4
		move.b	18(a3,d7.w),d3		;Which EG table
		lsl.l	#6,d3 			;x64
		add.l	d3,a4
		move.w	$e(a2),d3		;EG pointer
		moveq	#0,d4
		move.b	(a4,d3.w),d4		;That's my value
		move.l	(a5),a4 		;Pointer to waveform
		add.b	#128,d4 		;0..255
		lsr.l	#3,d4 			;0..31
		moveq	#0,d3
		move.b	$1c(a2),d3		;Old EG Value
		move.b	d4,$1c(a2)
		add.l	d3,a4 			;WaveForm Position
		move.l	a5,a6 			;Buffer
		add.l	d3,a6 			;Position
		addq.l	#4,a6 			;For adress in buffer
		cmp.b	d3,d4 			;Compare old with new value
		beq.b	bpnexteg		;no change ??
		bgt.b	bpishigh		;new value is higher
bpislow		sub.l	d4,d3 			;oldvalue-newvalue
		subq.l	#1,d3 			;Correction for DBRA
bpegloop1a	move.b	-(a6),d4
		move.b	d4,-(a4)
		dbra	d3,bpegloop1a
		bra.b	bpnexteg

bpishigh	sub.l	d3,d4 			;Newvalue-oldvalue
		subq.l	#1,d4 			;Correction for DBRA
bpegloop1b	move.b	(a6)+,d3
		neg.b	d3
		move.b	d3,(a4)+		;DoIt
		dbra	d4,bpegloop1b

bpnexteg	addq.w	#1,$e(a2)		;Next position
		move.w	20(a3,d7.w),d3		;EG table Length
		cmp.w	$e(a2),d3		;End Reached
		bne.b	bpendeg			;NO ??
		clr.w	$e(a2) 			;Reset EG Pointer
		cmpi.b	#1,$1d(a2)		;Once EG
		bne.b	bpendeg 		;NO ??
		clr.b	$1d(a2) 		;EG Off
bpendeg		rts
;------------------------------------------------------------------------------
; Calculate New Volume
;
; IN :	D0 = Volume
;	A5 = SMON Structure
;
; OUT:	D0 = New Volume
;

calvol
	move.l	a0,-(sp)
	move.l	volume+SM_DataArea(pc),a0
	mulu	(a0),d0
	lsr	#6,d0
	move.l	(sp)+,a0
	rts

;------------------------------------------------------------------------------
	dc.w 6848,6464,6080,5760,5440,5120,4832,4576,4320,4064,3840,3616
	dc.w 3424,3232,3040,2880,2720,2560,2416,2288,2160,2032,1920,1808
	dc.w 1712,1616,1520,1440,1360,1280,1208,1144,1080,1016,0960,0904
bpper	dc.w 0856,0808,0760,0720,0680,0640,0604,0572,0540,0508,0480,0452
	dc.w 0428,0404,0380,0360,0340,0320,0302,0286,0270,0254,0240,0226
	dc.w 0214,0202,0190,0180,0170,0160,0151,0143,0135,0127,0120,0113
	dc.w 0107,0101,0095,0090,0085,0080,0076,0072,0068,0064,0060,0057



;------------------------------------------------------------------------------
; Rewind
;
; IN :	A1 = Address
;
; OUT:	D1 = New Position
;

SM_Rewind
	movem.l	a0-a1,-(sp)
	lea	SM_DataArea(pc),a0
	move.l	SMON_Module(a0),a1

	move.w	SMON_BPStep(a0),d1
	beq.b	sforwa1
	subq.w	#1,d1
	bra.b	sforwa1
;------------------------------------------------------------------------------
; Forward
;
; IN :	A1 = Address
;
; OUT:	D1 = New Position
;

SM_Forward
	movem.l	a0-a1,-(sp)
	lea	SM_DataArea(pc),a0
	move.l	SMON_Module(a0),a1

	move.w	SMON_BPStep(a0),d1
	addq.w	#1,d1
	cmp.w	30(a1),d1
	blo.b	sforwa1
	moveq	#0,d1

sforwa1	move.w	d1,SMON_BPStep(a0)
	clr.b	SMON_BPPatCount(a0)

	movem.l	(sp)+,a0-a1
	rts


SM_DataArea
	ds.b	SoundMonStruct_SIZEOF


end
