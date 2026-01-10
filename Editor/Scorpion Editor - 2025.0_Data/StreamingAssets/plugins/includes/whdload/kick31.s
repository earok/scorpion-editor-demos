;*---------------------------------------------------------------------------
;  :Modul.	kick31.s
;  :Contents.	interface code and patches for kickstart 3.1 from A1200
;  :Author.	Wepl, JOTD, Psygore
;  :Version.	$Id: kick31.s 1.52 2024/06/11 00:49:19 wepl Exp wepl $
;  :History.	04.03.03 rework/cleanup
;		04.04.03 disk.ressource cleanup
;		06.04.03 some dosboot changes
;			 cache option added
;		15.05.03 patch for exec.ExitIntr to avoid double ints
;		22.06.03 adapted for whdload v16
;		13.11.03 merged support for A4000 image into
;		02.05.04 lowlevel loading/joypad emulation integrated
;		16.10.04 support for NUMDRIVES=0 added
;		26.01.05 trackdisk device IO_ACTUAL field set
;		11.02.05 PROMOTE_DISPLAY added
;		23.08.05 JOYPADEMU added, user defineable keys added
;		14.12.05 blue button no longer masked out from lowlevel
;			 result in joypad emulation
;		02.05.06 made compatible to ASM-One
;			 option NO68020 added to create 68000 compatible slaves
;		07.05.06 patches added to avoid overwriting the vector table (68000 support)
;		03.01.07 support for 40063.A600 started
;		16.01.07 support for 40063.A600 finished
;		21.01.07 _keyboard patch added to allow quit/debugkey on 68000
;		24.04.07 make exec.ColdReboot working by leaving the kick set the initial sp
;		07.11.07 _debug5 added
;		04.12.07 patch for exec.ExitIntr improved
;		26.10.08 detect dependency between HDINIT and BOOTDOS
;		09.06.09 option Force/S to joypad emulation added
;		22.07.11 adapted for whdload v17
;		14.02.16 with option CACHE chip-memory is now WT instead NC
;		02.01.17 host system gb_bplcon0 is now honored (genlock/lace)
;		29.03.17 NEEDFPU enables FPU with SetCPU now
;		25.07.17 fixed 68000 compatibility in dos_LoadSeg
;		07.10.17 reverted change from 14.02.16: option CACHE sets chip memory NC
;			 without a CACHE* option caches are switched off now!
;			 new option CACHECHIP enables only IC and sets chip memory WT
;			 new option CACHECHIPDATA enables IC/DC and sets chip memory WT
;		20.03.18 renamed _tags to _kick31_tags to avoid collisions
;		28.12.18 segtracker added
;		11.01.19 key repeat after osswitch disabled in input.device
;		13.01.19 _cb_keyboard added
;		17.08.19 INIT_NONVOLATILE added
;		26.04.20 prefer A600 kickstart if NO68020 is defined
;			 fail if A1200/4000 kickstart is present and cpu<68020 (JOTD/Wepl)
;		12.05.20 set WHDLF_Examine if HDINIT is set
;		29.10.20 INIT_LOWLEVEL/JOYPADEMU changed for constructed lowlevel.s
;		03.11.20 tagged library/device defines added
;		20.12.20 fixed key repeat in input.device (wrong variable offset)
;		21.12.20 added keymap loading
;		30.12.20 use MEMF_REVERSE for keymap loading
;		02.01.21 includes changed from Sources:whdload/... to whdload/...
;		13.11.21 INIT_RESOURCE added
;		14.11.21 WHDCTRL added
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
	INCLUDE	exec/resident.i
	INCLUDE	graphics/gfxbase.i

_LVOTaggedOpenLibrary = -810
OLTAG_GRAPHICS	=	1
OLTAG_LAYERS	=	2
OLTAG_INTUITION	=	3
OLTAG_DOS	=	4
OLTAG_ICON	=	5
OLTAG_EXPANSION	=	6
OLTAG_UTILITY	=	7
OLTAG_KEYMAP	=	8
OLTAG_GADTOOLS	=	9
OLTAG_WORKBENCH	=	10
ODTAG_TIMER	=	0
ODTAG_INPUT	=	1

KICKVERSION	= 40
KICKCRC600	= $970c				;40.063 A600
KICKCRC1200	= $9ff5				;40.068 A1200
KICKCRC4000	= $75D3				;40.068 A4000
KICKCRC		= KICKCRC1200			;compatibility for old slaves

	IFND NO68020
	MC68020
	ENDC

;============================================================================

	IFD	slv_Version
	IFLT	slv_Version-16
	FAIL	slv_Version must be 16 or higher
	ENDC

slv_FlagsAdd SET WHDLF_EmulPriv
	IFND NO68020
slv_FlagsAdd SET slv_FlagsAdd|WHDLF_Req68020
	ENDC
	IFD HDINIT
slv_FlagsAdd SET slv_FlagsAdd|WHDLF_Examine
	ENDC

KICKSIZE	= $80000
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

slv_base	SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	slv_Version		;ws_Version
		dc.w	slv_Flags|slv_FlagsAdd	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
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
_kickcrc	dc.w	-1			;ws_kickcrc
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
		lea	(_kick31_tags,pc),a0
		jsr	(resload_Control,a5)
	
	IFND slv_Version
	;load kickstart
		move.l	#KICKSIZE,d0			;length
		move.w	#KICKCRC,d1			;crc16
		lea	(slv_kickname,pc),a0		;name
		jsr	(resload_LoadKick,a5)
	ENDC

	;patch the kickstart
		lea	(kick_patch1200,pc),a0
	IFD slv_Version
		move.w	(_kickcrc,pc),d0
		cmp.w	#KICKCRC1200,d0
		beq	.patch
		lea	(kick_patch4000,pc),a0
		cmp.w	#KICKCRC4000,d0
		beq	.patch
		lea	(kick_patch600,pc),a0
.patch
	ENDC
		move.l	(_expmem,pc),a1
		jsr	(resload_Patch,a5)

	;call
kick_reboot
	IFND NO68020
		jmp	([_expmem,pc],2.w)		;original entry
	ELSE
	IFD slv_Version
		move.w	(_kickcrc,pc),d0
		cmp.w	#KICKCRC600,d0
		beq	.kickok
		moveq	#AFF_68020,d0
		and.l	(_attnflags,pc),d0
		bne	.kickok
		pea	(_badkickstart,pc)
		pea	TDREASON_FAILMSG
		jmp	(resload_Abort,a5)
.kickok
	ENDC
		move.l	(_expmem,pc),-(a7)
		addq.l	#2,(a7)
		rts
	ENDC

	IFD slv_Version

kick_patch600	PL_START
		PL_S	$d6,$166-$d6			;kick chksum, hardware init
		PL_PS	$166,kick_leaveled
		PL_S	$1a6,$1d0-$1a6			;kick chksum, avoid overwriting vector table
		PL_PS	$240,kick_detectchip
		PL_S	$246,$26a-$246			;kick_detectchip
		PL_S	$334,6				;kick_detectfast
		PL_L	$376,-1				;disable search for residents at $f00000
		PL_P	$38e,kick_detectfast
	;	PL_S	$422,6				;LED, reboot unexpected int
	;	PL_S	$430,6				;LED, reboot unexpected int
		PL_R	$460				;check Fat Gary, RAMSEY, Gayle $de1000
	IFEQ FASTMEMSIZE
	IFD HRTMON
		PL_PS	$5aa,kick_hrtmon
	ENDC
	ENDC
		PL_S	$5e8,$5fe-$5e8			;avoid overwriting vector table
		PL_PS	$634,kick_setvecs
		PL_S	$66a,12				;avoid overwriting vector table
		PL_C	$a4c,$a58-$a4c			;avoid overwriting vector table
		PL_C	$a5a,$a7a-$a5a			;avoid overwriting vector table
		PL_P	$c1c,kick_detectcpu
		PL_P	$d36,_flushcache		;exec.CacheControl
		PL_P	$db8,kick_reboot		;exec.ColdReboot
		PL_PS	$1380,exec_ExitIntr
		PL_PS	$1c6c,_flushcache		;exec.MakeFunctions using exec.CacheClearU without
							;proper init for cpu's providing CopyBack
	IFD MEMFREE
		PL_P	$1e86,exec_AllocMem
	ENDC
	;	PL_L	$329a,$70004e71			;SAD, movec vbr,d0 -> moveq #0,d0
		PL_S	$3cefc,$3cf9e-$3cefc		;autoconfiguration at $e80000
	IFD HDINIT
		PL_PS	$41ac4,hd_init
	ENDC
	IFGT NUMDRIVES-4
		PL_B	$41b6f,7			;allow 7 floppy drives
	ENDC
	IFD BOOTEARLY
		PL_PS	$41f68,kick_bootearly
	ENDC
	IFD BOOTBLOCK
		PL_PS	$42066,kick_bootblock		;a1=ioreq a4=buffer a6=execbase
	ENDC
		PL_PS	$bd70,gfx_readvpos		;patched to set NTSC/PAL
		PL_S	$bd8c,$bd9c-$bd8c		;snoop, byte writes to bpl1dat-bpl6dat, strange?
		PL_S	$c028,6				;blit wait, graphics init
		PL_S	$c044,6				;blit wait, graphics init
	IFD INITAGA
		PL_PS	$c2e4,gfx_initaga
	ENDC
		PL_PS	$c35e,gfx_bplcon0
		PL_P	$c46a,gfx_detectgenlock
		PL_PS	$ffc4,gfx_beamcon01
		PL_PS	$1001a,gfx_vbstrt1
		PL_PS	$10034,gfx_vbstrt2
		PL_PS	$10082,gfx_vbstrt2
		PL_PS	$100aa,gfx_beamcon02
		PL_PS	$100cc,gfx_snoop1
		PL_PS	$1543a,gfx_readvpos		;patched to set NTSC/PAL
	IFD STACKSIZE
		PL_L	$2305c,STACKSIZE/4
	ENDC
	IFD SEGTRACKER
		PL_PS	$230cc,segtracker_init
	ENDC
	IFD BOOTDOS
		PL_PS	$23100,dos_bootdos
	ENDC
	IFD CBDOSLOADSEG
		PL_PS	$27b9c,dos_LoadSeg
	ENDC
		PL_CB	$35936				;don't init scsi.device
		PL_PS	$4ed2,_keyboard
		PL_PS	$5a78,input_task
	IFD INIT_AUDIO					;audio.device
		PL_B	$37c2,RTF_COLDSTART|RTF_AUTOINIT
	ENDC
		PL_CB	$3e332				;don't init battclock.ressource
		PL_S	$4013c,$4015e-$4013c		;skip disk unit detect
		PL_P	$4028e,disk_getunitid
		PL_P	$40296,disk_getunitid
	IFD INIT_MATHFFP				;mathffp.library
		PL_B	$4094e,RTF_COLDSTART|RTF_AUTOINIT
	ENDC
		PL_P	$3c246,timer_init
	;	PL_NOP	$3b880,2			;skip rom menu
	IFD SETKEYBOARD
		PL_P	$40f04,keymap_addmap
	ENDC
		PL_P	$446aa,trd_task
		PL_P	$44ea8,trd_format
		PL_P	$452ec,trd_motor
		PL_P	$455dc,trd_readwrite
		PL_PS	$459aa,trd_protstatus
		PL_PS	$45e80,trd_init
	IFD FONTHEIGHT
		PL_B	$68900,FONTHEIGHT
	ENDC
	IFD BLACKSCREEN
		PL_C	$68966,6			;color17,18,19
		PL_C	$6896E,8			;color0,1,2,3
	ENDC
	IFD POINTERTICKS
		PL_W	$6896C,POINTERTICKS
	ENDC
	IFD INIT_GADTOOLS				;gadtools.library
		PL_B	$68a6e,RTF_COLDSTART|RTF_AUTOINIT
	ENDC
		PL_END

	ENDC

kick_patch1200	PL_START
		PL_S	$d6,$166-$d6			;kick chksum, hardware init
		PL_PS	$166,kick_leaveled
		PL_S	$1a6,$1d0-$1a6			;kick chksum, avoid overwriting vector table
		PL_PS	$240,kick_detectchip
		PL_S	$246,$26a-$246			;kick_detectchip
		PL_S	$334,6				;kick_detectfast
		PL_L	$376,-1				;disable search for residents at $f00000
		PL_P	$38e,kick_detectfast
	;	PL_S	$422,6				;LED, reboot unexpected int
	;	PL_S	$430,6				;LED, reboot unexpected int
		PL_R	$460				;check Fat Gary, RAMSEY, Gayle $de1000
	IFEQ FASTMEMSIZE
	IFD HRTMON
		PL_PS	$5aa,kick_hrtmon
	ENDC
	ENDC
		PL_S	$5e8,$5fe-$5e8			;avoid overwriting vector table
		PL_PS	$634,kick_setvecs
		PL_S	$66a,12				;avoid overwriting vector table
		PL_C	$a4c,$a58-$a4c			;avoid overwriting vector table
		PL_C	$a5a,$a7a-$a5a			;avoid overwriting vector table
		PL_P	$c1c,kick_detectcpu
		PL_P	$d36,_flushcache		;exec.CacheControl
		PL_P	$db8,kick_reboot		;exec.ColdReboot
		PL_PS	$1380,exec_ExitIntr
		PL_PS	$1c6c,_flushcache		;exec.MakeFunctions using exec.CacheClearU without
							;proper init for cpu's providing CopyBack
	IFD MEMFREE
		PL_P	$1e86,exec_AllocMem
	ENDC
	;	PL_L	$329a,$70004e71			;SAD, movec vbr,d0 -> moveq #0,d0
		PL_S	$38f8,$3a00-$38f8		;autoconfiguration at $e80000
	IFD HDINIT
		PL_PS	$42f4,hd_init
	ENDC
	IFGT NUMDRIVES-4
		PL_B	$439f,7				;allow 7 floppy drives
	ENDC
	IFD BOOTEARLY
		PL_PS	$4798,kick_bootearly
	ENDC
	IFD BOOTBLOCK
		PL_PS	$4896,kick_bootblock		;a1=ioreq a4=buffer a6=execbase
	ENDC
		PL_PS	$b484,gfx_readvpos		;patched to set NTSC/PAL
		PL_S	$b4a0,$b4b0-$b4a0		;snoop, byte writes to bpl1dat-bpl6dat, strange?
		PL_S	$b73c,6				;blit wait, graphics init
		PL_S	$b758,6				;blit wait, graphics init
	IFD INITAGA
		PL_PS	$b9f8,gfx_initaga
	ENDC
		PL_PS	$ba72,gfx_bplcon0
		PL_P	$bb7e,gfx_detectgenlock
		PL_PS	$f6d8,gfx_beamcon01
		PL_PS	$f72e,gfx_vbstrt1
		PL_PS	$f748,gfx_vbstrt2
		PL_PS	$f796,gfx_vbstrt2
		PL_PS	$f7be,gfx_beamcon02
		PL_PS	$f7e0,gfx_snoop1
		PL_PS	$14b4e,gfx_readvpos		;patched to set NTSC/PAL
	IFD STACKSIZE
		PL_L	$22772,STACKSIZE/4
	ENDC
	IFD SEGTRACKER
		PL_PS	$227e0,segtracker_init
	ENDC
	IFD WHDCTRL
		PL_PS	$2280c,dos_whdctrl
	ENDC
	IFD BOOTDOS
		PL_PS	$22814,dos_bootdos
	ENDC
	IFD CBDOSLOADSEG
		PL_PS	$272b0,dos_LoadSeg
	ENDC
		PL_CB	$3504a				;don't init scsi.device
		PL_PS	$3a7ea,_keyboard
		PL_PS	$3b390,input_task
	IFD INIT_AUDIO					;audio.device
		PL_B	$3b7ae,RTF_COLDSTART|RTF_AUTOINIT
	ENDC
		PL_CB	$3ddf2				;don't init battclock.ressource
		PL_S	$40414,$40436-$40414		;skip disk unit detect
		PL_P	$40566,disk_getunitid
		PL_P	$4056e,disk_getunitid
	IFD INIT_MATHFFP				;mathffp.library
		PL_B	$40632,RTF_COLDSTART|RTF_AUTOINIT
	ENDC
		PL_P	$40D3A,timer_init
	IFD SETKEYBOARD
		PL_P	$42878,keymap_addmap
	ENDC
	;	PL_NOP	$44294,2			;skip rom menu
		PL_P	$44A5A,trd_task
		PL_P	$45258,trd_format
		PL_P	$4569C,trd_motor
		PL_P	$4598C,trd_readwrite
		PL_PS	$45D5A,trd_protstatus
		PL_PS	$46230,trd_init
	IFD FONTHEIGHT
		PL_B	$68CB0,FONTHEIGHT
	ENDC
	IFD BLACKSCREEN
		PL_C	$68D16,6			;color17,18,19
		PL_C	$68D1E,8			;color0,1,2,3
	ENDC
	IFD POINTERTICKS
		PL_W	$68D1C,POINTERTICKS
	ENDC
	IFD INIT_GADTOOLS				;gadtools.library
		PL_B	$68e1e,RTF_COLDSTART|RTF_AUTOINIT
	ENDC
		PL_END

	IFD slv_Version

kick_patch4000	PL_START
		PL_S	$d6,$10A-$d6			;kick chksum, hardware init
		PL_PS	$10A,kick_leaveled
		PL_S	$146,$16C-$146			;A4000 DTack/bus stuff
		PL_S	$174,$17C-$174			;A4000 DTack/bus stuff
		PL_S	$180,$1aa-$180			;kick chksum, avoid overwriting vector table
		PL_PS	$21A,kick_detectchip
		PL_S	$220,$244-$220			;kick_detectchip
		PL_S	$30E,6				;kick_detectfast
		PL_L	$350,-1				;disable search for residents at $f00000
		PL_P	$368,kick_detectfast
	;	PL_S	$422,6				;LED, reboot unexpected int
	;	PL_S	$430,6				;LED, reboot unexpected int
		PL_R	$43A				;check Fat Gary, RAMSEY, Gayle $de1000
	IFEQ FASTMEMSIZE
	IFD HRTMON
		PL_PS	$582,kick_hrtmon
	ENDC
	ENDC
		PL_S	$5c0,$5d6-$5c0			;avoid overwriting vector table
		PL_PS	$60c,kick_setvecs
		PL_S	$642,$656-$642			;avoid overwriting vector table
		PL_C	$a54,$a60-$a54			;avoid overwriting vector table
		PL_C	$a62,$a82-$a62			;avoid overwriting vector table
		PL_P	$c24,kick_detectcpu
		PL_P	$d3e,_flushcache		;exec.CacheControl
		PL_P	$dc0,kick_reboot		;exec.ColdReboot
		PL_PS	$1388,exec_ExitIntr
		PL_PS	$1c74,_flushcache		;exec.MakeFunctions using exec.CacheClearU without
							;proper init for cpu's providing CopyBack
	IFD MEMFREE
		PL_P	$1e8e,exec_AllocMem
	ENDC
	;	PL_L	$329a,$70004e71			;SAD, movec vbr,d0 -> moveq #0,d0
		PL_S	$49F44,$4a068-$49f44		;autoconfiguration at $e80000
	IFD HDINIT
		PL_PS	$4006C,hd_init
	ENDC
	IFGT NUMDRIVES-4
		PL_B	$40117,7			;allow 7 floppy drives
	ENDC
	IFD BOOTEARLY
		PL_PS	$40510,kick_bootearly
	ENDC
	IFD BOOTBLOCK
		PL_PS	$4060E,kick_bootblock		;a1=ioreq a4=buffer a6=execbase
	ENDC
		PL_PS	$2A9DC,gfx_readvpos		;patched to set NTSC/PAL
		PL_S	$2A9F8,$10			;snoop, byte writes to bpl1dat-bpl6dat, strange?
		PL_S	$2AC94,6			;blit wait, graphics init
		PL_S	$2ACB0,6			;blit wait, graphics init
	IFD INITAGA
		PL_PS	$2AF50,gfx_initaga
	ENDC
		PL_PS	$2afca,gfx_bplcon0
		PL_P	$2B0D6,gfx_detectgenlock
		PL_PS	$2EC30,gfx_beamcon01
		PL_PS	$2EC86,gfx_vbstrt1
		PL_PS	$2ECA0,gfx_vbstrt2
		PL_PS	$2ECEE,gfx_vbstrt2
		PL_PS	$2ED16,gfx_beamcon02
		PL_PS	$2ED38,gfx_snoop1
		PL_PS	$340A6,gfx_readvpos		;patched to set NTSC/PAL
	IFD STACKSIZE
		PL_L	$18B9A,STACKSIZE/4
	ENDC
	IFD SEGTRACKER
		PL_PS	$18c08,segtracker_init
	ENDC
	IFD BOOTDOS
		PL_PS	$18C3C,dos_bootdos
	ENDC
	IFD CBDOSLOADSEG
		PL_PS	$1D6D8,dos_LoadSeg
	ENDC
		PL_CB	$7E3E				;don't init scsi.device
		PL_PS	$d3ee,_keyboard
		PL_PS	$df94,input_task
	IFD INIT_AUDIO					;audio.device
		PL_B	$6D6C,RTF_COLDSTART|RTF_AUTOINIT
	ENDC
		PL_CB	$44FC6				;don't init battclock.ressource
		PL_S	$41A10,$41A32-$41A10		;skip disk unit detect
		PL_P	$41B62,disk_getunitid
		PL_P	$41B6A,disk_getunitid
	IFD INIT_MATHFFP				;mathffp.library
		PL_B	$42102,RTF_COLDSTART|RTF_AUTOINIT
	ENDC
		PL_P	$C01A,timer_init
	;	PL_NOP	$44294,2			;skip rom menu
		PL_P	$4B84E,trd_task
		PL_P	$4C04C,trd_format
		PL_P	$4C490,trd_motor
		PL_P	$4C780,trd_readwrite
		PL_PS	$4CB4E,trd_protstatus
		PL_PS	$4D024,trd_init
	IFD SETKEYBOARD
		PL_P	$4d604,keymap_addmap
	ENDC
	IFD FONTHEIGHT
		PL_B	$6799C,FONTHEIGHT
	ENDC
	IFD BLACKSCREEN
		PL_C	$67A02,6			;color17,18,19
		PL_C	$67A0A,8			;color0,1,2,3
	ENDC
	IFD POINTERTICKS
		PL_W	$67A08,POINTERTICKS
	ENDC
	IFD INIT_GADTOOLS				;gadtools.library
		PL_B	$67B0A,RTF_COLDSTART|RTF_AUTOINIT
	ENDC
		PL_S	$4A024,$4A02C-$4A024	; write to $de0000
		PL_L	$1E67A,$70004E75	; installs some strange A4000 "bonus"
		PL_END

	ENDC

;============================================================================

kick_setvecs	move.w	(a1)+,d0
		beq	.skip
		lea	(a0,d0.w),a3
		move.l	a3,(a2)
.skip		addq.l	#4,a2
		cmp.w	#$7c,a2			;stop at NMI
		bne	kick_setvecs
		add.l	#$3e2-$3d6-6,(a7)
		rts

kick_leaveled	and.b	#~CIAB_LED,$BFE001
		rts

kick_detectchip	move.l	#CHIPMEMSIZE,a3
		rts

kick_detectfast
	IFEQ FASTMEMSIZE
		sub.l	a4,a4
	ELSE
		move.l	(_expmem,pc),a0
		add.l	#KICKSIZE,a0
		move.l	a0,a4
		add.l	#FASTMEMSIZE,a4
	ENDC
		rts

	IFEQ FASTMEMSIZE
	IFD HRTMON
kick_hrtmon	add.l	d2,d0
		subq.l	#8,d0			;hrt reads too many from stack -> avoid af
		move.l	d0,(SysStkUpper,a6)
		rts
	ENDC
	ENDC

kick_detectcpu	move.l	(_attnflags,pc),d0
	IFND NEEDFPU
		and.w	#~(AFF_68881|AFF_68882|AFF_FPU40),d0
	ENDC
		rts

exec_ExitIntr	tst.w	(_custom+intreqr)	;delay to make sure int is cleared
		btst	#5,($18+4,a7)		;original code
		rts

	IFD MEMFREE
exec_AllocMem	move.l	d0,-(a7)
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
.2		move.l	(a7)+,d0
		addq.l	#4,a7
		rts
	ENDC

	IFD BOOTEARLY
kick_bootearly	movem.l	d0-a6,-(a7)
		bsr	_bootearly
		movem.l	(a7)+,d0-a6
		moveq	#0,d2			;original
		lea	($1c,a2),a3		;original
		rts
	ENDC

	IFD BOOTBLOCK
kick_bootblock	move.l	(a7)+,d1		;original
		addq.l	#2,d1
		movem.l	d1-d7/a2-a6,-(a7)	;original
		bra	_bootblock
	ENDC

;============================================================================

gfx_bplcon0	move.w	#$200,(_custom+bplcon0)
		rts

gfx_beamcon01	bclr	#4,(gb_Bugs,a1)			;original
		move.l	a0,d2
		lea	(_cbswitch_beamcon0,pc),a0
		move.w	d4,(a0)
		st	(_cbflag_beamcon0-_cbswitch_beamcon0,a0)
		move.l	d2,a0
		rts

gfx_vbstrt1	move.l	d2,(vbstrt,a0)			;original
		move.l	(gb_SHFlist,a1),(cop2lc,a0)	;original
		move.l	a0,d0
		lea	(_cbswitch_vbstrt,pc),a0
		move.w	d2,(a0)
		st	(_cbflag_vbstrt-_cbswitch_vbstrt,a0)
		move.l	(gb_SHFlist,a1),(_cbswitch_cop2lc-_cbswitch_vbstrt,a0)
		move.l	d0,a0
		addq.l	#4,(a7)
		rts

gfx_vbstrt2	move.l	d2,(vbstrt,a0)			;original
		move.l	(gb_LOFlist,a1),(cop2lc,a0)	;original
		move.l	a0,d0
		lea	(_cbswitch_vbstrt,pc),a0
		move.w	d2,(a0)
		st	(_cbflag_vbstrt-_cbswitch_vbstrt,a0)
		move.l	(gb_LOFlist,a1),(_cbswitch_cop2lc-_cbswitch_vbstrt,a0)
		move.l	d0,a0
		addq.l	#4,(a7)
		rts

gfx_beamcon02	bclr	#13,d4				;original
		move.w	d4,(beamcon0,a0)		;original
		move.l	a0,d0
		lea	(_cbswitch_beamcon0,pc),a0
		move.w	d4,(a0)
		st	(_cbflag_beamcon0-_cbswitch_beamcon0,a0)
		move.l	d0,a0
		addq.l	#2,(a7)
		rts

	;move (custom),(cia) does not work with Snoop/S on 68060
gfx_snoop1	move.b	(vhposr,a0),d0
		move.b	d0,(ciatodlow,a6)
		rts

	;cbswitch: may change registers d0/d1
_cbswitch	move.l	(_cbswitch_cop2lc,pc),(_custom+cop2lc)
		move.b	(_cbflag_beamcon0,pc),d0
		beq	.nobeamcon0
		move.w	(_cbswitch_beamcon0,pc),(_custom+beamcon0)
.nobeamcon0	move.b	(_cbflag_vbstrt,pc),d0
		beq	.novbstrt
		move.w	(_cbswitch_vbstrt,pc),(_custom+vbstrt)
.novbstrt	move.l	(input_norepeat,pc),d0
		beq	.norepeat
		exg	d0,a0
		st	(a0)				;set repeat key invalid
		move.l	d0,a0
.norepeat	jmp	(a0)

gfx_readvpos	move	(_custom+vposr),d0
		move.l	(_monitor,pc),d1
		cmp.l	#PAL_MONITOR_ID,d1
		beq	.pal
		cmp.l	#DBLPAL_MONITOR_ID,d1
		beq	.pal
		bset	#12,d0
		bra.b	.end
.pal		bclr	#12,d0
.end		rts

gfx_detectgenlock
		move.l	(_bplcon0,pc),d0
		rts

	IFD INITAGA					;enable enhanced gfx modes
gfx_initaga	move.l	#SETCHIPREV_BEST,d0
		jsr	(_LVOSetChipRev,a6)
		moveq	#-1,d0
		movem.l	(-$34,a5),d2/d6/d7/a2/a3/a6	;original
		rts
	ENDC

;============================================================================

_keyboard	moveq	#0,d4				;original
		not.b	d2				;original
		ror.b	#1,d2				;original
		cmp.b	(_keyexit,pc),d2
		beq	.exit
		cmp.b	(_keydebug,pc),d2
		beq	.debug
	IFD CBKEYBOARD
		movem.l	d0-a6,-(a7)
		move.l	d2,d0
		bsr	_cb_keyboard
		movem.l	(a7)+,d0-a6
	ENDC
		rts

.exit		pea	TDREASON_OK
.quit		move.l	(_resload,pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.debug		addq.l	#4,a7				;skip return address
		movem.l	(a7)+,d2-d4/a6			;keyboard interrupt
		addq.l	#4,a7
		movem.l	(a7)+,d2/a2
		addq.l	#4,a7
		movem.l	(a7)+,a1/a2
		addq.l	#8,a7				;skip ExitIntr, ExecBase
		move.l	(_attnflags,pc),d0
		btst	#AFB_68010,d0
		movem.l	(a7)+,d0-d1/a0-a1/a5-a6
	;transform stackframe to resload_Abort args
		bne	.68010
.68000		move.w	(a7),-(a7)			;sr
		move.l	(4,a7),(2,a7)			;pc
.68010		move.w	(a7),(6,a7)			;sr
		move.l	(2,a7),(a7)			;pc
		clr.w	(4,a7)
		pea	TDREASON_DEBUG
		bra	.quit

	IFD SETKEYBOARD
keymap_addmap	movem.l	d2/a2,-(a7)
		lea	(.keymap,pc),a0
		move.l	(_resload,pc),a2
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		beq	.nokeymap
		move.l	#MEMF_REVERSE,d1		;reduce variations due user settings
		jsr	(_LVOAllocMem,a6)
		move.l	d0,d2
		beq	.nokeymap
		lea	(.keymap,pc),a0
		move.l	d2,a1
		jsr	(resload_LoadFile,a2)
		move.l	d2,a0
		sub.l	a1,a1				;tags
		jsr	(resload_Relocate,a2)
		lea	($26+kr_List,a5),a0		;list
		move.l	d2,a1				;node to add
		lea	(kn_KeyMap,a1),a2
		move.l	a2,($22,a5)			;set default KeyMap
		jsr	(_LVOAddHead,a6)
.nokeymap	move.l	a5,d0				;original
		movem.l	(a7)+,d2/a2/a5			;original
		rts					;original

.keymap		dc.b	"WHDLoad.keymap",0
	EVEN
	ENDC

;============================================================================

input_task	moveq	#0,d7				;original
		bset	d0,d7				;original
		move.l	d7,d6				;original
		pea	($b2,a5)			;last rawkey for repeat
		lea	(input_norepeat,pc),a0
		move.l	(a7)+,(a0)
		rts

input_norepeat	dc.l	0

;============================================================================

disk_getunitid
	IFEQ NUMDRIVES
		moveq	#-1,d0
		rts
	ELSE
	IFLT NUMDRIVES
		cmp.l	(_custom1,pc),d0
	ELSE
		subq.l	#NUMDRIVES,d0
	ENDC
		scc	d0
	IFND NO68020
		extb.l	d0
	ELSE
		ext.w	d0
		ext.l	d0
	ENDC
		rts
	ENDC

;============================================================================

timer_init	move.l	(_time,pc),a0
		move.l	(whdlt_days,a0),d0
		mulu	#24*60,d0
		add.l	(whdlt_mins,a0),d0
	IFND NO68020
		mulu.l	#60,d0
	ELSE
		move.l	d0,d1
		lsl.l	#6,d0
		lsl.l	#2,d1
		sub.l	d1,d0
	ENDC
		move.l	(whdlt_ticks,a0),d1
		divu	#50,d1
		ext.l	d1
		add.l	d1,d0
		move.l	d0,($40,a2)
		movem.l	(a7)+,d2/a2-a3		;original

	IFD INIT_RESOURCE
		bra	_resource_init
	ELSE
		rts
	ENDC

;============================================================================
;  $60.1 0-disk in drive 1-no disk
;  $60.4 0-readwrite 1-readonly
;  $61.7 motor status
;  $63 unit
;  $3c disk change count

trd_format
trd_readwrite	movem.l	d2/a1-a2,-(a7)

		moveq	#0,d1
		move.b	($63,a3),d1		;unit number
		clr.b	(IO_ERROR,a1)

		btst	#1,($60,a3)		;disk inserted?
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
		move.l	d1,(IO_ACTUAL,a1)	;actually read
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
_trd_chg	dc.b	%1111111		;diskchanged
	ELSE
_trd_chg	dc.b	0			;diskchanged
	ENDC

trd_motor	moveq	#0,d0
		bchg	#7,($61,a3)		;motor status
		seq	d0
		rts

trd_protstatus	moveq	#0,d0
		move.b	($63,a3),d1		;unit number
		move.b	(_trd_prot,pc),d0
		btst	d1,d0
		seq	d0
		move.l	d0,(IO_ACTUAL,a1)
		add.l	#$d74-$d5a-6,(a7)	;skip unnecessary code
		rts

trd_endio	move.l	(_expmem,pc),-(a7)	;jump into rom
		add.l	#$453A4,(a7)
		rts

tdtask_cause	move.l	(_expmem,pc),-(a7)	;jump into rom
		add.l	#$44BDC,(a7)
		rts

trd_init	lea	($14c,a3),a0		;original
		move.l	a0,($10,a3)		;original
		bset	#1,($60,a3)		;no disk in drive
		addq.l	#2,(a7)
		rts

trd_task	move.b	($63,a3),d1		;unit number
		lea	(_trd_chg,pc),a0
		bclr	d1,(a0)
		beq	.2			;if not changed skip

		bset	#1,($60,a3)		;set no disk inserted
		bne	.3
		addq.l	#1,($3c,a3)		;inc change count
		bsr	tdtask_cause
.3
		bclr	#1,($60,a3)		;set disk inserted
		addq.l	#1,($3c,a3)		;inc change count
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

	IFD CBDOSLOADSEG
dos_LoadSeg	move.l	d0,d1		;original
		beq	.end		;successful?
		tst.l	d7		;filename
		beq	.end

		movem.l	d0-a6,-(a7)
		move.l	d7,a0
.cnt		tst.b	(a0)+
		bne	.cnt
		subq.l	#1,a0
		sub.l	d7,a0
		move.l	a0,d0
		
		sub.w	#260,a7		;BSTR cannot be longer than 255
		move.l	a7,d4
		addq.l	#2,d4
		and.w	#$fffc,d4	;longword aligned
		move.l	d4,a0
		move.b	d0,(a0)+
		move.l	d7,a1
.cpy		move.b	(a1)+,(a0)+
		bne	.cpy

		move.l	d4,d0
		lsr.l	#2,d0
		bsr	_cb_dosLoadSeg
		bsr	_flushcache

		add.w	#260,a7
		movem.l	(a7)+,d0-a6

.end		move.l	(a7)+,a0
		lea	(12,a7),a7	;original
		tst.l	d0
		jmp	(a0)
	ENDC

	IFD WHDCTRL
dos_whdctrl	movem.l	d2-d3,-(a7)
		moveq	#OLTAG_DOS,d0
		move.l	(4),a6
		jsr	(_LVOTaggedOpenLibrary,a6)
		move.l	d0,a6
		lea	(.name,pc),a0
		move.l	a0,d1		;name
		lea	(.seglist,pc),a0
		move.l	a0,d2
		lsr.l	#2,d2		;seglist
		moveq	#-2,d3		;type/usecount, CMD_INTERNAL
		jsr	(_LVOAddSegment,a6)
		movem.l	(a7)+,d2-d3
		moveq	#0,d0		;continue with startup-sequence, see patch
		rts

.name		dc.b	"WHDCtrl",0
.template	dc.b	"Quit/S",0
	CNOP 0,4
.seglist	dc.l	0		;next segment
		moveq	#OLTAG_DOS,d0
		move.l	(4),a6
		jsr	(_LVOTaggedOpenLibrary,a6)
		move.l	d0,a6
		lea	(.template,pc),a0
		move.l	a0,d1
		clr.l	-(a7)
		move.l	a7,d2		;array
		moveq	#0,d3		;rdargs
		jsr	(_LVOReadArgs,a6)
		move.l	(a7)+,d1
		move.l	d0,d7
		beq	.fail
		tst.l	d1
		beq	.free
		move.l	(_resload,pc),a0
		pea	TDREASON_OK
		jmp	(resload_Abort,a0)
.free		move.l	d7,d1
		jsr	(_LVOFreeArgs,a6)
.end		moveq	#0,d0
		rts
.fail		jsr	(_LVOIoErr,a6)
		move.l	d0,d1		;code
		moveq	#0,d2		;header
		jsr	(_LVOPrintFault,a6)
		moveq	#20,d0
		rts
	ENDC

	IFD BOOTDOS
dos_bootdos
	;init boot exe
		lea	(dos_startup,pc),a0
		move.l	a0,(bootfile_exe_j+2-dos_startup,a0)
	;fake startup-sequence
		lea	(bootname_ss,pc),a0
		move.l	a0,d1
	;return
		rts

dos_startup
	IFD INIT_LOWLEVEL
		bsr	_lowlevel_init
	ENDC
	IFD INIT_NONVOLATILE
		bsr	_nonvolatile_init
	ENDC
	IFD PROMOTE_DISPLAY
		bsr	_promotedisplay
	ENDC
		bra	_bootdos
	ENDC

;---------------
; performs a C:Assign
; IN:	A0 = CSTR destination name
;	A1 = CPTR directory (could be 0 meaning SYS:)
; OUT:	-

	IFD DOSASSIGN
_dos_assign	movem.l	d2/a3-a6,-(a7)
		move.l	a0,a3			;A3 = name
		move.l	a1,a4			;A4 = directory

	;open doslib
		moveq	#OLTAG_DOS,d0
		move.l	(4),a6
		jsr	(_LVOTaggedOpenLibrary,a6)
		move.l	d0,a6

	;lock directory
		move.l	a4,d1
		move.l	#ACCESS_READ,d2
		jsr	(_LVOLock,a6)
		move.l	d0,d2
	IFD DEBUG
		beq	_debug3
	ENDC

	;make assign
		move.l	a3,d1
		jsr	(_LVOAssignLock,a6)
	IFD DEBUG
		tst.l	d0
		beq	_debug3
	ENDC
		
		movem.l	(a7)+,d2/a3-a6
		rts
	ENDC

;============================================================================

	IFD PROMOTE_DISPLAY

_promotedisplay	movem.l	d0-a6,-(a7)
		
		move.l	(_monitor,pc),d0
		moveq	#10,d5				;D5 = monitor id
		lea	(_mon_dblpal,pc),a3		;A3 = monitor name
		lea	(_load_dblpal,pc),a4		;A4 = monitor load
		cmp.l	#DBLPAL_MONITOR_ID,d0
		beq	.promote
		moveq	#9,d5				;D5 = monitor id
		lea	(_mon_dblntsc,pc),a3		;A3 = monitor name
		lea	(_load_dblntsc,pc),a4		;A4 = monitor load
		cmp.l	#DBLNTSC_MONITOR_ID,d0
		bne	.end
	;enable AGA chipset
.promote	moveq	#OLTAG_GRAPHICS,d0
		move.l	(4),a6
		jsr	(_LVOTaggedOpenLibrary,a6)
		move.l	d0,a5				;A5 = gfxbase
		move.l	d0,a6
		move.l	#SETCHIPREV_BEST,d0
		jsr	(_LVOSetChipRev,a6)
	;load monitor
		sub.l	a1,a1
		move.l	(4),a6
		jsr	(_LVOFindTask,a6)
		move.l	d0,a2				;A2 = process
		move.l	(pr_WindowPtr,a2),d6		;D6 = window
		moveq	#-1,d0
		move.l	d0,(pr_WindowPtr,a2)		;avoid 'Insert Volume' requester
		moveq	#OLTAG_DOS,d0
		jsr	(_LVOTaggedOpenLibrary,a6)
		move.l	d0,a6
		move.l	a4,d1				;command
		moveq	#0,d2				;taglist
		jsr	(_LVOSystemTagList,a6)
		move.l	d6,(pr_WindowPtr,a2)		;restore window
		tst.l	d0
		beq	.monok
.nomon		pea	(_err_load_mon,pc)
		pea	TDREASON_FAILMSG
		move.l	(_resload,pc),a0
		jmp	(resload_Abort,a0)
	;change default monitor
.monok		moveq	#0,d0				;display id
		move.l	a3,a1				;monitor name
		move.l	a5,a6
		jsr	(_LVOOpenMonitor,a6)
		move.l	d0,d7				;D7 = monitor
		beq	.nomon
		move.l	(gb_default_monitor,a6),a0
		jsr	(_LVOCloseMonitor,a6)
		move.w	d5,(gb_monitor_id,a6)
		move.l	d7,(gb_default_monitor,a6)
		bset	#LIBB_CHANGED,(LIB_FLAGS,a6)
		move.l	a6,a1
		move.l	(4),a6
		jsr	(_LVOSumLibrary,a6)
.end
		movem.l	(a7)+,d0-a6
		rts

	ENDC

;============================================================================

	IFD HDINIT

hd_init		move.l	(a7)+,d0
		movem.l	d0/d2/a2-a6,-(a7)	;original
		moveq	#0,d0			;original

	INCLUDE	whdload/kickfs.s
	ENDC

;============================================================================

	IFD SEGTRACKER

segtracker_init	move.l	(8,a0),($a4,a1)		;original

	INCLUDE whdload/segtracker.s
	ENDC

;============================================================================

_flushcache	move.l	(_resload,pc),-(a7)
		add.l	#resload_FlushCache,(a7)
		rts

;============================================================================

	IFD INIT_LOWLEVEL
	IFND BOOTDOS
	FAIL	INIT_LOWLEVEL requires BOOTDOS
	ENDC
	INCLUDE whdload/lowlevel.s
	ELSE
	IFD JOYPADEMU
	FAIL	JOYPADEMU requires INIT_LOWLEVEL
	ENDC
	ENDC

	IFD INIT_NONVOLATILE
	IFND BOOTDOS
	FAIL	INIT_NONVOLATILE requires BOOTDOS
	ENDC
	INCLUDE whdload/nonvolatile.s
	ENDC

	IFD INIT_RESOURCE
	INCLUDE whdload/resource.s
	ENDC

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

	IFND slv_Version
slv_kickname	dc.b	"40068.a1200",0
	ELSE
slv_kickname
	IFD NO68020
		dc.w	KICKCRC600,.a600-slv_base
	ENDC
		dc.w	KICKCRC1200,.a1200-slv_base
		dc.w	KICKCRC4000,.a4000-slv_base
	IFND NO68020
		dc.w	KICKCRC600,.a600-slv_base
	ENDC
		dc.w	0
.a600		dc.b	"40063.a600",0
.a1200		dc.b	"40068.a1200",0
.a4000		dc.b	"40068.a4000",0
	IFD NO68020
_badkickstart	dc.b	"Your Kickstart 3.1 image isn't 68000/010 compatible",0
	ENDC
	ENDC
	IFD PROMOTE_DISPLAY
_load_dblpal	dc.b	"DblPAL",0
_load_dblntsc	dc.b	"DblNTSC",0
_err_load_mon	dc.b	"Couldn't load monitor!",0
_mon_dblpal	dc.b	"DblPAL.monitor",0
_mon_dblntsc	dc.b	"DblNTSC.monitor",0
	ENDC
	EVEN
_kick31_tags	dc.l	WHDLTAG_CBSWITCH_SET
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
	IFD INIT_LOWLEVEL
		dc.l	WHDLTAG_LANG_GET
_language	dc.l	0
	ENDC
		dc.l	0
_resload	dc.l	0
_cbswitch_cop2lc	dc.l	0
_cbswitch_beamcon0	dc.w	0
_cbswitch_vbstrt	dc.w	0
_cbflag_beamcon0	dc.b	0
_cbflag_vbstrt		dc.b	0

;============================================================================

