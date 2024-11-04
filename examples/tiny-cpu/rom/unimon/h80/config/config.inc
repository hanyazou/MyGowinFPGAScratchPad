;;; -*- asm -*-
;;;
;;; Universal Monitor Z80 config file (sample)
;;;

;;;
;;; Memory
;;;

ENTRY:	EQU	0080H		; Entry point

RAM_B:	EQU	1000H
RAM_MAX:EQU	10000H
WORK_B:	equ	0F00H
STACK:	equ	0FF0H

BUFLEN:	equ	16

;;;
;;; Options
;;;

USE_IDENT = 1			; CPU Identification

USE_REGCMD = 0			; R(egister) command and related functions

USE_RAMCHK = 0			; Check RAM (Must be 1 for DRAM)

USE_WARMUP = 0			; DRAM warming up
	IF USE_WARMUP
WARMUP_ADDR = 8000H		;   Start address
WARMUP_INCR = 1			;   Address increment
WARMUP_CNT = 128 * 8		;   Count
	ENDIF

USE_NEWAPI = 0			; New API (RST 30H)

;;; HD64180 specific
DCNTL_V: EQU	00H
RMR_V:	EQU	83H
OMCR_V:	EQU	40H
IOBASE:	EQU	0C0H		; Internal I/O BASE (00H,40H,80H,0C0H)

;;; Z8S180 specific
	;; CPU Control Register
CCR1_V:	EQU	00H
	
;;; Z280 specific
	;; Bus Timing and Control Register: none additional WAIT
BTCR_V:	EQU	30H		; I/O=00, HM=00, DC=00
	;; Bus Timing and Initialization Register
BTIR_V:	EQU	40H		; (CS=00), LM=00, MP=0, (BS=1), (DIC=0)
	;; Cache Control Register
CCR_V:	EQU	00H		; Instruction & data cache enable, no burst mode
	;; Refresh Rate Register
RRR_V:	EQU	38H		; Disable refresh

;;;
;;; Special initialize routine
;;;

USE_SPINIT = 0
	IF USE_SPINIT

SPINIT	MACRO
	ENDM

	ENDIF

;;;
;;; Console Drivers
;;;

;;; H80 built in

USE_DEV_H80 = 1
	IF USE_DEV_H80
CONDAT:		equ	00H		; Data Register
CONSTAT:	equ	01H		; Status Register
	ENDIF

;;;
;;; Calling convention and temporary register assignment
;;;

asmtmp0		equ	r0      ; Assembler temporary
asmtmp1		equ	r1
res0		equ	r2      ; Function results
res1		equ	r3
res		equ	res0
arg0		equ	r4      ; Subprogram arguments
arg1		equ	r5
arg		equ	arg0

        ;; caller saved temprary registers

tmp0		equ	r6
tmp1		equ	r7
tmp		equ	tmp0

        ;; r8 ~ r15 registers are callee saved

v0		equ	r8
v1		equ	r9
v2		equ	r10
