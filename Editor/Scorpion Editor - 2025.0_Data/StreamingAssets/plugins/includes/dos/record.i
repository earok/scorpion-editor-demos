	IFND DOS_RECORD_I
DOS_RECORD_I SET 1
**
**	$VER: record.i 36.5 (12.7.90)
**	Includes Release 40.13
**
**	include file for record locking
**
**	(C) Copyright 1989-1993 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

     IFND  DOS_DOS_I
     INCLUDE "dos/dos.i"
     ENDC

* Modes for LockRecord/LockRecords()
REC_EXCLUSIVE		EQU	0
REC_EXCLUSIVE_IMMED	EQU	1
REC_SHARED		EQU	2
REC_SHARED_IMMED	EQU	3

* struct to be passed to LockRecords()/UnLockRecords()

 STRUCTURE RecordLock,0
	BPTR	rec_FH		; filehandle
	ULONG	rec_Offset	; offset in file
	ULONG	rec_Length	; length of file to be locked
	ULONG	rec_Mode	; Type of lock
 LABEL RecordLock_SIZEOF

	ENDC	; DOS_RECORD_I

