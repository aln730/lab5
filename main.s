            TTL Polled Serial I/O Lab 5
;****************************************************************
;Descriptive comment header goes here.
;(Program reads a character from UART, normalizes to uppercase, 
; and triggers the appropriate flag subroutine: C, N, V, or Z)
;Name:  Arnav Gawas
;Date:  02-19-2026
;Class:  CMPE-250
;Section: 01-2:00PM
;---------------------------------------------------------------
;Keil Simulator Template for KL05
;R. W. Melton
;August 21, 2025
;****************************************************************
;Assembler directives
            THUMB
            OPT    64  ;Turn on listing macro expansions
;****************************************************************
;EQUates
BYTE_MASK         EQU  0xFF
NIBBLE_MASK       EQU  0x0F
BYTE_BITS         EQU  8
NIBBLE_BITS       EQU  4
WORD_SIZE         EQU  4
HALFWORD_SIZE     EQU  2
HALFWORD_MASK     EQU  0xFFFF
RET_ADDR_T_MASK   EQU  1
VECTOR_TABLE_SIZE EQU 0x000000C0
VECTOR_SIZE       EQU 4
;****************************************************************
;Program
            AREA    MyCode,CODE,READONLY
            ENTRY
            EXPORT  Reset_Handler
            IMPORT  Init_UART0_Polling
            IMPORT  GetChar
            IMPORT  PutChar
            IMPORT  PutPrompt
            IMPORT  Carry
            IMPORT  Negative
            IMPORT  Overflow
            IMPORT  Zero
;---------------------------------------------------------------
Reset_Handler  PROC
    CPSID   I               ; mask interrupts
    BL      Startup         ; KL05 system startup
    BL      Init_UART0_Polling  ; initialize UART0

MainLoop
    BL      PutPrompt

ReadChar
    BL      GetChar         ; R0 = input char
    MOV     R1, R0          ; save original char

    ; lowercase → uppercase normalization
    CMP     R0, #'a'
    BLT     CheckCmd
    CMP     R0, #'z'
    BGT     CheckCmd
    SUB     R0, R0, #32     ; convert to uppercase

CheckCmd
    CMP     R0, #'C'
    BEQ     DoC
    CMP     R0, #'N'
    BEQ     DoN
    CMP     R0, #'V'
    BEQ     DoV
    CMP     R0, #'Z'
    BEQ     DoZ

    B       ReadChar        ; invalid input

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

    B       .               ; stay here
    ENDP
;---------------------------------------------------------------
RegInit     PROC
;********************************************************************
;Initialize registers and APSR.NZCV (optional startup routine)
;********************************************************************
    PUSH    {LR}
    LDR     R1,=0x11111111
    ADDS    R2,R1,R1
    ADDS    R3,R2,R1
    ADDS    R4,R3,R1
    ADDS    R5,R4,R1
    ADDS    R6,R5,R1
    ADDS    R7,R6,R1
    MOV     R8,R1
    ADD     R8,R8,R7
    MOV     R9,R1
    ADD     R9,R9,R8
    MOV     R10,R1
    ADD     R10,R10,R9
    MOV     R11,R1
    ADD     R11,R11,R10
    MOV     R12,R1
    ADD     R12,R12,R11
    MOV     R14,R2
    ADD     R14,R14,R12
    MOV     R0,R1
    ADD     R0,R0,R14
    MSR     APSR,R0
    LDR     R0,=0x05250821
    POP     {PC}
    ENDP
;---------------------------------------------------------------
;Constants
            AREA    MyConst,DATA,READONLY
PromptStr   DCB 13,10,"Enter flag (C/N/V/Z): ",0
CarryStr    DCB 13,10,"C - Carry flag selected",13,10,0
NegStr      DCB 13,10,"N - Negative flag selected",13,10,0
OvfStr      DCB 13,10,"V - Overflow flag selected",13,10,0
ZeroStr     DCB 13,10,"Z - Zero flag selected",13,10,0
            ALIGN
;---------------------------------------------------------------
;Vector Table Mapped to Address 0 at Reset
            AREA    RESET, DATA,READONLY
            EXPORT  __Vectors
            EXPORT  __Vectors_End
            EXPORT  __Vectors_Size
            IMPORT  __initial_sp
__Vectors 
            DCD    __initial_sp       ; 0x00: end of stack
            DCD    Reset_Handler      ; 0x04: reset vector
            SPACE  (VECTOR_TABLE_SIZE - (2 * VECTOR_SIZE)) ; fill remaining vectors
__Vectors_End
__Vectors_Size  EQU     __Vectors_End - __Vectors
            ALIGN
;---------------------------------------------------------------
;Stack Setup
            AREA    |.ARM.__at_0x1FFFFC00|,DATA,READWRITE,ALIGN=3
            EXPORT  __initial_sp
SSTACK_SIZE EQU 0x100
Stack_Mem   SPACE   SSTACK_SIZE
__initial_sp
;---------------------------------------------------------------
;Variables
            AREA    MyData,DATA,READWRITE
; You can define user variables here if needed
            ALIGN
            END
