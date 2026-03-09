****************
* Omia makroja *
* K-P **********

FALSE	=	0
TRUE	=	1

lob	macro
	jsr	_LVO\1(a6)
	endm

loab	macro
	ifc	"\1","Exec"
	move.l	4.w,a6
	else
	move.l	_\1Base,a6
	endc
	jsr	_LVO\2(a6)
	endm

lopc	macro
	ifc	"\1","Exec"
	move.l	4.w,a6
	else
	move.l	_\1Base(pc),a6
	endc
	jsr	_LVO\2(a6)
	endm

lore	macro
	ifc	"\1","Exec"
	ifd	_ExecBase
	ifeq	_ExecBase
	move.l	(a5),a6
	else
	move.l	_ExecBase(a5),a6
	endc
	else
	move.l	4.w,a6
	endc
	else
	move.l	_\1Base(a5),a6
	endc
	jsr	_LVO\2(a6)
	endm


pushm	macro
	ifc	"\1","all"
	movem.l	d0-a6,-(sp)
	else
	movem.l	\1,-(sp)
	endc
	endm

popm	macro
	ifc	"\1","all"
	movem.l	(sp)+,d0-a6
	else
	movem.l	(sp)+,\1
	endc
	endm

push	macro
	move.l	\1,-(sp)
	endm

pop	macro
	move.l	(sp)+,\1
	endm

pushpea	macro
	pea	\1
	move.l	(sp)+,\2
	endm
