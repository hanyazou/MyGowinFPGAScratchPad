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
	RET

CONOUT:
	OUT.B	(CONDAT),arg0
	RET
