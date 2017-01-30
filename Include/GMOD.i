*** Header file used for creating and calling GMOD modules ***
* Public domain by Bryan Ford

	ifnd	BRY_GMOD_I
BRY_GMOD_I	set	1


	ifnd	EXEC_TYPES_I
	include "exec/types.i"
	endc


*** This is the layout of the first part of every GMOD module.
 STRUCTURE	GMOD,0
	; The first four longwords contain various important values.
	ULONG	gmod_ID			; Must be 'GMOD'
	ULONG	gmod_Maker		; ID of creator program (ASCII, like IFF ID's)
	ULONG	gmod_LoadAddress	; Address at which to load module (0L = any)
	ULONG	gmod_MaxVecOfs		; Offset of end of vector table (numvecs+4)*4

	; From here on are the entrypoints
	; (actual instructions, not just vector pointers)
	LONG	gmod_InitMusic		; Initialize the module
	LONG	gmod_StartMusic		; Start playing (d0.l = song number)
	LONG	gmod_StopMusic		; Stop playing
	LONG	gmod_EndMusic		; Shut down the module
	LONG	gmod_Reserved		; Pause
	LONG	gmod_ContinueMusic	; Restart after pause
	LONG	gmod_VBlank50		; VBlank interrupt (50Hz)
	LONG	gmod_VBlank60		; VBlank interrupt (60Hz)
	LONG	gmod_Channel0		; Channel 0 loaded interrupt
	LONG	gmod_Channel1		; Channel 1 loaded interrupt
	LONG	gmod_Channel2		; Channel 2 loaded interrupt
	LONG	gmod_Channel3		; Channel 3 loaded interrupt
	LONG	gmod_GetNumSongs	; Get number of songs (d0.l)
	LONG	gmod_GetSongName	; Get description of a song (d1.l) into (d0.p)
	LONG	gmod_GetSongAuthor	; Get the name of a song's author (d1.l) into (d0.p)
	LONG	gmod_GetFrequency	; Get the timing frequency for the song (d0.l)
	LONG	gmod_TimerTick		; Routine to call at specified frequency
	LONG	gmod_GetMakerName	; Get name of creator program
	LONG	gmod_Hook		; Specify a Hook to call on various events
	LONG	gmod_Jump		; Jump to sequence/time/whatever
	LABEL	gmod_SIZEOF		; Don't depend on this when playing a GMOD!

	; Flags for the gmod_Hook call - similar to Intuition's IDCMP flags
	BITDEF	GMODH,REPEAT,0		; Call when music repeats
	BITDEF	GMODH,SEQUENCE,1	; Call when sequence changes


*** Use these macros to help when playing GMOD modules.
*** All of them assume that the pointer to the GMOD module is in a5.

* Branch if a vector offset (gmod_xxx) is in range
gmodbin		macro	; DReg,label
		cmp.l	gmod_MaxVecOfs(a5),\1
		bcs	\2
		endm

* Branch if a vector offset (gmod_xxx) is out of range
gmodbout	macro	; DReg,label
		cmp.l	gmod_MaxVecOfs(a5),\1
		bcc	\2
		endm

* Call a GMOD vector WITHOUT checking - you must first make sure it's there!
gmodcall	macro	; DReg
		jsr	0(a5,\1)
		endm

* Same as gmodcall, but with an immediate (as opposed to register) vector offset
gmodcalli	macro	; Offset
		jsr	\1(a5)
		endm

* This is what you'll usually use when calling GMOD entrypoints -
* it first checks to make sure the entrypoint is available, THEN calls
* it.  The GMOD pointer must be in a5, and the vector offset must
* be in some data register.
gmodmaycall	macro	; DReg
		cmp.l	gmod_MaxVecOfs(a5),\1
		dc.w	$6404		; bra.s *+2
		gmodcall \1
		endm


*** Use these macros if you are DEFINING a GMOD header.  This makes it
*** easier if you don't happen to know the lengths of the various instructions
*** by memory.

* Do-nothing entrypoint - stick this in entrypoints you don't need or can't support
gmodnop		macro			; Do-nothing entry in a GMOD header
		rts
		nop
		endm

* Branch to some other location (makes the GMOD header act like a jump table)
gmodbra		macro	; <label>	; 4-byte branch.
		jmp	\1(pc)		; (Some assemblers would optimize down a bra.w.)
		endm

* The following macro is useful for a few entrypoints like GetNumSongs
* where you just need to return a small constant value.
gmodq		macro	; const		; Return quick constant
		moveq	#\1,d0
		rts
		endm

	endc
	
