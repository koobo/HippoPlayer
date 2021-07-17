;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000


testi = 1

 ifne testi


    bset #1,$bfe001  ;**** LED ****

    lea MUSICDATA,a4
    bsr id_gamemusiccreator
    beq okmod

    rts
okmod
    


    lea   MUSICDATA,a0      ;pointer to datablock to play 
    lea   mainvolume,a1
    lea	  songover,a2
    lea   curpos,a3
    lea   maxpos,a4

    jsr   MU_startmusic     ;start music
loop	
    cmp.b	#$80,$dff006
    bne.b	loop
.x  cmp.b	#$81,$dff006
    bne.b	.x

    move	#$ff0,$dff180
	jsr     MU_interrupt
    clr	$dff180

    btst #6,$bfe001
    bne loop 		;wait for mouseclick

    jsr   MU_stopmusic      ;stop music
    rts			;EXIT program
 
mainvolume  
    	dc.w    64
songover
    	dc.w 0
curpos 
	dc.w	0
maxpos
	dc.w	0

; in: a4 = module
; out: d0 = 0, valid GMC
;      d0 = -1, not GMC
id_gamemusiccreator
	;bra	.skip

    moveq   #15-1,d0
    move.l  a4,a0
.sampleLoop
    cmp.w   #$40,6(a0)
    bhi.w   .notGmc
 
    * sample len
    move    4(a0),d1 
    cmp     #$7fff,d1
    bhi.w   .notGmc
    add     d1,d1
    * loop length (?), must be less than total length
    move    12(a0),d2 
    cmp     d1,d2
    bhi.w   .notGmc

    add     #16,a0
    dbf d0,.sampleLoop

    * pattern table size
    cmp.l   #$64,240(a4)
    bhi.w   .notGmc
    tst.l   240(a4)
    beq.w   .notGmc

    * pattern order table
    moveq   #100-1,d0
    lea     244(a4),a0
    moveq   #0,d2 * numpat
.pattLoop
    move    (a0),d1
    and     #$3ff,d1
    bne.w   .notGmc
    move    (a0),d1
    lsr     #8,d1
    lsr     #2,d1
    cmp     d2,d1
    blo.b   .numpat
    move    d1,d2
.numpat

    addq    #2,a0
    dbf d0,.pattLoop

    addq    #1,d2

    * consider one pattern song illegal
    * but allow it if length is one
    cmp.l   #1,240(a4)
    beq.b  .len1
    cmp     #1,d2
    beq.w   .notGmc
.len1
    cmp     #100,d2
    bhi.w   .notGmc

 * validate  patterns
    move    d2,d7
    subq    #1,d7

    move.b  243(a4),d6  * count of patterns or positions?
    addq.b  #1,d6
    
.patterns
    lea     444(a4),a0
    * traverse a pattern
    * four bytes per channel per row,
    * so 16 bytes per row
    * pattern lenght is then 64 rows.
    * go through all 4 byte note slots in one pattern.
    move    #256-1,d4
.rows  

    * first two bytes are contain note
    * and sample info.
    * 3rd is command
    * 4th is command parameter

    * get command code.
    * 0 = no command
    * 1 = slide up
    * 2 = slide down
    * 3 = set volume
    * 4 = pattern break 
    * 5 = pos jump
    * 6 = filter clear
    * 7 = filter set 
    * 8 = song step
    *   = rest are ignored

    move.b  2(a0),d1
    and.b   #$0f,d1
    cmp.b   #8,d1
   ; bhi.b   .notGmc

    * set volume. check for max volume parameter
    cmp.b   #3,d1
    bne.b   .c3
    cmp.b   #$40,3(a0)
;    bhi.b   .notGmc
.c3

  ; jump instruction, check if jump is in valid range?
    cmp.b   #5,d1
    bne.b   .c5
    cmp.b   3(a0),d6
;;;;    bhs.b   .notGmc
    blo.b .notGmc
.c5

    move.l  (a0),d0
    move    d0,d5
    and     #$f000,d0
    beq.b   .noSample
    
    swap    d0
    move.w  d0,d1
    clr.w   d0
    swap    d0
    lsr.w   #8,d0
    lsr.w   #4,d0
    sub.w   #1,d0
    lsl.w   #4,d0
    
    lea     MUSICDATA,a3
    * a1 = low bound
    move.l  a3,a1
    * a2 = high bound
    move.l  a3,a2
    add.l   #MUSICDATALEN,a2
  
    add.l   d0,a3

    * check if a0 is within module
    * it should contain sample info for this note
    cmp.l   a1,a3
    blo.b   .notGmc
    cmp.l   a2,a3
    bhs.b   .notGmc

    * (a0).l = sample data
    * 4(a6).w = sample len
    * d1 = sample period
    * 6(a6) = sample vol

    * check vol
    cmp #$40,6(a3)
    bhi.b   .notGmc

    * check period validity

.noSample

    addq    #4,a0
    dbf     d4,.rows

    add	    #1024,a4
    dbf	    d7,.patterns


    moveq   #0,d0
    rts
.notGmc
    moveq  #-1,d0 
    rts

    section data,data_c

mod
MUSICDATA
 ;incbin  "sys:Music/Roots/Modules/Game Music Creator/Allister Brimble/terry's big adventure.gmc"

; id fixed:
; incbin "sys:Music/Roots/Modules/Game Music Creator/- unknown/knights of the sky 4.gmc"
; incbin "sys:Music/Roots/Modules/Game Music Creator/Francois Garofalo/pop-up menu.gmc"
; incbin "sys:Music/Roots/Modules/Game Music Creator/Matt Bates/deuteros-ingame 1.gmc"
 
* not identified properly:
 ;incbin "sys:Music/Roots/Modules/Game Music Creator/Paul McMaster/jet set willy 2 title.gmc"
 ;incbin "sys:Music/Roots/Modules/Game Music Creator/Robin Burrows/fatal mission - che bang.gmc"
 incbin "sys:Music/Roots/Modules/Game Music Creator/Ten Pin Alley/covert action - finalmusic.gmc"
 ;incbin "sys:Music/Roots/Modules/Game Music Creator/Ten Pin Alley/covert action - thememusic.gmc"

MUSICDATALEN = *-MUSICDATA


    section gmc,code_c
 endc

start

    jmp MU_startmusic(pc)
    jmp MU_interrupt(pc)
    jmp MU_stopmusic(pc)

*******************************************************
******** GameMusicCreator Replay-routine v1.0 *********
*******************************************************
MU_startmusic:
    move.l  a1,hip_mainvolume
    move.l  a2,hip_songover
    move.l  a3,hip_currentpos
    move.l  a4,hip_maxpos

    move.l  a0,MU_data
    move.l  a0,MU_tablepos
    move.l  a0,MU_songpointer
    add.l   #242,MU_tablepos
    add.l   #444,MU_songpointer
    move.w  #64,MU_patterncount
    clr.w   $dff0a8
    clr.w   $dff0b8
    clr.w   $dff0c8
    clr.w   $dff0d8
    move.w  #$f,$dff096
    clr.l   MU_vol0
    clr.l   MU_vol2
    clr.l   MU_pospointer
    clr.w   MU_songspeed
    clr.w   MU_note0
    clr.w   MU_note1
    clr.w   MU_note2
    clr.w   MU_note3
    clr.w   MU_slide0
    clr.w   MU_slide1
    clr.w   MU_slide2
    clr.w   MU_slide3
    clr.w   MU_stop
    clr.l   MU_chan0
    clr.l   MU_chan1
    clr.l   MU_chan2
    clr.l   MU_chan3
    move.w  #6,MU_songstep
    move.l  a0,a2
    add.l   #244,a2
    move.l  240(a0),d1
    sub.l   #1,d1
    clr.l   d0
MU_sizeloop:
    move.w  (a2)+,d2
    cmp.w   d2,d0
    bge     MU_nosizeadd
    move.w  d2,d0
MU_nosizeadd:
    dbf     d1,MU_sizeloop
    add.l   #1024,d0
    move.l  a0,a1
    add.l   #444,a1
    add.l   d0,a1
    move.l  #14,d7
    bsr     MU_calcins
    ;move.l  $6c,MU_oldirq+2
    ;move.l  #MU_interrupt,$6c
    rts

MU_calcins:
    cmp.l   #0,(a0)
    bne     MU_calcit
    add.l   #16,a0
    dbf     d7,MU_calcins
    rts 
MU_calcit:
    move.l  (a0),d0
    move.l  8(a0),d1
    sub.l   d0,d1  ;repeat
    move.l  a1,(a0)
    move.l  a1,d0
    add.l   d1,d0
    move.l  d0,8(a0) ;set repeat
    cmp.w   #2,12(a0)
    bne     mu_looping
    move.l  #MU_empty,8(a0)
mu_looping:
    clr.l   d0
    move.w  4(a0),d0 ;add sampletable
    lsl.l   #1,d0
    add.l   d0,a1
    add.l   #16,a0
    dbf     d7,MU_calcins
    rts

MU_stopmusic:
    ;move.l  MU_oldirq+2,$6c
    clr.w   $dff0a8
    clr.w   $dff0b8
    clr.w   $dff0c8
    clr.w   $dff0d8
    move.w  #$f,$dff096
    rts
MU_interrupt:
    movem.l  d0-d7/a0-a6,-(a7)
    ;btst     #5,$dff01f
    ;beq      MU_novertblank
    bsr      MU_playsong
MU_novertblank:
    movem.l  (a7)+,d0-d7/a0-a6
;MU_oldirq:  jmp $0
    rts
MU_playsong:
    bsr     MU_everyvert
    add.w   #1,MU_songspeed
    move.w  MU_songstep,d0
    cmp.w   MU_songspeed,d0
    ble     MU_okplay
    rts
MU_okplay: 
    clr.w   MU_songspeed
    add.w   #1,MU_patterncount
    cmp.w   #65,MU_patterncount
    bne     MU_playit
MU_setnewpat:
    ******* calc position ****
    add.l   #1,MU_pospointer
    move.l  MU_pospointer,d0

    move.l  hip_currentpos(pc),a0
    move    d0,(a0)
    move.l  hip_maxpos(pc),a0

    move.l  MU_data,a5
    move    240+2(a5),(a0)

    cmp.l   240(a5),d0
    bhi     MU_setstart
        ***********************
    move.w  #1,MU_patterncount
    add.l   #2,MU_tablepos
    move.l  MU_tablepos,a0
    clr.l   d0
    move.w  (a0),d0
    move.l  MU_data,a0
    add.l   #444,a0
    add.l   d0,a0
    move.l  a0,MU_songpointer
    bra     MU_playit
    ************************
MU_setstart:
    clr.l   MU_pospointer

    move.l  hip_songover(pc),a0
    st      (a0)

    move.l  MU_data,MU_tablepos
    add.l   #242,MU_tablepos
    bra     MU_setnewpat
MU_playit:
    move.l  MU_songpointer,a0
    add.l   #16,MU_songpointer
    move.l  (a0),d0
    clr.w   d3
    move.w  #1,d2
    bsr     MU_setinstr
    bsr     MU_seteffect
    move.l  4(a0),d0
    move.w  #2,d2
    bsr     MU_setinstr
    bsr     MU_seteffect
    move.l  8(a0),d0
    move.w  #3,d2
    bsr     MU_setinstr
    bsr     MU_seteffect
    move.l  12(a0),d0
    move.w  #4,d2
    bsr     MU_setinstr
    bsr     MU_seteffect
    move.w  d3,$dff096
    rts
MU_setinstr:
    move.w  d0,d5
    and.w   #$f000,d0
    cmp.w   #0,d0
    bne     MU_setit
    rts
MU_setit:
    swap    d0
    move.w  d0,d1
    clr.w   d0
    swap    d0
    lsr.w   #8,d0
    lsr.w   #4,d0
    sub.w   #1,d0
    lsl.w   #4,d0
    move.l  MU_data,a6
    add.l   d0,a6
    cmp.w   #1,d2
    bne     MU_conti1
    clr.w   $dff0a8
    move.l  a6,MU_chan0
    move.l  (a6),$dff0a0
    move.w  4(a6),$dff0a4
    move.w  d1,$dff0a6
    move.w  d1,MU_note0
    move.w  6(a6),MU_vol0
    clr.w   MU_slide0
    bset    #0,d3
    rts
MU_conti1:
    cmp.w   #2,d2
    bne     MU_conti2
    clr.w   $dff0b8
    move.l  a6,MU_chan1
    move.l  (a6),$dff0b0
    move.w  4(a6),$dff0b4
    move.w  d1,$dff0b6
    move.w  d1,MU_note1
    move.w  6(a6),MU_vol1
    clr.w   MU_slide1
    bset    #1,d3
    rts
MU_conti2:
    cmp.w   #3,d2
    bne     MU_conti3
    clr.w   $dff0c8
    move.l  a6,MU_chan2
    move.l  (a6),$dff0c0
    move.w  4(a6),$dff0c4
    move.w  d1,$dff0c6
    move.w  d1,MU_note2
    move.w  6(a6),MU_vol2
    clr.w   MU_slide2
    bset    #2,d3
    rts
MU_conti3:
    clr.w   $dff0d8
    move.l  a6,MU_chan3
    move.l  (a6),$dff0d0
    move.w  4(a6),$dff0d4
    move.w  d1,$dff0d6
    move.w  d1,MU_note3
    move.w  6(a6),MU_vol3
    clr.w   MU_slide3
    bset    #3,d3
    rts
MU_seteffect:
    move.w  d5,d6
    and.w   #$00ff,d5
    and.w   #$0f00,d6
    cmp.w   #0,d6
    beq     MU_effjump2
    cmp.w   #$0100,d6
    beq     MU_slideup
    cmp.w   #$0200,d6
    beq     MU_slidedown
    cmp.w   #$0300,d6
    beq     MU_setvolume
    cmp.w   #$0500,d6
    beq     MU_posjump
    cmp.w   #$0400,d6
    bne     MU_nobreak
MU_itsabreak:
    move.w  #64,MU_patterncount
    rts
MU_nobreak:
    cmp.w   #$0800,d6
    bne     MU_effjump0
    move.w  d5,MU_songstep
    rts
MU_effjump0:
    cmp.w   #$0600,d6
    bne     MU_effjump1
    bclr    #1,$bfe001
    rts
MU_effjump1:
    cmp.w   #$0700,d6
    bne     MU_effjump2
    bset    #1,$bfe001
MU_effjump2:
    rts
MU_posjump:
    clr.l   d4
    move.w  d5,d4
    sub.l   #1,d4
    move.l  d4,MU_pospointer
    add.l   #1,d4
    lsl.w   #1,d4
    sub.w   #2,d4
    move.l  MU_data,a0
    add.l   #244,a0
    add.l   d4,a0
    move.l  a0,MU_tablepos
    bra     MU_itsabreak
MU_slideup:
    neg.w   d5
MU_slidedown:
    cmp.w   #1,d2
    bne     MU_j1
    move.w  d5,MU_slide0
    rts
MU_j1:
    cmp.w   #2,d2
    bne     MU_j2
    move.w  d5,MU_slide1
    rts
MU_j2:
    cmp.w   #3,d2
    bne     MU_j3
    move.w  d5,MU_slide2
    rts
MU_j3:
    move.w  d5,MU_slide3    
    rts
MU_setvolume:
    cmp.w   #1,d2
    bne     MU_j00
    move.w  d5,MU_vol0
    ;move.w  d5,$dff0a8
    rts
MU_j00:
    cmp.w   #2,d2
    bne     MU_j22
    move.w  d5,MU_vol1
    ;move.w  d5,$dff0b8
    rts
MU_j22:
    cmp.w   #3,d2
    bne     MU_j33
    move.w  d5,MU_vol2
    ;move.w  d5,$dff0c8
    rts
MU_j33:
    move.w  d5,MU_vol3
    ;move.w  d5,$dff0d8
    rts
MU_everyvert:
    move.w  MU_slide0,d0
    add.w   d0,MU_note0
    move.w  MU_note0,$dff0a6
    move.w  MU_slide1,d0
    add.w   d0,MU_note1
    move.w  MU_note1,$dff0b6
    move.w  MU_slide2,d0
    add.w   d0,MU_note2
    move.w  MU_note2,$dff0c6
    move.w  MU_slide3,d0
    add.w   d0,MU_note3
    move.w  MU_note3,$dff0d6
    btst    #0,MU_stop
    beq     MU_ok1
    bclr    #0,MU_stop
    move.l  MU_chan0,a0
    move.l  8(a0),$dff0a0
    move.w  12(a0),$dff0a4
    clr.l   MU_chan0
MU_ok1:
    btst    #1,MU_stop
    beq     MU_ok2
    bclr    #1,MU_stop
    move.l  MU_chan1,a0
    move.l  8(a0),$dff0b0
    move.w  12(a0),$dff0b4
    clr.l   MU_chan1
MU_ok2:
    btst    #2,MU_stop
    beq     MU_ok3
    bclr    #2,MU_stop
    move.l  MU_chan2,a0
    move.l  8(a0),$dff0c0
    move.w  12(a0),$dff0c4
    clr.l   MU_chan2
MU_ok3:
    btst    #3,MU_stop
    beq     MU_ok4
    bclr    #3,MU_stop
    move.l  MU_chan3,a0
    move.l  8(a0),$dff0d0
    move.w  12(a0),$dff0d4
    clr.l   MU_chan3
MU_ok4:
    move.w   #$8000,d3
    cmp.l    #0,MU_chan0
    beq      MU_okk1
    bset     #0,MU_stop
    bset     #0,d3
MU_okk1:
    cmp.l    #0,MU_chan1
    beq      MU_okk2
    bset     #1,MU_stop
    bset     #1,d3
MU_okk2:
    cmp.l    #0,MU_chan2
    beq      MU_okk3
    bset     #2,MU_stop
    bset     #2,d3
MU_okk3:
    cmp.l    #0,MU_chan3
    beq      MU_okk4
    bset     #3,MU_stop
    bset     #3,d3
MU_okk4:
    move.w   d3,$dff096

    move.l  hip_mainvolume(pc),a0
    move    (a0),d3

    move    d3,d0
    mulu    MU_vol0(pc),d0
    lsr     #6,d0
    move    d0,$dff0a8

    move    d3,d0
    mulu    MU_vol1(pc),d0
    lsr     #6,d0
    move    d0,$dff0b8
    
    move    d3,d0
    mulu    MU_vol2(pc),d0
    lsr     #6,d0
    move    d0,$dff0c8
  
    move    d3,d0
    mulu    MU_vol3(pc),d0
    lsr     #6,d0
    move    d0,$dff0d8
  
    ;move.w   MU_vol0,$dff0a8
    ;move.w   MU_vol1,$dff0b8
    ;move.w   MU_vol2,$dff0c8
    ;move.w   MU_vol3,$dff0d8
    rts
********** variables *****
MU_stop:  dc.w 0
MU_slide0: dc.w 0
MU_slide1: dc.w 0
MU_slide2: dc.w 0
MU_slide3: dc.w 0
MU_chan0: dc.l 0
MU_chan1: dc.l 0
MU_chan2: dc.l 0
MU_chan3: dc.l 0
MU_note0: dc.w 0
MU_note1: dc.w 0
MU_note2: dc.w 0
MU_note3: dc.w 0
MU_vol0: dc.w 0
MU_vol1: dc.w 0
MU_vol2: dc.w 0
MU_vol3: dc.w 0
MU_songspeed: dc.w 0
MU_songstep: dc.w 5
MU_patterncount: dc.w 0
MU_songpointer: dc.l 0
MU_tablepos: dc.l 0
MU_pospointer: dc.l 0 
MU_empty: blk.l 2,0
MU_data: dc.l  0

hip_mainvolume: dc.l 0
hip_songover:   dc.l 0
hip_currentpos: dc.l 0
hip_maxpos: dc.l 0
*************************************************
*************************************************

