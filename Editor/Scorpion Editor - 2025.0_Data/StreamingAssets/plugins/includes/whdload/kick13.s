;*---------------------------------------------------------------------------
;  :Modul.	kick13.s
;  :Contents.	interface code and patches for kickstart 1.3
;  :Author.	Wepl, Psygore
;  :Version.	$Id: kick13.s 0.84 2024/06/11 00:49:19 wepl Exp wepl $
;  :History.	19.10.99 started
;		18.01.00 trd_write with writeprotected fixed
;			 diskchange fixed
;		24.01.00 reworked to assemble with Asm-Pro
;		20.02.00 problems with Snoop/S on 68060 fixed
;		21.02.00 cbswitch added (cop2lc)
;		22.02.00 free memory count added
;		01.03.00 wait in _trd_changedisk removed because deadlocks
;		09.03.00 adapted for whdload v11
;		17.03.00 most stuff from SetPatch 1.38 added
;		20.03.00 some fixes for 68060 and snoop
;		16.04.00 loadview fixed
;		11.05.00 SetPatch can be enabled/disabled via a defined label
;		19.06.01 ChkBltWait problem fixed in blitter init
;		15.07.01 using time provided by whdload to init timer.device
;		02.08.01 exec.Supervisor fixed (to work with exec.SuperState)
;		03.08.01 NOFPU->NEEDFPU changed, DISKSONBOOT added
;			 bug in trackdisk fixed (endio missing on error)
;		04.08.01 flushcache and callback for dos.LoadSeg added
;		05.08.01 hd supported started
;		01.09.01 trap #15 to trap #14 changed in _Supervisor (debug rnc)
;			 BLACKSCREEN added
;		08.11.01 Supervisor patch removed, slaves now require
;			 WHDLF_EmulPriv to be set
;		27.11.01 fs enhanced
;		17.12.01 beta finished for Elvira
;		04.01.02 MAXFILENAME removed
;		16.01.02 support for Guru Meditation added
;		30.01.02 write cache added
;		06.02.02 cleanup
;		27.02.02 trailing slash in .buildname removed
;		05.03.02 modification of filter by kick disabled (Psygore)
;		17.04.02 POINTERTICKS added
;			 ACTION_DELETE_OBJECT fixed for nonexistent objects
;			 filesystem handler moved to kickfs.s
;		18.11.02 illegal trackdisk-patches enabled if DEBUG
;		30.11.02 FONTHEIGHT added
;		13.02.03 snoopbug at $6efe fixed (Psygore)
;			 STACKSIZE added (Captain HIT)
;		30.03.03 _bootearly/block made returnable
;		06.04.03 cache option added
;		15.05.03 patch for exec.ExitIntr to avoid double ints
;		11.06.03 patch for access fault from EndCLI (JOTD)
;		20.06.03 adapted for whdload v16
;		25.06.03 _dos_assign parameter change
;		09.12.03 keyboard acknowledgment fixed
;		06.02.04 keyboard acknowledgment fix fixed
;		19.02.04 clearing ciasdr removed
;		15.11.04 _keydebug/exit check added
;		26.01.05 trackdisk device IO_ACTUAL field set (Hacker uses this)
;		02.05.06 made compatible to ASM-One
;		04.05.06 patches added to avoid overwriting the vector table (68000 support)
;		18.08.07 fix for snoopbug at $6efe corrected (Psygore)
;		07.11.07 _debug5 added
;		04.12.07 patch for exec.ExitIntr improved
;		26.10.08 detect dependency between HDINIT and BOOTDOS
;		16.11.08 traps via the operating system are allowed again, reverting the
;			 change from 04.05.06 partial (JOTD and Gravity)
;		20.11.10 _cb_keyboard added
;		22.07.11 adapted for whdload v17
;		16.04.12 keyboard_start fixed for Snoop on 68060 (Psygore)
;		03.02.13 fix for LoadView(0)
;		14.02.16 with option CACHE chip memory is now WT instead NC
;		02.01.17 host system gb_bplcon0 is now honored (genlock/lace)
;		29.03.17 NEEDFPU enables FPU with SetCPU now
;		07.10.17 gfx.WaitBlit replaced with routine from kick31
;			 gfx.Text fixed to work with data cache enabled in chip memory
;			 reverted change from 14.02.16: option CACHE sets chip memory NC
;			 without a CACHE* option caches are switched off now!
;			 new option CACHECHIP enables only IC and sets chip memory WT
;			 new option CACHECHIPDATA enables IC/DC and sets chip memory WT
;		01.01.19 calculation of exec.ChkSum corrected
;			 support for SEGTRACKER added
;		15.01.19 key repeat after osswitch disabled in input.device
;		08.11.19 waitblit added to gfx_text patch (Psygore)
;		12.05.20 set WHDLF_Examine if HDINIT is set
;		22.12.20 added keymap loading
;		01.01.21 SEGTRACKER init performed earlier to avoid that UnLoadSeg gets
;			 called before (JOTD)
;		02.01.21 includes changed from Sources:whdload/... to whdload/...
;		02.08.21 patch for gfx_WaitBlit added
;		05.02.23 WHDCTRL added
;		19.02.23 CLI/Resident patch for WHDCtrl added
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, ASM-One 1.44, Asm-Pro 1.17, PhxAss 4.38
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	lvo/dos.i
	INCLUDE	lvo/exec.i
	INCLUDE	lvo/graphics.i
	INCLUDE	devices/keymap.i
	INCLUDE	devices/trackdisk.i
	INCLUDE	exec/memory.i
	INCLUDE	graphics/gfxbase.i
	INCLUDE	hardware/cia.i
	INCLUDE	hardware/custom.i
	INCLUDE	hardware/dmabits.i

	IFND	_custom
_custom		= $dff000
_ciaa		= $bfe001
	ENDC

KICKVERSION	= 34
KICKCRC		= $f9e3				;34.005

;============================================================================

	IFD	slv_Version
	IFLT	slv_Version-16
	FAIL	slv_Version must be 16 or higher
	ENDC

slv_FlagsAdd SET WHDLF_EmulPriv
	IFD HDINIT
slv_FlagsAdd SET slv_FlagsAdd|WHDLF_Examine
	ENDC

KICKSIZE	= $40000			;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

slv_base	SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	slv_Version		;ws_Version
		dc.w	slv_Flags|slv_FlagsAdd	;ws_flags
_basemem	dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_boot-slv_base		;ws_GameLoader
		dc.w	slv_CurrentDir-slv_base	;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	slv_keyexit		;ws_keyexit
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	slv_name-slv_base	;ws_name
		dc.w	slv_copy-slv_base	;ws_copy
		dc.w	slv_info-slv_base	;ws_info
		dc.w	slv_kickname-slv_base	;ws_kickname
		dc.l	KICKSIZE		;ws_kicksize
		dc.w	KICKCRC			;ws_kickcrc
	IFGE slv_Version-17
		dc.w	slv_config-slv_base	;ws_config
	ENDC
	ENDC

;============================================================================
; the following is to avoid "Error 86: Internal global optimize error" with
; BASM, which is caused by "IFD _label" and _label is defined after the IFD

	IFND BOOTBLOCK
	IFD _bootblock
BOOTBLOCK = 1
	ENDC
	ENDC
	IFND BOOTDOS
	IFD _bootdos
BOOTDOS = 1
	ENDC
	ENDC
	IFND BOOTEARLY
	IFD _bootearly
BOOTEARLY = 1
	ENDC
	ENDC
	IFND CBDOSREAD
	IFD _cb_dosRead
CBDOSREAD = 1
	ENDC
	ENDC
	IFND CBDOSLOADSEG
	IFD _cb_dosLoadSeg
CBDOSLOADSEG = 1
	ENDC
	ENDC
	IFND CBKEYBOARD
	IFD _cb_keyboard
CBKEYBOARD = 1
	ENDC
	ENDC

	IFD	BOOTDOS
	IFND	HDINIT
	FAIL	BOOTDOS/_bootdos requires HDINIT to be set
	ENDC
	ENDC

;============================================================================

_boot		lea	(_resload,pc),a1
		move.l	a0,(a1)				;save for later use
		move.l	a0,a5				;A5 = resload

WCPU_VAL SET 0
	IFD CACHE
WCPU_VAL SET WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB
	ENDC
	IFD CACHECHIP
WCPU_VAL SET WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_BC|WCPUF_SS|WCPUF_SB
	ENDC
	IFD CACHECHIPDATA
WCPU_VAL SET WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB
	ENDC
	IFD NEEDFPU
WCPU_VAL SET WCPU_VAL|WCPUF_FPU
	ENDC
	;setup cache/fpu
		move.l	#WCPU_VAL,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a5)

	;relocate some addresses
		lea	(_cbswitch,pc),a0
		lea	(_cbswitch_tag,pc),a1
		move.l	a0,(a1)

	;get tags
		lea	(_tags,pc),a0
		jsr	(resload_Control,a5)

	IFND slv_Version
	;load kickstart
		move.l	#KICKSIZE,d0			;length
		move.w	#KICKCRC,d1			;crc16
		lea	(slv_kickname,pc),a0		;name
		jsr	(resload_LoadKick,a5)
	ENDC

	;patch the kickstart
		lea	(kick_patch,pc),a0
		move.l	(_expmem,pc),a1
		jsr	(resload_Patch,a5)

	;call
kick_reboot	move.l	(_expmem,pc),a0
		jmp	(2,a0)				;original entry

kick_patch	PL_START
		PL_S	$d2,$fe-$d2
		PL_L	$106,$02390002			;skip LED power off (and.b #~CIAF_LED,$bfe001)
		PL_CW	$132				;color00 $444 -> $000
		PL_S	$136,$148-$136			;avoid overwriting vector table
		PL_W	$22e,$400			;avoid overwriting vector table
		PL_CW	$25a				;color00 $888 -> $000
	IFD HRTMON
		PL_PS	$286,kick_hrtmon
	ENDC
		PL_PS	$3d6,kick_setvecs
		PL_S	$3ec,12				;avoid overwriting vector table
		PL_PS	$422,exec_flush
		PL_W	$446,$17			;correct calc of exec.ChkSum
		PL_L	$4f4,-1				;disable search for residents at $f00000
		PL_S	$50C,$514-$50C			;skip LED power on
		PL_P	$546,kick_detectcpu
		PL_P	$592,kick_detectchip
		PL_P	$5f0,kick_reboot		;reboot (reset)
		PL_P	$61a,kick_detectfast
		PL_PS	$e9c,exec_ExitIntr
		PL_C	$7b4,$7c0-$7b4			;avoid overwriting vector table
		PL_C	$7c2,$7e2-$7c2			;avoid overwriting vector table
		PL_CW	$7ee				;avoid overwriting vector table
		PL_P	$1354,exec_snoop1
		PL_PS	$14b6,exec_SetFunction
		PL_PS	$15b2,exec_MakeFunctions
	IFD MEMFREE
		PL_P	$1826,exec_AllocMem
	ENDC
		PL_S	$4964,$4978-$4964		;skip disk unit detect
		PL_P	$4adc,disk_getunitid
		PL_S	$4cce,4				;skip autoconfiguration at $e80000
		PL_P	$5a58,gfx_waitblit
		PL_PS	$6d70,gfx_vbserver
		PL_PS	$6d86,gfx_snoop1
		PL_DATA	$6efe,8				;snoop bug ('and.w #$20,$DFF01E')
			btst #5,$dff01f
		PL_PS	$80d0,gfx_text
		PL_PS	$ad5e,gfx_setcoplc
		PL_S	$ad7a,6				;avoid ChkBltWait problem
		PL_S	$aecc,$e4-$cc			;skip color stuff & strange gb_LOFlist set
		PL_P	$af96,gfx_detectgenlock
		PL_P	$b00c,gfx_detectdisplay
		PL_PA	$b0ee,gfx_WaitBlit
		PL_PS	$d5be,gfx_fix1			;gfx_LoadView
		PL_S	$d5e2,6				;fix that LoadView(0) will set an corrupt clist to gb_LOFlist
	IFD FONTHEIGHT
		PL_B	$1b96c,FONTHEIGHT
	ENDC
	IFD BLACKSCREEN
		PL_C	$1b9d2,6			;color17,18,19
		PL_C	$1b9da,8			;color0,1,2,3
	ENDC
	IFD POINTERTICKS
		PL_W	$1b9d8,POINTERTICKS
	ENDC
		PL_PS	$25290,keyboard_start
		PL_PS	$253a2,keyboard_end
		PL_PS	$25e42,input_task
	IFD SETKEYBOARD
		PL_P	$27f76,keymap_addmap
	ENDC
	IFD HDINIT
		PL_PS	$28452,hd_init			;enter while starting strap
	ENDC
	IFD BOOTEARLY
		PL_PS	$284fa,kick_bootearly
	ENDC
	IFD BOOTBLOCK
		PL_PS	$285c6,kick_bootblock		;a1=ioreq a4=buffer a6=execbase
	ENDC
		PL_P	$28f88,timer_init
		PL_P	$2960c,trd_task
		PL_P	$29cfa,trd_format
		PL_P	$2a0e2,trd_motor
		PL_P	$2a3b4,trd_readwrite
		PL_PS	$2a6d6,trd_protstatus
	IFD DEBUG
		PL_L	$29c54,-1			;disable asynchron io
		PL_I	$2a19c				;empty dbf-loop in trackdisk.device
		PL_I	$2a5d8				;internal readwrite
		PL_I	$2a694				;trd_seek
		PL_I	$2af68				;trd_rawread
		PL_I	$2af6e				;trd_rawwrite
	ENDC
		PL_PS	$33ef0,dos_init
		PL_PS	$3568c,dos_endcli
		PL_PS	$36e4c,dos_LoadSeg
	IFD SEGTRACKER
		PL_PS	$377ca,dos_UnLoadSeg
	ENDC
	IFD WHDCTRL
		PL_PS	$38736,dos_whdctrl
		PL_PS	$39232,dos_residentload
		PL_PS	$394dc,dos_residentunload
	ENDC
	IFD BOOTDOS
		PL_PS	$38748,dos_bootdos
	ENDC
	IFD STACKSIZE
		PL_L	$387be,STACKSIZE/4
	ENDC
		PL_PS	$3c9b6,dos_1
	;the following stuff is from SetPatch 1.38
	IFD SETPATCH
		PL_P	$11b0,exec_UserState
		PL_P	$1696,exec_FindName
		PL_P	$195a,exec_AllocEntry
		PL_PS	$582c,gfx_MrgCop
		PL_PS	$7f66,gfx_SetFont
		PL_P	$7fa6,gfx_SetSoftStyle
	ENDC
		PL_END

;============================================================================

kick_setvecs	move.w	(a1)+,d0
		beq	.skip
		lea	(a0,d0.w),a3
		move.l	a3,(a2)
.skip		addq.l	#4,a2
		cmp.w	#$c0,a2			;stop after trap #15
		bne	kick_setvecs
		add.l	#$3e2-$3d6-6,(a7)
		rts

kick_detectfast
	IFEQ FASTMEMSIZE
		sub.l	a4,a4
	ELSE
		move.l	(_expmem,pc),a4
		add.l	#KICKSIZE,a4
		move.l	a4,($1f0-$1ea,a5)
		move.l	a4,($1fc-$1ea,a5)
		add.l	#FASTMEMSIZE,a4
		bsr	_flushcache
	ENDC
		jmp	(a5)

kick_detectchip	move.l	#CHIPMEMSIZE,a3
		jmp	(a5)

	IFD HRTMON
kick_hrtmon	move.l	a4,d0
		bne	.1
		move.l	a3,d0
.1		sub.l	#8,d0			;hrt reads too many from stack -> avoid af
		rts
	ENDC

kick_detectcpu	move.l	(_attnflags,pc),d0
	IFND NEEDFPU
		and.w	#~(AFF_68881|AFF_68882|AFF_FPU40),d0
	ENDC
		rts

exec_ExitIntr	tst.w	(_custom+intreqr)	;delay to make sure int is cleared
		btst	#5,($18+4,a7)		;original code
		rts

	;move.w (a7)+,($dff09c) does not work with Snoop/S on 68060
exec_snoop1	move.w	(a7),($dff09c)
		addq.l	#2,a7
		rts

exec_MakeFunctions
		subq.l	#8,a7
		move.l	(8,a7),(a7)
		move.l	a3,(4,a7)		;original
		lea	(_flushcache,pc),a3
		move.l	a3,(8,a7)
		moveq	#0,d0			;original
		move.l	a2,d1			;original
		rts

exec_SetFunction
		move.l	(a7)+,d1
		pea	(_flushcache,pc)
		move.l	d1,-(a7)
		bset	#1,(14,a1)		;original
		rts

exec_flush	lea	(_custom),a0		;original
		bra	_flushcache

	IFD MEMFREE
exec_AllocMem	movem.l	d0-d1/a0-a1,-(a7)
		move.l	#MEMF_LARGEST|MEMF_CHIP,d1
		jsr	(_LVOAvailMem,a6)
		move.l	(MEMFREE),d1
		beq	.3
		cmp.l	d1,d0
		bhi	.1
.3		move.l	d0,(MEMFREE)
.1		move.l	#MEMF_LARGEST|MEMF_FAST,d1
		jsr	(_LVOAvailMem,a6)
		move.l	(MEMFREE+4),d1
		beq	.4
		cmp.l	d1,d0
		bhi	.2
.4		move.l	d0,(MEMFREE+4)
.2		movem.l	(a7)+,d0-d1/a0-a1
		movem.l	(a7)+,d2-d3/a2
		rts
	ENDC

	IFD SETPATCH

exec_AllocEntry	movem.l	d2/d3/a2-a4,-(sp)
		movea.l	a0,a2
		moveq	#0,d3
		move.w	(14,a2),d3
		move.l	d3,d0
		lsl.l	#3,d0
		addi.l	#$10,d0
		move.l	#$10000,d1
		jsr	(-$C6,a6)
		movea.l	d0,a3
		movea.l	d0,a4
		tst.l	d0
		beq.b	.BD0
		move.w	d3,(14,a3)
		lea	($10,a2),a2
		lea	($10,a3),a3
		moveq	#0,d2
.B78		move.l	(0,a2),d1
		move.l	(4,a2),d0
		move.l	d0,(4,a3)
		beq.b	.B8E
		jsr	(_LVOAllocMem,a6)
		tst.l	d0
		beq.b	.BA4
.B8E		move.l	d0,(0,a3)
		addq.l	#8,a2
		addq.l	#8,a3
		addq.w	#1,d2
		subq.l	#1,d3
		bne.b	.B78
		move.l	a4,d0
.B9E		movem.l	(sp)+,d2/d3/a2-a4
		rts

.BA4		subq.w	#1,d2
		bmi.b	.BB8
		subq.l	#8,a3
		movea.l	(0,a3),a1
		move.l	(4,a3),d0
		jsr	(_LVOFreeMem,a6)
		bra.b	.BA4

.BB8		moveq	#0,d0
		move.w	(14,a4),d0
		lsl.l	#3,d0
		addi.l	#$10,d0
		movea.l	a4,a1
		jsr	(_LVOFreeMem,a6)
		move.l	(0,a2),d0
.BD0		bset	#$1F,d0
		bra.b	.B9E

exec_UserState	move.l	(sp)+,d1
		move.l	sp,usp
		movea.l	d0,sp
		movea.l	a5,a0
		lea	(.B18,pc),a5
		jmp	(_LVOSupervisor,a6)

.B18		movea.l	a0,a5
		move.l	d1,(2,sp)
		andi.w	#$DFFF,(sp)
		rte

exec_FindName	move.l	a2,-(sp)
		movea.l	a0,a2
		move.l	a1,d1
		move.l	(a2),d0
		beq.b	.FDC
.FBE		movea.l	d0,a2
		move.l	(a2),d0
		beq.b	.FDC
		tst.l	(10,a2)
		beq.b	.FBE
		movea.l	(10,a2),a0
		movea.l	d1,a1
.FD0		cmpm.b	(a0)+,(a1)+
		bne.b	.FBE
		tst.b	(-1,a0)
		bne.b	.FD0
		move.l	a2,d0
.FDC		movea.l	d1,a1
		movea.l	(sp)+,a2
		rts

	ENDC

	IFD BOOTEARLY
kick_bootearly	movem.l	d0-a6,-(a7)
		bsr	_bootearly
		movem.l	(a7)+,d0-a6
		lea	($2c,a5),a1		;original
		moveq	#0,d0			;original
		rts
	ENDC

	IFD BOOTBLOCK
kick_bootblock	movem.l	d2-d7/a2-a6,-(a7)
		bsr	_bootblock
		movem.l	(a7)+,d2-d7/a2-a6
		tst.l	d0			;original
		rts
	ENDC

;============================================================================

	;use routine from kick31 instead
gfx_waitblit	tst.b	(_custom+dmaconr)
		btst	#DMAB_BLITTER,(_custom+dmaconr)
		bne	.loop
		rts
.loop		tst.b	(_ciaa)
		tst.b	(_ciaa)
		btst	#DMAB_BLITTER,(_custom+dmaconr)
		bne	.loop
		tst.b	(_custom+dmaconr)
		rts

gfx_vbserver	lea	(_cbswitch_cop2lc,pc),a6
		move.l	d0,(a6)
		lea	($bfd000),a6		;original
		rts

_cbswitch	move.l	(_cbswitch_cop2lc,pc),(_custom+cop2lc)
		move.l	(input_norepeat,pc),d0
		beq	.norepeat
		exg	d0,a0
		st	(a0)				;set repeat key invalid
		move.l	d0,a0
.norepeat	jmp	(a0)

	;move (custom),(cia) does not work with Snoop/S on 68060
gfx_snoop1	move.b	(vhposr,a0),d0
		move.b	d0,(ciatodlow,a6)
		rts

	;gfx.Text uses gfx.BltClear to clear temporary buffer
	;later cpu is used to form output from font data with 'or' to
	;existing bitmap data, this fails with data cache in chip memory
	;-> gfx.BltClear replaced with cpu routine
gfx_text	move.w	(-2,a6),d0
		addq.w	#3,d0
		lsr.w	#2,d0
		subq.w	#1,d0
		bsr	gfx_waitblit		;required for "Batte Chess 2" on UAE
.clr		clr.l	(a1)+
		dbf	d0,.clr
		addq.l	#$80de-$80d0-6,(a7)
		rts

gfx_detectgenlock
		move.l	(_bplcon0,pc),d0
		rts

gfx_detectdisplay
		moveq	#4,d0			;pal
		move.l	(_monitor,pc),d1
		cmp.l	#PAL_MONITOR_ID,d1
		beq	.1
		cmp.l	#DBLPAL_MONITOR_ID,d1
		beq	.1
		moveq	#1,d0			;ntsc
.1		rts

gfx_setcoplc	moveq	#-2,d0
		move.l	d0,(a3)+
		move.l	a3,(cop2lc,a4)		;original
		move.l	a3,(gb_LOFlist,a2)
		move.l	a3,(gb_SHFlist,a2)
		move.l	d0,(a3)+
		clr.w	(color+2,a4)
		add.l	#$ad72-$ad5e-6,(a7)
		rts

gfx_WaitBlit	tst.b	(_custom+dmaconr)
		btst	#DMAB_BLTDONE-8,(_custom+dmaconr)
		beq.b	.1
.2		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		btst	#DMAB_BLTDONE-8,(_custom+dmaconr)
		bne.b	.2
.1		tst.b	(_custom+dmaconr)
		rts

	;somewhere there will used a empty view, too stupid
gfx_fix1	move.l	(v_LOFCprList,a1),d0
		beq	.s1
		move.l	d0,a0
		move.l	(4,a0),(gb_LOFlist,a3)
.s1		move.l	(v_SHFCprList,a1),d0
		beq	.s2
		move.l	d0,a0
		move.l	(4,a0),(gb_SHFlist,a3)
.s2		add.l	#$d5d2-$d5be-6,(a7)
		rts

	IFD SETPATCH

gfx_MrgCop	move.w	($10,a1),d0
		move.w	($9E,a6),d1
		eor.w	d1,d0
		andi.w	#4,d0
		beq.b	.F58
		and.w	($10,a1),d0
		beq.b	.F58
		movem.l	a2/a3,-(sp)
		movea.l	a1,a2
		movea.l	a1,a3
.F2E		move.l	(a3),d0
		beq.b	.F52
		movea.l	d0,a3
		move.w	($20,a3),d0
		move.w	#$2000,d1
		and.w	d0,d1
		beq.b	.F2E
		move.w	#4,d1
		and.w	d0,d1
		beq.b	.F2E
		movea.l	a2,a0
		movea.l	a3,a1
		jsr	(_LVOMakeVPort,a6)
		bra.b	.F2E
.F52		movea.l	a2,a1
		movem.l	(sp)+,a2/a3
.F58
		move.l	a1,-(a7)		;original
		pea	(.ret,pc)
		move.l	(8,a7),-(a7)
		add.l	#-6-$582c+$a5b4,(a7)
		rts

.ret		addq.l	#8,a7
		rts

gfx_SetFont	move.l	a0,d0
		beq.b	.FAC
		move.l	a1,d0
		beq.b	.FAC
		move.w	($14,a0),($3a,a1)	;original
		rts

.FAC		addq.l	#4,a7
		rts

gfx_SetSoftStyle
		move.l	d2,-(sp)
		moveq	#0,d2
		movem.l	d0/d1/a0/a1,-(sp)
		jsr	(_LVOAskSoftStyle,a6)
		move.b	d0,d2
		movem.l	(sp)+,d0/d1/a0/a1
		movea.l	($34,a1),a0
		and.b	d2,d1
		move.b	($38,a1),d2
		and.b	d1,d0
		not.b	d1
		and.b	d1,d2
		or.b	d0,d2
		move.b	d2,($38,a1)
		or.b	($16,a0),d2
		move.l	d2,d0
		move.l	(sp)+,d2
		rts

	ENDC

;============================================================================

disk_getunitid
	IFLT NUMDRIVES
		cmp.l	#1,d0			;at least one drive
		bcs	.set
		cmp.l	(_custom1,pc),d0
	ELSE
		subq.l	#NUMDRIVES,d0
	ENDC
.set		scc	d0
		ext.w	d0
		ext.l	d0
		rts

;============================================================================
; kick13 does not provide fast and fine access to cia timers, therefore we
; use the rasterbeam, required minimum waiting is 75탎, one rasterline is
; 63.5탎, three loops results in min=127탎 max=190.5탎

keyboard_start	moveq	#0,d4
		not.b	d0
		ror.b	#1,d0
		beq	.continue
		cmp.b	(_keyexit,pc),d0
		beq	.exit
		cmp.b	(_keydebug,pc),d0
		beq	.debug
	IFD CBKEYBOARD
		movem.l	d0-a6,-(a7)
		bsr	_cb_keyboard
		movem.l	(a7)+,d0-a6
	ENDC
.continue	lea	(_keyboarddelay,pc),a1
		move.b	(_custom+vhposr),(a1)
		rts

.exit		pea	TDREASON_OK
		bra	.abort

.debug		addq.l	#4,a7			;rts from patchs
		movem.l	(a7)+,d2-d4/a6
		addq.l	#4,a7			;rts from keyboard int
		movem.l	(a7)+,d2/a2
		addq.l	#4,a7			;rts from ports int
		move.l	(a7)+,a2
		move.w	(a7),(_custom+intena)
		addq.l	#6,a7			;rts from int handler
		movem.l	(a7)+,d0-d1/a0-a1/a5-a6
		move.w	(a7),(6,a7)
		move.l	(2,a7),(a7)
		clr.w	(4,a7)
		pea	TDREASON_DEBUG
.abort		move.l	(_resload,pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

keyboard_end	move.b	(_keyboarddelay,pc),d1
		lea	(_custom),a1
.wait1		cmp.b	(vhposr,a1),d1
		beq	.wait1
		move.b	(vhposr,a1),d1
.wait2		cmp.b	(vhposr,a1),d1
		beq	.wait2
		move.b	(vhposr,a1),d1
.wait3		cmp.b	(vhposr,a1),d1
		beq	.wait3
		addq.l	#2,(a7)
		and.b	#~(CIACRAF_SPMODE),(_ciaa+ciacra)
		rts

	IFD SETKEYBOARD
keymap_addmap	movem.l	d2/a3,-(a7)
		lea	(.keymap,pc),a0
		move.l	(_resload,pc),a3
		jsr	(resload_GetFileSize,a3)
		tst.l	d0
		beq	.nokeymap
		moveq	#MEMF_ANY,d1
		jsr	(_LVOAllocMem,a6)
		move.l	d0,d2
		beq	.nokeymap
		lea	(.keymap,pc),a0
		move.l	d2,a1
		jsr	(resload_LoadFile,a3)
		move.l	d2,a0
		sub.l	a1,a1				;tags
		jsr	(resload_Relocate,a3)
		lea	(kr_List,a2),a0			;list
		move.l	d2,a1				;node to add
		jsr	(_LVOAddHead,a6)
.nokeymap	movem.l	(a7)+,d2/a3
		move.l	(a7)+,a2			;original
		rts					;original

.keymap		dc.b	"WHDLoad.keymap",0
	EVEN
	ENDC

;============================================================================

input_task	moveq	#0,d7				;original
		bset	d0,d7				;original
		move.l	d7,d6				;original
		pea	($1212,a5)			;last rawkey for repeat
		lea	(input_norepeat,pc),a0
		move.l	(a7)+,(a0)
		rts

input_norepeat	dc.l	0

;============================================================================

timer_init	move.l	(_time,pc),a0
		move.l	(whdlt_days,a0),d0
		mulu	#24*60,d0
		add.l	(whdlt_mins,a0),d0
		move.l	d0,d1
		lsl.l	#6,d0			;*64
		lsl.l	#2,d1			;*4
		sub.l	d1,d0			;=*60
		move.l	(whdlt_ticks,a0),d1
		divu	#50,d1
		ext.l	d1
		add.l	d1,d0
		move.l	d0,($c6,a2)
		movem.l	(a7)+,d2/a2-a3		;original
		rts

;============================================================================
;  $34 execbase
;  $40.1 0-disk in drive 1-no disk
;  $40.4 0-readwrite 1-readonly
;  $41.7 motor status
;  $43 unit
; $126 disk change count

trd_format
trd_readwrite	movem.l	d2/a1-a2,-(a7)

		moveq	#0,d1
		move.b	($43,a3),d1		;unit number
		clr.b	(IO_ERROR,a1)

		btst	#1,($40,a3)		;disk inserted?
		beq	.diskok

		move.b	#TDERR_DiskChanged,(IO_ERROR,a1)

.end		movem.l	(a7),d2/a1-a2
		bsr	trd_endio
		movem.l	(a7)+,d2/a1-a2
		moveq	#0,d0
		move.b	(IO_ERROR,a1),d0
		rts

.diskok		cmp.b	#CMD_READ,(IO_COMMAND+1,a1)
		bne	.write

.read		moveq	#0,d2
		move.b	(_trd_disk,pc,d1.w),d2	;disk
		move.l	(IO_OFFSET,a1),d0	;offset
		move.l	(IO_LENGTH,a1),d1	;length
		move.l	d1,(IO_ACTUAL,a1)	;actually read (fix for Hacker)
		move.l	(IO_DATA,a1),a0		;destination
		move.l	(_resload,pc),a1
		jsr	(resload_DiskLoad,a1)
		bra	.end

.write		move.b	(_trd_prot,pc),d0
		btst	d1,d0
		bne	.protok
		move.b	#TDERR_WriteProt,(IO_ERROR,a1)
		bra	.end

.protok		lea	(.disk,pc),a0
		move.b	(_trd_disk,pc,d1.w),d0	;disk
		add.b	#"0",d0
		move.b	d0,(5,a0)		;name
		move.l	(IO_LENGTH,a1),d0	;length
		move.l	(IO_OFFSET,a1),d1	;offset
		move.l	(IO_DATA,a1),a1		;destination
		move.l	(_resload,pc),a2
		jsr	(resload_SaveFileOffset,a2)
		bra	.end

.disk		dc.b	"Disk.",0,0,0

_trd_disk	dc.b	1,2,3,4			;number of diskimage in drive
_trd_prot	dc.b	WPDRIVES		;protection status
	IFD DISKSONBOOT
_trd_chg	dc.b	%1111			;diskchanged
	ELSE
_trd_chg	dc.b	0			;diskchanged
	ENDC

trd_motor	moveq	#0,d0
		bchg	#7,($41,a3)		;motor status
		seq	d0
		rts

trd_protstatus	moveq	#0,d0
		move.b	($43,a3),d1		;unit number
		move.b	(_trd_prot,pc),d0
		btst	d1,d0
		seq	d0
		move.l	d0,(IO_ACTUAL,a1)
		add.l	#$708-$6d6-6,(a7)	;skip unnecessary code
		rts

trd_endio	move.l	(_expmem,pc),-(a7)	;jump into rom
		add.l	#$29e30,(a7)
		rts

tdtask_cause	move.l	(_expmem,pc),-(a7)	;jump into rom
		add.l	#$296e8,(a7)
		rts

trd_task	move.b	($43,a3),d1		;unit number
		lea	(_trd_chg,pc),a0
		bclr	d1,(a0)
		beq	.2			;if not changed skip

		bset	#1,($40,a3)		;set no disk inserted
		bne	.3
		addq.l	#1,($126,a3)		;inc change count
		bsr	tdtask_cause
.3
		bclr	#1,($40,a3)		;set disk inserted
		addq.l	#1,($126,a3)		;inc change count
		bsr	tdtask_cause

.2		rts

	IFD TRDCHANGEDISK
	;d0.b = unit
	;d1.b = new disk image number
_trd_changedisk	movem.l	a6,-(a7)

		and.w	#3,d0
		lea	(_trd_chg,pc),a0

		move.l	(4),a6
		jsr	(_LVODisable,a6)

		move.b	d1,(-5,a0,d0.w)
		bset	d0,(a0)

		jsr	(_LVOEnable,a6)

		movem.l	(a7)+,a6
		rts
	ENDC

;============================================================================

dos_init	move.l	#$10001,d1
	IFD SEGTRACKER
		bsr	st_install
	ENDC
		bra	_flushcache

dos_endcli	tst.l	D2			;is -1 with EndCLI
		bmi	.1
		move.b	(a0,d2.l),d3		;original
.1		move.l	d3,d1			;original
		rts

dos_1		move.l	#$118,d1		;original
		bra	_flushcache

dos_LoadSeg	clr.l	(12,a1)			;original
		moveq	#12,d4			;original
		lea	(.savea4,pc),a6
		move.l	a4,(a6)
		lea	(.bcplend,pc),a6
		rts

.savea4		dc.l	0

.bcplend	cmp.l	(.savea4,pc),a4		;are we in dos_51?
		beq	.end51
		jmp	($34128-$34134,a5)	;call original

.end51		lea	($34128-$34134,a5),a6	;restore original
	IFD CBDOSLOADSEG
		movem.l	d0-a6,-(a7)
		move.l	(a1),d0			;d0 = BSTR FileName
		tst.l	d1			;d1 = BPTR SegList
		beq	.failed
		bsr	_cb_dosLoadSeg
.failed		movem.l	(a7)+,d0-a6
	ENDC
	IFD SEGTRACKER
		movem.l	d0-d1/a0-a1,-(a7)
		move.l	(a1),a0			;a0 = BSTR FileName
		add.l	a0,a0
		add.l	a0,a0
		moveq	#0,d0
		move.b	(a0)+,d0		;length
		clr.b	(a0,d0.w)		;terminate, hopefully doesn't overwrite anything
		move.l	d1,d0			;d0 = BPTR SegList
		beq	.failed2
		bsr	st_track
.failed2	movem.l	(a7)+,d0-d1/a0-a1
	ENDC
		bsr	_flushcache
		jmp	(a6)

	IFD SEGTRACKER
dos_UnLoadSeg	bsr	st_untrack
		addq.l	#2,(a7)
		cmp.l	#$abcd,(8,a0,d2.l)	;original
		rts
	ENDC

	IFD WHDCTRL
	;add WHDCtrl to the list of resident commands
dos_whdctrl	move.l	(39*4,a2),a4		;G_ROOTSTRUCT
		moveq	#$3c,d0			;used BCPL stack
		jsr	(a5)
		lsl.l	#2,d1			;RootNode
		move.l	(rn_Info,a0,d1.l),a4
		add.l	a4,a4
		add.l	a4,a4			;A4 = DosInfo

		lea	(.segment,pc),a3
		pea	(.seglist,pc)
		move.l	(a7)+,d1
		lsr.l	#2,d1
		move.l	d1,(seg_Seg,a3)

		move.l	(di_NetHand,a4),(seg_Next,a3)
		move.l	a3,d1
		lsr.l	#2,d1
		move.l	d1,(di_NetHand,a4)

		moveq	#$3c,d0			;original
		move.l	($104,a2),a4		;original
		rts

	CNOP 0,4
.segment	dc.l	0			;seg_Next
		dc.l	2			;seg_UC = 1 to forbid unload
		dc.l	0			;seg_Seg
		dc.b	7,"WHDCtrl"		;seg_Name
	CNOP 0,4
.template	dc.b	6,"Quit/S"
	CNOP 0,4
.badargs	dc.b	9,"Bad args",10
	CNOP 0,4
.seglist	dc.l	0			;next segment
		sub.l	a0,a0			;BCPL standard value
WHDCTRLBUFLEN = 3				;buffer for G_RDARGS in LONGs
		sub	#WHDCTRLBUFLEN*4,a7
		lea	(.template,pc),a3
		move.l	a3,d1
		lsr.l	#2,d1			;D1 = template
		move.l	a7,d2
		lsr.l	#2,d2			;D2 = arg array + buffer
		moveq	#WHDCTRLBUFLEN-1,d3	;D3 = size of arg array + buffer (LONGs)
		move.l	(78*4,a2),a4		;G_RDARGS
		moveq	#12,d0			;used BCPL stack (a1)
		jsr	(a5)			;call BCPL
		tst.l	d1			;result from G_RDARGS
		beq	.fail
		tst.l	(a7)			;Quit?
		beq	.end
		move.l	(_resload,pc),a0
		pea	TDREASON_OK
		jmp	(resload_Abort,a0)
	;G_RDARGS has failed
.fail		lea	(.badargs,pc),a3
		move.l	a3,d1
		lsr.l	#2,d1
		move.l	(73*4,a2),a4		;G_WRITES
		moveq	#12,d0			;used BCPL stack (a1)
		jsr	(a5)			;call BCPL
		moveq	#10,d0			;RETURN_ERROR
.end		add	#WHDCTRLBUFLEN*4,a7
		rts

	; enable using resident instead loadseg
dos_residentload
		move.l	#$1c4,d0		;used stack
		movea.l	($9C,a2),a4		;G_ROOTSTRUCT
		jsr	(a5)
		lsl.l	#2,d1
		move.l	(rn_Info,a0,d1.l),d2
		lsl.l	#2,d2
		move.l	(di_NetHand,a0,d2.l),($1c4-12,a1)	;BPTR to first seg
		beq	.notfound
.search		moveq	#3,d1			;seg_Name is + 3 LONGs
		add.l	($1c4-12,a1),d1
		move.l	d1,d2			;adr name from seg
		move.l	($48,a1),d1		;48 = buffer cmdname
		move.l	#$1c4+4,d0		;used stack
		movea.l	($134,a2),a4		;G_COMPSTRING
		jsr	(a5)
		tst.l	d1
		beq	.found
		move.l	($1c4-12,a1),d1
		lsl.l	#2,d1
		move.l	(a0,d1.l),($1c4-12,a1)	;seg_Next
		bne.b	.search
.notfound	sf	($4c+99,a1)		;last byte of cmdname buffer
		moveq	#0,d1			;original
		move.l	#$1c4,d0		;original
		rts

.found		move.l	($1c4-12,a1),d1
		lsl.l	#2,d1
		tst.l	(seg_UC,a0,d1.l)
		ble.w	.notfound		;SYSTEM
		move.l	(seg_Seg,a0,d1.l),($1a8,a1)	;1a8 = segment
		st	($4c+99,a1)		;last byte of cmdname buffer
		add.l	#$39368-$39232-6,(a7)
		rts

	; disable unloading segment which is resident
dos_residentunload
		tst.b	($4c+99,a1)		;last byte of cmdname buffer
		bne	.resident
		move.l	#$1c4,d0		;original
		rts

.resident	addq.l	#$394e8-$394dc-6,(a7)
		rts
	ENDC

	IFD BOOTDOS
dos_bootdos
	;init boot exe
		lea	(_bootdos,pc),a3
		move.l	a3,(bootfile_exe_j+2-_bootdos,a3)
	;fake startup-sequence
		lea	(bootname_ss_b,pc),a3	;bstr
		move.l	a3,d1
	;return
		rts
	ENDC

;---------------
; performs a C:Assign
; IN:	A0 = CPTR destination name
;	A1 = CPTR directory (could be 0 meaning SYS:)
; OUT:	-

	IFD DOSASSIGN
_dos_assign	movem.l	d2/a3-a6,-(a7)
		move.l	a0,a3			;A3 = name
		move.l	a1,a4			;A4 = directory
		move.l	(4),a6

	;backward compatibilty (given BSTR instead CPTR)
		cmp.b	#" ",(a0)
		bls	.skipname

	;get length of name
		moveq	#-1,d2
.len		addq.l	#1,d2
		tst.b	(a0)+
		bne	.len

	;get memory for name
		move.l	d2,d0
		addq.l	#2,d0			;+ length and terminator
		move.l	#MEMF_ANY,d1
		jsr	(_LVOAllocMem,a6)
	IFD DEBUG
		tst.l	d0
		beq	_debug3
	ENDC
		move.l	d0,a0
		move.b	d2,(a0)+
.cpy		move.b	(a3)+,(a0)+
		bne	.cpy
		move.l	d0,a3
.skipname
	;get memory for node
		move.l	#DosList_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		jsr	(_LVOAllocMem,a6)
	IFD DEBUG
		tst.l	d0
		beq	_debug3
	ENDC
		move.l	d0,a5			;A5 = DosList

	;open doslib
		lea	(_dosname,pc),a1
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6

	;lock directory
		move.l	a4,d1
		move.l	#ACCESS_READ,d2
		jsr	(_LVOLock,a6)
		move.l	d0,d1
	IFD DEBUG
		beq	_debug3
	ENDC
		lsl.l	#2,d1
		move.l	d1,a0
		move.l	(fl_Task,a0),(dol_Task,a5)
		move.l	d0,(dol_Lock,a5)

	;init structure
		move.l	#DLT_DIRECTORY,(dol_Type,a5)
		move.l	a3,d0
		lsr.l	#2,d0
		move.l	d0,(dol_Name,a5)

	;add to the system
		move.l	(dl_Root,a6),a6
		move.l	(rn_Info,a6),a6
		add.l	a6,a6
		add.l	a6,a6
		move.l	(di_DevInfo,a6),(dol_Next,a5)
		move.l	a5,d0
		lsr.l	#2,d0
		move.l	d0,(di_DevInfo,a6)

		movem.l	(a7)+,d2/a3-a6
		rts
	ENDC

;============================================================================

	IFD HDINIT

hd_init		lea	-1,a2				;original A2 = -1

	INCLUDE	whdload/kickfs.s
	ENDC

;============================================================================

	IFD SEGTRACKER
	INCLUDE whdload/segtracker.s
	ENDC

;============================================================================

_flushcache	move.l	(_resload,pc),-(a7)
		add.l	#resload_FlushCache,(a7)
		rts

;============================================================================

	IFD DEBUG
_debug1		tst	-1	;unknown packet (=d4) for dos handler
_debug2		tst	-2	;no lock given for a_copy_dir (dos.DupLock)
_debug3		tst	-3	;error in _dos_assign
_debug4		tst	-4	;invalid lock specified
_debug5		tst	-5	;unable to alloc mem for iocache
		illegal		;security if executed without mmu
	ENDC

;============================================================================

slv_kickname	dc.b	"34005.a500",0
_keyboarddelay	dc.b	0
	EVEN
_tags		dc.l	WHDLTAG_CBSWITCH_SET
_cbswitch_tag	dc.l	0
		dc.l	WHDLTAG_ATTNFLAGS_GET
_attnflags	dc.l	0
		dc.l	WHDLTAG_MONITOR_GET
_monitor	dc.l	0
		dc.l	WHDLTAG_BPLCON0_GET
_bplcon0	dc.l	0
		dc.l	WHDLTAG_TIME_GET
_time		dc.l	0
	IFLT NUMDRIVES
		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
	ENDC
		dc.l	0
_resload	dc.l	0
_cbswitch_cop2lc	dc.l	0

;============================================================================

