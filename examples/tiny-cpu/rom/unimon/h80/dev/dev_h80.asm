;;;
;;;
;;; 


INIT:
	;; nothing to do here
	RET

CONIN:
	CALL	CONST		; wait for key input
	JR	Z,CONIN
	IN.B	res,(CONDAT)
	RET

CONST:
	XOR	res,res
	IN.B	res,(CONSTAT)
	OR	res,res
	RET

CONOUT:
	OUT.B	(CONDAT),res
	RET
