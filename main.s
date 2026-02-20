            TTL Program Title for Listing Header Goes Here
;****************************************************************
;Descriptive comment header goes here.
; Implements a polled UART0 menu to display APSR flags C, N, V, Z
;Name:  Arnav Gawas
;Date:  <Date completed here>
;Class:  CMPE-250
;Section:  <Your lab section, day, and time here>
;---------------------------------------------------------------
;Keil Template for KL05
;R. W. Melton
;September 13, 2020
;****************************************************************
;Assembler directives
            THUMB
            OPT    64              ; Turn on listing macro expansions
;****************************************************************
;Include files
            GET    MKL05Z4.s       ; Included by start.s
            OPT    1               ; Turn on listing
;****************************************************************
;EQUates
;****************************************************************
;Program
;Linker requires Reset_Handler
            AREA    MyCode,CODE,READONLY
            ENTRY
            EXPORT  Reset_Handler
            IMPORT  Startup
            EXPORT  PutChar
            IMPORT  Carry
            IMPORT  Negative
            IMPORT  Overflow
            IMPORT  PutPrompt
            IMPORT  Zero
            IMPORT  GetChar

;---------------------------------------------------------------
Reset_Handler  PROC
;---------------------------------------------------------------
; Mask interrupts
            CPSID   I
; KL05 system startup with 48-MHz system clock
            BL      Startup

; Initialize UART0 for polled I/O
            BL      Init_UART0_Polling

MainLoop
; Display prompt
            BL      PutPrompt

; Read one character from terminal
            BL      GetChar
            MOV     R4, R0        ; Save original char in R4
            MOV     R1, R0        ; Copy for uppercase conversion

; Convert lowercase to uppercase if needed
            CMP     R1, #'a'
            BLT     SkipUpperConvert
            CMP     R1, #'z'
            BGT     SkipUpperConvert
            SUB     R1, R1, #32  ; Convert to uppercase
SkipUpperConvert

; Check command characters
            CMP     R1, #'C'
            BEQ     CallCarry
            CMP     R1, #'N'
            BEQ     CallNegative
            CMP     R1, #'V'
            BEQ     CallOverflow
            CMP     R1, #'Z'
            BEQ     CallZero

; Invalid character, loop back
            B       MainLoop

;---------------------------------------
CallCarry
            MOV     R0, R4
            BL      PutChar
            BL      Carry
            B       MainLoop

CallNegative
            MOV     R0, R4
            BL      PutChar
            BL      Negative
            B       MainLoop

CallOverflow
            MOV     R0, R4
            BL      PutChar
            BL      Overflow
            B       MainLoop

CallZero
            MOV     R0, R4
            BL      PutChar
            BL      Zero
            B       MainLoop

; Stay here (should never exit)
            B       .
            ENDP

;----------------------------------------
; Init_UART0_Polling
;---------------------------------------------------------------
Init_UART0_Polling PROC
; Description: Initialize UART0 for polled I/O (8N1, 9600 baud)
; Input: none
; Output: none
; Registers modified: R0, R1
            LDR     R0, =SIM_SCGC4
            LDR     R1, [R0]
            ORR     R1, R1, #(1 << 10) ; Enable UART0 clock
            STR     R1, [R0]

            LDR     R0, =SIM_SCGC5
            LDR     R1, [R0]
            ORR     R1, R1, #(1 << 10) ; Enable PORTB clock
            STR     R1, [R0]

; Configure PORTB pins 1 (TX) and 2 (RX)
            LDR     R0, =PORTB_PCR1
            LDR     R1, =0x020          ; MUX=2: UART0_TX
            STR     R1, [R0]
            LDR     R0, =PORTB_PCR2
            LDR     R1, =0x020          ; MUX=2: UART0_RX
            STR     R1, [R0]

; UART0 baud 9600 @48MHz
            LDR     R0, =UART0_BDH
            MOV     R1, #0
            STR     R1, [R0]
            LDR     R0, =UART0_BDL
            MOV     R1, #52             ; BDL = 48MHz/(16*9600) ≈ 3125 → 52
            STR     R1, [R0]

; Enable transmitter and receiver
            LDR     R0, =UART0_C2
            MOV     R1, #(1<<2 | 1<<3)  ; RE=1, TE=1
            STR     R1, [R0]

            BX      LR
            ENDP

;----------------------------------------
; GetChar
;---------------------------------------------------------------
GetChar PROC
; Description: Poll UART0 and read a character
; Input: none
; Output: R0 = received character
; Registers modified: R0, R1, R2
PollRX
            LDR     R1, =UART0_S1
            LDR     R2, [R1]
            ANDS    R2, R2, #(1<<5)     ; Check RDRF
            BEQ     PollRX
            LDR     R0, =UART0_D
            LDRB    R0, [R0]
            BX      LR
            ENDP

;----------------------------------------
; PutChar
;---------------------------------------------------------------
PutChar PROC
; Description: Poll UART0 and send a character
; Input: R0 = character to send
; Output: none
; Registers modified: R1, R2
PollTX
            LDR     R1, =UART0_S1
            LDR     R2, [R1]
            ANDS    R2, R2, #(1<<7)     ; Check TDRE
            BEQ     PollTX
            LDR     R1, =UART0_D
            STRB    R0, [R1]
            BX      LR
            ENDP

            ALIGN
; Vector Table
            AREA    RESET, DATA, READONLY
            EXPORT  __Vectors
            EXPORT  __Vectors_End
            EXPORT  __Vectors_Size
            IMPORT  __initial_sp
            IMPORT  Dummy_Handler
            IMPORT  HardFault_Handler
__Vectors
            DCD    __initial_sp
            DCD    Reset_Handler
            DCD    Dummy_Handler
            DCD    HardFault_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
            DCD    Dummy_Handler
__Vectors_End
__Vectors_Size  EQU __Vectors_End - __Vectors
            ALIGN
            END
