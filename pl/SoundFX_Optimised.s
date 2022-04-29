;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000


test	=	0

	incdir	include:
	include	mucro.i
	include	misc/eagleplayer.i

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


 ifne test
bob
	lea	module,a0
	move.l	60(a0),d0
	cmp.l	#"SONG",d0

	* initial song number
	lea	module,a0
	lea	masterVol_,a1
	lea	dmawait,a2
	lea	curpos,a3
	lea	maxpos,a4
	lea	scope_,a5
	jsr	init
	bne.b	error

	bsr.b	playLoop
;	jsr	end
error
	rts

masterVol_	dc	$40/1
curpos		dc	0
maxpos		dc	0
scope_		ds.b scope_size

dmawait
	pushm	d0/d1
	moveq	#12-1,d1
.d	move.b	$dff006,d0
.k	cmp.b	$dff006,d0
	beq.b	.k
	dbf	d1,.d
	popm	d0/d1
	rts

playLoop
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

	rts

	SECTION	modu,data_c

module  incbin	"m:exo/SoundFX/- unknown/waterfall.sfx"

	SECTION	modu2,code_p
 endif


	jmp	init(pc)
	jmp	play(pc)
	
init
	move.l	a1,masterVolAddr
	move.l	a2,dmaWaitAddr
	move.l	a3,curPosAddr
	move.l	a4,maxPosAddr
	move.l	a5,scopeAddr
	bsr.w	fx_init
	bsr.b	posUpdate
	bsr.b	PatternInit
	moveq	#0,d0
	rts

posUpdate
	move.l	curPosAddr(pc),a0 
	move	TrackPos+2(pc),(a0)
	move.l	maxPosAddr(pc),a0
	move	AnzPat(pc),(a0)
	rts
	
play	
	move.l	masterVolAddr(pc),a0
	move	(a0),masterVol
	bsr.b	posUpdate
	bsr.w	fx_play
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
	move.l	#16,PI_Modulo(A0)	; Number of bytes to next row
	move.w	#64,PI_Pattlength(A0)	; Length of each stripe in rows
	clr.w	PI_Pattpos(A0)		; Current Position in Pattern (from 0)
	move	#6,PI_Speed(a0)		; Magic positive: use periods
	rts

* Called by the PI engine to get values for a particular row
ConvertNote
	moveq	#0,D0		; Period, Note
	moveq	#0,D1		; Sample number
	moveq	#0,D2		; Command 
	moveq	#0,D3		; Command argument

	tst	(a0)
	bmi.b	.no
	move	(a0),d0

	* sample num
	move.b	2(a0),d1
	lsr.b	#4,d1
.no
	moveq	#$f,d2
	and.b	2(a0),d2
	move.b	3(a0),d3

	rts


setVol
	push	a5
	sub.l	#$dff0a0,a5
	add.l	scopeAddr(pc),a5
	move	d3,ns_vol(a5)
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


dmaWaitAddr		dc.l 	0
masterVolAddr		dc.l	0
masterVol		dc	0
curPosAddr		dc.l 0
maxPosAddr		dc.l 0
scopeAddr		dc.l 0

fx_init:
	move.l	a0,SongPointer
	add	#60,a0			;Laengentabelle ueberspringen
	move.b	470(a0),AnzPat+1	;Laenge des Sounds
*	move	4(A0),DelayValue 	;Geschwindigkeit
	movem.l	d1-d7/a0-a6,-(SP)
	move.l	SongPointer,a0
	lea	532(A0),a0
	move	AnzPat(pc),d2		;wieviel Positions
	subq	#1,d2			;für dbf
	moveq	#0,d1
	moveq	#0,d0
SongLenLoop:
	move.b	(a0)+,d0		;Patternnummer holen
	cmp.b	d0,d1			;ist es die höchste ?
	bhi.s	LenHigher		;nein!
	move.b	d0,d1			;ja
LenHigher:
	dbf	d2,SongLenLoop
	move.l	d1,d0			;Hoechste BlockNummer nach d0
	addq	#1,d0			;plus 1
	mulu	#1024,d0		;Laenge eines Block
	movem.l	(SP)+,d1-d7/a0-a6
	add.l	d0,a0			;Zur Adresse der Songstr.
	add.w	#600,a0			;Laenge der SongStr.
	move.l	SongPointer(pc),a2
	lea	Instruments(pc),a1	;Tabelle auf Samples
	moveq	#14,d7			;15 Instrumente
CalcIns:
	move.l	a0,(A1)+		;Startadresse des Instr.
	add.l	(a2)+,a0		;berechnen un speichern
	dbf	d7,CalcIns
	lea	Instruments(pc),a0	;Zeiger auf instr.Tabelle
	moveq	#14,d7			;15 Instrumente
	lea	$dff000,a0		;AMIGA
	move.w	#-1,PlayLock		;player zulassen
	clr	$a8(A0)			;Alle Voloumenregs. auf 0
	clr	$b8(A0)
	clr	$c8(a0)
	clr	$d8(a0)
	clr.w	Timer			;zahler auf 0
	clr.l	TrackPos		;zeiger auf pos
	clr.l	PosCounter		;zeiger innehalb des pattern
	rts
fx_stop:
	lea	$dff000,a0		;AMIGA
	clr.w	PlayLock		;player sperren
	clr	$a8(a0)			;volumen auf 0
	clr	$b8(a0)
	clr	$c8(a0)
	clr	$d8(a0)
	move.w	#$f,$96(A0)		;dma sperren
	rts

fx_play:				;HauptAbspielRoutine
	movem.l	d0-d7/a0-a6,-(SP)
	addq.w	#1,Timer		;zähler erhöhen
	cmp.w	#6,Timer		;schon 6?
	bne.s	CheckEffects		;wenn nicht -> effekte
	clr.w	Timer			;sonst zähler löschen
	bsr.w 	PlaySound		;und sound spielen
NoPlay:	movem.l	(SP)+,d0-d7/a0-a6
	rts

CheckEffects:
	moveq	#3,d7			;4 kanäle
	lea	StepControl0,a4
	lea	ChannelData0(pc),a6	;zeiger auf daten für 0
	lea	$dff0a0,a5		;Kanal 0
EffLoop:
	movem.l	d7/a5,-(SP)
	bsr.s	MakeEffekts		;Effekt spielen
	movem.l	(Sp)+,d7/a5
NoEff:
	addq	#8,a4
	add	#$10,a5			;nächster Kanal
	add	#22,a6			;Nächste KanalDaten
	dbf	d7,EffLoop
	movem.l	(a7)+,d0-d7/a0-a6
	rts

MakeEffekts:
	move	(A4),d0
	beq.s	NoStep
	bmi.s	StepItUp
	add	d0,2(A4)
	move	2(A4),d0
	move	4(A4),d1
	cmp	d0,d1
	bhi.s	StepOk
	move	d1,d0
StepOk:
	move	d0,6(a5)
	MOVE	D0,2(A4)
	bsr.w	setPer
	rts

StepItUp:
	add	d0,2(A4)
	move	2(A4),d0
	move	4(A4),d1
	cmp	d0,d1
	blt.s	StepOk
	move	d1,d0
	bra.s	StepOk

NoStep:
	move.b	2(a6),d0
	and.b	#$0f,d0
	cmp.b	#1,d0
	beq.w	appreggiato
	cmp.b	#2,d0
	beq.w	pitchbend
	cmp.b	#3,d0
	beq.b	LedOn
	cmp.b	#4,d0
	beq.b	LedOff
	cmp.b	#7,d0
	beq.s	SetStepUp
	cmp.b	#8,d0
	beq.s	SetStepDown
	rts

LedOn:
	bset	#1,$bfe001
	rts
LedOff:
	bclr	#1,$bfe001
	rts

SetStepUp:
	moveq	#0,d4
StepFinder:
	clr	(a4)
	move	(A6),2(a4)
	moveq	#0,d2
	move.b	3(a6),d2
	and	#$0f,d2
	tst	d4
	beq.s	NoNegIt
	neg	d2
NoNegIt:	
	move	d2,(a4)
	moveq	#0,d2
	move.b	3(a6),d2
	lsr	#4,d2
	move	(a6),d0
	lea	NoteTable,a0

StepUpFindLoop:
	move	(A0),d1
	cmp	#-1,d1
	beq.s	EndStepUpFind
	cmp	d1,d0
	beq.s	StepUpFound
	addq	#2,a0
	bra.s	StepUpFindLoop
StepUpFound:
	lsl	#1,d2
	tst	d4
	bne.s	NoNegStep
	neg	d2
NoNegStep:
	move	(a0,d2.w),d0
	move	d0,4(A4)
	rts

EndStepUpFind:
	move	d0,4(A4)
	rts
	
SetStepDown:
	st	d4
	bra.s	StepFinder

StepControl0:
	dc.l	0,0
StepControl1:
	dc.l	0,0
StepControl2:
	dc.l	0,0
StepControl3:
	dc.l	0,0

appreggiato:
	lea	ArpeTable,a0
	moveq	#0,d0
	move	Timer,d0
	subq	#1,d0
	lsl	#2,d0
	move.l	(A0,d0.l),a0
	jmp	(A0)

Arpe4:	lsl.l	#1,d0
	clr.l	d1
	move.w	16(a6),d1
	lea.l	NoteTable,a0
Arpe5:	move.w	(a0,d0.l),d2
	cmp.w	(a0),d1
	beq.s	Arpe6
	addq.l	#2,a0
	bra.s	Arpe5

Arpe1:	clr.l	d0
	move.b	3(a6),d0
	lsr.b	#4,d0
	bra.s	Arpe4

Arpe2:	clr.l	d0
	move.b	3(a6),d0
	and.b	#$0f,d0
	bra.s	Arpe4

Arpe3:	move.w	16(a6),d2
	
Arpe6:	move.w	d2,6(a5)

	push	d0
	move 	d2,d0
	bsr.w	setPer
	pop	d0
	rts

pitchbend:
	clr.l	d0
	move.b	3(a6),d0
	lsr.b	#4,d0
	tst.b	d0
	beq.s	pitch2
	add.w	d0,(a6)
	move.w	(a6),6(a5)

	push	d0
	move	(a6),d0
	bsr.w	setPer
	pop	d0
	rts

pitch2:	clr.l	d0
	move.b	3(a6),d0
	and.b	#$0f,d0
	tst.b	d0
	beq.s	pitch3
	sub.w	d0,(a6)
	move.w	(a6),6(a5)

	push	d0
	move	(a6),d0
	bsr.w	setPer
	pop	d0
	
pitch3:	rts

PlaySound:
	move.l	SongPointer(pc),a0	;Zeiger auf SongFile
	add	#60,a0			;Laengentabelle ueberspringen
	move.l	a0,a3
	move.l	a0,a2
	lea	600(A0),a0		;Zeiger auf BlockDaten
	add	#472,a2			;zeiger auf Patterntab.
	add	#12,a3			;zeiger auf Instr.Daten
	move.l	TrackPos(pc),d0		;Postionzeiger

	move.l	PosCounter(pc),d1
	lsr.l	#4,d1
	move	d1,PatternInfo+PI_Pattpos

	clr.l	d1
	move.b	(a2,d0.l),d1		;dazugehörige PatternNr. holen
	moveq	#10,d7
	lsl.l	d7,d1			;*1024 / länge eines Pattern
	
	pea	(a0,d1.l)
	move.l	(sp)+,Stripe1
	pea	4(a0,d1.l)
	move.l	(sp)+,Stripe2
	pea	8(a0,d1.l)
	move.l	(sp)+,Stripe3
	pea	12(a0,d1.l)
	move.l	(sp)+,Stripe4

	add.l	PosCounter,d1		;Offset ins Pattern
	clr.w	DmaCon
	lea	StepControl0,a4
	lea	$dff0a0,a5		;Zeiger auf Kanal0
	lea	ChannelData0(pc),a6	;Daten für Kanal0
	moveq	#3,d7			;4 Kanäle
SoundHandleLoop:
	bsr.w	PlayNote		;aktuelle Note spielen
	add	#8,a4
	add.l	#$10,a5			;nächster Kanal
	add.l	#22,a6			;nächste Daten
	dbf	d7,SoundHandleLoop	;4*
	
	move	DmaCon(pc),d0		;DmaBits
	bset	#15,d0			;Clear or Set Bit setzen
	move.w	d0,$dff096		;DMA ein!

;	move	#300,d0			;Verzögern (genug für MC68030)
;Delay2:
;	dbf	d0,Delay2
	move.l	dmaWaitAddr(pc),a6
	jsr	(a6)
	
	lea	ChannelData3(pc),a6
	lea	$dff0d0,a5
	moveq	#3,d7
SetRegsLoop:
	move.l	10(A6),(a5)		;Adresse
	move	14(A6),4(A5)		;länge

	pushm	d0/d1
	move.l	10(A6),d0
	move	14(A6),d1
	bsr.w	setRep
	popm	d0/d1

NoSetRegs:
	sub	#22,a6			;nächste Daten
	sub	#$10,a5			;nächster Kanal
	dbf	d7,SetRegsLoop


	tst	PlayLock
	beq.s	NoEndPattern
	;addq	#1,PatternInfo+PI_Pattpos
	add.l	#16,PosCounter		;PatternPos erhöhen
	cmp.l	#1024,PosCounter	;schon Ende ?
	blt.s	NoEndPattern

	clr.l	PosCounter		;PatternPos löschen
	;clr	PatternInfo+PI_Pattpos
	addq.l	#1,TrackPos		;Position erhöhen
NoAddPos:
	move.w	AnzPat(pc),d0		;AnzahlPosition
	move.l	TrackPos(pc),d1		;Aktuelle Pos
	cmp.w	d0,d1			;Ende?
	bne.s	NoEndPattern		;nein!
	clr.l	TrackPos		;ja/ Sound von vorne
NoEndPattern:
	rts

PlayNote:
	clr.l	(A6)
	tst	PlayLock		;Player zugellassen ?
	beq.s	NoGetNote		;
	move.l	(a0,d1.l),(a6)		;Aktuelle Note holen
NoGetNote:
	addq.l	#4,d1			;PattenOffset + 4
	clr.l	d2
	cmp	#-3,(A6)		;Ist Note = 'PIC' ?
	beq.w	NoInstr2		;wenn ja -> ignorieren
	move.b	2(a6),d2		;Instr Nummer holen	
	and.b	#$f0,d2			;ausmaskieren
	lsr.b	#4,d2			;ins untere Nibble
	tst.b	d2			;kein Intrument ?
	beq.W	NoInstr2		;wenn ja -> überspringen
	
	clr.l	d3
	lea.l	Instruments(pc),a1	;Instr. Tabelle
	move.l	d2,d4			;Instrument Nummer
	subq	#1,d2
	lsl	#2,d2			;Offset auf akt. Instr.
	mulu	#30,d4			;Offset Auf Instr.Daten
	move.l	(a1,d2.w),4(a6)		;Zeiger auf akt. Instr.
	move.w	(a3,d4.l),8(a6)		;Instr.Länge
	move.w	2(a3,d4.l),18(a6)	;Volume
	move.w	4(a3,d4.l),d3		;Repeat
	tst	d3			;kein Repeat?
	beq.s	NoRepeat		;Nein!
					;Doch!
	
	move.l	4(a6),d2		;akt. Instr.
	add.l	d3,d2			;Repeat dazu
	move.l	d2,10(a6)		;Repeat Instr.
	move.w	6(a3,d4),14(a6)		;rep laenge
	move.w	18(a6),d3 		;Volume in HardReg.
	bra.s	NoInstr

NoRepeat:
	move.l	4(a6),d2		;Instrument	
	add.l	d3,d2			;rep Offset
	move.l	d2,10(a6)		;in Rep. Pos.
	move.w	6(a3,d4.l),14(a6)	;rep Laenge
	move.w	18(a6),d3 		;Volume in Hardware

CheckPic:
NoInstr:
	move.b	2(A6),d2
	and	#$0f,d2
	cmp.b	#5,d2
	beq.s	ChangeUpVolume
	cmp.b	#6,d2
	bne.B	SetVolume2
	moveq	#0,d2
	move.b	3(A6),d2
	sub	d2,d3		
	tst	d3
	bpl.b	SetVolume2	
	clr	d3
	bra.B	SetVolume2
ChangeUpVolume:
	moveq	#0,d2
	move.b	3(A6),d2
	add	d2,d3
	tst	d3
	cmp	#64,d3
	ble.B	SetVolume2
	move	#64,d3
SetVolume2:
	* vol
	mulu	masterVol(pc),d3
	lsr	#6,d3

	move	d3,8(A5)
	bsr.w	setVol

NoInstr2:
	cmp	#-3,(A6)		;Ist Note = 'PIC' ?
	bne.s	NoPic		
	clr	2(A6)			;wenn ja -> Note auf 0 setzen
	bra.s	NoNote	
NoPic:
	tst	(A6)			;Note ?
	beq.s	NoNote			;wenn 0 -> nicht spielen
	
	clr	(a4)
	move.w	(a6),16(a6)		;eintragen
	move.w	20(a6),$dff096		;dma abschalten
;	move.l	d7,-(SP)
;	move	#300,d7			;genug für MC68030
;Delay1:
;	dbf	d7,Delay1		;delay
;	move.l	(SP)+,d7
	push	a0
	move.l	dmaWaitAddr(pc),a0
	jsr	(a0)
	pop	a0

	cmp	#-2,(A6)		;Ist es 'STP'
	bne.s	NoStop			;Nein!
	clr	8(A5)
	bra.b	Super
NoStop:
	move.l	4(a6),0(a5)		;Intrument Adr.
	move.w	8(a6),4(a5)		;Länge
	move.w	0(a6),6(a5)		;Period

	pushm	d0/d1
	move.l	4(a6),d0
	move	8(a6),d1
	bsr.w	setAddr
	move	(a6),d0
	bsr.w	setPer
	popm	d0/d1
Super:
	move.w	20(a6),d0		;DMA Bit
	or.w	d0,DmaCon		;einodern
NoNote:
	rts

ArpeTable:
	dc.l	Arpe1
	dc.l	Arpe2
	dc.l	Arpe3
	dc.l	Arpe2
	dc.l	Arpe1

ChannelData0:
	blk.l	5,0			;Daten für Note
	dc.w	1			;DMA - Bit
ChannelData1:	
	blk.l	5,0			;u.s.w
	dc.w	2
ChannelData2:	
	blk.l	5,0			;etc.
	dc.w	4
ChannelData3:	
	blk.l	5,0			;a.s.o
	dc.w	8
Instruments:
	blk.l	15,0			;Zeiger auf die 15 Instrumente
PosCounter:
	dc.l	0			;Offset ins Pattern
TrackPos:
	dc.l	0			;Position Counter
Timer:
	dc.w	0			;Zähler 0-5
DmaCon:
	dc.w	0			;Zwischenspeicher für DmaCon
AnzPat:
	dc.w	1			;Anzahl Positions
PlayLock:
	dc.w	0			;Flag fuer 'Sound erlaubt'
SongPointer:
	dc.l	0

Reserve:
	dc.w	856,856,856,856,856,856,856,856,856,856,856,856
NoteTable:
	dc.w	856,808,762,720,678,640,604,570,538,508,480,453   ;1.Okt
	dc.w	428,404,381,360,339,320,302,285,269,254,240,226   ;2.Okt
	dc.w	214,202,190,180,170,160,151,143,135,127,120,113	  ;3.Okt
	dc.w	113,113,113,113,113,113,113,113,113,113,113,113	  ;Reserve
	dc.w	-1
