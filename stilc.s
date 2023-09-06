;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
    incdir  include:
    include mucro.i
	include	dos/dos_lib.i
	include	exec/exec.i
	include	dos/dosextens.i
    include exec/exec_lib.i

DEBUG	=	1
SERIALDEBUG = 1

DPRINT macro
	ifne DEBUG
	jsr	desmsgDebugAndPrint
  dc.b 	\1,10,0
  even
	endc
	endm


	DPRINT	"moi"
    bsr     createStilIndex
    move.l	count1,d0
    move.l	count2,d1
    move.l	count3,d2
    rts




Y:
createStilIndex:
    DPRINT "createStilIndex"
    sub.l   a4,a4   

    bsr     _getDos

    ; ---------------------------------
    * Open STIL.txt
    move.l  #.name1,d1
    move.l  #MODE_OLDFILE,d2
    lob     Open
    DPRINT  "open1=%lx"
    move.l  d0,d7
    beq     .exit

    ; ---------------------------------
    * Find STIL.txt length
	move.l	d7,d1		
	moveq	#0,d2	
	moveq	#1,d3
	lob	Seek
	move.l	d7,d1
	moveq	#0,d2	
	moveq	#1,d3
	lob	Seek
	move.l	d0,d5		* file length
	move.l	d7,d1
	moveq	#0,d2
	moveq	#-1,d3
	lob	Seek			* start of file
    DPRINT  "len=%lx"

    ; ---------------------------------
    * Try to open idx
    move.l  #.name2,d1
    move.l  #MODE_OLDFILE,d2
    lob     Open
    DPRINT  "open2=%lx"
    move.l  d0,d6
    bne     .yesIdx
    ; ---------------------------------
    * No previous idx, create new
    move.l  #.name2,d1
    move.l  #MODE_NEWFILE,d2
    lob     Open
    DPRINT  "open3=%lx"
    move.l  d0,d6
    beq     .exit
    bra     .writeLen
.yesIdx
    ; ---------------------------------
    * Read txt length from the start
    lea     -4(sp),sp
    move.l  d6,d1   * file
    move.l  sp,d2   * dest
    moveq   #4,d3   * len
    lob     Read
    * Go back to start
	move.l	d6,d1
	moveq	#0,d2
	moveq	#-1,d3
	lob	Seek		
    ; ---------------------------------
    * Compare txt length and the length stored in idx
    * If same, exit
    cmp.l   (sp)+,d5
    ;;;;;;;;;;beq     .exit
.writeLen
    ; ---------------------------------
    ; Allocate 10k + 190k here, the last part for output
    move.l  #1024*200,d0
    move.l  #MEMF_PUBLIC!MEMF_CLEAR,d1
    jsr     getmem
    beq     .exit
    DPRINT  "AllocMem=%lx"
    move.l  d0,a4
    * Output buffer into a5
    lea     10*1024(a4),a5
    bsr     _getDos

    ; ---------------------------------
    * Write the txt length into the idx
    move.l  d5,-(sp)
    move.l  d6,d1   * file
    move.l  sp,d2   * source
    moveq   #4,d3   * len
    lob     Write
    DPRINT  "Write=%lx"
    addq    #4,sp   * pop
    cmp.l   #-1,d0
    beq     .exit
    * d0 = -1 on error

    ; ---------------------------------
    * Read a chunk of txt
    lea     -200(sp),sp
    move.l  sp,a3           * line buffer
    moveq   #0,d5           * txt file position
    DPRINT  "readLoop"
.readLoop
    move.l  d7,d1
    move.l  a4,d2
    move.l  #1024*10,d3
    lob     Read
    DPRINT  "Read=%lx"
    move    #$0f0,$dff180
    move.l  d0,d4
    beq     .stopLoop
    bmi     .stopLoop
    ; ---------------------------------
    ; Read bytes until lime change
    move.l  a4,a0           * start
    lea     (a0,d0),a1      * end
.lineLoop
    move.b  (a0)+,d0
    cmp.b   #13,d0
    beq     .cr
    cmp.b   #10,d0
    beq     .lf
    addq.l  #1,count1
    * Copy one char, check if data exhausted
    move.b  d0,(a3)+
.continue
    cmp.l   a1,a0
    blo     .lineLoop

    * Update global data offset
    add.l   #1024*10,d5
    * See if we got a full chunk last time, read more if so
    cmp.l   #1024*10,d4
    ;beq     .readLoop
    bra     .stopLoop

.lf
.cr
    * Skip lines that are not the title line
    cmp.b   #"/",(sp)
    bne     .next
 ;   move    #$f00,$dff180
    ; ---------------------------------
    ; A whole line read, null terminate
    clr.b   (a3)
 if DEBUG
    move.l  sp,d0
    DPRINT  "Line=%s"
 endif
    ; Convert to uppercase
    move.l  sp,a2
    moveq   #'a',d1
    moveq   #'z',d2
    move.b  #$df,d3
    bra     .ugo
.ucase1
    cmp.b	d1,d0
    blo 	.up1
    cmp.b	d2,d0
    bhi 	.up1
    and.b   d3,d0 * to upper
.up1
    move.b  d0,(a2)+
.ugo
    move.b  (a2),d0
    bne     .ucase1
.ucase2
    ; ---------------------------------
    ; Check for extension and remove it
    cmp.b   #"D",-1(a2)
    bne     .next
    cmp.b   #"I",-2(a2)
    bne     .next
    cmp.b   #"S",-3(a2)
    bne     .next
    cmp.b   #".",-4(a2)
    bne     .next
    clr.b   -4(a2)
 if DEBUG
    move.l  sp,d0
    DPRINT  "UCas=%s"
 endif
    ; ---------------------------------
    ; Process string in a0

    ; Calc offset to the line after the title line, 
    ; where the data is.
    ; a0 points to 13 or 10 on the previous title line here.
    move.l  a0,a2
    cmp.b   #10,(a2)
    bne     .skip1
    addq    #1,a2
.skip1
    * Offset relative to the work buffer
    sub.l   a4,a2
    * Offset relative to the STIL.txt file
    add.l   d5,a2
    
 if DEBUG
    move.l  a2,d0
    DPRINT  "offs=%ld"
 endif

    ; USE a2!
    move.l  sp,d0
    push    a0
    move.l  d0,a0
    bsr     fnv1
    pop     a0

    DPRINT  "hash=%lx"

    * d0 = hash into output
    move.l  d0,(a5)+
    * a2 = offset, store three bytes
    move.l  a2,d0
    swap    d0
    move.b  d0,(a5)+
    rol.l   #8,d0
    move.b  d0,(a5)+
    rol.l   #8,d0
    move.b  d0,(a5)+
    
.next
    ; ---------------------------------
    ; Start getting a new line into a3
    move.l  sp,a3
    ; Ignore 10 if the line ended with 13 ealier
    cmp.b   #10,(a0)
    bne     .continue
    addq    #1,a0
    bra     .continue

.stopLoop

    lea     200(sp),sp

    ; ---------------------------------
    ; Write index
    move.l  d6,d1   * file
    lea     10*1024(a4),a0
    move.l  a0,d2   * src
    move.l  a5,d3
    sub.l   a0,d3   * length
    lob     Write

.exit
    ; ---------------------------------
    DPRINT  "exit"
    move.l  a4,a0
    jsr     freemem
    bsr     _getDos
    move.l  d7,d1
    beq     .x1
    lob     Close
.x1 move.l  d6,d1
    beq     .x2
    lob     Close
.x2
    rts

.upperCaseD0
    cmp.b	#'a',d0
    blo 	.up11
    cmp.b	#'z',d0
    bhi 	.up11
    and.b   #$df,d0 * to uppper
.up11
    rts    	

.name1  dc.b "STIL.txt",0
.name2  dc.b "STIL.idx",0
    even



* In:
*   a0 = string with null termination
* Out:
*   d0 = fnv1 hash
fnv1:
    push    a2
    move.l  #$811c9dc5,d0 * hval
    move.l  #$01000193,d1 * prime
    lea     mulu_32,a2
    bra     .go
.loop
    jsr     (a2)
    eor.b   d2,d0
.go
    addq.l  #1,count3
    move.b  (a0)+,d2
    bne     .loop
.x     
    pop     a2
    rts

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

    * d0=koko
* d1=tyyppi
getmem:
	movem.l	d1/d3/a0/a1/a6,-(sp)
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

	rts

* a0=osoite
freemem:
	movem.l	d0/d1/a0/a1/a6,-(sp)
	move.l	a0,d0
	beq.b	.n
	move.l	-(a0),d0
	move.l	a0,a1
	move.l	4.w,a6
	lob	FreeMem
.n	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts


_getDos:
   pushm d0-a5
   move.l .dosb,d0
   bne  .y
	lea	.d(pc),a1
	move.l      4.w,a6
    lob     OldOpenLibrary
    move.l   d0,.dosb
.y
     move.l	d0,a6
    popm  d0-a5
    rts
.d  dc.b    "dos.library",0
    even
.dosb	dc.l	0


count1 dc.l    0
count2 dc.l    0
count3 dc.l    0















 if DEBUG
PRINTOUT_DEBUGBUFFER
	pea	debugDesBuf(pc)
	bsr.b PRINTOUT
	rts

PRINTOUT
	pushm	d0-d3/a0/a1/a5/a6
	move.l	output(pc),d1
	bne	.open

	* try tall window firsr
	move.l	#.bmb,d1
	move.l	#MODE_NEWFILE,d2
	move.l	dosbase,a6
	lob 	Open
	move.l	d0,output
	bne.b	.open
	* smaller next
	move.l	#.bmbSmall,d1
	move.l	#MODE_NEWFILE,d2
	move.l	dosbase,a6
	lob	Open
	move.l	d0,output
	bne.b	.open
	* still not open! exit
	bra.b	.x

.bmb		dc.b	"CON:20/10/350/490/HiP PS3M debug",0
.bmbSmall  	dc.b	"CON:20/10/350/190/HiP PS3M debug",0
    even


.open
	move.l	32+4(sp),a0

	moveq	#0,d3
	move.l	a0,d2
.p	addq	#1,d3
	tst.b	(a0)+
	bne.b	.p
	move.l	_DosBase,a6
 	lob	Write
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

	lea	debugDesBuf(pc),a3
	move.l	sp,a1	
 ifne SERIALDEBUG
    lea     .putCharSerial(pc),a2
 else
	lea	.putc(pc),a2	
 endif
	move.l	4.w,a6
	lob	RawDoFmt
	movem.l	(sp)+,d0-d7/a0-a3/a6
 ifeq SERIALDEBUG
	bsr	PRINTOUT_DEBUGBUFFER
 endif
    pushm   all
    bsr     _getDos
    moveq   #50,d1
;    lob     Delay
    popm    all

	rts	* teleport!
.putc	
	move.b	d0,(a3)+	
	rts
.putCharSerial
    ;_LVORawPutChar
    ; output char in d0 to serial
    move.l  4.w,a6
    jsr     -516(a6)
    rts

_DosBase	
dosbase		ds.l 1
output			ds.l 	1
debugDesBuf		ds.b	1024

 endif ;; DEBUG

