            TTL Lab Exercise Five: APSR Glossary
;****************************************************************
;Polled Serial I/O using UART0 on KL05Z
;Inputs characters from terminal and prints APSR glossary
;Name:  Arnav Gawas
;Date:  March 20, 2026
;Class: CMPE-250
;Section: All sections
;****************************************************************
            THUMB
            OPT 64
            GET  MKL05Z4.s
            OPT 1

;---------------------------------------------------------------
;EQUATES
CR          EQU 0x0D
LF          EQU 0x0A
NULL        EQU 0x00

;UART0 registers (KL05 manual)
SIM_SCGC4   EQU 0x40048034
SIM_SCGC5   EQU 0x40048038
SIM_SOPT2   EQU 0x40048004
PORTB_PCR1  EQU 0x4004A004
PORTB_PCR2  EQU 0x4004A008
UART0_BDH   EQU 0x4006A000
UART0_BDL   EQU 0x4006A001
UART0_C1    EQU 0x4006A002
UART0_C2    EQU 0x4006A003
UART0_S1    EQU 0x4006A004
UART0_D     EQU 0x4006A007

;---------------------------------------------------------------
            AREA    MyCode,CODE,READONLY
            ENTRY
            EXPORT  Reset_Handler
            IMPORT  Startup
            IMPORT  PutPrompt
            IMPORT  Carry
            IMPORT  Negative
            IMPORT  Overflow
            IMPORT  Zero

;---------------------------------------------------------------
Reset_Handler  PROC
            CPSID   I               ; Mask interrupts
            BL      Startup         ; KL05 startup, 48 MHz
            BL      Init_UART0_Polling
MainLoop
            BL      PutPrompt

GetInput
            BL      GetChar         ; R0 = typed char
            MOV     R1, R0          ; save original char

; Convert lowercase a-z to uppercase
            CMP     R0, #'a'
            BLT     CheckCmd
            CMP     R0, #'z'
            BGT     CheckCmd
            SUBS    R0, R0, #32     ; 'a' → 'A'

CheckCmd
            CMP     R0, #'C'
            BEQ     DoC
            CMP     R0, #'N'
            BEQ     DoN
            CMP     R0, #'V'
            BEQ     DoV
            CMP     R0, #'Z'
            BEQ     DoZ

            B       GetInput        ; invalid → retry

DoC
            MOV     R0, R1
            BL      PutChar
            BL      Carry
            B       MainLoop

DoN
            MOV     R0, R1
            BL      PutChar
            BL      Negative
            B       MainLoop

DoV
            MOV     R0, R1
            BL      PutChar
            BL      Overflow
            B       MainLoop

DoZ
            MOV     R0, R1
            BL      PutChar
            BL      Zero
            B       MainLoop
            ENDP

;---------------------------------------------------------------
; UART Initialization for 9600 baud, 8N1
;---------------------------------------------------------------
Init_UART0_Polling
            PUSH    {R0-R3,LR}

; Enable UART0 clock (bit 10 in SCGC4)
            LDR     R0, =SIM_SCGC4
            LDR     R1, [R0]
            ORR     R1, R1, #(1 << 10)
            STR     R1, [R0]

; Enable PORTB clock (bit 10 in SCGC5)
            LDR     R0, =SIM_SCGC5
            LDR     R1, [R0]
            ORR     R1, R1, #(1 << 10)
            STR     R1, [R0]

; Select MCGFLLCLK for UART0
            LDR     R0, =SIM_SOPT2
            LDR     R1, [R0]
            ORR     R1, R1, #(1 << 26) ; UART0SRC = 01
            STR     R1, [R0]

; PORTB1 = ALT2 (TX)
            LDR     R0, =PORTB_PCR1
            MOV     R1, #2
            LSLS    R1, R1, #8
            STR     R1, [R0]

; PORTB2 = ALT2 (RX)
            LDR     R0, =PORTB_PCR2
            MOV     R1, #2
            LSLS    R1, R1, #8
            STR     R1, [R0]

; Disable UART0
            LDR     R0, =UART0_C2
            MOV     R1, #0
            STRB    R1, [R0]

; Set baud rate 9600 @ 48 MHz
            LDR     R0, =UART0_BDH
            MOV     R1, #0x01
            STRB    R1, [R0]
            LDR     R0, =UART0_BDL
            MOV     R1, #0x38
            STRB    R1, [R0]

; 8N1 (C1 = 0)
            LDR     R0, =UART0_C1
            MOV     R1, #0
            STRB    R1, [R0]

; Enable transmitter and receiver
            LDR     R0, =UART0_C2
            MOV     R1, #0x0C       ; TE=1, RE=1
            STRB    R1, [R0]

            POP     {R0-R3,PC}

;---------------------------------------------------------------
; GetChar: read character from UART0 into R0
;---------------------------------------------------------------
GetChar
            PUSH    {R1,R2,LR}
WaitRx
            LDR     R1, =UART0_S1
            LDRB    R2, [R1]
            MOVS    R1, #0x20       ; RDRF mask
            TST     R2, R1
            BEQ     WaitRx
            LDR     R1, =UART0_D
            LDRB    R0, [R1]
            POP     {R1,R2,PC}

;---------------------------------------------------------------
; PutChar: write character in R0 to UART0
;---------------------------------------------------------------
PutChar
            PUSH    {R1,R2,LR}
WaitTx
            LDR     R1, =UART0_S1
            LDRB    R2, [R1]
            MOVS    R1, #0x80       ; TDRE mask
            TST     R2, R1
            BEQ     WaitTx
            LDR     R1, =UART0_D
            STRB    R0, [R1]
            POP     {R1,R2,PC}
            ALIGN
            END
