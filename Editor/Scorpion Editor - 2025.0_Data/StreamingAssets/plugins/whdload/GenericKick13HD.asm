;*---------------------------------------------------------------------------
;  :Program.	GenericKickHD.asm
;  :Contents.	Slave for "GenericKick"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: GenericKick13HD.asm 1.6 2023/02/19 03:23:44 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta      
;		01.11.07 reworked for v16+ (Wepl)
;		24.04.16 version bump
;		15.11.21 updated for new kickemu, _cb_dosLoadSeg added
;		28.09.22 ignore unset names in _cb_dosLoadSeg
;		19.02.23 WHDCTRL added
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
	OUTPUT	"GenericKick13.slave"
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
BOOTDOS			;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
;CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
;DEBUG				;add more internal checks (Earok - We don't want this?)
;DISKSONBOOT			;insert disks in floppy drives
;DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
HDINIT				;initialize filesystem handler
;HRTMON				;add support for HrtMON (Earok - we don't want this?)
IOCACHE		= 8192		;cache for the filesystem handler (per fh)
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
;POINTERTICKS	= 1		;set mouse speed (Earok - don't need this?)
;SEGTRACKER			;add segment tracker (Earok - don't need this?)
;SETKEYBOARD			;activate host keymap  (Earok - don't need this?)
SETPATCH			;enable patches from SetPatch 1.38
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
	INCLUDE	whdload/kick13.s

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
; callback/hook which gets executed after each successful call to dos.LoadSeg
; can also be used instead of _bootdos, requires the presence of
; "startup-sequence"
; if you use diskimages that is the way to patch the executables

; the following example uses a parameter table to patch different executables
; after they get loaded

	IFD CBDOSLOADSEG

; D0 = BSTR name of the loaded program as BCPL string
; D1 = BPTR segment list of the loaded program as BCPL pointer

_cb_dosLoadSeg	lsl.l	#2,d0		;-> APTR
		beq	.end		;ignore if name is unset
		move.l	d0,a0
		moveq	#0,d0
		move.b	(a0)+,d0	;D0 = name length
	;remove leading path
		move.l	a0,a1
		move.l	d0,d2
.path		move.b	(a1)+,d3
		subq.l	#1,d2
		cmp.b	#":",d3
		beq	.skip
		cmp.b	#"/",d3
		bne	.chk
.skip		move.l	a1,a0		;A0 = name
		move.l	d2,d0		;D0 = name length
.chk		tst.l	d2
		bne	.path
	;get hunk length sum
		move.l	d1,a1		;D1 = segment
		moveq	#0,d2
.add		add.l	a1,a1
		add.l	a1,a1
		add.l	(-4,a1),d2	;D2 = hunks length
		subq.l	#8,d2		;hunk header
		move.l	(a1),a1
		move.l	a1,d7
		bne	.add
	;search patch
		lea	(_cbls_patch,pc),a1
.next		move.l	(a1)+,d3
		movem.w	(a1)+,d4-d5
		beq	.end
		cmp.l	d2,d3		;length match?
		bne	.next
	;compare name
		lea	(_cbls_patch,pc,d4.w),a2
		move.l	a0,a3
		move.l	d0,d6
.cmp		move.b	(a3)+,d7
		cmp.b	#"a",d7
		blo	.l
		cmp.b	#"z",d7
		bhi	.l
		sub.b	#$20,d7
.l		cmp.b	(a2)+,d7
		bne	.next
		subq.l	#1,d6
		bne	.cmp
		tst.b	(a2)
		bne	.next
	;set debug
	IFD DEBUG
		clr.l	-(a7)
		move.l	d1,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		move.l	(_resload,pc),a2
		jsr	(resload_Control,a2)
		move.l	(4,a7),d1
		add.w	#12,a7
	ENDC
	;patch
		lea	(_cbls_patch,pc,d5.w),a0
		move.l	d1,a1
		move.l	(_resload,pc),a2
		jsr	(resload_PatchSeg,a2)
	;end
.end		rts

LSPATCH	MACRO
		dc.l	\1		;cumulated size of hunks (not filesize!)
		dc.w	\2-_cbls_patch	;name
		dc.w	\3-_cbls_patch	;patch list
	ENDM

_cbls_patch	LSPATCH	2516,.n_run,_p_run2568
		LSPATCH	7080,.n_shellseg,_p_shellseg7080
		LSPATCH	2956,.n_assign,_p_assign3008
		dc.l	0

	;all upper case!
.n_run		dc.b	"RUN",0
.n_shellseg	dc.b	"SHELL-SEG",0
.n_assign	dc.b	"ASSIGN",0
	EVEN

_p_assign3008	PL_START
	;	PL_BKPT	$542			;access fault follows
		PL_B	$546,$60		;beq -> bra
		PL_END
_p_run2568	PL_START
		PL_END
_p_shellseg7080	PL_START
		PL_AW	$1990,$1a4c-$19ae	;dereferences NULL (maybe dirlock because actual directory is broken)
		PL_END

	ENDC

;============================================================================

	INCLUDE	GenericKickHD.asm

