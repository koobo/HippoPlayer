** Include file containing S3M-format and stuff for Play S3M

	ifnd	S3M_I

S3M_I	set	1


	STRUCTURE chanblock,0
	UBYTE	nt
	UBYTE	inst
	UBYTE	vol
	UBYTE	cmd
	UBYTE	info
	UBYTE	flgs

	APTR	sample
	UWORD	period
	UWORD	volume
	UBYTE	note
	UBYTE	lastcmd

	UWORD	toperiod
	UBYTE	notepspd
	
	UBYTE	retrigcn
	UBYTE	vibcmd
	UBYTE	vibpos

	LABEL	cblocksize


	STRUCTURE s3minsform,0
	UBYTE	instype
	STRUCT	insdosname,12
	UBYTE	inssig1
	UWORD	insmemseg
	LONG	inslength
	LONG	insloopbeg
	LONG	insloopend
	UBYTE	insvol
	UBYTE	insdsk
	UBYTE	inspack
	UBYTE	insflags
	UWORD	insloc2spd
	UWORD	inshic2spd
	STRUCT	inssig2,4
	UWORD	insgvspos
	UWORD	insint512
	LONG	insintlastused
	STRUCT	insname,28
	STRUCT	inssig,4
	LABEL	s3mins_SIZE


	STRUCTURE s3mform,0
	STRUCT	name,28
	UBYTE	sig1
	UBYTE	type
	STRUCT	sig2,2
	UWORD	ordernum
	UWORD	insnum
	UWORD	patnum
	UWORD	flags
	UWORD	cwtv
	UWORD	ffv
	STRUCT	s3msig,4
	UBYTE	mastervol
	UBYTE	initialspeed
	UBYTE	initialtempo
	UBYTE	mastermul
	STRUCT	sig3,12
	STRUCT	chanset,32
	UBYTE	orders
	;UWORD	*parapins
	;UWORD   *parappat
	;STRUCT	s3minsform
	LABEL	s3mform_SIZE
	endc
