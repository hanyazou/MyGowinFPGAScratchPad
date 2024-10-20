
	cpu	h80
	page	0

FRACBITS	equ	9
CONDAT		equ	0
STACK		equ	1000h
WIDTH		equ	78
HEIGHT		equ	24
FP0_0458	equ	0017h
FP0_0833	equ	002ah
FP4_0		equ	0800h
CA0		equ	0fc7fh
CB0		equ	0fe08h

tmp0		equ	r0
tmp1		equ	r1
res		equ	r2		
arg0		equ	r4
arg1		equ	r5
tmp		equ	r8
        
X		equ	r6
Y		equ	r7
I		equ	r11
A		equ	r12
B		equ	r13
CA		equ	r14
CB		equ	r15
T		equ	r3

	org	0000h

	ld.w	r0,STACK
	ld	sp,r0
	ld.sw	CB,CB0
	ld.sw	Y,HEIGHT
	add	Y,1

loop_y:
	ld.sw	CA,CA0
	ld.sw	X,WIDTH
	add	X,1

loop_x:
	ld	A,CA
	ld	B,CB
	xor	I,I

loop_i:
	mul	T,A,A
	sra	T,FRACBITS
	mul	tmp,B,B
	sra	tmp,FRACBITS
	sub	T,tmp		; T = A * A - B * B
	add	T,CA		; T = A * A - B * B + CA

	mul	tmp,A,B
	sra	tmp,FRACBITS-1	; res = A * B * 2
	add	B,tmp,CB	; B = A * B * 2 + CB

	ld	A,T		; A = T
	mul	T,A,A		; T = A * A
	sra	T,FRACBITS

	mul	tmp,B,B
	sra	tmp,FRACBITS
	add	T,tmp		; T = A * A + B * B

	ld.w	tmp,FP4_0
	cp	tmp,T		; 4.0 - (A * A + B * B)
	jr	nc,next

	ld	arg0,I
	call	put_pixel
	jr	exit_loop_i

next:
	add	I,1
	ld	tmp,16
	cp	I,tmp
	jp	c,loop_i

	ld.b	tmp," "
	ld.b	r1,CONDAT
	out.b	(r1),tmp

exit_loop_i:
	ld	tmp,FP0_0458	; CA += 0.0458
	add	CA,tmp
	sub	X,1
	jr	nz,loop_x

	ld	tmp,FP0_0833	; CB += 0.0833
	add	CB,tmp

	ld.b	tmp0,CONDAT
	ld.b	tmp1,0dh
	out.b	(tmp0),tmp1
	ld.b	tmp1,0ah
	out.b	(tmp0),tmp1

	sub	Y,1
	jr	nz,loop_y

	halt

put_pixel:
	ld.w	tmp,10
	cp	r4,tmp
	jr	c,l0
        add	r4,7
l0:
	ld	tmp,48
	add	r4,tmp
	ld.w	tmp,CONDAT
	out.b	(tmp),r4
	ret
