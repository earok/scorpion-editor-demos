;*---------------------------------------------------------------------------
;  :Modul.	kickfs.s
;  :Contents.	filesystem handler for kick emulation under WHDLoad
;  :Author.	Wepl, JOTD, Psygore
;  :Version.	$Id: kickfs.s 1.28 2024/06/11 00:53:28 wepl Exp wepl $
;  :History.	17.04.02 separated from kick13.s
;		02.05.02 _cb_dosRead added
;		09.05.02 symbols moved to the top for Asm-One/Pro
;		04.03.03 ACTION_COPY_DIR fixed, wb double click works now
;			 deleting of directories works clean
;			 changes by JOTD merged
;		04.04.03 various changes for kick31
;		11.07.03 relative object names now supported (e.g. "dh0:s//c/info")
;		06.08.03 sanity check for provided locks added (DEBUG)
;		09.08.03 ACTION_CURRENT_VOLUME added (JOTD)
;		01.09.03 ACTION_EXAMINE_FH fixed (Psygore)
;		29.04.04 ACTION_CREATE_DIR returns ERROR_OBJECT_EXISTS if exists
;		06.10.04 checks for startup-sequence if not BOOTDOS (JOTD)
;		17.10.04 set IoErr on Seek on success to be more system conform
;		26.11.04 set IoErr on Read on success to be more system conform
;			 ACTION_SET_COMMENT dummy added
;		08.02.05 ACTION_ADD_NOTIFY dummy added
;		04.05.06 fix for startup packet under v34
;			 ACTION_SET_DATE dummy added
;		07.11.07 when DEBUG is set and there is no memory for IOCACHE it
;			 faults with _debug5
;		12.08.09 now properly supports read and write on the same fh when
;			 using IOCACHE (flushs cache added), some comments added
;		16.08.09 flushing IOCACHE wasn't correct handled, fixed
;		12.01.14 minor optimizations
;		29.01.14 SNOOPFS added
;		07.03.18 IOCACHE handling fixed, if a write doesn't fit into the
;			 cache after a previous cached write the cache is now
;			 flushed before the actual write - this preserves the
;			 sequence and avoids possible WHDLoad switches because
;			 performing a resload_SaveFileOffset on not yet existing
;			 file offset
;		10.05.20 if Kickstart v37 is present ACTION_FIND_UPDATE now
;			 creates a nonexistent file
;		02.10.22 flush cache on write if cache is completely filled
;		07.06.24 added ACTION_RENAME_DISK
;		10.06.24 avoid writing special files
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9, Asm-Pro 1.16, PhxAss 4.38
;  :To Do.	more dos packets (maybe)
;  :Notes.	it should be remembered that MODE_READWRITE on dos.Open works
;		different in 1.3 (opens only existing files) and 2.0 (creates
;		files not existing), this makes no diff for kickfs, code is in
;		dos.library
;---------------------------------------------------------------------------*

	INCLUDE	lvo/expansion.i
	INCLUDE	dos/dosextens.i
	INCLUDE	dos/filehandler.i
	INCLUDE	exec/resident.i
	INCLUDE	libraries/configvars.i
	INCLUDE	libraries/expansionbase.i

	IFD SNOOPFS
	IFLT slv_Version-18
	FAIL SNOOPFS require slv_Version >= 18
	ENDC
	ENDC

;---------------------------------------------------------------------------*
;
; BootNode
; 08 LN_TYPE = NT_BOOTNODE
; 0a LN_NAME -> ConfigDev
;		10 cd_Rom+er_Type = ERTF_DIAGVALID
;		1c cd_Rom+er_Reserved0c -> DiagArea
;					   00 da_Config = DAC_CONFIGTIME
;					   06 da_BootPoint -> .bootcode
;					   0e da_SIZEOF
;		44 cd_SIZEOF
; 10 bn_DeviceNode -> DeviceNode (exp.MakeDosNode)
*		      04 dn_Type = 2
;		      24 dn_SegList -> .seglist
;		      2c dn_SIZEOF
; 14 bn_SIZEOF

	IFND HD_Cyls
HD_Cyls			= 80
	ENDC
HD_Surfaces		= 2
HD_BlocksPerTrack	= 11
HD_NumBlocksRes		= 2
HD_NumBlocks		= HD_Cyls*HD_Surfaces*HD_BlocksPerTrack-HD_NumBlocksRes
HD_NumBlocksUsed	= HD_NumBlocks/2
HD_BytesPerBlock	= 512
HD_NumBuffers		= 5

	;file locking is not implemented! no locklist is used
	;fl_Key is used for the filename which makes it impossible to compare two locks for equality!

	STRUCTURE MyLock,fl_SIZEOF
		LONG	mfl_pos			;position in file
		STRUCT	mfl_fib,fib_Reserved	;FileInfoBlock
	IFD IOCACHE
		LONG	mfl_cpos		;fileoffset cache points to, -1 means nothing cached
		LONG	mfl_clen		;amount of dirty data in cache
						;on read cache this is 0 and cache if filled completely
						;on write this is the amount of cached data
						;reads and writes can be mixed, the cache not!
		LONG	mfl_iocache		;pointer to cache memory
	ENDC
		LABEL	mfl_SIZEOF

;---------------------------------------------------------------------------*

		movem.l	d0-a6,-(a7)

	IFND	BOOTDOS
		lea	(ss_name,pc),a0
		move.l	(_resload,pc),a2
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		bne	.ssok
		pea	(ss_name,pc)
		pea	ERROR_OBJECT_NOT_FOUND
		pea	TDREASON_DOSREAD
		jmp	(resload_Abort,a2)
.ssok
	ENDC

		moveq	#ConfigDev_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		move.l	(4),a6
		jsr	(_LVOAllocMem,a6)
		move.l	d0,a5				;A5 = ConfigDev
		bset	#ERTB_DIAGVALID,(cd_Rom+er_Type,a5)
		lea	(.diagarea,pc),a0
		move.l	a0,(cd_Rom+er_Reserved0c,a5)

		lea	(.expansionname,pc),a1
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a4				;A4 = expansionbase

		lea	(.parameterPkt+8,pc),a0
		lea	(.devicename,pc),a1
		move.l	a1,-(a0)
		lea	(.handlername,pc),a1
		move.l	a1,-(a0)
		exg.l	a4,a6
		jsr	(_LVOMakeDosNode,a6)
		exg.l	a4,a6
		move.l	d0,a3				;A3 = DeviceNode
		lea	(.seglist,pc),a1
		move.l	a1,d1
		lsr.l	#2,d1
		move.l	d1,(dn_SegList,a3)
		moveq	#-1,d0
		move.l	d0,(dn_GlobalVec,a3)		;no BCPL shit

		moveq	#BootNode_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		jsr	(_LVOAllocMem,a6)
		move.l	d0,a1				;BootNode
		move.b	#NT_BOOTNODE,(LN_TYPE,a1)
		move.l	a5,(LN_NAME,a1)			;ConfigDev
		move.l	a3,(bn_DeviceNode,a1)

		lea	(eb_MountList,a4),a0
		jsr	(_LVOEnqueue,a6)

		movem.l	(a7)+,d0-a6
		rts

.diagarea	dc.b	DAC_CONFIGTIME		;da_Config
		dc.b	0			;da_Flags
		dc.w	0			;da_Size
		dc.w	0			;da_DiagPoint
		dc.w	.bootcode-.diagarea	;da_BootPoint
		dc.w	0			;da_Name
		dc.w	0			;da_Reserved01
		dc.w	0			;da_Reserved02

.parameterPkt	dc.l	0			;name of dos handler
		dc.l	0			;name of exec device
		dc.l	0			;unit number for OpenDevice
		dc.l	0			;flags for OpenDevice
		dc.l	16			;de_TableSize count following longwords
		dc.l	HD_BytesPerBlock/4	;de_SizeBlock longs per block
		dc.l	0			;de_SecOrg sector start, unused
		dc.l	HD_Surfaces		;de_Surfaces
		dc.l	1			;de_SectorPerBlock unused
		dc.l	HD_BlocksPerTrack	;de_BlocksPerTrack
		dc.l	HD_NumBlocksRes		;de_Reserved reserved blocks
		dc.l	0			;de_PreAlloc unused
		dc.l	0			;de_Interleave
		dc.l	0			;de_LowCyl
		dc.l	HD_Cyls-1		;de_HighCyl
		dc.l	HD_NumBuffers		;de_NumBuffers
		dc.l	MEMF_PUBLIC		;de_BufMemType
		dc.l	MAXINT			;de_MaxTransfer
		dc.l	-1			;de_Mask
		dc.l	0			;de_BootPri
		dc.l	ID_DOS_DISK		;de_DosType
	;	dc.l				;de_Baud
	;	dc.l				;de_Control
	;	dc.l				;de_BootBlocks
	EVEN

.bootcode	lea	(_dosname,pc),a1
		jsr	(_LVOFindResident,a6)
		move.l	d0,a0
		move.l	(RT_INIT,a0),a0
		jmp	(a0)			;init dos.library

	CNOP 0,4
		dc.l	16			;segment length
.seglist	dc.l	0			;next segment

	;get own message port
		move.l	(4),a6			;A6 = execbase
		sub.l	a1,a1
		jsr	(_LVOFindTask,a6)
		move.l	d0,a1
		lea	(pr_MsgPort,a1),a5	;A5 = MsgPort

	;init volume structure
		lea	(.volumename,pc),a0
		move.l	a0,d0
		lsr.l	#2,d0
		move.l	d0,-(a7)		;dl_Name
		clr.l	-(a7)			;dl_unused
		move.l	#ID_DOS_DISK,-(a7)	;dl_DiskType (is normally 0!)
		clr.l	-(a7)			;dl_LockList
		clr.l	-(a7)			;dl_VolumeDate
		clr.l	-(a7)			;dl_VolumeDate
		clr.l	-(a7)			;dl_VolumeDate
		clr.l	-(a7)			;dl_Lock
		move.l	a5,-(a7)		;dl_Task (MsgPort)
		move.l	#DLT_VOLUME,-(a7)	;dl_Type
		clr.l	-(a7)			;dl_Next
		move.l	a7,d0
		lsr.l	#2,d0
		move.l	d0,a3			;A3 = Volume (BPTR)
	;add to the system
		lea	(_dosname,pc),a1
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a0
		move.l	(dl_Root,a0),a0
		move.l	(rn_Info,a0),a0
		add.l	a0,a0
		add.l	a0,a0
		move.l	(di_DevInfo,a0),(dol_Next,a7)
		move.l	a3,(di_DevInfo,a0)

		move.l	(_resload,pc),a2	;A2 = resload

	;fetch and reply startup message
		move.l	a5,a0
		jsr	(_LVOWaitPort,a6)
		move.l	a5,a0
		jsr	(_LVOGetMsg,a6)
		move.l	d0,a4
		move.l	(LN_NAME,a4),a4		;A4 = DosPacket
	IFEQ 1
	;I don't remember that was good for, but it fails under
	;v34 because dp_Arg3 is NULL
		move.l	(dp_Arg3,a4),d0		;DeviceNode
		beq	.nodn			;not present under v34
		lsl.l	#2,d0
		move.l	d0,a0
		move.l  a5,(dn_Task,a0)	        ;signal: the handler is running
.nodn
	ENDC
	IFD SNOOPFS
		clr.l	-(a7)			;place for function infos
	ENDC
		bra	.reply1true

	;loop on receiving new packets
.mainloop
	IFD SNOOPFS
	;log the message
		move.w	(a7),d2			;skip startup package
		beq	.skipsnoop
		move.l	(dp_Arg5,a4),-(a7)
		move.l	(dp_Arg4,a4),-(a7)
		move.l	(dp_Arg3,a4),-(a7)
		move.l	(dp_Arg2,a4),-(a7)
		move.l	(dp_Arg1,a4),-(a7)
		move.l	(dp_Res2,a4),-(a7)
		move.l	(dp_Res1,a4),-(a7)
		pea	(.snoopfshead,pc)
		lea	(.action,pc,d2.w),a0
		jsr	(resload_Log,a2)
		add.w	#8*4,a7
.skipsnoop
	ENDC
		move.l	a5,a0
		jsr	(_LVOWaitPort,a6)
		move.l	a5,a0
		jsr	(_LVOGetMsg,a6)
		move.l	d0,a4
		move.l	(LN_NAME,a4),a4		;A4 = DosPacket

	;find and call appropriate action
		moveq	#0,d0
		move.l	(dp_Type,a4),d4
		lea	(.action,pc),a0
	IFND SNOOPFS
.next		movem.w	(a0)+,d0-d1
	ELSE
.next		movem.w	(a0)+,d0-d2
		move.w	d2,(a7)			;save
	ENDC
	IFD DEBUG
		tst.l	d0
		beq	_debug1			;unknown packet
	ENDC
		cmp.w	d0,d4			;this should be cmp.l
		bne	.next
		jmp	(.action,pc,d1.w)

KFSDPKT	MACRO
		dc.w	ACTION_\1
		dc.w	.a_\2-.action
	IFD SNOOPFS
		dc.w	.f_\2-.action
	ENDC
	ENDM

	CNOP 0,4
.action		KFSDPKT	CURRENT_VOLUME,current_volume	      ;7      7
		KFSDPKT	LOCATE_OBJECT,locate_object	      ;8      8
		KFSDPKT	RENAME_DISK,rename_disk		      ;9      9
		KFSDPKT	FREE_LOCK,free_lock		      ;f      15
		KFSDPKT	DELETE_OBJECT,delete_object	      ;10     16
		KFSDPKT	COPY_DIR,copy_dir		      ;13     19
		KFSDPKT	SET_PROTECT,set_protect		      ;15     21
		KFSDPKT	CREATE_DIR,create_dir		      ;16     22
		KFSDPKT	EXAMINE_OBJECT,examine_object	      ;17     23
		KFSDPKT	EXAMINE_NEXT,examine_next	      ;18     24
		KFSDPKT	DISK_INFO,disk_info		      ;19     25
		KFSDPKT	INFO,info			      ;1a     26
		KFSDPKT	FLUSH,flush			      ;1b     27
		KFSDPKT	SET_COMMENT,set_comment		      ;1c     28
		KFSDPKT	PARENT,parent			      ;1d     29
		KFSDPKT	INHIBIT,inhibit			      ;1f     31
		KFSDPKT	SET_DATE,set_date		      ;22     34
		KFSDPKT	READ,read			      ;52     82
		KFSDPKT	WRITE,write			      ;57     87
		KFSDPKT	FINDUPDATE,findupdate		      ;3ec    1004
		KFSDPKT	FINDINPUT,findinput		      ;3ed    1005
		KFSDPKT	FINDOUTPUT,findoutput		      ;3ee    1006
		KFSDPKT	END,end				      ;3ef    1007
		KFSDPKT	SEEK,seek			      ;3f0    1008
	IFGT KICKVERSION-36
		KFSDPKT	SAME_LOCK,same_lock		      ;28     40
		KFSDPKT	FH_FROM_LOCK,fh_from_lock	      ;402    1026
		KFSDPKT	IS_FILESYSTEM,is_filesystem	      ;403    1027
		KFSDPKT	EXAMINE_ALL,examine_all		      ;409    1033
		KFSDPKT	EXAMINE_FH,examine_fh		      ;40A    1034
		KFSDPKT	ADD_NOTIFY,add_notify		      ;1001   4097
	ENDC
		dc.w	0

;---------------
; reply dos-packet
; IN:	D0 = res1
;	D1 = res2

.reply2		move.l	d1,(dp_Res2,a4)

;---------------
; reply dos-packet
; IN:	D0 = res1

.reply1		move.l	d0,(dp_Res1,a4)
		move.l	(dp_Port,a4),a0
		move.l	(dp_Link,a4),a1
		move.l	a5,(dp_Port,a4)
		jsr	(_LVOPutMsg,a6)
		bra	.mainloop

	; conventions for action functions:
	; IN:	a2 = resload
	;	a3 = BPTR volume node
	;	a4 = packet
	;	a5 = MsgPort
	;	a6 = execbase

;---------------
; IN:	dp_Arg1 = BPTR new volume name

.a_rename_disk	move.l	#ERROR_DISK_WRITE_PROTECTED,d1
		move.l	#DOSFALSE,d0
		bra	.reply2

;---------------

.a_current_volume
		move.l	a3,d0			;volume
		moveq	#0,d1			;unit number
		bra	.reply2
	
;---------------

.a_locate_object
		bsr	.getarg1		;lock
		move.l	d7,d0
		bsr	.getarg2		;name
		move.l	d7,d1
		move.l	(dp_Arg3,a4),d2		;mode
		bsr	.lock
		lsr.l	#2,d0			;APTR > BPTR
		bne	.reply1
		bra	.reply2

;---------------

.a_free_lock	bsr	.getarg1
		move.l	d7,d0
		bsr	.unlock
		bra	.reply1true

;---------------

.a_delete_object
		bsr	.getarg1		;lock
		move.l	d7,d0
		bsr	.getarg2		;name
		move.l	d7,d1
		move.l	#ACCESS_READ,d2
		bsr	.lock
		move.l	d0,d7			;d7 = new lock
		beq	.reply2
		move.l	d0,a0
		tst.l	(mfl_fib+fib_DirEntryType,a0)
		bmi	.delete_do
	;a directory
		lea	(mfl_fib,a0),a0
		jsr	(resload_ExNext,a2)
		tst.l	d0
		bne	.delete_dirnotempty
		move.l	d7,a0
.delete_do	move.l	(fl_Key,a0),a0
		jsr	(resload_DeleteFile,a2)
		move.l	d7,d0
		bsr	.unlock
		bra	.reply1true

.delete_dirnotempty
		move.l	d7,d0
		bsr	.unlock
		moveq	#DOSFALSE,d0
		move.l	#ERROR_DIRECTORY_NOT_EMPTY,d1
		bra	.reply2

;---------------

.a_copy_dir	bsr	.getarg1
	IFD DEBUG
		beq	_debug2
	ENDC
	;copy name
		move.l	d7,a0			;a0 = APTR lock
	IFD DEBUG
		cmp.l	(fl_Task,a0),a5
		bne	_debug4
	ENDC
		move.l	(fl_Key,a0),a0		;name
		move.l	-(a0),d0
		moveq	#0,d1
		jsr	(_LVOAllocMem,a6)
		move.l	d0,d2			;d2 = new name
		beq	.copy_dir_nm
		move.l	d7,a0
		move.l	(fl_Key,a0),a0
		move.l	d2,a1
		move.l	-(a0),d0		;length
.copy_dir_cpy	move.l	(a0)+,(a1)+
		subq.l	#4,d0
		bhi	.copy_dir_cpy
	;copy lock
		move.l	#mfl_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		jsr	(_LVOAllocMem,a6)
		tst.l	d0
		beq	.copy_dir_nm2
	;fill lock structure
		move.l	d7,a0
		move.l	d0,a1
		move.l	(a0)+,(a1)+		;fl_Link
		addq.l	#4,d2
		move.l	d2,(a1)+		;fl_Key (name)
		addq.l	#4,a0
		move.l	(a0)+,(a1)+		;fl_Access
		move.l	(a0)+,(a1)+		;fl_Task (MsgPort)
		move.l	(a0)+,(a1)+		;fl_Volume
		lsr.l	#2,d0			;lock
		bra	.reply1

.copy_dir_nm2	move.l	d2,a1
		move.l	(a1),d0
		jsr	(_LVOFreeMem,a6)
.copy_dir_nm	moveq	#DOSFALSE,d0
		move.l	#ERROR_NO_FREE_STORE,d1
		bra	.reply2

;---------------

.a_create_dir	bsr	.getarg1
		move.l	d7,d0			;APTR lock
		bsr	.getarg2
		move.l	d7,d1			;BSTR name
		moveq	#ACCESS_READ,d2		;mode
		bsr	.lock
		tst.l	d0
		beq	.createdir_full
		bsr	.unlock
		moveq	#0,d0
		move.l	#ERROR_OBJECT_EXISTS,d1
		bra	.reply2
.createdir_full move.l	#ERROR_DISK_FULL,d1
		bra	.reply2

;---------------

	IFGT KICKVERSION-36
.a_examine_fh	move.l	(dp_Arg1,a4),a0		;lock
		bra	.a_examine
	ENDC

.a_examine_object
		bsr	.getarg1
		move.l	d7,a0			;a0 = APTR lock

.a_examine	bsr	.getarg2		;d7 = APTR fib
		move.l	a0,d0
		beq	.examine_root
	;copy whdload's examine result
		add.w	#mfl_fib,a0
		move.l	d7,a1
		moveq	#fib_Reserved/4-1,d0
.examine_fib	move.l	(a0)+,(a1)+
		dbf	d0,.examine_fib
	;adjust
.examine_adj
	;convert CSTR -> BSTR
		move.l	d7,a1
		lea	(fib_FileName,a1),a0
		bsr	.bstr
		lea	(fib_Comment,a1),a0
		bsr	.bstr
	;return
		bra	.reply1true

	;special handling of NULL lock
.examine_root	clr.l	-(a7)
		move.l	a7,a0
		move.l	d7,a1
		jsr	(resload_Examine,a2)
		addq.l	#4,a7
		lea	(.volumename+1,pc),a0	;CPTR
		move.l	d7,a1
		add.w	#fib_FileName,a1
.examine_root2	move.b	(a0)+,(a1)+
		bne	.examine_root2
		bra	.examine_adj

;---------------

.a_examine_next	bsr	.getarg2
		move.l	d7,a0			;a0 = APTR fib
		jsr	(resload_ExNext,a2)
		move.l	d7,a1
	;convert CSTR -> BSTR
		lea	(fib_FileName,a1),a0
		bsr	.bstr
		lea	(fib_Comment,a1),a0
		bsr	.bstr
		bra	.reply2

;---------------

.a_info		bsr	.getarg2
		bra	.a_disk_info_1

;---------------

.a_disk_info	bsr	.getarg1
.a_disk_info_1	move.l	d7,a0
		clr.l	(a0)+			;id_NumSoftErrors
		clr.l	(a0)+			;id_UnitNumber
		move.l	#ID_VALIDATED,(a0)+	;id_DiskState
		move.l	#HD_NumBlocks,(a0)+	;id_NumBlocks
		move.l	#HD_NumBlocksUsed,(a0)+	;id_NumBlocksUsed
		move.l	#HD_BytesPerBlock,(a0)+	;id_BytesPerBlock
		move.l	#ID_DOS_DISK,(a0)+	;id_DiskType
		move.l	a3,(a0)+		;id_VolumeNode
		clr.l	(a0)+			;id_InUse

;---------------

.a_is_filesystem
.a_set_protect
.a_set_comment
.a_set_date
.a_flush
.a_inhibit
.reply1true	moveq	#DOSTRUE,d0
		bra	.reply1

;---------------

.a_parent	bsr	.getarg1
		beq	.parent_root
		move.l	d7,a0			;d7 = lock
	IFD DEBUG
		cmp.l	(fl_Task,a0),a5
		bne	_debug4
	ENDC
		move.l	(fl_Key,a0),a0
		tst.b	(a0)
		beq	.parent_root
	;get string length
		moveq	#-1,d0
.parent_strlen	addq.l	#1,d0
		tst.b	(a0)+
		bne	.parent_strlen		;d0 = strlen
	;search for "/"
		move.l	d7,a0
		move.l	(fl_Key,a0),a0
		lea	(a0,d0.l),a1
.parent_search	cmp.b	#"/",-(a1)
		beq	.parent_slash
		cmp.l	a0,a1
		bne	.parent_search
	;no slash found, so we are locking root
	;lock the parent directory
.parent_slash
	;build temporary bstr
		move.l	a1,d0
		sub.l	a0,d0			;length
		move.l	d0,d3
		addq.l	#4,d3			;+1 and align4
		and.b	#$fc,d3
		sub.l	d3,a7
		move.l	a7,a1
		move.b	d0,(a1)+
.parent_cpy	move.b	(a0)+,(a1)+
		subq.l	#1,d0
		bhi	.parent_cpy
	;lock it
		moveq	#0,d0			;lock
		move.l	a7,d1			;name
		move.l	#ACCESS_READ,d2		;mode
		bsr	.lock
		add.l	d3,a7
		lsr.l	#2,d0			;APTR > BPTR
		bne	.reply1
		bra	.reply2
	;that is a special case!
.parent_root	moveq	#0,d0
		moveq	#0,d1
		bra	.reply2

;---------------

	IFGT KICKVERSION-36
.a_same_lock	bsr	.getarg1
		move.l	d7,a0
		bsr	.getarg2
		move.l	d7,a1
		move.l	a0,d0
		beq	.samelock_zero
	IFD DEBUG
		cmp.l	(fl_Task,a0),a5
		bne	_debug4
	ENDC
		move.l	(fl_Key,a0),a0
		tst.b	(a0)
		beq	.samelock_zero
		move.l	a1,d0
		beq	.samelock_neq
	IFD DEBUG
		cmp.l	(fl_Task,a1),a5
		bne	_debug4
	ENDC
		move.l	(fl_Key,a1),a1
.samelock_cmp	move.b	(a0)+,d0
		cmp.b	(a1)+,d0
		bne	.samelock_neq
		tst.b	d0
		bne	.samelock_cmp
.samelock_equ   bra	.reply1true

.samelock_zero	move.l	a1,d0
		beq	.samelock_equ
		move.l	(fl_Key,a1),a1
		tst.b	(a1)
		beq	.samelock_equ
.samelock_neq	moveq	#0,d0
		moveq	#0,d1
		bra	.reply2
	ENDC

;---------------

.a_read		move.l	(dp_Arg1,a4),a0			;a0 = APTR lock
	IFD DEBUG
		cmp.l	(fl_Task,a0),a5
		bne	_debug4
	ENDC
		move.l	(dp_Arg3,a4),d3			;d3 = readsize
	IFD IOCACHE
		moveq	#0,d4				;d4 = readcachesize
		bsr	.flush_write_cache		;cannot mix read/write, sets a0 again
	ENDC
		move.l	(mfl_pos,a0),d5			;d5 = pos
	;correct readsize if necessary
		move.l	(mfl_fib+fib_Size,a0),d2
		sub.l	d5,d2				;d2 = bytes left in file
		cmp.l	d2,d3
		bls	.read_ok
		move.l	d2,d3				;d3 = readsize
.read_ok	tst.l	d3
		beq	.read_end			;eof
		add.l	d3,(mfl_pos,a0)
	IFD BOOTDOS
	;special files
		move.l	(fl_Key,a0),a0			;name
		bsr	.specialfile
		tst.l	d0
		beq	.read_nospec
		move.l	d0,a0
		add.l	d5,a0				;source
		move.l	(dp_Arg2,a4),a1			;destination
		move.l	d3,d0
.read_spec	move.b	(a0)+,(a1)+
		subq.l	#1,d0
		bne	.read_spec
		bra	.read_end
.read_nospec	move.l	(dp_Arg1,a4),a0
	ENDC
	IFND IOCACHE
	;read direct
		move.l	d3,d0				;length
		move.l	d5,d1				;offset
		move.l	(fl_Key,a0),a0			;name
		move.l	(dp_Arg2,a4),a1			;buffer
		jsr	(resload_LoadFileOffset,a2)
	;finish
.read_end	move.l	d3,d0				;bytes read
		moveq	#0,d1				;no error
	IFD CBDOSREAD
		movem.l	d0-a6,-(a7)
		move.l	(dp_Arg1,a4),a0
		move.l	(mfl_pos,a0),d1
		sub.l	d0,d1				;file pos
		move.l	(fl_Key,a0),a0			;name
		move.l	(dp_Arg2,a4),a1			;buffer
		bsr	_cb_dosRead
		movem.l	(a7)+,d0-a6
	ENDC
		bra	.reply2
	ELSE
		move.l	#IOCACHE,d7			;d7 = IOCACHE
		move.l	(mfl_cpos,a0),d6		;d6 = cachepos
		bmi	.read_1				;skip if nothing cached yet
	;try from cache
		cmp.l	d5,d6				;pos to read higher than in cache?
		bhi	.read_1
		move.l	d7,d0
		add.l	d6,d0
		sub.l	d5,d0				;pos to read lower then end in cache?
		bls	.read_1
		move.l	d0,d4				;d4 = readcachesize
		cmp.l	d4,d3
		bhi	.read_2
		move.l	d3,d4				;fully from cache
.read_2		move.l	(mfl_iocache,a0),a0
		add.l	d5,a0
		sub.l	d6,a0				;source
		move.l	(dp_Arg2,a4),a1			;destination
		move.l	d4,d0
.read_3		move.b	(a0)+,(a1)+
		subq.l	#1,d0
		bne	.read_3
		add.l	d4,d5
		sub.l	d4,d2
		sub.l	d4,d3
		beq	.read_end
	;decide if read through cache or direct
.read_1		cmp.l	d7,d3				;fits remaining data to read into cache?
		blo	.read_c
	;read direct
.read_d		move.l	d3,d0				;length
		move.l	d5,d1				;offset
		move.l	(dp_Arg1,a4),a0
		move.l	(fl_Key,a0),a0			;name
		move.l	(dp_Arg2,a4),a1			;buffer
		add.l	d4,a1
		jsr	(resload_LoadFileOffset,a2)
		bra	.read_end
	;read through cache
.read_c
	;get memory if necessary
		move.l	(dp_Arg1,a4),a0
		move.l	(mfl_iocache,a0),d0
		bne	.read_c1
		move.l	d7,d0
		moveq	#MEMF_ANY,d1
		jsr	(_LVOAllocMem,a6)
		move.l	(dp_Arg1,a4),a0
		move.l	d0,(mfl_iocache,a0)
	IFD DEBUG
		beq	_debug5
	ELSE
		beq	.read_d
	ENDC
	;read into cache
.read_c1	move.l	d0,a1				;cache
		move.l	(mfl_fib+fib_Size,a0),d0
		sub.l	d5,d0				;length
		cmp.l	d7,d0
		bls	.read_c2
		move.l	d7,d0				;length
.read_c2	move.l	d5,d1				;offset
		move.l	(fl_Key,a0),a0			;name
		jsr	(resload_LoadFileOffset,a2)
		move.l	(dp_Arg1,a4),a0
		move.l	d5,(mfl_cpos,a0)
	;copy from cache
		move.l	(mfl_iocache,a0),a0		;source
		move.l	(dp_Arg2,a4),a1
		add.l	d4,a1				;destination
		move.l	d3,d0
.read_c3	move.b	(a0)+,(a1)+
		subq.l	#1,d0
		bne	.read_c3
	;finish
.read_end	move.l	d3,d0
		add.l	d4,d0
		moveq	#0,d1				;no error
	IFD CBDOSREAD
		movem.l	d0-a6,-(a7)
		move.l	(dp_Arg1,a4),a0
		move.l	(mfl_pos,a0),d1
		sub.l	d0,d1				;file pos
		move.l	(fl_Key,a0),a0			;name
		move.l	(dp_Arg2,a4),a1			;buffer
		bsr	_cb_dosRead
		movem.l	(a7)+,d0-a6
	ENDC
		bra	.reply2
	ENDC

;---------------

.a_write	move.l	(dp_Arg1,a4),a0			;APTR lock
	IFD DEBUG
		cmp.l	(fl_Task,a0),a5
		bne	_debug4
	ENDC
	IFD BOOTDOS
	;special files
		move.l	(fl_Key,a0),a0			;name
		bsr	.specialfile
		tst.l	d0
		beq	.write_nospec
		move.l	#ERROR_WRITE_PROTECTED,d1
		move.l	#DOSFALSE,d0
		bra	.reply2
.write_nospec	move.l	(dp_Arg1,a4),a0
	ENDC
	IFND IOCACHE
		move.l	(dp_Arg3,a4),d0			;len
		beq	.write_end
		move.l	(mfl_pos,a0),d1			;offset
		move.l	d1,d2
		add.l	d0,d2
		move.l	d2,(mfl_pos,a0)			;new position
		cmp.l	(mfl_fib+fib_Size,a0),d2
		bls	.write_inside
		move.l	d2,(mfl_fib+fib_Size,a0)	;new length
.write_inside	move.l	(fl_Key,a0),a0			;name
		move.l	(dp_Arg2,a4),a1			;buffer
		jsr	(resload_SaveFileOffset,a2)
.write_end	move.l	(dp_Arg3,a4),d0			;bytes written
		bra	.reply1
	ELSE
	;set new pos and correct size if necessary
		move.l	#IOCACHE,d4			;d4 = IOCACHE
		move.l	(dp_Arg2,a4),d5			;d5 = buffer
		move.l	(dp_Arg3,a4),d6			;d6 = len
		beq	.write_end
		move.l	(mfl_pos,a0),d7			;d7 = offset before write
		move.l	d6,d0
		add.l	d7,d0
		move.l	d0,(mfl_pos,a0)			;new position
		cmp.l	(mfl_fib+fib_Size,a0),d0
		bls	.write_inside
		move.l	d0,(mfl_fib+fib_Size,a0)	;new length
.write_inside
	;is there already a write cache?
		move.l	(mfl_clen,a0),d0
		bne	.write_chkapp
	;invalidate possible read cache
		moveq	#-1,d0
		move.l	d0,(mfl_cpos,a0)
		bra	.write_checkfit
	;matches the offset the end of the last cached write?
.write_chkapp	add.l	(mfl_cpos,a0),d0
		cmp.l	d0,d7
		bne	.write_flush
	;does fit existing cache + new write in 2*IOCACHE
		move.l	(mfl_clen,a0),d0
		add.l	d6,d0
		move.l	d4,d1
		add.l	d4,d1
		cmp.l	d1,d0
		blo	.write_fill
	;flush existing write cache
.write_flush	bsr	.flush_write_cache
	;check if write fits into the cache
.write_checkfit	cmp.l	d6,d4
		bls	.write_direct
	;fill cache
.write_fill
	;get memory if necessary
		move.l	(mfl_iocache,a0),d0
		bne	.write_memok
		move.l	d4,d0
		moveq	#MEMF_ANY,d1
		jsr	(_LVOAllocMem,a6)
		move.l	(dp_Arg1,a4),a0			;lock
		move.l	d0,(mfl_iocache,a0)
	IFD DEBUG
		beq	_debug5
	ELSE
		beq	.write_direct
	ENDC
.write_memok	move.l	d0,a1
	;determine bytes to copy
		move.l	d4,d0				;IOCACHE
		sub.l	(mfl_clen,a0),d0		;free bytes in cache
		beq	.write_flush			;flush if cache was full
		cmp.l	d6,d0				;len
		blo	.write_fill_len
		move.l	d6,d0
.write_fill_len
	;copy to cache
		tst.l	(mfl_cpos,a0)
		bpl	.write_cpos_set
		move.l	d7,(mfl_cpos,a0)		;new position
.write_cpos_set add.l	(mfl_clen,a0),a1
		add.l	d0,(mfl_clen,a0)		;new length
		sub.l	d0,d6				;len
		add.l	d0,d7				;position
		exg.l	d5,a0				;lock<>buffer
.write_cpy	move.b	(a0)+,(a1)+
		subq.l	#1,d0
		bne	.write_cpy
		exg.l	a0,d5				;lock<>buffer
		tst.l	d6				;all written?
		beq	.write_end
		bra	.write_flush			;loop for 2nd cycle
	;write without cache
.write_direct	move.l	d6,d0				;len
		move.l	d7,d1				;offset
		move.l	(fl_Key,a0),a0			;name
		move.l	d5,a1				;buffer
		jsr	(resload_SaveFileOffset,a2)
.write_end	move.l	(dp_Arg3,a4),d0			;bytes written
		bra	.reply1
	ENDC

;---------------		lock	delete	create
; MODE_READWRITE - UPDATE 1.3	WRITE	no	no
; MODE_READWRITE - UPDATE 2.0	READ	no	yes
; MODE_OLDFILE - INPUT		READ	no	no
; MODE_NEWFILE - OUTPUT		WRITE	yes	yes

	IFLT KICKVERSION-36
.a_findupdate	moveq	#ACCESS_WRITE,d2	;mode
		bra	.a_findall
	ELSE
.a_findupdate	moveq	#ACCESS_READ,d2		;mode
	;check exist and lock it
		bsr	.getarg2
		move.l	d7,d0			;APTR lock
		bsr	.getarg3
		move.l	d7,d1			;BSTR name
		bsr	.lock
		tst.l	d0			;APTR lock
		bne	.a_find_locked
		bra	.a_findoutput
	ENDC

.a_findinput	moveq	#ACCESS_READ,d2		;mode
.a_findall
	;check exist and lock it
		bsr	.getarg2
		move.l	d7,d0			;APTR lock
		bsr	.getarg3
		move.l	d7,d1			;BSTR name
		bsr	.lock
		tst.l	d0			;APTR lock
		beq	.reply2
	;init fh
.a_find_locked	bsr	.getarg1
		move.l	d7,a0			;fh
		move.l	d0,(fh_Arg1,a0)		;using the lock we refer the filename later
	;log the lock to allow check for Open/Close pair
	IFD SNOOPFS
		move.l	(dp_Arg3,a4),-(a7)
		move.l	(dp_Arg2,a4),-(a7)
		move.l	(dp_Arg1,a4),-(a7)
		move.l	d0,-(a7)
		pea	(.snoopfshead,pc)
		lea	(.f_find,pc),a0
		jsr	(resload_Log,a2)
		add.w	#5*4,a7
	ENDC
	;return
		bra	.reply1true

.a_findoutput	bsr	.getarg2
		move.l	d7,d0			;APTR lock
		bsr	.getarg3
		move.l	d7,d1			;BSTR name
		bsr	.buildname
		move.l	d0,d2			;d2 = name
		beq	.reply2
	IFD BOOTDOS
	;special files
		move.l	d2,a0			;name
		bsr	.specialfile
		tst.l	d0
		beq	.findout_nospec
	;free the name
		move.l	d2,a1
		move.l	-(a1),d0
		jsr	(_LVOFreeMem,a6)
		move.l	#ERROR_WRITE_PROTECTED,d1
		move.l	#DOSFALSE,d0
		bra	.reply2
.findout_nospec
	ENDC
	;create an empty file
		move.l	d2,a0
		sub.l	a1,a1
		moveq	#0,d0
		jsr	(resload_SaveFile,a2)
	;free the name
		move.l	d2,a1
		move.l	-(a1),d0
		jsr	(_LVOFreeMem,a6)
	IFLT KICKVERSION-36
		bra	.a_findupdate
	ELSE
		bra	.a_findinput
	ENDC

;---------------

.a_end
	IFD DEBUG
		move.l	(dp_Arg1,a4),a0		;APTR lock
		cmp.l	(fl_Task,a0),a5
		bne	_debug4
	ENDC
	IFD IOCACHE
		bsr	.flush_write_cache
	ENDC
		move.l	(dp_Arg1,a4),d0		;APTR lock
		bsr	.unlock
		bra	.reply1true

;---------------

	IFD IOCACHE
	;dp_Arg1 must be the filelock
	;a read cache remains intact!
	;must return a0 = APTR lock (dp_Arg1)
.flush_write_cache
		move.l	(dp_Arg1,a4),a0		;lock
		move.l	(mfl_clen,a0),d0	;len (only set on write cache)
		beq	.fwc_nowcache
		move.l	(mfl_cpos,a0),d1	;offset
		move.l	(mfl_iocache,a0),a1	;buffer
		move.l	(fl_Key,a0),a0		;name
		jsr	(resload_SaveFileOffset,a2)
		move.l	(dp_Arg1,a4),a0		;lock
		clr.l	(mfl_clen,a0)
		moveq	#-1,d0
		move.l	d0,(mfl_cpos,a0)
.fwc_nowcache	rts
	ENDC

;---------------

.a_seek		move.l	(dp_Arg1,a4),a0		;APTR lock
		move.l	(dp_Arg2,a4),d2		;offset
		move.l	(dp_Arg3,a4),d1		;mode
	;calculate new position
		beq	.seek_cur
		bmi	.seek_beg
.seek_end	add.l	(mfl_fib+fib_Size,a0),d2
		bra	.seek_chk
.seek_cur	add.l	(mfl_pos,a0),d2
.seek_beg
.seek_chk
	;validate new position
		cmp.l	(mfl_fib+fib_Size,a0),d2
		bhi	.seek_err
	;set new
		move.l	(mfl_pos,a0),d0		;return old position
		move.l	d2,(mfl_pos,a0)
		moveq	#0,d1
		bra	.reply2
.seek_err	move.l	#-1,d0
		move.l	#ERROR_SEEK_ERROR,d1
		bra	.reply2

;---------------

	IFGT KICKVERSION-36
.a_fh_from_lock	bsr	.getarg1		;handle
		move.l	d7,a0
		bsr	.getarg2		;lock
		move.l	d7,(fh_Arg1,a0)		;using the lock we refer the filename later
		bra	.reply1true
	ENDC

;---------------

	IFGT KICKVERSION-36
.a_add_notify
.a_examine_all	moveq	#DOSFALSE,d0
		move.l	#ERROR_ACTION_NOT_KNOWN,d1
		bra	.reply2
	ENDC

;---------------
; these functions get the respective arg converted from a BPTR to a APTR in D7

.getarg1	move.l	(dp_Arg1,a4),d7
		lsl.l	#2,d7
		rts
.getarg2	move.l	(dp_Arg2,a4),d7
		lsl.l	#2,d7
		rts
.getarg3	move.l	(dp_Arg3,a4),d7
		lsl.l	#2,d7
		rts

;---------------
; convert c-string into bcpl-string
; IN:	a0 = CSTR
; OUT:	-

.bstr		movem.l	d0-d2,-(a7)
		moveq	#-1,d0
		move.b	(a0)+,d2
.bstr_1		addq.l	#1,d0
		move.b	d2,d1
		move.b	(a0),d2
		move.b	d1,(a0)+
		bne	.bstr_1
		sub.l	d0,a0
		move.b	d0,(-2,a0)
		movem.l	(a7)+,d0-d2
		rts

;---------------
; lock a disk object
; IN:	d0 = APTR lock
;	d1 = BSTR name
;	d2 = LONG mode
; OUT:	d0 = APTR lock
;	d1 = LONG errcode

.lock		movem.l	d4/a4,-(a7)
	;get name
		bsr	.buildname
		tst.l	d0
		beq	.lock_quit
		move.l	d0,d4			;D4 = name
	;get memory for lock
		move.l	#mfl_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		jsr	(_LVOAllocMem,a6)
		tst.l	d0
		beq	.lock_nomem
		move.l	d0,a4			;A4 = myfilelock
	;special
	IFD BOOTDOS
		move.l	d4,a0
		bsr	.specialfile
		tst.l	d0
		beq	.lock_nospec
		move.l	#ST_FILE,(mfl_fib+fib_DirEntryType,a4)
		move.l	d1,(mfl_fib+fib_Size,a4)
		bra	.lock_spec
.lock_nospec
	ENDC
	;examine
		move.l	d4,a0			;name
		lea	(mfl_fib,a4),a1		;fib
		jsr	(resload_Examine,a2)
		tst.l	d0
		beq	.lock_notfound
.lock_spec
	;set return values
		move.l	a4,d0
		moveq	#0,d1
	;fill lock structure
	IFD IOCACHE
		subq.l	#1,(mfl_cpos,a4)	;nothing cached yet
	ENDC
		addq.l	#4,a4			;fl_Link
		move.l	d4,(a4)+		;fl_Key (name)
		move.l	d2,(a4)+		;fl_Access
		move.l	a5,(a4)+		;fl_Task (MsgPort)
		move.l	a3,(a4)+		;fl_Volume
.lock_quit	movem.l	(a7)+,d4/a4
.rts		rts
.lock_notfound	move.l	#mfl_SIZEOF,d0
		move.l	a4,a1
		jsr	(_LVOFreeMem,a6)
		pea	ERROR_OBJECT_NOT_FOUND
		bra	.lock_err
.lock_nomem	pea	ERROR_NO_FREE_STORE
	;on error free the name
.lock_err	move.l	d4,a1
		move.l	-(a1),d0
		jsr	(_LVOFreeMem,a6)
		move.l	(a7)+,d1
		moveq	#DOSFALSE,d0
		bra	.lock_quit

;---------------
; free a lock
; IN:	d0 = APTR lock
; OUT:	-

.unlock		tst.l	d0
		beq	.rts
		move.l	d0,a1
	IFD DEBUG
		cmp.l	(fl_Task,a1),a5
		bne	_debug4
		clr.l	(fl_Task,a1)
	ENDC
		move.l	(fl_Key,a1),-(a7)	;name
	IFD IOCACHE
		move.l	(mfl_iocache,a1),-(a7)
	ENDC
		move.l	#mfl_SIZEOF,d0
		jsr	(_LVOFreeMem,a6)
	IFD IOCACHE
		move.l	(a7)+,d0
		beq	.unlock1
		move.l	d0,a1
		move.l	#IOCACHE,d0
		jsr	(_LVOFreeMem,a6)
.unlock1
	ENDC
		move.l	(a7)+,a1
		move.l	-(a1),d0
		jmp	(_LVOFreeMem,a6)

;---------------
; build name for disk object
; IN:	d0 = APTR lock (can represent a directory or a file)
;	d1 = BSTR name (an object name relative to the lock, may contain assign or volume in front)
; OUT:	d0 = APTR name (size=-(d0), must be freed via exec.FreeMem)
;	d1 = LONG errcode

.buildname	movem.l	d3-d7,-(a7)
		moveq	#0,d6			;d6 = length path
		moveq	#0,d7			;d7 = length name
	;get length of lock
		tst.l	d0
		beq	.buildname_nolock
		move.l	d0,a0
	IFD DEBUG
		cmp.l	(fl_Task,a0),a5
		bne	_debug4
	ENDC
		move.l	(fl_Key,a0),a0
		move.l	a0,d4			;d4 = ptr path
		moveq	#-1,d6
.buildname_cl	addq.l	#1,d6
		tst.b	(a0)+
		bne	.buildname_cl
.buildname_nolock
	;get length of name
		move.l	d1,a0			;BSTR
		move.b	(a0)+,d7		;length
		beq	.buildname_noname
	;remove trailing "/"
		cmp.b	#1,d7
		beq	.buildname_nots
		cmp.b	#"/",(-1,a0,d7.l)
		bne	.buildname_nots
		subq.l	#1,d7
.buildname_nots
	;remove leading "xxx:"
		lea	(a0,d7.l),a1		;end
.buildname_col	cmp.b	#":",-(a1)
		beq	.buildname_fc
		cmp.l	a0,a1
		bne	.buildname_col
		subq.l	#1,a1
.buildname_fc	addq.l	#1,a1
		sub.l	a1,d7
		add.l	a0,d7
		move.l	a1,d5			;d5 = ptr name
.buildname_noname
	;allocate memory for object name
		moveq	#1+1+4,d0		;the possible seperator "/", 0 terminator, length
		add.l	d6,d0
		add.l	d7,d0
		move.l	d0,d3			;d3 = memlen
		move.l	#MEMF_ANY,d1
		jsr	(_LVOAllocMem,a6)
		tst.l	d0
		beq	.buildname_mem
		move.l	d0,a0
		move.l	d3,(a0)+
		move.l	a0,d0			;d0 = new object memory
	;copy name
		moveq	#"/",d3			;d3 = "/"
		move.l	d4,a1
		move.l	d6,d1
		beq	.buildname_name
.buildname_cp	move.b	(a1)+,(a0)+
		subq.l	#1,d1
		bne	.buildname_cp
	;add seperator
		tst.l	d7
		beq	.buildname_ok
		move.b	d3,(a0)+
	;copy path
.buildname_name	move.l	d5,a1
		move.l	d7,d1
		beq	.buildname_ok
.buildname_cn	move.b	(a1)+,(a0)+
		subq.l	#1,d1
		bne	.buildname_cn
.buildname_ok	clr.b	(a0)			;terminate
	;check for "//" (double slash) and trailing slash's
		move.l	d0,a0
		move.l	d0,a1
		cmp.b	(a0),d3
		beq	.buildname_inv		;must not start with a "/"
.buildname_ds1	move.b	(a0)+,d1
		beq	.buildname_ds3
		cmp.b	d3,d1
		bne	.buildname_ds2
		bset	#0,d7			;indicate slash
		beq	.buildname_ds3
	;two slash
		subq.l	#1,a1			;skip already written slash
		cmp.l	a1,d0
		bhs	.buildname_inv		;already at beginning?
.buildname_ss	cmp.b	-(a1),d3
		beq	.buildname_ds3
		cmp.l	a1,d0
		bne	.buildname_ss
		bra	.buildname_ds1
	;copy
.buildname_ds2	sf	d7			;no slash
.buildname_ds3	move.b	d1,(a1)+
		bne	.buildname_ds1
		tst.b	d7
		beq	.buildname_sok
	;trailing slash
		subq.l	#2,a1			;skip already written slash and 0
		cmp.l	a1,d0
		bhs	.buildname_inv		;already at beginning?
.buildname_ts1	cmp.b	-(a1),d3
		beq	.buildname_ts2
		cmp.l	a1,d0
		bne	.buildname_ts1
.buildname_ts2	clr.b	(a1)
.buildname_sok
	;finish
		moveq	#0,d1			;errorcode
.buildname_quit	movem.l	(a7)+,d3-d7
		rts

.buildname_inv	move.l	#ERROR_OBJECT_NOT_FOUND,d1
		bra	.buildname_err
.buildname_mem	move.l	#ERROR_NO_FREE_STORE,d1
.buildname_err	moveq	#DOSFALSE,d0
		bra	.buildname_quit

;---------------
; check for special internal files
; IN:	a0 = CSTR name
; OUT:	d0 = APTR filedata
;	d1 = LONG filelength

	IFD BOOTDOS
.specialfile
		lea	(bootfile_ss,pc),a1
		move.l	a1,d0
		move.l	#bootfile_ss_e-bootfile_ss,d1
		lea	(bootname_ss,pc),a1
		bsr	.specfile_chk
		beq	.specfile_rts

		lea	(bootfile_exe,pc),a1
		move.l	a1,d0
		move.l	#bootfile_exe_e-bootfile_exe,d1
		lea	(bootname_exe,pc),a1
		bsr	.specfile_chk
		beq	.specfile_rts

		moveq	#0,d0
		rts

.specfile_chk	move.l	a0,-(a7)

.specfile_cmp	cmpm.b	(a0)+,(a1)+
		bne	.specfile_end
		tst.b	(-1,a0)
		bne	.specfile_cmp

.specfile_end	move.l	(a7)+,a0
.specfile_rts	rts
	ENDC

;---------------

	CNOP 0,4
.volumename	dc.b	7,"WHDLoad",0		;BSTR (here with the exception that it must be
						;0-terminated!)
.devicename	dc.b	"whdload.device",0
.handlername	dc.b	"DH0",0
.expansionname	dc.b	"expansion.library",0
	IFD TRACEFS
.tracefs_name	dc.b	".tracefs",0
	ENDC
	IFD SNOOPFS
.snoopfshead		dc.b	"[KICKFS] ",0
.f_current_volume	dc.b	"%sCURRENT_VOLUME ErrorReport() dl=$%B r2=%ld fha1=$%lx",0
.f_locate_object	dc.b	"%sLOCATE_OBJECT         Lock() fl=$%B r2=%ld fl=$%B name=%b mode=%ld",0
.f_rename_disk		dc.b	"%sRENAME_DISK        Relabel() succ=%ld r2=%ld name=%b",0
.f_free_lock		dc.b	"%sFREE_LOCK           UnLock() succ=%ld r2=%ld fl=$%B",0
.f_delete_object	dc.b	"%sDELETE_OBJECT   DeleteFile() succ=%ld r2=%ld fl=$%B name=%b",0
.f_copy_dir		dc.b	"%sCOPY_DIR           DupLock() fl=$%B r2=%ld fl=$%B",0
.f_set_protect		dc.b	"%sSET_PROTECT  SetProtection() succ=%ld r2=%ld nul=%ld fl=$%B name=%b mask=$%lx",0
.f_create_dir		dc.b	"%sCREATE_DIR       CreateDir() fl=$%B r2=%ld fl=$%B name=%b",0
.f_examine_object	dc.b	"%sEXAMINE_OBJECT     Examine() succ=%ld r2=%ld fl=$%B fib=$%B",0
.f_examine_next		dc.b	"%sEXAMINE_NEXT        ExNext() succ=%ld r2=%ld fl=$%B fib=$%B",0
.f_disk_info		dc.b	"%sDISK_INFO           cmd.info succ=%ld r2=%ld id=$%B",0
.f_info			dc.b	"%sINFO                  Info() succ=%ld r2=%ld fl=$%B id=$%B",0
.f_flush		dc.b	"%sFLUSH               cmd.sync succ=%ld",0
.f_set_comment		dc.b	"%sSET_COMMENT     SetComment() succ=%ld r2=%ld nul=%ld fl=$%B name=%b comm=%b",0
.f_parent		dc.b	"%sPARENT           ParentDir() fl=$%B r2=%ld fl=$%B",0
.f_inhibit		dc.b	"%sINHIBIT            Inhibit() succ=%ld r2=%ld bool=%ld",0
.f_set_date		dc.b	"%sSET_DATE       SetFileDate() succ=%ld r2=%ld nul=%ld fl=$%B name=%b ds=$%lx",0
.f_read			dc.b	"%sREAD                  Read() len=$%lx r2=%ld fha1=$%lx buf=$%lx len=$%lx",0
.f_write		dc.b	"%sWRITE                Write() len=$%lx r2=%ld fha1=$%lx buf=$%lx len=$%lx",0
.f_findupdate		dc.b	"%sFINDUPDATE      Open(UPDATE) succ=%ld r2=%ld fh=$%B fl=$%B name=%b",0
.f_findinput		dc.b	"%sFINDINPUT      Open(OLDFILE) succ=%ld r2=%ld fh=$%B fl=$%B name=%b",0
.f_findoutput		dc.b	"%sFINDOUTPUT     Open(NEWFILE) succ=%ld r2=%ld fh=$%B fl=$%B name=%b",0
.f_find			dc.b	"%sFIND* internal lock  Open(*) fl=$%lx <- fh=$%B fl=$%B name=%b",0
.f_end			dc.b	"%sEND                  Close() succ=%ld r2=%ld fha1=$%lx",0
.f_seek			dc.b	"%sSEEK                  Seek() pos=$%lx r2=%ld fha1=$%lx pos=$%lx mode=%ld",0
	IFGT KICKVERSION-36
.f_same_lock		dc.b	"%sSAME_LOCK         SameLock() succ=%ld r2=%ld fl=$%B fl=$%B",0
.f_fh_from_lock		dc.b	"%sFH_FROM_LOCK  OpenFromLock() succ=%ld r2=%ld fh=$%B fl=$%B",0
.f_is_filesystem	dc.b	"%sIS_FILESYSTEM IsFileSystem() succ=%ld r2=%ld",0
.f_examine_all		dc.b	"%sEXAMINE_ALL          ExAll() succ=%ld r2=%ld fl=$%B ead=$%lx len=$%lx typ=%ld eac=$%lx",0
.f_examine_fh		dc.b	"%sEXAMINE_FH       ExamineFH() succ=%ld r2=%ld fha1=$%lx fib=$%B",0
.f_add_notify		dc.b	"%sADD_NOTIFY     StartNotify() succ=%ld r2=%ld nr=$%lx",0
	ENDC
	ENDC
_dosname	dc.b	"dos.library",0

;---------------

	IFD BOOTDOS
	IFND BOOTFILENAME
BOOTFILENAME	MACRO
		dc.b	"WHDBoot.exe"
	ENDM
	ENDC
	CNOP 0,4
bootfile_exe	dc.l	$3f3,0,1,0,0,2,$3e9,2	;exe header
bootfile_exe_j	jmp	$99999999		;avoid optimizing!
		dc.w	0			;pad to longword
		dc.l	$3f2			;exe footer
bootfile_exe_e
bootname_ss_b	dc.b	10			;BSTR
bootname_ss	dc.b	"WHDBoot.ss",0		;name of ':s/startup-sequence'
bootfile_ss	BOOTFILENAME
		dc.b	10
bootfile_ss_e
bootname_exe	BOOTFILENAME
		dc.b	0
	ELSE
ss_name		dc.b	"s/startup-sequence",0
	ENDC

;---------------

	EVEN
