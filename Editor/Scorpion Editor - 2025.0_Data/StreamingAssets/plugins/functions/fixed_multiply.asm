;D6 * D7 = D6 16.16
	movem.l d2-d4,-(a7)
	moveq #$00,d2
	tst.l d6
	bpl.w positiveD6
	neg.l d6
	moveq.l #-1,d2
positiveD6
	tst.l d7
	bpl.w positiveD7
	neg.l d7
	not.w d2
positiveD7
	move.l d6,d3
	move.l d6,d4
	mulu.w d7,d6
	clr.w d6
	swap.w d6
	swap.w d3
	mulu.w d7,d3
	add.l d3,d6
	swap.w d7
	move.l d4,d3
	mulu.w d7,d4
	add.l d4,d6
	swap.w d3
	mulu.w d7,d3
	swap.w d3
	add.l d3,d6
	tst.w d2
	beq.w isPositive
	neg.l d6
isPositive
	movem.l (a7)+,d2-d4
	;no rts as this is inlined

