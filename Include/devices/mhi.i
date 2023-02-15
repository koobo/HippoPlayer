	IFND	LIBRARIES_MHI_I
LIBRARIES_MHI_I SET	1

;/* MHI status flags for player */

MHIF_PLAYING          =   0
MHIF_STOPPED          =   1
MHIF_OUT_OF_DATA      =   2
MHIF_PAUSED           =   3

;/* MHI queries and returned values */

MHIF_UNSUPPORTED      =   0
MHIF_SUPPORTED        =   1
MHIF_FALSE            =   0
MHIF_TRUE             =   1

MHIQ_DECODER_NAME     = 1000
MHIQ_DECODER_VERSION  = 1001
MHIQ_AUTHOR           = 1002

MHIQ_IS_HARDWARE      = 1010
MHIQ_IS_68K           = 1011
MHIQ_IS_PPC           = 1012

MHIQ_CAPABILITIES     =   0
MHIQ_MPEG1            =   1
MHIQ_MPEG2            =   2
MHIQ_MPEG25           =   3
MHIQ_MPEG4            =   4   ;/* there is no MPEG3! */

MHIQ_LAYER1           =  10
MHIQ_LAYER2           =  11
MHIQ_LAYER3           =  12

MHIQ_VARIABLE_BITRATE =  20
MHIQ_JOINT_STEREO     =  21

MHIQ_BASS_CONTROL     =  30
MHIQ_TREBLE_CONTROL   =  31
MHIQ_MID_CONTROL      =  32
MHIQ_PREFACTOR_CONTROL = 33
MHIQ_5_BAND_EQ        =  34
MHIQ_10_BAND_EQ       =  35

MHIQ_VOLUME_CONTROL   =  40
MHIQ_PANNING_CONTROL  =  41
MHIQ_CROSSMIXING      =  42

;/* ********************** */
;/* MHI decoder parameters */
;/* ********************** */

MHIP_VOLUME           =   0        ;// 0=muted .. 100=0dB
MHIP_PANNING          =   1        ;// 0=left .. 50=center .. 100=right
MHIP_CROSSMIXING      =   2        ;// 0=stereo .. 100=mono
;;// For 3-band equalizer
MHIP_BASS             =   3        ;// 0=max.cut .. 50=unity gain .. 100=max.boost
MHIP_MID              =   4        ;// 0=max.cut .. 50=unity gain .. 100=max.boost
MHIP_TREBLE           =   5        ;// 0=max.cut .. 50=unity gain .. 100=max.boost
MHIP_PREFACTOR        =   6        ;// 0=max.cut .. 50=unity gain .. 100=max.boost
;;// Extension for 5-band equalizer
MHIP_MIDBASS          =   7        ;// 0=max.cut .. 50=unity gain .. 100=max.boost
MHIP_MIDHIGH          =   8        ;// 0=max.cut .. 50=unity gain .. 100=max.boost

;;// Extension for 10-band equalizer
MHIP_BAND1            =   9        ;// 32 Hz
MHIP_BAND2            = MHIP_BASS    ;// 64 Hz
MHIP_BAND3            =  10        ;// 125 Hz
MHIP_BAND4            = MHIP_MIDBASS  ;// 250 Hz
MHIP_BAND5            =  11        ;// 500 Hz
MHIP_BAND6            = MHIP_MID     ;// 1 kHz
MHIP_BAND7            =  12        ;// 2 kHz
MHIP_BAND8            = MHIP_MIDHIGH  ;// 4 kHz
MHIP_BAND9            =  13        ;// 8 kHz
MHIP_BAND10           = MHIP_TREBLE   ;// 16 kHz

    ENDC