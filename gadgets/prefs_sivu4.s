smode1	dc.l smode2
	dc.w 304,37,130,12,0,1,1
	dc.l 0,0,smode1t,0,0
	dc.w 0
	dc.l 0
smode1t	dc.b 1,0,1,0
	dc.w -288,2
	dc.l 0,smode1tx,0
smode1tx	dc.b "Play mode..........................",0
	even
smode2	dc.l jommo
	dc.w 364,51,70,12,0,1,1
	dc.l 0,0,smode2t,0,0
	dc.w 0
	dc.l 0
smode2t	dc.b 1,0,1,0
	dc.w -348,2
	dc.l 0,smode2tx,0
smode2tx	dc.b "Priority...................................",0
	even
jommo	dc.l pslider1
	dc.w 364,65,70,12,0,1,1
	dc.l 0,0,jommot,0,0
	dc.w 0
	dc.l 0
jommot	dc.b 1,0,1,0
	dc.w -348,2
	dc.l 0,jommotx,0
jommotx	dc.b "Mixing buffer size.........................",0
	even
pslider1	dc.l juusto
	dc.w 284,79,150,12,6,9,3
	dc.l pslider1gr,0,pslider1t,0,pslider1s
	dc.w 0
	dc.l 0
pslider1gr	dc.w 0,0,11,9,2
	dc.l pslider1im
	dc.b 3,0
	dc.l 0
pslider1t	dc.b 1,0,1,0
	dc.w -268,2
	dc.l 0,pslider1tx,0
pslider1tx	dc.b "Mixing rate..............",0
	even
pslider1s	dc.w 2,0,65535,0,0
	dc.w 0,0,0,0,0,0
juusto	dc.l juust0
	dc.w 284,93,150,12,6,9,3
	dc.l juustogr,0,juustot,0,juustos
	dc.w 0
	dc.l 0
juustogr	dc.w 0,0,11,9,2
	dc.l juustoim
	dc.b 3,0
	dc.l 0
juustot	dc.b 1,0,1,0
	dc.w -268,2
	dc.l 0,juustotx,0
juustotx	dc.b "Volume boost..................",0
	even
juustos	dc.w 2,0,0,0,0
	dc.w 0,0,0,0,0,0
juust0	dc.l Fruit
	dc.w 284,106,150,12,6,9,3
	dc.l juust0gr,0,juust0t,0,juust0s
	dc.w 0
	dc.l 0
juust0gr	dc.w 0,0,11,9,2
	dc.l juust0im
	dc.b 3,0
	dc.l 0
juust0t	dc.b 1,0,1,0
	dc.w -268,2
	dc.l 0,juust0tx,0
juust0tx	dc.b "Stereo level (surround).....",0
	even
juust0s	dc.w 2,0,0,0,0
	dc.w 0,0,0,0,0,0
Fruit	
    dc.l bENDER1
	dc.w 406,135-14,28,12,3,1,1
	dc.l 0,0,Fruitt,0,0
	dc.w 0
	dc.l 0
Fruitt	dc.b 1,0,1,0
	dc.w -390,2
	dc.l 0,Fruittx,0
Fruittx	dc.b "Use S:HippoPlayer.PS3M configuration file.......",0
	even
bENDER1	dc.l 0 
	dc.w 304,121+14,130,12,3,1,1
	dc.l 0,0,bENDER2t,0,0
	dc.w 0
	dc.l 0
bENDER2t	dc.b 1,0,1,0
	dc.w -288,2
	dc.l 0,bENDER2tx,0
bENDER2tx	dc.b "Use AmiGUS hardware mixer..........",0
	even
