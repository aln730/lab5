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
;--------------------------------------------------------------------				
			EXPORT  PutChar
			IMPORT  Negative 
			IMPORT  Overflow 
			IMPORT  PutPrompt 
			IMPORT  Zero
			IMPORT  Carry
Reset_Handler  PROC  {}
main
;---------------------------------------------------------------
;Mask interrupts
            CPSID   I
;KL05 system startup with 48-MHz system clock
            BL      Startup
;---------------------------------------------------------------
;>>>>> begin main program code <<<<<
;---------------------------------------------------------------
;Mask interrupts
            CPSID   I
;KL05 system startup
            BL      Startup

main_loop
;Initialize UART0
            BL      Init_UART0_Polling

menu_loop
;Display prompt
            BL      PutPrompt

;Read a character from terminal
            BL      GetChar       ; returns character in R0

;Check if lowercase and convert to uppercase
            MOV     R1, R0
            CMP     R0, #'a'
            BLT     skip_upper
            CMP     R0, #'z'
            BGT     skip_upper
            SUBS     R1, R1, #32  ; convert to uppercase

skip_upper
;Check if R1 = 'C','N','V','Z'
            CMP     R1, #'C'
            BEQ     do_C
            CMP     R1, #'N'
            BEQ     do_N
            CMP     R1, #'V'
            BEQ     do_V
            CMP     R1, #'Z'
            BEQ     do_Z
;If invalid command, loop back
            B       menu_loop

;---------------------------------------------------------------
do_C
;Echo original character
            MOV     R0, R0
            BL      PutChar
;Call Carry subroutine
            BL      Carry
            B       menu_loop

do_N
            MOV     R0, R0
            BL      PutChar
            BL      Negative
            B       menu_loop

do_V
            MOV     R0, R0
            BL      PutChar
            BL      Overflow
            B       menu_loop

do_Z
            MOV     R0, R0
            BL      PutChar
            BL      Zero
            B       menu_loop
;>>>>>   end main program code <<<<<
;Stay here
            B       .
            ENDP    ;main
;>>>>> begin subroutine code <<<<<
;>>>>> begin subroutine code <<<<<
;---------------------------------------------------------------
;UART0 Initialization Subroutine
;8N1 format, 9600 baud, uses port B pins 1 (TX) and 2 (RX)
Init_UART0_Polling  PROC
            PUSH    {R4-R5}          ; save temp registers

;Enable clock for UART0 and PortB
            LDR     R4, =SIM_SCGC4
            LDR     R5, [R4]
            MOVS    R2, #1           ; temporary small immediate
            LSLS    R2, R2, #10      ; 1 << 10 for UART0
            ORRS    R5, R5, R2
            STR     R5, [R4]

            LDR     R4, =SIM_SCGC5
            LDR     R5, [R4]
            MOVS    R2, #1
            LSLS    R2, R2, #10      ; 1 << 10 for PortB
            ORRS    R5, R5, R2
            STR     R5, [R4]

;Configure PTB1=TX, PTB2=RX for UART function (MUX=2)
            LDR     R4, =PORTB_PCR1
            MOVS    R5, #2
            LSLS    R5, R5, #8       ; 2 << 8
            STR     R5, [R4]

            LDR     R4, =PORTB_PCR2
            STR     R5, [R4]

;Set baud rate = 9600
;Assume 48MHz system clock, oversampling = 16
;UART0_BDH, UART0_BDL
            LDR     R4, =UART0_BDH
            MOVS    R5, #0            ; MSB of SBR
            STRB    R5, [R4]

            LDR     R4, =UART0_BDL
            MOVS    R5, #31           ; LSB of SBR ~ 312 / 0x138
            STRB    R5, [R4]

;Enable transmitter and receiver (RE | TE = 0x0C)
            LDR     R4, =UART0_C2
            MOVS    R5, #4            ; 1<<2 = RE
            MOVS    R2, #8            ; 1<<3 = TE
            ORRS    R5, R5, R2        ; combine RE|TE
            STRB    R5, [R4]

            POP     {R4-R5}
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
