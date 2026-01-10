;Scorpion custom boot sector (earok)
;Sources and inspirations:
;https://github.com/earok/close-and-run-amiga68k/blob/master/addchip.bootblock.s (Ross)
;https://github.com/cahirwpz/demoscene/blob/master/bootloader.asm (Krystian Bacławski)
;https://aminet.net/package/game/jump/SolidGold_Source (PHX)
;https://github.com/emmanuel-marty/unzx0_68000/blob/main/unzx0_68000.S
;https://github.com/keirf/Amiga-Stuff/blob/master/base/bootblock.S
;Cheers Alpine9000

;Todo - killcache from ;https://eab.abime.net/showthread.php?t=96233 ?

;LVOs etc
io_Device	EQU	$14
Supervisor  EQU -30
AllocMem	EQU	-198
AllocAbs	EQU	-204
FreeMem		EQU -210
DoIO		EQU	-456
CloseDevice EQU -450

MEMF_ANY    EQU $0
MEMF_CHIP   EQU $2
MEMF_CLEAR  EQU $10000

MEMF_CLEAR_CHIP	EQU $10002	
MEMF_CLEAR_ANY	EQU $10000
MEMF_CLEAR_FAST EQU $10004

IO_COMMAND  EQU 28
IO_LENGTH   EQU 36
IO_DATA     EQU 40
IO_OFFSET   EQU 44

CMD_READ	EQU 2
TD_MOTOR	EQU 9

NEGSIZE     EQU 16
POSSIZE     EQU 18

boot
            dc.b "DOS",0    ;Header
            dc.l 0          ;Checksum at 4, to be calculated at data compile time
            dc.b "SED1"     ;Placeholder at 8 for disc ID

            bra.w start     ;Force to W so size is consistent
            ;Disk specific variables starting from 16
execstart   dc.w 0 ;16 Pointer to Scorpion ZX0 crunced executable in sectors
execsize    dc.w 0 ;18 Size of Scorpion Executable in sectors (including redirects patched on the end)
origsize	dc.l 0 ;20 The original size of the Scorpion Executable before ZX0 crunching
redirstart  dc.l 0 ;24 Pointer to the redirect list (uncrunched after the ZX0 data)
redircount	dc.w 0 ;28 Number of relocations as word
datastart   dc.w 0 ;30 Pointer to Scorpion data lookup table in sectors
datasize    dc.w 0 ;32 Size of Scorpion data lookup header in sectors
savestart	dc.w 0 ;34 The start of the part of the disk where we can write user data (may be after the last sector if there's no space for saving)

start
; a6 = SysBase
; a1 = trackdisk IOStdReq
			;Put some useful stuff on the stack so we can grab it in blitz
            movem.l a1-a6/d1-d7,-(sp)  ; preserve registers			
			
            moveq.l #9,d7                    ; Shift left by nine to change sector size to full file size

            ;Put the offset into the IO structure
            moveq.l #0,d0
            move.w execstart,d0
            asl.l d7,d0
        	move.l	d0,IO_OFFSET(a1)

            ;Put the size into the IO structure
            moveq.l #0,d0
            move.w execsize,d0
            asl.l d7,d0                     ; Exec size is now full required memory size
            move.l d0,IO_LENGTH(a1)         ; Put this length into the IO request structure

            move.l a1,a5                    ; a5 now contains trackdisk.device IO request

            ;Allocate the memory now. d0 already contains the amount we want
			move.l  d0,d7 ;Remember how much we allocate here so we can deallocate later
            move.l	#MEMF_CLEAR_CHIP,d1
        	jsr	AllocMem(a6)

            ;Chip memory is now allocated. Do the executable read
        	move.l	a5,a1                   ;Move IO request into AI
        	move.l	d0,IO_DATA(a1)          ;d0 contains the pointer from allocmem
			move.l  d0,a5					;Don't forget where the memory is stored
			
        	jsr	DoIO(a6)
					
            ;It's all loaded, we need to decrunch to any available mem
			move.l  origsize,d0
            move.l	#MEMF_CLEAR_ANY,d1
        	jsr	AllocMem(a6)			
			
			move.l  a5,a0 ;The source is the chip ram that we allocated earlier 
			move.l  d0,a1 ;The target is the any ram that we just allocated
            movem.l a0-a6/d0-d7,-(sp)  ; preserve registers			
			jsr zx0_decompress
            movem.l (sp)+,a0-a6/d0-d7  ; preserve registers
			
			
			;Now we can fix the redirects
			move.l  a1,a5  ;We keep the target as a5 from now on			
			move.l  a1,d1  ;Also need the address in data register for add operation	
			move.l  a0,a1  ;Put the source chip into a1 so we can free immediately after the redirect
            add.l   redirstart,a0 ;a0 now contains the redirect offset
			moveq	#0,d0
			move.w	redircount,d0
					
			blt GameReady ;Skip if no redirects

redirectLoop
            move.l a5,a2 ;Reset redirect base
            add.l (a0)+,a2 ;Increase redirect base by the offset of the redirect
            add.l d1,(a2) ;Patch the redirect by the start of allocated memory
            dbra.w d0,redirectLoop ;Repeat X times

GameReady			
			;Ditch the chipram we used to load the crunched game
			move.l d7,d0
        	jsr	FreeMem(a6)

			;The game should be fully patched within any ram 
			Move.l a5,a0
			MoveQ #0,d0
            movem.l (sp)+,a1-a6/d1-d7  ; preserve registers								

			RTS

zx0_decompress:
               movem.l a2/d2,-(sp)  ; preserve registers
               moveq #-128,d1       ; initialize empty bit queue
                                    ; plus bit to roll into carry
               moveq #-1,d2         ; initialize rep-offset to 1

.literals:     bsr.s .get_elias     ; read number of literals to copy
               subq.l #1,d0         ; dbf will loop until d0 is -1, not 0
.copy_lits:    move.b (a0)+,(a1)+   ; copy literal byte
               dbf d0,.copy_lits    ; loop for all literal bytes
               
               add.b d1,d1          ; read 'match or rep-match' bit
               bcs.s .get_offset    ; if 1: read offset, if 0: rep-match

.rep_match:    bsr.s .get_elias     ; read match length (starts at 1)
.do_copy:      subq.l #1,d0         ; dbf will loop until d0 is -1, not 0
.do_copy_offs: move.l a1,a2         ; calculate backreference address
               add.l d2,a2          ; (dest + negative match offset)               
.copy_match:   move.b (a2)+,(a1)+   ; copy matched byte
               dbf d0,.copy_match   ; loop for all matched bytes

               add.b d1,d1          ; read 'literal or match' bit
               bcc.s .literals      ; if 0: go copy literals

.get_offset:   moveq #-2,d0         ; initialize value to $fe
               bsr.s .elias_loop    ; read high byte of match offset
               addq.b #1,d0         ; obtain negative offset high byte
               beq.s .done          ; exit if EOD marker
               move.w d0,d2         ; transfer negative high byte into d2
               lsl.w #8,d2          ; shift it to make room for low byte

               moveq #1,d0          ; initialize length value to 1
               move.b (a0)+,d2      ; read low byte of offset + 1 bit of len
               asr.l #1,d2          ; shift len bit into carry/offset in place
               bcs.s .do_copy_offs  ; if len bit is set, no need for more
               bsr.s .elias_bt      ; read rest of elias-encoded match length
               bra.s .do_copy_offs  ; go copy match

.get_elias:    moveq #1,d0          ; initialize value to 1
.elias_loop:   add.b d1,d1          ; shift bit queue, high bit into carry
               bne.s .got_bit       ; queue not empty, bits remain
               move.b (a0)+,d1      ; read 8 new bits
               addx.b d1,d1         ; shift bit queue, high bit into carry
                                    ; and shift 1 from carry into bit queue

.got_bit:      bcs.s .got_elias     ; done if control bit is 1
.elias_bt:     add.b d1,d1          ; read data bit
               addx.l d0,d0         ; shift data bit into value in d0
               bra.s .elias_loop    ; keep reading

.done:         movem.l (sp)+,a2/d2  ; restore preserved registers
.got_elias:    rts

;Fill to 1024 bytes
            cnop 0,1024

