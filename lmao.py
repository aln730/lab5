import serial

ser = serial.Serial("/dev/pts/6", 9600)

responses = {
    'C': "Carry: set if there was a carry out of or no borrow into the msb.",
    'N': "Negative: set if result is negative for signed number; N = msb.",
    'V': "Overflow: set if result is invalid for signed number.",
    'Z': "Zero: set if result is zero.",
}

def prompt():
    ser.write(b"Type a letter for APSR glossary lookup.\r\n>")

prompt()

while True:
    ch = ser.read(1).decode()
    upper = ch.upper()

    if upper in responses:
        ser.write(ch.encode())  # echo original
        ser.write(b"\r\n")
        ser.write(responses[upper].encode())
        ser.write(b"\r\n")
        prompt()import serial

ser = serial.Serial("COM2", 9600)

responses = {
    "n": "Negative: set if result is negative for signed number; N = msb.\r\n",
    "z": "Zero: set if result is zero.\r\n",
    "c": "Carry: set if there was a carry out of or no borrow into the msb.\r\n",
    "v": "Overflow: set if result is invalid for signed number.\r\n",
}

while True:
    ser.write(b"Type a letter for APSR glossary lookup.\r\n>")
    char = ser.read(1).decode().lower()
    ser.write((char + "\r\n").encode())
    if char in responses:
        ser.write(responses[char].encode())
