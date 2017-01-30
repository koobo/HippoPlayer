	IFND	LIBRARIES_PLAYSID_LIB_I
LIBRARIES_PLAYSID_LIB_I SET	1
**
**	$Filename: libraries/playsid_lib.i $
**	$Release: 1.0 $
**
**	(C) Copyright 1994 Per Håkan Sundell and Ron Birk
**	All Rights Reserved
**

	IFND    EXEC_TYPES_I
	include "exec/types.i"
	ENDC
	IFND    EXEC_NODES_I
	include "exec/nodes.i"
	ENDC
	IFND    EXEC_LISTS_I
	include "exec/lists.i"
	ENDC
	IFND    EXEC_LIBRARIES_I
	include "exec/libraries.i"
	ENDC

	LIBINIT

	LIBDEF _LVOAllocEmulResource
	LIBDEF _LVOFreeEmulResource
	LIBDEF _LVOReadIcon
	LIBDEF _LVOCheckModule
	LIBDEF _LVOSetModule
	LIBDEF _LVOStartSong
	LIBDEF _LVOStopSong
	LIBDEF _LVOPauseSong
	LIBDEF _LVOContinueSong
	LIBDEF _LVOForwardSong
	LIBDEF _LVORewindSong
	LIBDEF _LVOSetVertFreq
	LIBDEF _LVOSetChannelEnable
	LIBDEF _LVOSetReverseEnable
	LIBDEF _LVOSetTimeSignal
	LIBDEF _LVOSetTimeEnable
	LIBDEF _LVOSetDisplaySignal
	LIBDEF _LVOSetDisplayEnable

CALLPLAYSID	MACRO
	move.l	_PlaySidBase,a6
	jsr	_LVO\1(a6)
	ENDM

	ENDC	; LIBRARIES_PLAYSID_LIB_I

