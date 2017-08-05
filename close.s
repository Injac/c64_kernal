;.PAG 'CLOSE'
;***************************************
;* CLOSE -- CLOSE LOGICAL FILE       *
;*                                   *
;*     THE LOGICAL FILE NUMBER OF THE*
;* FILE TO BE CLOSED IS PASSED IN .A.*
;* KEYBOARD, SCREEN, AND FILES NOT   *
;* OPEN PASS STRAIGHT THROUGH. TAPE  *
;* FILES OPEN FOR WRITE ARE CLOSED BY*
;* DUMPING THE LAST BUFFER AND       *
;* CONDITIONALLY WRITING AN END OF   *
;* TAPE BLOCK.SERIAL FILES ARE CLOSED*
;* BY SENDING A CLOSE FILE COMMAND IF*
;* A SECONDARY ADDRESS WAS SPECIFIED *
;* IN ITS OPEN COMMAND.              *
;***************************************
;
NCLOSE	JSR JLTLK       ;LOOK FILE UP
	BEQ JX050       ;OPEN...
	CLC             ;ELSE RETURN
	RTS
;
JX050	JSR JZ100       ;EXTRACT TABLE DATA
	TXA             ;SAVE TABLE INDEX
	PHA
;
	LDA FA          ;CHECK DEVICE NUMBER
	BEQ JX150       ;IS KEYBOARD...DONE
	CMP #3
	BEQ JX150       ;IS SCREEN...DONE
	BCS JX120       ;IS SERIAL...PROCESS
	CMP #2          ;RS232?
	BNE JX115       ;NO...
;
; RS-232 CLOSE
;
; REMOVE FILE FROM TABLES
	PLA
	JSR JXRMV
;
	JSR CLN232      ;CLEAN UP RS232 FOR CLOSE
;
; DEALLOCATE BUFFERS
;
	JSR GETTOP      ;GET MEMSIZ
	LDA RIBUF+1     ;CHECK INPUT ALLOCATION
	BEQ CLS010      ;NOT...ALLOCATED
	INY
CLS010	LDA ROBUF+1     ;CHECK OUTPUT ALLOCATION
	BEQ CLS020
	INY
CLS020	LDA #00         ;DEALLOCATE
	STA RIBUF+1
	STA ROBUF+1
; FLAG TOP OF MEMORY CHANGE
	JMP MEMTCF      ;GO SET NEW TOP
;
;CLOSE CASSETTE FILE
;
JX115	LDA SA          ;WAS IT A TAPE READ?
	AND #$F
	BEQ JX150       ;YES
;
	JSR ZZZ         ;NO. . .IT IS WRITE
	LDA #0          ;END OF FILE CHARACTER
	SEC             ;NEED TO SET CARRY FOR CASOUT (ELSE RS232 OUTPUT!)
	JSR CASOUT      ;PUT IN END OF FILE
	JSR WBLK
	BCC JX117       ;NO ERRORS...
	PLA             ;CLEAN STACK FOR ERROR
	LDA #0          ;BREAK KEY ERROR
	RTS
;
JX117	LDA SA
	CMP #$62        ;WRITE END OF TAPE BLOCK?
	BNE JX150       ;NO...
;
	LDA #EOT
	JSR TAPEH       ;WRITE END OF TAPE BLOCK
	JMP JX150
;
;CLOSE AN SERIAL FILE
;
JX120	JSR CLSEI
;
;ENTRY TO REMOVE A GIVE LOGICAL FILE
;FROM TABLE OF LOGICAL, PRIMARY,
;AND SECONDARY ADDRESSES
;
JX150	PLA             ;GET TABLE INDEX OFF STACK
;
; JXRMV - ENTRY TO USE AS AN RS-232 SUBROUTINE
;
JXRMV	TAX
	DEC LDTND
	CPX LDTND       ;IS DELETED FILE AT END?
	BEQ JX170       ;YES...DONE
;
;DELETE ENTRY IN MIDDLE BY MOVING
;LAST ENTRY TO THAT POSITION.
;
	LDY LDTND
	LDA LAT,Y
	STA LAT,X
	LDA FAT,Y
	STA FAT,X
	LDA SAT,Y
	STA SAT,X
;
JX170	CLC             ;CLOSE EXIT
JX175	RTS
;.SKI 5
;LOOKUP TABLIZED LOGICAL FILE DATA
;
LOOKUP	LDA #0
	STA STATUS
	TXA
JLTLK	LDX LDTND
JX600	DEX
	BMI JZ101
	CMP LAT,X
	BNE JX600
	RTS
;.SKI 5
;ROUTINE TO FETCH TABLE ENTRIES
;
JZ100	LDA LAT,X
	STA LA
	LDA FAT,X
	STA FA
	LDA SAT,X
	STA SA
JZ101	RTS
;.END
; RSR  5/12/82 - MODIFY FOR CLN232