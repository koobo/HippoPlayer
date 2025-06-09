;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000


    STRUCTURE MD5Ctx,0
        ULONG  ctx_lo
        ULONG  ctx_hi
        ULONG  ctx_a
        ULONG  ctx_b
        ULONG  ctx_c
        ULONG  ctx_d
        STRUCT ctx_buffer,64
        STRUCT ctx_block,16*4
    LABEL MD5Ctx_SIZEOF


    REM
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
     EREM


* In:
*   a0 = context
MD5_Init:
    move.l  #$67452301,ctx_a(a0)
    move.l  #$efcdab89,ctx_b(a0)
    move.l  #$98badcfe,ctx_c(a0)
    move.l  #$10325476,ctx_d(a0)
    clr.l   ctx_lo(a0)
    clr.l   ctx_hi(a0)
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


;ilword	macro
;	ror	#8,\1
;	swap	\1
;	ror	#8,\1
;	endm

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

    rsreset
step_func       rs.b       1
step_rotation   rs.b       1
step_setget     rs.w       1
step_constant   rs.l       1
step_SIZEOF     rs.b       0

funcF = 0
funcG = 1
funcH = 2
funcI = 3



* In:
*   a0 = context
*   a1 = input data
*   d0 = input length
* Out:
*   a1 = input data, new position
MD5_Body:
    lea     (a1,d0.l),a3       * loop end
.loop
    ; ---------------------------------
    movem.l ctx_a(a0),d4/d5/d6/d7

    lea     .steps(pc),a2
    move.b  step_func(a2),d0
.stepLoop
    beq     .funcF
    subq.b  #1,d0
    beq     .funcG
    subq.b  #1,d0
    beq     .funcH
.funcI:
    ;(y) ^ ((x) | ~(z))
    move.l  d7,d0
    not.l   d0
    or.l    d5,d0
    eor.l   d6,d0
    bra     .funcDone

.funcF:
    ;((z) ^ ((x) & ((y) ^ (z))))
    move.l  d6,d0
    eor.l   d7,d0
    and.l   d5,d0
    eor.l   d7,d0
    bra     .funcDone

.funcG:
    ;((y) ^ ((z) & ((x) ^ (y))))
    move.l  d5,d0
    eor.l   d6,d0
    and.l   d7,d0
    eor.l   d6,d0
    bra     .funcDone

.funcH:
    ;(x) ^ (y) ^ (z)
    move.l  d5,d0
    eor.l   d6,d0
    eor.l   d7,d0

.funcDone:
    * d0 = result

    move.w  step_setget(a2),d1
    bmi.b   .set                    * unlikely branch
.get   
    add.l   ctx_block(a0,d1),d0
.cont
    add.l   step_constant(a2),d0
    add.l   d4,d0       * add ctx_a
    move.b  step_rotation(a2),d2
    rol.l   d2,d0
    add.l   d5,d0       * add ctx_b

* rotate the four 
* d4 = a
* d5 = b
* d6 = c
* d7 = d
    move.l   d7,d4
    move.l   d6,d7
    move.l   d5,d6
    move.l   d0,d5
    ; ---------------------------------
    lea     step_SIZEOF(a2),a2
    move.b  step_func(a2),d0
    bpl     .stepLoop
    ; ---------------------------------
    add.l   d4,ctx_a(a0)
    add.l   d5,ctx_b(a0)
    add.l   d6,ctx_c(a0)
    add.l   d7,ctx_d(a0)

    lea     64(a1),a1
    cmp.l   a3,a1
    bne     .loop

    rts

.set
    ext.w   d1
    move.l  (a1,d1),d2
    ilword  d2
    move.l  d2,ctx_block(a0,d1)
    add.l   d2,d0
    bra.b    .cont



* 64 steps
.steps:
         dc.b funcF 
         dc.b 7
         dc.w $8000!0<<2
         dc.l $d76aa478 

         dc.b funcF 
         dc.b 12
         dc.w $8000!1<<2
         dc.l $e8c7b756 

         dc.b funcF 
         dc.b 17
         dc.w $8000!2<<2
         dc.l $242070db 

         dc.b funcF 
         dc.b 22
         dc.w $8000!3<<2
         dc.l $c1bdceee 

         dc.b funcF 
         dc.b 7
         dc.w $8000!4<<2
         dc.l $f57c0faf 

         dc.b funcF 
         dc.b 12
         dc.w $8000!5<<2
         dc.l $4787c62a 

         dc.b funcF 
         dc.b 17
         dc.w $8000!6<<2
         dc.l $a8304613 

         dc.b funcF 
         dc.b 22
         dc.w $8000!7<<2
         dc.l $fd469501 

         dc.b funcF 
         dc.b 7
         dc.w $8000!8<<2
         dc.l $698098d8 

         dc.b funcF 
         dc.b 12
         dc.w $8000!9<<2
         dc.l $8b44f7af 

         dc.b funcF 
         dc.b 17
         dc.w $8000!10<<2
         dc.l $ffff5bb1 

         dc.b funcF 
         dc.b 22
         dc.w $8000!11<<2
         dc.l $895cd7be 

         dc.b funcF 
         dc.b 7
         dc.w $8000!12<<2
         dc.l $6b901122 

         dc.b funcF 
         dc.b 12
         dc.w $8000!13<<2
         dc.l $fd987193 

         dc.b funcF 
         dc.b 17
         dc.w $8000!14<<2
         dc.l $a679438e 

         dc.b funcF 
         dc.b 22
         dc.w $8000!15<<2
         dc.l $49b40821 

         dc.b funcG 
         dc.b 5
         dc.w 1<<2
         dc.l $f61e2562 

         dc.b funcG 
         dc.b 9
         dc.w 6<<2
         dc.l $c040b340 

         dc.b funcG 
         dc.b 14
         dc.w 11<<2
         dc.l $265e5a51 

         dc.b funcG 
         dc.b 20
         dc.w 0<<2
         dc.l $e9b6c7aa 

         dc.b funcG 
         dc.b 5
         dc.w 5<<2
         dc.l $d62f105d 

         dc.b funcG 
         dc.b 9
         dc.w 10<<2
         dc.l $02441453 

         dc.b funcG 
         dc.b 14
         dc.w 15<<2
         dc.l $d8a1e681 

         dc.b funcG 
         dc.b 20
         dc.w 4<<2
         dc.l $e7d3fbc8 

         dc.b funcG 
         dc.b 5
         dc.w 9<<2
         dc.l $21e1cde6 

         dc.b funcG 
         dc.b 9
         dc.w 14<<2
         dc.l $c33707d6 

         dc.b funcG 
         dc.b 14
         dc.w 3<<2
         dc.l $f4d50d87 

         dc.b funcG 
         dc.b 20
         dc.w 8<<2
         dc.l $455a14ed 

         dc.b funcG 
         dc.b 5
         dc.w 13<<2
         dc.l $a9e3e905 

         dc.b funcG 
         dc.b 9
         dc.w 2<<2
         dc.l $fcefa3f8 

         dc.b funcG 
         dc.b 14
         dc.w 7<<2
         dc.l $676f02d9 

         dc.b funcG 
         dc.b 20
         dc.w 12<<2
         dc.l $8d2a4c8a 

         dc.b funcH 
         dc.b 4
         dc.w 5<<2
         dc.l $fffa3942 

         dc.b funcH 
         dc.b 11
         dc.w 8<<2
         dc.l $8771f681 

         dc.b funcH 
         dc.b 16
         dc.w 11<<2
         dc.l $6d9d6122 

         dc.b funcH 
         dc.b 23
         dc.w 14<<2
         dc.l $fde5380c 

         dc.b funcH 
         dc.b 4
         dc.w 1<<2
         dc.l $a4beea44 

         dc.b funcH 
         dc.b 11
         dc.w 4<<2
         dc.l $4bdecfa9 

         dc.b funcH 
         dc.b 16
         dc.w 7<<2
         dc.l $f6bb4b60 

         dc.b funcH 
         dc.b 23
         dc.w 10<<2
         dc.l $bebfbc70 

         dc.b funcH 
         dc.b 4
         dc.w 13<<2
         dc.l $289b7ec6 

         dc.b funcH 
         dc.b 11
         dc.w 0<<2
         dc.l $eaa127fa 

         dc.b funcH 
         dc.b 16
         dc.w 3<<2
         dc.l $d4ef3085 

         dc.b funcH 
         dc.b 23
         dc.w 6<<2
         dc.l $04881d05 

         dc.b funcH 
         dc.b 4
         dc.w 9<<2
         dc.l $d9d4d039 

         dc.b funcH 
         dc.b 11
         dc.w 12<<2
         dc.l $e6db99e5 

         dc.b funcH 
         dc.b 16
         dc.w 15<<2
         dc.l $1fa27cf8 

         dc.b funcH 
         dc.b 23
         dc.w 2<<2
         dc.l $c4ac5665 

         dc.b funcI 
         dc.b 6
         dc.w 0<<2
         dc.l $f4292244 

         dc.b funcI 
         dc.b 10
         dc.w 7<<2
         dc.l $432aff97 

         dc.b funcI 
         dc.b 15
         dc.w 14<<2
         dc.l $ab9423a7 

         dc.b funcI 
         dc.b 21
         dc.w 5<<2
         dc.l $fc93a039 

         dc.b funcI 
         dc.b 6
         dc.w 12<<2
         dc.l $655b59c3 

         dc.b funcI 
         dc.b 10
         dc.w 3<<2
         dc.l $8f0ccc92 

         dc.b funcI 
         dc.b 15
         dc.w 10<<2
         dc.l $ffeff47d 

         dc.b funcI 
         dc.b 21
         dc.w 1<<2
         dc.l $85845dd1 

         dc.b funcI 
         dc.b 6
         dc.w 8<<2
         dc.l $6fa87e4f 

         dc.b funcI 
         dc.b 10
         dc.w 15<<2
         dc.l $fe2ce6e0 

         dc.b funcI 
         dc.b 15
         dc.w 6<<2
         dc.l $a3014314 

         dc.b funcI 
         dc.b 21
         dc.w 13<<2
         dc.l $4e0811a1 

         dc.b funcI 
         dc.b 6
         dc.w 4<<2
         dc.l $f7537e82 

         dc.b funcI 
         dc.b 10
         dc.w 11<<2
         dc.l $bd3af235 

         dc.b funcI 
         dc.b 15
         dc.w 2<<2
         dc.l $2ad7d2bb 

         dc.b funcI 
         dc.b 21
         dc.w 9<<2
         dc.l $eb86d391 

         dc   -1 ; END
