;==================================================================================================
; DS1307 PCF I2C CLOCK DRIVER
;
; LABELS STARTING WITH PCF ARE REFERENCING THE PCF8584 LIBRARY
;
;==================================================================================================
;
#IF (!PCFENABLE)
	.ECHO	"*** DS7 DRIVER REQUIRES PCF DRIVER.  SET PCFENABLE!!!\n"
	!!!	; FORCE AN ASSEMBLY ERROR
#ENDIF
;
DS7_OUT		.EQU	10000000B		; SELECT SQUARE WAVE FUNCTION
DS7_SQWE	.EQU	00010000B		; ENABLE SQUARE WAVE OUTPUT
DS7_RATE	.EQU	00000000B		; SET 1HZ OUPUT
;
DS7_DS1307    	.EQU  	11010000B   		; DEVICE IDENTIFIER
DS7_W   	.EQU  	00000000B   		; DEVICE WRITE
DS7_R   	.EQU  	00000001B   		; DEVICE READ
;
DS7_READ   	.EQU    (DS7_DS1307 | DS7_R)	; READ
DS7_WRITE 	.EQU    (DS7_DS1307 | DS7_W)	; WRITE
;
DS7_CTL		.EQU	(DS7_OUT | DS7_SQWE | DS7_RATE)
;
		DEVECHO	"DS1307: ENABLED\n"
;
;-----------------------------------------------------------------------------
; DS1307 INITIALIZATION
;
; ASSUMES PCF8584 I2C HAS ALREADY BEEN INITIALIZED
; CHECKS IF OSCILLATOR IS RUNNING. IF IT ISN'T THE
; CLOCK IS RESTARTED WITH DEFAULT VALUES.
;
; DRIVER WILL NOT BE INSTALLED AS PART OF HBIOS IF
; THERE IS ALREADY AND EXISTING RTC INSTALLED.
;
; 12HR MODE IS CURRENTLY ASSUMED
;
DS7RTC_INIT:
	CALL	NEWLINE			; Formatting
	PRTS("DS1307: $")		; ANNOUNCE DRIVER
;
	LD	A,(PCF_FAIL_FLAG)	; CHECK IF THE
	OR	A			; I2C DRIVER
	JR	NZ,RTC_INIT_FAIL	; INITIALIZED

	CALL	DS7_RDC			; READ CLOCK DATA
	LD	HL,DS7_BUF		; IF NOT RUNNING OR
	BIT	7,(HL)			; INVALID, RESTART
	JR	Z,DS7_CSET		; AND RESET.
	CALL	DS7_SETC
	CALL	DS7_RDC			; READ AND DISPLAY
DS7_CSET:
	CALL	DS7_DISP		; DATE AND TIME
;
	LD	A,(RTC_DISPACT)		; CHECK RTC DISPATCHER STATUS.
	OR	A			; RETURN NOW IF WE ALREADY HAVE
	RET	NZ			; A PRIMARY RTC INSTALLED.
;
	LD	BC,DS7_DISPATCH		; SETUP CLOCK HBIOS DISATCHER
	CALL	RTC_SETDISP
;
;	CALL	DS7_GETTIM
;
	XOR	A			; SIGNAL SUCCESS
	RET
;
RTC_INIT_FAIL:				; EXIT 
	CALL	PRTSTRD			; WITH 
	.DB	"NO I2C DRIVER$"	; ERROR
	PUSH	AF			; MESSAGE
RTC_INIT_ERR:				; EXIT
	POP	AF			; WITH
	LD	A,ERR_NOHW		; ERROR
	OR	A			; STATUS
	RET
;
;-----------------------------------------------------------------------------
; DS1307 HBIOS DISPATCHER
;
;   A: RESULT (OUT), 0=OK, Z=OK, NZ=ERROR
;   B: FUNCTION (IN)
;
DS7_DISPATCH:
	PUSH	AF				; CHECK IF WE
	LD	A,(PCF_FAIL_FLAG)		; HAVE HARDWARE
	OR	A				; AND ASSOCIATED
	JR	NZ,RTC_INIT_ERR			; DRIVER
	POP	AF
;
	LD	A, B				; GET REQUESTED FUNCTION
	AND	$0F				; ISOLATE SUB-FUNCTION
	JP	Z, DS7_GETTIM			; GET TIME
	DEC	A
	JP	Z, DS7_SETTIM			; SET TIME 
	DEC	A
	JP	Z, DS7_GETBYT			; GET NVRAM BYTE VALUE
	DEC	A
	JP	Z, DS7_SETBYT			; SET NVRAM BYTE VALUE
	DEC	A
	JP	Z, DS7_GETBLK			; GET NVRAM DATA BLOCK VALUE
	DEC	A
	JP	Z, DS7_SETBLK			; SET NVRAM DATA BLOCK VALUE 
	DEC	A
	JP	Z, DS7_GETALM			; GET ALARM
	DEC	A
	JP	Z, DS7_SETALM			; SET ALARM
	DEC	A
	JP	Z, DS7_DEVICE			; REPORT RTC DEVICE INFO
	SYSCHKERR(ERR_NOFUNC)
	RET
;
;-----------------------------------------------------------------------------
; DS1307 GET TIME
;
; HL POINTS TO A BUFFER TO STORE THE CURRENT TIME AND DATE IN.
; THE TIME AND DATE INFORMATION MUST BE TRANSLATED TO THE
; HBIOS FORMAT AND COPIED FROM THE HBIOS DRIVER BANK TO
; CALLER INVOKED BANK.
;
; HBIOS FORMAT  = YYMMDDHHMMSS
; DS1307 FORMAT = SSMMHH..DDMMYY..
;
DS7_GETTIM:
	PUSH	HL				; SAVE DESTINATION
	CALL	DS7_RDC				; READ THE CLOCK INTO THE BUFFER
;
	LD	HL,DS7_BUF+2
	LD	DE,DS7_BUF+3			; TRANSLATE
	LD	B,3				; FORMAT
DS7_GT0:LD	A,(HL)
	LD	(DE),A	
	INC	DE
	LD	A,(DE)
	LD	(HL),A
	DEC	HL
	DJNZ	DS7_GT0
;
	INC	HL				; POINT TO SECONDS
	RES	7,(HL)				; REMOVE OSCILLATOR BIT
	POP	DE				; HL POINT TO SOURCE
;						; DE POINT TO DESTINATION
#IF (0)
	PUSH	HL
	PUSH	DE
	EX	DE,HL
	LD	A,6
	CALL	PRTHEXBUF
	POP	DE
	POP	HL
#ENDIF
;	
	LD	A,BID_BIOS			; COPY FROM BIOS BANK
	LD	(HB_SRCBNK),A			; SET IT 
	LD	A, (HB_INVBNK)			; COPY TO CURRENT USER BANK
	LD	(HB_DSTBNK),A			; SET IT
	LD	BC, 6				; LENGTH IS 6 BYTES
#IF (INTMODE == 1)
	DI
#ENDIF
	CALL	HB_BNKCPY			; COPY THE CLOCK DATA
#IF (INTMODE == 1)
	EI
#ENDIF
	XOR	A				; SIGNAL SUCCESS
	RET	
;
;-----------------------------------------------------------------------------
; DS1307 SET TIME
;
;   A: RESULT (OUT), 0=OK, Z=OK, NZ=ERROR
;   HL: DATE/TIME BUFFER (IN)
;
; HBIOS FORMAT  = YYMMDDHHMMSS
; DS1307 FORMAT = SSMMHH..DDMMYY..
;
DS7_SETTIM:
;	CALL	PCF_DBG		; [0]


	LD	A, (HB_INVBNK)			; COPY FROM CURRENT USER BANK
	LD	(HB_SRCBNK), A			; SET IT
	LD	A, BID_BIOS			; COPY TO BIOS BANK
	LD	(HB_DSTBNK), A			; SET IT
	LD	DE, DS7_BUF			; DESTINATION ADDRESS
	LD	BC,6				; LENGTH IS 6 BYTES
#IF (INTMODE == 1)
	DI
#ENDIF
	CALL	HB_BNKCPY			; Copy the clock data
#IF (INTMODE == 1)
	EI
#ENDIF
;
;	CALL	PCF_DBG		; [1]

	CALL	PCF_WAIT_FOR_BB
	JP	NZ,PCF_BBERR
;	
	LD	A,DS7_WRITE	; SET SLAVE ADDRESS
        OUT	(PCF_RS0),A
;
        CALL	PCF_START	; GENERATE START CONDITION
	CALL	PCF_WAIT_FOR_PIN; AND ISSUE THE SLAVE ADDRESS
	CALL	NZ,PCF_PINERR
;
	LD	A,00H		; REGISTER 00
        OUT    	(PCF_RS0),A    	; PUT ADDRESS ON BUS
	CALL	PCF_WAIT_FOR_PIN
	CALL	NZ,PCF_PINERR
;
	LD	DE,5
	CALL	DS7_SET3	; STARTING AT REGISTER 0
;
	CALL 	PCF_STOP

	CALL	PCF_WAIT_FOR_BB
	JP	NZ,PCF_BBERR

;	CALL	PCF_DBG		; [2]
;
	LD	A,DS7_WRITE	; SET SLAVE ADDRESS
        OUT	(PCF_RS0),A
;
        CALL	PCF_START	; GENERATE START CONDITION
	CALL	PCF_WAIT_FOR_PIN; AND ISSUE THE SLAVE ADDRESS
	CALL	NZ,PCF_PINERR

;	CALL	PCF_DBG		; [3]
;
	LD	A,04H		; REGISTER 04
        OUT    	(PCF_RS0),A    	; PUT ADDRESS ON BUS
	CALL	PCF_WAIT_FOR_PIN
	CALL	NZ,PCF_PINERR
;
	LD	DE,2
	CALL	DS7_SET3

;	CALL	PCF_DBG		; [4]
;
	CALL 	PCF_STOP
	XOR	A
	RET
;
DS7_SET3:
	LD	B,3
	LD	HL,DS7_BUF
	ADD	HL,DE
DS7_SC1:PUSH	BC

	LD	A,(HL)

;	CALL	PRTHEXBYTE

        OUT     (PCF_RS0),A    	; PUT DATA ON BUS
	CALL	PCF_WAIT_FOR_ACK
	CALL	NZ,PCF_ACKERR
	POP	BC
	DEC	HL
	DJNZ	DS7_SC1
	RET
;
; HBIOS FORMAT  = YYMMDDHHMMSS
;                 991122083100
; DS1307 FORMAT = SSMMHH..DDMMYY..
;                 003108..221199
;
;-----------------------------------------------------------------------------
; FUNCTIONS THAT ARE NOT AVAILABLE OR IMPLEMENTED
;
DS7_GETBYT:
DS7_SETBYT:
DS7_GETBLK:
DS7_SETBLK:
DS7_SETALM
DS7_GETALM
	SYSCHKERR(ERR_NOTIMPL)
	RET
;-----------------------------------------------------------------------------
; REPORT RTC DEVICE INFO
;
; THE I2C BUS ADDRESS IS REPORTED RATHER THAN THE I2C PORT ADDRESS.
; ONLY ONE CLOCK CAN BE INSTALLED IN HBIOS SO DEVICE NUMBER IS ALWAYS 0.
;
DS7_DEVICE:
	LD	D,RTCDEV_DS7		; D := DEVICE TYPE
	LD	E,0			; E := PHYSICAL DEVICE NUMBER
	LD	H,0			; H := 0, DRIVER HAS NO MODES
	LD	L,DS7_DS1307		; L := BUS ADDRESS
	XOR	A			; SIGNAL SUCCESS
	RET
;-----------------------------------------------------------------------------
; RTC READ
;
; 1.	ISSUE SLAVE ADDRESS WITH START CONDITION AND WRITE STATUS
; 2.	OUTPUT THE ADDRESS TO ACCESS. (00H = START OF DS1307 REGISTERS)
; 3.	OUTPUT REPEAT START TO TRANSITION TO READ PROCESS
; 4.	ISSUE SLAVE ADDRESS WITH READ STATUS
; 5. 	DO A DUMMY READ 
; 6.	READ 8 BYTES STARTING AT ADDRESS PREVIOUSLY SET
; 7.	END READ WITH NON-ACKNOWLEDGE
; 8.	ISSUE STOP AND RELEASE BUS 
;
DS7_RDC:LD	A,DS7_WRITE	; SET SLAVE ADDRESS
        OUT	(PCF_RS0),A
;
	CALL	PCF_WAIT_FOR_BB
	JP	NZ,PCF_BBERR
;
        CALL	PCF_START	; GENERATE START CONDITION
	CALL	PCF_WAIT_FOR_PIN; AND ISSUE THE SLAVE ADDRESS
	CALL	NZ,PCF_PINERR
;
        LD     	A,0
        OUT    	(PCF_RS0),A    	; PUT ADDRESS MSB ON BUS
	CALL	PCF_WAIT_FOR_PIN
	CALL	NZ,PCF_PINERR
;
	CALL	PCF_REPSTART    ; REPEAT START
;
        LD	A,DS7_READ	; ISSUE CONTROL BYTE + READ
        OUT	(PCF_RS0),A
;
	CALL	PCF_READI2C	; DUMMY READ
;
	LD	HL,DS7_BUF	; READ 8 BYTES INTO BUFFER
	LD	B,8
DS7_RL1:CALL	PCF_READI2C
	LD	(HL),A
	INC	HL
	DJNZ    DS7_RL1
;
#IF (0)
	LD	A,8
	LD	DE,DS7_BUF	; DISPLAY DATA READ
	CALL	PRTHEXBUF	; 
	CALL   	NEWLINE
#ENDIF
;
	LD     	A,PCF_ES0	; END WITH NOT-ACKNOWLEDGE
	OUT    	(PCF_RS1),A       ; AND RELEASE BUS
	NOP
	IN    	A,(PCF_RS0)
	NOP
DS7_WTPIN:	
	IN	A,(PCF_RS1)	; READ S1 REGISTER
	BIT	7,A		; CHECK PIN STATUS
	JP	NZ,DS7_WTPIN
	CALL   	PCF_STOP
;
	IN    	A,(PCF_RS0)
        RET
;
;-----------------------------------------------------------------------------
; SET CLOCK
;
; IF THE CLOCK IS HALTED AS IDENTIFIED BY BIT 7 REGISTER 0, THEN ASSUME THE
; CLOCK HAS NOT BEEN SET AND SO SET THE CLOCK UP WITH A DEFAULT SET OF
; VALUES AS DEFINED IN THE DS7_CLKDATA TABLE.
;
DS7_SETC:
	CALL	PCF_WAIT_FOR_BB
	JP	NZ,PCF_BBERR
;	
	LD	A,DS7_WRITE	; SET SLAVE ADDRESS
        OUT	(PCF_RS0),A
;
        CALL	PCF_START	; GENERATE START CONDITION
	CALL	PCF_WAIT_FOR_PIN; AND ISSUE THE SLAVE ADDRESS
	CALL	NZ,PCF_PINERR
;
	LD	A,00H		; REGISTER 00
        OUT    	(PCF_RS0),A    	; PUT ADDRESS ON BUS
	CALL	PCF_WAIT_FOR_PIN
	CALL	NZ,PCF_PINERR
;
	LD	DE,DS7_CLKDATA
DS7_SC:	LD	A,(DE)
	CP	0FFH
	JR	Z,DS7_ESC
        OUT     (PCF_RS0),A    	; PUT DATA ON BUS
	CALL	PCF_WAIT_FOR_ACK
	CALL	NZ,PCF_ACKERR
	INC	DE
	JR	DS7_SC
;
DS7_ESC:CALL 	PCF_STOP
	RET
;
DS7_CLKDATA:
	.DB	00H		; SECONDS
	.DB	00H		; MINUTES
	.DB     00H		; HOURS
	.DB	01H		; DAY
	.DB	01H		; DATE
	.DB	01H		; MONTH
	.DB	21H		; YEAR
        .DB     DS7_CTL		; CONTROL (00010011B)
        .DB     0FFH            ; END FLAG  
;
;-----------------------------------------------------------------------------
; DISPLAY CLOCK INFORMATION FROM DATA STORED IN BUFFER
;
DS7_DISP:
	LD	HL,DS7_CLKTBL
DS7_CLP:LD	C,(HL)
	INC	HL
	LD	D,(HL)
	CALL	DS7_BCD
	INC	HL
	LD	A,(HL)
	OR      A
	RET	Z
        CALL	COUT
	INC	HL
	JR	DS7_CLP
	RET
;
DS7_CLKTBL:
	.DB	04H, 00111111B, '/'	; DD: 31
	.DB	05H, 00011111B, '/'	; MM: 12
	.DB	06H, 11111111B, ' '	; YY: 99
	.DB	02H, 01111111B, ':'	; SS: 59
	.DB	01H, 01111111B, ':'	; MM: 59
	.DB	00H, 00111111B, 00H	; HH: 24
;
DS7_BCD:PUSH	HL
	LD      HL,DS7_BUF     	; READ VALUE FROM
	LD      B,0           	; BUFFER, INDEXED BY A 
	ADD     HL,BC
	LD      A,(HL)
	AND     D             	; MASK OFF UNNEEDED
	SRL     A
	SRL     A
	SRL     A
	SRL     A      
	ADD     A,30H
	CALL    COUT
	LD      A,(HL)    
	AND     00001111B
	ADD     A,30H
	CALL    COUT
	POP	HL
	RET
;
DS7_BUF:	.FILL	8,0				; BUFFER FOR TIME, DATE AND CONTROL
;DS7_COLD	.DB	$80,$00,$00,$01,$01,$01,$00	; COLD START RTC SETTINGS
;
