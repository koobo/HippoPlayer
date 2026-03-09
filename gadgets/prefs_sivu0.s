pbutton1	dc.l nippug
	dc.w 52,37,190,12,0,1,1
	dc.l 0,0,pbutton1t,0,0
	dc.w 0
	dc.l 0
pbutton1t	dc.b 1,0,1,0
	dc.w -36,2
	dc.l 0,pbutton1tx,0
pbutton1tx	dc.b "Play",0
	even
nippug	dc.l kelloke
	dc.w 16,65,76,12,0,1,1
	dc.l 0,0,nippugt,0,0
	dc.w 0
	dc.l 0
nippugt	dc.b 1,0,1,0
	dc.w 10,2
	dc.l 0,nippugtx,0
nippugtx	dc.b "Timeout",0
	even
kelloke	dc.l kelloke2
	dc.w 148,65,94,12,4,9,3
	dc.l kellokegr,0,0,0,kellokes
	dc.w 0
	dc.l 0
kellokegr	dc.w 0,0,11,9,2
	dc.l kellokeim
	dc.b 3,0
	dc.l 0
kellokes	dc.w 2,0,0,0,0
	dc.w 0,0,0,0,0,0
kelloke2	dc.l salaatti2
	dc.w 148,79,94,12,4,9,3
	dc.l kelloke2gr,0,kelloke2t,0,kelloke2s
	dc.w 0
	dc.l 0
kelloke2gr	dc.w 0,0,11,9,2
	dc.l kelloke2im
	dc.b 3,0
	dc.l 0
kelloke2t	dc.b 1,0,1,0
	dc.w -132,2
	dc.l 0,kelloke2tx,0
kelloke2tx	dc.b "Alarm.....",0
	even
kelloke2s	dc.w 2,0,0,0,0
	dc.w 0,0,0,0,0,0
salaatti2	dc.l salaatti3
	dc.w 16,93,76,12,0,1,1
	dc.l 0,0,salaatti2t,0,0
	dc.w 0
	dc.l 0
salaatti2t	dc.b 1,0,1,0
	dc.w 10,2
	dc.l 0,salaatti2tx,0
salaatti2tx	dc.b "Startup",0
	even
salaatti3	dc.l salaatti
	dc.w 214,93,28,12,3,1,1
	dc.l 0,0,salaatti3t,0,0
	dc.w 0
	dc.l 0
salaatti3t	dc.b 1,0,1,0
	dc.w -120,2
	dc.l 0,salaatti3tx,0
salaatti3tx	dc.b "...............",0
	even
salaatti	dc.l tomaatti
	dc.w 16,135,226,12,0,1,1
	dc.l 0,0,salaattit,0,0
	dc.w 0
	dc.l 0
salaattit	dc.b 1,0,1,0
	dc.w 61,2
	dc.l 0,salaattitx,0
salaattitx	dc.b "Function keys",0
	even
tomaatti	dc.l kaktus
	dc.w 396,135,38,12,3,1,1
	dc.l 0,0,tomaattit,0,0
	dc.w 0
	dc.l 0
tomaattit	dc.b 1,0,1,0
	dc.w -136,2
	dc.l 0,tomaattitx,0
tomaattitx	dc.b "Priority.........",0
	even
kaktus	dc.l eins2
	dc.w 406,37,28,12,3,1,1
	dc.l 0,0,kaktust,0,0
	dc.w 0
	dc.l 0
kaktust	dc.b 1,0,1,0
	dc.w -146,2
	dc.l 0,kaktustx,0
kaktustx	dc.b "Hotkeys...........",0
	even
eins2	dc.l luuta
	dc.w 406,51,28,12,3,1,1
	dc.l 0,0,eins2t,0,0
	dc.w 0
	dc.l 0
eins2t	dc.b 1,0,1,0
	dc.w -146,2
	dc.l 0,eins2tx,0
eins2tx	dc.b "Doubleclick.......",0
	even
luuta	
;    dc.l bUu3
    dc.l bUu1
	dc.w 406,65,28,12,3,1,1
	dc.l 0,0,luutat,0,0
	dc.w 0
	dc.l 0
luutat	dc.b 1,0,1,0
	dc.w -146,2
	dc.l 0,luutatx,0
luutatx	dc.b "Continue on error",0
	even

;bUu3	dc.l bUu1
;	dc.w 406,79,28,12,3,1,1
;	dc.l 0,0,bUu3t,0,0
;	dc.w 0
;	dc.l 0
;bUu3t	dc.b 1,0,1,0
;	dc.w -146,2
;	dc.l 0,bUu3tx,0
;bUu3tx	dc.b "Early load........",0
;	even

bUu1	dc.l bUu22
	dc.w 406,93,28,12,3,1,1
	dc.l 0,0,bUu1t,0,0
	dc.w 0
	dc.l 0
bUu1t	dc.b 1,0,1,0
	dc.w -146,2
	dc.l 0,bUu1tx,0
bUu1tx	dc.b "Divider / dir.....",0
	even
bUu22	dc.l 0
	dc.w 406,107,28,12,3,1,1
	dc.l 0,0,bUu22t,0,0
	dc.w 0
	dc.l 0
bUu22t	dc.b 1,0,1,0
	dc.w -146,2
	dc.l 0,bUu22tx,0
bUu22tx	dc.b "Auto sort.........",0
	even
