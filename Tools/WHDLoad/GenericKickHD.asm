;*---------------------------------------------------------------------------
;  :Program.	GenericKick.asm
;  :Contents.	Slave for "GenericKick"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: GenericKickHD.asm 1.3 2016/04/24 23:18:33 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
;		01.11.07 reworked for v16+ (Wepl)
;		24.04.16 some cleanup, arg check
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

;============================================================================

_bootdos	lea	(_saveregs,pc),a0
		movem.l	d1-d3/d5-d7/a1-a2/a4-a6,(a0)
		move.l	(a7)+,(11*4,a0)
		move.l	(_resload,pc),a2	;A2 = resload

		lea	(_program,pc),a0
		move.l	#STR_BUF_SIZE,d0
		moveq	#0,d1
		jsr	(resload_GetCustom,a2)

	;split program and arguments
		lea	(_program,pc),a0
		tst.b	(a0)
		bne	.custom_set
		
	;Load game.exe instead into _program
		lea	(_game_exe,pc),a1
		
.push_game_exe_char
		move.b	(a1)+,(a0)+
		bne .push_game_exe_char
		
		lea	(_program,pc),a0
		
.custom_set
		moveq	#0,d3			;D3 = arglen
		
.search		move.b	(a0)+,d0
		beq	.noargs
		cmp.b	#" ",d0
		bne	.search
		clr.b	(-1,a0)			;terminate program
.skip		cmp.b	#" ",(a0)+
		beq	.skip
		subq.l	#1,a0
		move.l	a0,a3			;A3 = args
.count		tst.b	(a0)+
		beq	.lf
		addq.l	#1,d3
		bra	.count
.noargs		move.l	a0,a3
		addq.l	#1,a0
.lf		subq.l	#1,a0
		move.b	#10,(a0)+		;line feed
		clr.b	(a0)
		addq.l	#1,d3

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		lea	(_dosbase,pc),a0
		move.l	d0,(a0)
		move.l	d0,a6			;A6 = dosbase

	;assigns

	;load exe
		lea	(_program,pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_noseg

	;call
		move.l	d7,d1
		move.l	d3,d0
		move.l	a3,a0
		bsr	.call
		move.l	(_resload,pc),a2

	;wait a bit
		moveq	#50,d0
		jsr	(resload_Delay,a2)

	;quit
		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

; D0 = ULONG arg length
; D1 = BPTR  segment
; A0 = CPTR  arg string

.call		lea	(_callregs,pc),a1
		movem.l	d2-d7/a2-a6,(a1)
		move.l	(a7)+,(11*4,a1)
		move.l	d0,d4
		lsl.l	#2,d1
		move.l	d1,a3
		move.l	a0,a4
	;create longword aligend copy of args
		lea	(_callargs,pc),a1
		move.l	a1,d2
.callca		move.b	(a0)+,(a1)+
		subq.w	#1,d0
		bne	.callca
	;set args
		move.l	(_dosbase,pc),a6
		jsr	(_LVOInput,a6)
		lsl.l	#2,d0		;BPTR -> APTR
		move.l	d0,a0
		lsr.l	#2,d2		;APTR -> BPTR
		move.l	d2,(fh_Buf,a0)
		clr.l	(fh_Pos,a0)
		move.l	d4,(fh_End,a0)
	;call
		move.l	d4,d0
		move.l	a4,a0
		movem.l	(_saveregs,pc),d1-d3/d5-d7/a1-a2/a4-a6
		jsr	(4,a3)
	;return
		movem.l	(_callregs,pc),d2-d7/a2-a6
		move.l	(_callrts,pc),a0
		jmp	(a0)

	CNOP 0,4
_saveregs	ds.l	11
_saverts	dc.l	0
_dosbase	dc.l	0
_callregs	ds.l	11
_callrts	dc.l	0
_callargs	ds.b	208
STR_BUF_SIZE = 128
_program	ds.b	STR_BUF_SIZE,0
;_t_nocustom	dc.b	"You must specify the program to start via the Custom option!",0
_game_exe	dc.b	"game.exe",0
	EVEN

_noseg		pea	(_program,pc)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		jmp	(resload_Abort,a2)

;_nocustom
;		bra return_no_custom
		;pea	(_t_nocustom,pc)
		;pea	TDREASON_FAILMSG
		;jmp	(resload_Abort,a2)

;============================================================================

	END
