;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
    incdir  include:
    include mucro.i

    jmp     tfmx_init(pc)
    jmp     tfmx_end(pc)
    jmp     tfmx_forward(pc)
    jmp     tfmx_backward(pc)
    jmp     tfmx_getpos(pc)
    jmp     tfmx_stop(pc)
    jmp     tfmx_cont(pc)
    jmp     tfmx_volume(pc)
    jmp     tfmx_song(pc)
    jmp     tfmx_getsongs(pc)

module      dc.l    0
samples     dc.l    0
songOver    dc.l    0
songNumber  dc.w    0 

* In:
*   a0 = module address
*   a1 = sample address
*   a2  = song over address
*   d0 = song number
tfmx_init:
    move.l  a0,module
    move.l  a1,samples
    move.l  a2,songOver
    move    d0,songNumber

    lea     _timerInterrupt(pc),a1
	lea	tfmxi1(pc),a2
	move.l	a1,(a2)
    lea     _audioInterrupt(pc),a0
	move.l	a0,tfmxi2-tfmxi1(a2)
	move.l	a0,tfmxi3-tfmxi1(a2)
	move.l	a0,tfmxi4-tfmxi1(a2)
	move.l	a0,tfmxi5-tfmxi1(a2)

	bsr	tfmx_varaa
    beq     .ok3
    moveq   #0,d0   * failed
    rts
.ok3

	move.l  module(pc),a0
	cmp.l	#"TFHD",(a0)
	bne.b	.noo

	move.l	a0,d0
	add.l	4(a0),d0		* MDAT
	move.l	d0,d1
	add.l	10(a0),d1		* SMPL
	btst	#0,d1		* onko parittomassa osoitteessa?
	beq.b	.un
	addq.l	#1,d1		* on, v‰‰nnet‰‰n se parilliseksi
	move.l	d1,a0
	clr.l	(a0)		* alusta nollaa tyhj‰ks
	bra.b	.un
.noo

	move.l	module(pc),d0
	move.l	samples(pc),d1

.un
	bsr     start+$14
	moveq	#0,d0			* song number
	move	songNumber(pc),d0
	bsr     start+12

	bsr 	tfmx_cont
    bsr     tfmx_getsongs
    move.l  d0,d1   

    moveq   #1,d0   * success
    rts

tfmx_cont:
    bset	#0,$bfdf00
    rts

tfmx_stop:
	bclr	#0,$bfdf00
    rts

tfmx_volume:
    ext.l   d0
	bra     start+$28

tfmx_forward:
	move	_songPosition(pc),d0
	addq	#2,d0
	cmp	    _songLength,d0
	bhi.b	.og
	subq	#1,d0
	move	d0,_songPosition
.og	
	rts

tfmx_backward:
	subq	#1,_songPosition
	bpl.b	.gog
	clr	    _songPosition
.gog
	rts

tfmx_getpos:
    move    _songPosition(pc),d0
    move    _songLength(pc),d1
    rts

tfmx_song:  
    move    d0,songNumber
    rts

tfmx_end:
	
.tfmxe	
    bsr 	tfmx_stop
	bsr	start+$1C
	moveq	#0,D0
	bsr	start+$20
	moveq	#1,D0
	bsr	start+$20
	moveq	#2,D0
	bsr	start+$20
	moveq	#3,D0
	bsr	start+$20
    bsr     tfmx_vapauta
    rts



tfmx_varaa:
	move.l	a6,-(sp)
	moveq	#7,D0
	lea	tfmx_L000106(PC),A1
	move.l	4.w,A6
	jsr	-$A2(A6)
	move.l	D0,tfmx_L0000E0
	moveq	#8,D0
	lea	tfmx_L00011C(PC),A1
	jsr	-$A2(A6)
	move.l	D0,tfmx_L0000E4
	moveq	#9,D0
	lea	tfmx_L000132(PC),A1
	jsr	-$A2(A6)
	move.l	D0,tfmx_L0000E8
	moveq	#10,D0
	lea	tfmx_L000148(PC),A1
	jsr	-$A2(A6)
	move.l	D0,tfmx_L0000EC
	lea	.n(pc),A1
	jsr	-$1F2(A6)
	move.l	D0,tfmx_L0000DC
	beq.b	tfmx_C000338
	moveq	#1,D0
	lea	tfmx_L0000F0(PC),A1
	move.l	tfmx_L0000DC,A6
	jsr	-6(A6)
	tst.l	D0
	bne.b	tfmx_C000338
	moveq	#0,D0
	move.l	(sp)+,a6
	rts

.n	dc.b	"ciab.resource",0
 even

* vapautetaan kaikki
tfmx_vapauta:
	move.l	a6,-(sp)
	moveq	#1,D0
	lea	tfmx_L0000F0(PC),A1
	move.l	tfmx_L0000DC,A6
	jsr	-12(A6)
tfmx_C000338	moveq	#10,D0
	move.l	tfmx_L0000EC,A1
	move.l	4.w,A6
	jsr	-$A2(A6)
	moveq	#9,D0
	move.l	tfmx_L0000E8,A1
	jsr	-$A2(A6)
	moveq	#8,D0
	move.l	tfmx_L0000E4,A1
	jsr	-$A2(A6)
	moveq	#7,D0
	move.l	tfmx_L0000E0,A1
	jsr	-$A2(A6)
	move.l	(sp)+,a6
    moveq   #1,d0
	rts

* palauttaa songien m‰‰r‰n d0:ssa
tfmx_getsongs:
	move.l	module(pc),a0
	lea	$0100(a0),a0
	moveq.l	#-2,d0
	moveq.l	#2,d1
	moveq.l	#$1e,d2
.35a	addq.l	#1,d0
	tst.w	(a0)+
	bne.s	.362
	subq.l	#1,d1
.362	dbeq	d2,.35a
	rts	


tfmx_L0000DC	dc.l	1		* TFMX:n dataa
tfmx_L0000E0	dc.l	1
tfmx_L0000E4	dc.l	1
tfmx_L0000E8	dc.l	1
tfmx_L0000EC	dc.l	1


tfmx_L0000F0	dcb.l	$2,0
	dc.b	2,1			* nt_interrupt, prioriteetti 1
	dc.l	TFMX_Pro_MSG0
	dcb.w	$2,0
tfmxi1	dc.l	0
tfmx_L000106	dcb.l	$2,0
	dc.b	2,100
	dc.l	TFMX_Pro_MSG0
	dcb.w	$2,0
tfmxi2	dc.l	0
tfmx_L00011C	dcb.l	$2,0
	dc.b	2,100
	dc.l	TFMX_Pro_MSG0
	dcb.w	$2,0
tfmxi3	dc.l	0
tfmx_L000132	dcb.l	$2,0
	dc.b	2,100
	dc.l	TFMX_Pro_MSG0
	dcb.w	$2,0
tfmxi4	dc.l	0
tfmx_L000148	dcb.l	$2,0
	dc.b	2,100
	dc.l	TFMX_Pro_MSG0
	dcb.w	$2,0
tfmxi5	dc.l	0
TFMX_Pro_MSG0 dc.b "TFMX",0
 even


start
tfmx_base
tfmx_C000400	bra	tfmx_C00178A

	bra	tfmx_C000464

	bra	tfmx_C00178A

	bra	tfmx_C0017F4

	bra	tfmx_C001488

	bra	tfmx_C001948

	bra	tfmx_C001AA6

	bra	tfmx_C001AC4

	bra	tfmx_C0015E8

	bra	tfmx_C0017F4

	bra	tfmx_C001620

	bra	tfmx_C00166E

	bra	tfmx_C00178A

	bra	tfmx_C001674

	bra	tfmx_C0016AE

	bra	tfmx_C0016D6

	bra	tfmx_C001808

	bra	tfmx_C00178A

	bra	tfmx_C00178A

	bra	tfmx_C00178A

	bra	tfmx_C00178A

	bra	tfmx_C001A28

	bra	tfmx_C00178A

	bra	tfmx_C001A18

	bra	tfmx_C00178A

tfmx_C000464	movem.l	D0-D7/A0-A6,-(SP)
	lea	tfmx_L001B0C(PC),A6
	move.l	$18(A6),-(SP)
	move.w	$4A(A6),D0
	beq.s	tfmx_C0004B2
	move.w	D0,$DFF096
	moveq	#9,D1
	btst	#0,D0
	beq.s	tfmx_C00048A
	move.w	D1,$DFF0A6
tfmx_C00048A	btst	#1,D0
	beq.s	tfmx_C000496
	move.w	D1,$DFF0B6
tfmx_C000496	btst	#2,D0
	beq.s	tfmx_C0004A2
	move.w	D1,$DFF0C6
tfmx_C0004A2	btst	#3,D0
	beq.s	tfmx_C0004AE
	move.w	D1,$DFF0D6
tfmx_C0004AE	clr.w	$4A(A6)
tfmx_C0004B2	tst.b	$1E(A6)
	bne.s	tfmx_C0004BC
	bra	tfmx_C000506

tfmx_C0004BC	bsr	tfmx_C0009BC
	tst.b	$10(A6)
	bmi.s	tfmx_C0004CA
	bsr	tfmx_C000510
tfmx_C0004CA	lea	tfmx_L001B98(PC),A5
	move.w	$8C(A5),$DFF0A6
	lea	tfmx_L001C28(PC),A5
	move.w	$8C(A5),$DFF0B6
	lea	tfmx_L001CB8(PC),A5
	move.w	$8C(A5),$DFF0C6
	lea	tfmx_L001D48(PC),A5
	move.w	$8C(A5),$DFF0D6
	move.w	$48(A6),$DFF096
	clr.w	$48(A6)
tfmx_C000506	move.l	(SP)+,$18(A6)
	movem.l	(SP)+,D0-D7/A0-A6
tfmx_C00050E	rts

tfmx_C000510	lea	tfmx_L002018(PC),A5
	move.l	0(A6),A4
	subq.w	#1,$1C(A6)
	bpl.s	tfmx_C00050E
	move.w	6(A5),$1C(A6)
tfmx_C000524	move.l	A5,A0
	clr.b	13(A6)
	bsr.s	tfmx_C00056E
	tst.b	13(A6)
	bne.s	tfmx_C000524
	bsr.s	tfmx_C00056C
	tst.b	13(A6)
	bne.s	tfmx_C000524
	bsr.s	tfmx_C00056C
	tst.b	13(A6)
	bne.s	tfmx_C000524
	bsr.s	tfmx_C00056C
	tst.b	13(A6)
	bne.s	tfmx_C000524
	bsr.s	tfmx_C00056C
	tst.b	13(A6)
	bne.s	tfmx_C000524
	bsr.s	tfmx_C00056C
	tst.b	13(A6)
	bne.s	tfmx_C000524
	bsr.s	tfmx_C00056C
	tst.b	13(A6)
	bne.s	tfmx_C000524
	bsr.s	tfmx_C00056C
	tst.b	13(A6)
	bne.s	tfmx_C000524
	rts

tfmx_C00056C	addq.l	#4,A0
tfmx_C00056E	cmp.b	#$90,$48(A0)
	blo.s	tfmx_C00058A
	cmp.b	#$FE,$48(A0)
	bne.s	tfmx_C00059C
	st	$48(A0)
	move.b	$49(A0),D0
	bra	tfmx_C0015E8

tfmx_C00058A	lea	tfmx_L0021A0(PC),A1
	st	$15(A1)
	tst.b	$6A(A0)
	beq.s	tfmx_C00059E
	subq.b	#1,$6A(A0)
tfmx_C00059C	rts

tfmx_C00059E	move.w	$68(A0),D0
	add.w	D0,D0
	add.w	D0,D0
	move.l	$28(A0),A1
	move.l	0(A1,D0.W),$18(A6)
	move.b	$18(A6),D0
	cmp.b	#$F0,D0
	bhs.s	tfmx_C0005FE
	move.b	D0,D7
	cmp.b	#$C0,D0
	bhs.s	tfmx_C0005D2
	cmp.b	#$7F,D0
	blo.s	tfmx_C0005D2
	move.b	$1B(A6),$6A(A0)
	clr.b	$1B(A6)
tfmx_C0005D2	move.b	$49(A0),D1
	add.b	D1,D0
	cmp.b	#$C0,D7
	bhs.s	tfmx_C0005E2
	and.b	#$3F,D0
tfmx_C0005E2	move.b	D0,$18(A6)
	move.l	$18(A6),D0
	bsr	tfmx_C001488
	cmp.b	#$C0,D7
	bhs.s	tfmx_C000646
	cmp.b	#$7F,D7
	blo.s	tfmx_C000646
	bra	tfmx_C0006CA

tfmx_C0005FE	and.w	#15,D0
	add.w	D0,D0
	add.w	D0,D0
	jmp	tfmx_C00060A(PC,D0.W)

tfmx_C00060A	bra	tfmx_C00064E

	bra	tfmx_C000672

	bra	tfmx_C0006A0

	bra	tfmx_C0006C4

	bra	tfmx_C0006D4

	bra	tfmx_C0006DA

	bra	tfmx_C0006DA

	bra	tfmx_C0006DA

	bra	tfmx_C0006E6

	bra	tfmx_C000716

	bra	tfmx_C000726

	bra	tfmx_C000792

	bra	tfmx_C0006DA

	bra	tfmx_C00077A

	bra	tfmx_C0006D0

tfmx_C000646	addq.w	#1,$68(A0)
	bra	tfmx_C00059E

tfmx_C00064E	st	$48(A0)
	move.w	4(A5),D0
	cmp.w	2(A5),D0
	bne.s	tfmx_C000664
	move.w	0(A5),4(A5)

    move.l  a0,-(sp)
    move.l  songOver(pc),a0
    st      (a0)
    move.l  (sp)+,a0

	bra.s	tfmx_C000668

tfmx_C000664	addq.w	#1,4(A5)
tfmx_C000668	bsr	tfmx_C0007CE
	st	13(A6)
	rts

tfmx_C000672	tst.b	$4A(A0)
	beq.s	tfmx_C000686
	cmp.b	#$FF,$4A(A0)
	beq.s	tfmx_C00068C
	subq.b	#1,$4A(A0)
	bra.s	tfmx_C000696

tfmx_C000686	st	$4A(A0)
	bra.s	tfmx_C000646

tfmx_C00068C	move.b	$19(A6),D0
	subq.b	#1,D0
	move.b	D0,$4A(A0)
tfmx_C000696	move.w	$1A(A6),$68(A0)
	bra	tfmx_C00059E

tfmx_C0006A0	move.b	$19(A6),D0
	move.b	D0,$48(A0)
	add.w	D0,D0
	add.w	D0,D0
	move.l	$3C(A6),A1
	move.l	0(A1,D0.W),D0
	add.l	A4,D0
	move.l	D0,$28(A0)
	move.w	$1A(A6),$68(A0)
	bra	tfmx_C00059E

tfmx_C0006C4	move.b	$19(A6),$6A(A0)
tfmx_C0006CA	addq.w	#1,$68(A0)
	rts

tfmx_C0006D0	clr.w	$2E(A6)
tfmx_C0006D4	st	$48(A0)
	rts

tfmx_C0006DA	move.l	$18(A6),D0
	bsr	tfmx_C001488
	bra	tfmx_C000646

tfmx_C0006E6	move.l	$28(A0),$88(A0)
	move.w	$68(A0),$A8(A0)
	move.b	$19(A6),D0
	move.b	D0,$48(A0)
	add.w	D0,D0
	add.w	D0,D0
	move.l	$3C(A6),A1
	move.l	0(A1,D0.W),D0
	add.l	A4,D0
	move.l	D0,$28(A0)
	move.w	$1A(A6),$68(A0)
	bra	tfmx_C00059E

tfmx_C000716	move.l	$88(A5),$28(A5)
	move.w	$A8(A5),$68(A5)
	bra	tfmx_C000646

tfmx_C000726	lea	tfmx_L0021A0(PC),A1
	tst.w	0(A1)
	bne	tfmx_C000646
	move.w	#1,0(A1)
	move.b	$1B(A6),$31(A6)
	move.b	$19(A6),$32(A6)
	move.b	$19(A6),$33(A6)
	beq.s	tfmx_C000768
	move.b	#1,$11(A6)
	move.b	$30(A6),D0
	cmp.b	$31(A6),D0
	beq.s	tfmx_C00076E
	blo	tfmx_C000646
	neg.b	$11(A6)
	bra	tfmx_C000646

tfmx_C000768	move.b	$31(A6),$30(A6)
tfmx_C00076E	clr.b	$11(A6)
	clr.w	0(A1)
	bra	tfmx_C000646

tfmx_C00077A	lea	tfmx_L0021A0(PC),A1
	move.b	$19(A6),D0
	and.w	#3,D0
	add.w	D0,D0
	move.w	$1A(A6),$1E(A1,D0.W)
	bra	tfmx_C000646

tfmx_C000792	move.b	$1A(A6),D1
	and.w	#7,D1
	add.w	D1,D1
	add.w	D1,D1
	move.b	$19(A6),D0
	move.b	D0,$48(A5,D1.W)
	move.b	$1B(A6),$49(A5,D1.W)
	and.w	#$7F,D0
	add.w	D0,D0
	add.w	D0,D0
	move.l	$3C(A6),A1
	move.l	0(A1,D0.W),D0
	add.l	A4,D0
	move.l	D0,$28(A5,D1.W)
	clr.l	$68(A5,D1.W)
	st	$4A(A5,D1.W)
	bra	tfmx_C000646

tfmx_C0007CE	movem.l	A0/A1,-(SP)
tfmx_C0007D2	move.w	4(A5),D0
	lsl.w	#4,D0
	move.l	$38(A6),A0
	add.w	D0,A0
	move.l	$3C(A6),A1
	move.w	(A0)+,D0
	cmp.w	#$EFFE,D0
	bne.s	tfmx_C000810
	move.w	(A0)+,D0
	add.w	D0,D0
	add.w	D0,D0
	cmp.w	#$14,D0
	blo.s	tfmx_C0007F8
	moveq	#0,D0
tfmx_C0007F8	jmp	tfmx_C0007FC(PC,D0.W)

tfmx_C0007FC	bra	tfmx_C000900

	bra	tfmx_C00090A

	bra	tfmx_C000938

	bra	tfmx_C000962

	bra	tfmx_C000962

tfmx_C000810	move.w	D0,$48(A5)
	bmi.s	tfmx_C00082C
	clr.b	D0
	lsr.w	#6,D0
	move.l	0(A1,D0.W),D0
	add.l	A4,D0
	move.l	D0,$28(A5)
	clr.l	$68(A5)
	st	$4A(A5)
tfmx_C00082C	movem.w	(A0)+,D0-D6
	move.w	D0,$4C(A5)
	bmi.s	tfmx_C00084C
	clr.b	D0
	lsr.w	#6,D0
	move.l	0(A1,D0.W),D0
	add.l	A4,D0
	move.l	D0,$2C(A5)
	clr.l	$6C(A5)
	st	$4E(A5)
tfmx_C00084C	move.w	D1,$50(A5)
	bmi.s	tfmx_C000868
	clr.b	D1
	lsr.w	#6,D1
	move.l	0(A1,D1.W),D0
	add.l	A4,D0
	move.l	D0,$30(A5)
	clr.l	$70(A5)
	st	$52(A5)
tfmx_C000868	move.w	D2,$54(A5)
	bmi.s	tfmx_C000884
	clr.b	D2
	lsr.w	#6,D2
	move.l	0(A1,D2.W),D0
	add.l	A4,D0
	move.l	D0,$34(A5)
	clr.l	$74(A5)
	st	$56(A5)
tfmx_C000884	move.w	D3,$58(A5)
	bmi.s	tfmx_C0008A0
	clr.b	D3
	lsr.w	#6,D3
	move.l	0(A1,D3.W),D0
	add.l	A4,D0
	move.l	D0,$38(A5)
	clr.l	$78(A5)
	st	$5A(A5)
tfmx_C0008A0	move.w	D4,$5C(A5)
	bmi.s	tfmx_C0008BC
	clr.b	D4
	lsr.w	#6,D4
	move.l	0(A1,D4.W),D0
	add.l	A4,D0
	move.l	D0,$3C(A5)
	clr.l	$7C(A5)
	st	$5E(A5)
tfmx_C0008BC	move.w	D5,$60(A5)
	bmi.s	tfmx_C0008D8
	clr.b	D5
	lsr.w	#6,D5
	move.l	0(A1,D5.W),D0
	add.l	A4,D0
	move.l	D0,$40(A5)
	clr.l	$80(A5)
	st	$62(A5)
tfmx_C0008D8	tst.w	$2E(A6)
	bne.s	tfmx_C0008FA
	move.w	D6,$64(A5)
	bmi.s	tfmx_C0008FA
	clr.b	D6
	lsr.w	#6,D6
	move.l	0(A1,D6.W),D0
	add.l	A4,D0
	move.l	D0,$44(A5)
	clr.l	$84(A5)
	st	$66(A5)
tfmx_C0008FA	movem.l	(SP)+,A0/A1
	rts

tfmx_C000900	clr.b	$1E(A6)
	movem.l	(SP)+,A0/A1
	rts

tfmx_C00090A	tst.w	$36(A6)
	beq.s	tfmx_C000918
	bmi.s	tfmx_C000926
	subq.w	#1,$36(A6)
	bra.s	tfmx_C000930

tfmx_C000918	move.w	#$FFFF,$36(A6)
	addq.w	#1,4(A5)
	bra	tfmx_C0007D2

tfmx_C000926	move.w	2(A0),D0
	subq.w	#1,D0
	move.w	D0,$36(A6)
tfmx_C000930	move.w	(A0),4(A5)
	bra	tfmx_C0007D2

tfmx_C000938	move.w	(A0),6(A5)
	move.w	(A0),$1C(A6)
	move.w	2(A0),D0
	bmi.s	tfmx_C00095A
	and.w	#$1FF,D0
	tst.w	D0
	beq.s	tfmx_C00095A
	move.l	#$1B51F8,D1
	divu	D0,D1
	move.w	D1,$24(A6)
tfmx_C00095A	addq.w	#1,4(A5)
	bra	tfmx_C0007D2

tfmx_C000962	addq.w	#1,4(A5)
	lea	tfmx_L0021A0(PC),A1
	tst.w	0(A1)
	bne	tfmx_C0007D2
	move.w	#1,0(A1)
	move.b	3(A0),$31(A6)
	move.b	1(A0),$32(A6)
	move.b	1(A0),$33(A6)
	beq.s	tfmx_C0009A8
	move.b	#1,$11(A6)
	move.b	$30(A6),D0
	cmp.b	$31(A6),D0
	beq.s	tfmx_C0009AE
	blo	tfmx_C0007D2
	neg.b	$11(A6)
	bra	tfmx_C0007D2

tfmx_C0009A8	move.b	$31(A6),$30(A6)
tfmx_C0009AE	move.b	#0,$11(A6)
	clr.w	0(A1)
	bra	tfmx_C0007D2

tfmx_C0009BC	lea	tfmx_L001B98(PC),A5
	bsr.s	tfmx_C0009D2
	lea	tfmx_L001C28(PC),A5
	bsr.s	tfmx_C0009D2
	lea	tfmx_L001CB8(PC),A5
	bsr.s	tfmx_C0009D2
	lea	tfmx_L001D48(PC),A5
tfmx_C0009D2	move.l	$58(A5),A4
	tst.w	$3E(A5)
	bmi.s	tfmx_C0009E2
	subq.w	#1,$3E(A5)
	bra.s	tfmx_C0009EA

tfmx_C0009E2	clr.b	$3C(A5)
	clr.b	$3D(A5)
tfmx_C0009EA	move.l	$88(A5),D0
	beq.s	tfmx_C000A02
	clr.l	$88(A5)
	clr.b	$3C(A5)
	bsr	tfmx_C001488
	move.b	$3D(A5),$3C(A5)
tfmx_C000A02	tst.b	0(A5)
	beq	tfmx_C001088
	tst.w	$12(A5)
	beq.s	tfmx_C000A18
	subq.w	#1,$12(A5)
tfmx_C000A14	bra	tfmx_C001088

tfmx_C000A18	move.l	12(A5),A0
	move.w	$10(A5),D0
	add.w	D0,D0
	add.w	D0,D0
	move.l	0(A0,D0.W),$18(A6)
	moveq	#0,D0
	move.b	$18(A6),D0
	clr.b	$18(A6)
	add.w	D0,D0
	add.w	D0,D0
	cmp.w	#$A8,D0
	bhs	tfmx_C000AEC
	jmp	tfmx_C000A44(PC,D0.W)

tfmx_C000A44	bra	tfmx_C000B06

	bra	tfmx_C000B40

	bra	tfmx_C000B66

	bra	tfmx_C000BDE

	bra	tfmx_C000BF2

	bra	tfmx_C000CD6

	bra	tfmx_C000EDC

	bra	tfmx_C000D18

	bra	tfmx_C000DB4

	bra	tfmx_C000DAC

	bra	tfmx_C000E82

	bra	tfmx_C000E0C

	bra	tfmx_C000E2E

	bra	tfmx_C000D20

	bra	tfmx_C000D5A

	bra	tfmx_C000E62

	bra	tfmx_C000D0A

	bra	tfmx_C000B80

	bra	tfmx_C000BB2

	bra	tfmx_C000B1A

	bra	tfmx_C000E9E

	bra	tfmx_C000ED0

	bra	tfmx_C000F08

	bra	tfmx_C000DF4

	bra	tfmx_C000F18

	bra	tfmx_C000F38

	bra	tfmx_C000C16

	bra	tfmx_C000CAC

	bra	tfmx_C000C80

	bra	tfmx_C000C96

	bra	tfmx_C000CCC

	bra	tfmx_C000DA2

	bra	tfmx_C000F5A

	bra	tfmx_C000D86

	bra	tfmx_C000F72

	bra	tfmx_C000F98

	bra	tfmx_C000FCA

	bra	tfmx_C000FEA

	bra	tfmx_C000FDC

	bra	tfmx_C001004

	bra	tfmx_C00101E

	bra	tfmx_C001044

tfmx_C000AEC	tst.b	$8E(A5)
	beq.s	tfmx_C000AFA
	addq.w	#1,$10(A5)
	bra	tfmx_C001088

tfmx_C000AFA	st	$8E(A5)
tfmx_C000AFE	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000B06	clr.b	$1C(A5)
	clr.b	$26(A5)
	clr.w	$30(A5)
	clr.b	$4B(A5)
	clr.w	$6A(A5)
tfmx_C000B1A	addq.w	#1,$10(A5)
	tst.b	$19(A6)
	bne.s	tfmx_C000B30
	move.w	$16(A5),$DFF096
	bra	tfmx_C000A18

tfmx_C000B30	move.w	$16(A5),D0
	or.w	D0,$4A(A6)
	clr.b	$8E(A5)
	bra	tfmx_C001088

tfmx_C000B40	move.w	$46(A5),$DFF09A
	move.w	$46(A5),$DFF09C
	move.b	$19(A6),1(A5)
	addq.w	#1,$10(A5)
	move.w	$14(A5),D0
	or.w	D0,$48(A6)
	bra	tfmx_C000A18

tfmx_C000B66	clr.b	3(A5)
	move.l	$18(A6),D0
	add.l	4(A6),D0
tfmx_C000B72	move.l	D0,$2C(A5)
	move.l	D0,(A4)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000B80	move.b	$19(A6),3(A5)
	move.b	$19(A6),$1B(A5)
	move.w	$1A(A6),D1
	ext.l	D1
	move.l	D1,$5C(A5)
	move.l	$2C(A5),D0
	add.l	D1,D0
	tst.w	$6A(A5)
	beq.s	tfmx_C000B72
	move.l	D0,$2C(A5)
	move.l	D0,$64(A5)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000BB2	move.w	$1A(A6),D0
	move.w	$34(A5),D1
	add.w	D0,D1
	move.w	D1,$34(A5)
	tst.w	$6A(A5)
	beq.s	tfmx_C000BD2
	move.w	D1,$68(A5)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000BD2	move.w	D1,4(A4)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000BDE	move.w	$1A(A6),$34(A5)
	move.w	$1A(A6),4(A4)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000BF2	btst	#0,$19(A6)
	beq.s	tfmx_C000C0C
	tst.b	$53(A5)
	bne	tfmx_C000A14
	move.b	#1,$53(A5)
	bra	tfmx_C000AFE

tfmx_C000C0C	move.w	$1A(A6),$12(A5)
	bra	tfmx_C000AEC

tfmx_C000C16	move.w	$1A(A6),6(A5)
	clr.b	0(A5)
	move.w	$44(A5),$DFF09A
	bra	tfmx_C000AEC

_audioInterrupt:
tfmx_C000C2C	movem.l	D0/A5,-(SP)
	lea	tfmx_L001B98(PC),A5
	move.w	$DFF01E,D0
	and.w	$DFF01C,D0
	btst	#7,D0
	bne.s	tfmx_C000C5E
	lea	tfmx_L001C28(PC),A5
	btst	#8,D0
	bne.s	tfmx_C000C5E
	lea	tfmx_L001CB8(PC),A5
	btst	#9,D0
	bne.s	tfmx_C000C5E
	lea	tfmx_L001D48(PC),A5
tfmx_C000C5E	move.w	$46(A5),$DFF09C
	subq.w	#1,6(A5)
	bpl.s	tfmx_C000C7A
	move.b	#$FF,0(A5)
	move.w	$46(A5),$DFF09A
tfmx_C000C7A	movem.l	(SP)+,D0/A5
	rts

tfmx_C000C80	move.b	$19(A6),D0
	cmp.b	5(A5),D0
	bhs	tfmx_C000AFE
	move.w	$1A(A6),$10(A5)
	bra	tfmx_C000A18

tfmx_C000C96	move.b	$19(A6),D0
	cmp.b	$18(A5),D0
	bhs	tfmx_C000AFE
	move.w	$1A(A6),$10(A5)
	bra	tfmx_C000A18

tfmx_C000CAC	move.b	$19(A6),$52(A5)
	move.w	$1A(A6),$48(A5)
	move.w	#$101,$4A(A5)
	bsr	tfmx_C001298
	move.b	#1,$53(A5)
	bra	tfmx_C000AFE

tfmx_C000CCC	move.b	$19(A6),$37(A5)
	bra	tfmx_C000AFE

tfmx_C000CD6	tst.b	$1A(A5)
	beq.s	tfmx_C000CEA
	cmp.b	#$FF,$1A(A5)
	beq.s	tfmx_C000CF6
	subq.b	#1,$1A(A5)
	bra.s	tfmx_C000D00

tfmx_C000CEA	st	$1A(A5)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000CF6	move.b	$19(A6),D0
	subq.b	#1,D0
	move.b	D0,$1A(A5)
tfmx_C000D00	move.w	$1A(A6),$10(A5)
	bra	tfmx_C000A18

tfmx_C000D0A	tst.b	$36(A5)
	bne.s	tfmx_C000CD6
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000D18	clr.b	0(A5)
	bra	tfmx_C001088

tfmx_C000D20	cmp.b	#$FE,$1A(A6)
	bne.s	tfmx_C000D40
	move.b	5(A5),D2
	move.b	$1B(A6),D3
	clr.w	$1A(A6)
	lea	tfmx_L000D3C(PC),A1
	bra	tfmx_C000DBC

tfmx_L000D3C	dc.l	$1D43001B

tfmx_C000D40	move.w	8(A5),D0
	add.w	D0,D0
	add.w	8(A5),D0
	add.w	$1A(A6),D0
	move.b	D0,$18(A5)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000D5A	cmp.b	#$FE,$1A(A6)
	bne.s	tfmx_C000D78
	move.b	5(A5),D2
	move.b	$1B(A6),D3
	clr.w	$1A(A6)
	lea	tfmx_L000D74(PC),A1
	bra.s	tfmx_C000DBC

tfmx_L000D74	dc.l	$1D43001B

tfmx_C000D78	move.b	$1B(A6),$18(A5)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000D86	move.b	5(A5),$18(A6)
	move.b	9(A5),D0
	lsl.b	#4,D0
	or.b	D0,$1A(A6)
	move.l	$18(A6),D0
	bsr	tfmx_C001488
	bra	tfmx_C000AFE

tfmx_C000DA2	move.b	4(A5),D2
	lea	tfmx_C000AEC(PC),A1
	bra.s	tfmx_C000DBC

tfmx_C000DAC	moveq	#0,D2
	lea	tfmx_C000AEC(PC),A1
	bra.s	tfmx_C000DBC

tfmx_C000DB4	move.b	5(A5),D2
	lea	tfmx_C000AEC(PC),A1
tfmx_C000DBC	move.b	$19(A6),D0
	add.b	D2,D0
	and.b	#$3F,D0
	ext.w	D0
	add.w	D0,D0
	lea	tfmx_W0021CE(PC),A0
	move.w	0(A0,D0.W),D0
	move.w	10(A5),D1
	add.w	$1A(A6),D1
	beq.s	tfmx_C000DE4
	add.w	#$100,D1
	mulu	D1,D0
	lsr.l	#8,D0
tfmx_C000DE4	move.w	D0,$28(A5)
	tst.w	$30(A5)
	bne.s	tfmx_C000DF2
	move.w	D0,$8C(A5)
tfmx_C000DF2	jmp	(A1)

tfmx_C000DF4	move.w	$1A(A6),$28(A5)
	tst.w	$30(A5)
	bne	tfmx_C000AFE
	move.w	$1A(A6),$8C(A5)
	bra	tfmx_C000AFE

tfmx_C000E0C	move.b	$19(A6),$22(A5)
	move.b	#1,$23(A5)
	tst.w	$30(A5)
	bne.s	tfmx_C000E24
	move.w	$28(A5),$32(A5)
tfmx_C000E24	move.w	$1A(A6),$30(A5)
	bra	tfmx_C000AFE

tfmx_C000E2E	move.b	$19(A6),D0
	move.b	D0,$26(A5)
	lsr.b	#1,D0
	move.b	D0,$27(A5)
	move.b	$1B(A6),$20(A5)
	move.b	#1,$21(A5)
	tst.w	$30(A5)
	bne	tfmx_C000AFE
	move.w	$28(A5),$8C(A5)
	clr.w	$24(A5)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000E62	move.b	$1A(A6),$1C(A5)
	move.b	$19(A6),$1F(A5)
	move.b	$1A(A6),$1D(A5)
	move.b	$1B(A6),$1E(A5)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000E82	clr.b	$4B(A5)
	clr.w	$6A(A5)
	clr.b	3(A5)
	clr.b	$1C(A5)
	clr.b	$26(A5)
	clr.w	$30(A5)
	bra	tfmx_C000AFE

tfmx_C000E9E	tst.b	$36(A5)
	beq	tfmx_C000AFE
	tst.b	$1A(A5)
	beq.s	tfmx_C000EBA
	cmp.b	#$FF,$1A(A5)
	beq.s	tfmx_C000EC2
	subq.b	#1,$1A(A5)
	bra.s	tfmx_C000ECC

tfmx_C000EBA	st	$1A(A5)
	bra	tfmx_C000AFE

tfmx_C000EC2	move.b	$1B(A6),D0
	subq.b	#1,D0
	move.b	D0,$1A(A5)
tfmx_C000ECC	bra	tfmx_C001088

tfmx_C000ED0	move.l	12(A5),$38(A5)
	move.w	$10(A5),$40(A5)
tfmx_C000EDC	move.b	$19(A6),D0
	and.l	#$7F,D0
	move.l	$40(A6),A0
	add.w	D0,D0
	add.w	D0,D0
	add.w	D0,A0
	move.l	(A0),D0
	add.l	0(A6),D0
	move.l	D0,12(A5)
	move.w	$1A(A6),$10(A5)
	st	$1A(A5)
	bra	tfmx_C000A18

tfmx_C000F08	move.l	$38(A5),12(A5)
	move.w	$40(A5),$10(A5)
	bra	tfmx_C000AFE

tfmx_C000F18	move.l	$18(A6),D0
	add.l	D0,$2C(A5)
	move.l	$2C(A5),(A4)
	lsr.w	#1,D0
	sub.w	D0,$34(A5)
	move.w	$34(A5),4(A4)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000F38	clr.b	3(A5)
	move.l	4(A6),$2C(A5)
	move.l	4(A6),(A4)
	move.w	#1,$34(A5)
	move.w	#1,4(A4)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000F5A	move.b	$19(A6),D0
	and.w	#3,D0
	add.w	D0,D0
	lea	tfmx_L0021A0(PC),A0
	move.w	$1A(A6),$1E(A0,D0.W)
	bra	tfmx_C000AFE

tfmx_C000F72	clr.b	3(A5)
	move.l	$18(A6),D0
	add.l	4(A6),D0
	move.l	D0,$64(A5)
	move.l	D0,$2C(A5)
	move.l	4(A6),D0
	add.l	$60(A5),D0
	move.l	D0,(A4)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000F98	move.w	$18(A6),D0
	bne.s	tfmx_C000FA2
	move.w	#$100,D0
tfmx_C000FA2	lsr.w	#1,D0
	move.w	D0,4(A4)
	move.w	$18(A6),D0
	subq.w	#1,D0
	and.w	#$FF,D0
	move.w	D0,$6A(A5)
	move.w	$1A(A6),$68(A5)
	move.w	$1A(A6),$34(A5)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000FCA	move.l	$18(A6),D0
	lsl.l	#8,D0
	move.l	D0,$6C(A5)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000FDC	move.l	$18(A6),$78(A5)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C000FEA	move.w	$18(A6),$70(A5)
	move.w	$18(A6),$72(A5)
	move.w	$1A(A6),$74(A5)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C001004	move.w	$18(A6),$84(A5)
	move.w	$18(A6),$86(A5)
	move.w	$1A(A6),$82(A5)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C00101E	move.b	$1B(A6),$76(A5)
	move.b	$1A(A6),D0
	ext.w	D0
	lsl.w	#4,D0
	move.w	D0,$80(A5)
	move.w	$18(A6),$7C(A5)
	move.w	$18(A6),$7E(A5)
	addq.w	#1,$10(A5)
	bra	tfmx_C000A18

tfmx_C001044	addq.w	#1,$10(A5)
	clr.w	$6A(A5)
	tst.b	$19(A6)
	beq	tfmx_C000A18
	clr.l	$6C(A5)
	clr.w	$70(A5)
	clr.w	$72(A5)
	clr.w	$74(A5)
	clr.l	$78(A5)
	clr.w	$84(A5)
	clr.w	$86(A5)
	clr.w	$82(A5)
	clr.b	$76(A5)
	clr.w	$80(A5)
	clr.w	$7C(A5)
	clr.w	$7E(A5)
	bra	tfmx_C000A18

tfmx_C001088	tst.b	1(A5)
	bmi.s	tfmx_C001096
	bne.s	tfmx_C00109A
	move.b	#1,1(A5)
tfmx_C001096	bra	tfmx_C00141E

tfmx_C00109A	tst.b	3(A5)
	beq.s	tfmx_C0010CC
	move.l	$2C(A5),D0
	add.l	$5C(A5),D0
	move.l	D0,$2C(A5)
	tst.w	$6A(A5)
	beq.s	tfmx_C0010B8
	move.l	D0,$64(A5)
	bra.s	tfmx_C0010BA

tfmx_C0010B8	move.l	D0,(A4)
tfmx_C0010BA	sub.b	#1,3(A5)
	bne.s	tfmx_C0010CC
	move.b	$1B(A5),3(A5)
	neg.l	$5C(A5)
tfmx_C0010CC	tst.w	$6A(A5)
	beq	tfmx_C00118C
	move.l	$64(A5),A0
	move.l	$6C(A5),D4
	move.l	$78(A5),D5
	move.l	$60(A5),A1
	add.l	8(A6),A1
	move.w	$6A(A5),D7
	move.w	$68(A5),D6
	move.b	$76(A5),D3
	moveq	#0,D0
	move.b	$43,D1
tfmx_C0010FC	add.l	D5,D4
	swap	D0
	add.l	D4,D0
	swap	D0
	and.w	D6,D0
	move.b	0(A0,D0.W),D2
	tst.b	D3
	beq.s	tfmx_C00112E
	cmp.b	D1,D2
	beq.s	tfmx_C00112C
	bgt.s	tfmx_C001124
	subx.b	D3,D1
	bvs.s	tfmx_C00112C
	cmp.b	D1,D2
	bge.s	tfmx_C00112C
tfmx_C00111C	move.b	D1,(A1)+
	dbra	D7,tfmx_C0010FC
	bra.s	tfmx_C001134

tfmx_C001124	addx.b	D3,D1
	bvs.s	tfmx_C00112C
	cmp.b	D1,D2
	bgt.s	tfmx_C00111C
tfmx_C00112C	move.b	D2,D1
tfmx_C00112E	move.b	D2,(A1)+
	dbra	D7,tfmx_C0010FC
tfmx_C001134	move.b	D1,$43(A5)
	tst.b	D3
	beq.s	tfmx_C001154
	move.w	$80(A5),D0
	add.w	D0,$76(A5)
	subq.w	#1,$7C(A5)
	bne.s	tfmx_C001154
	move.w	$7E(A5),$7C(A5)
	neg.w	$80(A5)
tfmx_C001154	move.w	$74(A5),D0
	ext.l	D0
	add.l	D0,$6C(A5)
	subq.w	#1,$70(A5)
	bne.s	tfmx_C001170
	move.w	$72(A5),$70(A5)
	beq.s	tfmx_C001170
	neg.w	$74(A5)
tfmx_C001170	move.w	$82(A5),D0
	ext.l	D0
	add.l	D0,$78(A5)
	subq.w	#1,$84(A5)
	bne.s	tfmx_C00118C
	move.w	$86(A5),$84(A5)
	beq.s	tfmx_C00118C
	neg.w	$82(A5)
tfmx_C00118C	tst.b	$26(A5)
	beq.s	tfmx_C0011D6
	move.b	$20(A5),D0
	ext.w	D0
	add.w	D0,$24(A5)
	move.w	$28(A5),D0
	move.w	$24(A5),D1
	beq.s	tfmx_C0011B6
	and.l	#$FFFF,D0
	add.w	#$800,D1
	mulu	D1,D0
	lsl.l	#5,D0
	swap	D0
tfmx_C0011B6	tst.w	$30(A5)
	bne.s	tfmx_C0011C0
	move.w	D0,$8C(A5)
tfmx_C0011C0	subq.b	#1,$27(A5)
	bne.s	tfmx_C0011D6
	move.b	$26(A5),$27(A5)
	eor.b	#$FF,$20(A5)
	addq.b	#1,$20(A5)
tfmx_C0011D6	tst.w	$30(A5)
	beq.s	tfmx_C001234
	subq.b	#1,$23(A5)
	bne.s	tfmx_C001234
	move.b	$22(A5),$23(A5)
	move.w	$28(A5),D1
	moveq	#0,D0
	move.w	$32(A5),D0
	cmp.w	D1,D0
	beq.s	tfmx_C00120A
	blo.s	tfmx_C001220
	move.w	#$100,D2
	sub.w	$30(A5),D2
	mulu	D2,D0
	lsr.l	#8,D0
	cmp.w	D1,D0
	beq.s	tfmx_C00120A
	bhs.s	tfmx_C001212
tfmx_C00120A	clr.w	$30(A5)
	move.w	$28(A5),D0
tfmx_C001212	and.w	#$7FF,D0
	move.w	D0,$32(A5)
	move.w	D0,$8C(A5)
	bra.s	tfmx_C001234

tfmx_C001220	move.w	$30(A5),D2
	add.w	#$100,D2
	mulu	D2,D0
	lsr.l	#8,D0
	cmp.w	D1,D0
	beq.s	tfmx_C00120A
	bhs.s	tfmx_C00120A
	bra.s	tfmx_C001212

tfmx_C001234	tst.b	$1C(A5)
	beq.s	tfmx_C001282
	tst.b	$1D(A5)
	beq.s	tfmx_C001246
	subq.b	#1,$1D(A5)
	bra.s	tfmx_C001282

tfmx_C001246	move.b	$1C(A5),$1D(A5)
	move.b	$1E(A5),D0
	cmp.b	$18(A5),D0
	bgt.s	tfmx_C001274
	move.b	$1F(A5),D1
	sub.b	D1,$18(A5)
	bmi.s	tfmx_C001268
	cmp.b	$18(A5),D0
	bge.s	tfmx_C001268
	bra.s	tfmx_C001282

tfmx_C001268	move.b	$1E(A5),$18(A5)
	clr.b	$1C(A5)
	bra.s	tfmx_C001282

tfmx_C001274	move.b	$1F(A5),D1
	add.b	D1,$18(A5)
	cmp.b	$18(A5),D0
	ble.s	tfmx_C001268
tfmx_C001282	tst.w	$24(A6)
	beq.s	tfmx_C001298
	move.b	$24(A6),$BFD700
	move.b	$25(A6),$BFD600
tfmx_C001298	tst.b	$4B(A5)
	beq	tfmx_C00141E
	bmi.s	tfmx_C0012D8
	move.b	$52(A5),D0
	and.l	#$7F,D0
	move.l	$40(A6),A0
	add.w	D0,D0
	add.w	D0,D0
	add.w	D0,A0
	move.l	(A0),D0
	add.l	0(A6),D0
	move.l	D0,$4C(A5)
	clr.w	$50(A5)
	move.b	#$FF,$4B(A5)
	btst	#0,$49(A5)
	beq	tfmx_C0012D8
	bsr	tfmx_C0013B0
tfmx_C0012D8	subq.b	#1,$4A(A5)
	bne	tfmx_C0013C6
	move.b	$48(A5),$4A(A5)
	move.l	$4C(A5),A0
tfmx_C0012EA	move.w	$50(A5),D0
	move.b	0(A0,D0.W),D0
	move.b	D0,$18(A6)
	bne.s	tfmx_C001306
	tst.w	$50(A5)
	beq	tfmx_C00141E
	clr.w	$50(A5)
	bra.s	tfmx_C0012EA

tfmx_C001306	add.b	5(A5),D0
	and.w	#$3F,D0
	beq	tfmx_C0013B0
	add.w	D0,D0
	lea	tfmx_W0021CE(PC),A0
	move.w	0(A0,D0.W),D0
	move.w	10(A5),D1
	beq.s	tfmx_C00132A
	add.w	#$100,D1
	mulu	D1,D0
	lsr.l	#8,D0
tfmx_C00132A	btst	#0,$49(A5)
	bne.s	tfmx_C001356
	move.w	D0,$28(A5)
	tst.w	$30(A5)
	bne	tfmx_C00141E
	move.w	D0,$8C(A5)
	btst	#7,$18(A6)
	beq.s	tfmx_C00134E
	clr.b	$53(A5)
tfmx_C00134E	addq.w	#1,$50(A5)
	bra	tfmx_C00141E

tfmx_C001356	bsr	tfmx_C00146E
	btst	#2,$49(A5)
	bne.s	tfmx_C001376
	move.w	$50(A5),D1
	and.w	#3,D1
	tst.w	D1
	bne.s	tfmx_C001376
	moveq	#$10,D1
	cmp.b	$13(A6),D1
	bhs.s	tfmx_C001392
tfmx_C001376	btst	#7,$18(A6)
	beq.s	tfmx_C001382
	clr.b	$53(A5)
tfmx_C001382	move.w	D0,$28(A5)
	tst.w	$30(A5)
	bne	tfmx_C001392
	move.w	D0,$8C(A5)
tfmx_C001392	addq.w	#1,$50(A5)
	btst	#6,$18(A6)
	beq	tfmx_C00141E
	bsr	tfmx_C00146E
	move.w	#6,D1
	cmp.b	$12(A6),D1
	bhs	tfmx_C00141E
tfmx_C0013B0	bsr	tfmx_C00146E
	moveq	#0,D1
	move.b	$13(A6),D1
	and.b	$37(A5),D1
	move.w	D1,$50(A5)
	bra	tfmx_C00141E

tfmx_C0013C6	btst	#1,$49(A5)
	beq.s	tfmx_C00141E
	moveq	#0,D0
	move.b	$48(A5),D0
	mulu	#3,D0
	lsr.w	#3,D0
	cmp.b	$4A(A5),D0
	bne.s	tfmx_C00141E
	move.w	$28(A5),D0
	moveq	#0,D1
	move.b	$18(A5),D1
	mulu	#5,D1
	lsr.w	#3,D1
	move.l	A5,-(SP)
	add.l	$54(A5),A5
	move.l	$58(A5),A4
	move.b	D1,$18(A5)
	cmp.w	$28(A5),D0
	beq.s	tfmx_C001418
	move.w	D0,$28(A5)
	move.w	D0,$8C(A5)
	btst	#7,$18(A6)
	beq.s	tfmx_C001418
	clr.b	$53(A5)
tfmx_C001418	move.l	(SP)+,A5
	move.l	$58(A5),A4
tfmx_C00141E	tst.b	$11(A6)
	beq.s	tfmx_C00144E
	subq.b	#1,$32(A6)
	bne.s	tfmx_C00144E
	move.b	$33(A6),$32(A6)
	move.b	$11(A6),D0
	add.b	D0,$30(A6)
	move.b	$31(A6),D0
	cmp.b	$30(A6),D0
	bne.s	tfmx_C00144E
	clr.b	$11(A6)
	lea	tfmx_L0021A0(PC),A0
	clr.w	0(A0)
tfmx_C00144E	moveq	#0,D1
	move.b	$30(A6),D1
	moveq	#0,D0
	move.b	$18(A5),D0
	btst	#6,D1
	bne.s	tfmx_C001468
	add.w	D0,D0
	add.w	D0,D0
	mulu	D1,D0
	lsr.w	#8,D0
tfmx_C001468	move.w	D0,8(A4)
	rts

tfmx_C00146E	move.w	$DFF006,D7
	eor.w	D7,$12(A6)
	move.w	$12(A6),D7
	add.l	#$57294335,D7
	move.w	D7,$12(A6)
	rts

tfmx_C001488	movem.l	D0/A4-A6,-(SP)
	lea	tfmx_L001B0C(PC),A6
	move.l	$18(A6),-(SP)
	lea	tfmx_L001B58(PC),A5
	move.l	D0,$18(A6)
	move.b	$1A(A6),D0
	and.w	#15,D0
	add.w	D0,D0
	add.w	D0,D0
	move.l	0(A5,D0.W),A5
	move.b	$18(A6),D0
	cmp.b	#$FC,D0
	bne.s	tfmx_C0014C8
	move.b	$19(A6),$3C(A5)
	move.b	$1B(A6),D0
	move.w	D0,$3E(A5)
	bra	tfmx_C0015A2

tfmx_C0014C8	tst.b	$3C(A5)
	bne	tfmx_C0015A2
	tst.b	D0
	bpl	tfmx_C001538
	cmp.b	#$F7,D0
	bne.s	tfmx_C0014FC
	move.b	$19(A6),$1F(A5)
	move.b	$1A(A6),D0
	lsr.b	#4,D0
	addq.b	#1,D0
	move.b	D0,$1D(A5)
	move.b	D0,$1C(A5)
	move.b	$1B(A6),$1E(A5)
	bra	tfmx_C0015A2

tfmx_C0014FC	cmp.b	#$F6,D0
	bne.s	tfmx_C001526
	move.b	$19(A6),D0
	and.b	#$FE,D0
	move.b	D0,$26(A5)
	lsr.b	#1,D0
	move.b	D0,$27(A5)
	move.b	$1B(A6),$20(A5)
	move.b	#1,$21(A5)
	clr.w	$24(A5)
	bra.s	tfmx_C0015A2

tfmx_C001526	cmp.b	#$F5,D0
	bne.s	tfmx_C001532
	clr.b	$36(A5)
	bra.s	tfmx_C0015A2

tfmx_C001532	cmp.b	#$BF,D0
	bhs.s	tfmx_C0015AC
tfmx_C001538	move.b	$1B(A6),D0
	ext.w	D0
	move.w	D0,10(A5)
	move.b	$1A(A6),D0
	lsr.b	#4,D0
	and.w	#15,D0
	move.b	D0,9(A5)
	move.b	$19(A6),D0
	move.b	5(A5),4(A5)
	move.b	$18(A6),5(A5)
	move.l	$40(A6),A4
	add.w	D0,D0
	add.w	D0,D0
	add.w	D0,A4
	move.l	(A4),A4
	add.l	0(A6),A4
	move.l	A4,12(A5)
	clr.w	$10(A5)
	clr.w	$12(A5)
	clr.b	1(A5)
	st	$1A(A5)
	st	0(A5)
	clr.w	6(A5)
	move.w	$46(A5),$DFF09A
	move.w	$46(A5),$DFF09C
	move.b	#1,$36(A5)
tfmx_C0015A2	move.l	(SP)+,$18(A6)
	movem.l	(SP)+,D0/A4-A6
	rts

tfmx_C0015AC	move.b	$19(A6),$22(A5)
	move.b	#1,$23(A5)
	tst.w	$30(A5)
	bne.s	tfmx_C0015C4
	move.w	$28(A5),$32(A5)
tfmx_C0015C4	clr.w	$30(A5)
	move.b	$1B(A6),$31(A5)
	move.b	$18(A6),D0
	and.w	#$3F,D0
	move.b	D0,5(A5)
	add.w	D0,D0
	lea	tfmx_W0021CE(PC),A4
	move.w	0(A4,D0.W),$28(A5)
	bra.s	tfmx_C0015A2

tfmx_C0015E8	move.l	A5,-(SP)
	lea	tfmx_L001B58(PC),A5
	and.w	#15,D0
	add.w	D0,D0
	add.w	D0,D0
	move.l	0(A5,D0.W),A5
	tst.b	$3C(A5)
	bne.s	tfmx_C00161C
	move.w	$46(A5),$DFF09A
	move.w	$16(A5),$DFF096
	clr.b	0(A5)
	clr.w	$6A(A5)
	clr.b	$4B(A5)
tfmx_C00161C	move.l	(SP)+,A5
	rts

tfmx_C001620	movem.l	A5/A6,-(SP)
	lea	tfmx_L001B0C(PC),A6
	lea	tfmx_L0021A0(PC),A5
	move.w	#1,0(A5)
	move.b	D0,$31(A6)
	swap	D0
	move.b	D0,$32(A6)
	move.b	D0,$33(A6)
	beq.s	tfmx_C00165A
	move.b	$30(A6),D0
	move.b	#1,$11(A6)
	cmp.b	$31(A6),D0
	beq.s	tfmx_C001660
	blo.s	tfmx_C001668
	neg.b	$11(A6)
	bra.s	tfmx_C001668

tfmx_C00165A	move.b	$31(A6),$30(A6)
tfmx_C001660	clr.b	$11(A6)
	clr.w	0(A5)
tfmx_C001668	movem.l	(SP)+,A5/A6
	rts

tfmx_C00166E	lea	tfmx_L0021A0(PC),A0
	rts

tfmx_C001674	movem.l	A3-A6,-(SP)
	lea	tfmx_L001B0C(PC),A6
	lea	tfmx_L002018(PC),A5
	move.w	#1,$2E(A6)
	move.l	0(A6),A4
	move.l	$3C(A6),A3
	move.w	D0,$64(A5)
	clr.b	D0
	lsr.w	#6,D0
	move.l	0(A3,D0.W),D0
	add.l	A4,D0
	move.l	D0,$44(A5)
	clr.l	$84(A5)
	st	$66(A5)
	movem.l	(SP)+,A3-A6
	rts

tfmx_C0016AE	movem.l	A5/A6,-(SP)
	lea	tfmx_L001B0C(PC),A6
	lea	tfmx_L002018(PC),A5
	move.w	#1,$2E(A6)
	move.w	D0,$64(A5)
	move.l	A1,$44(A5)
	clr.l	$84(A5)
	st	$66(A5)
	movem.l	(SP)+,A5/A6
	rts

tfmx_C0016D6	movem.l	D1-D3/A4-A6,-(SP)
	lea	tfmx_L001B0C(PC),A6
	lea	tfmx_L001B58(PC),A4
	move.w	D0,D2
	move.l	0(A6),A5
	tst.l	$1D0(A5)
	bne.s	tfmx_C0016F8
	move.l	$5FC(A5),A5
	add.l	0(A6),A5
	bra.s	tfmx_C0016FC

tfmx_C0016F8	move.l	$44(A6),A5
tfmx_C0016FC	lsl.w	#3,D2
	cmp.b	#$FB,0(A5,D2.W)
	bne.s	tfmx_C001710
	move.w	2(A5,D2.W),D0
	bsr	tfmx_C001674
	bra.s	tfmx_C001772

tfmx_C001710	move.b	2(A5,D2.W),D3
	tst.b	$10(A6)
	bpl.s	tfmx_C00171E
	move.b	4(A5,D2.W),D3
tfmx_C00171E	and.w	#15,D3
	add.w	D3,D3
	add.w	D3,D3
	move.l	0(A4,D3.W),A4
	lsl.w	#6,D3
	move.b	5(A5,D2.W),D1
	bclr	#7,D1
	cmp.b	$3D(A4),D1
	bhs.s	tfmx_C001740
	tst.w	$3E(A4)
	bpl.s	tfmx_C001772
tfmx_C001740	cmp.b	$42(A4),D2
	bne.s	tfmx_C001754
	tst.w	$3E(A4)
	bmi.s	tfmx_C001754
	btst	#7,5(A5,D2.W)
	bne.s	tfmx_C001772
tfmx_C001754	move.l	0(A5,D2.W),D0
	and.l	#$FFFFF0FF,D0
	or.w	D3,D0
	move.l	D0,$88(A4)
	move.b	D1,$3D(A4)
	move.w	6(A5,D2.W),$3E(A4)
	move.b	D2,$42(A4)
tfmx_C001772	movem.l	(SP)+,D1-D3/A4-A6
	rts

tfmx_C001778	clr.b	0(A6)
	clr.l	$3C(A6)
	clr.w	$6A(A6)
	clr.b	$4B(A6)
	rts

tfmx_C00178A	move.l	A6,-(SP)
	lea	tfmx_L001B0C(PC),A6
	clr.b	$1E(A6)
	clr.w	$48(A6)
	lea	tfmx_L001B98(PC),A6
	bsr.s	tfmx_C001778
	lea	tfmx_L001C28(PC),A6
	bsr.s	tfmx_C001778
	lea	tfmx_L001CB8(PC),A6
	bsr.s	tfmx_C001778
	lea	tfmx_L001D48(PC),A6
	bsr.s	tfmx_C001778
	clr.w	$DFF0A8
	clr.w	$DFF0B8
	clr.w	$DFF0C8
	clr.w	$DFF0D8
	move.w	#15,$DFF096
	move.w	#$780,$DFF09C
	move.w	#$780,$DFF09A
	move.w	#$780,$DFF09C
	lea	tfmx_L0021A0(PC),A6
	clr.b	$15(A6)
	move.l	(SP)+,A6
	rts

tfmx_C0017F4	movem.l	D1-D7/A0-A6,-(SP)
	lea	tfmx_L001B0C(PC),A6
	move.b	D0,$2D(A6)
	bsr.s	tfmx_C001820
	movem.l	(SP)+,D1-D7/A0-A6
	rts

tfmx_C001808	movem.l	D1-D7/A0-A6,-(SP)
	lea	tfmx_L001B0C(PC),A6
	or.w	#$100,D0
	move.w	D0,$2C(A6)
	bsr.s	tfmx_C001820
	movem.l	(SP)+,D1-D7/A0-A6
	rts

tfmx_C001820	bsr	tfmx_C00178A
	clr.b	$1E(A6)
	clr.w	$2E(A6)
	move.l	0(A6),A4
	move.b	$2D(A6),D0
	and.w	#$1F,D0
	add.w	D0,D0
	add.w	D0,A4
	lea	tfmx_L002018(PC),A5
	move.b	$10(A6),D1
	bmi	tfmx_C001864
	and.w	#$1F,D1
	add.w	D1,D1
	lea	tfmx_L0020E0(PC),A0
	add.w	D1,A0
	move.w	4(A5),(A0)
	move.b	7(A5),$41(A0)
	move.w	$24(A6),$80(A0)
tfmx_C001864	bsr	tfmx_C001A28
	move.w	$100(A4),4(A5)
	move.w	$100(A4),0(A5)
	move.w	$140(A4),2(A5)
	move.w	$180(A4),D2
	btst	#0,$2C(A6)
	beq.s	tfmx_C0018B8
	lea	tfmx_L0020E0(PC),A0
	add.w	D0,A0
	move.w	(A0),4(A5)
	moveq	#0,D2
	move.b	$41(A0),D2
	tst.w	$80(A0)
	beq.s	tfmx_C0018B8
	move.w	$80(A0),$24(A6)
	move.b	$80(A0),$BFD700
	move.b	$81(A0),$BFD600
	clr.w	$80(A0)
	bra.s	tfmx_C0018DE

tfmx_C0018B8	cmp.w	#15,D2
	bls.s	tfmx_C0018DE
	move.w	D2,D0
	move.w	6(A5),D2
	move.l	#$1B51F8,D1
	divu	D0,D1
	move.w	D1,$24(A6)
	move.b	$24(A6),$BFD700
	move.b	D1,$BFD600
tfmx_C0018DE	move.w	#$1C,D1
	lea	tfmx_W0021C6(PC),A4
tfmx_C0018E6	move.l	A4,$28(A5,D1.W)
	move.w	#$FF00,$48(A5,D1.W)
	clr.l	$68(A5,D1.W)
	subq.w	#4,D1
	bpl.s	tfmx_C0018E6
	move.w	D2,6(A5)
	tst.b	$2D(A6)
	bmi.s	tfmx_C00190A
	move.l	0(A6),A4
	bsr	tfmx_C0007CE
tfmx_C00190A	clr.b	13(A6)
	clr.w	$1C(A6)
	st	$36(A6)
	move.b	$2D(A6),$10(A6)
	clr.b	$2C(A6)
	clr.w	$48(A6)
	lea	tfmx_L0021A0(PC),A4
	clr.w	0(A4)
	clr.b	$15(A4)
	bset	#1,$BFE001
	move.w	#$FF,$DFF09E
	move.b	#1,$1E(A6)
	rts

tfmx_C001948	movem.l	A2-A6,-(SP)
	lea	tfmx_L001B0C(PC),A6
	move.l	#$40400000,$30(A6)
	clr.b	$11(A6)
	move.l	D0,0(A6)
	move.l	D1,4(A6)
	move.l	D1,A4
	clr.l	(A4)
	move.l	D1,8(A6)
	move.l	D0,A4
	tst.l	$1D0(A4)
	beq.s	tfmx_C00199E
	move.l	$1D0(A4),D1
	add.l	D0,D1
	move.l	D1,$38(A6)
	move.l	$1D4(A4),D1
	add.l	D0,D1
	move.l	D1,$3C(A6)
	move.l	$1D8(A4),D1
	add.l	D0,D1
	move.l	D1,$40(A6)
	add.l	#$200,D0
	move.l	D0,$44(A6)
	bra.s	tfmx_C0019C2

tfmx_C00199E	move.l	#$800,D1
	add.l	D0,D1
	move.l	D1,$38(A6)
	move.l	#$400,D1
	add.l	D0,D1
	move.l	D1,$3C(A6)
	move.l	#$600,D1
	add.l	D0,D1
	move.l	D1,$40(A6)
tfmx_C0019C2	lea	tfmx_C000C2C(PC),A4
	lea	tfmx_L002018(PC),A5
	move.w	#5,6(A5)
	lea	tfmx_L0020E0(PC),A6
	move.w	#$1F,D0
tfmx_C0019D8	move.w	#5,$40(A6)
	clr.w	$80(A6)
	clr.w	(A6)+
	dbra	D0,tfmx_C0019D8
	lea	tfmx_L001B0C(PC),A6
	lea	tfmx_L001B58(PC),A4
	lea	tfmx_L001B98(PC),A5
	move.l	A5,(A4)+
	lea	tfmx_L001C28(PC),A5
	move.l	A5,(A4)+
	lea	tfmx_L001CB8(PC),A5
	move.l	A5,(A4)+
	lea	tfmx_L001D48(PC),A5
	move.l	A5,(A4)+
	moveq	#11,D0
tfmx_C001A0A	move.l	-$10(A4),(A4)+
	dbra	D0,tfmx_C001A0A
	movem.l	(SP)+,A2-A6
	rts

tfmx_C001A18	move.l	A6,-(SP)
	lea	tfmx_L001B0C(PC),A6
	subq.l	#4,A0
	move.l	A0,8(A6)
	move.l	(SP)+,A6
	rts

tfmx_C001A28	movem.l	A5/A6,-(SP)
	lea	tfmx_L001B0C(PC),A6
	clr.w	$24(A6)
	move.l	4,A5
	cmp.b	#$32,$212(A5)
	bne.s	tfmx_C001A66
	move.b	#$37,$BFD700
	move.b	#$6C,$BFD600
	move.l	0(A6),A5
	btst	#1,11(A5)
	beq.s	tfmx_C001A88
	move.w	#$376C,$24(A6)
	bra.s	tfmx_C001A88

tfmx_C001A66	move.b	#$37,$BFD700
	move.b	#$F0,$BFD600
	move.l	0(A6),A5
	btst	#1,11(A5)
	bne.s	tfmx_C001A88
	move.w	#$37EE,$24(A6)
tfmx_C001A88	tst.l	$20(A6)
	bne.s	tfmx_C001A96
	move.w	#$A000,$DFF09A
tfmx_C001A96	movem.l	(SP)+,A5/A6
	rts

_timerInterrupt:
tfmx_C001A9C	move.l	A6,-(SP)
	bsr	tfmx_C000464
	move.l	(SP)+,A6
	rts

tfmx_C001AA6	movem.l	A0/A6,-(SP)
	lea	tfmx_L001B0C(PC),A6
	move.w	$DFF01C,14(A6)
	move.w	#$8020,$DFF09A
	movem.l	(SP)+,A0/A6
	rts

tfmx_C001AC4	move.l	A6,-(SP)
	move.w	#$4780,$DFF09A
	lea	tfmx_L001B0C(PC),A6
	bsr	tfmx_C00178A
	tst.l	$28(A6)
	beq.s	tfmx_C001AE0
	clr.l	$28(A6)
tfmx_C001AE0	tst.l	$14(A6)
	beq	tfmx_C001AEC
	clr.l	$14(A6)
tfmx_C001AEC	tst.l	$20(A6)
	beq.s	tfmx_C001AF6
	clr.l	$20(A6)
tfmx_C001AF6	lea	tfmx_L001B0C(PC),A6
	or.w	#$C000,14(A6)
	move.w	14(A6),$DFF09A
	move.l	(SP)+,A6
	rts

tfmx_L001B0C	dcb.l	$9,0
	dc.l	$7FFF0000
	dcb.l	$2,0
	dc.l	$40400000
	dc.l	$FFFF
	dcb.l	$5,0
tfmx_L001B58	dcb.l	$10,0
tfmx_L001B98	dcb.l	$5,0
	dc.l	$82010001
	dcb.l	$B,0
	dc.l	$80800080
	dcb.l	$3,0
	dc.l	$90
	dc.l	$DFF0A0
	dc.l	0
	dc.l	4
	dcb.l	$A,0
	dc.l	$FF00
tfmx_L001C28	dcb.l	$5,0
	dc.l	$82020002
	dcb.l	$B,0
	dc.l	$81000100
	dcb.l	$3,0
	dc.l	$90
	dc.l	$DFF0B0
	dc.l	0
	dc.l	$104
	dcb.l	$A,0
	dc.l	$FF00
tfmx_L001CB8	dcb.l	$5,0
	dc.l	$82040004
	dcb.l	$B,0
	dc.l	$82000200
	dcb.l	$3,0
	dc.l	$90
	dc.l	$DFF0C0
	dc.l	0
	dc.l	$204
	dcb.l	$A,0
	dc.l	$FF00
tfmx_L001D48	dcb.l	$5,0
	dc.l	$82080008
	dcb.l	$B,0
	dc.l	$84000400
	dcb.l	$3,0
	dc.l	$FFFFFE50
	dc.l	$DFF0D0
	dc.l	0
	dc.l	$304
	dcb.l	$A,0
	dc.l	$FF00
	dcb.l	$23,0
	dc.l	$FF00
	dcb.l	$23,0
	dc.l	$FF00
	dcb.l	$23,0
	dc.l	$FF00
	dcb.l	$23,0
	dc.l	$FF00
tfmx_L002018	
	dc.w	0
_songLength:
	dc.w	0	
_songPosition:
	dc.w	0
    dc.w    6
	dcb.l	$30,0
tfmx_L0020E0	dcb.l	$30,0
tfmx_L0021A0	dcb.l	$9,0
	dc.w	0
tfmx_W0021C6	dc.w	$F400
	dc.w	0
	dc.w	$F000
	dc.w	0
tfmx_W0021CE	dc.w	$6AE
	dc.w	$64E
	dc.w	$5F4
	dc.w	$59E
	dc.w	$54D
	dc.w	$501
	dc.w	$4B9
	dc.w	$475
	dc.w	$435
	dc.w	$3F9
	dc.w	$3C0
	dc.w	$38C
	dc.w	$358
	dc.w	$32A
	dc.w	$2FC
	dc.w	$2D0
	dc.w	$2A8
	dc.w	$282
	dc.w	$25E
	dc.w	$23B
	dc.w	$21B
	dc.w	$1FD
	dc.w	$1E0
	dc.w	$1C6
	dc.w	$1AC
	dc.w	$194
	dc.w	$17D
	dc.w	$168
	dc.w	$154
	dc.w	$140
	dc.w	$12F
	dc.w	$11E
	dc.w	$10E
	dc.w	$FE
	dc.w	$F0
	dc.w	$E3
	dc.w	$D6
	dc.w	$CA
	dc.w	$BF
	dc.w	$B4
	dc.w	$AA
	dc.w	$A0
	dc.w	$97
	dc.w	$8F
	dc.w	$87
	dc.w	$7F
	dc.w	$78
	dc.w	$71
	dc.w	$D6
	dc.w	$CA
	dc.w	$BF
	dc.w	$B4
	dc.w	$AA
	dc.w	$A0
	dc.w	$97
	dc.w	$8F
	dc.w	$87
	dc.w	$7F
	dc.w	$78
	dc.w	$71
	dc.w	$D6
	dc.w	$CA
	dc.w	$BF
	dc.w	$B4
	dc.w	0
end
