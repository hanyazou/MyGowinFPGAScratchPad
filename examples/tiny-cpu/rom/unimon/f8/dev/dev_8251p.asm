;;;
;;;	8251 (USART) Console Driver (I/O mapped)
;;;

INIT:
	;; Reset USART (software)
	LI	00H
	OUT	USARTC
	OUT	USARTC
	OUT	USARTC
	LI	40H		; Reset
	OUT	USARTC

	LI	4EH
	OUT	USARTC

	LI	37H
	OUT	USARTC

	POP			; RET

CONIN:
	IN	USARTC
	NI	02H
	BZ	CONIN
	IN	USARTD
	LR	0,A

	POP			; RET

CONST:
	IN	USARTC
	NI	02H
	LR	0,A

	POP			; RET

CONOUT:
	IN	USARTC
	NI	01H
	BZ	CONOUT
	LR	A,0
	OUT	USARTD

	POP			; RET