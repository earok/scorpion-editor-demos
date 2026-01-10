;*---------------------------------------------------------------------------
;  :Modul.	segtracker.s
;  :Contents.	implementation of SegTracker with WHDLoad KickEmu
;  :Author.	Wepl
;  :Version.	$Id: segtracker.s 1.3 2021/01/02 01:14:16 wepl Exp wepl $
;  :History.	30.05.18 started
;		28.12.18 completed for 3.1 roms
;		01.01.19 completed for 1.x roms
;		01.01.21 fixed broken loop termination check in st_untrack
;  :Requires.	kick{12,13,31}.s (to be called from)
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.16, Asm-Pro 1.16, PhxAss 4.38
;  :To Do.	
;---------------------------------------------------------------------------*

	INCLUDE	exec/resident.i
	INCLUDE	exec/semaphores.i

	STRUCTURE	SegTrackerSignalSemaphore,SS_SIZE
		APTR	stss_find
		STRUCT	stss_list,MLH_SIZE
		LABEL	stss_SIZEOF

	STRUCTURE	SegTrackerSegNode,MLN_SIZE
		CPTR	stsn_name
		ULONG	stsn_array			;NULL terminated array of segment ptr/size
		LABEL	stsn_SIZEOF
		
;---------------------------------------------------------------------------*
; init SegTracker
;	init & add semaphore
;	add rom residents to list
;	patch dos functions on C dos.library versions
;	on BCPL dos.library versions patches are done individual

st_install	movem.l	d0-d1/a0-a6,-(a7)
		move.l	(4),a6				;A6 = exec

	;build semaphore
		lea	(st_sem,pc),a2			;A2 = Semaphore
		move.b	#-127,(LN_PRI,a2)
		lea	(st_semname,pc),a0
		move.l	a0,(LN_NAME,a2)
		lea	(st_find,pc),a0
		move.l	a0,(stss_find,a2)
		lea	(stss_list,a2),a0
		NEWLIST	a0
	IFGE KICKVERSION-36
		move.l	a2,a1
		jsr	(_LVOAddSemaphore,a6)
	ELSE
		move.b	#NT_SIGNALSEM,(LN_TYPE,a2)
		move.l	a2,a0
		jsr	(_LVOInitSemaphore,a6)
		lea	(SemaphoreList,a6),a0
		move.l	a2,a1
		jsr	(_LVOForbid,a6)
		jsr	(_LVOEnqueue,a6)
		jsr	(_LVOPermit,a6)
	ENDC
	;add rom modules
		move.l	(_expmem,pc),a3			;A3 = search start
		move.l	a3,a4
		add.l	#KICKSIZE,a4			;A4 = search end
		sub.l	a5,a5				;A5 = last segnode
.rom_loop	cmp	#RTC_MATCHWORD,(a3)+
		bne	.rom_next
		lea	(-2,a3),a2			;A2 = resident structure
		cmp.l	(RT_MATCHTAG,a2),a2
		bne	.rom_next
		move.l	(RT_ENDSKIP,a2),a3		;advance search pointer
	;check id-string, must contain a date
		move.l	(RT_IDSTRING,a2),a1
.rom_chkid	move.b	(a1)+,d0
		beq	.rom_next
		cmp.b	#'(',d0
		bne	.rom_chkid
	;term previous segment
		move.l	a5,d0
		beq	.rom_alloc
		move.l	a2,d0
		add.l	d0,(stsn_array+4,a5)		;set size
	;alloc new node
.rom_alloc	tst.b	(a1)+				;strlen
		bne	.rom_alloc
		add	#stsn_SIZEOF+8+4,a1		;+one-segment +"ROM "
		move.l	a1,d0
		sub.l	(RT_IDSTRING,a2),d0		;length
		move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
		jsr	(_LVOAllocMem,a6)
		move.l	d0,a5				;A5 = segnode
		move.l	a2,(stsn_array,a5)		;seg start
		subq.l	#4,(stsn_array,a5)		;made it compatible to segment lists
		move.l	a2,d0
		sub.l	d0,(stsn_array+4,a5)		;seg size prepared
		lea	(stsn_SIZEOF+8,a5),a1
		move.l	a1,(stsn_name,a5)
		move.l	#"ROM ",(a1)+
		move.l	(RT_IDSTRING,a2),a0
.rom_copy	move.b	(a0)+,d0
		cmp.b	#10,d0				;skip line feed
		beq	.rom_copy
		cmp.b	#13,d0				;skip carriage return
		beq	.rom_copy
		move.b	d0,(a1)+
		bne	.rom_copy
		lea	(st_sem+stss_list,pc),a0
		move.l	a5,a1
		jsr	(_LVOAddTail,a6)
.rom_next	cmp.l	a3,a4
		bhi	.rom_loop
	;term last segment
		move.l	a3,d0
		add.l	d0,(stsn_array+4,a5)		;set size

	IFGE KICKVERSION-36
	;add patches on dos.library
		lea	(_dosname,pc),a1
		jsr	(_LVOOldOpenLibrary,a6) 	
		move.l	d0,a3				;A3 = dos
		move	#_LVOLoadSeg,a0
		lea	(st_LoadSeg,pc),a1
		lea	(st_dloadseg,pc),a2
		bsr	.patch
		move	#_LVONewLoadSeg,a0
		lea	(st_NewLoadSeg,pc),a1
		lea	(st_dnewloadseg,pc),a2
		bsr	.patch
		move	#_LVOUnLoadSeg,a0
		lea	(st_UnLoadSeg,pc),a1
		lea	(st_dunloadseg,pc),a2
		bsr	.patch
	ENDC

		movem.l	(a7)+,d0-d1/a0-a6
		rts

	IFGE KICKVERSION-36
	;add patches on post BCPL dos.library releases
.patch		move.l	a1,d0				;func entry
		move.l	a3,a1				;library
		jsr	(_LVOSetFunction,a6)
		move.l	d0,(a2)
		rts
	ENDC
		
;---------------------------------------------------------------------------*
; track given segment

	IFGE KICKVERSION-36
		;D1=name D2=tags
st_NewLoadSeg	move.l	(st_dnewloadseg,pc),a0
		bra	st_load

		;D1=name
st_LoadSeg	move.l	(st_dloadseg,pc),a0
st_load		move.l	d1,-(a7)			;name
		jsr	(a0)
		move.l	(a7)+,a0			;name
	ENDC

		;D0=segment A0=name
st_track	movem.l	d0-d3/a2-a3/a6,-(a7)		;preserve return values from dos D0/D1
		move.l	d0,d2				;D2 = segment list
		beq	.quit				;if load failed
		move.l	a0,a2				;A2 = name
	;count segments, calc memory requirement
		move.l	d2,d0
		moveq	#0,d3				;D3 = memory length
.count		addq.l	#8,d3
		lsl.l	#2,d0				;BPTR -> APTR
		move.l	d0,a0
		move.l	(a0),d0				;next segment
		bne	.count
	;strlen, calc memory requirement
		move.l	a2,a0
.len		addq.l	#1,d3
		tst.b	(a0)+
		bne	.len
	;get memory
		add.l	#4+stsn_SIZEOF,d3		;first long to store allocation length
		move.l	d3,d0
		move.l	#MEMF_PUBLIC!MEMF_CLEAR,d1
		move.l	(4),a6
		jsr	(_LVOAllocMem,a6)
		tst.l	d0
		beq	.quit
		move.l	d0,a1				;A1 = segnode
		move.l	d3,(a1)+			;remember allocation length
	;fill segments
		lea	(stsn_array,a1),a0
		move.l	d2,d0				;segment list
.fill		lsl.l	#2,d0				;BPTR -> APTR
		move.l	d0,a3
		move.l	a3,(a0)+			;pointer
		move.l	(-4,a3),(a0)
		subq.l	#4,(a0)+			;length
		move.l	(a3),d0
		bne	.fill
		clr.l	(a0)+				;end of list
	;fill name
		move.l	a0,(stsn_name,a1)
.copy		move.b	(a2)+,(a0)+
		bne	.copy
	;add node
		lea	(st_sem+stss_list,pc),a0
		jsr	(_LVOForbid,a6)
		jsr	(_LVOAddHead,a6)
		jsr	(_LVOPermit,a6)
	;leave
.quit		movem.l	(a7)+,d0-d3/a2-a3/a6		;restore return values from dos D0/D1
		rts

;---------------------------------------------------------------------------*
; untrack given segment

	IFGE KICKVERSION-36
		;D1=segment
st_UnLoadSeg	move.l	(st_dunloadseg,pc),-(a7)
	ENDC

		;D1=segment
st_untrack	movem.l	d0-d1/a0-a4/a6,-(a7)		;preserve calling args
		tst.l	d1
		beq	.quit
		move.l	d1,a2				;A2 = segment list to be freed
		move.l	(4),a6				;A6 = exec
		jsr	(_LVOForbid,a6)
	;loop over provided segments
.loopseg	add.l	a2,a2
		add.l	a2,a2				;BPTR -> APTR
	;loop over stored segment lists
	;we assume there is always something in the list (ROM)
		move.l	(st_sem+stss_list+MLH_HEAD,pc),a3
.loopstseg	moveq	#0,d0				;flag used memory
	;loop over stored array
		lea	(stsn_array,a3),a0
.looparray	cmp.l	(a0)+,a2			;pointer equal?
		bne	.skip
		clr.l	(a0)				;mark unused
.skip		add.l	(a0)+,d0			;add size to flag
		tst.l	(a0)
		bne	.looparray
	;next stored segment list
		move.l	(MLN_SUCC,a3),a4		;next node
	;free stored segment list if empty
		tst.l	d0
		bne	.nextstseg
		move.l	a3,a1
		jsr	(_LVORemove,a6)
		move.l	a3,a1
		move.l	-(a1),d0
		jsr	(_LVOFreeMem,a6)
	;next stored segment list
.nextstseg	move.l	a4,a3
		tst.l	(MLN_SUCC,a3)
		bne	.loopstseg
.nextseg	move.l	(a2),a2
		move.l	a2,d0
		bne	.loopseg
		jsr	(_LVOPermit,a6)
.quit		movem.l	(a7)+,d0-d1/a0-a4/a6		;restore calling args
		rts

;---------------------------------------------------------------------------*
; support routine to find which segment belongs to an address
; if A1=A2 return segment list in (A1) instead
; IN:	A0 = APTR address to find
;	A1 = APTR ULONG to store segment number
;	A2 = APTR ULONG to store offset in segment
; OUT:	D0 = CPTR name of segment list

st_find		movem.l	d2-d3/a3-a4,-(a7)

	;loop over segment lists
		move.l	(st_sem+stss_list+MLH_HEAD,pc),d3
.loopstseg	moveq	#0,d0				;return code / segment count
		move.l	d3,a3
		move.l	(MLN_SUCC,a3),d3
		beq	.quit				;end of list
	;loop over current segment array
		lea	(stsn_array,a3),a4
.looparray	movem.l	(a4)+,d1/d2			;start/size
		cmp.l	d1,a0
		blo	.skip
		add.l	d1,d2
		cmp.l	d2,a0
		bhi	.skip
		move.l	d0,(a1)				;segment number
		sub.l	d1,a0
		subq.l	#4,a0				;pointer to next segment
		move.l	a0,(a2)				;offset in segment
		move.l	(stsn_name,a3),d0		;name
		cmp.l	a1,a2
		bne	.quit
		move.l	(stsn_array,a3),(a1)		;first segment
		bra	.quit
		
.skip		addq.l	#1,d0
		tst.l	(a4)
		bne	.looparray
		bra	.loopstseg

.quit		movem.l	(a7)+,d2-d3/a3-a4
		rts

;---------------------------------------------------------------------------*

	IFGE KICKVERSION-36
st_dloadseg	dc.l	0
st_dnewloadseg	dc.l	0
st_dunloadseg	dc.l	0
	ENDC
st_sem		ds.b	stss_SIZEOF
st_semname	dc.b	"SegTracker",0
	EVEN

;---------------------------------------------------------------------------*

