;APS00000088000000880000008800000088000000880000008800000088000000880000008800000088
; Inspired by https://github.com/calebstewart/md5/blob/main/md5.cpp

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

    STRUCTURE MD5Ctx,0
        ULONG  ctx_a
        ULONG  ctx_b
        ULONG  ctx_c
        ULONG  ctx_d
        STRUCT ctx_buffer,64
        STRUCT ctx_block,16*4
        ULONG  ctx_lo
        ULONG  ctx_hi
        * Pairs of (block address, constant) for steps g,h,i
        STRUCT ctx_stepsGHI,3*16*8
    LABEL MD5Ctx_SIZEOF


	ifd TEST
main:
    lea     .ctx,a0
    jsr     MD5_Init

    lea     .ctx,a0
    lea     input,a1
    move.l  #inputE-input,d0
    jsr      MD5_Update

    lea     .ctx,a0
    jsr     MD5_Final
    rts

.ctx    ds.b    MD5Ctx_SIZEOF

input
    incbin  "README.md"
;	dc.b " ",10
;	incbin	"actimpls.mod"	
;	incbin	"outofsilence"
inputE
    even
     endif


* In:
*   a0 = context
MD5_Init:
    move.l  #$67452301,ctx_a(a0)
    move.l  #$efcdab89,ctx_b(a0)
    move.l  #$98badcfe,ctx_c(a0)
    move.l  #$10325476,ctx_d(a0)
    clr.l   ctx_lo(a0)
    clr.l   ctx_hi(a0)

    * Prepare block addressess into a table
    * for steps g,h,i
    lea     MD5_Body\.stepsG(pc),a1
    lea     MD5_Body\.stepBlockOffsetsGHI(pc),a3
    lea     ctx_stepsGHI(a0),a4
    moveq   #16+16+16-1,d0
    moveq   #0,d2
.1
    move.b  (a3)+,d2
    lea     ctx_block(a0,d2),a2
    move.l  a2,(a4)+        * store address
    move.l  (a1)+,(a4)+     * store constant
    dbf     d0,.1
    rts

* In:
*   a0 = context
*   a1 = input data
*   d0 = input data size
MD5_Update:
    move.l  ctx_lo(a0),d1
    move.l  d1,d2
    * d1 = saved_lo
    add.l   d0,d2
    and.l   #$1fffffff,d2
    * d2 = (saved_lo + size) & 0x1fffffff
    move.l  d2,ctx_lo(a0)

    cmp.l   d1,d2
    bhs     .1
    * d2 < d1 (saved_lo)
    addq.l  #1,ctx_hi(a0)
.1
    ; ctx->hi += size >> 29;
    moveq   #29,d3
    move.l  d0,d4
    lsr.l   d3,d4
    add.l   d4,ctx_hi(a0)

	* used = saved_lo & 0x3f;
    and.l   #$3f,d1
    beq     .2
    * if (used){
        moveq   #64,d3
        sub.l   d1,d3
        * d3 = free - used
        cmp.l   d3,d0
        bhs     .22
        * size < free
            * memcpy(&ctx->buffer[used], data, size);
            lea     ctx_buffer(a0,d1),a2
            subq    #1,d0
            bmi     .cp1s
.cp1        move.b  (a1)+,(a2)+
            dbf     d0,.cp1
.cp1s
            rts
.22
		* memcpy(&ctx->buffer[used], data, free);
        move.l  d3,d4
        lea     ctx_buffer(a0,d1),a2
        subq    #1,d3
        bmi     .cp2s
.cp2    move.b  (a1)+,(a2)+
        dbf     d3,.cp2
.cp2s
		* data = (unsigned char *)data + free;
        add.l   d4,a1
		* size -= free;
        sub.l   d4,d0
        pushm   d0/a1
        lea     ctx_buffer(a0),a1
        moveq   #64,d0
        bsr     MD5_Body
        popm    d0/a1
    * }
.2
    cmp.l   #64,d0
    blo     .3
	* if (size >= 64) {
    push    d0
    * data = MD5_Body(ctx, data, size & ~(unsigned long)0x3f);
    and.l   #~$3f,d0
    bsr     MD5_Body
    * data pointer in a1 changed
    pop     d0
    and.l   #$3f,d0
.3
    ; memcpy(ctx->buffer, data, size);
    subq    #1,d0
    bmi     .skip
    lea     ctx_buffer(a0),a2
.cp move.b  (a1)+,(a2)+
    dbf     d0,.cp
.skip
    rts



* In:
*   a0 = context
* Out:
*   
MD5_Final:
	* used = ctx->lo & 0x3f;
    moveq   #$3f,d0
    and.l   ctx_lo(a0),d0

	* ctx->buffer[used++] = 0x80;
    move.b  #$80,ctx_buffer(a0,d0);
    addq.l  #1,d0
    
	* free = 64 - used;
    moveq   #64,d1
    sub.l   d0,d1


	* if (free < 8) {
    cmp.w   #8,d1
    bhs     .1
		* memset(&ctx->buffer[used], 0, free);
        lea     ctx_buffer(a0,d0),a1
        move    d1,d2
        subq    #1,d2
        bmi     .cs
.c      clr.b   (a1)+
        dbf     d2,.c
.cs
		* MD5_Body(ctx, ctx->buffer, 64);
        lea     ctx_buffer(a0),a1
        moveq   #64,d0
        bsr     MD5_Body
		* used = 0;
	    * free = 64;
        moveq   #0,d0
        moveq   #64,d1
.1
    
	* memset(&ctx->buffer[used], 0, free - 8);
    lea     ctx_buffer(a0,d0),a1
    move    d1,d2
    subq    #8,d2
    subq    #1,d2
    bmi     .c2s
.c2 clr.b   (a1)+
    dbf     d2,.c2
.c2s
    move.l  ctx_lo(a0),d0
    lsl.l   #3,d0
    move.l  d0,ctx_lo(a0)

    move.b  d0,ctx_buffer+56(a0)
    lsr.l   #8,d0
    move.b  d0,ctx_buffer+57(a0)
    lsr.l   #8,d0
    move.b  d0,ctx_buffer+58(a0)
    lsr.l   #8,d0
    move.b  d0,ctx_buffer+59(a0)

    move.l  ctx_hi(a0),d0
    move.b  d0,ctx_buffer+60(a0)
    lsr.l   #8,d0
    move.b  d0,ctx_buffer+61(a0)
    lsr.l   #8,d0
    move.b  d0,ctx_buffer+62(a0)
    lsr.l   #8,d0
    move.b  d0,ctx_buffer+63(a0)

    lea     ctx_buffer(a0),a1
    moveq   #64,d0
    bsr     MD5_Body

    movem.l ctx_a(a0),d0-d3
    ilword  d0
    ilword  d1
    ilword  d2
    ilword  d3
    rts


; 21840 ms - reference
; 21670 ms - h trick = -170ms = 0.7%
; 21360 ms - direct block address = -471ms = 2.2%

; h trick: 20050 ms to 19900 ms = 0.75%
; attributed horror v2.64:  11087 ms
; latest                    8039 ms = 27.5%

* In:
*   a0 = context
*   a1 = input data
*   d0 = input length
* Out:
*   a1 = input data, new position
MD5_Body:

; \1 a
; \2 b
; \3 c
; \4 d
; \5 tmp1 - output
; \6 tmp2
stepFa macro 
    move.l  (a1)+,\6    * read input

    ;((z) ^ ((x) & ((y) ^ (z))))
    move.l  \3,\5       * mix to \5
    ror.w   #8,\6       * ilword part 1
    eor.l   \4,\5       * \5 = c ^ d 
    swap    \6          * ilword part 2
    ror.w   #8,\6       * ilword part 3
    and.l   \2,\5       * \5 = (c ^ d) & b
    move.l  \6,(a6)+    * write to block buffer
    eor.l   \4,\5       * \5 = ((c ^ d) & b) ^ d

    add.l   \6,\5      * add block value
    add.l   \1,\5      * add ctx_a
    add.l   (a2)+,\5   * add constant
    endm

; \1 a
; \2 b
; \3 c - output
; \4 d
; \5 tmp2
stepFb macro 
    move.l  (a1)+,\5    * read input

    ;((z) ^ ((x) & ((y) ^ (z))))
    ror.w   #8,\5       * ilword part 1
    eor.l   \4,\3       * 3 = c ^ d 
    swap    \5          * ilword part 2
    ror.w   #8,\5       * ilword part 3
    and.l   \2,\3       * 3 = (c ^ d) & b
    move.l  \5,(a6)+    * write to block buffer
    eor.l   \4,\3       * 3 = ((c ^ d) & b) ^ d

    add.l   \5,\3      * add block value
    add.l   \1,\3      * add ctx_a
    add.l   (a2)+,\3   * add constant
    endm

; \1 a
; \2 b
; \3 c
; \4 d
; \5 tmp - output
stepGa macro 
    move.l  (a2)+,a4   * read block address

    ;((y) ^ ((z) & ((x) ^ (y))))
    move.l  \2,\5
    eor.l   \3,\5       * \5 = b ^ c
    and.l   \4,\5       * \5 = (b ^ c) & d
    eor.l   \3,\5       * \5 = ((b ^ c) & d) ^ c

    add.l   \1,\5      * add ctx_a
    add.l   (a4),\5    * add block value
    add.l   (a2)+,\5   * add constant
    endm

; \1 a
; \2 b - overwritten output
; \3 c
; \4 d
stepGb macro 
    move.l  (a2)+,a4   * read block address

    ;((y) ^ ((z) & ((x) ^ (y))))
;    move.l  \2,\5
    eor.l   \3,\2       * \2 = b ^ c
    and.l   \4,\2       * \2 = (b ^ c) & d
    eor.l   \3,\2       * \2 = ((b ^ c) & d) ^ c

    add.l   \1,\2      * add ctx_a
    add.l   (a4),\2    * add block value
    add.l   (a2)+,\2   * add constant
    endm

; \1 a
; \2 b
; \3 c
; \4 d
; \5 tmp - output
; \6 tmp 2 - intermediate result
stepHa macro 
    move.l  (a2)+,a4   * read block address

    ;(x) ^ (y) ^ (z)
    move.l  \2,\5       
    eor.l   \3,\5       * \5 = b ^ c
    move.l  \5,\6       * \6 = store for stepHb
    eor.l   \4,\5       * \5 = (b ^ c) ^ d

    add.l   \1,\5      * add ctx_a
    add.l   (a4),\5    * add block value
    add.l   (a2)+,\5   * add constant
    endm

; \1 a
; \2 b
; \3 c
; \4 d
; \5 tmp - output
stepHb macro 
    move.l  (a2)+,a4   * read block address

    ; use stepHa intermediate result in \5
    eor.l   \2,\5       * \5 = (b ^ c) ^ d

    add.l   \1,\5      * add ctx_a
    add.l   (a4),\5    * add block value
    add.l   (a2)+,\5   * add constant
    endm

; \1 a
; \2 b
; \3 c
; \4 d
; \5 tmp - out
stepIa macro 
    move.l  (a2)+,a4   * read block address

    ;(y) ^ ((x) | ~(z))
    move.l  \4,\5
    not.l   \5          * \5 = ~d
    or.l    \2,\5       * \5 = (~d) | b
    eor.l   \3,\5       * \5 = ((~d) | b) ^ c

    add.l   \1,\5      * add ctx_a
    add.l   (a4),\5    * add block value
    add.l   (a2)+,\5   * add constant
    endm

; \1 a
; \2 b
; \3 c
; \4 d - overwritten, out
stepIb macro 
    move.l  (a2)+,a4   * read block address

    ;(y) ^ ((x) | ~(z))
    not.l   \4          * \4 = ~d
    or.l    \2,\4       * \4 = (~d) | b
    eor.l   \3,\4       * \4 = ((~d) | b) ^ c

    add.l   \1,\4      * add ctx_a
    add.l   (a4),\4    * add block value
    add.l   (a2)+,\4   * add constant
    endm

    ; ---------------------------------
    lea     (a1,d0.l),a3       * loop end
.loop
    ; ---------------------------------
    movem.l ctx_a(a0),d4/d5/d6/d7
    lea     .stepsF(pc),a2
    ; Copy 64 bytes here 
    lea     ctx_block(a0),a6
    ; ---------------------------------
    moveq   #16/4-1,d3
.stepLoopF:
    *       A  B  C  D  t1 t2
    stepFa  d4,d5,d6,d7,d0,d1
    rol.l   #7,d0      * <<< 7
    add.l   d5,d0      * add ctx_b, b = new sum
    * d0 = new b - goes to b
    * d5 = old b - goes to c
    ; ---------------------------------
    *       A  B  C  D  t1 t2
    stepFa  d7,d0,d5,d6,d2,d1
    swap    d2         * <<< 12
    ror.l   #4,d2
    add.l   d0,d2      * tmp += b
    * d2 = new b - goes to b    
    * d0 = old b - goes to c
    ; ---------------------------------
    *       A  B  C  D  t1 t2
    stepFa  d6,d2,d0,d5,d7,d1
    swap    d7         * <<< 17
    rol.l   #1,d7
    add.l   d2,d7      * tmp += b
    * d7 = new b - goes to b    
    * d2 = old b - goes to c
    ; ---------------------------------
    move.l  d7,d6      * rotate: c = b 
    move.l  d2,d7      * rotate: d = c
    *       A  B  C  D  t1
    stepFb  d5,d6,d2,d0,d1
    swap    d2         * <<< 22
    rol.l   #6,d2      * <<<
    move.l  d6,d5      * new b
    add.l   d2,d5      * rotate: b = new sum
    move.l  d0,d4      * rotate: a = d
    ; ---------------------------------
    dbf     d3,.stepLoopF
    ; ---------------------------------
    lea     ctx_stepsGHI(a0),a2
    moveq   #16/4-1,d3
.stepLoopG:
    *       A  B  C  D  t 
    stepGa  d4,d5,d6,d7,d0
    rol.l   #5,d0      * <<< 5
    add.l   d5,d0      * tmp += b
    * d0 = new b - goes to b
    * d5 = old b - goes to c
    ; ---------------------------------
    *       A  B  C  D  t
    stepGa  d7,d0,d5,d6,d2
    swap    d2         * <<< 9
    ror.l   #7,d2
    add.l   d0,d2      * tmp += b
    * d2 = new b - goes to b    
    * d0 = old b - goes to c
    ; ---------------------------------
    *       A  B  C  D  t
    stepGa  d6,d2,d0,d5,d7
    swap    d7         * <<< 14
    ror.l   #2,d7
    add.l   d2,d7      * tmp += b
    * d7 = new b - goes to b    
    * d2 = old b - goes to c
    ; ---------------------------------
    move.l  d7,d6      * rotate: c = b 
    *       A  B  C  D 
    stepGb  d5,d7,d2,d0
    swap    d7         * <<< 20
    rol.l   #4,d7      * <<<
    move.l  d6,d5      * new b
    add.l   d7,d5      * rotate: b = new sum
    move.l  d2,d7      * rotate: d = c
    move.l  d0,d4      * rotate: a = d
    ; ---------------------------------
    dbf     d3,.stepLoopG
    ; ---------------------------------
    moveq   #16/4-1,d3
.stepLoopH:
    *       A  B  C  D  t  t2
    stepHa  d4,d5,d6,d7,d0,d2
    rol.l   #4,d0      * <<< 4
    add.l   d5,d0      * tmp += b
    * d0 = new b - goes to b
    * d5 = old b - goes to c
    ; ---------------------------------
    *       A  B  C  D  t
    stepHb  d7,d0,d5,d6,d2
    swap    d2         * <<< 11
    ror.l   #5,d2
    add.l   d0,d2      * tmp += b
    * d2 = new b - goes to b    
    * d0 = old b - goes to c
    ; ---------------------------------
    *       A  B  C  D  t  t2
    stepHa  d6,d2,d0,d5,d7,d4
    swap    d7         * <<< 16
    add.l   d2,d7      * tmp += b
    * d7 = new b - goes to b    
    * d2 = old b - goes to c
    ; ---------------------------------
    *       A  B  C  D  t
    stepHb  d5,d7,d2,d0,d4
    swap    d4         * <<< 23
    rol.l   #7,d4      * <<<
    move.l  d7,d5      * new b
    move.l  d7,d6      * rotate: c = b 
    add.l   d4,d5      * rotate: b = new sum
    move.l  d2,d7      * rotate: d = c
    move.l  d0,d4      * rotate: a = d
    ; ---------------------------------
    dbf     d3,.stepLoopH
    ; ---------------------------------
    moveq   #16/4-1,d3
.stepLoopI:
    *       A  B  C  D  t
    stepIa  d4,d5,d6,d7,d0
    rol.l   #6,d0      * tmp <<< 6
    add.l   d5,d0      * tmp += b
    * d0 = new b - goes to b
    * d5 = old b - goes to c
    ; ---------------------------------
    *       A  B  C  D  t
    stepIa  d7,d0,d5,d6,d2
    swap    d2         * <<< 10
    ror.l   #6,d2
    add.l   d0,d2      * tmp += b
    * d2 = new b - goes to b    
    * d0 = old b - goes to c
    ; ---------------------------------
    *       A  B  C  D  t
    stepIa  d6,d2,d0,d5,d7
    swap    d7         * <<< 15
    ror.l   #1,d7
    add.l   d2,d7      * tmp += b
    * d7 = new b - goes to b    
    * d2 = old b - goes to c
    ; ---------------------------------
    move.l  d0,d4      * rotate: a = d
    *       A  B  C  D 
    stepIb  d5,d7,d2,d0
    swap    d0         * <<< 21
    rol.l   #5,d0      * <<<
    move.l  d7,d5      * new b
    move.l  d7,d6      * rotate: c = b 
    add.l   d0,d5      * rotate: b = new sum
    move.l  d2,d7      * rotate: d = c
    ; ---------------------------------
    dbf     d3,.stepLoopI
    ; ---------------------------------
    add.l   d4,ctx_a(a0)
    add.l   d5,ctx_b(a0)
    add.l   d6,ctx_c(a0)
    add.l   d7,ctx_d(a0)
    ; ---------------------------------
    cmp.l   a3,a1      * check if end of last block
    bne     .loop
    rts



* 64 steps
.steps:
.stepsF:
         dc.l $d76aa478
         dc.l $e8c7b756
         dc.l $242070db
         dc.l $c1bdceee
         dc.l $f57c0faf
         dc.l $4787c62a
         dc.l $a8304613
         dc.l $fd469501
         dc.l $698098d8
         dc.l $8b44f7af
         dc.l $ffff5bb1
         dc.l $895cd7be
         dc.l $6b901122
         dc.l $fd987193
         dc.l $a679438e
         dc.l $49b40821
.stepsG:         
         dc.l $f61e2562 
         dc.l $c040b340 
         dc.l $265e5a51 
         dc.l $e9b6c7aa 
         dc.l $d62f105d 
         dc.l $02441453 
         dc.l $d8a1e681 
         dc.l $e7d3fbc8 
         dc.l $21e1cde6 
         dc.l $c33707d6 
         dc.l $f4d50d87 
         dc.l $455a14ed 
         dc.l $a9e3e905 
         dc.l $fcefa3f8 
         dc.l $676f02d9 
         dc.l $8d2a4c8a 
.stepsH:         
         dc.l $fffa3942 
         dc.l $8771f681 
         dc.l $6d9d6122 
         dc.l $fde5380c 
         dc.l $a4beea44 
         dc.l $4bdecfa9 
         dc.l $f6bb4b60 
         dc.l $bebfbc70 
         dc.l $289b7ec6 
         dc.l $eaa127fa 
         dc.l $d4ef3085 
         dc.l $04881d05 
         dc.l $d9d4d039 
         dc.l $e6db99e5 
         dc.l $1fa27cf8 
         dc.l $c4ac5665 
.stepsI:         
         dc.l $f4292244 
         dc.l $432aff97 
         dc.l $ab9423a7 
         dc.l $fc93a039 
         dc.l $655b59c3 
         dc.l $8f0ccc92 
         dc.l $ffeff47d 
         dc.l $85845dd1 
         dc.l $6fa87e4f 
         dc.l $fe2ce6e0 
         dc.l $a3014314 
         dc.l $4e0811a1 
         dc.l $f7537e82 
         dc.l $bd3af235 
         dc.l $2ad7d2bb 
         dc.l $eb86d391 

.stepBlockOffsetsGHI:
         dc.b 1<<2
         dc.b 6<<2
         dc.b 11<<2
         dc.b 0<<2
         dc.b 5<<2
         dc.b 10<<2
         dc.b 15<<2
         dc.b 4<<2
         dc.b 9<<2
         dc.b 14<<2
         dc.b 3<<2
         dc.b 8<<2
         dc.b 13<<2
         dc.b 2<<2
         dc.b 7<<2
         dc.b 12<<2
         dc.b 5<<2
         dc.b 8<<2
         dc.b 11<<2
         dc.b 14<<2
         dc.b 1<<2
         dc.b 4<<2
         dc.b 7<<2
         dc.b 10<<2
         dc.b 13<<2
         dc.b 0<<2
         dc.b 3<<2
         dc.b 6<<2
         dc.b 9<<2
         dc.b 12<<2
         dc.b 15<<2
         dc.b 2<<2
         dc.b 0<<2
         dc.b 7<<2
         dc.b 14<<2
         dc.b 5<<2
         dc.b 12<<2
         dc.b 3<<2
         dc.b 10<<2
         dc.b 1<<2
         dc.b 8<<2
         dc.b 15<<2
         dc.b 6<<2
         dc.b 13<<2
         dc.b 4<<2
         dc.b 11<<2
         dc.b 2<<2
         dc.b 9<<2
