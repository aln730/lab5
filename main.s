            TTL Program Title for Listing Header Goes Here
;****************************************************************
;Descriptive comment header goes here.
;(What does the program do?)
;Name:  <Your name here>
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
            OPT    64  ;Turn on listing macro expansions
;****************************************************************
;Include files
            GET  MKL05Z4.s     ;Included by start.s
            OPT  1   ;Turn on listing
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


Reset_Handler  PROC  {}
main
;---------------------------------------------------------------
;Mask interrupts
            CPSID   I
;KL05 system startup with 48-MHz system clock
            BL      Startup
;---------------------------------------------------------------
;>>>>> begin main program code <<<<<
        BL      Init_UART0_Polling

MainLoop
        ; Print prompt
        BL      PutPrompt

ReadChar
        ; Read a character from UART0
        BL      GetChar
        MOVS    R1, R0               ; Save original char for echoing

        ; Convert lowercase 'a'-'z' to uppercase
        CMP     R0, #'a'
        BLT     CheckCmd
        CMP     R0, #'z'
        BGT     CheckCmd
        SUBS    R0, R0, #32          ; Convert to uppercase

CheckCmd
        ; Compare to commands: C, N, V, Z
        CMP     R0, #'C'
        BEQ     DoC
        CMP     R0, #'N'
        BEQ     DoN
        CMP     R0, #'V'
        BEQ     DoV
        CMP     R0, #'Z'
        BEQ     DoZ

        ; Not a valid command, read another char
        B       ReadChar

DoC
        ; Echo character, call Carry subroutine
        MOVS    R0, R1
        BL      PutChar
        BL      Carry
        B       MainLoop

DoN
        MOVS    R0, R1
        BL      PutChar
        BL      Negative
        B       MainLoop

DoV
        MOVS    R0, R1
        BL      PutChar
        BL      Overflow
        B       MainLoop

DoZ
        MOVS    R0, R1
        BL      PutChar
        BL      Zero
        B       MainLoop

        ; Infinite loop to stay here if needed
        B       .

        ENDP
;>>>>> begin subroutine code <<<<<
;;>>>>> begin subroutine code <<<<<

;---------------------------------------
; Init_UART0_Polling
; Initializes UART0 for 9600 baud, 8N1, polling mode
;---------------------------------------
Init_UART0_Polling
        PUSH    {R1-R3, LR}

        ; Enable PORTB clock (SIM_SCGC5)
        LDR     R0, =0x40048038       ; SIM_SCGC5
        LDR     R1, [R0]
        MOVS    R2, #1
        LSL     R2, #10               ; PORTB
        ORR     R1, R1, R2
        STR     R1, [R0]

        ; Enable UART0 clock (SIM_SCGC4)
        LDR     R0, =0x4004803C       ; SIM_SCGC4
        LDR     R1, [R0]
        MOVS    R2, #1
        LSL     R2, #10               ; UART0
        ORR     R1, R1, R2
        STR     R1, [R0]

        ; Configure PORTB pins for UART0
        LDR     R0, =0x4004A008       ; PORTB_PCR2 (RX)
        MOVS    R1, #0x102
        STR     R1, [R0]

        LDR     R0, =0x4004A004       ; PORTB_PCR1 (TX)
        MOVS    R1, #0x102
        STR     R1, [R0]

        ; UART0 base
        LDR     R0, =0x4006A000

        ; Disable UART0 transmitter and receiver
        LDRB    R1, [R0,#0x03]        ; C2
        MOVS    R2, #0x0C              ; TE|RE
        BIC     R1, R1, R2
        STRB    R1, [R0,#0x03]

        ; Set baud rate for 9600 (BDH = 0x01, BDL = 0x38)
        MOVS    R1, #0x01
        STRB    R1, [R0,#0x00]        ; BDH
        MOVS    R1, #0x38
        STRB    R1, [R0,#0x01]        ; BDL

        ; 8N1 (default)
        MOVS    R1, #0x00
        STRB    R1, [R0,#0x02]        ; C1
        STRB    R1, [R0,#0x06]        ; C3
        MOVS    R1, #0x0F
        STRB    R1, [R0,#0x0A]        ; C4
        STRB    R1, [R0,#0x0B]        ; C5

        ; Clear status flags
        MOVS    R1, #0x1F
        STRB    R1, [R0,#0x04]        ; S1
        MOVS    R1, #0xC0
        STRB    R1, [R0,#0x05]        ; S2

        ; Enable UART0 transmitter and receiver
        MOVS    R1, #0x0C
        STRB    R1, [R0,#0x03]        ; C2

        POP     {R1-R3, PC}

;---------------------------------------
; PutChar
; Sends a single character via UART0 (polling)
; Input: R0 = character to send
;---------------------------------------
PutChar
        PUSH    {R1, LR}

WAIT_TX:
        LDR     R1, =0x4006A004       ; UART0_S1
        LDRB    R2, [R1]
        MOVS    R3, #0x80              ; TDRE
        ANDS    R2, R2, R3
        BEQ     WAIT_TX

        LDR     R1, =0x4006A007       ; UART0_D
        STRB    R0, [R1]

        POP     {R1, PC}

;---------------------------------------
; GetChar
; Receives a single character via UART0 (polling)
; Output: R0 = received character
;---------------------------------------
GetChar
        PUSH    {R1, LR}

WAIT_RX:
        LDR     R1, =0x4006A004       ; UART0_S1
        LDRB    R2, [R1]
        MOVS    R3, #0x20              ; RDRF
        ANDS    R2, R2, R3
        BEQ     WAIT_RX

        LDR     R1, =0x4006A007       ; UART0_D
        LDRB    R0, [R1]

        POP     {R1, PC}

;>>>>>   end subroutine code <<<<<
;>>>>>   end subroutine code <<<<<
            ALIGN
;****************************************************************
;Vector Table Mapped to Address 0 at Reset
;Linker requires __Vectors to be exported
            AREA    RESET, DATA, READONLY
            EXPORT  __Vectors
            EXPORT  __Vectors_End
            EXPORT  __Vectors_Size
            IMPORT  __initial_sp
            IMPORT  Dummy_Handler
            IMPORT  HardFault_Handler
__Vectors 
                                      ;ARM core vectors
            DCD    __initial_sp       ;00:end of stack
            DCD    Reset_Handler      ;01:reset vector
            DCD    Dummy_Handler      ;02:NMI
            DCD    HardFault_Handler  ;03:hard fault
            DCD    Dummy_Handler      ;04:(reserved)
            DCD    Dummy_Handler      ;05:(reserved)
            DCD    Dummy_Handler      ;06:(reserved)
            DCD    Dummy_Handler      ;07:(reserved)
            DCD    Dummy_Handler      ;08:(reserved)
            DCD    Dummy_Handler      ;09:(reserved)
            DCD    Dummy_Handler      ;10:(reserved)
            DCD    Dummy_Handler      ;11:SVCall (supervisor call)
            DCD    Dummy_Handler      ;12:(reserved)
            DCD    Dummy_Handler      ;13:(reserved)
            DCD    Dummy_Handler      ;14:PendSV (PendableSrvReq)
                                      ;   pendable request 
                                      ;   for system service)
            DCD    Dummy_Handler      ;15:SysTick (system tick timer)
            DCD    Dummy_Handler      ;16:DMA channel 0 transfer 
                                      ;   complete/error
            DCD    Dummy_Handler      ;17:DMA channel 1 transfer
                                      ;   complete/error
            DCD    Dummy_Handler      ;18:DMA channel 2 transfer
                                      ;   complete/error
            DCD    Dummy_Handler      ;19:DMA channel 3 transfer
                                      ;   complete/error
            DCD    Dummy_Handler      ;20:(reserved)
            DCD    Dummy_Handler      ;21:FTFA command complete/
                                      ;   read collision
            DCD    Dummy_Handler      ;22:low-voltage detect;
                                      ;   low-voltage warning
            DCD    Dummy_Handler      ;23:low leakage wakeup
            DCD    Dummy_Handler      ;24:I2C0
            DCD    Dummy_Handler      ;25:(reserved)
            DCD    Dummy_Handler      ;26:SPI0
            DCD    Dummy_Handler      ;27:(reserved)
            DCD    Dummy_Handler      ;28:UART0 (status; error)
            DCD    Dummy_Handler      ;29:(reserved)
            DCD    Dummy_Handler      ;30:(reserved)
            DCD    Dummy_Handler      ;31:ADC0
            DCD    Dummy_Handler      ;32:CMP0
            DCD    Dummy_Handler      ;33:TPM0
            DCD    Dummy_Handler      ;34:TPM1
            DCD    Dummy_Handler      ;35:(reserved)
            DCD    Dummy_Handler      ;36:RTC (alarm)
            DCD    Dummy_Handler      ;37:RTC (seconds)
            DCD    Dummy_Handler      ;38:PIT
            DCD    Dummy_Handler      ;39:(reserved)
            DCD    Dummy_Handler      ;40:(reserved)
            DCD    Dummy_Handler      ;41:DAC0
            DCD    Dummy_Handler      ;42:TSI0
            DCD    Dummy_Handler      ;43:MCG
            DCD    Dummy_Handler      ;44:LPTMR0
            DCD    Dummy_Handler      ;45:(reserved)
            DCD    Dummy_Handler      ;46:PORTA
            DCD    Dummy_Handler      ;47:PORTB
__Vectors_End
__Vectors_Size  EQU     __Vectors_End - __Vectors
            ALIGN
;****************************************************************
;Constants
            AREA    MyConst,DATA,READONLY
;>>>>> begin constants here <<<<<
;>>>>>   end constants here <<<<<
            ALIGN
;****************************************************************
;Variables
            AREA    MyData,DATA,READWRITE
;>>>>> begin variables here <<<<<
;>>>>>   end variables here <<<<<
            ALIGN
            END
