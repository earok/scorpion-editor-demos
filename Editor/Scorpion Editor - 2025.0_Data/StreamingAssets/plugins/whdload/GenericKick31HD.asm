;*---------------------------------------------------------------------------
;  :Program.	GenericKickHD.asm
;  :Contents.	Slave for "GenericKick"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: GenericKick31HD.asm 1.5 2022/10/03 14:35:40 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
;		01.11.07 reworked for v16+ (Wepl)
;		24.04.16 version bump
;		15.11.21 updated for new kickemu
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
;	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"GenericKick31.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimize warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= {chip_mem_size}	;size of chip memory
FASTMEMSIZE	= {fast_mem_size}	;size of fast memory
NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %0000		;write protection of floppy drives

BLACKSCREEN			;set all initial colors to black
;BOOTBLOCK			;enable _bootblock routine
BOOTDOS				;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
;CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
;DEBUG				;enable additional internal checks (Earok - we don't want this?)
;DISKSONBOOT			;insert disks in floppy drives
;DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
HDINIT				;initialize filesystem handler
;HRTMON				;add support for HrtMON (Earok - we don't want this?)
INITAGA			;enable AGA features (Earok - we do want AGA)
;INIT_AUDIO			;enable audio.device
;INIT_GADTOOLS			;enable gadtools.library
;INIT_LOWLEVEL			;load lowlevel.library
;INIT_MATHFFP			;enable mathffp.library
;INIT_NONVOLATILE		;init nonvolatile.library
;INIT_RESOURCE			;init whdload.resource
IOCACHE		= 10000		;cache for the filesystem handler (per fh)
;JOYPADEMU			;use keyboard for joypad buttons
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
;NO68020				;remain 68000 compatible (Earok - we only use this for AGA, so we can assume an 68020)
;POINTERTICKS	= 1		;set mouse speed
;PROMOTE_DISPLAY		;allow DblPAL/NTSC promotion
;SEGTRACKER			;add segment tracker (Earok - don't need this?)
;SETKEYBOARD			;activate host keymap (Earok - don't need this?)
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine
;WHDCTRL				;add WHDCtrl resident command (Earok - don't need this)

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D

;============================================================================

	INCDIR	Sources:
	INCLUDE	whdload/kick31.s

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"{project_name}",0
slv_copy	dc.b	"{copyright_year} {publisher}",0
slv_info	dc.b	"by {author}",10
		dc.b	"Version {version} "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
	EVEN

;============================================================================

	INCLUDE	GenericKickHD.asm

