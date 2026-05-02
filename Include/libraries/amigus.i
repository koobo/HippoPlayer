	IFND LIBRARIES_AMIGUS_I
LIBRARIES_AMIGUS_I SET 1

    IFND EXEC_TYPES_I
    INCLUDE "exec/types.i"
    ENDC ; EXEC_TYPES_I
        
;/**
; * Enumerates all known AmiGUS derivatives with their own ID.
; */
AmiGUS_Zorro2 = $7000   ; Original Zorro2 card, avoiding Zero collisions
AmiGUS_mini   = $7001   ; PCMCIA card

;/**
; * Flags defining all functional blocks / parts of an AmiGUS card.
; */
AMIGUS_FLAG_NONE       = $0000   ;//< No part ;)
AMIGUS_FLAG_PCM        = $0001   ;//< PCM like main part, incl. mixer
AMIGUS_FLAG_WAVETABLE  = $0002   ;//< Wavetable part
AMIGUS_FLAG_CODEC      = $0004   ;//< Codec part, for MP3, FLAC, ...

;/**
; * amigus.library error codes as returned by library interface functions.
; */
AMIGUS_IN_USE_START    = $0100
;enum AmiGUS_Errors {    
AmiGUS_NoError                = 0
AmiGUS_InUse                  = AMIGUS_IN_USE_START ;, // 0x0100
AmiGUS_PcmInUse               = AMIGUS_IN_USE_START                                             | AMIGUS_FLAG_PCM
AmiGUS_WavetableInUse         = AMIGUS_IN_USE_START                     | AMIGUS_FLAG_WAVETABLE                  
AmiGUS_PcmWavetableInUse      = AMIGUS_IN_USE_START                     | AMIGUS_FLAG_WAVETABLE | AMIGUS_FLAG_PCM
AmiGUS_CodecInUse             = AMIGUS_IN_USE_START | AMIGUS_FLAG_CODEC                                          
AmiGUS_PcmCodecInUse          = AMIGUS_IN_USE_START | AMIGUS_FLAG_CODEC                         | AMIGUS_FLAG_PCM
AmiGUS_WavetableCodecInUse    = AMIGUS_IN_USE_START | AMIGUS_FLAG_CODEC | AMIGUS_FLAG_WAVETABLE                  
AmiGUS_PcmWavetableCodecInUse = AMIGUS_IN_USE_START | AMIGUS_FLAG_CODEC | AMIGUS_FLAG_WAVETABLE | AMIGUS_FLAG_PCM
AmiGUS_NotYours               = $0200
AmiGUS_DetectError            = $0401
AmiGUS_InterruptInstallFailed = $0402
AmiGUS_InterruptRemoveFailed  = $0403
AmiGUS_NotFound               = $0404
AmiGUS_NotImplemented         = $0500
;};

;/**
; * AmiGUS card description as returned by amigus.library/AmiGUS_FindCard().
; *
; * No need to free it, ownership stays with amigus.library.
; * Consider ALL fields read-only, please.
; */
 STRUCTURE AmiGUS,0

  APTR      agus_PcmBase       ;//> Base address of the PCM part of the card.
  APTR      agus_WavetableBase ;//> Base address of the Wavetable part.
  APTR      agus_CodecBase     ;//> Base address of the codec part.

;  union {
;    ULONG     idLongs[ 2 ]     ;//> Hardware ID of the card's FPGA - in ULONGs.
;    UBYTE     idBytes[ 8 ]     ;//> Hardware ID of the card's FPGA - in UBYTEs.
;  } agus_FpgaId
  STRUCT    agus_FpgaId,8
  
  ULONG     agus_HardwareRev   ;//> Hardware revision of the card.
  ULONG     agus_FirmwareRev   ;//> Firmware revision of the card.

  APTR      agus_TypeName      ;//> Human readable card type string.
  UWORD     agus_TypeId        ;//> Card type from enum AmiGUS_TypeIds.

  UWORD     agus_Year          ;//> Firmware date, year portion.
  UBYTE     agus_Month         ;//> Firmware date, month portion.
  UBYTE     agus_Day           ;//> Firmware date, day portion.
  UBYTE     agus_Hour          ;//> Firmware date, hour portion.
  UBYTE     agus_Minute        ;//> Firmware date, minute portion.

 ENDC ;  LIBRARIES_AMIGUS_I
