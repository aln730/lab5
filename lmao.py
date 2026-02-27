from machine import UART
import time

# Initialize UART0 on Pico: TX=GP0, RX=GP1, 9600 baud
uart = UART(0, baudrate=9600, tx=0, rx=1)

# APSR responses
responses = {
    'C': "Carry: set if there was a carry out of or no borrow into the msb.",
    'N': "Negative: set if result is negative for signed number; N = msb.",
    'V': "Overflow: set if result is invalid for signed number.",
    'Z': "Zero: set if result is zero.",
}

def prompt():
    uart.write(b"Type a letter for APSR glossary lookup.\r\n>")

# Initial prompt
prompt()

while True:
    if uart.any():
        ch = uart.read(1).decode(errors='ignore')
        if not ch:
            continue

        upper = ch.upper()
        if upper in responses:
            uart.write(ch.encode())  # echo typed character
            uart.write(b"\r\n")
            uart.write(responses[upper].encode())
            uart.write(b"\r\n")
        else:
            uart.write(b"Invalid input. Try C, N, V, or Z.\r\n")
        prompt()
