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
;---------------------------------------------------------------
; Init_UART0_Polling
; UART0 init for KL05Z
; 9600 baud, 8N1, PTB1=TX, PTB2=RX
; Input : none
; Output: none
; Registers modified: LR, PC, PSR only
;---------------------------------------------------------------
Init_UART0_Polling  PROC
    PUSH {R1-R5}

    ; Enable UART0 clock (SIM_SCGC4 bit 10)
    LDR     R4, =SIM_SCGC4
    LDR     R5, [R4]
    MOVS    R1, #1
    LSLS    R1, R1, #10
    ORRS    R5, R5, R1
    STR     R5, [R4]

    ; Enable PORTB clock (SIM_SCGC5 bit 10)
    LDR     R4, =SIM_SCGC5
    LDR     R5, [R4]
    MOVS    R1, #1
    LSLS    R1, R1, #10
    ORRS    R5, R5, R1
    STR     R5, [R4]

    ; PTB1 = UART0_TX (MUX = 2)
    LDR     R4, =PORTB_PCR1
    MOVS    R5, #2
    LSLS    R5, R5, #8
    STR     R5, [R4]

    ; PTB2 = UART0_RX (MUX = 2)
    LDR     R4, =PORTB_PCR2
    STR     R5, [R4]

    ; Baud rate 9600 (48MHz, OSR=16, SBR≈312)
    LDR     R4, =UART0_BDH
    MOVS    R5, #0
    STRB    R5, [R4]

    LDR     R4, =UART0_BDL
    MOVS    R5, #31          ; ≈ 312
    STRB    R5, [R4]

    ; 8N1 default in C1 = 0
    LDR     R4, =UART0_C1
    MOVS    R5, #0
    STRB    R5, [R4]

    ; Enable RX + TX
    LDR     R4, =UART0_C2
    MOVS    R5, #4           ; RE
    MOVS    R1, #8           ; TE
    ORRS    R5, R5, R1
    STRB    R5, [R4]

    POP {R1-R5}
    BX  LR
    ENDP

;---------------------------------------------------------------
; PutChar
; Input : R0 = ASCII char
; Output: none
; Registers modified: LR, PC, PSR only
;---------------------------------------------------------------
PutChar         PROC
                PUSH {R1-R3, LR}

                LDR  R1, =UART0_BASE

PollTx          
                LDRB R3, [R1, #UART0_S1_OFFSET]     ; read status
                MOVS R2, #UART0_S1_TDRE_MASK        ; mask
                ANDS R3, R3, R2
                BEQ  PollTx                         ; wait until TDRE=1

                STRB R0, [R1, #UART0_D_OFFSET]      ; write data

                POP  {R1-R3, PC}
                ENDP

;---------------------------------------------------------------
; GetChar
; Input : none
; Output: R0 = ASCII char
; Registers modified: R0, LR, PC, PSR
;---------------------------------------------------------------
GetChar         PROC
                PUSH {R1-R3, LR}

                LDR  R1, =UART0_BASE

PollRx          
                LDRB R3, [R1, #UART0_S1_OFFSET]     ; read status
                MOVS R2, #UART0_S1_RDRF_MASK        ; mask
                ANDS R3, R3, R2
                BEQ  PollRx                         ; wait until RDRF=1

                LDRB R0, [R1, #UART0_D_OFFSET]      ; read data into R0

                POP  {R1-R3, PC}
                ENDP
	
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
