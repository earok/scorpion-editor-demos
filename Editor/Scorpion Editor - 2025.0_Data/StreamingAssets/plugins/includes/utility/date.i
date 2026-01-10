	IFND UTILITY_DATE_I
UTILITY_DATE_I	SET	1
**
**	$VER: date.i 39.1 (20.1.92)
**	Includes Release 40.13
**
**	Date conversion routines ClockData definition.
**
**	(C) Copyright 1989-1993 Commodore-Amiga Inc.
**	All Rights Reserved
**

;---------------------------------------------------------------------------

	IFND EXEC_TYPES_I
	INCLUDE	"exec/types.i"
	ENDC

;---------------------------------------------------------------------------

   STRUCTURE CLOCKDATA,0
	UWORD	sec
	UWORD	min
	UWORD	hour
	UWORD	mday
	UWORD	month
	UWORD	year
	UWORD	wday
   LABEL CD_SIZE

;---------------------------------------------------------------------------

	ENDC	; UTILITY_DATE_I
