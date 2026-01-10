	IFND	LIBRARIES_STC_I
LIBRARIES_STC_I SET 1
**
**	$Filename: libraries/stc.i $
**	$Revision: 2.0 $
**	$Date: 93/12/28 $
**
**	stc.library definitions
**
**	(C) Copyright 1991-1993 Jouni 'Mr.Spiv' Korhonen
**	    All Rights Reserved
**

    IFND    EXEC_TYPES_I
    include 'exec/types.i'
    ENDC
    IFND    EXEC_LISTS_I
    include 'exec/lists.i'
    ENDC
    IFND    EXEC_LIBRARIES_I
    include 'exec/libraries.i'
    ENDC
    IFND    EXEC_INTERRUPTS_I
    include 'exec/interrupts.i'
    ENDC
    IFND    DOS_DOS_I
    include 'dos/dos.i'
    ENDC
    IFND    UTILITY_TAGITEM_I
    include 'utility/tagitem.i'
    ENDC


STCNAME        MACRO
               dc.b    'stc.library',0
               ENDM

STCVERSION     equ	3

******************************************************************************
*                                                                            *
* Preferences                                                                *
*                                                                            *
******************************************************************************

S403           equ      0
S404           equ      1

phNOHEADER     equ      1
phNOMATCH      equ      2
phUNIT         equ      3
phNAME         equ      4
phREHEADER     equ      5
phOVERLAY      equ      6
phBREAK        equ      7
phHUNKID       equ      8

seEXEC         equ      0
sePEXEC        equ      1
seLIBRARY      equ      2
seOVERLAY      equ      3
seABSOLUTE     equ      4

isEXEC         equ      $80000000  * Note! Only bits 31-24 include info
isDATA         equ      $40000000  * about the file.
isS403         equ      $20000000  * Bits 23-0 amount of bytes from the
isS404         equ      $10000000  * beginning of the file to decrunch
isNPEXEC       equ      $01000000  * header.
isLPEXEC       equ      $02000000
isNABS         equ      $03000000
isPABS         equ      $04000000
isKABS         equ      $05000000
isSKIPMASK     equ      $00ffffff
isINFOMASK     equ      $ff000000
isERRORMASK    equ      isSKIPMASK

stc_TagBase    equ      TAG_USER

** CrunchDataTags() tags **
cdDESTINATION   equ      stc_TagBase+$01
cdLENGTH        equ      stc_TagBase+$02
cdABORTFLAGS    equ      stc_TagBase+$03
cdOUTPUTFLAGS   equ      stc_TagBase+$04
cdXPOS          equ      stc_TagBase+$05
cdYPOS          equ      stc_TagBase+$06
cdRASTPORT      equ      stc_TagBase+$07
cdMSGPORT       equ      stc_TagBase+$08
cdDISTBITS      equ      stc_TagBase+$09
cdBUFFER        equ      stc_TagBase+$0a

cdOutPutNIL     equ      0
cdOutPutCLI     equ      1
cdOutPutWIN     equ      2
cdAbortNIL      equ      0
cdAbortGADGET   equ      1
cdAbortCTRLC    equ      2
cdDist1K        equ      10
cdDist2K        equ      11
cdDist4K        equ      12
cdDist8K        equ      13
cdDist16K       equ      14

** SaveExecTags() tags **
sxSAVETYPE      equ      stc_TagBase+$0b
sxFILENAME      equ      stc_TagBase+$0c
sxDATABUFFER    equ      stc_TagBase+$0d
sxLENGTH        equ      stc_TagBase+$0e
sxLOAD          equ      stc_TagBase+$0f
sxJUMP          equ      stc_TagBase+$10
sxDECR          equ      stc_TagBase+$11
sxUSP           equ      stc_TagBase+$12
sxSSP           equ      stc_TagBase+$13
sxSR            equ      stc_TagBase+$14

sxData          equ      0
sxPExec         equ      1
sxPExecLib      equ      2
sxAbsNormal     equ      3
sxAbsPlain      equ      4
sxAbsKillSystem equ      5


** For old library version. DON'T use in new code!! **
        STRUCTURE stcCrunchInfo,0
          ULONG   stcci_FileLength
          APTR    stcci_Buffer
          APTR    stcci_FileBuffer
          APTR    stcci_MsgPort			* If NULL no event check
          APTR    stcci_RastPort
          APTR    stcci_GfxBase			* If NULL no crunchcounter
          WORD    stcci_XPos
          WORD    stcci_YPos
        LABEL     stcci_SIZEOF

******************************************************************************
*                                                                            *
* Library Base                                                               *
*                                                                            *
******************************************************************************

        STRUCTURE StcBase,LIB_SIZE
          APTR    stcb_DosBase
          BPTR    stcb_SegList
          ULONG   stcb_Flags
          ULONG   stcb_Pad

* For compatibily.. Don't read or write..                                 *
          APTR    stcb_FirstBuffer
          ULONG   stcb_BufferSize

* For compatibily.. Don't read or write..                                 *
          ULONG   stcb_SecurityLen

* This error message is GLOBAL data and includes more specific info about * 
* the last error. In most cases it's the result of IoErr() function.      * 
* Note! If there are several tasks using stc.library the value might not  * 
* contain correct value.. (this is my fault.. due the lack of references  * 
* when I started programming stc.library!)                                *
          ULONG   stcb_ErrorMsg
          APTR    stcb_GfxBase
          APTR    stcb_IntuiBase
        LABEL     stcb_SIZEOF



    ENDC	; LIBRARIES_STC_I
