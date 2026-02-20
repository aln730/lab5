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
; Initializes UART0 for polled serial I/O
; 9600 baud, 8N1, PTB1=TX, PTB2=RX
; Input : none
; Output: none
; Registers modified: LR, PC, PSR only
;---------------------------------------------------------------
Init_UART0_Polling  PROC
    PUSH {R0-R7}                 ; preserve all working regs

    ; Select MCGFLLCLK as UART0 clock source
    LDR  R0, =SIM_SOPT2
    LDR  R1, [R0]
    BIC  R1, R1, #SIM_SOPT2_UART0SRC_MASK
    ORR  R1, R1, #SIM_SOPT2_UART0SRC_MCGFLLCLK
    STR  R1, [R0]

    ; Set UART0 for external connection
    LDR  R0, =SIM_SOPT5
    LDR  R1, [R0]
    BIC  R1, R1, #SIM_SOPT5_UART0_EXTERN_MASK_CLEAR
    STR  R1, [R0]

    ; Enable UART0 clock
    LDR  R0, =SIM_SCGC4
    LDR  R1, [R0]
    ORR  R1, R1, #SIM_SCGC4_UART0_MASK
    STR  R1, [R0]

    ; Enable PORTB clock
    LDR  R0, =SIM_SCGC5
    LDR  R1, [R0]
    ORR  R1, R1, #SIM_SCGC5_PORTB_MASK
    STR  R1, [R0]

    ; PTB2 = UART0_RX
    LDR  R0, =PORTB_PCR2
    LDR  R1, =PORT_PCR_SET_PTB2_UART0_RX
    STR  R1, [R0]

    ; PTB1 = UART0_TX
    LDR  R0, =PORTB_PCR1
    LDR  R1, =PORT_PCR_SET_PTB1_UART0_TX
    STR  R1, [R0]

    ; Disable UART0
    LDR  R0, =UART0_BASE
    LDRB R1, [R0,#UART0_C2_OFFSET]
    BIC  R1, R1, #UART0_C2_T_R
    STRB R1, [R0,#UART0_C2_OFFSET]

    ; Configure 9600 baud, 8N1
    MOVS R1,#UART0_BDH_9600
    STRB R1,[R0,#UART0_BDH_OFFSET]

    MOVS R1,#UART0_BDL_9600
    STRB R1,[R0,#UART0_BDL_OFFSET]

    MOVS R1,#UART0_C1_8N1
    STRB R1,[R0,#UART0_C1_OFFSET]

    MOVS R1,#UART0_C3_NO_TXINV
    STRB R1,[R0,#UART0_C3_OFFSET]

    MOVS R1,#UART0_C4_NO_MATCH_OSR_16
    STRB R1,[R0,#UART0_C4_OFFSET]

    MOVS R1,#UART0_C5_NO_DMA_SSR_SYNC
    STRB R1,[R0,#UART0_C5_OFFSET]

    MOVS R1,#UART0_S1_CLEAR_FLAGS
    STRB R1,[R0,#UART0_S1_OFFSET]

    MOVS R1,#UART0_S2_NO_RXINV_BRK10_NO_LBKDETECT_CLEAR_FLAGS
    STRB R1,[R0,#UART0_S2_OFFSET]

    ; Enable UART0 RX + TX
    MOVS R1,#UART0_C2_T_R
    STRB R1,[R0,#UART0_C2_OFFSET]

    POP {R0-R7}
    BX  LR
    ENDP

;---------------------------------------------------------------
; PutChar
; Sends character in R0 via UART0 (polled)
; Input : R0 = character (ASCII)
; Output: none
; Registers modified: LR, PC, PSR only
;---------------------------------------------------------------
PutChar PROC
    PUSH {R1-R3}

    LDR  R1, =UART0_BASE
    MOVS R2, #UART0_S1_TDRE_MASK

Wait_Tx:
    LDRB R3, [R1,#UART0_S1_OFFSET]
    ANDS R3, R3, R2
    BEQ  Wait_Tx

    STRB R0, [R1,#UART0_D_OFFSET]

    POP {R1-R3}
    BX  LR
    ENDP

;---------------------------------------------------------------
; GetChar
; Receives character from UART0 (polled)
; Input : none
; Output: R0 = character (ASCII)
; Registers modified: R0, LR, PC, PSR
;---------------------------------------------------------------
GetChar PROC
    PUSH {R1-R3}

    LDR  R1, =UART0_BASE
    MOVS R2, #UART0_S1_RDRF_MASK

Wait_Rx:
    LDRB R3, [R1,#UART0_S1_OFFSET]
    ANDS R3, R3, R2
    BEQ  Wait_Rx

    LDRB R0, [R1,#UART0_D_OFFSET]

    POP {R1-R3}
    BX  LR
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
