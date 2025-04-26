ahiG1	dc.l ahiG2
	dc.w 70,51,364,12,0,1,1
	dc.l 0,0,ahiG1t,0,0
	dc.w 0
	dc.l 0
ahiG1t	dc.b 1,0,1,0
	dc.w -52,2
	dc.l 0,ahiG1tx,0
ahiG1tx	dc.b "Mode..",0
	even
ahiG2	dc.l ahiG3
	dc.w 158,37,28,12,3,1,1
	dc.l 0,0,ahiG2t,0,0
	dc.w 0
	dc.l 0
ahiG2t	dc.b 1,0,1,0
	dc.w -140,2
	dc.l 0,ahiG2tx,0
ahiG2tx	dc.b "Enable AHI.......",0
	even
ahiG3	dc.l ahiG4
	dc.w 406,37,28,12,3,1,1
	dc.l 0,0,ahiG3t,0,0
	dc.w 0
	dc.l 0
ahiG3t	dc.b 1,0,1,0
	dc.w -206,2
	dc.l 0,ahiG3tx,0
ahiG3tx	dc.b "Disable non-AHI replayers",0
	even
ahiG4	dc.l ahiG5
	dc.w 284,65,150,12,6,9,3
	dc.l ahiG4gr,0,ahiG4t,0,ahiG4s
	dc.w 0
	dc.l 0
ahiG4gr	dc.w 0,0,11,9,2
	dc.l ahiG4im
	dc.b 3,0
	dc.l 0
ahiG4t	dc.b 1,0,1,0
	dc.w -266,2
	dc.l 0,ahiG4tx,0
ahiG4tx	dc.b "Mixing rate..............",0
	even
ahiG4s	dc.w 2,0,0,0,0
	dc.w 0,0,0,0,0,0
ahiG5	dc.l ahiG6
	dc.w 284,79,150,12,4,9,3
	dc.l ahiG5gr,0,ahiG5t,0,ahiG5s
	dc.w 0
	dc.l 0
ahiG5gr	dc.w 0,0,11,9,2
	dc.l ahiG5im
	dc.b 3,0
	dc.l 0
ahiG5t	dc.b 1,0,1,0
	dc.w -266,2
	dc.l 0,ahiG5tx,0
ahiG5tx	dc.b "Master volume...............",0
	even
ahiG5s	dc.w 2,0,0,0,0
	dc.w 0,0,0,0,0,0
ahiG6	dc.l 0
	dc.w 284,93,150,12,4,9,3
	dc.l ahiG6gr,0,ahiG6t,0,ahiG6s
	dc.w 0
	dc.l 0
ahiG6gr	dc.w 0,0,11,9,2
	dc.l ahiG6im
	dc.b 3,0
	dc.l 0
ahiG6t	dc.b 1,0,1,0
	dc.w -266,2
	dc.l 0,ahiG6tx,0
ahiG6tx	dc.b "Stereo level.................",0
	even
ahiG6s	dc.w 2,0,0,0,0
	dc.w 0,0,0,0,0,0
