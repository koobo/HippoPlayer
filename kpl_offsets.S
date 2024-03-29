	rsreset				* Routine offsets, kplayer+kp_????
kp_init		rs.l	1
kp_music	rs.l	1
kp_end		rs.l	1
kp_setmaster	rs.l	1
kp_channelmask	rs.l	1
kp_playstop	rs.l	1
kp_clear	rs.l	1
kp_baseaddress	rs.l	1	* This is where the k_base addr is stored.

* channel data blocks
	rsreset
n_data		rs.l	1
n_start		rs.l	1	* Sample start address
n_length	rs	1	* Sample length (words)
n_volume	rs	1	* Volume
n_periodaddr	rs.l	1
n_loopstart	rs.l	1	* Loopstart
n_replen	rs	1	* Looplength
n_wavestart	rs.l	1
n_period	rs	1	* Period
n_dmabit	rs	1
n_toneportspeed	rs	1
n_wantedperiod	rs	1
n_pattpos	rs	1
n_period2	rs	1
n_tempvol	rs	1
n_sampleoffset	rs	1
n_vibratopos	rs.b	1
n_tremolopos	rs.b	1
n_toneportdirec	rs.b	1
n_vibratocmd	rs.b	1
n_tremolocmd	rs.b	1
n_loopcount	rs.b	1
n_funkoffset	rs.b	1
n_funkspeed	rs.b	1
n_retrig	rs.b	1
n_glisscontrol	rs.b	1


n_flag		rs	1
n_buffer	rs.l	1	* chip buffer (1kb)
n_datapointer	rs.l	1
n_datalength	rs.l	1
n_datarepointer	rs.l	1
n_datarelength	rs.l	1

n_sizeof	rs.b	0	* channel temp size

* variables & data
	rsreset	
k_counter	rs.b	1
k_speed		rs.b	1
k_posjumpflag	rs.b	1
k_pbreakflag	rs.b	1
k_pattdeltime	rs.b	1
k_pattdeltime2	rs.b	1
k_songpos	rs	1		* Song position
k_pbreakpos	rs	1
k_patternpos	rs	1		* Patternposition
k_dma		rs	1
k_mastervolume	rs	1
k_songdataptr	rs.l	1
k_fast		rs.b	1		* <>0: samplet fastissa
k_timingmode 	rs.b	1

k_filterstore	rs.b	1
k_trig		rs.b	1
k_tempo		rs.b	1
k_usetempo	rs.b	1		* ~0: ei tempoa
k_usertrig	rs.b	1		* User trigger
k_sysint	rs.b	1
k_playmusic	rs.b	1		* 0 = play
k_songover	rs.b	1		* Song played n times
k_chmask	rs.b	1		* Kanavamaski
k_intid		rs.b	1
k_whichtimer	rs.b	1
	rs.b	1

k_timerhi	rs.b	1
k_timerlo	rs.b	1
k_timervalue	rs.l	1
k_ciabase	rs.l	1		* cia?.resource base
k_cia		rs.l	1		* ciab tai ciaa osoite

k_null		rs.l	1
k_oldis1	rs.l	1
k_oldis2	rs.l	1
k_oldis3	rs.l	1
k_oldis4	rs.l	1

k_mt		rs.l	31		* Sampleaddresses

k_chan1temp	rs.b	n_sizeof	* Channel data blocks
k_chan2temp	rs.b	n_sizeof
k_chan3temp	rs.b	n_sizeof
k_chan4temp	rs.b	n_sizeof

k_roundtable	rs.b	1512

k_sizeof	rs.b	0		* size of k_base

