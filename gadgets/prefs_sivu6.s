pslider2	dc.l sIPULI
	dc.w 402-20+2,121+8+8-2,70-20,12,7,9,3
	dc.l pslider2gr,0,pslider2t,0,pslider2s
	dc.w 0
	dc.l 0
pslider2gr	dc.w 0,0,11,9,2
	dc.l pslider2im
	dc.b 3,0
	dc.l 0
pslider2t	dc.b 1,0,1,0
	dc.w -144+8+8+2,2
	dc.l 0,pslider2tx,0
pslider2tx	dc.b "TFMX rate",0
	even
pslider2s	dc.w 2,0,0,0,0
	dc.w 0,0,0,0,0,0
sIPULI	dc.l nAMISKA1 ;dc.l sIPULI2
	dc.w 180,37,50,12,7,9,3
	dc.l sIPULIgr,0,sIPULIt,0,sIPULIs
	dc.w 0
	dc.l 0
sIPULIgr	dc.w 2,0,11,9,2
	dc.l sIPULIim
	dc.b 3,0
	dc.l 0
sIPULIt	dc.b 1,0,1,0
	dc.w -164,2
	dc.l 0,sIPULItx,0
sIPULItx	dc.b "Sample buffer..",0
	even
sIPULIs	dc.w 2,5461,65535,0,0
	dc.w 0,0,0,0,0,0
;sIPULI2	dc.l nAMISKA1
;	dc.w 18,63,212,12,7,9,3
;	dc.l sIPULI2gr,0,sIPULI2t,0,sIPULI2s
;	dc.w 0
;	dc.l 0
;sIPULI2gr	dc.w 0,0,11,9,2
;	dc.l sIPULI2im
;	dc.b 3,0
;	dc.l 0
;sIPULI2t	dc.b 1,0,1,0
;	dc.w -2,-12
;	dc.l 0,sIPULI2tx,0
;sIPULI2tx	dc.b "Force sample rate..",0
;	even
;sIPULI2s	dc.w 2,0,65535,0,0
;	dc.w 0,0,0,0,0,0
nAMISKA1	dc.l nAMISKA2
	dc.w 202,79-28,28,12,3,1,1
	dc.l 0,0,nAMISKA1t,0,0
	dc.w 0
	dc.l 0
nAMISKA1t	dc.b 1,0,1,0
	dc.w -186,2
	dc.l 0,nAMISKA1tx,0
nAMISKA1tx	
    ;dc.b "Cybercalibration.......",0
    dc.b "Sample 14-bit output...",0
	even
nAMISKA2	dc.l nAMISKA3
	dc.w 406,37,28,12,3,1,1
	dc.l 0,0,nAMISKA2t,0,0
	dc.w 0
	dc.l 0
nAMISKA2t	dc.b 1,0,1,0
	dc.w -148,2
	dc.l 0,nAMISKA2tx,0
nAMISKA2tx	dc.b "MPEGA quality.....",0
	even
nAMISKA3	dc.l nAMISKA4
	dc.w 406,51,28,12,3,1,1
	dc.l 0,0,nAMISKA3t,0,0
	dc.w 0
	dc.l 0
nAMISKA3t	dc.b 1,0,1,0
	dc.w -148,2
	dc.l 0,nAMISKA3tx,0
nAMISKA3tx	dc.b "MPEGA freq. div...",0
	even
nAMISKA4	dc.l nAMISKA5
	dc.w 406,79-8,28,12,3,1,1
	dc.l 0,0,nAMISKA4t,0,0
	dc.w 0
	dc.l 0
nAMISKA4t	dc.b 1,0,1,0
	dc.w -148,2
	dc.l 0,nAMISKA4tx,0
nAMISKA4tx	dc.b "MED output mode...",0
	even
nAMISKA5	dc.l 0
	dc.w 260+120+8-4*8,107-12+12-8+2,174-120-8+4*8,12,7,9,3
	dc.l nAMISKA5gr,0,nAMISKA5t,0,nAMISKA5s
	dc.w 0
	dc.l 0
nAMISKA5gr	dc.w 0,0,11,9,2
	dc.l nAMISKA5im
	dc.b 3,0
	dc.l 0
nAMISKA5t	dc.b 1,0,1,0
	dc.w -2-120-8+4*8,0
	dc.l 0,nAMISKA5tx,0
nAMISKA5tx	dc.b "Rate",0
	even
nAMISKA5s	dc.w 2,0,0,0,0
	dc.w 0,0,0,0,0,0
