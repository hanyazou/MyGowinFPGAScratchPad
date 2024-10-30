;;; -*- asm -*-
;;;
;;; Universal Monitor 8080 config file (sample)
;;;

;;;
;;; Memory
;;;

ENTRY:	EQU	0080H
	
WORK_B:	equ	0FF00H
STACK:	equ	00000H

BUFLEN:	equ	16

;;;
;;;  Options
;;;

USE_IDENT = 1			; CPU Identification

USE_HEXCMD = 1			; L(oad) and P(unch) commands
NO_SREC = 0			;   Disable support for Motorola S record
USE_IOCMD = 1			; I(n) and O(ut) commands
USE_REGCMD = 1			; R(egister) command and related functions

USE_NEWAPI = 1			; New API (RST 6)

;;;
;;; Intel 8251
;;;

USE_DEV_8251 = 1
	IF USE_DEV_8251
USARTD:	equ	00H		; Data Register
USARTC:	equ	01H		; Control / Status Register
	ENDIF
	
;;;
;;; Software UART for 8085
;;;

USE_DEV_SOFT85 = 0
	IF USE_DEV_SOFT85
	;; Baudrate constants for CONIN (Receiver)
S85R1L = 18			; Loop between START and BIT 0
S85R1N = 1			; Number of NOPs
S85R2L = 12			; Loop between BITs
S85R2N = 0			; Number of NOPs
	;; Baudrate constants for CONOUT (Transmitter)
S85T1L = 11			; Loop between START and BIT 0
S85T1N = 0			; Number of NOPs
S85T2L = 10			; Loop between BITS
S85T2N = 1			; Number of NOPs
	ENDIF