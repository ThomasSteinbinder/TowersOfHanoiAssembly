;
; Towers of Hanoi - Assembly
;
; TOHAsm.asm
;
; Created: 18.10.2019 22:24:48
; Author : Thomas Steinbinder
;

// Values for the plates (first 3 bits can be ignored)
.EQU smallPlatePattern		= 0b00000100 // = 4 / 0x04
.EQU medPlatePattern		= 0b00001110 // = 14 / 0x0E
.EQU bigPlatePattern		= 0b00011111 // = 31 / 0x1F

.EQU stack1Button			= PD2
.EQU stack2Button			= PD3
.EQU stack3Button			= PD4
.EQU statusLed1				= PD5
.EQU statusLed2				= PD6
.EQU statusLed3				= PD7

.DEF currentStack			= r20
.DEF topPlateTemp			= r21
.DEF midPlateTemp			= r22
.DEF botPlateTemp			= r23
.DEF statusLedCurrentStack	= r24


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
	cbr r16, (1 << PD2) | (1 << PD3) | (1 << PD4)
	out DDRD, r16

	// Fill first stack
	ldi r16, smallPlatePattern
	sts startTop, r16
	ldi r16, medPlatePattern
	sts startMid, r16
	ldi r16, bigPlatePattern
	sts startBot, r16

	rjmp loop


loop:
	// debug stuff...
	lds r23, startTop
	lds r24, startMid
	lds r25, startBot
	lds r26, helpTop
	lds r27, helpMid
	lds r28, helpBot
	lds r29, goalTop
	lds r30, goalMid
	lds r31, goalBot
	nop
	nop
	nop

	sbic PIND, PD2 // button 1 pressed		
		ldi currentStack, 0
	sbic PIND, PD3 // button 2 pressed
		ldi currentStack, 1
	sbic PIND, PD4 // button 3 pressed
		ldi currentStack, 2

	// Pick or drop?
	lds r16, pickPlate
	cpi r16, 0 // Check if pickPlate is not yet set	
	breq pickIt // if so -> this is the first selected stack
	rjmp dropIt // else it's the second selected stack

	pickIt:
		rcall pullCurrentStack
		rcall Pick
		rjmp checkIfWon

	dropIt:
		rcall pushCurrentStack
		rcall Drop


	checkIfWon:
	lds r16, goalTop
	cpi r16, 0
	brne won

rjmp loop


won:
	nop// game is won!
	rjmp loop


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
	
	cbi PORTD, (statusLed1) | (statusLed2) | (statusLed3)
	clr r16
	sts pickPlate, r16

	pop r16
ret