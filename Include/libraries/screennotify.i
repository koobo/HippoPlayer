	IFND	LIBRARIES_SCREENNOTIFY_I
LIBRARIES_SCREENNOTIFY_I	SET	1
**
**	$VER:	screennotify.i	V1.0	(26.1.97)
**
**	screennotify.library definitions
**
**	Rewritten to .i from the original .h file
**	By Nik / Nerve Axis
**

	IFND	EXEC_PORTS_I
	INCLUDE	"exec/ports.i"
	ENDC

;Name and version

SCREENNOTIFY_NAME	MACRO
			dc.b	'screennotify.library',0
			ENDM

;Message sent to clients

	STRUCTURE	ScreenNotifyMessage,0
	STRUCT	snm_Message,MN_SIZE
	ULONG	snm_Type		;READ ONLY!!
	APTR	snm_Value		;READ ONLY!!
	LABEL	snm_SIZEOF

;Values for snm_Type

SCREENNOTIFY_TYPE_CLOSESCREEN	EQU	0	;CloseScreen() called, snm_Value contains
						;pointer to Screen structure
SCREENNOTIFY_TYPE_PUBLICSCREEN	EQU	1	;PubScreenStatus() called to make screen
						;public, snm_Value contains pointer to
						;PubScreenNode structure
SCREENNOTIFY_TYPE_PRIVATESCREEN	EQU	2	;PubScreenStatus() called to make screen
						;private, snm_Value contains pointer to
						;PubScreenNode structure
SCREENNOTIFY_TYPE_WORKBENCH	EQU	3	;snm_Value == FALSE (0): CloseWorkBench()
						;called, please close windows on WB
						;snm_Value == TRUE  (1): OpenWorkBench()
						;called, windows can be opened again.

	ENDC	;LIBRARIES_SCRREENNOTIFY_I
