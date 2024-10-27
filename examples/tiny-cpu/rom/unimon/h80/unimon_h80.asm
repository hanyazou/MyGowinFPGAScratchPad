;;; 
;;; Universal Monitor for H80
;;;   Copyright (C) 2019,2020,2021 Haruo Asano
;;;

	CPU	H80

TARGET:	equ	"H80"


	INCLUDE	"config.inc"

	INCLUDE	"../common.inc"

	
;;; 
;;; ROM area
;;;

	ORG	0000H
        ;; DI
	JP	CSTART

	ORG	0008H


	ORG	0010H
	JP	CONIN

	ORG	0018H
	JP	CONOUT

	;; ORG	0020H
	;; JP	EEREAD

	;; ORG	0028H
	;; JP	EEWRITE

	IF 0                    ; XXX

	ORG	0030H
	JP	RST30H

	ORG	0038H
	JP	RST38H

	;;
	;; Entry point
	;;

	ORG	ENTRY+0		; Cold start
E_CSTART:
	JP	CSTART
	
	ORG	ENTRY+8		; Warm start
E_WSTART:
	JP	WSTART

	ORG	ENTRY+16	; Console output
E_CONOUT:
	JP	CONOUT

	ORG	ENTRY+24	; (Console) String output
E_STROUT:
	JP	STROUT

	ORG	ENTRY+32	; Console input
E_CONIN:
	JP	CONIN

	ORG	ENTRY+40	; Console status
E_CONST:
	JP	CONST

	ENDIF                   ; XXX

	;;
	;;
	;; 

	ORG	0100H
CSTART:
	LD	tmp,STACK
	LD	SP,tmp

	IF USE_SPINIT
	SPINIT
	ENDIF

	;; DRAM warming up
	IF USE_WARMUP

	LD	HL,WARMUP_ADDR
	IF WARMUP_INCR > 1
	LD	DE,WARMUP_INCR
	ENDIF
	LD	BC,WARMUP_CNT
WU0:
	LD	A,(HL)
	IF WARMUP_INCR == 1
	INC	HL
	ENDIF
	IF WARMUP_INCR > 1
	ADD	HL,DE
	ENDIF
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,WU0

	ENDIF

	;; Check RAM
	IF USE_RAMCHK

	LD	DE,RAM_B
	LD	HL,RAM_B+1
RC0:
	LD	A,(HL)
	LD	B,A
	CPL
	LD	(HL),A
	CP	(HL)
	JR	NZ,RC1		; Unwritable
	LD	A,(DE)
	CP	(HL)
	JR	NZ,RC2
	LD	(HL),B
	LD	A,(DE)
	CP	(HL)
	JR	NZ,RC2
RC1:	
	;; (HL) and (DE) points same memory or (HL) points no memory
	LD	(RAMEND),HL
	JR	RCE
RC2:
	LD	(HL),B
	INC	HL
	LD	A,H
	OR	L
	JR	NZ,RC0
	LD	(RAMEND),HL
RCE:	
	ENDIF
	
	IF 0                    ; XXX

	;; CPU identification
	XOR	A
	LD	(PSPEC),A

	IF USE_IDENT
	LD	BC,00FFH
	DB	0EDH,4CH	; MLT BC (HD64180)
	LD	A,B
	OR	C
	JR	Z,ID_180
	LD	A,40H
	DB	0CBH,37H	; TEST A (Z280)
	JP	P,ID_280
	LD	A,7FH
	LD	R,A
	LD	A,R
	JP	M,ID_NSC
	;; Z80
	LD	HL,IM80
	XOR	A
	JP	IDE
	;; HD64180
	SAVE			; HD64180 specific initialization
	CPU	Z180
ID_180:
	LD	A,IOBASE
	OUT0	(3FH),A
	LD	A,DCNTL_V
	OUT0	(IOBASE+32H),A
	LD	A,RMR_V
	OUT0	(IOBASE+36H),A
	LD	A,7FH		; Try to change OMCR bit 7 to 0
	OUT0	(IOBASE+3EH),A
	IN0	A,(IOBASE+3EH)
	AND	80H
	JR	Z,ID_180Z	; HD64180Z detected

	LD	HL,IM180
	LD	A,01H
	JR	IDE
	;; HD64180Z
ID_180Z:
	LD	A,OMCR_V
	OUT0	(IOBASE+3EH),A
	XOR	A
	OUT0	(IOBASE+12H),A
	IN0	A,(IOBASE+12H)
	AND	40H
	JR	Z,ID_Z8S	; Z8S180 (SL1919) detected

	XOR	A
	OUT0	(IOBASE+1FH),A
	IN0	A,(IOBASE+1FH)
	OR	A
	JR	Z,ID_1960	; Z8S180 (SL1960) detected
	
	LD	HL,IM180Z
	LD	A,02H
	JR	IDE
	;; Z8S180 (SL1960)
ID_1960:
	LD	A,CCR1_V
	OUT0	(IOBASE+1FH),A
	LD	HL,IM1960
	LD	A,04H
	JR	IDE
	
	;; Z8S180
ID_Z8S:
	LD	A,CCR1_V
	OUT0	(IOBASE+1FH),A
	LD	HL,IMZ8S
	LD	A,05H
	JR	IDE

	RESTORE
	;; Z280
ID_280:
	LD	L,BTCR_V	; Z280 specific initialization
	LD	C,02H		; BTCR
	DB	0EDH,6EH	; LDCTL (C),HL
	LD	L,BTIR_V
	LD	C,0FFH		; BTIR
	DB	0EDH,6EH	; LDCTL (C),HL
	LD	L,CCR_V
	LD	C,12H		; CCR
	DB	0EDH,6EH	; LDCTL (C),HL

	LD	L,0FFH
	LD	C,08H		; IOBR
	DB	0EDH,6EH	; LDCTL (C),HL
	LD	A,RRR_V
	OUT	(0E8H),A	; RRR
	LD	L,00H
	LD	C,08H
	DB	0EDH,6EH	; LDCTL (C),HL

	LD	HL,IM280
	LD	A,08H
	JR	IDE
	;; NSC800
ID_NSC:	
	LD	HL,IMNSC
	LD	A,09H
IDE:
	LD	(PSPEC),A
	LD	(INBUF),HL
	ENDIF			; USE_IDENT

	ENDIF                   ; XXX

	CALL    INIT

	LD.W	tmp,8000H
	LD.W	(DSADDR),tmp
	LD.W	(SADDR),tmp
	LD.W	(GADDR),tmp
	LD	tmp,'I'
	LD.B	(HEXMOD),tmp
	XOR	tmp,tmp
	LD.B	(IOPAGE),tmp

	IF USE_REGCMD

	;; Initialize register value
	XOR	A
	LD	HL,REG_B
	LD	B,REG_E-REG_B
IR0:
	LD	(HL),A
	INC	HL
	DJNZ	IR0

	LD	HL,STACK
	LD	(REGSP),HL

	ENDIF

	LD	v0,100
TL:	
	XOR	arg0,arg0
	CALL	CONOUT
	DJNZ	v0,TL
	
	;; Opening message
	LD	arg0,OPNMSG
	CALL	STROUT

	IF USE_IDENT
	LD	HL,(INBUF)
	CALL	STROUT
	ENDIF

	IF USE_RAMCHK
	LD	HL,RAM_B
	CALL	HEXOUT4
	LD	A,'-'
	CALL	CONOUT
	LD	HL,(RAMEND)
	DEC	HL
	CALL	HEXOUT4
	CALL	CRLF
	ENDIF

WSTART:
	LD	arg0,PROMPT
	CALL	STROUT
	HALT
	IF 0                    ; XXX

	CALL	GETLIN
	LD	HL,INBUF
	CALL	SKIPSP
	CALL	UPPER
	OR	A
	JR	Z,WSTART

	CP	'D'
	JR	Z,DUMP
	CP	'G'
	JP	Z,GO
	CP	'S'
	JP	Z,SETM

	CP	'L'
	JP	Z,LOADH
	CP	'P'
	JP	Z,SAVEH

	CP	'I'
	JP	Z,PIN
	CP	'O'
	JP	Z,POUT
	CP	'Z'
	JP	Z,PBANK

	IF USE_REGCMD
	CP	'R'
	JP	Z,REG
	ENDIF

ERR:
	LD	HL,ERRMSG
	CALL	STROUT
	JR	WSTART

;;; 
;;; Dump memory
;;; 

DUMP:
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX		; 1st arg.
	LD	A,C
	OR	A
	JR	NZ,DP0
	;; No arg.
	CALL	SKIPSP
	LD	A,(HL)
	OR	A
	JR	NZ,ERR
	LD	HL,(DSADDR)
	LD	BC,128
	ADD	HL,BC
	LD	(DEADDR),HL
	JR	DPM

	;; 1st arg. found
DP0:
	LD	(DSADDR),DE
	CALL	SKIPSP
	LD	A,(HL)
	CP	','
	JR	Z,DP1
	OR	A
	JR	NZ,ERR
	;; No 2nd arg.
	LD	HL,128
	ADD	HL,DE
	LD	(DEADDR),HL
	JR	DPM
DP1:
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	LD	A,C
	OR	A
	JR	Z,ERR
	LD	A,(HL)
	OR	A
	JP	NZ,ERR
	INC	DE
	LD	(DEADDR),DE
DPM:
	;; DUMP main
	LD	HL,(DSADDR)
	LD	A,0F0H
	AND	A,L
	LD	L,A
	XOR	A
	LD	(DSTATE),A
DPM0:
	PUSH	HL
	CALL	DPL
	POP	HL
	LD	BC,16
	ADD	HL,BC
	CALL	CONST
	JR	NZ,DPM1
	LD	A,(DSTATE)
	CP	2
	JR	C,DPM0
	LD	HL,(DEADDR)
	LD	(DSADDR),HL
	JP	WSTART
DPM1:
	LD	(DSADDR),HL
	CALL	CONIN
	JP	WSTART

DPL:
	;; DUMP line
	CALL	HEXOUT4
	PUSH	HL
	LD	HL,DSEP0
	CALL	STROUT
	POP	HL
	LD	IX,INBUF
	LD	B,16
DPL0:
	CALL	DPB
	DJNZ	DPL0

	LD	HL,DSEP1
	CALL	STROUT

	LD	HL,INBUF
	LD	B,16
DPL1:
	LD	A,(HL)
	INC	HL
	CP	' '
	JR	C,DPL2
	CP	7FH
	JR	NC,DPL2
	CALL	CONOUT
	JR	DPL3
DPL2:
	LD	A,'.'
	CALL	CONOUT
DPL3:
	DJNZ	DPL1
	JP	CRLF

DPB:	; Dump byte
	LD	A,' '
	CALL	CONOUT
	LD	A,(DSTATE)
	OR	A
	JR	NZ,DPB2
	; Dump state 0
	LD	A,(DSADDR)	; Low byte
	CP	L
	JR	NZ,DPB0
	LD	A,(DSADDR+1)	; High byte
	CP	H
	JR	Z,DPB1
DPB0:	; Still 0 or 2
	LD	A,' '
	CALL	CONOUT
	CALL	CONOUT
	LD	(IX),A
	INC	HL
	INC	IX
	RET
DPB1:	; Found start address
	LD	A,1
	LD	(DSTATE),A
DPB2:
	LD	A,(DSTATE)
	CP	1
	JR	NZ,DPB0
	; Dump state 1
	LD	A,(HL)
	LD	(IX),A
	CALL	HEXOUT2
	INC	HL
	INC	IX
	LD	A,(DEADDR)	; Low byte
	CP	L
	RET	NZ
	LD	A,(DEADDR+1)	; High byte
	CP	H
	RET	NZ
	; Found end address
	LD	A,2
	LD	(DSTATE),A
	RET

;;;
;;; GO address
;;; 

GO:
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX
	LD	A,(HL)
	OR	A
	JP	NZ,ERR
	LD	A,C
	OR	A
	JR	Z,G0

	IF USE_REGCMD

	LD	(REGPC),DE
G0:
	;; R register adjustment
	IF USE_IDENT
	LD	A,(PSPEC)
	CP	08H		; Z280
	JR	Z,G1
	CP	09H		; NSC800
	JR	Z,G01
	LD	A,(REGR)
	SUB	02H
	AND	7FH
	LD	B,A
	LD	A,(REGR)
	AND	80H
	OR	B
	LD	(REGR),A
	JR	G1
G01:
	LD	A,(REGR)
	SUB	02H
	LD	(REGR),A
G1:
	ENDIF
	
	LD	HL,(REGSP)
	LD	SP,HL
	LD	HL,(REGPC)
	PUSH	HL
	LD	IX,(REGIX)
	LD	IY,(REGIY)
	LD	HL,(REGAFX)
	PUSH	HL
	LD	BC,(REGBCX)
	LD	DE,(REGDEX)
	LD	HL,(REGHLX)
	EXX
	POP	AF
	EX	AF,AF'
	LD	HL,(REGAF)
	PUSH	HL
	LD	BC,(REGBC)
	LD	DE,(REGDE)
	LD	HL,(REGHL)
	LD	A,(REGI)
	LD	I,A
	LD	A,(REGR)
	LD	R,A
	POP	AF
	RET			; POP PC

	ELSE
	
	LD	(GADDR),DE
G0:
	LD	HL,(GADDR)
	JP	(HL)

	ENDIF

;;;
;;; SET memory
;;; 

SETM:
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	LD	A,(HL)
	OR	A
	JP	NZ,ERR
	LD	A,C
	OR	A
	JR	NZ,SM0
	LD	DE,(SADDR)
SM0:
	EX	DE,HL
SM1:
	CALL	HEXOUT4
	PUSH	HL
	LD	HL,DSEP1
	CALL	STROUT
	POP	HL
	LD	A,(HL)
	PUSH	HL
	CALL	HEXOUT2
	LD	A,' '
	CALL	CONOUT
	CALL	GETLIN
	LD	HL,INBUF
	CALL	SKIPSP
	LD	A,(HL)
	OR	A
	JR	NZ,SM2
	;; Empty  (Increment address)
	POP	HL
	INC	HL
	LD	(SADDR),HL
	JR	SM1
SM2:
	CP	'-'
	JR	NZ,SM3
	;; '-'  (Decrement address)
	POP	HL
	DEC	HL
	LD	(SADDR),HL
	JR	SM1
SM3:
	CP	'.'
	JR	NZ,SM4
	POP	HL
	LD	(SADDR),HL
	JP	WSTART
SM4:
	CALL	RDHEX
	LD	A,C
	OR	A
	POP	HL
	JP	Z,ERR
	LD	(HL),E
	INC	HL
	LD	(SADDR),HL
	JR	SM1

;;;
;;; LOAD HEX file
;;;

LOADH:
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	LD	A,(HL)
	OR	A
	JP	NZ,ERR

	LD	A,C
	OR	A
	JR	NZ,LH0

	LD	DE,0		;Offset
LH0:
	CALL	CONIN
	CALL	UPPER
	CP	'S'
	JR	Z,LHS0
LH1:
	CP	':'
	JR	Z,LHI0
LH2:
	;; Skip to EOL
	CP	CR
	JR	Z,LH0
	CP	LF
	JR	Z,LH0
LH3:
	CALL	CONIN
	JR	LH2

LHI0:
	CALL	HEXIN
	LD	C,A		; Checksum
	LD	B,A		; Length

	CALL	HEXIN
	LD	H,A		; Address H
	ADD	A,C
	LD	C,A

	CALL	HEXIN
	LD	L,A		; Address L
	ADD	A,C
	LD	C,A

	;; Add offset
	ADD	HL,DE

	CALL	HEXIN
	LD	(RECTYP),A
	ADD	A,C
	LD	C,A		; Checksum

	LD	A,B
	OR	A
	JR	Z,LHI3
LHI1:
	CALL	HEXIN
	PUSH	AF
	ADD	A,C
	LD	C,A		; Checksum

	LD	A,(RECTYP)
	OR	A
	JR	NZ,LHI20

	POP	AF
	LD	(HL),A
	INC	HL
	JR	LHI2
LHI20:
	POP	AF
LHI2:
	DJNZ	LHI1
LHI3:
	CALL	HEXIN
	ADD	A,C
	JR	NZ,LHIE		; Checksum error
	LD	A,(RECTYP)
	OR	A
	JP	Z,LH3
	JP	WSTART
LHIE:
	LD	HL,IHEMSG
	CALL	STROUT
	JP	WSTART
	
LHS0:
	CALL	CONIN
	LD	(RECTYP),A

	CALL	HEXIN
	LD	B,A		; Length+3
	LD	C,A		; Checksum

	CALL	HEXIN
	LD	H,A
	ADD	A,C
	LD	C,A
	
	CALL	HEXIN
	LD	L,A
	ADD	A,C
	LD	C,A

	ADD	HL,DE

	DEC	B
	DEC	B
	DEC	B
	JR	Z,LHS3
LHS1:
	CALL	HEXIN
	PUSH	AF
	ADD	A,C
	LD	C,A		; Checksum

	LD	A,(RECTYP)
	CP	'1'
	JR	NZ,LHS2

	POP	AF
	LD	(HL),A
	INC	HL
	JR	LHS20
LHS2:
	POP	AF
LHS20:
	DJNZ	LHS1
LHS3:
	CALL	HEXIN
	ADD	A,C
	CP	0FFH
	JR	NZ,LHSE

	LD	A,(RECTYP)
	CP	'7'
	JR	Z,LHSR
	CP	'8'
	JR	Z,LHSR
	CP	'9'
	JR	Z,LHSR
	JP	LH3
LHSE:
	LD	HL,SHEMSG
	CALL	STROUT
LHSR:
	JP	WSTART
	
;;;
;;; SAVE HEX file
;;;

SAVEH:
	INC	HL
	LD	A,(HL)
	CALL	UPPER
	CP	'I'
	JR	Z,SH0
	CP	'S'
	JR	NZ,SH1
SH0:
	INC	HL
	LD	(HEXMOD),A
SH1:
	CALL	SKIPSP
	CALL	RDHEX
	LD	A,C
	OR	A
	JR	Z,SHE
	PUSH	DE
	POP	IX		; IX = Start address
	CALL	SKIPSP
	LD	A,(HL)
	CP	','
	JR	NZ,SHE
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX		; DE = End address
	LD	A,C
	OR	A
	JR	Z,SHE
	CALL	SKIPSP
	LD	A,(HL)
	OR	A
	JR	Z,SH2
SHE:
	JP	ERR

SH2:
	PUSH	IX
	POP	HL
	EX	DE,HL
	INC	HL
	OR	A
	SBC	HL,DE		; HL = Length
SH3:
	CALL	SHL
	LD	A,H
	OR	L
	JR	NZ,SH3

	LD	A,(HEXMOD)
	CP	'I'
	JR	NZ,SH4
	;; End record for Intel HEX
	LD	HL,IHEXER
	CALL	STROUT
	JP	WSTART
SH4:
	;; End record for Motorola S record
	LD	HL,SRECER
	CALL	STROUT
	JP	WSTART

SHL:
	LD	C,16
	LD	A,H
	OR	A
	JR	NZ,SHL0
	LD	A,L
	CP	C
	JR	NC,SHL0
	LD	C,A
SHL0:
	LD	B,0
	OR	A
	SBC	HL,BC
	LD	B,C

	LD	A,(HEXMOD)
	CP	'I'
	JR	NZ,SHLS

	;; Intel HEX
	LD	A,':'
	CALL	CONOUT

	LD	A,B
	CALL	HEXOUT2		; Length
	LD	C,B		; Checksum

	LD	A,D
	CALL	HEXOUT2
	LD	A,D
	ADD	A,C
	LD	C,A
	
	LD	A,E
	CALL	HEXOUT2
	LD	A,E
	ADD	A,C
	LD	C,A
	
	XOR	A
	CALL	HEXOUT2
SHLI0:
	LD	A,(DE)
	PUSH	AF
	CALL	HEXOUT2
	POP	AF
	ADD	A,C
	LD	C,A

	INC	DE
	DJNZ	SHLI0

	LD	A,C
	NEG	A
	CALL	HEXOUT2
	JP	CRLF

SHLS:
	;; Motorola S record
	LD	A,'S'
	CALL	CONOUT
	LD	A,'1'
	CALL	CONOUT

	LD	A,B
	ADD	A,2+1		; DataLength + 2(Addr) + 1(Sum)
	LD	C,A
	CALL	HEXOUT2

	LD	A,D
	CALL	HEXOUT2
	LD	A,D
	ADD	A,C
	LD	C,A
	
	LD	A,E
	CALL	HEXOUT2
	LD	A,E
	ADD	A,C
	LD	C,A
SHLS0:
	LD	A,(DE)
	PUSH	AF
	CALL	HEXOUT2		; Data
	POP	AF
	ADD	A,C
	LD	C,A

	INC	DE
	DJNZ	SHLS0

	LD	A,C
	CPL
	CALL	HEXOUT2
	JP	CRLF

;;;
;;; Port in
;;; 

PIN:
	INC	HL
	XOR	A
	LD	(SIZE),A
	LD	A,(PSPEC)
	CP	08H		; Z280
	JR	NZ,PI1
	LD	A,(HL)
	CALL	UPPER
	CP	'W'
	JR	Z,PI0
	CP	'S'
	JR	NZ,PI1
PI0:
	INC	HL
	LD	(SIZE),A
PI1:
	CALL	SKIPSP
	CALL	RDHEX
	LD	A,C
	OR	A
	JP	Z,ERR		; Port no. missing
	CALL	SKIPSP
	LD	A,(HL)
	OR	A
	JP	NZ,ERR

	LD	B,D
	LD	C,E

	LD	A,(SIZE)
	CP	'W'
	JR	Z,PIW
	CP	'S'
	JR	Z,PIS
	LD	A,(PSPEC)
	CP	08H		; Z280
	JR	Z,PIB
	;; Byte
	IN	A,(C)
	CALL	HEXOUT2
	CALL	CRLF
	JP	WSTART
	;; Byte (Z280 only)
PIB:
	LD	C,08		; I/O Bank register
	DB	0EDH,66H	; LDCTL HL,(C)
	PUSH	HL
	LD	A,(IOPAGE)
	LD	L,A
	DB	0EDH,6EH	; LDCTL (C),HL
	LD	C,E
	IN	A,(C)
	LD	C,08H		; I/O Bank register
	POP	HL
	DB	0EDH,6EH	; LDCTL (C),HL
	CALL	HEXOUT2
	CALL	CRLF
	JP	WSTART
	;; Word (Z280 only)
PIW:
	LD	C,08		; I/O Bank register
	DB	0EDH,66H	; LDCTL HL,(C)
	PUSH	HL
	LD	A,(IOPAGE)
	LD	L,A
	DB	0EDH,6EH	; LDCTL (C),HL
	LD	C,E
	DB	0EDH,0B7H	; IN HL,(C)
	EX	(SP),HL
	LD	C,08H
	DB	0EDH,6EH	; LDCTL (C),HL
	POP	HL
	CALL	HEXOUT4
	CALL	CRLF
	JP	WSTART
	;; Status (Z280 only)
PIS:
	DB	0EDH,66H	; LDCTL HL,(C)
	CALL	HEXOUT4
	CALL	CRLF
	JP	WSTART

;;;
;;; Port out
;;;

POUT:
	INC	HL
	XOR	A
	LD	(SIZE),A
	LD	A,(PSPEC)
	CP	08H		; Z280
	JR	NZ,PO1
	LD	A,(HL)
	CALL	UPPER
	CP	'W'
	JR	Z,PO0
	CP	'S'
	JR	NZ,PO1
PO0:
	INC	HL
	LD	(SIZE),A
PO1:
	CALL	SKIPSP
	CALL	RDHEX
	LD	A,C
	OR	A
	JP	Z,ERR		; Port no. missing
	PUSH	DE
	POP	IX
	CALL	SKIPSP
	LD	A,(HL)
	CP	','
	JP	NZ,ERR
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX
	LD	A,C
	OR	A
	JP	Z,ERR		; Data missing
	CALL	SKIPSP
	LD	A,(HL)
	OR	A
	JP	NZ,ERR

	PUSH	IX
	POP	BC

	LD	A,(SIZE)
	CP	'W'
	JR	Z,POW
	CP	'S'
	JR	Z,POS
	LD	A,(PSPEC)
	CP	08H		; Z280
	JR	Z,POB
	;; Byte
	OUT	(C),E
	JP	WSTART
	;; Byte (Z280 only)
POB:
	PUSH	BC
	LD	C,08		; I/O Bank register
	DB	0EDH,66H	; LDCTL HL,(C)
	LD	D,L
	LD	A,(IOPAGE)
	LD	L,A
	DB	0EDH,6EH	; LDCTL (C),HL
	POP	BC
	OUT	(C),E
	LD	C,08H		; I/O Bank register
	LD	L,D
	DB	0EDH,6EH	; LDCTL (C),HL
	JP	WSTART	
	;; Word (Z280 only)
POW:
	DB	0DDH,69H	; LD IXL,C
	LD	C,08		; I/O Bank register
	DB	0EDH,66H	; LDCTL HL,(C)
	PUSH	HL
	LD	A,(IOPAGE)
	LD	L,A
	DB	0EDH,6EH	; LDCTL (C),HL
	DB	0DDH,4DH	; LD C,IXL
	EX	DE,HL
	DB	0EDH,0BFH	; OUT (C),HL
	LD	C,08H		; I/O Bank register
	POP	HL
	DB	0EDH,6EH	; LDCTL (C),HL
	JP	WSTART
	;; Control (Z280 only)
POS:
	EX	DE,HL
	DB	0EDH,6EH	; LDCTL (C),HL
	JP	WSTART

;;;
;;; I/O Bank
;;;

PBANK:
	LD	A,(PSPEC)
	CP	08H		; Z280
	JP	NZ,ERR
	INC	HL
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	LD	A,(HL)
	OR	A
	JP	NZ,ERR
	LD	A,C
	OR	A
	JR	Z,PB0
	LD	A,E
	LD	(IOPAGE),A
	JP	WSTART
PB0:
	LD	A,(IOPAGE)
	CALL	HEXOUT2
	CALL	CRLF
	JP	WSTART

;;;
;;; Register
;;;

	IF USE_REGCMD

REG:
	INC	HL
	CALL	SKIPSP
	CALL	UPPER
	OR	A
	JR	NZ,RG0
	CALL	RDUMP
	JP	WSTART
RG0:
	EX	DE,HL
	LD	HL,RNTAB
RG1:
	CP	(HL)
	JR	Z,RG2		; Character match
	LD	C,A
	INC	HL
	LD	A,(HL)
	OR	A
	JR	Z,RGE		; Found end mark
	LD	A,C
	LD	BC,5
	ADD	HL,BC		; Next entry
	JR	RG1
RG2:
	INC	HL
	LD	A,(HL)
	CP	0FH		; Link code
	JR	NZ,RG3
	;; Next table
	INC	HL
	LD	C,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,C
	INC	DE
	LD	A,(DE)
	CALL	UPPER
	JR	RG1
RG3:
	OR	A
	JR	Z,RGE		; Found end mark

	LD	C,(HL)		; LD C,A???
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	PUSH	DE		; Reg storage address
	INC	HL
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A		; HL: Reg name
	CALL	STROUT
	LD	A,'='
	CALL	CONOUT

	LD	A,C
	AND	07H
	CP	1
	JR	NZ,RG4
	;; 8 bit register
	POP	HL
	LD	A,(HL)
	PUSH	HL
	CALL	HEXOUT2
	JR	RG5
RG4:
	;; 16 bit register
	POP	HL
	PUSH	HL
	INC	HL
	LD	A,(HL)
	CALL	HEXOUT2
	DEC	HL
	LD	A,(HL)
	CALL	HEXOUT2
RG5:
	LD	A,' '
	CALL	CONOUT
	PUSH	BC		; C: reg size
	CALL	GETLIN
	LD	HL,INBUF
	CALL	SKIPSP
	CALL	RDHEX
	LD	A,C
	OR	A
	JR	Z,RGR
	POP	BC
	POP	HL
	LD	A,C
	CP	1
	JR	NZ,RG6
	;; 8 bit register
	LD	(HL),E
	JR	RG7
RG6:
	;; 16 bit register
	LD	(HL),E
	INC	HL
	LD	(HL),D
RG7:
RGR:
	JP	WSTART
RGE:
	JP	ERR

RDUMP:
	LD	HL,RDTAB
RD0:
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,D
	OR	E
	JP	Z,CRLF		; End
	EX	DE,HL
	CALL	STROUT
	EX	DE,HL

	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,(HL)
	INC	HL
	EX	DE,HL
	CP	1
	JR	NZ,RD1
	;; 1 byte
	LD	A,(HL)
	CALL	HEXOUT2
	EX	DE,HL
	JR	RD0
RD1:
	;; 2 byte
	INC	HL
	LD	A,(HL)
	CALL	HEXOUT2		; High byte
	DEC	HL
	LD	A,(HL)
	CALL	HEXOUT2		; Low byte
	EX	DE,HL
	JR	RD0

	ENDIF

	ENDIF                   ; XXX

;;;
;;; Other support routines
;;;

STROUT:
	LD.B	tmp,(arg0)
	AND	tmp,tmp
	RET	Z
	PUSH	arg0
	LD	arg0,tmp
	CALL	CONOUT
	POP	arg0
	ADD	arg0,1
	JR	STROUT

	IF 0                    ; XXX

HEXOUT4:
	LD	A,H
	CALL	HEXOUT2
	LD	A,L
HEXOUT2:
	PUSH	AF
	RRA
	RRA
	RRA
	RRA
	CALL	HEXOUT1
	POP	AF
HEXOUT1:
	AND	0FH
	ADD	A,'0'
	CP	'9'+1
	JP	C,CONOUT
	ADD	A,'A'-'9'-1
	JP	CONOUT

HEXIN:
	XOR	A
	CALL	HI0
	RLCA
	RLCA
	RLCA
	RLCA
HI0:
	PUSH	BC
	LD	C,A
	CALL	CONIN
	CALL	UPPER
	CP	'0'
	JR	C,HIR
	CP	'9'+1
	JR	C,HI1
	CP	'A'
	JR	C,HIR
	CP	'F'+1
	JR	NC,HIR
	SUB	A,'A'-'9'-1
HI1:
	SUB	A,'0'
	OR	C
HIR:
	POP	BC
	RET
	
CRLF:
	LD	A,CR
	CALL	CONOUT
	LD	A,LF
	JP	CONOUT

GETLIN:
	LD	HL,INBUF
	LD	B,0
GL0:
	CALL	CONIN
	CP	CR
	JR	Z,GLE
	CP	LF
	JR	Z,GLE
	CP	BS
	JR	Z,GLB
	CP	DEL
	JR	Z,GLB
	CP	' '
	JR	C,GL0
	CP	80H
	JR	NC,GL0
	LD	C,A
	LD	A,B
	CP	BUFLEN-1
	JR	NC,GL0	; Too long
	INC	B
	LD	A,C
	CALL	CONOUT
	LD	(HL),A
	INC	HL
	JR	GL0
GLB:
	LD	A,B
	AND	A
	JR	Z,GL0
	DEC	B
	DEC	HL
	LD	A,08H
	CALL	CONOUT
	LD	A,' '
	CALL	CONOUT
	LD	A,08H
	CALL	CONOUT
	JR	GL0
GLE:
	CALL	CRLF
	LD	(HL),00H
	RET

SKIPSP:
	LD	A,(HL)
	CP	A,' '
	RET	NZ
	INC	HL
	JR	SKIPSP

UPPER:
	CP	'a'
	RET	C
	CP	'z'+1
	RET	NC
	ADD	A,'A'-'a'
	RET

RDHEX:
	LD	C,0
	LD	DE,0
RH0:
	LD	A,(HL)
	CALL	UPPER
	CP	'0'
	JR	C,RHE
	CP	'9'+1
	JR	C,RH1
	CP	'A'
	JR	C,RHE
	CP	'F'+1
	JR	NC,RHE
	SUB	'A'-'9'-1
RH1:
	SUB	'0'
	RLA
	RLA
	RLA
	RLA
	RLA
	RL	E
	RL	D
	RLA
	RL	E
	RL	D
	RLA
	RL	E
	RL	D
	RLA
	RL	E
	RL	D
	INC	HL
	INC	C
	JR	RH0
RHE:
	RET

;;;
;;; RST 30H Handler
;;;

RST30H:
	IF USE_NEWAPI

	PUSH	HL
	PUSH	BC
	LD	HL,APITBL
	LD	B,0
	ADD	HL,BC
	ADD	HL,BC
	LD	B,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,B
	POP	BC
	EX	(SP),HL		; Restore HL, jump address on stack top
	RET

APITBL:
	DW	API00		; 00: CSTART
	DW	API01		; 01: WSTART
	DW	CONOUT		; 02: CONOUT
	DW	STROUT		; 03: STROUT
	DW	CONIN		; 04: CONIN
	DW	CONST		; 05: CONST
	DW	API06		; 06: PSPEC

	;; CSTART
API00:
	POP	HL		; Drop return address
	DI
	JP	CSTART

	;; WSTART
API01:
	POP	HL		; Drop return address
	JP	WSTART

	;; PSPEC
API06:
	LD	A,(PSPEC)
	RET

	ELSE			; USE_NEWAPI

	RET

	ENDIF			; USE_NEWAPI

;;;
;;; RST 38H Handler
;;;

RST38H:
	IF USE_REGCMD

	PUSH	AF
	LD	A,R
	LD	(REGR),A
	LD	A,I
	LD	(REGI),A
	LD	(REGHL),HL
	LD	(REGDE),DE
	LD	(REGBC),BC
	POP	HL
	LD	(REGAF),HL
	EX	AF,AF'
	PUSH	AF
	EXX
	LD	(REGHLX),HL
	LD	(REGDEX),DE
	LD	(REGBCX),BC
	POP	HL
	LD	(REGAFX),HL
	LD	(REGIX),IX
	LD	(REGIY),IY
	POP	HL
	DEC	HL
	LD	(REGPC),HL
	LD	(REGSP),SP

	;; R register adjustment
	IF USE_IDENT
	LD	A,(PSPEC)
	CP	08H		; Z280
	JR	Z,R381
	CP	09H		; NSC800
	JR	Z,R380
	LD	A,(REGR)
	SUB	05H
	AND	7FH
	LD	B,A
	LD	A,(REGR)
	AND	80H
	OR	B
	LD	(REGR),A
	JR	R381
R380:
	LD	A,(REGR)
	SUB	05H
	LD	(REGR),A
R381:
	ENDIF

	LD	HL,RST38MSG
	CALL	STROUT
	CALL	RDUMP
	JP	WSTART

	ELSE

	RET

	ENDIF

	ENDIF                   ; XXX

;;;
;;; Messages
;;;
	
OPNMSG:
	DB	CR,LF,"Universal Monitor H80",CR,LF,00H

PROMPT:
	DB	"] ",00H

IHEMSG:
	DB	"Error ihex",CR,LF,00H
SHEMSG:
	DB	"Error srec",CR,LF,00H
ERRMSG:
	DB	"Error",CR,LF,00H

DSEP0:
	DB	" :",00H
DSEP1:
	DB	" : ",00H
IHEXER:
        DB	":00000001FF",CR,LF,00H
SRECER:
        DB	"S9030000FC",CR,LF,00H

	IF USE_IDENT
IM80:
	DB	"Z80",CR,LF,00H
IM180:
	DB	"HD64180R",CR,LF,00H
IM180Z:
	DB	"HD64180Z",CR,LF,00H
IM1960:
	DB	"Z8S180 SL1960",CR,LF,00H
IMZ8S:
	DB	"Z8S180",CR,LF,00H
IM280:
	DB	"Z280",CR,LF,00H
IMNSC:
	DB	"NSC800",CR,LF,00H
	ENDIF

RST38MSG:
	DB	"RST 38H",CR,LF,00H

	IF USE_REGCMD

	;; Register dump table
RDTAB:	DW	RDSA,   REGAF+1
	DB	1
	DW	RDSBC,  REGBC
	DB	2
	DW	RDSDE,  REGDE
	DB	2
	DW	RDSHL,  REGHL
	DB	2
	DW	RDSF,   REGAF
	DB	1

	DW	RDSIX,  REGIX
	DB	2
	DW	RDSIY,  REGIY
	DB	2

	DW	RDSAX,  REGAFX+1
	DB	1
	DW	RDSBCX, REGBCX
	DB	2
	DW	RDSDEX, REGDEX
	DB	2
	DW	RDSHLX, REGHLX
	DB	2
	DW	RDSFX,  REGAFX
	DB	1

	DW	RDSSP,  REGSP
	DB	2
	DW	RDSPC,  REGPC
	DB	2
	DW	RDSI,   REGI
	DB	1
	DW	RDSR,   REGR
	DB	1

	DW	0000H,  0000H
	DB	0

RDSA:	DB	"A =",00H
RDSBC:	DB	" BC =",00H
RDSDE:	DB	" DE =",00H
RDSHL:	DB	" HL =",00H
RDSF:	DB	" F =",00H
RDSIX:	DB	"  IX=",00H
RDSIY:	DB	" IY=",00H
RDSAX:	DB	CR,LF,"A'=",00H
RDSBCX:	DB	" BC'=",00H
RDSDEX:	DB	" DE'=",00H
RDSHLX:	DB	" HL'=",00H
RDSFX:	DB	" F'=",00H
RDSSP:	DB	"  SP=",00H
RDSPC:	DB	" PC=",00H
RDSI:	DB	" I=",00H
RDSR:	DB	" R=",00H

RNTAB:
	DB	'A',0FH		; "A?"
	DW	RNTABA,0
	DB	'B',0FH		; "B?"
	DW	RNTABB,0
	DB	'C',0FH		; "C?"
	DW	RNTABC,0
	DB	'D',0FH		; "D?"
	DW	RNTABD,0
	DB	'E',0FH		; "E?"
	DW	RNTABE,0
	DB	'F',0FH		; "F?"
	DW	RNTABF,0
	DB	'H',0FH		; "H?"
	DW	RNTABH,0
	DB	'I',0FH		; "I?"
	DW	RNTABI,0
	DB	'L',0FH		; "L?"
	DW	RNTABL,0
	DB	'P',0FH		; "P?"
	DW	RNTABP,0
	DB	'R',1		; "R"
	DW	REGR,RNR
	DB	'S',0FH		; "S?"
	DW	RNTABS,0

	DB	00H,0		; End mark

RNTABA:
	DB	00H,1		; "A"
	DW	REGAF+1,RNA
	DB	'\'',1		; "A'"
	DW	REGAFX+1,RNAX

	DB	00H,0
	
RNTABB:
	DB	00H,1		; "B"
	DW	REGBC+1,RNB
	DB	'\'',1		; "B'"
	DW	REGBCX+1,RNBX
	DB	'C',0FH		; "BC?"
	DW	RNTABBC,0

	DB	00H,0		; End mark

RNTABBC:
	DB	00H,2		; "BC"
	DW	REGBC,RNBC
	DB	'\'',2		; "BC'"
	DW	REGBCX,RNBCX

	DB	00H,0
	
RNTABC:
	DB	00H,1		; "C"
	DW	REGBC,RNC
	DB	'\'',1		; "C'"
	DW	REGBCX,RNCX

	DB	00H,0
	
RNTABD:
	DB	00H,1		; "D"
	DW	REGDE+1,RND
	DB	'\'',1		; "D'"
	DW	REGDEX+1,RNDX
	DB	'E',0FH		; "DE?"
	DW	RNTABDE,0

	DB	00H,0

RNTABDE:
	DB	00H,2		; "DE"
	DW	REGDE,RNDE
	DB	'\'',2		; "DE'"
	DW	REGDEX,RNDEX

	DB	00H,0
	
RNTABE:
	DB	00H,1		; "E"
	DW	REGDE,RNE
	DB	'\'',1		; "E'"
	DW	REGDEX,RNEX

	DB	00H,0
	
RNTABF:
	DB	00H,1		; "F"
	DW	REGAF,RNF
	DB	'\'',1		; "F'"
	DW	REGAFX,RNFX

	DB	00H,0
	
RNTABH:
	DB	00H,1		; "H"
	DW	REGHL+1,RNH
	DB	'\'',1		; "H'"
	DW	REGHLX+1,RNHX
	DB	'L',0FH		; "HL?"
	DW	RNTABHL,0

	DB	00H,0

RNTABHL:
	DB	00H,2		; "HL"
	DW	REGHL,RNHL
	DB	'\'',2		; "HL'"
	DW	REGHLX,RNHLX

	DB	00H,0
	
RNTABL:
	DB	00H,1		; "L"
	DW	REGHL,RNL
	DB	'\'',1		; "L'"
	DW	REGHLX,RNLX

	DB	00H,0
	
RNTABI:
	DB	00H,1		; "I"
	DW	REGI,RNI
	DB	'X',2		; "IX"
	DW	REGIX,RNIX
	DB	'Y',2		; "IY"
	DW	REGIY,RNIY
	
	DB	00H,0

RNTABP:
	DB	'C',2		; "PC"
	DW	REGPC,RNPC

	DB	00H,0

RNTABS:
	DB	'P',2		; "SP"
	DW	REGSP,RNSP

	DB	00H,0

RNA:	DB	"A",00H
RNBC:	DB	"BC",00H
RNB:	DB	"B",00H
RNC:	DB	"C",00H
RNDE:	DB	"DE",00H
RND:	DB	"D",00H
RNE:	DB	"E",00H
RNHL:	DB	"HL",00H
RNH:	DB	"H",00H
RNL:	DB	"L",00H
RNF:	DB	"F",00H
RNAX:	DB	"A'",00H
RNBCX:	DB	"BC'",00H
RNBX:	DB	"B'",00H
RNCX:	DB	"C'",00H
RNDEX:	DB	"DE'",00H
RNDX:	DB	"D'",00H
RNEX:	DB	"E'",00H
RNHLX:	DB	"HL'",00H
RNHX:	DB	"H'",00H
RNLX:	DB	"L'",00H
RNFX:	DB	"F'",00H
RNIX:	DB	"IX",00H
RNIY:	DB	"IY",00H
RNSP:	DB	"SP",00H
RNPC:	DB	"PC",00H
RNI:	DB	"I",00H
RNR:	DB	"R",00H

	ENDIF

;;;
;;; Console drivers
;;;
	ALIGN	2

	IF USE_DEV_H80
	INCLUDE	"dev/dev_h80.asm"
	ENDIF

;;;
;;; RAM area
;;;

	;;
	;; Work Area
	;;
	
	ORG	WORK_B

INBUF:	DS	BUFLEN	; Line input buffer
DSADDR:	DS	2	; Dump start address
DEADDR:	DS	2	; Dump end address
DSTATE:	DS	1	; Dump state
GADDR:	DS	2	; Go address
SADDR:	DS	2	; Set address
HEXMOD:	DS	1	; HEX file mode
RECTYP:	DS	1	; Record type
PSPEC:	DS	1	; Processor spec.
SIZE:	DS	1	; I/O Size 00H,'W','S'
IOPAGE:	DS	1	; I/O Page (for Z280)

	IF USE_REGCMD

REG_B:	
REGAF:	DS	2
REGBC:	DS	2
REGDE:	DS	2
REGHL:	DS	2
REGAFX:	DS	2		; Register AF'
REGBCX:	DS	2
REGDEX:	DS	2
REGHLX:	DS	2		; Register HL'
REGIX:	DS	2
REGIY:	DS	2
REGSP:	DS	2
REGPC:	DS	2
REGI:	DS	1
REGR:	DS	1
REG_E:
	ENDIF

	IF USE_RAMCHK
RAMEND:	DS	2
	ENDIF
	
	END
