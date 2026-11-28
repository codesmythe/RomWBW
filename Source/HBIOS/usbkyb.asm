;
;==================================================================================================
; CH376 NATIVE USB KEYBOARD DRIVER
;==================================================================================================
;
; STANDALONE KEYBOARD DRIVER.  REGISTERS ITSELF IN THE HBIOS KBD
; UNIT TABLE (KBD_ADDENT) DURING THE INIT PHASE IF A USB KEYBOARD IS
; FOUND.  REQUIRES THE CH376 NATIVE USB DRIVER (USB.ASM), WHICH MUST BE
; INITIALIZED (DEVICES ENUMERATED) BEFORE THIS MODULE.
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE HEADER
;--------------------------------------------------------------------------------------------------
;
ORG_USB_KYB	.EQU	$
;
	.DW	SIZ_USB_KYB		; MODULE SIZE
	.DW	USB_KYB_INITPHASE	; ADR OF INIT PHASE HANDLER
;
USB_KYB_INITPHASE:
	; INIT PHASE HANDLER, A=PHASE
	;CP	HB_PHASE_PREINIT	; PREINIT PHASE?
	;JP	Z,USB_KYB_PREINIT	; DO PREINIT
	CP	HB_PHASE_INIT		; INIT PHASE?
	JP	Z,USB_KYB_INIT	; DO INIT
	RET				; DONE
;
		DEVECHO	"USB_KYB: ENABLED\n"
;
#IF (!USBENABLE)
	.ECHO	"*** USB_KYB: USB_KYB REQUIRES USBENABLE ***\n"
	!!!	; FORCE AN ASSEMBLY ERROR
#ENDIF
;
#DEFINE DEFM	.DB
#DEFINE DEFB	.DB
#DEFINE DEFW	.DW
;
#IF (!USB_EZ80)
  #IF (SYSTIM == TM_NONE)
	.ECHO	"*** ERROR: USB_KYB REQUIRES SYSTEM TIMER -- NONE CONFIGURED!!!\n"
	!!!	; FORCE AN ASSEMBLY ERROR
  #ENDIF
#ENDIF
;
#include "./ch376-native/keyboard.s"
;
;__________________________________________________________________________________________________
; KEYBOARD INITIALIZATION
;__________________________________________________________________________________________________
;
USB_KYB_INIT:
	LD	IY,UKY_IDAT		; POINTER TO INSTANCE DATA
	PUSH	IY
	CALL	_keyboard_init		; A := 1 IF KEYBOARD FOUND, 0 IF NOT
	POP	IY
	OR	A			; SET FLAGS
	RET	Z			; NOT FOUND, DO NOT REGISTER
;
#IF (!USB_EZ80)
	; INSTALL TIMER TICK HANDLER TO SCAN KEYBOARD
	LD	HL,(VEC_TICK+1)		; SAVE EXISTING TICK VECTOR
	LD	(VEC_USB_KYB_TICK+1),HL	; ... AS OUR CHAIN TARGET
	LD	HL,USB_KYB_TICK		; INSTALL OUR HANDLER
	LD	(VEC_TICK+1),HL		; ... (SINGLE INSTRUCTION, INT SAFE)
#ENDIF
;
	; REGISTER AS KEYBOARD DEVICE
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
UKY_IDAT:
	.DW	UKY_FNTBL		; DRIVER FUNCTION TABLE ADDRESS
	.DB	'K'			; DRIVER TYPE
	.DB	$FF			; HBIOS UNIT NUMBER (FILLED DYNAMICALLY, $FF=NONE)
	.DB	0			; DRIVER UNIT NUMBER (ONLY ONE UNIT POSSIBLE)
	.DB	ERR_NONE		; DEVICE STATUS (HBIOS STATUS)
	.DW	UKY_STR_TAG		; DRIVER TAG STRING PTR
;
UKY_STR_TAG	.TEXT	"USB_KYB$"
;
; DRIVER FUNCTION TABLE
;
UKY_FNTBL:
	.DW	UKY_STAT
	.DW	UKY_FLUSH
	.DW	UKY_READ
	.DW	UKY_DEVICE
#IF (($ - UKY_FNTBL) != (KBD_FNCNT * 2))
	.ECHO	"*** INVALID UKY FUNCTION TABLE ***\n"
	!!!!!
#ENDIF
;
#IF (!USB_EZ80)
;__________________________________________________________________________________________________
; TIMER TICK HANDLER
;__________________________________________________________________________________________________
;
; COUNT FOR INTERRUPT HANDLER TO TRIGGER KEYBOARD SCANNER (EG: SCAN KEYBOARD ONLY EVERY 2ND INTERRUPT (2/60))
SCAN_INT_PERIOD:	.EQU	2
;
	.FILL	128,0			; KEYBOARD INTERRUPT STACK (NEEDS ~52 BYTES)
UKY_INTSTK:
;
USB_KYB_TICK:
	LD	A,SCAN_INT_PERIOD	; SCAN THE KEYBOARD EVERY 'SCAN_INT_PERIOD' INTERRUPTS.
UKY_SCNCNT	.EQU	$ - 1
	DEC	A
	LD	(UKY_SCNCNT),A
	JP	NZ,HB_TICK
;
	LD	A,SCAN_INT_PERIOD
	LD	(UKY_SCNCNT),A
;
	; WE NEED A BIGGER STACK
	LD	(UKY_INT_SP),SP		; SAVE ORIGINAL STACK FRAME
	LD	SP,UKY_INTSTK		; USE DEDICATED INT STACK FRAME
;
	CALL	_usb_kyb_tick
;
	LD	SP,$FFFF		; RESTORE ORIGINAL STACK FRAME
UKY_INT_SP	.EQU	$ - 2
;
VEC_USB_KYB_TICK:
	JP	HB_TICK			; CHAIN TO PREVIOUS TICK HANDLER
;
#ENDIF
;
;__________________________________________________________________________________________________
; KEYBOARD STATUS (BF_KBDSTAT)
;__________________________________________________________________________________________________
;
;   RETURNS A = NUMBER OF KEYCODES PENDING (0 = NONE).
;   DOES IDLE PROCESSING WHEN NOTHING IS PENDING.
;
UKY_STAT:
	CALL	_usb_kyb_status		; A := KEYCODES PENDING
	OR	A			; SET FLAGS
	JP	Z,CIO_IDLE		; RET VIA IDLE PROCESSING IF NO KEY
	RET
;
;__________________________________________________________________________________________________
; KEYBOARD FLUSH (BF_KBDFLUSH)
;__________________________________________________________________________________________________
;
;   DISCARDS ALL PENDING KEYCODES.  RETURNS A = 0.
;
UKY_FLUSH	.EQU	_usb_kyb_flush
;
;__________________________________________________________________________________________________
; KEYBOARD READ (BF_KBDREAD)
;__________________________________________________________________________________________________
;
;   WAITS FOR AND RETURNS THE NEXT KEYCODE.
;   RETURNS A = 0, E = KEYCODE, C = 0 (NO SCANCODE), D = 0 (NO STATE)
;
;   NOTE: THE NATIVE BUFFER IS FILLED BY THE TIMER TICK HANDLER, SO THIS
;   WILL WAIT FOREVER IF CALLED WITH INTERRUPTS DISABLED.
;
UKY_READ:
	CALL	_usb_kyb_read		; H := 0 IF KEY, L := KEYCODE
	LD	A,H
	OR	A
	JR	NZ,UKY_READ		; NO KEY YET, LOOP
	LD	E,L			; KEYCODE TO E
	LD	C,A			; NO SCANCODE
	LD	D,A			; NO STATE BITS
	RET				; A = 0, SUCCESS
;
;__________________________________________________________________________________________________
; KEYBOARD DEVICE
;__________________________________________________________________________________________________
;
UKY_DEVICE:
	LD	D,KBDDEV_USBKYB		; DEVICE TYPE
	LD	E,(IY+CFG_DEVNUM)	; PHYSICAL UNIT
	XOR	A			; SIGNAL SUCCESS
	RET
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE TRAILER
;--------------------------------------------------------------------------------------------------
;
END_USB_KYB	.EQU	$
SIZ_USB_KYB	.EQU	END_USB_KYB - ORG_USB_KYB
;
	MEMECHO	"USB_KYB occupies "
	MEMECHO	SIZ_USB_KYB
	MEMECHO	" bytes.\n"
