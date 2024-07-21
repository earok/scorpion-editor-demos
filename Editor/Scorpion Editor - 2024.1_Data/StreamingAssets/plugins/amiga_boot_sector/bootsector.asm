;THIS IS SEVERELY BROKEN/EXPERIMENTAL, DO NOT USE

;Scorpion custom boot sector (earok)
;Sources and inspirations:
;https://github.com/earok/close-and-run-amiga68k/blob/master/addchip.bootblock.s (Ross)
;https://github.com/cahirwpz/demoscene/blob/master/bootloader.asm (Krystian Bacławski)
;https://aminet.net/package/game/jump/SolidGold_Source (PHX)
;https://github.com/emmanuel-marty/unzx0_68000/blob/main/unzx0_68000.S

;Thx heaps Alpine9000

;TODO
;Should use ZX0 to crunch executable (keep redirects separate)

;LVOs etc
io_Device	EQU	$14
AllocMem	EQU	-198
AllocAbs	EQU	-204
DoIO		EQU	-456

MEMF_ANY    EQU 0
MEMF_CHIP   EQU 2

IO_LENGTH   EQU 36
IO_DATA     EQU 40
IO_OFFSET   EQU 44

BlitzPatch	EQU $2E	;We want to patch out the code after this with an RTS so Blitz doesn't proceed to open DOS etc

OpenLibrary     EQU -552

boot
            dc.b "DOS",0    ;Header
            dc.l 0          ;Checksum at 4, to be calculated at data compile time
            dc.b "SED1"     ;Placeholder at 8 for disc ID

            bra.w start     ;Force to W so size is consistent
            ;Disk specific variables starting from 16
execstart   dc.w 0 ;16 Pointer to Scorpion executable in sectors
execsize    dc.w 0 ;18 Size of Scorpion Executable in sectors (including redirects patched on the end)
redirstart  dc.l 0 ;20 Pointer to the redirect list (at the tail end of what's loaded with the executable)
redircount	dc.w 0 ;24 Number of relocations as word
datastart   dc.w 0 ;26 Pointer to Scorpion data lookup table in sectors
datasize    dc.w 0 ;28 Size of Scorpion data lookup header in sectors

start
; a6 = SysBase
; a1 = trackdisk IOStdReq

			;Patch out openlibrary
;			move.l #OldOpenLibraryLocation,A5
;			move.l OpenLibrary+2(A6),(A5)
;			move.l #OpenLibraryPatch,A5			
;			move.l A5,OpenLibrary+2(A6)


            moveq.l #9,D7                    ; Shift left by nine to change sector size to full file size

            ;Put the offset into the IO structure
            moveq.l #0,D0
            move.w execstart,D0
            asl.l D7,d0
        	move.l	d0,IO_OFFSET(A1)

            ;Put the size into the IO structure
            moveq.l #0,D0
            move.w execsize,D0
            asl.l D7,d0                     ; Exec size is now full required memory size
            move.l d0,IO_LENGTH(A1)         ; Put this length into the IO request structure

            move.l A1,a5                    ; A5 now contains trackdisk.device IO request

            ;Allocate the memory now. D0 already contains the amount we want
            move.l	#MEMF_CHIP,d1
        	jsr	AllocMem(a6)

            ;Chip memory is now allocated. Do the executable read
        	move.l	a5,a1                   ;Move IO request into AI
        	move.l	d0,IO_DATA(a1)          ;D0 contains the pointer from allocmem
			move.l  d0,A5					;Don't forget where the memory is stored
			
        	jsr	DoIO(a6)



            ;It's all loaded, we need to patch now
			move.l  A5,A0
			move.l  A5,D1 ;Also need the address in data register for add operation
            add.l   redirstart,a0 ;A0 contains the redirect offset

            ;Todo - decrunch to FAST RAM			
			move.w	redircount,D0
		
			
			blt GameReady ;Skip if no redirects



redirectLoop
            move.l A5,a1 ;Reset redirect base
			

			
            add.l (a0)+,a1 ;Increase redirect base by the offset of the redirect
            add.l d1,(a1) ;Patch the redirect by the start of allocated memory
            dbra.w d0,redirectLoop ;Repeat X times

GameReady			
			;The game should be fully patched within chipram  
;			bra GameReady infinite loop for debugging
			
			move.l A5,A4
			move.l 2(A4),A4 ;Get the location of the Blitz Basic initialisation code
			;Patch out the initialisation code after the memory has been initialised 
			;So blitz doesn't do automated calls to OpenLibrary etc
			move.w #$4e75,BlitzPatch(A4) 
            JMP (A5)

;Blitz attempts to open dos.library even if no dos calls are actually used, simply pretend it worked
;OpenLibraryPatch	
;			cmp.l #$646F732E,(A1) ;"dos."
;			bne OldOpenLibrary
			
;If we get to here, just pretend it worked
;			MoveQ #1,D0
;			rts

;If we get to here, it's not dos.library	
;OldOpenLibrary
;			dc.w $4EF9 ;JMP
;OldOpenLibraryLocation
;			dc.l 0			
			

;Fill to 1024 bytes
            cnop 0,1024

