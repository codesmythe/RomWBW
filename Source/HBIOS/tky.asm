;__________________________________________________________________________________________________
;
;	KEYBOARD DRIVER FOR S100 T35 Z80 FPGA
;
;__________________________________________________________________________________________________
;
; TODO:
;
TKY_IO_DATA	.EQU	$03
TKY_IO_STAT	.EQU	$02
;
;__________________________________________________________________________________________________
; DATA CONSTANTS
;__________________________________________________________________________________________________
;
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE HEADER
;--------------------------------------------------------------------------------------------------
;
ORG_TKY	.EQU	$
;
	.DW	SIZ_TKY			; MODULE SIZE
	.DW	TKY_INITPHASE		; ADR OF INIT PHASE HANDLER
;
TKY_INITPHASE:
	; INIT PHASE HANDLER, A=PHASE
	;CP	HB_PHASE_PREINIT	; PREINIT PHASE?
	;JP	Z,TKY_PREINIT		; DO PREINIT
	CP	HB_PHASE_INIT		; INIT PHASE?
	JP	Z,TKY_INIT		; DO INIT
	RET				; DONE
;
		DEVECHO	"TKY:"
		DEVECHO " IO="
		DEVECHO TKY_IO_DATA
		DEVECHO	"\n"
;
;__________________________________________________________________________________________________
; KEYBOARD INITIALIZATION
;__________________________________________________________________________________________________
;
TKY_INIT:
	LD	IY,TKY_IDAT		; POINTER TO INSTANCE DATA
;
	CALL	NEWLINE			; FORMATTING
	PRTS("TKY: IO=0x$")		; DISPLAY
	LD	A,TKY_IO_DATA		; PORT SETTING
	CALL	PRTHEXBYTE
;
	; CURENTLY JUST ASSUMES DEVICE IS PRESENT
	PUSH	IY			; DE := INSTANCE DATA PTR
	POP	DE			; ... FROM CALLER'S IY
	CALL	KBD_ADDENT		; ADD ENTRY, A := UNIT ASSIGNED
	LD	(IY+CFG_UNIT),A		; RECORD HBIOS UNIT NUMBER ASSIGNED
;	
	XOR	A			; SIGNAL SUCCESS
	RET
;
; INSTANCE DATA
;
TKY_IDAT:
	.DW	TKY_FNTBL		; DRIVER FUNCTION TABLE ADDRESS				
	.DB	'K'			; DRIVER TYPE						
	.DB	$FF			; HBIOS UNIT NUMBER (FILLED DYNAMICALLY, $FF=NONE)	
	.DB	0			; DRIVER UNIT NUMBER (ONLY ONE UNIT POSSIBLE)		
	.DB	ERR_NONE		; DEVICE STATUS (HBIOS STATUS)				
	.DW	TKY_STR_TAG		; DRIVER TAG STRING PTR					

TKY_STR_TAG	.TEXT	"TKY$"
;
; DRIVER FUNCTION TABLE
;
TKY_FNTBL:
	.DW	TKY_STAT
	.DW	TKY_FLUSH
	.DW	TKY_READ
	.DW	TKY_DEVICE
#IF (($ - TKY_FNTBL) != (KBD_FNCNT * 2))
	.ECHO	"*** INVALID TKY FUNCTION TABLE ***\n"
	!!!!!
#ENDIF
;
;__________________________________________________________________________________________________
; KEYBOARD STATUS
;__________________________________________________________________________________________________
;
TKY_STAT:
	IN	A,(TKY_IO_STAT)		; READ STATUS PORT
	AND	$01			; MASK FOR CHAR WAITING
	JP	Z,CIO_IDLE		; RET VIA IDLE PROCESSING IF NO KEY
	RET				; ELSE RETURN WITH A=1 AND NZ
;
;__________________________________________________________________________________________________
; KEYBOARD FLUSH
;__________________________________________________________________________________________________
;
TKY_FLUSH:
	; IGNORED FOR NOW
	XOR	A
	RET
;
;__________________________________________________________________________________________________
; KEYBOARD READ
;
;   RETURNS ASCII VALUE IN E.  T35 FPGA CODE JUST RETURNS ASCII VALUE, SO THERE WILL BE NO
;   SPECIAL VALUES LIKE PGUP, ARROWS, FUNCTION KEYS, ETC.
;__________________________________________________________________________________________________
;
TKY_READ:
	CALL	TKY_STAT		; KEY READY?
	JR	Z,TKY_READ		; NOT READY, KEEP TRYING
	IN	A,(TKY_IO_DATA)		; GET THE KEY
	LD	E,A			; MOVE TO E
	LD	C,0			; NO VALUE HERE
	LD	D,0			; NO VALUE HERE
	XOR	A			; SIGNAL SUCCESS
	RET				; AND DONE
;
;__________________________________________________________________________________________________
; KEYBOARD DEVICE
;__________________________________________________________________________________________________
;
TKY_DEVICE:
	LD	D,KBDDEV_TKY		; DEVICE TYPE
	LD	E,(IY+CFG_DEVNUM)	; PHYSICAL UNIT
	XOR	A			; SIGNAL SUCCESS
	RET
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE TRAILER
;--------------------------------------------------------------------------------------------------
;
END_TKY	.EQU	$
SIZ_TKY	.EQU	END_TKY - ORG_TKY
;	
	MEMECHO	"TKY occupies "
	MEMECHO	SIZ_TKY
	MEMECHO	" bytes.\n"
