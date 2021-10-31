;APS0000005F0000005F0000005F0000005F0000005F0000005F0000005F0000005F0000005F0000005F

		incdir	"INCLUDE:"
		include "exec/exec_lib.i"
		include	"exec/memory.i"
		include "mucro.i"
test=0

 ifne test
bob
;	lea	module,a0
;	jsr	Check2

	* initial song number
	lea	module,a0
	lea	masterVol,a1
	lea	songend,a2
	lea	maxpat,a3
	lea	curpat,a4
	jsr	init
	bne.b	error

	bsr.b	playLoop
	jsr	end
error
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


masterVol 	dc $40/1
songend		dc 0
maxpat		dc 0
curpat		dc 0

	SECTION	modu,data_c

module  incbin	"sys:Music/Roots/Modules/GlueMon/- unknown/giana sisters.glue"
 endif


*** NAME:	GlueMon v1.13 - Deliplayer version
*** 
*** AUTHOR:	Original replay (c) 1990 by GlueMaster / Northstar (Lars Malmborg)
*** 		Resourced and Deli-adapted by [·M·n·O·] (Lasse Jari Hansen)
***
*** E-MAIL:	ljh@sigma.ou.dk
***
*** HISTORY:	19-Nov-96 : 2. Aminet release.
***		17-Nov-96 : Changed entrire replay code from
***			    absolute to register-relative addressing.
***			  : Removed all self-modifying code.
*** 		08-Nov-96 : 1. Aminet release.
***		21-Oct-96 : Deli-adaption (Volume/Balance/Songend).
***		   Feb-92 : Stinger-adaption.
***		   Jan-92 : Original resourced.
***
*** INFO:	Text from Gluemaster's original replay routine:
***
***		GLUE MASTER'S SMALLER SIZE TUNE PLAYER
***		CREATED TO FIT IN A BOOT-INTRO !!!
***		MODIFIED 26/2-90 TO BE EVEN SHORTER ...
***		AND RE-ORGANIZED 25/6-90 TO SUPPLY A MODULE-FORMAT!!!
***		FURTHER MORE DEVELOPED TO PLAY DRUMS 31/8-90!!!
***
***		SPECIAL REPLAYER FOR BOTH WITH & WITHOUT DRUMS!
***		THIS IS THE REPLAY-SOURCE FOR THE MUSIC-DISK 'HIS MASTERS NOISE'!
***
***		© 1990 GLUE MASTER
***
***
***		This release includes the 10 tunes used in the reset
***		part of `His Master's Noise'
***
***			Bestick
***			Game Music 1
***			Gnu-Song
***			Gurksaft
***			Jobba
***			Loader
***			Popcorn
***			Songname
***			Trudelut
***			Woodsock
***
***		plus 6 "new" tunes, sent in by Gluemaster himself
***
***			Flood
***			Juice
***			Knytning
***			Latch
***			Memphis
***			Slugaren
***
***		ALL tunes are (c) by Gluemaster!
***
***		Credits must go to Gluemaster, for reporting/fixing
***		cache problems, the new tunes and ofcourse for
***		doing the darn thing in the first place!
***
***		Source released for educational purposes.
***		Feel free to contact me for bug reports or help.
***



;pl_ver		=	1
;pl_rev		=	13

;DTP_GetNumPatterns	=	$8000448a

		SECTION Player,Code

	jmp init(pc)
	jmp play(pc)
	jmp end(pc)

masterVolumeAddr 	dc.l 0
songEndAddr		dc.l 0
maxPattAddr		dc.l 0
curPattAddr		dc.l 0
chipData		dc.l 0
mus_rndwaveAddr		dc.l 0
mus_clrwaveAddr		dc.l 0
* a0 = mod
* a1 = master vol Address
* a2 = songend addr
init
	move.l a0,d7
	move.l a1,masterVolumeAddr
	move.l a2,songEndAddr
	move.l a3,maxPattAddr
	move.l a4,curPattAddr

	move.l	#chipDataEnd-chipDataStart,d0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	lore	Exec,AllocMem
	move.l	d0,chipData
	beq.b	.err

	move.l	d0,a0
	move.l	a0,mus_rndwaveAddr
	lea	32(a0),a0
	move.l	a0,mus_clrwaveAddr
	lea	mus_clrwave(pc),a1
	moveq	#32-1,d0
.c	move.b	(a1)+,(a0)+
	dbf	d0,.c

	move.l	d7,a0
	bsr.b	InitPlayer
	bsr.b	InitSnd
	bsr.w	get_patts
	move.l	maxPattAddr(pc),a0
	move	d0,(a0)
	moveq	#0,d0
	rts
.err
	moveq	#-1,d0
	rts
play
	bsr.w SetVol
	bsr.b Int
	move.l	curPattAddr(pc),a0
	move.l	mus_stuff_adr(pc),a1
	move	mus_modsong(a1),(a0)
	rts

end
	move.l chipData(pc),a1
	move.l	#chipDataEnd-chipDataStart,d0
	lore Exec,FreeMem
	rts

;start		PLAYERHEADER PlayerTagArray
;
;		dc.b '$VER: GlueMon player module V1.13 '
;		dc.b '(17-Nov-96)'
;		dc.b 0
;		even
;
;PlayerTagArray	dc.l	DTP_RequestDTVersion,16
;		dc.l	DTP_PlayerVersion,(pl_ver<<16)+pl_rev
;		dc.l	DTP_PlayerName,dat_PlayerName
;		dc.l	DTP_Creator,dat_CreatorName
;		dc.l	DTP_DeliBase,dat_delibase
;		dc.l	DTP_Check2,Chk
;		dc.l	DTP_CheckLen,ChkLen
;		dc.l	DTP_Flags,PLYF_SONGEND
;		dc.l	DTP_Interrupt,Int
;		dc.l	DTP_InitPlayer,InitPlayer
;		dc.l	DTP_EndPlayer,EndPlayer
;		dc.l	DTP_InitSound,InitSnd
;		dc.l	DTP_EndSound,EndSnd
;		dc.l	DTP_Volume,SetVol
;		dc.l	DTP_Balance,SetVol
;
;		dc.l	DTP_ModuleName,dat_modname
;		dc.l	DTP_GetNumPatterns,get_patts
;		dc.l	TAG_DONE

*-----------------------------------------------------------------------*
;
; Player/Creatorname

;dat_PlayerName	dc.b 'GlueMon',0
;dat_CreatorName	dc.b 'GlueMaster / Northstar,',10
;		dc.b 'optimized and adapted by [·M·n·O·]',0
;		even
;dat_delibase	dc.l 0
;dat_modname	dc.l	mus_stuff+mus_modname
;
;*-----------------------------------------------------------------------*
;;
;; Test the module
;
;Chk		move.l	dtg_ChkData(a5),a0	; GlueMon ?
;		moveq	#-1,d0			; module unknown (default)
;		cmp.l	#$474C5545,(a0)		; "GLUE"
;		bne.s	.ChkEnd
;		cmp.l	#~$474C5545,4(a0)	; ~"GLUE"
;		bne.s	.ChkEnd
;		moveq	#0,d0			; module recognised
;.ChkEnd		rts
;
;ChkLen	=	*-Chk				; DELI copies routine ?

*-----------------------------------------------------------------------*
;
; Interrupt for Replay

Int		movem.l	d0-a6,-(sp)
		bsr.w	glue_music
		movem.l	(sp)+,d0-a6
		rts

InitPlayer	move.l	mus_stuff_adr(pc),a4

	;	moveq	#0,d0
;		move.l	dtg_GetListData(a5),a0	; Function
;		jsr	(a0)

		addq.l	#8,a0			;GLUE + ~GLUE
		move.l	a0,mus_data(a4)		;set module
		lea	mus_modname(a4),a1
		moveq	#8-1,d0
.movname	move.b	(a0)+,(a1)+
		dbra	d0,.movname

		;move.l	dtg_AudioAlloc(a5),a0	; Function
		;jsr	(a0)			; returncode is already set !
		rts

EndPlayer	
		;move.l	dtg_AudioFree(a5),a0	; Function
		;jsr	(a0)
		rts

InitSnd		movem.l	d0-a6,-(sp)
		move.l	mus_stuff_adr(pc),a4
		sf	mus_songendflag(a4)
		bsr.w	glue_init
		movem.l	(sp)+,d0-a6
		rts

EndSnd		movem.l	d0-a6,-(sp)
		lea	$dff000,a6
		moveq	#0,d0
		move	d0,$a8(a6)
		move	d0,$b8(a6)
		move	d0,$c8(a6)
		move	d0,$d8(a6)
		move	#$f,$96(a6)
		movem.l	(sp)+,d0-a6
		rts

SetVol		
		move.l	mus_stuff_adr(pc),a4
		move.l	masterVolumeAddr(pc),a0
		move	(a0),mus_vol(a4)
		;move	dtg_SndVol(a5),mus_vol(a4)
		;move	dtg_SndLBal(a5),mus_lbal(a4)
		;move	dtg_SndRBal(a5),mus_rbal(a4)
		rts

get_patts	movem.l	d1-a6,-(sp)
		move.l	mus_stuff_adr(pc),a4
		move.l	mus_data(a4),a0
		lea	151(a0),a1
		moveq	#0,d0
.setbigpat	cmp.b	(a1)+,d0
		bhs.s	.sbploop
		move.b	-1(a1),d0
.sbploop	cmp.b	#$ff,(a1)
		bne.s	.setbigpat
		addq	#1,d0
		movem.l	(sp)+,d1-a6
		rts

*-----------------------------------------------------------------------*
;
; The actual replay ... "somewhat" modified.

		RSRESET
mus_drumrate	rs.w	1	;offsets for original glue data
mus_drumpitch	rs.w	1
mus_seed	rs.l	1
mus_extwave	rs.l	1
mus_vol1	rs.w	1
mus_vol2	rs.w	1
mus_vol3	rs.w	1
mus_vol4	rs.w	1
mus_waitpos	rs.b	1
		rs.b	1	;(pad)
mus_currpat	rs.l	1
mus_modsong	rs.w	1
mus_patterns	rs.l	64
mus_modpat	rs.w	1
mus_att1	rs.w	1	;offsets for previously selfmodified data
mus_sub1	rs.w	1
mus_dec1	rs.w	1
mus_att2	rs.w	1
mus_sub2	rs.w	1
mus_dec2	rs.w	1
mus_att3	rs.w	1
mus_sub3	rs.w	1
mus_dec3	rs.w	1
mus_att4	rs.w	1
mus_sub4	rs.w	1
mus_dec4	rs.w	1
mus_pl		rs.w	1
mus_rpspeed	rs.b	1
		rs.b	1	;(pad)
mus_data	rs.l	1	;deli related data
mus_modname	rs.b	9
mus_drumflag	rs.b	1
mus_vol		rs.w	1
mus_lbal	rs.w	1
mus_rbal	rs.w	1
mus_songendflag	rs.b	1
		rs.b	1	;(pad)
mus_stuff_sizo	rs.b	0

glue_music	move.l	mus_stuff_adr(pc),a4

		move.l	mus_rndwaveAddr(pc),a3
		move.l	mus_seed(a4),d1
		moveq	#7,d0
.rndloop	rol.l	#7,d1
		add.l	#$6eca756d,d1
		eori.l	#$9e59a92b,d1
		move.l	d1,(a3)+
		dbra	d0,.rndloop
		move.l	d1,mus_seed(a4)

		lea	$dff000,a6

		move	mus_vol1(a4),d0		;SUSTAIN-LEVEL
		cmp	mus_sub1(a4),d0
		bls.b	.s2
		move	mus_dec1(a4),d0		;DECAY-RATE
		sub	d0,mus_vol1(a4)

.s2		move	mus_vol2(a4),d0		;SUSTAIN-LEVEL
		cmp	mus_sub2(a4),d0
		bls.b	.s3
		move	mus_dec2(a4),d0		;DECAY-RATE
		sub	d0,mus_vol2(a4)

.s3		move	mus_vol3(a4),d0		;SUSTAIN-LEVEL
		cmp	mus_sub3(a4),d0	
		bls.b	.s4
		move	mus_dec3(a4),d0		;DECAY-RATE
		sub	d0,mus_vol3(a4)

.s4		move	mus_vol4(a4),d0		;SUSTAIN-LEVEL
		cmp	mus_sub4(a4),d0
		bls.b	.testnewtone
		move	mus_dec4(a4),d0		;DECAY-RATE
		sub	d0,mus_vol4(a4)

.testnewtone	addq.b	#1,mus_waitpos(a4)
		move.b	mus_waitpos(a4),d0
		cmp.b	mus_rpspeed(a4),d0
		bcc.b	.dosong
		tst.b	mus_drumflag(a4)
		bne.w	glue_22c8
		bra.w	glue_22b4

.dosong		clr.b	mus_waitpos(a4)
		add	#4,mus_modpat(a4)
		move	mus_modpat(a4),d0
		cmp	mus_pl(a4),d0
		bcs.b	glue_205c
		clr	mus_modpat(a4)
		addq	#1,mus_modsong(a4)
		move	mus_modsong(a4),d0
		move.l	mus_data(a4),a0
		lea	151(a0),a0
		move.b	(a0,d0),d1
		cmp.b	#$ff,d1
		bne.b	glue_2048
		clr	mus_modsong(a4)
		move.b	(a0),d1

		movem.l	d0-a6,-(sp)
		tst.b	mus_songendflag(a4)
		bne.s	.doit
		st	mus_songendflag(a4)
		bra.s	.dont
.doit		
		;move.l	dat_delibase(pc),a0
		;move.l	dtg_SongEnd(a0),a0
		;jsr	(a0)
		move.l songEndAddr(pc),a0 
		st (a0)
.dont		movem.l	(sp)+,d0-a6

glue_2048	and	#$ff,d1
		asl	#2,d1
		lea	mus_patterns(a4),a0
		move.l	(a0,d1),a2
		move.l	a2,mus_currpat(a4)
glue_205c	move.l	mus_currpat(a4),a0
		move	mus_modpat(a4),d0
		move.b	(a0,d0),d1
		cmp.b	#$fe,d1
		bne.b	glue_207a
		clr	mus_vol1(a4)
		bra.b	glue_2090

glue_207a	cmp.b	#$ff,d1
		beq.b	glue_2090
		bsr.w	glue_22ea
		move	d1,$a6(a6)
		move	mus_att1(a4),mus_vol1(a4)
glue_2090	move.b	1(a0,d0),d1
		cmp.b	#$fe,d1
		bne.b	glue_20a2
		clr	mus_vol2(a4)
		bra.b	glue_20b8

glue_20a2	cmp.b	#$ff,d1
		beq.b	glue_20b8
		bsr.w	glue_22ea
		move	d1,$b6(a6)
		move	mus_att2(a4),mus_vol2(a4)
glue_20b8	move.b	2(a0,d0),d1
		cmp.b	#$fe,d1
		bne.b	glue_20ca
		clr	mus_vol3(a4)
		bra.b	glue_20e0

glue_20ca	cmp.b	#$ff,d1
		beq.b	glue_20e0
		bsr.w	glue_22ea
		move	d1,$c6(a6)
		move	mus_att3(a4),mus_vol3(a4)
glue_20e0	tst.b	mus_drumflag(a4)
		beq.b	glue_211c
		move.b	3(a0,d0),d1
		cmp.b	#$fe,d1
		bne.b	glue_2100
		clr	mus_vol4(a4)
		bra.w	glue_22c8

glue_2100	cmp.b	#$ff,d1
		beq.w	glue_22c8
		bsr.w	glue_22ea
		move	d1,$d6(a6)
		move	mus_att4(a4),mus_vol4(a4)
		bra.w	glue_22c8

glue_211c	move.b	3(a0,d0),d1
		cmp.b	#$ff,d1
		beq.w	glue_22b4
		cmp.b	#$c8,d1
		bne.b	glue_2158
		move.l	mus_clrwaveAddr(pc),a0	;Corrected by Gluemaster
		move	#$0710,mus_drumrate(a4)
		move	#$ff01,mus_drumpitch(a4)
		move	#$0040,mus_vol4(a4)
		move.b	#8,mus_dec4+1(a4)
		bra.w	glue_22a4

glue_2158	cmp.b	#$c9,d1
		bne.b	glue_2188
		move.l	mus_rndwaveAddr(pc),a0
		move	#$0710,mus_drumrate(a4)
		move	#$0014,mus_drumpitch(a4)
		move	#$0040,mus_vol4(a4)
		move.b	#4,mus_dec4+1(a4)
		bra.w	glue_22a4

glue_2188	cmp.b	#$ca,d1
		bne.b	glue_21b8
		move.l	mus_extwave(a4),a0
		move	#$01c4,mus_drumrate(a4)
		move	#$ffce,mus_drumpitch(a4)
		move	#$0040,mus_vol4(a4)
		move.b	#4,mus_dec4+1(a4)
		bra.w	glue_22a4

glue_21b8	cmp.b	#$cb,d1
		bne.b	glue_21e8
		move.l	mus_extwave(a4),a0
		move	#$025c,mus_drumrate(a4)
		move	#$ffce,mus_drumpitch(a4)
		move	#$0040,mus_vol4(a4)
		move.b	#4,mus_dec4+1(a4)
		bra.w	glue_22a4

glue_21e8	cmp.b	#$cc,d1
		bne.b	glue_2218
		move.l	mus_extwave(a4),a0
		move	#$0388,mus_drumrate(a4)
		move	#$ffce,mus_drumpitch(a4)
		move	#$0040,mus_vol4(a4)
		move.b	#4,mus_dec4+1(a4)
		bra.b	glue_22a4

glue_2218	cmp.b	#$cd,d1
		bne.b	glue_2246
		move.l	mus_extwave(a4),a0
		move	#$04b8,mus_drumrate(a4)
		move	#$ffce,mus_drumpitch(a4)
		move	#$0040,mus_vol4(a4)
		move.b	#4,mus_dec4+1(a4)
		bra.b	glue_22a4

glue_2246	cmp.b	#$ce,d1
		bne.b	glue_2274
		move.l	mus_rndwaveAddr(pc),a0
		move	#$025c,mus_drumrate(a4)
		move	#$fff6,mus_drumpitch(a4)
		move	#$0030,mus_vol4(a4)
		move.b	#16,mus_dec4+1(a4)
		bra.b	glue_22a4

glue_2274	cmp.b	#$cf,d1
		bne.b	glue_22a4
		move.l	mus_rndwaveAddr(pc),a0
		move	#$025c,mus_drumrate(a4)
		move	#$fff6,mus_drumpitch(a4)
		move	#$0028,mus_vol4(a4)
		move.b	#2,mus_dec4+1(a4)
		bra.w	glue_22a4

glue_22a4	move	#8,$96(a6)
		move.l	a0,$d0(a6)
		move	#$8008,$96(a6)

glue_22b4	move	mus_drumpitch(a4),d1
		sub	d1,mus_drumrate(a4)
		move	mus_drumrate(a4),$d6(a6)

glue_22c8	movem.l	d0/d2,-(a7)		;;
;		move	mus_lbal(a4),d0		;set LEFT vol
;		mulu	mus_vol(a4),d0
;		lsr	#6,d0
		move	mus_vol(a4),d0		;set LEFT vol
		move	mus_vol1(a4),d2		;chan 1
		mulu	d0,d2
		lsr	#6,d2
		move	d2,$a8(a6)
		move	mus_vol4(a4),d2		;chan 4
		mulu	d0,d2
		lsr	#6,d2
		move	d2,$d8(a6)
		;move	mus_rbal(a4),d0		;set RIGHT vol
		;mulu	mus_vol(a4),d0
		;lsr	#6,d0
		move	mus_vol2(a4),d2		;chan 2
		mulu	d0,d2
		lsr	#6,d2
		move	d2,$b8(a6)
		move	mus_vol3(a4),d2		;chan 3
		mulu	d0,d2
		lsr	#6,d2
		move	d2,$c8(a6)
		movem.l	(a7)+,d0/d2
		rts

glue_22ea	lea	mus_periods(pc),a1
		and	#$fe,d1
		move	(a1,d1),d1
		rts

glue_init	movem.l	d0-a6,-(a7)
		move.l	mus_stuff_adr(pc),a4
		lea	$dff000,a6
		move.l	mus_data(a4),a3
		move	#$f,$96(a6)
		move.l	a3,d0
		add.l	#$16,d0
		move.l	d0,$a0(a6)
		move	#$10,$a4(a6)
		add.l	#$20,d0
		move.l	d0,$b0(a6)
		move	#$10,$b4(a6)
		add.l	#$20,d0
		move.l	d0,$c0(a6)
		move	#$10,$c4(a6)
		add.l	#$20,d0
		move.l	d0,mus_extwave(a4)
		move.l	d0,$d0(a6)
		move	#$10,$d4(a6)
		move	#$800f,$96(a6)
		move.b	21(a3),d1
		and	#$ff,d1
		asl	#2,d1
		move	d1,mus_pl(a4)
		move	d1,d2
		sub	#4,d2
		move	d2,mus_modpat(a4)
		move.b	150(a3),d0
		move.b	d0,d2
		sub.b	#2,d2
		and	#$ff,d2
		move	d2,mus_modsong(a4)
		add.b	#151,d0
		and.l	#$ff,d0
		add.l	a3,d0

		lea	mus_patterns(a4),a0
		and.l	#$ffff,d1
		moveq	#64-1,d7
.setpatterns	move.l	d0,(a0)+
		add.l	d1,d0
		dbra	d7,.setpatterns

		move.b	08(a3),mus_att1+1(a4)
		move.b	09(a3),mus_dec1+1(a4)
		move.b	10(a3),mus_sub1+1(a4)
		move.b	11(a3),mus_att2+1(a4)
		move.b	12(a3),mus_dec2+1(a4)
		move.b	13(a3),mus_sub2+1(a4)
		move.b	14(a3),mus_att3+1(a4)
		move.b	15(a3),mus_dec3+1(a4)
		move.b	16(a3),mus_sub3+1(a4)

		move.l	mus_data(a4),a0
		cmp	#$524d,18(a0)
		beq.b	.drumsinit
		st	mus_drumflag(a4)
		move.b	17(a3),mus_att4+1(a4)
		move.b	18(a3),mus_dec4+1(a4)
		move.b	19(a3),mus_sub4+1(a4)
		bra.b	.chan4inited
.drumsinit	sf	mus_drumflag(a4)
		move.b	#$30,mus_att4+1(a4)
		move.b	#$01,mus_dec4+1(a4)
		clr.b	mus_sub4+1(a4)

.chan4inited	move.b	20(a3),mus_rpspeed(a4)
		move.b	20(a3),d0
		sub.b	#1,d0
		move.b	d0,mus_waitpos(a4)
		clr.l	mus_vol1(a4)
		clr.l	mus_vol3(a4)
		clr	$a8(a6)
		clr	$b8(a6)
		clr	$c8(a6)
		clr	$d8(a6)
		move.l	#$986FA0B9,mus_seed(a4)
		movem.l	(a7)+,d0-a6
		rts

mus_periods	dc	$d60,$ca0,$be8,$b40,$a98,$a00,$970,$8e8
		dc	$868,$7f0,$780,$710,$6b0,$650,$5f4,$5a0
		dc	$54c,$500,$4b8,$474,$434,$3f8,$3c0,$388
		dc	$358,$328,$2fa,$2d0,$2a6,$280,$25c,$23a
		dc	$21a,$1fc,$1e0,$1c4,$1ac,$194,$17d,$168
		dc	$153,$140,$12e,$11d,$10d,$fe,$f0,$e2,$d6

mus_stuff_adr	dc.l	mus_stuff

;		section	emptystuff,BSS

mus_stuff	ds.b	mus_stuff_sizo
		even

;		section	drums,DATA_c

chipDataStart
mus_rndwave	ds.b	32

mus_clrwave	dc.b	$7f,$7f,-$7f,-$7f,00,10,20,30
		dc.b	40,50,60,70,80,90,100,110
		dc.b	120,130,140,150,160,170,180,190
		dc.b	180,160,140,120,100,80,60,40
mus_clrwaveEnd
chipDataEnd

 end

