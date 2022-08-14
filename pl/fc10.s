;APS00000022000000220000002200000022000000220000002200000022000000220000002200000022
	incdir	include:
	Include	mucro.i
	include	misc/eagleplayer.i
	incdir	include/
	include	patternInfo.i


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

testi	=	0

 ifne testi


	lea 	mod,a0
	lea	mainVol_(pc),a1
	lea	songend_(pc),a2
	lea	scope_(pc),a3
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

	jsr	end
	move	#$f,$dff096
	rts

songend_	dc 	0
mainVol_ 	dc 	$40/1
scope_		ds.b scope_size

	section	cc,data_c
;mod	incbin	"sys:music/modsanthology/synth/fc13/fc13.sting"
mod	incbin	"M:exo/future composer 1.3/jesper kyd/cytax-ice02-intro.smod"
 endc




	jmp init(pc)
	jmp play(pc)
	jmp end(pc)

moduleAddr	dc.l 	0
mainVolumeAddr	dc.l	0
mainVolume	dc 	$40
songOverAddr	dc.l 	0
scope	dc.l	0


init
	move.l	a0,moduleAddr
	move.l	a1,mainVolumeAddr 
	move.l	a2,songOverAddr
	move.l	a3,scope

	bsr.w	fc10init
	bsr.b	PatternInit
	moveq	#0,d0
	rts


play

	move.l	mainVolumeAddr(pc),a0 
	move	(a0),mainVolume
	bsr.w	fc10music

	* current position
	moveq	#0,d0
	move	V1data+6(pc),d0
	divu	#$d,d0

	move.l	V1data+52(pc),d1
	sub.l	V1data(pc),d1
	divu	#$d,d1
end

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
	moveq	#2,D0
	move.l	D0,PI_Modulo(A0)	; Number of bytes to next row
	move.w	#32,PI_Pattlength(A0)	; Length of each stripe in rows
	clr.w	PI_Pattpos(A0)		; Current Position in Pattern (from 0)
	move	#-1,PI_Speed(a0)	; Magic! Indicates notes, not periods
	rts

* Called by the PI engine to get values for a particular row
ConvertNote
	moveq	#0,D0		; Period, Note
	moveq	#0,D1		; Sample number
	moveq	#0,D2		; Command 
	moveq	#0,D3		; Command argument

	* Pattern end, turn into Protracker D-command
	cmp.b	#$49,(a0)
	bne.b 	.notEnd 
	moveq	#$d,d2
	rts
.notEnd
	* note, transpose missing
	moveq	#$7f,d0
	and.b	(a0),d0
	* zero for no note
	beq.b	.noNote

	lea	PI_NoteTranspose1(a1),a3
	add	PI_CurrentChannelNumber(a1),a3
	add.b	(a3),d0
	lea	PERIOD_INDEXES(pc),a3
	move.b	0(a3,d0.w),d0

	* instrument number, would need sound transpose too
	moveq	#$3f,d1
	and.b	1(a0),d1

	* Sample transpose
	lea	PI_SampleTranspose1(a1),a3
	add	PI_CurrentChannelNumber(a1),a3
	add.b	(a3),d1

	* Convert sample 0 into sample 1, so it will also
	* be printed as number.
	addq.b	#1,d1
.noNote

	move	#%11000000,d2
	and.b	1(a0),d2
	beq.b	.noPort
	* Portamento command
			;Bit 7 = portamento on
			;Bit 6 = portamento off
	* Portamento value
			;Bit 7-5 = always zero
			;Bit 4 = up/down
			;Bit 3-0 = value
	btst	#7,d2
	beq.b	.noPortVal
	move.b	3(a0),d3
.noPortVal
	lsr	#6,d2

.noPort


	rts


***************************************************************
**  Amiga FUTURE COMPOSER V1.0 / 1.2 / 1.3   Replay routine  **
***************************************************************


fc10init
;INIT_MUSIC:
* a0 = moduleaddress
	move.w #1,onoff

	bset	#1,$bfe001
	lea 100(a0),a1
	move.l a1,SEQpoint
	move.l a0,a1
	add.l 8(a0),a1
	move.l a1,PATpoint
	move.l a0,a1
	add.l 16(a0),a1
	move.l a1,FRQpoint
	move.l a0,a1
	add.l 24(a0),a1
	move.l a1,VOLpoint
	move.l 4(a0),d0
	divu #13,d0

	lea 40(a0),a1
	lea SOUNDINFO+4(pc),a2
	moveq #10-1,d1
initloop:
	move.w (a1)+,(a2)+
	move.l (a1)+,(a2)+
	addq.w #4,a2
	dbf d1,initloop
	moveq #0,d2
	move.l a0,d1
	add.l 32(a0),d1
	sub.l #WAVEFORMS,d1
	lea SOUNDINFO(pc),a0
	move.l d1,(a0)+
	moveq #9-1,d3
initloop1:
	move.w (a0),d2
	add.l d2,d1
	add.l d2,d1
	addq.w #6,a0
	move.l d1,(a0)+
	dbf d3,initloop1

	move.l SEQpoint(pc),a0
	moveq #0,d2
	move.b 12(a0),d2		;Get replay speed
	bne.s speedok
	move.b #3,d2			;Set default speed
speedok:
	move.w d2,respcnt		;Init repspeed counter
	move.w d2,repspd
INIT2:
	clr.w audtemp
	clr.w spdtemp
	move.w #$000f,$dff096		;Disable audio DMA
;	move.w #$0780,$dff09a		;Disable audio IRQ
	moveq #0,d7
	mulu #13,d0
	moveq #4-1,d6			;Number of soundchannels-1
	lea V1data(pc),a0		;Point to 1st voice data area
	lea SILENT(pc),a1
	lea o4a0c8(pc),a2
initloop2:
	move.l a1,10(a0)
	move.l a1,18(a0)
	clr.l 14(a0)
	clr.b 45(a0)
	clr.b 47(a0)
	clr.w 8(a0)
	clr.l 48(a0)
	move.b #$01,23(a0)
	move.b #$01,24(a0)
	clr.b 25(a0)
	clr.l 26(a0)
	clr.w 30(a0)
	moveq #$00,d3
	move.w (a2)+,d1
	move.w (a2)+,d3
	divu #$0003,d3
	move.b d3,32(a0)
	mulu #$0003,d3
	andi.l #$00ff,d3
	andi.l #$00ff,d1
	addi.l #$dff0a0,d1
	move.l d1,a6
	move.l #$0000,(a6)
	move.w #$0100,4(a6)
	move.w #$0000,6(a6)
	move.w #$0000,8(a6)
	move.l d1,60(a0)
	clr.w 64(a0)
	move.l SEQpoint(pc),(a0)
	move.l SEQpoint(pc),52(a0)
	add.l d0,52(a0)
	add.l d3,52(a0)
	add.l d7,(a0)
	add.l d3,(a0)
	move.w #$000d,6(a0)
	move.l (a0),a3
	move.b (a3),d1
	andi.l #$00ff,d1
	lsl.w #6,d1
	move.l PATpoint(pc),a4
	adda.w d1,a4
	move.l a4,34(a0)
	clr.l 38(a0)
	move.b #$01,33(a0)
	move.b #$02,42(a0)
	move.b 1(a3),44(a0)
	move.b 2(a3),22(a0)
	clr.b 43(a0)
	clr.b 45(a0)
	clr.w 56(a0)
	adda.w #$004a,a0	;Point to next voice's data area
	dbf d6,initloop2
	rts


fc10music
;PLAY:
	lea pervol(pc),a6
	tst.w onoff
	bne.s music_on
	rts
music_on:
	subq.w #1,respcnt		;Decrease replayspeed counter
	bne.s nonewnote
	move.w repspd(pc),respcnt	;Restore replayspeed counter

	lea 	V1data(pc),a0		;Point to voice1 data area
	lea	Stripe1(pc),a2
	bsr.w 	new_note
	move.b	44(a0),PatternInfo+PI_NoteTranspose1
	move.b	22(a0),PatternInfo+PI_SampleTranspose1
	
	lea 	V2data(pc),a0		;Point to voice2 data area
	lea	Stripe2(pc),a2
	bsr.w 	new_note
	move.b	44(a0),PatternInfo+PI_NoteTranspose2
	move.b	22(a0),PatternInfo+PI_SampleTranspose2
	
	lea 	V3data(pc),a0		;Point to voice3 data area
	lea	Stripe3(pc),a2
	bsr.w 	new_note
	move.b	44(a0),PatternInfo+PI_NoteTranspose3
	move.b	22(a0),PatternInfo+PI_SampleTranspose3
	
	lea 	V4data(pc),a0		;Point to voice4 data area
	lea	Stripe4(pc),a2
	bsr.w 	new_note
	move.b	44(a0),PatternInfo+PI_NoteTranspose4
	move.b	22(a0),PatternInfo+PI_SampleTranspose4
	
nonewnote:
	clr.w audtemp
	lea V1data(pc),a0
	bsr.w effects
	move.w d0,(a6)+ * per
	move.w d1,(a6)+ * vol
	lea V2data(pc),a0
	bsr.w effects
	move.w d0,(a6)+
	move.w d1,(a6)+
	lea V3data(pc),a0
	bsr.w effects
	move.w d0,(a6)+
	move.w d1,(a6)+
	lea V4data(pc),a0
	bsr.w effects
	move.w d0,(a6)+
	move.w d1,(a6)+
	
	lea pervol(pc),a6
	move.w audtemp(pc),d0
	ori.w #$8000,d0			;Set/clr bit = 1

	move.w d0,-(a7)
	moveq #0,d1
	move.l start1(pc),d2		;Get samplepointers
	move.w offset1(pc),d1		;Get offset
	add.l d1,d2			;Add offset
	move.l start2(pc),d3
	move.w offset2(pc),d1
	add.l d1,d3
	move.l start3(pc),d4
	move.w offset3(pc),d1
	add.l d1,d4
	move.l start4(pc),d5
	move.w offset4(pc),d1
	add.l d1,d5
	move.w ssize1(pc),d0		;Get sound lengths
	move.w ssize2(pc),d1
	move.w ssize3(pc),d6
	move.w ssize4(pc),d7
	move.w (a7)+,$dff096		;Enable audio DMA

chan1:
	lea V1data(pc),a0
	tst.w 72(a0)
	beq.s chan2
	subq.w #1,72(a0)
	cmpi.w #1,72(a0)
	bne.s chan2
	clr.w 72(a0)
	move.l d2,$dff0a0		;Set soundstart
	move.w d0,$dff0a4		;Set soundlength

	move.l	scope(pc),a0
	move.l	d2,scope_ch1+ns_loopstart(a0)
	move	d0,scope_ch1+ns_replen(a0)
chan2:
	lea V2data(pc),a0
	tst.w 72(a0)
	beq.s chan3
	subq.w #1,72(a0)
	cmpi.w #1,72(a0)
	bne.s chan3
	clr.w 72(a0)
	move.l d3,$dff0b0
	move.w d1,$dff0b4

	move.l	scope(pc),a0
	move.l	d3,scope_ch2+ns_loopstart(a0)
	move	d1,scope_ch2+ns_replen(a0)
chan3:
	lea V3data(pc),a0
	tst.w 72(a0)
	beq.s chan4
	subq.w #1,72(a0)
	cmpi.w #1,72(a0)
	bne.s chan4
	clr.w 72(a0)
	move.l d4,$dff0c0
	move.w d6,$dff0c4

	move.l	scope(pc),a0
	move.l	d4,scope_ch3+ns_loopstart(a0)
	move	d6,scope_ch3+ns_replen(a0)
chan4:
	lea V4data(pc),a0
	tst.w 72(a0)
	beq.s setpervol
	subq.w #1,72(a0)
	cmpi.w #1,72(a0)
	bne.s setpervol
	clr.w 72(a0)
	move.l d5,$dff0d0
	move.w d7,$dff0d4

	move.l	scope(pc),a0
	move.l	d5,scope_ch4+ns_loopstart(a0)
	move	d7,scope_ch4+ns_replen(a0)
setpervol:
	movem.l	d7/a0,-(sp)

	move	mainVolume(pC),d7

	lea $dff0a6,a5
	move.w (a6)+,(a5)	;Set period
	move.w (a6)+,d0		; added
	mulu	d7,d0	
	lsr.w #6,d0		; Delirium
	move.w d0,2(a5)		;Set volume

	move.l	scope(pc),a0
	move	d0,scope_ch1+ns_vol(a0)
	move	-4(a6),scope_ch1+ns_period(a0)

	move.w (a6)+,16(a5)	;Set period
	move.w (a6)+,d0		; added
	mulu	d7,d0	
	lsr.w #6,d0		; Delirium
	move.w d0,18(a5)	;Set volume

	move	d0,scope_ch2+ns_vol(a0)
	move	-4(a6),scope_ch2+ns_period(a0)

	move.w (a6)+,32(a5)	;Set period
	move.w (a6)+,d0		; added
	mulu	d7,d0	
	lsr.w #6,d0		; Delirium
	move.w d0,34(a5)	;Set volume

	move	d0,scope_ch3+ns_vol(a0)
	move	-4(a6),scope_ch3+ns_period(a0)

	move.w (a6)+,48(a5)	;Set period
	move.w (a6)+,d0		; added
	mulu	d7,d0	
	lsr.w #6,d0		; Delirium
	move.w d0,50(a5)	;Set volume

	move	d0,scope_ch4+ns_vol(a0)
	move	-4(a6),scope_ch4+ns_period(a0)
	
	movem.l	(sp)+,d7/a0
	rts

new_note:
	moveq #0,d5
	move.l 34(a0),a1

	move.l 	a1,(a2)		* set stripe pointer
	lea 	PatternInfo(pc),a2 
	move	40(a0),d1 	* pattern position, 2 byte increments
	lsr	#1,d1 
	move	d1,PI_Pattpos(a2)


	adda.w 40(a0),a1
	cmp.w #64,40(a0)
	bne.b samepat
	move.l (a0),a2
	adda.w 6(a0),a2		;Point to next sequence row
	cmpa.l 52(a0),a2	;Is it the end?
	bne.s notend

	move.l	songOverAddr(pc),a2
	st	(a2)

	move.w d5,6(a0)		;yes!
	move.l (a0),a2		;Point to first sequence
notend:
	moveq #1,d1
	addq.b #1,spdtemp
	cmpi.b #5,spdtemp
	bne.s nonewspd
	move.b d1,spdtemp
	move.b 12(a2),d1	;Get new replay speed
	beq.s nonewspd
	move.w d1,respcnt	;store in counter
	move.w d1,repspd
nonewspd:
	move.b (a2),d1		;Pattern to play
	move.b 1(a2),44(a0)	;Transpose value
	move.b 2(a2),22(a0)	;Soundtranspose value
	move.w d5,40(a0)
	lsl.w #6,d1
	add.l PATpoint(pc),d1	;Get pattern pointer
	move.l d1,34(a0)
	addi.w #$000d,6(a0)
	move.l d1,a1
samepat:
	move.b 1(a1),d1		;Get info byte
	move.b (a1)+,d0		;Get note
	bne.s ww1
	andi.w #%11000000,d1
	beq.s noport
	bra.s ww11
ww1:
	move.w d5,56(a0)
ww11:
	move.b d5,47(a0)
	move.b (a1),31(a0)

		;31(a0) = PORTAMENTO/INSTR. info
			;Bit 7 = portamento on
			;Bit 6 = portamento off
			;Bit 5-0 = instrument number
		;47(a0) = portamento value
			;Bit 7-5 = always zero
			;Bit 4 = up/down
			;Bit 3-0 = value
t_porton:
	btst #7,d1
	beq.s noport
	move.b 2(a1),47(a0)	
noport:
	andi.w #$007f,d0
	beq.b nextnote
	move.b d0,8(a0)
	move.b (a1),9(a0)
	move.b 32(a0),d2
	moveq #0,d3
	bset d2,d3
	or.w d3,audtemp
	move.w d3,$dff096
	move.b (a1),d1
	andi.w #$003f,d1	;Max 64 instruments
	add.b 22(a0),d1
	move.l VOLpoint(pc),a2
	lsl.w #6,d1
	adda.w d1,a2
	move.w d5,16(a0)
	move.b (a2),23(a0)
	move.b (a2)+,24(a0)
	move.b (a2)+,d1
	andi.w #$00ff,d1
	move.b (a2)+,27(a0)
	move.b #$40,46(a0)
	move.b (a2)+,d0
	move.b d0,28(a0)
	move.b d0,29(a0)
	move.b (a2)+,30(a0)
	move.l a2,10(a0)
	move.l FRQpoint(pc),a2
	lsl.w #6,d1
	adda.w d1,a2
	move.l a2,18(a0)
	move.w d5,50(a0)
	move.b d5,26(a0)
	move.b d5,25(a0)
nextnote:
	addq.w #2,40(a0)
	rts

effects:
	moveq #0,d7
testsustain:
	tst.b 26(a0)		;Is sustain counter = 0
	beq.s sustzero
	subq.b #1,26(a0)	;if no, decrease counter
	bra.w VOLUfx
sustzero:		;Next part of effect sequence
	move.l 18(a0),a1	;can be executed now.
	adda.w 50(a0),a1
testeffects:
	cmpi.b #$e1,(a1)	;E1 = end of FREQseq sequence
	beq.w VOLUfx
	cmpi.b #$e0,(a1)	;E0 = loop to other part of sequence
	bne.s testnewsound
	move.b 1(a1),d0		;loop to start of sequence + 1(a1)
	andi.w #$003f,d0
	move.w d0,50(a0)
	move.l 18(a0),a1
	adda.w d0,a1
testnewsound:
	cmpi.b #$e2,(a1)	;E2 = set waveform
	bne.w o49c64
	moveq #0,d0
	moveq #0,d1
	move.b 32(a0),d1
	bset d1,d0
	or.w d0,audtemp
	move.w d0,$dff096
	move.b 1(a1),d0
	andi.w #$00ff,d0
	lea SOUNDINFO(pc),a4
	add.w d0,d0
	move.w d0,d1
	add.w d1,d1
	add.w d1,d1
	add.w d1,d0
	adda.w d0,a4
	move.l 60(a0),a3
	move.l (a4),d1
	add.l #WAVEFORMS,d1
	move.l d1,(a3)
	move.l d1,68(a0)
	move.w 4(a4),4(a3)
	move.l 6(a4),64(a0)

	pushm	a2/a3
	move.l	scope(pc),a2
	sub	#$f0a0,a3
	add	a3,a2
	move.l	d1,ns_start(a2)
	move	4(a4),ns_length(a2)
	move.l	d1,ns_loopstart(a2)
	move	4(a4),ns_replen(a2)
	popm	a2/a3	

	swap d1
	move.w #$0003,72(a0)
	tst.w d1
	bne.s o49c52
	move.w #$0002,72(a0)
o49c52:
	clr.w 16(a0)
	move.b #$01,23(a0)
	addq.w #2,50(a0)
	bra.w o49d02
o49c64:
	cmpi.b #$e4,(a1)
	bne.s testpatjmp
	move.b 1(a1),d0
	andi.w #$00ff,d0
	lea SOUNDINFO(pc),a4
	add.w d0,d0
	move.w d0,d1
	add.w d1,d1
	add.w d1,d1
	add.w d1,d0
	adda.w d0,a4
	move.l 60(a0),a3
	move.l (a4),d1
	add.l #WAVEFORMS,d1
	move.l d1,(a3)
	move.l d1,68(a0)
	move.w 4(a4),4(a3)
	move.l 6(a4),64(a0)

	pushm	a2/a3
	move.l	scope(pc),a2
	sub	#$f0a0,a3
	add	a3,a2
	move.l	d1,ns_start(a2)
	move	4(a4),ns_length(a2)
	move.l	d1,ns_loopstart(a2)
	move	4(a4),ns_replen(a2)
	popm	a2/a3	

	swap d1
	move.w #$0003,72(a0)
	tst.w d1
	bne.s o49cae
	move.w #$0002,72(a0)
o49cae:
	addq.w #2,50(a0)
	bra.s o49d02
testpatjmp:
	cmpi.b #$e7,(a1)
	bne.s testnewsustain
	move.b 1(a1),d0
	andi.w #$00ff,d0
	lsl.w #6,d0
	move.l FRQpoint(pc),a1
	adda.w d0,a1
	move.l a1,18(a0)
	move.w d7,50(a0)
	bra.w testeffects
testnewsustain:
	cmpi.b #$e8,(a1)	;E8 = set sustain time
	bne.s o49cea
	move.b 1(a1),26(a0)
	addq.w #2,50(a0)
	bra.w testsustain
o49cea:
	cmpi.b #$e3,(a1)
	bne.s o49d02
	addq.w #3,50(a0)
	move.b 1(a1),27(a0)
	move.b 2(a1),28(a0)
o49d02:
	move.l 18(a0),a1
	adda.w 50(a0),a1
	move.b (a1),43(a0)
	addq.w #1,50(a0)
VOLUfx:
	tst.b 25(a0)
	beq.s o49d1e
	subq.b #1,25(a0)
	bra.s o49d70
o49d1e:
	subq.b #1,23(a0)
	bne.s o49d70
	move.b 24(a0),23(a0)
o49d2a:
	move.l 10(a0),a1
	adda.w 16(a0),a1
	move.b (a1),d0
	cmpi.b #$e8,d0
	bne.s o49d4a
	addq.w #2,16(a0)
	move.b 1(a1),25(a0)
	bra.s VOLUfx
o49d4a:
	cmpi.b #$e1,d0
	beq.s o49d70
	cmpi.b #$e0,d0
	bne.s o49d68
	move.b 1(a1),d0
	andi.l #$003f,d0
	subq.b #5,d0
	move.w d0,16(a0)
	bra.s o49d2a
o49d68:
	move.b (a1),45(a0)
	addq.w #1,16(a0)
o49d70:
	move.b 43(a0),d0
	bmi.s o49d7e
	add.b 8(a0),d0
	add.b 44(a0),d0
o49d7e:
	andi.w #$007f,d0
	lea PERIODS(pc),a1
	add.w d0,d0
	move.w d0,d1
	adda.w d0,a1
	move.w (a1),d0
	move.b 46(a0),d7
	tst.b 30(a0)
	beq.s o49d9e
	subq.b #1,30(a0)

	bra.s o49df4
o49d9e:
	move.b d1,d5
	move.b 28(a0),d4
	add.b d4,d4
	move.b 29(a0),d1
	tst.b d7
	bpl.s o49db4
	btst #0,d7
	bne.s o49dda
o49db4:
	btst #5,d7
	bne.s o49dc8
	sub.b 27(a0),d1
	bcc.s o49dd6
	bset #5,d7
	moveq #0,d1
	bra.s o49dd6
o49dc8:
	add.b 27(a0),d1
	cmp.b d4,d1
	bcs.s o49dd6
	bclr #5,d7
	move.b d4,d1
o49dd6:
	move.b d1,29(a0)
o49dda:
	lsr.b #1,d4
	sub.b d4,d1
	bcc.s o49de4
	subi.w #$0100,d1
o49de4:
	addi.b #$a0,d5
	bcs.s o49df2
o49dea:
	add.w d1,d1
	addi.b #$18,d5
	bcc.s o49dea
o49df2:
	add.w d1,d0
o49df4:
	eori.b #$01,d7
	move.b d7,46(a0)

	; DO THE PORTAMENTO THING
	moveq #0,d1
	move.b 47(a0),d1	;get portavalue
	beq.s a56d0		;0=no portamento
	cmpi.b #$1f,d1
	bls.s pOrtaup
portadown: 
	andi.w #$1f,d1
	neg.w d1
pOrtaup:
	sub.w d1,56(a0)
a56d0:
	add.w 56(a0),d0
o49e3e:
	cmpi.w #$0070,d0
	bhi.s nn1
	move.w #$0071,d0
nn1:
	cmpi.w #$06b0,d0
	bls.s nn2
	move.w #$06b0,d0
nn2:
	moveq #0,d1
	move.b 45(a0),d1
	rts



pervol: dcb.b 16,0	;Periods & Volumes temp. store
respcnt: dc.w 0		;Replay speed counter 
repspd:  dc.w 0		;Replay speed counter temp
onoff:   dc.w 0		;Music on/off flag.
firseq:	 dc.w 0		;First sequence
lasseq:	 dc.w 0		;Last sequence
audtemp: dc.w 0
spdtemp: dc.w 0

V1data:  dcb.b 64,0	;Voice 1 data area
offset1: dcb.b 02,0	;Is added to start of sound
ssize1:  dcb.b 02,0	;Length of sound
start1:  dcb.b 06,0	;Start of sound

V2data:  dcb.b 64,0	;Voice 2 data area
offset2: dcb.b 02,0
ssize2:  dcb.b 02,0
start2:  dcb.b 06,0

V3data:  dcb.b 64,0	;Voice 3 data area
offset3: dcb.b 02,0
ssize3:  dcb.b 02,0
start3:  dcb.b 06,0

V4data:  dcb.b 64,0	;Voice 4 data area
offset4: dcb.b 02,0
ssize4:  dcb.b 02,0
start4:  dcb.b 06,0

o4a0c8: dc.l $00000000,$00100003,$00200006,$00300009
SEQpoint: dc.l 0
PATpoint: dc.l 0
FRQpoint: dc.l 0
VOLpoint: dc.l 0

volume	dc.l	0
songend	dc.l	0

	even
SILENT: dc.w $0100,$0000,$0000,$00e1

PERIODS:
    dc.w $06b0,$0650,$05f4,$05a0,$054c,$0500,$04b8,$0474
	dc.w $0434,$03f8,$03c0,$038a

	dc.w $0358,$0328,$02fa,$02d0,$02a6,$0280,$025c,$023a
	dc.w $021a,$01fc,$01e0,$01c5

	dc.w $01ac,$0194,$017d,$0168,$0153,$0140,$012e,$011d
	dc.w $010d,$00fe,$00f0,$00e2

	dc.w $00d6,$00ca,$00be,$00b4,$00aa,$00a0,$0097,$008f
	dc.w $0087,$007f,$0078,$0071

	dc.w $0071,$0071,$0071,$0071,$0071,$0071,$0071,$0071
	dc.w $0071,$0071,$0071,$0071

	dc.w $0d60,$0ca0,$0be8,$0b40,$0a98,$0a00,$0970,$08e8
	dc.w $0868,$07f0,$0780,$0714

	dc.w $1ac0,$1940,$17d0,$1680,$1530,$1400,$12e0,$11d0
	dc.w $10d0,$0fe0,$0f00,$0e28


OCT macro
oc_ set (\1)*12
	rept 12
	dc.b	oc_
oc_ set oc_+1
	endr
	endm

* Map note index from pattern data into note indexes
* suitable for PatternInfo.
PERIOD_INDEXES:
	* 0. octave
	OCT 2-1
;	dc.w $06b0,$0650,$05f4,$05a0,$054c,$0500,$04b8,$0474
;	dc.w $0434,$03f8,$03c0,$038a
	* 1. octave
	OCT 2+0
;	dc.w $0358,$0328,$02fa,$02d0,$02a6,$0280,$025c,$023a
;	dc.w $021a,$01fc,$01e0,$01c5
	* 2. octave
	OCT 2+1
;	dc.w $01ac,$0194,$017d,$0168,$0153,$0140,$012e,$011d
;	dc.w $010d,$00fe,$00f0,$00e2
	* 3. octave
	OCT 2+2
;	dc.w $00d6,$00ca,$00be,$00b4,$00aa,$00a0,$0097,$008f
;	dc.b $0087,$007f,$0078,$0071
	* 4. octave
	OCT 2+3
;	dc.w $0071,$0071,$0071,$0071,$0071,$0071,$0071,$0071
;	dc.w $0071,$0071,$0071,$0071
	* -1. octave
	OCT 2-1
;	dc.w $0d60,$0ca0,$0be8,$0b40,$0a98,$0a00,$0970,$08e8
;	dc.w $0868,$07f0,$0780,$0714
	* -2. octave
	OCT 2-2
;	dc.w $1ac0,$1940,$17d0,$1680,$1530,$1400,$12e0,$11d0
;	dc.w $10d0,$0fe0,$0f00,$0e28
	* 0. octave again
	OCT 2+0
;	dc.w $06b0,$0650,$05f4,$05a0,$054c,$0500,$04b8,$0474
;	dc.w $0434,$03f8,$03c0,$038a
	* 1. octave again
	OCT 2+1
;	dc.w $0358,$0328,$02fa,$02d0,$02a6,$0280,$025c,$023a
;	dc.w $021a,$01fc,$01e0,$01c5
	* 2. octave again
	OCT 2+2
;	dc.w $01ac,$0194,$017d,$0168,$0153,$0140,$012e,$011d
;	dc.w $010d,$00fe,$00f0,$00e2
	* 3. octave again
	OCT 2+3
;	dc.w $00d6,$00ca,$00be,$00b4,$00aa,$00a0,$0097,$008f
;	dc.w $0087,$007f,$0078,$0071

SOUNDINFO:
;Offset.l , Sound-length.w , Start-offset.w , Repeat-length.w 

;Reserved for samples
	dc.w $0000,$0000,$0000,$0000,$0001 
	dc.w $0000,$0000,$0000,$0000,$0001 
	dc.w $0000,$0000,$0000,$0000,$0001 
	dc.w $0000,$0000,$0000,$0000,$0001 
	dc.w $0000,$0000,$0000,$0000,$0001 
	dc.w $0000,$0000,$0000,$0000,$0001 
	dc.w $0000,$0000,$0000,$0000,$0001 
	dc.w $0000,$0000,$0000,$0000,$0001 
	dc.w $0000,$0000,$0000,$0000,$0001 
	dc.w $0000,$0000,$0000,$0000,$0001 
;Reserved for synth sounds
	dc.w $0000,$0000,$0010,$0000,$0010 
	dc.w $0000,$0020,$0010,$0000,$0010 
	dc.w $0000,$0040,$0010,$0000,$0010 
	dc.w $0000,$0060,$0010,$0000,$0010 
	dc.w $0000,$0080,$0010,$0000,$0010 
	dc.w $0000,$00a0,$0010,$0000,$0010 
	dc.w $0000,$00c0,$0010,$0000,$0010 
	dc.w $0000,$00e0,$0010,$0000,$0010 
	dc.w $0000,$0100,$0010,$0000,$0010 
	dc.w $0000,$0120,$0010,$0000,$0010 
	dc.w $0000,$0140,$0010,$0000,$0010 
	dc.w $0000,$0160,$0010,$0000,$0010 
	dc.w $0000,$0180,$0010,$0000,$0010 
	dc.w $0000,$01a0,$0010,$0000,$0010 
	dc.w $0000,$01c0,$0010,$0000,$0010 
	dc.w $0000,$01e0,$0010,$0000,$0010 
	dc.w $0000,$0200,$0010,$0000,$0010 
	dc.w $0000,$0220,$0010,$0000,$0010 
	dc.w $0000,$0240,$0010,$0000,$0010 
	dc.w $0000,$0260,$0010,$0000,$0010 
	dc.w $0000,$0280,$0010,$0000,$0010 
	dc.w $0000,$02a0,$0010,$0000,$0010 
	dc.w $0000,$02c0,$0010,$0000,$0010 
	dc.w $0000,$02e0,$0010,$0000,$0010 
	dc.w $0000,$0300,$0010,$0000,$0010 
	dc.w $0000,$0320,$0010,$0000,$0010 
	dc.w $0000,$0340,$0010,$0000,$0010 
	dc.w $0000,$0360,$0010,$0000,$0010 
	dc.w $0000,$0380,$0010,$0000,$0010 
	dc.w $0000,$03a0,$0010,$0000,$0010 
	dc.w $0000,$03c0,$0010,$0000,$0010 
	dc.w $0000,$03e0,$0010,$0000,$0010 
	dc.w $0000,$0400,$0008,$0000,$0008 
	dc.w $0000,$0410,$0008,$0000,$0008 
	dc.w $0000,$0420,$0008,$0000,$0008 
	dc.w $0000,$0430,$0008,$0000,$0008 
	dc.w $0000,$0440,$0008,$0000,$0008
	dc.w $0000,$0450,$0008,$0000,$0008
	dc.w $0000,$0460,$0008,$0000,$0008
	dc.w $0000,$0470,$0008,$0000,$0008
	dc.w $0000,$0480,$0010,$0000,$0010
	dc.w $0000,$04a0,$0008,$0000,$0008
	dc.w $0000,$04b0,$0010,$0000,$0010
	dc.w $0000,$04d0,$0010,$0000,$0010
	dc.w $0000,$04f0,$0008,$0000,$0008
	dc.w $0000,$0500,$0008,$0000,$0008
	dc.w $0000,$0510,$0018,$0000,$0018
 

WAVEFORMS:
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $3f37,$2f27,$1f17,$0f07,$ff07,$0f17,$1f27,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c037,$2f27,$1f17,$0f07,$ff07,$0f17,$1f27,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$2f27,$1f17,$0f07,$ff07,$0f17,$1f27,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$b027,$1f17,$0f07,$ff07,$0f17,$1f27,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$b0a8,$1f17,$0f07,$ff07,$0f17,$1f27,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$b0a8,$a017,$0f07,$ff07,$0f17,$1f27,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$b0a8,$a098,$0f07,$ff07,$0f17,$1f27,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$b0a8,$a098,$9007,$ff07,$0f17,$1f27,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$b0a8,$a098,$9088,$ff07,$0f17,$1f27,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$b0a8,$a098,$9088,$8007,$0f17,$1f27,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$b0a8,$a098,$9088,$8088,$0f17,$1f27,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$b0a8,$a098,$9088,$8088,$9017,$1f27,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$b0a8,$a098,$9088,$8088,$9098,$1f27,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$b0a8,$a098,$9088,$8088,$9098,$a027,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$b0a8,$a098,$9088,$8088,$9098,$a0a8,$2f37
	dc.w $c0c0,$d0d8,$e0e8,$f0f8,$00f8,$f0e8,$e0d8,$d0c8
	dc.w $c0b8,$b0a8,$a098,$9088,$8088,$9098,$a0a8,$b037
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $817f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $8181,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $8181,$817f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $8181,$8181,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $8181,$8181,$817f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $8181,$8181,$8181,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $8181,$8181,$8181,$817f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $8181,$8181,$8181,$8181,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $8181,$8181,$8181,$8181,$817f,$7f7f,$7f7f,$7f7f
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $8181,$8181,$8181,$8181,$8181,$7f7f,$7f7f,$7f7f
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $8181,$8181,$8181,$8181,$8181,$817f,$7f7f,$7f7f
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$7f7f,$7f7f
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$8181,$8181
	dc.w $8181,$8181,$8181,$8181,$8181,$8181,$817f,$7f7f
	dc.w $8080,$8080,$8080,$8080,$8080,$8080,$8080,$8080
	dc.w $8080,$8080,$8080,$8080,$8080,$8080,$8080,$7f7f
	dc.w $8080,$8080,$8080,$8080,$8080,$8080,$8080,$8080
	dc.w $8080,$8080,$8080,$8080,$8080,$8080,$8080,$807f
	dc.w $8080,$8080,$8080,$8080,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8080,$8080,$8080,$807f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8080,$8080,$8080,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8080,$8080,$807f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8080,$8080,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8080,$807f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8080,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8080,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f,$7f7f
	dc.w $8080,$9098,$a0a8,$b0b8,$c0c8,$d0d8,$e0e8,$f0f8
	dc.w $0008,$1018,$2028,$3038,$4048,$5058,$6068,$707f
	dc.w $8080,$a0b0,$c0d0,$e0f0,$0010,$2030,$4050,$6070
	dc.w $4545,$797d,$7a77,$7066,$6158,$534d,$2c20,$1812
	dc.w $04db,$d3cd,$c6bc,$b5ae,$a8a3,$9d99,$938e,$8b8a
	dc.w $4545,$797d,$7a77,$7066,$5b4b,$4337,$2c20,$1812
	dc.w $04f8,$e8db,$cfc6,$beb0,$a8a4,$9e9a,$9594,$8d83
	dc.w $0000,$4060,$7f60,$4020,$00e0,$c0a0,$80a0,$c0e0
	dc.w $0000,$4060,$7f60,$4020,$00e0,$c0a0,$80a0,$c0e0
	dc.w $8080,$9098,$a0a8,$b0b8,$c0c8,$d0d8,$e0e8,$f0f8
	dc.w $0008,$1018,$2028,$3038,$4048,$5058,$6068,$707f
	dc.w $8080,$a0b0,$c0d0,$e0f0,$0010,$2030,$4050,$6070
