;
; Ullrich von Bassewitz, 06.08.1998
;
; void cputcxy (unsigned char x, unsigned char y, char c);
; void cputc (char c);
;

	.constructor	initconio
   	.export		_cputcxy, _cputc
	.export		_gotoxy, cputdirect
	.export		newline, putchar

	.import		popa

	.include	"../apple2/apple2.inc"


initconio:
	lda	#$FF		; Normal character display mode
	sta	INVFLG
	sta	SETALTCHAR	; Switch in alternate charset
	rts

; Plot a character - also used as internal function

_cputcxy:
	pha			; Save C
	jsr	popa		; Get Y
	jsr	_gotoxy
	pla			; Restore C

_cputc:
	cmp	#$0D		; Test for \r = carrage return
	bne	L1
	stz	CH		; Goto left edge of screen
	rts			; That's all we do
L1:
	cmp	#$0A		; Test for \n = line feed
	beq	newline
	ora	#$80		; Turn on high bit

cputdirect:
	jsr	putchar
	inc	CH		; Bump to next column
	lda	CH
	cmp	WNDWDTH
	bne	return
	stz	CH
return:
	rts

putchar:
	ldy	INVFLG
	cpy	#$FF		; Normal character display mode?
	beq	put
	cmp	#$E0		; Lowercase?
	bmi	mask
	and	#$7F		; Inverse lowercase
	bra	put
mask:
	and	INVFLG		; Apply normal, inverse, flash
put:
	ldy	CH
	bit	RD80VID 	; In 80 column mode?
	bpl	col40		; No, in 40 cols
	pha
	tya
	lsr			; Div by 2
	tay
	pla
	bcs	col40		; Odd cols go in 40 col memory
	bit	HISCR
	sta	(BASL),Y
	bit	LOWSCR
	rts
col40:
	sta	(BASL),Y
	rts

newline:
	lda	CH
	pha
	inc	CV
	lda	CV
	cmp	WNDBTM
	bne	L2
	lda	#$00
	sta	CV
L2:
	jsr	VTABZ
	pla
	sta	CH
	rts

_gotoxy:
	sta	CV		; Store Y
	jsr	VTABZ
	jsr	popa		; Get X
	sta	CH		; Store X
	rts
