;;; -*- asm -*-
;;;
;;; Universal Monitor 6809 config file (sample)
;;;

;;;
;;; Memory
;;; 

ROM_B:	equ	$E000		; ROM begin
ENTRY:	EQU	$FF80		; Entry point

WORK_B:	equ	$1F00		; WORK begin
STACK:	equ	$2000		; Stack end

BUFLEN:	EQU	16		; Buffer length ( 16 or above )
	
;;;
;;;  Options
;;;

USE_IDENT = 1			; CPU Identification
USE_REGCMD = 1			; Register related commands
USE_NATIVE = 1			; HD6309 NATIVE mode

USE_WARMUP = 0			; DRAM warming up

;;;
;;; Special initialize routine
;;;

USE_SPINIT = 0
	IF USE_SPINIT

SPINIT	MACRO
	ENDM

	ENDIF

;;;
;;; Motorola MC6850
;;;

USE_DEV_6850 = 1
	IF USE_DEV_6850
	;; ACIA
ACIAC:	equ	$8018		; Control / Status Register
ACIAD:	equ	$8019		; Data Register
ACCR_V:	EQU	$15		; Control: x16, 8-bit, N, 1
	ENDIF