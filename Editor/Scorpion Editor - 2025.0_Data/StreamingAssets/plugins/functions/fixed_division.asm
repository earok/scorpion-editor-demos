;D6 / D7 = D6 16.16
	move.l d5,-(a7)
	moveq #$2f,d5
	movem.l d2-d4,-(a7)
	moveq #0,d2
	tst.l d7
;   401e7bec 6700 0050                beq.w #$0050 == $401e7c3e  Div0 protection (handled in exception handling+guru)
	bpl.w d7Positive
	neg.l d7
	moveq #-1,d2
d7Positive
	tst.l d6
	bpl.w d6Positive
	neg.l d6
	not.w d2
d6Positive
	moveq #$00,d3
	moveq #$00,d4
loopStart
	lsl.l #$01,d4
	lsr.l #$01,d7
	beq.w zeroTest
	roxr.l #$01,d3
	dbf.w d5,loopStart
	bra.w loopEnd
zeroTest
	roxr.l #$01,d3
	beq.w test2
	cmp.l d3,d6
	bcs.w test2
	sub.l d3,d6
	addq.w #$01,d4
test2
	dbf.w d5,loopStart
loopEnd
	tst.w d2
	beq.w test3
	neg.l d4
test3
	move.l d4,d6
	movem.l (a7)+,d2-d4
	move.l (a7)+,d5
	;No rts as this is inlined