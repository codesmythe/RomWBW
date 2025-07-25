;======================================================================
;	TMS9918, V9938/58 VDU DRIVER
;
; WRITTEN BY: DOUGLAS GOODALL
; UPDATED BY: WAYNE WARTHEN -- 4/7/2013
; UPDATED BY: DEAN NETHERTON -- 5/26/2021 - V9958 SUPPORT
; UPDATED BY: JOSE L. COLLADO -- 11/15/2023 - MEMORY MAP CHANGES
; UPDATED BY: DAN WERNER -- 2/11/2024 - DUODYNE SUPPORT
;======================================================================
;
; TODO:
;   - IMPLEMENT SET CURSOR STYLE (VDASCS) FUNCTION?
;   - IMPLEMENT ALTERNATE DISPLAY MODES?
;   - IMPLEMENT DYNAMIC READ/WRITE OF CHARACTER BITMAP DATA?
;
;======================================================================
; TMS DRIVER - CONSTANTS
;======================================================================
;
;
;
; 40 Column Video Memory Map
; -----------------------------------
;			Start	Length
; Pattern Table:	$0000	$0800	Font data (8 x 256)
; Unused:		$0800	$1000
; Sprite Patterns:	$1800	$0800
; Color Table:		$2000	$1800
; Name Table:		$3800	$0400	Display characters (40 x 25)
; Sprite Attributes:	$3B00	$0100
; Unused:		$3C00	$0400
;
; 80 Column Video Memory Map (MSX like)
; -------------------------------------
;			Start	Length
; Pattern Table:	$1000	$0800	Font data (8 x 256)
; Sprite Patterns:	$????	$????
; Color Table:		$????	$????
; Name Table:		$0000	$0800	Display characters (80 x 25)
; Sprite Attributes:	$????	$????
; Unused:		$????	$????
;
TMSCTRL1:       .EQU   1               ; CONTROL BITS
TMSINTEN:       .EQU   5               ; INTERRUPT ENABLE BIT
;
TMSKBD_NONE	.EQU	0
TMSKBD_KBD	.EQU	1
TMSKBD_PPK	.EQU	2
TMSKBD_MKY	.EQU	3
TMSKBD_NABU	.EQU	4
TMSKBD_USB	.EQU	5
;
TMSKBD		.EQU	TMSKBD_NONE	; ASSUME NONE
;
		DEVECHO	"TMS: MODE="
;
#IF (TMSMODE == TMSMODE_SCG)
TMS_DATREG	.EQU	$98		; READ/WRITE DATA
TMS_CMDREG	.EQU	$99		; READ STATUS / WRITE REG SEL
TMS_ACR		.EQU	$9C		; AUX CONTROL REGISTER
		DEVECHO	"SCG"
#ENDIF
;
#IF (TMSMODE == TMSMODE_N8)
TMS_DATREG	.EQU	$98		; READ/WRITE DATA
TMS_CMDREG	.EQU	$99		; READ STATUS / WRITE REG SEL
TMS_PPIA	.EQU	$84		; PPI PORT A
TMS_PPIB	.EQU	$85		; PPI PORT B
TMS_PPIC	.EQU	$86		; PPI PORT C
TMS_PPIX	.EQU	$87		; PPI CONTROL PORT
TMSKBD		.SET	TMSKBD_PPK	; PPK KEYBOARD
		DEVECHO	"N8"
#ENDIF
;
#IF (TMSMODE == TMSMODE_MSX)
TMS_DATREG	.EQU	$98		; READ/WRITE DATA
TMS_CMDREG	.EQU	$99		; READ STATUS / WRITE REG SEL
		DEVECHO	"MSX"
#ENDIF
;
#IF (TMSMODE == TMSMODE_MSXKBD)
TMS_DATREG	.EQU	$98		; READ/WRITE DATA
TMS_CMDREG	.EQU	$99		; READ STATUS / WRITE REG SEL
TMS_KBDDATA	.EQU	$60		; KBD CTLR DATA PORT
TMS_KBDST	.EQU	$64		; KBD CTLR STATUS/CMD PORT
TMSKBD		.SET	TMSKBD_KBD	; PS2 KEYBOARD
		DEVECHO	"MSXKBD"
#ENDIF
;
#IF (TMSMODE == TMSMODE_MSXMKY)
TMS_DATREG	.EQU	$98		; READ/WRITE DATA
TMS_CMDREG	.EQU	$99		; READ STATUS / WRITE REG SEL
TMSKBD		.SET	TMSKBD_MKY	; MSX KEYBOARD
		DEVECHO	"MSXMKY"
#ENDIF
;
#IF (TMSMODE == TMSMODE_MSXUKY)
TMS_DATREG	.EQU	$98		; READ/WRITE DATA
TMS_CMDREG	.EQU	$99		; READ STATUS / WRITE REG SEL
TMSKBD		.SET	TMSKBD_USB	; MSX KEYBOARD
		DEVECHO	"MSX-USB_KYB"
#ENDIF
;
#IF (TMSMODE == TMSMODE_MBC)
TMS_DATREG	.EQU	$98		; READ/WRITE DATA
TMS_CMDREG	.EQU	$99		; READ STATUS / WRITE REG SEL
TMS_ACR		.EQU	$9C		; AUX CONTROL REGISTER
TMS_KBDDATA	.EQU	$E2		; KBD CTLR DATA PORT
TMS_KBDST	.EQU	$E3		; KBD CTLR STATUS/CMD PORT
TMSKBD		.SET	TMSKBD_KBD	; PS2 KEYBOARD
		DEVECHO	"MBC"
#ENDIF
;
#IF (TMSMODE == TMSMODE_COLECO)
TMS_DATREG	.EQU	$BE		; READ/WRITE DATA
TMS_CMDREG	.EQU	$BF		; READ STATUS / WRITE REG SEL
		DEVECHO	"COLECO"
#ENDIF
;
#IF (TMSMODE == TMSMODE_DUO)
TMS_DATREG	.EQU	$A0		; READ/WRITE DATA
TMS_CMDREG	.EQU	$A1		; READ STATUS / WRITE REG SEL
TMS_ACR		.EQU	$A6		; AUX CONTROL REGISTER
TMS_KBDDATA	.EQU	$4C		; KBD CTLR DATA PORT
TMS_KBDST	.EQU	$4D		; KBD CTLR STATUS/CMD PORT
TMSKBD		.SET	TMSKBD_KBD	; PS2 KEYBOARD
		DEVECHO	"DUO"
#ENDIF
;
#IF (TMSMODE == TMSMODE_NABU)
TMS_DATREG	.EQU	$A0		; READ/WRITE DATA
TMS_CMDREG	.EQU	$A1		; READ STATUS / WRITE REG SEL
TMSKBD		.SET	TMSKBD_NABU	; NABU KEYBOARD
		DEVECHO	"NABU"
#ENDIF
;
		DEVECHO	", IO="
		DEVECHO	TMS_DATREG
;
TMS_ROWS	.EQU	24
;
#IF (TMS80COLS)
TMS_FNTVADDR	.EQU	$1000		; VRAM ADDRESS OF FONT DATA
TMS_FNTSIZE	.EQU	8*256		; ### JLC Mod for JBL compatibility ### = 8x8 Font 256 Chars
TMS_CHRVADDR	.EQU	$0000		; VRAM ADDRESS OF CHAR SCREEN DATA (NEW CONSTANT) = REG2 * $400
TMS_COLS	.EQU	80
#ELSE					; ALL OTHER MODES...
;TMS_FNTVADDR	.EQU	$0800		; VRAM ADDRESS OF FONT DATA
TMS_FNTVADDR	.EQU	$0000		; VRAM ADDRESS OF FONT DATA ### JLC Mod for JBL compatibility ### = REG4 * $800
TMS_FNTSIZE	.EQU	8*256		; ### JLC Mod for JBL compatibility ### = 8x8 Font 256 Chars
; ### JLC Fix to allow Name Table Addresses other than $0000 and JBL Compatibility ###
TMS_CHRVADDR	.EQU	$3800		; VRAM ADDRESS OF CHAR SCREEN DATA (NEW CONSTANT) = REG2 * $400
TMS_COLS	.EQU	40
#ENDIF
;
		DEVECHO	", SCREEN="
		DEVECHO	TMS_COLS
		DEVECHO	"X"
		DEVECHO	TMS_ROWS
;
;;;#DEFINE USEFONT8X8
;;;#DEFINE	TMS_FONT FONT8X8
#DEFINE USEFONT6X8
#DEFINE	TMS_FONT FONT6X8
;
TERMENABLE	.SET	TRUE		; INCLUDE TERMINAL PSEUDODEVICE DRIVER
;
		DEVECHO ", KEYBOARD="
;
#IF (TMSKBD == TMSKBD_NONE)
		DEVECHO	"NONE"
#ENDIF
;
#IF (TMSKBD == TMSKBD_PPK)
PPKENABLE	.SET	TRUE		; INCLUDE PPK KEYBOARD SUPPORT
		DEVECHO	"PPK"
#ENDIF
;
#IF (TMSKBD == TMSKBD_KBD)
KBDENABLE	.SET	TRUE		; INCLUDE PS2 KEYBOARD SUPPORT
		DEVECHO	"KBD"
#ENDIF
;
#IF (TMSKBD == TMSKBD_MKY)
MKYENABLE	.SET	TRUE		; INCLUDE MSX KEYBOARD SUPPORT
		DEVECHO	"MKY"
#ENDIF
;
#IF (TMSKBD == TMSKBD_NABU)
NABUKBENABLE	.SET	TRUE		; INCLUDE NABU KEYBOARD SUPPORT
		DEVECHO	"NABU"
#ENDIF
;
#IF (TMSKBD == TMSKBD_USB)
USBKYBENABLE	.SET	TRUE		; INCLUDE USB KEYBOARD SUPPORT
		DEVECHO	"USB-KYB"
#ENDIF
;
#IF (TMSTIMENABLE & (INTMODE > 0))
		DEVECHO	", INTERRUPTS ENABLED"
#ENDIF
		DEVECHO	"\n"
;
; TMS_IODELAY IS USED TO ADD RECOVERY TIME TO TMS9918/V9958 ACCESSES
; IF YOU SEE SCREEN CORRUPTION, ADJUST THIS!!!
;
#IF (CPUFAM == CPU_Z180)
  ; BELOW WAS TUNED FOR Z180 AT 18MHZ
  #DEFINE	TMS_IODELAY	EX (SP),HL \ EX (SP),HL	; 38 W/S
  ;#DEFINE	TMS_IODELAY	NOP \ NOP \ NOP \ NOP \ NOP ; 20 W/S ### JLC Mod for Clock/2 (9 MHz) ###
#ELSE
  ; BELOW WAS TUNED FOR Z80 AT 8MHZ
  #IF (TMS80COLS)
    #DEFINE	TMS_IODELAY	NOP \ NOP \ NOP \ NOP \ NOP \ NOP \ NOP ; V9958 NEEDS AT WORST CASE, APPROX 4us (28T) DELAY BETWEEN I/O (WHEN IN TEXT MODE)
  #ELSE
    #DEFINE	TMS_IODELAY	NOP \ NOP ; 8 W/S
  #ENDIF
#ENDIF
;
;======================================================================
; TMS DRIVER - INITIALIZATION
;======================================================================
;
TMS_PREINIT:
#IF (TMSKBD == TMSKBD_KBD)
	LD	IY,TMS_IDAT		; POINTER TO INSTANCE DATA
	CALL	KBD_PREINIT
#ENDIF
	; DISABLE INTERRUPT GENERATION UNTIL AFTER INTERRUPT HANDLER
	; HAS BEEN INSTALLED.
	LD	A, (TMS_INITVDU_REG_1)
        RES	TMSINTEN, A             ; RESET INTERRUPT ENABLE BIT
	LD	(TMS_INITVDU_REG_1), A
        LD	C, TMSCTRL1
	JP	TMS_SET_X		; SET REG W/O INT MGMT
;
TMS_INIT:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
;
#IF ((TMSMODE == TMSMODE_SCG) | (TMSMODE == TMSMODE_MBC) | (TMSMODE == TMSMODE_DUO))
	LD	A,$FF
	EZ80_IO
	OUT	(TMS_ACR),A		; INIT AUX CONTROL REG
#ENDIF
;
	CALL	NEWLINE			; FORMATTING
	PRTS("TMS: MODE=$")

#IF ((TMSMODE == TMSMODE_MBC) | (TMSMODE == TMSMODE_DUO))
	LD	A,$FE
	EZ80_IO
	OUT	(TMS_ACR),A		; CLEAR VDP RESET
#ENDIF
;
	LD	IY,TMS_IDAT		; POINTER TO INSTANCE DATA
;
#IF (TMSMODE == TMSMODE_SCG)
	PRTS("SCG$")
#ENDIF
#IF (TMSMODE == TMSMODE_N8)
	PRTS("N8$")
#ENDIF
#IF (TMSMODE == TMSMODE_MSX)
	PRTS("MSX$")
#ENDIF
#IF (TMSMODE == TMSMODE_MSXKBD)
	PRTS("MSXKBD$")
#ENDIF
#IF (TMSMODE == TMSMODE_MSXMKY)
	PRTS("MSXMKY$")
#ENDIF
#IF (TMSMODE == TMSMODE_MBC)
	PRTS("MBC$")
#ENDIF
#IF (TMSMODE == TMSMODE_COLECO)
	PRTS("COLECO$")
#ENDIF
#IF (TMSMODE == TMSMODE_DUO)
	PRTS("DUO$")
#ENDIF
#IF (TMSMODE == TMSMODE_NABU)
	PRTS("NABU$")
#ENDIF
;
	PRTS(" IO=0x$")
	LD	A,TMS_DATREG
	CALL	PRTHEXBYTE
	CALL	TMS_PROBE		; CHECK FOR HW EXISTENCE
	JR	Z,TMS_INIT1		; CONTINUE IF PRESENT
;
	; *** HARDWARE NOT PRESENT ***
	PRTS(" NOT PRESENT$")
	OR	$FF			; SIGNAL FAILURE
	RET
;
TMS_INIT1:
#IF (TMSTIMENABLE)
	CALL PRTSTRD
	.TEXT	" INTERRUPT ENABLED$"
#ENDIF
	CALL	PC_SPACE
	LD	A,TMS_COLS
	CALL	PRTDEC8
	LD	A,'X'
	CALL	COUT
	LD	A,TMS_ROWS
	CALL	PRTDEC8
;
	CALL 	TMS_CRTINIT		; SETUP THE TMS CHIP REGISTERS
	CALL	TMS_LOADFONT		; LOAD FONT DATA FROM ROM TO TMS STRORAGE
	; *** DIAGNOSE FONT LOAD ERROR HERE!!! ***
	CALL	TMS_CLEAR		; CLEAR SCREEN, HOME CURSOR
#IF (TMSKBD == TMSKBD_PPK)
	CALL	PPK_INIT		; INITIALIZE PPI KEYBOARD DRIVER
#ENDIF
#IF (TMSKBD == TMSKBD_KBD)
	CALL	KBD_INIT		; INITIALIZE 8242 KEYBOARD DRIVER
#ENDIF
#IF (TMSKBD == TMSKBD_MKY)
	CALL	MKY_INIT		; INITIALIZE MKY KEYBOARD DRIVER
#ENDIF
#IF (TMSKBD == TMSKBD_NABU)
	CALL	NABUKB_INIT		; INITIALIZE NABU KEYBOARD DRIVER
#ENDIF
#IF (TMSKBD == TMSKBD_USB)
	CALL	CHUKB_INIT
#ENDIF

#IF (TMSTIMENABLE & (INTMODE > 0))
;
  #IF (INTMODE == 1)
	; ADD IM1 INT CALL LIST ENTRY
	LD	HL,TMS_TSTINT		; GET INT VECTOR
	CALL	HB_ADDIM1		; ADD TO IM1 CALL LIST
  #ELSE
	; INSTALL VECTOR
	LD	HL,TMS_TSTINT
	LD	(IVT(INT_VDP)),HL	; IVT INDEX
  #ENDIF
;
	; ENABLE VDP INTERRUPTS NOW
	LD	A, (TMS_INITVDU_REG_1)
	SET	TMSINTEN,A		; SET INTERRUPT ENABLE BIT
	LD	(TMS_INITVDU_REG_1),A
	LD	C, TMSCTRL1
	CALL	TMS_SET
;
  #IF (TMSMODE == TMSMODE_NABU)
	; ENABLE VDP INTERRUPTS ON NABU INTERRUPT CONTROLLER
	LD	A,14			; PSG R14 (PORT A DATA)
	OUT	(NABU_RSEL),A		; SELECT IT
	LD	A,(NABU_CTLVAL)		; GET NABU CTL PORT SHADOW REG
	SET	4,A			; ENABLE VDP INTERRUPTS
	LD	(NABU_CTLVAL),A		; UPDATE SHADOW REG
	OUT	(NABU_RDAT),A		; WRITE TO HARDWARE
  #ENDIF
;
#ENDIF
;
	; ADD OURSELVES TO VDA DISPATCH TABLE
	LD	BC,TMS_FNTBL		; BC := FUNCTION TABLE ADDRESS
	LD	DE,TMS_IDAT		; DE := TMS INSTANCE DATA PTR
	CALL	VDA_ADDENT		; ADD ENTRY, A := UNIT ASSIGNED
;
	; INITIALIZE EMULATION
	LD	C,A			; C := ASSIGNED VIDEO DEVICE NUM
	LD	DE,TMS_FNTBL		; DE := FUNCTION TABLE ADDRESS
	LD	HL,TMS_IDAT		; HL := TMS INSTANCE DATA PTR
	CALL	TERM_ATTACH		; DO IT
;
	XOR	A			; SIGNAL SUCCESS
	RET
;
;======================================================================
; TMS DRIVER - VIDEO DISPLAY ADAPTER (VDA) FUNCTIONS
;======================================================================
;
TMS_FNTBL:
	.DW	TMS_VDAINI
	.DW	TMS_VDAQRY
	.DW	TMS_VDARES
	.DW	TMS_VDADEV
	.DW	TMS_VDASCS
	.DW	TMS_VDASCP
	.DW	TMS_VDASAT
	.DW	TMS_VDASCO
	.DW	TMS_VDAWRC
	.DW	TMS_VDAFIL
	.DW	TMS_VDACPY
	.DW	TMS_VDASCR
#IF (TMSKBD == TMSKBD_NONE)
  	.DW	TMS_STAT
  	.DW	TMS_FLUSH
  	.DW	TMS_READ
#ENDIF
#IF (TMSKBD == TMSKBD_PPK)
	.DW	PPK_STAT
	.DW	PPK_FLUSH
	.DW	PPK_READ
#ENDIF
#IF (TMSKBD == TMSKBD_KBD)
  	.DW	KBD_STAT
  	.DW	KBD_FLUSH
  	.DW	KBD_READ
#ENDIF
#IF (TMSKBD == TMSKBD_MKY)
  	.DW	MKY_STAT
  	.DW	MKY_FLUSH
  	.DW	MKY_READ
#ENDIF
#IF (TMSKBD == TMSKBD_USB)
	.DW	UKY_STAT
	.DW	UKY_FLUSH
	.DW	UKY_READ
#ENDIF
#IF (TMSKBD == TMSKBD_NABU)
	.DW	NABUKB_STAT
	.DW	NABUKB_FLUSH
	.DW	NABUKB_READ
#ENDIF
	.DW	TMS_VDARDC
#IF (($ - TMS_FNTBL) != (VDA_FNCNT * 2))
	.ECHO	"*** INVALID TMS FUNCTION TABLE ***\n"
	!!!!!
#ENDIF
;
TMS_VDAINI:
	; RESET VDA
	; CURRENTLY IGNORES VIDEO MODE AND BITMAP DATA
	CALL	TMS_VDARES		; RESET VDA
	CALL	TMS_CLEAR		; CLEAR SCREEN
	XOR	A			; SIGNAL SUCCESS
	RET
;
TMS_VDAQRY:
	LD	C,$00			; MODE ZERO IS ALL WE KNOW
	LD	D,TMS_ROWS		; ROWS
	LD	E,TMS_COLS		; COLS
	LD	HL,0			; EXTRACTION OF CURRENT BITMAP DATA NOT SUPPORTED YET
	XOR	A			; SIGNAL SUCCESS
	RET
;
TMS_VDARES:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
	CALL	TMS_CRTINIT1A
	CALL	TMS_CLRCUR		; CLEAR CURSOR
	CALL	TMS_LOADFONT		; RELOAD FONT
	LD	A,$FF			; REMOVE
	LD	(TMS_CURSAV),A		; ... SAVED CURSOR CHAR
	CALL	TMS_SETCUR		; RESTORE CURSOR
	XOR	A
	RET

TMS_VDADEV:
	LD	D,VDADEV_TMS		; D := DEVICE TYPE
	LD	E,0			; E := PHYSICAL UNIT IS ALWAYS ZERO
	LD	H,TMSMODE		; H := MODE
	LD	L,TMS_DATREG		; L := BASE I/O ADDRESS
	XOR	A			; SIGNAL SUCCESS
	RET

TMS_VDASCS:
	SYSCHKERR(ERR_NOTIMPL)		; NOT IMPLEMENTED (YET)
	RET

TMS_VDASCP:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
	CALL	TMS_CLRCUR
	CALL	TMS_XY			; SET CURSOR POSITION
	CALL	TMS_SETCUR
	XOR	A			; SIGNAL SUCCESS
	RET

TMS_VDASAT:
	XOR	A			; NOT POSSIBLE, JUST SIGNAL SUCCESS
	RET

TMS_VDASCO:
	; ### JLC Mod - Implement Default Text Mode Colors via ANSI_VDASCO or direct HBIOS Call
	;
	; Color setting is in reg D in ANSI Format as described in RomWBW System Guide
	; Convert Color Format from ANSI to TMS shuffling bits arround and using
	; Color Conversion Table at TMS_COLOR_TBL (approximated equivalences)
	; Save converted value to (TMS_TMSCOLOR)
	;
	; TMS hardware only allows setting a global (screen) foreground/background color.  So, we
	; only process this command if E is 1.
	;
	LD	A,D			; GET CHAR/SCREEN SCOPE
	CP	1			; SCREEN?
	JR	NZ,TMS_VDASCO_Z		; IF NOT, JUST RETURN
;
	LD	A,E			; GET COLOR BYTE
	AND	$F0			; ISOLATE BACKGROUND
	RRCA \ RRCA \ RRCA \ RRCA	; MOVE TO LOWER NIBBLE
	LD	HL,TMS_COLOR_TBL	; POINT TO COLOR CONVERSION TABLE
	CALL	ADDHLA			; OFFSET TO DESIRED COLOR
	LD	B,(HL)			; PUT NEW BG IN B
;
	LD	A,E			; GET COLOR BYTE
	AND	$0F			; ISOLATE FOREGROUND
	LD	HL,TMS_COLOR_TBL	; POINT TO COLOR CONVERSION TABLE
	CALL	ADDHLA			; OFFSET TO DESIRED COLOR
	LD	A,(HL)			; PUT NEW FG IN A
	RLCA \ RLCA \ RLCA \ RLCA	; MOVE TO UPPER NIBBLE
;
	OR	B			; COMBINE WITH FG
	LD	C, 7			; C = Color Register, A = Desired new Color in TMS Format
	CALL	TMS_SET			; Write to specific TMS Register, Change Default Text Color
;
TMS_VDASCO_Z:
	XOR	A			; SIGNAL SUCCESS
	RET

TMS_VDAWRC:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
	CALL	TMS_CLRCUR		; CURSOR OFF
	LD	A,E			; CHARACTER TO WRITE GOES IN A
	CALL	TMS_PUTCHAR		; PUT IT ON THE SCREEN
	CALL	TMS_SETCUR
	XOR	A			; SIGNAL SUCCESS
	RET

TMS_VDAFIL:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
	CALL	TMS_CLRCUR
	LD	A,E			; FILL CHARACTER GOES IN A
	EX	DE,HL			; FILL LENGTH GOES IN DE
	CALL	TMS_FILL		; DO THE FILL
	CALL	TMS_SETCUR
	XOR	A			; SIGNAL SUCCESS
	RET

TMS_VDACPY:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
	CALL	TMS_CLRCUR
	; LENGTH IN HL, SOURCE ROW/COL IN DE, DEST IS TMS_POS
	; BLKCPY USES: HL=SOURCE, DE=DEST, BC=COUNT
	PUSH	HL			; SAVE LENGTH
	CALL	TMS_XY2IDX		; ROW/COL IN DE -> SOURCE ADR IN HL
	POP	BC			; RECOVER LENGTH IN BC
	LD	DE,(TMS_POS)		; PUT DEST IN DE
	CALL	TMS_BLKCPY		; DO A BLOCK COPY
	CALL	TMS_SETCUR
	XOR	A
	RET

TMS_VDASCR:
#IF (CPUFAM == CPU_Z180)
	CALL	TMS_Z180IO
#ENDIF
	CALL	TMS_CLRCUR
TMS_VDASCR0:
	LD	A,E			; LOAD E INTO A
	OR	A			; SET FLAGS
	JR	Z,TMS_VDASCR2		; IF ZERO, WE ARE DONE
	PUSH	DE			; SAVE E
	JP	M,TMS_VDASCR1		; E IS NEGATIVE, REVERSE SCROLL
	CALL	TMS_SCROLL		; SCROLL FORWARD ONE LINE
	POP	DE			; RECOVER E
	DEC	E			; DECREMENT IT
	JR	TMS_VDASCR0		; LOOP
TMS_VDASCR1:
	CALL	TMS_RSCROLL		; SCROLL REVERSE ONE LINE
	POP	DE			; RECOVER E
	INC	E			; INCREMENT IT
	JR	TMS_VDASCR0		; LOOP
TMS_VDASCR2:
	CALL	TMS_SETCUR
	XOR	A
	RET

;----------------------------------------------------------------------
; READ VALUE AT CURRENT VDU BUFFER POSITION
; RETURN E = CHARACTER, B = COLOUR, C = ATTRIBUTES
;----------------------------------------------------------------------

TMS_VDARDC:
	OR	$FF			; UNSUPPORTED FUNCTION
	RET

; DUMMY FUNCTIONS BELOW BECAUSE SCG BOARD HAS NO
; KEYBOARD INTERFACE

TMS_STAT:
	XOR	A			; SIGNAL NOTHING READY
	JP	CIO_IDLE		; DO IDLE PROCESSING

TMS_FLUSH:
	XOR	A			; SIGNAL SUCCESS
	RET

TMS_READ:
	LD	E,26			; RETURN <SUB> (CTRL-Z)
	XOR	A			; SIGNAL SUCCESS
	RET
;
;======================================================================
; TMS DRIVER - PRIVATE DRIVER FUNCTIONS
;======================================================================
;
;----------------------------------------------------------------------
; SET TMS9918 REGISTER VALUE
;   TMS_SET WRITES VALUE IN A TO VDU REGISTER SPECIFIED IN C
;   TMS_SET_X IS A VARIANT THAT DOES NOT DO INT MGMT (TMS_PREINIT)
;----------------------------------------------------------------------
;
TMS_SET:
	; NORMALLY, WE WRAP REG CHANGES WITH DI/EI TO AVOID CONFLICTS
	HB_DI
	CALL	TMS_SET_X
	HB_EI
	RET
;
TMS_SET_X:
	; ENTRY POINT W/O INT MGMT NEEDED BY TMS_PREINIT
	EZ80_IO
	OUT	(TMS_CMDREG),A		; WRITE IT
	TMS_IODELAY
	LD	A,C			; GET THE DESIRED REGISTER
	OR	$80			; SET BIT 7
	EZ80_IO
	OUT	(TMS_CMDREG),A		; SELECT THE DESIRED REGISTER
	TMS_IODELAY
	RET
;
;----------------------------------------------------------------------
; SET TMS9918 READ/WRITE ADDRESS
;   TMS_WR SETS TMS9918 TO BEGIN WRITING AT VDU ADDRESS SPECIFIED IN HL
;   TMS_RD SETS TMS9918 TO BEGIN READING AT VDU ADDRESS SPECIFIED IN HL
;----------------------------------------------------------------------
;
TMS_WR:
#IF (TMS80COLS)
        ; CLEAR R#14 FOR V9958
	HB_DI
	XOR	A
	EZ80_IO
	OUT	(TMS_CMDREG), A
	TMS_IODELAY
	LD	A, $80 | 14
	EZ80_IO
	OUT	(TMS_CMDREG), A
	TMS_IODELAY
	HB_EI
#ENDIF

	PUSH	HL
	SET	6,H			; SET WRITE BIT
	CALL	TMS_RD
	POP	HL
	RET
;
TMS_RD:
	HB_DI
	LD	A,L
	EZ80_IO
	OUT	(TMS_CMDREG),A
	TMS_IODELAY
	LD	A,H
	EZ80_IO
	OUT	(TMS_CMDREG),A
	TMS_IODELAY
	HB_EI
	RET
;
;----------------------------------------------------------------------
; PROBE FOR TMS HARDWARE
;----------------------------------------------------------------------
;
; ON RETURN, ZF SET INDICATES HARDWARE FOUND
;
TMS_PROBE:
	; SET WRITE ADDRESS TO $0000
	LD	HL,0
	CALL	TMS_WR
	; WRITE TEST PATTERN TO FIRST TWO BYTES
	LD	A,$A5			; FIRST BYTE
	EZ80_IO
	OUT	(TMS_DATREG),A		; OUTPUT
	;TMS_IODELAY			; DELAY
	CALL	DLY64			; DELAY
	CPL				; COMPLEMENT ACCUM
	EZ80_IO
	OUT	(TMS_DATREG),A		; SECOND BYTE
	;TMS_IODELAY			; DELAY
	CALL	DLY64			; DELAY
;
	; SET READ ADDRESS TO $0000
	LD	HL,0
	CALL	TMS_RD
	; READ TEST PATTERN
	LD	C,$A5			; VALUE TO EXPECT
	EZ80_IO
	IN	A,(TMS_DATREG)		; READ FIRST BYTE
	;TMS_IODELAY			; DELAY
	CALL	DLY64			; DELAY
	CP	C			; COMPARE
	RET	NZ			; RETURN ON MISCOMPARE
	EZ80_IO
	IN	A,(TMS_DATREG)		; READ SECOND BYTE
	;TMS_IODELAY			; DELAY
	CALL	DLY64			; DELAY
	CPL				; COMPLEMENT IT
	CP	C			; COMPARE
	RET				; RETURN WITH RESULT IN Z
;
;----------------------------------------------------------------------
; TMS9918 DISPLAY CONTROLLER CHIP INITIALIZATION
;----------------------------------------------------------------------
;
TMS_CRTINIT:
	; SET WRITE ADDRESS TO $0000 Beginning of VRAM
	LD	HL,0
	CALL	TMS_WR
;
	; FILL ENTIRE 16KB VRAM CONTENTS with $00
	LD	DE,$4000		; 16KB
TMS_CRTINIT1:
	XOR	A
	EZ80_IO
	OUT	(TMS_DATREG),A
	TMS_IODELAY			; DELAY
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,TMS_CRTINIT1
;
TMS_CRTINIT1A:
;
	; INITIALIZE VDU REGISTERS
	LD 	C,0			; START WITH REGISTER 0
	LD	B,TMS_INITVDULEN	; NUMBER OF REGISTERS TO INIT
	LD 	HL,TMS_INITVDU		; HL = POINTER TO THE DEFAULT VALUES
TMS_CRTINIT2:
	LD	A,(HL)			; GET VALUE
	CALL	TMS_SET			; WRITE IT
	INC	HL			; POINT TO NEXT VALUE
	INC	C			; POINT TO NEXT REGISTER
	DJNZ	TMS_CRTINIT2		; LOOP
;
	; ENABLE WAIT SIGNAL IF 9938/58
#IF (TMS80COLS)
	LD	C,25			; REGISTER 25
	LD	A,%00000100		; ONLY WTE BIT SET
	CALL	TMS_SET			; DO IT
#ENDIF
	RET
;
;----------------------------------------------------------------------
; CLEAR SCREEN AND HOME CURSOR
;----------------------------------------------------------------------
;
TMS_CLEAR:
	LD	DE,0			; ROW = 0, COL = 0
	CALL	TMS_XY			; SEND CURSOR TO TOP LEFT
	LD	A,' '			; BLANK THE SCREEN
	LD	DE,TMS_ROWS * TMS_COLS	; FILL ENTIRE BUFFER
	CALL	TMS_FILL		; DO IT
	LD	DE,0			; ROW = 0, COL = 0
	CALL	TMS_XY			; SEND CURSOR TO TOP LEFT
	XOR	A
	DEC	A
	LD	(TMS_CURSAV),A
	CALL	TMS_SETCUR		; SET CURSOR
;
	XOR	A			; SIGNAL SUCCESS
	RET
;
;----------------------------------------------------------------------
; LOAD FONT DATA
;----------------------------------------------------------------------
;
TMS_LOADFONT:
	; SET WRITE ADDRESS TO TMS_FNTVADDR
	LD	HL,TMS_FNTVADDR
	CALL	TMS_WR
;
; THE USE OF COMPRESSED FONT STORAGE FOR THE TMS DRIVER IS DISABLED
; SO THAT WE CAN RELOAD THE FONT DATA ON USER RESET.  THE TMS CHIP
; IS FREQUENTLY REPROGRAMMED BY GAMES, ETC., SO IT IS NECESSARY TO
; REINIT AND RELOAD FONTS.  RELOADING A COMPRESSED FONT AFTER
; SYSTEM INITIALIZATION REQUIRES A LARGE DECOMPRESSION BUFFER THAT WE
; HAVE NO WAY TO ACCOMMODATE WITHOUT TRASHING OS/APP MEMORY.
;
	LD	A,FONTID_6X8		; WE WANT 6X8
	CALL	FNT_SELECT		; SELECT IT
	RET	NZ			; ERROR RETURN
;
	; FILL TMS_FNTVADDR BYTES FROM FONTDATA
	LD	DE,TMS_FNTSIZE
TMS_LOADFONT1:
	CALL	FNT_NEXT		; NEXT FONT DATA BYTE
	EZ80_IO
	OUT	(TMS_DATREG),A
	TMS_IODELAY			; DELAY
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,TMS_LOADFONT1
	XOR	A			; SIGNAL SUCCESS
	RET
;
;----------------------------------------------------------------------
; VIRTUAL CURSOR MANAGEMENT
;   TMS_SETCUR CONFIGURES AND DISPLAYS CURSOR AT CURRENT CURSOR LOCATION
;   TMS_CLRCUR REMOVES THE CURSOR
;
; VIRTUAL CURSOR IS GENERATED BY DYNAMICALLY CHANGING FONT GLYPH
; FOR CHAR 255 TO BE THE INVERSE OF THE GLYPH OF THE CHARACTER UNDER
; THE CURRENT CURSOR POSITION.  THE CHARACTER CODE IS THEN SWITCHED TO
; THE VALUE 255 AND THE ORIGINAL VALUE IS SAVED.  WHEN THE DISPLAY
; NEEDS TO BE CHANGED THE PROCESS IS UNDONE.  IT IS ESSENTIAL THAT
; ALL DISPLAY CHANGES BE BRACKETED WITH CALLS TO TMS_CLRCUR PRIOR TO
; CHANGES AND TMS_SETCUR AFTER CHANGES.
;----------------------------------------------------------------------
;
TMS_SETCUR:
	PUSH	HL			; PRESERVE HL
	PUSH	DE			; PRESERVE DE
	LD	HL,(TMS_POS)		; GET CURSOR POSITION
	CALL	TMS_RD			; SETUP TO READ VDU BUF
	EZ80_IO
	IN	A,(TMS_DATREG)		; GET REAL CHAR UNDER CURSOR
	TMS_IODELAY			; DELAY
	PUSH	AF			; SAVE THE CHARACTER
	CALL	TMS_WR			; SETUP TO WRITE TO THE SAME PLACE
	LD	A,$FF			; REPLACE REAL CHAR WITH 255
	EZ80_IO
	OUT	(TMS_DATREG),A		; DO IT
	TMS_IODELAY			; DELAY
	POP	AF			; RECOVER THE REAL CHARACTER
	LD	B,A			; PUT IT IN B
	LD	A,(TMS_CURSAV)		; GET THE CURRENTLY SAVED CHAR
	CP	B			; COMPARE TO CURRENT
	JR	Z,TMS_SETCUR3		; IF EQUAL, BYPASS EXTRA WORK
	LD	A,B			; GET REAL CHAR BACK TO A
	LD	(TMS_CURSAV),A		; SAVE IT
	; GET THE GLYPH DATA FOR REAL CHARACTER
	LD	HL,0			; ZERO HL
	LD	L,A			; HL IS NOW RAW CHAR INDEX
	LD	B,3			; LEFT SHIFT BY 3 BITS
TMS_SETCUR0:				; MULT BY 8 FOR FONT INDEX
	SLA	L			; SHIFT LSB INTO CARRY
	RL	H			; SHFT MSB FROM CARRY
	DJNZ	TMS_SETCUR0		; LOOP 3 TIMES
	LD	DE,TMS_FNTVADDR		; OFFSET TO START OF FONT TABLE
	ADD	HL,DE			; ADD TO FONT INDEX
	CALL	TMS_RD			; SETUP TO READ GLYPH
	LD	B,8			; 8 BYTES
	LD	HL,TMS_BUF		; INTO BUFFER
TMS_SETCUR1:				; READ GLYPH LOOP
	EZ80_IO
	IN	A,(TMS_DATREG)		; GET NEXT BYTE
	TMS_IODELAY			; IO DELAY
	LD	(HL),A			; SAVE VALUE IN BUF
	INC	HL			; BUMP BUF POINTER
	DJNZ	TMS_SETCUR1		; LOOP FOR 8 BYTES
;
	; NOW WRITE INVERTED GLYPH INTO FONT INDEX 255
	LD	HL,TMS_FNTVADDR + (255 * 8)	; LOC OF GLPYPH DATA FOR CHAR 255
	CALL	TMS_WR			; SETUP TO WRITE THE INVERTED GLYPH
	LD	B,8			; 8 BYTES PER GLYPH
	LD	HL,TMS_BUF		; POINT TO BUFFER
TMS_SETCUR2:				; WRITE INVERTED GLYPH LOOP
	LD	A,(HL)			; GET THE BYTE
	INC	HL			; BUMP THE BUF POINTER
	XOR	$FF			; INVERT THE VALUE
	EZ80_IO
	OUT	(TMS_DATREG),A		; WRITE IT TO VDU
	TMS_IODELAY			; IO DELAY
	DJNZ	TMS_SETCUR2		; LOOP FOR ALL 8 BYTES OF GLYPH
;
TMS_SETCUR3:	; RESTORE REGISTERS AND RETURN
	POP	DE			; RECOVER DE
	POP	HL			; RECOVER HL
	RET				; RETURN
;
;
;
TMS_CLRCUR:	; REMOVE VIRTUAL CURSOR FROM SCREEN
	PUSH	HL			; SAVE HL
	LD	HL,(TMS_POS)		; POINT TO CURRENT CURSOR POS
	CALL	TMS_WR			; SET UP TO WRITE TO VDU
	LD	A,(TMS_CURSAV)		; GET THE REAL CHARACTER
	EZ80_IO
	OUT	(TMS_DATREG),A		; WRITE IT
	TMS_IODELAY			; IO DELAY
	POP	HL			; RECOVER HL
	RET				; RETURN
;
;----------------------------------------------------------------------
; SET CURSOR POSITION TO ROW IN D AND COLUMN IN E
;----------------------------------------------------------------------
;
TMS_XY:
	CALL	TMS_XY2IDX		; CONVERT ROW/COL TO BUF IDX
	LD	(TMS_POS),HL		; SAVE THE RESULT (DISPLAY POSITION)
	RET
;
;----------------------------------------------------------------------
; CONVERT XY COORDINATES IN DE INTO LINEAR INDEX IN HL
; D=ROW, E=COL
;----------------------------------------------------------------------
;
TMS_XY2IDX:
	LD	A,E			; SAVE COLUMN NUMBER IN A
	LD	H,D			; SET H TO ROW NUMBER
	LD	E,TMS_COLS		; SET E TO ROW LENGTH
	CALL	MULT8			; MULTIPLY TO GET ROW OFFSET
	LD	E,A			; GET COLUMN BACK
	ADD	HL,DE			; ADD IT IN
	LD	DE,TMS_CHRVADDR		; Add offset Address to start of Name Table (Char)
	ADD	HL,DE
	RET				; RETURN
;
;----------------------------------------------------------------------
; WRITE VALUE IN A TO CURRENT VDU BUFFER POSITION, ADVANCE CURSOR
;----------------------------------------------------------------------
;
TMS_PUTCHAR:
	PUSH	AF			; SAVE CHARACTER
	LD	HL,(TMS_POS)		; LOAD CURRENT POSITION INTO HL
	CALL	TMS_WR			; SET THE WRITE ADDRESS
	POP	AF			; RECOVER CHARACTER TO WRITE
	EZ80_IO
	OUT	(TMS_DATREG),A		; WRITE THE CHARACTER
	TMS_IODELAY
	LD	HL,(TMS_POS)		; LOAD CURRENT POSITION INTO HL
	INC	HL
	LD	(TMS_POS),HL
	RET
;
;----------------------------------------------------------------------
; FILL AREA IN BUFFER WITH SPECIFIED CHARACTER AND CURRENT COLOR/ATTRIBUTE
; STARTING AT THE CURRENT FRAME BUFFER POSITION
;   A: FILL CHARACTER
;   DE: NUMBER OF CHARACTERS TO FILL
;----------------------------------------------------------------------
;
TMS_FILL:
	LD	C,A			; SAVE THE CHARACTER TO WRITE
	LD	HL,(TMS_POS)		; SET STARTING POSITION
	CALL	TMS_WR			; SET UP FOR WRITE
;
TMS_FILL1:
	LD	A,C			; RECOVER CHARACTER TO WRITE
	EZ80_IO
	OUT	(TMS_DATREG),A
	TMS_IODELAY
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,TMS_FILL1
;
	RET
;
;----------------------------------------------------------------------
; SCROLL ENTIRE SCREEN FORWARD BY ONE LINE (CURSOR POSITION UNCHANGED)
;----------------------------------------------------------------------
;
TMS_SCROLL:
	LD	HL,TMS_CHRVADDR		; SOURCE ADDRESS OF CHARACTER BUFFER
	LD	C,TMS_ROWS - 1		; SET UP LOOP COUNTER FOR ROWS - 1
;
TMS_SCROLL0:				; READ LINE THAT IS ONE PAST CURRENT DESTINATION
	PUSH	HL			; SAVE CURRENT DESTINATION
	LD	DE,TMS_COLS
	ADD	HL,DE			; POINT TO NEXT ROW SOURCE
	CALL	TMS_RD			; SET UP TO READ
	LD	DE,TMS_BUF
	LD	B,TMS_COLS
TMS_SCROLL1:
	EZ80_IO
	IN	A,(TMS_DATREG)
	TMS_IODELAY
	LD	(DE),A
	INC	DE
	DJNZ	TMS_SCROLL1
	POP	HL			; RECOVER THE DESTINATION
;
	; WRITE THE BUFFERED LINE TO CURRENT DESTINATION
	CALL	TMS_WR			; SET UP TO WRITE
	LD	DE,TMS_BUF
	LD	B,TMS_COLS
TMS_SCROLL2:
	LD	A,(DE)
	EZ80_IO
	OUT	(TMS_DATREG),A
	TMS_IODELAY
	INC	DE
	DJNZ	TMS_SCROLL2
;
	; BUMP TO NEXT LINE
	LD	DE,TMS_COLS
	ADD	HL,DE
	DEC	C			; DECREMENT ROW COUNTER
	JR	NZ,TMS_SCROLL0		; LOOP THRU ALL ROWS
;
	; FILL THE NEWLY EXPOSED BOTTOM LINE
	CALL	TMS_WR
	LD	A,' '
	LD	B,TMS_COLS
TMS_SCROLL3:
	EZ80_IO
	OUT	(TMS_DATREG),A
	TMS_IODELAY
	DJNZ	TMS_SCROLL3
;
	RET
;
;----------------------------------------------------------------------
; REVERSE SCROLL ENTIRE SCREEN BY ONE LINE (CURSOR POSITION UNCHANGED)
;----------------------------------------------------------------------
;
TMS_RSCROLL:
	LD	HL,TMS_COLS * (TMS_ROWS - 1)
	LD	DE,TMS_CHRVADDR		; Add offset Address to start of Name Table (Char)
	ADD	HL,DE
	LD	C,TMS_ROWS - 1
;
TMS_RSCROLL0:	; READ THE LINE THAT IS ONE PRIOR TO CURRENT DESTINATION
	PUSH	HL			; SAVE THE DESTINATION ADDRESS
	LD	DE,-TMS_COLS
	ADD	HL,DE			; SET SOURCE ADDRESS
	CALL	TMS_RD			; SET UP TO READ
	LD	DE,TMS_BUF		; POINT TO BUFFER
	LD	B,TMS_COLS		; LOOP FOR EACH COLUMN
TMS_RSCROLL1:
	EZ80_IO
	IN	A,(TMS_DATREG)		; GET THE CHAR
	TMS_IODELAY			; RECOVER
	LD	(DE),A			; SAVE IN BUFFER
	INC	DE			; BUMP BUFFER POINTER
	DJNZ	TMS_RSCROLL1		; LOOP THRU ALL COLS
	POP	HL			; RECOVER THE DESTINATION ADDRESS
;
	; WRITE THE BUFFERED LINE TO CURRENT DESTINATION
	CALL	TMS_WR			; SET THE WRITE ADDRESS
	LD	DE,TMS_BUF		; POINT TO BUFFER
	LD	B,TMS_COLS		; INIT LOOP COUNTER
TMS_RSCROLL2:
	LD	A,(DE)			; LOAD THE CHAR
	EZ80_IO
	OUT	(TMS_DATREG),A		; WRITE TO SCREEN
	TMS_IODELAY			; DELAY
	INC	DE			; BUMP BUF POINTER
	DJNZ	TMS_RSCROLL2		; LOOP THRU ALL COLS
;
	; BUMP TO THE PRIOR LINE
	LD	DE,-TMS_COLS		; LOAD COLS (NEGATIVE)
	ADD	HL,DE			; BACK UP THE ADDRESS
	DEC	C			; DECREMENT ROW COUNTER
	JR	NZ,TMS_RSCROLL0		; LOOP THRU ALL ROWS
;
	; FILL THE NEWLY EXPOSED BOTTOM LINE
	CALL	TMS_WR
	LD	A,' '
	LD	B,TMS_COLS
TMS_RSCROLL3:
	EZ80_IO
	OUT	(TMS_DATREG),A
	TMS_IODELAY
	DJNZ	TMS_RSCROLL3
;
	RET
;
;----------------------------------------------------------------------
; BLOCK COPY BC BYTES FROM HL TO DE
;----------------------------------------------------------------------
;
TMS_BLKCPY:
	; SAVE DESTINATION AND LENGTH
	PUSH	BC			; LENGTH
	PUSH	DE			; DEST
;
	; READ FROM THE SOURCE LOCATION
TMS_BLKCPY1:
	CALL	TMS_RD			; SET UP TO READ FROM ADDRESS IN HL
	LD	DE,TMS_BUF		; POINT TO BUFFER
	LD	B,C
TMS_BLKCPY2:
	EZ80_IO
	IN	A,(TMS_DATREG)		; GET THE NEXT BYTE
	TMS_IODELAY			; DELAY
	LD	(DE),A			; SAVE IN BUFFER
	INC	DE			; BUMP BUF PTR
	DJNZ	TMS_BLKCPY2		; LOOP AS NEEDED
;
	; WRITE TO THE DESTINATION LOCATION
	POP	HL			; RECOVER DESTINATION INTO HL
	CALL	TMS_WR			; SET UP TO WRITE
	LD	DE,TMS_BUF		; POINT TO BUFFER
	POP	BC			; GET LOOP COUNTER BACK
	LD	B,C
TMS_BLKCPY3:
	LD	A,(DE)			; GET THE CHAR FROM BUFFER
	EZ80_IO
	OUT	(TMS_DATREG),A		; WRITE TO VDU
	TMS_IODELAY			; DELAY
	INC	DE			; BUMP BUF PTR
	DJNZ	TMS_BLKCPY3		; LOOP AS NEEDED
;
	RET
;
;----------------------------------------------------------------------
; Z180 LOW SPEED I/O CODE BRACKETING
;----------------------------------------------------------------------
;
#IF (CPUFAM == CPU_Z180)
;
TMS_Z180IO:
	; HOOK CALLERS RETURN TO RESTORE DCNTL
	EX	(SP),HL			; SAVE HL & HL := RET ADR
	LD	(TMS_Z180IOR),HL	; SET RET ADR
	LD	HL,TMS_Z180IOX		; HL := SPECIAL RETURN ADR
	EX	(SP),HL			; RESTORE HL, INS NEW RET ADR
	; SET Z180 MAX I/O WAIT STATES
	PUSH	AF			; SAVE AF
	IN0	A,(Z180_DCNTL)		; GET CURRENT Z180 DCNTL
	LD	(TMS_DCNTL),A		; SAVE IT
	OR	%00110000		; NEW DCNTL VALUE (MAX I/O W/S)
	OUT0	(Z180_DCNTL),A		; IMPLEMENT IT
	POP	AF			; RESTORE AF
	; BACK TO CALLER
TMS_Z180IOR	.EQU	$+1
	JP	$0000			; BACK TO CALLER
;
TMS_Z180IOX:
	; RESTORE ORIGINAL DCNTL
	PUSH	AF			; SAVE AF
	LD	A,(TMS_DCNTL)		; ORIG DCNTL
	OUT0	(Z180_DCNTL),A		; IMPLEMENT IT
	POP	AF			; RESTORE AF
	RET				; DONE
;
#ENDIF

#IF (TMSTIMENABLE & (INTMODE > 0))
TMS_TSTINT:
	IN_A_NN(TMS_CMDREG)
	AND	$80
	JR	NZ,TMS_INTHNDL
	AND	$00			; RETURN Z - NOT HANDLED
	RET

TMS_INTHNDL:
	CALL	HB_TIMINT		; RETURN NZ - HANDLED
	OR	$FF
	RET
#ENDIF
;
;==================================================================================================
;   TMS DRIVER - DATA
;==================================================================================================
;
TMS_POS		.DW	0		; CURRENT DISPLAY POSITION
TMS_CURSAV	.DB	0		; SAVES ORIGINAL CHARACTER UNDER CURSOR
TMS_BUF		.FILL	256,0		; COPY BUFFER
;
; ### JLC Mod
; ANSI-->TMS Color Conversion Table
TMS_COLOR_TBL	.DB	$01,$08,$02,$0A,$04,$06,$0C,$0F,$0E,$09,$03,$0B,$05,$0D,$07,$0F
;
;==================================================================================================
;   TMS DRIVER - INSTANCE DATA
;==================================================================================================
;
TMS_IDAT:
#IF ((TMSKBD == TMSKBD_NONE) | (TMSKBD == TMSKBD_MKY) | (TMSKBD == TMSKBD_NABU))
	.FILL	4,0			; DUMMY KEYBOARD CONFIG DATA
#ENDIF
#IF (TMSKBD == TMSKBD_PPK)
	.DB	TMS_PPIA		; PPI PORT A
	.DB	TMS_PPIB		; PPI PORT B
	.DB	TMS_PPIC		; PPI PORT C
	.DB	TMS_PPIX		; PPI CONTROL PORT
#ENDIF
#IF (TMSKBD == TMSKBD_KBD)
	.DB	KBDMODE_PS2		; PS/2 8242 KEYBOARD CONTROLLER
	.DB	TMS_KBDST		; 8242 CMD/STATUS PORT
	.DB	TMS_KBDDATA		; 8242 DATA PORT
	.DB	0			; FILLER
#ENDIF
;
	.DB	TMS_DATREG
	.DB	TMS_CMDREG
;
;==================================================================================================
;   TMS DRIVER - TMS9918 REGISTER INITIALIZATION
;==================================================================================================
;
; Control Registers (write CMDREG):
;
; Reg	Bit 7	Bit 6	Bit 5	Bit 4	Bit 3	Bit 2	Bit 1	Bit 0	Description
; 0	-	-	-	-	-	-	M3	EXTVID
; 1	4/16K	BL	GINT	M1	M2	-	SI	MAG
; 2	-	-	-	-	PN13	PN12	PN11	PN10
; 3	CT13	CT12	CT11	CT10	CT9	CT8	CT7	CT6
; 4	-	-	-	-	-	PG13	PG12	PG11
; 5	-	SA13	SA12	SA11	SA10	SA9	SA8	SA7
; 6	-	-	-	-	-	SG13	SG12	SG11
; 7	TC3	TC2	TC1	TC0	BD3	BD2	BD1	BD0
;
; Status (read CMDREG):
;
; 	Bit 7	Bit 6	Bit 5	Bit 4	Bit 3	Bit 2	Bit 1	Bit 0	Description
; 	INT	5S	C	FS4	FS3	FS2	FS1	FS0
;
; M1,M2,M3	Select screen mode
; EXTVID	Enables external video input.
; 4/16K		Selects 16kB RAM if set. No effect in MSX1 system.
; BL		Blank screen if reset; just backdrop. Sprite system inactive
; SI		16x16 sprites if set; 8x8 if reset
; MAG		Sprites enlarged if set (sprite pixels are 2x2)
; GINT		Generate interrupts if set
; PN*		Address for pattern name table
; CT*		Address for colour table (special meaning in M2)
; PG*		Address for pattern generator table (special meaning in M2)
; SA*		Address for sprite attribute table
; SG*		Address for sprite generator table
; TC*		Text colour (foreground)
; BD*		Back drop (background). Sets the colour of the border around
; 		the drawable area. If it is 0, it is black (like colour 1).
; FS*		Fifth sprite (first sprite that's not displayed). Only valid
; 		if 5S is set.
; C		Sprite collision detected
; 5S		Fifth sprite (not displayed) detected. Value in FS* is valid.
; INT		Set at each screen update, used for interrupts.
;
#IF (TMS80COLS)
;
; NOTE: YAMAHA 9938/58 DOCUMENTATION SAYS R3 IS SAME AS 9918 (ADR >> 10),
; BUT THIS SEEMS TO BE WRONG AND CORRECTLY DOCUMENTED AT
; https://www.msx.org/wiki/Screen_Modes_Description#SCREEN_0_in_80-column_.28Text_mode_2.29
; BITS 1-0 SHOULD BE 1.  BITS 8-2 SHOULD BE (ADR >> 8).
;
; ### JLC Mod
; TEXT MODE DEFAULT COLOR (REG 7) CAN BE CHANGED INVOKING VDASCO
; OR VIA ANSI PRIVATE ESC SEQ. (SEE ANSI.ASM FOR DETAILS)
;
TMS_INITVDU:	; V9958 REGISTER SET
	.DB	$04		; REG 0 - NO EXTERNAL VID, SET M4 = 1 FOR 80 COLS
TMS_INITVDU_REG_1:
	.DB	$50		; REG 1 - ENABLE SCREEN, SET M1
	.DB	$03		; REG 2 - SET PATTERN NAME TABLE TO (TMS_CHRVADDR >> 8) | $03
	.DB	$00		; REG 3 - NO COLOR TABLE
	.DB	$02		; REG 4 - SET PATTERN GENERATOR TABLE TO (TMS_FNTVADDR -> $1000)
	.DB	$00		; REG 5 - SPRITE ATTRIBUTE IRRELEVANT
	.DB	$00		; REG 6 - NO SPRITE GENERATOR TABLE
	.DB	$F0		; REG 7 - WHITE ON BLACK
	.DB	$88		; REG 8 - COLOUR BUS INPUT, DRAM 64K
#IF (TICKFREQ == 50)
	.DB	$02		; REG 9
#ELSE
	.DB	$00		; REG 9
#ENDIF
	.DB	$00		; REG 10 - COLOUR TABLE A14-A16 (TMS_FNTVADDR - $1000)
;
#ELSE 		; _______TMS9918 REGISTER SET_______
;
TMS_INITVDU:	; V9918 REGISTER SET
	.DB	$00		; REG 0 - SET TEXT MODE, NO EXTERNAL VID
TMS_INITVDU_REG_1:
	.DB	$D0		; REG 1 - SET 16K VRAM, ENABLE SCREEN, NO INTERRUPTS, TEXT MODE ($50 TO BLANK SCREEN)
	.DB	$0E		; REG 2 - SET PATTERN NAME TABLE TO (TMS_CHRVADDR >> 10)
	.DB	$FF		; REG 3 - NO COLOR TABLE, SET TO MODE II DEFAULT VALUE
	.DB	$00		; REG 4 - SET PATTERN GENERATOR TABLE TO (TMS_FNTVADDR -> $0000)
	.DB	$76		; REG 5 - SPRITE ATTRIBUTE IRRELEVANT, SET TO MODE II DEFAULT VALUE
	.DB	$03		; REG 6 - NO SPRITE GENERATOR TABLE, SET TO MODE II DEFAULT VALUE
	.DB	$E1		; REG 7 - TEXT COLOR
;
#ENDIF
;
TMS_INITVDULEN	.EQU	$ - TMS_INITVDU
;
;
#IF (CPUFAM == CPU_Z180)
TMS_DCNTL	.DB	$00	; SAVE Z180 DCNTL AS NEEDED
#ENDIF
;
; ### JLC Mod
;===============================================================================
; BASIC ANSI to TMS COLOR CONVERSION TABLE (NIBBLES FOR FOREGROUND & BACKGROUND)
;          Follows RomWBW System Guide Chapter 8, HBIOS Reference
;-------------------------------------------------------------------------------
;					 ANSI Color 		TMS Equivalent
;-------------------------------------------------------------------------------
;					 0 Black		1
;					 1 Red			8
;					 2 Green		2
;					 3 Brown		A
;					 4 Blue			4
;					 5 Magenta		6
;					 6 Cyan			C
;					 7 White		F
;					 8 Gray			E
;					 9 Light Red		9
;					 A Light Green		3
;					 B Yellow		B
;	 				 C Light Blue		5
;	 				 D Light Magenta	D
;	 				 E Light Cyan		7
;	 				 F Bright White		F
;===============================================================================
;
