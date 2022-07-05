;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
;; /*      fix_fft.c - Fixed-point Fast Fourier Transform  */
;; /*
;;         fix_fft()       perform FFT or inverse FFT
;;         window()        applies a Hanning window to the (time) input
;;         fix_loud()      calculates the loudness of the signal, for
;;                         each freq point. Result is an integer array,
;;                         units are dB (values will be negative).
;;         iscale()        scale an integer value by (numer/denom).
;;         fix_mpy()       perform fixed-point multiplication.
;;         Sinewave[1024]  sinewave normalized to 32767 (= 1.0).
;;         Loudampl[100]   Amplitudes for lopudnesses from 0 to -99 dB.
;;         Low_pass        Low-pass filter, cutoff at sample_freq / 4.


;;         All data are fixed-point short integers, in which
;;         -32768 to +32768 represent -1.0 to +1.0. Integer arithmetic
;;         is used for speed, instead of the more natural floating-point.

;;         For the forward FFT (time -> freq), fixed scaling is
;;         performed to prevent arithmetic overflow, and to map a 0dB
;;         sine/cosine wave (i.e. amplitude = 32767) to two -6dB freq
;;         coefficients; the one in the lower half is reported as 0dB
;;         by fix_loud(). The return value is always 0.

;;         For the inverse FFT (freq -> time), fixed scaling cannot be
;;         done, as two 0dB coefficients would sum to a peak amplitude of
;;         64K, overflowing the 32k range of the fixed-point integers.
;;         Thus, the fix_fft() routine performs variable scaling, and
;;         returns a value which is the number of bits LEFT by which
;;         the output must be shifted to get the actual amplitude
;;         (i.e. if fix_fft() returns 3, each value of fr[] and fi[]
;;         must be multiplied by 8 (2**3) for proper scaling.
;;         Clearly, this cannot be done within the fixed-point short
;;         integers. In practice, if the result is to be used as a
;;         filter, the scale_shift can usually be ignored, as the
;;         result will be approximately correctly normalized as is.


;;         TURBO C, any memory model; uses inline assembly for speed
;;         and for carefully-scaled arithmetic.

;;         Written by:  Tom Roberts  11/8/89
;;         Made portable:  Malcolm Slaney 12/15/94 malcolm@interval.com

;;                 Timing on a Macintosh PowerBook 180.... (using Symantec C6.0)
;;                         fix_fft (1024 points)             8 ticks
;;                         fft (1024 points - Using SANE)  112 Ticks
;;                         fft (1024 points - Using FPU)    11

;; */

;; /* FIX_MPY() - fixed-point multiplication macro.
;;    This macro is a statement, not an expression (uses asm).
;;    BEWARE: make sure _DX is not clobbered by evaluating (A) or DEST.
;;    args are all of type fixed.
;;    Scaling ensures that 32767*32767 = 32767. */
;; #define dosFIX_MPY(DEST,A,B)       {       \
;;         _DX = (B);                      \
;;         _AX = (A);                      \
;;         asm imul dx;                    \
;;         asm add ax,ax;                  \
;;         asm adc dx,dx;                  \
;;         DEST = _DX;             }

;; #define FIX_MPY(DEST,A,B)       DEST = ((long)(A) * (long)(B))>>15

;; #define N_WAVE          1024    /* dimension of Sinewave[] */

N_WAVE		= 	1024
	
;; #define LOG2_N_WAVE     10      /* log2(N_WAVE) */

LOG2_N_WAVE	= 	10
	
;; #define N_LOUD          100     /* dimension of Loudampl[] */

N_LOUD = 100

;; #ifndef fixed
;; #define fixed short
;; #endif

;; extern fixed Sinewave[N_WAVE]; /* placed at end of this file for clarity */
;; extern fixed Loudampl[N_LOUD];
;; int db_from_ampl(fixed re, fixed im);
;; fixed fix_mpy(fixed a, fixed b);

;; /*
;;         fix_fft() - perform fast Fourier transform.

;;         if n>0 FFT is done, if n<0 inverse FFT is done
;;         fr[n],fi[n] are real,imaginary arrays, INPUT AND RESULT.
;;         size of data = 2**m
;;         set inverse to 0=dft, 1=idft
;; */

FFT_TEST = 0

	ifne FFT_TEST
FFT_SIZE = 4
	else
FFT_SIZE = 7
	endif
	
FFT_LENGTH = 1<<FFT_SIZE
FFT_LOOPS = 0

; disable multitasking for more accuracy

	ifne FFT_TEST

	incdir	"include:"
	include	"exec/exec_lib.i"
test
	move.l	4.w,a6
	jsr	_LVOForbid(a6)
	jsr	_LVODisable(a6)

	bsr	convert_sine

	bsr.w	.waitVBlank
	bsr	testFFT
	bsr	testFFT
	bsr	testFFT

	move.l	$dff004,d6
	and.l	#$1ff00,d6
	lsr.l	#8,d6
* FS-UAE A500 kick13+68000: 
* - 165
* - 163: sine conversion ASRs removed
* - 162: use SP for vars, a5 for another sine pointer
* - 160: use all table indexes multiplied by two 

	move.l	4.w,a6
	jsr	_LVOEnable(a6)
	jsr	_LVOPermit(a6)
	rts


.waitVBlank
.v1	btst	#0,$dff005
	beq.b	.v1
.v2	btst	#0,$dff005
	bne.b	.v2
	rts
	
testFFT
	lea	.test_real_in(pc),a0
	lea	fr(pc),a1
	moveq	#FFT_LENGTH-1,d0
.c	move	(a0)+,(a1)+
	dbf	d0,.c


	lea	fr(pc),a0
	;bsr	windowFFT

	lea	fr(pc),a0
	lea	fi(pc),a1
	bsr.w	sampleFFT

	moveq	#-1,d7

	moveq	#FFT_LENGTH-1,d0
	lea	.test_real_out(pc),a0
	lea	fr(pc),a1
.ch1	cmpm.w	(a0)+,(a1)+
	bne.b	.error
	dbf	d0,.ch1

	moveq	#FFT_LENGTH-1,d0
	lea	.test_img_out(pc),a0
	lea	fi(pc),a1
.ch2	cmpm.w	(a0)+,(a1)+
	bne.b	.error
	dbf	d0,.ch2

	;; passed
	moveq	#0,d7

;	lea	fr(pc),a0
;	lea	fi(pc),a1
;	bsr	loudFFT
;	rts
		
;	lea	fr(pc),a0
;	lea	fi(pc),a1
;	move.l	d7,-(sp)
;	bsr.w	calcFFTPower
;	move.l	(sp)+,d7

.error

	movem.l	cloop1,d0-d4
	rts



.test_real_in
 	dc.w 1000,923,707,382,0,-382,-707,-923,-1000,-923,-707,-382,0,382,707,923
.test_real_out
	dc.w -2,498,0,0,0,1,1,0,0,0,0,0,0,-1,-1,498
.test_img_out
 	dc.w 0,-3,-1,-2,0,-1,-1,-2,0,1,1,0,0,1,1,2

	
temp	dc.l	0
cloop1	dc.l	0
cloop2	dc.l	0
cloop3	dc.l	0
cloop4	dc.l	0
cloop5	dc.l	0
maxSqr	dc.l	0
temp2	dc.l	0
	endif ; FFT_TEST

	if 0
prepareSquareTable
	lea	squareTable,a0
	move	#$ffff,d1
	moveq	#0,d0
.l
	move	d0,d2
	muls	d2,d2
	move.l	d2,(a0)+
	addq	#1,d0
	cmp	d0,d1
	bne.b	.l
	rts
	endif



;in
; a0 = result array reals
; a1 = result array imaginary
;out
; a0 = result (overwritten input array)
; REM ;;;;;;;;;;;;;,
;calcFFTPower	
;	; Calculate for the 1st half, 2nd half is mirror of the 1st and
;	; not used in drawing.
;	moveq	#FFT_LENGTH/2-1,d7
;	move.l	#$ffff,d6
;;	lea	squareTable,a2
;.l
;	move	(a0),d0
;	move	(a1)+,d1
;	muls	d0,d0
;	muls	d1,d1
;	add.l	d1,d0
;	 
;
;;	cmp.l	maxSqr(pc),d0
;;	blo.b	.s
;;	move.l	d0,maxSqr
;;	move	(a0),temp
;;	move	-2(a1),temp2
;;.s
;	; See which square root to use
;	cmp.l	d6,d0
;	bls.b	.16	
;
;	bsr.b	isqrt32
;
;	move	d1,(a0)+
;	dbf	d7,.l	
;	rts
;.16
;	bsr.b	isqrt16
;	move	d1,(a0)+
;	dbf	d7,.l	
;	rts
;
;
;	incdir	
;	include	"isqrt16.s"
; EREM ;;;;;;;;;;;;;;;;;


 ifne FFT_TEST
fi	ds.w	FFT_LENGTH
fr	ds.w	FFT_LENGTH
fpow	ds.w	FFT_LENGTH
 endif


 ifne FFT_TEST
convert_sine
	lea	Sinewave(pc),a3
	move	#N_WAVE-1,d0
.loop	
	asr	(a3)+
	dbf	d0,.loop
	rts
 endif


; in
;    a0 = 16-bit signed sampledata (real array)
;    a1 = imaginary array, to be overwritten
;    a2 = sinewave
; out
;   a0 = result array, real (overwritten input)
;   a1 = result array, imaginary
sampleFFT
	; clear first half of the imaginary array
	move.l	a1,a3

	moveq	#FFT_LENGTH/2/4-1,d0
	moveq	#0,d6
.c	
	move.l	d6,(a3)+
	move.l	d6,(a3)+
	move.l	d6,(a3)+
	move.l	d6,(a3)+
	dbf	d0,.c

 
fix_fft

	rsreset
.m		rs.w	1
.k		rs.w	1
.i		rs.w	1
.l		rs.w	1
.istep		rs.w	1
.sineConverted  rs.w 	1
.varsSizeof	rs.b	0

	movem.l	a4/a5/a6,-(sp)
	lea	-.varsSizeof(sp),sp
	;lea	.vars(pc),a5
	; m, data size 1<<7 = 128
	move	#FFT_SIZE,.m(sp)
 ifne FFT_TEST
	lea	Sinewave(pc),a2	
 endif
	; Cosine
	lea	N_WAVE/4*2(a2),a5


;; int fix_fft(fixed fr[], fixed fi[], int m, int inverse)
;; {
;;         int mr,nn,i,j,l,k,istep, n, scale, shift;
;;         fixed qr,qi,tr,ti,wr,wi,t;

;;                 n = 1<<m;

.n	= 	FFT_LENGTH

;;         if(n > N_WAVE)
;;                 return -1;

;;         mr = 0;
;	clr.w	.mr(sp)

;;         nn = n - 1;

.nn	= 	.n-1

;;         /* decimation in time - re-order data */
;;         for(m=1; m<=nn; ++m) {

	moveq	#.nn-1,d7 	; loop counter
	moveq	#.nn,d3		; loop comparison

; Cleared earlier:
;	moveq	#0,d6		; mr

	moveq	#1,d5		; m
	move	#.n,d4		; preloaded constant

	lea	(.n*2).w,a6	; loop condition constant for loop5 preloaded
	
;; ------------------------------------------------------------------
; top level loop
.loop1
; loop 1 run 127 times when FFT_LENGTH = 128
	ifne	FFT_LOOPS
	addq.l	#1,cloop1
	endif
		
;;                 l = n;

	move	d4,d0		; d4 = .n
	
;; ------------------------------------------------------------------
.loop2
; loop 2 run 247 times when FFT_LENGTH = 128
	ifne	FFT_LOOPS
	addq.l	#1,cloop2
	endif

;;                 do {
;;                         l >>= 1;

	lsr.w	#1,d0

;;                 } while(mr+l > nn);

	move.w	d6,d2	
	add.w	d0,d2
	cmp.w	d3,d2
	bhi.b	.loop2
;; ------------------------------------------------------------------

	;move.w	d0,.l(sp)

;;                 mr = (mr & (l-1)) + l;

	; d6 = mr
	move.w	d0,d1
	subq.w	#1,d1		; l-1
	and.w	d6,d1		; d6 = mr
	add.w	d0,d1
	move.w	d1,d6

;;                 if(mr <= m) continue;

	cmp.w	d5,d1		; d5 = m
	bls.b	.continue

	add	d1,d1		; mr index
	move.w	d5,d2		; m index
	add	d2,d2

;;                 tr = fr[m];
	; d0 = tr/ti
	move	(a0,d2.w),d0

;;                 fr[m] = fr[mr];

	move	(a0,d1.w),(a0,d2.w)
	
;;                 fr[mr] = tr;

	move	d0,(a0,d1.w)
	
;;                 ti = fi[m];
	
	move	(a1,d2.w),d0
	
;;                 fi[m] = fi[mr];

	move	(a1,d1.w),(a1,d2.w)

;;                 fi[mr] = ti;

	move	d0,(a1,d1.w)

;; ------------------------------------------------------------------
	; loop condition and increment
.continue
	addq	#1,d5	; d5 = m
	dbf	d7,.loop1

;;         }

;;         l = 1;

	move.w	#1*2,.l(sp) 	* index

;;         k = LOG2_N_WAVE-1;

	move.w	#LOG2_N_WAVE-1,.k(sp)
	moveq	#15,d5		; shift for multiplications for loop 5 

;; ------------------------------------------------------------------
; top level loop 
.loop3
; loop 3 run 7 times when FFT_LENGTH = 128

	ifne	FFT_LOOPS
	addq.l	#1,cloop3
	endif

;;         while(l < n) {
;;                 /* it may not be obvious, but the shift will be performed
;;                    on each data point exactly once, during this pass. */
;;                 istep = l << 1;

	move.w	.l(sp),d0	* index
	add.w	d0,d0
	move.w	d0,.istep(sp)	* index

;;                 for(m=0; m<l; ++m) {

;	clr.w	.m(sp)
	clr.w	(sp)
	
;; ------------------------------------------------------------------
.loop4
	ifne	FFT_LOOPS
	addq.l	#1,cloop4
	endif
	
; loop 4 run 127 times when FFT_LENGTH = 128

;;                         j = m << k;
;	move.w	.m(sp),d0

;	move.w	(sp),d0
;	move.w	.k(sp),d1

	movem.w	(sp),d0/d1	; load both .m an .k, stored sequentially
	move	d0,d6		* index .m
	lsl	d1,d0

;;                         wi = -Sinewave[j];
;;                         wi >>= 1;

	;add.w	d0,d0
	move.w	(a2,d0.w),d1
	neg.w	d1
;	asr.w	#1,d1
	move	d1,a4
;	a4 = wi

;;                         wr =  Sinewave[j+N_WAVE/4];
;;                         wr >>= 1;

;	add.w	#N_WAVE/4*2,d0
;	move.w	(a2,d0.w),d1
;	asr.w	#1,d1
;	move	d1,a3
	move	(a5,d0.w),a3

	; a3 = wr

;; ------------------------------------------------------------------
;;                         for(i=m; i<n; i+=istep) {
	;move.w	.m(sp),d6	; i
	;move.w	(sp),d6		; i - load a few lins above already
	
	move	.l(sp),d7	; j 
	add	d6,d7

;	add	d6,d6		; i table index
;	add	d7,d7		; j table index

	; loop increment
	; use double as d6 and d7 are word table indices
	move	.istep(sp),d0	* index
;	add	d0,d0
	; loop condition is in a6

.loop5
	ifne	FFT_LOOPS
	addq.l	#1,cloop5
	endif

;speed 162 to 160 when removed moveq #15,d5 from inside the loop

; loop 5 run 448 times when FFT_LENGTH = 128

;;                                 j = i + l;
	; step one at loop end

;;                                 tr = fix_mpy(wr,fr[j])-fix_mpy(wi,fi[j]);

	
	move	(a0,d7),d3	; fr(j)
	move	(a1,d7),d4	; fi(j)

	move.w	a3,d1		; fr(j)*wr
	muls.w	d3,d1
	asr.l	d5,d1

	move.w	a4,d2		; fi(j)*wi
	muls.w	d4,d2
	asr.l	d5,d2


	sub.l	d2,d1
	; d1 = tr
	
;;                                 qr = fr[i];
;;                                 qr >>= 1;

	move.w	(a0,d6.w),d2
	asr.w	#1,d2
	; d2 = qr

 if 0
		;; fr[j] = qr - tr
	move	d2,d5
	sub	d1,d5
	move	d5,(a0,d7.w)

		;; fr[i] = qr + tr
	add.w	d1,d2
	move	d2,(a0,d6.w)
 endif
		;; fr[j] = qr - tr
	sub	d1,d2
	move	d2,(a0,d7.w)

		;; fr[i] = qr + tr
	add.w	d1,d2
	add.w	d1,d2
	move	d2,(a0,d6.w)

;;                                 ti = fix_mpy(wr,fi[j])+fix_mpy(wi,fr[j]);

	move.w	a3,d1		; fi(j)*wr
	muls.w	d4,d1
	asr.l	d5,d1

	move.w	a4,d2		; fr(j)*wi
	muls.w	d3,d2
	asr.l	d5,d2

	add.l	d2,d1

	; d1 = ti

		;;  qi = fi[i];
		;;  qi >>= 1;
	move.w	(a1,d6.w),d2
	asr.w	#1,d2
	; d2 = qi


 if 0
 		;; fi[j] = qi - ti
	move	d2,d5
	sub	d1,d5
	move	d5,(a1,d7.w)
	
		;; fi[i] = qi + ti
	add	d1,d2
	move	d2,(a1,d6.w)
 endif
		;; fi[j] = qi - ti
	sub	d1,d2
	move	d2,(a1,d7.w)
	
		;; fi[i] = qi + ti
	add	d1,d2
	add	d1,d2
	move	d2,(a1,d6.w)

;;                         }
; for loop:  for(i=m; i<n; i+=istep) 
	; add istep twice as d6 and d7 are word table indices
	; d0 = 2*istep
	add	d0,d6	; i+=istep
	add	d0,d7	; j+=istep
	; a6 = 2*.n
	cmp.w	a6,d6
	blo.b	.loop5

;;                 }

	ifne	.m
	fail 	.m referred without index, so it must be zero
	endif

;for loop: for(m=0; m<l; ++m) 	
	addq	#1*2,(sp)
	;move.w	.m(sp),d0
	move.w	(sp),d0
	cmp.w	.l(sp),d0
	blo.b	.loop4

;;                 --k;

	subq.w	#1,.k(sp)

;;                 l = istep;

	move.w	.istep(sp),.l(sp)

;;         }

; loop condition: while(l < n) 
;	move.w	.l(sp),d0
;	cmp.w	#.n,d0
	cmp.w	#.n*2,.l(sp)
	blo.w	.loop3

;;         return scale;
;; }

	; DONE
	lea	.varsSizeof(sp),sp
	movem.l	(sp)+,a4/a5/a6
	rts

;; /*      window() - apply a Hanning window       */
;; void window(fixed fr[], int n)

; in:
;   a0 = input data
;   a2 = sinewave
windowFFT

;; {
;;         int i,j,k;

;;         j = N_WAVE/n;

	; sinewave index step
	move	#N_WAVE/FFT_LENGTH*2,d7

;;         n >>= 1;
	
	; loop end condition
	moveq	#FFT_LENGTH/2-1,d6

;;         for(i=0,k=N_WAVE/4; i<n; ++i,k+=j)
;;                 FIX_MPY(fr[i],fr[i],16384-(Sinewave[k]>>1));

	;i=0

	;k=N_WAVE/4
	;index to sinewave
	;lea	Sinewave+N_WAVE/4*2(pc),a1
	lea 	N_WAVE/4*2(a2),a1

	moveq	#15,d3		; muls shift
	move	#16384,d2
.for1
	; 16384-(Sinewave(k)>>1)
	move	(a1),d4
	asr	#1,d4
	move	d2,d5
	sub	d4,d5

	; fr(i)
	muls	(a0),d5
	asr.l	d3,d5
	move	d5,(a0)+

	; ++i
	;addq	#1,d0
	; k+=j
	;add	d7,d1
	add	d7,a1
	;i<n
	dbf	d6,.for1

;;         n <<= 1;

	; loop end condition
;	add	d6,d6
	moveq	#FFT_LENGTH/2-1,d6
	
;;         for(k-=j; i<n; ++i,k-=j)
;;                 FIX_MPY(fr[i],fr[i],16384-(Sinewave[k]>>1));
;; }

	; k-=j
	;sub	d7,d1
	sub	d7,a1
		
.for2
	; 16384-(Sinewave(k)>>1)
	move	(a1),d4
	asr	#1,d4
	move	d2,d5
	sub	d4,d5

	muls	(a0),d5
	asr.l	d3,d5
	move	d5,(a0)+

	;++i
	;addq	#1,d0
	;k-=j
	;sub	d7,d1
	sub	d7,a1
	;i<n
	dbf	d6,.for2

	rts

;; /*      fix_loud() - compute loudness of freq-spectrum components.
;;         n should be ntot/2, where ntot was passed to fix_fft();
;;         6 dB is added to account for the omitted alias components.
;;         scale_shift should be the result of fix_fft(), if the time-series
;;         was obtained from an inverse FFT, 0 otherwise.
;;         loud[] is the loudness, in dB wrt 32767; will be +10 to -N_LOUD.
;; */
;; void fix_loud(fixed loud[], fixed fr[], fixed fi[], int n, int scale_shift)
;; {
;;         int i, max;

;;         max = 0;
;;         if(scale_shift > 0)
;;                 max = 10;
;;         scale_shift = (scale_shift+1) * 6;

;;         for(i=0; i<n; ++i) {
;;                 loud[i] = db_from_ampl(fr[i],fi[i]) + scale_shift;
;;                 if(loud[i] > max)
;;                         loud[i] = max;
;;         }
;; }


;in
; a0 = result array reals
; a1 = result array imaginary
;out
; a0 = result (overwritten input array)
; rem ;;;;;;;;;
;loudFFT
;	lea	Loudampl(pc),a2
;	lea	Loudampl2(pc),a3
;	
;	tst.l	(a3)
;	bne.b	.1
;
;	move	(a2)+,d0
;	muls	d0,d0
;	move.l	d0,(a3)+
;
;	moveq	#N_LOUD-1-1,d7
;.l1
;	move	(a2)+,d0
;	muls	d0,d0
;	move.l	d0,(a3)
;	add.l	-4(a3),d0
;	lsr.l	#1,d0
;	move.l	d0,-4(a3)
;	addq.l	#4,a3
;	dbf	d7,.l1
;.1
;
;nok
;	moveq	#FFT_LENGTH/2-1,d7
;.l2
;	move	(a0)+,d0
;	muls	d0,d0
;	move	(a1)+,d1
;	muls	d1,d1
;	add.l	d1,d0
;
;	lea	Loudampl2(pc),a2
;	moveq	#0,d6
;	moveq	#N_LOUD,d5
;.l3
;	cmp.l	(a2)+,d0
;	bhi.b	.break
;	
;	addq	#1,d6
;	;cmp	#N_LOUD,d6
;	cmp		d5,d6
;	bne.b	.l3
;
;.break
;	* d6 = dB level
;	;neg	d6
;	;addq	#6,d6
;	;bmi.b	.2
;	;moveq	#0,d6
;.2
;
;	subq	#6,d6
;	bpl.b 	.3
;	moveq	#0,d6
;.3	
;	move	d6,-2(a0)
;
;	dbf	d7,.l2
;
;
;	rts
; EREM ;;;;;;;;;;;;;;;

;; /*      db_from_ampl() - find loudness (in dB) from
;;         the complex amplitude.
;; */
;; int db_from_ampl(fixed re, fixed im)
;; {
;;         static long loud2[N_LOUD] = {0};
;;         long v;
;;         int i;

;;         if(loud2[0] == 0) {
;;                 loud2[0] = (long)Loudampl[0] * (long)Loudampl[0];
;;                 for(i=1; i<N_LOUD; ++i) {
;;                         v = (long)Loudampl[i] * (long)Loudampl[i];
;;                         loud2[i] = v;
;;                         loud2[i-1] = (loud2[i-1]+v) / 2;
;;                 }
;;         }

;;         v = (long)re * (long)re + (long)im * (long)im;

;;         for(i=0; i<N_LOUD; ++i)
;;                 if(loud2[i] <= v)
;;                         break;

;;         return (-i);
;; }

;; /*
;;         fix_mpy() - fixed-point multiplication
;; */
;; fixed fix_mpy(fixed a, fixed b)
;; {
;;         FIX_MPY(a,a,b);
;;         return a;
;; }

;; /*
;;         iscale() - scale an integer value by (numer/denom)
;; */
;; int iscale(int value, int numer, int denom)
;; {
;; #ifdef  DOS
;;         asm     mov ax,value
;;         asm     imul WORD PTR numer
;;         asm     idiv WORD PTR denom

;;         return _AX;
;; #else
;;                 return (long) value * (long)numer/(long)denom;
;; #endif
;; }

;; /*
;;         fix_dot() - dot product of two fixed arrays
;; */
;; fixed fix_dot(fixed *hpa, fixed *pb, int n)
;; {
;;         fixed *pa;
;;         long sum;
;;         register fixed a,b;
;;         unsigned int seg,off;

;; /*      seg = FP_SEG(hpa);
;;         off = FP_OFF(hpa);
;;         seg += off>>4;
;;         off &= 0x000F;
;;         pa = MK_FP(seg,off);
;;  */
;;         sum = 0L;
;;         while(n--) {
;;                 a = *pa++;
;;                 b = *pb++;
;;                 FIX_MPY(a,a,b);
;;                 sum += a;
;;         }

;;         if(sum > 0x7FFF)
;;                 sum = 0x7FFF;
;;         else if(sum < -0x7FFF)
;;                 sum = -0x7FFF;

;;         return (fixed)sum;
;; #ifdef  DOS
;;         /* ASSUMES hpa is already normalized so FP_OFF(hpa) < 16 */
;;         asm     push    ds
;;         asm     lds     si,hpa
;;         asm     les     di,pb
;;         asm     xor     bx,bx

;;         asm     xor     cx,cx

;; loop:   /* intermediate values can overflow by a factor of 2 without
;;            causing an error; the final value must not overflow! */
;;         asm     lodsw
;; .
;;         asm     imul    word ptr es:[di]
;;         asm     add     bx,ax
;;         asm     adc     cx,dx
;;         asm     jo      overflow
;;         asm     add     di,2
;;         asm     dec     word ptr n
;;         asm     jg      loop

;;         asm     add     bx,bx
;;         asm     adc     cx,cx
;;         asm     jo      overflow

;;         asm     pop     ds
;;         return _CX;

;; overflow:
;;         asm     mov     cx,7FFFH
;;         asm     adc     cx,0

;;         asm     pop     ds
;;         return _CX;
;; #endif

;; }


;; #if N_WAVE != 1024
;;         ERROR: N_WAVE != 1024
;; #endif
;; fixed Sinewave[1024] = {
;;       0,    201,    402,    603,    804,   1005,   1206,   1406,
;;    1607,   1808,   2009,   2209,   2410,   2610,   2811,   3011,
;;    3211,   3411,   3611,   3811,   4011,   4210,   4409,   4608,
;;    4807,   5006,   5205,   5403,   5601,   5799,   5997,   6195,
;;    6392,   6589,   6786,   6982,   7179,   7375,   7571,   7766,
;;    7961,   8156,   8351,   8545,   8739,   8932,   9126,   9319,
;;    9511,   9703,   9895,  10087,  10278,  10469,  10659,  10849,
;;   11038,  11227,  11416,  11604,  11792,  11980,  12166,  12353,
;;   12539,  12724,  12909,  13094,  13278,  13462,  13645,  13827,
;;   14009,  14191,  14372,  14552,  14732,  14911,  15090,  15268,
;;   15446,  15623,  15799,  15975,  16150,  16325,  16499,  16672,
;;   16845,  17017,  17189,  17360,  17530,  17699,  17868,  18036,
;;   18204,  18371,  18537,  18702,  18867,  19031,  19194,  19357,
;;   19519,  19680,  19840,  20000,  20159,  20317,  20474,  20631,
;;   20787,  20942,  21096,  21249,  21402,  21554,  21705,  21855,
;;   22004,  22153,  22301,  22448,  22594,  22739,  22883,  23027,
;;   23169,  23311,  23452,  23592,  23731,  23869,  24006,  24143,
;;   24278,  24413,  24546,  24679,  24811,  24942,  25072,  25201,
;;   25329,  25456,  25582,  25707,  25831,  25954,  26077,  26198,
;;   26318,  26437,  26556,  26673,  26789,  26905,  27019,  27132,
;;   27244,  27355,  27466,  27575,  27683,  27790,  27896,  28001,
;;   28105,  28208,  28309,  28410,  28510,  28608,  28706,  28802,
;;   28897,  28992,  29085,  29177,  29268,  29358,  29446,  29534,
;;   29621,  29706,  29790,  29873,  29955,  30036,  30116,  30195,
;;   30272,  30349,  30424,  30498,  30571,  30643,  30713,  30783,
;;   30851,  30918,  30984,  31049,
;;   31113,  31175,  31236,  31297,
;;   31356,  31413,  31470,  31525,  31580,  31633,  31684,  31735,
;;   31785,  31833,  31880,  31926,  31970,  32014,  32056,  32097,
;;   32137,  32176,  32213,  32249,  32284,  32318,  32350,  32382,
;;   32412,  32441,  32468,  32495,  32520,  32544,  32567,  32588,
;;   32609,  32628,  32646,  32662,  32678,  32692,  32705,  32717,
;;   32727,  32736,  32744,  32751,  32757,  32761,  32764,  32766,
;;   32767,  32766,  32764,  32761,  32757,  32751,  32744,  32736,
;;   32727,  32717,  32705,  32692,  32678,  32662,  32646,  32628,
;;   32609,  32588,  32567,  32544,  32520,  32495,  32468,  32441,
;;   32412,  32382,  32350,  32318,  32284,  32249,  32213,  32176,
;;   32137,  32097,  32056,  32014,  31970,  31926,  31880,  31833,
;;   31785,  31735,  31684,  31633,  31580,  31525,  31470,  31413,
;;   31356,  31297,  31236,  31175,  31113,  31049,  30984,  30918,
;;   30851,  30783,  30713,  30643,  30571,  30498,  30424,  30349,
;;   30272,  30195,  30116,  30036,  29955,  29873,  29790,  29706,
;;   29621,  29534,  29446,  29358,  29268,  29177,  29085,  28992,
;;   28897,  28802,  28706,  28608,  28510,  28410,  28309,  28208,
;;   28105,  28001,  27896,  27790,  27683,  27575,  27466,  27355,
;;   27244,  27132,  27019,  26905,  26789,  26673,  26556,  26437,
;;   26318,  26198,  26077,  25954,  25831,  25707,  25582,  25456,
;;   25329,  25201,  25072,  24942,  24811,  24679,  24546,  24413,
;;   24278,  24143,  24006,  23869,  23731,  23592,  23452,  23311,
;;   23169,  23027,  22883,  22739,  22594,  22448,  22301,  22153,
;;   22004,  21855,  21705,  21554,  21402,  21249,  21096,  20942,
;;   20787,  20631,  20474,  20317,  20159,  20000,  19840,  19680,
;;   19519,  19357,  19194,  19031,  18867,  18702,  18537,  18371,
;;   18204,  18036,  17868,  17699,  17530,  17360,  17189,  17017,
;;   16845,  16672,  16499,  16325,  16150,  15975,  15799,  15623,
;;   15446,  15268,  15090,  14911,  14732,  14552,  14372,  14191,
;;   14009,  13827,  13645,  13462,  13278,  13094,  12909,  12724,
;;   12539,  12353,  12166,  11980,  11792,  11604,  11416,  11227,
;;   11038,  10849,  10659,  10469,  10278,  10087,   9895,   9703,
;;    9511,   9319,   9126,   8932,   8739,   8545,   8351,   8156,
;;    7961,   7766,   7571,   7375,   7179,   6982,   6786,   6589,
;;    6392,   6195,   5997,   5799,   5601,   5403,   5205,   5006,
;;    4807,   4608,   4409,   4210,   4011,   3811,   3611,   3411,
;;    3211,   3011,   2811,   2610,   2410,   2209,   2009,   1808,
;;    1607,   1406,   1206,   1005,    804,    603,    402,    201,
;;       0,   -201,   -402,   -603,   -804,  -1005,  -1206,  -1406,
;;   -1607,  -1808,  -2009,  -2209,  -2410,  -2610,  -2811,  -3011,
;;   -3211,  -3411,  -3611,  -3811,  -4011,  -4210,  -4409,  -4608,
;;   -4807,  -5006,  -5205,  -5403,  -5601,  -5799,  -5997,  -6195,
;;   -6392,  -6589,  -6786,  -6982,  -7179,  -7375,  -7571,  -7766,
;;   -7961,  -8156,  -8351,  -8545,  -8739,  -8932,  -9126,  -9319,
;;   -9511,  -9703,  -9895, -10087, -10278, -10469, -10659, -10849,
;;  -11038, -11227, -11416, -11604, -11792, -11980, -12166, -12353,
;;  -12539, -12724, -12909, -13094, -13278, -13462, -13645, -13827,
;;  -14009, -14191, -14372, -14552, -14732, -14911, -15090, -15268,
;;  -15446, -15623, -15799, -15975, -16150, -16325, -16499, -16672,
;;  -16845, -17017, -17189, -17360, -17530, -17699, -17868, -18036,
;;  -18204, -18371, -18537, -18702, -18867, -19031, -19194, -19357,
;;  -19519, -19680, -19840, -20000, -20159, -20317, -20474, -20631,
;;  -20787, -20942, -21096, -21249, -21402, -21554, -21705, -21855,
;;  -22004, -22153, -22301, -22448, -22594, -22739, -22883, -23027,
;;  -23169, -23311, -23452, -23592, -23731, -23869, -24006, -24143,
;;  -24278, -24413, -24546, -24679, -24811, -24942, -25072, -25201,
;;  -25329, -25456, -25582, -25707, -25831, -25954, -26077, -26198,
;;  -26318, -26437, -26556, -26673, -26789, -26905, -27019, -27132,
;;  -27244, -27355, -27466, -27575, -27683, -27790, -27896, -28001,
;;  -28105, -28208, -28309, -28410, -28510, -28608, -28706, -28802,
;;  -28897, -28992, -29085, -29177, -29268, -29358, -29446, -29534,
;;  -29621, -29706, -29790, -29873, -29955, -30036, -30116, -30195,
;;  -30272, -30349, -30424, -30498, -30571, -30643, -30713, -30783,
;;  -30851, -30918, -30984, -31049, -31113, -31175, -31236, -31297,
;;  -31356, -31413, -31470, -31525, -31580, -31633, -31684, -31735,
;;  -31785, -31833, -31880, -31926, -31970, -32014, -32056, -32097,
;;  -32137, -32176, -32213, -32249, -32284, -32318, -32350, -32382,
;;  -32412, -32441, -32468, -32495, -32520, -32544, -32567, -32588,
;;  -32609, -32628, -32646, -32662, -32678, -32692, -32705, -32717,
;;  -32727, -32736, -32744, -32751, -32757, -32761, -32764, -32766,
;;  -32767, -32766, -32764, -32761, -32757, -32751, -32744, -32736,
;;  -32727, -32717, -32705, -32692, -32678, -32662, -32646, -32628,
;;  -32609, -32588, -32567, -32544, -32520, -32495, -32468, -32441,
;;  -32412, -32382, -32350, -32318, -32284, -32249, -32213, -32176,
;;  -32137, -32097, -32056, -32014, -31970, -31926, -31880, -31833,
;;  -31785, -31735, -31684, -31633, -31580, -31525, -31470, -31413,
;;  -31356, -31297, -31236, -31175, -31113, -31049, -30984, -30918,
;;  -30851, -30783, -30713, -30643, -30571, -30498, -30424, -30349,
;;  -30272, -30195, -30116, -30036, -29955, -29873, -29790, -29706,
;;  -29621, -29534, -29446, -29358, -29268, -29177, -29085, -28992,
;;  -28897, -28802, -28706, -28608, -28510, -28410, -28309, -28208,
;;  -28105, -28001, -27896, -27790, -27683, -27575, -27466, -27355,
;;  -27244, -27132, -27019, -26905, -26789, -26673, -26556, -26437,
;;  -26318, -26198, -26077, -25954, -25831, -25707, -25582, -25456,
;;  -25329, -25201, -25072, -24942, -24811, -24679, -24546, -24413,
;;  -24278, -24143, -24006, -23869, -23731, -23592, -23452, -23311,
;;  -23169, -23027, -22883, -22739, -22594, -22448, -22301, -22153,
;;  -22004, -21855, -21705, -21554, -21402, -21249, -21096, -20942,
;;  -20787, -20631, -20474, -20317, -20159, -20000, -19840, -19680,
;;  -19519, -19357, -19194, -19031, -18867, -18702, -18537, -18371,
;;  -18204, -18036, -17868, -17699, -17530, -17360, -17189, -17017,
;;  -16845, -16672, -16499, -16325, -16150, -15975, -15799, -15623,
;;  -15446, -15268, -15090, -14911, -14732, -14552, -14372, -14191,
;;  -14009, -13827, -13645, -13462, -13278, -13094, -12909, -12724,
;;  -12539, -12353, -12166, -11980, -11792, -11604, -11416, -11227,
;;  -11038, -10849, -10659, -10469, -10278, -10087,  -9895,  -9703,
;;   -9511,  -9319,  -9126,  -8932,  -8739,  -8545,  -8351,  -8156,
;;   -7961,  -7766,  -7571,  -7375,  -7179,  -6982,  -6786,  -6589,
;;   -6392,  -6195,  -5997,  -5799,  -5601,  -5403,  -5205,  -5006,
;;   -4807,  -4608,  -4409,  -4210,  -4011,  -3811,  -3611,  -3411,
;;   -3211,  -3011,  -2811,  -2610,  -2410,  -2209,  -2009,  -1808,
;;   -1607,  -1406,  -1206,  -1005,   -804,   -603,   -402,   -201,
;; };
 
 ifne FFT_TEST
Sinewave 
	dc.w	       0,    201,    402,    603,    804,   1005,   1206,   1406
	dc.w	    1607,   1808,   2009,   2209,   2410,   2610,   2811,   3011
	dc.w	    3211,   3411,   3611,   3811,   4011,   4210,   4409,   4608
	dc.w	    4807,   5006,   5205,   5403,   5601,   5799,   5997,   6195
	dc.w	    6392,   6589,   6786,   6982,   7179,   7375,   7571,   7766
	dc.w	    7961,   8156,   8351,   8545,   8739,   8932,   9126,   9319
	dc.w	    9511,   9703,   9895,  10087,  10278,  10469,  10659,  10849
	dc.w	   11038,  11227,  11416,  11604,  11792,  11980,  12166,  12353
	dc.w	   12539,  12724,  12909,  13094,  13278,  13462,  13645,  13827
	dc.w	   14009,  14191,  14372,  14552,  14732,  14911,  15090,  15268
	dc.w	   15446,  15623,  15799,  15975,  16150,  16325,  16499,  16672
	dc.w	   16845,  17017,  17189,  17360,  17530,  17699,  17868,  18036
	dc.w	   18204,  18371,  18537,  18702,  18867,  19031,  19194,  19357
	dc.w	   19519,  19680,  19840,  20000,  20159,  20317,  20474,  20631
	dc.w	   20787,  20942,  21096,  21249,  21402,  21554,  21705,  21855
	dc.w	   22004,  22153,  22301,  22448,  22594,  22739,  22883,  23027
	dc.w	   23169,  23311,  23452,  23592,  23731,  23869,  24006,  24143
	dc.w	   24278,  24413,  24546,  24679,  24811,  24942,  25072,  25201
	dc.w	   25329,  25456,  25582,  25707,  25831,  25954,  26077,  26198
	dc.w	   26318,  26437,  26556,  26673,  26789,  26905,  27019,  27132
	dc.w	   27244,  27355,  27466,  27575,  27683,  27790,  27896,  28001
	dc.w	   28105,  28208,  28309,  28410,  28510,  28608,  28706,  28802
	dc.w	   28897,  28992,  29085,  29177,  29268,  29358,  29446,  29534
	dc.w	   29621,  29706,  29790,  29873,  29955,  30036,  30116,  30195
	dc.w	   30272,  30349,  30424,  30498,  30571,  30643,  30713,  30783
	dc.w	   30851,  30918,  30984,  31049
	dc.w	   31113,  31175,  31236,  31297
	dc.w	   31356,  31413,  31470,  31525,  31580,  31633,  31684,  31735
	dc.w	   31785,  31833,  31880,  31926,  31970,  32014,  32056,  32097
	dc.w	   32137,  32176,  32213,  32249,  32284,  32318,  32350,  32382
	dc.w	   32412,  32441,  32468,  32495,  32520,  32544,  32567,  32588
	dc.w	   32609,  32628,  32646,  32662,  32678,  32692,  32705,  32717
	dc.w	   32727,  32736,  32744,  32751,  32757,  32761,  32764,  32766
	dc.w	   32767,  32766,  32764,  32761,  32757,  32751,  32744,  32736
	dc.w	   32727,  32717,  32705,  32692,  32678,  32662,  32646,  32628
	dc.w	   32609,  32588,  32567,  32544,  32520,  32495,  32468,  32441
	dc.w	   32412,  32382,  32350,  32318,  32284,  32249,  32213,  32176
	dc.w	   32137,  32097,  32056,  32014,  31970,  31926,  31880,  31833
	dc.w	   31785,  31735,  31684,  31633,  31580,  31525,  31470,  31413
	dc.w	   31356,  31297,  31236,  31175,  31113,  31049,  30984,  30918
	dc.w	   30851,  30783,  30713,  30643,  30571,  30498,  30424,  30349
	dc.w	   30272,  30195,  30116,  30036,  29955,  29873,  29790,  29706
	dc.w	   29621,  29534,  29446,  29358,  29268,  29177,  29085,  28992
	dc.w	   28897,  28802,  28706,  28608,  28510,  28410,  28309,  28208
	dc.w	   28105,  28001,  27896,  27790,  27683,  27575,  27466,  27355
	dc.w	   27244,  27132,  27019,  26905,  26789,  26673,  26556,  26437
	dc.w	   26318,  26198,  26077,  25954,  25831,  25707,  25582,  25456
	dc.w	   25329,  25201,  25072,  24942,  24811,  24679,  24546,  24413
	dc.w	   24278,  24143,  24006,  23869,  23731,  23592,  23452,  23311
	dc.w	   23169,  23027,  22883,  22739,  22594,  22448,  22301,  22153
	dc.w	   22004,  21855,  21705,  21554,  21402,  21249,  21096,  20942
	dc.w	   20787,  20631,  20474,  20317,  20159,  20000,  19840,  19680
	dc.w	   19519,  19357,  19194,  19031,  18867,  18702,  18537,  18371
	dc.w	   18204,  18036,  17868,  17699,  17530,  17360,  17189,  17017
	dc.w	   16845,  16672,  16499,  16325,  16150,  15975,  15799,  15623
	dc.w	   15446,  15268,  15090,  14911,  14732,  14552,  14372,  14191
	dc.w	   14009,  13827,  13645,  13462,  13278,  13094,  12909,  12724
	dc.w	   12539,  12353,  12166,  11980,  11792,  11604,  11416,  11227
	dc.w	   11038,  10849,  10659,  10469,  10278,  10087,   9895,   9703
	dc.w	    9511,   9319,   9126,   8932,   8739,   8545,   8351,   8156
	dc.w	    7961,   7766,   7571,   7375,   7179,   6982,   6786,   6589
	dc.w	    6392,   6195,   5997,   5799,   5601,   5403,   5205,   5006
	dc.w	    4807,   4608,   4409,   4210,   4011,   3811,   3611,   3411
	dc.w	    3211,   3011,   2811,   2610,   2410,   2209,   2009,   1808
	dc.w	    1607,   1406,   1206,   1005,    804,    603,    402,    201
	dc.w	       0,   -201,   -402,   -603,   -804,  -1005,  -1206,  -1406
	dc.w	   -1607,  -1808,  -2009,  -2209,  -2410,  -2610,  -2811,  -3011
	dc.w	   -3211,  -3411,  -3611,  -3811,  -4011,  -4210,  -4409,  -4608
	dc.w	   -4807,  -5006,  -5205,  -5403,  -5601,  -5799,  -5997,  -6195
	dc.w	   -6392,  -6589,  -6786,  -6982,  -7179,  -7375,  -7571,  -7766
	dc.w	   -7961,  -8156,  -8351,  -8545,  -8739,  -8932,  -9126,  -9319
	dc.w	   -9511,  -9703,  -9895, -10087, -10278, -10469, -10659, -10849
	dc.w	  -11038, -11227, -11416, -11604, -11792, -11980, -12166, -12353
	dc.w	  -12539, -12724, -12909, -13094, -13278, -13462, -13645, -13827
	dc.w	  -14009, -14191, -14372, -14552, -14732, -14911, -15090, -15268
	dc.w	  -15446, -15623, -15799, -15975, -16150, -16325, -16499, -16672
	dc.w	  -16845, -17017, -17189, -17360, -17530, -17699, -17868, -18036
	dc.w	  -18204, -18371, -18537, -18702, -18867, -19031, -19194, -19357
	dc.w	  -19519, -19680, -19840, -20000, -20159, -20317, -20474, -20631
	dc.w	  -20787, -20942, -21096, -21249, -21402, -21554, -21705, -21855
	dc.w	  -22004, -22153, -22301, -22448, -22594, -22739, -22883, -23027
	dc.w	  -23169, -23311, -23452, -23592, -23731, -23869, -24006, -24143
	dc.w	  -24278, -24413, -24546, -24679, -24811, -24942, -25072, -25201
	dc.w	  -25329, -25456, -25582, -25707, -25831, -25954, -26077, -26198
	dc.w	  -26318, -26437, -26556, -26673, -26789, -26905, -27019, -27132
	dc.w	  -27244, -27355, -27466, -27575, -27683, -27790, -27896, -28001
	dc.w	  -28105, -28208, -28309, -28410, -28510, -28608, -28706, -28802
	dc.w	  -28897, -28992, -29085, -29177, -29268, -29358, -29446, -29534
	dc.w	  -29621, -29706, -29790, -29873, -29955, -30036, -30116, -30195
	dc.w	  -30272, -30349, -30424, -30498, -30571, -30643, -30713, -30783
	dc.w	  -30851, -30918, -30984, -31049, -31113, -31175, -31236, -31297
	dc.w	  -31356, -31413, -31470, -31525, -31580, -31633, -31684, -31735
	dc.w	  -31785, -31833, -31880, -31926, -31970, -32014, -32056, -32097
	dc.w	  -32137, -32176, -32213, -32249, -32284, -32318, -32350, -32382
	dc.w	  -32412, -32441, -32468, -32495, -32520, -32544, -32567, -32588
	dc.w	  -32609, -32628, -32646, -32662, -32678, -32692, -32705, -32717
	dc.w	  -32727, -32736, -32744, -32751, -32757, -32761, -32764, -32766
	dc.w	  -32767, -32766, -32764, -32761, -32757, -32751, -32744, -32736
	dc.w	  -32727, -32717, -32705, -32692, -32678, -32662, -32646, -32628
	dc.w	  -32609, -32588, -32567, -32544, -32520, -32495, -32468, -32441
	dc.w	  -32412, -32382, -32350, -32318, -32284, -32249, -32213, -32176
	dc.w	  -32137, -32097, -32056, -32014, -31970, -31926, -31880, -31833
	dc.w	  -31785, -31735, -31684, -31633, -31580, -31525, -31470, -31413
	dc.w	  -31356, -31297, -31236, -31175, -31113, -31049, -30984, -30918
	dc.w	  -30851, -30783, -30713, -30643, -30571, -30498, -30424, -30349
	dc.w	  -30272, -30195, -30116, -30036, -29955, -29873, -29790, -29706
	dc.w	  -29621, -29534, -29446, -29358, -29268, -29177, -29085, -28992
	dc.w	  -28897, -28802, -28706, -28608, -28510, -28410, -28309, -28208
	dc.w	  -28105, -28001, -27896, -27790, -27683, -27575, -27466, -27355
	dc.w	  -27244, -27132, -27019, -26905, -26789, -26673, -26556, -26437
	dc.w	  -26318, -26198, -26077, -25954, -25831, -25707, -25582, -25456
	dc.w	  -25329, -25201, -25072, -24942, -24811, -24679, -24546, -24413
	dc.w	  -24278, -24143, -24006, -23869, -23731, -23592, -23452, -23311
	dc.w	  -23169, -23027, -22883, -22739, -22594, -22448, -22301, -22153
	dc.w	  -22004, -21855, -21705, -21554, -21402, -21249, -21096, -20942
	dc.w	  -20787, -20631, -20474, -20317, -20159, -20000, -19840, -19680
	dc.w	  -19519, -19357, -19194, -19031, -18867, -18702, -18537, -18371
	dc.w	  -18204, -18036, -17868, -17699, -17530, -17360, -17189, -17017
	dc.w	  -16845, -16672, -16499, -16325, -16150, -15975, -15799, -15623
	dc.w	  -15446, -15268, -15090, -14911, -14732, -14552, -14372, -14191
	dc.w	  -14009, -13827, -13645, -13462, -13278, -13094, -12909, -12724
	dc.w	  -12539, -12353, -12166, -11980, -11792, -11604, -11416, -11227
	dc.w	  -11038, -10849, -10659, -10469, -10278, -10087,  -9895,  -9703
	dc.w	   -9511,  -9319,  -9126,  -8932,  -8739,  -8545,  -8351,  -8156
	dc.w	   -7961,  -7766,  -7571,  -7375,  -7179,  -6982,  -6786,  -6589
	dc.w	   -6392,  -6195,  -5997,  -5799,  -5601,  -5403,  -5205,  -5006
	dc.w	   -4807,  -4608,  -4409,  -4210,  -4011,  -3811,  -3611,  -3411
	dc.w	   -3211,  -3011,  -2811,  -2610,  -2410,  -2209,  -2009,  -1808
	dc.w	   -1607,  -1406,  -1206,  -1005,   -804,   -603,   -402,   -201
  endif

;; #if N_LOUD != 100
;;         ERROR: N_LOUD != 100
;; #endif
;; fixed Loudampl[100] = {
;;   32767,  29203,  26027,  23197,  20674,  18426,  16422,  14636,
;;   13044,  11626,  10361,   9234,   8230,   7335,   6537,   5826,
;;    5193,   4628,   4125,   3676,   3276,   2920,   2602,   2319,
;;    2067,   1842,   1642,   1463,   1304,   1162,   1036,    923,
;;     823,    733,    653,    582,    519,    462,    412,    367,
;;     327,    292,    260,    231,    206,    184,    164,    146,
;;     130,    116,    103,     92,     82,     73,     65,     58,
;;      51,     46,     41,     36,     32,     29,     26,     23,
;;      20,     18,     16,     14,     13,     11,     10,      9,
;;       8,      7,      6,      5,      5,      4,      4,      3,
;;       3,      2,      2,      2,      2,      1,      1,      1,
;;       1,      1,      1,      0,      0,      0,      0,      0,
;;       0,      0,      0,      0,
;; };


;Loudampl
;  dc.w  32767,  29203,  26027,  23197,  20674,  18426,  16422,  14636
;  ; 9
;  dc.w  13044,  11626,  10361,   9234,   8230,   7335,   6537,   5826
;  ; 17
;  dc.w   5193,   4628,   4125,   3676,   3276,   2920,   2602,   2319
;  ; 25
;  dc.w   2067,   1842,   1642,   1463,   1304,   1162,   1036,    923
;  ; 33
;  dc.w    823,    733,    653,    582,    519,    462,    412,    367
;  ; 41
;  dc.w    327,    292,    260,    231,    206,    184,    164,    146
;  ; 49
;  dc.w    130,    116,    103,     92,     82,     73,     65,     58
;  ; 57
;  dc.w     51,     46,     41,     36,     32,     29,     26,     23
;  ; 65
;  dc.w     20,     18,     16,     14,     13,     11,     10,      9
;  ; 73
;  dc.w      8,      7,      6,      5,      5,      4,      4,      3
;  dc.w      3,      2,      2,      2,      2,      1,      1,      1
;  dc.w      1,      1,      1,      0,      0,      0,      0,      0
;  dc.w      0,      0,      0,      0
;
;
;
;Loudampl2
;	ds.l	N_LOUD

;; #ifdef  MAIN

;; #include        <stdio.h>
;; #include        <math.h>

;; #define M       4
;; #define N       (1<<M)

;; main(){
;;         fixed real[N], imag[N];
;;         int     i;

;;         for (i=0; i<N; i++){
;;                 real[i] = 1000*cos(i*2*3.1415926535/N);
;;                 imag[i] = 0;
;;         }

;;         fix_fft(real, imag, M, 0;

;;         for (i=0; i<N; i++){
;;                 printf("%d: %d, %d\n", i, real[i], imag[i]);
;;         }

;;         fix_fft(real, imag, M, 1);

;;         for (i=0; i<N; i++){
;;                 printf("%d: %d, %d\n", i, real[i], imag[i]);
;;         }
;; }
;; #endif  /* MAIN */


;	section	table,bss_p
;squareTable
;	ds.l	$ffff
