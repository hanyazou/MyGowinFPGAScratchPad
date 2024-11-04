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

	LD	v1,RAM_B
	LD	v2,RAM_B+1
	XOR	tmp0,tmp0
	XOR	tmp1,tmp1
RC0:
	LD.B	tmp0,(v2)
	LD	tmp1,tmp0
	CPL	tmp0
	AND	tmp0,0ffh
	LD.B	(v2),tmp0
	LD.B	arg0,(v2)
	CP	tmp0,arg0
	JR	NZ,RC1		; Unwritable
	LD.B	tmp0,(v1)
	CP	tmp0,arg0
	JR	NZ,RC2
	LD.B	(v2),tmp1
	LD.B	tmp0,(v1)
	LD.B	arg0,(v2)
	CP	tmp0,arg0
	JR	NZ,RC2
RC1:	
	;; (v2) and (v1) points same memory or (v2) points no memory
	LD.W	(RAMEND),v2
	JR	RCE
RC2:
	LD.B	(v2),tmp1
	ADD	v2,1
	CP	v2,RAM_MAX
	JR	C,RC0
	LD.W	(RAMEND),v2
RCE:	
	ENDIF
	
	;; CPU identification
	XOR	tmp,tmp
	LD.B	(PSPEC),tmp

	IF USE_IDENT
	;; H8032
	LD	v0,IM8032
	XOR	v1,v1
	JP	IDE

IDE:
	LD.B	(PSPEC),v1
	LD.W	(INBUF),v0
	ENDIF			; USE_IDENT

	CALL    INIT

	LD.W	tmp,1000H
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
	XOR	res0,res0
	CALL	CONOUT
	DJNZ	v0,TL
	
	;; Opening message
	LD	arg0,OPNMSG
	CALL	STROUT

	IF USE_IDENT
	LD.W	arg0,(INBUF)
	CALL	STROUT
	ENDIF

	IF USE_RAMCHK
	LD	arg0,RAM_B
	CALL	HEXOUT4
	LD	res0,'-'
	CALL	CONOUT
	LD.W	arg0,(RAMEND)
	SUB	arg0,1
	CALL	HEXOUT4
	CALL	CRLF
	ENDIF

WSTART:
	LD	arg0,PROMPT
	CALL	STROUT

	CALL	GETLIN
	LD	arg0,INBUF
	CALL	SKIPSP
	CALL	UPPER
	OR	res,res
	JR	Z,WSTART

	CP	res,'D'
	JR	Z,DUMP
	CP	res,'G'
	JP	Z,GO
	CP	res,'S'
	JP	Z,SETM

	CP	res,'L'
	JP	Z,LOADH
	CP	res,'P'
	JP	Z,SAVEH

	IF 0                    ; XXX
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

        ENDIF                   ; XXX

ERR:
	LD	arg0,ERRMSG
	CALL	STROUT
	JR	WSTART

;;; 
;;; Dump memory
;;; 

DUMP:
	ADD	arg0,1
	CALL	SKIPSP
	CALL	RDHEX		; 1st arg.
	OR	res1,res1	; number of digits
	JR	NZ,DP0
	;; No arg.
	CALL	SKIPSP
	OR	res0,res0
	JR	NZ,ERR
	LD.W	tmp,(DSADDR)
	ADD	tmp,128
	LD.W	(DEADDR),tmp
	JR	DPM

	;; 1st arg. found
DP0:
	LD.W	(DSADDR),arg1   ; value of 1st arg.
	CALL	SKIPSP
	CP	res0,','
	JR	Z,DP1
	OR	res0,res0
	JR	NZ,ERR
	;; No 2nd arg.
	ADD	arg1,128
	LD.W	(DEADDR),arg1
	JR	DPM
DP1:
	ADD	arg0,1          ; skip ','
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	OR	res1,res1       ; number of digits
	JR	Z,ERR
	OR	res0,res0
	JP	NZ,ERR
	ADD	arg1,1		; value of 2nd arg.
	LD.W	(DEADDR),arg1
DPM:
	;; DUMP main
	XOR	arg0,arg0
	LD.W	arg0,(DSADDR)
	AND	arg0,0FFF0H
	XOR	tmp,tmp
	LD.B	(DSTATE),tmp

DPM0:
	PUSH	arg0
	CALL	DPL
	POP	arg0
	ADD	arg0,16
	CALL	CONST
	JR	NZ,DPM1
	LD.B	res0,(DSTATE)
	CP	res0,2
	JR	C,DPM0
	LD.W	arg0,(DEADDR)
	LD.W	(DSADDR),arg0
	JP	WSTART
DPM1:
	LD.W	(DSADDR),arg0
	CALL	CONIN
	JP	WSTART

DPL:
	;; DUMP line
	CALL	HEXOUT4
	PUSH	arg0
	LD	arg0,DSEP0
	CALL	STROUT
	POP	arg0
	LD	v0,INBUF
	LD	v1,16
DPL0:
	CALL	DPB
	DJNZ	v1,DPL0

	LD	arg0,DSEP1
	CALL	STROUT

	LD	arg0,INBUF
	LD	v1,16

DPL1:
	LD.B	res0,(arg0)
	ADD	arg0,1
	CP	res0,' '
	JR	C,DPL2
	CP	res0,7FH
	JR	NC,DPL2
	CALL	CONOUT
	JR	DPL3
DPL2:
	LD.B	res0,'.'
	CALL	CONOUT
DPL3:
	DJNZ	v1,DPL1
	JP	CRLF

DPB:	; Dump byte
	LD	res0,' '
	CALL	CONOUT
	XOR	tmp,tmp
	LD.B	tmp,(DSTATE)
	OR	tmp,tmp
	JR	NZ,DPB2
	; Dump state 0
	XOR	tmp,tmp
	LD.W	tmp,(DSADDR)
	CP	tmp,arg0
	JR	Z,DPB1
DPB0:	; Still 0 or 2
	LD.B	res0,' '
	CALL	CONOUT
	CALL	CONOUT
	LD.B	(v0),res0
	ADD	arg0,1
	ADD	v0,1
	RET
DPB1:	; Found start address
	LD.B	tmp,1
	LD.B	(DSTATE),tmp
DPB2:
	LD.B	tmp,(DSTATE)
	CP	tmp,1
	JR	NZ,DPB0
	; Dump state 1
	LD.B	res0,(arg0)
	LD.B	(v0),res0
	CALL	HEXOUT2
	ADD	arg0,1
	ADD	v0,1
	LD.W	tmp,(DEADDR)	; Low byte
	CP	arg0,tmp
	RET	NZ
	; Found end address
	LD.B	tmp,2
	LD.B	(DSTATE),tmp
	RET

;;;
;;; GO address
;;; 

GO:
	INC	arg0
	CALL	SKIPSP
	CALL	RDHEX		; arg1=value, res1=number of digits
	CALL	SKIPSP		; res0 is the first character that is a not space or null
	OR	res0,res0	; error if any trailing garbege
	JP	NZ,ERR
	OR	res1,res1	; no argument if number of digits is zero
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
	
	LD.W	(GADDR),arg1
G0:
	LD.W	tmp,(GADDR)
	JP	(tmp)

	ENDIF

;;;
;;; SET memory
;;; 

SETM:
	INC	arg0
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	OR	res0,res0
	JP	NZ,ERR
	OR	res1,res1
	JR	NZ,SM0
	XOR	arg1,arg1
	LD.W	arg1,(SADDR)
SM0:
	EX	arg1,arg0
SM1:
	CALL	HEXOUT4
	PUSH	arg0
	LD	arg0,DSEP1
	CALL	STROUT
	POP	arg0
	LD.B	res0,(arg0)
	PUSH	arg0
	CALL	HEXOUT2
	LD	res0,' '
	CALL	CONOUT
	CALL	GETLIN
	LD	arg0,INBUF
	CALL	SKIPSP
	OR	res0,res0
	JR	NZ,SM2
	;; Empty  (Increment address)
	POP	arg0
	INC	arg0
	LD.W	(SADDR),arg0
	JR	SM1
SM2:
	CP	res0,'-'
	JR	NZ,SM3
	;; '-'  (Decrement address)
	POP	arg0
	DEC	arg0
	LD.W	(SADDR),arg0
	JR	SM1
SM3:
	CP	res0,'.'
	JR	NZ,SM4
	POP	arg0
	LD.W	(SADDR),arg0
	JP	WSTART
SM4:
	CALL	RDHEX
	OR	res1,res1
	POP	arg0
	JP	Z,ERR
	LD.B	(arg0),arg1
	INC	arg0
	LD.W	(SADDR),arg0
	JR	SM1

;;;
;;; LOAD HEX file
;;;

LOADH:
	INC	arg0
	CALL	SKIPSP
	CALL	RDHEX
	CALL	SKIPSP
	OR	res0,res0
	JP	NZ,ERR

	OR	res1,res1	; number of digits
	JR	NZ,LH0

	LD	arg1,0		; Offset
LH0:
	CALL	CONIN
	CALL	UPPER
	CP	res0,'S'
	JR	Z,LHS0
LH1:
	CP	res0,':'
	JR	Z,LHI0
LH2:
	;; Skip to EOL
	CP	res0,CR
	JR	Z,LH0
	CP	res0,LF
	JR	Z,LH0
LH3:
	CALL	CONIN
	JR	LH2

LHI0:
	CALL	HEXIN
	LD	v1,res0		; Checksum
	LD	v0,res0		; Length

	CALL	HEXIN
	ADD	v1,res0		; Checksum
	SL	res0,8
	LD	arg0,res0	; Address H

	CALL	HEXIN
	OR	arg0,res0	; Address L
	ADD	v1,res0		; Checksum

	;; Add offset
	ADD	arg0,arg1

	CALL	HEXIN
	LD.B	(RECTYP),res0
	ADD	v1,res0		; Checksum

	OR	v0,v0		; Length
	JR	Z,LHI3
LHI1:
	CALL	HEXIN
	ADD	v1,res0		; Checksum

	XOR	tmp,tmp
	LD.B	tmp,(RECTYP)
	OR	tmp,tmp
	JR	NZ,LHI2

	LD.B	(arg0),res0
	INC	arg0
LHI2:
	DJNZ	v0,LHI1
LHI3:
	CALL	HEXIN
	ADD	v1,res0
	AND	v1,0ffh
	OR	v1,v1
	JR	NZ,LHIE		; Checksum error
	XOR	tmp,tmp
	LD.B	tmp,(RECTYP)
	OR	tmp,tmp
	JP	Z,LH3
	JP	WSTART
LHIE:
	LD	arg0,IHEMSG
	CALL	STROUT
	JP	WSTART
	
LHS0:
	CALL	CONIN
	LD.B	(RECTYP),res0

	CALL	HEXIN
	LD	v0,res0		; Length+3
	LD	v1,res0		; Checksum

	CALL	HEXIN
	ADD	v1,res0		; Checksum
	SL	res0,8
	LD	arg0,res0	; Address H
	
	CALL	HEXIN
	OR	arg0,res0	; Address L
	ADD	v1,res0		; Checksum

	ADD	arg0,arg1

	SUB	v0,3
	JR	Z,LHS3
LHS1:
	CALL	HEXIN
	ADD	v1,res0		; Checksum

	XOR	tmp,tmp
	LD.B	tmp,(RECTYP)
	CP	tmp,'1'
	JR	NZ,LHS20

	LD.B	(arg0),res0
	INC	arg0

LHS20:
	DJNZ	v0,LHS1
LHS3:
	CALL	HEXIN
	ADD	v1,res0
	AND	v1,0ffh
	CP	v1,0FFH
	JR	NZ,LHSE		; Checksum error

	XOR	tmp,tmp
	LD.B	tmp,(RECTYP)
	CP	tmp,'7'
	JR	Z,LHSR
	CP	tmp,'8'
	JR	Z,LHSR
	CP	tmp,'9'
	JR	Z,LHSR
	JP	LH3
LHSE:
	LD	arg0,SHEMSG
	CALL	STROUT
LHSR:
	JP	WSTART

;;;
;;; SAVE HEX file
;;;

SAVEH:
	INC	arg0
	XOR	res0,res0
	LD.B	res0,(arg0)
	CALL	UPPER
	CP	res0,'I'
	JR	Z,SH0
	CP	res0,'S'
	JR	NZ,SH1
SH0:
	INC	arg0
	LD.B	(HEXMOD),res0
SH1:
	CALL	SKIPSP
	CALL	RDHEX
	OR	res1,res1
	JR	Z,SHE
	LD	v0,arg1		; v0 = Start address
	CALL	SKIPSP
	CP	res0,','
	JR	NZ,SHE
	INC	arg0
	CALL	SKIPSP
	CALL	RDHEX		; arg1 = End address
	OR	res1,res1	; res1 = Number of digits
	JR	Z,SHE
	CALL	SKIPSP
	OR	res0,res0
	JR	Z,SH2
SHE:
	JP	ERR

SH2:
	LD	arg0,v0
	EX	arg1,arg0
	INC	arg0
	SUB	arg0,arg1	; arg0 = Length
SH3:
	CALL	SHL
	OR	arg0,arg0
	JR	NZ,SH3

	XOR	tmp,tmp
	LD.B	tmp,(HEXMOD)
	CP	tmp,'I'
	JR	NZ,SH4
	;; End record for Intel HEX
	LD	arg0,IHEXER
	CALL	STROUT
	JP	WSTART
SH4:
	;; End record for Motorola S record
	LD	arg0,SRECER
	CALL	STROUT
	JP	WSTART

SHL:
	LD	v0,16		; v0 is line length, 16 or remain length
	CP	arg0,v0
	JR	NC,SHL0
	LD	v0,arg0		; remain length (< 16)
SHL0:
	SUB	arg0,v0		; subtruct line length from total length

	XOR	tmp,tmp
	LD.B	tmp,(HEXMOD)
	CP	tmp,'I'
	JR	NZ,SHLS		; HEXMOD != I means Motorola S record

	;; Intel HEX
	LD	res0,':'
	CALL	CONOUT

	LD	res0,v0		; output line length
	CALL	HEXOUT2
	LD	v1,v0		; v1 is checksum

	LD	res0,arg1	; output higher address
	SRL	res0,8
	ADD	v1,res0		; calculate checksum
	CALL	HEXOUT2
	
	AND	res0,arg1	; output lower address
	AND	res0,0ffh
	ADD	v1,res0		; calculate checksum
	CALL	HEXOUT2
	
	XOR	res0,res0	; recode type ( 00 means data record)
	CALL	HEXOUT2
SHLI0:
	XOR	res0,res0
	LD.B	res0,(arg1)
	ADD	v1,res0		; checksum
	CALL	HEXOUT2

	INC	arg1
	DJNZ	v0,SHLI0	; repeat for the length of line

	NEG	v1		; add checksum
	LD	res0,v1
	CALL	HEXOUT2
	JP	CRLF

SHLS:
	;; Motorola S record
	LD	res0,'S'
	CALL	CONOUT
	LD	res0,'1'
	CALL	CONOUT

	ADD	v0,2+1		; DataLength + 2(Addr) + 1(Sum)
	LD	v1,v0		; v1 is checksum
	LD	res,v0		; output length
	CALL	HEXOUT2

	LD	res0,arg0	; output higher address
	SRL	res0,8
	LD	v1,res0		; calculate checksum
	CALL	HEXOUT2
	
	LD	res0,arg0	; output lower address
	AND	res0,0ffh
	LD	v1,res0		; calculate checksum
	CALL	HEXOUT2

SHLS0:
	XOR	res0,res0
	LD.B	res0,(arg1)
	ADD	v1,res0		; checksum
	CALL	HEXOUT2

	INC	arg1
	DJNZ	v0,SHLS0	; repeat for the length of line

	CPL	v1		; add checksum
	LD	res0,v1
	CALL	HEXOUT2
	JP	CRLF

	IF 0                    ; XXX

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
	LD.B	res0,(arg0)
	AND	res0,res0
	RET	Z
	CALL	CONOUT
	ADD	arg0,1
	JR	STROUT

HEXOUT4:
	LD	res0,arg0
	SRA	res0,8
	CALL	HEXOUT2
	LD	res0,arg0
HEXOUT2:
	LD	tmp,res0
	SRA	res0,4
	CALL	HEXOUT1
	LD	res0,tmp
HEXOUT1:
	AND	res0,0FH
	ADD	res0,'0'
	CP	res0,'9'+1
	JP	C,CONOUT
	ADD	res0,'A'-'9'-1
	JP	CONOUT

HEXIN:
	XOR	res,res
	CALL	HI0
	SL	res,4
HI0:
	PUSH	v0
	LD	v0,res
	CALL	CONIN
	CALL	UPPER
	CP	res,'0'
	JR	C,HIR
	CP	res,'9'+1
	JR	C,HI1
	CP	res,'A'
	JR	C,HIR
	CP	res,'F'+1
	JR	NC,HIR
	SUB	res,'A'-'9'-1
HI1:
	SUB	res,'0'
	OR	res,v0
HIR:
	POP	v0
	RET

CRLF:
	LD	res0,CR
	CALL	CONOUT
	LD	res0,LF
	JP	CONOUT

GETLIN:
	PUSH	v2
	PUSH	v0
	LD	v2,INBUF
	LD	v0,0
GL0:
	CALL	CONIN
	CP	res,CR
	JR	Z,GLE
	CP	res,LF
	JR	Z,GLE
	CP	res,BS
	JR	Z,GLB
	CP	res,DEL
	JR	Z,GLB
	CP	res,' '
	JR	C,GL0
	CP	res,80H
	JR	NC,GL0
	CP	v0,BUFLEN-1
	JR	NC,GL0	; Too long
	ADD	v0,1
	CALL	CONOUT
	LD.B	(v2),res
	ADD	v2,1
	JR	GL0
GLB:
	AND	v0,v0
	JR	Z,GL0
	SUB	v0,1
	SUB	v2,1
	LD	res0,08H
	CALL	CONOUT
	LD	res0,' '
	CALL	CONOUT
	LD	res0,08H
	CALL	CONOUT
	JR	GL0
GLE:
	CALL	CRLF
	LD.B	(v2),00H
	POP	v0
	POP	v2
	RET

SKIPSP:
	XOR	res,res
	LD.B	res,(arg0)
	CP	res,' '
	RET	NZ
	ADD	arg0,1
	JR	SKIPSP

UPPER:
	CP	res,'a'
	RET	C
	CP	res,'z'+1
	RET	NC
	ADD	res,'A'-'a'
	RET

RDHEX:
	XOR	arg1,arg1	; value
	XOR	res1,res1	; number of digits
RH0:
	XOR	res,res
	LD.B	res,(arg0)
 	CALL	UPPER
	CP	res,'0'
 	JR	C,RHE
	CP	res,'9'+1
 	JR	C,RH1
	CP	res,'A'
 	JR	C,RHE
	CP	res,'F'+1
 	JR	NC,RHE
	SUB	res,'A'-'9'-1
RH1:
	SUB	res,'0'
	SL	arg1,4
	OR	arg1,res
	ADD	arg0,1
	ADD	res1,1
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
IM8016:
	DB	"H80(16)",CR,LF,00H
IM8032:
	DB	"H80(32)",CR,LF,00H
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
	ALIGN	2
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
	ALIGN	2
RAMEND:	DS	2
	ENDIF

        ORG 1000h
        DB	0
	
	END
