;;;
;;;	EMILY Board Console Driver
;;;

	INCLUDE	"../../emily.inc"

INIT:
	LDI	0x00
	ST	disp(SMBASE+EO_HSK)(P2)
	ST	disp(SMBASE+EO_CMD)(P2) ; Command

	LDI	EG_SIG
	ST	disp(SMBASE+EO_SIG)(P2) ; Signature

	LDI	EH_REQ
	ST	disp(SMBASE+EO_HSK)(P2) ; Handshake

	RET
	
CONIN:
	LD	disp(SMBASE+EO_HSK)(P2)
	SCL
	CAI	EH_REQ
	JZ	CONIN

	LDI	EC_CIN
	ST	disp(SMBASE+EO_CMD)(P2)

	LDI	EH_REQ
	ST	disp(SMBASE+EO_HSK)(P2)
CIN0:
	LD	disp(SMBASE+EO_HSK)(P2)
	SCL
	CAI	EH_REQ
	JZ	CIN0

	LD	disp(SMBASE+EO_DAT)(P2)

	RET

CONST:
	LD	disp(SMBASE+EO_HSK)(P2)
	SCL
	CAI	EH_REQ
	JZ	CONST

	LDI	EC_CST
	ST	disp(SMBASE+EO_CMD)(P2)

	LDI	EH_REQ
	ST	disp(SMBASE+EO_HSK)(P2)
CST0:
	LD	disp(SMBASE+EO_HSK)(P2)
	SCL
	CAI	EH_REQ
	JZ	CST0

	LD	disp(SMBASE+EO_DAT)(P2)

	RET

CONOUT:
	ST	@-1(P1)
COUT0:
	LD	disp(SMBASE+EO_HSK)(P2) ; Handshake
	SCL
	CAI	EH_REQ
	JZ	COUT0

	LDI	EC_COT		; CONOUT
	ST	disp(SMBASE+EO_CMD)(P2)

	LD	@1(P1)
	ST	disp(SMBASE+EO_DAT)(P2) ; Data[0]

	LDI	EH_REQ
	ST	disp(SMBASE+EO_HSK)(P2) ; Data[0]

	RET