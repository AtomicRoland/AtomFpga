;----------------------------------------------
; RTC-INT
; Show time and date on the upper line of the screen
;----------------------------------------------
	.DEFINE asm_code $0600
	.DEFINE header   0		; Header Atomulator
	.DEFINE filenaam "RTC-INT.BIN"

	irqvec_l 	= $204
	irqvec_h	= $205
	
	rtc		= $BFD0
	rtc_year	= rtc
	rtc_month	= rtc+1
	rtc_day		= rtc+2
	rtc_hour	= rtc+3
	rtc_minute	= rtc+4
	rtc_second	= rtc+5
	rtc_control	= rtc+6
	rtc_status	= rtc+7

	godil_mer	= $BDE0	; Godil Mode Extension Register

	screenstart	= $8000
	attribstart	= $8C80
	.org asm_code-22*header

.IF header
;********************************************************************
; ATM Header for Atomulator

name_start:
	.byte filenaam			; Filename
name_end:
	.repeat 16-name_end+name_start	; Fill with 0 till 16 chars
	  .byte $0
	.endrep

	.word start_asm			; 2 bytes startaddress
	.word start_asm			; 2 bytes linkaddress
	.word eind_asm-start_asm	; 2 bytes filelength

;********************************************************************
.ENDIF


exec:
start_asm:
	sta invertoption	; save the invert option (0 = do not invert, others = do invert)
	sei			; disable interrupts
	lda #<isr		; set the interrupt service vector
	sta irqvec_l		
	lda #>isr
	sta irqvec_h
	cli			; enable interrupts
	lda #1			; 10 interrupts per second
	sta rtc_control
	rts			; end

isr:	tya			; save registers
	pha
	txa
	pha
	jsr print_date		; print the day and date
	jsr clear_gap		; clear the area between the date and time
	jsr print_time		; print the time
	jsr invert		; invert the top line
	sta rtc_status		; clear the interrupt
	pla			; restore registers
	tax
	pla
	tay
	pla
	rti			; end of interrupt service routine	

print_date:			; prints the date
	lda rtc_month		; load the register that holds the month and day of the week
	and #$70		; mask out the month
	lsr a			; shift the day of the week to the lower nibble (4 shifts)
	lsr a			; we should shift four times, but the print routine needs an index that is multiple of 4, so to save time we only shift twic
	jsr print_dow
	ldy rtc_day		; load the day
	jsr printdec		; print it
	lda #'-'		; print a dash
	sta screenstart,x
	inx 
	lda rtc_month		; print the month
	and #$0F		; mask the day-of-week
	tay			; transfer to y for printing
	jsr printdec
	lda #'-'		; print a dash
	sta screenstart,x
	inx		
	ldy #20			; introduce a new y2k bug
	jsr printdec
	ldy rtc_year		; print the year
	jsr printdec
	rts

clear_gap:			; between the date and the time is a gap. Clear it..
	lda #$20		; load space character
clear1:	sta screenstart,x	; write to the screen
	inx			; increment x register
	cpx #24			; enough cleared?
	bne clear1		; no, then clear the next position
	bit godil_mer		; test VGA80x40 mode
	bpl clear3		; if normal vdu then goto end of routine
clear2:	sta screenstart,x	; continue write to screen
	inx 			; increment x register
	cpx #72			; enough cleared?
	bne clear2		; no, then clear the next position
clear3:	rts

print_time:			; prints the date
	ldy rtc_hour		; load the hour
	jsr printdec		; print it
	lda #':'		; print a colon
	sta screenstart,x
	inx 
	ldy rtc_minute		; print the minutes
	jsr printdec
	lda #':'		; print a colon
	sta screenstart,x		
	inx
	ldy rtc_second		; print the seconds
	jsr printdec
	rts

print_dow:			; prints the day of the week
	tay			; transfer to pointer register y
	ldx #$00		; we start at the upper left corner and abuse that for counting characters
pdow1:	lda weekday,y		; load character
	sta screenstart,x	; write to screen
	iny			; increment pointers
	inx
	cpx #$04		; four characters printed (space is included)
	bne pdow1		; no, print the rest
	rts			; yes, return to ISR

printdec:			; print the decimal value of A
	; I use a table to look up the digits to print for speed; it takes less
	; time to copy a few digits than calculate them every interrupt cycle. This
	; takes a bit more memory but we have tons of memory in the FPGAtom.
	lda digithi,y		; load high digit
	sta screenstart,x	; write to screen
	inx			; increment x-position
	lda digitlo,y		; load low digit
	sta screenstart,x	; write to screen
	inx			; increment x-position
	rts			; return to main routine

invert:				; inverts the date/time line
	lda invertoption	; test for inversion
	beq no_invert		; jmp if not invert
	lda godil_mer		; test for VGA80x40
	bmi invert80		; if it is then jump
	ldx #31			; load pointer
inv1:	lda screenstart,x	; load character
	ora #$80		; invert it by setting bit 7
	sta screenstart,x	; write back to screen
	dex			; decrement pointer
	bpl inv1		; invert next char if not all done
	bmi no_invert		; branch to end of routine
invert80:			; invert top line
	ldx #79			; load pointer
	lda #$71		; load inverted colour (blue on white)
inv2:	sta attribstart,x	; write to attribute memory
	dex			; decrement pointer
	bpl inv2		; invert next char if not all done
no_invert: rts			; end of routine



invertoption: .byte $00

weekday: .dword $200E1513	; sun
	 .dword $200E0F0D	; mon
	 .dword $20051514	; tue
	 .dword $20040517	; wed
	 .dword $20150814	; thu
	 .dword $20091206	; fri
	 .dword $20140113	; sat

digithi: .byte 48,48,48,48,48,48,48,48,48,48
	 .byte 49,49,49,49,49,49,49,49,49,49
	 .byte 50,50,50,50,50,50,50,50,50,50
	 .byte 51,51,51,51,51,51,51,51,51,51
	 .byte 52,52,52,52,52,52,52,52,52,52
	 .byte 53,53,53,53,53,53,53,53,53,53

digitlo: .byte 48,49,50,51,52,53,54,55,56,57
	 .byte 48,49,50,51,52,53,54,55,56,57
	 .byte 48,49,50,51,52,53,54,55,56,57
	 .byte 48,49,50,51,52,53,54,55,56,57
	 .byte 48,49,50,51,52,53,54,55,56,57
	 .byte 48,49,50,51,52,53,54,55,56,57

eind_asm:


