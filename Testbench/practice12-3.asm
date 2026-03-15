#include <p16Lf1826.inc>

temp	equ	0x25

;-----------start
		org	0x00
		clrw
		clrf temp
		movlw .3
		movwf temp
		movlw 0
loop	addlw .1
		decfsz temp
		goto loop
		goto $
		end