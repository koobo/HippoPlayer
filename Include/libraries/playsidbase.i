	IFND LIBRARIES_PLAYSIDBASE_I
LIBRARIES_PLAYSIDBASE_I	SET	1
**
**	$Filename: libraries/playsidbase.i $
**	$Release: 1.0 $
**
**	(C) Copyright 1994 Per Håkan Sundell and Ron Birk
**	    All Rights Reserved
**

	IFND EXEC_LISTS_I
	include "exec/lists.i"
	ENDC

	IFND EXEC_LIBRARIES_I
	include "exec/libraries.i"
	ENDC

PLAYSIDNAME	MACRO
	dc.b "playsid.library",0
	ENDM

PLAYSIDVERSION	equ	1

	STRUCTURE PlaySidBase,LIB_SIZE
		UBYTE	psb_Flags
		UBYTE	psb_Pad
		APTR	psb_SysLib
		APTR	psb_SegList
		UWORD	psb_PlayMode
		UWORD	psb_TimeSeconds
		UWORD	psb_TimeMinutes
		; Private...

	STRUCTURE	DisplayData,0
	APTR	dd_Sample1
	APTR	dd_Sample2
	APTR	dd_Sample3
	APTR	dd_Sample4
        WORD	dd_Length1
        WORD	dd_Length2
        WORD	dd_Length3
        WORD	dd_Length4
	WORD	dd_Period1
	WORD	dd_Period2
	WORD	dd_Period3
	WORD	dd_Period4
	WORD	dd_Enve1
	WORD	dd_Enve2
	WORD	dd_Enve3
	WORD	dd_Enve4
	WORD	dd_SyncLength1
	WORD	dd_SyncLength2
	WORD	dd_SyncLength3
	WORD	dd_Volume
	BYTE	dd_SyncInd1
	BYTE	dd_SyncInd2
	BYTE	dd_SyncInd3
	LABEL	dd_SIZEOF

; --- Error --------------------------------------------------------------
SID_NOMEMORY	equ	-1
SID_NOAUDIODEVICE	equ	-2
SID_NOCIATIMER	equ	-3
SID_NOPAUSE	equ	-4
SID_NOMODULE	equ	-5
SID_NOICON	equ	-6
SID_BADTOOLTYPE	equ	-7
SID_NOLIBRARY	equ	-8
SID_BADHEADER	equ	-9
SID_NOSONG	equ	-10
SID_LIBINUSE	equ	-11

; --- Playing Modes ------------------------------------------------------
PM_STOP		equ	0
PM_PLAY		equ	1
PM_PAUSE	equ	2

; --- Module Header ------------------------------------------------------

SID_HEADER	EQU	"PSID"
SID_VERSION	EQU	2
HEADERINFO_SIZE EQU	32

SID_SIDSONG	EQU	(0)
SIDF_SIDSONG	EQU	(1<<SID_SIDSONG)

		STRUCTURE SIDHeader,0
		ULONG	sidh_id
		UWORD	sidh_version
		UWORD	sidh_length
		UWORD	sidh_start
		UWORD	sidh_init
		UWORD	sidh_main
		UWORD	sidh_number
		UWORD	sidh_defsong
		ULONG	sidh_speed
		STRUCT	sidh_name,HEADERINFO_SIZE
		STRUCT	sidh_author,HEADERINFO_SIZE
		STRUCT	sidh_copyright,HEADERINFO_SIZE
		UWORD	sidh_flags
		ULONG	sidh_reserved
		LABEL	sidh_sizeof

	ENDC ; LIBRARIES_PLAYSIDBASE_I
