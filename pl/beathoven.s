;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000

testi=1

;Start
;        moveq   #-1,D0                  ; security
;        rts
;
;        dc.b    'BEATHOVEN109'          ; ID string, use BEATHOVEN100 for
;                                        ; first version of Beathoven mods
;                                        ; or BEATHOVENNEW for last version
;                                        ; of Beathoven mods (higher than 1.20)
;
;        dc.l    Play                    ; pointer to Interrupt routine
;                                        ; (must exist)
;        dc.l    InitSong                ; pointer to InitSong routine
;                                        ; (must exist)
;        dc.l    1                       ; number of subsongs (must exist)
;
;        dc.l    EndSound                ; pointer to EndSound routine
;                                        ; (must exist or 0)
;        dc.l    0                       ; pointer to optional InitPlayer
;                                        ; routine (must exist or 0)
;        dc.l    ModuleName              ; pointer to module name label
;                                        ; (must exist or 0)
;        dc.l    AuthorName              ; pointer to module author label
;                                        ; (must exist or 0)
;        dc.l    SpecialInfo             ; pointer to special text label
;                                        ; (must exist or 0)
;        dc.l    SampleInfo              ; pointer to SampleInfo label
;                                        ; (must exist or 0)
;        dc.l    EndSampleInfo           ; pointer to end of SampleInfo label
;                                        ; (must exist or 0)
;        dc.l    ModuleEnd-Start         ; size of loaded file
;        dc.l    ModuleEnd-ModuleStart   ; size of loaded module
;        dc.l    SampleEnd-SampleStart   ; size of samples
;        dc.l    (ModuleEnd-ModuleStart)-(SampleEnd-SampleStart)
;                                        ; size of songdata (with replayer)
;        dc.l    0                       ; timer speed (must exist or 0) for
;                                        ; old (BEATHOVEN100) mods or pointer
;                                        ; to samples file for (BEATHOVENNEW)
;                                        ; new mods


* play
BEAT_PLAY = 16
* init, song in d0
BEAT_INIT = 20
* num of subsongs
BEAT_SUBSONGS = 24 
* optional end 
BEAT_END = 28
* optional init player
BEAT_OPT_INIT = 32
* module name
BEAT_NAME = 36
* author name
BEAT_AUTHOR = 40

 ifne testi
	lea	module,a4
	bsr	id_beathoven
	beq	yes
	rts
yes
	 lea	module+$20,a0
	move.l	BEAT_SUBSONGS(a0),d0

   	 move.l  BEAT_INIT(a0),a0
   	 moveq   #0,d0
    	jsr (a0)

	 lea	module+$20,a0
	move.l	BEAT_OPT_INIT(a0),d0
	beq.b	.noOpt
	move.l	d0,a0
	jsr 	(a0)
.noOpt


loop
	cmp.b	#$80,$dff006	
	bne.b	loop
.e	cmp.b	#$81,$dff006	
	bne.b	.e

	move	#$ff0,$dff180
	
    lea	module+$20,a0
    move.l  BEAT_PLAY(a0),a0
    moveq   #0,d0
    jsr (a0)

	clr	$dff180

	btst	#6,$bfe001
	bne.b	loop

	lea	module+$20,a0
	  move.l  BEAT_END(a0),d0
	beq.b	o1
    	move.l	d0,a0
	jsr  (a0)
o1

	;jsr	Mt_end
	rts

* in: a4 = module
* out: 
*   d0 = 0, is beathoven
*   do = -1, is not beathoven
id_beathoven
    * these seem to be executables, so check for hunk
    cmp.l   #$3f3,(a4)
    bne.b   .notBeat
    * skip hunk header
    lea     $20(a4),a0
    cmp.l   #$70ff4e75,(a0)
    bne.b   .notBeat
    cmp.l   #'BEAT',4(a0)
    bne.b   .notBeat
    cmp.l   #'HOVE',8(a0)
    bne.b   .notBeat
    * looks good, relocate it
    move.l  a4,a0
    bsr reloc
    moveq   #0,d0
    rts
.notBeat    
    moveq   #-1,d0 
    rts

* relocate code hunk in a0
reloc
	lea	28(a0),a0
	move.l	(a0)+,d2
	lsl.l	#2,d2	
	move.l	a0,a1
	move.l	a0,d1
	lea	4(a0,d2.l),a0
	move.l	(a0)+,d2
	subq.l	#1,d2
	bmi.b	.024c
	addq.w	#4,a0
.0242	move.l	(a0)+,d0
	add.l	d1,(a1,d0.l)
	dbf	d2,.0242
.024c	addq.w	#8,a0
	rts	

	section b,data_c

module	
;  OK 
;  incbin "sys:music/roots/modules/beathoven/blackmonks trainer.bss"
;  incbin "sys:music/roots/modules/beathoven/dancingman.bss"
; incbin "sys:music/roots/modules/beathoven/denaris loading.bss"
; incbin "sys:music/roots/modules/beathoven/derpreisistheiss.bss"
; incbin "sys:music/roots/modules/beathoven/detonator hiscore.bss"
; incbin "sys:music/roots/modules/beathoven/detonator title.bss"
; incbin "sys:music/roots/modules/beathoven/funny funk.bss"
; incbin "sys:music/roots/modules/beathoven/ganymed.bss"
; incbin "sys:music/roots/modules/beathoven/gluecksrad.bss"
; incbin "sys:music/roots/modules/beathoven/in80daysaroundtheworld.bss"
; incbin "sys:music/roots/modules/beathoven/journey.bss"
; incbin "sys:music/roots/modules/beathoven/katakis loading.bss"
; incbin "sys:music/roots/modules/beathoven/letsdance.bss"
; incbin "sys:music/roots/modules/beathoven/phalanx ii.bss"
; incbin "sys:music/roots/modules/beathoven/rainbowartsslideshow.bss"
; incbin "sys:music/roots/modules/beathoven/ringside.bss"
; incbin "sys:music/roots/modules/beathoven/riskant!.bss"
; incbin "sys:music/roots/modules/beathoven/smash intro.bss"
; incbin "sys:music/roots/modules/beathoven/stars.bss"
; incbin "sys:music/roots/modules/beathoven/streetgang.bss"
; incbin "sys:music/roots/modules/beathoven/third intro.bss"
; incbin "sys:music/roots/modules/beathoven/tristar cracktro.bss"
; incbin "sys:music/roots/modules/beathoven/viruskillerv1.3pro.bss"
; incbin "sys:music/roots/modules/beathoven/viruskillerv2.0pro.bss"
; incbin "sys:music/roots/modules/beathoven/wetten dass.bss"
; incbin "sys:music/roots/modules/beathoven/zoom! (us).bss"
; incbin "sys:music/roots/modules/beathoven/zoom!.bss"

; KIPPAA? molemmat
; incbin "sys:music/roots/modules/beathoven/the great giana sisters ingame"
 incbin "sys:music/roots/modules/beathoven/the great giana sisters title"

 

; NOT OK
; incbin "sys:music/roots/modules/beathoven/katakis loading v1.bss"
; incbin "sys:music/roots/modules/beathoven/rock challenge.bss"

