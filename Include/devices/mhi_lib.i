	IFND	LIBRARIES_MHI_LIB_I
LIBRARIES_MHI_LIB_I SET	1

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

;#pragma amicall(MHIBase,0x01E,MHIAllocDecoder(a0,d0))
;#pragma amicall(MHIBase,0x024,MHIFreeDecoder(a3))
;#pragma amicall(MHIBase,0x02A,MHIQueueBuffer(a3,a0,d0))
;#pragma amicall(MHIBase,0x030,MHIGetEmpty(a3))
;#pragma amicall(MHIBase,0x036,MHIGetStatus(a3))
;#pragma amicall(MHIBase,0x03C,MHIPlay(a3))
;#pragma amicall(MHIBase,0x042,MHIStop(a3))
;#pragma amicall(MHIBase,0x048,MHIPause(a3))
;#pragma amicall(MHIBase,0x04E,MHIQuery(d1))
;#pragma amicall(MHIBase,0x054,MHISetParam(a3,d0,d1))
	LIBINIT

    LIBDEF _LVOMHIAllocDecoder
    LIBDEF _LVOMHIFreeDecoder
    LIBDEF _LVOMHIQueueBuffer
    LIBDEF _LVOMHIGetEmpty
    LIBDEF _LVOMHIGetStatus
    LIBDEF _LVOMHIPlay
    LIBDEF _LVOMHIStop
    LIBDEF _LVOMHIPause
    LIBDEF _LVOMHIQuery
    LIBDEF _LVOMHISetParam

    ENDC