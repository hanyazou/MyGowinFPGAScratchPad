;;;
;;;
;;; 


INIT:
	;; nothing to do here
	RET

CONIN:
	XOR	res,res
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
