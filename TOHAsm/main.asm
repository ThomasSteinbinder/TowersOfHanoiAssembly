;
; Towers of Hanoi - Assembly
;
; TOHAsm.asm
;
; Created: 18.10.2019 22:24:48
; Author : Thomas Steinbinder
;

// Values for the plates (first 3 bits can be ignored)
.EQU smallPlatePattern	= 0b00000100 // = 4 / 0x04
.EQU medPlatePattern	= 0b00001110 // = 14 / 0x0E
.EQU bigPlatePattern	= 0b00011111 // = 31 / 0x1F

.EQU stack1Button		= PD2
.EQU stack2Button		= PD3
.EQU stack3Button		= PD4
.EQU statusLed1			= PD5
.EQU statusLed2			= PD6
.EQU statusLed3			= PD7

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
	nop
	nop

	sbic PIND, PD2 // button 1 pressed
		rcall button1
	sbic PIND, PD3 // button 2 pressed
		rcall button2
	sbic PIND, PD4 // button 3 pressed
		rcall button3

	// check if won:
	lds r16, goalTop
	cpi r16, 0
	brne won

rjmp loop

won:
	nop// game is won!
	rjmp loop

button1:
	push r16

	// Is this the second stack selected or the first?
	lds r16, pickPlate
	cpi r16, 0 // Check if pickPlate is not yet set	
	breq pickIt1 // if so -> this is the first selected stack
	rjmp dropIt1 // else it's the second selected stack

	pickIt1:
		rcall button1Pick
		rjmp retBtn1

	dropIt1:
		rcall button1Drop

	retBtn1:
		pop r16
ret


button1Pick:
	push r16

	// Check top plate slot
	lds r16, startTop
	cpi r16, 0
	breq checkMid1 // if top plate is empty -> check next one
	sts pickPlate, r16 // else pick it,
	clr r16 // remove it from the stack
	sts startTop, r16 
	rjmp setStatusLed1 // and set status led (then return)
	
	// Check middle plate
	checkMid1:
		lds r16, startMid
		cpi r16, 0
		breq checkBot1 // if mid plate is empty -> check next one
		sts pickPlate, r16 // else pick it
		clr r16 // remove it from the stack
		sts startMid, r16 
		rjmp setStatusLed1 // and set status led (then return)

	// Check bottom plate
	checkBot1:
		lds r16, startBot
		cpi r16, 0
		breq retBtn1Pick // if bot plate is empty -> return
		sts pickPlate, r16 // else pick it
		clr r16 // and remove it from the stack... TODO: actually this should be done after droping the plate... the pick-position should be saved somehow...
		sts startBot, r16 

	setStatusLed1:
		sbi PORTD, statusLed1

	retBtn1Pick:
		pop r16
ret


button1Drop:
	push r16
	push r17

	lds r17, pickPlate

	// Check bottom slot
	lds r16, startBot
	cpi r16, 0 // if bot is not empty
	brne compareBotAndPicked1 // check if its smaller than pickedPlate
	sts startBot, r17 // else drop it
	rcall successfulDrop // clear status leds
	rjmp retBtn1Drop // and return
	compareBotAndPicked1:
		cp r17, r16 // if pickedPlate is greater than current plate on stack
		brge retBtn1Drop // return... else:

	// Check middle slot
	lds r16, startMid
	cpi r16, 0 // if mid is not empty
	brne compareMidAndPicked1 // check if its smaller than pickedPlate
	sts startMid, r17 // else drop it
	rcall successfulDrop // clear status leds
	rjmp retBtn1Drop // and return
	compareMidAndPicked1:
		cp r17, r16 // if pickedPlate is greater than current plate on stack
		brge retBtn1Drop // return... else:

	// top plate must empty (or pick- and drop-stack are identical)
	sts startTop, r17 // so just drop it
	rcall successfulDrop // clear status LEDS and return

	retBtn1Drop:
		pop r16
		pop r17
ret


// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------

button2:
	push r16

	// Is this the second stack selected or the first?
	lds r16, pickPlate
	cpi r16, 0 // Check if pickPlate is not yet set	
	breq pickIt2 // if so -> this is the first selected stack
	rjmp dropIt2 // else it's the second selected stack

	pickIt2:
		rcall button2Pick
		rjmp retBtn2

	dropIt2:
		rcall button2Drop

	retBtn2:
		pop r16
ret


button2Pick:
	push r16

	// Check top plate slot
	lds r16, helpTop
	cpi r16, 0
	breq checkMid2 // if top plate is empty -> check next one
	sts pickPlate, r16 // else pick it
	clr r16 // remove it from the stack
	sts helpTop, r16 
	rjmp setStatusLed2 // and set status led (then return)
	
	// Check middle plate
	checkMid2:
		lds r16, helpMid
		cpi r16, 0
		breq checkBot2 // if mid plate is empty -> check next one
		sts pickPlate, r16 // else pick it
		clr r16 // remove it from the stack
		sts helpMid, r16 
		rjmp setStatusLed2 // and set status led (then return)

	// Check bottom plate
	checkBot2:
		lds r16, helpBot
		cpi r16, 0
		breq retBtn2Pick // if bot plate is empty -> return
		sts pickPlate, r16 // else pick it
		clr r16 // and remove it from the stack
		sts helpBot, r16 

	setStatusLed2:
		sbi PORTD, statusLed2

	retBtn2Pick:
		pop r16
ret


button2Drop:
	push r16
	push r17

	lds r17, pickPlate

	// Check bottom slot
	lds r16, helpBot
	cpi r16, 0 // if bot is not empty
	brne compareBotAndPicked2 // check if its smaller than pickedPlate
	sts helpBot, r17 // else drop it
	rcall successfulDrop // clear status leds
	rjmp retBtn2Drop // and return
	compareBotAndPicked2:
		cp r17, r16 // if pickedPlate is greater than current plate on stack
		brge retBtn2Drop // return... else:

	// Check middle slot
	lds r16, helpMid
	cpi r16, 0 // if mid is not empty
	brne compareMidAndPicked2 // check if its smaller than pickedPlate
	sts helpMid, r17 // else drop it
	rcall successfulDrop // clear status leds
	rjmp retBtn2Drop // and return
	compareMidAndPicked2:
		cp r17, r16 // if pickedPlate is greater than current plate on stack
		brge retBtn2Drop // return... else:

	// top plate must empty (or pick- and drop-stack are identical)
	sts helpTop, r17 // so just drop it
	rcall successfulDrop // clear status LEDS and return

	retBtn2Drop:
		pop r16
		pop r17
ret


// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------

button3:
	push r16

	// Is this the second stack selected or the first?
	lds r16, pickPlate
	cpi r16, 0 // Check if pickPlate is not yet set	
	breq pickIt3 // if so -> this is the first selected stack
	rjmp dropIt3 // else it's the second selected stack

	pickIt3:
		rcall button3Pick
		rjmp retBtn3

	dropIt3:
		rcall button3Drop

	retBtn3:
		pop r16
ret


button3Pick:
	push r16

	// Check top plate slot
	lds r16, goalTop
	cpi r16, 0
	breq checkMid3 // if top plate is empty -> check next one
	sts pickPlate, r16 // else pick it
	clr r16 // remove it from the stack
	sts goalTop, r16 
	rjmp setStatusLed3 // and set status led (then return)
	
	// Check middle plate
	checkMid3:
		lds r16, goalMid
		cpi r16, 0
		breq checkBot3 // if mid plate is empty -> check next one
		sts pickPlate, r16 // else pick it
		clr r16 // remove it from the stack
		sts goalMid, r16 
		rjmp setStatusLed3 // and set status led (then return)

	// Check bottom plate
	checkBot3:
		lds r16, goalBot
		cpi r16, 0
		breq retBtn3Pick // if bot plate is empty -> return
		sts pickPlate, r16 // else pick it
		clr r16 // and remove it from the stack
		sts goalBot, r16 

	setStatusLed3:
		sbi PORTD, statusLed3

	retBtn3Pick:
		pop r16
ret


button3Drop:
	push r16
	push r17

	lds r17, pickPlate

	// Check bottom slot
	lds r16, goalBot
	cpi r16, 0 // if bot is not empty
	brne compareBotAndPicked3 // check if its smaller than pickedPlate
	sts goalBot, r17 // else drop it
	rcall successfulDrop // clear status leds
	rjmp retBtn3Drop // and return
	compareBotAndPicked3:
		cp r17, r16 // if pickedPlate is greater than current plate on stack
		brge retBtn3Drop // return... else:

	// Check middle slot
	lds r16, goalMid
	cpi r16, 0 // if mid is not empty
	brne compareMidAndPicked3 // check if its smaller than pickedPlate
	sts goalMid, r17 // else drop it
	rcall successfulDrop // clear status leds
	rjmp retBtn3Drop // and return
	compareMidAndPicked3:
		cp r17, r16 // if pickedPlate is greater than current plate on stack
		brge retBtn3Drop // return... else:

	// top plate must empty (or pick- and drop-stack are identical)
	sts goalTop, r17 // so just drop it
	rcall successfulDrop // clear status LEDS and return

	retBtn3Drop:
		pop r16
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