;;;
;;;
;;; 


INIT:
	LD	P2M,#00H
	LD	P3M,#41H	; NoParity

	LD	T0,#SDIV0
	LD	PRE0,#(SDIV1 << 2) + 1
	LD	TMR,#73H

	CLR	IMR
	EI
	DI

	LD	SIO,#0AH
	AND	IRQ,#0EFH
	
	RET

CONIN:
	LD	R0,IRQ
	AND	R0,#08H
	JR	Z,CONIN
	LD	R0,SIO
	AND	IRQ,#0F7H
	RET
	
CONST:
	LD	R0,IRQ
	AND	R0,#08H
	RET

CONOUT:
	LD	R1,IRQ
	AND	R1,#10H
	JR	Z,CONOUT
	LD	SIO,R0
	AND	IRQ,#0EFH
	RET
	