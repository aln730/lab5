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

GetInput
            BL      GetChar          ; R0 = typed character
            MOV     R1, R0           ; save original character

; check if lowercase (a–z)
            CMP     R0, #'a'
            BLT     CheckUpper
            CMP     R0, #'z'
            BGT     CheckUpper
            SUB     R0, R0, #32      ; convert to uppercase

CheckUpper
            CMP     R0, #'C'
            BEQ     CmdC
            CMP     R0, #'N'
            BEQ     CmdN
            CMP     R0, #'V'
            BEQ     CmdV
            CMP     R0, #'Z'
            BEQ     CmdZ

            B       GetInput         ; invalid → try again

CmdC
            MOV     R0, R1
            BL      PutChar
            BL      Carry
            B       MainLoop

CmdN
            MOV     R0, R1
            BL      PutChar
            BL      Negative
            B       MainLoop

CmdV
            MOV     R0, R1
            BL      PutChar
            BL      Overflow
            B       MainLoop

CmdZ
            MOV     R0, R1
            BL      PutChar
            BL      Zero
            B       MainLoop

;>>>>>   end main program code <<<<<
;Stay here
            B       .
            ENDP    ;main

;>>>>> begin subroutine code <<<<<

;---------------------------------------------------------------
; Init_UART0_Polling
;---------------------------------------------------------------
Init_UART0_Polling
            PUSH    {R0-R3,LR}

; Enable clocks for UART0 and PORTB
            LDR     R0, =SIM_SCGC4
            LDR     R1, [R0]
            ORR     R1, R1, #SIM_SCGC4_UART0_MASK
            STR     R1, [R0]

            LDR     R0, =SIM_SCGC5
            LDR     R1, [R0]
            ORR     R1, R1, #SIM_SCGC5_PORTB_MASK
            STR     R1, [R0]

; Select MCGFLLCLK for UART0
            LDR     R0, =SIM_SOPT2
            LDR     R1, [R0]
            BIC     R1, R1, #SIM_SOPT2_UART0SRC_MASK
            ORR     R1, R1, #(1 << SIM_SOPT2_UART0SRC_SHIFT)
            STR     R1, [R0]

; Set PORTB pins 1 and 2 to UART function (ALT2)
            LDR     R0, =PORTB_PCR1
            MOVS    R1, #(2 << PORT_PCR_MUX_SHIFT)
            STR     R1, [R0]

            LDR     R0, =PORTB_PCR2
            MOVS    R1, #(2 << PORT_PCR_MUX_SHIFT)
            STR     R1, [R0]

; Disable UART0 before config
            LDR     R0, =UART0_C2
            MOVS    R1, #0
            STRB    R1, [R0]

; Set baud rate = 9600 (SBR = 0x0138)
            LDR     R0, =UART0_BDH
            MOVS    R1, #0x01
            STRB    R1, [R0]

            LDR     R0, =UART0_BDL
            MOVS    R1, #0x38
            STRB    R1, [R0]

; 8N1 configuration
            LDR     R0, =UART0_C1
            MOVS    R1, #0
            STRB    R1, [R0]

; Enable transmitter and receiver
            LDR     R0, =UART0_C2
            MOVS    R1, #(UART0_C2_TE_MASK | UART0_C2_RE_MASK)
            STRB    R1, [R0]

            POP     {R0-R3,PC}

;---------------------------------------------------------------
; GetChar  → R0 = received character
;---------------------------------------------------------------
GetChar
            PUSH    {R1,LR}

WaitRx
            LDR     R1, =UART0_S1
            LDRB    R2, [R1]
            TST     R2, #UART0_S1_RDRF_MASK
            BEQ     WaitRx

            LDR     R1, =UART0_D
            LDRB    R0, [R1]

            POP     {R1,PC}

;---------------------------------------------------------------
; PutChar  (R0 = character to send)
;---------------------------------------------------------------
PutChar
            PUSH    {R1-R2,LR}

WaitTx
            LDR     R1, =UART0_S1
            LDRB    R2, [R1]
            TST     R2, #UART0_S1_TDRE_MASK
            BEQ     WaitTx

            LDR     R1, =UART0_D
            STRB    R0, [R1]

            POP     {R1-R2,PC}

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
