import serial
import time

# ===== Use COM1 =====
ser = serial.Serial("COM1", 9600, timeout=1)

# APSR responses
responses = {
    'C': "Carry: set if there was a carry out of or no borrow into the msb.",
    'N': "Negative: set if result is negative for signed number; N = msb.",
    'V': "Overflow: set if result is invalid for signed number.",
    'Z': "Zero: set if result is zero.",
}

def prompt():
    ser.write(b"Type a letter for APSR glossary lookup.\r\n>")

# Initial prompt
prompt()

while True:
    ch = ser.read(1).decode(errors='ignore')  # read 1 character
    if not ch:
        continue

    upper = ch.upper()

    if upper in responses:
        ser.write(ch.encode())  # echo typed character
        ser.write(b"\r\n")
        ser.write(responses[upper].encode())
        ser.write(b"\r\n")
        prompt()  # repeat prompt after each valid input
