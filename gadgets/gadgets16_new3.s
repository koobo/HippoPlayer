button1	dc.l button2
	dc.w 88,35,24,13,4,1,1
	dc.l button1gr,0,0,0,0
	dc.w 0
	dc.l 0
button1gr	dc.w 9,3,7,7,1
	dc.l button1im
	dc.b 1,0
	dc.l 0
button2	dc.l button3
	dc.w 244,35,12,13,4,1,1
	dc.l button2gr,0,0,0,0
	dc.w 0
	dc.l 0
button2gr	dc.w 3,2,5,9,1
	dc.l button2im
	dc.b 1,0
	dc.l 0
button3	dc.l button4
	dc.w 192,35,24,13,4,1,1
	dc.l button3gr,0,0,0,0
	dc.w 0
	dc.l 0
button3gr	dc.w 7,3,10,7,1
	dc.l button3im
	dc.b 1,0
	dc.l 0
button4	dc.l button5
	dc.w 218,35,24,13,4,1,1
	dc.l button4gr,0,0,0,0
	dc.w 0
	dc.l 0
button4gr	dc.w 6,3,12,7,1
	dc.l button4im
	dc.b 1,0
	dc.l 0
button5	dc.l button6
	dc.w 166,35,24,13,4,1,1
	dc.l button5gr,0,0,0,0
	dc.w 0
	dc.l 0
button5gr	dc.w 4,3,16,7,1
	dc.l button5im
	dc.b 1,0
	dc.l 0
button6	dc.l button7
	dc.w 8,35,24,13,4,1,1
	dc.l button6gr,0,0,0,0
	dc.w 0
	dc.l 0
button6gr	dc.w 4,3,16,7,1
	dc.l button6im
	dc.b 1,0
	dc.l 0
button7	dc.l button8
	dc.w 102,49,32,13,0,1,1
	dc.l 0,0,button7t,0,0
	dc.w 0
	dc.l 0
button7t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,button7tx,0
button7tx	dc.b "Add",0
	even
button8	dc.l slider1
	dc.w 136,49,32,13,0,1,1
	dc.l 0,0,button8t,0,0
	dc.w 0
	dc.l 0
button8t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,button8tx,0
button8tx	dc.b "Del",0
	even
slider1	dc.l slider4
	dc.w 9,50,54,12,7,9,3
	dc.l slider1gr,0,0,0,slider1s
	dc.w 0
	dc.l 0
slider1gr	dc.w 35,0,11,9,2
	dc.l slider1im
	dc.b 3,0
	dc.l 0
slider1s	dc.w 2,65535,0,0,0
	dc.w 0,0,0,0,0,0
slider4	dc.l button12
	dc.w 9,65,16,63,4,9,3
	dc.l slider4gr,0,0,0,slider4s
	dc.w 0
	dc.l 0
slider4gr	dc.w 0,0,8,4,0
	dc.l 0
	dc.b 0,0
	dc.l 0
slider4s	dc.w 5,65535,0,0,0
	dc.w 0,0,0,0,0,0
button12	dc.l button13
	dc.w 140,35,24,13,4,1,1
	dc.l button12gr,0,0,0,0
	dc.w 0
	dc.l 0
button12gr	dc.w 8,3,9,7,1
	dc.l button12im
	dc.b 1,0
	dc.l 0
button13	dc.l button11
	dc.w 34,35,26,13,4,1,1
	dc.l button13gr,0,0,0,0
	dc.w 0
	dc.l 0
button13gr	dc.w 8,3,9,7,1
	dc.l button13im
	dc.b 1,0
	dc.l 0
button11	dc.l button20
	dc.w 68,49,32,13,0,1,1
	dc.l 0,0,button11t,0,0
	dc.w 0
	dc.l 0
button11t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,button11tx,0
button11tx	dc.b "New",0
	even
button20	dc.l kela1
	dc.w 236,49,20,13,0,1,1
	dc.l 0,0,button20t,0,0
	dc.w 0
	dc.l 0
button20t	dc.b 1,0,1,0
	dc.w 2,3
	dc.l 0,button20tx,0
button20tx	dc.b "Pr",0
	even
kela1	dc.l kela2
	dc.w 62,35,24,13,4,1,1
	dc.l kela1gr,0,0,0,0
	dc.w 0
	dc.l 0
kela1gr	dc.w 5,3,14,7,1
	dc.l kela1im
	dc.b 1,0
	dc.l 0
kela2	dc.l plg
	dc.w 114,35,24,13,4,1,1
	dc.l kela2gr,0,0,0,0
	dc.w 0
	dc.l 0
kela2gr	dc.w 5,3,14,7,1
	dc.l kela2im
	dc.b 1,0
	dc.l 0
plg	dc.l lilb1
	dc.w 170,49,32,13,0,1,1
	dc.l 0,0,plgt,0,0
	dc.w 0
	dc.l 0
plgt	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,plgtx,0
plgtx	dc.b "Prg",0
	even
lilb1	dc.l lilb2
	dc.w 204,49,14,13,0,1,1
	dc.l 0,0,lilb1t,0,0
	dc.w 0
	dc.l 0
lilb1t	dc.b 1,0,1,0
	dc.w 3,3
	dc.l 0,lilb1tx,0
lilb1tx	dc.b "M",0
	even
lilb2	dc.l 0
	dc.w 220,49,14,13,0,1,1
	dc.l 0,0,lilb2t,0,0
	dc.w 0
	dc.l 0
lilb2t	dc.b 1,0,1,0
	dc.w 3,3
	dc.l 0,lilb2tx,0
lilb2tx	dc.b "S",0
	even
