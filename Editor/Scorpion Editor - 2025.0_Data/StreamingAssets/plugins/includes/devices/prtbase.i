   IFND  DEVICES_PRTBASE_I
DEVICES_PRTBASE_I EQU	1
**
**	$VER: prtbase.i 1.9 (26.7.90)
**	Includes Release 40.13
**
**	printer.device base structure definitions
**
**	(C) Copyright 1987-1993 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

   IFND  EXEC_TYPES_I
   INCLUDE  "exec/types.i"
   ENDC
   IFND  EXEC_NODES_I
   INCLUDE  "exec/nodes.i"
   ENDC
   IFND  EXEC_LISTS_I
   INCLUDE  "exec/lists.i"
   ENDC
   IFND  EXEC_PORTS_I
   INCLUDE  "exec/ports.i"
   ENDC
   IFND  EXEC_LIBRARIES_I
   INCLUDE  "exec/libraries.i"
   ENDC
   IFND  EXEC_TASKS_I
   INCLUDE  "exec/tasks.i"
   ENDC

   IFND  DEVICES_PARALLEL_I
   INCLUDE  "devices/parallel.i"
   ENDC
   IFND  DEVICES_SERIAL_I
   INCLUDE  "devices/serial.i"
   ENDC
   IFND  DEVICES_TIMER_I
   INCLUDE  "devices/timer.i"
   ENDC
   IFND  LIBRARIES_DOSEXTENS_I
   INCLUDE  "libraries/dosextens.i"
   ENDC
   IFND  INTUITION_INTUITION_I
   INCLUDE  "intuition/intuition.i"
   ENDC


 STRUCTURE  DeviceData,LIB_SIZE
    APTR dd_Segment	      ; A0 when initialized
    APTR dd_ExecBase	      ; A6 for exec
    APTR dd_CmdVectors	      ; command table for device commands
    APTR dd_CmdBytes	      ; bytes describing which command queue
    UWORD   dd_NumCommands    ; the number of commands supported
    LABEL   dd_SIZEOF


*------
*------ device driver private variables ------------------------------
*------
du_Flags EQU   LN_PRI	      ; various unit flags

;------ IO_FLAGS
    BITDEF  IO,QUEUED,4       ; command is queued to be performed
    BITDEF  IO,CURRENT,5      ; command is being performed
    BITDEF  IO,SERVICING,6    ; command is being actively performed
    BITDEF  IO,DONE,7	      ; command is done

;------ du_Flags
    BITDEF  DU,STOPPED,0      ; commands are not to be performed


*------ Constants ----------------------------------------------------
P_PRIORITY	EQU	0
P_OLDSTKSIZE	EQU	$0800	; stack size for child task (OBSOLETE)
P_STKSIZE	EQU	$1000	; stack size for child task
P_BUFSIZE	EQU	256	; size of internal buffers for text i/o
P_SAFESIZE	EQU	128	; safety margin for text output buffer

*------ pd_Flags ------
   BITDEF   P,IOR0,0	      ; IOR0 is in use
   BITDEF   P,IOR1,1	      ; IOR1 is in use
   BITDEF   P,EXPUNGED,7      ; device to be expunged when all closed

 STRUCTURE  PrinterData,dd_SIZEOF
    STRUCT  pd_Unit,MP_SIZE   ; the one and only unit
    BPTR pd_PrinterSegment    ; the printer specific segment
    UWORD   pd_PrinterType    ; the segment printer type
    APTR pd_SegmentData       ; the segment data structure
    APTR pd_PrintBuf	      ; the raster print buffer
    APTR pd_PWrite	      ; the parallel write function
    APTR pd_PBothReady	      ; the parallel write function's done

    IFGT IOEXTPar_SIZE-IOEXTSER_SIZE
    STRUCT  pd_IOR0,IOEXTPar_SIZE   ; port I/O request 0
    STRUCT  pd_IOR1,IOEXTPar_SIZE   ;   and 1 for double buffering
    ENDC

    IFLE IOEXTPar_SIZE-IOEXTSER_SIZE
    STRUCT  pd_IOR0,IOEXTSER_SIZE   ; port I/O request 0
    STRUCT  pd_IOR1,IOEXTSER_SIZE   ;   and 1 for double buffering
    ENDC

    STRUCT  pd_TIOR,IOTV_SIZE       ; timer I/O request
    STRUCT  pd_IORPort,MP_SIZE      ;   and message reply port
    STRUCT  pd_TC,TC_SIZE           ; write task
    STRUCT  pd_OldStk,P_OLDSTKSIZE  ;   and stack space (OBSOLETE)
    UBYTE   pd_Flags                ; device flags
    UBYTE   pd_pad		    ; padding
    STRUCT  pd_Preferences,pf_SIZEOF ; the latest preferences
    UBYTE   pd_PWaitEnabled         ; wait function switch
;   /* new fields for V2.0 */
    UBYTE   pd_Pad1		    ; padding
    STRUCT  pd_Stk,P_STKSIZE	    ; stack space
    LABEL   pd_SIZEOF               ; warning! this may be odd

    BITDEF  PPC,GFX,0		;graphics (bit position)
    BITDEF  PPC,COLOR,1		;color (bit position)

PPC_BWALPHA	EQU	$00	;black&white alphanumerics
PPC_BWGFX	EQU	$01	;black&white graphics
PPC_COLORALPHA	EQU	$02	;color alphanumerics
PPC_COLORGFX	EQU	$03	;color graphics

PCC_BW		EQU	1	;black&white only
PCC_YMC		EQU	2	;yellow/magenta/cyan only
PCC_YMC_BW	EQU	3	;yellow/magenta/cyan or black&white
PCC_YMCB	EQU	4	;yellow/magenta/cyan/black

PCC_4COLOR	EQU	$4	;a flag for YMCB and BGRW
PCC_ADDITIVE	EQU	$8	;not ymcb but blue/green/red/white
PCC_WB		EQU	$9	;black&white only, 0 == BLACK
PCC_BGR		EQU	$a	;blue/green/red
PCC_BGR_WB	EQU	$b	;blue/green/red or black&white
PCC_BGRW	EQU	$c	;blue/green/red/white
;	The picture must be scanned once for each color component, as the
;	printer can only define one color at a time.  ie. If 'PCC_YMC' then
;	first pass sends all 'Y' info to printer, second pass sends all 'M'
;	info, and third pass sends all C info to printer.  The CalComp
;	PlotMaster is an example of this type of printer.
PCC_MULTI_PASS	EQU	$10	;see explanation above

 STRUCTURE  PrinterExtendedData,0
    APTR    ped_PrinterName   ; printer name, null terminated
    APTR    ped_Init          ; called after LoadSeg
    APTR    ped_Expunge       ; called before UnLoadSeg
    APTR    ped_Open          ; called at OpenDevice
    APTR    ped_Close         ; called at CloseDevice
    UBYTE   ped_PrinterClass  ; printer class
    UBYTE   ped_ColorClass    ; color class
    UBYTE   ped_MaxColumns    ; number of print columns available
    UBYTE   ped_NumCharSets   ; number of character sets
    UWORD   ped_NumRows       ; number of 'pins' in print head
    ULONG   ped_MaxXDots      ; number of dots maximum in a raster dump
    ULONG   ped_MaxYDots      ; number of dots maximum in a raster dump
    UWORD   ped_XDotsInch     ; horizontal dot density
    UWORD   ped_YDotsInch     ; vertical dot density
    APTR    ped_Commands      ; printer text command table
    APTR    ped_DoSpecial     ; special command handler
    APTR    ped_Render        ; raster render function
    LONG    ped_TimeoutSecs   ; good write timeout
;------	the following only exists if the segment version is 33 or greater
	APTR     ped_8BitChars	;conversion strings for the extended font
	LONG     ped_PrintMode	;set if text printed, otherwise 0
;------	the following only exists if the segment version is 34 or greater
	APTR	ped_ConvFunv	; ptr to conversion function for all chars
	LABEL   ped_SIZEOF

 STRUCTURE  PrinterSegment,0
    ULONG   ps_NextSegment    ; (actually a BPTR)
    ULONG   ps_runAlert       ; MOVEQ #0,D0 : RTS
    UWORD   ps_Version        ; segment version
    UWORD   ps_Revision       ; segment revision
    LABEL   ps_PED            ; printer extended data

   ENDC
