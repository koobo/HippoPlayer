;APS00000088000000880000008800000088000000880000008800000088000000880000008800000088
; Asm port of https://github.com/easyaspi314/xxhash-clean/blob/master/xxhash32-ref.c

  ifnd __VASM
	incdir	include:
	include exec/types.i
	include mucro.i

ilword	macro
	ror	#8,\1
	swap	\1
	ror	#8,\1
	endm

TEST=1
  endif

	ifd TEST

TEST_DATA_SIZE = 101

ASSERT macro
    cmp.l   #\1,d0
    beq.b   *+4
    illegal
    endm

main:
    bsr     .initTestData

    lea     test_data,a0
    move.l  #0,d0
    moveq   #0,d1
    bsr     XXH32
    ASSERT  $02CC5D05

    lea     test_data,a0
    move.l  #0,d0
    move.l  #PRIME32_1,d1
    bsr     XXH32
    ASSERT  $36B78AE7

    lea     test_data,a0
    move.l  #1,d0
    moveq   #0,d1
    bsr     XXH32
    ASSERT  $B85CBEE5

    lea     test_data,a0
    move.l  #1,d0
    move.l  #PRIME32_1,d1
    bsr     XXH32
    ASSERT  $D5845D64

    lea     test_data,a0
    move.l  #14,d0
    moveq   #0,d1
    bsr     XXH32
    ASSERT  $E5AA0AB4

    lea     test_data,a0
    move.l  #14,d0
    move.l  #PRIME32_1,d1
    bsr     XXH32
    ASSERT  $4481951D

    lea     test_data,a0
    move.l  #TEST_DATA_SIZE,d0
    moveq   #0,d1
    bsr     XXH32
    ASSERT  $1F1AA412

    lea     test_data,a0
    move.l  #TEST_DATA_SIZE,d0
    move.l  #PRIME32_1,d1
    bsr     XXH32
    ASSERT  $498EC8E2
    rts

.initTestData:
    lea     test_data,a0
    moveq   #0,d7
    move.l  #PRIME32_1,d6
.l
    move.l  d6,d2
    rol.l   #8,d2
    move.b  d2,(a0)+

    move.l  d6,d0
    move.l  d6,d1
    bsr     xxh_mulu_32
    move.l  d0,d6

    addq.l  #1,d7
    cmp.l   #TEST_DATA_SIZE,d7
    bne     .l
    rts

test_data   ds.b    TEST_DATA_SIZE
    even


input
    incbin  "README.md"
inputE
    even

    endif



PRIME32_1 = $9E3779B1
PRIME32_2 = $85EBCA77
PRIME32_3 = $C2B2AE3D
PRIME32_4 = $27D4EB2F
PRIME32_5 = $165667B1


* In:
*   d0 = input data
*   \1 = accumulator
* Out:
*   \1 = new accumulator
XXH32_round  macro
    move.l  #PRIME32_2,d1

;    bsr     xxh_mulu_32
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
;
    add.l   d0,\1   
    swap    \1
    ror.l   #3,\1
    move.l  \1,d1
    move.l  #PRIME32_1,d0

;    bsr     xxh_mulu_32
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
;
    move.l  d0,\1
    endm


* In:
*   a0 = input data
*   d0 = input data length
*   d1 = input seed
XXH32:
    rsreset
.inputData      rs.l    1
.inputLength    rs.l    1   
.seed           rs.l    1   
.acc1           rs.l    1
.acc2           rs.l    1
.acc3           rs.l    1
.acc4           rs.l    1
.offset         rs.l    1   
.hash           rs.l    1
.remaining      rs.l    1
.data_sizeof    rs.b    0

    moveq   #.data_sizeof/4-1,d2
.1  clr.l   -(sp)
    dbf     d2,.1
    move.l  sp,a5

    move.l  a0,.inputData(a5)
    move.l  d0,.inputLength(a5)
    move.l  d1,.seed(a5)

    move.l  .inputLength(a5),.remaining(a5)

    cmp.l   #16,.remaining(a5)
    blo     .2

    * Initialize accumulators
    move.l  .seed(a5),d0
    add.l   #PRIME32_1,d0
    add.l   #PRIME32_2,d0
    move.l  d0,.acc1(a5)

    move.l  .seed(a5),d0
    add.l   #PRIME32_2,d0
    move.l  d0,.acc2(a5)

    move.l  .seed(a5),.acc3(a5)

    move.l  .seed(a5),d0
    sub.l   #PRIME32_1,d0
    move.l  d0,.acc4(a5)

    movem.l  .acc1(a5),d4-d7

.mainLoop
    move.l  (a0)+,d0
    ilword  d0
    XXH32_round d4

    move.l  (a0)+,d0
    ilword  d0
    XXH32_round d5

    move.l  (a0)+,d0
    ilword  d0
    XXH32_round d6

    move.l  (a0)+,d0
    ilword  d0
    XXH32_round d7

    sub.l   #16,.remaining(a5)
    cmp.l   #16,.remaining(a5)
    bhs     .mainLoop

    movem.l  d4-d7,.acc1(a5)

    * Hash
    move.l  .acc1(a5),d0
    rol.l   #1,d0
    move.l  .acc2(a5),d1
    rol.l   #7,d1
    add.l   d1,d0
    move.l  .acc3(a5),d1
    rol.l   #8,d1
    rol.l   #4,d1
    add.l   d1,d0
    move.l  .acc4(a5),d1
    swap    d1
    rol.l   #2,d1
    add.l   d1,d0
    move.l  d0,.hash(a5)
    bra     .3
.2
    * Not enough data for the main loop
    move.l  .seed(a5),d0
    add.l   #PRIME32_5,d0
    move.l  d0,.hash(a5)
.3

    * Main loop over

    move.l  .inputLength(a5),d0
    add.l   d0,.hash(a5)
    
    * Remaining >= 4

.remLoop1
    cmp.l   #4,.remaining(a5)
    blo     .4

    move.l  (a0)+,d0
    ilword  d0
    move.l  #PRIME32_3,d1
    bsr     xxh_mulu_32
    add.l   d0,.hash(a5)
    move.l  .hash(a5),d0
    moveq   #17,d1
    rol.l   d1,d0
    move.l  #PRIME32_4,d1
    bsr     xxh_mulu_32
    move.l  d0,.hash(a5)
    subq.l  #4,.remaining(a5)
    bra     .remLoop1
.4

    * Remaining != 0

.remLoop2
    tst.l   .remaining(a5)
    beq     .5

    moveq   #0,d0
    move.b  (a0)+,d0
    move.l  #PRIME32_5,d1
    bsr     xxh_mulu_32
    add.l   d0,.hash(a5)
    move.l  .hash(a5),d0
    moveq   #11,d1
    rol.l   d1,d0
    move.l  #PRIME32_1,d1
    bsr     xxh_mulu_32
    move.l  d0,.hash(a5)
    subq.l  #1,.remaining(a5)
    bra     .remLoop2
.5
    * Avalanche

    move.l  .hash(a5),d0
    moveq   #15,d1
    lsr.l   d1,d0
    eor.l   d0,.hash(a5)

    move.l  .hash(a5),d0
    move.l  #PRIME32_2,d1
    bsr     xxh_mulu_32
    move.l  d0,.hash(a5)

    move.l  .hash(a5),d0
    moveq   #13,d1
    lsr.l   d1,d0
    eor.l   d0,.hash(a5)

    move.l  .hash(a5),d0
    move.l  #PRIME32_3,d1
    bsr     xxh_mulu_32
    move.l  d0,.hash(a5)

    move.l  .hash(a5),d0
    moveq   #16,d1
    lsr.l   d1,d0
    eor.l   d0,.hash(a5)

    move.l  .hash(a5),d0

    lea     .data_sizeof(sp),sp
    rts


* xxh_mulu_32 --- d0 = d0*d1
* scracth: d2,d3
xxh_mulu_32:	
    ;movem.l	d2/d3,-(sp)
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
	;movem.l	(sp)+,d2/d3
	rts	
