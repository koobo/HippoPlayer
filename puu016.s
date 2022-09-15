;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
*******************************************************************************
*                                HippoPlayer
*******************************************************************************
* Aloitettu 5.2.-94

ver	macro
;	dc.b	"v2.30 (5.8.1996)"
;	dc.b	"v2.31ﬂA (24.8.-96)"
;	dc.b	"v2.31ﬂC (?.?.1996)"
;	dc.b	"v2.35 (23.11.1996)"
;	dc.b	"v2.37 (31.12.1996)"
;	dc.b	"v2.38 (9.2.1997)"
;	dc.b	"v2.40 (29.6.1997)"
;	dc.b	"v2.41 (25.10.1997)"
;	dc.b	"v2.42 (20.12.1997)"
;	dc.b	"v2.44 (16.8.1998)"
;	dc.b	"v2.44 (16.8.1998)"
;	dc.b	"v2.45 (10.1.2000)"
;	dc.b	"v2.47ﬂ (?.?.2021)"
;	dc.b	"v2.47 (31.8.2021)"
;	dc.b	"v2.48 (31.10.2021)"
;	dc.b	"v2.49ﬂ (?.?.2021)"
;	dc.b	"v2.49 (29.11.2021)"
;	dc.b	"v2.50ﬂ (?.?.202?)"
;	dc.b	"v2.50 (31.12.2021)"
;	dc.b	"v2.52ﬂ (?.?.202?)"
;	dc.b	"v2.52 (30.4.2022)"
;	dc.b	"v2.53 (13.7.2022)"
;	dc.b	"v2.54ﬂ (?.?.2022)"
;	dc.b	"v2.54 (30.8.2022)"
	dc.b	"v2.55ﬂ (?.?.2022)"
	endm	

 ifnd DEBUG
* AsmOne setting:
* Enable debug logging 
DEBUG = 1
 endif

 ifnd __VASM
* AsmOne setting:
* 1: Run from AsmOne
* 0: CLI/Workbench  
asm = 1
 else
asm = 0
 endif


BETA	= 0	* 0: ei beta, 1: public beta, 2: private beta
zoom	= 0	* 1: zoomaava hippo
fprog	= 0 * 1: file add progress indicator, ei oikein toimi (kaataa)
floadpr = 1	* 1: unpacked file load progress indicator
PILA	= 0	* 1: pikku pila niille joilla on wRECin key muttei 060:aa
TARK	= 0	* 1: tekstien tarkistus
EFEKTI  = 0	* 1: efekti volumesliderill‰
ANNOY	= 0 * 1: Unregistered version tekstej‰ ymp‰riins‰

DELI_TEST_MODE 		= 	0
FEATURE_FREQSCOPE	=	0
FEATURE_SPECTRUMSCOPE	= 	1
FEATURE_HORIZ_RESIZE = 1
FEATURE_P61A        =   0
FEATURE_UHC_AMINET  =   0

 ifeq (FEATURE_FREQSCOPE+FEATURE_SPECTRUMSCOPE)
    fail "Enable only one"
 endif
 
 ifeq (FEATURE_FREQSCOPE+FEATURE_SPECTRUMSCOPE-2)
    fail "Enable only one"
 endif

; Magic constants used with playingmodule and chosenmodule
; Positive value:
; - playingmodule: index of the module being played
; - chosenmodule: index of the module that is selected
; Negative value: 
; - playingmodule: there is no module being played 
; - chosenmodule: there is no module chosen in the list
; Special value 0x7fffffff: 
; - playingmodule: there is a module being played, but it is not in the list (deleted or list cleared)
; - chosenmodule: TODO, what is it
PLAYING_MODULE_NONE 	= -1	 	* needs to be negative
PLAYING_MODULE_REMOVED	= $7fffffff	* needs to be positive
MAX_MODULES		= $1ffff 		    * this should be enough!


	
 ;ifne TARK
 ;ifeq asm
 ;printt "Onko CHECKSUMMI oikea? Molemmat!"
 ;printt "Onko CHECKSUMMI oikea?"
 ;endc
 ;endc
 

WINX	= 2	* X ja Y lis‰ykset p‰‰ikkunan grafiikkaan
WINY	= 3

* This char as the first char in filename indicates a list divider
DIVIDER_MAGIC = '˜'

;isListDivider macro 
;	cmp.b 	#DIVIDER_MAGIC,\1
;	endm

isFavoriteModule macro 
	tst.b 	l_favorite(\1)
	endm

;
;* Checks if list is in favorite mode
;* Z is set if in normal mode, otherwise favorite mode
;isListInFavoriteMode macro
;	cmp.b #LISTMODE_FAVORITES,listMode(a5)
;	endm
;

iword	macro
	ror	#8,\1
	endm

ilword	macro
	ror	#8,\1
	swap	\1
	ror	#8,\1
	endm

tlword	macro
	move.b	\1,\2
	ror.l	#8,\2
	move.b	\1,\2
	ror.l	#8,\2
	move.b	\1,\2
	ror.l	#8,\2
	move.b	\1,\2
	ror.l	#8,\2
	endm

tword	macro
	move.b	\1,\2
	ror	#8,\2
	move.b	\1,\2
	ror	#8,\2
	endm

***** Tarkistaa rekisterˆitymiseen liittyv‰t tekstit


check	macro

 ifne TARK
 ifeq asm
	lea	CHECKSTART(pc),a0	
	moveq	#0,d0
	moveq	#0,d1
	moveq	#8,d2
.qghg\1	move.b	(a0)+,d1
	neg.b	d1
	add	d2,d0
	add	d1,d0
	addq	#1,d2
	cmp.b	#$ff,(a0)
	bne.b	.qghg\1
 ifeq BETA
	tst.b	eicheck(a5)
	bne.b	.fghz\1
	sub	textchecksum(a5),d0
	sne	exitmainprogram(a5)
.fghz\1
 endc
 endc
 endc

	endm


 	incdir	include:
	include	exec/exec_lib.i
	include	exec/ports.i
	include	exec/types.i
	include	exec/execbase.i
	include	exec/memory.i
	include	exec/lists.i
	include exec/semaphores.i

	include	graphics/gfxbase.i
	include	graphics/graphics_lib.i
	include	graphics/rastport.i
	include graphics/scale.i
	include	graphics/text.i

;	include	graphics/rpattr.i

	include	intuition/intuition_lib.i
	include	intuition/intuition.i

	include	dos/dos_lib.i
	include	dos/dosextens.i

	include	rexx/rxslib.i

	include	devices/audio.i
	include	devices/input.i
	include	devices/inputevent.i

	include	workbench/startup.i
	include	workbench/workbench.i
	include	workbench/wb_lib.i

	include	hardware/intbits.i
	include	hardware/cia.i

	include	resources/cia_lib.i
	include	libraries/diskfont_lib.i
	


	include	libraries/powerpacker_lib.i
	include	libraries/reqtools.i
	include	libraries/reqtools_lib.i
	include	libraries/xpk.i
	include	libraries/xpkmaster_lib.i
	include	libraries/playsidbase.i
	include	libraries/playsid_lib.i
	include	libraries/xfdmaster_lib.i
	include	libraries/xfdmaster.i
	include	libraries/screennotify_lib.i
	include	libraries/screennotify.i
	include	graphics/layers_lib.i
	
	include	devices/ahi.i
	include	devices/ahi_lib.i

	include	misc/deliplayer.i
	include	misc/eagleplayer.i

	include	math/mathffp_lib.i
	include	math/mathtrans_lib.i
	
	include	libraries/timer_lib.i
	include	devices/timer.i
	include	intuition/sghooks.i

	incdir include/
	include	mucro.i
	include	med.i
	include	Guru.i
	include	ps3m.i
	include	patternInfo.i
use = 0
	include	player61.i

	include	playerIds.i
	include	kpl_offsets.S

*******************************************************************************
*
* Prefs tiedoston rakenne
*

prefsversio	=	21	* Prefs-tiedoston versio
		rsreset
prefs_versio		rs.b	1
prefs_play		rs.b	1
prefs_show		rs.b	1
prefs_tempo		rs.b	1
prefs_tfmxrate		rs.b	1
prefs_s3mmode1		rs.b	1
prefs_s3mmode2		rs.b	1
prefs_s3mmode3		rs.b	1
prefs_ps3mb		rs.b	1
prefs_timeoutmode	rs.b	1
XXXprefs_quadmode	rs.b	1
XXXprefs_quadon		rs.b	1		* 1: quad oli p‰‰ll‰
prefs_ptmix		rs.b	1		* 0: chip, 1: fast, 2: ps3m
prefs_xpkid		rs.b	1
prefs_fade		rs.b	1
prefs_pri		rs.b	1
prefs_boxsize		rs.b	1
prefs_infoon		rs.b	1
prefs_doubleclick	rs.b	1
prefs_startuponoff	rs.b	1
prefs_hotkey		rs.b	1
prefs_cerr		rs.b	1
prefs_nasty		rs.b	1
prefs_dbf		rs.b	1
prefs_filter		rs.b	1
prefs_vbtimer		rs.b	1
prefs_timeout		rs	1
prefs_s3mrate		rs.l	1
prefs_mainpos1		rs.l	1
prefs_mainpos2		rs.l	1
prefs_prefspos		rs.l	1
Xprefs_quadpos		rs.l	1
			rs	1
prefs_alarm		rs	1
prefs_moddir		rs.b	150
prefs_prgdir		rs.b	150-1
prefs_stereofactor	rs.b	1
prefs_arclha		rs.b	100
prefs_arczip		rs.b	100
prefs_arclzx		rs.b	100
prefs_pubscreen		rs.b	MAXPUBSCREENNAME+1
prefs_startup		rs.b	120
prefs_fkeys		rs.b	120*10
prefs_textattr		rs.b	ta_SIZEOF-4
prefs_fontname		rs.b	20
prefs_groupmode		rs.b	1
prefs_groupname		rs.b	99
prefs_div		rs.b	1
prefs_early		rs.b	1
prefs_prefix		rs.b	1
prefs_xfd		rs.b	1
			rs.l	1
prefs_infopos2		rs.l	1
prefs_arcdir		rs.b	150
prefs_pattern		rs.b	70
prefs_infosize		rs	1
prefs_ps3msettings	rs.b	1
prefs_prefsivu		rs.b	1
prefs_kokolippu		rs.b	1		* 0: ikkuna pieni
prefs_samplebufsiz	rs.b	1
prefs_cybercalibration	rs.b 1
prefs_calibrationfile	rs.b	99
prefs_forcerate		rs	1

prefs_ahi_use		rs.b	1
prefs_ahi_muutpois	rs.b	1
prefs_ahi_rate		rs.l	1
prefs_ahi_mastervol	rs	1
prefs_ahi_stereolev	rs	1
prefs_ahi_mode		rs.l	1
prefs_ahi_name		rs.b	44

prefs_autosort		rs.b	1

prefs_samplecyber	rs.b	1
prefs_mpegaqua		rs.b	1
prefs_mpegadiv		rs.b	1
prefs_medmode		rs.b	1
prefs_favorites		rs.b	1
prefs_medrate		rs	1

prefs_tooltips		rs.b 	1
prefs_savestate		rs.b 	1
prefs_altbuttons	rs.b	1

prefs_quadraScope   rs.b 1
prefs_quadraScopeBars   rs.b 1
prefs_quadraScopeF   rs.b 1
prefs_quadraScopeFBars   rs.b 1
prefs_hippoScope   rs.b 1
prefs_hippoScopeBars   rs.b 1
prefs_patternScope   rs.b 1
prefs_patternScopeXL   rs.b 1
prefs_spectrumScope   rs.b 1
prefs_spectrumScopeBars   rs.b 1
	rs.b 1
	
prefs_quadraScopePos   rs.l 1
prefs_quadraScopeFPos   rs.l 1
prefs_hippoScopePos   rs.l 1
prefs_patternScopePos   rs.l 1
prefs_spectrumScopePos   rs.l 1

prefs_listtextattr		rs.b	ta_SIZEOF-4
prefs_listfontname		rs.b	30

	printt "TODO TODO: dangerous buffer size"

prefs_size		rs.b	0

*******************************************************************************
*
* Scope variables for one audio channel
* Values are copied here from replay code internal structures.
* Originally only Protracker supported, now also many others.

* Scope data for one channel
* This should correspond go the "PTch" structure in hippoport
              rsreset
ns_start      rs.l       1 * Sample start address
ns_length     rs         1 * Length in words
ns_loopstart  rs.l       1 * Loop start address
ns_replen     rs         1 * Loop length in words
ns_tempvol    rs         1 * Volume
ns_period     rs         1 * Period
;Unused:
;ns_tempvol2	rs	1
ns_size       rs.b       0 * = 16 bytes

* Combined scope data structure
              rsreset
scope_ch1	  rs.b	ns_size
scope_ch2	  rs.b	ns_size
scope_ch3	  rs.b	ns_size
scope_ch4	  rs.b	ns_size
scope_trigger rs.b  1 * Audio channel enable DMA flags
scope_pad	  rs.b  1
scope_size    rs.b  0

 if ns_size<>16
    fail "This is assumed to be 16 in code"
 endif

*******************************************************************************
*
* Message sent to HippoPort by another instances of Hippo
*

MESSAGE_MAGIC_ID = "K-P!"
MESSAGE_COMMAND_HIDE = "HIDE"
MESSAGE_COMMAND_QUIT = "QUIT"
MESSAGE_COMMAND_PRG = "PRGM"

	STRUCTURE 	HippoMessage,MN_SIZE
	LONG		HM_Identifier	* "K-P!"
	APTR		HM_Arguments	* sv_argvArray. May contain above commands
	LABEL		HippoMessage_SIZEOF 

*******************************************************************************
*
* "HiP-Port" structure
*

	STRUCTURE	HippoPort,MP_SIZE
	LONG		hip_private1	* Private..
	APTR		hip_kplbase	* Protracker replayer data area
	WORD		hip_reserved0	* Private..
	BYTE		hip_quit	* If non-zero, your program should quit
	BYTE		hip_opencount	* Open count
	BYTE		hip_mainvolume	* Main volume, 0-64
	BYTE		hip_play	* If non-zero, HiP is playing
	BYTE		hip_playertype 	* 33 = Protracker, 49 = PS3M. 

	*** Protracker ***
	BYTE		hip_reserved2
	APTR		hip_PTch1	* Protracker channel data for ch1
	APTR		hip_PTch2	* ch2
	APTR		hip_PTch3	* ch3
	APTR		hip_PTch4	* ch4

	*** PS3M ***
	APTR		hip_ps3mleft	* Buffer for the left side
	APTR		hip_ps3mright	* Buffer for the right side
	LONG		hip_ps3moffs	* Playing position
	LONG		hip_ps3mmaxoffs	* Max value for hip_ps3moffs

	BYTE		hip_PTtrigger1
	BYTE		hip_PTtrigger2
	BYTE		hip_PTtrigger3
	BYTE		hip_PTtrigger4

	APTR		hip_moduleListHeader	* pointer to the moduleListHeader of modules
	LONG		hip_playtime	* time played in secs
	LONG		hip_colordiv	*
	WORD		hip_ps3mrate	* ps3m mix rate

	LABEL		HippoPort_SIZEOF 


	*** PT channel data block
	STRUCTURE	PTch,0
	LONG		PTch_start	* Start address of sample
	WORD		PTch_length	* Length of sample in words
	LONG		PTch_loopstart	* Start address of loop
	WORD		PTch_replen	* Loop length in words
	WORD		PTch_volume	* Channel volume
	WORD		PTch_period	* Channel period
	WORD		PTch_private1	* Private...
	

*******************************************************************************
*
* Global variables and work space
*

	rsreset
_ExecBase	rs.l	1
_GFXBase	rs.l	1
_IntuiBase	rs.l	1
_DosBase	rs.l	1
_ReqBase	rs.l	1
_WBBase		rs.l	1
_RexxBase	rs.l	1
_ScrNotifyBase	rs.l	1
_DiskFontBase	rs.l	1
_PPBase		rs.l	1
_XPKBase	rs.l	1
_SIDBase	rs.l	1
_MedPlayerBase	rs.l	1
_MedPlayerBase1	rs.l	1
_MedPlayerBase2	rs.l	1
_MedPlayerBase3	rs.l	1
_MlineBase		rs.l	1
_XFDBase	rs.l	1
_FFPBase	rs.l 1
_MTBase     rs.l 1
_LayersBase rs.l 1
 ifne DEBUG
output		rs.l	1
 endc

sidlibstore1	rs.l	2		* pSid kick13 patchin varasto
sidlibstore2	rs.l	2

owntask		rs.l	1
lockhere	rs.l	1		* currentdir-lock
homelock	rs.l 	1		* homedir-lock (V36)
cli			rs.l	1
segment		rs.l	1	* Toisiks ekan hunkin segmentti
* Fileinfoblock used by main task
fileinfoblock	rs.b	260		* 4:ll‰ jaollisessa osoitteessa!
* Fileinfoblock used by file req task
fileinfoblock2	rs.b	260		

 if fileinfoblock&%11
	fail Not divisible by 4
 endif
 if fileinfoblock2&%11
	fail Not divisible by 4
 endif

filecomment	rs.b	80+4		* tiedoston kommentti
windowbase	rs.l	1		* p‰‰ohjelma
mainWindowLock rs.l 1
appwindow	rs.l	1		* appwindowbase
screenlock	rs.l	1
rastport	rs.l	1		*
userport	rs.l	1		*
windowbase2	rs.l	1		* prefs
rastport2	rs.l	1		* 
userport2	rs.l	1		*
fontbase	rs.l	1		* ordinary font to be used everywhere
topazbase	rs.l	1
minifontbase 	rs.l	1
listfontbase	rs.l	1		* points to some font base
notifyhandle	rs.l	1		* Screennotifylle
windowtop	rs	1		* ikkunoiden eisysteemialueen yl‰reuna
windowright	rs	1
windowleft	rs	1
windowbottom	rs	1
windowtopb	rs	1		* sc_BorTop
gotscreeninfo	rs.b	1
infolag		rs.b	1 * mit‰ n‰ytet‰‰n infoikkunassa: 0=sample, ~0=about

infotaz		rs.l	1 * infoikkunan datan osoite

listFontHeight	rs.w	1

windowtop2	rs	1
windowleft2	rs	1
windowbottom2	rs	1


nilfile		rs.l	1		* NIL:

keycheckroutine	rs.l	1		* check_keyfile rutiinin osoite

pen_0		rs.l	1		* piirtokyn‰t
pen_1		rs.l	1
pen_2		rs.l	1
pen_3		rs.l	1

WINSIZX		rs	1		* p‰‰ikkunan koot
WINSIZY		rs	1

previousWindowWidth 	rs 	1
previousWindowHeight 	rs 	1

eicheck		rs.b	1
reghippo	rs.b 	1 		* ensimm‰inen hippo hieman sivummalle

req_file	rs.l	1		* p‰‰requesteri
req_file2	rs.l	1		* load/save program
req_file3	rs.l	1		* prefs
kokolippu	rs	1		* 0: pieni
windowpos	rs	2		* Ison ikkunan paikka
windowZippedPos	rs	2	* Pienen ikkunan paikka (ZipWindow). Must be together
windowZippedSize rs	2	* ja koko
infopos2	rs	2		* sampleikkunan ja sidinfon paikka

screenaddr	rs.l	1		* N‰ytˆn osoite
windowpos_p	rs	2		* Prefs ikkunan paikka
Xquadpos		rs	2		* Quad-ikkunan paikka
wbkorkeus	rs	1		* Workbench n‰ytˆn korkeus
wbleveys	rs	1
prefs_prosessi	rs	1		* ei-0: Prefs-prosessi p‰‰ll‰
filereq_prosessi rs	1		* ei-0: Files-prosessi p‰‰ll‰
info_prosessi	rs	1		* ...
about_moodi	rs.b	1		* 0: normaali, 1: moduleinfo
filereqmode	rs.b	1		* 0: add mode, ~0: insert mode 
fileinsert	rs.l	1		* node jonka j‰lkeen insertti
haluttiinuusimodi rs	1		* new-nappulaa ja play:t‰ varten
confirmFavoritesModificationDisabled		rs.b	1
infoon		rs.b	1		* 1: info on

exitmainprogram	rs.b	1		* <>1: poistu ohjelmasta
startuperror	rs.b	1		* virhe k‰ynnistyksess‰
oldchip		rs	1		* free memille vertailua varten
oldfast		rs	1		* ...

prefsexit	rs.b	1		* ~0: prefssist‰ poistuttu
lprgadd		rs.b	1		* ~0: loadprg addaa vanhan per‰‰n (join)
prefsivu	rs	1		* 0..5: sivu prefs-ikkunassa
prefsivugads	rs.l	1		* vastaavien gadgettien alkuosoite

seed		rs.l	1		* randomgeneratorin SEED
freezegads	rs.b	1		* ~0: Mainwindowin gadgetit OFF
hippoporton	rs.b	1		* ~0: hippo portti initattu

ciasaatu	rs.b	1		* 1: saatiin cia timeri
vbsaatu		rs.b	1		* 1: saatiin vb intti

prefs_task	rs.l	1		* prefs-prosessi

* Prefs window will close if it receives this signal
prefs_closeSignal	rs.b	1		* prefs-signaali

* Prefs window will update contents when receiving this
prefs_updateContentsSignal	rs.b	1		* prefs-signaali 2

songHasEndedSignal	rs.b	1	* Kappale soinut
ownsignal2	rs.b	1	* position update in title bar, prefs update 
uiRefreshSignal	rs.b	1	* lootan p‰ivitys
ownsignal4	rs.b	1	* Sulje ja avaa ikkuna
						* NOTE: this does not seem be used!
audioPortSignal	rs.b	1	* AudioIO:n signaali
fileReqSignal	rs.b	1	* Filereqprosessin signaali
rawKeySignal	rs.b	1	* rawkey inputhandlerilta
info_signal	rs.b	1	* about signaali infojen p‰ivitykseen
info_signal2	rs.b	1	* about signaali infojen p‰ivitykseen
tooltipSignal	rs.b  	1	* signal for opening tooltip popup

* Flag used to discard unnecessary mousemove IDCMP-messages
ignoreMouseMoveMessage 	rs.b  	1

oli_infoa	rs.b	1	* freemodulea ennen inforequn tila (0:eip‰‰ll‰)

info_task	rs.l	1	* infoikkunan taski

ciabasea	rs.l	1	* ciaa resource base
ciabaseb	rs.l	1	* ciab
ciabase		rs.l	1	* jompikumpi kumpi on k‰ytˆss‰
ciaddr		rs.l	1	* ...
timerhi		rs.b	1	* timerin arvo
timerlo		rs.b	1	* ...
whichtimer	rs.b	1	* Kumpi cia timeri
kelattiintaakse	rs.b	1	* <>0: kelattiin taakkepp‰in

mousex		rs	1		* hiiren paikka x,y
mousey		rs	1

******* Scope variables

taskQuadraScope		     rs.b TC_SIZE
taskQuadraScopeF	 rs.b TC_SIZE
taskHippoScope		     rs.b TC_SIZE
taskSpectrumScope	     rs.b TC_SIZE
taskPatternScope         rs.b  TC_SIZE

* Status for scope tasks:
RUNNING_NOT       = 0
RUNNING_YES       = 1
* Request scope shutdown
RUNNING_SHUT_IT   = $80
quadraScopeRunning	rs.b 1
quadraScopeFRunning 	rs.b 1
hippoScopeRunning	rs.b 1
patternScopeRunning     rs.b 1
spectrumScopeRunning    rs.b 1
scopeToggleTable        rs.b 5 * Used by toggleScopes()

* This turns to 1 if user has manually activated the scope
* by LMB click, when scope was passivated because not being
* visible. As this is global user does not need to do that again.
scopeManualActivation	rs.b 1	
__pad0     	        rs.b 1

scopeData  rs.b	 scope_size

 if DEBUG
;; Scope performance measurement data
scopeStartTimeSecs		rs.l	1
scopeStartTimeMicros	rs.l	1
scopeStopTimeSecs		rs.l	1
scopeStopTimeMicros		rs.l	1
scopeFrameCounter		rs.l	1
scopeRenderTime         rs.l    1
;; Timer.device stuff
timerOpen               rs.w    1
timerRequest	        rs.b    IOTV_SIZE
clockStart              rs.b    EV_SIZE
clockEnd                rs.b    EV_SIZE
 endif

ps3mchannels	rs.l	1	* Osoitin PS3M mixer channel blockeihin

**** Sampleplayerin datat

sampleforcerate		rs	1
sampleforcerate_new 	rs	1
sampleforceratepot_new	rs	1
samplebufsizpot_new	rs.l	1
samplebufsiz_new	rs.b	1
samplebufsiz0		rs.b	1
samplebufsiz		rs.l	1

* Sample playback rate, bytes per frame.
sampleadd		rs.l	1
* Pointer to a pointer to the sample position.
* This is reset to zero by sample player when a buffer
* is played through.
samplefollow		rs.l	1
* Sample pointer for mono samples, or the other stereo channel
samplepointer		rs.l	1
* Sample pointer to the other stereo channel
samplepointer2		rs.l	1
* Set to non-zero if sample being played is stereo
samplestereo		rs.b	1

* This is set in loadfile() to indicate a sample is found.
* Actual loading is then skipped.
sampleinit		rs.b	1		
* Sample format
* 1 = IFF
* 2 = AIFF
* 3 = WAV
* 4 = MP3
sampleformat		rs.b	1

* This is set in loadfile() to indicate an executable module has been 
* loaded with LoadSeg(). Value can be 0 for normal processing,
* or p_delicustom or p_futureplayer.
executablemoduleinit		rs.b	1

****** Prefs asetukset, joita k‰sitell‰‰n

mixingrate_new	rs.l	1		* Prefs-uudet arvot kaikille
ps3mb_new	rs.b	1
timeoutmode_new	rs.b	1
s3mmixpot_new	rs	1		* Propgadgettien arvot
tfmxmixpot_new	rs	1
volumeboostpot_new rs	1
stereofactorpot_new rs	1
tfmxmixingrate_new rs	1
lootamoodi_new	rs	1
timeout_new	rs	1
timeoutpot_new	rs	1
tempoflag_new	rs.b	1
playmode_new	rs.b	1
s3mmode1_new	rs.b	1
s3mmode2_new	rs.b	1
s3mmode3_new	rs.b	1
stereofactor_new rs.b	1
div_new		rs.b	1
Xquadmode_new	rs.b	1
moduledir_new	rs.b	150
prgdir_new	rs.b	150
arcdir_new	rs.b	150
ptmix_new	rs.b	1
xpkid_new	rs.b	1
fade_new	rs.b	1
pri_new		rs.b	1
ps3msettings_new rs.b	1
ps3msettings	rs.b	1

dclick_new	rs.b	1
centname_new	rs.b	1
startuponoff_new rs.b	1
newdir_new	rs.b	1
hotkey_new	rs.b	1
cerr_new	rs.b	1
dbf_new		rs.b	1
nasty_new	rs.b	1
pubscreen_new	rs.b	MAXPUBSCREENNAME+1 ; = 140
arclha_new	rs.b	100
arczip_new	rs.b	100
arclzx_new	rs.b	100
pattern_new	rs.b	70
startup_new	rs.b	120
fkeys_new	rs.b	120*10
pubwork		rs.l	1
xfd_new		rs.b	1
fontname_new	rs.b	20+1
listfontname_new rs.b 	20+1
early_new	rs.b	1
prefix_new	rs.b	1
autosort_new	rs.b	1
favorites_new	rs.b	1	
tooltips_new	rs.b 	1	
savestate_new	rs.b 	1
altbuttons_new  rs.b   1
quadraScope_new rs.b 1
quadraScopeBars_new rs.b 1
quadraScopeF_new rs.b 1
quadraScopeFBars_new rs.b 1
hippoScope_new rs.b 1
hippoScopeBars_new rs.b 1
patternScope_new rs.b 1
patternScopeXL_new rs.b 1
spectrumScope_new rs.b 1
spectrumScopeBars_new rs.b 1
	
samplecyber_new	rs.b	1
mpegaqua_new	rs.b	1
mpegadiv_new	rs.b	1
medmode_new	rs.b	1
medrate_new	rs	1
medratepot_new	rs	1

alarmpot_new	rs.l	1
alarm_new	rs	1
vbtimer_new	rs.b	1
Xscopechanged	rs.b	1		* scopea muutettu
contonerr_laskuri rs.b 1		* kuinka monta virheellist‰ lataus
cybercalibration_new rs.b 1		* yrityst‰
calibrationfile_new rs.b 100
newcalibrationfile rs.b	1

prefs_exit	rs.b	1		* Prefs exit-flaggi



slider4oldheight rs	1
slider1old	rs	1		* previous VertPot value to detect changes
slider4old	rs	1		* previous VertPot value to detect changes
mainvolume	rs	1		* p‰‰-‰‰nenvoimakkuus
mixirate	rs.l	1		* miksaustaajuus S3M:‰lle
textchecksum	rs	1
priority	rs.l	1		* ohjelman prioriteetti
tfmxmixingrate	rs	1		* rate 1-22
s3mmode1	rs.b	1		* prioriteetti / killeri
s3mmode2	rs.b	1	* surround,stereo,mono,real surround,14-bit
s3mmode3	rs.b	1		* Volume boost
stereofactor	rs.b	1		* stereofactor
xfd		rs.b	1		* ~0: k‰ytet‰‰n xfdmaster.libb°‰
ps3mb		rs.b	1

QUADMODE_QUADRASCOPE = 0
QUADMODE_HIPPOSCOPE = 1
QUADMODE_FREQANALYZER = 2
QUADMODE_PATTERNSCOPE = 3
QUADMODE_FQUADRASCOPE = 4
QUADMODE_PATTERNSCOPEXL = 5


* Store the original window height to switch between
* large and normal height mode
quadWindowHeightOriginal	rs.w	1

* Timeout mode: 0=all modules, $ff=only thos with no end-detection
timeoutmode	rs.b	1
filterstatus	rs.b	1		* filtterin 
modulefilterstate rs.b	1		* ..
ptmix		rs.b	1		* 0: normi ptreplay, 1:mixireplay
xpkid		rs.b	1		* 0: ei xpktunnistusta, 1:joo
							* seems to be that 0 enables xpkid here
fade		rs.b	1		* 0: ei feidausta
boxsize		rs	1		* montako nime‰ mahtuu fileboksiin
						* size of the module name box
* filebox slider value set in prefs, range: 2..48
boxsize_new	rs	1		
boxsizepot_new	rs	1
* This value represents the y-difference compared to
* a box of 8 lines height. Many places it is assumed that
* the box is 8 lines, afterwards resizing was added on top of it.
boxy		rs	1		* 8-nimisen lootaan y-kokomuutos
boxsize0	rs	1		* previous boxsize value to detect changes
boxsize00	rs	1		* magic flag that causes reopening the main window
boxsizez	rs	1		* rmb + ? zoomausta varten
						* alternative boxsize for RMB 
doubleclick	rs.b	1		* <>0: tiedoston doubleclick-play
tabularasa	rs.b	1		* aloitettiinko tyhjalla modilistalla?
startuponoff	rs.b	1		* <>0: startupsoitto p‰‰ll‰
hotkey		rs.b	1		* <>0: hotkeyt p‰‰ll‰
contonerr	rs.b	1		* <>0: jatketaan latauserrorin sattuessa
vbtimer		rs.b	1		* ~0: K‰ytet‰‰n vb ajastusta	
vbtimeruse	rs.b	1		* ~0: t‰m‰n hetkinen
groupmode_new	rs.b	1
groupname_new	rs.b	100
infosize_new	rs	1		* module infon koko
infosize	rs	1
infosizepot_new	rs	1

prefixcut	rs.b	1
earlyload	rs.b	1
divdir		rs.b	1
cybercalibration rs.b	1

* Playtime in seconds when module should be stopped automatically,
* zero if not enabled
timeout		rs	1		* moduulin soittoaika

alarm		rs	1		* alarm aika
do_alarm	rs.b	1		* ~0: her‰tys! :)

new		rs.b	1		* onko painettu New:i‰?
new2		rs.b	1		* onko painettu New:i‰?

gfxcard		rs.b 	1		* jos ~0, k‰ytˆss‰ n‰yttˆkortti

samplecyber	rs.b	1		* ~0: sampleplayer k‰ytt‰‰ cybercalibr.
mpegaqua	rs.b	1		* MPEGA quality
mpegadiv	rs.b	1		* MPEGA freq. division
medmode		rs.b	1		* MED mode
medrate		rs	1		* MED mixing rate


*******

sortbuf		rs.l	1		* sorttaukseen puskuri

TITLEBAR_TIME_POSLEN_SONG 		= 0
TITLEBAR_CLOCK_FREEMEM			= 1
TITLEBAR_NAME					= 2
TITLEBAR_TIMEDUR_POSLEN			= 3
lootamoodi	rs	1		* lootan moodi, titlebar mode

lootassa	rs	1		* viimeisin tieto lootassa
colordiv	rs.l	1		* colorclock/vbtaajuus
vertfreq	rs	1		* virkistystaajuudet
horizfreq	rs	1

clockconstant	rs.l	1		* Clock Constant PAL/NTSC

pos_nykyinen	rs	1		* moduulin position
pos_maksimi	rs	1		
positionmuutos	rs	1

datestamp1	rs.l	3		 * ajanottoa varten
datestamp2	rs.l	3
aika1		rs.l	1
aika2		rs.l	1
vanhaaika	rs	1
ticktack	rs	1	* vb tick count for titlebar refresh
tooltipTick	rs 	1	* vb tick count for tooltips, counts from positive to 0
userIdleTick rs  1	* refresh counter updated each ui refresh tick, cleared on mouse
kokonaisaika	rs	2	* pt-moduille laskettu kesto aika, min/sec
				* tai sampleille

modamount		rs.l	1	* modien m‰‰r‰
divideramount	rs.l	1	* dividereitten m‰‰r‰ (info window)
firstname		rs.l	1	* nimi ikkunan ekan nimen numero
firstname2		rs.l	1	* 

* List node represeneting an index
* Should be zeroed if list structure
* changes above the node.
cachedNodeIndex	rs.l	1
cachedNode	rs.l	1	

markedline	rs.l	1	* merkitty rivi
				* Highlighted line inside the box, range is from 0
				* to current boxsize

playingmodule	rs.l	1	* index of the module that is being played
chosenmodule	rs.l	1	* index of the chosen module in the list

GROUPMODE_ALL_ON_STARTUP = 0
GROUPMODE_ALL_ON_DEMAND = 1
GROUPMODE_DISABLE = 2
GROUPMODE_LOAD_SINGLE = 3
groupmode	rs.b	1	* player group handling mode

movenode	rs.b	1	* ~0: move p‰‰ll‰
nodetomove	rs.l	1	* t‰t‰ nodea siirret‰‰n

chosenmodule2	rs.l	1	* TODO: what is this
hippoonbox	rs.b	1	* ~0: shownames p‰ivitt‰‰ koko n‰ytˆn
dontmark	rs.b	1	* ei merkata nime‰ listassa

clickmodule	rs.l	1	* doubleklikattumodule
clicksecs	rs.l	1	* aika CurrentTime()lt‰ DoubleClick()ille
clickmicros	rs.l	1

playerbase	rs.l	1	* soittorutiinin base
playertype	rs	1	* pt_????

tempoflag	rs.b	1	* 0: tempo sallittu, ei-0: tempo ei sallitu
songover	rs.b	1	* kappale soinut loppuun
uusikick	rs.b	1	* ~0 jos kickstart 2.0+
win		rs.b 	1	* ~0: ikkuna auki, 0: EI IKKUNAA, hide!

* Contains gadget address which was selected with RMB, or null if none.
rightButtonSelectedGadget 	rs.l 	1	
* Routine to run after RMB is raised, while still on top of said gadget
rightButtonSelectedGadgetRoutine	rs.l	1
* Tooltip that has been activated and will be shown
activeTooltip				rs.l	1	
* Gadget for which tooltips shall be disabled.
* This is set when a gadget has been pressed by the user
* so that tooltip is not unnecessarily shown.
disableTooltipForGadget  	rs.l 	1
* Tooltip intuition window, if open	
tooltipPopupWindow			rs.l 	1

playing		rs.b	1	* 0: ei soiteta, ei-0: soitetaan
playmode	rs.b	1	* kuinka soitetaan listaa
filterstore	rs.b	1	* filtterin tila

keyfilechecked	rs.b	1	* ~0: keyfile tarkistettu

songnumber	rs	1	* modin sis‰isen kappaleen numero
maxsongs	rs	1	* maximi songnumber
minsong  	rs 	1   * min songnumber


moduleaddress	rs.l	1	* modin osoite
moduleaddress2	rs.l	1	* modin osoite ladattaessa doublebufferingilla
modulelength	rs.l	1	* modin pituus
modulefilename	rs.l	1	* modin tiedoston nimi
solename	rs.l	1	* osoitin pelkk‰‰n tied.nimeen
kanavatvarattu	rs	1	* 0: ei varattu, ei-0: varattu

;earlymoduleaddress	rs.l	1	*
;earlymodulelength	rs.l	1	*
;earlytfmxsamples	rs.l	1
;earlytfmxsamlen		rs.l	1
;earlylod_tfmx		rs.b	1
;do_early		rs.b	1



oldst		rs.b	1	* 0: pt modi, ~0: old soundtracker modi
sidflag		rs.b	1	* songnumberin muuttamiseen
* Set to true if the last loaded module is a remote module.
* Path is in "modulefilename" as usual.
uriDecodeNameBeforeShowing	rs.b	1

kelausnappi	rs.b	1	* 0: jos ei cia kelausta
kelausvauhti	rs.b	1	* 1: 2x, 2: 4x
do_early	rs.b	1


externalplayers	rs.l	1	* ulkoisen soittorutiininivaskan osoite

external	rs.b	1	* lippu: tarvitaan xplayeri
			rs.b 	1	* pad
xtype		rs.w	1	* ladatun replayerin tyyppi
xplayer		rs.l	1	* osote
xlen		rs.l	1	* pakattupituus

ps3msettingsfile rs.l	1	* ps3m settings filen osoite
calibrationaddr	 rs.l	1	* CyberSound 14-bit calibration table

sampleroutines	rs.l	0
aonroutines	rs.l	0
thxroutines	rs.l	0
digiboosterroutines rs.l 0
digiboosterproroutines rs.l 0
hippelcosoroutines rs.l	0
ps3mroutines	rs.l	0
oktaroutines	rs.l	0
bpsmroutines	rs.l	0
fc14routines	rs.l	0
fc10routines	rs.l	0
jamroutines	rs.l	0
p60routines	rs.l	0
pumatrackerroutines 	rs.l 0
gamemusiccreatorroutines rs.l 0
digitalmugicianroutines	rs.l 0
medleyroutines rs.l 0
futureplayerroutines rs.l 0
daveloweroutines	rs.l 	0
bendaglishroutines	rs.l	0
sidmon2routines 	rs.l 	0
deltamusic1routines rs.l 	0
soundfxroutines	rs.l	0
gluemonroutines	rs.l	0
pretrackerroutines rs.l	0
custommaderoutines rs.l 0
startrekkerroutines rs.l 0
voodooroutines	rs.l	0
sonicroutines	rs.l	0
tfmxroutines	rs.l	0
tfmx7routines	rs.l	1	* Soittorutiini purettuna (TFMX 7ch)
player60samples	rs.l	1	* P60A:n samplejen osoite
startrekkerdataaddr rs.l 0
tfmxsamplesaddr	rs.l	1	* TFMX:n samplejen osoite
startrekkerdatalen rs.l 0
tfmxsampleslen	rs.l	1	* TFMX:n samplejen pituus
medrelocced	rs.b	1	* ei-0: Med-modi relocatoitu
medtype		rs.b	1	* 0: 1-4, 1: 5-8, 2: 1-64

ps3m_mname	rs.l	1	* ps3m:n informaation v‰lityst‰ varten
ps3m_numchans	rs.l	1
ps3m_mtype	rs.l	1
ps3m_samples	rs.l	1
ps3m_xm_insts	rs.l	1
ps3m_buff1	rs.l	1
ps3m_buff2	rs.l	1
ps3m_mixingperiod rs.l	1
ps3m_playpos	rs.l	1
ps3m_buffSizeMask rs.l	1
ps3mUnpackedPattern rs.l 1

ahi_use_new		rs.b	1
ahi_muutpois_new	rs.b	1
ahi_rate_new		rs.l	1
ahi_ratepot_new		rs	1
ahi_mastervol_new	rs	1
ahi_mastervolpot_new	rs	1
ahi_mode_new		rs.l	1
ahi_stereolev_new	rs	1
ahi_stereolevpot_new	rs	1
ahi_name_new		rs.b	44


* file list header, Minimal List Header
moduleListHeader	rs.b	MLH_SIZE	* tiedostolistan headeri
filelistaddr	rs.l	1		* REQToolsin tiedostolistan osoite

loading		rs.b	1		* ~0: lataus meneill‰‰n
loading2	rs.b	1		* ~0: filejen addaus meneill‰‰n
* List of favorite modules
favoriteListHeader	rs.b 	MLH_SIZE
* Flag indicates the list has changed before last save
favoriteListChanged	rs.b	1
			rs.b	1	* pad

* List for file browser
fileBrowserListHeader	rs.b	MLH_SIZE


** InfoWindow kamaa
;infosample	rs.l	1		* samplesoittajan v‰liaikaisalue
swindowbase	rs.l	1
suserport	rs.l	1
srastport	rs.l	1
ssliderold	rs.l	1
sfirstname	rs	1
sfirstname2	rs	1
riviamount	rs	1
oldswinsiz	rs	1
oldsgadsiz	rs	1
skokonaan	rs.b	1
		rs.b	1

******* LoadDatan muuttujia
lod_a			rs.b	0
lod_address		rs.l	1
lod_length		rs.l	1
lod_filename		rs.l	1
lod_memtype		rs.l	1
lod_start		rs.l	1
lod_len			rs.l	1
lod_filehandle		rs.l	1
lod_error		rs	1
lod_xpkerror		rs	1
lod_xfderror		rs	1
lod_archive		rs.b	1	 * 0: ei archive, <>0: archive
lod_tfmx		rs.b	1
lod_pad			rs.b	1
lod_kommentti		rs.b	1	 * 0: ei oteta kommenttia
lod_xpkfile		rs.b	1	 * <>0: tiedosto oli xpk-pakattu
lod_exefile		rs.b	1	 * <>0: file was an exe		
lod_dirlock		rs.l	1
lod_buf			rs.b	200
lod_b			rs.b	0

newdirectory	rs.b	1
newdirectory2	rs.b	1

prefsdata	rs.b	prefs_size	* Prefs-tiedosto
startup		= prefsdata+prefs_startup
fkeys		= prefsdata+prefs_fkeys
groupname	= prefsdata+prefs_groupname

ahi_rate	= prefsdata+prefs_ahi_rate
ahi_mastervol	= prefsdata+prefs_ahi_mastervol
ahi_stereolev	= prefsdata+prefs_ahi_stereolev
ahi_mode	= prefsdata+prefs_ahi_mode
ahi_name	= prefsdata+prefs_ahi_name
ahi_use		= prefsdata+prefs_ahi_use
ahi_muutpois	= prefsdata+prefs_ahi_muutpois
ahi_use_nyt	rs.b	1
favorites	rs.b	1
tooltips	rs.b  	1
savestate	rs.b    1
altbuttons  rs.b    1
altbuttonsUse  rs.b    1
autosort	= prefsdata+prefs_autosort

* Runtime scope settings
quadraScope   rs.b 1
quadraScopeBars   rs.b 1
quadraScopeF   rs.b 1
quadraScopeFBars   rs.b 1
hippoScope   rs.b 1
hippoScopeBars   rs.b 1
patternScope   rs.b 1
patternScopeXL   rs.b 1
spectrumScope   rs.b 1
spectrumScopeBars   rs.b 1
 
* audio homman muuttujat
acou_deviceerr	rs.l	1
iorequest	rs.b	ioa_SIZEOF
audioport	rs.b	MP_SIZE

* input devicen muuttujat
idopen		rs.l	1
iorequest2	rs.b	IO_SIZE
idmsgport	rs.b	MP_SIZE
intstr		rs.b	IS_SIZE
rawkeyinput	rs	1		* rawkoodi

******* Viestiportti
omaviesti0	rs.l	1		* Porttiin saapunut viesti

hippoport	rs.b	HippoPort_SIZEOF

poptofrontr	rs.l	1		* rutiini esiinpullauttamiseksi
newcommand	rs.l	1		* osoitin uuteen komentoon
*******

********* ARexx
rexxport	rs.b	MP_SIZE
rexxmsg		rs.l	1
rexxon		rs.b	1		* ~0: ARexx aktivoitu!
keycheck	rs.b	1		* keyfile checkki. 0=oikea keyfile
rexxresult	rs.l	1		* argstringi

********

wintitl		rs.b	80
wintitl2	rs.b	80

tfmx_L0000DC	rs.l	1		* TFMX:n dataa
tfmx_L0000E0	rs.l	1
tfmx_L0000E4	rs.l	1
tfmx_L0000E8	rs.l	1
tfmx_L0000EC	rs.l	1
sidheader	rs.b	sidh_sizeof

 
moduledir	= prefsdata+prefs_moddir * modulehakemisto
prgdir		= prefsdata+prefs_prgdir * prghakemisto
arcdir		= prefsdata+prefs_arcdir
arclha		= prefsdata+prefs_arclha * pakkerit
arczip		= prefsdata+prefs_arczip
arclzx		= prefsdata+prefs_arclzx
pattern		= prefsdata+prefs_pattern
pubscreen	= prefsdata+prefs_pubscreen
nastyaudio	= prefsdata+prefs_nasty
doublebuf	= prefsdata+prefs_dbf
calibrationfile = prefsdata+prefs_calibrationfile

tokenizedpattern	rs.b	70*2+2

newpubscreen	rs.b	1
newpubscreen2	rs.b	1


deleteflag	rs.b	1	* filen ja dividerin deletointiin

* teksti: "Registered to "
	
;regtext		rs.b	14-1
;	rs.b	1
keycode		rs.b	1		* 33
keyfile		rs.b	64		* keyfile!

INFO_MODULE_NAME_LEN = 50+10
modulename	rs.b 	INFO_MODULE_NAME_LEN+2 * moduulin nimi
moduletype	rs.b	40		* tyyppi tekstin‰
req_array	rs.b	0		* reqtoolsin muotoiluparametrit
desbuf		rs.b	200		* muotoilupuskuri, temporary buffer
desbuf2		rs.b	200		* muotoilupuskuri prefssille
filename	rs.b	108		* tiedoston nimi (reqtools)
filename2	rs.b	108		* Load/Save program-rutiineille
tempdir		rs.b	200		* ReqToolsin hakemistopolku 
PROBE_BUFFER_LEN = 2048
probebuffer	rs.b	PROBE_BUFFER_LEN * tiedoston tutkimispuskuri
ptsonglist	rs.b	64		* Protrackerin songlisti
xpkerror	rs.b	82		* XPK:n virhe (max. 80 merkki‰)
findpattern	rs.b	30		* find pattern
divider		rs.b	26		* divider

omabitmap	rs.b	bm_SIZEOF-7*4	* 1 bitplanea, ei tilaa muille
bitmapHippoHead	rs.b	bm_SIZEOF-6*4	* 2
omabitmap3	rs.b	bm_SIZEOF-7*4	* 1
omabitmap4	rs.b	bm_SIZEOF-6*4	* 2
omabitmap5	rs.b	bm_SIZEOF-6*4	* 2

							* Semaphore to protect access to the data of the module
							* being played.
moduleDataSemaphore		rs.b	SS_SIZE
							* Semaphore to protect access to the module list
moduleListSemaphore 	rs.b 	SS_SIZE

ARGVSLOTS	=	16		* max. parametrej‰
sv_argvArray	rs.l	ARGVSLOTS	* pointers to zero terminated strings
sv_argvBuffer	rs.b	256			* strings are here

randomValueMask  	rs.l		1 * mask to quickly cull too big random numbers based on modamount
randomtable		rs.l		1 * pointer to random table, allocated when needed

* Indicates which mode the list is in, either normal list 
* or favorites, or file browser
LISTMODE_NORMAL		= 0
LISTMODE_FAVORITES 	= 1
LISTMODE_BROWSER	= 2
listMode		rs.b	1

* This is set each time list has been edited by user in some way.
moduleListChanged	rs.b		1

kplbase	rs.b	k_sizeof		* KPlayerin muuttujat (ProTracker)

*** Deli support data
deliData	rs.l    1
* Dynamically allocated:
deliBase	rs.l 	1
* LoadSeg() data 
deliPlayer	rs.l	1
* Type of player which was loaded
deliPlayerType	rs.w	1
* Load file array pointer, contains (addr,len) pairs
* Data loaded with dtg_LoadFile
deliLoadFileArray	rs.l 1
deliLoadFileIoErr	rs.l 1
* Some tag data for faster access
deliStoredInterrupt	rs.l	1
deliStoredSetVolume	rs.l 	1
deliStoredSetVoices rs.l	1
deliStoredNoteStruct rs.l 	1
deliStoredGetPositionNr rs.l 1
deliPath		rs.l	1
deliPathArray		rs.l	1
* Pattern info data returned by EP	
deliPatternInfo		rs.l 	1
* UPS_USER struct info returned by EP
deliUPSStruct			rs.l 	1

* Path read from auto saved modulelist comment,
* which is the last path used to add files to list
lastStoredFileReqDirectory	rs.l 	1

* Stores the selection indexes so that returning to
* parent can select the correct item.
FILEBROWSER_HISTORY_SIZE = 16
fileBrowserSelectionHistoryIndex rs.w 1
fileBrowserSelectionHistory		 rs.l FILEBROWSER_HISTORY_SIZE
* Lock for currently active dir, so that it can 
* be saved to state if needed.
fileBrowserCurrentDirLock		rs.l	1

* Region used to create a clip region for the list box
listBoxRegion		rs.l	1
* Layers library clip region to keep list box text drawing inside,
* useful for variable sized fonts.	
listBoxClipRegion	rs.l	1

* String extend structure to configure custom font to string gadgets on kick2.0+
stringExtendStruct 	rs.b	sex_SIZEOF

* Popup list selector memory remember pointer
listSelectorRememberPtr		rs.l	1

* UHC aminet mirror path, if this is NULL, there's no UHC
* installed. Should be freed on exit.
 ifne FEATURE_UHC_AMINET
uhcAminetMirrorPath			rs.l	1
 endif
uhcAvailable				rs.b	1	
							rs.b	1

 if DEBUG
debugDesBuf		rs.b	1000
 endif

* Size of global variables data. Must be even.
size_var	rs.b	0

	ifne	size_var&1
	fail
	endc


*********************************************************************************
*
* Playerbasen rakenne
*
	rsreset
p_init		rs.l	1
p_ciaroutine	rs.l	0
p_play		rs.l	1
p_vblankroutine	rs.l	1
p_end		rs.l	1
p_stop		rs.l	1
p_cont		rs.l	1
p_volume	rs.l	1
p_song		rs.l	1
p_eteen		rs.l	1
p_taakse	rs.l	1
p_ahiupdate	rs.l	1
p_id  		rs.l 	1
p_author	rs.l 	1
p_type 		rs.w    1
p_liput		rs	1	* ominaisuudet
p_name		rs.l	1

p_NOP macro 
	dc.l	$4e754e75
	endm

 if pt_prot<>33 
   fail This must be 33
 endc 
 if pt_multi<>49
   fail This must be 49
 endc 

* player group version
xpl_versio	=	25


*********************************************************************************
*
* Tiedostolistan yhden yksikˆn rakenne
* Mudule list node element
*

	rsreset
		rs.b	MLN_SIZE	* Minimal node 
l_nameaddr	rs.l	1		* osoitin pelkk‰‰n tied.nimeen
					* address to filename without path
l_favorite	rs.b 	1		* favorite status for this file
l_divider	rs.b	1		* this is a divider, ie. a path
l_remote	rs.b    1       * 0: local file, 1: remote
l_filename	rs.b	0		* tied.nimi ja polku alkaa t‰st‰
					* full path to filename begins at this point
					* element size is dynamically calculated based on path length.
l_size		rs.b	0


*********************************************************************************
*
* Soittomoodit
*

* Repeat list 
pm_repeat	=	1
* Play list once
pm_through	=	2
* Repeat module
pm_repeatmodule	=	3
* Play module once
pm_module	=	4
* Random play 
pm_random	=	5
pm_max		=	5


*********************************************************************************
*
* Soittorutiinin ominaisuusliput
*

pb_cont		=	0
pb_stop		=	1
pb_song		=	2
pb_kelauseteen	=	3
pb_kelaustaakse =	4
pb_volume	=	5
pb_ciakelaus	=	6		* 2x = lmb, 4x = rmb
pb_ciakelaus2	=	7		* pattern = lmb, 2x = rmb
pb_end		=	14
pb_poslen	=	15
pb_scope	=	13	; Replayer supports patternscope or quadscope
pb_ahi		=	12
pb_quadscopePoke =      11      ; Normal quadscope or EP poke interface
pb_quadscopeUps	=  	10	; EP UPS interface
pf_cont		=	1<<pb_cont
pf_stop		=	1<<pb_stop
pf_song		=	1<<pb_song
pf_kelauseteen	=	1<<pb_kelauseteen
pf_kelaustaakse	=	1<<pb_kelaustaakse
pf_kelaus	=	pf_kelauseteen!pf_kelaustaakse
pf_volume	=	1<<pb_volume
pf_ciakelaus	=	1<<pb_ciakelaus!1<<pb_kelauseteen
pf_ciakelaus2	=	1<<pb_ciakelaus2!1<<pb_kelauseteen
pf_end		=	1<<pb_end
pf_poslen	=	1<<pb_poslen
pf_scope	=	1<<pb_scope
pf_ahi		=	1<<pb_ahi
pf_quadscopeUps	=	1<<pb_quadscopeUps
pf_quadscopePoke =	1<<pb_quadscopePoke


*********************************************************************************
*
* PS3M:n moodit
*

sm_surround	=	1
sm_stereo	=	2
sm_mono		=	3
sm_real		=	4
sm_stereo14	=	5


*********************************************************************************
*
* P‰‰- ja prefsikkunan liput
*

wflags set WFLG_ACTIVATE!WFLG_DRAGBAR!WFLG_CLOSEGADGET!WFLG_DEPTHGADGET
wflags set wflags!WFLG_SMART_REFRESH!WFLG_RMBTRAP!WFLG_REPORTMOUSE
idcmpflags set IDCMP_GADGETUP!IDCMP_MOUSEBUTTONS!IDCMP_CLOSEWINDOW
idcmpflags set idcmpflags!IDCMP_MOUSEMOVE!IDCMP_RAWKEY
idcmpflags set idcmpflags!IDCMP_ACTIVEWINDOW!IDCMP_INACTIVEWINDOW
idcmpflags set idcmpflags!IDCMP_NEWSIZE


wflags2	set WFLG_ACTIVATE!WFLG_DRAGBAR!WFLG_CLOSEGADGET!WFLG_DEPTHGADGET
wflags2 set wflags2!WFLG_SMART_REFRESH!WFLG_RMBTRAP
idcmpflags2 set IDCMP_GADGETUP!IDCMP_CLOSEWINDOW!IDCMP_MOUSEMOVE
idcmpflags2 set idcmpflags2!IDCMP_MOUSEBUTTONS!IDCMP_RAWKEY

*********************************************************************************
*
* Debug macros
*

* Print to debug console
DEBU	macro
	ifne	DEBUG
	pea	\1
	jsr	PRINTOUT
	endc
	endm

* Print to debug console, very clever.
* Param 1: string
* d0-d6:    formatting parameters, d7 is reserved
DPRINT macro
	ifne DEBUG
	jsr	desmsgDebugAndPrint
  dc.b 	\1,10,0
  even
	endc
	endm

* No auto line feed
DPRINT2 macro
	ifne DEBUG
	pea	.LDD\2(pc)
	jsr	PRINTOUT
	bra.b	.LD\2
.LDD\2
 	dc.b 	\1,0
 	even
.LD\2
	endc
	endm

* delay
DDELAY macro
	ifne DEBUG
	pushm	all
	move.l	#\1*50,d1
	lore	Dos,Delay
	popm	all
	endc
	endm


; Macro to check the gadget GFLG_DISABLED flag
; GLFG_DISABLED = $0100
skipIfGadgetDisabled macro
	btst	#0,gg_Flags+\1
	beq.b	*+4
	rts
	endm

*********************************************************************************
*
* Start up from CLI or Workbench
* - Handles command line parameters,
* - setting up a new process (detachment),
* - Workbench message,
* - Passing parameters to already existing hippo instance.
* - Can't be used when running from AsmOne.
*

 ifeq asm

	section	detach,code_p

progstart
	lea	var_b,a5
	move.l	a0,d6
	move.l	d0,d7

	move.l	4.w,a6
	move.l	a6,(a5)
	lea	dosname,a1
	lob	OldOpenLibrary
	move.l	d0,a4
	move.l	d0,_DosBase(a5)

	sub.l	a1,a1
	lob	FindTask
	move.l	d0,a3

	moveq	#0,d5
	tst.l	pr_CLI(a3)	* ajettiinko WB:st‰
	bne.b	.nowb
	lea	pr_MsgPort(a3),a0
	lob	WaitPort
	lea	pr_MsgPort(a3),a0
	lob	GetMsg
	move.l	d0,d5
	move.l	d0,a0
	move.l  sm_NumArgs(a0),d4
	* Get WBArg array:
	move.l	sm_ArgList(a0),d0	* nykyisen hakemiston lukko
	beq.b	.waswb			* workbenchilt‰
	move.l	d0,a1
	move.l	wa_Lock(a1),lockhere(a5)
	DPRINT	"Start from WB"
	bsr.w	.buildWbStartParams
	bra.b	.waswb
.nowb	
	move.l	pr_CurrentDir(a3),lockhere(a5) * nykyinen hakemisto CLI:lt‰
	DPRINT	"Start from CLI"

	push	a3
	bsr.w	CLIparms
	pop	a3
.waswb	


	* a3 = current task

	bsr.w	.getDirInfo
	lea	portname,a1		* joko oli yksi HiP??
	lore	Exec,FindPort
	tst.l	d0
	bne.w	.poptofront

	* There was no hip already running, launch a new one

	move.l	a4,a6			* hankitaan kopio lukosta
	move.l	lockhere(a5),d1
	lob	DupLock
	move.l	d0,lockhere(a5)

	move.l	#procname,d1
	moveq	#0,d2			* prioriteetti
	lea	progstart-4(pc),a0
	move.l	(a0),d3
	move.l	d3,segment(a5)		* seuraavan hunkin pointteri
	clr.l	(a0)
;	move.l	#4000,d4		* stacksize
	move.l	#5000,d4		* stacksize
	move.l	a4,a6
	lob	CreateProc	

.eien	

	* if new HiP was NOT launched close the debug window
 if DEBUG
	tst.l	segment(a5)
	bne.b	.launched
	move.l	output(a5),d1
	beq.b	.out
	move.l	_DosBase(a5),a6
	move.l	#3*50,d1
	lob	Delay
	move.l	output(a5),d1
	beq.b	.out
	lob 	Close
.out
 endif

.launched

	move.l	(a5),a6			* vastataan WB:n viestiin
	tst.l	d5
	beq.b	.nomsg
	lob	Forbid
	move.l	d5,a1
	lob	ReplyMsg
.nomsg
	moveq	#0,d0
	rts

* Get parameters received by launching with project icons
* where the tool is defined to be HiP. Multiple projects
* can be opened simultaneously.
*
* This builds the command line argument array based
* on WBArgs. The CLI arg processing will then handle
* these as if they were entered from CLI.
*
* In:
*   d4 = WBArg parameter count
*   a1 = WBArg array
.buildWbStartParams
	pushm	all

 if DEBUG
 	move.l	d4,d0
 	DPRINT	"sm_NumArgs=%ld"
 endif

	* Pointers to strings
	lea	sv_argvArray(a5),a2
	* Strings
	lea	sv_argvBuffer(a5),a4
	* Temporary buffer:
	lea	ptheader,a3
.wbArgLoop
	* Null term it for safety
	clr.b	(a3)
	move.l	wa_Name(a1),d0
	move.l	wa_Lock(a1),d1
 if DEBUG
	DPRINT	"wa_Name=%s wa_Lock=%lx"
	tst.l	d1
 endif
	beq.b	.nullLock
	move.l	a3,d2
	move.l	#200,d3
	jsr	getNameFromLock
	tst.l	d0
	* Skip if errors
	beq.b	.stop
.nullLock
	* Store string ptr
	move.l	a4,(a2)+
	* Copy path based on lock
	move.l	a3,a0
	tst.b	(a0)
	beq.b	.emptyPath
.copyPath1
	move.b	(a0)+,(a4)+
	bne.b	.copyPath1
	subq	#1,a4
	cmp.b	#':',-1(a4)
	beq.b	.noSep
	move.b	#'/',(a4)+
.emptyPath
.noSep
	* Copy filename
	move.l	wa_Name(a1),a0
.copyName1
	move.b	(a0)+,(a4)+
	bne.b	.copyName1

 if DEBUG
	move.l	-4(a2),d0
	DPRINT	"-->%s"
 endif
	addq	#wa_SIZEOF,a1
	subq	#1,d4
	bne.b	.wbArgLoop
.stop
	popm	all
	rts

* in:
*  a3 = current task
*  a6 = exec
.getDirInfo 
	cmp	#36,LIB_VERSION(a6)
	blo.b	.noo	
	move.l 	pr_HomeDir(a3),d1
	beq.b	.noo
	lore	Dos,DupLock
	move.l	d0,homelock(a5)
.noo

 if DEBUG
	move.l 	lockhere(a5),d1
	move.l	#ptheader,d2
	moveq	#100,d3 
	jsr	getNameFromLock
	move.l	#ptheader,d0
	DPRINT	"Current dir: %s"
	move.l 	homelock(a5),d1
	beq.b	.ooold
	move.l	#ptheader,d2
	moveq	#100,d3 
	jsr	getNameFromLock
	move.l	#ptheader,d0
	DPRINT	"Home dir: %s"
.ooold
 endif 
	rts

.poptofront
	tst.l	sv_argvArray+4(a5)	* oliko parametrej‰?
	bne.b	.huh			* jos ei, pullautetaan hip!

	move.l	d0,a0
	move.l	poptofrontr-hippoport(a0),a0	* pullautusrutiini
	jsr	(a0)								* what is this evil magic?
	bra.w	.eien

* Oli! L‰hetet‰‰n hipille!
.huh
	* Let us send a message to an already existing hippo with command line marguments passed
	* here.

	move.l	d0,a3			* p‰‰ll‰olevan hipin portti

	sub.l	a1,a1
	lore	Exec,FindTask
	move.l	d0,owntask(a5)

	jsr	createport0		* luodaan oma portti!

	* Use this buffer to construct a Message structure
	lea	desbuf(a5),a0		* portti desbufiin
	NEWLIST	a0

	move.l	a3,a0			* kohdeportti
	lea	desbuf(a5),a1		* viesti

	;pushpea	sv_argvArray(a5),MN_LENGTH(a1) * uudet parametrit viestiin
	;move.l	#"K-P!",MN_LENGTH+4(a1) * tunnistin!

	bsr.b	.preparePaths

 if DEBUG
	push	a0
	lea	sv_argvArray(a5),a0
	moveq	#0,d0
.bob
	tst.l	(a0)
	beq.b	.bob2
	move.l	(a0)+,d1
	DPRINT	"%ld: %s"
	addq	#1,d0
	bra.b	.bob
.bob2
	pop 	a0
 endif

	move.l	#MESSAGE_MAGIC_ID,HM_Identifier(a1) 			* magic identifier
	pushpea	sv_argvArray(a5),HM_Arguments(a1) 		  * cmdline parameter array
	* MN_SIZE is left unset
	pushpea	hippoport(a5),MN_REPLYPORT(a1)	* t‰h‰n porttiin vastaus
	lob	PutMsg

	lea	hippoport(a5),a0	* odotellaan vastausta
	lob	WaitPort

	jsr	deleteport0

	bra.w	.eien

* This checks the command line parameters and adds a fully qualified path 
* to filenames if possible. Uses V36 DOS functions as it would be quite
* painful, yet still doable, otherwise.
.preparePaths
	pushm	all
	;move.l	(a5),a0
	;cmp	#34,LIB_VERSION(a0)	
	;ble.b	.done			* Kickstart 1.3 or earlier? GETOUTTAHERE
	
	* Grab the prepared arguments array
	lea	sv_argvArray(a5),a3
	* Construct any new path strings here, plenty of space
	lea	probebuffer(a5),a4
.loop
	* Take one and see if it was the last one
	move.l	(a3),d3
	beq.b	.done

	* See if it was one of the four letter commands
	move.l	d3,a0 
	jsr		kirjainta4
* skip commands
	cmp.l	#MESSAGE_COMMAND_HIDE,d0
	beq.b	.wasCommand 
	cmp.l	#MESSAGE_COMMAND_QUIT,d0
	beq.b	.wasCommand 
	cmp.l	#MESSAGE_COMMAND_PRG,d0
	beq.b	.wasCommand 

* consider this a file. let's try to get a lock on it.
	move.l 	d3,d1
	moveq	#ACCESS_READ,d2
	lore  	Dos,Lock
	move.l	d0,d4
	beq.b	.noLock

	* DOS will now provide us with a full path from the lock, conveniently.
	move.l	d4,d1
 	pushpea tempdir(a5),d2  		* this space can be used
 	move.l	#200,d3 
 	jsr	getNameFromLock
	* store return status for a little while so we can UnLock first
	move.l	d0,d3

	move.l	d4,d1
	lob    	UnLock

 	* If something went wrong, skip
 	tst.l	d3
 	beq.b	.error

	* Copy the path to the destination buffer
 	lea	tempdir(a5),a0 
 	move.l	a4,a1
.copy
 	move.b	(a0)+,(a1)+
 	bne.b	.copy
 	* Overwrite arg slot with the new fully qualified path + filename entry
 	move.l	a4,(a3)
 	* Temp buffer position to hold the next possible path+filename
 	move.l	a1,a4

.wasCommand
.noLock
.error
	* go to next argv slot
	addq.l	#4,a3
	bra.b	.loop
.done 
	popm	all
	rts

CLIparms
;=======================================================================
;====== CLI Startup Code ===============================================
;=======================================================================
;       d0  process CLI BPTR (passed in), then temporary
;       d2  dos command length (passed in)
;       d3  argument count
;       a0  temporary
;       a1  argv buffer
;       a2  dos command buffer (passed in)
;       a3  argv array
*       a4  Task (passed in)
*       a5  SVar structure if not QARG (passed in)
*       a6  AbsExecBase (passed in)
*       sp  WBenchMsg (still 0), sVar or 0, then RetAddr (passed in)
*       sp  argc, argv, WBenchMsg, sVar or 0,RetAddr (at bra domain)

	move.l	172(a3),d0			* pr_CLI
	move.l	d7,d2
	move.l	d6,a2

        ;------ find command name
                lsl.l   #2,d0           ; pr_CLI bcpl pointer conversion
                move.l  d0,a0
                move.l  cli_CommandName(a0),d0
                lsl.l   #2,d0           ; bcpl pointer conversion

                ;-- start argv array
                lea     sv_argvBuffer(a5),a1
                lea     sv_argvArray(a5),a3

                ;-- copy command name
                move.l  d0,a0
                moveq.l #0,d0
                move.b  (a0)+,d0        ; size of command name
                clr.b   0(a0,d0.l)      ; terminate the command name
                move.l  a0,(a3)+
                moveq   #1,d3           ; start counting arguments

        ;------ null terminate the arguments, eat trailing control characters
                lea     0(a2,d2.l),a0
stripjunk:
                cmp.b   #' ',-(a0)
                dbhi    d2,stripjunk

                clr.b   1(a0)

        ;------ start gathering arguments into buffer
newarg:
                ;-- skip spaces
                move.b  (a2)+,d1
                beq.s   parmExit
                cmp.b   #' ',d1
                beq.s   newarg
                cmp.b   #9,d1           ; tab
                beq.s   newarg

                ;-- check for argument count verflow
                cmp.w   #ARGVSLOTS-1,d3
                beq.s   parmExit

                ;-- push address of the next parameter
                move.l  a1,(a3)+
                addq.w  #1,d3

                ;-- process quotes
                cmp.b   #'"',d1
                beq.s   doquote

                ;-- copy the parameter in
                move.b  d1,(a1)+

nextchar:
                ;------ null termination check
                move.b  (a2)+,d1
                beq.s   parmExit
                cmp.b   #' ',d1
                beq.s   endarg

                move.b  d1,(a1)+
                bra.s   nextchar

endarg:
                clr.b   (a1)+
                bra.s   newarg

doquote:
        ;------ process quoted strings
                move.b  (a2)+,d1
                beq.s   parmExit
                cmp.b   #'"',d1
                beq.s   endarg

                ;-- '*' is the BCPL escape character
                cmp.b   #'*',d1
                bne.s   addquotechar

                move.b  (a2)+,d1
                move.b  d1,d2
                and.b   #$df,d2         ;d2 is temp toupper'd d1

                cmp.b   #'N',d2         ;check for dos newline char
                bne.s   checkEscape

                ;--     got a *N -- turn into a newline
                moveq   #10,d1
                bra.s   addquotechar

checkEscape:
                cmp.b   #'E',d2
                bne.s   addquotechar

                ;--     got a *E -- turn into a escape
                moveq   #27,d1

addquotechar:
                move.b  d1,(a1)+
                bra.s   doquote

parmExit:
        ;------ all done -- null terminate the arguments
                clr.b   (a1)
                clr.l   (a3)

	rts



 endc
 

*********************************************************************************
*
* Main program section
*

	section	refridgerator,code

* Correctly aligned fake segments for new processes. 
* Addresses must be divisible by 4.
* These are user for CreateProc() calls.

main0	jmp	main(pc)

	cnop 0,4
	dc.l	16
filereq_segment
	dc.l	0
	jmp	filereq_code(pc)

	cnop 0,4
	dc.l	16
prefs_segment
	dc.l	0
	jmp	prefs_code(pc)

	cnop 0,4
	dc.l	16
info_segment
	dc.l	0
	jmp	info_code

	dc	0 * pad


;	dc.l	16
;quad_segment
;	dc.l	0
;	jmp	quad_code

;	dc	0	* pad


 ifne DEBUG
PRINTOUT_DEBUGBUFFER
	pea	debugDesBuf+var_b 
	bsr.b PRINTOUT
	rts

PRINTOUT
	pushm	d0-d3/a0/a1/a5/a6
	lea	var_b,a5
	move.l	output(a5),d1
	bne.b	.open

	* try tall window firsr
	move.l	#.bmb,d1
	move.l	#MODE_NEWFILE,d2
	lore	Dos,Open
	move.l	d0,output(a5)
	bne.b	.open
	* smaller next
	move.l	#.bmbSmall,d1
	move.l	#MODE_NEWFILE,d2
	lob	Open
	move.l	d0,output(a5)
	bne.b	.open
	* still not open! exit
	bra.b	.x

.bmb	dc.b	"CON:0/0/350/500/HiP debug",0
.bmbSmall
	dc.b	"CON:0/0/350/200/HiP debug",0
    even
.open
	move.l	32+4(sp),a0

	moveq	#0,d3
	move.l	a0,d2
.p	addq	#1,d3
	tst.b	(a0)+
	bne.b	.p
 	lore	Dos,Write
.x	popm	d0-d3/a0/a1/a5/a6
	move.l	(sp)+,(sp)
	rts
 endc

 ifne DEBUG
getmemCount 	dc.l	0
freememCount	dc.l	0
getmemTotal		dc.l	0
 endc


intuiname	dc.b	"intuition.library",0
gfxname		dc.b	"graphics.library",0
dosname		dc.b	"dos.library",0
reqname		dc.b	"reqtools.library",0
wbname		dc.b	"workbench.library",0
diskfontname	dc.b	"diskfont.library",0
rexxname	dc.b	"rexxsyslib.library",0
scrnotifyname	dc.b	"screennotify.library",0
idname		dc.b	"input.device",0
nilname		dc.b	"NIL:",0
portname	dc.b	"HiP-Port",0
rmname		dc.b	"RexxMaster",0
fileprocname	dc.b	"HiP-Filereq",0
prefsprocname	dc.b	"HiP-Prefs",0
infoprocname	dc.b	"HiP-Info",0
layersName	dc.b	"layers.library",0
cianame	dc.b	"ciaa.resource",0
 
CHECKSTART
CHECKSUM	=	43647

procname	
reqtitle
windowname1
	dc.b	"HippoPlayer",0

about_tt
 
 dc.b "This program is registered to          ",10,3
 dc.b "%39s",10,3
 dc.b "≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠",10,3
 dc.b " List has %5ld files,  %5ld dividers ",10,3
 dc.b 0


;scrtit	dc.b	"HippoPlayer - Copyright © 1994-2021 K-P Koljonen",0
scrtit	dc.b	"HippoPlayer"
	dc.b	" by K-P in 1994-2000, 2021-2022",0
	dc.b	"$VER: "
banner_t
	dc.b	"HippoPlayer "
versionStringStart
	ver
versionStringEnd
	dc.b	10,"Programmed by K-P Koljonen",0

regtext_t dc.b	"Registered to",0
no_one	 dc.b	"   no-one",0


about_t
 dc.b "≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠",10,3
 dc.b "≠≠≠  HippoPlayer "
 ver
 dc.b "  ≠≠≠",10,3
 dc.b "≠≠          by K-P Koljonen          ≠≠",10,3
 dc.b "≠≠≠       Hippopotamus Design       ≠≠≠",10,3
 dc.b "≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠",10,3

about_t1
 dc.b "    This program is not registered!    ",10,3
 dc.b "You should register to support quality ",10,3
 dc.b "    software and to reward the poor    ",10,3
 dc.b "       author from his hard work.      ",10,3
  
 dc.b "≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠",10,3
 dc.b " HippoPlayer can be freely distributed",10,3
 dc.b " as long as all the files are included",10,3
 dc.b "   unaltered. Not for commercial use",10,3
 dc.b " without a permission from the author.",10,3
 dc.b " Copyright © 1994-2022 by K-P Koljonen",10,3
 dc.b "           *** FREEWARE ***",10,3
 dc.b "≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠",10,3
 ;dc.b "Snail mail: Kari-Pekka Koljonen",10,3
 ;dc.b "            Torikatu 31",10,3
 ;dc.b "            FIN-40900 S‰yn‰tsalo",10,3
 ;dc.b "            Finland",10,3
 ;dc.b 10,3
 ;dc.b "E-mail:     kpk@cc.tut.fi",10,3
  dc.b "E-mail:     kpk@iki.fi",10,3
 ;dc.b "            k-p@s2.org",10,3
 ;dc.b 10,3
 ;dc.b "WWW:        www.students.tut.fi/~kpk",10,3
 ;dc.b "IRC:        K-P",10,3,10,3
 dc.b "≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠≠",10,3
 dc.b "    Hippopothamos the river-horse",10,3
 dc.b "    Hippopotamus  amphibius:   a  large",10,3
 dc.b "herbivorous   mammal,  having  a  thick",10,3
 dc.b "hairless  body, short legs, and a large",10,3
 dc.b "head and muzzle.",10,3
 dc.b "    Hippopotami  live in the rivers and",10,3
 dc.b "lakes  of  Africa.  A hippo weighs 2500",10,3
 dc.b "kilos, is 140-160 cm high and 4 m long.",10,3
 dc.b "Hippos  form  herds  of 30 individuals.",10,3
 dc.b "They  are  good swimmers and divers and",10,3
 dc.b "can  stay  under water for six minutes.",10,3
 dc.b "In  the  daytime they lie on the shores",10,3
 dc.b "of  small  islands  or rest in water so",10,3
 dc.b "that  only  their eyes and nostrils can",10,3
 dc.b "be  seen.   With  the  fall of darkness",10,3
 dc.b "they get up from the water and graze on",10,3
 dc.b "the   riverside   walking   along  well",10,3
 dc.b "trampled  paths.   On  a single night a",10,3
 dc.b "hippo   eats   60   kilos   of   grass,",10,3
 dc.b "waterplants and fruit.",10,3
 dc.b 0
 dc.b $ff
 even


 ifne asm
flash	
.p	move	$dff006,$dff180
	btst	#6,$bfe001
	bne.b	.p
	rts
 endc

*
* Main program entry point
*
main
	* Global variables are in a5
	lea	var_b,a5
	move.l	4.w,a6
	* Exec is accessed a lot so it's shortest to get it from offset 0.
	move.l	a6,(a5)
	* Copy of exec for use in level1 software interrupt
	move.l	a6,exeksi

	sub.l	a1,a1
	lob	FindTask
	move.l	d0,owntask(a5)

	* Prepare a semaphore for module data access
	lea	moduleDataSemaphore(a5),a0
	lob	InitSemaphore

	* Prepare a semaphore for module list access, which is a linked list
	lea	moduleListSemaphore(a5),a0
	lob	InitSemaphore

	not.l	idopen(a5)		* -1 = input.devide ei avattu

;	move	#0,pen_0+2(a5)		* kick2.0+ v‰rit
	clr	pen_0+2(a5)
	move	#1,pen_1+2(a5)
	move	#2,pen_2+2(a5)
	move	#3,pen_3+2(a5)
	move.b	#33,keycode(a5)		* keycode

	pushpea	poptofront(pc),poptofrontr(a5)

	move	#264,WINSIZX(a5)
	* This includes 8 lines of 8-pixel height rows
	move	#136,WINSIZY(a5)
	move	WINSIZX(a5),wsizex
	move	WINSIZY(a5),wsizey


	cmp	#34,LIB_VERSION(a6)		* v‰rit kickstartin mukaan
	ble.b	.vanha
	st	uusikick(a5)		* Uusi kickstart

	* Set homedir for this task, kick2.0+
	* Assume hat pr_HomeDir gets unlocked by os.
 ifeq asm	
	move.l	owntask(a5),a3 
	tst.l 	pr_HomeDir(a3) 
	bne.b 	.hasHome 
	move.l	homelock(a5),d1 
	lore	Dos,DupLock
	move.l	d0,pr_HomeDir(a3)
.hasHome
 endif

	; Set nw_DetailPen and nw_BlockPen
	; nw_DetailPen: prop gadget background, title bar background
	; nw_BlockPen: prop gadget border color, title bar color

	basereg	winstruc,a2
	lea	winstruc,a2
	move	#$0301,d0
;	moveq	#$0001,d0
	move	d0,colors(a2)			* Ikkunoiden v‰rit sen mukaan
	move	d0,colors2(a2)
	move	d0,colors3(a2)

	* Ikkunat avautuu publiscreeneille
	;lea	winstruc,a0	
	move.l	a2,a0
	bsr.b	.boob
	lea	winstruc2(a2),a0
	bsr.b	.boob
	lea	winstruc3(a2),a0
	bsr.b	.boob
	lea	winlistsel(a2),a0
	bsr.b	.boob
	lea	swinstruc(a2),a0
	bsr.b	.boob
	bra.b	.ohib

.boob	move	#PUBLICSCREEN,nw_Type(a0)
	or.l	#WFLG_NW_EXTENDED,nw_Flags(a0)
	rts

.ohib
	* Zipped window width
	move	WINSIZX(a5),windowZippedSize(a5)	* Pienen koko ZipWindowille
	* zipped window height
	move	#11,windowZippedSize+2(a5)

	* Request events for kick2.0+
	* Catch zip window and window resize events
	or.l	#IDCMP_CHANGEWINDOW,idcmpmw(a2)	
.vanha	
	; Above stuff for kick2.0+
	endb	a2

	* Dos has been opened in the startup code
	
 ifeq asm				* uusi nykyinen hakemisto
	move.l	lockhere(a5),d1
	lore	Dos,CurrentDir
 endc

	* In asm mode startup code is skipped
 ifne asm
	lea	dosname(pc),a1
	lore	Exec,OldOpenLibrary
	move.l	d0,_DosBase(a5)
 endc

	lea	intuiname(pc),a1
	lore	Exec,OldOpenLibrary
	move.l	d0,_IntuiBase(a5)

	* The first debug print should be after opening
	* intuition since it may use the alert box.	

	DPRINT	"Hippo is alive"

	tst.b	uusikick(a5)
	beq.b	.olld
	lea	wbname(pc),a1
	lob	OldOpenLibrary
	move.l	d0,_WBBase(a5)
	lea	scrnotifyname(pc),a1
	lob	OldOpenLibrary
	move.l	d0,_ScrNotifyBase(a5)
.olld
	lea	diskfontname(pc),a1
	lob	OldOpenLibrary
	move.l	d0,_DiskFontBase(a5)

	lea	rmname(pc),a1		* Onko RexxMast p‰‰ll‰?
	lob	FindTask
	tst.l	d0
	beq.b	.norexx
	lea	rexxname(pc),a1		* jos on, avataan rexxsyslib
	lob	OldOpenLibrary
	move.l	d0,_RexxBase(a5)
	sne	rexxon(a5)		* Lippu
.norexx

	lea 	gfxname(pc),a1		
	lob	OldOpenLibrary
	move.l	d0,_GFXBase(a5)

	lea 	layersName(pc),a1		
	lob	OldOpenLibrary
	move.l	d0,_LayersBase(a5)

	pushpea	nilname(pc),d1
	move.l	#MODE_OLDFILE,d2
	lore	Dos,Open
	move.l	d0,nilfile(a5)

	lea	cianame(pc),a1
	push	a1
	move.b	#'a',3(a1)
	moveq	#0,d0
	lore	Exec,OpenResource
	move.l	d0,ciabasea(a5)
	pop	a1
	move.b	#'b',3(a1)
	moveq	#0,d0
	lob	OpenResource
	move.l	d0,ciabaseb(a5)

 if DEBUG
	jsr	openTimer
 endif

	* Get the default font for fallback cases, topaz.8
	lea	topaz_text_attr,a0
	move.l	a0,a3
	basereg	topaz_text_attr,a3
	lore	GFX,OpenFont
	move.l	d0,topazbase(a5)	

	pushm	all
	bsr.w	loadprefs
	bsr.w	loadps3msettings
	bsr.w	loadcybersoundcalibration
	popm	all



	tst	boxsize(a5)		* jos alkukoko 0 niin laitetaan zoomiks
	bne.b	.nzo			* 8
	move	#8,boxsizez(a5)	
.nzo

* Open fonts


.poh

	* text_attr is now according to loaded prefs
	lea	text_attr(a3),a0	* nyt jo muutettu prefssien mukaan
	tst.l	_DiskFontBase(a5)	* onko libbi‰?
	beq.b	.fontProblem1
	
 if DEBUG
	move.l	ta_Name(a0),d0 
	DPRINT	"Opening main font %s"
 endif 
	lore	DiskFont,OpenDiskFont
	move.l	d0,fontbase(a5)
	bne.b	.mainFontOk
	
.fontProblem1
	; Revert main font to topaz
	DPRINT	"main topaz revert"
	lea	text_attr(a3),a0	
	pushpea	topaz(a3),(a0)+
	move	#8,(a0)+
	clr	(a0)
	lea	topaz_text_attr(a3),a0
	lore	GFX,OpenFont
	move.l	d0,fontbase(a5)

.mainFontOk
	move.l	fontbase(a5),stringExtendStruct+sex_Font(a5)

	* list_text_attr is now according to loaded prefs
	lea	list_text_attr(a3),a0	* nyt jo muutettu prefssien mukaan
	tst.l	_DiskFontBase(a5)	* onko libbi‰?
	beq.b	.fontProblem2
	
 if DEBUG
	move.l	ta_Name(a0),d0 
	DPRINT	"Opening list font %s"
 endif 
	lore	DiskFont,OpenDiskFont
	move.l	d0,listfontbase(a5)
	bne.b	.listFontOk
	
.fontProblem2
	; Revert main font to topaz
	DPRINT	"list topaz revert"

	lea	list_text_attr(a3),a0	
	pushpea	topaz(a3),(a0)+
	move	#8,(a0)+
	clr	(a0)
	lea	topaz_text_attr(a3),a0
	lore	GFX,OpenFont
	move.l	d0,listfontbase(a5)
	DPRINT	"revert topaz"

.listFontOk
	endb	a3
	move.l	listfontbase(a5),a0
	bsr.w	setListFont

	* Fonts set, some other stuff next

	bsr.w	createport0
	tst.b	rexxon(a5)
	beq.b	.nor1
	bsr.w	createrexxport
.nor1



	bsr.w	getsignal
	move.b	d0,songHasEndedSignal(a5)
	bsr.w	getsignal
	move.b	d0,ownsignal2(a5)
	bsr.w	getsignal
	move.b	d0,uiRefreshSignal(a5)
	bsr.w	getsignal
	;move.b	d0,ownsignal4(a5)
	;bsr.w	getsignal
	move.b	d0,audioPortSignal(a5)
	bsr.w	getsignal
	move.b	d0,fileReqSignal(a5)
	bsr.w	getsignal
	move.b	d0,rawKeySignal(a5)
	bsr.w	getsignal
	move.b	d0,tooltipSignal(a5)

	* Do all kinds of adjustments to gadgets

	lea	sivu0,a0		* Kaikkia pageja 3pix ylˆsp‰in!
	basereg	sivu0,a0

	* Add the "Favorites" prefs button to the end of the
	* list of first page of prefs gadgets
	;move.l	#prefsFavorites,bUu22
	pushpea	prefsFavorites(a0),bUu22(a0)
	* Add "Button tooltips" prefs button to the page 2
	;move.l	#prefsTooltips,eskimO
	pushpea	prefsTooltips(a0),eskimO(a0)
	endb	a0

;	lea	sivu0,a0		* Kaikkia pageja 3pix ylˆsp‰in!
	bsr.b	.hum
	lea	sivu1-sivu0(a0),a0
	bsr.b	.hum
	lea	sivu2-sivu1(a0),a0
	bsr.b	.hum
	lea	sivu3-sivu2(a0),a0
	bsr.b	.hum
	lea	sivu4-sivu3(a0),a0
	bsr.b	.hum
	lea	sivu5-sivu4(a0),a0
	bsr.b	.hum
	lea	sivu6-sivu5(a0),a0
	bsr.b	.hum
	bra.b	.him
.hum
	move.l	a0,a1
.lop0	subq	#3,gg_TopEdge(a1)
	tst.l	(a1)
	beq.b	.e0
	move.l	(a1),a1
	bra.b	.lop0
.e0	rts

.him
	
	; Build the sex struct, font will be set
	; when it is loaded, set pens here.
	lea	stringExtendStruct(a5),a1
	move.b	#1,sex_Pens+0(a1)
	; already zeroes
	;move.b	#0,sex_Pens+1(a1)
	move.b	#1,sex_ActivePens+0(a1)
	;move.b	#0,sex_ActivePens+1(a1)

	; Make space for list mode change button
	lea	gadgetFileSlider,a0
	add	#14,gg_TopEdge(a0)
	sub	#18,gg_Height(a0)

	; The last main window button is "gadgetSortButton",
	; add another button as the new last one
	basereg	gadgetFileSlider,a0
	;move.l	#gadgetListModeChangeButton,gadgetSortButton+gg_NextGadget
	pushpea	gadgetListModeChangeButton(a0),gadgetSortButton+gg_NextGadget(a0)
	endb	a0
	
	move.l	_IntuiBase(a5),a6

	* Give each gadget a gg_GadgetID,
	* set proper text attr for ones which have text.
	moveq	#1,d0
	basereg	gadgets,a3
	lea		gadgets,a3
	lea		gadgets(a3),a1
	bsr.b	.num

** Prefs
	moveq	#1,d0
	lea		gadgets2(a3),a1
	bsr.b	.num
	moveq	#20,d0
	lea		sivu0(a3),a1
	bsr.b	.num
	moveq	#20,d0
	lea		sivu1(a3),a1
	bsr.b	.num
	moveq	#20,d0
	lea		sivu2(a3),a1
	bsr.b	.num
	moveq	#20,d0
	lea		sivu3(a3),a1
	bsr.b	.num
	moveq	#20,d0
	lea		sivu4(a3),a1
	bsr.b	.num
	moveq	#20,d0
	lea		sivu5(a3),a1
	bsr.b	.num
	moveq	#20,d0
	lea		sivu6(a3),a1
	bsr.b	.num
	endb	a3
	bra		.eer2

.num
* Numeroidaan gadgetit
	move.l	a1,a0

.er	bsr.b	.gadu
	move.l	(a0),d1
	beq.b	.eer
	move.l	d1,a0
	addq	#1,d0
	bra.b	.er
.eer	rts

* Gives a gadget an id number
* Adjust text gadget font
* Adjust prop gadget 
.gadu
	move	d0,gg_GadgetID(a0)
	move.l 	gg_SpecialInfo(a0),a2
	
	cmp	#GTYP_PROPGADGET,gg_GadgetType(a0)
	bne.b	.noProp
	* Proportional gadget setup!
	* Enable complement highlight
	* GFLG_GADGHCOMP = 0
	and		#~GFLG_GADGHNONE,gg_Flags(a0)
	* Adjust layout 
	addq	#1,gg_TopEdge(a0)
	subq	#3,gg_Height(a0)
	subq	#1,gg_Width(a0)
	* kick2.0+: newlook borderless
	or		#PROPNEWLOOK!PROPBORDERLESS,pi_Flags(a2)	
	and		#~AUTOKNOB,pi_Flags(a2)
.noProp

	cmp		#GTYP_STRGADGET,gg_GadgetType(a0)
	bne.b	.noStr
	tst.b	uusikick(a5)
	beq.b	.noStr
	* Kick2.0 only
	* Make string gadgets tab cyclable and set font with string extend
	or		#GFLG_TABCYCLE!GFLG_STRINGEXTEND,gg_Flags(a0)
	pushpea	stringExtendStruct(a5),si_Extension(a2)

.noStr
	* If contains text, set font
	tst.l	gg_GadgetText(a0)
	beq.b	.noTxt
	move.l	gg_GadgetText(a0),a2	* IntuiText
	move.l	#text_attr,it_ITextFont(a2)	* fontti
	tst.l	it_NextText(a2)
	beq.b	.noTxt
	move.l	it_NextText(a2),a2
	move.l	#text_attr,it_ITextFont(a2)	* fontti
.noTxt	

	rts

.eer2
	* Adjust file slider a bit
	lea		slider4,a0
	basereg	slider4,a0
	addq	#1,slider4+gg_Height(a0)
	addq	#1,slider4+gg_LeftEdge(a0)
	addq	#1,slider4+gg_Width(a0)
	move.l	#slimage,slider4+gg_GadgetRender(a0)	* filebox-slideriin image

	* Nudge this a bit!
	addq	#1,gg_TopEdge+juust0(a0) 		* ps3m stereo level

	* Info window slider
	moveq	#0,d0
	lea		gAD1(a0),a0
	endb	a0
	bsr		.gadu
	addq	#3,gg_Height(a0)
	addq	#1,gg_Width(a0)
	move.l	#slimage2,gg_GadgetRender(a0) 	* moduleinfo-slideriin image
	
	
	* Gadget stuff done.

	move.l	#PLAYING_MODULE_NONE,chosenmodule2(a5)

	bset	#1,$bfe001
	sne	filterstore(a5)			* filtterin tila talteen
	st	modulefilterstate(a5)

	lea	moduleListHeader(a5),a0		* Uusi lista
	NEWLIST	a0
	lea	favoriteListHeader(a5),a0
	NEWLIST a0
	lea	fileBrowserListHeader(a5),a0
	NEWLIST a0

	lea	.startingMsg(pc),a0
	moveq	#102+WINX,d0
	bsr.w	printbox
	bra.b	.startingMsg2
.startingMsg dc.b "Starting...",0
 even
.startingMsg2



	jsr	loadkeyfile		* ladataan key-file


******* Vanha kick: otsikkopalkin ja WB-nayton koko
	tst.b	uusikick(a5)
	bne.w	.newkick

	; Copy alternative horiz prop gadget gfx for kick13
	lea	horizPropGadgetGfxNormal,a0
	moveq	#horizPropGadgetGfxNormal_kick13-horizPropGadgetGfxNormal,d0
	lea	(a0,d0),a1
	move.l	a1,a2
.cp13	move	(a1)+,(a0)+
	cmp.l	a0,a2
	bne.b	.cp13

	lea	horizPropGadgetGfxDouble,a0
	moveq	#horizPropGadgetGfxDouble_kick13-horizPropGadgetGfxDouble,d0
	lea	(a0,d0),a1
	move.l	a1,a2
.cp14	move	(a1)+,(a0)+
	cmp.l	a0,a2
	bne.b	.cp14
 


** 3 pixeli‰ korkeempi infowindowin slideri
;	addq	#3,gg_Height+gAD1

* kick1.3 v‰rit
;	move	#0,pen_0+2(a5)	
	clr	pen_0+2(a5)
	move	#1,pen_1+2(a5)
	move	#2,pen_2+2(a5)
	move	#3,pen_3+2(a5)


** Poistetaan reqtoolsrequesterien pubscreentagit
	lea	otag1(pc),a0
	clr.l	(a0)
	clr.l	otag2-otag1(a0)
	clr.l	otag3-otag1(a0)
	clr.l	otag4-otag1(a0)
	clr.l	otag5-otag1(a0)
;	clr.l	otag6-otag1(a0)
;	clr.l	otag7-otag1(a0)
	clr.l	otag8-otag1(a0)
;	clr.l	otag9-otag1(a0)
;	clr.l	otag10-otag1(a0)
;	clr.l	otag11-otag1(a0)
;	clr.l	otag12-otag1(a0)
;	clr.l	otag13-otag1(a0)
	clr.l	otag14-otag1(a0)
	clr.l	otag15-otag1(a0)
	clr.l	otag16-otag1(a0)
	clr.l	otag17-otag1(a0)
	
	* Opens a 1x1 pixel sized window to fetch some Workbench attributes
	* Then immediately closes it!

	lea	winstruc,a0
	move.l	#$00010001,wsizex-winstruc(a0)	* koko 1x1
	lore	Intui,OpenWindow
	tst.l	d0
	bne.b	.go2
	move.b	#i_nowindow,startuperror(a5)
	bra.w	exit
.go2	
	move.l	d0,a0
	move.l	wd_WScreen(a0),a1		* WB screen addr
	move	sc_Width(a1),wbleveys(a5)	* WB:n leveys
	move	sc_Height(a1),wbkorkeus(a5)	* WB:n korkeus
	move.b	sc_BarHeight(a1),windowtop+1(a5) * palkin korkeus
	lob	CloseWindow
	move	WINSIZX(a5),wsizex
	move	WINSIZY(a5),wsizey
	sub	#10,windowtop(a5)
.newkick

	bsr.w	inithippo
	bsr.w	initkorva
	bsr.w	initkorva2
 ifne FEATURE_HORIZ_RESIZE
	jsr	initializeButtonRowLayout
 endif

	st	reghippo(a5)


	move.l	(a5),a0
	moveq	#0,d1
	move.b	PowerSupplyFrequency(a0),d1	
	move.l	#3546895,d0
	cmp	#50,d1
	beq.b	.pal
;	move.l	#3579545,d0
	move	#$9E99,d0
.pal	move.l	d0,clockconstant(a5)

	bsr.w	divu_32
	move.l	d0,colordiv(a5)		* 50Hz tai 60Hz n‰ytˆlle

	move	#15600,horizfreq(a5)
	move	#50,vertfreq(a5)
	
	bsr.w	srand			* randomgeneratorin seed!



	lea	sv_argvArray+4(a5),a3	* ei ekaa
	tst.l	(a3)
	beq.b	.nohide
	move.l	(a3),a0
	bsr.w	kirjainta4
	cmp.l	#MESSAGE_COMMAND_HIDE,d0		* oliko komento 'HIDE'??
	bne.b	.nohide
	clr.b	win(a5)
	bra.b	.hid
.nohide
	bsr.w	get_rt

	st	win(a5)
	bsr.w	avaa_ikkuna		* palauttaa d4:ss‰ keycheckin~
	beq.b	.go3
	clr.b	win(a5)
	move.b	#i_nowindow,startuperror(a5)
	bra.w	exit
.go3


* ikkuna avattu.. katotaan pit‰‰ko olla pieni
	tst.b	prefsdata+prefs_kokolippu(a5)
	beq.b	.hid
	bsr.w	zipMainWindow
.hid

	jsr	inforivit_clear
	jsr	importFavoriteModulesFromDisk
	jsr	initializeUHC

	DPRINT	"Loading group"

	tst.b	groupmode(a5)			* ladataanko playergrouppi?
	bne.b	.purr
	jsr	loadplayergroup
	move.l	d0,externalplayers(a5)
;	bne.b	.purr
;	lea	grouperror_t,a1		* ei valiteta vaikka ei lˆydykk‰‰n
;	bsr.w	request


* ladataan playerlibitkin samantien
* these were previously loaded at start up. not a very good idea,
* slows down and uses extra mem for nothing.
	;jsr	get_sid
	;jsr	get_med1
	;jsr	get_med2
	;jsr	get_med3
	;jsr	get_mline

.purr


	pushpea	scopeData+scope_ch1(a5),hippoport+hip_PTch1(a5)
	pushpea	scopeData+scope_ch2(a5),hippoport+hip_PTch2(a5)
	pushpea	scopeData+scope_ch3(a5),hippoport+hip_PTch3(a5)
	pushpea	scopeData+scope_ch4(a5),hippoport+hip_PTch4(a5)
	pushpea	kplbase(a5),hippoport+hip_kplbase(a5)
	pushpea	moduleListHeader(a5),hippoport+hip_moduleListHeader(a5)

	move.l	colordiv(a5),hip_colordiv+hippoport(a5)


	moveq	#INTB_VERTB,d0
	lea	intserver,a1
	lore	Exec,AddIntServer
	st	ciasaatu(a5)
	st	vbsaatu(a5)

	bsr.w	init_inputhandler
	bsr.w	init_screennotify
	jsr	startAndStopScopeTasks

	tst.b	infoon(a5)
	beq.b	.qq
;	st	oli_infoa(a5)
	DPRINT	"Starting info"
	jsr	rbutton10b
.qq

	jsr	inforivit_clear

	tst	boxsize(a5)
	beq.b	.oohi

	lea	banner_t(pc),a0			* registered to..
	moveq	#11+WINX,d0
	moveq	#18+WINY,d1
	bsr.w	print

	; ei annoytekstia vaikkei rekisteroity
	cmp.b	#' ',keyfile(a5)
	beq.b	.oohi

	lea	regtext_t(pc),a0
	moveq	#62+WINY,d1
	bsr.b	.rount

	lea	keyfile(a5),a0
	moveq	#72+WINY,d1
	bsr.b	.rount
	bra.b	.oohi

.rount
	moveq	#34+WINX,d0
	tst.b	uusikick(a5)
	bne.b	.uere
	add	#28,d0
.uere	
	move	boxsize(a5),d2
	beq.b	.oohi
	cmp	#7,d2
	bhi.b	.re
	add	#50,d0
.re	cmp	#3,d2
	bne.b	.r
	addq	#6,d1
	bra.b	.w

 
.r	lsr	#1,d2
	subq	#1,d2
	lsl	#3,d2
	add	d2,d1
.w	bra.w	print

.oohi



 ifne EFEKTI
	jsr	efekti
 endc
	tst.l	sv_argvArray+4(a5)
	bne.b	.komento0
	tst.b	startuponoff(a5)
	beq.b	.komento0
	tst.b	startup(a5)
	beq.b	.komento0
	pushpea	startup(a5),sv_argvArray+4(a5) * Parametriksi startupmoduuli
	clr.l	sv_argvArray+8(a5)
.komento0
	bsr.w	komentojono			* tutkitaan komentojono.

	* Command line and startup modules handled,
	* if none of these provided stuff, try the saved
	* state modules.
	tst.l 	modamount(a5)
	bne.b	.skip
	jsr	importSavedStateModulesFromDisk
.skip

*********************************************************************************
*
* P‰‰silmukka
*	

	DPRINT	"Entering message loop"

;	jsr	startQuadraScopeTask

	bra.b	msgloop
returnmsg
	bsr.w	flush_messages
msgloop	
	tst.b	exitmainprogram(a5)
	bne.w	exit

	cmp.b	#1,do_alarm(a5)
	bne.b	.noal				* her‰tys!
	addq.b	#1,do_alarm(a5)
	lea	startup(a5),a0
	tst.b	(a0)
	beq.b	.noal				* onko moduulia??
	move.l	a0,sv_argvArray+4(a5)		* Parametriksi startupmoduuli
	clr.l	sv_argvArray+8(a5)
	bsr.w	komentojono
	bra.b	returnmsg
.noal

	moveq	#0,d0
	move.b	songHasEndedSignal(a5),d1
	bset	d1,d0
	move.b	ownsignal2(a5),d1
	bset	d1,d0
	move.b	uiRefreshSignal(a5),d1
	bset	d1,d0
	;move.b	ownsignal4(a5),d1
	;bset	d1,d0
	move.b	audioPortSignal(a5),d1
	bset	d1,d0
	move.b	fileReqSignal(a5),d1
	bset	d1,d0
	move.b	rawKeySignal(a5),d1
	bset	d1,d0
	move.b	tooltipSignal(a5),d1
	bset	d1,d0
	move.b	hippoport+MP_SIGBIT(a5),d1 * oman viestiportin bitti
	bset	d1,d0

	tst.b	win(a5)
	beq.b	.nw
	move.l	userport(a5),a0
	move.b	MP_SIGBIT(a0),d1		* ikkunan IDCMP:n sigbit
	bset	d1,d0
.nw
	tst.b	rexxon(a5)
	beq.b	.nre
	move.b	rexxport+MP_SIGBIT(a5),d1	* ARexx-portin signalibitti
	bset	d1,d0
.nre
	* We get signal?
	lore	Exec,Wait		* Odotellaan...
	* Active signals in D0

	tst.b	rexxon(a5)
	beq.b	.nrexm
	move.b	rexxport+MP_SIGBIT(a5),d3	* Tuliko ARexx viesti?
	btst	d3,d0
	beq.b	.nrexm
	jsr	rexxmessage
	bra.w		returnmsg

.nrexm
* Tuliko viesti‰ porttiin?
	move.b	hippoport+MP_SIGBIT(a5),d3
	btst	d3,d0
	beq.b	.ow
	push	d0
	bsr.w	omaviesti
	pop	d0
.ow

* Tuliko omia signaaleja??
	move.b	songHasEndedSignal(a5),d3
	btst	d3,d0
	beq.b	.nowo
	pushm	all
	bsr.w	signalreceived
	popm	all


*** Poistuttiinko preffsist‰?
* Prefs window was just closed? Do stuff!
* Probably this bit handles things like:
* - move windows to a newly set public screen
* - update filebox size according to prefs changes
* - update titlebar information
* - quite ugly!
.nowo	move.b	ownsignal2(a5),d3	* p‰ivitet‰‰n positionia
	btst	d3,d0
	beq.b	.noSignal2
	push	d0  * save signal mask
	bsr.w	handleSignal2
	move.l	d0,d1
	; d0 = -1 -> window error, exit
	; d0 =  1 -> window reopened, skip rest of the event loop
	; d0 =  0 -> continue
	pop	d0
	tst.l	d1
	bmi.w	exit
	bne.w	returnmsg
.noSignal2

	move.b	uiRefreshSignal(a5),d3	* p‰ivitet‰‰n...
	btst	d3,d0
	beq.b	.wow
	addq	#1,userIdleTick(a5)
	push	d0
	jsr	lootaan_aika
	jsr	lootaan_kello
;	bsr.w	lootaan_muisti
	jsr	lootaan_nimi
	; No need to call this every refresh signal, it is handled via RMB 
	; and IDCMP-event handlers anyway:
	;bsr.w	zipwindow

	* Try to save favorite modules when user has been idle for a while
	moveq	#0,d0 
	move	userIdleTick(a5),d0 
	cmp	#7,d0
	blo.b	.notIdleEnough
	jsr	exportFavoriteModulesWithMessage
.notIdleEnough

	pop	d0

.wow


*** poistuttiin filerequesterista

	push	d0
	move.b	fileReqSignal(a5),d3
	btst	d3,d0
	beq.b	.nwww

* this signal is set when the filerequester for adding files is ready

	tst.b	autosort(a5)		* automaattinen sorttaus?
	beq.b	.nas
	bsr.w	rsort
.nas

	jsr	listChanged
	bsr.w	forceRefreshList


	move.b	haluttiinuusimodi(a5),d1
	clr.b	haluttiinuusimodi(a5)

	move.b	new(a5),d0
	clr.b	new(a5)
	tst.b	d0
;	beq.b	.nwww		* ??
	beq.b	.whm		* ??
	bpl.b	.nwww	

.whm	;tst.b	haluttiinuusimodi(a5)
	tst.b	d1
	beq.b	.nwww
	;clr.b	haluttiinuusimodi(a5)


* T‰nne tullaan sillon, kun on painettu playt‰ eik‰ ollut modeja,
* filereq-prosessin signaalista. Eli aletaan soittaa ekaa valittua modia.

	tst.l	modamount(a5)		* Ei modeja edelleenk‰‰n
	beq.b	.nwww

	movem.l	d0-a6,-(sp)
	clr.l	firstname(a5)		* valitaan eka
	clr.l	chosenmodule(a5)
	tst.l	playingmodule(a5)
	bmi.b	.ee
	move.l	#PLAYING_MODULE_REMOVED,playingmodule(a5)
.ee	
	cmp.b	#pm_random,playmode(a5)
	bne.b	.noRand
	bsr.w	soitamodi_random
	bra.b	.wasRand
.noRand
	bsr.w	rbutton1
.wasRand
	movem.l	(sp)+,d0-a6
	
.nwww	pop	d0

	bsr.w	areMainWindowGadgetsFrozen
	bne.w	.nwwwq

	move.b	rawKeySignal(a5),d3	* rawkey inputhandlerilta
	btst	d3,d0
	beq.w	.nwwwq
	DPRINT	"rawkey from input handler"
	moveq	#0,d4
	move	rawkeyinput(a5),d3
	cmp	#$25,d3			* oliko 'h'?
	beq.b	.hide
	cmp	#$01,d3			* '1'? -> iconify
	bne.b	.nico
	moveq	#0,d3			* muutetaan -> ~`
	bsr.w	nappuloita
	bra.w	returnmsg
.nico

	tst	d3
	beq.b  .noKeys
	bsr.w nappuloita
	bra.w	returnmsg
.noKeys

	tst.b	win(a5)
	bne.b	.obh
.open	
	bsr.w	openw
	bne.w	exit
	bra.w	returnmsg

.obh	
* painettiinko zip windowi ei-ikkunassa? pullautetaan..
	tst.b	kokolippu(a5)
	beq.b	.op
	bsr.w	front
	bra.b	.nwwwq
.op	bsr.w	sulje_ikkuna
	clr.b	win(a5)
	bra.b	.open


.hide
	tst.b	win(a5)
	beq.b	.open
	bsr.w	sulje_ikkuna
	clr.b	win(a5)
	bra.w	returnmsg


.nwwwq

	* Note: signal4 does not seem to be triggered anywhere!
;	move.b	ownsignal4(a5),d3
;	btst	d3,d0
;	beq.b	.nowww
;	bsr.w	sulje_ikkuna
;	bsr.w	avaa_ikkuna
;	bne.w	exit
;	bra.w	returnmsg
;
;.nowww	
	
	* Tooltip display signal check
	move.b	tooltipSignal(a5),d3 
	btst	d3,d0 
	beq.b	.noTooltipSignal
	bsr.w	tooltipDisplayHandler
.noTooltipSignal

* Vastataan IDCMP:n viestiin

	
;getmoremsg
	tst.b	win(a5)
	beq.w	msgloop

	* Ignore any ui actions if window is frozen
	* Flush any remaining messages 
	bsr.w	areMainWindowGadgetsFrozen
	bne.w	returnmsg		

* Process IDCMP messages if any
	clr.b	ignoreMouseMoveMessage(a5)
.idcmpLoop
	move.l	userport(a5),a4
	move.l	a4,a0
	lore Exec,GetMsg
	* Go back to mainloop if no more messages left
	tst.l	d0
	beq.w	msgloop

	move.l	d0,a1
	move.l	im_Class(a1),d2		* luokka	
	move	im_Code(a1),d3		* koodi
	move	im_Qualifier(a1),d4	* RAWKEY: IEQUALIFIER_?
	move.l	im_IAddress(a1),a2 	* gadgetin tai olion osoite
	move	im_MouseX(a1),mousex(a5)
	move	im_MouseY(a1),mousey(a5)

	lob	ReplyMsg

	cmp.l	#IDCMP_CHANGEWINDOW,d2
	bne.b	.noChangeWindow
	; Window resize events go into IDCMP_CHANGEWINDOW
	; on kick 2.0+.
	bsr.w	zipwindow
	bsr.w	mainWindowSizeChanged
	bra.b	.idcmpLoop

.noChangeWindow
	cmp.l	#IDCMP_NEWSIZE,d2
	bne.b	.noNewSize
	tst.b	uusikick(a5)
	bne.b	.idcmpLoop
	; Use this event on kick1.3, as CHANGEWINDOW is not reported there.
	bsr.w	mainWindowSizeChanged
	bra.b	.idcmpLoop
.noNewSize

	cmp.l	#IDCMP_RAWKEY,d2
	bne.b	.noRawKey
	clr	userIdleTick(a5)	
	bsr.w	nappuloita
	bra.b	.idcmpLoop
.noRawKey	
	* There will be a lot of mousemove messages.
	* To keep the load light only take the first one and filter out the
	* rest during this message loop.
	* Prop gadgets and tooltips will work with fewer events, too.
	cmp.l	#IDCMP_MOUSEMOVE,d2
	bne.b	.noMouseMove
	clr	userIdleTick(a5)		* clear user idle counter, user is moving mouse
	tst.b	ignoreMouseMoveMessage(a5) 
	bne.b  	.idcmpLoop
	st	ignoreMouseMoveMessage(a5)
	bsr.w	mousemoving
	bra.w	.idcmpLoop

.noMouseMove
	cmp.l	#IDCMP_GADGETUP,d2
	bne.b	.noGadgetUp
	clr	userIdleTick(a5)	
	bsr.w	gadgetsup
	bra.w	.idcmpLoop
.noGadgetUp
	cmp.l	#IDCMP_MOUSEBUTTONS,d2
	bne.b	.noMouseButtons
	clr	userIdleTick(a5)	
	bsr.w	buttonspressed
	bra.w	.idcmpLoop
.noMouseButtons	
	cmp.l	#IDCMP_CLOSEWINDOW,d2
	bne.b	.noClose
	bra.b	exit
.noClose
	; When activating or inactivating the window
	; frame will be redrawn on top of the resize gadget,
	; so redraw it to ensure correct visual.
	cmp.l	#IDCMP_ACTIVEWINDOW,d2
	bne.b	.noActive
	bsr.w	refreshResizeGadget
	bra.w	.idcmpLoop
.noActive
	cmp.l	#IDCMP_INACTIVEWINDOW,d2
	bne.b	.noInactive
	bsr.w	refreshResizeGadget
.noInactive

	* All messages checked
	bra.w	.idcmpLoop
	
exit	
	lea	var_b,a5

	DPRINT "Hippo is exiting"
	bsr.w	setMainWindowWaitPointer	

	lea	.exmsg(pc),a0
	moveq	#102+WINX,d0
	bsr.w	printbox
	bra.b	.exmsg2
.exmsg dc.b	"Exiting...",0
 even
.exmsg2
	jsr	exportFavoriteModulesToDisk
	jsr	exportSavedStateModulesToDisk
	jsr	deinitUHC
* poistetaan loput prosessit...


* onko prosessien k‰ynnistys kesken?
;	cmp	#1,prefs_prosessi(a5)
;	beq.b	.er2	
;	cmp	#1,quad_prosessi(a5)
;	beq.b	.er2	
;	cmp	#1,filereq_prosessi(a5)
;	beq.b	.er2	

	bsr.w	sulje_prefs
	;jsr	sulje_quad
	jsr	stopScopeTasks
	jsr	sulje_info

	tst.b	hippoport+hip_opencount(a5)	* onko portilla
	beq.b	.joer				* k‰ytt‰ji‰?

** k‰sket‰‰n niit‰ sammumaan.
	st	hippoport+hip_quit(a5)


	moveq	#3*25-1,d7		* odotetaan max 2 sekkaa
.jorl	tst.b	hippoport+hip_opencount(a5)
	beq.b	.joer
	bsr.w	dela
	dbf	d7,.jorl
	bra.b	.er
	clr.b	hippoport+hip_quit(a5)	* ei en‰‰ quittia jos ei onnistunu.

.joer

* n‰it‰ ei voida niin vaan poistaakaan.
	tst	filereq_prosessi(a5)
	beq.b	.ex

.er	lea	.clo(pc),a1
.req	jsr	request
	clr.b	exitmainprogram(a5)	* ei en‰‰ exitti‰.	
	bra.w	msgloop
.clo	dc.b	"Close all requesters & external programs and try again!",0
 even

.ex
	bsr.w	rbutton4b		* eject /wo fade
	bsr.w	freelist		* vapautetaan lista
	jsr	rem_ciaint

	jsr	freeFavoriteList
	jsr	freeFileBrowserList

	tst.b	vbsaatu(a5)
	beq.b	.nbv
	moveq	#INTB_VERTB,d0
	lea	intserver,a1
	lore	Exec,RemIntServer
.nbv



	tst.b	filterstore(a5)
	bne.b	.ee
	bclr	#1,$bfe001
.ee
	jsr	vapauta_kanavat
	bsr.w	rem_inputhandler
	bsr.w	rem_screennotify

	move.l	externalplayers(a5),a0		* vapautetaan playerit
	bsr.w	freemem

	move.l	xplayer(a5),a0
	bsr.w	freemem
	move.l	ps3msettingsfile(a5),a0		* vapautetaan ps3masetustied.
	bsr.w	freemem
	move.l	calibrationaddr(a5),a0
	bsr.w	freemem
	move.l	randomtable(a5),a0
	bsr.w 	freemem
	move.l	lastStoredFileReqDirectory(a5),a0 
	bsr.w	freemem

	jsr	closeTooltipPopup
	bsr.w	flush_messages
	bsr.w	sulje_ikkuna

	move.b	songHasEndedSignal(a5),d0
	bsr.w	freesignal
	move.b	ownsignal2(a5),d0
	bsr.w	freesignal
	move.b	uiRefreshSignal(a5),d0
	bsr.w	freesignal
	;move.b	ownsignal4(a5),d0
	;bsr.w	freesignal
	move.b	audioPortSignal(a5),d0
	bsr.w	freesignal
	move.b	fileReqSignal(a5),d0
	bsr.w	freesignal
	move.b	rawKeySignal(a5),d0
	bsr.w	freesignal
	move.b	tooltipSignal(a5),d0
	bsr.w	freesignal

	move.l	fontbase(a5),d0
	beq.b	.uh22
	move.l	d0,a1
	lore	GFX,CloseFont
.uh22

	move.l	minifontbase(a5),d0
	beq.b	.uh3
	move.l	d0,a1
	lore	GFX,CloseFont
.uh3
	move.l	listfontbase(a5),d0
	beq.b	.uh4
	move.l	d0,a1
	lore	GFX,CloseFont
.uh4
	move.l	topazbase(a5),a1
	lore	GFX,CloseFont

	move.l	req_file(a5),d0
	beq.b	.whoop
	move.l	d0,a1
	lore	Req,rtFreeRequest
.whoop

	tst.b	rexxon(a5)
	beq.b	.nor2
	bsr.w	deleterexxport
.nor2	bsr.w	deleteport0

	move.l	nilfile(a5),d1
	lore	Dos,Close
 
 if DEBUG
	jsr	closeTimer
 endif

	move.l	_SIDBase(a5),d0		* poistetaan sidplayer
	beq.b	.nahf			
	jsr	rem_sidpatch		* patchi kanssa
	move.l	_SIDBase(a5),a1
	lore	Exec,CloseLibrary
.nahf	
	move.l	_MedPlayerBase1(a5),d0
	bsr.w	closel
	move.l	_MedPlayerBase2(a5),d0
	bsr.w	closel
	move.l	_MedPlayerBase3(a5),d0
	bsr.w	closel
	move.l	_MlineBase(a5),d0
	bsr.w	closel

	move.l	_PPBase(a5),d0
	bsr.w	closel
	move.l	_XPKBase(a5),d0
	bsr.w	closel
	move.l	_XFDBase(a5),d0
	bsr.w	closel
	move.l	_ScrNotifyBase(a5),d0
	bsr.w	closel
	move.l	_RexxBase(a5),d0
	bsr.w	closel
	move.l	_DiskFontBase(a5),d0
	bsr.w	closel
	move.l	_WBBase(a5),d0
	bsr.w	closel
	move.l	_GFXBase(a5),d0
	bsr.w	closel
	move.l	_ReqBase(a5),d0
	bsr.w	closel
	move.l	_FFPBase(a5),d0
	bsr.w	closel
	move.l	_MTBase(a5),d0
	bsr.w	closel
	move.l	_LayersBase(a5),d0
	bsr.w	closel

	bsr.w	tulostavirhe
	move.l	_IntuiBase(a5),d0
	bsr.w	closel

	move.l	fileBrowserCurrentDirLock(a5),d1
	beq.b	._1
	lore	Dos,UnLock
._1


 ifne DEBUG
	move.l	getmemCount(pc),d0
	DPRINT "Getmem count: %ld"
	move.l	freememCount(pc),d1
	DPRINT "Freememcount: %ld"
	move.l	getmemTotal(pc),d0 
	lsr.l	#8,d0 
	lsr.l	#2,d0 
	DPRINT "Getmem total: %ld kilobytes"
	move.l	getmemTotal(pc),d0
	move.l	getmemCount(pc),d1
	bne.b	.nz
	moveq	#1,d1
.nz
	bsr.w		divu_32
	DPRINT "Getmem avg: %ld bytes"

	move.l	#(1)*50,d1
	lore	Dos,Delay

 	move.l	output(a5),d1
 	beq.b	.xef
	lob	Close
.xef
 endc ; DEBUG

	* free any locks
	move.l	_DosBase(a5),a6
	move.l	lockhere(a5),d1
	beq.b	.noLock
	lob		UnLock
.noLock
	move.l	homelock(a5),d1
	beq.b	.noHome
	lob     UnLock
.noHome

	lore	Exec,Forbid			* forbid multitasking 

	move.l	_DosBase(a5),d0		* last library to be closed
	bsr.b	closel
	; safely assume DOS is still available after this

 ifeq asm
	; detached process exit
	bsr.w	vastomaviesti		* reply to any message we may have received

	* Free program segments. After this the following code lines may become
	* unavailable.
	move.l	segment(a5),d1
	move.l  _DosBase(a5),a6
	jmp 	_LVOUnLoadSeg(a6)   * end of transmission
 else
	; asm-one exit
	moveq	#0,d0				* end of transmission
	rts
 endif 

closel:
	beq.b	.notopen
	move.l	d0,a1
	lore	Exec,CloseLibrary
.notopen
	rts

freesignal
	tst.b	d0
	bmi.b	.e
	lore	Exec,FreeSignal
.e	rts

getsignal
	moveq	#-1,d0
	move.l	(a5),a6
	jmp	_LVOAllocSignal(a6)

smallDelay:
dela:	pushm	all		* pienenpieni delay
	moveq	#1,d1
	lore	Dos,Delay
	popm	all
	rts

*** Avaa ReqToolssin

get_rt:
	lea	var_b,a5
	tst.l	_ReqBase(a5)
	bne.b	.o
	pushm	d0/d1/a0/a1/a6
	lea 	reqname(pc),a1		
	moveq	#38,d0
	lore	Exec,OpenLibrary
	move.l	d0,_ReqBase(a5)
	bne.b	.ok

	move.b	#1,startuperror(a5)
	bsr.b	tulostavirhe
;	move.l	#$7fffffff,d1
	moveq	#-2,d1
	ror.l	#1,d1

	lore	Dos,Delay
.ok
	popm	d0/d1/a0/a1/a6
.o	move.l	_ReqBase(a5),a6
	rts


;se_noreq
;	move.b	#i_noreq,startuperror(a5)
;	bsr.b	tulostavirhe
;	bra.b	exit2

tulostavirhe
	tst.b	startuperror(a5)
	bne.b	.ee
	rts
.ee	pushm	all

	move.b	startuperror(a5),d0
	lea	.r1(pc),a0
	subq.b	#1,d0
	beq.b	.r
	lea	.r2(pc),a0
	subq.b	#1,d0
	beq.b	.r
	lea	.r3(pc),a0
	subq.b	#1,d0
	bne.b	.x
.r	
	moveq	#0,d0		* recovery
	moveq	#19,d1		* korkeus
	lore	Intui,DisplayAlert
	
.x	popm	all
	rts

.r1	;dc	(640-((.r1e-.r1-2)*8))/2
	;dc	208
	dc	176
	dc.b	11
	dc.b	"HiP frozen: no reqtools.library V38+!",0,0
.r1e
 even
.r2	
	;dc	(640-((.r2e-.r2-2)*8))/2
	dc	212
	dc.b	11
	dc.b	"HiP: no CIA interrupts!",0,0
.r2e
 even
.r3	
	;dc	(640-((.r3e-.r3-2)*8))/2
	dc	248
	dc.b	11
 	dc.b	"HiP: no window!",0,0
.r3e
  even
 
i_noreq		=	1
i_nocia		=	2
i_nowindow	=	3


*******
* Flush main window messages
*******
flush_messages
	bsr.b	.fl
	move.l	windowbase(a5),a0 
	jmp		flushWindowMessages

* Flush port messages too
* Hippoportin messaget pois
.fl	tst.b	hippoporton(a5)
	beq.b	.exit
	move.l	(a5),a6
	lea	hippoport(a5),a0
	lob	GetMsg
	tst.l	d0
	beq.b	.exit
	move.l	d0,a1
	lob	ReplyMsg
	bra.b	.fl
.exit 	rts
		


createrexxport	pushm	all
		lea	.p(pc),a4
		lea	rexxport(a5),a2
		bra.b	createport1

.p	dc.b	"HIPPOPLAYER",0
 even
	
createport0	pushm	all
		lea	portname(pc),a4
		lea	hippoport(a5),a2
		st	hippoporton(a5)
createport1	moveq	#-1,d0
		lore	Exec,AllocSignal	* varataan signaalibitti
		move.b	d0,MP_SIGBIT(a2)	* asetetaan signaali porttiin
		move.l	owntask(a5),MP_SIGTASK(a2) * asetataan osoite porttiin
		move.b	#NT_MSGPORT,LN_TYPE(a2)	* noden tyyppi = MSGPORT
		clr.b	MP_FLAGS(a2)		* nollataan liput
		move.l	a4,LN_NAME(a2)
		move.l	a2,a1
		lob	AddPort
		popm	all
		rts

deleterexxport	pushm	all
		lea	rexxport(a5),a2
		bra.b	deleteport1

deleteport0	
		tst.b	hippoporton(a5)
		bne.b	.n
		rts

.n		clr.b	hippoporton(a5)
		pushm	all
		lea	hippoport(a5),a2
deleteport1	move.l	a2,a1
		lore	Exec,RemPort
		moveq	#0,d0
		move.b	MP_SIGBIT(a2),d0	* signaalin numero
		lob	FreeSignal
		popm	all
		rts


******************************************************************************
* Screennotify
*****************************************************************************

init_screennotify
	tst.b	uusikick(a5)
	beq.b	.x
	move.l	_ScrNotifyBase(a5),d0
	beq.b	.x
	move.l	d0,a6
	moveq	#0,d0			* priority
	lea	hippoport(a5),a0
	lob	AddWorkbenchClient
	move.l	d0,notifyhandle(a5)
.x	rts

rem_screennotify
	move.l	notifyhandle(a5),d0
	beq.b	.x
	move.l	d0,a0
	lore	ScrNotify,RemWorkbenchClient
.x	rts


******************************************************************************
* Inputhandler
*****************************************************************************

init_inputhandler
	lea	idname(pc),a0
	moveq	#0,d0			* unit
	lea	iorequest2(a5),a1
	moveq	#0,d1			* flags
	lore	Exec,OpenDevice
	move.l	d0,idopen(a5)
	bne.w	iderror	

	lea	idmsgport(a5),a2
	move.b	#NT_MSGPORT,LN_TYPE(a2)
	clr.b	MP_FLAGS(a2)
	clr.l	LN_NAME(a2)		* name

	moveq	#-1,d0			* get signal bit
	lob	AllocSignal
	move.b	d0,MP_SIGBIT(a2)
;	bmi.b	iderror

	move.l	owntask(a5),MP_SIGTASK(a2)
	lea	MP_MSGLIST(a2),a0
	NEWLIST	a0
	lea	iorequest2(a5),a1
	move.l	a2,MN_REPLYPORT(a1)

	lea	intstr(a5),a4
	move.b	#NT_INTERRUPT,LN_TYPE(a4)
	move.b	#60,LN_PRI(a4)
	lea	inputhandler(pc),a2
	move.l	a2,IS_CODE(a4)
	move.l	a5,IS_DATA(a4)		* IS_DATA = var_b

	lea	iorequest2(a5),a1
	move	#IND_ADDHANDLER,IO_COMMAND(a1)
	move.l	a4,IO_DATA(a1)
	lob	DoIO


*** Registration check.
	tst.b	keycheck(a5)
	beq.b	.rite
	lea	no_one(pc),a0
	lea	keyfile(a5),a1
.jaffa	move.b	(a0)+,(a1)+
	bne.b	.jaffa
.rite
****

	tst.l	d0
	bne.b	iderror
	moveq	#0,d0
	rts

 
rem_inputhandler
iderror
	tst.l	idopen(a5)
	bne.b	.nope

	lea	iorequest2(a5),a1
	move	#IND_REMHANDLER,IO_COMMAND(a1)
	lea	intstr(a5),a0
	move.l	a0,IO_DATA(a1)
	lore	Exec,DoIO

	move.l	idopen(a5),d0
	lea	iorequest2(a5),a1
	lob	CloseDevice

.nope	
	moveq	#0,d0
	move.b	idmsgport+MP_SIGBIT(a5),d0
	bmi.b	.nope2
	beq.b	.nope2
	lore	Exec,FreeSignal
.nope2

	moveq	#0,d0
	rts


* a0 = start of the event list
* a1 = user data pointer (var_b)
inputhandler
	tst.b	hotkey(a1)
	beq.b	.quit
	push	a0
.handlerloop
	cmp.b	#IECLASS_RAWKEY,ie_Class(a0)
	bne.b	.cont
	move	ie_Qualifier(a0),d0
	and	#IEQUALIFIER_LSHIFT!IEQUALIFIER_CONTROL!IEQUALIFIER_LCOMMAND,d0
	cmp	#IEQUALIFIER_LSHIFT!IEQUALIFIER_CONTROL!IEQUALIFIER_LCOMMAND,d0
	bne.b	.cont
	move	ie_Code(a0),d0			* rawkoodi
	tst.b	d0
	bmi.b	.cont				* vain jos nappula alhaalla
	clr.b	ie_Class(a0)			* ieclass_null (syodaan pois)
	move	d0,rawkeyinput(a1)		* a1 = var_b
	pushm	d1/a6
	move.b	rawKeySignal(a1),d1
	jsr	signalit
	popm	d1/a6
	bra.b	.exhand
	
.cont	
	;move.l	ie_NextEvent(a0),d0		* seuraava
	move.l	(a0),d0		* ie_NextEvent = 0
	move.l	d0,a0
	bne.b	.handlerloop
.exhand	
	pop	a0
.quit	move.l	a0,d0
	rts



*******
* Printti rutiini
* Text printing. Variants for different target windows.
* Supports line changes.
*******

* sPrint = Info-ikkunaan
sprint  pushm	all
	add	windowleft(a5),d0
	add	windowtop(a5),d1	* suhteutetaan palkin fonttiin
	move.l	srastport(a5),a4
	bra.b	doPrint	


* Print3 = Prefs-ikkunaan
print3	pushm	all
	add	windowleft(a5),d0
	add	windowtop(a5),d1	* suhteutetaan palkin fonttiin
	move.l	rastport2(a5),a4
	bra.b	doPrint	

* Print to mainwindow with bold font style.
printBold
	pushm	d0-d2/a0-a2/a6
	move.l	rastport(a5),a1
	moveq	#FSF_BOLD,d0	* enable bold bit
	moveq	#FSF_BOLD,d1	* mask of bits to change
	lore	GFX,SetSoftStyle
	popm	d0-d2/a0-a2/a6
	bsr.b	print
	move.l	rastport(a5),a1
	moveq	#0,d0		* disable bold bit
	moveq	#FSF_BOLD,d1	* mask of bits to change
	lore	GFX,SetSoftStyle
	 
	rts

* P‰‰ikkunaan
* d0/d1 = x,y
* a0 = teksti
print:
	add	windowleft(a5),d0
	add	windowtop(a5),d1	* suhteutetaan palkin fonttiin
	tst.b	win(a5)		* onko ikkunaa?
	beq.b	.r
	tst.b	kokolippu(a5)	* ei tulosteta, jos ikkuna pienen‰
	bne.b	.e
.r	rts
.e
	pushm	all
	move.l	rastport(a5),a4
;uup
doPrint:

	move.l	_GFXBase(a5),a6
	move.l	a0,a2

	move	d0,d4
	move	d1,d5
.luup	
	move	d4,d0
	move	d5,d1

	move.l	a4,a1
	lob	Move			* move drawing point
	move.l	a4,a1
	move.l	a2,a0

	moveq	#0,d7
	moveq	#0,d0
.plah	addq	#1,d0	* find out number of chars to output
	tst.b	(a2)
	beq.b	.pog
	cmp.b	#10,(a2)+	* check for line changes
	bne.b	.plah
	moveq	#1,d7
.pog
	subq	#1,d0
	lob	Text

	tst	d7
	beq.b	.x
;	addq	#8,d5		* next vertical line
	move.l	rp_Font(a4),a0
	add	tf_YSize(a0),d5
	bra.b	.luup		

.x	popm	all
	rts

*** A0:sta 4 ascii-kirjainta D0:aan 
kirjainta4
	move.b	(a0)+,d0
	beq.b	.x
	lsl.l	#8,d0
	move.b	(a0)+,d0
	beq.b	.x
	lsl.l	#8,d0
	move.b	(a0)+,d0
	beq.b	.x
	lsl.l	#8,d0
	move.b	(a0),d0
.x	and.l	#$dfdfdfdf,d0		* muunnetaan isoiksi
	rts



******************************************************************************
* Avaa ikkunan ja pikkasen alustaakin
*******

handleSignal2
;	DPRINT	"Signal 2"

	* Update title bar with position information
	jsr	lootaan_pos

	* see if prefs window was just closed
	tst.b	prefsexit(a5)
	beq.b	.noe
	clr.b	prefsexit(a5)

	* Do this to update favorite status if settings changed
	jsr	handleFavoriteModuleConfigChange

	* Check if boxsize in prefs was changed
	move	boxsize(a5),d0		* onko boxin koko vaihtunut??
	cmp	boxsize0(a5),d0
	bne.b	.noe
	* Do a content refresh is box size not changed. Not sure why
	jsr	forceRefreshList
.noe
	* Prefs exit check done

	* Check if window width changed
	move.l	windowbase(a5),a0

	move	wd_Width(a0),d0
	cmp	previousWindowWidth(a5),d0
	beq.b	.sameWidth
	* Store as the new width
	;move	d0,wsizex
	move	d0,WINSIZX(a5)
	move	d0,previousWindowWidth(a5)
	* Force reopen window
	move	#-1,boxsize0(a5)
 if DEBUG
	ext.l	d0
	DPRINT	"width changed to %ld"
 endif
.sameWidth

** ei saa r‰mp‰t‰ ikkunaa jos se ei oo oikeassa koossaan!!

	moveq	#0,d7
	move	boxsize(a5),d0		* onko boxin koko vaihtunut??
	cmp	boxsize0(a5),d0
	beq.b	.boxSizeNotChanged
	
 if DEBUG
 	ext.l	d0
 	moveq	#0,d1
 	move	boxsize0(a5),d1
	DPRINT	"Boxsize changed to %ld from %ld"
 endif
 
	move	d0,boxsize0(a5)
	bsr.w	setboxy
	moveq	#1,d7

	push	d7
	bsr.w	.closeAndReopenWindow
	pop	d7
	tst.l	d0
	bne.w	.error
	move	boxsize(a5),boxsize0(a5)
	bra.b	.boxSizeChanged

.boxSizeNotChanged
	* Ensures the refresh gadget looks correct
	* after user releases it and window is not reopened
	bsr	refreshResizeGadget

	* Check if height changed
	move	wd_Height(a0),d0
	cmp	previousWindowHeight(a5),d0
	beq.b	.sameHeight
	* Change the window size back
	moveq	#0,d0 ; deltaX
	move	previousWindowHeight(a5),d1
	sub	wd_Height(a0),d1 ; deltaY
	bmi.b	.neg
	* ensure negative change to not go over screen,
	* kick1.3 does not do sanity checks
	sub	listFontHeight(a5),d1
.neg	
	DPRINT	"restore height"
	lore	Intui,SizeWindow
.sameHeight
.boxSizeChanged

** ei saa r‰mp‰t‰ ikkunaa jos se ei oo oikeassa koossaan!!

	tst.b	newpubscreen(a5)	* Valittiinko prefsista uusi
	beq.b	.noewp			* pubscreeni?
	clr.b	newpubscreen(a5)	* siirret‰‰n ikkunat sinne

	bsr.b	.closeAndReopenWindow
	bne.b	.error

	; Also move scope windows to the new screen
	jsr	stopScopeTasks
	jsr	startAndStopScopeTasks

	; And the info window
	tst	info_prosessi(a5)
	beq.b	.return
	jsr	sulje_info
	move.b	oli_infoa(a5),d0
	st	oli_infoa(a5)
	push	d0
	jsr	start_info
	pop	d0
	move.b	d0,oli_infoa(a5)
.return
	moveq	#1,d0
	rts
;;	bra.w	returnmsg

.noewp	
	move.l	d7,d0
	rts

.closeAndReopenWindow
	* Is a window open? If not, just open
	tst.b	win(a5)
	beq.b	.av2
	* Window was open. Small or big?
	tst.b	kokolippu(a5)
	bne.b	.iso2
	* Small, close
	bsr.w	sulje_ikkuna
	clr.b	win(a5)
.av2	
	* Just open, a different method?
	bsr.b	openw
	bne.b	.error
	rts
.iso2
	* This closes and reopens the window
	bsr.w	avaa_ikkuna2
	bne.b	.error
.bar2

	rts

.error
	moveq	#-1,d0
	rts


openw:
	tst.b	win(a5)
	bne.b	.x
	st	win(a5)
	clr.b	kokolippu(a5)		* pieni -> iso
	bsr.w	avaa_ikkuna
	bne.b	.x
	jsr	whatgadgets2
	moveq	#0,d0
.x	rts


plx1	equr	d4
ply1	equr	d5
plx2	equr	d6
ply2	equr	d7

*** Painettiin Zoom-gadgettia

*** P‰ivitet‰‰n ikkunan sis‰ltˆ

zipwindow:
	DPRINT	"ZipWindow refresh"
	tst.b	win(a5)
	bne.b	.onw	
	rts
.onw
	pushm	all
	move.l	windowbase(a5),a0
	move	wd_Height(a0),d0
 if DEBUG
 	ext.l	d0
 	moveq	#0,d1
 	move	windowZippedSize+2(a5),d1
	DPRINT	"height=%ld zipped=%ld"
 endif
	cmp	windowZippedSize+2(a5),d0
	bne.b	.biggified

	* Zipped to small size
	tst.b	kokolippu(a5)
	beq.b	.x * Safety: already small?
	clr.b	kokolippu(a5)
	* Store zipped position 
	move.l	4(a0),windowZippedPos(a5)
** pieni ikkuna!
	;move.l	windowbase(a5),a0
	lea	gadgets,a1
	moveq	#-1,d0
	moveq	#-1,d1
	sub.l	a2,a2
	lore	Intui,RemoveGList
	DPRINT	"small"
	bra.b	.x

.biggified
	tst.b	kokolippu(a5)
	bne.b	.x * Already big?
	st	kokolippu(a5)
	DPRINT	"big"
	* Store window position
	move.l	4(a0),windowpos(a5)
	bsr.w	wrender

.x	popm	all
	rts


* Close and reopen window
avaa_ikkuna2:
	bsr.w	sulje_ikkuna
	not.b	kokolippu(a5)
	
* Open window
avaa_ikkuna:
	DPRINT	"Open window"
	bsr.w	getscreeninfo
	bne.w	.opener

	; Button config, may adjust WINSIZY
	jsr	configureMainWindowButtonSizes
	; Update into window structure

	lea	winstruc,a0
	basereg	winstruc,a0

	move	WINSIZX(a5),wsizex(a0)
	move	WINSIZY(a5),wsizey(a0)
	tst	winstruc+nw_MaxWidth(a0)
	bne.b	.set
	move	WINSIZX(a5),d0
	move	d0,winstruc+nw_MinWidth(a0)
	add	d0,d0
	move	d0,winstruc+nw_MaxWidth(a0)
.set
	endb	a0

	move.l	_IntuiBase(a5),a6

	move.l	windowZippedPos(a5),(a0)	* Pienen paikka ja koko
	moveq	#11,d0
	tst.b	uusikick(a5)
	bne.b	.new1
	moveq	#10,d0				* kick1.3
.new1	add	windowtop(a5),d0
	move	d0,wsizey-winstruc(a0)
	bsr.w	.leve

	* What is this?
	not.b	kokolippu(a5)
	beq.b	.small

	basereg	winstruc,a0
	move	#7,slimheight(a0)	* slideri pieneks, jotta ei tuu sotkuja
	endb	a0

	move	WINSIZY(a5),d0
	add	boxy(a5),d0
	add	windowtop(a5),d0
	move	d0,wsizey-winstruc(a0)	* Ison koko ja paikka
	move.l	windowpos(a5),(a0)
	bsr.w	.leve

	move	wbkorkeus(a5),d6	* Mahtuuko ruudulle pystysuunnassa?
	sub	WINSIZY(a5),d6
	sub	windowtop(a5),d6
.uudest
	move	d6,d0
	sub	boxy(a5),d0		* mahtuuko fileboxi?
	bmi.b	.negatiivi

	cmp	2(a0),d0
	bge.b	.okkk
	move	d0,2(a0)
	bra.b	.okkk

.negatiivi
	subq	#1,boxsize(a5)		* Pienennet‰‰n fileboksia..
	subq	#1,boxsize0(a5)
	bsr.w	setboxy
	move	d6,d0
	sub	boxy(a5),d0
	bmi.b	.negatiivi
	move	WINSIZY(a5),d0
	add	windowtop(a5),d0
	add	boxy(a5),d0
	move	d0,wsizey-winstruc(a0)	* Ison koko ja paikka
	bra.b	.uudest
.okkk

.small	

	lea	slider4,a3		* fileboxin slideri
	moveq	#gadgetFileSliderInitialHeight,d3	* y-koko
	and	#~$80,gg_TopEdge(a3)
	add	boxy(a5),d3
	bpl.b	.r
	or	#$80,gg_TopEdge(a3)
	clr	d3
.r	move	d3,gg_Height(a3)


;	tst.b	uusikick(a5)
;	beq.b	.ded
	subq	#3,gg_Height(a3)
;.ded
	basereg	slider4,a3

	* Remove the fileslider from the gadget list
	* if it is not visible. On kick13 there may be
	* some gfx trash otherwise.
	* Normal chain:
	;move.l	#slider4,slider1+gg_NextGadget(a3)
	move.l	a3,slider1+gg_NextGadget(a3)
	tst	boxsize(a5)
	bne.b	.isBox
	* Skip over slider4
	;move.l	#button12,slider1+gg_NextGadget(a3)
	pushpea	button12(a3),slider1+gg_NextGadget(a3)
.isBox
	endb	a3
	
	lob	OpenWindow
	move.l	d0,windowbase(a5)
	bne.b	.ok
	bsr.w	unlockscreen

.opener	moveq	#-1,d0			* Ei auennut!
	rts

.leve	move	wbleveys(a5),d0		* WB:n leveys
	move	(a0),d1			* Ikkunan x-paikka
	add	4(a0),d1		* Ikkunan oikea laita
	cmp	d0,d1
	bls.b	.okk
	sub	4(a0),d0	* Jos ei mahdu ruudulle, laitetaan
	move	d0,(a0)		* mahdollisimman oikealle
.okk	rts

.ok
	move.l	d0,a0
	move.l	wd_RPort(a0),rastport(a5)
	move.l	wd_UserPort(a0),userport(a5)
	;move	wd_Height(a0),wkork(a5)

 if DEBUG
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	move	wd_LeftEdge(a0),d0
	move	wd_TopEdge(a0),d1
	move	wd_Width(a0),d2
	move	wd_Height(a0),d3
	DPRINT	"Open window pos=%ldx%ld size=%ldx%ld"
 endif
	move.l	rastport(a5),a1
	move.l	fontbase(a5),a0
	lore	GFX,SetFont	

	tst.b	uusikick(a5)	* jos kickstart 2.0+, pistet‰‰n ikkuna
	beq.b	.elderly	* appwindowiksi.

	moveq	#0,d0		* ID
	move.l	#"AppW",d1	* userdata
	move.l	windowbase(a5),a0
	lea	hippoport(a5),a1 * msgport
	sub.l	a2,a2		* null
	lore	WB,AddAppWindowA
	move.l	d0,appwindow(a5)
.elderly
	jsr	createlistBoxRegion

	; Store this for detecting height changes after window opened
	move	winstruc+nw_Height,previousWindowHeight(a5)

	bsr.w	wrender
	moveq	#0,d0
	rts





getscreeninfo
	st	gotscreeninfo(a5)

*** Selvitet‰‰n ikkunan n‰ytˆn ominaisuudet
*** Uusi kick 
	tst.b	uusikick(a5)
	beq.w	.olde

	lea	pubscreen(a5),a0
	lore	Intui,LockPubScreen
	move.l	d0,screenlock(a5)
	bne.b	.ok1
	sub.l	a0,a0
	lob	LockPubScreen
	move.l	d0,screenlock(a5)
	beq.w	.opener
.ok1
	move.l	d0,a0

	move.l	d0,screenaddr(a5)
	move	sc_Width(a0),wbleveys(a5)	* N‰ytˆn leveys
	move	sc_Height(a0),wbkorkeus(a5)	* N‰ytˆn korkeus
	clr	windowtop(a5)
	clr	windowtopb(a5)
	clr	windowbottom(a5)
	clr	windowleft(a5)
	clr	windowright(a5)
	move.b	sc_BarHeight(a0),windowtop+1(a5) * Palkin korkeus
	move.b	sc_WBorBottom(a0),windowbottom+1(a5)
	move.b	sc_WBorTop(a0),windowtopb+1(a5)
	move.b	sc_WBorLeft(a0),windowleft+1(a5)
	move.b	sc_WBorRight(a0),windowright+1(a5)

	move.l 	sc_Font(a0),a1  * TextAttr, screen font
	moveq	#0,d3
	move	ta_YSize(a1),d3

 if DEBUG
	moveq	#0,d0
	move.b	sc_BarHeight(a0),d0
	moveq	#0,d1
	move.b	sc_BarVBorder(a0),d1
	move.l	d3,d2
	DPRINT	"sc_BarHeight=%ld sc_BarVBorder=%ld fontY=%ld"
	moveq	#0,d0
	move.b	sc_WBorTop(a0),d0
	moveq	#0,d1
	move.b	sc_WBorBottom(a0),d1
	DPRINT	"sc_WBorTop=%ld sc_WBorBottom=%ld"
 endif

	* It seems that the total height of the window
	* border must be calculated using the screen font height
	* and adding some safety margin.
	* Screen bar height can't be used to calculate window
	* title bar height since that can configured separately.
	addq	#2,d3
	move	d3,windowtop(a5)
 

* Screen Border = 0 + Window Border = 0, font 13
* - sc_BarHeight= 15
* - sc_WBorTop = 2
* - ta_YSize = 13

* Screen Border = 0 + Window Border = 0, font 8
* - sc_BarHeight= 10
* - sc_WBorTop = 2
* - ta_YSize = 8

* Screen Border = 0 + Window Border = 0 + font 24
* - sc_BarHeight= 26
* - sc_WBorTop = 2
* - ta_YSize = 24

* Screen Border = 8 + Window Border = 0 + font 13
* - sc_BarHeight= 23
* - sc_WBorTop = 2
* - ta_YSize = 13

* Screen Border = 8 + Window Border = 0 + font 8
* - sc_BarHeight= 18
* - sc_WBorTop = 2
* - ta_YSize = 8

* Screen Border = 0 + Window Border = 8 + font 13
* - sc_BarHeight= 15
* - sc_WBorTop = 10
* - ta_YSize = 13


	move	windowtopb(a5),d0
	add	d0,windowtop(a5)

	subq	#4,windowleft(a5)		* saattaa menn‰ negatiiviseksi
	subq	#4,windowright(a5)
	subq	#2,windowtop(a5)
	subq	#2,windowbottom(a5)

;	subq	#4,windowleft(a5)
;	subq	#4,windowright(a5)
;	subq	#2,windowbottom(a5)


** Tutkaillaan n‰ytˆn tyyppi‰!
* Talteen oikea hz scopeja varten


	lea	sc_ViewPort(a0),a2
	move.l	a2,a0
	lore	GFX,GetVPModeID
	and.l	#$40000000,d0		* onko native amiga screeni?
	beq.b	.nogfxcard
	st	gfxcard(a5)
	bra.w	.ba	
.nogfxcard


;	lea	sc_ViewPort(a0),a0	* viewport
	move.l	a2,a0
	move.l	vp_ColorMap(a0),a0	* colormap
	move.l	cm_VPModeID(a0),d0	* handle

	lob	FindDisplayInfo
	move.l	d0,d4
	beq.b	.ba

	lea	-40(sp),sp
	move.l	sp,a4

	moveq	#0,d5
	moveq	#0,d6
	moveq	#0,d7

	move.l	#DTAG_DISP,d1
	bsr.b	.pa
	move	dis_PixelSpeed(a4),d5

	move.l	#DTAG_MNTR,d1
	bsr.b	.pa
	move	mtr_TotalRows(a4),d6	
	move	mtr_TotalColorClocks(a4),d7

	lea	40(sp),sp

	move.l	#1000000000,d0
;	divu.l	d5,d0		* pixelclock in Hz
	move.l	d5,d1
	bsr.w	divu_32
	
	move.l	#280,d1
	divu	d5,d1		* pixelclocks/280ns colorclock
	mulu	d7,d1		* pixelclocks per line
	
;	divu.l	d1,d0		* linefrequency in Hz
	bsr.w	divu_32

	move.l	d0,d1
	divu	d6,d1		* vertical frequency

	move	d0,horizfreq(a5)
	move	d1,vertfreq(a5)

	move.l	clockconstant(a5),d0
	ext.l	d1
	bsr.w	divu_32
	move.l	d0,colordiv(a5)
	bra.b	.ba

.pa	move.l	d4,a0
	moveq	#0,d2
	move.l	a4,a1
	moveq	#40,d0		* buf size
	jmp	_LVOGetDisplayInfoData(a6)
;	rts

.ba


;******************************* Piirtokynien selvitys

;	move.l	(a5),a1
;	cmp	#39,LIB_VERSION(a1)
;	blo.w	.kick2

;	move.l	screenaddr(a5),a0
;	lea	sc_ViewPort(a0),a3
;	move.l	vp_ColorMap(a3),a3	* ColorMappi

;	move.l	#$a0000000,d1
;	move.l	d1,d2
;	move.l	d1,d3
;	move.l	a3,a0
;	lea	.tags(pc),a1
;	lore	GFX,ObtainBestPenA
;	move.l	d0,pen_0(a5)

;	moveq	#0,d1
;	moveq	#0,d2
;	moveq	#0,d3
;	move.l	a3,a0
;	lea	.tags(pc),a1
;	lob	ObtainBestPenA
;	move.l	d0,pen_1(a5)

;	moveq	#0,d1
;	moveq	#0,d2
;	moveq	#0,d3
;	move.l	a3,a0
;	lea	.tags(pc),a1
;	lob	ObtainBestPenA
;	move.l	d0,pen_1(a5)

;	move.l	#$f0000000,d1
;	move.l	d1,d2
;	move.l	d1,d3
;	move.l	a3,a0
;	lea	.tags(pc),a1
;	lob	ObtainBestPenA
;	move.l	d0,pen_2(a5)

;	move.l	#$60000000,d1
;	move.l	#$80000000,d2
;	move.l	#$B0000000,d3
;	move.l	a3,a0
;	lea	.tags(pc),a1
;	lob	ObtainBestPenA
;	move.l	d0,pen_3(a5)

;	bra.b	.kick2

;.tags
;	dc.l	OBP_Precision,PRECISION_GUI
;	dc.l	TAG_END

;.kick2


	sub	#10,windowtop(a5)
	;bpl.b	.olde
	;clr	windowtop(a5)
	
*** S‰‰det‰‰n ikkunat ja gadgetit otsikkopalkin koon mukaan

.olde
	; This does some magic that is needed for the layout.
	; Otherwise after zip window layout will start to break
	move	windowtop(a5),d0
	move	windowtop2(a5),d1
	move	d0,windowtop2(a5)
	sub	d1,d0			* ERO!

* nw_TopEdge = 2
* nw_Width   = 4
* nw_Height  = 6

	lea	winstruc,a0
	basereg	winstruc,a0

	add	d0,winstruc+nw_Height(a0)		* suhteutetaan koot fonttiin
	add	d0,winstruc2+nw_Height(a0)
	add	d0,winstruc3+nw_Height(a0)
	add	d0,swinstruc+nw_Height(a0)
	add	d0,windowZippedSize+2(a5)	* pienen ikkunan zip-koko

	move	windowleft(a5),d1
	move	windowleft2(a5),d2
	move	d1,windowleft2(a5)
	sub	d2,d1
	add	d1,winstruc+nw_Width(a0)
	add	d1,winstruc2+nw_Width(a0)
	add	d1,winstruc3+nw_Width(a0)
	add	d1,swinstruc+nw_Width(a0)

	add	d1,WINSIZX(a5)

	move	windowbottom(a5),d3
	move	windowbottom2(a5),d4
	move	d3,windowbottom2(a5)
	sub	d4,d3
	add	d3,WINSIZY(a5)
	add	d3,prefssiz+2(a0)
	add	d3,quadsiz+2(a0)
	add	d3,swinsiz+2(a0)

	tst	quadWindowHeightOriginal(a5)
	bne.b	.setAlready
	move	quadsiz+2,quadWindowHeightOriginal(a5)
	sub	#SCOPE_DRAW_AREA_HEIGHT_DEFAULT,quadWindowHeightOriginal(a5)
.setAlready

	* Store new window size
	move	WINSIZX(a5),wsizex(a0)
	move	WINSIZY(a5),wsizey(a0)
	move	WINSIZX(a5),previousWindowWidth(a5)

	endb	a0

	lea	gadgets,a0
	bsr.b	.hum
	lea	gadgets2-gadgets(a0),a0
	bsr.b	.hum
	lea	gAD1-gadgets2(a0),a0
	bsr.b	.hum
	lea	sivu0-gAD1(a0),a0
	bsr.b	.hum
	lea	sivu1-sivu0(a0),a0
	bsr.b	.hum
	lea	sivu2-sivu1(a0),a0
	bsr.b	.hum
	lea	sivu3-sivu2(a0),a0
	bsr.b	.hum
	lea	sivu4-sivu3(a0),a0
	bsr.b	.hum
	lea	sivu5-sivu4(a0),a0
	bsr.b	.hum
	lea	sivu6-sivu5(a0),a0
	bsr.b	.hum


	bsr.w	unlockscreen
	moveq	#0,d0
	rts
.opener	moveq	#-1,d0
	rts


.hum
	move.l	a0,a1
.lop0	add	d0,6(a1)
	add	d1,4(a1)
	tst.l	(a1)
	beq.b	.e0
	move.l	(a1),a1
	bra.b	.lop0
.e0	rts


	


****** Piirret‰‰n ikkunan kamat

wrender:
 ifne FEATURE_HORIZ_RESIZE
 	jsr	layoutButtonRow
 endif

	move.l	pen_0(a5),d0
	move.l	rastport(a5),a1
	lore	GFX,SetBPen

	lea	gadgets,a4

	tst.b	kokolippu(a5)
	beq.w	.pienehko


	move.l	rastport(a5),a2
	moveq	#4,d0
	moveq	#11,d1
;	move	#259,d2
	move	WINSIZX(a5),d2
	subq	#6,d2
	move	WINSIZY(a5),d3
	subq	#3,d3
	add	boxy(a5),d3
	sub	windowbottom(a5),d3
	bsr.w	drawtexture


* tyhjennet‰‰n...
* laatikoitten alueet

;	lea	gadgets,a3
;	move.l	a3,a4
	move.l	a4,a3
.clrloop
	move.l	(a3),d7
	movem	4(a3),d0/d1/d4/d5	* putsataan gadgetin alue..
	bsr.b	.cler
	move.l	d7,a3
	tst.l	d7
	bne.b	.clrloop
	bra.b	.oru

.cler	
	; This one is invisible, skip it, though
	; its not in the list at this point anyway?
	cmp.l	#gadgetResize,a3
	beq.b	.skipClear

	tst	boxsize(a5)
	bne.b	.clef
	* Box is minimized, skipped gadgets:
	cmp.l	#gadgetListModeChangeButton,a3
	beq.b	.skipClear
	cmp.l	#slider4,a3		* fileslider
	bne.b	.clef
.skipClear
	rts	
.clef
	move.l	rastport(a5),a0
	move.l	a0,a1
	move	d0,d2
	move	d1,d3
	moveq	#$0a,d6
	move.l	_GFXBase(a5),a6
	jmp	_LVOClipBlit(a6)
.oru
;.vanaha

	* Insert an invisible size gadget last
	bsr.w	configResizeGadget


* sitten isket‰‰n gadgetit ikkunaan..
	move.l	windowbase(a5),a0
	move.l	a4,a1
	moveq	#-1,d0
	moveq	#-1,d1
	sub.l	a2,a2
	lore	Intui,AddGList
	
	move.l	a4,a0
	move.l	windowbase(a5),a1
	sub.l	a2,a2
	lob	RefreshGadgets

	tst.b	uusikick(a5)
	bne.b	.newK
	; Seems an extra refresh is needed here to get bg correct
	lea	slider1,a0
	bsr	refreshGadgetInA0
.newK

**** paksunnetaan gadujen reunat

* Draw button highlights

	lea	(a4),a3
.loloop
	move.l	(a3),d3

	tst	boxsize(a5)
	bne.b	.visibleBox
	* Skip this one if it is not properly visible
	cmp.l	#gadgetListModeChangeButton,a3
	beq.b	.nel
.visibleBox
	jsr	drawButtonFrameMainWindow
.nel
	move.l	d3,a3
	tst.l	d3
	bne.b	.loloop

* Draw slider highlights

;	tst.b	uusikick(a5)
;	beq.b	.nelq

	tst	boxsize(a5)
	beq.b	.nofs

	movem	slider4+4,plx1/ply1/plx2/ply2	* fileslider
	add	plx1,plx2
	add	ply1,ply2
	subq	#2,plx1
	addq	#1,plx2
	subq	#2,ply1
	addq	#1,ply2
	move.l	rastport(a5),a1
	bsr.w	sliderlaatikko
.nofs
	movem	slider1+4,plx1/ply1/plx2/ply2	* volumeslider
	add	plx1,plx2
	add	ply1,ply2
	subq	#2,plx1
	addq	#1,plx2
	subq	#2,ply1
	addq	#1,ply2
	move.l	rastport(a5),a1
	bsr.w	sliderlaatikko

;.nelq

*** Piirret‰‰n korvat
	pushm	all
	lea	button7,a0		* Add
	bsr.w	printkorva
	lea	lilb1-button7(a0),a0	* M
	bsr.w	printkorva
	lea	lilb2-lilb1(a0),a0	* S
	bsr.w	printkorva
	lea	kela2-lilb2(a0),a0	* >, forward
	bsr.w	printkorva
	lea	plg-kela2(a0),a0	* Prg
	bsr.w	printkorva
	lea	button8-plg(a0),a0	* Del
	bsr.w	printkorva
	lea	button2-button8(a0),a0	* i
	bsr.w	printkorva
	lea	button11-button2(a0),a0	* new
	bsr.w	printkorva
	lea	button20-button11(a0),a0 * pr
	bsr.w	printkorva
	lea	button1-button20(a0),a0 * play
	bsr.w	printkorva


 ifd abda

*** Piirret‰‰n 'underlinet'


	move.l	pen_1(a5),d0
	move.l	rastport(a5),a1
	lore	GFX,SetAPen

	lea	button11+4,a3

	movem	(a3),d0/d1
	bsr.b	.dru

	movem	button7-button11(a3),d0/d1
	bsr.b	.dru

	movem	button8-button11(a3),d0/d1
	bsr.b	.dru

	movem	plg-button11(a3),d0/d1
	bsr.b	.dru

	movem	lilb1-button11(a3),d0/d1
	subq	#1,d0
	bsr.b	.dru

	movem	lilb2-button11(a3),d0/d1
	subq	#1,d0
	bsr.b	.dru

	movem	button20-button11(a3),d0/d1
	addq	#6,d0
	bsr.b	.dru
	bra.b	.dru0

.dru
	addq	#4,d0
	add	#11,d1

	movem	d0/d1,-(sp)
	move.l	rastport(a5),a1
	lore	GFX,Move
	movem	(sp)+,d0/d1
	addq	#6,d0
	move.l	rastport(a5),a1
	jmp	_LVODraw(a6)

.dru0
 endc



	popm	all


	bsr.w	inforivit_clear


	tst	boxsize(a5)		* filebox
	beq.b	.b
	moveq	#28+WINX,plx1
;	move	#253+WINX,plx2
	move	WINSIZX(a5),plx2
	subq	#8,plx2

	moveq	#61+WINY,ply1
	move	#128+WINY,ply2
 	tst.b	altbuttonsUse(a5)
	beq.b	.noAlt1
 	add	#16,ply1
	add	#16,ply2
.noAlt1

	add	windowleft(a5),plx1
	add	windowleft(a5),plx2
	add	boxy(a5),ply2
	add	windowtop(a5),ply1
	add	windowtop(a5),ply2
	move.l	rastport(a5),a1
	bsr.w	laatikko1
.b
	moveq	#5+WINX,plx1		* infobox
	;move	#254+WINX,plx2
	move	WINSIZX(a5),plx2
	subq	#8,plx2

	moveq	#10+WINY,ply1
	moveq	#29+WINY,ply2
	add	windowleft(a5),plx1
	add	windowleft(a5),plx2
	add	windowtop(a5),ply1
	add	windowtop(a5),ply2
	move.l	rastport(a5),a1
	bsr.w	laatikko2



	tst.l	playingmodule(a5)
	bmi.b	.npl
	bsr.w	inforivit_play

	tst.b	playing(a5)
	bne.b	.npl
	bsr.w	inforivit_pause

.npl	st	hippoonbox(a5)
	bsr.w	shownames


.pienehko
	st	lootassa(a5)
	clr.b	wintitl2(a5)
	bsr.w	lootaa
	bsr.w	reslider

	DPRINT	"wrender done"

	move.l	windowbase(a5),a0
	bsr.w	setscrtitle
	move.l	keycheckroutine(a5),-(sp)
	rts


	
* Calculate y-offset related to boxsize value
* Used in placing gfx into the main window.
setboxy:
	move	boxsize(a5),d0
	* original "default" size was 8, so it is relative to that.
	subq	#8,d0
	;muls	#8,d0
	muls	listFontHeight(a5),d0

	* All y-calculations assume that boxy(a5) includes 
	* in it 8 rows of list box lines with 8-pixel tall font.
	* Need to adjust accordingly here.
	move	listFontHeight(a5),d1
	subq	#8,d1	* difference to reference font height 8
	asl	#3,d1
	add	d1,d0

	tst	boxsize(a5)
	bne.b	.x
	subq	#6,d0

.x	move	d0,boxy(a5)
 if DEBUG
 	ext.l	d0
 	moveq	#0,d1
 	move	boxsize(a5),d1
 	moveq	#0,d2
 	move	listFontHeight(a5),d2
 	DPRINT	"boxy=%ld boxsize=%ld fontheight=%ld"
 endif
	rts

* Set font to be used for the list. Also 
* calculates the y-offset magic for gfx placement
* which is relative to the font.
* in:
*   a0 = font to set for the list
setListFont
	move.l	a0,listfontbase(a5)
	; Dig height for this since it is used widely
	move	tf_YSize(a0),listFontHeight(a5)	
	bsr.b	setboxy
	rts


front	pushm	all
	move.l	windowbase(a5),d7
	beq.b	.q
.a	move.l	d7,a0
	lore	Intui,WindowToFront
	move.l	d7,a0
	lob	ActivateWindow
	move.l	d7,a0
	bsr.w	get_rt
	move.l	wd_WScreen(a0),a0
	lob	rtScreenToFrontSafely
.qq	popm	all
	rts

.q	bsr.w	avaa_ikkuna2	
	move.l	windowbase(a5),d7
	bne.b	.a
	bra.b	.qq

unlockscreen
	tst.b	uusikick(a5)
	beq.b	.q
	move.l	screenlock(a5),a1
	sub.l	a0,a0
	lore	Intui,UnlockPubScreen
.q	rts


* Called upon IDCMP_NEWSIZE after the user dragged the
* window size gadget. Filebox size is set accoring to window height.
mainWindowSizeChanged
	move.l	windowbase(a5),a0
	tst.b	kokolippu(a5)
	bne.b	.z
	* Store zipped position so it will be saved with prefs
	movem	4(a0),d0/d1
	DPRINT	"zipped move to %ldx%ld"
	movem	d0/d1,windowZippedPos(a5)
.z
	tst.b	win(a5)
	bne.b	.y
.x 	DPRINT	"bail out"
	rts
.y
 if DEBUG
	movem	wd_Width(a0),d0/d1
	movem	winstruc+nw_Width,d2/d3
	DPRINT	"size change to %ldx%ld (orig %ldx%ld)"
 endif
	bsr.w	getFileboxYStartToD2
	move	wd_Height(a0),d0

	* account for bottom border
	subq	#6,d0
	sub	windowbottom(a5),d0

	sub	d2,d0
	bmi.b	.x
	* Divide to font height pixel rows
	;lsr	#3,d0
	ext.l	d0
	divu	listFontHeight(a5),d0

	* Store new box size
	move	d0,boxsize(a5)
	
 if DEBUG
 	ext.l	d0
	DPRINT	"boxsize=%ld"
 endif

	* Set new boxsize into prefs gadget
	bsr.w	setprefsbox

	* Signal to make changes happen
	move.b	ownsignal2(a5),d1
	jsr	signalit	
	* Also update prefs window box size value.
	* This doesn't actually update the propgadget position, 
	* ah well.
	bra.w	updateprefs

* Disables the low right bottom resize gadget by making it 0 pixel wide
disableResizeGadget
	* Hide and disable
	lea	gadgetResize,a1
	clr	gg_Width(a1)
	or	#GFLG_DISABLED,gg_Flags(a1)
	rts


* Enables or disables the resize gadget
configResizeGadget
	bsr.b	disableResizeGadget
	* Check if box is visible?
	tst	boxsize(a5)
	beq.b	enableResizeGadget\.small

* Enables the low right bottom resize gadget, on kick2.0+ only,
* where GTYP_SIZING is available.
enableResizeGadget
	lea	gadgetResize,a1
	move.l	windowbase(a5),a0
	* Height is a bit larger than the window bottom border
	moveq	#0,d0
	move.b	wd_BorderBottom(a0),d0
	addq	#3,d0
	;move	d0,gg_Height(a1)

	* Position at the bottom of the window
;	subq	#2,d0
	neg	d0
	move	d0,gg_TopEdge(a1)

	* Enable and unhide
	and	#~GFLG_DISABLED,gg_Flags(a1)
	move	#6,gg_Width(a1)

	* Set wd_MinSize to correspond to 3 rows
	bsr.b	getFileboxYStartToD2
;	add	#3*8+6,d2
	moveq	#3,d0
	mulu	listFontHeight(a5),d0
	* some additional adjustment: bottom border?
	addq	#6,d0
	add	windowbottom(a5),d0

	add	d0,d2
	move	d2,wd_MinHeight(a0)

	* Max size too, 47 lines down, total 50
	moveq	#50-3,d0
	mulu	listFontHeight(a5),d0
	add	d0,d2

	move	d2,wd_MaxHeight(a0)


 if DEBUG
	moveq	#0,d0
	move	wd_MinHeight(a0),d0
	moveq	#0,d1
	move	wd_MaxHeight(a0),d1
	DPRINT	"wd_MinHeight=%ld wd_MaxHeight=%ld"
 endif

.old
.small
	rts

* Refresh the resize gadget if possible
refreshResizeGadget
	tst.b	uusikick(a5)
	beq.b	.x
	push	a0
	lea	gadgetResize,a0
	bsr.w	refreshGadgetInA0
	pop	a0
.x	rts

* Calculate the start y-position of the filebox 
getFileboxYStartToD2
	moveq	#62+WINY,d2
	tst.b	altbuttonsUse(a5)
	beq.b	.noAlt
	add	#16,d2
.noAlt
	add	windowtop(a5),d2
	rts
	
*******************************************************************************
* Asettaa ikkunan screentitlen
* a0 = windowbase
setscrtitle
	pushm	d0/d1/a0/a1/a6
	lea	-1.w,a1
	lea	scrtit(pc),a2
	lore	Intui,SetWindowTitles
	popm	d0/d1/a0/a1/a6
	rts



*******************************************************************************
* Sulkee ikkunan
*******
sulje_ikkuna
	tst.b	win(a5)
	bne.b	.x
.uh	rts
.x	
	bsr.w	flush_messages
	
	move.l	appwindow(a5),d0
	beq.b	.noapp
	move.l	d0,a0
	lore	WB,RemoveAppWindow
	clr.l	appwindow(a5)
.noapp

	move.l	_IntuiBase(a5),a6		
	move.l	windowbase(a5),d0
	beq.b	.uh
	move.l	d0,a0

	tst.b	kokolippu(a5)
	bne.b	.big
	move.l	4(a0),windowZippedPos(a5)	* Pienen ikkunan koordinaatit
 if DEBUG
 	movem	4(a0),d0/d1
	DPRINT	"Close small window %ldx%ld"
 endif
	bra.b	.small

.big	move.l	4(a0),windowpos(a5)	* Ison ikkunan koordinaatit
 if DEBUG
 	movem	4(a0),d0/d1
	DPRINT	"Close big window %ldx%ld"
 endif

.small
	jsr	disposelistBoxRegion

	move.l	46(a0),a1		* WB screen addr
	move	14(a1),wbkorkeus(a5)	* WB:n korkeus
	clr.l	windowbase(a5)
	jmp	_LVOCloseWindow(a6)



;freepens
;	move.l	(a5),a0
;	cmp	#39,LIB_VERSION(a0)
;	blo.b	.q
;	move.l	screenlock(a5),a3
;	lea	sc_ViewPort(a3),a3
;	move.l	vp_ColorMap(a3),a3	* ColorMappi
;	move.l	pen_0(a5),d0
;	bsr.b	.burb
;	move.l	pen_1(a5),d0
;	bsr.b	.burb
;	move.l	pen_2(a5),d0
;	bsr.b	.burb
;	move.l	pen_3(a5),d0
;	bsr.b	.burb
;.q	rts
;.burb	move.l	a3,a0
;	lore	GFX,ReleasePen
;	rts



******************************************************************************
* WaitPointer
**************

* TODO: Could use rtLockWindow to replace freezegads and set wait pointer

pon1
setMainWindowWaitPointer:
	pushm	all
	move.l	windowbase(a5),d0
	bra.b	pon0

pon2	pushm	all
	move.l	windowbase2(a5),d0

pon0	beq.b	.q
	move.l	d0,a0
	bsr.w	get_rt
	lob	rtSetWaitPointer
.q	popm	all
	rts

clearMainWindowWaitPointer:
poff1
	pushm	all
	move.l	windowbase(a5),d0
	bra.b	poff0

poff2	pushm	all
	move.l	windowbase2(a5),d0

poff0	beq.b	.q
	move.l	d0,a0
	lore	Intui,ClearPointer
.q	popm	all
	rts

freezeMainWindowGadgets
	addq.b	#1,freezegads(a5)		* gadgetit jumiin!
	rts

unfreezeMainWindowGadgets
	subq.b	#1,freezegads(a5)
	bpl.b 	.ok
	clr.b   freezegads(a5)
.ok	rts

areMainWindowGadgetsFrozen
	tst.b	freezegads(a5)
	rts

******************************************************************************
* Sanity functions
**************

* Semaphore functions preserve all registers except maybe A0

obtainModuleList
	pushm	a0/a6
	lea 	moduleListSemaphore(a5),a0
	lore    Exec,ObtainSemaphore
	popm	a0/a6
	rts

releaseModuleList
	pushm	a0/a6
	lea 	moduleListSemaphore(a5),a0
	lore    Exec,ReleaseSemaphore
	popm	a0/a6
	rts

obtainModuleData:
	pushm	a0/a6
	lea 	moduleDataSemaphore(a5),a0
	lore    Exec,ObtainSemaphore
	popm	a0/a6
	rts

releaseModuleData:
	pushm	a0/a6
	lea 	moduleDataSemaphore(a5),a0
	lore    Exec,ReleaseSemaphore
	popm	a0/a6
	rts

showOutOfMemoryError
	push	a1
	lea	memerror_t,a1
	jsr	request
	pop 	a1 
	rts

lockMainWindow 
	tst.l	windowbase(a5)
	beq.b	.x
	pushm	all
	bsr.w	get_rt
	move.l	windowbase(a5),a0
	lob    	rtLockWindow
	move.l	d0,mainWindowLock(a5)
	popm	all
.x	rts

unlockMainWindow
	tst.l	mainWindowLock(a5)
	beq.b	.x 
	pushm	all
	bsr.w	get_rt
	move.l	windowbase(a5),a0
	move.l	mainWindowLock(a5),a1
	lob 	rtUnlockWindow
	clr.l	mainWindowLock(a5)
	popm	all
.x	rts



******************************************************************************
* Grafiikkaa *
**************
* Hipon tulostaminen

HIPPOHEAD_WIDTH = 96
HIPPOHEAD_HEIGHT = 66

inithippo
*** Lasketaan checksummi infoikkunan no-onelle ja unregistered-tekstille.

	check	1

	tst.b	uusikick(a5)
	bne.b	.new

	* Re-map colors to be more kick13 compatible
	* Switch colors 1 and 2
	* %00 = %00
	* %01 = %10
	* %10 = %01
	* %11 = %11
	lea	hippohead,a0
	lea	792(a0),a1
	move	#96*66/8-1,d7
.bytes
	moveq	#$1,d2
.bits
	move.b	(a0),d0
	and	d2,d0
	move.b	(a1),d1
	and	d2,d1
	add 	d1,d0
	cmp	d2,d0
	bne.b	.z
	eor.b	d2,(a0)
	eor.b	d2,(a1)
.z
	add.b   d2,d2
	bne.b	.bits

	addq	#1,a0
	addq	#1,a1
	dbf	d7,.bytes

.new

	lea	bitmapHippoHead(a5),a2
	move.l	a2,a0
	moveq	#2,d0
	moveq	#HIPPOHEAD_WIDTH,d1
	moveq	#HIPPOHEAD_HEIGHT,d2
	lore	GFX,InitBitMap
	move.l	#hippohead,bm_Planes(a2)
	move.l	#hippohead+792,bm_Planes+4(a2)
	rts

 ifeq zoom
* tavallinen hipon p‰‰
printhippo1:
;	DPRINT	"Print hippo"

	tst	boxsize(a5)
	beq.b	.q
	tst.b	win(a5)
	bne.b	.yep
.q	rts
.yep
	pushm	d0-d7/a0-a2/a6
	move.b	reghippo(a5),d7
	clr.b	reghippo(a5)

	* no registered name? 
	tst.b	keyfile(a5)
	beq.b	.noreg
	cmp.b	#' ',keyfile(a5)
	bne.b	.az
.noreg	moveq	#0,d7
.az


	moveq	#0,d0		* l‰hde x,y
	moveq	#0,d1
	moveq	#HIPPOHEAD_HEIGHT,d5		* y-koko

	; Calc y-position
	moveq	#76+WINY-14,d3
	tst.b	altbuttonsUse(a5)
	beq.b	.noAlt1
	add	#16,d3
.noAlt1

	move	boxsize(a5),d6
	mulu	listFontHeight(a5),d6
	sub	d5,d6
	bmi.b	.r	; will it fit?
	lsr	#1,d6	; center it 
	add	d6,d3	

	;moveq	#92,d2		* kohde x
	move	WINSIZX(a5),d2
	lsr	#1,d2
	sub	#HIPPOHEAD_WIDTH/2-8,d2

	tst.b	d7
	beq.b	.e
	move	#150,d2		* position when registered
.e


	lea	bitmapHippoHead(a5),a0
	move.l	rastport(a5),a1		* main
	add	windowleft(a5),d2
	add	windowtop(a5),d3
;	move	#$ee,d6		* minterm, kopio a or d ->d
	move	#$c0,d6		* minterm, suora kopio
	moveq	#HIPPOHEAD_WIDTH,d4		* x-koko
	lore	GFX,BltBitMapRastPort
.r	popm	d0-d7/a0-a2/a6
	rts
 else

printhippo1
* zoomaava hipon p‰‰
	tst.b	win(a5)
	bne.b	.yep
	;beq.b	.q
	;tst.b	uusikick(a5)
	;bne.b	.yep
.q	;rts
.yep
	pushm	all
	move.b	reghippo(a5),d7
	clr.b	reghippo(a5)

	lea	-(bm_SIZEOF+bsa_SIZEOF)(sp),sp
	move.l	sp,a4
	lea	bm_SIZEOF(a4),a3

	move.l	sp,a0
	moveq	#(bm_SIZEOF+bsa_SIZEOF)/2-1,d0
.cl	clr	(a0)+
	dbf	d0,.cl

	tst	boxsize(a5)
	beq.w	.r

	move.l	#224,d0
	move.l	#400*2,d1		* 2 planea
	lore	GFX,AllocRaster
	tst.l	d0
	beq.w	.r
	move.l	d0,a2

	move.l	a4,a0
	moveq	#2,d0
	move	#220,d1		* leveys 220
	move	#400,d2		* korkeus 400
	lob	InitBitMap
	move.l	a2,bm_Planes(a4)
	lea	(224/8)*400(a2),a0
	move.l	a0,bm_Planes+4(a4)


* alkup. x: 96, y: 66
* max  x: 220, y: 400

	moveq	#HIPPOHEAD_WIDTH,d0
	moveq	#HIPPOHEAD_HEIGHT,d1

	move	d0,bsa_SrcWidth(a3)
	move	d1,bsa_SrcHeight(a3)
	move	d0,bsa_XSrcFactor(a3)
	move	d1,bsa_YSrcFactor(a3)
	move	d0,bsa_XDestFactor(a3)
	move	d1,bsa_YDestFactor(a3)

	move.l	a4,bsa_DestBitMap(a3)
	pushpea	bitmapHippoHead(a5),bsa_SrcBitMap(a3)


	move.l	windowbase(a5),a0
	move	wd_Height(a0),d0
	sub	#88,d0

	move	d0,bsa_YDestFactor(a3)

	move	d0,d1
	add	#30,d1

	move	#220,d2
	tst.b	d7
	beq.b	.ne0
	moveq	#94,d2
.ne0

	cmp	d2,d1
	blo.b	.e
	move	d2,d1
.e
	move	d1,bsa_XDestFactor(a3)

	move.l	a3,a0
	lob	BitMapScale


	moveq	#0,d0		* l‰hde x
	moveq	#0,d1		* y
	moveq	#79+1,d3	* y
	move	bsa_DestWidth(a3),d4
	move	bsa_DestHeight(a3),d5


	move	#32+220/2+3,d2	* kohde x
	move	d4,d6
	lsr	#1,d6
	sub	d6,d2

	tst.b	d7
	beq.b	.ne
	move	#160,d2
.ne


	move.l	a4,a0
	move.l	rastport(a5),a1		* main
	add	windowleft(a5),d2
	add	windowtop(a5),d3
	move	#$ee,d6		* minterm, kopio a or d ->d
	lob	BltBitMapRastPort

	move.l	a2,d0
	beq.b	.r
	move.l	a2,a0
	move.l	#224,d0
	move.l	#400*2,d1		* 2 planea
	lob	FreeRaster

.r	
	
	lea	(bm_SIZEOF+bsa_SIZEOF)(sp),sp
	
	popm	all
	rts
 endc
	

** Print into scope window
printHippoScopeWindow
	;tst.b	uusikick(a5)
	;bne.b	.yep
	;rts
;.yep	
	pushm	d0-d6/a0-a2/a6
	lea	bitmapHippoHead(a5),a0
	move.l	s_rastport3(a4),a1		* quad
	moveq	#0,d0	
	moveq	#0,d1


	* Center hippohead into scope window
	move.l	s_scopeWindowBase(a4),a2 
	move	wd_Width(a2),d2
	lsr	#1,d2
	sub	#HIPPOHEAD_WIDTH/2,d2

	move	#14,d3
	move	s_scopeDrawAreaHeight(a4),d4
	sub	#SCOPE_DRAW_AREA_HEIGHT_DEFAULT,d4
	asr	#1,d4
	add	d4,d3

	moveq	#HIPPOHEAD_WIDTH,d4	
	moveq	#HIPPOHEAD_HEIGHT,d5
	add	windowleft(a5),d2
	add	windowtop(a5),d3
	move	#$c0,d6			* suora kopio
	lore	GFX,BltBitMapRastPort
	popm	d0-d6/a0-a2/a6
	rts


*********

initkorva
	lea	omabitmap4(a5),a2
	move.l	a2,a0
	moveq	#2,d0
	moveq	#16,d1
	moveq	#4,d2
	lore	GFX,InitBitMap
	move.l	#korvadata,bm_Planes(a2)
	move.l	#korvadata+8,bm_Planes+4(a2)
	rts

initkorva2
	lea	omabitmap5(a5),a2
	move.l	a2,a0
	moveq	#2,d0
	moveq	#16,d1
	moveq	#4,d2
	lore	GFX,InitBitMap
	move.l	#korvadata2,bm_Planes(a2)
	move.l	#korvadata2+8,bm_Planes+4(a2)
	rts

* d2 = x
* d3 = y

* a0 = Gadget
printkorva2
	pushm	d0-d7/a0-a2/a6
	move.l	rastport2(a5),a1	* prefs
	lea	omabitmap4(a5),a2
	bra.b	pkor

* Draw the RMB ear symbol 
* a0 = Gadget
printkorva
	tst.b	win(a5)
	bne.b	.q
	rts
.q
	pushm	d0-d7/a0-a2/a6
	move.l	rastport(a5),a1		* main
	lea	omabitmap5(a5),a2
	tst.b	uusikick(a5)
	bne.b	pkor
	lea	omabitmap4(a5),a2	* kick13: korva ilman tausta patternia

pkor
	movem	gg_LeftEdge(a0),d2/d3
	add	gg_Width(a0),d2
	subq	#4,d2

	moveq	#0,d0		* l‰hde x,y
	moveq	#0,d1
	moveq	#5,d4		* x-koko
	moveq	#4,d5		* y-koko

	move	#$c0,d6		* minterm, suora kopio a->d
	move.l	a2,a0
	lore	GFX,BltBitMapRastPort
.r	popm	d0-d7/a0-a2/a6
	rts


******** Tick-merkki

inittick
	lea	omabitmap3(a5),a2
	move.l	a2,a0
	moveq	#1,d0			* planes
	moveq	#16,d1			* lev
	moveq	#7,d2			* kork
	lore	GFX,InitBitMap
	move.l	#tickdata,bm_Planes(a2)
	rts

* d0 = <>0: aseta merkki, muutoin tyhjenn‰ alue
* d2/d3 = kohde x,y

tickaa	pushm	d0-d6/a0-a2/a6

	move	#$c0,d6			* suora kopio
;	move	#$ee,d6			* D: A or D
	tst.b	d0
	bne.b	.set
	moveq	#$0a,d6		* clear
.set

	movem	gg_LeftEdge(a0),d2/d3
	addq	#7,d2
	addq	#2+1,d3
	
	lea	omabitmap3(a5),a0
	move.l	rastport2(a5),a1		* prefs
	moveq	#0,d0				* l‰hde x,y
	moveq	#0,d1
	moveq	#16,d4				* koko x,y
	moveq	#7,d5
;	add	windowleft(a5),d2
;	add	windowtop(a5),d3
	lore	GFX,BltBitMapRastPort
	popm	d0-d6/a0-a2/a6
	rts




*******************************************************************************
* Merkkijonon muotoilu
*******
desmsg:
	movem.l	d0-d7/a0-a3/a6,-(sp)
	lea	desbuf(a5),a3	;puskuri
ulppa	move.l	sp,a1		* parametrit ovat t‰‰ll‰!
pulppa	lea	putc(pc),a2	;merkkien siirto
	move.l	(a5),a6
	lob	RawDoFmt
	movem.l	(sp)+,d0-d7/a0-a3/a6
	rts
putc	move.b	d0,(a3)+	
	rts


desmsg2:
	movem.l	d0-d7/a0-a3/a6,-(sp)
	lea	desbuf2(a5),a3
	bra.b	ulppa

* a3 = desbuf
desmsg3:
	movem.l	d0-d7/a0-a3/a6,-(sp)
	bra.b	ulppa


* a3 = desbuf

 if DEBUG 
desmsgDebugAndPrint
	* sp contains the return address, which is
	* the string to print
	movem.l	d0-d7/a0-a3/a6,-(sp)
	* get string
	move.l	4*(8+4+1)(sp),a0
	* find end of string
	move.l	a0,a1
.e	tst.b	(a1)+
	bne.b	.e
	move.l	a1,d7
	btst	#0,d7
	beq.b	.even
	addq.l	#1,d7
.even
	* overwrite return address 
	* for RTS to be just after the string
	move.l	d7,4*(8+4+1)(sp)

	lea	debugDesBuf+var_b,a3
	move.l	sp,a1	
	lea	putc(pc),a2	
	move.l	4.w,a6
	lob	RawDoFmt
	movem.l	(sp)+,d0-d7/a0-a3/a6
	bsr.w	PRINTOUT_DEBUGBUFFER
	rts	* teleport!
 endif

*******************************************************************************
* Laatikoiden piirto
*******

* Taalla bugaa joku, kun kaatuu P96 ja MCP

* d0 = x1
* d1 = y1
* d2 = x2
* d3 = y2



** bevelboksit, reunat kaks pixeli‰

laatikko1:
	move.l	pen_2(a5),d3
	move.l	pen_1(a5),d2
	bra.b	laatikko0

laatikko2:
	move.l	pen_1(a5),d3
	move.l	pen_2(a5),d2

;	bra.b	laatikko0


* In:
*   d2 = pen 1
*   d3 = pen 2
*   d4 = x1
*   d5 = y1
*   d6 = x2
*   d7 = y2
*   a1 = rastport 
laatikko0:
	tst.b	uusikick(a5)
	bne.b	.new
	exg	d2,d3
.new

	move.l	a1,a3
	move	d2,a4
	move	d3,a2

** valkoset reunat

	move	a2,d0
	move.l	a3,a1
	lore	GFX,SetAPen

	move	plx2,d0		* x1
	subq	#1,d0		
	move	ply1,d1		* y1
	move	plx1,d2		* x2
	move	ply1,d3		* y2
	bsr.w	drawli

	move	plx1,d0		* x1
	move	ply1,d1		* y1
	move	plx1,d2
	addq	#1,d2
	move	ply2,d3
	bsr.w	drawli
	
** mustat reunat

	move	a4,d0
	move.l	a3,a1
	lob	SetAPen

	move	plx1,d0
	addq	#1,d0
	move	ply2,d1
	move	plx2,d2
	move	ply2,d3
	bsr.b	drawli

	move	plx2,d0
	move	ply2,d1
	move	plx2,d2
	move	ply1,d3
	bsr.b	drawli

	move	plx2,d0
	subq	#1,d0
	move	ply1,d1
	addq	#1,d1
	move	plx2,d2
	subq	#1,d2
	move	ply2,d3
	bsr.b	drawli

looex	move.l	pen_1(a5),d0
	move.l	a3,a1
	jmp	_LVOSetAPen(a6)
	
** bevelboksi, reunat 1 pix

laatikko3

	move.l	a1,a3
	move.l	pen_2(a5),a2
	move.l	pen_1(a5),a4

	tst.b	uusikick(a5)
	bne.b	.new
	exg	a2,a4
.new

	move	a4,d0
	move.l	a3,a1
	lore	GFX,SetAPen

	move	plx1,d0
	move	ply2,d1
	move	plx1,d2
	move	ply1,d3
	bsr.b	drawli

	move	plx1,d0
	move	ply1,d1
	move	plx2,d2
	move	ply1,d3
	bsr.b	drawli

	move	a2,d0
	move.l	a3,a1
	lob	SetAPen

	move	plx2,d0
	move	ply1,d1
	addq	#1,d1
	move	plx2,d2
	move	ply2,d3
	bsr.b	drawli

	move	plx2,d0
	move	ply2,d1
	move	plx1,d2
	addq	#1,d2
	move	ply2,d3
	bsr.b	drawli

	bra.b	looex



drawli	cmp	d0,d2
	bhi.b	.e
	exg	d0,d2
.e	cmp	d1,d3
	bhi.b	.x
	exg	d1,d3
.x	move.l	a3,a1
	move.l	_GFXBase(a5),a6
	jmp	_LVORectFill(a6)


** muikea sliderkehys



sliderlaatikko
;	rts
	
	move.l	a1,a3
	move.l	pen_1(a5),a2
	move.l	pen_2(a5),a4

	tst.b	uusikick(a5)
	bne.b	.new
	exg	a2,a4
.new

** valkoset reunat

	move	a4,d0
	move.l	a3,a1
	lore	GFX,SetAPen

	move	plx2,d0
	move	ply1,d1
	move	plx1,d2
	move	ply1,d3
	bsr.b	drawli

	move	plx1,d0
	move	ply1,d1
	move	plx1,d2
	move	ply2,d3
	bsr.b	drawli

	move	plx1,d0
	addq	#2,d0
	move	ply2,d1
	subq	#1,d1
	move	plx2,d2
	subq	#1,d2
	move	ply2,d3
	subq	#1,d3
	bsr.b	drawli

	move	plx2,d0
	subq	#1,d0
	move	ply2,d1
	subq	#1,d1
	move	plx2,d2
	subq	#1,d2
	move	ply1,d3
	addq	#2,d3
	bsr.b	drawli

** mustat

	move	a2,d0
	move.l	a3,a1
	lob	SetAPen

	move	plx2,d0
	move	ply1,d1
	addq	#1,d1
	move	plx2,d2
	move	ply2,d3
	bsr.b	drawli

	move	plx2,d0
	move	ply2,d1
	move	plx1,d2
	addq	#1,d2
	move	ply2,d3
	bsr.w	drawli

	move	plx1,d0
	addq	#1,d0
	move	ply2,d1
	move	plx1,d2
	addq	#1,d2
	move	ply1,d3
	addq	#1,d3
	bsr.w	drawli

	move	plx1,d0
	addq	#1,d0
	move	ply1,d1
	addq	#1,d1
	move	plx2,d2
	subq	#1,d2
	move	ply1,d3
	addq	#1,d3
	bsr.w	drawli

	bra.w	looex


*******************************************************************************
* Tyhjent‰‰ alueen ikkunasta
*******
* d0 = x1
* d1 = y1
* d2 = x2
* d3 = y2
tyhjays:
	tst.b	win(a5)
	beq.b	.q
	movem.l	d0-a6,-(sp)
	sub	d0,d2
	sub	d1,d3
	move	d2,d4
	move	d3,d5
	addq	#1,d4
	addq	#1,d5
 	move.l	rastport(a5),a0
	move.l	a0,a1
	add	windowleft(a5),d0
	add	windowtop(a5),d1
	move	d0,d2
	move	d1,d3
	moveq	#$0a,d6
	lore	GFX,ClipBlit
	movem.l	(sp)+,d0-a6
.q	rts


*******************************************************************************
* Pullautetaan ikkuna p‰‰limm‰iseksi
*******
poptofront
	movem.l	d0-a6,-(sp)
	lea	var_b,a5
	move	#$25,rawkeyinput(a5)
	tst.b	win(a5)
	beq.b	.now
	clr	rawkeyinput(a5)
.now	move.b	rawKeySignal(a5),d1
	jsr	signalit
	movem.l	(sp)+,d0-a6
	rts


*******************************************************************************
* Muistin k‰sittely‰
*******

* d0=koko
* d1=tyyppi
getmem:
	movem.l	d1/d3/a0/a1/a6,-(sp)
 ifne DEBUG
	add.l	d0,getmemTotal
	addq.l	#1,getmemCount
 endc
	addq.l	#4,d0
	move.l	d0,d3
	move.l	4.w,a6
	lob	AllocMem
	tst.l	d0
	beq.b	.err
	move.l	d0,a0
	move.l	d3,(a0)+
	move.l	a0,d0
.err	movem.l	(sp)+,d1/d3/a0/a1/a6
	rts

* a0=osoite
freemem:
	movem.l	d0/d1/a0/a1/a6,-(sp)
 ifne DEBUG
	addq.l	#1,freememCount
 endc
	move.l	a0,d0
	beq.b	.n
	move.l	-(a0),d0
	move.l	a0,a1
	move.l	4.w,a6
	lob	FreeMem
.n	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts


;freeearly
;	pushm	all

;	move.l	(a5),a6
;	move.l	earlymoduleaddress(a5),d0
;	beq.b	.ee
;	move.l	d0,a1
;	move.l	earlymodulelength(a5),d0
;	beq.b	.ee

;	lob	FreeMem
;	clr.l	earlymoduleaddress(a5)
;	clr.l	earlymodulelength(a5)

;.ee	
;	move.l	earlytfmxsamples(a5),d0
;	beq.b	.eee
;	tst.b	earlylod_tfmx(a5)
;	bne.b	.cl
;	move.l	d0,a1
;	move.l	earlytfmxsamlen(a5),d0
;	lob	FreeMem
;.cl	clr.l	earlytfmxsamples(a5)
;	clr.l	earlytfmxsamlen(a5)
;	clr.b	earlylod_tfmx(a5)
;.eee	
;	popm	all
;	rts




freemodule:
	movem.l	d0-a6,-(sp)

	DPRINT	"freemodule obtain data"
	bsr.w	obtainModuleData

	* Check if need to do UnLoadSeg
	bsr.w	moduleIsExecutable
	move.b	d0,d7

	* IT hack!
	jsr	isImpulseTrackerActive
	sne	d6
	
	* Need to clear playertype(a5) to avoid
    * following freemodules to maybe mistakenly thing
    * that UnLoadSeg() is needed.

	clr	playertype(a5)
	clr.b	modulename(a5)
	clr.b	moduletype(a5)
	clr.b	kelausnappi(a5)
	clr.b	do_early(a5)
	clr.b	oldst(a5)
	clr.b	sidflag(a5)
	clr	ps3minitcount
	clr.b	ahi_use_nyt(a5)

	clr	pos_maksimi(a5)
	clr	pos_nykyinen(a5)
;	st	positionmuutos(a5)
	clr	positionmuutos(a5)
	clr	songnumber(a5)
	clr 	maxsongs(a5)
	clr 	minsong(a5)
	* For non-EP players supporting patterninfo
	clr.l	deliPatternInfo(a5) 
	jsr	clearScopeData
	
;	bsr.w	lootaa
	bsr.w	inforivit_clear

	* free replay code, this label here is silly
	* all of them are in the same address
	* with different labels
	lea	ps3mroutines(a5),a0		* vapautetaan replayeri
	jsr	freereplayer
	jsr	freeDeliPlayer
	
	move.l	(a5),a6
	move.l	moduleaddress(a5),d0
	beq.b	.ee
	move.l	d0,a1

	tst.b	d7
	beq.b	.normal
	move.l 	a1,d1
	lore	Dos,UnLoadSeg
 if DEBUG
	move.l	moduleaddress(a5),d0
	DPRINT	"UnLoadSeg 0x%lx"
 endif
	bra.b	.exe
.normal

	move.l	modulelength(a5),d0
	beq.b	.ee

	* IT deliplayer memory overrun hack
	tst.b	d6
	bne.b	.notIT
	DPRINT	"IT hack 2!"
	addq.l	#2,d0
.notIT
	lob	FreeMem
.exe

	clr.l	moduleaddress(a5)
	clr.l	modulelength(a5)

;	tst.l	keyfile+44(a5)	* datan v‰lilt‰ 38-50 pit‰‰ olla nollia
;	beq.b	.zz
;	move.l	tempexec(a5),a0
;	addq.l	#1,IVVERTB+IV_DATA(a0)
;.zz

	bsr.w	sulje_foo	

.ee	

	* See if there are TFMX samples that can be freed
	move.l	tfmxsamplesaddr(a5),d0
	beq.b	.noTFMX
	DPRINT	"Free extra data 0x%lx"
	move.l	d0,a1
	move.l	tfmxsampleslen(a5),d0
	lob	FreeMem
.noTFMX
	clr.l	tfmxsamplesaddr(a5)
	clr.l	tfmxsampleslen(a5)
	clr.b	lod_tfmx(a5)

	DPRINT	"freemodule release data"
	bsr.w	releaseModuleData

	movem.l	(sp)+,d0-a6
	rts


* out:
*  d0 = non-zero if loaded module is an LoadSeg() loaded exe	
moduleIsExecutable
	cmp	#pt_delicustom,playertype(a5)
	beq.b	.isExe
	cmp	#pt_futureplayer,playertype(a5)
	beq.b	.isExe
	cmp	#pt_davelowe,playertype(a5)
	beq.b	.isExe
	moveq	#0,d0
	rts
.isExe 
	moveq	#1,d0 
	rts

*******************************************************************************
* Volumen feidaus
********
fadevolumedown
	movem.l	d1-a6,-(sp)
	move	mainvolume(a5),d7
	move	d7,d6

	tst.b	fade(a5)
	beq.b	.nop
	tst.l	playingmodule(a5)
	bmi.b	.nop
	tst.b	playing(a5)
	beq.b	.nop
	move.l	playerbase(a5),a0
	moveq	#pf_volume,d0
	and	p_liput(a0),d0
	beq.b	.nop

	cmp	#pt_multi,playertype(a5)	* onko ps3m?
	bne.b	.loop
	move.l	priority(a5),d5
	move.b	#10,priority+3(a5)
	bsr.w	mainpriority
.loop
	moveq	#1,d1
	lore	Dos,Delay

	move	d6,mainvolume(a5)
	move.l	playerbase(a5),a0
	jsr	p_volume(a0)
	subq	#1,d6
	cmp	#-1,d6
	bne.b	.loop

	cmp	#pt_multi,playertype(a5)	* onko ps3m?
	bne.b	.nop
	move.l	d5,priority(a5)
	bsr.b	mainpriority

.nop	

	

	move	d7,d0
	movem.l	(sp)+,d1-a6
	rts


fadevolumeup
	movem.l	d1-a6,-(sp)
	move	mainvolume(a5),d7
	addq	#1,d7
	moveq	#0,d6

	tst.b	fade(a5)
	beq.b	.nop
	tst.l	playingmodule(a5)
	bmi.b	.nop
	tst.b	playing(a5)
	beq.b	.nop
	move.l	playerbase(a5),a0
	moveq	#pf_volume,d0
	and	p_liput(a0),d0
	beq.b	.nop

	cmp	#pt_multi,playertype(a5)	* onko ps3m?
	bne.b	.loop
	move.l	priority(a5),d5
	move.b	#10,priority+3(a5)
	bsr.b	mainpriority
.loop
	moveq	#1,d1
	lore	Dos,Delay

	move	d6,mainvolume(a5)
	move.l	playerbase(a5),a0
	jsr	p_volume(a0)
	addq	#1,d6
	cmp	d6,d7
	bne.b	.loop

	cmp	#pt_multi,playertype(a5)	* onko ps3m?
	bne.b	.nop
	move.l	d5,priority(a5)
	bsr.b	mainpriority

.nop	
	movem.l	(sp)+,d1-a6
	rts


*******************************************************************************
* Asettaa p‰‰ohjelman prioriteetin
******** 

mainpriority
	pushm	d0/d1/a0/a1/a6
	move.l	owntask(a5),a1		* asetetaan p‰‰ohjelman prioriteetin
	move.l	priority(a5),d0
	lore	Exec,SetTaskPri
	popm	d0/d1/a0/a1/a6
	rts




******************************************************************************
* Hiiren nappeja painettiin
* Mouse button handler
*******
* in:
*   d3=im_Code

* SELECTDOWN: left button down
* SELECTUP: left button up
* MENUDOWN: right button down
* MENUUP: right button up

buttonspressed:
	tst.b	win(a5)			* onko ikkuna auki?
	beq.w	.nowindow

	* Any button activity should first close any active tooltip
	bsr.w	closeTooltipPopup

	cmp	#SELECTDOWN,d3		* left button down
	bne.b	.test1
	bsr.w	.leftButtonDownAction
	rts

.test1
	cmp	#MENUUP,d3
	bne.b	.test2
	bsr.w	.rightButtonUpAction		* right button up
	rts 

.test2	cmp	#MENUDOWN,d3			* right button down
	bne.b 	.exit
	bsr.b	.rightButtonDownAction
.exit 
	rts
	
.rightButtonDownAction

* Oikeata nappulaa painettu. Tutkitaan oliko rmbfunktio-nappuloiden p‰‰ll‰

	tst.b	kokolippu(a5)		* onko pienen‰?
	beq.b	.nowindow

** onko lootan p‰‰ll‰
** on top of the filebox?
	move	mousex(a5),d0
	move	mousey(a5),d1
	sub	windowleft(a5),d0
	sub	windowtop(a5),d1	* suhteutus fonttiin

	cmp	#7+WINX,d0
	blo.b	.y
	cmp	#70+WINX,d0	* 247
	bhi.b	.y
	cmp	#10+WINY,d1
	blo.b	.y
	cmp	#30+WINY,d1
	bhi.b	.y

** toggle scope with rmb when on top of suitable place
	jsr	toggleScopes

.handled
	rts
.y

** check buttons with RMB functions defined and trigger those

	DPRINT	"RMB DOWN check"

	lea	rightButtonActionsList,a2
.actionLoop
	move.l	a2,a0
	add	(a2)+,a0
	move.l	(a2)+,a1
	bsr.b	.rightButtonDownCheck
	beq.b	.handled
	tst.w	(a2) 
	bne.b	.actionLoop

	* no RMB actions found
	* try line marking
	bsr.w	marklineRightMouseButton
	beq.b	.nothingMarked
	rts

.nothingMarked
	* Last RMB action,
	* Zip Window 
.nowindow

	tst.b	uusikick(a5)
	bne.b	.new
	bsr.w	sulje_ikkuna		* Vaihdetaan ikkunan kokoa (kick1.3)
	bsr.w	avaa_ikkuna
	rts

.new	
	DPRINT	"ZipWindow Intuition"
	move.l	windowbase(a5),a0	* Kick2.0+
	lore	Intui,ZipWindow
	rts

.leftButtonDownAction

* jos oli lootan p‰‰ll‰ niin avataan info ikkuna!
	move	mousex(a5),d0
	move	mousey(a5),d1
	sub	windowleft(a5),d0
	sub	windowtop(a5),d1	* suhteutus fonttiin

	cmp	#7+WINX,d0
	blo.b	.x
	cmp	#70+WINX,d0	* 247
	bhi.b	.x
	cmp	#10+WINY,d1
	blo.b	.x
	cmp	#30+WINY,d1
	blo.b	.yea

	* mouse not on top of info box, try marking files

.x	bsr.w	markline		* merkit‰‰n modulenimi
	rts

.yea

** modinfon infon avaus
	bsr.w	modinfoaaa
	rts

* in:
*   a0=gadget
*   a1=gadget function to run
.rightButtonDownCheck
	bsr.w	checkMouseOnGadget
	bne.b	.mouseNotOn
	move.l	a0,rightButtonSelectedGadget(a5)
	move.l	a1,rightButtonSelectedGadgetRoutine(a5)
	bsr.w	forceSelectGadget
	moveq	#0,d0
.mouseNotOn
	rts

* Right button has been released.
* Check if there was a right button activation on a gadget.
* If the pointer is still on that gadget, run the routine.
.rightButtonUpAction
	move.l	rightButtonSelectedGadget(a5),d2
	beq.b	.noGadget

	DPRINT	"RMB UP"

	* In any case RMB selected gadgets should be deselected when now.
	*
	* The display memory gets XORred and acts as internal state
	* even if select flag is cleared and gadget is refreshed.
	* Toggling select and deselect again results in a neutral
	* toggle button look.
	move.l	d2,a0
	bsr.w	forceDeselectGadget
	move.l	d2,a0
	bsr.w	forceSelectGadget
	move.l	d2,a0
	bsr.w	forceDeselectGadget
	
	move.l	d2,a0
	bsr.w 	checkMouseOnGadget
	bne.b	.xy	

	* Pointer was on top, run the routine
	move.l	rightButtonSelectedGadgetRoutine(a5),d0
	beq.b	.xy
	move.l	d0,a0
	DPRINT	"Execute routine"
	jsr	(a0)
.xy
	clr.l	rightButtonSelectedGadget(a5)
	clr.l	rightButtonSelectedGadgetRoutine(a5)
.noGadget
	rts


*** Zoomataan fileboxi pois tai takasin
*** Switch filebox size
zoomfilebox
	DPRINT	"Zoom filebox"
	move	boxsize(a5),d0
	beq.b	.z
	clr	boxsize(a5)
	move	d0,boxsizez(a5)
	bsr.w	disableResizeGadget
	bra.b	.x
.z
	move	boxsizez(a5),boxsize(a5)
	bsr.w	enableResizeGadget
.x
	bsr.w	setprefsbox
	move.b	ownsignal2(a5),d1
	jmp	signalit		* prefsp‰ivitys-signaali
	

*** Open module info window
modinfoaaa
	DPRINT	"modinfo"
	* flag: display mod info
	clr.b	infolag(a5)
	tst	info_prosessi(a5)
	beq.b	.zz	
	move.l	infotaz(a5),a0		* jos oli jo modinfo niin suljetaan
	cmp.l	#about_t,a0
	beq	start_info
	bra	sulje_info
		
.zz	bra	rbutton10b

* Forces a boolean gadget to show the selected status
* in:
*   a0=gadget
forceSelectGadget
	move.l	a0,d2
	move.l	windowbase(a5),a0
	move.l	d2,a1 
	lore	Intui,RemoveGadget

	move.l	d2,a1
	or	#GFLG_SELECTED,gg_Flags(a1)

	move.l	windowbase(a5),a0
	moveq	#-1,d0 
	lob	AddGadget
	move.l	d2,a0	
	bsr.b	refreshGadget
	rts

* Forces a boolean gadget to show the deselected status
* in:
*   a0=gadget
forceDeselectGadget

	move.l	a0,d2
	move.l	windowbase(a5),a0
	move.l	d2,a1 
	lore	Intui,RemoveGadget

	move.l	d2,a1
	and	#~GFLG_SELECTED,gg_Flags(a1)

	move.l	windowbase(a5),a0
	moveq	#-1,d0 
	lob	AddGadget

	move.l	d2,a0	
	bsr.b	refreshGadget
	rts

* Redraws gadget
* in:
*   a0=gadget
refreshGadget
refreshGadgetInA0
	move.l	windowbase(a5),a1
	sub.l	a2,a2
	moveq	#1,d0	
	lore	Intui,RefreshGList
	rts


* Checks if mouse pointer is within given gadget in main window
* in: 
*   a0=gadget
* destroys:
*   d0-d3, d6, d7
* out:
*   d0 = 0  was inside
*   d0 = -1 was not inside
checkMouseOnGadget
	movem	gg_LeftEdge(a0),d0-d3
	move	mousex(a5),d6
	move	mousey(a5),d7
	subq	#1,d3
	add	d0,d2
	add	d1,d3
	cmp	d0,d6
	blo.b	.xx
	cmp	d2,d6
	bhi.b	.xx
	cmp	d1,d7
	blo.b	.xx
	cmp	d3,d7
	bhi.b	.xx
	moveq	#0,d0			* kelpaa
	rts
.xx	moveq	#-1,d0
	rts


******************************************************************************
* Tooltip handling
*******

 STRUCTURE TooltipListEntry,0
    	UWORD ttle_gadget
    	UWORD ttle_tooltip
 LABEL  ttle_SIZEOF

 STRUCTURE ToolTip,0
    	UBYTE tt_width
	UBYTE tt_height
	APTR  tt_text
 LABEL  tt_SIZEOF

* Tooltip handler
* Called when a mouse move event is received.
* It will close any existing tooltip and set up a new one if needed.
tooltipHandler
	;DPRINT	"tooltiphandler"

	* First, inactivate incoming tooltip
	bsr.w	deactivateTooltip
	
	* Close any tooltip that may be showing since mouse was moving.
	bsr.w	closeTooltipPopup

	* Check if window is zipped to toolbar size
	tst.b	kokolippu(a5)
	beq.b	.exit

	* If some lengthy operation is going on lets not
	* try to display tooltips.
	bsr.w	areMainWindowGadgetsFrozen
	bne.b	.exit

	* Skip further checks if mouse is not over the main button area
	move	mousey(a5),d1

	* Check if above "Play" button
	lea	gadgetPlayButton,a0
	move	gg_TopEdge(a0),d2
	cmp	d1,d2
	blo.b	.under
	* Mouse is over the "Play" button, exit	
	rts
.under		
	* Check if below the "New" button
	;lea	gadgetNewButton,a0
	lea	gadgetListModeChangeButton,a0
	move	gg_TopEdge(a0),d2
	add	gg_Height(a0),d2
	cmp	d1,d2
	bhi.b	.below
	* Mouse is below the "New" button, exit
	rts
.below

	* Then check if pointer is on top of some gadget
	lea tooltipList,a3
.loop 
	lea	ttle_gadget(a3),a0
	add	(a0),a0

	* Check if gadget is disabled, no tooltips for those
	move	gg_Flags(a0),d0
	and	#GFLG_DISABLED,d0
	bne.b	.disabled

	bsr.b	checkMouseOnGadget
	bne.b	.no
	* Yes it was.
	* Check if this gadget was not allowed to have tooltips for now
	cmp.l  disableTooltipForGadget(a5),a0
	beq.b	.disabled
	* Store tooltip to be displayed and activate
	lea	ttle_tooltip(a3),a0
	add	(a0),a0
	move.l	a0,activeTooltip(a5)
	* Count down this many ticks before attempting to show tooltip
	move	#1*50+25,tooltipTick(a5) * about 1.5 seconds	
	rts
.disabled
	;DPRINT	"was disabled"
.no 
	addq.l	#ttle_SIZEOF,a3
	tst.w	(a3)
	bne.b	.loop
.exit	rts

* Displays tooltip if needed
tooltipDisplayHandler	
	pushm	all 
	move.l	activeTooltip(a5),d0 
	beq.b	.exit 
	clr.l	activeTooltip(a5)
	clr.l	disableTooltipForGadget(a5)
	* skip display if not enabled in prefs
	tst.b	tooltips(a5)
	beq.b	.exit
	move.l	d0,a0 
	bsr.w	showTooltipPopup
.exit
	popm all
	rts

* Clears any previous tooltip activation so it will not be shown
* after the timeout
deactivateTooltip
	clr	tooltipTick(a5)
	clr.l	activeTooltip(a5)
	rts


*******************************************************************************
* Omaan viestiporttiin tuli viesti
******
omaviesti
	pushm	all
	lea	hippoport(a5),a0
	lore	Exec,GetMsg
	tst.l	d0
	beq.w	.huh
	move.l	d0,a1
	move.l	a1,omaviesti0(a5)

	;cmp.l	#"KILL",MN_LENGTH+2(a1)	* ????????
	;beq.w	.killeri

	* What kind of a message is this?

	* Sent by another hippo?
	cmp.l	#MESSAGE_MAGIC_ID,HM_Identifier(a1)
	beq.w	.oma

	* App window message?
	* This is likely kick2.0 feature, dropping icons
	* on top of windows.
	cmp.l	#'AppW',am_UserData(a1)		* Onko AppWindow-viesti?
	beq.b	.appw

	* Screen notify message?
	movem.l	snm_Type(a1),d3/d4
	cmp.l	#SCREENNOTIFY_TYPE_WORKBENCH,d3
	bne.w	.huh
	tst.l	d4
	bne.b	.open

	tst.b	win(a5)			* HIDE!
	beq.w	.huh
	bsr.w	sulje_ikkuna
	clr.b	win(a5)
	bsr.w	sulje_prefs
	jsr	stopScopeTasks
	bsr.w	sulje_info
	bra.w	.huh

.open	
	tst.b	win(a5)
	bne.w	.huh
	bsr.w	openw
	bra.w	.huh

*********************************************
* App window drag'n'drop handler
*********************************************
.appw
** AppWindow-viesti!!
	move.l	am_NumArgs(a1),d7	* argsien m‰‰r‰
	beq		.huh
	bsr.w	tokenizepattern
	jsr		engageNormalMode
	bsr		obtainModuleList
 if DEBUG
	move.l	d7,d0
	DPRINT	"AppWindow drag'n'drop num=%ld"
 endif
	subq	#1,d7
	move.l	am_ArgList(a1),a3	* WBArg array
	lea	-200(sp),sp
	move.l	sp,a2
.addfiles
	move.l	wa_Lock(a3),d1
	move.l	sp,d2
	move.l	#150,d3			* max pituus
	jsr		getNameFromLock
	tst.l	d0
	beq		.error

	move.l	sp,a2
.fe	tst.b	(a2)+
	bne.b	.fe
	subq	#1,a2
	cmp.b	#':',-1(a2)
	beq.b	.na
	move.b	#'/',(a2)+
.na	clr.b	(a2)

	* If this is empty, a dir was dropped
	move.l	wa_Name(a3),a0
	tst.b	(a0)
	bne.b	.file
	DPRINT	"Directory scan"
	move.l	sp,a0
.1	tst.b	(a0)+
	bne.b	.1
	subq	#2,a0	* skip null and the 1st dir separator
	move.l	sp,a1
	bsr		nimenalku
	* a0 = dir name
	bsr.w	adddivider
	* d2 = path
	move.l	sp,d2
	* d3 = path len + l_size
	move.l	a2,d3
	sub.l	sp,d3
	add.l	#l_size,d3

	pushm	all
	bsr		lockMainWindow
	bsr		filereq_code\.scanni
	bsr		unlockMainWindow
	popm	all
	bra.b	.continue
.file
.cp	move.b	(a0)+,(a2)+
	bne.b	.cp

 if DEBUG
	move.l		sp,d0
	DPRINT	"->%s"
 endif
	pushpea	tokenizedpattern(a5),d1
	move.l	sp,d2
	lore	Dos,MatchPatternNoCase
	* 0 = did not match, skip this file if so
	tst.l	d0
	beq.b	.continue

	move.l	sp,a0
	bsr		createListNodeAndAdd

.continue
.error
	addq	#wa_SIZEOF,a3
	dbf		d7,.addfiles
.lop	
	lea		200(sp),sp
	bsr		releaseModuleList
	bsr.w	listChanged
	bsr.w	forceRefreshList
	bra.b	.huh


* oma viesti saapui!
.oma
	* Copy commandline arguments from the message to local buffer
	move.l	HM_Arguments(a1),a0
	lea	sv_argvArray(a5),a2
.c	move.l	(a0)+,(a2)+
	bne.b	.c

	* Check out the first parameter 
	move.l	sv_argvArray+4(a5),a0
	bsr.w	kirjainta4
	cmp.l	#MESSAGE_COMMAND_QUIT,d0
	bne.b	.app
	st	exitmainprogram(a5)
	bra.b	.huh

.app
	bsr.w	komentojono		* tutkitaan uudet komennot
.huh	bsr.b	vastomaviesti


.he	popm	all
	rts

.killeri
	st	exitmainprogram(a5)
	bra.b	.he



vastomaviesti
	pushm	d0/d1/a0/a1/a6
	move.l	omaviesti0(a5),d0
	beq.b	.x
	clr.l	omaviesti0(a5)
	move.l	d0,a1
	lore	Exec,ReplyMsg
.x	popm	d0/d1/a0/a1/a6
	rts


*******************************************************************************
* Oman signaalin vastaanotto (moduuli soitettu, jatkotoimenpiteet)
*******
signalreceived
	DPRINT	"Song end signal"

	moveq	#1,d7			* menn‰‰n listassa eteenp‰in
					* step forward in the list

	cmp.b	#pm_random,playmode(a5)	* Arvotaanko j‰rjestys?
	bne.b	.norand

* Previously when a song end was detected in random play mode,
* the next subsong was played if there were any subsongs.
* Better would be to randomize a new module instead.

** Onko subsongeja soiteltavaks?
** Are there any subsongs to play next?
;	move.l	playerbase(a5),a0
;	move	p_liput(a0),d0
;	* See if this replayer supports subsongs
;	btst	#pb_song,d0
; 	beq.b	.ran
;	move	songnumber(a5),d0
;	cmp	maxsongs(a5),d0
;	bne.w	actionNextSong		* next song!
;.ran	
	* no subsongs, randomize next one
	bra.w	.karumeininki

.norand
	* Play mode is not random. 

	cmp.b	#pm_repeatmodule,playmode(a5) 	* Jatketaanko soittoa?
	beq.w	.reet			* If module repeat on, just exit
	
	cmp.l	#1,modamount(a5) * Jos vain yksi modi,
	bne.b	.notone		* jatketaan soittoa keskeytyksett‰.
	cmp.l	#PLAYING_MODULE_REMOVED,playingmodule(a5) * Listassa yksi modi, joka on uusi.
	bne.b	.oon			* Soitetaan se.
	moveq	#0,d7			* ei lis‰t‰ eik‰ v‰hennet‰
					* no stepping in the list
	bra.b	.notone
.oon

	cmp.b	#pm_repeat,playmode(a5)
	bne.b	.notone

** Onko subsongeja soiteltavaks?
	move.l	playerbase(a5),a0
	move	p_liput(a0),d0
	btst	#pb_song,d0
 	beq.w	.reet
	move	songnumber(a5),d0
	cmp	maxsongs(a5),d0
	bne.w	rbutton13		* next song!
	bra.w	.reet

.notone

	tst.l	playingmodule(a5)	* soitettiinko edes mit‰‰n
	bmi.w	.err

	cmp.b	#pm_module,playmode(a5)	* Play mode was "module", stop after playing 
	beq.w	.stop

** Onko subsongeja soiteltavaks?
* Check for subsongs
	move.l	playerbase(a5),a0
	move	p_liput(a0),d0
	btst	#pb_song,d0
 	beq.b	.eipa
	move	songnumber(a5),d0
	cmp	maxsongs(a5),d0
	bne.w	rbutton13		* next song!
	

.eipa
	DPRINT	"Replay end"

	* Stopping playback 
	bsr.w	obtainModuleData
	clr.b	playing(a5)		* soitto seis
	move.l	playerbase(a5),a0	* stop module
	jsr 	p_end(a0)
	bsr.w	releaseModuleData

	bsr.w	freemodule

	tst.l	modamount(a5)		* onko modeja?
	beq.w	.err

	cmp.l	#PLAYING_MODULE_REMOVED,playingmodule(a5) * Lista tyhj‰tty? Soitetaan eka modi.
	bne.b	.eekk
	moveq	#0,d7				* no stepping in the list
	clr.l	chosenmodule(a5)
.eekk
	* select next module 
	ext.l	d7 
	move.l	chosenmodule(a5),d0 
	add.l	d7,d0
	bpl.b	.wasPositive			
	* negative index, wrap to the last module
	move.l	modamount(a5),chosenmodule(a5)
	subq.l	#1,chosenmodule(a5)
	bra.b	.repea
.wasPositive
	move.l	d0,chosenmodule(a5)
	* Note that upper bound check is not here, it's done below when
	* traversing the list nodes.
.repea

	move.l	chosenmodule(a5),playingmodule(a5)
	move.l	playingmodule(a5),d0

	bsr.w	forceRefreshList

	DPRINT	"signalreceived getListNode"
	bsr.w	getListNode
	beq.w	.erer 
	move.l	a0,a3

	tst.b	l_divider(a3)
	beq.b	.wasfile
	tst	d7			* pit‰‰ olla jotain ett‰ ei j‰‰ 
	bne.b	.eekk		* jummaamaan dividerin kohdalle,
	moveq	#1,d7	* step forward
	bra.b	.eekk
.wasfile

	lea	l_filename(a3),a0	* ladataan
	moveq	#0,d0			* no double buffering
	jsr	loadmodule
	tst.l	d0
	bne.b	.loader

	DPRINT	"Replay init"
	move.l	playerbase(a5),a0	* soitto p‰‰lle
	jsr	p_init(a0)
	tst.l	d0
	bne.b	.mododo

	bsr.w	settimestart
.reet0	st	playing(a5)
	bsr.w	inforivit_play
	bsr.w	start_info
.reet
	rts

.loader	
	* load error, no module to play
	move.l	#PLAYING_MODULE_NONE,playingmodule(a5)	* latausvirhe
	bra.b	.reet

.mododo	
	* init error, no module to play

	DPRINT	"ERROR, deallocate resources!"
	jsr	rem_ciaint
	jsr	vapauta_kanavat

	move.l	#PLAYING_MODULE_NONE,playingmodule(a5)	* initti virhe
	jsr	init_error
	bra.b	.reet

.err	
	move.l	#PLAYING_MODULE_NONE,playingmodule(a5)	* ei modeja mit‰ soittaa
	move.l	#PLAYING_MODULE_NONE,chosenmodule(a5)
	rts

.stop  	bsr.w	actionStopButton		* stop!
	bra.b	.reet

* modit loppui, mit‰ tehd‰‰n?
* No modules left to play
.erer	move.l	#PLAYING_MODULE_NONE,playingmodule(a5)

	cmp.b	#pm_through,playmode(a5)
	bne.b	.hm
	* select last module
	move.l	modamount(a5),chosenmodule(a5)
	subq.l	#1,chosenmodule(a5)
	bsr.w	resh
	bra.w	.reet

.hm	
	* In "pm_through" mode start over from the first module
 	clr.l	playingmodule(a5)	* Alotetaan alusta
	* select first module
	clr.l	chosenmodule(a5)

	* SANITY CHECK: in the case where it's all dividers,
	* stop instead of trying to find something to play.
	jsr	calculateDividersInList
	cmp.l	modamount(a5),d0
	beq.b	.err
	bra.w	.repea

* Shuffle-soitto
.karumeininki
	move.l	modamount(a5),d0
	beq.w	.reet		* jos ei yht‰‰n, jatketaan entisen soittoa
	cmp.l	#1,d0		* Jos vain yksi, jatketaan soittoa
	beq.w	.reet
	bra.w	soitamodi2


******************************************************************************
*
* Random stuff
*
****************

* Randomize a module
* out:
*    chosenmodule(a5) will get the index of the randomized module
satunnaismodi
	move.l	modamount(a5),d0
	* Low bound check
	cmp.l	#1,d0
	bhi.b	.nof
	clr.l	chosenmodule(a5)
	rts
.nof
	* High bound check
	cmp.l	#MAX_MODULES,d0		* jos liikaa, ei yll‰pidet‰ listaa
	bhi.b	.onviela
	subq.l	#1,d0			* for dbf

	* Loop as much as we have modules and test if the random table 
	* has free slots left.

.h	bsr.w	testRandomTableEntry
	beq.b	.onviela
	;dbf	d0,.h
	subq.l	#1,d0 
	bpl.b	.h

	DPRINT 	"all random table slots taken"

	* All slots taken, clear it and start over.
	* This means all modules have randomly played.
	bsr.b	clear_random
	bra.b	satunnaismodi

.onviela
	* There are free slots left in the random table.
	* Next get a random value in the range [0, number of modules-1].
	move.l	modamount(a5),d3
	subq.l	#1,d3
.a	bsr.w	getRandomValue
	* Function returns 0..MAX_RANDOM_MASK,
	* which may be larger than modamount(a5). 
	* Accept only random values in range.
	cmp.l	d3,d1
	bhi.b	.a

	* Got a random value in proper range in d1
	* Test if a slot is free. Try again if not.
	move.l	d1,d0
	bsr.b	testRandomTableEntry
	bne.b	.a
	* Was free. Take it.
	bsr.w	setRandomTableEntry

	* I choose you, module in index d1
	move.l	d1,chosenmodule(a5)
.reet	rts


* Clear random table and do force refresh of list
* if in random mode.
clear_random:
	bsr.b	clearRandomTable
	cmp.b	#pm_random,playmode(a5)
	bne.b	.x
	* Request refresh to clear out random play indicators.
	* This may update list in surprising situations.
	* For example, when selecting parent item in filebrowser,
	* before the parent contents are refreshed into view.
	st	hippoonbox(a5)
	pushm	all
	;bsr.w	shownames
	bsr.w	showNamesNoCentering
	popm	all
.x
	rts

* Clear random table
clearRandomTable
	pushm	d0/a0
	DPRINT  "clearRandomTable"
	bsr.w	 obtainModuleList
	clr.l	randomValueMask(a5)
	tst.l	randomtable(a5)
	beq.b	.noList
	move.l	randomtable(a5),a0 
	bsr.w 	freemem 
	move.l	randomtable(a5),d0
	clr.l	randomtable(a5)
.noList
	bsr.w	releaseModuleList
	popm	d0/a0
	rts

* Test if index given in d0 is taken in the random table
* in:
*      d0 = module index to test
* out:
*      Z is set if index is taken
testRandomTableEntry:
	push	a0
	bsr.b	getRandomValueTableEntry
	beq.b	.error
	btst	d0,(a0)
.error
	pop     a0
	rts


* Each index maps into one bit in the randomtable. 
* It is created here if not available.
* It's much faster to use a bit table for this instead of doing list traversal.
* in:
*      d0 = module index to test
* out:
*      a0 = index in the ranom table that should be tested 
getRandomValueTableEntry:
	push 	d1
	tst.l	randomtable(a5) 
	bne.b	.yesTable

	* Each byte can hold a slot for 8 modules.
	* A bit silly dynamic allocation as probably
	* the amount is a very few bytes.
	push	d0
	move.l	modamount(a5),d0 
	DPRINT	"New randomtable for %ld"

	lsr.l	#3,d0
	addq.l	#1,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	bsr.w	getmem
	
	move.l	d0,randomtable(a5)
	bne.b	.ok
	bsr.w	showOutOfMemoryError
.ok
	pop     d0
		
	tst.l	randomtable(a5)
	beq.b	.problem
.yesTable
	move.l	randomtable(a5),a0
	move.l	d0,d1
	lsr.l	#3,d1 
	add.l	d1,a0
	* Restoring d1 with pop (which is a move.l (sp)+) alters the Z-flag.
	* movem.l (sp)+,d1 would not do this,
	* for fun clear the Z-flag manually!
	pop 	d1
	and.b	#~(1<<2),ccr
.problem
	rts

* Sets the random table entry as taken for given module index.
* in:
*   d0 = module index
setRandomTableEntry
	pushm	all
	DPRINT  "setRandomTableEntry %ld"
	
	* Set it in the table
	bsr.w	getRandomValueTableEntry
	beq.b	.error
	bset	d0,(a0)
.error

	cmp.b	#pm_random,playmode(a5)
	bne.b	.x

	* This requests refresh of list contents. Possibly not reasonable.
	st	hippoonbox(a5)
.x
	popm	all
	rts

* Get seed for random generator
srand   
	move.l	4.w,a6
	moveq	#MEMF_PUBLIC,d1
	lob	AvailMem
	add.l	ThisTask(a6),d0

	lea	$dff000,a1
	add.l	4(a1),d0      ; Initialize random generator.. Call once
        add.l   2(a1),d0
	lea	$dc0000,a0
	add.l	(a0)+,d0
	add.l	(a0)+,d0
	add.l	(a0)+,d0
	add.l	(a0),d0

	moveq	#0,d1
	move.b	$bfec01,d1
;	add.l	d1,d0
	rol.l	d1,d0

	move	$a(a1),d1	* joy0dat
	add	d1,d0
	move	$c(a1),d1	* joy1dat
	add	d1,d0
	move	$1a(a1),d1	* dskbytr
	add	d1,d0
	move	$18(a1),d1	* serdatr
	add	d1,d0

        move.l  d0,seed(a5)
        rts

* Returns a pseudo random number
* out:
*    d1 = random number, range 0..MAX_RANDOM_MASK
getRandomValue
	push	d0
	move.l  seed(a5),d0     ; Returns random number (result: d0 = 0-32767)
        move.l  #$41c64e6d,d1
        bsr.b	mulu_32
        add.l   #$3039,d0
        move.l  d0,seed(a5)
        moveq   #$10,d1
        lsr.l   d1,d0
		
	move.l	d0,d1 
	bsr.w	getRandomValueMask
	and.l	d0,d1

	pop	d0
        rts



* mulu_32 --- d0 = d0*d1
mulu_32	movem.l	d2/d3,-(sp)
	move.l	d0,d2
	move.l	d1,d3
	swap	d2
	swap	d3
	mulu	d1,d2
	mulu	d0,d3
	mulu	d1,d0
	add	d3,d2
	swap	d2
	clr	d2
	add.l	d2,d0
	movem.l	(sp)+,d2/d3
	rts	

* divu_32 --- d0 = d0/d1, d1=remainder
divu_32	move.l	d3,-(a7)
	swap	d1
	tst	d1
	bne.b	.lb_5f8c
	swap	d1
	move.l	d1,d3
	swap	d0
	move	d0,d3
	beq.b	.lb_5f7c
	divu	d1,d3
	move	d3,d0
.lb_5f7c	swap	d0
	move	d0,d3
	divu	d1,d3
	move	d3,d0
	swap	d3
	move	d3,d1
	move.l	(a7)+,d3
	rts	

.lb_5f8c	swap	d1
	move	d2,-(a7)
	moveq	#16-1,d3
	move	d3,d2
	move.l	d1,d3
	move.l	d0,d1
	clr	d1
	swap	d1
	swap	d0
	clr	d0
.lb_5fa0	add.l	d0,d0
	addx.l	d1,d1
	cmp.l	d1,d3
	bhi.b	.lb_5fac
	sub.l	d3,d1
	addq	#1,d0
.lb_5fac	dbf	d2,.lb_5fa0
	move	(a7)+,d2
	move.l	(a7)+,d3
	rts	

;umult64 - mulu.l d0,d0:d1
;by Meynaf/English Amiga Board
mulu_64
     move.l d2,-(a7)
     move.w d0,d2
     mulu d1,d2
     move.l d2,-(a7)
     move.l d1,d2
     swap d2
     move.w d2,-(a7)
     mulu d0,d2
     swap d0
     mulu d0,d1
     mulu (a7)+,d0
     add.l d2,d1
     moveq #0,d2
     addx.w d2,d2
     swap d2
     swap d1
     move.w d1,d2
     clr.w d1
     add.l (a7)+,d1
     addx.l d2,d0
     move.l (a7)+,d2
 	rts

; udivmod64 - divu.l d2,d0:d1
; by Meynaf/English Amiga Board
divu_64
	move.l d3,-(a7)
 	moveq #31,d3
.loop
	 add.l d1,d1
	 addx.l d0,d0
 	bcs.s .over
 	cmp.l d2,d0
 	bcs.s .sui
 	sub.l d2,d0
.re
 	addq.b #1,d1
.sui
 	dbf d3,.loop
 	move.l (a7)+,d3	; v=0
 	rts
.over
 	sub.l d2,d0
 	bcs.s .re
 	move.l (a7)+,d3
 	or.b #4,ccr		; v=1
 	rts



* To discard too big random values quickly, "and" the value with a 
* suitable mask, based on amount of modules. Calculate the mask here.
getRandomValueMask
	move.l	randomValueMask(a5),d0 
	bne.b	.x
	move.l 	modamount(a5),d0 
	bsr.b	findHighestBit 
	add.l	d0,d0
	subq.l 	#1,d0
	move.l	d0,randomValueMask(a5)
.x	rts

* Find highest bit set in value
*
* in: 
*   d0 = value to check
* out: 
*   d0 = highest bit in value set
* example: 0x7f -> 0x40

findHighestBit
	push	d1
	move.l	d0,d1
	lsr.l	#1,d1
	or.l	d1,d0

	move.l	d0,d1
	lsr.l	#2,d1
	or.l	d1,d0

	move.l	d0,d1
	lsr.l	#4,d1
	or.l	d1,d0

	move.l	d0,d1
	lsr.l	#8,d1
	or.l	d1,d0

	move.l	d0,d1
	clr	d1
	swap	d1
	or.l	d1,d0

	move.l	d0,d1
	lsr.l	#1,d1
	sub.l	d1,d0
	pop	d1
	rts	



******************************************************************************
* Soitamoduuli 
* Play a module
* in:
*    d7 = step to move in the list, -1 to play previous, +1 to play next. 
****************

soitamodi_random:
	moveq	#1,d5 		* 1: force random
	moveq	#0,d6		* 0: allow volume fade down before startig to play new module
	bra.b	umph

* Called from "signalreceived". That is, when a module playback has ended.
soitamodi2:
	moveq	#-1,d6		* ~0: disable volume fade down before starting to play new module
	moveq	#0,d5		* 0: no forced random
	bra.b	umph

* Called based on user input
soitamodi:
	DPRINT  "Soitamodi"
	moveq	#0,d6		* 0: allow volume fade down
	moveq	#0,d5		* 0: no forced random
umph	
;	cmp.b	#$7f,do_early(a5)	* early load p‰‰ll‰? disable!
;	beq	.ags

 if DEBUG
	move.l	chosenmodule(a5),d0
	DPRINT	"play mod, chosen=%ld"
 endif

	tst	d5
	bne.b 	.raaps

	cmp.b	#pm_random,playmode(a5)	* onko satunnaissoitto?
	bne.b	.bere
.raaps	
	* randomize a module in chosenmodule(a5)
	bsr.w	satunnaismodi
	* set step to zero
	moveq	#0,d7
.bere
	* Calculate in long words to avoid possible word overflow.
	move.l	modamount(a5),d1

	* Calculate candidate for the next module
	move.l	chosenmodule(a5),d0
	add.l	d7,d0
	bpl.b	.e					* meni yli listan alkup‰‰st‰?
	* Result is negative. Wrap to the end of the list.
.getLast
	move.l	d1,d0
	subq.l	#1,d0
	bra.b	.ee
.e
	cmp.l	d1,d0
	blt.b	.ee
	* Result is higher than the amount of modules. Wrap to the beginning,
	* or end, depending on the movement direction.
	tst.l	d7
	bmi.b	.getLast
.getFirst
	moveq	#0,d0
.ee
	* Valid chosenmodule index found
	move.l	d0,chosenmodule(a5)
	DPRINT "->chosenmodule %ld"
	* Take a slot in the random table as well
	move.l	d0,d2					* store copy for later
	bsr.w	setRandomTableEntry		* Merkataan listaan..

;	st	hippoonbox(a5)
	bsr.w	resh

* etsit‰‰n listasta vastaava tiedosto
* find the corresponding file from the list

	DPRINT	"soitamodi getListNode"
	bsr.w	getListNode
	beq.w	.erer
	move.l	a0,a3

	* This might be a list divider. Try again in that case.
	;isListDivider l_filename(a3)	* onko divideri?
	tst.b	l_divider(a3)
	beq.b	.noDiv		* kokeillaan edellist‰/seuraavaa/rnd

	* try next one until at end of the list
	TSTNODE	a3,a0
	bne.w	umph
	bra.w	.erer
.noDiv

	cmp.l	playingmodule(a5),d2	* onko sama kuin juuri soitettava??
	bne.b	.new

	* It was the same one which already was playing.
	* Restart it from beginning.

* on!
	DPRINT	"Replay end"
	bsr.w	obtainModuleData
	bsr.w	halt			* soitetaan vaan alusta
	move.l	playerbase(a5),a0
	jsr 	p_end(a0)

	DPRINT	"Replay init"
	move.l	playerbase(a5),a0
	jsr	p_init(a0)
	bsr.w	releaseModuleData

	tst.l	d0
	bne.w	.inierr

	st	playing(a5)		* Ei varmaan tuu initerroria
	bsr.w	inforivit_play
	bsr.w	settimestart
	bsr.w	start_info
	rts
	
.new
	DPRINT	"New mod"

	* New module to be played.

	moveq	#0,d7			* flag for double buffering (0: no db)
	tst.l	playingmodule(a5)	* Oliko soitettavana mit‰‰n?
							* Was something being played?							
	bmi.b	.nomod

	* Yes. Stop and free it.

	tst	d6			* ei fadea jos signalreceivedist‰
	bne.b	.hm1

	move.b	doublebuf(a5),d7	* onko doublebuffering?
	bne.b	.nomod

	bsr.w	fadevolumedown
	move	d0,-(sp)
.hm1
	DPRINT	"Replay end"

	bsr.w	obtainModuleData
	bsr.w	halt			* Vapautetaan se jos on
	move.l	playerbase(a5),a0
	jsr	p_end(a0)
	bsr.w	releaseModuleData
	bsr.w	freemodule	

	tst	d6
	bne.b	.hm2
	move	(sp)+,mainvolume(a5)
.hm2

.nomod
	* Store index of the new module being played
	move.l	d2,playingmodule(a5)	* Uusi numero

	* a3 contains the list elment
	lea	l_filename(a3),a0	* Ladataan
	* load it, d7 contains double buffering flag
	move.b	d7,d0
	jsr	loadmodule
	tst.l	d0
	bne.b	.loader

	DPRINT	"Replay init"
	move.l	playerbase(a5),a0
	jsr	p_init(a0)
	tst.l	d0
	bne.b	.inierr

	bsr.w	settimestart
	st	playing(a5)
	bsr.w	inforivit_play
	bsr.w	start_info

.erer
;	bsr.w	shownames
	rts

.loader	
	* Load failed.
	* Did not get a module to play successfully.
	move.l	#PLAYING_MODULE_NONE,playingmodule(a5)
	rts


.inierr	
	DPRINT	"Replay init ERROR"

	* Replay init failed.
	* Did not get a module to play successfully.
	move.l	#PLAYING_MODULE_NONE,playingmodule(A5)	* initvirhe
	jmp	init_error


*** Early load

;.early
;	move.b	#$7f,do_early(a5)	* Next/Prev/Play soittavat
					* nyt ladatun piisin

* vanhat talteen
;	move.l	moduleaddress(a5),earlymoduleaddress(a5)
;	move.l	modulelength(a5),earlymodulelength(a5)
;	move.l	tfmxsamplesaddr(a5),earlytfmxsamples(a5)
;	move.l	tfmxsampleslen(a5),earlytfmxsamlen(a5)
;	move.b	lod_tfmx(a5),earlylod_tfmx(a5)


;	lea	l_filename(a3),a0	* Ladataan
;	move.l	l_nameaddr(a3),solename(a5)
;	moveq	#MEMF_CHIP,d0
;	lea	moduleaddress(a5),a1
;	lea	modulelength(a5),a2
;	moveq	#0,d1			* kommentti talteen
;	bsr.w	loadfile
;	tst.l	d0
;	beq	.ok

;	bsr	freeearly
;	clr.b	do_early(a5)
;	bra	loaderr

;.ok	bsr	inforivit_play
;	rts	


*******************************************************************************
* Asetataan arvot propgadgeteille
*******
nupit

* volume
	lea	slider1,a0
	move	#65535/64,d0		* 65535/max
	bsr.w	setknob
 ifeq EFEKTI
;	move	#65535*64/64,d0		* 65535*arvo/max
	moveq	#-1,d0
 else
	moveq	#0,d0
 endc
	bsr.w	setknob2

;	lea	slider4,a0
	lea	slider4-slider1(a0),a0
	move.l	gg_SpecialInfo(a0),a1
	move	#65535/1,pi_VertBody(a1)
;	move	#0,pi_VertPot(a1)
	clr	pi_VertPot(a1)

* mixingrate s3m
;	lea	pslider1,a0
	lea	pslider1-slider4(a0),a0
	moveq	#65535/(580-50),d0	* 65535/max
	bsr.w	setknob
	move	#65535*50/(580-50),d0	* 65535*arvo/max
	bsr.w	setknob2

* mixingrate tfmx
;	lea	pslider2,a0
	lea	pslider2-pslider1(a0),a0
	move	#65535/(22-1),d0		* 65535/max
	bsr.w	setknob
	move	#65535*11/21,d0		* 65535*arvo/max
	bsr.w	setknob2

* volumeboost s3m
;	lea	juusto,a0
	lea	juusto-pslider2(a0),a0
	;move	#65535/9,d0
	move	#65535/17,d0
	bsr.w	setknob
;	move	#65535/9*0,d0
	moveq	#0,d0
	bsr.w	setknob2

* stereoarvo s3m
;	lea	juust0,a0
	lea	juust0-juusto(a0),a0
	move	#65535/64,d0
	bsr.w	setknob
;	move	#65535/32*0,d0
	moveq	#0,d0
	bsr.w	setknob2

* boxsize
;	lea	meloni,a0
	lea	meloni-juust0(a0),a0
	move	#65535/(51-3),d0		* 65535/max
	bsr.w	setknob
	move	#65535*(8-3)/(51-3),d0		* 65535*arvo/max
	bsr.w	setknob2

* infosize
;	lea	eskimO,a0
	lea	eskimO-meloni(a0),a0
	move	#65535/(50-3),d0		* 65535/max
	bsr.b	setknob
	move	#65535*(16-3)/(50-3),d0		* 65535*arvo/max
	bsr.b	setknob2

* timeout
;	lea	kelloke,a0
	lea	kelloke-eskimO(a0),a0
	move	#65535/1800,d0			* 65535/max
	bsr.b	setknob
;	move	#65535*0/1800,d0		* 65535*arvo/max
	moveq	#0,d0
	bsr.b	setknob2

* alarm
;	lea	kelloke2,a0
	lea	kelloke2-kelloke(a0),a0
	moveq	#65535/1440,d0			* 65535/max
	bsr.b	setknob
;	moveq	#65535*0/1440,d0		* 65535*arvo/max
	moveq	#0,d0
	bsr.b	setknob2

* samplebuffersize
;	lea	sIPULI,a0
	lea	sIPULI-kelloke2(a0),a0
	move	#65535/5,d0		* 65535/max
	bsr.b	setknob
;	move	#65535*0/3,d0		* 65535*arvo/max
	moveq	#0,d0
	bsr.b	setknob2

* sample forced sampling rate
;	lea	sIPULI2,a0
	lea	sIPULI2-sIPULI(a0),a0
	moveq	#65535/600,d0		* 65535/max
	bsr.b	setknob
;	move	#65535*0/600,d0		* 65535*arvo/max
	moveq	#0,d0
	bsr.b	setknob2



* ahi rate
;	lea	ahiG4,a0
	lea	ahiG4-sIPULI2(a0),a0
	moveq	#65535/(580-50),d0	* 65535/max
	bsr.b	setknob
	move	#65535*50/(580-50),d0	* 65535*arvo/max
	bsr.b	setknob2

* ahi mastervol
;	lea	ahiG5,a0
	lea	ahiG5-ahiG4(a0),a0
	moveq	#65535/1000,d0		* 65535/max
	bsr.b	setknob
	moveq	#65535*1/1000,d0	* 65535*arvo/max
	bsr.b	setknob2

* ahi stereolev
;	lea	ahiG6,a0
	lea	ahiG6-ahiG5(a0),a0
	move	#65535/100,d0		* 65535/max
	bsr.b	setknob
;	move	#65535*00,d0		* 65535*arvo/max
	moveq	#0,d0
	bsr.b	setknob2

* MED rate
	lea	nAMISKA5-ahiG6(a0),a0
	moveq	#65535/(580-50),d0	* 65535/max
	bsr.b	setknob
	move	#65535*50/(580-50),d0	* 65535*arvo/max
	bsr.b	setknob2
	rts


* Vert.. Horiz..

setknob	move.l	gg_SpecialInfo(a0),a1
	move	d0,pi_HorizBody(a1)
	rts
setknob2
	move.l	gg_SpecialInfo(a0),a1
	move	d0,pi_HorizPot(a1)
	rts



nappilasku
	move.l	gg_SpecialInfo(a2),a0
	mulu	pi_HorizPot(a0),d0
	add.l	#32767,d0
	divu	#65535,d0
	and.l	#$ffff,d0
	rts




*******************************************************************************
* Nappulaa painettu, tehd‰‰n vastaava (gadgetti) toiminto
*******
* d3 = rawkey
* d4 = iequalifier

handleRawKeyInput
nappuloita

  REM
  if DEBUG
   	moveq   #0,d0
    	move.b	d3,d0
	moveq	#0,d1
 	move	d4,d1
  	DPRINT	"Raw key=%lx qual=%lx"
  endc 
  EREM
	and	#$ff,d3
	* mask out non-kb qualifiers
	and	#$ff,d4

	* react only if button is down
	tst.b	d3
	bmi.w	.exit	* vain jos nappula alhaalla
	movem.l	d0-a6,-(sp)

	cmp	#IEQUALIFIER_CONTROL,d4
	bne.b	.noControl

	cmp.b	#$23,d3		* f + control
	bne.b	.2
	jsr	toggleFavoriteStatusForCurrentModule
	bra.w	.ee
.2
	cmp.b	#$37,d3	 	* m + control
 	bne.b	.3
	jsr		modlandSearch
	bra	.ee
.3
 ifne FEATURE_UHC_AMINET
	cmp.b	#$20,d3	 	* a + control
 	bne.b	.4
	jsr		aminetSearch
	bra	.ee
.4
 endif
	

.noControl

	and.b	#IEQUALIFIER_LSHIFT!IEQUALIFIER_RSHIFT,d4
	beq.b	.noshifts

	cmp.b	#$37,d3		* m + shift
	bne.b	.1
	bsr.w	rlistmode
	bra.w	.ee
.1


	cmp.b	#$17,d3		* i + shift?
	bne.b	.f0
	; window will be opened active:
	or.l	#WFLG_ACTIVATE,sflags
	bsr.w	rbutton10b
	bra.b	.ee
.f0
	cmp.b	#$41,d3		* backspace + shift?
	beq.b	.fid
	cmp.b	#$22,d3		* d + shift?
	bne.b	.fi
.fid	bsr.w	rbutton8b
	bra.b	.ee
.fi

	cmp.b	#$39,d3		* onko shift + fast forward?
	beq.b	.if
	cmp.b	#$1f,d3
	bne.b	.no1f
.if	bsr.w	rbutton_kela2_turbo
	bra.b	.ee
.no1f

.noshifts
	cmp.b	#$23,d3		* [F]ind
	bne.b	.not_f
	tst.b	d4
	bne.b	.fi_c
	bsr.w	find_new
	bra.b	.ee
.fi_c	bsr.w	find_continue
	bra.b	.ee

.not_f
	cmp.b	#$50,d3		* Oliko funktion‰pp‰imi‰??
	blo.b	.f1
	cmp.b	#$59,d3
	bhi.b	.f1
	bsr.w	fkeyaction
	bra.b	.ee
.f1


	lea	.nabs(pc),a0	
.checke
	cmp	(a0)+,d3
	beq.b	.jee
	addq.l	#2,a0
	cmp.l	#.nabse,a0
	bne.b	.checke
	DPRINT	"No action for key"
.ee	movem.l	(sp)+,d0-a6
.sd	
.exit
	rts
.jee	
	move	(a0),d0
	add	d0,a0
	jsr	(a0)
	bra.b	.ee


* $13 r 	prefs

* return $44	play
* *, $2b (returnin vieress‰) play random module
* ylos $4c	lista ylos
* alas $4d	lista alas

* vas $4f	prev song
* oik $4e	next song
* k $27 	prev 
* l $28		next 

* s $10		add divider

* n $36		new

* d $22		delete module
* backspace $41	delete module
* space $40	stop/cont
* esc $45	exit program
* tab $42	eject module
* < $38		prev pattern -
* > $39		next pattern \kelaus
* a $20		add modules

* v $34		volume down
* b $35		volume up


* help $5f	about etc.
* c $33		clear list
* ~` $0		window shrink/expand
* 7 7	show: time - poslen 0	
* 8 8	show: kello/memory 1
* 9 9	show: name 2
* 0 $a 	show: time/duration - poslen
* i $17		moduleinfo
* f1-f10 $50-$59	Funktio-lataussoitto
* w $11		save modprogram
* o $19	 	load modprogram
* h $25		hide!)
* [ $1a		join modprogram

* m $37		move
* t $14		insert
* s $21		sort

* z $31		scope Ltoggle

* f $23		find module

* o $18		comment file

* g $24		play list repeatedly
* h $25		play mods in random order


********
* numeron‰ppis
* [ ] / *
* 7 8 9 -
* 4 5 6 +
* 1 2 3 E
* 000 . E
* 4 - prev song 	$2d
* 6 - next song		$2f
* 8 - select prev	$3e
* 2 - select next	$1e
* 7 - play prev		$3d
* 9 - play next		$3f
* 1 - rewind		$1d
* 3 - fast forward	$1f
* 5 - stop/cont		$2e
* 0 - add mods		$f
* * - random play	$5d
* - - vol down		$4a
* + - vol up		$5e
* enter - return	$43
* . - load program	$3c
* [ - del mod		$5a
* ] - move mod		$5b
* / - insert		$5c


.nabs

	dc	$12
	dr	execuutti


	dc	$13
	dr	rbutton20

	dc	$36
	dr	rbutton11

	dc	$24
	dr	.pm1
	dc	$25
	dr	.pm2	

	dc	$31 * z-key
	dr	.scopetoggle

	dc	$37
	dr	rmove
	dc	$14
	dr	rinsert
	dc	$21
	dr	rsort

	dc	$11
	dr	rsaveprog
	dc	$19
	dr	rloadprog
	dc	$1a
	dr	rloadprog0

	dc	$27
	dr	rbutton6	* prev
	dc	$28
	dr	rbutton5	* next
	dc	$4e
	dr	actionPrevSong	* prev song
	dc	$4f
	dr	actionNextSong	* next song

	dc	7
	dr	.showtime
	dc	8
	dr	.showclock
	dc	9
	dr	.showname
	dc	$a
	dr	.showtime2

	dc	$45
	dr	.qui

	dc	$44
	dr	rbutton1

	dc	$40
	dr	stopcont

	dc	$22
	dr	rbutton8
	dc	$41
	dr	rbutton8

	dc	$42
	dr	rbutton4

	dc	$38
	dr	rbutton_kela1
	dc	$39
	dr	rbutton_kela2

	dc	$4c
	dr	lista_ylos

	dc	$4d
	dr	lista_alas

	dc	$33
	dr	rbutton9

	dc	$20
	dr	rbutton7

	dc	$34
	dr	.voldown
	dc	$35
	dr	.volup

	dc	$5f
	dr	rbutton10
	dc	$17
	dr	.infoo

	dc	0
	dr	.ocl

	dc	$2b
	dr	.rand

	dc	$10
	dr	add_divider

	dc	$18
	dr	comment_file

*** Numeron‰ppis


	dc	$2f
	dr	actionPrevSong		* prev song
	dc	$2d
	dr	actionNextSong		* next song
	dc	$3e
	dr	lista_ylos	* select prev
	dc	$1e
	dr	lista_alas	* select next
	dc	$3d
	dr	rbutton6	* play prev
	dc	$3f
	dr	rbutton5	* play next
	dc	$1d
	dr	rbutton_kela1	* rewind
	dc	$1f
	dr	rbutton_kela2	* fast forward
	dc	$2e
	dr	stopcont	* stop/cont
	dc	$f
	dr	rbutton7	* add
	dc	$5d
	dr	.rand		* play random mod
	dc	$4a
	dr	.voldown	* volume down
	dc	$5e
	dr	.volup		* volume up
	dc	$43
	dr	rbutton1	* play
	dc	$3c	
	dr	rloadprog	* load program
	dc	$5a
	dr	rbutton8	* del mod
	dc	$5b
	dr	rmove		* move mod
	dc	$5c
	dr	rinsert		* insert mods
.nabse


.rand	bra.w	soitamodi_random


.qui	st	exitmainprogram(a5)
	rts

.ocl	bra.w	zipMainWindow



.showtime
	clr	lootamoodi(a5)
	bra.w	lootaa
.showclock
	move	#1,lootamoodi(a5)
	bra.w	lootaa
.showname
	move	#2,lootamoodi(a5)
	bra.w	lootaa
.showtime2
	move	#3,lootamoodi(a5)
	bra.w	lootaa


.scopetoggle
	jmp	toggleScopes

.pm1	move.b	#pm_repeat,playmode(a5)	* playmode pikan‰pp‰imet
.pm0	st	hippoonbox(a5)
	bra.w	shownames
.pm2	move.b	#pm_random,playmode(a5)
	bra.b	.pm0

*** Volume nappuloilla c ja v
.volup
	move	mainvolume(a5),d0
	addq	#1,d0
	cmp	#64,d0
	bls.b	.vol
	moveq	#64,d0
	bra.b	.vol
.voldown
	move	mainvolume(a5),d0
	subq	#1,d0
	bpl.b	.vol
	moveq	#0,d0
.vol
	move	slider1+gg_Flags,d1
	and	#GFLG_DISABLED,d1
	beq.b	.vo1
	rts

.vo1	move	d0,mainvolume(a5)
	bne.b	.ere
	moveq	#1,d0
.ere	bra.w	volumerefresh


.infoo
** modinfon infon avaus
	DPRINT	"modinfo KEY"
	bra	modinfoaaa
 REM
	tst	info_prosessi(a5)
	beq.b	.zz
	move.l	infotaz(a5),a0		* jos oli jo modinfo niin suljetaan
	cmp.l	#about_t,a0
	beq.b	.rrz
	bsr.w	sulje_info
	bra.b	.xz
.rrz	bra.w	start_info
.zz	clr.b	infolag(a5)
	bsr.w	rbutton10b
.xz	rts
 EREM


** stop/continue

stopcont
	tst.b	playing(a5)
	beq.w	actionContinue
	bra.w	actionStopButton


lista_ylos				* shiftin kanssa nopeempi!
	moveq	#1,d0		* lines to skip up
	and	#IEQUALIFIER_LSHIFT!IEQUALIFIER_RSHIFT,d4
	beq.b	.nsh
	tst	boxsize(a5)
	beq.b	.nsh
	move	boxsize(a5),d0
	lsr	#1,d0			* with shift, skip half of the box size
.nsh
	ext.l	d0
	move.l	chosenmodule(a5),d1

	sub.l	d0,d1
	bpl.b	.wasOk
	move.l	modamount(a5),chosenmodule(a5)
	subq.l	#1,chosenmodule(a5)
	bra.w		resh
.wasOk
	move.l	d1,chosenmodule(a5)
	bra.w	resh

lista_alas
	moveq	#1,d0		* lines to skip down
	and	#IEQUALIFIER_LSHIFT!IEQUALIFIER_RSHIFT,d4
	beq.b	.nsh
	tst	boxsize(a5)
	beq.b	.nsh
	move	boxsize(a5),d0
	lsr	#1,d0
.nsh
	ext.l	d0
	move.l	chosenmodule(a5),d1
	add.l	d0,d1

	move.l	modamount(a5),d0
	;cmp	chosenmodule(a5),d0
	cmp.l	d1,d0
	bhi.b	.ee
	moveq	#0,d1
	;clr	chosenmodule(a5)
.ee	
	move.l	d1,chosenmodule(a5)
	bra.w	resh


********* Window zip

zipMainWindow	tst.b	uusikick(a5)
	bne.b	.newo
	bsr.w	sulje_ikkuna		* Vaihdetaan ikkunan kokoa
	bra.w	avaa_ikkuna
.newo	move.l	windowbase(a5),a0	* Kick2.0+
	move.l	_IntuiBase(a5),a6
	jmp	_LVOZipWindow(a6)

************************************** Funktion‰pp‰imet!

fkeyaction
	sub.b	#$50,d3
	ext	d3
	mulu	#120,d3
	lea	fkeys(a5),a0
	add.l	d3,a0
	tst.b	(a0)
	bne.b	.oli
	rts

.oli	move.l	a0,sv_argvArray+4(a5)		* Parametri!
	clr.l	sv_argvArray+8(a5)

	bsr.w	rbutton9		* freelist & shownames
	bsr.w	rbutton4		* EJECT!

	bra.w	komentojono			* tutkitaan komentojono.


*******************************************************************************
* Jotain gadgettia painettu, tehd‰‰n vastaava toiminto
* Gadget activated
*******
* in:
*   a2 = intuition gadget

gadgetsup
	bsr.w	    areMainWindowGadgetsFrozen
	bne.b 	.exit

	movem.l	d0-a6,-(sp)

	* Deactivate tooltips for the gadget that was activated
	* until some other gadget tooltip gets shown.
	move.l	a2,disableTooltipForGadget(a5)
	* Any button activity should first close any active tooltip
	bsr.w	closeTooltipPopup

	move	gg_GadgetID(a2),d0
	add	d0,d0
	lea	.gadlist-2(pc,d0),a0
	add	(a0),a0
	jsr	(a0)

	movem.l	(sp)+,d0-a6
.exit 
	rts
	
.gadlist	
	dr	rbutton1	* play
	dr	modinfoaaa	* modinfo toggle
	dr	stopcont	* stop/continue
	dr	rbutton4	* eject
	dr	rbutton5	* next
	dr	rbutton6	* prev
	dr	rbutton7	* add
	dr	rbutton8	* del
	dr	rslider1	* volume
	dr	rslider4	* fileselector
	dr	rbutton13	* Prev Song
	dr	rbutton12	* Next Song
	dr	rbutton11	* New
	dr	rbutton20	* Prefs
	dr	rbutton_kela1	* Taaksekelaus
	dr	rbutton_kela2	* Eteenkelaus
	dr	rloadprog	* ohjelman lataus
	dr	rmove		* move
	dr	rsearchfuncs	* search functions
	dr	rlistmode	* listmode change

* Print some text into the filebox
** a0 = teksti, d0 = x-koordinaatti
printbox:
	tst.b	win(a5)
	beq.b	.q
	tst	boxsize(a5)
	bne.b	.p
.q	rts
.p	pushm	d0/a0
	bsr.w	clearbox		* fileboxi tyhj‰ks
	popm	d0/a0
	moveq	#69+WINY,d1	
	tst.b	altbuttonsUse(a5)
	beq.b	.noAlt1
 	add	#16,d1
.noAlt1
 	move	boxsize(a5),d2
	lsr	#1,d2
	subq	#1,d2
	mulu	listFontHeight(a5),d2
	add	d2,d1
	bra.w	print

rlistmode
	jmp	toggleListMode



*******************************************************************************
* Sortti
*******

* This creates an array of
* 4 bytes  = node pointer to the module entry,
* 28 bytes = calculated weight based on module name,
* sorts that, and recreates the module list.

SORT_WEIGHT_LENGTH = 28
SORT_ELEMENT_LENGTH = 4+SORT_WEIGHT_LENGTH

 if SORT_ELEMENT_LENGTH<>32
	fail 
 endif


rsort
sortButtonAction
	cmp.b	#LISTMODE_BROWSER,listMode(a5)
	bne.b	.1
	DPRINT	"Sort disabled in file browser"
	rts
.1
	skipIfGadgetDisabled gadgetSortButton
	bsr.b	sortModuleList
	bra.w	forceRefreshList

sortModuleList:
	* Skip force refresh

	* Let's not sort a list with 1 module, that would be silly I guess.
	cmp.l	#2,modamount(a5)
	bhs.b	.so
	rts
.so
	bsr.w	lockMainWindow

	* Skip info display in these cases
	cmp.l	#100,modamount(a5)
	blo.b	.d
	* Annoying to see the text flashing rapidly
	* when browsing
	cmp.b	#LISTMODE_BROWSER,listMode(a5)
	beq.b	.d
	
	lea	.t(pc),a0
	moveq	#102+WINX,d0
	bsr		printbox
	bra.b	.d
.t	dc.b	"Sorting...",0
 even

.d
	move.l	modamount(a5),d0
	moveq	#SORT_ELEMENT_LENGTH,d1		* node address and weight
	bsr.w	mulu_32		* 
	addq.l	#8,d0			* add some empty space, this is needed when rebuilding the list
							* to check if end is reached.
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	bsr.w	getmem
	move.l	d0,sortbuf(a5)
	bne.b	.okr
	bsr.w 	showOutOfMemoryError
	bra.w	.error
.okr

	move.l	d0,a2


** Lasketaan painot jokaiselle
	DPRINT  "rsort obtain list"
	bsr.w	obtainModuleList
	;lea	moduleListHeader(a5),a3
	bsr.w	getVisibleModuleListHeader
	move.l	a0,a3
 
 if DEBUG
	clr.l	.swaps
	clr.l	.comps
 endif

* paino 24 bytee

	* sort table in a2
	move.l	a2,a4

	move.l	(a3),a3		* MLH_HEAD
.ploop
	tst.l	(a3)		* check if last node?
	beq.b	.ep

	* Fill slot at a4
	move.l	a4,a2
	move.l	a3,(a2)+	* noden osoite taulukkoon

	* Calculate value based on l_nameaddr in given node a3,
	* write it in (a2)+
	bsr.w	.getWeight
	
	* Remove node from list
	move.l	a3,a1		* poistetaan node (a1)
	REMOVE

	* get next node
	SUCC	a3,a3
	* next slot in table
	lea		SORT_ELEMENT_LENGTH(a4),a4
	bra.b	.ploop
.ep
	* Weights done
	* Now sort in divider sections

	move.l	sortbuf(a5),a3

.ml	moveq	#0,d5		* 1. sortattava node
	moveq	#0,d6		* viimeinen sortattava node

	bsr.w	.eka
	bne.b	.loph

	move.l	a3,d5

	bsr.w	.toka

	move.l	a3,d7
	sub.l	d5,d7		* montako nodea sortataan

	* Nodes count
	lsr.l	#5,d7	; /32 - SORT_ELEMENT_LENGTH

;	subq	#1,d7		* 1 pois (listan loppu tai seuraava divideri)
	cmp.l	#2,d7		* v‰h 2 kpl
	blo.b	.ml

	move.l	d5,a2
	bsr.w	.sort
	bra.b	.ml

.loph

	* Start rebuilding the list with sorted nodes
	move.l	sortbuf(a5),a3
	bsr.w	getVisibleModuleListHeader
	move.l	a0,a2
.er
	tst.l	(a3)
	beq.b	.r			* end reached? this is the extra space mentioned above
	move.l	(a3),a1  	* grab node address

	* Add a1 to a0
	move.l	a2,a0
	ADDTAIL			* lis‰t‰‰n node (a1)

	lea SORT_ELEMENT_LENGTH(a3),a3	
	bra.b	.er
.r
	move.l	sortbuf(a5),a0
	bsr.w	freemem

.error

	bsr.w	listChanged
	tst.l	playingmodule(a5)
	bmi.b	.npl
	move.l	#PLAYING_MODULE_REMOVED,playingmodule(a5)
.npl	clr.l	chosenmodule(a5)
	
 if DEBUG
	move.l	.swaps(pc),d1
	move.l	.comps(pc),d0
	DPRINT	"Compares=%ld swaps=%ld"
 endif

	DPRINT  "rsort release list"
	bsr.w	releaseModuleList
	bsr.w	unlockMainWindow
	rts

* a3 = lista
* Hakee ensimm‰isen nimen, joka ei ole divideri

.eka
.ploop2
	tst.l	(a3)		* Oliko viimeinen
	beq.b	.ep2
	move.l	(a3),a0
	tst.b	l_divider(a0)
	beq.b	.jep1
	* Ignore dividers in browser mode
	cmp.b	#LISTMODE_BROWSER,listMode(a5)
	beq.b	.jep1

	lea	SORT_ELEMENT_LENGTH(a3),a3
	bra.b	.ploop2

.ep2	moveq	#-1,d0
	rts
.jep1	moveq	#0,d0
	rts

* Hakee dividerin tai listan lopun a3:een

.toka
.ploop3
	tst.l	(a3)		* Oliko viimeinen
	beq.b	.jep1
	move.l	(a3),a0
	* Ignore dividers in browser mode
	cmp.b	#LISTMODE_BROWSER,listMode(a5)
	beq.b	._d
	tst.b	l_divider(a0)
	bne.b	.jep1
._d
	lea	SORT_ELEMENT_LENGTH(a3),a3
	bra.b	.ploop3


*--------------------

.sort
	pushm	all
 	bsr.b	.sort0
 	popm	all
	rts

 if DEBUG
.swaps	dc.l	0
.comps	dc.l	0
 endif

* in:
*   a2 = start of array
*   d7 = number of items to sort
.sort0
	move.l	a2,a0
	moveq	#SORT_ELEMENT_LENGTH,d5		* element length
	moveq	#1,d4

; Comb sort the array.

;	Lea.l	List(Pc),a0
;	Move.l	#ListSize,d7	; Number of values

	Move.l	d7,d1		; d1=Gap
.MoreSort
;	lsl.l	#8,d1
;	Divu.w	#333,d1		; 1.3*256 = 332.8
;	ext.l	d1

	move.l	d1,d0 
	lsl.l	#8,d0 
	move.l	#333,d1
	bsr.w 	divu_32
	move.l	d0,d1

	MoveQ	#0,d0		; d0=Switch

	Cmp.l	d4,d1		; if gap<1 then gap:=1
	Bpl.b	.okgap
	Moveq	#1,d1
.okgap:
	Move.l	d7,d2		; d2=Top
	Sub.l	d1,d2		; D2=NMAX-gap
	Move.l	a0,a1

 ;     Lea.l   (a1,d1.w*2),a2  ; a2=a1+gap
 ;   move    d1,d6
 ;   mulu    d5,d6
 ;   lea     (a1,d6.l),a2

	move.l	d1,d6
	lsl.l	#5,d6 * x32 - SORT_ELEMENT_LENGTH
	lea		(a1,d6.l),a2
 
.Loop:	
	* Compare. 
	* It's likely the compares after the 1st one are not often hit.
 if DEBUG
	addq.l	#1,.comps
 endif
	move.l	4(a1),d3
	cmp.l	4(a2),d3
	bne.b	.notokval
	move.l	8(a1),d3
	cmp.l	8(a2),d3
	bne.b	.notokval
	move.l	12(a1),d3
	cmp.l	12(a2),d3
	bne.b	.notokval
	move.l	16(a1),d3
	cmp.l	16(a2),d3
	bne.b	.notokval
	move.l	20(a1),d3
	cmp.l	20(a2),d3
	bne.b	.notokval
	move.l	24(a1),d3
	cmp.l	24(a2),d3
	bne.b	.notokval
	move.l	28(a1),d3
	cmp.l	28(a2),d3
	beq.b	.okval
.notokval
	bmi.b	.okval

 if DEBUG
	addq.l	#1,.swaps
 endif

;	Move.w	(a1)+,d3
;	Cmp.w	(a2)+,d3
;	Bmi	.okval
;	Beq	.okval

;	Move.w	-2(a1),d3	; swap
;	Move.w	-2(a2),-2(a1)
;	Move.w	d3,-2(a2)

** swap 32 bytes: 
* - node pointer
* - 28 bytes of weight

	* swap 32 bytes
	* free:
	* d0, d3, d6, a3, a4, a5, a6
	movem.l		(a1),d0/d3/d6/a3/a4/a5/a6
 	move.l		(a2)+,(a1)+
 	move.l		(a2)+,(a1)+
 	move.l		(a2)+,(a1)+
 	move.l		(a2)+,(a1)+
 	move.l		(a2)+,(a1)+
 	move.l		(a2)+,(a1)+
 	move.l		(a2)+,(a1)+
 	movem.l		d0/d3/d6/a3/a4/a5/a6,-7*4(a2)
	* swap remaining 4 bytes
 	move.l	(a1),d6
	move.l	(a2),(a1)+
	move.l	d6,(a2)+

	Moveq	#1,d0
	bra.b	.ok1

.okval:
	add.l	d5,a1
	add.l	d5,a2
.ok1

	subq.l	#1,d2 
	bne.b	.Loop

	Cmp.l	d4,d1		; gap < 1 ?
	Bne.w	.MoreSort
	Tst.w	d0		; Any entries swapped ?
	Bne.w	.MoreSort
	Rts

*-------------------

* Calculates the weight for an item for sorting
* in:
*   a3 = list node
* out:
*   (a2)+ = 28 bytes in this address

* Lower case and strip prefix so that string is usable for sorting
.getWeight	
	move.l	l_nameaddr(a3),a0

	* In normal case dividers have no value when sorting,
	* in brower mode they should be sorted properly.
	cmp.b	#LISTMODE_BROWSER,listMode(a5)
	beq.b	.browserMode
	tst.b	l_divider(a3)
	beq.b	.boobo
	* dividers ignored
	rts

	* In browser mode modify name so that
	* directories get sorted before files
.browserMode
	tst.b	l_divider(a3)
	beq.b	.notDiv
	lea	-(SORT_WEIGHT_LENGTH+2)(sp),sp
	move.l	sp,a1
	moveq	#SORT_WEIGHT_LENGTH-1,d0
	move.b	#DIVIDER_MAGIC,(a1)+
.cp_	
	move.b	(a0)+,(a1)+
	dbeq	d0,.cp_
	move.l	sp,a0
	bsr.b	.doGetV		
	lea	SORT_WEIGHT_LENGTH+2(sp),sp
	rts
.notDiv
.boobo
.doGetV
	* in/out: a0
	bsr.w	cut_prefix

	moveq	#SORT_WEIGHT_LENGTH-1,d0
	moveq	#'a',d2
	moveq	#'z',d3
	move.b	#$df,d4

	* Copy string as upper case into the weight array
	* for case insensitive comparison
.doV
	move.b	(a0)+,d1
	cmp.b	d2,d1
	blo.b	.z
	cmp.b	d3,d1
	bhi.b	.z
	* Lower case detected, convert it
	and.b	d4,d1
.z	move.b	d1,(a2)+
	dbeq	d0,.doV
	rts


*******************************************************************************
* Move
*******
rmove
moveButtonAction
	skipIfGadgetDisabled gadgetMoveButton

	tst.b	movenode(a5)	* Jos toistamiseen painetaan, menn‰‰n "play"hin
	bne.w	rbutton1

	cmp.l	#2,modamount(a5)
	blo.b	.qq
	bsr.w	getcurrent
	beq.b	.q
	move.l	a3,nodetomove(a5)
 if DEBUG
	move.l	l_nameaddr(a3),d0
	DPRINT	"moving %s"
 endc
	st	movenode(a5)
	move.l	a3,a1
	lore	Exec,Remove
	subq.l	#1,modamount(a5)
	bsr.w	listChanged
	tst.l	playingmodule(a5)
	bmi.b	.q
	move.l	#PLAYING_MODULE_REMOVED,playingmodule(a5)
.q	
	bsr.w	forceRefreshList
.qq	rts



* etsit‰‰n listasta vastaava kohta
;	DPRINT  "getcurrent obtain list"
; 	bsr.w		obtainModuleList
; 	lea	er(a5),a4
; .luuppo
; 	TSTNODE	a4,a3
; 	beq.b	.q
; 	move.l	a3,a4
; 	;dbf	d0,.luuppo
; 	subq.l	#1,d0 
; 	bpl.b  .luuppo
; 	DPRINT  "getcurrent release list 1"
; 	bsr.w		releaseModuleList
* a3 = valittu nimi
; 	moveq	#1,d0
; 	rts
; .q	
; 	DPRINT  "getcurrent release list 2"
; ;	bsr.w		releaseModuleList
; 	moveq	#0,d0
; 	rts



*******************************************************************************
* Comment file
*******

comment_file
	bsr.w	getcurrent
	beq.b	.x
	move.l	a3,a4

** kaapataan vanha kommentti

	moveq	#0,d4
	pushpea	l_filename(a3),d1
	moveq	#ACCESS_READ,d2
	lore	Dos,Lock
	move.l	d0,d4
	beq.b	.ne

	move.l	d4,d1
	pushpea	fileinfoblock(a5),d2
	lob	Examine

	move.l	d4,d1
	beq.b	.ne
	lob	UnLock
.ne

	bsr.w	get_rt
	lea	-90(sp),sp

** initial string
	lea	fileinfoblock+fib_Comment(a5),a0
	move.l	sp,a1
.c	move.b	(a0)+,(a1)+
	bne.b	.c

	move.l	sp,a1
	moveq	#79,d0		* max chars
	sub.l	a3,a3
	lea	ftags(pc),a0
	lea	.ti(pc),a2
	bsr.w	setMainWindowWaitPointer
	lob	rtGetStringA
	tst.l	d0
	beq.b	.xx

	pushpea	l_filename(a4),d1
	move.l	sp,d2
	lore	Dos,SetComment
	
.xx	bsr.w	clearMainWindowWaitPointer
	lea	90(sp),sp
.x	rts

.ti	dc.b	"Enter file comment",0
 even

	

*******************************************************************************
* Find module
*******

rsearchfuncs
	DPRINT	"Search functions"
	lea		.options(pc),a4
	lea		gadgetSortButton,a0
	move	gg_LeftEdge(a0),d6
	moveq	#20,d7
	add		gg_TopEdge(a0),d7
	pushpea	.callback(pc),d4
	bsr		listSelectorMainWindow
	bmi.b	.skip
	beq		find_new
	subq	#1,d0
	beq		find_continue
	subq	#1,d0
	beq.b	.modland
 ifne FEATURE_UHC_AMINET
	subq	#1,d0
	beq.b	.aminet
 endif
.skip
	rts

.modland
	jmp	modlandSearch
 ifne FEATURE_UHC_AMINET
.aminet
	jmp	aminetSearch
 endif

* in:
*   d3 = index to check
.callback
	; Disable bottom two rows if UHC not available
	cmp		#2,d3
	blo.b	.n
	tst.b	uhcAvailable(a5)
	bne.b	.n
	moveq	#0,d0
	rts
.n	moveq	#1,d0
	rts

.options
	* max width, rows
 ifne FEATURE_UHC_AMINET
	dc.b	24,4
 else
	dc.b	24,3
 endif
	dc.b	"Search list    [F]      ",0
	dc.b	"Search next    [SHIFT+F]",0
	dc.b	"Search Modland [CTRL+M] ",0
 ifne FEATURE_UHC_AMINET
 	dc.b	"Search Aminet  [CTRL+A] ",0
 endif

enterSearchPattern_t
	dc.b	"Enter search pattern",0
 even

find_new
	cmp.l	#3,modamount(a5)
	bhi.b	.ok
	rts
.ok
	bsr.w	get_rt
	lea	findpattern(a5),a1	
	moveq	#27,d0
	sub.l	a3,a3
	lea	ftags(pc),a0
	lea	enterSearchPattern_t(pc),a2
	bsr.w	setMainWindowWaitPointer
	lob	rtGetStringA
	bsr.w	clearMainWindowWaitPointer
	tst.l	d0
	bne.b	find_continue	
	rts

ftags
	dc.l	RTGS_Width,262
	dc.l	RT_TextAttr,text_attr
otag15	dc.l	RT_PubScrName,pubscreen+var_b
	dc.l	TAG_END
	


find_continue
	cmp.l	#3,modamount(a5)
	bhi.b	.ok
	rts
.ok
	bsr.w	setMainWindowWaitPointer
	pea	clearMainWindowWaitPointer(pc)

	; Use chosen module as starting point of seardh

	DPRINT  "find_continue obtain list"
	bsr.w	obtainModuleList

	bsr.w	getcurrent		* a0 => chosen module listnode
	tst.l	d0 
	bne.b	.foundCurrent
	* start from beginning
	clr.l	chosenmodule(a5)
	bsr.w	getcurrent
.foundCurrent

	move.l	a0,a3
	move.l	a3,a4

	move.l	chosenmodule(a5),d7
;	subq	#1,d7

	move	#$df,d2

.luuppo
	addq.l	#1,d7
	TSTNODE	a4,a3
	beq.b	.qq
	move.l	a3,a4
	bsr.b	.find
	bne.b	.luuppo
	bra.b	.q
.qq
* lista l‰pi eik‰ lˆytyny. k‰yd‰‰n alusta l‰htˆkohtaan.

	moveq	#-1,d7
	bsr.w	getVisibleModuleListHeader
	move.l	a0,a4
.luuppo2
	addq.l	#1,d7
	cmp.l	chosenmodule(a5),d7
	beq.b	.q
	TSTNODE	a4,a3
	beq.b	.q
	move.l	a3,a4
	bsr.b	.find
	bne.b	.luuppo2

.q	
	DPRINT  "find_continue release list"
	bsr.w 	releaseModuleList
	rts


.find
	move.l	l_nameaddr(a3),a0

.flop1	lea	findpattern(a5),a1
	move.b	(a1)+,d0
	and.b	d2,d0

.flop2	move.b	(a0)+,d1
	beq.b	.notfound
	and.b	d2,d1
	cmp.b	d0,d1
	bne.b	.flop2
	
.flop3	move.b	(a1)+,d0
	beq.b	.found
	and.b	d2,d0
	move.b	(a0)+,d1
	beq.b	.notfound
	and.b	d2,d1
	cmp.b	d0,d1
	beq.b	.flop3
	subq	#1,a0
	bra.b	.flop1

.notfound
	moveq	#-1,d0
	rts

.found	
	move.l	d7,chosenmodule(a5)
 if DEBUG
	move.l	d7,d0
	DPRINT	"Found module at %ld"
 endc
	bsr.w	forceRefreshList
	moveq	#0,d0
	rts




*******************************************************************************
* Kelaus
*******
rbutton_kela1
	tst.b	playing(a5)
	beq.b	.e
	tst.l	playingmodule(a5)
	bmi.b	.e
	st	kelattiintaakse(a5)
	move.l	playerbase(a5),a0
	jsr	p_taakse(a0)	
.e	rts

rbutton_kela2_turbo
	move.b	#1,kelausvauhti(a5)
	tst.b	playing(a5)
	beq.b	.e
	tst.l	playingmodule(a5)
	bmi.b	.e
	move.l	playerbase(a5),a0
	move	p_liput(a0),d0
	btst	#pb_ciakelaus2,d0
	beq.b	.nr
	not.b	kelausnappi(a5)
	rts

.nr	move.b	#2,kelausvauhti(a5)
	bra.b	rkelr

.e	rts


rbutton_kela2
	move.b	#1,kelausvauhti(a5)
rkelr

	tst.b	playing(a5)
	beq.b	.e
	tst.l	playingmodule(a5)
	bmi.b	.e
	move.l	playerbase(a5),a0
	move	p_liput(a0),d0
	btst	#pb_ciakelaus,d0
	beq.b	.norm
	not.b	kelausnappi(a5)
	rts

.norm	jmp	p_eteen(a0)	
.e	rts

*******************************************************************************
* New
*******
newButtonAction
rbutton11
	skipIfGadgetDisabled gadgetNewButton
	st	new(a5)
;	bsr.w	rbutton9		* Clear list
	bra.w	rbutton1		* Play


*******************************************************************************
* P‰ivitet‰‰n propgadgetteja, kun liikutaan hiirell‰
*******
mousemoving
	movem.l	d0-a6,-(sp)
;	DPRINT	"mousemove"
	lea	slider1,a2
	bsr.w	rslider1
	lea	slider4,a2
	bsr.w	rslider4
	bsr.w	tooltipHandler
	movem.l	(sp)+,d0-a6
	rts


*******************************************************************************
* Next
*******
nextButtonAction:
rbutton5
	moveq	#1,d7		* liikutaan eteenp‰in listassa
	bra.w	soitamodi

*******************************************************************************
* Prev
*******
prevButtonAction:
rbutton6
	moveq	#-1,d7		* liikutaankin taakkep‰in listassa
	bra.w	soitamodi


*******************************************************************************
* Song number <
*******
actionNextSong
rbutton12
	moveq	#1,d1		* lis‰t‰‰n songnumberia

songSkip
	tst.l	playingmodule(a5)
	bmi.b	.nosong

	clr.b	kelausnappi(a5)

	* this is reversed! TODO: FIX?
	move	songnumber(a5),d0
	sub	d1,d0

	move	minsong(a5),d1 
	move	maxsongs(a5),d2
	bsr.w	clampWord

	DPRINT	"New song: %ld"
	move	d0,songnumber(a5)

	st	kelattiintaakse(a5)
	clr.b	playing(a5)
	move.l	playerbase(a5),a0
	jsr	p_song(a0)
	st	playing(a5)
	st	kelattiintaakse(a5)
	bsr.w	settimestart

	bsr.w	inforivit_play
.err	
	bsr.w	lootaan_aika
.nosong
	rts


*******************************************************************************
* Song number >
*******
actionPrevSong
rbutton13
	moveq	#-1,d1			* v‰hennet‰‰n songnumberia
	bra.b	songSkip


******************************************************************************
* Stop
*******
actionStopButton
rbutton3
	tst.l	playingmodule(a5)
	bpl.b	.hu
.hehe	rts
.hu	
	DPRINT	"stop"

	clr.b	kelausnappi(a5)

	move.l	playerbase(a5),a0
	moveq	#pf_stop,d0
	and	p_liput(a0),d0
	beq.b	.hehe

	bsr.w	fadevolumedown
	move	d0,-(sp)

	* The "playing" flags is polled in the interrupts.
	clr.b	playing(a5)
	move.l	playerbase(a5),a0
	jsr	p_stop(a0)
	
	move	(sp)+,mainvolume(a5)

	bra.w	inforivit_pause
;.hehe	rts

*******************************************************************************
* Cont
*******
actionContinue
	tst.l	playingmodule(a5)
	bpl.b	.hu
.hehe	rts
.hu	
	DPRINT	"continue"

	clr.b	kelausnappi(a5)

	move.l	playerbase(a5),a0
	moveq	#pf_cont,d0
	and	p_liput(a0),d0
	beq.b	.hehe

	st	playing(a5)
	move.l	playerbase(a5),a0
	jsr	p_cont(a0)

	bsr.w	fadevolumeup

	bra.w	inforivit_play
;	rts
	
*******************************************************************************
* Eject
*******
rbutton4b
	moveq	#1,d0		* fade volume: no
	bra.b	rbutton4a

ejectButtonAction
rbutton4
	moveq	#0,d0		* fade volume: allowed
rbutton4a
	DPRINT	"Eject button action"
	clr.b	kelausnappi(a5)

	tst.l	playingmodule(a5)
	bpl.b	.hu
	bra.w	freemodule
.hu	
	tst	d0
	bne.b	.nofa

	bsr.w	fadevolumedown

.nofa	move	d0,-(sp)
	DPRINT	"Replay end (eject)"

	lore    Exec,Disable
	bsr.w	halt
	move.l	#PLAYING_MODULE_NONE,playingmodule(a5)
	lore    Exec,Enable
	move.l	playerbase(a5),d0
	move.l	playerbase(a5),a0
	jsr	p_end(a0)
	
	bsr.w	freemodule
	move	(sp)+,mainvolume(a5)
	clr.b	movenode(a5)
	rts


*******************************************************************************
* Tyhjennet‰‰n moduulista
*******
rbutton9
	DPRINT	"clearListButtonAction"
	skipIfGadgetDisabled gadgetNewButton
	bsr.w	confirmFavoritesModification
	bne.b	clearlist
	rts

clearlist
	clr.b	movenode(a5)
	DPRINT  "clearlist"
	bsr.w	setMainWindowWaitPointer
	cmp.b	#LISTMODE_FAVORITES,listMode(a5)
	beq.b	.isFav
	bsr.w	freelist
	bra.b	.done 
.isFav
	jsr	freeFavoriteList
.done
	DPRINT "clearlist done"
	bsr.w	clearMainWindowWaitPointer
	bra.w	shownames

*******************************************************************************
* Volumegadgetti
*******
rslider1
	move.l	gg_SpecialInfo(a2),a0
	move	pi_HorizPot(a0),d0
	cmp	slider1old(a5),d0
	bne.b	.new
	rts
.new	move	d0,slider1old(a5)
	moveq	#64,d0		* max
	bsr.w	nappilasku
	move	d0,mainvolume(a5)

	tst.l	playingmodule(a5)
	bmi.b	.ee
	move.l	playerbase(a5),a0
	jsr	p_volume(a0)
.ee	
	rts



*** D0 = volume
*** Uusi volumearvo ja sliderin p‰ivitys
volumerefresh
	cmp	#64,d0
	blo.b	.r
	moveq	#64,d0
.r	move	d0,mainvolume(a5)

	mulu	#65535,d0
	divu	#64,d0
	lea	slider1,a0
	move.l	gg_SpecialInfo(a0),a1
	move	d0,d1

	tst.b	win(a5)
	beq.b	.nw

	move	pi_Flags(a1),d0
	move	pi_HorizBody(a1),d3
	moveq	#0,d2
	moveq	#0,d4
	move.l	windowbase(a5),a1
	sub.l	a2,a2
	moveq	#1,d5
	lore	Intui,NewModifyProp
.nw
	tst.b	playing(a5)
	beq.b	.k
	move	mainvolume(a5),d0
	move.l	playerbase(a5),a0
	jsr	p_volume(a0)
.k	rts



*******************************************************************************
* Fileselectorgadgetti
*******
* Calculates the first visible filename based on slider position

rslider4
	move.l	gg_SpecialInfo(a2),a0
	move	pi_VertPot(a0),d0
	cmp	slider4old(a5),d0
	bne.b	.new
.q	rts
.new	move	d0,slider4old(a5)

	* Map VertPot [0..$ffff] to [0..modamount-boxsize].
	* This calculation will not fit into 32 bits if modamount is 0x1ffff.
	* Will be ok if we scale VertPot down one bit.
	* Take scaling into account later below as well.

	and.l	#$ffff,d0
	;DPRINT "slider4 mouse, VertPot=%lx"

	lsr.l	#1,d0		* [0..$7fff]

	move.l	modamount(a5),d1
	moveq	#0,d2
	move	boxsize(a5),d2
	sub.l	d2,d1
	bpl.b	.e
	moveq	#0,d1
.e
	bsr.w 	mulu_32
	add.l	#32767>>1,d0		* round upwards
	move.l	#65535>>1,d1 
	bsr.w	divu_32

	cmp.l	firstname(a5),d0
	beq.b	.q
	move.l	d0,firstname(a5)
	bra.w	showNamesNoCentering

*******************************************************************************
* Suhteutetaan nuppi tiedostojen m‰‰r‰‰n
* Asetetaan valitun nimen kohdalle
*******

forceRefreshList:
	DPRINT	"forceRefreshList"
	st	hippoonbox(a5)


resh:	pushm	all
	bsr.w	shownames
	bsr.b	reslider
	popm	all
	rts

* Resizes the box slider gadget according to the amount of modules in it
reslider

	* Calculate pi_vertBody, the vertical size of the prop gadget.
	move.l	modamount(a5),d0
	bne.b	.e
	moveq	#1,d0
.e
	moveq	#0,d1
	move	boxsize(a5),d1
	beq.w	.eiup

	cmp.l	d1,d0		* v‰h boxsize
	bhs.b	.ok
	move.l	d1,d0
.ok
	lsl.l	#8,d0
	bsr.w	divu_32
 	
	move.l	d0,d1
	move.l	#65535<<8,d0
	bsr.w	divu_32
	move.l	d0,d1
	bsr.w	.ch

 	; VertPot should be in range 0..$ffff

	lea	slider4,a0
	move.l	gg_SpecialInfo(a0),a1
	cmp	pi_VertBody(a1),d0
	sne	d4		* did it change compared to previous?
	lsl	#8,d4
	move	d0,pi_VertBody(a1)

* Below a historical comment line expressing joy:

*** Toimii vihdoinkin!

	* Calculate pi_vertPot, the vertical position of the prop gadget.
	* calculations will not fit into 32-bits if firstname is over 0xffff.
	* scale calculations down with 1 bit.

	* vertpot = (first name index) * 65535 / (modamount-boxsize)
	* modamount: 10000
	* boxsize: 20
	* firstname: 10000-20
	* ->
	* (10000-20)*(65535/2)/((10000/2)-20/2) = 0xffff

	move.l	firstname(a5),d0
	* scale down, +1 is needed to round upwards
	* as the fractions get floored off
	move.l	#65535,d1  * scale 
	;bsr.w	mulu_32
	bsr.w	mulu_64
	* d0:d1 now has a 64-bit value 

	move.l	modamount(a5),d2
	moveq	#0,d3
	move	boxsize(a5),d3 
	sub.l	d3,d2
	bgt.b	.positive	* check if over 0
	moveq	#1,d2	 	* avoid zero division
.positive

;	bsr.w	divu_32  * d0=d0/d1
	bsr.w	divu_64	 
	* d0:d1 is now d0:d1/d2
	* take the lower 32 bits
	move.l	d1,d0	
	bsr.w	.ch

	cmp	pi_VertPot(a1),d0
	sne	d4		* did it change compared to previous?
	move	d0,pi_VertPot(a1)

	* Subsequent mousemoves will call rslider4 to update
	* firstname according to VertPot, but that is not needed
	* since we did that already here. There would also be
	* jumps because the VertPot range 0..0xffff is not
	* very accurate for large amount of modules.
	move	d0,slider4old(a5)

	move	gg_Height(a0),d0

	basereg	slider4,a0

	cmp	#8,slimheight(a0)
	blo.b	.fea

	cmp	slider4oldheight(a5),d0
	bne.b	.fea

	tst	d4		* was there a change?
	beq.b	.eiup

.fea	tst.b	win(a5)
	beq.b	.eiup

	move	d0,slider4oldheight(a5)

;	move	gg_Height(a0),d0
	mulu	pi_VertBody(a1),d0	* koko pixelein‰
	divu	#$ffff,d0
	bne.b	.f
	moveq	#8,d0			* onko < 1? minimiksi 8
.f
	cmp	#8,d0
	bhs.b	.zze
	moveq	#8,d0
.zze
	move	d0,slimheight(a0)
	subq	#2+1,d0
	move	d0,d1

	lea	slim,a2
	lea	slim1a(a0),a1
	tst.b	uusikick(a5)
	bne.b	.newz
	* Select alternate gfx
	lea	slim1a_kick13-slim1a(a1),a1
.newz
	move	(a1)+,(a2)+
.filf	move	(a1),(a2)+
	dbf	d0,.filf
	addq	#2,a1
	move	(a1)+,(a2)+

	move	(a1)+,(a2)+
.fil	move	(a1),(a2)+
	dbf	d1,.fil
	move	2(a1),(a2)

.bar

	* Refresh one gadget
	;lea	slider4,a0
	endb	a0
	bsr.w	refreshGadgetInA0

.eiup
	rts


.ch	cmp.l	#$ffff,d0
	bls.b	.ok3
	move.l	#$ffff,d0
.ok3	rts


;resetslider
;	move.l	a0,-(sp)
;	move.l	slider4+gg_SpecialInfo,a0
;	clr	pi_VertPot(a0)
;	move.l	(sp)+,a0
;	rts




*******************************************************************************
* Play module
*******
* TODO: obtainModuleList
* TODO: most of this is duplicated elsewhere? in signalreceived?

playButtonAction
rbutton1
	DPRINT  "playButtonAction"

	tst.b	movenode(a5)
	beq.w	.nomove

**** Onko move p‰‰ll‰?
	clr.b	movenode(a5)

	bsr.w	getcurrent
	bne.b	.gotCurrent
	* No selection! Insert to beginning
	bsr.w	getVisibleModuleListHeader
	move.l	a0,a3
.gotCurrent

 if DEBUG
 	move.l	l_nameaddr(a3),d0
	DPRINT	"move, inserting after %s"
 endc

	DPRINT  "playButtonAction obtain list"
	bsr.w	obtainModuleList
	;lea	moduleListHeader(a5),a0	* Insertoidaan node...
	bsr.w	getVisibleModuleListHeader
	move.l	nodetomove(a5),a1
	move.l	a3,a2
	
	lore	Exec,Insert
	addq.l	#1,modamount(a5)
	addq.l	#1,chosenmodule(a5)	* valitaan movetettu node
	DPRINT  "playButtonAction release list"
	bsr.w	releaseModuleList
	bsr.w	listChanged
	bsr.w	forceRefreshList
	rts

.nomove
	;check	2		* reg check

	tst.b	new(a5)			* onko New?
	bne.b	.newoe

	tst.l	modamount(a5)		* onko modeja
	bne.b	.huh

.newoe	;st	new2(a5)
	st	haluttiinuusimodi(a5)
	bra.w	rbutton7		* jos ei, ladataan...

.huh	move.l	chosenmodule(a5),d0	* onko valittua nime‰
	bpl.b	.ere
	moveq	#0,d0			* jos ei, otetaan eka
.ere	
	move.l	d0,d2

	DPRINT	"->chosen module %ld"

	;move.b	new2(a5),d1
	;clr.b	new2(a5)

	cmp.b	#pm_random,playmode(a5)
	bne.b	.xa

	move.b	tabularasa(a5),d3
	clr.b	tabularasa(a5)
	tst.b	d3
	bne.w	soitamodi_random

	;tst.b	d1
	;bne.w	soitamodi_random * soita randomi, now 'New' ja randomplay
	;bsr.w	shownames
.xa

	bsr.w	clear_random		* Tyhj‰x
	bsr.w	setRandomTableEntry		* merkit‰‰n...

* etsit‰‰n listasta vastaava tiedosto

	DPRINT	"playbutton getListNode"
	bsr.w	getListNode
	beq.w	.erer
	move.l 	a0,a3

	* Is it a divider?
;	isListDivider l_filename(a3)
	tst.b	l_divider(a3)
	beq.b	.je

	* In file browser mode, dividers need special attention
	cmp.b	#LISTMODE_BROWSER,listMode(a5)
	bne.b	.noBrowser
	jmp	fileBrowserDir
.noBrowser

	* skip over to the next module if this was a divider
	TSTNODE	a3,a3
	beq.w	.erer			* end of list reached?
							* try the next one
	addq.l	#1,chosenmodule(a5)
	bsr.w	resh
	bra.w	.huh
.je
	cmp.l 	playingmodule(a5),d2	* onko sama kuin juuri soitettava??
	bne.w	.new
	* Special case: some delicustoms, SUNTronic modules,
	* can't handle being started over, to be safe
	* load these modules again before restarting.
	cmp	#pt_delicustom,playertype(a5)
	beq.w	.new
	* Same with all EaglePlayers to be save.
	* At least Tim Follin crashes.
	cmp	#pt_eagle_start,playertype(a5)
	bhs.w	.new
	* Similar case with SonicArranger with built-in
	* replayer code. Data is modified upon init so that
	* subsequent inits with same data will fail as
	* unsupported module.
	cmp	#pt_sonicarranger,playertype(a5)
	bne.b	.notSoar
	* Check for "compact" SA module
	move.l  moduleaddress(a5),a0 
	cmp.l	#'SOAR',(a0)
	bne.w 	.new
.notSoar
	DPRINT	"Restarting the same module!"
;.early
	bsr.w	fadevolumedown
	move	d0,-(sp)


	DPRINT	"Replay end"
* Soitetaan vaan alusta
	;lore	Exec,Disable
	bsr.w	halt
	;lore    Exec,Enable
	move.l	playerbase(a5),a0
	jsr	p_end(a0)
	move	(sp)+,mainvolume(a5)

	DPRINT	"Replay init"
	move.l	playerbase(a5),a0
	jsr	p_init(a0)
	tst.l	d0
	bne.w	.inierr

	st	playing(a5)		* Ei varmaan tuu initerroria
	bsr.w	settimestart
	bsr.w	inforivit_play
	bra.w	start_info
	;rts

.new	moveq	#0,d7
	tst.l	playingmodule(a5)	* Onko soitettavana mit‰‰n?
	bmi.b	.nomod

	move.b	doublebuf(a5),d7	* Onko doublebufferinki p‰‰ll‰?
	bne.b	.nomod

	bsr.w	fadevolumedown
	move	d0,-(sp)
	DPRINT	"Replay end"

	;lore	Exec,Disable
	bsr.w	halt			* Vapautetaan se jos on
	;lore 	Exec,Enable
	move.l	playerbase(a5),a0
	jsr	p_end(a0)
	bsr.w	freemodule	
	move	(sp)+,mainvolume(a5)
.nomod

	move.l	d2,playingmodule(a5)	* Uusi numero

	lea	l_filename(a3),a0	* Ladataan
	move.b	d7,d0 * double buffering flag
	jsr	loadmodule
	tst.l	d0
	bne.b	.loader

	DPRINT	"Replay init"
	move.l	playerbase(a5),a0
	jsr	p_init(a0)
	tst.l	d0
	bne.b	.inierr

	bsr.w	settimestart
.reet0	st	playing(a5)
	bsr.w	inforivit_play
	bsr.w	start_info
.erer
	rts

.loader	
	move.l	#PLAYING_MODULE_NONE,playingmodule(a5)
	rts

.inierr2
	moveq	#ier_unknown,d0

.inierr	
	DPRINT	"Replay init ERROR"
	move.l	#PLAYING_MODULE_NONE,playingmodule(A5)	* initvirhe
	bra.w	init_error
;	rts

halt:	clr.b	playing(a5)	
;	clr	songnumber(a5)
	clr	pos_nykyinen(a5)
	clr	positionmuutos(a5)
	rts




*******************************************************************************
* Insertti
*******
insertButtonAction
rinsert
	tst.l	modamount(a5)
	beq.w	rbutton7
	bsr.b	rinsert2
	bra.w	rbutton7

rinsert2
	move.l	chosenmodule(a5),d0

* etsit‰‰n listasta vastaava kohta
	DPRINT	"insert getListNode"
	bsr.w	getListNode
	beq.w	rbutton7		* go to "add"

* a0 = valittu nimi
	move.l	a0,fileinsert(a5)
	st	filereqmode(a5)
	rts
	



*******************************************************************************
* Add divider
*******
add_divider
	skipIfGadgetDisabled gadgetMoveButton
	
	DPRINT  "add_divider obtain list"
	bsr.w	obtainModuleList
	tst.l	modamount(a5)
	beq.w	.x
	move.l	chosenmodule(a5),d0
	bmi.w	.x
;	subq	#1,d0			* valitun nimen edellinen node

	DPRINT	"addDivider getListNode"
	bsr.w	getListNode
	beq.b	.x
	move.l	a0,a3

	bsr.w	get_rt

	push	a3
	lea	divider(a5),a1	
	moveq	#27-1,d0			* Request 27 bytes?
	sub.l	a3,a3
	lea	.tags(pc),a0
	lea	.ti(pc),a2
	bsr.w	setMainWindowWaitPointer
	lob	rtGetStringA
	bsr.w	clearMainWindowWaitPointer
	pop	a3
	tst.l	d0
	beq.b	.x

	addq.l	#1,modamount(a5)

	* Divider, reserve 30 bytes for the name. 27 bytes from above, one char from below
	moveq	#l_size+30,d0
	move.l	#MEMF_CLEAR,d1
	bsr.w	getmem
	beq.b	.x
	move.l	d0,a1

	lea	divider(a5),a0
	lea	l_filename(a1),a2
	move.l	a2,l_nameaddr(a1)
	st	l_divider(a1)
.fe	move.b	(a0)+,(a2)+
	bne.b	.fe
	
* a1 = insertattava nimi
;	lea	moduleListHeader(a5),a0
	bsr.w	getVisibleModuleListHeader
	move.l	a3,a2
	lore	Exec,Insert
	bsr.w	listChanged
	bsr.w	forceRefreshList

.x	
	DPRINT  "add_divider release list"
	bsr.w		releaseModuleList
	rts

.ti	dc.b	"Add divider",0
 even

.tags
	dc.l	RTGS_Width,262
	dc.l	RT_TextAttr,text_attr
otag17	dc.l	RT_PubScrName,pubscreen+var_b
	dc.l	TAG_END




*******************************************************************************
* Add files to list
* Recursive scan (apparently only on kick2.0 (not quite, also works on 1.3))
* Uses a separate process
*******
addButtonAction
rbutton7
	skipIfGadgetDisabled gadgetAddButton

	clr.b	movenode(a5)
	tst	filereq_prosessi(a5)
	beq.b	.ook
.skip
	rts
.ook	
	bsr.w	confirmFavoritesModification
	beq.b	.skip

	move.l	_DosBase(a5),a6

	;bra	filereq_code

	pushpea	fileprocname(pc),d1

	move.l	priority(a5),d2
;	moveq	#0,d2			* pri

	pushpea	filereq_segment(pc),d3
	lsr.l	#2,d3
	* stack size needs to be large.  needed for recursive dir scan,
	* it seems that kick1.3 needs more than kick3.0 for 10 levels of 
	* sub dirs.
	move.l	#7000,d4	
	lob	CreateProc
	tst.l	d0
	beq.b	.error
	addq	#1,filereq_prosessi(a5)
.error	rts

filereq_code
	lea	var_b,a5
	addq	#1,filereq_prosessi(a5)	* Lippu: prosessi p‰‰ll‰
	moveq	#0,d7

	tst.l	modamount(a5)
	sne	tabularasa(a5)		* pistetaan lippu jos aluks 
					* ei moduuleja. tata kaytetaan
					* randomplayn kanssa, eli katotaan
					* otetaanko eka moduuli taysin 
					* randomilla

	bsr.b	.filer

	* Now exiting this process

	lore	Exec,Forbid

	move.b	fileReqSignal(a5),d1	* Send signal, all done
	bsr.w	signalit
	clr.b	filereqmode(a5)

	clr	filereq_prosessi(a5)	* Lippu: prosessi poistettu
	rts
	
* Varsinainen operaatio alkaa t‰st‰..
.filer
	bsr.w	tokenizepattern

	bsr.w	get_rt
	tst.l	req_file(a5)
	bne.b	.onfi
	moveq	#RT_FILEREQ,D0
	sub.l	a0,a0
	lob	rtAllocRequestA
	move.l	d0,req_file(a5)
.onfi

** BUGI?!?

	tst.b	newdirectory(a5)	* Onko uusi hakemisto?
	beq.b	.eimuut
	clr.b	newdirectory(a5)

	* Use either prefs set directory, or one from saved state

	move.l	req_file(a5),a1		* Vaihdetaan hakemistoa...
	lea	newdir_tags(pc),a0
	lea	moduledir(a5),a2
	move.l	a2,4(a0)

	tst.b	savestate(a5)
	beq.b	.noSaveState
	move.l	lastStoredFileReqDirectory(a5),d0 
	beq.b	.noSaveState
	move.l	d0,4(a0)
.noSaveState
 if DEBUG
	move.l	4(a0),d0
	DPRINT	"FileReq to %s"
 endif
	lore	Req,rtChangeReqAttrA

	* When set once, filereq will remember the 
	* last user dir.
	move.l	lastStoredFileReqDirectory(a5),a0 
	bsr.w		freemem
	clr.l	lastStoredFileReqDirectory(a5)

.eimuut

	move.l	req_file(a5),a1		* Match pattern
	lea	matchp_tags(pc),a0
	lore	Req,rtChangeReqAttrA

	st	loading2(a5)			* checked with loading(a5)

	* launch file requester
	lea	filereqtags(pc),a0		* tags for configuration
	move.l	req_file(a5),a1		* requester structure
	lea	filename(a5),a2			* selected filename (must be 108 bytes)
	lea	filereqtitle(pc),a3		* requester title
	lore	Req,rtFileRequestA	* ReqToolsin tiedostovalikko	
	push	d0					* Result is in d0, 
								* FALSE or a pointer to rtFileList

	* During processing of data lock window and reserve
	* the list structure.

	DPRINT  "filereq_code obtain list"
	bsr.w		obtainModuleList
	bsr.w		lockMainWindow
	pop 	d0
	bsr.b	.processResult

	move.l	filelistaddr(a5),d0
	beq.b	.noFileList
	move.l	d0,a0
	* This was never done previously. A memory leak possibly?
	lore	Req,rtFreeFileList
	clr.l	filelistaddr(a5)
.noFileList

	DPRINT  "filereq_code release list"
	bsr.w		releaseModuleList
	bsr.w		unlockMainWindow
	rts

.processResult
	* Test if user selected anything or canceled
	move.l	d0,filelistaddr(a5)
	bne.b	.val

	move.b	#$7f,new(a5)		* new-lippu: cancel
	bra.w	.fileReqCancelled
.val

	tst.b	new(a5)			* jos 'new', clearataan lista.
	beq.b	.non1
	bsr.w	clearlist
.non1

 ifne fprog
	bsr	openfilewin
 endc

	bsr.w	parsereqdir		* Tehd‰‰n hakemistopolku..

* We will now normalize the directory given to us by ReqTools
* This creates consistent paths everytime,
* and allows favorites logic path matching to work.

	pushpea	tempdir(a5),d1
	jsr	normalizeFilePath

	* contains the files from reqtools as per user selection
	move.l	filelistaddr(a5),a4	
	
	* let's calculate how much space is needed to store
	* path in d4.

	moveq	#0,d4			* polun pituus
	lea	tempdir(a5),a0
.f	addq.l	#1,d4
	tst.b	(a0)+
	bne.b	.f
;	subq.l	#1,d4			* -1, nolla pois per‰st‰
;	add.l	#l_size,d4		* listayksikˆn koko
	add.l	#l_size-1,d4
.buildlist

***** K‰sitell‰‰n valitut hakemistot 

	cmp.l	#-1,rtfl_StrLen(a4)	* onko hakemisto?????
	bne.w	.file				* reqtools-listan file

	move.l	rtfl_Name(a4),a0	* hakemiston nimi
	bsr.w	adddivider

* rtfl_Name(a4)	= hakemisto 2
* tempdir(a5) = hakemisto 1
* Koko hakemistonpolku = Hakemisto 1/hakemisto 2
	lea	-200(sp),sp
	move.l	sp,a3
	lea	tempdir(a5),a0
.c0	move.b	(a0)+,(a3)+
	bne.b	.c0
	subq.l	#1,a3				* null 
	move.l	rtfl_Name(a4),a0
.c1	move.b	(a0)+,(a3)+
	bne.b	.c1
	subq.l	#1,a3
	move.b	#'/',(a3)+
	clr.b	(a3)

 if DEBUG 
	move.l	sp,d0
	DPRINT	"ReqTools dir: %s"
 endif 

	move.l	a3,d3			* hakemiston pituus
	sub.l	sp,d3
	add.l	#l_size,d3		* listayksikˆn koko

* d3 = dir len + l_size
* sp = dir

	move.l	sp,d2
	pushm	all
	bsr.b	.scanni			* rekursiivinen hakemiston tutkimus
	popm	all
	lea	200(sp),sp

	bsr.w	.dirdiv
	bra.w	.skip


* recursively scan directory
* in: 
*  d2 = path to directory to be scanned, with separator
*  d3 = path length + l_size. d3 should not be destroyed
.scanni

 if DEBUG
	move.l	d2,d0
	DPRINT	"Scan: %s"
 endif
	move.l	d2,a4		* hakemisto
	moveq	#0,d6		* lock for dir scan

	* Have a buffer that stores pointers to subdirectory names within this subdirectory.
.MAX_SUBDIRS_TO_SCAN = 250

	* space for counter and path pointers	
	move.l	#.MAX_SUBDIRS_TO_SCAN*4+2,d0	
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	bsr.w	getmem
	move.l	d0,d7
	beq.w	.errd

	* Get a lock on dir.
	* This will succeed even on an empty string, it will then
	* be a lock on SYS:. Add a paranoia check for that.
	tst.b	(a4)
	beq.w	.errd
	move.l	a4,d1
	moveq	#ACCESS_READ,d2
	lore	Dos,Lock
	move.l	d0,d6			* d6 = hakemiston lukko
  if DEBUG
	bne.b	.lockOk
	DPRINT	"Lock failed!"
	bra.w 	.errd
  else 
	beq.w	.errd
  endif
.lockOk
	* Examine it
	move.l	d6,d1
	pushpea	fileinfoblock2(a5),d2
	lob	Examine
	tst.l	d0
	beq.w	.errd


.loopo	cmp.l	#MAX_MODULES,modamount(a5)	* Ei enemp‰‰ kuin ~16000
	bhs.w	.errd

	move.l	d6,d1
	pushpea	fileinfoblock2(a5),d2
	lore	Dos,ExNext
	* No more items to check in directory?
	tst.l	d0
	beq.w	.dodirs	

	* Success! What is it?
	* ST_ROOT=1
	* ST_USERDIR=2
	* ST_SOFTLINK=3
	* ST_LINKDIR=4
	* ST_FILE=-3
	* ST_LINKFILE=-4
	* ST_PIPEFILE=-5

	move.l	fib_DirEntryType+fileinfoblock2(a5),d0
	cmp.l	#ST_FILE,d0
	beq.w	.filetta
	cmp.l	#ST_LINKFILE,d0
	beq.w	.filetta
	cmp.l	#ST_USERDIR,d0
	bne.w	.unsupportedEntry

	* It was a directory. Store it for later, this way
	* files in the directory get placed first in the list,
	* then after that the subdir contents.

	;tst.b	uusikick(a5)		* rekursiivinen vain kick2.0+
	;beq.b	.loopo

* otetaan kyseisen hakemiston nimi talteen myˆhemp‰‰ k‰yttˆ‰ varten
* build a full path for this dir entry
.MAX_PATH_LEN = 200
	move.l	#.MAX_PATH_LEN,d0
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	bsr.w	getmem
	move.l	d0,a1
	tst.l	d0
	beq.b	.lc0
	* high bound
	lea	.MAX_PATH_LEN-1(a1),a2

	move.l	a4,a0
.lc	cmp.l   a1,a2
	beq.b	.pathOverflow
	move.b	(a0)+,(a1)+
	bne.b	.lc
	subq	#1,a1
	lea	fib_FileName+fileinfoblock2(a5),a0
.lc2	cmp.l   a1,a2
	beq.b	.pathOverflow
	move.b	(a0)+,(a1)+
	bne.b	.lc2

	* Add path separator
	subq	#1,a1		* NULL
	cmp.b	#':',-1(a1)
	beq.b	.dd
	move.b	#'/',(a1)+
.dd	clr.b	(a1)

	* check if subdir buffer limit is reached
	move.l	d7,a0
	move	(a0),d1

 if DEBUG
	cmp	#.MAX_SUBDIRS_TO_SCAN,d1
	blo.b	.BOB
	DPRINT	"Subdir limit!"
.BOB
 endif

	cmp	#.MAX_SUBDIRS_TO_SCAN,d1
	bhs.w	.loopo
	* add one path pointer and increment counter
	addq	#1,(a0)+
	lsl	#2,d1
	move.l	d0,(a0,d1)
.lc0
	bra.w	.loopo

.pathOverflow
	DPRINT	"Path name overflow!"
	bra.w	.loopo
.unsupportedEntry
	DPRINT	"Unsupported entry: %ld"
	bra.w	.loopo

**** skannattuamme yhden hakemiston tutkitaan siin‰ olleet muut hakemistot
* Files scanned, now check the subdirs.
.dodirs
	* ExNext failed, then we come here.
	* ERROR_NO_MORE_ENTRIES = 232 should be the normal case.
 if DEBUG
	lore	Dos,IoErr
	cmp.l	#ERROR_NO_MORE_ENTRIES,d0
	beq.b	.io
	DPRINT	"IoErr=%ld"
.io
 endif
	;tst.b	uusikick(a5)		* rekursiivinen vain kick2.0+
	;beq.w	.errd
	* Allow recursion into directories with kick1.3 too!
	pushm	all

	* sort subdirs to get them in nice order
	move.l 	d7,a0 		
	move	(a0)+,d0
	jsr	sortStringPtrArray

	* the first word in the memory contains the subdir count
	move.l	d7,a3
	move	(a3)+,d5
	beq.b	.errd2
	* some subdirs were stored
	subq	#1,d5

.dodirsLoop
	* subdir path
	move.l	(a3)+,d6

	move.l	d6,a0
.findDirEnd
	tst.b	(a0)+
	bne.b	.findDirEnd
	move.l	a0,d3	* store this for later
	move.l	d6,a1
	subq	#2,a0	* skip last NULL and separator
	bsr.w	nimenalku
	* a0 = last part of the path

	* Add a named divider from a0
	* Remove separator temporarily
	move.l	d3,a1
	move.b	-2(a1),d0
	clr.b	-2(a1)
	bsr.w	adddivider	* all regs preserved
	move.b	d0,-2(a1)

	pushm	all
	* path length
	sub.l	d6,d3
	add.l	#l_size,d3
	* path to scan
	move.l	d6,d2
	* scan it
	bsr.w	.scanni
	; Add end-of-directory divider
	bsr.w	.dirdiv
	popm	all
	dbf	d5,.dodirsLoop

.errd2	popm	all
	bra.b	.errd

* in: 
*   a4="dir 1/dir 2/",0
*   d3=list element length based on this path
.filetta

** Patternmatchaus
	tst.b	uusikick(a5)
	beq.b	.yas
	pushpea	tokenizedpattern(a5),d1
	pushpea	fib_FileName+fileinfoblock2(a5),d2
	push	a6
	lore	Dos,MatchPatternNoCase
	pop	a6
	tst.l	d0			* kelpaako vaiko eik¯?
	beq.w	.loopo
.yas

	* allocate memory for list node

	lea	fib_FileName+fileinfoblock2(a5),a0	* filename

	move.l	a0,a1
.fie	tst.b	(a1)+
	bne.b	.fie
	sub.l	a0,a1		* nimen pituus

	move.l	d3,d0		* hakemisto + nimi (pituus)
	add.l	a1,d0
	move.l	d0,d2		* TODO: whats this
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	bsr.w	getmem
	bne.b	.gotMem2
	bsr.w	showOutOfMemoryError
	bra.b	.errd
.gotMem2
	move.l	d0,a3		* a3 = listunit
	
	lea	l_filename(a3),a1
	move.l	a4,a0
.c2	
	move.b	(a0)+,(a1)+	* kopioidaan hakemisto
	bne.b	.c2
	subq.l	#1,a1
	move.l	a1,l_nameaddr(a3)	* ja tiedosto
	lea	fib_FileName+fileinfoblock2(a5),a0
.c3	
	move.b	(a0)+,(a1)+
	bne.b	.c3

	bsr.w	addfile
	bra.w	.loopo

.errd	
	move.l	d6,d1
	beq.b	.erde
	lore	Dos,UnLock
.erde	

* vapautetaan lukot hakemiston hakemistoihin
	tst.l	d7
	beq.b	.erde0

	move.l	d7,a3
	move	(a3)+,d3
	beq.b	.erde1
	subq	#1,d3

.erde2	move.l	(a3)+,a0
	bsr.w	freemem
	dbf	d3,.erde2
.erde1
	move.l	d7,a0		
	bsr.w	freemem
.erde0
	rts


************* Reqtoollislta saadut tiedostot
* d4=path length
.file
	;DPRINT 	"Adding file at .file"

	cmp.l	#MAX_MODULES,modamount(a5)	* Ei enemp‰‰ kuin 16383
	bhs.b	.overload

	move.l	d4,d0				* listunit,polku,nimi pituus
	add.l	rtfl_StrLen(a4),d0	* incoming string length
	addq.l	#1,d0				* space for terminating zero

	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1		* varataan muistia
	bsr.w	getmem
	bne.b	.gotMem
	bsr.w	showOutOfMemoryError
	bra.b	.whoops2
.gotMem
	move.l	d0,a3

	lea	l_filename(a3),a1
	lea	tempdir(a5),a0
.copy	
	move.b	(a0)+,(a1)+		* kopioidaan polku
	bne.b	.copy
	subq.l	#1,a1			* remove zero
	move.l	a1,l_nameaddr(a3)	* pelk‰n nimen osoite
	movem.l	rtfl_StrLen(a4),d0/a0	* StrLen/Name
	subq	#1,d0
.copy2
	move.b	(a0)+,(a1)+		* kopioidaan tiedoston nimi
	dbf	d0,.copy2
	clr.b	(a1)	

	bsr.b	addfile

.skip
								* Check for next entry in rtFileList
	move.l	rtfl_Next(a4),d0	* Joko loppui?
	beq.b	.whoops3
	move.l	d0,a4
	bra.w	.buildlist

.whoops2
.whoops	
.whoops3	
.fileReqCancelled

	tst.l	chosenmodule(a5)
	bpl.b	.ee
	clr.l	chosenmodule(a5)	* moduuliksi eka jos ei ennest‰‰n
.ee

	clr.b	loading2(a5)

 ifne fprog
	bsr	closefilewin
 endc
	* all done!?
	rts


.overload
	lea	.t(pc),a1
	bsr.w	request
	bra.b	.whoops


.dirdiv
	lea	.barf(pc),a0
	bra.b	adddivider

.t	dc.b	"My stomach feels content.",0
	* This must not be changed, content checked in adddivider below.
.barf	dc.b	"/\/\/\/\/\/\/\",0
	even

* addaa/inserttaa listaan a3:ssa olevan noden
* in: 
*   a3 = list node to be added into the list
addfile:
	cmp.l	#MAX_MODULES,modamount(a5)
	bhs.b	.exit

	addq.l	#1,modamount(a5)
	move.l	(a5),a6
	bsr.w	getVisibleModuleListHeader
	move.l	a3,a1

	tst.b	filereqmode(a5)		* onko add vai insert?
	bne.b	.insert

 	jsr	_LVOAddTail(a6)

	move.l	a3,a0
	jsr	updateFavoriteStatus
	rts
 
.insert	move.l	fileinsert(a5),a2	* mink‰ filen per‰‰n insertataan
	lob	Insert

	move.l	a3,a0
	jsr	updateFavoriteStatus
.exit
	rts



*** Lis‰t‰‰n divideri hakemistolle
* a0 = hakemiston nimi
*      directory name

adddivider:
	pushm	all
	moveq	#0,d7

	* Check configuration flag for automatically added dividers
	tst.b	divdir(a5)
	beq.w	.meek
	move.l	a0,a2

** testataan onko dirdivideri? jos on, pistet‰‰n sen p‰‰lle
	;lea	moduleListHeader(a5),a3
	bsr.w	getVisibleModuleListHeader
	move.l	a0,a3
	move.l	MLH_TAILPRED(a3),d0    * this points to the last element of the list
	beq.b	.pehe
	move.l	d0,a3

	move.l	l_nameaddr(a3),d0
	beq.b	.pehe
	move.l	d0,a0

;	isListDivider (a0)    * Magic divider character
;	bne.b	.pehe
	tst.b	l_divider(a3)
	beq.b	.pehe
	cmp.b	#'/',7-1(a0)	 * Another magic divider character
	bne.b	.pehe
	moveq	#1,d7		 * set a magic flag: overwrite existing divider
	bra.b	.hue
.pehe


	; List can display 27 characters per line.
.MAX_WIDTH = 27

	; There is no path information, only the file name on its own.
	; There will be an invisible char first, the divider magic marker.
	; There will be a terminating zero last.
	; Therefore a buffer of 27+1+1 on top of l_size should be ok.

	; Reserve this much chars for the actual name
.MAX_NAME = 21

	moveq	#l_size+30,d0
	move.l	#MEMF_CLEAR,d1
	bsr.w	getmem
	beq.b	.meek

	move.l	d0,a3
.hue	
	move.l	a2,a0

	lea	l_filename(a3),a2
	move.l	a2,l_nameaddr(a3)

	* first insert divider magic marker
	;move.b	#DIVIDER_MAGIC,(a2)+	* divider merkint‰
	st	l_divider(a3)

	* a0 = directory name

	* find out length of the name,
	* max allowed is 21	
	move.l	a0,a1
.findLength
	tst.b	(a1)+
	bne.b	.findLength
	* discard null termination
	subq	#1,a1
	move.l	a1,d0
	sub.l	a0,d0
	cmp	#.MAX_NAME,d0
	bls.b	.lengthOk
	moveq	#.MAX_NAME,d0
.lengthOk

	* this is the high bound that should not be written to
	lea	.MAX_WIDTH(a2),a1

	* length of name is now in d0.
	* how much is left for padding stars?
	moveq	#.MAX_WIDTH,d1
	sub	d0,d1
	* how about on either side?
	lsr	#1,d1
	* reserve one byte for space on both sides
	subq	#1,d1
	* do left padding
.leftPad
	move.b	#'*',(a2)+
	subq	#1,d1
	bne.b	.leftPad
	move.b	#' ',(a2)+
	* then fill in the name
.copyName
	move.b	(a0)+,(a2)+
	subq	#1,d0
	bne.b	.copyName
	* right pad
	move.b	#' ',(a2)+
	* fill until right bound is reached
.rightPad
	move.b	#'*',(a2)+
	cmp.l	a1,a2
	bne.b	.rightPad

	clr.b	(a2)
	tst.b	d7		* did we overwrite an old one? 
	bne.b	.noAdd
	bsr.w	addfile		* no, let's add
.noAdd

.meek	popm	all
	rts





** Asetetaan hakemisto requesteriin
newdir_tags
	dc.l	RTFI_Dir
	dc.l	0			* Uuden hakemiston osoite t‰h‰n
	dc.l	TAG_END


matchp_tags
	dc.l	RTFI_MatchPat,var_b+pattern
	dc.l	TAG_END


* Reqtoolsin tagit
filereqtags
	dc.l	RTFI_Flags
	dc.l	FREQF_MULTISELECT!FREQF_PATGAD!FREQF_SELECTDIRS
;	dc.l	RT_TextAttr,text_attr
otag2	dc.l	RT_PubScrName,pubscreen+var_b
	dc.l	TAG_END
filereqtitle
	dc.b	"Select files & dirs to add",0

 even












 ifne fprog
fail not used 

*********************************
* File add progress indicator

wflags5 = WFLG_SMART_REFRESH!WFLG_BORDERLESS
idcmpflags5 = 0 ;IDCMP_MOUSEBUTTONS!IDCMP_INACTIVEWINDOW

openfilewin
	pushm	all

	move.l	screenaddr(a5),d0
	beq.w	.x
	move.l	d0,a0

	move	sc_MouseX(a0),d6
	move	sc_MouseY(a0),d7

	lea	winfile,a0		* asetetaan pointterin kohdalle
	move	#125,nw_Width(a0)
	move	#15,nw_Height(a0)

	sub	#125/2,d6
	bpl.b	.b
	moveq	#0,d6
.b	move	d6,nw_LeftEdge(a0)

	sub	#15/2,d7
	bpl.b	.ba
	moveq	#0,d7
.ba	move	d7,nw_TopEdge(a0)



	bsr.w	tark_mahtu

	lore	Intui,OpenWindow
	move.l	d0,d5
	beq.w	.x
	move.l	d0,a0
	move.l	wd_RPort(a0),d7		* rastport

	move.l	d5,filewin
	move.l	d7,filerastport

	move.l	d7,a1
	move.l	pen_1(a5),d0
	lore	GFX,SetAPen
	move.l	d7,a1
	move.l	pen_0(a5),d0
	lob	SetBPen

	move.l	d7,a1
	move.l	fontbase(a5),a0
	lob	SetFont	


	move.l	d7,a1
	lea	winfile,a0
	moveq	#0,plx1
	move	nw_Width(a0),plx2
	moveq	#0,ply1
	move	nw_Height(a0),ply2
	subq	#1,ply2
	subq	#1,plx2
	bsr.w	laatikko2

	move	modamount(a5),fileamount


.x	popm	all
	rts


printfilewin
	pushm	d1/d1/a0/a4

	tst.l	filewin
	beq.b	.x

	move	modamount(a5),d0
	sub	fileamount(pc),d0

	lea	.foo(pc),a0
	bsr	putnumber
	clr.b	(a0)

	lea	.goo(pc),a0
	moveq	#7,d0
	moveq	#10,d1

	move.l	filerastport(pc),a4
	bsr.b	.dd

.x	popm	d0/d1/a0/a4
	rts

.dd	pushm	all
	bra	uup


.goo	dc.b	"Entries: "
.foo	dc.b	"       "
 even

filewin		dc.l	0
filerastport	dc.l	0
fileamount	dc.l	0

closefilewin
	pushm	all
	move.l	filewin(pc),d0
	beq.b	.x
	move.l	d0,a0
	lore	Intui,CloseWindow
.x	popm	all
	rts



winfile
	dc	0,0	* paikka 
	dc	0,0	* koko
	dc.b	0,0	;palkin v‰rit
	dc.l	idcmpflags4
	dc.l	wflags4
	dc.l	0
	dc.l	0	
	dc.l	0	; title
	dc.l	0
	dc.l	0	
	dc	0,0
	dc	0,0
	dc	WBENCHSCREEN
	dc.l	enw_tags
 endc











*******************************************************************************
* Vapautetaan tiedostolista
*******
freelist:
	DPRINT  "freelist obtain list"
	bsr.w		obtainModuleList
	tst.l		modamount(a5)
	beq.b	.listEmpty
	move.l	#PLAYING_MODULE_NONE,chosenmodule(a5)
	tst.l	playingmodule(a5)
	bmi.b	.ehe
	move.l	#PLAYING_MODULE_REMOVED,playingmodule(a5)
.ehe
	move.l	(a5),a6		* execbase
	lea	moduleListHeader(a5),a2
.freelist_loop
	* a0: list, a1: destroyed, d0: node, or zero
	; TODO: Use MACRO
	move.l	a2,a0
	lob	RemHead
	beq.b	.listFreed
	move.l	d0,a0

	bsr.w	freemem
	bra.b	.freelist_loop

.listFreed
	* no longer modules in list, at all
	clr.l	modamount(a5) 
	* need to reset random table to nothingness as well
	bsr.w	clear_random
	bsr.w	clearCachedNode

	* reset list slider and list box 
	clr.l	firstname(a5)	
	bsr.w	reslider

.listEmpty
	DPRINT  "freelist release list"
	bsr.w	releaseModuleList
	rts


*******************************************************************************
* Parsetaan reqtoolsilta saatu hakemistopolku
*******
parsereqdir
	move.l	req_file(a5),a0
parsereqdir3
	lea	tempdir(a5),a1
parsereqdir2
	move.l	16(a0),a0
	tst.b	(a0)
	bne.b	.dij
	clr	(a1)
	rts
.dij	move.b	(a0)+,(a1)+		* tehd‰‰n hakemisto
	bne.b	.dij
	subq.l	#2,a1
	cmp.b	#':',(a1)
	beq.b	.nfo
	addq.l	#1,a1
	move.b	#'/',(a1)
.nfo	clr.b	1(a1)
	rts



*******************************************************************************
* Ladataan/tallennetaan moduuliohjelma
*******

* ladataan PRG joka on d7:ssa, AREXX
rloadprog2
	bra.b	rloadprogDoIt

* LoadProgram joka AddTailaa vanhan listan per‰‰n.
* Only from keyboard.
rloadprog0		
	st	lprgadd(a5)

* From keys, gadgets
rloadprog
	moveq	#0,d7
	skipIfGadgetDisabled gadgetPrgButton

rloadprogDoIt

	bsr.w 	setMainWindowWaitPointer
	DPRINT  "rloadprog obtain list"
	bsr.w	obtainModuleList
	bsr.b 	.doLoadProgram
	bsr.w	 clearMainWindowWaitPointer
	DPRINT  "rloadprog release list"
	bsr.w	releaseModuleList
	rts

.doLoadProgram
	tst	filereq_prosessi(a5)
	bne.w	.kex

	bsr.b	.showLoadingProgram
	bra.b	.dd

.showLoadingProgram
	pushm	all
	lea	.t(pc),a0
	moveq	#46+WINX,d0
	bsr.w	printbox
	popm	all
	rts
.t	dc.b	"Loading module program...",0
 even

.dd
	clr.b	movenode(a5)

	tst.l	d7
	bne.b	.loe

	bsr.w	get_rt
	moveq	#RT_FILEREQ,D0
	sub.l	a0,a0
	lob	rtAllocRequestA
	move.l	d0,req_file2(a5)
	beq.w	.kex

	move.l	d0,a1			* Vaihdetaan hakemistoa...
	lea	newdir_tags(pc),a0
	pushpea	prgdir(a5),4(a0)
	lob	rtChangeReqAttrA

	move.l	req_file2(a5),a1	* pattern match
	lea	matchp_tags(pc),a0	
	lob	rtChangeReqAttrA

	lea	.tags(pc),a0
	move.l	req_file2(a5),a1
	lea	filename(a5),a2		* T‰nne tiedoston polku ja nimi
	clr.b	(a2)

	lea	filereqtitle2(pc),a3
	lob	rtFileRequestA		* ReqToolsin tiedostovalikko
	tst.l	d0
	beq.w	.kex
	move.l	req_file2(a5),a0
	bsr.w	parsereqdir3

	lea	tempdir(a5),a0		* kopioidaan polku ja nimi yhdeksi
	lea	filename2(a5),a1
.c	move.b	(a0)+,(a1)+
	bne.b	.c
	subq.l	#1,a1
	lea	filename(a5),a0
.a	move.b	(a0)+,(a1)+
	bne.b	.a


.loe	
	tst.b	lprgadd(a5)		* ei putsata jos addataan
	bne.b	.yad
	bsr.w	freelist		* putsataan vanha lista
.yad

	lea	filename2(a5),a0
	tst.l	d7
	beq.b	.ewew
	move.l	d7,a0
.ewew
	moveq	#0,d4
.loadp
	move.b	lprgadd(a5),d7
	clr.b	lprgadd(a5)

***** ladataan proggis

	move.l	a0,.infile

 if DEBUG
	move.l	a0,d0
	moveq	#0,d1
	move.b	d7,d1
	DPRINT	"Infile: %s add: %ld"
 endif		


	move.l	_DosBase(a5),a6
	move.l	a0,d1
	move.l	#1005,d2
	lob	Open
	move.l	d0,d6
	beq.w	.openerr

	move.l	d6,d1		* selvitet‰‰n filen pituus
	moveq	#0,d2	
	moveq	#1,d3
	lob	Seek
	move.l	d6,d1
	moveq	#0,d2	
	moveq	#1,d3
	lob	Seek
	move.l	d0,d5		* pituus

	move.l	d6,d1
	moveq	#0,d2
	moveq	#-1,d3
	lob	Seek		* alkuun

	move.l	d5,d0		* muistia listalle
	DPRINT	"Allocating %ld for list"
	moveq	#MEMF_PUBLIC,d1
	bsr.w	getmem
	move.l	d0,a3
	bne.b	.gotMem

	* bail out!
.bailOut
	moveq	#0,d5	* memory address for freemem 
.bailOut2
	bsr.w	showOutOfMemoryError
	move.l	d6,d1
	lob	Close
	bra.w	.x2
.gotMem
	* We will need at least another d5 since
	* the list needs to be created.
	push	a6
	moveq	#MEMF_ANY,d1
	lore	Exec,AvailMem
	pop  	a6
	DPRINT	"Mem left   %ld"
	* Arbitrary 100 kB safety margin
	sub.l	#100*1024,d0
	cmp.l	d0,d5
	ble.b	.yesMem
	* address in d5 gets freed later
	move.l	a3,d5
	bra.b	.bailOut2
.yesMem
	
	move.l	d6,d1		* file
	move.l	a3,d2		* destination
	move.l	d5,d3		* pituus
	lob	Read

	move.l	a3,d1
	add.l	d0,d1
	move.l	d1,.loppu

	push	d0

	move.l	d6,d1
	lob	Close

	cmp.l	(sp)+,d5	* read error?
	bne.w	.x2

** A3:ssa moduulilista
** jos on xpk pakattu, pit‰‰ purkaakkin.

	cmp.l	#"XPKF",(a3)
	bne.w	.nox

	jsr	get_xpk
	beq.w	.what

	cmp.l	#"HiPP",16(a3)	* uusi formaatti?
	bne.b	.nu
	cmp	#"rg",20(a3)
	beq.b	.nyy
.nu
	cmp.l	#"HIPP",16(a3)	* tunnistus, vanha formaatti?
	bne.w	.what
	cmp	#"RO",20(a3)
	bne.w	.what
.nyy

	move.l	a3,a0
	bsr.w	freemem

	lea	.tagz(pc),a0
	clr.l	.len-.tagz(a0)
	lore	XPK,XpkUnpack

	tst.l	d0
	beq.b  .xpkOk
	* no freeing later:
	moveq	#0,d5
	lea	xpk_module_program_error(pc),a1
	bsr.w	request
	bra.w	.x2
.xpkOk

	move.l	.addr(pc),a3
	move.l	a3,d0
	add.l	.oiklen(pc),d0
	move.l	d0,.loppu

	bra.b	.noxx

.tagz
		dc.l	XPK_InName
.infile		dc.l	0

		dc.l	XPK_GetOutBuf,.addr
		dc.l	XPK_GetOutBufLen,.len
		dc.l	XPK_GetOutLen,.oiklen

		dc.l	XPK_OutMemType,MEMF_PUBLIC
		dc.l	XPK_PassThru,1
;		dc.l	XPK_GetError,xpkerror+var_b	* virheilmoitus
		dc.l	TAG_END

.len	dc.l	0
.addr	dc.l	0
.oiklen	dc.l	0
.loppu	dc.l	0

.noxx

.nox


***************** ALoitetaan k‰sittely



	move.l	a3,d5		* muistialue talteen d5:een

	* read stuff from a3 until a4, into list in a2
	pushm 	d1-a6
	lea		moduleListHeader(a5),a2
	move.l	.loppu(pc),a4 
	bsr.w	importModuleProgramFromData
	DPRINT 	"Imported %ld files"
	popm	d1-a6

	move.l	d0,modamount(a5)

	tst.b	d7
	bne.b	.append
	move.l	d0,modamount(a5)
	bra.b	.noAppend
.append
	add.l	d0,modamount(a5)
.noAppend	


.x2
	tst.l	d5
	beq.b	.xxx

	tst.l	.len
	beq.b	.xx0

	move.l	.len(pc),d0	* xpk puskurin vapautus
	move.l	d5,a1
	lore	Exec,FreeMem
	clr.l	.len
	bra.b	.xxx
.xx0
	
	move.l	d5,a0
	bsr.w	freemem
.xxx

	sub.l	a4,a4
.x1	
	tst	d4
	bne.b	.ext
	move.l	req_file2(a5),d0
	beq.b	.ex
	move.l	d0,a1
	move.l	_ReqBase(a5),a6
	lob	rtFreeRequest

.ex

	clr.l	chosenmodule(a5)	* moduuliksi eka
.kex	bsr.w	listChanged
	bsr.w	forceRefreshList
	rts

.what
	lea	unknown_module_program_error(pc),a1
	bsr.w	request
	bra.b	.x2

.openerr
	move	#1,a4			* lippu
	lea	openerror_t,a1
	bsr.w	request
	bra.b	.x1



.ext
* ladattiin ohjelma komentojonon kautta, soitetaan eka tai satunnainen
* riippuen prefs-s‰‰dˆist‰.
* Jos ohjelmaa ei saatu ladattua, niin pistet‰‰n filerequesteri.

	bsr.w	vastomaviesti

	cmp	#1,a4	* avausvirhe? -> ei tehd‰ mit‰‰n
	bne.b	.r
	moveq	#lod_openerr,d0
	rts

.r	cmp.b	#pm_random,playmode(a5)
	bne.b	.noran
	move.l	modamount(a5),d0
	cmp.l	#MAX_MODULES,d0
	bhi.b	.noran
	
	subq.l	#1,d0
.b	bsr.w	getRandomValue
	cmp.l	d0,d1
	bhi.b	.b
		
	move.l	d1,d0
	bsr.w	setRandomTableEntry

	move.l	d1,chosenmodule(a5)
	bra.b	.eh

.noran	clr.l	chosenmodule(a5)

.eh	
	bsr.w	forceRefreshList
	bra.w	rbutton1	* Play

.blob	bsr.w	.showLoadingProgram
	bra.w	.loadp


.tags
	dc.l	RTFI_Flags,FREQF_PATGAD
otag1	dc.l	RT_PubScrName,pubscreen+var_b,0

* UGH! Evil hackery:
;loadprog
;	bra.b	*-22		* bra.b -> bra.b .blob

* in:
*   a0 = module program file name
*   d4 = some magic flag?
*   d7 = some other magic flag?
loadprog
	DPRINT	"loadprog"
	* Ensure correct list mode
	jsr	engageNormalMode
	bra.b	rloadprogDoIt\.blob

* Variant that skips the prg file header,
* and adds extra data in front of every added
* file path.
* in:
*   a2 = list header
*   a3 = data read from file
*   a4 = end address of buffer
*   d4 = line header length
*   d6 = line header address 
importModuleProgramFromDataSkipHeader:
	pushm	d1-a6
 if DEBUG
	move.l	a3,d0 
	move.l	a4,d1
	DPRINT	"importModuleProgramFromDataSkipHdr %lx %lx"
 endif
	moveq	#0,d7 		* count
	move.l	a4,d5		* use this register
	move.l	a2,a4 		* list header here
	bra	importModuleProgramFromData\.r1

* in:
*   a2 = list header
*   a3 = data read from file
*   a4 = end address of buffer
* out:
*   d0 = number of modules  
importModuleProgramFromData:
	pushm	d1-a6
 if DEBUG
	move.l	a3,d0 
	move.l	a4,d1
	DPRINT	"importModuleProgramFromData %lx %lx"
 endif

* Free:
* d3
* d4
* d6

	moveq	#0,d7 		* count
	
	move.l	a3,d0
	beq.w	.x2

	moveq	#0,d4		* no line header
	moveq	#0,d6		* no line header

	move.l	a4,d5		* use this register
	move.l	a2,a4 		* list header here

	;moveq	#0,d6		* 0 = vanha formaatti

	cmp.l	#"HiPP",(a3)
	bne		.what
	cmp	#"rg",4(a3)
	bne		.what
.r2	cmp.b	#10,(a3)+	* skipataan kaks rivinvaihtoa
	bne.b	.r2
	addq	#1,a3
.r1
	
;	lea	moduleListHeader(a5),a4
;	move.l	a5,a4
.ploop

	* Is this an url?
	moveq	#0,d3	* local
	cmp.b	#"h",(a3)
	bne.b	.local
	cmp.b	#"t",1(a3)
	bne.b	.local
	cmp.b	#"t",2(a3)
	bne.b	.local
	cmp.b	#"p",3(a3)
	bne.b	.local
	move	#1,d3	* remote
.local

	move.l	a3,a0
	moveq	#10,d1
.r23	
	cmp.l	d5,a0
	bhs.w	.x2		* upper bound check
	;cmp.b	#10,(a0)+
	cmp.b	(a0)+,d1
	bne.b	.r23
	move.l	a0,d0
	sub.l	a3,d0	* pituus

	add.l	#1+l_size,d0	* nolla nimen per‰‰n ja listayksikˆn pituus
	add.l	d4,d0	* add extra header space if any
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	bsr.w	getmem
	bne.b	.gotMem2
	bsr.w	showOutOfMemoryError
	bra		.x2	
.gotMem2
	move.l	d0,a2

	* Copy filename 
	lea	l_filename(a2),a0

	cmp.b	#DIVIDER_MAGIC,(a3)
	bne.b	.notDiv2
	addq	#1,a3
	st	l_divider(a2)
.notDiv2

	* See if additional header should
	* be prepended to the line. This indicates
	* a remote url, it is used to add the base url address.
	tst.l	d6
	beq.b	.noHdr
	moveq	#1,d3	* remote!
	move.l	d6,a6
.copyHdr
	move.b	(a6)+,(a0)+
	bne.b	.copyHdr
	subq	#1,a0 * to NULL
.noHdr

	* Copy chars until line change
	moveq	#10,d1
.le	
	move.b	(a3)+,d2
	move.b	d2,(a0)+
	cmp.b	d1,d2
	bne.b	.le
	* Replace LF with NULL
	clr.b	-(a0)

	lea	l_filename(a2),a1
	tst.b	l_divider(a2)
	beq.b	.notDiv
	move.l	a1,a0
	bra.b	.wasDiv
.notDiv
	tst.b	d3
	beq.b	.wasLocal
	; Config this node as a remote node
	move.l	a2,a0
	jsr		configRemoteNode
	bra.b	.wasRemote
.wasLocal
	bsr.w	nimenalku
.wasDiv
	move.l	a0,l_nameaddr(a2)
.wasRemote

	* add node a1 to list a0	
	move.l	a2,a1
	move.l	a4,a0
	lore	Exec,AddTail
	addq.l	#1,d7

	move.l	a2,a0

	* protect a3, which is killed here
	push	a3
	jsr	updateFavoriteStatus
	pop 	a3

	cmp.l	#MAX_MODULES,d7
	bhs.b	.x2

	* Go until at the end of given buffer
	cmp.l	d5,a3
	blo.w	.ploop
.x2
	move.l	d7,d0
	popm	d1-a6
	rts

* unknown format
.what
	lea	unknown_module_program_error(pc),a1
	bsr.w	request
	bra.b  	.x2

unknown_module_program_error  dc.b	"Not a module program!",0
xpk_module_program_error	 dc.b	"Could not load XPK compressed module program!",0
 even


*** Etsii tiedoston nimest‰ (polku/nimi) pelk‰n tiedoston nimen alun
*** a0 <= loppu
*** a1 <= alku
*** a0 => nimi
nimenalku:
.f	move.b	-(a0),d0		* etsit‰‰n pelk‰n nimen alku
	cmp.b	#'/',d0
	beq.b	.fo
	cmp.b	#':',d0
	beq.b	.fo
	cmp.l	a1,a0
	bne.b	.f
	bra.b	.fof
.fo	addq.l	#1,a0
.fof rts


rsaveprog
	cmp.b 	#LISTMODE_FAVORITES,listMode(a5)
	beq.b	.x
	cmp.b 	#LISTMODE_BROWSER,listMode(a5)
	beq.b	.x
	DPRINT  "rsaveprog obtain list"
	bsr.w 	obtainModuleList
	bsr.w	 setMainWindowWaitPointer
	bsr.b	.doSaveProg
	bsr.w 	clearMainWindowWaitPointer
	DPRINT  "rloadprog release list"
	bsr.w 	releaseModuleList
.x	rts

.doSaveProg
	clr.b	movenode(a5)

	tst	filereq_prosessi(a5)
	bne.w	.ex

	tst.l	modamount(a5)
	beq.w	.nomods

	bsr.w	get_rt
	moveq	#RT_FILEREQ,D0
	sub.l	a0,a0
	lob	rtAllocRequestA
	move.l	d0,req_file2(a5)
	beq.w	.ex

	move.l	d0,a1			* Vaihdetaan hakemistoa...
	lea	newdir_tags(pc),a0
	pushpea	prgdir(a5),4(a0)
	lob	rtChangeReqAttrA

.eimuut
	move.l	req_file2(a5),a1	* pattern match
	lea	matchp_tags(pc),a0	
	lob	rtChangeReqAttrA


	lea	.t(pc),a0
	moveq	#50+WINX,d0
	bsr.w	printbox
	bra.b	.d
.t	dc.b	"Saving module program...",0
 even
.d

	lea	.tags(pc),a0
	
	move.l	req_file2(a5),a1
	lea	filename(a5),a2		* T‰nne tiedoston polku ja nimi

	lea	filereqtitle3(pc),a3
	lob	rtFileRequestA		* ReqToolsin tiedostovalikko
	tst.l	d0
	beq.b	.ex
	move.l	req_file2(a5),a0
	bsr.w	parsereqdir3

	lea	tempdir(a5),a0		* kopioidaan polku ja nimi yhdeksi
	lea	filename2(a5),a1
.c	move.b	(a0)+,(a1)+
	bne.b	.c
	subq.l	#1,a1
	lea	filename(a5),a0
.a	move.b	(a0)+,(a1)+
	bne.b	.a

	lea	tempdir(a5),a0
	lea	prgdir(a5),a1
.cpe2	move.b	(a0)+,(a1)+
	bne.b	.cpe2

	lea	filename2(a5),a0
	lea	moduleListHeader(a5),a1
	bsr.b exportModuleProgramToFile

	move.l	req_file2(a5),d0
	beq.b	.ex
	move.l	d0,a1
	move.l	_ReqBase(a5),a6
	lob	rtFreeRequest
.ex

	bsr.w	forceRefreshList
	rts

.nomods	lea	.lerr(pc),a1
	bra.w	request

.lerr	dc.b	"No program to save!",0
 even


.tags	dc.l	RTFI_Flags,FREQF_PATGAD
otag16	dc.l	RT_PubScrName,pubscreen+var_b,0


prgheader	dc.b	"HiPPrg",10,10	* headeri
headere


filereqtitle2
	dc.b	"Load module program",0
filereqtitle3
	dc.b	"Save module program",0
 even



* in:
*  a0 = filename
*  a1 = list
exportModuleProgramToFile:
 if DEBUG
	move.l	a0,d0
	DPRINT	"Exporting module list to %s"
 endif
	move.l	a1,a4
	move.l	_DosBase(a5),a6
	move.l	#1006,d2
	move.l	a0,d1
	lob	Open

	move.l	d0,d6
	beq		.openError	

	move.l	d6,d1
	lea	prgheader(pc),a0
	move.l	a0,d2
	moveq	#headere-prgheader,d3
	lob	Write

.saveloop
	* Get next and test for end
	TSTNODE	a4,a3
	beq.b	.exit
	move.l	a3,a4

	lea	-200(sp),sp
	move.l	sp,a1

	lea	l_filename(a3),a0
	tst.b	l_divider(a3)
	beq.b	.noDiv
	move.b	#DIVIDER_MAGIC,(a1)+
.noDiv


.co	move.b	(a0)+,(a1)+
	bne.b	.co
	subq	#1,a1
	move.b	#10,(a1)+

	move.l	a1,d3
	sub.l	sp,d3
	move.l	sp,d2
	move.l	d6,d1		* tallennetaan nimi
	lob	Write	

	lea	200(sp),sp

	cmp.l	d3,d0
	bne.b	.writeError
	bra.b	.saveloop
	
.exit
	move.l	d6,d1
	beq.b	.x
	lob	Close
.x	
	rts

.writeError
	lea	.err(pc),a1
	bsr.w	request
	bra.b	.exit

.openError
	lea	openerror_t,a1
	bsr.w	request
	bra.b	.exit

.err	dc.b	"Error while writing module program!",0
 even


*******************************************************************************
* Komentojono
*******

komentojono:
	DPRINT	"Processing command line parameters"

	* Ensure correct list mode before proceeding
	jsr	engageNormalMode

	lea	sv_argvArray+4(a5),a3	* ei ekaa
	moveq	#ARGVSLOTS-1-1,d7
	move.l	modamount(a5),d6	* vanha m‰‰r‰ talteen

* HIDEst‰ ja QUITista ei v‰litet‰!

*** Silmukka
.alp
	move.l	(a3)+,d5
	beq.w	.end

 if DEBUG
	move.l	d5,d0
	DPRINT	"->%ls"
 endif

	move.l	d5,a0
	bsr.w	kirjainta4
	cmp.l	#MESSAGE_COMMAND_HIDE,d0
	beq.b	.skip
	cmp.l	#MESSAGE_COMMAND_QUIT,d0
	beq.b	.skip
	cmp.l	#MESSAGE_COMMAND_PRG,d0
	bne.b	.hmm
	move.l	(a3),a0			* ohjelman nimi
	moveq	#-1,d4			* lippu
	bra.w	loadprog
.hmm

	move.l	d5,a0
	bsr		createListNodeAndAdd

.skip	dbf	d7,.alp

.end
	bsr.w	vastomaviesti

	tst.l	modamount(a5)
	beq.b	.x
	move.l	d6,chosenmodule(a5)	* ensimm‰inen uusi moduuli valituksi

	bsr.w	listChanged
	bsr.w	forceRefreshList
	bsr.w	rbutton1		* soitetaan 
.x	rts


* In:
*   a0 = File path
createListNodeAndAdd
	pushm	all
	move.l	a0,d5
.f	tst.b	(a0)+
	bne.b	.f
	move.l	a0,d0
	sub.l	d5,d0			* pituus

	add.l	#l_size,d0		* listayksikˆn pituus
	move.l	#MEMF_CLEAR,d1
	bsr.w	getmem
	beq.b	.end
	move.l	d0,a2

	lea	l_filename(a2),a0	* kopioidaan
	move.l	d5,a1
.c	move.b	(a1)+,(a0)+
	bne.b	.c

	lea	l_filename(a2),a1
	bsr.w	nimenalku
	move.l	a0,l_nameaddr(a2)

	move.l	a2,a1
	bsr.w	getVisibleModuleListHeader
	lore	Exec,AddTail

	* update favorite status for node a0
	move.l	a2,a0
	* destroys a2/a3 (no stack saving for speed there)
	jsr	updateFavoriteStatus

	addq.l	#1,modamount(a5)	* m‰‰r‰++
.end
	popm	all
	rts

*************
* Tokenisoidaan file match patterni

tokenizepattern
	pushm	all
	tst.b	uusikick(a5)
	beq.b	.feff
	lea	tokenizedpattern(a5),a0
	move.l	a0,d2
	lea	70*2+2(a0),a1
.f	clr	(a0)+
	cmp.l	a1,a0
	bne.b	.f

	pushpea	pattern(a5),d1
	move.l	#70*2+2,d3
	lore	Dos,ParsePatternNoCase
.feff	popm	all
	rts



*******************************************************************************
* Ladataan/tallennetaan prefs-tiedosto
***************************

loadprefs
	DPRINT 	"Load prefs"
	pushpea	prefsfilename(pc),d7

;	move.l	(a5),a0			* Kokeillaan ladata preffsi
;	cmp	#36,LIB_VERSION(a0)	* PROGDIR:ist‰
;	blo.b	.nah
;	move.l	#prefsfilename2,d1
;	move.l	d1,d4
;	move.l	#ACCESS_READ,d2
;	lore	Dos,Lock
;	move.l	d0,d1
;	beq.b	.nah
;	lob	UnLock
;	move.l	d4,d7
;.nah


* d7 = tied.nimi
loadprefs2

	push	d7
	move	#200,wbkorkeus(a5)
	move	#640,wbleveys(a5)
	move	#360,windowpos(a5)		* pistet‰‰n ikkunoiden paikat
	move	#23,windowpos+2(a5)
	move	#360,windowZippedPos(a5)
	move	#23,windowZippedPos+2(a5)
	move	#42,windowpos_p(a5)
	move	#18,windowpos_p+2(a5)
	;move	#259,quadpos(a5)
	;move	#157,quadpos+2(a5)
	bsr.w	aseta_vakiot

	pop	d1

	move.l	_DosBase(a5),a6
	move.l	#1005,d2
	lob	Open
	move.l	d0,d4
	beq.w	.nope
	lea	prefsdata(a5),a0
	move.l	a0,d2
	move.l	d0,d1
	move.l	#prefs_size,d3
	lob	Read

	cmp.b	#prefsversio,prefsdata(a5)	* Onko oikea versio?
	beq.b	.q

	DPRINT	"Old prefs, set some defaults"

* Vanha prefssi?
* Laitetaan defaultti archivejutut 
	bsr.w	defarc
* when migrating to a new prefs version I want the tooltips
* to be on by default!
	st	prefs_tooltips+prefsdata(a5)
.q
	cmp.l	#prefs_size,d0
	bhi.w	.eeee

	DPRINT	"Set values"

* Pistet‰‰n ladatut arvot yms. paikoilleen
	lea	prefsdata(a5),a0
	move.l	prefs_s3mrate(a0),mixirate(a5)
	move.b	prefs_play(a0),playmode(a5)
	move.b	prefs_show(a0),lootamoodi+1(a5)
	move.b	prefs_tempo(a0),tempoflag(a5)
	move.b	prefs_tfmxrate(a0),tfmxmixingrate+1(a5)
	move.b	prefs_s3mmode1(a0),s3mmode1(a5)
	move.b	prefs_s3mmode2(a0),s3mmode2(a5)
	move.b	prefs_s3mmode3(a0),s3mmode3(a5)
	
	;move.b	prefs_quadmode(a0),quadmode(a5)
	move.l	prefs_mainpos1(a0),windowpos(a5)
	move.l	prefs_mainpos2(a0),windowZippedPos(a5)
	move.l	prefs_prefspos(a0),windowpos_p(a5)
	;move.l	prefs_quadpos(a0),quadpos(a5)
	;move.b	prefs_quadon(a0),quadon(a5)
	move.b	prefs_ptmix(a0),ptmix(a5)
	move.b	prefs_xpkid(a0),xpkid(a5)
	move.b	prefs_fade(a0),fade(a5)
	move.b	prefs_pri(a0),d0
	ext	d0
	ext.l	d0
	move.l	d0,priority(a5)
	move.b	prefs_boxsize(a0),boxsize+1(a5)
	move.b	prefs_boxsize(a0),boxsize0+1(a5)
	move.b	prefs_doubleclick(a0),doubleclick(a5)
	move.b	prefs_startuponoff(a0),startuponoff(a5)
	move	prefs_timeout(a0),timeout(a5)
	move.b	prefs_hotkey(a0),hotkey(a5)
	move.b	prefs_cerr(a0),contonerr(a5)
	move.b	prefs_ps3mb(a0),ps3mb(a5)
	move.b	prefs_timeoutmode(a0),timeoutmode(a5)
	move.b	prefs_filter(a0),filterstatus(a5)
	move.b	prefs_vbtimer(a0),vbtimer(a5)
	move.b	prefs_groupmode(a0),groupmode(a5)
	move	prefs_alarm(a0),alarm(a5)
	move.b	prefs_stereofactor(a0),stereofactor(a5)
	move.b	prefs_div(a0),divdir(a5)
	move.b	prefs_prefix(a0),prefixcut(a5)
	move.b	prefs_early(a0),earlyload(a5)
	move.l	prefs_infopos2(a0),infopos2(a5)
	move.b	prefs_xfd(a0),xfd(a5)
	move	prefs_infosize(a0),infosize(a5)
	bne.b	.rr
	move	#16,infosize(a5)
.rr
	move.b	prefs_infoon(a0),infoon(a5)
	move.b	prefs_ps3msettings(a0),ps3msettings(a5)
	move.b	prefs_prefsivu(a0),prefsivu+1(a5)
	move.b	prefs_samplebufsiz(a0),samplebufsiz0(a5)
	move.b	prefs_cybercalibration(a0),cybercalibration(a5)
	move	prefs_forcerate(a0),sampleforcerate(a5)

	move.b	prefs_samplecyber(a0),samplecyber(a5)
	
	move.b	prefs_mpegaqua(a0),d0
	moveq	#0,d1
	moveq	#2,d2
	bsr.w	clampByte
	move.b	d0,mpegaqua(a5)
	
	move.b	prefs_mpegadiv(a0),d0 
	bsr.w	clampByte
	move.b	d0,mpegadiv(a5)

	move.b	prefs_medmode(a0),d0
	moveq	#0,d1
	moveq	#1,d2
	bsr.w	clampByte
	move.b	d0,medmode(a5)

	move	prefs_medrate(a0),medrate(a5)
	move.b	prefs_favorites(a0),favorites(a5)
	move.b	prefs_tooltips(a0),tooltips(a5)
	move.b	prefs_savestate(a0),savestate(a5)
	move.b  prefs_altbuttons(a0),altbuttons(a5)
 
	move.l	prefs_textattr(a0),text_attr+4		* ysize jne
	pushpea	prefs_fontname+prefsdata(a5),text_attr
	move.l	prefs_listtextattr(a0),list_text_attr+4		* ysize jne
	pushpea	prefs_listfontname+prefsdata(a5),list_text_attr

	st	newdirectory(a5)		* Lippu: uusi hakemisto

	bsr.b	sliderit
	bsr.w	setprefsbox
	bsr.w	mainpriority

.eee	
	move.l	d4,d1
	lob	Close	
.nope
	rts

.eeee	

	lea	prefsdata(a5),a0
	move	#prefs_size/2-1,d0
.zapit	clr	(a0)+
	dbf	d0,.zapit

	bsr.b	.eee
	bsr.w	aseta_vakiot

	lea	.err(pc),a1
	bra.w	request


.err	dc.b	"Trouble with the prefs file (wrong version?).",0
 even

* in:
*  d0 = value, can be negative
*  d1 = low bound
*  d2 = high bound
* out:
*  d0 = value within bounds
clampByte
	ext		d0 
	ext		d1 
	ext		d2
clampWord
	ext.l	d0
	ext.l	d1
	ext.l	d2
clamp
	cmp.l	d1,d0
	;blo.b	.low   
	blt.b	.low  
	cmp.l	d2,d0
	bhi.b	.high
	rts
.low	move.l	d1,d0
	rts
.high	move.l	d2,d0
	rts
	

sliderit
* mixingrate s3m

	move.l	mixirate(a5),d0
	sub.l	#5000,d0
	divu	#100,d0
	mulu	#65535,d0
	divu	#580-50,d0

	lea	pslider1,a0
	bsr.w	setknob2

* mixingrate tfmx
	lea	pslider2-pslider1(a0),a0
	move	tfmxmixingrate(a5),d0
	subq	#1,d0
	mulu	#65535,d0
	divu	#21,d0
	bsr.w	setknob2

* volumeboost ps3m
	lea	juusto-pslider2(a0),a0
	moveq	#0,d0
	move.b	s3mmode3(a5),d0
	mulu	#65535,d0
	divu	#16,d0
	bsr.w	setknob2

* stereoarvo ps3m
	lea	juust0-juusto(a0),a0
	moveq	#0,d0
	move.b	stereofactor(a5),d0
	mulu	#65535,d0
	divu	#64,d0
	bsr.w	setknob2

* timeout
	lea	kelloke-juust0(a0),a0
	move	timeout(a5),d0
	mulu	#65535,d0
	divu	#1800,d0		* 10*60 sekkaa
	bsr.w	setknob2

* alarm
	lea	kelloke2-kelloke(a0),a0
	move	alarm(a5),d1
	moveq	#0,d0
	move.b	d1,d0
	lsr	#8,d1
	mulu	#60,d1
	add	d1,d0

	mulu	#65535,d0
	divu	#1440,d0
	bsr.w	setknob2

* moduleinfo
	lea	eskimO-kelloke2(a0),a0
	move	infosize(a5),d0
	subq	#3,d0
	mulu	#65535,d0
	divu	#50-3,d0
	bsr.w	setknob2


* samplebuffersize
	lea	sIPULI-eskimO(a0),a0
	moveq	#0,d0
	move.b	samplebufsiz0(a5),d0
	mulu	#65535,d0
	divu	#5,d0
	bsr.w	setknob2

* sampleforcerate
	lea	sIPULI2-sIPULI(a0),a0
	moveq	#0,d0
	move	sampleforcerate(a5),d0
	mulu	#65535,d0
	divu	#600-9,d0
	bsr.w	setknob2



* ahi rate
	move.l	ahi_rate(a5),d0
	sub.l	#5000,d0
	divu	#100,d0
	mulu	#65535,d0
	divu	#580-50,d0

	lea	ahiG4-sIPULI2(a0),a0
	bsr.w	setknob2

* ahi master volume
	moveq	#0,d0
	move	ahi_mastervol(a5),d0
	mulu	#65535,d0
	divu	#1000,d0

	lea	ahiG5-ahiG4(a0),a0
	bsr.w	setknob2

* ahi stereo level
	moveq	#0,d0
	move	ahi_stereolev(a5),d0
	mulu	#65535,d0
	divu	#100,d0

	lea	ahiG6-ahiG5(a0),a0
	bsr.w	setknob2

* mixingrate med

	moveq	#0,d0
	move	medrate(a5),d0
	sub.l	#5000,d0
	divu	#100,d0
	mulu	#65535,d0
	divu	#580-50,d0
	lea	nAMISKA5-ahiG6(a0),a0
	bsr.w	setknob2

	rts

* Update box size slider in prefs
setprefsbox
* boxsize
	lea	meloni,a0
	move	boxsize(a5),d0
	beq.b	.x
	subq	#2,d0
.x	mulu	#65535,d0
	divu	#51-3,d0
	bra.w	setknob2

setPrefsInfoBox
	lea	eskimO,a0
	move	infosize(a5),d0
	subq	#3,d0
	mulu	#65535,d0
	divu	#50-3,d0
	bra		setknob2

saveprefs
	DPRINT	"Prefs save"
	move.l	windowbase(a5),d0
	beq.b	.h
	move.l	d0,a0
	tst.b	kokolippu(a5)
	beq.b	.smal
	move.l	4(a0),windowpos(a5)
	bra.b	.h
.smal	move.l	4(a0),windowZippedPos(a5)

.h	move.l	windowbase2(a5),d0
	beq.b	.g
	move.l	d0,a0
	move.l	4(a0),windowpos_p(a5)
.g	

	tst	info_prosessi(a5)
	sne	prefs_infoon+prefsdata(a5)

	move.l	swindowbase(a5),d0
	beq.b	.gg
	move.l	d0,a0
	move.l	4(a0),infopos2(a5)
.gg


* Arvot yms. prefs-tiedostoon
	lea	prefsdata(a5),a0
	move.b	#prefsversio,(a0)
	move.l	mixirate(a5),prefs_s3mrate(a0)
	move.b	playmode(a5),prefs_play(a0)
	move.b	lootamoodi+1(a5),prefs_show(a0)
	move.b	tempoflag(a5),prefs_tempo(a0)
	move.b	tfmxmixingrate+1(a5),prefs_tfmxrate(a0)
	move.b	s3mmode1(a5),prefs_s3mmode1(a0)
	move.b	s3mmode2(a5),prefs_s3mmode2(a0)
	move.b	s3mmode3(a5),prefs_s3mmode3(a0)
	move.l	windowpos(a5),prefs_mainpos1(a0)
	move.l	windowZippedPos(a5),prefs_mainpos2(a0)
	move.l	windowpos_p(a5),prefs_prefspos(a0)
	move.b	ptmix(a5),prefs_ptmix(a0)
	move.b	xpkid(a5),prefs_xpkid(a0)
	move.b	fade(a5),prefs_fade(a0)
	move.b	priority+3(a5),prefs_pri(a0)
	move.b	boxsize+1(a5),prefs_boxsize(a0)
	move.b	doubleclick(a5),prefs_doubleclick(a0)
	move.b	startuponoff(a5),prefs_startuponoff(a0)
	move	timeout(a5),prefs_timeout(a0)
	move.b	hotkey(a5),prefs_hotkey(a0)
	move.b	contonerr(a5),prefs_cerr(a0)
	move.b	ps3mb(a5),prefs_ps3mb(a0)
	move.b	timeoutmode(a5),prefs_timeoutmode(a0)
	move.b	filterstatus(a5),prefs_filter(a0)
	move.b	vbtimer(a5),prefs_vbtimer(a0)
	move.b	groupmode(a5),prefs_groupmode(a0)
	move	alarm(a5),prefs_alarm(a0)
	move.b	stereofactor(a5),prefs_stereofactor(a0)
	move.b	divdir(a5),prefs_div(a0)
	move.b	prefixcut(a5),prefs_prefix(a0)
	move.b	earlyload(a5),prefs_early(a0)
	move.l	infopos2(a5),prefs_infopos2(a0)
	move.b	xfd(a5),prefs_xfd(a0)
	move	infosize(a5),prefs_infosize(a0)
	move.b	ps3msettings(a5),prefs_ps3msettings(a0)
	move.b	prefsivu+1(a5),prefs_prefsivu(a0)
	move.b	kokolippu(a5),prefs_kokolippu(a0)
	not.b	prefs_kokolippu(a0)
	move.b	samplebufsiz0(a5),prefs_samplebufsiz(a0)
	move.b	cybercalibration(a5),prefs_cybercalibration(a0)
	move	sampleforcerate(a5),prefs_forcerate(a0)

	move.b	samplecyber(a5),prefs_samplecyber(a0)
	move.b	mpegaqua(a5),prefs_mpegaqua(a0)
	move.b	mpegadiv(a5),prefs_mpegadiv(a0)
	move.b	medmode(a5),prefs_medmode(a0)
	move	medrate(a5),prefs_medrate(a0)
	move.b	favorites(a5),prefs_favorites(a0)
	move.b	tooltips(a5),prefs_tooltips(a0)
	move.b	savestate(a5),prefs_savestate(a0)
	move.b	altbuttons(a5),prefs_altbuttons(a0)


	move.l	text_attr+4,prefs_textattr(a0)
	move.l	text_attr,a1
	lea	prefs_fontname(a0),a2
.cec	move.b	(a1)+,(a2)+
	bne.b	.cec

	move.l	list_text_attr+4,prefs_listtextattr(a0)
	move.l	list_text_attr,a1
	lea	prefs_listfontname(a0),a2
.cec2	move.b	(a1)+,(a2)+
	bne.b	.cec2


.ohi
	move.l	_DosBase(a5),a6
	pushpea	prefsfilename(pc),d1
	move.l	#1006,d2
	lob	Open
	move.l	d0,d4
	beq.b	.nope
	lea	prefsdata(a5),a0
	move.l	a0,d2
	move.l	d0,d1
	move.l	#prefs_size,d3
	lob	Write
	cmp.l	#prefs_size,d0
	bne.b	.eeef
.clc	move.l	d4,d1
	lob	Close
.nope	rts

.eeef	bsr.b	.clc
	lea	.errr(pc),a1
	bra.w	request

.errr	dc.b	"Couldn't save prefs file!",0

prefsfilename dc.b	"S:HippoPlayer.prefs",0
;prefsfilename2 dc.b	"PROGDIR:HippoPlayer.prefs",0
 even

*******************************************************************************
* Asetetaan vakioarvot yms.

defarc
	lea	.lha(pc),a0
	lea	arclha(a5),a1
	bsr.w	copyb

	lea	.zip(pc),a0
	lea	arczip(a5),a1
	bsr.w	copyb

	lea	.lzx(pc),a0
	lea	arclzx(a5),a1
	bsr.w	copyb

	lea	.arc(pc),a0
	lea	arcdir(a5),a1
	bra.w	copyb
;	rts

.arc	dc.b	"RAM:",0

.lha	dc.b	'c:lha >nil: x -IqmMNQw "%s"',0
* m	no messages for query
* q	be quiet
* M	no autoshow files
* N	no progress indicator
* I	ignore LHAOPTS variable
* Qw	disable wildcards


.lzx	dc.b 'c:lzx >nil: -m -q x "%s"',0

.zip
zipDecompressCommand
	dc.b	'c:unzip >nil: -jo "%s"',0
* j: do not create folders
* o: overwrite without asking
* qq	be very quiet

* decompress %s to stdout and redirect to current dir data file
gzipDecompressCommand
	dc.b	'gzip -d -c "%s" >gzData',0	

 even
	

aseta_vakiot
	DPRINT	"Set defaults"
	bsr.w	nupit
	move	#64,mainvolume(a5)
	move.l	#PLAYING_MODULE_NONE,playingmodule(a5)
	move.l	#PLAYING_MODULE_NONE,chosenmodule(a5)
	move	#12,tfmxmixingrate(a5)
	move.b	#pm_repeat,playmode(a5)		* lippu: toistetaan
	move.l	#10000,mixirate(a5)
	move	#CHECKSUM,textchecksum(a5)
	move	#12,tfmxmixingrate(a5)
	move.b	#2,s3mmode1(a5)
	move.b	#sm_surround,s3mmode2(a5)
	clr.b	s3mmode3(a5)
	move	#8,boxsize(a5)
	move	#8,boxsize0(a5)
	move.b	#2,ps3mb(a5)	* 4,8,16,32,64
	move.b	#32,stereofactor(a5)
	move	#16,infosize(a5)

	move	#8,text_attr+4

	lea	check_keyfile,a2

	lea	defgroup(pc),a0
	lea	groupname(a5),a1
	bsr.w	copyb
	
	st	newdirectory(a5)
	lea	.defdir1(pc),a0
	lea	moduledir(a5),a1
	bsr.w	copyb

	lea	.defdir1(pc),a0
	lea	prgdir(a5),a1
	bsr.w	copyb

	lea	.defdir2(pc),a0
	lea	arcdir(a5),a1
	bsr.b	copyb

	lea	.wb(pc),a0
	lea	pubscreen(a5),a1
	bsr.b	copyb

	lea	.pat(pc),a0
	lea	pattern(a5),a1
	bsr.b	copyb

	move.l	a2,keycheckroutine(a5)

	bra.w	defarc
;	rts

.defdir1 dc.b	"SYS:",0
.defdir2 dc.b	"RAM:",0
.wb	dc.b	"Workbench",0
.pat	dc.b	"~(#?.info|smpl.#?|#?.ins|#?.nt|#?.as|#?.instr|#?.ss)",0
defgroup dc.b	"S:"	
hipGroupFileName
	dc.b	"HippoPlayer.Group",0
 even

bcopy
copyb	move.b	(a0)+,(a1)+
	bne.b	copyb
	rts



******************************************************************************
* Lataa PS3M asetustiedoston

loadps3msettings

	move.l	_DosBase(a5),a6

; ifeq asm
;	tst.b	uusikick(a5)
;	beq.b	.old
;	lea	.n2(pc),a0
;	move.b	#"R",.n1-.n2(a0)
;	move.l	a0,d1
;	move.l	#1005,d2
;	lob	Open
;	move.l	d0,d4
;	bne.b	.ok
;.old
; endc

	lea	.n1(pc),a0
;	move.b	#'S',(a0)
	move.l	a0,d1
	move.l	#1005,d2
	lob	Open
	move.l	d0,d4
	beq.b	.xx
.ok
	move.l	d4,d1		* selvitet‰‰n filen pituus
	moveq	#0,d2	
	moveq	#1,d3
	lob	Seek
	move.l	d4,d1
	moveq	#0,d2	
	moveq	#1,d3
	lob	Seek
	move.l	d0,d5

	move.l	d4,d1		* alkuun
	moveq	#0,d2
	moveq	#-1,d3
	lob	Seek

	move.l	d5,d0
	moveq	#MEMF_PUBLIC,d1
	bsr.w	getmem
	move.l	d0,d7
	beq.b	.x

	move.l	d4,d1
	move.l	d7,d2
	move.l	d5,d3
	lob	Read
	cmp.l	d5,d0
	bne.b	.er

	move.l	d7,ps3msettingsfile(a5)
	bra.b	.x
.er
	move.l	d7,a0
	bsr.w	freemem

.x	move.l	d4,d1
	beq.b	.xx
	lob	Close	

.xx	rts


;.n2	dc.b	"PROGDI"
;.n1	dc.b	"R:HippoPlayer.PS3M",0
.n1	dc.b	"S:HippoPlayer.PS3M",0
 even


*********************************************************************
* Ladataan CyberSound 14-bit kalibraatiotiedosto

loadcybersoundcalibration
	tst.b	cybercalibration(a5)
	beq.b	.xx
	tst.l	calibrationaddr(a5)
	bne.b	.xx

	moveq	#0,d7


	move.l	_DosBase(a5),a6
	pushpea	calibrationfile(a5),d1
	move.l	#1005,d2
	lob	Open
	move.l	d0,d4
	bne.b	.ok

.err	lea	.er1(pc),a1
	bsr.w	request
	bra.b	.x
.ok

	move.l	#256,d0
	moveq	#MEMF_PUBLIC,d1
	bsr.w	getmem
	move.l	d0,d7
	beq.b	.err

	move.l	d4,d1
	move.l	d7,d2
	move.l	#256,d3
	lob	Read
	cmp.l	#256,d0
	bne.b	.err

	move.l	d7,calibrationaddr(a5)
	bra.b	.kos

.x
	tst.l	d7
	beq.b	.kos
	move.l	d7,a0
	bsr.w	freemem
.kos
	move.l	d4,d1
	beq.b	.xx
	lob	Close	
.xx	rts

.er1	dc.b	"Unable to load calibration file!",0
 even

******************************************************************************
* Piirt‰‰ tekstuurin ikkunaan

drawtexture:
	movem.l	d0-a6,-(sp)
	ext.l	d0
	ext.l	d1
	ext.l	d2
	ext.l	d3
	movem.l	d0-d3,-(sp)

	move.l	rp_AreaPtrn(a2),d6
	move.b	rp_AreaPtSz(a2),d7

	lea	.texture(pc),a0
	move.l	a0,rp_AreaPtrn(a2)
	move.b	#1,rp_AreaPtSz(a2)

	move.l	a2,a1
	move.l	pen_0(a5),d0
	lore	GFX,SetAPen
	move.l	a2,a1

	move.l	pen_3(a5),d0
	tst.b	uusikick(a5)
	bne.b	.n
	move.l	pen_1(a5),d0 * kick1.3: different color
.n
	lob	SetBPen

	movem.l	(sp)+,d0-d3
	move.l	a2,a1
	add	windowleft(a5),d0
	add	windowtop(a5),d1
	add	windowleft(a5),d2
	tst.b	uusikick(a5)
	bne.b	.nn
	addq	#2,d2 * kick1.3: more wider
.nn
	add	windowtop(a5),d3
	lob	RectFill

	move.l	a2,a1
	move.l	pen_1(a5),d0
	lob	SetAPen
	move.l	a2,a1
	move.l	pen_0(a5),d0
	lob	SetBPen

	move.l	d6,rp_AreaPtrn(a2)
	move.b	d7,rp_AreaPtSz(a2)
	
	movem.l	(sp)+,d0-a6
	rts

.texture dc	$5555,$aaaa



*******************************************************************************
*** SECTION *******************************************************************
*
* Preferences section
* - Prefs UI
*
*******************************************************************************


*******************************************************************************
* Preferences
* Luodaan erillinen prosessi
*******

* This will signal the prefs window to update itself.
updateprefs:
	; Called from scope, no logging
	;DPRINT	"Update prefs"
	pushm	all
	tst	prefs_prosessi(a5)
	beq.b	.x
	move.l	prefs_task(a5),d0
	beq.b	.x
	move.l	d0,a1
	moveq	#0,d0
	move.b	prefs_updateContentsSignal(a5),d1
	bset	d1,d0
	lore	Exec,Signal
.x	popm	all
	rts

* T‰m‰ aiheutti enforcer-hitin jos ei ollut prefs-taskia!

sulje_prefs
	tst	prefs_prosessi(a5)
	beq.b	.ww
	tst.l	prefs_task(a5)
	beq.b	.ww
	move.l	a6,-(sp)
	moveq	#0,d0			* signaali prefssille lopettamisesta
	move.b	prefs_closeSignal(a5),d1
	bset	d1,d0
	move.l	prefs_task(a5),a1
	lore	Exec,Signal
	move.l	(sp)+,a6
.w	tst	prefs_prosessi(a5)	* odotellaan..
	beq.b	.ww
	bsr.w	dela
	bra.b	.w
.ww	rts

rbutton20
;	bra.b	prefs_code

	tst	prefs_prosessi(a5)	* sammutus jos oli p‰‰ll‰
	bne.b	sulje_prefs

.ook	
	movem.l	d0-a6,-(sp)
	move.l	_DosBase(a5),a6
	pushpea	prefsprocname(pc),d1
;	moveq	#0,d2			* pri
	move.l	priority(a5),d2

	pushpea	prefs_segment(pc),d3
	lsr.l	#2,d3
	move.l	#3000,d4
	lob	CreateProc
	tst.l	d0
	beq.b	.error
	addq	#1,prefs_prosessi(a5)
.error	movem.l	(sp)+,d0-a6
	rts


	
prefs_code
	lea	var_b,a5
	addq	#1,prefs_prosessi(a5)	* Lippu: prosessi p‰‰ll‰

	printt	"TODO: refactor prefs data handling"

	clr.b	prefs_exit(a5)		* Lippu

	st	boxsize00(a5)

* Arvot yms. v‰liaikaismuuttujiin
	move.l	mixirate(a5),mixingrate_new(a5)
	move	tfmxmixingrate(a5),tfmxmixingrate_new(a5)
	move	lootamoodi(a5),lootamoodi_new(a5)
	move.b	tempoflag(a5),tempoflag_new(a5)
	move.b	playmode(a5),playmode_new(a5)
	move.b	newdirectory(a5),newdir_new(a5)
	move.b	s3mmode1(a5),s3mmode1_new(a5)
	move.b	s3mmode2(a5),s3mmode2_new(a5)
	move.b	s3mmode3(a5),s3mmode3_new(a5)
	move.b	ptmix(a5),ptmix_new(a5)
	move.b	xpkid(a5),xpkid_new(a5)
	move.b	fade(a5),fade_new(a5)
	move.b	priority+3(a5),pri_new(a5)
	move.b	doubleclick(a5),dclick_new(a5)
	move.b	startuponoff(a5),startuponoff_new(a5)
	move	boxsize(a5),boxsize_new(a5)
	bsr.w	setprefsbox
	move	timeout(a5),timeout_new(a5)
	move.b	hotkey(a5),hotkey_new(a5)
	move.b	contonerr(a5),cerr_new(a5)
	move.b	doublebuf(a5),dbf_new(a5)
	move.b	nastyaudio(a5),nasty_new(a5)
	move.b	ps3mb(a5),ps3mb_new(a5)
	move.b	timeoutmode(a5),timeoutmode_new(a5)
	move.b	vbtimer(a5),vbtimer_new(a5)
	move.b	groupmode(a5),groupmode_new(a5)
	move	alarm(a5),alarm_new(a5)
	move.b	stereofactor(a5),stereofactor_new(a5)
	move.b	divdir(a5),div_new(a5)
	move.b	prefixcut(a5),prefix_new(a5)
	move.b	earlyload(a5),early_new(a5)
	move.b	xfd(a5),xfd_new(a5)
	move	infosize(a5),infosize_new(a5)
	bsr	setPrefsInfoBox
	move.b	ps3msettings(a5),ps3msettings_new(a5)
	move.b	samplebufsiz0(a5),samplebufsiz_new(a5)
	move.b	cybercalibration(a5),cybercalibration_new(a5)
	move	sampleforcerate(a5),sampleforcerate_new(a5)

	move.b	samplecyber(a5),samplecyber_new(a5)
	move.b	mpegaqua(a5),mpegaqua_new(a5)
	move.b	mpegadiv(a5),mpegadiv_new(a5)
	move.b	medmode(a5),medmode_new(a5)
	move	medrate(a5),medrate_new(a5)
	move.b	favorites(a5),favorites_new(a5)
	move.b	tooltips(a5),tooltips_new(a5)
	move.b	savestate(a5),savestate_new(a5)
	move.b	altbuttons(a5),altbuttons_new(a5)

	move.b quadraScopeBars(a5),quadraScopeBars_new(a5)        
	move.b quadraScopeFBars(a5),quadraScopeFBars_new(a5)         
	move.b hippoScopeBars(a5),hippoScopeBars_new(a5)       
	move.b spectrumScopeBars(a5),spectrumScopeBars_new(a5)  


	move.l	ahi_rate(a5),ahi_rate_new(a5)
	move	ahi_mastervol(a5),ahi_mastervol_new(a5)
	move.l	ahi_mode(a5),ahi_mode_new(a5)
	move	ahi_stereolev(a5),ahi_stereolev_new(a5)
	move.b	ahi_use(a5),ahi_use_new(a5)
	move.b	ahi_muutpois(a5),ahi_muutpois_new(a5)

	move.b	autosort(a5),autosort_new(a5)


;	move.l	pslider1+gg_SpecialInfo,a0
;	move	pi_HorizPot(a0),s3mmixpot_new(a5)
;	move.l	pslider2+gg_SpecialInfo,a0
;	move	pi_HorizPot(a0),tfmxmixpot_new(a5)
;	move.l	juusto+gg_SpecialInfo,a0
;	move	pi_HorizPot(a0),volumeboostpot_new(a5)
;	move.l	juust0+gg_SpecialInfo,a0
;	move	pi_HorizPot(a0),stereofactorpot_new(a5)
;	move.l	meloni+gg_SpecialInfo,a0
;	move	pi_HorizPot(a0),boxsizepot_new(a5)
;	move.l	kelloke+gg_SpecialInfo,a0
;	move	pi_HorizPot(a0),timeoutpot_new(a5)
;	move.l	kelloke2+gg_SpecialInfo,a0
;	move	pi_HorizPot(a0),alarmpot_new(a5)
;	move.l	eskimO+gg_SpecialInfo,a0
;	move	pi_HorizPot(a0),infosizepot_new(a5)
;	move.l	sIPULI+gg_SpecialInfo,a0
;	move	pi_HorizPot(a0),samplebufsizpot_new(a5)
;	move.l	sIPULI2+gg_SpecialInfo,a0
;	move	pi_HorizPot(a0),sampleforceratepot_new(a5)

	lea	pslider1s+pi_HorizPot,a0
	move	(a0),s3mmixpot_new(a5)
	move	pslider2s-pslider1s(a0),tfmxmixpot_new(a5)
	move	juustos-pslider1s(a0),volumeboostpot_new(a5)
	move	juust0s-pslider1s(a0),stereofactorpot_new(a5)
	move	melonis-pslider1s(a0),boxsizepot_new(a5)
	move	kellokes-pslider1s(a0),timeoutpot_new(a5)
	move	kelloke2s-pslider1s(a0),alarmpot_new(a5)
	move	eskimOs-pslider1s(a0),infosizepot_new(a5)
	move	sIPULIs-pslider1s(a0),samplebufsizpot_new(a5)
	move	sIPULI2s-pslider1s(a0),sampleforceratepot_new(a5)
	move	ahiG4s-pslider1s(a0),ahi_ratepot_new(a5)
	move	ahiG5s-pslider1s(a0),ahi_mastervolpot_new(a5)
	move	ahiG6s-pslider1s(a0),ahi_stereolevpot_new(a5)
	move	nAMISKA5s-pslider1s(a0),medratepot_new(a5)

	lea	fontname_new(a5),a0
	lea	prefs_fontname+prefsdata(a5),a1
.cc	move.b	(a1)+,(a0)+
	bne.b	.cc

	lea	listfontname_new(a5),a0
	lea	prefs_listfontname+prefsdata(a5),a1
.cc2	
	move.b	(a1)+,(a0)+
	bne.b	.cc2
		
		
	lea	ack2,a3
	lea	arclha(a5),a0
	lea	arclha_new(a5),a1
	bsr.w	.copy

	lea	ack3-ack2(a3),a3
	lea	arczip(a5),a0
	lea	arczip_new(a5),a1
	bsr.w	.copy

	lea	ack4-ack3(a3),a3
	lea	arclzx(a5),a0
	lea	arclzx_new(a5),a1
	bsr.b	.copy

	lea	DuU0-ack4(a3),a3
	lea	pattern(a5),a0
	lea	pattern_new(a5),a1
	bsr.b	.copy


	lea	pubscreen_new(a5),a1
	lea	pubscreen(a5),a0
.w	move.b	(a0)+,(a1)+
	bne.b	.w

	lea	groupname(a5),a0
	lea	groupname_new(a5),a1
.ww	move.b	(a0)+,(a1)+
	bne.b	.ww

	lea	moduledir(a5),a0
	lea	moduledir_new(a5),a1
.www	move.b	(a0)+,(a1)+
	bne.b	.www

	lea	prgdir(a5),a0
	lea	prgdir_new(a5),a1
.wwww	move.b	(a0)+,(a1)+
	bne.b	.wwww

	lea	arcdir(a5),a0
	lea	arcdir_new(a5),a1
.wwwww	move.b	(a0)+,(a1)+
	bne.b	.wwwww
	

	lea	startup_new(a5),a1
	lea	startup(a5),a0
	moveq	#120-1,d0
	bsr.b	.cp2

	lea	calibrationfile(a5),a0
	lea	calibrationfile_new(a5),a1
.ww2	move.b	(a0)+,(a1)+
	bne.b	.ww2

	lea	ahi_name(a5),a0
	lea	ahi_name_new(a5),a1
.w32	move.b	(a0)+,(a1)+
	bne.b	.w32


	lea	fkeys_new(a5),a1
	lea	fkeys(a5),a0
	move	#10*120-1,d0
	bsr.b	.cp2

	bra.b	.ohi

.copy	
	move.l	gg_SpecialInfo(a3),a2
	move.l	si_Buffer(a2),a2	* Teksipuskuri

.c	move.b	(a0),(a1)+
	move.b	(a0)+,(a2)+
	bne.b	.c
	rts

.cp2	move.b	(a0)+,(a1)+
	dbf	d0,.cp2
	rts

.ohi


	bsr.w	inittick


	move	#GFLG_DISABLED,d0

	tst.b	uusikick(a5)		* uusi kick?
	bne.b	.uusi
** Disabloidaan screengadgetti!
;	or	d0,gg_Flags+pbutton13
** Disabloidaan ahi-valinta
	or	d0,gg_Flags+VaL6

.uusi

	move.l	_IntuiBase(a5),a6
	lea	winstruc2,a0
	move	wbkorkeus(a5),d0	* Onko ikkuna liian suuri?
	cmp	nw_Height(a0),d0	* Kutistetaan 200:aan pixeliin
	bhi.b	.ok
	move	d0,nw_Height(a0)
.ok

	move.l	windowpos_p(a5),(a0)	* Paikka

	bsr.w	tark_mahtu

	lob	OpenWindow
	move.l	d0,windowbase2(a5)
	beq.w	exprefs

	move.l	d0,a0
	move.l	wd_RPort(a0),rastport2(a5)
	move.l	wd_UserPort(a0),userport2(a5)

	bsr.w	setscrtitle


;	tst.b	uusikick(a5)
;	beq.b	.vanaha

	move.l	rastport2(a5),a2
	moveq	#4,d0
	moveq	#11,d1
	move	#452-6,d2
	move	#182-15,d3
	bsr.w	drawtexture

.ohih

* pagenappulot
	lea	VaL1,a0
	bsr.b	.cler2
	lea	VaL2-VaL1(a0),a0
	bsr.b	.cler2
	lea	VaL3-VaL2(a0),a0
	bsr.b	.cler2
	lea	VaL4-VaL3(a0),a0
	bsr.b	.cler2
	lea	VaL5-VaL4(a0),a0
	bsr.b	.cler2
	lea	VaL6-VaL5(a0),a0
	bsr.b	.cler2
	lea	VaL7-VaL6(a0),a0
	bsr.b	.cler2

* saveusecancel-alue
	lea	pbutton14,a0
	bsr.b	.cler2
	lea	pbutton6-pbutton14(a0),a0
	bsr.b	.cler2
	lea	pbutton7-pbutton6(a0),a0
	bsr.b	.cler2
	bra.b	.oru

.cler2
	movem	4(a0),d0/d1/d4/d5
	sub	windowleft(a5),d0
	sub	windowtop(a5),d1
	bra.w	pcler
.oru
;.vanaha


	move.l	rastport2(a5),a1
	move.l	fontbase(a5),a0
	lore	GFX,SetFont	




* sitten isket‰‰n gadgetit ikkunaan..
	move.l	windowbase2(a5),a0
	lea	gadgets2,a1
	moveq	#-1,d0
	moveq	#-1,d1
	sub.l	a2,a2
	lore	Intui,AddGList
	lea	gadgets2,a0
	move.l	windowbase2(a5),a1
	sub.l	a2,a2
	lob	RefreshGadgets


	move.l	rastport2(a5),a1
	move.l	pen_1(a5),d0
	lore	GFX,SetAPen
	move.l	pen_0(a5),d0
	move.l	rastport2(a5),a1
	lob	SetBPen


	move.l	(a5),a6
	sub.l	a1,a1
	lob	FindTask
	move.l	d0,prefs_task(a5)

	moveq	#-1,d0
	lob	AllocSignal
	move.b	d0,prefs_closeSignal(a5)
;	bmi.w	exprefs
	moveq	#-1,d0
	lob	AllocSignal
	move.b	d0,prefs_updateContentsSignal(a5)
;	bmi.w	exprefs

	bsr.w	prefsgads


	moveq	#12,d4			* laatikko
	moveq	#31,d5
	move	#439,d6
	move	#146,d7
	add	windowleft(a5),d4
	add	windowleft(a5),d6
	add	windowtop(a5),d5
	add	windowtop(a5),d7
	move.l	rastport2(a5),a1
	bsr.w	laatikko3


	bra.b	msgloop2
returnmsg2
	bsr.w	flush_messages2
msgloop2
	tst.b	prefs_exit(a5)
	bne.w	exprefs

	move.l	(a5),a6
	moveq	#0,d0
	move.l	userport2(a5),a4
	move.b	MP_SIGBIT(a4),d1	* IDCMP signalibitti
	bset	d1,d0
	move.b	prefs_closeSignal(a5),d1	* oma signaali
	bset	d1,d0
	move.b	prefs_updateContentsSignal(a5),d1	* oma signaali ikkunan p‰ivitykseen
	bset	d1,d0
	lob	Wait			* Odotellaan...

	move.b	prefs_closeSignal(a5),d1	* k‰skeekˆ p‰‰ohjelma lopettamaan?
	btst	d1,d0
	bne.w	exprefs

	move.b	prefs_updateContentsSignal(a5),d1	* p‰ivitys?
	btst	d1,d0
	beq.b	.naa
	* Update window!
	pushm	all
	cmp	#4,prefsivu(a5)
	bne.b	.er
	* Done only for page 4?
	bsr.w	prefsgads
	bra.b	.er2
.er	bsr.w	pupdate
.er2	popm	all
.naa

* Vastataan IDCMP:n viestiin

	move.l	userport2(a5),a4
	move.l	a4,a0
	lob	GetMsg
	tst.l	d0
	beq.b	msgloop2

	move.l	d0,a1
	move.l	im_Class(a1),d2		* luokka	
	move	im_Code(a1),d3		* koodi
	move.l	im_IAddress(a1),a2 	* gadgetin tai olion osoite
	move	im_MouseX(a1),d6	* mousen koordinaatit
	move	im_MouseY(a1),d7

	lob	ReplyMsg

	cmp.l	#IDCMP_RAWKEY,d2
	bne.b	.nr
	tst.b	d3
	bmi.w	returnmsg2
	move	d3,rawkeyinput(a5)
	move.b	rawKeySignal(a5),d1
	bsr.w	signalit
	bra.w	returnmsg2
.nr
	cmp.l	#IDCMP_MOUSEMOVE,d2
	beq.w	mousemoving2
	cmp.l	#IDCMP_GADGETUP,d2
	beq.w	gadgetsup2
	cmp.l	#IDCMP_MOUSEBUTTONS,d2
	beq.w	pmousebuttons
	cmp.l	#IDCMP_CLOSEWINDOW,d2
	bne.w	msgloop2

	bsr.w	flush_messages2

exprefs	move.l	_IntuiBase(a5),a6		

	move.l	windowbase2(a5),d0
	beq.b	.eek

	move.l	d0,a0
	move.l	prefsivugads(a5),d0
	beq.b	.hh
	move.l	d0,a1
	moveq	#-1,d0
	moveq	#-1,d1
	sub.l	a2,a2
	lob	RemoveGList
	clr.l	prefsivugads(a5)
.hh
	move.l	windowbase2(a5),a0
	move.l	4(a0),windowpos_p(a5)
	lob	CloseWindow
	clr.l	windowbase2(a5)
.eek
	move.l	(a5),a6

	moveq	#0,d0
	move.b	prefs_closeSignal(a5),d0
	bmi.b	.yyk
	lob	FreeSignal
.yyk	
	moveq	#0,d0
	move.b	prefs_updateContentsSignal(a5),d0
	bmi.b	.yyk2
	lob	FreeSignal
.yyk2

	bsr.w	freepubwork		* Vapautetaan mahd. pubscreenlocki
	clr.l	pubwork(a5)

	tst.b	prefs_exit(a5)
	beq.w	.cancelled
	cmp.b	#-1,prefs_exit(a5)	* Cancel
	beq.w	.cancelled

** USE
	DPRINT	"Prefs use"

	move.l	mixingrate_new(a5),mixirate(a5)
	move	tfmxmixingrate_new(a5),tfmxmixingrate(a5)
	move	lootamoodi_new(a5),lootamoodi(a5)
	move.b	tempoflag_new(a5),tempoflag(a5)
	move.b	playmode_new(a5),playmode(a5)
	move.b	s3mmode1_new(a5),s3mmode1(a5)
	move.b	s3mmode2_new(a5),s3mmode2(a5)
	move.b	s3mmode3_new(a5),s3mmode3(a5)
	move.b	ptmix_new(a5),ptmix(a5)
	move.b	xpkid_new(a5),xpkid(a5)
	move.b	fade_new(a5),fade(a5)
	move.b	pri_new(a5),d0
	ext	d0
	ext.l	d0
	move.l	d0,priority(a5)
	move	boxsize_new(a5),boxsize(a5)
	move.b	dclick_new(a5),doubleclick(a5)
	move.b	startuponoff_new(a5),startuponoff(a5)
	move	timeout_new(a5),timeout(a5)
	move.b	hotkey_new(a5),hotkey(a5)
	move.b	cerr_new(a5),contonerr(a5)
	move.b	dbf_new(a5),doublebuf(a5)
	move.b	nasty_new(a5),nastyaudio(a5)
	move.b	ps3mb_new(a5),ps3mb(a5)
	move.b	timeoutmode_new(a5),timeoutmode(a5)
	move.b	vbtimer_new(a5),vbtimer(a5)
	move.b	groupmode_new(a5),groupmode(a5)

	move	alarm_new(a5),alarm(a5)
	move.b	stereofactor_new(a5),stereofactor(a5)
	move.b	div_new(a5),divdir(a5)
	move.b	prefix_new(a5),prefixcut(a5)
	move.b	early_new(a5),earlyload(a5)
	move.b	xfd_new(a5),xfd(a5)
	move.b	ps3msettings_new(a5),ps3msettings(a5)
	move.b	samplebufsiz_new(a5),samplebufsiz0(a5)
	move.b	cybercalibration_new(a5),cybercalibration(a5)
	move	sampleforcerate_new(a5),sampleforcerate(a5)

	move.b	samplecyber_new(a5),samplecyber(a5)
	move.b	mpegaqua_new(a5),mpegaqua(a5)
	move.b	mpegadiv_new(a5),mpegadiv(a5)
	move.b	medmode_new(a5),medmode(a5)
	move	medrate_new(a5),medrate(a5)

	move.l	ahi_rate_new(a5),ahi_rate(a5)
	move	ahi_mastervol_new(a5),ahi_mastervol(a5)
	move.l	ahi_mode_new(a5),ahi_mode(a5)
	move	ahi_stereolev_new(a5),ahi_stereolev(a5)
	move.b	ahi_use_new(a5),ahi_use(a5)
	move.b	ahi_muutpois_new(a5),ahi_muutpois(a5)

	move.b	favorites_new(a5),favorites(a5)
	move.b	tooltips_new(a5),tooltips(a5)
	move.b	savestate_new(a5),savestate(a5)

	move.b	altbuttons(a5),d0
	move.b	altbuttons_new(a5),altbuttons(a5)
	cmp.b	altbuttons(a5),d0
	beq.b	.1
	DPRINT	"Alt buttons changed"
	* magic! causes reopening of the main window:
	clr	boxsize00(a5)
.1

	move.b	autosort_new(a5),autosort(a5)

;	move	infosize_new(a5),infosize(a5)

	move	infosize(a5),d0
	move	infosize_new(a5),infosize(a5)
	cmp	infosize(a5),d0
	beq.b	.eimu
	tst	info_prosessi(a5)
	beq.b	.eimu
** updatetaan infoikkunaa
	bsr.w	sulje_info
	move.b	oli_infoa(a5),d7
	st	oli_infoa(a5)
	push	d7
	bsr.w	start_info
	pop	d7
	move.b	d7,oli_infoa(a5)

.eimu

** asetetaan fontti
	tst	boxsize00(a5)
	bne.w	.enor
	clr	boxsize0(a5)

	;tst.b	uusikick(a5)
	;beq.b	.enor
	tst.l	_DiskFontBase(a5)	* lib?
	beq.w	.enor

	lore	Exec,Forbid

	lea	text_attr,a4
	basereg	text_attr,a4

	move.l	prefs_textattr+prefsdata(a5),text_attr+4(a4)
	pushpea	prefs_fontname+prefsdata(a5),text_attr(a4)

	move.l	fontbase(a5),a1
	lore	GFX,CloseFont
	lea	text_attr(a4),a0
	lore	DiskFont,OpenDiskFont
	move.l	d0,fontbase(a5)
	move.l	d0,stringExtendStruct+sex_Font(a5)
	
	move.l	prefs_listtextattr+prefsdata(a5),list_text_attr+4(a4)
	pushpea	prefs_listfontname+prefsdata(a5),list_text_attr(a4)

	move.l	listfontbase(a5),a1
	lore	GFX,CloseFont
	lea	list_text_attr(a4),a0
	lore	DiskFont,OpenDiskFont
	move.l	d0,listfontbase(a5)
	bne.b	.gotFont
	
	lea	list_text_attr(a4),a0	
	pushpea	topaz(a4),(a0)+
	move	#8,(a0)+
	clr	(a0)
	lea	topaz_text_attr(a4),a0
	lore	GFX,OpenFont
	move.l	d0,listfontbase(a5)
	DPRINT	"revert topaz"
.gotFont
	move.l	d0,a0
	bsr.w	setListFont

	endb	a4

	lore	Exec,Permit

	tst	info_prosessi(a5)
	beq.b	.enor
	bsr.w	rbutton10b
	bsr.w	rbutton10b
.enor


	tst.b	newdirectory(a5)
	beq.b	.aaps
	lea	moduledir_new(a5),a0
	lea	moduledir(a5),a1
	bsr.w	.copy
.aaps
	tst.b	newdirectory2(a5)
	beq.b	.aaps2
	lea	prgdir_new(a5),a0
	lea	prgdir(a5),a1
	bsr.w	.copy
.aaps2
	lea	arcdir_new(a5),a0
	lea	arcdir(a5),a1
	bsr.w	.copy

	lea	arclha_new(a5),a0
	lea	arclha(a5),a1
	bsr.w	.copy
	lea	arczip_new(a5),a0
	lea	arczip(a5),a1
	bsr.w	.copy
	lea	arclzx_new(a5),a0
	lea	arclzx(a5),a1
	bsr.w	.copy
	lea	pattern_new(a5),a0
	lea	pattern(a5),a1
	bsr.b	.copy

	lea	pubscreen_new(a5),a0
	lea	pubscreen(a5),a1
	bsr.b	.copy

	lea	groupname_new(a5),a0
	lea	groupname(a5),a1
	bsr.b	.copy

	lea	calibrationfile_new(a5),a0
	lea	calibrationfile(a5),a1
	bsr.b	.copy

	lea	ahi_name_new(a5),a0
	lea	ahi_name(a5),a1
	bsr.b	.copy

	lea	startup_new(a5),a0
	lea	startup(a5),a1
	moveq	#120-1,d0
	bsr.b	.copy2

	lea	fkeys_new(a5),a0
	lea	fkeys(a5),a1
	move	#10*120-1,d0
	bsr.b	.copy2


* ladataan caib fle jos tarpeen

	tst.b	cybercalibration(a5)
	beq.b	.dw
	tst.l	calibrationaddr(a5)
	beq.b	.dw2
	tst.b	newcalibrationfile(a5)
	beq.b	.dw
	move.l	calibrationaddr(a5),a0
	bsr.w	freemem
	clr.l	calibrationaddr(a5)
.dw2	bsr.w	loadcybersoundcalibration
.dw	clr.b	newcalibrationfile(a5)



	cmp.b	#2,prefs_exit(a5)	* Tallennetaanko??
	bne.w	.jee
	bsr.w	saveprefs
	bra.w	.jee

.copy	move.b	(a0)+,(a1)+
	bne.b	.copy
	rts
.copy2	move.b	(a0)+,(a1)+
	dbf	d0,.copy2
	rts

.cancelled
	DPRINT	"Prefs cancel"
* Pistet‰‰n vanhat asennot propgadgetteihin
;	move.l	pslider1+gg_SpecialInfo,a0
;	move	s3mmixpot_new(a5),pi_HorizPot(a0)
;	move.l	pslider2+gg_SpecialInfo,a0
;	move	tfmxmixpot_new(a5),pi_HorizPot(a0)
;	move.l	juusto+gg_SpecialInfo,a0
;	move	volumeboostpot_new(a5),pi_HorizPot(a0)
;	move.l	juust0+gg_SpecialInfo,a0
;	move	stereofactorpot_new(a5),pi_HorizPot(a0)
;	move.l	meloni+gg_SpecialInfo,a0
;	move	boxsizepot_new(a5),pi_HorizPot(a0)
;	move.l	eskimO+gg_SpecialInfo,a0
;	move	infosizepot_new(a5),pi_HorizPot(a0)
;	move.l	kelloke+gg_SpecialInfo,a0
;	move	timeoutpot_new(a5),pi_HorizPot(a0)
;	move.l	kelloke2+gg_SpecialInfo,a0
;	move	alarmpot_new(a5),pi_HorizPot(a0)
;	move.l	sIPULI+gg_SpecialInfo,a0
;	move	samplebufsizpot_new(a5),pi_HorizPot(a0)
;	move.l	sIPULI2+gg_SpecialInfo,a0
;	move	sampleforceratepot_new(a5),pi_HorizPot(a0)


	lea	pslider1s+pi_HorizPot,a0
	move	s3mmixpot_new(a5),(a0)
	move	tfmxmixpot_new(a5),pslider2s-pslider1s(a0)
	move	volumeboostpot_new(a5),juustos-pslider1s(a0)
	move	stereofactorpot_new(a5),juust0s-pslider1s(a0)
	move	boxsizepot_new(a5),melonis-pslider1s(a0)
	move	infosizepot_new(a5),eskimOs-pslider1s(a0)
	move	timeoutpot_new(a5),kellokes-pslider1s(a0)		
	move	alarmpot_new(a5),kelloke2s-pslider1s(a0)
	move	samplebufsizpot_new(a5),sIPULIs-pslider1s(a0)	
	move	sampleforceratepot_new(a5),sIPULI2s-pslider1s(a0)	
	move	ahi_ratepot_new(a5),ahiG4s-pslider1s(a0)
	move	ahi_mastervolpot_new(a5),ahiG5s-pslider1s(a0)
	move	ahi_stereolevpot_new(a5),ahiG6s-pslider1s(a0)
	move	medratepot_new(a5),nAMISKA5s-pslider1s(a0)


	move.b	newdir_new(a5),newdirectory(a5)

	move.l	text_attr+4,prefs_textattr+prefsdata(a5)
	lea	fontname_new(a5),a0
	lea	prefs_fontname+prefsdata(a5),a1
.cec	move.b	(a0)+,(a1)+
	bne.b	.cec

	move.l	list_text_attr+4,prefs_listtextattr+prefsdata(a5)
	lea	listfontname_new(a5),a0
	lea	prefs_listfontname+prefsdata(a5),a1
.cec2
	move.b	(a0)+,(a1)+
	bne.b	.cec2


	move	boxsize(a5),boxsize0(a5)	* ei vaihdettu fonttia..
	

	move.b	s3mmode3(a5),s3mmode3_new(a5)
	bsr.w	updateps3m
	move.b	stereofactor(a5),stereofactor_new(a5)
	bsr.w	updateps3m2

	move	ahi_mastervol(a5),ahi_mastervol_new(a5)
	move	ahi_stereolev(a5),ahi_stereolev_new(a5)
	bsr.w	updateahi

	

	clr.b	newpubscreen2(a5)
.jee	

	lore	Exec,Forbid		* kielletaan muut taskit!

	bsr.w	mainpriority

	move.b	ownsignal2(a5),d1
	bsr.w	signalit		* signaali: poistutaan preffsist‰..

	st	prefsexit(a5)

	move.b	newpubscreen2(a5),newpubscreen(a5)
	clr.b	newpubscreen2(a5)
	
	clr.l	prefs_task(a5)
	clr	prefs_prosessi(a5)	* Lippu: prosessi poistettu
	rts

flush_messages2
	move.l	windowbase2(a5),a0 
	bra.w	flushWindowMessages



* d0,d1: x,y
* d4,d5: x-koko,y-koko

pcler	
	push	a0
	move.l	rastport2(a5),a0
	move.l	a0,a1
	add	windowleft(a5),d0
	add	windowtop(a5),d1
	move	d0,d2
	move	d1,d3
	moveq	#$0a,d6
	lore	GFX,ClipBlit
	pop	a0
	rts



****************************************************************
*** T‰r‰ytet‰‰n ikkunaan oikean sivun gadgetit


prefsgads2
	cmp	prefsivu(a5),d0
	beq.b	.xx
	move	d0,prefsivu(a5)
	bra.b	prefsgads
.xx	rts

prefsgads
** Valinta nappulan 'highlight'

	lea	VaL1,a0
	moveq	#7-1,d0
	moveq	#0,d2
.lup	move.l	pen_1(a5),d1
	cmp	prefsivu(a5),d2
	bne.b	.no
	move.l	pen_2(a5),d1
	tst.b	uusikick(a5)
	bne.b	.no
	move.l	pen_3(a5),d1
.no	move.l	gg_GadgetText(a0),a1
	move.b	d1,it_FrontPen(a1)
	move.l	(a0),a0
	addq	#1,d2
	dbf	d0,.lup
	lea	VaL1,a0
	moveq	#6,d0
	move.l	windowbase2(a5),a1
	sub.l	a2,a2
	lore	Intui,RefreshGList


	moveq	#13,d0		* laatikko
	moveq	#32,d1
	move	#439,d4
	move	#146,d5
	sub	d0,d4
	sub	d1,d5
	bsr.w	pcler

	move.l	windowbase2(a5),a0
	move.l	prefsivugads(a5),d0
	beq.b	.hh
	move.l	d0,a1
	moveq	#-1,d0
	moveq	#-1,d1
	sub.l	a2,a2
	lore	Intui,RemoveGList
.hh

	lea	sivu0,a1
	move	prefsivu(a5),d0
	beq.b	.yy
	lea	sivu1-sivu0(a1),a1
	subq	#1,d0
	beq.b	.yy
	lea	sivu2-sivu1(a1),a1
	subq	#1,d0
	beq.b	.yy
	lea	sivu3-sivu2(a1),a1
	subq	#1,d0
	beq.b	.yy
	lea	sivu4-sivu3(a1),a1
	subq	#1,d0
	beq.b	.yy
	lea	sivu5-sivu4(a1),a1
	subq	#1,d0
	beq.b	.yy
	lea	sivu6-sivu5(a1),a1
.yy

	move.l	a1,prefsivugads(a5)

	move.l	windowbase2(a5),a0
	moveq	#-1,d0
	moveq	#-1,d1
	sub.l	a2,a2
	lore	Intui,AddGList

	* Remove "Early load" gadget
	move.l	windowbase2(a5),a0
	lea	bUu3,a1
	lob	RemoveGadget

	lea	gadgets2,a0
	move.l	windowbase2(a5),a1
	sub.l	a2,a2
	lob	RefreshGadgets


;	tst.b	uusikick(a5)
;	beq.w	.loru

*** Gadgettien reunojen vahvistus
	lea	gadgets2,a3
.loloop
	move.l	(a3),d3

;	moveq	#GTYP_GTYPEMASK,d7
;	and	gg_GadgetType(a3),d7	* tyyppi
;	cmp.b	#GTYP_PROPGADGET,d7	* ei kosketa slidereihim
;	beq.b	.sli
;	cmp.b	#GTYP_STRGADGET,d7	* eik‰ stringeihin
;	beq.b	.nel

	move	gg_GadgetType(a3),d7
	subq.b	#GTYP_PROPGADGET,d7
	beq.b	.sli
	subq.b	#GTYP_STRGADGET-GTYP_PROPGADGET,d7
	beq.b	.nel	

	jsr	drawButtonFramePrefsWindow

.nel	move.l	d3,a3
	tst.l	d3
	bne.b	.loloop
	bra.b	.loru

.sli
	;tst.b	uusikick(a5)
	;beq.b	.nel

	movem	4(a3),plx1/ply1/plx2/ply2	* fileslider
	add	plx1,plx2
	add	ply1,ply2
	subq	#2,plx1
	addq	#1,plx2
	subq	#2,ply1
	addq	#1,ply2
	push	d3
	move.l	rastport2(a5),a1
	bsr.w	sliderlaatikko
	pop	d3

	bra.b	.nel


.loru


	move.l	rastport2(a5),a1
	move.l	pen_1(a5),d0
	lore	GFX,SetAPen
	move.l	pen_0(a5),d0
	move.l	rastport2(a5),a1
	lob	SetBPen


	bra.w	pupdate
	


****************** 

mousemoving2			* P‰ivitet‰‰n propgadgetteja
	movem.l	d0-a6,-(sp)

	move	prefsivu(a5),d0
	bne.b	.x	
	bsr.w	psup4		* timeout
	bsr.w	purealarm	* alarm
	bra.b	.z
.x
	subq	#1,d0
	bne.b	.2
	bsr.w	pbox		* box size
	bsr.w	pinfosize
	bra.b	.z
.2
	subq	#1,d0
	bne.b	.3
	bra.b	.z
.3
	subq	#2,d0
	bne.b	.4
	
	bsr.w	pupdate7	* ps3m volboost
	bsr.w	pupdate7b	* ps3m stereo
	bsr.w	psup1		* ps3m mixingrate
	bra.b	.z

.4
	subq	#1,d0
	bne.b	.5
	
	bsr.w	pahi4		* ahi mixing rate
	bsr.w	pahi5		* ahi master volume
	bsr.w	pahi6		* ahi stereolev
	bra.b	.z

.5
	bsr.w	psup2		* tfmx mixingrate
	bsr.w	psup2b		* samplebufsiz
	bsr.w	psup2c		* sampleforcerate
	bsr.w	pupmedrate	* med mixing rate
	

.z	movem.l	(sp)+,d0-a6
	bra.w	returnmsg2


*** Oikeata nappulaa painettu. Tutkitaan oliko gadgetin p‰‰ll‰ jolla on
*** requesteri.
pmousebuttons
	cmp	#MENUDOWN,d3		* oikea nappula
	bne.w	returnmsg2

	pushm	all

	move	prefsivu(a5),d0
	bne.b	.1

	lea	pbutton1,a0		* play
	lea	rpbutton2_req(pc),a2
	bsr.w	.check
	lea	tomaatti,a0		* priority
	lea	rpri_req(pc),a2
	bsr.w	.check
; Early load has been disabled 
;	lea	bUu3,a0
;	lea	rearly_req(pc),a2
;	bsr.w	.check
	bra.w	.xx

.1	subq	#1,d0
	bne.b	.2

	lea	pbutton2,a0		* show
	lea	rpbutton1_req(pc),a2
	bsr.w	.check
	;lea	pout3,a0		* scope type
	;lea	rquadm_req(pc),a2
	;bsr.w	.check
	lea	bUu2,a0			* prefix cut
	lea	rprefx_req(pc),a2
	bsr.w	.check
	bra.b	.xx

.2	subq	#1,d0
	bne.b	.3

	lea	pout1,a0		* filter control
	lea	rpfilt_req(pc),a2
	bsr.b	.check
	lea	laren1,a0		* pt replayer
	lea	rptmix_req(pc),a2
	bsr.b	.check
	lea	PoU2,a0
	lea	rpgmode_req(pc),a2
	bsr.b	.check
	bra.b	.xx

.3	subq	#2,d0
	bne.b	.4

	lea	smode2,a0		* ps3m playmode
	lea	rsmode1_req(pc),a2	
	bsr.b	.check
	lea	smode1,a0		* ps3m state
	lea	rsmode2_req(pc),a2
	bsr.b	.check
	lea	jommo,a0		* ps3m buffer size
	lea	rps3mb_req(pc),a2
	bsr.b	.check
	bra.b	.xx
	
					* ahi sivun ohi
.4	;nop
	subq	#1,d0
	beq.b	.xx
.5

	lea	nAMISKA2,a0
	lea	rmpegaqua_req(pc),a2	* mpega quality
	bsr.b	.check
	lea	nAMISKA3,a0
	lea	rmpegadiv_req(pc),a2	* mpega freq div
	bsr.b	.check
	lea	nAMISKA4,a0
	lea	rmedmode_req(pc),a2	* med mode
	bsr.b	.check


.xx	popm	all
	bra.w	returnmsg2

.check	movem	4(a0),d0-d3
	subq	#1,d3
	add	d0,d2
	add	d1,d3
	cmp	d0,d6
	blo.b	.x
	cmp	d2,d6
	bhi.b	.x
	cmp	d1,d7
	blo.b	.x
	cmp	d3,d7
	bhi.b	.x
	pushm	a0/d6/d7
	jsr	(a2)
	popm	a0/d6/d7
.x	rts
	



* This updates the preds window to match state.
* p-functions handle each gadget.
pupdate:				* Ikkuna p‰ivitys
	pushm	all
	DPRINT	"prefs::pUpdate"

	move	prefsivu(a5),d0
	bne.b	.2

	bsr.w	pupdate2		* play
	bsr.w	ppri			* priority
	bsr.w	pdclick			* doubleclick
	bsr.w	pstartuponoff		* startup
	bsr.w	psup4			* timeoutslider
	bsr.w	phot			* hotkey
	bsr.w	perr			* cont on err
	bsr.w	pdiv			* divider dir
	bsr.w	pearly			* early load
	bsr.w	purealarm		* alarm slider
	bsr.w	pautosort		* auto sort
	bsr.w	pfavorites		* favorites
	bsr.w	psavestate		* savestate
	bra.w	.x

.2	subq	#1,d0
	bne.b	.3

	;bsr.w	psup3			* scope mode
	bsr.w	pbox			* box size
	;bsr.w	psup0			* scope on/off
	bsr.w	pinfosize		* info size
	bsr.w	pupdate1		* show
	bsr.w	pselscreen		* screen
	;bsr.w	pscopebar		* scope bars
	bsr.w	pprefx			* prefix cut
	bsr.w	pfont			* fontti
	bsr.w	pscreen			* screen refresh rates
	bsr.w	ptooltips  	     	* tooltips
	bsr.w	paltbuttons  	        * alt buttons
	bsr.w	pQuadraScope
	bsr.w	pQuadraScopeBars
	bsr.w	pQuadraScopeF
	bsr.w	pQuadraScopeFBars
	bsr.w	pHippoScope
	bsr.w	pHippoScopeBars
	bsr.w	pPatternScope
	bsr.w	pPatternScopeXL
	bsr.w	pSpectrumScope
	bsr.w	pSpectrumScopeBars
	bsr.w	pListFont
	bra.w	.x

.3	subq	#1,d0
	bne.b	.4

	bsr.w	pipm			* pt replayer
	bsr.w	pupf			* filter
	bsr.w	pupdate3		* pt tempo
	bsr.w	pvbt			* vblank timer
	bsr.w	pnasty			* nasty audio
	bsr.w	ppgfile			* pgfilename
	bsr.w	ppgmode			* pgmode
	bsr.w	ppgstat			* pgstatus
	bsr.w	pdbf			* volume fade
	bra.b	.x

.4	subq	#1,d0
	bne.b	.5

	bsr.w	pux			* xpk id
	bsr.w	pdbuf			* doublebuffering
	bsr.w	pdup			* mod/prg/arc dirrit
	bsr.w	pxfd			* xfdmaster
	bra.b	.x

.5	subq	#1,d0
	bne.b	.6

	bsr.w	pupdate5		* ps3m priority
	bsr.w	pupdate6		* ps3m playmode
	bsr.w	pupdate7		* ps3m volboost
	bsr.w	psup1			* ps3m mixingrate
	bsr.w	pps3mb			* ps3m buffer
	bsr.w	pupdate7b		* stereo
	bsr.w	psettings		* settings file
	bsr.w	pcyber			* cyber calibration
	bsr.w	pcybername		* cyber calibration file name
	bra.b	.x

.6	subq.b	#1,d0
	bne.b	.7
	
	bsr.w	pahi1			* ahi use
	bsr.w	pahi2			* ahi disable others
	bsr.w	pahi3			* ahi select mod
	bsr.w	pahi4			* ahi mixing rate
	bsr.w	pahi5			* ahi master volume
	bsr.w	pahi6			* ahi stereo level
	bra.b	.x


.7
	bsr.w	psup2			* tfmx mixingrate
	bsr.w	psup2b			* samplebufsize
	bsr.w	psup2c			* sampleforcerate
	bsr.w	pupmedrate		* med mixing rate
	bsr.w	psamplecyber		* sample cyber
	bsr.w	pmpegaqua		* MPEGA quality
	bsr.w	pmpegadiv		* MPEGA freq division
	bsr.w	pmedmode		* med mode


.x	popm	all
	rts




***** Tarkistetaan mahtuuko avattava ikkuna ruudulle
* a0 = ikkuna
tark_mahtu
	move	wbleveys(a5),d0		* WB:n leveys
	move	(a0),d1			* Ikkunan x-paikka
	add	4(a0),d1		* Ikkunan oikea laita
	cmp	d0,d1
	bls.b	.ok1
	sub	4(a0),d0	* Jos ei mahdu ruudulle, laitetaan
	move	d0,(a0)		* mahdollisimman oikealle
.ok1	move	wbkorkeus(a5),d0	* WB:n korkeus
	move	2(a0),d1		* Ikkunan y-paikka
	add	6(a0),d1		* Ikkunan oikea laita
	cmp	d0,d1
	bls.b	.ok2
	sub	6(a0),d0	* Jos ei mahdu ruudulle, laitetaan
	move	d0,2(a0)	* mahdollisimman alas
.ok2	rts




**************************
* Tulostaa teksti‰ gadgetin sis‰lle
* a0 = teksti
* a1 = gadgetti

prunt2:
	pushm	all
	moveq	#1,d7		* ei korvaa
	bra.b	pru0

prunt
	pushm	all
	moveq	#0,d7
pru0
	movem.l	a0/a1,-(Sp)			* putsaus
	movem	gg_LeftEdge(a1),d0/d1/d4/d5
	move.l	rastport2(a5),a0
	subq	#3,d4
	subq	#4,d5
	addq	#2,d0
	addq	#2,d1

	move.l	a0,a1
	move	d0,d2
	move	d1,d3
	moveq	#$0a,d6
	lore	GFX,ClipBlit
	popm	a0/a1

	* a1 = gadgetti
	* a0 = teksti
	move.l	a0,a2
.fe	tst.b	(a2)+
	bne.b	.fe
	sub.l	a0,a2
	move	a2,d0
	subq	#1,d0

	lsl	#2,d0
	move	gg_Width(a1),d2
	lsr	#1,d2
	sub	d0,d2

	movem	gg_LeftEdge(a1),d0/d1	* x,y
	add	d2,d0
	bsr.b	.pr

	tst	d7
	bne.b	.nok
	move.l	a1,a0
	bsr.w	printkorva2
.nok
	popm	all
	rts

.pr	pushm	all
	addq	#8,d1
	move.l	rastport2(a5),a4
	bra.w	doPrint


** Suoritetaan gadgettia vastaava toiminto
gadgetsup2
	movem.l	d0-a6,-(sp)
	move	gg_GadgetID(a2),d0

 if DEBUG
	ext.l	d0
	DPRINT	"Gadget id=%ld"
 endif

	add	d0,d0
	cmp	#20*2,d0
	bhs.b	.pag
	lea	.gadlist-2(pc,d0),a0
.x	add	(a0),a0
	jsr	(a0)
	movem.l	(sp)+,d0-a6
	bra.w	returnmsg2

.pag
;	sub	#10*2,d0
	lea	.s0-20*2(pc,d0),a0
	move	prefsivu(a5),d1
	beq.b	.x
	lea	.s1-20*2(pc,d0),a0
	subq	#1,d1
	beq.b	.x
	lea	.s2-20*2(pc,d0),a0
	subq	#1,d1
	beq.b	.x
	lea	.s3-20*2(pc,d0),a0
	subq	#1,d1
	beq.b	.x
	lea	.s4-20*2(pc,d0),a0
	subq	#1,d1
	beq.b	.x
	lea	.s5-20*2(pc,d0),a0
	subq	#1,d1
	beq.b	.x
	lea	.s6-20*2(pc,d0),a0
	bra.b	.x


.gadlist
*** P‰‰gadgetit
	dr	rpbutton14	* save
	dr	rpbutton6	* use
	dr	rpbutton7	* cancel
	dr	rval0		* sivu0
	dr	rval1		* sivu1
	dr	rval2		* sivu2
	dr	rval3		* sivu3
	dr	rval4		* sivu4
	dr	rval5		* sivu5
	dr	rval6		* sivu6

.s0
*** Sivu0
	dr	rpbutton2	* play		* pbutton1
	dr	rtimeoutmode	* timeoutmoodi
	dr	rtimeoutslider	* timeout
	dr	ralarm		* her‰tyskello
	dr	rstartup	* startup
	dr	rstartuponoff	* startup on/off
	dr	rfkeys		* fkeys
	dr	rpri		* prioriteetti
	dr	rhotkey		* hotkey
	dr	rdclick		* doubleclick
	dr	rerr		* continue on error
	dr	rearly		* early load
	dr	rdiv		* divider / dir
	dr	rautosort	* autosort
	dr	rfavorites	* favorites
	dr 	rsavestate	* save state

.s1
*** Sivu1
	dr	rpbutton1	* show		* pbutton2
	dr	rselscreen	* publicscreen
	dr	rbox		* boxsize
	dr	rfont		* font selector
	;dr	rquad		* scope on/off
	;dr	rquadm		* scopen moodi	* pout3
	;dr	rscopebar	* bar mode scopeille
	dr	rprefx		* prefix cut
	dr	rinfosize	* module info size
	dr  	rtooltips     * tooltips
	dr  	raltbuttons * alt buttons
	dr	rQuadraScope
	dr	rQuadraScopeBars
	dr	rQuadraScopeF
	dr	rQuadraScopeFBars
	dr	rHippoScope
	dr	rHippoScopeBars
	dr	rPatternScope
	dr	rPatternScopeXL
	dr	rSpectrumScope
	dr	rSpectrumScopeBars
	dr	rListFont

.s2
*** Sivu2
	dr	rpgfile		* pg file select
	dr	rpgmode		* pg mode
	dr	rpfilt		* filtteri
	dr	rdbf		* fadevolume
	dr	rnasty		* nasty audio
	dr	rvbtimer	* vblank timer
	dr	rptmix		* pt norm/fast/ps3m
	dr	rpbutton3	* pt tempo
;	dr	rpslider2	* tfmx rate
;	dr	rpslider2b	* samplebufsiz
;	dr	rpslider2c	* sampleforcerate

.s3
*** Sivu3
	dr	rpbutton10	* moduledir
	dr	rselprgdir	* prgdir
	dr	rselarcdir	* archive dir
	dr	rarch2		* archiver: lha
	dr	rarch4		* archiver: lzx
	dr	rarch3		* archiver: zip
	dr	rdbuf		* doublebuffering
	dr	rxp		* xpk id on/off
	dr	rxfd		* xfdmaster on/off
	dr	rpattern	* file pattern

.s4
*** Sivu4
	dr	rsmode2		* ps3m playmode
	dr	rsmode1		* ps3m priority
	dr	rps3mb		* ps3m mixbuffersize
	dr	rpslider1	* ps3m mixingrate
	dr	rsmode3		* ps3m volumeboost
	dr	rsmode4		* ps3m stereofactor
	dr	rsettings	* settings file on/off
	dr	rcyber		* cyber calibration
	dr	rcybername	* cyber calibration file name

*** Sivu5
.s5	dr	rahi3		* ahi select mode
	dr	rahi1		* ahi use
	dr	rahi2		* ahi disable others
	dr	rahi4		* ahi mixing rate
	dr	rahi5		* ahi master volume
	dr	rahi6		* ahi stereo level

*** Sivu6
.s6
	dr	rpslider2	* tfmx rate
	dr	rpslider2b	* samplebufsiz
	dr	rpslider2c	* sampleforcerate
	dr	rsamplecyber	* sample cybercalibration
	dr	rmpegaqua	* mpega quality
	dr	rmpegadiv	* mpeda freq division
	dr	rmedmode	* med mode
	dr	rmedrate	* med rate



rval0	moveq	#0,d0
	bra.w	prefsgads2
rval1	moveq	#1,d0
	bra.w	prefsgads2
rval2	moveq	#2,d0
	bra.w	prefsgads2
rval3	moveq	#3,d0
	bra.w	prefsgads2
rval4	moveq	#4,d0
	bra.w	prefsgads2
rval5	moveq	#5,d0
	bra.w	prefsgads2
rval6	moveq	#6,d0
	bra.w	prefsgads2


*** Scope

rQuadraScope:
	DPRINT	"rQuadrascope"
	not.b	prefsdata+prefs_quadraScope(a5)
	bne.b	.start
	bsr.w	stopQuadraScopeTask
	bra.b 	pQuadraScope
.start	
	bsr.w	startQuadraScopeTask
	
pQuadraScope:
	move.b	prefsdata+prefs_quadraScope(a5),d0
	lea	prefsQuadraScope,a0
	bra.w	tickaa

rQuadraScopeBars:
	DPRINT	"rQuadrascopeBars"
	not.b	prefsdata+prefs_quadraScopeBars(a5)
	bsr.w	restartQuadraScopeTask

pQuadraScopeBars
	move.b	prefsdata+prefs_quadraScopeBars(a5),d0
	lea	prefsQuadraScopeBars,a0
	bra.w	tickaa

rQuadraScopeF
	DPRINT	"rQuadraScopeF"
	not.b	prefsdata+prefs_quadraScopeF(a5)
	bne.b	.start
	bsr.w	stopQuadraScopeFTask
	bra.b	pQuadraScopeF
.start	
	bsr.w	startQuadraScopeFTask

pQuadraScopeF
	move.b	prefsdata+prefs_quadraScopeF(a5),d0
	lea	prefsQuadraScopeF,a0
	bra.w	tickaa

rQuadraScopeFBars
	DPRINT	"rQuadraScopeFBars"
	not.b	prefsdata+prefs_quadraScopeFBars(a5)
	bsr.w	restartQuadraScopeFTask
	
pQuadraScopeFBars
	move.b	prefsdata+prefs_quadraScopeFBars(a5),d0
	lea	prefsQuadraScopeFBars,a0
	bra.w	tickaa

rHippoScope
	DPRINT	"rHippoScope"
	not.b	prefsdata+prefs_hippoScope(a5)
	bne.b	.start
	bsr.w	stopHippoScopeTask
	bra.b pHippoScope
.start	
	bsr.w	startHippoScopeTask
	
pHippoScope
	move.b	prefsdata+prefs_hippoScope(a5),d0
	lea	prefsHippoScope,a0
	bra.w	tickaa


rHippoScopeBars
	DPRINT	"rHippoScopeBars"
	not.b	prefsdata+prefs_hippoScopeBars(a5)
	bsr.w	restartHippoScopeTask

pHippoScopeBars
	move.b	hippoScopeBars_new(a5),d0
	lea	prefsHippoScopeBars,a0
	bra.w	tickaa

rPatternScope
	DPRINT	"rPatternScope"
	not.b	prefsdata+prefs_patternScope(a5)
	bne.b	.start
	bsr.w	stopPatternScopeTask
	bra.b 	pPatternScope
.start	
	bsr.w	startPatternScopeTask

pPatternScope
	move.b	prefsdata+prefs_patternScope(a5),d0
	lea	prefsPatternScope,a0
	bra.w	tickaa

rPatternScopeXL
	DPRINT	"rPatternScopeXL"
	not.b	prefsdata+prefs_patternScopeXL(a5)
	bsr.w	restartPatternScopeTask

pPatternScopeXL
	move.b	prefsdata+prefs_patternScopeXL(a5),d0
	lea	prefsPatternScopeXL,a0
	bra.w	tickaa

rSpectrumScope
	DPRINT	"rSpectrumScope"
	not.b	prefsdata+prefs_spectrumScope(a5)
	bne.b	.start
	bsr.w	stopSpectrumScopeTask
	bra.b 	pSpectrumScope
.start	
	bsr.w	startSpectrumScopeTask
	
pSpectrumScope
	move.b	prefsdata+prefs_spectrumScope(a5),d0
	lea	prefsSpectrumScope,a0
	bra.w	tickaa

rSpectrumScopeBars
	DPRINT	"rSpectrumScopeBars"
	not.b	prefsdata+prefs_spectrumScopeBars(a5)
	bsr.w	restartSpectrumScopeTask

pSpectrumScopeBars
	move.b	prefsdata+prefs_spectrumScopeBars(a5),d0
	lea	prefsSpectrumScopeBars,a0
	bra.w	tickaa
	

** Mixingrate S3M
rpslider1
psup1
	lea	pslider1,a2
	move	#580-050,d0		* max
	bsr.w	nappilasku
	add	#50,d0
	mulu	#100,d0
	move.l	d0,mixingrate_new(a5)

	divu	#1000,d0
	swap	d0
	moveq	#0,d1
	move	d0,d1
	clr	d0
	swap	d0

	lea	info2_t(pC),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0
;	movem	pslider1+4,d0/d1
	movem	4(a2),d0/d1
	sub	#65,d0
	addq	#8,d1
	bra.w	print3b

info2_t dc.b	"%2.2ld.%1.1ldkHz",0
 even

***** PS3M buffer

rps3mb_req
	lea	.b(pc),a0
	bsr.w	listselector
	bmi.b	.x
	move.b	d0,ps3mb_new(a5)
	bra.b	pps3mb

.x	rts

.b	dc.b	4,4
	dc.b	"4kB",0
	dc.b	"8kB",0
	dc.b	"16kB",0
	dc.b	"32kB",0


rps3mb
	addq.b	#1,ps3mb_new(a5)
	cmp.b	#3,ps3mb_new(a5)
	bls.b	.ok
	clr.b	ps3mb_new(a5)
.ok

pps3mb
	move.b	ps3mb_new(a5),d1
	moveq	#4,d0
	lsl	d1,d0
	lea	.f(pC),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0
	lea	jommo,a1
	bra.w	prunt

.f	dc.b	"%ldkB",0
 even


** Mixingrate TFMX
rpslider2
psup2
	lea	pslider2,a2
	moveq	#22-1,d0		* max
	bsr.w	nappilasku
	addq	#1,d0
	move	d0,tfmxmixingrate_new(a5)
	
	lea	.info3_t(pC),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0
;	movem	pslider2+4,d0/d1
	movem	4(a2),d0/d1
	sub	#48,d0
	addq	#8,d1
	bra.w	print3b

.info3_t dc.b	"%2.2ldkHz",0
 even



** Samplebuffersize
rpslider2b
psup2b
	lea	sIPULI,a2
	moveq	#5,d0		* max
	bsr.w	nappilasku
	move.b	d0,samplebufsiz_new(a5)

	move	d0,d1
	moveq	#1,d0
	addq	#2,d1
	lsl	d1,d0

	lea	.t(pC),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0
;	movem	sIPULI+4,d0/d1
	movem	4(a2),d0/d1
	sub	#44,d0
	addq	#8,d1

	bra.w	print3b

.t 	dc.b	"%3.3ldkB",0
 even

********** force sample rate

rpslider2c
psup2c
	lea	sIPULI2,a2
	move	#600-9,d0		* max
	bsr.w	nappilasku
	move	d0,sampleforcerate_new(a5)
	bne.b	.m

	lea	.of(pc),a0
	bra.b	.p
.m
	add	#9,d0
	divu	#10,d0
	move.l	d0,d1
	clr	d1
	swap	d1
	ext.l	d0
	
	lea	.t(pC),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0
.p	
;	movem	sIPULI2+4,d0/d1
	movem	4(a2),d0/d1
	add	#149,d0
	subq	#6,d1

	bra.w	print3b

.of	dc.b	".....off",0
.t	dc.b	" %2.2ld.%1.1ldkHz",0
	even 



** Archivers: tempdir, lha jne..

rpattern
	move.l	DuU0+gg_SpecialInfo,a0
	lea	pattern_new(a5),a1
	bra.b	acopy

rarch2	move.l	ack2+gg_SpecialInfo,a0
	lea	arclha_new(a5),a1
	bra.b	acopy
rarch3	move.l	ack3+gg_SpecialInfo,a0
	lea	arczip_new(a5),a1
	bra.b	acopy
rarch4	move.l	ack4+gg_SpecialInfo,a0
	lea	arclzx_new(a5),a1

acopy	move.l	si_Buffer(a0),a0	* Teksipuskuri
.c	move.b	(a0)+,(a1)+
	bne.b	.c

;	jsr	flash

	rts

** Save
rpbutton14
	move.b	#2,prefs_exit(a5)
	rts
** Exit
rpbutton6
	move.b	#1,prefs_exit(a5)
	rts
** Cancel
rpbutton7
	st	prefs_exit(a5)
	rts




** Show; Mit‰ n‰ytet‰‰n otsikkopalkissa

rpbutton1_req
	lea	ls1(pc),a0
	bsr.w	listselector
	bmi.b	.x
	move	d0,lootamoodi_new(a5)
	bra.b	pupdate1

.x	rts

rpbutton1
	addq	#1,lootamoodi_new(a5)	* vaihetaan moodia
	cmp	#3,lootamoodi_new(a5)
	ble.b	.ook
	clr	lootamoodi_new(a5)
.ook
	
pupdate1
	lea	ls2(pc),a0
	move	lootamoodi_new(a5),d0
	beq.b	.n
	lea	ls3(pc),a0
	subq	#1,d0
	beq.b	.n
	lea	ls4(pc),a0
	subq	#1,d0
	beq.b	.n
	lea	ls44(pc),a0
.n	

	lea	pbutton2,a1
	bra.w	prunt

ls1	dc.b	22,4	* leveys/korkeus merkkein‰
ls2 	dc.b	"Time, pos/len, song",0
ls3 	dc.b	"Clock, free memory",0
ls4	dc.b	"Module name",0
ls44 	dc.b	"Time/duration, pos/len",0
 even




** Play; Soittotapa

rpbutton2_req
	lea	ls50(pc),a0
	bsr.w	listselector
	bmi.b	.x
	addq.b	#1,d0
	move.b	d0,playmode_new(a5)
	bra.b	pupdate2

.x	rts

rpbutton2
	addq.b	#1,playmode_new(a5)
	cmp.b	#pm_max,playmode_new(a5)
	ble.b	pupdate2
	move.b	#1,playmode_new(a5)
	
pupdate2
	move.b	playmode_new(a5),d0
	lea	ls5(pc),a0
	subq.b	#1,d0
	beq.b	.ee
	lea	ls6(pc),a0
	subq.b	#1,d0
	beq.b	.ee
	lea	ls7(pc),a0
	subq.b	#1,d0
	beq.b	.ee
	lea	ls8(pc),a0
	subq.b	#1,d0
	beq.b	.ee
	lea	ls9(pc),a0
.ee	
	lea	pbutton1,a1
	bra.w	prunt 

ls50	dc.b	23,5
ls5 dc.b	"List repeatedly",0
ls6 dc.b	"List once",0
ls7 dc.b	"Module repeatedly",0
ls8 dc.b	"Module once",0
ls9 dc.b	"Modules in random order",0
 even


** Tempomoodi
rpbutton3
	not.b	tempoflag_new(a5)

pupdate3
	tst.b	tempoflag_new(a5)
	seq	d0
	lea	pbutton3,a0
	bra.w	tickaa


** S3M moodit 1,2,3

rsmode1_req
	lea	ls51(pc),a0
	bsr.w	listselector
	bmi.b	.x
	move.b	d0,s3mmode1_new(a5)
	bra.b	pupdate5

.x	rts

rsmode1
	addq.b	#1,s3mmode1_new(a5)
	cmp.b	#5,s3mmode1_new(a5)
	bls.b	pupdate5
	clr.b	s3mmode1_new(a5)

pupdate5
	lea	ls52(pc),a0
	move.b	s3mmode1_new(a5),d0
	beq.b	.e
	lea	ls53(pc),a0
	subq.b	#1,d0
	beq.b	.e
	lea	ls531(pc),a0
	subq.b	#1,d0
	beq.b	.e
	lea	ls532(pc),a0
	subq.b	#1,d0
	beq.b	.e
	lea	ls533(pc),a0
	subq.b	#1,d0
	beq.b	.e
	lea	ls54(pc),a0
.e	
	lea	smode2,a1
	bra.w	prunt

* -10, -3, 0, +3, +10

ls51	dc.b	7,6
ls52	dc.b	"-10",0
ls53	dc.b	"-1",0
ls531	dc.b	"0",0
ls532	dc.b	"+1",0
ls533	dc.b	"+9",0
ls54	dc.b	"Killer",0		* 5
 even


rsmode2_req
	lea	ls10(pc),a0
	bsr.w	listselector
	bmi.b	.x
	addq.b	#1,d0
	move.b	d0,s3mmode2_new(a5)
	bra.b	pupdate6

.x	rts


rsmode2
	addq.b	#1,s3mmode2_new(a5)
	cmp.b	#5,s3mmode2_new(a5)
	ble.b	pupdate6
	move.b	#1,s3mmode2_new(a5)

pupdate6
	lea	ls11(pc),a0
	move.b	s3mmode2_new(a5),d0
	subq.b	#1,d0
	beq.b	.e
	lea	ls12(pc),a0
	subq.b	#1,d0
	beq.b	.e
	lea	ls13(pc),a0
	subq.b	#1,d0
	beq.b	.e
	lea	ls14(pc),a0
	subq.b	#1,d0
	beq.b	.e
	lea	ls15(pc),a0

.e	
	lea	smode1,a1
	bra.w	prunt


ls10	dc.b	13,5
ls11	dc.b	"Surround",0
ls12	dc.b	"Stereo",0
ls13	dc.b	"Mono",0
ls14	dc.b	"Real surround",0
ls15	dc.b	"14-bit stereo",0
 even

** Volboost

rsmode3
pupdate7
	lea	juusto,a2
	moveq	#16,d0			* max
	bsr.w	nappilasku
	move.b	d0,s3mmode3_new(a5)
	bsr.w	updateps3m

	moveq	#0,d0
	move.b	s3mmode3_new(a5),d0
	lea	.i(pC),a0
	bsr.w	desmsg2

	lea	desbuf2(a5),a0
;	movem	juusto+4,d0/d1
	movem	4(a2),d0/d1
	sub	#16+8,d0
	addq	#8,d1
	bra.w	print3b
.i	dc.b	"%2.2ld",0
 even

*** Stereo

rsmode4
pupdate7b
	lea	juust0,a2
	moveq	#64,d0			* max
	bsr.w	nappilasku
	move.b	d0,stereofactor_new(a5)

	bsr.b	updateps3m2

	mulu	#100,d0
	lsr.l	#6,d0		* x/64
	lea	.i(pC),a0
	bsr.w	desmsg2


;	movem	juust0+4,d0/d1
	movem	4(a2),d0/d1
	sub	#41+1,d0
	addq	#8,d1
	movem	d0/d1,-(sp)

	lea	.ii(pc),a0
	bsr.w	print3b

	lea	desbuf2(a5),a0
	movem	(sp)+,d0/d1


	bra.w	print3b
.i	dc.b	"%3.3ld%%",0
.ii	dc.b	"  ",0
 even

updateps3m2
	tst.b	ahi_use_nyt(a5)
	bne.b	.nd

	lea	var_b,a5
	tst.l	playingmodule(a5)
	bmi.b	.nd
	tst.b	playing(a5)
	beq.b	.nd
	cmp	#pt_multi,playertype(a5)
	bne.b	.nd
	cmp.b	#1,s3mmode2(a5)		* onko surround?
	bne.b	.nd
	moveq	#64,d1
	sub.b	stereofactor_new(a5),d1
	move	d1,$dff0c8
	move	d1,$dff0d8
.nd	rts

updateps3m
	tst.b	ahi_use_nyt(a5)
	bne.b	.nd

	tst.l	playingmodule(a5)
	bmi.b	.nd
	tst.b	playing(a5)
	beq.b	.nd
	cmp	#pt_multi,playertype(a5)
	bne.b	.nd
	pushm	all
	move.b	s3mmode3_new(a5),d0
	jsr	ps3m_boost
	popm	all
.nd
	rts


**** ps3m settings
rsettings
	not.b	ps3msettings_new(a5)
psettings
;	tst.b	ps3msettings_new(a5)
;	sne	d0
	move.b	ps3msettings_new(a5),d0
	lea	Fruit,a0
	bra.w	tickaa




***** cyber calibration nappu
rcyber
	not.b	cybercalibration_new(a5)
pcyber
;	tst.b	cybercalibration_new(a5)
;	sne	d0
	move.b	cybercalibration_new(a5),d0
	lea	bENDER1,a0
	bra.w	tickaa



***** cyber calibration file name
rcybername
	lea	calibrationfile_new(a5),a0
	move.l	a0,a1			* mihin hakemistoon menn‰‰n
	lea	.t(pc),a2
	bsr.w	pgetfile
	st	newcalibrationfile(a5)
	bra.b	pcybername

.t	dc.b	"Select calibration file",0
 even

pcybername
	lea	calibrationfile_new(a5),a0
	move.l	a0,a2
.f	tst.b	(a2)+
	bne.b	.f
	move.l	sp,a1
	lea	-30(sp),sp
	moveq	#20-1,d0
.c	move.b	-(a2),-(a1)
	cmp.l	a0,a2
	beq.b	.cx
	dbf	d0,.c
.cx	
	move.l	a1,a0
	lea	bENDER2,a1
	bsr.w	prunt2	
	lea	30(sp),sp
	rts






** Filtteri
rpfilt_req
	lea	ls16(pc),a0
	bsr.w	listselector
	bmi.b	.x
	move.b	d0,filterstatus(a5)
	bra.b	pupf

.x	rts

rpfilt
	addq.b	#1,filterstatus(a5)
	cmp.b	#2,filterstatus(a5)
	ble.b	pupf
	clr.b	filterstatus(a5)

pupf
	lea	ls17(pc),a0
	move.b	filterstatus(a5),d0
	bne.b	.prp

	bset	#1,$bfe001
	tst.b	modulefilterstate(a5)
	bne.b	.pr
	bclr	#1,$bfe001
	bra.b	.pr
.prp
	lea	ls18(pc),a0
	subq.b	#1,d0
	beq.b	.pr
	lea	ls19(pc),a0
.pr	
	lea	pout1,a1
	bra.w	prunt

ls16	dc.b	6,3
ls17	dc.b	"Module",0
ls18	dc.b	"Off",0
ls19	dc.b	"On",0
 even	

rptmix_req
	lea	ls20(pc),a0
	bsr.w	listselector
	bmi.b	.x
	move.b	d0,ptmix_new(a5)
	bra.b	pipm

.x	rts

rptmix
	addq.b	#1,ptmix_new(a5)
	cmp.b	#2,ptmix_new(a5)
	bls.b	pipm
	clr.b	ptmix_new(a5)
pipm
	lea	ls21(pc),a0
	move.b	ptmix_new(a5),d0
	beq.b	.n
	lea	ls22(pc),a0
	subq.b	#1,d0
	beq.b	.n
	lea	ls23(pc),a0
.n	
	lea	laren1,a1
	bra.w	prunt

ls20	dc.b	7,3
ls21	dc.b	"Normal",0
ls22	dc.b	"Fastram",0
ls23	dc.b	"PS3M",0
 even 

** XPKID
rxp	not.b	xpkid_new(a5)

pux	
	tst.b	xpkid_new(a5)
	seq	d0
	lea	makkara,a0
	bra.w	tickaa

	
**** XFDmaster
rxfd	not.b	xfd_new(a5)
pxfd	;tst.b	xfd_new(a5)
	;sne	d0
	move.b	xfd_new(a5),d0
	lea	nappU2,a0
	bra.w	tickaa


*** volumefade
rdbf	not.b	fade_new(a5)

pdbf	;tst.b	fade_new(a5)
	;sne	d0
	move.b	fade_new(a5),d0
	lea	kinkku,a0
	bra.w	tickaa


**** Prioriteetti
rpri_req
	lea	ls200(pc),a0
	bsr.w	listselector
	bmi.b	.x
	subq.b	#1,d0
	move.b	d0,pri_new(a5)
	bra.b	ppri

.x	rts

rpri
	move.b	pri_new(a5),d0
	addq.b	#2,d0
	cmp.b	#2,d0
	bls.b	.r
	moveq	#0,d0
.r	subq.b	#1,d0
	move.b	d0,pri_new(a5)

ppri
	lea	ls201(pc),a0
	move.b	pri_new(a5),d0
	bmi.b	.0	
	lea	ls202(pc),a0
	beq.b	.0
	lea	ls203(pc),a0

.0	lea	tomaatti,a1
	bra.w	prunt

ls200	dc.b	2,3
ls201	dc.b	"-1",0
ls202	dc.b	"0",0
ls203	dc.b	"+1",0
 even

** Valitaan hakemisto moddir
rpbutton10
	bsr.w	dir_req
	bne.b	.ee
	rts
.ee	
	move.l	d7,a0
	lea	moduledir_new(a5),a1
	bsr.w	parsereqdir2		* Tehd‰‰n hakemistopolku..
	st	newdirectory(a5)

psele	move.l	d7,a1
	lob	rtFreeRequest

* 19 max

pdup
	lea	moduledir_new(a5),a0
	basereg	DuU1,a1
	lea	DuU1,a1
	bsr.b	.o
	lea	prgdir_new(a5),a0
	lea	DuU2(a1),a1
	bsr.b	.o
	lea	arcdir_new(a5),a0		* DISABLED!
	lea	DuU3(a1),a1
	endb	a1
	bsr.b	.o
	rts

.o	lea	-32(sp),sp
	lea	30(sp),a2
	clr.b	(a2)

	move.l	a0,a3
.u	tst.b	(a0)+
	bne.b	.u

	cmp.b	#'/',-2(a0)
	bne.b	.cy
	subq	#2,a0
.cy


	moveq	#19-1,d0
.c	cmp.l	a3,a0
	beq.b	.cc
	move.b	-(a0),-(a2)
	dbf	d0,.c
.cc	
	move.l	a2,a0
	bsr.w	prunt2
	lea	32(sp),sp
	rts


** Valitaan hakemisto prgdir
rselprgdir
	bsr.b	dir_req
	bne.b	.ee
	rts
.ee	
	move.l	d7,a0
	lea	prgdir_new(a5),a1
	bsr.w	parsereqdir2		* Tehd‰‰n hakemistopolku..
	st	newdirectory2(a5)
	bra.b	psele

** Valitaan hakemisto prgdir
rselarcdir
	bsr.b	dir_req
	bne.b	.ee
	rts
.ee	
	move.l	d7,a0
	lea	arcdir_new(a5),a1
	bsr.w	parsereqdir2		* Tehd‰‰n hakemistopolku..
	bra.w	psele



** Hakemisto requesteri
dir_req	bsr.w	get_rt
	moveq	#RT_FILEREQ,D0
	sub.l	a0,a0
	lob	rtAllocRequestA
	move.l	d0,d7
	beq.b	.eek
	bsr.w	pon2		* waitpointer

	lea	.dirtags(pc),a0
	move.l	d7,a1
	lea	desbuf2(a5),a2		* Kunhan jonnekkin laitetaan..
	lea	.dirreqtitle(pc),a3
	lob	rtFileRequestA		* ReqToolsin tiedostovalikko
	bsr.w	poff2
	tst.l	d0
.eek	rts

.dirreqtitle dc.b "Select directory",0
 even


.dirtags
	dc.l	RTFI_Flags,FREQF_NOFILES
;	dc.l	RT_TextAttr,text_attr
otag4	dc.l	RT_PubScrName,pubscreen+var_b
	dc.l	TAG_END





*** Box size

rbox
pbox
	lea	meloni,a2
	moveq	#51-3,d0		* max
	bsr.w	nappilasku
	beq.b	.fe
	addq	#2,d0

.fe	move	d0,boxsize_new(a5)

	lea	.i(pC),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0

;	movem	meloni+4,d0/d1
	movem	4(a2),d0/d1
	sub	#26,d0
	addq	#8,d1

	bra.w	print3b

.i dc.b	"%-2.2ld",0
 even

rinfosize
pinfosize
	lea	eskimO,a2
	moveq	#50-3,d0		* max
	bsr.w	nappilasku
	addq.l	#3,d0
	move	d0,infosize_new(a5)

	lea	.i(pC),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0

;	movem	eskimO+4,d0/d1
	movem	4(a2),d0/d1
	sub	#26,d0
	addq	#8,d1

	bra.w	print3b

.i dc.b	"%-2.2ld",0
 even


********* Doubleclick
rdclick
	not.b	dclick_new(a5)
pdclick
	;tst.b	dclick_new(a5)
	;sne	d0
	move.b	dclick_new(a5),d0
	lea	eins2,a0
	bra.w	tickaa

********* Favorite
rfavorites
	not.b	favorites_new(a5)
pfavorites
	move.b	favorites_new(a5),d0
	lea	prefsFavorites,a0
	bra.w	tickaa

********* Tooltips
rtooltips
	not.b	tooltips_new(a5)
ptooltips
	move.b	tooltips_new(a5),d0
	lea	prefsTooltips,a0
	bra.w	tickaa

********* Save state
rsavestate
	not.b	savestate_new(a5)
psavestate
	move.b	savestate_new(a5),d0
	lea	prefsSaveState,a0
	bra.w	tickaa

********* Alt buttons
raltbuttons
	not.b	altbuttons_new(a5)

paltbuttons
	move.b	altbuttons_new(a5),d0
	lea	prefsAltButtons,a0
	bra.w	tickaa


********* Autosort
rautosort
	not.b	autosort_new(a5)
pautosort
	;tst.b	autosort_new(a5)
	;sne	d0
	move.b	autosort_new(a5),d0
	lea	bUu22,a0
	bra.w	tickaa



********* Startup on/off
rstartuponoff
	not.b	startuponoff_new(a5)
pstartuponoff
	;tst.b	startuponoff_new(a5)
	;sne	d0
	move.b	startuponoff_new(a5),d0
	lea	salaatti3,a0
	bra.w	tickaa


********* Startup
* a0 = paikka nimelle (jossa vanha nimi)

rstartup
	lea	startup_new(a5),a0
	move.l	a0,a1			* mihin hakemistoon menn‰‰n
	sub.l	a2,a2

pgetfile
	move.l	a2,d4		 * title
	bsr.w	get_rt
	move.l	a0,d6
	move.l	a1,d5
	moveq	#RT_FILEREQ,D0
	sub.l	a0,a0
	lob	rtAllocRequestA
	move.l	d0,req_file3(a5)
	bne.b	.joo
	rts
.joo
	move.l	d5,a0
.f0	tst.b	(a0)+
	bne.b	.f0
	move.l	d5,a1
	bsr.w	nimenalku

	move.l	a0,a2
	lea	desbuf2(a5),a3		* nimi
.c	move.b	(a0)+,(a3)+
	bne.b	.c

	move.b	(a2),d7
	clr.b	(a2)

	move.l	req_file3(a5),a1		* Vaihdetaan hakemistoa...
	lea	newdir_tags(pc),a0
	move.l	d5,4(a0)
	lore	Req,rtChangeReqAttrA

	move.l	req_file3(a5),a1		* Match pattern
	lea	matchp_tags(pc),a0
	lob	rtChangeReqAttrA
	move.b	d7,(a2)


	lea	.tags(pc),a0
	move.l	req_file3(a5),a1
	lea	desbuf2(a5),a2
	lea	.title(pc),a3
	tst.l	d4
	beq.b	.noti
	move.l	d4,a3
.noti

	bsr.w	pon2		* waitpointer

	lore	Req,rtFileRequestA	* ReqToolsin tiedostovalikko
	bsr.w	poff2
	tst.l	d0
	beq.b	.eek


	move.l	req_file3(a5),a0
	move.l	d6,a1
	bsr.w	parsereqdir2

	addq	#1,a1
	lea	desbuf2(a5),a0
.e	move.b	(a0)+,(a1)+
	bne.b	.e

.eek	
	move.l	req_file3(a5),d0
	beq.b	.eek2
	move.l	d0,a1
	lore	Req,rtFreeRequest
.eek2
	rts


.title dc.b "Select module or program",0
 even

.tags
	dc.l	RTFI_Flags,FREQF_PATGAD
otag14	dc.l	RT_PubScrName,pubscreen+var_b,TAG_END

********* Alarm
ralarm
	rts

purealarm
	lea	kelloke2,a2
	move.l	gg_SpecialInfo(a2),a0
	move	pi_HorizPot(a0),d0
	move	#1440,d0		* max
	bsr.w	nappilasku

	divu	#60,d0
	moveq	#0,d1
	move.b	d0,d1
	lsl	#8,d1
	swap	d0
	move.b	d0,d1

	move	d1,alarm_new(a5)
	ext.l	d1
	beq.b	.nl

	moveq	#0,d0
	move	d1,d0
	lsr	#8,d0
	and	#$ff,d1

	lea	.t(pC),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0
.r
;	movem	kelloke2+4,d0/d1
	movem	4(a2),d0/d1
	sub	#68,d0
	addq	#8,d1


	bra.b	print3b

.nl
	lea	.nil(pc),a0
	bra.b	.r

.nil	dc.b	".....Off",0
.t	dc.b	"...%02ld:%02ld",0
 even


print3b:
	pushm	all			* Sit‰varten ett‰ windowtop/left
	move.l	rastport2(a5),a4	* arvoja ei lis‰tt‰isi kun
	bra.w	doPrint			* teksti on jo suhteessa gadgettiin


******* FKeys
rfkeys
	lea	-60(sp),sp
	move.l	sp,a4

	lea	fkeys_new(a5),a0
	moveq	#10-1,d0
.lop	move.l	a0,(a4)+
	lea	120(a0),a0
	dbf	d0,.lop
	clr.l	(a4)

	lea	.form(pc),a1
	lea	(sp),a4
	lea	.gad(pc),a2
	lea	.tags(pc),a0
	sub.l	a3,a3
	bsr.w	get_rt
	bsr.w	pon2
	lob	rtEZRequestA
	bsr.w	poff2
	tst.l	d0
	bne.b	.e
	moveq	#11,d0
.e	subq	#1,d0
	lea	60(sp),sp
	tst.b	d0
	beq.b	.x
	subq	#1,d0		* 0-9

	lea	fkeys_new(a5),a0
	mulu	#120,d0
	add.l	d0,a0
	move.l	a0,a1		* jos ei ole ennest‰‰n tiedostoa,
	tst.b	(a1)		* otetaan hakemistoksi oletusmusahakemisto
	bne.b	.jep
	lea	moduledir(a5),a1	
.jep
	sub.l	a2,a2
	bsr.w	pgetfile
	bra.b	rfkeys

.x	rts


.gad	dc.b	"_OK|F_1|F_2|F_3|F_4|F_5|F_6|F_7|F_8|F_9|F1_0",0
.title	dc.b	"Function keys",0

.form
	dc.b	"F1:  %-60.60s",10
	dc.b	"F2:  %-60.60s",10
	dc.b	"F3:  %-60.60s",10
	dc.b	"F4:  %-60.60s",10
	dc.b	"F5:  %-60.60s",10
	dc.b	"F6:  %-60.60s",10
	dc.b	"F7:  %-60.60s",10
	dc.b	"F8:  %-60.60s",10
	dc.b	"F9:  %-60.60s",10
	dc.b	"F10: %-60.60s",0

 even

.tags	dc.l	RTEZ_ReqTitle,.title
	dc.l	RT_Underscore,"_"
	dc.l	RT_TextAttr,text_attr
otag5	dc.l	RT_PubScrName,pubscreen+var_b
	dc.l	TAG_END

*********** Timeout

rtimeoutslider
psup4
	lea	kelloke,a2
	move	#1800,d0		* max
	bsr.w	nappilasku
	move	d0,timeout_new(a5)
	beq.b	.nl

	divu	#60,d0
	move.l	d0,d1
	swap	d1
	ext.l	d1
	ext.l	d0

	lea	.t(pC),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0
.r	
;	movem	kelloke+4,d0/d1
	movem	4(a2),d0/d1
	sub	#52,d0
	addq	#8,d1


	bra.w	print3b

.nl
	lea	.nil(pc),a0
	bra.b	.r

.nil	dc.b	"...Off",0
.t	dc.b	" %02ld:%02ld",0
 even


******* timeoutmode
rtimeoutmode
	lea	.gad(pc),a2
	lea	.form(pc),a1
	pea	.1(pc)
	tst.b	timeoutmode_new(a5)
	beq.b	.o
	addq	#4,sp
	pea	.2(pc)
.o	lea	(sp),a4
	bsr.b	pselector2
	seq	timeoutmode_new(a5)
	addq	#4,sp
	rts
.form	dc.b	"Timeout affects %s modules.",0
.gad	dc.b	"_All modules|_Never ending modules",0
.1	dc.b	"all",0
.2	dc.b	"never-ending",0
 even





* Reqtools-valikko
pselector
	sub.l	a4,a4
pselector2
	bsr.w	get_rt
	lea	.tags(pc),a0
	sub.l	a3,a3
	bsr.w	pon2
	lob	rtEZRequestA
	bsr.w	poff2
	tst.l	d0
	rts


.tags	
	dc.l	RTEZ_ReqTitle,reqtitle
	dc.l	RT_Underscore,"_"
	dc.l	RT_TextAttr,text_attr
otag3	dc.l	RT_PubScrName,pubscreen+var_b
	dc.l	TAG_END

pgad5	dc.b	"_1|_2|_3|_4|_5",0
 even


******* Hotkey
rhotkey
	not.b	hotkey_new(a5)
phot
	;tst.b	hotkey_new(a5)
	;sne	d0
	move.b	hotkey_new(a5),d0
	lea	kaktus,a0
	bra.w	tickaa

**** Cont on error
rerr
	not.b	cerr_new(a5)
perr
	;tst.b	cerr_new(a5)
	;sne	d0
	move.b	cerr_new(a5),d0
	lea	luuta,a0
	bra.w	tickaa




**** Select screen

rselscreen
	tst.b	uusikick(a5)
	bne.b	.n
	rts

.n	st	newpubscreen2(a5)
	
	bsr.b	freepubwork

.l	move.l	pubwork(a5),a0
	lea	pubscreen_new(a5),a1
	lore	Intui,NextPubScreen
	tst.l	d0
	bne.b	.fe
	clr.l	pubwork(a5)
	bra.b	.l
.fe
	bsr.b	pselscreen

	lea	pubscreen_new(a5),a0
	lob	LockPubScreen
	move.l	d0,pubwork(a5)
	beq.b	.l
	rts

freepubwork
	move.l	pubwork(a5),d0
	beq.b	.eb
	move.l	d0,a1
	sub.l	a0,a0
	lore	Intui,UnlockPubScreen
.eb	rts
	
pselscreen
	tst.b	uusikick(a5)
	bne.b	.new
	lea	pubscreen_new(a5),a0
	bra.b	.rpo

.new

	lea	pubscreen_new(a5),a2
	lea	desbuf2(a5),a1
	move.l	a1,a0
	moveq	#18-1,d0
.c	move.b	(a2)+,(a1)+
	dbeq	d0,.c
	clr.b	(a1)

.rpo	lea	pbutton13,a1
	bra.w	prunt2
	


**** doublebuffering
rdbuf
	not.b	dbf_new(a5)
pdbuf
	;tst.b	dbf_new(a5)
	;sne	d0
	move.b	dbf_new(a5),d0
	lea	nappu1,a0
	bra.w	tickaa

**** nasty audio
rnasty
	not.b	nasty_new(a5)
pnasty
	;tst.b	nasty_new(a5)
	;sne	d0
	move.b	nasty_new(a5),d0
	lea	nappu2,a0
	bra.w	tickaa


rvbtimer
	not.b	vbtimer_new(a5)
pvbt
	;tst.b	vbtimer_new(a5)
	;sne	d0
	move.b	vbtimer_new(a5),d0
	lea	nApPu,a0	
	bra.w	tickaa


****** FontSelector



pfont
	lea	prefs_fontname+prefsdata(a5),a0
	lea	gfonttou,a1

showFontNameInGadget
	lea	-20(sp),sp
	move.l	sp,a2
	moveq	#10-1,d0
.c	cmp.b	#'.',(a0)
	beq.b	.cc
	move.b	(a0)+,(a2)+
	dbeq	d0,.c
.cc	clr.b	(a2)
	move.l	sp,a0
	bsr.w	prunt2
	lea	20(sp),sp
	rts

rfont
	DPRINT	"rfont"
	tst.l	_DiskFontBase(a5)
	bne.b	.y
	rts
.y
	moveq	#RT_FONTREQ,d0
	lore	Req,rtAllocRequestA
	move.l	d0,d7

	lea	.tit(pc),a3
	lea	fontreqtags(pc),a0

	; Remove pubscreen for old kickstart to prevent crash
	tst.b	uusikick(a5)
	bne.b	.new
	basereg	fontreqtags,a0
	clr.l	fontreqtags\.pubScreenTag(a0)
	endb	a0
.new

	move.l	d7,a1
	bsr.w	pon2
	lob	rtFontRequestA
	bsr.w	poff2
	tst.l	d0
	beq.b	.ew

	move.l	d7,a0
	lea	rtfo_Attr(a0),a0	* fontin textattr
	* Open font from TextAttr in A0
	lore	DiskFont,OpenDiskFont	
	tst.l	d0
	beq.b	.ew
	move.l	d0,a3
	
	cmp	#8,tf_XSize(a3)
	sne	d3
	cmp	#8,tf_YSize(a3)
	sne 	d4
	btst	#FPB_PROPORTIONAL,tf_Flags(a3) 
	sne 	d5

	move.l	a3,a1
	lore	GFX,CloseFont
	move.l	a3,a1
	lob	RemFont		* puis muistista

	or.b	d3,d4 
	or.b	d4,d5
	bne.b	.ew

	move.l	d7,a0
	lea	rtfo_Attr(a0),a0
	move.l	4(a0),prefs_textattr+prefsdata(a5) * YSize, Style, Flags talteen
	move.l	(a0),a0				* Fontin nimi
	lea	prefs_fontname+prefsdata(a5),a1
	printt "TOOD: DANGER: the output buffer is just 20 chars long"
	
.cec	move.b	(a0)+,(a1)+
	bne.b	.cec

	clr	boxsize00(a5)		* avataan ja suljetaan p‰‰ikkuna


.ew
	move.l	d7,a1
	lore	Req,rtFreeRequest
	bra.w	pfont


.tit	dc.b	"Select main font",0
 even

fontreqtags
	dc.l	RTFO_Flags,FREQF_NOBUFFER!FREQF_FIXEDWIDTH
	dc.l	RTFO_SampleHeight,12
	dc.l	RTFO_MaxHeight,8
	dc.l	RTFO_MinHeight,8
	dc.l	RTFO_FilterFunc,.fontfilter
	dc.l	RT_TextAttr,text_attr
.pubScreenTag
	dc.l	RT_PubScrName,pubscreen+var_b
	dc.l	TAG_END

.fontfilter
	ds.b	MLN_SIZE
	dc.l	.hookroutine	* h_Entry
	dc.l	0		* h_SubEntry
	dc.l	0		* h_Data

.hookroutine
* a1 = textattr
	pushm	d1-a6		
	lea	var_b,a5
	moveq	#FALSE,d7
	cmp	#8,ta_YSize(a1)		* 8 pixeli‰ korkee?
	bne.b	.x
	btst	#FPB_PROPORTIONAL,ta_Flags(a1)	* Onko proportional?
	bne.b	.x	

	move.l	a1,a0			* tutkitaan onko leveys 8 pixeli‰
	lore	DiskFont,OpenDiskFont
	tst.l	d0
	beq.b	.x
	move.l	d0,a3
	cmp	#8,tf_XSize(a3)
	bne.b	.no
	moveq	#TRUE,d7
.no	move.l	a3,a1
	lore	GFX,CloseFont
	move.l	a3,a1
	lob	RemFont		* puis muistista
.x	move.l	d7,d0
	popm	d1-a6
	rts


rListFont
	DPRINT	"rListFont"
	tst.l	_DiskFontBase(a5)
	bne.b	.y
	rts
.y
	moveq	#RT_FONTREQ,d0
	lore	Req,rtAllocRequestA
	move.l	d0,d7

	lea	.tit(pc),a3
	lea	listfontreqtags(pc),a0

	; Remove pubscreen for old kickstart to prevent crash
	tst.b	uusikick(a5)
	bne.b	.new
	basereg	listfontreqtags,a0
	clr.l	listfontreqtags\.pubScreenTag(a0)
	endb	a0
.new
	move.l	d7,a1
	bsr.w	pon2
	lob	rtFontRequestA
	bsr.w	poff2
	tst.l	d0
	beq.b	.ew

	move.l	d7,a0
	lea	rtfo_Attr(a0),a0
	move.l	4(a0),prefs_listtextattr+prefsdata(a5) * YSize, Style, Flags talteen
	move.l	(a0),a0				* Fontin nimi
	lea	prefs_listfontname+prefsdata(a5),a1
.cec	move.b	(a0)+,(a1)+
	bne.b	.cec

	clr	boxsize00(a5)		* avataan ja suljetaan p‰‰ikkuna

.ew
	move.l	d7,a1
	lore	Req,rtFreeRequest
	bra.b	pListFont


.tit	dc.b	"Select list font",0
 even

listfontreqtags
	dc.l	RTFO_Flags,FREQF_NOBUFFER
	dc.l	RTFO_SampleHeight,8
	dc.l	RTFO_MaxHeight,30
	dc.l	RTFO_MinHeight,6
	dc.l	RT_TextAttr,text_attr
.pubScreenTag
	dc.l	RT_PubScrName,pubscreen+var_b
	dc.l	TAG_END

pListFont
	DPRINT	"pListFont"
	lea	prefs_listfontname+prefsdata(a5),a0
	lea	prefsListFont,a1
	bra.w	showFontNameInGadget


*** Printataan screen refresh ratetkin

pscreen
	tst.b	gfxcard(a5)
	beq.b	.nop
	lea	.dea(pc),a0
	bra.b	.do

.nop
	moveq	#0,d0
	move	vertfreq(a5),d0

	moveq	#0,d1
	move	horizfreq(a5),d1
	divu	#1000,d1
	ext.l	d1

	lea	.de(pc),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0

.do	moveq	#16,d0
	move	#122+18,d1
	add	windowtop(a5),d1
	bra.w	print3b


.de
	dc.b	"Screen: %ldHz/%ldkHz",0
.dea	dc.b	"A gfx card detected.",0
 even


***** Playergroup file

rpgfile
	lea	groupname_new(a5),a0
	move.l	a0,a1			* mihin hakemistoon menn‰‰n
	lea	.tit(pc),a2
	bsr.w	pgetfile
	bra.b	ppgfile

.tit	dc.b	"Select player group file",0
 even

ppgfile
	lea	groupname_new(a5),a0
	move.l	a0,a2
.f	tst.b	(a2)+
	bne.b	.f
	move.l	sp,a1
	lea	-30(sp),sp
	moveq	#23-1,d0
.c	move.b	-(a2),-(a1)
	cmp.l	a0,a2
	beq.b	.cx
	dbf	d0,.c
.cx	
	move.l	a1,a0
	lea	RoU1,a1
	bsr.w	prunt2	
	lea	30(sp),sp
	rts


******** Playergroup mode

rpgmode_req
	lea	ls300(pc),a0
	bsr.w	listselector
	bmi.b	.x
	move.b	d0,groupmode_new(a5)
	bra.b	ppgmode
.x	rts


rpgmode
	move.b	groupmode_new(a5),d0
	addq.b	#1,d0
	cmp.b	#3,d0
	bls.b	.r
	moveq	#0,d0
.r	move.b	d0,groupmode_new(a5)

ppgmode
	lea	ls301(pc),a0
	move.b	groupmode_new(a5),d0
	beq.b	.0
	lea	ls302(pc),a0
	subq.b	#1,d0
	beq.b	.0
	lea	ls303(pc),a0
	subq.b	#1,d0
	beq.b	.0
	lea	ls304(pc),a0
	
.0	lea	PoU2,a1
	bra.w	prunt

ls300	dc.b	14,4
ls301	dc.b	"All on startup",0
ls302	dc.b	"All on demand",0
ls303	dc.b	"Disable",0
ls304	dc.b	"Load single",0
 even


ppgstat
	lea	.2(pc),a0
	tst.l	externalplayers(a5)
	beq.b	.q
	lea	.1(pc),a0
.q

	movem	PoU2+4,d0/d1
	add	#40,d0
	subq	#6,d1
	bra.w	print3b

.2	dc.b	"not loaded",0
.1 	dc.b	"....loaded",0
 even

*********** Divider / dir

rdiv
	not.b	div_new(a5)
pdiv
	;tst.b	div_new(a5)
	;sne	d0
	move.b	div_new(a5),d0
	lea	bUu1,a0
	bra.w	tickaa


**** Prefix cut
rprefx_req
	lea	ls299(pc),a0
	bsr.w	listselector
	bmi.b	.x
	move.b	d0,prefix_new(a5)
	cmp.b	#7,d0
	blo.b	pprefx
	move.b	#6,prefix_new(a5)
	bra.b	pprefx
.x	rts

rprefx
	move.b	prefix_new(a5),d0
	addq.b	#1,d0
	cmp.b	#6,d0
	bls.b	.r
	moveq	#0,d0
.r	move.b	d0,prefix_new(a5)

pprefx
	moveq	#0,d0
	move.b	prefix_new(a5),d0
	add	d0,d0
	lea	ls299+2(pc,d0),a0
	lea	bUu2,a1
	bra.w	prunt

ls299	dc.b	1,7
	dc.b	"0",0
	dc.b	"1",0
	dc.b	"2",0
	dc.b	"3",0
	dc.b	"4",0
	dc.b	"5",0
	dc.b	"6",0
 even

**** Early load
* DISABLED!
rearly
pearly	rts
;rearly_req
;	lea	ls400(pc),a0
;	bsr.w	listselector
;	bmi.b	.x
;	move.b	d0,early_new(a5)
;	cmp.b	#11,d0
;	blo.b	pearly
;	move.b	#10,early_new(a5)
;	bra.b	pearly
;.x	rts
;
;rearly
;	move.b	early_new(a5),d0
;	addq.b	#1,d0
;	cmp.b	#10,d0
;	bls.b	.r
;	clr.b	d0
;.r	move.b	d0,early_new(a5)
;pearly
;	moveq	#0,d0
;	move.b	early_new(a5),d0
;	add	d0,d0
;	lea	ls400+2(pc,d0),a0
;	lea	bUu3,a1
;	bra.w	prunt
;
;
;
;
;ls400	dc.b	2,11
;	dc.b	"0",0
;	dc.b	"1",0
;	dc.b	"2",0
;	dc.b	"3",0
;	dc.b	"4",0
;	dc.b	"5",0
;	dc.b	"6",0
;	dc.b	"7",0
;	dc.b	"8",0
;	dc.b	"9",0
;	dc.b	"10",0
; even
;


;samplecyber	rs.b	1
;mpegaqua	rs.b	1
;mpegadiv	rs.b	1
;medmode		rs.b	1
;medrate		rs	1

;samplecyber_new	rs.b	1
;mpegaqua_new	rs.b	1
;mpegadiv_new	rs.b	1
;medmode_new	rs.b	1
;medrate_new	rs	1



*** Sample cybercalibration

rsamplecyber
	not.b	samplecyber_new(a5)
psamplecyber
	move.b	samplecyber_new(a5),d0
	lea	nAMISKA1,a0
	bra.w	tickaa


** MPEGA quality

rmpegaqua_req
	lea	ls500(pc),a0
	bsr.w	listselector
	bmi.b	.x
	move.b	d0,mpegaqua_new(a5)
	bra.b	pmpegaqua
.x	rts
rmpegaqua
	addq.b	#1,mpegaqua_new(a5)
	cmp.b	#3,mpegaqua_new(a5)
	bne.b	pmpegaqua
	clr.b	mpegaqua_new(a5)
pmpegaqua
	moveq	#0,d0
	move.b	mpegaqua_new(a5),d0
	lsl	#2,d0
	lea	ls501(pc,d0),a0
	lea	nAMISKA2,a1
	bra.w	prunt
ls500	dc.b	4,3
ls501	dc.b	"Low",0
ls502	dc.b	"Med",0
ls503	dc.b	"Hi ",0
 even

** MPEGA quality

rmpegadiv_req
	lea	ls600(pc),a0
	bsr.w	listselector
	bmi.b	.x
	move.b	d0,mpegadiv_new(a5)
	bra.b	pmpegadiv
.x	rts
rmpegadiv
	addq.b	#1,mpegadiv_new(a5)
	cmp.b	#3,mpegadiv_new(a5)
	bne.b	pmpegadiv
	clr.b	mpegadiv_new(a5)
pmpegadiv
	moveq	#0,d0
	move.b	mpegadiv_new(a5),d0
	add	d0,d0
	lea	ls601(pc,d0),a0
	lea	nAMISKA3,a1
	bra.w	prunt
ls600	dc.b	2,3
ls601	dc.b	"1",0
ls602	dc.b	"2",0
ls603	dc.b	"4",0
 even



** MED mode

rmedmode_req
	lea	ls700(pc),a0
	bsr.w	listselector
	bmi.b	.x
	move.b	d0,medmode_new(a5)
	bra.b	pmedmode
.x	rts
rmedmode
	addq.b	#1,medmode_new(a5)
	cmp.b	#2,medmode_new(a5)
	bne.b	pmedmode
	clr.b	medmode_new(a5)
pmedmode
	moveq	#0,d0
	move.b	medmode_new(a5),d0
	add	d0,d0
	lea	ls701(pc,d0),a0
	lea	nAMISKA4,a1
	bra.w	prunt
ls700	dc.b	2,2
ls701	dc.b	"8",0
ls702	dc.b	"14",0
 even




pupmedrate	
rmedrate
	lea	nAMISKA5,a2
	move	#580-050,d0		* max
	bsr.w	nappilasku
	add	#50,d0
	mulu	#100,d0
	move	d0,medrate_new(a5)

	divu	#1000,d0
	swap	d0
	moveq	#0,d1
	move	d0,d1
	clr	d0
	swap	d0

	lea	info2_t(pC),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0
	movem	4(a2),d0/d1
	add	#118,d0
	subq	#6,d1
	bra.w	print3b




***************************************
* AHI valinnat

*** use ahi
rahi1	not.b	ahi_use_new(a5)
pahi1	;tst.b	ahi_use_new(a5)
	;sne	d0
	move.b	ahi_use_new(a5),d0
	lea	ahiG2,a0
	bra.w	tickaa


*** ahi disable muut
rahi2	not.b	ahi_muutpois_new(a5)
pahi2	;tst.b	ahi_muutpois_new(a5)
	;sne	d0
	move.b	ahi_muutpois_new(a5),d0
	lea	ahiG3,a0
	bra.w	tickaa


*** ahi select mode
rahi3
	OPENAHI	1
	move.l	d0,d7
	beq.w	rahi3_e
	move.l	d0,a6

	lea	audioreqtags(pc),a0
	jsr	_LVOAHI_AllocAudioRequestA(a6)
	move.l	d0,d6
	beq.b	.gr

	move.l	d6,a0
	lea	audioreqtags2(pc),a1
	move.l	windowbase2(a5),4(a1)	* parent window

	jsr	_LVOAHI_AudioRequestA(a6)
	tst.l	d0
	beq.b	.gr
	move.l	d6,a0
	move.l	ahiam_AudioID(a0),d0
	move.l	d0,ahi_mode_new(a5)

	lea	-50(sp),sp

	lea	ahi_attrtags(pc),a1
	move.l	sp,ahimodenam-ahi_attrtags(a1)
	jsr	_LVOAHI_GetAudioAttrsA(a6)

	move.l	sp,a0
.f	tst.b	(a0)+
	bne.b	.f
	subq	#1,a0
	move.l	a0,d0
	sub.l	sp,d0
	moveq	#42,d1
	sub	d0,d1
	subq	#1,d1
	bmi.b	.h
.r	move.b	#' ',(a0)+
	dbf	d1,.r
	clr.b	(a0)
.h
	lea	ahi_name_new(a5),a1
	move.l	sp,a0
.c	move.b	(a0)+,(a1)+
	bne.b	.c

	lea	50(sp),sp


.gr
	tst.l	d6
	beq.b	.gr2
	move.l	d6,a0
	jsr	_LVOAHI_FreeAudioRequest(a6)
.gr2


	CLOSEAHI

;	bsr	pahi3
;	rts


pahi3	lea	ahi_name_new(a5),a0
	tst.b	(a0)
	bne.b	.y
	lea	.non(pc),a0
.y	movem	ahiG1+4,d0/d1
	add	#10,d0
	addq	#8,d1
	bra.w	print3b

.non	dc.b	"NONE",0
 even

rahi3_e
	lea	.e(pc),a1
	bra.w	request
.e	dc.b	"Couldn't open AHI device!",0
 even



audioreqtags2
	dc.l	AHIR_Window,0
	dc.l	AHIR_DoDefaultMode,TRUE
	dc.l	AHIR_SleepWindow,TRUE
	dc.l	AHIR_TitleText,ahirt
	dc.l	AHIR_TextAttr,text_attr
audioreqtags
	dc.l	TAG_END

ahirt	dc.b	"Select audio mode",0
 even

ahi_attrtags
	dc.l	AHIDB_BufferLen,39+4
	dc.l	AHIDB_Name,0
ahimodenam = *-4
	dc.l	TAG_END




*** ahi mixing rate
pahi4
rahi4
	lea	ahiG4,a2
	move	#580-050,d0		* max
	bsr.w	nappilasku
	add	#50,d0
	mulu	#100,d0
	move.l	d0,ahi_rate_new(a5)

	divu	#1000,d0
	swap	d0
	moveq	#0,d1
	move	d0,d1
	clr	d0
	swap	d0

	lea	info2_t(pC),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0
;	movem	ahiG4+4,d0/d1
	movem	4(a2),d0/d1
	sub	#65,d0
	addq	#8,d1
	bra.w	print3b

*** master volume
pahi5
rahi5	
	lea	ahiG5,a2
	move	#1000,d0		* max
	bsr.w	nappilasku
	move	d0,ahi_mastervol_new(a5)

	lea	.i(pC),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0
;	movem	ahiG5+4,d0/d1
	movem	4(a2),d0/d1
	sub	#49,d0
	addq	#8,d1
	bsr.w	print3b
	bra.b	updateahi

.i	dc.b	".%4.4ld",0
 even

*** stereo level
pahi6
rahi6	
	lea	ahiG6,a2
	moveq	#100,d0		* max
	bsr.w	nappilasku
	move	d0,ahi_stereolev_new(a5)

	lea	.i(pC),a0
	bsr.w	desmsg2
	lea	desbuf2(a5),a0
;	movem	ahiG6+4,d0/d1
	movem	4(a2),d0/d1
	sub	#41,d0
	addq	#8,d1
	bsr.w	print3b
	bra.b	updateahi
	

.i	dc.b	"%3.3ld%%",0
 even



updateahi
	pushm	all

	cmp	#pt_digiboosterpro,playertype(a5)
	beq.b	.d

	tst.b	ahi_use_nyt(a5)
	beq.b	.nd

.d	tst.l	playingmodule(a5)
	bmi.b	.nd
	tst.b	playing(a5)
	beq.b	.nd

	move.l	playerbase(a5),a0
	move	p_liput(a0),d0
	btst	#pb_ahi,d0
	beq.b	.nd

	move	ahi_mastervol_new(a5),d0
	move	ahi_stereolev_new(a5),d1
	jsr	p_ahiupdate(a0)
.nd	popm	all
	rts


 
*********************************
**************** Listselector
********************************

* Mieletˆn.

wflags4 = WFLG_SMART_REFRESH!WFLG_ACTIVATE!WFLG_BORDERLESS!WFLG_RMBTRAP
idcmpflags4 = IDCMP_INACTIVEWINDOW!IDCMP_GADGETUP!IDCMP_MOUSEBUTTONS!IDCMP_RAWKEY


listSelectorMainWindow
	pushm	d1-a6	
	move.l	windowbase(a5),a0	
	bra.b	listselector\.do

* in: 
*   d4 = callback to check whether line should be enabled
*   d6 = mouse x
*   d7 = mouse y
*   a0 = data to show
* out: 
*   d0 = selected index, or -1 if cancel
listselector:
.LINE_HEIGHT = 12

	pushm	d1-a6	
	move.l	a0,a4
	moveq	#0,d4
	move.l	windowbase2(a5),a0	* prefs-ikkuna
.do
	add	wd_LeftEdge(a0),d6	* mousepos suhteellinen prefs-ikkunan
	add	wd_TopEdge(a0),d7	* yl‰laitaan

	lea	winlistsel,a0		* asetetaan pointterin kohdalle

	moveq	#0,d5
	move.b	(a4),d5
	mulu	#8,d5
	add	#16,d5
	move	d5,nw_Width(a0)

	lsr	#1,d5
	sub	d5,d6
	bpl.b	.oe
	moveq	#0,d6
.oe	move	d6,nw_LeftEdge(a0)

	moveq	#0,d5
	move.b	1(a4),d5
	mulu	#.LINE_HEIGHT,d5
	addq	#8,d5
	move	d5,nw_Height(a0)

	lsr	#1,d5
	sub	d5,d7
	bpl.b	.oee
	moveq	#0,d7
.oee	move	d7,nw_TopEdge(a0)

	bsr.w	tark_mahtu

	lore	Intui,OpenWindow
	move.l	d0,d6
	beq.w	.x
	move.l	d0,a0
	move.l	wd_RPort(a0),d7		* rastport
	move.l	wd_UserPort(a0),a3	* userport


	pushm	all
	
	moveq	#0,d7
	move.b	(a4)+,d7	* max leveys
	lsl	#3,d7			* x8

	moveq	#0,d5
	move.b	(a4)+,d5	* vaakarivej‰
	subq	#1,d5
	move.l	a4,a0

	moveq	#0,d2
	moveq	#4,d3 	* start y
.prl	
	move.l	a0,a1
.fe	tst.b	(a1)+
	bne.b	.fe
	move.l	a1,d1
	sub.l	a0,d1
	subq	#1,d1
	lsl	#3,d1
	move	d7,d0
	sub	d1,d0
	lsr	#1,d0
	;addq	#8,d0	* right margin

	move	d3,d1
	* d0 = x
	* d1 = y
	* a0 = text
	bsr.w	.print
	add		#.LINE_HEIGHT,d3 * next y
	addq	#1,d2 * id number
	move.l	a1,a0
	dbf	d5,.prl

	movem.l	(sp),d0-a6

	move.l	d7,a1
	lea	winlistsel,a0
	moveq	#0,plx1
	move	nw_Width(a0),plx2
	moveq	#0,ply1
	move	nw_Height(a0),ply2
	subq	#1,ply2
	subq	#1,plx2
	bsr.w	laatikko1
	popm	all

	moveq	#-1,d7		* selection
.msgloop3
	moveq	#0,d0
	move.b	MP_SIGBIT(a3),d1	* IDCMP signalibitti
	bset	d1,d0
	lore	Exec,Wait			* Odotellaan...

	move.l	a3,a0
	lob	GetMsg
	tst.l	d0
	beq.b	.msgloop3

	move.l	d0,a1
	move.l	im_Class(a1),d2		* luokka	
	move	im_Code(a1),d3		* koodi
	move.l	im_IAddress(a1),a2 	* gadgetin tai olion osoite
;	move	im_MouseX(a1),d6	* mousen koordinaatit
;	move	im_MouseY(a1),d7

	lob	ReplyMsg

	cmp.l	#IDCMP_GADGETUP,d2
	bne.b	.noGadget
	move	gg_GadgetID(a2),d7
	bra.b	.done
.noGadget
	cmp.l	#IDCMP_MOUSEBUTTONS,d2
	bne.b	.noButtons
	cmp		#SELECTDOWN,d3
	beq.b	.done
	cmp		#MENUDOWN,d3
	beq.b	.done
.noButtons
	cmp.l	#IDCMP_RAWKEY,d2
	beq.b	.done
	cmp.l	#IDCMP_INACTIVEWINDOW,d2
	bne.b	.msgloop3
	
.done
	move.l	d6,a0
	bsr.w	flushWindowMessages

	move.l	d6,d0
	beq.b	.eek
	move.l	d0,a0
	lore	Intui,CloseWindow
.eek
.x
	lea	listSelectorRememberPtr(a5),a0
	moveq	#1,d0 * forget all of it
	lore	Intui,FreeRemember

	move	d7,d0
	popm	d1-a6
	rts

* Makes a bool gadget 
* In:
*   d0 = x
*   d1 = y
*   d2 = id
*   d4 = callback
*   a0 = text
*   d6 = window base
.print
	pushm	all
	
	move.l	a0,a4	* save text
	move	d0,d5
	move	d1,d7
	move	d2,d3

	; Get NewGadget
	lea	listSelectorRememberPtr(a5),a0
	moveq	#gg_SIZEOF,d0
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	lore	Intui,AllocRemember
	tst.l	d0
	beq		.xx
	move.l	d0,a3
	; Only need to change these fields
	move	#GFLG_GADGHCOMP,gg_Flags(a3)
	move	#GACT_RELVERIFY,gg_Activation(a3)
	move	#GTYP_BOOLGADGET,gg_GadgetType(a3)

	move.l	d6,a0
	move	wd_Width(a0),d0
	sub		#16-4,d0
	move	d0,gg_Width(a3)
	move	#.LINE_HEIGHT,gg_Height(a3)
	move	#8-2,gg_LeftEdge(a3)
	move	d7,gg_TopEdge(a3)
	move	d3,gg_GadgetID(a3)

	* Enable/disable callback
	tst.l	d4
	beq.b	.enabled
	move.l	d4,a0
	jsr		(a0)
	bne.b	.enabled
	or	#GFLG_DISABLED,gg_Flags(a3)
.enabled

	lea	listSelectorRememberPtr(a5),a0
	moveq	#it_SIZEOF,d0
	move.l	#MEMF_CLEAR!MEMF_PUBLIC,d1
	lob		AllocRemember
	tst.l	d0
	beq		.xx
	move.l	d0,a2
	move.l	a2,gg_GadgetText(a3)
	move.b	#1,it_FrontPen(a2)
	move.b	#RP_JAM1,it_DrawMode(a2)
	move.l	a4,it_IText(a2)
	move.l	#text_attr,it_ITextFont(a2)
	addq	#2,d5
	move	d5,it_LeftEdge(a2)	
	move	#2,it_TopEdge(a2)

	move.l	d6,a0
	move.l	a3,a1
	moveq	#0,d0 * position
	lob		AddGadget

	move.l	a3,a0
	move.l	d6,a1 * window
	sub.l	a2,a2 * req
	moveq	#1,d0 * numgad
	lob		RefreshGList

	move.l	d6,a1
	move.l	wd_RPort(a1),a1
	move.l	a3,a3
	bsr		doDrawButtonFrame
.xx
	popm	all
	rts


*******************************************************************************
*  End of Prefs section
*******************************************************************************

*******
* Kirjoitetaan n‰kyv‰t tiedoston nimet ikkunaan
* Writes the filenames into the box
*******

* hippoonbox(a5) is a flag that requests the whole list to be redrawn instead
* of some clever partial refresh that is used when scrolling up and down.


showNamesNoCentering
shownames2
	moveq	#1,d4		* flag: do not center
	bra.b	shownames\.doit

* Clears the filebox area
clearbox:
	tst	boxsize(a5)
	beq.b	.x
	tst.b	win(a5)
	bne.b	.r
.x	rts
.r	moveq	#30+WINX,d0
	moveq	#62+WINY,d1
;	move	#251+WINX,d2
	move	WINSIZX(a5),d2
	sub	#10,d2
	move	#127+WINY,d3
 	tst.b	altbuttonsUse(a5)
	beq.b	.noAlt1
	add	#16,d1
	add	#16,d3  
.noAlt1
	add	boxy(a5),d3
	bra.w	tyhjays

shownames:
	moveq	#0,d4	 	* flag: center
.doit
	tst	boxsize(a5)
	beq.b	.bx
	tst.b	win(a5)		* onko ikkunaa?
	bne.b	.iswin
.bx	rts

.iswin

	pushm	all

	tst.l	modamount(a5)
	bne.b	.eper

	bsr.b	clearbox

	cmp.b 	#LISTMODE_FAVORITES,listMode(a5)
	bne.b	.doHippo
	* What to show when no modules and favorites mode?
	moveq	#90+WINX,d0
	lea	.noFavs(pc),a0
	tst.b	favorites(a5)
	bne.b	.favsOn
	lea	.noFavs2(pc),a0
	moveq	#90-7*8+WINX,d0
.favsOn
	bsr.w	printbox
	bra.b	.wasFav
.noFavs 	dc.b 	"No favorites!",10
		dc.b	"Add with RMB.",0
.noFavs2	dc.b	"Favorites feature disabled!",0
		even
.doHippo
	bsr.w	printhippo1
.wasFav	
	st	hippoonbox(a5)		* koko hˆsk‰n tulostus
	bra.w	.nomods
.eper

	tst	d4		* ei mink‰‰nlaista uudelleensijoitusta
	bne.b	.nob

	moveq	#0,d2
	move	boxsize(a5),d2
	move.l	d2,d3
	lsr	#1,d2		* center chosenmodule in the middle of the box
	
	move.l	chosenmodule(a5),d0
	;DPRINT "Shownames center index %ld"

	sub.l	d2,d0
	bmi.b	.nok
	move.l	modamount(a5),d1
	sub.l	d3,d1
	bmi.b	.nok
	cmp.l	d1,d0
	blo.b	.ok
	move.l	d1,d0
	bra.b	.ok
.nok	
	moveq	#0,d0	
.ok	
	move.l	d0,firstname(a5)
	;DPRINT "->first name %ld"

.nob
	tst.b	hippoonbox(a5)
	beq.b	.eh
	clr.b	hippoonbox(a5)
	bra.w	.neen
.eh
	move.l	firstname(a5),d0
	move.l	firstname2(a5),d7
	move.l	d0,firstname2(a5)
	cmp.l	d0,d7
	beq.w	.nomods
	sub.l	d0,d7		* d7 should be in range 0..boxsize
	bmi.b	.alas

.ylos
	moveq	#0,d1 
	move	boxsize(a5),d1
	cmp.l	d1,d7
	bhs.w	.all

	bsr.w	.unmark

* siirrytty d7 rivi‰ ylˆsp‰in:
* kopioidaan rivit 0 -> d7 (koko: boxsize-d7 r) kohtaan 0 ja printataan
* kohtaan 0 d7 kpl uusia rivej‰

	moveq	#63+WINY,d1		* source y
	move	d7,d3
	;lsl	#3,d3
	mulu	listFontHeight(a5),d3
	add	#63+WINY,d3		* dest y
	tst.b	altbuttonsUse(a5)
	beq.b	.noAlt1
	add	#16,d1		* source y
	add	#16,d3		* desy y
.noAlt1
	bsr.w	.copy
	move.l	firstname(a5),d0
	moveq	#0,d1
	move	d7,d2
	bra.b	.rcr


.alas	
	moveq	#0,d1 
	move	boxsize(a5),d1
	neg.l  	d7 
	cmp.l	d1,d7 
	bhs.b	.all

	bsr.w	.unmark

* siirrytty d7 rivi‰ alasp‰in:
* kopioidaan rivit d7 -> boxsizee (koko: boxsize-d7 r) kohtaan 0 ja printataan
* kohtaan boxsize-d7 d7 kpl uusia rivej‰

	move	d7,d1
	;lsl	#3,d1
	mulu	listFontHeight(a5),d1
	add	#63+WINY,d1		* source y	
	moveq	#63+WINY,d3	* dest y
	tst.b	altbuttonsUse(a5)
	beq.b	.noAlt2
	add	#16,d1		* source y
	add	#16,d3		* dest y
.noAlt2
	bsr.b	.copy
	moveq	#0,d0 
	move 	boxsize(a5),d0 
	add.l 	firstname(a5),d0
	sub.l	d7,d0
	moveq	#0,d1 
	move	boxsize(a5),d1
	sub.l   d7,d1
	move.l	d7,d2

.rcr	bsr.w	doPrintNames
	bra.b	.huh2

.nomods	
	bsr.b	.unmark
.huh2
.xx
	move.l	#-1,markedline(a5)
	move.l	chosenmodule(a5),d0
	bmi.b	.huh
	sub.l	firstname(a5),d0
	bmi.b	.huh
	move.l	d0,markedline(a5)		* merkit‰‰n valittu nimi
	bsr.w	markit
.huh
	move.l	chosenmodule(a5),chosenmodule2(a5)
	move.l	firstname(a5),firstname2(a5)
	clr.b	dontmark(a5)

	popm	all
	rts

.all
.neen
	* clear and print all names
	bsr.w	clearbox

	move.l	firstname(a5),d0
	moveq	#0,d1
	move	boxsize(a5),d2
	bsr.b	doPrintNames
	bra.b	.huh2



.copy	
	move	boxsize(a5),d5	* y size
	sub	d7,d5
	;lsl	#3,d5
	mulu	listFontHeight(a5),d5

	moveq	#32+WINX,d0	* source x
	move	d0,d2		* dest x
	;move	#27*8+1,d4	* x size
	move	WINSIZX(a5),d4
	sub	#264-216-2,d4

	add	windowleft(a5),d0
	add	windowtop(a5),d1
	add	windowleft(a5),d2
	add	windowtop(a5),d3
	move.l	rastport(a5),a0
	move.l	a0,a1
	move.b	#$c0,d6		* minterm: a->d
	move.l	_GFXBase(a5),a6
	jmp	_LVOClipBlit(a6)



.unmark
	tst.b	dontmark(a5)
	bne.b	.huh22

	move.l	chosenmodule2(a5),d0
	bmi.b	.huh22
	sub.l	firstname2(a5),d0
	bmi.b	.huh22
	push	d7
	move.l	chosenmodule(a5),-(sp)
	move.l	chosenmodule2(a5),chosenmodule(a5)
	bsr.w	unmarkit
	move.l	(sp)+,chosenmodule(a5)
	pop	d7
.huh22	rts

* d0 = alkurivi
* d1 = eka rivi ruudulla
* d2 = printattavien rivien m‰‰r‰
doPrintNames
;	DPRINT  "shownames obtain list"
	bsr.w  obtainModuleList
	;lea	moduleListHeader(a5),a4	
	bsr.w	getVisibleModuleListHeader
	move.l	a0,a4

; if DEBUG
; 	ext.l	d2
;	DPRINT	"doPrintNames first=%ld target=%ld amount=%ld"
; endif
	* d0 = module index
	* d1 = line number to print to
	* d2 = number of lines to print
	* find out the corresponding list entry
	move.l	d0,d3 		* keep track of the module index as well here
	move.l	d1,d4		* move this out of the way
	subq.l	#1,d0
	bmi.b	.baa

	bsr.w	getListNodeCached
	beq.w	.lop	* check for z-flag error indication
	tst.l	(a0)
	beq.w	.lop
	move.l	a0,a3
	move.l	a0,a4
.baa

	move	d2,d5
	subq	#1,d5

	move	d4,d6
	;lsl	#3,d6
	mulu	listFontHeight(a5),d6
	add	#83+WINY-14,d6		* turn line number into a Y-coordinate
	tst.b	altbuttonsUse(a5)
	beq.b	.noAlt1
 	add	#16,d6	
.noAlt1

	move.l	rastport(a5),a1
	move.l	listfontbase(a5),a0
	lore	GFX,SetFont
	
	jsr	setListBoxClip

	* loop to print d5 lines 
.looppo
	* a4=current node
	* a3=next node
	* test if at end
	TSTNODE	a4,a3
	beq.w	.lop			* joko loppui
	move.l	a3,a4
	
	move.l	l_nameaddr(a3),a0
	bsr.w	cut_prefix
	move.l	a0,a2		* name is in a2

	moveq	#0,d7		* clear divider flag

	tst.b	l_divider(a3)
	beq.b	.nodi
	st	d7	* set flag: divider being handled
	* Set color for list divider
	push	a1
	cmp.b	#LISTMODE_BROWSER,listMode(a5)
	beq.b	.1
.3	move.l	pen_2(a5),d0
	move.l	rastport(a5),a1
	lore	GFX,SetBPen
	move.l	pen_3(a5),d0
	move.l	rastport(a5),a1
	lob	SetAPen
	bra.b	.2
.1
	* Filebrowser divider color
	* Special case for parent node:
	tst.b	l_divider(a3)
	bpl.b	.3
	* Filebrowser directory:
	move.l	pen_2(a5),d0
	move.l	rastport(a5),a1
	lore	GFX,SetAPen
.2
	pop	a1
.nodi

	* name to print
	move.l	a2,a0		
	
	lea	-200(sp),sp
	tst.b	l_remote(a3)
	beq.b	.local
	move.l	a0,d0
	* Remote entries: url decoding, also replace /
	move.l	sp,a1
.unescape
	move.b	(a0)+,d0
	cmp.b	#"/",d0
	bne.b	.noSlsh
	move.b	#" ",(a1)+
	move.b	#"-",(a1)+
	move.b	#" ",(a1)+
	bra.b	.unescape
.noSlsh
	cmp.b	#"%",d0
	bne.b	.noEsc
	bsr		convertHexTextToNumber
.noEsc
	move.b	d0,(a1)+
	bne		.unescape

	* cleaned up name 
	move.l	sp,a0
.local

	* target x, y
	moveq	#33+WINX,d0
	move.l	d6,d1
	* progress to next vertical line 
	add	listFontHeight(a5),d6

	; Adjust y-position according to baseline,
	; so it will hit the exact spot
	move.l	listfontbase(a5),a1
	add	tf_Baseline(a1),d1
	subq	#6,d1
	push	d1	; save start y

	* Favorites are bolded, skip this if feature disabled
	tst.b	favorites(a5)
	beq.b	.noFav
	isFavoriteModule a3
	beq.b	.noFav
	cmp.b 	#LISTMODE_FAVORITES,listMode(a5)
	beq.b	.noBold
	bsr.w	printBold
	bra.b	.wasFav
.noFav
.noBold
	bsr.w	print
.wasFav
	; Clear the line towards the right edge of rastport
	move.l	rastport(a5),a1	
	lore	GFX,ClearEOL

	pop	d1	; restore start y
	
	lea		200(sp),sp * name buffer

	; Display random marker if needed
	tst.b	d7		* divider will not have a random play marker
	bne.b	.noMarker
	cmp.b	#pm_random,playmode(a5)
	bne.b	.noMarker
	* Random play mode magic check: Add a marker to the end to indicate module has been played?
	* Here the module index is needed
	move.l 	d3,d0 
	bsr.w	testRandomTableEntry ; keeps d1 is safe
	beq.b	.noMarker

	* marker x-pos relative to the right edge
	moveq	#-12,d0
	add	WINSIZX(a5),d0

	* Go back the amount of pixels for the marker
	move.l	rastport(a5),a1
	move.l	rp_Font(a1),a1
	lea	.marker(pc),a0
	
	* See if the marker has a glyph in the font
	move	#"Æ",d2
	cmp.b	tf_HiChar(a1),d2
	bls.b	.yesRmark
	* Use alternative
	moveq	#"*",d2
.yesRmark
	move.b	d2,(a0)

	* How many pixels does it take
	tst.l	tf_CharSpace(a1)
	beq.b	.noCharSpace
	* Check individual char spaces, prop fonts
	sub.b	tf_LoChar(a1),d2
	add	d2,d2
	move.l	tf_CharSpace(a1),a1
	sub	(a1,d2),d0
	bra.b	.hadCharSpace
.noCharSpace
	* Fixed width font
	sub	tf_XSize(a1),d0	

.hadCharSpace
	bsr.w	print ; print marker to d0, d1
.noMarker

	* Set ordinary colors if divider was previously printed
	tst.b	d7
	beq.b	.nodiv
	move.l	pen_0(a5),d0
	move.l	rastport(a5),a1
	lore	GFX,SetBPen
	move.l	pen_1(a5),d0
	move.l	rastport(a5),a1
	lob	SetAPen
.nodiv

	* loop until all names printed
	addq.l	#1,d3 	 	* next module index
	dbf	d5,.looppo
.lop	
	* Lines printed

	* Restore normal font
	move.l	rastport(a5),a1
	move.l	fontbase(a5),a0
	lore	GFX,SetFont

	jsr	removeListBoxClip

	bsr.w 	releaseModuleList
	rts
	
.marker	dc.b	0,0


***** Katkaisee prefixin nimest‰ a0:ssa

cut_prefix:
;	isListDivider (a0)		* onko divideri?
;	beq.b	.xx

	pushm	d0/a1
	move.b	prefixcut(a5),d0
	beq.b	.x
	move.l	a0,a1
	ext	d0
;	subq	#1,d0
.l	cmp.b	#".",(a0)+
	beq.b	.x
	tst.b	-1(a0)
	beq.b	.h
	dbf	d0,.l
.h	move.l	a1,a0
	
.x	popm	d0/a1
.xx	rts


* in:
*   a0 = test pointer with two chars to convert
* out: 
*   d0 = number
convertHexTextToNumber
	pushm	d1-d3
	moveq	#2-1,d2
	moveq	#4,d1
	moveq	#0,d0
.loop
	moveq	#0,d3
	move.b	(a0)+,d3
	cmp.b	#"a",d3
	bhs.b	.hih 
	cmp.b	#"A",d3
	bhs.b	.hi 
	sub.b	#"0",d3
	bra.b	.lo
.hih
	sub.b	#"a"-10,d3
	bra.b	.lo
.hi
	sub.b	#"A"-10,d3
.lo
	lsl	d1,d3
	or	d3,d0
	subq	#4,d1
	dbf	d2,.loop
	popm	d1-d3
	rts

*******************************************************************************
* Deletoidaan yksi tiedosto listasta
*******

* right mouse button + Del button
hiiridelete
	skipIfGadgetDisabled gadgetDelButton
	tst.l	chosenmodule(a5)
	bmi.b	.noChosen
	bsr.w	areyousure_delete
	tst.l	d0
	bne.b	rbutton8b
.noChosen
	rts

rbutton8b
	skipIfGadgetDisabled gadgetDelButton
.l	moveq	#1,d7		* DELETE from DISK!
	bsr.b	delete\.elete
	tst.b	deleteflag(a5)
	bne.b	.l
	bra.w	resh

rbutton8
deleteButtonAction
delete
	cmp.b	#LISTMODE_BROWSER,listMode(a5)
	beq.w	fileBrowserGoToParent

	skipIfGadgetDisabled gadgetDelButton
	moveq	#0,d7
	bsr.b	.elete
	bsr.w	resh
	clr.b	deleteflag(a5)
.skip
	rts
.elete
	bsr.w	confirmFavoritesModification
	beq.b	.skip

	clr.b	movenode(a5)
	moveq	#PLAYING_MODULE_NONE,d0
	move.l	d0,chosenmodule2(a5)
	st	hippoonbox(a5)
	bsr.w	listChanged

	move.l	chosenmodule(a5),d0
	bmi.w	.erer

	tst.l	playingmodule(a5)
	bmi.b	.huh	

	cmp.l	playingmodule(a5),d0	* onko dellattava sama kuin soitettava?
	beq.b	.sama

	subq.l	#1,playingmodule(a5)
	bpl.b	.huh
.sama	move.l	#PLAYING_MODULE_REMOVED,playingmodule(a5)

.huh	tst.l	modamount(a5)
	beq.w	.erer

	;lea	moduleListHeader(a5),a4
	bsr.w	getVisibleModuleListHeader
	move.l	a0,a4

	DPRINT	"delete getListNode"
	bsr.w	getListNode
	beq.w	.erer
	move.l	a0,a3
	
	tst.l	d7
	beq.b	.nmod

;	isListDivider l_filename(a3)
;	bne.b	.de
	tst.b	l_divider(a3)
	beq.b	.de
	not.b	deleteflag(a5)		 * Deleting a divider! Special action
	beq.w	.nmodo
	bra.b	.ni
.de
	tst.b	deleteflag(a5)
	bne.b	.ni

	pushm	all
	lea	.del(pc),a0
	moveq	#37+WINX,d0
	bsr.w	printbox
	popm	all


	moveq	#-2,d5
	moveq	#0,d6
.noa
	lea	l_filename(a3),a0
	tst.b	l_remote(a3)	* can't delete remotes
	bne.b	.nmod
	move.l	a0,d1
	lore	Dos,DeleteFile	
	tst.l	d0
	bne.b	.nmod

* ei onnistunu.
	addq	#1,d5
	beq.b	.ni

	tst	d6
	bne.b	.noa

	pushm	d5/d6
	bsr.w	rbutton4	* ejektoidaan ja yritet‰‰n uusiks
	popm	d5/d6
	bra.b	.noa

.ni
** onko toisiks viimenen dellattava?
	move.l	modamount(a5),d0
	subq.l	#1,d0
	cmp.l	chosenmodule(a5),d0
	bne.b	.nmod
	clr.b	deleteflag(a5)

.nmod
	move.l	a3,a1
	lore	Exec,Remove
	move.l	a3,a0
 ifne DEBUG
	DPRINT2 "Deleting->",1
	DEBU	l_filename(a0)
	DPRINT  "<-"
 endc


	bsr.w	freemem

	subq.l	#1,modamount(a5)
	bpl.b	.ak
	bne.b	.ak
	move.l	#PLAYING_MODULE_NONE,chosenmodule(a5)
	bra.b	.ee
.ak	
	move.l	modamount(a5),d0
	cmp.l	chosenmodule(a5),d0
	bne.b	.ee
	subq.l	#1,d0
	move.l	d0,chosenmodule(a5)
.ee
.nmodo
	st	hippoonbox(a5)
	bra.w	shownames
;	rts

.erer	clr.b	deleteflag(a5)
	rts

.del	dc.b	"-ªª>> Deleting file! <<´´-",0
 even	



***************************************************************************
*
* Execute file
*

execuutti
	lea	-300(sp),sp
	move.l	sp,a4
	clr.b	(a4)

	jsr	get_rt
	moveq	#RT_FILEREQ,D0
	sub.l	a0,a0
	lob	rtAllocRequestA
	move.l	d0,d7
	beq.b	.kex

	tst.b	uusikick(a5)
	beq.b	.ne
	move.l	lockhere(a5),d1
	pushpea	200(sp),d2
	moveq	#100,d3
	jsr	getNameFromLock
	lea	.tagz(pc),a0
	move.l	d7,a1
	pushpea	200(sp),4(a0)
	lore	Req,rtChangeReqAttrA
.ne
	lea	otag15(pc),a0
	move.l	d7,a1
	lea	(a4),a2		* tiedoston nimi

	lea	.title(pc),a3
	lob	rtFileRequestA		* ReqToolsin tiedostovalikko
	tst.l	d0
	beq.b	.kex

	move.l	d7,a0
	lea	100(a4),a1
	move.l	#'run ',(a1)+
	bsr.w	parsereqdir2
	addq	#1,a1
.c	move.b	(a4)+,(a1)+
	bne.b	.c

* sp+100 = ajettava komento

	pushpea	100(sp),d1
	moveq	#0,d2			* input
	move.l	nilfile(a5),d3		* output
	lore	Dos,Execute


.kex	lea	300(sp),sp
	rts

.tagz	dc.l	RTFI_Dir,0
	dc.l	TAG_END

.title	dc.b	"Select executable",0
 even

*******************************************************************************
* Kahden ylimm‰isen tekstirivin hommat (loota)
*******
* 30 merkki‰ leve‰ alue

inforivit_clear
	movem.l	d0-d4,-(sp)
	moveq	#7+WINX,d0
	moveq	#11+WINY,d1
;	move	#252+WINX,d2
	move	WINSIZX(a5),d2
	sub	#10,d2
	moveq	#28+WINY,d3
	bsr.w	tyhjays
	movem.l	(sp)+,d0-d4
	rts

inforivit_killerps3m
	lea	var_b,a5
inforivit_play
	bsr.b	inforivit_clear
	tst.l	playingmodule(a5)
	bpl.b	.huh
	bra.w	bopb
	
.huh
 ifne FEATURE_HORIZ_RESIZE	
	; determine field length for name based on window width
	moveq	#0,d2
	move	WINSIZX(a5),d2
	; left and right border, length of "Name: ", some more
	sub	#8+8+6*8+8,d2
	lsr	#3,d2
	divu	#10,d2
	or.l	#$30<<16+$30,d2
	lea	fieldLen1(pc),a0
	basereg	fieldLen1,a0
	move.b	d2,fieldLen1+0(a0)
	move.b	d2,fieldLen2+0(a0)
	swap	d2
	move.b	d2,fieldLen1+1(a0)
	move.b	d2,fieldLen2+1(a0)
	endb	a0
 endif ; FEATURE

	moveq	#0,d2

* Jos S3M, nime‰ ei tartte siisti‰.

	cmp	#pt_multi,playertype(a5)
	bne.w	.eer

	move.l	ps3m_mtype(a5),a0
	cmp	#mtMOD,(a0)		* MODeissa ei konvertointia
	seq	d2

	lea	asciitable,a2		* konvertoidaan PC -> Amiga

	move.l	ps3m_mname(a5),a0
	move.l	(a0),a0
	lea	modulename(a5),a1
	moveq	#INFO_MODULE_NAME_LEN-1,d0
	moveq	#0,d1
.copc	move.b	(a0)+,d1

	tst.b	d2
	beq.b	.htht
	move.b	d1,(a1)+
	bra.b	.hth
.htht	
	move.b	(a2,d1),(a1)+
.hth	dbeq	d0,.copc
	clr.b	(a1)

	move.l	ps3m_numchans(a5),a0
	move	(a0),d2

	move.l	ps3m_mtype(a5),a0
	move	(a0),d0
	move	d0,d3

	lea	.1(pc),a0
	subq	#1,d0
	beq.b	.hee 	; s3m
	lea	.2(pc),a0
	subq	#1,d0
	beq.b	.hee2	; Pro/Fasttracker
	lea	.3(pc),a0
	subq	#1,d0
	beq.b	.hee  	; mtm
	lea	.4(pc),a0
	subq	#1,d0
	beq.b	.hee  	; xm
	moveq	#0,d2  	; it: clear channel count for
	lea	 .5(pc),a0
.hee	move.l	a0,d1

	cmp	#mtMOD,d3
	bne.w	.leer
	pushm	d1/d2
	bsr.w	siisti_nimi
	popm	d1/d2
	bra.w	.leer

.hee2
	; ensure zero termination for pt mods?
	lea	modulename(a5),a1
	clr.b	20(a1)
	bra.b	.hee

.1	dc.b	"Screamtracker ]I[",0
.2	dc.b	"Pro/Fasttracker",0
.3	dc.b	"Multitracker",0
.4	dc.b	"Fasttracker ][ XM",0
.5	dc.b	"ImpulseTracker      [DP]",0
 even

.eer	bsr.w	siisti_nimi

	move.l	playerbase(a5),a0
	lea	p_name(a0),a0
	move.l	a0,d1

	tst.b	oldst(a5)
 	beq.b	.leer
	pushpea	.oldst(pc),d1
	bra.b	.leer
.oldst	dc.b	"Old Soundtracker",0
 even
.leer

	lea	modulename(a5),a0
	move.l	a0,d0

	lea	tyyppi1_t(pc),a0
	tst	d2			* PS3M channel count
	beq.b	.ic
	lea	tyyppi2_t(pc),a0
.ic	bsr.w	desmsg

	lea	desbuf(a5),a2		* moduletyyppi talteen
	move.l	a2,a0
	lea	moduletype(a5),a1
.ol	cmp.b	#10,(a2)+
	bne.b	.ol
	addq.l	#6,a2
.cep	move.b	(a2)+,(a1)+
	bne.b	.cep
	clr.b	(a1)

bipb	moveq	#18+WINY,d1
bipb2	moveq	#11+WINX,d0
	printt "TODO TODO: length check"
	jsr	print
bopb	rts

putinfo:
	bsr.w	inforivit_clear
	bra.b	bipb

putinfo2
	moveq	#26+WINY,d1
	bra.b	bipb2	

infolines_loadToChipMemory
	lea	.1(pc),a0
	bra.b	putinfo
.1	dc.b	"Loading to chip memory...",0
 even

infolines_loadToPublicMemory
	lea	.1(pc),a0
	bra.b	putinfo
.1	dc.b	"Loading to public memory...",0
 even

 
inforivit_tfmxload
	lea	.1(pc),a0
	bra.b	putinfo
.1	dc.b	"Loading TFMX samples...",0
 even

inforivit_ppload
	lea	.1(pc),a0
	bra.b	putinfo2
.1	dc.b	"PowerPacker file",0
 even

inforivit_pause
	lea	.1(pc),a0
	bra.w	putinfo2
;.1	dc.b	"        *** Paused ***        ",0
.1	dc.b	"-=-=-=-=-=- Paused -=-=-=-=-=-",0
 even

inforivit_xpkload
	lea	.1(pc),a0
	lea	probebuffer+8(a5),a1
	move.l	a1,d0
	bsr.w	desmsg
	lea	desbuf(a5),a0
	bra.w	putinfo2
.1	dc.b	"XPK %4s",0
 even

inforivit_xpkload2
	lea	.1(pc),a0
	bra.w	putinfo
.1	dc.b	"Identifying XPK file...",0
 even

inforivit_fimpload
	lea	.1(pc),a0
	bra.w	putinfo2
.1	dc.b	"FImp file",0
 even

inforivit_fimpdecr
	lea	.1(pc),a0
	bra.w	putinfo
.1	dc.b	"Exploding...",0
 even

inforivit_xfd
	lea	.1(pc),a0
	bsr.w	desmsg	
	lea	desbuf(a5),a0
	bra.w	putinfo
.1	dc.b	"XFD decrunching...",10
	dc.b	"%-30s",0
 even


inforivit_errc
	lea	.1(pc),a0
	bra.w	putinfo
.1	dc.b	"*** ERROR ***",10
	dc.b	"Skipping...",0
 even

inforivit_initerror
	lea	.1(pc),a0
	bra.w	putinfo
.1	dc.b	"Initialization error!",0
 even

inforivit_warn
	lea	.1(pc),a0
	bra.w	putinfo
.1	dc.b	"*** Warning! ***",10
	dc.b	"File was loaded in chip ram! ",0
 even

inforivit_group
	lea	.1(pc),a0
	bra.w	putinfo
.1	dc.b	"Loading player group...",0
 even

inforivit_group2
	lea	.1(pc),a0
	bra.w	putinfo
.1	dc.b	"Loading replayer...",0
 even

inforivit_extracting
	lea	.1(pc),a0
	tst	d6
	beq.b	.q
	lea	.2(pc),a0
	subq	#1,d6
	beq.b	.q
	lea	.3(pc),a0
.q	bra.w	putinfo
.1	dc.b	"LhA extracting...",0
.2	dc.b	"UnZipping...",0
.3	dc.b	"LZX extracting...",0
 even

inforivit_downloading
	lea	.1(pc),a0
	bra.w	putinfo
.1	dc.b	"Downloading...",0
 even

inforivit_searching
	lea	.1(pc),a0
	bra.w	putinfo
.1	dc.b	"Searching...",0
 even


;inforivit_initializing
;	lea	.1(pc),a0
;	bra.w	putinfo2
;.1	dc.b	"Initializing...",0
; even
;
;inforivit_identifying
;	lea	.1(pc),a0
;	bra.w	putinfo
;.1	dc.b	"Identifying...",0
; even
;
* Siistit‰‰n moduulin nimi 

siisti_nimi
	lea	modulename-1(a5),a0
	bsr.b	.cap
.loo	addq.l	#1,a0
	tst.b	(a0)
	beq.b	.end
	cmp.b	#' ',(a0)
	beq.b	.jee
	cmp.b	#'-',(a0)
	beq.b	.jee
	cmp.b	#'(',(a0)
	beq.b	.jee
	cmp.b	#')',(a0)
	beq.b	.jee
	cmp.b	#'<',(a0)
	beq.b	.jee
	cmp.b	#'>',(a0)
	beq.b	.jee
	cmp.b	#'_',(a0)
	beq.b	.jee
	bra.b	.loo
.end
	rts


.jee	tst.b	1(a0)
	beq.b	.end
	bsr.b	.cap
	bra.b	.loo

.cap	
	cmp.b	#'a',1(a0)		* Jos mahdollista, muutetaan
	blo.b	.m			* kirjain isoksi.
	cmp.b	#'z',1(a0)
	bhi.b	.m
	and.b	#$df,1(a0)

	cmp.b	#'I',1(a0)
	bne.b	.m
	cmp.b	#'i',2(a0)
	bne.b	.m
	and.b	#$df,2(a0)
	cmp.b	#'i',3(a0)
	bne.b	.m
	and.b	#$df,3(a0)
.m	rts



fieldLen1 = *+8
tyyppi1_t	dc.b	"Name: %.24s",10
		dc.b	"Type: %.24s",0

fieldLen2 = *+8
tyyppi2_t	dc.b	"Name: %.24s",10
		dc.b	"Type: %.24s %ldch",0
typpi
 even

*******************************************************************************
* Loota (otsikkopalkki tiedot)
*******

settimestart
	move.b	ahi_use(a5),ahi_use_nyt(a5)	* ahi:n tila talteen

	pushm	d0/d1/d2/a0/a1/a6
	pushpea	datestamp1(a5),d1
	lore	Dos,DateStamp
	move.l	datestamp1+4(a5),d0
	mulu	#60*50,d0
	add.l	datestamp1+8(a5),d0
	move.l	d0,aika1(a5)

	check	3

	popm	d0/d1/d2/a0/a1/a6
	rts


* 0= 	dc.b	8+4,"Time, pos/len, song",0
* 1= 	dc.b	0,"Time/duration, pos/len",0
* 2= 	dc.b	2*8,"Clock, free memory",0
* 3=		4*8,"Module name",0


lootaa					* p‰ivitet‰‰n kaikki

	bsr.w	lootaan_kello
;	bsr.w	lootaan_muisti
	bsr.w	lootaan_nimi
;	bsr.b	lootaan_aika		
;	rts

lootaan_pos

lootaan_song
;	moveq	#1,d0

lootaan_aika
	moveq	#0,d0
	tst	lootamoodi(a5)
	beq.b	.ook
	cmp	#3,lootamoodi(a5)
	beq.b	.ook
	rts
.ook	
	pushm	all
	clr.b	do_alarm(a5)		* sammutetaan her‰tys

	clr	lootassa(a5)		

* ajan p‰ivitys (datestamp-magic)

	tst	d0			* mit‰ t‰‰ tekee?
	bne.b	.npa

	move.l	aika2(a5),d3

	pushpea	datestamp2(a5),d1
	lore	Dos,DateStamp
	move.l	datestamp2+4(a5),d0
	mulu	#60*50,d0
	add.l	datestamp2+8(a5),d0
	move.l	d0,aika2(a5)

	cmp	#pt_multi,playertype(a5)
	bne.b	.je
	cmp.b	#5,s3mmode1(a5)		* killer
	beq.b	.not
.je
	tst.b	playing(a5)
	bne.b	.npa

.not

	sub.l	d3,d0
	add.l	d0,aika1(a5)		* erotus samana jos ei soiteta
.npa

	move.l	aika2(a5),d0
	sub.l	aika1(a5),d0

	move.l	d0,hippoport+hip_playtime(a5)

************* t‰h‰n timeout!
	move	timeout(a5),d1
	beq.w	.ok0
	mulu	#50,d1

	cmp.l	d1,d0
	blo.b	.ok0

	DPRINT 	"Timeout triggered %ld"

	cmp.l	#1,modamount(a5)	* 0 tai 1 modia -> ei timeouttia
	bls.b	.ok0

	tst.b	timeoutmode(a5)		* timeout-moodi
	beq.b	.all			* -> kaikille modeille

	move.l	playerbase(a5),a0	* vain niille, joilla ei ole
	move	p_liput(a0),d1		* end-detectia.
	btst	#pb_end,d1		* onko end-detect?
	bne.b	.ok0			* -> on
	btst	#pb_poslen,d1		* poslenist‰ voidaan p‰‰tell‰ end-detect
	bne.b	.ok0

.all	push	d0			* painetaan 'next'i‰ :)

	move	#$28,rawkeyinput(a5)	* NEXT!

	* In random play mode let's just select the next random
	* module instead of going through the subsongs.
	cmp.b	#pm_random,playmode(a5)	
	beq.b	.nosongs
	
	move.l	playerbase(a5),a0	
	move	p_liput(a0),d1		
	btst	#pb_song,d1
	beq.b	.nosongs
	move	songnumber(a5),d0
	cmp	maxsongs(a5),d0
	beq.b	.nosongs
	move	#$4e,rawkeyinput(a5)	* next song
.nosongs

	move.b	rawKeySignal(a5),d1
	bsr.w	signalit
	pop	d0
.ok0


	move.b	earlyload(a5),d1
	beq.b	.noerl
	tst.b	playing(a5)
	beq.b	.noerl

	tst.b	do_early(a5)		* joko oli p‰‰ll‰?
	bne.b	.noerl

	move	pos_maksimi(a5),d2
	sub	pos_nykyinen(a5),d2
	cmp.b	d1,d2
	bhi.b	.noerl

	st	do_early(a5)
	move	#$28,rawkeyinput(a5)
	move.b	rawKeySignal(a5),d1
	pushm	all
	bsr.w	signalit
	popm	all
.noerl



	cmp.l	#99*60*50,d0		* onko aika 99:59?
	blo.b	.ok
	bsr.w	settimestart
	moveq	#0,d0
.ok

	divu	#50,d0
	ext.l	d0
	divu	#60,d0
	swap	d0
	moveq	#0,d1
	move	d0,d1
	clr	d0
	swap	d0

	bsr.w	logo
	divu	#10,d0
	add.b	#'0',d0
	move.b	d0,(a0)+
	swap	d0
	add.b	#'0',d0
	move.b	d0,(a0)+
	move.b	#':',(a0)+

	divu	#10,d1
	add.b	#'0',d1
	move.b	d1,(a0)+
	swap	d1
	add.b	#'0',d1
	move.b	d1,(a0)+

******
	cmp	#pt_sample,playertype(a5)
	beq.b	.koa
	cmp	#pt_prot,playertype(a5)
	bne.b	.oai
.koa	cmp	#3,lootamoodi(a5)
	bne.b	.oai
	

	move.b	#'/',(a0)+
	tst.l	kokonaisaika(a5)
	bne.b	.aik
	move.b	#'-',(a0)+
	move.b	#'-',(a0)+
	move.b	#':',(a0)+
	move.b	#'-',(a0)+
	move.b	#'-',(a0)+
	bra.b	.oai
.aik

	moveq	#0,d0
	move	kokonaisaika(a5),d0
	divu	#10,d0
	add.b	#'0',d0
	move.b	d0,(a0)+
	swap	d0
	add.b	#'0',d0
	move.b	d0,(a0)+
	move.b	#':',(a0)+

	moveq	#0,d1
	move	kokonaisaika+2(a5),d1
	divu	#10,d1
	add.b	#'0',d1
	move.b	d1,(a0)+
	swap	d1
	add.b	#'0',d1
	move.b	d1,(a0)+
.oai

*****
	tst.l	playingmodule(a5)
	bmi.w	.jaa

	move.l	playerbase(a5),a1
	move	p_liput(a1),d0
	btst	#pb_poslen,d0
	beq.b	.lootaan_song

	move.b	#" ",(a0)+
.lootaan_pos
	move	pos_nykyinen(a5),d0
	bsr.w	putnumber
	move.b	#'/',(a0)+
	move	pos_maksimi(a5),d0
	bsr.w	putnumber


.lootaan_song
	move.l	playerbase(a5),a1
	move	p_liput(a1),d0
	btst	#pb_song,d0
	beq.b	.jaa

	cmp	#pt_prot,playertype(a5)
	bne.b	.pot
	cmp	#3,lootamoodi(a5)
	beq.b	.jaa
.pot


	move	songnumber(a5),d0
	addq	#1,d0
	sub	minsong(a5),d0

	move.b	#' ',(a0)+
	move.b	#'#',(a0)+
	bsr.w	putnumber

	cmp	#pt_prot,playertype(a5)		* ei maxsongeja
	bne.b	.nptr
	cmp.b	#$ff,ptsonglist+1(a5)	* onko enemm‰n kuin yksi songi??
	bne.b	.nptr
.ql	cmp.b	#'#',-(a0)		* jos vain yksi, ei songnumberia!
	bne.b	.ql
	bra.b	.jaa
.nptr
	move.b	#"/",(a0)+
	moveq	#0,d0
	move	maxsongs(a5),d0
	addq	#1,d0
	sub		minsong(a5),d0
	bsr.w	putnumber
.jaa	

;	tst.b	uusikick(a5)	
;	beq.b	.eisitten

;	cmp.b	#' ',-1(a0)
;	beq.b	.piz
;	move.b	#' ',(a0)+		* tungetaan aina modnimi v‰liin
;.piz	lea	modulename(a5),a1
;	moveq	#40-1,d0
;.he	move.b	(a1)+,(a0)+
;	dbeq	d0,.he

;.eisitten	* vanhalla kickill‰ ei, koska se sotkee gadgetit jos liian pitk‰
		* uudella tulee errori amigaguidella scrollailtaessa jos
		* teksti menee reunuksen yli.. kai. 
		

	clr.b	(a0)
	bra.w	lootaus




lootaan_kello
	cmp	#1,lootamoodi(a5)
	beq.b	.ook
	rts
.ook
	pushm	all
	moveq	#0,d7

	lea	-16(sp),sp
	move.l	sp,d1
	lore	Dos,DateStamp
	move.l	4(sp),d1
	lea	16(sp),sp
	cmp	#1,lootassa(a5)
	bne.b	.erp
	cmp	vanhaaika(a5),d1
	bne.b	.erp
	addq	#1,d7

.erp	move	#1,lootassa(a5)

	move	d1,vanhaaika(a5)
	divu	#60,d1			* tunnit/minuutit
	move.l	d1,d2

	move	d1,d3
	lsl	#8,d3			* d3 = alarm-vertaus


	lea	-10(sp),sp
	move.l	sp,a0
	move	d1,d0
	bsr.w	putnumber2
	move.b	#":",(a0)+
	move.l	d2,d0
	swap	d0
	add	d0,d3
	bsr.w	putnumber2
	clr.b	(a0)
	move.l	sp,a3

	cmp.b	#2,do_alarm(a5)
	beq.b	.noal
	cmp	alarm(a5),d3
	bne.b	.noal
	addq.b	#1,do_alarm(a5)
.noal


	moveq	#MEMF_CHIP,d1
	lore	Exec,AvailMem
	move.l	d0,d4
	moveq	#MEMF_FAST,d1
	lob	AvailMem
	move.l	d0,d5

	moveq	#10,d1
	lsr.l	d1,d4
	lsr.l	d1,d5
	
	cmp	oldchip(a5),d4
	bne.b	.new
	cmp	oldfast(a5),d5
	bne.b	.new
	addq	#1,d7
.new
	move	d4,oldchip(a5)
	move	d5,oldfast(a5)

	cmp	#2,d7
	bne.b	.pr
	lea	10(sp),sp
	bra.w	xloota
.pr

	move.l	a3,d0
	moveq	#0,d1
	moveq	#0,d2
	move	d4,d1
	move	d5,d2
	lea	.form(pc),a0
	bsr.w	desmsg
	lea	10(sp),sp

	bra.b	lootaus

.form	dc.b	"HiP %s c%ld f%ld",0
 even

lootaan_nimi
	cmp	#2,lootamoodi(a5)
	beq.b	.ook
	rts
.ook
	pushm	all
	clr.b	do_alarm(a5)		* sammutetaan her‰tys
	move	#2,lootassa(a5)

	bsr.b	logo
	lea	modulename(a5),a1
	moveq	#INFO_MODULE_NAME_LEN-1,d0
.he	move.b	(a1)+,(a0)+
	dbeq	d0,.he
	clr.b	(a0)

lootaus

* Tulostetaan vain jos on muuttunut!

	lea	desbuf(a5),a0
	lea	wintitl(a5),a2
	move.l	a2,a1
.c	move.b	(a0)+,(a2)+
	bne.b	.c

	lea	wintitl2(a5),a0
	move.l	a1,a2

.fpel	move.b	(a0)+,d1
	move.b	(a2)+,d0
	beq.b	.e
	cmp.b	d0,d1
	bne.b	.jep
	bra.b	.fpel
.e	tst.b	d1
	beq.b	xloota

.jep	lea	wintitl2(a5),a0
	move.l	a1,a2
.poa	move.b	(a2)+,(a0)+
	bne.b	.poa

	tst.b	win(a5)
	beq.b	xloota
	move.l	windowbase(a5),a0
	lea	-1.w,a2			* Screentitle (ei ole)
	lore	Intui,SetWindowTitles

xloota	popm	all
	rts	


* titleen mahtuu 23 kirjainta 8*8 fontilla.

;wintitl ds.b	80
;wintitl2 ds.b	80

logo	lea	desbuf(a5),a0
	rts
;	lea	.hip(pc),a1
;.c	move.b	(a1)+,(a0)+
;	bne.b	.c
;	move.b	#' ',-1(a0)
;	rts
;.hip	dc.b	"HiP ",0
; even

* a0 = mihink‰ laitetaan
* d0 = luku joka k‰‰nnet‰‰n ASCIIksi
putnumber2
	st	d1
	bra.b	putnu
putnumber
	moveq	#0,d1
putnu	ext.l	d0
	divu	#100,d0
	beq.b	.e
	or.b	#'0',d0
	move.b	d0,(a0)+
	st	d1
.e
	clr	d0
	swap	d0
	divu	#10,d0
	bne.b	.b
	tst	d1
	beq.b	.c

.b	or.b	#'0',d0
	move.b	d0,(a0)+

.c	swap	d0
	or.b	#'0',d0
	move.b	d0,(a0)+
	rts


*******************************************************************************
* Hiiren nappuloita painettu, tutkitaan oliko tiedostojen p‰‰ll‰
* ja pistet‰‰n palkki
*******

* Out:
*   d0 = zero if no files hit under mouse, 1 otherwise
*   d1 = Index of selected file
getFileBoxIndexFromMousePosition:
	tst	boxsize(a5)
	beq.w	.out

	move	mousex(a5),d0
	move	mousey(a5),d1
	sub	windowleft(a5),d0
	sub	windowtop(a5),d1	* suhteutus fonttiin

	* Vertical modifier when big buttons used
	moveq	#0,d3
	tst.b	altbuttonsUse(a5)
	beq.b	.noAlt0
	moveq	#16,d3
.noAlt0

	cmp	#30+WINX,d0		* onko tiedostolistan p‰‰ll‰?
	blo.b	.out

	; Left edge value
	move	WINSIZX(a5),d2
	sub	#9,d2
	;cmp	#251+WINX,d0
	cmp	d2,d0
	bhi.b	.out
	
	moveq	#63+WINY,d2		* Top edge
	add	d3,d2			* Modifier!
	cmp	d2,d1
;	cmp	#63+WINY,d1
	blo.b	.out

	move	#126+WINY,d2		* Bottom edge
	add	d3,d2			* Modifier!
	add	boxy(a5),d2		* Height of box
	cmp	d2,d1
	bhi.b	.out

	* converts y-koordinate into a line number (font is 8 pix tall)
	sub	#63+WINY,d1
	sub	d3,d1

 if DEBUG
 	push	d1
 	moveq	#0,d0
 	move	d1,d0
 	moveq	#0,d1
	move	mousey(a5),d1
 	DPRINT	"hit %ld mouseY=%ld"
 	pop	d1
 endif

; hit 44 -> line 5
; hit 58 -> line 7
;     81 ->      11

	* round up?
	;move	listFontHeight(a5),d0
	;lsr	#1,d0
	;add	d0,d1

	;lsr	#3,d1	
	ext.l	d1
	divu	listFontHeight(a5),d1

 if DEBUG
 	moveq	#0,d0
 	move	d1,d0
 	DPRINT	"line %ld"
 endif

	moveq	#1,d0			* success
	rts
.out  
	* nothing marked
	moveq	#0,d0 
	rts


* Calculates chosenmodule, which is an index of the selected item.
* Chosen line is highlighted and previously chosen line highlight removed.

markline:
	bsr.w getFileBoxIndexFromMousePosition
	beq.b  .out
	bsr.b	.doMark
	* something marked
	moveq	#1,d0
	rts
.out  
	* nothing marked
	moveq	#0,d0 
	rts

* filebox line number in d1
.doMark

	* list is empty
	; this may allow doubleclicking of empty list to open file req
	tst.l	modamount(a5)
	bne.b	.ona
	moveq	#0,d1		* ei oo modeja, otetaan eka
.ona
	ext.l	d1
	move.l	d1,d2
	add.l	firstname(a5),d1
	* See if clicking on an already chosen module
	cmp.l	chosenmodule(a5),d1
	beq.b	.oo
	* This does not seem to happen ever?
	cmp.l	#PLAYING_MODULE_REMOVED,chosenmodule(a5)
	beq.b	.oo2
	pushm	d1/d2
	bsr.b	unmarkit
	popm	d1/d2
.u	st	dontmark(a5)
.oo2	
.oo
.continue
	move.l	d1,chosenmodule(a5)
	move.l	d2,markedline(a5)

	move.l	clickmodule(a5),d3
	move.l	d1,clickmodule(a5)

	* double click test
	cmp.l	d1,d3
	bne.b	.nodouble
	move.l	#-1,clickmodule(a5)	

	subq.l	#8,sp
	lea	(sp),a0
	lea	4(sp),a1
	lore	Intui,CurrentTime
	movem.l	(sp)+,d2/d3
	movem.l	clicksecs(a5),d0/d1
	lob	DoubleClick
	tst.l	d0
	beq.b	.double
* Tiedostoa doubleclickattu! Soitetaan...
* Double click detected
	tst.b	doubleclick(a5)		* onko sallittua?
	bne.w	rbutton1		* Play!
	rts

.nodouble
	lea	clicksecs(a5),a0	* klikin aika talteen
	lea	clickmicros(a5),a1
	lore	Intui,CurrentTime
.double
	bsr.w	showNamesNoCentering
	bsr.w	reslider
	rts

* Highlight line by xorring/complementing it
* Highlight is cleared by doing the same operation again on the same line.
unmarkit			* pyyhitaan merkkaus pois
markit
	move.l	chosenmodule(a5),d0

	* Bounds check
	cmp.l	modamount(a5),d0
	bhs.b	.outside

	move.l	markedline(a5),d5
	bmi.b	.outside
	moveq	#0,d0
	move	boxsize(a5),d0
	cmp.l	d0,d5
	bhs.b	.outside
	tst.b	win(a5)
	beq.b	.outside

; TODO: this probably prevents clicking on empty parts of the list
;       to highlight lines
	; Why is the above done? remove?
;	move.l	d5,d1
;	bsr.w	 obtainModuleList
;	lea	moduleListHeader(a5),a4	
;	move.l	chosenmodule(a5),d0	* etsit‰‰n kohta
;.luuppo
	* a4=current node
	* a3=next node
	* test if at end
;	TSTNODE	a4,a3
;	beq.b	.nomods
;	move.l	a3,a4
;	;dbf	d0,.luuppo
;	subq.l #1,d0 
;	bpl.b  .luuppo

	move	d5,d1
	;lsl	#3,d1		* mulu #8,d1
	mulu	listFontHeight(a5),d1
	add	#63+WINY,d1
	tst.b	altbuttonsUse(a5)
	beq.b	.noAlt1
	add	#16,d1
.noAlt1
	moveq	#33+WINX,d0 
	add	windowleft(a5),d0
	add	windowtop(a5),d1
	move	d0,d2
	move	d1,d3
;	move	#216,d4
	move	WINSIZX(a5),d4
	sub	#264-216-1,d4

	;moveq	#8,d5
	move	listFontHeight(a5),d5
	moveq	#$50,d6		* EOR
	
	move.l	rastport(a5),a1
	move.b	rp_Mask(a1),d7
	move.b	#%11,rp_Mask(a1)	* K‰sitell‰‰n kahta alinta bittitasoa.
	move.l	a1,a0
	lore	GFX,ClipBlit

	move.l	rastport(a5),a1
	move.b	d7,rp_Mask(a1)

.nomods
;	bsr.w	 releaseModuleList

.outside	
	rts

marklineRightMouseButton
	* Check if feature is enabled in prefs
	tst.b	favorites(a5)
	beq.b	.out
	bsr.w	 getFileBoxIndexFromMousePosition
	beq.b  .out
	* RMB was hit on top of the list.
	* In fav list ignore the click.
	cmp.b 	#LISTMODE_FAVORITES,listMode(a5)
	beq.b	.ou
	bsr.b	.doMark
	* something marked
.ou	moveq	#1,d0
	rts
.out  
	* nothing marked
	moveq	#0,d0 
	rts

.doMark
	moveq	#0,d0
	move	d1,d0
	move.l	d0,d3
	DPRINT	"RMB mark on line %ld"

	* To get node index add index of the first visible
	* item
	add.l	firstname(a5),d0
	move.l	d0,d4

	* Toggle for node at index d0
	bsr.w	toggleFavoriteStatus
	beq.b	.failed

	move.l	d4,d0
	* d0 contains the node index
	move	d3,d1 	* target y-line
	moveq	#1,d2   * just do one line
	push 	d3
	bsr.w	doPrintNames
	pop 	d3

	* see if this line happened to be chosen already.
	* in this case the highlight should be restored as it was just
	* wiped away above.
	cmp.l	 markedline(a5),d3	
	bne.b	.different
	bsr.w	markit
.different
	rts	
.notFile
.failed
	DPRINT	"Not favoriting this line"
	rts


*******************************************************************************
*** SECTION *******************************************************************
*
* List node utilities
*
*******************************************************************************


* Gets the chosen module list element 
* Out:
*    d0 = 0 if not found
*    d0 = 1 if data available
*    a3 = list node pointer
*** Chosenmodule node A3:een
getcurrent:
	tst.l	modamount(a5)
	beq.b	.q
	move.l	chosenmodule(a5),d0
	bpl.b	getcurrent2
.q	moveq	#0,d0
	rts

* Gets the chosen module list element into a3
* In:
*   d0 = Module index
* Out:
*    d0 = 0 if not found
*    d0 = 1 if data available
*    a3 = list node pointer
getcurrent2:
	bsr.b getListNode
	move.l	a0,a3
	rts


* Gets the list header that corresponds to the current list mode,
* either normal, or favorites list, or filebrowser list.
* Out:
*  a0 = list header address
getVisibleModuleListHeader:
	cmp.b 	#LISTMODE_FAVORITES,listMode(a5)
	beq.b	.isFav
	cmp.b	 #LISTMODE_BROWSER,listMode(a5)
	beq.b	.isBrowser
	lea	moduleListHeader(a5),a0
	rts
.isFav
	lea	favoriteListHeader(a5),a0
	rts
.isBrowser
	lea	fileBrowserListHeader(a5),a0
	rts
	

* When an element is moved, added, inserted, deleted,
* random bookkeeping must be reset,
* and cached node as well. They would otherwise
* no longer represent the list state correctly.
* Also set a flag, this is used to detect chnages in favorites
* content.
* In file browser mode contents can NOT be changed.

listChanged:
	DPRINT "List changed"
	bsr.w	clearCachedNode
	bsr.w	clear_random	
	cmp.b	#LISTMODE_BROWSER,listMode(a5)
	beq.b	.browser
	st	moduleListChanged(a5)
.browser
	rts

; TODO: list traversal end check should not be needed,
; unless for some reason listamount and list ocntents are
; not in sync

* Node getter
* in:
*   d0=index, 32-bit
* out:
*   a0=list node
*   Z=set if index is out of bounds
getListNode:
	DPRINT	"getListNode %ld"

	tst.l	modamount(a5)
	beq.b	.out
	cmp.l 	modamount(a5),d0
	bhs.b	.out

	bsr.w	obtainModuleList
	;lea	moduleListHeader(a5),a0
	bsr.b	getVisibleModuleListHeader

	move.l	a0,d1	* Sanity check
	beq.b	.out

	* When using dbf loop usually subtract 1, but here
	* one SUCC is needed to get to the head element
	* so don't subtract
	move.l	d0,d1
	swap	d0
.loop
	SUCC    a0,a0
	dbf	d1,.loop
	dbf	d0,.loop
	bsr.w	releaseModuleList

 if DEBUG
 	move.l	l_nameaddr(a0),d0
	DPRINT	"->found=%s"
 endc
	moveq	#1,d0 	* found
	rts
.out
	moveq	#0,d0
	rts



* Cached list node getter
* in:
*   d0 = index
* out:
*   a0 = list node
*   Z-flag = set if error (out of bounds), not set if ok
getListNodeCached

* algo (not actually used here):
* - if index is nearer head than cached node
*   - use head as cached reference node
* - else if index is nearer tail than cached node
*   - use tail as cached reference node
* - else
*   - use cached node as reference node

	tst.l	modamount(a5)
	beq.b	.out
	cmp.l 	modamount(a5),d0
	bhs.b	.out

	tst.l	cachedNode(a5)
	bne.b	.n
	* Get head node from the minimal list header
	bsr.w	getVisibleModuleListHeader
	move.l	MLH_HEAD(a0),cachedNode(a5)
	;move.l	moduleListHeader+MLH_HEAD(a5),cachedNode(a5)
	clr.l	cachedNodeIndex(a5)
.n
	move.l	cachedNodeIndex(a5),d1
	* New cached index
	move.l	d0,cachedNodeIndex(a5)
	;DPRINT	"Getlistnode to=%ld cached=%ld"
	move.l	cachedNode(a5),a0

	* See if cached is the same as requested:
	sub.l	d1,d0
	beq.b   .x
	bpl.b  	.forward2
	bra.b	.backward2

.x	* Same, just return
	moveq	#1,d0
	rts
.out
	moveq	#0,d0 * error
	rts

; These allow jump to be over 16 bits
.backward2 
	neg.l 	d0
	subq.l	#1,d0
	move.l	d0,d1
	swap 	d0
.bloop
	PRED   	a0,a0
	dbf 	d1,.bloop 
	dbf	d0,.bloop
	move.l 	a0,cachedNode(a5)
	rts 

.forward2
	subq.l	#1,d0
	move.l	d0,d1
	swap 	d0
.floop
	SUCC    a0,a0
	dbf 	d1,.floop 
	dbf	d0,.floop
	move.l 	a0,cachedNode(a5)
	rts

clearCachedNode
	clr.l	cachedNode(a5)	
	rts

*******************************************************************************
*** SECTION *******************************************************************
*
* Tooltip popup
*
*******************************************************************************

* in: 
*   a0=structure of
*       dc.b <width in characters>
*       dc.b <height in characters>
*       dc.b "string",0
showTooltipPopup

.wflags = WFLG_SIMPLE_REFRESH!WFLG_BORDERLESS
.idcmpflags = 0

	pushm	all
	move.l	a0,a4

	* where is the mouse?
	move	mousex(a5),d6 
	move	mousey(a5),d7

	move.l	windowbase(a5),a0	* main window
	add	wd_LeftEdge(a0),d6	* relative mouse position
	add	wd_TopEdge(a0),d7

	lea	.tooltipPopup(pc),a0		

	* set width based from given parameters
	* which provide width and height in chars
	moveq	#0,d5
	move.b	(a4),d5
	mulu	#8,d5
	add	#16,d5
	move	d5,nw_Width(a0)

	* center horizontally around the pointer
	lsr	#1,d5
	sub	d5,d6
	bpl.b	.oe
	moveq	#0,d6
.oe	move	d6,nw_LeftEdge(a0)

	* height
	moveq	#0,d5
	move.b	1(a4),d5
	mulu	#8,d5
	addq	#7,d5
	move	d5,nw_Height(a0)

	* place above pointer a bit
	sub	d5,d7
	subq	#8,d7
	move	d7,nw_TopEdge(a0)

	* see if it fits on screen and adjust
	bsr.w	tark_mahtu

	lore	Intui,OpenWindow
	move.l	d0,d5
	beq.w	.x
	DPRINT	"Tooltip opened %lx"
	move.l	d0,a0
	move.l	wd_RPort(a0),d7		* rastport
	move.l	a0,tooltipPopupWindow(a5)

	* set pens and font
	move.l	d7,a1
	move.l	pen_1(a5),d0
	lore	GFX,SetAPen
	move.l	d7,a1
	move.l	pen_0(a5),d0
	lob	SetBPen
	move.l	d7,a1
	move.l	fontbase(a5),a0
	lob	SetFont	

	moveq	#0,d4
	move.b	(a4)+,d4	* max leveys
	lsl	#3,d4

	moveq	#0,d5
	move.b	(a4)+,d5	* vaakarivej‰
	subq	#1,d5
	move.l	a4,a0

	* initial y-coordinate for the rows
	moveq	#10,d3
.prl	
	move	d3,d1
	moveq	#8,d0	* x-coord
	bsr.b	.print
	* next y
	addq	#8,d3
	* find next line
.eol
	tst.b 	(a0)+
	bne.b	.eol
	dbf	d5,.prl

	* d7 = rastport
	* draw a bordaer
	move.l	d7,a1
	lea	.tooltipPopup(pc),a0
	moveq	#0,plx1
	move	nw_Width(a0),plx2
	moveq	#0,ply1
	move	nw_Height(a0),ply2
	subq	#1,ply2
	subq	#1,plx2
	bsr.w	laatikko1
.x
	popm	all
	rts


.print	pushm	all
	move.l	d7,a4
	jmp	doPrint

* Tooltip window structure
.tooltipPopup
	dc	0,0	* paikka 
	dc	0,0	* koko
	dc.b	0,0	;palkin v‰rit
	dc.l	.idcmpflags
	dc.l	.wflags
	dc.l	0
	dc.l	0	
	dc.l	0	; title
	dc.l	0
	dc.l	0	
	dc	0,0	 * min x,y
	dc	1000,1000 * max x,y
	dc	WBENCHSCREEN
	dc.l	enw_tags

* Closes the tooltip popup if open.
* Also deactivates any tooltip that is about to open.
closeTooltipPopup
	pushm	all
	bsr.w	deactivateTooltip
	move.l	tooltipPopupWindow(a5),d0
	beq.b	.exit
	move.l	d0,a0
	bsr.b	flushWindowMessages
	move.l	tooltipPopupWindow(a5),a0
	lore	Intui,CloseWindow
	clr.l	tooltipPopupWindow(a5)
.exit 	
	popm	all
	rts


* Flush the window message queue. This should be done before closing window.
* This way the message sender can free the message data, if it was dynamically created.
* in:
*   a0 = intuition window
flushWindowMessages
	pushm 	d2/a6
	move.l	a0,d2
	bne.b	.loop
.exit
	popm    d2/a6
	rts
.loop
	move.l	d2,a0
	* Window may not have a user port, eg. if no IDCMP set 	
	move.l	wd_UserPort(a0),d0
	beq.b	.exit
	move.l	d0,a0
	lore	Exec,GetMsg
	tst.l	d0
	beq.b	.exit
	move.l	d0,a1
	lob	ReplyMsg
	bra.b	.loop


*******************************************************************************
* Lataa keyfilen
*******

loadkeyfile
	pushm	all
	move.l	_DosBase(a5),a6
	pushpea	keyfilename(pc),d1
	moveq	#_LVOOpen*4,d0
	move.l	#400,-(sp)
	add.l	#605,(sp)
	pop	d2
	bsr.b	.nixi	
	move.l	d0,d4
	beq.b	.error

	move.l	d4,d1
	pushpea	keyfile(a5),d2
	moveq	#64,d3
	lob	Read

	move.l	d4,d1
	lob	Close	

.error
	popm	all
	rts


.nixi	asr.l	#2,d0
	jsr	(a6,d0)
	rts



*******************************************************************************
*** SECTION *******************************************************************
*
* Info window
* - module info
* - about info
*
*******************************************************************************

sulje_foo
	cmp	#33,info_prosessi(a5)
	shs	oli_infoa(a5)
	rts

*** Sulkee module infon
sulje_info:
	cmp	#33,info_prosessi(a5)
	bhs.b	.joo
	clr.b	oli_infoa(a5)
	rts

.joo	
	pushm	d0/d1/a0/a1/a6
	move.l	info_task(a5),a1
	moveq	#0,d0
	move.b	info_signal(a5),d1
	bset	d1,d0
	lore	Exec,Signal	

.t	tst	info_prosessi(a5)	* odotellaan
	beq.b	.tt
	jsr	dela
	bra.b	.t
.tt
	popm	d0/d1/a0/a1/a6
	rts


	
start_info
	tst.b	oli_infoa(a5)
	bne.b	.j
	tst	info_prosessi(a5)
	beq.b	.x
.j
	tst	info_prosessi(a5)
	beq.b	rbutton10b
	move.l	info_task(a5),a1		* P‰ivityspyyntˆ!
	moveq	#0,d0
	move.b	info_signal2(a5),d1
	bset	d1,d0
	move.l	(a5),a6
	jmp	_LVOSignal(a6)


.x	clr.b	oli_infoa(a5)
	rts

infoWindowButtonAction
rbutton10b
	tst	info_prosessi(a5)
	bne.b	sulje_info

	movem.l	d0-a6,-(sp)
	move.l	_DosBase(a5),a6
	move.l	#infoprocname,d1
	move.l	priority(a5),d2

	move.l	#info_segment,d3
	lsr.l	#2,d3
	move.l	#4000,d4
	lob	CreateProc
	tst.l	d0
	beq.b	.n
	addq	#1,info_prosessi(a5)
.n	movem.l	(sp)+,d0-a6
.x	rts

info_code
	lea	var_b,a5
	addq	#1,info_prosessi(a5)

	sub.l	a1,a1
	lore	Exec,FindTask
	move.l	d0,info_task(a5)

	moveq	#-1,d0
	lob	AllocSignal
	move.b	d0,info_signal(a5)
	moveq	#-1,d0
	lob	AllocSignal
	move.b	d0,info_signal2(a5)

	bsr.b	.infocode

	move.b	info_signal(a5),d0
	jsr	freesignal
	move.b	info_signal2(a5),d0
	jsr	freesignal

	lore	Exec,Forbid
	clr	info_prosessi(a5)
	rts


************* Module info
.infocode

*** Avataan ikkuna
* 39 kirjainta mahtuu laatikkoon
* Linefeedi ILF joka myˆhemmin korvataan 10:ll‰. Sit‰varten ett‰ voidaan
* karsia ylim‰‰r‰set linefeedit pois.

ILF	=	$83
ILF2	=	$03

swflags set WFLG_SMART_REFRESH!WFLG_NOCAREREFRESH!WFLG_DRAGBAR
swflags set swflags!WFLG_CLOSEGADGET!WFLG_DEPTHGADGET!WFLG_RMBTRAP
sidcmpflags set IDCMP_CLOSEWINDOW!IDCMP_GADGETUP!IDCMP_MOUSEMOVE!IDCMP_RAWKEY
sidcmpflags set sidcmpflags!IDCMP_MOUSEBUTTONS!IDCMP_NEWSIZE
sidcmpflags set sidcmpflags!IDCMP_ACTIVEWINDOW!IDCMP_INACTIVEWINDOW


	tst.b	gotscreeninfo(a5)
	bne.b	.joo
	jsr	getscreeninfo
.joo

	lea	swinstruc,a0
	basereg swinstruc,a0
	move	nw_Height+swinstruc(a0),oldswinsiz(a5)
	move	gg_Height+gAD1(a0),oldsgadsiz(a5)

	move	infosize(a5),d0
	subq	#3,d0
	lsl	#3,d0
	add	d0,nw_Height+swinstruc(a0)
	add	d0,gg_Height+gAD1(a0)
	endb	a0

	; Set window size limits
	; Max height 50 lines
	move	oldswinsiz(a5),d0
	move	d0,nw_MinHeight(a0)
	add	#(50-3)*8,d0
	move	d0,nw_MaxHeight(a0)

	; fit into the screen
	
	move	wbkorkeus(a5),d2
.lo	cmp	nw_Height(a0),d2
	bhi.b	.fine
	
	clr	nw_TopEdge(a0)		* sijoitetaan mahd. ylˆs
	subq	#1,infosize(a5)
	subq	#8,nw_Height(a0)

	move	infosize(a5),d0
	subq	#3,d0
	lsl	#3,d0
	add	oldsgadsiz(a5),d0
	move	d0,gg_Height+gAD1
	bra.b	.lo

.fine
	move.l	infopos2(a5),(a0)
	bsr.w	tark_mahtu

	move.l	a0,a2
	basereg swinstruc,a2

	move	#7,slim2height(a2)
	
	lore	Intui,OpenWindow
	move.l	d0,swindowbase(a5)

	and.l	#~WFLG_ACTIVATE,sflags(a2) * clearataan active-flaggi
	move	d7,swinstruc+nw_Height(a2)
	endb	a2

	tst.l	d0
	bne.b	.koo
	lea	windowerr_t(pc),a1
	bsr.w	request
	bra.w	.sexit
.koo

	move.l	d0,a0
	move.l	wd_RPort(a0),srastport(a5)
	move.l	wd_UserPort(a0),suserport(a5)

	move.l	srastport(a5),a1
	move.l	fontbase(a5),a0
	lore	GFX,SetFont	
	
	move.l	swindowbase(a5),a0
	jsr	setscrtitle

	; Reset slider position
	lea	gAD1,a0
	move.l	gg_SpecialInfo(a0),a1
	move	pi_Flags(a1),d0
	move.l	swindowbase(a5),a1
	sub.l	a2,a2
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	lore	Intui,ModifyProp

.redraw
	DPRINT	"Info redraw"
	move.l	srastport(a5),a2
	moveq	#4,d0
	moveq	#11,d1
	move	#356-5-2+2,d2
	moveq	#147-13*8-2,d3
	move	infosize(a5),d4
	subq	#3,d4
	lsl	#3,d4
	add	d4,d3
	bsr.w	drawtexture

	; set slider height
	move	infosize(a5),d0
	subq	#3,d0
	lsl	#3,d0
	add	oldsgadsiz(a5),d0
	;move	d0,gg_Height+gAD1

	lea	gAD1,a3
	move	d0,gg_Height(a3)

	movem	4(a3),plx1/ply1/plx2/ply2	* slider
	add	plx1,plx2
	add	ply1,ply2
	subq	#2,plx1
	addq	#1,plx2
	subq	#2,ply1
	addq	#1,ply2
	move.l	srastport(a5),a1
	bsr.w	sliderlaatikko

.reprint

	moveq	#29,plx1
	move	#351-3,plx2
	moveq	#13,ply1
	moveq	#143-13*8,ply2
	move	infosize(a5),d0
	subq	#3,d0
	lsl	#3,d0
	add	d0,ply2
	add	windowleft(a5),plx1
	add	windowleft(a5),plx2
	add	windowtop(a5),ply1
	add	windowtop(a5),ply2
	move.l	srastport(a5),a1

	* Select box frame depending on if info or about window
	lea	laatikko2(pc),a0
	tst.b	infolag(a5)
	bne.b	.a
	cmp	#pt_prot,playertype(a5)
	bne.b	.a
	lea	laatikko1(pc),a0
.a	jsr	(a0)

	moveq	#31-2+2,d0		* tyhjennet‰‰n
	moveq	#15-1,d1
	move	#350-31-5+2,d4
	moveq	#144-15-13*8,d5
	move	infosize(a5),d6
	subq	#3,d6
	lsl	#3,d6
	add	d6,d5
	add	windowleft(a5),d0
	add	windowtop(a5),d1
	move.l	srastport(a5),a0
	move.l	a0,a1
	move	d0,d2
	move	d1,d3
	moveq	#$0a,d6
	lore	GFX,ClipBlit
	st	skokonaan(a5)

	jsr	obtainModuleData
	bsr	.prepareInfoWindowContent
	jsr	releaseModuleData
	; check if got data
	tst.l	infotaz(a5)
	beq.w	.sexit


	clr	riviamount(a5)
	move.l	infotaz(a5),a0
.fii	tst.b	(a0)
	beq.b	.kii
	cmp.b	#10,(a0)+
	bne.b	.fii
	addq	#1,riviamount(a5)
	bra.b	.fii
.kii

	bsr.w	.print

	clr	sfirstname(a5)
	bsr.w	.reslider
	bsr	.refreshInfoWindowResizeGadget

*** Info window message loop
.SKIP
	DPRINT	"info msg loop"
	bra.b	.msgLoop
.returnmsg
	bsr.w	.flush_messages
.msgLoop
	moveq	#0,d0			* viestisilmukka
	moveq	#0,d1
	move.l	suserport(a5),a4
	move.b	MP_SIGBIT(a4),d1	* signalibitti
	bset	d1,d0
	move.b	info_signal(a5),d1
	bset	d1,d0
	move.b	info_signal2(a5),d1
	bset	d1,d0
	lore	Exec,Wait

	; exit signal?
	move.b	info_signal(a5),d1
	btst	d1,d0
	bne.w	.sexit
	; content refresh signal?
	move.b	info_signal2(a5),d1
	btst	d1,d0
	beq.b	.noRefresh
	* refresh content signal
	bsr.w	.flush_messages
	bsr.w	.fraz
	bra.w	.reprint
.noRefresh

.idcmpLoop	
	move.l	a4,a0
	lore	Exec,GetMsg
	tst.l	d0
	beq.b	.msgLoop

	move.l	d0,a1
	move.l	im_Class(a1),d2		* luokka	
	move	im_Code(a1),d3		* koodi
	move.l	im_IAddress(a1),a2 	* gadgetin tai olion osoite
	move	im_Qualifier(a1),d4	* RAWKEY: IEQUALIFIER_?
	move	im_MouseX(a1),d5
	move	im_MouseY(a1),d6

	lob	ReplyMsg

	cmp.l	#IDCMP_ACTIVEWINDOW,d2
	bne.b	.noActive
	bsr.w	.refreshInfoWindowResizeGadget
	bra.b	.idcmpLoop

.noActive
	cmp.l	#IDCMP_INACTIVEWINDOW,d2
	bne.b	.noInactive
	bsr.w	.refreshInfoWindowResizeGadget
	bra.b	.idcmpLoop
	
.noInactive
	;cmp.l	#IDCMP_NEWSIZE,d2
	moveq	#IDCMP_NEWSIZE,d0
	cmp.l	d0,d2
	bne.b	.noNewSize
	bsr	.infoWindowNewSize
	beq.b	.idcmpLoop
	bsr.w	.flush_messages
	bra.w	.redraw

.noNewSize
	cmp.l	#IDCMP_RAWKEY,d2
	bne.b	.noRawKey
	bsr	.srawkeyz
	bne.b	.sexit
	bra.b	.idcmpLoop

.noRawKey
	;cmp.l	#IDCMP_MOUSEMOVE,d2
	moveq	#IDCMP_MOUSEMOVE,d0
	cmp.l	d0,d2
	bne.b	.noMouseMove
	bsr	.smousemoving
	bra.b	.idcmpLoop

.noMouseMove
	;cmp.l	#IDCMP_MOUSEBUTTONS,d2
	moveq	#IDCMP_MOUSEBUTTONS,d0
	cmp.l	d0,d2
	bne.b	.noMouseButtons
	cmp	#SELECTDOWN,d3			* vasen
	bne.b	.noSelectDown
	bsr.w	.samplePlay
	bra.w	.idcmpLoop

.noSelectDown
	cmp	#MENUDOWN,d3			* oikea
	beq.b	.sexit

.noMouseButtons
	cmp.l	#IDCMP_CLOSEWINDOW,d2
	bne.w	.idcmpLoop
	
.sexit	
	DPRINT	"info exit"
	bsr.b	.flush_messages

	move	oldswinsiz(a5),nw_Height+swinstruc
	move	oldsgadsiz(a5),gg_Height+gAD1

	move.l	_IntuiBase(a5),a6		
	move.l	swindowbase(a5),d0
	beq.b	.uh1
	move.l	d0,a0
	move.l	4(a0),infopos2(a5) * preserve position
	lob	CloseWindow
	clr.l	swindowbase(a5)
.uh1
	bsr.b	.fraz

	;bsr.w	freeinfosample
	rts


.fraz	move.l	infotaz(a5),a0
	cmp.l	#about_t,a0
	beq.b	.fr0z
	jsr	freemem
.fr0z	clr.l	infotaz(a5)
	rts


.flush_messages
	move.l	swindowbase(a5),a0
	bra.w  flushWindowMessages
	
.reslider
	moveq	#0,d0
	move	riviamount(a5),d0
	bne.b	.xe
	moveq	#1,d0
.xe

	moveq	#0,d1
	move	infosize(a5),d1
	beq.w	.eiup
	cmp	d1,d0		* v‰h boxsize
	bhs.b	.ok
	move	d1,d0
.ok
	lsl.l	#8,d0
	bsr.w	divu_32
 	
	move.l	d0,d1
	move.l	#65535<<8,d0
	bsr.w	divu_32
	move.l	d0,d1

	lea	gAD1,a0
	basereg	gAD1,a0

	move.l	gg_SpecialInfo+gAD1(a0),a1
	cmp	pi_VertBody(a1),d1
	sne	d2
	lsl	#8,d2
	move	d1,pi_VertBody(a1)

	move	riviamount(a5),d1
	sub	infosize(a5),d1
	beq.b	.pp
	bpl.b	.p
.pp	moveq	#1,d1
.p	ext.l	d1

	move	sfirstname(a5),d0
	mulu	#65535,d0
	bsr.w	divu_32
	cmp	pi_VertPot(a1),d0
	sne	d2
	move	d0,pi_VertPot(a1)

;	tst	d2
;	beq.b	.eiup


	move	gg_Height+gAD1(a0),d0
	mulu	pi_VertBody(a1),d0
	divu	#$ffff,d0
	bne.b	.f
	moveq	#8,d0
.f
	cmp	#8,d0
	bhs.b	.zze
	moveq	#8,d0
.zze
	move	d0,slim2height(a0)
	subq	#2+1,d0
	move	d0,d1

	lea	slim2,a2
	lea	slim1a(a0),a1
	tst.b	uusikick(a5)
	bne.b	.newz
	* Select alternate gfx
	lea	slim1a_kick13-slim1a(a1),a1
.newz
	move	(a1)+,(a2)+
.filf	move	(a1),(a2)+
	dbf	d0,.filf
	addq	#2,a1
	move	(a1)+,(a2)+

	move	(a1)+,(a2)+
.fil	move	(a1),(a2)+
	dbf	d1,.fil
	move	2(a1),(a2)
.bar	
	endb	a0
	;lea	gAD1,a0
	bsr.w	.refreshInfoWindowGadget
.eiup	rts


.infoWindowNewSize
	DPRINT	"info newsize"
	move.l	swindowbase(a5),a0
	lore	Intui,RefreshWindowFrame
	bsr.w	.refreshInfoWindowResizeGadget

	move.l	swindowbase(a5),a0
 	move	wd_Height(a0),d0

	* account for bottom border
	subq	#6,d0
	sub	windowbottom(a5),d0

	* calculate new size
	moveq	#11,d1
	add	windowtop(a5),d1

	sub	d1,d0
	lsr	#3,d0
	move	infosize(a5),d3 
	move	d0,infosize(a5)

 if DEBUG
 	ext.l	d0
 	DPRINT	"size=%ld"
 endif
	* adjust window height to match infosize
	subq	#3,d0
	lsl	#3,d0
	add	oldswinsiz(a5),d0
	sub	wd_Height(a0),d0
	beq.b	.skipSize
	bmi.b	.neg
	* ensure negative change to not go over screen,
	* kick1.3 does not do sanity checks
	subq	#8,d0 * font height
.neg
 if DEBUG
 	ext.l	d0
	DPRINT	"adjust by %ld"
 endif
	move	d0,d1
	moveq	#0,d0
	lore	Intui,SizeWindow
	; restore previous infosize, await for another
	; new size event
	move	d3,infosize(a5)
	bra.b	.sizeNotChanged
.skipSize
	bsr	setPrefsInfoBox
	bsr	updateprefs
	; return 1: do refresh
	moveq	#1,d0
	rts
.sizeNotChanged
	; no refresh
	moveq	#0,d0
	rts


.refreshInfoWindowResizeGadget
	lea	gadgetResize,a0
.refreshInfoWindowGadget
	move.l	swindowbase(a5),a1
	sub.l	a2,a2
	moveq	#1,d0	
	lore	Intui,RefreshGList
	rts


.srawkeyz
* ylˆs: $4c
* alas: $4d
	cmp	#$45,d3		* ESC
	beq.b	.rawkeyExitExit

	move	infosize(a5),d0
	cmp	riviamount(a5),d0
	bhi.b	.rawkeyExit

	moveq	#1,d0
	and	#IEQUALIFIER_LSHIFT!IEQUALIFIER_RSHIFT,d4
	beq.b	.nsh
	move	infosize(a5),d0
	lsr	#1,d0
.nsh
	move	sfirstname(a5),d2

	cmp	#$4d,d3
	beq.b	.alaz
	cmp	#$4c,d3
	bne.w	.rawkeyExit

	sub	d0,sfirstname(a5)
	bpl.b	.zoo
	clr	sfirstname(a5)
	bra.b	.zoo
.alaz	
	move	sfirstname(a5),d1
	add	d0,d1
	move	riviamount(a5),d0
	sub	infosize(a5),d0
	cmp	d0,d1
	bls.b	.foop
	move	d0,d1
.foop
	move	d1,sfirstname(a5)

.zoo	
	cmp	d2,d1
	beq.b	.rawkeyExit
	bsr.w	.reslider
	bsr.b	.print
	
.rawkeyExit
	moveq	#0,d0
	rts

.rawkeyExitExit
	moveq	#1,d0
	rts

.smousemoving
	lea	gAD1,a2
	move.l	gg_SpecialInfo(a2),a0
	move	pi_VertPot(a0),d0
	cmp	ssliderold(a5),d0
	bne.b	.new
.q	rts
.new	move	d0,ssliderold(a5)


	move	riviamount(a5),d1
	sub	infosize(a5),d1
	bpl.b	.ye
	moveq	#0,d1
.ye	mulu	d1,d0
	add.l	#32767,d0
	divu	#65535,d0

	cmp	sfirstname(a5),d0
	beq.b	.q
	move	d0,sfirstname(a5)

	bsr.b	.print
	rts

.print
	tst.b	skokonaan(a5)
	beq.b	.naht
	clr.b	skokonaan(a5)

	moveq	#0,d0
.all0	moveq	#0,d1
	move	infosize(a5),d2
	bra.w	.print2

.all	move	sfirstname(a5),d0
	bra.b	.all0
	

.naht

	move	sfirstname(a5),d0
	move	sfirstname2(a5),d7
	move	d0,sfirstname2(a5)
	cmp	d0,d7
	beq.b	.xx
	sub	d0,d7
	bmi.b	.alas


.ylos	cmp	infosize(a5),d7
	bhs.b	.all


* siirrytty d7 rivi‰ ylˆsp‰in:
* kopioidaan rivit 0 -> d7 (koko: infosize-d7 r) kohtaan 0 ja printataan
* kohtaan 0 d7 kpl uusia rivej‰

	moveq	#16-1,d1		* source y

	move	d7,d3
	lsl	#3,d3
	add	#16-1,d3		* dest y

	bsr.b	.copy

	move	sfirstname(a5),d0
	moveq	#0,d1
	move	d7,d2
	bra.b	.print2



.alas	neg	d7		
	cmp	infosize(a5),d7
	bhs.b	.all

* siirrytty d7 rivi‰ alasp‰in:
* kopioidaan rivit d7 -> infosize (koko: infosize-d7 r) kohtaan 0 ja printataan
* kohtaan infosize-d7 d7 kpl uusia rivej‰

	move	d7,d1
	lsl	#3,d1
	add	#16-1,d1		* source y	
	moveq	#16-1,d3		* dest y

	bsr.b	.copy

	move	sfirstname(a5),d0
	add	infosize(a5),d0
	sub	d7,d0
	move	infosize(a5),d1
	sub	d7,d1
	move	d7,d2
	bsr.b	.print2

	
.xx
	rts

** kopioidaan 

.copy	

	move	infosize(a5),d5	* y size
	sub	d7,d5
	lsl	#3,d5

	move.b	#$c0,d6		* minterm: a->d
	moveq	#31-2,d0		* source x =
	move.l	d0,d2		* dest x
	move	#39*8+4,d4	* x size
	add	windowleft(a5),d0
	add	windowtop(a5),d1
	add	windowleft(a5),d2
	add	windowtop(a5),d3
	move.l	srastport(a5),a0
	move.l	a0,a1
	move.l	_GFXBase(a5),a6
	jmp	_LVOClipBlit(a6)



* d0 = alkurivi
* d1 = eka rivi ruudulla
* d2 = printattavien rivien m‰‰r‰
.print2
	move.l	infotaz(a5),a3
	subq	#1,d0
	bmi.b	.rr
.fle	cmp.b	#10,(a3)+
	bne.b	.fle
	dbf	d0,.fle
.rr	cmp.b	#10,-1(a3)	
	bne.b	.ra
	addq	#1,a3		* skip ILF2
.ra

	move	d1,d7
	lsl	#3,d7
	add	#22-1,d7
	
	move	d2,d6
	subq	#1,d6		* ???

.lorp
	lea	-50(sp),sp
	move.l	sp,a0
	move.l	a0,a1

	move.l	a1,d0

.lorp2	move.b	(a3)+,(a1)+
	beq.b	.xp
	
	cmp.b	#10,-1(a1)
	bne.b	.lorp2
	clr.b	-1(a1)	
	addq	#1,a3		* skipataan ILF2
.xp	subq	#1,a1

	move.l	a1,d1
	sub.l	d0,d1
	moveq	#39,d0
	sub	d1,d0
	subq	#1,d0
	bmi.b	.xo
.pe	move.b	#' ',(a1)+
	dbf	d0,.pe
	clr.b	(a1)
.xo

;	cmp.l	#"----",(a0)
;	bne.b	.xq
;	bsr.b	.palk
;	bra.b	.xw
;.xq

	moveq	#35-2,d0
	move	d7,d1
	jsr	sprint

.xw	addq	#8,d7
	lea	50(sp),sp
	tst.b	-1(a3)
	beq.b	.xip

	dbf	d6,.lorp
.xip
	rts
	

* x = 35
* y = d7
* x size = 39*8
* y size = 8
;.palk
;	pushm	all
;	tst.b	uusikick(a5)		* uusi kick?
;	beq.b	.oz

;	push	d7

;	move	d7,ply1
;	subq	#6,ply1
;	moveq	#7,ply2
;	moveq	#35,plx1
;	move.l	#39*8-2,plx2
;	add.l	plx1,plx2
;	add.l	ply1,ply2
;	bsr	.1

;	pop	d7
	
;	move.l	srastport(a5),a2
;	moveq	#35+1,d0
;	subq	#5,d7
;	move	d7,d1
;	move	#39*8+35-3,d2
;	moveq	#5,d3
;	add	d7,d3
;	bsr.w	drawtexture

;.oz	popm	all
;	rts

* Local desmsg variant
* in: 
*   a3 = desbuf
*   a1 = parametrit
.desmsg4	
	movem.l	d0-d7/a0-a3/a6,-(sp)
	jmp	pulppa

; Put line change with special line feed so that ordinary line feeds
; can be filtered out.
.putLineChange	
	move.b	#ILF,(a3)+
	move.b	#ILF2,(a3)+
	rts

.prepareFailed
	DPRINT	"prepare fail"
	rts

.prepareInfoWindowContent

	; which content to display?
	move.b	infolag(a5),d0
	;clr.b	infolag(a5)
	;tst.b	d0
	beq.b	.modinf
	* Display generic about text

******** About- aiheet
	move	#39,info_prosessi(a5)		* info-lippu
	lea	about_t,a0
	move.l	a0,infotaz(a5)
	* Displays some statistics with correct keyfile.
	* tst.b	keycheck(a5)
	* bne.w	.nox
	
	lea	(about_t1-about_t)(a0),a4
	lea	(about_tt-about_t1)(a4),a0
	lea	-200(sp),sp
	move.l	sp,a3

	move.l	modamount(a5),d0
	move.l	divideramount(a5),d1
	sub.l	d1,d0
	movem.l	d0/d1,-(sp)
	pea	keyfile(a5)
	move.l	sp,a1
	bsr.b	.desmsg4
	add	#8+4,sp
	st	eicheck(a5)

	move.l	sp,a0
.c	move.b	(a0)+,(a4)+
	bne.b	.c
	move.b	#'≠',-1(a4)

	lea	200(sp),sp
	bra.w	.nox

.modinf
	* Display module specific information
******** Kehitell‰‰n infoa moduulista


	clr	sfirstname(a5)
	clr	sfirstname2(a5)
	clr.l	infotaz(a5)

	; safety checks
	tst	playertype(a5)
	beq.b	.1
	tst.l	moduleaddress(a5)
	beq.b	.1
	tst.l	playingmodule(a5)
	bpl.b	.bah
.1
	* Nothing is being played. Display "No info available".

	move	#35,info_prosessi(a5)		* lipbub

	moveq	#3,d5
	bsr.w	.allo2
	beq.w	.prepareFailed

	lea	.huhe(pc),a0
	move.l	infotaz(a5),a1
.faz	move.b	(a0)+,(a1)+
	bne.b	.faz

	bra.w	.selvis

.bah
	* Something is being played.
	* Check supported types.

******************* THX

	cmp	#pt_thx,playertype(a5)
	bne.b	.nothx
	move	#33,info_prosessi(a5)

	move.l	moduleaddress(a5),a4
	moveq	#0,d5
	move.b	12(a4),d5
	move	d5,d7
	bsr.w	.allo * out: a3 = output buffer
	beq.w	.prepareFailed

	move.l	moduleaddress(a5),a4
	move.l	a4,a2
	add.l	modulelength(a5),a2

	add	4(a4),a4
	bsr.b	.fo

	subq	#1,d7
	moveq	#1,d0

.thxb
	lea	-10(sp),sp
	move.l	sp,a1

	move.l	d0,(a1)	 * param 1
	move.l	a4,4(a1) * param 2
	lea	.thxform(pc),a0
	bsr.w	.desmsg4
	bsr.w	.lloppu
	lea	10(sp),sp
	bsr.b	.fo
	
	addq	#1,d0
	dbf	d7,.thxb

	bra.w	.selvis

.fo	cmp.l	a2,a4
	beq.b	.fox
	tst.b	(a4)+
	bne.b	.fo
.fox	rts

******************* DIGI Booster
.nothx

	cmp	#pt_digibooster,playertype(a5)
	bne.b	.nobooster
	move	#33,info_prosessi(a5)

	moveq	#31,d5
	bsr.w	.allo
	beq.w	.prepareFailed


	move.l	moduleaddress(a5),a0
	lea	176(a0),a2		* lengths
	lea	642(a0),a4		* samplenames

	moveq	#31-1,d7
	moveq	#1,d0

.digib

	lea	-16(sp),sp
	move.l	sp,a1

	move.l	d0,(a1)
	move.l	(a2)+,8(a1)
	move.l	a4,4(a1)

	lea	.medform(pc),a0
	bsr.w	.desmsg4

	lea	16(sp),sp
	bsr.w	.lloppu

	lea	30(a4),a4
	
	addq	#1,d0
	dbf	d7,.digib

	bra.w	.selvis


.nobooster


	cmp	#pt_med,playertype(a5)		* MED
	bne.b	.nomed
	move	#33,info_prosessi(a5)		* lipub

***************** MED
	tst.b	medrelocced(a5)		* pit‰Ê olla relokatoitu
	beq.w	.noo

	move.l	moduleaddress(a5),a0
	move.l	32(a0),a1		* MMD0exp
	tst.l	20(a1)
	beq.w	.noo_med
	move.l	20(a1),a2		* MMDInstrInfo (samplenamet)
	move	24(a1),d4		* samplejen m‰‰r‰
	move	26(a1),d6		* entry size

	move.l	24(a0),d7		* insthdr

	move	d4,d5
	bsr.w	.allo
	beq.w	.prepareFailed

	move.l	d7,a0

	subq	#1,d4
	moveq	#1,d0
.medl
	move.l	a2,d1
	move.l	(a0)+,d2
	bne.b	.moe
	lea	.zero(pc),a1
	moveq	#0,d2
	bra.b	.moee
.moe
	move.l	d2,a1
	move.l	(a1),d2
.moee

	push	a0
	lea	-16(sp),sp
	move.l	sp,a1
	movem.l	d0/d1/d2,(a1)
	lea	.medform(pc),a0
	bsr.w	.desmsg4
	lea	16(sp),sp
	bsr.w	.lloppu
	pop	a0

	add	d6,a2
	addq	#1,d0
	dbf	d4,.medl

	bra.w	.selvis



.nomed
	cmp	#pt_sid,playertype(a5)		* PSID
	bne.w	.nosid

* SID piisista infoa

	move	#33,info_prosessi(a5)		* PSID info-lippu


	lea	-42(sp),sp
	move.l	sp,a1
	pushpea	sidheader+sidh_name(a5),(a1)+
	pushpea	sidheader+sidh_author(a5),(a1)+
	pushpea	sidheader+sidh_copyright(a5),(a1)+
	clr.l	(a1)+
	clr.l	(a1)+
	move	sidheader+sidh_number(a5),-6(a1)
	move	sidheader+sidh_defsong(a5),-2(a1)
	move.l	modulelength(a5),(a1)+
	move.l	moduleaddress(a5),d0
	move.l	d0,(a1)+
	add.l	modulelength(a5),d0
	move.l	d0,(a1)+
	pushpea	filecomment(a5),(a1)+
	clr.l	(a1)

	move.l	sp,a1
	moveq	#11,d5
	bsr.w	.allo2
	bne.b	.jee9
	lea	42(sp),sp
	bra.w	.prepareFailed
.jee9

	lea	.form(pc),a0
	move.l	infotaz(a5),a3
	bsr.w	.desmsg4
	lea	42(sp),sp

	bsr.w	.putcomment
	bra.w	.selvis


.form	dc.b	"PSID-module",ILF,ILF2
	dc.b	"≠≠≠≠≠≠≠≠≠≠≠",ILF,ILF2
	dc.b	"Name: %-33.33s",ILF,ILF2
	dc.b	"Author: %-31.31s",ILF,ILF2
	dc.b	"Copyright: %-28.28s",ILF,ILF2
	dc.b	"Songs: %ld (default %ld)",ILF,ILF2
	dc.b	"Size: %-7.ld     ($%08.lx-$%08.lx)",ILF,ILF2
	dc.b	"Comment:",ILF,ILF2,0
 even

.huhe	dc.b	ILF,ILF2
	dc.b	"          No info available.",0
.zero = *-1
 even

.nosid

	* Check for IT special case,
	* handle it as an eagleplayer
	jsr	isImpulseTrackerActive
	beq.b	.yesIT
	cmp	#pt_eagle_start,playertype(a5)		* eagleplayer
	blo.w	.noeagle
.yesIT
	move	#33,info_prosessi(a5)		* some magic flag

	lea	.form3(pc),a0
	lea	-32(sp),sp
	move.l	sp,a4
	bsr.w	.namtypsizcom

	moveq	#10+20,d5
	bsr.w	.allo2
	bne.b	.jee9eg
	lea	32(sp),sp
	bra.w	.prepareFailed
.jee9eg
	move.l	sp,a1
	move.l	infotaz(a5),a3
	bsr.w	.desmsg4
	bsr.w	.putcomment
	lea	32(sp),sp

	move.l	infotaz(a5),a3
	bsr.w	.lloppu
	bsr.w	.putLineChange

	move.l	#MI_SongName,d1
	lea	.eagleSong(pc),a0
	bsr.w	.deliPutInfo
	move.l	#MI_AuthorName,d1
	lea	.eagleAuthor(pc),a0
	bsr.w	.deliPutInfo
	move.l	#MI_SubSongs,d1
	lea	.eagleSubsongs(pc),a0
	bsr.w	.deliPutInfo
	move.l	#MI_Prefix,d1
	lea	.eaglePrefix(pc),a0
	bsr.w	.deliPutInfo
	move.l	#MI_Samples,d1
	lea	.eagleSamples(pc),a0
	bsr.w	.deliPutInfo
	move.l	#MI_SynthSamples,d1
	lea	.eagleSynthSamples(pc),a0
	bsr.w	.deliPutInfo
	move.l	#MI_Songsize,d1
	lea	.eagleSongSize(pc),a0
	bsr.w	.deliPutInfo
	move.l	#MI_SamplesSize,d1
	lea	.eagleSamplesSize(pc),a0
	bsr.w	.deliPutInfo
	move.l	#MI_Voices,d1
	lea	.eagleVoices(pc),a0
	bsr.w	.deliPutInfo

	move.l	#MI_Duration,d1
	jsr	deliFindInfoValue
	ble.b	.noEagleDur
	divu	#60,d0 
	move.l	d0,d1
	swap	d1 
	ext.l 	d0 
	ext.l 	d1
	lea	.eagleDuration(pc),a0
	bsr.w	.deliPutInfo2
.noEagleDur

	move.l	#MI_About,d1
	lea	.eagleAbout(pc),a0
	bsr.w	.deliPutInfo

	move.l	infotaz(a5),a3
	bsr.w	.lloppu
	bsr.w	.putLineChange
	
	move.l	#DTP_PlayerName,d0 
	jsr	deliGetTag 
	beq.b 	.noPlrName 
	lea	.eagleName(pc),a0 
	bsr.b	.deliPutInfo2	
.noPlrName 
	* Creator, 1-3 lines
	move.l	#DTP_Creator,d0 
	jsr	deliGetTag 
	beq.b 	.noCrtr
	lea	.eagleCreator(pc),a0 
	; format output buffer
	lea	-200(sp),sp
	move.l	sp,a3
	jsr	desmsg3
	move.l	sp,a0

	; target output buffer
	move.l	infotaz(a5),a3
	bsr.w	.lloppu
	; do three lines wrapping at space
	bsr.b	.doLine
	bpl.b	.ends
	bsr.b	.doLine
	bpl.b	.ends
	bsr.b	.doLine
	bra.b	.ends

* Copies a line to output, cuts at space near the end of line
* in:
*   a0 = input text
*   a3 = output buffer
* out:
*   a0 = pointer to next line if available
*   a3 = pointer to next position in output buffer
*   d0 = negative: all input handled
*        positive: data left in input for the next row
.doLine
	moveq	#39-1,d0
	moveq	#0,d1
.cl1	cmp.b	#" ",(a0)
	bne.b	.ns1
	addq	#1,d1 ; keep track of spaces
.ns1	move.b	(a0)+,(a3)+
	dbeq	d0,.cl1
	tst	d0
	bpl.b	.endLine
	; find previous space to cut from
	; SAFETY: if there are any
	tst	d1
	beq.b	.endLin
.li1	subq	#1,a3
	cmp.b	#" ",-(a0)
	bne.b	.li1
	addq	#1,a0
	move.l	a0,d0
.endLin
	moveq	#-1,d0
.endLine
	bsr.w	.putLineChange
	tst	d0
	rts
.ends
	lea	200(sp),sp
.noCrtr
	bra.w	.selvis

.deliPutInfo
	push 	a0
	jsr	deliFindInfoValue
	pop  	a0
	tst.l	d0
	* zero or lower
	ble.b	.noInfo
.deliPutInfo2
	move.l	infotaz(a5),a3
	bsr.w	.lloppu
	bsr.b	.deliFormat
.noInfo
	rts

.deliFormat	
	pushm	d0-d7
	move.l	sp,a1
	lea	putc,a2	;merkkien siirto
	lore 	Exec,RawDoFmt
	popm	d0-d7
	rts

* max width: 39
.eagleSong	 	dc.b	"Song: %-33.33s",ILF,ILF2,0
.eagleAuthor		dc.b	"Author: %-31.31s",ILF,ILF2,0
.eagleSubsongs		dc.b	"Subsongs: %ld",ILF,ILF2,0
.eagleSamples		dc.b	"Samples: %ld",ILF,ILF2,0
.eagleSynthSamples	dc.b	"Synth samples: %ld",ILF,ILF2,0
.eagleSongSize	 	dc.b	"Song size: %ld bytes",ILF,ILF2,0
.eagleSamplesSize	dc.b	"Samples size: %ld bytes",ILF,ILF2,0
.eaglePrefix 		dc.b	"Prefix: %s",ILF,ILF2,0
.eagleVoices	 	dc.b	"Voices: %ld",ILF,ILF2,0
.eagleDuration	 	dc.b	"Duration: %02ld:%02ld",ILF,ILF2,0
.eagleAbout	     	dc.b	"About: %-32.32s",ILF,ILF2,0
.eagleName		dc.b	"Eagleplayer: %-26.26s",ILF,ILF2,0
.eagleCreator       	dc.b	"Creator: %s",0
 even

.noeagle

********* module (PT)

	move	#34,info_prosessi(a5)		* show samplenames info-lippu

	

	cmp	#pt_startrekker,playertype(a5)
	beq.b	.yes
	cmp	#pt_prot,playertype(a5)
	bne.b	.nop
.yes	move.l	#ptheader,d4
	bra.b	.mod
.nop
	cmp	#pt_multi,playertype(a5)
	bne.w	.noo
	move.l	moduleaddress(a5),d4

	move.l	ps3m_mtype(a5),a0
	cmp	#mtMOD,(a0)
	beq.b	.mod
	cmp	#mtS3M,(a0)
	beq.w	.s3m
	cmp	#mtMTM,(a0)
	beq.w	.mtm
	cmp	#mtXM,(a0)
	beq.w	.xm
	bra.w	.noo


.mod	
	moveq	#31,d5
	bsr.w	.allo
	beq.w	.prepareFailed

	moveq	#0,d7
	moveq	#31-1,d6
.loop2	move	d7,d0
	mulu	#30,d0
	move.l	d4,a0
	lea	20(a0,d0),a2		* 22 bytes samplename

** kludge, jos eka char on 0 ja toka ei, se on samplename.
	tst.b	(a2)
	bne.b	.nokl
	tst.b	1(a2)
	beq.b	.nokl
	move.b	#' ',(a2)
.nokl

	lea	-24(sp),sp
	move.l	sp,a0
	move.l	a0,d1			* name, null terminated
	move.l	a2,a1
	moveq	#22-1,d0
.copz	move.b	(a1)+,(a0)+
	dbeq	d0,.copz
	clr.b	(a0)

	moveq	#0,d2
	move	22(a2),d2
	add.l	d2,d2			* length

	move.l	d7,d0
	addq	#1,d0


	lea	-16(sp),sp
	move.l	sp,a1
	movem.l	d0/d1/d2,(a1)
	lea	.form0(pc),a0
	bsr.w	.desmsg4
	lea	16(sp),sp
	bsr.w	.lloppu

	lea	24(sp),sp

	addq	#1,d7
	dbf	d6,.loop2
	bra.w	.selvis






******* screamtracker

.s3m
	move.l	d4,a0
	move	insnum(a0),d5
	iword	d5
	bsr.w	.allo
	beq.w	.prepareFailed

* a3 = pointteri tekstipuskuriin

	move.l	d4,a0
	move	insnum(a0),d5
	iword	d5

	moveq	#0,d7

.loop	move	d7,d0
	add	d0,d0

	move.l	ps3m_samples(a5),a2
	move.l	(a2),a2
	move	(a2,d0),d0
	iword	d0
	lsl	#4,d0
	move.l	d4,a0
	lea	(a0,d0),a0
	lea	insname(a0),a1
	move.l	a1,d1
	move.l	inslength(a0),d2
	ilword	d2
	and.l	#$7ffff,d2
	move.l	d7,d0
	addq	#1,d0

	lea	-16(sp),sp
	move.l	sp,a1
	movem.l	d0/d1/d2,(a1)
	lea	.form2(pc),a0
	bsr.w	.desmsg4
	lea	16(sp),sp
	bsr.w	.lloppu

	addq	#1,d7
	cmp	d5,d7
	blo.b	.loop
.pois	
	bra.w	.selvis


***** XM

.xm
	move.l	d4,a0
	lea	xmNumInsts(a0),a0
	tword	(a0)+,d5
	bsr.w	.allo
	beq.w	.prepareFailed

	move.l	d4,a0
	move.l	ps3m_xm_insts(a5),a0
	moveq	#0,d7

.loop0	move	d7,d0
	lsl	#2,d0
	move.l	(a0,d0),a2
	moveq	#0,d1
	move.l	a2,a1
	tlword	(a1)+,d0
	move.l	a1,d6			; Name

	lea	xmNumSamples(a2),a1
	tword	(a1)+,d2
	tst	d2
	beq.w	.skip
	lea	xmSmpHdrSize(a2),a1
	tlword	(a1)+,d3
	add.l	d0,a2
	subq	#1,d2
.k0o	move.l	a2,a1
	tlword	(a1)+,d0
	add.l	d0,d1
	add.l	d3,a2
	dbf	d2,.k0o

.skip	
;	move.l	d1,(a4)+	* size



	pushm	d0-a2/a4-a6
	move.l	d1,d2
	and.l	#$7ffff,d2
	move.l	d7,d0
	addq	#1,d0
	move.l	d6,d1
	lea	-16(sp),sp
	move.l	sp,a1
	movem.l	d0/d1/d2,(a1)
	lea	.form2(pc),a0
	bsr.w	.desmsg4
	lea	16(sp),sp
	popm	d0-a2/a4-a6
	bsr.w	.lloppu


	addq.l	#1,d7
	cmp	d5,d7
	blo.w	.loop0

	bra.w	.selvis


***** multitracker

.mtm
	move.l	d4,a0
	moveq	#0,d5
	move.b	30(a0),d5
	bsr.w	.allo
	beq.w	.prepareFailed

	moveq	#0,d7
.loop3	move	d7,d0
	mulu	#37,d0
	move.l	d4,a0
	lea	66(a0,d0),a2
	move.l	a2,d1			; Name

	moveq	#0,d2
	move.b	22(a2),d2
	lsl	#8,d2
	move.b	23(a2),d2
	lsl.l	#8,d2
	move.b	24(a2),d2
	lsl.l	#8,d2
	move.b	25(a2),d2
	ilword	d2
;	move.l	d2,(a4)+		* size


	move.l	d7,d0
	addq	#1,d0

	lea	-16(sp),sp
	move.l	sp,a1
	movem.l	d0/d1/d2,(a1)
	lea	.form2(pc),a0
	bsr.w	.desmsg4
	lea	16(sp),sp
	bsr.w	.lloppu


	addq.l	#1,d7
	cmp	d5,d7
	blo.b	.loop3
	bra.w	.pois



* PS3M
.form11	dc.b	"Name: %-33.33s",ILF,ILF2
	dc.b	"Type: %-25.25s %2.ld.%1.1ldkHz",ILF,ILF2
	dc.b	"Size: %-7.ld     ($%08.lx-$%08.lx)",ILF,ILF2
	dc.b	"Comment: ",0


* PT
.form1	dc.b	"Name: %-33.33s",ILF,ILF2
	dc.b	"Type: %-33.33s",ILF,ILF2
	dc.b	"Size: %-7.ld     ($%08.lx-$%08.lx)",ILF,ILF2
	dc.b	"Comment: ",0

** PT

.form0	dc.b	'%02ld %-22.22s        %6ld',ILF,ILF2,0

** PS3M

.medform 
.form2	dc.b	"%03ld %-28.28s %6ld",ILF,ILF2,0

.thxform
 	dc.b	"%03ld %-35.35s",ILF,ILF2,0

 even



** Joku muu modi

.noo_med
.noo
	* DEFAULT INFO
	DPRINT	"default info"
	
	move	#35,info_prosessi(a5)

	lea	.form3(pc),a0

	lea	-32(sp),sp
	move.l	sp,a4
	bsr.w	.namtypsizcom

	moveq	#10,d5
	bsr.w	.allo2
	bne.b	.jee9a
	lea	32(sp),sp
	bra.w	.prepareFailed
.jee9a
	* parameters in a1
	move.l	sp,a1
	move.l	infotaz(a5),a3
	bsr.w	.desmsg4
	bsr.w	.putcomment
	lea	32(sp),sp
	
	moveq	#0,d0 
	move.l	playerbase(a5),a0 
	jsr	p_author(a0) 
	tst.l	d0 
	beq.b 	.noAuth

	lea	.author(pc),a0
	; format output buffer
	lea	-200(sp),sp
	move.l	sp,a3
	jsr	desmsg3
	move.l	sp,a0
	move.l	a0,d0

	; target output buffer
	move.l	infotaz(a5),a3
	bsr.w	.lloppu
	bsr.w	.doLine
	bpl.b	.endA
	bsr.w	.doLine
	bpl.b	.endA
	bsr.w	.doLine
.endA	lea	200(sp),sp
.noAuth
	bra.w	.selvis


.form3	
	dc.b	"Name: %-33.33s",ILF,ILF2
	dc.b	"Type: %-33.33s",ILF,ILF2
	dc.b	"Size: %-9.ld   ($%08.lx-$%08.lx)",ILF,ILF2
	dc.b	ILF,ILF2
	dc.b	"Comment:",ILF,ILF2,0
.author
	dc.b	"Player: %s",0
  even


.putcomment
	pushm	d0/d1/a0/a3
	moveq	#39+1,d1
	bra.b	.puct

.putcomment2
	pushm	d0/d1/a0/a3
	moveq	#30+1,d1
.puct
	move.l	infotaz(a5),a3
	bsr.w	.lloppu
	lea	filecomment(a5),a0
 if DEBUG
	move.l	a0,d0
	DPRINT	"comment: %s"
 endif
	tst.b	(a0)
	beq.b	.empty
	bsr.b	.putlines
	bsr.w	.putLineChange
	bsr.w	.putLineChange
.empty
	popm	d0/d1/a0/a3
	rts

.putlines
	moveq	#0,d0
.com	addq	#1,d0
	cmp	d1,d0
	bne.b	.naga
	moveq	#39,d1
	tst.b	(a0)
	beq.b	.naga
	moveq	#0,d0
	bsr.w	.putLineChange
.naga	move.b	(a0)+,(a3)+
	bne.b	.com
	subq	#1,a3 ; back to NULL
	rts
 
*************************************

* writes into a4 depending on format:
* - module name address
* - module type address
* - mix rate integer
* - mix rate decimal
* - module length
* - module start addr
* - module end addr

.namtypsizcom
	pushm	d0/d1

	pushpea	modulename(a5),(a4)+
	pushpea	moduletype(a5),(a4)+

	cmp	#pt_med,playertype(a5)
	bne.b	.lee
	cmp.b	#2,medtype(a5)		* Med 1-64ch?
	bne.b	.lee

	move.l	moduleaddress(a5),a1	* onko samplenimiÊ?
	move.l	32(a1),a1		* MMD0exp
	tst.l	20(a1)
	bne.b	.rrqq

.lee
	cmp	#pt_multi,playertype(a5)		* mixing rate
	bne.b	.nah
	jsr	isImpulseTrackerActive
	beq.b	.nah
.rrqq	
	move.l	mixirate(a5),d0
	tst.b	ahi_use_nyt(a5)
	beq.b	.psz
	move.l	ahi_rate(a5),d0
.psz
	divu	#1000,d0
	move.l	d0,d1
	clr	d1
	swap	d1
	ext.l	d0
	move.l	d0,(a4)+
	move.l	d1,(a4)+
.nah

	move.l	modulelength(a5),(a4)

	tst.b	lod_xpkfile(a5)		* v‰hennet‰‰n xpk:n turvapuskurin koko
	beq.b	.noxp
	sub.l	#256,(a4)
.noxp
	addq.l	#4,a4

	cmp	#pt_sample,playertype(a5)
	beq.b	.jccc
	cmp	#pt_tfmx,playertype(a5)
	beq.b	.jt
	cmp	#pt_tfmx7,playertype(a5)
	bne.b	.jcc

.jt
	move.l	tfmxsampleslen(a5),d0
	add.l	d0,-4(a4)

* tfmx? pistet‰‰n mdat ja smpl alkuosoitteet
	move.l	moduleaddress(a5),(a4)+
	move.l	tfmxsamplesaddr(a5),(a4)+
	bra.b	.xop
.jccc
	clr.l	(a4)+		* sampleilla ei osoitteita
	clr.l	(a4)+
	bra.b	.xop
.jcc


	move.l	moduleaddress(a5),d0
	move.l	d0,(a4)+
	add.l	modulelength(a5),d0
	move.l	d0,(a4)+

.xop

	popm	d0/d1
	rts


.allo:
	bsr.b	.allo2
	beq.b	.xiipo

	lea	-32(sp),sp
	move.l	sp,a4
	bsr.w	.namtypsizcom

	lea	.form1(pc),a0

	cmp	#pt_med,playertype(a5)
	bne.b	.nee
	cmp.b	#2,medtype(a5)
	beq.b	.okod
;	move.l	moduleaddress(a5),a0
;	move.l	32(a0),a0		* MMD0exp
;	tst.l	20(a0)			* onko samplenimi‰?
;	beq.b	.okod
.nee
	cmp	#pt_multi,playertype(a5)
	bne.b	.bahz
.okod	lea	.form11(pC),a0
.bahz	


	move.l	sp,a1
	move.l	infotaz(a5),a3
	bsr.w	.desmsg4
	lea	32(sp),sp

	bsr.w	.putcomment2
	
	move.l	infotaz(a5),a3
	bsr.b	.lloppu

	bsr.w	.putLineChange
	moveq	#39-1,d0
.ca	move.b	#"≠",(a3)+
	dbf	d0,.ca
	bsr.w	.putLineChange
	clr.b	(a3)

	moveq	#1,d0
.xiipo	rts

.lloppu	tst.b	(a3)+
	bne.b	.lloppu
	subq	#1,a3
	rts
	

.allo2:
** Varataan muistia tekstipuskurille
	move	d5,d0
	add	#20,d0		* 20 vararivi‰ varalle
	mulu	#40,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	jsr	getmem
	move.l	d0,infotaz(a5)
	rts

.selvis
** If we made this far the module information text has been built

**  Karsitaan kummat merkit pois
	move.l	infotaz(a5),a2

* sallittu alue: 33-126, 160-255
	lea	asciitable,a0
	moveq	#0,d0
	moveq	#0,d1
	move.b	#'≠',d2

.clo	tst.b	(a2)
	beq.b	.nox
	move.b	(a2),d0

	cmp.b	#ILF,d0
	bne.b	.per
	cmp.b	#ILF2,1(a2)
	bne.b	.per
	move.b	#10,(a2)+
	bra.b	.nomu
.per


* charset conversion s3m, xm
* tehd‰‰n vasta ≠≠≠≠≠ rivin j‰lkeen

	tst.b	d1
	bne.b	.conve

	cmp.b	d2,d0
	bne.b	.ohic
	cmp.b	1(a2),d2
	bne.b	.ohic
	st	d1

.conve
	cmp	#pt_multi,playertype(a5)
	bne.b	.ohic
	move.l	ps3m_mtype(a5),a1
	cmp	#mtS3M,(a1)
	beq.b	.con
	cmp	#mtMTM,(a1)
	beq.b	.con
	cmp	#mtXM,(a1)
	bne.b	.ohic
.con
	cmp.b	d2,d0
	beq.b	.ohic
	move.b	(a0,d0),d0		* PC -> Amiga
	move.b	d0,(a2)
.ohic

	cmp.b	#10,d0
	beq.b	.mur
	cmp.b	#33,d0
	blo.b	.mur
	cmp.b	#126,d0
	bls.b	.nomu
	cmp.b	#160,d0
	bhs.b	.nomu
.mur	move.b	#' ',(a2)
.nomu	addq	#1,a2
	bra.b	.clo
.nox
	rts

****** PT sample play

.samplePlay
	sub	windowleft(a5),d5
	sub	windowtop(a5),d6	* suhteutus fonttiin

	cmp	#31,d5
	blo.w	.samplePlayExit
	cmp	#345,d5
	bhi.w	.samplePlayExit
	cmp	#14,d6
	blo.w	.samplePlayExit
	move	infosize(a5),d0
	lsl	#3,d0
	add	#14,d0
	cmp	d0,d6
	bhi.w	.samplePlayExit

	tst.b	ahi_muutpois(a5)
	bne.w	.samplePlayExit

	cmp	#pt_prot,playertype(a5)
	bne.w	.samplePlayExit
	tst.l	playingmodule(a5)
	bmi.w	.samplePlayExit

* d5/d6 = mouse x/y

	move	d6,d0
	sub	#14+1,d0
	lsr	#3,d0
	add	sfirstname(a5),d0
	subq	#1,d0
	bmi.w	.samplePlayExit

	move.l	infotaz(a5),a0
.ff	cmp.b	#10,(a0)+
	bne.b	.ff
	dbf	d0,.ff

	addq	#1,a0
	cmp.b	#' ',2(a0)
	bne.w	.samplePlayExit

	move.b	(a0)+,d0
	cmp.b	#'0',d0
	blo.w	.samplePlayExit
	cmp.b	#'3',d0
	bhi.w	.samplePlayExit
	and	#$f,d0
	mulu	#10,d0
	move.b	(a0)+,d1
	and	#$f,d1
	add	d1,d0		* d0 = samplenum

	cmp	#$1f,d0
	bhi.b	.samplePlayExit

	move	d0,d7
	subq	#1,d7
	bmi.b	.samplePlayExit
	
	jsr	obtainModuleData
	move.l	moduleaddress(a5),a1	* onko chipiss‰?
	lore	Exec,TypeOfMem
	jsr	releaseModuleData
	btst	#MEMB_CHIP,d0
	beq.b	.samplePlayExit

	jsr	obtainModuleData
	move.l	moduleaddress(a5),a1

	lea	952(a1),a0		* tutkitaan patternien m‰‰r‰
	moveq	#128-1,d0
	moveq	#0,d1
.k_lop1
	move.b	(a0)+,d2
	cmp.b	d2,d1
	bhi.b	.k_lop2
	move.b	d2,d1
.k_lop2	dbf	d0,.k_lop1
	addq	#1,d1
	mulu	#1024,d1		* Eka sample patternien j‰lkeen
	lea	1084(a1),a0
	add.l	d1,a0

	move	d7,d0
	moveq	#0,d1

.l	add.l	d1,a0
	moveq	#0,d1
	move	42(a1),d1	* len
	add.l	d1,d1
	moveq	#0,d2
	move	46(a1),d2	* repeat point
	add.l	d2,d2
	add.l	a0,d2
	move	48(a1),d3	* repeat len
	bne.b	.lw
	moveq	#1,d3
.lw

	lea	30(a1),a1
	dbf	d0,.l

	tst	d1
	bne.b	.sampleLenOk
	;* Something wrong with the data, go back to loop
	jsr	releaseModuleData
.samplePlayExit
	rts

.sampleLenOk

* a0 = sampleaddr
* d1 = samplelen
* d2 = repeat point
* d3 = repeat len

;	push	d5

*** Onko sample fastissa?
;	bsr	freeinfosample
;	move.l	d1,d6
;	sub.l	a0,d2
	
; ei taida toimia koska lev4 interruptit sotkevat

;	lea	foosample,a1
;	move.l	a1,a2
;.lrr	move.b	(a0)+,(a1)+
;	subq.l	#1,d6
;	bne.b	.lrr

;	move.l	a2,a0
;	add.l	a0,d2	

;	move.l	a0,d5
;	move.l	d1,d6

;	move.l	a0,a1
;	lore	Exec,TypeOfMem
;	btst	#MEMB_CHIP,d0
;	bne.b	.okc

;	move.l	d6,d0
;	moveq	#MEMF_CHIP,d1
;	bsr	getmem

;	sub.l	d5,d2
;	add.l	d0,d2

;	move.l	d5,a0
;	move.l	d0,d5
;	move.l	d0,a1
;	move.l	d6,d0
;	lob	CopyMem

;	move.l	d5,infosample(a5)

;	move.l	#nullsample,d2
;	moveq	#1,d3

.okc
;	move.l	d5,a0
;	move.l	d6,d1

;****
;	pop	d5


	tst.b	playing(a5)
	beq.b	.s1
	pushm	all
	* Pause playback first
	bsr.w	stopcont		* pausetaan
	popm	all
.s1

	* Set up audio registers for playback

	lea	$dff096,a3

	move	#$f,(a3)
	move.l	a0,$a0-$96(a3)
	move.l	a0,$b0-$96(a3)
	move.l	a0,$c0-$96(a3)
	move.l	a0,$d0-$96(a3)
	move	mainvolume(a5),d0
	lsr	#1,d0
	move	d0,$a8-$96(a3)
	move	d0,$b8-$96(a3)
	move	d0,$c8-$96(a3)
	move	d0,$d8-$96(a3)

	lsr.l	#1,d1
	move	d1,$a4-$96(a3)
	move	d1,$b4-$96(a3)
	move	d1,$c4-$96(a3)
	move	d1,$d4-$96(a3)

** Mouse coordinate defines the sample period
** perioidi mousen x-koordinaatista
	sub	#31,d5			* d5 = 0-315
	mulu	#36,d5
	divu	#315,d5
	add	d5,d5
	move	periods(pc,d5),d5

	move	d5,$a6-$96(a3)
	move	d5,$b6-$96(a3)
	move	d5,$c6-$96(a3)
	move	d5,$d6-$96(a3)

	lore	GFX,WaitTOF
	move	#$800f,(a3)
	lob		WaitTOF

	move.l	d2,$a0-$96(a3)
	move.l	d2,$b0-$96(a3)
	move.l	d2,$c0-$96(a3)
	move.l	d2,$d0-$96(a3)
	move	d3,$a4-$96(a3)
	move	d3,$b4-$96(a3)
	move	d3,$c4-$96(a3)
	move	d3,$d4-$96(a3)

	* Sample is now playing
	jsr	releaseModuleData

	bra.w	.samplePlayExit

periods
	dc	856,808,762,720,678,640,604,570,538,508,480,453
	dc	428,404,381,360,339,320,302,285,269,254,240,226
	dc	214,202,190,180,170,160,151,143,135,127,120,113
periodsEnd

* NOT USED
;freeinfosample
;	tst.l	infosample(a5)
;	beq.b	.x
;	pushm	all
;	move.l	infosample(a5),a0
;	clr.l	infosample(a5)
;	jsr	freemem
;	popm	all
;.x	rts


****************************************************************
* About
**

calculateDividersInList
	jsr	obtainModuleList
	bsr.w	getVisibleModuleListHeader
	moveq	#0,d0
.l	TSTNODE	a0,a0
	beq.b	.e
	tst.b	l_divider(a0)
	beq.b	.l
	addq.l	#1,d0
	bra.b	.l
.e	jsr	releaseModuleList
	rts

aboutButtonAction
rbutton10
	DPRINT	"about"
	movem.l	d0-a6,-(sp)

* lasketaan dividereitten m‰‰r‰
	DPRINT  "aboutButtonAction obtain list"
	* calculate the amount of list dividers in the list
	;lea	moduleListHeader(a5),a4
	bsr.b	calculateDividersInList
	move.l	d0,divideramount(a5)
	DPRINT  "aboutButtonAction release list"

	; set flag: info window should display the about info
	st	infolag(a5)

	tst	info_prosessi(a5)
	beq.b	.z

	move.l	infotaz(a5),a0		* jos oli jo aboutti niin suljetaan
	cmp.l	#about_t,a0
	bne.b	.rr
	bsr.w	sulje_info
	bra.b	.x
.rr
	bsr.w	start_info
	bra.b	.x

.z	bsr.w	rbutton10b

.x	movem.l	(sp)+,d0-a6
	rts


*******************************************************************************
* (error) Requesteri
*******
* a1 = teksti

request:
	movem.l	d0-a6,-(sp)
	sub.l	a4,a4
request2:
	lea	.ok_g(pc),a2
	bsr.w	rawrequest
	movem.l	(sp)+,d0-a6
	tst.l	d0	* not needed?!
	rts

.ok_g	dc.b	"OK",0
 even

areyousure_delete
	movem.l	d1-a6,-(sp)
	lea	.z(pc),a1
	lea	.y(pc),a2
	lea	infodefresponse(pc),a4
	move.l	(a4),d7
	clr.l	(a4)
	bsr.w	rawrequest
	move.l	d7,(a4)
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts

.z	dc.b	"Delete this file (or divider section)?",0
.y	dc.b	"_Yes|_No",0
 even

* Check if favorites list should be modified from the user
* Out:
*   d0 = 0 if modification not allowed
*   d0 = 1 if modification allowed
confirmFavoritesModification
	; Check if in favorites list
	cmp.b	#LISTMODE_FAVORITES,listMode(a5)
	beq.b	.favs
	* No confirmation, all ok	
.ok	moveq	#1,d0
	rts
.favs
	tst.b	confirmFavoritesModificationDisabled(a5)
	bne.b	.ok

	push	a4
	lea	infodefresponse(pc),a4
	move.l	(a4),-(sp)
	; Set "Nope" as the default response
	clr.l	(a4)
	lea	.z(pc),a1
	lea	.y(pc),a2
	bsr.b	rawrequest
	move.l	(sp)+,(a4)
	pop	a4
	; d0 = 1: yes
	; d0 = 2: yes, dont ask again
	; d0 = 0: nope

	; Nope
	tst.l	d0
	beq.b	.x
	; Yes
	cmp	#1,d0
	beq.b	.ok
	; Yes, dont ask again
	cmp	#2,d0
	bne.b	.x
	st	confirmFavoritesModificationDisabled(a5)
	bra.b	.ok

.x	moveq	#0,d0
	rts

.z dc.b	"Modify the favorites list?",0
.y dc.b "_Yes|Yes, _don't ask again|_Nope!",0
 even
 
rawrequest:
	jsr	get_rt
	movem.l	a0-a4,-(sp)
	moveq	#RT_REQINFO,D0
	sub.l	a0,a0
;	move.l	_ReqBase+var_b,a6		* ???
	lob	rtAllocRequestA
	move.l	d0,d7
	movem.l	(sp)+,a0-a4
	tst.l	d0
	beq.b	.w
	move.l	d7,a3
	lea	inforeqtags0(pc),a0
	jsr	setMainWindowWaitPointer
	lob	rtEZRequestA
	jsr	clearMainWindowWaitPointer
	move.l	d0,-(sp)
	move.l	d7,a1
	lob	rtFreeRequest
	move.l	(sp)+,d0
	tst.l	d0
.w	rts





inforeqtags0
	dc.l	RTEZ_Flags,EZREQF_CENTERTEXT
	dc.l	RTEZ_ReqTitle,reqtitle

	dc.l	RTEZ_DefaultResponse,1
infodefresponse	=	*-4

	dc.l	RT_Underscore,"_"
	dc.l	RT_TextAttr,text_attr
otag8	dc.l	RT_PubScrName,pubscreen+var_b
	dc.l	TAG_END

init_error
	* Eagle related error messages shown elsewhere
	cmp	#ier_eagleplayer,d0 
	beq.b 	.skip
	
	neg	d0
	add	d0,d0
	lea	.ertab-2(pc,d0),a1
	add	(a1),a1
	bsr.w	request
.skip
* vapautetaan moduuli
	jsr	freemodule
* printataan infoa
	bra.w	inforivit_initerror


.ertab	dr	ier_error_t
	dr	ier_nochannels_t
	dr	ier_nociaints_t
	dr	ier_noaudints_t
	dr	ier_nomedplayerlib_t
	dr	ier_nomedplayerlib2_t
	dr	ier_mederr_t
	dr	ier_playererr_t
	dr	memerror_t
	dr	ier_nosid_t
	dr	ier_sidicon_t
	dr	ier_sidinit_t
	dr	ier_nopr_t
	dr	nochip_t
	dr	unknown_t
	dr	grouperror_t
	dr	filerr_t
	dr	hardware_t
	dr	ahi_t
	dr	ier_nomled_t
	dr	ier_mlederr_t
	dr	ier_not_compatible_t
	dr	ier_eagleplayer_t

ier_error	=	-1
ier_nochannels	=	-2
ier_nociaints	=	-3
ier_noaudints	=	-4
ier_nomedplayerlib =	-5
ier_nomedplayerlib2 =	-6
ier_mederr	=	-7
ier_playererr	=	-8
ier_nomem	=	-9
ier_nosid	=	-10
ier_sidicon	=	-11
ier_sidinit	=	-12
ier_noprocess	=	-13
ier_nochip	=	-14
ier_unknown	=	-15
ier_grouperror	=	-16
ier_filerr	=	-17
ier_hardware	=	-18
ier_ahi		=	-19
ier_nomled	=	-20
ier_mlederr	=	-21
ier_not_compatible = 	-22
ier_eagleplayer	= 	-23

;hardware_t
ier_playererr_t
ier_error_t
	dc.b	"Init error!?",0
ier_nochannels_t
	dc.b	"Couldn't allocate audio channels!",0
ier_nociaints_t
	dc.b	"Couldn't allocate CIA timer(s)!",0
ier_noaudints_t
	dc.b	"Couldn't allocate audio interrupts!",0
ier_nomedplayerlib_t
ier_nomedplayerlib2_t
 dc.b	"Couldn't open medplayer, octaplayer or octamixplayer.library!",0
	
ier_mederr_t
ier_sidinit_t
	dc.b	"Couldn't allocate audio channels or CIA interrupts!",0
ier_nosid_t
	dc.b	"Couldn't open playsid.library!",0
ier_sidicon_t
	dc.b	"Trouble with SID icon!",0
ier_nomled_t
	dc.b	"Couldn't open mline.library!",0
ier_mlederr_t
	dc.b	"MusiclineEditor init error!",0
ier_nopr_t
	dc.b	"Couldn't create process!",0
nochip_t dc.b	"Not enough chip memory!",0
filerr_t	dc.b	"File error!",0
hardware_t	dc.b "68020 or better required!",0
ahi_t	dc.b	"AHI device error!",0
ier_not_compatible_t
	dc.b	"Unsupported module type!",0
ier_eagleplayer_t
	dc.b	"Couldn't load eagleplayer!",0
 even


 ifne EFEKTI
efekti
	tst.b	win(a5)		* onko ikkunaa?
	beq.b	.r
	tst.b	kokolippu(a5)	* ikkuna pieni?
	beq.b	.r

	moveq	#.sine-.sin-1,d7
	lea	.sin(pc),a3
.loop
	lore	GFX,WaitTOF
	lob	WaitTOF
	
	lea	slider1,a0
;	move	#65535,d1		* 65535*arvo/max
	moveq	#-1,d1
	moveq	#0,d0
	move.b	(a3)+,d0
	bmi.b	.sk
	mulu	d0,d1
	lsr.l	#6,d1			* uusi HorizPot

	move.l	gg_SpecialInfo(a0),a1
	move	pi_Flags(a1),d0
	move	pi_HorizBody(a1),d3
	moveq	#0,d2
	moveq	#0,d4
	move.l	windowbase(a5),a1
	sub.l	a2,a2
	moveq	#1,d5
	lore	Intui,NewModifyProp


.sk	dbf	d7,.loop
.r
	rts

.sin
	DC.b	0,-1,3,6,$B,$11,$17,$1D,$24
	DC.b	$2A,$30,$36,$3B,$40

	dc.b	$3C,$38,$36
	DC.b	$34,$33,$32,$31,$32,-1,$33,$34
	DC.b	$35,$37,$38,$39,$3B,$3C,$3D,$3F
	DC.b	$40

	dc.b	$3F,$3E,$3D,-1,-1,$3C,-1
	DC.b	-1,$3D,-1,-1,-1,$3E,-1,-1
	DC.b	-1,$3F,$40
.sine

 even

  endc
  

*******************************************************************************
*** SECTION *******************************************************************
*
* Vertical blanking interrupt
* CIA interrupt
* Software interrupt
*
*******************************************************************************

*******************************************************************************
* Keskeytykset
*******


intserver
	dc.l	0,0
	dc.b	2
	dc.b	0	* priority
	dc.l	.intname
	dc.l	var_b		* is_Data passed in a1
	dc.l	.vbinterrupt


.intname dc.b	"HiP-VBlank",0
 even

.vbinterrupt
	pushm	d2-d7/a2-a6
	move.l	a1,a5			* a1 = is_Data = var_b

	* Check if tooltip tick count is active.
	* It it expires, trigger a signal
	tst	tooltipTick(a5)
	beq.b	.notActive
	subq	#1,tooltipTick(a5)
	bne.b	.notActive
	move.b	tooltipSignal(a5),d1
	bsr.w	signalit
.notActive

	* Are we playing something?
	tst.b	playing(a5)
	beq.b	.notPlaying

	* Yes.
	* Let's call the CIA-replay routine if user has opted
	* for VBlank timing.

	push	a5
	* Check for VBlank timing flag
	tst.b	vbtimeruse(a5)
	beq.b	.novb
	* Play some music!
	move.l	playerbase(a5),a0
	jsr	p_ciaroutine(a0)
	move.l	(sp),a5
.novb
	* Whatever happened above, let's call the VBlank-replay routine.
	move.l	playerbase(a5),a0
	jsr	p_vblankroutine(a0)
	pop	a5

	* Call scope interrupt code.
	* This will keep track of sample playback positions for drawing.
	bsr.w	scopeinterrupt

	* Set filter 
	move.b	filterstatus(a5),d0
	bne.b	.oop
	btst	#1,$bfe001
	sne	modulefilterstate(a5)
	bra.b	.uup
.oop	subq.b	#1,d0
	bne.b	.eep
.peep	bset	#1,$bfe001
	bra.b	.uup
.eep	bclr	#1,$bfe001
.uup
	
	* Check if song has ended
	tst.b	songover(a5)
	beq.b	.huh
.songover	
	clr.b	songover(a5)

	* Trigger signal for the main application loop indicating song has ended.
	* If there is a loading operation going on, let's not signal.
	* This tests both "loading" and "loading2"
	tst	loading(a5)	
	bne.b	.wasLoading
	move.b	songHasEndedSignal(a5),d1
	bsr.w	signalit
.huh
.notPlaying
.wasLoading
	* Another are we playing check?
	tst.b	playing(a5)
	beq.b	.notPlaying2

	* Yes, we still are. Let's check if the playing position has changed
	* since the last check.
	move	pos_nykyinen(a5),d0	* current position
	move	positionmuutos(a5),d1	* last known position
	cmp	d1,d0
	beq.b	.eee
	move	d0,positionmuutos(a5)	* was different, store new changed position

	tst.b	kelattiintaakse(a5)	* check if there was some rewinding going on
	beq.b	.norewind
	clr.b	kelattiintaakse(a5)	* there was, let's not check for songend based 
					* on positions
	bra.b	.rewind
.norewind
	* If the last known position is higher than the current position,
	* we deduce that the song has actually ended and may have restarted
	* from the beginning.
	* This may trigger an extra songend signal after 
	* the above signal, so it should only be enabled for formats
	* that have pos/len but not songend support.
	* These are: MED, SoundFX, StarTrekker
	move.l	playerbase(a5),a0
	move	#pf_end,d2
	and	p_liput(a0),d2
	;bne.b	.skipCheck
	beq.b	.noSongEnd
	* This player supports songend. 
	* To avoid extra songend detections, do the song position
	* check only if the current position is non-zero.
	* This detects PT modules that jump from the last position to 
	* some other than position zero.
	tst	d0
	beq.b	.skipCheck

.noSongEnd

	* Current format does not have songend support, do the check!
	sub	d1,d0	
	bmi.b	.songover
.rewind
.skipCheck
	* Send a signal indicating that playing position has changed
	move.b	ownsignal2(a5),d1
	bsr.w	signalit
.eee
.notPlaying2

	* UI refresh signal
	* When playing: every 1/2th of second
	* When not: every second
	
	move	vertfreq(a5),d0
	tst.b	playing(a5)
	beq.b	.notPlaying3
	lsr     #1,d0				
.notPlaying3

	* Count if enough VBlanks have passed and then signal
	addq	#1,ticktack(a5)		
	cmp	ticktack(a5),d0
	bhi.b	.nope
	clr	ticktack(a5)
	move.b	uiRefreshSignal(a5),d1
	bsr.w	signalit
.nope

	* YET ANOTHER TEST!
	tst.b	playing(a5)	
	beq.w	.notPlaying4
	tst.b	vbtimeruse(a5)
	bne.b	.eir
	* Yes we are still playing and actually using CIA-timers
	* Check if user wants to fast forward.

	move.l	playerbase(a5),a0	* Kelaus CIA-ajastimella
	move	p_liput(a0),d0
	* Check if the replayer supports forwarding using timer
	btst	#pb_ciakelaus,d0
	bne.b	.joog
	* Check if the replayers forwarding by skipping patterns
	btst	#pb_ciakelaus2,d0
	beq.b	.eir
	
	cmp	#pt_prot,playertype(a5)		* ProTracker??
	bne.b	.joog
	* Yes it was protracker. Some special handling here.
	lea	kplbase(a5),a0
	move	k_timerhi(a0),d0
	move.b	k_whichtimer(a0),d1
	tst.b	kelausnappi(a5)
	beq.b	.bb
	lsr	#1,d0
.bb	move.l	k_cia(a0),a0
	lea	ciatalo(a0),a0
	tst.b	d1
	beq.b	.aap
	lea	$200(a0),a0
.aap	bra.b	.aa

	* Timer based forward.
	* Set a new timer delay into the CIA timer
.joog
	move	timerhi(a5),d0
	tst.b	kelausnappi(a5)		* onko painettu kelausnappia?
	beq.b	.kel
	move.b	kelausvauhti(a5),d1
	lsr	d1,d0
.kel
	move.l	ciaddr(a5),a0
	lea	ciatalo(a0),a0
	tst.b	whichtimer(a5)
	beq.b	.aa
	lea	$200(a0),a0
.aa
	move.b	d0,(a0)
	ror	#8,d0
	move.b	d0,$100(a0)
.eir
	* CIA timer based forwarding setup done.

	* Next up, update HippoPort contents for any external users.

	move.b	mainvolume+1(a5),hippoport+hip_mainvolume(a5)
	move.b	playertype+1(a5),hippoport+hip_playertype(a5)

	cmp	#pt_multi,playertype(a5)
	bne.b	.por

	* PS3M data update
	move.l	ps3m_buff1(a5),a0
	move.l	(a0),hippoport+hip_ps3mleft(a5)
	move.l	ps3m_buff2(a5),a0
	move.l	(a0),hippoport+hip_ps3mright(a5)
	move.l	ps3m_playpos(a5),a0
	move.l	(a0),d0
	lsr.l	#8,d0
	move.l	d0,hippoport+hip_ps3moffs(a5)
	move.l	ps3m_buffSizeMask(a5),a0
	move.l	(a0),hippoport+hip_ps3mmaxoffs(a5)
.por
.nop
.notPlaying4
	* Final piece of data
	move.b	playing(a5),hippoport+hip_play(a5)

	popm	d2-d7/a2-a6
	moveq	#0,d0
	rts


* d1 = signal number sent to the main task
signalit
	move.l	owntask+var_b,a1
	moveq	#0,d0
	bset	d1,d0
	move.l	4.w,a6			
	jmp	_LVOSignal(a6)


******************************************************************************
*
* CIA timer interrupt
* Software interrupt
*
******************************************************************************

ciaserver
	dc.l	0,0
	dc.b	2
	dc.b	0	* prioriteetti
	dc.l	.intname2
	dc.l	softserver		* is_Data passed in a1
	dc.l	ciainterrupt

.intname2 dc.b	"HiP-CIA",0
 even

* cdtv-compatible CIA interrupt driver
* All this does is trigger the software interrupt so as not to disturb
* level 5 stuff, such as serial transfers.

ciainterrupt	
	push	a6
;	move.l	4.w,a6
	move.l	exeksi(pc),a6    * Probably faster compared to CHIP RAM access
	lob	Cause
	pop	a6
	moveq	#0,d0
	rts

exeksi	dc.l	0

softserver
	dc.l	0,0
	dc.b	2
	dc.b	0	* priority
	dc.l	.softintname
	dc.l	var_b		* is_Data passed in a1
	dc.l	softint     * code entry point

.softintname
	dc.b "HiP-SoftInt",0
 even

softint	
	* Do nothing if not playing
	tst.b	playing(a1)
	beq.b	.exit
	pushm	d2-d7/a0/a2-a4/a6
	move.l	a1,a5
	* Call the CIA replay routine if it's a non-AHI routine and AHI is not enabled
	move.l	playerbase(a5),a0	
	* AHI is active?
	tst.b	ahi_use_nyt(a5)
	beq.b	.noAHI
	* AHI is active, check if player supports it.
	move	p_liput(a0),d0
	and		#pf_ahi,d0
	bne.b	.yesAHI
	* Player is not AHI player. Can play music here.
.noAHI
	* Play music!
	jsr	p_play(a0)
.yesAHI
	popm	d2-d7/a0/a2-a4/a6
.exit	
	moveq	#0,d0
	rts




********************************************************************************
*** SECTION ********************************************************************
*
* ARexx support
*
********************************************************************************

******************************************************************************
*
* ARexx-toiminnot
*
******************************************************************************

rexxmessage
	pushm	all
	lea	rexxport(a5),a0
	lore	Exec,GetMsg
	move.l	d0,rexxmsg(a5)
	beq.b	.nomsg

	move.l	rexxmsg(a5),a1
	clr.l	rm_Result1(a5)
	clr.l	rm_Result2(a5)
	clr.l	rexxresult(a5)

	lea	rm_Args(a1),a4
	tst.l	(a4)
	beq.b	.end

 if DEBUG
	move.l	(a4),d0
	DPRINT	"ARexx: %s"
 endif

	lea	.komennot-4(pc),a3
.loop	addq.l	#4,a3
	tst	(a3)
	beq.b	.end
	move.l	a3,a2
	add	(a2),a2
	move.l	a2,a0
	lore	Rexx,Strlen
	move.l	d0,d3
	move.l	a2,a0
	move.l	(a4),a1
	lob	StrcmpN
	tst.l	d0
	bne.b	.loop
	move.l	(a4),a1
	add.l	d3,a1
	cmp.b	#' ',(a1)+	* Onko komennon j‰lkeen SPACE?
	seq	d0		* Lippu p‰‰lle jos on.
	move.l	a3,a0
	addq	#2,a0
	add	(a0),a0
	pushm	all
	jsr	(a0)
	popm	all
.end

	move.l	rexxmsg(a5),a1
	move.l	rexxresult(a5),rm_Result2(a1)
	lore	Exec,ReplyMsg
.nomsg
	popm	all
	rts	returnmsg

.komennot
	dr	.playt,.playr
	dr	.cleart,clearlist
	dr	.contt,actionContinue
	dr	.stopt,actionStopButton
	dr	.ejectt,rbutton4
	dr	.lprgt,.loadprg
	dr	.addt,.add
	dr	.delt,rbutton8
	dr	.volt,.volume
	dr	.rewt,rbutton_kela1
	dr	.ffwdt,rbutton_kela2
	dr	.movet,.move
	dr	.sortt,._rsort
	dr	.insertt,.insert
	dr	.quitt,.quit
	; Put these before "CHOOSE" since matcher will 
	; get the shorter one otherwise
	dr	.chooseNextT,.chooseNext
	dr	.choosePrevT,.choosePrev
	dr	.chooset,.choose
	dr	.psongt,.playsong
	dr	.gett,.get
	dr	.randt,.playrand
	dr	.hidet,.hide
	dr	.sizet,.size
	dr	.pbsct,.setpubscreen
	dr	.toutt,.timeout
	dr	.ps3m1,.ps3mmode
	dr	.ps3m2,.ps3mboost
	dr	.ps3m3,.ps3mrate
	dr	.loadp,.loadprefs
	dr	.sampt,rbutton10b
	dr	.listmodet,toggleListMode
	dr	.favoritet,.toggleFavorite
	dc 	0 ; END

.playt	dc.b	"PLAY",0
.cleart	dc.b	"CLEAR",0
.contt	dc.b	"CONT",0
.stopt	dc.b	"STOP",0
.ejectt	dc.b	"EJECT",0
.lprgt	dc.b	"LOADPRG",0
.addt	dc.b	"ADD",0
.delt	dc.b	"DEL",0
.volt	dc.b	"VOLUME",0
.rewt	dc.b	"REW",0
.ffwdt	dc.b	"FFWD",0
.movet	dc.b	"MOVE",0
.sortt	dc.b	"SORT",0
.insertt dc.b	"INSERT",0
.quitt	dc.b	"QUIT",0
.chooset dc.b	"CHOOSE",0
.chooseNextT dc.b "CHOOSENEXT",0
.choosePrevT dc.b "CHOOSEPREV",0
.psongt	dc.b	"SONGPLAY",0
.gett	dc.b	"GET",0
.randt	dc.b	"RANDPLAY",0
.hidet	dc.b	"HIDE",0
.sizet	dc.b	"ZIP",0
.pbsct	dc.b	"PUBSCREEN",0
.toutt	dc.b	"TIMEOUT",0
.ps3m1	dc.b	"PS3MMODE",0
.ps3m2	dc.b	"PS3MBOOST",0
.ps3m3	dc.b	"PS3MRATE",0
.loadp	dc.b	"LOADPREFS",0
.sampt	dc.b	"SAMPLES",0
.listmodet dc.b "TOGGLEMODE",0
.favoritet dc.b "FAVORITE",0
 even

._rsort	jmp	rsort

*** PLAY
.playr	
	tst.b	d0
	beq.w	rbutton1
	move.l	a1,sv_argvArray+4(a5)
	clr.l	sv_argvArray+8(a5)
	bsr.w	clearlist
	bra.w	komentojono

*** LOADPRG
.loadprg
	tst.b	d0
	beq.w	rloadprog
	move.l	a1,d7
	bra.w	rloadprog2

*** QUIT
.quit	st	exitmainprogram(a5)
.exit	rts


*** ADD	
.add	
	printt "TODO: switch to normal list mode"

	tst.b	d0
	beq.w	rbutton7

.add2	cmp.l	#MAX_MODULES,modamount(a5)	* Ei enemp‰‰ kuin ~16000
	bhs.b	.exit

	move.l	a1,a2
.fe	tst.b	(a2)+
	bne.b	.fe
	sub.l	a1,a2
	add	#l_size,a2
	move.l	a2,d0			* nimen pituus

	move.l	#MEMF_CLEAR,d1		* varataan muistia
	jsr	getmem
	beq.b	.exit
	move.l	d0,a3

	lea	l_filename(a3),a2
	move.l	a2,a0
.cp1	move.b	(a1)+,(a2)+
	bne.b	.cp1

	move.l	a0,a1
	move.l	a2,a0
	bsr.w	nimenalku
	move.l	a0,l_nameaddr(a3)	* pelk‰n nimen osoite

	bsr.w	addfile
	bsr.w	listChanged

	tst.l	chosenmodule(a5)
	bpl.b	.ee
	clr.l	chosenmodule(a5)	* moduuliksi eka jos ei ennest‰‰n
.ee	
	bsr.w	forceRefreshList
	rts


*** INSERT
.insert
	printt "TODO: switch to normal list mode"

	tst.b	d0
	beq.w	rinsert
	bsr.w	rinsert2
	bsr.b	.add2
	clr.b	filereqmode(a5)
	rts


*** MOVE
.move
	printt "TODO: switch to normal list mode"

	bsr.w	a2i
	move	d0,-(sp)
	jsr	rmove
	move	(sp)+,d0
	subq	#1,d0
	bsr.b	.choo
	jmp	rmove	


*** CHOOSE
.choose
	bsr.w	a2i
	subq.l	#1,d0
	bsr.b	.choo
	bra.w	resh

*** valitaan d0:ssa olevan numeron tiedosto
.choo
	move.l	d0,chosenmodule(a5)
	cmp.l	modamount(a5),d0
	blo.b	.chosenOk
	move.l	modamount(a5),chosenmodule(a5)
	subq.l	#1,chosenmodule(a5)
	bpl.b	.chosenOk
	clr.l	chosenmodule(a5)
.chosenOk
	rts

.chooseNext
	moveq	#0,d4	* rawkey modifier, no shift
	jmp	lista_alas
.choosePrev	
	moveq	#0,d4	* rawkey modifier, no shift
	jmp	lista_ylos
	
*** VOLUME
.volume
	bsr.w	a2i
	bra.w	volumerefresh


*** PLAYSONG
.playsong
	bsr.w	a2i
	subq	#1,d0
	move	d0,songnumber(a5)
	moveq	#0,d1
	jmp	songSkip
	
	

*** PLAYRAND
.playrand
	jmp	soitamodi_random
	

*** HIDE
.hide
	bsr.w	a2i		* d0 = 0 tai 1
	tst.b	d0
	beq.b	.hide_hide
	tst.b	win(a5)
	beq.b	.hide1
	rts
.hide_hide
	tst.b	win(a5)
	bne.b	.hide1
	rts
.hide1	move	#$25,rawkeyinput(a5)
.hide2
	move.b	rawKeySignal(a5),d1
	bra.w	signalit


*** SIZE

;	move.l	windowbase(a5),a0	* Kick2.0+
;	lore	Intui,ZipWindow
	
.size
	bsr.w	a2i
	tst.b	d0
	beq.b	.size_small
	tst.b	kokolippu(a5)
	beq.b	.size1
	rts
.size_small
	tst.b	kokolippu(a5)
	bne.b	.size1
	rts
.size1	
	tst.b	uusikick(a5)
	beq.b	.oldk
	move.l	windowbase(a5),a0	* Kick2.0+
;	lore	Intui,ZipWindow
	move.l	_IntuiBase(a5),a6
	jmp	_LVOZipWindow(a6)

.oldk	jsr	sulje_ikkuna		* kick1.2+
;	bra.w	avaa_ikkuna
	jmp	avaa_ikkuna


*** PUBSCREEN
.setpubscreen
	tst.b	uusikick(a5)
	bne.b	.nwkd
	rts

.nwkd	bsr.b	.prefspo
	lea	pubscreen(a5),a0
.c123	move.b	(a1)+,(a0)+
	bne.b	.c123
	st	newpubscreen(a5)
	move.b	ownsignal2(a5),d1
	bra.w	signalit

*** TIMEOUT
.timeout
	bsr.b	.prefspo
	bsr.w	a2i
	cmp	#600,d0
	bls.b	.ok32
	move	#600,d0
.ok32	move	d0,timeout(a5)
	bra.w	sliderit

*** PS3M
.ps3mmode
	bsr.b	.prefspo
	bsr.w	a2i
	move.b	d0,s3mmode2(a5)
	rts

.ps3mboost
	bsr.b	.prefspo
	bsr.w	a2i
	cmp.b	#8,d0
	bls.b	.ok12
	moveq	#8,d0
.ok12	move.b	d0,s3mmode3(a5)
	bra.w	sliderit

.ps3mrate
	bsr.b	.prefspo
	bsr.w	a2i
	cmp.l	#5000,d0
	bhs.b	.ok55
	move.l	#5000,d0
.ok55	cmp.l	#58000,d0
	bls.b	.ok76
	move.l	#58000,d0
.ok76	move.l	d0,mixirate(a5)
	bra.w	sliderit

.prefspo
	push	a1
	bsr.w	sulje_prefs
	pop	a1
	rts



**** LOADPREFS
* This probably doesn't work perfectly
.loadprefs
	push	a1
	jsr	rbutton4		* eject
	bsr.w	clearlist
	;bsr.w	sulje_quad
	bsr.w	stopScopeTasks
	bsr.b	.prefspo
	jsr	sulje_ikkuna
	jsr	rem_inputhandler
	pop	d7
	bsr.w	loadprefs2
	jsr	setboxy
	jsr	init_inputhandler
;	tst.b	quadon(a5)			* avataanko scope?
;	beq.b	.q
;	bsr.w	start_quad
;.q
	not.b	kokolippu(a5)
	jmp	avaa_ikkuna

.toggleFavorite
	bra.w	toggleFavoriteStatusForCurrentModule

* GET:
* 	current song
* 	chosenmodule
*	subsongs
*	play on/off
*	num files
*	current songpos
*	max songpos
*	playingmodule
*	modulename
*	moduletype
*	duration
*	hide status
*	app version
*	volume

.get	move.b	(a1)+,d0
	lsl.l	#8,d0
	move.b	(a1)+,d0
	lsl.l	#8,d0
	move.b	(a1)+,d0
	lsl.l	#8,d0
	move.b	(a1)+,d0

	lea	.getlist-2(pC),a1
.getloop
	addq.l	#2,a1
	tst.l	(a1)
	beq.b	.getx
	cmp.l	(a1)+,d0
	bne.b	.getloop
	add	(a1),a1
	jsr	(a1)
.getx	rts

.getlist
	dc.l	"PLAY"
	dr	.getplay
	dc.l	"CFIL"
	dr	.getcfil
	dc.l	"NFIL"
	dr	.getnfil
	dc.l	"CSNG"
	dr	.getcsng
	dc.l	"NSNG"
	dr	.getnsng
	dc.l	"CSPO"
	dr	.getcspo
	dc.l	"MSPO"
	dr	.getmspo
	dc.l	"CURR"
	dr	.getcurrent
	dc.l	"NAME"
	dr	.getname
	dc.l	"TYPE"
	dr	.gettype
	dc.l	"CNAM"
	dr	.currname
	dc.l	"FNAM"
	dr	.fullname
	dc.l	"COMM"
	dr	.getcomment
	dc.l	"SIZE"
	dr	.getsize
	dc.l	"HIDS"
	dr	.hidestatus
	dc.l	"DURA"
	dr	.duration
	dc.l	"FILT"
	dr	.filter
	dc.l	"VERS"
	dr	.version
	dc.l	"VOLU"
	dr	.getVolume
	dc.l	0

.getplay
	moveq	#1,d0
	and.b	playing(a5),d0
	bra.w	i2amsg

.getcfil
	move.l	chosenmodule(a5),d0
	bmi.b	.getcfil0
	cmp.l	#PLAYING_MODULE_REMOVED,d0
	beq.b	.getcfil0
	addq.l	#1,d0
	bra.w	i2amsg2
.getcfil0
	moveq	#0,d0
	bra.w	i2amsg

.getnfil
	move.l	modamount(a5),d0
	bra.w	i2amsg2

.getcsng
	move	songnumber(a5),d0
	addq	#1,d0
	bra.w	i2amsg

.getnsng
	move	maxsongs(a5),d0
	addq	#1,d0
	bra.w	i2amsg

.getcspo
	move	pos_nykyinen(a5),d0
	bra.w	i2amsg

.getmspo
	move	pos_maksimi(a5),d0
	bra.w	i2amsg

.getname
	lea	modulename(a5),a2
	bra.w	str2msg

.gettype
	lea	moduletype(a5),a2
	bra.w	str2msg

.getcurrent
	move.l	playingmodule(a5),d0
	bmi.b	.getc0
	addq.l	#1,d0
	cmp.l	#PLAYING_MODULE_REMOVED+1,d0
	bne.w	i2amsg2
.getc0	moveq	#0,d0
	bra.w	i2amsg

.currname
	bsr.w	getcurrent
	bne.b	.curr0
	lea	.empty(pc),a2
	bra.w	str2msg
.curr0	lea	l_filename(a3),a2
	bra.w	str2msg

.fullname
	move.l	playingmodule(a5),d0
	bmi.b	.curr1
	cmp.l	#PLAYING_MODULE_REMOVED,d0
	bne.b	.curr2
.curr1	lea	.empty(pc),a2
	bra.w	str2msg	
.curr2	bsr.w	getcurrent2
	lea	l_filename(a3),a2
	bra.w	str2msg

.getcomment
	lea	filecomment(a5),a2
	bra.w	str2msg

.getsize
	move.l	modulelength(a5),d0
	add.l	tfmxsampleslen(a5),d0
	bra.b	i2amsg2

.duration
	cmp	#pt_prot,playertype(a5)
	beq.b	.d9	
	moveq	#0,d0
	bra.b	i2amsg2
.d9
	move	kokonaisaika(a5),d0
	mulu	#60,d0
	add	kokonaisaika+2(a5),d0
	bra.b	i2amsg2

.hidestatus
	moveq	#1,d0
	and.b	win(a5),d0
	eor.b	#1,d0
	bra.b	i2amsg

.filter
	btst	#1,$bfe001
	seq	d0
	and.l	#%1,d0
	bra.b	i2amsg

.getVolume
	moveq	#0,d0
	move	mainvolume(a5),d0
	bra.b	i2amsg

* provide version string
.version
	lea	-30(sp),sp
	lea	versionStringStart,a0
	lea	versionStringEnd-versionStringStart(a0),a1
	move.l 	sp,a2
.copy
	move.b	(a0)+,(a2)+
	cmp.l	a0,a1
	bne.b	.copy
	clr.b	(a2)
	move.l	sp,a2
	bsr.b	str2msg
	lea	30(sp),sp
	rts

.empty	dc	0

** a1:ssa oleva ascii-luku D0:aan
a2i	pushm	d1/a0/a6
	move.l	a1,a0
	lore	Rexx,CVa2i
	popm	d1/a0/a6
	rts

*** d0:ssa oleva luku rexxviestiksi
i2amsg	ext.l	d0
i2amsg2	pushm	d0/d1/a0/a1/a6
	moveq	#3,d1
	lore	Rexx,CVi2arg
	move.l	d0,rexxresult(a5)
	popm	d0/d1/a0/a1/a6
	rts

** a2:ssa oleva tekstinp‰tk‰ rexxviestiksi
str2msg	pushm	d0/d1/a0/a1/a6
	move.l	a2,a0
	lore	Rexx,Strlen
	move.l	a2,a0
	lob	CreateArgstring
	move.l	d0,rexxresult(a5)
	popm	d0/d1/a0/a1/a6
	rts




;	move.l	rm_Args(a1),a0	; test for different commands here!
;	bsr.w	CLI_Write	; you must parse the parameters yourself

;	move.l	_RexxSysLibBase(pc),a6
;	lea	ret_string(pc),a0
;	move.l	a0,a1
;.len	tst.b	(a1)+
;	bne.s	.len
;	move.l	a1,d0
;	sub.l	a0,d0
;	subq.l	#1,d0
;	jsr	_LVOCreateArgstring(a6)

;	move.l	4.w,a6
;	move.l	RexxMsg_Ptr,a1
;	clr.l	rm_Result1(a1)		; result1 (Include:rexx/error.i)
;				; reselt1=rc (a global arexx var)
;	clr.l	rm_Result2(a1)		; result2 (0 for no return argstring)
;	move.l	d0,rm_Result2(a1)	; result2 (result=your string)
				; result only accept if arexx contains
				; Options Results
;	jsr	_LVOReplyMsg(a6)


********************************************************************************
*** SECTION ********************************************************************
*
* Scopes
*
********************************************************************************
                              rsreset
s_global                      rs.l       1
s_quad_task                   rs.l       1
s_windowTitle                 rs.l      1
* Pointer to the running status flag
s_runningStatusAddr            rs.l      1
s_storedPositionAddr		rs.l 	1
s_newWindow                   rs.b       enw_SIZEOF
s_scopeWindowBase             rs.l       1
s_rastport3                   rs.l       1	
s_userport3                   rs.l       1
s_buffer0                     rs.l       1
s_buffer0w                    rs.w       1
s_buffer0h                    rs.w       1
s_quadmode                    rs.b       1
s_quadmode2                   rs.b       1
s_scopeDrawAreaWidth		rs.w 	1
s_scopeDrawAreaModulo		rs.w 	1
s_scopeDrawAreaWidthRequest   rs.w       1
s_scopeDrawAreaHeightRequest  rs.w       1
s_scopeDrawAreaHeight         rs.w       1
s_quadNoteScrollerLines       rs.w       1
s_quadNoteScrollerLinesHalf   rs.w       1
s_scopePreviousLeftEdge       rs.w       1
s_scopePreviousTopEdge        rs.w       1
s_scopePreviousWidth          rs.w       1
s_scopePreviousHeight         rs.w       1
s_scopePreviousPattPos        rs.w       1
s_scopePreviousSongPos        rs.w       1
s_omabitmap                   rs.b      bm_SIZEOF
s_buffer1                     rs.l       1
s_buffer2                     rs.l       1
s_draw1                       rs.l       1
s_draw2                       rs.l       1
* Triggered channel volumes for Protracker animated volume bars
s_patternScopeVolumes	      rs.w       4
                              ifne       FEATURE_FREQSCOPE
s_deltab1                     rs.l       1	
s_deltab2                     rs.l       1	
s_deltab3                     rs.l       1	
s_deltab4                     rs.l       1	
                              endif
                              ifne       FEATURE_SPECTRUMSCOPE
s_spectrumMemory              rs.l       1
s_spectrumVolumeTable         rs.l       1
s_spectrumMuluTable           rs.l       1
s_spectrumExpTable            rs.l       1
s_spectrumSineTable           rs.l       1
s_spectrumChannel1            rs.l       1
s_spectrumChannel2            rs.l       1
s_spectrumChannel3            rs.l       1
s_spectrumChannel4            rs.l       1
s_spectrumMixedData           rs.l       1
s_spectrumImagData            rs.l       1
s_spectrumInitialized         rs.w       1
                              endif

s_multab                      rs.w       256 * modulo multiplication table
s_scopeHorizontalBarTable     rs.b       512
s_mtab                        rs.b       64*256*2 * volume table for scopes
sizeof_scopeVars              rs.b       1

* Incoming volume values need to be validated or else there will
* be over indexing mayhem and memory corruption!
CLAMPVOL macro
	cmp	#$40,\1
	bls.b	*+4
	moveq	#$40,\1
	endm


* Structure to help task starting and stopping
    STRUCTURE ScopeTaskDefinition,0
        UWORD st_runningStatusOffset * Relative to a5
        UWORD st_prefsStatusOffset * Relative to a5+prefsdata
        UWORD st_taskOffset * Relative to a5
        UWORD st_entryPoint * Code start address relative offset
    LABEL ScopeTaskDefinition_SIZEOF

quadraScopeTaskDefinition
	dc.w	quadraScopeRunning
	dc.w	prefs_quadraScope
	dc.w	taskQuadraScope
	dr.w	quadraScopeEntry

quadraScopeFTaskDefinition
	dc.w	quadraScopeFRunning
	dc.w	prefs_quadraScopeF
	dc.w	taskQuadraScopeF
	dr.w	quadraScopeFEntry

hippoScopeTaskDefinition
	dc.w	hippoScopeRunning
	dc.w	prefs_hippoScope
	dc.w	taskHippoScope
	dr.w	hippoScopeEntry

patternScopeTaskDefinition
	dc.w	patternScopeRunning
	dc.w	prefs_patternScope
	dc.w	taskPatternScope
	dr.w	patternScopeEntry

spectrumScopeTaskDefinition
	dc.w	spectrumScopeRunning
	dc.w	prefs_spectrumScope
	dc.w	taskSpectrumScope
	dr.w	spectrumScopeEntry


* In:
*   a2 = Task name
*   a3 = Task structure
* Out:
*   d0 = 1: ok, 0: out of mem
initScopeTask:
	bsr.b	resetScopeTask

	* Initialize ln_Node
	move.b	#NT_TASK,LN_TYPE(a3)
	* Initial priority 0
	clr.b	LN_PRI(a3)
	move.l	a2,LN_NAME(a3)

	* Allocate stack mementry
	lea	.memList(pc),a0
	lore	Exec,AllocEntry
	* Sets bit 31 on failure
	tst.l	d0
	bmi.b	.fail

	* a1 = MemList
	move.l	d0,a1
	* a2 = allocated mem block
	move.l	ML_ME+ME_ADDR(a1),a2

	* Set stack pointers
	move.l	a2,TC_SPLOWER(a3)
	lea	3000(a2),a2
	move.l	a2,TC_SPUPPER(a3)
	move.l	a2,TC_SPREG(a3)

	* Create mementry list in task 
	lea	TC_MEMENTRY(a3),a0
	NEWLIST	a0

	* Add stack memory entry at a1 to the task mementry list,
	* to be freed on task exit.
	lob	AddHead

	moveq	#1,d0
.x	rts

.fail	
	moveq	#0,d0
	rts

.memList
	* reserve space for list node
	DS.B	LN_SIZE 	  
	* number of entries
	DC.W	1		
    	* entry #1 - stack space
	DC.L	MEMF_PUBLIC!MEMF_CLEAR
	DC.L	3000
	
* In:
*   a3 = Task structure
resetScopeTask
	* Reset task structure
	move.l	a3,a0
	moveq	#TC_SIZE-1,d0
.c	clr.b	(a0)+
	dbf	d0,.c
	rts

* In:
*  a4 = task definition
*  d7 = capability bits, pf_samplescope/pf_patternscope
startScopeTask:
	pushm	d2-d7/a2-a6
	* Check player caps, do not start
	* scope if not supported
;	move.l	playerbase(a5),d0
;	beq.b	.1
;	move.l	d0,a0
;	move	p_liput(a0),d0
;	and	d7,d0
;	beq.b	.x
;.1

	* Check if running already
	move	st_runningStatusOffset(a4),d7
	tst.b 	(a5,d7)
	bne.b	.x

	;DPRINT	"startScopeTask"

	* Get task structure
	move	st_taskOffset(a4),d0
	lea	(a5,d0),a3
	lea	.tn(pc),a2
	bsr.w	initScopeTask

	* Mark it as running
	move.b	#RUNNING_YES,(a5,d7)

	* Start
	move.l	a3,a1
	* initialPC
	lea	st_entryPoint(a4),a2
	add	(a2),a2
	* finalPC (system default)
	sub.l a3,a3		 
	lore	Exec,AddTask

	* Update prefs status as well
	move	st_prefsStatusOffset(a4),d0
	lea	prefsdata(a5),a0
	st	(a0,d0)
.x
	popm	d2-d7/a2-a6
	rts

.tn	dc.b	"HiP-Scope",0
	even

* Sets up scopes open or close according to prefs.
startAndStopScopeTasks
	DPRINT	"startAndStopScopeTasks"
	tst.b	prefsdata+prefs_quadraScope(a5)
	beq.b	.1
	bsr.b	startQuadraScopeTask
	bra.b	.2
.1	bsr.b	stopQuadraScopeTask
.2
	tst.b	prefsdata+prefs_quadraScopeF(a5)
	beq.b	.3
	bsr.b	startQuadraScopeFTask
	bra.b	.4
.3	bsr.b	stopQuadraScopeFTask	
.4
	tst.b	prefsdata+prefs_hippoScope(a5)
	beq.b	.5
	bsr.b	startHippoScopeTask
	bra.b	.6
.5	bsr.b	stopHippoScopeTask	
.6
	tst.b	prefsdata+prefs_patternScope(a5)
	beq.b	.7
	bsr.b	startPatternScopeTask
	bra.b	.8
.7	bsr.b	stopPatternScopeTask	
.8
	tst.b	prefsdata+prefs_spectrumScope(a5)
	beq.b	.9
	bsr.b	startSpectrumScopeTask
	bra.b	.10
.9	bsr.w	stopSpectrumScopeTask	
.10
	rts

startQuadraScopeTask
	;DPRINT	"startQuadraScopeTask"
	lea	quadraScopeTaskDefinition(pc),a4
	bra.w	startScopeTask

stopQuadraScopeTask
	;DPRINT	"stopQuadraScopeTask"
	lea	quadraScopeTaskDefinition(pc),a4
	bra.w	stopScopeTask

restartQuadraScopeTask
	tst.b	quadraScopeRunning(a5)
	beq.b	.x
	bsr.b	stopQuadraScopeTask
	bsr.b	startQuadraScopeTask
.x	rts	

startQuadraScopeFTask
	;DPRINT	"startQuadraScopeFTask"
	lea	quadraScopeFTaskDefinition(pc),a4
	bra.w	startScopeTask

stopQuadraScopeFTask
	;DPRINT	"stopQuadraScopeFTask"
	lea	quadraScopeFTaskDefinition(pc),a4
	bra.w	stopScopeTask

restartQuadraScopeFTask
	tst.b	quadraScopeFRunning(a5)
	beq.b	.x
	bsr.b	stopQuadraScopeFTask
	bsr.b	startQuadraScopeFTask
.x	rts	

startHippoScopeTask
	;DPRINT	"startHippoScopeTask"
	lea	hippoScopeTaskDefinition(pc),a4
	bra.w	startScopeTask

stopHippoScopeTask
	;DPRINT	"stopHippoScopeTask"
	lea	hippoScopeTaskDefinition(pc),a4
	bra.w	stopScopeTask

restartHippoScopeTask
	tst.b	hippoScopeRunning(a5)
	beq.b	.x
	bsr.b	stopHippoScopeTask
	bsr.b	startHippoScopeTask
.x	rts	

startPatternScopeTask
	;DPRINT	"startPatternScopeTask"
	bsr.w	getScopeMiniFontIfNeeded
	lea	patternScopeTaskDefinition(pc),a4
	bra.w	startScopeTask

stopPatternScopeTask
	;DPRINT	"stopPatternScopeTask"
	lea	patternScopeTaskDefinition(pc),a4
	bra.b	stopScopeTask

restartPatternScopeTask
	tst.b	patternScopeRunning(a5)
	beq.b	.x
	bsr.b	stopPatternScopeTask
	bsr.b	startPatternScopeTask
.x	rts	

startSpectrumScopeTask
	;DPRINT	"startSpectrumScopeTask"

	move.l	(a5),a6
	tst.l	_FFPBase(a5)
	bne.b	.1
	lea	_FFPName,a1
	lob	OldOpenLibrary
	move.l	d0,_FFPBase(a5)
	beq.b	.fail
.1
	tst.l	_MTBase(a5)
	bne.b	.2
	lea	_MTName,a1
	lob  	OldOpenLibrary
	move.l	d0,_MTBase(a5)
	bne.b	.2
.fail
	rts
.2
	lea	spectrumScopeTaskDefinition(pc),a4
	bra.w	startScopeTask
		
stopSpectrumScopeTask
	;DPRINT	"stopSpectrumScopeTask"
	lea	spectrumScopeTaskDefinition(pc),a4
	bra.b	stopScopeTask

restartSpectrumScopeTask
	tst.b	spectrumScopeRunning(a5)
	beq.b	.x
	bsr.b	stopSpectrumScopeTask
	bsr.b	startSpectrumScopeTask
.x	rts	

stopScopeTasks
	DPRINT	"stopScopeTasks"
	bsr.w	stopQuadraScopeTask
	bsr.w	stopQuadraScopeFTask
	bsr.w	stopHippoScopeTask
	bsr.b	stopPatternScopeTask
	bra.b	stopSpectrumScopeTask

stopScopeTask
	* Check if running already
	move	st_runningStatusOffset(a4),d7
	tst.b 	(a5,d7)
	beq.w	.x

	;DPRINT	"stopScopeTask"

	* Get task structure
	move	st_taskOffset(a4),d0
	lea	(a5,d0),a1

	* Raise task priority to normal
	* so it will exit promptly
	moveq	#0,d0
	lore	Exec,SetTaskPri

	* Flag indicates scope should quit
	move.b	#RUNNING_SHUT_IT,(a5,d7)
.loop
	tst.b 	(a5,d7)
	beq.b	.z
	jsr	smallDelay
	bra.b	.loop
.z

;; Display some performance measurements when scope is stopped.
 if DEBUG
	move.l	scopeStopTimeSecs(a5),d0
	sub.l	scopeStartTimeSecs(a5),d0
	bne.b	.zz
	moveq	#1,d0
.zz
	move.l	scopeFrameCounter(a5),d1
	move.l	d1,d2
	divu	d0,d2
	move.l	d2,d3
	ext.l	d2
	swap	d3
	ext.l	d3

	move.l	scopeRenderTime(a5),d4
	move.l	scopeFrameCounter(a5),d5
	bne.b	.zzz
	moveq	#1,d5
.zzz	
 	divu	d5,d4
	ext.l	d4
	tst.b	uusikick(a5)
	bne.b	.zzzz
	moveq	#-1,d4
.zzzz
	DPRINT	"Time=%lds frames=%ld fps=%ld.%ld avg=%ldms"
 endif
.x	rts


* Out:
*   Z not set if any of the scopes is running
anyScopeRunning
	move.b	quadraScopeRunning(a5),d0
	or.b	quadraScopeFRunning(a5),d0
	or.b	hippoScopeRunning(a5),d0
	or.b	patternScopeRunning(a5),d0
	or.b	spectrumScopeRunning(a5),d0
	rts

toggleScopes
	DPRINT	"toggleScopes"
	lea	scopeToggleTable(a5),a2
	* Is any scope running?
	bsr.b	anyScopeRunning
	beq.b	.start
	* Preserve running statuses and stop all
	move.b	quadraScopeRunning(a5),(a2)+
	move.b	quadraScopeFRunning(a5),(a2)+
	move.b	hippoScopeRunning(a5),(a2)+
	move.b	patternScopeRunning(a5),(a2)+
	move.b	spectrumScopeRunning(a5),(a2)+
	bra.w	stopScopeTasks
	
.start
	* Start scopes that were toggled off.
	* If none were toggled off, start the default
	* one. Test 5 bytes:
	tst.b	(a2)
	bne.b	.some
	tst.b	1(a2)
	bne.b	.some
	tst.b	2(a2)
	bne.b	.some
	tst.b	3(a2)
	bne.b	.some
	tst.b	4(a2)
	bne.b	.some
	* Enable the 1st one if all are off
	st	(a2)
.some
	tst.b	(a2)+
	beq.b	.a
	bsr.w	startQuadraScopeTask
.a	tst.b	(a2)+
	beq.b	.b
	bsr.w	startQuadraScopeFTask
.b	tst.b	(a2)+
	beq.b	.c
	bsr.w	startHippoScopeTask
.c	tst.b	(a2)+
	beq.b	.d
	bsr.w	startPatternScopeTask
.d	tst.b	(a2)+
	beq.b	.e
	bsr.w	startSpectrumScopeTask
.e
	* Make prefs window show the correct status
	bsr.b	updateScopeStatusesToPrefs
	bra.w	updateprefs

* Update the prefs scope toggle statuses to match
* actual runtime state.
updateScopeStatusesToPrefs
	tst.b	quadraScopeRunning(a5)
	sne	prefsdata+prefs_quadraScope(a5)
	tst.b	quadraScopeFRunning(a5)
	sne	prefsdata+prefs_quadraScopeF(a5)
	tst.b	hippoScopeRunning(a5)
	sne	prefsdata+prefs_hippoScope(a5)
	tst.b	patternScopeRunning(a5)
	sne	prefsdata+prefs_patternScope(a5)
	tst.b	spectrumScopeRunning(a5)
	sne	prefsdata+prefs_spectrumScope(a5)
	rts


*******************************************************************************
* Scoperutiinit
*******************************************************************************
wflags3 set WFLG_SMART_REFRESH!WFLG_DRAGBAR!WFLG_CLOSEGADGET!WFLG_DEPTHGADGET
wflags3 set wflags3!WFLG_RMBTRAP
idcmpflags3 = IDCMP_CLOSEWINDOW!IDCMP_MOUSEBUTTONS

; These could be useful to detect window changes but they don't
; seem to work on kick1.3 similarly as on kick3.0.
;!IDCMP_NEWSIZE!IDCMP_CHANGEWINDOW!IDCMP_REFRESHWINDOW

QUADMODE2_QUADRASCOPE = 0
QUADMODE2_QUADRASCOPE_BARS = 1
QUADMODE2_HIPPOSCOPE = 2
QUADMODE2_HIPPOSCOPE_BARS = 3
QUADMODE2_FREQANALYZER = 4
QUADMODE2_FREQANALYZER_BARS = 5
QUADMODE2_PATTERNSCOPE = 6
QUADMODE2_PATTERNSCOPE_BARS = 7
QUADMODE2_FQUADRASCOPE = 8
QUADMODE2_FQUADRASCOPE_BARS = 9
QUADMODE2_PATTERNSCOPEXL = 10
QUADMODE2_PATTERNSCOPEXL_BARS = 11

SCOPE_DRAW_AREA_WIDTH_DEFAULT = 320
SCOPE_DRAW_AREA_HEIGHT_DEFAULT = 64
SCOPE_DRAW_AREA_HEIGHT_DOUBLE = 2*64

* If more channels than defined here,
* switch to small font.
SCOPE_SMALL_FONT_CHANNEL_LIMIT = 8

; DPRINT can't be used as scope is now a task,
; DPRINT uses dos.library which is not allowed.
SDPRINT macro

	endm

* Scope task entry points:

quadraScopeEntry
	lea	var_b,a5
	move	#quadraScopeRunning,d6
	moveq	#QUADMODE_QUADRASCOPE,d7
	move.b	#$80,d0
	and.b	prefsdata+prefs_quadraScopeBars(a5),d0
	or.b	d0,d7
	
	lea	.t(pc),a3
	lea	prefsdata+prefs_quadraScopePos(a5),a2
	bra.w	scopeEntry

.t	dc.b	"QuadraScope",0
 even

quadraScopeFEntry
	lea	var_b,a5
	move	#quadraScopeFRunning,d6
	moveq	#QUADMODE_FQUADRASCOPE,d7
	move.b	#$80,d0
	and.b	prefsdata+prefs_quadraScopeFBars(a5),d0
	or.b	d0,d7

	lea	.t(pc),a3
	lea	prefsdata+prefs_quadraScopeFPos(a5),a2
	bra.w	scopeEntry

.t	dc.b	"Filled QuadraScope",0
 even

hippoScopeEntry
	lea	var_b,a5
	move	#hippoScopeRunning,d6
	moveq	#QUADMODE_HIPPOSCOPE,d7
	move.b	#$80,d0
	and.b	prefsdata+prefs_hippoScopeBars(a5),d0
	or.b	d0,d7

	lea	.t(pc),a3
	lea	prefsdata+prefs_hippoScopePos(a5),a2
	bra.b	scopeEntry

.t	dc.b	"HippoScope",0
 even

patternScopeEntry
	lea	var_b,a5
	move	#patternScopeRunning,d6
	moveq	#QUADMODE_PATTERNSCOPE,d7
	tst.b	prefsdata+prefs_patternScopeXL(a5)
	beq.b	.1
	moveq	#QUADMODE_PATTERNSCOPEXL,d7
.1
	
	lea	.t(pc),a3
	lea	prefsdata+prefs_patternScopePos(a5),a2
	bra.b	scopeEntry

.t	dc.b	"PatternScope",0
 even

spectrumScopeEntry
	lea	var_b,a5
	move	#spectrumScopeRunning,d6
	moveq	#QUADMODE_FREQANALYZER,d7
	move.b	#$80,d0
	and.b	prefsdata+prefs_spectrumScopeBars(a5),d0
	or.b	d0,d7

	lea	.t(pc),a3
	lea	prefsdata+prefs_spectrumScopePos(a5),a2
	bra.b	scopeEntry

.t	dc.b	"SpectrumScope",0
 even

* Main scope task entry point
* In:
*   d6 = Offset to scope running flag 
*   d7 = operating mode
*   a2 = Address to load-from and store-to the window position
*   a3 = window title
*   a5 = global variables
scopeEntry:
	move.l	(a5),a6
	SDPRINT	"Scope task started"

	* Allocate local state variables
	move.l	#sizeof_scopeVars,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	jsr	getmem
	bne.b	.gotMem
	* Quit with error
	lea	memerror_t(pc),a1
	bra.w	request
.gotMem
	move.l	d0,a4
	move.l	a5,s_global(a4)

	* Store address for the running status flag to check and pass shutdown info
	pea	(a5,d6)
	move.l	(sp)+,s_runningStatusAddr(a4)
	* Store requested operating mode
	move.b	d7,s_quadmode(a4)
	* Store window position on exit to this address
	move.l	a2,s_storedPositionAddr(a4)
	* Window title should be set to this
	move.l	a3,s_windowTitle(a4)

	sub.l	a1,a1
	lore	Exec,FindTask
	move.l	d0,s_quad_task(a4)

* Modulo multab 
	lea	s_multab(a4),a0
	moveq	#0,d0
.mu	move	d0,(a0)+
	add	#40,d0
	cmp	#40*256,d0
	bne.b	.mu

	;clr.l	s_mtab(a4)
	clr.l	s_buffer0(a4)
  ifne FEATURE_FREQSCOPE
	clr.l	s_deltab1(a4)
  endif

	move	#SCOPE_DRAW_AREA_WIDTH_DEFAULT,s_scopeDrawAreaWidth(a4) 
	move	#SCOPE_DRAW_AREA_WIDTH_DEFAULT/8,s_scopeDrawAreaModulo(a4)
	move	#SCOPE_DRAW_AREA_HEIGHT_DEFAULT,s_scopeDrawAreaHeight(a4)


 if DEBUG
	moveq	#0,d0 
	move.b	s_quadmode(a4),d0
	SDPRINT	"Quad mode: %lx"
 endif
	* This creates a jumptable compatible value out of quadmode,
	* where bit 8 indicates "bars enabled"
	move.b	s_quadmode(a4),d0
	moveq	#$f,d1
	and.b		d0,d1
	add.b	d1,d1
	tst.b	d0
	bpl.b	.e
	addq.b	#1,d1
.e	move.b	d1,s_quadmode2(a4)	* 0-9

	moveq	#0,d0
	move.b	s_quadmode2(a4),d0
	lsl	#1,d0
	jmp	.t(pc,d0)
.t	
	bra.b	.1		* quadrascope
	bra.b	.3		* quadrascope bars
	bra.b	.2		* hipposcope 
	bra.b	.4		* hipposcope bars
	bra.b	.5		* freq. analyzer
	bra.b	.6		* freq. analyzer bars
	bra.b	.patternScopeNormal	* patternscope
	bra.b	.patternScopeNormalBars	* patternscope bars (ei oo!)
	bra.b	.7		* filled quadrascope
	bra.b	.8		* filled quadrascope & bars
	bra.b	.patternScopeXL	* patternscope xl
	bra.b	.patternScopeXLBars	* patternscope xl bars (no bars available though)


.7	moveq	#-1,d7
	bra.b	.11
.8	moveq	#-1,d7
	bra.b	.33

* Quadrascope
.1	moveq	#0,d7
.11	
	bsr.w	voltab
	bra.b	.cont

* Hipposcope
.2
	bsr.w	voltab2
	bra.b	.cont


.3	moveq	#0,d7
.33
	bsr.w	voltab

.wo	
	bsr.w	makeScopeHorizontalBars		* tehd‰‰n palkkitaulu
	bra.b	.cont


.4
	bsr.w	voltab2
	bra.b	.wo

.5	
  ifne FEATURE_FREQSCOPE
	bsr.w	voltab3
	bsr.b	.delt
	beq.w	.memer
 endif
 ifne FEATURE_SPECTRUMSCOPE
	jsr	spectrumInitialize
	beq.w	.memer
 endif
	bra.b	.cont

  ifne FEATURE_FREQSCOPE 
.delt	move.l	#(256+32)*4,d0
	move.l	#MEMF_CLEAR,d1
	jsr	getmem
	move.l	d0,s_deltab1(a4)
	beq.b	.r
	add.l	#256+32,d0
	move.l	d0,s_deltab2(a4)
	add.l	#256+32,d0
	move.l	d0,s_deltab3(a4)
	add.l	#256+32,d0
	move.l	d0,s_deltab4(a4)
.r	rts
  endif

.6	
  ifne FEATURE_FREQSCOPE 
	bsr.w	voltab3
	bsr.b	.delt
	beq.w	.memer
  endif
  if FEATURE_SPECTRUMSCOPE
   	jsr	spectrumInitialize
	beq.w	.memer
  endif
	bra.b	.wo * go to bar init

.patternScopeNormal
.patternScopeNormalBars
	* Prevent use of _BARS enumeration in quadmode2,
	* makes things easier. 
	move.b	#QUADMODE2_PATTERNSCOPE,s_quadmode2(a4)
	SDPRINT	"Patternscope NORMAL"
	bra.b	.cont
.patternScopeXL
.patternScopeXLBars
	move.b	#QUADMODE2_PATTERNSCOPEXL,s_quadmode2(a4)
	SDPRINT	"Patternscope XL"
.cont

	* Start with no size request active.
	move	s_scopeDrawAreaWidth(a4),s_scopeDrawAreaWidthRequest(a4)
	move	s_scopeDrawAreaHeight(a4),s_scopeDrawAreaHeightRequest(a4)
		
	* lines count for patternscope, 8px high rows
	move	s_scopeDrawAreaHeight(a4),d0
	lsr	#3,d0 
	move	d0,s_quadNoteScrollerLines(a4)
	lsr	#1,d0
	move	d0,s_quadNoteScrollerLinesHalf(a4)

	move.l	_IntuiBase(a5),a6
	
	* Copy new window structure for modifications
	lea	winstruc3,a2
	lea	s_newWindow(a4),a1
	move.l	a1,a0
	moveq	#enw_SIZEOF-1,d0
.copy	move.b	(a2)+,(a1)+
	dbf	d0,.copy

	* Restore top/left to some previous used value
	move.l	s_storedPositionAddr(a4),a1
	move.l	(a1),(a0)

	move	quadWindowHeightOriginal(a5),d0
	add	s_scopeDrawAreaHeight(a4),d0
	move	d0,nw_Height(a0)

	move	wbleveys(a5),d0		* WB:n leveys
	move	(a0),d1			* Ikkunan x-paikka
	add	4(a0),d1		* Ikkunan oikea laita
	cmp	d0,d1
	bls.b	.ok1
	sub	4(a0),d0	* Jos ei mahdu ruudulle, laitetaan
	move	d0,(a0)		* mahdollisimman oikealle
.ok1	move	wbkorkeus(a5),d0	* WB:n korkeus
	move	2(a0),d1		* Ikkunan y-paikka
	add	6(a0),d1		* Ikkunan oikea laita
	cmp	d0,d1
	bls.b	.ok2
	sub	6(a0),d0	* Jos ei mahdu ruudulle, laitetaan
	move	d0,2(a0)	* mahdollisimman alas
.ok2
	lob	OpenWindow
	move.l	d0,s_scopeWindowBase(a4)
	bne.b	.ok3
	lea	windowerr_t(pc),a1
.me	bsr.w	request
	bra.w	qexit

.memer	lea	memerror_t(pc),a1
	bra.b	.me

.ok3
	move.l	d0,a0
	move.l	wd_RPort(a0),s_rastport3(a4)
	move.l	wd_UserPort(a0),s_userport3(a4)
	
	move.l	s_windowTitle(a4),a1
	lea	scrtit,a2
	lore	Intui,SetWindowTitles

	move.l	_GFXBase(a5),a6
	move.l	s_rastport3(a4),a1
	move.l	pen_1(a5),d0
	lob	SetAPen

	move.l	s_scopeWindowBase(a4),a0 
	move	wd_LeftEdge(a0),s_scopePreviousLeftEdge(a4)
	move	wd_TopEdge(a0),s_scopePreviousTopEdge(a4)
	move	wd_Width(a0),s_scopePreviousWidth(a4)
	move	wd_Height(a0),s_scopePreviousHeight(a4)

	bsr.w	drawScopeWindowDecorations
	bsr.w	initScopeBitmaps
	beq.b	.memer

; TEST! OK

	* State flag indicating whether scope has been cleared
	moveq	#0,d7
	* State flag indicating font request has been shown 
	* Up bit for patternscope
	moveq	#0,d6	
	bsr.w	patternScopeIsActive
	bne.b	.noPatts
	SDPRINT	"Patternscope active"
	st	d6
.noPatts

	* Set to non-zero if LMB is pressed
	move.b	scopeManualActivation(a5),d5
	jsr	printHippoScopeWindow	

;; Scope performance measurements
 if DEBUG
	lea	scopeStartTimeSecs(a5),a0
	lea	scopeStartTimeMicros(a5),a1
	lore	Intui,CurrentTime
	clr.l	scopeFrameCounter(a5)
	clr.l scopeRenderTime(a5)
 endif

	; Ready to run	
	move.l	s_quad_task(a4),a1
	moveq	#-30,d0				* Prioriteetti 0:sta -30:een
	lore	Exec,SetTaskPri

*********************************************************************
* Scope main loop
*********************************************************************

scopeTest=0

scopeLoop:

 ifne scopeTest
 	move	#$666,$dff180
.1 	cmp.b	#$40,$dff006
 	bne.b	.1
.2 	cmp.b	#$40,$dff006
 	beq.b	.2
 	move	#$f00,$dff180
 else
	move.l	_GFXBase(a5),a6
	lob	WaitTOF
 endif


	;tst.b	tapa_quad(a5)		* pit‰‰kˆ poistua?
	;bne.w	qexit
	move.l	s_runningStatusAddr(a4),a0
	tst.b	(a0)
	bmi.w	qexit

	* Bypass screen check if LMB has been pressed
	tst.b 	d5
	bne.b	.screenVisible

	move.l	_IntuiBase(a5),a1
	move.l	ib_FirstScreen(a1),a1
	move.l	s_scopeWindowBase(a4),a0	* ollaanko p‰‰llimm‰isen‰?

	* Scope screen is the active screen?
	cmp.l	wd_WScreen(a0),a1
	beq.b	.screenVisible
	* Scope screen is not active, but screen might be partially
	* visible? sc_TopEdge==0 means it can't be partially visible.
	tst	sc_TopEdge(a1)
	beq.w 	.continue
.screenVisible

	tst.b	playing(a5)
	beq.b	.doNotDraw

	* No scopes when AHI
	tst.b	ahi_use_nyt(a5)
	bne.b	.doNotDraw

	* Does the active player support scopes?
	move.l	playerbase(a5),d0
	beq.b	.doNotDraw
	move.l	d0,a0
	move	p_liput(a0),d0 
	btst	#pb_scope,d0 
	beq.b	.doNotDraw

	* Do not draw if patternmode and no pattern info
	cmp.b	#QUADMODE2_PATTERNSCOPE,s_quadmode2(a4)
	beq.b	.testPattern
	cmp.b	#QUADMODE2_PATTERNSCOPEXL,s_quadmode2(a4)
	bne.b	.noPattern
.testPattern	
	* Protracker special case
	cmp	#pt_prot,playertype(a5)
	beq.b	.izOk
	* Pattern data check
	tst.l	deliPatternInfo(a5)
	bne.b	.izOk
	bra.b	.doNotDraw
.noPattern
	* Check for sample scope support
	and	#pf_quadscopeUps!pf_quadscopePoke,d0
	beq.b	.doNotDraw
.izOk

	bsr.w	scopeDrawAreaSizeChangeRequestIsActive
	bne.b	.doNotDraw

	tst.b	d7
	bne.b	.doDraw
	* This clears the hippo gfx away when starting again
	bsr.w	scopeDrawAreaClear
.doDraw
	* Needs a clear in the future
	moveq	#-1,d7

	pushm	d5/d6/d7
	jsr	obtainModuleData
	* Final safety check
	tst.b	playing(a5)
	beq.b	.1
	bsr.w	drawScope
.1	jsr 	releaseModuleData
	popm	d5/d6/d7
	bra.b	.continue

.doNotDraw
	* See if clear requested
	tst.b	d7
	beq.b	.continue
	* Request fulfilled
	moveq	#0,d7
	bsr.w	scopeDrawAreaClear
	jsr	printHippoScopeWindow
	;bra.w	.continue - FALL THROUGH

.m
.continue
	* Manual size and position detection by polling.
	bsr.w	scopeWindowChangeHandler

	* Store window position so it gets saved with prefs
	move.l	s_scopeWindowBase(a4),a0
	move.l	s_storedPositionAddr(a4),a1
	move.l	4(a0),(a1)

.getMoreMsg
	* Poll for messages
	move.l	s_userport3(a4),a0
	lore	Exec,GetMsg
	tst.l	d0
	beq.w	scopeLoop
	move.l	d0,a1

	move.l	im_Class(a1),d2		* luokka	
	move	im_Code(a1),d3
	lob	ReplyMsg

;	cmp.l	#IDCMP_REFRESHWINDOW,d2 
;	bne.b 	.noRefresh
;	bsr.w	scopeRefreshWindow
;	bra.b	.getMoreMsg
;.noRefresh
;	cmp.l	#IDCMP_CHANGEWINDOW,d2 
;	bne.b 	.noChangeWindow
;	bsr	scopeWindowChanged
;	bra.b	.getMoreMsg
;.noChangeWindow
;	cmp.l	#IDCMP_NEWSIZE,d2 
;	bne.b 	.noNewSize
;	bsr.w	scopeWindowSizeChanged
;	bra.b	.getMoreMsg
;.noNewSize

	cmp.l	#IDCMP_MOUSEBUTTONS,d2
	bne.b	.noButtons

	* RMB closes window
	cmp	#MENUDOWN,d3
	beq.b	.quit
	cmp	#SELECTDOWN,d3
	bne.b	.noButtons
	* LMB activates 
	st	d5
	move.b	d5,scopeManualActivation(a5)

.noButtons
	cmp.l	#IDCMP_CLOSEWINDOW,d2
	beq.b	.quit
	bra.b	.getMoreMsg
	
.quit
	;clr.b	scopeflag(a5)
	
*********************************************************************
* Scope exit
*********************************************************************

qexit:

;; Scope performance measurements
 if DEBUG
	lea	scopeStopTimeSecs(a5),a0
	lea	scopeStopTimeMicros(a5),a1
	lore	Intui,CurrentTime
 endif

	SDPRINT	"Scope task will exit"
	bsr.b	qflush_messages

	bsr.b	freeScopeBitmaps
  ifne FEATURE_FREQSCOPE
	move.l	s_deltab1(a4),a0
	clr.l	s_deltab1(a4)
	jsr	freemem
  endif
  ifne FEATURE_SPECTRUMSCOPE
	jsr	spectrumUninitialize
  endif

	move.l	_IntuiBase(a5),a6		
	move.l	s_scopeWindowBase(a4),d0
	beq.b	.uh1
	move.l	d0,a0
	lob	CloseWindow
	clr.l	s_scopeWindowBase(a4)
.uh1

	SDPRINT	"Scope task exiting"
	;clr	quad_prosessi(a5)	* lippu: lopetettiin

	* Dangerous exit procedures!	
	lore	Exec,Forbid

	* Not running anymore
	move.l	s_runningStatusAddr(a4),a0
	clr.b	(a0)

	* Is prefs displayed? Update as scope status changes
	bsr.w	updateScopeStatusesToPrefs
	cmp	#1,prefsivu(a5)		
	bne.b	.x
	* This will Signal()
	bsr.w	updateprefs
.x


	* Free local data. a4 invalid after this
	move.l	a4,a0
	jsr	freemem

	* Exit task into default task clean up
	rts




qflush_messages
	move.l	s_scopeWindowBase(a4),a0 
	bra.w	flushWindowMessages

freeScopeBitmaps
	move.l	s_buffer0(a4),d0
	beq.b	.noFree
	move.l	d0,a0
	clr.l	s_buffer0(a4)
	move	s_buffer0w(a4),d0
	move	s_buffer0h(a4),d1
	lore	GFX,FreeRaster
.noFree
	rts

initScopeBitmaps
	bsr.b 	freeScopeBitmaps

	moveq	#0,d0
	move	s_scopeDrawAreaWidth(a4),d0 
	moveq	#0,d1
	move	s_scopeDrawAreaHeight(a4),d1
	* allocate 6 extra rasterlines per buffer
	addq.l	#6,d1
	* two buffers
	add.l	d1,d1
	move	d0,s_buffer0w(a4)
	move	d1,s_buffer0h(a4)
	lore	GFX,AllocRaster
	move.l	d0,s_buffer0(a4)
	beq.b	.memError 

 	move.l	d0,a0
	move.l	a0,s_buffer0(a4)

	* AllocRaster does not clear memory, clear it
	move.l 	a0,a1
	move	s_scopeDrawAreaModulo(a4),d1
	mulu	s_buffer0h(a4),d1
	lsr.l	#2,d1
	subq	#1,d1
.clr
	clr.l	(a1)+
	dbf	d1,.clr

	move	s_scopeDrawAreaModulo(a4),d1
	* leave two lines spare at the top
	add	d1,a0
	add	d1,a0
	;add.l	#320/8*2,d0		* yl‰‰lle 2 vararivi‰
	move.l	a0,s_buffer1(a4)

	move	s_scopeDrawAreaModulo(a4),d0
	move	s_scopeDrawAreaHeight(a4),d1
	* four lines spare at the botrom
	addq	#4,d1
	mulu	d1,d0
	add.l	d0,a0
	move.l	a0,s_buffer2(a4)
	
*** Initialisoidaan oma bitmappi
	lea	s_omabitmap(a4),a0
	moveq	#1,d0
	move	s_scopeDrawAreaWidth(a4),d1
	move	s_scopeDrawAreaHeight(a4),d2
	* why add 2 here? 
	addq	#2,d2
	lore	GFX,InitBitMap
	move.l	s_buffer1(a4),s_omabitmap+bm_Planes(a4)
 
	move.l	s_buffer1(a4),s_draw1(a4)
	move.l	s_buffer2(a4),s_draw2(a4)
	move	s_scopeDrawAreaModulo(a4),d0
	* make draw buffer start at 3rd line. why?
	mulu	#3,d0
	add.l	d0,s_draw1(a4)
	add.l	d0,s_draw2(a4)

.memError
	rts

* Z is set if patternscope is active
patternScopeIsActive
	cmp.b	#QUADMODE2_PATTERNSCOPE,s_quadmode2(a4) 
	beq.b	.isPatts
	cmp.b	#QUADMODE2_PATTERNSCOPEXL,s_quadmode2(a4)
.isPatts
	rts


scopeDrawAreaClear
	move.l	s_rastport3(a4),a1
	move.l	pen_0(a5),d0
	lore	GFX,SetAPen
	move.l	s_rastport3(a4),a1
	moveq	#10,d0
	moveq	#14,d1
	move	s_scopeDrawAreaWidth(a4),d2
	add	#10,d2
	move	s_scopeDrawAreaHeight(a4),d3
	add	#79-64,d3
	add	windowleft(a5),d0
	add	windowleft(a5),d2
	add	windowtop(a5),d1
	add	windowtop(a5),d3
	jmp	_LVORectFill(a6)


* Called each scope loop to detect changes in window position
* and size. This provides IDCMP_NEWSIZE and IDCMP_CHANGEWINDOW
* kind of functionality by polling. Seems to work on kick1.3 and kick3.0,
* for some reason the IDCMP approach did not work similarly on
* both kickstarts.
scopeWindowChangeHandler
	move.l	s_scopeWindowBase(a4),a0
	move	wd_Width(a0),d0 
	move	wd_Height(a0),d1 
	move	wd_TopEdge(a0),d2 
	move	wd_LeftEdge(a0),d3

	cmp	s_scopePreviousTopEdge(a4),d2
	bne.b	.posChange
	cmp	s_scopePreviousLeftEdge(a4),d3 
	bne.b	.posChange
	cmp	s_scopePreviousWidth(a4),d0 
	bne.b	.sizeChange
	cmp 	s_scopePreviousHeight(a4),d1 
	bne.b	.sizeChange
	rts
.posChange
	move	d2,s_scopePreviousTopEdge(a4) 
	move	d3,s_scopePreviousLeftEdge(a4)
	bra.w		scopeWindowChanged
	
.sizeChange 
	move	d0,s_scopePreviousWidth(a4)
	move	d1,s_scopePreviousHeight(a4)
	bra.w		scopeWindowSizeChanged
	

;scopeRefreshWindow
;	move.l	scopeWindowBase(a5),a0
;	lore	Intui,BeginRefresh
;;	bsr.b	drawScopeWindowDecorations
;	moveq	#1,d0 * true: complete
;	move.l	scopeWindowBase(a5),a0 
;	lore	Intui,EndRefresh
;	rts

drawScopeWindowDecorations
	move.l	s_rastport3(a4),a2
	moveq	#4,d0
	moveq	#11,d1
	move	s_scopeDrawAreaWidth(a4),d2
	add	#335-320,d2
	move	s_scopeDrawAreaHeight(a4),d3
	add	#82-64,d3
	bsr.w	drawtexture

	moveq	#8,d0
	moveq	#13,d1
	move	s_scopeDrawAreaWidth(a4),d4
	add	#323-320,d4
	move	s_scopeDrawAreaHeight(a4),d5
	addq	#67-64,d5
	moveq	#$0a,d6
	move.l	s_rastport3(a4),a0
	move.l	a0,a1
	add	windowleft(a5),d0
	add	windowtop(a5),d1
	move.l	d0,d2
	move.l	d1,d3
	lob	ClipBlit
	;bra.b	.drawBox 

.drawBox
	moveq	#7,plx1
	move	s_scopeDrawAreaWidth(a4),plx2
	add	#332-320,plx2
	moveq	#13,ply1
	move	s_scopeDrawAreaHeight(a4),ply2
	add	#80-64,ply2
	add	windowleft(a5),plx1
	add	windowleft(a5),plx2
	add	windowtop(a5),ply1
	add	windowtop(a5),ply2
	move.l	s_rastport3(a4),a1
	push	a4
	jsr	laatikko2
	pop	a4
	rts


requestNormalScopeDrawArea
	move	#SCOPE_DRAW_AREA_WIDTH_DEFAULT,d0 
	moveq	#SCOPE_DRAW_AREA_HEIGHT_DEFAULT,d1
	* falling thru!

* Resize window based on relative change to
* the draw area.
* In:
*   d0 = new draw area width, must be divisible by 16
*        for blitter
*   d1 = new draw area height
* Out:
*   d0 = 0 if draw area is already matching
*   d0 = ~0 window will change to accommodate
requestScopeDrawAreaChange

	move	d0,s_scopeDrawAreaWidthRequest(a4)
	move	d1,s_scopeDrawAreaHeightRequest(a4)
	sub	s_scopeDrawAreaWidth(a4),d0
	sub	s_scopeDrawAreaHeight(a4),d1
	move	d1,d2
	or	d0,d2
	beq.b	.noDiff

 if DEBUG 	
	ext.l 	d0 
	ext.l 	d1
	SDPRINT	"Draw area change %ld %ld"
 endif


	move.l	s_scopeWindowBase(a4),a0
	* Calculate new right edge position for window 
	move	wd_LeftEdge(a0),d2
	add	wd_Width(a0),d2
	add	d0,d2
	move	wbleveys(a5),d3
	sub	d2,d3

	move	wd_TopEdge(a0),d4
	add	wd_Height(a0),d4
	add	d1,d4
	move	wbkorkeus(a5),d5
	sub	d4,d5

	tst	d3
	bmi.b	.1
	moveq	#0,d3
.1	tst	d5
	bmi.b	.2
	moveq	#0,d5
.2
	move	d3,d2
	or	d5,d2
	beq.b	.fits
 
	move	d3,d0
	move	d5,d1 
 if DEBUG 
 	ext.l 	d0 
 	ext.l 	d1
	SDPRINT	"->move %ld %ld"
 endif
   
	lore	Intui,MoveWindow
	moveq	#1,d0
	rts
.fits
 if DEBUG 
 	ext.l 	d0 
 	ext.l 	d1
	SDPRINT	"->resize %ld %ld"
 endif 

	move.l	s_scopeWindowBase(a4),a0 
	lore 	Intui,SizeWindow
	moveq	#1,d0
	rts
.noDiff
;	SDPRINT	"->no change!"
	moveq	#0,d0
	rts

scopeDrawAreaSizeChangeRequestIsActive
	move	s_scopeDrawAreaWidthRequest(a4),d0 
	cmp	s_scopeDrawAreaWidth(a4),d0 
	bne.b 	.yes
	move	s_scopeDrawAreaHeightRequest(a4),d0 
	cmp	s_scopeDrawAreaHeight(a4),d0 
	bne.b 	.yes
	moveq	#0,d0
	rts
.yes	
	moveq	#1,d0
	rts

* Called when IDCMP_CHANGEWINDOW message arrives.
scopeWindowChanged
	SDPRINT	"scopeWindowChanged"
 if DEBUG
	move.l	s_scopeWindowBase(a4),a0
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	move	wd_LeftEdge(a0),d0
	move	wd_TopEdge(a0),d1
	move	wd_Width(a0),d2
	move	wd_Height(a0),d3
	SDPRINT	"left=%ld top=%ld width=%ld height=%ld"
 endif
	* Request again after window move
 	bsr.b	scopeDrawAreaSizeChangeRequestIsActive
	beq.b 	.nope 
	move	s_scopeDrawAreaWidthRequest(a4),d0
	move	s_scopeDrawAreaHeightRequest(a4),d1
	bsr.w 	requestScopeDrawAreaChange
.nope
	rts

* Called when IDCMP_NEWSIZE message arrives.
* Window size change request has been fulfilled.
scopeWindowSizeChanged
	pushm	d2-d6
	SDPRINT	"scopeWindowSizeChanged"
 if DEBUG
	move.l	s_scopeWindowBase(a4),a0
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	move	wd_LeftEdge(a0),d0
	move	wd_TopEdge(a0),d1
	move	wd_Width(a0),d2
	move	wd_Height(a0),d3
	SDPRINT	"left=%ld top=%ld width=%ld height=%ld"
 endif
	move	s_scopeDrawAreaWidthRequest(a4),s_scopeDrawAreaWidth(a4)
	move	s_scopeDrawAreaHeightRequest(a4),s_scopeDrawAreaHeight(a4)
	move	s_scopeDrawAreaWidth(a4),d0 
	lsr	#3,d0 
	move	d0,s_scopeDrawAreaModulo(a4)

	* lines count for patternscope, 8px high rows
	move	s_scopeDrawAreaHeight(a4),d0
	lsr	#3,d0 
	move	d0,s_quadNoteScrollerLines(a4)
	lsr	#1,d0
	move	d0,s_quadNoteScrollerLinesHalf(a4)

	bsr.w	initScopeBitmaps
	bsr.w	drawScopeWindowDecorations
	popm	d2-d6
	rts


*********************************************************************
* Scope interrupt code, keeps track the play positions of 
* replayer samples
*********************************************************************

* in:
*    a5 = var_b
scopeinterrupt:				
	cmp	#pt_prot,playertype(a5)
	bne.w	.notProtracker

	* Copy scope data from Protracker data structures

	lea	kplbase(a5),a0
	move.b	k_usertrig(a0),d0
	or.b	d0,scopeData+scope_trigger(a5)
	clr.b	k_usertrig(a0)

	lea	k_chan1temp(a0),a2
	lea	scopeData+scope_ch1(a1),a0
	lea	hippoport+hip_PTtrigger1(a5),a3
	moveq	#4-1,d1
.setscope
	ror.b	#1,d0
	bpl.b	.e
	addq.b	#1,(a3)
	move.l	n_start(a2),ns_start(a0)
	move	n_length(a2),ns_length(a0)
	move.l	n_loopstart(a2),ns_loopstart(a0)
	move	n_replen(a2),ns_replen(a0)
.e	move	n_period(a2),ns_period(a0)	

	move	n_tempvol(a2),d2
	CLAMPVOL d2
	move	d2,ns_tempvol(a0)
	
	addq	#1,a3 * next trigger byte
	lea	n_sizeof(a2),a2
	lea	ns_size(a0),a0
	dbf	d1,.setscope

.quadScopeSampleFollow
	* Update quadrascope sample data pointers based on period

	moveq	#4-1,d1
	lea	scopeData+scope_ch1(a5),a0

.le	moveq	#0,d0
	tst	ns_period(a0)
	beq.b	.noe
	move.l	colordiv(a5),d0		* colorclock/vbtaajuus
	divu	ns_period(a0),d0
	ext.l	d0
.noe	
	add.l	d0,ns_start(a0)
	lsr	#1,d0
	moveq	#0,d2
	move	ns_length(a0),d2
	sub.l	d0,d2
	move	d2,ns_length(a0)
	move.l	d2,d0
	bpl.b	.plu

	* Negative overrun
	;move	ns_length(a0),d0
	;ext.l	d0
	;move.l	d2,d0

	* safety check
	move	ns_replen(a0),d2
	bne.b	.nz
	moveq	#1,d2
.nz
	* Modulo with respect to the replen
	divs	d2,d0
	swap	d0
	ext.l	d0
	* Adjust replen according to overrun, words
	moveq	#0,d2
	move	ns_replen(a0),d2
	add.l	d0,d2
	move	d2,ns_length(a0)
	* Adjust loopstart, bytes
	move.l	ns_loopstart(a0),ns_start(a0)
	add.l	d0,d0
	sub.l	d0,ns_start(a0)
.plu	
	lea	ns_size(a0),a0
	dbf	d1,.le
	rts

.notProtracker
	cmp	#pt_sample,playertype(a5)
	bne.b	.notSample

	* Sample scope data. Update sample follow position once per frame.
	move.l	sampleadd(a5),d0
	move.l	samplefollow(a5),a0
	add.l	d0,(a0)
.x	rts

.notSample
	* PSID uses it's own following mechanism
	cmp	#pt_sid,playertype(a5)
	beq.b	.x

	* Check player has generic quadrascope support
	move.l	playerbase(a5),a0
	move	p_liput(a0),d1

	* Poke method:
	btst	#pb_quadscopePoke,d1
	bne.w	.quadScopeSampleFollow
	
	* UPS method:
	btst	#pb_quadscopeUps,d1
	beq.b	.noScopes

	* UPS struct provided by eagle player?
	move.l	deliUPSStruct(a5),d0
	* Unnecessary check?
	beq.w	.quadScopeSampleFollow


	* Handle UPS, it will provide input for normal sample follow
	bsr.b	.handleUPS
	bra.w	.quadScopeSampleFollow

.noScopes
	* No scopes for u this time.
	rts

.handleUPS
	move.l	d0,a0
	tst	UPS_Enabled(a0)
	bne.b	.disabled
	lea	nullsample,a1

	lea	UPS_Voice1Adr(a0),a2
	lea	scopeData+scope_ch1(a5),a3
	moveq	#4-1,d0
.upsLoop
	move	UPS_Voice1Vol(a2),d1
	CLAMPVOL d1
	move	d1,ns_tempvol(a3)
	move	UPS_Voice1Per(a2),d1
	beq.b	.1
	* New sample starts as period is non-zero
	move	d1,ns_period(a3)
	move.l	UPS_Voice1Adr(a2),ns_start(a3)
	move	UPS_Voice1Len(a2),ns_length(a3)
.1	
	move.l	UPS_Voice1Adr(a2),d1
	move	UPS_Voice1Len(a2),d2

	tst	UPS_Voice1Repeat(a2)
	beq.b	.11
	* This case is very seldom used
	move.l	a1,d1
	moveq	#1,d2
.11
	move.l	d1,ns_loopstart(a3)
	move	d2,ns_replen(a3)

	lea	UPS_Modulo(a2),a2
	lea	ns_size(a3),a3
	dbf	d0,.upsLoop
.disabled
	rts


* Clears any scope data that points into module data.
clearScopeData
	clr.l	deliUPSStruct(a5)
	clr.b	scope_trigger+scopeData(a5)
	lea	scope_ch1+scopeData(a5),a0
	moveq	#4*ns_size/2-1,d0
.c	clr	(a0)+
	dbf	d0,.c
	rts

* Opens the mini font for 4+ channel notescroller if needed
getScopeMiniFontIfNeeded
	tst.l	minifontbase(a5)
	bne.b	.skip
	* See if we need the small font
;	bsr.w	patternScopeIsActive
;	bne.b	.skip
;	move.l	deliPatternInfo(a5),d0
;	beq.b	.skip
;	move.l	d0,a0
;	cmp	#SCOPE_SMALL_FONT_CHANNEL_LIMIT,PI_Voices(a0)
;	bls.b	.skip
	lea	diskfontname,a1
	lore	Exec,OldOpenLibrary
	tst.l 	d0 
	beq.b	.skip
	move.l	d0,a6
	lea	mini_text_attr,a0
	lob	OpenDiskFont
	move.l	d0,minifontbase(a5)
	move.l	a6,a1
	lore 	Exec,CloseLibrary
;	tst.l	minifontbase(a5)
;	bne.b	.miniOk
;	lea	.noFontMsg(pc),a1 
;	tst.b	(a1)
;	beq.b	.skip
;	bsr	request
;	* Show this only once to not be annoying
;	clr.b	(a1)	
.skip
	rts
.miniOk
	DPRINT	"Got mini font"
	rts
;.noFontMsg
;	dc.b	"Couldn't open 'mini4' font for patternscope!",0;
;	even

******* Quadrascopelle 
voltab
	lea	s_mtab(a4),a0
	moveq	#$40-1,d3
	moveq	#0,d2

	tst	d7
	bne.b	.voltab_fill

.olp2	moveq	#0,d0
	move	#256-1,d4
.olp1	move	d0,d1
	ext	d1
	muls	d2,d1
	asr	#8,d1
	add	#32,d1
	mulu	#40,d1
	add	#39,d1
	move	d1,(a0)+
	addq	#1,d0
	dbf	d4,.olp1
	addq	#1,d2
	dbf	d3,.olp2
	rts

******* Filled quadrascope

.voltab_fill
;	lea	mtab(a5),a0
;	moveq	#$40-1,d3
;	moveq	#0,d2
.olp2q	moveq	#0,d0
	move	#256-1,d4
.olp1q	move	d0,d1
	ext	d1
	muls	d2,d1
	asr	#8,d1
	tst	d1
	bmi.b	.mee
	moveq	#31,d5
	sub	d1,d5
	move	d5,d1
	sub	#32,d1
.mee	add	#32,d1
	mulu	#40,d1
	add	#39,d1
	move	d1,(a0)+
	addq	#1,d0
	dbf	d4,.olp1q
	addq	#1,d2
	dbf	d3,.olp2q
	rts



******* Hipposcopelle
voltab2
	lea	s_mtab(a4),a0

	moveq	#$40-1,d3
	moveq	#0,d2
.op2
	moveq	#0,d0
	move	#256-1,d4
.op1
	move	d0,d1
	ext	d1
	muls	d2,d1
	asr	#8,d1
	add.b	#$80,d1
	move.b	d1,(a0)+

	addq	#1,d0
	dbf	d4,.op1

	addq	#1,d2
	dbf	d3,.op2


	moveq	#$40-1,d3
	moveq	#0,d2
.olp2a
	moveq	#0,d0
	move	#256-1,d4
.olp1a
	move	d0,d1
	ext	d1
	muls	d2,d1
	asr	#7,d1
	muls	#80,d1		* x-alue: 0-80
	divs	#127,d1
	add.b	#$80,d1
	move.b	d1,(a0)+

	addq	#1,d0
	dbf	d4,.olp1a

	addq	#1,d2
	dbf	d3,.olp2a
	
	rts



***************** Freqscopelle
  ifne FEATURE_FREQSCOPE
voltab3
	move.l	m_mtab(a4),a0
	moveq	#$40-1,d3
	moveq	#0,d2
.olp2	moveq	#0,d0
	move	#256-1,d4
.olp1	move	d0,d1
	ext	d1
	muls	d2,d1
	asr	#6,d1
	move.b	d1,(a0)+
	addq	#1,d0
	dbf	d4,.olp1
	addq	#1,d2
	dbf	d3,.olp2
	rts
  endif

**************************************************************************
* Scope draw
**************************************************************************

drawScope:

	* See if the whole drawing phase can be skipped
	bsr.w	patternScopeIsActive
	bne.b	.noPattSc
	move.l	deliPatternInfo(a5),d0 
	beq.b 	.noPattSc 
	move.l	d0,a0
	movem	PI_Pattpos(a0),d0/d1 
	cmp	s_scopePreviousPattPos(a4),d0 
	bne.b	.doUpdate
	cmp	s_scopePreviousSongPos(a4),d1 
	bne.b	.doUpdate
	rts
.doUpdate
	move	d0,s_scopePreviousPattPos(a4)
	move	d1,s_scopePreviousSongPos(a4)
.noPattSc
	* s_draw1 = draw scope in this buffer
	* s_draw2 = clear this buffer

	* clear draw area
	move.l	_GFXBase(a5),a6
	lob	OwnBlitter
	lob	WaitBlit

	lea	$dff058,a0
	move.l	s_draw2(a4),$54-$58(a0)	
	move	#0,$66-$58(a0)
	move.l	#$01000000,$40-$58(a0)

	* build BLTSIZ parameter
	move	s_scopeDrawAreaHeight(a4),d0
	lsl	#6,d0
	move	s_scopeDrawAreaModulo(a4),d1
	lsr	#1,d1	* words
	add	d1,d0
	* Do blit
	move	d0,(a0)

	* Continue clearing while scope is drawn into the other buffer
	lob	DisownBlitter

* Scope performance measurements
* Disaster is obvious, playing the first 40 seconds
* - v2.52 spectrumScope on A500: 75 ms average
* - v2.53 spectrumScope on A500: 70 ms
*               micro-optimized: 69 ms
*               alternative asr: 58 ms
 if DEBUG
	addq.l	#1,scopeFrameCounter(a5)
	jsr	startMeasure
	bsr.w	.render
	jsr	stopMeasure
	add.l	d0,scopeRenderTime(a5)
 else
	bsr.w	.render
 endif

	* scope processed, deliver unto screen

	* double buffer
	move.l	s_draw1(a4),d0
	move.l	s_draw2(a4),d1
	move.l	d1,s_draw1(a4)
	move.l	d0,s_draw2(a4)

	* Copy s_draw1 to screen
	
	lea	s_omabitmap(a4),a0
	move.l	d0,bm_Planes(a0)

	move.l	_GFXBase(a5),a6	* kopioidaan kamat ikkunaan
	move.l	s_rastport3(a4),a1
	moveq	#0,d0		* l‰hde x,y
	moveq	#0,d1
	moveq	#10,d2		* kohde x,y
	moveq	#15,d3
	add	windowleft(a5),d2
	add	windowtop(a5),d3
	move	#$c0,d6		* minterm, suora kopio a->d
	move	s_scopeDrawAreaWidth(a4),d4
	move	s_scopeDrawAreaHeight(a4),d5

	* Perform some adjustments based on mode and type
	cmp.b	#QUADMODE_FREQANALYZER,s_quadmode(a4)
	beq.b	.noMagic
	cmp.b	#QUADMODE_PATTERNSCOPE,s_quadmode(a4)
	beq.b	.pattern
	cmp.b	#QUADMODE_PATTERNSCOPEXL,s_quadmode(a4)
	beq.b	.pattern

	cmp	#pt_sample,playertype(a5)
	beq.b	.centerStereo
	cmp	#pt_multi,playertype(a5)
	bne.b	.noMagic
	cmp.b	#QUADMODE_HIPPOSCOPE,s_quadmode(a4)
	bne.b	.centerStereo
	* Center PS3M + hipposcope
	addq	#4,d2		; target x
	subq	#4,d4		; width
	bra.b	.noMagic
	
.centerStereo
	* This will center the two wide stereo scope graphs
	* with sample player and PS3M
	addq	#4,d0		; source x
	subq	#4,d4		; width
	bra.b	.noMagic

.pattern
	* Move patternscope one pixel to the right
	* to have some space on the left border.
	addq	#1,d2		; target x
	subq	#1,d4		; width

.noMagic
	lob	BltBitMapRastPort
	rts


.render
	cmp	#pt_sample,playertype(a5)
	beq.b	.renderSample

	moveq	#0,d0
	move.b	s_quadmode2(a4),d0
	add	d0,d0

	cmp	#pt_multi,playertype(a5)
	beq.w	.renderPS3M

;	* Check for generic quadscope support
;	move.l	playerbase(a5),a0
;	move	#pf_quadscopeUps!pf_quadscopePoke,d1
;	and	p_liput(a0),d1
;	bne.b	.doit
;	tst.l	deliPatternInfo(a5)
;	bne.b	.doit	
;	rts
;.doit

	* Protracker scope
	* .. or similarly working others

	jmp	.t(pc,d0)

* protracker jump table
.t	bra.b	.1 * quad
	bra.b	.3 * + bars
	bra.b	.2 * hippo
	bra.b	.4 * + bars
	bra.b	.5 * freq
	bra.b	.6 * + bars
	bra.b	.7 * pattern normal size
	bra.b	.7 * --""-- 
	bra.b	.8 * fquad
	bra.b	.9 * + bars
	bra.b	.7 * pattern extra large
	bra.b	.7 * --""--

.3	bsr.w	lever
.1	bra.w	quadrascope

.4	bsr.w	lever
.2	bra.w	hipposcope

.5	bra.w	freqscope

.6	bsr.w	freqscope
	lore	GFX,WaitBlit
	bra.w	leverEor

.7	* Protracker specific notescroller launch
	cmp	#pt_prot,playertype(a5)
	beq.w	notescroller
	* Generic notescroller launch
	tst.l	deliPatternInfo(a5)
	bne.w	noteScroller2
	rts
	
.8	bsr.w	quadrascope
	bra.w	mirrorfill

.9	bsr.b	.8
	lore	GFX,WaitBlit
	bra.w	leverEor * extra gfx drawn, must wait until fill done

;.other
;	* Fallback option!
;	* Display notescroller if possible.
;	* Non-Protracker formats.
;	tst.l	deliPatternInfo(a5)
;	beq.b	.cont
;	bsr	noteScroller2
;.cont
;	rts


* Sample scope
.renderSample
	* Get normal scope area
	bsr.w	requestNormalScopeDrawArea
	bne.b	.sampleSkip * wait for resize

	cmp.b	#QUADMODE2_FQUADRASCOPE,s_quadmode2(a4)
	beq.b	.fil
	cmp.b	#QUADMODE2_FQUADRASCOPE_BARS,s_quadmode2(a4)	
	beq.b	.fil
	cmp.b	#QUADMODE2_FREQANALYZER,s_quadmode2(a4)
	beq.w	freqscope
	cmp.b	#QUADMODE2_FREQANALYZER_BARS,s_quadmode2(a4)
	beq.w	freqscope
	cmp.b	#QUADMODE2_PATTERNSCOPE,s_quadmode2(a4)
	beq.b	.sampleSkip
	cmp.b	#QUADMODE2_PATTERNSCOPEXL,s_quadmode2(a4)	
	beq.b	.sampleSkip
	* Default
	bsr.w	samplescope
.sampleSkip
	rts
.fil
	bsr.w	samplescopefilled
	bra.b	mirrorfill

.renderPS3M

	* PS3M scope
	* multichannel jump table
	jmp	.tt(pc,d0)
.tt	bra.b	.11 * quad
	bra.b	.11
	bra.b	.22 * hipp
	bra.b	.22
	bra.b	.33 * freq
	bra.b	.33
	bra.b	.55 * patt
	bra.b	.55
	bra.b	.44 * fquad
	bra.b	.44
	bra.b	.55 * patt
	bra.b	.55

.11	bra.w	multiscope
.22	bra.w	multihipposcope
.33	bra.w	freqscope
.44	bsr.w	multiscopefilled
	bra.b	mirrorfill
.55	* PS3M patternscope mode
	tst.l	deliPatternInfo(a5) 
	bne.w	noteScroller2
	rts


mirrorfill
	lore	GFX,OwnBlitter
	lob	WaitBlit

	move.l	s_draw1(a4),a0
	lea	$dff058,a2

	move.l	a0,$50-$58(a2)	* A
	lea	40(a0),a1
	move.l	a1,$48-$58(a2)	* C
	move.l	a1,$54-$58(a2)	* D
	moveq	#0,d0
	move	d0,$60-$58(a2)	* C
	move	d0,$64-$58(a2)	* A
	move	d0,$66-$58(a2)	* D
	moveq	#-1,d0
	move.l	d0,$44-$58(a2)
	move.l	#$0b5a0000,$40-$58(a2)	* D = A not C
	move	#31*64+20,(a2)	

	lea	63*40(a0),a1		* kopioidaan
	lob	WaitBlit
	movem.l	a0/a1,$50-$58(a2)
	move	#-80,$66-$58(a2) 	* D
	move.l	#$09f00000,$40-$58(a2)
	move	#32*64+20,(a2)	

	lob	DisownBlitter
	rts


* In: 
*   a3 = scope data
* Out:
*   d0 = sample start, or 0 if bounds check failed for any value
*   d1 = loop start
*   d2 = sample length
*   d3 = repeat length
*   
getScopeChannelData:
	cmp	#pt_prot,playertype(a5)
	bne.b	.notPt

	* Similar check as before
	move.l	ns_start(a3),d0
	beq.b	.fail
	move.l	ns_loopstart(a3),d1
	beq.b	.fail
	move	ns_length(a3),d2
	move	ns_replen(a3),d3
	tst.l	d0
	rts

.notPt
	* More comprehensive check for others
 REM
	move.l	ns_start(a3),d0
	move.l	ns_loopstart(a3),d2
	moveq	#0,d1
	move	ns_length(a3),d1
	moveq	#0,d3
	move	ns_replen(a3),d3
	move.l	moduleaddress(a5),d4
	move.l	d4,d5
	add.l	modulelength(a5),d5
	SDPRINT	"%lx %lx %lx %lx - %lx %lx"
 EREM

	move.l	ns_start(a3),d0
	beq.b	.fail
	move.l	ns_loopstart(a3),d1
	beq.b	.fail
	move	ns_length(a3),d2
	beq.b	.fail
	move	ns_replen(a3),d3
	beq.b	.fail
	cmp.l	#1024,d0
	blo.b	.fail
	cmp.l	#1024,d1
	blo.b	.fail

 REM
	
	* This one has waveforms inside the replay code:
	cmp	#pt_future10,playertype(a5)
	beq.b	.skipCheck
	;cmp	#pt_digitalmugician,playertype(a5)
	;beq.b	.skipCheck

	move.l	moduleaddress(a5),d4
	move.l	d4,d5
	add.l	modulelength(a5),d5

	* This one has samples loaded separately:
	cmp	#pt_robhubbard2,playertype(a5)
	bne.b	.notRH2
	* Samples are found elsewhere, get the bounds:
	move.l	deliLoadFileArray(a5),d4
	beq.b	.skipCheck
	push	a2
	move.l	d4,a2 
	move.l	(a2)+,d4 * addr
	move.l	d4,d5
	add.l	(a2),d5 * len
	pop	a2
;	SDPRINT	"%lx %lx %lx %lx-%lx %lx"
.notRH2

	* Check start
	cmp	#2,d2
	bls.b	.shortLen
	cmp.l	d4,d0
	blo.b	.fail
	cmp.l	d5,d0
	bhs.b	.fail
.shortLen

 EREM
 
 REM
	* Check loop start
	cmp	#2,d3
	bls.b	.shortRepLen
	cmp.l	d4,d1
	blo.b	.fail
	cmp.l	d5,d1
	blo.b	.fail
.shortRepLen
 EREM
 
.skipCheck
.go
	tst.l	d0
	rts
.fail
	moveq	#0,d0
	rts

quadrascope:
	lea	scopeData+scope_ch1(a5),a3
	move.l	s_draw1(a4),a0
	lea	-30(a0),a0
	bsr.b	.scope

	lea	scopeData+scope_ch2(a5),a3
	move.l	s_draw1(a4),a0
	lea	-20(a0),a0
	bsr.b	.scope

	lea	scopeData+scope_ch3(a5),a3
	move.l	s_draw1(a4),a0
	lea	-10(a0),a0
	bsr.b	.scope

	lea	scopeData+scope_ch4(a5),a3
	move.l	s_draw1(a4),a0

;	bsr.w	.scope
;	rts

.scope
	bsr.w	getScopeChannelData
	bne.b	.jolt
	rts

.jolt	
	
	move.l	d0,a1 * start
	move.l	d1,a6 * loopstart
	moveq	#0,d5
	move	d2,d5 * len
	moveq	#0,d4
	move	d3,d4 * replen
	
	move	ns_tempvol(a3),d1
	mulu	mainvolume(a5),d1
	lsr	#6,d1
	bne.b	.heee
	moveq	#1,d1
.heee	
	CLAMPVOL d1
	subq	#1,d1
	add	d1,d1
	lsl.l	#8,d1
	lea	s_mtab(a4),a2
	add.l	d1,a2

	lea	-40(a0),a3

	cmp.b	#8,s_quadmode2(a4)
	beq.b	.iik
	cmp.b	#9,s_quadmode2(a4)
	bne.b	.ook
	* Filled quadrascope
.iik	move.l	a0,a3
.ook

	;moveq	#0,d1
	moveq	#80/8-1,d7
	moveq	#1,d0
	moveq	#0,d6
		
drlo	

sco	macro
	moveq	#0,d2
	move.b	(a1)+,d2
	add	d2,d2
	move	(a2,d2),d3
	or.b	d0,(a0,d3)
	or.b	d0,(a3,d3)

	ifne	\2
	add.b	d0,d0
	endc
	
	ifne	\1
	subq.l	#2,d5
	bpl.b	hm\2	* $6a04
	move.l	d4,d5	* replen
	move.l	a6,a1   * loop start
hm\2
	endc
	endm

	sco	0,1
	sco	1,2
	sco	0,3
	sco	1,4
	sco	0,5
	sco	1,6
	sco	0,7
	sco	1,0

	* Reset bit pattern:
	moveq	#1,d0
	sub.l	d0,a0
	sub.l	d0,a3
	dbf	d7,drlo

	rts

hipposcope:
	lea	scopeData+scope_ch1(a5),a3
	move.l	s_draw1(a4),a6
	lea	-20-95*40(a6),a6
	bsr.b	.twirl
	* a6 is unchanged
	
	lea	scopeData+scope_ch2(a5),a3
	lea	10(a6),a6
	bsr.b	.twirl

	lea	scopeData+scope_ch3(a5),a3
	lea	10(a6),a6
	bsr.b	.twirl

	lea	scopeData+scope_ch4(a5),a3
	lea	10(a6),a6
	;bsr.b	.twirl
	;rts


.twirl
	push 	a4
	
	move	ns_tempvol(a3),d0
	mulu	mainvolume(a5),d0
	lsr	#6,d0
	CLAMPVOL d0
	subq	#1,d0
	bpl.b	.e
	moveq	#0,d0
.e	lsl	#8,d0

	* volume multab, y-specific value
	lea	s_mtab(a4),a0
	lea	(a0,d0),a2

	* modulo multab
	lea	s_multab(a4),a0

	* x-specific byte value is in the other half
	lea	64*256(a2),a4


lir	macro
	* x-value
	move.b	(a1)+,d1
	move.b	(a4,d1),d1

	* y-value
	moveq	#0,d2
	move.b	5(a1),d2
	move.b	(a2,d2),d2

	* modulo multab access
	add	d2,d2
	move	(a0,d2),d3

	* plot pixel
	move	d1,d2
	lsr	#3,d2
	sub	d2,d3
	bset	d1,(a6,d3)

	* progress in sample data,
	* check every other pixel
 ifne \2
	subq.l	#2,d4
	bpl.b	.h\1
	move.l	d5,d4
	move.l	d6,a1
.h\1	
 endc
	endm


	bsr.w	getScopeChannelData
	beq.w	.x


	move.l	d0,a1 * start
	move.l	d1,d6 * loopstart
	moveq	#0,d4
	move	d2,d4 * len
	moveq	#0,d5
	move	d3,d5 * replen
	
	* plot this many pixels
	moveq	#108/4-1,d0
	moveq	#0,d1
.d
	lir	0,0
	lir	1,1
	lir	2,0
	lir	3,1
	dbf	d0,.d
.x
	pop	a4
	rts



**** Taajuusanalysaattori

yip	macro
	move.b	(a0)+,d0
	not.b	d0
	add.b	d0,d0
	and	d5,d0
	move	(a2,d0),d0
	or.b	d6,(a1,d0)
	ror.b	#1,d6
	bpl.b	.b\1
	addq	#1,a1
.b\1
 	endm

piup	macro
	move.b	(a1)+,d0
	sub.b	(a1),d0
	bpl.b	.e\1
	neg.b	d0
.e\1	addq.b	#1,(a0,d0)
	subq.l	#1,d5
	bpl.b	.l\1
	cmp	d3,d4
	beq	.break
	move.l	d4,d5
	move.l	a4,a1
.l\1	
	endm

freqscope
  ifne FEATURE_SPECTRUMSCOPE
	jmp	runSpectrumScope
  endif
  
  ifne FEATURE_FREQSCOPE
  fail "Fix a4 accessess first"
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
	moveq	#0,d7
	move.l	deltab1(a5),a0
	lea	(256+32)*4(a0),a1
.clr	movem.l	d0-d7,-(a1)
	movem.l	d0-d7,-(a1)
	cmp.l	a0,a1
	bne.b	.clr


*** PS3M freqscope

	cmp	#pt_multi,playertype(a5)
	bne.b	.protr

;	move.l	buff1,a1
	move.l	ps3m_buff1(a5),a1
	move.l	(a1),a1

	move.l	deltab1(a5),a0
	bsr.w	.tutps3m

;	move.l	buff2,a1
	move.l	ps3m_buff2(a5),a1
	move.l	(a1),a1

	move.l	deltab2(a5),a0
	bsr.w	.tutps3m

	bra.b	.drl

.protr

	lea	scopeData+scope_ch1(a5),a3
	move.l	deltab1(a5),a0
	bsr.w	.tut
	lea	scopeData+scope_ch4(a5),a3
	move.l	deltab4(a5),a0
	bsr.w	.tut

	lea	scopeData+scope_ch2(a5),a3
	move.l	deltab2(a5),a0
	bsr.w	.tut
	lea	scopeData+scope_ch3(a5),a3
	move.l	deltab3(a5),a0
	bsr.w	.tut

	move	ns_tempvol+scopeData+scope_ch1(a5),d1
	move	ns_tempvol+scopeData+scope_ch4(a5),d2
	move.l	deltab1(a5),a0
	move.l	deltab4(a5),a1
	bsr.w	.pre

	move	ns_tempvol+scopeData+scope_ch2(a5),d1
	move	ns_tempvol+scopeData+scope_ch3(a5),d2
	move.l	deltab2(a5),a0
	move.l	deltab3(a5),a1
	bsr.b	.pre

.drl	move.l	deltab1(a5),a0
	move.l	draw1(a5),a1
	addq	#3,a1
	bsr.w	.dr

	move.l	deltab2(a5),a0
	move.l	draw1(a5),a1
	lea	21(a1),a1
	bsr.w	.dr

* Pystyfillaus
	lore	GFX,OwnBlitter

	move.l	draw1(a5),a0
	addq	#2,a0
	moveq	#2,d0
	lea	40(a0),a1
	lea	$dff000,a2

	lob	WaitBlit
	move.l	a0,$50(a2)	* A
	move.l	a1,$48(a2)	* C
	move.l	a1,$54(a2)	* D
	move	d0,$60(a2)	* C
	move	d0,$64(a2)	* A
	move	d0,$66(a2)	* D
	move.l	#-1,$44(a2)
	move.l	#$0b5a0000,$40(a2)	* D = A not C
	move	#65*64+19,$58(a2)

	lob	WaitBlit
	jmp	_LVODisownBlitter(a6)


.pre
	mulu	mainvolume(a5),d1
	lsr	#6,d1
	bne.b	.1
	moveq	#1,d1
.1	subq	#1,d1
	lsl.l	#8,d1
	move.l	mtab(a5),a2
	add.l	d1,a2

	mulu	mainvolume(a5),d2
	lsr	#6,d2
	bne.b	.2
	moveq	#1,d2
.2	subq	#1,d2
	lsl.l	#8,d2
	move.l	mtab(a5),a3
	add.l	d2,a3

	moveq	#128/4-1,d0
	moveq	#0,d3
	moveq	#0,d4
.volm	
 rept 4
	move.b	(a0),d3
	move.b	(a1)+,d4
	move.b	(a2,d3),d3
	add.b	(a3,d4),d3
	move.b	d3,(a0)+
 endr
	dbf	d0,.volm
	rts
	


.dr
	clr.b	(a0)
;	lea	1*40(a1),a1
	lea	multab(a5),a2
	moveq	#128/8-1,d7
	move.b	#$80,d6
	move	#%01111110,d5
.dloop
	yip	0
	yip	1
	yip	2
	yip	3
	yip	4
	yip	5
	yip	6
	yip	7
	dbf	d7,.dloop
	rts


.tut	
	move	ns_tempvol(a3),d4
	mulu	mainvolume(a5),d4
	lsr	#6,d4
	bne.b	.h
	moveq	#1,d4
.h



;	move.l	ns_loopstart(a3),d0
;	beq.b	.halt
;	move.l	ns_start(a3),d1
;	bne.b	.jolt
;.halt	rts
;.jolt	

	bsr	getScopeChannelData
	bne.b	.jolt
	rts
.jolt

	;move.l	d0,a4
	;move.l	d1,a1
	move.l	d0,a1 * start
	move.l	d1,a4 * loop start

	moveq	#0,d4
	move	d3,d4 * replen
	moveq	#0,d5
	move	d2,d5 * len

;	moveq	#0,d4
;	move	ns_replen(a3),d4
;	add.l	d4,d4
;	moveq	#0,d5
;	move	ns_length(a3),d5
;	add.l	d5,d5

	move	ns_period(a3),d0
	bne.b	.noe
	rts

.noe	move.l	colordiv(a5),d7		* colorclock/vbtaajuus
	divu	d0,d7			* d7.w = bytes per 1/50s
	mulu	#11,d7		* tutkitaan 11/15 osa framesta (73%)
	divu	#15,d7

	move	d7,d6
	lsr	#3,d7
	subq	#1,d7
	moveq	#0,d0
	moveq	#2,d3


.loop1
	piup	0
	piup	1
	piup	2
	piup	3
	piup	00
	piup	11
	piup	22
	piup	33
	dbf	d7,.loop1	

	and	#%111,d6
	beq.b	.n
	subq	#1,d6
.loop2	piup	4
	dbf	d6,.loop2
.n
.break
	rts



.tutps3m
;	move.l	mixingperiod,d0
	push	a0
	move.l	ps3m_mixingperiod(a5),a0
	move.l	(a0),d0
	pop	a0
	bne.b	.oe
	rts

.oe	move.l	colordiv(a5),d7		* colorclock/vbtaajuus
	divu	d0,d7			* d7.w = bytes per 1/50s
	mulu	#11,d7		* tutkitaan 11/15 osa framesta (73%)
	divu	#15,d7

	lsr	#2,d7
	subq	#1,d7
	moveq	#0,d0

;	move.l	playpos,d5
	push	a0
	move.l	ps3m_playpos(a5),a0
	move.l	(a0),d5
	pop	a0
		
	lsr.l	#8,d5
	bsr.w	getps3mb

piup2	macro
	move.b	(a1,d5.l),d0
	sub.b	1(a1,d5.l),d0
	bpl.b	.w\1
	neg.b	d0
.w\1	addq.b	#1,(a0,d0)
	addq	#1,d5
	and	d4,d5
	endm

.loop11	piup2	0
	piup2	1
	piup2	2
	piup2	3
	dbf	d7,.loop11

	rts
  endif ; FEATURE_FREQSCOPE

*********** Scopet PS3M
*** stereoscope

multiscope

	move.l	ps3m_buff1(a5),a1
	move.l	(a1),a1

	move.l	s_draw1(a4),a0
	lea	19(a0),a0
	bsr.b	.h

	move.l	ps3m_buff2(a5),a1
	move.l	(a1),a1
	move.l	s_draw1(a4),a0
	lea	39(a0),a0
.h

	move.l	ps3m_playpos(a5),a2
	move.l	(a2),d5
	lsr.l	#8,d5
	lea	s_multab(a4),a2
		
	moveq	#160/8-1-1,d7
	moveq	#1,d0
	move	#$80,d6
	bsr.w	getps3mb

multiscope0

.drlo	
 
 rept 8
 	move	d6,d2
	add.b	(a1,d5.l),d2
	lsr.b	#2,d2
	add	d2,d2
	move	(a2,d2),d2
	or.b	d0,-40(a0,d2)
	or.b	d0,(a0,d2)
	add.b	d0,d0

	addq.l	#1,d5
;	and.l	d4,d5
	cmp.l	d4,d5
	bne.b	*+4
	moveq	#0,d5
 endr
	
	moveq	#1,d0
	sub	d0,a0
	dbf	d7,.drlo
	rts




multiscopefilled

	move.l	ps3m_buff1(a5),a1
	move.l	(a1),a1

	move.l	s_draw1(a4),a0
	lea	19(a0),a0
	bsr.b	.h

	move.l	ps3m_buff2(a5),a1
	move.l	(a1),a1
	move.l	s_draw1(a4),a0
	lea	39(a0),a0
.h

	move.l	ps3m_playpos(a5),a2
	move.l	(a2),d5
	lsr.l	#8,d5
	lea	s_multab(a4),a2
		
	moveq	#160/8-1-1,d7
	moveq	#1,d0
	move	#$80,d6
	bsr.w	getps3mb

multiscopefilled0

hurl	macro 
	move	d6,d2
	add.b	(a1,d5.l),d2
	bpl.b	.ok\1
	not.b	d2
.ok\1
	lsr.b	#2,d2
	add	d2,d2
	move	(a2,d2),d2
	or.b	d0,(a0,d2)
	add.b	d0,d0
	addq.l	#1,d5

;	and.l	d4,d5
	cmp.l	d4,d5
	bne.b	*+4
	moveq	#0,d5
	endm

.drlo	
	hurl	1
	hurl	2
	hurl	3
	hurl	4
	hurl	5
	hurl	6
	hurl	7
	hurl	8

	moveq	#1,d0
	sub	d0,a0
	dbf	d7,.drlo
	rts




***** hipposcope ps3m:lle

multihipposcope:
	move.l	ps3m_buff1(a5),a1
	move.l	(a1),a1

	move	#240,d0
	bsr.b	.1
	move.l	ps3m_buff2(a5),a1
	move.l	(a1),a1
	moveq	#88,d0
	
.1

	move.l	ps3m_playpos(a5),a2
	move.l	(a2),d5
	lsr.l	#8,d5

	lea	s_multab(a4),a2
	move.l	s_draw1(a4),a3
	bsr.b	getps3mb
	moveq	#32,d6
	moveq	#120-1,d7
.d

	move.b	(a1,d5),d1
	asr.b	#1,d1
	ext	d1
	add	d0,d1

	move.b	5(a1,d5),d2
	asr.b	#2,d2 
	ext	d2
	add	d6,d2
	add	d2,d2
	move	(a2,d2),d3

	move	d1,d2
	lsr	#3,d2
	sub	d2,d3
	bset	d1,39(a3,d3)

	add	d2,d3			* toinen pixeli viereen
	addq	#1,d1
	move	d1,d2
	lsr	#3,d2
	sub	d2,d3
	bset	d1,39(a3,d3)

	addq	#1,d5
	and	d4,d5

	dbf	d7,.d

	rts


getps3mb
	push	a0
	move.l	ps3m_buffSizeMask(a5),a0
	move.l	(a0),d4
	pop	a0
	rts






*********************************************************************
* NoteScroller (ProTracker)
*

noteScrollerHorizontalLines
*** viiva
	move.l	s_draw1(a4),a0
	move	s_scopeDrawAreaModulo(a4),d2
	* first line at y-coordinate
	move	s_scopeDrawAreaHeight(a4),d3
	lsr	#1,d3
	sub	#9,d3
	mulu	d2,d3
	add	d3,a0

.normal
	* 2nd row offset
	lsl	#3,d2
	subq	#2,d2
	* 19 times 16 pixels horizontally
	move	s_scopeDrawAreaModulo(a4),d0
	lsr	#1,d0
	subq	#1,d0
	move	#$aaaa,d1
.raita	
	* put 16 pixels here
	or.w	d1,(a0)+
	* ...and 8 pixels below
	or.w	d1,(a0,d2)
	dbf	d0,.raita
	rts

* out:
*  d4 = modulo, or NULL
*  a2 = data
noteScrollerGetFont
	* Check if font is usable
	move.l	fontbase(a5),a2
	moveq	#8,d4
	cmp	tf_YSize(a2),d4
	bne.b 	.try1
	cmp	tf_XSize(a2),d4 
	bne.b 	.try1
	btst	#FPB_PROPORTIONAL,tf_Flags(a2)
	beq.b	.okFont
.try1
	* Fallback to topaz
	move.l	topazbase(a5),a2
	cmp	tf_YSize(a2),d4 
	bne.b 	.badFont
	cmp	tf_XSize(a2),d4 
	bne.b 	.badFont
	btst	#FPB_PROPORTIONAL,tf_Flags(a2)
	beq.b	.okFont
.badFont
	* Can't use these fonts, give up!
	moveq	#0,d4
	rts
.okFont
	* store font data into a2 and d4 for fast access later
	move	tf_Modulo(a2),d4		* font modulo
	move.l	tf_CharData(a2),a2		* data
	rts


patternScopePt:
noteScrollerPt:
notescroller:
	move	#SCOPE_DRAW_AREA_WIDTH_DEFAULT,d0
	moveq	#SCOPE_DRAW_AREA_HEIGHT_DEFAULT,d1
	cmp.b	#QUADMODE2_PATTERNSCOPEXL,s_quadmode2(a4)
	bne.b 	.normHeight
	move	#SCOPE_DRAW_AREA_HEIGHT_DOUBLE,d1
.normHeight
	cmp	s_scopeDrawAreaWidth(a4),d0
	bne.b	.plz
	cmp	s_scopeDrawAreaHeight(a4),d1
	beq.b	.sizeOk
.plz	bsr.w	requestScopeDrawAreaChange
	rts
.sizeOk

	bsr.w	.notescr
	bsr.w	noteScrollerHorizontalLines

	* Volume update
	lea	scopeData+scope_ch1(a5),a0
	* channel bitmask
	moveq	#1,d2
	moveq	#4-1,d1
	lea	s_patternScopeVolumes(a4),a2
.setscope	
	* see if channel bit is on
	move.b	scopeData+scope_trigger(a5),d0
	and.b	d2,d0
	beq.b	.e	
	* was on, clear it, and copy the volume value
	move.b  d2,d0 	
	not.b   d0
	and.b  	d0,scopeData+scope_trigger(a5)
	move	ns_tempvol(a0),d0
	CLAMPVOL d0
	move	d0,(a2)
.e	
	* next bit
	add.b	d2,d2
	lea	ns_size(a0),a0
	addq	#2,a2
	dbf	d1,.setscope

	move	s_patternScopeVolumes+0(a4),d0
	moveq	#2,d1
	bsr.b	.palkki
	move	s_patternScopeVolumes+2(a4),d0
	moveq	#11,d1
	bsr.b	.palkki
	move	s_patternScopeVolumes+4(a4),d0
	moveq	#20,d1
	bsr.b	.palkki
	move	s_patternScopeVolumes+6(a4),d0
	moveq	#29,d1
	bsr.b	.palkki

	lea	scopeData+scope_ch1(a5),a3
	move.b	#%11100000,d2
	moveq	#38,d1
	bsr.b	.palkki2
	lea	scopeData+scope_ch2(a5),a3
	moveq	#%1110,d2
	moveq	#38,d1
	bsr.b	.palkki2
	lea	scopeData+scope_ch3(a5),a3
	moveq	#39,d1
	move.b	#%11100000,d2
	bsr.b	.palkki2
	lea	scopeData+scope_ch4(a5),a3
	moveq	#%1110,d2
	moveq	#39,d1
	bsr.b	.palkki2

.ohi
	* animate the volume bars towards bottom
	lea	s_patternScopeVolumes(a4),a0
	moveq	#4-1,d0
.orl	tst	(a0)+
	beq.b	.urh
	subq	#1,-2(a0)
.urh	dbf	d0,.orl
	rts


***** Volumepalkgi

.palkki
	mulu	mainvolume(a5),d0
	lsr	#6,d0

	move.l	s_draw1(a4),a0
	* horizontal position
	add	d1,a0
	* move to bottom
	move	s_quadNoteScrollerLines(a4),d1
	lsl	#3,d1
	mulu	s_scopeDrawAreaModulo(a4),d1
	add.l	d1,a0

	lea	.paldata(pC),a1
	moveq	#-2,d2
	subq	#1,d0
	bmi.b	.yg
.purl	and.b	d2,(a0)
	move.b	-(a1),d1
	or.b	d1,(a0)
	lea	-40(a0),a0
	dbf	d0,.purl	
.yg	rts



**** Periodpalkki
	
.palkki2
	cmp	#2,ns_length(a3)
	bls.b	.h
	moveq	#0,d0
	move	ns_period(a3),d0
	beq.b	.h
	* range is 108 - 907
	sub	#108,d0

	* this many vertical pixels
	move	s_quadNoteScrollerLines(a4),d3
	lsl	#3,d3
	subq	#5,d3
	mulu	d3,d0
	divu	#907-108,d0

	move.l	s_draw1(a4),a0
	lea	s_multab(a4),a1
	add	d0,d0
	move	(a1,d0),d0
	add	d0,a0
	add	d1,a0

	or.b	d2,(a0)
	or.b	d2,40(a0)
	or.b	d2,80(a0)
	or.b	d2,120(a0)

.h	rts




* 8x64
	DC.B	$FC,$FC,$FC,$FC
	DC.B	$FC,$DC,$FC,$7C
	DC.B	$FC,$DC,$FC,$54
	DC.B	$FC,$5C,$FC,$54
	DC.B	$FC,$54,$FC,$54
	DC.B	$B8,$54,$FC,$54
	DC.B	$B8,$54,$AC,$54
	DC.B	$B8,$54,$A8,$54
	DC.B	$A8,$54,$A8,$54
	DC.B	$88,$54,$28,$54
	DC.B	$88,$54,$00,$54
	DC.B	$88,$54,$00,$54
	DC.B	$00,$54,$00,$54
	DC.B	$00,$10,$00,$54
	DC.B	$00,$10,$00,$00
	DC.B	$00,$10,$00,$00
.paldata


**************** Piirret‰‰n patterndata

.notescr
	pushm	a4/a5/a6

	lea	kplbase(a5),a0
	move.l	k_songdataptr(a0),a3
	moveq	#0,d0
	move	k_songpos(a0),d0
	move.b	(a3,d0),d0
	lsl	#6,d0
	add	k_patternpos(a0),d0
	lsl.l	#4,d0
	add.l	d0,a3
	lea	1084-952(a3),a3

	* draw this many lines
	move	s_quadNoteScrollerLines(a4),d7
	subq	#1,d7 * dbf
	move	k_patternpos(a0),d6	* eka rivi?

	* Target
	move.l	s_draw1(a4),a0
	addq	#3,a0

	* figure out where to place the first line
	move	d6,d0
	; move the cursor in the middle
	sub	s_quadNoteScrollerLinesHalf(a4),d0
	bpl.b	.ok
	neg	d0
	sub	d0,d7

	move	s_quadNoteScrollerLinesHalf(a4),d1
	sub	d0,d1
	sub	d1,d6
	lsl	#4,d1
	sub	d1,a3

	; vertical position in target 
	mulu	#8*40,d0
	add.l	d0,a0

	bra.b	.ok2
.ok
	move	s_quadNoteScrollerLinesHalf(a4),d0
	lsl	#4,d0
	sub	d0,a3
	sub	s_quadNoteScrollerLinesHalf(a4),d6
.ok2

	
	bsr.w	noteScrollerGetFont * Uses d4,a2 only
	beq.w	.exitNoteScroller

	* Target screen addr goes in a4 
	move.l	a0,a4

	* convert row in D6 to BCD
	moveq	#0,d0
	move	d6,d0
	divu	#10,d0 
	lsl.b	#4,d0
	move.w	d0,d6
	swap	d0 
	or.b	d0,d6	

	* d3 is FREE!
	* use for horizontal skipping
	moveq	#9,d3

	* vertical loop
	* line loop
.plorl
	* print linenumber, in BCD format
	* avoid DIVU in loop this way
	lea	.pos(pc),a0		

	move.w	d6,d0	* $00XY
	lsl.w	#4,d0	* $0XY0
	lsr.b	#4,d0	* $0X0Y
	or.w	#$3030,d0
	move	d0,(a0)

	move.l	a4,a1
	subq	#3,a1
	moveq	#2-1,d1
	bsr.w	.print

	* horizontal loop
	* print 4 horizontal notes	
	moveq	#4-1,d5
.plorl2
	* builds a one note text here
	lea	.note(pc),a0

	moveq	#0,d0
	move.b	2(a3),d0
	bne.b	.jee
	* empty note
	clr.w	(a0)+
	clr.b	(a0)+
	bra.b	.nonote

* notes table is here so that a shorter
* access can be used below
.notes	dc.b	"C-"
	dc.b	"C#"
	dc.b	"D-"
	dc.b	"D#"
	dc.b	"E-"
	dc.b	"F-"
	dc.b	"F#"
	dc.b	"G-"
	dc.b	"G#"
	dc.b	"A-"
	dc.b	"A#"
	dc.b	"B-"
 	even

.jee
	* calculate octave number
	subq	#1,d0
	divu	#12*2,d0
	moveq	#'0',d1 
	* first octave is 1
	addq.b	#1,d0
	add.b	d0,d1
	* figure out note text
	swap	d0
	* two chars
	move	.notes(pc,d0.w),(a0)+
	move.b	d1,(a0)+
.nonote

	move.b	3(a3),d0	* sample num
	bne.b	.onh
	* a0 is odd here
	clr.b	(a0)+
	clr.b	(a0)+
	bra.b	.eihn
.onh
	* sample number pre-multiplied by 4
	lsr.b	#2,d0
	move.b	d0,d1
	* get the upper digit
	lsr.b	#4,d1
	bne.b	.onh2
	clr.b	(a0)+
	bra.b	.eihn2
.onh2	or.b	#'0',d1
	move.b	d1,(a0)+
.eihn2	
	* lower digit
	and.b	#$f,d0
	bsr.b	.hegs
.eihn

	move.b	(a3)+,d0	* command, premultiplied
	lsr.b	#2,d0
	bsr.b	.hegs
	move.b	(a3),d0 * command parameter
	move.b	d0,d1
	lsr.b	#4,d0	* upper char
	bsr.b	.hegs
	moveq	#$f,d0	* lower char
	and.b	d1,d0
	bsr.b	.hegs

	* print 8 chars
	* a4 = destination bufer
	move.l	a4,a1
	;lea	.note(pc),a0
	subq	#8,a0
	moveq	#8-1,d1
	bsr.b	.print

	* next note
	addq.l	#4-1,a3
	* next horizontal position
	;add	#9,a4
	add	d3,a4
	dbf	d5,.plorl2

	* next vertical position
	lea	(8*40-4*9)(a4),a4
	* next pattern line, check if at the end
	* clear X flag for ABCD
	sub.b	d0,d0
	* Next row in BCD
	moveq	#1,d0
	abcd.b	d0,d6
	* row 64 in BCD
	cmp.b	#$64,d6
	dbeq d7,.plorl
.exitNoteScroller
	popm	a4/a5/a6	
	rts

* convert decimal number 0-9 into ASCII char
.hegs	cmp.b	#9,d0
	bhi.b	.high1
	or.b	#'0',d0
	move.b	d0,(a0)+
	rts
.high1	
	add.b	#-10+'A',d0
	move.b	d0,(a0)+
	rts

.note	dc.b	"00000000"
.pos	dc.b	"00"
 even

.print
	* a2 contains font data
	* d4 contains font modulo
	
	* get one char to print
	moveq	#0,d0
.ooe	
	move.b	(a0)+,d0
	beq.b	.space	 * space check
	* get char pixels
	lea	-$20(a2,d0),a6

	* do 8 pixels height
 	move.b	(a6),(a1)+	
	add	d4,a6
	move.b	(a6),1*40-1(a1)	
	add	d4,a6
	move.b	(a6),2*40-1(a1)	
	add	d4,a6
	move.b	(a6),3*40-1(a1)	
	add	d4,a6
	move.b	(a6),4*40-1(a1)	
	add	d4,a6
	move.b	(a6),5*40-1(a1)	
	add	d4,a6
	move.b	(a6),6*40-1(a1)	
	add	d4,a6
	move.b	(a6),7*40-1(a1)	
	* go to next horiz position
	dbf	d1,.ooe
	rts 
.space	
	* go to next horiz position
	addq	#1,a1
	dbf	d1,.ooe
	rts

	




***************************************************************************
* a0 = bitmap
* a1 = (playsidbase+50)
* d0 = kanava


;SIDscope
;	move.l	draw1(a5),a0
;	moveq	#0,d0
;	bsr.b	.1
;	bsr.b	.1
;	bsr.w	.1

;.1	bsr.b	.2
;	add	#10,a0
;	addq	#1,d0
;	rts

;.2	movem.l	d0-a6,-(sp)
;	move.l	_SIDBase(a5),a1
;	move.l	50(a1),a1
;	lea	multab(a5),a6

;	add.w	d0,d0
;	move.w	d0,d1
;	add.w	d0,d0
;	move.l	0(a1,d0.w),a3  * dd_SampleX
;	add.w	d0,d0
;	lea	lbl006b58,a2
;	lea	lbl006950,a4
;	lsl.w	#4,d0
;	add.w	d0,a4
;	lea	lbl006b50,a5
;	moveq	#64-1,d3
;	move.w	#32*40,d4
;	move.w	$20(a1,d1.w),d6 * dd_EnveX
;	bne.s	.lbc006706

;.lbc0066f8	move.w	d4,(a4)+
;	dbra	d3,.lbc0066f8

;	lea	-$80(a4),a4
;	bra.b	.lbc006752

;.lbc006706	cmp.w	#$7a,$18(a1,d1.w)  * dd_PeriodX
;	bls.s	.lbc0066f8

;	moveq	#0,d4
;	move.l	#$7b0000,d5
;	divu	$18(a1,d1.w),d5 * dd_PeriodX
;	move.w	$10(a1,d1.w),d7 * dd_LengthX
;	move.w	0(a5,d1.w),d2
;.lbc006722	add.w	d5,0(a2,d1.w)
;	addx.w	d4,d2
;.lbc006728	cmp.w	d7,d2
;	blt.s	.lbc006730

;	sub.w	d7,d2
;	bra.s	.lbc006728

;.lbc006730	
;	move.b	0(a3,d2.w),d0
;	ext	d0
;	muls	d6,d0
;	asr	#8,d0
;;	asr	#1,d0
;	add	#32,d0
;	add	d0,d0
;	move	(a6,d0),(a4)+
;	dbra	d3,.lbc006722

;	lea	-$80(a4),a4
;	move.w	d2,0(a5,d1.w)
;.lbc006752
;;	move.w	#$3e0,d0
;;.lbc006756
;;	clr.l	0(a0,d0.w)
;;	clr.l	4(a0,d0.w)
;;	sub.w	#$20,d0
;;	bpl.s	.lbc006756

;	moveq	#31-1,d0
;	move.l	#$80000000,d1
;	move.l	#$40000000,d4
;	moveq	#40,d6
;.lbc006774
;	move.w	(a4)+,d2
;	move.w	(a4),d3
;	or.l	d1,0(a0,d2.w)
;	or.l	d4,0(a0,d3.w)
;	cmp.w	d3,d2
;	beq.s	.lbc0067b6

;	bhi.s	.lbc00679e

;.lbc006786	move.w	d3,d5
;	sub.w	d2,d5
;	cmp.w	d6,d5
;	bls.s	.lbc0067b6

;	add.w	d6,d2
;	sub.w	d6,d3
;	or.l	d1,0(a0,d2.w)
;	or.l	d4,0(a0,d3.w)
;	bra.b	.lbc006786

;.lbc00679e	move.w	d2,d5
;	sub.w	d3,d5
;	cmp.w	d6,d5
;	bls.s	.lbc0067b6

;	add.w	d6,d3
;	sub.w	d6,d2
;	or.l	d1,0(a0,d2.w)
;	or.l	d4,0(a0,d3.w)
;	bra.b	.lbc00679e

;.lbc0067b6	ror.l	#1,d1
;	ror.l	#1,d4
;	dbra	d0,.lbc006774

;	move.w	(a4)+,d2
;	move.w	(a4),d3
;	or.l	d1,0(a0,d2.w)
;	or.l	d4,4(a0,d3.w)
;	cmp.w	d3,d2
;	beq.s	.lbc006800

;	bhi.s	.lbc0067e8

;.lbc0067d0	move.w	d3,d5
;	sub.w	d2,d5
;	cmp.w	d6,d5
;	bls.s	.lbc006800

;	add.w	d6,d2
;	sub.w	d6,d3
;	or.l	d1,0(a0,d2.w)
;	or.l	d4,4(a0,d3.w)
;	bra.b	.lbc0067d0

;.lbc0067e8	move.w	d2,d5
;	sub.w	d3,d5
;	cmp.w	d6,d5
;	bls.s	.lbc006800

;	add.w	d6,d3
;	sub.w	d6,d2
;	or.l	d1,0(a0,d2.w)
;	or.l	d4,4(a0,d3.w)
;	bra.b	.lbc0067e8

;.lbc006800	ror.l	#1,d1
;	ror.l	#1,d4
;	moveq	#31-1,d0
;.lbc006806	move.w	(a4)+,d2
;	move.w	(a4),d3
;	or.l	d1,4(a0,d2.w)
;	or.l	d4,4(a0,d3.w)
;	cmp.w	d3,d2
;	beq.s	.lbc006848

;	bhi.s	.lbc006830

;.lbc006818	move.w	d3,d5
;	sub.w	d2,d5
;	cmp.w	d6,d5
;	bls.s	.lbc006848

;	add.w	d6,d2
;	sub.w	d6,d3
;	or.l	d1,4(a0,d2.w)
;	or.l	d4,4(a0,d3.w)
;	bra.b	.lbc006818

;.lbc006830	move.w	d2,d5
;	sub.w	d3,d5
;	cmp.w	d6,d5
;	bls.s	.lbc006848

;	add.w	d6,d3
;	sub.w	d6,d2
;	or.l	d1,4(a0,d2.w)
;	or.l	d4,4(a0,d3.w)
;	bra.b	.lbc006830

;.lbc006848	ror.l	#1,d1
;	ror.l	#1,d4
;	dbra	d0,.lbc006806

;	movem.l	(sp)+,d0-a6
;	rts


*******************************************************************

********** Palkit

leverEor
	* Flag: eor
	moveq	#1,d4
	bra.b	lever\.go

lever
	* Flag: or
	moveq	#0,d4
.go
	lea	scopeData+scope_ch1(a5),a3
	moveq	#4-1,d7
	move.l	s_draw1(a4),a2
.l	move.l	a2,a0
	bsr.b	.drawLever
	lea	10(a2),a2
	lea	ns_size(a3),a3
	dbf	d7,.l
	rts
	

* 907-108
.drawLever
	cmp	#2,ns_length(a3)
	bls.b	.h
	moveq	#0,d1
	move	ns_period(a3),d1
	beq.b	.h
	sub	#108,d1
	lsl	#1,d1
	divu	#27,d1		* lukualueeksi 0-59

	* clamp
	cmp	#59,d1
	bls.b	.1
	move	#59,d1
.1

	lea	s_multab(a4),a1
	add	d1,d1
	add	(a1,d1),a0

	move	ns_tempvol(a3),d0
	mulu	mainvolume(a5),d0
	lsr	#6,d0
	bne.b	.pad
	moveq	#1,d0
.pad	
	lsl	#3,d0
	subq	#8,d0
	bpl.b	.ojdo
	moveq	#0,d0
.ojdo
	lea	s_scopeHorizontalBarTable(a4),a1
	movem.l	(a1,d0),d0/d1

	move.l	#$55555555,d3
	and.l	d3,d0
	and.l	d3,d1

	move.l	d0,d2
	move.l	d1,d3
	roxl.l	#1,d3
	roxl.l	#1,d2

	tst.b	d4
	bne.b	.eor

	or.l	d0,(a0)+
	or.l	d1,(a0)
	or.l	d2,40-4(a0)
	or.l	d3,40(a0)
	or.l	d0,80-4(a0)
	or.l	d1,80(a0)
	or.l	d2,120-4(a0)
	or.l	d3,120(a0)

.h	rts

.eor
	eor.l	d0,(a0)+
	eor.l	d1,(a0)
	eor.l	d2,40-4(a0)
	eor.l	d3,40(a0)
	eor.l	d0,80-4(a0)
	eor.l	d1,80(a0)
	eor.l	d2,120-4(a0)
	eor.l	d3,120(a0)
	rts

****** taulukkoon 1-64 pix leveit‰ palkkeja

makeScopeHorizontalBars	
	lea	s_scopeHorizontalBarTable(a4),a0
	moveq	#64-1,d0
	moveq	#0,d1
	moveq	#0,d2
.l	roxr.l	#1,d1
	roxr.l	#1,d2
	bset	#31,d1
	move.l	d1,(a0)+
	move.l	d2,(a0)+
	dbf	d0,.l
	rts


*** Sample scope
*** Any sample played by the sample player

samplescope
	bsr.b	samples0
	move.l	samplepointer(a5),a1
	move.l	(a1),a1
	tst.b	samplestereo(a5)
	bne.b	.st
	lea	39(a0),a0
	moveq	#39-1,d7
	bra.w	multiscope0
.st	
	lea	19(a0),a0
	moveq	#19-1,d7
	bsr.w	multiscope0
	bsr.b	samples0
	lea	39(a0),a0
	move.l	samplepointer2(a5),a1
	move.l	(a1),a1
	moveq	#19-1,d7
	bra.w	multiscope0

samplescopefilled
	bsr.b	samples0
	move.l	samplepointer(a5),a1
	move.l	(a1),a1
	tst.b	samplestereo(a5)
	bne.b	.st
	lea	39(a0),a0
	moveq	#39-1,d7
	bra.w	multiscopefilled0
.st	
	lea	19(a0),a0
	moveq	#19-1,d7
	bsr.w	multiscopefilled0
	bsr.b	samples0
	lea	39(a0),a0
	move.l	samplepointer2(a5),a1
	move.l	(a1),a1
	moveq	#19-1,d7
	bra.w	multiscopefilled0


samples0
	move.l	samplefollow(a5),a0
	move.l	(a0),d5
;	move.l	samplefollow(a5),d5

	move.l	samplebufsiz(a5),d4
	subq.l	#1,d4

	moveq	#1,d0
	move	#$80,d6

	lea	s_multab(a4),a2
	move.l	s_draw1(a4),a0
	rts


*********************************************************************
* GENERIC NOTESCROLLER
* Note scroller supporting the PI_PatternInfo data
* patternScopeGeneric
* noteScrollerGeneric
* patternScope2
noteScroller2:
	move.l	deliPatternInfo(a5),a1
	lea	PI_Stripes(a1),a0
	move	PI_Voices(a1),d7
	clr	PI_CurrentChannelNumber(a1)

* Required height in d1
	moveq	#SCOPE_DRAW_AREA_HEIGHT_DEFAULT,d1
	cmp.b	#QUADMODE2_PATTERNSCOPEXL,s_quadmode2(a4)
	bne.b	.notXl
	move	#SCOPE_DRAW_AREA_HEIGHT_DOUBLE,d1
.notXl
	cmp	#4,d7
	bhi.b	.over

	move	#SCOPE_DRAW_AREA_WIDTH_DEFAULT,d0
	bsr.w	requestScopeDrawAreaChange
	beq.b	.proceed
	* resize will happen later
	rts
.over
	
	* max 18 stripes fit into 640 pixels
	cmp	#18,d7
	bls.b	.max16
	moveq	#18,d7
.max16
	* Request larger/wider/narrower window
	move	d7,d0

	cmp	#SCOPE_SMALL_FONT_CHANNEL_LIMIT,d7
	bhi.b	.narrow
	* normal font stripe
;	mulu	#72,d0
	move	d0,d2 * tricky mul with 72
	lsl	#6,d2
	lsl	#3,d0
	add	d2,d0
	bra.b	.wide
.narrow
	* Test if font is available
	tst.l	minifontbase(a5)
	beq.b	.x
	* each narrow stripe is 32 pix
	lsl	#5,d0 ;mulu	#32,d0 	
.wide
	* some right margin
	;add	#32,d0
	* ensure divisible by 16 for blitter safety
	;add	#15,d0
	add	#32+15,d0
	and	#$fff0,d0

	bsr.w	requestScopeDrawAreaChange
	beq.b	.proceed
	rts

.proceed

	* magic flag: display row numbers column	 
	lea	.pos(pc),a6
	clr.b	(a6)

	* Draw here
	move.l	s_draw1(a4),a6

	* Channel count
	subq	#1,d7
.loop
	pushm	d6/d7/a0/a4/a5/a6
	move.l	(a0),a0		* stripe data
	bsr.b	.doStripe
	popm	d6/d7/a0/a4/a5/a6

	* magic flag: no row numbers more than once
	lea	.pos(pc),a2
	tst.b	(a2)
	bmi.b	.wasSet
	* jump over number column
	addq	#3,a6
	st	(a2)
.wasSet
	addq	#4,a0 		* next stripe

	cmp	#SCOPE_SMALL_FONT_CHANNEL_LIMIT,PI_Voices(a1)
	bls.b	.voices4
	* 32 pixels per stripe
	addq	#4,a6		* next screen pos horizontal
	bra.b	.continue
.voices4
	* 72 pixels per stripe
	add	#9,a6
.continue
	addq	#1,PI_CurrentChannelNumber(a1)
	dbf	d7,.loop

	bsr.w	noteScrollerHorizontalLines
.x	rts

.xy	

 if DEBUG
* MTM modules commonly have empty stripes, caught
* by insanity checks.

; 	move	#$0f0,$dff180
;	move.l	moduleaddress(a5),d0
;	move.l	modulelength(a5),d1
;	move.l	a0,d2
;	SDPRINT	"INSANITY %lx %ld -> %lx"
 endif
	rts


***********************************************************
* Draw one stripe
***********************************************************

.doStripe

*** Sanity check, is the stripe address legal?

	move.l	a0,d0
	beq.b	.xy

	move.l	ps3mUnpackedPattern(a5),d0
	tst.l	d0
	beq.b	.noPattern
	* Pointer within the unpacked pattern region?

	cmp.l	d0,a0
	bhs.b	.sane
	add.l	#32*4*64,d0
	cmp.l	d0,a0
	blo.b	.sane

.noPattern
	* Pointer within the module data?

	cmp.w	#1024,a0
	bls.b	.xy
	move.l  moduleaddress(a5),a3
   	cmp.l   a3,a0
	bls.b	.xy
    	add.l   modulelength(a5),a3
    	cmp.l   a3,a0
   	bhs.b   .xy
.sane

*** calculate stuff
	
	* draw this many lines
	move	s_quadNoteScrollerLines(a4),d7
	subq	#1,d7 * dbf
	move	PI_Pattpos(a1),d6

	* current position in data
	move	d6,d0
	mulu	PI_Modulo+2(a1),d0 
	add.l	d0,a0

	* figure out where to place the first line
	move	d6,d0
	; move the cursor in the middle
	sub	s_quadNoteScrollerLinesHalf(a4),d0
	bpl.b	.ok
	neg	d0
	sub	d0,d7

	move	s_quadNoteScrollerLinesHalf(a4),d1
	sub	d0,d1
	sub	d1,d6
	mulu	PI_Modulo+2(a1),d1
	* adjust data pointer
	sub	d1,a0

	* vertical position in target 
	mulu	s_scopeDrawAreaModulo(a4),d0
	lsl.l	#3,d0
	add.l	d0,a6
	bra.b	.ok2
.ok
	move	s_quadNoteScrollerLinesHalf(a4),d0
	mulu	PI_Modulo+2(a1),d0
	sub	d0,a0
	sub	s_quadNoteScrollerLinesHalf(a4),d6
.ok2
	bsr.w	noteScrollerGetFont * uses d4,a2
	beq.w	.exitNoteScroller
	
	
* d4 = font modulo
* d6 = line number
* d7 = rows to draw
* d7 = screen modulo, other half
* a0 = pattern data
* a1 = pattern info
* a2 = font data
* a4 = destination draw buffer

	swap	d7
	move	s_scopeDrawAreaModulo(a4),d7
	move	d7,d0 
	lsl	#3,d0 	* x8, full height of font
	swap	d7

	* destination draw buffer	
	move.l	a6,a4

***********************************************************
* Line numbers column
***********************************************************

	lea	.pos(pc),a3
	tst.b	(a3)
	bmi.b	.skipNumbers

	pushm	d6/d7/a4/a5
	* row modulo in d0
	
	* row number in D2 as BCD
	moveq	#0,d3
	move	d6,d3
	* Keep visual range at 0..99, larger won't fit
	cmp		#100,d3
	blo.b	.s
	sub		#100,d3
.s
	divu	#10,d3 
	lsl.b	#4,d3
	move	d3,d2
	swap	d3 
	or.b	d3,d2
	
.lineNumberRowLoop
	* get screen modulo
	swap	d7

	* print line number as BCD from D2 
	move	d2,d3	* $00XY
	lsl.w	#4,d3	* $0XY0
	lsr.b	#4,d3	* $0X0Y
	or.w	#$3030,d3
	move	d3,(a3)

	move.l	a4,a5
	moveq	#2-1,d3
	bsr.w	.print
	subq	#2,a3 	* restore a3

	* next vertical draw position, one font height down
	* row modulo is in d0
	add	d0,a4

	* clear X flag for ABCD
	sub.b	d3,d3
	* Next row in BCD
	moveq	#1,d3
	abcd.b	d3,d2
	
	* get loop counter
	swap	d7

	* next pattern line, check if at the end
	addq	#1,d6
	cmp	PI_Pattlength(a1),d6
	dbeq	d7,.lineNumberRowLoop

	popm	d6/d7/a4/a5
	* move "cursor" 3 chars to the right 
	addq	#3,a4

.skipNumbers

	* Select font for note data
	cmp	#SCOPE_SMALL_FONT_CHANNEL_LIMIT,PI_Voices(a1)
	bls.b	.normalFont
	move.l	minifontbase(a5),a2
	move	tf_Modulo(a2),d4		
	move.l	tf_CharData(a2),a2		
.normalFont
	
***********************************************************
* Note column
***********************************************************

.rowLoop
	* get screen modulo for .print and .printSmall routines
	swap	d7

	* save a1
	move.l	a1,d5

* ChipTracker, TME, Mugician2, TCBTracker, etc
* register usage: d0-d3, a1

	* Get note data at a0
	move.l	PI_Convert(a1),a3
	jsr	(a3)
	move.l	d5,a1

* d0 = period
* d1 = sample num
* d2 = command 
* d3 = command argument

	moveq	#0,d5
	lea	.note(pc),a3
	tst	d0
	beq.b	.emptyNote
	* Check magic flag: negative indicates note indices
	tst	PI_Speed(a1)	
	bmi.b	.notPeriod
	lea	periods(pc),a5
	lea	periodsEnd(pc),a6
.findPeriod
	cmp	(a5)+,d0
	beq.b	.found
	addq	#1,d5
	cmp.l	a6,a5
	bne.b	.findPeriod
* Unknown
	move.w  #'**',(a3)+
	move.b  #'*',(a3)+
	bra.b	.unknownNote

.notes	dc.b	"C-"
	dc.b	"C#"
	dc.b	"D-"
	dc.b	"D#"
	dc.b	"E-"
	dc.b	"F-"
	dc.b	"F#"
	dc.b	"G-"
	dc.b	"G#"
	dc.b	"A-"
	dc.b	"A#"
	dc.b	"B-"
 	even

* Use value as an index
.notPeriod
	move	d0,d5
	* indices start from 1
	subq	#1,d5
.found
	* print note
	* divide to get octave
	divu	#12,d5
	* convert octave into text
	moveq	#'0',d0
	* first octave shall be 1, not 0
	addq.b	#1,d5
	add.b	d5,d0
	* convert note into text
	swap 	d5
	add	d5,d5
	move.w	.notes(pc,d5),(a3)+
	* print octave
	move.b	d0,(a3)+
	bra.b	.wasNote

.emptyNote
	clr.w	(a3)+
	clr.b	(a3)+
.unknownNote
.wasNote

	* sample 00-ff
	move.b	d1,d0
	beq.b	.noSampleNum

	lsr.b	#4,d0
	bsr.b	.convertD0ToCharInA3
	moveq	#$f,d0
	and.b	d1,d0
	bsr.b	.convertD0ToCharInA3Fill
	bra.b	.wasSampleNum

.noSampleNum
	clr.b	(a3)+
	clr.b	(a3)+

.wasSampleNum

	* Command 0-Z
	move.b	d2,d0
	bsr.b	.convertD0ToCharInA3Fill

	* Param 00-ff
	move.b	d3,d0
	lsr.b	#4,d0
	bsr.b	.convertD0ToCharInA3Fill
	moveq	#$f,d0
	and.b	d3,d0
	bsr.b	.convertD0ToCharInA3Fill

	; to the start of .note
	;lea	.note(pc),a3
	subq	#8,a3

	* print a3 into a4
	move.l	a4,a5
	moveq	#8-1,d3
	
	cmp	#SCOPE_SMALL_FONT_CHANNEL_LIMIT,PI_Voices(a1)
	bls.b	.printNorm
	bsr.b	.printSmall
	bra.b	.wasSmall
.printNorm
	bsr.b	.print
.wasSmall
	* next vertical draw position, one font height down
	move	d7,d3
	lsl	#3,d3	* times 8
	add	d3,a4

	* get loop counter
	swap	d7

	* Next row in data
	add.l	PI_Modulo(a1),a0
	* Row counter
	addq	#1,d6
	cmp	PI_Pattlength(a1),d6
	dbeq	d7,.rowLoop

.exitNoteScroller
	rts

.convertD0ToCharInA3
	beq.b	.emptyChar
.convertD0ToCharInA3Fill
	cmp.b	#9,d0
	bhi.b	.high1
	or.b	#'0',d0
	move.b	d0,(a3)+
	rts
.high1	
	add.b	#-10+'A',d0
	move.b	d0,(a3)+
	rts
.emptyChar 
	clr.b	(a3)+
	rts

* Large font print
* in:
*   a5 = dest draw buffer
*   a3 = text to draw
*   a2 = contains font data
*   d4 = contains font modulo

.print
	* get one char to print
	moveq	#0,d5
	move.l	a5,d1
.charLoop	
	move.b	(a3)+,d5
	beq.b	.space
	* get char pixels
	lea	-$20(a2,d5),a6
	* do 8 pixels height
 rept 7
 	move.b	(a6),(a5)	
	add	d4,a6
	add	d7,a5
 endr
	move.b	(a6),(a5)	
.space
	* next horiz position in screen buffer
	addq.l	#1,d1
	move.l	d1,a5
	
	* go to next horiz position
	dbf	d3,.charLoop
	rts

* Print text with small font
* Assumes:
* - fixed font
* - width 4
* - height 8
* - even number of chars as input text
* - d7 = screen modulo

.printSmall	

	* nibble mask
	move	#$f0,d2

	* dest buffer pointer
	move.l	a5,d1

	* get one char to print here
	moveq	#0,d5
.charLoop2	
	* even position

	move.b	(a3)+,d5
	beq.w	.evenCharSkip * space check

	* get char pixels
	* check which source nibble to use
	* index should be halved since 4 pixels per char
	ror.l	#1,d5
	lea	-$10(a2,d5),a6	* space char $20/2
	bmi.b	.lowNib

 rept 7
 	move.b	(a6),d0 
	and.b	d2,d0 
 	or.b	d0,(a5)	
	add	d4,a6
	add	d7,a5
 endr
	move.b	(a6),d0 
	and.b	d2,d0 
 	or.b	d0,(a5)	

	bra.b	.evenCharDone

.lowNib

 rept 7
 	move.b	(a6),d0 
	lsl.b	#4,d0 
 	or.b	d0,(a5)	
	add	d4,a6
	add	d7,a5
 endr
	move.b	(a6),d0 
	lsl.b	#4,d0 
 	or.b	d0,(a5)	
* odd char done	


.evenCharDone
	move.l	d1,a5
.evenCharSkip

	* odd position

	move.b	(a3)+,d5
	beq.w	.oddCharDone	* space check

	* get char pixels
	ror.l	#1,d5
	lea	-$10(a2,d5),a6
	bmi.b	.lowNib2
 
  rept 7
 	move.b	(a6),d0 
	lsr.b	#4,d0
	or.b	d0,(a5)	
	add	d4,a6
	add	d7,a5
 endr
	move.b	(a6),d0 
	lsr.b	#4,d0
 	or.b	d0,(a5)	

	bra.b	.oddCharDone
.lowNib2
 rept 7
	moveq	#$f,d0
 	and.b	(a6),d0 
 	or.b	d0,(a5)	
	add	d4,a6
	add	d7,a5
 endr
	moveq	#$f,d0
 	and.b	(a6),d0 
 	or.b	d0,(a5)	
* odd char done	

.oddCharDone
	* go to next horiz position 
	addq.l	#1,d1
	move.l	d1,a5
	
	* next two input chars
	subq	#1,d3
	dbf	d3,.charLoop2
	rts

.note	dc.b	"00000000"
.pos	dc.b	"00"
 even

; End of scopes for now

********************************************************************************
*** SECTION ********************************************************************
*
* Module loading
*
********************************************************************************

*******
* Module loading
* Moduulin lataus
*
* in:
*  a0 = module file name with path 
*  a3 = list node 
*  d0 = ~0: Use double buffering
*

loadmodule:
	; Popup should close so that window is visible during load
	bsr.w	closeTooltipPopup
	st	loading(a5)
	* Store pointer to the name part. Used
	* do determine what to show in the infobox, and
	* also with the PS3M configuration file.
	move.l	l_nameaddr(a3),solename(a5)
	* Store this so that the name can ne urldecoded before showing.
	move.b	l_remote(a3),uriDecodeNameBeforeShowing(a5)
	* Check if a remote file
	beq.b	.doLoadModule

	move.b	d0,d7	* doublebuffering flag
	lea	-200(sp),sp	* space for output path
	move.l	sp,a0
	jsr	fetchRemoteFile
  if DEBUG
	move.l	sp,d0
	DPRINT	"Remote loaded: %s"
  endif
	move.l	sp,a0	* path to load from
	move.b	d7,d0   * double buffering flag
	bsr.b	.doLoadModule
	move.l	sp,d1
	push	d0	* save status
	lore	Dos,DeleteFile * delete tempfile
	pop	d0	* status into d0
	lea	200(sp),sp
	rts

* in:
*   a0 = path to load from
*   d0 = double buffering flag
.doLoadModule
	move.b	d0,d7
	beq.w	.nodbf

*****************************************************************
* Double buffer load
*****************************************************************
	DPRINT	"Double buffer load"

	* Load with double buffering.
	* Module being played is preserved while new one is loaded.

	* Tampering with module data here
	jsr	obtainModuleData

	move.l	a0,modulefilename(a5)

	* Store properties of current module
	lea	-40(sp),sp
	lea	(sp),a2
	move.l	modulelength(a5),(a2)+
	move.l	tfmxsamplesaddr(a5),(a2)+
	move.l	tfmxsampleslen(a5),(a2)+
	move.b	lod_tfmx(a5),(a2)

	* Reset the extra data properties
	* loadfile() sets for TFMX. For other files
	* they are untouched. freemodule() will free
	* these, setting to zero avoids double freemem
	* crash.
	clr.l	tfmxsamplesaddr(a5) 
	clr.l	tfmxsampleslen(a5)

;	move.l	modulefilename(a5),a0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d0
	lea	moduleaddress2(a5),a1
	lea	modulelength(a5),a2
	moveq	#0,d1			* kommentti talteen
	bsr.w	loadfile
	move.l	d0,d7			* store loadfile status

	clr.b	loading(a5)		* lataus loppu

	clr	songnumber(a5)
	clr	pos_maksimi(a5)
	clr	pos_nykyinen(a5)

	* Store properties of the module that was just loaded
	lea	20(sp),a2
	move.l	modulelength(a5),(a2)+
	move.l	tfmxsamplesaddr(a5),(a2)+
	move.l	tfmxsampleslen(a5),(a2)+
	move.b	lod_tfmx(a5),(a2)

	* Restore properties of current module
	lea	(sp),a2
	move.l	(a2)+,modulelength(a5)
	move.l	(a2)+,tfmxsamplesaddr(a5)
	move.l	(a2)+,tfmxsampleslen(a5)
	move.b	(a2),lod_tfmx(a5)

	push	d7

	jsr	releaseModuleData

	* At this point correct properties
	* for current module should be in place
	* for freeing to NOT CRASH.


	jsr	fadevolumedown
	move	d0,-(sp)
	DPRINT	"Replay end"
	;lore    Exec,Disable
	jsr	halt			* Vapautetaan se jos on
	;lore    Exec,Enable
	;;;move.l	modulefilename(a5),a0
	move.l	playerbase(a5),a0
	jsr	p_end(a0)

	;;;move.l	modulefilename(a5),a0
	jsr	freemodule	
	move	(sp)+,mainvolume(a5)

	pop	d7

	jsr	obtainModuleData

	* Finally store properties of the newly loaded module.
	lea	20(sp),a2
;	move.l	(a2)+,moduleaddress(a5)
	move.l	moduleaddress2(a5),moduleaddress(a5)
	move.l	(a2)+,modulelength(a5)
	move.l	(a2)+,tfmxsamplesaddr(a5)
	move.l	(a2)+,tfmxsampleslen(a5)
	move.b	(a2),lod_tfmx(a5)

	* Grab exe load status from loader
	move.b 	lod_exefile(a5),executablemoduleinit(a5)

	tst.l	d7
	beq.b	.nay
* errori? putsataan tfmx osotteet
	clr.l	tfmxsamplesaddr(a5)
	clr.l	tfmxsampleslen(a5)
.nay

	lea	40(sp),sp

	jsr	releaseModuleData

	cmp	#XPKERR_NOMEM,lod_xpkerror(a5)
	beq.b	.nomemdbf
	cmp	#XPKERR_SMALLBUF,lod_xpkerror(a5)
	beq.b	.nomemdbf
	cmp	#lod_nomemory,d7	* tuliko out of memory?
	beq.b	.nomemdbf		* uusi yritys, kun edellinen modi
	cmp	#lod_nomemoryf,d7	* ei enaa oo muistissa
	beq.b	.nomemdbf

	move.l	d7,-(sp)
	bra.b	.diddbf

.nomemdbf
	move.l	modulefilename(a5),a0

.nodbf
*****************************************************************
** Normal loading
*****************************************************************
	
 ifne DEBUG
	move.l	a0,d0
	DPRINT	 "Loading: %s"
 endif

	jsr	freemodule		* Varmistetaan

	clr	songnumber(a5)
	clr	pos_maksimi(a5)
	clr	pos_nykyinen(a5)
	move.l	a0,modulefilename(a5)

;	move.l	modulefilename(a5),a0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d0
	lea	moduleaddress(a5),a1
	lea	modulelength(a5),a2
	moveq	#0,d1			* kommentti talteen
	bsr.w	loadfile
	move.l	d0,-(sp)
	clr.b	loading(a5)		* lataus loppu

	clr.b	songover(a5)	* varmistuksia, hˆlmˆo


.diddbf	bsr.w	inforivit_clear
	jsr	reslider

	move.l	(sp)+,d0
	tst	d0
	bne.w	.err			* virhe lataamisessa

	* Grab exe load status from loader
	move.b 	lod_exefile(a5),executablemoduleinit(a5)

	* These two case have been identifier earlier during load phase
	tst.b	sampleinit(a5)
	bne.b	.nip
	tst.b	executablemoduleinit(a5)
	bne.b	.nip

	move.l	moduleaddress(a5),a0	* Oliko moduleprogram??
	cmp.l	#"HiPP",(a0)
	bne.b	.nipz
	cmp	#"rg",4(a0)
	beq.b	.nipa
.nipz
	cmp.l	#"HIPP",(a0)
	bne.b	.nip
	cmp	#"RO",4(a0)
	bne.b	.nip

.nipa
	lea	-150(sp),sp
	move.l	sp,a3
	move.l	modulefilename(a5),a0
.cop	move.b	(a0)+,(a3)+
	bne.b	.cop

	jsr	freemodule
	jsr	clearlist	* lista tyhj‰ks
	move.l	#PLAYING_MODULE_NONE,playingmodule(a5)

	move.l	sp,a0			* ohjelman nimi
	moveq	#-1,d4			* lippu
	jsr	loadprog		* ladataan moduuliohjelma
	lea	150+4(sp),sp
;	addq	#4,sp			* ei palata samaan aliohjelmaan!
	rts
.nip
	bsr.w	tutki_moduuli
	tst.l	d0
	bne.b	.unk_err		* ep‰m‰‰r‰inen tiedosto

	clr.b	contonerr_laskuri(a5)	* nollataan virhelaskuri
	rts	

**** Virhe, ja pit‰isi ladata toinen moduuli.
.iik
	cmp.l	#1,modamount(a5)
	beq.b	loaderr

	addq.b	#1,contonerr_laskuri(a5) 	* jos sattuu viisi per‰kk‰ist‰ 
	cmp.b	#5,contonerr_laskuri(a5) 	* virhett‰, keskeytet‰‰n
	bne.b	.iik2				* contonerror-toiminto
	clr.b	contonerr_laskuri(a5)
	bra.b	loaderr
.iik2
	bsr.w	inforivit_errc		* Skipping -teksti
	moveq	#50,d1
	lore	Dos,Delay

	move.l	#PLAYING_MODULE_NONE,playingmodule(a5)
	moveq	#1,d7			* seuraava piisi!
	jsr	soitamodi
	addq	#4,sp			* ei samaan paluuosoitteeseen!
	rts


.unk_err
	move.l	d0,-(sp)
	jsr	freemodule
	move.l	(sp)+,d0

.err	
	tst.b	contonerr(a5)		* Continue on error?
	bne.b	.iik
loaderr
	cmp	#lod_xpkerr,d0
	beq.w	xpkvirhe
	cmp	#lod_xfderr,d0
	beq.w	xfdvirhe
	cmp	#lod_tuntematon,d0
	beq.w	tuntematonvirhe

	move	d0,d1
	neg	d1
	add	d1,d1
	lea	.ertab2-2(pc,d1),a1
	add	(a1),a1
	bra.w	request			* requesteri

.ertab2	dr	openerror_t
	dr	readerror_t
	dr	memerror_t
	dr	cryptederror_t
	dr	error_t
	dr	unknownpperror_t
	dr	grouperror_t
	dr	noxpkerror_t
	dr	nopperror_t
	dr	error_t		* xpk errori muualla
	dr	unknown_t
	dr	nofast_t
	dr	execerr_t
	dr	lockerr_t
	dr	notafile_t
	dr	openerror_t
	dr	error_t
	dr	extract_t
	dr  readerror_t  * loadseg failure 

cryptederror_t
;	dc.b	"File is encrypted!",0
unknownpperror_t
;	dc.b	"Unknown PowerPacker format!",0

error_t
	dc.b	"Error!?",0
openerror_t
	dc.b	"Error opening file!",0
readerror_t
	dc.b	"Read error!",0
noxpkerror_t
	dc.b	"No xpkmaster.library!",0
nopperror_t
	dc.b	"No powerpacker.library!",0
unknown_t
	dc.b	"Unknown file format!",0
unknownDueToAhi_t
	dc.b	"Unknown file format!",10
	dc.b	"This may be because non-AHI",10
	dc.b	"replayers are disabled.",0
unknownDueToGroupDisabled_t
	dc.b	"Unknown file format!",10
	dc.b	"This may be because the",10
	dc.b	"player group is disabled.",0
nofast_t
memerror_t	
	dc.b	"Not enough memory!",0
;nofast_t dc.b	"Not enough fast memory!",0
execerr_t dc.b	"External error!",0
lockerr_t dc.b	"Can't lock on file!",0
notafile_t dc.b	"Not a file!",0
grouperror_t dc.b "Trouble with the player group!",10
		dc.b "Check that the file "
		dc.b '"HippoPlayer.group"'
		dc.b " is up-to-date.",0

windowerr_t	dc.b	"Couldn't to open window!",0
;extract_t	dc.b	"Extraction error!",0
extract_t	dc.b	"Extraction error!",10
		dc.b	"No known files found in archive.",0
 even	



xpkvirhe			* N‰ytet‰‰n XPK:n oma virheilmoitus.
	movem.l	d0-a6,-(sp)
	lea	.x(pc),a1
	lea	xarray(pc),a4
	pushpea	xpkerror(a5),(a4)
	bra.w	request2

.x	dc.b	"XPK error:",10
	dc.b	"%s",0
 even

xarray	dc.l	0

xfdvirhe			* N‰ytet‰‰n XFD:n oma virheilmoitus.
	movem.l	d0-a6,-(sp)
	move	lod_xfderror(a5),d0
	lore	XFD,xfdGetErrorText
	lea	.x(pc),a1
	lea	xarray(pc),a4
	move.l	d0,(a4)
	bra.w	request2

.x	dc.b	"XFD error:",10
	dc.b	"%s",0
 even


** Moduuli oli tuntematon!
* Poistetaanko listasta??

tuntematonvirhe
	movem.l	d0-a6,-(sp)
	lea	unknown_t(pc),a1
	tst.b ahi_muutpois(a5)
	beq.b	.noAhiSkip
	lea	unknownDueToAhi_t(pc),a1
.noAhiSkip
	cmp.b	#GROUPMODE_DISABLE,groupmode(a5)
	bne.b	.groupSkip
	lea	unknownDueToGroupDisabled_t(pc),a1
.groupSkip

	lea	.g(pc),a2
	cmp.b	#LISTMODE_BROWSER,listMode(a5)
	bne.b	.noBr	
	lea	.onlyOk(pc),a2
	bsr.w	rawrequest
	bra.b	.w
.noBr
	bsr.w	rawrequest
	tst.l	d0
	beq.b	.w	
	bsr.w	delete
.w	movem.l	(sp)+,d0-a6
	rts

.g	dc.b	"_Delete from list|_OK",0
.onlyOk = *-4
 even

*******************************************************************************
* Ladataan tiedosto, jos pakattu - FImp, XPK, PP, LhA, Zip, LZX - puretaan
****
* a0 <= nimi
* d0 <= muistin tyyppi
* a1 <= mihin pistet‰‰n alkuosoite
* a2 <= mihin pistet‰‰n pituus
* d0 => 0 tai virhe

* Virheet (d0:ssa):
lod_openerr	=	-1
lod_readerr	=	-2
lod_nomemory	=	-3
lod_crypted	=	-4	; ( vain PP )
lod_unknownpp	=	-6	; ( vain PP )
lod_grouperror	=	-7
lod_noxpk	=	-8
lod_nopp	=	-9
lod_xpkerr	=	-10
lod_tuntematon	=	-11
lod_nomemoryf	=	-12
lod_execerr	=	-13
lod_lockerr	=	-14
lod_notafile	=	-15
lod_openerr2	=	-16
lod_xfderr	=	-17
lod_extract	=	-18
lod_loadsegfail = -19

* Skip XPK identification
loadfileStraight
	push	d7
	move.b	xpkid(a5),d7
	* DISABLE:
	st	xpkid(a5)
	push	d7
	bsr.b	loadfile
	pop	d7
	move.b	d7,xpkid(a5)
	pop	d7
	rts

loadfile
	movem.l	d1-a6,-(sp)

	jsr	setMainWindowWaitPointer

	lea	lod_a(a5),a3
	lea	lod_b(a5),a4
.clr	clr	(a3)+
	cmp.l	a4,a3
	bne.b	.clr

	move.l	d0,lod_memtype(a5)	
	move.b	d1,lod_kommentti(a5)
	move.l	a0,lod_filename(a5)
	move.l	a1,lod_start(a5)
	move.l	a2,lod_len(a5)
	clr.l	(a1)
	clr.l	(a2)

	move.l	lod_filename(a5),a0	* tutkitaan nimen liite
	move.l	a0,a2
.fe	tst.b	(a0)+
	bne.b	.fe
	subq	#1,a0

	* Clear flag that indicates that the module that was loaded
	* was in fact an executable. If this is not done,
	* XPK packed modules are thought to be DeliCustoms and mayhem ensues.
	;clr.b	executablemoduleinit(a5)
	clr.b	lod_exefile(a5)

** Archiven purku

	move.b	-(a0),d0
	ror.l	#8,d0
	move.b	-(a0),d0
	ror.l	#8,d0
	move.b	-(a0),d0
	ror.l	#8,d0
	move.b	-(a0),d0

	move.l	d0,d1
	* upper case conversion for easy matching
	and.l	#$dfdfdfff,d1
	cmp.l	#'LHA.',d1
	beq.b	.lha
	cmp.l	#'LZH.',d1
	beq.b	.lha
	cmp.l	#'LZX.',d1
	beq.b	.lzx
	cmp.l	#'ZIP.',d1
	beq.b	.zip
	* gzip test
	* ".gzX"
	and.l	#$ffdfdf00,d0
	cmp.l	#'.GZ'<<8,d0
	bne.w	.nope
	lea	gzipDecompressCommand,a0
	moveq	#1,d6	* "Unzipping" message
	bra.b	.unp

.lha	lea	arclha(a5),a0
	moveq	#0,d6
	bra.b	.unp
.zip	lea	arczip(a5),a0
	moveq	#1,d6
	bra.b	.unp
.lzx	lea	arclzx(a5),a0
	moveq	#2,d6

.unp	

	pushm	all
	* takes type in d6
	bsr.w	inforivit_extracting
	bsr.w	remarctemp	* varmuuden vuoksi poistetan tempdirri jos on
	popm	all

	* lod_buf will contain the command line to Execute
	* unarchive into current dir, which will be a temp dir created here

	move.l	lod_filename(a5),d0
	lea	lod_buf(a5),a3
	jsr	desmsg3

	st	lod_archive(a5)		* lippu!!

* SP = RAM:∞HiP∞

	lea	-160(sp),sp
	move.l	sp,a1
	lea	arcdir(a5),a0
	jsr	copyb
	subq	#1,a1
	cmp.b	#':',-1(a1)
	beq.b	.na
	move.b	#'/',(a1)+
.na	
	lea	tdir(pc),a0
	jsr	copyb

** vanha kick: kopioidaan parametrin per‰‰n RAM:∞HiP∞/
	tst.b	uusikick(a5)
	bne.b	.nu
	lea	lod_buf(a5),a1
.barf	tst.b	(a1)+
	bne.b	.barf
	subq	#1,a1
	move.b	#' ',(a1)+
	lea	(sp),a0
	jsr	copyb
	subq	#1,a1
	cmp.b	#':',-1(a1)
	beq.b	.na0
	move.b	#'/',(a1)+
.na0	clr.b	(a1)

.nu

	move.l	sp,a4

	moveq	#0,d6
	moveq	#0,d5

*** Luodaan dirri

	move.l	a4,d1
	lore	Dos,CreateDir
	tst.l	d0
	beq.b	.onjo
	move.l	d0,d1
	lob	UnLock


.onjo
*** Lockki dirriin
	move.l	a4,d1
	moveq	#ACCESS_READ,d2
	lob	Lock

	move.l	d0,d7
	beq.w	.x

*** CD dirriin

	move.l	d0,d1
	lob	CurrentDir
	move.l	d0,d6

*** Ajetaan kamat

	pushpea	lod_buf(a5),d1
	moveq	#0,d2			* input
	move.l	nilfile(a5),d3		* output
	lob	Execute

	* back to old current dir
	move.l	d7,d1
	lob	CurrentDir


*** Skannataan dirrin filÈt

	move.l	d7,d1
	pushpea	fileinfoblock(a5),d2
	lob	Examine
	tst.l	d0
	beq.w	 .x

 if DEBUG
	pushpea	fib_FileName+fileinfoblock(a5),d0
	DPRINT  "Scanning: %s"
 endif
	
.loop	
	move.l	d7,d1
	lob	ExNext
	tst.l	d0
	beq.w	.x

	pushm	all

 if DEBUG
	pushpea	fib_FileName+fileinfoblock(a5),d0
	DPRINT  "->%s"
 endif
	pushpea	fib_FileName+fileinfoblock(a5),d1
	move.l	#MODE_OLDFILE,d2
	lob	Open
	move.l	d0,d4
	beq.w	.bah

	move.l	d4,d1

	lea	probebuffer(a5),a0
	move.l	a0,d2

	move.l	#PROBE_BUFFER_LEN/4-1,d0	* tyhj‰ks
.clear	clr.l	(a0)+
	dbf	d0,.clear

	move.l	#PROBE_BUFFER_LEN,d3
	lob	Read
	move.l	d0,d7
	cmp.l	#100,d0
	bls.w	.nah

*** Tsekataan tyyppi‰

	lea	probebuffer(a5),a0

** Tutkaillaan moduulia tarkistusrutiineilla

	pushm	d4/a4
	move.l	a0,a4
	bsr.w	id_protracker
	beq.w	.on

	bsr.w	id_ps3m		
	tst.l	d0
	beq.w	.on

	bsr.w	id_tfmxunion
	beq.w	.on

	bsr.w	id_TFMX_PRO
	tst	d0
	beq.b	.on

	bsr.w	id_TFMX7V
	tst	d0
	beq.b	.on

	bsr.w	id_tfmx
	beq.b	.on

	DPRINT	"Internal"
	lea	internalFormats(pc),a3 
	bsr.w	identifyFormatsOnly 
	beq.b .on
	DPRINT	"Group"
	lea	groupFormats(pc),a3 
	bsr.w	identifyFormatsOnly 
	beq.b .on
	DPRINT	"Eagle"
	lea	eagleFormats(pc),a3 
	bsr.w	identifyFormatsOnly 
	beq.b .on

 ifne FEATURE_P61A
	move.l	fileinfoblock+8(a5),d0	* Tied.nimen 4 ekaa kirjainta
	bsr.w	id_player2
	beq.b	.on
 endif

	cmp.l   #"XPKF",(a4)             * pakatut kelpaavat!
	beq.b   .on
	cmp.l   #"IMP!",(a4)
	beq.b   .on
	cmp.l   #"PP20",(a4)
	beq.b	.on

;	bsr.w	id_oldst		* oldst tunnistus viimeiseksi
;	beq.b	.on

	moveq	#-1,d0
	bra.b	.ei

.on	moveq	#0,d0
.ei	popm	d4/a4
	
	tst	d0
	bne.b	.nah

.joo

* juhuu! kopioidaan tied. nimi talteen

	lea	lod_buf(a5),a1
	move.l	a1,lod_filename(a5)
	move.l	a4,a0
	jsr	bcopy
	subq	#1,a1
	move.b	#'/',(a1)+
	lea	fib_FileName+fileinfoblock(a5),a0
	push	a0
	jsr	bcopy
	pop	a0		* tfmx?

	move.l	(a0),d0
	and.l	#$dfdfdfdf,d0
	cmp.l	#"MDAT",d0
	bne.b	.now
	st	lod_tfmx(a5)	* lippu: archive = tfmx
.now
	
	move.l	d4,d1
	lob	Close
	popm	all
	st	d5
	bra.b	.x
.nah

	move.l	d4,d1
	lob	Close
.bah
	popm	all
	bra.w	.loop

.x
	move.l	d6,d1
	lob	CurrentDir

	move.l	d7,d1
	beq.b	.xx
	lob	UnLock
.xx

	lea	160(sp),sp

	tst	d5
	bne.b	.nope

* oliko sopivaa file‰?
	move	#lod_extract,lod_error(a5)
	bra.w	.exit



.nope
	* Ordinary file load below, archive extraction above.

	move.l	_DosBase(a5),a6
	move.l	lod_filename(a5),d1
	moveq	#ACCESS_READ,d2
	lob	Lock			
	move.l	d0,d3
	beq.w	.open_error
	move.l	d0,d1
	lea	fileinfoblock(a5),a3
	move.l	a3,d2
	lob	Examine
	tst.l	d0 
	bne.b 	.exOk
	move.l	d3,d1
	lob	UnLock
	bra.w	.open_error
.exOk
	move.l	d3,d1
	lob	UnLock

	;tst.l	fib_DirEntryType(a3)	* onko tiedosto vai hakemisto?
	;bpl.w	.nofile_err
	cmp.l	#ST_FILE,fib_DirEntryType(a3)
	beq.b	.isFile
	cmp.l	#ST_LINKFILE,fib_DirEntryType(a3)
	bne.w	.nofile_err
.isFile

	move.l	124(a3),lod_length(a5)	* tiedoston pituus
	beq.w	.open_error		* jos 0 -> errori

	tst.b	lod_kommentti(a5)
	bne.b	.noc
	lea	fileinfoblock+144(a5),a0	* kopioidaan kommentti talteen
	lea	filecomment(a5),a1
	moveq	#80-1,d0
.cece	move.b	(a0)+,(a1)+
	dbeq	d0,.cece
	clr.b	(a1)
.noc
	* Read some bytes of data into the probebuffer

	DPRINT	"Probing"

	move.l	#1005,d2
	move.l	lod_filename(a5),d1
	lob	Open
	move.l	d0,lod_filehandle(a5)
	beq.w	.open_error

	lea	probebuffer(a5),a0
	move.w	#PROBE_BUFFER_LEN/4-1,d0
.clrProbe
	clr.l	(a0)+
	dbf	d0,.clrProbe

	* Here the full buffer is not used for some reason.
	* Probably for optimization.
	
	move.l	lod_filehandle(a5),d1
	lea	probebuffer(a5),a0
	move.l	a0,d2
	move.l	#1084,d3
	lob	Read
	DPRINT	"Probe read: %ld"
;	cmp.l	#1084,d0
;	bne.w	.read_error

* Check if this is an archive file
*** onko lha, lzx, zip?

	cmp	#'PK',probebuffer(a5)
	bne.b	.nozip
	cmp.b	#$20,2+probebuffer(a5)
	bhs.b	.nozip
	cmp.b	#$20,3+probebuffer(a5)
	bhs.b	.nozip

	bsr.w	.closeit
	clr.l	lod_filehandle(a5)
	bra.w	.zip
.nozip

	cmp.l	#"LZX"<<8,probebuffer(a5)
	bne.b	.nolzx

	bsr.w	.closeit
	clr.l	lod_filehandle(a5)
	bra.w	.lzx
.nolzx

	cmp	#'-l',2+probebuffer(a5)
	bne.b	.nolha
	move.l	4+probebuffer(a5),d0
* d0 = "h5-v"
	and.l	#$ff00ff00,d0
	cmp.l	#$68002d00,d0
	bne.b	.nolha

	bsr.w	.closeit
	clr.l	lod_filehandle(a5)
	bra.w	.lha

.nolha

	bsr.w	.handleExecutableModuleLoading
	* Skip the rest if LoadSeg above went fine
	;tst.b	executablemoduleinit(a5)
	tst.b 	lod_exefile(a5)
	bne.w	.exit


** Is this a sample file, stop loading if so.
** Jos havaitaan file sampleks, ei ladata enemp‰‰
	lea	probebuffer(a5),a0
	clr.b	sampleinit(a5)
	bsr.w	.samplecheck
	bne.b	.nosa
	st	sampleinit(a5)
	bra.w	.exit

.nosa	clr.b	sampleformat(a5)

	* This checks whether the file should be loaded into FAST ram

	lea	probebuffer(a5),a0	* Kannattaako ladata fastiin??
	bsr.w	.checkm

	* XPK compressed file check

	cmp.l	#"XPKF",probebuffer(a5)
	bne.w	.wasnt_xpk

	bsr.w	get_xpk
	beq.w	.lib_error1

** file on xpk, katsotaan jos se on sample:
	lea	probebuffer+16(a5),a0
	clr.b	sampleinit(a5)
	bsr.w	.samplecheck
	bne.b	.nosa2
	st	sampleinit(a5)
	bra.w	.exit

.nosa2	clr.b	sampleformat(a5)


	st	lod_xpkfile(a5)	* lippu: xpk file

* Ladataan eka XPK-hunkki tiedostosta ja katsotaan voidaanko se
* ladata fastiin.

	tst.b	xpkid(a5)	* Oliko XPK id p‰‰ll‰?
	bne.w	.noid

	bsr.w	inforivit_xpkload2

	lea	.xpktags2(pc),a1
	move.l	lod_filename(a5),.in2-.xpktags2(a1)
	lea	.xfhpointerp(pc),a0
	lore	XPK,XpkOpen
 	tst.l	d0
	bne.w	.xpk_error

	move.l	.xfhpointerp(pc),a0	* Varataan ekalle hunkille muistia.
	move.l	xf_NLen(a0),d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	jsr	getmem
	move.l	d0,d4
	bne.b	.ok

	move.l	.xfhpointerp(pc),a0
	lob	XpkClose
	bra.w	.nomem_error
.ok


	move.l	.xfhpointerp(pc),a0
	move.l	xf_NLen(a0),d0
	move.l	d4,a1
	lob	XpkRead
	tst.l	d0
	bpl.b	.oka

	push	d0
	move.l	.xfhpointerp(pc),a0
	lob	XpkClose
	move.l	d4,a0
	jsr	freemem
	pop	d0
	bra.w	.xpk_error
.oka

	move.l	.xfhpointerp(pc),a0
	lob	XpkClose

	move.l	lod_length(a5),-(sp)
	move.l	12+probebuffer(a5),lod_length(a5)	* unXPKed length

	move.l	d4,a0
	bsr.w	.checkm
	move.l	(sp)+,lod_length(a5)

	move.l	d4,a0
	jsr	freemem
	bra.b	.oo

.xpktags2
	dc.l	XPK_InName
.in2	dc.l	0

	dc.l	XPK_GetError
	dc.l	xpkerror+var_b	* virheilmoitus
	dc.l	TAG_END

.xfhpointerp dc.l	0


.oo
.noid

	bsr.w	.infor
	bsr.w	inforivit_xpkload

	tst.b	win(a5)
	beq.b	.eilo
	moveq	#81+WINX-1,plx1
	;move	#245+WINX+2,plx2
	move	WINSIZX(a5),plx2
	sub	#18,plx2
	moveq	#21+WINY,ply1
	moveq	#27+WINY,ply2
	add	windowleft(a5),plx1
	add	windowleft(a5),plx2
	add	windowtop(a5),ply1
	add	windowtop(a5),ply2
	move.l	rastport(a5),a1
	jsr	laatikko2
.eilo

	lea	.xpktags(pc),a0
	lea	lod_address(a5),a1
	move.l	a1,.xpkaddr-.xpktags(a0)
	lea	lod_length(a5),a1
	move.l	a1,.xpklen1-.xpktags(a0)

	move.l	lod_filename(a5),.xpkfile-.xpktags(a0)
	move.l	lod_memtype(a5),.xpkmem-.xpktags(a0)
	move.l	_XPKBase(a5),a6
	lob	XpkUnpack
	tst.l	d0
	bne.w	.xpk_error
	bra.w	.exit

.xpktags
		dc.l	XPK_InName
.xpkfile	dc.l	0

		dc.l	XPK_GetOutBuf
.xpkaddr	dc.l	0

		dc.l	XPK_GetOutBufLen
.xpklen1	dc.l	0

		dc.l	XPK_OutMemType
.xpkmem		dc.l	2		* muistin tyyppi

		dc.l	XPK_PassThru
		dc.l	1

		dc.l	XPK_GetError
		dc.l	xpkerror+var_b	* virheilmoitus

		dc.l	XPK_ChunkHook
		dc.l	.hook
		dc.l	TAG_END



.hook	ds.b	MLN_SIZE
	dc.l	.hookroutine	* h_Entry
	dc.l	0		* h_SubEntry
	dc.l	0		* h_Data



** Printataan infoa ladattaessa xpk filett‰
.hookroutine
* a1 = progress report structure
	pushm	d1-d7/a0/a1/a5/a6
	lea	var_b,a5
	tst.b	win(a5)
	beq.b	.xxx

	moveq	#$7f,d4
	and.l	xp_Done(a1),d4
	cmp	#100,d4
	bls.b	.h0
	moveq	#100,d4
.h0

        move.l  rastport(a5),a0
        move.l  a0,a1

        move.b  rp_Mask(a0),d7
        move.b	#%11,rp_Mask(a0)

        moveq   #82+WINX,d0
        moveq   #22+WINY,d1
        add     windowleft(a5),d0
        add     windowtop(a5),d1

        move.l  d0,d2
        move.l  d1,d3
        ;mulu    #163,d4	
		move	WINSIZX(a5),d5
		sub	#101+2,d5
		mulu	d5,d4
        divu    #100,d4

        moveq   #5,d5
        move    #$f0,d6
        lore    GFX,ClipBlit

        move.l  rastport(a5),a0
        move.b  d7,rp_Mask(a0)

.xxx	popm	d1-d7/a0/a1/a5/a6
	moveq	#0,d0		* ei breakkia!	
	rts



.wasnt_xpk

	* Was not XPK compressed. Is it powerpacker compressed?

	cmp.l	#"PP20",probebuffer(a5)
	bne.b	.wasnt_pp

	bsr.w	infolines_loadToChipMemory
	bsr.w	inforivit_ppload

	bsr.w	get_pp
	beq.w	.lib_error2

	move.l	d0,a6
	move.l	lod_filename(a5),a0		* filename
	moveq	#4,d0		* col
	move.l	lod_memtype(a5),d1
	lea	lod_address(a5),a1
	lea	lod_length(a5),a2
	sub.l	a3,a3
	lob	ppLoadData
	tst.l	d0
	beq.w	.exit
	bra.w	.pp_error	
.wasnt_pp

	* FImp compressed file?

	cmp.l	#"IMP!",probebuffer(a5)
	bne.b	.wasnt_fimp

	bsr.w	infolines_loadToChipMemory
	bsr.w	inforivit_fimpload

	move.l	lod_length(a5),d4
	move.l	4+probebuffer(a5),lod_length(a5)

	bsr.w	.alloc
	move.l	d0,lod_address(a5)
	beq.w	.fimp_error

	bsr.w	.seekstart

	move.l	_DosBase(a5),a6
	move.l	lod_filehandle(a5),d1
	move.l	lod_address(a5),d2
	move.l	d4,d3
	lob	Read
	cmp.l	d4,d0
	bne.w	.fimp_error2

	bsr.w	inforivit_fimpdecr

	move.l	lod_address(a5),a0
	jsr	fimp_decr	
	bra.w	.exit

.wasnt_fimp

*	Next up, try loading with XFDMaster if it is enabled
********* Lataus XFDmaster.libill‰

	tst.b	xfd(a5)
	beq.w	.wasnt_xfd

	bsr.w	get_xfd
	beq.w	.wasnt_xfd

** Tavallinen lataus t‰ss‰ v‰liss‰

	bsr.w	.alloc
	move.l	d0,lod_address(a5)
	beq.w	.error

	bsr.w	.infor
	bsr.w	.seekstart

	move.l	lod_filehandle(a5),d1
	move.l	lod_address(a5),d2
	move.l	lod_length(a5),d3
	move.l	_DosBase(a5),a6
	lob	Read
	cmp.l	lod_length(a5),d0
	bne.w	.error2

	lore	XFD,xfdAllocBufferInfo	
	move.l	d0,a3	
	tst.l	d0
	beq.w	.exit		* Error: menee tavallisena filen‰

	move.l	lod_address(a5),xfdbi_SourceBuffer(a3)
	move.l	lod_length(a5),xfdbi_SourceBufLen(a3)
	move.l	a3,a0
	lob	xfdRecogBuffer
	tst.l	d0
	bne.b	.xok1		* Error: tavallisena filen‰

.xok0	move.l	a3,a1
	lob	xfdFreeBufferInfo
	bra.w	.exit
.xok1
	move.l	xfdbi_PackerName(a3),d0
	bsr.w	inforivit_xfd

	move	xfdbi_PackerFlags(a3),d0
	and	#XFDPFF_PASSWORD!XFDPFF_RELOC!XFDPFF_ADDR,d0
	beq.b	.xok2		* Pakkerityyppi v‰‰r‰.. Ei kelpaa!
	move	#lod_tuntematon,lod_error(a5)
	bra.b	.xok0
.xok2

	moveq	#MEMF_CHIP,d0
	move.l	d0,xfdbi_TargetBufMemType(a3)
	move.l	a3,a0
	lob	xfdDecrunchBuffer
	tst.l	d0
	bne.b	.xok3
	move	xfdbi_Error(a3),lod_xfderror(a5) * error numba talteen
	move	#lod_xfderr,lod_error(a5)
	bsr.w	.free			* Vapautetaan pakattu file
	bra.b	.xok0
.xok3
	bsr.w	.free			* Vapautetaan pakattu file

	move.l	xfdbi_TargetBuffer(a3),lod_address(a5)	* Puretun tiedot
	move.l	xfdbi_TargetBufLen(a3),lod_length(a5)

	move.l	a3,a1
	lore	XFD,xfdFreeBufferInfo
** OK!
	bra.w	.exit


.wasnt_xfd

* Finally here we just do an ordinary read.
****** Ihan Tavallinen Lataus

 if DEBUG
	move.l	lod_length(a5),d0
	DPRINT	"Normal load %ld"
 endif
 	
	pushm d0/a0
	lea	probebuffer(a5),a0
	bsr.w	id_it
	popm d0/a0
	bne.b	.wasNotIt
	DPRINT	"IT hack 1!"
	move.l	lod_length(a5),d0
	addq.l	#2,d0
	move.l	lod_memtype(a5),d1
	lore	Exec,AllocMem
	bra.b	.itAlloc
.wasNotIt

	bsr.w	.alloc
.itAlloc
	move.l	d0,lod_address(a5)
	beq.w	.error

	bsr.w	.infor

;	bsr.w	.seekstart

	* Make use of the already read data in probebuffer
	move.l	lod_filehandle(a5),d1		
	moveq	#0,d2
	moveq	#OFFSET_CURRENT,d3
	lore	Dos,Seek
	DPRINT	"File position %ld"
	cmp.l	#-1,d0
	beq.w	.error2

	move.l	lod_address(a5),a0

	move.l	d0,d1
	beq.b	.skipInitial

	lea	probebuffer(a5),a1
	subq	#1,d0
.copyInitial
	move.b	(a1)+,(a0)+
	dbf	d0,.copyInitial
.skipInitial

 ifeq floadpr
	move.l	lod_filehandle(a5),d1
	move.l	lod_address(a5),d2
	move.l	lod_length(a5),d3
	move.l	_DosBase(a5),a6
	lob	Read
	cmp.l	lod_length(a5),d0
	bne.w	.error2
 else

*** laatukko file load progress indicator blabh
	pushm	d1/a0
	tst.b	win(a5)
	beq.b	.eilox
	moveq	#15+WINX,plx1
	;move	#245+WINX,plx2
	move	WINSIZX(a5),plx2
	sub	#18,plx2
	moveq	#21+WINY,ply1
	moveq	#27+WINY,ply2
	add	windowleft(a5),plx1
	add	windowleft(a5),plx2
	add	windowtop(a5),ply1
	add	windowtop(a5),ply2
	move.l	rastport(a5),a1
	jsr	laatikko3
.eilox	popm	d1/a0

	move.l	lod_length(a5),d4
	* subtract already read amount
	sub.l	d1,d4
	* where to load data, considering the already read amount
	move.l	a0,d5
	;move.l	lod_address(a5),d5


.loadloop
 ;if DEBUG
 ;	move.l	d4,d0
 ;	DPRINT	"Bytes to read %ld"
 ;endif
	* See if we got all of it already?
	tst.l	d4
	beq.w	.don
	bmi.w	.don

	move.l	lod_filehandle(a5),d1
	move.l	d5,d2
	move.l	#$2000,d3
	lore	Dos,Read

	cmp.l	#-1,d0
	bne.b	.noErr
 if DEBUG
	lob	IoErr
	DPRINT	"IoErr=%ld"
 endif
	bra.w	.error2
.noErr

	* Subtract total bytes to be read
	sub.l	d0,d4
	bmi.w	.error2
	beq.b	.don

	* Advance target addres
	add.l	d0,d5
	bsr.b	.lood
	bra.b	.loadloop

* Draw progress bar
.lood
	tst.b	win(a5)
	beq.b	.wxx
	pushm	d4/d5

	* File length is in d5
	move.l	lod_length(a5),d5
	move.l	d5,d3
	lsr.l	#8,d3
	* Bytes left to read is in d4
	sub.l	d4,d5
	* Bytes read is in d5
	lsr.l	#8,d5

	* Calculate 
	;mulu	#229,d5
	move	WINSIZX(a5),d7
	sub	#35,d7
	mulu	d7,d5
	divu	d3,d5
	move	d5,d4

        move.l  rastport(a5),a0
        move.l  a0,a1

        move.b  rp_Mask(a0),d7
        move.b	#%11,rp_Mask(a0)

        moveq   #16+WINX,d0
        moveq   #22+WINY,d1
        add     windowleft(a5),d0
        add     windowtop(a5),d1

        move.l  d0,d2
        move.l  d1,d3

        moveq   #5,d5
        move    #$f0,d6
        lore    GFX,ClipBlit

        move.l  rastport(a5),a0
        move.b  d7,rp_Mask(a0)

	popm	d4/d5
.wxx
	rts
.don
	DPRINT	"Read done"
 endc

.exit	

	bsr.b	.closeit

	tst.b	lod_archive(a5)		* dellataan archivetempfile
	beq.b	.eiarc
	tst.b	lod_tfmx(a5)		* jos oli tfmx, ei dellata
	bne.b	.eiarc
	bsr.w	remarctemp
.eiarc

	tst	lod_error(a5)
	beq.b	.okk

	bsr.w	.free

;	tst.l	lod_address(a5)
;	beq.b	.noko
;	bsr	freemodule
	bra.b	.noko
.okk
	* Store results
	move.l	lod_start(a5),a0
	move.l	lod_address(a5),(a0)
	move.l	lod_len(a5),a0
	move.l	lod_length(a5),(a0)
.noko
	jsr	clearMainWindowWaitPointer

	move	lod_error(a5),d0
	ext.l	d0
	movem.l	(sp)+,d1-a6
	tst.l	d0
	rts



.seekstart
	move.l	lod_filehandle(a5),d1		* tiedoston alkuun
	moveq	#0,d2
	moveq	#-1,d3
	move.l	_DosBase(a5),a6
	lob	Seek
 if DEBUG
	lob	IoErr
	DPRINT	"Seek IoErr=%ld"
 endif	
	rts

.closeit
	move.l	lod_filehandle(a5),d1
	beq.b	.em
	move.l	_DosBase(a5),a6
	lob	Close
.em	rts



.checkm
        bsr.w   tutki_moduuli2
	cmp.b	#2,d0
	beq.w	.ptfoo
        cmp.b   #-1,d0
        beq.b   .nofast

.publl  move.l   #MEMF_PUBLIC!MEMF_CLEAR,d0
	DPRINT	"Loading to PUBLIC memory"

.osd    move.l  d0,lod_memtype(a5)
.nofast rts

.nofas	move.l	#MEMF_CHIP!MEMF_CLEAR,d0
	bra.b	.osd



***** tutkaillaan onko sample

* 
* In:
*   a0 = probebuffer
* Out:
*   Z-flag set if recognized
.samplecheck
** IFF
	move.b	#1,sampleformat(a5)
	cmp.l	#"FORM",(a0)
	bne.b	.nosa0
	cmp.l	#"8SVX",8(a0)
	beq.w	.sampl
** AIFF
	move.b	#2,sampleformat(a5)
	cmp.l	#"AIFF",8(a0)
	beq.w	.sampl

.nosa0
** RIFF WAVE
	move.b	#3,sampleformat(a5)
	cmp.l	#"RIFF",(a0)
	bne.b	.nosaa
	cmp.l	#"WAVE",8(a0)
	beq.w	.sampl
.nosaa
** MPEG
	move.b	#4,sampleformat(a5)

	* Check file suffix
	move.l	modulefilename(a5),a1
.zu	tst.b	(a1)+
	bne.b	.zu
	subq.l	#1,a1
	move.b	-(a1),d0
	ror.l	#8,d0
	move.b	-(a1),d0
	ror.l	#8,d0
	move.b	-(a1),d0
	ror.l	#8,d0
	move.b	-(a1),d0
	ror.l	#8,d0
	and.l	#$ffdfdfff,d0
	cmp.l	#".MP1",d0
	beq.b	.sampl
	cmp.l	#".MP2",d0
	beq.b	.sampl
	cmp.l	#".MP3",d0
	beq.b	.sampl

	* Check file prefix
	move.l	modulefilename(a5),a1
	move.l	a1,a2
.zu2	tst.b	(a1)+
	bne.b	.zu2
	subq.l	#1,a1
.zu3	cmp.l	a1,a2
	beq.b	.zu4
	cmp.b	#":",-1(a1)
	beq.b	.zu4
	cmp.b	#"/",-1(a1)
	beq.b	.zu4
	subq	#1,a1
	bra.b	.zu3
.zu4
	move.l	a1,d0

	move.b	(a1)+,d0
	rol.l	#8,d0
	move.b	(a1)+,d0
	rol.l	#8,d0
	move.b	(a1)+,d0
	rol.l	#8,d0
	move.b	(a1)+,d0
	and.l	#$dfdfffff,d0
	cmp.l	#"MP1.",d0
	beq.b	.sampl
	cmp.l	#"MP2.",d0
	beq.b	.sampl
	cmp.l	#"MP3.",d0
	beq.b	.sampl

	* Finally check probe buffer contents 
	bsr.w	id_mp3

.sampl	rts
	

** Ladataan PT file fastiin jos ei mahdu chipppppiin
.ptfoo
	tst.b	ahi_use(a5)		* AHI? -> public
	bne.w	.publl
	cmp.b	#2,ptmix(a5)		* PS3M? -> public
	beq.w	.publl

	pushm	all
	move.l	#MEMF_LARGEST!MEMF_CHIP,d1
	lore	Exec,AvailMem
	cmp.l	lod_length(a5),d0
	popm	all
	blo.w	.publl
	rts

.infor	
	move.l	lod_memtype(a5),d0
	btst	#MEMB_PUBLIC,d0
	bne.w	infolines_loadToPublicMemory
	bra.w	infolines_loadToChipMemory

.nofile_err
	move	#lod_notafile,lod_error(a5)
	bra.w	.exit

.open_error
 if DEBUG
	lore	Dos,IoErr
	DPRINT	"Open IoErr=%ld"
 endif

	move	#lod_openerr,lod_error(a5)
	bra.w	.exit

.error
.nomem_error
.fimp_error
	move	#lod_nomemory,lod_error(a5)
	bra.w	.exit

.fimp_error2
.error2	
	bsr.b	.free
.read_error
	move	#lod_readerr,lod_error(a5)
	bra.w	.exit
.lib_error1
	move	#lod_noxpk,lod_error(a5)
	bra.w	.exit
.lib_error2
	move	#lod_nopp,lod_error(a5)
	bra.w	.exit
.xpk_error
	move	#lod_xpkerr,lod_error(a5)
	move	d0,lod_xpkerror(a5)
;	bra.w	.exit
	bra.w	.noko	

.pp_error
	move	d0,lod_error(a5)	* PP:n virhekoodi (yhteensopiva)
	bra.w	.exit


.alloc	
	move.l	lod_length(a5),d0
	move.l	lod_memtype(a5),d1
	move.l	(a5),a6
	lob	AllocMem
	tst.l	d0
	rts

.free	move.l	lod_address(a5),d0
	beq.b	.eee
	clr.l	lod_address(a5)
	move.l	d0,a1
	move.l	lod_length(a5),d0
 if DEBUG
 	move.l	a1,d1
	DPRINT	"Free %ld bytes at 0x%lx"
 endif
	move.l	(a5),a6
	lob	FreeMem
.eee	rts



.handleExecutableModuleLoading
	* Probebuffer now has 1084 of data we can check
	* for Delitracker CUSTOM format, as it has to be loaded
	* with LoadSeg(), being an exe file.
	* Clear the flag that indicates exe module load status.
	;clr.b	executablemoduleinit(a5)
	clr.b	lod_exefile(a5)
	* There are no AHI supported exe type modules
	tst.b	ahi_muutpois(a5)
	bne.w	.ahiSkip
	pushm 	d1-a6
	lea	probebuffer(a5),a4
	move.l	#1084,d7

	* Test for known exe formats

	bsr.w	id_futureplayer
	bne.b	.notFuturePlayer
	moveq	#pt_futureplayer,d7
	bra.b	.exeOk

.notFuturePlayer
	bsr.w	id_delicustom
	bne.b	.notDeliCustom
	moveq	#pt_delicustom,d7
	bra.b	.exeOk 

.notDeliCustom 
	bsr.w	id_davelowe
	bne.b	.notDl
	move	#pt_davelowe,d7
	bra.b	.exeOk
.notDl
	bra.b	.notKnown
.exeOk
	move.l	#MEMF_PUBLIC,lod_memtype(a5)
	bsr.w	.infor
	move.l	lod_filename(a5),d1
	lore	Dos,LoadSeg
	tst.l	d0
	beq.b	.loadSegErr
	* set type of loadsegged module
	;move.b	d7,executablemoduleinit(a5)
	move.b	d7,lod_exefile(a5)
	move.l	d0,lod_address(a5)
	* length is not readily available for these, so clear it
	clr.l	lod_length(a5)
 if DEBUG
	move.l	d7,d0
	DPRINT	"Module LoadSeg ok for type %ld"
 endif
.loadExit
.notKnown
	popm 	d1-a6
.ahiSkip
	rts
.loadSegErr
	move	#lod_loadsegfail,lod_error(a5)
	bra.b 	.loadExit

* Removes the temp directory used for unarchiving lha etc
remarctemp
	pushm	all
	lea	-200(sp),sp
	move.l	sp,a1
	lea	.del1(pc),a0
	jsr	copyb
	subq	#1,a1

	lea	arcdir(a5),a0
	jsr	copyb
	subq	#1,a1
	cmp.b	#':',-1(a1)
	beq.b	.nar
	move.b	#'/',(a1)+
.nar	
	lea	tdir(pc),a0
	jsr	copyb
	subq	#1,a1
	lea	.del2(pc),a0
	jsr	copyb

	move.l	sp,d1
	moveq	#0,d2
	move.l	nilfile(a5),d3
	lore	Dos,Execute
	lea	200(sp),sp
	popm	all
	rts

.del1	dc.b	"c:delete ",0
.del2	dc.b	" ALL QUIET",0 ;FORCE

tdir	dc.b	"∞HiP∞",0
 even


get_xpk	move.l	_XPKBase(a5),d0
	beq.b	.noep
	rts
.noep	lea 	xpkname,a1		
	move.l	a6,-(sp)
	move.l	(a5),a6
	lob	OldOpenLibrary
	move.l	(sp)+,a6
	move.l	d0,_XPKBase(a5)
	rts

get_pp	move.l	_PPBase(a5),d0
	beq.b	.noep
	rts
.noep	lea 	ppname,a1		
	move.l	a6,-(sp)
	move.l	(a5),a6
	lob	OldOpenLibrary
	move.l	(sp)+,a6
	move.l	d0,_PPBase(a5)
	rts

get_sid	move.l	_SIDBase(a5),d0
	beq.b	.noep
	rts
.noep	lea 	sidname,a1		
	move.l	a6,-(sp)
	move.l	(a5),a6
	lob	OldOpenLibrary
	move.l	(sp)+,a6
	move.l	d0,_SIDBase(a5)
	beq.b	.q
	bsr.w	init_sidpatch
	moveq	#1,d0
.q	rts

get_xfd
	move.l	_XFDBase(a5),d0
	beq.b	.x
	rts
.x	lea	xfdname,a1
	push	a6
	lore	Exec,OldOpenLibrary
	pop	a6
	move.l	d0,_XFDBase(a5)
	rts

get_med1
	move.l	_MedPlayerBase1(a5),d0
	beq.b	.q
	rts
.q	lea	medplayername1,a1
;	moveq	#6,d0
	push	a6
;	lore	Exec,OpenLibrary
	lore	Exec,OldOpenLibrary
	pop	a6
	move.l	d0,_MedPlayerBase1(a5)
	rts	

get_med2
	move.l	_MedPlayerBase2(a5),d0
	beq.b	.q
	rts
.q	lea	medplayername2,a1
;	moveq	#6,d0
	push	a6
;	lore	Exec,OpenLibrary
	lore	Exec,OldOpenLibrary
	pop	a6
	move.l	d0,_MedPlayerBase2(a5)
	rts	

get_med3
	move.l	_MedPlayerBase3(a5),d0
	beq.b	.q
	rts
.q	lea	medplayername3,a1
;	moveq	#7,d0
	push	a6
;	lore	Exec,OpenLibrary
	lore	Exec,OldOpenLibrary
	pop	a6
	move.l	d0,_MedPlayerBase3(a5)
	rts	


get_mline
	move.l	_MlineBase(a5),d0
	beq.b	.q
	rts
.q	lea	mlinename,a1
	push	a6
	lore	Exec,OldOpenLibrary
	pop	a6
	move.l	d0,_MlineBase(a5)
	rts	



*******************************************************************************
* Analysoidaan tiedosto
*******************************************************************************


*******
* Search
*******
* in:
*   a1 = etsitt‰v‰
*   a4 = mist‰ etsit‰‰n
*   d0 = etsitt‰v‰n pituus
*   d7 = modin pituus
* out:
*   d0 =  0: found
*   d0 = -1: not found
*   a0 = end of last match

search
	move.l	#2048,d2
	cmp.l	d7,d2
	blo.b	.sea
	move.l	d7,d2		
.sea	
	lea	(a4,d2.l),a3	 * Etsit‰‰n kaksi kilotavua tai modin pituus

	move	d0,d2
	subq	#2,d2
	move.l	a4,a0
	move.b	(a1)+,d0
.moh	move.l	a1,a2
.findi	
	cmp.l	a3,a0
	bhs.b	.eieh
	cmp.b	(a0)+,d0
	bne.b	.findi

	move	d2,d1
.fid	cmpm.b	(a2)+,(a0)+
	dbne	d1,.fid
	beq.b	.yeah

.fof	cmp.l	a3,a0
	blo.b	.moh
.eieh	moveq	#-1,d0
	rts
.yeah	moveq	#0,d0
	rts


*******
* Analysoidaan moduuli
*******
* Tutkitaan, onko moduuli sellanen jonka vois ladata fastiin.
* a0 = moduuli, 1084 bytee

tutki_moduuli2
	DPRINT	"Check where to load"
	pushm	d1-a6
	move.l	a0,a4
	move.l	#1084,d7
	bsr.b	.do
	popm	d1-a6
	rts
.do
* ptmix -> 0: chip, 1: fast, 2: ps3m
	tst.b	ahi_use(a5)
	bne.b	.er

	tst.b	ptmix(a5)
	beq.b	.er

	cmp.b	#2,ptmix(a5)
	beq.b	.er

	bsr.w	.ptch		* fast
	beq.w	.rf
	bra.b	.nom

.er	bsr.w	.ptch		* 
	beq.w	.ff

.nom
;	bsr	id_ps3m
;	tst.l	d0
;	beq.w	.goPublic
	cmp.l	#'SCRM',44(a0)		* Screamtracker ]I[
	beq.w	.f
	cmp.l	#"OCTA",1080(a0)	* Fasttracker
	beq.w	.f

	cmp.l	#"Exte",(a0)		* Fasttracker ][ XM
	bne.b	.kala
	cmp.l	#"nded",4(a0)
	bne.b	.kala
	cmp.l	#" Mod",8(a0)
	bne.b	.kala
	cmp.l	#"ule:",12(a0)
	beq.w	.f

.kala	move.l	1080(a0),d0
	and.l	#$ffffff,d0		* fast
	cmp.l	#"CHN",d0
	beq.w	.f
	cmp	#"CH",1082(a0)		* fast
	beq.w	.f
	move.l	(a0),d0
	lsr.l	#8,d0
	cmp.l	#'MTM',d0		* multi
	beq.w	.f
	move.l	1080(a0),d0
	lsr.l	#8,d0
	cmp.l	#"TDZ",d0		* take
	beq.b	.f

	bsr.w	id_it			 * IT
	beq.b	.f


* tfmx song data?

* This check also matches "Hippel7", but apparently
* the probebuffer data at this point is not enough
* to id Hippel7 properly. Those will be moved into 
* chip ram at later tage

	cmp.l	#"TFMX",(a4)
	beq.b	.goPublic
	cmp.l	#"tfmx",(a4)
	beq.b	.goPublic

	bsr.w	id_oktalyzer8ch
	beq.b	.goPublic

	cmp.l	#'PSID',(a4)		* PSID-tiedosto
	beq.b	.goPublic

	bsr.w	id_thx_
	tst.l	d0
	beq.B	.goPublic
	bsr.w	id_pretracker_
	tst.l	d0
	beq.B	.goPublic
	bsr.w	id_mline
	tst.l	d0
	beq.b	.goPublic
	jsr	id_musicmaker8_
	tst.l	d0
	beq.b	.goPublic
	;bsr	id_digitalmugician2 
	;beq.b	.goPublic

** OctaMed SoundStudio mixattavat moduulit
	move.l	(a4),d0
	lsr.l	#8,d0
	cmp.l	#'MMD',d0
	bne.b	.nome
	btst	#0,20(a4)		* mmdflags, MMD_LOADTOFASTMEM
	bne.b	.goPublic
.nome

	bsr.w	id_digibooster_
	tst.l	d0
	beq.b	.goPublic
	bsr.w	id_digiboosterpro_
	tst.l	d0
	beq.b	.goPublic
	bsr		id_aon8
	tst.l	d0
	beq.b	.goPublic
	

	tst.b	ahi_use(a5)
	bne.b	.ahitun

.goChip
.nf	
	moveq	#-1,d0		* chip
	rts
.goPublic
.f	moveq	#0,d0		* public
	rts
.ff	moveq	#2,d0		* Protracker file
	rts
.rf	moveq	#1,d0		* fast
	rts
 

.ptch	cmp.l	#"M.K.",1080(a0)
	beq.b	.petc
	cmp.l	#"M!K!",1080(a0)
;	beq.b	.petc
;	cmp.l	#"FLT4",1080(a0)
.petc	rts

.ahitun
	pushm	all

	move.l	a0,a4
	bsr.w	id_hippelcoso
	beq.b	.ok
	moveq	#-1,d0

.ok	popm	all
	beq.b	.f
	bra.b	.nf



tutki_moduuli
	DPRINT	"Identify module"
;	bsr	inforivit_identifying
 ifne PILA

	lea	keyfile(a5),a4
	push	a4

	lea	.aag_id(pc),a1		 * onko AAG'97 keyfile?
	moveq	#4,d0
	moveq	#40,d7
	bsr.w	search
	pop	a0
	beq.b	.screw

	move.l	#$20202020,d0	
	or.l	(a0),d0
	cmp.l	#"wrec",d0		* wREC oF zYMOSIS?
	bne.b	.nwr
	move.l	(a5),a0
	btst	#AFB_68060,AttnFlags+1(a0)	* 68060?
	bne.b	.nwr
.screw	
	moveq	#-128,d1		* odotellaan
	ror.l	#7,d1
	lore	Dos,Delay
.nwr


 endc


	* Address may be null in case of sample file
	move.l	moduleaddress(a5),a4
	move.l	modulelength(a5),d7

	* NOTE! Some are very slow
	* - hippel
	* - activision pro

;	tst.b	keyfile+49(a5)	* datan v‰lilt‰ 38-50 pit‰‰ olla nollia
;	beq.b	.zz
;	move.l	(a5),a2
;	addq.l	#1,IVSOFTINT+IV_CODE(a2)
;.zz

	
	tst.b	ahi_use(a5)
	bne.b	.ohi
	cmp.b	#2,ptmix(a5)	* Normaali vai miksaava PT replayeri?
	beq.b	.ohi
	
	* Ensure no id funcs are ran on executables
	tst.b	executablemoduleinit(a5)
	bne.b	.ohi
	* See if there is data to check
	move.l	a4,d0
	beq.b	.ohi
	bsr.w	id_protracker
	beq.w	.protracker

.ohi
	* Test for formats that do not require an external
	* replay code.
	clr.b	external(a5)		* Lippu: ei tartte player grouppia 

	* First test for exe modules, skip the rest
	* of the checks since moduledata is a seglist
	cmp.b	#pt_delicustom,executablemoduleinit(a5)
	beq.w	.delicustom

	tst.b	sampleinit(a5)
	bne.b	.noop

	tst.b	ahi_muutpois(a5)	
	bne.b	.noop

	* Ensure no id funcs are ran on executables
	tst.b	executablemoduleinit(a5)
	bne.b	.noop

	* These do not require player group:

	DPRINT	"Internal"
	lea	internalFormats(pc),a3 
	bsr.w	identifyFormats
	beq.w 	.ex2

;	DPRINT	"Eagle"
;	lea	eagleFormats(pc),a3
;	bsr 	identifyFormats 
;	beq.w 	.ex2

	***********************************

	tst.l	externalplayers(a5)
	bne.b	.noop

	bsr.w	id_sid
	beq.w	.sid

	bsr.w	id_oldst
	beq.w	.oldst
.noop

	tst.l	externalplayers(a5)	* ladataan playerit
	bne.b	.rite
	cmp.b	#GROUPMODE_DISABLE,groupmode(a5)	* onko disabled
	beq.w	.nopl

	cmp.b	#GROUPMODE_LOAD_SINGLE,groupmode(a5)	* tarpeen vaatiessa 1 replayeri?
	bne.b	.rote
	st	external(a5)		* Lippu!
	bra.b	.rite
.rote
	bsr.w	loadplayergroup
	move.l	d0,externalplayers(a5)
	bne.b	.rite
	moveq	#lod_grouperror,d0
	rts


.rite

	tst.b	ahi_muutpois(a5)
	beq.b	.mpa
	tst.b	executablemoduleinit(a5)
	bne.b	.mpa

** AHIa tukevat replayerit
	bsr.w	id_hippelcoso
	beq.w	.hippelcoso

	bra.b	.mp
.mpa
	* First test for exe modules, skip the rest
	* of the checks since moduledata is a seglist
	cmp.b	#pt_futureplayer,executablemoduleinit(a5)
	beq.w	.futureplayer
	cmp.b	#pt_davelowe,executablemoduleinit(a5)
	beq.w	.davelowe

	tst.b	sampleinit(a5)		* sample??
	bne.w	.sample

	bsr.w	id_TFMX_PRO
	tst	d0
	beq.w	.tfmx

	bsr.w	id_TFMX7V
	tst	d0
	beq.w	.tfmx7

	bsr.w	id_tfmx
	beq.w	.tfmx

	bsr.w	id_tfmxunion
	beq.w	.tfmxunion

	DPRINT	"Group"
	lea	groupFormats(pc),a3 
	bsr.w	identifyFormats
	beq.b .ex2

	DPRINT	"Eagle"
	lea	eagleFormats(pc),a3
	bsr.w 	identifyFormats 
	beq.b 	.ex2

 ifne FEATURE_P61A
	move.l	fileinfoblock+8(a5),d0	* Tied.nimen 4 ekaa kirjainta
	bsr.w	id_player2
	beq.w	.player
 endif

.mp
	bsr.w	id_ps3m		
	tst.l	d0
	beq.w	.multi

	clr.b	external(a5)
.nope
.nopl

	tst.b	ahi_muutpois(a5)
	bne.b	.er

	bsr.w	id_sid
	beq.w	.sid

	bsr.w	id_oldst
	beq.b	.oldst


.er	
	DPRINT 	"Unknown format"
	moveq	#lod_tuntematon,d0
	rts	

.ex
	 bsr.w	tee_modnimi
.ex2	
	cmp	#pt_prot,playertype(a5)
	beq.b	.wew
	cmp	#pt_med,playertype(a5)
	beq.b	.wew
	bsr.w	whatgadgets
.wew
 if DEBUG
	moveq	#0,d0
	move	playertype(a5),d0
	moveq	#p_name,d1
	add.l	playerbase(a5),d1 
	DPRINT 	"Detected %ld %s"
 endif
	moveq	#0,d0
	rts

.oldst	st	oldst(a5)
	bsr.w	convert_oldst
	bra.b	.pro0

.protracker	
	clr.b	oldst(a5)
.pro0	pushpea	p_protracker(pc),playerbase(a5)
	move	#pt_prot,playertype(a5)
	moveq	#20-1,d0
	bsr.w	copyNameFromModule
	bra.b	.ex2

.multi	pushpea	p_multi(pc),playerbase(a5)
	move	#pt_multi,playertype(a5)
	bsr.w	moveModuleToPublicMem		* siirret‰‰n fastiin jos mahdollista

	move.l	moduleaddress(a5),a1	* tutkaillaan onko miss‰ muistissa
	lore	Exec,TypeOfMem
	and.l	#MEMF_CHIP,d0
	beq.w	.ex2

** Arf! Ladattiin chippiin!
** Onko vehkeess‰ fastia laisinkaan? Jos on, pistet‰‰n warn-tekstinp‰tk‰.

	moveq	#MEMF_FAST,d1
	lob	AvailMem
	tst.l	d0
	beq.w	.ex2

	bsr.w	inforivit_warn
	moveq	#65,d1
	lore	Dos,Delay
	bra.w	.ex2



.sid	pushpea	p_sid(pc),playerbase(a5)
	move	#pt_sid,playertype(a5)
	bsr.w	moveModuleToPublicMem		* siirret‰‰n fastiin jos mahdollista
	bra.w	.ex2

 ifne FEATURE_P61A
.player
	pushpea	p_player(pc),playerbase(a5)
	move	#pt_player,playertype(a5)
	bra.w	.ex
 endif

.hippelcoso
	move	d5,maxsongs(a5)
	pushpea	p_hippelcoso(pc),playerbase(a5)
	move	#pt_hippelcoso,playertype(a5)
	bra.w	.ex

.delicustom
	pushpea	p_delicustom(pc),playerbase(a5)
	move	#pt_delicustom,playertype(a5)
	bra.w	.ex

.futureplayer
	pushpea	p_futureplayer(pc),playerbase(a5)
	move	#pt_futureplayer,playertype(a5)
	bra.w	.ex

.davelowe
	pushpea	p_davelowe(pc),playerbase(a5)
	move	#pt_davelowe,playertype(a5)
	bra.w	.ex

**** Oliko  sample??
.sample
	pushpea	p_sample(pC),playerbase(a5)
	move	#pt_sample,playertype(a5)
	bra.w	.ex



** Yhdistetty TFMX formaatti

.tfmxunion
	moveq	#0,d7
	moveq	#$7f,d0
	and.b	8(a4),d0		*  tyyppi
	cmp.b	#3,d0
	beq.b	.t7
	moveq	#1,d7
.t7	bra.w	.ok



* TFMX onkin hankalampi homma..

.tfmx7	moveq	#0,d7
	bra.b	.t	

.tfmx	moveq	#1,d7
.t	
	moveq	#0,d0

	lea	fileinfoblock+8(a5),a0		* tied.nimi: mdat.*
	cmp.l	#'MDAT',(a0)
	beq.b	.uq
	cmp.l	#'mdat',(a0)
	bne.b	.qo
.uq	cmp.b	#'.',4(a0)
	beq.b	.ook


.qo	tst.b	(a0)+			* tied.nimi: *.mdat
	bne.b	.qo
	subq	#1,a0
	moveq	#0,d0
	move.b	-(a0),d0
	rol.l	#8,d0
	move.b	-(a0),d0
	rol.l	#8,d0
	move.b	-(a0),d0
	rol.l	#8,d0
	move.b	-(a0),d0
	and.l	#$dfdfdfdf,d0
	cmp.l	#'TADM',d0	* MDAT nurinp‰i
	bne.w	.er
	cmp.b	#'.',-(a0)
	bne.w	.er

.ook
	
	lea	-150(sp),sp		* tied nimi stackkiin
	move.l	sp,a1

	tst.b	lod_archive(a5)		* archivesta?
	beq.b	.pin
	lea	lod_buf(a5),a0
	bra.b	.cop

.pin	move.l	modulefilename(a5),a0
.cop	move.b	(a0)+,(a1)+
	bne.b	.cop

	lea	(sp),a0
.leep	lea	.tfmxid(pc),a1			* Etsit‰‰n nimest‰ 'mdat'
.luup	move.b	(a1)+,d1
	beq.b	.olioikea
	move.b	(a0)+,d0
	beq.w	.er
	bset	#5,d0			* pieneksi kirjaimeksi	
	cmp.b	d1,d0
	bne.b	.leep
	bra.b	.luup
.olioikea

	;subq.l	#1,a0			* muunnetaan 'smpl'
	move.b	#'l',-(a0)
	move.b	#'p',-(a0)
	move.b	#'m',-(a0)
	move.b	#'s',-(a0)

	lea	(sp),a1
* KPK 2016: removed debug requester when loading
* TFMX module
*	bsr	request		

	bsr.w	inforivit_tfmxload

	clr.b	lod_tfmx(a5)

	move.b	lod_archive(a5),d6


	lea	(sp),a0
	moveq	#MEMF_CHIP,d0
	lea	tfmxsamplesaddr(a5),a1
	lea	tfmxsampleslen(a5),a2
	moveq	#1,d1			* Ei oteta filen kommenttia talteen
	move.b	xpkid(a5),d4		* ei XPK ID:t‰ samplefileille
	st	xpkid(a5)
	bsr.w	loadfile
	move.b	d4,xpkid(a5)
	move.l	d0,-(sp)

;	tst.b	lod_archive(a5)
	tst.b	d6
	beq.b	.bar
	bsr.w	remarctemp
.bar

	bsr.w	inforivit_clear

	move.l	(sp)+,d0
	lea	150(sp),sp
	tst.l	d0
	beq.b	.ok
	rts
	
.ok	pushpea	p_tfmx(pc),playerbase(a5)
	move	#pt_tfmx,playertype(a5)
	tst	d7
	bne.w	.ex
	pushpea	p_tfmx7(pc),playerbase(a5)
	move	#pt_tfmx7,playertype(a5)
	bra.w	.ex

;.tfmxid	dc.b	"mdat.",0
.tfmxid		dc.b	"mdat",0
 even


* Utility function
* In:
*   Z-flag
* Out:
*   d0 = 0, if Z set, -1 if not
idtest	beq.b	.y
	moveq	#-1,d0
	rts
.y	moveq	#0,d0
	rts

* Run through format list and execute id function for each format
* in:
*   a3 = array of formats
* out:
*   d0 = 0 if some format accepted the module, ~0 otherwise
identifyFormatsOnly
	* Flag: only identify, do not grab data
	moveq	#1,d1
	bra.b 	doIdentifyFormats
identifyFormats
	* Flag: identify and grab module name and type
	moveq	#0,d1
	clr.b	modulename(a5)
doIdentifyFormats
.loop 
	tst	(a3)
	beq.b	.notFound
	move.l	a3,a0
	add	(a0),a0
 if DEBUG
	;pushpea	p_name(a0),d0
	;DPRINT	"- %s"
 endif
	pushm	all
	jsr	p_id(a0)
	tst.b	d0
	popm 	all
	beq.b 	.found
	addq	#2,a3
	bra.b	.loop
.found
	tst.b	d1 
	bne.b 	.nameOk

	move.l	a0,playerbase(a5)
	move	p_type(a0),playertype(a5)
	
	tst.b	modulename(a5)
	bne.b 	.nameOk 
	* Name was not provided by identifiers, make one
	bsr.b	tee_modnimi
.nameOk
	moveq	#0,d0
	rts
.notFound
	moveq	#-1,d0 
	rts

* Grab name from loaded module data
* In:
*   d0 = max length for name
* From start of the data:
copyNameFromModule
	move.l	moduleaddress(a5),a1
* From pointer in A1:
copyNameFromA1
	lea	modulename(a5),a0
.co	move.b	(a1)+,(a0)+
	dbeq	d0,.co
	clr.b	(a0)
	rts 
	
*******************************************************************
* Formaattien tunnistusrutiinit
*
* Parametrit: 
* D7 <= moduulin pituus (tai tutkittavan alueen pituus)
* A4 <= moduulin osoite (tutkittavan alueen osoite)
*
*
* Tulos:
* D0 => 0 jos moduuli on tunnettu
* D0 => -1 jos moduuli ei tunnetti
* 
* Jotkut palauttavat myˆs muuta informaatiota rekistereiss‰,
* kuten D5 => maxsong
*
 

keyfilename	dc.b	"L:HippoPlayer.Key",0
 even


*******
* Virittelee nimen tied.nimest‰
*******
tee_modnimi:
	moveq	#INFO_MODULE_NAME_LEN-1,d1
	lea		modulename(a5),a1
	tst.b	lod_archive(a5)		* Paketista purettuna
	bne.b	.arc				* otetaan pelkk‰ filename
	move.l	solename(a5),a0
	tst.b	uriDecodeNameBeforeShowing(a5)
	bne.b	.decode
	bra.b	.copy
.arc
	* This contains info from the last archive loaded file 
	lea	fib_FileName+fileinfoblock(a5),a0
.copy	
	move.b	(a0)+,(a1)+
	dbeq	d1,.copy
	clr.b	(a1)
	rts
.decode
	* This is the end part of a url, contains a path delimiter. 
	* Don't show the path to save space.
.3	cmp.b	#"/",(a0)+
	bne.b	.3
.2
	move.b	(a0)+,d0
	cmp.b	#"%",d0
	bne.b	.1
	* Converts the following 2 bytes from a0
	bsr		convertHexTextToNumber
.1	move.b	d0,(a1)+
	dbeq	d1,.2
	clr.b	(a1)
	rts

*******************************************************************************
* Lataa ulkoisen soittorutiinirykelm‰n
*******

loadplayergroup
	DPRINT	"Load player group"
	pushm	d1-a6


	bsr.w	inforivit_group

	moveq	#0,d7
	bsr.w		openPlayerGroupFile
	beq.w	.error
.ok
	move.l	d4,d1		* selvitet‰‰n filen pituus
	moveq	#0,d2	
	moveq	#1,d3
	lob	Seek
	move.l	d4,d1
	moveq	#0,d2	
	moveq	#1,d3
	lob	Seek
	move.l	d0,d5

	move.l	d4,d1		* alkuun
	moveq	#0,d2
	moveq	#-1,d3
	lob	Seek

	move.l	d5,d0
	moveq	#MEMF_PUBLIC,d1
	jsr	getmem
	move.l	d0,d7
	beq		.error

	move.l	d4,d1
	move.l	d7,d2
	move.l	d5,d3
	lob	Read
	cmp.l	d5,d0
	bne.b	.er

	move.l	d7,a0
	cmp.l	#"HiPx",(a0)
	beq.b	.x

.er
	move.l	d7,a0
	jsr	freemem
	bra.b	.error

.x	move.l	d4,d1
	beq.b	.xx
	lob	Close	

	move.l	d7,a0		* onko oikee versio??

 if DEBUG
	moveq	#0,d0
	move.b	4+3(a0),d0
	moveq	#xpl_versio,d1
	DPRINT	"Version: %ld, required: %ld"
 endif

	cmp.b	#xpl_versio,4+3(a0)
	bhs.b	.xx

	move.l	d7,a0
	jsr	freemem
	moveq	#0,d7

.xx	
	;bsr.w	inforivit_clear

 if DEBUG 
	move.l	d7,a0 
	move.l	-4(a0),d0 
	DPRINT	"Group size %ld"
 endif

	move.l	d7,d0
	popm	d1-a6
	rts

.error	moveq	#0,d7
	bra.b	.x

* out:
*  d4 = file handle, or NULL if error
openPlayerGroupFile
	move.l	_DosBase(a5),a6
	
	* First try home dir
	tst.l	homelock(a5)
	beq.b	.noHome

	lea	-100(sp),sp 
	move.l	sp,a0
	lea	progdir(pc),a1 
.c1 	move.b	(a1)+,(a0)+
	bne.b	.c1
	subq	#1,a0 
	lea	hipGroupFileName,a1
.c2	move.b	(a1)+,(a0)+
	bne.b	.c2
 if DEBUG 
	move.l	sp,d0
	DPRINT	"->%s"
 endif
	move.l	sp,d1
	move.l	#1005,d2
	lob		Open
	lea	100(sp),sp
	move.l	d0,d4
	bne.b	.ok 

.noHome
 if DEBUG 
	pushpea	groupname(a5),d0
	DPRINT	"->%s"
 endif

	pushpea	groupname(a5),d1
	move.l	#1005,d2
	lob	Open
	move.l	d0,d4
.ok 
	rts

progdir 
	dc.b	"PROGDIR:",0
	even



* lataa yksitt‰isen replayerin playergroupista
* d1 = muistin tyyppi

loadreplayer
	DPRINT	"Load single replayer"
	pushm	d1-d6/a0/a2-a6
	move.l	d6,a4				* muistin tyyppi!

	move.l	externalplayers(a5),a0		* grouppi poies
	jsr	freemem
	clr.l	externalplayers(a5)

	move	playertype(a5),d0		* onko jo sama ladattuna?
	cmp	xtype(a5),d0
	bne.b	.jou
	DPRINT	"Using already loaded"
	move.l	xplayer(a5),a1			* osoite a1:een
	move.l	xlen(a5),d7
	moveq	#1,d0
	popm	d1-d6/a0/a2-a6
	rts

.jou
	move	d0,xtype(a5)
	
	move.l	xplayer(a5),a0			* vapautetaan vanha 
	jsr	freemem
	clr.l	xplayer(a5)

	bsr.w	inforivit_group2

	bsr.w	openPlayerGroupFile
	beq.w	.error

	move.l	d4,d1
	pushpea	probebuffer+1024(a5),d2
	move.l	#1024,d3
	lob	Read
	cmp.l	#1024,d0
	bne.w	.error	


 if DEBUG
	moveq	#0,d0
	move.b	7+probebuffer+1024(a5),d0
	moveq	#xpl_versio,d1
	DPRINT	"Version: %ld, required: %ld"
 endif


	cmp.b	#xpl_versio,7+probebuffer+1024(a5)
	blo.w	.error

	lea	probebuffer+8+1024(a5),a0
	move	playertype(a5),d0
.find
	tst	(a0)
	beq.w 	.error
	cmp	(a0),d0 
	beq.b 	.found 
	lea	2+4+4(a0),a0 
	bra.b	.find
.found
	movem.l	2(a0),d2/d6	* player offset, length
	move.l	d6,xlen(a5)	* pituus talteen

 if DEBUG
 	push	d2
 	ext.l	d0
	move.l	d2,d1
	move.l	d6,d2
	DPRINT	"Single rep type=%ld offs=%ld len=%ld"
	pop	d2
 endif

	move.l	d4,d1		* hyp‰t‰‰n oikeaan kohtaan
	moveq	#-1,d3
	lob	Seek

	move.l	d6,d0
	move.l	a4,d1
	jsr	getmem
	move.l	d0,xplayer(a5)	* muistia playerille
	beq.b	.error

	move.l	d4,d1		* file
	move.l	xplayer(a5),d2	* buffer
	move.l	d6,d3		* length
	lob	Read
	cmp.l	d6,d0
	beq.b	.ox

	move.l	d7,a0
	jsr	freemem
	bra.b	.error

.ox	moveq	#1,d7

.x	move.l	d4,d1
	beq.b	.xx
	lob	Close	


.xx	
;	bsr.w	inforivit_clear

	move.l	d7,d0
	move.l	xplayer(a5),a1
	move.l	d6,d7
	tst.l	d0

	popm	d1-d6/a0/a2-a6
	rts

.error	moveq	#0,d7
	clr		xtype(a5)
	bra.b	.x



*******************************************************************************
* Enabloidaan k‰ytetyt gadgetit ja disabloidaan k‰ytt‰m‰ttˆm‰t
* Scope kanssa
*******


* Disables a button gadget
* in:
*   a0 = button gadget
disableButton
	move	#GFLG_DISABLED,d0
	and	gg_Flags(a0),d0
	bne.b	.alreadyDisabled
	or	#GFLG_DISABLED,gg_Flags(a0)
	jsr	refreshGadgetInA0
.alreadyDisabled
	rts

* Enables a button gadget
* in:
*   a0 = button gadget
enableButton
	move	#GFLG_DISABLED,d0
	and	gg_Flags(a0),d0
	beq.b	.alreadyEnabled
	and	 #~GFLG_DISABLED,gg_Flags(a0)
	* When re-enabling, need to draw the frame and clear
	* the disabled shadow
	move.l	a0,a3
	push	a0
	bsr.w	redrawButtonGadget	
	pop	a0
	moveq	#1,d0
.alreadyEnabled
	rts

* Enables a button gadget with RMB ear gfx
* in:
*   a0 = button gadget
enableButtonWithEar
	bsr.b	enableButton
	beq.b	.alreadyEnabled
	jsr	printkorva
.alreadyEnabled
	rts
	


whatgadgets2
	moveq	#0,d0
	bra.b	whag

whatgadgets
	moveq	#1,d0
whag	tst.b	win(a5)
	bne.b	.w
.ww	rts
.w

	tst.l	playerbase(a5)
	beq.b	.ww

	pushm	all

	move.l	playerbase(a5),a0
	move	p_liput(a0),d7

;	tst	d0
;	beq.b	.c

; In v2.50 and older scopes were shut down here if 
; active player didn't support it. 

* if usescope=1 then open scope if flag=1
* else
* if scope=open then close scope and set flag=1
* else
* clear flag

;	tst.b	scopeflag(a5)
;	beq.b	.c
;	btst	#pb_scope,d7
;	beq.b	.notopen
;	tst	quad_prosessi(a5)
;	bne.b	.c
;	bsr.w	start_quad2
;	bra.b	.c
;.notopen
;	tst	quad_prosessi(a5)
;	beq.b	.c
;	bsr.w	sulje_quad2

;.c

;	tst.l	keyfile+40(a5)	* datan v‰lilt‰ 38-50 pit‰‰ olla nollia
;	beq.b	.zz
;	move.l	tempexec(a5),a1
;	addq.l	#1,IVVERTB+IV_DATA(a1)
;.zz


	cmp	#pt_prot,playertype(a5)
	bne.b	.rep
	cmp.b	#$ff,ptsonglist+1(a5)	* jos vain yksi PT songi, sammutetaan 
	bne.b	.rep			* song-gadgetit!
	and	#~pf_song,d7
.rep
	lea	gadstate(pc),a4

	ror	#1,d7		* ei v‰litet‰ ekasta (joskus oli cont)

	moveq	#5-1,d6
.loop
	addq.l	#4,a4
	move.l	(a4)+,a0
	move.l	windowbase(a5),a1
	sub.l	a2,a2

	ror	#1,d7
	bpl.b	.off

	tst.b	-8(a4)		* oliko ennest‰‰n p‰‰ll‰?
	bne.b	.on

	move.l	a0,a3
	and	#~GFLG_DISABLED,gg_Flags(a3)
	bsr.w	redrawButtonGadget

	lea	kela2,a0
	cmp.l	a0,a3
	bne.b	.nokela
;	lea	kela2,a0		* >, forward
	jsr	printkorva
.nokela

	st	-8(a4)
	bra.b	.on

.off	tst.b	-8(a4)		* oliko pois p‰‰lt‰?
	beq.b	.on
	clr.b	-8(a4)
	move.l	a0,a3
	or	#GFLG_DISABLED,gg_Flags(a3)
	moveq	#1,d0
	lore	Intui,RefreshGList
	bsr.b	drawButtonFrameMainWindow

.on
	tst	2(a4)		* enemm‰n kuin yksi kerrallaan?
	bne.b	.l
	rol	#1,d7
	bra.b	.loop
.l
	dbf	d6,.loop

	popm	all
	rts

* Draws the button frame. 
* Check for gadgets that should be skipped so it is safe
* to call this with all gadgets.
* in:
*   a3 = gadget
drawButtonFrameMainWindow
	* File and volume sliders
	cmp.l	#slider1,a3
	beq.b	.x
	cmp.l	#slider4,a3
	beq.b	.x
	* Invisible resize gadget
	cmp.l	#gadgetResize,a3
	beq.b	.x

	pushm	all				* varjostus kuntoon taas
	move.l	rastport(a5),a1
	bsr.b	doDrawButtonFrame
	popm	all
.x	rts


* in:
*   a3 = gadget
drawButtonFramePrefsWindow
	pushm	all				* varjostus kuntoon taas
	move.l	rastport2(a5),a1
	bsr.b	doDrawButtonFrame
	popm	all
	rts

* in:
*   a1 = rastport
*   a3 = gadget
doDrawButtonFrame
	movem	4(a3),plx1/ply1/plx2/ply2
	add	plx1,plx2
	add	ply1,ply2
	subq	#1,ply2
	subq	#1,plx1
	move.l	pen_2(a5),d3
	move.l	pen_1(a5),d2
	jmp	laatikko0


* Clear button area, refresh gadget, draw button frame
* in:
*   a3 = gadget
redrawButtonGadget
	movem	4(a3),d0/d1	* putsataan gadgetin alue..
	move	d0,d2
	move	d1,d3
	movem	8(a3),d4/d5
	move.l	rastport(a5),a0
	move.l	a0,a1
	push	d6
	moveq	#$0a,d6
	lore	GFX,ClipBlit
	pop	d6

	move.l	a3,a0
	jsr	refreshGadgetInA0

	bsr.w	drawButtonFrameMainWindow
	rts



gadstate
	dc.l	$ff000001,button3	* stop/cont
	dc.l	$ff000001,button13	* prevsong
	dc.l	$ff000000,button12	* nextsong
	dc.l	$ff000001,kela2		* forwardd
	dc.l	$ff000001,kela1		* backward
	dc.l	$ff000001,slider1	* volume






********************************************************************************
*** SECTION ********************************************************************
*
* Favorite list handling
*
*****************************************************************************

toggleFavoriteStatusForCurrentModule
	tst.b	favorites(a5)
	beq.b	.1
	cmp.b 	#LISTMODE_FAVORITES,listMode(a5)
	beq.b	.1
	move.l	chosenmodule(a5),d0
	bsr.b	toggleFavoriteStatus
	beq.b	.1
	jsr	forceRefreshList
.1	rts




* Toggle favorite status for list node
* in:
*   d0 = node index
* out:
*	d0 = 0 on failure, 1 on OK
toggleFavoriteStatus
	* Get the actual node into a0
	bsr.w	getListNode
	beq.b	.notFound

	tst.b	l_divider(a0)
	bne.b	.notFile

	* Toggle favorite status
	isFavoriteModule a0 
	bne.b	.wasFavorite
	bsr.b	addFavoriteModule
	bra.b	.wasNotFavorite
.wasFavorite
	bsr.w	removeFavoriteModule
.wasNotFavorite
	moveq	#1,d0
	rts
.notFound
.notFile
	moveq	#0,d0
	rts

* in:
*   a0 = module list node
addFavoriteModule
	isFavoriteModule a0
	bne.b .exit

 if DEBUG
	pea	l_filename(a0)
	pop  d0
	DPRINT	"addFavoriteModule %s"
 endif
	* set favorite flag
	st	l_favorite(a0)
	
	* see if for some reason a0 is already in the favorite list
	bsr.w	findFavoriteModule
	tst.l	d0
	bne.b	.exit	* bail out if so

	move.l	a0,a3

	* copy this node and add to favorite list
	* get length of memory region, it's before the actual data
	move.l	-4(a3),d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	jsr	getmem
	beq.b	.noMem
	move.l	d0,a4

	* Copy node contents
	move.l	a3,a0
	move.l	a4,a1
	move.l	-4(a3),d0
	lore 	Exec,CopyMem

	* Need to modify l_nameaddr pointer to point to the newly copied path.
	* Figure out the index to the name-without-path using the original node
	
	lea	l_filename(a3),a0	* this ptr is lower than
	move.l	l_nameaddr(a3),d0 	* ... this ptr
	sub.l	a0,d0	 * d0 is now an index 	

	* apply index to the new node
	lea	l_filename(a4,d0.l),a0
	move.l	a0,l_nameaddr(a4)

	* Append to list
	move.l	a4,a1
	lea	favoriteListHeader(a5),a0
	lob	AddTail

	st	favoriteListChanged(a5)
 if DEBUG
	bsr.w	logFavoriteList
 endif
.noMem
.exit
	rts

* in:
*  a0 = module list node
removeFavoriteModule
	isFavoriteModule a0
	beq.b	.exit
	clr.b	l_favorite(a0)

 if DEBUG
	pea	l_filename(a0)
	pop  d0
	DPRINT	"removeFavoriteModule %s"
	 endif

.loop
	* Find matching l_filename from favorite list
	* node is in a0
	bsr.b	findFavoriteModule
	beq.b	.exit
	* found matching one, in a1
	move.l	a1,d2
	* Remove a1 from list 
	* Destroys a0, a1
	push	a0
	REMOVE
	* Free associated memory
	move.l	d2,a0
	jsr 	freemem
	pop	a0
	st	favoriteListChanged(a5)
	* search again to find duplicates, although there shouldn't be 
	bra.b	.loop
.exit
 if DEBUG
	bsr.w	logFavoriteList
 endif
	rts

* in:
*   a0 = node to find by matching filename
* out:
*   a1 = favorite node that matches
*   d0 = 1 when match, 0 when no match
* destroys:
*   d0,a2,a3
findFavoriteModule
	* Find matching l_filename from favorite list
	lea	favoriteListHeader(a5),a1
.loop
	TSTNODE	a1,a1
	beq.b	.notFound
	lea	l_filename(a0),a2
	lea	l_filename(a1),a3
.compare
	* if name differs get the next one
	cmpm.b	(a2)+,(a3)+
	bne.b	.loop
	* matches so far, loop until zero termination
	tst.b	(a2)
	bne.b	.compare
	* the counterpart must also have a zero here
	tst.b	(a3)
	bne.b	.notFound
* no differences found, it is a match
	moveq	#1,d0
	rts
.notFound
	moveq	#0,d0
	rts

freeFavoriteList
	move.l	(a5),a6		* execbase
	lea	favoriteListHeader(a5),a2
.loop
	* a0: list, a1: destroyed, d0: node, or zero
	move.l	a2,a0
	lob	RemHead
	beq.b	.listFreed
	move.l	d0,a0
	jsr	freemem
	bra.b	.loop

.listFreed
	st	favoriteListChanged(a5)
	cmp.b 	#LISTMODE_FAVORITES,listMode(a5)
	bne.b	.noFav
	* In favorite mode, no more modules to show
	clr.l	modamount(a5)
.noFav	
	rts

importFavoriteModulesFromDisk
	DPRINT	"importFavoriteModulesFromDisk"
	tst.b	favorites(a5)
	bne.b	.enabled
	DPRINT	"->disabled in prefs"
	rts
.enabled

	moveq	#0,d6
	lea	favoriteModuleFileName(pc),a0
	jsr	plainLoadFile
	move.l	d0,d6
	beq.b	.noData
	move.l	d1,d5

	lea favoriteListHeader(a5),a2
	move.l	d6,a3			* start of buffer	
	lea	(a3,d5.l),a4	* end of buffer
	jsr	importModuleProgramFromData
	DPRINT 	"Imported %ld favorite files"

	move.l	d6,a0
	jsr	freemem
.noData
	bsr.w	logFavoriteList
	rts


exportFavoriteModulesWithMessage
	pushm	all
	tst.b	favorites(a5)
	beq.w	.x
	tst.b	favoriteListChanged(a5)
	beq.w	.x

	* storage for two intuitimes
	lea	-16(sp),sp
	lea	(sp),a0 		* secs
	lea	4(sp),a1		* micros
	lore	Intui,CurrentTime

	jsr	setMainWindowWaitPointer
	jsr	freezeMainWindowGadgets
	lea	.msg(pc),a0
	moveq	#68+WINX,d0
	jsr	printbox
	bra.b	.c
.msg 	dc.b  	"Saving favorites...",0
 even
.c	bsr.b	exportFavoriteModulesToDisk
	* Wait a while so that user can see something happened
.wait
	lea	8(sp),a0		* secs
	lea	12(sp),a1		* micros
	lore	Intui,CurrentTime
	move.l	8(sp),d0
	sub.l	(sp),d0			* secs elapsed
	cmp.l	#1,d0			* this many secs at least
	bhs.b	.done
	moveq	#10,d1			* wait a bit
	lore	Dos,Delay
	bra.b	.wait
.done
	lea	16(sp),sp

	jsr	unfreezeMainWindowGadgets
	jsr	clearMainWindowWaitPointer
	* request full refresh of filebox:
	jsr	forceRefreshList
.x	popm	all
	rts
	
exportFavoriteModulesToDisk
	DPRINT	"exportFavoriteModulesToDisk"
	tst.b	favorites(a5)
	beq.b	.x

	* User is exiting while in fav mode?
	cmp.b 	#LISTMODE_FAVORITES,listMode(a5)
	bne.b	.normalMode
	move.b	moduleListChanged(a5),d0 
	clr.b	moduleListChanged(a5)
	or.b	d0,favoriteListChanged(a5)
.normalMode

	tst.b	favoriteListChanged(a5)
	beq.b	.x
	lea	favoriteModuleFileName(pc),a0
	lea	favoriteListHeader(a5),a1
	jsr 	exportModuleProgramToFile
	clr.b	favoriteListChanged(a5)
.x	rts

favoriteModuleFileName
	dc.b	"S:HippoFavorites.prg",0
 even

* in:
*  a0 = list node
updateFavoriteStatus
	tst.b	l_divider(a0)
	bne.b	.skipDivs
	bsr.w	findFavoriteModule
	* a matching favorite module was found? set flag 
	sne	l_favorite(a0)
.skipDivs
	rts

logFavoriteList
; if DEBUG
;	DPRINT	"Favorite modules:"
;	lea	favoriteListHeader(a5),a0
;.l	TSTNODE	a0,a0
;	beq.b	.x
;	lea	l_filename(a0),a1
;	move.l	a1,d0
;	DPRINT	"%s"
;	bra.b	.l
;.x
; endif
	rts

handleFavoriteModuleConfigChange
	pushm	all

	tst.b	favorites(a5)
	beq.b	.noFavs
	DPRINT	"handleFavoriteModuleConfigChange: enabled"
	
* favorites are enabled.
* - they may have been enabled ealier, or
* - they became enabled just now

* if the list is not empty, this likely means favorites was enabled
* and there is stuff in the list, do nothing
	lea	favoriteListHeader(a5),a0
	IFNOTEMPTY a0,.exit

	DPRINT	"->populating"

* if list is empty, try importing data
	bsr.w	importFavoriteModulesFromDisk
* then the current list should be updated to contain favorite statuses
	lea	moduleListHeader(a5),a0
.loop
	TSTNODE	a0,a0
	beq.b	.end
	* find if node a0 is in favorite module list
	bsr.w	findFavoriteModule
	* Use the return status to update favorite status for this node 
	move.b	d0,l_favorite(a0)
	bra.b	.loop
.end
	* refresh list
	bra.b	.refresh

.noFavs
	DPRINT	"handleFavoriteModuleConfigChange: disabled"
	;bsr.w	disableListModeChangeButton
	cmp.b 	#LISTMODE_FAVORITES,listMode(a5)
	bne.b	.noFav
	* If disabled from prefs must toggle to normal mode
	;bsr.b	toggleListMode
	bsr.b	engageNormalMode
.noFav
	
	* favorites are not enabled
	lea	favoriteListHeader(a5),a0
	IFEMPTY a0,.exit
	DPRINT	"->cleaning up"
	* there's some stuff in the list, free it and refresh view
	* l_favorite need not be cleaned since they won't be displayed
	* anyway if feature is disabled
	bsr.w	freeFavoriteList
.refresh
	jsr	forceRefreshList

.exit
	popm	all 
	rts

********************************************************************************
*** SECTION ********************************************************************
*
* List mode operations
*
******************************************************************************

toggleListMode
	cmp.b 	#LISTMODE_NORMAL,listMode(a5)
	beq.b	engageFavoritesMode
	cmp.b	#LISTMODE_FAVORITES,listMode(a5)
	beq.w	engageFileBrowserMode
	; falling
	;cmp.b	#LISTMODE_BROWSER,listMode(a5)
	;beq.b	engageNormalMode
	;rts

engageNormalMode
	DPRINT	"engage normal"
	pushm	all
	
	cmp.b	#LISTMODE_NORMAL,listMode(a5)
	beq.b	.skip
	
	cmp.b	#LISTMODE_FAVORITES,listMode(a5)
	bne.b	.wasNotFav

	* List was in favorite mode.
	* Store list changed status, so changes will be saved.
	* Combine with favoritesListChanged, since that may also
	* indicate save status from edits in normal listview.
	move.b	moduleListChanged(a5),d0
	or.b	d0,favoriteListChanged(a5)
	clr.b	moduleListChanged(a5)

.wasNotFav
	move.b	#LISTMODE_NORMAL,listMode(a5)
	bsr.b	engageListMode

.skip
	popm	all
	rts	

engageFavoritesMode
	pushm	all
	DPRINT	"engage favorites"
	* Moving to favorite mode
	* moduleListChanged must be cleared initially to catch
	* any subsequent user edits.
	clr.b	moduleListChanged(a5)
	move.b	#LISTMODE_FAVORITES,listMode(a5)
	bsr.b	engageListMode
	popm	all
	rts	
	
* Common operations to be done after list mode change
engageListMode
	bsr.w	.setListModeChangeButtonIcon
	bsr.w	.setButtonStatesAccordingToListMode
	bsr.b	.setListState
	* Playing module should be invalidated,
	* it is not compatible between the two lists.
	tst.l	playingmodule(a5) 
	bmi.b	.not
	move.l	#PLAYING_MODULE_REMOVED,playingmodule(a5)
.not
	rts


.setListState
	* Remove previous list selection
	move.l	#PLAYING_MODULE_NONE,chosenmodule(a5)		

	jsr	obtainModuleList	
	jsr	clearRandomTable
	
	bsr.w	clearCachedNode
	bsr.w	getVisibleModuleListHeader
	move.l	a0,a4
	* set d1 to FF if list is in normal mode
	cmp.b	#LISTMODE_NORMAL,listMode(a5)
	seq 	d1
	* set d2 to FF if favorites changed
	tst.b	favoriteListChanged(a5)
	sne	d2
	and.b	d1,d2
	* d2 is now FF is both are true:
	* - list in normal mode
	* - favorites were changed
	* in this case, we must update the favorite status
	* of each list node

	* TODO: kick13 slider4 height is bad
	* TODO: profiling

	* Need to update modamount(a5) and check
	* favourite status if user has edited
	* favorites. Can take a while!
	jsr	setMainWindowWaitPointer
	
	moveq	#0,d3
.count
	TSTNODE a4,a4
	beq.b	.end
	tst.b	d2
	beq.b	.noChange
	move.l	a4,a0
	bsr.w	updateFavoriteStatus
.noChange
	addq.l	#1,d3
	bra.b	.count
.end
	move.l	d3,modamount(a5)
 if DEBUG
	move.l	d3,d0
	DPRINT	"Modamount=%ld"
 endif
	jsr	releaseModuleList
	jsr	clearMainWindowWaitPointer
	jsr	forceRefreshList
	rts

.setButtonStatesAccordingToListMode
	lea	gadgets,a4
	basereg	gadgets,a4
	cmp.b	#LISTMODE_NORMAL,listMode(a5)
	beq.b	.normalMode
	cmp.b	#LISTMODE_FAVORITES,listMode(a5)
	beq.b	.favoritesMode
	cmp.b	#LISTMODE_BROWSER,listMode(a5)
	beq.b	.browserMode
	rts

.normalMode
	lea	gadgetAddButton(a4),a0
	bsr.w	enableButtonWithEar
	lea	gadgetDelButton(a4),a0
	bsr.w	enableButtonWithEar
	lea	gadgetNewButton(a4),a0
	bsr.w	enableButtonWithEar
	lea	gadgetSortButton(a4),a0
	bsr.w	enableButtonWithEar
	lea	gadgetMoveButton(a4),a0
	bsr.w	enableButtonWithEar
	lea	gadgetPrgButton(a4),a0
	bsr.w	enableButtonWithEar
	rts

.favoritesMode
	lea	gadgetPrgButton(a4),a0
	bsr.w	disableButton
	rts

	
.browserMode
	lea	gadgetAddButton(a4),a0
	bsr.w	disableButton
	lea	gadgetDelButton(a4),a0
	bsr.w	disableButton
	lea	gadgetNewButton(a4),a0
	bsr.w	disableButton
	;lea	gadgetSortButton(a4),a0
	;bsr.w	disableButton
	lea	gadgetMoveButton(a4),a0
	bsr.w	disableButton
	lea	gadgetPrgButton(a4),a0
	bsr.w	disableButton
	endb	a4
	rts

.setListModeChangeButtonIcon
	lea	listImage,a0
	cmp.b 	#LISTMODE_NORMAL,listMode(a5)
	beq.b	.set
	lea	favoriteImage-listImage(a0),a0
	cmp.b 	#LISTMODE_FAVORITES,listMode(a5)
	beq.b	.set
	lea	fileBrowserImage-favoriteImage(a0),a0
	cmp.b 	#LISTMODE_BROWSER,listMode(a5)
	beq.b	.set
	rts
.set
	* Toggle listmode button icon
	move.l	a0,gadgetListModeChangeButtonImagePtr
	lea	gadgetListModeChangeButton,a0
	jmp	refreshGadgetInA0
	

********************************************************************************
*** SECTION ********************************************************************
*
* Save state operations
* - module list
* - list mode
* - chosen module
* - play status
*
*******************************************************************************

importSavedStateModulesFromDisk
	DPRINT	"importSavedStateModulesFromDisk"
	tst.b	savestate(a5)
	bne.b	.enabled
.error	rts

.enabled
	lea	savedStateModuleFileName(pc),a0
	jsr	plainLoadFile
	move.l	d0,d6	* address
	beq.b	.error
	move.l	d1,d7 	* length

	lea moduleListHeader(a5),a2
	move.l	d6,a3		* start of buffer	
	lea	(a3,d7.l),a4	* end of buffer
	jsr	importModuleProgramFromData
	DPRINT 	"Imported %ld files"

	move.l	d6,a0
	jsr	freemem

	* Can be zero
	move.l	d0,modamount(a5)
	
	pushpea	savedStateModuleFileName(pc),d1
	moveq	#ACCESS_READ,d2
	lore	Dos,Lock
	move.l	d0,d4
	beq.b	.noLock
	move.l	d4,d1
	pushpea	fileinfoblock(a5),d2
	lob	Examine
	move.l	d4,d1
	beq.b	.noLock
	lob	UnLock
	lea	fileinfoblock+fib_Comment(a5),a0
 if DEBUG
	move.l	a0,d0
	DPRINT	"State=%s"
 endif
	cmp.b	#" ",8(a0)
	beq.b	.parse
.noLock
.exit
	jsr	resh
.none
	rts
	
.parse
* "00000000 00 abc"
* convert into number
	moveq	#0,d3
	moveq	#28,d1
	moveq	#8-1,d2
.loop
	moveq	#0,d0
	move.b	(a0)+,d0
	cmp.b	#"A",d0
	bhs.b	.hi 
	sub.b	#"0",d0
	bra.b	.lo
.hi
	sub.b	#"A"-10,d0
.lo
	lsl.l	d1,d0
	or.l	d0,d3
	subq.l	#4,d1
	dbf	d2,.loop

	* check play/no play
	cmp.b	#"1",1(a0)
	seq	d7

	* check list mode!
	* switch mode before setting chosen module
	* chosenmodule will be reset otherwise.
	cmp.b	#"1",2(a0)
	beq.b	.favMode
	cmp.b	#"2",2(a0)
	beq.b	.browserMode
	* default
	bsr.w	engageNormalMode
	bra.b	.engaged
.favMode
	bsr.w	engageFavoritesMode
	bra.b	.engaged
.browserMode
	bsr.w	engageFileBrowserMode
	cmp.b	#" ",3(a0)
	bne.b	.engaged
	tst.b	4(a0)
	beq.b	.engaged
	* Pass path into a0
	addq	#4,a0
	pushm	d3/d7
	bsr.w	fileBrowserDirWithPath	
	popm	d3/d7
	bra.b	.fbInit

.engaged

	cmp.b	#" ",3(a0)
	bne.b	.noPath
	tst.b	4(a0)
	beq.b	.noPath

	lea	4(a0),a1
	move.l	a1,a2
.fl	tst.b	(a2)+
	bne.b	.fl
	
	move.l	a2,d0
	sub.l	a1,d0 
	moveq	#MEMF_PUBLIC,d1
	jsr	getmem
	move.l	d0,lastStoredFileReqDirectory(a5) 
	beq.b	.noPath
	move.l	d0,a0
.copy
	move.b	(a1)+,(a0)+
	cmp.l	a2,a1
	bne.b	.copy

	DPRINT	"Saved filereq path=%s"

.noPath
.fbInit
	tst.l	d3
	bmi.b	.neg
	move.l	d3,chosenmodule(a5)
.neg

	* Finally, either just refresh or play.
	tst.b	d7
	beq.w	.exit
	jsr	resh
	tst.l	modamount(a5)
	beq.b	.empty
	jmp	playButtonAction
.empty
	rts

exportSavedStateModulesToDisk
	DPRINT	"exportSavedStateModulesToDisk"
	tst.b	savestate(a5)
	beq.w	.x

	lea	savedStateModuleFileName(pc),a0
	lea	moduleListHeader(a5),a1
	jsr 	exportModuleProgramToFile

	* Formatting parameters into d0,d1,d2,d3

	* Store current file browser dir, if
	* currently in browser mode
	cmp.b	#LISTMODE_BROWSER,listMode(a5)
	bne.b	.notBrowser
	move.l	fileBrowserCurrentDirLock(a5),d1
	beq.b	.notBrowser

	pushpea	probebuffer(a5),d2	* temp buffer
	move.l	#200,d3
	bsr.w		getNameFromLock
	tst.l	d0
	beq.b	.notBrowser
	pushpea	probebuffer(a5),d3
	bra.b	.yesDir
.notBrowser

	* Store last used dir as well
	* Try the reqtools dir first
	move.l	req_file(a5),d3
	beq.b	.doEmpty
	move.l	d3,a0
	move.l	rtfi_Dir(a0),d3
	bne.b	.yesDir
.doEmpty
	* ..then the previously stored one
	move.l	lastStoredFileReqDirectory(a5),d3
	bne.b	.yesDir
	pushpea	.empty(pc),d3
.yesDir

	* Store playing state and chosen module into comment
	move.l	chosenmodule(a5),d0

	moveq	#0,d1
	tst.l	playingmodule(a5)
	bmi.b	.no
	moveq	#1,d1
.no
	
* Store list mode
	moveq	#0,d2
	move.b	listMode(a5),d2

	lea	.comment(pc),a0
	lea	probebuffer(a5),a1 	* nice temp buffer
	jsr	desmsg

 if DEBUG 
	pushpea desbuf(a5),d0
	DPRINT	"->%s"
 endif

	pushpea	savedStateModuleFileName(pc),d1
	pushpea	desbuf(a5),d2
	lore	Dos,SetComment

.x	rts

* <chosenmodule< <play/noplay><listmode> <filereq path> 
.comment	dc.b	"%08lx %ld%ld %s"
.empty		dc.b	0
		even

savedStateModuleFileName
	dc.b	"S:HippoSavedList.prg",0
 even

********************************************************************************
*** SECTION ********************************************************************
*
* File browser mode operations
*
********************************************************************************

freeFileBrowserList
	push	a6
	move.l	(a5),a6		* execbase
	lea	fileBrowserListHeader(a5),a2
.loop
	* a0: list, a1: destroyed, d0: node, or zero
	move.l	a2,a0
	lob	RemHead
	beq.b	.listFreed
	move.l	d0,a0
	jsr	freemem
	bra.b	.loop
.listFreed
	cmp.b	#LISTMODE_BROWSER,listMode(a5)
	bne.b	.noB
	clr.l	modamount(a5)
.noB	pop	a6
	rts

countFileBrowserFiles
	jsr	obtainModuleList
	lea	fileBrowserListHeader(a5),a0
	moveq	#0,d0
.loop
	TSTNODE	a0,a0
	beq.b	.x
	addq.l	#1,d0
	bra.b	.loop
.x
	jsr	releaseModuleList
	rts

engageFileBrowserMode
	DPRINT	"engage file browser"
	pushm	all
	move.b	#LISTMODE_BROWSER,listMode(a5)
	bsr.b	countFileBrowserFiles
	move.l	d0,modamount(a5)
	bsr.w	engageListMode
	tst.l	modamount(a5)
	bne.b	.notRootView
	moveq	#0,d0	* initial chosen item
	bsr.b	fileBrowserRoot
.notRootView
	popm	all
	rts

* Fill root level entries with volume names
* in:
*   d0 = chosen item index
fileBrowserRoot
	DPRINT	"file browser root, select=%ld"
	push	d0
	jsr	setMainWindowWaitPointer
	jsr	obtainModuleList
	clr	fileBrowserSelectionHistoryIndex(a5)
	bsr.w	freeFileBrowserList

	* According to the Amiga Guru Book, access to dl_Root
	* should always be protected as it may change.
	lore	Exec,Forbid

	move.l	_DosBase(a5),a0
	move.l	dl_Root(a0),a0
	move.l	rn_Info(a0),d0
	lsl.l	#2,d0
	move.l	d0,a0
	move.l	di_DevInfo(a0),d5
.devloop
	lsl.l	#2,d5
	move.l	d5,a3
	
	* Only grab volumes
	cmp.l	#DLT_VOLUME,dl_Type(a3)
	bne.b	.next

	move.l	dl_Name(a3),d1
	lsl.l	#2,d1
	move.l	d1,a2
	moveq	#0,d2
	move.b	(a2)+,d2

	* Add extra space for ":" and NULL
	moveq	#l_size+2,d0	
	add.l	d2,d0
	move.l	#MEMF_CLEAR,d1
	jsr	getmem
	beq.b	.error

	move.l	d0,a1
	lea	l_filename(a1),a0
	move.l	a0,l_nameaddr(a1)
	st	l_divider(a1)
	subq	#1,d2
.copyName
	move.b	(a2)+,(a0)+
	dbf	d2,.copyName
	move.b	#":",(a0)+
	clr.b	(a0)

	bsr.w	getVisibleModuleListHeader
	ADDTAIL	* add node (a1)
	addq.l	#1,modamount(a5)
.next
	move.l	dl_Next(a3),d5
	bne.b	.devloop

.error

	lore	Exec,Permit

	* Does not do force refresh
	jsr	sortModuleList

	* Select item
	pop	d0
	move.l	d0,chosenmodule(a5)
	jsr	forceRefreshList
	
	jsr	releaseModuleList
	jsr	clearMainWindowWaitPointer
	rts


* Enters a given directory 
* in:
*    a0 = path
fileBrowserDirWithPath
	moveq	#-1,d4
	move.l	a0,d1
	bra.b	fileBrowserDir\.plainPath

* Enters a directory denoted by the given list node, which is a divider
* in:
*    a3 = parent node
fileBrowserDir
 if DEBUG
	pushpea	l_filename(a3),d0
	move.l	chosenmodule(a5),d1
	DPRINT	"fileBrowserDir %s at %ld"
 endif
	* Chosen module status in d4
	moveq	#-1,d4
	move.l	a3,a0
	bsr.w	isFileBrowserParentNode
	beq.b	.notParent
 if DEBUG
 	pushpea	l_filename(a3),d0
 	move.l	l_nameaddr(a3),d1
	DPRINT	"->ENTERING parent %s -> %s"
 endif
	* When entering parent pop the selection from history
	bsr.w	popFileBrowserSelectionHistoryItem
	move.l	d0,d4
.notParent

	* Path to d1
	pushpea	l_filename(a3),d1

	* Check if empty path, this means the root level
	tst.b	l_filename(a3)
	beq.w	fileBrowserRoot

.plainPath
	jsr	obtainModuleList
	jsr	setMainWindowWaitPointer
	jsr	tokenizepattern

	tst.l	d4
	bpl.b	.goingToParent
	* Entering a new dir, push previous selection,
	bsr.w	pushFileBrowserSelectionHistoryItem
	* ... then select first item.
	moveq	#0,d4
.goingToParent
	* d4 and d5 flow to the end
	moveq	#0,d5	* initial value

	* Start reading dir
	* path in d1
	moveq	#ACCESS_READ,d2
	lore	Dos,Lock
	move.l	d0,d6
	beq.w	.error0

	move.l	d6,d1
	pushpea	fileinfoblock(a5),d2
	lob	Examine
	tst.l	d0
	beq.w	.error0

	* Copy lock for state saving
	move.l	fileBrowserCurrentDirLock(a5),d1
	beq.b	.1
	lob	UnLock
.1 	move.l	d6,d1
	lob	DupLock
	move.l	d0,fileBrowserCurrentDirLock(a5)

	* Empty whatever we had previously
	bsr.w	freeFileBrowserList

	*********************************************
	* Construct "Parent"
	*********************************************
	
	* NULL lock means the "SYS:"
	move.l	d6,d1
	lore	Dos,ParentDir
	move.l	d0,d7
		
	lea	-200(sp),sp
	move.l	d0,d1		* lock
	bne.b	.notNull
	* NULL lock, clear the path to indicate this
	clr.b	(sp)
	bra.b	.ok
.notNull
	move.l	sp,d2		* buf
	move.l	#200,d3		* len
	bsr.w	getNameFromLock
	push	d0
	move.l	d7,d1
	lore 	Dos,UnLock
	pop	d0
	tst.l	d0
	bne.b	.ok
	lea	200(sp),sp
	bra.w	.error0

.ok
	* Create parent entry 

	move.l	sp,a0
	moveq	#createNode\.PARENT,d7	 * make parent node
	bsr.w	createNode
	lea	200(sp),sp
	tst.l	d0
	beq.w	.error0

	bsr.w	makeParentNode
	* store parent node into d5 for a while
	move.l	a0,d5
	
	*********************************************
	* Dir scan
	*********************************************

	* Build base path
	lea	-200(sp),sp
	move.l	d6,d1		* lock
	move.l	sp,d2		* buf
	move.l	#160,d3		* len, leave 40 for filename
	bsr.w	getNameFromLock
	tst.l	d0
	beq.b	.lockFail

	move.l	sp,a0
.findEnd
	tst.b	(a0)+
	bne.b	.findEnd
	subq	#1,a0		* back to NULL

	cmp.b	#":",-1(a0)
	beq.b	.isSep
	cmp.b	#"/",-1(a0)
	beq.b	.isSep
	move.b	#"/",(a0)+
.isSep
	* Path address
	move.l	sp,a3
	* Filename part start position
	move.l	a0,a4

.scan
	move.l	d6,d1
	pushpea	fileinfoblock(a5),d2
	lore	Dos,ExNext
	tst.l	d0
	beq.b	.scanDone

	move.l	fib_DirEntryType+fileinfoblock(a5),d0
	cmp.l	#ST_FILE,d0
	beq.b	.file
	cmp.l	#ST_LINKFILE,d0
	beq.b	.file
	cmp.l	#ST_USERDIR,d0
	bne.b	.scan
	moveq	#createNode\.DIR,d7	* dir
	bra.b	.plzDo

.file
	tst.b	uusikick(a5)
	beq.b	.oldKick
	pushpea	tokenizedpattern(a5),d1
	pushpea	fib_FileName+fileinfoblock(a5),d2
	lore	Dos,MatchPatternNoCase
	* 0 = did not match, skip this file if so
	tst.l	d0
	beq.b	.scan
.oldKick
	moveq	#createNode\.FILE,d7	* file
.plzDo
	bsr.b	.doEntry
	bne.b	.scan	* stop on error

.scanDone
.lockFail
	lea	200(sp),sp
.error0

	move.l	d6,d1
	beq.b	.noLock
	lore	Dos,UnLock
.noLock

	* HACK! If playmode(a5) is pm_random, this happens:
	* sortModuleList -> listChanged -> clear_random ->
	* showNames. The sorted list is updated, then
	* the header is added, and another refresh is done.
	* This causes flicker and also the selected item
	* focus can become off-by-one.
	* Temporarily disable the random mode to prevent this.
	 
	move.b	playmode(a5),d6
	move.b	#pm_repeat,playmode(a5)

	* All done. Sort it. 
	* Does not do force refresh.
	* Destroys every register known to man.
	pushm	d4/d5/d6
	jsr	sortModuleList
	popm	d4/d5/d6

	* Restore iiiiit	
	move.b	d6,playmode(a5)
	
	* Insert parent to the top
	tst.l	d5
	beq.b	.noParent
	bsr.w	getVisibleModuleListHeader
	* get parent node
	move.l	d5,a1
	* Insert a1 into a0
	lore	Exec,AddHead
	addq.l	#1,modamount(a5)
.noParent

	* Figure out if the chosen module.
	* Eg, returning from "parent" to a correct item.
 	move.l	d4,chosenmodule(a5)
	jsr	forceRefreshList
	
	jsr	releaseModuleList
	jsr	clearMainWindowWaitPointer
	rts

* Creates a list node and adds it to the list
* in:
*   a3 = Path start address
*   a4 = Filename start address in the path
*   d6 = parent lock
*   d7 = 0 = file, 1 = dir
*   fileinfoblock: File to add
* out:
*   d0: 1 = ok, 0 = error
.doEntry	
	* copy current filename part, from ExNext
	lea	fib_FileName+fileinfoblock(a5),a1
	move.l	a4,a2
.cp2
	move.b	(a1)+,(a2)+
	bne.b	.cp2

	move.l	a3,a0
	* Create node using path in a0
	bsr.w createNode
	beq.b	.error_

	pushm	a3/a4
	move.l	a0,a3
	pushpea	l_filename(a3),d0
	jsr	addfile
	popm	a3/a4
	moveq	#1,d0	* ok
	rts
.error_
	moveq	#0,d0 	* failboat
	rts


fileBrowserGoToParent
	DPRINT	"Go to parent"
	* Get the 1st node
	moveq	#0,d0
	bsr.w	getListNode
	beq.b	.x
	move.l	a0,a3	* save this
	bsr.b	isFileBrowserParentNode
	beq.b	.x
	* Enter into node a3
	bsr.w	fileBrowserDir
.x
	rts

* Checks if this node is a "Parent" node
* in:
*   a0 = node
* out:
*   d0 = 1 if was a parent node, 0 otherwise
isFileBrowserParentNode
	cmp.b	#$7f,l_divider(a0)
	bne.b	.not
	moveq	#1,d0	* true
	rts
.not
	moveq	#0,d0	* false
	rts

* Make node a parent directory node
* in:
*   a0 = node
makeParentNode
	push	a0
	pushpea	fib_FileName+fileinfoblock(a5),d0
	lea	.form(pc),a0
	jsr	desmsg
	pop	a0

	lea	l_filename(a0),a1
.end	tst.b	(a1)+
	bne.b	.end
	move.l	a1,l_nameaddr(a0)
	lea	desbuf(a5),a2
.cp	move.b	(a2)+,(a1)+
	bne.b	.cp
 
	* magic: indicate parent divider/dir with $7f,
	* normal divider/dir is $ff.
	move.b	#$7f,l_divider(a0)

 if DEBUG
	pushpea	l_filename(a0),d0
	move.l	l_nameaddr(a0),d1
	DPRINT	"makeParentNode path=%s->`%s`"
 endif
	rts

.form	dc.b	"´´´ %s",0
 even


* in:
*   a0: path
*   d7: 0 = file, 1 = dir, 2 = parent dir
* out:
*   a0: new node
*   d0: 1 on success, 0 on out-of-mem
createNode
.FILE = 0
.DIR = 1
.PARENT = 2

	move.l	a0,d1
	move.l	d7,d0

	move.l	a0,a2
.len
	tst.b	(a0)+
	bne.b	.len
	sub.l	a2,a0
	add	#l_size,a0
	cmp.b	#.PARENT,d7
	bne.b	.notPar
	add	#30,a0		* additional space for list item name
.notPar
	move.l	a0,d0
	move.l	#MEMF_CLEAR,d1
	jsr	getmem
	beq.b	.memErr
	move.l	d0,a0

	* copy path
	lea	l_filename(a0),a1

	tst.b	d7
	beq.b	.notDiv
	st	l_divider(a0)
.notDiv

.copy	move.b	(a2)+,(a1)+
	bne.b	.copy

	* find file name
	lea	l_filename(a0),a2
.findFile
	cmp.b	#"/",-1(a1)
	beq.b	.found
	cmp.b	#":",-1(a1)
	beq.b	.found
	subq	#1,a1
	cmp.l	a2,a1
	bne.b	.findFile
.found	
	move.l	a1,l_nameaddr(a0)
	moveq	#1,d0
	rts
.memErr
	moveq	#0,d0
	rts

* Keeps track of indexes of entered directories.
pushFileBrowserSelectionHistoryItem
	move	fileBrowserSelectionHistoryIndex(a5),d0
 	cmp	#FILEBROWSER_HISTORY_SIZE,d0
	bhs.b	.full
	lea	fileBrowserSelectionHistory(a5),a0
 	lsl	#2,d0
	move.l	chosenmodule(a5),(a0,d0)
 	addq	#1,fileBrowserSelectionHistoryIndex(a5)
.full
	rts

* Pops the last item out.
popFileBrowserSelectionHistoryItem
	move	fileBrowserSelectionHistoryIndex(a5),d0
	subq	#1,d0
	bpl.b	.ok
	DPRINT	"Browser history underflow"
	moveq	#0,d0
	rts
.ok
	move	d0,fileBrowserSelectionHistoryIndex(a5)
 	lsl	#2,d0
	lea	fileBrowserSelectionHistory(a5),a0
	add	d0,a0
	move.l	(a0),d0
	clr.l	(a0)
 	rts


;parentNodeLabel
;	dc.b 	"  ´´´´´´´ Parent ªªªªªªªª  "
;		    ;0123456789123456789012345678
;	even

*******************************************************************************
* CreatePort
*******
createport
	movem.l	a0-a2,-(sp)
	lea	audioport(a5),a0
	move.l	a0,a2
	lea	MP_SIZE(a0),a1
.clr	clr	(a0)+
	cmp.l	a1,a0
	bne.b	.clr
	move.l	owntask(a5),MP_SIGTASK(a2)
	move.b	audioPortSignal(a5),MP_SIGBIT(a2)
	move.b	#NT_MSGPORT,LN_TYPE(a2)
	clr.l	LN_NAME(a2)
	move.b	#PA_SIGNAL,MP_FLAGS(a2)
	lea	MP_MSGLIST(a2),a0
	NEWLIST	a0
	movem.l	(sp)+,a0-a2
	rts

*******
* CreateIO
*******
createio
	movem.l	a0-a2,-(sp)
	lea	iorequest(a5),a0
	move.l	a0,a2
	lea	ioa_SIZEOF(a0),a1
.clr	clr	(a2)+
	cmp.l	a1,a2
	bne.b	.clr
	lea	audioport(a5),a1
	move.l	a1,MN_REPLYPORT(a0)
	move.b	#NT_MESSAGE,LN_TYPE(a0)
	move	#ioa_SIZEOF,MN_LENGTH(a0)
	movem.l	(sp)+,a0-a2
	rts

***************************************************************************
* getNameFromLock
* DOS library NameFromLock is originally a V36 function. 
* Here's a port ofthe  V40 implementation that works on older 
* kickstarts.
* in:
*   d1 = lock
*   d2 = output buffer
*   d3 = max length of output buffer, will fail if not enough
* out:
*   d0 = 1 success, 0 failure
*******
getNameFromLock:
.true		equ	1
.false		equ	0
.return		equr	d5
.fl_lock	equr	d6
.fl_lock2	equr	d7
.fib		equr	d4

	tst.l 	d1
	bne.b	.lockOk
	DPRINT	"NULL lock!"
	* A NULL lock is valid and will return "SYS:" or similar, but
	* it is not ok in Hippo context.
	moveq	#.false,d0
	rts
.lockOk

	pushm 	d1-a6
	* It's all DOS, baby
	move.l	_DosBase(a5),a6
	tst.b	uusikick(a5)
	beq.b	.old
	lob     NameFromLock
 if DEBUG
	bne.b	.ok_
	DPRINT	"NameFromLock FAILED!"
.ok_
 endif	
 	tst.l	d0
	popm	d1-a6
	rts
.old

	* Use this one as the working fib, probably fine.
	pushpea	fileinfoblock2(a5),.fib

	* save start of output buffer to a3 for later
	move.l	d2,a3	

	* initial return code status: false
	moveq	#.false,.return

	* clear output buffer
	move.l	d3,d0			
	subq.l	#1,d0	* dbf length
	move.l	a3,a4	
.clr
	clr.b	(a4)+
	dbf	d0,.clr
	subq.l	#1,a4	* leave one zero at the end for safety

	* start filling a4 from the end

	* First, copy the lock
	lob 	DupLock
	move.l	d0,.fl_lock
.loop	
	move.l	.fl_lock,d1
	lob  	ParentDir
	move.l	d0,.fl_lock2
	beq.b	.loopEnd

	move.l	.fl_lock,d1
	move.l	.fib,d2
	lob 	Examine
	tst.l	d0
	beq.b	.cleanup
	
	* add separator if needed
	tst.b	(a4)
	beq.b	.noSep
	cmp.l	a3,a4		* space check!
	beq.b	.noSpace
	move.b	#'/',-(a4)
.noSep
	move.l	.fib,a0
	lea	fib_FileName(a0),a0
	move.l	a0,a1
.findEnd
	tst.b	(a0)+
	bne.b	.findEnd
	subq.l	#1,a0	* backtrack to NULL
.copyPart
	cmp.l	a3,a4		* space check!
	beq.b	.noSpace
	move.b	-(a0),-(a4)
	cmp.l	a0,a1
	bne.b	.copyPart
	
	* done with this lock, go looping
	move.l	.fl_lock,d1
	lob UnLock

	move.l .fl_lock2,.fl_lock
	bra.b	.loop
.loopEnd
	* next comes the name for the device
	cmp.l	a3,a4		* space check!
	beq.b	.noSpace
	move.b	#':',-(a4)

	* Dig into the lock, first convert BPTR to APTR.
	move.l	.fl_lock,a0
	add.l	a0,a0 
	add.l 	a0,a0
	move.l 	fl_Volume(a0),a0
	* a0 = BPTR to DevList
	add.l	a0,a0 
	add.l 	a0,a0
	move.l	dl_Name(a0),a0
	* a0 = BPTR to name, should be null terminated.
	* Check if true also on V34? Use the BCPL
	* string length, that should be good.
	add.l	a0,a0 
	add.l 	a0,a0
	
	moveq	#0,d0
	move.b	(a0)+,d0 * read BCPL string length
	move.l	a0,a1 	* keep the start address for loop

	* Skip to end of string
	add.l	d0,a0

.copyPart2
	cmp.l	a3,a4		* space check!
	beq.b	.noSpace
	move.b	-(a0),-(a4)
	cmp.l	a0,a1
	bne.b	.copyPart2	

	* all done!
	* move the resulting string to the front of the buffer.
	* here a3 and a4 point to the same buffer 

.move
	move.b	(a4)+,(a3)+
	bne.b	.move


	* indicate success
	moveq 	#.true,.return
.noSpace
.cleanup
	move.l	.fl_lock,d1
	lob UnLock
	
	* return status
	move.l	.return,d0
 if DEBUG
	bne.b	.ok 
	DPRINT	"GetNameFromLock FAILED!"
.ok
 endif	

	popm 	d1-a6
	tst.l 	d0
	rts


***************************************************************************
* Takes a file path and normalizes it by replacing
* logical names/assigns with actual drive names.
* It will transform path parts such as "SYS:"
* into drive names like "A500-HD:".
* In case of error original path remains untouched. 
* in:
*   d1 = pointer to path
* out:
*   path given in d1 is replaced, should contain space for growing

normalizeFilePath
 	pushm	all
 if DEBUG
	move.l	d1,d0
	DPRINT	"Normalizing: %s"
 endif
	move.l	d1,d7

 	;pushpea	tempdir(a5),d1
	moveq	#ACCESS_READ,d2
	lore  	Dos,Lock
	move.l	d0,d4
	beq.b	.noLock1
	lea	-200(sp),sp
	move.l	d4,d1
	move.l	sp,d2
	move.l	#200,d3
	bsr.w  	getNameFromLock
	tst.l	d0 
	beq.b	.noName
	move.l	sp,a0
	;lea		tempdir(a5),a1
	move.l	d7,a1
.copyPath
	move.b	(a0)+,(a1)+
	bne.b	.copyPath
	cmp.b	#':',-2(a1)
	beq.b	.isDrive
	move.b	#'/',-1(a1)
	clr.b	(a1)
.isDrive
.noName
	lea	200(sp),sp
	move.l	d4,d1
	lob 	UnLock
 if DEBUG
	move.l	d7,d0
	DPRINT	"to: %s"
 endif
.noLock1
	popm	all
	rts

***************************************************************************
* Insertion sort of string pointer array 
*
* in:
*  a0 = array of string pointers
*  d0 = length of the array, unsigned 16-bit
* out:
*  a0 = sorted array
sortStringPtrArray
	cmp	#1,d0
	bls.b	.x
	pushm	d1/d2/d3/d6/d7/a1/a2
	moveq	#1,d1 
.sortLoopOuter
	move	d1,d2
.sortLoopInner
	move	d2,d3
	lsl	#2,d3
	movem.l	-4(a0,d3),a1/a2
.strCmp 
	move.b	(a1)+,d6
	move.b	(a2)+,d7
	cmp.b	d6,d7
	blo.b	.swap
	tst.b	d6
	beq.b	.exitLoop
	tst.b	d7
	beq.b	.exitLoop
	cmp.b	d6,d7
	beq.b	.strCmp
	cmp.b	d6,d7
	bhi.b	.exitLoop
.swap
	movem.l	-4(a0,d3),a1/a2
	exg	a1,a2
	movem.l	a1/a2,-4(a0,d3)
	
	subq	#1,d2
;	bra.b 	.sortLoopInner
	bne.b	.sortLoopInner	
.exitLoop
	addq	#1,d1
	cmp 	d0,d1
	bne.b 	.sortLoopOuter
	popm	d1/d2/d3/d6/d7/a1/a2
.x	rts


*******************************************************************************
* Big buttons, normal buttons
*******************************************************************************

configureMainWindowButtonSizes
	lea	gadgets,a4
	basereg gadgets,a4

	lea	button1im,a3
	basereg button1im,a3

	tst.b	altbuttons(a5)
	beq.w	.useNormal
	; Already in alt mode?
	tst.b	altbuttonsUse(a5)
	bne.w	.x
	move.b	altbuttons(a5),altbuttonsUse(a5)
	* Enlarge main window!
	add	#16,WINSIZY(a5)

; Set up double buttons
	* 1st row
	lea	gadgetPlayButton(a4),a0
	lea	button1imDouble(a3),a2
	bsr.w	.double
	lea	gadgetInfoButton(a4),a0
	lea	button2imDouble(a3),a2
	bsr.w	.double
	lea	gadgetStopButton(a4),a0
	lea	button3imDouble(a3),a2
	bsr.w	.double
	lea	gadgetEjectButton(a4),a0
	lea	button4imDouble(a3),a2
	bsr.w	.double
	lea	gadgetNextButton(a4),a0
	lea	button5imDouble(a3),a2
	bsr.w	.double
	lea	gadgetPrevButton(a4),a0
	lea	button6imDouble(a3),a2
	bsr.w	.double
	lea	gadgetNextSongButton(a4),a0
	lea	button12imDouble(a3),a2
	bsr.b	.double
	lea	gadgetPrevSongButton(a4),a0
	lea	button13imDouble(a3),a2
	bsr.b	.double
	lea	gadgetForwardButton(a4),a0
	lea	kela2imDouble(a3),a2
	bsr.b	.double
	lea	gadgetRewindButton(a4),a0
	lea	kela1imDouble(a3),a2
	bsr.b	.double

	* 2nd row
	lea	gadgetAddButton(a4),a0
	bsr.b	.double2
	lea	gadgetDelButton(a4),a0
	bsr.b	.double2
	lea	gadgetNewButton(a4),a0
	bsr.b	.double2
	lea	gadgetPrefsButton(a4),a0
	bsr.b	.double2
	lea	gadgetVolumeSlider(a4),a0
	bsr.b	.double2
	lea	gadgetSortButton(a4),a0
	bsr.b	.double2
	lea	gadgetMoveButton(a4),a0
	bsr.b	.double2
	lea	gadgetPrgButton(a4),a0
	bsr.b	.double2

	lea	gadgetListModeChangeButton(a4),a0
	add	#16,gg_TopEdge(a0)

	lea	gadgetFileSlider(a4),a0
	add	#16,gg_TopEdge(a0)

	lea	gadgetVolumeSlider(a4),a0
	move.l	gg_GadgetRender(a0),a1
	pushpea slider1imDouble(a3),ig_ImageData(a1)
	addq	#8,ig_Height(a1)
	bra.b	.doubleDone
.double
	addq	#8,gg_Height(a0)
	move.l	gg_GadgetRender(a0),a1
	move.l	a2,ig_ImageData(a1)
	lsl.w	ig_Height(a1)
	rts
.double2
	addq	#8,gg_Height(a0)
	addq	#8,gg_TopEdge(a0)
	move.l	gg_GadgetText(a0),d0
	beq.b	.doubleNoText
	move.l	d0,a1
	addq	#4,it_TopEdge(a1)
.doubleNoText
.doubleDone
	rts

.useNormal
	; Already in normal mode?
	tst.b	altbuttonsUse(a5)
	beq.w	.x
	move.b	altbuttons(a5),altbuttonsUse(a5)

	* Diminish main window!
	sub	#16,WINSIZY(a5)

; Set up normal buttons

	* 1st row
	lea	gadgetPlayButton(a4),a0
	lea	button1im(a3),a2
	bsr.w	.normal
	lea	gadgetInfoButton(a4),a0
	lea	button2im(a3),a2
	bsr.w	.normal
	lea	gadgetStopButton(a4),a0
	lea	button3im(a3),a2
	bsr.w	.normal
	lea	gadgetEjectButton(a4),a0
	lea	button4im(a3),a2
	bsr.w	.normal
	lea	gadgetNextButton(a4),a0
	lea	button5im(a3),a2
	bsr.w	.normal
	lea	gadgetPrevButton(a4),a0
	lea	button6im(a3),a2
	bsr.w	.normal
	lea	gadgetNextSongButton(a4),a0
	lea	button12im(a3),a2
	bsr.b	.normal
	lea	gadgetPrevSongButton(a4),a0
	lea	button13im(a3),a2
	bsr.b	.normal
	lea	gadgetForwardButton(a4),a0
	lea	kela2im(a3),a2
	bsr.b	.normal
	lea	gadgetRewindButton(a4),a0
	lea	kela1im(a3),a2
	bsr.b	.normal

	* 2nd row
	lea	gadgetAddButton(a4),a0
	bsr.b	.normal2
	lea	gadgetDelButton(a4),a0
	bsr.b	.normal2
	lea	gadgetNewButton(a4),a0
	bsr.b	.normal2
	lea	gadgetPrefsButton(a4),a0
	bsr.b	.normal2
	lea	gadgetVolumeSlider(a4),a0
	bsr.b	.normal2
	lea	gadgetSortButton(a4),a0
	bsr.b	.normal2
	lea	gadgetMoveButton(a4),a0
	bsr.b	.normal2
	lea	gadgetPrgButton(a4),a0
	bsr.b	.normal2

	lea	gadgetListModeChangeButton(a4),a0
	sub	#16,gg_TopEdge(a0)

	lea	gadgetFileSlider(a4),a0
	sub	#16,gg_TopEdge(a0)

	lea	gadgetVolumeSlider(a4),a0
	move.l	gg_GadgetRender(a0),a1
	pushpea slider1im(a3),ig_ImageData(a1)
	subq	#8,ig_Height(a1)
	bra.b	.normalDone
.normal
	subq	#8,gg_Height(a0)
	move.l	gg_GadgetRender(a0),a1
	move.l	a2,ig_ImageData(a1)
	lsr.w	ig_Height(a1)
	rts
.normal2
	subq	#8,gg_Height(a0)
	subq	#8,gg_TopEdge(a0)
	move.l	gg_GadgetText(a0),d0
	beq.b	.normalNoText
	move.l	d0,a1
	subq	#4,it_TopEdge(a1)
.normalNoText
.normalDone
	rts

.x
	rts

	endb   a3
	endb   a4


*******************************************************************************
* IFF pictures to buttons
*******************************************************************************
 REM 
initializeButtonImages
	lea	iffname,a0
	lore	Exec,OldOpenLibrary
	tst.l	d0
	beq.w	.x
	move.l	d0,d7

	move.l	d0,a6
	lea	.pic(pc),a0
	moveq	#IFFL_MODE_READ,d0
	lob		OpenIFF
	move.l	d0,d6
	beq.b	.x

	move.l	d6,a1
	lob     GetBMHD
	tst.l	d0
	beq.b	.x
	move.l	d0,a4
	move	bmh_Width(a4),d1
	move	bmh_Height(a4),d2
	move.b	bmh_nPlanes(a4),d0

	lea bitmapPlayButton(pc),a0
	lore 	GFX,InitBitMap

	move	bmh_Width(a4),d0
	move	bmh_Height(a4),d1
	moveq	#0,d2
	move.b	bmh_nPlanes(a4),d2
	mulu	d2,d1
	lore	Exec,AllocRaster
	tst.l	d0
	beq.b	.x
	move.l	d0,a0
	lea	bitmapPlayButton+bm_Planes(pc),a1
	* Length of one plane in bytes:
	move	bitmapPlayButton+bm_BytesPerRow(pc),d1
	mulu	bitmapPlayButton+bm_Rows(pc),d1
	moveq	#0,d0
	move.b	bitmapPlayButton+bm_Depth(pc),d0
	subq	#1,d0
.planes
	move.l	a0,(a1)+
	add	d1,a0
	dbf	d0,.planes

	move.l	d6,a1
	lea	bitmapPlayButton(pc),a0
	move.l	d7,a6
	lob	DecodePic
	tst.l	d0
	beq.b	.x
	
	nop
.x
	tst.l	d6
	beq.b	.1
	move.l	d6,a1
	lob	CloseIFF

.1


	move.l	d7,d0
	jsr	closel

	rts

.pic	dc.b	"sys:HippoPlayButton.iff",0

bitmapPlayButton ds.b bm_SIZEOF
 EREM


*******************************************************************************
*** SECTION *******************************************************************
*
* Replay routines
* Related support functions
*
*******************************************************************************



*******************************************************************************
* Audio allocation
*******************************************************************************

varaa_kanavat
	tst.b	kanavatvarattu+var_b
	beq.b	.jee
	moveq	#0,d0
	rts
.jee	
	movem.l	d1-a6,-(sp)
	lea	var_b,a5

	move.l	playerbase(a5),a0
	move	p_liput(a0),d0
	btst	#pb_ahi,d0
	beq.b	.naa
	tst.b	ahi_use_nyt(a5)
	bne.b	.na
.naa

	bsr.w	createport
	bsr.w	createio

	lea	iorequest(a5),a1
	lea	.adname(pc),a0
	moveq	#0,d0
	moveq	#0,d1
	moveq	#100,d7
	tst.b	nastyaudio(a5)
	beq.b	.nona
	moveq	#127,d7
.nona	move.b	d7,LN_PRI(a1)
	lea	.allocmap(pc),a2
	move.l	a2,ioa_Data(a1)
* d2 = kanavalistan pituus
	moveq	#1,d2			* vain yksi vaihtoehto
	move.l	d2,ioa_Length(a1)
	move.l	(a5),a6
	lob	OpenDevice
	move.l	d0,d5
	move.l	d5,acou_deviceerr(a5)
	bne.b	acouscl
	st	kanavatvarattu(a5)
	DPRINT	"Audio open"
.na	movem.l	(sp)+,d1-a6
	moveq	#0,d0
	rts

.adname		dc.b	"audio.device",0
.allocmap	dc.b	$0f
 even

acouscl
	movem.l	(sp)+,d1-a6
	bsr.b	vapauta_kanavat
	moveq	#-1,d0
	rts

vapauta_kanavat	
	tst.b	kanavatvarattu+var_b
	bne.b	.eeo
	rts
.eeo	movem.l	d0-a6,-(sp)
	lea	var_b,a5

	tst.l	acou_deviceerr(a5)
	bne.b	acouscll
	lea	iorequest(a5),a1
	lore	Exec,CloseDevice
	DPRINT	"Audio close"
acouscll
	clr.l	acou_deviceerr(a5)
	clr.b	kanavatvarattu(a5)
	movem.l	(sp)+,d0-a6
	rts

*******************************************************************************
* CIA interrupt handling
*******************************************************************************

_ciaa	=	$bfe001
_ciab	=	$bfd000


	
* init with default tempo 
init_ciaint:
	moveq	#0,d0
* init with specified tempo in d0. 0 = default
init_ciaint_withTempo:
	tst.b	ciasaatu(a5)
	bne.b	.hm
.c	moveq	#0,d0
	rts

.hm	clr.b	vbtimeruse(a5)		* k‰ytet‰‰n ciaa
	tst.b	vbtimer(a5)		* onko vblank k‰ytˆss‰?
	beq.b	.ci
	st	vbtimeruse(a5)		* k‰ytet‰‰n vblankia
	bra.b	.c
.ci
	pushm	d1-a6

	move	#28419/2,d1
	tst	d0
	beq.b	.default
	move	d0,d1
.default
	move	d1,timerhi(a5)

** CIAA

	lea	_ciaa,a3
	lea	ciaserver(pc),a4
	moveq	#0,d6			* timer a
	move.l	ciabasea(a5),d0
	beq.b	.noa
	move.l	d0,a6
	lea	(a4),a1
	move.l	d6,d0
	lob	AddICRVector
	tst.l	d0
	beq.b	.gottimer		* Saatiinko?

	lea	(a4),a1
	moveq	#1,d6			* timer b
	move.l	d6,d0
	lob	AddICRVector
	tst.l	d0
	beq.b	.gottimer
.noa
** CIAB

	lea	_ciab,a3
	lea	ciaserver(pc),a4
	moveq	#0,d6			* timer a
	move.l	ciabaseb(a5),d0
	beq.b	.nob
	move.l	d0,a6
	lea	(a4),a1
	move.l	d6,d0
	lob	AddICRVector
	tst.l	d0
	beq.b	.gottimer		* Saatiinko?

	lea	(a4),a1
	moveq	#1,d6			* timer b
	move.l	d6,d0
	lob	AddICRVector
	tst.l	d0
	beq.b	.gottimer
.nob
	popm	d1-a6
	moveq	#-1,d0			* ERROR! Ei saatu varattua timeri‰.
	rts

.gottimer
	move.l	a3,ciaddr(a5)
	move.l	a6,ciabase(a5)
	move.b	d6,whichtimer(a5)	* 0: timer a, 1:timer b

 if DEBUG
	move.l a3,d0
	moveq	#0,d1
	move.b whichtimer(a5),d1
	DPRINT	"CIA Timer allocated %lx %ld"
 endif
	bsr.b	ciaint_setTempo

	lea	ciacra(a3),a2
	tst.b	d6
	beq.b	.tima
	lea	ciacrb(a3),a2
.tima
	clr.b	ciasaatu(a5)		* saatiin keskeytys

	move.b	#%00010001,(a2)		* Continuous, force load
	popm	d1-a6
	moveq	#0,d0
	rts


* Sets tempo value word from timerhi(a5) into currently
* active CIA timer.
* May be called from interrupt.
ciaint_setTempo
	pushm	a2/a3/a5
	lea		var_b,a5
	move.l 	ciaddr(a5),a3
	lea	ciatalo(a3),a2
	tst.b	whichtimer(a5)
	beq.b	.timera
	lea	ciatblo(a3),a2
.timera	
	move.b	timerlo(a5),(a2)
	move.b	timerhi(a5),$100(a2)
; Probaly not good idea to debug print here,
; can be called from interrupt (in case of DeliCustom).
	popm	a2/a3/a5
	rts

ciaint_setTempoFromD0
	move	d0,timerhi+var_b
	bra.b	ciaint_setTempo


rem_ciaint
	tst.b	ciasaatu(a5)
	beq.b	.hm
	rts

.hm	pushm	all
	move.l	ciaddr(a5),a3

	moveq	#0,d0
	move.b	whichtimer(a5),d0	* RemICRVector
	bne.b	.b
	move.b	#%00000000,ciacra(a3)
	bra.b	.a
.b	move.b	#%00000000,ciacrb(a3)
.a
	move.l	ciabase(a5),a6
	lea	ciaserver(pc),a1
	lob	RemICRVector
	st	ciasaatu(a5)		* ei keskeytyst‰!
	DPRINT	"CIA Timer freed"
	popm	all
	rts


*******************************************************************************
*                                Soittorutiinit
*******************************************************************************

**********************************************
* Varaa muistia ja purkaa soittorutiinin
* a0 = osoitin paikkaan mihin laitetaan osoite

allocreplayer2
	pushm	d1-a6
	DPRINT	"Alloc replayer to chip"
	moveq	#MEMF_CHIP,d6
	bra.b	are

allocreplayer
	pushm	d1-a6
	DPRINT	"Alloc replayer to public mem"
	moveq	#MEMF_PUBLIC,d6
are	

	tst.l	(a0)			* onko jo ennest‰‰n?
	bne.w	.alreadyHaveIt

	jsr	setMainWindowWaitPointer

;	push 	a0
;	bsr.w	inforivit_group2
;	pop 	a0

	cmp.b	#GROUPMODE_LOAD_SINGLE,groupmode(a5)
	bne.b	.nah

** Ladataan yksi kipale replayereit‰ groupista
	bsr.w	loadreplayer
* a1 = replayeri pakattuna
* d7 = pakatun pituus
	bne.b	.contti
.xab	popm	d1-a6
	jsr	clearMainWindowWaitPointer
	moveq	#ier_grouperror,d0
	rts

.nah
	move	playertype(a5),d0

	* map player type into a position in the group header
	* table
	move.l	externalplayers(a5),a4
	addq	#8,a4			* skip header

.find
	tst	(a4) 			* end reached?
	beq.b 	.xab
	cmp	(a4),d0 
	beq.b	.found 
	lea	2+4+4(a4),a4
	bra.b	.find
.found
	movem.l 2(a4),d0/d7		* offset, length

	* get actual data address, relative to start
	move.l	externalplayers(a5),a1
	add.l	d0,a1
.contti
	move.l	a1,a4
	move.l	a0,a3
	cmp.l	#"IMP!",(a4)
	beq.b	.imp
	moveq	#1,d5		* type flag
	jsr	getDeshrinkledSize
	bra.b	.noImp
.imp
	moveq	#0,d5		* type flag
	move.l	4(a4),d0	* fimp decompressed size
.noImp
	* d0 = decompressed size
	move.l	d6,d1		* mem type
	jsr	getmem
	move.l	d0,(a3)		* store pointer
	bne.b	.ok2
	popm	d1-a6
	jsr	clearMainWindowWaitPointer
	moveq	#ier_nomem,d0
	rts

.ok2	
	move.l	d0,a1

	* a4 = compressed data
	* a1 = output buffer
	tst	d5
	bne.b	.shr

	move.l	a4,a0
	move.l	d7,d0
	lore	Exec,CopyMem	
	move.l	(a3),a0
	DPRINT	"Exploding"
	jsr	fimp_decr
	bra.b	.wasImp
.shr
	DPRINT	"Deshrinklering"
	jsr	deshrinkle
	
.wasImp
	cmp	#pt_eagle_start,playertype(a5)
	bhs.b 	.ok 
	
	* see if it needs to be relocated
	move.l	(a3),a0
	cmp.l	#$000003f3,(a0)
	bne.b	.ok
	DPRINT	"Relocating"
	bsr.b	reloc
.ok
	bsr.b	clearCpuCaches

 
.x	popm	d1-a6
	jsr	clearMainWindowWaitPointer
	moveq	#0,d0	
	rts

.alreadyHaveIt
	bra.b	.x

* Clear CPU caches
* Use after code has been modified.
* Can be called from deli support code.
clearCpuCaches
	pushm	all
	lea	var_b,a5
	move.l	(a5),a6
	cmp	#37,LIB_VERSION(a6)
	blo.b	.vanha
	lob	CacheClearU	* cachet tyhjix, ei gurua 68040:ll‰!
.vanha
	popm 	all
	rts

**
* Reloc rutiini ilmeisesti pelk‰lle ajettavalle code_hunkille
**
* a0 = hunkki
reloc	pushm	d0-d2/a0/a1
	lea	28(a0),a0		* Address of CODE hunk length in long words
	move.l	(a0)+,d2	* Read it
	lsl.l	#2,d2		* Convert to bytes
	move.l	a0,a1		* a0 = start of the actual code
	move.l	a0,d1		* also in d1 
	lea	4(a0,d2.l),a0	* skip over to HUNK_RELOC32 start + 4
						* skip over the hunk id, that is
	move.l	(a0)+,d2	* Number of offsets to handle
	subq.l	#1,d2
	bmi.b	.024c
	addq.w	#4,a0		* Skip over the target hunk number, assume we know it
.0242	move.l	(a0)+,d0 * read RELOC32 offset
	* Add start address of the code hunk to the 
	* address specified by the reloc offset
	add.l	d1,(a1,d0.l)
	dbf	d2,.0242
.024c	addq.w	#8,a0	* a0 points to next hunk likely
	popm	d0-d2/a0/a1
	rts	



***********************************
* Vapauttaa soittorutiinin muistista
* a0 = osoitin soittorutiinin osoittimeen
freereplayer
	tst.l	(a0)
	beq.b	.x
	push	a0
	move.l	(a0),a0
	jsr	freemem
	pop	a0
	clr.l	(a0)
.x
	cmp.b	#GROUPMODE_DISABLE,groupmode(a5)	* jos playerfile disabloitu,
	blo.b	.xx			* vapautetaan se ejectin yhteydess‰
					* tai load single moodina
	move.l	externalplayers(a5),a0		
	clr.l	externalplayers(a5)
	jsr	freemem
.xx	rts

*************
* Tarkistaa onko moduuli fastissa. Jos on, siirt‰‰ sen chippiin

moveModuleToChipMem
siirra_moduuli
	pushm	d1-a6

	move.l	moduleaddress(a5),a3

	move.l	a3,a1
	lore	Exec,TypeOfMem
	btst	#MEMB_CHIP,d0
	bne.b	sirchip

	moveq	#MEMF_CHIP,d1
sirmo	move.l	modulelength(a5),d0
	lob	AllocMem
	tst.l	d0
	beq.b	sirerro
	move.l	d0,moduleaddress(a5)

	move.l	a3,a0
	move.l	d0,a1
	move.l	modulelength(a5),d0
	lob	CopyMem

	move.l	a3,a1
	move.l	modulelength(a5),d0
	lob	FreeMem

sirchip	moveq	#0,d0
sirx	popm	d1-a6
	rts

sirerro	moveq	#ier_nomem,d0
	bra.b	sirx


*************
* Tarkistaa onko moduuli chipiss‰. Jos on, siirt‰‰ sen fastiin (jos on).

moveModuleToPublicMem
siirra_moduuli2
	pushm	d1-a6

	move.l	moduleaddress(a5),a3

	move.l	a3,a1
	lore	Exec,TypeOfMem
	btst	#MEMB_FAST,d0
	bne.b	sirx

	moveq	#MEMF_FAST,d1
	bra.b	sirmo
	
;	move.l	modulelength(a5),d0
;	lob	AllocMem
;	tst.l	d0
;	beq.b	.x

;	move.l	d0,moduleaddress(a5)

;	move.l	a3,a0
;	move.l	d0,a1
;	move.l	modulelength(a5),d0
;	lob	CopyMem

;	move.l	a3,a1
;	move.l	modulelength(a5),d0
;	lob	FreeMem

;.fast	moveq	#0,d0
;.x	popm	d1-a6
;	rts

	

*************

dmawait
	pushm	d0/d1
	moveq	#12-1,d1
.d	move.b	$dff006,d0
.k	cmp.b	$dff006,d0
	beq.b	.k
	dbf	d1,.d
	popm	d0/d1
	rts

;	pushm	d0/a0
;	moveq	#8-1,d0
;	lea.l	$bfe001,a0
;.e 	rept	23
;	tst.b	(a0)
;	endr
;	dbf	d0,.e
;	popm	d0/a0
;	rts


clearsound
	pushm	d0/a0
	lea	$dff096,a0
	move	#$f,(a0)
	moveq	#0,d0
	move	d0,$a8-$96(a0)
	move	d0,$b8-$96(a0)
	move	d0,$c8-$96(a0)
	move	d0,$d8-$96(a0)
	popm	d0/a0
	rts


******************************************************************************
* Music formats
******************************************************************************

* Formats
* - built-in replayers in hippo
* - replayer code is within modules
* - replayer code is in libraries
* - TFMX and ProTracker have special handling 
internalFormats
	;dr.w	p_protracker 
	dr.w	p_med 
	dr.w 	p_mline 
	dr.w 	p_musicassembler 
	dr.w 	p_fred 
	dr.w	p_sidmon1 
	dr.w 	p_deltamusic 
	dr.w	p_markii 
	dr.w 	p_mon
	dr.w 	p_beathoven 
	dr.w	p_hippel	* very slow id 
	dc.w 	0

* Formats
* - replayers are in the HippoPlayer.group
groupFormats
	dr.w 	p_jamcracker 
	dr.w 	p_pumatracker 
	dr.w 	p_futurecomposer13
	dr.w 	p_futurecomposer14 
	dr.w 	p_oktalyzer
	;dr.w	p_tfmx
	dr.w	p_hippelcoso 
	dr.w	p_soundmon 
	dr.w	p_soundmon3 
	dr.w	p_digibooster 
	dr.w 	p_digiboosterpro 
	dr.w	p_thx 
	dr.w 	p_aon 
	dr.w	p_gamemusiccreator 
	dr.w	p_medley 
	dr.w	p_bendaglish 
	dr.w	p_sidmon2 
	dr.w	p_deltamusic1 
	dr.w	p_soundfx 
	dr.w	p_gluemon
	dr.w	p_pretracker 
	dr.w 	p_custommade 
	dr.w 	p_sonicarranger
	dr.w	p_startrekker
	dr.w	p_voodoosupremesynthesizer
 ifne FEATURE_P61A
	dr.w 	p_player
 endif
 	dr.w 	p_aon8
	dc.w 	0


* Formats
* - replayers provided in eagleplayer plugins
eagleFormats
	dr.w	p_synthesis
	dr.w	p_syntracker
	dr.w	p_robhubbard2
	dr.w	p_chiptracker
	dr.w	p_quartet
	dr.w	p_facethemusic
	dr.w	p_richardjoseph
	dr.w	p_instereo1 
	dr.w	p_instereo2
	dr.w	p_jasonbrooke
	dr.w	p_earache
	dr.w	p_krishatlelid
	dr.w	p_richardjoseph2
	dr.w	p_hippel7
	dr.w	p_aprosys
	dr.w	p_hippelst
	dr.w	p_tcbtracker
	dr.w	p_markcooksey 
	dr.w	p_maxtrax
	dr.w	p_wallybeben
	dr.w	p_synthpack
	dr.w	p_robhubbard 
	dr.w 	p_jeroentel
	dr.w	p_sonix
	dr.w	p_quartetst 
	; Hangs on privileged instruction?
	;dr.w	p_coredesign
	dr.w	p_digitalmugician2
	dr.w	p_musicmaker4
	dr.w	p_musicmaker8
	dr.w	p_soundcontrol
	dr.w	p_stonetracker
	dr.w	p_themusicalenlightenment
	dr.w	p_timfollin2
	dr.w	p_digitalmugician
	dr.w 	p_jasonpage
	dr.w	p_specialfx
	dr.w	p_steveturner
	dr.w 	p_davidwhittaker
	dr.w	p_activisionpro  	* very slow id
	dc.w 	0	

******************************************************************************
* Protracker
******************************************************************************

p_protracker
	jmp	.proinit(pc)
	p_NOP
	jmp	.provb(pc)
	jmp	.proend(pc)
	jmp	.prostop(pc)
	jmp	.procont(pc)
	jmp	.provolume(pc)
	jmp	.prosong(pc)		* Song
	jmp	.eteen(pc)
	jmp	.taakse(pc)
	p_NOP
	jmp id_protracker(pc)
	p_NOP
	dc.w pt_prot 				* type
.flags	
 dc pf_cont!pf_stop!pf_volume!pf_song!pf_kelaus!pf_poslen!pf_end!pf_scope!pf_ciakelaus2!pf_quadscopePoke

	dc.b	"Protracker",0
 even


.proinit
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	movem.l	d1-d2/a0/a1,-(sp)

	move.l	moduleaddress(a5),a0	* Onko konvertattu?

	tst.b	950(a0)			* song len v‰h. 1
	bne.b	.ce
	move.b	#1,950(a0)
.ce
	cmp.b	#"K",951(a0)
	beq.b	.c
	move	#950/2-1,d0
	lea	ptheader,a1
.cl	move	(a0)+,(a1)+
	dbf	d0,.cl
.c


	bsr.w	.getsongs
	bsr.w	whatgadgets

	lea	kplbase(a5),a0
	move.l	moduleaddress(a5),a1

	moveq	#0,d0
	move.b	950(a1),d0
	move	d0,pos_maksimi(a5)

	bsr.b	.init

	cmp	#-1,d0
	beq.b	.eok
	cmp	#-2,d0
	beq.b	.eok3
	bsr.w	.provolume
	moveq	#0,d0
.eok2	movem.l	(sp)+,d1-d2/a0/a1
	rts

.eok	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	bra.b	.eok2
.eok3	bsr.w	vapauta_kanavat
	moveq	#ier_nomem,d0
	bra.b	.eok2


.init
	moveq	#0,d0
.init1
	moveq	#1,d1			* cia
	move.b	vbtimer(a5),vbtimeruse(a5)
	beq.b	.cuse
	moveq	#0,d1			* vb
.cuse

	moveq	#0,d2

	tst.b	oldst(a5)		* onko old st?
	bne.b	.s
	tst.b	tempoflag(a5)
	bne.b	.s
	bset	#0,d2			* tempo flag
.s	
	movem.l	d0/d1/a0/a1/a6,-(sp)	* oobko modi tosiaan fastissa?
	move.l	moduleaddress(a5),a1
	lore	Exec,TypeOfMem
	btst	#MEMB_CHIP,d0	
	movem.l	(sp)+,d0/d1/a0/a1/a6
	bne.b	.ss
	bset	#1,d2			* fast flag
.ss
	lea	kplbase(a5),a0
	jmp	kplayer+kp_init
	

.proend	move.l	d0,-(sp)
	jsr	kplayer+kp_end
	move.l	(sp)+,d0
	bra.w	vapauta_kanavat

.prostop
	move.l	d0,-(Sp)
	moveq	#1,d0
	jsr	kplayer+kp_playstop
	jsr	kplayer+kp_clear
	move.l	(sp)+,d0
	rts

.procont
	move.l	d0,-(Sp)
	moveq	#0,d0
 	jsr	kplayer+kp_playstop
	move.l	(sp)+,d0
	rts	

.provolume
	move.l	d0,-(sp)
	move	mainvolume(a5),d0
	jsr	kplayer+kp_setmaster
	move.l	(sp)+,d0
	rts

* ei soittoa, tutkitaan vain onko kappale loppunut
.provb
	tst.b	vbtimeruse(a5)
	beq.b	.cus
	jsr	kplayer+kp_music
.cus
	move	kplbase+k_songpos(a5),pos_nykyinen(a5)
	tst.b	kplbase+k_songover(a5)
	sne	songover(a5)
	clr.b	kplbase+k_songover(a5)
	rts

.eteen
	movem.l	d0/d1/a0,-(sp)
	move.l	moduleaddress(a5),a0
	moveq	#0,d0
	move.b	950(a0),d0		* songlength
	move	kplbase+k_songpos(a5),d1
	addq	#1,d1
	cmp	d0,d1
	blo.b	.a
	clr	d1
.a	move	d1,kplbase+k_songpos(a5)
	clr	kplbase+k_patternpos(a5)
	move	d1,pos_nykyinen(a5)
	movem.l	(sp)+,d0/d1/a0
	rts
.taakse
	move.l	d0,-(sp)
	move	kplbase+k_songpos(a5),d0
	subq	#1,d0
	bpl.b	.b
	clr	d0
.b	move	d0,kplbase+k_songpos(a5)
	clr	kplbase+k_patternpos(a5)
	move	d0,pos_nykyinen(a5)
	move.l	(sp)+,d0
.yee	rts


* Tutkii koko songin, ja kattoo jos olisi erillisi‰ songeja.
.getsongs
	move.l	moduleaddress(a5),a0
	cmp.b	#'K',951(a0)
	beq.b	.yee

	clr.l	kokonaisaika(a5)
	cmp	#3,lootamoodi(a5)
	bne.b	.la
	pushm	d2-a6
	move.l	moduleaddress(a5),a0
	move.b	tempoflag(a5),d0
	not.b	d0
	bsr.w	modlen		* moduulin kesto ajallisesti
	popm	d2-a6
	move	d0,kokonaisaika(a5)	* mins
	move	d1,kokonaisaika+2(a5)	* secs
.la

	move.l	a6,-(sp)

	move	#$0fff,d3
	moveq	#0,d0
	move.b	950(a0),d0		* songlength
	move	d0,a6
	subq	#1,d0
	moveq	#0,d1
	lea	1084(a0),a2		* eka patterni
	lea	952(a0),a3		* position-lista

	lea	ptsonglist(a5),a4
	moveq	#64-1,d2
.cc	move.b	#$ff,(a4)+
	dbf	d2,.cc
	lea	ptsonglist(a5),a4
	clr.b	(a4)+

.check
	moveq	#0,d2
	move.b	(a3)+,d2
	lsl.l	#5,d2			* d2*1024
	lsl.l	#5,d2	
	lea	(a2,d2.l),a1

************************ OPT

	moveq	#1024/4/4-1,d2
.look	
	movem.l	(a1)+,d4-d7
	and	d3,d4
	rol	#8,d4
	and	d3,d5
	rol	#8,d5
	and	d3,d6
	rol	#8,d6
	and	d3,d7
	rol	#8,d7

	cmp.b	#$b,d4
	beq.b	.jump1
	cmp.b	#$b,d5
	beq.b	.jump2
	cmp.b	#$b,d6
	beq.b	.jump3
	cmp.b	#$b,d7
	beq.b	.jump4
	cmp.b	#$d,d4
	beq.b	.next
	cmp.b	#$d,d5
	beq.b	.next
	cmp.b	#$d,d6
	beq.b	.next
	cmp.b	#$d,d7
	beq.b	.next

	dbf	d2,.look

.next	addq	#1,d1
	dbf	d0,.check

	move.b	#-1,(a4)
	lea	ptsonglist(a5),a0
	move.l	a0,a1
.f	cmp.b	#-1,(a0)+
	bne.b	.f
	sub.l	a1,a0
	subq	#1,a0
	move	a0,d0
	subq.b	#1,d0
	move.b	d0,maxsongs+1(a5)

	move.l	(sp)+,a6
	rts

.jump4	move	d7,d4
	bra.b	.jump
.jump3	move	d6,d4
	bra.b	.jump
.jump2	move	d5,d4
.jump1	
.jump	rol	#8,d4
	cmp.b	d1,d4
	bhs.b	.next

	moveq	#1,d4
	add.b	d1,d4

	cmp	a6,d4
	blo.b	.eoe
	moveq	#-1,d4			* Moduulin alkuun
.eoe	move.b	d4,(a4)+
	bra.b	.next


.prosong
	movem.l	d0-a1,-(Sp)

	lea	ptsonglist(a5),a0
	cmp.b	#-1,1(a0)
	beq.b	.nosong

	move	songnumber(a5),d7
	move.b	(a0,d7),d7
	bmi.b	.nosong

	jsr	kplayer+kp_end
	
	lea	kplbase(a5),a0
	move.l	moduleaddress(a5),a1
	move.l	d7,d0

	bsr.w	.init1
	bsr.w	.provolume

.nosong	movem.l	(sp)+,d0-a1
	rts




nl_note		EQU	0  ; W
nl_cmd		EQU	2  ; W
nl_cmdlo	EQU	3  ; B
nl_pattpos	EQU	4 ; B
nl_loopcount	EQU	6	 ; B
nl_ts		=	8	* channeltempsize



modlen

	basereg	modlen,a5
	lea	modlen(pc),a5

	lea	.datastart(a5),a1
	lea	.dataend(a5),a2
.lfe	clr.b	(a1)+
	cmp.l	a1,a2
	bne.b	.lfe

	MOVE.L	A0,.mt_SongDataPtr(a5)
	move.b	d0,.tempoflag(a5)

	move	#125,.Tempo(a5)
	move.b	#6,.mt_speed(a5)

;	CLR.B	.mt_counter(a5)
;	CLR.B	.mt_SongPos(a5)
;	CLR.W	.mt_PatternPos(a5)

	move.l	#1773447,d0
	divu	.Tempo(a5),d0
	move	d0,.tempoval(a5)

.loop	bsr.b	.mt_music
	tst	.songend(a5)
	beq.b	.loop

	cmp.b	#1,.songend(a5)
	bne.b	.nod
	moveq	#0,d0
	moveq	#0,d1
	rts
.nod


	move.l	.time(a5),d0
	move.l	#709379,d1	* PAL

;	move.l	(a5),a0
;	cmp.b	#60,PowerSupplyFrequency(a0)
;	bne.b	.pal
;	move.l	#715909,d1	* NTSC
;.pal
	jsr	divu_32
				* d0 = kesto sekunteina

	divu	#60,d0
	move.l	d0,d1
	swap	d1
	rts


.mt_music
	lea	modlen(pc),a5
	addq	#1,.varmistus(a5)
;	cmp	#512,.varmistus(a5)
;	cmp	#2048,.varmistus(a5)
	cmp	#4096,.varmistus(a5)
	blo.b	.noy
	clr	.mt_PatternPos(a5)
	CLR.B	.mt_PBreakPos(a5)
	CLR.B	.mt_PosJumpFlag(a5)
	clr.b	.mt_PattDelTime(a5)
	clr.b	.mt_PattDelTime2(a5)
	clr.b	.mt_counter(a5)
	move	#1024,.mt_PatternPos(a5)
	bra.b	.mt_GetNewNote
.noy

	moveq	#0,d0
	move	.tempoval(a5),d0
	add.l	d0,.time(a5)

	ADDQ.B	#1,.mt_counter(a5)
	MOVE.B	.mt_counter(a5),D0
	CMP.B	.mt_speed(a5),D0
	BLO.S	.mt_NoNewNote
	CLR.B	.mt_counter(a5)
	TST.B	.mt_PattDelTime2(a5)
	BEQ.S	.mt_GetNewNote
	BSR.S	.mt_NoNewAllChannels
	BRA.B	.mt_dskip

.mt_NoNewNote
	pea	.mt_NoNewPosYet(a5)

.mt_NoNewAllChannels
	LEA	.mt_chan1temp(a5),A6
	BSR.B	.mt_CheckEfx
	addq	#nl_ts,a6
	BSR.B	.mt_CheckEfx
	addq	#nl_ts,a6
	BSR.B	.mt_CheckEfx
	addq	#nl_ts,a6

.mt_CheckEfx
	moveq	#$f,d0
	and.b	nl_cmd(A6),D0
	CMP.B	#$E,D0
	BEQ.W	.mt_E_Commands
.mt_Return
	RTS


.mt_GetNewNote

	MOVE.L	.mt_SongDataPtr(a5),A0
	LEA	12(A0),A3
	LEA	952(A0),A2	;pattpo
	LEA	1084(A0),A0	;patterndata
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	mOVE.B	.mt_SongPos(a5),D0
	MOVE.B	(A2,D0.W),D1
	ASL.L	#8,D1
	ASL.L	#2,D1
	ADD.W	.mt_PatternPos(a5),D1

	LEA	.mt_chan1temp(a5),A6
	BSR.S	.mt_PlayVoice
	addq	#nl_ts,a6
	BSR.S	.mt_PlayVoice
	addq	#nl_ts,a6
	BSR.S	.mt_PlayVoice
	addq	#nl_ts,a6
	pea	.mt_SetDMA(pc)

;	BSR.S	.mt_PlayVoice
;	BRA.B	.mt_SetDMA


.mt_PlayVoice
	MOVE.L	(A0,D1.L),(A6)
	ADDQ.L	#4,D1
	Bra.w	.mt_CheckMoreEfx


.mt_SetDMA
.mt_dskip
	tst.b	.songend(a5)
	bne.w	.mt_exit

	ADD.W	#16,.mt_PatternPos(a5)
	MOVE.B	.mt_PattDelTime(a5),D0
	BEQ.S	.mt_dskc
	MOVE.B	D0,.mt_PattDelTime2(a5)
	CLR.B	.mt_PattDelTime(a5)
.mt_dskc	TST.B	.mt_PattDelTime2(a5)
	BEQ.S	.mt_dska
	SUBQ.B	#1,.mt_PattDelTime2(a5)
	BEQ.S	.mt_dska
	SUB.W	#16,.mt_PatternPos(a5)
.mt_dska	TST.B	.mt_PBreakFlag(a5)
	BEQ.S	.mt_nnpysk
	SF	.mt_PBreakFlag(a5)
	MOVEQ	#0,D0
	MOVE.B	.mt_PBreakPos(a5),D0
	CLR.B	.mt_PBreakPos(a5)
	LSL.W	#4,D0
	MOVE.W	D0,.mt_PatternPos(a5)
.mt_nnpysk
	CMP.W	#1024,.mt_PatternPos(a5)
	BLO.S	.mt_NoNewPosYet
.mt_NextPosition	
	clr	.varmistus(a5)

	MOVEQ	#0,D0
	MOVE.B	.mt_PBreakPos(a5),D0
	LSL.W	#4,D0
	MOVE.W	D0,.mt_PatternPos(a5)
	CLR.B	.mt_PBreakPos(a5)
	CLR.B	.mt_PosJumpFlag(a5)
	ADDQ.B	#1,.mt_SongPos(a5)
	bpl.b	.jo
	st	.songend(a5)
.jo
	AND.B	#$7F,.mt_SongPos(a5)
	MOVE.B	.mt_SongPos(a5),D1

	MOVE.L	.mt_SongDataPtr(a5),A0
	CMP.B	950(A0),D1
	BLO.S	.mt_NoNewPosYet
	CLR.B	.mt_SongPos(a5)
	st	.songend(a5)

.mt_NoNewPosYet	
	TST.B	.mt_PosJumpFlag(a5)
	BNE.S	.mt_NextPosition
.mt_exit	
	RTS



.mt_PositionJump
	push	d1
	MOVE.B	.mt_SongPos(a5),D1		* hyv‰ksyt‰‰n jos jumppi
	addq.b	#1,d1				* viimeisess‰ patternissa
	MOVE.L	.mt_SongDataPtr(a5),a0
	cmp.b	950(a0),d1
	bne.b	.nre
	st	.songend(a5)
	pop	d1
	bra.b	.fine

.nre	pop	d1
	move.b	#1,.songend(a5)

.fine
	SUBQ.B	#1,D0
	MOVE.B	D0,.mt_SongPos(a5)

.mt_pj2	CLR.B	.mt_PBreakPos(a5)
	ST 	.mt_PosJumpFlag(a5)
	RTS


.mt_PatternBreak
	MOVEQ	#0,D0
	MOVE.B	nl_cmdlo(A6),D0
	MOVE.L	D0,D2
	LSR.B	#4,D0
	MULU	#10,D0
	AND.B	#$0F,D2
	ADD.B	D2,D0
	CMP.B	#63,D0
	BHI.S	.mt_pj2
	MOVE.B	D0,.mt_PBreakPos(a5)
	ST	.mt_PosJumpFlag(a5)
	RTS

.mt_SetSpeed
	MOVEQ	#0,D0
	MOVE.B	3(A6),D0
	Bne.b	.no0
	moveq	#31,d0
.no0
	tst	.tempoflag(a5)
	beq.b	.notempo
	CMP.B	#32,D0
	BHS.B	.SetTempo
.notempo
	CLR.B	.mt_counter(a5)
	MOVE.B	D0,.mt_speed(a5)
	RTS

.SetTempo
	move	d0,.Tempo(a5)

	move.l	#1773447,d0
	divu	.Tempo(a5),d0
	move	d0,.tempoval(a5)
	rts


.mt_CheckMoreEfx
	moveq	#$f,d0
	and.b	2(a6),d0
	CMP.B	#$B,D0
	BEQ.W	.mt_PositionJump
	CMP.B	#$D,D0
	BEQ.S	.mt_PatternBreak
	CMP.B	#$E,D0
	BEQ.S	.mt_E_Commands
	CMP.B	#$F,D0
	BEQ.S	.mt_SetSpeed
	rts

.mt_E_Commands
	MOVE.B	nl_cmdlo(A6),D0
	AND.B	#$F0,D0
	CMP.B	#$60,D0
	BEQ.B	.mt_JumpLoop
	CMP.B	#$E0,D0
	BEQ.B	.mt_PatternDelay
	RTS


.mt_JumpLoop
	TST.B	.mt_counter(a5)
	BNE.W	.mt_Return
	moveq	#$f,d0
	and.b	nl_cmdlo(A6),D0
	BEQ.S	.mt_SetLoop
	TST.B	nl_loopcount(A6)
	BEQ.S	.mt_jumpcnt
	SUBQ.B	#1,nl_loopcount(A6)
	BEQ.W	.mt_Return
.mt_jmploop	MOVE.B	nl_pattpos(A6),.mt_PBreakPos(a5)
	ST	.mt_PBreakFlag(a5)
	RTS

.mt_jumpcnt
	MOVE.B	D0,nl_loopcount(A6)
	BRA.S	.mt_jmploop

.mt_SetLoop
	MOVE.W	.mt_PatternPos(a5),D0
	LSR.W	#4,D0
	MOVE.B	D0,nl_pattpos(A6)
	RTS


.mt_PatternDelay
	TST.B	.mt_counter(a5)
	BNE.W	.mt_Return
	MOVEQ	#$f,D0
	and.b	nl_cmdlo(A6),D0
	TST.B	.mt_PattDelTime2(a5)
	BNE.W	.mt_Return
	ADDQ.B	#1,D0
	MOVE.B	D0,.mt_PattDelTime(a5)
.qq	RTS


.datastart	

.songend	dc	0
.Tempo		dc	125
.tempoval	dc	0
.tempoflag	dc	0
.time		dc.l	0

.mt_chan1temp	ds.b	8
.mt_chan2temp	ds.b	8
.mt_chan3temp	ds.b	8
.mt_chan4temp	ds.b	8
 even

.varmistus	dc	0
.mt_SongDataPtr	dc.l 0
.mt_PatternPos	dc.w 0
.mt_speed	dc.b 6
.mt_counter	dc.b 0
.mt_SongPos	dc.b 0
.mt_PBreakPos	dc.b 0
.mt_PosJumpFlag	dc.b 0
.mt_PBreakFlag	dc.b 0
.mt_PattDelTime	dc.b 0
.mt_PattDelTime2 dc.b 0
 even

.dataend

 endb	a5

* TODO: also run id_oldst 
id_protracker
	cmp.l	#'M.K.',1080(a4)	* Protracker
	beq.b	.p	
	cmp.l	#'M!K!',1080(a4)	* Protracker 100 patterns
	beq.b	.p	
;	cmp.l	#'FLT4',1080(a4)	* Startrekker
;	bra.w	idtest
	moveq	#-1,d0 
	rts
	
.p	moveq	#0,d0
	rts


*******
* Tunnistetaan Old Soundtracker piisit (15 samplea). Tarttee n. 1700 byte‰
*******
id_oldst

*** Tarkistetaan onko samplejen arvot moduulille sopivat
	lea	20(a4),a0
	moveq	#0,d0
	move	#$7fff,d2
	moveq	#15-1,d1
.l1
	cmp	22(a0),d2	* samplelen
	blo.w	.fail
	cmp	#1,22(a0)
	bhi.b	.f0
	addq	#1,d0
.f0
	cmp.b	#64,25(a0)	* volume
	bhi.w	.fail	
	cmp	26(a0),d2	* repeat point
	blo.b	.fail
	cmp	28(a0),d2	* repeat length
	blo.b	.fail
	lea	30(a0),a0
	dbf	d1,.l1
	
	cmp	#15,d0
	beq.b	.fail


* a0 = songlen
	tst.b	(a0)
	beq.b	.fail
	cmp.b	#$7f,(a0)
	bhi.b	.fail
	addq	#2,a0	

***** Ovatko postablen arvot oikeita (0-63)?

	moveq	#128-1,d0
	moveq	#0,d1
.l2	tst.b	(a0)
	beq.b	.l22
	addq	#1,d1
.l22	cmp.b	#63,(a0)+
	bhi.b	.fail
	dbf	d0,.l2

	tst	d1
	beq.b	.fail


* a0 = patterndata

*** Tarkistetaan eka patterni

	move	#4*64-1,d3
.l3
	move	(a0)+,d0
	move	(a0)+,d1

	move	d0,d2
	and	#$f000,d2		* pit‰s olla tyhj‰‰
	bne.b	.fail

	move	d1,d2			* tutkaillaan komentoa
	and	#$0f00,d2		* sallittuja: 0-4, a-f
	cmp	#$0400,d2
	bls.b	.oks
	cmp	#$0a00,d2
	blo.b	.fail

.oks

	move	d1,d2			* onko samplea?
	and	#$f000,d2
	beq.b	.noper


	and	#$fff,d0		* period
	beq.b	.noper
	cmp	#856,d0
	bhi.b	.fail
	cmp	#113,d0
	blo.b	.fail	
.noper
	dbf	d3,.l3

	moveq	#0,d0
	rts

.fail	moveq	#-1,d0
	rts

convert_oldst

*******
* Muutetaan PT-formaattiin
* a4 <= moduuli

	move.l	modulelength(a5),d0
	add.l	#484,d0
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	lore	Exec,AllocMem
	tst.l	d0
	beq.b	.fail
	move.l	d0,a3

	lea	(a4),a0
	lea	(a3),a1
	move	#470/2-1,d0
.c1	move	(a0)+,(a1)+
	dbf	d0,.c1

	lea	16*30(a1),a1		* 16 tyhj‰‰ samplee

	moveq	#(128+1+1)/2-1,d0
.c2	move	(a0)+,(a1)+
	dbf	d0,.c2
	move.l	#"M.K.",(a1)+

	move.l	a4,a2
	add.l	modulelength(a5),a2
.c3	move.b	(a0)+,(a1)+
	cmp.l	a2,a0
	bne.b	.c3

	move.b	#$7f,951(a3)

	lea	20(a3),a0		* repeat pointer jaetaan kahdella
	moveq	#$f-1,d0
.f	
	lsr	26(a0)
	lea	30(a0),a0
	dbf	d0,.f

	move.l	moduleaddress(a5),a1
	move.l	modulelength(a5),d0
	lore	Exec,FreeMem

	move.l	a3,moduleaddress(a5)
	add.l	#484,modulelength(a5)

	moveq	#0,d0			* on oikee moduuli
	rts

.fail	moveq	#-1,d0
	rts




******************************************************************************
* SID
******************************************************************************

p_sid:	jmp	.init(pc)
	p_NOP
	jmp 	sidScopeUpdate(pc)
	jmp	.end(pc)
	jmp	.stop(pc)
	jmp	.cont(pc)
	p_NOP
	jmp	.song(pc)
	jmp	.eteen(pc)
	p_NOP
	p_NOP
	jmp 	id_sid1(pc)
	p_NOP
	dc.w 	pt_sid 				* type
	dc	pf_cont!pf_stop!pf_song!pf_kelauseteen!pf_volume!pf_scope!pf_quadscopePoke
	dc.b	"PSID",0
.flag	dc.b	0
 even

.init
	bsr.w	get_sid
	bne.b	.ok
	moveq	#ier_nosid,d0
	rts

.ok
	movem.l	d1-a6,-(sp)


	move.l	_SIDBase(a5),a6

	tst.b	.flag
	bne.b	.plo

	* Enable getting data for scopes.
	* Must have patched the display signal away first.
	moveq	#1,d0
	lob	SetDisplayEnable

	lob	AllocEmulResource
	tst.l	d0
	bne.w	.error1

	move.l	moduleaddress(a5),a0
	cmp.l	#"PSID",(a0)
	bne.b	.noheader

	lea	sidheader(a5),a1
	moveq	#sidh_sizeof-1,d0
.co	move.b	(a0)+,(a1)+
	dbf	d0,.co
	bra.b	.h2

.noheader
	move.l	modulefilename(a5),a0
	lea	sidheader(a5),a1
	lob	ReadIcon	
	tst.l	d0
	bne.b	.error2

.h2
	lea	sidheader(a5),a0
	move.l	moduleaddress(a5),a1
	move.l	modulelength(a5),d0
	lob	SetModule


	lea	sidheader+sidh_name(a5),a0	* kappaleen nimi paikalleen
	moveq	#32-1,d0
	lea	modulename(a5),a1
.c	move.b	(a0)+,(a1)+
	dbeq	d0,.c

	st	.flag			* piisi initattu
	move	sidheader+sidh_number(a5),maxsongs(a5)
	subq	#1,maxsongs(a5)

	tst.b	sidflag(a5)
	bne.b	.plo
	st	sidflag(a5)
	move	sidh_defsong+sidheader(a5),songnumber(a5)
	subq	#1,songnumber(a5)
.plo

	bsr.b	.sanko
	tst.l	d0
	bne.b	.error3	

	bset	#1,$bfe001
	moveq	#0,d0
.er	movem.l	(sp)+,d1-a6
	rts


.error1
	moveq	#ier_nomem,d0
	bra.b	.er

.error2	bsr.b	.free
	moveq	#ier_sidicon,d0
	bra.b	.er

.error3
	bsr.b	.free
	moveq	#ier_sidinit,d0
	bra.b	.er


.free	lob	FreeEmulResource

	clr.b	.flag
	rts

.sanko	moveq	#0,d1
	move	songnumber(a5),d1
	addq	#1,d1
	move.l	sidh_speed+sidheader(a5),d2
	moveq	#50,d0
	btst	d1,d2
	beq.b	.ok2
	moveq	#60,d0
.ok2	lore	SID,SetVertFreq

	moveq	#0,d0
	move	songnumber(a5),d0
	addq	#1,d0
	lob	StartSong

	rts

.song	movem.l	d0/d1/a0/a1/a6,-(sp)
	bsr.b	.sanko
	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts	

.end
	movem.l	d0/d1/a0/a1/a6,-(sp)
	lore	SID,StopSong
	bsr.b	.free
	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts


.stop	movem.l	d0/d1/a0/a1/a6,-(sp)
	lore	SID,PauseSong
	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts

.cont	movem.l	d0/d1/a0/a1/a6,-(sp)
	lore	SID,ContinueSong
	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts

.eteen
	movem.l	d0/d1/a0/a1/a6,-(sp)
;	moveq	#4,d0
	moveq	#6,d0
	lore	SID,ForwardSong
	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts

*** Killeri viritys kick1.3:lle, jotta playsid.library toimisi


rem_sidpatch
	move.l	(a5),a0
	cmp	#34,LIB_VERSION(a0)
	bhi.b	.q
	move.l	_SIDBase(a5),a6
	cmp	#1,LIB_VERSION(a6)
	bne.b	.q
	cmp	#1,LIB_REVISION(a6)
	bne.b	.q
	move.l	_LVOStartSong+2(a6),a4
	move.l	12714+2(a4),a0
	move.l	12714+2+6(a4),a1
	move.l	sidlibstore2(a5),86(a0)
	move.l	sidlibstore2+4(a5),4+86(a0)
	move.l	sidlibstore1(a5),14(a1)
	move.l	sidlibstore1+4(a5),4+14(a1)
	bsr.w	clearCpuCaches
.q	
	bsr.w	sid_remVolumePatch
	rts

init_sidpatch
	move.l	(a5),a0
	cmp	#34,LIB_VERSION(a0)
	bhi.b	.q
	move.l	_SIDBase(a5),a6
	cmp	#1,LIB_VERSION(a6)
	bne.b	.q
	cmp	#1,LIB_REVISION(a6)
	bne.b	.q

	move.l	_LVOStartSong+2(a6),a4
	move.l	12714+2(a4),a0
	move.l	12714+2+6(a4),a1

* a1+14
*	move.l	4.w,a6		* ei saa tuhota
*	jsr	-$29a(a6)	* saa tuhota

* a0+86 
*	move.l	4.w,a6		* saa tuhota
*	jsr	-$2a0(a6)	* saa tuhota

	move.l	14(a1),sidlibstore1(a5)
	move.l	4+14(a1),sidlibstore1+4(a5)
	move.l	86(a0),sidlibstore2(a5)
	move.l	4+86(a0),sidlibstore2+4(a5)

	move.l	.sidp1(pc),14(a1)
	move.l	.sidp1+4(pc),4+14(a1)
	move.l	.sidp2(pc),86(a0)
	move.l	.sidp2+4(pc),4+86(a0)
	bsr.w	clearCpuCaches
.q
	bsr.w	sid_addVolumePatch
	rts

.sidp1	
	dc.w	$4eb9 ; jsr
	dc.l	.sidpatch1
	nop
.sidp2
	dc.w	$4eb9 ; jsr
	dc.l	.sidpatch1
	nop

.sidpatch1
	move.l	4.w,a6

* -$29a	CreateMsgPort
.LB_090C MOVEQ	#$22,D0
 	MOVE.L	#$00010001,D1
	JSR	-$00C6(A6)
	MOVE.L	D0,-(A7)
	BEQ.B	.LB_094A
	MOVEQ	#-$01,D0
	JSR	-$014A(A6)
	MOVE.L	(A7),A0
	MOVE.B	#$04,$0008(A0)
;	MOVE.B	#$00,$000E(A0)
	clr.b	$e(a0)
	MOVE.B	D0,$000F(A0)
	BMI.B	.LB_094E
	MOVE.L	$0114(A6),$0010(A0)
	LEA	$0014(A0),A1
	MOVE.L	A1,$0008(A1)
	ADDQ.L	#4,A1
	CLR.L	(A1)
	MOVE.L	A1,-(A1)
.LB_094A MOVE.L	(A7)+,D0
	RTS	
.LB_094E MOVEQ	#$22,D0
	MOVE.L	A0,A1
	JSR	-$00D2(A6)
	CLR.L	(A7)
	BRA.B	.LB_094A


.sidpatch2
	move.l	4.w,a6

* -$2a0	DeleteMsgPort
.LB_095A mOVE.L	A0,-(A7)
	BEQ.B	.LB_0978
	MOVEQ	#$00,D0
	MOVE.B	$000F(A0),D0
	JSR	-$0150(A6)
	MOVE.L	(A7),A1
	MOVEQ	#-$01,D0
	MOVE.L	D0,$0014(A1)
	MOVE.L	D0,(A1)
	MOVEQ	#$22,D0
	JSR	-$00D2(A6)
.LB_0978 ADDQ.L	#4,A7
	RTS	



; AllocEmulResource funkkarin osoitteesta:
; 8418: move d0,$dff0a8
;  +12: move d0,$dff0b8
;  +12: move d0,$dff0c8

sid_addVolumePatch
	move.l	_SIDBase(a5),a0
	cmp #1,LIB_VERSION(a0)
	bne.b	.q
	cmp	#1,LIB_REVISION(a0)
	bne.b	.q
	lea	_LVOAllocEmulResource(a0),a0
	move.l	2(a0),a0
	
	move	#$4eb9,8418(a0) ; jsr
	pushpea .setVol1(pc),8418+2(a0)
	move	#$4eb9,12+8418(a0)
	pushpea .setVol2(pc),12+8418+2(a0)
	move	#$4eb9,12+12+8418(a0)
	pushpea .setVol3(pc),12+12+8418+2(a0)
	* Disable DisplaySignal mechanism,
	* alternatively could SetDisplaySignal
	* so that when display is enabled there will be no
	* crashhhhhh.
	move	#$4e75,1136(a0) ; rts
	bsr.w	clearCpuCaches
.q
	rts

.setVol1
	push	d0
	mulu	var_b+mainvolume,d0 
	lsr	#6,d0
	move	d0,$dff0a8
	pop 	d0
	rts
.setVol2
	push	d0
	mulu	var_b+mainvolume,d0 
	lsr	#6,d0
	move	d0,$dff0b8
	pop 	d0
	rts
.setVol3
	push	d0
	mulu	var_b+mainvolume,d0 
	lsr	#6,d0
	move	d0,$dff0c8
	pop 	d0
	rts

;.setVol4
;	push	d0
;	mulu	var_b+mainvolume,d0 
;	lsr	#6,d0
;	move	d0,$dff0d8
;	pop 	d0
;	rts


sid_remVolumePatch
	move.l	_SIDBase(a5),a0
	cmp #1,LIB_VERSION(a0)
	bne.b	.q
	cmp	#1,LIB_REVISION(a0)
	bne.b	.q
	lea	_LVOAllocEmulResource(a0),a0
	move.l	2(a0),a0
	move	.vol1orig(pc),8418(a0)
	move.l	.vol1orig+2(pc),8418+2(a0)
	move	.vol2orig(pc),12+8418(a0)
	move.l	.vol2orig+2(pc),12+8418+2(a0)
	move	.vol3orig(pc),12+12+8418(a0)
	move.l	.vol3orig+2(pc),12+12+8418+2(a0)
	bsr.w	clearCpuCaches
.q
	rts

.vol1orig	move	d0,$dff0a8
.vol2orig	move	d0,$dff0b8
.vol3orig	move	d0,$dff0c8


*******
* Tunnistetaan SID piisit
*******

id_sid1 
	bsr.b	id_sid1_
	bne.b 	.no
	bsr.w	moveModuleToPublicMem		* siirret‰‰n fastiin jos mahdollista
	moveq	#0,d0 
.no 
	rts


id_sid1_
	cmp.l	#"PSID",(a4)
	beq.b	.q
	moveq	#-1,d0
	rts
.q	moveq	#0,d0
	rts

id_sid
	bsr.b	id_sid1
	beq.w	.yea

	move.l	modulefilename(a5),a0
	lea	desbuf(a5),a1
	move.l	a1,a2
.c	move.b	(a0)+,(a1)+
	bne.b	.c
	subq.l	#1,a1
	move.b	#'.',(a1)+
	move.b	#'i',(a1)+
	move.b	#'n',(a1)+
	move.b	#'f',(a1)+
	move.b	#'o',(a1)+
	clr.b	(a1)

	move.l	a2,d1			* avataan_ikoni
	move.l	#1005,d2
	lore	Dos,Open
	move.l	d0,d5
	beq.b	.no

	lea	probebuffer(a5),a0	* luetaan ikoni
	move.l	a0,d2
	move.l	#1000,d3			* 1000 bytee
	move.l	d5,d1
	lob	Read
	move.l	d5,d1
	lob	Close

* tutkitaan onko playsidin ikoni.

	lea	probebuffer(a5),a0
	move	#1000,d2

.leep	lea	.id1(pc),a1
.luup	move.b	(a1)+,d1
	beq.b	.yea
	move.b	(a0)+,d0
	subq	#1,d2
	beq.b	.no
	btst	#5,d1
	beq.b	.cl
	bset	#5,d0
	bra.b	.cll
.cl	bclr	#5,d0
.cll	cmp.b	d1,d0
	bne.b	.leep
	bra.b	.luup

.no	moveq	#-1,d0
	rts
.yea	moveq	#0,d0
	rts

.id1	dc.b	"PLAYSID",0
.ide1
 even

* Scope data update and following
* This is emulates what the PlaySid pplication does.
sidScopeUpdate
	* Skip this if not needed
	bsr.w	anyScopeRunning
	beq.w	.x

	lea	scopeData+scope_ch1(a5),a0
	moveq	#0,d7
	move.l	_SIDBase(a5),a1
	* DisplayData:
	move.l	50(a1),a1
	lea	.followPositions(pc),a3
	lea	.followFractions(pc),a2
	moveq	#0,d4
.loop
	* WORD index d7
	moveq	#0,d1
	move	dd_Length1(a1,d7),d1
	move	dd_Period1(a1,d7),d2 
	move	dd_Enve1(a1,d7),d3

	move	d2,ns_period(a0)
	move	d3,ns_tempvol(a0)
	move	d1,d6
	* Elsewhere these are handled as words
	lsr	#1,d6
	move	d6,ns_length(a0)
	move	d6,ns_replen(a0)

	* APTR index d6
	move	d7,d6
	add	d6,d6
	* Set initial sample position
	move.l	dd_Sample1(a1,d6),d6
	move.l	d6,ns_start(a0)
	move.l	d6,ns_loopstart(a0)
	
.MIN_PERIOD = 123

	cmp	#.MIN_PERIOD,d2
	bhs.b	.notEmpty
	clr	ns_tempvol(a0)
	bra.b	.skip
.notEmpty
	move.l	#.MIN_PERIOD<<16,d5
	divu	d2,d5 * dd_Period1
	* d5 = fractional 16-bit step
	* Get follow position
	move.w	(a3,d7.w),d2
	* This many steps per frame
	moveq	#$40-1,d0
.step
	* Update fractions
	add.w	d5,(a2,d7.w)
	* Add bytes if enough fractions
	addx.w	d4,d2
.retry
	* Check if stepped over the end
	cmp.w	d1,d2
	blt.s	.ok
	sub.w	d1,d2
	bra.s	.retry
.ok
	dbf	d0,.step
	
	* Updated byte position
	move.w	d2,(a3,d7.w)

	* Set final sample position and length
	* for scopes
	ext.l	d2
	add.l	d2,ns_start(a0)
	lsr	#1,d2 * words
	sub	d2,ns_length(a0)
	
.skip
	lea	ns_size(a0),a0
	addq	#2,d7
	cmp	#4*2,d7
	bne.b	.loop
.x	rts

.followPositions
	ds.w	4
.followFractions
	ds.w	4

* T‰nne v‰liin h‰m‰‰v‰sti

*******************************************************************************
* Tarkistaa keyfilen. Muuttaa rekisterˆij‰n nimen tekstiksi ja palauttaa
* keycheck(a5):ss‰ nollan, jos aito.
*******

check_keyfile
	tst.b	keyfilechecked(a5)
	beq.b	.not
	rts
.not	st	keyfilechecked(a5)

	lea	keyfile(a5),a4
	move.l	56(a4),d0
	swap	d0
	lsr.l	#1,d0
	divu	#1005,d0
	moveq	#0,d4

	move.l	a4,a0
	moveq	#38-1,d2
	moveq	#0,d1
.k	sub.b	(a0)+,d1
	dbf	d2,.k

	sub.l	d1,d0
	add.b	d0,d4

	move.l	a4,a0
	move	30(a0),d0		* %111
	lsr	#1,d0

	moveq	#0,d1			* %111
	move	34(a0),d1
	move	d1,d2
	subq.b	#1,d1
	lsl	#3,d1
	or.l	d1,d0

	moveq	#0,d1			* %11111
	move.b	32(a0),d1
	sub	d2,d1
	lsl.l	#6,d1
	or.l	d1,d0

	moveq	#0,d1
	move.b	36(a0),d1
	lsl.l	#8,d1
	lsl.l	#2,d1
	or.l	d1,d0

	clr.b	36(a0)
	clr.b	32(a0)
	clr	34(a0)
	clr	30(a0)

	move.l	a4,a0
	moveq	#32-1,d3
	moveq	#0,d2
.cle	moveq	#0,d1
	move.b	(a0)+,d1
	add	d1,d2
	dbf	d3,.cle

	sub.l	d2,d0
	add.b	d0,d4

	bra.b	.l
.ll	move.b	-2(a4),d0
	sub.b	d0,-1(a4)
.l	tst.b	(a4)+
	bne.b	.ll

	or.b	d4,keycheck(a5)
	bne.b	.hot

	lea	wreg1,a0
	clr.b	(a0)
	clr.b	wreg2-wreg1(a0)
	clr.b	wreg3-wreg1(a0)
.hot	rts	




******************************************************************************
* Delta music
******************************************************************************
p_deltamusic
	jmp	.deltainit(pc)
	jmp	.deltaplay(pc)
	p_NOP
	jmp	.deltaend(pc)
	jmp	.deltastop(pc)
	p_NOP
	jmp	.deltavolume(pc)
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp .id_deltamusic(pc)
	jmp	.author(pc)
	dc.w pt_delta2 				* type
	dc	pf_cont!pf_stop!pf_volume!pf_ciakelaus
	dc.b	"Delta Music 2",0
.a	dc.b	"Bent Nielsen",0
 even

.author
	pushpea	.a(pc),d0
	rts

.deltainit
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	movem.l	d0-a6,-(sp)
	moveq	#1,d0
.delt	move.l	moduleaddress(a5),a0
	jsr	(a0)
	movem.l	(sp)+,d0-a6
	moveq	#0,d0
	rts	

.deltaplay
	movem.l	d0-a6,-(sp)
	moveq	#0,d0	
	bra.b	.delt

.deltaend
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat
.deltastop
	bra.w	clearsound

.deltavolume
	movem.l	d0-a6,-(sp)
	move	mainvolume(a5),d1
	subq	#1,d1
	bpl.b	.err
	moveq	#0,d1
.err	moveq	#2,d0
	bra.b	.delt



.id_deltamusic
	lea	.delta_id(pc),a1	* Delta Music 2
	moveq	#.delend-.delta_id,d0
	bsr.w	search
	bra.w	idtest

.delta_id
	dc.b	"DELTA MUSIC"
.delend
 even


******************************************************************************
* Future Composer 1.0 - 1.3
******************************************************************************

fc_author
	pushpea	.a(pc),d0
	rts

.a	dc.b	"Supersero/Superions (based on Jochen Hippel replay)",0
	even 

p_futurecomposer13
	jmp	.fc10init(pc)
	jmp	.fc10play(pc)
	p_NOP
	jmp	.fc10end(pc)
	jmp	.fc10stop(pc)
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp .id_futurecomposer13(pc)
	jmp	fc_author(pc)
	dc.w pt_future10			* type
	dc	pf_cont!pf_stop!pf_volume!pf_end!pf_ciakelaus!pf_poslen!pf_scope!pf_quadscopePoke
	dc.b	"Future Composer v1.0-1.3",0
 even


.offset_init = $20+0
.offset_play = $20+4


.fc10init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	fc10routines(a5),a0
	bsr.w	allocreplayer2 * Into CHIP, has waveforms in it
	beq.b	.ok3
	bsr.w	rem_ciaint
	bra.w	vapauta_kanavat

.ok3
	pushm	d0-d7/a1-a6
	move.l	moduleaddress(a5),a0
	lea	mainvolume(a5),a1
	lea	songover(a5),a2
	lea	scopeData(a5),a3
	move.l	fc10routines(a5),a4
	jsr	.offset_init(a4)
	popm	d0-d7/a1-a6
	move.l	a0,deliPatternInfo(a5)
	moveq	#0,d0
	rts
.fc10play
	push	a5
	move.l	fc10routines(a5),a0
	jsr	.offset_play(a0)
	pop	a5
	move	d0,pos_nykyinen(a5)
	move	d1,pos_maksimi(a5)
	rts

.fc10end
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat
.fc10stop
	bra.w	clearsound

.id_futurecomposer13
	cmp.l	#'SMOD',(a4)		* Futurecomposer 1.0-1.3
	bra.w	idtest

******************************************************************************
* Future Composer 1.4
******************************************************************************


p_futurecomposer14
	jmp	.fc10init(pc)
	jmp	.fc10play(pc)
	p_NOP
	jmp	.fc10end(pc)
	jmp	.fc10stop(pc)
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp .id_futurecomposer14(pc)
	jmp	fc_author(pc)
	dc.w pt_future14	* type
	dc	pf_cont!pf_stop!pf_volume!pf_end!pf_ciakelaus!pf_poslen!pf_scope!pf_quadscopePoke
	dc.b	"Future Composer v1.4",0

 even

.offset_init = $20+0
.offset_play = $20+4
.offset_end = $20+8


.fc10init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	fc14routines(a5),a0
	bsr.w	allocreplayer2
	beq.b	.ok3
	bsr.w	rem_ciaint
	bra.w	vapauta_kanavat
;	rts

.ok3	
	pushm 	d0-d7/a1-a6
	move.l	moduleaddress(a5),a0
	lea	mainvolume(a5),a1
	lea	songover(a5),a2
	lea	scopeData(a5),a3
	move.l	fc14routines(a5),a4
	jsr	.offset_init(a4)
	popm	d0-d7/a1-a6
	move.l	a0,deliPatternInfo(a5)
	moveq	#0,d0
	rts
.fc10play
	move.l	fc14routines(a5),a0
	push	a5
	jsr	.offset_play(a0)
	pop 	a5 
	move	d0,pos_nykyinen(a5)
	move	d1,pos_maksimi(a5)
	rts

.fc10end
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat
.fc10stop
	bra.w	clearsound

.id_futurecomposer14
	cmp.l	#'FC14',(a4)		* Futurecomposer 1.4
	bra.w	idtest




******************************************************************************
* SoundMon
******************************************************************************

bp_author 
	pushpea	.a(pc),d0 
	rts

.a 	dc.b	"Brian Postma",0 
	even

p_soundmon
	jmp	.bpsminit(pc)
	jmp	.bpsmplay(pc)
	p_NOP
	jmp	.bpsmend(pc)
	jmp	.bpsmstop(pc)
	p_NOP
	p_NOP
	p_NOP
	jmp	.eteen(pc)
	jmp	.taakse(pc)
	p_NOP
	jmp .id_soundmon(pc)
	jmp	bp_author(pc)
	dc.w pt_soundmon2
 	dc pf_scope!pf_cont!pf_stop!pf_poslen!pf_kelaus!pf_volume!pf_end!pf_ciakelaus2!pf_scope!pf_quadscopePoke
	dc.b	"BP SoundMon v2.0",0
 even

.offset_init	= $20+0
.offset_play	= $20+4
.offset_forward	= $20+8
.offset_rewind	= $20+12


.bpsminit
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	bpsmroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bra.w	vapauta_kanavat
;	rts
.ok3


	move.l	moduleaddress(a5),a0
	lea	songover(a5),a1
	lea	pos_nykyinen(a5),a2
	lea	nullsample,a3
	clr.l	(a3)
	lea	mainvolume(a5),a4
	pushpea	dmawait(pc),d0
	pushpea	scopeData(a5),d1

	pushm	a5/a6
	move.l	bpsmroutines(a5),a6
	jsr	.offset_init(a6)
	popm	a5/a6
	move.l	a0,deliPatternInfo(a5)
	moveq	#0,d0
	rts
.bpsmplay
	move.l	bpsmroutines(a5),a0
	jmp	.offset_play(a0)
.bpsmend
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat

.bpsmstop
	bra.w	clearsound

.eteen
	move.l	bpsmroutines(a5),a0
	jmp	.offset_forward(a0)

.taakse
	move.l	bpsmroutines(a5),a0
	jmp	.offset_rewind(a0)



.id_soundmon 
	bsr.b 	.id_soundmon_
	bne.b 	.x 
	moveq	#25-1,d0
	bsr.w	copyNameFromModule
	moveq	#0,d0
.x	rts

.id_soundmon_
	move.l	26(a4),d0		* Soundmon
	lsr.l	#8,d0
	cmp.l	#'V.2',d0
	bra.w	idtest



******************************************************************************
* SoundMon 3
******************************************************************************

p_soundmon3
	jmp	.bpsminit(pc)
	jmp	.bpsmplay(pc)
	p_NOP
	jmp	.bpsmend(pc)
	jmp	.bpsmstop(pc)
	p_NOP
	p_NOP
	p_NOP
	jmp	.eteen(pc)
	jmp	.taakse(pc)
	p_NOP	
	jmp 	.id_soundmon3(pc)
	jmp	bp_author(pc)
	dc.w 	pt_soundmon3 	* type
 	dc pf_scope!pf_cont!pf_stop!pf_poslen!pf_kelaus!pf_volume!pf_end!pf_ciakelaus2!pf_scope!pf_quadscopePoke
	dc.b	"BP SoundMon 3 (v2.2)",0
 even

.bpsminit
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	bpsmroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bra.w	vapauta_kanavat
;	rts
.ok3


	move.l	moduleaddress(a5),a0
	lea	songover(a5),a1
	lea	pos_nykyinen(a5),a2
	lea	nullsample,a3
	clr.l	(a3)
	lea	mainvolume(a5),a4
	pushpea	dmawait(pc),d0
	pushpea	scopeData(a5),d1

	pushm	a5/a6
	move.l	bpsmroutines(a5),a6
	jsr	$20(a6)
	popm	a5/a6
	move.l	a0,deliPatternInfo(a5)
	moveq	#0,d0
	rts
.bpsmplay
	move.l	bpsmroutines(a5),a0
	jmp	$20+4(a0)
.bpsmend
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat

.bpsmstop
	bra.w	clearsound

.taakse
	move.l	bpsmroutines(a5),a0
	jmp	12+$20(a0)

.eteen
	move.l	bpsmroutines(a5),a0
	jmp	8+$20(a0)


.id_soundmon3 
	bsr.b 	.id_soundmon3_
	bne.b 	.x 
	moveq	#25-1,d0
	bsr.w	copyNameFromModule
	moveq	#0,d0
.x	rts

.id_soundmon3_
	move.l	26(a4),d0		* Soundmon
	lsr.l	#8,d0
	cmp.l	#'V.3',d0
	beq.b	.y
	cmp.l	#'BPS',d0
	bra.w	idtest

.y	moveq	#0,d0
	rts


******************************************************************************
* Jamcracker
******************************************************************************

p_jamcracker
	jmp	.jaminit(pc)
	jmp	.jamplay(pc)
	p_NOP
	jmp	.jamend(pc)
	jmp	.jamstop(pc)
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp .id_jamcracker(pc)
	jmp	.author(pc)
	dc.w pt_jamcracker				* type
	dc	pf_cont!pf_stop!pf_end!pf_ciakelaus!pf_poslen!pf_volume!pf_scope!pf_quadscopePoke
	dc.b	"JamCracker",0
.a 	dc.b 	"Xag/Betrayal, Martin Kemmel",0
 even

.offset_init	= $20+0
.offset_play	= $20+4


.author
	pushpea	.a(pc),d0
	rts 

.jaminit
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	jamroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bra.w	vapauta_kanavat
;	rts

.ok3	
	pushm 	a5/a6
	move.l	moduleaddress(a5),a0
	lea	dmawait(pc),a1
	lea	songover(a5),a2
	lea 	mainvolume(a5),a3 
	lea 	nullsample,a4
	move.l	jamroutines(a5),a6
	lea	scopeData(a5),a5
	jsr	.offset_init(a6)
	popm 	a5/a6
	move	d0,pos_maksimi(a5)
	move.l	a0,deliPatternInfo(a5)
	moveq	#0,d0
	rts	

.jamplay
	move.l	jamroutines(a5),a0
	jsr 	.offset_play(a0)
	move	d0,pos_nykyinen(a5)
	rts

.jamend
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat

.jamstop
	bra.w	clearsound


.id_jamcracker
	cmp.l	#'BeEp',(a4)		* JamCracker
	bra.w	idtest

******************************************************************************
* Music Assembler
******************************************************************************

p_musicassembler
	jmp	.massinit(pc)
	jmp	.massplay(pc)
	p_NOP
	jmp	.massend(pc)
	jmp	.massstop(pc)
	p_NOP
	jmp	.massvolume(pc)
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp .id_musicassembler(pc)
	jmp	.author(pc)
	dc.w pt_musicass				* type
	dc	pf_cont!pf_stop!pf_volume!pf_ciakelaus
	dc.b	"Music Assembler",0
.a 	dc.b	"Oscar Giesen, Marco Swagerman",0
 even

.author
	pushpea	.a(pc),d0
	rts

.massinit
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2

	moveq	#0,d0
.minit	move.l	moduleaddress(a5),a0
	jsr	(a0)
	bsr.b	.massvolume
	moveq	#0,d0
	rts	

.massplay
	move.l	moduleaddress(a5),a0
	jmp	12(a0)

.massend
	bsr.w	rem_ciaint
	pushm	all
	move.l	moduleaddress(a5),a0
	jsr	4(a0)
	popm	all
	bra.w	vapauta_kanavat

.massstop
	bra.w	clearsound


.massvolume
	move	mainvolume(a5),d0
	moveq	#$f,d1
	move.l	moduleaddress(a5),a0
	jmp	8(a0)

;.masssong
;	move.l	moduleaddress(a5),a0
;	jsr	4(a0)		* end
;	moveq	#0,d0
;	move	songnumber(a5),d0
;	bra.b	.minit



.id_musicassembler
	lea	.muass_id(pc),a1	* Music Assembler
	moveq	#.muassend-.muass_id,d0
	bsr.w	search
	bra.w	idtest


.muass_id
	dc.b	"usa-team 89"
.muassend
 even

******************************************************************************
* Fred
******************************************************************************

p_fred
	jmp	.fredinit(pc)
	jmp	.fredplay(pc)
	p_NOP
	jmp	.fredend(pc)
	jmp	.fredstop(pc)
	p_NOP
	p_NOP
	jmp	.fredsong(pc)
	p_NOP
	p_NOP
	p_NOP
	jmp .id_fred(pc)
	jmp	.author(pc)
	dc.w pt_fred				* type
	dc	pf_cont!pf_stop!pf_song!pf_ciakelaus
	dc.b	"Fred",0
.a 	dc.b	"Frederic Hahn",0
 even

.author
	pushpea	.a(pc),d0
	rts
	
.fredinit
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	movem.l	d0-a6,-(sp)
	moveq	#0,d0
	bset	#1,$bfe001
.finit	move.l	moduleaddress(a5),a0
	jsr	(a0)
	movem.l	(sp)+,d0-a6
	moveq	#0,d0
	rts	

.fredplay
	move.l	moduleaddress(a5),a0
	jmp	4(a0)

.fredend
	bsr.w	rem_ciaint
	movem.l	d0-a6,-(sp)
	move.l	moduleaddress(a5),a0
	jsr	8(a0)
	movem.l	(sp)+,d0-a6
	bra.w	vapauta_kanavat

.fredstop
	bra.w	clearsound


.fredsong
	movem.l	d0-a6,-(sp)
	move.l	moduleaddress(a5),a0
	jsr	8(a0)		* end
	moveq	#0,d0
	move	songnumber(a5),d0
	bra.b	.finit


.id_fred
* d5 => maxsongs
	move.l	a4,a0
	moveq	#-1,d0				; Modul nicht erkannt (default)
	cmpi.w	#$4efa,(a0)
	bne.s	.ChkEnd
	cmpi.w	#$4efa,$04(a0)
	bne.s	.ChkEnd
	cmpi.w	#$4efa,$08(a0)
	bne.s	.ChkEnd
	cmpi.w	#$4efa,$0c(a0)
	bne.s	.ChkEnd
	add.w	2(a0),a0
	moveq	#4-1,d1
.ChkLoop cmpi.w	#$123a,2(a0)
	bne.s	.ChkNext
	cmpi.w	#$b001,6(a0)
	beq.s	.ChkSong
.ChkNext addq.l	#2,a0
	dbra	d1,.ChkLoop
	bra.s	.ChkEnd				; Modul nicht erkannt
.ChkSong add.w	4(a0),a0
	moveq	#0,d5
	move.b	4(a0),d5
	move	d5,maxsongs(a5)
	moveq	#0,d0				; Modul erkannt
.ChkEnd	tst.l	d0
	rts


******************************************************************************
* SonicArranger
******************************************************************************

p_sonicarranger
	jmp	.init(pc)
	jmp	 .play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	 .stop(pc)
	p_NOP
	p_NOP
	jmp 	.song(pc)
	jmp 	.forward(pc)
	jmp 	.backward(pc)
	p_NOP
	jmp .id_sonicarranger(pc)
	jmp	.author(pc)
	dc.w pt_sonicarranger				* type
	dc pf_cont!pf_stop!pf_poslen!pf_kelaus!pf_volume!pf_end!pf_ciakelaus2!pf_song
	dc.b	"Sonic Arranger",0
.a 	dc.b	"Carsten Schlote, Branko Mikic, Carsten Herbst",0
 even

.author
	pushpea	.a(pc),d0
	rts	

.offset_init 		= $20+0
.offset_play 		= $20+4
.offset_end		= $20+8
.offset_song 		= $20+12
.offset_forward 	= $20+16
.offset_backward 	= $20+20

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	sonicroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bra.w	vapauta_kanavat
.ok3
	;bra	.skip

	move.l	moduleaddress(a5),a0
	move.l	modulelength(a5),d0
	lea	mainvolume(a5),a1
	lea	songover(a5),a2
	lea	pos_nykyinen(a5),a3
	move.l	sonicroutines(a5),a4
	push	a5
	jsr	.offset_init(a4)
	pop	a5
	cmp.b	#-1,d0
	beq.b	.memErr
	cmp.b	#-2,d0
	beq.b	.formatErr
	move	d1,pos_maksimi(a5)
	move	d3,maxsongs(a5)

	move	d2,d0
	bsr.w	ciaint_setTempoFromD0
.skip
	moveq	#0,d0
	rts	

.memErr	moveq	#ier_nomem,d0
	rts
.formatErr
	moveq	#ier_not_compatible,d0
	rts

.end
	bsr.w	rem_ciaint
	move.l	sonicroutines(a5),a0
	jsr	.offset_end(a0)
	bsr.w	clearsound
	bra.w	vapauta_kanavat

.stop
	bra.w	clearsound
	
.song
	move	songnumber(a5),d0
	move.l	sonicroutines(a5),a0
	push	a5
	jsr	.offset_song(a0)
	pop	a5
	move	d0,pos_maksimi(a5)
	rts

.forward
	move.l	sonicroutines(a5),a0
	push	a5
	jsr	.offset_forward(a0)
	pop	a5
	rts
.backward
	move.l	sonicroutines(a5),a0
	push	a5
	jsr	.offset_backward(a0)
	pop	a5
	rts

.play	
	move.l	sonicroutines(a5),a0
	jmp	.offset_play(a0)


; in: a4 = module
;     d7 = module length
; out: d0 = 0, valid valid
;      d0 = -1, not valid
.id_sonicarranger
	move.l	a4,a0
	move.l	d7,d3
	moveq	#-1,D0

	cmp.l	#'SOAR',(A0)
	bne.b	.NoSong
	addq.l	#4,A0
	cmp.l	#'V1.0',(A0)+
	bne.w	.Fault
	cmp.l	#'STBL',(A0)
	bne.w	.Fault
	bra.w	.Found
.NoSong
	cmp.w	#$4EFA,(A0)
	bne.b	.NoRepa
	move.w	2(A0),D1
	beq.b	.Fault
	bmi.b	.Fault
	btst	#0,D1
	bne.b	.Fault
	lea	6(A0,D1.W),A1
	cmp.w	#$41FA,(A1)+
	bne.b	.Fault
	moveq	#0,D1
	move.w	(A1),D1
	beq.b	.Fault
	bmi.b	.Fault
	btst	#0,D1
	bne.b	.Fault
	add.w	D1,A1
	subq.l	#8,D3
	sub.l	D1,D3
	bmi.b	.Fault
	move.l	A1,A0
.NoRepa
	move.l	A0,A1
	moveq	#$28,D1
	sub.l	D1,D3
	bmi.b	.Fault
	cmp.l	(A1)+,D1
	bne.b	.Fault
	moveq	#6,D1
.NextLong
	move.l	(A1)+,D2
	beq.b	.Fault
	bmi.b	.Fault
	btst	#0,D2
	bne.b	.Fault
	dbf	D1,.NextLong
	sub.l	D2,D3
	bmi.b	.Fault
	lea	(A0,D2.L),A1
	move.l	(A1)+,D1
	beq.b	.SynthOnly
	move.l	A1,A0
.NextSize
	sub.l	(A0),D3
	bmi.b	.Fault
	add.l	(A0)+,A1
	addq.l	#4,A1
	subq.l	#1,D1
	bne.b	.NextSize
.SynthOnly
	moveq	#12,D1
	sub.l	D1,D3
	bmi.b	.Fault
	lea	.Text(PC),A0
.CheckString
	cmpm.b	(A0)+,(A1)+
	bne.b	.Fault
	dbeq	D1,.CheckString
.Found
	moveq	#0,D0
.Fault
	tst.l	d0
	rts
.Text
	dc.b	'deadbeef'
	dc.l	0


******************************************************************************
* SidMon 1.0
******************************************************************************

p_sidmon1
	jmp	.sm10init(pc)
	jmp	.sm10play(pc)
	p_NOP
	jmp	.sm10end(pc)
	jmp	.sm10stop(pc)
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp 	.id_sidmon1(pc)
	jmp	author_vliet(pc)
	dc.w 	pt_sidmon1			* type
	dc	pf_stop!pf_cont!pf_ciakelaus
	dc.b	"SidMon 1",0
 even

.sm10init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	movem.l	d0-a6,-(sp)
	; The id routine does code modification to the module
	; provided replay routine, for safety clear caches
	; before calling.
	bsr.w	clearCpuCaches
	move.l	sid10init(pc),a0
	jsr	(a0)
	movem.l	(sp)+,d0-a6
	moveq	#0,d0
	rts	

.sm10play
	move.l	sid10music(pc),a0
	jmp	(a0)

.sm10end
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat
.sm10stop
	bra.w	clearsound



.id_sidmon1
* d1 => sid10init
* d2 => sid10music
	move.l	a4,a0
	bsr.b	.do 
	tst.l	d0 
	bne.b 	.no
	move.l	d1,sid10init
	move.l	d2,sid10music
.no
	rts 
.do
	moveq	#-$01,d0
	cmpi.l	#$08f90001,(a0)
	bne.b	.l_f218
	cmpi.l	#$00bfe001,$0004(a0)
.l_f1f6	bne.b	.l_f218
	cmpi.w	#$4e75,$025c(a0)
	beq.b	.l_f20e
	cmpi.w	#$4ef9,$025c(a0)
	bne.b	.l_f218
	move.w	#$4e75,$025c(a0)
.l_f20e	moveq	#$2c,d1
	move.l	#$0000016a,d2
	bra.b	.l_f266
.l_f218	cmpi.w	#$41fa,(a0)
	bne.b	.l_f278
	cmpi.w	#$d1e8,$0004(a0)
	bne.b	.l_f278
	cmpi.w	#$4e75,$0230(a0)
	beq.b	.l_f23e
	cmpi.w	#$4ef9,$0230(a0)
	bne.b	.l_f248
	move.w	#$4e75,$0230(a0)
.l_f23e	moveq	#$00,d1
	move.l	#$0000013e,d2
	bra.b	.l_f266
.l_f248	cmpi.w	#$4e75,$029c(a0)
	beq.b	.l_f25e
	cmpi.w	#$4ef9,$029c(a0)
	bne.b	.l_f278
	move.w	#$4e75,$029c(a0)
.l_f25e	moveq	#$00,d1
	move.l	#$0000016a,d2
.l_f266	moveq	#$00,d0
	add.l	a0,d1		* init
	add.l	a0,d2		* music
;	movem.l	d1/d2,sid10init
.l_f278	
	rts	


sid10init	dc.l	0
sid10music	dc.l	0


******************************************************************************
* Oktalyzer (v1.56)
******************************************************************************

p_oktalyzer
	jmp	.okinit(pc)
	jmp	.okplay(pc)
	p_NOP
	jmp	.okend(pc)
	jmp	.okstop(pc)
	jmp	.okcont(pc)
	jmp	.okvolume(pc)
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp 	.id(pc)
	jmp	.author(pc)
	dc.w 	pt_oktalyzer * type
	dc	pf_volume!pf_end!pf_poslen!pf_stop!pf_cont!pf_scope!pf_quadscopePoke
	dc.b	"Oktalyzer",0
.a	dc.b	"Armin Sander",0
 even

.author
	pushpea	.a(pc),d0 
	rts

.offset_init = $20+0 
.offset_play = $20+4 
.offset_end  = $20+8 
.offset_vol  = $20+12 


.okstop	
	move	#$f,$dff096
	rts
.okcont
	move	#$800f,$dff096
	rts
	
.okinit	
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2

	lea	oktaroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bra.w	vapauta_kanavat

.ok3	
	move.l	moduleaddress(a5),a0
	lea	songover(a5),a1
	lea	scopeData(a5),a2
	move.l	oktaroutines(a5),a3
	push	a5
	jsr	.offset_init(a3)
	pop	a5
	tst	d0
	bne.b	.mem
	
	move.l	a0,deliPatternInfo(a5)
 if DEBUG 
	moveq	#0,d0
	move	PI_Voices(a0),d0
	DPRINT	"Voices: %ld"
 endif 
	bsr.b	.okvolume
	moveq	#0,d0
	rts

.mem	moveq	#ier_nomem,d0
	rts

.okplay	
	push	a5
	move.l	oktaroutines(a5),a0
	jsr	.offset_play(a0)
	pop	a5
	move	d0,pos_nykyinen(a5)
	move	d1,pos_maksimi(a5)
	rts

.okend	
	bsr.w	rem_ciaint
	pushm	all
	move.l	oktaroutines(a5),a0
	jsr	.offset_end(a0)
	popm	all
.oke	bra.w	vapauta_kanavat

.okvolume
	moveq	#0,d0
	move	mainvolume(a5),d0
	move.l	oktaroutines(a5),a0
	jmp	.offset_vol(a0)


.id 
	bsr.b	id_oktalyzer8ch 
	bne.b	id_oktalyzer

	bsr.w	moveModuleToPublicMem
	moveq	#0,d0 
	rts

id_oktalyzer
	cmp.l	#'OKTA',(a4)		* Oktalyzer
	bne.b	.nok
	cmp.l	#'SONG',4(a4)
	bra.w	idtest

.nok	moveq	#-1,d0
	rts

id_oktalyzer8ch
	bsr.b  id_oktalyzer
	bne.b 	.no
	cmp.l	#$00010001,$10(a4)	* Onko 8 kanavaa?
	bne.b	.no
	cmp.l	#$00010001,$10+4(a4)
	beq.b	.go
.no 
	moveq	#-1,d0
	rts
.go 
	moveq	#0,d0
	rts
******************************************************************************
* TFMX
******************************************************************************

tfmx_author
	pushpea	.a(pc),d0 
	rts
.a 
	dc.b	"Chris Huelsbeck, Peter Thierolf",0
	even

p_tfmx
	jmp	.tfmxinit(pc)
	p_NOP
	jmp	.tfmxvb(pc)
	jmp	.tfmxend(pc)
	jmp	.tfmxstop(pc)
	jmp	.tfmxcont(pc)
	jmp	.tfmxvolume(pc)
	jmp	.tfmxsong(pc)
	jmp	.eteen(pc)
	jmp	.taakse(pc)
	p_NOP
	jmp id_tfmx(pc) 
	jmp	tfmx_author(pc)
	dc.w pt_tfmx				* type
	dc	pf_cont!pf_stop!pf_song!pf_volume!pf_kelaus!pf_poslen!pf_end
	dc.b	"TFMX",0
 even


.eteen
	pushm	d0/a0
	move.l	tfmxroutines(a5),a0
	move	7196(a0),d0
	addq	#2,d0
	cmp	7194(a0),d0
	bhi.b	.og
	subq	#1,d0
	move	d0,7196(a0)
.og	popm	d0/a0
	rts

.taakse
	push	a0
	move.l	tfmxroutines(a5),a0
	subq	#1,7196(a0)
	bpl.b	.gog
	clr	7196(a0)
.gog	pop	a0
	rts

.tfmxvb
	push	a0
	move.l	tfmxroutines(a5),a0
	move	7194(a0),pos_maksimi(a5)
	move	7196(a0),pos_nykyinen(a5)
	pop	a0
	rts

.tfmxinit
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok
	lea	tfmxroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok2
	bra.w	vapauta_kanavat
;	rts
.ok2
	move.l	tfmxroutines(a5),a0
	lea	5788(a0),a1
	lea	tfmxi1(pc),a2
;	move.l	a1,tfmxi1
	move.l	a1,(a2)
	lea	2092(a0),a0
;	move.l	a0,tfmxi2
;	move.l	a0,tfmxi3
;	move.l	a0,tfmxi4
;	move.l	a0,tfmxi5
	move.l	a0,tfmxi2-tfmxi1(a2)
	move.l	a0,tfmxi3-tfmxi1(a2)
	move.l	a0,tfmxi4-tfmxi1(a2)
	move.l	a0,tfmxi5-tfmxi1(a2)

	bsr.w	tfmx_varaa
	beq.b	.ok3
;	move.l	tfmxroutines(a5),a0
;	bsr.w	freereplayer
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts

.ok3
	bsr.w	gettfmxsongs
	move	d0,maxsongs(a5)


	move.l	moduleaddress(a5),a0
	cmp.l	#"TFHD",(a0)
	bne.b	.noo

	move.l	a0,d0
	add.l	4(a0),d0		* MDAT
	move.l	d0,d1
	add.l	10(a0),d1		* SMPL
	btst	#0,d1		* onko parittomassa osoitteessa?
	beq.b	.un
	addq.l	#1,d1		* on, v‰‰nnet‰‰n se parilliseksi
	move.l	d1,a0
	clr.l	(a0)		* alusta nollaa tyhj‰ks
	bra.b	.un
.noo


	move.l	moduleaddress(a5),d0
	move.l	tfmxsamplesaddr(a5),d1

.un
	move.l	tfmxroutines(a5),A0
	jsr	$14(A0)
	moveq	#0,d0			* song number
	move	songnumber(a5),d0
	move.l	tfmxroutines(a5),A0
	jsr	12(A0)


	bsr.b	.tfmxvolume
	bsr.b	.tfmxcont
	moveq	#0,d0
	rts

.tfmxcont
	bset	#0,$bfdf00
	rts

.tfmxstop
	bclr	#0,$bfdf00
	bra.w	clearsound


.tfmxsong
	bsr.b	.tfmxe
	bra.b	.ok3

.tfmxvolume
	moveq	#0,d0
	move	mainvolume(a5),d0
	move.l	tfmxroutines(a5),A0
	jmp	$28(A0)

.tfmxend
	pushm	all
	bsr.w	tfmx_vapauta
	bsr.b	.tfmxe
	popm	all
	bra.w	vapauta_kanavat
	
.tfmxe	bsr.b	.tfmxstop
	move.l	tfmxroutines(a5),A0
	jsr	$1C(A0)
	moveq	#0,D0
	move.l	tfmxroutines(a5),A0
	jsr	$20(A0)
	moveq	#1,D0
	move.l	tfmxroutines(a5),A0
	jsr	$20(A0)
	moveq	#2,D0
	move.l	tfmxroutines(a5),A0
	jsr	$20(A0)
	moveq	#3,D0
	move.l	tfmxroutines(a5),A0
	jsr	$20(A0)
	rts



tfmx_varaa
	move.l	a6,-(sp)
	moveq	#7,D0
	lea	tfmx_L000106(PC),A1
	move.l	(a5),A6
	jsr	-$A2(A6)
	move.l	D0,tfmx_L0000E0(a5)
	moveq	#8,D0
	lea	tfmx_L00011C(PC),A1
	jsr	-$A2(A6)
	move.l	D0,tfmx_L0000E4(a5)
	moveq	#9,D0
	lea	tfmx_L000132(PC),A1
	jsr	-$A2(A6)
	move.l	D0,tfmx_L0000E8(a5)
	moveq	#10,D0
	lea	tfmx_L000148(PC),A1
	jsr	-$A2(A6)
	move.l	D0,tfmx_L0000EC(a5)
	lea	.n(pc),A1
	jsr	-$1F2(A6)
	move.l	D0,tfmx_L0000DC(a5)
	beq.b	tfmx_C000338
	moveq	#1,D0
	lea	tfmx_L0000F0(PC),A1
	move.l	tfmx_L0000DC(a5),A6
	jsr	-6(A6)
	tst.l	D0
	bne.b	tfmx_C000338
	moveq	#0,D0
	move.l	(sp)+,a6
	rts

.n	dc.b	"ciab.resource",0
 even

* vapautetaan kaikki
tfmx_vapauta
	move.l	a6,-(sp)
	moveq	#1,D0
	lea	tfmx_L0000F0(PC),A1
	move.l	tfmx_L0000DC(a5),A6
	jsr	-12(A6)
tfmx_C000338	moveq	#10,D0
	move.l	tfmx_L0000EC(a5),A1
	move.l	(a5),A6
	jsr	-$A2(A6)
	moveq	#9,D0
	move.l	tfmx_L0000E8(a5),A1
	jsr	-$A2(A6)
	moveq	#8,D0
	move.l	tfmx_L0000E4(a5),A1
	jsr	-$A2(A6)
	moveq	#7,D0
	move.l	tfmx_L0000E0(a5),A1
	jsr	-$A2(A6)
	move.l	(sp)+,a6
	rts


tfmx_L0000F0	dcb.l	$2,0
	dc.b	2,1			* nt_interrupt, prioriteetti 1
	dc.l	TFMX_Pro_MSG0
	dcb.w	$2,0
tfmxi1	dc.l	0
tfmx_L000106	dcb.l	$2,0
	dc.b	2,100
	dc.l	TFMX_Pro_MSG0
	dcb.w	$2,0
tfmxi2	dc.l	0
tfmx_L00011C	dcb.l	$2,0
	dc.b	2,100
	dc.l	TFMX_Pro_MSG0
	dcb.w	$2,0
tfmxi3	dc.l	0
tfmx_L000132	dcb.l	$2,0
	dc.b	2,100
	dc.l	TFMX_Pro_MSG0
	dcb.w	$2,0
tfmxi4	dc.l	0
tfmx_L000148	dcb.l	$2,0
	dc.b	2,100
	dc.l	TFMX_Pro_MSG0
	dcb.w	$2,0
tfmxi5	dc.l	0
TFMX_Pro_MSG0 dc.b "TFMX",0
 even


* palauttaa songien m‰‰r‰n d0:ssa
gettfmxsongs
	move.l	moduleaddress(a5),a0
	lea	$0100(a0),a0
	moveq.l	#-2,d0
	moveq.l	#2,d1
	moveq.l	#$1e,d2
.35a	addq.l	#1,d0
	tst.w	(a0)+
	bne.s	.362
	subq.l	#1,d1
.362	dbeq	d2,.35a
	rts	


* TODO: all variants

id_tfmxunion
	cmp.l	#'TFHD',(a4)		* Yhdistetty TFMX formaatti
	bra.w	idtest

id_tfmx
	cmp.l	#"TFMX",(a4)
	beq.b	.y
	cmp.l	#"tfmx",(a4)
	bra.w	idtest

.y	moveq	#0,d0
	rts
	


id_TFMX_PRO	
	move.l	a4,a1
	lea	TFMX_IDs(pc),a0
.id_loop
	tst.b	(a0)
	beq.b	.Not_TFMX_PRO
	move.l	a4,a1		;Module
.strloop
	tst.b	(a0)
	beq.s	.found
	cmpm.b	(a0)+,(a1)+
	beq.s	.strloop
.skiploop
	tst.b	(a0)+
	bne.s	.skiploop
	bra.s	.id_loop
.found
	move.l	a4,a0	;Module
	move.w	$100(a0),d0
	move.l	$1D0(a0),d1
	bne.s	.valid
	move.l	#$800,d1
.valid
	add.l	d1,a0	;Channel table
	moveq	#0,d1
	moveq	#0,d3	;Start as TFMX Pro
.chanloop
	move.w	d0,d2	;Channel number
	lsl.w	#4,d2
	move.l	a0,a2
	add.w	d2,a2	;Channel pointer
	move.w	(a2)+,d2	;Channel number
	cmp.w	#$EFFE,d2	;End mark
	bne.s	.done
	move.w	(a2)+,d2	;Channel type
	add.w	d2,d2
	cmp.w	#10,d2
	blo.s	.notover10
	moveq	#0,d2
	moveq	#0,d3	;Is TFMX Pro
.notover10
	jmp	.JTab(pc,d2.w)
.JTab
	bra.s	.done
	bra.s	.test
	bra.s	.next
	bra.s	.probably_not
	bra.s	.next
.test
	tst.w	d1	;Flip-flop?
	beq.s	.start
	bmi.s	.channum
	bra.s	.chan
.start
	move.w	#$FFFF,d1
	addq.w	#1,d0	;Next channel
	bra.s	.chanloop
.channum
	move.w	2(a2),d1
.chan
	subq.w	#1,d1
	move.w	(a2),d0	;Paired channel?
	bra.s	.chanloop
.probably_not
	moveq	#-1,d3
.next
	addq.w	#1,d0	;Next Channel
	bra.s	.chanloop
.done
	tst.l	d3
	bne.s	.Not_TFMX_PRO
	moveq	#0,d0	;Identified!
	bra.s	.exit
.Not_TFMX_PRO
	moveq	#-1,d0
.exit
	rts

TFMX_IDs
	dc.b	'tfmxsong',0
	dc.b	'TFMX-SONG',0
	dc.b	'TFMX_SONG',0,0


******************************************************************************
* TFMX 7 channels
******************************************************************************



p_tfmx7
	jmp	.tfmxinit(pc)
	p_NOP
	jmp	.vb(pc)
	jmp	.tfmxend(pc)
	jmp	.stop(pc)
	jmp	.cont(pc)
	jmp	.tfmxvol(pc)
	jmp	.tfmxsong(pc)
	jmp	.eteen(pc)
	jmp	.taakse(pc)
	p_NOP
	jmp 	id_TFMX7V(pc)
	jmp	tfmx_author(pc)
	dc.w 	pt_tfmx7 	* type
	dc	pf_volume!pf_song!pf_poslen!pf_kelaus!pf_end!pf_stop!pf_cont
	dc.b	"TFMX 7ch",0
 even

.OFFSET_INIT = 0+$20
.OFFSET_END = 4+$20
.OFFSET_VOL = 8+$20
.OFFSET_FORWARD = 12+$20
.OFFSET_BACKWARD = 16+$20
.OFFSET_STOP = 20+$20
.OFFSET_CONTINUE = 24+$20
.OFFSET_POSITION = 28+$20

.stop
	move.l	tfmx7routines(a5),a0
	jmp 	.OFFSET_STOP(a0)

.cont	
	move.l	tfmx7routines(a5),a0
	jmp 	.OFFSET_CONTINUE(a0)

.eteen
	move.l	tfmx7routines(a5),a0
	jmp	.OFFSET_FORWARD(a0)
	
.taakse
	move.l	tfmx7routines(a5),a0
	jmp 	.OFFSET_BACKWARD(a0)

.vb	push	a0
	move.l	tfmx7routines(a5),a0
	jsr	.OFFSET_POSITION(a0)
	move	d0,pos_nykyinen(a5)
	move	d1,pos_maksimi(a5)
	pop	a0
	rts

.tfmxend
	tst.l	tfmx7routines(a5)
	beq.b	.e
	move.l	tfmx7routines(a5),a4
	pushm	all
	jsr	.OFFSET_END(a4)
	popm	all
	bsr.w	vapauta_kanavat
	move.l	.tfmxbuf(pc),a0
	jsr	freemem
	clr.l	.tfmxbuf
.e	rts

.tfmxsong
	bsr.b	.tfmxend
;	bra.w	.tfmxinit

.tfmxinit
	bsr.w	varaa_kanavat
	beq.b	.okk
	moveq	#ier_nochannels,d0
	rts
.okk
	movem.l	d1-a6,-(sp)
	bsr.b	.eh
	movem.l	(sp)+,d1-a6
	rts

.eh
	lea	tfmx7routines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok
	rts
.ok
	move.l	#4096+1024,d0	* +turva-alue
	move.l	#MEMF_CHIP!MEMF_CLEAR,d1
	jsr	getmem
	move.l	d0,.tfmxbuf
	bne.b	.ok2
;	lea	tfmx7routines(a5),a0
;	bsr.w	freereplayer
	moveq	#ier_nomem,d0
	rts
.ok2	

	bsr.w	gettfmxsongs
	move	d0,maxsongs(a5)


	move.l	moduleaddress(a5),a0
	cmp.l	#"TFHD",(a0)
	bne.b	.noo

	move.l	a0,d0
	add.l	4(a0),d0		* MDAT
	move.l	d0,d1
	add.l	10(a0),d1		* SMPL
	bra.b	.un
.noo
	move.l	moduleaddress(a5),d0
	move.l	tfmxsamplesaddr(a5),d1

.un
	move.l	tfmxroutines(a5),a4
	moveq	#0,d3
	move	songnumber(a5),d3
	moveq	#0,d2
	move	tfmxmixingrate(a5),d2
	move.l	.tfmxbuf(pc),d4
	move.l	a5,-(sp)
	jsr	.OFFSET_INIT(a4)
	move.l	(sp)+,a5
	bsr.b	.tfmxvol
	moveq	#0,d0
	rts


.tfmxbuf dc.l	0	* koko 4096

.tfmxvol
	move	mainvolume(a5),d0
	move.l	tfmx7routines(a5),a4
	move.l	a5,-(sp)
	jsr	.OFFSET_VOL(a4)
	move.l	(sp)+,a5
	rts



id_TFMX7V
	move.l	a4,a1
	lea	TFMX_IDs(pc),a0
.idloop
	tst.b	(a0)
	beq.b	.Not_TFMX7V
	move.l	a4,a1
.strloop
	tst.b	(a0)
	beq.s	.validID
	cmpm.b	(a0)+,(a1)+
	beq.s	.strloop
.skiploop
	tst.b	(a0)+
	bne.s	.skiploop
	bra.s	.idloop
.validID
	move.l	a4,a0
	move.w	$100(a0),d0
	move.l	$1D0(a0),d1
	bne.s	.valid
	move.l	#$800,d1
.valid
	add.l	d1,a0
	moveq	#0,d1
	moveq	#0,d3
.chanloop
	move.w	d0,d2
	lsl.w	#4,d2
	move.l	a0,a2
	add.w	d2,a2
	move.w	(a2)+,d2
	cmp.w	#$EFFE,d2
	bne.s	.done
	move.w	(a2)+,d2
	add.w	d2,d2
	cmp.w	#10,d2
	blo.s	.intable
	moveq	#0,d2
	moveq	#0,d3
.intable
	jmp	.JTab(pc,d2.w)
.JTab
	bra.s	.done
	bra.s	.check
	bra.s	.next
	bra.s	.probably_not
	bra.s	.next
.check
	tst.w	d1
	beq.s	.norm
	bmi.s	.paired
	bra.s	.chan
.norm
	move.w	#$FFFF,d1
	addq.w	#1,d0
	bra.s	.chanloop
.paired
	move.w	2(a2),d1
.chan
	subq.w	#1,d1
	move.w	(a2),d0
	bra.s	.chanloop
.probably_not
	moveq	#-1,d3
.next
	addq.w	#1,d0
	bra.s	.chanloop
.done
	tst.l	d3
	beq.s	.Not_TFMX7V
	moveq	#0,d0	;Identified!
	bra.s	.exit
.Not_TFMX7V
	moveq	#-1,d0
.exit
	rts




******************************************************************************
* MED
******************************************************************************

p_med	jmp	.medinit(pc)
	p_NOP
	jmp	.medvb(pc)
	jmp	.medend(pc)
	jmp	.medstop(pc)
	jmp	.medcont(pc)
	p_NOP
	jmp	.medsong(pc)
	jmp	.eteen(pc)
	jmp	.taakse(pc)
	p_NOP
	jmp .id_med(pc)
	jmp	.author(pc)
	dc.w pt_med
.flgs	dc	pf_stop!pf_cont!pf_poslen!pf_kelaus!pf_song
	dc.b	"MED "
.nam1	dc.b	"     "
.nam2	dc.b	"      ",0

.pahk1  dc.b	"4ch",0
.pahk2  dc.b	"5-8ch",0
.pahk3	dc.b	"1-64ch",0
.a_	dc.b	"Teijo Kinnunen",0

 even

.author
	pushpea	.a_(pc),d0
	rts

.medvb
	move.l	moduleaddress(a5),a0
	move	46(a0),pos_nykyinen(a5)
	move.l	8(a0),a0
	move	506(a0),pos_maksimi(a5)
	rts

.eteen
	movem.l	d0/d1/a0,-(sp)
	move.l	moduleaddress(a5),a0
	move	pos_maksimi(a5),d0
	move	46(a0),d1
	addq	#1,d1
	cmp	d0,d1
	blo.b	.a
	clr	d1
.a	move	d1,46(a0)
;	clr	44(a0)
;	clr	48(a0)
;	clr.b	50(a0)
	move	d1,pos_nykyinen(a5)
	movem.l	(sp)+,d0/d1/a0
	rts
.taakse
	movem.l	d0/a0,-(sp)
	move.l	moduleaddress(a5),a0
	move	46(a0),d0
	subq	#1,d0
	bpl.b	.b
	clr	d0
.b	move	d0,46(a0)
;	clr	44(a0)
	move	d0,pos_nykyinen(a5)
	movem.l	(sp)+,d0/a0
.yee	rts



.medinit
	movem.l	d1-a6,-(sp)

	move.l	_MedPlayerBase(a5),d0
	bne.w	.ook

;	move	#30,maxsongs(a5)


	lea	.flgs(pc),a1
	or	#pf_song!pf_kelaus!pf_poslen,(a1)
	move.l	moduleaddress(a5),a0
	move.l	(a0),.nam1
	cmp.l	#"MMD2",(a0)		* onko mmd2+? poistetaan kelaus..
	blo.b	.olde
	and	#~pf_kelaus!pf_poslen,(a1)
.olde
	bsr.w	whatgadgets

	move.l	moduleaddress(a5),a0
	moveq	#0,d0
	move.b	51(a0),d0
	move	d0,maxsongs(a5)

	tst.b	medrelocced(a5)		* oliko jo relokatoitu??
	bne.w	.yeep


	move.l	moduleaddress(a5),a0
	move.l	32(a0),a1		* MMD0exp
	add.l	a0,a1
	move.l	44(a1),d0		* songname
	beq.b	.nonam
	add.l	d0,a0	

	lea	modulename(a5),a1	* nimi talteen
	moveq	#40-1,d0
.co	move.b	(a0)+,(a1)+
	dbeq	d0,.co
	clr.b	(a1)
	jsr	lootaan_nimi	
.nonam
	

	move.l	moduleaddress(a5),a0
	move	506(a1),pos_maksimi(a5)

	move.l	8(a0),a1		* MMD0song *song
	add.l	a0,a1			* reloc

	btst	#6,767(a1)		* flags; 5-8 kanavaa?
	sne	d0
	btst	#7,768(a1)		* flags2; miksaus?
	sne	d1
	and	#%01,d0
	and	#%10,d1
	or	d1,d0
	move.b	d0,medtype(a5)

	cmp.b	#3,d0
	bhs.b	.error2

* d0:
* 0 = 4ch   medplayer
* 1 = 5-8ch octaplayer
* 2 = 1-64ch octamixplayer
* 3 = 1-64ch octamixplayer?


** katotaan onko midisampleja.
* a0 = 63 samplestructuree, 8 bytee kukin
	moveq	#63-1,d1
	moveq	#0,d7
.chmi	tst.b	4(a0)		* midich, 0 jos ei midi
	beq.b	.jep
	addq	#1,d7
;	jsr	flash
.jep	addq	#8,a0	
	dbf	d1,.chmi


	lea	.nam2(pc),a0
	lea	.pahk1(pc),a1
	tst.b	d0
	beq.b	.di
	lea	.pahk2(pc),a1
	subq.b	#1,d0
	beq.b	.di
	lea	.pahk3(pc),a1
.di	move.b	(a1)+,(a0)+
	bne.b	.di


;	cmp.b	#2,medtype(a5)
;	bne.b	.yeep

	move.l	moduleaddress(a5),a0	* pistet‰‰nkˆ fastiin?
	btst	#0,20(a0)		* mmdflags; MMD_LOADTOFASTMEM
	beq.b	.yeep

** jos on octamixplayerill‰ soitettava ja sijaitsee chipiss‰, koitetaan
** siirt‰‰ fastiin:
	bsr.w	moveModuleToPublicMem


.yeep
	
	lea	get_med1(pc),a0		* medplayer
	move.b	medtype(a5),d0
	beq.b	.do
	lea	get_med2(pc),a0		* octaplayer
	subq.b	#1,d0
	beq.b	.do
	lea	get_med3(pc),a0		* octamixplayer
.do	jsr	(a0)
	
	move.l	d0,_MedPlayerBase(a5)
	bne.b	.ook
	moveq	#ier_nomedplayerlib,d0
.ee	movem.l	(sp)+,d1-a6
	rts

.error2
	moveq	#ier_mederr,d0
	bra.b	.ee


.ook
	move.l	d0,a6

	tst	d7
	beq.b	.nomidi		* onko midisampleja?

	moveq	#1,d0		* saadaanko seriali?
	bsr.b	.getplayer
	tst.l	d0
	beq.b	.gotserial
.nomidi	moveq	#0,d0		* jos ei, kokeillaan ilman.
	bsr.b	.getplayer
	tst.l	d0
	bne.b	.error2
.gotserial
	tst.b	medrelocced(a5)
	bne.b	.eek
	st	medrelocced(a5)
	move.l	moduleaddress(a5),a0
	bsr.b	.relocmodule
.eek	
	moveq	#0,d0
	move	songnumber(a5),d0
	bsr.b	.setmodnum
	move.l	moduleaddress(a5),a0
 	bsr.b	.playmodule
	movem.l	(sp)+,d1-a6
	moveq	#0,d0
	rts

.getplayer
	jsr	dela
	bsr.b	.G
	jmp	dela

.G
	moveq	#_LVOMEDGetPlayer,d7
	move.b	medtype(a5),d6
	beq.b	.do2
	moveq	#_LVOMEDGetPlayer8,d7
	subq.b	#1,d6
	beq.b	.do2
	moveq	#_LVOMEDGetPlayerM,d7
.do2	jmp	(a6,d7)

.relocmodule
	moveq	#_LVOMEDRelocModule,d7
	move.b	medtype(a5),d6
	beq.b	.do3
	moveq	#_LVOMEDRelocModule8,d7
	subq.b	#1,d6
	beq.b	.do3
	moveq	#_LVOMEDRelocModuleM,d7
.do3	jmp	(a6,d7)

.setmodnum
	moveq	#_LVOMEDSetModnum,d7
	move.b	medtype(a5),d6
	beq.b	.do4
	moveq	#_LVOMEDSetModnum8,d7
	subq.b	#1,d6
	beq.b	.do4
	moveq	#_LVOMEDSetModnumM,d7
.do4	jmp	(a6,d7)


.playmodule
	jsr	dela
	bsr.b	.P
	jmp	dela
.P

	moveq	#_LVOMEDPlayModule,d7
	move.b	medtype(a5),d6
	beq.b	.do5
	moveq	#_LVOMEDPlayModule8,d7
	subq.b	#1,d6
	beq.b	.do5a

** octamixplayer
	moveq	#0,d0			* 8-bit
	move.b	medmode(a5),d0		* 1: 14-bit
	lob	MEDSet14BitMode
	moveq	#0,d0
	move	medrate(a5),d0		* mixingrate
	lob	MEDSetMixingFrequency

	moveq	#_LVOMEDPlayModuleM,d7
.do5	jmp	(a6,d7)


** octaplayer. asetetaan SetHQ() jos tarvis
.do5a
	moveq	#0,d0
	move.b	medmode(a5),d0
	lob	MEDSetHQ
	bra.b	.do5


.medend
	jsr	dela
	bsr.b	.E
	jmp	dela
.E
	movem.l	d0/d1/a0/a1/a6,-(sp)
	move.l	_MedPlayerBase(a5),a6

	moveq	#_LVOMEDFreePlayer,d0
	move.b	medtype(a5),d1
	beq.b	.do6
	moveq	#_LVOMEDFreePlayer8,d0
	subq.b	#1,d1
	beq.b	.do6
	moveq	#_LVOMEDFreePlayerM,d0
.do6	jsr	(a6,d0)

	move.l	a6,d0
	jsr	closel
	clr.l	_MedPlayerBase(a5)

	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts

.medstop
	movem.l	d0/d1/a0/a1/a6,-(sp)
	move.l	_MedPlayerBase(a5),a6

	moveq	#_LVOMEDStopPlayer,d0
	move.b	medtype(a5),d1
	beq.b	.do7
	moveq	#_LVOMEDStopPlayer8,d0
	subq.b	#1,d1
	beq.b	.do7
	moveq	#_LVOMEDStopPlayerM,d0
.do7	jsr	(a6,d0)

	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts

.medcont
	movem.l	d0/d1/a0/a1/a6,-(sp)
	move.l	_MedPlayerBase(a5),a6
	move.l	moduleaddress(a5),a0

	moveq	#_LVOMEDContModule,d0
	move.b	medtype(a5),d1
	beq.b	.do8
	moveq	#_LVOMEDContModule8,d0
	subq.b	#1,d1
	beq.b	.do8
	moveq	#_LVOMEDContModuleM,d0
.do8	jsr	(a6,d0)

	movem.l	(sp)+,d0/d1/a0/a1/a6
	rts


.medsong
	bsr.w	.medend
	bra.w	.medinit

.id_med 	
	bsr.b 	.id_med_ 
	bne.b	.x 
	clr.b	medrelocced(a5)
.x	rts

.id_med_

	move.l	(a4),d0			* MED
	lsr.l	#8,d0
	cmp.l	#'MMD',d0
	bra.w	idtest




******************************************************************************
* The Player v6.1a
******************************************************************************
guru_author
	pushpea	.a(pc),d0
	rts
.a	dc.b	"Jarno Paananen (Guru/Sahara Surfers)"
	even

  ifne FEATURE_P61A
p_player
	jmp	.p60init(pc)
	p_NOP
	p_NOP
	jmp	.p60end(pc)
	jmp	.p60stop(pc)
	jmp	.p60cont(pc)
	jmp	.p60volume(pc)
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp id_player(pc)
	jmp	guru_author(pc)
	dc.w pt_player
	dc	pf_stop!pf_cont!pf_volume
	dc.b	"The Player 6.1A",0
 even


.p60end
	movem.l	d0-a6,-(sp)
	lea	$dff000,a6
	move.l	p60routines(a5),a0
	jsr	P61_EndOffset(a0)

	bsr.b	.frees

	movem.l	(sp)+,d0-a6
	rts


.frees	move.l	player60samples(a5),d0
	beq.b	.eee
	move.l	d0,a0
	jsr	freemem
	clr.l	player60samples(a5)
.eee	rts

.p60stop
	move.l	p60routines(a5),a0
	clr	P61_PlayFlag(a0)
	bra.w	clearsound
.p60cont
	move.l	p60routines(a5),a0
	st	P61_PlayFlag+1(a0)
	rts

.p60volume
	push	a0
	move.l	p60routines(a5),a0
	move	mainvolume(a5),P61_MasterVolume(a0)
	pop	a0
	rts

.p60init
	lea	p60routines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok
	rts
.ok
	movem.l	d1-a6,-(sp)
	move.l	moduleaddress(a5),a0
	cmp.l	#'P61A',(a0)
	bne.b	.ee
	addq.l	#4,a0
.ee
	btst	#6,3(a0)
	beq.b	.nopacked

	tst.l	player60samples(a5)	* ei uusiks
	bne.b	.nopacked
	move.l	4(a0),d0
	addq.l	#8,d0
	moveq	#MEMF_CHIP,d1
	jsr	getmem
	move.l	d0,player60samples(a5)
	beq.b	.memerr
.nopacked

	move.l	p60routines(a5),a0
	move.b	tempoflag(a5),d0
	not.b	d0
	move.b	d0,P61_UseTempo+1(a0)
	st	P61_PlayFlag+1(a0)
	bsr.b	.p60volume

	move.l	moduleaddress(a5),a0
	moveq	#0,d0
	sub.l	a1,a1
	move.l	player60samples(a5),a2
	lea	$dff000,a6
	move.l	p60routines(a5),a3
	jsr	P61_InitOffset(a3)
	tst	d0
	beq.b	.ok2
;	lea	p60routines(a5),a0
;	bsr.w	freereplayer
	bsr.w	.frees
	moveq	#ier_playererr,d0
.ok2	movem.l	(sp)+,d1-a6
	rts

.memerr	
;	lea	p60routines(a5),a0
;	bsr.w	freereplayer
	moveq	#ier_nomem,d0
	bra.b	.ok2

 
* TODO: both
id_player
 	cmp.l	#'P61A',(a4)		* The player 6.1a
	bra.w	idtest

id_player2				* filename <= D0
	and.l	#$dfffffff,d0
	cmp.l	#'P61.',d0
	bra.w	idtest
  endif	; FEATURE_P61A


******************************************************************************
* Mark II
******************************************************************************

p_markii
	jmp	.markinit(pc)
	jmp	.markmusic(pc)
	p_NOP
	jmp	.markend(pc)
	jmp	clearsound(pc)
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp .id_markii(pc)
	jmp	.author(pc)
	dc.w pt_markii
	dc	pf_stop!pf_cont!pf_ciakelaus
	dc.b	"Mark II",0
.a	dc.b	"Darius Zendeh",0
 even

.author
	pushpea	.a(pc),d0
	rts

.markinit
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2

	pushm	all
	move.l	moduleaddress(a5),a0
	moveq.l	#-1,d0
	jsr	(a0)
	popm	all
	moveq	#0,d0
	rts	

.markmusic
	move.l	moduleaddress(a5),a0
	moveq.l	#0,d0
	moveq.l	#1,d1
	jmp	(a0)

.markend
	pushm	all
	move.l	moduleaddress(a5),a0
	moveq.l	#1,d0
	moveq.l	#1,d1
	jsr	(a0)
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bsr.w	vapauta_kanavat
	popm	all
	rts


.id_markii
	moveq.l	#-1,d0

	cmp	#$48e7,(a4)
	bne.b	.eim
	cmp	#$41fa,4(a4)	
	bne.b	.eim
	cmp	#$4cd8,8(a4)
	bne.b	.eim
	cmp.l	#$0c0000ff,12(a4)
	beq.b	.joom
.eim

	lea	.lbw000106(pc),a1
.lbc0000ea
	move.w	(a1)+,d1
	beq.s	.lbc000104
	cmp.l	#$2e5a4144,$0000(a4,d1.w)
	bne.s	.lbc0000ea
	cmp.l	#$5338392e,$0004(a4,d1.w)
	bne.s	.lbc0000ea
.joom	moveq.l	#0,d0
.lbc000104
	tst.l	d0
	rts	
.lbw000106	dc.w	$02a0,$033c,$0348,0


******************************************************************************
* Maniacs of Noise
******************************************************************************


p_mon	jmp	.moninit(pc)
	jmp	.monmusic(pc)
	p_NOP
	jmp	.monend(pc)
	jmp	clearsound(pc)
	p_NOP
	jmp	.monvol(pc)
	jmp	.monsong(pc)
	p_NOP
	p_NOP
	p_NOP
	jmp .id_maniacsofnoise(pc)
	jmp	.author(pc)
	dc.w pt_mon
	dc	pf_stop!pf_cont!pf_song!pf_volume!pf_ciakelaus
	dc.b	"Maniacs of Noise",0
.a 	dc.b 	"Charles Deenen, Jeroen Tel",0
 even

.author
	pushpea	.a(pc),d0
	rts

.moninit
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2

.init	pushm	all
	moveq.l	#0,d0
	moveq	#0,d1
	move.l	moduleaddress(a5),a0
	push	a5
	jsr	(a0)
	pop	a5
	move.l	a1,.volu
	move	songnumber(a5),d0
	addq	#1,d0
	moveq.l	#0,d1
	move.l	moduleaddress(a5),a0
	push	a5
	jsr	8(a0)
	pop	a5
	bsr.b	.monvol
	popm	all
	moveq	#0,d0 
	rts	

.monvol	move.l	.volu(pc),a0
	move	mainvolume+var_b,(a0)
	rts

.volu	dc.l	0

.monmusic
	move.l	moduleaddress(a5),a0
	jmp	4(a0)

.monend	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat


.monsong
	bsr.w	clearsound
	bra.b	.init


.id_maniacsofnoise
	bsr.b 	.id_maniacsofnoise_
	bne.b 	.not 
	move	d5,maxsongs(a5)
	moveq	#0,d0
.not rts 

.id_maniacsofnoise_
* d5 => max songs

	move.l	a4,a0
;	move.l	modulelength(a5),d1
	move.l	d7,d1

	moveq.l	#-1,d0
	cmp.w	#$4efa,(a0)
	bne.s	.o0001a8
	cmp.w	#$4efa,4(a0)
	bne.s	.o0001a8
	cmp.w	#$4efa,8(a0)
	bne.s	.o0001a8
	cmp.w	#$4efa,12(a0)
	beq.s	.o0001a8
.o00015e	cmp.w	#$4bfa,0(a0)
	bne.s	.o000182
	cmp.w	#$0280,4(a0)
	bne.s	.o000182
	cmp.l	#$000000ff,6(a0)
	bne.s	.o000182
	cmp.l	#$5300b02d,$0014(a0)
	beq.s	.o00018a
.o000182	addq.l	#2,a0
	subq.l	#2,d1
	bpl.s	.o00015e
	bra.s	.o0001a8
 
.o00018a	move.w	2(a0),d1
	lea	0(a0,d1.w),a1
	move.w	$0018(a0),d1
	lea	0(a1,d1.w),a1
	moveq.l	#0,d0
	move.b	2(a1),d0
	subq	#1,d0
	move.w	d0,d5
	moveq.l	#0,d0
.o0001a8
	tst.l	d0
	rts	



******************************************************************************
* David Whittaker
******************************************************************************

p_davidwhittaker
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp 	.id(pc)
	jmp	deliAuthor(pc)
	dc  	pt_davidwhittaker
.flags	dc 	pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"David Whittaker     [EP]",0
	        
.path 	dc.b "david whittaker",0
 	even

.init
	lea	.path(pc),a0 
	moveq	#0,d0
	bsr.w	deliLoadAndInit
	rts

.id
	move.l	a4,a0
	MOVEQ	#-1,D0
	MOVE.L	A0,A1
	CMP.L	#$48E7F1FE,(A1)
	BNE.S	.lbC0003DC
	ADDQ.L	#4,A1
	CMP.W	#$6100,(A1)+
	BNE.S	.lbC000410
	ADD.W	(A1),A1
	MOVEQ	#9,D1
.lbC0003C4	CMP.W	#$47FA,(A1)+
	BEQ.S	.lbC0003D0
	DBRA	D1,.lbC0003C4
	RTS

.lbC0003D0	BSR.b	.lbC000424
	TST.L	D2
	BNE.S	.lbC000410
	BRA.S	.lbC00040E

.lbC0003DC	CMP.L	#$8F90001,(A1)
	BEQ.S	.lbC000412
	CMP.L	#$4E714E71,(A1)
	BEQ.S	.lbC000410
	CMP.W	#$47FA,(A1)+
	BEQ.S	.lbC000406
	MOVEQ	#3,D1
.lbC0003F4	CMP.W	#$47FA,(A1)+
	BEQ.S	.lbC000400
	DBRA	D1,.lbC0003F4
	RTS

.lbC000400	ADD.W	(A1),A1
	CMP.L	A0,A1
	BNE.S	.lbC000410
.lbC000406	
	BSR.S	.lbC000424
	TST.L	D2
	BNE.S	.lbC000410
.lbC00040C	
.lbC00040E	MOVEQ	#0,D0
.lbC000410	RTS

.lbC000412	ADDQ.L	#4,A1
	CMP.L	#$BFE001,(A1)+
	BNE.S	.lbC000410
	BSR.S	.lbC000424
	TST.L	D2
	BEQ.S	.lbC00040C
	RTS

.lbC000424	MOVEQ	#$7F,D1
.lbC000426	CMP.W	#$6100,(A1)+
	BEQ.S	.lbC000434
	DBRA	D1,.lbC000426
.lbC000430	MOVEQ	#-1,D2
	RTS

.lbC000434	ADD.W	(A1),A1
	MOVEQ	#$7F,D1
	CMP.L	#$48E7F1FE,(A0)
	BNE.S	.lbC00044A
	ADDQ.L	#4,A1
	CMP.W	#$6100,(A1)+
	BNE.S	.lbC000430
	ADD.W	(A1),A1
.lbC00044A	CMP.W	#$4E75,(A1)
	BEQ.S	.lbC000430
	CMP.W	#$2F0B,(A1)
	BEQ.S	.lbC000466
	CMP.L	#$DFF0C8,(A1)
	BEQ.S	.lbC000466
	ADDQ.L	#2,A1
	DBRA	D1,.lbC00044A
	BRA.S	.lbC000430

.lbC000466	MOVEQ	#0,D2
	RTS
 


******************************************************************************
* Hippel-COSO
******************************************************************************


;	jmp	ini(pc)
;	jmp	Int(pc)
;	jmp	end(pc)
;	jmp	SetVol(pc)
;	jmp	ahi_update(pc)
;	jmp	ahi_pause(pc)

hippel_author
	pushpea	.a(pc),d0
	rts
.a 	dc.b	"Jochen 'Mad Max' Hippel",0
 	even


p_hippelcoso
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	jmp	.cont(pc)
	jmp	.volume(pc)
	jmp	.song(pc)
	p_NOP
	p_NOP
	jmp	.ahiupdate(pc)
	jmp id_hippelcoso(pc)
	jmp	hippel_author(pc)
	dc.w pt_hippelcoso
.liput	dc pf_cont!pf_stop!pf_end!pf_volume!pf_song!pf_ciakelaus!pf_ahi!pf_scope!pf_quadscopePoke
	dc.b	"Hippel-COSO",0
 even

.stop
	tst.b	ahi_use_nyt(a5)
	beq.w	clearsound

.a	move.l	hippelcosoroutines(a5),a0
	jmp	$20+20(a0)

.cont
	tst.b	ahi_use_nyt(a5)
	bne.b	.a
	rts

.init
	tst.b	ahi_use(a5)
	bne.b	.ahi

	or	#pf_ciakelaus,.liput

	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	hippelcosoroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
.gog	bsr.w	rem_ciaint
	bra.w	vapauta_kanavat
;	rts

.ahi	and	#~pf_ciakelaus,.liput

	lea	hippelcosoroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok4
	rts

.ok3	
	bsr.w	siirra_moduuli
	bne.b	.gog
.ok4

	move.l	moduleaddress(a5),a0
	lea	songover(a5),a1
	moveq	#0,d0
	move	songnumber(a5),d0
	addq	#1,d0
	lea	dmawait(pc),a2
	lea	scopeData(a5),a3

	move.l	modulelength(a5),d1
	move.b	ahi_use(a5),d2
	move.l	ahi_mode(a5),d3
	move.l	ahi_rate(a5),d4

* d0 = songnumber
* d1 = modulelength
* d2 = use ahi
* d3 = ahi mode
* d4 = ahi rate
* a0 = module
* a1 = songend
* a2 = dmawait
* a3 = scope

	move.l	hippelcosoroutines(a5),a4
	jsr	$20+0(a4)
	tst.l	d0
	bne.b	.ER

	bsr.b	.volume
	moveq	#0,d0
.ER	rts	


.play	move.l	hippelcosoroutines(a5),a0
	jmp	$20+4(a0)

.end
	tst.b	ahi_use_nyt(a5)
	bne.b	.ahien

	bsr.w	rem_ciaint
	pushm	all
	move.l	hippelcosoroutines(a5),a0
	jsr	$20+8(a0)
	popm	all
	bsr.w	clearsound
	bra.w	vapauta_kanavat

.ahien	move.l	hippelcosoroutines(a5),a0
	jmp	$20+8(a0)

.volume
	moveq	#64,d0
	sub	mainvolume(a5),d0
	move.l	hippelcosoroutines(a5),a0
	jmp	$20+12(a0)
	
.song
	move.l	hippelcosoroutines(a5),a0
	jsr	$20+8(a0)
	tst.b	ahi_use_nyt(a5)
	bne.b	.sa
	bsr.w	clearsound
.sa	bra.w	.ok3



.ahiupdate
	move.l	hippelcosoroutines(a5),a0
	jmp	$20+16(a0)




id_hippelcoso 
	bsr.b 	.id_hippelcoso_
	bne.b .x 
	move	d5,maxsongs(a5)
	moveq	#0,d0 
.x 	rts


; Testet, ob es sich um ein Hippel-COSO-Modul handelt

.id_hippelcoso_
* d5 => max songs

;	move.l	dtg_ChkData(a5),a0		; ^module
	move.l	a4,a0

	cmpi.l	#"COSO",$00(a0)			; test ID
	bne.b	.ChkFail
	cmpi.l	#"TFMX",$20(a0)			; test ID
	bne.s	.ChkFail

	move.l	$1c(a0),d0
	sub.l	$18(a0),d0
	bmi.s	.ChkFail				; table corrupt !
	divu	#10,d0
	swap	d0
	tst.w	d0				; multiple of 10 ?
	bne.s	.ChkFail				; no !
	swap	d0
	subq.w	#1,d0
	beq.s	.ChkFail				; sampletable is empty !
	move.l	a0,a1
	add.l	$18(a0),a1			; ^sampletable
	move.l	a1,a2
	moveq	#0,d2
.Chkoop move.l	(a1),d1				; ^samplestart
	cmp.l	d2,d1
	ble.b	.Chkext
	move.l	d1,d2
	move.l	a1,a2
.Chkext add.w	#10,a1				; next sample
	subq.l	#1,d0
	bne.s	.Chkoop

	move.l	$1c(a0),d0			; ^samples
	move.l	d0,d1
	add.l	(a2)+,d1			; get samplestart
	moveq	#0,d2
	move.w	(a2)+,d2			; get samplelength
	add.l	d2,d2
	add.l	d2,d1
	addq.l	#4,d1				; 4 bytes null-sample


;	move.l	modulelength(a5),d2

;	cmp.l	d1,d2
;;	slt	LoadSamp			; set load-samples flag
;	blt.b	.ChkFail		* ei hyv‰ksyt‰ modeja joissa erilliset samplet


;	add.l	#1024,d1
;	cmp.l	d0,d2				; test size of module
;	blt.s	.ChkFail				; too small
;	cmp.l	d1,d2				; test size of module
;	bgt.s	.ChkFail				; too big

	move.l	$18(a4),d0
	sub.l	$14(a4),d0
	divu	#6,d0
	subq.w	#2,d0
	move.w	d0,d5				; store MaxSong
	moveq	#0,d0				; Modul erkannt

	bra.s	.Chknd
.ChkFail
	moveq	#-1,d0				; Modul nicht erkannt
.Chknd
	tst.l	d0
	rts



******************************************************************************
* Hippel
******************************************************************************

p_hippel
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	clearsound(pc)
	p_NOP
	p_NOP
	jmp	.song(pc)
	p_NOP
	p_NOP
	p_NOP
	jmp id_hippel(pc)
	jmp	hippel_author(pc)
	dc.w pt_hippel
	dc	pf_cont!pf_stop!pf_song!pf_ciakelaus
	dc.b	"Hippel",0
 even

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2

	move	songnumber(a5),d0
	addq	#1,d0
	move.l	moduleaddress(a5),a0
	jsr	(a0)
	moveq	#0,d0
	rts	


.play	
	move.l	hippelmusic(pc),a0
	jmp	(a0)

.end
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat



.song
	bsr.w	clearsound
	bra.b	.ok2


hippelmusic	dc.l	0





id_hippel 
	push	d7
	bsr.b 	.id_hippel_
	pop	d7
	tst.l	d0
	bne.b .x 
	move.l	d4,hippelmusic
	move	d5,maxsongs(a5)
	moveq	#0,d0 
.x 	rts



.id_hippel_
* d7 <= modlen
* a4 <= mod
* d4 => hippel music 
* d5 => max songs

	* check some data, not all, too slow otherwise
	cmp.l	#1024*4,d7
	blo.b	.ok
	move.l	#1024*4,d7
.ok
	move.l	d7,d0

	cmp.l	#100,d0
	blo.w	.lbC000288

	move.l	a4,a0
	move.l	a4,a1
	add.l	d0,a1
	lea	$10(a0),a0
.loop	addq	#1,a0	
	cmp.l	a0,a1
	beq.w	.ChkFail
	cmp.b	#"T",(a0)
	bne.b	.loop
	cmp.b	#"F",1(a0)
	bne.b	.loop
	cmp.b	#"M",2(a0)
	bne.b	.loop
	cmp.b	#"X",3(a0)
	bne.b	.loop

	move.l	a4,a1
	move.l	a1,a0
	move.l	d7,d0

	cmp.w	#$6000,(a1)
	bne.s	.lbC000156
	addq.w	#2,a1
	move.w	(a1),d1
	bmi.s	.lbC0001B6
	btst	#0,d1
	bne.s	.lbC0001B6
	add.w	d1,a1
	bra.s	.lbC00016E
 
.lbC000156	cmp.b	#$60,(a1)
	bne.s	.lbC0001B6
	move.b	1(a1),d1
	ext.w	d1
	bmi.s	.lbC0001B6
	btst	#0,d1
	bne.s	.lbC0001B6
	add.w	d1,a1
	addq.w	#2,a1
.lbC00016E	addq.w	#4,a1
	cmp.w	#$6100,(a1)
	bne.s	.lbC000186
	addq.w	#2,a1
	move.w	(a1),d1
	bmi.s	.lbC0001B6
	btst	#0,d1
	bne.s	.lbC0001B6
	add.w	d1,a1
	bra.s	.lbC00018E
 
.lbC000186	cmp.w	#$41FA,(a1)
	bne.s	.lbC0001B6
	addq.w	#4,a1
.lbC00018E	addq.w	#2,a1
	cmp.w	#$6100,(a1)+
	bne.s	.lbC0001B6
	move.w	(a1),d1
	bmi.s	.lbC0001B6
	btst	#0,d1
	bne.s	.lbC0001B6
	add.w	d1,a1
	cmp.w	#$41FA,(a1)+
	bne.s	.lbC0001B6
	move.w	(a1),d1
	bmi.s	.lbC0001B6
	btst	#0,d1
	bne.s	.lbC0001B6
	add.w	d1,a1
	clr.w	(a1)
.lbC0001B6	cmp.b	#$60,(a0)
	bne.s	.lbC0001D0
	cmp.b	#$60,2(a0)
	bne.s	.lbC0001D0
	cmp.w	#$48E7,4(a0)
	bne.s	.lbC0001D0
	addq.l	#2,a0
	bra.s	.lbC00022C
 
.lbC0001D0	cmp.b	#$60,(a0)
	bne.s	.lbC0001EA
	cmp.b	#$60,2(a0)
	bne.s	.lbC0001EA
	cmp.w	#$41FA,4(a0)
	bne.s	.lbC0001EA
	addq.l	#2,a0
	bra.s	.lbC00022C
 
.lbC0001EA	cmp.w	#$6000,(a0)
	bne.s	.lbC000204
	cmp.w	#$6000,4(a0)
	bne.s	.lbC000204
	cmp.w	#$48E7,8(a0)
	bne.s	.lbC000204
	addq.l	#4,a0
	bra.s	.lbC00022C
 
.lbC000204	cmp.w	#$6000,(a0)
	bne.s	.lbC000288
	cmp.w	#$6000,4(a0)
	bne.s	.lbC000288
	cmp.w	#$6000,8(a0)
	bne.s	.lbC000288
	cmp.w	#$6000,12(a0)
	bne.s	.lbC000288
	cmp.w	#$48E7,$0010(a0)
	bne.s	.lbC000288
	addq.l	#4,a0
.lbC00022C	move.l	a0,d4
	move.w	#$007F,d1
.lbC000236	cmp.w	#$41FA,(a0)+
	bne.s	.lbC00026C
	move.w	(a0),d2
	bmi.s	.lbC00026C
	btst	#0,d2
	bne.s	.lbC00026C
	cmp.w	#$4000,d2
	bcc.s	.lbC00026C
	cmp.l	#'TFMX',$0000(a0,d2.w)
	bne.s	.lbC00025C
	move.w	$0010(a0,d2.w),d3
	bra.s	.lbC000274
 
.lbC00025C	cmp.l	#'COSO',$0000(a0,d2.w)
	bne.s	.lbC00026C
	move.w	#$00FF,d3
	bra.s	.lbC000274
 
.lbC00026C	subq.l	#2,d0
	dbmi	d1,.lbC000236
	bra.s	.lbC000288
 
.lbC000274
	subq.b	#1,d3
	move.w	d3,d5
	moveq	#0,d0
	rts	

.lbC000288
.ChkFail
	moveq.l	#-1,d0
	rts	




******************************************************************************
* Digibooster
******************************************************************************

db_author
	pushpea	.a(pc),d0
	rts
.a 	dc.b 	"Tomasz & Waldemar Piasta",0
	even

p_digibooster
	jmp	.init(pc)
	p_NOP
	jmp	.vb(pc)
	jmp	.end(pc)
	jmp	.stop(pc)
	jmp	.cont(pc)
	jmp	.volu(pc)
	p_NOP
	jmp	.eteen(pc)
	jmp	.taakse(pc)
	p_NOP
	jmp .id_digibooster(pc)
	jmp	db_author(pc)
	dc.w pt_digibooster
	dc	pf_poslen!pf_kelaus!pf_volume!pf_stop!pf_cont!pf_end
	dc.b	"DIGI Booster",0
 even

.stop
	clr.b	.stopcont
	move	#$f,$dff096
	rts

.cont
	st	.stopcont
	move	#$800f,$dff096
	rts


.volu
	move.l	.vol(pc),a0
	move	mainvolume(a5),(a0)
	rts

.vb
	move.l	.pos(pc),a0
	move.b	(a0),pos_nykyinen+1(a5)
	move.l	.maxpos(pc),a0
	move.b	(a0),pos_maksimi+1(a5)
	rts



.eteen
	move	pos_maksimi(a5),d0
	move	pos_nykyinen(a5),d1
	addq	#1,d1
	cmp	d0,d1
	blo.b	.a
	clr	d1
.a
	move.l	.pos(pc),a0
	move.b	d1,(a0)
	move.l	.pattpos(pc),a0
	clr.b	(a0)

	rts
.taakse
	move.l	.pos(pc),a0
	move.b	(a0),d0
	subq.b	#1,d0
	bpl.b	.b
	clr.b	d0
.b	move.b	d0,(a0)
	move.l	.pattpos(pc),a0
	clr.b	(a0)
	move.b	d0,pos_nykyinen+1(a5)
	rts




.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	

	lea	digiboosterroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bra.w	vapauta_kanavat
;	rts

.ok3	

	push	a5
	move.l	moduleaddress(a5),a0
	lea	songover(a5),a1
	lea	.stopcont(pc),a2
	st	(a2)

	DPRINT	"DIGIBooster init"
	move.l	digiboosterroutines(a5),a3
	jsr	$20+0(a3)
	pop	a5
	tst.l	d0
	bne.b	.er


;	lea	songpos(pc),a0
;	move.l	moddigi(pc),a1
;	lea	ordnum(a1),a1
;	lea	pattpos(pc),a2
* 	a3 = vol

	movem.l	a0-a3,.pos
	bsr.w	.volu

	DPRINT	"ok"

	moveq	#0,d0
	rts	

.stopcont dc	0
.pos	dc.l	0
.maxpos	dc.l	0
.pattpos dc.l	0
.vol	dc.l	0



; d7 =  0  all right
; d7 = -1  not enough memory for mixbuffers
; d7 = -2  cant alloc cia timers


.er	bsr.w	vapauta_kanavat

	addq	#1,d0
	bne.b	.cia
	moveq	#ier_nomem,d0
	rts

.cia	moveq	#ier_nociaints,d0
	rts



.end	pushm	all
	move.l	digiboosterroutines(a5),a0
	jsr	$20+4(a0)
	popm	all
	bra.w	vapauta_kanavat


.id_digibooster
	bsr.b 	id_digibooster_
	bne.b 	.x 
	bsr.w	moveModuleToPublicMem		* siirret‰‰n fastiin jos mahdollista
	lea	610(a4),a1
	moveq	#30-1,d0
	bsr.w	copyNameFromA1
	moveq	#0,d0
.x 	rts

id_digibooster_
	cmp.l	#'DIGI',(a4)
	bne.b	.nd
	cmp.l	#' Boo',4(a4)
	bne.b	.nd
	cmp.l	#'ster',8(a4)
	bra.w	idtest

.nd	moveq	#-1,d0
	rts

******************************************************************************
* Digibooster PRO
******************************************************************************


p_digiboosterpro
	jmp	.init(pc)
	p_NOP
	jmp	.vb(pc)
	jmp	.end(pc)
	jmp	.stop(pc)
	jmp	.cont(pc)
	p_NOP
	p_NOP
	jmp	.eteen(pc)
	jmp	.taakse(pc)
	jmp	.ahiupdate(pc)
	jmp .id_digiboosterpro(pc)
	jmp	db_author(pc)
	dc.w pt_digiboosterpro
	dc	pf_volume!pf_stop!pf_cont!pf_ahi!pf_poslen!pf_kelaus!pf_end
	dc.b	"DIGI Booster Pro",0
 even

.stop
.cont
	move.l	digiboosterproroutines(a5),a0
	jmp	8+$20(a0)

.ahiupdate
	rts	* omat pannaukset ja autoboostit
	
;	move.l	digiboosterproroutines(a5),a0
;	jmp	12+$20(a0)

.vb

	move.l	.songp(pc),a0
	move	(a0),pos_nykyinen(a5)
	move.l	.ordn(pc),a0
	move	(a0),pos_maksimi(a5)
	rts


.init
	move.l	(a5),a0
	btst	#AFB_68020,AttnFlags+1(a0)
	bne.b	.okk
	moveq	#ier_hardware,d0
	rts
.okk


	lea	digiboosterproroutines(a5),a0
	bsr.w	allocreplayer
	bne.b	.x

	move.l	moduleaddress(a5),a0
	move.l	modulelength(a5),d4
	
	move.l	ahi_rate(a5),d0
	move	ahi_mastervol(a5),d1
	move	ahi_stereolev(a5),d2
	move.l	ahi_mode(a5),d3
	move.l	digiboosterproroutines(a5),a1
	lea	mainvolume(a5),a2
	lea	songover(a5),a3

	st	ahi_use_nyt(a5)

	pushm	d1-a6
	jsr	$20+0(a1)

	movem.l	a0/a1/a2,.songp

	popm	d1-a6

	DPRINT	"DIGIBooster pro init: %ld"
	
	tst.l	d0
	beq.b	.x
	moveq	#ier_error,d0

;	moveq	#0,d0
.x	rts	

.end
	pushm	all
	clr.b	ahi_use_nyt(a5)
	move.l	digiboosterproroutines(a5),a1
	jsr	$20+4(a1)
	popm	all
	rts




.eteen
	move	pos_maksimi(a5),d0
	move	pos_nykyinen(a5),d1
	addq	#1,d1
	cmp	d0,d1
	blo.b	.a
	clr	d1
.a
	move.l	.songp(pc),a0
	move	d1,(a0)
	move.l	.pattpos(pc),a0
	clr	(a0)

	rts
.taakse
	move.l	.songp(pc),a0
	move	(a0),d0
	subq	#1,d0
	bpl.b	.b
	clr	d0
.b	move	d0,(a0)
	move.l	.pattpos(pc),a0
	clr	(a0)
	move	d0,pos_nykyinen(a5)
	rts




.songp	dc.l	0
.ordn	dc.l	0
.pattpos dc.l	0


.id_digiboosterpro
	bsr.b 	id_digiboosterpro_
	bne.b 	.y 
	bsr.w	moveModuleToPublicMem		* siirret‰‰n fastiin jos mahdollista
	move.l	moduleaddress(a5),a1
	lea	16(a4),a1
	moveq	#42-1,d0	
	bsr.w	copyNameFromA1
	moveq	#0,d0
.y 	rts

id_digiboosterpro_
	cmp.l	#'DBM0',(a4)
	bra.w	idtest

******************************************************************************
* THX
******************************************************************************

thx_author
	pushpea	.a(pc),d0
	rts
.a 	dc.b	"Dexter & Pink/aBYSs",0
	even 

p_thx
	jmp	.init(pc)
	jmp .ahxCIAInterrupt(pc)
	p_NOP   ; vb not used
	jmp	.end(pc)
	jmp	.stop(pc)
	jmp	.cont(pc)
	jmp	.volu(pc)
	jmp	.song(pc)
	jmp	.eteen(pc)
	jmp	.taakse(pc)
	p_NOP
	jmp 	.id_thx(pc)
	jmp	thx_author(pc)
	dc.w 	pt_thx
	dc	pf_cont!pf_stop!pf_volume!pf_end!pf_song!pf_kelaus!pf_poslen!pf_scope!pf_quadscopePoke
	dc.b	"AHX Sound System",0
 even


.ahxInitCIA          = 0*4
.ahxInitPlayer       = 1*4
.ahxInitModule       = 2*4
.ahxInitSubSong      = 3*4
.ahxInterrupt        = 4*4
.ahxStopSong         = 5*4
.ahxKillPlayer       = 6*4
.ahxKillCIA          = 7*4
.ahxNextPattern      = 8*4   ;implemented, although no-one requested it :-)
.ahxPrevPattern      = 9*4   ;implemented, although no-one requested it :-)

.ahxBSS_P            = 10*4  ;pointer to ahx's public (fast) memory block
.ahxBSS_C            = 11*4  ;pointer to ahx's explicit chip memory block
.ahxBSS_Psize        = 12*4  ;size of public memory (intern use only!)
.ahxBSS_Csize        = 13*4  ;size of chip memory (intern use only!)
.ahxModule           = 14*4  ;pointer to ahxModule after InitModule
.ahxIsCIA            = 15*4  ;byte flag (using ANY (intern/own) cia?)
.ahxTempo            = 16*4  ;word to cia tempo (normally NOT needed to xs)

.ahx_pExternalTiming = 0         ;byte, offset to public memory block
.ahx_pMainVolume     = 1         ;byte, offset to public memory block
.ahx_pSubsongs       = 2         ;byte, offset to public memory block
.ahx_pSongEnd        = 3         ;flag, offset to public memory block
.ahx_pPlaying        = 4         ;flag, offset to public memory block
.ahx_pVoice0Temp     = 14        ;struct, current Voice 0 values
.ahx_pVoice1Temp     = 246       ;struct, current Voice 1 values
.ahx_pVoice2Temp     = 478       ;struct, current Voice 2 values
.ahx_pVoice3Temp     = 710       ;struct, current Voice 3 values

.ahx_currentSongPos	= $448+4
.ahx_maxSongPos 	= $44c+4
.ahx_currentPattPos 	= $44a

.ahx_pvtTrack        = 0         ;byte          (relative to ahx_pVoiceXTemp!)
.ahx_pvtTranspose    = 1         ;byte          (relative to ahx_pVoiceXTemp!)
.ahx_pvtNextTrack    = 2         ;byte          (relative to ahx_pVoiceXTemp!)
.ahx_pvtNextTranspose= 3         ;byte          (relative to ahx_pVoiceXTemp!)
.ahx_pvtADSRVolume   = 4         ;word, 0..64:8 (relative to ahx_pVoiceXTemp!)
.ahx_pvtAudioPointer = 92        ;pointer       (relative to ahx_pVoiceXTemp!)
.ahx_pvtAudioPeriod  = 100       ;word          (relative to ahx_pVoiceXTemp!)
.ahx_pvtAudioVolume  = 102       ;word          (relative to ahx_pVoiceXTemp!)

; current ADSR Volume (0..64) = ahx_pvtADSR.w >> 8        (I use 24:8 32-Bit)
; ahx_pvtAudioXXX are the REAL Values passed to the hardware!



.eteen	move.l	thxroutines(a5),a0
	jmp	.ahxNextPattern(a0)

.taakse	move.l	thxroutines(a5),a0
	jmp	.ahxPrevPattern(a0)


.stop
	move	#$f,$dff096
	bra.b	.sc

.cont	move	#$800f,$dff096
.sc	move.l	thxroutines(a5),a0
	move.l	.ahxBSS_P(a0),a0
	not.b	.ahx_pPlaying(a0)
	rts

	

.volu	move.l	thxroutines(a5),a0
	move.l	.ahxBSS_P(a0),a0
	move.b	mainvolume+1(a5),.ahx_pMainVolume(a0)
	rts

.updateInfo
	move.l	thxroutines(a5),a0
	move.l	.ahxBSS_P(a0),a0

	move	.ahx_currentSongPos(a0),pos_nykyinen(a5)
	move	.ahx_maxSongPos(a0),pos_maksimi(a5)

	tst.b	.ahx_pSongEnd(a0)
	beq.b	.x
	clr.b	.ahx_pSongEnd(a0)
	st	songover(a5)
.x	rts




.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	thxroutines(a5),a0
	bsr.w	allocreplayer
	bne.w	vapauta_kanavat
	beq.b	.ok3
	bra.w	vapauta_kanavat

.ok3	
	DPRINT	"AHX init"
	pushm	d1-a6

;	lea	.ahxCIAInterrupt(pc),a0
;	moveq	#0,d0
;	move.l	thxroutines(a5),a2
;	jsr	.ahxInitCIA(a2)
;	tst	d0
;	bne.w	.thxInitFailed2

	moveq	#0,d0	* loadwavesfile if possible
	moveq	#0,d1	* calculate filters (ei thx v 1.xx!!)

	move.l	moduleaddress(a5),a0
	tst.b	3(a0)
	bne.b	.new
	moveq	#1,d1	* ei filttereit‰!
.new

	sub.l   a0,a0	* auto alloc fast mem
	sub.l   a1,a1	* auto alloc chip
	lea	ciaint_setTempoFromD0(pc),a2 * pass CIA timer poke routine
	move.l	thxroutines(a5),a3
	jsr	setMainWindowWaitPointer
	jsr	.ahxInitPlayer(a3)
	jsr	clearMainWindowWaitPointer
	tst	d0
	beq.b	.ok4

;	move.l	thxroutines(a5),a3
;	jsr	.ahxKillCIA(a3)
	bsr.w	vapauta_kanavat
	moveq	#ier_nomem,d0
	bra.b	.xxx
.ok4
	
	moveq	#0,d0			* normal speed
	move.l	moduleaddress(a5),a0
	jsr	.ahxInitModule(a3)
	tst	d0
	bne.b	.thxInitFailed

	move.l	.ahxBSS_P(a3),a0
	clr	maxsongs(a5)
	move.b	.ahx_pSubsongs(a0),maxsongs+1(a5)

	moveq	#0,d0
	move	songnumber(a5),d0
	moveq   #0,d1
	jsr	.ahxInitSubSong(a3)

	bsr.w	.volu
	bsr.w	.patternInit

	popm	d1-a6

	pushpea	.PatternInfo(pc),deliPatternInfo(a5)
	moveq	#0,d0
	rts	

.thxInitFailed
;	move.l	thxroutines(a5),a2
;	jsr	.ahxKillCIA(a2)
.thxInitFailed2
	
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
.xxx
	popm	d1-a6
	rts


.ahxCIAInterrupt
	move.l	thxroutines(a5),a0
	* All regs preserved:
	jsr	.ahxInterrupt(a0)
	bsr		.updateInfo
	bra.w	.updateStripes

.end	DPRINT	"AHX end"
	bsr.w	rem_ciaint
	bsr.b	.halt
	bra.w	vapauta_kanavat

.song	bsr.b	.halt
	bra.w	.ok3

.halt	
;	pushm	all
;	move.l	thxroutines(a5),a2
;	jsr	.ahxKillCIA(a2)
;	popm	all
.halt2	move.l	thxroutines(a5),a2
	jsr	.ahxStopSong(a2)
	jsr	.ahxKillPlayer(a2)
	
	bra.w	clearsound

* Scope support
* Update scope data once per vblank
.updateScope
	lea	scopeData+scope_ch1(a4),a0
	move.l	thxroutines(a4),a1
	move.l	.ahxBSS_P(a1),a1
	lea	.ahx_pVoice0Temp(a1),a1

	moveq	#4-1,d0
.scope
	tst.l	ns_start(a0)
	bne.b	.same
	* This needs tobe done only once it seems
	move.l	.ahx_pvtAudioPointer(a1),ns_start(a0)
	move.l	.ahx_pvtAudioPointer(a1),ns_loopstart(a0)
	move	#$140,ns_length(a0)
	move	#$140,ns_replen(a0)
.same
	move	.ahx_pvtAudioPeriod(a1),ns_period(a0)
	move	.ahx_pvtAudioVolume(a1),ns_tempvol(a0)
	move	.ahx_pvtAudioVolume(a1),d1
	CLAMPVOL d1
	move	d1,ns_tempvol(a0)

	lea	232(a1),a1	* Next channel data 
	lea	ns_size(a0),a0
	dbf	d0,.scope
.xx	rts


* Pattern scope support

.updateStripes
	pushm	d0-d1/a0-a4
	move.l	a5,a4
	bsr.b	.updateScope

	* Skip if not needed
	tst.b	patternScopeRunning(a4)
	beq.b	.noUpd

	move.l	thxroutines(a4),a0
	move.l	.ahxBSS_P(a0),a0

	tst.b	.ahx_pPlaying(a0)
	beq.b	.noUpd
	
	move	.ahx_currentPattPos(a0),.PatternInfo+PI_Pattpos
	lea	.ahx_pVoice0Temp(a0),a0

	move.l	moduleaddress(a4),a1
	lea	.PatternInfo+PI_NoteTranspose1(pc),a2
	lea	.Stripe1(pc),a3

	* Get SS, number of subsongs
	moveq	#0,d1
	move.b	13(a1),d1
	* Subsong list length in bytes:
	add	d1,d1
	* Skip over subsong list 
	lea	14(a1,d1),a4
	* Get LEN, length of the position list
	move	6(a1),d1
	and	#$fff,d1
	* Position list length in bytes:
	lsl	#3,d1
	* Skip over position list,
	* A4 now points to the 1st track data
	add	d1,a4
	* Get TRL, track length
	moveq	#0,d0
	move.b	10(a1),d0
	* Track length in bytes
	mulu	#3,d0

	bsr.b	.doStripe
	bsr.b	.doStripe
	bsr.b	.doStripe
	bsr.b	.doStripe
.noUpd
	popm	d0-d1/a0-a4
	rts

.doStripe
	move.b	.ahx_pvtTranspose(a0),(a2)+
	moveq	#0,d1
	move.b	.ahx_pvtTrack(a0),d1
	lea	232(a0),a0	* Next channel data 

	* If bit 7 of byte 6 is 1, track 0 is included. 
	* If it is 0, track 0 was empty, and is
        * therefore not saved with the module, to save space.
	tst.b	6(a1)
	bmi.b	.notZero
	* Track 0 not included.
	tst.b	d1
	bne.b	.1
	* Track 0 is an empty stripe
.goZero	clr.l	(a3)+
	rts
.notZero
	subq.b	#1,d1
	bmi.b	.goZero
.1
	* Get current track offset
	mulu	d0,d1
	* Address of current track
	add.l 	a4,d1
	* Into the stripe array
	move.l	d1,(a3)+
	rts

.patternInit
	lea	.PatternInfo(PC),A0
	move.w	#4,PI_Voices(A0)	; Number of stripes (MUST be at least 4)
	pea	.ConvertNote(pc) 
	move.l	(sp)+,PI_Convert(a0)
	moveq	#3,D0
	move.l	D0,PI_Modulo(A0)	; Number of bytes to next row
	move.l	moduleaddress(a5),a1
	move.b	10(a1),d0 		* TRL, track length 1-64
	move.w	d0,PI_Pattlength(A0)	; Length of each stripe in rows
	clr.w	PI_Pattpos(A0)		; Current Position in Pattern (from 0)
	move	#-1,PI_Speed(a0)	; Magic! Indicates notes, not periods
	rts

* Called by the PI engine to get values for a particular row
* Each entry is 24 bits (3 bytes) long, and consists of
* bits 23-18 (6 bits): The note. This ranges from 0 (no note) to 60 (B-5)
* bits 17-12 (6 bits): The sample. This ranges from 0 to 63.
* bits 11-8  (4 bits): The command. See list below
* bits 7-0   (8 bits): The command's data. See list below

.ConvertNote
	moveq	#0,D0		; Period, Note
	moveq	#0,D1		; Sample number
	moveq	#0,D2		; Command 
	moveq	#0,D3		; Command argument
	
	* 01234567 01234567 01234567
	* nnnnnnSS SSSScccc PPPPPPPP

	move.b	(a0),d0
	rol	#8,d0
	move.b	1(a0),d0

	moveq	#$f,d2
	and.b	d0,d2 	* cmd
	
	lsr	#4,d0
	moveq	#%111111,d1
	and.b	d0,d1	* sample

	lsr	#6,d0	* note
	beq.b 	.noNote


	lea	PI_NoteTranspose1(a1),a3
	add	PI_CurrentChannelNumber(a1),a3
	add.b	(a3),d0
	ext	d0

	* Up one octaves to allow negative transpose
	add	#1*12,d0

.noNote

	move.b	2(a0),d3	* arg
	rts

.PatternInfo 		ds.b	PI_Stripes	
.Stripe1		dc.l	1
.Stripe2		dc.l	1
.Stripe3		dc.l	1
.Stripe4		dc.l	1

.id_thx 
	bsr.b id_thx_
	bne.b	.y
	move.l	moduleaddress(a5),a1
	add	4(a1),a1		* modulename
	moveq	#25-1,d0
	bsr.w	copyNameFromA1
	moveq	#0,d0
.y 	rts

id_thx_
	move.l	(a4),d0			* THX
	lsr.l	#8,d0
	cmp.l	#"THX",d0
	bra.w	idtest


******************************************************************************
* MusiclineEditor
******************************************************************************

p_mline
	jmp	.init(pc)
	p_NOP
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	jmp	.cont(pc)
	jmp	.volume(pc)
	jmp	.song(pc)
	p_NOP
	p_NOP
	p_NOP
	jmp id_mline(pc)
	jmp	.author(pc)
	dc.w pt_mline
	dc	pf_cont!pf_stop!pf_volume!pf_song
	dc.b	"MusiclineEditor",0
.a 	dc.b	"Conny Cyreus, Christian Cyreus, Jimmy Fredriksson, John Carehag",0
 even
	
.author
	pushpea	.a(pc),d0
	rts

._LVOInitPlayer		=	-30
._LVOEndPlayer		=	-36
._LVOStartPlay		=	-42
._LVOStopPlay		=	-48
._LVOInitTune		=	-54
._LVOMasterVol		=	-60
._LVOSubTuneRange	=	-66
._LVOSelectTune		=	-72
._LVONextTune		=	-78
._LVOPrevTune		=	-84
._LVOCheckModule	=	-90


.init
	lea	-200(sp),sp
	move.l	sp,a4

	lea	arcdir(a5),a0
	move.l	a4,a1
.c	move.b	(a0)+,(a1)+
	bne.b	.c
	subq	#1,a1
	cmp.b	#':',-1(a1)
	beq.b	.cc
	cmp.b	#'/',-1(a1)
	beq.b	.cc
	move.b	#'/',(a1)+
.cc
	lea	.foo(pc),a0
.c2	move.b	(a0)+,(a1)+
	bne.b	.c2

	move.l	a4,a0
	move.l	moduleaddress(a5),a1
	move.l	modulelength(a5),d0
	bsr.w	plainSaveFile
	bmi.b	.orr

	bsr.w	get_mline
	bne.b	.ok0
	lea	200(sp),sp
	moveq	#ier_nomled,d0
	rts
.ok0
	move.l	a4,a0
	move.l	_MlineBase(a5),a6
	jsr	._LVOInitPlayer(a6)
	tst.l	d0
	beq.b	.ok

	bsr.b	.del
.orr	lea	200(sp),sp
	moveq	#ier_mlederr,d0
	rts
.ok
	jsr	._LVOSubTuneRange(a6)
	move	d1,maxsongs(a5)

	jsr	._LVOInitTune(a6)
	jsr	._LVOStartPlay(a6)
	bsr.b	.volume

	bsr.b	.del

	lea	200(sp),sp
	moveq	#0,d0
	rts

.del	move.l	a4,d1
	move.l	_DosBase(a5),a6
	jmp	_LVODeleteFile(a6)

.end
	move.l	_MlineBase(a5),a6
	jmp	._LVOEndPlayer(a6)

.cont
	move.l	_MlineBase(a5),a6
	jmp	._LVOStartPlay(a6)
	
.stop
	move.l	_MlineBase(a5),a6
	jmp	._LVOStopPlay(a6)

.volume
	moveq	#0,d0
	move	mainvolume(a5),d0
	move.l	_MlineBase(a5),a6
	jmp	._LVOMasterVol(a6)

.song
	moveq	#0,d0
	move	songnumber(a5),d0
	move.l	_MlineBase(a5),a6
	jmp	._LVOSelectTune(a6)

.foo	dc.b	"∞∞HiP-MLine",0
 even



id_mline
	cmp.l	#"MLED",(a4)		* musicline editor
	bne.b	.nd
	cmp.l	#"MODL",4(a4)
	bra.w	idtest

.nd	moveq	#-1,d0
	rts
	



******************************************************************************
* Artofnoise
******************************************************************************

p_aon
	jmp	.init(pc)
	jmp 	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	jmp	.cont(pc)
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp 	.id_aon(pc)
	jmp	author_twice(pc)
	dc.w 	pt_aon
	dc      pf_cont!pf_stop!pf_end!pf_ciakelaus!pf_poslen!pf_volume!pf_scope!pf_quadscopePoke
	dc.b	"Art Of Noise 4ch",0
 even

.OFFSET_INIT = $20+0
.OFFSET_PLAY = $20+4
.OFFSET_END  = $20+8
.OFFSET_STOP = $20+12
.OFFSET_CONT = $20+16

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	aonroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bra.w	vapauta_kanavat
.ok3
	pushm	d1-a6

	move.l	moduleaddress(a5),a0
	lea	mainvolume(a5),a1
	lea	songover(a5),a2 
	lea	ciaint_setTempoFromD0(pc),a3
	lea	scopeData(a5),a4
	move.l	aonroutines(a5),a6
	jsr	.OFFSET_INIT(a6)
	tst.l	d0
	bne.b	.noMem
	move.l	a0,deliPatternInfo(a5)

.x	popm	d1-a6
	rts

.noMem
	moveq	#ier_nomem,d0
	bra.b	.x

.end
	bsr.w	rem_ciaint
	move.l	aonroutines(a5),a0
	jsr	.OFFSET_END(a0)
	bsr.w	clearsound
	bra.w	vapauta_kanavat

.play
	move.l	aonroutines(a5),a0
	jsr	.OFFSET_PLAY(a0)
	move	d0,pos_nykyinen(a5) 
	move	d1,pos_maksimi(a5)
	rts

.stop
	move.l	aonroutines(a5),a0
	jmp		.OFFSET_STOP(a0)
	
.cont	
	move.l	aonroutines(a5),a0
	jmp		.OFFSET_CONT(a0)

.id_aon
	cmp.l	#"AON4",(a4)		* aon 4 channel
	bra.w	idtest



******************************************************************************
* Artofnoise 8ch
******************************************************************************

author_twice	
	pushpea	.a(pc),d0
	rts
.a	dc.b	"Bastian Spiegel (Twice/Lego)",0
 even

p_aon8
	jmp	.init(pc)
	jmp 	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	jmp	.cont(pc)
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp 	.id(pc)
	jmp	author_twice(pc)
	dc.w 	pt_aon8
	dc      pf_cont!pf_stop!pf_end!pf_ciakelaus!pf_poslen!pf_volume!pf_scope!pf_quadscopePoke
	dc.b	"Art Of Noise 8ch",0
 even

.OFFSET_INIT = $20+0
.OFFSET_PLAY = $20+4
.OFFSET_END  = $20+8
.OFFSET_STOP = $20+12
.OFFSET_CONT = $20+16

.init
	move.l	(a5),a0
	btst	#AFB_68020,AttnFlags+1(a0)
	bne.b	.okk
	moveq	#ier_hardware,d0
	rts
.okk
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	aonroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bra.w	vapauta_kanavat
.ok3
	pushm	d1-a6

	move.l	moduleaddress(a5),a0
	lea	mainvolume(a5),a1
	lea	songover(a5),a2 
	lea	ciaint_setTempoFromD0(pc),a3
	lea	scopeData(a5),a4
	move.l	aonroutines(a5),a6
	jsr	.OFFSET_INIT(a6)
	tst.l	d0
	bne.b	.noMem
	; Provides patterninfo but there is a visual delay due
	; to the mix buffer mechanism, so disabled for now.
	;move.l	a0,deliPatternInfo(a5)

.x	popm	d1-a6
	rts

.noMem
	moveq	#ier_nomem,d0
	bra.b	.x

.end
	bsr.w	rem_ciaint
	move.l	aonroutines(a5),a0
	jsr	.OFFSET_END(a0)
	bsr.w	clearsound
	bra.w	vapauta_kanavat

.play
	move.l	aonroutines(a5),a0
	jsr	.OFFSET_PLAY(a0)
	move	d0,pos_nykyinen(a5) 
	move	d1,pos_maksimi(a5)
	rts

.stop
	move.l	aonroutines(a5),a0
	jmp		.OFFSET_STOP(a0)
	
.cont	
	move.l	aonroutines(a5),a0
	jmp		.OFFSET_CONT(a0)

.id
	bsr.b	id_aon8
	bne.b	.no
	bsr.w	moveModuleToPublicMem
	moveq	#0,d0
.no	rts

id_aon8
	cmp.l	#"AON8",(a4)		* aon 8 channel
	bra.w	idtest



******************************************************************************
* PS3M
******************************************************************************


	rsset	14+32
init1j		rs.l	1
init2j		rs.l	1
init0j		rs.l	1
poslenj		rs.l	1
endj		rs.l	1
stopj		rs.l	1
contj		rs.l	1
eteenj		rs.l	1
taaksej		rs.l	1
volj		rs.l	1
boostj		rs.l	1

* Sets Z if PS3M+ImpulseTracker is active
isImpulseTrackerActive
	pushm	d0/a0
	cmp	#pt_multi,playertype(a5)
	bne.b	.no
	move.l	ps3m_mtype(a5),d0
	beq.b	.no
	move.l	d0,a0
	cmp	#mtIT,(a0)
	beq.b	.yes
.no	moveq	#-1,d0
.x	popm	d0/a0
	rts
.yes	moveq	#0,d0
	bra.b	.x

p_multi	jmp	.s3init(pc)
	p_NOP		* CIA
	jmp	.s3poslen(pc)		* VB
	jmp	.s3end(pc)
	jmp	.s3stop(pc)
	jmp	.s3cont(pc)
	jmp	.s3vol(pc)
	p_NOP		* Song
	jmp	.eteen(pc)
	jmp	.taakse(pc)
	jmp	ps3m_boost(pc)		* ahiupdate
	jmp id_ps3m(pc)
	jmp	.author(pc)
	dc.w pt_multi
.flags
 dc pf_cont!pf_stop!pf_volume!pf_kelaus!pf_poslen!pf_end!pf_scope!pf_ahi!pf_quadscopePoke
	dc.b	"PS3M",0
.itPath
	dc.b	"impulse",0
 even

.author
	move.l	ps3m_mtype(a5),a0
	cmp	#mtIT,(a0)
	bne.w	guru_author
	bra.w	deliAuthor


;init1j	jmp	init1r(pc)
;init2j	jmp	init2r(pc)
;init0j	jmp	s3init(pc)
;poslenj	jmp	s3poslen(pc)
;endj	jmp	s3end(pc)
;stopj	jmp	s3stop(pc)
;contj	jmp	s3cont(pc)
;eteenj	jmp	eteen(pc)
;taaksej	jmp	taakse(pc)

* This does test resource allocation and frees them right after.
.s3init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	bsr.w	vapauta_kanavat

	bsr.w	init_ciaint
	beq.b	.ok2
	moveq	#ier_nociaints,d0
	rts
.ok2	bsr.w	rem_ciaint

	lea	ps3mroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	rts

.ok3	
	pushm	d1-a6

	* IT deliplayer will clear the "poslen" flag, so make sure
	* it is available for other formats.
	lea	.flags(pc),a0
	or	#pf_poslen,(a0)

	move.l	moduleaddress(a5),a0
	bsr.W 	id_it
	bne.b	.notIt
	DPRINT "IT detected"

	move.l	(a5),a0
	btst	#AFB_68020,AttnFlags+1(a0)
	bne.b	.cpuOk
	moveq	#ier_hardware,d0
	bra.w	.itError
.cpuOk

	moveq	#$62,d0	* version
	lea	.itPath(pc),a0 
	* Distract the loader so that it will not try to
	* load PS3M from player group, instead it will
	* try eagleplayer loading from filesystem.
	move	playertype(a5),-(sp)
	move	#-1,playertype(a5)
	jsr	setMainWindowWaitPointer
	bsr.w	loadDeliPlayer 
	move	(sp)+,playertype(a5)
	tst.l 	d0
	bmi.w 	.itError
	bsr.w	deliInit
	jsr 	clearMainWindowWaitPointer
	tst.l	d0
	bne.w	.itError
.notIt


	addq	#1,ps3minitcount

	move	mixirate+2(a5),hip_ps3mrate+hippoport(a5)

* v‰litet‰‰n tietoa ps3m:lle ja hankitaan sit‰ silt‰

	move.b	cybercalibration(a5),d0
	move.l	calibrationaddr(a5),d1

	move.b	ahi_use(a5),d2
	move.l	ahi_rate(a5),d3
	move	ahi_mastervol(a5),d4
	move	ahi_stereolev(a5),d5
	move.l	ahi_mode(a5),d6
	move.l	modulelength(a5),d7

	lea	ps3m_mname(a5),a0
	lea	ps3m_numchans(a5),a1
	lea	ps3m_mtype(a5),a2
	lea	ps3m_samples(a5),a3
	lea	ps3m_xm_insts(a5),a4
	move.l	ps3mroutines(a5),a6
	jsr	init1j(a6)

	;pushpea	CHECKSTART,d0		* tarkistussummaa varten
	lea	ps3m_buff1(a5),a0
	lea	ps3m_buff2(a5),a1
	lea	ps3m_mixingperiod(a5),a2
	lea	ps3m_playpos(a5),a3
	lea	ps3m_buffSizeMask(a5),a4
	move.l	ps3mroutines(a5),a6
	move.l	deliPlayer(a5),d0
	move.l	deliBase(a5),d1
	jsr	init2j(a6)
	move.l	d0,ps3mchannels(a5)

	move.l	mixirate(a5),d0	
	move.b	s3mmode3(a5),d1		* volumeboost
	moveq	#0,d3
	move.b	s3mmode2(a5),d3		* mono/stereo/surround
	move.b	s3mmode1(a5),d4		* priority/killer

	move.l	moduleaddress(a5),d2	* moduuli

	move.b	ps3mb(a5),d5		* mixing buffer size
	lea	playing(a5),a0		* stop/cont-lippu
	lea	inforivit_killerps3m,a1	* killer ps3m viesti
	lea	mainvolume(a5),a2	* voluumi
	move.l	_DosBase(a5),a3
	lea	songover(a5),a4		* kappale loppuu-lippu
	move.l	_GFXBase(a5),a6
	pushpea	pos_nykyinen(a5),d6	* songpos -osoite
	pushpea	.adjustroutine(pc),d7	* asetusten s‰‰tˆrutiini
	move.l	ps3mroutines(a5),a5
	pea	.updateps3m3(pc)	* updaterutiini, surroundin stereo
	jsr	init0j(a5)
	addq	#4,sp			* pop pea

	lea	var_b,a5

	bsr.w	isImpulseTrackerActive
	bne.b	.notIT
	* No patternscope for this one	
	sub.l	a0,a0
	sub.l	a1,a1

	* TODO: in case of PS3M init error, do some
	* deli uninitializing?

.notIT

	move.l	a0,deliPatternInfo(a5)
	move.l	a1,ps3mUnpackedPattern(a5)
 if DEBUG
	tst.l	deliPatternInfo(a5)
	beq.b	.noPatInfo
	push	d0
	moveq	#0,d0
	move	PI_Voices(a0),d0
	move.l	PI_Modulo(a0),d1
	DPRINT	"Voices=%ld modulo=%ld"
	pop 	d0
.noPatInfo
 endif

	popm	d1-a6
	cmp	#333,d0		* killermoden koodi
	bne.b	.e
	addq	#4,sp		* killer: hyp‰t‰‰n play-aliohjelman 'ohi'
.e	rts

* Failed to init eagleplayer
.itError
	popm	d1-a6
	rts


.updateps3m3
	pushm	d1/a5
	lea	var_b,a5
	cmp.b	#1,s3mmode2(a5)		* onko surround?
	bne.b	.nd
	moveq	#64,d1
	sub.b	stereofactor(a5),d1
	move	d1,$dff0c8
	move	d1,$dff0d8
.nd	popm	d1/a5
	rts

* VBLANK routine
* Updates:
* - position and lenght info
* - patternscope information, if needed
.s3poslen
	tst.b	patternScopeRunning(a5)
	* Inform PS3M, set to zero to skip patternscope routines
	sne	d0
.noScope
	move.l	ps3mroutines(a5),a0
	jmp	poslenj(a0)

.s3end	clr.l	ps3mUnpackedPattern(a5)
	move.l	ps3mroutines(a5),a0
	jmp	endj(a0)
	

.s3stop	move.l	ps3mroutines(a5),a0
	jmp	stopj(a0)

.s3cont	move.l	ps3mroutines(a5),a0
	jmp	contj(a0)

.s3vol	move.l	ps3mroutines(a5),a0
	jmp	volj(a0)

.eteen	move.l	ps3mroutines(a5),a0
	jmp	eteenj(a0)

.taakse	move.l	ps3mroutines(a5),a0
	jmp	taaksej(a0)


******** Asetukset kanavam‰‰r‰n mukaan
* t‰nne hyp‰t‰‰n initin j‰lkeen. d0:ssa on kanavien m‰‰r‰.

.adjustroutine
	pushm	d2/d6-a6
	lea	var_b,a5
	moveq	#0,d6			* -1: vaikuttaa, 0: ei vaikuta
	cmp	#1,ps3minitcount	* asetustiedosto vaikuttaa vain
	bne.w	.xei			* ensimm‰iseen inittiin latauksen
					* j‰lkeen

	tst.b	ps3msettings(a5)	* k‰ytet‰‰nkˆ vai ei?
	beq.w	.xei

	move	d0,d7			* kanavien m‰‰r‰

	move.l	ps3msettingsfile(a5),d0
	beq.w	.xei
	move.l	d0,a0
	bsr.w	.tah

	moveq	#-1,d6

	lea	32*13(a0),a1		* file asetukset t‰‰ll‰

	move	d7,d0			* ensin asetukset kanavataulukosta
	subq	#1,d0
	mulu	#13,d0
	add	d0,a0
	addq	#3,a0
	bsr.w	.gets

	move.l	a1,a0			* t‰htirivien ohi
	bsr.w	.tah

	move.l	solename(a5),a1
.fine	tst.b	(a1)+
	bne.b	.fine
	sub.l	solename(a5),a1
	subq	#1,a1
	move	a1,d2

.filel
	addq	#1,a0
	cmp.b	#'¯',(a0)		* loppumerkki?
	beq.b	.golly
	move	d2,d5
	subq	#1,d5

	move.l	solename(a5),a1
.fid	cmpm.b	(a0)+,(a1)+
	bne.b	.fe
	dbf	d5,.fid
	addq	#2,a0
	bsr.b	.gets
	bra.b	.golly

.fe	cmp.b	#10,(a0)+
	bne.b	.fe
	bra.b	.filel

.golly



***** nappulat prefsiss‰
	pushm	all
	move.l	mixirate(a5),d0
	sub.l	#5000,d0
	divu	#100,d0
	mulu	#65535,d0
	divu	#580-50,d0
	lea	pslider1,a0
	jsr	setknob2
	lea	juusto,a0
	moveq	#0,d0
	move.b	s3mmode3(a5),d0
	mulu	#65535,d0
	divu	#16,d0
	jsr	setknob2
	popm	all


	move.l	mixirate(a5),d0		* mixingrate
	move.b	s3mmode3(a5),d1		* volumeboost
	moveq	#0,d3
	move.b	s3mmode2(a5),d3		* mono/stereo/surround/jne..
	move.b	s3mmode1(a5),d4		* pri/killer

.xei	tst.l	d6
	popm	d2/d6-a6
	rts

.find0	cmp.b	#10,(a0)+
	bne.b	.find0

.tah
.f0
	cmp.b	#'"',(a0)
	beq.b	.ofk
	cmp.b	#'0',(a0)
	bne.b	.find0	
.ofk	rts


.gets	move.b	(a0),d0
	cmp.b	#'?',d0
	beq.b	.sk0
	and	#$f,d0
	move.b	d0,s3mmode1(a5)	
	move.b	d0,s3mmode1_new(a5)
.sk0
	move.b	2(a0),d0
	cmp.b	#'?',d0
	beq.b	.sk1
	and	#$f,d0
	move.b	d0,s3mmode2(a5)
	move.b	d0,s3mmode2_new(a5)
.sk1
	move.b	4(a0),d0
	cmp.b	#'?',d0
	beq.b	.sk2
	and	#$f,d0
	move.b	d0,s3mmode3(a5)
	move.b	d0,s3mmode3_new(a5)
.sk2

	moveq	#0,d0
	move.b	6(a0),d1
	cmp.b	#'?',d1
	beq.b	.sk3
	and	#$f,d1
	mulu	#10000,d1
	add.l	d1,d0
	move.b	7(a0),d1
	and	#$f,d1
	mulu	#1000,d1
	add.l	d1,d0
	move.b	8(a0),d1
	and	#$f,d1
	mulu	#100,d1
	add.l	d1,d0
	move.l	d0,mixirate(a5)
	move.l	d0,mixingrate_new(a5)
.sk3
	cmp	#4,prefsivu(a5)
	bne.b	.re
	jsr	updateprefs
.re	rts



ps3m_boost
.ahiupdate
	move.l	ps3mroutines(a5),a0
	jmp	boostj(a0)




mtS3M = 1
mtMOD = 2
mtMTM = 3
mtXM  = 4
mtIT  = 5


* Initti vaihe 1. Jos d0<>0, moduuli ei kelpaa.
id_ps3m		pushm	d1-a6
;	clr	PS3M_reinit
;	clr	ps3minitcount

	move.l	a4,a0
;	move.l	moduleaddress(a5),a0

	bsr.w	id_it
	beq.w	.it

	cmp.l	#"SCRM",44(a0)
	beq.b	.s3m

	move.l	(a0),d0
	lsr.l	#8,d0
	cmp.l	#"MTM",d0
	beq.b	.mtm

	move.l	a0,a1
	lea	.xmsign(pc),a2
	moveq	#3,d0
.l	cmpm.l	(a1)+,(a2)+
	bne.b	.j
	dbf	d0,.l
	bra.b	.xm

.j	move.l	1080(a0),d0
	cmp.l	#"OCTA",d0
	beq.b	.fast8
	cmp.l	#"M.K.",d0
	beq.b	.pro4
	cmp.l	#"M!K!",d0
	beq.b	.pro4
	cmp.l	#"FLT4",d0
	beq.b	.pro4

	move.l	d0,d1
	and.l	#$ffffff,d1
	cmp.l	#"CHN",d1
	beq.b	.chn

	and.l	#$ffff,d1
	cmp.l	#"CH",d1
	beq.b	.ch

	move.l	d0,d1
	and.l	#$ffffff00,d1
	cmp.l   #"TDZ"<<8,d1
	beq.b	.tdz
	moveq	#1,d0
	bra.b	.init

.xm	cmp	#$401,xmVersion(a0)		; Kool turbo-optimizin'...
	bne.b	.j
.it
.chn
.ch
.tdz
.fast8
.pro4
.mtm
.s3m	moveq	#0,d0

.init	tst.l	d0
	popm	d1-a6
	rts


.xmsign		dc.b	"Extended Module:"
 even

ps3minitcount	dc	0

* ID from A0
id_it
	push	d1
	MOVEQ	#0,D0
	CMP.L	#$494D504D,(A0)
	BNE.S	.itFail
	MOVE.W	$2A(A0),D1			*  Cmwt: format version
	ROR.W	#8,D1
 if DEBUG
	push	d0
	moveq	#0,d0
	move	d1,d0
	DPRINT	"IT version: %lx"
	pop	d0
 endif
	CMP.W	#$100,D1
	BEQ.S	.itYes
	CMP.W	#$200,D1
	BEQ.S	.itYes
; TEST: Fake version $214 to look like version $200
;	CMP.W	#$214,D1
;	Bne.S	.itFail
;	move	#$0002,$2A(a0)
;	bra.b	.itYes
.itFail
	MOVEQ	#-1,D0
.itYes
	pop	d1
	tst.l	d0
	RTS





******************************************************************************
* Sampleplayer
******************************************************************************

p_sample
	jmp	.init(pc)
	p_NOP	* CIA
	p_NOP	* VB
	jmp	.end(pc)		* end
	jmp	.dostop(pc)		* Stop
	jmp	.docont(pc)		* Cont
	jmp	.vol(pc)		* volume
	p_NOP	* Song
	p_NOP	* Eteen
	p_NOP	* Taakse
	jmp	.ahiup(pc)		* AHI Update
	jmp 	id_sample(pc)
	p_NOP	* author
	dc.w 	pt_sample
	dc	pf_volume!pf_scope!pf_stop!pf_cont!pf_end!pf_ahi!pf_quadscopePoke
.name	dc.b	"                        ",0
 even

	rsset	$20
.s_init		rs.l	1
.s_end		rs.l	1
.s_stop		rs.l	1
.s_cont		rs.l	1
.s_vol		rs.l	1
.s_ahiup	rs.l	1
.s_ahinfo	rs.l	1
	
.init
	lea	sampleroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok
	rts
.ok
	pushm	a5/a6

** v‰litet‰‰n infoa

	move.b	ahi_use(a5),d0
	move.l	ahi_rate(a5),d1
	move	ahi_mastervol(a5),d2
	move	ahi_stereolev(a5),d3
	move.l	ahi_mode(a5),d4
	move.l	sampleroutines(a5),a0

*** lis‰‰‰
	move.b	mpegaqua(a5),d5
	move.b	mpegadiv(a5),d6

	jsr	.s_ahinfo(a0)

	move.l	colordiv(a5),d0
	DPRINT	"colordiv=%ld"
** lis‰‰
	moveq	#0,d0
	cmp	#16000,horizfreq(a5)
	slo	d0
	move	d0,-(sp)
	pea	songover(a5)
	move.l	colordiv(a5),-(sp)
	move.l	_XPKBase(a5),-(sp)

	move.b	samplebufsiz0(a5),d0
	move.b	sampleformat(a5),d1

	move.l	_DosBase(a5),a1
	move.l	_GFXBase(a5),a2
	lea	.name(pc),a3
	move.l	modulefilename(a5),a4

	pushpea	varaa_kanavat(pc),d2
	pushpea	vapauta_kanavat(pc),d3
;	pushpea	probebuffer(a5),d4
	pushpea	kokonaisaika(a5),d5

	move.b	samplecyber(a5),d7
;	move.b	cybercalibration(a5),d6
	move.l	calibrationaddr(a5),d7

	move	sampleforcerate(a5),a6

	move.l	sampleroutines(a5),a0
	jsr	.s_init(a0)

	add	#14,sp

	popm	a5/a6

	move.l	d1,sampleadd(a5)
	move.l	a0,samplefollow(a5)
	move.l	a1,samplepointer(a5)
	move.l	a2,samplepointer2(a5)
	move.b	d2,samplestereo(a5)
	move.l	d3,samplebufsiz(a5)

 if DEBUG
	pushm	d0-d3
	move.l	d3,d0
	move.l	(a1),d2
	move.l	(a2),d3
	DPRINT	"Bufsize=%ld add=%ld buf1=%lx buf2=%lx"
	popm	d0-d3
 endif

	tst	d0
	bne.b	.x

	bsr.b	.vol
	moveq	#0,d0
.x	rts

.end	move.l	sampleroutines(a5),a0
	jmp	.s_end(a0)

.dostop	move.l	sampleroutines(a5),a0
	jmp	.s_stop(a0)

.docont	move.l	sampleroutines(a5),a0
	jmp	.s_cont(a0)

.vol	move	mainvolume(a5),d0
	move.l	sampleroutines(a5),a0
	jmp	.s_vol(a0)

.ahiup	move.l	sampleroutines(a5),a0
	jmp	.s_ahiup(a0)

id_sample
	rts

* In:
*   a0 = probebuffer, size 2048
* Out:
*  d0 = 0 = recognized, -1 = not
id_mp3
	* Check for ID3v2 header
	move.l	(a0),d0
	lsr.l	#8,d0
	cmp.l	#"ID3",d0
	bne.b	.not

	cmp.b	#$ff,3(a0)
	beq.b	.not
	cmp.b	#$ff,4(a0)
	beq.b	.not
	* Low flag nybble should be zero
	moveq	#$0f,d0
	and.b	5(a0),d0
	bne.b	.not
	* synchsafe integer bytes are all 7 bits
	cmp.b	#$80,6(a0)
	bhs.b	.not
	cmp.b	#$80,7(a0)
	bhs.b	.not
	cmp.b	#$80,8(a0)
	bhs.b	.not
	cmp.b	#$80,9(a0)
	bhs.b	.not
	bra.b	.yepID3v2
.not

	* Find MPEG sync word
	* This is very unreliable in the sense that many other formats
	* will be recognized as MPEG streams. Let's not do it.

 REM ;;;;
;#define SYNC_VALID( v ) ( ((v & 0xFFE00000) == 0xFFE00000) &&\
;                          ((v & 0x00060000) != 0x00000000) &&\
;                          ((v & 0xF000) != 0xF000) &&\
;                          ((v & 0xF000) != 0x0000) &&\
;                          ((v & 0x0C00) != 0x0C00) )
	move	#PROBE_BUFFER_LEN-4-1,d1
	move.l	a0,a1
.loop
	move.b	(a1)+,d2
	lsl.l	#8,d2
	move.b	(a1),d2
	lsl.l	#8,d2
	move.b	1(a1),d2
	lsl.l	#8,d2
	move.b	2(a1),d2
	
	move.l	d2,d3
	and.l	#$FFE00000,d3
	cmp.l	#$FFE00000,d3
	bne.b	.next

	move.l	d2,d3
	and.l	#$00060000,d3
	beq.b	.next

	move.l	d2,d3
	and.l	#$F000,d3
	cmp.w	#$F000,d3
	beq.b	.next

	move.l	d2,d3
	and.l	#$F000,d3
	beq.b	.next
	
	move.l	d2,d3
	and.l	#$0C00,d3
	cmp.w	#$0C00,d3
	bne.b	.yepSyncWord
.next
	dbf	d1,.loop
 EREM ;;;;;;;;;
.nope
	moveq	#-1,d0
	rts

.yepID3v2
	DPRINT	"MP3 ID3v2 tag found"
	moveq	#0,d0
	rts
.yepSyncWord
	DPRINT	"MP3 sync word found"
	moveq	#0,d0
	rts

******************************************************************************
* PumaTracker
******************************************************************************

p_pumatracker
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp .id_pumatracker(pc)
	jmp	.author(pc)
	dc.w pt_pumatracker
	dc	pf_stop!pf_cont!pf_ciakelaus
	dc.b	"PumaTracker",0
.a  dc.b "Jean-Charles Meyrignac, Pierre-Eric Loriaux",0
 even

.author
	pushpea	.a(pc),d0
	rts

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	pumatrackerroutines(a5),a0
	* allocate into chip mem
	bsr.w	allocreplayer2
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	pushm	all
	move.l	moduleaddress(a5),a0
	move.l	pumatrackerroutines(a5),a3
	jsr	$20+0(a3)
	popm	all
	moveq	#0,d0
	rts	

.play
	move.l	pumatrackerroutines(a5),a0
	jmp	$20+4(a0)
	rts
.end
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat

.stop
	bra.w	clearsound


.id_pumatracker 
	bsr.b .id_pumatracker_
	bne.b .x 
	moveq	#12-1,d0
	bsr.w	copyNameFromModule
	moveq	#0,d0
.x 	rts

.id_pumatracker_
	* test some attributes
	* positive song length
	tst		$c(a4)
	bmi.b	.notPuma
	* positive num of patterns
	tst		$e(a4)
	bmi.b	.notPuma
	* positive num of sound data
	tst		$10(a4)
	bmi.b	.notPuma

	* sample 1 start offset
	tst.l	$14(a4)
	bmi.b	.notPuma

	* sample 2 start offset
	tst.l	$18(a4)
	bmi.b	.notPuma

	* Find some magic words that should be there
	lea		.patt(pc),a1
	moveq	#.patte-.patt,d0
	bsr.w	search
	bne.b	.notPuma

	* search "patt" again after the first instance
	push	a4
	move.l	a0,a4
	lea		.patt(pc),a1
	moveq	#.patte-.patt,d0
	bsr.w	search
	pop 	a4
	tst.l	d0 
	bne.b	.notPuma

	moveq	#0,d0
	rts
.notPuma	
	moveq	#-1,d0 
	rts

.patt 	dc.b	"patt"
.patte
 even


******************************************************************************
* Beathoven Synthesizer
******************************************************************************

p_beathoven
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP
	p_NOP
	jmp	.song(pc)
	p_NOP
	p_NOP
	p_NOP
	jmp .id_beathoven(pc)
	jmp	.author(pc)
	dc.w pt_beathoven
	dc	pf_cont!pf_stop!pf_ciakelaus!pf_song
	dc.b	"Beathoven Synthesizer",0
.a  	dc.b "Thomas Lopatic (Dr.Nobody/HQC), adapted by Wanted Team",0
 even

.author 
	pushpea	.a(pc),d0 
	rts 

* play
.BEAT_PLAY = 16+$20
* init, song in d0
.BEAT_INIT = 20+$20
* num of subsongs
.BEAT_SUBSONGS = 24+$20 
* optional end 
.BEAT_END = 28+$20
* optional init player
.BEAT_OPT_INIT = 32+$20
* module name
.BEAT_NAME = 36+$20
* author name
.BEAT_AUTHOR = 40+$20

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2

	bsr.b 	.doInit
	moveq	#0,d0
	rts

.doInit
	pushm	all
	move.l	moduleaddress(a5),a2
	move.l	.BEAT_SUBSONGS(a2),d0 
	DPRINT	"Beathoven init, subsongs=%ld"
	subq	#1,d0
	move	d0,maxsongs(a5)
	push 	a2
	move.l	.BEAT_INIT(a2),a0
	moveq	#0,d0	* subsong
	move	songnumber(a5),d0	
	DPRINT	"Subsong=%ld"
	jsr		(a0)
	pop 	a2
	move.l	.BEAT_OPT_INIT(a2),d0 
	beq.b  .noOpt
	move.l	d0,a0
	jsr		(a0)
.noOpt	popm	all
	rts	

.deInit
	pushm	all
	move.l	moduleaddress(a5),a0
	move.l	.BEAT_END(a0),d0
	beq.b	.noEnd
	move.l	d0,a0
	jsr	(a0)
.noEnd	popm	all
	rts

.play
	move.l	moduleaddress(a5),a0
	move.l	.BEAT_PLAY(a0),a0
	jmp		(a0)
	

.end
	bsr.w	rem_ciaint
	bsr.b	.deInit
	bra.w	vapauta_kanavat

.stop
	bra.w	clearsound

.song
	bsr.b	.deInit
	bsr.w	.doInit
	rts

.id_beathoven
	bsr.b .id_beathoven_
	bne.b .x 
	move.l	moduleaddress(a5),a1
	move.l	$20+36(a1),a1
	moveq	#30-1,d0
	bsr.w	copyNameFromA1
	moveq	#0,d0
.x 	rts

* in: a4 = module
* out: 
*   d0 = 0, is beathoven
*   do = -1, is not beathoven
.id_beathoven_
    * these seem to be executables, so check for hunk
    cmp.l   #$3f3,(a4)
    bne.b   .notBeat
    * skip hunk header
    lea     $20(a4),a0
    cmp.l   #$70ff4e75,(a0)
    bne.b   .notBeat
    cmp.l   #'BEAT',4(a0)
    bne.b   .notBeat
    cmp.l   #'HOVE',8(a0)
    bne.b   .notBeat
    * looks good, relocate it
    move.l  a4,a0
    bsr.w reloc
	* clear the hunk id for safety to avoid reloccing again
	clr.l	(a4)
	bsr.w	clearCpuCaches
    moveq   #0,d0
    rts
.notBeat    
    moveq   #-1,d0 
    rts




******************************************************************************
* Game Music Creator
******************************************************************************

p_gamemusiccreator
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp id_gamemusiccreator(pc)
	jmp	.author(pc)
	dc.w pt_gamemusiccreator
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_end!pf_poslen!pf_volume!pf_scope!pf_quadscopePoke
	dc.b	"Game Music Creator",0
.a 	dc.b "Andreas Tadic",0
 even

.author
	pushpea	.a(pc),d0 
	rts

.GMC_INIT  = $20+0
.GMC_PLAY  = $20+4
.GMC_END   = $20+8

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	gamemusiccreatorroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	pushm	d0-d7/a1-a6
	move.l	moduleaddress(a5),a0
	lea	mainvolume(a5),a1
	lea	songover(a5),a2
	lea	pos_nykyinen(a5),a3
	lea	pos_maksimi(a5),a4
	move.l	gamemusiccreatorroutines(a5),a6
	lea	scopeData(a5),a5
	move.l	#nullsample,d0
	jsr	.GMC_INIT(a6)
	popm	d0-d7/a1-a6
	move.l	a0,deliPatternInfo(a5)
	moveq	#0,d0
	rts	

.play
	move.l	gamemusiccreatorroutines(a5),a0
	jmp	.GMC_PLAY(a0)

.end
	bsr.w	rem_ciaint
	move.l	gamemusiccreatorroutines(a5),a0
	jsr	.GMC_END(a0)
	bsr.w	clearsound
	bra.w	vapauta_kanavat

.stop
	bra.w	clearsound

; in: a4 = module
; out: d0 = 0, valid GMC
;      d0 = -1, not GMC
id_gamemusiccreator
	pushm 	d1-a6
	bsr.b	.do
	popm 	d1-a6 
	rts
.do
	moveq   #15-1,d0
	move.l  a4,a0
.sampleLoop
	* sample vol check probably
	cmp.b   #$40,7(a0)
    	bhi.w   .notGmc

    * sample len
 	move    4(a0),d1 
    	cmp     #$7fff,d1
    	bhi.w   .notGmc

    	add     d1,d1
    * loop length (?), must be less than total length
    	move    12(a0),d2 
    	cmp     d1,d2
    	bhi.b   .notGmc

    	add     #16,a0
    	dbf d0,.sampleLoop

    * pattern table size
    	cmp.b   #$64,243(a4)
    	bhi.b   .notGmc
    	tst.b   243(a4)
    	beq.b   .notGmc

    * pattern order table
	* contains offsets to patterns, each pattern is $400 bytes long,
	* 4 channels * 64 rows * 4 bytes
	* Possible to have 100 individual patterns
 	moveq   #100-1,d7
	lea     244(a4),a0
    	moveq   #0,d2 * numpat
.pattLoop
	* offsets should be divisible by $400
    	move    (a0),d0
    	and     #$3ff,d0
    	bne.b   .notGmc

	* store the highest pattern index	
	move    (a0),d0
	lsr     #8,d0
    	lsr     #2,d0
   	cmp     d2,d0
    	blo.b   .numpat
    	move    d0,d2
.numpat
    	addq.l    #2,a0
    	dbf d7,.pattLoop

	; check how many patterns are there
    	addq    #1,d2

	; high bound
    	cmp     #100,d2
    	bhi.b   .notGmc
 * validate the first pattern, it's apparently
 * a bit difficult to correctly determine the real amount
 * of patterns in a module. Thre should at least be one!

.patterns
    	lea     444(a4),a0
     * traverse a pattern
    * four bytes per channel per row,
    * so 16 bytes per row
    * pattern lenght is then 64 rows.
    * go through all 4 byte note slots in one pattern.

    move    #256-1,d5		* 64 rows x 4 channels
.rows  
    * first two bytes are contain note
    * and sample info.
    * 3rd is command
    * 4th is command parameter

    * get command code.
    * 0 = no command
    * 1 = slide up
    * 2 = slide down
    * 3 = set volume
    * 4 = pattern break 
    * 5 = pos jump
    * 6 = filter clear
    * 7 = filter set 
    * 8 = song step
    *   = rest are ignored

	moveq	#$f,d0
	and.b	2(a0),d0

    * set volume. could check for max volume
	* but some modules have over the max of 64 here
	* check for max volume parameter
;    cmp.b   #3,d0
;    bne.b   .c3
;    cmp.b   #$40,3(a0)
;	bhi.w   .notGmc3
;.c3

	move.l  (a0),d0
    	and     #$f000,d0
    	beq.b   .noSample
	clr	d0
	swap    d0
	tst	d0
	beq.b	.okP
	* d0 is now the period
	* 0 is allowed
	lea	periods,a1
	moveq	#(periodsEnd-periods)/2-1,d1
.perLoop
	cmp	(a1)+,d0
	beq.b	.okP
	dbf	d1,.perLoop
	* BAD PERIOD, BAD!
	bra.b	.notGmc
.okP
.noSample
    	addq.l  #4,a0
    	dbf     d5,.rows
   	moveq   #0,d0
    	rts
.notGmc
   	moveq  #-1,d0 
	rts


******************************************************************************
* Digital Mugician
******************************************************************************

author_vliet
	pushpea	.a(pc),d0
	rts
.a dc.b "Reinier van Vliet (Rhino/Team Hoi)",0
 even

p_digitalmugician
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id_digitalmugician(pc)
	jmp	deliAuthor(pc)
	dc  pt_digitalmugician
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_kelauseteen!pf_kelaustaakse!pf_scope!pf_quadscopePoke
	dc.b	"Digital Mugician    [EP]",0
.path	dc.b	"mugician.amp",0
 even
 
.init
	lea	.path(pc),a0 
	moveq	#0,d0
	bsr.w	deliLoadAndInit
	rts 

; in: a4 = module
; out: d0 = 0, valid DMU
;      d0 = -1, not DMU
.id_digitalmugician
	lea	.id_start(pc),a1	
	moveq	#.id_end-.id_start,d0
	bsr.w	search
	bra.w	idtest

.id_start
	dc.b	' MUGICIAN/SOFTEYES 1990 '
.id_end
 even

******************************************************************************
* Delitracker CUSTOM
******************************************************************************

p_delicustom
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	p_NOP
	p_NOP
	p_NOP
	jmp id_delicustom(pc)
	jmp	deliAuthor(pc)
	dc.w pt_delicustom
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_song
	dc.b	"DeliTracker Custom",0
 even

.init
	move.l	moduleaddress(a5),d0
	lsl.l	#2,d0
	bsr.w	deliInit
	rts

id_delicustom
	lea	.id1_start(pc),a1	
	moveq	#.id1_end-.id1_start,d0
	bsr.w	search
	bne.b	.notDeli
	lea	.id2_start(pc),a1	
	moveq	#.id2_end-.id2_start,d0
	bsr.w	search
	bne.b	.notDeli
	lea	.id3_start(pc),a1	
	moveq	#.id3_end-.id3_start,d0
	bsr.w	search
	bne.b	.notDeli

	* search() leaves with a0 pointing
	* to the next byte to be searched,
	* get the value for DTP_CustomPlayer,
	* it must be non-zero
	tst.l	(a0)
	beq.b	.notDeli

	moveq	#0,d0
	rts
	
.notDeli
	moveq	#-1,d0 
	rts

.id1_start
	moveq	#-1,d0
	rts
.id1_end

.id2_start
	dc.b	"DELIRIUM"
.id2_end

; Seems that the parameter for this that can be anything but 0
.id3_start
	dc.l DTP_CustomPlayer
.id3_end



******************************************************************************
* Synthesis
******************************************************************************

p_synthesis
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	p_NOP
	p_NOP
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_synthesis 
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_end!pf_song
	dc.b	"Synthesis           [EP]",0

.path dc.b "synth 4.0",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|11,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l	a4,a0 
	MOVEQ	#1,D0
	CMP.L	#$53796E74,(A0)
	BNE.S	.lbC000436
	MOVE.L	4(A0),D0
	LSR.L	#8,D0
	CMP.L	#$68342E,D0
	BEQ.S	.lbC000424
	CMP.L	#$682E5063,4(A0)
	BNE.S	.lbC000436
	MOVEQ	#$64,D0
.lbC0003F0	CMP.L	#$D1FC0000,(A0)
	BNE.S	.lbC00040C
	CMP.L	#$CC22C8,4(A0)
	BNE.S	.lbC00040C
	CMP.L	#$7200123A,8(A0)
	BEQ.S	.lbC000414
.lbC00040C	ADDQ.L	#4,A0
	DBRA	D0,.lbC0003F0
	RTS

.lbC000414	MOVEQ	#-1,D0
	SUBQ.L	#4,A0
	CMP.W	#$41FA,(A0)+
	BNE.S	.lbC000436
	MOVEQ	#0,D1
	MOVE.W	(A0),D1
	ADD.L	D1,A0
.lbC000424	
	MOVEQ	#0,D0
.lbC000436	
	rts


******************************************************************************
* SynTracker
******************************************************************************

p_syntracker
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	p_NOP
	p_NOP
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc pt_syntracker
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_end
	dc.b	"SynTracker          [EP]",0
.path dc.b "syntracker",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|2,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l 	a4,a0
	LEA	.SYNTRACKERSONMSG(PC),A1
	MOVEQ	#-1,D0
	MOVEQ	#15,D1
.lbC0001E0	CMPM.B	(A1)+,(A0)+
	BNE.S	.lbC0001EA
	DBRA	D1,.lbC0001E0
	MOVEQ	#0,D0
.lbC0001EA	
	RTS

.SYNTRACKERSONMSG	dc.b	'SYNTRACKER-SONG:',0,0


******************************************************************************
* Rob Hubbard 2
******************************************************************************

p_robhubbard2
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	p_NOP
	p_NOP
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_robhubbard2
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_end!pf_scope!pf_quadscopePoke
	dc.b	"R.Hubbard 2/Infogra.[EP]",0
.path dc.b "rob hubbard 2",0
 even

.init
	lea	.path(pc),a0 
	move.l	#2<<16|0,d0
	bsr.w	deliLoadAndInit
	rts 

; in: a4 = module
;     d7 = module length
; out: d0 = 0, valid valid
;      d0 = -1, not valid
.id
	move.l	a4,a0 
	SUB.W	$10(A0),D7
	SUBQ.L	#2,D7
	BNE.S	.lbC000336
	MOVE.W	(A0),D0
	LEA	0(A0,D0.W),A0
	TST.W	(A0)
	BMI.S	.lbC000336
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.W	2(A0),D1
	MOVE.W	12(A0),D2
	MOVE.W	6(A0),D3
	MOVEQ	#$10,D4
.lbC000320	MOVE.W	0(A0,D4.W),D0
	CMP.W	D1,D0
	BGT.S	.lbC000336
	CMP.W	D2,D0
	BLT.S	.lbC000336
	ADDQ.W	#2,D4
	CMP.W	D4,D3
	BLT.S	.lbC000320
	MOVEQ	#0,D0
	RTS
.lbC000336	MOVEQ	#-1,D0
	RTS


******************************************************************************
* ChipTracker
******************************************************************************


p_chiptracker
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_chiptracker 
 dc pf_scope!pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_poslen!pf_kelauseteen!pf_kelaustaakse!pf_ciakelaus2!pf_quadscopeUps
	dc.b	"ChipTracker         [EP]",0

.path dc.b "chiptracker",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|3,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	cmp.l   #'KRIS',952(A4)
	sne	d0
	rts

******************************************************************************
* Medley Sound System
******************************************************************************

p_medley
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP 	
	p_NOP
	jmp	.song(pc) 
	p_NOP
	p_NOP
	p_NOP
	jmp .id_medley(pc)
	jmp	.author(pc)
	dc.w pt_medley
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_song
	dc.b	"Medley Sound",0
.a 	dc.b	"Paul van der Valk",0
 even

.author
	pushpea	.a(pc),d0 
	rts

.MEDLEY_INIT  = 0+$20
.MEDLEY_PLAY  = 4+$20
.MEDLEY_END   = 8+$20
.MEDLEY_SONG  = 12+$20

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	medleyroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	pushm	d1-a6
	move.l	moduleaddress(a5),a0
	lea	mainvolume(a5),a1
	lea	maxsongs(a5),a2
	lea	ciaint_setTempoFromD0(pc),a3
	move	songnumber(a5),d0 	* song number
	;moveq	#8,d0
	addq	#1,d0
	move.l	medleyroutines(a5),a6
	jsr	.MEDLEY_INIT(a6)
	popm	d1-a6
	* INIT returns 0 on success
	rts	

.play
	move.l	medleyroutines(a5),a0
	jmp	.MEDLEY_PLAY(a0)

.stop
	bra.w	clearsound

.song
 if DEBUG
	moveq	#0,d0
	move	songnumber(a5),d0
	DPRINT	"Song %ld"
 endif
 	move.l	medleyroutines(a5),a0
	jsr	.MEDLEY_SONG(a0)
	rts

.end
	bsr.w	rem_ciaint
	pushm	all
	move.l	medleyroutines(a5),a0
	jsr	.MEDLEY_END(a0)
	popm	all
	bsr.w	clearsound
	bra.w	vapauta_kanavat



; in: a4 = module
;     d7 = module lenght
; out: d0 = 0, valid valid
;      d0 = -1, not valid
.id_medley
	cmp.l 	#"MSOB",(a4)
	bne.b	.invalid
	* next, three offsets, should point to inside module
	* first byte should be zero since mods are small
	tst.b	4(a4)
	bne.b	.invalid
	tst.b	8(a4)
	bne.b	.invalid
	tst.b	12(a4)
	bne.b	.invalid

	move.l	4(a4),d0
	add.l	a4,d0
	cmp.l	d0,a4
	bhs.b	.invalid
	move.l	8(a4),d0
	add.l	a4,d0
	cmp.l	d0,a4
	bhs.b	.invalid
	move.l	12(a4),d0
	add.l	a4,d0
	cmp.l	d0,a4
	bhs.b	.invalid

	moveq	#0,d0
	rts

.invalid
	moveq	#-1,d0
	rts


******************************************************************************
* Future Player
******************************************************************************

p_futureplayer
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP 	
	p_NOP
	jmp	.song(pc) 
	p_NOP
	p_NOP
	p_NOP
	jmp id_futureplayer(pc)
	jmp	.author(pc)
	dc.w pt_futureplayer
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_song
	dc.b	"Future Player",0
.a 	dc.b	"Paul van der Valk, adapted by Wanted Team",0
 even

.author
	pushpea	.a(pc),d0 
	rts


.FP_INIT  = 0+$20
.FP_PLAY  = 4+$20
.FP_END   = 8+$20
.FP_SONG  = 12+$20

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	futureplayerroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	pushm	d1-a6
	move.l	moduleaddress(a5),d0
	lea	nullsample,a1
	lea	mainvolume(a5),a2
	lea	maxsongs(a5),a3
	lea	ciaint_setTempoFromD0(pc),a4
	move	songnumber(a5),d1 	* song number, starts from 0
	move.l	futureplayerroutines(a5),a6
	push	a5
	jsr	.FP_INIT(a6)
	pop	a5
	tst.l	d0
	bne.b	.inifail
	* song name is in a0
 if DEBUG
	move.l 	a0,d0
	DPRINT	"Song name: %s"
 endif
	lea	modulename(a5),a1
.c	move.b	(a0)+,(a1)+
	bne.b	.c

	moveq	#0,d0
.inifail
	popm	d1-a6
	* INIT returns 0 on success
	rts	

.play
	move.l	futureplayerroutines(a5),a0
	jmp	.FP_PLAY(a0)

.stop
	bra.w	clearsound

.song
 if DEBUG
	moveq	#0,d0
	move	songnumber(a5),d0
	DPRINT	"Song %ld"
 endif
	move.l	futureplayerroutines(a5),a0
	jsr	.FP_SONG(a0)
	rts

.end
	bsr.w	rem_ciaint
	pushm	all
	move.l	futureplayerroutines(a5),a0
	jsr	.FP_END(a0)
	popm	all
	bsr.w	clearsound
	bra.w	vapauta_kanavat


; in: a4 = module
;     d7 = module length
; out: d0 = 0, valid valid
;      d0 = -1, not valid
id_futureplayer
	cmp.l	#$000003F3,(A4)
	bne.b	.fail
	tst.b	20(A4)				; loading into chip check
	beq.b	.fail
	lea	32(A4),A0
	cmp.l	#$70FF4E75,(A0)+
	bne.b	.fail
	cmp.l	#'F.PL',(A0)+
	bne.b	.fail
	cmp.l	#'AYER',(A0)+
	bne.b	.fail
	tst.l	20(A0)				; Song pointer check
	beq.b	.fail

	moveq	#0,D0
	rts
.fail
	moveq	#-1,D0
	rts



******************************************************************************
* Ben Daglish
******************************************************************************

p_bendaglish
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP 	
	p_NOP
	jmp	.song(pc) 
	p_NOP
	p_NOP
	p_NOP
	jmp .id_bendaglish(pc)
	jmp	.author(pc)
	dc.w pt_bendaglish
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_song
	dc.b	"Ben Daglish",0
.a 	dc.b	"Ben Daglish, adapted by Wanted Team",0
 even

.author
	pushpea	.a(pc),d0 
	rts

.BD_INIT  = 0+$20
.BD_PLAY  = 4+$20
.BD_END   = 8+$20
.BD_SONG  = 12+$20

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	bendaglishroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	pushm	d1-a6
	move.l	moduleaddress(a5),a0
	lea	mainvolume(a5),a1
	lea	maxsongs(a5),a2
	move	songnumber(a5),d0 	* song number, starts from 0
	move.l	bendaglishroutines(a5),a6
	jsr	.BD_INIT(a6)
	popm	d1-a6
	* INIT returns 0 on success
	rts	

.play
	move.l	bendaglishroutines(a5),a0
	jmp	.BD_PLAY(a0)

.stop
	bra.w	clearsound

.song
 if DEBUG
	moveq	#0,d0
	move	songnumber(a5),d0
	DPRINT	"Song %ld"
 endif
	pushm	all
	* Safety:
 	move.l  #$07800780,$dff09a
	move.l	bendaglishroutines(a5),a0
	jsr	.BD_SONG(a0)
	popm	all
	rts

.end
	bsr.w	rem_ciaint
	pushm	all
	* Safety: disable audio interrupts and clear requests
	* which this replayer uses. Pending interrupts
	* may trigger after code is in wrong state or deallocated.
 	move.l  #$07800780,$dff09a
	move.l	bendaglishroutines(a5),a0
	jsr	.BD_END(a0)
	popm	all
	bsr.w	clearsound
	bra.w	vapauta_kanavat


; in: a4 = module
;     d7 = module length
; out: d0 = 0, valid valid
;      d0 = -1, not valid
.id_bendaglish
	move.l	a4,a0
	cmp.w	#$6000,(A0)+
	bne.s	.fail
	move.l	A0,A1
	move.w	(A0)+,D1
	beq.b	.fail
	bmi.b	.fail
	btst	#0,D1
	bne.b	.fail
	cmp.w	#$6000,(A0)+
	bne.s	.fail
	move.w	(A0)+,D1
	beq.b	.fail
	bmi.b	.fail
	btst	#0,D1
	bne.b	.fail
	addq.l	#2,A0
	cmp.w	#$6000,(A0)+
	bne.s	.fail
	move.w	(A0),D1
	beq.b	.fail
	bmi.b	.fail
	btst	#0,D1
	bne.b	.fail
	add.w	(A1),A1
	cmp.l	#$3F006100,(A1)
	bne.s	.fail
	cmpi.w	#$3D7C,6(A1)
	bne.s	.fail
	cmpi.w	#$41FA,12(A1)
	bne.s	.fail
	moveq	#0,D0
	rts

.fail	moveq	#-1,d0
	rts


******************************************************************************
* Sidmon v2
******************************************************************************

p_sidmon2
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP 	
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp .id_sidmon2(pc)
	jmp	.author(pc)
	dc.w pt_sidmon2
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume
	dc.b	"SidMon 2",0
.a	dc.b	"Michael Kleps (Unknown/DOC 1990)",0
 even

.author
	pushpea	.a(pc),d0 
	rts


.INIT  = 0+$20
.PLAY  = 4+$20

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	sidmon2routines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	pushm	d1-a6
	move.l	moduleaddress(a5),a0
	lea	mainvolume(a5),a1
	lea	dmawait(pc),a2
	move.l	sidmon2routines(a5),a6
	jsr	.INIT(a6)
	popm	d1-a6
	moveq	#0,d0
	rts	

.play
	move.l	sidmon2routines(a5),a0
	jmp	.PLAY(a0)

.stop
	bra.w	clearsound

.end
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat


; in: a4 = module
;     d7 = module length
; out: d0 = 0, valid valid
;      d0 = -1, not valid
.id_sidmon2
	lea		.idStart(pc),a1
	moveq	#.idEnd-.idStart,d0
	bra.w 	search

.idStart	dc.b	'SIDMON II - THE MIDI VERSION'
.idEnd 
 even 


******************************************************************************
* Delta Music 1
******************************************************************************

p_deltamusic1
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP 	
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp .id_deltamusic1(pc)
	jmp	.author(pc)
	dc.w pt_deltamusic1
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume
	dc.b	"Delta Music 1",0
.a 	dc.b	"Bent Nielsen",0
 even

.author
	pushpea	.a(pc),d0 
	rts

.INIT  = 0+$20
.PLAY  = 4+$20

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	deltamusic1routines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	pushm	d1-a6
	move.l	moduleaddress(a5),a0
	lea	mainvolume(a5),a1
	lea	dmawait(pc),a2
	move.l	deltamusic1routines(a5),a6
	jsr	.INIT(a6)
	popm	d1-a6
	moveq	#0,d0
	rts	

.play
	move.l	deltamusic1routines(a5),a0
	jmp	.PLAY(a0)

.stop
	bra.w	clearsound

.end
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat


; in: a4 = module
;     d7 = module length
; out: d0 = 0, valid valid
;      d0 = -1, not valid
.id_deltamusic1
	move.l 	a4,a0
	move.l  d7,d0
	cmp.l	#"ALL ",(a0)
	bne.b	.no
	moveq	#104,d1
	lea	4(a0),a1
	moveq	#24,d2
.l	cmp.l	(a1)+,d1
	dbf	d2,.l
	cmp.l 	d1,d0
	blo.b 	.no
	moveq	#0,d0
	rts
.no	moveq	#-1,d0 
	rts

******************************************************************************
* SoundFX
******************************************************************************

p_soundfx
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP 	
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp .id_soundfx(pc)
	jmp	.author(pc)
	dc.w pt_soundfx
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_poslen!pf_scope!pf_quadscopePoke
	dc.b	"SoundFX",0
.a 	dc.b	"Christian Haller, Christian A. Webber",0
 even

.author
	pushpea	.a(pc),d0 
	rts

.INIT  = 0+$20
.PLAY  = 4+$20

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	soundfxroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	pushm	d1-d7/a1-a6
	move.l	moduleaddress(a5),a0
	lea	mainvolume(a5),a1
	lea	dmawait(pc),a2
	lea	pos_nykyinen(a5),a3
	lea 	pos_maksimi(a5),a4
	move.l	soundfxroutines(a5),a6
	lea	scopeData(a5),a5
	jsr	.INIT(a6)
	popm	d1-d7/a1-a6
	move.l	a0,deliPatternInfo(a5)
	moveq	#0,d0
	rts	

.play
	move.l	soundfxroutines(a5),a0
	jmp	.PLAY(a0)

.stop
	bra.w	clearsound

.end
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat


; in: a4 = module
;     d7 = module length
; out: d0 = 0, valid valid
;      d0 = -1, not valid
.id_soundfx
	cmp.l	#"SONG",60(a4)
	bne.b	.no
	moveq	#0,d0
	rts
.no	moveq	#-1,d0 
	rts

******************************************************************************
* GlueMon
******************************************************************************

p_gluemon
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP 	
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp .id_gluemon(pc)
	jmp	.author(pc)
	dc.w pt_gluemon
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_end
	dc.b	"GlueMon",0
.a	dc.b	"Lars Malmborg (GlueMaster/North Star)",0
 even

.author
	pushpea	.a(pc),d0 
	rts

.INIT  = 0+$20
.PLAY  = 4+$20
.END   = 8+$20

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea 	gluemonroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	pushm	d1-a6
	move.l	moduleaddress(a5),a0
	lea	mainvolume(a5),a1
	lea	songover(a5),a2
	lea 	pos_maksimi(a5),a3
	lea	pos_nykyinen(a5),a4
	move.l	gluemonroutines(a5),a6
	jsr	.INIT(a6)
	popm	d1-a6
	moveq	#0,d0
	rts	

.play
	move.l	gluemonroutines(a5),a0
	jmp	.PLAY(a0)

.stop
	lea	$dff096,a0
	moveq	#0,d0
	move	d0,$a8-$96(a0)
	move	d0,$b8-$96(a0)
	move	d0,$c8-$96(a0)
	move	d0,$d8-$96(a0)
	;bra.w	clearsound
	rts

.end
	move.l	gluemonroutines(a5),a0
	jsr	.END(a0)
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat


; in: a4 = module
;     d7 = module length
; out: d0 = 0, valid valid
;      d0 = -1, not valid
.id_gluemon
	cmp.l	#"GLUE",(a4)
	bne.b	.no
	cmp.l	#~"GLUE",4(a4)
	bne.b	.no
	moveq	#0,d0
	rts
.no	moveq	#-1,d0 
	rts

******************************************************************************
* PreTracker
******************************************************************************

p_pretracker
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP 	
	p_NOP
	jmp	.song(pc)
	p_NOP
	p_NOP
	p_NOP
	jmp .id_pretracker(pc)
	jmp	.pre_author(pc)
	dc.w pt_pretracker
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_scope!pf_quadscopePoke!pf_poslen!pf_end!pf_song
	dc.b	"PreTracker by Pink/aBYSs",0
.author = *-11
 even

.offset_init = $20+0
.offset_play = $20+4
.offset_stop = $20+8
.offset_song = $20+12

.pre_author
	pushpea	.author(pc),d0
	rts

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea 	pretrackerroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	jsr	setMainWindowWaitPointer
	pushm	d2-d7/a1-a6
	move.l	moduleaddress(a5),a0
	lea	scopeData(a5),a1
	lea	mainvolume(a5),a2
	lea	songover(a5),a3
	move.l pretrackerroutines(a5),a4
	jsr	.offset_init(a4)
	popm	d2-d7/a1-a6
	jsr	clearMainWindowWaitPointer
	tst.l	d0
	beq.b 	.noMem
	bmi.b	.initErr
;	move.l	a0,deliPatternInfo(a5)
	subq	#1,d1
	move	d1,maxsongs(a5)

 if DEBUG
 	moveq	#0,d0
	move	d1,d0
	DPRINT	"Songs %ld"
 endif
	moveq	#0,d0
	rts	

.noMem
	moveq #ier_nomem,d0
	rts

.initErr
	moveq #ier_not_compatible,d0
	rts

.play
	push	a5
	move.l	pretrackerroutines(a5),a0
	jsr	.offset_play(a0)
	pop	a5
	move	d0,pos_nykyinen(a5)
	move	d1,pos_maksimi(a5)
	rts
	
.stop
	bra.w	clearsound

.end
	bsr.w	rem_ciaint
	bsr.w	clearsound
	move.l pretrackerroutines(a5),a0
	jsr	.offset_stop(a0)
	bra.w	vapauta_kanavat

.song
	moveq	#0,d0
	move	songnumber(a5),d0
	DPRINT	"Setting subsong %ld"
	move.l pretrackerroutines(a5),a0
	jmp	.offset_song(a0)

.id_pretracker 
	bsr.b 	id_pretracker_
	bne.b .x
	lea	$14(a4),a1
	moveq	#20-1,d0
	bsr.w	copyNameFromA1
	moveq	#0,d0
.x  rts

; in: a4 = module
;     d7 = module length
; out: d0 = 0, valid valid
;      d0 = -1, not valid
id_pretracker_
	move.l	(a4),d0
	lsr.l	#8,d0
	cmp.l	#"PRT",d0
	bne.b	.no
	tst	4(a4)
	bne.b	.no
	tst	8(a4)
	bne.b	.no
	tst	$c(a4)
	bne.b	.no
	moveq	#0,d0
	rts
.no	moveq	#-1,d0 
	rts

******************************************************************************
* CustomMade
******************************************************************************

p_custommade
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP 	
	p_NOP
	jmp	.song(pc) 
	p_NOP
	p_NOP
	p_NOP
	jmp .id_custommade(pc)
	jmp	.author(pc)
	dc.w pt_custommade
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_song
	dc.b	"CustomMade",0
.a 	dc.b	"Ivo Zoer & Ron Klaren, adapted by Andy Silva & Wanted Team",0
 even

.author
	pushpea	.a(pc),d0 
	rts

 even

.INIT  = 0+$20
.PLAY  = 4+$20
.SONG  = 8+$20

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	custommaderoutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	pushm	d1-a6
	move.l	moduleaddress(a5),a0
	lea	mainvolume(a5),a1
	lea 	songover(a5),a2
	move.l	custommaderoutines(a5),a3
	jsr	.INIT(a3)

*   d1 = min song, always 1
*   d2 = max song
*   d3 = timer value

	subq	#1,d2 
	clr	songnumber(a5)
	move	d2,maxsongs(a5)

	move	d3,d0 
	bsr.w	ciaint_setTempoFromD0

	popm	d1-a6
	* INIT returns 0 on success
	moveq	#0,d0
	rts	

.play
	move.l	custommaderoutines(a5),a0
	jmp	.PLAY(a0)

.stop
	bra.w	clearsound

.song
 if DEBUG
	moveq	#0,d0
	move	songnumber(a5),d0
	DPRINT	"Song %ld"
 endif
	* starts from 1, not 0
	addq	#1,d0
	move.l	custommaderoutines(a5),a0
	jsr	.SONG(a0)
	rts

.end
	bsr.w	rem_ciaint
	bsr.w	clearsound
	bra.w	vapauta_kanavat


; in: a4 = module
;     d7 = module length
; out: d0 = 0, valid valid
;      d0 = -1, not valid
.id_custommade
	move.l	a4,a0
	moveq	#-1,D0
	
	cmp.w	#$4EF9,(A0)		; jmp
	beq.b	.Later
	cmp.w	#$4EB9,(A0)		; jsr
	beq.b	.Later
	cmp.w	#$6000,(A0)		; bra.w
	bne.b	.Fault
	cmp.w	#$6000,4(A0)
	beq.b	.More
.Fault
	rts
.Later
	cmp.w	#$4EF9,6(A0)
	bne.b	.Fault
.More
	lea	8(A0),A1
	lea	400(A1),A2
.Last
	cmp.l	#$42280030,(A1)
	bne.b	.NOM
	cmp.l	#$42280031,4(A1)
	bne.b	.NOM
	cmp.l	#$42280032,8(A1)
	beq.b	.Found
.NOM
	addq.l	#2,A1
	cmp.l	A1,A2
	bne.b	.Last
	rts
.Found
	moveq	#0,D0
	rts



******************************************************************************
* Dave Lowe
******************************************************************************

p_davelowe
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP 	
	p_NOP
	jmp	.song(pc) 
	p_NOP
	p_NOP
	p_NOP
	jmp id_davelowe(pc)
	jmp	.author(pc)
	dc.w pt_davelowe
	dc pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_song!pf_end
	dc.b	"Dave Lowe",0
.a 	dc.b	"Dave Lowe, adapted by Wanted Team",0
 even

.author
	pushpea	.a(pc),d0 
	rts

.INIT  = 0+$20
.PLAY  = 4+$20
.END   = 8+$20
.SONG  = 12+$20

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	daveloweroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	pushm	d1-a6
	move.l	moduleaddress(a5),a0 
	* LoadSeg BPTR->APTR
	add.l	a0,a0
	add.l	a0,a0
	lea	mainvolume(a5),a1 
	lea	songover(a5),a2
	move.l	daveloweroutines(a5),a3
	jsr	.INIT(a3)
	subq	#1,d2
	move	d2,maxsongs(a5)

 if DEBUG
 	push	d0
	move.l	d1,d0
	move.l	d2,d1
	move.l	d3,d2
	DPRINT	"Range %ld-%ld %s"
	pop	d0
 endif
	tst.l	d3
	beq.b	.x
	move.l	d3,a0
	lea	modulename(a5),a1
.c	move.b	(a0)+,(a1)+
	bne.b	.c
.x
	popm	d1-a6
	* INIT returns 0 on success
	rts	

.play
	move.l	daveloweroutines(a5),a0
	jsr	.PLAY(a0)
	rts

.stop
	bra.w	clearsound

.song
 if DEBUG
	moveq	#0,d0
	move	songnumber(a5),d0
	addq	#1,d0
	DPRINT	"Song %ld"
 endif
	move.l	daveloweroutines(a5),a0
	jmp .SONG(a0)

.end
	bsr.w	rem_ciaint
	pushm	all
	move.l	daveloweroutines(a5),a0
	jsr	.END(a0)
	popm	all
	bsr.w	clearsound
	bra.w	vapauta_kanavat


; in: a4 = module
;     d7 = module length
; out: d0 = 0, valid valid
;      d0 = -1, not valid
id_davelowe
	move.l	a4,a0
	cmp.l	#$000003F3,(A0)
	bne.b	.fail
	tst.b	20(A0)				; loading into chip check
	beq.b	.fail
	lea	32(A0),A0
	cmp.l	#$70FF4E75,(A0)+
	bne.b	.fail
	cmp.l	#'UNCL',(A0)+
	bne.b	.fail
	cmp.l	#'EART',(A0)+
	bne.b	.fail
	tst.l	(A0)+				; InitSound pointer check
	beq.b	.fail
	tst.l	(A0)+				; Interrupt pointer check
	beq.b	.fail
	addq.l	#4,A0
	tst.l	(A0)				; Subsong Counter label check
	beq.b	.fail
	moveq	#0,D0
	rts
.fail
	moveq	#-1,D0
	rts


******************************************************************************
* StarTrekker AM
******************************************************************************

p_startrekker
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	p_NOP 	
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	p_NOP
	jmp 	.id(pc)
	jmp	.author(pc)
	dc.w 	pt_startrekker
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_poslen!pf_scope!pf_quadscopePoke
	dc.b	"StarTrekker AM",0
.a 	dc.b "Bjoern Wesen/Exolon of Fairlight",0
 even

.author
	pushpea	.a(pc),d0 
	rts
	
.INIT  = 0+$20
.PLAY  = 4+$20
.END   = 8+$20


.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	startrekkerroutines(a5),a0
	bsr.w	allocreplayer2
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	pushm	d1-a6

	move.l	moduleaddress(a5),a0
	move	#950/2-1,d0
	lea	ptheader,a1
.cl	move	(a0)+,(a1)+
	dbf	d0,.cl


	* Load extra data file ".nt"
	jsr	getcurrent 
	* a3 = node
	lea	-200(sp),sp
	lea	l_filename(a3),a0 
	move.l	sp,a1
.c	move.b	(a0)+,(a1)+
	bne.b	.c
	subq	#1,a1
	move.b	#".",(a1)+
	move.b	#"n",(a1)+
	move.b	#"t",(a1)+
	clr.b	(a1)

	move.l	sp,a0
	bsr.b	.loadExtraFile
	* d0 = 0 if success
 	lea	200(sp),sp

	tst.l	d0 
	beq.b 	.gotNt
	
	* Load extra data file ".as"
	* Audio Sculpture
	jsr	getcurrent 
	* a3 = node
	lea	-200(sp),sp
	lea	l_filename(a3),a0 
	move.l	sp,a1
.c2	move.b	(a0)+,(a1)+
	bne.b	.c2
	subq	#1,a1
	move.b	#".",(a1)+
	move.b	#"a",(a1)+
	move.b	#"s",(a1)+
	clr.b	(a1)

	move.l	sp,a0
	bsr.b	.loadExtraFile
	* d0 = 0 if success
 	lea	200(sp),sp

	tst.l	d0 
	bne.b 	.fileErr

.gotNt
	move.l	moduleaddress(a5),a0
	move.l	startrekkerdataaddr(a5),a1
	lea	mainvolume(a5),a2
	lea	songover(a5),a3
	lea	dmawait(pc),a4
	move.l	modulelength(a5),d0
	pushm	a5/a6
	move.l	startrekkerroutines(a5),a6
	lea	scopeData(a5),a5
	jsr	.INIT(a6)
	moveq	#0,d0
	popm 	a5/a6
	move.l	a0,deliPatternInfo(a5)
	move	d1,pos_maksimi(a5)
.x
	popm	d1-a6
	tst.l	d0
	* INIT returns 0 on success
	rts	

.loadExtraFile	
 if DEBUG
	move.l	a0,d0
	DPRINT	"Loading %ls"
 endif
	move.l	#MEMF_CHIP!MEMF_CLEAR,d0
	lea	startrekkerdataaddr(a5),a1
	lea 	startrekkerdatalen(a5),a2
	jsr	loadfileStraight
	rts

.fileErr 
	* No extra data file tound. Proceed as Protracker
	DPRINT	"Revert to Protracker"
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	pushpea	p_protracker(pc),playerbase(a5)
	move	#pt_prot,playertype(a5)
	moveq	#0,d0 
	move.l	playerbase(a5),a0 
	jsr	p_init(a0)
	bra.b 	.x

.play
	push	a5
	move.l	startrekkerroutines(a5),a0
	jsr	.PLAY(a0)
	pop 	a5
	move	d0,pos_nykyinen(a5)
	rts

.stop
	bra.w	clearsound

.end
	bsr.w	rem_ciaint
	move.l	startrekkerroutines(a5),a0
	jsr	.END(a0)
	bsr.w	clearsound
	bra.w	vapauta_kanavat

.id
	bsr.b	.id_
	bne.b 	.nok
	moveq	#20-1,d0
	bsr.w	copyNameFromModule
	moveq	#0,d0	
.nok	rts

; in: a4 = module
;     d7 = module lenght
; out: d0 = 0, valid valid
;      d0 = -1, not valid
.id_
	cmp.l	#"FLT4",$438(a4)
	beq.s	.k
	cmp.l	#"EXO4",$438(a4)
	beq.s	.k
	moveq	#-1,d0
	rts 
.k
	moveq	#0,d0
	rts


******************************************************************************
* Voodoo Supreme Synthesizer
******************************************************************************

p_voodoosupremesynthesizer
	jmp	.init(pc)
	jmp	.play(pc)
	p_NOP
	jmp	.end(pc)
	jmp	.stop(pc)
	jmp	.cont(pc)
	jmp	.vol(pc)
	jmp	.song(pc)
	p_NOP
	p_NOP
	p_NOP
	jmp 	.id(pc)
	jmp	.author(pc)
	dc.w 	pt_voodoosupremesynthesizer
	dc	pf_stop!pf_cont!pf_ciakelaus!pf_volume!pf_song
	dc.b	"VoodooSupremeSynthesizer",0
.a 	dc.b "Thomas Partl",0
 even

.author
	pushpea	.a(pc),d0 
	rts

.INIT  = 0+$20
.PLAY  = 4+$20
.END   = 8+$20
.VOL   = 12+$20
.SONG  = 16+$20

.init
	bsr.w	varaa_kanavat
	beq.b	.ok
	moveq	#ier_nochannels,d0
	rts
.ok	
	bsr.w	init_ciaint
	beq.b	.ok2
	bsr.w	vapauta_kanavat
	moveq	#ier_nociaints,d0
	rts
.ok2
	lea	voodooroutines(a5),a0
	bsr.w	allocreplayer
	beq.b	.ok3
	bsr.w	rem_ciaint
	bsr.w	vapauta_kanavat
	rts
.ok3
	move.l	moduleaddress(a5),a0
	move.l	modulelength(a5),d0
	lea	songover(a5),a1
	move.l	voodooroutines(a5),a2
	jsr	.INIT(a2)
	tst.l	d0
	bne.b	.noMem

	* min song = d1
	* max song = d2
	move	d2,maxsongs(a5)

	bsr.b	.vol
	moveq	#0,d0
	rts

.noMem
	moveq	#ier_nomem,d0
	rts
.end
	bsr.w	rem_ciaint
	move.l	voodooroutines(a5),a0
	jsr	.END(a0)
	bsr.w	clearsound
	bsr.w	vapauta_kanavat
	rts

.play
	move.l	voodooroutines(a5),a0
	jsr	.PLAY(a0)
	rts
.stop
	bra.w	clearsound
.cont
	rts
.vol
	move	mainvolume(a5),d0
	move.l	voodooroutines(a5),a0
	jmp	.VOL(a0)
.song	
	move	songnumber(a5),d0
	move.l	voodooroutines(a5),a0
	jmp	.SONG(a0)
	
.id
	move.l	a4,a0
	move.l	d7,d0
	ADDQ.L	#1,D0
	AND.L	#$FFFFFFFE,D0
	ADD.L	D0,A0
	MOVEQ	#-1,D0
	SUB.W	#$40,A0
	MOVEQ	#$1F,D1
.lbC000360	
	CMP.L	#$56535330,(A0)
	BEQ.B	.lbC000372
	ADDQ.L	#2,A0
	DBRA	D1,.lbC000360
	RTS
.lbC000372	
	CMP.L	#$100,4(A0)
	BHS.B	.no
	MOVEQ	#0,D0
.no
	RTS

******************************************************************************
* Quartet
******************************************************************************

p_quartet
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp 	.id(pc)
	jmp	deliAuthor(pc)
	dc  	pt_quartet 
 	dc 	pf_stop!pf_cont!pf_volume!pf_end!pf_poslen!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"Quartet             [EP]",0

.path dc.b "quartet",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|1,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l	a4,a0
        cmp.b   #$50,1(A0)
        bne.b   .Fault
        cmp.b   #30,(A0)
        bhi.b   .Fault
        moveq   #0,D1
        move.b  (A0),D1
        beq.b   .Fault
        move.l  #3000,D2                        ; max. tempo
        divu.w  D1,D2
        swap    D2
        tst.w   D2
        bne.b   .Fault
     move.l  d7,D2
        bclr    #0,D2
        add.l   D2,A0
        moveq   #15,D2
        moveq   #-1,D3
.NextEnd
        move.w  -(A0),D1
        beq.b   .Zero
        cmp.w   D3,D1
        beq.b   .CheckEnd
.Fault
        moveq   #-1,D0
        rts
.Zero
        dbf     D2,.NextEnd
        bra.b   .Fault
.CheckEnd
        cmp.l   -2(A0),D3
        bne.b   .Fault
        cmp.l   -6(A0),D3
        bne.b   .Fault
        moveq   #0,D0
	rts

******************************************************************************
* Face The Music
******************************************************************************

p_facethemusic
	jmp	.init(pc)
	jmp	deliPlay(pc)
	jmp	.ftmVBlank(pc)
	jmp	.end(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_facethemusic 
.flags 	dc pf_stop!pf_cont!pf_volume!pf_end	
	dc.b	"Face The Music      [EP]",0

.path dc.b "face the music",0
 even


.init
	lea	.path(pc),a0 
	moveq	#0<<16|7,d0
	bsr.w	deliLoadAndInit
	bne.b	.error

	* Some tunes seem to end prematurely, try this
	lea	.flags(pc),a0
	and	#~pf_end,(a0)
	moveq	#0,d0
.error	
	rts


.end
	bsr.w	deliEnd
	* Extra safety:
	move.l  #$07800780,$dff09a
	rts

.id
	bsr.b	.do
	bne.b	.not 
	bsr.w 	moveModuleToPublicMem
	moveq	#0,d0
.not		
	rts

.do
	MOVEQ	#0,D0
	MOVE.L	(A4),D1
	AND.L	#$FFFFFF00,D1
	CMP.L	#$46544D00,D1
	SNE	D0
	rts

.ftmVBlank
	* Need to call this so that volume and voices are updated.
	* FTM uses it's own interrupt otherwise.
	bra.w	deliInterrupt

******************************************************************************
* Richard Joseph
******************************************************************************

p_richardjoseph
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_richardjoseph
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_poslen!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"R.Joseph/VectorDean [EP]",0
.path dc.b "richard joseph player",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|2,d0
	bsr.w	deliLoadAndInit
	bne.b	.error

	* Some tunes seem to end prematurely, try this
	lea	.flags(pc),a0
	and	#~pf_end,(a0)
	moveq	#0,d0
.error	
	rts

.id
        movea.l a4,A0
        moveq   #-1,D0
        move.l  (A0)+,D1
        clr.b   D1
        cmp.l   #$524A5000,D1
        bne.b   .Fault
        cmp.l   #'SMOD',(A0)+
        bne.b   .Fault
        addq.l  #4,A0
        tst.l   (A0)
        bne.b   .Fault
        moveq   #0,D0
.Fault
        rts


******************************************************************************
* In Stereo 1
******************************************************************************

p_instereo1
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp 	.id(pc)
	jmp	deliAuthor(pc)
	dc 	pt_instereo1
	dc 	pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus
	dc.b	"In Stereo! 1.0      [EP]",0

.path dc.b "in stereo 1.0",0
 even

* Let's bend over backwards for this one.
* It is an amplifier eagleplayer, so it can run
* with data in fast ram. The replay code contains waveform
* buffers. They need to be in chip. Therefore,
* patch the eagleplayer to load into chip ram before loading it.

.init	pushm	d1-a6	

	* First, find it.
	lea	.path(pc),a3
	bsr.w	findDeliPlayer
	beq.w	.error 
	move.l d0,d7 	* lock

	* Get the path
	lea	-100(sp),sp
	move.l 	d7,d1
	move.l	sp,d2
	moveq	#100,d3 
	bsr.w	getNameFromLock
	move.l  d0,d6 

	move.l	d7,d1
	lore  Dos,UnLock

	tst.l	d6 
	beq.w 	.nameFromLockErr
	
	* Read it
	move.l	sp,a0
	bsr.w	plainLoadFile 
	lea	100(sp),sp 
	tst.l  d0 
	beq.b  .fileError 

	* Grab the 1st entry from the hunk size table and set
	* 31th bit to 0, 30th bit to 1, to indicate hunk should be loaded
	* into chip.
	move.l	d0,a1
	move.l	d0,d3
	move.l 	20(a1),d0 
	and.l	#%00111111111111111111111111111111,d0 
	or.l	#%01000000000000000000000000000000,d0 
	move.l	d0,20(a1)

	move.l	d1,d0
	lea	-100(sp),sp 
	move.l	sp,a0
	move.b	#'R',(a0)+
	move.b	#'A',(a0)+
	move.b	#'M',(a0)+
	move.b	#':',(a0)+
	lea	.path(pc),a2 
.c	move.b	(a2)+,(a0)+
	bne.b	.c
	move.l	sp,a0
	bsr.w	plainSaveFile 
	lea	100(sp),sp

	move.l	d3,a0 
	jsr	freemem

	tst.l	d0 
	bmi.b 	.fileError

	lea	.path(pc),a0 
	move.l	#5<<16|0,d0

	* Camouflage playertype so that the group lookup 
	* will fail and loader will look into 
	* filesystem, finding the above patched player.
	move	playertype(a5),-(sp)
	move	#-1,playertype(a5)
	bsr.w	deliLoadAndInit
	move	(sp)+,playertype(a5)
	tst.l	d0

.error	popm	d1-a6
	rts

.fileError 
	lea	100(sp),sp
	moveq	#-1,d0
	bra.b  .error 	

.nameFromLockErr
	lea	100(sp),sp 
	moveq	#-1,d0 
	bra.b 	.error


.id
	MOVEQ	#1,D0
	CMP.L	#$49534D21,(A4)
	BNE.b .f 
	CMP.L	#$56312E32,4(A4)
	BNE.b .f
	MOVEQ	#0,D0
.f	rts

******************************************************************************
* In Stereo 2
******************************************************************************

p_instereo2
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp 	.id(pc)
	jmp	deliAuthor(pc)
	dc 	pt_instereo2
	dc 	pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus
	dc.b	"In Stereo! 2.0      [EP]",0

.path dc.b "in stereo 2.0",0
 even

.init
	lea	.path(pc),a0 
	move.l	#2<<16|1,d0
	bsr.w	deliLoadAndInit
	rts 

.id
 	MOVEQ	#1,D0
	CMP.L	#$49533230,(A4)
	BNE.S	.f
	CMP.L	#$44463130,4(A4)
	BNE.S	.f
	CMP.L	#$5354424C,8(A4)
	BNE.S	.f
	MOVEQ	#0,D0
.f  
	rts



******************************************************************************
* Jason Brooke
******************************************************************************

p_jasonbrooke
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_jasonbrooke
	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_poslen!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"Jason Brooke        [EP]",0
	        
.path dc.b "jason brooke",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|1,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l	a4,a0

	MOVEQ	#-1,D0
	;LEA	lbW000166(PC),A1
	MOVE.L	A0,A2
	CMP.L	#$48E7F0F0,(A0)+
	BNE.S	.lbC00058C
	CMP.L	#$424047FA,(A0)+
	BNE.S	.lbC00058A
	CMP.L	#$FFF84A2B,(A0)
	BNE.S	.lbC00058A
	;ST	(A1)
.lbC000588	MOVEQ	#0,D0
.lbC00058A	RTS

.lbC00058C	LEA	$AC(A2),A0
	MOVEQ	#$19,D1
.lbC000592	CMP.W	#$48E7,(A0)+
	BEQ.S	.lbC00059E
	DBRA	D1,.lbC000592
	BRA.S	.lbC00058A

.lbC00059E	CMP.W	#$F8FC,(A0)
	BEQ.S	.lbC0005AA
	CMP.W	#$F8F8,(A0)
	BNE.S	.lbC00058A
.lbC0005AA	ADDQ.L	#2,A0
	CMP.L	#$8F90001,(A0)+
	BNE.S	.lbC00058A
	CMP.L	#$BFE001,(A0)+
	BNE.S	.lbC00058A
	CMP.L	#$33FC0780,(A0)+
	BNE.S	.lbC00058A
	CMP.L	#$DFF09A,(A0)+
	BNE.S	.lbC00058A
	CMP.W	#$47FA,(A0)+
	BNE.S	.lbC00058A
	MOVEQ	#1,D1
	SWAP	D1
	MOVEQ	#0,D2
	MOVE.W	(A0),D2
	SUB.L	D2,D1
	SUB.L	D1,A0
	CMP.L	A2,A0
	BNE.S	.lbC00058A
	;CLR.W	(A1)
	BRA.S	.lbC000588


******************************************************************************
* EarAche
******************************************************************************

p_earache
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_earache
	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_poslen!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"EarAche             [EP]",0
	        
.path dc.b "earache",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|1,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l	a4,a0
	bsr.b 	.id_ 
	tst.l d0
	rts

.id_
	moveq	#-1,D0

	tst.w	(A0)
	beq.b	.CheckRout
	cmp.l	#'EASO',(A0)
	bne.b	.NoHead
	addq.l	#4,A0
	bra.b	.CheckRout
.NoHead
	cmp.w	#$6000,(A0)+
	bne.b	.Fault
	move.l	A0,A1
	move.w	(A0)+,D1
	beq.b	.Fault
	bmi.b	.Fault
	btst	#0,D1
	bne.b	.Fault
	cmp.w	#$6000,(A0)+
	bne.b	.Fault
	move.w	(A0)+,D2
	beq.b	.Fault
	bmi.b	.Fault
	btst	#0,D2
	bne.b	.Fault
	add.w	D1,A1
	cmp.l	#$33FC000F,(A1)+
	bne.b	.Fault
	cmp.l	#$00DFF096,(A1)+
	bne.b	.Fault
	cmp.w	#$43FA,(A1)+
	bne.b	.Fault
	move.w	(A1),D1
	beq.b	.Fault
	bmi.b	.Fault
	btst	#0,D1
	bne.b	.Fault
	add.w	D1,A1
	move.l	A1,A0
.CheckRout
	cmp.l	#$18,(A0)		; check routine taken from EarAche editor
	bne.b	.Fault
	move.l	4(A0),D2
	sub.l	(A0),D2
	ble.b	.Fault
	and.w	#7,D2
	bne.b	.Fault
	move.l	$10(A0),D2
	sub.l	8(A0),D2
	ble.b	.Fault
	and.w	#15,D2
	bne.b	.Fault
	moveq	#0,D0
.Fault
	rts



******************************************************************************
* Kris Hatlelid
******************************************************************************

p_krishatlelid
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	.end(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_krishatlelid
	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_poslen!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"Kris Hatlelid       [EP]",0
	        
.path dc.b "kris hatlelid",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|1,d0
	bsr.w	deliLoadAndInit
	rts 

.end
	* Safety: disable audio interrupts and clear requests
	* which this replayer uses. Pending interrupts
	* may trigger after code is in wrong state or deallocated.
	move.l  #$07800780,$dff09a
	bra.w	deliEnd

.id
	move.l	a4,a0
	CMP.L	#$3F3,(A0)+
	BNE.S	.lbC000506
	TST.L	(A0)+
	BNE.S	.lbC000506
	CMP.L	#3,(A0)+
	BNE.S	.lbC000506
	TST.L	(A0)+
	BNE.S	.lbC000506
	CMP.L	#2,(A0)+
	BNE.S	.lbC000506
	MOVE.L	(A0)+,D1
	BCLR	#$1E,D1
	CMP.B	#$40,(A0)
	BNE.S	.lbC000506
	ADDQ.L	#4,A0
	CMP.L	#1,(A0)+
	BNE.S	.lbC000506
	CMP.L	#$3E9,(A0)+
	BNE.S	.lbC000506
	CMP.L	(A0)+,D1
	BNE.S	.lbC000506
	CMP.L	#$60000016,(A0)+
	BNE.S	.lbC00050A
	CMP.L	#$ABCD,(A0)+
	BNE.S	.lbC000506
	CMP.L	#$B07C0000,$10(A0)
	BNE.S	.lbC00050E
	BRA.S	.lbC000524

.lbC000506	MOVEQ	#-1,D0
	RTS

.lbC00050A	LEA	-$14(A0),A0
.lbC00050E	CMP.L	#$41F90000,$10(A0)
	BNE.S	.lbC000506
	CMP.L	#$4E75,$14(A0)
	BNE.S	.lbC000506
.lbC000524	MOVEQ	#0,D0
	RTS



******************************************************************************
* Richard Joseph
******************************************************************************

p_richardjoseph2
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_richardjoseph2
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_poslen!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"Richard Joseph      [EP]",0
	
	        
.path dc.b "richard joseph",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|2,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	MOVE.L	a4,A0
	CMP.L	#$3F3,(A0)
	BNE.S	.lbC00043E
	TST.B	$14(A0)
	BEQ.S	.lbC00043E
	LEA	$20(A0),A0
	CMP.L	#$70FF4E75,(A0)+
	BNE.S	.lbC00043E
	CMP.L	#$522E4A4F,(A0)+
	BNE.S	.lbC00043E
	CMP.L	#$53455048,(A0)+
	BNE.S	.lbC00043E
	TST.L	(A0)+
	BEQ.S	.lbC00043E
	TST.L	(A0)+
	BEQ.S	.lbC00043E
	TST.L	(A0)+
	BEQ.S	.lbC00043E
	TST.L	(A0)
	BEQ.S	.lbC00043E
	MOVEQ	#0,D0
	RTS

.lbC00043E	MOVEQ	#-1,D0
	RTS



******************************************************************************
* Hippel 7ch
******************************************************************************

p_hippel7
	jmp	.init(pc)
	jmp	deliPlay(pc)
	jmp	deliInterrupt(pc) ; handle position and vol updates
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	p_NOP
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp id_hippel7(pc)
	jmp	deliAuthor(pc)
	dc  pt_hippel7
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_poslen
	dc.b	"Jochen Hippel 7v    [EP]",0
		        
.path dc.b "jochen hippel 7v",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|4,d0
	bsr.w	deliLoadAndInit
	rts 

id_hippel7
	bsr.b	.id
	bne.b	.not
	* This is identified as TFMX song data which goes into
	* public mem, fix it.
	bsr.w	moveModuleToChipMem
	moveq	#0,d0
.not
	rts
.id
	move.l	a4,a0
	moveq	#-1,D0

	cmp.w	#$6000,(A0)
	bne.b	.Song
	addq.l	#2,A0
	move.w	(A0),D1
	beq.b	.Fault
	bmi.b	.Fault
	btst	#0,D1
	bne.b	.Fault
	lea	(A0,D1.W),A0
	moveq	#10,D1
.Find_1
	cmp.l	#$308141FA,(A0)
	beq.b	.OK_1
	addq.l	#2,A0
	dbf	D1,.Find_1
	rts
.OK_1
	addq.l	#4,A0
	move.w	(A0),D1
	beq.b	.Fault
	bmi.b	.Fault
	btst	#0,D1
	bne.b	.Fault
	lea	(A0,D1.W),A0
.Song
	cmp.l	#'TFMX',(A0)+
	bne.b	.Fault
	tst.b	(A0)
	bne.b	.Fault
	moveq	#2,D1
	add.w	(A0)+,D1
	add.w	(A0)+,D1
	lsl.l	#6,D1
	moveq	#1,D2
	add.w	(A0)+,D2
	moveq	#1,D3
	add.w	(A0)+,D3
	mulu.w	#28,D3
	mulu.w	(A0)+,D2
	add.l	D2,D1
	add.l	D3,D1
	addq.l	#2,A0
	moveq	#1,D2
	add.w	(A0)+,D2
	lsl.l	#3,D2
	add.l	D2,D1
	moveq	#32,D2
	add.l	D2,D1
	add.l	D1,A0
	tst.l	(A0)+
	bne.b	.Fault
	move.w	(A0),D2
	beq.b	.Fault
	add.l	D2,D2
	cmp.l	26(A0),D2
	bne.b	.Fault
	moveq	#0,D0
.Fault
	tst.l	d0
	rts

******************************************************************************
* AProSys
******************************************************************************

p_aprosys
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_aprosys
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"AProSys             [EP]",0
		        
.path dc.b "aprosys",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|1,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	CMP.L	#$41445256,(A4)
	BNE.S	.f
	CMP.L	#$5041434B,4(A4)
	BNE.S	.f
	MOVEQ	#0,D0
	rts
.f	
	MOVEQ	#-1,D0
	RTS



******************************************************************************
* Jochen Hippel ST (also Jochen Hippel COSO ST)
******************************************************************************

p_hippelst
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_hippelst
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_poslen!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"Jochen Hippel ST    [EP]",0	        
.path dc.b "jochen hippel st",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|4,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l	a4,a0
	move.l	d7,d0

        ;move.l  dtg_ChkData(A5),A0
        ;move.l  dtg_ChkSize(A5),D0
        move.l  A0,A4
        bsr.b   .Check
        cmp.w   #2,D0
        bne.b   .Fault
        moveq   #0,D1
        cmp.l   #'LSMP',$1C(A0)
        bne.b   .OneFile
        moveq   #1,D1
.OneFile
        ;lea     TwoFiles(PC),A1
        ;move.l  D1,(A1)+
        ;sub.l   A4,A0
        ;move.l  A0,(A1)
        moveq   #0,D0
        bra.b   .Found

.Fault   moveq   #-1,D0
.Found   rts

.Check
.lbC0001C0	MOVEA.L	A0,A1
	MOVEQ	#$7F,D1
	BRA.S	.lbC0001DA

.lbC0001C6	CMPI.W	#$41FA,(A1)+
	BNE.S	.lbC0001F2
	MOVE.W	(A1),D2
	BMI.S	.lbC0001F2
	BTST	#0,D2
	BNE.S	.lbC0001F2
	LEA	0(A1,D2.W),A0
.lbC0001DA	CMPI.L	#'MMME',(A0)
	BEQ.S	.lbC0001FC
	CMPI.L	#'TFMX',(A0)
	BEQ.S	.lbC000204
	CMPI.L	#'COSO',(A0)
	BEQ.S	.lbC000262
.lbC0001F2	SUBQ.L	#2,D0
	DBMI	D1,.lbC0001C6
.lbC0001F8	MOVEQ	#0,D0
	RTS

.lbC0001FC
;	MOVEQ	#1,D0
;	RTS

.lbC000200	MOVEQ	#2,D0
	RTS

.lbC000204	CMPI.W	#$200,4(A0)
	BGE.S	.lbC0001F8

	tst.w	16(A0)				; FX Check
	beq.b	.lbC0001F8

	BSR.S	.lbC000216
	CMP.L	D6,D7
	BLT.S	.lbC000230
	MOVEQ	#1+1,D0
	RTS

.lbC000216	MOVE.W	4(A0),D0
	LEA	$20(A0),A1
	MOVEQ	#0,D6
	MOVEQ	#0,D7
.lbC000222	BSR.B	.lbC0002B6
	LEA	$40(A1),A1
	DBRA	D0,.lbC000222
	RTS

.lbC000230
;	MOVEQ	#2,D0
;	ADD.W	4(A0),D0
;	ADD.W	6(A0),D0
;	MULU.W	#$40,D0
;	LEA	$20(A0,D0.W),A1
;	MOVE.W	8(A0),D0
;	MOVE.W	12(A0),D1
;	ADDQ.W	#1,D0
;	MULU.W	D0,D1
;	ADDA.L	D1,A1
;	MOVE.B	3(A1),D1
;	CMP.B	#$FF,D1
;	BNE.S	lbC00025E
	MOVEQ	#5,D0
	RTS

;lbC00025E	MOVEQ	#3,D0
;	RTS

.lbC000262
	tst.w	48(A0)				; FX Check
	beq.b	.lbC0001F8
	tst.l	24(A0)
	beq.b	.lbC0001F8

	CMPI.L	#'TFMX',$20(A0)
	BEQ.S	.lbC00027A
	CMPI.L	#'MMME',$20(A0)
	BEQ.b	.lbC000200
	MOVEQ	#0,D0
	RTS

.lbC00027A	BSR.S	.lbC000284
	CMP.L	D6,D7
	BLT.S	.lbC00029E
	MOVEQ	#2,D0
	RTS

.lbC000284	MOVEA.L	A0,A2
	ADDA.L	4(A0),A2
	MOVEQ	#0,D6
	MOVEQ	#0,D7
	MOVE.W	$24(A0),D0
.lbC000292
	tst.w	64(A0)
	beq.b	.Longer

	MOVEA.W	(A2)+,A1

	bra.b .SkipLon
.Longer
	move.l	(A2)+,A1
.SkipLon
	ADDA.L	A0,A1
	BSR.S	.lbC0002B6
	DBRA	D0,.lbC000292
	RTS

.lbC00029E
;	MOVE.L	$10(A0),D0
;	LEA	0(A0,D0.W),A1
;	CMPI.B	#$FF,3(A1)
;	BEQ.S	lbC0002B2
	MOVEQ	#4,D0
	RTS


.lbC0002B6	MOVEA.L	A1,A3
	MOVEQ	#0,D1
	MOVE.B	(A3)+,D1
	CMP.B	#$E2,D1
	BNE.S	.lbC0002CC
	TST.B	(A3)
	BMI.S	.lbC0002CA
	ADDQ.W	#1,D6
	BRA.S	.lbC0002CC

.lbC0002CA	ADDQ.W	#1,D7
.lbC0002CC	RTS



******************************************************************************
* TCBTracker
******************************************************************************

p_tcbtracker
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_tcbtracker
.flags	dc pf_scope!pf_stop!pf_cont!pf_volume!pf_end!pf_poslen!pf_ciakelaus2!pf_kelauseteen!pf_kelaustaakse!pf_quadscopeUps
	dc.b	"TCBTracker (ST)     [EP]",0	        
.path dc.b "tcb tracker",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|3,d0
	bsr.w	deliLoadAndInit
	rts 


.id
	move.l	a4,a0 
	move.l	d7,d0
	
	lea	(a0,d0.l),a2		; pour tests ultÈrieurs
	cmpi.l	 #$132,d0
	blo.b	.ohno			; trop petit
	cmpi.l	#"AN C",(a0)
	bne.b	.ohno
	moveq	#0,d3
	move.l	#"OOL!",d1		; marque avec "!"
	move.l	4(a0),d2
	cmp.l	d1,d2
	beq.s	.hm
	moveq	#1,d3
	move.b	#".",d1			; ou marque avec "."
	cmp.l	d1,d2
	bne.s	.ohno
.hm
	move.l	8(a0),d1
	cmpi.l	#127,d1			; nb patt : pas plus de 127, quand mÍme ?
	bhi.s	.ohno
	cmpi.b	#15,12(a0)		; speed en 16-n donc <16
	bhi.s	.ohno
	tst.b	13(a0)			; ‡ priori toujours 0
	bne.s	.ohno
	tst.b	$8e(a0)			; taille seq (peut pas Ítre 0 ou >7f)
	ble.s	.ohno
	lea	$110(a0),a1		; patt
	tst.b	d3
	beq.s	.fmt1
;	tst.w	$128(a0)		; faut que ce soit 0
;	bne.s	.ohno			; or 2 too, like TCB.MDemo4 5
	lea	$132(a0),a1
.fmt1
	mulu.w	#$200,d1		; taille patt (on avait encore d1=nbr)
	add.l	d1,a1			; et adr suite
	lea	$d4(a1),a3
	cmp.l	a2,a3			; regarder qu'il ne manque pas qqch...
	bhs.s	.ohno
;	move.l	(a1),d3			; taille totale d'ici
;	add.l	d3,a1
;	cmp.l	a2,a1			; tronquÈ !
;	bhi.s	.ohno
	cmpi.l	#-1,-8(a3)		; FFFFFFFF
	bne.s	.ohno
	tst.l	-4(a3)			; 00000000 (juste avant spl)
	bne.s	.ohno
	cmpi.l	#$d4,-$90(a3)		; 1er spl toujours en +$d4
	bne.s	.ohno
; todo : vÈrifier que les effets <>0 ou <>13 ne sont pas utilisÈs
;.loop

; bon, Áa devrait suffire...
; ok
	moveq	#0,d0
	rts
.ohno
	moveq	#-1,d0
	rts
;forswap				; pour calculer chklen




******************************************************************************
* Mark Cooksey
******************************************************************************

p_markcooksey
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp 	.id(pc)
	jmp	deliAuthor(pc)
	dc  	pt_markcooksey
.flags	dc 	pf_stop!pf_cont!pf_volume!pf_end!pf_poslen!pf_ciakelaus!pf_song!pf_quadscopeUps!pf_scope
	dc.b	"Mark Cooksey        [EP]",0	        
.path 	dc.b 	"mark cooksey",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0,d0
	bra	deliLoadAndInit

.id
	move.l	a4,a0
	moveq	#-1,D0

	;lea	Format(PC),A1
	cmp.l	#$D040D040,(A0)
	bne.b	.NextCheck
	cmp.w	#$4EFB,4(A0)
	bne.b	.fail
	move.w	#$6000,D1
	cmp.w	8(A0),D1
	bne.b	.fail
	cmp.w	12(A0),D1
	bne.b	.fail
	cmp.w	16(A0),D1
	bne.b	.fail
	cmp.w	20(A0),D1
	bne.b	.fail
	cmp.w	#$43FA,40(A0)
	beq.b	.Old
	cmp.w	24(A0),D1
	bne.b	.fail
	cmp.w	#$43FA,150(A0)
	bne.b	.fail
.Old
;	clr.b	(A1)
.Older
	moveq	#0,D0
.fail
	rts

.NextCheck
	cmp.w	#$601A,(A0)
	bne.b	.Third
	addq.l	#2,A0
	move.l	(A0)+,D1
	bmi.b	.fail
	btst	#0,D1
	bne.b	.fail
	tst.w	(A0)+
	bne.b	.fail
	moveq	#4,D2
.ZeroCheck
	tst.l	(A0)+
	bne.b	.fail
	dbf	D2,.ZeroCheck
	lea	2(A0),A2
	moveq	#3,D2
.BranchCheck
	cmp.w	#$6000,(A0)+
	bne.b	.fail
	move.w	(A0)+,D1
	bmi.b	.fail
	btst	#0,D1
	bne.b	.fail
	dbf	D2,.BranchCheck
	add.w	(A2),A2
	cmp.l	#$48E780F0,(A2)
	bne.b	.fail

	;st	(A1)
	bra.b	.Older

.Third
	moveq	#1,D2
.BranchCheck2
	cmp.w	#$6000,(A0)+
	bne.b	.fail2
	move.w	(A0)+,D1
	bmi.b	.fail2
	btst	#0,D1
	bne.b	.fail2
	dbf	D2,.BranchCheck2
	cmp.w	#$4DFA,(A0)+
	bne.b	.fail2
	addq.l	#2,A0
	cmp.w	#$4A56,(A0)
	beq.b	.Later
	cmp.w	#$4A16,(A0)
	bne.b	.fail2
.Later
	addq.l	#6,A0
	cmp.w	#$41F9,(A0)+
	bne.b	.fail2
	cmp.l	#$DFF000,(A0)+
	bne.b	.fail2
	;move.b	#1,(A1)
	moveq	#0,D0
.fail2
	rts
; EREM **************************

******************************************************************************
* Activision Pro
******************************************************************************

p_activisionpro
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_activisionpro
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus
	dc.b	"Activision Pro      [EP]",0
	        
.path dc.b "activision pro",0
 even

.init
	lea	.path(pc),a0 
	move.l	#1<<16|8,d0
	bsr.w	deliLoadAndInit
	rts 

.id

	move.l	a4,a0 
	move.l	d7,d0

	* check smaller area, otherwise can be slooow
	cmp.l	#1024*4,d0
	blo.b	.ok
	move.l	#1024*4,d0
.ok

.lbC0004CA	MOVE.L	A0,A4
	MOVE.L	D0,D4
	MOVE.L	D0,D2
	MOVE.L	A0,A2
	LEA	.lbB000624(PC),A1
	MOVEq	#3,D1
	BSR.W	.lbC0005EE
	BNE.S	.lbC000518
	;MOVE.L	A0,lbL0000BA
	LEA	.lbB00062C(PC),A1
	MOVEq	#12,D1
	BSR.W	.lbC0005EE
	BNE.W	.lbC0005EC
	;MOVE.L	A0,lbL0000BE
	MOVEQ	#0,D1
	CMP.W	#$4E75,$28(A2)
	BNE.S	.lbC00050C
	MOVEQ	#2,D1
.lbC00050C	
	;MOVE.L	D1,lbL0000C2
	MOVEQ	#0,D0
	BRA.W	.lbC0005EC

.lbC000518	MOVE.L	A4,A0
	MOVE.L	D4,D2
	LEA	.lbB000646(PC),A1
	MOVEq	#9,D1
	BSR.W	.lbC0005EE
	BNE.S	.lbC00055A
	;MOVE.L	A0,lbL0000BA
	LEA	.lbB00065A(PC),A1
	MOVEq	#10,D1
	BSR.B	.lbC0005EE
	BNE.B	.lbC0005EC
	;MOVE.L	A0,lbL0000BE
	;MOVE.L	#2,lbL0000C2
	MOVEQ	#0,D0
	BRA.B	.lbC0005EC

.lbC00055A	MOVE.L	A4,A0
	MOVE.L	D4,D2
	CMP.W	#$6000,(A0)
	BNE.B	.lbC0005EA
	CMP.W	#$6000,4(A0)
	BNE.B	.lbC0005EA
	CMP.W	#$6000,8(A0)
	BNE.S	.lbC0005EA
	CMP.W	#$6000,12(A0)
	BNE.S	.lbC0005EA
	CMP.W	#$6000,$10(A0)
	BNE.S	.lbC0005EA
	CMP.W	#$6000,$14(A0)
	BNE.S	.lbC0005EA
	CMP.W	#$6000,$18(A0)
	BNE.B	.lbC0005EA
	CMP.W	#$6000,$1C(A0)
	BNE.B	.lbC0005EA
	CMP.W	#$6000,$20(A0)
	BNE.B	.lbC0005EA
	CMP.W	#$6000,$20(A0)
	BNE.B	.lbC0005EA
	MOVE.W	$16(A0),D0
	LEA	$16(A0,D0.W),A1
	CMP.L	#$2F0841FA,(A1)
	BNE.S	.lbC0005EA
	;MOVE.L	A1,lbL0000BA
	MOVE.W	$1A(A0),D0
	LEA	$1A(A0,D0.W),A1
	;MOVE.L	A1,lbL0000BE
	;MOVE.L	#2,lbL0000C2
	MOVEQ	#0,D0
	BRA.S	.lbC0005EC

.lbC0005EA	MOVEQ	#-1,D0
.lbC0005EC	RTS

.lbC0005EE	MOVE.L	D1,D3
	BSR.B	.lbC000604
	BEQ.S	.lbC000600
	ADDQ.L	#2,A0
	SUBQ.L	#2,D2
	BGT.S	.lbC0005EE
	MOVEQ	#-1,D0
	RTS

.lbC000600	MOVEQ	#0,D0
	RTS

.lbC000604
	MOVEM.L	D1/D3/A0/A1,-(SP)
	MOVEQ	#-1,D0
.lbC00060A	MOVE.W	(A1)+,D1
	CMP.W	#$FFFF,D1
	BEQ.S	.lbC000616
	CMP.W	(A0),D1
	BNE.S	.lbC00061E
.lbC000616	ADDQ.L	#2,A0
	DBRA	D3,.lbC00060A
	MOVEQ	#0,D0
.lbC00061E	MOVEM.L	(SP)+,D1/D3/A0/A1
	RTS

.lbB000624	dc.b	$48
	dc.b	$E7
	dc.b	$FC
	dc.b	$FE
	dc.b	$E9
	dc.b	$41
	dc.b	$70
	dc.b	0
.lbB00062C	dc.b	$48
	dc.b	$E7
	dc.b	$FC
	dc.b	$FE
	dc.b	$41
.lbB000631	dc.b	$FA
	dc.b	$FF
	dc.b	$FF
	dc.b	$43
.lbB000635	dc.b	$FA
	dc.b	$FF
	dc.b	$FF
	dc.b	$47
.lbB000639	dc.b	$FA
	dc.b	$FF
	dc.b	$FF
	dc.b	$4B
.lbB00063D	dc.b	$FA
	dc.b	$FF
	dc.b	$FF
	dc.b	$2C
	dc.b	$7C
	dc.b	0
	dc.b	$DF
	dc.b	$F0
	dc.b	$A0
.lbB000646	dc.b	$48
	dc.b	$E7
	dc.b	0
	dc.b	$C0
	dc.b	$41
.lbB00064B	dc.b	$FA
	dc.b	$FF
	dc.b	$FF
	dc.b	$43
.lbB00064F	dc.b	$FA
	dc.b	$FF
	dc.b	$FF
	dc.b	2
	dc.b	$80
	dc.b	0
	dc.b	0
	dc.b	0
	dc.b	$FF
	dc.b	$E5
	dc.b	$40
.lbB00065A
	dc.b	$48
	dc.b	$E7
	dc.b	$FC
	dc.b	$FE
	dc.b	$41

* This bit is needed to recognize "d-generation-sfx.avp":

.lbB00065F
	dc.b	$FA
	dc.b	$FF
	dc.b	$FF
	dc.b	$43
.lbB000663	dc.b	$FA
	dc.b	$FF
	dc.b	$FF
	dc.b	$4B

.lbB000667	dc.b	$FA
	dc.b	$FF
	dc.b	$FF
	dc.b	$2C
	dc.b	$7C
	dc.b	0
	dc.b	$DF
	dc.b	$F0
	dc.b	$A0
	dc.b	$48
	dc.b	$E7
	dc.b	$C0
	dc.b	4
	dc.b	$2A
	dc.b	$7A
	dc.b	$FA
	dc.b	$66
	dc.b	$70
	dc.b	1
	dc.b	$72
	dc.b	0
	dc.b	$4E
	dc.b	$AD
	dc.b	$FE
	dc.b	$EC
	dc.b	$4C
	dc.b	$DF
	dc.b	$20
	dc.b	3
	dc.b	$4E
	dc.b	$75
 even

******************************************************************************
* MaxTrax
******************************************************************************

p_maxtrax
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_maxtrax
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"MaxTrax             [EP]",0
	        
.path dc.b "maxtrax",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|2,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	movea.l	a4,A0
	moveq	#-1,D0

	move.l	d7,D1
	lea	(A0,D1.L),A1
	cmp.l	#'MXTX',(A0)+
	bne.b	.Fault
	tst.w	(A0)+
	beq.b	.Fault
	bmi.b	.Fault
	tst.w	(A0)+
	bpl.b	.NoMicro				; no microtonal?
	lea	256(A0),A0
.NoMicro
	move.w	(A0)+,D1			; songs number
	beq.b	.Fault
	cmp.w	#256,D1
	bhi.b	.Fault
	subq.w	#1,D1
.SongCheck
	move.l	(A0)+,D2
	beq.b	.Fault
	bmi.b	.Fault
	mulu.w	#6,D2
	add.l	D2,A0
	cmp.l	A0,A1
	ble.b	.Fault
	dbf	D1,.SongCheck
	cmp.w	#64,(A0)
	bhi.b	.Fault
	;lea	.TwoFiles(PC),A1
	;move.w	(A0),(A1)
	moveq	#0,D0
.Fault
	rts


******************************************************************************
* Wally Beben
******************************************************************************

p_wallybeben
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_wallybeben
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"Wally Beben         [EP]",0
	        
.path dc.b "wally beben",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|1,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l	a4,a0
	moveq	#-1,D0

	cmp.w	#$6000,(A0)+
	bne.b	.Fault
	move.w	(A0)+,D1
	beq.b	.Fault
	bmi.b	.Fault
	btst	#0,D1
	bne.b	.Fault
	lea	-2(A0,D1.W),A1
	cmp.b	#$61,(A1)+
	bne.b	.Fault
	tst.b	(A1)+
	bne.b	.Short
	addq.l	#2,A1
.Short
	cmp.w	#$4239,(A1)
	bne.b	.Fault
	addq.l	#6,A1
	cmp.w	#$4239,(A1)
	bne.b	.Fault
	addq.l	#6,A1
	cmp.w	#$4E75,(A1)
	bne.b	.Fault
	cmp.l	#$48E7FFFE,(A0)+
	bne.b	.Fault
	cmp.w	#$6100,(A0)+
	bne.b	.Fault
	add.w	(A0),A0
	cmp.l	#$4CF900FF,(A0)+
	beq.b	.Found
	cmp.w	#$1039,(A0)
	bne.b	.Fault
.Found
	moveq	#0,D0
.Fault
	rts

******************************************************************************
* Synth Pack by Karsten Obarski
******************************************************************************

p_synthpack
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_synthpack
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"Synth Pack          [EP]",0
	        
.path dc.b "synth pack",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|2,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l	a4,a0
	MOVEQ	#-1,D0
	CMP.L	#$4F424953,(A0)+
	BNE.S	.lbC0004FC
	CMP.L	#$594E5448,(A0)+
	BNE.S	.lbC0004FC
	CMP.L	#$5041434B,(A0)+
	BNE.S	.lbC0004FC
	CMP.W	#$100,$500(A0)
	BEQ.S	.lbC0004F8
	TST.L	$500(A0)
	BNE.S	.lbC0004FC
	;BRA.S	.lbC0004FA
.lbC0004F8	
.lbC0004FA	MOVEQ	#0,D0
.lbC0004FC	RTS


******************************************************************************
* Rob Hubbard
******************************************************************************

p_robhubbard
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_robhubbard
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"Rob Hubbard         [EP]",0
.path dc.b "rob hubbard",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|6,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l	a4,a0
	moveq	#-1,D0
	move.w	#$6000,D1
	cmp.w	(A0),D1
	bne.s	.Return
	cmp.w	4(A0),D1
	bne.s	.Return
	cmp.w	8(A0),D1
	bne.s	.Return
	cmp.w	12(A0),D1
	bne.s	.Return
	cmp.w	16(A0),D1
	bne.s	.Return
	cmp.w	#$41FA,20(A0)
	bne.s	.Return
	cmp.l	#$4E7541FA,28(A0)
	bne.s	.Return
	moveq	#0,D0
.Return
	rts			



******************************************************************************
* Jeroen Tel
******************************************************************************

p_jeroentel
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_jeroentel
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"Jeroen Tel          [EP]",0
.path dc.b "jeroen tel",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|1,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l	a4,a0 
	moveq	#-1,D0
	cmp.l	#1700,d7
	ble.b	.Fault

	lea	40(A0),A1
.Check
	cmp.l	#$02390001,(A0)
	beq.b	.More
	addq.l	#2,A0
	cmp.l	A0,A1
	bne.b	.Check
	rts
.More
	addq.l	#8,A0
	cmp.b	#$66,(A0)+
	bne.b	.Fault
	move.b	(A0)+,D1
	bmi.b	.Fault
	beq.b	.Fault
	cmp.w	#$4E75,(A0)
	bne.b	.Fault
	ext.w	D1
	add.w	D1,A0
	cmp.w	#$4A39,(A0)
	bne.b	.NoOne
	moveq	#3,D1
.NextOne
	cmp.w	#$4A39,(A0)
	bne.b	.Fault
	lea	18(A0),A0
	dbf	D1,.NextOne
.NoOne
	cmp.l	#$78001839,(A0)
	bne.b	.Fault
	moveq	#0,D0
.Fault
	rts



******************************************************************************
* Sonix Music Driver
* Prefixes: SMUS, TINY, SNX
******************************************************************************

p_sonix
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_sonix
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"Sonix Music Driver  [EP]",0
.path dc.b "sonix music driver",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|1,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l	a4,a0
	moveq	#-1,D0

	move.l	d7,d4
	move.l	A0,A1
	cmp.l	#'FORM',(A0)
	beq.w	.SmusCheck
	move.w	(A0),D1
	and.w	#$00F0,D1
	bne.b	.TinyCheck
	moveq	#20,D3
	moveq	#3,D1
.NextPos
	move.l	(A0)+,D2
	beq.b	.fault
	bmi.b	.fault
	btst	#0,D2
	bne.b	.fault
	add.l	D2,D3
	dbf	D1,.NextPos
	cmp.l	D4,D3
	bge.b	.fault
	addq.l	#4,A0
	moveq	#3,D1
.SecPass
	tst.b	(A0)
	bpl.b	.fault
	cmp.w	#-1,(A0)
	beq.b	.OK1
	cmp.b	#$84,(A0)
	bhi.b	.fault
.OK1
	add.l	(A1)+,A0
	dbf	D1,.SecPass
	tst.b	(A0)
	beq.b	.fault
.found
	moveq	#0,D0
.fault
	rts


.TinyCheck
	cmp.l	#332,D4
	ble.b	.fault
	lea	48(A0),A1
	cmp.l	#$140,(A1)+
	bne.b	.fault
	moveq	#2,D1
.NextPos2
	move.l	(A1)+,D2
	beq.b	.fault
	bmi.b	.fault
	btst	#0,D2
	bne.b	.fault
	cmp.l	D2,D4
	ble.b	.fault
	lea	(A0,D2.L),A2
	cmp.w	#-1,(A2)
	beq.b	.OK2
	tst.l	(A2)+
	bne.b	.fault
	tst.w	(A2)+
	bne.b	.fault
	tst.b	(A2)
	bpl.b	.fault
	cmp.b	#$82,(A2)
	bhi.b	.fault
.OK2
	dbf	D1,.NextPos2
	bra.b	.found

.SmusCheck
	cmp.l	#'SMUS',8(A0)
	bne.b	.fault
	cmp.l	#'SHDR',12(A0)
	tst.b	23(A0)
	beq.b	.fault
	lea	24(A0),A1
	cmp.l	#'NAME',(A1)+
	bne.b	.fault
	move.l	(A1)+,D1
	bmi.b	.fault
	addq.l	#1,D1
	bclr	#0,D1
	add.l	D1,A1
	cmp.l	#'SNX1',(A1)+
	bne.w	.fault
	move.l	(A1)+,D1
	bmi.w	.fault
	addq.l	#1,D1
	bclr	#0,D1
	add.l	D1,A1
.MoreIns
	cmp.l	#'INS1',(A1)+
	bne.w	.fault
	move.l	(A1)+,D1
	bmi.w	.fault
	addq.l	#1,D1
	bclr	#0,D1
	cmp.b	#63,(A1)			; real sample number
	bhi.w	.fault
	tst.b	1(A1)				; MIDI check
	bne.w	.fault
	add.l	D1,A1
	cmp.l	#'TRAK',(A1)
	bne.b	.MoreIns
	bra.w	.found



******************************************************************************
* Quartet ST
******************************************************************************

p_quartetst
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id_quartet_st(pc)
	jmp	deliAuthor(pc)
	dc  pt_quartetst
.flags	dc pf_stop!pf_cont!pf_volume!pf_ciakelaus!pf_scope!pf_quadscopeUps
	dc.b	"Quartet ST          [EP]",0
.path dc.b "quartet st",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|3,d0
	bsr.w	deliLoadAndInit
	rts 

* Quartet ST
.id_quartet_st
	move.l	a4,a0
	move.w	(A0),D1
	beq.b	.Fault
	cmp.w	#$10,D1
	bhi.b	.Fault
	cmp.b	#4,7(A0)
	bne.b	.Fault
	cmp.b	#4,6(A0)
	bhi.b	.Fault
	tst.l	8(A0)
	bne.b	.Fault
	cmp.w	#'WT',12(A0)
	beq.b	.Skippy
.NoSpec
	tst.l	12(A0)
	bne.b	.Fault
.Skippy
	cmp.l	#$4C,24(A0)
	bhi.b	.Fault
	move.l	24(A0),D1
	and.w	#3,D1
	bne.b	.Fault
	cmp.w	#$0056,16(A0)
	beq.b	.Oki
.Fault
	moveq	#-1,D0
	rts
.Oki
	moveq	#0,D0
	rts




******************************************************************************
* Core Design
* NOT USED
******************************************************************************
 
 REM **********************************

p_coredesign
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id_core_design(pc)
	jmp	deliAuthor(pc)
	dc  pt_coredesign
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_ciakelaus
	dc.b	"Core Design         [EP]",0
.path dc.b "core design",0
 even

.init
	lea	.path(pc),a0 
	move.l	#10<<16|10,d0
	bsr.w	deliLoadAndInit
	rts 

* Core Design
.id_core_design
	move.l a4,a0
	cmp.l	#$000003F3,(A0)
	bne.b	.fail
	tst.b	20(A0)				; loading into chip check
	beq.b	.fail
	lea	32(A0),A0
	cmp.l	#$70FF4E75,(A0)+
	bne.b	.fail
	cmp.l	#'S.PH',(A0)+
	bne.b	.fail
	cmp.l	#'IPPS',(A0)+
	bne.b	.fail
	tst.l	(A0)+				; Interrupt pointer check
	beq.b	.fail
	tst.l	(A0)+				; Audio Interrupt pointer check
	beq.b	.fail
	tst.l	(A0)+				; InitSong pointer check
	beq.b	.fail
	tst.l	(A0)+				; EndSong pointer check
	beq.b	.fail
	tst.l	(A0)				; Subsongs check
	beq.b	.fail

	moveq	#0,D0
	rts
.fail
	moveq	#-1,D0
	rts

* Sierra AGI
* DTP_UserConfig

;Check2
;	movea.l	dtg_ChkData(A5),A0
;	moveq	#-1,D0
;
;	cmp.w	#$800,(A0)
;	bne.b	Fault
;	move.l	dtg_ChkSize(A5),D2
;	move.l	A0,A1
;	moveq	#0,D1
;	moveq	#2,D3
;NextInfo
;	addq.l	#2,A1
;	move.b	1(A1),D1
;	lsl.w	#8,D1
;	move.b	(A1),D1
;	cmp.l	D1,D2
;	ble.b	Fault
;	tst.w	D1
;	beq.b	Fault
;	lea	(A0,D1.L),A2
;	cmp.b	#-1,-1(A2)
;	bne.b	Fault
;	cmp.b	#-1,-2(A2)
;	bne.b	Fault
;	dbf	D3,NextInfo
;
;	moveq	#0,D0
;Fault
;	rts

 EREM **********************************


******************************************************************************
* Music Maker V8
******************************************************************************

p_musicmaker8
	jmp	.init(pc)
	jmp	deliPlay(pc)
	jmp	deliInterrupt(pc) ; Vol + voices
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp	.id_musicmaker8(pc)
	jmp	deliAuthor(pc)
	dc 	 pt_musicmaker8
.flags	dc 	pf_stop!pf_cont!pf_volume!pf_end
	dc.b	"MusicMaker V8 8-ch  [EP]",0
.path 	dc.b "musicmaker8",0
 even

.init
	lea	.path(pc),a0 
	move.l	#8<<16|5,d0
	bsr.w	deliLoadAndInit
	rts 


.id_musicmaker8
	bsr.b	id_musicmaker8_
	bne.b	.no
	bsr.w	moveModuleToPublicMem
	moveq	#0,d0
.no
	rts
	
* Check
id_musicmaker8_
.lbC00046E	MOVEm.L	d6/D7,-(SP)
	;MOVE.L	$24(A5),A0		* dtg_ChkData
	move.l	a4,a0
	move.l	a4,d6			* end bound
	add.l	d7,d6
	MOVEQ	#0,D7
	CMP.L	#$464F524D,(A0)		; FORM
	BNE.S	.lbC00049C
	CMP.L	#$4D4D5638,8(A0)	; MMV8
	BNE.S	.lbC00049C
	MOVE.L	#$53444154,D0		; SDAT
	BSR.b	MM_SearchLongWord
	TST.L	D0
	BMI.b	.NotRecognized
	ADDQ.L	#4,A0
	MOVEQ	#-1,D7
.lbC00049C	CMP.W	#$5345,(A0)	; SE
	BNE.b	.NotRecognized
	bsr.b	MM4_8_ExtraCheck
	BNE.b	.NotRecognized
	TST.L	D7
	;BEQ.S	OldFormatCheck
	beq.b	.NotRecognized
	;MOVE.L	$24(A5),A0			* dtg_ChkData
	move.l	a4,a0
	MOVE.L	#$494E5354,D0		; INST
	BSR.b	MM_SearchLongWord
	TST.L	D0
	BPL.b	.CheckEnd
	;MOVE.L	$24(A5),A0
	move.l	a4,a0
	MOVE.L	#$50494E53,D0		; PINS
	BSR.b	MM_SearchLongWord
	TST.L	D0
	BPL.b	.CheckEnd
	BRA.b	.NotRecognized

.CheckEnd	MOVEm.L	(SP)+,d6/D7
	MOVEQ	#0,D0
	RTS

.NotRecognized	MOVEm.L	(SP)+,d6/D7
	MOVEQ	#-1,D0
	RTS

MM_SearchLongWord	MOVEM.L	D1/A2,-(SP)
	ADDQ.L	#4,A0
	MOVE.L	(A0)+,A2
	ADD.L	A0,A2
	ADDQ.L	#4,A0
.lbC000308	
	cmp.l	d6,a0
	bhs.b	.nope
	CMP.L	(A0)+,D0
	BEQ.S	.lbC000318
	MOVE.L	(A0)+,D1
	ADD.L	D1,A0
	CMP.L	A2,A0
	BLO.S	.lbC000308
.nope
	MOVEQ	#-1,D0
	BRA.S	.lbC00031A

.lbC000318	MOVE.L	(A0)+,D0
.lbC00031A	MOVEM.L	(SP)+,D1/A2
	RTS

MM4_8_ExtraCheck
.lbC000CB4	CMP.W	#$5345,(A0)	; ST
	BEQ.S	.lbC000CC0
	CMP.B	#$FF,(A0)
	BRA.S	.lbC000CC6

.lbC000CC0	CMP.B	#$FF,$16(A0)
.lbC000CC6	SNE	D0
	EXT.W	D0
	EXT.L	D0
	RTS
	

******************************************************************************
* Music Maker V4
******************************************************************************

p_musicmaker4
	jmp	.init(pc)
	jmp	deliPlay(pc)
	jmp	deliInterrupt(pc) ; Vol + voices
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp	 id_musicmaker4(pc)
	jmp	deliAuthor(pc)
	dc  pt_musicmaker4
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_ciakelaus
	dc.b	"MusicMaker V8 4-ch  [EP]",0
.path dc.b "musicmaker4",0
 even

.init
	lea	.path(pc),a0 
	move.l	#8<<16|5,d0
	bsr.w	deliLoadAndInit
	rts 

;EP_Check5 (FPTR) - same as DTP_Check2 but module is loaded into public

id_musicmaker4
	bsr.b	.Check2
	beq.b	.ok
	bsr.b	.Check5
.ok	tst.l	d0
	rts

.Check2	MOVEQ	#1,D0
	BRA.S	.lbC000466

.Check5	MOVEQ	#0,D0
.lbC000466	MOVEM.L	d5/D6/D7,-(SP)
	MOVE.L	D0,D5
	;MOVE.L	$24(A5),A0		* dtg_ChkData
	move.l	a4,a0
	move.l	a4,d6			* end bound
	add.l	d7,d6
	MOVEQ	#0,D7
	CMP.L	#$464F524D,(A0)		; FORM
	BNE.S	.lbC000498
	CMP.L	#$4D4D5638,8(A0)	; MMV8
	BNE.S	.lbC000498
	MOVE.L	#$53444154,D0
	BSR.W	MM_SearchLongWord
	TST.L	D0
	BMI.b	.lbC0005BA
	ADDQ.L	#4,A0
	MOVEQ	#-1,D7
.lbC000498	CMP.W	#$5345,(A0)	; SE
	BNE.B	.lbC0005BA
	bSR.w	MM4_8_ExtraCheck
	BEQ.B	.lbC0005BA
	MOVE.B	$17(A0),D0
	CMP.B	#$10,D0
	BLO.b	.lbC0005BA
	CMP.B	#$40,D0
	BHI.b .lbC0005BA
	TST.L	D7
	;BEQ.S	lbC0004FC
	beq.b	.NotRecognized
;	MOVE.L	$24(A5),A0
	move.l	a4,a0
	MOVE.L	#$494E5354,D0		; INST
	BSR.w MM_SearchLongWord
	TST.L	D0
	BMI.S	.lbC0004DE
	TST.L	D5
	BNE.b	.lbC0005B2
	BRA.b	.lbC0005BA

.lbC0004DE	
;	MOVE.L	$24(A5),A0
	move.l	a4,a0
	MOVE.L	#$50494E53,D0		; PINS
	BSR.w	MM_SearchLongWord
	TST.L	D0
	BMI.b	.lbC0005BA
	TST.L	D5
	BNE.b	.lbC0005BA
	BRA.w	.lbC0005B2

.Ok
.lbC0005B2	MOVEM.L	(SP)+,d5/D6/D7
	MOVEQ	#0,D0
	RTS

.NotRecognized
.lbC0005BA	MOVEM.L	(SP)+,d5/D6/D7
	MOVEQ	#-1,D0
	RTS

******************************************************************************
* Digital Mugician 2
******************************************************************************

p_digitalmugician2
	jmp	.init(pc)
	jmp	deliPlay(pc)
	jmp	deliInterrupt(pc) ; for position updates
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp id_digitalmugician2(pc)
	jmp	deliAuthor(pc)
	dc  pt_digitalmugician2
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_kelauseteen!pf_kelaustaakse!pf_scope
	dc.b	"Digital Mugician II [EP]",0
.path dc.b "mugician ii",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|8,d0
	bsr.w	deliLoadAndInit
	rts 

* digital mugician ii ("mugician ii")
* DTP_UserConfig
id_digitalmugician2
;	bsr.b 	.do
;	tst.l	d0
;	bne.b	.no
;	bsr	moveModuleToPublicMem
;	moveq	#0,d0
;.no 
;	rts
;.do	
	move.l	a4,a0
	moveq	#-1,D0
	lea	.text(PC),A1
	moveq	#$19,D6
.test	cmpm.b	(A0)+,(A1)+
	bne.b	.Fault
	dbra	D6,.test	
	moveq	#0,D0
.Fault
	rts
.text
	dc.b	' MUGICIAN2/SOFTEYES 1990'
	dc.w	1
 even  

******************************************************************************
* StoneTracker
******************************************************************************

p_stonetracker
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP ;jmp	deliInterrupt(pc) ; for position updates
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp id_stonetracker(pc)
	jmp	deliAuthor(pc)
	dc  pt_stonetracker
.flags	dc pf_stop!pf_cont!pf_volume!pf_song!pf_kelaus!pf_end
	dc.b	"StoneTracker        [EP]",0
.path dc.b "eaglestone",0
 even
 
.init
	lea	.path(pc),a0 
	moveq	#0<<16|1,d0
	bsr.w	deliLoadAndInit
	bmi.b	.not
.MHD_Name = 4
	move.l	moduleaddress(a5),a0
	lea	.MHD_Name(a0),a0
 	lea	modulename(a5),a1
 	moveq	#31-1,d0
.name	move.b	(a0)+,(a1)+
 	dbeq	d0,.name

	moveq	#0,d0
.not
	rts 


id_stonetracker
	push	a4
	bsr.b	.id_stonetracker_
	pop	a4
	tst.l 	d0 
	bne.b .not 
	bsr.w	moveModuleToPublicMem
	moveq	#0,d0
.not
	rts
	
.id_stonetracker_
	move.l	a4,a0
	MOVEQ	#-1,D0
	;MOVE.L	$24(A5),A0
	;MOVE.L	$28(A5),D7
	MOVE.L	(A0)+,D1
	MOVE.W	D1,D2
	CMP.L	#$53504D02,D1
	BNE.b	.lbC00327A
	LEA	(A0),A3
	MOVEQ	#$1F,D6
	BSR.b	.lbC00327E
	BNE.b	.lbC00327A
	LEA	$20(A0),A0
	MOVEM.W	(A0)+,D3-D6
	LEA	(A0),A1
	MOVEM.L	D3/D4,-(SP)
	ADD.L	D3,D3
	ADD.L	D3,D3
	ADD.L	D4,D4
	ADD.L	D4,D4
	LEA	0(A1,D3.L),A2
	LEA	0(A2,D4.L),A3
	MOVEM.L	(SP)+,D3/D4
	MOVE.W	D3,D2
	SUBQ.W	#1,D2
	BMI.b	.lbC00327A
	LEA	(A1),A4
.lbC003250	CMP.L	(A4)+,D7
	BLS.S	.lbC00327A
	DBRA	D2,.lbC003250
	MOVE.W	D4,D2
	SUBQ.W	#1,D2
	BMI.S	.lbC00327A
	LEA	(A2),A4
.lbC003260	CMP.L	(A4)+,D7
	BLS.S	.lbC00327A
	DBRA	D2,.lbC003260
	MOVE.W	D5,D2
	SUBQ.W	#1,D2
	BMI.S	.lbC003278
	LEA	(A3),A4
.lbC003270	CMP.L	(A4)+,D7
	BLS.S	.lbC00327A
	DBRA	D2,.lbC003270
.lbC003278	MOVEQ	#0,D0
.lbC00327A	TST.L	D0
	RTS

.lbC00327E	MOVE.B	(A3)+,D0
	BEQ.S	.lbC003290
	AND.B	#$7F,D0
	CMP.B	#$20,D0
	BLT.S	.lbC003294
	SUBQ.L	#1,D6
	BGT.S	.lbC00327E
.lbC003290	MOVEQ	#0,D0
	BRA.S	.lbC003296

.lbC003294	MOVEQ	#-1,D0
.lbC003296	RTS

******************************************************************************
* Soundcontrol
******************************************************************************

p_soundcontrol
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_soundcontrol
.flags	dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus2!pf_kelaustaakse!pf_scope!pf_quadscopeUps
	dc.b	"SoundControl        [EP]",0
	        
.path dc.b "soundcontrol",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|3,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l	a4,a0
	MOVEQ	#-1,D0
	CMP.W	#3,$20(A0)
	BEQ.S	.lbC000466
	CMP.W	#2,$20(A0)
	BNE.S	.lbC00048E
	TST.L	$1C(A0)
	BNE.S	.lbC00048E
.lbC000466	TST.W	$10(A0)
	BNE.S	.lbC00048E
	MOVE.W	$12(A0),D1
	BMI.S	.lbC00048E
	BTST	#0,D1
	BNE.S	.lbC00048E
	ADD.W	D1,A0
	CMP.W	#$FFFF,$3E(A0)
	BNE.S	.lbC00048E
	CMP.L	#$400,$40(A0)
	BNE.S	.lbC00048E
	MOVEQ	#0,D0
.lbC00048E
	rts


******************************************************************************
* The Musical Enlightenment
******************************************************************************

p_themusicalenlightenment
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp .id(pc)
	jmp	deliAuthor(pc)
	dc  pt_themusicalenlightenment
.flags	dc pf_scope!pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus2!pf_kelaustaakse!pf_quadscopeUps
	dc.b	"The Musical Enlighte[EP]",0
	        
.path dc.b "tme",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|3,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	movea.l	a4,A0
	lea	(a4,d7.l),a3	* upper bound

	moveq	#-1,D0

	tst.b	(A0)
	bne.b	.Fault
	move.l	d7,D1
	cmp.l	#7000,D1
	blt.b	.Fault
	move.l	(A0),D2
	beq.b	.Fault

	cmp.l	#$0000050F,$3C(A0)
	bne.s	.CheckAnother
	cmp.l	#$0000050F,$40(A0)
	bne.s	.CheckAnother
	bra.b	.TME_OK

.CheckAnother
	* Range check

	pea	$1284(a0)
	cmp.l	(sp)+,a3
	bhs.b	.Fault

	cmp.l	#$00040B11,$1284(A0)
	bne.s	.CheckSize

	pea	$1188(a0)
	cmp.l	(sp)+,a3
	bhs.b	.Fault

	cmp.l	#$181E2329,$1188(A0)
	bne.s	.CheckSize

	pea	$128c(a0)
	cmp.l	(sp)+,a3
	bhs.b	.Fault

	cmp.l	#$2F363C41,$128C(A0)
	bne.s	.CheckSize
.TME_OK
	moveq	#0,D0
.Fault
	rts

.CheckSize
	bsr.b	.GetSize
	cmp.l	D2,A2
	beq.b	.TME_OK
	bra.b	.Fault
.GetSize
	move.l	A0,A1
	move.l	A0,A2

	pea	$1aaa(a2)
	cmp.l	(sp)+,a3
	bhs.b	.X
	
	pea	$1a84(a1)
	cmp.l	(sp)+,a3
	bhs.b	.X

	lea	$1AAA(A2),A2
	move.w	$1A84(A1),D3
	mulu.w	#12,D3
	add.l	D3,A2

	pea	$1a86(a1)
	cmp.l	(sp)+,a3
	bhs.b	.X	

	move.w	$1A86(A1),D3
	mulu.w	#6,D3
	add.l	D3,A2
	moveq	#0,D1
.NextInuc
	addq.l	#4,A2
	tst.b	-4(A2)
	bne.b	.NextInuc
	addq.l	#4,D1
	cmp.l	#$400,D1
	blt.b	.NextInuc
	moveq	#0,D1

	lea	$44(A1),A1
.NextSamp
	pea	$18(A1,D1.L)
	cmp.l	(sp)+,a3
	bhs.b	.X

	tst.b	$18(A1,D1.L)
	beq.b	.NoSample
	add.l	4(A1,D1.L),A2
.NoSample	add.l	#$80,D1
	cmp.l	#$1000,D1
	blt.b	.NextSamp
	sub.l	A0,A2
.X	rts



******************************************************************************
* Tim Follin
******************************************************************************

p_timfollin2
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp 	.id(pc)
	jmp	deliAuthor(pc)
	dc  	pt_timfollin2
 dc pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus2!pf_scope!pf_quadscopePoke
	dc.b	"Tim Follin          [EP]",0
	        
.path dc.b "tim follin ii",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|0,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	MOVEQ	#-1,D0
	MOVE.L	a4,A0
	MOVE.W	#$4EF9,D1
	CMP.W	(A0),D1
	BNE.S	.lbC00057C
	CMP.W	6(A0),D1
	BNE.S	.lbC00057A
	CMP.W	12(A0),D1
	BNE.S	.lbC00057A
	CMP.W	$12(A0),D1
	BNE.S	.lbC00057A
	CMP.W	$18(A0),D1
	BNE.S	.lbC00057A
	CMP.W	$1E(A0),D1
	BNE.S	.lbC00057A
	MOVE.L	$2C(A0),D1
	SUB.L	2(A0),D1
	CMP.W	#$A0,D1
	MOVEQ	#0,D0
.lbC00057A	
	RTS

.lbC00057C
	CMP.W	#$601A,(A0)
	BNE.S	.lbC000586
	LEA	$1C(A0),A0
.lbC000586	
	CMP.W	#$1010,(A0)
	BEQ.S	.lbC000592
	CMP.W	#$1012,(A0)
	BNE.S	.lbC00057A
.lbC000592
	ADDQ.L	#2,A0
	MOVE.L	4(A0),D1
	CMP.L	8(A0),D1
	BNE.S	.lbC00057A
	CMP.L	12(A0),D1
	BNE.S	.lbC00057A
	CMP.L	$10(A0),D1
	BNE.S	.lbC00057A
	MOVEQ	#0,D0
	RTS

******************************************************************************
* Jason Page
******************************************************************************

p_jasonpage
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp 	.id(pc)
	jmp	deliAuthor(pc)
	dc  	pt_jasonpage
	dc 	pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus2!pf_scope!pf_quadscopeUps
	dc.b	"Jason Page          [EP]",0
	        
.path dc.b "jason page",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|0,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l	a4,a0

	MOVEQ	#-1,D0
	CMP.W	#2,(A0)
	BNE.S	.lbC000382
	BTST	#0,3(A0)
	BNE.S	.lbC000382
	MOVE.W	4(A0),D1
	BTST	#0,D1
	BNE.S	.lbC000382
	TST.W	0(A0,D1.W)
	BNE.S	.lbC000382
	MOVE.W	$30(A0),D0
	LEA	2(A0),A1
	MOVEQ	#$16,D1
.lbC00034E	TST.W	(A1)
	BEQ.S	.lbC000382
	BTST	#0,1(A1)
	BNE.S	.lbC000382
	CMP.W	(A1)+,D0
	BLE.S	.lbC000382
	DBRA	D1,.lbC00034E
	MOVEQ	#0,D0
	MOVE.W	$2E(A0),D0
	ADD.L	D0,A0
	MOVE.W	(A0),D0
	AND.W	#$F00,D0
	CMP.W	#$F00,D0
	BNE.S	.lbC00037C
	BRA.W	.lbC000380

.lbC00037C
.lbC000380	BRA.S	.lbC0003AE

.lbC000382	TST.W	(A0)
	BNE.S	.lbC0003B0
	TST.L	$80(A0)
	BNE.S	.lbC0003B0
	CMP.L	#$CBE,$84(A0)
	BNE.S	.lbC0003B0
	CMP.L	#$308BE,$CB6(A0)
	BNE.S	.lbC0003B0
	CMP.L	#$309BE,$CBA(A0)
	BNE.S	.lbC0003B0
.lbC0003AE	MOVEQ	#0,D0
.lbC0003B0	RTS
	RTS


******************************************************************************
* Steve Turner
******************************************************************************

p_steveturner
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp 	.id(pc)
	jmp	deliAuthor(pc)
	dc  	pt_steveturner
	dc 	pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus2!pf_scope!pf_quadscopeUps
	dc.b	"Steve Turner        [EP]",0
	        
.path dc.b "steve turner",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|0,d0
	bsr.w	deliLoadAndInit
	rts 

.id
	move.l	a4,a0
	MOVEQ	#-1,D0
	CMP.W	#$2B7C,(A0)
	BNE.S	.no
	CMP.W	#$2B7C,8(A0)
	BNE.S	.no
	CMP.W	#$2B7C,$10(A0)
	BNE.S	.no
	CMP.W	#$2B7C,$18(A0)
	BNE.S	.no
	CMP.L	#$303C00FF,$20(A0)
	BNE.S	.no
	CMP.L	#$32004EB9,$24(A0)
	BNE.S	.no
	CMP.W	#$4E75,$2C(A0)
	BNE.S	.no
	MOVEQ	#0,D0
.no
	rts

******************************************************************************
* SpecialFX
******************************************************************************

p_specialfx
	jmp	.init(pc)
	jmp	deliPlay(pc)
	p_NOP
	jmp	deliEnd(pc)
	jmp	deliStop(pc)
	jmp	deliCont(pc)
	jmp	deliVolume(pc)
	jmp	deliSong(pc)
	jmp	deliForward(pc)
	jmp	deliBackward(pc)
	p_NOP
	jmp 	.id(pc)
	jmp	deliAuthor(pc)
	dc  	pt_specialfx
	dc 	pf_stop!pf_cont!pf_volume!pf_end!pf_song!pf_ciakelaus2!pf_scope!pf_quadscopeUps
	dc.b	"Special FX          [EP]",0
	        
.path dc.b "special fx",0
 even

.init
	lea	.path(pc),a0 
	moveq	#0<<16|0,d0
	bsr.b	deliLoadAndInit
	rts 

.id
	move.l	a4,a0
	MOVEQ	#-1,D0
	MOVE.W	#$6000,D1
	CMP.W	(A0)+,D1
	BNE.S	.lbC0003C6
	MOVE.L	A0,A1
	MOVE.W	(A0)+,D2
	BMI.S	.lbC0003C6
	BEQ.S	.lbC0003C6
	BTST	#0,D2
	BNE.S	.lbC0003C6
	MOVEQ	#2,D4
.lbC000378	CMP.W	(A0)+,D1
	BNE.S	.lbC0003C6
	MOVE.W	(A0)+,D3
	BMI.S	.lbC0003C6
	BEQ.S	.lbC0003C6
	BTST	#0,D3
	BNE.S	.lbC0003C6
	DBRA	D4,.lbC000378
	ADD.W	D2,A1
	CMP.W	(A0),D1
	BNE.S	.lbC0003AE
	MOVEQ	#2,D4
.lbC000394	CMP.W	(A0)+,D1
	BNE.S	.lbC0003C6
	MOVE.W	(A0)+,D3
	BMI.S	.lbC0003C6
	BEQ.S	.lbC0003C6
	BTST	#0,D3
	BNE.S	.lbC0003C6
	DBRA	D4,.lbC000394
	CMP.W	(A0),D1
	BEQ.S	.lbC0003C6
	BRA.S	.lbC0003B6

.lbC0003AE	CMP.W	#$6100,(A1)
	BNE.S	.lbC0003C6
	ADDQ.L	#4,A1
.lbC0003B6	CMP.W	#$41F9,(A1)
	BNE.S	.lbC0003C6
	ADDQ.L	#6,A1
	CMP.W	#$43F9,(A1)
	BNE.S	.lbC0003C6
	MOVEQ	#0,D0
.lbC0003C6	RTS

*******************************************************************************
*** SECTION *******************************************************************
*
* EaglePlayer plugin support 
* Keywords: Delisupport, Eaglesupport
*
******************************************************************************


DELI_LIST_DATA_SLOTS = 64

 STRUCTURE DTN_NoteStruct,0
	APTR	nst_Channels		;pointer to a list of notechannels */
	ULONG	nst_Flags		;misc flags (see below) */
	ULONG	nst_MaxFrequency	;max. frequency of this player (28,867 Hz in DMA mode) */
	UWORD	nst_MaxVolume		;max. volume of this player (in most cases 64) */
	STRUCT	nst_Reserved,18		;reserved for future use (must be 0 for now) */
	LABEL	DTN_NoteStruct_SIZEOF


 STRUCTURE DTN_NoteChannel,0
	APTR	nch_NextChannel		;next channel in the list (NULL if last) */
	ULONG	nch_NotePlayer		;for use by the noteplayer (the deliplayer must ignore this) */
	WORD	nch_Reserved0		;reserved for future use (must be 0 for now) */
	UBYTE	nch_Private		;just what it says */
	UBYTE	nch_Changed		;what has changed since last call */
	WORD	nch_StereoPos		;set this field when the InitNote function is called */
	WORD	nch_Stereo		;describes "where" this channel is supposed to play */
	APTR	nch_SampleStart		;^sampledata */
	ULONG	nch_SampleLength	;size of sample */
	APTR	nch_RepeatStart		;^repeat part of sample */
	ULONG	nch_RepeatLength	;size of repeat part */
	ULONG	nch_Frequency		;frequency (or period) of sample */
	UWORD	nch_Volume		;volume of sample */
	STRUCT	nch_Reserved1,26	;reserved for future use (must be 0 for now) */
	LABEL	DTN_NoteChannel_SIZEOF


NSTB_Dummy	EQU	0	; only a dummy-NoteStruct (no NotePlayer
				; needed)
NSTF_Dummy	EQU	1<<0
NSTB_Period	EQU	1	; Amiga period supplied instead of frequency
NSTF_Period	EQU	1<<1
NSTB_ExtPeriod 	EQU	2	; Extended period (period*4) supplied instead
				; of frequency 
NSTF_ExtPeriod	EQU	1<<2
NSTB_NTSCTiming EQU	3	; Period/ExtPeriod supplied in NTSC instead of
				; PAL 
NSTF_NTSCTiming EQU	1<<3
NSTB_EvenLength EQU	4	; Samplelength supplied as WORD instead of
				; LONG 
NSTF_EvenLength EQU	1<<4
NSTB_AllRepeats EQU	5	; play Repeats even if no One-Shot part was
				; played yet 
NSTF_AllRepeats EQU	1<<5

NSTB_Reverse 	EQU	8	; little endian byte ordering 
NSTF_Reverse 	EQU	1<<8
NSTB_Signed 	EQU	9	; sample data is signed linear
				; (2's complement) 
NSTF_Signed 	EQU	1<<9
NSTB_Unsigned 	EQU	10	;       -"-      unsigned linear 
NSTF_Unsigned 	EQU	1<<10
NSTB_Ulaw 	EQU	11	;       -"-      U-law (logarithmic) 
NSTF_Ulaw 	EQU	1<<11
NSTB_Alaw 	EQU	12	;       -"-      A-law (logarithmic) 
NSTF_Alaw 	EQU	1<<12
NSTB_Float 	EQU	13	;       -"-      IEEE floats 
NSTF_Float 	EQU	1<<13

NSTB_7Bit 	EQU	16	; sample data is in 7-bit format 
NSTF_7Bit 	EQU	1<<16
NSTB_8Bit 	EQU	17	;        -"-        bytes 
NSTF_8Bit 	EQU	1<<17
NSTB_16Bit 	EQU	18	;        -"-        16-bit words 
NSTF_16Bit 	EQU	1<<18
NSTB_24Bit 	EQU	19	;        -"-        24-bit data 
NSTF_24Bit 	EQU	1<<19
NSTB_32Bit 	EQU	20	;        -"-        longwords 
NSTF_32Bit 	EQU	1<<20
NSTB_64Bit 	EQU	21	;        -"-        quadwords 
NSTF_64Bit 	EQU	1<<21

* Load player and initialize module
* in:
*   a0: eagleplayer name
*   d0: required version; major<<16|minor
* out:
*   d0: 0=all ok, negative ier_-code otherwise
deliLoadAndInit:
	jsr	setMainWindowWaitPointer
	bsr.b	loadDeliPlayer 
	tst.l 	d0
	bmi.b 	.loadErr 
	bsr.w	deliInit
.loadErr	
	jsr 	clearMainWindowWaitPointer
	tst.l	d0
	rts

* in:
*   a0: name
*   d0: required version; major<<16|minor
* out:
*   d0: loaded seglist or negative error code if fail
loadDeliPlayer:
	move.l	d0,d5
	move.l	a0,a3
	* See if can reuse the old player
	move	playertype(a5),d0
	beq.b	.noMod
	cmp	deliPlayerType(a5),d0
	beq.w	.useOld
.noMod
	bsr.w	freeDeliPlayer

	bsr.w 	findDeliPlayer
	move.l	d0,d4
	bmi.w	.err
	bsr.w	.load 
	move.l	d0,d3
	move.l	d4,d1
	lore 	Dos,UnLock

	* Remove temporary EP file
	pushpea	epPath(pc),d1
	lore	Dos,DeleteFile

	moveq	#-1,d0	* err flag
	tst.l   d3
	beq.b	.err

	* Get version
	move.l	d3,d0 
	lsl.l	#2,d0
	move.l	d0,a0 
	move.l	#DTP_PlayerVersion,d0
	bsr.w	deliGetTagFromA0
	beq.b	.noVersion 
	move.l	d0,d6

	* Version check!
	cmp.l	d5,d6
	bhs.b	.ok

	move.l	d3,d1 
	lore Dos,UnLoadSeg

	move.l	a3,d0
	move.l	d5,d1
	clr	d1
	swap	d1
	move	d5,d2
	ext.l	d2
	move.l	d6,d3
	clr	d3 
	swap 	d3 
	move	d6,d4
	ext.l	d4

	move.l	playerbase(a5),a0
	pushpea	p_name(a0),d5
	
	lea	.errMsg(pc),a0 
	jsr	desmsg
	lea	 desbuf(a5),a1
	jsr	request

	moveq	#ier_eagleplayer,d0
	rts

.ok
.noVersion
	move	moduletype(a5),deliPlayerType(a5)
	move.l	d3,d0 
	lsl.l	#2,d0
.err
	rts

.useOld 
	move.l	deliPlayer(a5),d0
	DPRINT	"Using previous delipl 0x%lx"
	rts

.errMsg
	dc.b	"Version mismatch for eagleplayer:",10
	dc.b	'"%s"',10
	dc.b	"Required version: %ld.%ld or newer, found: %ld.%ld",10
	dc.b	'Detected format: "%s"',0
 even


* in:
*   d4 = lock
* out:
*   d0 = seglist or NULL
.load
	lea	-100(sp),sp
	move.l 	d4,d1
	move.l	sp,d2
	moveq	#100,d3 
	bsr.w	getNameFromLock
	beq.b 	.err2

 if DEBUG
 	move.l	sp,d0
	DPRINT	"loadDeliPlayer %s"
 endif
 	move.l	sp,d1
	lore 	Dos,LoadSeg
.err2

	lea	100(sp),sp
	tst.l	d0
	rts

epPath		dc.b	"RAM:hippoEP",0
 even


* in:
*   a3: name
* out:
*   d0: lock or negative err
findDeliPlayer	
	* See if this can be loaded from the group
	lea	-4(sp),sp 
	move.l	sp,a0
	* initialize to zero, important
	clr.l	(a0) 
	bsr.w	allocreplayer
	move.l	(sp),a1
	lea	4(sp),sp
	tst.l	d0
	beq.w	.epFromGroup

	lea 	.searchPath1(pc),a2 
	bsr.w 	.tryLock
	bne.b	.ok 
	
* PROGDIR not available on kick13 or asm
 ifeq asm
	tst.b	uusikick(a5)
	beq.b	.skip
	lea 	.searchPath2(pc),a2 
	bsr.b 	.tryLock
	bne.b	.ok 
	lea 	progdir,a2 
	bsr.b 	.tryLock
	bne.b	.ok 
.skip
 endc 

	lea	 .searchPath3(pc),a2 
	bsr.b 	.tryLock
	beq.b	.fail	
.ok
	rts

.fail 
	move.l	playerbase(a5),a0 
	pushpea p_name(a0),d1
	move.l	a3,d0
	lea	.errMsg(pc),a0 
	jsr	desmsg
	lea	 desbuf(a5),a1
	jsr	request
	moveq	#ier_eagleplayer,d0
	rts	
.errMsg
	dc.b	"Could not load eagleplayer:",10
	dc.b	'"%s"',10
	dc.b	'Detected format: "%s"',0
	 even

.tryLock
	lea	-100(sp),sp
	move.l	sp,a1
.path	
	move.b	(a2)+,(a1)+
	bne.b	.path
	subq	#1,a1
	move.l	a3,a0
.name	
	move.b	(a0)+,(a1)+
	bne.b	.name

	move.l	sp,d1
	moveq	#ACCESS_READ,d2
 	lore 	Dos,Lock
	lea	100(sp),sp
	tst.l	d0
	rts
.searchPath1
	dc.b	"RAM:",0
.searchPath2
	dc.b	"PROGDIR:eagleplayers/",0
.searchPath3
	dc.b	"eagleplayer2:eagleplayers/",0
 even

* Copy replay data from group into a file for LoadSeg()
* in:
*   a1 = replayer data from group
.epFromGroup
	push	a1
	lea	epPath(pc),a0 
	* Mem allocation size is here.
	* To get data size this must be subtracted
	move.l	-4(a1),d0
	subq.l	#4,d0
	bsr.w	plainSaveFile
	pop 	a0 
	jsr	freemem

	tst.l	d0
	beq.w	.fail

	pushpea	epPath(pc),d1
	moveq	#ACCESS_READ,d2
 	lore 	Dos,Lock
	tst.l	d0 
	beq.w	.fail
	rts

freeDeliPlayer:
	pushm	all
	tst.l	deliPlayer(a5)
	beq.b	.x

	* DeliCustom is UnloadSegged elsewhere
	cmp	#pt_delicustom,deliPlayerType(a5)
	beq.b 	.skip
	move.l	deliPlayer(a5),d1
	lsr.l	#2,d1
	lore	Dos,UnLoadSeg
	DPRINT	"freeDeliPlayer"
.skip
	clr.l	deliPlayer(a5)
	clr	deliPlayerType(a5)
.x
	bsr.b	.freeDeliLoadedFile
	bsr.w	freeDeliBase
	popm	all
	rts

.freeDeliLoadedFile
	tst.l	deliLoadFileArray(a5)
	beq.b 	.xy
	move.l	deliLoadFileArray(a5),a2
.loop
	tst.l 	(a2) 
	beq.b 	.end
	move.l	(a2),a1
	move.l	4(a2),d0
	lore 	Exec,FreeMem
	clr.l	(a2)+
	clr.l	(a2)+
	bra.b 	.loop
.end 
	clr.l	deliLoadFileIoErr(a5)
	clr.l	deliLoadFileArray(a5)
.xy 
	rts	


* in:
*   d0 = tag to find
* out:
*   d0 = tag data or NULL if not found
deliGetTag
	* This is a ptr to a seglist, loaded with LoadSeg()
	move.l	deliPlayer(a5),a0
deliGetTagFromA0
	* tag item array
	move.l	16(a0),a0
.loop
    ;cmp.l  #TAG_END,(a0)
    tst.l   (a0)            * TAG_END is NULL
    beq.b   .notFound
    cmp.l   (a0),d0
    bne.b   .notThis
    move.l  4(a0),d0
    rts
.notFound
	moveq   #0,d0
	rts
.notThis
    addq.l  #8,a0
    bra.b   .loop

deliCallFunc	
	tst.l	d0 
	beq.b	.noFunc
	DPRINT	"Call %lx"
	pushm 	d2-d7/a2-a6
	move.l	deliBase(a5),a5
	move.l	d0,a0
	jsr	(a0)
	popm	d2-d7/a2-a6
.noFunc rts

* in:
*   d0: deliplayer or delicustom address from loadseg
* out:
*   d0: 0=all ok, negative ier_-code otherwise
deliInit:
	pushm	d1-a6	
	DPRINT	"deliInit 0x%lx"
	move.l	d0,deliPlayer(a5)
	move	playertype(a5),deliPlayerType(a5)
	bsr.w	buildDeliBase
	tst.l	d0
	beq.w	.noMemError
	move.l	deliBase(a5),a4

	* Quite important to clear the old ones away
	* so that they don't get accidentally called
	* on new modules and crash.
	clr.l	deliStoredInterrupt(a5)
	clr.l	deliStoredSetVolume(a5)
	clr.l	deliStoredSetVoices(a5) 
	clr.l	deliStoredNoteStruct(a5) 
	clr.l	deliStoredGetPositionNr(a5)
	clr.l	deliPatternInfo(a5)
	
 if DEBUG
 	move.l	#DTP_PlayerName,d0 
	bsr.w	deliGetTag 
	beq.b	.noPlr
	DPRINT	"Name: %s"
.noPlr

	bsr.w	deliShowTags
	bsr.w	deliShowFlags
 endif

	* Order in DT
	* InitPlayer
	* SubSongRange
	* SubSongRange
	* Volume
	* Volume
	* InitSound (dtg_SndNum=1)
	* SubSongRange	

	move.l	#DTP_DeliBase,d0
	bsr.w	deliGetTag
	beq.b	.noDBTag
	move.l	d0,a0 
	move.l	a4,(a0)
.noDBTag

	move.l	#EP_EagleBase,d0
	bsr.w	deliGetTag
	beq.b	.noEBTag
	move.l	d0,a0 
	move.l	a4,(a0)
.noEBTag

	move.l	#DTP_Config,d0  
	bsr.w	deliGetTag
	bsr.w	deliCallFunc

	* For ImpulseTracker support:
	move.l	#DTP_InitNote,d0  
	bsr.w	deliGetTag
	bsr.w	deliCallFunc

	move.l	#DTP_CustomPlayer,d0
	bsr.w	deliGetTag
	bne.w	.checksOk

	* Checks! Run through known ones
	* and accept if one of these accepts.
	
	move.l	#DTP_Check2,d0  
	bsr.w	deliGetTag
	beq.b	.noCheck2
	bsr.w	deliCallFunc
	DPRINT	"DTP_Check2: %ld"
	tst.l	d0
	beq.b	.checksOk
.noCheck2	
	move.l	#EP_Check3,d0  
	bsr.w	deliGetTag
	beq.b	.noCheck3
	bsr.w	deliCallFunc
	DPRINT	"EP_Check3: %ld"
	tst.l	d0
	beq.b	.checksOk
.noCheck3
	move.l	#EP_Check5,d0  
	bsr.w	deliGetTag
	;beq.b	.noCheck5
	beq.w	.checkError
	bsr.w	deliCallFunc
	DPRINT	"EP_Check5: %ld"
	tst.l	d0
	bne.w	.checkError
.noCheck5

.checksOk
	bsr.w	clearCpuCaches  ; Extra safety

	move.l	#EP_InitAmplifier,d0 
	bsr.w	deliGetTag 
	bsr.w	deliCallFunc

	move.l	#EP_PatternInit,d0  
	bsr.w	deliGetTag
	beq.b	.noPattInit
	bsr.w	deliCallFunc
	move.l	a0,deliPatternInfo(a5)
.noPattInit

	move.l	#EP_Flags,d0
	bsr.w	deliGetTag
	beq.b	.noFlags
	bsr.w	deliHandleFlags
.noFlags

	move.l	#DTP_ExtLoad,d0  
	bsr.w	deliGetTag
	beq.b	.noExtLoad
	bsr.w	deliCallFunc
	DPRINT	"DTP_ExtLoad: %lx"
	tst.l	d0
	bne.w	.extLoadError
.noExtLoad

	move.l	#EP_StructInit,d0
	bsr.w	deliGetTag
	beq.b	.noUPS
	bsr.w	deliCallFunc	
	move.l	a0,deliUPSStruct(a5)
	;beq.w	.noUPS
	;move.l	playerbase(a5),a0
	;or	#pf_scope!pf_quadscopeUps,p_liput(a0)
;	DPRINT	"Quadscope supported"
.noUPS
 
	move.l	#DTP_InitPlayer,d0  
	bsr.w	deliGetTag
	bsr.w	deliCallFunc	
	* Status is returned in d0, can't rely on status flags
	* here. d0=0 if ok, else not ok
	tst.l	d0
	bne.w	.initError
	DPRINT	"initPlayer ok"

	bsr.w	clearCpuCaches  ; Extra safety

	* set default song number
	bsr.w	deliGetSongInfo
	* d0 = def, d1 = min, d2 = max	
	move.l	deliBase(a5),a0
	move	d0,dtg_SndNum(a0)
	move	d0,songnumber(a5)
	move	d1,minsong(a5)
	move	d2,maxsongs(a5)	

	move.l	#DTP_Volume,d0  
	bsr.w	deliGetTag
	move.l	d0,deliStoredSetVolume(a5)

	move.l	#EP_Voices,d0  
	bsr.w	deliGetTag
	move.l	d0,deliStoredSetVoices(a5)

	move.l	#DTP_NoteStruct,d0  
	bsr.w	deliGetTag
	beq.b 	.noNoteStruct
	* This is an address to the struct
	move.l	d0,a0
	move.l	(a0),a0
	move.l	a0,deliStoredNoteStruct(a5)
 if DEBUG 
	bsr.w	deliShowNoteStruct
 endif 
.noNoteStruct

	move.l	#DTP_InitSound,d0  
	bsr.w	deliGetTag
	bsr.w	deliCallFunc	
	* Does not return error code

	DPRINT	"InitSound ok"
	bsr.w	clearCpuCaches  ; Extra safety

	* Get position info if available
	bsr.w	deliUpdatePositionInfo

	move.l	#DTP_Interrupt,d0  
	bsr.w	deliGetTag
	move.l	d0,deliStoredInterrupt(a5)	

	move.l	#DTP_StartInt,d0
	bsr.w	deliGetTag
	beq.b	.noStartInt
	DPRINT	"using module interrupt"
	bsr.w	deliCallFunc
	* DTP_StartInt overrides DTP_Interrupt
	clr.l	deliStoredInterrupt(a5)
	bra.b	.skip
.noStartInt

	* see if an interrupt routine is provided.
	* if so, set up a cia interrupt to drive it.
	* otherwise assume the module handles it.
	tst.l	deliStoredInterrupt(a5)
	beq.b	.skip
	* If running PS3M, do not start interrupts.
	* PS3M will handle it.
	cmp	#pt_multi,playertype(a5)
	beq.b 	.skip

	DPRINT	"using hippo interrupt"
 
	* interrupt routine provided, set up an interrupt
	move	dtg_Timer(a4),d0
	bsr.w	init_ciaint_withTempo
	beq.b	.gotCia
	DPRINT	"cia error"

	* try to clean up
	move.l	#DTP_EndSound,d0  
	bsr.w	deliGetTag
	bsr.w	deliCallFunc	
	move.l	#DTP_EndPlayer,d0  
	bsr.w	deliGetTag
	bsr.w	deliCallFunc	

	moveq	#ier_nociaints,d0
	bra.b	.ciaError
.gotCia
.skip

 if DEBUG
	moveq	#0,d0
	move	dtg_Timer(a4),d0
	DPRINT	"init ok, dtg_Timer=%ld"
 endif

; TEST RUN
 ifne DELI_TEST_MODE
 	move	#1-1,d0
.bbb
	pushm all
	move.l	deliStoredInterrupt(a5),a0 
	move.l	deliBase(a5),a5
	;jsr	 (a0)
	popm all
	dbf	d0,.bbb
 endc
	* ok
	moveq	#0,d0
.ciaError
.exit
	popm	d1-a6
	rts

.checkError
	moveq	#ier_unknown,d0
	bra.b	.exit
.noMemError
	moveq	#ier_nomem,d0 
	bra.b 	.exit

.initError
	DPRINT	"InitPlayer error: %ld"
	tst.l	deliLoadFileIoErr(a5)
	bne.b	.ioErr
	lea	.initErrMsg(pc),a0 
	bra.b	.showErr

.extLoadError
	tst.l	deliLoadFileIoErr(a5)
	bne.b 	.ioErr
	lore	Dos,IoErr 
	bra.b	.ioErr2

.ioErr
	move.l	deliLoadFileIoErr(a5),d0
.ioErr2
	tst.b	uusikick(a5)
	bne.b	.newIoErr
.oldIoErr
	lea	.ioErrMsg(pc),a0 
.showErr
	jsr	desmsg
.ioErr3
	lea	 desbuf(a5),a1 
	jsr	 request
	moveq	#ier_eagleplayer,d0
	bra.b	.exit

.newIoErr
	tst.l	d0
	beq.b	.oldIoErr

	lea	.ioErrMsg2(pc),a3
	clr.b	(a3)
	move.l	d0,d1 
	pushpea	.ioErrMsg(pc),d2
	pushpea desbuf(a5),d3
	moveq	#100,d4
	lore	Dos,Fault
	move.b	#' ',(a3)
	bra.b	.ioErr3

.initErrMsg 
	dc.b	"Eagleplayer init error (%ld)",0
.ioErrMsg
	dc.b	"Error loading additional module data"
.ioErrMsg2
	dc.b	" (%ld)",0
 even


* Read module info values
* in:
*   d1: info value to find
* out:
*   d0: value, or -1 if not found
deliFindInfoValue
	move.l	#EP_Get_ModuleInfo,d0
	bsr.w	deliGetTag
	beq.b 	.tryAnother
	bsr.w	deliCallFunc
	bra.b	.gotIt
.tryAnother
	move.l	#EP_NewModuleInfo,d0 
	bsr.w	deliGetTag
	beq.b 	.notFound
	move.l	d0,a0
.gotIt
	* a0 = module info table
.loop
	move.l	(a0)+,d0
	beq.b  .end 
	cmp.l	d1,d0 
	beq.b 	.found
	addq.l	#4,a0
	bra.b  .loop
.found 
	move.l (a0),d0 
.end 
	rts
.notFound 
	moveq	#-1,d0 
	rts 

* After InitSound this updates the max position info
deliUpdatePositionInfo	
	clr	pos_maksimi(a5)
	move.l	#EP_GetPositionNr,d0  
	bsr.w	deliGetTag
	move.l	d0,deliStoredGetPositionNr(a5) 
	beq.b	.noPos
	move.l	#MI_Length,d1
	bsr.b	deliFindInfoValue 
	bmi.b 	.noPos
	beq.b	.noPos
	move	d0,pos_maksimi(a5)
	move.l	playerbase(a5),a0 
	or	#pf_poslen,p_liput(a0)
	rts
.noPos
	move.l	playerbase(a5),a0 
	move	p_liput(a0),d0
	bclr	#pb_poslen,d0
	move	d0,p_liput(a0)
	rts

* out:
*  d0=default song
*  d1=min song
*  d2=max song
deliGetSongInfo
	move.l	#DTP_SubSongRange,d0  
	bsr.w	deliGetTag
	beq.b	.noSubSongs1
	bsr.w	deliCallFunc
	move.l	d1,d2
	move.l	d0,d1
	move.l	playerbase(a5),a0 
	or	#pf_song,p_liput(a0)
	DPRINT	"Subsongs def=%ld min=%ld max=%ld"
	rts

.noSubSongs1
	move.l	#DTP_NewSubSongRange,d0  
	bsr.w	deliGetTag
	beq.b	.noSubSongs2
	move.l	d0,a0
	movem	(a0),d0/d1/d2
	move.l	playerbase(a5),a0 
	or	#pf_song,p_liput(a0)
	DPRINT	"NewSubSongs def=%ld min=%ld max=%ld"
	rts
	
.noSubSongs2
	DPRINT	"No subsongs"
	move.l	playerbase(a5),a0 
	and	#~pf_song,p_liput(a0)
	moveq	#0,d0 
	moveq	#0,d1 
	moveq	#0,d2	
	rts	

* Interrupt play routine, use cached pointers to avoid tag searches
deliInterrupt:
deliPlay:
	move.l	a5,a4
	push	a4
	move.l	deliBase(a5),a5
	move	mainvolume(a4),d0
	move	d0,dtg_SndVol(a5)
	move	d0,EPG_Voice1Vol(a5)
	move	d0,EPG_Voice2Vol(a5)
	move	d0,EPG_Voice3Vol(a5)
	move	d0,EPG_Voice4Vol(a5)

	move.l	deliStoredSetVoices(a4),d0 
	beq.b 	.noSetVoices
	move.l	d0,a0
	* Enable all channels
	moveq	#%1111,d0
	jsr 	(a0)
	move.l	(sp),a4
.noSetVoices

	move.l	deliStoredInterrupt(a4),d0
	beq.b	.noInt
	move.l	d0,a0
 ifne DELI_TEST_MODE
	move	#$500,$dff180
 else
	jsr	(a0)
 endif
	move.l	(sp),a4
.noInt

	move.l	deliStoredSetVolume(a4),d0
	beq.b	.noVol
	move.l 	d0,a0
	jsr	(a0)
	move.l	(sp),a4
.noVol

	move.l	deliStoredGetPositionNr(a4),d0
	beq.b 	.noPos 
	move.l 	d0,a0
	jsr	(a0)
	move.l	(sp),a4
	tst	d0
	bmi.b	.noPos
	move	d0,pos_nykyinen(a4)
.noPos	
	pop 	a4
	
	pushm	a4/a5/a6
	move.l	deliStoredNoteStruct(a4),d0 
	bsr.w	deliNotePlayer
	popm	a4/a5/a6
	rts

deliEnd:
	pushm	d1-a6
	DPRINT	"deliEnd"
	
	move.l	deliStoredInterrupt(a5),d0
	beq.b	.noIntUsed
	bsr.w	rem_ciaint
.noIntUsed

	move.l	#DTP_StopInt,d0
	bsr.w	deliGetTag
	bsr.w	deliCallFunc

	move.l	#DTP_EndSound,d0  
	bsr.w	deliGetTag
	bsr.w	deliCallFunc

	move.l	#DTP_EndPlayer,d0  
	bsr.w	deliGetTag
	bsr.w	deliCallFunc
	
	move.l	#EP_StructEnd,d0  
	bsr.w	deliGetTag
	bsr.w	deliCallFunc

	bsr.w	clearsound

	move.l	#EP_EjectPlayer,d0
	bsr.w	deliGetTag
	bsr.w	deliCallFunc
	
	popm	d1-a6
	rts

deliSong
	bsr.b	deliStop
	bsr.w	deliGetSongInfo
	* returns
	* d1 = min song
	* d2 = max song
	
	move	songnumber(a5),d0

	* clamp d0 within d1-d2
	jsr	clampWord
	move	d0,songnumber(a5)

	DPRINT	"deliSong set: %ld"
	
	* Put it, wrong number may crash some players
	move.l deliBase(a5),a0
	move	d0,dtg_SndNum(a0)

	move.l	#DTP_InitSound,d0
	bsr.w	deliGetTag
	bsr.w	deliCallFunc
	move.l	#DTP_StartInt,d0
	bsr.w	deliGetTag
	bsr.w	deliCallFunc
	bsr.w	deliUpdatePositionInfo
	rts

* Not sure what exactly should be done with these two.
* Seems to work more or less.
deliStop
	DPRINT	"deliStop"
	move.l	#DTP_EndSound,d0
	bsr.w	deliGetTag
	;bsr	deliCallFunc	;;**
	move.l	#DTP_StopInt,d0
	bsr.w	deliGetTag
	bsr.w	deliCallFunc
	bsr.w	clearsound
	;move	#$f,$dff096
	rts

deliCont
	DPRINT	"deliCont"
	move.l	#DTP_InitSound,d0
	bsr.w	deliGetTag
	;bsr	.callFunc
	move.l	#DTP_StartInt,d0
	bsr.w	deliGetTag
	bsr.w	deliCallFunc
	move	#$800f,$dff096
	rts

deliForward
	DPRINT	"deliForward"
	move.l	#DTP_NextPatt,d0
	bsr.w	deliGetTag
	bsr.w	deliCallFunc
	rts

deliBackward
	DPRINT	"deliBackward"
	move.l	#DTP_PrevPatt,d0
	bsr.w	deliGetTag
	bsr.w	deliCallFunc
	rts

deliVolume	
	move.l	deliBase(a5),a0
	move	mainvolume(a5),d0
	move	d0,dtg_SndVol(a0)
	move	d0,EPG_Voice1Vol(a0)
	move	d0,EPG_Voice2Vol(a0)
	move	d0,EPG_Voice3Vol(a0)
	move	d0,EPG_Voice4Vol(a0)
	move.l	deliStoredSetVolume(a5),d0
	beq.b	.noVol
	move.l 	d0,a1
	push	a5
	move.l	a0,a5	
	jsr	(a1)
	pop 	a5
.noVol
	rts

deliAuthor
	rts
	;move.l	#DTP_Creator,d0
	;bra	deliGetTag
	
freeDeliBase
	tst.l	deliData(a5)
	beq.b	.x

	move.l deliData(a5),a0 
	jsr 	freemem 
.x	clr.l	deliData(a5)
	rts 



* Build the DeliBase structure, this is not a complete version.
buildDeliBase
	bsr.b	freeDeliBase

	rsreset 
_eagleJumpTable 	rs.b 	-ENPP_SizeOf
_deliBase		rs.b 	EPG_SizeOf 
_deliPath		rs.b    200
_deliPathArray		rs.b   	200
_upsStructure 		rs.b  	UPS_SizeOF
* Space for 128 (address, length) pairs for dtg_LoadFile 
_loadFileArray		rs.l 	2*DELI_LIST_DATA_SLOTS
_deliDataSize		rs.b	0

	move.l	#_deliDataSize,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	jsr	getmem
	bne.b 	.ok 
	rts
.ok
	move.l 	d0,deliData(a5)
	move.l	d0,a4

	lea	_deliBase(a4),a0 
	move.l	a0,deliBase(a5)

	* InStereo2 uses this private structure
	lea	_upsStructure(a4),a1
	move.l	a1,EPG_UPS_Structure(a0)

	lea	_loadFileArray(a4),a1
	move.l	a1,deliLoadFileArray(a5)

	lea	_deliPath(a4),a1
	move.l	a1,deliPath(a5)
	move.l	a1,dtg_DirArrayPtr(a0)

	lea	_deliPathArray(a4),a1
	move.l	a1,deliPathArray(a5)
	move.l	a1,dtg_PathArrayPtr(a0)

	push	a0
	jsr	getcurrent 
	pop 	a0
	* a3 = node
	
	* Grab path and file parts
	* Name without path to A1
	move.l	l_nameaddr(a3),a1
	move.l	a1,dtg_FileArrayPtr(a0)
	* Full path to A2
	lea	l_filename(a3),a2
	move.l	deliPath(a5),a3
	push	a2
.copy	move.b	(a2)+,(a3)+
	cmp.l	a2,a1
	bne.b	.copy
	clr.b	(a3)		

	* The full path needs to be populated here, too.
	* "Test drive 2" uses it, for example.
	pop	a2
	move.l	deliPathArray(a5),a1
.c2	move.b	(a2)+,(a1)+
	bne.b	.c2 


 if DEBUG
	move.l	dtg_FileArrayPtr(a0),d0
	DPRINT	"File: %s"
	move.l	dtg_DirArrayPtr(a0),d0
	DPRINT	"Dir: %s"
 endif

	move.l	_DosBase(a5),dtg_DOSBase(a0)
	move.l	_IntuiBase(a5),dtg_IntuitionBase(a0)
	move.l	_GFXBase(a5),dtg_GfxBase(a0)
	
	; Illegal address for enforcer
	move.l	#$10000000,dtg_GadToolsBase(a0)
	move.l	#$10000000,dtg_AslBase(a0)

	clr	dtg_SndNum(a0) * this must be correct 
	moveq	#64,d0
	move	d0,dtg_SndVol(a0)
	move	d0,dtg_SndLBal(a0)
	move	d0,dtg_SndRBal(a0)
	clr	dtg_LED(a0)

	move	#%1111,EPG_Voices(a0)
	move	d0,EPG_Voice1Vol(a0)
	move	d0,EPG_Voice2Vol(a0)
	move	d0,EPG_Voice3Vol(a0)
	move	d0,EPG_Voice4Vol(a0)
	move	#255,EPG_Volume(a0)
	move	#255,EPG_Balance(a0)
	move	#255,EPG_LeftBalance(a0)
	move	#255,EPG_RightBalance(a0)

	move.l	moduleaddress(a5),dtg_ChkData(a0) 
	move.l	modulelength(a5),dtg_ChkSize(a0)
	* Default timer value is needed by
	* Sonix Sound Driver
	move	#28419/2,dtg_Timer(a0)

	pea	deliAllocAudio(pc)
	move.l	(sp)+,dtg_AudioAlloc(a0)
	pea	deliFreeAudio(pc)
	move.l	(sp)+,dtg_AudioFree(a0)
	pea	dmawait(pc)
	move.l	(sp)+,dtg_WaitAudioDMA(a0)
	pea	.startInt(pc)
	move.l	(sp)+,dtg_StartInt(a0)
	pea	.stopInt(pc)
	move.l	(sp)+,dtg_StopInt(a0)
	pea	.songEnd(pc)
	move.l	(sp)+,dtg_SongEnd(a0)	* may be called from interrupt
	pea	.setTimer(pc)
	move.l	(sp)+,dtg_SetTimer(a0)	* may be called from interrupt
	pea	.allocListData(pc)
	move.l	(sp)+,dtg_AllocListData(a0)
	pea	.freeListData(pc)
	move.l	(sp)+,dtg_FreeListData(a0)
	pea	deliCopyString(pc)
	move.l	(sp)+,dtg_CopyString(a0)
	pea	deliCopyFile(pc)
	move.l	(sp)+,dtg_CopyFile(a0)
	pea	deliCopyDir(pc)
	move.l	(sp)+,dtg_CopyDir(a0)
	pea	deliLoadFile(pc)
	move.l	(sp)+,dtg_LoadFile(a0)
	pea	deliGetListData(pc)
	move.l	(sp)+,dtg_GetListData(a0)
	pea	.cutSuffix(pc)
	move.l	(sp)+,dtg_CutSuffix(a0)

	pea	deliModuleChange(pc)
	move.l	(sp)+,EPG_ModuleChange(a0)

	* Stub the rest
 	lea	.stub(pc),a1
	move.l	a1,dtg_LockScreen(a0)
	move.l	a1,dtg_UnlockScreen(a0)
	move.l	a1,dtg_NotePlayer(a0) 	* may be called from interrupt

	* EaglePlayer negative offset jump table
	lea	eagleJumpTableStart(pc),a1
	lea 	eagleJumpTableEnd(pc),a2	
.jumps	
	move.l	a1,a3
	add	(a1)+,a3
	move.l	a3,-(a0)	; jmp destination
	move	#$4ef9,-(a0) ; jmp
	cmp.l	a1,a2
	bne.b	.jumps
	; Ensure jump table code is flushed
 	bra	clearCpuCaches

.songEnd
	* May be called from interrupt, no logging allowed
	pushm	d0/a0/a5
	lea	var_b,a5
	move.l	playerbase(a5),a0 
	move	p_liput(a0),d0 
	and	#pf_end,d0
	beq.b	.noSongEnd
	st	songover(a5)
.noSongEnd
	popm 	d0/a0/a5
	rts

.setTimer
	* May be called from interrupt, no logging allowed
	push	d0
	move	dtg_Timer(a5),d0
	jsr	ciaint_setTempoFromD0
	pop 	d0 
	rts

.stub
	moveq	#0,d0
.dummyEagleFunc
	rts

.startInt	
	DPRINT 	"deliStartInt"
	moveq	#0,d0
	rts
.stopInt 
	DPRINT	"deliStopInt"
	moveq	#0,d0
	rts
.cutSuffix 
	DPRINT	"cutSuffix"
	moveq	#0,d0
	rts
.allocListData
	DPRINT	"allocListData %ld %lx"
	* used by stonetracker
	pushm	d1-a6
	lea	var_b,a5
	move.l	d0,d6
	move.l	d1,d7
	bsr.w	deliFindEmptyListDataSlot
	bne.b	.err
	move.l	a1,a3 
	move.l	d6,d0
	move.l	d7,d1
	lore 	Exec,AllocMem
	tst.l 	d0 
	beq.b 	.err
	* Store into list data slot
	movem.l	d0/d6,(a3)
.allocListDataX
 	popm 	d1-a6
	rts
.err
	moveq	#0,d0
	bra.b 	.allocListDataX
	
.freeListData
	DPRINT	"freeListData"
	moveq	#0,d0
	rts

deliAllocAudio 
	DPRINT	"deliAudioAlloc"
	pushm	d1-a6
	lea	var_b,a5
	* returns d0=0 on success:
	jsr	varaa_kanavat 
	popm	d1-a6
	rts

deliFreeAudio 
	DPRINT	"deliAudioFree"
	pushm	d1-a6
	lea	var_b,a5
	jsr	vapauta_kanavat
	popm	d1-a6
	rts

deliCopyString move.l a0,d0
	bsr.w	deliAppendStr
 if DEBUG
	move.l	deliPathArray+var_b,d1
	DPRINT	"copyString %s path=%s"
 endif
	moveq	#0,d0
	rts
deliCopyFile 
	move.l	dtg_FileArrayPtr(a5),a0
	bsr.w	deliAppendStr
 if DEBUG
	move.l	deliPathArray+var_b,d0
	DPRINT	"copyFile path=%s"
 endif
	moveq	#0,d0
	rts
deliCopyDir 
	move.l	dtg_DirArrayPtr(a5),a0
	bsr.w	deliAppendStr
 if DEBUG
	move.l	deliPathArray+var_b,d0
	DPRINT	"copyDir path=%s"
 endif
	moveq	#0,d0
	rts
deliLoadFile
 if DEBUG
	move.l	deliPathArray+var_b,d0
	DPRINT	"loadFile '%s'"
 endif
	pushm	d1-a6
	lea 	var_b,a5

	* Find empty loadfile slot
	bsr.b	deliFindEmptyListDataSlot
	bne.b	.noSlots
	lea	4(a1),a2

	move.l	#MEMF_CHIP!MEMF_CLEAR,d0
	move.l	deliPathArray+var_b,a0

	jsr	loadfileStraight
	clr.l 	deliLoadFileIoErr(a5)
	move.l	d0,d7
	beq.b	.ok	
	lore 	Dos,IoErr
	move.l	d0,deliLoadFileIoErr(a5)
.ok
	move.l	d7,d0
 if DEBUG
	move.l	(a1),d1
	move.l	(a2),d2
	move.l	deliLoadFileIoErr(a5),d3
	DPRINT "deliLoad=%ld addr=%lx len=%ld err=%ld"
 endif
.noSlots
	popm	d1-a6
	
 * 0 = success, non-0: fail
	rts

* out:
*   a1 = empty slot for (addr,len) pair
deliFindEmptyListDataSlot
	move.l	deliLoadFileArray(a5),a1
	moveq	#0,d0
.find
	cmp	#DELI_LIST_DATA_SLOTS,d0 
	beq.b	.error 
	tst.l	(a1)
	beq.b	.found
	addq.l	#8,a1
	addq	#1,d0
	bra.b 	.find
.found
	moveq	#0,d0
	rts
.error 
	moveq	#-1,d0 
	rts 

* Get loaded data
* in: 
*   d0 = file number. 0 is the original module, 
*                     1 is the 1st loaded file with dtg_LoadFile, etc
deliGetListData 
	DPRINT	"getListData %ld"
	tst.l	d0 
	beq.b	.first

	* Grab (addr,len) so that index 1 corresponds to the first item.
	pushm	d3/a1
	move.l	deliLoadFileArray+var_b,a1
	move	d0,d3
	lsl	#3,d3

 if DEBUG
 	move.l	-8(a1,d3),d0
	move.l	-8+4(a1,d3),d1
	DPRINT	"0x%lx %ld"
 endif
	move.l	-8(a1,d3),a0
	move.l	-8+4(a1,d3),d0
	popm	d3/a1
	rts
.first
 if DEBUG
	move.l	moduleaddress+var_b,d0
	move.l	modulelength+var_b,d1
	DPRINT	"0x%lx %ld"
 endif
	move.l	moduleaddress+var_b,a0
	move.l	modulelength+var_b,d0
	rts

deliAppendStr
	move.l 	dtg_PathArrayPtr(a5),a1 
.1	tst.b 	(a1)+
	bne.b 	.1
	subq	#1,a1
.2	move.b 	(a0)+,(a1)+
	bne.b 	.2
	rts

* First negative offset is first, -6
eagleJumpTableStart
	dr.w funcENPP_AllocSampleStruct
	dr.w funcENPP_NewLoadFile2
	dr.w funcENPP_MakeDirCorrect
	dr.w funcENPP_TestAufHide
	dr.w funcENPP_ClearCache
	dr.w funcENPP_CopyMemQuick
	dr.w funcENPP_GetPassword
	dr.w funcENPP_StringCopy2
	dr.w funcENPP_ScreenToFront
	dr.w funcENPP_WindowToFront
	dr.w funcENPP_GetListData
	dr.w funcENPP_LoadFile    **
	dr.w funcENPP_CopyDir 	 **
	dr.w funcENPP_CopyFile    **
	dr.w funcENPP_CopyString
	dr.w funcENPP_AllocAudio
	dr.w funcENPP_FreeAudio
	dr.w funcENPP_StartInterrupt
	dr.w funcENPP_StopInterrupt
	dr.w funcENPP_SongEnd
	dr.w funcENPP_CutSuffix
	dr.w funcENPP_SetTimer
	dr.w funcENPP_WaitAudioDMA
	dr.w funcENPP_SaveMem
	dr.w funcENPP_FileReq
	dr.w funcENPP_TextRequest
	dr.w funcENPP_LoadExecutable
	dr.w funcENPP_NewLoadFile
	dr.w funcENPP_ScrollText
	dr.w funcENPP_LoadPlConfig
	dr.w funcENPP_SavePlConfig
	dr.w funcENPP_FindTag
	dr.w funcENPP_FindAuthor
	dr.w funcENPP_Hexdez
	dr.w funcENPP_TypeText
	dr.w funcENPP_ModuleChange
	dr.w funcENPP_ModuleRestore
	dr.w funcENPP_StringCopy
	dr.w funcENPP_CalcStringSize
	dr.w funcENPP_StringCMP
	dr.w funcENPP_DMAMask	 	*
	dr.w funcENPP_PokeAdr		*	 
	dr.w funcENPP_PokeLen		*
	dr.w funcENPP_PokePer		*
	dr.w funcENPP_PokeVol		*
	dr.w funcENPP_PokeCommand	* filter toggle
	dr.w funcENPP_Amplifier
	dr.w funcENPP_TestAbortGadget
	dr.w funcENPP_GetEPNrfromMessage
	dr.w funcENPP_InitDisplay
	dr.w funcENPP_FillDisplay
	dr.w funcENPP_RemoveDisplay
	dr.w funcENPP_GetLocaleString
	dr.w funcENPP_SetWaitPointer
	dr.w funcENPP_ClearWaitPointer
	dr.w funcENPP_OpenCatalog
	dr.w funcENPP_CloseCatalog
	dr.w funcENPP_AllocAmigaAudio
	dr.w funcENPP_FreeAmigaAudio
	dr.w funcENPP_RawToFormat
	dr.w funcENPP_FindAmplifier
	dr.w funcENPP_UserCallup5
	dr.w funcENPP_GetLoadListData
	dr.w funcENPP_SetListData
	dr.w funcENPP_GetHardwareType
eagleJumpTableEnd

funcENPP_ClearCache
	;DPRINT "ENPP_ClearCache"
	jmp clearCpuCaches
funcENPP_GetListData
	bra.w	deliGetListData
funcENPP_LoadFile
	bra.w	deliLoadFile
funcENPP_CopyDir
	DPRINT "ENPP_CopyDir"
	bra.w	deliCopyDir
funcENPP_CopyFile
	DPRINT "ENPP_CopyFile"
	bra.w	 deliCopyFile
funcENPP_CopyString
	DPRINT "ENPP_CopyString"
	bra.w	deliCopyString
funcENPP_AllocAudio
	DPRINT "ENPP_AllocAudio"
	bra.w deliAllocAudio
funcENPP_FreeAudio
	DPRINT "ENPP_FreeAudio"
	bra.w deliFreeAudio
funcENPP_SongEnd
	;DPRINT "ENPP_SongEnd"
	jmp	 dtg_SongEnd(a5)
funcENPP_SetTimer
	;DPRINT "ENPP_SetTimer"
	jmp dtg_SetTimer(a5)
funcENPP_WaitAudioDMA
	;DPRINT "ENPP_WaitAudioDMA"
	jmp dmawait
funcENPP_ModuleChange
	DPRINT "ENPP_ModuleChange"
	bra.w	deliModuleChange
funcENPP_AllocAmigaAudio
	;DPRINT "ENPP_AllocAmigaAudio"
	bra.w	deliAllocAudio
funcENPP_FreeAmigaAudio
	;DPRINT "ENPP_FreeAmigaAudio"
	bra.w deliFreeAudio

* Sequence (kpl14.s):
* - Stop channel DMAs
* - Set sample start and sample length
* - Large DMA wait
* - Enable channel DMAs
* - Small DMA wait
* - Set loopstart and replen for enabled channels

* Sequence (noteplayer):
* - Stop channel DMAs, ENPP_DMAMask
* - Set sample:
*   - ENPP_PokeAdr, ENPP_PokeLen
*   - ENPP_PokeVol, ENPP_PokePer
* - Start channel DMAs, ENPP_DMAMask
* - Set sample loop:
*   - ENPP_PokeAdr, ENPP_PokeLen

* In:
*   d0 = negative: enable DMA, positive: disable DMA
*   d1 = DMA audio flags %abcd
funcENPP_DMAMask
	;move	#$f00,$dff180

	push	d1
	tst	d0
	bpl.b	.clr
	or	#$8000,d1
	move	d1,$dff096
;	* Set scope trigger bits
	or.b	d1,scopeData+scope_trigger+var_b
	jsr	dmawait
	pop 	d1
	rts

.clr
	move	d1,$dff096
	not.b	d1
	* Clear scope trigger bits
	and.b	d1,scopeData+scope_trigger+var_b
	jsr	dmawait
	pop 	d1
	rts

* In:
*   d0 = address
*   d1 = channel 0..3
funcENPP_PokeAdr
	pushm	d2/d3/a0/a1
	moveq	#3,d2
	and	d1,d2
	lsl	#4,d2
	lea	$dff0a0,a0
	move.l	d0,(a0,d2)

	* Set sample start if DMA is not enabled,
	* otherwise set loopstart
 	lea	var_b,a0
 	move	#pf_quadscopePoke,d3
 	move.l	playerbase(a0),a1
 	and	p_liput(a1),d3
 	beq.b	.2

	lea	scopeData(a0),a0
	moveq	#1,d3
	lsl	d1,d3
	and.b	scope_trigger(a0),d3
	bne.b	.1
	move.l	d0,ns_start+scope_ch1(a0,d2)
.1
	move.l	d0,ns_loopstart+scope_ch1(a0,d2)
.2
	popm	d2/d3/a0/a1
	rts
	
* In:
*   d0 = length
*   d1 = channel 0..3
funcENPP_PokeLen
	pushm	d2/d3/a0/a1
	moveq	#3,d2
	and	d1,d2
	lsl	#4,d2
	tst	d0
	bne.b	.nozero
	moveq	#1,d0
.nozero
	lea	$dff0a0,a0
	move	d0,4(a0,d2)

 	* Set sample len if DMA is not enabled,
	* otherwise set looplen
 	lea	var_b,a0
 	move	#pf_quadscopePoke,d3
 	move.l	playerbase(a0),a1
 	and	p_liput(a1),d3
 	beq.b	.2

	lea	scopeData(a0),a0
	moveq	#1,d3
	lsl	d1,d3
	and.b	scope_trigger(a0),d3
	bne.b 	.1
	move	d0,ns_length+scope_ch1(a0,d2)
.1
	move	d0,ns_replen+scope_ch1(a0,d2)
.2
	popm	d2/d3/a0/a1
	rts

* In:
*   d0 = period
*   d1 = channel 0..3
funcENPP_PokePer
	pushm	d2/d3/a0/a1
	moveq	#3,d2
	and	d1,d2
	lsl	#4,d2
	lea	$dff0a0,a0
	move	d0,6(a0,d2)

	lea	var_b,a0
 	move	#pf_quadscopePoke,d3
 	move.l	playerbase(a0),a1
 	and	p_liput(a1),d3
 	beq.b	.1

	lea	scopeData(a0),a0
	move	d0,ns_period(a0,d2)
.1
	popm	d2/d3/a0/a1
	rts

* In:
*   d0 = volume
*   d1 = channel 0..3
funcENPP_PokeVol
	pushm	d2/d3/a0/a1
	moveq	#3,d2
	and	d1,d2
	lsl	#4,d2
	mulu	mainvolume+var_b,d0
	lsr	#6,d0
	lea	$dff0a0,a0
	move	d0,8(a0,d2)

 	lea	var_b,a0
 	move	#pf_quadscopePoke,d3
 	move.l	playerbase(a0),a1
 	and	p_liput(a1),d3
 	beq.b	.1

	lea	scopeData(a0),a0
	CLAMPVOL d0
	move	d0,ns_tempvol(a0,d2)
.1
	popm	d2/d3/a0/a1
	rts

* In:
*   d0 = command
*   d1 = parameter
funcENPP_PokeCommand
	;DPRINT "ENPP_PokeCommand"
	cmp.b	#1,d0 
	bne.b 	.unknown
	* d1=0 -> led off
	* d1=1 -> led on
	tst.b 	d1
	beq.b .off
	bclr	#1,$bfe001
.unknown
	rts
.off 
	bset	#1,$bfe001
	rts

*************** Unimplemented eaglebase functions:

 if DEBUG
funcENPP_Amplifier
	; Called from interrupt, no logging
	;DPRINT "ENPP_Amplifier"
	rts
funcENPP_AllocSampleStruct
	DPRINT "ENPP_AllocSampleStruct"
	rts
funcENPP_NewLoadFile2
	DPRINT "ENPP_NewLoadFile2"
	rts
funcENPP_MakeDirCorrect
	DPRINT "ENPP_MakeDirCorrect"
	rts
funcENPP_TestAufHide
	DPRINT "ENPP_TestAufHide"
	rts
funcENPP_CopyMemQuick
	DPRINT "ENPP_CopyMemQuick"
	rts
funcENPP_GetPassword
	DPRINT "ENPP_GetPassword"
	rts
funcENPP_StringCopy2
	DPRINT "ENPP_StringCopy2"
	rts
funcENPP_ScreenToFront
	DPRINT "ENPP_ScreenToFront"
	rts
funcENPP_WindowToFront
	DPRINT "ENPP_WindowToFront"
	rts
funcENPP_StartInterrupt
	DPRINT "ENPP_StartInterrupt"
	rts
funcENPP_StopInterrupt
	DPRINT "ENPP_StopInterrupt"
	rts
funcENPP_CutSuffix
	DPRINT "ENPP_CutSuffix"
	rts
funcENPP_SaveMem
	DPRINT "ENPP_SaveMem"
	rts
funcENPP_FileReq
	DPRINT "ENPP_FileReq"
	rts
funcENPP_TextRequest
	DPRINT "ENPP_TextRequest"
	rts
funcENPP_LoadExecutable
	DPRINT "ENPP_LoadExecutable"
	rts
funcENPP_NewLoadFile
	DPRINT "ENPP_NewLoadFile"
	rts
funcENPP_ScrollText
	DPRINT "ENPP_ScrollText"
	rts
funcENPP_LoadPlConfig
	DPRINT "ENPP_LoadPlConfig"
	rts
funcENPP_SavePlConfig
	DPRINT "ENPP_SavePlConfig"
	rts
funcENPP_FindTag
	DPRINT "ENPP_FindTag"
	rts
funcENPP_FindAuthor
	DPRINT "ENPP_FindAuthor"
	rts
funcENPP_Hexdez
	DPRINT "ENPP_Hexdez"
	rts
funcENPP_TypeText
	DPRINT "ENPP_TypeText"
	rts
funcENPP_ModuleRestore
	DPRINT "ENPP_ModuleRestore"
	rts
funcENPP_StringCopy
	DPRINT "ENPP_StringCopy"
	rts
funcENPP_CalcStringSize
	DPRINT "ENPP_CalcStringSize"
	rts
funcENPP_StringCMP
	DPRINT "ENPP_StringCMP"
	rts
funcENPP_TestAbortGadget
	DPRINT "ENPP_TestAbortGadget"
	rts
funcENPP_GetEPNrfromMessage
	DPRINT "ENPP_GetEPNrfromMessage"
	rts
funcENPP_InitDisplay
	DPRINT "ENPP_InitDisplay"
	rts
funcENPP_FillDisplay
	DPRINT "ENPP_FillDisplay"
	rts
funcENPP_RemoveDisplay
	DPRINT "ENPP_RemoveDisplay"
	rts
funcENPP_GetLocaleString
	DPRINT "ENPP_GetLocaleString"
	rts
funcENPP_SetWaitPointer
	DPRINT "ENPP_SetWaitPointer"
	rts
funcENPP_ClearWaitPointer
	DPRINT "ENPP_ClearWaitPointer"
	rts
funcENPP_OpenCatalog
	DPRINT "ENPP_OpenCatalog"
	rts
funcENPP_CloseCatalog
	DPRINT "ENPP_CloseCatalog"
	rts
funcENPP_RawToFormat
	DPRINT "ENPP_RawToFormat"
	rts
funcENPP_FindAmplifier
	DPRINT "ENPP_FindAmplifier"
	rts
funcENPP_UserCallup5
	DPRINT "ENPP_UserCallup5"
	rts
funcENPP_GetLoadListData
	DPRINT "ENPP_GetLoadListData"
	rts
funcENPP_SetListData
	DPRINT "ENPP_SetListData"
	rts
funcENPP_GetHardwareType
	DPRINT "ENPP_GetHardwareType"
	rts
 else 
funcENPP_Amplifier
funcENPP_AllocSampleStruct
funcENPP_NewLoadFile2
funcENPP_MakeDirCorrect
funcENPP_TestAufHide
funcENPP_CopyMemQuick
funcENPP_GetPassword
funcENPP_StringCopy2
funcENPP_ScreenToFront
funcENPP_WindowToFront
funcENPP_StartInterrupt
funcENPP_StopInterrupt
funcENPP_CutSuffix
funcENPP_SaveMem
funcENPP_FileReq
funcENPP_TextRequest
funcENPP_LoadExecutable
funcENPP_NewLoadFile
funcENPP_ScrollText
funcENPP_LoadPlConfig
funcENPP_SavePlConfig
funcENPP_FindTag
funcENPP_FindAuthor
funcENPP_Hexdez
funcENPP_TypeText
funcENPP_ModuleRestore
funcENPP_StringCopy
funcENPP_CalcStringSize
funcENPP_StringCMP
funcENPP_TestAbortGadget
funcENPP_GetEPNrfromMessage
funcENPP_InitDisplay
funcENPP_FillDisplay
funcENPP_RemoveDisplay
funcENPP_GetLocaleString
funcENPP_SetWaitPointer
funcENPP_ClearWaitPointer
funcENPP_OpenCatalog
funcENPP_CloseCatalog
funcENPP_RawToFormat
funcENPP_FindAmplifier
funcENPP_UserCallup5
funcENPP_GetLoadListData
funcENPP_SetListData
funcENPP_GetHardwareType
	rts
 endif

* NotePlayer implementation from EaglePlayer sources
deliNotePlayer
	tst.l	d0
	bne.b 	.DT_NotePlayer
	rts
.DT_NotePlayer:	

		;movem.l	a4-a6,-(a7)
		;move.l	PufferAdr(pc),a5
		;move.l	DT_NoteStruct(a5),d0
		;beq.w	.Return
		move.l	d0,a4
		move.l	4(a4),d7	;Flags
				
		move.l	(a4),d0
		beq.w	.Return
		move.l	d0,a4

		*--------- neue Note (= DMA off) ---------*
		move.l	a4,a0
		moveq	#4-1,d2
		moveq	#0,d1
		moveq	#1,d3
.pass1		move.b	11(a0),d0
		and.b	#2,d0		;NCHF_Sample
		beq.s	.skip
		or.l	d3,d1		;DMA Mask
.skip		lsl.l	#1,d3
		move.l	(a0),d0
		beq.s	.Last1
		move.l	d0,a0		*add #NoteStruct1-NoteStruct0,a0
		dbf	d2,.pass1
.Last1:
		tst.l	d1
		beq.s	.nostopDMA
		moveq	#0,d0		;D0.w neg=enable ; 0/pos=disable
					;D1 = Maske (LONG !!)
		jsr	ENPP_DMAMask(a5)
		moveq	#0,d0		;D0.w neg=enable ; 0/pos=disable
.nostopDMA:	;move.l	d1,-(a7)
		move.l	d1,d6
	
		*---------- Neue Note setzen -------------*
		move.l	a4,a0
		moveq	#4-1,d2
		moveq	#0,d1
.pass2		move.b	11(a0),d0
		and.b	#2,d0				;NCHF_Sample
		beq.s	.skip2

		move.l	$10(A0),d0			;SampleStart
		jsr	ENPP_PokeAdr(A5)

		moveq	#0,d0
		move.w	nch_SampleLength(a0),d0
		btst	#4,d7
		bne.s	.pokeword1
		move.l	nch_SampleLength(A0),d0		;NCH_SampleLength ;SampleLen
		lsr.l	#1,d0				;Bytes -> Words
.pokeword1:
		jsr	ENPP_PokeLen(a5)
.skip2:		addq	#1,d1
		move.l	(a0),d0
		beq.s	.Last2
		move.l	d0,a0		;add #NoteStruct1-NoteStruct0,a0
		dbf	d2,.pass2
.Last2:

		*-------- Volume/Period neu setzen -------*
		move.l	a4,a0
		moveq	#4-1,d2
		moveq	#0,d1
.pass3
		move.b	11(a0),d0
		and.b	#$10,d0				;NCHF_Volume
		beq.s	.skip3

		move	nch_Volume(a0),d0			;Volume
		jsr	ENPP_PokeVol(a5)
.skip3:		move.b	11(a0),d0
		and.b	#8,d0				;NCHF_Frequency
		beq.s	.skip4

; Only Amiga periods supported in Hippo

;		moveq	#0,d0
;		move.w	$20(A0),d0			;Period (or Frequency)
;		btst	#2,d7
;		bne.s	.extper				;4*Period ?
;		btst	#1,d7				
;		bne.s	.per				;1*Period ?
;							;Frequenz in Period umrechnen
;		moveq	#0,d0
;		move.l	$20(a0),d3			;Frequenz
;		beq	.per				;== 0 ? -> weiter
;		lsr.l	#1,d3
;		move.l	#3546895/2,d0		;Amiga Audiorate
;		divu	d3,d0			;
;		and.l	#$ffff,d0
;		bra.s	.per
;.extper
;		lsr	#2,d0				;noch ersetzen durch DirektWrite bei 4*Per
;.per
		move.w	nch_Frequency(A0),d0		;Period (or Frequency)
		jsr	ENPP_PokePer(a5)
.skip4:		addq	#1,d1
		move.l	(a0),d0
		beq.s	.Last3
		move.l	d0,a0		;add.w #NoteStruct1-NoteStruct0,a0
		dbf	d2,.pass3
.Last3:

		*----- DMA starten (wenn erforderlich) ----*
		;move.l	(a7)+,d1
		move.l	d6,d1
		tst.l	d1
		beq.s	.NostartDMA
		move	#$8000,d0	;D0.w neg=enable ; 0/pos=disable
					;D1 = Maske (LONG !!)
		jsr	ENPP_DMAMask(a5)

		*------ Repeatadr/Repeatlen poken --------*
.NostartDMA:	move.l	a4,a0
		moveq	#4-1,d2
		moveq	#0,d1
.pass4		move.b	11(a0),d0
		and.b	#4!32!64,d0			;NCHF_Repeat
		beq.s	.skip5

		move.l	nch_RepeatStart(a0),d0		;RepeatStart
		jsr	ENPP_PokeAdr(A5)

		moveq	#0,d0
		move.w	nch_RepeatLength(a0),d0		;Repeatlen
		btst	#4,d7
		bne.s	.pokeword2
		move.l	nch_RepeatLength(A0),d0		;NCH_SampleLength ;SampleLen
		lsr.l	#1,d0				;Bytes -> Words
.pokeword2:
		jsr	ENPP_PokeLen(a5)
.skip5:
		clr.b	11(a0)
		addq	#1,d1
		move.l	(a0),d0
		beq.s	.Last
		move.l	d0,a0		*add #NoteStruct1-NoteStruct0,a0
		dbf	d2,.pass4
.Last:

.Return:
;		jsr	ENPP_Amplifier(a5)

		*moveq	#0,d1
		*moveq	#0,d0
		;movem.l	(a7)+,a4-a6
		rts

deliModuleChange
	pushm	all
	DPRINT	"deliModuleChange"
 if DEBUG
	move.l	EPG_ARG1(a5),d0 
	move.l	EPG_ARG2(a5),d1 
	move.l	EPG_ARG3(a5),d2 
	DPRINT	"Start=%lx len=%ld patches=%lx"
	move.l	EPG_ARG4(a5),d0
	move.l	EPG_ARG5(a5),d1 
	DPRINT	"arg4=%lx arg5=%lx"
 endif
	
	; additional args not supported, lol!
	moveq	#1,d0
	cmp.l	EPG_ARG4(a5),d0 
	bne.b	.notSupp
	
	moveq	#-2,d0
	cmp.l	EPG_ARG5(a5),d0 
	bne.b 	.notSupp

	tst.l	EPG_ARG1(a5)
	beq.b	.notSupp

	tst.l	EPG_ARG3(a5)
	beq.b	.notSupp

	tst.l	EPG_ARG2(a5)
	beq.b	.notSupp

	* Data to patch
	move.l	EPG_ARG1(a5),a0
	* PatchTable 
	move.l	EPG_ARG3(a5),a1 
	* Length of data to patch
	move.l 	EPG_ARG2(a5),d1 
	
	* Keep within data limits
	move.l	var_b+modulelength,d2
	cmp.l	d2,d1
	blo.b	.ok
	move.l	d2,d1
	DPRINT	"capped"
.ok

	bsr.b 	.patch
	popm	all
	bra.w	funcENPP_ClearCache
	
.notSupp
	DPRINT	"Unsupported params!"
	rts

* in:
*  a1 = patch table
*  a0 = data
*  d1 = len
.patch
	* End bound is at a4
	lea	(a0,d1.l),a4
	* PatchTable start at d1
	move.l	a1,d1
.loop
	* find from a3 to a4
	move.l	a0,a3
	* Get code to find
	move.l	d1,a2
	add	(a1),a2
.findCode
	* read data word
	move	(a3),d7
	* check bounds
	cmp.l	a4,a3
	bhs.b	.notFound
	* see if the 1st word is found here
	cmp	(a2),d7
	beq.b	.found
.notF	
	* continue search from the next word 
	addq	#2,a3
	bra.b	.findCode

.found
	* compare the rest
	* get length in words minus one
	move	2(a1),d6
	* data to search from
	move.l	a3,a6
	* what to search
	move.l	a2,a5
.cmp	cmpm.w	(a5)+,(a6)+
	bne.b	.notF
	dbf	d6,.cmp
	* Found correct data at a3
	* apply patch
	
	* patch address relative to patch table start
	move.l	d1,a5
	add	4(a1),a5
	* length of the code to overwrite with the patch
	move	2(a1),d6
; JSR x = $4eB9 xxxx xxxx
; NOP   = $4e71
	* write "jsr <patch address>"
	move	#$4eb9,(a3)+
	move.l	a5,(a3)+
	* that was three words
	subq	#3,d6	
	bmi.b	.NoNop
	* fill the rest with NOPs
.nopFill	
	move	#$4e71,(a3)+
	dbf	d6,.nopFill
.NoNop	
	* try to apply patch again, fixes Mark Cooksey
	bra.b	.loop
.notFound
	* next patch
	addq	#6,a1
	tst	(a1)
	bne.b	.loop
	rts
	

* Maps some EP flags into hippo flags
* in:
*    d0 = EPF_Flags
deliHandleFlags
	move.l	playerbase(a5),a0
	move 	p_liput(a0),d1

	bclr	#pb_end,d1
	btst	#EPF_Songend,d0 
	beq.b 	.1
	bset	#pb_end,d1
.1	
	bclr	#pb_song,d1
	btst	#EPF_NextSong,d0
	beq.b 	.2
	bset	#pb_song,d1
.2
	bclr	#pb_volume,d1
	btst	#EPF_Volume,d0
	beq.b 	.3
	bset	#pb_volume,d1
.3
;	bclr	#pb_kelauseteen,d1
;	btst	#EPF_NextPatt,d0
;	beq.b 	.4
;	bset	#pb_kelauseteen,d1
;.4
;	bclr	#pb_kelaustaakse,d1
;	btst	#EPF_PrevPatt,d0
;	beq.b 	.5
;	bset	#pb_kelaustaakse,d1
;.5
	move	d1,p_liput(a0)
	rts



 if DEBUG
deliShowTags
	move.l	deliPlayer(a5),a0
	move.l	16(a0),a0
.tloop
	movem.l	(a0)+,d0/d1

	move.l	d0,d2
	sub.l	#DTP_TagBase,d2
	bmi.b	.next
	lsl.l	#2,d2
	lea	tagsTable(pc),a1
	add.l	d2,a1

	cmp.l	#tagsTableEnd,a1
	blo.b 	.okTag
.next
	move.l	d0,d2
	sub.l	#EP_TagBase,d2
	bmi.b	.unknown
	lsl.l	#2,d2
	lea	tagsTable2(pc),a1
	add.l	d2,a1
	
	cmp.l	#tagsTable2,a1
	bhs.b	.okTag
.unknown
	DPRINT  "Tag? %lx: %lx"
	bra.b	.oddTag
.okTag
	move.l	d1,d2
	move.l	(a1),d1
	DPRINT  "Tag %lx %s: %lx"
.oddTag
	tst.l	(a0) 
	bne.b	.tloop
	rts

tagsTable
 dc.l EDTP_InternalPlayer
 dc.l EDTP_CustomPlayer 
 dc.l EDTP_RequestDTVersion
 dc.l EDTP_RequestKickVersion
 dc.l EDTP_PlayerVersion
 dc.l EDTP_PlayerName   
 dc.l EDTP_Creator    	
 dc.l EDTP_Check1   
 dc.l EDTP_Check2   
 dc.l EDTP_ExtLoad    	
 dc.l EDTP_Interrupt    
 dc.l EDTP_Stop   	 
 dc.l EDTP_Config   	
 dc.l EDTP_UserConfig   
 dc.l EDTP_SubSongRange 
 dc.l EDTP_InitPlayer   
 dc.l EDTP_EndPlayer    
 dc.l EDTP_InitSound    
 dc.l EDTP_EndSound   	
 dc.l EDTP_StartInt   	
 dc.l EDTP_StopInt    	
 dc.l EDTP_Volume   	
 dc.l EDTP_Balance    	
 dc.l EDTP_Faster   	
 dc.l EDTP_Slower   
 dc.l EDTP_NextPatt   
 dc.l EDTP_PrevPatt   
 dc.l EDTP_NextSong   	
 dc.l EDTP_PrevSong   
 dc.l EDTP_SubSongTest  
 dc.l EDTP_NewSubSongRange
 dc.l EDTP_DeliBase  	
 dc.l EDTP_Flags   	
 dc.l EDTP_CheckLen   	
 dc.l EDTP_Description  
 dc.l EDTP_Decrunch   	
 dc.l EDTP_Convert    	
 dc.l EDTP_NotePlayer   
 dc.l EDTP_NoteStruct   
 dc.l EDTP_NoteInfo   	
 dc.l EDTP_NoteSignal   
 dc.l EDTP_Process    	
 dc.l EDTP_Priority   	
 dc.l EDTP_StackSize    
 dc.l EDTP_MsgPort    	
 dc.l EDTP_Appear   	
 dc.l EDTP_Disappear   	
 dc.l EDTP_ModuleName   
 dc.l EDTP_FormatName   
 dc.l EDTP_AuthorName   
 dc.l EDTP_InitNote  
 dc.l EDTP_NoteAllocMem
 dc.l EDTP_NoteFreeMem
 dc.l EDTP_PlayerInfo
 dc.l EDTP_Patterns
 dc.l EDTP_Duration
 dc.l EDTP_SampleData
 dc.l EDTP_MiscText

tagsTableEnd
 
tagsTable2
	dc.l EEP_Get_ModuleInfo	
	dc.l EEP_Free_ModuleInfo	
	dc.l EEP_Voices		
	dc.l EEP_SampleInit		
	dc.l EEP_SampleEnd		
	dc.l EEP_Save
	dc.l EEP_ModuleChange		
	dc.l EEP_ModuleRestore	
	dc.l EEP_StructInit		
	dc.l EEP_StructEnd		
	dc.l EEP_LoadPlConfig		
	dc.l EEP_SavePlConfig		
	dc.l EEP_GetPositionNr	
	dc.l EEP_SetSpeed		
	dc.l EEP_Flags		
	dc.l EEP_KickVersion		
	dc.l EEP_PlayerVersion	
	dc.l EEP_CheckModule		
	dc.l EEP_EjectPlayer
	dc.l EEP_Date			
	dc.l EEP_Check3
	dc.l EEP_SaveAsPT		
	dc.l EEP_NewModuleInfo	
	dc.l EEP_FreeExtLoad
	dc.l EEP_PlaySample		
	dc.l EEP_PatternInit		
	dc.l EEP_PatternEnd		
	dc.l EEP_Check4
	dc.l EEP_Check5
	dc.l EEP_Check6
	dc.l EEP_CreatorLNr
	dc.l EEP_PlayerNameLNr
	dc.l EEP_PlayerInfo		
	dc.l EEP_PlaySampleInit
	dc.l EEP_PlaySampleEnd
	dc.l EEP_InitAmplifier	
	dc.l EEP_CheckSegment
	dc.l EEP_Show
	dc.l EEP_Hide
	dc.l EEP_LocaleTable
	dc.l EEP_Helpnodename
	dc.l EEP_AttnFlags
	dc.l EEP_EagleBase
	dc.l EEP_Check7		
	dc.l EEP_Check8		
	dc.l EEP_SetPlayFrequency
	dc.l EEP_SamplePlayer
tagsTable2End

EDTP_InternalPlayer   	dc.b "DTP_InternalPlayer",0 ; obsolete
EDTP_CustomPlayer   	dc.b "DTP_CustomPlayer",0 ; player is a customplayer
EDTP_RequestDTVersion   	dc.b "DTP_RequestDTVersion",0 ; minimum DeliTracker version needed
EDTP_RequestKickVersion   	dc.b "DTP_RequestKickVersion",0 ; minimum KickStart version needed
EDTP_PlayerVersion   	dc.b "DTP_PlayerVersion",0 ; actual player version & revision
EDTP_PlayerName   	dc.b "DTP_PlayerName",0 ; name of this player
EDTP_Creator    	dc.b "DTP_Creator",0 ; misc string
EDTP_Check1   	dc.b "DTP_Check1",0 ; Check Format before loading
EDTP_Check2   	dc.b "DTP_Check2",0 ; Check Format after file is loaded
EDTP_ExtLoad    	dc.b "DTP_ExtLoad",0 ; Load additional files
EDTP_Interrupt    	dc.b "DTP_Interrupt",0 ; Interrupt routine
EDTP_Stop   	dc.b "DTP_Stop",0 ; Clear Patterncounter
EDTP_Config   	dc.b "DTP_Config",0 ; Config Player
EDTP_UserConfig   	dc.b "DTP_UserConfig",0 ; User-Configroutine
EDTP_SubSongRange   	dc.b "DTP_SubSongRange",0 ; Get min&max subsong number
EDTP_InitPlayer   	dc.b "DTP_InitPlayer",0 ; Initialisize the Player
EDTP_EndPlayer    	dc.b "DTP_EndPlayer",0 ; Player clean up
EDTP_InitSound    	dc.b "DTP_InitSound",0 ; Soundinitialisation routine
EDTP_EndSound   	dc.b "DTP_EndSound",0 ; End sound
EDTP_StartInt   	dc.b "DTP_StartInt",0 ; Start interrupt
EDTP_StopInt    	dc.b "DTP_StopInt",0 ; Stop interrupt
EDTP_Volume   	dc.b "DTP_Volume",0 ; Set Volume
EDTP_Balance    	dc.b "DTP_Balance",0 ; Set Balance
EDTP_Faster   	dc.b "DTP_Faster",0 ; Incease playspeed
EDTP_Slower   	dc.b "DTP_Slower",0 ; Decrease playspeed
EDTP_NextPatt   	dc.b "DTP_NextPatt",0 ; Jump to next pattern
EDTP_PrevPatt   	dc.b "DTP_PrevPatt",0 ; Jump to previous pattern
EDTP_NextSong   	dc.b "DTP_NextSong",0 ; Play next subsong
EDTP_PrevSong   	dc.b "DTP_PrevSong",0 ; Play previous subsong
EDTP_SubSongTest   	dc.b "DTP_SubSongTest",0 ; Test, if given subsong is vaild
EDTP_NewSubSongRange   	dc.b "DTP_NewSubSongRange",0 ; enhanced replacement for EDTP_SubSongRange
EDTP_DeliBase  	dc.b "DTP_DeliBase",0 ; the address of a pointer where DT
EDTP_Flags   	dc.b "DTP_Flags",0 ; misc Flags (see below)
EDTP_CheckLen   	dc.b "DTP_CheckLen",0 ; Length of the Check Code
EDTP_Description   	dc.b "DTP_Description",0 ; misc string
EDTP_Decrunch   	dc.b "DTP_Decrunch",0 ; pointer to Decrunch Code
EDTP_Convert    	dc.b "DTP_Convert",0 ; pointer to Converter Code
EDTP_NotePlayer   	dc.b "DTP_NotePlayer",0 ; pointer to a NotePlayer Structure
EDTP_NoteStruct   	dc.b "DTP_NoteStruct",0 ; the address of a pointer to the
EDTP_NoteInfo   	dc.b "DTP_NoteInfo",0 ; a pointer where DT stores a pointer
EDTP_NoteSignal   	dc.b "DTP_NoteSignal",0 ; pointer to NoteSignal code
EDTP_Process    	dc.b "DTP_Process",0 ; pointer to process entry code
EDTP_Priority   	dc.b "DTP_Priority",0 ; priority of the process
EDTP_StackSize    	dc.b "DTP_StackSize",0 ; stack size of the process
EDTP_MsgPort    	dc.b "DTP_MsgPort",0 ; a pointer where DT stores a pointer
EDTP_Appear   	dc.b "DTP_Appear",0 ; open your window, if you can
EDTP_Disappear   	dc.b "DTP_Disappear",0 ; go dormant
EDTP_ModuleName   	dc.b "DTP_ModuleName",0 ; get the name of the current module
EDTP_FormatName   	dc.b "DTP_FormatName",0 ; get the name of the module format
EDTP_AuthorName   	dc.b "DTP_AuthorName",0 ; not implemented yet
EDTP_InitNote   	dc.b "DTP_InitNote",0 ; NoteStruct initialization
EDTP_NoteAllocMem dc.b "DTP_NoteAllocMem",0
EDTP_NoteFreeMem dc.b "DTP_NoteFreeMem",0
EDTP_PlayerInfo dc.b "DTP_PlayerInfo",0
EDTP_Patterns dc.b "DTP_Patterns",0
EDTP_Duration dc.b "DTP_Duration",0
EDTP_SampleData dc.b "DTP_SampleData",0
EDTP_MiscText dc.b "DTP_MiscText",0

EEP_Get_ModuleInfo	dc.b "EP_Get_ModuleInfo",0
EEP_Free_ModuleInfo	dc.b "EP_Free_ModuleInfo",0
EEP_Voices			dc.b "EP_Voices",0
EEP_SampleInit		dc.b "EP_SampleInit",0
EEP_SampleEnd		dc.b "EP_SampleEnd",0
EEP_Save	    	dc.b "EP_Save",0
EEP_ModuleChange	dc.b "EP_ModuleChange",0
EEP_ModuleRestore	dc.b "EP_ModuleRestore",0
EEP_StructInit		dc.b "EP_StructInit",0
EEP_StructEnd		dc.b "EP_StructEnd",0
EEP_LoadPlConfig	dc.b "EP_LoadPlConfig",0
EEP_SavePlConfig	dc.b "EP_SavePlConfig",0
EEP_GetPositionNr	dc.b "EP_GetPositionNr",0
EEP_SetSpeed		dc.b "EP_SetSpeed",0
EEP_Flags		    dc.b "EP_Flags",0
EEP_KickVersion		dc.b "EP_KickVersion",0
EEP_PlayerVersion	dc.b "EP_PlayerVersion",0
EEP_CheckModule		dc.b "EP_CheckModule",0
EEP_EjectPlayer		dc.b "EP_EjectPlayer",0
EEP_Date		    dc.b "EP_Date",0
EEP_Check3		    dc.b "EP_Check3",0
EEP_SaveAsPT		dc.b "EP_SaveAsPT",0
EEP_NewModuleInfo	dc.b "EP_NewModuleInfo",0
EEP_FreeExtLoad		dc.b "EP_FreeExtLoad",0
EEP_PlaySample		dc.b "EP_PlaySample",0
EEP_PatternInit		dc.b "EP_PatternInit",0
EEP_PatternEnd		dc.b "EP_PatternEnd",0
EEP_Check4	     	dc.b "EP_Check4",0
EEP_Check5		    dc.b "EP_Check5",0
EEP_Check6		    dc.b "EP_Check6",0
EEP_CreatorLNr		dc.b "EP_CreatorLNr",0
EEP_PlayerNameLNr	dc.b "EP_PlayerNameLNr",0
EEP_PlayerInfo		dc.b "EP_PlayerInfo",0
EEP_PlaySampleInit	dc.b "EP_PlaySampleInit",0
EEP_PlaySampleEnd	dc.b "EP_PlaySampleEnd",0
EEP_InitAmplifier	dc.b "EP_InitAmplifier",0
EEP_CheckSegment	dc.b "EP_CheckSegment",0
EEP_Show	     	dc.b "EP_Show",0
EEP_Hide		    dc.b "EP_Hide",0
EEP_LocaleTable		dc.b "EP_LocaleTable",0
EEP_Helpnodename	dc.b "EP_Helpnodename",0
EEP_AttnFlags		dc.b "EP_AttnFlags",0
EEP_EagleBase		dc.b "EP_EagleBase",0
EEP_Check7	    	dc.b "EP_Check7",0
EEP_Check8		    dc.b "EP_Check8",0
EEP_SetPlayFrequency dc.b "EP_SetPlayFrequency",0
EEP_SamplePlayer    dc.b "EP_SamplePlayer",0                  
 even

deliShowFlags
	move.l	#EP_Flags,d0
	bsr.w	deliGetTag
	beq.w	.noFlags
	btst	#EPF_Songend,d0
	beq.b	.f10
	DPRINT	"EPF_Songend"
.f10
	btst	#EPF_Restart,d0
	beq.b	.f11
	DPRINT	"EPF_Restart"
.f11
	btst	#EPF_Disable,d0
	beq.b	.f12
	DPRINT	"EPF_Disable"
.f12
	btst	#EPF_NextSong,d0
	beq.b	.f13
	DPRINT	"EPF_NextSong"
.f13
	btst	#EPF_PrevSong,d0
	beq.b	.f14 
	DPRINT	"EPF_PrevSong"
.f14 
	btst	#EPF_NextPatt,d0
	beq.b	.f15
	DPRINT	"EPF_PrevPatt"
.f15 
	btst	#EPF_Volume,d0
	beq.b	.f16
	DPRINT	"EPF_Volume"
.f16 
	btst	#EPF_Balance,d0
	beq.b	.f17
	DPRINT	"EPF_Balance"
.f17 
	btst	#EPF_Voices,d0
	beq.b	.f18
	DPRINT	"EPF_Voices"
.f18 
	btst	#EPF_Save,d0
	beq.b	.f19
	DPRINT	"EPF_Save"
.f19
	btst	#EPF_Analyzer,d0
	beq.b	.f20
	DPRINT	"EPF_Analyzer"
.f20
	btst	#EPF_ModuleInfo,d0
	beq.b	.f21
	DPRINT	"EPF_ModuleInfo"
.f21
	btst	#EPF_SampleInfo,d0
	beq.b	.f22 
	DPRINT	"EPF_SampleInfo"
.f22 
	btst	#EPF_Packable,d0
	beq.b	.f23
	DPRINT	"EPF_Packable"
.f23 
	btst	#EPF_InternalUPSStructure,d0
	beq.b	.f24
	DPRINT	"EPF_InternalUPSStructure"
.f24 
	btst	#EPF_RestartSong,d0
	beq.b	.f25
	DPRINT	"EPF_RestartSong"
.f25 
	btst	#EPF_LoadFast,d0
	beq.b	.f26
	DPRINT	"EPF_LoadFast"
.f26 
	btst	#EPF_EPAudioAlloc,d0
	beq.b	.f27
	DPRINT	"EPF_EPAudioAlloc"
.f27 
	btst	#EPF_VolBalVoi,d0
	beq.b	.f28
	DPRINT	"EPF_VolBalVoi"
.f28 
	btst	#EPF_CalcDuration,d0
	beq.b	.f29
	DPRINT	"EPF_CalcDuration"
.f29 
	 
.noFlags
	rts 

deliShowNoteStruct
	move.l	deliStoredNoteStruct(a5),d0
	beq.w 	.x

	DPRINT	"NoteStruct: %lx"

	move.l	nst_MaxFrequency(a0),d0 
	DPRINT	"MaxFreq: %ld"
	moveq	#0,d0
	move	nst_MaxVolume(a0),d0 
	DPRINT	"MaxVol: %ld"

	move.l	nst_Flags(a0),d1 
	move.l	d1,d0 
	DPRINT	"Flags: %lx"
	
	moveq	#0,d0
	btst	#NSTB_Period,d1
	sne	d0
	DPRINT	"NSTB_Period: %lx"

	btst	#NSTB_ExtPeriod,d1
	sne	d0
	DPRINT	"NSTB_ExtPeriod: %lx"

	btst	#NSTB_NTSCTiming,d1
	sne	d0
	DPRINT	"NSTB_NTSCTiming: %lx"

	btst	#NSTB_EvenLength,d1
	sne	d0
	DPRINT	"NSTB_EvenLength %lx"

	btst	#NSTB_AllRepeats,d1
	sne	d0
	DPRINT	"NSTB_AllRepeats %lx"

	btst	#NSTB_Reverse,d1
	sne	d0
	DPRINT	"NSTB_Reverse %lx"

	btst	#NSTB_Signed,d1
	sne	d0
	DPRINT	"NSTB_Signed %lx"

	btst	#NSTB_Unsigned,d1
	sne	d0
	DPRINT	"NSTB_Unsigned %lx"

	btst	#NSTB_Ulaw,d1
	sne	d0
	DPRINT	"NSTB_Ulaw %lx"

	btst	#NSTB_Alaw,d1
	sne	d0
	DPRINT	"NSTB_Alaw %lx"

	btst	#NSTB_Float,d1
	sne	d0
	DPRINT	"NSTB_Float %lx"

	btst	#NSTB_7Bit,d1
	sne	d0
	DPRINT	"NSTB_7Bit %lx"

	btst	#NSTB_8Bit,d1
	sne	d0
	DPRINT	"NSTB_8Bit %lx"

	btst	#NSTB_16Bit,d1
	sne	d0
	DPRINT	"NSTB_16Bit %lx"

	btst	#NSTB_24Bit,d1
	sne	d0
	DPRINT	"NSTB_24Bit %lx"

	btst	#NSTB_32Bit,d1
	sne	d0
	DPRINT	"NSTB_32Bit %lx"

	btst	#NSTB_64Bit,d1
	sne	d0
	DPRINT	"NSTB_64Bit %lx"

.x
	rts


 endif

****************************************************************************
*
* File load and save utilities
*
***************************************************************************

* Loads a file
* in:
*  a0 = file path
* out: 
*  d0 = loaded file address, or NULL if error
*  d1 = length
plainLoadFile:
	pushm	d2-a6
	moveq	#0,d7

	move.l	_DosBase(a5),a6
	move.l	a0,d1
	move.l	#MODE_OLDFILE,d2
	lob	Open
	move.l	d0,d6
	beq.b	.openErr

	move.l	d6,d1		
	moveq	#0,d2	
	moveq	#1,d3
	lob	Seek
	move.l	d6,d1
	moveq	#0,d2	
	moveq	#1,d3
	lob	Seek
	move.l	d0,d5		* file length
	move.l	d6,d1
	moveq	#0,d2
	moveq	#-1,d3
	lob	Seek			* start of file

	move.l	d5,d0		
	moveq	#MEMF_PUBLIC,d1
	jsr	getmem
	move.l	d0,d7
	beq.b	.noMem

	move.l	d6,d1		* file
	move.l	d7,d2		* destination
	move.l	d5,d3		* pituus
	lob	Read
	* d0 = -1 on error, read bytes otherwise
	tst.l	d0 
	bpl.b 	.ok

	move.l	d7,a0 
	jsr	freemem 
	moveq	#0,d7
.ok

.noMem 
	move.l	d6,d1
	lore 	Dos,Close

.openErr 

	move.l	d7,d0
	move.l  d5,d1
	popm	d2-a6 
	rts

* Saves a file
* in:	
*  a0 = file path
*  a1 = data address
*  d0 = data length
* out: 
*  d0 = Written bytes or -1 if error
plainSaveFile
	pushm	d1-a6
	moveq	#-1,d7
	move.l	a1,d4
	move.l 	d0,d5

	move.l	_DosBase(a5),a6
	move.l	a0,d1
	move.l	#MODE_NEWFILE,d2
	lob	Open
	move.l	d0,d6
	beq.b	.openErr

	move.l	d6,d1	* file
	move.l	d4,d2	* buffer
	move.l	d5,d3  	* len
	lob 	Write
	move.l  d0,d7 

	move.l	d6,d1 
	lob		Close
.openErr 
	move.l	d7,d0
	popm	d1-a6 
	rts

***************************************************************************
*
* Frequency spectrum scope
* Integer FFT
*
***************************************************************************

  ifne FEATURE_SPECTRUMSCOPE
spectrum:

	;incdir
	include	"hippo_fft.s"

; Length of the mixed data, to be passed to FFT
MIX_LENGTH = FFT_LENGTH

; Sample data bytes to be copied. Should be enough so that mixing
; process has enough data, as it interpolates according to current
; channel period. 
; For HIPC.WingsOfDeath (Level 1) this buffer is not long enough
; so either make it larger or do range check using mask.
SAMPLE_LENGTH = MIX_LENGTH*2
SAMPLE_LENGTH_MASK = 255

 if SAMPLE_LENGTH<>256
   fail "Assumed to be 256"
 endif

spectrumInitialize
	SDPRINT	"Spectrum init"

VOLUME_TABLE_LEN = $40*$100*2
MULU_TABLE_LEN = SCOPE_DRAW_AREA_HEIGHT_DEFAULT*2
EXP_TABLE_LEN = SCOPE_DRAW_AREA_HEIGHT_DEFAULT
SINE_TABLE_LEN = 1024*2

SPECTRUM_TOTAL set VOLUME_TABLE_LEN+MULU_TABLE_LEN+EXP_TABLE_LEN*4+SINE_TABLE_LEN
SPECTRUM_TOTAL set SPECTRUM_TOTAL+4*SAMPLE_LENGTH ; bytes
SPECTRUM_TOTAL set SPECTRUM_TOTAL+2*FFT_LENGTH*2  ; words

	clr.b	s_spectrumInitialized(a4)

	move.l	#SPECTRUM_TOTAL,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	jsr	getmem
	move.l	d0,s_spectrumMemory(a4)
	beq.b	.x
	move.l	d0,a0
	move.l	a0,s_spectrumVolumeTable(a4)
	add.l	#VOLUME_TABLE_LEN,a0
	move.l	a0,s_spectrumMuluTable(a4)
	add	#MULU_TABLE_LEN,a0
	move.l	a0,s_spectrumExpTable(a4)
	add	#EXP_TABLE_LEN*4,a0
	move.l	a0,s_spectrumSineTable(a4)
	add	#SINE_TABLE_LEN,a0
	move.l	a0,s_spectrumChannel1(a4)
	add	#SAMPLE_LENGTH,a0
	move.l	a0,s_spectrumChannel2(a4)
	add	#SAMPLE_LENGTH,a0
	move.l	a0,s_spectrumChannel3(a4)
	add	#SAMPLE_LENGTH,a0
	move.l	a0,s_spectrumChannel4(a4)
	add	#SAMPLE_LENGTH,a0
	move.l	a0,s_spectrumMixedData(a4)
	add	#FFT_LENGTH*2,a0
	move.l	a0,s_spectrumImagData(a4)

	bsr.w	prepareSpectrumSineTable
	bsr.b	prepareSpectrumVolumeTable
	bsr.b	prepareSpectrumMuluTable
	bsr.b	prepareSpectrumExpTable

	st	s_spectrumInitialized(a4)
	moveq	#1,d0
	rts
	
.x	SDPRINT "Spectrum init failed"
	moveq	#0,d0
	rts


spectrumUninitialize
	SDPRINT	"Spectrum uninit"
	clr.b	s_spectrumInitialized(a4)
	move.l	s_spectrumMemory(a4),a0
	clr.l	s_spectrumMemory(a4)
	jmp	freemem
	
prepareSpectrumVolumeTable
	move.l	s_spectrumVolumeTable(a4),a0
	moveq	#0,d0
.v
	moveq	#0,d1
.byte
	move	d1,d2
	ext	d2
	muls	d0,d2
	; Here could do some scaling if needed to suit the graph
	move	d2,(a0)+

	addq	#1,d1
	cmp	#256,d1
	bne.b	.byte

	addq	#1,d0
	cmp	#64,d0
	bne.b	.v
	moveq	#1,d0
	rts

; in:
;    d0 = volume
; out:
;    a2 = table
getSpectrumVolumeTable
	mulu	mainvolume(a5),d0
	lsr	#6,d0
	CLAMPVOL d0
	tst	d0
	bne.b	.1
	moveq	#1,d0
.1	subq	#1,d0
	lsl	#8,d0
	add	d0,d0
	move.l	s_spectrumVolumeTable(a4),a2
	add	d0,a2
	rts

prepareSpectrumMuluTable
	move.l	s_spectrumMuluTable(a4),a0
	moveq	#0,d0
	moveq	#SCOPE_DRAW_AREA_HEIGHT_DEFAULT-1,d1
.l	move	d0,(a0)+
	add	#SCOPE_DRAW_AREA_WIDTH_DEFAULT/8,d0
	dbf	d1,.l
	rts


; Creates a table to for mapping FFT magnitudes into dB levels.
; Magnitude for each value would be: sqr(real^2+image^2)
; Maximum value for real or image is 0x7fff.
; The end result is such that low frequencies visually not overpowering
; and the graph is more even between frequencies.

prepareSpectrumExpTable
	move.l	s_spectrumExpTable(a4),a2

	; Do this:
	; local s, i; s = 0; for (i = 0; i < 64; i++, s=s-0.15) print(0x7fff*exp(s));

	move.l	#1000,d0
	lore	FFP,SPFlt
	move.l	d0,d2
	* Adjust exponential curve shape:
	;move.l	#155,d0
	move.l	#160,d0
	lob	SPFlt
	move.l	d2,d1
	lob	SPDiv
	move.l	d0,d5
	
	moveq	#EXP_TABLE_LEN-1,d7
	moveq	#FFP_zero,d6
.loop
	move.l	d6,d0
	lore	MT,SPExp
	move.l 	#FFP_7fff,d1
	lore	FFP,SPMul
	* Squared:
	move.l	d0,d1
	lob	SPMul
	lob	SPFix
	move.l	d0,(a2)+

	move.l	d6,d0
	move.l	d5,d1
	lob	SPSub
	move.l	d0,d6
	dbf	d7,.loop

	move.l	s_spectrumExpTable(a4),a2
	moveq	#EXP_TABLE_LEN-1-1,d7
	* Calculate averages
	addq.l	#4,a2
.loop2
	move.l	(a2),d0
	add.l	-4(a2),d0
	lsr.l	#1,d0
	move.l	d0,-4(a2)
	addq.l	#4,a2
	dbf	d7,.loop2

	* Reverse the table so that loudnessFFT can 
	* use post-increment instead of pre-decrement, which
	* is slower.
	move.l	s_spectrumExpTable(a4),a0
	lea	EXP_TABLE_LEN*4(a0),a1
	moveq	#EXP_TABLE_LEN/2-1,d7
.reverse
	move.l	(a0),d0
	move.l	-(a1),(a0)+
	move.l	d0,(a1)
	dbf	d7,.reverse
	rts
 

; Calculate loudness values for the FFT
;
;in:
;  a0 = result array reals
;  a1 = result array imaginary
;out:
;  a0 = result (overwritten input array)

loudnessFFT
	move.l	s_spectrumExpTable(a4),a3	
	moveq	#FFT_LENGTH/2-1,d7
	move.l	a0,a6
.l1
	* Calculate re^2 + im^2.
	* This is the squared magnitude of the complex value.
	move	(a0)+,d0
	muls	d0,d0
	move	(a1)+,d1
	muls	d1,d1
	add.l	d1,d0

	* Find the slot in the table where the value lands.
	* The index represents the decibel value with range 0..64

* Forward search, loud values are searched first.
* Typically forward search is wasteful since
* on average module loudnesses are on the lower half
* of the search table. For snare/drum hits and similar
* forward search is better, but those happen rarely.
* DMU.ferry_tell is exceptionally loud, for this one
* the forward search is better.

* Reverse search, quiet values are searched first.
* With a few test modules this takes much less steps
* compared to the forward search.
* Test with two mods, loop iteration counts:
* normal count:  1b570b  1c53b9
* reverse count:  cf5af   bed25

* Reverse search is used here by reversing the search table 
* in prepareSpectrumExpTable.

	move.l	a3,a2
	moveq	#EXP_TABLE_LEN-1,d1
	* this loop is may run 4096 times in the worst case
.l2	cmp.l	(a2)+,d0
	* If the 1st cmp succeeds, the loop breaks without
	* d1 decrementing.
	dbls	d1,.l2

	* Use the DBcc counter directly.
	* See if all entries were searched (not likely to happen).
	tst	d1
	bpl.b	.notEnd
	moveq	#0,d1
.notEnd
	move.b	d1,(a6)+

	dbf	d7,.l1
	rts


* Precalculated FFP constants
FFP_2PIper1024 	= $c90fdb39 * 2PI divided by 1024
FFP_7fff 	= $fffe004f
FFP_zero        = 0

* This calculates a 1024 entry sine table with 16-bit
* range.
prepareSpectrumSineTable
	move.l	_FFPBase(a5),d6
	move.l	_MTBase(a5),d5

	move.l	s_spectrumSineTable(a4),a2
 
	* D4 = multiplier 
	* D3 = step
	* D2 = current

	moveq	#FFP_zero,d2
	move.l	#FFP_2PIper1024,d3
	move.l	#FFP_7fff,d4

	move	#1024-1,d7
.loop
	move.l	d2,d0
	move.l	d5,a6
	lob	SPSin
	move.l	d4,d1
	move.l	d6,a6
	lob	SPMul
	lob	SPFix
	* fix_fft uses values shifted by one
	asr.l	#1,d0 
	move	d0,(a2)+

	move.l	d2,d0
	move.l	d3,d1
	lob	SPAdd
	move.l	d0,d2

	dbf	d7,.loop   
	rts

runSpectrumScope
	tst.b	s_spectrumInitialized(a4)
	beq.w	.x

	cmp	#pt_multi,playertype(a5)
	beq.b	.ps3m
	cmp	#pt_sample,playertype(a5)
	beq.b	.sample
	bra.b	.normal

.ps3m
	bsr.w	spectrumGetPS3MSampleData
	bra.b	.go
.sample
	bsr.w	spectrumGetSampleData
	bra.b	.go
.normal
	bsr.w	spectrumCopySamples
* A500 average = 2ms
	bsr.w	spectrumMixSamplesNew
* A500 average = 4ms

.go
	move.l	s_spectrumMixedData(a4),a0
	move.l	s_spectrumSineTable(a4),a2
	bsr.w	windowFFT
* A500 average = 2ms

	move.l	s_spectrumMixedData(a4),a0
	move.l	s_spectrumImagData(a4),a1
	move.l	s_spectrumSineTable(a4),a2
	bsr.w	sampleFFT
* A500 average = 39ms (old: 52ms)

	move.l	s_spectrumMixedData(a4),a0
	move.l	s_spectrumImagData(a4),a1
	bsr.w	loudnessFFT
* A500 average = 8ms

	bsr.w	drawFFT
* A500 average = 1ms

	* Vertical fill
	lore	GFX,OwnBlitter

	move.l	s_draw1(a4),a0
	;addq	#2,a0 * horiz offset
	;moveq	#2,d0 * modulo
	moveq	#0,d0 * modulo
	lea	40(a0),a1 * target is one line below
	lea	$dff000,a2

	lob	WaitBlit
	move.l	a0,$50(a2)	* A
	move.l	a1,$48(a2)	* C
	move.l	a1,$54(a2)	* D
	move	d0,$60(a2)	* C
	move	d0,$64(a2)	* A
	move	d0,$66(a2)	* D
	move.l	#-1,$44(a2) * masks
	move.l	#$0b5a0000,$40(a2)	* D = A not C
	* Height: 65 px
	* Width 19*16 = 304 px
	;move	#65*64+19,$58(a2)
	move	#65*64+20,$58(a2)
	lob	DisownBlitter
	
;	bsr.b	drawScales
	
.x	rts

* Test visualization
 REM
drawScales
	lob	WaitBlit
	move.l	s_draw1(a4),a0
	moveq	#SCOPE_DRAW_AREA_HEIGHT_DEFAULT/2,d0
	mulu	s_scopeDrawAreaModulo(a4),d0
	add.l	d0,a0
	moveq	#SCOPE_DRAW_AREA_WIDTH_DEFAULT/32-1,d0
.l	move.l	#-1,(a0)+
	dbf	d0,.l
	rts
 EREM

spectrumCopySamples
	push	a4

	move.l	a4,a6
	lea	scopeData+scope_ch1(a5),a3
	move.l	s_spectrumChannel1(a6),a4
	bsr.b	.copySample
	lea	scopeData+scope_ch2(a5),a3
	move.l	s_spectrumChannel2(a6),a4
	bsr.b	.copySample
	lea	scopeData+scope_ch3(a5),a3
	move.l	s_spectrumChannel3(a6),a4
	bsr.b	.copySample
	lea	scopeData+scope_ch4(a5),a3
	move.l	s_spectrumChannel4(a6),a4
	bsr.b	.copySample
	pop	a4
	rts

* in
*   a3 = scope channel block
*   a4 = sample data destination buffer
.copySample
	; Destination buffer
	;lea	channelData(a3),a4

	* For clearing data
	moveq	#0,d3
	
	tst	ns_period(a3)
	beq.b	.empty
	tst	ns_tempvol(a3)
	beq.b	.empty

	* Insanity check value
	lea	1024.w,a0

	move.l	ns_start(a3),a1
	cmp.l	a0,a1 * insanity check
	blo.b	.empty
	move.l	ns_loopstart(a3),d1
	cmp.l	a0,d1 * insanity check
	bhs.b	.jolt

.empty
	moveq	#SAMPLE_LENGTH/4/8-1,d1
.c
	move.l	d3,(a4)+
	move.l	d3,(a4)+
	move.l	d3,(a4)+
	move.l	d3,(a4)+
	move.l	d3,(a4)+
	move.l	d3,(a4)+
	move.l	d3,(a4)+
	move.l	d3,(a4)+
	dbf	d1,.c
	rts

.jolt	
	* a1 = sample start
	* d1 = loopstart
	moveq	#0,d5
	move	ns_length(a3),d5	* Sample length in words

	; See if enough data to copy all in one block
	cmp	#SAMPLE_LENGTH/2,d5
	bhs.b	.large

	; sample length 2, ie. empty sample?
	cmp	#2,d5
	bls.b	.empty

	; Small sample, or large sample with not a lot remaining

	moveq	#0,d0
	move	ns_replen(a3),d0

	; this loop is active when there is some data to be copied
	moveq	#SAMPLE_LENGTH/2-1,d7	* words to copy
.small
	; sample word
	; source pointer can be odd
	move.b	(a1)+,(a4)+
	move.b	(a1)+,(a4)+
	
	subq.l	#1,d5			* one word copied, check length
	dbmi	d7,.small

	* Sample data exhausted (d5 = -1), 
	* or buffer full (d7 = -1)
	tst	d7
	bmi.b	.full

	* Continue with loop data
	cmp	#2,d0
	bls.b	.emptyRepeat

	; sample repeat	starts
	; repeat length
	move.l	d0,d5
	; repeat data start
	move.l	d1,a1
	* continue copy 
	bra.b	.small
.full
	rts

.emptyRepeat
	move	d3,(a4)+
	dbf	d7,.emptyRepeat
	rts

.large
	* Check source address evenness
	move.w	a1,d0
	ror.b	#1,d0
	bpl.b	.evenCopy
	moveq	#SAMPLE_LENGTH/16-1,d0
	* copy from odd address
.oddCopy
 rept 16
	move.b	(a1)+,(a4)+
 endr
	dbf	d0,.oddCopy
	rts

* Copy SAMPLE_LENGTH bytes, 256 bytes that is
	if SAMPLE_LENGTH<>256	
		fail 256 assumed here
	endif
* Free: d0-d7, a0,a2,a3 = 44 bytes at a time
.evenCopy
	* 000-044
	movem.l	(a1)+,d0-d7/a0/a2/a3
	movem.l	d0-d7/a0/a2/a3,(a4)
	* 044-088
	movem.l	(a1)+,d0-d7/a0/a2/a3
	movem.l	d0-d7/a0/a2/a3,44(a4)
	* 088-132
	movem.l	(a1)+,d0-d7/a0/a2/a3
	movem.l	d0-d7/a0/a2/a3,44*2(a4)
	* 132-176
	movem.l	(a1)+,d0-d7/a0/a2/a3
	movem.l	d0-d7/a0/a2/a3,44*3(a4)
	* 172-220
	movem.l	(a1)+,d0-d7/a0/a2/a3
	movem.l	d0-d7/a0/a2/a3,44*4(a4)
	* 220-256 (36 bytes)
	movem.l	(a1),d0-d7/a0
	movem.l	d0-d7/a0,44*5(a4)
	rts

; in:
;    d0 = period
; out:
;    d1 = 8+8 fixed point sample skip value ff000000aa, ff = fractions
calcSampleStep
	* sanity check, 100 corresponds to about 35 kHz
	cmp	#100,d0
	bhs.b .1
	moveq	#100,d0
.1
	move.l	clockconstant(a5),d1 * PAL or NTSC clock constant
	divu	d0,d1		* playback frequency in hertz
	ext.l	d1
	lsl.l	#8,d1
	divu	#8000,d1	* resampling destination frequency
	;divu	#16000,d1	* resampling destination frequency
	;divu	#20000,d1	* resampling destination frequency
	;divu	#24000,d1	* resampling destination frequency
	;divu	#28000,d1	* resampling destination frequency
	ext.l	d1
	ror.l	#8,d1

	; 8000 dest frequency means that the FFT scale goes
	; from 0 to 4000.
	rts


 REM ***********
spectrumMixSamples
	lea	scopeData+scope_ch1(a5),a1
	move.l	s_spectrumChannel1(a4),a0
	moveq	#1,d4
	bsr.b	.mixSample

	lea	scopeData+scope_ch2(a5),a1
	move.l	s_spectrumChannel2(a4),a0
	moveq	#0,d4
	bsr.b	.mixSample

	lea	scopeData+scope_ch3(a5),a1
	move.l	s_spectrumChannel3(a4),a0
	moveq	#0,d4
	bsr.b	.mixSample

	lea	scopeData+scope_ch4(a5),a1
	move.l	s_spectrumChannel4(a4),a0
	moveq	#0,d4
	;bsr.b	.mixSample
	;rts

.mixSample
	move	ns_tempvol(a1),d0
	bsr.w	getSpectrumVolumeTable
	; out: a2 = voltab

	move	ns_period(a1),d0
	bsr.b	calcSampleStep
	; result in d1

	move.l	s_spectrumMixedData(a4),a1

	moveq	#0,d6
	moveq	#0,d0
	move	#SAMPLE_LENGTH_MASK,d3
	moveq	#MIX_LENGTH/4-1,d7
	
	* Copy or add?
	tst	d4
	beq.b	.add
.m1
	; move to buffer (first set)
	rept	4
	; sample byte
	moveq	#0,d5
	move.b	(a0,d0.w),d5
	; volume scaled byte
	add	d5,d5
	; copy
	move.w	(a2,d5.w),(a1)+

	; next source sample
	add.l	d1,d0
	addx.w	d6,d0
	endr

	; safety: keep offset within data buffer
	and	d3,d0

	dbf	d7,.m1
	rts
.add
; add to buffer
.m2
	rept	4
	; sample byte
	moveq	#0,d5
	move.b	(a0,d0.w),d5
	; volume scaled byte
	add	d5,d5
	move.w	(a2,d5.w),d4
	; add to mix buffer
	add.w	d4,(a1)+

	; next source sample
	add.l	d1,d0
	addx.w	d6,d0
	endr

	; safety: keep offset within data buffer
	and	d3,d0
	dbf	d7,.m2
	rts
 EREM *****************


* Mix four channels into one for input to the FFT
* Two channels at a time
spectrumMixSamplesNew
	lea	scopeData+scope_ch1(a5),a1
	move	ns_tempvol(a1),d0
	bsr.w	getSpectrumVolumeTable
	move.l	a2,a3
	; a3 = ch1 voltab
	move	ns_period(a1),d0
	bsr.b	calcSampleStep
	move.l	d1,d2
	; d2 = ch1 step

	lea	scopeData+scope_ch2(a5),a1
	move	ns_tempvol(a1),d0
	bsr.w	getSpectrumVolumeTable
	; a2 = ch2 voltab
	move	ns_period(a1),d0
	bsr.b	calcSampleStep
	; d1 = ch2 step

	move.l	s_spectrumChannel1(a4),a0	
	move.l	s_spectrumChannel2(a4),a1	
	move.l	s_spectrumMixedData(a4),a6

	; ch1 pos
	moveq	#0,d0
	; ch2 pos
	moveq	#0,d4
	; addx zero
	moveq	#0,d6

	push	a5
	lea	(SAMPLE_LENGTH_MASK).w,a5
	exg	d1,a5

	moveq	#MIX_LENGTH/2-1,d7
.loop
	rept	2
	moveq	#0,d5
	move.b	(a0,d0.w),d5  ; ch1 byte
	add	d5,d5
	move.w	(a3,d5.w),d5  ; volume scaled byte

	moveq	#0,d3
	move.b	(a1,d4.w),d3 ; ch2 byte
	add	d3,d3
	add.w	(a2,d3.w),d5 ; ch1+ch2
	move	d5,(a6)+     ; to output

	add.l	d2,d0 	; next ch1 byte
	addx.w	d6,d0
	add.l	a5,d4   ; next ch2 byte
	addx.w	d6,d4
	endr

	; Buffer index safety
	and.w	d1,d0
	and.w	d1,d4

	dbf	d7,.loop

	pop	a5

	lea	scopeData+scope_ch3(a5),a1
	move	ns_tempvol(a1),d0
	bsr.w	getSpectrumVolumeTable
	move.l	a2,a3
	; a3 = ch3 voltab
	move	ns_period(a1),d0
	bsr.w	calcSampleStep
	move.l	d1,d2
	; d2 = ch3 step

	lea	scopeData+scope_ch4(a5),a1
	move	ns_tempvol(a1),d0
	bsr.w	getSpectrumVolumeTable
	; a2 = ch4 voltab
	move	ns_period(a1),d0
	bsr.w	calcSampleStep
	; d1 = ch4 step

	move.l	s_spectrumChannel3(a4),a0	
	move.l	s_spectrumChannel4(a4),a1	
	move.l	s_spectrumMixedData(a4),a6

	; ch3 pos
	moveq	#0,d0
	; ch4 pos
	moveq	#0,d4

	push	a5
	lea	(SAMPLE_LENGTH_MASK).w,a5
	exg	d1,a5

	moveq	#MIX_LENGTH/2-1,d7
.loop2
	rept	2
	moveq	#0,d5
	move.b	(a0,d0.w),d5 ; ch3 byte
	add	d5,d5
	move.w	(a3,d5.w),d5

	moveq	#0,d3
	move.b	(a1,d4.w),d3 ; ch4 byte
	add	d3,d3
	add.w	(a2,d3.w),d5  * ch3+ch4
	add	d5,(a6)+      * ch1+ch2+ch3+ch4

	add.l	d2,d0 ; next ch3 sample
	addx.w	d6,d0
	add.l	a5,d4 ; next ch4 sample
	addx.w	d6,d4
	endr
	
	* Safety check for buffer indexes
	and.w	d1,d0
	and.w	d1,d4
	
	dbf	d7,.loop2

	pop	a5
	rts

drawFFT
	; FFT data is here.
	; The other half is mirror of the first.
	move.l	s_spectrumMixedData(a4),a0
	move.l	s_draw1(a4),a1
	move.l	s_spectrumMuluTable(a4),a2

;%11111000 00000000 ror #5
;%00000111 11000000 ror #5
;%00000000 00111110 ror #5
;%11110000 00000001 ror #8
;%00000001 11110000

	; Bitmask to draw with
	move	#%0111100000000000,d6
	; Bitmask to detect word boundary collisions
	move	#%1111100000000000,d5

	; Take the 1st half
	moveq	#FFT_LENGTH/2-1,d7
	* Y-table index
	moveq	#0,d1
.loop
	move.b	(a0)+,d1  * Get value in range 0..64
	add.b	d1,d1     * Word index 0..128
	* Y-address from table
	move	(a2,d1),d0
	* Draw bits
	or.w	d6,(a1,d0)

	* Shift bit mask
	ror.w 	#5,d6
	* Shift also this and see if should continue to following word
	ror.w	#5,d5
	bmi.b	.2
	
	dbf	d7,.loop
.x	rts		

.2
	* Draw data point which is split between words
	subq	#1,d7
	bmi.b	.x

	* Get another value	
	move.b	(a0)+,d1
	add.b	d1,d1
	move	(a2,d1),d0

	* Bits that go into the 2nd byte
	or.b	d6,1(a1,d0)
	* Bits that go into the 3rd
	move	d6,d4
	ror.w	#8,d4
	or.b	d4,2(a1,d0)
	* Moving on to next 16 pixels
	addq.l	#2,a1

	ror.w	#5,d5
	ror.w 	#5,d6
	dbf	d7,.loop
	rts

spectrumGetPS3MSampleData
	move.l	ps3m_playpos(a5),a0
	move.l	(a0),d0
	lsr.l	#8,d0
	move.l	ps3m_buffSizeMask(a5),a0
	move.l	(a0),d1

	move.l	ps3m_buff1(a5),a0
	move.l	(a0),a0
	move.l	ps3m_buff2(a5),a1
	move.l	(a1),a1
	
	move.l	s_spectrumMixedData(a4),a2
	moveq	#FFT_LENGTH-1,d7
.loop
	move.b	(a0,d0.l),d2
	move.b	(a1,d0.l),d3
	ext	d2
	ext	d3
	add	d3,d2
	asl	#4,d2   * scaling!
	move	d2,(a2)+
	addq	#1,d0
	and	d1,d0
	dbf	d7,.loop

	rts

spectrumGetSampleData
	jsr	samples0
	* d5 = follow offset
	* d4 = buffer size mask

	move.l	s_spectrumMixedData(a4),a3
	moveq	#FFT_LENGTH/2-1,d7

	move.l	samplepointer(a5),a1
	move.l	(a1),a1
	
	tst.b	samplestereo(a5)
	bne.b	.stereo

	* mono	
.mloop
	move.b	(a1,d5.l),d2
	ext	d2
	asl	#5,d2 * scale
	move	d2,(a3)+
	
	addq.l	#1,d5
	cmp.l	d4,d5
	bne.b	.1
	moveq	#0,d5
.1
	dbf	d7,.mloop
	rts

.stereo
	move.l	samplepointer2(a5),a2
	move.l	(a2),a2
.sloop
	move.b	(a1,d5.l),d2
	move.b	(a2,d5.l),d3
	ext	d2
	ext	d3
	add	d3,d2
	asl	#4,d2 * scale
	move	d2,(a3)+

	addq.l	#1,d5
	cmp.l	d4,d5
	bne.b	.2
	moveq	#0,d5
.2
	dbf	d7,.sloop
	rts

  endif ; FEATURE_SPECTRUMSCOPE


***************************************************************************
*
* Region and clipping for filebox
*
***************************************************************************

createlistBoxRegion
	bsr.b	disposelistBoxRegion

	lore	GFX,NewRegion
	move.l	d0,listBoxRegion(a5)
	beq.b	.x

	lea	-ra_SIZEOF(sp),sp
	move.l	sp,a1
	moveq	#30+WINX,d0
	moveq	#62+WINY,d1
	move	WINSIZX(a5),d2
	sub	#10,d2

	move	#127+WINY,d3
	tst.b	altbuttonsUse(a5)
	beq.b	.noAlt
	add	#16,d1
	add	#16,d3  
.noAlt
	add	boxy(a5),d3
	add	windowleft(a5),d0
	add	windowtop(a5),d1
	add	windowtop(a5),d3

	; Adjust the end X so that it matches the 
	; markline highlight
	subq	#3,d2
	; Adjust the start x so that font will not bleed outside
	; the markline highlight
	addq	#1+2,d0

	move	d0,ra_MinX(a1)
	move	d1,ra_MinY(a1)
	move	d2,ra_MaxX(a1)
	move	d3,ra_MaxY(a1)

	move.l	listBoxRegion(a5),a0
	lob	OrRectRegion
	lea	ra_SIZEOF(sp),sp
.x	tst.l	d0
	rts


disposelistBoxRegion
	pushm	all
	move.l	listBoxRegion(a5),d0
	beq.b	.x
	clr.l	listBoxRegion(a5)
	move.l	d0,a0
	lore	GFX,DisposeRegion
.x	popm	all
	rts

setListBoxClip
	pushm	all
	tst.l	listBoxRegion(a5)
	beq.b	.x
	move.l	windowbase(a5),a0
	move.l	wd_WLayer(a0),a0
	move.l	listBoxRegion(a5),a1
	lore	Layers,InstallClipRegion
	; d0 = previous clip region or NULL
	move.l	d0,listBoxClipRegion(a5)
	; Out of memory is also possible, this
	; is visible in some flag somewhere.
.x	popm	all
	rts


removeListBoxClip
	move.l	windowbase(a5),a0
	move.l	wd_WLayer(a0),a0
	; Null is ok here:
	move.l	listBoxClipRegion(a5),a1
	lore	Layers,InstallClipRegion
	rts


***************************************************************************
*
* Row button layout
*
***************************************************************************
 ifne FEATURE_HORIZ_RESIZE

; Store the original gadget gg_Widht and gg_LeftEdge 
; for relative layouting later when window size changes.
initializeButtonRowLayout
	lea	row1Gadgets,a0
	bsr.b	.do
	lea	row2Gadgets,a0
;	bsr.b	.do
;	rts
	
.do
.1	tst	(a0)
	beq.b	.2
	move.l	a0,a1
	add	(a0)+,a1
	move	gg_Width(a1),(a0)+
	move	gg_LeftEdge(a1),(a0)
	; Remove left border
	subq	#8,(a0)+
	bra.b	.1
.2
	rts


layoutButtonRow
  if DEBUG
	moveq	#0,d1
	move	winstruc+nw_Width,d1
	move	d1,d0
	; remove left and right borders
	sub	#8+8,d1 
	lsl.l	#8,d1
	; original width without borders
	divu	#264-8-8,d1
	ext.l	d1
	DPRINT	"Layout width=%ld mul=%ld"
  endif

	lea	row1Gadgets,a0
	bsr.b	.do
	lea	row2Gadgets,a0
;	bsr.b	.do
;	rts

.do
.1	tst	(a0)
	beq.b	.2
	move.l	a0,a1
	add	(a0),a1

	moveq	#0,d1
	move	winstruc+nw_Width,d1
	; remove left and right borders
	sub	#8+8,d1 
	lsl.l	#8,d1
	; original width without borders
	divu	#264-8-8,d1
	move.l	d1,d2
	
	mulu	4(a0),d1
	lsr.l	#8,d1
	; add left border
	addq	#8,d1
	move	d1,gg_LeftEdge(a1)

	mulu	2(a0),d2
	lsr.l	#8,d2
	move	d2,gg_Width(a1)

	bsr.b	.centerContent
	addq	#6,a0
	bra.b	.1
.2
	rts

; in:
;   a1 = gadget
.centerContent
	tst.l	gg_GadgetText(a1)
	bne.b	.centerText
	move	gg_Flags(a1),d0
	and	#GFLG_GADGIMAGE,d0
	bne.b	.centerImage
	rts

.centerImage
	move.l	gg_GadgetRender(a1),a2	
	move	gg_Width(a1),d3
	sub	ig_Width(a2),d3
	lsr	#1,d3
	move	d3,ig_LeftEdge(a2)
	rts

.centerText
	push	a0
	move.l	gg_GadgetText(a1),a2

	move.l	it_IText(a2),a0
	move.l	a0,d0
.c	tst.b	(a0)+
	bne.b	.c
	sub.l	d0,a0
	subq	#1,a0
	* string length in d0
	move.l	a0,d0

	; Calculate text lenght in pixels using
	; the current rastport draw modes.
	push	a1
	move.l	rastport(a5),a1
	move.l	it_IText(a2),a0
	lore	GFX,TextLength
	pop	a1

	; center	
	move	gg_Width(a1),d3
	sub	d0,d3
	lsr	#1,d3
	move	d3,it_LeftEdge(a2)
	
	pop	a0
	rts
 endif ; FEATURE




***************************************************************************
*
* Modland, Aminet integration using UHC
*
***************************************************************************

SEARCH_MODLAND = 0
SEARCH_AMINET = 1

modlandSearch
	DPRINT	"modlandSearch"
	moveq	#SEARCH_MODLAND,d7

 ifne FEATURE_UHC_AMINET
	bra.b	remoteSearch
aminetSearch
	DPRINT	"aminetSearch"
	moveq	#SEARCH_AMINET,d7
 endif

* Requests a search pattern from the user,
* then creates an executable shell script to launch
* UHC search using the given search pattern.
* The search result file is imported as a normal modulelist.
*
* in:
*  d7 = remote type enumeration
remoteSearch
	tst.b	uhcAvailable(a5)
	bne.b	.go
	rts
.go
	jsr		lockMainWindow

	* Storage space for user input
	lea	-50(sp),sp
	move.l	sp,a1
	clr.b	(a1)
	jsr		get_rt
	; a1 = string buffer
	; d0 = max chars
	moveq	#40,d0
	; a2 = requester title
	lea		.searchModland(pc),a2
 ifne FEATURE_UHC_AMINET
	cmp.b	#SEARCH_MODLAND,d7
	beq.b	.5
	lea		.searchAminet(pc),a2
.5
 endif

	; a3 = rtReqInfo structure or null
	sub.l	a3,a3
	; a0 = tags, to set the public screen
	lea		otag15,a0
	lob		rtGetStringA
; d0 = true if something entered, false otherwise
	tst.l	d0
	beq		.exit

	jsr		inforivit_searching

	* Prepare script into desbuf(a5)
	lea		.modlandSearchCmd(pc),a0
 ifne FEATURE_UHC_AMINET
	cmp.b	#SEARCH_MODLAND,d7
	beq.b	.1
	lea		.aminetSearchCmd(pc),a0
.1
 endif
 	move.l	sp,d0		* search word
	jsr		desmsg

	* Save it into a file for execution
	lea		desbuf(a5),a0
	move.l	a0,a1
.findEnd
	tst.b	(a0)+
	bne.b	.findEnd
	clr.b	(a0)

	* Find length for saving
	move.l	a0,d0
	sub.l	a1,d0

	lea		remoteScriptPath(pc),a0
	; data in a1
	bsr		plainSaveFile
	tst.l	d0
	bmi		.exit

	pushpea	remoteExecute(pc),d1
 if DEBUG
	move.l	d1,d0
	DPRINT	"%s"
 endif
	moveq	#0,d2			* input
	move.l	nilfile(a5),d3	* output
	lore	Dos,Execute
	DPRINT	"Status=%ld"

	* Read the results file
	lea		.modlandResultsPath(pc),a0
 ifne FEATURE_UHC_AMINET
	cmp.b	#SEARCH_MODLAND,d7
	beq.b	.a
	lea		.aminetResultsPath(pc),a0
.a
 endif
 	bsr	plainLoadFile
	DPRINT	"Results=%lx"
	tst.l	d0
	beq		.exit
	; d0 = data
	; d1 = len
	
	DPRINT	"Importing"
	jsr		obtainModuleList
	pushm	all
	* free previous normal list
	jsr		freelist
	* ensure the normal mode is active
	jsr		engageNormalMode
	popm	all

	; start of data
	move.l	d0,a3
	; end of data
	lea		(a3,d1.l),a4
	; destination list
	lea moduleListHeader(a5),a2
	
	* Determine line header to use to add the "http://" -base address
	* to each line.
	pushpea	.modlandLine(pc),d6
	moveq	#.modlandLineE-.modlandLine,d4
 ifne FEATURE_UHC_AMINET
	cmp.b	#SEARCH_MODLAND,d7
	beq.b	.2
	* Aminet mirror is populated after aminetsearch has been done,
	* so get it here.
	bsr		getUHCAminetMirror
	move.l	uhcAminetMirrorPath(a5),d6
	beq.b	.noAminet
	move.l	d6,a0
.flen
	tst.b	(a0)+
	bne.b	.flen
	move.l	a0,d4
	sub.l	d6,d4 * string length in d4
.2
 endif
	* Import data
	* This will also set l_remote and l_nameaddr
	* to correct values for remote files.
	jsr		importModuleProgramFromDataSkipHeader
	move.l	d0,modamount(a5)

	move.l	a3,a0
	jsr		freemem
	jsr		forceRefreshList
	jsr		releaseModuleList
.exit
.noAminet
	jsr		inforivit_play
	jsr		unlockMainWindow
	lea 	50(sp),sp
	rts


.modlandLine
	dc.b	"http://ftp.modland.com/pub/modules/",0
.modlandLineE

.searchModland
	dc.b	"Search Modland",0

.modlandResultsPath
	dc.b	"T:modlandsearch",0
.modlandSearchCmd
	dc.b	"path ${UHCBIN}C ${UHCBIN}S ADD",10
	dc.b 	'modlandsearch "%s"',10
	dc.b	0
 ifne FEATURE_UHC_AMINET
.searchAminet
	dc.b	"Search Aminet",0
.aminetResultsPath
	dc.b	"T:aminetsearch",0
.aminetSearchCmd
	dc.b	"path ${UHCBIN}C ${UHCBIN}S ADD",10
	dc.b 	'aminetsearch "%s"',10
	dc.b	0
 endif
	even

* Set list node remote type and
* set l_nameaddr to be proper for showing to user.
* In:
*   a0 = list node
configRemoteNode
	pushm	d0/a0-a2
	st		l_remote(a0)
 
 	lea		l_filename(a0),a1
	move.l	a1,a2
.findEnd2
	tst.b	(a1)+
	bne.b	.findEnd2

	moveq	#2-1,d0
.findSlash
	cmp.l	a1,a2
	beq.b	.break * safety check
	cmp.b	#"/",-(a1)
	bne.b	.findSlash
	dbf	d0,.findSlash
	addq	#1,a1
.break
	move.l	a1,l_nameaddr(a0)
	popm	d0/a0-a2
	rts

* Loads a remote file into a tempfile using aget.
* The url is based on the node l_filename and l_remote status.
* in:
*   a0 = buffer for the path to the output file path to be filled
*   a3 = node
* out:
*   a0 = path to file, delete after loading
fetchRemoteFile	
	pushm	d1-a6
	DPRINT	"fetchRemoteFile"

	moveq	#0,d7	* status

	* Temporary target file path, the last part of the url path
	move.l	l_nameaddr(a3),a1
.end
	tst.b	(a1)+
	bne.b	.end
.sl	cmp.b	#"/",-(a1)
	bne.b	.sl
	addq	#1,a1

	move.l	a1,a2
	move.b	#"T",(a0)+
	move.b	#":",(a0)+
.copy
	move.b	(a2)+,(a0)+
	bne.b	.copy

	* Generate parametrized script
	lea		l_filename(a3),a0
	move.l	a0,d0
	move.l	a1,d1
	lea		.getScript(pc),a0
	jsr		desmsg

	jsr		inforivit_downloading
	jsr		setMainWindowWaitPointer

	* Save into a file to execute
	lea		desbuf(a5),a0
	move.l	a0,a1
.findEnd
	tst.b	(a1)+
	bne.b	.findEnd
	sub.l	a0,a1
	subq	#1,a1
	move.l	a1,d0	* file len

	lea		remoteScriptPath(pc),a0
	lea		desbuf(a5),a1
	bsr		plainSaveFile
	tst.l	d0
	bmi		.exit

	pushpea	remoteExecute(pc),d1
	moveq	#0,d2			* input
	move.l	nilfile(a5),d3	* output
	lore	Dos,Execute
	DPRINT	"Execute=%ld"
	moveq	#1,d7 * ok
.exit
	jsr		clearMainWindowWaitPointer
	move.l	d7,d0
	popm	d1-a6
	rts


.getScript
	dc.b	"path ${UHCBIN}C ADD",10
	dc.b	'aget %s "T:%s" QUIET',0
remoteExecute
	dc.b	"execute "
remoteScriptPath
	dc.b	"T:hip",0

 even

* Checks if UHC is installed
initializeUHC
	tst.b	uusikick(a5)
	bne.b	.go
	rts
.go
	pushpea	.uhc(pc),d1
	moveq	#ACCESS_READ,d2
	lore  	Dos,Lock
	move.l	d0,d1
	beq.b	.nope	
	st		uhcAvailable(a5)
	lob		UnLock
.nope
	rts

.uhc	dc.b	"ENV:UHCBIN",0
 even

  ifne FEATURE_UHC_AMINET
getUHCAminetMirror
	pushm	d1-a6
	move.l	uhcAminetMirrorPath(a5),d0
	clr.l	uhcAminetMirrorPath(a5)
	jsr		freemem

	lea	.aminetMirrorPath(pc),a0
	bsr	plainLoadFile
	* d0 = data
	* d1 = length
	tst.l	d0
	beq.b	.x
	move.l	d1,d7
	move.l	d0,a3

	* space for header + NULL
	moveq	#.httpE-.http+1,d0
	add.l	d7,d0
	move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
	jsr		getmem
	beq.b	.x
	move.l	d0,uhcAminetMirrorPath(a5)
	move.l	d0,a0

	lea		.http(pc),a1
.c1	move.b	(a1)+,(a0)+
	bne.b	.c1
	subq	#1,a0
	move.l	a3,a1
	subq	#1,d7
.c2	move.b	(a1)+,(a0)+
	dbf		d7,.c2
	clr.b	(a0)

	move.l	a3,a0
	jsr		freemem
 if DEBUG
	move.l	uhcAminetMirrorPath(a5),d0
	DPRINT	"UHC aminet mirror=%s"
 endif
.x
	popm	d1-a6
	rts

.http	dc.b	"http://",0
.httpE

.aminetMirrorPath
	dc.b	"ENV:UHC/AMINETMIRROR",0
	even

deinitUHC
	move.l	uhcAminetMirrorPath(a5),a0
	jmp		freemem
 else

deinitUHC
	rts

 endif


	
***************************************************************************
*
* Performance measurement with timer.device
*
***************************************************************************

 if DEBUG
openTimer
	move.l	(a5),a0
	move	LIB_VERSION(a0),d0
	cmp	#36,d0
	blo.b	.x
	move.l	a0,a6

	lea	.timerDeviceName(pc),a0
	moveq	#UNIT_ECLOCK,d0
	moveq	#0,d1
	lea	timerRequest(a5),a1
	lob	OpenDevice		; d0=0 if success
	tst.l	d0
	seq	timerOpen(a5)
.x	rts

.timerDeviceName dc.b	"timer.device",0
	even

closeTimer
	tst.b	timerOpen(a5)
	beq.b	.x
	clr.b	timerOpen(a5)
	move.l	(a5),a6
	lea	timerRequest(a5),a1
	lob	CloseDevice
.x	rts

startMeasure
	tst.b	timerOpen(a5)
	beq.b	.x
	push	a6	
	move.l	IO_DEVICE+timerRequest(a5),a6
	lea	clockStart(a5),a0
	lob	ReadEClock
	pop 	a6
.x	rts

; out: d0: difference in millisecs
stopMeasure
	tst.b	timerOpen(a5)
	bne.b	.x
	moveq	#-1,d0
	rts
.x	pushm	d2-d4/a6
	move.l	IO_DEVICE+timerRequest(a5),a6
	lea	clockEnd(a5),a0
	lob	ReadEClock
	move.l	d0,d2
	; d2 = ticks/s
	divu	#1000,d2
	; d2 = ticks/ms
	ext.l	d2
	
	; Calculate diff between start and stop times
	; in 64-bits
	;move.l	EV_HI+clockEnd(a5),d0
	move.l	EV_LO+clockEnd(a5),d1
	;move.l	EV_HI+clockStart(a5),d3
	sub.l	EV_LO+clockStart(a5),d1
	;subx.l	d3,d0

	; Ignore the upper 32 bits, such large intervals
	; are not needed.
	divu	d2,d1
	moveq	#0,d0
	move	d1,d0

	; Turn the diff into millisecs
	; Divide d0:d1 by d2
	;jsr	divu_64
	; d0:d1 is now d0:d1/d2
	; take the lower 32-bits
	;move.l	d1,d0
	popm	d2-d4/a6
	rts

  endif

*******************************************************************************
* Playereit‰

		;incdir
* Protracker code
kplayer		incbin	kpl
		;incdir	asm:player/pl/

* FImp decruncher code
fimp_decr	incbin	fimp_dec.bin

shr_decr	include	ShrinklerDecompress.s

* in:
*    a4 = data
* out:
*    d0 = size
getDeshrinkledSize
	move.l	shr_safety_margin(a4),d0
	bpl.b	.pos
	moveq	#0,d0
.pos	add.l	shr_uncompressed_size(a4),d0
	rts

* in:
*    a4 = data in
*    a1 = output buffer
deshrinkle
	move.l	a4,a0
	moveq	#FLAG_PARITY_CONTEXT,d7
	and.l	shr_flags(a0),d7
	* Skip header
	add	shr_header_size(a0),a0
	* Skip id and header size
	addq	#8,a0
	bra.w	ShrinklerDecompress


xpkname         dc.b    "xpkmaster.library",0
ppname          dc.b    "powerpacker.library",0
medplayername1  dc.b    "medplayer.library",0
medplayername2  dc.b    "octaplayer.library",0
medplayername3  dc.b    "octamixplayer.library",0
sidname         dc.b    "playsid.library",0
mlinename       dc.b    "mline.library",0
xfdname         dc.b    "xfdmaster.library",0
_MTName         dc.b    "mathtrans.library",0
_FFPName        dc.b    "mathffp.library",0
                even

	section	plrs,data

*******************************************************************************
*
* UI structures
* - Font definitions
* - Window structures
* - Gadgets
*

topaz_text_attr
	dc.l	topaz		* ta_Name
	dc	8		* ta_YSize
	dc.b	0		* ta_Style
	dc.b	0		* ta_Flags

text_attr
	dc.l	topaz		* ta_Name
	dc	8		* ta_YSize
	dc.b	0		* ta_Style
	dc.b	0		* ta_Flags

topaz	dc.b	"topaz.font",0
 even


mini_text_attr
	dc.l	.mini	* ta_Name
	dc	8		* ta_YSize
	dc.b	0		* ta_Style
	dc.b	0		* ta_Flags
;	dc.b	FPF_PROPORTIONAL * ta_Flags

.mini	dc.b	"mini4.font",0
 even

list_text_attr
	dc.l	topaz	* ta_Name
	dc	8	*	 ta_YSize
	dc.b	0	* ta_Style
	dc.b	0	* ta_Flags


* Main window
* STRUCTURE NewWindow
winstruc
	* nw_LeftEdge
	dc	360	;vas.yl‰k.x-koord.
	* nw_TopEdge
	dc	23	;---""--- y-koord
	* nw_Width
wsizex	dc	0	* sizex
	* nw_Height
wsizey	dc	0	* 181+25 ja 11
	* nw_DetailPen, nw_BlockPen
colors	dc.b	2,1	;palkin v‰rit
	* nw_IDCMPFlags
idcmpmw	dc.l	idcmpflags
	* nw_Flags
	dc.l	wflags
	* nw_FirstGadget
 	dc.l	0		* gadgets
	* nw_CheckMark
	dc.l	0	
	* nw_Title
	dc.l	windowname1
	* nw_Screen
	dc.l	0	;screen struc
	* bw_BitMap
	dc.l	0	;bitmap struc
	* nw_MinWidth, nw_MinHeight
	dc	0,0		* min x,y
	* nw_MaxWidth, nw_MaxHeight
	dc	0,512
	* nw_Type
	dc	WBENCHSCREEN
	dc.l	.t

*** Kick2.0+ window extension
* pubscreen, zip window

.t	dc.l	WA_PubScreenName,pubscreen+var_b	
	dc.l	WA_PubScreenFallBack,TRUE
	* Needed by ZipWindow (kick2.0)
	* Pointer to four words, LeftEdge, TopEdge, Width, Height
	dc.l	WA_Zoom,windowZippedPos+var_b 	
	dc.l	TAG_END

* Main window gadgets
gadgets
	;incdir
	include	gadgets/gadgets16_new3.s


* Prefs-window
winstruc2
	dc	0,0
prefssiz
	dc	452,170
colors2	dc.b	2,1
	dc.l	idcmpflags2
	dc.l	wflags2
 	dc.l	0		* gadgets
	dc.l	0	
	dc.l	.w
	dc.l	0	;screen struc
	dc.l	0	;bitmap struc
	dc	0,0	* min x,y
	dc	1000,1000 * max x,y
	dc	WBENCHSCREEN
	dc.l	enw_tags

.w	dc.b	"HippoPrefs"
wreg2
 ifne ANNOY
	dc.b	" - Unregistered version!",0
 else
	dc.b	0
 endif

 even

* Scope window
winstruc3
	dc	259
	dc	157
quadsiz	dc	340,85
	dc.b	2,1	;palkin v‰rit
	dc.l	idcmpflags3
	dc.l	wflags3
	dc.l	0
	dc.l	0	
;quadtitl
	dc.l	.t
	dc.l	0
	dc.l	0	
	dc	0,0	* min x,y
	dc	1000,1000 * max x,y
	dc	WBENCHSCREEN
	dc.l	enw_tags

.t	dc.b	"HippoScope"
wreg3
 ifne ANNOY
	dc.b	" - Unregistered version!",0
 else
 	dc.b	0
 endif
 even

* Pop up selector window used in prefs
winlistsel
	dc	0,0	* paikka 
winlistsiz
	dc	0,0	* koko
;	dc.b	2,1	;palkin v‰rit
	dc.b	0,0	;palkin v‰rit
	dc.l	idcmpflags4
	dc.l	wflags4
	dc.l	0
	dc.l	0	
	dc.l	0	; title
	dc.l	0
	dc.l	0	
	dc	0,0	 * min x,y
	dc	1000,1000 * max x,y
	dc	WBENCHSCREEN
	dc.l	enw_tags

* Prefs windows gadgets
gadgets2	include gadgets/prefs_main2.s
sivu0		include	gadgets/prefs_sivu0.s
sivu1		include	gadgets/prefs_sivu1.s
sivu2		include	gadgets/prefs_sivu2.s
sivu3		include	gadgets/prefs_sivu3.s
sivu4		include	gadgets/prefs_sivu4.s
sivu5		include	gadgets/prefs_sivu5.s
sivu6		include	gadgets/prefs_sivu6.s

* This is the "Favorites" button that belongs to prefs "sivu0" page.
* It should be the "next gadget" for gadget "bUu22", which is the "autosort" 
* button :-)
* I drew the button using the GadEdit tool but after exporting as source
* the data was not exactly same as the original, creating extra stuff
* and other odd things, so I copy-pasted the new bit here.

prefsFavorites dc.l prefsSaveState
       dc.w 406,121,28,12,3,1,1
       dc.l 0
       dc.l 0,prefsFavoritest,0,0
       dc.w 0
       dc.l 0
prefsFavoritest        dc.b 1,0,1,0
       dc.w -146,2
       dc.l 0,prefsFavoritestx,0
prefsFavoritestx       dc.b "Favorite modules..",0
       even

* "Save state" button
prefsSaveState
       dc.l 0
       dc.w 406,121-42,28,12,3,1,1
       dc.l 0
       dc.l 0,prefsSaveStatet,0,0
       dc.w 0
       dc.l 0
prefsSaveStatet        dc.b 1,0,1,0
       dc.w -146,2
       dc.l 0,prefsSaveStatetx,0
prefsSaveStatetx  
	     dc.b "Keep list on exit ",0
       even

* "Button tooltips" button copypasted from above, 
* x-coordinates adjusted manually.

prefsTooltips dc.l prefsAltButtons
       dc.w 214,107,28,12,3,1,1
       dc.l 0
       dc.l 0,prefsTooltipst,0,0
       dc.w 0
       dc.l 0
prefsTooltipst        dc.b 1,0,1,0
       dc.w -198,2
       dc.l 0,prefsTooltipstx,0
prefsTooltipstx 
       dc.b "Button tooltips.........",0
       even

prefsAltButtons 
       dc.l prefsQuadraScope
       dc.w 214,107+14,28,12,3,1,1
       dc.l 0
       dc.l 0,prefsAltButtonst,0,0
       dc.w 0
       dc.l 0
prefsAltButtonst        dc.b 1,0,1,0
       dc.w -198,2
       dc.l 0,prefsAltButtonstx,0
prefsAltButtonstx 
      ;dc.b "Bizarre buttons.........",0
      ;dc.b "Unconventional buttons..",0
       dc.b "Big buttons.............",0

prefsBarsText
	dc.b	"Bars",0
	even

prefsQuadraScope 
       dc.l prefsQuadraScopeBars
       dc.w 406-70,51+14+14,28,12,3,1,1
       dc.l 0,0,.t,0,0
       dc.w 0
       dc.l 0
.t        
       dc.b 1,0,1,0
       dc.w -146+70,2
       dc.l 0,.tx,.t2
.tx
       dc.b "Quadra",0
       even
.t2    
       dc.b 1,0,1,0
       dc.w -146+70,2-14
       dc.l 0,.tx2,0
.tx2	dc.b	 "Scopes:",0
 even

prefsQuadraScopeBars
       dc.l prefsQuadraScopeF
       dc.w 406,51+14+14,28,12,3,1,1
       dc.l 0,0,.t,0,0
       dc.w 0
       dc.l 0
.t        
       dc.b 1,0,1,0
       dc.w -40+4,2
       dc.l 0,prefsBarsText,0


prefsQuadraScopeF
       dc.l prefsQuadraScopeFBars
       dc.w 406-70,51+14+14+14,28,12,3,1,1
       dc.l 0,0,.t,0,0
       dc.w 0
       dc.l 0
.t        
       dc.b 1,0,1,0
       dc.w -146+70,2
       dc.l 0,.tx,0
.tx
       dc.b "Fill quad",0
       even

prefsQuadraScopeFBars
       dc.l prefsHippoScope
       dc.w 406,51+14+14+14,28,12,3,1,1
       dc.l 0,0,.t,0,0
       dc.w 0
       dc.l 0
.t        
       dc.b 1,0,1,0
       dc.w -40+4,2
       dc.l 0,prefsBarsText,0

prefsHippoScope
       dc.l prefsHippoScopeBars
       dc.w 406-70,51+14+14+14+14,28,12,3,1,1
       dc.l 0,0,.t,0,0
       dc.w 0
       dc.l 0
.t        
       dc.b 1,0,1,0
       dc.w -146+70,2
       dc.l 0,.tx,0
.tx
       dc.b "Hippo",0
       even

prefsHippoScopeBars
       dc.l prefsPatternScope
       dc.w 406,51+14+14+14+14,28,12,3,1,1
       dc.l 0,0,.t,0,0
       dc.w 0
       dc.l 0
.t        
       dc.b 1,0,1,0
       dc.w -40+4,2
       dc.l 0,prefsBarsText,0


prefsPatternScope
       dc.l prefsPatternScopeXL
       dc.w 406-70,51+14+14+14+14+14+14,28,12,3,1,1
       dc.l 0,0,.t,0,0
       dc.w 0
       dc.l 0
.t        
       dc.b 1,0,1,0
       dc.w -146+70,2
       dc.l 0,.tx,0
.tx
       dc.b "Pattern",0
       even
 even

prefsPatternScopeXL
       dc.l prefsSpectrumScope
       dc.w 406,51+14+14+14+14+14+14,28,12,3,1,1
       dc.l 0,0,.t,0,0
       dc.w 0
       dc.l 0
.t        
       dc.b 1,0,1,0
       dc.w -40+4,2
       dc.l 0,.tx,0
.tx
       dc.b "XL",0
 even

prefsSpectrumScope
       dc.l prefsSpectrumScopeBars
       dc.w 406-70,51+14+14+14+14+14,28,12,3,1,1
       dc.l 0,0,.t,0,0
       dc.w 0
       dc.l 0
.t        
       dc.b 1,0,1,0
       dc.w -146+70,2
       dc.l 0,.tx,0
.tx
       dc.b "Spectrum",0
       even

prefsSpectrumScopeBars
       dc.l prefsListFont
       dc.w 406,51+14+14+14+14+14,28,12,3,1,1
       dc.l 0,0,.t,0,0
       dc.w 0
       dc.l 0
.t        
       dc.b 1,0,1,0
       dc.w -40+4,2
       dc.l 0,prefsBarsText,0

; Button to select list font, on prefs page 2
prefsListFont
	dc.l	0 ; LAST ONE
	dc.w 120+37,93,(122+6*8)/2,12,0,1,1
	dc.l 0,0,0,0,0
	dc.w 0
	dc.l 0

; Gadget
gadgetListModeChangeButton
	; gg_NextGadget
	dc.l gadgetResize
	; gg_LeftEdge
	dc 9
	; gg_TopEdge
	dc 64
	; gg_Width
	dc 18
	; gg_Height
	dc 13
	; gg_Flags
	dc GFLG_GADGIMAGE
	; gg_Activation
	dc GACT_RELVERIFY
	; gg_GadgetType
	dc GTYP_BOOLGADGET
	; gg_GadgetRender
	dc.l gadgetListModeChangeButtonImage
	; gg_SelectRender
	dc.l 0
	; gg_GadgetText
	dc.l 0
	; gg_MutualExclude
	dc.l 0
	; gg_SpecialInfo
	dc.l 0
	; gg_GadgetId
	dc.w 0
	; gg_UserData
	dc.l 0


; Image
gadgetListModeChangeButtonImage
	; ig_LeftEdge
	dc 4
	; ig_TopEdge
	dc 3
	; ig_Width
	dc 9+1
	; ig_Height
	dc 7
	; ig_Depth
	dc 1
	; ig_ImageData
gadgetListModeChangeButtonImagePtr
	dc.l	listImage
	; ig_PlanePick
	dc.b 1
	; ig_PlaneOff
	dc.b 0
	; ig_NextImage
	dc.l 0

gadgetResize
	; gg_Next
	dc.l	0
	; gg_LeftEdge: relative to right edge
	dc.w	-5
	; gg_TopEdge: relative to bottom edge
	dc.w	-5
	; gg_Width, gg_Height
	dc.w	6,6
	; gg_Flags
	dc.w	GFLG_RELRIGHT!GFLG_RELBOTTOM!GFLG_GADGIMAGE
	; gg_Activation
	dc.w	0
	; gg_GadgetType
	dc.w	GTYP_SIZING
	; gg_GadgetRender
	dc.l	.gadgetResizeImage
	; gg_SelectRender
	dc.l	0
	; gg_GadgetText
	dc.l	0	
	; gg_MutualExclude
	dc.l	0
	; gg_SpecialInfo
	dc.l	0
	; gg_GadgetId
	dc.w	0
	; gg_UserData
	dc.l	0

; Image
.gadgetResizeImage
	; ig_LeftEdge
	dc 0
	; ig_TopEdge
	dc 0
	; ig_Width
	dc 6
	; ig_Height
	dc 6
	; ig_Depth
	dc 2
	; ig_ImageData
	dc.l	resizeGadgetImage
	; ig_PlanePick
	dc.b %11
	; ig_PlaneOff
	dc.b 0
	; ig_NextImage
	dc.l 0


* Rename the gadgets defined above to something not crazy
* 1st row
gadgetPlayButton 	EQU  button1
gadgetInfoButton	EQU  button2
gadgetStopButton	EQU  button3
gadgetEjectButton	EQU  button4
gadgetNextButton	EQU  button5
gadgetPrevButton        EQU  button6
gadgetForwardButton     EQU  kela2
gadgetRewindButton      EQU  kela1
gadgetNextSongButton    EQU  button12
gadgetPrevSongButton    EQU  button13
* 2nd row
gadgetAddButton         EQU  button7
gadgetDelButton         EQU  button8
gadgetNewButton   	EQU  button11
gadgetPrefsButton	EQU  button20
gadgetVolumeSlider	EQU  slider1
gadgetFileSlider        EQU  slider4
gadgetSortButton        EQU  lilb2
gadgetMoveButton        EQU  lilb1 
gadgetPrgButton         EQU  plg

 ifne FEATURE_HORIZ_RESIZE
; Index to gadget and the original gg_Width and gg_LeftEdge
row1Gadgets
	dr	gadgetPrevButton
	dc	0,0
	dr	gadgetPrevSongButton
	dc	0,0
	dr	gadgetRewindButton
	dc	0,0
	dr	gadgetPlayButton
	dc	0,0
	dr 	gadgetForwardButton
	dc	0,0
	dr	gadgetNextSongButton
	dc	0,0
	dr	gadgetNextButton
	dc	0,0
	dr	gadgetStopButton
	dc	0,0
	dr	gadgetEjectButton
	dc	0,0
	dr	gadgetInfoButton
	dc	0,0
	dc	0 ; END
	
row2Gadgets
	dr	gadgetVolumeSlider
	dc	0,0
	dr	gadgetNewButton
	dc	0,0
	dr	gadgetAddButton
	dc	0,0
	dr	gadgetDelButton
	dc	0,0
	dr	gadgetPrgButton
	dc	0,0
	dr	gadgetMoveButton
	dc	0,0
	dr	gadgetSortButton
	dc	0,0
	dr	gadgetPrefsButton
	dc	0,0
	dc	0 ; END
 endif ; FEATURE

gadgetFileSliderInitialHeight = 67-16+2

* Contains gadget-routine pairs that determine
* the right mouse button actions when button is released
rightButtonActionsList	
	* New -> Clear
	dr.w	gadgetNewButton
	dc.l	rbutton9
	* Prefs -> zoom file box
	dr.w	gadgetPrefsButton
	dc.l	zoomfilebox
	* S -> Sort
	dr.w	gadgetSortButton
	dc.l	rsort
	* Move -> Add divider
	dr.w	gadgetMoveButton
	dc.l	add_divider
	* Add -> Insert
	dr.w 	gadgetAddButton
	dc.l	rinsert
	* Load Prg -> Save Prg
	dr.w	gadgetPrgButton
	dc.l	rsaveprog
	* > -> Fast forward
	dr.w 	gadgetForwardButton
	dc.l	rbutton_kela2_turbo
	* Del -> Nuke file
	dr.w	gadgetDelButton
	dc.l	hiiridelete  
	* i -> About
	dr.w 	gadgetInfoButton
	dc.l	aboutButtonAction
	* Play -> Random play
	dr.w	gadgetPlayButton
	dc.l	soitamodi_random
	dc.w	0 ; END
 

* Contains tooltip data for mainwindow gadgets
tooltipList
	dr.w 	gadgetPlayButton,.play
	dr.w	gadgetInfoButton,.info
	dr.w	gadgetStopButton,.stop
	dr.w	gadgetEjectButton,.eject 
	dr.w	gadgetNextButton,.next
	dr.w	gadgetPrevButton,.prev
	dr.w	gadgetAddButton,.add
	dr.w	gadgetDelButton,.del
	dr.w 	gadgetNewButton,.new
	dr.w	gadgetNextSongButton,.nextSong
	dr.w	gadgetPrevSongButton,.prevSong
	dr.w	gadgetPrefsButton,.prefs
	dr.w	gadgetSortButton,.sort
	dr.w 	gadgetMoveButton,.move
	dr.w	gadgetPrgButton,.prg 
	dr.w	gadgetForwardButton,.forward
	dr.w	gadgetRewindButton,.rewind
	dr.w	gadgetListModeChangeButton,.listModeChange
	dc.w	0 ; END
 
.play
	dc.b	34,2
	dc.b	"LMB: Play or restart chosen module",0
	dc.b	"RMB: Play a random module",0
.info
	dc.b	21,2
	dc.b	"LMB: Show module info",0
	dc.b	"RMB: Show about info",0
.stop
	dc.b	25,1
	dc.b	"Stop or continue playback",0
.eject
	dc.b	29,1
	dc.b	"Stop and eject current module",0
.next
	dc.b	16,1
	dc.b	"Play next module",0
.prev
	dc.b	20,1
	dc.b	"Play previous module",0
.add
	dc.b	47,2
	dc.b	"LMB: Add new modules to the list",0
	dc.b	"RMB: Insert new modules after the chosen module",0
.del
	dc.b	35,4
	dc.b	"LMB: Remove chosen module",0
	dc.b	"RMB: Remove from list and from disk",0
	dc.b	"     RMB on a divider will remove",0
	dc.b    "     the divided list section",0
.new
	dc.b	29,2
	dc.b	"LMB: Clear list and add files",0
	dc.b	"RMB: Clear list",0
.nextSong
	dc.b	17,1
	dc.b	"Play next subsong",0
.prevSong
	dc.b	21,1
	dc.b	"Play previous subsong",0
.prefs
	dc.b	21,2
	dc.b	"LMB: Open preferences",0
	dc.b    "RMB: Zoom file box",0
.sort
;	dc.b	16,2
;	dc.b	"LMB: Sort list",0
;	dc.b	"RMB: Find module",0
	dc.b	21,2
	dc.b	"LMB: Search functions",0
	dc.b	"RMB: Sort list",0
.move
	dc.b	26,4
	dc.b	"LMB: Move chosen module,",0
	dc.b    "     press again to insert",0
	dc.b    "     the moved module",0
	dc.b	"RMB: Add divider",0
.prg
	dc.b	24+5,4
	dc.b	"LMB: Load module program",0
	dc.b	"RMB: Save module program",0
	dc.b	"Favorite modules are saved to",0
	dc.b	34,"S:HippoFavorites.prg",34,0
.forward
	dc.b	36,4
	dc.b	"LMB: Skip module forward",0
	dc.b    "     or play faster if can't skip",0
	dc.b	"RMB: Play even faster!",0
	dc.b    "Stop fast playback by pressing again",0
.rewind
	dc.b	20,1
	dc.b	"Skip module backward",0
;.listModeChange
;	dc.b	38,2
;	dc.b	"LMB: Toggle list mode",0
;	dc.b	"     Normal > Favorites > File browser",0
.listModeChange
	dc.b	22,4
	dc.b	"LMB: Toggle list mode",0
	dc.b	"     - Normal playlist",0
	dc.b    "     - Favorites list",0
	dc.b    "     - File browser",0

  even

*** Samplename ikkuna
swinstruc
	dc	0	;vas.yl‰k.x-koord.
	dc	0	;---""--- y-koord
swinsiz	dc	361-5,150-13*8-2
colors3	dc.b	2,1	;palkin v‰rit
	dc.l	sidcmpflags
sflags	dc.l	swflags
	dc.l	gAD1	;1. gadgetti
	dc.l	0	
	dc.l	.w
	dc.l	0	;screen struc
	dc.l	0	
	dc	0,0,0,0,WBENCHSCREEN
	dc.l	enw_tags

.w	dc.b	"HippoInfo"
wreg1
 ifne ANNOY
	dc.b	" - Unregistered version!",0
 else
 	dc.b	0
 endif

 even

* Slider for the module info window
gAD1	
	dc.l gadgetResize
	dc.w 9,14,16,127-13*8,GFLG_GADGHNONE,9,3
	dc.l gAD1gr,0,0,0,gAD1s
	dc.w 0
	dc.l 0
gAD1gr	dc.w 0,0,6,4,0
	dc.l 0
	dc.b 0,0
	dc.l 0
gAD1s	dc.w 5,65535,0,0,0
	dc.w 0,0,0,0,0,0




*** Kick2.0+ window extension
* Asetetaan pubscreen

enw_tags
	dc.l	WA_PubScreenName,pubscreen+var_b	
	dc.l	WA_PubScreenFallBack,TRUE
	dc.l	TAG_END
	


*** file ja infoslider imagestruktuurit


slimage		dc	0	* leftedge
		dc	0	* topedge
		dc	16	* width
slimheight	dc	8	* heigh
		dc	2	* depth
		dc.l	slim	* data
		dc.b	%11	* planepick
		dc.b	0	* planeon/onff
		dc.l	0	* nextimage

slimage2	dc	0	* leftedge
		dc	0	* topedge
		dc	16	* width
slim2height	dc	8	* heigh
		dc	2	* depth
		dc.l	slim2	* data
		dc.b	%11	* planepick
		dc.b	0	* planeon/onff
		dc.l	0	* nextimage


; Vertical slider graphics, these are copied in the
; actual output gfx buffer depending on the slider size

; kickstart 2.0+
; Bitplane 1
slim1a	dc	%0000000000000000	; top line
.slim2a	dc	%0000000000000001	; middle lines
.slim3a	dc	%0111111111111111	; bottom line
; Bitplane 2
.slim1b	dc	%1111111111111110
.slim2b	dc	%1000000000000000
.slim3b	dc	%0000000000000000
 
; kickstart 1.3
; Bitplane 1
slim1a_kick13
.slim1a	dc	%1111111111111110	; top line
.slim2a	dc	%1000000000000000	; middle lines
.slim3a	dc	%0000000000000000	; bottom line
; Bitplane 2
.slim1b	dc	%0000000000000000
.slim2b	dc	%0000000000000001
.slim3b	dc	%0111111111111111


** PC -> Amiga somekinda text conversion table
asciitable
	DC.B	$00,$01,$02,$03,$04,$05,$06,$07
	DC.B	$08,$09,$0A,$0B,$0C,$0D,$0E,$0F
	DC.B	$3E,$3C,$12,$21,$B6,$A7,$2D,$17
	DC.B	$18,$19,$1A,$1B,$60,$2D,$1E,$1F
	DC.B	$20,$21,$22,$23,$24,$25,$26,$27
	DC.B	$28,$29,$2A,$2B,$2C,$2D,$2E,$2F
	DC.B	$30,$31,$32,$33,$34,$35,$36,$37
	DC.B	$38,$39,$3A,$3B,$3C,$3D,$3E,$3F
	DC.B	$40,$41,$42,$43,$44,$45,$46,$47
	DC.B	$48,$49,$4A,$4B,$4C,$4D,$4E,$4F
	DC.B	$50,$51,$52,$53,$54,$55,$56,$57
	DC.B	$58,$59,$5A,$5B,$5C,$5D,$5E,$5F
	DC.B	$60,$61,$62,$63,$64,$65,$66,$67
	DC.B	$68,$69,$6A,$6B,$6C,$6D,$6E,$6F
	DC.B	$70,$71,$72,$73,$74,$75,$76,$77
	DC.B	$78,$79,$7A,$7B,$7C,$7D,$7E,$7F
	DC.B	$C7,$DC,$E9,$E2,$E4,$E0,$E5,$E7
	DC.B	$EA,$EB,$E8,$CF,$CE,$CC,$C4,$C5
	DC.B	$C8,$E6,$C6,$D4,$F6,$D2,$FB,$F9
	DC.B	$FF,$D6,$DC,$E7,$A3,$D8,$52,$66
	DC.B	$E1,$CD,$D3,$DA,$D1,$D1,$AA,$AA
	DC.B	$BF,$2E,$2E,$BD,$BC,$A1,$AB,$BB
	DC.B	$AA,$AE,$D1,$7C,$7C,$7C,$7C,$2E
	DC.B	$2E,$7C,$7C,$2E,$27,$27,$27,$2E
	DC.B	$60,$5E,$2E,$7C,$2D,$7C,$7C,$7C
	DC.B	$60,$2E,$5E,$2E,$7C,$3D,$7C,$5E
	DC.B	$5E,$2E,$2E,$60,$60,$2E,$2E,$7C
	DC.B	$7C,$27,$2E,$D8,$5F,$7C,$7C,$AF
	DC.B	$61,$DF,$72,$6E,$45,$D3,$B5,$74
	DC.B	$FE,$D8,$4F,$F0,$2D,$F8,$C9,$6E
	DC.B	$3D,$B1,$3E,$3C,$66,$4A,$F7,$3D
	DC.B	$B0,$B7,$B7,$56,$6E,$B2,$B7,$20

	section	mini,data_c

* 2 bitplane image, 96x66 pixels
hippohead	incbin	gfx/hip.raw

tickdata	dc	$001c,$0030,$0060,$70c0,$3980,$1f00,$0e00

* 16x4 pixeli‰

* %00 = tausta
* %10 = musta
* %01 = valkoinen
* %11 = sininen

korvadata
	dc.b	%01000000,%00000000	* 1 bpl
	dc.b	%10100000,%00000000     
	dc.b	%10010000,%00000000
	dc.b	%11111000,%00000000

	dc.b	%10000000,%00000000	* 2 bpl
	dc.b	%01000000,%00000000
	dc.b	%01100000,%00000000
	dc.b	%00000000,%00000000

* Sininen patterni mukana
korvadata2
	dc.b	%01010101,%00000000	* 1 bpl
	dc.b	%10101010,%00000000
	dc.b	%10010101,%00000000
	dc.b	%11111010,%00000000

	dc.b	%10010101,%00000000	* 2 bpl
	dc.b	%01001010,%00000000
	dc.b	%01100101,%00000000
	dc.b	%00000010,%00000000


*** Slider2im
; Vertical slider image normal size
; Width: 11 pixels
; Height: 9 pixels
juustoim	
juust0im	
meloniim	
eskimOim
kellokeim
kelloke2im
pslider1im
pslider2im
sIPULIim
sIPULI2im
slider1im
ahiG4im
ahiG5im
ahiG6im
nAMISKA5im
horizPropGadgetGfxNormal
	; bitplane 1
	dc.w %0000000000000000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0111111111100000
	; bitplane 2
	dc.w %1111111111000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %0000000000000000

horizPropGadgetGfxNormal_kick13
	; bitplane 1
	dc.w %1111111111000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	; bitplane 2
	dc.w %0000000000000000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0111111111100000

* Width: 11 pixels
* Height: 9+8 pixels

slider1imDouble
horizPropGadgetGfxDouble
	; bitplane 1
	dc.w %0000000000000000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0111111111100000
	; bitplane 2
	dc.w %1111111111000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %0000000000000000

horizPropGadgetGfxDouble_kick13
	; bitplane 1
	dc.w %1111111111000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %1000000000000000
	dc.w %0000000000000000
	; bitplane 2
	dc.w %0000000000000000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0000000000100000
	dc.w %0111111111100000



button1im	
	dc	%1100000000000000				
	dc	%1111000000000000				
	dc	%1111110000000000				
	dc	%1111111000000000				
	dc	%1111110000000000				
	dc	%1111000000000000				
	dc	%1100000000000000				
	dc	%0000000000000000				

button1imDouble

	dc	%1000000000000000				
	dc	%1100000000000000				
	dc	%1110000000000000				
	dc	%1111000000000000				
	dc	%1111100000000000				
	dc	%1111110000000000				
	dc	%1111111000000000				
	dc	%1111111000000000				
	dc	%1111110000000000				
	dc	%1111100000000000				
	dc	%1111000000000000				
	dc	%1110000000000000				
	dc	%1100000000000000				
	dc	%1000000000000000				
	dc	%0000000000000000				

button2im
	dc	%0111000000000000				
	dc	%0111000000000000				
	dc	%0000000000000000				
	dc	%1111000000000000				
	dc	%0111000000000000				
	dc	%0111000000000000				
	dc	%0111000000000000				
	dc	%0111000000000000				
	dc	%1111110000000000				

button2imDouble
	dc	%0000000000000000				
	dc	%0111000000000000				
	dc	%0111000000000000				
	dc	%0111000000000000				
	dc	%0000000000000000				
	dc	%1111000000000000				
	dc	%1111000000000000				
	dc	%0111000000000000				
	dc	%0111000000000000				
	dc	%0111000000000000				
	dc	%0111000000000000				
	dc	%0111000000000000				
	dc	%0111000000000000				
	dc	%0111000000000000				
	dc	%1111110000000000				
	dc	%1111110000000000				
	dc	%0000000000000000				
	dc	%0000000000000000				

button3im
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%0000000000000000				

button3imDouble
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%1111001111000000				
	dc	%0000000000000000				
	dc	%0000000000000000				

button4im
	dc	%0000011000000000				
	dc	%0001111110000000
	dc	%0111111111100000				
	dc	%1111111111110000				
	dc	%0000000000000000				
	dc	%1111111111110000				
	dc	%1111111111110000				
	dc	%0000000000000000				

button4imDouble
	dc	%0000000000000000				
	dc	%0000011000000000				
	dc	%0000111100000000
	dc	%0001111110000000
	dc	%0011111111000000				
	dc	%0111111111100000				
	dc	%1111111111110000				
	dc	%1111111111110000				
	dc	%0000000000000000				
	dc	%0000000000000000				
	dc	%1111111111110000				
	dc	%1111111111110000				
	dc	%1111111111110000				
	dc	%1111111111110000				
	dc	%0000000000000000				
	dc	%0000000000000000				

button5im
	dc	%1100000110000011
	dc	%1111000111100011
	dc	%1111110111111011
	dc	%1111111111111111
	dc	%1111110111111011
	dc	%1111000111100011
	dc	%1100000110000011
	dc	%0000000000000000				

button5imDouble
	dc	%1000000100000011
	dc	%1100000110000011
	dc	%1110000111000011
	dc	%1111000111100011
	dc	%1111100111110011
	dc	%1111110111111011
	dc	%1111111111111111
	dc	%1111111111111111
	dc	%1111110111111011
	dc	%1111100111110011
	dc	%1111000111100011
	dc	%1110000111000011
	dc	%1100000110000011
	dc	%1000000100000011
	dc	%0000000000000000					
	dc	%0000000000000000				

button6im
	dc	%1100000110000011
	dc	%1100011110001111
	dc	%1101111110111111
	dc	%1111111111111111
	dc	%1101111110111111
	dc	%1100011110001111
	dc	%1100000110000011
	dc	%0000000000000000				

button6imDouble
	dc	%1100000010000001
	dc	%1100000110000011
	dc	%1100001110000111
	dc	%1100011110001111
	dc	%1100111110011111
	dc	%1101111110111111
	dc	%1111111111111111
	dc	%1111111111111111
	dc	%1101111110111111
	dc	%1100111110011111
	dc	%1100011110001111
	dc	%1100001110000111
	dc	%1100000110000011
	dc	%1100000010000001
	dc	%0000000000000000				
	dc	%0000000000000000				

button12im
	dc	%1100000110000000
	dc	%1111000110000000
	dc	%1111110110000000
	dc	%1111111110000000
	dc	%1111110110000000
	dc	%1111000110000000
	dc	%1100000110000000
	dc	%0000000000000000

button12imDouble
	dc	%1000000110000000
	dc	%1100000110000000
	dc	%1110000110000000
	dc	%1111000110000000
	dc	%1111100110000000
	dc	%1111110110000000
	dc	%1111111110000000
	dc	%1111111110000000
	dc	%1111110110000000
	dc	%1111100110000000
	dc	%1111000110000000
	dc	%1110000110000000
	dc	%1100000110000000
	dc	%1000000110000000
	dc	%0000000000000000
	dc	%0000000000000000	

button13im
	dc	%1100000110000000
	dc	%1100011110000000
	dc	%1101111110000000
	dc	%1111111110000000
	dc	%1101111110000000
	dc	%1100011110000000
	dc	%1100000110000000
	dc	%0000000000000000				

button13imDouble
	dc	%1100000010000000
	dc	%1100000110000000
	dc	%1100001110000000
	dc	%1100011110000000
	dc	%1100111110000000
	dc	%1101111110000000
	dc	%1111111110000000
	dc	%1111111110000000
	dc	%1101111110000000
	dc	%1100111110000000
	dc	%1100011110000000
	dc	%1100001110000000
	dc	%1100000110000000
	dc	%1100000010000000
	dc	%0000000000000000				
	dc	%0000000000000000				


kela1im
	dc	%0000011000001100
	dc	%0001111000111100
	dc	%0111111011111100
	dc	%1111111111111100
	dc	%0111111011111100
	dc	%0001111000111100
	dc	%0000011000001100
	dc	%0000000000000000				

kela1imDouble
	dc	%0000001000000100
	dc	%0000011000001100
	dc	%0000111000011100
	dc	%0001111000111100
	dc	%0011111001111100
	dc	%0111111011111100
	dc	%1111111111111100
	dc	%1111111111111100
	dc	%0111111011111100
	dc	%0011111001111100
	dc	%0001111000111100
	dc	%0000111000011100
	dc	%0000011000001100
	dc	%0000001000000100
	dc	%0000000000000000				
	dc	%0000000000000000				

kela2im	
	dc	%1100000110000000
	dc	%1111000111100000
	dc	%1111110111111000
	dc	%1111111111111100
	dc	%1111110111111000
	dc	%1111000111100000
	dc	%1100000110000000
	dc	%0000000000000000				

kela2imDouble
	dc	%1000000100000000
	dc	%1100000110000000
	dc	%1110000111000000
	dc	%1111000111100000
	dc	%1111100111110000
	dc	%1111110111111000
	dc	%1111111111111100
	dc	%1111111111111100
	dc	%1111110111111000
	dc	%1111100111110000
	dc	%1111000111100000
	dc	%1110000111000000
	dc	%1100000110000000
	dc	%1000000100000000
	dc	%0000000000000000				
	dc	%0000000000000000				


* height 8
* width 16

favoriteImage
	dc	%0111011100000000				
	dc	%1111111110000000				
	dc	%1111111110000000				
	dc	%0111111100000000				
	dc	%0011111000000000				
	dc	%0001110000000000				
	dc	%0000100000000000				

listImage
	dc	%1101111111000000
	dc	%0000000000000000				
	dc	%1101111111000000
	dc	%0000000000000000
	dc	%1101111111000000
	dc	%0000000000000000
	dc	%1101111111000000


 REM
fileBrowserImage
	dc	%1111111000000000
	dc	%1010010100000000				
	dc	%1011110010000000
	dc	%1000000010000000
	dc	%1011111010000000
	dc	%1011111010000000
	dc	%1111111110000000
 EREM
 
fileBrowserImage
	dc	%1111111100000000
	dc	%1010011010000000				
	dc	%1011111001000000
	dc	%1000000001000000
	dc	%1011111101000000
	dc	%1011001101000000
	dc	%1111111111000000

resizeGadgetImage
	; plane 1
	dc	%0000010000000000
	dc	%0001010000000000
	dc	%0011010000000000
	dc	%0111010000000000
	dc	%0000010000000000
	dc	%1111110000000000
	; plane 2
	dc	%1111100000000000
	dc	%1000000000000000
	dc	%1000000000000000
	dc	%1000000000000000
	dc	%1000000000000000
	dc	%0000000000000000

	section	mah,bss_c

* Tyhj‰ sample PS3M:lle ja BPSoundMon2.0:lle.
ps3memptysample
nullsample	ds.l	1

* tilaa filebox-sliderin imagelle
slim:	ds	410*2

* sampleinfo-slideri
slim2:	ds	410*2


	section	udnm,bss_p

		cnop 0,4
* Global variables
var_b		ds.b	size_var

* Copy of Protracker module header data for the info window
ptheader	ds.b	950
 end
