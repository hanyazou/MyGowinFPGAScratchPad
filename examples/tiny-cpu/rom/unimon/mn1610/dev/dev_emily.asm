;;;
;;; 	EMILY Board Console Driver
;;;

	INCLUDE	"../../emily.inc"

INIT:
	MVI	R0,X'00'
	ST	R0,SMBASE+EO_HSK
	ST	R0,SMBASE+EO_CMD ; Command

	MVI	R0,EG_SIG
	ST	R0,SMBASE+EO_SIG ; Signature

	MVI	R0,EH_REQ
	ST	R0,SMBASE+EO_HSK ; Handshake

	RET

CONIN:
	L	R0,SMBASE+EO_HSK
	MVI	R1,EH_REQ
	CB	R0,R1,NZ
	B	CONIN

	MVI	R0,EC_CIN
	ST	R0,SMBASE+EO_CMD

	ST	R1,SMBASE+EO_HSK
CIN0:
	L	R0,SMBASE+EO_HSK
	CB	R0,R1,NZ
	B	CIN0

	L	R0,SMBASE+EO_DAT
	L	R1,CINC
	AND	R0,R1
	
	RET

CINC:	DC	X'00FF'
	
CONST:
	L	R0,SMBASE+EO_HSK
	MVI	R1,EH_REQ
	CB	R0,R1,NZ
	B	CONST

	MVI	R0,EC_CST	; CONST Command
	ST	R0,SMBASE+EO_CMD

	ST	R1,SMBASE+EO_HSK
CST0:
	L	R0,SMBASE+EO_HSK
	CB	R0,R1,NZ
	B	CST0

	L	R0,SMBASE+EO_DAT
	L	R1,CINC
	AND	R0,R1

	RET

CONOUT:
	PUSH	R0
COUT0:
	L	R0,SMBASE+EO_HSK
	MVI	R1,EH_REQ
	CB	R0,R1,NZ
	B	COUT0

	MVI	R0,EC_COT	; CONOUT Command
	ST	R0,SMBASE+EO_CMD

	POP	R0
	ST	R0,SMBASE+EO_DAT

	ST	R1,SMBASE+EO_HSK

	RET