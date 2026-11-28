;__________________________________________________________________________________________________
; HARDWARE INTERFACE FOR POLLED AND INTERRUPT DRIVEN PS2 KEYBOARD.
;
; IN POLLED MODE THE CONTROLLER PORT VALUES ARE KNOWN BY THE CALLING DRIVER.
; IN INTERRUPT MODE THE DEVICES PORTS ARE UNKNOWN SO PREDEFINED PORT VALUES ARE USED.
;
; REQUIRES AN APPROPRIATE INTERRUPT JUMPER TO BE SET. 
; CURRENTLY CONFIGURED FOR INT #2 ON DUODYNE WITH I/O MULTI BOARD.
;__________________________________________________________________________________________________
;
#IF ((INTMODE == 2) & PSKINTS))
	; TODO: INTS ONLY POSSIBLE ON PSK0
;
;__________________________________________________________________________________________________
; KEYBOARD QUEUE FOR INTERRUPTS
;__________________________________________________________________________________________________
;
;
PSKQSIZ		.EQU	32		; MUST BE POWER OF TWO, <=128
PSKQGETX	.DB	0		; QUEUE INDEX
PSKQPUTX	.DB	0		; QUEUE INDEX
;		.DB	$55		; GUARD BYTE FOR DEBUGGING ; NOTE THAT SCAN CODES ARE BEING
PSKQ		.FILL	PSKQSIZ,0	; CIRCULAR KEYBOARD BUFFER ; BUFFERED. ONE KEY PRESS CAN
;		.DB	$AA		; GUARD BYTE FOR DEBUGGING ; GENERATE SEVERAL SCAN CODES
;
;__________________________________________________________________________________________________
; RESET THE QUEUE TO EMPTY
;__________________________________________________________________________________________________
;
;PSKQINIT: 
;	XOR	A
;	LD	(PSKQGETX),A
;	LD	(PSKQPUTX),A
;	RET
;
;__________________________________________________________________________________________________
; KEYBOARD INTERRUPT VECTOR
;__________________________________________________________________________________________________
;
PSK_INT:
;	CALL	PSKQDBG
	LD	IY,PSK_IDAT		; POINT TO INSTANCE DATA
;
	CALL	PSK_IST_P		; READ CONTROLLER STATUS
	RET	Z			; EXIT IF NOTHINGTO READ
	LD	C,(IY+PSK_DAT)
	EZ80_IO				; IF SOMETHING PENDING
	IN	A,(C)			; READ THE BYTE IN
	LD	B,A			; AND SAVE IT
;
	CALL	PSKQLEN			; CHECK IF 
	SUB	PSKQSIZ			; QUEUE IS FULL
	RET	Z			; EXIT IF THE QUEUE IS FULL
;
	LD	HL,PSKQPUTX		; CREATE QUEUE INDEX
	CALL	PSK_Q_IDX		; POINTER IN HL
;
	LD	(HL),A			; SAVE THE CHARACTER IN THE QUEUE
;	CALL	PSKQDBG
;
	RET
#ENDIF
;
;__________________________________________________________________________________________________
; KEYBOARD READ
;__________________________________________________________________________________________________
;
; READ DIRECT FROM PORT
;
PSK_IN_P:
	LD	C,(IY+PSK_DAT)		; DATA PORT
	EZ80_IO
	IN	A,(C)			; GET THE DATA VALUE
	RET
;
; READ FROM INTERRUPT QUEUE
;
#IF ((INTMODE == 2) & PSKINTS))
	; TODO: INTS ONLY POSSIBLE ON PSK0
;
PSK_IN_Q:
PSKQPOP:
	CALL	PSKQLEN
	RET	Z			; EXIT IF THE QUEUE IS EMPTY
;
	LD	HL,PSKQGETX		; CREATE QUEUE INDEX
	CALL	PSK_Q_IDX		; POINTER IN HL
;
	LD	A,(HL)			; GET THE CHARACTER FROM THE QUEUE
;	LD	(HL),B			; DEBUG - CLEAN QUEUE
;
	RET

PSK_Q_IDX:
	LD	A,(HL)			; CREATE QUEUE INDEX
	AND	PSKQSIZ-1
	INC	(HL)			; UPDATE INDEX
	LD	HL,PSKQ			; INDEX INTO THE QUEUE
	LD	C,A
	LD	A,B			; NOTE THE QUEUE GET
	LD	B,0			; AND PUT INDEXES
	ADD	HL,BC			; NEVER DECREASE
	RET
;
#ENDIF
;
#IF ((INTMODE == 2) & PSKINTS))
	; TODO: INTS ONLY POSSIBLE ON PSK0
PSK_IN	.EQU	PSK_IN_Q
#ELSE
PSK_IN	.EQU	PSK_IN_P
#ENDIF
;
;__________________________________________________________________________________________________
; KEYBOARD INPUT STATUS
;__________________________________________________________________________________________________
;
; DIRECT PORT STATUS READ
;
PSK_IST_P:
	LD	C,(IY+PSK_ST)		; STATUS PORT
	EZ80_IO
	IN	A,(C)			; GET STATUS
	AND	$01			; ISOLATE INPUT PENDING BIT
	RET
;
; STATUS FROM INTERRUPT QUEUE
;
#IF ((INTMODE == 2) & PSKINTS))
	; TODO: INTS ONLY POSSIBLE ON PSK0
;
PSK_IST_Q:
PSKQLEN:				; EXIT WITH NUMBER OF CHARACTERS IN QUEUE
	LD	A,(PSKQPUTX)		; Z STATUS AND ZERO IF NONE 
	LD	HL,PSKQGETX
	SUB	(HL)
	RET
;
#ENDIF
;
; 	RETURN INDICATION OF KEYBOARD DATA READY
;
#IF ((INTMODE == 2) & PSKINTS))
	; TODO: INTS ONLY POSSIBLE ON PSK0
PSK_IST	.EQU	PSK_IST_Q
#ELSE
PSK_IST	.EQU	PSK_IST_P
#ENDIF
;
;__________________________________________________________________________________________________
; OUTPUT TO KEYBOARD COMMAND PORT
;__________________________________________________________________________________________________
;
PSK_CMDOUT:
	LD	C,(IY+PSK_CMD)		; COMMAND PORT
	EZ80_IO
	OUT	(C),A	
	RET
;__________________________________________________________________________________________________
; OUTPUT TO KEYBOARD COMMAND DATA
;__________________________________________________________________________________________________
;
PSK_DTAOUT:
	LD	C,(IY+PSK_DAT)		; DATA PORT
	EZ80_IO
	OUT	(C),A
	RET
;__________________________________________________________________________________________________
; KEYBOARD OUTPUT STATUS - A=0, Z SET FOR NOT READY, OTHERWISE READY TO WRITE
;__________________________________________________________________________________________________
;
PSK_OST:
	LD	C,(IY+PSK_ST)		; STATUS PORT
	EZ80_IO
	IN	A,(C)			; GET STATUS
	AND	$02			; ISOLATE OUTPUT EMPTY BIT
	XOR	$02			; FLIP IT FOR APPROPRIATE RETURN VALUES
	RET
;
;__________________________________________________________________________________________________
; DEBUG QUEUE
;__________________________________________________________________________________________________
;
#IF ((INTMODE == 2) & PSKINTS & 0)
	; TODO: INTS ONLY POSSIBLE ON PSK0
PSKQDBG:
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF

	CALL	NEWLINE			; PRINT QUEUE CONTENTS
	LD	B,PSKQSIZ		; +2 PRE AND POST GUARD BYTES
	LD	HL,PSKQ			; -1 PRE AND POST GUARD BYTES
PSKQPRT:
	LD	A,(HL)
	CALL	PRTHEXBYTE
	INC	HL
	DJNZ	PSKQPRT

	LD	A,' '			; PRINT QUEUE INDEX
	CALL	COUT
	LD	A,(PSKQGETX)
	AND	PSKQSIZ-1
	CALL	PRTHEXBYTE

	LD	A,' '			; PRINT QUEUE INDEX
	CALL	COUT
	LD	A,(PSKQPUTX)
	AND	PSKQSIZ-1
	CALL	PRTHEXBYTE

	LD	A,' '			; PRINT # SCAN CODES IN QUEUE
	CALL	COUT
	CALL	PSKQLEN
	CALL	PRTHEXBYTE
	CALL	NEWLINE

	POP	AF
	POP	BC
	POP	DE
	POP	HL
	RET
#ENDIF
