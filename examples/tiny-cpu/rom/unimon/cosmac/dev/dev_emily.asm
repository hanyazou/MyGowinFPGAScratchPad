;;;
;;;	EMILY Board Console Driver
;;;

	INCLUDE	"../../emily.inc"

SMREG	EQU	7		;

INIT:	
	LDI	high(SMBASE)
	PHI	SMREG
	LDI	low(SMBASE+EO_HSK)
	PLO	SMREG
	LDI	00H
	STR	SMREG
	INC	SMREG		; EO_CMD
	STR	SMREG

	DEC	SMREG
	DEC	SMREG		; EO_SIG
	LDI	EG_SIG
	STR	SMREG

	INC	SMREG		; EO_HSK
	LDI	EH_REQ
	STR	SMREG

	SEP	RETN

CONIN:
	LDI	low(SMBASE+EO_HSK)
	PLO	SMREG
CI0:
	LDN	SMREG
	SMI	EH_REQ
	BZ	CI0

	INC	SMREG		; EO_CMD
	LDI	EC_CIN
	STR	SMREG

	DEC	SMREG		; EO_HSK
	LDI	EH_REQ
	STR	SMREG
CI1:
	LDN	SMREG
	SMI	EH_REQ
	BZ	CI1

	LDI	low(SMBASE+EO_DAT)
	PLO	SMREG
	LDN	SMREG
	PLO	8

	SEP	RETN

CONST:
	LDI	low(SMBASE+EO_HSK)
	PLO	SMREG
CS0:
	LDN	SMREG
	SMI	EH_REQ
	BZ	CS0

	INC	SMREG		; EO_CMD
	LDI	EC_CST
	STR	SMREG

	DEC	SMREG		; EO_HSK
	LDI	EH_REQ
	STR	SMREG
CS1:
	LDN	SMREG
	SMI	EH_REQ
	BZ	CS1

	LDI	low(SMBASE+EO_DAT)
	PLO	SMREG
	LDN	SMREG
	PLO	8

	SEP	RETN

CONOUT:
	LDI	low(SMBASE+EO_HSK)
	PLO	SMREG
CO0:
	LDN	SMREG
	SMI	EH_REQ
	BZ	CO0

	INC	SMREG		; EO_CMD
	LDI	EC_COT
	STR	SMREG

	INC	SMREG
	INC	SMREG		; EO_DAT[0]
	GLO	8		; R8.L
	STR	SMREG

	LDI	low(SMBASE+EO_HSK)
	PLO	SMREG
	LDI	EH_REQ
	STR	SMREG

	SEP	RETN
