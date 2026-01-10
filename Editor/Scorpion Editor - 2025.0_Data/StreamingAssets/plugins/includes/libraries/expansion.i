	IFND	LIBRARIES_EXPANSION_I
LIBRARIES_EXPANSION_I	SET	1
**
**	$VER: expansion.i 36.6 (5.11.90)
**	Includes Release 40.13
**
**	External definitions for expansion.library
**
**	(C) Copyright 1989-1993 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

	IFND	EXEC_TYPES_I
	INCLUDE	"exec/types.i"
	ENDC	;EXEC_TYPES_I



EXPANSIONNAME	MACRO
		dc.b	'expansion.library',0
		ENDM


;flag for the AddDosNode() call
	BITDEF	ADN,STARTPROC,0

	ENDC	;LIBRARIES_EXPANSION_I
