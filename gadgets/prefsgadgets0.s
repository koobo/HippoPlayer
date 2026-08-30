ptext1	dc.l pbutton1
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
pbutton1	dc.l pbutton2
	dc.w 48,16,190,12,0,1,1
	dc.l pbutton1gr,0,pbutton1t,0,0
	dc.w 0
	dc.l 0
pbutton1gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l pbutton1xy,pbutton1gr2
pbutton1xy	dc.w 0,11
	dc.w 0,0
	dc.w 189,0
pbutton1gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l pbutton1xy2,0
pbutton1xy2	dc.w 189,1
	dc.w 189,11
	dc.w 1,11
pbutton1t	dc.b 1,0,1,0
	dc.w -36,2
	dc.l 0,pbutton1tx,0
pbutton1tx	dc.b "Play",0
	even
pbutton2	dc.l pbutton3
	dc.w 48,30,190,12,0,1,1
	dc.l pbutton2gr,0,pbutton2t,0,0
	dc.w 0
	dc.l 0
pbutton2gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l pbutton2xy,pbutton2gr2
pbutton2xy	dc.w 0,11
	dc.w 0,0
	dc.w 189,0
pbutton2gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l pbutton2xy2,0
pbutton2xy2	dc.w 189,1
	dc.w 189,11
	dc.w 1,11
pbutton2t	dc.b 1,0,1,0
	dc.w -36,2
	dc.l 0,pbutton2tx,0
pbutton2tx	dc.b "Show",0
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
pslider2	dc.l pbutton14
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
pbutton14	dc.l pbutton6
	dc.w 14,198,138,12,0,1,1
	dc.l pbutton14gr,0,pbutton14t,0,0
	dc.w 0
	dc.l 0
pbutton14gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l pbutton14xy,pbutton14gr2
pbutton14xy	dc.w 0,11
	dc.w 0,0
	dc.w 137,0
pbutton14gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l pbutton14xy2,0
pbutton14xy2	dc.w 137,1
	dc.w 137,11
	dc.w 1,11
pbutton14t	dc.b 1,0,1,0
	dc.w 53,2
	dc.l 0,pbutton14tx,0
pbutton14tx	dc.b "Save",0
	even
pbutton6	dc.l pbutton7
	dc.w 158,198,138,12,0,1,1
	dc.l pbutton6gr,0,pbutton6t,0,0
	dc.w 0
	dc.l 0
pbutton6gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l pbutton6xy,pbutton6gr2
pbutton6xy	dc.w 0,11
	dc.w 0,0
	dc.w 137,0
pbutton6gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l pbutton6xy2,0
pbutton6xy2	dc.w 137,1
	dc.w 137,11
	dc.w 1,11
pbutton6t	dc.b 1,0,1,0
	dc.w 57,2
	dc.l 0,pbutton6tx,0
pbutton6tx	dc.b "Use",0
	even
pbutton7	dc.l pbutton11
	dc.w 302,198,138,12,0,1,1
	dc.l pbutton7gr,0,pbutton7t,0,0
	dc.w 0
	dc.l 0
pbutton7gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l pbutton7xy,pbutton7gr2
pbutton7xy	dc.w 0,11
	dc.w 0,0
	dc.w 137,0
pbutton7gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l pbutton7xy2,0
pbutton7xy2	dc.w 137,1
	dc.w 137,11
	dc.w 1,11
pbutton7t	dc.b 1,0,1,0
	dc.w 49,2
	dc.l 0,pbutton7tx,0
pbutton7tx	dc.b "Cancel",0
	even
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
pout1	dc.l pout2
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
pout2	dc.l pout3
	dc.w 148,72,90,12,0,1,1
	dc.l pout2gr,0,pout2t,0,0
	dc.w 0
	dc.l 0
pout2gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l pout2xy,pout2gr2
pout2xy	dc.w 0,11
	dc.w 0,0
	dc.w 89,0
pout2gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l pout2xy2,0
pout2xy2	dc.w 89,1
	dc.w 89,11
	dc.w 1,11
pout2t	dc.b 1,0,1,0
	dc.w 14,2
	dc.l 0,pout2tx,0
pout2tx	dc.b "On / Off",0
	even
pout3	dc.l laren1
	dc.w 48,86,124,12,0,1,1
	dc.l pout3gr,0,pout3t,0,0
	dc.w 0
	dc.l 0
pout3gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l pout3xy,pout3gr2
pout3xy	dc.w 0,11
	dc.w 0,0
	dc.w 123,0
pout3gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l pout3xy2,0
pout3xy2	dc.w 123,1
	dc.w 123,11
	dc.w 1,11
pout3t	dc.b 1,0,1,0
	dc.w -36,3
	dc.l 0,pout3tx,0
pout3tx	dc.b "Type",0
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
juusto	dc.l tomaatti
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
tomaatti	dc.l meloni
	dc.w 402,72,38,12,0,1,1
	dc.l tomaattigr,0,tomaattit,0,0
	dc.w 0
	dc.l 0
tomaattigr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l tomaattixy,tomaattigr2
tomaattixy	dc.w 0,11
	dc.w 0,0
	dc.w 37,0
tomaattigr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l tomaattixy2,0
tomaattixy2	dc.w 37,1
	dc.w 37,11
	dc.w 1,11
tomaattit	dc.b 1,0,1,0
	dc.w -152,3
	dc.l 0,tomaattitx,0
tomaattitx	dc.b "Priority...........",0
	even
meloni	dc.l eins1
	dc.w 168,58,70,12,4,9,3
	dc.l melonigr,0,melonit,0,melonis
	dc.w 0
	dc.l 0
melonigr	dc.w 0,0,8,10,2
	dc.l meloniim
	dc.b 3,0
	dc.l 0
melonit	dc.b 1,0,1,0
	dc.w -156,3
	dc.l 0,melonitx,0
melonitx	dc.b "Filebox.........",0
	even
melonis	dc.w 2,0,65535,0,0
	dc.w 0,0,0,0,0,0
eins1	dc.l eins2
	dc.w 592,55,28,11,3,1,1
	dc.l eins1gr,0,eins1t,0,0
	dc.w 0
	dc.l 0
eins1gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l eins1xy,eins1gr2
eins1xy	dc.w 0,10
	dc.w 0,0
	dc.w 27,0
eins1gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l eins1xy2,0
eins1xy2	dc.w 27,1
	dc.w 27,10
	dc.w 1,10
eins1t	dc.b 1,0,1,0
	dc.w -138,2
	dc.l 0,eins1tx,0
eins1tx	dc.b "Center name......",0
	even
eins2	dc.l salaatti
	dc.w 592,42,28,11,3,1,1
	dc.l eins2gr,0,eins2t,0,0
	dc.w 0
	dc.l 0
eins2gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l eins2xy,eins2gr2
eins2xy	dc.w 0,10
	dc.w 0,0
	dc.w 27,0
eins2gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l eins2xy2,0
eins2xy2	dc.w 27,1
	dc.w 27,10
	dc.w 1,10
eins2t	dc.b 1,0,1,0
	dc.w -138,2
	dc.l 0,eins2tx,0
eins2tx	dc.b "Doubleclick......",0
	even
salaatti	dc.l salaatti2
	dc.w 250,30,190,12,0,1,1
	dc.l salaattigr,0,salaattit,0,0
	dc.w 0
	dc.l 0
salaattigr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l salaattixy,salaattigr2
salaattixy	dc.w 0,11
	dc.w 0,0
	dc.w 189,0
salaattigr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l salaattixy2,0
salaattixy2	dc.w 189,1
	dc.w 189,11
	dc.w 1,11
salaattit	dc.b 1,0,1,0
	dc.w 43,2
	dc.l 0,salaattitx,0
salaattitx	dc.b "Function keys",0
	even
salaatti2	dc.l salaatti3
	dc.w 250,44,72,12,0,1,1
	dc.l salaatti2gr,0,salaatti2t,0,0
	dc.w 0
	dc.l 0
salaatti2gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l salaatti2xy,salaatti2gr2
salaatti2xy	dc.w 0,11
	dc.w 0,0
	dc.w 71,0
salaatti2gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l salaatti2xy2,0
salaatti2xy2	dc.w 71,1
	dc.w 71,11
	dc.w 1,11
salaatti2t	dc.b 1,0,1,0
	dc.w 8,2
	dc.l 0,salaatti2tx,0
salaatti2tx	dc.b "Startup",0
	even
salaatti3	dc.l kelloke
	dc.w 412,44,28,12,3,1,1
	dc.l salaatti3gr,0,0,0,0
	dc.w 0
	dc.l 0
salaatti3gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l salaatti3xy,salaatti3gr2
salaatti3xy	dc.w 0,11
	dc.w 0,0
	dc.w 27,0
salaatti3gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l salaatti3xy2,0
salaatti3xy2	dc.w 27,1
	dc.w 27,11
	dc.w 1,11
kelloke	dc.l kaktus
	dc.w 370,58,70,12,4,9,3
	dc.l kellokegr,0,0,0,kellokes
	dc.w 0
	dc.l 0
kellokegr	dc.w 0,0,8,10,2
	dc.l kellokeim
	dc.b 3,0
	dc.l 0
kellokes	dc.w 2,0,65535,0,0
	dc.w 0,0,0,0,0,0
kaktus	dc.l luuta
	dc.w 592,29,28,11,3,1,1
	dc.l kaktusgr,0,kaktust,0,0
	dc.w 0
	dc.l 0
kaktusgr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l kaktusxy,kaktusgr2
kaktusxy	dc.w 0,10
	dc.w 0,0
	dc.w 27,0
kaktusgr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l kaktusxy2,0
kaktusxy2	dc.w 27,1
	dc.w 27,10
	dc.w 1,10
kaktust	dc.b 1,0,1,0
	dc.w -138,2
	dc.l 0,kaktustx,0
kaktustx	dc.b "Hotkeys..........",0
	even
luuta	dc.l ptext2
	dc.w 592,81,28,11,3,1,1
	dc.l luutagr,0,luutat,0,0
	dc.w 0
	dc.l 0
luutagr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l luutaxy,luutagr2
luutaxy	dc.w 0,10
	dc.w 0,0
	dc.w 27,0
luutagr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l luutaxy2,0
luutaxy2	dc.w 27,1
	dc.w 27,10
	dc.w 1,10
luutat	dc.b 1,0,1,0
	dc.w -138,2
	dc.l 0,luutatx,0
luutatx	dc.b "Continue on error",0
	even
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
pbutton12	dc.l pbutton13
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
pbutton13	dc.l nappu1
	dc.w 70,44,168,12,0,1,1
	dc.l pbutton13gr,0,pbutton13t,0,0
	dc.w 0
	dc.l 0
pbutton13gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l pbutton13xy,pbutton13gr2
pbutton13xy	dc.w 0,11
	dc.w 0,0
	dc.w 167,0
pbutton13gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l pbutton13xy2,0
pbutton13xy2	dc.w 167,1
	dc.w 167,11
	dc.w 1,11
pbutton13t	dc.b 1,0,1,0
	dc.w -58,2
	dc.l 0,pbutton13tx,0
pbutton13tx	dc.b "Screen",0
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
jommo	dc.l nippug
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
nippug	dc.l pout3b
	dc.w 250,58,64,12,0,1,1
	dc.l nippuggr,0,nippugt,0,0
	dc.w 0
	dc.l 0
nippuggr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l nippugxy,nippuggr2
nippugxy	dc.w 0,11
	dc.w 0,0
	dc.w 63,0
nippuggr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l nippugxy2,0
nippugxy2	dc.w 63,1
	dc.w 63,11
	dc.w 1,11
nippugt	dc.b 1,0,1,0
	dc.w 3,2
	dc.l 0,nippugtx,0
nippugtx	dc.b "Timeout",0
	even
pout3b	dc.l nApPu
	dc.w 174,86,64,12,0,1,1
	dc.l pout3bgr,0,pout3bt,0,0
	dc.w 0
	dc.l 0
pout3bgr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l pout3bxy,pout3bgr2
pout3bxy	dc.w 0,11
	dc.w 0,0
	dc.w 63,0
pout3bgr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l pout3bxy2,0
pout3bxy2	dc.w 63,1
	dc.w 63,11
	dc.w 1,11
pout3bt	dc.b 1,0,1,0
	dc.w -162,-11
	dc.l 0,pout3btx,0
pout3btx	dc.b "Scope............",0
	even
nApPu	dc.l gfonttou
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
gfonttou	dc.l blpgo
	dc.w 380,16,60,12,0,1,1
	dc.l gfonttougr,0,gfonttout,0,0
	dc.w 0
	dc.l 0
gfonttougr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l gfonttouxy,gfonttougr2
gfonttouxy	dc.w 0,11
	dc.w 0,0
	dc.w 59,0
gfonttougr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l gfonttouxy2,0
gfonttouxy2	dc.w 59,1
	dc.w 59,11
	dc.w 1,11
gfonttout	dc.b 1,0,1,0
	dc.w 14,2
	dc.l 0,gfonttoutx,0
gfonttoutx	dc.b "Font",0
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
juust0	dc.l bUu1
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
bUu1	dc.l bUu2
	dc.w 592,133,28,11,3,1,1
	dc.l bUu1gr,0,bUu1t,0,0
	dc.w 0
	dc.l 0
bUu1gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l bUu1xy,bUu1gr2
bUu1xy	dc.w 0,10
	dc.w 0,0
	dc.w 27,0
bUu1gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l bUu1xy2,0
bUu1xy2	dc.w 27,1
	dc.w 27,10
	dc.w 1,10
bUu1t	dc.b 1,0,1,0
	dc.w -138,2
	dc.l 0,bUu1tx,0
bUu1tx	dc.b "Divider / dir....",0
	even
bUu2	dc.l bUu3
	dc.w 592,146,28,11,0,1,1
	dc.l bUu2gr,0,bUu2t,0,0
	dc.w 0
	dc.l 0
bUu2gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l bUu2xy,bUu2gr2
bUu2xy	dc.w 0,10
	dc.w 0,0
	dc.w 27,0
bUu2gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l bUu2xy2,0
bUu2xy2	dc.w 27,1
	dc.w 27,10
	dc.w 1,10
bUu2t	dc.b 1,0,1,0
	dc.w -138,2
	dc.l 0,bUu2tx,0
bUu2tx	dc.b "Prefix cut.......",0
	even
bUu3	dc.l 0
	dc.w 592,159,28,11,0,1,1
	dc.l bUu3gr,0,bUu3t,0,0
	dc.w 0
	dc.l 0
bUu3gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l bUu3xy,bUu3gr2
bUu3xy	dc.w 0,10
	dc.w 0,0
	dc.w 27,0
bUu3gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l bUu3xy2,0
bUu3xy2	dc.w 27,1
	dc.w 27,10
	dc.w 1,10
bUu3t	dc.b 1,0,1,0
	dc.w -138,2
	dc.l 0,bUu3tx,0
bUu3tx	dc.b "Early load.......",0
	even
