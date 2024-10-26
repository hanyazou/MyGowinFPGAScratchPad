;;;
;;;	EMILY Board Console Driver
;;;

	INCLUDE	"../../emily.inc"

INIT:
	LD	P3,=SMBASE

	LD	A,=0x00	
	ST	A,EO_HSK,P3
	ST	A,EO_CMD,P3	; Command

	LD	A,=EG_SIG
	ST	A,EO_SIG,P3	; Signature

	LD	A,=EH_REQ
	ST	A,EO_HSK,P3	; Handshake

	RET

CONIN:
	PLI	P3,=SMBASE

	IF FOR_INS8073
	LD	A,=EG_SIG
	ST	A,EO_SIG,P3
	ENDIF
CIN0:	
	LD	A,EO_HSK,P3
	SUB	A,=EH_REQ
	BZ	CIN0

	LD	A,=EC_CIN
	ST	A,EO_CMD,P3

	LD	A,=EH_REQ
	ST	A,EO_HSK,P3
CIN1:
	LD	A,EO_HSK,P3
	SUB	A,=EH_REQ
	BZ	CIN1

	LD	A,EO_DAT,P3

	POP	P3
	RET

CONST:
	PLI	P3,=SMBASE
CST0:	
	LD	A,EO_HSK,P3
	SUB	A,=EH_REQ
	BZ	CST0

	LD	A,=EC_CST
	ST	A,EO_CMD,P3

	LD	A,=EH_REQ
	ST	A,EO_HSK,P3
CST1:
	LD	A,EO_HSK,P3
	SUB	A,=EH_REQ
	BZ	CST1

	LD	A,EO_DAT,P3

	POP	P3
	RET

CONOUT:
	PLI	P3,=SMBASE
	PUSH	A

	IF FOR_INS8073
	LD	A,=EG_SIG
	ST	A,EO_SIG,P3
	ENDIF

COUT0:
	LD	A,EO_HSK,P3	; Handshake
	SUB	A,=EH_REQ
	BZ	COUT0

	LD	A,=EC_COT	; CONOUT
	ST	A,EO_CMD,P3

	POP	A
	ST	A,EO_DAT,P3	; Data[0]

	LD	A,=EH_REQ
	ST	A,EO_HSK,P3	; Handshake

	POP	P3
	RET