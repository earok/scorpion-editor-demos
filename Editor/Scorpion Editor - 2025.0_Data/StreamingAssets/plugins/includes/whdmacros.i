;*---------------------------------------------------------------------------
;  :Module.	whdmacros.i
;  :Contens.	useful macros and symbols for WHDLoad-Slaves
;  :Author.	Bert Jahn
;  :History.	11.04.99 separated from whdload.i
;		07.09.00 macro 'skip' fixed for distance of 2
;		21.09.00 macro 'blitz' small fix
;		04.06.04 macro 'blitz' improved
;		29.10.04 macro 'blitz' fixed (oh god what a mess)
;		27.02.07 waitvbs added
;		03.09.07 BLITWAIT macro improved
;		06.09.07 adapted to work with Devpac 3.18
;		26.12.20 macro 'blitz' no longer uses movem to avoid breaking
;			 _MOVEMREGS/_MOVEMBYTES 
;		21.12.20 macro LOG added
;  :Language.	68000 Assembler
;---------------------------------------------------------------------------*

 IFND WHDMACROS_I
WHDMACROS_I SET 1

	IFND	HARDWARE_CIA_I
	INCLUDE	hardware/cia.i
	ENDC
	IFND	HARDWARE_CUSTOM_I
	INCLUDE	hardware/custom.i
	ENDC
	IFND	HARDWARE_INTBITS_I
	INCLUDE	hardware/intbits.i
	ENDC
	IFND	HARDWARE_DMABITS_I
	INCLUDE	hardware/dmabits.i
	ENDC
	IFND	EXEC_TYPES_I
	INCLUDE	exec/types.i
	ENDC

;=============================================================================

 BITDEF POTGO,OUTRY,15
 BITDEF POTGO,DATRY,14
 BITDEF POTGO,OUTRX,13
 BITDEF POTGO,DATRX,12
 BITDEF POTGO,OUTLY,11
 BITDEF POTGO,DATLY,10
 BITDEF POTGO,OUTLX,9
 BITDEF POTGO,DATLX,8
 BITDEF POTGO,START,0

_ciaa		= $bfe001
_ciab		= $bfd000
_custom		= $dff000

****************************************************************
***** write opcode ILLEGAL to specified address
ill	MACRO
	IFNE	NARG-1
		FAIL	arguments "ill"
	ENDC
		move.w	#$4afc,\1
	ENDM

****************************************************************
***** write opcode RTS to specified address
ret	MACRO
	IFNE	NARG-1
		FAIL	arguments "ret"
	ENDC
		move.w	#$4e75,\1
	ENDM

****************************************************************
***** skip \1 instruction bytes on address \2
skip	MACRO
	IFNE	NARG-2
		FAIL	arguments "skip"
	ENDC
	IFNE \1&1
		FAIL	arguments "skip"
	ENDC
	IFEQ \1-2
		move.w	#$4e71,\2
	ELSE
	IFLE \1-126
		move.w	#$6000+\1-2,\2
	ELSE
	IFLE \1-32766
		move.l	#$60000000+\1-2,\2
	ELSE
		FAIL	"skip: distance to large"
	ENDC
	ENDC
	ENDC
	ENDM

****************************************************************
***** write \1 times opcode NOP starting at address \2
***** (better to use "skip" instead)
nops	MACRO
	IFNE	NARG-2
		FAIL	arguments "nops"
	ENDC
		movem.l	d0/a0,-(a7)
		IFGT \1-127
			move.w	#\1-1,d0
		ELSE
			moveq	#\1-1,d0
		ENDC
		lea	\2,a0
.lp\@		move.w	#$4e71,(a0)+
		dbf	d0,.lp\@
		movem.l	(a7)+,d0/a0
	ENDM

****************************************************************
***** write opcode JMP \2 to address \1
patch	MACRO
	IFNE	NARG-2
		FAIL	arguments "patch"
	ENDC
		move.w	#$4ef9,\1
		pea	(\2,pc)
		move.l	(a7)+,2+\1
	ENDM

****************************************************************
***** write opcode JSR \2 to address \1
patchs	MACRO
	IFNE	NARG-2
		FAIL	arguments "patchs"
	ENDC
		move.w	#$4eb9,\1
		pea	(\2,pc)
		move.l	(a7)+,2+\1
	ENDM

****************************************************************
***** wait that blitter has finished his job
***** (this is adapted from graphics.WaitBlit, see autodocs for
*****  hardware bugs/caveats and check eab thread 31758)
***** if \1 is given it must be an address register containing _custom
BLITWAIT MACRO
	IFEQ	NARG-1
		tst.b	(dmaconr,\1)
		btst	#DMAB_BLTDONE-8,(dmaconr,\1)
		beq.b	.1\@
.2\@		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		btst	#DMAB_BLTDONE-8,(dmaconr,\1)
		bne.b	.2\@
.1\@		tst.b	(dmaconr,\1)
	ELSE
		tst.b	(_custom+dmaconr)
		btst	#DMAB_BLTDONE-8,(_custom+dmaconr)
		beq.b	.1\@
.2\@		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		btst	#DMAB_BLTDONE-8,(_custom+dmaconr)
		bne.b	.2\@
.1\@		tst.b	(_custom+dmaconr)
	ENDC
	ENDM

****************************************************************
***** wait of vertical blank
***** if \1 is given it must be an address register containing _custom
waitvb	MACRO
	IFEQ	NARG-1
.1\@		btst	#0,(vposr+1,\1)
		beq	.1\@
.2\@		btst	#0,(vposr+1,\1)
		bne	.2\@
	ELSE
.1\@		btst	#0,(_custom+vposr+1)
		beq	.1\@
.2\@		btst	#0,(_custom+vposr+1)
		bne	.2\@
	ENDC
	ENDM
***** this is the same as before but secure
***** it also works when the code always run in only one half of
***** the screen and therefore vertical bit pos 8 is unchanged
***** (eg on programs with heavy interrupts or copper ints)
waitvbs	MACRO
		movem.l	d0-d2,-(a7)
		bsr	.g\@
.1\@		move.w	d0,d2
		bsr	.g\@
		cmp.w	d0,d2
		bls	.1\@
		bra	.q\@
	IFEQ	NARG-1
.g\@		move.w	(vposr,\1),d0
		move.b	(vhposr,\1),d1
		cmp.w	(vposr,\1),d0
	ELSE
.g\@		move.w	(_custom+vposr),d0
		move.b	(_custom+vhposr),d1
		cmp.w	(_custom+vposr),d0
	ENDC
		bne	.g\@
		and.w	#1,d0
		lsl.w	#8,d0
		move.b	d1,d0
		rts
.q\@		movem.l	(a7)+,d0-d2
	ENDM

****************************************************************
***** wait for pressing any button
***** if \1 is given it must be an address register containing _custom
waitbutton	MACRO
	IFEQ	NARG
		move.l	a0,-(a7)
		lea	(_custom),a0
.down\@		bsr	.wait\@
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
		btst	#POTGOB_DATLY-8,(potinp,a0)		;RMB
		beq	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		bne	.down\@
.up\@		bsr	.wait\@					;entprellen
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
		btst	#POTGOB_DATLY-8,(potinp,a0)		;RMB
		beq	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		beq	.up\@
		bsr	.wait\@					;entprellen
		bra	.done\@
.wait\@		waitvb	a0
		rts
.done\@		move.l	(a7)+,a0
	ELSE
	IFEQ	NARG-1
.down\@		bsr	.wait\@
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
		btst	#POTGOB_DATLY-8,(potinp,\1)		;RMB
		beq	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		bne	.down\@
.up\@		bsr	.wait\@					;entprellen
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
		btst	#POTGOB_DATLY-8,(potinp,\1)		;RMB
		beq	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		beq	.up\@
		bsr	.wait\@					;entprellen
		bra	.done\@
.wait\@		waitvb	\1
		rts
.done\@
	ELSE
		FAIL	arguments "waitbutton"
	ENDC
	ENDC
	ENDM

waitbuttonup	MACRO
	IFEQ	NARG
		move.l	a0,-(a7)
		lea	(_custom),a0
.up\@		bsr	.wait\@					;entprellen
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
		btst	#POTGOB_DATLY-8,(potinp,a0)		;RMB
		beq	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		beq	.up\@
		bsr	.wait\@					;entprellen
		bra	.done\@
.wait\@		waitvb	a0
		rts
.done\@		move.l	(a7)+,a0
	ELSE
	IFEQ	NARG-1
.up\@		waitvb	\1					;entprellen
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
		btst	#POTGOB_DATLY-8,(potinp,\1)		;RMB
		beq	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		beq	.up\@
		waitvb	\1					;entprellen
	ELSE
		FAIL	arguments "waitbuttonup"
	ENDC
	ENDC
	ENDM

****************************************************************
***** flash the screen and wait for LMB
blitz		MACRO
		move.l	d0,-(a7)
	;	move	#DMAF_SETCLR!DMAF_RASTER,(_custom+dmacon)
.lpbl\@
	IFNE NARG&1
		move	#$4200,(_custom+bplcon0)
	ENDC
		move.w	d0,(_custom+color)
		subq.w	#1,d0
		btst	#6,$bfe001
		bne	.lpbl\@
		bsr	.waitvb\@			;entprellen
		bsr	.waitvb\@			;entprellen
.lp2bl\@
	IFNE NARG&1
		move	#$4200,(_custom+bplcon0)
	ENDC
		move.w	d0,(_custom+color)
		subq.w	#1,d0
		btst	#6,$bfe001
		beq	.lp2bl\@
		bsr	.waitvb\@			;entprellen
		bsr	.waitvb\@			;entprellen
		clr.w	(_custom+color)
		move.l	(a7)+,d0
		bra	.end\@
.waitvb\@	waitvb
		rts
.end\@
		ENDM

****************************************************************
***** color the screen and wait for LMB
bwait		MACRO
		move	#$1200,bplcon0+_custom
.wd\@
	IFEQ NARG
		move.w	#$ff0,color+_custom		;yellow
	ELSE
		move.w	#\1,color+_custom
	ENDC
		btst	#6,$bfe001
		bne	.wd\@
		waitvb					;entprellen
		waitvb					;entprellen
.wu\@		btst	#6,$bfe001
		beq	.wu\@
		waitvb					;entprellen
		waitvb					;entprellen
		clr.w	color+_custom
		ENDM

****************************************************************
***** install Vertical-Blank-Interrupt which quits on LMB pressed
QUITVBI		MACRO
		move.l	a0,-(a7)
		lea	(.vbi,pc),a0
		move.l	a0,$6c
		bra	.g
.vbi		btst	#6,$bfe001
		beq	.vbi+1		;create "address error"
		move.w	#INTF_VERTB,_custom+intreq
		rte
.g		move.w	#INTF_SETCLR!INTF_INTEN!INTF_VERTB,_custom+intena
		move.w	#INTF_VERTB,_custom+intreq
		move.l	(a7)+,a0
	ENDM

****************************************************************
***** set all registers to zero
resetregs	MACRO
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		moveq	#0,d7
		sub.l	a0,a0
		sub.l	a1,a1
		sub.l	a2,a2
		sub.l	a3,a3
		sub.l	a4,a4
		sub.l	a5,a5
		sub.l	a6,a6
	ENDM

****************************************************************
***** create message in .whdl_log
***** requires WHDLoad version 18 and active option FileLog/S
***** label _resload must contain Resload base
***** all arguments must be long
***** all registers are preserved
***** this macro only works with vasm!
***** LOG <"text %s d0=%lx d1=%ld">,d0,d1

LOG MACRO
		move.l	a0,-(a7)	; don't use movem to preserve _MOVEMREGS/BYTES
		move.l	a1,-(a7)
		move.l	a2,-(a7)
CARG SET \#
	REPT \#-1
		move.l	\-,-(a7)
	ENDR
		bra	.skip\@
.fmt\@		db	\1,0
	EVEN
.skip\@		lea	(.fmt\@),a0
		move.l	a7,a1
		move.l	(_resload,pc),a2
		jsr	(resload_Log,a2)

		add	#(\#-1)*4,a7
		move.l	(a7)+,a2
		move.l	(a7)+,a1
		move.l	(a7)+,a0
	ENDM

;=============================================================================

 ENDC
