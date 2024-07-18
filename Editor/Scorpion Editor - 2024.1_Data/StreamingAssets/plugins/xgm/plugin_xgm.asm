;Mega Drive XGM sound driver (part of SGDK by Stef), based on the NextBasic implementation of XGM, thanks to Luiz Mendoza and Matheus Castellar.
Z80_DRV_COMMAND equ $A00100 ;Driver command
Z80_DRV_PARAMS equ $A00104 ;Driver parameters base

FunctionTable
;XGM Init - Load Z80 driver and initialize system. 
;JSR 0(plugin_XGM)
;A0.l = Location of Z80 driver
;D0.l = Size of Z80 Driver
;D1.l = Location of Null sample (must be 256 byte aligned)
    bra.w XGM_init

;XGM VInt - Updates the driver, run during VINT
;JSR 4(plugin_XGM)
;D0.b = Number of frames to increase (typically 1, may be more or less to handle difference between PAL/NTSC etc)
    bra.w XGM_vint

;XGM IsPlayingMusic - Simply returns if music is being played or not
;JSR 8(plugin_XGM)
;Returns IsPlayingMusic in D0
    bra.w XGM_IsPlayingMusic

;XGM StartPlayMusic - Starts playing a track
;A0 = Memory space for sample table
;A1 = Track location
;A2 = Location of NULL sample
;JSR 12(plugin_xgm)
    bra.w XGM_StartPlayMusic

;XGM ResumePlayMusic
;JSR 16(plugin_xgm)
    bra.w XGM_ResumePlayMusic

;XGM StopPlayMusic
;D0 = Memory address of stop_bin (empty music file)
;JSR 20(plugin_xgm)
    bra.w XGM_StopPlayMusic

;XGM IsPlayingPCM
;D0 = Channel to test.
;Returns result in D0
;JSR 24(plugin_xgm)
    bra.w XGM_IsPlayingPCM

;XGM Play pcm sample
;A1 = Sample (must be 256 byte aligned)
;A2 = Pointer to longword variable to contain the sample number (initial value of this variable should be $40)
;D1 = Length
;D2 = Channel
;JSR 28(plugin_xgm)
    bra.w XGM_PlayPCM

;XGM Enable DMA protection. This is automatically disabled by the XGM_VINT
;JSR 32(plugin_XGM)
    bra.w XGM_EnableProtection

XGM_init
    move.w  #$100,($A11100)         ; Send the Z80 a bus request.
    move.w  #$100,($A11200)

@z80_wait1:
    move.w  ($A11100),D2            ; read Z80 halted state
    btst    #8,D2                   ; Z80 halted ?
    bne     @z80_wait1              ; not yet, wait..
     
    MOVE.L  #$A00000,A1
     
@loop:
    MOVE.B  (A0)+,(A1)+
    DBRA    D0,@loop               ; load driver
    
    move.l  #$A01C00,a0             ; point to Z80 sample id table (first entry = silent sample)

    lsr.l   #8,d1
    move.b  d1,(a0)+                ; sample address
    lsr.l   #8,d1
    move.b  d1,(a0)+
    move.b  #$01,(a0)+              ; sample length
    move.b  #$00,(a0) 
     
    move.w  #$000,($A11200)         ; Start Z80 Reset
    move.w  #$000,($A11100)         ; release the Z80 bus

    move.l  #$A00102,a0             ; point to status

@test_ready:
    move.w  #100,d0                 ; 

@wait:
    DBRA    D0,@wait               ; wait a bit
    
    move.w  #$100,($A11100)         ; Send the Z80 a bus request
    move.w  #$100,($A11200)         ; End Z80 Reset

@z80_wait2:
    move.w  ($A11100),D0            ; read Z80 halted state
    btst    #8,D0                   ; Z80 halted ?
    bne     @z80_wait2              ; not yet, wait...

    move.b (a0),d0
    move.w  #$000,($A11100)         ; release the Z80 bus
    
    btst   #7,d0                    ; not yet ready
    beq    @test_ready   
    rts


XGM_vint
@z80_wait1_XGM_vint:
    move.w  #$100,($A11100)         ; Send the Z80 a bus request.
    move.w  ($A11100),d1            ; read Z80 halted state
    btst    #8,d1                   ; Z80 halted ?
    bne     @z80_wait1_XGM_vint              ; not yet, wait..

    ;Disable DMA protection automatically
    move.b  #0,(Z80_DRV_PARAMS+$B)

    tst.b ($A00112);Make sure Z80 is not accessing $A00104 + $0E 
    beq XGM_vint_ready

    ; wait a bit (about 80 cycles) before we try again
    move.w  #$000,($A11100)         ; release the Z80 bus
    movem.l d0-d3,-(sp)
    movem.l (sp)+,d0-d3
    bra XGM_vint

XGM_vint_ready

    ;Move the frame number
    move.b D0,($A00113) ;$A00104 + $0F

    move.w  #$000,($A11100)         ; release the Z80 bus
    rts


XGM_IsPlayingMusic
    move.w  #$100,($A11100)         ; Send the Z80 a bus request
    move.w  #$100,($A11200)

@XGM_IsPlayingMusic_z80_wait1:
    move.w  ($A11100),D0            ; read Z80 halted state
    btst    #8,D0                   ; Z80 halted ?
    bne     @XGM_IsPlayingMusic_z80_wait1              ; not yet, wait..

    move.b  ($A00102),d0            ; get channel playing status
    andi.l  #$40,d0                 ; keep play XGM bit only    
    move.w  #$000,($A11100)         ; release the Z80 bus
    rts


XGM_StartPlayMusic
    move.w  #$100,($A11100)         ; Send the Z80 a bus request
    move.w  #$100,($A11200)
    
@XGM_StartPlayMusic_z80_wait1:
    move.w  ($A11100),D0            ; read Z80 halted state
    btst    #8,D0                   ; Z80 halted ?
    bne     @z80_wait1              ; not yet, wait..
    moveq   #0,d0
     
@XGM_Playmusic_Loop:                              ; prepare sample id table
    move.w  d0,d1
    add.w   d1,d1   
    add.w   d1,d1
    moveq   #0,d2   
    move.w  0(a1,d1.w),d2           ; get sample addr in song bank table
    rol.w   #8,d2                   ; revert endianess

    cmp.w   #$FFFF,d2               ; is null sample ?
    bne     @not_null
    
    move.l  A2,d2
    jmp     @addr_done
    
@not_null:
    addq.w  #1,d2                   ; add offset
    lsl.l   #8,d2                   ; pass to 24 bits
    add.l   a1,d2                   ; transform to absolute address

@addr_done
    lsr.l   #8,d2                   ; get high byte
    move.b  d2,0(a0,d1.w)
    lsr.w   #8,d2                   ; get low byte
    move.b  d2,1(a0,d1.w)
    move.w  2(a1,d1.w),2(a0,d1.w)   ; copy sample length

    addq.w  #1,d0
    cmp.w   #$3F,d0
    bne     @XGM_Playmusic_Loop

    move.l  #$A01C04,a2             ; destination of sample id table
    lsl.w   #2,d0                   ; set size in bytes
    subq.w  #1,d0
     
@sampleIdLoop:
    move.b (a0)+,(a2)+
    dbra   d0,@sampleIdLoop         ; load sample id table

    move.l  a1,d0                   ; d0 = song address
    add.l   #$100,d0                ; bypass sample id table

    moveq   #0,d2
    move.w  $FC(a1),d2              ; get sample data size
    rol.w   #8,d2                   ; revert endianess
    lsl.l   #8,d2                   ; pass to 24 bits

    add.l   d2,d0                   ; bypass samples data
    addq.l  #4,d0                   ; bypass music data size field
    
    move.l  #Z80_DRV_PARAMS,a2             ; XGM base parameters address

    move.b  d0,0(a2)                ; low byte
    lsr.l   #8,d0
    move.b  d0,1(a2)                ; med low byte
    lsr.l   #8,d0
    move.b  d0,2(a2)                ; med high byte
    lsr.l   #8,d0
    move.b  d0,3(a2)                ; high byte
    
    or.b    #$40,(Z80_DRV_COMMAND)          ; send play XGM command

    move.w  #$000,($A11100)         ; release the Z80 bus    
    rts


XGM_ResumePlayMusic
    move.w  #$100,($A11100)         ; Send the Z80 a bus request
    move.w  #$100,($A11200)

@XGM_ResumePlayMusic_z80_wait1:
    move.w  ($A11100),D0            ; read Z80 halted state
    btst    #8,D0                   ; Z80 halted ?
    bne     @XGM_ResumePlayMusic_z80_wait1              ; not yet, wait..
    
    or.b    #$20,(Z80_DRV_COMMAND)          ; send resume play command

    move.w  #$000,($A11100)         ; release the Z80 bus
    rts



XGM_StopPlayMusic
    move.w  #$100,($A11100)         ; Send the Z80 a bus request
    move.w  #$100,($A11200)

@XGM_StopPlayMusic_z80_wait1:
    move.w  ($A11100),d1            ; read Z80 halted state
    btst    #8,d1                   ; Z80 halted ?
    bne     @XGM_StopPlayMusic_z80_wait1              ; not yet, wait..

; Redundant - instead of stopping, we now play a silent file instead   
;    or.b    #$10,(Z80_DRV_COMMAND)          ; send stop play command

    move.l  #Z80_DRV_PARAMS,a2             ; XGM base parameters address

    move.b  d0,0(a2)                ; low byte
    lsr.l   #8,d0
    move.b  d0,1(a2)                ; med low byte
    lsr.l   #8,d0
    move.b  d0,2(a2)                ; med high byte
    lsr.l   #8,d0
    move.b  d0,3(a2)                ; high byte

    and.b    #$f,(Z80_DRV_COMMAND)          ; we want to clear out any resume, stop etc commands
    or.b    #$40,(Z80_DRV_COMMAND)          ; send play XGM command

    move.w  #$000,($A11100)         ; release the Z80 bus
    rts


XGM_IsPlayingPCM
    move.w  #$100,($A11100)         ; Send the Z80 a bus request
    move.w  #$100,($A11200)

@XGM_IsPlayingPCM_z80_wait1:
    move.w  ($A11100),d1            ; read Z80 halted state
    btst    #8,d1                   ; Z80 halted ?
    bne     @XGM_IsPlayingPCM_z80_wait1              ; not yet, wait..

    and.b   ($A00102),d2            ; get channel playing status
    moveq   #0,d7
    move.b  d2,d0                   ; store in d0
    
    move.w  #$000,($A11100)         ; release the Z80 bus
    rts


XGM_PlayPCM
    move.w  #$100,($A11100)         ; Send the Z80 a bus request
    move.w  #$100,($A11200)
    
@XGM_PlayPCM_z80_wait1:
    move.w  ($A11100),D0            ; read Z80 halted state
    btst    #8,D0                   ; Z80 halted ?
    bne     @XGM_PlayPCM_z80_wait1              ; not yet, wait..

    move.l  (a2),d0
    lsl.l   #2,d0
    lea     $A01C00,a0
    adda.l  d0,a0                   ; a0 point on id table entry
    
    move.l  a1,d0                   ; d0 = sample address
    
    lsr.l   #8,d0                   ; get sample address (high byte)
    move.b  d0,(a0)+
    lsr.w   #8,d0                   ; get sample address (low byte)
    move.b  d0,(a0)+
;    lsr.l   #8,d1                   ; get sample length (high byte) <- Address already divided by 256 at compile time
    move.b  d1,(a0)+
    lsr.w   #8,d1                   ; get sample length (low byte)
    move.b  d1,(a0)+
    
    move.l  d2,d0
    and.l   #3,d0                   ; d0 = channel number
    
    lea     Z80_DRV_COMMAND,a0
    moveq   #1,d1    
    lsl.l   d0,d1                   ; d1 = channel shift command
    or.b    d1,(a0)                 ; set PCM play command
    
    lea     $A00108,a0   
    add.l   d0,d0
    adda.l  d0,a0                   ; a0 point on channel info

    move.l  d2,d0
;    lsr.l   #4,d0
    and.l   #$C,d0                  ; d0 = priority
    
    move.b  d0,(a0)+                ; set priority
    
    move.l  (a2),d0       ; d0 = PCM id

    move.b  d0,(a0)                 ; set PCM id

    addq.l  #1,d0  
    and.l   #$FF,d0                
    or.l   #$40,d0                  ; id < 0x40 are reserved for music
    move.l  d0,(a2)       ; pass to next id

    move.w  #$000,($A11100)         ; release the Z80 bus
    rts

XGM_EnableProtection
    move.w  #$100,($A11100)         ; Send the Z80 a bus request.
    move.w  ($A11100),d1            ; read Z80 halted state
    btst    #8,d1                   ; Z80 halted ?
    bne     XGM_EnableProtection              ; not yet, wait..
    move.b  #1,(Z80_DRV_PARAMS+$B) ;Write the DMA protection byte
    move.w  #$000,($A11100)         ; release the Z80 bus
    rts
