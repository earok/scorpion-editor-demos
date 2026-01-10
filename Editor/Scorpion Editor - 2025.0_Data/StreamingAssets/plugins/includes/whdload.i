;*---------------------------------------------------------------------------
;  :Module.	whdload.i
;  :Contens.	include file for WHDLoad and Slaves
;  :Author.	Bert Jahn
;  :History.	11.04.99 marcos moved to separate include file
;		08.05.99 resload_Patch added
;		09.03.00 new stuff for whdload v11
;		10.07.00 new stuff for whdload v12
;		25.11.00 new stuff for whdload v13
;		13.01.01 some comments spelling errors fixed
;		15.03.01 v14 stuff added
;		15.04.01 FAILMSG added
;		29.04.01 resload_Relocate tags added
;		09.12.01 v15 stuff added
;		20.08.02 WHDLTAG_ALIGN added
;		19.11.02 WHDLTAG_CHKCOPCON added
;		03.06.03 EmulDivZero added
;		16.06.03 new PL's added
;		18.07.03 EmulIllegal added
;		05.06.04 macro PL_S improved
;		27.06.04 WHDLTAG_LOADSEG added
;		10.01.05 PL_OR's added
;		02.04.06 PL_GA added
;		02.05.06 made compatible to ASM-One
;		05.05.07 some cleanup and minor comment fixes
;		06.09.07 adapted to work with Devpac 3.18
;		11.11.07 PL_BKPT, PL_BELL added
;		28.07.08 PL_NOPS added
;		22.07.11 new stuff for whdload v17
;		22.05.12 PL_* added check for number of arguments
;			 commentary reworked
;		16.03.13 PL_CMDADR checks for negative destination address
;		24.03.13 PL_IF,ELSE,ENDIF added
;		19.01.14 resload_VSNPrintF and resload_Log added
;		11.03.14 WHDLTAG_CUST_#? added
;		09.11.17 PL_STR0 macro added
;		17.01.21 WHDLTAG_Private7 added
;			 replaced IFMI with IFLT to improve compatibility
;		13.01.23 WHDLTAG_Private8/9 added
;		12.05.24 added resload_ReadJoyPort
;  :Copyright.	© 1996-2024 Bert Jahn, All Rights Reserved
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, ASM-One 1.44, Asm-Pro 1.17, PhxAss 4.38, Devpac 3.18, Vasm
;---------------------------------------------------------------------------*

 IFND WHDLOAD_I
WHDLOAD_I SET 1

	IFND	EXEC_EXECBASE_I
	INCLUDE	exec/execbase.i
	ENDC
	IFND	EXEC_TYPES_I
	INCLUDE	exec/types.i
	ENDC
	IFND	GRAPHICS_MODEID_I
	INCLUDE	graphics/modeid.i
	ENDC
	IFND	UTILITY_TAGITEM_I
	INCLUDE	utility/tagitem.i
	ENDC

;=============================================================================
;	misc
;=============================================================================

SLAVE_HEADER	MACRO
		moveq	#-1,d0
		rts
		dc.b	"WHDLOADS"
		ENDM

;=============================================================================
;	return-values for termination (resload_Abort)
;=============================================================================

TDREASON_OK		= -1	;normal termination
TDREASON_DOSREAD	= 1	;error caused by resload_ReadFile
				; primary   = dos errorcode
				; secondary = file name
TDREASON_DOSWRITE	= 2	;error caused by resload_SaveFile or
				;resload_SaveFileOffset
				; primary   = dos errorcode
				; secondary = file name
TDREASON_DEBUG		= 5	;cause WHDLoad to make a coredump and quit
				; primary   = PC (to be written to dump files)
				; secondary = SR (to be written to dump files)
TDREASON_DOSLIST	= 6	;error caused by resload_ListFiles
				; primary   = dos errorcode
				; secondary = directory name
TDREASON_DISKLOAD	= 7	;error caused by resload_DiskLoad
				; primary   = dos errorcode
				; secondary = disk number
TDREASON_DISKLOADDEV	= 8	;error caused by resload_DiskLoadDev
				; primary   = trackdisk errorcode
TDREASON_WRONGVER	= 9	;an version check (e.g. CRC16) has detected an
				;unsupported version of the installed program
TDREASON_OSEMUFAIL	= 10	;error in the OS emulation module
				; primary   = subsystem (e.g. "exec.library")
				; secondary = error number (e.g. _LVOAllocMem)
; version 7
TDREASON_REQ68020	= 11	;installed program requires a MC68020
TDREASON_REQAGA		= 12	;installed program requires the AGA chip set
TDREASON_MUSTNTSC	= 13	;installed program needs NTSC video mode to run
TDREASON_MUSTPAL	= 14	;installed program needs PAL video mode to run
; version 8
TDREASON_MUSTREG	= 15	;WHDLoad must be registered
TDREASON_DELETEFILE	= 27	;error caused by resload_DeleteFile
				; primary   = dos errorcode
				; secondary = file name
; version 14.1
TDREASON_FAILMSG	= 43	;fail with a slave defined message text
				; primary   = text

;=============================================================================
; tagitems for the resload_Control function
;=============================================================================

 ENUM	TAG_USER+$8000000
 EITEM	WHDLTAG_ATTNFLAGS_GET	;get info about current CPU/FPU/MMU
 EITEM	WHDLTAG_ECLOCKFREQ_GET	;get frequency custom chips operate on
 EITEM	WHDLTAG_MONITOR_GET	;get the used monitor/video mode
				;(NTSC_MONITOR_ID or PAL_MONITOR_ID)
 EITEM	WHDLTAG_Private1
 EITEM	WHDLTAG_Private2
 EITEM	WHDLTAG_Private3
 EITEM	WHDLTAG_BUTTONWAIT_GET	;get value of WHDLoad option ButtonWait/S (0/-1)
 EITEM	WHDLTAG_CUSTOM1_GET	;get value of WHDLoad option Custom1/N (integer)
 EITEM	WHDLTAG_CUSTOM2_GET	;get value of WHDLoad option Custom2/N (integer)
 EITEM	WHDLTAG_CUSTOM3_GET	;get value of WHDLoad option Custom3/N (integer)
 EITEM	WHDLTAG_CUSTOM4_GET	;get value of WHDLoad option Custom4/N (integer)
 EITEM	WHDLTAG_CUSTOM5_GET	;get value of WHDLoad option Custom5/N (integer)
; version 7
 EITEM	WHDLTAG_CBSWITCH_SET	;set a function to be executed during switch
				;from operating system to installed program
 EITEM	WHDLTAG_CHIPREVBITS_GET	;get info about current custom chip set
; version 8
 EITEM	WHDLTAG_IOERR_GET	;get last dos errorcode
 EITEM	WHDLTAG_Private4
; version 9
 EITEM	WHDLTAG_CBAF_SET	;set a function to be executed when an access
				;fault exception occurs
 EITEM	WHDLTAG_VERSION_GET	;get WHDLoad major version number
 EITEM	WHDLTAG_REVISION_GET	;get WHDLoad minor version number
 EITEM	WHDLTAG_BUILD_GET	;get WHDLoad build number
 EITEM	WHDLTAG_TIME_GET	;get current time and date
; version 11
 EITEM	WHDLTAG_BPLCON0_GET	;get operating system bplcon0
; version 12
 EITEM	WHDLTAG_KEYTRANS_GET	;get pointer to a 128 byte table to convert
				;rawkeys to ASCII-chars
; version 13
 EITEM	WHDLTAG_CHKBLTWAIT	;enable/disable blitter wait check
 EITEM	WHDLTAG_CHKBLTSIZE	;enable/disable blitter size check
 EITEM	WHDLTAG_CHKBLTHOG	;enable/disable dmacon.blithog (bltpri) check
 EITEM	WHDLTAG_CHKCOLBST	;enable/disable bplcon0.color check
; version 14
 EITEM	WHDLTAG_LANG_GET	;GetLanguageSelection like lowlevel.library
; version 14.5
 EITEM	WHDLTAG_DBGADR_SET	;set debug base address
; version 15
 EITEM	WHDLTAG_DBGSEG_SET	;set debug base segment address (BPTR!)
; version 15.2
 EITEM	WHDLTAG_CHKCOPCON	;enable/disable copcon check
 EITEM	WHDLTAG_Private5	;allows setting WCPU_Base_CB using SetCPU
; version 18
 EITEM	WHDLTAG_CUST_DISABLE	;marks a custom register invalid for Snoop
 EITEM	WHDLTAG_CUST_READ	;marks a custom register readable for Snoop
 EITEM	WHDLTAG_CUST_WRITE	;marks a custom register writable for Snoop
 EITEM	WHDLTAG_CUST_STROBE	;marks a custom register read/writable for Snoop
 EITEM	WHDLTAG_Private6
; version 18.7
 EITEM	WHDLTAG_Private7
; version 18.9
 EITEM	WHDLTAG_Private8
 EITEM	WHDLTAG_Private9

;=============================================================================
; tagitems for the resload_Relocate function
;=============================================================================

; version 14.1
 ENUM	TAG_USER+$8100000
 EITEM	WHDLTAG_CHIPPTR		;relocate MEMF_CHIP hunks to this address
 EITEM	WHDLTAG_FASTPTR		;relocate MEMF_FAST hunks to this address
; version 15.1
 EITEM	WHDLTAG_ALIGN		;round up hunk lengths to the given multiple
; version 16.3
 EITEM	WHDLTAG_LOADSEG		;create a segment list like dos.LoadSeg

;=============================================================================
; tagitems for the resload_DiskLoadDev function
;=============================================================================

; version 16.0
 ENUM	TAG_USER+$8200000
 EITEM	WHDLTAG_TDUNIT		;unit of trackdisk.device to use

;=============================================================================
;	structure returned by WHDLTAG_TIME_GET
;=============================================================================

    STRUCTURE whdload_time,0
	ULONG	whdlt_days	;days since 1978-01-01
	ULONG	whdlt_mins	;minutes since last day
	ULONG	whdlt_ticks	;1/50 seconds since last minute
	UBYTE	whdlt_year	;78..77 (1978..2077)
	UBYTE	whdlt_month	;1..12
	UBYTE	whdlt_day	;1..31
	UBYTE	whdlt_hour	;0..23
	UBYTE	whdlt_min	;0..59
	UBYTE	whdlt_sec	;0..59
	LABEL	whdlt_SIZEOF

;=============================================================================
; Slave		Version 1+
;=============================================================================

    STRUCTURE	WHDLoadSlave,0
	STRUCT	ws_Security,4	;moveq #-1,d0 rts
	STRUCT	ws_ID,8		;"WHDLOADS"
	UWORD	ws_Version	;required WHDLoad version
	UWORD	ws_Flags	;see below
	ULONG	ws_BaseMemSize	;size of required memory (multiple of $1000)
	ULONG	ws_ExecInstall	;must be 0
	RPTR	ws_GameLoader	;Slave code, called by WHDLoad
	RPTR	ws_CurrentDir	;subdirectory for data files
	RPTR	ws_DontCache	;pattern for files not to cache

;=============================================================================
; additional	Version 4+
;=============================================================================

	UBYTE	ws_keydebug	;raw key code to quit with debug
	UBYTE	ws_keyexit	;raw key code to exit

;=============================================================================
; additional	Version 8+
;=============================================================================

	LONG	ws_ExpMem	;size of required expansions memory, during
				;initialization overwritten by WHDLoad with
				;address of the memory (multiple of $1000)
				;if negative it is optional

;=============================================================================
; additional	Version 10+
;=============================================================================

	RPTR	ws_name		;name of the installed program
	RPTR	ws_copy		;year and owner of the copyright
	RPTR	ws_info		;additional informations (author, version ...)

;=============================================================================
; additional	Version 16+
;=============================================================================

	RPTR	ws_kickname	;name of kickstart image
	ULONG	ws_kicksize	;size of kickstart image
	UWORD	ws_kickcrc	;CRC16 of kickstart image

;=============================================================================
; additional	Version 17+
;=============================================================================

	RPTR	ws_config	;configuration of splash window buttons
	LABEL	ws_SIZEOF

;=============================================================================
; Flags for ws_Flags
;=============================================================================

	BITDEF WHDL,Disk,0	;means diskimages are used by the Slave
				;starting WHDLoad 0.107 obsolete
	BITDEF WHDL,NoError,1	;forces WHDLoad to abort the installed program
				;if error during resload_#? function occurs
	BITDEF WHDL,EmulTrap,2	;forward "trap #n" exceptions to the handler
				;of the installed program
	BITDEF WHDL,NoDivZero,3	;ignore division by zero exceptions
; version 7
	BITDEF WHDL,Req68020,4	;abort if no MC68020 or better is available
	BITDEF WHDL,ReqAGA,5	;abort if no AGA chipset is available
; version 8
	BITDEF WHDL,NoKbd,6	;tells WHDLoad that it doesn't should
				;acknowledge keyboard interrupts, must be used
				;if the installed program checks the keyboard
				;from the VBI
	BITDEF WHDL,EmulLineA,7	;forward "line-a" exceptions to the handler
				;of the installed program
; version 9
	BITDEF WHDL,EmulTrapV,8	;forward "trapv" exceptions to the handler
				;of the installed program
; version 11
	BITDEF WHDL,EmulChk,9	;forward "chk, chk2" exceptions to the handler
				;of the installed program
	BITDEF WHDL,EmulPriv,10	;forward 'privilege violation' exceptions to
				;the handler of the installed program
; version 12
	BITDEF WHDL,EmulLineF,11 ;forward "line-f" exceptions to the handler
				;of the installed program
; version 13
	BITDEF WHDL,ClearMem,12	;initialize BaseMem and ExpMem with 0
; version 15
	BITDEF WHDL,Examine,13	;enables usage of resload_Examine/ExNext
; version 16
	BITDEF WHDL,EmulDivZero,14 ;forward 'division by zero' exceptions to
				;the handler of the installed program
	BITDEF WHDL,EmulIllegal,15 ;forward 'illegal instruction' exceptions to
				;the handler of the installed program

;=============================================================================
; properties for resload_SetCPU
;=============================================================================

WCPUF_Base	= 3		;BaseMem mask
WCPUF_Base_NCS	= 0		;BaseMem = non cacheable serialized
WCPUF_Base_NC	= 1		;BaseMem = non cacheable
WCPUF_Base_WT	= 2		;BaseMem = cacheable write through
WCPUF_Base_CB	= 3		;BaseMem = cacheable copyback
WCPUF_Exp	= 12		;ExpMem mask
WCPUF_Exp_NCS	= 0		;ExpMem = non cacheable serialized
WCPUF_Exp_NC	= 4		;ExpMem = non cacheable
WCPUF_Exp_WT	= 8		;ExpMem = cacheable write through
WCPUF_Exp_CB	= 12		;ExpMem = cacheable copyback
WCPUF_Slave	= 48		;Slave mask
WCPUF_Slave_NCS	= 0		;Slave = non cacheable serialized
WCPUF_Slave_NC	= 16		;Slave = non cacheable
WCPUF_Slave_WT	= 32		;Slave = cacheable write through
WCPUF_Slave_CB	= 48		;Slave = cacheable copyback

	BITDEF WCPU,IC,8	;instruction cache (20-60)
	BITDEF WCPU,DC,9	;data cache (30-60)
	BITDEF WCPU,NWA,10	;disable write allocation (30)
	BITDEF WCPU,SB,11	;store buffer (60)
	BITDEF WCPU,BC,12	;branch cache (60)
	BITDEF WCPU,SS,13	;superscalar dispatch (60)
	BITDEF WCPU,FPU,14	;enable fpu (60)

WCPUF_All	= WCPUF_Base!WCPUF_Exp!WCPUF_Slave!WCPUF_IC!WCPUF_DC!WCPUF_NWA!WCPUF_SB!WCPUF_BC!WCPUF_SS!WCPUF_FPU

;=============================================================================
; resload_#? functions
; a JMP-tower inside WHDLoad (similar to a library)
; base is given on startup via A0
;=============================================================================

    STRUCTURE	ResidentLoader,0
	ULONG	resload_Install		;private
	ULONG	resload_Abort
		; return to operating system (4)
		; IN: (a7) = ULONG  reason for aborting
		;   (4,a7) = ULONG  primary error code
		;   (8,a7) = ULONG  secondary error code
		; ATTENTION: this routine must be called via JMP (not JSR)
	ULONG	resload_LoadFile
		; load file to memory (8)
		; IN:	a0 = CSTR   filename
		;	a1 = APTR   address
		; OUT:	d0 = ULONG  success (size of file)
		;	d1 = ULONG  dos errorcode
	ULONG	resload_SaveFile
		; write memory to file (c)
		; IN:	d0 = ULONG  size
		;	a0 = CSTR   filename
		;	a1 = APTR   address
		; OUT:	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode
	ULONG	resload_SetCACR
		; set cachebility for BaseMem (10)
		; IN:	d0 = ULONG  new setup
		;	d1 = ULONG  mask
		; OUT:	d0 = ULONG  old setup
	ULONG	resload_ListFiles
		; list filenames of a directory (14)
		; IN:	d0 = ULONG  buffer size
		;	a0 = CSTR   name of directory to scan
		;	a1 = APTR   buffer (must be located inside Slave,
		;	with WHDLoad 16.8+ also inside ExpMem)
		; OUT:	d0 = ULONG  amount of names in buffer filled
		;	d1 = ULONG  dos errorcode
	ULONG	resload_Decrunch
		; uncompress data in memory (18)
		; IN:	a0 = APTR   source
		;	a1 = APTR   destination (can be equal to source)
		; OUT:	d0 = ULONG  uncompressed size
	ULONG	resload_LoadFileDecrunch
		; load file and uncompress it (1c)
		; IN:	a0 = CSTR   filename
		;	a1 = APTR   address
		; OUT:	d0 = ULONG  success (size of file uncompressed)
		;	d1 = ULONG  dos errorcode
	ULONG	resload_FlushCache
		; clear CPU caches (20)
		; IN:	-
		; OUT:	-
	ULONG	resload_GetFileSize
		; get size of a file (24)
		; IN:	a0 = CSTR   filename
		; OUT:	d0 = ULONG  size of file
	ULONG	resload_DiskLoad
		; load part from disk image (28)
		; IN:	d0 = ULONG  offset
		;	d1 = ULONG  size
		;	d2 = ULONG  disk number
		;	a0 = APTR   destination
		; OUT:	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode

******* the following functions require ws_Version >= 2

	ULONG	resload_DiskLoadDev
		; load part from physical disk via trackdisk (2c)
		; IN:	d0 = ULONG  offset
		;	d1 = ULONG  size
		;	a0 = APTR   destination
		;	a1 = STRUCT taglist
		; OUT:	d0 = BOOL   success
		;	d1 = ULONG  trackdisk errorcode

******* the following functions require ws_Version >= 3

	ULONG	resload_CRC16
		; calculate 16 bit CRC checksum (30)
		; IN:	d0 = ULONG  size
		;	a0 = APTR   address
		; OUT:	d0 = UWORD  CRC checksum

******* the following functions require ws_Version >= 5

	ULONG	resload_Control
		; misc control, get/set variables (34)
		; IN:	a0 = STRUCT taglist
		; OUT:	d0 = BOOL   success
	ULONG	resload_SaveFileOffset
		; write memory to file at offset (38)
		; IN:	d0 = ULONG  size
		;	d1 = ULONG  offset
		;	a0 = CSTR   filename
		;	a1 = APTR   address
		; OUT:	d0 = BOOL   success
		;	d1 = ULONG  dos errcode

******* the following functions require ws_Version >= 6

	ULONG	resload_ProtectRead
		; mark memory as read protected (3c)
		; IN:	d0 = ULONG  length
		;	a0 = APTR   address
		; OUT:	-
	ULONG	resload_ProtectReadWrite
		; mark memory as read and write protected (40)
		; IN:	d0 = ULONG  length
		;	a0 = APTR   address
		; OUT:	-
	ULONG	resload_ProtectWrite
		; mark memory as write protected (44)
		; IN:	d0 = ULONG  length
		;	a0 = APTR   address
		; OUT:	-
	ULONG	resload_ProtectRemove
		; remove memory protection (48)
		; IN:	d0 = ULONG  length
		;	a0 = APTR   address
		; OUT:	-
	ULONG	resload_LoadFileOffset
		; load part of file to memory (4c)
		; IN:	d0 = ULONG  size
		;	d1 = ULONG  offset
		;	a0 = CSTR   filename
		;	a1 = APTR   destination
		; OUT:	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode

******* the following functions require ws_Version >= 8

	ULONG	resload_Relocate
		; relocate AmigaDOS executable (50)
		; IN:	a0 = APTR   address (source=destination)
		;	a1 = STRUCT taglist
		; OUT:	d0 = ULONG  size
	ULONG	resload_Delay
		; wait some time or button pressed (54)
		; IN:	d0 = ULONG  time to wait in 1/10 seconds
		; OUT:	-
	ULONG	resload_DeleteFile
		; delete file (58)
		; IN:	a0 = CSTR   filename
		; OUT:	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode

******* the following functions require ws_Version >= 10

	ULONG	resload_ProtectSMC
		; detect self modifying code (5c)
		; IN:	d0 = ULONG  length
		;	a0 = APTR   address
		; OUT:	-
	ULONG	resload_SetCPU
		; control CPU setup (60)
		; IN:	d0 = ULONG  properties, see above
		;	d1 = ULONG  mask
		; OUT:	d0 = ULONG  old properties
	ULONG	resload_Patch
		; apply patchlist (64)
		; IN:	a0 = APTR   patchlist, see below
		;	a1 = APTR   destination address
		; OUT:	-

******* the following functions require ws_Version >= 11

	ULONG	resload_LoadKick
		; load kickstart image (68)
		; IN:	d0 = ULONG  length of image
		;	d1 = UWORD  crc16 of image
		;	a0 = CSTR   basename of image
		; OUT:	-
	ULONG	resload_Delta
		; apply WDelta data to modify memory (6c)
		; IN:	a0 = APTR   src data
		;	a1 = APTR   dest data
		;	a2 = APTR   wdelta data
		; OUT:	-
	ULONG	resload_GetFileSizeDec
		; get size of a packed file (70)
		; IN:	a0 = CSTR   filename
		; OUT:	d0 = ULONG  size of file uncompressed

******* the following functions require ws_Version >= 15

	ULONG	resload_PatchSeg
		; apply patchlist to a segment list (74)
		; IN:	a0 = APTR   patchlist, see below
		;	a1 = BPTR   segment list
		; OUT:	-

	ULONG	resload_Examine
		; examine a file or directory (78)
		; IN:	a0 = CSTR   name
		;	a1 = APTR   struct FileInfoBlock (260 bytes)
		; OUT:	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode

	ULONG	resload_ExNext
		; examine next entry of a directory (7c)
		; IN:	a0 = APTR   struct FileInfoBlock (260 bytes)
		; OUT:	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode

	ULONG	resload_GetCustom
		; get Custom argument (80)
		; IN:	d0 = ULONG  length of buffer
		;	d1 = ULONG  reserved, must be 0
		;	a0 = APTR   buffer
		; OUT:	d0 = BOOL   true if Custom has fit into buffer

******* the following functions require ws_Version >= 18

	ULONG	resload_VSNPrintF
		; format string like clib.vsnprintf/exec.RawDoFmt (84)
		; IN:	d0 = ULONG  length of buffer
		;	a0 = APTR   buffer to fill
		;	a1 = CPTR   format string
		;	a2 = APTR   argument array
		; OUT:	d0 = ULONG  length of created string with unlimited
		;		    buffer without final '\0'
		;	a0 = APTR   pointer to final '\0'

	ULONG	resload_Log
		; write log message (88)
		; IN:	a0 = CSTR   format string
		;   (4,a7) = LABEL  argument array
		; OUT:	-

******* the following functions require ws_Version >= 19

	ULONG	resload_ReadJoyPort
		; return the state of the selected joy/mouse port (8c)
		; IN:	d0 = ULONG  port/flags
		; OUT:	d0 = ULONG  state

	LABEL	resload_SIZEOF

******* compatibility for older slave sources:

resload_CheckFileExist = resload_GetFileSize

;=============================================================================
; commands used in patchlist
; each command follows the address to modify, if bit #15 of the command is
; cleared address follows as 32 bit, if bit #15 of the command is set it
; follows as 16 bit (unsigned extended to 32 bit)
; the following arguments differ for the various commands
; control commands (END, IF*, ELSE, ENDIF) does not follow an address, on 
; these commands (except END) bit #14 is set to indicate them
; see autodoc file whdload.doc for enhanced documentation and examples

 BITDEF PLCMD,WORDADR,15
 BITDEF PLCMD,CTRL,14

	ENUM	0
	EITEM	PLCMD_END		;end of list
	EITEM	PLCMD_R			;set RTS
	EITEM	PLCMD_P			;set JMP
	EITEM	PLCMD_PS		;set JSR
	EITEM	PLCMD_S			;set BRA (skip)
	EITEM	PLCMD_I			;set ILLEGAL
	EITEM	PLCMD_B			;write byte to specified address
	EITEM	PLCMD_W			;write word to specified address
	EITEM	PLCMD_L			;write long to specified address
; version 11
	EITEM	PLCMD_A			;write address which is calculated as
					;base + arg to specified address
; version 14
	EITEM	PLCMD_PA		;write address given by argument to
					;specified address
	EITEM	PLCMD_NOP		;fill given area with NOP instructions
; version 15
	EITEM	PLCMD_C			;clear n bytes
	EITEM	PLCMD_CB		;clear one byte
	EITEM	PLCMD_CW		;clear one word
	EITEM	PLCMD_CL		;clear one long
; version 16
	EITEM	PLCMD_PSS		;set JSR + NOP..
	EITEM	PLCMD_NEXT		;continue with another patch list
	EITEM	PLCMD_AB		;add byte to specified address
	EITEM	PLCMD_AW		;add word to specified address
	EITEM	PLCMD_AL		;add long to specified address
	EITEM	PLCMD_DATA		;write n data bytes to specified address
; version 16.5
	EITEM	PLCMD_ORB		;or byte to specified address
	EITEM	PLCMD_ORW		;or word to specified address
	EITEM	PLCMD_ORL		;or long to specified address
; version 16.6
	EITEM	PLCMD_GA		;get specified address and store it in the slave
; version 16.9
	EITEM	PLCMD_BKPT		;call freezer
	EITEM	PLCMD_BELL		;show visual bell
; version 17.2
	EITEM	PLCMD_IFBW		;condition if ButtonWait/S
	EITEM	PLCMD_IFC1		;condition if Custom1/N
	EITEM	PLCMD_IFC2		;condition if Custom2/N
	EITEM	PLCMD_IFC3		;condition if Custom3/N
	EITEM	PLCMD_IFC4		;condition if Custom4/N
	EITEM	PLCMD_IFC5		;condition if Custom5/N
	EITEM	PLCMD_IFC1X		;condition if bit of Custom1/N
	EITEM	PLCMD_IFC2X		;condition if bit of Custom2/N
	EITEM	PLCMD_IFC3X		;condition if bit of Custom3/N
	EITEM	PLCMD_IFC4X		;condition if bit of Custom4/N
	EITEM	PLCMD_IFC5X		;condition if bit of Custom5/N
	EITEM	PLCMD_ELSE		;condition alternative
	EITEM	PLCMD_ENDIF		;end of condition block

;=============================================================================
; macros to build patchlist

PLIFCNTCHK	MACRO
	IFNE PLIFCNT
	FAIL	\1 pairs of IF* and ENDIF do not match
	ENDC
	ENDM
PLIFCNTINC	MACRO
PLIFCNT SET PLIFCNT+1
	ENDM

PL_START	MACRO			;start of patchlist
PLIFCNT SET 0				;counts if nesting
.patchlist
		ENDM

PL_END		MACRO			;end of patchlist
	PLIFCNTCHK PL_END
	dc.w	PLCMD_END
		ENDM

PL_CMDADR	MACRO			;set cmd and address
	IFLT \2
	FAIL	PL_CMDADR patch address cannot be negative
	ENDC
	IFLT $ffff-\2
	dc.w	\1
	dc.l	\2
	ELSE
	dc.w	PLCMDF_WORDADR+\1
	dc.w	\2
	ENDC
	ENDM

PL_R		MACRO			;set "rts"
	IFNE	NARG-1
	FAIL	PL_R wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_R,\1
		ENDM

PL_PS		MACRO			;set "jsr"
	IFNE	NARG-2
	FAIL	PL_PS wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_PS,\1
	dc.w	\2-.patchlist		;destination (inside slave!)
		ENDM

PL_P		MACRO			;set "jmp"
	IFNE	NARG-2
	FAIL	PL_P wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_P,\1
	dc.w	\2-.patchlist		;destination (inside slave!)
		ENDM

PL_S		MACRO			;skip bytes, set "bra"
	IFNE	NARG-2
	FAIL	PL_S wrong number of arguments
	ENDC
	IFLT $8000-(\2)
	FAIL PL_S positive distance \2 too large, max is $8000
	ENDC
	IFGT -$7ffe-(\2)
	FAIL PL_S negative distance \2 too large, max is -$7ffe
	ENDC
	PL_CMDADR PLCMD_S,\1
	dc.w	\2-2			;distance
		ENDM

PL_I		MACRO			;set "illegal"
	IFNE	NARG-1
	FAIL	PL_I wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_I,\1
		ENDM

PL_B		MACRO			;write byte
	IFNE	NARG-2
	FAIL	PL_B wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_B,\1
	dc.w	\2			;data to write
		ENDM

PL_W		MACRO			;write word
	IFNE	NARG-2
	FAIL	PL_W wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_W,\1
	dc.w	\2			;data to write
		ENDM

PL_L		MACRO			;write long
	IFNE	NARG-2
	FAIL	PL_L wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_L,\1
	dc.l	\2			;data to write
		ENDM

; version 11

PL_A		MACRO			;write address (base+arg)
	IFNE	NARG-2
	FAIL	PL_A wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_A,\1
	dc.l	\2			;data to write
		ENDM

; version 14

PL_PA		MACRO			;write address
	IFNE	NARG-2
	FAIL	PL_PA wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_PA,\1
	dc.w	\2-.patchlist		;destination (inside slave!)
		ENDM

PL_NOP		MACRO			;fill area with NOPs
	IFNE	NARG-2
	FAIL	PL_NOP wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_NOP,\1
	dc.w	\2			;distance given in bytes
		ENDM
PL_NOPS		MACRO			;fill area with NOPs
	IFNE	NARG-2
	FAIL	PL_NOPS wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_NOP,\1
	dc.w	2*\2			;distance given in NOP count
		ENDM

; version 15

PL_C		MACRO			;clear area
	IFNE	NARG-2
	FAIL	PL_C wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_C,\1
	dc.w	\2			;length
		ENDM

PL_CB		MACRO			;clear one byte
	IFNE	NARG-1
	FAIL	PL_CB wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_CB,\1
		ENDM

PL_CW		MACRO			;clear one word
	IFNE	NARG-1
	FAIL	PL_CW wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_CW,\1
		ENDM

PL_CL		MACRO			;clear one long
	IFNE	NARG-1
	FAIL	PL_CL wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_CL,\1
		ENDM

; version 16

PL_PSS		MACRO			;set JSR, NOP..
	IFNE	NARG-3
	FAIL	PL_PSS wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_PSS,\1
	dc.w	\2-.patchlist		;destination (inside slave!)
	dc.w	\3			;byte count of NOPs to append
		ENDM

PL_NEXT		MACRO			;continue with another patch list
	IFNE	NARG-1
	FAIL	PL_NEXT wrong number of arguments
	ENDC
	PLIFCNTCHK PL_NEXT
	PL_CMDADR PLCMD_NEXT,0
	dc.w	\1-.patchlist		;destination (inside slave!)
		ENDM

PL_AB		MACRO			;add byte
	IFNE	NARG-2
	FAIL	PL_AB wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_AB,\1
	dc.w	\2			;data to add
		ENDM

PL_AW		MACRO			;add word
	IFNE	NARG-2
	FAIL	PL_AW wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_AW,\1
	dc.w	\2			;data to add
		ENDM

PL_AL		MACRO			;add long
	IFNE	NARG-2
	FAIL	PL_AL wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_AL,\1
	dc.l	\2			;data to add
		ENDM

; there are three macros provided for the DATA command, if you want change a 
; string PL_STR can be used:
;	PL_STR	$340,<NewString!>
; if the string should be 0-terminated at the destination PL_STR0 can be used:
;	PL_STR0	$340,<New C-String>
; for binary data you must use PL_DATA according the following example:
;	PL_DATA	$350,.stop-.strt
; .strt	dc.b	2,3,$ff,'a',0
;	move.w	#$600,d0
; .stop	EVEN

PL_DATA		MACRO			;write n bytes to specified address
	IFNE	NARG-2
	FAIL	PL_DATA wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_DATA,\1
	dc.w	\2			;count of bytes to write
		ENDM

PL_STR		MACRO
	IFNE	NARG-2
	FAIL	PL_STR wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_DATA,\1
	dc.w	.dat2\@-.dat1\@
.dat1\@	dc.b	"\2"
.dat2\@	EVEN
		ENDM	

PL_STR0		MACRO
	IFNE	NARG-2
	FAIL	PL_STR0 wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_DATA,\1
	dc.w	.dat2\@-.dat1\@
.dat1\@	dc.b	"\2",0
.dat2\@	EVEN
		ENDM	

; version 16.5

PL_ORB		MACRO			;or byte
	IFNE	NARG-2
	FAIL	PL_ORB wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_ORB,\1
	dc.w	\2			;data to or
		ENDM

PL_ORW		MACRO			;or word
	IFNE	NARG-2
	FAIL	PL_ORW wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_ORW,\1
	dc.w	\2			;data to or
		ENDM

PL_ORL		MACRO			;or long
	IFNE	NARG-2
	FAIL	PL_ORL wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_ORL,\1
	dc.l	\2			;data to or
		ENDM

; version 16.6

PL_GA		MACRO			;get address
	IFNE	NARG-2
	FAIL	PL_GA wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_GA,\1
	dc.w	\2-.patchlist		;destination (inside slave!)
		ENDM

; version 16.9

; PL_BKPT sets a breakpoint:
; WHDLoad will write an ILLEGAL ($4afc) to the address and remembers the
; original contents, when the ILLEGAL is executed the original contents is
; restored, a NMI stackframe is created and the detected freezer called
; if there is no freezer nothing will be done, the VBR should be moved by
; WHDLoad to allow catching the illegal instruction exception

PL_BKPT		MACRO
	IFNE	NARG-1
	FAIL	PL_BKPT wrong number of arguments
	ENDC
	PL_CMDADR PLCMD_BKPT,\1
		ENDM

; PL_BELL shows a visual bell:
; similar to PL_BKPT, instead of entering a freezer a color cycle will be
; shown for the given time or lmb pressed, time is given in 1/10s

PL_BELL		MACRO
	IFNE	NARG-2
	FAIL	PL_BELL wrong number of arguments (adr,time)
	ENDC
	PL_CMDADR PLCMD_BELL,\1
	dc.w	\2			;time to wait
		ENDM

; version 17.2

PL_IFBW		MACRO
	IFNE	NARG
	FAIL	PL_IFBW no arguments allowed
	ENDC
	PLIFCNTINC
	dc.w	PLCMDF_CTRL+PLCMD_IFBW
		ENDM
PL_IFC1		MACRO
	IFNE	NARG
	FAIL	PL_IFC1 no arguments allowed
	ENDC
	PLIFCNTINC
	dc.w	PLCMDF_CTRL+PLCMD_IFC1
		ENDM
PL_IFC2		MACRO
	IFNE	NARG
	FAIL	PL_IFC2 no arguments allowed
	ENDC
	PLIFCNTINC
	dc.w	PLCMDF_CTRL+PLCMD_IFC2
		ENDM
PL_IFC3		MACRO
	IFNE	NARG
	FAIL	PL_IFC3 no arguments allowed
	ENDC
	PLIFCNTINC
	dc.w	PLCMDF_CTRL+PLCMD_IFC3
		ENDM
PL_IFC4		MACRO
	IFNE	NARG
	FAIL	PL_IFC4 no arguments allowed
	ENDC
	PLIFCNTINC
	dc.w	PLCMDF_CTRL+PLCMD_IFC4
		ENDM
PL_IFC5		MACRO
	IFNE	NARG
	FAIL	PL_IFC5 no arguments allowed
	ENDC
	PLIFCNTINC
	dc.w	PLCMDF_CTRL+PLCMD_IFC5
		ENDM
PL_IFC1X	MACRO
	IFNE	NARG-1
	FAIL	PL_IFC1X wrong number of arguments
	ENDC
	IFGT	\1-31
	FAIL	PL_IFC1X bit number must be 0..31
	ENDC
	PLIFCNTINC
	dc.w	PLCMDF_CTRL+PLCMD_IFC1X,\1
		ENDM
PL_IFC2X	MACRO
	IFNE	NARG-1
	FAIL	PL_IFC2X wrong number of arguments
	ENDC
	IFGT	\1-31
	FAIL	PL_IFC2X bit number must be 0..31
	ENDC
	PLIFCNTINC
	dc.w	PLCMDF_CTRL+PLCMD_IFC2X,\1
		ENDM
PL_IFC3X	MACRO
	IFNE	NARG-1
	FAIL	PL_IFC3X wrong number of arguments
	ENDC
	IFGT	\1-31
	FAIL	PL_IFC3X bit number must be 0..31
	ENDC
	PLIFCNTINC
	dc.w	PLCMDF_CTRL+PLCMD_IFC3X,\1
		ENDM
PL_IFC4X	MACRO
	IFNE	NARG-1
	FAIL	PL_IFC4X wrong number of arguments
	ENDC
	IFGT	\1-31
	FAIL	PL_IFC4X bit number must be 0..31
	ENDC
	PLIFCNTINC
	dc.w	PLCMDF_CTRL+PLCMD_IFC4X,\1
		ENDM
PL_IFC5X	MACRO
	IFNE	NARG-1
	FAIL	PL_IFC5X wrong number of arguments
	ENDC
	IFGT	\1-31
	FAIL	PL_IFC5X bit number must be 0..31
	ENDC
	PLIFCNTINC
	dc.w	PLCMDF_CTRL+PLCMD_IFC5X,\1
		ENDM
PL_ELSE		MACRO
	IFNE	NARG
	FAIL	PL_ELSE no arguments allowed
	ENDC
	IFLE PLIFCNT
	FAIL	PL_ELSE there must be an PL_IF* before
	ENDC
	dc.w	PLCMDF_CTRL+PLCMD_ELSE
		ENDM
PL_ENDIF	MACRO
	IFNE	NARG
	FAIL	PL_ENDIF no arguments allowed
	ENDC
	IFLE PLIFCNT
	FAIL	PL_ENDIF there must be an PL_IF* before
	ENDC
PLIFCNT SET PLIFCNT-1
	dc.w	PLCMDF_CTRL+PLCMD_ENDIF
		ENDM

;=============================================================================
; flags for resload_ReadJoyPort
;=============================================================================

; input flags:

 BITDEF RJP,DETECT,31		; request new detection (GAMECTRL/JOYSTK)
 BITDEF RJP,WANTMOUSE,30	; get mouse result

; output flags:

RJP_TYPE_GAMECTRL = 1<<28	; cd32pad
RJP_TYPE_MOUSE = 2<<28		; mouse
RJP_TYPE_JOYSTK = 3<<28		; joystick
RJP_TYPE_MASK	= 15<<28

 BITDEF RJP,BLUE,23		; pad-blue/stop, mouse-right, stick-2nd-fire
 BITDEF RJP,RED,22		; pad-red/select, mouse-left, stick-fire
 BITDEF RJP,YELLOW,21		; pad-yellow/repeat
 BITDEF RJP,GREEN,20		; pad-green/shuffle
 BITDEF RJP,FORWARD,19		; pad-forward
 BITDEF RJP,REVERSE,18		; pad-reverse
 BITDEF RJP,PLAY,17		; pad-play/pause, mouse-middle, stick-3rd-fire

 BITDEF RJP,UP,3
 BITDEF RJP,DOWN,2
 BITDEF RJP,LEFT,1
 BITDEF RJP,RIGHT,0

RJP_MHORZ_MASK = 255<<0		; mouse horizontal position
RJP_MVERT_MASK = 255<<8		; mouse vertical position

;=============================================================================

 ENDC
