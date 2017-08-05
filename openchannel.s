;.PAG 'OPEN CHANNEL'
;***************************************
;* CHKIN -- OPEN CHANNEL FOR INPUT     *
;*                                     *
;* THE NUMBER OF THE LOGICAL FILE TO BE*
;* OPENED FOR INPUT IS PASSED IN .X.   *
;* CHKIN SEARCHES THE LOGICAL FILE     *
;* TO LOOK UP DEVICE AND COMMAND INFO. *
;* ERRORS ARE REPORTED IF THE DEVICE   *
;* WAS NOT OPENED FOR INPUT ,(E.G.     *
;* CASSETTE WRITE FILE), OR THE LOGICAL*
;* FILE HAS NO REFERENCE IN THE TABLES.*
;* DEVICE 0, (KEYBOARD), AND DEVICE 3  *
;* (SCREEN), REQUIRE NO TABLE ENTRIES  *
;* AND ARE HANDLED SEPARATE.           *
;***************************************
;
NCHKIN	JSR LOOKUP      ;SEE IF FILE KNOWN
	BEQ JX310       ;YUP...
;
	JMP ERROR3      ;NO...FILE NOT OPEN
;
JX310	JSR JZ100       ;EXTRACT FILE INFO
;
	LDA FA
	BEQ JX320       ;IS KEYBOARD...DONE.
;
;COULD BE SCREEN, KEYBOARD, OR SERIAL
;
	CMP #3
	BEQ JX320       ;IS SCREEN...DONE.
	BCS JX330       ;IS SERIAL...ADDRESS IT
	CMP #2          ;RS232?
	BNE JX315       ;NO...
;
	JMP CKI232
;
;SOME EXTRA CHECKS FOR TAPE
;
JX315	LDX SA
	CPX #$60        ;IS COMMAND A READ?
	BEQ JX320       ;YES...O.K....DONE
;
	JMP ERROR6      ;NOT INPUT FILE
;
JX320	STA DFLTN       ;ALL INPUT COME FROM HERE
;
	CLC             ;GOOD EXIT
	RTS
;
;AN SERIAL DEVICE HAS TO BE A TALKER
;
JX330	TAX             ;DEVICE # FOR DFLTO
	JSR TALK        ;TELL HIM TO TALK
;
	LDA SA          ;A SECOND?
	BPL JX340       ;YES...SEND IT
	JSR TKATN       ;NO...LET GO
	JMP JX350
;
JX340	JSR TKSA        ;SEND SECOND
;
JX350	TXA
	BIT STATUS      ;DID HE LISTEN?
	BPL JX320       ;YES
;
	JMP ERROR5      ;DEVICE NOT PRESENT
;.PAG 'OPEN CHANNEL OUT'
;***************************************
;* CHKOUT -- OPEN CHANNEL FOR OUTPUT     *
;*                                     *
;* THE NUMBER OF THE LOGICAL FILE TO BE*
;* OPENED FOR OUTPUT IS PASSED IN .X.  *
;* CHKOUT SEARCHES THE LOGICAL FILE    *
;* TO LOOK UP DEVICE AND COMMAND INFO. *
;* ERRORS ARE REPORTED IF THE DEVICE   *
;* WAS NOT OPENED FOR INPUT ,(E.G.     *
;* KEYBOARD), OR THE LOGICAL FILE HAS   *
;* REFERENCE IN THE TABLES.             *
;* DEVICE 0, (KEYBOARD), AND DEVICE 3  *
;* (SCREEN), REQUIRE NO TABLE ENTRIES  *
;* AND ARE HANDLED SEPARATE.           *
;***************************************
;
NCKOUT	JSR LOOKUP      ;IS FILE IN TABLE?
	BEQ CK5         ;YES...
;
	JMP ERROR3      ;NO...FILE NOT OPEN
;
CK5	JSR JZ100       ;EXTRACT TABLE INFO
;
	LDA FA          ;IS IT KEYBOARD?
	BNE CK10        ;NO...SOMETHING ELSE.
;
CK20	JMP ERROR7      ;YES...NOT OUTPUT FILE
;
;COULD BE SCREEN,SERIAL,OR TAPES
;
CK10	CMP #3
	BEQ CK30        ;IS SCREEN...DONE
	BCS CK40        ;IS SERIAL...ADDRESS IT
	CMP #2          ;RS232?
	BNE CK15
;
	JMP CKO232
;
;
;SPECIAL TAPE CHANNEL HANDLING
;
CK15	LDX SA
	CPX #$60        ;IS COMMAND READ?
	BEQ CK20        ;YES...ERROR
;
CK30	STA DFLTO       ;ALL OUTPUT GOES HERE
;
	CLC             ;GOOD EXIT
	RTS
;
CK40	TAX             ;SAVE DEVICE FOR DFLTO
	JSR LISTN       ;TELL HIM TO LISTEN
;
	LDA SA          ;IS THERE A SECOND?
	BPL CK50        ;YES...
;
	JSR SCATN       ;NO...RELEASE LINES
	BNE CK60        ;BRANCH ALWAYS
;
CK50	JSR SECND       ;SEND SECOND...
;
CK60	TXA
	BIT STATUS      ;DID HE LISTEN?
	BPL CK30        ;YES...FINISH UP
;
	JMP ERROR5      ;NO...DEVICE NOT PRESENT
;.END