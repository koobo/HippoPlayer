;APS0000111100009186000035070000AAA70004B5BE0005F05A00042D4800049C1F000030E30000C0A3

test	=	0

 ifnd DEBUG
DEBUG	=	0
 endif

* Print to debug console, very clever.
* Param 1: string
* d0-d6:    formatting parameters, d7 is reserved
DPRINT macro
	ifne DEBUG
	bsr	desmsgDebugAndPrint
  dc.b 	\1,10,0
  even
	endc
	endm


**** Sample player

*** IFF/RIFF WAVE/AIFF mono/stereo 8/14/16-bit Paula/AHI
*** unpacked/xpk packed
*** mp1-3 tuki (sample format = 4)

	incdir	include:
	include	exec/exec_lib.i
	include	exec/execbase.i
	include	exec/memory.i
	include	dos/dos_lib.i
	include	dos/dosextens.i
	include	dos/dostags.i
    include	dos/var.i
	include	graphics/graphics_lib.i

	include	libraries/xpkmaster_lib.i
	include	libraries/xpk.i

	include	devices/ahi.i
	include	devices/ahi_lib.i

	include	utility/hooks.i

	include	mucro.i

;KUTISTUSTAAJUUS	=	28603
KUTISTUSTAAJUUS	=	27710


ier_error	=	-1
ier_nochannels	=	-2
ier_nociaints	=	-3
ier_noaudints	=	-4
ier_nomedplayerlib =	-5
ier_nomedplayerlib2 =	-6
ier_mederr	=	-7
ier_playererr	=	-8
ier_nomem	=	-9
ier_nosid	=	-10
ier_sidicon	=	-11
ier_sidinit	=	-12
ier_noprocess	=	-13
ier_nochip	=	-14
ier_unknown	=	-15
ier_grouperror	=	-16
ier_filerr	=	-17
ier_hardware	=	-18
ier_ahi		=	-19

****************** MPEGA library

_LVOMPEGA_open 		=	-30
_LVOMPEGA_close 	=	-36
_LVOMPEGA_decode 	=	-42
_LVOMPEGA_seek 		=	-48
_LVOMPEGA_time 		=	-54
_LVOMPEGA_find_sync	=	-60
_LVOMPEGA_scale	   =	-66

MPEGA_BSFUNC_OPEN  = 0
MPEGA_BSFUNC_CLOSE = 1
MPEGA_BSFUNC_READ  = 2
MPEGA_BSFUNC_SEEK  = 3

MPEGA_MODE_STEREO   = 0
MPEGA_MODE_J_STEREO = 1
MPEGA_MODE_DUAL     = 2
MPEGA_MODE_MONO     = 3

MPEGA_MAX_CHANNELS = 2    ; Max channels
MPEGA_PCM_SIZE     = 1152 ; Max samples per frame

MPEGA_ERR_NONE     = 0
MPEGA_ERR_BASE     = 0
MPEGA_ERR_EOF      = (MPEGA_ERR_BASE-1)
MPEGA_ERR_BADFRAME = (MPEGA_ERR_BASE-2)
MPEGA_ERR_MEM      = (MPEGA_ERR_BASE-3)
MPEGA_ERR_NO_SYNC  = (MPEGA_ERR_BASE-4)

;/* Full control structure of MPEG Audio decoding */
;typedef struct {
;   struct Hook *bs_access;    /* NULL for default access (file I/O) or give your own bitstream access */
;   MPEGA_LAYER layer_1_2;     /* Layer I & II settings */
;   MPEGA_LAYER layer_3;       /* Layer III settings */
;   WORD check_mpeg;           /* 1 to check for mpeg audio validity at start of stream, 0 otherwise */
;   LONG stream_buffer_size;   /* size of bitstream buffer in bytes (0 -> default size) */
;                              /* NOTE: stream_buffer_size must be multiple of 4 bytes */
;} MPEGA_CTRL;

; ULONG __saveds __asm HookFunc( register __a0 struct Hook  *hook,
;                                  register __a2 APTR          handle,
;                                  register __a1 MPEGA_ACCESS *access );
;
;   MPEGA_ACCESS struct specify bitstream access function & parameters
;
;   access->func == MPEGA_BSFUNC_OPEN
;      open the bitstream
;      access->data.open.buffer_size is the i/o block size your read function can use
;      access->data.open.stream_size is the total size of the current stream
;                                    (in bytes, set it to 0 if unknown)
;      return your file handle (or NULL if failed)
;   access->func == MPEGA_BSFUNC_CLOSE
;      close the bitstream
;      return 0 if ok
;   access->func == MPEGA_BSFUNC_READ
;      read bytes from bitstream.
;      access->data.read.buffer is the destination buffer.
;      access->data.read.num_bytes is the number of bytes requested for read.
;      return # of bytes read or 0 if EOF.
;   access->func == MPEGA_BSFUNC_SEEK
;      seek into the bitstream
;      access->data.seek.abs_byte_seek_pos is the absolute byte position to reach.
;      return 0 if ok





**********************

iword	macro
	ror	#8,\1
	endm

ilword	macro
	ror	#8,\1
	swap	\1
	ror	#8,\1
	endm

tlword	macro
	move.b	\1,\2
	ror.l	#8,\2
	move.b	\1,\2
	ror.l	#8,\2
	move.b	\1,\2
	ror.l	#8,\2
	move.b	\1,\2
	ror.l	#8,\2
	endm

tword	macro
	move.b	\1,\2
	ror	#8,\2
	move.b	\1,\2
	ror	#8,\2
	endm



* sampletyypit

;sam_iff		=	0
;sam_iffs	=	1
;sam_aiff	=	2
;sam_aiffs	=	3
;sam_wav		=	4
;sam_wavs	=	5



** xpk laturi
	STRUCTURE myFH,0
	ULONG	mfh_fh		;(must be the first item!!)
	UWORD	mfh_is_xpk	;if non-zero then XPK
	ULONG	mfh_filepos	;XPK only - position in file
	APTR	mfh_xbuff	;XPK only - address of decrunch buffer
	ULONG	mfh_xbuffsize	;XPK only - size of decrunch buffer (=XPK chunksize)
	APTR	mfh_buffpos	;XPK only - current position in decrunch buffer
	ULONG	mfh_buffcontent	;XPK only - current content of decrunch buffer
	APTR	mfh_filename	;(must be the last item!!)
	LABEL	mfh_SIZEOF


	rsreset

_ExecBase	rs.l	1
_DosBase	rs.l	1
_GFXBase	rs.l	1
_XPKBase	rs.l	1
_MPEGABase	rs.l	1
ahibase		rs.l	1
ahi_task	rs.l	1
ahi_ctrl	rs.l	1
ahiflags	rs.l	1
modulefilename	rs.l	1
probebuffer	rs.b	500
kokonaisaika	rs.l	1
desbuf		rs.b	256
textBuffer  rs.b    128
colordiv	rs.l	1
sample_prosessi	rs	1
mainvolume	rs	1
pname		rs.l	1

varaa		rs.l	1
vapauta		rs.l	1

songover	rs.l	1

cpu		rs.b	1
cybercalibration rs.b	1
calibrationaddr	rs.l	1

sampleforcerate	rs	1
samplebuf	rs.l	1	* sampleplayeri
;samplehandle	rs.l	1	* sampletiedosto
;samplehandle2	rs.l	1	* sampletiedosto 2
killsample	rs.b	1
		rs.b	1

fh1	rs.b	mfh_SIZEOF
fh2	rs.b	mfh_SIZEOF

mpstream	rs.l	1	* mp1-3 stream
mplippu		rs	1
mpbitrate	rs	1
mplayer		rs	1
mpbuffpos	rs.l	1
mpbuffcontent	rs.l	1
mpfreqdiv	rs	1
mpqual		rs	1

sampleformat	rs.b	1	* 1: iff, 2: aiff, 3: riff, 4: mp
samplebits	rs.b	1
samplestereo	rs.b	1
samplestop	rs.b	1
samplebarf	rs.b	1
samplecyberset	rs.b	1
samplework	rs.l	1
samplework2	rs.l	1
samplebodysize	rs.l	1
samplestart	rs.l	1
samplefreq	rs	1

samplebuffer	rs.l	8+1
samplecyber	rs.l	1

sampleper	rs	1
samplepointer	rs.l	1
samplepointer2	rs.l	1
samplefollow	rs.l	1
sampleadd	rs.l	1

kutistus	rs.b	1	* ~0: kutistetaan yli 28kHz samplet 28kHz:iin
samplebufsiz0	rs.b	1
samplebufsiz	rs.l	1

ahi		rs.b	1
ahitrigger	rs.b	1

ahisample1	rs.l	1
ahisample2	rs.l	1
ahisample3	rs.l	1
ahisample4	rs.l	1

mainTask        rs.l    1
mpStreamerTask  rs.l    1
id3v2Data       rs.l    1
mpega_sync_position rs.l 1

 if DEBUG
output			rs.l 	1
debugDesBuf		rs.b	1000
 endif

size_var	rs.b	0



; REM
 ifne test
	lea	var_b,a5
	move.l	4.w,(a5)
	move.l	(a5),a6
	lea	.dosn(pc),a1
	lob	OldOpenLibrary
	move.l	d0,_DosBase(a5)

	move	#1,mpfreqdiv(a5)
	move.l	#.mo,modulefilename(a5)
	move	#2,d1	
	addq.b	#2,d1
	moveq	#1,d0
	lsl	d1,d0
	lsl.l	#8,d0
	lsl.l	#2,d0
	cmp.l	#$20000,d0
	bne.b	.nfo
	subq.l	#8,d0
.nfo
	move.l	d0,samplebufsiz(a5)
	jmp	init\.mpinit

.dosn	dc.b	"dos.library",0
;.mo	dc.b	"m:mp3/desalmados.mp3",0
.mo	dc.b	"m:mp3/matt gray - refourmation/who knows.mp3",0
 even
 endif


	jmp	init(pc)
	jmp	endSamplePlay(pc)
	jmp	stop(pc)
	jmp	cont(pc)
	jmp	vol(pc)
	jmp	ahi_update(pc)
	jmp	ahinfo(pc)
    jmp hasMp3TagText(pc)
    jmp getMp3TagText(pc)

	dc.l	16
sample_segment
	dc.l	0
	jmp	sample_code


 ifd DEBUG
flash1	move	#$f00,d0
	bra.b	fla
flash2	move	#$0f0,d0
	bra.b	fla
flash3	move	#$00f,d0
	bra.w	fla

fla	move	d0,$dff180
	btst	#6,$bfe001
	bne.b	fla

	swap	d0
	move	#-1,d0
.r	dbf	d0,.r
	swap	d0
	lsr	#1,d0
.f	move	d0,$dff180
	btst	#6,$bfe001
	beq.b	.f
	rts
 endc

ahinfo
	move.b	d0,ahi+var_b
	move.l	d1,ahirate
	move	d2,ahi_mastervol
	mulu	#$8000,d3
	divu	#100,d3
	move	d3,ahi_stereolev
	move.l	d4,ahimode

** vähän muutakin
* d5 = mpega qua 0,1,2
* d6 = mpega div 0,1,2

	move.b	d5,mpqual+1+var_b
	moveq	#1,d0
	lsl	d6,d0
	move	d0,mpfreqdiv+var_b

	rts

endSamplePlay:
	pushm	all
	DPRINT	"end sample play"
	lea	var_b(pc),a5
	st	killsample(a5)
.w	
	* Wait for the process to exit
	moveq	#2,d1
	lore	Dos,Delay
	tst	sample_prosessi(a5)
	bne.b	.w

	* Try this again, should be done
	* in the same task as ahi_init, otherwise might
	* hang.
	bsr	ahi_end

 if DEBUG
	move.l	output(a5),d1
	beq.b	.noDbg
	move.l	#2*50,d1
	lore	Dos,Delay
	move.l	output(a5),d1
	clr.l	output(a5)
	lore	Dos,Close
.noDbg
 endif

	popm	all
	rts
	
vol	
	pushm	all
	lea	var_b(pc),a5
	bsr.b	.b
	popm	all
	rts

.b	
	move	d0,mainvolume(a5)

	tst.b	ahi(a5)
	bne.w	ahivol

    tst     mplippu(a5)
    bne     .mp3vol

	lea	$dff0a8,a0

	move.b	samplecyberset(a5),d1
	bne.b	.volc

	move	d0,(a0)			* vasen
	move	d0,$10(a0)		* oikea
	move	d0,$20(a0)		* oikea
	move	d0,$30(a0)		* vasen
	rts

.volc	move	#1,(a0)			* 14-bit volumet
	move	#1,$10(a0)
	move	#$40,$20(a0)
	move	#$40,$30(a0)
	rts

    * For mp3 volume use the scale mechanism, keep paula volume constant
    * to allow 14-bit output to work
.mp3vol
    tst.l 	_MPEGABase(a5)
    beq.b 	.x
    lea	$dff0a8,a0
    bsr     .volc
    * turn into 0..100 percentage
    mulu    #100,d0
    lsr     #6,d0
    move.l	mpstream(a5),a0
    lore    MPEGA,MPEGA_scale
.x
    rts


cont	clr.b	samplestop+var_b
	rts
stop	st	samplestop+var_b
	rts

init:
	lea	var_b(pc),a5
	bsr.b	.doInit
	DPRINT	"init status=%ld"
 if DEBUG
	tst.l	d0
	beq.b	._1
	move.l	output(a5),d1
	beq.b	._1
	move.l	#4*50,d1
	lore	Dos,Delay
	move.l	output(a5),d1
	clr.l	output(a5)
	lore	Dos,Close
._1
 endif
	tst.l	d0
	rts
.doInit
	* Two subroutine calls when getting here, hence 4+4
	move.b	13+4+4(sp),kutistus(a5)
	move.l	8+4+4(sp),songover(a5)
	move.l	4+4+4(sp),colordiv(a5)
	move.l	4+4(sp),_XPKBase(a5)

	move.b	d0,samplebufsiz0(a5)
	move.b	d1,sampleformat(a5)

	move.l	d2,varaa(a5)
	move.l	d3,vapauta(a5)

;	move.l	d4,probebuffer(a5)
	move.l	d5,kokonaisaika(a5)

	move.b	d6,cybercalibration(a5)
	move.l	d7,calibrationaddr(a5)

	move.l	4.w,(a5)
	move.l	a1,_DosBase(a5)
	move.l	a2,_GFXBase(a5)
	move.l	a3,pname(a5)
	move.l	a4,modulefilename(a5)

	move	a6,sampleforcerate(a5)

	tst.b	ahi(a5)		* jos AHI, ei kutistusta eikä calibrationia
	beq.b	.noz
	clr.b	kutistus(a5)
	clr.b	cybercalibration(a5)
.noz
	DPRINT	"Start"

	move.l	(a5),a0
	btst	#AFB_68020,AttnFlags+1(a0)
	sne	cpu(a5)	

	tst	sample_prosessi(a5)
	bne.b	.q
	bsr.w	varaa_kanavat
	beq.w	.ok
	DPRINT	"No audio"
	moveq	#ier_nochannels,d0
.q	rts

.ok

*********
	clr.b	samplestop(a5)
	clr.b	samplebarf(a5)
	clr.b	samplebits(a5)
	clr.b	samplestereo(a5)
	clr.b	samplecyberset(a5)

	move.b	samplebufsiz0(a5),d1
	addq.b	#2,d1
	moveq	#1,d0
	lsl	d1,d0
	lsl.l	#8,d0
	lsl.l	#2,d0

;	cmp.l	#$20000,d0
;	bne.b	.nfo
;	subq.l	#8,d0
;.nfo

    ; range 4-128 kB
	move.l	d0,samplebufsiz(a5)
    DPRINT  "sample buffer=%ld"

    bsr     isRemoteSample
    bne     .remote

*** Kiskaistaan sample auki jotta saadaan tietoa
	lea	fh1(a5),a0
	move.l	modulefilename(a5),mfh_filename(a0)
	bsr.w	_xopen
	tst.l	d0
	bne.w	.orok

	pushpea	probebuffer(a5),d2
	move.l	#200,d3
	lea	fh1(a5),a0
	bsr.w	_xread
	tst.l	d0
	bmi.w	.orok

	lea	fh1(a5),a0
	bsr.w	_xclose
*************
.remote

	cmp.b	#2,sampleformat(a5)
	beq.w	.aiffinit
	cmp.b	#3,sampleformat(a5)
	beq.w	.wavinit

	cmp.b	#4,sampleformat(a5)
	beq.w	.mpinit


***** IFF INIT

.iffinit

	move.l	#200,d2
	moveq	#4,d0
	lea	probebuffer(a5),a4
	lea	.v(pc),a1
	bsr.w	sea
	bne.w	.vaara

	tst.b	15+4(a0)		* onko sCompression?
	bne.w	.vaara
	move	12+4(a0),samplefreq(a5)

	move.l	#200,d2
	moveq	#4,d0
	lea	probebuffer(a5),a4
	lea	.v2(pc),a1
	bsr.w	sea
	bne.w	.vaara

	move.l	(a0)+,samplebodysize(a5)
	move.l	a0,d0			* alkuoffsetti
	sub.l	a4,d0
	move.l	d0,samplestart(a5)

	move.l	samplebodysize(a5),d0
	bsr.w	.moi

	lea	fh1(a5),a0
	move.l	modulefilename(a5),mfh_filename(a0)
	bsr.w	_xopen
	bne.b	.orok

;	move.l	modulefilename(a5),d1
;	move.l	#MODE_OLDFILE,d2
;	lore	Dos,Open
;	move.l	d0,samplehandle(a5)
;	beq.b	.orok

	move.l	#200,d2			* onko stereo?
	moveq	#4,d0
	lea	probebuffer(a5),a4
	lea	.v3(pc),a1
	bsr.w	sea
	bne.w	.sampleok
	cmp.l	#6,4(a0)
	bne.w	.sampleok

* jaahas, se on stereo
	st	samplestereo(a5)

	move.l	samplebodysize(a5),d0	* lasketaan aika uudestaan
	bsr.b	.moi

	lea	fh2(a5),a0
	move.l	modulefilename(a5),mfh_filename(a0)
	bsr.w	_xopen
	beq.w	.sampleok

;	move.l	modulefilename(a5),d1
;	move.l	#MODE_OLDFILE,d2
;	lore	Dos,Open
;	move.l	d0,samplehandle2(a5)
;	bne.w	.sampleok

.orok
	DPRINT	"ier_filerr"
	moveq	#ier_filerr,d0
	bra.w	sampleiik
	

.v	dc.b	"VHDR",0
.v2	dc.b	"BODY",0
.v3	dc.b	"CHAN",0
.w0	dc.b	"fmt ",0
.w2	dc.b	"data",0
.ai0	dc.b	"COMM",0
.ai1	dc.b	"SSND",0
 even


.moi	
	bsr.w	.freqcheck

	tst.b	samplebits(a5)		* lasketaan kestoaika
	beq.b	.moi0
	lsr.l	#1,d0
.moi0	tst.b	samplestereo(a5)
	beq.b	.moi1
	lsr.l	#1,d0
.moi1	divu	samplefreq(a5),d0

.moi_mp
    DPRINT  "format duration %ld secs"
	ext.l	d0
	divu	#60,d0

	push	a0
	move.l	kokonaisaika(a5),a0
	move	d0,(a0)+
	swap	d0
	move	d0,(a0)
	pop	a0
	rts

****** WAV INIT
.wavinit
	move.l	#200,d2
	moveq	#4,d0
	lea	probebuffer(a5),a4
	lea	.w0(pc),a1
	bsr.w	sea
	bne.w	.vaara

	cmp	#$0100,4(a0)	* onko WAVE_FORMAT_PCM?
	bne.w	.vaara
	cmp	#$0100,6(a0)
	beq.b	.wavm
	cmp	#$0200,6(a0)
	bne.w	.vaara
	st	samplestereo(a5)
.wavm

	move.l	8(a0),d0
	ilword	d0
	move	d0,samplefreq(a5)

	move.b	18(a0),d0
	cmp.b	#8,d0

	beq.b	.wa1
	cmp.b	#16,d0
	bne.w	.vaara
	st	samplebits(a5)
.wa1
	lea	.w2(pc),a1
	move.l	#200,d2
	moveq	#4,d0
	lea	probebuffer(a5),a4
	bsr.w	sea
	bne.w	.vaara

	tlword	(a0)+,d0
.wah
	bsr.w	.moi

	move.l	a0,d0			* alkuoffsetti
	sub.l	a4,d0
	move.l	d0,samplestart(a5)

	move.l	samplebufsiz(a5),d0
	tst.b	samplestereo(a5)
	beq.b	.wa2
	add.l	d0,d0
.wa2	tst.b	samplebits(a5)
	beq.b	.wa3
	add.l	d0,d0
.wa3
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1	* AIFF/WAVille työpuskureita
	bsr.w	getmem
	move.l	d0,samplework(a5)
	bne.b	.wa4
	DPRINT	"ier_nomem"
	moveq	#ier_nomem,d0
	bra.w	sampleiik
.wa4

	lea	fh1(a5),a0
	move.l	modulefilename(a5),mfh_filename(a0)
	bsr.w	_xopen
	bne.w	.orok

;	move.l	modulefilename(a5),d1
;	move.l	#MODE_OLDFILE,d2
;	lore	Dos,Open
;	move.l	d0,samplehandle(a5)
;	beq.w	.orok

	bra.w	.sampleok

*********** AIFF init

.aiffinit
	move.l	#200,d2
	moveq	#4,d0
	lea	probebuffer(a5),a4
	lea	.ai0(pc),a1
	bsr.w	sea
	bne.w	.vaara

	cmp	#1,4(a0)
	beq.b	.aimo
	cmp	#2,4(a0)
	bne.w	.vaara
	st	samplestereo(a5)
.aimo

	cmp	#8,10(a0)
	beq.b	.aim0
	cmp	#16,10(a0)
	bne.w	.vaara
	st	samplebits(a5)
.aim0

	move	12(a0),d0	* exponent
	move.l	14(a0),d1	* mantissa

	sub	#$3fff+31,d0
	neg	d0
	lsr.l	d0,d1
	move	d1,samplefreq(a5)

	lea	.ai1(pc),a1
	move.l	#200,d2
	moveq	#4,d0
	lea	probebuffer(a5),a4
	bsr.w	sea
	bne.w	.vaara

	move.l	(a0)+,d0
	bra.w	.wah


*********** MP init

.mpinit
	DPRINT	"MPEGA init"

* mpega stream
	rsreset
.norm		rs	1	* 1 or 2
.layer		rs	1	* 0...3
.mode		rs	1	* 1...3
.bitrate	rs	1	* in kbps	
.frequency	rs.l	1	* in Hz
.channels	rs	1	* 1 or 2
.ms_duration	rs.l	1	* duration in ms



	move	mpfreqdiv(a5),d0
	move	mpqual(a5),d1

	lea	.control(pc),a0
	basereg	.control,a0
	move	d0,.fd1(a0)
	move	d0,.fd2(a0)
	move	d0,.fd3(a0)
	move	d0,.fd4(a0)
	move	d1,.q1(a0)
	move	d1,.q2(a0)
	move	d1,.q3(a0)
	move	d1,.q4(a0)
	endb	a0

	move.l	4.w,a6
	lea	.mplibn(pc),a1
	lob	OldOpenLibrary
	move.l	d0,_MPEGABase(a5)
	bne.b	.uzx
	DPRINT	"no MPEGA"
	moveq	#ier_error,d0
	bra.w	sampleiik
.uzx

	* Set up hook
	lea	.mpega_hook(pc),a0
	lea	.mpega_hook_func(pc),a1
	move.l	a1,h_Entry(a0)

	move.l	modulefilename(a5),a0
    bsr     isRemoteSample
    beq     .local
    bsr     mp_start_streaming
    DPRINT  "open PIPE:",0
    lea     pipefile(pc),a0
.local

 if DEBUG
	move.l	a0,d0
	DPRINT	"MPEGA_open %s"
 endif
	lea	.control(pc),a1	
	lore	MPEGA,MPEGA_open
	move.l	d0,mpstream(a5)
	bne.b	.uz
.nostream
	DPRINT	"no MPEGA stream"
	moveq	#ier_filerr,d0
	bra.w	sampleiik
.uz
	move.l	d0,a3

	clr.l	mpbuffpos(a5)
	clr.l	mpbuffcontent(a5)

	move	.layer(a3),mplayer(a5)
	move	.bitrate(a3),mpbitrate(a5)
;	move	.channels(a0),d3
;	move.l	.ms_duration(a0),d4	

	move	.mode(a3),d0
	cmp	#MPEGA_MODE_MONO,d0
	sne	samplestereo(a5)	* stereo
	st	samplebits(a5)		* 16-bit

	move.l	.frequency(a3),d0
	divu	mpfreqdiv(a5),d0
	move	d0,samplefreq(a5)
 
 if DEBUG
	move.l	.frequency(a3),d0
    DPRINT  "freq=%ld Hz"
	move.l	.ms_duration(a3),d0	
    DPRINT  "duration=%ld ms"
 endif

    moveq   #0,d0
    bsr     isRemoteSample
    bne     .remote2
	move.l	.ms_duration(a3),d0	* pituus millisekunteina
 	divu	#1000,d0
.remote2
	bsr.w	.moi_mp
	bsr.w	.freqcheck

	st	mplippu(a5)
	move.b	#2,sampleformat(a5)	* huijataan että ollaan AIFF
    * Enforce 14-bit output for MP3 if high quality settings
    cmp     #1,mpfreqdiv(a5)
    bne.b   .lq
    tst.b   samplestereo(a5)
    beq.b   .lq
    st      cybercalibration(a5)
    DPRINT  "Enabling 14-bit mp3 output"
.lq

	move.l	samplebufsiz(a5),d0
	lsl.l	#2,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	bsr.w	getmem
	move.l	d0,samplework(a5)
	bne.b	.wa4q
	DPRINT	"ier_nomem"
	moveq	#ier_nomem,d0
	bra.w	sampleiik
.wa4q

	bra.w	.sampleok




.control	
	dc.l	.mpega_hook	* no hook
;	dc.l	0

* layer 1 & 2
	dc	0	* 1 = force mono
* mono
.fd1	dc	4	* freq_div 1, 2 or 4
.q1	dc	0	* quality 0 (low) ... 2 (high)
	dc.l	0	* freq_max
* stereo
.fd2	dc	4	* freq_div 1, 2 or 4
.q2	dc	0	* quality 0 (low) ... 2 (high)
	dc.l	0	* freq_max

	
* layer 3
	dc	0	* 1 = force mono
* mono
.fd3	dc	4	* freq_div 1, 2 or 4
.q3	dc	0	* quality 0 (low) ... 2 (high)
	dc.l	0	* freq_max
* stereo
.fd4	dc	4	* freq_div 1, 2 or 4
.q4	dc	0	* quality 0 (low) ... 2 (high)
	dc.l	0	* freq_max


	dc	0	* check validity if 1 
	dc.l	0	* stream buffer size (0=default)



.mplibn	dc.b	"mpega.library",0
 even



;typedef struct {
;
;   LONG  func;           /* MPEGA_BSFUNC_xxx */
;   union {
;      struct {
;         char *stream_name; /* in */
;         LONG buffer_size;  /* in */
;         LONG stream_size;  /* out */
;      } open;
;      struct {
;         void *buffer;      /* in/out */
;         LONG num_bytes;    /* in */
;      } read;
;      struct {
;         LONG abs_byte_seek_pos; /* out */
;      } seek;
;   } data;
;
;} MPEGA_ACCESS;

.mpega_hook
	* Hook structure from utility.i
	ds.b	h_SIZEOF
	
* In:
*   a0 = APTR hook
*   a1 = MPEGA_ACCESS *access
*   a2 = APTR handle
.mpega_hook_func
	pushm	d1-a6
	bsr.b	.doHook
	popm	d1-a6
	rts
.doHook
	lea	var_b(pc),a5
	move.l	_DosBase(a5),a6

	cmp.l	#MPEGA_BSFUNC_OPEN,(a1)
	beq 	.mpega_hook_open
	cmp.l	#MPEGA_BSFUNC_READ,(a1)
	beq 	.mpega_hook_read
	cmp.l	#MPEGA_BSFUNC_SEEK,(a1)
	beq 	.mpega_hook_seek
	cmp.l	#MPEGA_BSFUNC_CLOSE,(a1)
	beq 	.mpega_hook_close
	moveq	#-1,d0
	rts

.mpega_hook_open
	DPRINT	"mpega_hook_open"
	move.l	a1,a3
	move.l	4(a3),d1 	 * stream_name

	move.l	#MODE_OLDFILE,d2
	lob	Open
	move.l	d0,d7
	beq 	.mpega_open_error 

    bsr     mpega_skip_id3v2_stream
   
	clr.l   12(a3) * stream_size

    move.l  d7,d1
    lob     IsInteractive
    tst.l   d0
    bne     .cantSeek

    * Get current position
	move.l	d7,d1
    moveq	#0,d2		* offset
	moveq	#OFFSET_CURRENT,d3
	lob	Seek
    move.l  d0,d4
    DPRINT  "current=%ld"
    * Seek to end
	move.l	d7,d1	
    moveq	#0,d2		* offset
	moveq	#OFFSET_END,d3
	lob	Seek
    * Go back to current position
	move.l	d7,d1	
    move.l  d4,d2
	moveq	#OFFSET_BEGINNING,d3
	lob	Seek
    * d0 = old position, the end
    * subtract the original current position
    * so that any skipped data is not included
    sub.l   d4,d0 
	move.l	d0,12(a3) * stream_size
    DPRINT  "stream size = %ld"
 
.cantSeek
	* Return Dos file handle
	move.l	d7,d0
.mpega_open_error
	rts	

.mpega_hook_close
	DPRINT	"mpega_hook_close"
	move.l	a2,d1
	beq.b	.nullHandle
	lob	Close
	moveq	#0,d0	* ok
	rts
.nullHandle
	moveq	#-1,d0 * not ok
	rts	

.mpega_hook_read
 if DEBUG
	pushm	all
	move.l	a1,a4
	move.l	a2,d1
	moveq	#0,d2
	moveq	#OFFSET_CURRENT,d3
	lob	Seek
	move.l	d0,d1

	move.l	8(a4),d0 * length to read
	DPRINT	"mpega_hook_read %ld at %ld"
	popm	all
 endif
	move.l	a2,d1    * handle
	move.l	4(a1),d2 * buffer addr
	move.l	8(a1),d3 * length to read
	lob	Read
	* d0 = bytes read or NULL if eof
	cmp.l	#-1,d0
	beq.b	.mpega_read_err
	rts	
.mpega_read_err
	* eof
	moveq	#0,d0
	rts

.mpega_hook_seek
	DPRINT	"mpega_hook_seek"
	move.l	a2,d1
	move.l	4(a1),d2	* abs_byte_seek_pos
	add.l	mpega_sync_position(a5),d2
	moveq	#OFFSET_BEGINNING,d3
	lob	Seek
	cmp.l	#-1,d0
	beq.b	.seek_err
	moveq	#0,d0 * ok
	rts
.seek_err
    DPRINT  "seek failed!"
	rts



.freqcheck:
	push	d0
	move	#60000,d0
	cmp	samplefreq(a5),d0
	bhs.b	.ofq
	move	d0,samplefreq(a5)
.ofq
	move	sampleforcerate(a5),d0
	beq.b	.ofqq
	add	#9,d0
	mulu	#100,d0
	move	d0,samplefreq(a5)
.ofqq	pop	d0
	rts




******* Ok. Let's soitetaan


.sampleok
	bsr.b	.freqcheck

** muotoillaan inforivi hipolle

	lea	.t1(pc),a0
	move.b	sampleformat(a5),d0
	subq.b	#1,d0
	beq.b	.fr1
	lea	.t2(pc),a0
	subq.b	#1,d0
	beq.b	.fr1
	lea	.t3(pc),a0
.fr1	move.l	a0,d0

	tst	mplippu(a5)
	beq.b	.yi0
	move	mplayer(a5),d0
	ext.l	d0
.yi0

	moveq	#8,d1
	tst.b	samplebits(a5)
	beq.b	.fr3
	moveq	#16,d1
.fr3
	tst	mplippu(a5)
	beq.b	.nomp
	move	mpbitrate(a5),d1
.nomp

	moveq	#"S",d2
	tst.b	samplestereo(a5)
	bne.b	.fr2
	moveq	#"M",d2
.fr2	

	moveq	#0,d3
	move	samplefreq(a5),d3
	add	#500,d3			* pyöristetään ylöspäin
	divu	#1000,d3
	ext.l	d3

    moveq   #8,d4
    tst.b   samplestereo(a5)
    beq.b   .lqq
    cmp     #44100,samplefreq(a5)
    blo.b   .lqq
    tst.b   cpu(a5)
    beq.b   .lqq
    moveq   #14,d4
.lqq

	lea	.form(pc),a0
	tst	mplippu(a5)
	beq.b	.nomp2
	lea	.form2(pc),a0
.nomp2
	bsr.w	desmsg

	lea	desbuf(a5),a0
	move.l	pname(a5),a1
.ci	move.b	(a0)+,(a1)+
	bne.b	.ci



** varataan puskurit


	lea	samplebuffer(a5),a3

	tst.b	ahi(a5)		* jos ahi, ei tarvita näitä puskureita
	bne.b	.ok2

	moveq	#2,d6				* kaksi puskuria monolle

	move.l	samplebufsiz(a5),d0
	tst.b	samplestereo(a5)
	beq.b	.es
	add	d6,d6				* neljä stereolle
.es

	tst.b	cybercalibration(a5)		* kalibroitu 14-bittinen
	beq.b	.es2
	tst.b	samplebits(a5)
	beq.b	.es2
	tst.l	calibrationaddr(a5)
	;beq.b	.es2
	st	samplecyberset(a5)
	add	d6,d6				* 8 kpl
.es2




	subq	#1,d6
.allocloo
	move.l	samplebufsiz(a5),d0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	bsr.w	getmem
	move.l	d0,(a3)+
	beq.b	.memerr
	dbf	d6,.allocloo

	bsr.w	initsamplecyber
	beq.b	.memerr

	bra.b	.ok2

.memerr
	DPRINT	"ier_nochip"
	moveq	#ier_nochip,d0
	bra.w	sampleiik
.ok2


	move.l	#3546895,d4
	move.l	(a5),a0
	cmp.b	#60,PowerSupplyFrequency(a0)
	bne.b	.nx
;	move.l	#3579545,d4
	move	#$9E99,d4
.nx	

*** kutistus? varataan työtilaa sillekkin jos tarvis

	moveq	#0,d7
	move	samplefreq(a5),d7

 if DEBUG
	move.l	d7,d0
	DPRINT	"frequency=%ld"
 endif

	tst.b	kutistus(a5)
	beq.b	.nok
	cmp	#KUTISTUSTAAJUUS,d7
	blo.b	.nok
    DPRINT  "need resampling"
	move	#KUTISTUSTAAJUUS,d7

	move.l	samplebufsiz(a5),d0	* kutistukselle

	cmp.b	#1,sampleformat(a5)
	beq.b	.iffku1
	tst.b	samplecyberset(a5)
	beq.b	.iffku0
	add.l	d0,d0			* calibration, 2x
.iffku0	tst.b	samplestereo(a5)
	beq.b	.iffku1
	add.l	d0,d0			* stereo, 4x
.iffku1

	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	bsr.w	getmem
	move.l	d0,samplework2(a5)
	bne.b	.nik
	DPRINT	"ier_nomem"
	moveq	#ier_nomem,d0
	bra.w	sampleiik

.nok	clr.b	kutistus(a5)		* ei tartte kutistaa
.nik	

	divu	d7,d4
	move	d4,sampleper(a5)	* samplen periodi
 if DEBUG
	moveq	#0,d0
	move	d4,d0
	DPRINT	"period=%ld"
 endif
	move.l	colordiv(a5),d0	
 	DPRINT	"colordiv=%ld"
	divu	d4,d0
	ext.l	d0
	move.l	d0,sampleadd(a5)	* seuranta, paljonko soitetaan framessa

**** ahi? tarvitaan puskureita..

	tst.b	ahi(a5)
	beq.w	.nika

	cmp.b	#1,sampleformat(a5)	* jos AHI ja IFF, pari työpurskuria
	bne.b	.naiff
	move.l	samplebufsiz(a5),d0
	tst.b	samplestereo(a5)
	beq.b	.naod
	add.l	d0,d0
.naod	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	bsr.w	getmem
	move.l	d0,samplework(a5)
	beq.b	.nomo
.naiff

	lea	ahisample1(a5),a3	* ahille left/right 8 tai 16 bit
	moveq	#4-1,d3

.alco	move.l	samplebufsiz(a5),d0

	tst.b	samplebits(a5)
	beq.b	.can
	add.l	d0,d0			* 16-bit
.can
	move.l	d0,d4

	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	bsr.w	getmem
	move.l	d0,(a3)+
	beq.b	.nomo
	dbf	d3,.alco
	bra.b	.ahin
.nomo
	DPRINT	"ier_nomem"
	moveq	#ier_nomem,d0
	bra.w	sampleiik

*** ahi init

.ahin
	move.l	ahisample1(a5),d0
	movem.l	d0/d4,ahi_sound1+4
	move.l	ahisample2(a5),d0
	movem.l	d0/d4,ahi_sound2+4
	move.l	ahisample3(a5),d0
	movem.l	d0/d4,ahi_sound3+4
	move.l	ahisample4(a5),d0
	movem.l	d0/d4,ahi_sound4+4

	moveq	#AHIST_M16S,d0		* sampletyyppi
	tst.b	samplebits(a5)
	bne.b	.can0
	moveq	#AHIST_M8S,d0
.can0	move.l	d0,ahi_sound1
	move.l	d0,ahi_sound2
	move.l	d0,ahi_sound3
	move.l	d0,ahi_sound4


;	tst.l	ahibase(a5)
;	beq.b	.noaf
;	bsr	ahi_end
;.noaf
	bsr.w	ahi_alustus
	bne.b	.ahi_error


.nika

	move	mainvolume+var_b(pc),d0
	bsr.w	vol

	DPRINT	"CreateProc"

** käynnistetään prosessi
	pushpea	.pn(pc),d1
	moveq	#0,d2			* pri
	pushpea	sample_segment(pc),d3
	lsr.l	#2,d3
	move.l	#4000,d4
	lore	Dos,CreateProc
	tst.l	d0
	beq.b	.error
	addq	#1,sample_prosessi(a5)

** palautetaan arvoja
	move.l	sampleadd(a5),d1
	lea	samplefollow(a5),a0
	lea	samplepointer(a5),a1
	lea	samplepointer2(a5),a2
	move.b	samplestereo(a5),d2
	move.l	samplebufsiz(a5),d3

 if DEBUG
	pushm	all
	move.l	d1,d0
	move.l	d3,d1
	DPRINT	"add=%ld buf=%ld"
	popm	all 
 endif
	moveq	#0,d0
	rts

.ahi_error
	bsr.w	ahi_end
	DPRINT	"ier_ahi"
	moveq	#ier_ahi,d0
	bra.w	sampleiik


.error	
	DPRINT	"ier_noprocess"
	moveq	#ier_noprocess,d0
	bra.w	sampleiik

.vaara
	DPRINT	"ier_unknown"
	moveq	#ier_unknown,d0
	bra.w	sampleiik


.t1	dc.b	"IFF 8SVX",0
.t2	dc.b	"AIFF",0
.t3	dc.b	"RIFF WAVE",0
.t4	dc.b	"MP",0
.form	dc.b	"%s %ld-bit %lc %2ldkHz",0
.form2	dc.b	"MP%ld %ldkB %lc %2ldkHz %ld-bit",0
.pn	dc.b	"HiP-Sample",0
 even

isRemoteSample
    pushm   d0/a0
	move.l	modulefilename(a5),a0
    cmp.b   #"h",(a0)
    bne     .local
    cmp.b   #"t",1(a0)
    bne     .local
    cmp.b   #"t",2(a0)
    bne     .local
    cmp.b   #"p",3(a0)
    bne     .local
    cmp.b   #":",4(a0)
    bne     .local
    DPRINT  "remote file"
    moveq   #1,d0
    popm    d0/a0
    rts
.local
    moveq   #0,d0
    popm    d0/a0
    rts


*******************************************************************************
* AHI kamat

ahi_alustus
	pushm	all

	sub.l	a1,a1
	move.l	4.w,a6
	lob	FindTask
	move.l	d0,ahi_task(a5)
	DPRINT	"ahi_init task=%lx"

	OPENAHI	1
	move.l	d0,ahibase(a5)
	beq.w	.ahi_error		* oudosti tämä bugaa välillä.
	move.l	d0,a6

	lea	ahi_tags(pc),a1
	jsr	_LVOAHI_AllocAudioA(a6)
	move.l	d0,ahi_ctrl(a5)
	beq.w	.ahi_error
	move.l	d0,a2

	moveq	#0,d0				;sample 1
	moveq	#AHIST_DYNAMICSAMPLE,d1
	lea	ahi_sound1(pc),a0
	jsr	_LVOAHI_LoadSound(a6)
	tst.l	d0
	bne.w	.ahi_error

	moveq	#1,d0				;sample 2
	moveq	#AHIST_DYNAMICSAMPLE,d1
	lea	ahi_sound2(pc),a0
	jsr	_LVOAHI_LoadSound(a6)
	tst.l	d0
	bne.w	.ahi_error

	moveq	#2,d0				;sample 3
	moveq	#AHIST_DYNAMICSAMPLE,d1
	lea	ahi_sound3(pc),a0
	jsr	_LVOAHI_LoadSound(a6)
	tst.l	d0
	bne.w	.ahi_error

	moveq	#3,d0				;sample 4
	moveq	#AHIST_DYNAMICSAMPLE,d1
	lea	ahi_sound4(pc),a0
	jsr	_LVOAHI_LoadSound(a6)
	tst.l	d0
	bne.w	.ahi_error

	move.l	ahimode(pc),d0
	lea	getattr_tags(pc),a1
	jsr	_LVOAHI_GetAudioAttrsA(a6)

	bsr.w	ahi_setmastervol
	move	mainvolume+var_b(pc),d0
	bsr.w	vol

**** frequency
	moveq	#0,d0		* channel
	moveq	#0,d1
	move	samplefreq(a5),d1 * freq in hertz
	moveq	#AHISF_IMM,d2	* flags
	move.l	ahi_ctrl(a5),a2
	jsr	_LVOAHI_SetFreq(a6)

	moveq	#1,d0		* channel
	moveq	#0,d1
	move	samplefreq(a5),d1 * freq in hertz
	moveq	#AHISF_IMM,d2	* flags
	move.l	ahi_ctrl(a5),a2
	jsr	_LVOAHI_SetFreq(a6)

	lea	ahi_ctrltags(pc),a1
	jsr	_LVOAHI_ControlAudioA(a6)
	DPRINT	"->control audio: %ld"
	tst.l	d0
	bne.b	.ahi_error

	popm	all
	moveq	#0,d0
	rts

.ahi_error
	popm	all
	moveq	#-1,d0
	rts




ahi_sound1
	dc.l	AHIST_M16S	* type
	dc.l	0		* addr
	dc.l	0		* len

ahi_sound2
	dc.l	AHIST_M16S
	dc.l	0
	dc.l	0


ahi_sound3
	dc.l	AHIST_M16S
	dc.l	0
	dc.l	0

ahi_sound4
	dc.l	AHIST_M16S
	dc.l	0
	dc.l	0

ahi_end:
	pushm	all

 	sub.l	a1,a1
	move.l	4.w,a6
	lob	FindTask
	DPRINT	"ahi_end task=%lx"
	cmp.l	ahi_task(a5),d0
	beq.b	.ok
	DPRINT	"task mismatch, skipping"
	bra.b	.x
.ok
	move.l	ahibase(a5),d0
	beq.b	.1
	DPRINT	"ahi_end"
	move.l	d0,a6

	move.l	ahi_ctrl(a5),a2
	jsr	_LVOAHI_FreeAudio(a6)
	CLOSEAHI
	DPRINT	"close ahi ok"
.1	clr.l	ahibase(a5)
.x	popm	all
	rts

ahi_ctrltags:
	dc.l	AHIC_Play,1
setpause = *-1
	dc.l	TAG_DONE
ahi_tags
	dc.l	AHIA_MixFreq,28000
ahirate = *-4
	dc.l	AHIA_Channels,2
	dc.l	AHIA_Sounds,4
	dc.l	AHIA_AudioID,$00020004		; Just an example! No hardcoded values permitted!
ahimode = *-4

	dc.l	AHIA_SoundFunc,SoundFunc
	dc.l	TAG_DONE

SoundFunc:
	blk.b	MLN_SIZE
	dc.l	soundfunc
	dc.l	0
	dc.l	0

soundfunc:
	cmp	#1,ahism_Channel(a1)
	beq.b	.x
	st	ahitrigger+var_b
.x	rts

;ahi_enablesound
;	pushm	all
;	cmp.b	#1,setpause
;	beq.b	ahibax
;	move.b	#1,setpause
;ahibahi	lea	ahi_ctrltags(pc),a1
;	move.l	ahibase(a5),a6
;	jsr	_LVOAHI_ControlAudioA(a6)
;ahibax
;	popm	all
;	rts

;ahi_stopsound
;	pushm	all
;	clr.b	setpause
;	bra.b	ahibahi
	


ahi_mastervol	dc	0
ahi_stereolev	dc	0
attr_stereo	dc.l	0
attr_panning	dc.l	0


ahi_update

	move	d0,ahi_mastervol
	mulu	#$8000,d1
	divu	#100,d1
	move	d1,ahi_stereolev
	bsr.b	ahi_setmastervol
	bsr.b	ahivol
	rts

ahi_setmastervol
	pushm	d0/d1/a0-a2/a6

	moveq	#2,d0			* 2 channels
	tst.l	attr_stereo
	beq.b	.mono
	tst.l	attr_panning		* sama jos panning
	bne.b	.mono
	lsr.l	#1,d0
.mono					* d0 = max master vol
	subq	#1,d0
	lsl.l	#8,d0

	mulu	ahi_mastervol(pc),d0
	divu	#1000,d0
	ext.l	d0
	add	#1<<8,d0
	lsl.l	#8,d0

	move.l	#AHIET_MASTERVOLUME,ahi_effect+ahie_Effect
	move.l	d0,ahi_effect+ahiemv_Volume

	lea	ahi_effect(pc),a0
	move.l	ahi_ctrl+var_b(pc),a2
	move.l	ahibase+var_b(pc),d1
	beq.b	.x
	move.l	d1,a6
	jsr	_LVOAHI_SetEffect(a6)
.x

	popm	d0/d1/a0-a2/a6
	rts

ahi_effect
	ds.b	AHIEffMasterVolume_SIZEOF


getattr_tags
	dc.l	AHIDB_Stereo,attr_stereo
	dc.l	AHIDB_Panning,attr_panning
	dc.l	TAG_END

ahivol
	move	mainvolume+var_b(pc),d0
	moveq	#0,d6
	bsr.b	ahi_setvolume
	move	mainvolume+var_b(pc),d0
	moveq	#1,d6
	bsr.b	ahi_setvolume
	rts

;in:
* d0	volume
* d6	channel
ahi_setvolume:
	movem.l	d0-d3/d6/a0-a2/a6,-(sp)

	moveq	#0,d1
	move	d0,d1
	lsl.l	#8,d1
	lsl.l	#2,d1

	moveq	#0,d2
	move.l	#$8000,d2		* keskellä
	moveq	#0,d3
	move	ahi_stereolev(pc),d3
	btst	#0,d6		
	beq.b	.parillinen
	neg.l	d3			
.parillinen				* parillinen = oikealla
	add.l	d3,d2

	move.l	d6,d0

	move.l	ahibase+var_b(pc),d3
	beq.b	.xa
	move.l	d3,a6

	moveq	#AHISF_IMM,d3
	move.l	ahi_ctrl+var_b(pc),a2
;	move.l	ahibase+var_b(pc),a6
	jsr	_LVOAHI_SetVol(a6)
.xa	movem.l	(sp)+,d0-d3/d6/a0-a2/a6
	rts

ahi_stopsound
ahihalt	pushm	all
	DPRINT	"ahi_stopsound"
	moveq	#0,d0		* channel
	moveq	#0,d1		* freq = 0, temporary stop
	move.l	ahi_ctrl+var_b(pc),a2
	move.l	ahibase+var_b(pc),d2
	beq.b	.x
	move.l	d2,a6
	moveq	#AHISF_IMM,d2
	jsr	_LVOAHI_SetFreq(a6)

	moveq	#1,d0		* channel
	moveq	#0,d1		* freq = 0, temporary stop
	moveq	#AHISF_IMM,d2
	move.l	ahi_ctrl+var_b(pc),a2
	jsr	_LVOAHI_SetFreq(a6)


	moveq	#0,d0
	moveq	#0,d6
	bsr.b	ahi_setvolume
	moveq	#0,d0
	moveq	#1,d6
	bsr.w	ahi_setvolume

.x
	popm	all
	rts

ahi_enablesound
ahiunhalt
	pushm	all
	moveq	#0,d0		* channel
	moveq	#0,d1		* freq
	move	samplefreq+var_b(pc),d1
	move.l	ahi_ctrl+var_b(pc),a2
	move.l	ahibase+var_b(pc),d2
	beq.b	.x
	move.l	d2,a6
	moveq	#AHISF_IMM,d2
	jsr	_LVOAHI_SetFreq(a6)

	moveq	#1,d0		* channel
	move	samplefreq+var_b(pc),d1
	moveq	#AHISF_IMM,d2
	move.l	ahi_ctrl+var_b(pc),a2
	jsr	_LVOAHI_SetFreq(a6)

	move	mainvolume+var_b(pc),d0
	moveq	#0,d6
	bsr.w	ahi_setvolume
	move	mainvolume+var_b(pc),d0
	moveq	#1,d6
	bsr.w	ahi_setvolume


.x	popm	all
	rts


*******************************************************************************



sampleiik:

	pushm	all
	
	bsr.w	clearsound
	bsr.w	vapauta_kanavat
	bsr.w	closesample

	bsr.w	ahi_end

	move.l	samplework(a5),a0
	bsr.w	freemem
	clr.l	samplework(a5)
	move.l	samplework2(a5),a0
	bsr.w	freemem
	clr.l	samplework2(a5)
	move.l	samplecyber(a5),a0
	bsr.w	freemem
	clr.l	samplecyber(a5)


	lea	samplebuffer(a5),a3
.f	move.l	(a3)+,d0
	beq.b	.b
	move.l	d0,a0

	bsr.w	freemem
	clr.l	-4(a3)
	bra.b	.f
.b

	move.l	ahisample1(a5),a0
	bsr.w	freemem
	move.l	ahisample2(a5),a0
	bsr.w	freemem
	move.l	ahisample3(a5),a0
	bsr.w	freemem
	move.l	ahisample4(a5),a0	* mis-aligned freemem??
	bsr.w	freemem	

	clr.l	ahisample1(a5)
	clr.l	ahisample2(a5)
	clr.l	ahisample3(a5)
	clr.l	ahisample4(a5)


	move.l	_MPEGABase(a5),d0
	beq.b	.x
	move.l	d0,a1
	lore	Exec,CloseLibrary
	clr.l	_MPEGABase(a5)
.x

	popm	all
	rts

**************** 

sample_code
	lea	var_b(pc),a5
	addq	#1,sample_prosessi(a5)

	DPRINT	"Process"

;	bsr	ahi_alustus
;	beq	.zee
;.koa	move	$dff006,$dff180
;	btst	#6,$bfe001
;	bne.b	.koa
;	bra	quit2
;.zee
;	move	mainvolume+var_b(pc),d0
;	bsr.w	vol


;	moveq	#10,d1
;.ee	move	#-1,d0
;.e	move	$dff006,$dff180
;	dbf	d0,.e
;	dbf	d1,.ee

;	bsr.w	sampleiik
;	lore	Exec,Forbid
;	clr	sample_prosessi(a5)
;	clr.b	killsample(a5)
;	rts



************ IFF
	cmp.b	#2,sampleformat(a5)
	beq.w	.aiff
	cmp.b	#3,sampleformat(a5)
	beq.w	.wav
.iff

	tst.b	samplestereo(a5)
	bne.w	.iffs

**** AHI IFF mono

	tst.b	ahi(a5)
	beq.b	.loop0

	move.l	samplework(a5),a4
	lea	ahisample1(a5),a3

.llpopo3
	move.l	#AHISF_IMM,ahiflags(a5)
	moveq	#0,d7

;	move.l	samplehandle(a5),d1
;	move.l	samplestart(a5),d2		* bodyn alkuun
;	moveq	#-1,d3
;	lore	Dos,Seek

	lea	fh1(a5),a0
	move.l	samplestart(a5),d2		* bodyn alkuun
	moveq	#OFFSET_BEGINNING,d3
	bsr.w	_xseek


.loopahi3
	move.l	a4,d2
	move.l	samplebufsiz(a5),d3
;	move.l	samplehandle(a5),d1
;	lore	Dos,Read	

	lea	fh1(a5),a0
	bsr.w	_xread

	move.l	d0,d6
	beq.w	quit

	movem.l	(a3),a0/a1	
	move.l	a4,a2
	move.l	d6,d0		* len
	lsr.l	#1,d0
	subq	#1,d0

.mahmo	move	(a2)+,d1
	move	d1,(a0)+	* toinen puoli
	move	d1,(a1)+	* ja toinen
	dbf	d0,.mahmo

	bsr.w	ahiunhalt

	bsr.w	ahiplay

	bsr.w	wait
	bne.w	quit

	bsr.w	ahiswap

	cmp.l	samplebufsiz(a5),d6
	beq.b	.loopahi3

	bsr.w	wait
	bsr.w	songoverr

	bsr.w	ahihalt
	
	bra.b	.llpopo3




*******************




.loop0
	bsr.w	clrsamplebuf


	lea	samplebuffer(a5),a3

	clr.l	samplefollow(a5)
	move.l	4(a3),samplepointer(a5)

;	move.l	samplehandle(a5),d1
;	move.l	samplestart(a5),d2		* bodyn alkuun
;	moveq	#-1,d3
;	lore	Dos,Seek


;	bsr	flash1

	lea	fh1(a5),a0
	move.l	samplestart(a5),d2		* bodyn alkuun
	moveq	#OFFSET_BEGINNING,d3
	bsr.w	_xseek

;	bsr	flash2

.loop
	move.l	(a3),d2			* chip
		tst.b	kutistus(a5)
		beq.b	.nk1
		move.l	samplework2(a5),d2	* työpuskuri kutistukselle
.nk1

	move.l	samplebufsiz(a5),d3
;	move.l	samplehandle(a5),d1
;	lore	Dos,Read	


	lea	fh1(a5),a0
	bsr.w	_xread


;	bsr	flash3

	move.l	d0,d6
	beq.w	quit

	tst.b	kutistus(a5)
	beq.b	.nk2
		move.l	(a3),a1		* kohde
		move.l	samplework2(a5),a0 * lähde
		move.l	d6,d2		* pituus
		bsr.w	truncate	* kutistetaan, uusi pituus = d0
		bra.b	.nk3
.nk2
	move.l	d6,d0
.nk3	lsr.l	#1,d0
	move.l	(a3),a0
	move.l	(a3),a1
	bsr.w	playblock
	bsr.w	wait
	bne.w	quit

	clr.l	samplefollow(a5)
	move.l	(a3),samplepointer(a5)
 
	movem.l	(a3),d0/d1
	exg	d0,d1
	movem.l	d0/d1,(a3)

	cmp.l	samplebufsiz(a5),d6
	beq.b	.loop

	bsr.w	wait
	bsr.w	songoverr
	bra.w	.loop0
	


*********** IFF STEREO
.iffs


**** AHI IFF stereo

	tst.b	ahi(a5)
	beq.w	.iffss

	move.l	samplework(a5),a4
	lea	ahisample1(a5),a3

.llpopo4
	move.l	#AHISF_IMM,ahiflags(a5)
	moveq	#0,d7

;	move.l	samplehandle(a5),d1
;	move.l	samplestart(a5),d2		* bodyn alkuun
;	moveq	#-1,d3
;	lore	Dos,Seek

	lea	fh1(a5),a0
	move.l	samplestart(a5),d2		* bodyn alkuun
	moveq	#OFFSET_BEGINNING,d3
	bsr.w	_xseek

;	move.l	samplehandle2(a5),d1
;	move.l	samplestart(a5),d2		* bodyn alkuun
;	move.l	samplebodysize(a5),d3
;	lsr.l	#1,d3
;	add.l	d3,d2
;	moveq	#-1,d3
;	lob	Seek

	lea	fh2(a5),a0
	move.l	samplestart(a5),d2		* bodyn alkuun
	move.l	samplebodysize(a5),d3
	lsr.l	#1,d3
	add.l	d3,d2

	moveq	#OFFSET_BEGINNING,d3
	bsr.w	_xseek



.loopahi4
	move.l	a4,d2
	move.l	samplebufsiz(a5),d3
;	move.l	samplehandle(a5),d1
;	lore	Dos,Read	

	lea	fh1(a5),a0
	bsr.w	_xread

	tst.l	d0
	beq.w	quit

	move.l	a4,d2
	move.l	samplebufsiz(a5),d3
	add.l	d3,d2
;	move.l	samplehandle2(a5),d1
;	lore	Dos,Read	

	lea	fh2(a5),a0
	bsr.w	_xread

	move.l	d0,d6
	beq.w	quit

	push	a6

	movem.l	(a3),a0/a1	
	move.l	a4,a2
	move.l	a2,a6
	add.l	samplebufsiz(a5),a6
	move.l	d6,d0		* len
	lsr.l	#1,d0
	subq	#1,d0

.mahmo2	move	(a2)+,(a0)+
	move	(a6)+,(a1)+
	dbf	d0,.mahmo2

	pop	a6

	bsr.w	ahiunhalt

	bsr.w	ahiplay

	bsr.w	wait
	bne.w	quit

	bsr.w	ahiswap

	cmp.l	samplebufsiz(a5),d6
	beq.b	.loopahi4

	bsr.w	wait
	bsr.w	songoverr

	bsr.w	ahihalt
	
	bra.w	.llpopo4




.iffss

*********** IFF stereo


	bsr.w	clrsamplebuf


	lea	samplebuffer(a5),a3
	
	clr.l	samplefollow(a5)

	move.l	8(a3),samplepointer(a5)
	move.l	12(a3),samplepointer2(a5)

;	move.l	samplehandle(a5),d1
;	move.l	samplestart(a5),d2		* bodyn alkuun
;	moveq	#-1,d3
;	lore	Dos,Seek

	lea	fh1(a5),a0
	move.l	samplestart(a5),d2		* bodyn alkuun
	moveq	#OFFSET_BEGINNING,d3
	bsr.w	_xseek

;	move.l	samplehandle2(a5),d1
;	move.l	samplestart(a5),d2		* bodyn alkuun
;	move.l	samplebodysize(a5),d3
;	lsr.l	#1,d3
;	add.l	d3,d2
;	moveq	#-1,d3
;	lob	Seek

	lea	fh2(a5),a0
	move.l	samplestart(a5),d2		* bodyn alkuun
	move.l	samplebodysize(a5),d3
	lsr.l	#1,d3
	add.l	d3,d2
	moveq	#OFFSET_BEGINNING,d3
	bsr.w	_xseek


.loops
	move.l	(a3),d2
	tst.b	kutistus(a5)
	beq.b	.nks0
		move.l	samplework2(a5),d2
.nks0
	move.l	samplebufsiz(a5),d3
;	move.l	samplehandle(a5),d1
;	lore	Dos,Read	

	lea	fh1(a5),a0
	bsr.w	_xread

	tst.l	d0
	beq.w	quit

	tst.b	kutistus(a5)
	beq.b	.nks1
		move.l	(a3),a1		* kohde
		move.l	samplework2(a5),a0 * lähde
		move.l	d0,d2		* pituus
		bsr.w	truncate	* kutistetaan, uusi pituus = d0
.nks1


	move.l	4(a3),d2
	tst.b	kutistus(a5)
	beq.b	.nks2
		move.l	samplework2(a5),d2
.nks2

	move.l	samplebufsiz(a5),d3
;	move.l	samplehandle2(a5),d1
;	lore	Dos,Read	

	lea	fh2(a5),a0
	bsr.w	_xread

	move.l	d0,d6
	beq.w	quit

	tst.b	kutistus(a5)
	beq.b	.nks3
		move.l	4(a3),a1	* kohde
		move.l	samplework2(a5),a0 * lähde
		move.l	d6,d2		* pituus
		bsr.w	truncate	* kutistetaan, uusi pituus = d0
		bra.b	.nks4
.nks3


	move.l	d6,d0
.nks4	lsr.l	#1,d0
	movem.l	(a3),a0/a1
	bsr.w	playblock
	bsr.w	wait
	bne.w	quit

	clr.l	samplefollow(a5)
	move.l	(a3),samplepointer(a5)
	move.l	4(a3),samplepointer2(a5)

	movem.l	(a3),d0/d1/d2/d3
	exg	d0,d2
	exg	d1,d3
	movem.l	d0/d1/d2/d3,(a3)

	cmp.l	samplebufsiz(a5),d6
	beq.w	.loops

	bsr.w	wait
	bsr.w	songoverr
	bra.w	.iffs


************* WAV / AIFF
.aiff
	moveq	#-1,d5
	bra.b	.wow
.wav
	DPRINT	"WAV/AIFF"
	moveq	#0,d5

.wow	tst.b	samplestereo(a5)
	bne.w	.wavs


******** AHI AIFF/WAV mono

	tst.b	ahi(a5)
	beq.w	.wl


	move.l	samplework(a5),a4
	lea	ahisample1(a5),a3

.llpopo2
	move.l	#AHISF_IMM,ahiflags(a5)
	moveq	#0,d7


;	tst	mplippu(a5)
;	bne.b	.yi1
;	move.l	samplehandle(a5),d1
;	move.l	samplestart(a5),d2		* bodyn alkuun
;	moveq	#-1,d3
;	lore	Dos,Seek
;.yi1
	bsr.w	mp_start

.loopahi2

	bsr.w	.wavread
	beq.w	quit

	movem.l	(a3),a0/a1	
	move.l	a4,a2
	move.l	d6,d0		* len
	lsr.l	#1,d0
	subq	#1,d0

	move	#$8080,d1

	tst.b	samplebits(a5)
	bne.b	.ah16m
	tst.b	d5
	beq.b	.ahwa8m

.ah8m	move	(a2)+,d2	* 8-bit AIFF mono
	move	d2,(a0)+	
	move	d2,(a1)+
	dbf	d0,.ah8m
	bra.b	.ahacm

.ahwa8m
;	move	(a2)+,d2	* 8-bit WAV mono
;	ror	#8,d2
;	eor	d1,d2
;	move	d2,(a0)+
;	move	d2,(a1)+

 rept 2
	move.b	(a2)+,d2
	eor.b	d1,d2
	move.b	d2,(a0)+
	move.b	d2,(a1)+
 endr
	dbf	d0,.ahwa8m
	bra.b	.ahacm

.ah16m	tst.b	d5
	bne.b	.ah16mm
.ah16mo
 rept 2
	move	(a2)+,d2	* 16-bit WAV mono
	ror	#8,d2
	move	d2,(a0)+
	move	d2,(a1)+
 endr
	dbf	d0,.ah16mo
	bra.b	.ahacm

.ah16mm	move.l	(a2)+,d2	* 16-bit AIFF mono
	move.l	d2,(a0)+	
	move.l	d2,(a1)+
	dbf	d0,.ah16mm

.ahacm

	bsr.w	ahiunhalt

	bsr.w	ahiplay

	bsr.w	wait
	bne.w	quit

	bsr.w	ahiswap

	cmp.l	samplebufsiz(a5),d6
	beq.w	.loopahi2

	bsr.w	wait
	bsr.w	songoverr

	bsr.w	ahihalt
	
	bra.w	.llpopo2



********* AIFF/WAV mono



.wl
	DPRINT	"AIFF WAV/MONO"

	bsr.w	clrsamplebuf

	lea	samplebuffer(a5),a3

	move.l	samplework(a5),a4

	clr.l	samplefollow(a5)
	move.l	4(a3),samplepointer(a5)

;	tst	mplippu(a5)
;	bne.b	.yi2
;	move.l	samplehandle(a5),d1
;	move.l	samplestart(a5),d2		* bodyn alkuun
;	moveq	#-1,d3
;	lore	Dos,Seek
;.yi2
	bsr.w	mp_start

.loopw

	bsr.w	.wavread
	beq.w	quit

	tst.b	samplecyberset(a5)
	bne.b	.14bitmono

	move.l	(a3),a1
	tst.b	kutistus(a5)
	beq.b	.nkw0
		move.l	samplework2(a5),a1
.nkw0
	move.l	d6,d0
	move.l	a4,a0
	bsr.w	.convert_mono

	tst.b	kutistus(a5)
	beq.b	.nkw1
		move.l	(a3),a1		* kohde
		move.l	samplework2(a5),a0 * lähde
		move.l	d6,d2		* pituus
		bsr.w	truncate	* kutistetaan, uusi pituus = d0
		bra.b	.nkw3
.nkw1

	move.l	d6,d0
.nkw3	lsr.l	#1,d0
	move.l	(a3),a0
	move.l	(a3),a1
	bsr.w	playblock
	bsr.w	wait
	bne.w	quit

	clr.l	samplefollow(a5)
	move.l	(a3),samplepointer(a5)

	movem.l	(a3),d0/d1
	exg	d0,d1
	movem.l	d0/d1,(a3)

	bra.w	.oba


.14bitmono


	move.l	d6,d0
	move.l	a4,a0
	move.l	(a3),a1
	move.l	8(a3),a2

	tst.b	kutistus(a5)
	beq.b	.g0
		move.l	samplework2(a5),a1
		move.l	a1,a2
		add.l	samplebufsiz(a5),a2
.g0

	push	a6
	bsr.w	.convert_mono_14bit
	pop	a6

	tst.b	kutistus(a5)
	beq.b	.g1
		move.l	(a3),a1			* kohde
		move.l	samplework2(a5),a0 	* lähde
		move.l	d6,d2			* pituus
		bsr.w	truncate		* kutistetaan, uusi pituus = d0

		move.l	8(a3),a1		* kohde
		add.l	samplebufsiz(a5),a0
		bsr.w	truncate		* kutistetaan, uusi pituus = d0
		bra.b	.g2
.g1
	

	move.l	d6,d0
.g2	lsr.l	#1,d0
	move.l	(a3),a0
	move.l	a0,a1
	move.l	8(a3),a2
	push	a3
	move.l	a2,a3
	bsr.w	playblock_14bit
	pop	a3
	
	bsr.w	wait
	bne.w	quit

	clr.l	samplefollow(a5)
	move.l	8(a3),samplepointer(a5)
	move.l	8+4(a3),samplepointer2(a5)

	movem.l	(a3),d0/d1
	exg	d0,d1
	movem.l	d0/d1,(a3)

	movem.l	8(a3),d0/d1
	exg	d0,d1
	movem.l	d0/d1,8(a3)




.oba

	cmp.l	samplebufsiz(a5),d6
	beq.w	.loopw

	bsr.w	wait
	bsr.w	songoverr
	bra.w	.wl
	
.wavread	
	move.l	a4,d2
	move.l	samplebufsiz(a5),d3
	tst.b	samplebits(a5)
	beq.b	.w0
	add.l	d3,d3
.w0
;	move.l	samplehandle(a5),d1
;	lore	Dos,Read	

	tst	mplippu(a5)
	beq.b	.em1
	lsr.l	#1,d3
	bsr.w	read_mp_mono
	add.l	d0,d0
	bra.b	.emm1
.em1
	lea	fh1(a5),a0
	bsr.w	_xread

.emm1
	move.l	d0,d6
	tst.b	samplebits(a5)
	beq.b	.w1
	lsr.l	#1,d6
.w1	tst.l	d6
	rts


.convert_mono
* a0 = source
* a1 = dest
* d0 = len

	lsr.l	#2,d0
	subq	#1,d0

	tst	d5
	bne.b	.aiffc


	tst.b	samplebits(a5)
	bne.b	.w2
	move.l	#$80808080,d2
.w4	
	move.l	(a0)+,d1
	eor.l	d2,d1
	move.l	d1,(a1)+

	dbf	d0,.w4
	rts

.w2	
 rept 4
	move	(a0)+,d1
	move.b	d1,(a1)+
 endr
	dbf	d0,.w2
	rts

.aiffc
	tst.b	samplebits(a5)
	bne.b	.w22
.w42	
	move.l	(a0)+,(a1)+
	dbf	d0,.w42
	rts

.w22	
 rept 4
	move.b	(a0)+,(a1)+
	addq	#1,a0
 endr
	dbf	d0,.w22
	rts







.convert_mono_14bit
* a0 = source
* a1 = dest 1
* a2 = dest 2
* d0 = len

	move.l	samplecyber(a5),a6

	lsr.l	#2,d0
	subq	#1,d0
	moveq	#0,d1

	tst	d5
	bne.w	.aiffc14

	tst.b	cpu(a5)
	bne.b	.w214_020

.w214	
 rept 4
	moveq	#0,d1
	move	(a0)+,d1
	ror	#8,d1
	add.l	d1,d1
	move.b	(a6,d1.l),(a2)+
	move.b	1(a6,d1.l),(a1)+
 endr
 
	dbf	d0,.w214
	rts

.w214_020
 rept 4
	move	(a0)+,d1
	ror	#8,d1
	move.b	(a6,d1.l*2),(a2)+
	move.b	1(a6,d1.l*2),(a1)+
 endr

	dbf	d0,.w214_020
	rts


.aiffc14
	tst.b	cpu(a5)
	bne.b	.w2214_020
.w2214
 rept 4
	moveq	#0,d1
	move	(a0)+,d1
	add.l	d1,d1
	move.b	(a6,d1.l),(a2)+
	move.b	1(a6,d1.l),(a1)+
 endr
	dbf	d0,.w2214
	rts

.w2214_020
 rept 4
	move	(a0)+,d1
	move.b	(a6,d1.l*2),(a2)+
	move.b	(a6,d1.l*2),(a1)+
 endr
	dbf	d0,.w2214_020
	rts



************* AIFF/WAV stereo

.wavs	
	tst.b	ahi(a5)
	beq.w	.noah


**** AHI, AIFF/WAV stereo
	DPRINT	"AHI AIFF/WAV STEREO"

	move.l	samplework(a5),a4
	lea	ahisample1(a5),a3

.llpopo
	move.l	#AHISF_IMM,ahiflags(a5)
	moveq	#0,d7

;	tst	mplippu(a5)
;	bne.b	.yi3
;	move.l	samplehandle(a5),d1
;	move.l	samplestart(a5),d2		* bodyn alkuun
;	moveq	#-1,d3
;	lore	Dos,Seek
.yi3
	bsr.w	mp_start

.loopahi1

	bsr.w	wavread2
	beq.w	quit

	movem.l	(a3),a0/a1	
	move.l	a4,a2
	move.l	d6,d0		* len
	lsr.l	#1,d0
	subq	#1,d0

	tst.b	samplebits(a5)
	bne.b	.ah16
	move.b	#$80,d1
	tst.b	d5
	beq.b	.ahwa8

.ah8	
 rept 2
 	move.b	(a2)+,(a0)+	* 8-bit AIFF stereo
	move.b	(a2)+,(a1)+
 endr
	dbf	d0,.ah8
	bra.b	.ahac

.ahwa8	
 rept 2
	move.b	(a2)+,d2	* 8-bit WAV stereo
	eor.b	d1,d2
	move.b	d2,(a0)+
	move.b	(a2)+,d2
	eor.b	d1,d2
	move.b	d2,(a1)+
 endr
	dbf	d0,.ahwa8
	bra.b	.ahac

.ah16
	tst.b	d5
	bne.b	.ah166
.ah11	
 rept 2
	move	(a2)+,d2
	ror	#8,d2
	move	d2,(a0)+	* 16-bit WAV stereo
	move	(a2)+,d2
	ror	#8,d2
	move	d2,(a1)+
 endr
	dbf	d0,.ah11
	bra.b	.ahac

.ah166	
 rept 2
	move	(a2)+,(a0)+	* 16-bit AIFF stereo
	move	(a2)+,(a1)+
 endr
	dbf	d0,.ah166

.ahac

	bsr.w	ahiunhalt

	bsr.w	ahiplay

	bsr.w	wait
	bne.w	quit

	bsr.w	ahiswap

	cmp.l	samplebufsiz(a5),d6
	beq.w	.loopahi1

	bsr.w	wait
	bsr.w	songoverr

	bsr.w	ahihalt
	
	bra.w	.llpopo

************************
.noah

********** AIFF/WAV STEREO

	DPRINT	"AIFF/WAV STEREO"

    * Detect mp3 special case when no cybersound calibration used
    tst.l   samplecyber(a5)
    bne.b   .wl2
    tst     mplippu(a5)
    bne     decodeMp3
.wl2

 
	bsr.w	clrsamplebuf

	move.l	samplework(a5),a4
	lea	samplebuffer(a5),a3

;	tst	mplippu(a5)
;	bne.b	.yi4
;	move.l	samplehandle(a5),d1
;	move.l	samplestart(a5),d2		* bodyn alkuun
;	moveq	#-1,d3
;	lore	Dos,Seek
;.yi4	
	bsr.w	mp_start

	clr.l	samplefollow(a5)
	move.l	8(a3),samplepointer(a5)
	move.l	12(a3),samplepointer2(a5)

.loopw2
	
	bsr.w	wavread2
	beq.w	quit

	tst.b	samplecyberset(a5)
	bne.b	.14bit0

	movem.l	(a3),a1/a2

	tst.b	kutistus(a5)
	beq.b	.h0
		move.l	samplework2(a5),a1
		move.l	a1,a2
		add.l	samplebufsiz(a5),a2
.h0

	move.l	d6,d0
	move.l	a4,a0
	bsr.w	convert_stereo

	tst.b	kutistus(a5)
	beq.b	.h1
		move.l	(a3),a1			* kohde
		move.l	samplework2(a5),a0 	* lähde
		move.l	d6,d2			* pituus
		bsr.w	truncate		* kutistetaan, uusi pituus = d0

		move.l	4(a3),a1		* kohde
		add.l	samplebufsiz(a5),a0
		bsr.w	truncate		* kutistetaan, uusi pituus = d0
		bra.b	.h2
.h1

	move.l	d6,d0
.h2	lsr.l	#1,d0
	movem.l	(a3),a0/a1
	bsr.w	playblock
	bsr.w	wait
	bne.w	quit

	clr.l	samplefollow(a5)
	move.l	(a3),samplepointer(a5)
	move.l	4(a3),samplepointer2(a5)

	movem.l	(a3),d0/d1/d2/d3
	exg	d0,d2
	exg	d1,d3
	movem.l	d0/d1/d2/d3,(a3)
	bra.w	.loh

.14bit0

	move.l	d6,d0
	move.l	a4,a0

	pushm	a3/a4/a6
	movem.l	(a3),a1/a2		* vas oik LSB kanavat
	movem.l	16(a3),a3/a4		* vas oik MSB kanavat

	tst.b	kutistus(a5)
	beq.b	.j0
		move.l	samplework2(a5),a1
		move.l	a1,a2
		add.l	samplebufsiz(a5),a2
		move.l	a2,a3
		add.l	samplebufsiz(a5),a3
		move.l	a3,a4
		add.l	samplebufsiz(a5),a4
.j0
    DPRINT  "convert stereo 14bit"
	bsr.w	convert_stereo_14bit

	movem.l	(sp),a3/a4/a6

	tst.b	kutistus(a5)
	beq.b	.j1
        DPRINT  "downsample"
		move.l	(a3),a1			* kohde
		move.l	samplework2(a5),a0 	* lähde
		move.l	d6,d2			* pituus
		bsr.w	truncate		* kutistetaan, uusi pituus = d0

		move.l	4(a3),a1		* kohde
		add.l	samplebufsiz(a5),a0
		bsr.w	truncate		* kutistetaan, uusi pituus = d0

		move.l	16(a3),a1		* kohde
		add.l	samplebufsiz(a5),a0
		bsr.w	truncate		* kutistetaan, uusi pituus = d0

		move.l	20(a3),a1		* kohde
		add.l	samplebufsiz(a5),a0
		bsr.w	truncate		* kutistetaan, uusi pituus = d0
		bra.b	.j2
.j1

	move.l	d6,d0
.j2	lsr.l	#1,d0
	movem.l	(a3),a0/a1
	movem.l	16(a3),a2/a3
	bsr.w	playblock_14bit

	popm	a3/a4/a6
	
	bsr.w	wait
	bne.w	quit

	clr.l	samplefollow(a5)
	move.l	16(a3),samplepointer(a5)
	move.l	16+4(a3),samplepointer2(a5)

	movem.l	(a3),d0/d1/d2/d3
	exg	d0,d2
	exg	d1,d3
	movem.l	d0/d1/d2/d3,(a3)

	movem.l	16(a3),d0/d1/d2/d3
	exg	d0,d2
	exg	d1,d3
	movem.l	d0/d1/d2/d3,16(a3)


.loh
	
	cmp.l	samplebufsiz(a5),d6
	beq.w	.loopw2

	bsr.w	wait
	bsr.w	songoverr
    * Start from the beginning?
	bra.w	.wl2
	

	

wavread2	
	move.l	a4,d2
	move.l	samplebufsiz(a5),d3
	add.l	d3,d3			* stereo
	tst.b	samplebits(a5)
	beq.b	.w00
	add.l	d3,d3
.w00
;	move.l	samplehandle(a5),d1
;	lore	Dos,Read	

	tst	mplippu(a5)
	beq.b	.em2
	lsr.l	#2,d3
	bsr.w	read_mp_stereo
	lsl.l	#2,d0
	bra.b	.emm2
.em2
	lea	fh1(a5),a0
	bsr.w	_xread

.emm2
	move.l	d0,d6
	tst.b	samplebits(a5)
	beq.b	.w10
	lsr.l	#1,d6
.w10	lsr.l	#1,d6
	rts


convert_stereo
* a0 = source
* a1 = dest 1 
* a2 = dest 2
* d0 = len

	lsr.l	#2,d0
	subq	#1,d0

	tst	d5
	bne.b	.aiffc2

	tst.b	samplebits(a5)
	bne.b	.w12
	move.b	#$80,d2
.w14	

 rept 4
	move.b	(a0)+,d1
	eor.b	d2,d1
	move.b	d1,(a1)+
	move.b	(a0)+,d1
	eor.b	d2,d1
	move.b	d1,(a2)+
 endr


	dbf	d0,.w14
	rts

.w12	
 rept 4
	move	(a0)+,d1
	move.b	d1,(a1)+
	move	(a0)+,d1
	move.b	d1,(a2)+
 endr
	dbf	d0,.w12
	rts


.aiffc2
	tst.b	samplebits(a5)
	bne.b	.w123
.w143	
 rept 4
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a2)+
 endr
	dbf	d0,.w143
	rts

.w123	
 rept 4
	move.b	(a0)+,(a1)+
	addq.l	#1,a0
	move.b	(a0)+,(a2)+
	addq.l	#1,a0
 endr
 	dbf	d0,.w123
	rts







convert_stereo_14bit
* a0 = source
* a1 = dest 1 
* a2 = dest 2
* a3 = dest 3
* a4 = dest 4
* d0 = len

    tst.l   samplecyber(a5)
    beq     .ordinary_stereo_14bit

	move.l	samplecyber(a5),a6

	lsr.l	#2,d0
	subq	#1,d0
	moveq	#0,d1

	tst	d5
	bne.w	.aiffc214

	tst.b	cpu(a5)
	bne.w	.w1214_020
.w1214
 rept 4
	moveq	#0,d1
	move	(a0)+,d1
	ror	#8,d1
	add.l	d1,d1
	move.b	(a6,d1.l),(a3)+
	move.b	1(a6,d1.l),(a1)+

	moveq	#0,d1
	move	(a0)+,d1
	ror	#8,d1
	add.l	d1,d1
	move.b	(a6,d1.l),(a4)+
	move.b	1(a6,d1.l),(a2)+
 endr
	dbf	d0,.w1214
	rts

.w1214_020
 rept 4
	move	(a0)+,d1
	ror	#8,d1
	move.b	(a6,d1.l*2),(a3)+
	move.b	1(a6,d1.l*2),(a1)+

	move	(a0)+,d1
	ror	#8,d1
	move.b	(a6,d1.l*2),(a4)+
	move.b	1(a6,d1.l*2),(a2)+
 endr
	dbf	d0,.w1214_020
	rts




.aiffc214
	tst.b	cpu(a5)
	bne.b	.w12314_020

.w12314	
 rept 4
	moveq	#0,d1
	move	(a0)+,d1
	add.l	d1,d1
	move.b	(a6,d1.l),(a3)+
	move.b	1(a6,d1.l),(a1)+

	moveq	#0,d1
	move	(a0)+,d1
	add.l	d1,d1
	move.b	(a6,d1.l),(a4)+
	move.b	1(a6,d1.l),(a2)+
 endr
 	dbf	d0,.w12314
	rts


.w12314_020
 rept 4
	move	(a0)+,d1
	move.b	(a6,d1.l*2),(a3)+
	move.b	1(a6,d1.l*2),(a1)+

	move	(a0)+,d1
	move.b	(a6,d1.l*2),(a4)+
	move.b	1(a6,d1.l*2),(a2)+
 endr
 	dbf	d0,.w12314_020
	rts


.ordinary_stereo_14bit
  	lsr.l	#2,d0
	subq	#1,d0

.o_w1214_020
 rept 4
	move	(a0)+,d1
    lsr.b   #2,d1
    move.b  d1,(a1)+
	ror	#8,d1
    move.b  d1,(a3)+

	move	(a0)+,d1
    lsr.b   #2,d1
    move.b  d1,(a2)+
	ror	#8,d1
    move.b  d1,(a4)+
 endr
 	dbf	d0,.o_w1214_020
	rts



; -----------------
    * Special case for stereo mp3
decodeMp3
.wl2
    DPRINT  "mp3 loop"
	bsr.w	clrsamplebuf

	move.l	samplework(a5),a4
	lea	samplebuffer(a5),a3

	bsr.w	mp_start

	clr.l	samplefollow(a5)
	move.l	8(a3),samplepointer(a5)
	move.l	12(a3),samplepointer2(a5)

.loopw2

	move.l	a4,d2
	move.l	samplebufsiz(a5),d3
	;add.l	d3,d3			* stereo
	;add.l	d3,d3       * 16-bits
	;lsr.l	#2,d3
    ;----------------------------------
    ; read mp3
	movem.l	d1-a6,-(a7)

	move.l	d2,a3

	move.l	d3,d7	;len
	moveq	#0,d5	;already read

.xloop	tst.l	d7
	bgt.b	.go_on
.eof	
	move.l	d5,d0
	bra.b	.exit

.go_on	move.l	mpbuffcontent(a5),d0
	ble.b	.read
	sub.l	d0,d7
	bge.b	.copy
	add.l	d0,d7
	move.l	d7,d0
	moveq	#0,d7
.copy	

	move.l	mpbuffpos(a5),d1
	add.l	d0,d5
	add.l	d0,mpbuffpos(a5)
	sub.l	d0,mpbuffcontent(a5)

	lea	mpbuffer1(pc),a0
	lea	mpbuffer2(pc),a1
	add.l	d1,d1
	add.l	d1,a0
	add.l	d1,a1

	subq	#1,d0

.co	move	(a0)+,(a3)+
	move	(a1)+,(a3)+
	dbf	d0,.co
	bra.b	.xloop

.read
	clr.l	mpbuffpos(a5)

	pushm	d1-a6
	move.l	mpstream(a5),a0
	lea	.pcm(pc),a1
	lore	MPEGA,MPEGA_decode
	popm	d1-a6
    * 1152 bytes decoded at a time
    move.l	d0,mpbuffcontent(a5)
	bmi.b	.eof
	bra.b	.xloop

.pcm	dc.l	mpbuffer1
	dc.l	mpbuffer2

.exit	movem.l	(a7)+,d1-a6
    bra     .continue

    ;----------------------------------
.continue
	lsl.l	#2,d0
	move.l	d0,d6
	lsr.l	#2,d6
;	beq.w	quit
    bne     .gotData
    DPRINT  "no more data!"
    bsr     songoverr
    bra     quit
.gotData

	move.l	d6,d0       * input length
	move.l	a4,a0

	pushm	a3/a4/a6
	movem.l	(a3),a1/a2		* vas oik LSB kanavat
	movem.l	16(a3),a3/a4		* vas oik MSB kanavat

    DPRINT  "convert and resample stereo 14bit"

    * Detemine resampling target frequency
    * In case no resampling needed, ratio will be 1:1 and step 1
    * Sample freq into d1 and d2
    moveq   #0,d1
    move    samplefreq(a5),d1
    move.l  d1,d2
    tst.b   kutistus(a5)
    beq.b   .do1
    move.l  #KUTISTUSTAAJUUS,d2
.do1

    * dest length = (target freq * source length)/source freq
    move.l  d2,d0
    mulu.l  d6,d0
    divu.l  d1,d0
    * d0 = target length
    push    d0

    * Calculate fractional step with 12-bit fractions
    * fffxxxxx.
    * Divide (target frequency)<<12 by destination frequency 
    lsl.l   #8,d1
    lsl.l   #4,d1
    divu.w  d2,d1
    ext.l   d1
    ror.l	#8,d1
	ror.l	#4,d1

    ; Start with index 0, X cleared
    sub.l   d2,d2
    ; Index mask
    move.l	#$0003ffff,d3
    ; Mask to clear two LSB bits from both right and left
    move.l  #%11111111111111001111111111111100,d5
    ; Two bytes, ie. a word, at a time
    lsr.l   #1,d0
    subq    #1,d0
.bob
 rept 2
    * Index into d4
    move.l  d2,d4
    and.l   d3,d4
    * Next sample
	addx.l	d1,d2

    * ror does not change X, lsr does, can't use it here
    * LLLLLLLLllllllllRRRRRRRRrrrrrrrr
    move.l  (a0,d4.l*4),d4
    * LLLLLLLLllllll00RRRRRRRRrrrrrr00
    and.l   d5,d4
    ror.b   #2,d4
    move.b  d4,(a2)+        * right LSB
    ror.w	#8,d4
    move.b  d4,(a4)+        * right MSB
    swap    d4
    ror.b   #2,d4
    move.b  d4,(a1)+        * left LSB
    ror.w   #8,d4
    move.b  d4,(a3)+        * left MSB

 endr
    dbf     d0,.bob

    pop     d0

.ohi

	movem.l	(sp),a3/a4/a6

.j2	lsr.l	#1,d0
    DPRINT  "play words=%ld"
	movem.l	(a3),a0/a1
	movem.l	16(a3),a2/a3
	bsr.w	playblock_14bit

	popm	a3/a4/a6
	
	bsr.w	wait
	bne.w	quit

	clr.l	samplefollow(a5)
	move.l	16(a3),samplepointer(a5)
	move.l	16+4(a3),samplepointer2(a5)

	movem.l	(a3),d0/d1/d2/d3
	exg	d0,d2
	exg	d1,d3
	movem.l	d0/d1/d2/d3,(a3)

	movem.l	16(a3),d0/d1/d2/d3
	exg	d0,d2
	exg	d1,d3
	movem.l	d0/d1/d2/d3,16(a3)


.loh
	
 if DEBUG
    move.l  d6,d0
    move.l  samplebufsiz(a5),d1
    DPRINT  "last read=%ld buffer=%ld"
 endif

	cmp.l	samplebufsiz(a5),d6
	beq.w	.loopw2

	bsr.w	wait
	bsr.w	songoverr
    * Start from the beginning?
	bra.w	.wl2
	

; -----------------


quit:
	DPRINT	"quit"
	bsr.b	wait
    bsr     mp_stop_streaming
quit2:	
	bsr.w	sampleiik
	lore	Exec,Forbid
	clr	sample_prosessi(a5)
	clr.b	killsample(a5)
	rts

* Wait a short while and check if should exit and clean up.
* Out:
*    Z clear: should stop and quit
*    Z set: should continue playback
wait:
	lore	GFX,WaitTOF
	tst.b	killsample(a5)
	bne.b	.q          * status: Z clear, exit 

    * Test for stop/pause 
	tst.b	samplestop(a5)
	beq.b	.nos
    * Should stop/pause now

	tst.b	ahi(a5)
	beq.b	.screw
    * Stop pause AHI
	bsr.w	ahi_stopsound
	bra.b	.screa
.screw
    * Stop/pause Paula
	move	#$f,$dff096
.screa	
    * Continue waiting, set flag
    st	samplebarf(a5)
	bra.b	wait
.nos
    * Should continue from stopped/paused state

	tst.b	ahi(a5)
	beq.b	.screw2

    * Continue AHI sound 
    bsr.w	ahi_enablesound

	tst.b	ahitrigger(a5)
	beq.b	wait
	clr.b	ahitrigger(a5)
	bra.b	.screa2

.screw2
    * Continue Paula sound
	move	#$800f,$dff096
    * This waits for the next audio interrupt, why?
	move	$dff01e,d0
	and	#$0780,d0
	beq.b	wait
.screa2
    * Clear pause/stopped status flag
	tst.b	samplebarf(a5)
	beq.b	.qw
	clr.b	samplebarf(a5)
	bra.b	wait
.qw

	tst.b	ahi(a5)
	bne.b	.aqq
    * Clear audio interrupt requests
	move	#$0780,$dff09c
.qq	
    * Status: Z set, continue
    moveq	#0,d0
.q	rts

.aqq	clr.b	ahitrigger(a5)
	bra.b	.qq


clrsamplebuf
	tst.b	ahi(a5)
	bne.b	.ozfj
	move	#$f,$dff096
.ozfj

	lea	samplebuffer(a5),a1
.xll	
	move.l	(a1)+,d0
	beq.b	.q
	move.l	d0,a0

	move.l	-4(a0),d0
	subq.l	#4,d0
	lsr.l	#2,d0
.cfd	clr.l	(a0)+
	subq.l	#1,d0
	bne.b	.cfd
	bra.b	.xll
.q	rts

playblock
	push	a4
	lea     $dff0a0,a4
	move.l  a0,(a4)
	move.l  a1,$b0-$a0(a4)
	move.l  a1,$c0-$a0(a4)
	move.l  a0,$d0-$a0(a4)

goa	move    d0,$a4-$a0(a4)
	move    d0,$b4-$a0(a4)
	move    d0,$c4-$a0(a4)
	move    d0,$d4-$a0(a4)
	move    sampleper(a5),d0
	move	d0,$a6-$a0(a4)
	move    d0,$b6-$a0(a4)
	move    d0,$c6-$a0(a4)
	move    d0,$d6-$a0(a4)
	move    #$800f,$96-$a0(a4)
	pop	a4
	rts
	

playblock_14bit
	push	a4
	lea     $dff0a0,a4
	move.l  a0,(a4)
	move.l  a1,$b0-$a0(a4)
	move.l  a3,$c0-$a0(a4)
	move.l  a2,$d0-$a0(a4)
	bra.b	goa

ahiplay
	DPRINT	"ahi_play"
	move	#0,d0		* channel
	move.l	d7,d1		* samplebank	
	moveq	#0,d2		* offset
	move.l	d6,d3		* samples to play
	move.l	ahiflags(a5),d4
	move.l	ahi_ctrl(a5),a2
	move.l	ahibase(a5),a6
	lob	AHI_SetSound
	moveq	#1,d0		* channel
	move.l	d7,d1		* samplebank	
	addq	#1,d1
	moveq	#0,d2		* offset
	move.l	d6,d3		* samples to play
	move.l	ahiflags(a5),d4	* IMMEDIATE vain ekalla kerralla
	clr.l	ahiflags(a5)
	move.l	ahi_ctrl(a5),a2
	lob	AHI_SetSound
	rts

ahiswap	movem.l	(a3),d0/d1/d2/d3
	exg	d0,d2
	exg	d1,d3
	movem.l	d0/d1/d2/d3,(a3)
	eor	#2,d7
	rts



*********************** MP kamoja


* d2 = addr
* d3 = siz

read_mp_mono
	moveq	#-1,d0
	bsr.b	read_mp
	rts

read_mp_stereo

	moveq	#0,d0
	bsr.b	read_mp
	rts

read_mp
	movem.l	d1-a6,-(a7)

;	move.l	d0,d3
	move.l	d2,a3
	move	d0,d6
	bra.b	.is_xpk

.exit	movem.l	(a7)+,d1-a6
	rts

.is_xpk	
	move.l	d3,d7	;len
	moveq	#0,d5	;already read

.xloop	tst.l	d7
	bgt.b	.go_on
.eof	
	move.l	d5,d0
	bra.b	.exit

.go_on	move.l	mpbuffcontent(a5),d0
	ble.b	.read
	sub.l	d0,d7
	bge.b	.copy
	add.l	d0,d7
	move.l	d7,d0
	moveq	#0,d7
.copy	


	move.l	mpbuffpos(a5),d1
	add.l	d0,d5
	add.l	d0,mpbuffpos(a5)
	sub.l	d0,mpbuffcontent(a5)

	lea	mpbuffer1(pc),a0
	lea	mpbuffer2(pc),a1
	add.l	d1,d1
	add.l	d1,a0
	add.l	d1,a1

	subq	#1,d0

	tst	d6
	bne.b	.mono


.co	move	(a0)+,(a3)+
	move	(a1)+,(a3)+
	dbf	d0,.co
	bra.b	.xloop
.mono
	move	(a0)+,(a3)+
	;move	(a1)+,(a3)+
	dbf	d0,.mono
	bra.b	.xloop

.read
	clr.l	mpbuffpos(a5)

	pushm	d1-a6
	move.l	mpstream(a5),a0
	lea	.pcm(pc),a1
	lore	MPEGA,MPEGA_decode
	popm	d1-a6

	move.l	d0,mpbuffcontent(a5)
	bmi.b	.eof
	bra.b	.xloop

.pcm	dc.l	mpbuffer1
	dc.l	mpbuffer2


mp_start
	tst	mplippu(a5)
	beq.b	.x
	tst.l 	_MPEGABase(a5)
	beq.b 	.x
	pushm	all
	move.l	mpstream(a5),a0
	moveq	#0,d0
	lore	MPEGA,MPEGA_seek
	clr.l	mpbuffpos(a5)
	clr.l	mpbuffcontent(a5)

    * Set initial volume for mp3
    move    mainvolume(a5),d0
    bne.b   .y1
    moveq   #$40,d0 
.y1
    bsr     vol


	popm	all
.x	
	rts


mp_close
	pushm	all
    move.l  id3v2Data(a5),a0
    clr.l   id3v2Data(a5)
    bsr     freemem

	tst	mplippu(a5)
	beq.b	.hx
	move.l	mpstream(a5),d0
	beq.b	.hx
	move.l	d0,a0
	lore	MPEGA,MPEGA_close
	clr.l	mpstream(a5)
.hx	popm	all
	rts








************ samplen skaalaus
* sisään:
* d0 = lähdetaajuus
* d1 = kohdetaajuus
* d2 = lähdepituus
* a0 = lähde
* a1 = kohde

* ulos:
* d0 = kohdepituus

truncate:
* max taajuus noin 28600, period 124

	pushm	d1-a6

    moveq	#0,d0
	move	samplefreq(a5),d0
	move.l	#KUTISTUSTAAJUUS,d1

    DPRINT  "resample %ld->%ld in=%ld bytes"

    * source length d2 range is max 128kB
    * calculate target length based on ratio of frequencies
	movem.l	d0/d1,-(sp)
    * mul target frequency by source length
	move.l	d2,d0
	bsr.w	mulu_32
	move.l	(sp),d1
    * divide result by source frequency
	bsr.w	divu_32
	move.l	d0,d7	
	move.l	d7,d6			* kohdepituus
	movem.l	(sp)+,d0/d1

    * Calculate fractional step with 12-bit fractions
    * fffxxxxx.
	lsl.l	#8,d0
    lsl.l	#4,d0
    divu	d1,d0	
	ext.l	d0
	ror.l	#8,d0
	ror.l	#4,d0

    * Fractional index at d2 to zero and clear the x-flag
    sub.l   d2,d2

    ; Do two bytes at a time, this matches with
    ; paula word accuacy
	lsr.l	#1,d7
	subq	#1,d7
	
    * max integer range: 128kB -> 17 bits
    * Mask with one extra bit just to be sure
	move.l	#$0003ffff,d3
.lop
	move.l	d2,d4
	and.l	d3,d4
	move.b	(a0,d4.l),(a1)+
	addx.l	d0,d2

	move.l	d2,d4
	and.l	d3,d4
	move.b	(a0,d4.l),(a1)+
	addx.l	d0,d2

	dbf	d7,.lop

	move.l	d6,d0
    DPRINT  "out=%ld bytes"
	popm	d1-a6
	rts	

songoverr:
	move.l	songover+var_b(pc),a0
	st	(a0)
	rts


closesample
	pushm	all

	tst	mplippu(a5)
	bne.b	.c

	lea	fh1(a5),a0
	bsr.w	_xclose
	lea	fh2(a5),a0
	bsr.w	_xclose

.c	bsr.w	mp_close




;	move.l	samplehandle(a5),d1
;	beq.b	.x
;	lore	Dos,Close
;.x	clr.l	samplehandle(a5)
;	move.l	samplehandle2(a5),d1
;	beq.b	.z
;	lore	Dos,Close
;.z	clr.l	samplehandle2(a5)
	popm	all
	rts



pipefile   dc.b    "PIPE:hipposample",0
    even

mp_start_streaming
    pushm   all
    tst.l   mpStreamerTask(a5)
    bne     .x
    DPRINT  "----------- mp_start_streaming"

    move.l  4.w,a6
    sub.l   a1,a1
    lob     FindTask
    move.l  d0,mainTask(a5)

    moveq   #0,d0
    moveq   #SIGF_SINGLE,d1
    jsr     _LVOSetSignal(a6)

    move.l  #.tags,d1
    lore    Dos,CreateNewProc
    DPRINT  "CrateNewProc=%ld"

    * Wait here until the task is fully running
    move.l  4.w,a6
    moveq   #SIGF_SINGLE,d0
    jsr     _LVOWait(a6)

    DPRINT  "started"
.x
    popm    all
    rts

.tags
    dc.l    NP_Entry,mp_streamer_task
    dc.l    NP_Name,.name
    dc.l    TAG_END

.name   
    dc.b    "HiP-streamer",0
    even

mp_streamer_task

    rsreset
.uhcPathFormatted   rs.b    50
.agetCmdFormatted   rs.b    100
.agetArgsFormatted  rs.b    200
.varsSize           rs.b    0
   
    lea     var_b,a5
    lea     -.varsSize(sp),sp
    move.l  sp,a4

    DPRINT  "mp_streamer_task start"

    move.l  4.w,a6
    sub.l   a1,a1
    lob     FindTask
    move.l  d0,mpStreamerTask(a5)
    move.l  d0,a0
    move.l  LN_NAME(a0),d1
    DPRINT  "%lx %s"
  
    move.l  #.envVarName,d1     * variable name
    pushpea .uhcPathFormatted(a4),d2     * output buffer
    moveq   #50-1,d3            * space available
    move.l  #GVF_GLOBAL_ONLY,d4 * global variable
    lore    Dos,GetVar
    
    pushpea .uhcPathFormatted(a4),d0
    DPRINT  "UHCBIN=%s"

    lea     .agetCmd(pc),a0
    lea     .agetCmdFormatted(a4),a3
    bsr     desmsg2

    pushpea .agetCmdFormatted(a4),d0
    DPRINT  "cmd=%s"

    pushpea .agetCmdFormatted(a4),d1
    lore    Dos,LoadSeg
    move.l  d0,d6
    beq     .exit
    DPRINT  "LoadSeg=%lx"

    move.l	modulefilename(a5),d0
    lea     .args(pc),a0
    lea     .agetArgsFormatted(a4),a3
    bsr     desmsg2
    
    * length of args
    lea     .agetArgsFormatted(a4),a0
    move.l  a0,a1
.fe   
    tst.b   (a0)+
    bne.b   .fe
    move.l  a0,d4
    sub.l   a1,d4
    subq.l  #1,d4   

 ifne DEBUG
    pushpea .agetArgsFormatted(a4),d0
    DPRINT  "args=%s"
    move.l  d4,d0
    DPRINT  "len=%ld"
 endif

    ; Notify main task
    move.l  4.w,a6
    move.l  mainTask(a5),a1
    moveq   #SIGF_SINGLE,d0
    jsr     _LVOSignal(a6)

    move.l  d6,d1       * seglist
    move.l  #4096,d2    * stack size
    pushpea .agetArgsFormatted(a4),d3 * argptr
                          * d4 = arg size
    lore    Dos,RunCommand
    DPRINT  "runCommand=%lx"
    
    move.l  d6,d1
    beq.b   .a
    lore    Dos,UnLoadSeg
.a

.exit
    DPRINT  "mp_streamer_task stopped"

    lea     .varsSize(sp),sp
    lore    Exec,Forbid
    clr.l   mpStreamerTask(a5)
    rts

.envVarName
    dc.b    "UHCBIN",0

.agetCmd
    dc.b	'%sC/aget',0

.args
	dc.b	'"%s" PIPE:hipposample/65536/2',0

.tags
    dc.l    NP_Name,.name
    dc.l    TAG_END

.name   dc.b    "HiP-aget",0
    even

mp_stop_streaming
    tst.l   mpStreamerTask(a5)
    beq    .1
    DPRINT  "--------------- mp_stop_streaming"
    bsr     mp_close

    move.l  mpStreamerTask(a5),a1
    move.l  #SIGBREAKF_CTRL_C,d0
    move.l  4.w,a6
    lob     Signal 
 
    DPRINT  "signal sent"

    move.l  #pipefile,d1
    move.l  #MODE_OLDFILE,d2
    lore    Dos,Open
    DPRINT  "Pipe=%lx"
    move.l  d0,d7

    * Wait until read fails, this indicates
    * the sender has reacted to CTRL_C
    moveq   #0,d6
    moveq   #0,d5
.loop   
    tst.l   d5
    bmi.b   .skip
    move.l  d7,d1
    lore    Dos,FGetC
    addq.l  #1,d6
    move.l  d0,d5
    bra     .cont
.skip  
    moveq   #1,d1
    lore    Dos,Delay
.cont
    tst.l   mpStreamerTask(a5)
    bne.b   .loop

 if DEBUG
    move.l  d6,d0
    DPRINT  "task closed, flushed %ld bytes" 
 endif
   
.1
    move.l  d7,d1
    beq.b   .2
    lore    Dos,Close
.2
    DPRINT  "mp streaming stopped"
    rts





initsamplecyber
	moveq	#1,d0
	tst.b	samplecyberset(a5)
	beq.b	.nocy
	tst.l	calibrationaddr(a5)
	beq.b	.nocy

	move.l	#$20000,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	bsr.w	getmem
	move.l	d0,samplecyber(a5)
	beq.b	.nocy


	move.l	d0,a0
	move.l	calibrationaddr(a5),a1
	bsr.b	_CreateTable
	moveq	#1,d0

.nocy	tst.l	d0
	rts





*****************************************************************************
*
* CyberSound: 14 Bit sound driver
*
* (c) 1995 by Christian Buchner
*
*****************************************************************************
*
* _CreateTable **************************************************************

		; Parameters

		; a0 = Table address
		; (MUST have enough space for 65536 UWORDS)
		; a1 = Additive Array
		; 256 UBYTEs
		;
		; the table is organized as follows:
		; 32768 UWORDS positive range, ascending order
		; 32768 UWORDS negative range, ascending order
		; access: (a0,d0.l*2)
		; where d0.w is signed word sample data
		; and the upper word of d0.l is *cleared!*


_CreateTable	movem.l	a2/d2-d6,-(sp)

		lea	128(a1),a2

		move.l	a2,a1			; count the number of steps
		moveq	#128-1,d0		; in the positive range
		moveq	#0,d5
.countpositive	move.b	(a1)+,d1
		ext.w	d1
		ext.l	d1
		add.l	d1,d5
		dbra	d0,.countpositive	; d5=number of steps
		move.l	#32768,d6		; reset stretch counter
		
		move.l	a2,a1			; middle value in calibdata
		move.w	#32768-1,d0		; number of positive values -1
		moveq	#0,d1			; HI value
		moveq	#0,d2			; LO value
		moveq	#0,d3			; counter
.fetchnext2	move.b	(a1)+,d4		; add calibtable to counter
		ext.w	d4
		add.w	d4,d3
.outerloop2	tst.w	d3
		bgt.s	.positive2
.negative2	addq.w	#1,d1			; increment HI value
		sub.w	d4,d2			; reset LO value
		bra.s	.fetchnext2
.positive2	move.b	d1,(a0)+		; store HI and LO value
		move.b	d2,(a0)+
		sub.l	d5,d6			; stretch the table
		bpl.s	.repeat2		; to 32768 entries
		add.l	#32768,d6
		addq.w	#1,d2			; increment LO value
		subq.w	#1,d3			; decrement counter
.repeat2	dbra	d0,.outerloop2

		move.l	a2,a1			; count the number of steps
		moveq	#128-1,d0		; in the negative range
		moveq	#0,d5
.countnegative	move.b	-(a1),d1
		ext.w	d1
		ext.l	d1
		add.l	d1,d5
		dbra	d0,.countnegative	; d5=number of steps
		move.l	#32768,d6		; reset stretch counter
		
		add.l	#2*32768,a0		; place at the end of the table
		move.l	a2,a1			; middle value in calibdata
		move.w	#32768-1,d0		; number of negative values -1
		moveq	#-1,d1			; HI value
		moveq	#-1,d2			; LO value
		moveq	#0,d3			; counter
.fetchnext1	move.b	-(a1),d4		; add calibtable to counter
		ext.w	d4
		add.w	d4,d3
		add.w	d4,d2			; maximize LO value
.outerloop1	tst.w	d3
		bgt.s	.positive1
.negative1	subq.w	#1,d1
		bra.s	.fetchnext1
.positive1	move.b	d2,-(a0)		; store LO and HI value
		move.b	d1,-(a0)
		sub.l	d5,d6			; stretch the table
		bpl.s	.repeat1		; to 32768 entries
		add.l	#32768,d6
		subq.w	#1,d2			; decrement lo value
		subq.w	#1,d3			; decrement counter
.repeat1	dbra	d0,.outerloop1

		movem.l	(sp)+,a2/d2-d6
		rts


*******
* d0=koko
* d1=tyyppi
getmem	movem.l	d1/d3/a0/a1/a6,-(sp)
	addq.l	#4,d0
	move.l	d0,d3
	move.l	4.w,a6
	lob	AllocMem
	tst.l	d0
	beq.b	.err
	move.l	d0,a0
	move.l	d3,(a0)+
	move.l	a0,d0
.err	movem.l	(sp)+,d1/d3/a0/a1/a6
	rts

* a0=osoite
freemem	movem.l	d0/d1/a0/a1/a6,-(sp)
	move.l	a0,d0
	beq.b	.n
	move.l	-(a0),d0
	move.l	a0,a1
	move.l	4.w,a6
	lob	FreeMem
.n	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts

*******
* Search
*******
* a1 = etsittävä
* a4 = mistä etsitään
* d0 = etsittävän pituus


search
	move.l	#2048,d2
	cmp.l	d7,d2
	blo.b	sea
	move.l	d7,d2		
sea	lea	(a4,d2.l),a3	 * Etsitään kaksi kilotavua tai modin pituus

	move	d0,d2
	subq	#2,d2
	move.l	a4,a0
	move.b	(a1)+,d0
.moh	move.l	a1,a2
.findi	
	cmp.l	a3,a0
	bhs.b	.eieh
	cmp.b	(a0)+,d0
	bne.b	.findi

	move	d2,d1
.fid	cmpm.b	(a2)+,(a0)+
	dbne	d1,.fid
	beq.b	.yeah

.fof	cmp.l	a3,a0
	blo.b	.moh
.eieh	moveq	#-1,d0
	rts
.yeah	moveq	#0,d0
	rts


*******************************************************************************
* Merkkijonon muotoilu
*******
desmsg2:
    	movem.l	d0-d7/a0-a3/a6,-(sp)
	    ;lea	desbuf(a5),a3	;puskuri
        bra     desmsg0

desmsg:
	movem.l	d0-d7/a0-a3/a6,-(sp)
	lea	desbuf(a5),a3	;puskuri
desmsg0
	move.l	sp,a1		* parametrit ovat täällä!
	lea	.putc(pc),a2	;merkkien siirto
	move.l	(a5),a6
	lob	RawDoFmt
	movem.l	(sp)+,d0-d7/a0-a3/a6
	rts
.putc	move.b	d0,(a3)+	
	rts


clearsound
	tst.b	ahi(a5)
	bne.b	.x

	pushm	d0/a0
	lea	$dff096,a0
	move	#$f,(a0)
	moveq	#0,d0
	move	d0,$a8-$96(a0)
	move	d0,$b8-$96(a0)
	move	d0,$c8-$96(a0)
	move	d0,$d8-$96(a0)
	popm	d0/a0
.x	rts

varaa_kanavat
	tst.b	ahi(a5)
	bne.b	.x
	move.l	varaa+var_b(pc),-(sp)
	rts
.x	moveq	#0,d0
	rts
	
vapauta_kanavat
	tst.b	ahi(a5)
	bne.b	.x
	move.l	vapauta+var_b(pc),-(sp)
.x	rts


* mulu_32 --- d0 = d0*d1
mulu_32	movem.l	d2/d3,-(sp)
	move.l	d0,d2
	move.l	d1,d3
	swap	d2
	swap	d3
	mulu	d1,d2
	mulu	d0,d3
	mulu	d1,d0
	add	d3,d2
	swap	d2
	clr	d2
	add.l	d2,d0
	movem.l	(sp)+,d2/d3
	rts	

* divu_32 --- d0 = d0/d1, d1=jakojäännös
divu_32	move.l	d3,-(a7)
	swap	d1
	tst	d1
	bne.b	.lb_5f8c
	swap	d1
	move.l	d1,d3
	swap	d0
	move	d0,d3
	beq.b	.lb_5f7c
	divu	d1,d3
	move	d3,d0
.lb_5f7c	swap	d0
	move	d0,d3
	divu	d1,d3
	move	d3,d0
	swap	d3
	move	d3,d1
	move.l	(a7)+,d3
	rts	

.lb_5f8c	swap	d1
	move	d2,-(a7)
	moveq	#16-1,d3
	move	d3,d2
	move.l	d1,d3
	move.l	d0,d1
	clr	d1
	swap	d1
	swap	d0
	clr	d0
.lb_5fa0	add.l	d0,d0
	addx.l	d1,d1
	cmp.l	d1,d3
	bhi.b	.lb_5fac
	sub.l	d3,d1
	addq	#1,d0
.lb_5fac	dbf	d2,.lb_5fa0
	move	(a7)+,d2
	move.l	(a7)+,d3
	rts	



*****************************



;***_XOpen**********************************************************
; parameters:
;  a0 - myFH (mfh_filename must have been initialized!)
; result:
;  d0 - 0=OK, other=ERROR
; 
; -DOSBase must be valid
; -if file starts with "XPKF" and XPKBase=NULL
;    -> result=-2 -> call _XOpen again when xpkmaster.library was opened
_xopen
	movem.l	d1-a6,-(a7)
	move.l	a0,a5

	moveq	#mfh_SIZEOF-5,d0	;don't clear mfh_filename !!
.clrloo	clr.b	(a0)+
	dbf	d0,.clrloo

;	move.l	(loadall,pc),d0
;	beq.b	.notloadall
;	move.l	(loadallvec,pc),a0
;	cmp.l	#"XPKF",(a0)
;	beq.b	.xla
;	bra.w	.end_ok
;.notloadall

	move.l	(mfh_filename,a5),d1
	move.l	#MODE_OLDFILE,d2

	move.l	_DosBase+var_b,a6
	lob	Open

	move.l	d0,(a5)
	bne.b	.open_ok
	moveq	#-1,d0			;-1=DOS_OPEN_ERROR
	bra.w	.exit
.open_ok
	move.l	d0,d1
	lea	(.xpkf_test,pc),a0
	move.l	a0,d2
	moveq	#4,d3

	move.l	_DosBase+var_b,a6
	lob	Read

	move.l	(.xpkf_test,pc),d0
	cmp.l	#"XPKF",d0
	beq.b	.is_xpk
	move.l	(a5),d1
	moveq	#0,d2
	moveq	#OFFSET_BEGINNING,d3

	move.l	_DosBase+var_b,a6
	lob	Seek

	bra.b	.end_ok

.is_xpk
	move.l	(a5),d1

	move.l	_DosBase+var_b,a6
	lob	Close

	clr.l	(a5)
.xla	move.l	(_XPKBase+var_b),d0
	bne.b	.xpklib_ok
	moveq	#-2,d0			;-2=XPKMASTER_NOT_OPEN
	bra.b	.exit
.xpklib_ok
	move.l	d0,a6
	move.l	a5,a0
	lea	(xpkopentags,pc),a1
;	tst.l	(loadall,a4)
;	bne.b	.la
	move.l	(mfh_filename,a5),(4,a1)
.la	
	move.l	_XPKBase+var_b,a6
	lob	XpkOpen

	move.l	d0,(xpk_error)
	beq.b	.xpkopen_ok
	moveq	#-3,d0			;-3=XPK_ERROR
	bra.b	.exit
.xpkopen_ok
	st	(mfh_is_xpk,a5)
	move.l	(a5),a0
	move.l	(xf_NLen,a0),d0
	move.l	d0,(mfh_xbuffsize,a5)
	add.l	#XPK_MARGIN,d0
	moveq	#0,d1
	bsr.w	getmem
	move.l	d0,(mfh_xbuff,a5)
	bne.b	.end_ok
	moveq	#-4,d0			;-4=MEM_ERROR
	bra.b	.exit

.end_ok	moveq	#0,d0
.exit	movem.l	(a7)+,d1-a6
	tst.l	d0
	rts

.xpkf_test	dc.l	0
xpkopentags	dc.l	XPK_InName,0	;to be patched!
		dc.l	XPK_GetError,xpkerrormsg
		dc.l	XPK_ShortError,-1
xot_inlen	dc.l	0,0,0


xpk_error	dc.l	0
xpkerrormsg	ds.b	82


;***_XRead**********************************************************
; parameters:
;  a0 - myFH
;  d2 - buffer
;  d3 - len
; result:
;  d0 - bytes read (0=EOF, <0=ERROR)
_xread
	movem.l	d1-a6,-(a7)
	move.l	a0,a5		;myFH
	tst	(mfh_is_xpk,a5)
	bne.b	.is_xpk

;	move.l	(loadall,pc),d0
;	beq.b	.nla
;	move.l	(mfh_filepos,a5),a0
;	add.l	(loadallvec,pc),a0
;	move.l	d2,a1
;	move.l	d3,d0
;	add.l	d0,(mfh_filepos,a5)
;	move.l	4.w,a6
;	lob	CopyMem
;	move.l	d3,d0
;	bra.b	.exit

.nla	move.l	(a0),d1		;mfh_fh
	move.l	_DosBase+var_b,a6
	lob	Read
.exit	movem.l	(a7)+,d1-a6
	rts
.is_xpk	move.l	d2,d6	;buf
	move.l	d3,d7	;len
	moveq	#0,d5	;already read
.xloop	tst.l	d7
	bgt.b	.go_on
.eof	move.l	d5,d0
	add.l	d0,(mfh_filepos,a5)
	bra.b	.exit
.go_on	move.l	(mfh_buffcontent,a5),d0
	ble.b	.read
	sub.l	d0,d7
	bge.b	.copy
	add.l	d0,d7
	move.l	d7,d0
	moveq	#0,d7
.copy	move.l	(mfh_buffpos,a5),a0
	move.l	d6,a1
	add.l	d0,d5
	add.l	d0,(mfh_buffpos,a5)
	add.l	d0,d6
	sub.l	d0,(mfh_buffcontent,a5)
	move.l	4.w,a6
	lob	CopyMem
	bra.b	.xloop
.read	move.l	(a5),a0		;mfh_fh
	move.l	(mfh_xbuff,a5),a1
	move.l	a1,(mfh_buffpos,a5)
	move.l	(mfh_xbuffsize,a5),d0
	move.l	_XPKBase+var_b,a6
	lob	XpkRead
	move.l	d0,(mfh_buffcontent,a5)
	beq.b	.eof
	bgt.b	.xloop
	move.l	d0,(xpk_error)
	bra.b	.exit


;***_XSeek**********************************************************
; parameters:
;  a0 - myFH
;  d2 - newpos (only positive numbers (forward seeking) supported)
;  d3 - offset (only OFFSET_BEGINNING and OFFSET_CURRENT supported)
; result:
;  d0 - oldpos (<0=ERROR)
_xseek
	movem.l	d1-a6,-(a7)
	move.l	a0,a5			;myFH
	tst	(mfh_is_xpk,a5)
	bne.b	.is_xpk

;	move.l	(loadall,pc),d0
;	beq.b	.nla

;	move.l	(mfh_filepos,a5),d0	;oldpos
;	tst.l	d3
;	beq.b	.offcur
;	clr.l	(mfh_filepos,a5)
;.offcur	add.l	d2,(mfh_filepos,a5)
;	bra.b	.exit

.nla	move.l	(a5),d1
	move.l	_DosBase+var_b,a6
	lob	Seek
.exit	movem.l	(a7)+,d1-a6
	rts
.is_xpk	move.l	d2,d6			;newpos
	move.l	(mfh_filepos,a5),d7	;oldpos
	tst.l	d3			;offset
	beq.b	.seek_loop		;OFFSET_CURRENT

	move.l	(a5),a0
	move.l	_XPKBase+var_b,a6
	lob	XpkClose
	clr.l	(a5)
	clr.l	(mfh_filepos,a5)
	clr.l	(mfh_buffcontent,a5)
	move.l	a5,a0
	lea	(xpkopentags,pc),a1

;	tst.l	(loadall,a4)
;	bne.b	.la
	move.l	(mfh_filename,a5),(4,a1)
.la	
	move.l	_XPKBase+var_b,a6
	lob	XpkOpen			;"seek" to beginning
	move.l	d0,(xpk_error)
	beq.b	.seek_loop
	moveq	#-1,d0			;ERROR
	bra.b	.exit
.seek_loop
	tst.l	d6			;newpos
	bgt.b	.do_seek
	move.l	d7,d0			;return old position
	bra.b	.exit
.do_seek
	move.l	(mfh_buffcontent,a5),d0
	ble.b	.read
	cmp.l	d6,d0
	bmi.b	.not_enough
	sub.l	d6,(mfh_buffcontent,a5)
	add.l	d6,(mfh_buffpos,a5)
	add.l	d6,(mfh_filepos,a5)
	moveq	#0,d6
	bra.b	.seek_loop
.not_enough
	sub.l	d0,d6
	add.l	d0,(mfh_filepos,a5)
.read
	move.l	(a5),a0
	move.l	(mfh_xbuff,a5),a1
	move.l	a1,(mfh_buffpos,a5)
	move.l	(mfh_xbuffsize,a5),d0

	move.l	_XPKBase+var_b,a6
	lob	XpkRead
	move.l	d0,(mfh_buffcontent,a5)
	beq.b	.eof
	bgt.b	.seek_loop
	move.l	d0,(xpk_error)
	bra.w	.exit
.eof	moveq	#-1,d0			;ERROR (EOF)
	bra.w	.exit



;***_XClose*********************************************************
; parameters:
;  a0 - myFH (should be safe to call several times unlike DOS/Close()!!)
_xclose
	movem.l	d1-a6,-(a7)
	move.l	a0,a5

	move.l	(a5),d1
	beq.b	.no_fh
	clr.l	(a5)
	tst	(mfh_is_xpk,a5)
	bne.b	.is_xpk
	move.l	_DosBase+var_b,a6
	lob	Close
	bra.b	.no_fh
.is_xpk	move.l	(_XPKBase+var_b),d0
	beq.b	.no_fh
	move.l	d0,a6
	move.l	d1,a0
	lob	XpkClose
.no_fh
	lea	(mfh_xbuff,a5),a0
	move.l	(a0),d0
	beq.b	.no_xbuff
	clr.l	(a0)
	move.l	d0,a0
	bsr.w	freemem
.no_xbuff
	movem.l	(a7)+,d1-a6
	rts

*********************************************************************
*
* ID3v2 tag handling
*
*********************************************************************

* In: 
*   d0 = file handle when it is a stream
mpega_skip_id3v2_stream
    pushm   all
	move.l	d0,d6

    move.l  id3v2Data(a5),a0
    clr.l   id3v2Data(a5)
    bsr     freemem

	lea	findSyncBuffer(pc),a3
	move.l	d6,d1
	move.l	a3,d2
	* Read 10 bytes, the size of the ID3v2 header
	moveq	#10,d3
	move.l	_DosBase(a5),a6
	lob	Read
	tst.l	d0
	beq 	.mpega_skip_exit_stream

	* Is it a ID3v2 header?
	move.l	(a3),d0
	lsr.l	#8,d0
	cmp.l	#"ID3",d0
	bne 	.mpega_skip_exit_stream

	* Get size, synchsafe integer, 4x 7-bit bytes
    lea     6(a3),a0
    bsr     get_syncsafe_integer
    DPRINT  "ID3 header length=%ld"
    move.l  d0,d3
    beq.b   .mpega_skip_exit_stream

    * Grab data into a buffer
    move.l  d3,d0
    addq.l  #8,d0 * add some extra for safety
    moveq   #MEMF_PUBLIC,d1    
    bsr     getmem
    move.l  d0,id3v2Data(a5)
    move.l  d0,a3

    * d3 is the amount of data to skip now
    move.l  d3,d0
    add.l   #10,d0
    move.l  d0,mpega_sync_position(a5)
.skipLoop
	move.l	d6,d1
    lob     FGetC
    * d0 = 0-255 or -1 if error
    tst.l   d0
    bmi     .skipError
    cmp.w   #0,a3
    beq.b   .s1
    move.b  d0,(a3)+
.s1
    subq.l  #1,d3
    bne.b   .skipLoop
   
.skipError
 if DEBUG   
    move.l  d3,d0
    DPRINT  "Not skipped: %ld"
 endif
.mpega_skip_exit_stream
    popm    all
	rts



* Out:
*   d0 = non-zero: has text, zero: no text
hasMp3TagText:
    lea     var_b,a0
    move.l  id3v2Data(a0),d0
    DPRINT  "hasMp3TagText=%lx "
    rts

ILF	=	$83
ILF2	=	$03

* In:
*   a0 = info window text buffer
getMp3TagText:
    pushm   all
    lea     var_b,a5
    move.l  a0,a2
    bsr     mpega_parse_id3v2
    popm    all
    rts
    

* In:
*  a2 = info window text buffer
mpega_parse_id3v2
    pushm   all
    tst.l   id3v2Data(a5)
    beq     .xit
    move.l  id3v2Data(a5),a3
    moveq   #0,d0
    move.b  findSyncBuffer+3,d0
    DPRINT  "parse ID3v2, version=%ld"
    cmp.b   #3,d0
    blo     .xit

    * End pointer to a4
    move.l  a3,a4
    add.l   -4(a3),a4

    * Check flags from header read earlier
    move.b  findSyncBuffer+5,d7

    move.l  #$80,d0
    and.b   d7,d0
    DPRINT  "Sync: %lx"
    tst.b   d0
    bne     .xit
    move.l  #$40,d0
    and.b   d7,d0
    DPRINT  "Extended hdr: %lx"
    tst.b    d0
    beq     .p1
    bsr     get_syncsafe_integer
    DPRINT  "Extended header size: %ld"
    add.l   d0,a3
.p1

    * Frame size is 10 bytes, end bound
    lea     -10(a4),a4

    lea     .titleFormat(pc),a0
    bsr     appendWithFormat
    
    move.l  #"TPE1",d0
    lea     .tpe1Format(pc),a0
    bsr     findAndAppendWithFormat
    move.l  #"TPE2",d0
    lea     .tpe2Format(pc),a0
    bsr     findAndAppendWithFormat
    move.l  #"TPE3",d0
    lea     .tpe3Format(pc),a0
    bsr     findAndAppendWithFormat
    move.l  #"TPE4",d0
    lea     .tpe4Format(pc),a0
    bsr     findAndAppendWithFormat
    move.l  #"TCOM",d0
    lea     .tcomFormat(pc),a0
    bsr     findAndAppendWithFormat
    move.l  #"TOPE",d0
    lea     .topeFormat(pc),a0
    bsr     findAndAppendWithFormat
    move.l  #"TIT1",d0
    lea     .tit1Format(pc),a0
    bsr     findAndAppendWithFormat

    move.l  #"TIT2",d0
    lea     .tit2Format(pc),a0
    bsr     findAndAppendWithFormat

    move.l  #"TIT2",d0
    bsr     findFrameByName
    beq.b   .11
    move.l  d0,a0
    bsr     appendWithWrap
.11
 
    move.l  #"TIT3",d0
    lea     .tit3Format(pc),a0
    bsr     findAndAppendWithFormat
    move.l  #"TALB",d0
    lea     .talbFormat(pc),a0
    bsr     findAndAppendWithFormat
    move.l  #"TYER",d0
    lea     .tyerFormat(pc),a0
    bsr     findAndAppendWithFormat
    move.l  #"TDAT",d0
    lea     .tdatFormat(pc),a0
    bsr     findAndAppendWithFormat
    move.l  #"TDRC",d0
    lea     .tdrcFormat(pc),a0
    bsr     findAndAppendWithFormat
    move.l  #"TDRL",d0
    lea     .tdrlFormat(pc),a0
    bsr     findAndAppendWithFormat
    move.l  #"TRCK",d0
    lea     .trckFormat(pc),a0
    bsr     findAndAppendWithFormat

    move.l  #"TLEN",d0
    bsr     findFrameByName
    beq.b   .1
    bsr     convertMsString
    lea     .tlenFormat(pc),a0
    bsr     appendWithFormat
.1

    move.l  #"TMOO",d0
    lea     .tmooFormat(pc),a0
    bsr     findAndAppendWithFormat
    move.l  #"TRSN",d0
    lea     .trsnFormat(pc),a0
    bsr     findAndAppendWithFormat
    
.xit
    popm    all
    rts

.titleFormat
    dc.b    ILF,ILF2
    dc.b    " --- MP3 info ---",ILF,ILF2,ILF,ILF2,0
.tpe1Format
    dc.b    " Artist:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.tpe2Format
    dc.b    " Band:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.tpe3Format
    dc.b    " Conductor:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.tpe4Format
    dc.b    " Remixed by:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.tcomFormat
    dc.b    " Composer:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.topeFormat
    dc.b    " Original artist:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.tit1Format
    dc.b    " Content:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
;.tit2Format
;    dc.b    " Title:",ILF,ILF2
;    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.tit2Format
    dc.b    " Title:",ILF,ILF2,0
.tit3Format
    dc.b    " Subtitle:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.talbFormat
    dc.b    " Album:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.tyerFormat
    dc.b    " Year:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.tdatFormat
    dc.b    " Date:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.tdrcFormat
    dc.b    " Recording time:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.tdrlFormat
    dc.b    " Release time:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.trckFormat
    dc.b    " Track number:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.tlenFormat
    dc.b    " Length:",ILF,ILF2
    dc.b    " %ld:%02ld",ILF,ILF2,ILF,ILF2,0
.tmooFormat
    dc.b    " Mood:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0
.trsnFormat
    dc.b    " Radio station:",ILF,ILF2
    dc.b    " %-37.37s",ILF,ILF2,ILF,ILF2,0

 even

* In:
*   d0 = frame name 4-cbar
*   a0 = format string
*   a2 = buffer to append
findAndAppendWithFormat
    bsr     findFrameByName
    bne.b   .1
    rts
.1
appendWithFormat:
    bsr     desmsg
    lea     desbuf(a5),a0
.cc move.b  (a0)+,(a2)+
    bne     .cc
    subq    #1,a2
    rts

* In:
*   a0 =  string
*   a2 = buffer to append
appendWithWrap:
    pushm   d0-a1/a3-a6
    move.l  a2,a3
    move.b  #" ",(a3)+
    bsr     .doLine
    bpl     .ends
    move.b  #" ",(a3)+
    bsr     .doLine
    bpl     .ends
    move.b  #" ",(a3)+
    bsr     .doLine
.ends
    move.l  a3,a2
    popm    d0-a1/a3-a6
    rts


* Copies a line to output, cuts at space near the end of line
* in:
*   a0 = input text
*   a3 = output buffer
* out:
*   a0 = pointer to next line if available
*   a3 = pointer to next position in output buffer
*   d0 = negative: all input handled
*        positive: data left in input for the next row
.doLine
    move.l  a0,d0
	moveq	#37-1,d0
	moveq	#0,d1
.cl1
    cmp.b   #"_",(a0)
    beq     .ys1
    cmp.b	#" ",(a0)
	bne.b	.ns1
.ys1
	addq	#1,d1 ; keep track of spaces
.ns1	    
    move.b	(a0)+,(a3)+
	dbeq	d0,.cl1
	tst	d0
	bpl.b	.endLine
	; find previous space to cut from
	; SAFETY: if there are any
	tst	d1
	beq.b	.endLin
.li1	
    subq	#1,a3
    cmp.b   #"_",-(a0)
    beq     .ys2
	cmp.b	#" ",(a0)
	bne.b	.li1
.ys2
	addq	#1,a0
	move.l	a0,d0
.endLin
	moveq	#-1,d0
.endLine
	bsr.w	.putLineChange
	tst	d0
	rts

; Put line change with special line feed so that ordinary line feeds
; can be filtered out.
.putLineChange	
	move.b	#ILF,(a3)+
	move.b	#ILF2,(a3)+
	rts
* In: 
*    d0 = 4-char frame name to find
*    a3 = start of data
*    a4 = end of data
* Out:
*    d0 = NULL or pointer to frame text
findFrameByName
    pushm   d1-a6
    moveq   #0,d7    
    move.l  d0,d6
.loop
    cmp.b   #"A",(a3)
    blo     .xit    
    cmp.b   #"Z",(a3)
    bhi     .xit    
    
    move.b  (a3),d2
    rol.l   #8,d2
    move.b  1(a3),d2
    rol.l   #8,d2
    move.b  2(a3),d2
    rol.l   #8,d2
    move.b  3(a3),d2
    lea     4(a3),a0
    bsr     get_syncsafe_integer
    move.l  d0,d1

    * Overflow check
    move.l  a3,d0
    add.l   d1,d0
    
    cmp.l   a4,d0
    bhs     .xit

    cmp.l   d2,d6
    bne     .next

    * Frame data start
    lea     10(a3),a0
    bsr     getFrameText
    bne.b   .found 
.next
    * Skip over the frame header + frame to the next one
    lea     10(a3,d1.l),a3

    cmp.l   a4,a3
    blo     .loop
.xit
    moveq   #0,d0
.x
    popm    d1-a6
    rts

.found
    pushpea textBuffer(a5),d0
    bra     .x

;; Encoding:
;; $00   ISO-8859-1 [ISO-8859-1]. Terminated with $00.
;; $01   UTF-16 [UTF-16] encoded Unicode [UNICODE] with BOM. All
;;       strings in the same frame SHALL have the same byteorder.
;;       Terminated with $00 00.
;; $02   UTF-16BE [UTF-16] encoded Unicode [UNICODE] without BOM.
;;       Terminated with $00 00.
;; $03   UTF-8
 



* in:
*    a0 = data
*    d1 = len
getFrameText
    pushm   d1-a6
    clr.b   textBuffer(a5)
    * check length
    cmp.l   #2,d1
    blo     .x

    * check encoding
    moveq   #0,d2
    move.b  (a0)+,d2
    cmp.b   #0,d2
    beq.b   .ok
    cmp.b   #3,d2
    bne     .x
.ok
    lea     textBuffer(a5),a1
    * Limit of chars on one line in infowindow is 40
    moveq   #3*40-1,d2

    * subtract char encoding and one for dbcc
    subq.l  #1+1,d1
.c1 move.b  (a0)+,(a1)+
    subq    #1,d2
    dbeq    d1,.c1
    clr.b   (a1)
    moveq   #1,d0
    bra.b   .y
.x
    moveq   #0,d0
.y
    popm   d1-a6
    rts


* in:
*   a0 = data
get_syncsafe_integer:
	* Get size, synchsafe integer, 4x 7-bit bytes
	moveq	#0,d0
	or.b	(a0),d0
	lsl.l	#7,d0
	or.b	1(a0),d0
	lsl.l	#7,d0
	or.b	2(a0),d0
	lsl.l	#7,d0
	or.b	3(a0),d0
    rts


* in:
*   a0 = string with milliseconds as text
* out:
*   d0 = seconds
*   d1 = minutes
convertMsString:
    moveq   #0,d0
    move.l  a0,a1
.1
    tst.b   (a1)+
    bne     .1
    subq    #1,a1

    moveq   #1,d2
.loop
    cmp.l   a0,a1
    beq     .x
    moveq   #$f,d3
    and.b   -(a1),d3

    mulu.l  d2,d3
    add.l   d3,d0
    mulu.l  #10,d2
    bra     .loop
.x
    divu.l  #1000,d0
    divul.l #60,d1:d0
    rts


 if DEBUG
PRINTOUT_DEBUGBUFFER
	pea	debugDesBuf+var_b 
	bsr.b PRINTOUT
	rts

PRINTOUT
	pushm	d0-d3/a0/a1/a5/a6
	lea	var_b,a5
	move.l	output(a5),d1
	bne.b	.open

	* try tall window firsr
	move.l	#.bmb,d1
	move.l	#MODE_NEWFILE,d2
	lore	Dos,Open
	move.l	d0,output(a5)
	bne.b	.open
	* smaller next
	move.l	#.bmbSmall,d1
	move.l	#MODE_NEWFILE,d2
	lob	Open
	move.l	d0,output(a5)
	bne.b	.open
	* still not open! exit
	bra.b	.x

.bmb	dc.b	"CON:20/10/350/490/HiP sample debug",0
.bmbSmall
	dc.b	"CON:20/10/350/190/HiP sample debug",0
    even
.open
	move.l	32+4(sp),a0

	moveq	#0,d3
	move.l	a0,d2
.p	addq	#1,d3
	tst.b	(a0)+
	bne.b	.p
 	lore	Dos,Write
.x	popm	d0-d3/a0/a1/a5/a6
	move.l	(sp)+,(sp)
	rts
 
desmsgDebugAndPrint
	* sp contains the return address, which is
	* the string to print
	movem.l	d0-d7/a0-a3/a6,-(sp)
	* get string
	move.l	4*(8+4+1)(sp),a0
	* find end of string
	move.l	a0,a1
.e	tst.b	(a1)+
	bne.b	.e
	move.l	a1,d7
	btst	#0,d7
	beq.b	.even
	addq.l	#1,d7
.even
	* overwrite return address 
	* for RTS to be just after the string
	move.l	d7,4*(8+4+1)(sp)

	lea	debugDesBuf+var_b,a3
	move.l	sp,a1	
	lea	.putc(pc),a2	
	move.l	4.w,a6
	lob	RawDoFmt
	movem.l	(sp)+,d0-d7/a0-a3/a6
	bsr.w	PRINTOUT_DEBUGBUFFER
	rts	* teleport!
.putc	
	move.b	d0,(a3)+	
	rts
 endif

var_b	ds.b	size_var

findSyncBuffer
            ds.b    10
mpbuffer1	ds	MPEGA_PCM_SIZE
mpbuffer2	ds	MPEGA_PCM_SIZE
