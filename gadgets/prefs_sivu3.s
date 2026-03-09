DuU1	dc.l DuU2
	dc.w 84,37,158,12,0,1,1
	dc.l 0,0,DuU1t,0,0
	dc.w 0
	dc.l 0
DuU1t	dc.b 1,0,1,0
	dc.w -68,2
	dc.l 0,DuU1tx,0
DuU1tx	dc.b "Modules",0
	even
DuU2	dc.l DuU3
	dc.w 84,51,158,12,0,1,1
	dc.l 0,0,DuU2t,0,0
	dc.w 0
	dc.l 0
DuU2t	dc.b 1,0,1,0
	dc.w -68,2
	dc.l 0,DuU2tx,0
DuU2tx	dc.b "Programs",0
	even
DuU3	dc.l ack2
	dc.w 84,79,158,12,0,1,1
	dc.l 0,0,DuU3t,0,0
	dc.w 0
	dc.l 0
DuU3t	dc.b 1,0,1,0
	dc.w -68,2
	dc.l 0,DuU3tx,0
DuU3tx	dc.b "Archives",0
	even
ack2	dc.l ack4
	dc.w 88,94,150,8,0,1,4
	dc.l ack2gr,0,ack2t,0,ack2s
	dc.w 0
	dc.l 0
ack2gr	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ack2xy,ack2gr2
ack2xy	dc.w -2,7
	dc.w -2,-1
	dc.w 150,-1
ack2gr2	dc.w 0,0
	dc.b 2,0,1,3
	dc.l ack2xy2,ack2gr3
ack2xy2	dc.w 151,-1
	dc.w 151,8
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
	dc.w 152,-2
	dc.w 152,8
ack2gr6	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ack2xy6,ack2gr7
ack2xy6	dc.w 153,-2
	dc.w 153,9
	dc.w -4,9
ack2gr7	dc.w 0,0
	dc.b 1,0,1,2
	dc.l ack2xy7,0
ack2xy7	dc.w 154,-2
	dc.w 154,9
ack2t	dc.b 1,0,1,0
	dc.w -72,0
	dc.l 0,ack2tx,0
ack2tx	dc.b "LhA.....",0
	even
ack2s	dc.l ack2buf,0
	dc.w 0,200,0,0,0,0,0,0
	dc.l 0,0,0
ack2buf	ds.b 200
	even
ack4	dc.l ack3
	dc.w 88,108,150,8,0,1,4
	dc.l ack4gr,0,ack4t,0,ack4s
	dc.w 0
	dc.l 0
ack4gr	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ack4xy,ack4gr2
ack4xy	dc.w -2,7
	dc.w -2,-1
	dc.w 150,-1
ack4gr2	dc.w 0,0
	dc.b 2,0,1,3
	dc.l ack4xy2,ack4gr3
ack4xy2	dc.w 151,-1
	dc.w 151,8
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
	dc.w 152,-2
	dc.w 152,8
ack4gr6	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ack4xy6,ack4gr7
ack4xy6	dc.w 153,-2
	dc.w 153,9
	dc.w -4,9
ack4gr7	dc.w 0,0
	dc.b 1,0,1,2
	dc.l ack4xy7,0
ack4xy7	dc.w 154,-2
	dc.w 154,9
ack4t	dc.b 1,0,1,0
	dc.w -72,0
	dc.l 0,ack4tx,0
ack4tx	dc.b "LZX.....",0
	even
ack4s	dc.l ack4buf,0
	dc.w 0,200,0,0,0,0,0,0
	dc.l 0,0,0
ack4buf	ds.b 200
	even
ack3	dc.l nappu1
	dc.w 88,122,150,8,0,1,4
	dc.l ack3gr,0,ack3t,0,ack3s
	dc.w 0
	dc.l 0
ack3gr	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ack3xy,ack3gr2
ack3xy	dc.w -2,7
	dc.w -2,-1
	dc.w 150,-1
ack3gr2	dc.w 0,0
	dc.b 2,0,1,3
	dc.l ack3xy2,ack3gr3
ack3xy2	dc.w 151,-1
	dc.w 151,8
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
	dc.w 152,-2
	dc.w 152,8
ack3gr6	dc.w 0,0
	dc.b 1,0,1,3
	dc.l ack3xy6,ack3gr7
ack3xy6	dc.w 153,-2
	dc.w 153,9
	dc.w -4,9
ack3gr7	dc.w 0,0
	dc.b 1,0,1,2
	dc.l ack3xy7,0
ack3xy7	dc.w 154,-2
	dc.w 154,9
ack3t	dc.b 1,0,1,0
	dc.w -72,0
	dc.l 0,ack3tx,0
ack3tx	dc.b "Zip.....",0
	even
ack3s	dc.l ack3buf,0
	dc.w 0,200,0,0,0,0,0,0
	dc.l 0,0,0
ack3buf	ds.b 200
	even
nappu1	dc.l makkara
	dc.w 406,37,28,12,3,1,1
	dc.l 0,0,nappu1t,0,0
	dc.w 0
	dc.l 0
nappu1t	dc.b 1,0,1,0
	dc.w -148,2
	dc.l 0,nappu1tx,0
nappu1tx	dc.b "Doublebuffering...",0
	even
makkara	dc.l nappU2
	dc.w 406,51,28,12,3,1,1
	dc.l 0,0,makkarat,0,0
	dc.w 0
	dc.l 0
makkarat	dc.b 1,0,1,0
	dc.w -148,2
	dc.l 0,makkaratx,0
makkaratx	dc.b "XPK identify......",0
	even
nappU2	dc.l DuU0
	dc.w 406,65,28,12,3,1,1
	dc.l 0,0,nappU2t,0,0
	dc.w 0
	dc.l 0
nappU2t	dc.b 1,0,1,0
	dc.w -148,2
	dc.l 0,nappU2tx,0
nappU2tx	dc.b "XFDmaster library",0
	even
DuU0	dc.l 0
	dc.w 264,108,164,8,0,1,4
	dc.l DuU0gr,0,DuU0t,0,DuU0s
	dc.w 0
	dc.l 0
DuU0gr	dc.w 0,0
	dc.b 1,0,1,3
	dc.l DuU0xy,DuU0gr2
DuU0xy	dc.w -2,7
	dc.w -2,-1
	dc.w 163,-1
DuU0gr2	dc.w 0,0
	dc.b 2,0,1,3
	dc.l DuU0xy2,DuU0gr3
DuU0xy2	dc.w 164,-1
	dc.w 164,8
	dc.w -2,8
DuU0gr3	dc.w 0,0
	dc.b 1,0,1,2
	dc.l DuU0xy3,DuU0gr4
DuU0xy3	dc.w -1,7
	dc.w -1,0
DuU0gr4	dc.w 0,0
	dc.b 2,0,1,2
	dc.l DuU0xy4,DuU0gr5
DuU0xy4	dc.w -4,8
	dc.w -4,-2
DuU0gr5	dc.w 0,0
	dc.b 2,0,1,4
	dc.l DuU0xy5,DuU0gr6
DuU0xy5	dc.w -3,8
	dc.w -3,-2
	dc.w 165,-2
	dc.w 165,8
DuU0gr6	dc.w 0,0
	dc.b 1,0,1,3
	dc.l DuU0xy6,DuU0gr7
DuU0xy6	dc.w 166,-2
	dc.w 166,9
	dc.w -4,9
DuU0gr7	dc.w 0,0
	dc.b 1,0,1,2
	dc.l DuU0xy7,0
DuU0xy7	dc.w 167,-2
	dc.w 167,9
DuU0t	dc.b 1,0,1,0
	dc.w 10,-14
	dc.l 0,DuU0tx,0
DuU0tx	dc.b "File match pattern",0
	even
DuU0s	dc.l DuU0buf,0
	dc.w 0,70,0,0,0,0,0,0
	dc.l 0,0,0
DuU0buf	ds.b 70
	even
