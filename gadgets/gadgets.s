button1	dc.l button2
	dc.w 42,35,40,13,0,1,1
	dc.l button1gr,0,button1t,0,0
	dc.w 0
	dc.l 0
button1gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button1xy,button1gr2
button1xy	dc.w 0,12
	dc.w 0,0
	dc.w 39,0
button1gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button1xy2,0
button1xy2	dc.w 39,1
	dc.w 39,12
	dc.w 1,12
button1t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,button1tx,0
button1tx	dc.b "Play",0
	even
button2	dc.l button3
	dc.w 84,35,40,13,0,1,1
	dc.l button2gr,0,button2t,0,0
	dc.w 0
	dc.l 0
button2gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button2xy,button2gr2
button2xy	dc.w 0,12
	dc.w 0,0
	dc.w 39,0
button2gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button2xy2,0
button2xy2	dc.w 39,1
	dc.w 39,12
	dc.w 1,12
button2t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,button2tx,0
button2tx	dc.b "Cont",0
	even
button3	dc.l button4
	dc.w 126,35,40,13,0,1,1
	dc.l button3gr,0,button3t,0,0
	dc.w 0
	dc.l 0
button3gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button3xy,button3gr2
button3xy	dc.w 0,12
	dc.w 0,0
	dc.w 39,0
button3gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button3xy2,0
button3xy2	dc.w 39,1
	dc.w 39,12
	dc.w 1,12
button3t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,button3tx,0
button3tx	dc.b "Stop",0
	even
button4	dc.l button5
	dc.w 168,35,48,13,0,1,1
	dc.l button4gr,0,button4t,0,0
	dc.w 0
	dc.l 0
button4gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button4xy,button4gr2
button4xy	dc.w 0,12
	dc.w 0,0
	dc.w 47,0
button4gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button4xy2,0
button4xy2	dc.w 47,1
	dc.w 47,12
	dc.w 1,12
button4t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,button4tx,0
button4tx	dc.b "Eject",0
	even
button5	dc.l button6
	dc.w 50,49,40,13,0,1,1
	dc.l button5gr,0,button5t,0,0
	dc.w 0
	dc.l 0
button5gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button5xy,button5gr2
button5xy	dc.w 0,12
	dc.w 0,0
	dc.w 39,0
button5gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button5xy2,0
button5xy2	dc.w 39,1
	dc.w 39,12
	dc.w 1,12
button5t	dc.b 1,0,1,0
	dc.w 5,3
	dc.l 0,button5tx,0
button5tx	dc.b "Next",0
	even
button6	dc.l button7
	dc.w 8,49,40,13,0,1,1
	dc.l button6gr,0,button6t,0,0
	dc.w 0
	dc.l 0
button6gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button6xy,button6gr2
button6xy	dc.w 0,12
	dc.w 0,0
	dc.w 39,0
button6gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button6xy2,0
button6xy2	dc.w 39,1
	dc.w 39,12
	dc.w 1,12
button6t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,button6tx,0
button6tx	dc.b "Prev",0
	even
button7	dc.l button8
	dc.w 156,49,32,13,0,1,1
	dc.l button7gr,0,button7t,0,0
	dc.w 0
	dc.l 0
button7gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button7xy,button7gr2
button7xy	dc.w 0,12
	dc.w 0,0
	dc.w 31,0
button7gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button7xy2,0
button7xy2	dc.w 31,1
	dc.w 31,12
	dc.w 1,12
button7t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,button7tx,0
button7tx	dc.b "Add",0
	even
button8	dc.l button9
	dc.w 190,49,32,13,0,1,1
	dc.l button8gr,0,button8t,0,0
	dc.w 0
	dc.l 0
button8gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button8xy,button8gr2
button8xy	dc.w 0,12
	dc.w 0,0
	dc.w 31,0
button8gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button8xy2,0
button8xy2	dc.w 31,1
	dc.w 31,12
	dc.w 1,12
button8t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,button8tx,0
button8tx	dc.b "Del",0
	even
button9	dc.l slider1
	dc.w 224,49,32,13,0,1,1
	dc.l button9gr,0,button9t,0,0
	dc.w 0
	dc.l 0
button9gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button9xy,button9gr2
button9xy	dc.w 0,12
	dc.w 0,0
	dc.w 31,0
button9gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button9xy2,0
button9xy2	dc.w 31,1
	dc.w 31,12
	dc.w 1,12
button9t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,button9tx,0
button9tx	dc.b "Clr",0
	even
slider1	dc.l slider4
	dc.w 12,65,60,9,6,9,3
	dc.l slider1gr,0,0,0,slider1s
	dc.w 0
	dc.l 0
slider1gr	dc.w 45,0,7,7,2
	dc.l slider1im
	dc.b 3,0
	dc.l 0
slider1s	dc.w 2,65535,65535,0,0
	dc.w 0,0,0,0,0,0
slider4	dc.l button12
	dc.w 11,78,14,68,4,9,3
	dc.l slider4gr,0,0,0,slider4s
	dc.w 0
	dc.l 0
slider4gr	dc.w 0,0,6,4,0
	dc.l 0
	dc.b 0,0
	dc.l 0
slider4s	dc.w 5,65535,0,0,0
	dc.w 0,0,0,0,0,0
button12	dc.l button13
	dc.w 124,49,26,13,0,1,1
	dc.l button12gr,0,button12t,0,0
	dc.w 0
	dc.l 0
button12gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button12xy,button12gr2
button12xy	dc.w 0,12
	dc.w 0,0
	dc.w 25,0
button12gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button12xy2,0
button12xy2	dc.w 25,1
	dc.w 25,12
	dc.w 1,12
button12t	dc.b 1,0,1,0
	dc.w 5,3
	dc.l 0,button12tx,0
button12tx	dc.b "NS",0
	even
button13	dc.l button11
	dc.w 96,49,26,13,0,1,1
	dc.l button13gr,0,button13t,0,0
	dc.w 0
	dc.l 0
button13gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button13xy,button13gr2
button13xy	dc.w 0,12
	dc.w 0,0
	dc.w 25,0
button13gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button13xy2,0
button13xy2	dc.w 25,1
	dc.w 25,12
	dc.w 1,12
button13t	dc.b 1,0,1,0
	dc.w 5,3
	dc.l 0,button13tx,0
button13tx	dc.b "PS",0
	even
button11	dc.l button20
	dc.w 8,35,32,13,0,1,1
	dc.l button11gr,0,button11t,0,0
	dc.w 0
	dc.l 0
button11gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button11xy,button11gr2
button11xy	dc.w 0,12
	dc.w 0,0
	dc.w 31,0
button11gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button11xy2,0
button11xy2	dc.w 31,1
	dc.w 31,12
	dc.w 1,12
button11t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,button11tx,0
button11tx	dc.b "New",0
	even
button20	dc.l kela1
	dc.w 106,63,46,13,0,1,1
	dc.l button20gr,0,button20t,0,0
	dc.w 0
	dc.l 0
button20gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button20xy,button20gr2
button20xy	dc.w 0,12
	dc.w 0,0
	dc.w 45,0
button20gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button20xy2,0
button20xy2	dc.w 45,1
	dc.w 45,12
	dc.w 1,12
button20t	dc.b 1,0,1,0
	dc.w 3,3
	dc.l 0,button20tx,0
button20tx	dc.b "Prefs",0
	even
kela1	dc.l kela2
	dc.w 222,35,16,13,0,1,1
	dc.l kela1gr,0,kela1t,0,0
	dc.w 0
	dc.l 0
kela1gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l kela1xy,kela1gr2
kela1xy	dc.w 0,12
	dc.w 0,0
	dc.w 15,0
kela1gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l kela1xy2,0
kela1xy2	dc.w 15,1
	dc.w 15,12
	dc.w 1,12
kela1t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,kela1tx,0
kela1tx	dc.b "<",0
	even
kela2	dc.l plg
	dc.w 240,35,16,13,0,1,1
	dc.l kela2gr,0,kela2t,0,0
	dc.w 0
	dc.l 0
kela2gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l kela2xy,kela2gr2
kela2xy	dc.w 0,12
	dc.w 0,0
	dc.w 15,0
kela2gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l kela2xy2,0
kela2xy2	dc.w 15,1
	dc.w 15,12
	dc.w 1,12
kela2t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,kela2tx,0
kela2tx	dc.b ">",0
	even
plg	dc.l slg
	dc.w 206,63,24,13,0,1,1
	dc.l plggr,0,plgt,0,0
	dc.w 0
	dc.l 0
plggr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l plgxy,plggr2
plgxy	dc.w 0,12
	dc.w 0,0
	dc.w 23,0
plggr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l plgxy2,0
plgxy2	dc.w 23,1
	dc.w 23,12
	dc.w 1,12
plgt	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,plgtx,0
plgtx	dc.b "Lp",0
	even
slg	dc.l lilb1
	dc.w 232,63,24,13,0,1,1
	dc.l slggr,0,slgt,0,0
	dc.w 0
	dc.l 0
slggr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l slgxy,slggr2
slgxy	dc.w 0,12
	dc.w 0,0
	dc.w 23,0
slggr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l slgxy2,0
slgxy2	dc.w 23,1
	dc.w 23,12
	dc.w 1,12
slgt	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,slgtx,0
slgtx	dc.b "Sp",0
	even
lilb1	dc.l lilb2
	dc.w 154,63,24,13,0,1,1
	dc.l lilb1gr,0,lilb1t,0,0
	dc.w 0
	dc.l 0
lilb1gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l lilb1xy,lilb1gr2
lilb1xy	dc.w 0,12
	dc.w 0,0
	dc.w 23,0
lilb1gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l lilb1xy2,0
lilb1xy2	dc.w 23,1
	dc.w 23,12
	dc.w 1,12
lilb1t	dc.b 1,0,1,0
	dc.w 4,3
	dc.l 0,lilb1tx,0
lilb1tx	dc.b "Mo",0
	even
lilb2	dc.l button10
	dc.w 180,63,24,13,0,1,1
	dc.l lilb2gr,0,lilb2t,0,0
	dc.w 0
	dc.l 0
lilb2gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l lilb2xy,lilb2gr2
lilb2xy	dc.w 0,12
	dc.w 0,0
	dc.w 23,0
lilb2gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l lilb2xy2,0
lilb2xy2	dc.w 23,1
	dc.w 23,12
	dc.w 1,12
lilb2t	dc.b 1,0,1,0
	dc.w 3,3
	dc.l 0,lilb2tx,0
lilb2tx	dc.b "In",0
	even
button10	dc.l 0
	dc.w 80,63,24,13,0,1,1
	dc.l button10gr,0,button10t,0,0
	dc.w 0
	dc.l 0
button10gr	dc.w 0,0
	dc.b 2,0,1,3
	dc.l button10xy,button10gr2
button10xy	dc.w 0,12
	dc.w 0,0
	dc.w 23,0
button10gr2	dc.w 0,0
	dc.b 1,0,1,3
	dc.l button10xy2,0
button10xy2	dc.w 23,1
	dc.w 23,12
	dc.w 1,12
button10t	dc.b 1,0,1,0
	dc.w 8,3
	dc.l 0,button10tx,0
button10tx	dc.b "?",0
	even
