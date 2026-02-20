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
        BL      PutPrompt
ReadChar
        BL      GetChar
        MOVS    R1, R0               ; save original char

        ; lowercase a-z check
        CMP     R0, #'a'
        BLT     CheckCmd
        CMP     R0, #'z'
        BGT     CheckCmd
        SUBS    R0, R0, #32          ; convert to uppercase

CheckCmd
        CMP     R0, #'C'
        BEQ     DoC
        CMP     R0, #'N'
        BEQ     DoN
        CMP     R0, #'V'
        BEQ     DoV
        CMP     R0, #'Z'
        BEQ     DoZ

        B       ReadChar

DoC
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


;>>>>>   end main program code <<<<<
;Stay here
            B       .
            ENDP    ;main
;>>>>> begin subroutine code <<<<<
;======================
; Initialize UART0 (Polling)
;======================
Init_UART0_Polling PROC
    PUSH {R1-R7, LR}

    ; Enable PORTB clock
    LDR  R1, =0x40048038       ; SIM_SCGC5
    LDR  R2, [R1]
    ORR  R2, R2, #1<<10
    STR  R2, [R1]

    ; Enable UART0 clock
    LDR  R1, =0x4004803C       ; SIM_SCGC4
    LDR  R2, [R1]
    ORR  R2, R2, #1<<10
    STR  R2, [R1]

    ; Configure UART0 transmit/receive source
    LDR  R1, =0x40048004       ; SIM_SOPT2
    LDR  R2, [R1]
    ; Clear bits 26-27
    MOVS R3, #3
    LSL  R3, R3, #26
    BIC  R2, R2, R3
    ; Set bit 26
    ORR  R2, R2, #1<<26
    STR  R2, [R1]

    ; Configure PORTB pins (PTB1=RX, PTB2=TX)
    LDR  R1, =0x4004A004       ; PORTB_PCR1
    MOVS R2, #2
    STR  R2, [R1]

    LDR  R1, =0x4004A008       ; PORTB_PCR2
    MOVS R2, #2
    STR  R2, [R1]

    ; UART0_C1 = 0 (default)
    LDR  R1, =0x4006A002       ; UART0_C1
    MOVS R2, #0
    STRB R2, [R1]

    ; Baud rate: 9600 (48MHz / 16 / 9600)
    LDR  R1, =0x4006A00A       ; UART0_BDH
    MOVS R2, #0
    STRB R2, [R1]

    LDR  R1, =0x4006A00B       ; UART0_BDL
    MOVS R2, #52               ; BD = 52
    STRB R2, [R1]

    ; UART0_C2: Enable RE and TE
    LDR  R1, =0x4006A002       ; UART0_C2
    MOVS R2, #0
    ORRS R2, R2, #1<<2         ; RE
    ORRS R2, R2, #1<<3         ; TE
    STRB R2, [R1]

    POP {R1-R7, PC}
ENDP

;======================
; Get a character from UART0
;======================
GetChar PROC
    PUSH {R1, LR}

GC_Wait
    LDR  R1, =0x4006A004       ; UART0_S1
    LDRB R2, [R1]
    ANDS R2, R2, #1<<5         ; Check RDRF
    BEQ  GC_Wait

    LDR  R1, =0x4006A007       ; UART0_D
    LDRB R0, [R1]

    POP {R1, PC}
ENDP

;======================
; Send a character via UART0
;======================
PutChar PROC
    PUSH {R1, LR}

PC_Wait
    LDR  R1, =0x4006A004       ; UART0_S1
    LDRB R2, [R1]
    ANDS R2, R2, #1<<7         ; Check TDRE
    BEQ  PC_Wait

    LDR  R1, =0x4006A007       ; UART0_D
    STRB R0, [R1]

    POP {R1, PC}
ENDP
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
