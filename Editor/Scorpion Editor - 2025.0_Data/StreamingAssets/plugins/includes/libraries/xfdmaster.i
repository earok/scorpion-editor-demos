	IFND	LIBRARIES_XFDMASTER_I
LIBRARIES_XFDMASTER_I	SET	1

**
**	$VER: xfdmaster.i 38.3 (28.2.98)
**
**	Copyright © 1994-98 by Georg Hörmann
**	All Rights Reserved
**

	IFND EXEC_LIBRARIES_I
	include "exec/libraries.i"
	ENDC

;======================================================================
; Library Base
;======================================================================

    STRUCTURE	xfdMasterBase,LIB_SIZE
	ULONG	xfdm_SegList		; PRIVATE
	APTR	xfdm_DosBase		; may be used for I/O etc.
	APTR	xfdm_FirstSlave		; list of available slaves
	APTR	xfdm_FirstForeman	; PRIVATE
	ULONG	xfdm_MinBufferSize	; (V36) min. bufsize for xfdRecogBuffer()
	ULONG	xfdm_MinLinkerSize	; (V36) min. bufsize for xfdRecogLinker()
	APTR	xfdm_ExecBase		; (V38.2) cached for fast access
	LABEL	xfdMasterBase_SIZE

XFDM_VERSION	EQU	38	;for OpenLibrary()

XFDM_NAME	MACRO
		dc.b	"xfdmaster.library",0
		ENDM

;======================================================================
; Object Types (V36)
;======================================================================

XFDOBJ_BUFFERINFO	EQU	1	; xfdBufferInfo structure
XFDOBJ_SEGMENTINFO	EQU	2	; xfdSegmentInfo structure
XFDOBJ_LINKERINFO	EQU	3	; xfdLinkerInfo structure
XFDOBJ_SCANNODE		EQU	4	; (V37) xfdScanNode structure
XFDOBJ_SCANHOOK		EQU	5	; (V37) xfdScanHook structure
XFDOBJ_MAX		EQU	5	; PRIVATE

;======================================================================
; Buffer Info
;======================================================================

    STRUCTURE	xfdBufferInfo,0
	APTR	xfdbi_SourceBuffer	; pointer to source buffer
	ULONG	xfdbi_SourceBufLen	; length of source buffer
	APTR	xfdbi_Slave		; PRIVATE
	APTR	xfdbi_PackerName	; name of recognized packer
	UWORD	xfdbi_PackerFlags	; flags for recognized packer
	LABEL	xfdbi_MaxSpecialLen	; max. length of special info (eg. password)
	UWORD	xfdbi_Error		; error return code
	APTR	xfdbi_TargetBuffer	; pointer to target buffer
	ULONG	xfdbi_TargetBufMemType	; memtype of target buffer
	ULONG	xfdbi_TargetBufLen	; full length of buffer
	ULONG	xfdbi_TargetBufSaveLen	; used length of buffer
	ULONG	xfdbi_DecrAddress	; address to load decrunched file
	ULONG	xfdbi_JmpAddress	; address to jump in file
	APTR	xfdbi_Special		; special decrunch info (eg. password)
	UWORD	xfdbi_Flags		; (V37) flags to influence recog/decr
	UWORD	xfdbi_Reserved0		; (V38) PRIVATE
	ULONG	xfdbi_MinTargetLen	; (V38) required length of target buffer
	ULONG	xfdbi_FinalTargetLen	; (V38) final length of decrunched file
	APTR	xfdbi_UserTargetBuf	; (V38) target buffer allocated by user
	ULONG	xfdbi_UserTargetBufLen	; (V38) target buffer length
	LABEL	xfdBufferInfo_SIZE

;======================================================================
; Segment Info
;======================================================================

    STRUCTURE	xfdSegmentInfo,0
	ULONG	xfdsi_SegList		; value received by LoadSeg()
	APTR	xfdsi_Slave		; PRIVATE
	APTR	xfdsi_PackerName	; name of recognized packer
	UWORD	xfdsi_PackerFlags	; flags for recognized packer
	LABEL	xfdsi_MaxSpecialLen	; max. length of special info (eg. password)
	UWORD	xfdsi_Error		; error return code
	APTR	xfdsi_Special		; special decrunch info (eg. password)
	UWORD	xfdsi_RelMode		; (V34) relocation mode
	UWORD	xfdsi_Flags		; (V37) flags to influence recog/decr
	LABEL	xfdSegmentInfo_SIZE

;======================================================================
; Linker Info (V36)
;======================================================================

    STRUCTURE	xfdLinkerInfo,0
	APTR	xfdli_Buffer		; pointer to buffer
	ULONG	xfdli_BufLen		; length of buffer
	APTR	xfdli_LinkerName	; name of recognized linker
	FPTR	xfdli_Unlink		; PRIVATE
	UWORD	xfdli_Reserved		; set to NULL
	UWORD	xfdli_Error		; error return code
	ULONG	xfdli_Hunk1		; PRIVATE
	ULONG	xfdli_Hunk2		; PRIVATE
	ULONG	xfdli_Amount1		; PRIVATE
	ULONG	xfdli_Amount2		; PRIVATE
	APTR	xfdli_Save1		; pointer to first unlinked file
	APTR	xfdli_Save2		; pointer to second unlinked file
	ULONG	xfdli_SaveLen1		; length of first unlinked file
	ULONG	xfdli_SaveLen2		; length of second unlinked file
	LABEL	xfdLinkerInfo_SIZE

;======================================================================
; Scan Node (V37)
;======================================================================

    STRUCTURE	xfdScanNode,0
	APTR	xfdsn_Next		; pointer to next xfdScanNode structure (or NULL)
	APTR	xfdsn_Save		; pointer to data
	ULONG	xfdsn_SaveLen		; length of data
	APTR	xfdsn_PackerName	; name of recognized packer
	UWORD	xfdsn_PackerFlags	; flags for recognized packer
	LABEL	xfdScanNode_SIZE

;======================================================================
; Scan Hook (V37)
;======================================================================

    STRUCTURE	xfdScanHook,0
	APTR	xfdsh_Entry		; entrypoint of hook code
	APTR	xfdsh_Data		; private data of hook
	ULONG	xfdsh_ToDo		; bytes still to scan (READ ONLY)
	ULONG	xfdsh_ScanNode		; found data right now (or NULL) (READ ONLY)
	LABEL	xfdScanHook_SIZE

;======================================================================
; Error Codes
;======================================================================

XFDERR_OK		EQU	$0000	; no error

XFDERR_NOMEMORY		EQU	$0001	; error allocating memory
XFDERR_NOSLAVE		EQU	$0002	; no slave entry in info structure
XFDERR_NOTSUPPORTED	EQU	$0003	; slave doesn't support called function
XFDERR_UNKNOWN		EQU	$0004	; unknown file
XFDERR_NOSOURCE		EQU	$0005	; no sourcebuffer/seglist specified
XFDERR_WRONGPASSWORD	EQU	$0006	; wrong password for decrunching
XFDERR_BADHUNK		EQU	$0007	; bad hunk structure
XFDERR_CORRUPTEDDATA	EQU	$0008	; crunched data is corrupted
XFDERR_MISSINGRESOURCE	EQU	$0009	; (V34) missing external resource (eg. libs)
XFDERR_WRONGKEY		EQU	$000a	; (V35) wrong 16/32 bit key
XFDERR_BETTERCPU	EQU	$000b	; (V37) better CPU required
XFDERR_HOOKBREAK	EQU	$000c	; (V37) hook caused break
XFDERR_DOSERROR		EQU	$000d	; (V37) dos error
XFDERR_NOTARGET		EQU	$000e	; (V38) no user target given
XFDERR_TARGETTOOSMALL	EQU	$000f	; (V38) user target is too small
XFDERR_TARGETNOTSUPPORTED EQU	$0010	; (V38) user target not supported

XFDERR_UNDEFINEDHUNK	EQU	$1000	; (V34) undefined hunk type
XFDERR_NOHUNKHEADER	EQU	$1001	; (V34) file is not executable
XFDERR_BADEXTTYPE	EQU	$1002	; (V34) bad hunk_ext type
XFDERR_BUFFERTRUNCATED	EQU	$1003	; (V34) unexpected end of file
XFDERR_WRONGHUNKAMOUNT	EQU	$1004	; (V34) wrong amount of hunks
XFDERR_NOOVERLAYS	EQU	$1005	; (V36) overlays not allowed

XFDERR_UNSUPPORTEDHUNK	EQU	$2000	; (V34) hunk type not supported
XFDERR_BADRELMODE	EQU	$2001	; (V34) unknown XFDREL_#? mode

;======================================================================
; Relocation modes (V34)
;======================================================================

XFDREL_DEFAULT		EQU	$0000	; use memory types given by hunk_header
XFDREL_FORCECHIP	EQU	$0001	; force all hunks to chip ram
XFDREL_FORCEFAST	EQU	$0002	; force all hunks to fast ram

;======================================================================
; Values for xfd??_PackerFlags
;======================================================================

	BITDEF	XFDPF,RELOC,0		; relocatible file packer
	BITDEF	XFDPF,ADDR,1		; absolute address file packer
	BITDEF	XFDPF,DATA,2		; data file packer

	BITDEF	XFDPF,PASSWORD,4	; packer requires password
	BITDEF	XFDPF,RELMODE,5		; (V34) decruncher supports xfdsi_RelMode
	BITDEF	XFDPF,KEY16,6		; (V35) packer requires 16 bit key
	BITDEF	XFDPF,KEY32,7		; (V35) packer requires 32 bit key

	BITDEF	XFDPF,RECOGLEN,8	; (V38) slave recognizes target lengths
	BITDEF	XFDPF,USERTARGET,9	; (V38) slave supports user target buffer

	BITDEF	XFDPF,EXTERN,15		; (V37) PRIVATE

;======================================================================
; Values for xfd??_Flags (V37)
;======================================================================

	BITDEF	XFDF,RECOGEXTERN,0	; xfdRecog#?() uses external slaves
	BITDEF	XFDF,RECOGTARGETLEN,1	; (V38) xfdRecogBuffer() uses only slaves
					; that recognize target lengths
	BITDEF	XFDF,RECOGUSERTARGET,2	; (V38) xfdRecogBuffer() uses only slaves
					; that support user targets
	BITDEF	XFDF,USERTARGET,3	; (V38) xfdbi_DecrunchBuffer() decrunchs
					; to given xfdbi_UserTarget

;======================================================================
; Flags for xfdTestHunkStructureFlags() (V36)
;======================================================================

	BITDEF	XFDTH,NOOVERLAYS,0	; abort on hunk_overlay ($3f5)

;======================================================================
; Flags for xfdStripHunks() (V36)
;======================================================================

	BITDEF	XFDSH,NAME,0		; strip hunk_name ($3e8)
	BITDEF	XFDSH,SYMBOL,1		; strip hunk_symbol ($3f0)
	BITDEF	XFDSH,DEBUG,2		; strip hunk_debug ($3f1)

;======================================================================
; Flags for xfdScanData() (V37)
;======================================================================

	BITDEF	XFDSD,USEEXTERN,0	; use external slaves for scanning
	BITDEF	XFDSD,SCANODD,1		; scan at odd addresses too

;======================================================================
; Foreman
;======================================================================

    STRUCTURE	xfdForeman,0
	STRUCT	xfdf_Security,4		; moveq #-1,d0 : rts
	STRUCT	xfdf_ID,4		; set to XFDF_ID
	UWORD	xfdf_Version		; set to XFDF_VERSION
	UWORD	xfdf_Reserved		; not used by now, set to NULL
	ULONG	xfdf_Next		; PRIVATE
	ULONG	xfdf_SegList		; PRIVATE
	APTR	xfdf_FirstSlave		; first slave (see below)
	LABEL	xfdForeman_SIZE

XFDF_ID		EQU	(("X"<<24)!("F"<<16)!("D"<<8)!("F"))
XFDF_VERSION	EQU	1

;======================================================================
; Slave
;======================================================================

    STRUCTURE	xfdSlave,0
	APTR	xfds_Next		; next slave (or NULL)
	UWORD	xfds_Version		; set to XFDS_VERSION
	UWORD	xfds_MasterVersion	; minimum XFDM_VERSION required
	APTR	xfds_PackerName		; NULL-terminated name of packer
	UWORD	xfds_PackerFlags	; flags for packer
	UWORD	xfds_MaxSpecialLen	; max. length of special info (eg. password)
	FPTR	xfds_RecogBuffer	; buffer recognition code (or NULL)
	FPTR	xfds_DecrunchBuffer	; buffer decrunch code (or NULL)
	LABEL	xfds_ScanData		; (V37) XFDPFB_DATA: scan code (or NULL)
	FPTR	xfds_RecogSegment	; segment recognition code (or NULL)
	LABEL	xfds_VerifyData		; (V37) XFDPFB_DATA: verify code (or NULL)
	FPTR	xfds_DecrunchSegment	; segment decrunch code (or NULL)
	UWORD	xfds_SlaveID		; (V36) slave ID (only internal slaves)
	UWORD	xfds_ReplaceID		; (V36) ID of slave to be replaced
	ULONG	xfds_MinBufferSize	; (V36) min. bufsize for RecogBufferXYZ()
	LABEL	xfdSlave_SIZE

XFDS_VERSION	EQU	2

;======================================================================
; Additional Recognition Results (V38)
;======================================================================

    STRUCTURE	xfdRecogResult,0
	ULONG	xfdrr_MinTargetLen	; min. required length of target buffer
	ULONG	xfdrr_FinalTargetLen	; final length of decrunched file
	LABEL	xfdRecogResult_SIZE

;======================================================================
; Internal Slave IDs (V36)
;======================================================================

XFDID_BASE	EQU	$8000

XFDID_PowerPacker23		EQU	(XFDID_BASE+$0001)
XFDID_PowerPacker30		EQU	(XFDID_BASE+$0003)
XFDID_PowerPacker30Enc		EQU	(XFDID_BASE+$0005)
XFDID_PowerPacker30Ovl		EQU	(XFDID_BASE+$0007)
XFDID_PowerPacker40		EQU	(XFDID_BASE+$0009)
XFDID_PowerPacker40Lib		EQU	(XFDID_BASE+$000a)
XFDID_PowerPacker40Enc		EQU	(XFDID_BASE+$000b)
XFDID_PowerPacker40LibEnc	EQU	(XFDID_BASE+$000c)
XFDID_PowerPacker40Ovl		EQU	(XFDID_BASE+$000d)
XFDID_PowerPacker40LibOvl	EQU	(XFDID_BASE+$000e)
XFDID_PowerPackerData		EQU	(XFDID_BASE+$000f)
XFDID_PowerPackerDataEnc	EQU	(XFDID_BASE+$0010)
XFDID_ByteKiller13		EQU	(XFDID_BASE+$0011)
XFDID_ByteKiller20		EQU	(XFDID_BASE+$0012)
XFDID_ByteKiller30		EQU	(XFDID_BASE+$0013)
XFDID_ByteKillerPro10		EQU	(XFDID_BASE+$0014)
XFDID_ByteKillerPro10Pro	EQU	(XFDID_BASE+$0015)
XFDID_DragPack10		EQU	(XFDID_BASE+$0016)
XFDID_TNMCruncher11		EQU	(XFDID_BASE+$0017)
XFDID_HQCCruncher20		EQU	(XFDID_BASE+$0018)
XFDID_RSICruncher14		EQU	(XFDID_BASE+$0019)
XFDID_ANCCruncher		EQU	(XFDID_BASE+$001a)
XFDID_ReloKit10			EQU	(XFDID_BASE+$001b)
XFDID_HighPressureCruncher	EQU	(XFDID_BASE+$001c)
XFDID_STPackedSong		EQU	(XFDID_BASE+$001d)
XFDID_TSKCruncher		EQU	(XFDID_BASE+$001e)
XFDID_LightPack15		EQU	(XFDID_BASE+$001f)
XFDID_CrunchMaster10		EQU	(XFDID_BASE+$0020)
XFDID_HQCCompressor100		EQU	(XFDID_BASE+$0021)
XFDID_FlashSpeed10		EQU	(XFDID_BASE+$0022)
XFDID_CrunchManiaData		EQU	(XFDID_BASE+$0023)
XFDID_CrunchManiaDataEnc	EQU	(XFDID_BASE+$0024)
XFDID_CrunchManiaLib		EQU	(XFDID_BASE+$0025)
XFDID_CrunchManiaNormal		EQU	(XFDID_BASE+$0026)
XFDID_CrunchManiaSimple		EQU	(XFDID_BASE+$0027)
XFDID_CrunchManiaAddr		EQU	(XFDID_BASE+$0028)
XFDID_DefJamCruncher32		EQU	(XFDID_BASE+$0029)
XFDID_DefJamCruncher32Pro	EQU	(XFDID_BASE+$002a)
XFDID_TetraPack102		EQU	(XFDID_BASE+$002b)
XFDID_TetraPack11		EQU	(XFDID_BASE+$002c)
XFDID_TetraPack21		EQU	(XFDID_BASE+$002d)
XFDID_TetraPack21Pro		EQU	(XFDID_BASE+$002e)
XFDID_TetraPack22		EQU	(XFDID_BASE+$002f)
XFDID_TetraPack22Pro		EQU	(XFDID_BASE+$0030)
XFDID_DoubleAction10		EQU	(XFDID_BASE+$0031)
XFDID_DragPack252Data		EQU	(XFDID_BASE+$0032)
XFDID_DragPack252		EQU	(XFDID_BASE+$0033)
XFDID_FCG10			EQU	(XFDID_BASE+$0034)
XFDID_Freeway07			EQU	(XFDID_BASE+$0035)
XFDID_IAMPacker10ATM5Data	EQU	(XFDID_BASE+$0036)
XFDID_IAMPacker10ATM5		EQU	(XFDID_BASE+$0037)
XFDID_IAMPacker10ICEData	EQU	(XFDID_BASE+$0038)
XFDID_IAMPacker10ICE		EQU	(XFDID_BASE+$0039)
XFDID_Imploder			EQU	(XFDID_BASE+$003a)
XFDID_ImploderLib		EQU	(XFDID_BASE+$003b)
XFDID_ImploderOvl		EQU	(XFDID_BASE+$003c)
XFDID_FileImploder		EQU	(XFDID_BASE+$003d)
XFDID_MasterCruncher30Addr	EQU	(XFDID_BASE+$003f)
XFDID_MasterCruncher30		EQU	(XFDID_BASE+$0040)
XFDID_MaxPacker12		EQU	(XFDID_BASE+$0041)
XFDID_PackIt10Data		EQU	(XFDID_BASE+$0042)
XFDID_PackIt10			EQU	(XFDID_BASE+$0043)
XFDID_PMCNormal			EQU	(XFDID_BASE+$0044)
XFDID_PMCSample			EQU	(XFDID_BASE+$0045)
XFDID_XPKPacked			EQU	(XFDID_BASE+$0046)
XFDID_XPKCrypted		EQU	(XFDID_BASE+$0047)
XFDID_TimeCruncher17		EQU	(XFDID_BASE+$0048)
XFDID_TFACruncher154		EQU	(XFDID_BASE+$0049)
XFDID_TurtleSmasher13		EQU	(XFDID_BASE+$004a)
XFDID_MegaCruncher10		EQU	(XFDID_BASE+$004b)
XFDID_MegaCruncher12		EQU	(XFDID_BASE+$004c)
XFDID_ProPack			EQU	(XFDID_BASE+$004d)
XFDID_ProPackData		EQU	(XFDID_BASE+$004e)
XFDID_ProPackDataKey		EQU	(XFDID_BASE+$004f)
XFDID_STCruncher10		EQU	(XFDID_BASE+$0050)
XFDID_STCruncher10Data		EQU	(XFDID_BASE+$0051)
XFDID_SpikeCruncher		EQU	(XFDID_BASE+$0052)
XFDID_SyncroPacker46		EQU	(XFDID_BASE+$0053)
XFDID_SyncroPacker46Pro		EQU	(XFDID_BASE+$0054)
XFDID_TitanicsCruncher11	EQU	(XFDID_BASE+$0055)
XFDID_TitanicsCruncher12	EQU	(XFDID_BASE+$0056)
XFDID_TryItCruncher101		EQU	(XFDID_BASE+$0057)
XFDID_TurboSqueezer61		EQU	(XFDID_BASE+$0058)
XFDID_TurboSqueezer80		EQU	(XFDID_BASE+$0059)
XFDID_TurtleSmasher200		EQU	(XFDID_BASE+$005a)
XFDID_TurtleSmasher200Data	EQU	(XFDID_BASE+$005b)
XFDID_StoneCracker270		EQU	(XFDID_BASE+$005c)
XFDID_StoneCracker270Pro	EQU	(XFDID_BASE+$005d)
XFDID_StoneCracker292		EQU	(XFDID_BASE+$005e)
XFDID_StoneCracker299		EQU	(XFDID_BASE+$005f)
XFDID_StoneCracker299d		EQU	(XFDID_BASE+$0060)
XFDID_StoneCracker300		EQU	(XFDID_BASE+$0061)
XFDID_StoneCracker300Data	EQU	(XFDID_BASE+$0062)
XFDID_StoneCracker310		EQU	(XFDID_BASE+$0063)
XFDID_StoneCracker310Data	EQU	(XFDID_BASE+$0064)
XFDID_StoneCracker311		EQU	(XFDID_BASE+$0065)
XFDID_StoneCracker400		EQU	(XFDID_BASE+$0066)
XFDID_StoneCracker400Data	EQU	(XFDID_BASE+$0067)
XFDID_StoneCracker401		EQU	(XFDID_BASE+$0068)
XFDID_StoneCracker401Data	EQU	(XFDID_BASE+$0069)
XFDID_StoneCracker401Addr	EQU	(XFDID_BASE+$006a)
XFDID_StoneCracker401BetaAddr	EQU	(XFDID_BASE+$006b)
XFDID_StoneCracker403Data	EQU	(XFDID_BASE+$006c)
XFDID_StoneCracker404		EQU	(XFDID_BASE+$006d)
XFDID_StoneCracker404Data	EQU	(XFDID_BASE+$006e)
XFDID_StoneCracker404Addr	EQU	(XFDID_BASE+$006f)
XFDID_ChryseisCruncher09	EQU	(XFDID_BASE+$0070)
XFDID_QuickPowerPacker10	EQU	(XFDID_BASE+$0071)
XFDID_GNUPacker12		EQU	(XFDID_BASE+$0072)
XFDID_GNUPacker12Seg		EQU	(XFDID_BASE+$0073)
XFDID_GNUPacker12Data		EQU	(XFDID_BASE+$0074)
XFDID_TrashEliminator10		EQU	(XFDID_BASE+$0075)
XFDID_MasterCruncher30Data	EQU	(XFDID_BASE+$0076)
XFDID_SuperCruncher27		EQU	(XFDID_BASE+$0077)
XFDID_UltimatePacker11		EQU	(XFDID_BASE+$0078)
XFDID_ProPackOld		EQU	(XFDID_BASE+$0079)
XFDID_SACFPQCruncher		EQU	(XFDID_BASE+$007a)
XFDID_PowerPackerPatch10	EQU	(XFDID_BASE+$007b)
XFDID_CFP135			EQU	(XFDID_BASE+$007c)
XFDID_BOND			EQU	(XFDID_BASE+$007d)
XFDID_PowerPackerLoadSeg	EQU	(XFDID_BASE+$007e)
XFDID_StoneCracker299b		EQU	(XFDID_BASE+$007f)
XFDID_CrunchyDat10		EQU	(XFDID_BASE+$0080)
XFDID_PowerPacker20		EQU	(XFDID_BASE+$0081)
XFDID_StoneCracker403		EQU	(XFDID_BASE+$0082)
XFDID_PKProtector200		EQU	(XFDID_BASE+$0083)

	ENDC	; LIBRARIES_XFDMASTER_I
