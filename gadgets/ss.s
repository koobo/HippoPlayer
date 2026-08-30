ptext1	dc.l pbutton3
	dc.w 19,119,188,8,0,1,4
	dc.l ptext1gr,0,ptext1t,0,ptext1s
	dc.w 0
	dc.l 0
ptext1gr	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ptext1xy,ptext1gr2
ptext1xy	dc.w -2,7
	dc.w -2,-1
	dc.w 187,-1
ptext1gr2	dc.w 0,0
	dc.b 2,0,1,3
	dc.l ptext1xy2,ptext1gr3
ptext1xy2	dc.w 188,-1
	dc.w 188,8
	dc.w -2,8
ptext1gr3	dc.w 0,0
	dc.b 1,0,1,2
	dc.l ptext1xy3,ptext1gr4
ptext1xy3	dc.w -1,7
	dc.w -1,0
ptext1gr4	dc.w 0,0
	dc.b 2,0,1,2
	dc.l ptext1xy4,ptext1gr5
ptext1xy4	dc.w -4,8
	dc.w -4,-2
ptext1gr5	dc.w 0,0
	dc.b 2,0,1,4
	dc.l ptext1xy5,ptext1gr6
ptext1xy5	dc.w -3,8
	dc.w -3,-2
	dc.w 189,-2
	dc.w 189,8
ptext1gr6	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ptext1xy6,ptext1gr7
ptext1xy6	dc.w 190,-2
	dc.w 190,9
	dc.w -4,9
ptext1gr7	dc.w 0,0
	dc.b 1,0,1,2
	dc.l ptext1xy7,0
ptext1xy7	dc.w 191,-2
	dc.w 191,9
ptext1t	dc.b 1,0,1,0
	dc.w -2,-12
	dc.l 0,ptext1tx,0
ptext1tx	dc.b "н Moduledir нн Programdir н",0
	even
ptext1s	dc.l ptext1buf,0
	dc.w 0,150,0,0,0,0,0,0
	dc.l 0,0,0
ptext1buf	ds.b 150
	even
pbutton3	dc.l pslider1
	dc.w 412,119,28,12,3,1,1
	dc.l pbutton3gr,0,pbutton3t,0,0
	dc.w 0
	dc.l 0
pbutton3gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l pbutton3xy,pbutton3gr2
pbutton3xy	dc.w 0,11
	dc.w 0,0
	dc.w 27,0
pbutton3gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l pbutton3xy2,0
pbutton3xy2	dc.w 27,1
	dc.w 27,11
	dc.w 1,11
pbutton3t	dc.b 1,0,1,0
	dc.w -162,3
	dc.l 0,pbutton3tx,0
pbutton3tx	dc.b "Protracker tempo....",0
	even
pslider1	dc.l pslider2
	dc.w 336,178,104,12,4,9,3
	dc.l pslider1gr,0,pslider1t,0,pslider1s
	dc.w 0
	dc.l 0
pslider1gr	dc.w 0,0,8,10,2
	dc.l pslider1im
	dc.b 3,0
	dc.l 0
pslider1t	dc.b 1,0,1,0
	dc.w -108,3
	dc.l 0,pslider1tx,0
pslider1tx	dc.b "Mrate",0
	even
pslider1s	dc.w 2,0,65535,0,0
	dc.w 0,0,0,0,0,0
pslider2	dc.l pbutton11
	dc.w 372,133,68,12,4,9,3
	dc.l pslider2gr,0,pslider2t,0,pslider2s
	dc.w 0
	dc.l 0
pslider2gr	dc.w 0,0,8,10,2
	dc.l pslider2im
	dc.b 3,0
	dc.l 0
pslider2t	dc.b 1,0,1,0
	dc.w -122,3
	dc.l 0,pslider2tx,0
pslider2tx	dc.b "TFMX rate",0
	even
pslider2s	dc.w 2,0,65535,0,0
	dc.w 0,0,0,0,0,0



pbutton11	dc.l smode1
	dc.w 212,117,26,12,0,1,1
	dc.l pbutton11gr,0,pbutton11t,0,0
	dc.w 0
	dc.l 0
pbutton11gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l pbutton11xy,pbutton11gr2
pbutton11xy	dc.w 0,11
	dc.w 0,0
	dc.w 25,0
pbutton11gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l pbutton11xy2,0
pbutton11xy2	dc.w 25,1
	dc.w 25,11
	dc.w 1,11
pbutton11t	dc.b 1,0,1,0
	dc.w 9,2
	dc.l 0,pbutton11tx,0
pbutton11tx	dc.b "?",0
	even
smode1	dc.l smode2
	dc.w 88,165,82,12,0,1,1
	dc.l smode1gr,0,smode1t,0,0
	dc.w 0
	dc.l 0
smode1gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l smode1xy,smode1gr2
smode1xy	dc.w 0,11
	dc.w 0,0
	dc.w 81,0
smode1gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l smode1xy2,0
smode1xy2	dc.w 81,1
	dc.w 81,11
	dc.w 1,11
smode1t	dc.b 1,0,1,0
	dc.w -75,3
	dc.l 0,smode1tx,0
smode1tx	dc.b "State/buf",0
	even
smode2	dc.l pout1
	dc.w 88,179,126,12,0,1,1
	dc.l smode2gr,0,smode2t,0,0
	dc.w 0
	dc.l 0
smode2gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l smode2xy,smode2gr2
smode2xy	dc.w 0,11
	dc.w 0,0
	dc.w 125,0
smode2gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l smode2xy2,0
smode2xy2	dc.w 125,1
	dc.w 125,11
	dc.w 1,11
smode2t	dc.b 1,0,1,0
	dc.w -75,3
	dc.l 0,smode2tx,0
smode2tx	dc.b "Play mode",0
	even

pout1	dc.l laren1
	dc.w 370,91,70,12,0,1,1
	dc.l pout1gr,0,pout1t,0,0
	dc.w 0
	dc.l 0
pout1gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l pout1xy,pout1gr2
pout1xy	dc.w 0,11
	dc.w 0,0
	dc.w 69,0
pout1gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l pout1xy2,0
pout1xy2	dc.w 69,1
	dc.w 69,11
	dc.w 1,11
pout1t	dc.b 1,0,1,0
	dc.w -120,3
	dc.l 0,pout1tx,0
pout1tx	dc.b "Filter control",0
	even


laren1	dc.l makkara
	dc.w 370,105,70,12,0,1,1
	dc.l laren1gr,0,laren1t,0,0
	dc.w 0
	dc.l 0
laren1gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l laren1xy,laren1gr2
laren1xy	dc.w 0,11
	dc.w 0,0
	dc.w 69,0
laren1gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l laren1xy2,0
laren1xy2	dc.w 69,1
	dc.w 69,11
	dc.w 1,11
laren1t	dc.b 1,0,1,0
	dc.w -120,3
	dc.l 0,laren1tx,0
laren1tx	dc.b "PT replayer....",0
	even
makkara	dc.l kinkku
	dc.w 592,68,28,11,3,1,1
	dc.l makkaragr,0,makkarat,0,0
	dc.w 0
	dc.l 0
makkaragr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l makkaraxy,makkaragr2
makkaraxy	dc.w 0,10
	dc.w 0,0
	dc.w 27,0
makkaragr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l makkaraxy2,0
makkaraxy2	dc.w 27,1
	dc.w 27,10
	dc.w 1,10
makkarat	dc.b 1,0,1,0
	dc.w -138,2
	dc.l 0,makkaratx,0
makkaratx	dc.b "XPK identify.....",0
	even
kinkku	dc.l ack2
	dc.w 592,16,28,11,3,1,1
	dc.l kinkkugr,0,kinkkut,0,0
	dc.w 0
	dc.l 0
kinkkugr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l kinkkuxy,kinkkugr2
kinkkuxy	dc.w 0,10
	dc.w 0,0
	dc.w 27,0
kinkkugr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l kinkkuxy2,0
kinkkuxy2	dc.w 27,1
	dc.w 27,10
	dc.w 1,10
kinkkut	dc.b 1,0,1,0
	dc.w -138,2
	dc.l 0,kinkkutx,0
kinkkutx	dc.b "Fade volume......",0
	even
ack2	dc.l ack3
	dc.w 486,175,132,8,0,1,4
	dc.l ack2gr,0,ack2t,0,ack2s
	dc.w 0
	dc.l 0
ack2gr	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ack2xy,ack2gr2
ack2xy	dc.w -2,7
	dc.w -2,-1
	dc.w 129,-1
ack2gr2	dc.w 0,0
	dc.b 2,0,1,3
	dc.l ack2xy2,ack2gr3
ack2xy2	dc.w 130,-1
	dc.w 130,8
	dc.w -2,8
ack2gr3	dc.w 0,0
	dc.b 1,0,1,2
	dc.l ack2xy3,ack2gr4
ack2xy3	dc.w -1,7
	dc.w -1,0
ack2gr4	dc.w 0,0
	dc.b 2,0,1,2
	dc.l ack2xy4,ack2gr5
ack2xy4	dc.w -4,8
	dc.w -4,-2
ack2gr5	dc.w 0,0
	dc.b 2,0,1,4
	dc.l ack2xy5,ack2gr6
ack2xy5	dc.w -3,8
	dc.w -3,-2
	dc.w 131,-2
	dc.w 131,8
ack2gr6	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ack2xy6,ack2gr7
ack2xy6	dc.w 132,-2
	dc.w 132,9
	dc.w -4,9
ack2gr7	dc.w 0,0
	dc.b 1,0,1,2
	dc.l ack2xy7,0
ack2xy7	dc.w 133,-2
	dc.w 133,9
ack2t	dc.b 1,0,1,0
	dc.w -32,0
	dc.l 0,ack2tx,0
ack2tx	dc.b "LhA",0
	even
ack2s	dc.l ack2buf,0
	dc.w 0,100,0,0,0,0,0,0
	dc.l 0,0,0
ack2buf	ds.b 100
	even
ack3	dc.l ack4
	dc.w 486,201,132,8,0,1,4
	dc.l ack3gr,0,ack3t,0,ack3s
	dc.w 0
	dc.l 0
ack3gr	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ack3xy,ack3gr2
ack3xy	dc.w -2,7
	dc.w -2,-1
	dc.w 129,-1
ack3gr2	dc.w 0,0
	dc.b 2,0,1,3
	dc.l ack3xy2,ack3gr3
ack3xy2	dc.w 130,-1
	dc.w 130,8
	dc.w -2,8
ack3gr3	dc.w 0,0
	dc.b 1,0,1,2
	dc.l ack3xy3,ack3gr4
ack3xy3	dc.w -1,7
	dc.w -1,0
ack3gr4	dc.w 0,0
	dc.b 2,0,1,2
	dc.l ack3xy4,ack3gr5
ack3xy4	dc.w -4,8
	dc.w -4,-2
ack3gr5	dc.w 0,0
	dc.b 2,0,1,4
	dc.l ack3xy5,ack3gr6
ack3xy5	dc.w -3,8
	dc.w -3,-2
	dc.w 131,-2
	dc.w 131,8
ack3gr6	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ack3xy6,ack3gr7
ack3xy6	dc.w 132,-2
	dc.w 132,9
	dc.w -4,9
ack3gr7	dc.w 0,0
	dc.b 1,0,1,2
	dc.l ack3xy7,0
ack3xy7	dc.w 133,-2
	dc.w 133,9
ack3t	dc.b 1,0,1,0
	dc.w -32,0
	dc.l 0,ack3tx,0
ack3tx	dc.b "Zip",0
	even
ack3s	dc.l ack3buf,0
	dc.w 0,100,0,0,0,0,0,0
	dc.l 0,0,0
ack3buf	ds.b 100
	even
ack4	dc.l juusto
	dc.w 486,188,132,8,0,1,4
	dc.l ack4gr,0,ack4t,0,ack4s
	dc.w 0
	dc.l 0
ack4gr	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ack4xy,ack4gr2
ack4xy	dc.w -2,7
	dc.w -2,-1
	dc.w 129,-1
ack4gr2	dc.w 0,0
	dc.b 2,0,1,3
	dc.l ack4xy2,ack4gr3
ack4xy2	dc.w 130,-1
	dc.w 130,8
	dc.w -2,8
ack4gr3	dc.w 0,0
	dc.b 1,0,1,2
	dc.l ack4xy3,ack4gr4
ack4xy3	dc.w -1,7
	dc.w -1,0
ack4gr4	dc.w 0,0
	dc.b 2,0,1,2
	dc.l ack4xy4,ack4gr5
ack4xy4	dc.w -4,8
	dc.w -4,-2
ack4gr5	dc.w 0,0
	dc.b 2,0,1,4
	dc.l ack4xy5,ack4gr6
ack4xy5	dc.w -3,8
	dc.w -3,-2
	dc.w 131,-2
	dc.w 131,8
ack4gr6	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ack4xy6,ack4gr7
ack4xy6	dc.w 132,-2
	dc.w 132,9
	dc.w -4,9
ack4gr7	dc.w 0,0
	dc.b 1,0,1,2
	dc.l ack4xy7,0
ack4xy7	dc.w 133,-2
	dc.w 133,9
ack4t	dc.b 1,0,1,0
	dc.w -32,0
	dc.l 0,ack4tx,0
ack4tx	dc.b "LZX",0
	even
ack4s	dc.l ack4buf,0
	dc.w 0,100,0,0,0,0,0,0
	dc.l 0,0,0
ack4buf	ds.b 100
	even
juusto	dc.l ptext2
	dc.w 370,165,70,12,4,9,3
	dc.l juustogr,0,juustot,0,juustos
	dc.w 0
	dc.l 0
juustogr	dc.w 0,0,8,10,2
	dc.l juustoim
	dc.b 3,0
	dc.l 0
juustot	dc.b 1,0,1,0
	dc.w -144,3
	dc.l 0,juustotx,0
juustotx	dc.b "Volume boost....",0
	even
juustos	dc.w 2,0,0,0,0
	dc.w 0,0,0,0,0,0

ptext2	dc.l pbutton12
	dc.w 19,132,188,8,0,1,4
	dc.l ptext2gr,0,0,0,ptext2s
	dc.w 0
	dc.l 0
ptext2gr	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ptext2xy,ptext2gr2
ptext2xy	dc.w -2,7
	dc.w -2,-1
	dc.w 187,-1
ptext2gr2	dc.w 0,0
	dc.b 2,0,1,3
	dc.l ptext2xy2,ptext2gr3
ptext2xy2	dc.w 188,-1
	dc.w 188,8
	dc.w -2,8
ptext2gr3	dc.w 0,0
	dc.b 1,0,1,2
	dc.l ptext2xy3,ptext2gr4
ptext2xy3	dc.w -1,7
	dc.w -1,0
ptext2gr4	dc.w 0,0
	dc.b 2,0,1,2
	dc.l ptext2xy4,ptext2gr5
ptext2xy4	dc.w -4,8
	dc.w -4,-2
ptext2gr5	dc.w 0,0
	dc.b 2,0,1,4
	dc.l ptext2xy5,ptext2gr6
ptext2xy5	dc.w -3,8
	dc.w -3,-2
	dc.w 189,-2
	dc.w 189,8
ptext2gr6	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ptext2xy6,ptext2gr7
ptext2xy6	dc.w 190,-2
	dc.w 190,9
	dc.w -4,9
ptext2gr7	dc.w 0,0
	dc.b 1,0,1,2
	dc.l ptext2xy7,0
ptext2xy7	dc.w 191,-2
	dc.w 191,9
ptext2s	dc.l ptext2buf,0
	dc.w 0,150,0,0,0,0,0,0
	dc.l 0,0,0
ptext2buf	ds.b 150
	even
pbutton12	dc.l nappu1
	dc.w 212,130,26,12,0,1,1
	dc.l pbutton12gr,0,pbutton12t,0,0
	dc.w 0
	dc.l 0
pbutton12gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l pbutton12xy,pbutton12gr2
pbutton12xy	dc.w 0,11
	dc.w 0,0
	dc.w 25,0
pbutton12gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l pbutton12xy2,0
pbutton12xy2	dc.w 25,1
	dc.w 25,11
	dc.w 1,11
pbutton12t	dc.b 1,0,1,0
	dc.w 9,2
	dc.l 0,pbutton12tx,0
pbutton12tx	dc.b "?",0
	even
nappu1	dc.l nappu2
	dc.w 592,94,28,11,3,1,1
	dc.l nappu1gr,0,nappu1t,0,0
	dc.w 0
	dc.l 0
nappu1gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l nappu1xy,nappu1gr2
nappu1xy	dc.w 0,10
	dc.w 0,0
	dc.w 27,0
nappu1gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l nappu1xy2,0
nappu1xy2	dc.w 27,1
	dc.w 27,10
	dc.w 1,10
nappu1t	dc.b 1,0,1,0
	dc.w -138,2
	dc.l 0,nappu1tx,0
nappu1tx	dc.b "Doublebuffering..",0
	even
nappu2	dc.l jommo
	dc.w 592,107,28,11,3,1,1
	dc.l nappu2gr,0,nappu2t,0,0
	dc.w 0
	dc.l 0
nappu2gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l nappu2xy,nappu2gr2
nappu2xy	dc.w 0,10
	dc.w 0,0
	dc.w 27,0
nappu2gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l nappu2xy2,0
nappu2xy2	dc.w 27,1
	dc.w 27,10
	dc.w 1,10
nappu2t	dc.b 1,0,1,0
	dc.w -138,2
	dc.l 0,nappu2tx,0
nappu2tx	dc.b "Nasty audio......",0
	even
jommo	dc.l nApPu
	dc.w 172,165,42,12,0,1,1
	dc.l jommogr,0,jommot,0,0
	dc.w 0
	dc.l 0
jommogr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l jommoxy,jommogr2
jommoxy	dc.w 0,11
	dc.w 0,0
	dc.w 41,0
jommogr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l jommoxy2,0
jommoxy2	dc.w 41,1
	dc.w 41,11
	dc.w 1,11
jommot	dc.b 1,0,1,0
	dc.w -140,-12
	dc.l 0,jommotx,0
jommotx	dc.b "*** PS3M settings ***",0
	even
nApPu	dc.l blpgo
	dc.w 592,120,28,11,3,1,1
	dc.l nApPugr,0,nApPut,0,0
	dc.w 0
	dc.l 0
nApPugr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l nApPuxy,nApPugr2
nApPuxy	dc.w 0,10
	dc.w 0,0
	dc.w 27,0
nApPugr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l nApPuxy2,0
nApPuxy2	dc.w 27,1
	dc.w 27,10
	dc.w 1,10
nApPut	dc.b 1,0,1,0
	dc.w -138,2
	dc.l 0,nApPutx,0
nApPutx	dc.b "VBlank timing....",0
	even
blpgo	dc.l alarb
	dc.w 250,16,118,12,0,1,1
	dc.l blpgogr,0,blpgot,0,0
	dc.w 0
	dc.l 0
blpgogr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l blpgoxy,blpgogr2
blpgoxy	dc.w 0,11
	dc.w 0,0
	dc.w 117,0
blpgogr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l blpgoxy2,0
blpgoxy2	dc.w 117,1
	dc.w 117,11
	dc.w 1,11
blpgot	dc.b 1,0,1,0
	dc.w 11,2
	dc.l 0,blpgotx,0
blpgotx	dc.b "Player group",0
	even
alarb	dc.l juust0
	dc.w 334,44,52,12,0,1,1
	dc.l alarbgr,0,alarbt,0,0
	dc.w 0
	dc.l 0
alarbgr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l alarbxy,alarbgr2
alarbxy	dc.w 0,11
	dc.w 0,0
	dc.w 51,0
alarbgr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l alarbxy2,0
alarbxy2	dc.w 51,1
	dc.w 51,11
	dc.w 1,11
alarbt	dc.b 1,0,1,0
	dc.w 5,2
	dc.l 0,alarbtx,0
alarbtx	dc.b "Alarm",0
	even
juust0	dc.l 0
	dc.w 370,152,70,12,4,9,3
	dc.l juust0gr,0,juust0t,0,juust0s
	dc.w 0
	dc.l 0
juust0gr	dc.w 0,0,8,10,2
	dc.l juust0im
	dc.b 3,0
	dc.l 0
juust0t	dc.b 1,0,1,0
	dc.w -144,3
	dc.l 0,juust0tx,0
juust0tx	dc.b "Stereo.......",0
	even
juust0s	dc.w 2,0,65535,0,0
	dc.w 0,0,0,0,0,0
