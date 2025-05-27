;APS0000422E000000000000000000000000000000000000000000000000000000000000000000000000

	incdir	include:
	include	exec/exec_lib.i
	include	exec/interrupts.i
	include	hardware/intbits.i
	include	hardware/cia.i
	include	resources/cia_lib.i
	include	exec/ports.i
	include	mucro.i
	;incdir

_ciaa	=	$bfe001
_ciab	=	$bfd000

CHM	=	0	* 1: k‰‰nnet‰‰n channelmask-homma mukaan
fast	=	1	* 0: ei fastram rutiinia
dmawait	set	1	* 1: isot dmawaitit, toimii esim super72 jne,
			* 0: tavalliset, 6+3 tms

dmwait set dmawait|fast


*******************************************************************************
*                  KPlayer v33 --- 31.3.1996 © by K-P Koljonen                *
*******************************************************************************
* A flexible and fast ProTracker-module player.
* All commands excluding E4 and E7 are supported.
*
* k_init
* ≠≠≠≠≠≠
* Initialize everything necessary (no audiochannel allocating), convert
* patterndata to KPlayer format.
* A0   <= 2000 bytes buffer (for variables etc.)
* A1   <= Protracker/Noisetracker/Stattrekker module, 64 or 100 patterns
* D0.b <= Starting position
* D1.b <= 0: user, 1: automatic cia
* D2.b <= Flags, bit 0: tempo, bit 1: fast ram play
* D0   => 0: OK, -1: Couldn't allocate CIA timer or invalid module.
*
* k_music
* ≠≠≠≠≠≠≠
* In modes 0 and 1 call this every frame to play the music.
* 
* k_end
* ≠≠≠≠≠
* Stop the audio DMA and interrupts.
* D0.w => Stopping position
*
* k_channelmask
* ≠≠≠≠≠≠≠≠≠≠≠≠≠
* D0.b <= Channelmask. Set bit = channel enabled,
*         bit 0 = channel 0 ... bit 3 = channel 3.
*	  Disabled channel of the module will be totally ignored and no
*         audio registers will be changed.
* 
* k_playstop
* ≠≠≠≠≠≠≠≠≠≠
* D0.b <= 0: Play, non-0: don't play
*
* k_setmaster
* ≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠
* Set the mastervolume of the music (default max=64).
* D0.b <= Mastervolume
*
* k_clear 
* ≠≠≠≠≠≠≠
* Stop audio DMA.
*
* Timing modes
* ≠≠≠≠≠≠≠≠≠≠≠≠
* 0 - system friendly, no tempo, no interrupts, DMA wait
* 1 - no tempo, CIAB timer B interrupt
* 2 - tempo, CIAB timers A and B
* 3 - system friendly, tempo, CIAA timer A or B interrupt, DMA wait
*
* k_base
* ≠≠≠≠≠≠
* k_base is the data area for KPlayer where all the variables
* needed for playing one module is located. 
*
* Speed
* ≠≠≠≠≠
* Rastertime usage with most modules is between 2 and 7 lines on 68000
* Amigas. In addition to these lines, modes 0 and 3 use a DMA wait of 7+3
* lines.
* Setting the mastervolume to maximum (64) will gain some speed (no need
* to scale volumes).
* Fast ram player uses about 15% cpu on A500.
*
* Usertrig
* ≠≠≠≠≠≠≠≠
* It's possible to use the information in k_base to make quadrascopes etc.
* The byte k_usertrig (k_base+k_usertrig) has four bits (0-3) for every
* channel. At the same time as one of these bits sets, a new sample
* in the respective channel starts to play. You should clear k_usertrig after 
* you've read it.
*   Samplestarts, volumes, periods, etc. can be found by examining the
* k_base structure below.
*
* KPlayer by: K-P Koljonen
* 	      Torikatu 31
*	      40900 S‰yn‰tsalo
*	      Finland
*		
*	      kpkoljon@freenet.hut.fi
*
*******************************************************************************
	rsreset				* Routine offsets, kplayer+kp_????
kp_init		rs.l	1
kp_music	rs.l	1
kp_end		rs.l	1
kp_setmaster	rs.l	1
kp_channelmask	rs.l	1
kp_playstop	rs.l	1
kp_clear	rs.l	1
kp_baseaddress	rs.l	1	* This is where the k_base addr is stored.

* channel data blocks
	rsreset
n_data		rs.l	1
n_start		rs.l	1	* Sample start address
n_length	rs	1	* Sample length (words)
n_volume	rs	1	* Volume
n_periodaddr	rs.l	1
n_loopstart	rs.l	1	* Loopstart
n_replen	rs	1	* Looplength
n_wavestart	rs.l	1
n_period	rs	1	* Period
n_dmabit	rs	1
n_toneportspeed	rs	1
n_wantedperiod	rs	1
n_pattpos	rs	1
n_period2	rs	1
n_tempvol	rs	1
n_sampleoffset	rs	1
n_vibratopos	rs.b	1
n_tremolopos	rs.b	1
n_toneportdirec	rs.b	1
n_vibratocmd	rs.b	1
n_tremolocmd	rs.b	1
n_loopcount	rs.b	1
n_funkoffset	rs.b	1
n_funkspeed	rs.b	1
n_retrig	rs.b	1
n_glisscontrol	rs.b	1


n_flag		rs	1
n_buffer	rs.l	1	* chip buffer (1kb)
n_datapointer	rs.l	1
n_datalength	rs.l	1
n_datarepointer	rs.l	1
n_datarelength	rs.l	1

n_sizeof	rs.b	0	* channel temp size

* variables & data
	rsreset	
k_counter	rs.b	1
k_speed		rs.b	1
k_posjumpflag	rs.b	1
k_pbreakflag	rs.b	1
k_pattdeltime	rs.b	1
k_pattdeltime2	rs.b	1
k_songpos	rs	1		* Song position
k_pbreakpos	rs	1
k_patternpos	rs	1		* Patternposition
k_dma		rs	1
k_mastervolume	rs	1
k_songdataptr	rs.l	1
k_fast		rs.b	1		* <>0: samplet fastissa
k_timingmode 	rs.b	1

k_filterstore	rs.b	1
k_trig		rs.b	1
k_tempo		rs.b	1
k_usetempo	rs.b	1		* ~0: ei tempoa
k_usertrig	rs.b	1		* User trigger
k_sysint	rs.b	1
k_playmusic	rs.b	1		* 0 = play
k_songover	rs.b	1		* Song played n times
k_chmask	rs.b	1		* Kanavamaski
k_intid		rs.b	1
k_whichtimer	rs.b	1
	rs.b	1

k_timerhi	rs.b	1
k_timerlo	rs.b	1
k_timervalue	rs.l	1
k_ciabase	rs.l	1		* cia?.resource base
k_cia		rs.l	1		* ciab tai ciaa osoite

k_null		rs.l	1
k_oldis1	rs.l	1
k_oldis2	rs.l	1
k_oldis3	rs.l	1
k_oldis4	rs.l	1

k_mt		rs.l	31		* Sampleaddresses

k_chan1temp	rs.b	n_sizeof	* Channel data blocks
k_chan2temp	rs.b	n_sizeof
k_chan3temp	rs.b	n_sizeof
k_chan4temp	rs.b	n_sizeof

k_roundtable	rs.b	1512

k_sizeof	rs.b	0		* size of k_base

 ifnd __VASM
main
;	move	$dff01c,-(sp)
;	move	#$7fff,$dff09a

	lea	k_base,a0
	lea	module,a1
	moveq	#0,d0
	moveq	#0,d1		* Mode
	moveq	#0,d1		* Mode
;	moveq	#%11,d2		* flags, fastramyes, tempoyes
;	moveq	#%01,d2		* flags, tempoyes


	bsr.b	kplayer+kp_init
 	tst.l	d0
	bne.b	.error

 ifne CHM
	moveq	#%0001,d0
	bsr	kplayer+kp_channelmask
 endc

	moveq	#$3f,d0
	bsr.b	kplayer+kp_setmaster

.loop	

.1	cmp.b	#$60,$dff006
	bne.b	.1
.2	cmp.b	#$60,$dff006
	beq.b	.2

	tst.b	k_base+k_timingmode
	bne.b	.rr

;	move	#$ff0,$dff180
	bsr.w	k_music
;	clr	$dff180
.rr
	btst	#6,$bfe001	* left
	bne.b	.loop

	bsr.b	kplayer+kp_end
.error	rts
 endif



*******************************************************************************

* sample
	rsreset
s_start		rs.l	1
s_length	rs	1
s_volume	rs	1
s_periodaddr	rs.l	1	* s_finetune k‰yt‰nnˆss‰
s_loopstart	rs.l	1
s_replen	rs	1
s_wavestart	rs.l	1

* note
d_command	=	0
d_period	=	2
d_samplenum	=	3

* orig. sampleinfo
ss_length	=	42-42
ss_finetune	=	44-42
ss_volume	=	45-42
ss_repeat	=	46-42
ss_replen	=	48-42

binstart
kplayer
	bra.b	k_init
	rts
	bra.w	k_music
	bra.w	k_end
	bra.w	k_setmaster
 ifne CHM
	bra.w	k_channelmask
 else
 	rts
 	rts
 endc
	bra.w	k_playstop
	bra.w	k_clear

k_baseaddr 	dc.l	0	* k_base's address

k_intname
 dc.b " KPlayer v33 © 31.3.1996 by K-P Koljonen",0
k_cianame	dc.b	"ciaa.resource",0
 even

***********************
*        Init         
***********************

k_init	cmp.l	#'M.K.',1080(a1)
	beq.b	k_valid
	cmp.l	#'M!K!',1080(a1)
	beq.b	k_valid
	cmp.l	#'FLT4',1080(a1)
	beq.b	k_valid
	moveq	#-1,d0
	rts
k_valid	movem.l	d1-a6,-(sp)
	lea	k_baseaddr(pc),a5
	move.l	a0,(a5)
	move.l	a0,a5

	move	#k_sizeof/2-1,d7	* tyhj‰t‰‰n muuttujatila
k_c	clr	(a0)+
	dbf	d7,k_c

	move.l	a1,a4
	move.b	d0,k_songpos+1(a5)
	move.b	d1,k_timingmode(a5)
	move.b	#%1111,k_chmask(a5)
	ror.b	#1,d2
	spl	k_usetempo(a5)

 ifne fast
	ror.b	#1,d2
	smi	k_fast(a5)
	bpl.b	.chip

	pushm	all
	move.l	4.w,a6
	move.l	#1024,d0
	moveq	#2,d1			* MEMF_CHIP
	move.l	#$10002,d1		* MEMF_CHIP!MEMF_CLEAR
	lob	AllocMem
	move.l	d0,a0
	move.l	a0,n_buffer+k_chan1temp(a5)
	lea	256(a0),a0
	move.l	a0,n_buffer+k_chan2temp(a5)
	lea	256(a0),a0
	move.l	a0,n_buffer+k_chan3temp(a5)
	lea	256(a0),a0
	move.l	a0,n_buffer+k_chan4temp(a5)
	popm	all
.chip
 endc
	move	#1,k_chan1temp+n_dmabit(a5)
	move	#2,k_chan2temp+n_dmabit(a5)
	move	#4,k_chan3temp+n_dmabit(a5)
	move	#8,k_chan4temp+n_dmabit(a5)
	move.b	#6,k_speed(a5)		* nopeus: 6
	move.b	#4,(a5)			* laskuri: 4

	move	#$40,k_mastervolume(a5)	* p‰‰volume: 64
	move.b	#125,k_tempo(a5)	* tempo: 125


	lea	k_mt(a5),a3		* sampleinfo lista
	moveq	#31-1,d0
	lea	20(a4),a2
k_mkm	move.l	a2,(a3)+
	lea	30(a2),a2
	dbf	d0,k_mkm

	lea	952(a1),a0		* tutkitaan patternien m‰‰r‰
	moveq	#128-1,d0	
	moveq	#0,d1
k_lop1
	move.b	(a0)+,d2
	cmp.b	d2,d1
	bhi.b	k_lop2
	move.b	d2,d1
k_lop2
	dbf	d0,k_lop1
	addq	#1,d1

	mulu	#1024,d1	* Eka sample patternien j‰lkeen
	lea	1084(a4),a0
	add.l	d1,a0
	lea	42(a4),a2

	clr.l	(a4)		* moduulin alkuun tyhj‰ longwordi!
	move.l	a4,k_null(a5)

	lea	20(a4),a1	* vet‰st‰‰n samplennimien p‰‰lle

	lea	k_pertab(pc),a3
	move.l	a3,d5
	
	move.l	a0,d7
	moveq	#0,d4
	moveq	#31-1,d0
k_lop3				* Tehd‰‰n omat sampleinfo (alkup.nimien p‰‰lle)

** Versio 3 (toimii, ehk‰)

        move.l  a0,s_start(a1)
        moveq   #0,d1
        move    (a2),d1         * onk
	cmp	#2,d1		* joku raja pit‰‰ vet‰‰: ei alle 4b sampleja
	bhs.b	k_nonol

        move    #1,ss_replen(a2) * To
	move    #1,s_length(a1)  * Pi
	move.l	a0,-(sp)
	move.l	a4,a0			* nullsample
	bsr.b	k_noe
	move.l	(sp)+,a0
	bra.b	k_nil

k_nonol move    d1,s_length(a1)
        clr     (a0)
	bsr.b	k_noe

k_nil	dbf	d0,k_lop3
	bra.b	k_konmo

k_noe	
	move.l	d1,d4
	add.l	d4,d4

	moveq	#%1111,d1
	and.b	ss_finetune(a2),d1
	add	d1,d1

	move.l	d1,a3
	add.l	d5,a3
	add	(a3),a3
	move.l	a3,s_periodaddr(a1)

	move.b	ss_volume(a2),d1
	move	d1,s_volume(a1)

	move	ss_repeat(a2),d1
	beq.b	k_norep

	moveq	#0,d3
	move	d1,d3
	add.l	d3,d3
	move.l	a0,d2
	add.l	d3,d2
	move.l	d2,s_loopstart(a1)
	move.l	d2,s_wavestart(a1)
	move	ss_replen(a2),d2
	add	d2,d1
	move	d1,s_length(a1)
	move	d2,s_replen(a1)
	bra.b	k_wasrep
k_norep
	move.l	a0,s_loopstart(a1)
	move.l	a0,s_wavestart(a1)
	move	ss_replen(a2),s_replen(a1) 
	bne.b	.ye
	move	#1,s_replen(a1)			* V‰hint‰‰n 1!!
.ye
k_wasrep

k_dud	add.l	d4,a0
	lea	30(a1),a1
	lea	30(a2),a2
	rts

k_konmo
	
	lea	1084(a4),a3
	lea	952(a4),a4
	move.l	a4,k_songdataptr(a5)

	subq.l	#1,a4
	moveq	#'K',d0
	cmp.b	(a4),d0
	beq.w	k_what			* moduuli kertaalleen convertattu
	move.b	d0,(a4)			* tunniste


* tehd‰‰n perioidien pyˆristystaulukko
	moveq	#36-1,d2
	lea	k_pt2(pc),a0
	lea	k_roundtable(a5),a1
	moveq	#100,d0
.eee	move	-(a0),d1
.ee	cmp	d0,d1
	beq.b	.e
	move	d1,(a1)+
	addq	#1,d0
	bra.b	.ee
.e	dbf	d2,.eee



	move.l	d7,a4			* patterndatan loppu
	move	#$fff,d6
	lea	k_periodtable(pc),a1
	lea	k_roundtable(a5),a2
	
k_conv					* K‰‰nnet‰‰n KPlayer-muotoon
	move	(a3),d0
	and	d6,d0
	beq.b	k_nope		

	sub	#100,d0			* (pyˆristetty) perioidi taulukosta
	add	d0,d0
	move	-3*2(a2,d0),d0

* max=907-108
;	cmp	#907,d0			* onko period sallituissa rajoissa?
;	bhi.b	k_nope
;	cmp	#108,d0
;	blo.b	k_nope

* 36 nuottia
	moveq	#36-1,d2

	move.l	a1,a0
	moveq	#1,d1
k_findit
	cmp	(a0)+,d0
	beq.b	k_wasi
	addq	#2,d1
	dbf	d2,k_findit

k_nope
	moveq	#0,d1		* ei perioidia
k_wasi	
	moveq	#$10,d3		* samplenum=4+1 bitti‰
	and.b	(a3),d3
	move.b	2(a3),d4
	lsr.b	#4,d4
	or.b	d4,d3		* samplenumero
	lsl.b	#2,d3		* kertaa 4

	move	2(a3),d4
	and	d6,d4		* command

	move	d4,d5		* patternbreak
	and	#$0f00,d5
	cmp	#$0d00,d5
	bne.b	k_grr

	move	d4,d5		* muutetaan patternbreak (D00)
	and	#$f0,d5
	lsr	#4,d5
	mulu	#10,d5
	and	#$f0f,d4
	add	d5,d4
k_grr
	cmp	#$0ED0,d4	* Onko notedelay ilman delayta?
	bne.b	.gr		* Poistetaan sellaiset.
	moveq	#0,d4
.gr
	ror	#8,d4
	lsl.b	#2,d4		* kerrotaan komento nelj‰ll‰
	rol	#8,d4

	move	d4,(a3)+
	move.b	d1,(a3)+
	move.b	d3,(a3)+

	cmp.l	a4,a3
	blo.b	k_conv
k_what	

 	bsr.w	k_foff		* filtteri pois ja ent.asento talteen
	sne	k_filterstore(a5)
	bsr.w	k_clear

	st	k_whichtimer(a5)

	moveq	#0,d0
	cmp.b	#1,k_timingmode(a5)
	beq.b	.ff
	bsr.b	k_moodi
	bra.b	.fe
.ff	bsr.b	k_imode3
.fe	tst.l	d0

x	movem.l	(sp)+,d1-a6
	rts


k_moodi
	st	k_usetempo(a5)		* tempo pois
 ifne fast
	bsr.w	k_fastinit
 endc
	moveq	#0,d0
	rts

k_imode3
	lea	softint(pC),a0
	lea	intserver(pC),a1
	pea	k_softkiller1(pc)
	move.l	(sp)+,IS_CODE(a0)
	pea	k_intname(pc)
	move.l	(sp),LN_NAME(a0)
	move.l	(sp)+,LN_NAME(a1)
	pea	k_killer3(pc)
	move.l	(sp)+,IS_CODE(a1)
	pea	softint(pc)
	move.l	(sp)+,IS_DATA(a1)
	lea	dummyserver(pc),a0
	pea	dummy(pc)
	move.l	(sp)+,IS_CODE(a0)


	bsr.w	k_timerval

* k‰ytet‰‰n CIAA timeri‰.
	lea	_ciaa,a3
	moveq	#0,d6
	lea	k_cianame(pc),a1
	move.b	#'a',3(a1)
	moveq	#0,d0
	move.l	4.w,a6
	move.l	a6,exeksi-k_cianame(a1)
	lob	OpenResource
	move.l	d0,k_ciabase(a5)
	beq.b	.se
	move.l	d0,a6

	lea	intserver(pc),a1
	move.l	d6,d0
	lob	AddICRVector
	tst.l	d0
	beq.b	k_gottimer		* Saatiinko?

	lea	intserver(pc),a1
	moveq	#1,d6			* timer b
	move.l	d6,d0
	lob	AddICRVector
	tst.l	d0
	beq.b	k_gottimer

.se
** kokeillaan ciab:t‰
	lea	_ciab,a3
	moveq	#0,d6
	lea	k_cianame(pc),a1
	move.b	#'b',3(a1)
	moveq	#0,d0
	move.l	4.w,a6
	lob	OpenResource
	move.l	d0,k_ciabase(a5)
	beq.b	k_err
	move.l	d0,a6

	lea	intserver(pc),a1
	move.l	d6,d0			* timer a
	lob	AddICRVector
	tst.l	d0
	beq.b	k_gottimer		* Saatiinko?

	lea	intserver(pc),a1
	moveq	#1,d6			* timer b
	move.l	d6,d0
	lob	AddICRVector
	tst.l	d0
	beq.b	k_gottimer

k_err	moveq	#-1,d0			* ERROR! Ei saatu varattua timeri‰.
	rts

k_gottimer
	move.b	d6,k_whichtimer(a5)
	move.l	a3,k_cia(a5)

	lea	ciatalo(a3),a2
	tst.b	d6
	beq.b	.timera
	lea	ciatblo(a3),a2
.timera
	move.b	k_timerlo(a5),(a2)
	move.b	k_timerhi(a5),$100(a2)

 ifne fast
	bsr.b	k_fastinit
 endc

	lea	ciacra(a3),a2
	tst.b	d6
	beq.b	.tima
	lea	ciacrb(a3),a2
.tima
	move.b	#%00010001,(a2)		* Continuous, start


k_eiks	
	rts


	

k_timerval				* Tutkii ajastimen
	move.l	#1773447,d0		* Pal, NTSC=1789773
	move.l	4.w,a0
	cmp.b	#50,531(a0)		* PowerSupplyFrequency
	beq.b	k_waspal
;	move.l	#1789773,d0		* NTSC
	move	#$4f4d,d0
k_waspal
	move.l	d0,k_timervalue(a5)
	divu	#125,d0
	move	d0,k_timerhi(a5)
	rts


 ifne fast
k_fastinit
	tst.b	k_fast(a5)
	bne.b	.f
	rts

.f	pushm	all
	bsr.w	k_clear

	lea	$dff000,a3
	move.l	#$07800780,$9a(a3)

	moveq	#128/2,d0
	move	d0,$a4(a3)	* len
	move	d0,$b4(a3)
	move	d0,$c4(a3)
	move	d0,$d4(a3)
	
	move.l	4.w,a6
	moveq	#INTB_AUD0,d0
	lea	audi0(pc),a1
	move.l	a5,IS_DATA(a1)
	pea	audi0r(pc)
	move.l	(sp)+,IS_CODE(a1)
	lob	SetIntVector
	move.l	d0,k_oldis1(a5)

	moveq	#INTB_AUD1,d0
	lea	audi1(pc),a1
	move.l	a5,IS_DATA(a1)
	pea	audi1r(pc)
	move.l	(sp)+,IS_CODE(a1)
	lob	SetIntVector
	move.l	d0,k_oldis2(a5)

	moveq	#INTB_AUD2,d0
	lea	audi2(pc),a1
	move.l	a5,IS_DATA(a1)
	pea	audi2r(pc)
	move.l	(sp)+,IS_CODE(a1)
	lob	SetIntVector
	move.l	d0,k_oldis3(a5)

	moveq	#INTB_AUD3,d0
	lea	audi3(pc),a1
	move.l	a5,IS_DATA(a1)
	pea	audi3r(pc)
	move.l	(sp)+,IS_CODE(a1)
	lob	SetIntVector
	move.l	d0,k_oldis4(a5)

	popm	all
	rts
 endc
 

* d1 = rasterlines to wait
waitti
	pushm	d0/d1
.d	move.b	6(a6),d0
.k	cmp.b	6(a6),d0
	beq.b	.k
	dbf	d1,.d
	popm	d0/d1
	rts

;		pushm	d1/d6/d7/a1
;		lea.l	6+1(a6),a1
;		move.b	(a1),d7
;		and.b	#$f0,d7
;.loop1		move.b	(a1),d6
;		and.b	#$f0,d6
;		cmp.b	d7,d6
;		beq.s	.loop1
;.loop2		move.b	(a1),d6
;		and.b	#$f0,d6
;		cmp.b	d7,d6
;		bne.s	.loop2
;		dbf	d1,.loop1
;		popm	d1/d6/d7/a1
;		rts

;	pushm	d1/a0
;	lea.l	$bfe001,a0
;.e 	rept	23
;	tst.b	(a0)
;	endr
;	dbf	d1,.e
;	popm	d1/a0
;	rts


dummyserver
	dc.l	0,0
	dc.b	2,0
	dc.l	0
	dc.l	0
	dc.l	0

softint
	dc.l	0,0
	dc.b	2,0
	dc.l	0
	dc.l	0
	dc.l	0

intserver
	dc.l	0,0
	dc.b	2,0
	dc.l	0
	dc.l	0
	dc.l	0

dummy
	moveq	#0,d0
	rts


 ifne fast


audi0	dc.l	0,0
	dc.b	2,100
	dc.l	0
	dc.l	0
	dc.l	0
audi1	dc.l	0,0
	dc.b	2,100
	dc.l	0
	dc.l	0
	dc.l	0
audi2	dc.l	0,0
	dc.b	2,100
	dc.l	0
	dc.l	0
	dc.l	0
audi3	dc.l	0,0
	dc.b	2,100
	dc.l	0
	dc.l	0
	dc.l	0


* a1 = is_data = k_base
* a0 = $dff000

audi0r	
	pushm	a2/a3
	lea	k_chan1temp(a1),a1
	lea	$a0(a0),a0
	bsr.b	dof
	popm	a2/a3
	move	#INTF_AUD0,$9c-$a0(a0)
	moveq	#0,d0
	rts

audi1r	
	pushm	a2/a3
	lea	k_chan2temp(a1),a1
	lea	$b0(a0),a0
	bsr.b	dof
	popm	a2/a3
	move	#INTF_AUD1,$9c-$b0(a0)
	moveq	#0,d0
	rts
audi2r	
	pushm	a2/a3
	lea	k_chan3temp(a1),a1
	lea	$c0(a0),a0
	bsr.b	dof
	popm	a2/a3
	move	#INTF_AUD2,$9c-$c0(a0)
	moveq	#0,d0
	rts
audi3r	
	pushm	a2/a3
	lea	k_chan4temp(a1),a1
	lea	$d0(a0),a0
	bsr.b	dof
	popm	a2/a3
	move	#INTF_AUD3,$9c-$d0(a0)
	moveq	#0,d0
	rts



*** Kopioidaan chip-puskuriin

dof

	move.l	n_buffer(a1),a2
	not.b	n_flag(a1)
	beq.b	.oer
	lea	128(a2),a2
.oer
	move.l	a2,(a0)
	
copys
	move.l	n_datapointer(a1),a3
	move	n_datalength(a1),d0

	cmp	#128/2,d0
	bhi.b	.big
	cmp	#1,d0
	bhi.b	.med
	cmp	#1,n_datarelength(a1)
	bls.b	.small

.med
;	moveq	#128/2-1,d1
;.copy	move	(a3)+,(a2)+
;	subq	#1,d0
;	bne.b	.ok
;	move.l	n_datarepointer(a1),a3
;	move	n_datarelength(a1),d0
;.ok	dbf	d1,.copy
;
;.ex	move	d0,n_datalength(a1)
;	move.l	a3,n_datapointer(a1)
;	rts

	moveq	#128/2-1,d1
.copy	move	(a3)+,(a2)+
	subq	#1,d0
	dbeq	d1,.copy
	tst	d1
	bmi.b	.ex

	move.l	n_datarepointer(a1),a3
	move	n_datarelength(a1),d0
	dbf	d1,.copy

.ex	move	d0,n_datalength(a1)
	move.l	a3,n_datapointer(a1)
	rts


.big
   rept	32
	move.l	(a3)+,(a2)+
   endr
	sub	#128/2,d0
	bra.b	.ex


*** 2 byten loopit
.small
	moveq	#0,d1
	rept	32
	move.l	d1,(a2)+
	endr
	bra.w	.ex
	
 endc
 

**************
* Keskeytykset
***************

;k_killer4b
;	not.b	k_intid(a5)
;	beq.b	k_repe2
;	bsr.b	k_repe1
;	move.b	#%00011001,$bfdf00	* Timer B, one shot
;	rts

* Systeemi-keskeytykset

k_softkiller1
;	move	#$ff0,$dff180
	bsr.w	k_music
;	clr	$dff180
	moveq	#0,d0
	rts



* toimis muuten muttei CDTV:ss‰.

;k_killer3
;k_killer5
;	lob	Cause
;	moveq	#0,d0
;	rts


k_killer3
k_killer5
	push	a6			* a1=is_Data=softint
;	move.l	4.w,a6
	move.l	exeksi(pc),a6
	lob	Cause
	pop	a6
	moveq	#0,d0
	rts

exeksi	dc.l	0

k_repe1					* Asettaa DMA:t p‰‰lle
	move	k_dma(a5),d0
	or	#$8000,d0
	move	d0,$dff096
	rts

k_repe2					* Asettaa repeatit
	lea	$dff0a0,a0
 ifne CHM
	move.b	k_chmask(a5),d0
	ror.b	#1,d0
	bpl.b	k_noch1
	move.l	k_chan1temp+n_loopstart(a5),(a0)
	move	k_chan1temp+n_replen(a5),$a4-$a0(a0)
k_noch1	ror.b	#1,d0
	bpl.b	k_noch2
	move.l	k_chan2temp+n_loopstart(a5),$b0-$a0(a0)
	move	k_chan2temp+n_replen(a5),$b4-$a0(a0)
k_noch2	ror.b	#1,d0
	bpl.b	k_noch3
	move.l	k_chan3temp+n_loopstart(a5),$c0-$a0(a0)
	move	k_chan3temp+n_replen(a5),$c4-$a0(a0)
k_noch3	ror.b	#1,d0
	bpl.b	k_noch4
	move.l	k_chan4temp+n_loopstart(a5),$d0-$a0(a0)
	move	k_chan4temp+n_replen(a5),$d4-$a0(a0)
k_noch4
	rts
 else
	move.l	k_chan1temp+n_loopstart(a5),(a0)+
	move	k_chan1temp+n_replen(a5),(a0)
	move.l	k_chan2temp+n_loopstart(a5),$b0-$a0-4(a0)
	move	k_chan2temp+n_replen(a5),$b4-$a0-4(a0)
	move.l	k_chan3temp+n_loopstart(a5),$c0-$a0-4(a0)
	move	k_chan3temp+n_replen(a5),$c4-$a0-4(a0)
	move.l	k_chan4temp+n_loopstart(a5),$d0-$a0-4(a0)
	move	k_chan4temp+n_replen(a5),$d4-$a0-4(a0)
	rts

 endc

************************
*        Muut
************************

k_end	movem.l	d1/a0/a1/a3/a5/a6,-(sp) 	* Soiton lopetus
	move.l	k_baseaddr(pc),a5


	bsr.b	k_emode3
	bsr.w	k_clear 

 ifne fast
	tst.b	k_fast(a5)
	beq.b	.n

	move.l	#$07800780,$dff09a

	move.l	4.w,a6
	moveq	#INTB_AUD0,d0
	move.l	k_oldis1(a5),a1
	lob	SetIntVector
	moveq	#INTB_AUD1,d0
	move.l	k_oldis2(a5),a1
	lob	SetIntVector
	moveq	#INTB_AUD2,d0
	move.l	k_oldis3(a5),a1
	lob	SetIntVector
	moveq	#INTB_AUD3,d0
	move.l	k_oldis4(a5),a1
	lob	SetIntVector

	move.l	n_buffer+k_chan1temp(a5),d0
	beq.b	.n
	move.l	d0,a1
	move.l	#1024,d0
	lob	FreeMem
.n	
 endc

	tst.b	k_filterstore(a5)
	bsr.w	k_fili

;	move	k_songpos(a5),d0
	movem.l	(sp)+,d1/a0/a1/a3/a5/a6
	rts


k_emode3
	move.l	k_cia(a5),a3
	moveq	#0,d0
	move.b	k_whichtimer(a5),d0	
	bmi.b	.xxx
	bne.b	.b
	move.b	#%00000000,ciacra(a3)
	bra.b	.a
.b	move.b	#%00000000,ciacrb(a3)
.a
	lea	intserver(pc),a1
	move.l	k_ciabase(a5),a6
	lob	RemICRVector

.xxx	rts


k_clear	movem.l	d0/a6,-(sp)		* ƒ‰ni DMA pois p‰‰lt‰
	lea	$dff096,a6
	move	#$f,(a6)
	moveq	#0,d0
	move	d0,$a8-$96(a6)
	move	d0,$b8-$96(a6)
	move	d0,$c8-$96(a6)
	move	d0,$d8-$96(a6)
	movem.l	(sp)+,d0/a6
	rts

k_setmaster				* Asettaa p‰‰volumen
	move.l	a0,-(sp)
	move.l	k_baseaddr(pc),a0
	move.b	d0,k_mastervolume+1(a0)
	move.l	(sp)+,a0
	rts

 ifne CHM
k_channelmask
	move.l	a0,-(sp)
	move.l	k_baseaddr(pc),a0
	move.b	d0,k_chmask(a0)
	move.l	(sp)+,a0
	rts
 endc

k_playstop
	move.l	a0,-(sp)
	move.l	k_baseaddr(pc),a0
	move.b	d0,k_playmusic(a0)
	move.l	(sp)+,a0
	rts

***********************
*        Music         
***********************

k_music
	movem.l	d0-a6,-(sp)
	move.l	k_baseaddr(pc),a5
	lea	$dff000,a6

	tst.b	k_playmusic(a5)
	bne.w	k_puis2

;	move.b	k_speed(a5),d1
	move	(a5),d1
	addq.b	#1,(a5)
	move.b	(a5),d0
	cmp.b	d1,d0
	blo.s	k_nonewnote
	clr.b	(a5)

	subq.b	#1,d1
	bne.b	k_noone
	bsr.b	k_read			* Nopeus 1
k_noone

	tst.b	k_pattdeltime2(a5)
	beq.w	k_getnewnote		* patterndelay p‰‰ll‰
	pea	k_dskip(pc)
	bra.b	k_nonewallchannels

k_nonewnote
	addq.b	#1,d0
	cmp.b	d1,d0
	bne.b	k_hubba
					* otetaan ennalta sampleinfot
	bsr.b	k_nonewallchannels

	tst.b	k_pattdeltime2(a5)	* ei oteta jos patterndelay p‰‰ll‰
	bne.w	k_puis

	pea	k_puis(pc)

k_read

	move.l	k_songdataptr(a5),a3
	moveq	#0,d0
	move	k_songpos(a5),d0
	move.b	(a3,d0),d0
	lsl	#6,d0
	add	k_patternpos(a5),d0
	lsl.l	#4,d0
	add.l	d0,a3
	lea	1084-952(a3),a3

	lea	k_chan1temp(a5),a4
	moveq	#4-1,d6	
	moveq	#n_sizeof,d7
	moveq	#0,d0
k_checknote
	move.l	a4,a2
	move.l	(a3)+,(a2)+

	move.b	-1(a2),d0		* samplenum
	beq.b	k_nosamp
	move.l	k_mt-4(a5,d0),a1	* sampledata

* start 4, length 2, volume 2, periodaddr 4, loopstart 4, replen 2, wavestart 4
	move	(a1)+,(a2)+
	movem.l	(a1),d1-d5
	movem.l	d1-d5,(a2)


k_nosamp
 	add.l	d7,a4
	dbf	d6,k_checknote

	rts

k_hubba	
	pea	k_nonewposyet(pc)

k_nonewallchannels			* Suoritetaan pelk‰t efektit
	lea	$a0(a6),a3
	lea	k_chan1temp(a5),a4
 ifne CHM
	move.b	k_chmask(a5),d3
 else
	moveq	#$10,d3
 endc
	moveq	#n_sizeof,d4
	moveq	#4-1,d5
k_checkefx
 ifne CHM
	ror.b	#1,d3
	bpl.b	k_hup
 endc
	bsr.w	k_pernop

	move.b	n_funkspeed(a4),d0
	beq.b	k_nofunk
	bsr.w	k_funkit2
k_nofunk
	tst	(a4)
	beq.b	k_hup

	moveq	#0,d0
	move.b	(a4),d0
	jsr	k_jump1(pc,d0)
k_hup

 ifne CHM
	lea	$10(a3),a3
 else
	add	d3,a3
 endc
	add.l	d4,a4
	dbf	d5,k_checkefx
	rts


k_jump1	bra.w	k_arpeggio		* 0
	bra.w	k_portaup		* 1
	bra.w	k_portadown		* 2
	bra.w	k_toneportamento	* 3	
	bra.w	k_vibrato2		* 4
	bra.w	k_toneplusvolslide	* 5
	bra.w	k_vibratoplusvolslide	* 6
	bra.w	k_tremolo2		* 7
	rts				* 8
	rts
	rts				* 9
	rts
	bra.w	k_volumeslide		* a
	rts				* b
	rts
	rts				* c
	rts
	rts				* d
	rts
	bra.w	k_e_commands2		* e
	rts				* f

k_getnewnote				* Soitetaan uusi nuotti
	clr	k_dma(a5)
	lea	$a0(a6),a3
	lea	k_chan1temp(a5),a4
 ifne CHM
	move.b	k_chmask(a5),d3
 else
	moveq	#$10,d3
 endc
	moveq	#n_sizeof,d4
	moveq	#4-1,d5

k_playvoice
 ifne CHM
	ror.b	#1,d3
	bpl.w	k_tadaa
 endc

	tst.l	(a4)
	bne.b	k_slurt
	move	n_period(a4),6(a3)
	bra.b	k_setregs
k_slurt
	tst.b	d_samplenum(a4)
	beq.b	k_setregs
	move	n_volume(a4),n_tempvol(a4)


k_setregs
	moveq	#0,d0
	move.b	(a4),d0

	
	tst.b	d_period(a4)		* onko perioidi?
	beq.w	k_checkmoreefx
	jmp	k_jum(pc,d0)

k_jum	bra.b	k_setperiod		* 0
	nop
	bra.b	k_setperiod		* 1
	nop
	bra.b	k_setperiod		* 2
	nop
	bra.w	k_settoneporta		* 3
	bra.b	k_setperiod		* 4
	nop
	bra.w	k_settoneporta		* 5
	bra.b	k_setperiod		* 6
	nop
	bra.b	k_setperiod		* 7
	nop
	bra.b	k_setperiod		* 8
	nop
	bra.b	k_sofs			* 9 sampleoffset
	nop
	bra.b	k_setperiod		* a
	nop
	bra.b	k_setperiod		* b
	nop
	bra.b	k_setperiod		* c
	nop
	bra.b	k_setperiod		* d
	nop
	bra.w	k_eekom			* e notedelay tai finetune
	bra.b	k_setperiod		* f
	nop

k_sofs	
	bsr.w	k_sampleoffset
	; prevent sample offset being run in the below
	; part again, which will likely set the sample length
	; to 1 falsely. The length is set to Paula before this
	; so playback will be fine, scopes just get confused.
	moveq	#0,d0
	
k_setperiod
	move.l	n_periodaddr(a4),d1
	bne.b	.o
	lea	k_pt1(pc),a1	
	bra.b	.i
.o	move.l	d1,a1
.i


k_returnfine
	moveq	#0,d1
 	move.b	d_period(a4),d1
	subq	#1,d1
	move	(a1,d1),n_period(a4)	* Uusi perioidi
	move	d1,n_period2(a4)	* Arpeggiota varten

	clr	n_vibratopos(a4)	* clr vibpos.b & trepos.b

	move	n_dmabit(a4),d1		* DMA:t pois
	move	d1,$96(a6)
 	or	d1,k_dma(a5)
	or.b	d1,k_usertrig(a5)
;	move	n_length(a4),4(a3)
;	move.l	n_start(a4),(a3)
	move	n_period(a4),6(a3)

	tst.l	n_start(a4)		* nollasample?
	beq.b	.noa
	tst	n_length(a4)
	bne.b	.joos
.noa	move.l	k_null(a5),n_start(a4)
	move	#1,n_length(a4)
	move.l	k_null(a5),n_loopstart(a4)
	move	#1,n_replen(a4)

.joos


 ifne fast
	tst.b	k_fast(a5)
	bne.b	.fast
	move	n_length(a4),4(a3)
	move.l	n_start(a4),(a3)
	bra.b	.chip
.fast
	move	d1,$96(a6)
	move	n_period(a4),6(a3)

	bsr.b	k_setfastsample
.chip
 else
	move	n_length(a4),4(a3)
	move.l	n_start(a4),(a3)
 endc  
	

k_checkmoreefx
	jsr	k_jump2(pc,d0)		* komennot

k_tadaa	
 ifne CHM
	lea	$10(a3),a3
 else
	add	d3,a3
 endc
	add.l	d4,a4
	dbf	d5,k_playvoice
	bra.w	k_setdma

k_eekom	move	(a4),d1			* ED0
	and	#$f0,d1
	cmp.b	#$d0,d1
	beq.b	k_tadaa
;	bne.b	k_ek2
;	bsr.w	k_notedelay
;	bra.b	k_tadaa

k_ek2	cmp.b	#$50,d1			* E50
	bne.w	k_setperiod
	bsr.w	k_setfinetune
	bra.w	k_returnfine

k_jump2
	bra.b	k_pernop		* 0
	nop
	bra.b	k_pernop		* 1
	nop
	bra.b	k_pernop		* 2
	nop
	bra.b	k_pernop		* 3
	nop
	bra.w	k_vibrato		* 4
	bra.b	k_pernop		* 5
	nop
	bra.b	k_pernop		* 6
	nop
	bra.w	k_tremolo		* 7
	bra.b	k_pernop		* 8
	nop
;	bra.b	k_pernop		* 9
;	nop
	bra.w	k_sampleoffset		* 9
	bra.b	k_pernop		* a
	nop
	bra.w	k_positionjump		* b
	bra.w	k_volumechange		* c
	bra.w	k_patternbreak		* d
	bra.w	k_e_commands		* e
	bra.w	k_setspeed		* f


* Asetetaan normaaliperioidi
k_pernop
	move	n_period(a4),6(a3)
 	rts

 ifne fast
k_setfastsample
	lsl	#7,d1
	move	d1,$9a(a6)
	move	d1,$9c(a6)

	move.l	n_start(a4),n_datapointer(a4)
	move	n_length(a4),n_datalength(a4)
	move	n_replen(a4),n_datarelength(a4)
	move.l	n_loopstart(a4),n_datarepointer(a4)


	pushm	d0/a2/a3
	move.l	a4,a1
	move.l	a3,a0
	move.l	n_buffer(a1),a2
	move.l	a2,(a3)
	clr.b	n_flag(a1)
	bsr.w	copys
	popm	d0/a2/a3
	rts
 endc

k_setdma
	st	k_trig(a5)		* Lippu: asetetaan repeatit

k_dskip					* Muut hommat
	addq	#1,k_patternpos(a5)
	move.b	k_pattdeltime(a5),d0
	beq.s	k_dskc
	clr.b	k_pattdeltime(a5)
	move.b	d0,k_pattdeltime2(a5)
k_dskc	tst.b	k_pattdeltime2(a5)
	beq.s	k_dska
	subq.b	#1,k_pattdeltime2(a5)
	beq.s	k_dska
	subq	#1,k_patternpos(a5)
k_dska
	tst.b	k_pbreakflag(a5)
	beq.s	k_nnpysk
	clr.b	k_pbreakflag(a5)
	move	k_pbreakpos(a5),d0
	clr	k_pbreakpos(a5)
	move	d0,k_patternpos(a5)
k_nnpysk
	cmp	#64,k_patternpos(a5)
	blo.s	k_nonewposyet
k_nextposition	
	move	k_pbreakpos(a5),k_patternpos(a5)
	clr	k_pbreakpos(a5)
	clr.b	k_posjumpflag(a5)
	addq	#1,k_songpos(a5)
	move	k_songpos(a5),d0
	move.l	k_songdataptr(a5),a0
	cmp.b	-2(a0),d0
	blo.s	k_nonewposyet
	clr	k_songpos(a5)
	addq.b	#1,k_songover(a5)	* Kappale loppui!
****
;	move.b	#6,k_speed(a5)		* nopeus: 6
****
	move.b	#125,k_tempo(a5)	* tempo: 125
	tst.b	k_usetempo(a5)
	bne.b	k_nonewposyet		* no tempo!
	move.b	k_tempo(a5),d0
	bsr.w	k_settempo2


k_nonewposyet	
	tst.b	k_posjumpflag(a5)
	bne.s	k_nextposition
k_puis	


					* Mastervolume-hommeli
	move	n_tempvol+k_chan1temp(a5),d1	
	move	n_tempvol+k_chan2temp(a5),d2
	move	n_tempvol+k_chan3temp(a5),d3
	move	n_tempvol+k_chan4temp(a5),d4
	move	k_mastervolume(a5),d0
	cmp	#$40,d0
	bhs.b	k_noneed

	mulu	d0,d1
	mulu	d0,d2
	mulu	d0,d3
	mulu	d0,d4
	lsr	#6,d1
	lsr	#6,d2
	lsr	#6,d3
	lsr	#6,d4

k_noneed

 ifne CHM
	move.b	k_chmask(a5),d0
	ror.b	#1,d0
	bpl.b	k_nov1
	move	d1,$a8(a6)
k_nov1	ror.b	#1,d0
	bpl.b	k_nov2
	move	d2,$b8(a6)
k_nov2	ror.b	#1,d0
	bpl.b	k_nov3
	move	d3,$c8(a6)
k_nov3	ror.b	#1,d0
	bpl.b	k_nov4
	move	d4,$d8(a6)
k_nov4	
 else
	move	d1,$a8(a6)
	move	d2,$b8(a6)
	move	d3,$c8(a6)
	move	d4,$d8(a6)
 endc	

 ifne fast
	tst.b	k_fast(a5)
	beq.b	k_cip
	tst.b	k_trig(a5)
	beq.b	k_puis2
	clr.b	k_trig(a5)

	move.l	n_loopstart+k_chan1temp(a5),n_datarepointer+k_chan1temp(a5)
	move	n_replen+k_chan1temp(a5),n_datarelength+k_chan1temp(a5)
	move.l	n_loopstart+k_chan2temp(a5),n_datarepointer+k_chan2temp(a5)
	move	n_replen+k_chan2temp(a5),n_datarelength+k_chan2temp(a5)
	move.l	n_loopstart+k_chan3temp(a5),n_datarepointer+k_chan3temp(a5)
	move	n_replen+k_chan3temp(a5),n_datarelength+k_chan3temp(a5)
	move.l	n_loopstart+k_chan4temp(a5),n_datarepointer+k_chan4temp(a5)
	move	n_replen+k_chan4temp(a5),n_datarelength+k_chan4temp(a5)

	moveq	#20-1,d1		* hpos
	bsr.w	waitti

	move	k_dma(a5),d0
	move	d0,d2
	or	#$8000,d0
	lsl	#7,d2
	or	#$8000,d2
	move	d0,$96(a6)

	moveq	#7-1,d1			* Viiveet
	bsr.w	waitti

	move	d2,$9a(a6)
	;move	d1,$9c(a6)


	bra.b	k_puis2

k_cip
 endc
 
	tst.b	k_trig(a5)
	beq.b	k_puis2
	clr.b	k_trig(a5)

 ifne dmawait
	moveq	#12-1,d1			* Viiveet
 else
  	moveq	#6-1,d1
 endc
	bsr.w	waitti
	bsr.w	k_repe1

 ifne dmawait
	moveq	#3-1,d1
 else
	moveq	#2-1,d1
 endc
	bsr.w	waitti
	bsr.w	k_repe2

k_puis2	movem.l	(sp)+,d0-a6
	rts


	
******************
* Commands
******************

k_sampleoffset				* 900
	moveq	#0,d1
	move.b	1(a4),d1
	beq.s	k_sononew
	lsl	#7,d1
	move	d1,n_sampleoffset(a4)
k_sononew
	move	n_sampleoffset(a4),d1
	cmp     n_length(a4),d1
	; Using signed comparison is a bug in PT regarding
	; 128kB samples. Preserve this bug.
	;bhs.s   k_sofskip
	bge.b	k_sofskip
	sub	d1,n_length(a4)
	add.l	d1,d1
	add.l	d1,n_start(a4)
	rts
k_sofskip
	move	#1,n_length(a4)
	rts



k_arplist
 dc.b 0,-1,1,0,-1,1,0,-1,1,0,-1,1,0,-1,1,0,-1,1,0,-1,1,0,-1,1,0,-1,1,0,-1,1,0
 dc.b -1

k_arpeggio				
	move.l	n_periodaddr(a4),d0
	bne.b	.jep
	rts
.jep	move.l	d0,a0

	moveq	#$1f,d0
	and.b	(a5),d0
	move.b	k_arplist(pc,d0),d0
	beq.w	k_pernop
	bmi.b	k_arpeggio1
	moveq	#$f,d0
	and	(a4),d0
	bra.s	k_arpeggio3

k_arpeggio1
	move	(a4),d0
	lsr	#4,d0

k_arpeggio3
	add	d0,d0
	add	n_period2(a4),d0
;	move.l	n_periodaddr(a4),a0
	move	(a0,d0),6(a3)
	rts



k_settoneporta				* 300
	move.l	n_periodaddr(a4),d0
	beq.w	k_tadaa			* SUURI BUGI!

	move.l	d0,a1
	moveq	#0,d0
	move.b	d_period(a4),d0
	subq	#1,d0
	move	d0,n_period2(a4)	* Arpeggiota varten
	move	(a1,d0),d2
	move	n_period(a4),d0
	clr.b	n_toneportdirec(a4)
	cmp	d0,d2
	beq.b	k_er
	slt	n_toneportdirec(a4)	
k_er	move	d2,n_wantedperiod(a4)
	bra.w	k_tadaa


k_fineportaup				* E10
	tst.b	(a5)
	bne.b	k_fer
	moveq	#$f,d0
	and	(a4),d0
	bne.b	k_pucon
	rts

k_fineportadown				* E20
	tst.b	(a5)
	bne.b	k_fer
	moveq	#$f,d0
	and	(a4),d0
	bne.b	k_pucon2
k_fer	rts


k_portaup
	moveq	#0,d0
	move.b	1(a4),d0
k_pucon
	move	n_period(a4),d7
	sub	d0,d7
	cmp	#113,d7
	bge.s	k_portaskip
	moveq	#113,d7
k_portaskip
	move	d7,n_period(a4)
	move	d7,6(a3)
k_ret	rts
 
k_portadown
	moveq	#0,d0
	move.b	1(a4),d0
k_pucon2
	move	n_period(a4),d7
	add	d0,d7
	cmp	#856,d7
	bls.s	k_portaskip
	move	#856,d7
	bra.b	k_portaskip


k_toneportamento			* 300
	move.b	1(a4),d0
	beq.s	k_toneportnochange
	move.b	d0,n_toneportspeed+1(a4)
	clr.b	1(a4)			* Clear tp cmd
k_toneportnochange
	tst	n_wantedperiod(a4)
	beq.b	k_ret
	move	n_toneportspeed(a4),d0
	move	n_period(a4),d1
	move	n_wantedperiod(a4),d2

	tst.b	n_toneportdirec(a4)
	bne.s	k_toneportaup

k_toneportadown
	add	d0,d1
	cmp	d1,d2
	bgt.s	k_toneportasetper
	bra.s	k_raaps

k_toneportaup
	sub	d0,d1
	cmp	d1,d2  	
	blt.s	k_toneportasetper

k_raaps	clr	n_wantedperiod(a4)
	move	d2,d1

k_toneportasetper
	move	d1,n_period(a4)

	tst.b	n_glisscontrol(a4)	* E31 glissando (sika hidas)
	beq.b	k_glissskip
	move.l	n_periodaddr(a4),a0
	lea	72(a0),a1
k_glissloop
	cmp	(a0)+,d1
	bhs.s	k_glissfound
	cmp.l	a1,a0
	blo.b	k_glissloop
	lea	-2(a1),a0
k_glissfound
	move	-2(a0),d1
k_glissskip
	move	d1,6(a3) 
	rts

k_vibrato				* 400
	move.b	1(a4),d0
	beq.s	k_vz
	move.b	n_vibratocmd(a4),d2
	moveq	#$f,d1
	and	d0,d1
	beq.b	k_vib1
	and	#$f0,d2
	or.b	d1,d2
k_vib1
	move	d0,d1
	and	#$f0,d1
	beq.b	k_vib2
	and	#$0f,d2
	or.b	d1,d2
k_vib2
	move.b	d2,n_vibratocmd(a4)
	clr.b	1(a4)			* Clear vibcmd
k_vz	rts

k_vibrato2
	move.b	n_vibratopos(a4),d0
	lsr	#2,d0
	and	#$1f,d0
	moveq	#$f,d2
	and.b	n_vibratocmd(a4),d2
	lsl	#5,d2
	add	d0,d2
	moveq	#0,d1
	move.b	k_vibtab(pc,d2),d1

	move	n_period(a4),d0
	tst.b	n_vibratopos(a4)
	bmi.s	k_vibratoneg
	add	d1,d0
	bra.s	k_vibrato3
k_vibratoneg
	sub	d1,d0
k_vibrato3
	move	d0,6(a3)
	move.b	n_vibratocmd(a4),d0
	lsr.b	#2,d0
	and	#$3c,d0
	add.b	d0,n_vibratopos(a4)
	rts

k_vibtab
 dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 dc.b 0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,2,2,2,3
 dc.b 3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,1,1,1,0,0,0,0,1,1,2,2,3,3,4,4,4,5,5,5,5
 dc.b 5,5,5,5,5,5,5,4,4,4,3,3,2,2,1,1,0,0,0,1,2,3,3,4,5,5,6,6,7,7,7,7,7,7,7,7,7
 dc.b 7,7,6,6,5,5,4,3,3,2,1,0,0,0,1,2,3,4,5,6,7,7,8,8,9,9,9,9,9,9,9,9,9,8,8,7,7
 dc.b 6,5,4,3,2,1,0,0,1,2,3,4,5,6,7,8,9,9,10,11,11,11,11,11,11,11,11,11,10,9,9
 dc.b 8,7,6,5,4,3,2,1,0,1,2,4,5,6,7,8,9,10,11,12,12,13,13,13,13,13,13,13,12,12
 dc.b 11,10,9,8,7,6,5,4,2,1,0,1,3,4,6,7,8,10,11,12,13,14,14,15,15,15,15,15,15
 dc.b 15,14,14,13,12,11,10,8,7,6,4,3,1,0,1,3,5,6,8,9,11,12,13,14,15,16,17,17,17
 dc.b 17,17,17,17,16,15,14,13,12,11,9,8,6,5,3,1,0,1,3,5,7,9,11,12,14,15,16,17
 dc.b 18,19,19,19,19,19,19,19,18,17,16,15,14,12,11,9,7,5,3,1,0,2,4,6,8,10,12,13
 dc.b 15,16,18,19,20,20,21,21,21,21,21,20,20,19,18,16,15,13,12,10,8,6,4,2,0,2,4
 dc.b 6,9,11,13,15,16,18,19,21,22,22,23,23,23,23,23,22,22,21,19,18,16,15,13,11
 dc.b 9,6,4,2,0,2,4,7,9,12,14,16,18,20,21,22,23,24,25,25,25,25,25,24,23,22,21
 dc.b 20,18,16,14,12,9,7,4,2,0,2,5,8,10,13,15,17,19,21,23,24,25,26,27,27,27,27
 dc.b 27,26,25,24,23,21,19,17,15,13,10,8,5,2,0,2,5,8,11,14,16,18,21,23,24,26,27
 dc.b 28,29,29,29,29,29,28,27,26,24,23,21,18,16,14,11,8,5,2

k_tremolo				* 700
	move.b	1(a4),d0
	beq.s	k_tz
	move.b	n_tremolocmd(a4),d2
	moveq	#$f,d1
	and	d0,d1
	beq.b	k_tre1
	and	#$f0,d2
	or.b	d1,d2
k_tre1
	move	d0,d1
	and	#$f0,d1
	beq.b	k_tre2
	and	#$0f,d2
	or.b	d1,d2
k_tre2
	move.b	d2,n_tremolocmd(a4)
	clr.b	1(a4)			* Clear trecmd
k_tz	rts

k_tremolo2
	move.b	n_tremolopos(a4),d0
	lsr	#2,d0
	and	#$1f,d0
	moveq	#$f,d2
	and.b	n_tremolocmd(a4),d2
	lsl	#5,d2
	add	d0,d2
	moveq	#0,d1
	lea	k_vibtab(pc),a0
	move.b	(a0,d2),d1

	move	n_volume(a4),d0
	tst.b	n_tremolopos(a4)
	bmi.s	k_tremoloneg
	add	d1,d0
	bra.s	k_tremolo3
k_tremoloneg
	sub	d1,d0
k_tremolo3
	bpl.s	k_tremoloskip
	moveq	#0,d0
	bra.b	k_tremolook
k_tremoloskip
	cmp	#$40,d0
	bls.s	k_tremolook
	move	#$40,d0
k_tremolook
	move	d0,n_tempvol(a4)
	move.b	n_tremolocmd(a4),d0
	lsr.b	#2,d0
	and	#$3c,d0
	add.b	d0,n_tremolopos(a4)
	rts


k_toneplusvolslide			* 500
	bsr.w	k_toneportnochange
	bra.b	k_volumeslide

k_vibratoplusvolslide			* 600
	bsr.w	k_vibrato2

k_volumeslide				* A00
	move	(a4),d0
	and	#$0f0,d0
	bne.b	k_volslideup
	moveq	#$f,d0
	and	(a4),d0

k_volslidedown
	move	n_volume(a4),d7
	sub.b	d0,d7
	bpl.s	k_vsdskip
	moveq	#0,d7
k_vsdskip
	move	d7,n_volume(a4)
 	move	d7,n_tempvol(a4)
	rts

k_volslideup
	lsr	#4,d0
k_vup
	move	n_volume(a4),d7
	add.b	d0,d7
	cmp.b	#$40,d7
	bls.s	k_vsuskip
	moveq	#$40,d7
k_vsuskip
	move.b	d7,n_volume+1(a4)
	move.b	d7,n_tempvol+1(a4)
k_r7	rts


k_volumefineup				* EA0
	tst.b	(a5)
	bne.b	k_r7
	moveq	#$f,d0
	and	(a4),d0
	bra.b	k_vup

k_volumefinedown			* EB0
	tst.b	(a5)
	bne.b	k_r7
	moveq	#$f,d0
	and	(a4),d0
	bra.b	k_volslidedown


k_volumechange				* C00
	move.b	1(a4),d0
	cmp.b	#$40,d0
	bls.s	k_volumeok
	moveq	#$40,d0
k_volumeok
	move.b	d0,n_volume+1(a4)
	move.b	d0,n_tempvol+1(a4)
	rts

k_positionjump				* B00
	move	(a4),d0
	and	#$ff,d0
	cmp	k_songpos(a5),d0	* hyppy samaan positioniin?
	bne.b	.ook
	;moveq	#0,d0			* ei k‰y!
    * Jump to same position, allow if there is also
    * a patternbreak somewhere, otherwise
    * this is a stop which should be ignored.
    cmp.b   #$d*4,k_chan1temp(a5)	
    beq.b   .ook
    cmp.b   #$d*4,k_chan2temp(a5)	
    beq.b   .ook
    cmp.b   #$d*4,k_chan3temp(a5)	
    beq.b   .ook
    cmp.b   #$d*4,k_chan4temp(a5)	
    bne.b   k_pj3
.ook
    * See if the jump is in the last position
    move    k_songpos(a5),d2
	addq	#1,d2
	move.l	k_songdataptr(a5),a0
	cmp.b	-2(a0),d2
    bne     .notLast
    * It was, consider this the end
    addq.b  #1,k_songover(a5)
.notLast

	subq	#1,d0
	move	d0,k_songpos(a5)
	st 	k_posjumpflag(a5)
k_pj2	clr	k_pbreakpos(a5)
k_pj3
	rts

k_patternbreak				* D00
	st	k_posjumpflag(a5)
	move	(a4),d0
	cmp.b	#63,d0
	bhi.s	k_pj2
	move.b	d0,k_pbreakpos+1(a5)
	rts

k_setspeed				* F00
	move.b	1(a4),d0
	bne.b	k_nozero
	moveq	#$1f,d0			* Jos 0, pistet‰‰n hitain, eli $1F
	bra.b	k_notempo
k_nozero
	cmp.b	#$1f,d0
	bhi.b	k_settempo
k_notempo
	clr.b	(a5)
	move.b	d0,k_speed(a5)
	rts

k_settempo
	tst.b	k_usetempo(a5)		* Onko tempo sallittu?
	bne.b	k_notempo
k_settempo2
	move.b	d0,k_tempo(a5)
	and	#$ff,d0
	move.l	k_timervalue(a5),d1
	divu	d0,d1
	move	d1,k_timerhi(a5)

	move.l	k_cia(a5),a0
	lea	ciatalo(a0),a0
	tst.b	k_whichtimer(a5)
	beq.b	.timera
	lea	ciatblo-ciatalo(a0),a0
.timera

	move.b	d1,(a0)
	lsr	#8,d1
	move.b	d1,$100(a0)
	rts


k_e_commands2
k_e_commands
	move	(a4),d0
	and	#$f0,d0
k_e_co	lsr	#2,d0
	jmp	k_jump3(pc,d0)

k_jump3
	bra.w	k_filteronoff		* 0
	bra.w	k_fineportaup		* 1
	bra.w	k_fineportadown		* 2
	bra.w	k_setglisscontrol	* 3
	rts				* 4 k_setvibratocontrol
	rts
	bra.w	k_setfinetune		* 5
	bra.w	k_jumploop		* 6
	rts				* 7 k_settremolocontrol
	rts
	rts				* 8
	rts

;	bra.b	k_setretrig		* 9
;	rts
	bra.b	k_retrignote
	rts

	bra.w	k_volumefineup		* a
	bra.w	k_volumefinedown	* b

	bra.b	k_notecut		* c notecut
	rts

	bra.b	k_notedelay		* d notedelay
	rts

	bra.w	k_patterndelay		* e
	bra.w	k_funkit		* f

;k_e_commands2
;	move	(a4),d0
;	and	#$f0,d0
;	cmp.b	#$90,d0
;	bne.b	k_e_co


;k_retrignote
;	subq.b	#1,n_retrig(a4)
;	bne.b	k_r4

;	bsr.b	k_setretrig

;	move	n_dmabit(a4),d0
;	move	d0,$96(a6)		
;	or	d0,k_dma(a5)

;	move	n_length(a4),4(a3)

; ifne fast
;	tst.b	k_fast(a5)
;	bne.b	.fast
;	move.l	n_start(a4),(a3)
;	bra.b	.chip
;.fast	bsr.w	k_setfastsample
;.chip
; else
; 	move.l	n_start(a4),(a3)
; endc

;	st	k_trig(a5)
;	or.b	d0,k_usertrig(a5)
;k_r4	rts


;k_setretrig
;	moveq	#$f,d7			* E90
;	and	(a4),d7
;	move.b	d7,n_retrig(a4)
;	rts

k_retrignote
	moveq	#$f,d0
	and	(a4),d0
	beq.b	k_r4
	moveq	#0,d7
	move.b	(a5),d7
	bne.b	.skip
	tst.b	d_period(a4)
	bne.b	k_r4
.skip

;.loop	cmp.b	d0,d7
;	beq.b	.doit
;	blo.b	k_r4
;	sub.b	d0,d7
;	bmi.b	k_r4
;	bra.b	.loop
;.doit

	divu	d0,d7
	swap	d7
	tst	d7
	bne.b	k_r4

	move	n_dmabit(a4),d0		* DMA:t pois
	move	d0,$96(a6)
 	or	d0,k_dma(a5)
	st	k_trig(a5)
	or.b	d0,k_usertrig(a5)

 ifeq fast
	move	n_length(a4),4(a3)
	move.l	n_start(a4),(a3)
 endc


 ifne fast
	tst.b	k_fast(a5)
	bne.b	.fast
	move	n_length(a4),4(a3)
	move.l	n_start(a4),(a3)
	bra.b	.chip
.fast
	move	d0,d1
	bsr.w	k_setfastsample
.chip
 else
	move	n_length(a4),4(a3)
	move.l	n_start(a4),(a3)
 endc

k_r4	rts



k_notecut				* EC0
	moveq	#$f,d0
	and	(a4),d0
	cmp.b	(a5),d0
	bne.b	k_r5
	clr.b	n_volume+1(a4)
	clr	n_tempvol(a4)
k_r5	rts


k_notedelay				* ED0
	tst.b	d_period(a4)
	beq.b	k_r5

	moveq	#$f,d6
	and	(a4),d6

	cmp.b	(a5),d6	
	bne.b	k_r5

	move.l	n_periodaddr(a4),d1
	beq.b	k_r5



	move.l	d1,a1
	moveq	#0,d1
 	move.b	d_period(a4),d1
	move	-1(a1,d1),n_period(a4)	* Uusi perioidi
	move	d1,n_period2(a4)	* Arpeggiota varten
	move	n_period(a4),6(a3)



	move	n_dmabit(a4),d0		* DMA:t pois
	move	d0,$96(a6)
 	or	d0,k_dma(a5)
	st	k_trig(a5)
	or.b	d0,k_usertrig(a5)

 ifeq fast
	move	n_length(a4),4(a3)
	move.l	n_start(a4),(a3)
 endc

 ifne fast
	tst.b	k_fast(a5)
	bne.b	.fast
	move	n_length(a4),4(a3)
	move.l	n_start(a4),(a3)
	bra.b	.chip
.fast
	move	d0,d1
	bsr.w	k_setfastsample
.chip
 else
	move	n_length(a4),4(a3)
	move.l	n_start(a4),(a3)
 endc 

	clr	n_vibratopos(a4)
	rts

k_filteronoff				* E00
	moveq	#$f,d0
	and	(a4),d0
k_fili	bne.b	k_foff
	bclr	#1,$bfe001
	rts
k_foff	bset	#1,$bfe001
	rts

k_setglisscontrol			* E30
	moveq	#$f,d0
	and	(a4),d0
	move.b	d0,n_glisscontrol(a4)
	rts

;k_setvibratocontrol
;	moveq	#$f,d0
;	and	(a4),d0
;	and.b	#$f0,n_wavecontrol(a4)
;	or.b	d0,n_wavecontrol(a4)
;	rts

;k_settremolocontrol
;	move.b	1(a4),d0
;	lsl.b	#4,d0
;	and.b	#$0f,n_wavecontrol(a4)
;	or.b	d0,n_wavecontrol(a4)
;	rts

k_setfinetune				* E50
	moveq	#$f,d1
	and	(a4),d1
	add	d1,d1
	lea	k_pertab(pc,d1),a1
	add	(a1),a1
	move.l	a1,n_periodaddr(a4)
	rts

k_pertab
 dr k_pt1,k_pt2,k_pt3,k_pt4,k_pt5,k_pt6,k_pt7,k_pt8,k_pt9,k_pt10,k_pt11,k_pt12
 dr k_pt13,k_pt14,k_pt15,k_pt16

k_jumploop				* E60
	tst.b	(a5)
	bne.b	k_r3

	moveq	#$f,d0
	and	(a4),d0
	beq.s	k_setloop

	tst.b	n_loopcount(a4)
	beq.s	k_jumpcnt
	subq.b	#1,n_loopcount(a4)
	beq.b	k_r3
k_jmploop
	move	n_pattpos(a4),k_pbreakpos(a5)
	st	k_pbreakflag(a5)
k_r3	rts

k_jumpcnt
	move.b	d0,n_loopcount(a4)
	bra.s	k_jmploop
k_setloop
	move	k_patternpos(a5),n_pattpos(a4)
	rts

k_patterndelay				* EE8
	tst.b	(a5)
	bne.b	k_r6

	tst.b	k_pattdeltime2(a5)
	bne.b	k_r6

	moveq	#$f,d0
	and	(a4),d0
	addq.b	#1,d0
	move.b	d0,k_pattdeltime(a5)
k_r6	rts

k_funkit
	moveq	#$f,d0
	and	(a4),d0
	move.b	d0,n_funkspeed(a4)
	rts
k_funkit2
	* is there any sample data?
	tst.l	n_wavestart(a4)
	beq.b	k_funkend
;	move.b	n_funkspeed(a4),d0
;	beq.b	k_funkend
	ext	d0
	move.b	k_funktable(pc,d0),d0
	add.b	d0,n_funkoffset(a4)
	btst	#7,n_funkoffset(a4)
	beq.b	k_funkend
	clr.b	n_funkoffset(a4)

	move.l	n_loopstart(a4),d1
	moveq	#0,d0
	move	n_replen(a4),d0
	add.l	d0,d0
	add.l	d1,d0
	move.l	n_wavestart(a4),a0
	addq.l	#1,a0
	cmp.l	d0,a0
	blo.b	k_funkok
	move.l	d1,a0
k_funkok
	move.l	a0,n_wavestart(a4)
	not.b	(a0)
;	moveq	#-1,d0
;	sub.b	(a0),d0
;	move.b	d0,(a0)
k_funkend
	rts

k_funktable
	dc.b	0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128


*		c   c#  d   d#  e   f   f#  g   g#  a   a#  b  

	dc	900
k_periodtable
k_pt1	dc	856,808,762,720,678,640,604,570,538,508,480,453
	dc	428,404,381,360,339,320,302,285,269,254,240,226
	dc	214,202,190,180,170,160,151,143,135,127,120,113

k_pt2	dc	850,802,757,715,674,637,601,567,535,505,477,450
	dc	425,401,379,357,337,318,300,284,268,253,239,225
	dc	213,201,189,179,169,159,150,142,134,126,119,113
k_pt3	dc	844,796,752,709,670,632,597,563,532,502,474,447
	dc	422,398,376,355,335,316,298,282,266,251,237,224
	dc	211,199,188,177,167,158,149,141,133,125,118,112
k_pt4	dc	838,791,746,704,665,628,592,559,528,498,470,444
	dc	419,395,373,352,332,314,296,280,264,249,235,222
	dc	209,198,187,176,166,157,148,140,132,125,118,111
k_pt5	dc	832,785,741,699,660,623,588,555,524,495,467,441
	dc	416,392,370,350,330,312,294,278,262,247,233,220
	dc	208,196,185,175,165,156,147,139,131,124,117,110
k_pt6	dc	826,779,736,694,655,619,584,551,520,491,463,437
	dc	413,390,368,347,328,309,292,276,260,245,232,219
	dc	206,195,184,174,164,155,146,138,130,123,116,109
k_pt7	dc	820,774,730,689,651,614,580,547,516,487,460,434
	dc	410,387,365,345,325,307,290,274,258,244,230,217
	dc	205,193,183,172,163,154,145,137,129,122,115,109
k_pt8	dc	814,768,725,684,646,610,575,543,513,484,457,431
	dc	407,384,363,342,323,305,288,272,256,242,228,216
	dc	204,192,181,171,161,152,144,136,128,121,114,108
k_pt9	dc	907,856,808,762,720,678,640,604,570,538,508,480
	dc	453,428,404,381,360,339,320,302,285,269,254,240
	dc	226,214,202,190,180,170,160,151,143,135,127,120
k_pt10	dc	900,850,802,757,715,675,636,601,567,535,505,477
	dc	450,425,401,379,357,337,318,300,284,268,253,238
	dc	225,212,200,189,179,169,159,150,142,134,126,119
k_pt11	dc	894,844,796,752,709,670,632,597,563,532,502,474
	dc	447,422,398,376,355,335,316,298,282,266,251,237
	dc	223,211,199,188,177,167,158,149,141,133,125,118
k_pt12	dc	887,838,791,746,704,665,628,592,559,528,498,470
	dc	444,419,395,373,352,332,314,296,280,264,249,235
	dc	222,209,198,187,176,166,157,148,140,132,125,118
k_pt13	dc	881,832,785,741,699,660,623,588,555,524,494,467
	dc	441,416,392,370,350,330,312,294,278,262,247,233
	dc	220,208,196,185,175,165,156,147,139,131,123,117
k_pt14	dc	875,826,779,736,694,655,619,584,551,520,491,463
	dc	437,413,390,368,347,328,309,292,276,260,245,232
	dc	219,206,195,184,174,164,155,146,138,130,123,116
k_pt15	dc	868,820,774,730,689,651,614,580,547,516,487,460
	dc	434,410,387,365,345,325,307,290,274,258,244,230
	dc	217,205,193,183,172,163,154,145,137,129,122,115
k_pt16	dc	862,814,768,725,684,646,610,575,543,513,484,457
	dc	431,407,384,363,342,323,305,288,272,256,242,228
	dc	216,203,192,181,171,161,152,144,136,128,121,114

binend

 ifnd __VASM
	section	blah,bss_p

k_base	ds.b	k_sizeof


	section	po,data_c

;module	incbin	music:mod.figure
;module	incbin	sys:music/mod.realdeal
module	incbin	sys:music/mod.test9
 endif