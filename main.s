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
            BL      Init_UART0_Polling   ; Initialize UART0

MainLoop
            BL      PutPrompt            ; Display prompt
            BL      GetChar              ; Read char into R0

            MOV     R4, R0               ; Save original char
            MOV     R1, R0
            CMP     R1, #'a'
            BLT     SkipUpperConvert
            CMP     R1, #'z'
            BGT     SkipUpperConvert
            SUB     R1, R1, #32         ; Convert to uppercase
SkipUpperConvert

            CMP     R1, #'C'
            BEQ     CallCarry
            CMP     R1, #'N'
            BEQ     CallNegative
            CMP     R1, #'V'
            BEQ     CallOverflow
            CMP     R1, #'Z'
            BEQ     CallZero
            B       MainLoop             ; Not valid, repeat

CallCarry
            MOV     R0, R4               ; Restore original char
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
;>>>>>   end main program code <<<<<
;Stay here
            B       .
            ENDP    ;main
;>>>>> begin subroutine code <<<<<
Init_UART0_Polling PROC
            LDR     R0, =SIM_SCGC4
            LDR     R1, [R0]
            ORR     R1, R1, #0x400         ; Enable UART0 clock (1<<10)
            STR     R1, [R0]

            LDR     R0, =SIM_SCGC5
            LDR     R1, [R0]
            ORR     R1, R1, #0x400         ; Enable PORTB clock (1<<10)
            STR     R1, [R0]

            ; Configure PORTB pins 1 (TX) and 2 (RX)
            LDR     R0, =PORTB_PCR1
            MOV     R1, #0x20              ; MUX=2 for UART0_TX
            STR     R1, [R0]
            LDR     R0, =PORTB_PCR2
            MOV     R1, #0x20              ; MUX=2 for UART0_RX
            STR     R1, [R0]

            ; UART0 baud 9600 @48MHz
            LDR     R0, =UART0_BDH
            MOV     R1, #0
            STR     R1, [R0]
            LDR     R0, =UART0_BDL
            MOV     R1, #52                 ; BDL = 48MHz/(16*9600)
            STR     R1, [R0]

            ; Enable transmitter and receiver
            LDR     R0, =UART0_C2
            MOV     R1, #0xC                ; RE=1, TE=1 -> 0b1100
            STR     R1, [R0]

            BX      LR
            ENDP

;----------------------------------------
;GetChar: Reads one character from UART0
; Input: none
; Output: R0 = received char
; Clobbers: R0, R1, R2
;----------------------------------------
GetChar  PROC
PollRX
            LDR     R1, =UART0_S1
            LDR     R2, [R1]
            ANDS    R2, R2, #0x20          ; Check RDRF (bit 5)
            BEQ     PollRX
            LDR     R0, =UART0_D
            LDRB    R0, [R0]
            BX      LR
            ENDP

;----------------------------------------
;PutChar: Sends one character to UART0
; Input: R0 = char to send
; Output: none
; Clobbers: R1, R2
;----------------------------------------
PutChar  PROC
PollTX
            LDR     R1, =UART0_S1
            LDR     R2, [R1]
            ANDS    R2, R2, #0x80          ; Check TDRE (bit 7)
            BEQ     PollTX
            LDR     R1, =UART0_D
            STRB    R0, [R1]
            BX      LR
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
