;
; Towers of Hanoi - Assembly
;
; TOHAsm.asm
;
; Created: 18.10.2019 22:24:48
; Author : Thomas Steinbinder
;

// Values for the plates (first 3 bits can be ignored)
.EQU smallPlatePattern			= 0b00000100 // = 4 / 0x04
.EQU medPlatePattern			= 0b00001110 // = 14 / 0x0E
.EQU bigPlatePattern			= 0b00011111 // = 31 / 0x1F

// Pins for the shift registers
.EQU data						= PB1 // pin 9
.EQU latch						= PB2 // pin 10
.EQU clock						= PB3 // pin 11

.EQU stack1Button				= PD2
.EQU stack2Button				= PD3
.EQU stack3Button				= PD4
.EQU statusLed1					= PD5
.EQU statusLed2					= PD6
.EQU statusLed3					= PD7

.DEF currentStack				= r18
.DEF topPlateTemp				= r19
.DEF midPlateTemp				= r20
.DEF botPlateTemp				= r21
.DEF statusLedCurrentStack		= r22
.DEF currentPlateMaxSizePattern	= r23


.DSEG
	// Vars for the 3 plate slots on each of the 3 stacks
	startTop:	.BYTE	1
	startMid:	.BYTE	1
	startBot:	.BYTE	1

	helpTop:	.BYTE	1
	helpMid:	.BYTE	1
	helpBot:	.BYTE	1

	goalTop:	.BYTE	1
	goalMid:	.BYTE	1
	goalBot:	.BYTE	1

	// Temp var for plate to draw from
	pickPlate:	.BYTE	1

.CSEG

; Replace with your application code
start:
	
	// Pin 2, 3, 4 as input for buttons the rest as output
	ser r16
	cbr r16, (1 << stack1Button) | (1 << stack2Button) | (1 << stack3Button)
	out DDRD, r16

	// All pins of PORTB as output 
	ser r16
	out DDRB, r16

	// clear all working registers:
	clr currentStack
	clr topPlateTemp
	clr midPlateTemp
	clr botPlateTemp
	clr statusLedCurrentStack
	clr currentPlateMaxSizePattern

	// Fill first stack
	ldi r16, smallPlatePattern	
	sts startTop, r16
	ldi r16, medPlatePattern
	sts startMid, r16
	ldi r16, bigPlatePattern
	sts startBot, r16

	// Clear the other stacks
	clr r16
	sts helpTop, r16
	sts helpMid, r16
	sts helpBot, r16
	sts goalTop, r16
	sts goalMid, r16
	sts goalBot, r16
	sts pickPlate, r16

	rcall DrawGame

	rjmp loop


loop:
	// debug stuff...	
	/*lds r23, startTop
	lds r24, startMid
	lds r25, startBot
	lds r26, helpTop
	lds r27, helpMid
	lds r28, helpBot
	lds r29, goalTop
	lds r30, goalMid
	lds r31, goalBot
	nop */

	ldi currentStack, 99 // invalid stack

	sbic PIND, PD2 // button 1 pressed		
		ldi currentStack, 0
	sbic PIND, PD3 // button 2 pressed
		ldi currentStack, 1
	sbic PIND, PD4 // button 3 pressed
		ldi currentStack, 2

	cpi currentStack, 99
	breq loop

	// Pick or drop?
	lds r16, pickPlate
	cpi r16, 0 // Check if pickPlate is not yet set	
	breq pickIt // if so -> this is the first selected stack
	rjmp dropIt // else it's the second selected stack

	pickIt:
		rcall pullCurrentStack
		rcall Pick
		rcall pushCurrentStack
		rjmp checkIfWon

	dropIt:
		rcall pullCurrentStack
		rcall Drop
		rcall pushCurrentStack

	checkIfWon:
	rcall drawGame
	rcall waitLong
	lds r16, goalTop
	cpi r16, 0
	brne won

rjmp loop


won:
	in r16, PORTD
	cbr r16, (1 << latch) | (1 << clock)
	out PORTB, r16

	cpi r17, 4
	brne Toggle2

	Toggle1:
		sbr r16, (1 << data)
		clr r17
		rjmp ToggleEnd

	Toggle2:
		cbr r16, (1 << data)
		inc r17;
		
	ToggleEnd:
	out PORTB, r16

	sbr r16, (1 << clock)
	out PORTB, r16

	sbr r16, (1 << latch)
	out PORTB, r16
	
	// wait:
	clr r16
	waitWon:
		rcall waitMedium
		inc r16
		cpi r16, 5
		brne waitWon

rjmp won


pullCurrentStack:
	cpi currentStack, 0 // If first stack is selected
	breq cacheStack1 // cache the first stack
	cpi currentStack, 1 // elseif second stack is selected
	breq cacheStack2 // cache the second stack
	
	// else cache third stack:
	cacheStack3:
		lds topPlateTemp, goalTop
		lds midPlateTemp, goalMid
		lds botPlateTemp, goalBot
		lds statusLedCurrentStack, statusLed3
		rjmp retCacheStack

	cacheStack2:
		lds topPlateTemp, helpTop
		lds midPlateTemp, helpMid
		lds botPlateTemp, helpBot
		lds statusLedCurrentStack, statusLed2
		rjmp retCacheStack

	cacheStack1:
		lds topPlateTemp, startTop
		lds midPlateTemp, startMid
		lds botPlateTemp, startBot
		lds statusLedCurrentStack, statusLed1

	retCacheStack:
ret


pushCurrentStack:
	cpi currentStack, 0 // If first stack is selected
	breq updateStack1 // update the first stack
	cpi currentStack, 1 // elseif second stack is selected
	breq updateStack2 // update the second stack
	
	// else update third stack:
	updateStack3:
		sts goalTop, topPlateTemp
		sts goalMid, midPlateTemp
		sts goalBot, botPlateTemp
		sts statusLed3, statusLedCurrentStack
		rjmp retUpdateStack

	updateStack2:
		sts helpTop, topPlateTemp
		sts helpMid, midPlateTemp
		sts helpBot, botPlateTemp
		sts statusLed2, statusLedCurrentStack
		rjmp retUpdateStack

	updateStack1:
		sts startTop, topPlateTemp
		sts startMid, midPlateTemp
		sts startBot, botPlateTemp
		sts statusLed1, statusLedCurrentStack

	retUpdateStack:
ret


Pick:
	push r16

	cpi topPlateTemp, 0
	breq checkMid // if top plate is empty -> check next one
	sts pickPlate, topPlateTemp // else pick it,
	clr topPlateTemp // remove it from the stack
	rjmp setStatusLed // and set status led (then return)
	
	// Check middle plate
	checkMid:
		cpi midPlateTemp, 0
		breq checkBot // if mid plate is empty -> check next one
		sts pickPlate, midPlateTemp // else pick it
		clr midPlateTemp // remove it from the stack
		rjmp setStatusLed // and set status led (then return)

	// Check bottom plate
	checkBot:
		cpi botPlateTemp, 0
		breq retBtnPick // if bot plate is empty -> return
		sts pickPlate, botPlateTemp // else pick it
		clr botPlateTemp // and remove it from the stack...

	setStatusLed:
		cpi currentStack, 0 // If first stack is selected
		breq setLed1 // set first led
		cpi currentStack, 1 // elseif second stack is selected
		breq setLed2 // set second led
		
		// else set third led
		setLed3:
			sbi PORTD, statusLed3
			rjmp retBtnPick
		setLed2:
			sbi PORTD, statusLed2
			rjmp retBtnPick
		setLed1:
			sbi PORTD, statusLed1
			rjmp retBtnPick

	retBtnPick:
		pop r16
ret


Drop:
	push r17

	lds r17, pickPlate

	// Check bottom slot
	cpi botPlateTemp, 0 // if bot is not empty
	brne compareBotAndPicked // check if its smaller than pickedPlate
	mov botPlateTemp, r17 // else drop it
	rcall successfulDrop // clear status leds
	rjmp retBtnDrop // and return
	compareBotAndPicked:
		cp r17, botPlateTemp // if pickedPlate is greater than current plate on stack
		brge retBtnDrop // return... else:

	// Check middle slot
	cpi midPlateTemp, 0 // if mid is not empty
	brne compareMidAndPicked // check if its smaller than pickedPlate
	mov midPlateTemp, r17 // else drop it
	rcall successfulDrop // clear status leds
	rjmp retBtnDrop // and return
	compareMidAndPicked:
		cp r17, midPlateTemp // if pickedPlate is greater than current plate on stack
		brge retBtnDrop // return... else:

	// top plate must empty (or pick- and drop-stack are identical)
	mov topPlateTemp, r17 // so just drop it
	rcall successfulDrop // clear status LEDS and return

	retBtnDrop:
		pop r17
ret

// Kills all the status leds and clears the temp pickedPlate field
successfulDrop:
	push r16

	lds r16, PORTD
	cbr r16, (1 >> statusLed1) | (1 >> statusLed2) | (1 >> statusLed3)
	out PORTD, r16
	clr r16
	sts pickPlate, r16

	pop r16
ret


drawGame:
	push r16

	lds currentStack, goalBot
	ldi currentPlateMaxSizePattern, bigPlatePattern
	rcall drawCurrentStack
	lds currentStack, goalMid
	ldi currentPlateMaxSizePattern, medPlatePattern
	rcall drawCurrentStack
	lds currentStack, goalTop
	ldi currentPlateMaxSizePattern, smallPlatePattern
	rcall drawCurrentStack

	lds currentStack, helpBot
	ldi currentPlateMaxSizePattern, bigPlatePattern
	rcall drawCurrentStack
	lds currentStack, helpMid
	ldi currentPlateMaxSizePattern, medPlatePattern
	rcall drawCurrentStack
	lds currentStack, helpTop
	ldi currentPlateMaxSizePattern, smallPlatePattern
	rcall drawCurrentStack

	lds currentStack, startBot
	ldi currentPlateMaxSizePattern, bigPlatePattern
	rcall drawCurrentStack
	lds currentStack, startMid
	ldi currentPlateMaxSizePattern, medPlatePattern
	rcall drawCurrentStack
	lds currentStack, startTop
	ldi currentPlateMaxSizePattern, smallPlatePattern
	rcall drawCurrentStack
	
	sbr r16, (1 << latch)
	out PORTB, r16

	pop r16
ret


drawCurrentStack:
	push r16
	push r17

	// how many bits does this plate have?
	cpi currentPlateMaxSizePattern, bigPlatePattern // if current plate is big (5 bits)
	brge fiveBits // draw five bits
	cpi currentPlateMaxSizePattern, medPlatePattern // if current plate is med (3 bits)
	brge threeBits // draw 3 bits
	// else draw one bit:

	oneBit:
		ldi r17, 1
		clc
		ror currentStack
		ror currentStack
		rjmp loopShift
	threeBits:
		ldi r17, 3
		clc
		ror currentStack
		rjmp loopShift
	fiveBits:
		ldi r17, 5		

	loopShift:
		// Reset latch and clock
		in r16, PORTB
		cbr r16, (1 << latch) | (1 << clock)
		out PORTB, r16

		sbrs currentStack, 0
		rjmp clearBit
		setBit:
			sbr r16, (1 << data)
			rjmp goShift
		clearBit:
			cbr r16, (1 << data)

		goShift:
			out PORTB, r16 // set data bit 

			sbr r16, (1 << clock) // shift
			out PORTB, r16
			dec r17
			clc
			ror currentStack

			cpi r17, 0
			brne loopShift			
	pop r16
	pop r17
ret


waitLong:
	push r16
	push r17
	ser r16
	ser r17

	waitLongLoop:
		waitLongInnerLoop:
			rcall waitShort
			inc r17
			cpi r17, 0xFF
			brne waitLongInnerLoop
		inc r16
		cpi r16, 15
		brne waitLongLoop

	pop r17
	pop r16
ret


waitMedium:
	push r16
	ser r16

	waitMedLoop:
		rcall waitShort
		inc r16
		cpi r16, 0xFF
		brne waitMedLoop

	pop r16
ret

waitShort:
	push r16
	ser r16

	waitLoop:
		inc r16
		cpi r16, 0xFF
		brne waitLoop

	pop r16
ret