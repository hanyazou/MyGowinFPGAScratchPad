;;;
;;;
;;; 


INIT:
	;; nothing to do here
	RET

CONIN:
	IN	res,(CONDAT)
	RET

CONST:
	IN	res,(CONST)
	RET

CONOUT:
	OUT.B	(CONDAT),arg0
	RET
