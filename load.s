;.PAG 'LOAD FUNCTION'
;**********************************
;* LOAD RAM FUNCTION              *
;*                                *
;* LOADS FROM CASSETTE 1 OR 2, OR *
;* SERIAL BUS DEVICES >=4 TO 31   *
;* AS DETERMINED BY CONTENTS OF   *
;* VARIABLE FA. VERIFY FLAG IN .A *
;*                                *
;* ALT LOAD IF SA=0, NORMAL SA=1  *
;* .X , .Y LOAD ADDRESS IF SA=0   *
;* .A=0 PERFORMS LOAD,<> IS VERIFY*
;*                                *
;* HIGH LOAD RETURN IN X,Y.       *
;*                                *
;**********************************
;.SKI 3
LOADSP	STX MEMUSS      ;.X HAS LOW ALT START
	STY MEMUSS+1
LOAD	JMP (ILOAD)     ;MONITOR LOAD ENTRY
;
NLOAD	STA VERCK       ;STORE VERIFY FLAG
	LDA #0
	STA STATUS
;
	LDA FA          ;CHECK DEVICE NUMBER
	BNE LD20
;
LD10	JMP ERROR9      ;BAD DEVICE #-KEYBOARD
;
LD20	CMP #3
	BEQ LD10        ;DISALLOW SCREEN LOAD
	BCC LD100       ;HANDLE TAPES DIFFERENT
;
;LOAD FROM CBM IEEE DEVICE
;
	LDY FNLEN       ;MUST HAVE FILE NAME
	BNE LD25        ;YES...OK
;
	JMP ERROR8      ;MISSING FILE NAME
;
LD25	LDX SA          ;SAVE SA IN .X
	JSR LUKING      ;TELL USER LOOKING
	LDA #$60        ;SPECIAL LOAD COMMAND
	STA SA
	JSR OPENI       ;OPEN THE FILE
;
	LDA FA
	JSR TALK        ;ESTABLISH THE CHANNEL
	LDA SA
	JSR TKSA        ;TELL IT TO LOAD
;
	JSR ACPTR       ;GET FIRST BYTE
	STA EAL
;
	LDA STATUS      ;TEST STATUS FOR ERROR
	LSR A
	LSR A
	BCS LD90        ;FILE NOT FOUND...
	JSR ACPTR
	STA EAH
;
	TXA             ;FIND OUT OLD SA
	BNE LD30        ;SA<>0 USE DISK ADDRESS
	LDA MEMUSS      ;ELSE LOAD WHERE USER WANTS
	STA EAL
	LDA MEMUSS+1
	STA EAH
LD30	JSR LODING      ;TELL USER LOADING
;
LD40	LDA #$FD        ;MASK OFF TIMEOUT
	AND STATUS
	STA STATUS
;
	JSR STOP        ;STOP KEY?
	BNE LD45        ;NO...
;
	JMP BREAK       ;STOP KEY PRESSED
;
LD45	JSR ACPTR       ;GET BYTE OFF IEEE
	TAX
	LDA STATUS      ;WAS THERE A TIMEOUT?
	LSR A
	LSR A
	BCS LD40        ;YES...TRY AGAIN
	TXA
	LDY VERCK       ;PERFORMING VERIFY?
	BEQ LD50        ;NO...LOAD
	LDY #0
	CMP (EAL),Y      ;VERIFY IT
	BEQ LD60        ;O.K....
	LDA #SPERR      ;NO GOOD...VERIFY ERROR
	JSR UDST        ;UPDATE STATUS
	.BYT $2C        ;SKIP NEXT STORE
;
LD50	STA (EAL),Y
LD60	INC EAL         ;INCREMENT STORE ADDR
	BNE LD64
	INC EAH
LD64	BIT STATUS      ;EOI?
	BVC LD40        ;NO...CONTINUE LOAD
;
	JSR UNTLK       ;CLOSE CHANNEL
	JSR CLSEI       ;CLOSE THE FILE
	BCC LD180       ;BRANCH ALWAYS
;
LD90	JMP ERROR4      ;FILE NOT FOUND
;
;LOAD FROM TAPE
;
LD100	LSR A
	BCS LD102       ;IF C-SET THEN IT'S CASSETTE
;
	JMP ERROR9      ;BAD DEVICE #
;
LD102	JSR ZZZ         ;SET POINTERS AT TAPE
	BCS LD104
	JMP ERROR9      ;DEALLOCATED...
LD104	JSR CSTE1       ;TELL USER ABOUT BUTTONS
	BCS LD190       ;STOP KEY PRESSED?
	JSR LUKING      ;TELL USER SEARCHING
;
LD112	LDA FNLEN       ;IS THERE A NAME?
	BEQ LD150       ;NONE...LOAD ANYTHING
	JSR FAF         ;FIND A FILE ON TAPE
	BCC LD170       ;GOT IT!
	BEQ LD190       ;STOP KEY PRESSED
	BCS LD90        ;NOPE..;.END OF TAPE
;
LD150	JSR FAH         ;FIND ANY HEADER
	BEQ LD190       ;STOP KEY PRESSED
	BCS LD90        ;NO HEADER
;
LD170	LDA STATUS
	AND #SPERR      ;MUST GOT HEADER RIGHT
	SEC
	BNE LD190       ;IS BAD
;
	CPX #BLF        ;IS IT A MOVABLE PROGRAM...
	BEQ LD178       ;YES
;
	CPX #PLF        ;IS IT A PROGRAM
	BNE LD112       ;NO...ITS SOMETHING ELSE
;
LD177	LDY #1          ;FIXED LOAD...
	LDA (TAPE1),Y    ;...THE ADDRESS IN THE...
	STA MEMUSS      ;...BUFFER IS THE START ADDRESS
	INY
	LDA (TAPE1),Y
	STA MEMUSS+1
	BCS LD179       ;JMP ..CARRY SET BY CPX'S
;
LD178	LDA SA          ;CHECK FOR MONITOR LOAD...
	BNE LD177       ;...YES WE WANT FIXED TYPE
;
LD179	LDY #3          ;TAPEA - TAPESTA
;CARRY SET BY CPX'S
	LDA (TAPE1),Y
	LDY #1
	SBC (TAPE1),Y
	TAX             ;LOW TO .X
	LDY #4
	LDA (TAPE1),Y
	LDY #2
	SBC (TAPE1),Y
	TAY             ;HIGH TO .Y
;
	CLC             ;EA = STA+(TAPEA-TAPESTA)
	TXA
	ADC MEMUSS      ;
	STA EAL
	TYA
	ADC MEMUSS+1
	STA EAH
	LDA MEMUSS      ;SET UP STARTING ADDRESS
	STA STAL
	LDA MEMUSS+1
	STA STAH
	JSR LODING      ;TELL USER LOADING
	JSR TRD         ;DO TAPE BLOCK LOAD
	.BYT $24        ;CARRY FROM TRD
;
LD180	CLC             ;GOOD EXIT
;
; SET UP END LOAD ADDRESS
;
	LDX EAL
	LDY EAH
;
LD190	RTS
;.SKI 5
;SUBROUTINE TO PRINT TO CONSOLE:
;
;SEARCHING [FOR NAME]
;
LUKING	LDA MSGFLG      ;SUPPOSED TO PRINT?
	BPL LD115       ;...NO
	LDY #MS5-MS1    ;"SEARCHING"
	JSR MSG
	LDA FNLEN
	BEQ LD115
	LDY #MS6-MS1    ;"FOR"
	JSR MSG
;.SKI 3
;SUBROUTINE TO OUTPUT FILE NAME
;
OUTFN	LDY FNLEN       ;IS THERE A NAME?
	BEQ LD115       ;NO...DONE
	LDY #0
LD110	LDA (FNADR),Y
	JSR BSOUT
	INY
	CPY FNLEN
	BNE LD110
;
LD115	RTS
;.SKI 3
;SUBROUTINE TO PRINT:
;
;LOADING/VERIFING
;
LODING	LDY #MS10-MS1   ;ASSUME 'LOADING'
	LDA VERCK       ;CHECK FLAG
	BEQ LD410       ;ARE DOING LOAD
	LDY #MS21-MS1   ;ARE 'VERIFYING'
LD410	JMP SPMSG
;.END