����                                        


testi	=	1

 ifne testi

	bset	#1,$bfe001
;	bsr	Chk
;	bsr	InitPlay

	lea	module,a0
	moveq	#1,d0
	lea	foo(pc),a1
	lea	dmaw(pc),a2
	bsr	ini

loop	
	cmp.b	#$80,$dff006	
	bne.b	loop

	move	#$ff0,$dff180
	bsr	Int
	clr	$dff180

	btst	#6,$bfe001
	bne.b	loop
	bsr	RemSnd
	move	#$f,$dff096
	rts

foo	dc	0

dmaw
	movem.l	d0/d1,-(sp)
	moveq   #12-1,d1
.d      move.b  $dff006,d0
.k      cmp.b   $dff006,d0
        beq.b   .k
        dbf     d1,.d	
	movem.l	(sp)+,d0/d1
	rts


 endc

hdr
	jmp	ini(pc)
	jmp	Int(pc)
	jmp	end(pc)
	jmp	SetVol(pc)


ini	
* d0 = songnumber
* a0 = module
* a1 = songend
* a2 = dmawait

	move.l	a1,songend
	move.l	a0,SongData
	move.l	a2,dmawait
;	lea	module,a0
	add.l	$1c(a0),a0
	move.l	a0,SampData

	bsr.b	InitSnd
	rts

end	
	bsr.b	RemSnd
	rts


songend	dc.l	0
dmawait	dc.l	0



;PlayerTagArray
;	dc.l	DTP_RequestDTVersion,17
;	dc.l	DTP_PlayerVersion,01<<16+40
;	dc.l	DTP_PlayerName,PName
;	dc.l	DTP_Creator,CName
;	dc.l	DTP_DeliBase,delibase
;	dc.l	DTP_Check2,Chk
;	dc.l	DTP_ExtLoad,Load
;	dc.l	DTP_SubSongRange,SubSong
;	dc.l	DTP_Flags,PLYF_SONGEND
;	dc.l	DTP_Interrupt,Int
;	dc.l	DTP_InitPlayer,InitPlay
;	dc.l	DTP_EndPlayer,EndPlay
;	dc.l	DTP_InitSound,InitSnd
;	dc.l	DTP_EndSound,RemSnd
;	dc.l	DTP_Volume,SetVol
;	dc.l	TAG_DONE

*-----------------------------------------------------------------------*
;
; Player/Creatorname und lokale Daten

;PName	dc.b 'Hippel-COSO',0
;CName	dc.b 'Jochen Hippel,',10
;	dc.b 'adapted by Delirium',0
;	even

;SamplesTxt	dc.b '.samp',0
;	even

;delibase	dc.l 0

SongData	dc.l 0
SampData	dc.l 0
;MaxSong		dc.w 0				; maximal subsongnumber
;LoadSamp	dc.b 0
;	even

*-----------------------------------------------------------------------*
;
;Interrupt f�r Replay

Int
	movem.l	d0-d1/a0-a1,-(sp)
	bsr.b	HippelBase+4			; DudelDiDum
	movem.l	(sp)+,d0-d1/a0-a1
	rts

*-----------------------------------------------------------------------*
;
; Testet, ob es sich um ein Hippel-COSO-Modul handelt

;Chk
;;	move.l	dtg_ChkData(a5),a0		; ^module
;	lea	module,a0

;	cmpi.l	#"COSO",$00(a0)			; test ID
;	bne.s	ChkFail
;	cmpi.l	#"TFMX",$20(a0)			; test ID
;	bne.s	ChkFail

;	move.l	$1c(a0),d0
;	sub.l	$18(a0),d0
;	bmi.s	ChkFail				; table corrupt !
;	divu	#10,d0
;	swap	d0
;	tst.w	d0				; multiple of 10 ?
;	bne.s	ChkFail				; no !
;	swap	d0
;	subq.w	#1,d0
;	beq.s	ChkFail				; sampletable is empty !
;	move.l	a0,a1
;	add.l	$18(a0),a1			; ^sampletable
;	move.l	a1,a2
;	moveq	#0,d2
;ChkLoop	move.l	(a1),d1				; ^samplestart
;	cmp.l	d2,d1
;	ble.s	ChkNext
;	move.l	d1,d2
;	move.l	a1,a2
;ChkNext	add.w	#10,a1				; next sample
;	subq.l	#1,d0
;	bne.s	ChkLoop

;	move.l	$1c(a0),d0			; ^samples
;	move.l	d0,d1
;	add.l	(a2)+,d1			; get samplestart
;	moveq	#0,d2
;	move.w	(a2)+,d2			; get samplelength
;	add.l	d2,d2
;	add.l	d2,d1
;;	addq.l	#4,d1				; 4 bytes null-sample


;;	move.l	dtg_ChkSize(a5),d2		; size of module
;	move.l	#modulee-module,d2

;	cmp.l	d1,d2
;;	slt	LoadSamp			; set load-samples flag
;	blt	ChkFail		* ei hyv�ksyt� modeja joissa erilliset samplet

;	add.l	#1024,d1
;	cmp.l	d0,d2				; test size of module
;	blt.s	ChkFail				; too small
;	cmp.l	d1,d2				; test size of module
;	bgt.s	ChkFail				; too big
;	moveq	#0,d0				; Modul erkannt
;	bra.s	ChkEnd
;ChkFail
;	moveq	#-1,d0				; Modul nicht erkannt
;ChkEnd
;	rts

*-----------------------------------------------------------------------*
;
; Sample laden, falls n�tig

;Load
;	moveq	#0,d0				; no error

;	tst.b	LoadSamp			; load samples ?
;	beq.s	LoadEnd				; no !

;	move.l	dtg_PathArrayPtr(a5),a0
;	clr.b	(a0)				; clear Path

;	move.l	dtg_CopyDir(a5),a0		; copy dir into patharray
;	jsr	(a0)

;	move.l	dtg_CopyFile(a5),a0		; append filename
;	jsr	(a0)

;	move.l	dtg_CutSuffix(a5),a0		; remove '.pp' suffix if necessary
;	jsr	(a0)

;	move.l	dtg_PathArrayPtr(a5),a0		; search end of string
;	moveq	#1,d0
;Search	addq.l	#1,d0
;	tst.b	(a0)+
;	bne.s	Search

;Suffix	subq.l	#1,d0				; search suffix
;	beq.s	NoSuffix
;	cmpi.b	#".",-(a0)
;	bne.s	Suffix
;	clr.b	(a0)				; remove suffix
;NoSuffix
;	lea	SamplesTxt(pc),a0		; join '.samp'
;	move.l	dtg_CopyString(a5),a1
;	jsr	(a1)

;	move.l	dtg_LoadFile(a5),a0
;	jsr	(a0)				; returncode is already set !
;LoadEnd
;	rts

*-----------------------------------------------------------------------*
;
; Set min. & max. subsong number

;SubSong
;	moveq	#1,d0				; min.
;	move.w	MaxSong(pc),d1			; max.
;	rts

*-----------------------------------------------------------------------*
;
; Init Player



;InitPlay
;	moveq	#0,d0
;	move.l	dtg_GetListData(a5),a0		; Function
;	jsr	(a0)
;	lea	module,a0
;	move.l	a0,SongData

;	move.l	$18(a0),d0
;	sub.l	$14(a0),d0
;	divu	#6,d0
;	subq.w	#1,d0
;	move.w	d0,MaxSong			; store MaxSong

;	moveq	#1,d0
;	move.l	dtg_GetListData(a5),a0		; Function
;	jsr	(a0)

;	lea	module,a0
;	add.l	$1c(a0),a0
;	move.l	a0,SampData

;	move.l	dtg_AudioAlloc(a5),a0		; Function
;	jsr	(a0)				; returncode is already set !
	rts

*-----------------------------------------------------------------------*
;
; End Player

;EndPlay
;	move	#$f,$dff096
;	move.l	dtg_AudioFree(a5),a0		; Function
;	jsr	(a0)
;	rts

*-----------------------------------------------------------------------*
;
; Init Sound

InitSnd
;	moveq	#0,d0
;	move.w	dtg_SndNum(a5),d0
;	moveq	#1,d0
	move.l	SongData(pc),a0
	move.l	SampData(pc),a1
	bsr.b	HippelBase+0			; Init Sound
	rts

*-----------------------------------------------------------------------*
;
; Remove Sound

RemSnd
	moveq	#0,d0
	move.l	SongData(pc),a0
	move.l	SampData(pc),a1
	bsr.b	HippelBase+0			; End Sound
	rts

*-----------------------------------------------------------------------*
;
; Set Volume

SetVol
* d0 = volume
;	moveq	#64,d0
;	sub.w	dtg_SndVol(a5),d0
	mulu	#25,d0
	lsr.w	#4,d0
	bsr.b	HippelBase+8			; Volume
	rts

*-----------------------------------------------------------------------*
;
; Jochen Hippel Replay (AmberStar)

HippelBase
	bra.w	lbC00002E

	bra.w	lbC0000D8

	bra.w	lbC000022

;	dc.b	'MUSIC BY JOCHEN HIPPEL'

lbC000022
	pea	(a0)
	lea	lbW000C8A(pc),a0
	move.w	d0,(a0)
	move.l	(sp)+,a0
	rts

lbC00002E
	movem.l	d0-d7/a0-a6,-(sp)
	lea	lbL000C78(pc),a2
	move.l	a1,(a2)
	move.w	d0,-(sp)
	bsr.b	lbC000072
	move.w	(sp)+,d0
	bne.b	lbC00004C
	lea	lbW000A8E(pc),a6
	st	(a6)
	bra.s	lbC00006C

lbC00004C
	move.l	lbL000C80(pc),a1
	subq.l	#$01,d0
	add.w	d0,d0
	move.w	d0,d1
	add.w	d0,d0
	add.w	d1,d0
	add.w	d0,a1
	move.w	(a1)+,d0
	move.w	(a1)+,d1
	lea	lbW000A8C(pc),a0
	move.w	(a1),(a0)
	bsr.w	lbC000442
lbC00006C
	movem.l	(sp)+,d0-d7/a0-a6
	rts

lbC000072
	lea	lbL000C84(pc),a2
	move.l	a0,(a2)
	move.l	$0004(a0),a1
	add.l	a0,a1
	lea	lbL000C5C(pc),a2
	move.l	a1,(a2)
	move.l	$0008(a0),a1
	add.l	a0,a1
	lea	lbL000C64(pc),a2
	move.l	a1,(a2)
	move.l	$000C(a0),a1
	add.l	a0,a1
	lea	lbL000C58(pc),a2
	move.l	a1,(a2)
	move.l	$0010(a0),a1
	add.l	a0,a1
	lea	lbL000C6C(pc),a2
	move.l	a1,(a2)
	move.l	$0014(a0),a1
	add.l	a0,a1
	lea	lbL000C80(pc),a2
	move.l	a1,(a2)
	move.l	$0018(a0),a1
	add.l	a0,a1
	lea	lbL000C70(pc),a2
	move.l	a1,(a2)
	move.l	$001C(a0),a1
	add.l	a0,a1
	lea	lbL000C78(pc),a2
	tst.l	(a2)
	bne.s	lbC0000D6
	move.l	a1,(a2)
lbC0000D6
	rts

lbC0000D8
	movem.l	d0-d7/a0-a6,-(sp)
	moveq	#$00,d7
	move.w	lbW000A8E(pc),d0
	beq.s	lbC00010A
	move.w	#$000F,$00DFF096
	move.l	d7,$00DFF0A6
	move.l	d7,$00DFF0B6
	move.l	d7,$00DFF0C6
	move.l	d7,$00DFF0D6
	movem.l	(sp)+,d0-d7/a0-a6
	rts

lbC00010A
	lea	$00DFF000,a6
	lea	lbW000A92(pc),a5
	move.w	d7,(a5)
	lea	Channel1Data(pc),a0
	bsr.w	lbC000552
	move.l	d0,-(sp)
	lea	Channel2Data(pc),a0
	bsr.w	lbC000552
	move.l	d0,-(sp)
	lea	Channel3Data(pc),a0
	bsr.w	lbC000552
	move.l	d0,-(sp)
	lea	Channel4Data(pc),a0
	bsr.w	lbC000552
	move.l	d0,-(sp)
	move.w	(a5),d7
	beq.b	lbC00027C
	or.w	#$8000,d7
	move.l	lbL000AA4(pc),a0
	move.w	lbW000ACC(pc),d0
	move.l	lbL000AFA(pc),a1
	move.w	lbW000B22(pc),d1
	move.l	lbL000B50(pc),a2
	move.w	lbW000B78(pc),d2
	move.l	lbL000BA6(pc),a3
	move.w	lbW000BCE(pc),d3
	bsr.b	lbC0002C0
	move.w	d7,$0096(a6)
	bsr.b	lbC0002C0
	move.l	(sp)+,$00D6(a6)
	move.l	(sp)+,$00C6(a6)
	move.l	(sp)+,$00B6(a6)
	move.l	(sp)+,$00A6(a6)
	move.l	a0,$00A0(a6)
	move.w	d0,$00A4(a6)
	move.l	a1,$00B0(a6)
	move.w	d1,$00B4(a6)
	move.l	a2,$00C0(a6)
	move.w	d2,$00C4(a6)
	move.l	a3,$00D0(a6)
	move.w	d3,$00D4(a6)
	bra.s	lbC00028C

lbC00027C
	move.l	(sp)+,$00D6(a6)
	move.l	(sp)+,$00C6(a6)
	move.l	(sp)+,$00B6(a6)
	move.l	(sp)+,$00A6(a6)
lbC00028C
	lea	lbW000A8A(pc),a0
	subq.w	#$01,(a0)+
	bne.s	lbC0002BA
	move.w	(a0),-(a0)
	moveq	#$00,d5
	moveq	#$06,d6
	lea	Channel1Data(pc),a0
	bsr.b	lbC0002D0
	lea	Channel2Data(pc),a0
	bsr.b	lbC0002D0
	lea	Channel3Data(pc),a0
	bsr.b	lbC0002D0
	lea	Channel4Data(pc),a0
	bsr.b	lbC0002D0
lbC0002BA
	movem.l	(sp)+,d0-d7/a0-a6
lbC0002BE
	rts

lbC0002C0
	move.l	a0,-(sp)			; added by Delirium
	move.l	dmawait(pc),a0
	jsr	(a0)
	move.l	(sp)+,a0
	rts

	
lbC0002D0
	subq.b	#$01,$003C(a0)
	bpl.s	lbC0002BE
	move.b	$003D(a0),$003C(a0)
lbC0002DC
	move.l	$0018(a0),a1
lbC0002E0
	move.b	(a1)+,d0
	cmp.b	#$FF,d0
	bne.w	lbC000380
	move.l	$0008(a0),a3
	move.l	$0004(a0),a2
	add.w	$003A(a0),a2
	cmp.l	a3,a2
	bne.s	lbC000302
	move.w	d5,$003A(a0)

	move.l	a0,-(sp)
	move.l	songend(pc),a0
	st	(a0)
;	move.l	delibase(pc),a0
;	move.l	dtg_SongEnd(a0),a0
;	jsr	(a0)
	move.l	(sp)+,a0

	move.l	$0004(a0),a2
lbC000302
	moveq	#$00,d1
	moveq	#$00,d2
	move.b	(a2)+,d1
	move.b	(a2)+,$004E(a0)
	move.b	(a2),d2
	cmp.w	#$007F,d2
	ble.s	lbC000360
	move.b	d2,d3
	lsr.w	#$04,d3
	and.w	#$000F,d3
	and.w	#$000F,d2
	cmp.b	#$0F,d3
	bne.s	lbC000340
	moveq	#$64,d3
	tst.w	d2
	beq.s	lbC00033A
	moveq	#$0F,d3
	sub.w	d2,d3
	addq.w	#$01,d3
	add.w	d3,d3
	move.w	d3,d2
	add.w	d3,d3
	add.w	d2,d3
lbC00033A
	move.b	d3,$0051(a0)
	bra.s	lbC000364

lbC000340
	cmp.b	#$08,d3
	bne.s	lbC00034E
	lea	lbW000A8E(pc),a2		; Flag: Songend reached
	st	(a2)

	move.l	a0,-(sp)
	move.l	songend(pc),a0
	st	(a0)
;	move.l	delibase(pc),a0
;	move.l	dtg_SongEnd(a0),a0
;	jsr	(a0)
	move.l	(sp)+,a0

	bra.s	lbC000364

lbC00034E
	cmp.b	#$0E,d3
	bne.s	lbC00035E
	and.w	#$000F,d2
	lea	lbW000A8C(pc),a2
	move.w	d2,(a2)
lbC00035E
	bra.s	lbC000364

lbC000360
	move.b	d2,$0043(a0)
lbC000364
	add.w	d1,d1
	move.l	lbL000C58(pc),a3
	add.w	d1,a3
	move.w	(a3),a3
	add.l	lbL000C84(pc),a3
	move.l	a3,$0018(a0)
	add.w	#$000C,$003A(a0)
	bra.w	lbC0002DC

lbC000380
	cmp.b	#$FE,d0
	bne.s	lbC000392
	move.b	(a1),$003D(a0)
	move.b	(a1)+,$003C(a0)
	bra.w	lbC0002E0

lbC000392
	cmp.b	#$FD,d0
	bne.s	lbC0003A6
	move.b	(a1),$003D(a0)
	move.b	(a1)+,$003C(a0)
	move.l	a1,$0018(a0)
	rts

lbC0003A6
	move.b	d0,$0041(a0)
	move.b	(a1)+,d1
	move.b	d1,$0042(a0)
	and.w	#$00E0,d1
	beq.s	lbC0003BA
	move.b	(a1)+,$004B(a0)
lbC0003BA
	move.l	a1,$0018(a0)
	move.w	d5,$001C(a0)
	tst.b	d0
	bmi.b	lbC000440
	move.b	$0042(a0),d1
	and.w	#$001F,d1
	add.b	$0043(a0),d1
	move.l	lbL000C64(pc),a2
	add.w	d1,d1
	add.w	d1,a2
	move.w	(a2),a2
	add.l	lbL000C84(pc),a2
	move.w	d5,$0038(a0)
	move.b	(a2),$0044(a0)
	move.b	(a2)+,$0045(a0)
	moveq	#$00,d1
	move.b	(a2)+,d1
	move.b	(a2)+,$0048(a0)
	moveq	#$00,d0
	move.b	#$40,$0050(a0)
	move.b	(a2)+,d0
	move.b	d0,$0049(a0)
	move.b	d0,$0040(a0)
	move.b	(a2)+,$004A(a0)
	move.l	a2,$0010(a0)
	move.b	d5,$0046(a0)
	cmp.b	#$80,d1
	beq.s	lbC000440
	move.l	lbL000C5C(pc),a2
	btst	#$06,$0042(a0)
	beq.s	lbC00042A
	move.b	$004B(a0),d1
lbC00042A
	add.w	d1,d1
	add.w	d1,a2
	move.w	(a2),a2
	add.l	lbL000C84(pc),a2
	move.l	a2,$0014(a0)
	move.w	d5,$0036(a0)
	move.b	d5,$0047(a0)
lbC000440
	rts

lbC000442
	moveq	#$00,d5
	lea	$00DFF000,a6
	move.w	#$000F,$0096(a6)
;	move.w	#$0780,$009A(a6)
	move.l	d0,d7
	mulu	#$000C,d7
	move.l	d1,d6
	addq.l	#$01,d6
	mulu	#$000C,d6
	moveq	#$03,d0
	lea	Channel1Data(pc),a0
	lea	lbL000A6C(pc),a1
	lea	lbL000C46(pc),a2
lbC000476
	sf	$0052(a0)
	move.l	a1,$0010(a0)
	move.l	a1,$0014(a0)
	move.b	#$01,$0044(a0)
	move.b	#$01,$0045(a0)
	sf	$0046(a0)
	move.w	d5,$0038(a0)
	sf	$0047(a0)
	sf	$0048(a0)
	sf	$0049(a0)
	sf	$0032(a0)
	sf	$0053(a0)
	move.b	d5,$0040(a0)
	sf	$004A(a0)
	sf	$004B(a0)
	move.b	#$64,$0051(a0)
	st	$004C(a0)
	st	$003C(a0)
	sf	$004D(a0)
	sf	$004F(a0)
	move.w	d5,$0036(a0)
	move.w	d5,$001C(a0)
	move.w	d5,$0034(a0)
	move.l	(a2)+,d1
	move.l	(a2)+,d3
	divu	#$0003,d3
	moveq	#$00,d4
	bset	d3,d4
	move.w	d4,$003E(a0)
	mulu	#$0003,d3
	and.l	#$000000FF,d3
	and.l	#$000000FF,d1
	add.l	a6,d1
	move.l	d1,a4
	move.l	lbL000C78(pc),(a4)+
	move.w	#$0001,(a4)+
	move.w	d5,(a4)+
	move.w	d5,(a4)+
	move.l	d1,$0000(a0)
	lea	lbW000550(pc),a3
	move.l	a3,$0018(a0)
	move.l	lbL000C6C(pc),$0004(a0)
	move.l	lbL000C6C(pc),$0008(a0)
	add.l	d6,$0008(a0)
	add.l	d3,$0008(a0)
	add.l	d7,$0004(a0)
	add.l	d3,$0004(a0)
	move.w	d5,$003A(a0)
	lea	$0056(a0),a0
	dbra	d0,lbC000476
	lea	lbW000A8A(pc),a0
	move.w	#$0001,(a0)
	move.w	d5,$0004(a0)
	move.w	d5,$0006(a0)
	rts

lbW000550
	dc.w	$FFFF

lbC000552
	tst.b	$0047(a0)
	beq.s	lbC000560			* get new note?
	subq.b	#$01,$0047(a0)		* speed counter?
	bra.w	lbC00084E

lbC000560
	move.l	$0014(a0),a1		* pattern pointer?
	add.w	$0036(a0),a1		* pattern pos?
lbC000568
	moveq	#$00,d0
	move.b	(a1)+,d0
	cmp.w	#$00E0,d0
	blt.w	lbC000846
	sub.w	#$00E0,d0
	add.w	d0,d0
	move.w	lbW000582(pc,d0.w),d0
	jmp	lbC000598(pc,d0.w)

lbW000582
	dc.w	lbC0005BE-lbC000598
	dc.w	lbC00084E-lbC000598
	dc.w	lbC00079C-lbC000598
	dc.w	lbC0005B0-lbC000598
	dc.w	lbC000804-lbC000598
	dc.w	lbC0006DA-lbC000598
	dc.w	lbC000770-lbC000598
	dc.w	lbC0005CE-lbC000598
	dc.w	lbC0005A6-lbC000598
	dc.w	lbC00063C-lbC000598
	dc.w	lbC000598-lbC000598

lbC000598
	move.b	(a1)+,$0053(a0)
	sf	$0054(a0)
	addq.w	#$02,$0036(a0)		* increment pattern pos?
	bra.s	lbC000568

lbC0005A6
	move.b	(a1)+,$0047(a0)
	addq.w	#$02,$0036(a0)
	bra.s	lbC000552

lbC0005B0
	addq.w	#$03,$0036(a0)
	move.b	(a1)+,$0048(a0)
	move.b	(a1)+,$0049(a0)
	bra.s	lbC000568

lbC0005BE
	moveq	#$00,d0
	move.b	(a1)+,d0
	move.w	d0,$0036(a0)
	move.l	$0014(a0),a1
	add.w	d0,a1
	bra.s	lbC000568

lbC0005CE
	moveq	#$00,d1
	move.b	(a1)+,d1
	cmp.b	$004C(a0),d1
	beq.s	lbC000626
	sf	$0053(a0)
	move.b	d1,$004C(a0)
	move.w	d0,-(sp)
	move.w	$003E(a0),d0
	or.w	d0,(a5)
	move.w	d0,$00DFF096
	move.w	(sp)+,d0
	move.l	lbL000C70(pc),a4
	move.w	d1,d3
	lsl.w	#$03,d1
	add.w	d3,d3
	add.w	d3,d1
	add.w	d1,a4
	move.l	$0000(a4),a2
	add.l	lbL000C78(pc),a2
	move.l	$0000(a0),a3
	move.l	a2,(a3)+
	move.w	$0004(a4),(a3)+
	move.w	#$0004,(a3)+
	moveq	#$00,d1
	move.w	$0006(a4),d1
	add.l	d1,a2
	move.l	a2,$000C(a0)
	move.w	$0008(a4),$0034(a0)
lbC000626
	move.w	d7,$0038(a0)
	move.b	#$01,$0044(a0)
	addq.w	#$02,$0036(a0)
	sf	$0032(a0)
	bra.w	lbC000568

lbC00063C
	sf	$0053(a0)
	st	$004C(a0)
	move.w	d0,-(sp)
	move.w	$003E(a0),d0
	or.w	d0,(a5)
	move.w	d0,$00DFF096
	move.w	(sp)+,d0
	moveq	#$00,d1
	move.b	(a1)+,d1
	move.l	lbL000C70(pc),a4
	move.w	d1,d3
	lsl.w	#$03,d1
	add.w	d3,d3
	add.w	d3,d1
	add.w	d1,a4
	move.l	$0000(a4),a2
	add.l	lbL000C78(pc),a2
	moveq	#$00,d0
	move.w	$0004(a2),d0
	move.w	$0006(a2),d2
	lsl.w	#$02,d2
	mulu	#$0018,d0
	addq.l	#$08,a2
	move.l	a2,a4
	add.l	d0,a2
	add.w	d2,a2
	moveq	#$00,d1
	move.b	(a1)+,d1
	mulu	#$0018,d1
	add.l	d1,a4
	move.l	(a4)+,d1
	move.l	(a4)+,d2
	and.l	#$FFFFFFFE,d1
	and.l	#$FFFFFFFE,d2
	sub.l	d1,d2
	lsr.l	#$01,d2
	add.l	a2,d1
	move.l	$0000(a0),a3
	move.l	d1,(a3)+
	move.w	d2,(a3)+
	move.w	#$0004,(a3)
	move.l	d1,$000C(a0)
	pea	(a2)
	move.l	d1,a2
	move.b	(a2)+,(a2)
	move.l	(sp)+,a2
	moveq	#$01,d1
	move.w	d1,$0034(a0)
	move.w	d7,$0038(a0)
	move.b	#$01,$0044(a0)
	addq.w	#$03,$0036(a0)
	sf	$0032(a0)
	bra.w	lbC000568

lbC0006DA
	sf	$0053(a0)
	move.w	d0,-(sp)
	move.w	$003E(a0),d0
	or.w	d0,(a5)
	move.w	d0,$00DFF096
	move.w	(sp)+,d0
	move.l	$0000(a0),a3
	move.w	#$0004,$0006(a3)
	moveq	#$00,d1
	move.b	(a1)+,d1
	move.l	lbL000C70(pc),a4
	move.w	d1,d3
	lsl.w	#$03,d1
	add.w	d3,d3
	add.w	d3,d1
	add.w	d1,a4
	move.l	$0000(a4),a2
	move.l	a2,$001E(a0)
	moveq	#$00,d0
	move.w	$0004(a4),d0
	move.w	d0,d1
	add.l	d0,d0
	add.l	d0,a2
	move.l	a2,$0022(a0)
	move.b	(a1)+,-(sp)
	move.w	(sp)+,d0
	move.b	(a1)+,d0
	cmp.w	#$FFFF,d0
	bne.s	lbC000730
	move.w	d1,d0
lbC000730
	move.w	d0,$0026(a0)
	move.b	(a1)+,-(sp)
	move.w	(sp)+,d0
	move.b	(a1)+,d0
	move.w	d0,$002A(a0)
	move.b	(a1)+,-(sp)
	move.w	(sp)+,d0
	move.b	(a1)+,d0
	move.w	d0,$0028(a0)
	sf	$0030(a0)
	move.b	(a1)+,$0031(a0)
	sf	$0033(a0)
	sf	$002C(a0)
	st	$0032(a0)
	move.w	d7,$0038(a0)
	move.b	#$01,$0044(a0)
	add.w	#$0009,$0036(a0)
	bra.w	lbC000568

lbC000770
	move.b	(a1)+,-(sp)
	move.w	(sp)+,d0
	move.b	(a1)+,d0
	move.w	d0,$002A(a0)
	move.b	(a1)+,-(sp)
	move.w	(sp)+,d0
	move.b	(a1)+,d0
	move.w	d0,$0028(a0)
	sf	$0030(a0)
	move.b	(a1)+,$0031(a0)
	sf	$002C(a0)
	sf	$0033(a0)
	addq.w	#$06,$0036(a0)
	bra.w	lbC000568

lbC00079C
	sf	$0053(a0)
	st	$004C(a0)
	move.w	d0,-(sp)
	move.w	$003E(a0),d0
	or.w	d0,(a5)
	move.w	d0,$00DFF096
	move.w	(sp)+,d0
	moveq	#$00,d1
	move.b	(a1)+,d1
	move.l	lbL000C70(pc),a4
	move.w	d1,d3
	lsl.w	#$03,d1
	add.w	d3,d3
	add.w	d3,d1
	add.w	d1,a4
	move.l	$0000(a4),a2
	add.l	lbL000C78(pc),a2
	move.l	$0000(a0),a3
	move.l	a2,(a3)+
	move.w	$0004(a4),(a3)+
	move.w	#$0004,(a3)
	moveq	#$00,d1
	move.w	$0006(a4),d1
	add.l	d1,a2
	move.l	a2,$000C(a0)
	move.w	$0008(a4),$0034(a0)
	move.w	d7,$0038(a0)
	move.b	#$01,$0044(a0)
	addq.w	#$02,$0036(a0)
	sf	$0032(a0)
	bra.w	lbC000568

lbC000804
	moveq	#$00,d1
	move.b	(a1)+,d1
	move.l	lbL000C70(pc),a4
	move.w	d1,d3
	lsl.w	#$03,d1
	add.w	d3,d3
	add.w	d3,d1
	add.w	d1,a4
	move.l	$0000(a4),a2
	add.l	lbL000C78(pc),a2
	move.l	$0000(a0),a3
	move.l	a2,(a3)+
	moveq	#$00,d1
	move.w	$0006(a4),d1
	add.l	d1,a2
	move.l	a2,$000C(a0)
	move.w	$0004(a4),(a3)
	move.w	$0008(a4),$0034(a0)
	addq.w	#$02,$0036(a0)
	sf	$0032(a0)
	bra.w	lbC000568

lbC000846
	move.b	d0,$004D(a0)
	addq.w	#$01,$0036(a0)		* increment patt pos?
lbC00084E
	tst.b	$0032(a0)
	beq.b	lbC0008D2
	tst.b	$0033(a0)
	bne.b	lbC0008D2
	subq.b	#$01,$0030(a0)
	bpl.b	lbC0008D2
	move.b	$0031(a0),$0030(a0)
	move.l	$001E(a0),a1
	move.l	$0022(a0),a2
	moveq	#$00,d0
	move.w	$0026(a0),d0
	move.w	$0028(a0),d1
	move.w	$002A(a0),d2
	tst.b	$002C(a0)
	bne.s	lbC00088E
	st	$002C(a0)
	bra.s	lbC0008B6

lbC00088E
	ext.l	d1
	add.l	d1,d0
	bpl.s	lbC00089C
	st	$0033(a0)
	sub.l	d1,d0
	bra.s	lbC0008B6

lbC00089C
	move.l	a1,a3
	move.l	d0,d3
	add.l	d3,d3
	add.l	d3,a3
	moveq	#$00,d3
	move.w	d2,d3
	add.l	d3,d3
	add.l	d3,a3
	cmp.l	a2,a3
	ble.s	lbC0008B6
	st	$0033(a0)
	sub.l	d1,d0
lbC0008B6
	move.w	d0,$0026(a0)
	add.l	lbL000C78(pc),a1
	add.l	d0,d0
	add.l	d0,a1
	move.w	d2,$0034(a0)
	move.l	a1,$000C(a0)
	move.l	$0000(a0),a2
	move.l	a1,(a2)+
	move.w	d2,(a2)+
lbC0008D2
	tst.b	$0046(a0)
	beq.s	lbC0008DE
	subq.b	#$01,$0046(a0)
	bra.s	lbC00093C

lbC0008DE
	subq.b	#$01,$0044(a0)
	bne.s	lbC00093C
	move.b	$0045(a0),$0044(a0)
lbC0008EA
	move.l	$0010(a0),a1
	add.w	$0038(a0),a1
	moveq	#$00,d0
	move.b	(a1)+,d0
	cmp.w	#$00E0,d0
	blt.s	lbC000934
	sub.w	#$00E0,d0
	add.w	d0,d0
	move.w	lbW00090A(pc,d0.w),d0
	jmp	lbC00091C(pc,d0.w)

lbW00090A
	dc.w	lbC000926-lbC00091C
	dc.w	lbC000932-lbC00091C
	dc.w	lbC000932-lbC00091C
	dc.w	lbC000932-lbC00091C
	dc.w	lbC000932-lbC00091C
	dc.w	lbC000932-lbC00091C
	dc.w	lbC000932-lbC00091C
	dc.w	lbC000932-lbC00091C
	dc.w	lbC00091C-lbC00091C

lbC00091C
	move.b	(a1),$0046(a0)
	addq.w	#$02,$0038(a0)
	bra.s	lbC0008D2

lbC000926
	moveq	#$00,d0
	move.b	(a1),d0
	subq.w	#$05,d0
	move.w	d0,$0038(a0)
	bra.s	lbC0008EA

lbC000932
	bra.s	lbC00093C

lbC000934
	move.b	d0,$004F(a0)
	addq.w	#$01,$0038(a0)
lbC00093C
	move.b	$004D(a0),d0
	bmi.s	lbC00094A
	add.b	$0041(a0),d0
	add.b	$004E(a0),d0
lbC00094A
	and.w	#$007F,d0
	lea	lbW000C8E(pc),a1
	add.w	d0,d0
	move.w	$00(a1,d0.w),d0
	moveq	#$0A,d2
	tst.b	$004A(a0)
	beq.s	lbC000966
	subq.b	#$01,$004A(a0)
	bra.s	lbC0009AE

lbC000966
	moveq	#$00,d1
	moveq	#$00,d4
	moveq	#$00,d5
	move.b	$0050(a0),d6
	move.b	$0049(a0),d4
	move.b	$0048(a0),d5
	move.b	$0040(a0),d1
	btst	#$05,d6
	bne.s	lbC00098E
	sub.w	d5,d1
	bpl.s	lbC00099A
	bset	#$05,d6
	moveq	#$00,d1
	bra.s	lbC00099A

lbC00098E
	add.w	d5,d1
	cmp.w	d4,d1
	ble.s	lbC00099A
	bclr	#$05,d6
	move.w	d4,d1
lbC00099A
	move.b	d1,$0040(a0)
	move.b	d6,$0050(a0)
	lsr.w	#$01,d4
	sub.w	d4,d1
	ext.l	d1
	muls	d0,d1
	asr.l	d2,d1
	add.l	d1,d0
lbC0009AE
	btst	#$05,$0042(a0)
	beq.s	lbC0009DE
	moveq	#$00,d1
	move.b	$004B(a0),d1
	bmi.s	lbC0009CE
	add.w	d1,$001C(a0)
	move.w	$001C(a0),d1
	mulu	d0,d1
	lsr.l	d2,d1
	sub.w	d1,d0
	bra.s	lbC0009DE

lbC0009CE
	neg.b	d1
	add.w	d1,$001C(a0)
	move.w	$001C(a0),d1
	mulu	d0,d1
	lsr.l	d2,d1
	add.w	d1,d0
lbC0009DE
	move.w	d0,$002E(a0)
	tst.b	$0052(a0)
	beq.s	lbC0009F8
	move.l	$0000(a0),a3
	move.w	#$0001,$0006(a3)
	move.w	#$0000,$000A(a3)
lbC0009F8
	swap	d0
	moveq	#$00,d1
	moveq	#$00,d2
	move.b	$004F(a0),d2
	move.b	$0051(a0),d1
	sub.w	lbW000C8A(pc),d1
	moveq	#$00,d3
	move.b	$0053(a0),d3
	beq.s	lbC000A40
	moveq	#$00,d4
	move.b	$0054(a0),d4
	bne.s	lbC000A3C
	sf	$0053(a0)
	move.w	d7,-(sp)
	bsr.b	lbC000A50
	and.w	#$00FF,d7
	mulu	d7,d3
	divu	#$00FF,d3
	move.b	d3,$0054(a0)
	move.w	d3,d4
lbC000A3C
	sub.w	d4,d1
	move.w	(sp)+,d7
lbC000A40
	tst.w	d1
	bpl.s	lbC000A46
	moveq	#$00,d1
lbC000A46
	mulu	d1,d2
	divu	#$0064,d2
lbC000A4C
	move.w	d2,d0
	rts

lbC000A50
	pea	(a0)
	move.w	d6,-(sp)
	lea	lbW000A90(pc),a0
	move.w	(a0),d7
	add.w	#$4793,d7
	move.w	d7,d6
	ror.w	#$06,d7
	eor.w	d6,d7
	move.w	d7,(a0)
	move.w	(sp)+,d6
	move.l	(sp)+,a0
	rts

lbL000A6C
	dc.l	$01000000			; Empty Track ?
	dc.l	$000000E1
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
lbW000A8A
	dc.w	$0000
lbW000A8C
	dc.w	$0000
lbW000A8E
	dc.w	$0000
lbW000A90
	dc.w	$0000
lbW000A92
	dc.w	$0000
Channel1Data
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
lbL000AA4
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
lbW000ACC
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
Channel2Data
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
lbL000AFA
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
lbW000B22
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
Channel3Data
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
lbL000B50
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
lbW000B78
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
Channel4Data
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
lbL000BA6
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
lbW000BCE
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
	dc.w	$0000
lbL000C46
	dc.l	$000000A0
	dc.l	$00000000
	dc.l	$000000B0
	dc.l	$00000003
	dc.l	$000000C0
	dc.l	$00000006
	dc.l	$000000D0
	dc.l	$00000009
lbL000C56
	dc.w	$0040				; (unused) !!!
lbL000C58
	dc.l	$00000000
lbL000C5C
	dc.l	$00000000
lbL000C60
	dc.l	$00000000
lbL000C64
	dc.l	$00000000
lbL000C68
	dc.l	$00000000
lbL000C6C
	dc.l	$00000000
lbL000C70
	dc.l	$00000000
lbL000C74
	dc.l	$00000000
lbL000C78
	dc.l	$00000000
lbL000C7C
	dc.l	$00000000
lbL000C80
	dc.l	$00000000
lbL000C84
	dc.l	$00000000
lbW000C8A
	dc.w	$0000
lbW000C8E
	dc.w	$06B0
	dc.w	$0650
	dc.w	$05F4
	dc.w	$05A0
	dc.w	$054C
	dc.w	$0500
	dc.w	$04B8
	dc.w	$0474
	dc.w	$0434
	dc.w	$03F8
	dc.w	$03C0
	dc.w	$038A
	dc.w	$0358
	dc.w	$0328
	dc.w	$02FA
	dc.w	$02D0
	dc.w	$02A6
	dc.w	$0280
	dc.w	$025C
	dc.w	$023A
	dc.w	$021A
	dc.w	$01FC
	dc.w	$01E0
	dc.w	$01C5
	dc.w	$01AC
	dc.w	$0194
	dc.w	$017D
	dc.w	$0168
	dc.w	$0153
	dc.w	$0140
	dc.w	$012E
	dc.w	$011D
	dc.w	$010D
	dc.w	$00FE
	dc.w	$00F0
	dc.w	$00E2
	dc.w	$00D6
	dc.w	$00CA
	dc.w	$00BE
	dc.w	$00B4
	dc.w	$00AA
	dc.w	$00A0
	dc.w	$0097
	dc.w	$008F
	dc.w	$0087
	dc.w	$007F
	dc.w	$0078
	dc.w	$0071
	dc.w	$0071
	dc.w	$0071
	dc.w	$0071
	dc.w	$0071
	dc.w	$0071
	dc.w	$0071
	dc.w	$0071
	dc.w	$0071
	dc.w	$0071
	dc.w	$0071
	dc.w	$0071
	dc.w	$0071
	dc.w	$0D60
	dc.w	$0CA0
	dc.w	$0BE8
	dc.w	$0B40
	dc.w	$0A98
	dc.w	$0A00
	dc.w	$0970
	dc.w	$08E8
	dc.w	$0868
	dc.w	$07F0
	dc.w	$0780
	dc.w	$0714

 ifne testi

	section	da,data_c

module	incbin	music:hip/HIPC.lethalexcess-level1
modulee

 endc
 
