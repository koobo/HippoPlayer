RoU1	dc.l PoU2
	dc.w 52,65,190,12,0,1,1
	dc.l 0,0,RoU1t,0,0
	dc.w 0
	dc.l 0
RoU1t	dc.b 1,0,1,0
	dc.w -36,2
	dc.l 0,RoU1tx,0
RoU1tx	dc.b "File",0
	even
PoU2	dc.l pout1
	dc.w 120,51,122,12,0,1,1
	dc.l 0,0,PoU2t,0,0
	dc.w 0
	dc.l 0
PoU2t	dc.b 1,0,1,0
	dc.w -104,2
	dc.l 0,PoU2tx,PoU2t2
PoU2tx	dc.b "Mode........",0
	even
PoU2t2	dc.b 1,0,1,0
	dc.w -104,-12
	dc.l 0,PoU2tx2,0
PoU2tx2	dc.b "Player group......",0
	even
pout1	dc.l kinkku
	dc.w 172,79,70,12,0,1,1
	dc.l 0,0,pout1t,0,0
	dc.w 0
	dc.l 0
pout1t	dc.b 1,0,1,0
	dc.w -156,2
	dc.l 0,pout1tx,0
pout1tx	dc.b "Filter control.....",0
	even
kinkku	dc.l nappu2
	dc.w 150,93,28,12,3,1,1
	dc.l 0,0,kinkkut,0,0
	dc.w 0
	dc.l 0
kinkkut	dc.b 1,0,1,0
	dc.w -134,2
	dc.l 0,kinkkutx,0
kinkkutx	dc.b "Fade volume.....",0
	even
nappu2	dc.l nApPu
	dc.w 150,107,28,12,3,1,1
	dc.l 0,0,nappu2t,0,0
	dc.w 0
	dc.l 0
nappu2t	dc.b 1,0,1,0
	dc.w -134,2
	dc.l 0,nappu2tx,0
nappu2tx	dc.b "Nasty audio.....",0
	even
nApPu	dc.l laren1
	dc.w 150,121,28,12,3,1025,1
	dc.l 0,0,nApPut,0,0
	dc.w 0
	dc.l 0
nApPut	dc.b 1,0,1,0
	dc.w -134,2
	dc.l 0,nApPutx,0
nApPutx	dc.b "VBlank timing...",0
	even
laren1	dc.l pbutton3
	dc.w 364,37,70,12,0,1,1
	dc.l 0,0,laren1t,0,0
	dc.w 0
	dc.l 0
laren1t	dc.b 1,0,1,0
	dc.w -106,2
	dc.l 0,laren1tx,0
laren1tx	dc.b "PT replayer..",0
	even
pbutton3	dc.l gadgetEnablePositionSlider
	dc.w 406,51,28,12,3,1,1
	dc.l 0,0,pbutton3t,0,0
	dc.w 0
	dc.l 0
pbutton3t	dc.b 1,0,1,0
	dc.w -148,2
	dc.l 0,pbutton3tx,0
pbutton3tx	dc.b "Protracker tempo..",0
	even

gadgetEnablePositionSlider
    dc.l    0
	dc.w 406,51+14*2,28,12,3,1,1
	dc.l 0,0,.pbutton3t,0,0
	dc.w 0
	dc.l 0
.pbutton3t	dc.b 1,0,1,0
	dc.w -148,2
	dc.l 0,.pbutton3tx,0
.pbutton3tx	dc.b "Position slider...",0
;.pbutton3txdc.b "Protracker tempo..",0
	even

