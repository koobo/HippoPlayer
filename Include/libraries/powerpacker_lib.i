	IFND	LIBRARIES_POWERPACKER_LIB_I
LIBRARIES_POWERPACKER_LIB_I SET	1
**
**	$Filename: libraries/powerpacker_lib.i $
**	$Release: 1.2 $
**
**	(C) Copyright 1991 Nico François
**	    All Rights Reserved
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

	LIBDEF _LVOppLoadData
	LIBDEF _LVOppDecrunchBuffer
	LIBDEF _LVOppCalcChecksum
	LIBDEF _LVOppCalcPasskey
	LIBDEF _LVOppDecrypt
	LIBDEF _LVOppGetPassword
	LIBDEF _LVOppOBSOLETE1
	LIBDEF _LVOppOBSOLETE2
	LIBDEF _LVOppDecrHdr             ; private!
	LIBDEF _LVOppCryptDecrHdr        ; private!
	LIBDEF _LVOppOverlayDecrHdr      ; private!
	LIBDEF _LVOppAllocCrunchInfo
	LIBDEF _LVOppFreeCrunchInfo
	LIBDEF _LVOppCrunchBuffer
	LIBDEF _LVOppWriteDataHeader
	LIBDEF _LVOppEnterPassword
	LIBDEF _LVOppPasswordCallback		; private!
	LIBDEF _LVOppErrorMessage

CALLPP	MACRO
	MOVE.L	_PPBase(pc),A6
	JSR	_LVO\1(A6)
	ENDM
	ENDC	; LIBRARIES_POWERPACKER_LIB_I
