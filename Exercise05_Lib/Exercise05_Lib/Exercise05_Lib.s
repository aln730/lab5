            TTL Lab Exercise Five Library
;****************************************************************
;Provides subroutines for Lab Exercise Five.
;* PutPrompt
;* Carry
;* Negative
;* Overflow
;* Zero
;Name:  R. W. Melton
;Date:  February 10, 2025
;Class:  CMPE-250
;Section:  All sections
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
;Characters
CR                EQU  0x0D
LF                EQU  0x0A
NULL              EQU  0x00
;****************************************************************
;Exercise05_Lib Subroutines
;Requires PutChar subroutine
            AREA    Exercise05_Lib,CODE,READONLY
            EXPORT  Carry
            EXPORT  Negative
            EXPORT  Overflow
            EXPORT  PutPrompt
            EXPORT  Zero
            IMPORT  PutChar
;---------------------------------------------------------------
Carry       PROC   {R0-R13}
;**********************************************************************
;Prints glossary entry for C (carry) on a separate line
;Input:     none
;Output:    none
;Calls:     PutString
;Uses:      c_String
;Modifies:  PSR
;**********************************************************************
            PUSH   {R0,LR}           ;save registers modified
            ADR    R0,c_string       ;&c_string
            BL     PutString
            POP    {R0,PC}           ;restore registers and return
            ENDP   ;Carry
;---------------------------------------------------------------
Negative    PROC   {R0-R13}
;**********************************************************************
;Prints glossary entry for N (negative) on a separate line
;Input:     none
;Output:    none
;Calls:     PutString
;Uses:      n_String
;Modifies:  PSR
;**********************************************************************
            PUSH   {R0,LR}           ;save registers modified
            ADR    R0,n_string       ;&n_string
            BL     PutString
            POP    {R0,PC}           ;restore registers and return
            ENDP   ;Negative
;---------------------------------------------------------------
Overflow    PROC   {R0-R13}
;**********************************************************************
;Prints glossary entry for V (overflow) on a separate line
;Input:     none
;Output:    none
;Calls:     PutString
;Uses:      v_String
;Modifies:  PSR
;**********************************************************************
            PUSH   {R0,LR}           ;save registers modified
            ADR    R0,v_string       ;&v_string
            BL     PutString
            POP    {R0,PC}           ;restore registers and return
            ENDP   ;Overflow
;---------------------------------------------------------------
PutPrompt   PROC   {R0-R13}
;**********************************************************************
;Puts prompt on terminal
;Input:     none
;Output:    none
;Calls:     PutString
;Uses:      prompt
;Modifies:  PSR
;**********************************************************************
;Save registers
            PUSH   {R0,LR}    
            ADR    R0,prompt      ;Put prompt
            BL     PutString
            POP    {R0,PC}
            ENDP   ;PutPrompt
;---------------------------------------------------------------
PutString   PROC   {R0-R13}
;**********************************************************************
;Transmits each character in null-terminated string to UART0.
;Input:     R0: Address of string to transmit
;Output:    none
;Calls:     PutChar
;Modifies:  PSR
;**********************************************************************
;Save registers
            PUSH   {R0-R2,LR}    
            LDR    R2,ptr_PutChar ;Needed to call PutChar in loop
            MOV    R1,R0          ;R0 needed for parameter
PutStringLoop                     ;repeat {
            LDRB   R0,[R1,#0]     ;  CurrentChar of string
            CMP    R0,#NULL       ;  if (CurrentChar != NULL) {
            BEQ    PutStringDone
            PUSH   {R0-R3}        ;    /* Support C PutChar () */
            BLX    R2             ;    Send current char to terminal
            POP    {R0-R3}        ;    /* Support C PutChar () */
            ADDS   R1,R1,#1       ;    CurrentCharPtr++
            B      PutStringLoop  ;} until (CurrentChar == NULL)
;Restore registers
PutStringDone
            POP    {R0-R2,PC}
            ENDP   ;PutString
;---------------------------------------------------------------
Zero        PROC   {R0-R13}
;**********************************************************************
;Prints glossary entry for Z (zero) on a separate line
;Input:     none
;Output:    none
;Calls:     PutString
;Uses:      z_string
;Modifies:  PSR
;**********************************************************************
            PUSH   {R0,LR}           ;save registers modified
            ADR    R0,z_string       ;&z_string
            BL     PutString
            POP    {R0,PC}           ;restore registers and return
            ENDP   ;Zero
;---------------------------------------------------------------
;****************************************************************
            ALIGN
ptr_PutChar DCD     PutChar
            ALIGN
prompt      DCB     "Type a letter for APSR glossary lookup."
            DCB     CR,LF,'>',NULL
            ALIGN
c_string    DCB     CR,LF
            DCB     "Carry:  set if there was a carry out of "
            DCB     "(or no borrow into) the msb."
            DCB     CR,LF,NULL
            ALIGN
n_string    DCB     CR,LF
            DCB     "Negative:  set if result is negative for "
            DCB     "signed number; N = msb."
            DCB     CR,LF,NULL
            ALIGN
v_string    DCB     CR,LF
            DCB     "Overflow:  set if result is invalid for "
            DCB     "signed number."
            DCB     CR,LF,NULL
            ALIGN
z_string    DCB     CR,LF
            DCB     "Zero:  set if result is zero."
            DCB     CR,LF,NULL
            ALIGN
            END
            