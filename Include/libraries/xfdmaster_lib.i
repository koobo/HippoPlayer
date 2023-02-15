	IFND	LIBRARIES_XFDMASTER_LIB_I
LIBRARIES_XFDMASTER_LIB_I	SET	1

**
**	$VER: xfdmaster_lib.i 37.1 (28.2.96)
**
**	Copyright © 1994-96 by Georg Hörmann
**	All Rights Reserved
**

	IFND EXEC_LIBRARIES_I
	include "exec/libraries.i"
	ENDC

;======================================================================
; LVO Definitions
;======================================================================

	LIBINIT
	LIBDEF	_LVOxfdAllocBufferInfo		; obsolete: use xfdAllocObject()
	LIBDEF	_LVOxfdFreeBufferInfo		; obsolete: use xfdFreeObject()
	LIBDEF	_LVOxfdAllocSegmentInfo		; obsolete: use xfdAllocObject()
	LIBDEF	_LVOxfdFreeSegmentInfo		; obsolete: use xfdFreeObject()
	LIBDEF	_LVOxfdRecogBuffer
	LIBDEF	_LVOxfdDecrunchBuffer
	LIBDEF	_LVOxfdRecogSegment
	LIBDEF	_LVOxfdDecrunchSegment
	LIBDEF	_LVOxfdGetErrorText
	LIBDEF	_LVOxfdTestHunkStructure	; obsolete: use xfdTestHunkStructureNew()
; New for V34
	LIBDEF	_LVOxfdTestHunkStructureNew	; obsolete: use xfdTestHunkStructureFlags()
	LIBDEF	_LVOxfdRelocate
; New for V36
	LIBDEF	_LVOxfdTestHunkStructureFlags
	LIBDEF	_LVOxfdStripHunks
	LIBDEF	_LVOxfdAllocObject
	LIBDEF	_LVOxfdFreeObject
	LIBDEF	_LVOxfdRecogLinker
	LIBDEF	_LVOxfdUnlink
; New for V37
	LIBDEF	_LVOxfdScanData
	LIBDEF	_LVOxfdFreeScanList
	LIBDEF	_LVOxfdObjectType
	LIBDEF	_LVOxfdInitScanHook

	ENDC	; LIBRARIES_XFDMASTER_LIB_I
