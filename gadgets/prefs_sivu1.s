pbutton2	dc.l pbutton13
	dc.w 52,37,190,12,0,1,1
	dc.l 0,0,pbutton2t,0,0
	dc.w 0
	dc.l 0
pbutton2t	dc.b 1,0,1,0
	dc.w -36,2
	dc.l 0,pbutton2tx,0
pbutton2tx	dc.b "Show",0
	even
pbutton13	dc.l meloni
	dc.w 74,51,168,12,0,1,1
	dc.l 0,0,pbutton13t,0,0
	dc.w 0
	dc.l 0
pbutton13t	dc.b 1,0,1,0
	dc.w -58,2
	dc.l 0,pbutton13tx,0
pbutton13tx	dc.b "Screen",0
	even
meloni	dc.l gfonttou
	dc.w 172,65,70,12,6,9,3
	dc.l melonigr,0,melonit,0,melonis
	dc.w 0
	dc.l 0
melonigr	dc.w 0,0,11,9,2
	dc.l meloniim
	dc.b 3,0
	dc.l 0
melonit	dc.b 1,0,1,0
	dc.w -156,2
	dc.l 0,melonitx,0
melonitx	dc.b "Filebox.........",0
	even
melonis	dc.w 2,0,0,0,0
	dc.w 0,0,0,0,0,0

gfonttou	
	;dc.l pout2
	dc.l bUu2
	dc.w 120,93,122,12,0,1,1
	dc.l 0,0,gfonttout,0,0
	dc.w 0
	dc.l 0
gfonttout	dc.b 1,0,1,0
	dc.w -104,2
	dc.l 0,gfonttoutx,0
gfonttoutx	dc.b "Font.........",0
	even

; Disable old three scope gadgets
;pout2	dc.l pout3
;	dc.w 406,107,28,12,3,1,1
;		dc.l 0,0,pout2t,0,0
;	dc.w 0
;	dc.l 0
;pout2t	dc.b 1,0,1,0
;	dc.w -146,2
;	dc.l 0,pout2tx,0
;pout2tx	dc.b "Scope.............",0
;	even
;pout3	dc.l pout3b
;	dc.w 312,121,122,12,0,1,1
;	dc.l 0,0,pout3t,0,0
;	dc.w 0
;	dc.l 0
;pout3t	dc.b 1,0,1,0
;	dc.w -52,2
;	dc.l 0,pout3tx,0
;pout3tx	dc.b "Type..",0
;	even
;pout3b	dc.l bUu2
;	dc.w 406,135,28,12,3,1,1
;	dc.l 0,0,pout3bt,0,0
;	dc.w 0
;	dc.l 0
;pout3bt	dc.b 1,0,1,0
;	dc.w -146,2
;	dc.l 0,pout3btx,0
;pout3btx	dc.b "Scope bars........",0
;	even

bUu2	dc.l eskimO
	dc.w 406,37,28,12,3,1,1
	dc.l 0,0,bUu2t,0,0
	dc.w 0
	dc.l 0
bUu2t	dc.b 1,0,1,0
	dc.w -146,2
	dc.l 0,bUu2tx,0
bUu2tx	dc.b "Prefix cut........",0
	even
eskimO	dc.l 0
	dc.w 172,79,70,12,6,9,3
	dc.l eskimOgr,0,eskimOt,0,eskimOs
	dc.w 0
	dc.l 0
eskimOgr	dc.w 0,0,11,9,2
	dc.l eskimOim
	dc.b 3,0
	dc.l 0
eskimOt	dc.b 1,0,1,0
	dc.w -156,2
	dc.l 0,eskimOtx,0
eskimOtx	dc.b "Module info.....",0
	even
eskimOs	dc.w 2,0,0,0,0
	dc.w 0,0,0,0,0,0
